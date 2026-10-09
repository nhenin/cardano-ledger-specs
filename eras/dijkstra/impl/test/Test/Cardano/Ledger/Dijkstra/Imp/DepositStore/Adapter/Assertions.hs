{-# LANGUAGE DataKinds #-}

module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Assertions (
  conformsTo,
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
import Test.Cardano.Ledger.Common (Property, (===))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Transaction (
  checkPreservedDeclarations,
  withPreservedDeclarations,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Compare an implementation with an independent domain rule on the same input.
-- Compare the complete results, including the specific failure when rejected.
-- The fixture generator supplies the input and reports it if the comparison fails.
conformsTo ::
  (Eq result, Show result) => (input -> result) -> (input -> result) -> input -> Property
conformsTo implementation rule input = implementation input === rule input

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
