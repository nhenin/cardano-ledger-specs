module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.RecoverySpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | State restoration preserves allocated amounts and restores outputs, records and Store balance together.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-RECOVERY - Recovery" $ do
  it "DS-STATE-RECOVERY-N01 - preserves allocated UTxO capacity deposits through state serialization and restoration" preservesDepositsThroughStateRestoration
  it "DS-STATE-RECOVERY-N02 - restores outputs, UTxO capacity deposit records and Store balance together on rollback" rollsBackOutputsRecordsAndBalanceTogether
{- FOURMOLU_ENABLE -}

preservesDepositsThroughStateRestoration :: Expectation
preservesDepositsThroughStateRestoration = False `shouldBe` True

rollsBackOutputsRecordsAndBalanceTogether :: Expectation
rollsBackOutputsRecordsAndBalanceTogether = False `shouldBe` True
