-- | Collateral settlement preserves ADA and the existing native-asset conservation checks.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.ConservationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- ADA observations use applied collateral effects after accepted phase-2 failure.
-- Native-asset validation covers both script outcomes while its trigger is active.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-CONSERVATION - Conservation" $ do
  it "DS-COLLATERAL-CONSERVATION-N01 - conserves ADA for mixed collateral inputs when return storage needs an additional deposit" conservesMixedCollateralWithDepositShortfall
  prop "DS-COLLATERAL-CONSERVATION-P01 - accepted phase-2 failure ⇒ collateralInputCoins + releasedUTxODeposits = collateralReturnCoins + collateralReturnUTxODeposit + collateralFee" conservesCollateralAda
  it "DS-COLLATERAL-CONSERVATION-F01 - rejects missing, added or changed native assets in the collateral return" rejectsCollateralAssetImbalance
  it "DS-COLLATERAL-CONSERVATION-N02 - accepts native-asset collateral when its return preserves every asset and quantity" acceptsBalancedCollateralAssets
  it "DS-COLLATERAL-CONSERVATION-F02 - rejects token-bearing collateral when no return is specified" rejectsUnreturnedCollateralAssets
{- FOURMOLU_ENABLE -}

conservesMixedCollateralWithDepositShortfall :: Expectation
conservesMixedCollateralWithDepositShortfall = False `shouldBe` True

conservesCollateralAda :: Bool
conservesCollateralAda = False

rejectsCollateralAssetImbalance :: Expectation
rejectsCollateralAssetImbalance = False `shouldBe` True

acceptsBalancedCollateralAssets :: Expectation
acceptsBalancedCollateralAssets = False `shouldBe` True

rejectsUnreturnedCollateralAssets :: Expectation
rejectsUnreturnedCollateralAssets = False `shouldBe` True
