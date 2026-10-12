module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.VotingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Neither allocated deposits nor the global Store balance contribute additional voting power.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-VOTING - Voting" $ do
  it "DS-VOTING-N01 - does not count allocated UTxO capacity deposits or Store balance as additional voting power" excludesDepositsFromVotingPower
{- FOURMOLU_ENABLE -}

excludesDepositsFromVotingPower :: Expectation
excludesDepositsFromVotingPower = False `shouldBe` True
