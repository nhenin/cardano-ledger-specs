-- | Collateral inputs and the specified return determine settlement without an ordinary declaration.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.SettlementSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- Applied ledger effects, balances and allocated records belong to State specs.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-SETTLEMENT - Settlement" $ do
  it "DS-COLLATERAL-SETTLEMENT-N01 - derives Store changes from collateral inputs and return without a separate declaration" derivesSettlementFromCollateral
  it "DS-COLLATERAL-SETTLEMENT-P01 - does not let ordinary Store declarations change collateral settlement" ordinaryDeclarationsCannotChangeSettlement
  it "DS-COLLATERAL-SETTLEMENT-N02 - settles multiple collateral inputs with no return output" settlesInputsWithoutReturn
{- FOURMOLU_ENABLE -}

derivesSettlementFromCollateral :: Expectation
derivesSettlementFromCollateral = False `shouldBe` True

ordinaryDeclarationsCannotChangeSettlement :: Expectation
ordinaryDeclarationsCannotChangeSettlement = False `shouldBe` True

settlesInputsWithoutReturn :: Expectation
settlesInputsWithoutReturn = False `shouldBe` True
