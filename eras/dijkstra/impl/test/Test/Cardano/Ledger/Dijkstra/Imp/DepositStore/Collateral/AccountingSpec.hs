module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.AccountingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "Collateral funds UTxO capacity deposits before covering its minimum fee (DS-COLL-002)" $ do
  it "reuses released UTxO capacity deposits when the collateral return requires the same amount" reusesReleasedDeposits
  it "credits excess released UTxO capacity deposits to fees rather than the treasury" creditsReleasedSurplusToFees
  prop "accepted phase-2 failure ⇒ feesAfter = feesBefore + collateralCoinFee + releasedUTxODepositFee" addsReleasedSurplusToFees
  prop "accepted phase-2 failure ⇒ treasuryAfter = treasuryBefore" preservesTreasury
  it "funds additional return UTxO capacity deposits from collateral coins" fundsAdditionalReturnDeposit
  it "requires the collateral minimum after funding the return and additional UTxO capacity deposits" requiresMinimumFeeAfterReturnFunding
  prop "accepted phase-2 failure ⇒ collateralCoinFee ≥ ceil(txFee * collateralPercentage / 100)" fundsMinimumFeeIndependently
  it "does not use released UTxO capacity deposit surplus to satisfy the collateral minimum" surplusCannotFundMinimumFee
  it "does not use released UTxO capacity deposit surplus to fund a larger collateral return" surplusCannotFundLargerReturn
  it "rejects a collateral funding shortfall of one lovelace" rejectsOneLovelaceShortfall
  it "settles multiple collateral inputs with no return output" settlesInputsWithoutReturn
  it "counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs" mixedInputsCountImplicitCoinsWithoutStoreRelease
  it "allocates no Store deposit to an implicit collateral return even when consuming store-backed collateral inputs" implicitReturnRequiresNoStoreAllocation
  it "accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded" zeroApplicationAdaReturnIsAccepted
  it "conserves ADA across collateral inputs, return, Store and fees" conservesCollateralValue
  prop "accepted phase-2 failure ⇒ collateralInputCoins + releasedUTxODeposits = collateralReturnCoins + collateralReturnUTxODeposit + collateralFee" conservesCollateralAda
{- FOURMOLU_ENABLE -}

reusesReleasedDeposits :: Expectation
reusesReleasedDeposits = False `shouldBe` True

creditsReleasedSurplusToFees :: Expectation
creditsReleasedSurplusToFees = False `shouldBe` True

addsReleasedSurplusToFees :: Bool
addsReleasedSurplusToFees = False

preservesTreasury :: Bool
preservesTreasury = False

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

settlesInputsWithoutReturn :: Expectation
settlesInputsWithoutReturn = False `shouldBe` True

mixedInputsCountImplicitCoinsWithoutStoreRelease :: Expectation
mixedInputsCountImplicitCoinsWithoutStoreRelease = False `shouldBe` True

implicitReturnRequiresNoStoreAllocation :: Expectation
implicitReturnRequiresNoStoreAllocation = False `shouldBe` True

zeroApplicationAdaReturnIsAccepted :: Expectation
zeroApplicationAdaReturnIsAccepted = False `shouldBe` True

conservesCollateralValue :: Expectation
conservesCollateralValue = False `shouldBe` True

conservesCollateralAda :: Bool
conservesCollateralAda = False
