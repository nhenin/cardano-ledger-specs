-- | Destination requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Settlement.DestinationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-DESTINATION - Destination" $ do
    prop "DS-TX-SETTLEMENT-DESTINATION-P01 - each settlement output: 0 ≤ index < length(ownOutputs)" settlementIndexIsWithinOwnOutputs
    it "DS-TX-SETTLEMENT-DESTINATION-F01 - rejects an index outside the declaring body's output sequence" outOfBoundsIndexIsRejected
    it "DS-TX-SETTLEMENT-DESTINATION-F02 - does not resolve a SubTx settlement index against TopTx outputs" subTxIndexCannotSelectTopTxOutput
    it "DS-TX-SETTLEMENT-DESTINATION-F03 - does not resolve a settlement index against collateral return" settlementIndexCannotSelectCollateralReturn
    it "DS-TX-SETTLEMENT-DESTINATION-F04 - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs" finalReleaseWithoutOutputsCannotSettleLocally
{- FOURMOLU_ENABLE -}

-- | Each settlement output: 0 ≤ index < length(ownOutputs)
-- Executable backlog: replace with a ledger check against independent expectations.
settlementIndexIsWithinOwnOutputs :: Bool
settlementIndexIsWithinOwnOutputs = False

-- | Rejects an index outside the declaring body's output sequence
-- Executable backlog: replace with a ledger check against independent expectations.
outOfBoundsIndexIsRejected :: Expectation
outOfBoundsIndexIsRejected = False `shouldBe` True

-- | Does not resolve a SubTx settlement index against TopTx outputs
-- Executable backlog: replace with a ledger check against independent expectations.
subTxIndexCannotSelectTopTxOutput :: Expectation
subTxIndexCannotSelectTopTxOutput = False `shouldBe` True

-- | Does not resolve a settlement index against collateral return
-- Executable backlog: replace with a ledger check against independent expectations.
settlementIndexCannotSelectCollateralReturn :: Expectation
settlementIndexCannotSelectCollateralReturn = False `shouldBe` True

-- | Rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs
-- Executable backlog: replace with a ledger check against independent expectations.
finalReleaseWithoutOutputsCannotSettleLocally :: Expectation
finalReleaseWithoutOutputsCannotSettleLocally = False `shouldBe` True
