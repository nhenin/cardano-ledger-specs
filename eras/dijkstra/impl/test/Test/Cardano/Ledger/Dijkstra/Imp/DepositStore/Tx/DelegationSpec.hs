module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DelegationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "Delegation changes who accounts for the contribution (DS-TX-010)" $ do
    prop "topTxNetUTxODepositChange + Σ(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange" localContributionsEqualTotalNetChange
    prop "switching between local accounting and delegation preserves txTotalNetUTxODepositChange" delegationPreservesTotalNetChange
    it "checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change" delegatedAllocationMatchesSubTxNetChange
    it "checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change" delegatedReleaseMatchesSubTxNetChange
    it "counts delegated funding once in TopTx accounting" topTxAccountsForDelegatedFundingOnce
    it "rejects a delegation request that the complete batch does not fund" unfundedDelegationIsRejected
    it "accepts offsetting delegated operations in a financially balanced batch" balancedBatchAllowsOffsettingDelegations
{- FOURMOLU_ENABLE -}

localContributionsEqualTotalNetChange :: Bool
localContributionsEqualTotalNetChange = False

delegationPreservesTotalNetChange :: Bool
delegationPreservesTotalNetChange = False

delegatedAllocationMatchesSubTxNetChange :: Expectation
delegatedAllocationMatchesSubTxNetChange = False `shouldBe` True

delegatedReleaseMatchesSubTxNetChange :: Expectation
delegatedReleaseMatchesSubTxNetChange = False `shouldBe` True

topTxAccountsForDelegatedFundingOnce :: Expectation
topTxAccountsForDelegatedFundingOnce = False `shouldBe` True

unfundedDelegationIsRejected :: Expectation
unfundedDelegationIsRejected = False `shouldBe` True

balancedBatchAllowsOffsettingDelegations :: Expectation
balancedBatchAllowsOffsettingDelegations = False `shouldBe` True
