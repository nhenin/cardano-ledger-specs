-- | Attribution requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.AttributionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-ATTRIBUTION - Attribution" $ do
    prop "DS-TX-ATTRIBUTION-P01 - topTxNetUTxODepositChange + Σ(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange" localContributionsEqualTotalNetChange
    prop "DS-TX-ATTRIBUTION-P02 - switching between local accounting and delegation preserves txTotalNetUTxODepositChange" delegationPreservesTotalNetChange
    it "DS-TX-ATTRIBUTION-N01 - counts delegated funding once in TopTx accounting" topTxAccountsForDelegatedFundingOnce
    it "DS-TX-ATTRIBUTION-N02 - keeps the same batch net change when a SubTx delegates funding of its net allocation" delegatedFundingPreservesTotal
    it "DS-TX-ATTRIBUTION-N03 - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx" finalReleaseWithoutOutputsCanDelegate
{- FOURMOLU_ENABLE -}

-- | TopTxNetUTxODepositChange + Σ(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange
-- Executable backlog: replace with a ledger check against independent expectations.
localContributionsEqualTotalNetChange :: Bool
localContributionsEqualTotalNetChange = False

-- | Switching between local accounting and delegation preserves txTotalNetUTxODepositChange
-- Executable backlog: replace with a ledger check against independent expectations.
delegationPreservesTotalNetChange :: Bool
delegationPreservesTotalNetChange = False

-- | Counts delegated funding once in TopTx accounting
-- Executable backlog: replace with a ledger check against independent expectations.
topTxAccountsForDelegatedFundingOnce :: Expectation
topTxAccountsForDelegatedFundingOnce = False `shouldBe` True

-- | Keeps the same batch net change when a SubTx delegates funding of its net allocation
-- Executable backlog: replace with a ledger check against independent expectations.
delegatedFundingPreservesTotal :: Expectation
delegatedFundingPreservesTotal = False `shouldBe` True

-- | Allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx
-- Executable backlog: replace with a ledger check against independent expectations.
finalReleaseWithoutOutputsCanDelegate :: Expectation
finalReleaseWithoutOutputsCanDelegate = False `shouldBe` True
