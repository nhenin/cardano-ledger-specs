-- | Conservation requirements, retained as executable backlog until implemented.
--
-- Contract: P01 observes accepted transactions with an explicit TopTx declaration
-- on either phase-2 outcome. An all-absent transaction has no Store term, not a
-- declared zero. P02 compares acceptance with independent batch conservation only while all other
-- requirements hold, including existing legacy-mode restrictions. Consumed and
-- produced values exclude DepositStore terms until the declared batch term is
-- added once. Imbalanced SubTxs and fee exports remain permitted. N06 freezes all
-- other batch flows; N07 explicitly accounts for the export in TopTx fees.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.ConservationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-CONSERVATION - Conservation" $ do
    prop "DS-TX-CONSERVATION-P01 - accepted transaction with explicit TopTx declaration ⇒ consumedValue + inject(max(0, -declaredTxTotalNetUTxODepositChange)) = producedValue + inject(max(0, declaredTxTotalNetUTxODepositChange))" completeBatchConservesValue
    prop "DS-TX-CONSERVATION-P02 - with other rules satisfied, ledger acceptance agrees with batch conservation even when SubTxs are financially imbalanced" batchAcceptanceAllowsSubTxImbalance
    it "DS-TX-CONSERVATION-N01 - counts the net allocation once on the produced side" netAllocationIsProducedOnce
    it "DS-TX-CONSERVATION-N02 - counts the net release once on the consumed side" netReleaseIsConsumedOnce
    it "DS-TX-CONSERVATION-N03 - accepts financially imbalanced SubTxs when the complete batch balances" balancedBatchAllowsImbalancedSubTxs
    it "DS-TX-CONSERVATION-N04 - preserves a SubTx's ability to contribute ADA to TopTx fees" subTxCanContributeToTopTxFees
    it "DS-TX-CONSERVATION-F01 - rejects a batch imbalance of one lovelace" lovelaceImbalanceIsRejected
    it "DS-TX-CONSERVATION-F02 - rejects a native-asset imbalance even when ADA balances" nativeAssetImbalanceIsRejected
    it "DS-TX-CONSERVATION-F03 - rejects a delegation request that the complete batch does not fund" unfundedDelegationIsRejected
    it "DS-TX-CONSERVATION-N05 - accepts offsetting delegated operations in a financially balanced batch" balancedBatchAllowsOffsettingDelegations
    it "DS-TX-CONSERVATION-N06 - requires an output of 12 ADA for 10 input ADA and a 2 ADA net release with no other ADA flows" releaseIncreasesOutputWithoutOtherFlows
    it "DS-TX-CONSERVATION-N07 - allows an output of 10 ADA when the other 2 ADA contributes to TopTx fees" releaseCanContributeToTopTxFees
    it "DS-TX-CONSERVATION-F04 - rejects a 10 ADA output for 10 input ADA and a 2 ADA release when all other batch flows stay fixed" releaseCannotDisappearWithoutAnAccountedExport
    it "DS-TX-CONSERVATION-N08 - accepts ordinary batch conservation on the phase-2 failure path" ordinaryConservationPassesOnPhase2Failure
    it "DS-TX-CONSERVATION-F05 - rejects an ordinary batch imbalance even when phase 2 fails" ordinaryImbalanceFailsOnPhase2Failure
{- FOURMOLU_ENABLE -}

-- | Accepted transaction with explicit TopTx declaration ⇒ consumedValue + inject(max(0, -declaredTxTotalNetUTxODepositChange)) = producedValue + inject(max(0, declaredTxTotalNetUTxODepositChange))
-- Executable backlog: replace with a ledger check against independent expectations.
completeBatchConservesValue :: Bool
completeBatchConservesValue = False

-- | With other rules satisfied, ledger acceptance agrees with batch conservation even when SubTxs are financially imbalanced
-- Executable backlog: replace with a ledger check against independent expectations.
batchAcceptanceAllowsSubTxImbalance :: Bool
batchAcceptanceAllowsSubTxImbalance = False

-- | Counts the net allocation once on the produced side
-- Executable backlog: replace with a ledger check against independent expectations.
netAllocationIsProducedOnce :: Expectation
netAllocationIsProducedOnce = False `shouldBe` True

-- | Counts the net release once on the consumed side
-- Executable backlog: replace with a ledger check against independent expectations.
netReleaseIsConsumedOnce :: Expectation
netReleaseIsConsumedOnce = False `shouldBe` True

-- | Accepts financially imbalanced SubTxs when the complete batch balances
-- Executable backlog: replace with a ledger check against independent expectations.
balancedBatchAllowsImbalancedSubTxs :: Expectation
balancedBatchAllowsImbalancedSubTxs = False `shouldBe` True

-- | Preserves a SubTx's ability to contribute ADA to TopTx fees
-- Executable backlog: replace with a ledger check against independent expectations.
subTxCanContributeToTopTxFees :: Expectation
subTxCanContributeToTopTxFees = False `shouldBe` True

-- | Rejects a batch imbalance of one lovelace
-- Executable backlog: replace with a ledger check against independent expectations.
lovelaceImbalanceIsRejected :: Expectation
lovelaceImbalanceIsRejected = False `shouldBe` True

-- | Rejects a native-asset imbalance even when ADA balances
-- Executable backlog: replace with a ledger check against independent expectations.
nativeAssetImbalanceIsRejected :: Expectation
nativeAssetImbalanceIsRejected = False `shouldBe` True

-- | Rejects a delegation request that the complete batch does not fund
-- Executable backlog: replace with a ledger check against independent expectations.
unfundedDelegationIsRejected :: Expectation
unfundedDelegationIsRejected = False `shouldBe` True

-- | Accepts offsetting delegated operations in a financially balanced batch
-- Executable backlog: replace with a ledger check against independent expectations.
balancedBatchAllowsOffsettingDelegations :: Expectation
balancedBatchAllowsOffsettingDelegations = False `shouldBe` True

-- | Requires an output of 12 ADA for 10 input ADA and a 2 ADA net release with no other ADA flows
-- Executable backlog: replace with a ledger check against independent expectations.
releaseIncreasesOutputWithoutOtherFlows :: Expectation
releaseIncreasesOutputWithoutOtherFlows = False `shouldBe` True

-- | Allows an output of 10 ADA when the other 2 ADA contributes to TopTx fees
-- Executable backlog: replace with a ledger check against independent expectations.
releaseCanContributeToTopTxFees :: Expectation
releaseCanContributeToTopTxFees = False `shouldBe` True

-- | Rejects a 10 ADA output for 10 input ADA and a 2 ADA release when all other batch flows stay fixed
-- Executable backlog: replace with a ledger check against independent expectations.
releaseCannotDisappearWithoutAnAccountedExport :: Expectation
releaseCannotDisappearWithoutAnAccountedExport = False `shouldBe` True

-- | Accepts ordinary batch conservation on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
ordinaryConservationPassesOnPhase2Failure :: Expectation
ordinaryConservationPassesOnPhase2Failure = False `shouldBe` True

-- | Rejects an ordinary batch imbalance even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
ordinaryImbalanceFailsOnPhase2Failure :: Expectation
ordinaryImbalanceFailsOnPhase2Failure = False `shouldBe` True
