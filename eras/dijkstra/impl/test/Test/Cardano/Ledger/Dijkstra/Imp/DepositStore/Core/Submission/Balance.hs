{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Fund real assets and exact illustrated deposits for transaction-balance
-- specifications. Re-signing deliberately performs no fee or value fixup.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance (
  resignTx,
  observeBalance,
  buildAndSignTx,
  buildAndSignPhase2InvalidTx,
  fundNativeAssets,
  fundTenAdaWithTwoAdaDeposit,
) where

import Cardano.Ledger.Binary (Sized (sizedSize), mkSized)
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Mary.Value (AssetName (..), MaryValue (..), PolicyID (..), multiAssetFromList)
import Cardano.Ledger.Plutus (mkInlineDatum)
import Cardano.Ledger.Shelley.LedgerState (curPParamsEpochStateL, nesEsL)
import Cardano.Ledger.Shelley.Scripts (ShelleyEraScript (mkRequireSignature))
import Cardano.Ledger.Val (Val (coin, isAdaOnly, (<->)), inject)
import qualified Data.ByteString as BS
import Data.List (find)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import qualified PlutusLedgerApi.V1 as Plutus
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.Balance as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release as Release
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (forM_, shouldBe)

-- | Regenerate every ordered child's witnesses before the parent witnesses.
-- Keep fees, input ownership, outputs, mint and declarations exactly as supplied;
-- a deliberately introduced imbalance must survive until ledger submission.
resignTx :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
resignTx tx = do
  children <- traverse rederiveAddrTxWits $ OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
  rederiveAddrTxWits $ tx & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable children

-- | Resolve every ordinary input against the live ledger after preparation,
-- including fee or script inputs added by fixup. Check the oracle's supported
-- flow boundary explicitly before calculating independent consumed/produced values.
observeBalance :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra Balance.Balance
observeBalance tx = do
  checkSupportedBody tx
  forM_ (OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL) checkSupportedBody
  allocations <- getIndexedUTxOs
  pure $ Balance.balance allocations tx

-- | These scenarios have application inputs/outputs, fees and Store transfers.
-- Additional financial flows must extend the independent oracle before use.
checkSupportedBody :: Tx l DijkstraEra -> ImpTestM DijkstraEra ()
checkSupportedBody tx = do
  tx ^. bodyTxL . certsTxBodyL `shouldBe` mempty
  tx ^. bodyTxL . withdrawalsTxBodyL `shouldBe` mempty
  tx ^. bodyTxL . mintTxBodyL `shouldBe` mempty
  tx ^. bodyTxL . treasuryDonationTxBodyL `shouldBe` Coin 0
  tx ^. bodyTxL . directDepositsTxBodyL `shouldBe` mempty
  tx ^. bodyTxL . proposalProceduresTxBodyL `shouldBe` mempty

-- | Prepare witnesses and fees, then independently balance the implicit parent
-- output. The valid control therefore follows the specification's value equation,
-- rather than assuming that production fixup implements Store balance correctly.
buildAndSignTx :: ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignTx proposal = Accounting.buildAndSignTx proposal >>= balancePreparedTx

-- | Prepare a genuinely failing script and collateral, while keeping the ordinary
-- proposal independently balanced. Ordinary balance is not a phase-2-failure
-- validity requirement; this builder merely establishes the scenario's premise.
buildAndSignPhase2InvalidTx :: ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignPhase2InvalidTx proposal = Accounting.buildAndSignPhase2InvalidTx proposal >>= balancePreparedTx

-- | Correct only application ADA in implicit parent output zero. Native assets
-- must already balance; no declaration, Store output, fee or child is repaired.
-- Never use this function on a deliberately imbalanced negative-test mutation.
balancePreparedTx :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
balancePreparedTx tx = do
  observed <- observeBalance tx
  let residual = Balance.consumedValue observed <-> Balance.producedValue observed
  isAdaOnly residual `shouldBe` True
  signed <- resignTx $ Balance.changeTopOutputCoins (coin residual) tx
  independentlyBalanced <- observeBalance signed
  Balance.isBalanced independentlyBalanced `shouldBe` True
  pure signed

-- | Mint a positive quantity under a fresh signature policy in an accepted
-- funding transaction. Add its implicit output as a TopTx input and copy the
-- same application value to a new implicit TopTx output, preserving balance and
-- every deposit declaration. Return the token-only value for explicit assertions
-- or mutations; the copied output also carries ten ADA to cover its minimum.
-- The fixed name permits a same-width asset-identity mutation without changing fees.
fundNativeAssets :: Integer -> ReleaseTx -> ImpTestM DijkstraEra (MaryValue, ReleaseTx)
fundNativeAssets quantity proposal = do
  (quantity > 0) `shouldBe` True
  policy <- PolicyID <$> (impAddNativeScript . mkRequireSignature =<< freshKeyHash)
  address <- freshKeyAddrNoPtr_
  let assets = multiAssetFromList [(policy, AssetName "balance-a", quantity)]
      tokenValue = MaryValue mempty assets
      output = mkBasicTxOutWithImplicitDeposit address $ MaryValue (Coin 10_000_000) assets
  funding <-
    submitTx $
      mkBasicTx mkBasicTxBody
        & bodyTxL
          . mintTxBodyL
          .~ assets
        & bodyTxL
          . outputsTxBodyL
          .~ SSeq.singleton output
  impGetUTxO (txInAt (0 :: Int) funding) >>= (`shouldBe` output)
  state <- Release.readAccountingState
  let context = ledgerState proposal
      tx = unsignedTx proposal
      withTokens =
        proposal
          { ledgerState = context {Pricing.accountingState = state}
          , unsignedTx =
              tx
                & bodyTxL
                  . inputsTxBodyL
                  %~ Set.insert (txInAt (0 :: Int) funding)
                & bodyTxL
                  . outputsTxBodyL
                  %~ (<> SSeq.singleton output)
          }
  pure (tokenValue, withTokens)

-- | Establish the concrete ten-ADA application / two-ADA deposit example with
-- one actual Store-backed source. Its only spending SubTx proposes an implicit
-- twelve-ADA output and has no additional funding input. TopTx has a separate
-- generated implicit funding source, so fees need not reduce that child output.
-- Both bodies remain undeclared for the specification to supply its own DSL.
fundTenAdaWithTwoAdaDeposit :: Coin -> ImpTestM DijkstraEra ReleaseTx
fundTenAdaWithTwoAdaDeposit topFunding = do
  modifyPParams $
    (ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 2_000))
      . (ppMaxTxSizeL .~ 100_000)
  address <- freshKeyAddrNoPtr_
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  let source = twoAdaDepositOutput address
      implicitFunding = mkBasicTxOutWithImplicitDeposit address $ inject topFunding
  Pricing.outputDeposit parameters source `shouldBe` Coin 2_000_000
  funding <-
    submitTx $
      Pricing.declareNetDeposit (Coin 2_000_000) $
        mkBasicTx mkBasicTxBody
          & bodyTxL
            . outputsTxBodyL
            .~ SSeq.fromList [implicitFunding, source]
  state <- Release.readAccountingState
  impGetUTxO (txInAt (1 :: Int) funding) >>= (`shouldBe` source)
  Map.lookup (txInAt (1 :: Int) funding) (recordedAmounts $ liveOutputStore state)
    `shouldBe` Just (Coin 2_000_000)
  let child :: Tx SubTx DijkstraEra
      child =
        mkBasicTx mkBasicTxBody
          & bodyTxL
            . inputsTxBodyL
            .~ Set.singleton (txInAt (1 :: Int) funding)
          & bodyTxL
            . outputsTxBodyL
            .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 12_000_000)
      tx =
        mkTopTxWithSubTxs [child]
          & bodyTxL
            . inputsTxBodyL
            .~ Set.singleton (txInAt (0 :: Int) funding)
          & bodyTxL
            . outputsTxBodyL
            .~ SSeq.singleton implicitFunding
  pure $ ReleaseTx (Pricing.LedgerState state parameters) tx

-- | Select a measured 840-byte Store output. With the 160-byte overhead and
-- the fixture price of 2000 lovelace per byte, its recorded deposit is two ADA.
twoAdaDepositOutput :: Addr -> TxOut DijkstraEra
twoAdaDepositOutput address =
  case find ((== 840) . sizedSize . mkSized (eraProtVerLow @DijkstraEra)) (paddedSources address) of
    Just output -> output
    Nothing -> error "No inline datum length gives the exact two-ADA fixture deposit"

-- | Search around the measured padding length, using a second CBOR integer
-- width to cover any size skipped by byte-string chunk boundaries.
paddedSources :: Addr -> [TxOut DijkstraEra]
paddedSources address =
  let measured = sizedSize $ mkSized (eraProtVerLow @DijkstraEra) $ paddedSource address 700 0
      estimatedPadding = 700 + 840 - fromIntegral measured
   in [ paddedSource address padding marker
      | padding <- [estimatedPadding - 4 .. estimatedPadding + 4]
      , marker <- [0, 24]
      ]

-- | Preserve exactly ten application ADA while varying irrelevant inline datum
-- bytes solely to obtain the independently verified two-ADA source deposit.
paddedSource :: Addr -> Int -> Integer -> TxOut DijkstraEra
paddedSource address padding marker =
  mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets $ inject $ Coin 10_000_000)
    & datumTxOutL
      .~ mkInlineDatum (Plutus.List [Plutus.B $ BS.replicate padding 0, Plutus.I marker])
