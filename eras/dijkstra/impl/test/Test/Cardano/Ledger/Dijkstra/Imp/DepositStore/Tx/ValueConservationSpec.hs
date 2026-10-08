module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ValueConservationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "The complete batch conserves value (DS-TX-004)" $ do
    prop "consumedValue + inject(max(0, -txTotalNetUTxODepositChange)) = producedValue + inject(max(0, txTotalNetUTxODepositChange))" completeBatchConservesValue
    prop "ledger acceptance agrees with the model even when individual SubTxs are financially imbalanced" batchAcceptanceAllowsSubTxImbalance
    it "counts the net allocation once on the produced side" netAllocationIsProducedOnce
    it "counts the net release once on the consumed side" netReleaseIsConsumedOnce
    it "accepts financially imbalanced SubTxs when the complete batch balances" balancedBatchAllowsImbalancedSubTxs
    it "preserves a SubTx's ability to contribute ADA to TopTx fees" subTxCanContributeToTopTxFees
    it "rejects a batch imbalance of one lovelace" lovelaceImbalanceIsRejected
    it "rejects a native-asset imbalance even when ADA balances" nativeAssetImbalanceIsRejected
{- FOURMOLU_ENABLE -}

completeBatchConservesValue :: Bool
completeBatchConservesValue = False

batchAcceptanceAllowsSubTxImbalance :: Bool
batchAcceptanceAllowsSubTxImbalance = False

netAllocationIsProducedOnce :: Expectation
netAllocationIsProducedOnce = False `shouldBe` True

netReleaseIsConsumedOnce :: Expectation
netReleaseIsConsumedOnce = False `shouldBe` True

balancedBatchAllowsImbalancedSubTxs :: Expectation
balancedBatchAllowsImbalancedSubTxs = False `shouldBe` True

subTxCanContributeToTopTxFees :: Expectation
subTxCanContributeToTopTxFees = False `shouldBe` True

lovelaceImbalanceIsRejected :: Expectation
lovelaceImbalanceIsRejected = False `shouldBe` True

nativeAssetImbalanceIsRejected :: Expectation
nativeAssetImbalanceIsRejected = False `shouldBe` True
