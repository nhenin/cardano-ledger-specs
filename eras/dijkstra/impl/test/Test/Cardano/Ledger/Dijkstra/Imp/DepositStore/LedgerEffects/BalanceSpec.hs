module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.BalanceSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | The Store balance follows the applied net transfer and preserves surplus on either accepted outcome at fixed prices.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-BALANCE - Balance" $ do
  prop "DS-STATE-BALANCE-P01 - ordinary success with a TopTx declaration ⇒ storeBalanceAfter = storeBalanceBefore + declaredTxTotalNetUTxODepositChange" successStoreDelta
  it "DS-STATE-BALANCE-N01 - changes the balance by exactly the applied allocations minus releases" appliesExactStoreBalanceChange
  prop "DS-STATE-BALANCE-P02 - accepted phase-2 failure ⇒ storeBalanceAfter = storeBalanceBefore + collateralReturnUTxODeposit - releasedUTxODeposits" updatesStoreBalance
  prop "DS-STATE-BALANCE-P03 - fixed pricing and accepted execution ⇒ storeBalanceAfter - totalUTxODepositsAfter = storeBalanceBefore - totalUTxODepositsBefore" surplusInvariant
  it "DS-STATE-BALANCE-N02 - preserves pre-existing Store surplus across ordinary success and accepted phase-2 failure" preservesExistingSurplus
  it "DS-STATE-BALANCE-N03 - applies no ordinary Store transfer when every declaration is absent" absentDeclarationsTransferNothing
{- FOURMOLU_ENABLE -}

successStoreDelta :: Bool
successStoreDelta = False

appliesExactStoreBalanceChange :: Expectation
appliesExactStoreBalanceChange = False `shouldBe` True

updatesStoreBalance :: Bool
updatesStoreBalance = False

surplusInvariant :: Bool
surplusInvariant = False

preservesExistingSurplus :: Expectation
-- Start with a nonzero surplus and cover allocations, releases and zero net change
-- on each accepted outcome. Derive balances and live obligations independently.
preservesExistingSurplus = False `shouldBe` True

-- | Use an accepted implicit-only ordinary transaction with every declaration absent.
-- Compare the actual Store balance and live records before and after submission.
absentDeclarationsTransferNothing :: Expectation
absentDeclarationsTransferNothing = False `shouldBe` True
