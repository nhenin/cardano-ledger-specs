{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Build allocation proposals using implicit funding from the real test ledger.
-- The calling spec supplies declarations and checks the submission outcome.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Allocation (
  forAllStandaloneAllocationTx,
  forAllPostConwayAllocationTx,
  forAllTopTxAndSubTxAllocationTx,
  buildAndSignTx,
  removeTopTxDeclaration,
  submitTx,
  isAccepted,
  isRejectedWith,
) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (
  curPParamsEpochStateL,
  esLStateL,
  lsAccountingStateL,
  nesEsL,
 )
import Cardano.Ledger.Val (inject)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, Property, forAll)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (isImplicitOutput)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (ordinarySpendingInputs)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Allocation as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  checkPreservedOutputsAndDeclarations,
  isAccepted,
  isRejectedWith,
  removeTopTxDeclaration,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest hiding (submitTx)
import qualified Test.Cardano.Ledger.Dijkstra.ImpTest as ImpTest
import Test.Cardano.Ledger.Imp.Common (forM_, shouldBe)

-- | Generate an undeclared standalone proposal at a fresh key address. Snapshot
-- the actual pricing parameters; the callback supplies the declaration to test.
-- No Store-backed sources are created or consumed during preparation.
forAllStandaloneAllocationTx ::
  Gen TopTx.AllocationScenario ->
  (TopTx.AllocationTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllStandaloneAllocationTx scenarios check =
  forAll scenarios $ \scenario -> do
    modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310)
    address <- freshKeyAddrNoPtr_
    parameters <- getsNES $ nesEsL . curPParamsEpochStateL
    let proposal =
          mkBasicTx mkBasicTxBody
            & bodyTxL . outputsTxBodyL .~ SSeq.fromList (TopTx.createdOutputs address scenario)
            & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
    check $ TopTx.AllocationTx parameters proposal

-- | Translate a Conway output through the production Dijkstra conversion, fund
-- that translated output through an accepted ledger transaction, then propose
-- consuming it to create generated store-backed outputs. This exercises output
-- translation, not a complete hard-fork state transition. The source retains its
-- ADA and remains implicit, with no Store deposit to release.
forAllPostConwayAllocationTx ::
  Gen TopTx.AllocationScenario ->
  (TopTx.AllocationTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllPostConwayAllocationTx scenarios check =
  forAll scenarios $ \scenario -> do
    modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310)
    address <- freshKeyAddrNoPtr_
    parameters <- getsNES $ nesEsL . curPParamsEpochStateL
    let outputs = TopTx.createdOutputs address scenario
        sourceCoins = foldMap (^. coinTxOutL) outputs <> Coin 10_000_000
        conwayOutput = mkBasicTxOutWithImplicitDeposit @ConwayEra address $ inject sourceCoins
        translatedOutput = upgradeTxOut @DijkstraEra conwayOutput
    translatedOutput ^. coinTxOutL `shouldBe` sourceCoins
    translatedOutput ^. addrTxOutL `shouldBe` address
    isImplicitOutput translatedOutput `shouldBe` True
    funded <-
      ImpTest.submitTx $
        mkBasicTx mkBasicTxBody
          & bodyTxL . outputsTxBodyL .~ SSeq.singleton translatedOutput
    let sourceInput = txInAt 0 funded
    impGetUTxO sourceInput >>= (`shouldBe` translatedOutput)
    records <-
      recordedAmounts . liveOutputStore <$> getsNES (nesEsL . esLStateL . lsAccountingStateL)
    Map.lookup sourceInput records `shouldBe` Nothing
    check $
      TopTx.AllocationTx parameters $
        mkBasicTx mkBasicTxBody
          & bodyTxL . inputsTxBodyL .~ Set.singleton sourceInput
          & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs
          & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration

-- | Give TopTx and one SubTx their independently generated output plans. Fund the
-- child's application ADA and required allocation with an implicit input; parent
-- funding and fees are supplied during signing. Both declarations remain absent
-- for the spec to supply. Neither body can release a recorded Store deposit.
forAllTopTxAndSubTxAllocationTx ::
  Gen TopTx.AllocationBatchScenario ->
  (TopTx.AllocationTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllTopTxAndSubTxAllocationTx scenarios check =
  forAll scenarios $ \scenario -> do
    modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310)
    address <- freshKeyAddrNoPtr_
    parameters <- getsNES $ nesEsL . curPParamsEpochStateL
    let ownOutputs = TopTx.createdOutputs address $ TopTx.topTxAllocation scenario
        childOutputs = TopTx.createdOutputs address $ TopTx.subTxAllocation scenario
        childAllocation = foldMap (Pricing.outputDeposit parameters) childOutputs
    childInput <- sendCoinTo address $ foldMap (^. coinTxOutL) childOutputs <> childAllocation
    let child =
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.singleton childInput
            & bodyTxL . outputsTxBodyL .~ SSeq.fromList childOutputs
            & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ SubTx.NoUTxODepositDeclaration
        proposal =
          TopTx.AllocationTx parameters $
            mkTopTxWithSubTxs [child]
              & bodyTxL . outputsTxBodyL .~ SSeq.fromList ownOutputs
              & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
    length (TopTx.unsignedTx proposal ^. bodyTxL . subTransactionsTxBodyL) `shouldBe` 1
    (foldMap (Pricing.outputDeposit parameters) ownOutputs > Coin 0) `shouldBe` True
    (childAllocation > Coin 0) `shouldBe` True
    check proposal

-- | Fund application outputs, the supplied allocation and fees, then sign.
-- Preserve the proposal's declarations and outputs. Every final spending input
-- must be implicit with no Store allocation, so allocation alone triggers presence.
-- These checks protect the fixture; ledger effects are not asserted here.
buildAndSignTx :: TopTx.AllocationTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignTx proposal = do
  let tx = TopTx.unsignedTx proposal
  signed <- fixupTx tx
  checkPreservedOutputsAndDeclarations tx signed
  Set.isSubsetOf (tx ^. bodyTxL . inputsTxBodyL) (signed ^. bodyTxL . inputsTxBodyL) `shouldBe` True
  map (^. bodyTxL . inputsTxBodyL) (OMap.elems $ signed ^. bodyTxL . subTransactionsTxBodyL)
    `shouldBe` map (^. bodyTxL . inputsTxBodyL) (OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL)
  records <-
    recordedAmounts . liveOutputStore <$> getsNES (nesEsL . esLStateL . lsAccountingStateL)
  forM_ (ordinarySpendingInputs signed) $ \input -> do
    output <- impGetUTxO input
    isImplicitOutput output `shouldBe` True
    Map.lookup input records `shouldBe` Nothing
  pure signed
