-- | Collateral settlement preserves ADA and the existing native-asset conservation checks.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.ConservationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-CONSERVATION - Conservation" $ do
  it "DS-COLLATERAL-CONSERVATION-N01 - conserves ADA across collateral inputs, return, Store and fees" conservesCollateralValue
  prop "DS-COLLATERAL-CONSERVATION-P01 - accepted phase-2 failure ⇒ collateralInputCoins + releasedUTxODeposits = collateralReturnCoins + collateralReturnUTxODeposit + collateralFee" conservesCollateralAda
  it "DS-COLLATERAL-CONSERVATION-F01 - rejects a collateral native-asset imbalance" preservesExistingNativeAssetChecks
{- FOURMOLU_ENABLE -}

conservesCollateralValue :: Expectation
conservesCollateralValue = False `shouldBe` True

conservesCollateralAda :: Bool
conservesCollateralAda = False

preservesExistingNativeAssetChecks :: Expectation
preservesExistingNativeAssetChecks = False `shouldBe` True
