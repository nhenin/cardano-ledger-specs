module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Collateral.TransitionSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLL-004 - Collateral settlement is derived from the applied failure path" $ do
  it "derives Store changes from collateral inputs and return without a separate declaration" derivesSettlementFromCollateral
  it "does not let ordinary Store declarations change collateral settlement" ordinaryDeclarationsCannotChangeSettlement
  it "applies ordinary Store operations and leaves collateral untouched on success" successLeavesCollateralUntouched
  it "applies collateral settlement and no ordinary Store operations on an accepted phase-2 failure" phaseTwoFailureAppliesOnlyCollateral
  it "consumes only collateral inputs and creates only the specified collateral return in the UTxO on an accepted phase-2 failure" phaseTwoFailureChangesOnlyCollateralUTxO
  it "removes consumed store-backed collateral records and records the return only when store-backed, preserving records outside collateral inputs on an accepted phase-2 failure" phaseTwoFailureChangesOnlyCollateralDepositRecords
  prop "accepted phase-2 failure ⇒ storeBalanceAfter = storeBalanceBefore + collateralReturnUTxODeposit - releasedUTxODeposits" updatesStoreBalance
  prop "accepted phase-2 failure ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + collateralReturnUTxODeposit - releasedUTxODeposits" updatesDepositObligations
  it "leaves the entire ledger state unchanged on rejection, including UTxO, allocated deposit records and Store balance" rejectionLeavesLedgerUntouched
  prop "batch rejected ⇒ acceptedLedgerStateAfter = acceptedLedgerStateBefore" preservesRejectedState
{- FOURMOLU_ENABLE -}

derivesSettlementFromCollateral :: Expectation
derivesSettlementFromCollateral = False `shouldBe` True

ordinaryDeclarationsCannotChangeSettlement :: Expectation
ordinaryDeclarationsCannotChangeSettlement = False `shouldBe` True

successLeavesCollateralUntouched :: Expectation
successLeavesCollateralUntouched = False `shouldBe` True

phaseTwoFailureAppliesOnlyCollateral :: Expectation
phaseTwoFailureAppliesOnlyCollateral = False `shouldBe` True

phaseTwoFailureChangesOnlyCollateralUTxO :: Expectation
phaseTwoFailureChangesOnlyCollateralUTxO = False `shouldBe` True

phaseTwoFailureChangesOnlyCollateralDepositRecords :: Expectation
phaseTwoFailureChangesOnlyCollateralDepositRecords = False `shouldBe` True

updatesStoreBalance :: Bool
updatesStoreBalance = False

updatesDepositObligations :: Bool
updatesDepositObligations = False

rejectionLeavesLedgerUntouched :: Expectation
rejectionLeavesLedgerUntouched = False `shouldBe` True

preservesRejectedState :: Bool
preservesRejectedState = False
