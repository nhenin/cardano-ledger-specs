-- | Attribution requirements, retained as executable backlog until implemented.
--
-- Contract: compare observed production attribution against an independent
-- per-form signed projection, not an identity reconstructed from the same total.
-- Local allocation/release contributes +amount/-amount locally; delegation and
-- explicit zero contribute zero locally. Test delegated allocations and releases.
-- Reassigning responsibility preserves the required batch change, not necessarily
-- acceptance with unchanged settlement selectors or output amounts.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AttributionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-ATTRIBUTION - Attribution" $ do
    prop "DS-TX-ATTRIBUTION-P01 - observed TopTx and local SubTx attribution matches the independent signed contribution projection" attributionMatchesIndependentProjection
    prop "DS-TX-ATTRIBUTION-P02 - switching local and delegated accounting changes attribution by the signed contribution and preserves the required batch change" delegationChangesAttributionButPreservesTotal
    it "DS-TX-ATTRIBUTION-N01 - counts delegated funding once in TopTx accounting" topTxAccountsForDelegatedFundingOnce
    it "DS-TX-ATTRIBUTION-N02 - keeps the same batch net change when a SubTx delegates funding of its net allocation" delegatedFundingPreservesTotal
    it "DS-TX-ATTRIBUTION-N03 - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx" finalReleaseWithoutOutputsCanDelegate
    it "DS-TX-ATTRIBUTION-N04 - observes zero local and delegated amounts with no funding request for SubTx explicit zero" explicitZeroHasNoDelegatedAccounting
{- FOURMOLU_ENABLE -}

-- | Observed TopTx and local SubTx attribution matches the independent signed contribution projection
-- Executable backlog: replace with a ledger check against independent expectations.
attributionMatchesIndependentProjection :: Bool
attributionMatchesIndependentProjection = False

-- | Switching local and delegated accounting changes attribution by the signed contribution and preserves the required batch change
-- Executable backlog: replace with a ledger check against independent expectations.
delegationChangesAttributionButPreservesTotal :: Bool
delegationChangesAttributionButPreservesTotal = False

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

-- | Observes zero local and delegated amounts with no funding request for SubTx explicit zero
-- Executable backlog: observe production attribution against independent zero amounts.
explicitZeroHasNoDelegatedAccounting :: Expectation
explicitZeroHasNoDelegatedAccounting = False `shouldBe` True
