-- | Participation requirements, retained as executable backlog until implemented.
--
-- Contract: compare the isolated selector check with its independent predicate
-- for exact batch net-release declarations. topTxNetRelease is max(0, -attributed
-- TopTx change), so zero and positive attributed changes both require no selector.
-- Net-allocation and explicit-zero batch declarations have no TopTx selector, even
-- when the attributed TopTx change is negative. Validate on both phase-2 outcomes.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.ParticipationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-PARTICIPATION - Participation" $ do
    prop "DS-TX-SETTLEMENT-PARTICIPATION-P01 - for an exact batch net release, passes participation validation ⇔ (uses NoTopTxSettlement ⇔ topTxNetRelease = 0)" noTopTxSettlementIffNoTopTxNetRelease
    it "DS-TX-SETTLEMENT-PARTICIPATION-N01 - requires NoTopTxSettlement when SubTxs settle the entire net release locally" localSubTxSettlementsNeedNoTopTxSettlement
    it "DS-TX-SETTLEMENT-PARTICIPATION-N02 - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share" topTxNetReleaseRequiresSettlementOutput
    it "DS-TX-SETTLEMENT-PARTICIPATION-N03 - accepts a net release settled across TopTx and SubTx outputs" releaseCanBeSettledAcrossBodies
    it "DS-TX-SETTLEMENT-PARTICIPATION-N04 - allows TopTx's settlement amount to exceed the batch net release when SubTxs account for net allocations locally" topTxSettlementCanExceedBatchNetRelease
    it "DS-TX-SETTLEMENT-PARTICIPATION-F01 - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share" missingTopTxSettlementIsRejected
    it "DS-TX-SETTLEMENT-PARTICIPATION-F02 - rejects a TopTx settlement output when TopTx has no net release to settle" unnecessaryTopTxSettlementIsRejected
    it "DS-TX-SETTLEMENT-PARTICIPATION-N05 - does not require a TopTx settlement output when the batch declares a net allocation" netAllocationNeedsNoSettlementOutput
    it "DS-TX-SETTLEMENT-PARTICIPATION-N06 - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative" zeroBatchNeedsNoSettlementOutput
    it "DS-TX-SETTLEMENT-PARTICIPATION-N07 - accepts NoTopTxSettlement when TopTx's attributed contribution is a net allocation" positiveTopTxAttributionNeedsNoSettlement
    it "DS-TX-SETTLEMENT-PARTICIPATION-N08 - accepts correct release participation on the phase-2 failure path" participationPassesOnPhase2Failure
    it "DS-TX-SETTLEMENT-PARTICIPATION-F03 - rejects incorrect release participation even when phase 2 fails" participationFailsOnPhase2Failure
{- FOURMOLU_ENABLE -}

-- | For an exact batch net release, passes participation validation ⇔ (uses NoTopTxSettlement ⇔ topTxNetRelease = 0)
-- Executable backlog: replace with a ledger check against independent expectations.
noTopTxSettlementIffNoTopTxNetRelease :: Bool
noTopTxSettlementIffNoTopTxNetRelease = False

-- | Requires NoTopTxSettlement when SubTxs settle the entire net release locally
-- Executable backlog: replace with a ledger check against independent expectations.
localSubTxSettlementsNeedNoTopTxSettlement :: Expectation
localSubTxSettlementsNeedNoTopTxSettlement = False `shouldBe` True

-- | Requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share
-- Executable backlog: replace with a ledger check against independent expectations.
topTxNetReleaseRequiresSettlementOutput :: Expectation
topTxNetReleaseRequiresSettlementOutput = False `shouldBe` True

-- | Accepts a net release settled across TopTx and SubTx outputs
-- Executable backlog: replace with a ledger check against independent expectations.
releaseCanBeSettledAcrossBodies :: Expectation
releaseCanBeSettledAcrossBodies = False `shouldBe` True

-- | Allows TopTx's settlement amount to exceed the batch net release when SubTxs account for net allocations locally
-- Executable backlog: replace with a ledger check against independent expectations.
topTxSettlementCanExceedBatchNetRelease :: Expectation
topTxSettlementCanExceedBatchNetRelease = False `shouldBe` True

-- | Rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share
-- Executable backlog: replace with a ledger check against independent expectations.
missingTopTxSettlementIsRejected :: Expectation
missingTopTxSettlementIsRejected = False `shouldBe` True

-- | Rejects a TopTx settlement output when TopTx has no net release to settle
-- Executable backlog: replace with a ledger check against independent expectations.
unnecessaryTopTxSettlementIsRejected :: Expectation
unnecessaryTopTxSettlementIsRejected = False `shouldBe` True

-- | Does not require a TopTx settlement output when the batch declares a net allocation
-- Executable backlog: replace with a ledger check against independent expectations.
netAllocationNeedsNoSettlementOutput :: Expectation
netAllocationNeedsNoSettlementOutput = False `shouldBe` True

-- | Does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative
-- Executable backlog: replace with a ledger check against independent expectations.
zeroBatchNeedsNoSettlementOutput :: Expectation
zeroBatchNeedsNoSettlementOutput = False `shouldBe` True

-- | Accepts NoTopTxSettlement when TopTx's attributed contribution is a net allocation
-- Executable backlog: replace with a ledger check against independent expectations.
positiveTopTxAttributionNeedsNoSettlement :: Expectation
positiveTopTxAttributionNeedsNoSettlement = False `shouldBe` True

-- | Accepts correct release participation on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
participationPassesOnPhase2Failure :: Expectation
participationPassesOnPhase2Failure = False `shouldBe` True

-- | Rejects incorrect release participation even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
participationFailsOnPhase2Failure :: Expectation
participationFailsOnPhase2Failure = False `shouldBe` True
