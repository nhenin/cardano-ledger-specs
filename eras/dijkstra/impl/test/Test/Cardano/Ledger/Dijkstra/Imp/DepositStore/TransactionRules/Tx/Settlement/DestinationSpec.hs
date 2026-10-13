-- | Destination requirements, retained as executable backlog until implemented.
--
-- Contract: compare isolated index resolution with the owning regular-output
-- sequence. Participation is otherwise valid; coverage is checked separately.
-- Include first/last valid and first invalid positions at both body levels, empty
-- outputs, siblings, nested outputs and collateral return. The checks apply on
-- both phase-2 outcomes, whether or not ordinary outputs are later applied.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.DestinationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-DESTINATION - Destination" $ do
    prop "DS-TX-SETTLEMENT-DESTINATION-P01 - passes destination validation ⇔ every selected index is within its own regular output sequence" settlementIndexIsWithinOwnOutputs
    it "DS-TX-SETTLEMENT-DESTINATION-F01 - rejects an index outside the declaring body's output sequence" outOfBoundsIndexIsRejected
    it "DS-TX-SETTLEMENT-DESTINATION-F02 - does not resolve a SubTx settlement index against TopTx outputs" subTxIndexCannotSelectTopTxOutput
    it "DS-TX-SETTLEMENT-DESTINATION-F03 - does not resolve a settlement index against collateral return" settlementIndexCannotSelectCollateralReturn
    it "DS-TX-SETTLEMENT-DESTINATION-F04 - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs" finalReleaseWithoutOutputsCannotSettleLocally
    it "DS-TX-SETTLEMENT-DESTINATION-N01 - accepts the first and last own regular output as settlement destinations" ownBoundaryDestinationsAreAccepted
    it "DS-TX-SETTLEMENT-DESTINATION-F05 - does not resolve a TopTx settlement index against nested SubTx outputs" topTxIndexCannotSelectSubTxOutput
    it "DS-TX-SETTLEMENT-DESTINATION-F06 - does not resolve a SubTx settlement index against a sibling SubTx's outputs" subTxIndexCannotSelectSiblingOutput
    it "DS-TX-SETTLEMENT-DESTINATION-N02 - accepts valid ordinary settlement destinations on the phase-2 failure path" destinationsPassOnPhase2Failure
    it "DS-TX-SETTLEMENT-DESTINATION-F07 - rejects an invalid ordinary settlement index even when phase 2 fails" invalidDestinationFailsOnPhase2Failure
{- FOURMOLU_ENABLE -}

-- | Passes destination validation ⇔ every selected index is within its own regular output sequence
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

-- | Accepts the first and last own regular output as settlement destinations
-- Executable backlog: replace with a ledger check against independent expectations.
ownBoundaryDestinationsAreAccepted :: Expectation
ownBoundaryDestinationsAreAccepted = False `shouldBe` True

-- | Does not resolve a TopTx settlement index against nested SubTx outputs
-- Executable backlog: replace with a ledger check against independent expectations.
topTxIndexCannotSelectSubTxOutput :: Expectation
topTxIndexCannotSelectSubTxOutput = False `shouldBe` True

-- | Does not resolve a SubTx settlement index against a sibling SubTx's outputs
-- Executable backlog: replace with a ledger check against independent expectations.
subTxIndexCannotSelectSiblingOutput :: Expectation
subTxIndexCannotSelectSiblingOutput = False `shouldBe` True

-- | Accepts valid ordinary settlement destinations on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
destinationsPassOnPhase2Failure :: Expectation
destinationsPassOnPhase2Failure = False `shouldBe` True

-- | Rejects an invalid ordinary settlement index even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
invalidDestinationFailsOnPhase2Failure :: Expectation
invalidDestinationFailsOnPhase2Failure = False `shouldBe` True
