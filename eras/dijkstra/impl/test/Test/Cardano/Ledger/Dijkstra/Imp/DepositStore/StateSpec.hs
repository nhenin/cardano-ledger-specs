module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.StateSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.AllocationsSpec as Allocations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.BalanceSpec as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.ExecutionSpec as Execution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.InitializationSpec as Initialization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.RecoverySpec as Recovery
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.SolvencySpec as Solvency

-- | Applied effects and invariants of the accepted ledger state.
spec :: Spec
spec = describe "State" $ do
  Execution.spec
  Allocations.spec
  Balance.spec
  Solvency.spec
  Conservation.spec
  Initialization.spec
  Recovery.spec
