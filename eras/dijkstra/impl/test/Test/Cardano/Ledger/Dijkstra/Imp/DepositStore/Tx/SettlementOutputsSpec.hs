module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.SettlementOutputsSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-007 - Settlement indices identify outputs in their own body" $ do
    prop "each settlement output: 0 ≤ index < length(ownOutputs)" settlementIndexIsWithinOwnOutputs
    prop "each settlement output: coin(ownOutputs[index]) ≥ settlementAmount" settlementOutputCoversSettlementAmount
    it "rejects an index outside the declaring body's output sequence" outOfBoundsIndexIsRejected
    it "does not resolve a SubTx settlement index against TopTx outputs" subTxIndexCannotSelectTopTxOutput
    it "does not resolve a settlement index against collateral return" settlementIndexCannotSelectCollateralReturn
    it "rejects a settlement output containing less ADA than its settlement amount" insufficientSettlementCoinsAreRejected
    it "accepts a settlement output containing exactly its settlement amount" exactSettlementCoinsAreAccepted
    it "accepts a settlement output containing the settlement amount and additional funds" additionalSettlementFundsAreAccepted
    it "rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference" externalDepositCannotFundSettlement
    it "accepts a store-backed settlement output with application ADA equal to the settlement amount" exactApplicationAdaFundsSettlement
    it "checks TopTx's derived settlement amount rather than the entire batch net release" topTxOutputCoversDerivedSettlementAmount
    it "does not credit the settlement amount to the selected output a second time" settlementIsNotCreditedTwice
    it "requires an output of 12 ADA for 10 input ADA and a 2 ADA net release with no other ADA flows" releaseIncreasesOutputWithoutOtherFlows
    it "allows an output of 10 ADA when the other 2 ADA contributes to TopTx fees" releaseCanContributeToTopTxFees
{- FOURMOLU_ENABLE -}

settlementIndexIsWithinOwnOutputs :: Bool
settlementIndexIsWithinOwnOutputs = False

settlementOutputCoversSettlementAmount :: Bool
settlementOutputCoversSettlementAmount = False

outOfBoundsIndexIsRejected :: Expectation
outOfBoundsIndexIsRejected = False `shouldBe` True

subTxIndexCannotSelectTopTxOutput :: Expectation
subTxIndexCannotSelectTopTxOutput = False `shouldBe` True

settlementIndexCannotSelectCollateralReturn :: Expectation
settlementIndexCannotSelectCollateralReturn = False `shouldBe` True

insufficientSettlementCoinsAreRejected :: Expectation
insufficientSettlementCoinsAreRejected = False `shouldBe` True

exactSettlementCoinsAreAccepted :: Expectation
exactSettlementCoinsAreAccepted = False `shouldBe` True

additionalSettlementFundsAreAccepted :: Expectation
additionalSettlementFundsAreAccepted = False `shouldBe` True

externalDepositCannotFundSettlement :: Expectation
externalDepositCannotFundSettlement = False `shouldBe` True

exactApplicationAdaFundsSettlement :: Expectation
exactApplicationAdaFundsSettlement = False `shouldBe` True

topTxOutputCoversDerivedSettlementAmount :: Expectation
topTxOutputCoversDerivedSettlementAmount = False `shouldBe` True

settlementIsNotCreditedTwice :: Expectation
settlementIsNotCreditedTwice = False `shouldBe` True

releaseIncreasesOutputWithoutOtherFlows :: Expectation
releaseIncreasesOutputWithoutOtherFlows = False `shouldBe` True

releaseCanContributeToTopTxFees :: Expectation
releaseCanContributeToTopTxFees = False `shouldBe` True
