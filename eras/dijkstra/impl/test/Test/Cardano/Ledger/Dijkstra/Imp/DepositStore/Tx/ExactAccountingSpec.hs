module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ExactAccountingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-003 - Each body's UTxO capacity deposit declaration is exact" $ do
    prop "∀ s ∈ SubTxs: hasDeclaration(s) ⇒ declaredNetUTxODepositChange(s) = allocatedUTxODeposits(s) - releasedUTxODeposits(s)" subTxDeclarationEqualsAllocatedMinusReleasedDeposits
    it "accepts a contribution equal to allocated UTxO capacity deposits minus released UTxO capacity deposits" exactContributionIsAccepted
    it "rejects a net allocation one lovelace below the required contribution" understatedAllocationIsRejected
    it "rejects a net allocation one lovelace above the required contribution" overstatedAllocationIsRejected
    it "rejects a net release one lovelace below the required contribution" understatedReleaseIsRejected
    it "rejects a net release one lovelace above the required contribution" overstatedReleaseIsRejected
    it "rejects opposing declaration errors even when they cancel in the batch total" opposingDeclarationErrorsAreRejected
    it "checks TopTx's own UTxO capacity deposit contribution separately from SubTx contributions" topTxContributionIsCheckedSeparately
{- FOURMOLU_ENABLE -}

subTxDeclarationEqualsAllocatedMinusReleasedDeposits :: Bool
subTxDeclarationEqualsAllocatedMinusReleasedDeposits = False

exactContributionIsAccepted :: Expectation
exactContributionIsAccepted = False `shouldBe` True

understatedAllocationIsRejected :: Expectation
understatedAllocationIsRejected = False `shouldBe` True

overstatedAllocationIsRejected :: Expectation
overstatedAllocationIsRejected = False `shouldBe` True

understatedReleaseIsRejected :: Expectation
understatedReleaseIsRejected = False `shouldBe` True

overstatedReleaseIsRejected :: Expectation
overstatedReleaseIsRejected = False `shouldBe` True

opposingDeclarationErrorsAreRejected :: Expectation
opposingDeclarationErrorsAreRejected = False `shouldBe` True

topTxContributionIsCheckedSeparately :: Expectation
topTxContributionIsCheckedSeparately = False `shouldBe` True
