module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.ValidationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLL-001 - Collateral retains its existing validation trigger" $ do
  it "requires collateral when TopTx has redeemers" requiresCollateralForTopTxRedeemers
  it "requires collateral when only a SubTx has redeemers" requiresCollateralForSubTxRedeemers
  it "requires collateral when both TopTx and SubTxs have redeemers" requiresCollateralForBothRedeemers
  it "rejects insufficient collateral funding when redeemers trigger validation even if all scripts succeed" successfulScriptsDoNotBypassCollateralFunding
  it "accepts a batch whose scripts succeed when its required collateral is fully funded and all other rules hold" successfulScriptsAcceptValidCollateral
  it "does not require collateral merely because a transaction uses the DepositStore" storeActivityAloneNeedsNoCollateral
  it "supports implicit and store-backed collateral inputs and returns" supportsBothOutputVariants
  it "preserves the existing key-control and native-asset checks" preservesExistingCollateralChecks
{- FOURMOLU_ENABLE -}

requiresCollateralForTopTxRedeemers :: Expectation
requiresCollateralForTopTxRedeemers = False `shouldBe` True

requiresCollateralForSubTxRedeemers :: Expectation
requiresCollateralForSubTxRedeemers = False `shouldBe` True

requiresCollateralForBothRedeemers :: Expectation
requiresCollateralForBothRedeemers = False `shouldBe` True

successfulScriptsDoNotBypassCollateralFunding :: Expectation
successfulScriptsDoNotBypassCollateralFunding = False `shouldBe` True

successfulScriptsAcceptValidCollateral :: Expectation
successfulScriptsAcceptValidCollateral = False `shouldBe` True

storeActivityAloneNeedsNoCollateral :: Expectation
storeActivityAloneNeedsNoCollateral = False `shouldBe` True

supportsBothOutputVariants :: Expectation
supportsBothOutputVariants = False `shouldBe` True

preservesExistingCollateralChecks :: Expectation
preservesExistingCollateralChecks = False `shouldBe` True
