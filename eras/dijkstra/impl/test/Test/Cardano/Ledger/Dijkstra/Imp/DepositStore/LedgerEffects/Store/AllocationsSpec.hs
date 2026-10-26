{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | Allocation records belong to live Store-backed output references. New records
-- use accepted output sizes; unconsumed records retain their creation-time amounts.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Store.AllocationsSpec (spec) where

import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (
  curPParamsEpochStateL,
  nesEsL,
  utxosUtxo,
 )
import Cardano.Ledger.State (depositStoreAllocations, unUTxO)
import Cardano.Ledger.Val (inject)
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, chooseInt, chooseInteger, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects as Effects
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.UTxO as InputRoles
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  assertDepositTotal,
  recordedDepositStore,
  retainsCreationMetadata,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (isImplicitOutput)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as Context
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting as AccountingSubmission
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  createdOrdinaryOutputs,
  ordinarySpendingInputs,
  readLedger,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (
  fixupTx,
  freshKeyAddrNoPtr_,
  getsNES,
  modifyPParams,
 )
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe, shouldNotBe)

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-ALLOCATIONS - Allocation records" $ do
  -- Every ordinary body contributes its own output references. Duplicate output
  -- values remain separate records; consumed inputs disappear and unrelated records stay.
  prop "DS-STATE-ALLOCATIONS-P01 - accepted ∧ phase2Valid ⇒ allocationsAfter = (allocationsBefore without ordinaryInputs) ∪ newAllocations" $
    forAll Effects.ordinaryScenarios $ \scenarios ->
      forM_ scenarios $ \scenario ->
        forM_ [Effects.buildAndSignOrdinary, Effects.buildAndSignDelegatedOrdinary] $ \build -> do
          signedTx <- build scenario
          previousUTxOState <- readLedger
          parameters <- getsNES $ nesEsL . curPParamsEpochStateL
          let recordsBefore = depositStoreAllocations $ recordedDepositStore previousUTxOState
              newAllocations = Pricing.createdAllocations
                (Pricing.LedgerState previousUTxOState parameters) signedTx
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          assertDepositTotal utxoState
          let recordsAfter = depositStoreAllocations $ recordedDepositStore utxoState
          recordsAfter `shouldBe` newAllocations <> Map.withoutKeys recordsBefore (ordinarySpendingInputs signedTx)
          Map.keysSet recordsAfter `shouldBe` Map.keysSet
            (Map.filter (not . isImplicitOutput) $ unUTxO $ utxosUtxo utxoState)

  -- Both real script outcomes cover mixed collateral, absent/implicit/Store returns,
  -- equal deposits and changed prices. Shared ordinary/collateral sources are removed
  -- once by the selected path; reference-only records remain unchanged.
  prop "DS-STATE-ALLOCATIONS-P02 - accepted ⇒ allocationsAfter = (allocationsBefore without appliedInputs) ∪ appliedAllocations" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario ->
        forM_ ([False] <> [True | Collateral.StoreBacked `elem` Collateral.inputForms scenario]) $ \shared -> do
          fixture <- Collateral.buildAndSign scenario >>= InputRoles.withReferenceOnlyInput
          Fixture{signedTx, previousUTxOState, collateralInputs, returnDeposit} <-
            if shared then InputRoles.withSharedOrdinaryInput fixture else pure fixture
          let recordsBefore = depositStoreAllocations $ recordedDepositStore previousUTxOState
              returnInput = txInAt (length $ signedTx ^. bodyTxL . outputsTxBodyL) signedTx
              returnAllocation = case signedTx ^. bodyTxL . collateralReturnTxBodyL of
                SJust (StoreBackedTxOut _) -> Map.singleton returnInput returnDeposit
                _ -> Map.empty
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          assertDepositTotal utxoState
          let recordsAfter = depositStoreAllocations $ recordedDepositStore utxoState
          recordsAfter `shouldBe` case signedTx ^. isPhase2ValidTxL of
            Phase2Valid -> Map.withoutKeys recordsBefore $ ordinarySpendingInputs signedTx
            Phase2Invalid -> returnAllocation <> Map.withoutKeys recordsBefore collateralInputs
          Map.keysSet recordsAfter `shouldBe` Map.keysSet
            (Map.filter (not . isImplicitOutput) $ unUTxO $ utxosUtxo utxoState)

  -- The accepted wire output has one more byte than its canonical re-encoding.
  -- Its measured allocation survives a real state-codec restore, changed prices
  -- and reference-only use; consuming it finally removes precisely that record.
  prop "DS-STATE-ALLOCATIONS-P03 - snapshotRestore ∧ priceChanged ∧ referenceOnly ⇒ recordedDepositAfter = creationDeposit; consumed ⇒ recordAbsent" $
    forAll (Coin <$> chooseInteger (50000000, 60000000)) $ \coins -> do
      (allocationTx, acceptedBytes) <- Effects.buildAndSignNoncanonicalAllocation coins
      let source = txInAt 0 allocationTx
          creationDeposit = Coin $ 1000 * (160 + toInteger acceptedBytes)
          version = eraProtVerLow @DijkstraEra
      submitTx allocationTx >>= isAccepted
      allocatedState <- readLedger
      retainsCreationMetadata source acceptedBytes (CoinPerByte $ CompactCoin 1000) allocatedState
      let records = depositStoreAllocations $ recordedDepositStore allocatedState
      Map.lookup source records `shouldBe` Just creationDeposit
      canonicalOutput <- expectJust $
        Map.lookup source $ unUTxO $ utxosUtxo allocatedState
      fromIntegral (Binary.sizedSize $ Binary.mkSized version canonicalOutput) `shouldBe` acceptedBytes - 1
      Effects.restoreUTxOState allocatedState
      modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 2000)
      parameters <- getsNES $ nesEsL . curPParamsEpochStateL
      Pricing.outputDeposit parameters canonicalOutput `shouldNotBe` creationDeposit
      referenceTx <- fixupTx $ mkBasicTx mkBasicTxBody & bodyTxL . referenceInputsTxBodyL .~ Set.singleton source
      submitTx referenceTx >>= isAccepted
      referencedState <- readLedger
      retainsCreationMetadata source acceptedBytes (CoinPerByte $ CompactCoin 1000) referencedState
      depositStoreAllocations (recordedDepositStore referencedState) `shouldBe` records
      address <- freshKeyAddrNoPtr_
      spendingTx <- fixupTx $
        Pricing.declareNetDeposit (Coin $ negate $ 1000 * (160 + toInteger acceptedBytes)) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.singleton source
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address $ inject coins)
      submitTx spendingTx >>= isAccepted
      consumedState <- readLedger
      assertDepositTotal consumedState
      depositStoreAllocations (recordedDepositStore consumedState) `shouldBe` Map.delete source records

  -- A zero byte price creates zero-valued records, not missing records. Parent
  -- and child outputs remain distinct; their translated funding inputs are implicit.
  prop "DS-STATE-ALLOCATIONS-N01 - bytePrice = 0 ∧ createdStoreBackedOutputs ≠ ∅ ⇒ newAllocations = {(outputRef, 0) | outputRef ∈ createdStoreBackedOutputs}" $
    forAll (do
      count <- chooseInt (1, 3)
      let operations = (Accounting.bodyOperations count 0) {Accounting.sourceTranslation = True}
      Accounting.scenario operations [operations]) $ \scenario -> do
        proposal <- AccountingSubmission.fundAccountingScenario scenario
        modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 0)
        parameters <- getsNES $ nesEsL . curPParamsEpochStateL
        let repriced = proposal {Context.ledgerState = (Context.ledgerState proposal) {Pricing.protocolParameters = parameters}}
        signedTx <- AccountingSubmission.buildAndSignTx $ Context.addDeclaration
          (Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]) repriced
        previousUTxOState <- readLedger
        let newAllocations = Map.map (const $ Coin 0) $
              Map.filter (not . isImplicitOutput) $ createdOrdinaryOutputs signedTx
        Map.null newAllocations `shouldBe` False
        submitTx signedTx >>= isAccepted
        utxoState <- readLedger
        assertDepositTotal utxoState
        depositStoreAllocations (recordedDepositStore utxoState)
          `shouldBe` newAllocations <> Map.withoutKeys
            (depositStoreAllocations $ recordedDepositStore previousUTxOState) (ordinarySpendingInputs signedTx)

  -- A real failing parent script skips proposed allocations/releases in every
  -- ordinary body. This fixture's disjoint collateral uses implicit deposits only.
  prop "DS-STATE-ALLOCATIONS-P04 - accepted ∧ phase2Invalid ∧ implicitOnlyCollateral ⇒ allocationsAfter = allocationsBefore" $
    forAll Effects.ordinaryScenarios $ \scenarios ->
      forM_ (filter (not . null . Accounting.subOperations) scenarios) $ \scenario -> do
        signedTx <- Effects.buildAndSignOrdinaryPhase2Invalid scenario
        recordsBefore <- depositStoreAllocations . recordedDepositStore <$> readLedger
        submitTx signedTx >>= isAccepted
        recordsAfter <- depositStoreAllocations . recordedDepositStore <$> readLedger
        recordsAfter `shouldBe` recordsBefore
{- FOURMOLU_ENABLE -}
