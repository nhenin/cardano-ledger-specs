-- | Grammar requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.GrammarSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-GRAMMAR - Grammar" $ do
    it "DS-TX-GRAMMAR-N01 - does not interpret an explicit SubTx zero as a delegation request" explicitZeroDoesNotDelegate
{- FOURMOLU_ENABLE -}

-- | Does not interpret an explicit SubTx zero as a delegation request
-- Executable backlog: replace with a ledger check against independent expectations.
explicitZeroDoesNotDelegate :: Expectation
explicitZeroDoesNotDelegate = False `shouldBe` True
