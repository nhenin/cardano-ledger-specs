-- | Collateral validation and settlement responsibilities.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.CollateralSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.AuthorizationSpec as Authorization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.FundingSpec as Funding
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.ScopeSpec as Scope
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.SettlementSpec as Settlement
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.SurplusSpec as Surplus
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.TotalSpec as Total

spec :: Spec
spec = describe "Collateral" $ do
  Scope.spec
  Authorization.spec
  Funding.spec
  Surplus.spec
  Total.spec
  Settlement.spec
  Conservation.spec
