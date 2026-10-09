module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.TotalCollateralSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLL-003 - Total collateral keeps its input-minus-return meaning" $ do
  it "accepts a declared total equal to collateral input coins minus return coins" acceptsExactTotalCollateral
  it "rejects a declared total differing by one lovelace when collateral validation applies" rejectsOneLovelaceTotalMismatch
  it "rejects an incorrect supplied total when redeemers trigger collateral validation even if all scripts succeed" successfulScriptsDoNotBypassTotalCollateralCheck
  it "includes coins funding additional UTxO capacity deposits in the declared total" includesAdditionalDepositFunding
  it "excludes UTxO capacity deposits released from the Store from the declared total" excludesReleasedDeposits
  it "still checks collateral funding when the optional total is absent" checksFundingWithoutDeclaredTotal
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

checksFundingWithoutDeclaredTotal :: Expectation
checksFundingWithoutDeclaredTotal = False `shouldBe` True
