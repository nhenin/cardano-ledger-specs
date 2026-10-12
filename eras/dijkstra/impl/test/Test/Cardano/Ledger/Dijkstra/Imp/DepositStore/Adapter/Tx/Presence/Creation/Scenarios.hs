{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Execute each creation-presence scenario against fresh ledger state.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Scenarios (
  ExpectedSubmission (..),
  outputCreationScenarios,
) where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (IsPhase2Valid (..), injectFailure, isPhase2ValidTxL)
import Cardano.Ledger.Dijkstra.Rules (DijkstraSubUtxoPredFailure, DijkstraUtxoPredFailure)
import Lens.Micro ((&), (.~))
import Test.Cardano.Ledger.Common (Spec, forM_, it)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Assertions (
  checkPreservedCreationFixture,
  submitPreparedRejection,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Fixture as Fixture
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Transaction (
  buildTxWithCreatedOutputs,
  preparePhase2InvalidTx,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (LedgerSpec, fixupTx, submitTx_, withNoFixup)
import Test.Cardano.Ledger.Imp.Common (withImpInit)

-- | The exact submission result stated by each scenario.
data ExpectedSubmission
  = Accepted
  | RejectedTopTx (DijkstraUtxoPredFailure DijkstraEra)
  | RejectedSubTx (DijkstraSubUtxoPredFailure DijkstraEra)

-- | Register one fresh ledger test per row. Store-backed fixtures are submitted
-- only for rejection; fee and application-asset balancing does not fund a capacity
-- deposit. Accepted controls contain only implicit-deposit outputs.
outputCreationScenarios :: [(String, Fixture.TxOutputs, IsPhase2Valid, ExpectedSubmission)] -> Spec
outputCreationScenarios scenarios =
  withImpInit @(LedgerSpec DijkstraEra) $
    forM_ scenarios $ \(requirement, outputs, phase2, expected) ->
      it requirement $ do
        prepared <- buildTxWithCreatedOutputs outputs
        fixed <- case phase2 of
          Phase2Valid -> fixupTx prepared
          Phase2Invalid -> preparePhase2InvalidTx prepared
        checkPreservedCreationFixture (prepared & isPhase2ValidTxL .~ phase2) fixed
        case expected of
          Accepted -> withNoFixup $ submitTx_ fixed
          RejectedTopTx failure -> submitPreparedRejection (injectFailure failure) fixed
          RejectedSubTx failure -> submitPreparedRejection (injectFailure failure) fixed
