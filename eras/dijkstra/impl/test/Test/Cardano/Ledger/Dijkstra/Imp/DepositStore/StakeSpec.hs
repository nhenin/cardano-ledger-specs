module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.StakeSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Intentionally failing placeholders for the agreed DepositStore rules.
-- Replace each placeholder with a ledger check against independent expectations.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "External UTxO capacity deposits contribute no stake or voting power (DS-STAKE-001)" $ do
  it "counts the full ADA in implicit outputs under the existing staking rules" countsFullImplicitOutputADA
  it "counts only application ADA in store-backed outputs under the existing staking rules" countsOnlyStoreBackedApplicationADA
  it "does not count allocated UTxO capacity deposits or Store balance as additional voting power" excludesDepositsFromVotingPower
  it "still counts Store ADA in total monetary conservation" includesStoreInMonetaryConservation
  it "does not add the global Store balance to stake totals" excludesStoreBalanceFromStake
  it "ordinary success ⇒ a net allocation changes stake only through its applied ordinary UTxO effects" allocationStakeFollowsAppliedOutputs
  it "ordinary success ⇒ a net release changes stake only through its applied ordinary UTxO effects" releaseStakeFollowsAppliedOutputs
  it "ordinary success ⇒ unapplied collateral settlement and collateral return add no stake effects" successExcludesUnappliedCollateralStake
  it "accepted phase-2 failure ⇒ stake follows collateral consumption and return without effects from unapplied ordinary allocations, releases or outputs" failureStakeFollowsOnlyCollateral
  it "preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects" preservesExistingStakeUpdateRules
{- FOURMOLU_ENABLE -}

countsFullImplicitOutputADA :: Expectation
countsFullImplicitOutputADA = False `shouldBe` True

countsOnlyStoreBackedApplicationADA :: Expectation
countsOnlyStoreBackedApplicationADA = False `shouldBe` True

excludesDepositsFromVotingPower :: Expectation
excludesDepositsFromVotingPower = False `shouldBe` True

includesStoreInMonetaryConservation :: Expectation
includesStoreInMonetaryConservation = False `shouldBe` True

excludesStoreBalanceFromStake :: Expectation
excludesStoreBalanceFromStake = False `shouldBe` True

allocationStakeFollowsAppliedOutputs :: Expectation
allocationStakeFollowsAppliedOutputs = False `shouldBe` True

releaseStakeFollowsAppliedOutputs :: Expectation
releaseStakeFollowsAppliedOutputs = False `shouldBe` True

successExcludesUnappliedCollateralStake :: Expectation
successExcludesUnappliedCollateralStake = False `shouldBe` True

failureStakeFollowsOnlyCollateral :: Expectation
failureStakeFollowsOnlyCollateral = False `shouldBe` True

preservesExistingStakeUpdateRules :: Expectation
preservesExistingStakeUpdateRules = False `shouldBe` True
