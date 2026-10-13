-- | Spending requirements, retained as executable backlog until implemented.
--
-- Contract: use otherwise valid, funded transactions with store-backed spending
-- inputs and no store-backed created outputs, so creation cannot mask this rule.
-- Acceptance controls satisfy exactness, dependency, settlement and conservation.
-- Rejections assert the spending-presence failure. Ordinary validation applies on
-- both phase-2 outcomes; only execution decides which effects are applied.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.Activity.SpendingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-PRESENCE-ACTIVITY-SPENDING - Spending" $ do
    it "DS-TX-PRESENCE-ACTIVITY-SPENDING-N01 - accepts a TopTx spending a store-backed input with its own declaration" acceptsSpendingTopTxWithOwnDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SPENDING-N02 - accepts a SubTx spending a store-backed input with its own declaration" acceptsSpendingSubTxWithOwnDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SPENDING-F01 - rejects a TopTx spending a store-backed input without a declaration" spendingTopTxInputRequiresDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SPENDING-F02 - rejects a SubTx spending a store-backed input without its own declaration" spendingSubTxInputRequiresDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SPENDING-N03 - accepts exact declarations for store-backed spending on the phase-2 failure path" acceptsSpendingDeclarationsOnPhase2Failure
    it "DS-TX-PRESENCE-ACTIVITY-SPENDING-F03 - rejects a missing spending declaration even when phase 2 fails" spendingPresenceSurvivesPhase2Failure
{- FOURMOLU_ENABLE -}

-- | Accepts a TopTx spending a store-backed input with its own declaration
-- Executable backlog: replace with a ledger check against independent expectations.
acceptsSpendingTopTxWithOwnDeclaration :: Expectation
acceptsSpendingTopTxWithOwnDeclaration = False `shouldBe` True

-- | Accepts a SubTx spending a store-backed input with its own declaration
-- Executable backlog: replace with a ledger check against independent expectations.
acceptsSpendingSubTxWithOwnDeclaration :: Expectation
acceptsSpendingSubTxWithOwnDeclaration = False `shouldBe` True

-- | Rejects a TopTx spending a store-backed input without a declaration
-- Executable backlog: replace with a ledger check against independent expectations.
spendingTopTxInputRequiresDeclaration :: Expectation
spendingTopTxInputRequiresDeclaration = False `shouldBe` True

-- | Rejects a SubTx spending a store-backed input without its own declaration
-- Executable backlog: replace with a ledger check against independent expectations.
spendingSubTxInputRequiresDeclaration :: Expectation
spendingSubTxInputRequiresDeclaration = False `shouldBe` True

-- | Accepts exact declarations for store-backed spending on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
acceptsSpendingDeclarationsOnPhase2Failure :: Expectation
acceptsSpendingDeclarationsOnPhase2Failure = False `shouldBe` True

-- | Rejects a missing spending declaration even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
spendingPresenceSurvivesPhase2Failure :: Expectation
spendingPresenceSurvivesPhase2Failure = False `shouldBe` True
