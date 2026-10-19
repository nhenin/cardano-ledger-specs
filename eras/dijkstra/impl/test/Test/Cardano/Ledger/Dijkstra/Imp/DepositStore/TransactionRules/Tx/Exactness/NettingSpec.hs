-- | Exactness rejects both understated and overstated declarations.
-- The remaining netting requirements stay visible as executable backlog.
--
-- Contract: for an explicit TopTx declaration and exact SubTx contributions,
-- compare the isolated netting validator with declared batch change == independently
-- required batch change. Include accepted controls and invalid totals. In ledger
-- fixtures, preserve financial balance or assert the netting failure, so ordinary
-- conservation cannot stand in for exactness. Validation applies on both phase-2
-- outcomes; State.Execution alone selects the actual applied Store transfer.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Exactness.NettingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core (injectFailure)
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import Cardano.Ledger.Val (Val ((<->)))
import Test.Cardano.Ledger.Common (Expectation, Spec, describe, forAll, it, prop, shouldBe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  fundReleaseScenario,
  submitTxAndExpectFailureContaining,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (fixupTx, rederiveAddrTxWits)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-EXACTNESS-NETTING - Netting" $ do
    prop "DS-TX-EXACTNESS-NETTING-P01 - passes netting validation ⇔ declaredTxTotalNetUTxODepositChange = requiredTxTotalNetUTxODepositChange" totalNetChangeEqualsSumOfBodyChanges
    it "DS-TX-EXACTNESS-NETTING-N01 - includes both TopTx and SubTx UTxO capacity deposit changes in the declared total" totalIncludesTopTxAndSubTxChanges
    it "DS-TX-EXACTNESS-NETTING-N02 - nets a 5 ADA allocation and a 3 ADA release into a TopTx allocation of 2 ADA" allocationExceedsRelease
    it "DS-TX-EXACTNESS-NETTING-N03 - nets a 3 ADA allocation and a 5 ADA release into a TopTx release of 2 ADA" releaseExceedsAllocation
    it "DS-TX-EXACTNESS-NETTING-N04 - uses TopTx explicit zero when nonzero body contributions cancel exactly" allocationsAndReleasesCancel
    prop "DS-TX-EXACTNESS-NETTING-F01 - rejects a TopTx net allocation one lovelace below the required batch total" $
      forAll TopTx.standaloneTopTxRequiringNetAllocation $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <-> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
    prop "DS-TX-EXACTNESS-NETTING-F02 - rejects a TopTx net allocation one lovelace above the required batch total" $
      forAll TopTx.standaloneTopTxRequiringNetAllocation $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
    prop "DS-TX-EXACTNESS-NETTING-F03 - rejects a TopTx net release one lovelace below the required batch release" $
      forAll TopTx.standaloneTopTxOnlyImplicitOutputs $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
    prop "DS-TX-EXACTNESS-NETTING-F04 - rejects a TopTx net release one lovelace above the required batch release" $
      forAll TopTx.standaloneTopTxOnlyImplicitOutputs $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <-> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
    it "DS-TX-EXACTNESS-NETTING-F05 - rejects TopTx explicit zero when the required batch total is nonzero" topTxZeroCannotReplaceNonzeroBatchTotal
    it "DS-TX-EXACTNESS-NETTING-F06 - rejects a nonzero TopTx declaration when the required batch total is zero" nonzeroTopTxTotalCannotReplaceZero
    it "DS-TX-EXACTNESS-NETTING-F07 - rejects a TopTx declaration whose sign opposes the required batch total" topTxTotalMustHaveRequiredSign
    it "DS-TX-EXACTNESS-NETTING-N05 - accepts TopTx explicit zero when its own release is offset by SubTx allocations" ownTopTxReleaseCanHaveZeroBatchTotal
    it "DS-TX-EXACTNESS-NETTING-N06 - accepts TopTx explicit zero when its own allocation is offset by SubTx releases" ownTopTxAllocationCanHaveZeroBatchTotal
    it "DS-TX-EXACTNESS-NETTING-N07 - accepts an exact TopTx batch total on the phase-2 failure path" exactTopTxTotalPassesOnPhase2Failure
    it "DS-TX-EXACTNESS-NETTING-F08 - rejects an inexact TopTx batch total even when phase 2 fails" inexactTopTxTotalFailsOnPhase2Failure
    it "DS-TX-EXACTNESS-NETTING-F09 - rejects a TopTx total that omits or double-counts a delegated contribution" delegatedContributionAppearsOnceInTopTxTotal
{- FOURMOLU_ENABLE -}

-- | Passes netting validation ⇔ declaredTxTotalNetUTxODepositChange = requiredTxTotalNetUTxODepositChange
-- Executable backlog: replace with a ledger check against independent expectations.
totalNetChangeEqualsSumOfBodyChanges :: Bool
totalNetChangeEqualsSumOfBodyChanges = False

-- | Includes both TopTx and SubTx UTxO capacity deposit changes in the declared total
-- Executable backlog: replace with a ledger check against independent expectations.
totalIncludesTopTxAndSubTxChanges :: Expectation
totalIncludesTopTxAndSubTxChanges = False `shouldBe` True

-- | Nets a 5 ADA allocation and a 3 ADA release into a TopTx allocation of 2 ADA
-- Executable backlog: replace with a ledger check against independent expectations.
allocationExceedsRelease :: Expectation
allocationExceedsRelease = False `shouldBe` True

-- | Nets a 3 ADA allocation and a 5 ADA release into a TopTx release of 2 ADA
-- Executable backlog: replace with a ledger check against independent expectations.
releaseExceedsAllocation :: Expectation
releaseExceedsAllocation = False `shouldBe` True

-- | Uses TopTx explicit zero when nonzero body contributions cancel exactly
-- Executable backlog: replace with a ledger check against independent expectations.
allocationsAndReleasesCancel :: Expectation
allocationsAndReleasesCancel = False `shouldBe` True

-- | Rejects TopTx explicit zero when the required batch total is nonzero
-- Executable backlog: replace with a ledger check against independent expectations.
topTxZeroCannotReplaceNonzeroBatchTotal :: Expectation
topTxZeroCannotReplaceNonzeroBatchTotal = False `shouldBe` True

-- | Rejects a nonzero TopTx declaration when the required batch total is zero
-- Executable backlog: replace with a ledger check against independent expectations.
nonzeroTopTxTotalCannotReplaceZero :: Expectation
nonzeroTopTxTotalCannotReplaceZero = False `shouldBe` True

-- | Rejects a TopTx declaration whose sign opposes the required batch total
-- Executable backlog: replace with a ledger check against independent expectations.
topTxTotalMustHaveRequiredSign :: Expectation
topTxTotalMustHaveRequiredSign = False `shouldBe` True

-- | Accepts TopTx explicit zero when its own release is offset by SubTx allocations
-- Executable backlog: replace with a ledger check against independent expectations.
ownTopTxReleaseCanHaveZeroBatchTotal :: Expectation
ownTopTxReleaseCanHaveZeroBatchTotal = False `shouldBe` True

-- | Accepts TopTx explicit zero when its own allocation is offset by SubTx releases
-- Executable backlog: replace with a ledger check against independent expectations.
ownTopTxAllocationCanHaveZeroBatchTotal :: Expectation
ownTopTxAllocationCanHaveZeroBatchTotal = False `shouldBe` True

-- | Accepts an exact TopTx batch total on the phase-2 failure path
-- Executable backlog: replace with a ledger check against independent expectations.
exactTopTxTotalPassesOnPhase2Failure :: Expectation
exactTopTxTotalPassesOnPhase2Failure = False `shouldBe` True

-- | Rejects an inexact TopTx batch total even when phase 2 fails
-- Executable backlog: replace with a ledger check against independent expectations.
inexactTopTxTotalFailsOnPhase2Failure :: Expectation
inexactTopTxTotalFailsOnPhase2Failure = False `shouldBe` True

-- | Rejects a TopTx total that omits or double-counts a delegated contribution
-- Executable backlog: replace with a ledger check against independent expectations.
delegatedContributionAppearsOnceInTopTxTotal :: Expectation
delegatedContributionAppearsOnceInTopTxTotal = False `shouldBe` True
