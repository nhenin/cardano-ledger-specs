module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.SolvencySpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Each accepted state has enough Store ADA to cover its outstanding obligations.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-SOLVENCY - Solvency" $ do
  prop "DS-STATE-SOLVENCY-P01 - ordinary success ⇒ storeBalanceAfter ≥ totalUTxODepositsAfter ≥ 0" solvency
  it "DS-STATE-SOLVENCY-N01 - keeps the Store balance at least equal to outstanding UTxO capacity deposit obligations" keepsBalanceAboveObligations
  it "DS-STATE-SOLVENCY-F01 - rejects a transition that would leave the Store insolvent" rejectsInsolventTransition
  it "DS-STATE-SOLVENCY-N02 - checks the accepted batch result without requiring each SubTx to balance independently" checksCompleteBatchSolvency
  it "DS-STATE-SOLVENCY-N03 - fixed pricing and a solvent initial state ⇒ epoch transitions preserve Store solvency" preservesSolvencyAcrossFixedPolicyEpochs
{- FOURMOLU_ENABLE -}

solvency :: Bool
solvency = False

keepsBalanceAboveObligations :: Expectation
keepsBalanceAboveObligations = False `shouldBe` True

rejectsInsolventTransition :: Expectation
rejectsInsolventTransition = False `shouldBe` True

checksCompleteBatchSolvency :: Expectation
checksCompleteBatchSolvency = False `shouldBe` True

preservesSolvencyAcrossFixedPolicyEpochs :: Expectation
preservesSolvencyAcrossFixedPolicyEpochs = False `shouldBe` True
