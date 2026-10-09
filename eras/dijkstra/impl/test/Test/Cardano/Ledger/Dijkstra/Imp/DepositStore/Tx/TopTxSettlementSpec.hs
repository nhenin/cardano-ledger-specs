module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.TopTxSettlementSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-006 - TopTx settlement for a batch net release" $ do
    prop "for a batch net release: NoTopTxSettlement ⇔ topTxNetRelease = 0" noTopTxSettlementIffNoTopTxNetRelease
    it "requires NoTopTxSettlement when SubTxs settle the entire net release locally" localSubTxSettlementsNeedNoTopTxSettlement
    it "requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share" topTxNetReleaseRequiresSettlementOutput
    it "accepts a net release settled across TopTx and SubTx outputs" releaseCanBeSettledAcrossBodies
    it "allows TopTx's settlement amount to exceed the batch net release when SubTxs fund net allocations locally" topTxSettlementCanExceedBatchNetRelease
    it "rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share" missingTopTxSettlementIsRejected
    it "rejects a TopTx settlement output when TopTx has no net release to settle" unnecessaryTopTxSettlementIsRejected
{- FOURMOLU_ENABLE -}

noTopTxSettlementIffNoTopTxNetRelease :: Bool
noTopTxSettlementIffNoTopTxNetRelease = False

localSubTxSettlementsNeedNoTopTxSettlement :: Expectation
localSubTxSettlementsNeedNoTopTxSettlement = False `shouldBe` True

topTxNetReleaseRequiresSettlementOutput :: Expectation
topTxNetReleaseRequiresSettlementOutput = False `shouldBe` True

releaseCanBeSettledAcrossBodies :: Expectation
releaseCanBeSettledAcrossBodies = False `shouldBe` True

topTxSettlementCanExceedBatchNetRelease :: Expectation
topTxSettlementCanExceedBatchNetRelease = False `shouldBe` True

missingTopTxSettlementIsRejected :: Expectation
missingTopTxSettlementIsRejected = False `shouldBe` True

unnecessaryTopTxSettlementIsRejected :: Expectation
unnecessaryTopTxSettlementIsRejected = False `shouldBe` True
