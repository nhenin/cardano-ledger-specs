-- | Coverage requirements, retained as executable backlog until implemented.
--
-- Contract: given valid participation and destination, compare the isolated
-- coverage validator with independently required settlement amounts and selected
-- application ADA. Full-ledger negative fixtures preserve batch conservation by
-- placing the missing amount in a different implicit output. Test both body levels
-- and output variants, on both phase-2 outcomes. This lower bound imposes neither
-- independent SubTx balance nor the unresolved stronger local-settlement guarantee.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.CoverageSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-COVERAGE - Coverage" $ do
    prop "DS-TX-SETTLEMENT-COVERAGE-P01 - with valid destinations, passes coverage validation ⇔ each selected output's application ADA ≥ its settlement amount" settlementOutputCoversSettlementAmount
    it "DS-TX-SETTLEMENT-COVERAGE-F01 - rejects a settlement output containing less ADA than its settlement amount" insufficientSettlementCoinsAreRejected
    it "DS-TX-SETTLEMENT-COVERAGE-N01 - accepts a settlement output containing exactly its settlement amount" exactSettlementCoinsAreAccepted
    it "DS-TX-SETTLEMENT-COVERAGE-N02 - accepts a settlement output containing the settlement amount and additional funds" additionalSettlementFundsAreAccepted
    it "DS-TX-SETTLEMENT-COVERAGE-F02 - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference" externalDepositCannotFundSettlement
    it "DS-TX-SETTLEMENT-COVERAGE-N03 - accepts a store-backed settlement output with application ADA equal to the settlement amount" exactApplicationAdaFundsSettlement
    it "DS-TX-SETTLEMENT-COVERAGE-N04 - checks TopTx's derived settlement amount rather than the entire batch net release" topTxOutputCoversDerivedSettlementAmount
    it "DS-TX-SETTLEMENT-COVERAGE-N05 - accepts covered ordinary settlement outputs on the phase-2 failure path" coveragePassesOnPhase2Failure
    it "DS-TX-SETTLEMENT-COVERAGE-F03 - rejects insufficient ordinary settlement coverage even when phase 2 fails" insufficientCoverageFailsOnPhase2Failure
    it "DS-TX-SETTLEMENT-COVERAGE-F04 - rejects a TopTx output that covers the batch release but not TopTx's larger attributed release" batchReleaseCannotReplaceTopTxCoverage
{- FOURMOLU_ENABLE -}

-- | With valid destinations, passes coverage validation ⇔ each selected output's application ADA ≥ its settlement amount
-- Executable backlog: replace with a ledger check against independent expectations.
settlementOutputCoversSettlementAmount :: Bool
settlementOutputCoversSettlementAmount = False

-- | Rejects a settlement output containing less ADA than its settlement amount
-- Executable backlog: replace with a ledger check against independent expectations.
insufficientSettlementCoinsAreRejected :: Expectation
insufficientSettlementCoinsAreRejected = False `shouldBe` True

-- | Accepts a settlement output containing exactly its settlement amount
-- Executable backlog: replace with a ledger check against independent expectations.
exactSettlementCoinsAreAccepted :: Expectation
exactSettlementCoinsAreAccepted = False `shouldBe` True

-- | Accepts a settlement output containing the settlement amount and additional funds
-- Executable backlog: replace with a ledger check against independent expectations.
additionalSettlementFundsAreAccepted :: Expectation
additionalSettlementFundsAreAccepted = False `shouldBe` True

-- | Rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference
-- Executable backlog: replace with a ledger check against independent expectations.
externalDepositCannotFundSettlement :: Expectation
externalDepositCannotFundSettlement = False `shouldBe` True

-- | Accepts a store-backed settlement output with application ADA equal to the settlement amount
-- Executable backlog: replace with a ledger check against independent expectations.
exactApplicationAdaFundsSettlement :: Expectation
exactApplicationAdaFundsSettlement = False `shouldBe` True

-- | Checks TopTx's derived settlement amount rather than the entire batch net release
-- Executable backlog: replace with a ledger check against independent expectations.
topTxOutputCoversDerivedSettlementAmount :: Expectation
topTxOutputCoversDerivedSettlementAmount = False `shouldBe` True

-- | Accepts covered ordinary settlement outputs on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
coveragePassesOnPhase2Failure :: Expectation
coveragePassesOnPhase2Failure = False `shouldBe` True

-- | Rejects insufficient ordinary settlement coverage even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
insufficientCoverageFailsOnPhase2Failure :: Expectation
insufficientCoverageFailsOnPhase2Failure = False `shouldBe` True

-- | Rejects a TopTx output that covers the batch release but not TopTx's larger attributed release
-- Executable backlog: replace with a ledger check against independent expectations.
batchReleaseCannotReplaceTopTxCoverage :: Expectation
batchReleaseCannotReplaceTopTxCoverage = False `shouldBe` True
