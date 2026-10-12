module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.InitializationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | The Conway upgrade preserves implicit outputs and initializes the Store without extracting existing funds.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-INITIALIZATION - Initialization" $ do
  it "DS-STATE-INITIALIZATION-N01 - preserves existing output references and values and keeps those outputs implicit" preservesTranslatedImplicitOutputs
  it "DS-STATE-INITIALIZATION-N02 - initializes Store balance and UTxO capacity deposit obligations to zero" initializesEmptyStore
  it "DS-STATE-INITIALIZATION-N03 - does not transfer funds from another ledger pot during initialization" leavesExistingLedgerPotsUnchanged
{- FOURMOLU_ENABLE -}

preservesTranslatedImplicitOutputs :: Expectation
preservesTranslatedImplicitOutputs = False `shouldBe` True

initializesEmptyStore :: Expectation
initializesEmptyStore = False `shouldBe` True

leavesExistingLedgerPotsUnchanged :: Expectation
leavesExistingLedgerPotsUnchanged = False `shouldBe` True
