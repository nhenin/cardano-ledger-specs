{-# LANGUAGE DataKinds #-}

-- | Scenarios and independent observations for TopTx total exactness.
-- Child declarations are exact preconditions here; the spec supplies TopTx's
-- declaration explicitly. Prices and recorded releases determine every amount.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx (
  withTopTxAndSubTxChanges,
  withEveryChildDeclarationForm,
  allocatingFiveAdaReleasingThreeAda,
  allocatingThreeAdaReleasingFiveAda,
  withOffsettingBodyChanges,
  withNonzeroTotal,
  withTopTxReleaseOffsetBySubTxAllocations,
  withTopTxAllocationOffsetBySubTxReleases,
  withDelegatedChange,
  allocationAndReleaseDelegation,
  withExactLocalSubTxDeclarations,
  withEveryExactChildDeclarationForm,
  withDelegatedSubTxDeclaration,
  ownNetDeposit,
  requiredNetChange,
  validateNetChange,
  expectedNetChange,
  addTopDeclaration,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  requiredTxTotalNetUTxODeposit,
  validateTopTxExactness,
 )
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.Val ((<->))
import Data.List.NonEmpty (NonEmpty (..))
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, elements)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (liveOutputStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario,
  bodyOperations,
  scenario,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as Children
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Standalone
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as Context
import Validation (Validation (..))

-- | Nonzero child allocations and releases coexist with a zero, allocating or
-- releasing parent. Vary their magnitudes while retaining distinct body changes.
withTopTxAndSubTxChanges :: Gen AccountingScenario
withTopTxAndSubTxChanges = do
  magnitude <- chooseInt (1, 3)
  topChange <- elements [-1, 0, 1]
  scenario
    (bodyOperations (magnitude + topChange) magnitude)
    [bodyOperations (magnitude + 1) 0, bodyOperations 0 magnitude]

-- | Local allocation, delegated allocation, local release, delegated release,
-- explicit zero and absence each have their own child. The two zero-change
-- children differ: one recreates Store outputs, the other has no Store operation.
withEveryChildDeclarationForm :: Gen AccountingScenario
withEveryChildDeclarationForm = do
  magnitude <- chooseInt (1, 3)
  scenario
    (bodyOperations (magnitude + 1) magnitude)
    [ bodyOperations magnitude 0
    , bodyOperations (magnitude + 1) 0
    , bodyOperations 0 magnitude
    , bodyOperations 0 (magnitude + 1)
    , bodyOperations magnitude magnitude
    , bodyOperations 0 0
    ]

-- | Exact aggregate prices: TopTx allocates 2 ADA and releases 1 ADA; its
-- children allocate another 3 ADA and release another 2 ADA.
allocatingFiveAdaReleasingThreeAda :: Gen AccountingScenario
allocatingFiveAdaReleasingThreeAda =
  scenario (bodyOperations 2 1) [bodyOperations 3 0, bodyOperations 0 2]

-- | Exact aggregate prices: TopTx allocates 1 ADA and releases 2 ADA; its
-- children allocate another 2 ADA and release another 3 ADA.
allocatingThreeAdaReleasingFiveAda :: Gen AccountingScenario
allocatingThreeAdaReleasingFiveAda =
  scenario (bodyOperations 1 2) [bodyOperations 2 0, bodyOperations 0 3]

-- | A neutral parent contains two children with equal opposite nonzero changes.
withOffsettingBodyChanges :: Gen AccountingScenario
withOffsettingBodyChanges = do
  magnitude <- chooseInt (1, 3)
  scenario
    (bodyOperations 1 1)
    [bodyOperations magnitude 0, bodyOperations 0 magnitude]

-- | Generate either sign of the complete transaction's nonzero net change.
-- Every body contributes, so a child cannot be accidentally omitted unnoticed.
withNonzeroTotal :: Gen AccountingScenario
withNonzeroTotal = do
  magnitude <- chooseInt (1, 3)
  allocation <- elements [True, False]
  if allocation
    then scenario (bodyOperations magnitude 0) [bodyOperations 1 0]
    else scenario (bodyOperations 0 magnitude) [bodyOperations 0 1]

-- | A parent release is offset by allocations distributed over two children.
withTopTxReleaseOffsetBySubTxAllocations :: Gen AccountingScenario
withTopTxReleaseOffsetBySubTxAllocations = do
  magnitude <- chooseInt (1, 3)
  scenario
    (bodyOperations 0 (magnitude + 1))
    [bodyOperations magnitude 0, bodyOperations 1 0]

-- | A parent allocation is offset by releases distributed over two children.
withTopTxAllocationOffsetBySubTxReleases :: Gen AccountingScenario
withTopTxAllocationOffsetBySubTxReleases = do
  magnitude <- chooseInt (1, 3)
  scenario
    (bodyOperations (magnitude + 1) 0)
    [bodyOperations 0 magnitude, bodyOperations 0 1]

-- | One nonzero child change can be declared as either an allocation request
-- or a release delegated to TopTx. The parent supplies a separate own change.
withDelegatedChange :: Gen AccountingScenario
withDelegatedChange = do
  magnitude <- chooseInt (1, 3)
  allocation <- elements [True, False]
  scenario
    (bodyOperations 2 1)
    [if allocation then bodyOperations magnitude 0 else bodyOperations 0 magnitude]

-- | Both directions of delegation in every generated sample. The parent has
-- its own one-ADA allocation; one scenario's child allocates, the other's releases.
-- Vary the child magnitude and application funding while retaining the same
-- operation plan when comparing local and delegated declarations.
allocationAndReleaseDelegation :: Gen (AccountingScenario, AccountingScenario)
allocationAndReleaseDelegation = do
  magnitude <- chooseInt (1, 3)
  allocation <- scenario (bodyOperations 2 1) [bodyOperations magnitude 0]
  release <- scenario (bodyOperations 2 1) [bodyOperations 0 magnitude]
  pure (allocation, release)

-- | Give every child its independently calculated own declaration, locally
-- accounted. This establishes the child-exactness precondition of TopTx tests;
-- it leaves the parent declaration absent for the calling specification.
withExactLocalSubTxDeclarations :: ReleaseTx -> ReleaseTx
withExactLocalSubTxDeclarations proposal =
  Context.addDeclaration
    ( Declarations TopTx.NoUTxODepositDeclaration $
        zipWith localDeclaration (Children.allocatedDeposits proposal) (Children.releasedDeposits proposal)
    )
    proposal

-- | Assign the six child forms promised by 'withEveryChildDeclarationForm'.
-- Amounts come from each actual body's independent deposit observations.
withEveryExactChildDeclarationForm :: ReleaseTx -> ReleaseTx
withEveryExactChildDeclarationForm proposal =
  Context.addDeclaration
    ( Declarations TopTx.NoUTxODepositDeclaration $
        zipWith3
          declarationForm
          [0 :: Int ..]
          (Children.allocatedDeposits proposal)
          (Children.releasedDeposits proposal)
    )
    proposal

-- | Select delegation only for the two designated children. The two remaining
-- zero-change forms retain the local declaration helper's active/absent distinction.
declarationForm :: Int -> Coin -> Coin -> SubTx.SubTxUTxODepositDeclaration
declarationForm 1 allocated released = case allocated <-> released of
  Coin amount -> SubTx.RequestsUTxODepositFromTopTx $ positiveAmount amount
declarationForm 3 allocated released = case released <-> allocated of
  Coin amount -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) SubTx.DelegateToTopTx
declarationForm _ allocated released = localDeclaration allocated released

-- | The single child requests its allocation or delegates its release. Its
-- amount still equals its own priced allocation minus recorded release.
withDelegatedSubTxDeclaration :: ReleaseTx -> ReleaseTx
withDelegatedSubTxDeclaration proposal =
  Context.addDeclaration
    ( Declarations TopTx.NoUTxODepositDeclaration $
        zipWith
          delegatedDeclaration
          (Children.allocatedDeposits proposal)
          (Children.releasedDeposits proposal)
    )
    proposal

delegatedDeclaration :: Coin -> Coin -> SubTx.SubTxUTxODepositDeclaration
delegatedDeclaration allocated released = case allocated <-> released of
  Coin amount
    | amount > 0 -> SubTx.RequestsUTxODepositFromTopTx $ positiveAmount amount
    | otherwise ->
        SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) SubTx.DelegateToTopTx

-- | An inactive child remains absent; active equal operations declare zero.
localDeclaration :: Coin -> Coin -> SubTx.SubTxUTxODepositDeclaration
localDeclaration allocated released = case allocated <-> released of
  Coin amount
    | amount > 0 -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
    | amount < 0 ->
        SubTx.DeclaresNetUTxODepositRelease
          (positiveAmount $ negate amount)
          (SubTx.SubTxSettlementOutput $ TxIx 0)
    | allocated == Coin 0 && released == Coin 0 -> SubTx.NoUTxODepositDeclaration
    | otherwise -> SubTx.DeclaresZeroNetUTxODeposit

-- | Parent-only change from priced own outputs and recorded own inputs.
-- This is independent of the transaction total and every declared amount.
ownNetDeposit :: ReleaseTx -> Coin
ownNetDeposit proposal =
  Standalone.allocatedDeposits (ledgerState proposal) (unsignedTx proposal)
    <-> Standalone.releasedDeposits (ledgerState proposal) (unsignedTx proposal)

-- | Observe the production required transaction total for the supplied proposal.
-- Tests compare this with independently priced outputs and recorded input deposits;
-- the declaration's local/delegated form must not change the required amount.
requiredNetChange :: ReleaseTx -> Coin
requiredNetChange proposal =
  requiredTxTotalNetUTxODeposit
    (Standalone.protocolParameters $ ledgerState proposal)
    (liveOutputStore $ Standalone.utxoState $ ledgerState proposal)
    (unsignedTx proposal ^. bodyTxL)

-- | Run only production TopTx exactness against the funded snapshot. Other
-- ledger rules do not affect this result, including settlement and conservation.
validateNetChange ::
  ReleaseTx -> Validation (NonEmpty DepositStoreAccountingFailure) ()
validateNetChange proposal =
  validateTopTxExactness
    (Standalone.protocolParameters $ ledgerState proposal)
    (liveOutputStore $ Standalone.utxoState $ ledgerState proposal)
    (unsignedTx proposal ^. bodyTxL)

-- | Independently require the declared amount to equal priced allocations minus
-- consumed recorded deposits. No production accounting predicate is consulted.
expectedNetChange :: Coin -> ReleaseTx -> Validation (NonEmpty DepositStoreAccountingFailure) ()
expectedNetChange declared proposal
  | declared == Context.netDeposit proposal = Success ()
  | otherwise = Failure $ InexactTopTxDepositChange declared (Context.netDeposit proposal) :| []

-- | Replace only the parent declaration, preserving all exact child declarations.
addTopDeclaration :: TopTx.TopTxUTxODepositDeclaration -> ReleaseTx -> ReleaseTx
addTopDeclaration declaration proposal =
  proposal
    { unsignedTx = unsignedTx proposal & bodyTxL . netUTxODepositChangeTxBodyL .~ declaration
    }
