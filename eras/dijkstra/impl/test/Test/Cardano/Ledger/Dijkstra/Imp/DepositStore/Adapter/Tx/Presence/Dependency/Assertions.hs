{-# LANGUAGE DataKinds #-}

module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Dependency.Assertions (
  submitTxAndExpectSuccess,
  submitTxAndExpectRejection,
  submitPreparedTxAndExpectAcceptance,
  submitPreparedTxAndExpectRejection,
) where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (Tx, TxLevel (TopTx), injectFailure)
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure)
import Cardano.Ledger.Shelley.LedgerState (esLStateL, nesEsL)
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Dependency.Transaction (
  checkPreservedDeclarations,
  withPreservedDeclarations,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Prepare and submit a transaction, including any SubTxs it contains, to the test
-- ledger, requiring acceptance.
-- Check that preparation preserves the declarations and implicit-output fixture.
-- An accepted transaction updates the test ledger state.
submitTxAndExpectSuccess :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectSuccess batch = withPreservedDeclarations batch $ submitTx_ batch

-- | Capture the state after fixture funding and fixup, immediately before the
-- submitted batch. Funding transactions are not part of the rejection assertion.
submitTxAndExpectRejection ::
  DijkstraUtxoPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectRejection expectedFailure batch = do
  fixed <- fixupTx batch
  checkPreservedDeclarations batch fixed
  submitPreparedTxAndExpectRejection expectedFailure fixed

-- | Use a finalized batch as supplied, including its declared phase-2 outcome.
submitPreparedTxAndExpectAcceptance :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedTxAndExpectAcceptance batch = withNoFixup $ submitTxAndExpectSuccess batch

-- | Require the exact rejection and unchanged ledger state after fixture preparation.
submitPreparedTxAndExpectRejection ::
  DijkstraUtxoPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedTxAndExpectRejection expectedFailure batch = do
  before <- getsNES $ nesEsL . esLStateL
  withNoFixup $
    withPreservedDeclarations batch $
      submitFailingTx
        batch
        (injectFailure expectedFailure :| [])
  after <- getsNES $ nesEsL . esLStateL
  after `shouldBe` before
