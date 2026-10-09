{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Execute declaration scenarios against the test ledger, keeping transaction
-- preparation and submission mechanics outside the domain specification.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.DeclarationScenarios (
  ExpectedSubmission (..),
  declarationScenarios,
) where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (IsPhase2Valid (..))
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure)
import Test.Cardano.Ledger.Common (Spec, forM_, it)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Assertions (
  submitPreparedTxAndExpectAcceptance,
  submitPreparedTxAndExpectRejection,
  submitTxAndExpectRejection,
  submitTxAndExpectSuccess,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.DeclarationDependency as Fixture
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Transaction (
  buildTxWithUTxODepositDeclarations,
  preparePhase2InvalidBatch,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (LedgerSpec)
import Test.Cardano.Ledger.Imp.Common (withImpInit)

-- | The expected ledger submission result, stated independently in each row.
data ExpectedSubmission
  = Accepted
  | Rejected (DijkstraUtxoPredFailure DijkstraEra)

-- | Register each row as a separate named test with fresh ledger state.
-- Rows contain the requirement, a declarations fixture,
-- phase-2 outcome and expected submission result.
--
-- Build funded transactions with implicit-deposit outputs and no Store activity,
-- preserving the declarations. For phase-2-invalid rows, prepare a failing script
-- and collateral before submission. Rejection checks also require unchanged state.
declarationScenarios ::
  [ ( String
    , Fixture.Declarations
    , IsPhase2Valid
    , ExpectedSubmission
    )
  ] ->
  Spec
declarationScenarios scenarios =
  withImpInit @(LedgerSpec DijkstraEra) $
    forM_ scenarios $ \(requirement, declarations, phase2, expected) ->
      it requirement $ case (phase2, expected) of
        (Phase2Valid, Accepted) ->
          buildTxWithUTxODepositDeclarations declarations >>= submitTxAndExpectSuccess
        (Phase2Valid, Rejected failure) ->
          buildTxWithUTxODepositDeclarations declarations >>= submitTxAndExpectRejection failure
        (Phase2Invalid, Accepted) ->
          buildTxWithUTxODepositDeclarations declarations
            >>= preparePhase2InvalidBatch
            >>= submitPreparedTxAndExpectAcceptance
        (Phase2Invalid, Rejected failure) ->
          buildTxWithUTxODepositDeclarations declarations
            >>= preparePhase2InvalidBatch
            >>= submitPreparedTxAndExpectRejection failure
