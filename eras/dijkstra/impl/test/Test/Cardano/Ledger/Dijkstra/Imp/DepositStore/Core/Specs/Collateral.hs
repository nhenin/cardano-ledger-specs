{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}

-- | Generated collateral proposals backed by real, accepted funding transactions.
-- Ordinary funding, script evaluation and signing are preparation only: the
-- specifications choose the collateral amounts and assert the ledger outcome.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (
  OutputForm (..),
  Scenario (..),
  Fixture (..),
  scenarios,
  fundingScenarios,
  ordinaryDeclarationCases,
  assetScenarios,
  additionalAsset,
  buildAndSign,
  withCoinFee,
  withReturnCoins,
  withReturnAssets,
  withoutReturn,
) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Mary.Value (
  AssetName (..),
  MaryValue (..),
  MultiAsset (..),
  PolicyID (..),
  multiAssetFromList,
 )
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript, mkInlineDatum)
import Cardano.Ledger.Shelley.LedgerState (
  UTxOState,
  curPParamsEpochStateL,
  nesEsL,
 )
import Cardano.Ledger.Shelley.Scripts (pattern RequireSignature)
import Cardano.Ledger.State (depositStoreAllocations)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val ((<->)), inject)
import qualified Data.ByteString as BS
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..), strictMaybeToMaybe)
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import qualified PlutusLedgerApi.V1 as Plutus
import Test.Cardano.Ledger.Common (Gen, arbitrary, chooseInt, chooseInteger)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (recordedDepositStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration as Declaration
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (readLedger)
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe)
import Test.Cardano.Ledger.Plutus.Examples (alwaysFailsWithDatum, alwaysSucceedsWithDatum)

-- | The existing output DSL, used independently for each input and the return.
data OutputForm = Implicit | StoreBacked
  deriving (Eq, Show)

-- | Shape and script outcome are selected explicitly by each specification.
-- Prices, payload sizes, application coins and token quantities can vary without
-- changing that shape. Equal payload sizes and coin widths at the same byte price
-- give equal deposits.
data Scenario = Scenario
  { inputForms :: [OutputForm]
  , returnForm :: Maybe OutputForm
  , phase2 :: IsPhase2Valid
  , bytePrice :: Integer
  , sourceBytePrice :: Integer
  , sourceBytes :: Int
  , returnBytes :: Int
  , inputCoinsPerOutput :: Coin
  , tokenQuantity :: Integer
  }
  deriving (Show)

-- | Snapshot immediately before submission, after all source funding and signing.
-- Released deposits come from recorded allocations; the return deposit is priced
-- independently from its final bytes. Neither amount invokes the collateral rule.
data Fixture = Fixture
  { signedTx :: Tx TopTx DijkstraEra
  , previousUTxOState :: UTxOState DijkstraEra
  , collateralInputs :: Set.Set TxIn
  , inputCoins :: Coin
  , releasedDeposits :: Coin
  , returnDeposit :: Coin
  , minimumFee :: Coin
  , protocolParameters :: PParams DijkstraEra
  , collateralAssets :: MultiAsset
  }
  deriving (Show)

-- | Generate fresh numeric data for the requested shape. Tokens are absent by
-- default; the native-asset specification supplies a positive generated quantity.
scenarios :: [OutputForm] -> Maybe OutputForm -> IsPhase2Valid -> Gen Scenario
scenarios forms returned validity = do
  price <- chooseInteger (1_000, 5_000)
  bytes <- chooseInt (0, 48)
  coins <- Coin <$> chooseInteger (50_000_000, 60_000_000)
  pure $ Scenario forms returned validity price price bytes bytes coins 0

-- | Every sample covers the Store funding relationships, including equal-sized
-- replacement, larger and smaller replacements, mixed inputs and absent returns.
-- Both outcomes execute real scripts. Relative payload sizes force the chosen
-- deposit relationship without installing invented Store balances or records.
-- One replacement lowers the byte price after funding, so its release must come
-- from the recorded deposit rather than repricing the input at the current price.
fundingScenarios :: Gen [Scenario]
fundingScenarios = do
  generated <- scenarios [StoreBacked] (Just StoreBacked) Phase2Invalid
  let bytes = sourceBytes generated
      price = bytePrice generated
  pure
    [ generated
        { inputForms = forms
        , returnForm = returned
        , phase2 = validity
        , sourceBytes = sourceSize
        , returnBytes = returnedSize
        , sourceBytePrice = priceAtAllocation
        }
    | (forms, returned, sourceSize, returnedSize, priceAtAllocation) <-
        [ ([Implicit], Just StoreBacked, bytes, bytes, price)
        , ([StoreBacked], Just StoreBacked, bytes, bytes, price)
        , ([StoreBacked], Just StoreBacked, bytes, bytes + 32, price)
        , ([StoreBacked], Just StoreBacked, bytes + 32, bytes, price)
        , ([StoreBacked], Just Implicit, bytes, bytes, price)
        , ([Implicit, StoreBacked], Just StoreBacked, bytes, bytes, price)
        , ([StoreBacked, StoreBacked], Nothing, bytes, bytes, price)
        , ([Implicit, StoreBacked], Nothing, bytes, bytes, price)
        , ([StoreBacked], Just StoreBacked, bytes, bytes, 2 * price)
        ]
    , validity <- [Phase2Valid, Phase2Invalid]
    ]

-- | Vary ordinary declaration syntax independently of a fixed collateral
-- proposal. These values are calculation inputs, not claims of ordinary financial
-- validity. Existing declaration generators cover every form and body position.
ordinaryDeclarationCases :: Gen [Declarations]
ordinaryDeclarationCases = do
  amount <- arbitrary
  index <- arbitrary
  Declaration.generateCases amount index

-- | Native assets cross both output representations and both script outcomes.
-- Every combination includes Store activity; the pure legacy case belongs to
-- the shared collateral rules outside this Store-specific suite. All assets
-- originate in accepted minting.
assetScenarios :: Gen [Scenario]
assetScenarios = do
  generated <- scenarios [StoreBacked] (Just StoreBacked) Phase2Invalid
  quantity <- chooseInteger (1, 1_000)
  pure
    [ generated
        { inputForms = forms
        , returnForm = Just returned
        , phase2 = validity
        , tokenQuantity = quantity
        }
    | forms <- [[Implicit], [StoreBacked], [Implicit, StoreBacked]]
    , returned <- [Implicit, StoreBacked]
    , StoreBacked `elem` forms || returned == StoreBacked
    , validity <- [Phase2Valid, Phase2Invalid]
    ]

-- | Add a previously absent token under the fixture's existing policy. Its name
-- differs from the funded "collateral" token, so the proposed return invents an
-- asset instead of merely changing a funded quantity.
additionalAsset :: MultiAsset -> MultiAsset
additionalAsset (MultiAsset policies) =
  case Map.minViewWithKey policies of
    Just ((policy, tokens), rest) ->
      MultiAsset $ Map.insert policy (Map.insert (AssetName "extra") 1 tokens) rest
    Nothing -> error "Collateral asset fixture requires a funded native asset"

-- | Fund every selected input plus one unrelated Store output. Mint any generated
-- tokens in that accepted transaction. An actual V4 script establishes the chosen
-- phase-2 path; ordinary fixup uses a temporary implicit return because its legacy
-- helper does not understand Store-backed returns. Install the requested return
-- afterwards and re-sign without repairing collateral funding. Source outputs
-- retain their recorded deposits if the current byte price changes after funding.
buildAndSign :: Scenario -> ImpTestM DijkstraEra Fixture
buildAndSign scenario@Scenario {inputForms, returnForm, phase2, bytePrice, sourceBytePrice, inputCoinsPerOutput} = do
  modifyPParams $
    (ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin $ fromInteger sourceBytePrice))
      . (ppCollateralPercentageL .~ 150)
  address <- freshKeyAddrNoPtr_
  sourceParameters <- getsNES $ nesEsL . curPParamsEpochStateL
  assets <- case tokenQuantity scenario of
    0 -> pure mempty
    quantity -> do
      policy <- PolicyID <$> (impAddNativeScript . RequireSignature =<< freshKeyHash)
      pure $ multiAssetFromList [(policy, AssetName "collateral", quantity)]
  let sourceOutputs =
        [ output form address (sourceBytes scenario) $ MaryValue inputCoinsPerOutput assets
        | form <- inputForms
        ]
      unrelatedOutput = output StoreBacked address (sourceBytes scenario) $ inject inputCoinsPerOutput
      allOutputs = sourceOutputs <> [unrelatedOutput]
      totalAssets = foldMap (const assets) inputForms
      sourceAllocation = foldMap (Pricing.outputDeposit sourceParameters) allOutputs
  fundingTx <-
    submitTx $
      Pricing.declareNetDeposit sourceAllocation $
        mkBasicTx mkBasicTxBody
          & bodyTxL . outputsTxBodyL .~ SSeq.fromList allOutputs
          & bodyTxL . mintTxBodyL .~ totalAssets
  let sourceInputs = [txInAt index fundingTx | index <- [0 .. length inputForms - 1]]
  traverse impGetUTxO sourceInputs >>= (`shouldBe` sourceOutputs)
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin $ fromInteger bytePrice)
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  let inputs = Set.fromList sourceInputs
      totalInputCoins = foldMap (const inputCoinsPerOutput) inputForms
      finalReturn =
        maybe
          SNothing
          ( \form -> SJust $ output form address (returnBytes scenario) $ MaryValue (Coin 10_000_000) totalAssets
          )
          returnForm
      preparationReturn =
        fmap
          (\returned -> mkBasicTxOutWithImplicitDeposit address $ inject $ returned ^. coinTxOutL)
          finalReturn
  scriptInput <- produceScript . hashPlutusScript $ case phase2 of
    Phase2Valid -> alwaysSucceedsWithDatum SPlutusV4
    Phase2Invalid -> alwaysFailsWithDatum SPlutusV4
  prepared <-
    fixupTx $
      mkBasicTx mkBasicTxBody
        & bodyTxL . inputsTxBodyL .~ Set.singleton scriptInput
        & bodyTxL . feeTxBodyL .~ Coin 2_000_011
        & bodyTxL . collateralInputsTxBodyL .~ inputs
        & bodyTxL . collateralReturnTxBodyL .~ preparationReturn
        & bodyTxL . totalCollateralTxBodyL
          .~ SJust (totalInputCoins <-> foldMap (^. coinTxOutL) finalReturn)
  signed <-
    rederiveAddrTxWits $
      prepared
        & bodyTxL . collateralReturnTxBodyL .~ finalReturn
        & isPhase2ValidTxL .~ phase2
  state <- readLedger
  let records = depositStoreAllocations $ recordedDepositStore state
      released = foldMap id $ Map.restrictKeys records inputs
      Coin fee = signed ^. bodyTxL . feeTxBodyL
      percentage = toInteger $ parameters ^. ppCollateralPercentageL
  released `shouldBe` foldMap (Pricing.outputDeposit sourceParameters) sourceOutputs
  signed ^. bodyTxL . collateralInputsTxBodyL `shouldBe` inputs
  signed ^. bodyTxL . collateralReturnTxBodyL `shouldBe` finalReturn
  pure
    Fixture
      { signedTx = signed
      , previousUTxOState = state
      , collateralInputs = inputs
      , inputCoins = totalInputCoins
      , releasedDeposits = released
      , returnDeposit = foldMap (Pricing.outputDeposit parameters) finalReturn
      , minimumFee = Coin $ (fee * percentage + 99) `div` 100
      , protocolParameters = parameters
      , collateralAssets = totalAssets
      }

-- | Same address and payload encoding for both output forms; the only semantic
-- difference is whether storage is funded inside or outside the output's value.
output :: OutputForm -> Addr -> Int -> MaryValue -> TxOut DijkstraEra
output form address bytes value =
  ( case form of
      Implicit -> mkBasicTxOutWithImplicitDeposit address value
      StoreBacked -> mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets value
  )
    & datumTxOutL .~ mkInlineDatum (Plutus.B $ BS.replicate bytes 0)

-- | Choose application coins so the requested fee remains after funding any
-- additional return deposit. Solve using the final coin's encoded width; this
-- covers zero and CBOR width changes without assuming a fixed return deposit.
-- The returned fixture retains the same ledger snapshot and source inputs.
withCoinFee :: Coin -> Fixture -> ImpTestM DijkstraEra Fixture
withCoinFee requested fixture = do
  returned <- expectJust $ strictMaybeToMaybe $ signedTx fixture ^. bodyTxL . collateralReturnTxBodyL
  installReturn (SJust $ returnWithCoinFee 8 requested fixture returned) fixture

-- | Reprice until the return's coin and deposit agree. Bound iteration so an
-- unsupported exact amount at a CBOR-width discontinuity reports a fixture error
-- instead of hanging the suite. Generated application amounts avoid those gaps.
returnWithCoinFee :: Int -> Coin -> Fixture -> TxOut DijkstraEra -> TxOut DijkstraEra
returnWithCoinFee attempts requested fixture returned
  | attempts <= 0 = error "Collateral return has no stable exact coin-fee fixture"
  | otherwise =
      let deposit = Pricing.outputDeposit (protocolParameters fixture) returned
          additional = max mempty (deposit <-> releasedDeposits fixture)
          coins = inputCoins fixture <-> additional <-> requested
          next = returned & coinTxOutL .~ coins
       in if next == returned
            then next
            else returnWithCoinFee (attempts - 1) requested fixture next

-- | Set the return's application ADA directly, retaining its assets and payload.
-- Reprice the final bytes and update the optional legacy total before re-signing.
withReturnCoins :: Coin -> Fixture -> ImpTestM DijkstraEra Fixture
withReturnCoins coins fixture = do
  returned <- expectJust $ strictMaybeToMaybe $ signedTx fixture ^. bodyTxL . collateralReturnTxBodyL
  installReturn (SJust $ returned & coinTxOutL .~ coins) fixture

-- | Replace only returned native assets, allowing a specification to introduce
-- missing, extra or incorrect quantities. No asset balancing or fixup follows.
withReturnAssets :: MultiAsset -> Fixture -> ImpTestM DijkstraEra Fixture
withReturnAssets assets fixture = do
  returned <- expectJust $ strictMaybeToMaybe $ signedTx fixture ^. bodyTxL . collateralReturnTxBodyL
  let value = MaryValue (returned ^. coinTxOutL) assets
      changed = case returned of
        ImplicitDepositTxOut implicit -> ImplicitDepositTxOut $ implicit & valueTxOutL .~ value
        StoreBackedTxOut stored -> StoreBackedTxOut $ stored & applicationAssetsTxOutL .~ ApplicationAssets value
  installReturn (SJust changed) fixture

-- | Remove the return entirely while keeping the collateral inputs and script.
-- The complete input coin amount becomes the optional declared total.
withoutReturn :: Fixture -> ImpTestM DijkstraEra Fixture
withoutReturn = installReturn SNothing

-- | Re-sign the supplied return exactly, without a second ledger fixup.
installReturn :: StrictMaybe (TxOut DijkstraEra) -> Fixture -> ImpTestM DijkstraEra Fixture
installReturn returned fixture = do
  signed <-
    rederiveAddrTxWits $
      signedTx fixture
        & bodyTxL . collateralReturnTxBodyL .~ returned
        & bodyTxL . totalCollateralTxBodyL
          .~ SJust (inputCoins fixture <-> foldMap (^. coinTxOutL) returned)
  pure
    fixture
      { signedTx = signed
      , returnDeposit = foldMap (Pricing.outputDeposit $ protocolParameters fixture) returned
      }
