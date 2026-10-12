module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.AllocationsSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Live store-backed outputs retain exactly their allocated amounts, which determine their release and outstanding obligations.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-ALLOCATIONS - Allocations" $ do
  prop "DS-STATE-ALLOCATIONS-P01 - ordinary success ⇒ releasedUTxODeposits = Σ(allocatedUTxODeposit(utxo[input])) over consumed store-backed inputs" releasedDepositsMatchRecords
  it "DS-STATE-ALLOCATIONS-N01 - records the allocated UTxO capacity deposit alongside each newly created store-backed output" recordsDepositWithCreatedOutput
  it "DS-STATE-ALLOCATIONS-N02 - removes a spent output's UTxO capacity deposit record and releases its UTxO capacity deposit exactly once" removesAndReleasesSpentRecordOnce
  it "DS-STATE-ALLOCATIONS-N03 - keeps UTxO capacity deposit records unchanged when outputs are only referenced" preservesReferencedOutputRecords
  it "DS-STATE-ALLOCATIONS-N04 - keeps Σ(live allocated UTxO capacity deposits) equal to outstanding UTxO capacity deposit obligations" matchesLiveDepositsToObligations
  it "DS-STATE-ALLOCATIONS-N05 - does not leave missing or orphan UTxO capacity deposit records after accepted transitions" preservesRecordConsistency
  it "DS-STATE-ALLOCATIONS-N06 - releases the allocated UTxO capacity deposit even when reserialization would change the output size" releasesRecordedDepositAfterReserialization
  it "DS-STATE-ALLOCATIONS-N07 - does not release UTxO capacity deposits from the DepositStore when a translated implicit output is spent" spendsTranslatedOutputWithoutStoreRelease
  prop "DS-STATE-ALLOCATIONS-P02 - ordinary success ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + txTotalNetUTxODepositChange" successObligationDelta
  it "DS-STATE-ALLOCATIONS-N08 - removes consumed store-backed collateral records and records the return only when store-backed, preserving records outside collateral inputs on an accepted phase-2 failure" phaseTwoFailureChangesOnlyCollateralDepositRecords
  prop "DS-STATE-ALLOCATIONS-P03 - accepted phase-2 failure ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + collateralReturnUTxODeposit - releasedUTxODeposits" updatesDepositObligations
{- FOURMOLU_ENABLE -}

releasedDepositsMatchRecords :: Bool
releasedDepositsMatchRecords = False

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

releasesRecordedDepositAfterReserialization :: Expectation
releasesRecordedDepositAfterReserialization = False `shouldBe` True

spendsTranslatedOutputWithoutStoreRelease :: Expectation
spendsTranslatedOutputWithoutStoreRelease = False `shouldBe` True

successObligationDelta :: Bool
successObligationDelta = False

phaseTwoFailureChangesOnlyCollateralDepositRecords :: Expectation
phaseTwoFailureChangesOnlyCollateralDepositRecords = False `shouldBe` True

updatesDepositObligations :: Bool
updatesDepositObligations = False
