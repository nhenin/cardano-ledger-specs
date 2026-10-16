-- | Collateral input eligibility and required payment-key witnesses remain distinct checks.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.AuthorizationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- Exercise both output variants with valid signed controls. Key-locked eligibility
-- uses the collateral trigger; required payment-key witnesses do not depend on it.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-AUTHORIZATION - Authorization" $ do
  it "DS-COLLATERAL-AUTHORIZATION-F01 - rejects a script-controlled collateral input when collateral validation applies" rejectsScriptControlledCollateral
  it "DS-COLLATERAL-AUTHORIZATION-F02 - rejects a key-controlled collateral input whose required payment-key witness is missing" rejectsMissingCollateralKeyWitness
{- FOURMOLU_ENABLE -}

rejectsScriptControlledCollateral :: Expectation
rejectsScriptControlledCollateral = False `shouldBe` True

rejectsMissingCollateralKeyWitness :: Expectation
rejectsMissingCollateralKeyWitness = False `shouldBe` True
