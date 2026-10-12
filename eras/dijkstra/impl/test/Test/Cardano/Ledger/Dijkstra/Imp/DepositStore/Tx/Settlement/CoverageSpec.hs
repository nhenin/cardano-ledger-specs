-- | Coverage requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Settlement.CoverageSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-COVERAGE - Coverage" $ do
    prop "DS-TX-SETTLEMENT-COVERAGE-P01 - each settlement output: coin(ownOutputs[index]) ≥ settlementAmount" settlementOutputCoversSettlementAmount
    it "DS-TX-SETTLEMENT-COVERAGE-F01 - rejects a settlement output containing less ADA than its settlement amount" insufficientSettlementCoinsAreRejected
    it "DS-TX-SETTLEMENT-COVERAGE-N01 - accepts a settlement output containing exactly its settlement amount" exactSettlementCoinsAreAccepted
    it "DS-TX-SETTLEMENT-COVERAGE-N02 - accepts a settlement output containing the settlement amount and additional funds" additionalSettlementFundsAreAccepted
    it "DS-TX-SETTLEMENT-COVERAGE-F02 - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference" externalDepositCannotFundSettlement
    it "DS-TX-SETTLEMENT-COVERAGE-N03 - accepts a store-backed settlement output with application ADA equal to the settlement amount" exactApplicationAdaFundsSettlement
    it "DS-TX-SETTLEMENT-COVERAGE-N04 - checks TopTx's derived settlement amount rather than the entire batch net release" topTxOutputCoversDerivedSettlementAmount
{- FOURMOLU_ENABLE -}

-- | Each settlement output: coin(ownOutputs[index]) ≥ settlementAmount
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
