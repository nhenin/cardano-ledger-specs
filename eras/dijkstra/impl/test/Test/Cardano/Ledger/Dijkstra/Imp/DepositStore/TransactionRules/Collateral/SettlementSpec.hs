-- | Collateral inputs and the specified return determine settlement without an ordinary declaration.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.SettlementSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- Applied ledger effects, balances and allocated records belong to State specs.
-- Full-ledger comparisons require independently valid ordinary declarations.
-- Without a return, accepted fixtures contain no collateral native assets.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-SETTLEMENT - Settlement" $ do
  it "DS-COLLATERAL-SETTLEMENT-N01 - derives Store changes from collateral inputs and return without a separate declaration" derivesSettlementFromCollateral
  prop "DS-COLLATERAL-SETTLEMENT-P01 - derived collateral Store change is independent of ordinary Store declarations" ordinaryDeclarationsCannotChangeSettlement
  it "DS-COLLATERAL-SETTLEMENT-N02 - derives the released Store amount from multiple ADA-only collateral inputs with no return" derivesReleaseWithoutReturn
{- FOURMOLU_ENABLE -}

derivesSettlementFromCollateral :: Expectation
derivesSettlementFromCollateral = False `shouldBe` True

ordinaryDeclarationsCannotChangeSettlement :: Bool
ordinaryDeclarationsCannotChangeSettlement = False

derivesReleaseWithoutReturn :: Expectation
derivesReleaseWithoutReturn = False `shouldBe` True
