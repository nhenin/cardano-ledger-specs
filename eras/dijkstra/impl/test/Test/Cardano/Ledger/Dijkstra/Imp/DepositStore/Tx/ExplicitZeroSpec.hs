module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ExplicitZeroSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- PositiveCoin construction and codec bounds are covered in Binary.Golden.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-008 - Explicit zero is different from an absent declaration" $ do
    it "accepts an explicit zero when the declared UTxO capacity deposit contribution is zero" zeroContributionAcceptsExplicitZero
    it "rejects an explicit zero when a net allocation must be funded" requiredAllocationRejectsExplicitZero
    it "does not interpret an explicit SubTx zero as a delegation request" explicitZeroDoesNotDelegate
{- FOURMOLU_ENABLE -}

zeroContributionAcceptsExplicitZero :: Expectation
zeroContributionAcceptsExplicitZero = False `shouldBe` True

requiredAllocationRejectsExplicitZero :: Expectation
requiredAllocationRejectsExplicitZero = False `shouldBe` True

explicitZeroDoesNotDelegate :: Expectation
explicitZeroDoesNotDelegate = False `shouldBe` True
