module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.ConwayTransitionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Intentionally failing placeholders for the agreed DepositStore rules.
-- Replace each placeholder with a ledger check against independent expectations.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STORE-004 - The Conway transition starts with an empty Store" $ do
  it "preserves existing output references and values and keeps those outputs implicit" preservesTranslatedImplicitOutputs
  it "initializes Store balance and UTxO capacity deposit obligations to zero" initializesEmptyStore
  it "does not transfer funds from another ledger pot during initialization" leavesExistingLedgerPotsUnchanged
  it "does not release UTxO capacity deposits from the DepositStore when a translated implicit output is spent" spendsTranslatedOutputWithoutStoreRelease
  it "accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding" fundsPostConwayStoreBackedOutputsExactly
  it "rejects a missing allocation declaration when spending a translated implicit output to create store-backed outputs" rejectsMissingPostConwayAllocation
  it "rejects an inexact allocation when spending a translated implicit output to create store-backed outputs" rejectsInexactPostConwayAllocation
{- FOURMOLU_ENABLE -}

preservesTranslatedImplicitOutputs :: Expectation
preservesTranslatedImplicitOutputs = False `shouldBe` True

initializesEmptyStore :: Expectation
initializesEmptyStore = False `shouldBe` True

leavesExistingLedgerPotsUnchanged :: Expectation
leavesExistingLedgerPotsUnchanged = False `shouldBe` True

spendsTranslatedOutputWithoutStoreRelease :: Expectation
spendsTranslatedOutputWithoutStoreRelease = False `shouldBe` True

fundsPostConwayStoreBackedOutputsExactly :: Expectation
fundsPostConwayStoreBackedOutputsExactly = False `shouldBe` True

rejectsMissingPostConwayAllocation :: Expectation
rejectsMissingPostConwayAllocation = False `shouldBe` True

rejectsInexactPostConwayAllocation :: Expectation
rejectsInexactPostConwayAllocation = False `shouldBe` True
