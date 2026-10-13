module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.ExecutionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Only the effects selected by the ledger outcome are applied, and rejected batches leave the accepted state unchanged.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-EXECUTION - Execution" $ do
  prop "DS-STATE-EXECUTION-P01 - ordinary success ⇒ utxoAfter = (utxoBefore without regularInputs) union newRegularOutputsWithUTxODeposits" ordinaryUTxOTransition
  it "DS-STATE-EXECUTION-N01 - applies ordinary effects and no collateral effects on success, including when input roles overlap" successAppliesOnlyOrdinaryEffects
  it "DS-STATE-EXECUTION-N02 - applies collateral settlement and no ordinary Store operations on an accepted phase-2 failure" phaseTwoFailureAppliesOnlyCollateral
  it "DS-STATE-EXECUTION-N03 - consumes only collateral inputs and creates only the specified collateral return in the UTxO on an accepted phase-2 failure" phaseTwoFailureChangesOnlyCollateralUTxO
  it "DS-STATE-EXECUTION-N04 - does not credit the settlement amount to the selected output a second time" settlementIsNotCreditedTwice
  it "DS-STATE-EXECUTION-F01 - leaves the entire ledger state unchanged when a later body rejects a batch after earlier SubTx processing" lateBatchRejectionLeavesLedgerUntouched
  prop "DS-STATE-EXECUTION-P02 - batch rejected ⇒ acceptedLedgerStateAfter = acceptedLedgerStateBefore" preservesRejectedState
{- FOURMOLU_ENABLE -}

ordinaryUTxOTransition :: Bool
ordinaryUTxOTransition = False

successAppliesOnlyOrdinaryEffects :: Expectation
-- Include an input used for both regular spending and collateral: success consumes
-- it through ordinary spending and releases its allocation once, not once per role.
successAppliesOnlyOrdinaryEffects = False `shouldBe` True

phaseTwoFailureAppliesOnlyCollateral :: Expectation
phaseTwoFailureAppliesOnlyCollateral = False `shouldBe` True

phaseTwoFailureChangesOnlyCollateralUTxO :: Expectation
-- Include overlapping ordinary/collateral input roles. Only ordinary inputs outside
-- the collateral set survive; the shared input is consumed once as collateral.
phaseTwoFailureChangesOnlyCollateralUTxO = False `shouldBe` True

settlementIsNotCreditedTwice :: Expectation
settlementIsNotCreditedTwice = False `shouldBe` True

lateBatchRejectionLeavesLedgerUntouched :: Expectation
-- Pair a valid batch with a later-body failure after an earlier SubTx can contribute
-- candidate effects. Compare the complete accepted ledger state, including derived
-- distributions and monetary pots, rather than only the Store fields.
lateBatchRejectionLeavesLedgerUntouched = False `shouldBe` True

preservesRejectedState :: Bool
preservesRejectedState = False
