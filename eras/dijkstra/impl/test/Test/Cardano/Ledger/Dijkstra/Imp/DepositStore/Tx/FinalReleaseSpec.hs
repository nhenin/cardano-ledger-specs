module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.FinalReleaseSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "Spending the last store-backed output releases its UTxO capacity deposit (DS-TX-005)" $ do
    it "requires a net release when a body spends store-backed outputs and creates only implicit outputs" spendingLastStoreBackedOutputRequiresRelease
    it "rejects an explicit zero when that body must release UTxO capacity deposits" zeroDeclarationCannotReplaceRelease
    it "preserves that body's net release even when another body's net allocation offsets it" anotherBodyAllocationDoesNotCancelOwnRelease
    it "allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx" finalReleaseWithoutOutputsCanDelegate
    it "rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs" finalReleaseWithoutOutputsCannotSettleLocally
{- FOURMOLU_ENABLE -}

spendingLastStoreBackedOutputRequiresRelease :: Expectation
spendingLastStoreBackedOutputRequiresRelease = False `shouldBe` True

zeroDeclarationCannotReplaceRelease :: Expectation
zeroDeclarationCannotReplaceRelease = False `shouldBe` True

anotherBodyAllocationDoesNotCancelOwnRelease :: Expectation
anotherBodyAllocationDoesNotCancelOwnRelease = False `shouldBe` True

finalReleaseWithoutOutputsCanDelegate :: Expectation
finalReleaseWithoutOutputsCanDelegate = False `shouldBe` True

finalReleaseWithoutOutputsCannotSettleLocally :: Expectation
finalReleaseWithoutOutputsCannotSettleLocally = False `shouldBe` True
