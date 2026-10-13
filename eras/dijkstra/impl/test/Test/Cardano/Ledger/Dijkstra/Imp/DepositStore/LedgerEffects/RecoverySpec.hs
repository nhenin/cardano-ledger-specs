module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.RecoverySpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | State restoration preserves allocated amounts and restores outputs, records and Store balance together.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-RECOVERY - Recovery" $ do
  it "DS-STATE-RECOVERY-N01 - preserves the complete ledger state through serialization and restoration, including outputs, allocated records and Store surplus" preservesLedgerStateThroughRestoration
  it "DS-STATE-RECOVERY-N02 - restores the complete prior ledger state on rollback after ordinary success or accepted phase-2 failure" rollsBackCompleteLedgerState
{- FOURMOLU_ENABLE -}

preservesLedgerStateThroughRestoration :: Expectation
-- Compare complete semantic state with mixed output variants, distinct allocations
-- and nonzero Store surplus. Then spend a restored output whose accepted size differs
-- from its reserialization and observe release of the retained allocation.
preservesLedgerStateThroughRestoration = False `shouldBe` True

rollsBackCompleteLedgerState :: Expectation
-- For each accepted outcome, restore the exact prior state, including other pots and
-- derived distributions, then replay the transition and compare with its first result.
rollsBackCompleteLedgerState = False `shouldBe` True
