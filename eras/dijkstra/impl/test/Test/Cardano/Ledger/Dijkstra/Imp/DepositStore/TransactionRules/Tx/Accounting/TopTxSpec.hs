{-# LANGUAGE NumericUnderscores #-}

-- | TopTx declares the total change caused by itself and every SubTx.
-- ownNetDeposit(body) = allocatedDeposits(body) - releasedDeposits(body).
-- transactionNetDeposit(topTx) = ownNetDeposit(topTx) + sum(ownNetDeposit(subTx)).
-- Derive allocations from priced outputs and releases from recorded inputs.
-- Declared amounts are signed: allocation is positive, release negative, explicit zero 0.
-- Every tested TopTx supplies a declaration; missing declarations are a separate rule.
--
-- Present SubTx declarations are exact; grammar, presence and input resolution hold.
-- Accepted controls satisfy all other requirements. Rejection cases start from a
-- valid control and require InexactTopTxDepositChange; changing the declared total
-- may also break financial conservation, so additional failures are allowed.
-- Unless specified otherwise, phase 2 succeeds and the transaction declares that outcome.
-- A correct total cannot repair an incorrect child declaration; SubTxSpec checks it.
-- The derived TopTx own change is a diagnostic, not another declaration field.
-- Validation applies on both phase-2 outcomes; ledger execution determines which
-- effects apply. Every ledger case starts from real funded Store records and
-- independently priced proposed outputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.TopTxSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core (injectFailure)
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import Cardano.Ledger.Val (Val ((<->)))
import Data.Maybe (catMaybes)
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Fixture
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx as Scenario
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as Context
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  buildAndSignPhase2InvalidTx,
  buildAndSignTx,
  fundAccountingScenario,
  mutateTopTxDeclaration,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  fundReleaseScenario,
  submitTxAndExpectFailureContaining,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (fixupTx, rederiveAddrTxWits)
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-ACCOUNTING-TOPTX - TopTx declares the exact transaction total" $ do
    -- bodies = {topTx} ∪ subTxs; every Σ over body includes TopTx and all SubTxs.
    -- Child sums include local and delegated operations exactly once.
    -- declaredSubTxs = {subTx ∈ subTxs | hasDeclaration(subTx)}.
    -- RequiredDeclarations ensures an absent child declaration has no own Store operations;
    -- its own net change is zero, without treating absence as an explicit zero declaration.
    -- P01 isolates TopTx exactness; N02 derives an identity from the exact total.
    -- Other cases assert ledger acceptance or the specific TopTx exactness failure.

    -- TopTx declares the exact transaction total.
    -- Compare the isolated TopTx validator with independently computed deposits; this equivalence
    -- does not assert complete ledger acceptance.
    prop "DS-TX-ACCOUNTING-TOPTX-P01 - topTxAccountingValid(topTx) ⇔ declaredNetDeposit(topTx) = transactionNetDeposit(topTx)" $
      forAll Fixture.arbitraryScenario $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        let required = Context.netDeposit proposal
        forM_ [required, required <-> Coin 1, required <> Coin 1, Coin 0, Coin 0 <-> required] $ \declared@(Coin amount) ->
          Scenario.validateAccounting (Scenario.addTopDeclaration
            (case compare amount 0 of
              GT -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              LT -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)
              EQ -> TopTx.DeclaresZeroNetUTxODeposit) proposal)
            `shouldBe` Scenario.expectedAccounting declared proposal

    -- TopTx and SubTxs contribute to the total.
    -- Cover both zero and nonzero TopTx own changes alongside nonzero child changes.
    -- The declared total includes every own change exactly once.
    prop "DS-TX-ACCOUNTING-TOPTX-N01 - (∃ subTx ∈ subTxs: ownNetDeposit(subTx) ≠ 0) ∧ declaredNetDeposit(topTx) = transactionNetDeposit(topTx) ⇒ accepted" $
      forAll Scenario.withTopTxAndSubTxChanges $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        buildAndSignTx (Scenario.addTopDeclaration
          (case Context.netDeposit proposal of
            Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            _ -> TopTx.DeclaresZeroNetUTxODeposit) proposal)
          >>= submitTx >>= isAccepted

    -- TopTx's own change is derived from its total.
    -- Subtract all present child declarations, including delegated operations.
    -- Children without declarations have no own Store operations.
    -- The result is a diagnostic, not another declaration field.
    prop "DS-TX-ACCOUNTING-TOPTX-N02 - declaredNetDeposit(topTx) = transactionNetDeposit(topTx) ⇒ declaredNetDeposit(topTx) - Σ_{subTx ∈ declaredSubTxs} declaredNetDeposit(subTx) = ownNetDeposit(topTx)" $
      forAll Scenario.withEveryChildDeclarationForm $ \scenario -> do
        proposal <- Scenario.withEveryExactChildDeclarationForm <$> fundAccountingScenario scenario
        signedTx <- buildAndSignTx (Scenario.addTopDeclaration
          (case Context.netDeposit proposal of
            Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount) proposal)
        declaredTotal <- expectJust $ TopTx.declaredNetDeposit signedTx
        declaredTotal <-> foldMap id (catMaybes $ SubTx.declaredNetDeposits signedTx)
          `shouldBe` Scenario.ownNetDeposit proposal
        submitTx signedTx >>= isAccepted

    -- 5 ADA allocated, 3 ADA released.
    -- Both sums cover TopTx and all SubTxs; the transaction requires a net allocation of 2 ADA.
    prop "DS-TX-ACCOUNTING-TOPTX-N03 - Σ allocatedDeposits(body) = 5 ADA ∧ Σ releasedDeposits(body) = 3 ADA ∧ declaredNetDeposit(topTx) = 2 ADA ⇒ accepted" $
      forAll Scenario.allocatingFiveAdaReleasingThreeAda $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        (Context.allocatedDeposits proposal, Context.releasedDeposits proposal)
          `shouldBe` (Coin 5_000_000, Coin 3_000_000)
        buildAndSignTx (Scenario.addTopDeclaration
          (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount 2_000_000) proposal)
          >>= submitTx >>= isAccepted

    -- 3 ADA allocated, 5 ADA released.
    -- Both sums cover TopTx and all SubTxs; the transaction releases 2 ADA net.
    prop "DS-TX-ACCOUNTING-TOPTX-N04 - Σ allocatedDeposits(body) = 3 ADA ∧ Σ releasedDeposits(body) = 5 ADA ∧ declaredNetDeposit(topTx) = -2 ADA ⇒ accepted" $
      forAll Scenario.allocatingThreeAdaReleasingFiveAda $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        (Context.allocatedDeposits proposal, Context.releasedDeposits proposal)
          `shouldBe` (Coin 3_000_000, Coin 5_000_000)
        buildAndSignTx (Scenario.addTopDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) (TopTx.TopTxSettlementOutput $ TxIx 0)) proposal)
          >>= submitTx >>= isAccepted

    -- Nonzero body changes produce a zero total.
    -- Allocating and releasing bodies offset each other. TopTx still supplies an explicit zero
    -- declaration.
    prop "DS-TX-ACCOUNTING-TOPTX-N05 - (∃ body ∈ bodies: ownNetDeposit(body) ≠ 0) ∧ transactionNetDeposit(topTx) = 0 ∧ declaredNetDeposit(topTx) = 0 ⇒ accepted" $
      forAll Scenario.withOffsettingBodyChanges $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        Context.netDeposit proposal `shouldBe` Coin 0
        buildAndSignTx (Scenario.addTopDeclaration TopTx.DeclaresZeroNetUTxODeposit proposal)
          >>= submitTx >>= isAccepted

    -- Standalone TopTx understates its net allocation by one lovelace.
    -- Create one more store-backed output than is consumed. Start from a valid control and alter
    -- only the signed declaration.
    prop "DS-TX-ACCOUNTING-TOPTX-F01 - subTxs = ∅ ∧ transactionNetDeposit(topTx) > 1 lovelace ∧ declaredNetDeposit(topTx) = transactionNetDeposit(topTx) - 1 lovelace ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll TopTx.standaloneTopTxRequiringNetAllocation $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <-> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
        submitTx prepared >>= isAccepted

    -- Standalone TopTx overstates its net allocation by one lovelace.
    -- Use the same net-allocation generator and increase only the declaration by one lovelace.
    prop "DS-TX-ACCOUNTING-TOPTX-F02 - subTxs = ∅ ∧ transactionNetDeposit(topTx) > 0 ∧ declaredNetDeposit(topTx) = transactionNetDeposit(topTx) + 1 lovelace ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll TopTx.standaloneTopTxRequiringNetAllocation $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
        submitTx prepared >>= isAccepted

    -- Standalone TopTx understates its net release by one lovelace.
    -- Only implicit outputs are created. Adding one to the negative declaration reduces the release
    -- magnitude.
    prop "DS-TX-ACCOUNTING-TOPTX-F03 - subTxs = ∅ ∧ allocatedDeposits(topTx) = 0 ∧ releasedDeposits(topTx) > 1 lovelace ∧ declaredNetDeposit(topTx) = transactionNetDeposit(topTx) + 1 lovelace ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll TopTx.standaloneTopTxOnlyImplicitOutputs $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
        submitTx prepared >>= isAccepted

    -- Standalone TopTx overstates its net release by one lovelace.
    -- Only implicit outputs are created. Subtracting one from the negative declaration increases the
    -- release magnitude.
    prop "DS-TX-ACCOUNTING-TOPTX-F04 - subTxs = ∅ ∧ allocatedDeposits(topTx) = 0 ∧ releasedDeposits(topTx) > 0 ∧ declaredNetDeposit(topTx) = transactionNetDeposit(topTx) - 1 lovelace ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll TopTx.standaloneTopTxOnlyImplicitOutputs $ \scenario -> do
        (ledgerState, topTx) <- fundReleaseScenario scenario
        let required = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
            declared = required <-> Coin 1
        prepared <- fixupTx $ TopTx.declareNetDeposit required topTx
        invalid <- rederiveAddrTxWits $ TopTx.declareNetDeposit declared prepared
        submitTxAndExpectFailureContaining (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
        submitTx prepared >>= isAccepted

    -- Explicit zero cannot replace a nonzero total.
    -- Cover both a required net allocation and a required net release.
    prop "DS-TX-ACCOUNTING-TOPTX-F05 - transactionNetDeposit(topTx) ≠ 0 ∧ declaredNetDeposit(topTx) = 0 ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll Scenario.withNonzeroTotal $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        let required = Context.netDeposit proposal
        signedTx <- buildAndSignTx (Scenario.addTopDeclaration
          (case required of
            Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            Coin amount -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)) proposal)
        invalid <- mutateTopTxDeclaration TopTx.DeclaresZeroNetUTxODeposit signedTx
        submitTxAndExpectFailureContaining
          (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange (Coin 0) required) invalid
        submitTx signedTx >>= isAccepted

    -- A nonzero declaration cannot replace a zero total.
    -- Cover both an allocation declaration and a release declaration when the transaction total is
    -- zero.
    prop "DS-TX-ACCOUNTING-TOPTX-F06 - transactionNetDeposit(topTx) = 0 ∧ declaredNetDeposit(topTx) ≠ 0 ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll Scenario.withOffsettingBodyChanges $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        signedTx <- buildAndSignTx (Scenario.addTopDeclaration TopTx.DeclaresZeroNetUTxODeposit proposal)
        forM_
          [ (Coin 1, TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount 1)
          , (Coin (-1), TopTx.DeclaresNetUTxODepositRelease (positiveAmount 1) TopTx.NoTopTxSettlement)
          ] $ \(declared, declaration) -> do
            invalid <- mutateTopTxDeclaration declaration signedTx
            submitTxAndExpectFailureContaining
              (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared (Coin 0)) invalid
        submitTx signedTx >>= isAccepted

    -- TopTx declares the opposite direction.
    -- A required allocation cannot be declared as a release, or a required release as an allocation.
    prop "DS-TX-ACCOUNTING-TOPTX-F07 - declaredNetDeposit(topTx) × transactionNetDeposit(topTx) < 0 ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll Scenario.withNonzeroTotal $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        let required@(Coin amount) = Context.netDeposit proposal
        signedTx <- buildAndSignTx (Scenario.addTopDeclaration
          (if amount > 0
            then TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            else TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)) proposal)
        invalid <- mutateTopTxDeclaration
          (if amount > 0
            then TopTx.DeclaresNetUTxODepositRelease (positiveAmount amount) TopTx.NoTopTxSettlement
            else TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount $ negate amount) signedTx
        submitTxAndExpectFailureContaining
          (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange (Coin $ negate amount) required) invalid
        submitTx signedTx >>= isAccepted

    -- TopTx releases while SubTxs allocate.
    -- The child allocations exactly offset the parent release. TopTx declares the transaction total,
    -- not its own negative change.
    prop "DS-TX-ACCOUNTING-TOPTX-N06 - ownNetDeposit(topTx) < 0 ∧ (∀ subTx ∈ subTxs: ownNetDeposit(subTx) ≥ 0) ∧ Σ ownNetDeposit(subTx) = -ownNetDeposit(topTx) ∧ declaredNetDeposit(topTx) = 0 ⇒ accepted" $
      forAll Scenario.withTopTxReleaseOffsetBySubTxAllocations $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        Context.netDeposit proposal `shouldBe` Coin 0
        buildAndSignTx (Scenario.addTopDeclaration TopTx.DeclaresZeroNetUTxODeposit proposal)
          >>= submitTx >>= isAccepted

    -- TopTx allocates while SubTxs release.
    -- The child releases exactly offset the parent allocation. TopTx declares the transaction total,
    -- not its own positive change.
    prop "DS-TX-ACCOUNTING-TOPTX-N07 - ownNetDeposit(topTx) > 0 ∧ (∀ subTx ∈ subTxs: ownNetDeposit(subTx) ≤ 0) ∧ Σ ownNetDeposit(subTx) = -ownNetDeposit(topTx) ∧ declaredNetDeposit(topTx) = 0 ⇒ accepted" $
      forAll Scenario.withTopTxAllocationOffsetBySubTxReleases $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        Context.netDeposit proposal `shouldBe` Coin 0
        buildAndSignTx (Scenario.addTopDeclaration TopTx.DeclaresZeroNetUTxODeposit proposal)
          >>= submitTx >>= isAccepted

    -- An exact total remains valid when phase 2 fails.
    -- The failing script matches the declared outcome. Exactness still uses proposed ordinary
    -- deposits; collateral execution is a separate rule.
    prop "DS-TX-ACCOUNTING-TOPTX-N08 - declaredNetDeposit(topTx) = transactionNetDeposit(topTx) ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ accepted" $
      forAll Scenario.withNonzeroTotal $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        buildAndSignPhase2InvalidTx (Scenario.addTopDeclaration
          (case Context.netDeposit proposal of
            Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            Coin amount -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)) proposal)
          >>= submitTx >>= isAccepted

    -- An inexact total is rejected even when phase 2 fails.
    -- A failing script does not waive deposit exactness. The script matches the declared outcome;
    -- rejection must include the TopTx exactness failure.
    prop "DS-TX-ACCOUNTING-TOPTX-F08 - declaredNetDeposit(topTx) ≠ transactionNetDeposit(topTx) ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll Scenario.withNonzeroTotal $ \scenario -> do
        proposal <- Scenario.withExactLocalSubTxDeclarations <$> fundAccountingScenario scenario
        let required = Context.netDeposit proposal
        signedTx <- buildAndSignPhase2InvalidTx (Scenario.addTopDeclaration
          (case required of
            Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            Coin amount -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)) proposal)
        invalid <- mutateTopTxDeclaration TopTx.DeclaresZeroNetUTxODeposit signedTx
        submitTxAndExpectFailureContaining
          (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange (Coin 0) required) invalid
        submitTx signedTx >>= isAccepted

    -- A delegated change belongs in the total exactly once.
    -- delegated(subTx) means an allocation request or a release targeting DelegateToTopTx.
    -- Omitting or adding a second copy of a delegated child change makes the total inexact;
    -- delegation changes responsibility, not the counted amount.
    prop "DS-TX-ACCOUNTING-TOPTX-F09 - subTx ∈ subTxs ∧ delegated(subTx) ∧ ownNetDeposit(subTx) ≠ 0 ∧ declaredNetDeposit(topTx) ∈ {transactionNetDeposit(topTx) - ownNetDeposit(subTx), transactionNetDeposit(topTx) + ownNetDeposit(subTx)} ⇒ rejectedWith(InexactTopTxDepositChange)" $
      forAll Scenario.withDelegatedChange $ \scenario -> do
        proposal <- Scenario.withDelegatedSubTxDeclaration <$> fundAccountingScenario scenario
        let required = Context.netDeposit proposal
            delegatedChange = foldMap id $ catMaybes $ SubTx.declaredNetDeposits $ Context.unsignedTx proposal
        signedTx <- buildAndSignTx (Scenario.addTopDeclaration
          (case required of
            Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)
            _ -> TopTx.DeclaresZeroNetUTxODeposit) proposal)
        forM_ [required <-> delegatedChange, required <> delegatedChange] $ \declared@(Coin amount) -> do
          invalid <- mutateTopTxDeclaration
            (case compare amount 0 of
              GT -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              LT -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)
              EQ -> TopTx.DeclaresZeroNetUTxODeposit) signedTx
          submitTxAndExpectFailureContaining
            (injectFailure $ DepositStoreFailure $ InexactTopTxDepositChange declared required) invalid
        submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
