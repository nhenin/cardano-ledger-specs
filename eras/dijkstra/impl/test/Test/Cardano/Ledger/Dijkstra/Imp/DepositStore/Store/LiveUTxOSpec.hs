module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.LiveUTxOSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Intentionally failing placeholders for the agreed DepositStore rules.
-- Replace each placeholder with a ledger check against independent expectations.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "Live UTxO entries retain their allocated UTxO capacity deposits (DS-STORE-005)" $ do
  prop "ordinary success ⇒ releasedUTxODeposits = Σ(allocatedUTxODeposit(utxo[input])) over consumed store-backed inputs" releasedDepositsMatchRecords
  prop "ordinary success ⇒ utxoAfter = (utxoBefore without regularInputs) union newRegularOutputsWithUTxODeposits" ordinaryUTxOTransition
  it "records the allocated UTxO capacity deposit alongside each newly created store-backed output" recordsDepositWithCreatedOutput
  it "removes a spent output's UTxO capacity deposit record and releases its UTxO capacity deposit exactly once" removesAndReleasesSpentRecordOnce
  it "keeps UTxO capacity deposit records unchanged when outputs are only referenced" preservesReferencedOutputRecords
  it "keeps Σ(live allocated UTxO capacity deposits) equal to outstanding UTxO capacity deposit obligations" matchesLiveDepositsToObligations
  it "does not leave missing or orphan UTxO capacity deposit records after accepted transitions" preservesRecordConsistency
  it "preserves allocated UTxO capacity deposits through state serialization and restoration" preservesDepositsThroughStateRestoration
  it "restores outputs, UTxO capacity deposit records and Store balance together on rollback" rollsBackOutputsRecordsAndBalanceTogether
{- FOURMOLU_ENABLE -}

releasedDepositsMatchRecords :: Bool
releasedDepositsMatchRecords = False

ordinaryUTxOTransition :: Bool
ordinaryUTxOTransition = False

recordsDepositWithCreatedOutput :: Expectation
recordsDepositWithCreatedOutput = False `shouldBe` True

removesAndReleasesSpentRecordOnce :: Expectation
removesAndReleasesSpentRecordOnce = False `shouldBe` True

preservesReferencedOutputRecords :: Expectation
preservesReferencedOutputRecords = False `shouldBe` True

matchesLiveDepositsToObligations :: Expectation
matchesLiveDepositsToObligations = False `shouldBe` True

preservesRecordConsistency :: Expectation
preservesRecordConsistency = False `shouldBe` True

preservesDepositsThroughStateRestoration :: Expectation
preservesDepositsThroughStateRestoration = False `shouldBe` True

rollsBackOutputsRecordsAndBalanceTogether :: Expectation
rollsBackOutputsRecordsAndBalanceTogether = False `shouldBe` True
