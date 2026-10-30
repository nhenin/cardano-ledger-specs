{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Real funding and generated output forms for minimum-coin specifications.
-- Store-backed application assets are distinct from their externally funded
-- deposit. Implicit outputs retain their byte-priced minimum application ADA.
-- Every supplied declaration remains the specification's explicit choice.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.MinimumCoin (
  Body (..),
  Content (..),
  Scenario (..),
  Fixture (..),
  storeBackedNativeAssets,
  storeBackedDatumOrReferenceScript,
  storeBackedAddressOnly,
  implicitMinimum,
  fund,
  buildAndSignTx,
  oneLovelaceBelowMinimum,
  selectedOutput,
  minimumCoins,
) where

import Cardano.Ledger.Binary (Sized (sizedSize), mkSized)
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Mary.Value (AssetName (..), MaryValue (..), PolicyID (..), multiAssetFromList)
import Cardano.Ledger.Plutus (mkInlineDatum)
import Cardano.Ledger.Shelley.LedgerState (curPParamsEpochStateL, nesEsL)
import Cardano.Ledger.Shelley.Scripts (ShelleyEraScript (mkRequireSignature))
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val ((<->)), inject)
import qualified Data.ByteString as BS
import Data.Foldable (toList)
import Data.Maybe.Strict (StrictMaybe (..))
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Typeable (Typeable)
import Lens.Micro
import qualified PlutusLedgerApi.V1 as Plutus
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (isImplicitOutput)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance as Submission
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release as Release
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Ordinary output ownership; a child has its own output-index namespace.
data Body = TopTxOutput | SubTxOutput deriving (Eq, Show)

-- | The selected output's payload, independently of its body and phase-2 outcome.
-- Datum-only and reference-script-only outputs have no application assets at all.
data Content = NativeAssets | InlineDatum | ReferenceScript | AddressOnly | Implicit
  deriving (Eq, Show)

-- | Generated price, payload size, token quantity and funding vary each sample.
-- Body, output content and phase-2 outcome are enumerated by the public generators.
data Scenario = Scenario
  { body :: Body
  , phase2 :: IsPhase2Valid
  , content :: Content
  , bytePrice :: Integer
  , payloadBytes :: Int
  , tokenQuantity :: Integer
  , sourceCoins :: Coin
  }
  deriving (Show)

-- | An undeclared, funded proposal. The Store allocation and implicit minimum
-- are independently priced from the exact selected output supplied to the ledger.
data Fixture = Fixture
  { proposal :: ReleaseTx
  , allocatedDeposit :: Coin
  , requiredMinimum :: Coin
  }
  deriving (Show)

-- | A positive native-asset quantity with zero application ADA, in both bodies
-- and on both phase-2 paths. Tokens are minted in an earlier accepted transaction.
storeBackedNativeAssets :: Gen [Scenario]
storeBackedNativeAssets = scenarios [NativeAssets]

-- | Cover datum-only AND reference-script-only Store outputs in every sample,
-- for each body and phase-2 path. Neither variant carries application assets.
storeBackedDatumOrReferenceScript :: Gen [Scenario]
storeBackedDatumOrReferenceScript = scenarios [InlineDatum, ReferenceScript]

-- | A Store output containing only its address: no ADA, tokens, datum or script.
storeBackedAddressOnly :: Gen [Scenario]
storeBackedAddressOnly = scenarios [AddressOnly]

-- | An implicit output exactly at its own size-dependent minimum. An inline
-- datum varies the serialized size, and the application coin is solved as a fixed point.
implicitMinimum :: Gen [Scenario]
implicitMinimum = scenarios [Implicit]

-- | Vary numeric premises while exhaustively visiting the body/content/path product.
scenarios :: [Content] -> Gen [Scenario]
scenarios contents = do
  price <- chooseInteger (1_000, 4_310)
  bytes <- chooseInt (0, 96)
  quantity <- chooseInteger (1, 10_000)
  application <- Coin <$> chooseInteger (200_000_000, 210_000_000)
  pure
    [ Scenario owner validity payload price bytes quantity application
    | payload <- contents
    , owner <- [TopTxOutput, SubTxOutput]
    , validity <- [Phase2Valid, Phase2Invalid]
    ]

-- | Establish a real implicit funding input and, when needed, mint the exact
-- native-asset quantity in that earlier accepted transaction. Output zero carries
-- change; output one is the selected test output and must survive preparation intact.
-- The target body's declaration is deliberately absent for the specification.
fund :: Scenario -> ImpTestM DijkstraEra Fixture
fund generated@Scenario {body, content, bytePrice, sourceCoins} = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin $ fromInteger bytePrice)
  address <- freshKeyAddrNoPtr_
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  assets <- case content of
    NativeAssets -> do
      policy <- PolicyID <$> (impAddNativeScript . mkRequireSignature =<< freshKeyHash)
      pure $ multiAssetFromList [(policy, AssetName "minimum-coin", tokenQuantity generated)]
    _ -> pure mempty
  let source = mkBasicTxOutWithImplicitDeposit address $ MaryValue sourceCoins assets
  funding <-
    submitTx $
      mkBasicTx mkBasicTxBody
        & bodyTxL . mintTxBodyL .~ assets
        & bodyTxL . outputsTxBodyL .~ SSeq.singleton source
  impGetUTxO (txInAt (0 :: Int) funding) >>= (`shouldBe` source)
  output <- outputForScenario generated parameters address $ MaryValue (Coin 0) assets
  let balanceOutput = mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 20_000_000
      ownBody =
        mkBasicTx mkBasicTxBody
          & bodyTxL . inputsTxBodyL .~ Set.singleton (txInAt (0 :: Int) funding)
          & bodyTxL . outputsTxBodyL .~ SSeq.fromList [balanceOutput, output]
      tx = case body of
        TopTxOutput -> ownBody
        SubTxOutput ->
          mkBasicTx mkBasicTxBody
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton balanceOutput
            & bodyTxL . subTransactionsTxBodyL
              .~ OMap.fromFoldable
                [ bodyWithOutputs
                    (Set.singleton $ txInAt (0 :: Int) funding)
                    [balanceOutput, output]
                ]
      allocation = Pricing.outputDeposit parameters output
      minimumAmount = if content == Implicit then minimumCoins parameters output else Coin 0
  state <- Release.readAccountingState
  output ^. coinTxOutL `shouldBe` minimumAmount
  pure $ Fixture (ReleaseTx (Pricing.LedgerState state parameters) tx) allocation minimumAmount

-- | Construct an undeclared body with its supplied input ownership and output order.
bodyWithOutputs :: Typeable l => Set.Set TxIn -> [TxOut DijkstraEra] -> Tx l DijkstraEra
bodyWithOutputs inputs outputs =
  mkBasicTx mkBasicTxBody
    & bodyTxL . inputsTxBodyL .~ inputs
    & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs

-- | Construct the selected output without choosing a declaration. A reference
-- script is stored, not executed; its presence does not introduce a minting policy.
outputForScenario ::
  Scenario -> PParams DijkstraEra -> Addr -> MaryValue -> ImpTestM DijkstraEra (TxOut DijkstraEra)
outputForScenario generated parameters address assets =
  case content generated of
    NativeAssets -> pure $ mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets assets
    InlineDatum -> pure $ withDatum generated $ mkBasicTxOutWithStoreBackedDeposit address mempty
    ReferenceScript -> do
      scriptKey <- freshKeyHash
      pure $
        mkBasicTxOutWithStoreBackedDeposit address mempty
          & referenceScriptTxOutL .~ SJust (fromNativeScript $ mkRequireSignature scriptKey)
    AddressOnly -> pure $ mkBasicTxOutWithStoreBackedDeposit address mempty
    Implicit ->
      pure $ atMinimum parameters $ withDatum generated $ mkBasicTxOutWithImplicitDeposit address mempty

-- | Vary a semantically irrelevant inline byte string, including CBOR length boundaries.
withDatum :: Scenario -> TxOut DijkstraEra -> TxOut DijkstraEra
withDatum generated =
  datumTxOutL .~ mkInlineDatum (Plutus.B $ BS.replicate (payloadBytes generated) 0)

-- | Independent byte-price equation over the complete accepted output encoding.
-- Dijkstra's implicit wrapper adds no bytes. This never calls the production
-- minimum-coin predicate or treats a Store allocation as application ADA.
minimumCoins :: PParams DijkstraEra -> TxOut DijkstraEra -> Coin
minimumCoins parameters output =
  case parameters ^. ppCoinsPerUTxOByteL of
    CoinPerByte (CompactCoin price) ->
      Coin $ toInteger price * (160 + toInteger (sizedSize $ mkSized (eraProtVerLow @DijkstraEra) output))

-- | Solve coin = price * (160 + serializedSize(output)) after placing that coin
-- in the output itself, so CBOR coin-width changes are included in the boundary.
atMinimum :: PParams DijkstraEra -> TxOut DijkstraEra -> TxOut DijkstraEra
atMinimum parameters output =
  let required = minimumCoins parameters output
   in if output ^. coinTxOutL == required
        then output
        else atMinimum parameters $ output & coinTxOutL .~ required

-- | Build exact financial balance and signatures while preserving the selected
-- output and all explicit declarations. The invalid path executes a genuinely
-- failing V4 script with disjoint implicit collateral, never merely a false flag.
buildAndSignTx :: Scenario -> ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignTx generated declared = do
  signed <- case (content generated, phase2 generated) of
    (Implicit, Phase2Valid) -> Accounting.buildAndSignTx declared
    (Implicit, Phase2Invalid) -> Accounting.buildAndSignPhase2InvalidTx declared
    (_, Phase2Valid) -> Submission.buildAndSignTx declared
    (_, Phase2Invalid) -> Submission.buildAndSignPhase2InvalidTx declared
  case content generated of
    Implicit -> do
      sources <- traverse impGetUTxO $ Set.toList $ Release.ordinarySpendingInputs signed
      all isImplicitOutput sources `shouldBe` True
      all isImplicitOutput (Release.createdOrdinaryOutputs signed) `shouldBe` True
    _ -> pure ()
  selectedOutput generated signed `shouldBe` selectedOutput generated (unsignedTx declared)
  signed ^. isPhase2ValidTxL `shouldBe` phase2 generated
  pure signed

-- | Select output one in its own body. TopTx's change output never stands in for
-- the child target, and a fixture with a different child count is rejected.
selectedOutput :: Scenario -> Tx TopTx DijkstraEra -> TxOut DijkstraEra
selectedOutput generated tx =
  case drop 1 $ toList $ case body generated of
    TopTxOutput -> tx ^. bodyTxL . outputsTxBodyL
    SubTxOutput -> onlyChild tx ^. bodyTxL . outputsTxBodyL of
    output : _ -> output
    [] -> error "MinimumCoin fixture requires target output one"

-- | The child scenario always contains exactly one ordinary SubTx.
onlyChild :: Tx TopTx DijkstraEra -> Tx SubTx DijkstraEra
onlyChild tx = case OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL of
  [child] -> child
  _ -> error "MinimumCoin fixture requires exactly one SubTx"

-- | Remove exactly one lovelace from the selected implicit output and return it
-- to TopTx change. Re-sign without fixup; the declaration, Store pricing, fees and
-- complete transaction balance stay intact. Recompute the minimum from the final
-- bytes to prove that the deficit remains exactly one despite CBOR size changes.
oneLovelaceBelowMinimum ::
  Scenario -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
oneLovelaceBelowMinimum generated tx = do
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  let before = selectedOutput generated tx
      required = minimumCoins parameters before
      changed =
        changeSelectedCoin generated (Coin 0 <-> Coin 1) tx
          & bodyTxL . outputsTxBodyL %~ changeCoinAt 0 (Coin 1)
  content generated `shouldBe` Implicit
  before ^. coinTxOutL `shouldBe` required
  minimumCoins parameters (selectedOutput generated changed) `shouldBe` required
  selectedOutput generated changed ^. coinTxOutL `shouldBe` (required <-> Coin 1)
  signed <- Submission.resignTx changed
  signed ^. bodyTxL . feeTxBodyL `shouldBe` (tx ^. bodyTxL . feeTxBodyL)
  signed ^. sizeTxF `shouldBe` (tx ^. sizeTxF)
  pure signed

-- | Change only the selected body's own output one, keeping all other content.
changeSelectedCoin :: Scenario -> Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
changeSelectedCoin generated difference tx = case body generated of
  TopTxOutput -> tx & bodyTxL . outputsTxBodyL %~ changeCoinAt 1 difference
  SubTxOutput ->
    tx
      & bodyTxL . subTransactionsTxBodyL
        .~ OMap.fromFoldable [onlyChild tx & bodyTxL . outputsTxBodyL %~ changeCoinAt 1 difference]

-- | Adjust application ADA at one known output index without replacing its payload.
changeCoinAt ::
  Int -> Coin -> SSeq.StrictSeq (TxOut DijkstraEra) -> SSeq.StrictSeq (TxOut DijkstraEra)
changeCoinAt selected difference =
  SSeq.fromList
    . zipWith
      (\index output -> if index == selected then output & coinTxOutL <>~ difference else output)
      [0 ..]
    . toList
