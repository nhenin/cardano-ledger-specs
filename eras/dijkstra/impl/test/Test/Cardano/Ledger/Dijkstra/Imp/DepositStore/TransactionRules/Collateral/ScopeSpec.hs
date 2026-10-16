-- | Redeemers in any transaction body activate the collateral requirement.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.ScopeSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- The trigger applies to presence, funding and supplied-total checks. Input lookup,
-- output validity and collateral-count limits retain their independent scope.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-SCOPE - Scope" $ do
  it "DS-COLLATERAL-SCOPE-F01 - rejects TopTx redeemers without collateral" requiresCollateralForTopTxRedeemers
  it "DS-COLLATERAL-SCOPE-F02 - rejects SubTx redeemers without collateral even when TopTx has none" requiresCollateralForSubTxRedeemers
  it "DS-COLLATERAL-SCOPE-F03 - rejects redeemers in both TopTx and SubTxs without collateral" requiresCollateralForBothRedeemers
  it "DS-COLLATERAL-SCOPE-N01 - does not require collateral merely because a transaction uses the DepositStore" storeActivityAloneNeedsNoCollateral
  it "DS-COLLATERAL-SCOPE-N02 - does not apply redeemer-gated funding or supplied-total checks when no body has redeemers" noRedeemersSkipGatedCollateralChecks
  it "DS-COLLATERAL-SCOPE-F04 - rejects independently invalid collateral inputs or returns without redeemers" noRedeemersPreserveIndependentCollateralChecks
{- FOURMOLU_ENABLE -}

requiresCollateralForTopTxRedeemers :: Expectation
requiresCollateralForTopTxRedeemers = False `shouldBe` True

requiresCollateralForSubTxRedeemers :: Expectation
requiresCollateralForSubTxRedeemers = False `shouldBe` True

requiresCollateralForBothRedeemers :: Expectation
requiresCollateralForBothRedeemers = False `shouldBe` True

storeActivityAloneNeedsNoCollateral :: Expectation
storeActivityAloneNeedsNoCollateral = False `shouldBe` True

noRedeemersSkipGatedCollateralChecks :: Expectation
noRedeemersSkipGatedCollateralChecks = False `shouldBe` True

noRedeemersPreserveIndependentCollateralChecks :: Expectation
noRedeemersPreserveIndependentCollateralChecks = False `shouldBe` True
