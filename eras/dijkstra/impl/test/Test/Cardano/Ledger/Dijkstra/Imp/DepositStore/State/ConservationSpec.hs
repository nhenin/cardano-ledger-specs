module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.State.ConservationSpec (spec) where

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
includesStoreInMonetaryConservation = False `shouldBe` True
