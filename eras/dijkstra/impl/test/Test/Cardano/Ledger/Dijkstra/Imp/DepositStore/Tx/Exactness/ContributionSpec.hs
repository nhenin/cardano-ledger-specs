-- | Contribution requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Exactness.ContributionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-EXACTNESS-CONTRIBUTION - Contribution" $ do
    prop "DS-TX-EXACTNESS-CONTRIBUTION-P01 - ∀ s ∈ SubTxs: hasDeclaration(s) ⇒ declaredNetUTxODepositChange(s) = allocatedUTxODeposits(s) - releasedUTxODeposits(s)" subTxDeclarationEqualsAllocatedMinusReleasedDeposits
    it "DS-TX-EXACTNESS-CONTRIBUTION-N01 - accepts a contribution equal to allocated UTxO capacity deposits minus released UTxO capacity deposits" exactContributionIsAccepted
    it "DS-TX-EXACTNESS-CONTRIBUTION-F01 - rejects a net allocation one lovelace below the required contribution" understatedAllocationIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F02 - rejects a net allocation one lovelace above the required contribution" overstatedAllocationIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F03 - rejects a net release one lovelace below the required contribution" understatedReleaseIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F04 - rejects a net release one lovelace above the required contribution" overstatedReleaseIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F05 - rejects opposing declaration errors even when they cancel in the batch total" opposingDeclarationErrorsAreRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-N02 - checks TopTx's own UTxO capacity deposit contribution separately from SubTx contributions" topTxContributionIsCheckedSeparately
    it "DS-TX-EXACTNESS-CONTRIBUTION-N03 - accepts an explicit zero when the declared UTxO capacity deposit contribution is zero" zeroContributionAcceptsExplicitZero
    it "DS-TX-EXACTNESS-CONTRIBUTION-F06 - rejects an explicit zero when a net allocation must be funded" requiredAllocationRejectsExplicitZero
    it "DS-TX-EXACTNESS-CONTRIBUTION-N04 - checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change" delegatedAllocationMatchesSubTxNetChange
    it "DS-TX-EXACTNESS-CONTRIBUTION-N05 - checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change" delegatedReleaseMatchesSubTxNetChange
    it "DS-TX-EXACTNESS-CONTRIBUTION-N06 - requires a net release when a body spends store-backed outputs and creates only implicit outputs" spendingLastStoreBackedOutputRequiresRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-F07 - rejects an explicit zero when that body must release UTxO capacity deposits" zeroDeclarationCannotReplaceRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-N07 - preserves that body's net release even when another body's net allocation offsets it" anotherBodyAllocationDoesNotCancelOwnRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-N08 - still requires the exact UTxO capacity deposit for an output with no application assets" emptyApplicationAssetsStillRequireExactDeposit
    it "DS-TX-EXACTNESS-CONTRIBUTION-N09 - accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding" fundsPostConwayStoreBackedOutputsExactly
    it "DS-TX-EXACTNESS-CONTRIBUTION-F08 - rejects an inexact allocation when spending a translated implicit output to create store-backed outputs" rejectsInexactPostConwayAllocation
    it "DS-TX-EXACTNESS-CONTRIBUTION-F09 - rejects an unrelated release from pre-existing Store surplus" rejectsUnrelatedReleaseFromStoreSurplus
{- FOURMOLU_ENABLE -}

-- | ∀ s ∈ SubTxs: hasDeclaration(s) ⇒ declaredNetUTxODepositChange(s) = allocatedUTxODeposits(s) - releasedUTxODeposits(s)
-- Executable backlog: replace with a ledger check against independent expectations.
subTxDeclarationEqualsAllocatedMinusReleasedDeposits :: Bool
subTxDeclarationEqualsAllocatedMinusReleasedDeposits = False

-- | Accepts a contribution equal to allocated UTxO capacity deposits minus released UTxO capacity deposits
-- Executable backlog: replace with a ledger check against independent expectations.
exactContributionIsAccepted :: Expectation
exactContributionIsAccepted = False `shouldBe` True

-- | Rejects a net allocation one lovelace below the required contribution
-- Executable backlog: replace with a ledger check against independent expectations.
understatedAllocationIsRejected :: Expectation
understatedAllocationIsRejected = False `shouldBe` True

-- | Rejects a net allocation one lovelace above the required contribution
-- Executable backlog: replace with a ledger check against independent expectations.
overstatedAllocationIsRejected :: Expectation
overstatedAllocationIsRejected = False `shouldBe` True

-- | Rejects a net release one lovelace below the required contribution
-- Executable backlog: replace with a ledger check against independent expectations.
understatedReleaseIsRejected :: Expectation
understatedReleaseIsRejected = False `shouldBe` True

-- | Rejects a net release one lovelace above the required contribution
-- Executable backlog: replace with a ledger check against independent expectations.
overstatedReleaseIsRejected :: Expectation
overstatedReleaseIsRejected = False `shouldBe` True

-- | Rejects opposing declaration errors even when they cancel in the batch total
-- Executable backlog: replace with a ledger check against independent expectations.
opposingDeclarationErrorsAreRejected :: Expectation
opposingDeclarationErrorsAreRejected = False `shouldBe` True

-- | Checks TopTx's own UTxO capacity deposit contribution separately from SubTx contributions
-- Executable backlog: replace with a ledger check against independent expectations.
topTxContributionIsCheckedSeparately :: Expectation
topTxContributionIsCheckedSeparately = False `shouldBe` True

-- | Accepts an explicit zero when the declared UTxO capacity deposit contribution is zero
-- Executable backlog: replace with a ledger check against independent expectations.
zeroContributionAcceptsExplicitZero :: Expectation
zeroContributionAcceptsExplicitZero = False `shouldBe` True

-- | Rejects an explicit zero when a net allocation must be funded
-- Executable backlog: replace with a ledger check against independent expectations.
requiredAllocationRejectsExplicitZero :: Expectation
requiredAllocationRejectsExplicitZero = False `shouldBe` True

-- | Checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change
-- Executable backlog: replace with a ledger check against independent expectations.
delegatedAllocationMatchesSubTxNetChange :: Expectation
delegatedAllocationMatchesSubTxNetChange = False `shouldBe` True

-- | Checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change
-- Executable backlog: replace with a ledger check against independent expectations.
delegatedReleaseMatchesSubTxNetChange :: Expectation
delegatedReleaseMatchesSubTxNetChange = False `shouldBe` True

-- | Requires a net release when a body spends store-backed outputs and creates only implicit outputs
-- Executable backlog: replace with a ledger check against independent expectations.
spendingLastStoreBackedOutputRequiresRelease :: Expectation
spendingLastStoreBackedOutputRequiresRelease = False `shouldBe` True

-- | Rejects an explicit zero when that body must release UTxO capacity deposits
-- Executable backlog: replace with a ledger check against independent expectations.
zeroDeclarationCannotReplaceRelease :: Expectation
zeroDeclarationCannotReplaceRelease = False `shouldBe` True

-- | Preserves that body's net release even when another body's net allocation offsets it
-- Executable backlog: replace with a ledger check against independent expectations.
anotherBodyAllocationDoesNotCancelOwnRelease :: Expectation
anotherBodyAllocationDoesNotCancelOwnRelease = False `shouldBe` True

-- | Still requires the exact UTxO capacity deposit for an output with no application assets
-- Executable backlog: replace with a ledger check against independent expectations.
emptyApplicationAssetsStillRequireExactDeposit :: Expectation
emptyApplicationAssetsStillRequireExactDeposit = False `shouldBe` True

-- | Accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding
-- Executable backlog: replace with a ledger check against independent expectations.
fundsPostConwayStoreBackedOutputsExactly :: Expectation
fundsPostConwayStoreBackedOutputsExactly = False `shouldBe` True

-- | Rejects an inexact allocation when spending a translated implicit output to create store-backed outputs
-- Executable backlog: replace with a ledger check against independent expectations.
rejectsInexactPostConwayAllocation :: Expectation
rejectsInexactPostConwayAllocation = False `shouldBe` True

-- | Rejects an unrelated release from pre-existing Store surplus
-- Executable backlog: replace with a ledger check against independent expectations.
rejectsUnrelatedReleaseFromStoreSurplus :: Expectation
rejectsUnrelatedReleaseFromStoreSurplus = False `shouldBe` True
