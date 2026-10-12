module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.StakeSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Eligible outputs contribute their application ADA under the existing stake update rules.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STAKE - Stake" $ do
  it "DS-STAKE-N01 - counts the full ADA in implicit outputs under the existing staking rules" countsFullImplicitOutputADA
  it "DS-STAKE-N02 - counts only application ADA in store-backed outputs under the existing staking rules" countsOnlyStoreBackedApplicationADA
  it "DS-STAKE-N03 - does not add the global Store balance to stake totals" excludesStoreBalanceFromStake
  it "DS-STAKE-N04 - ordinary success ⇒ a net allocation changes stake only through its applied ordinary UTxO effects" allocationStakeFollowsAppliedOutputs
  it "DS-STAKE-N05 - ordinary success ⇒ a net release changes stake only through its applied ordinary UTxO effects" releaseStakeFollowsAppliedOutputs
  it "DS-STAKE-N06 - ordinary success ⇒ unapplied collateral settlement and collateral return add no stake effects" successExcludesUnappliedCollateralStake
  it "DS-STAKE-N07 - accepted phase-2 failure ⇒ stake follows collateral consumption and return without effects from unapplied ordinary allocations, releases or outputs" failureStakeFollowsOnlyCollateral
  it "DS-STAKE-N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects" preservesExistingStakeUpdateRules
{- FOURMOLU_ENABLE -}

countsFullImplicitOutputADA :: Expectation
countsFullImplicitOutputADA = False `shouldBe` True

countsOnlyStoreBackedApplicationADA :: Expectation
countsOnlyStoreBackedApplicationADA = False `shouldBe` True

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
