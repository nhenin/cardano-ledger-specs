-- | Excess released collateral capacity deposits are credited to the fee pot.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.SurplusSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
-- Compare actual fee and treasury pots after an accepted phase-2 failure. Derive
-- expected credits from the fixture; State owns Store balances and path selection.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-SURPLUS - Surplus" $ do
  it "DS-COLLATERAL-SURPLUS-N01 - credits excess released UTxO capacity deposits to fees rather than the treasury" creditsReleasedSurplusToFees
  prop "DS-COLLATERAL-SURPLUS-P01 - accepted phase-2 failure ⇒ feesAfter = feesBefore + collateralCoinFee + releasedUTxODepositFee" addsReleasedSurplusToFees
  prop "DS-COLLATERAL-SURPLUS-P02 - accepted phase-2 failure ⇒ treasuryAfter = treasuryBefore" preservesTreasury
{- FOURMOLU_ENABLE -}

creditsReleasedSurplusToFees :: Expectation
creditsReleasedSurplusToFees = False `shouldBe` True

addsReleasedSurplusToFees :: Bool
addsReleasedSurplusToFees = False

preservesTreasury :: Bool
preservesTreasury = False
