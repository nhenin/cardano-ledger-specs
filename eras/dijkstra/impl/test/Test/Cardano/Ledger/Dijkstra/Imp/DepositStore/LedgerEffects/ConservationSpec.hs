module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.ConservationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Store ADA remains part of the total monetary balance without counting obligations as another pot.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-CONSERVATION - Conservation" $ do
  it "DS-STATE-CONSERVATION-N01 - still counts Store ADA in total monetary conservation" includesStoreInMonetaryConservation
{- FOURMOLU_ENABLE -}

includesStoreInMonetaryConservation :: Expectation
-- Compare all affected monetary pots before and after ordinary success and accepted
-- phase-2 failure, including a state with positive Store surplus. Count allocation
-- records zero times and actual Store ADA once, independently of the ledger total helper.
-- For collateral, cover mixed input forms and a return needing an additional
-- deposit, as well as equal deposits, released surplus and an absent return:
-- inputCoins + releasedDeposits = returnCoins + returnDeposit + collateralFee.
-- This includes the former DS-COLLATERAL-CONSERVATION-N01/P01 obligations.
includesStoreInMonetaryConservation = False `shouldBe` True
