-- | Netting requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Exactness.NettingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-EXACTNESS-NETTING - Netting" $ do
    prop "DS-TX-EXACTNESS-NETTING-P01 - declared TopTx: declaredNetUTxODepositChange = Σ(netUTxODepositChange) over all bodies" totalNetChangeEqualsSumOfBodyChanges
    it "DS-TX-EXACTNESS-NETTING-N01 - includes both TopTx and SubTx UTxO capacity deposit changes in the declared total" totalIncludesTopTxAndSubTxChanges
    it "DS-TX-EXACTNESS-NETTING-N02 - nets a 5 ADA allocation and a 3 ADA release into AllocateUTxODeposit 2" allocationExceedsRelease
    it "DS-TX-EXACTNESS-NETTING-N03 - nets a 3 ADA allocation and a 5 ADA release into ReleaseUTxODeposit 2" releaseExceedsAllocation
    it "DS-TX-EXACTNESS-NETTING-N04 - uses NoUTxODepositChange when allocations and releases cancel exactly" allocationsAndReleasesCancel
{- FOURMOLU_ENABLE -}

-- | Declared TopTx: declaredNetUTxODepositChange = Σ(netUTxODepositChange) over all bodies
-- Executable backlog: replace with a ledger check against independent expectations.
totalNetChangeEqualsSumOfBodyChanges :: Bool
totalNetChangeEqualsSumOfBodyChanges = False

-- | Includes both TopTx and SubTx UTxO capacity deposit changes in the declared total
-- Executable backlog: replace with a ledger check against independent expectations.
totalIncludesTopTxAndSubTxChanges :: Expectation
totalIncludesTopTxAndSubTxChanges = False `shouldBe` True

-- | Nets a 5 ADA allocation and a 3 ADA release into AllocateUTxODeposit 2
-- Executable backlog: replace with a ledger check against independent expectations.
allocationExceedsRelease :: Expectation
allocationExceedsRelease = False `shouldBe` True

-- | Nets a 3 ADA allocation and a 5 ADA release into ReleaseUTxODeposit 2
-- Executable backlog: replace with a ledger check against independent expectations.
releaseExceedsAllocation :: Expectation
releaseExceedsAllocation = False `shouldBe` True

-- | Uses NoUTxODepositChange when allocations and releases cancel exactly
-- Executable backlog: replace with a ledger check against independent expectations.
allocationsAndReleasesCancel :: Expectation
allocationsAndReleasesCancel = False `shouldBe` True
