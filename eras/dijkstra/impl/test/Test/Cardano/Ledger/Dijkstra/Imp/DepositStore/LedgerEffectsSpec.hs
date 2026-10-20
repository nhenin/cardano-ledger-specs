module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffectsSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.AllocationsSpec as Allocations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.BalanceSpec as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.ExecutionSpec as Execution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.FeesSpec as Fees
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.InitializationSpec as Initialization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.RecoverySpec as Recovery
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.SolvencySpec as Solvency

-- | Applied effects and invariants of the accepted ledger state.
spec :: Spec
spec = describe "Ledger effects" $ do
  Execution.spec
  Allocations.spec
  Balance.spec
  Fees.spec
  Solvency.spec
  Conservation.spec
  Initialization.spec
  Recovery.spec
