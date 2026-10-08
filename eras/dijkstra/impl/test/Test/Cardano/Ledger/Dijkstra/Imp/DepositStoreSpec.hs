module Test.Cardano.Ledger.Dijkstra.Imp.DepositStoreSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.AccountingSpec as CollateralAccounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.TotalCollateralSpec as TotalCollateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.TransitionSpec as CollateralTransition
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.ValidationSpec as CollateralValidation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.StakeSpec as Stake
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.ConwayTransitionSpec as ConwayTransition
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.LiveUTxOSpec as LiveUTxO
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.PricingSpec as Pricing
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.SolvencySpec as Solvency
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ApplicationAssetsSpec as ApplicationAssets
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DeclarationDependencySpec as DeclarationDependency
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DeclarationSpec as Declaration
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DelegationSpec as Delegation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ExactAccountingSpec as ExactAccounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ExplicitZeroSpec as ExplicitZero
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.FinalReleaseSpec as FinalRelease
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.NettingSpec as Netting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ReleaseAuthoritySpec as ReleaseAuthority
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.SettlementOutputsSpec as SettlementOutputs
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.TopTxSettlementSpec as TopTxSettlement
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ValueConservationSpec as ValueConservation

-- | Executable backlog for docs/dijkstra-deposit-store-rules.md.
-- Each domain rule owns its properties and concrete cases. Every assertion
-- deliberately fails until implemented against the ledger; these placeholders
-- do not exercise ledger validation yet. All other ledger rules are assumed
-- satisfied in each case.
--
-- Compare ledger decisions and observed state with independent model results.
-- Do not turn a model definition into a test that merely compares it to itself.
-- Mathematical notation is defined in the document's domain model section.
spec :: Spec
spec = describe "DepositStore" $ do
  Declaration.spec
  Netting.spec
  ExactAccounting.spec
  ValueConservation.spec
  FinalRelease.spec
  TopTxSettlement.spec
  SettlementOutputs.spec
  ExplicitZero.spec
  DeclarationDependency.spec
  Delegation.spec
  ReleaseAuthority.spec
  ApplicationAssets.spec
  CollateralValidation.spec
  CollateralAccounting.spec
  TotalCollateral.spec
  CollateralTransition.spec
  Solvency.spec
  Pricing.spec
  ConwayTransition.spec
  LiveUTxO.spec
  Stake.spec

-- Deferred: DS-STORE-002 parameter changes, DS-PLUTUS-001 context projection,
-- and any stronger DS-TX-007 settlement guarantee beyond the agreed checks.
