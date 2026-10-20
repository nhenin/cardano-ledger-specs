-- | Generated Store operations for TopTx's settlement designation requirement.
-- Counts establish the mathematical premises; the specs supply every declaration.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement.Designation (
  netReleaseWithAnyTopTxShare,
  allReleasesSettledBySubTxs,
  topTxReleasesDeposits,
  releasesSplitAcrossBodies,
  localAllocationsReduceBatchRelease,
  netAllocation,
  zeroTotalWithTopTxRelease,
  positiveTopTxShare,
  bothDesignationBranches,
  validateDesignation,
) where

import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (DepositStoreAccountingFailure, validateTopTxSettlement)
import Data.List.NonEmpty (NonEmpty)
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, vectorOf)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario,
  bodyOperations,
  scenario,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import Validation (Validation)

-- | A negative total with positive, zero or negative TopTx own change. The single
-- child's release exceeds TopTx's allocations; the spec tests local and delegated
-- accounting for that same release and both possible designation forms.
netReleaseWithAnyTopTxShare :: Gen AccountingScenario
netReleaseWithAnyTopTxShare = do
  allocated <- chooseInt (0, 3)
  released <- chooseInt (0, 3)
  childRelease <- chooseInt (allocated + 1, allocated + 3)
  scenario (bodyOperations allocated released) [bodyOperations 0 childRelease]

-- | One to three children release positive deposits; TopTx has no Store operations.
-- Local declarations therefore leave no release share for TopTx.
allReleasesSettledBySubTxs :: Gen AccountingScenario
allReleasesSettledBySubTxs = do
  count <- chooseInt (1, 3)
  released <- vectorOf count $ chooseInt (1, 3)
  scenario (bodyOperations 0 0) $ map (bodyOperations 0) released

-- | Standalone TopTx consumes one to three Store allocations and creates none.
topTxReleasesDeposits :: Gen AccountingScenario
topTxReleasesDeposits = do
  released <- chooseInt (1, 3)
  scenario (bodyOperations 0 released) []

-- | TopTx and one to three children each release a positive amount locally.
releasesSplitAcrossBodies :: Gen AccountingScenario
releasesSplitAcrossBodies = do
  ownRelease <- chooseInt (1, 3)
  count <- chooseInt (1, 3)
  childReleases <- vectorOf count $ chooseInt (1, 3)
  scenario (bodyOperations 0 ownRelease) $ map (bodyOperations 0) childReleases

-- | TopTx releases more than a child locally allocates. Thus its required output
-- amount exceeds the complete transaction's net release.
localAllocationsReduceBatchRelease :: Gen AccountingScenario
localAllocationsReduceBatchRelease = do
  allocation <- chooseInt (1, 3)
  remainingRelease <- chooseInt (1, 3)
  scenario (bodyOperations 0 $ allocation + remainingRelease) [bodyOperations allocation 0]

-- | TopTx releases deposits but a larger local child allocation makes the total
-- positive. The allocation declaration has no settlement selector.
netAllocation :: Gen AccountingScenario
netAllocation = do
  released <- chooseInt (1, 3)
  extraAllocation <- chooseInt (1, 3)
  scenario (bodyOperations 0 released) [bodyOperations (released + extraAllocation) 0]

-- | Equal TopTx release and local child allocation make the total exactly zero,
-- while TopTx's attributed change remains negative.
zeroTotalWithTopTxRelease :: Gen AccountingScenario
zeroTotalWithTopTxRelease = do
  amount <- chooseInt (1, 3)
  scenario (bodyOperations 0 amount) [bodyOperations amount 0]

-- | A local child release exceeds TopTx's own allocation. The batch releases,
-- but TopTx's own positive share requires NoTopTxSettlement.
positiveTopTxShare :: Gen AccountingScenario
positiveTopTxShare = do
  allocation <- chooseInt (1, 3)
  extraRelease <- chooseInt (1, 3)
  scenario (bodyOperations allocation 0) [bodyOperations 0 $ allocation + extraRelease]

-- | A required TopTx designation and a zero TopTx release share in every sample.
-- Used on the actual phase-2 failure path so neither branch is left to random chance.
bothDesignationBranches :: Gen (AccountingScenario, AccountingScenario)
bothDesignationBranches = (,) <$> topTxReleasesDeposits <*> allReleasesSettledBySubTxs

-- | Observe only the production designation validator. Generated output zero is
-- valid and sufficiently funded, so index/coin checks cannot mask this contract.
validateDesignation :: ReleaseTx -> Validation (NonEmpty DepositStoreAccountingFailure) ()
validateDesignation = validateTopTxSettlement . (^. bodyTxL) . unsignedTx
