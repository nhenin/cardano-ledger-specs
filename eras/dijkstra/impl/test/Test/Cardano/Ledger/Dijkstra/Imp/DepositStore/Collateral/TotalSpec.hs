-- | A supplied total declares collateral input coins minus return coins.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.TotalSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-TOTAL - Total" $ do
  it "DS-COLLATERAL-TOTAL-N01 - accepts a declared total equal to collateral input coins minus return coins" acceptsExactTotalCollateral
  it "DS-COLLATERAL-TOTAL-F01 - rejects a declared total differing by one lovelace when collateral validation applies" rejectsOneLovelaceTotalMismatch
  it "DS-COLLATERAL-TOTAL-F02 - rejects an incorrect supplied total when redeemers trigger collateral validation even if all scripts succeed" successfulScriptsDoNotBypassTotalCollateralCheck
  it "DS-COLLATERAL-TOTAL-N02 - includes coins funding additional UTxO capacity deposits in the declared total" includesAdditionalDepositFunding
  it "DS-COLLATERAL-TOTAL-N03 - excludes UTxO capacity deposits released from the Store from the declared total" excludesReleasedDeposits
{- FOURMOLU_ENABLE -}

acceptsExactTotalCollateral :: Expectation
acceptsExactTotalCollateral = False `shouldBe` True

rejectsOneLovelaceTotalMismatch :: Expectation
rejectsOneLovelaceTotalMismatch = False `shouldBe` True

successfulScriptsDoNotBypassTotalCollateralCheck :: Expectation
successfulScriptsDoNotBypassTotalCollateralCheck = False `shouldBe` True

includesAdditionalDepositFunding :: Expectation
includesAdditionalDepositFunding = False `shouldBe` True

excludesReleasedDeposits :: Expectation
excludesReleasedDeposits = False `shouldBe` True
