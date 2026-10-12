-- | Collateral inputs retain the existing key-control requirements.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.AuthorizationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-AUTHORIZATION - Authorization" $ do
  it "DS-COLLATERAL-AUTHORIZATION-F01 - rejects collateral inputs that fail the existing key-control checks" preservesExistingKeyControlChecks
{- FOURMOLU_ENABLE -}

preservesExistingKeyControlChecks :: Expectation
preservesExistingKeyControlChecks = False `shouldBe` True
