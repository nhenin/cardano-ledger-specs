-- | Contribution requirements, retained as executable backlog until implemented.
--
-- Contract: compare the isolated contribution validator with independently
-- calculated required own changes, using resolved input allocation records and
-- new output prices. Direct declarations here are SubTx contributions. TopTx
-- declares the batch total; its own contribution is only a derived diagnostic.
-- Exercise exact, too-small, too-large, zero and wrong-sign amounts in local and
-- delegated forms on both phase-2 outcomes. Full-ledger rejection fixtures keep
-- batch conservation valid or assert the specific contribution failure.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Exactness.ContributionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-EXACTNESS-CONTRIBUTION - Contribution" $ do
    prop "DS-TX-EXACTNESS-CONTRIBUTION-P01 - passes contribution validation ⇔ each declared SubTx change equals its required own deposit change" subTxDeclarationEqualsAllocatedMinusReleasedDeposits
    it "DS-TX-EXACTNESS-CONTRIBUTION-N01 - accepts a SubTx contribution equal to its allocated deposits minus its released deposits" exactContributionIsAccepted
    it "DS-TX-EXACTNESS-CONTRIBUTION-F01 - rejects a SubTx net allocation one lovelace below its required amount" understatedAllocationIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F02 - rejects a SubTx net allocation one lovelace above its required amount" overstatedAllocationIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F03 - rejects a SubTx net release one lovelace below its required amount" understatedReleaseIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F04 - rejects a SubTx net release one lovelace above its required amount" overstatedReleaseIsRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-F05 - rejects opposing SubTx declaration errors even when they cancel in the batch total" opposingDeclarationErrorsAreRejected
    it "DS-TX-EXACTNESS-CONTRIBUTION-N02 - derives TopTx's own contribution by removing all SubTx contributions from its declared batch total" topTxOwnContributionIsDerivedFromBatchTotal
    it "DS-TX-EXACTNESS-CONTRIBUTION-N03 - accepts a SubTx explicit zero when its required own deposit change is zero" zeroContributionAcceptsExplicitZero
    it "DS-TX-EXACTNESS-CONTRIBUTION-F06 - rejects a SubTx explicit zero when its required own deposit change is positive" requiredAllocationRejectsExplicitZero
    it "DS-TX-EXACTNESS-CONTRIBUTION-N04 - checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change" delegatedAllocationMatchesSubTxNetChange
    it "DS-TX-EXACTNESS-CONTRIBUTION-N05 - checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change" delegatedReleaseMatchesSubTxNetChange
    it "DS-TX-EXACTNESS-CONTRIBUTION-N06 - requires a SubTx net release when it spends store-backed outputs and creates only implicit outputs" spendingLastStoreBackedOutputRequiresRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-F07 - rejects a SubTx explicit zero when its required own deposit change is negative" zeroDeclarationCannotReplaceRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-N07 - preserves a SubTx's declared net release when another body's allocation offsets it" anotherBodyAllocationDoesNotCancelOwnRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-N08 - still requires the exact UTxO capacity deposit for an output with no application assets" emptyApplicationAssetsStillRequireExactDeposit
    it "DS-TX-EXACTNESS-CONTRIBUTION-N09 - accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding" fundsPostConwayStoreBackedOutputsExactly
    it "DS-TX-EXACTNESS-CONTRIBUTION-F08 - rejects an inexact allocation when spending a translated implicit output to create store-backed outputs" rejectsInexactPostConwayAllocation
    it "DS-TX-EXACTNESS-CONTRIBUTION-F09 - rejects an unrelated release from pre-existing Store surplus" rejectsUnrelatedReleaseFromStoreSurplus
    it "DS-TX-EXACTNESS-CONTRIBUTION-F10 - rejects a SubTx release when its required own deposit change is positive" releaseCannotReplaceSubTxAllocation
    it "DS-TX-EXACTNESS-CONTRIBUTION-F11 - rejects a SubTx allocation when its required own deposit change is negative" allocationCannotReplaceSubTxRelease
    it "DS-TX-EXACTNESS-CONTRIBUTION-N10 - accepts exact SubTx contributions on the phase-2 failure path" exactSubTxContributionsPassOnPhase2Failure
    it "DS-TX-EXACTNESS-CONTRIBUTION-F12 - rejects an inexact SubTx contribution even when phase 2 fails" inexactSubTxContributionFailsOnPhase2Failure
{- FOURMOLU_ENABLE -}

-- | passes contribution validation ⇔ each declared SubTx change equals its required own deposit change
-- Executable backlog: replace with a ledger check against independent expectations.
subTxDeclarationEqualsAllocatedMinusReleasedDeposits :: Bool
subTxDeclarationEqualsAllocatedMinusReleasedDeposits = False

-- | Accepts a SubTx contribution equal to its allocated deposits minus its released deposits
-- Executable backlog: replace with a ledger check against independent expectations.
exactContributionIsAccepted :: Expectation
exactContributionIsAccepted = False `shouldBe` True

-- | Rejects a SubTx net allocation one lovelace below its required amount
-- Executable backlog: replace with a ledger check against independent expectations.
understatedAllocationIsRejected :: Expectation
understatedAllocationIsRejected = False `shouldBe` True

-- | Rejects a SubTx net allocation one lovelace above its required amount
-- Executable backlog: replace with a ledger check against independent expectations.
overstatedAllocationIsRejected :: Expectation
overstatedAllocationIsRejected = False `shouldBe` True

-- | Rejects a SubTx net release one lovelace below its required amount
-- Executable backlog: replace with a ledger check against independent expectations.
understatedReleaseIsRejected :: Expectation
understatedReleaseIsRejected = False `shouldBe` True

-- | Rejects a SubTx net release one lovelace above its required amount
-- Executable backlog: replace with a ledger check against independent expectations.
overstatedReleaseIsRejected :: Expectation
overstatedReleaseIsRejected = False `shouldBe` True

-- | Rejects opposing SubTx declaration errors even when they cancel in the batch total
-- Executable backlog: replace with a ledger check against independent expectations.
opposingDeclarationErrorsAreRejected :: Expectation
opposingDeclarationErrorsAreRejected = False `shouldBe` True

-- | Derives TopTx's own contribution by removing all SubTx contributions from its declared batch total
-- Executable backlog: replace with a ledger check against independent expectations.
topTxOwnContributionIsDerivedFromBatchTotal :: Expectation
topTxOwnContributionIsDerivedFromBatchTotal = False `shouldBe` True

-- | Accepts a SubTx explicit zero when its required own deposit change is zero
-- Executable backlog: replace with a ledger check against independent expectations.
zeroContributionAcceptsExplicitZero :: Expectation
zeroContributionAcceptsExplicitZero = False `shouldBe` True

-- | Rejects a SubTx explicit zero when its required own deposit change is positive
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

-- | Requires a SubTx net release when it spends store-backed outputs and creates only implicit outputs
-- Executable backlog: replace with a ledger check against independent expectations.
spendingLastStoreBackedOutputRequiresRelease :: Expectation
spendingLastStoreBackedOutputRequiresRelease = False `shouldBe` True

-- | Rejects a SubTx explicit zero when its required own deposit change is negative
-- Executable backlog: replace with a ledger check against independent expectations.
zeroDeclarationCannotReplaceRelease :: Expectation
zeroDeclarationCannotReplaceRelease = False `shouldBe` True

-- | Preserves a SubTx's declared net release when another body's allocation offsets it
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

-- | Rejects a SubTx release when its required own deposit change is positive
-- Executable backlog: replace with a ledger check against independent expectations.
releaseCannotReplaceSubTxAllocation :: Expectation
releaseCannotReplaceSubTxAllocation = False `shouldBe` True

-- | Rejects a SubTx allocation when its required own deposit change is negative
-- Executable backlog: replace with a ledger check against independent expectations.
allocationCannotReplaceSubTxRelease :: Expectation
allocationCannotReplaceSubTxRelease = False `shouldBe` True

-- | Accepts exact SubTx contributions on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
exactSubTxContributionsPassOnPhase2Failure :: Expectation
exactSubTxContributionsPassOnPhase2Failure = False `shouldBe` True

-- | Rejects an inexact SubTx contribution even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
inexactSubTxContributionFailsOnPhase2Failure :: Expectation
inexactSubTxContributionFailsOnPhase2Failure = False `shouldBe` True
