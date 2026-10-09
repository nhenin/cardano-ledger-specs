module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.NettingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-002 - TopTx declares the net change for the whole batch" $ do
    prop "declared TopTx: declaredNetUTxODepositChange = Σ(netUTxODepositChange) over all bodies" totalNetChangeEqualsSumOfBodyChanges
    it "includes both TopTx and SubTx UTxO capacity deposit changes in the declared total" totalIncludesTopTxAndSubTxChanges
    it "nets a 5 ADA allocation and a 3 ADA release into AllocateUTxODeposit 2" allocationExceedsRelease
    it "nets a 3 ADA allocation and a 5 ADA release into ReleaseUTxODeposit 2" releaseExceedsAllocation
    it "uses NoUTxODepositChange when allocations and releases cancel exactly" allocationsAndReleasesCancel
    it "keeps the same batch net change when a SubTx delegates funding of its net allocation" delegatedFundingPreservesTotal
    it "does not require a TopTx settlement output when the batch declares a net allocation" netAllocationNeedsNoSettlementOutput
    it "does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative" zeroBatchNeedsNoSettlementOutput
{- FOURMOLU_ENABLE -}

totalNetChangeEqualsSumOfBodyChanges :: Bool
totalNetChangeEqualsSumOfBodyChanges = False

totalIncludesTopTxAndSubTxChanges :: Expectation
totalIncludesTopTxAndSubTxChanges = False `shouldBe` True

allocationExceedsRelease :: Expectation
allocationExceedsRelease = False `shouldBe` True

releaseExceedsAllocation :: Expectation
releaseExceedsAllocation = False `shouldBe` True

allocationsAndReleasesCancel :: Expectation
allocationsAndReleasesCancel = False `shouldBe` True

delegatedFundingPreservesTotal :: Expectation
delegatedFundingPreservesTotal = False `shouldBe` True

netAllocationNeedsNoSettlementOutput :: Expectation
netAllocationNeedsNoSettlementOutput = False `shouldBe` True

zeroBatchNeedsNoSettlementOutput :: Expectation
zeroBatchNeedsNoSettlementOutput = False `shouldBe` True
