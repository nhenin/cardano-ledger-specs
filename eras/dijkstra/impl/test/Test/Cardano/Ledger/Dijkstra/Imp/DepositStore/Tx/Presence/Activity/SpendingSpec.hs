-- | Spending requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.Activity.SpendingSpec (spec) where

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
