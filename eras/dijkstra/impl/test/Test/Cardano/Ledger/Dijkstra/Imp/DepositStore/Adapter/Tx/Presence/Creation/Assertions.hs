{-# LANGUAGE DataKinds #-}

-- | Assert creation-fixture preservation and atomic rejection of prepared transactions.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Assertions (
  checkPreservedCreationFixture,
  submitPreparedRejection,
) where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (DijkstraLedgerPredFailure)
import Cardano.Ledger.Shelley.LedgerState (esLStateL, nesEsL)
import Data.Foldable (toList)
import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.OMap.Strict as OMap
import Lens.Micro
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Fixup may append implicit TopTx change, but must retain every supplied output
-- and each body's own declaration, including its phase-2 outcome.
checkPreservedCreationFixture ::
  Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedCreationFixture prepared submitted = do
  let preparedOutputs = toList $ prepared ^. bodyTxL . outputsTxBodyL
      submittedOutputs = toList $ submitted ^. bodyTxL . outputsTxBodyL
      preparedSubs = OMap.elems $ prepared ^. bodyTxL . subTransactionsTxBodyL
      submittedSubs = OMap.elems $ submitted ^. bodyTxL . subTransactionsTxBodyL
  take (length preparedOutputs) submittedOutputs `shouldBe` preparedOutputs
  all isImplicitOutput (drop (length preparedOutputs) submittedOutputs) `shouldBe` True
  submitted
    ^. bodyTxL
      . netUTxODepositChangeTxBodyL
      `shouldBe` (prepared ^. bodyTxL . netUTxODepositChangeTxBodyL)
  length submittedSubs `shouldBe` length preparedSubs
  map (^. bodyTxL . outputsTxBodyL) submittedSubs
    `shouldBe` map (^. bodyTxL . outputsTxBodyL) preparedSubs
  map (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL) submittedSubs
    `shouldBe` map (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL) preparedSubs
  submitted ^. isPhase2ValidTxL `shouldBe` (prepared ^. isPhase2ValidTxL)

-- | Recognize change outputs that do not introduce Store activity.
isImplicitOutput :: TxOut DijkstraEra -> Bool
isImplicitOutput (ImplicitDepositTxOut _) = True
isImplicitOutput (StoreBackedTxOut _) = False

-- | Snapshot after all fixture funding and fixup. A rejected batch must leave
-- the full ledger state unchanged, including its UTxO and accounting state.
submitPreparedRejection ::
  DijkstraLedgerPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedRejection expectedFailure fixed = do
  before <- getsNES $ nesEsL . esLStateL
  withNoFixup $ submitFailingTx fixed (expectedFailure :| [])
  after <- getsNES $ nesEsL . esLStateL
  after `shouldBe` before
