-- | Collateral coins fund the specified return, additional capacity deposit and minimum fee.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.FundingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- Both output variants are fixture coverage across these funding cases and the
-- authorization, settlement and conservation checks; they are not a separate rule.
-- Funding validation covers both script outcomes whenever any body has redeemers.
-- Observe required amounts and acceptance here; State owns applied Store records.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-FUNDING - Funding" $ do
  it "DS-COLLATERAL-FUNDING-F01 - rejects insufficient collateral funding when redeemers trigger validation even if all scripts succeed" successfulScriptsDoNotBypassCollateralFunding
  it "DS-COLLATERAL-FUNDING-N01 - accepts a batch whose scripts succeed when its required collateral is fully funded and all other rules hold" successfulScriptsAcceptValidCollateral
  it "DS-COLLATERAL-FUNDING-N02 - accepts funded collateral with implicit or store-backed inputs and returns" supportsBothOutputVariants
  it "DS-COLLATERAL-FUNDING-N03 - reuses released UTxO capacity deposits when the collateral return requires the same amount" reusesReleasedDeposits
  it "DS-COLLATERAL-FUNDING-N04 - funds additional return UTxO capacity deposits from collateral coins" fundsAdditionalReturnDeposit
  it "DS-COLLATERAL-FUNDING-F02 - rejects collateral coins below the minimum fee after funding the return and additional UTxO capacity deposits" requiresMinimumFeeAfterReturnFunding
  prop "DS-COLLATERAL-FUNDING-P01 - accepted batch with redeemers ⇒ collateralCoinFee ≥ ceil(txFee * collateralPercentage / 100)" fundsMinimumFeeIndependently
  it "DS-COLLATERAL-FUNDING-F03 - rejects collateral whose minimum fee depends on released UTxO capacity deposit surplus" surplusCannotFundMinimumFee
  it "DS-COLLATERAL-FUNDING-F04 - rejects a collateral return whose funding depends on released UTxO capacity deposit surplus" surplusCannotFundLargerReturn
  it "DS-COLLATERAL-FUNDING-F05 - rejects collateral funding one lovelace below a rounded-up minimum fee" rejectsOneLovelaceShortfall
  it "DS-COLLATERAL-FUNDING-N05 - counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs" mixedInputsCountImplicitCoinsWithoutStoreRelease
  it "DS-COLLATERAL-FUNDING-N06 - requires zero Store deposit for an implicit collateral return even with store-backed collateral inputs" implicitReturnRequiresNoStoreDeposit
  it "DS-COLLATERAL-FUNDING-N07 - accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded" zeroApplicationAdaReturnIsAccepted
  it "DS-COLLATERAL-FUNDING-F06 - rejects underfunded collateral when the optional total is absent" checksFundingWithoutDeclaredTotal
  it "DS-COLLATERAL-FUNDING-N08 - accepts collateral funding exactly at a rounded-up minimum fee" acceptsRoundedUpMinimumFee
{- FOURMOLU_ENABLE -}

successfulScriptsDoNotBypassCollateralFunding :: Expectation
successfulScriptsDoNotBypassCollateralFunding = False `shouldBe` True

successfulScriptsAcceptValidCollateral :: Expectation
successfulScriptsAcceptValidCollateral = False `shouldBe` True

supportsBothOutputVariants :: Expectation
supportsBothOutputVariants = False `shouldBe` True

reusesReleasedDeposits :: Expectation
reusesReleasedDeposits = False `shouldBe` True

fundsAdditionalReturnDeposit :: Expectation
fundsAdditionalReturnDeposit = False `shouldBe` True

requiresMinimumFeeAfterReturnFunding :: Expectation
requiresMinimumFeeAfterReturnFunding = False `shouldBe` True

fundsMinimumFeeIndependently :: Bool
fundsMinimumFeeIndependently = False

surplusCannotFundMinimumFee :: Expectation
surplusCannotFundMinimumFee = False `shouldBe` True

surplusCannotFundLargerReturn :: Expectation
surplusCannotFundLargerReturn = False `shouldBe` True

rejectsOneLovelaceShortfall :: Expectation
rejectsOneLovelaceShortfall = False `shouldBe` True

mixedInputsCountImplicitCoinsWithoutStoreRelease :: Expectation
mixedInputsCountImplicitCoinsWithoutStoreRelease = False `shouldBe` True

implicitReturnRequiresNoStoreDeposit :: Expectation
implicitReturnRequiresNoStoreDeposit = False `shouldBe` True

zeroApplicationAdaReturnIsAccepted :: Expectation
zeroApplicationAdaReturnIsAccepted = False `shouldBe` True

checksFundingWithoutDeclaredTotal :: Expectation
checksFundingWithoutDeclaredTotal = False `shouldBe` True

acceptsRoundedUpMinimumFee :: Expectation
acceptsRoundedUpMinimumFee = False `shouldBe` True
