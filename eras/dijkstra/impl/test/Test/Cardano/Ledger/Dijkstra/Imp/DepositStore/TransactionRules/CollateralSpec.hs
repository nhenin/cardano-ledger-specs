-- | Collateral validation and settlement responsibilities.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.CollateralSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.AuthorizationSpec as Authorization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.FundingSpec as Funding
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.ScopeSpec as Scope
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.SettlementSpec as Settlement
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.SurplusSpec as Surplus
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.TotalSpec as Total

spec :: Spec
spec = describe "Collateral" $ do
  Scope.spec
  Authorization.spec
  Funding.spec
  Surplus.spec
  Total.spec
  Settlement.spec
  Conservation.spec
