{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | A body spending a store-backed output must declare its own deposit change.
-- Ordinary success consumes the output and releases its recorded Store deposit;
-- newly created store-backed outputs require new allocations. Spending can thus
-- result in a net allocation, a net release or zero, depending on those outputs.
-- TopTx declares the transaction total; each SubTx declares its own contribution.
--
-- ∀ body: storeBackedInputs(body) ≠ ∅ ⇒ hasDeclaration(body).
-- Resolve ordinary inputs in the live UTxO; use their recorded Store deposits.
-- releasedDeposits is the proposed release, applied only on ordinary success.
-- allocatedDeposits is the deposit required by created store-backed outputs.
-- Acceptance assumes exact declarations and all other ledger requirements met.
-- Each source output and its allocation are funded by real ledger transactions.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.Activity.SpendingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (DijkstraSubUtxoPredFailure (..), DijkstraUtxoPredFailure (..))
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTxDeclaration
import Cardano.Ledger.Shelley.LedgerState (
  esLStateL,
  lsUTxOStateL,
  nesEsL,
  utxosDepositStore,
  utxosFees,
  utxosFeesL,
  utxosUtxo,
 )
import Cardano.Ledger.State (DepositStore (..), UTxO (..))
import Cardano.Ledger.Val (Val ((<->)))
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (strictMaybeToMaybe)
import qualified Data.OMap.Strict as OMap
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, it, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Spending
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe, shouldSatisfy, withImpInit)

{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-PRESENCE-ACTIVITY-SPENDING - ∀ body: storeBackedInputs(body) ≠ ∅ ⇒ hasDeclaration(body)" $ do
    -- Apply the presence rule independently to TopTx and every SubTx:
    --
    -- Store-backed inputs | Own declaration | Presence result
    -- Present             | Absent          | Reject: missing declaration.
    -- Present             | Present         | Pass presence; check other rules.
    -- Absent              | Either          | No spending-presence requirement.
    --
    -- spendingPresenceValid(body) ⇔ storeBackedInputs(body) = ∅ ∨ hasDeclaration(body)
    -- Explicit zero counts as present. Presence alone never proves acceptance:
    -- exact amounts, settlement and all other ledger rules must also hold.
    -- With no store-backed inputs, creation or SubTx dependency may still require
    -- a declaration. These obligations also hold on the phase-2 failure path.
    --
    -- N01-N08 exercise present declarations in otherwise valid spending scenarios.
    -- F01-F05 remove a spending body's declaration and require rejection.

    -- Standalone TopTx, any output form.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-N01 - subTxs = ∅ ∧ releasedDeposits > 0 ∧ declaredNetDeposit = allocatedDeposits - releasedDeposits ⇒ accepted" $
      forAll TopTx.withoutSubTxsConsumingDeposits $ \scenario -> do
        (ledgerState, topTx) <- fundSpendingScenario scenario
        let netDeposit = TopTx.allocatedDeposits ledgerState topTx <-> TopTx.releasedDeposits ledgerState topTx
        submitTxAndExpectSuccess ledgerState (TopTx.declareNetDeposit netDeposit topTx)

    -- Standalone TopTx, only implicit outputs.
    -- No new Store allocation is required, so it declares the full release.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-N02 - subTxs = ∅ ∧ releasedDeposits > 0 ∧ storeBackedOutputs = ∅ ∧ declaredNetDeposit = -releasedDeposits ⇒ accepted" $
      forAll TopTx.withoutSubTxsConsumingDepositsCreatingOnlyImplicitOutputs $ \scenario -> do
        (ledgerState, topTx) <- fundSpendingScenario scenario
        let netDeposit = Coin 0 <-> TopTx.releasedDeposits ledgerState topTx
        submitTxAndExpectSuccess ledgerState (TopTx.declareNetDeposit netDeposit topTx)

    withImpInit @(LedgerSpec DijkstraEra) $ do
      -- These single-body controls create only implicit ordinary outputs.
      -- N04/F03 exercise (subTxs, body) = (∅, topTx) and ({subTx}, subTx).
      -- In the SubTx case, TopTx has no store-backed inputs of its own.
      -- phase1Valid includes exact accounting, settlement and collateral checks.
      -- Phase2Invalid is declared explicitly; the supplied V4 script always fails.

      -- One SubTx releases its deposit into its own output.
      -- TopTx declares the matching total.
      it "DS-TX-PRESENCE-ACTIVITY-SPENDING-N03 - subTxs = {subTx} ∧ releasedDeposits(subTx) > 0 ∧ allocatedDeposits(subTx) = 0 ∧ declaredNetDeposit(topTx) = declaredNetDeposit(subTx) = -releasedDeposits(subTx) ⇒ accepted" $ do
        fixture <- buildTxSpendingStoreBackedOutput SubTxSpending
        fixed <- fixupTx $ spendingTx fixture
        checkPreservedSpendingFixture fixture fixed
        outputInput <- ordinaryOutputInput fixture fixed
        storeBefore <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        withNoFixup $ submitTx_ fixed
        storeAfter <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        depositStoreAllocations (utxosDepositStore storeAfter)
          `shouldBe` Map.delete (spendingInput fixture) (depositStoreAllocations $ utxosDepositStore storeBefore)
        depositStoreBalance (utxosDepositStore storeAfter)
          `shouldBe` depositStoreBalance (utxosDepositStore storeBefore) <-> spendingDeposit fixture
        UTxO after <- getUTxO
        Map.member (spendingInput fixture) after `shouldBe` False
        Map.member outputInput after `shouldBe` True
        created <- impGetUTxO outputInput
        created ^. coinTxOutL `shouldBe` Coin 10_000_000 <> spendingDeposit fixture

      -- TopTx omits its required declaration.
      it "DS-TX-PRESENCE-ACTIVITY-SPENDING-F01 - subTxs = ∅ ∧ releasedDeposits(topTx) > 0 ∧ ¬hasDeclaration(topTx) ⇒ rejected ∧ ledgerAfter = ledgerBefore" $ do
        fixture <- buildTxSpendingStoreBackedOutput TopTxSpending
        fixed <- fixupTx $ spendingTx fixture
        checkPreservedSpendingFixture fixture fixed
        removeSpendingDeclaration fixture fixed
          >>= submitTxAndExpectFailureContaining (injectFailure $ MissingUTxODepositDeclaration @DijkstraEra)

      -- TopTx declares, but the spending SubTx does not.
      -- The parent's declaration cannot replace the child's.
      it "DS-TX-PRESENCE-ACTIVITY-SPENDING-F02 - subTxs = {subTx} ∧ releasedDeposits(subTx) > 0 ∧ declaredNetDeposit(topTx) = -releasedDeposits(subTx) ∧ ¬hasDeclaration(subTx) ⇒ rejected ∧ ledgerAfter = ledgerBefore" $ do
        fixture <- buildTxSpendingStoreBackedOutput SubTxSpending
        fixed <- fixupTx $ spendingTx fixture
        checkPreservedSpendingFixture fixture fixed
        removeSpendingDeclaration fixture fixed
          >>= submitTxAndExpectFailureContaining (injectFailure $ SubMissingUTxODepositDeclaration @DijkstraEra)

      -- Phase 2 fails with valid declarations.
      -- Tested for both TopTx and SubTx; only collateral effects apply.
      it "DS-TX-PRESENCE-ACTIVITY-SPENDING-N04 - releasedDeposits(body) > 0 ∧ declaredNetDeposit(topTx) = declaredNetDeposit(body) = -releasedDeposits(body) ∧ phase1Valid ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ accepted ∧ ordinaryEffects = ∅" $
        forM_ [TopTxSpending, SubTxSpending] $ \owner -> do
            fixture <- buildTxSpendingStoreBackedOutput owner
            fixed <- preparePhase2InvalidSpendingTx $ spendingTx fixture
            checkPreservedSpendingFixture fixture fixed
            outputInput <- ordinaryOutputInput fixture fixed
            UTxO before <- getUTxO
            storeBefore <- utxosDepositStore <$> getsNES (nesEsL . esLStateL . lsUTxOStateL)
            feesBefore <- getsNES $ nesEsL . esLStateL . lsUTxOStateL . utxosFeesL
            collateralFee <- expectJust $ strictMaybeToMaybe (fixed ^. bodyTxL . totalCollateralTxBodyL)
            returnedCollateral <- expectJust $ strictMaybeToMaybe (fixed ^. bodyTxL . collateralReturnTxBodyL)
            let collateralInputs = fixed ^. bodyTxL . collateralInputsTxBodyL
                collateralReturnInput = txInAt (length (fixed ^. bodyTxL . outputsTxBodyL)) fixed
            collateralInputs `shouldSatisfy` (not . Set.null)
            withNoFixup $ submitTx_ fixed
            UTxO after <- getUTxO
            storeAfter <- utxosDepositStore <$> getsNES (nesEsL . esLStateL . lsUTxOStateL)
            storeAfter `shouldBe` storeBefore
            Map.lookup (spendingInput fixture) after `shouldBe` Map.lookup (spendingInput fixture) before
            Map.member outputInput after `shouldBe` False
            Map.restrictKeys after collateralInputs `shouldBe` Map.empty
            Map.lookup collateralReturnInput after `shouldBe` Just returnedCollateral
            feesAfter <- getsNES $ nesEsL . esLStateL . lsUTxOStateL . utxosFeesL
            feesAfter `shouldBe` feesBefore <> collateralFee

      -- Phase 2 fails with a missing spending declaration.
      -- The entire transaction is rejected, including the collateral transition.
      it "DS-TX-PRESENCE-ACTIVITY-SPENDING-F03 - releasedDeposits(body) > 0 ∧ ¬hasDeclaration(body) ∧ phase2Script = AlwaysFails ∧ declaredPhase2 = Invalid ⇒ rejected ∧ ledgerAfter = ledgerBefore" $
        forM_
          [ (TopTxSpending, injectFailure $ MissingUTxODepositDeclaration @DijkstraEra)
          , (SubTxSpending, injectFailure $ SubMissingUTxODepositDeclaration @DijkstraEra)
          ] $ \(owner, failure) -> do
            fixture <- buildTxSpendingStoreBackedOutput owner
            fixed <- preparePhase2InvalidSpendingTx $ spendingTx fixture
            checkPreservedSpendingFixture fixture fixed
            removeSpendingDeclaration fixture fixed >>= submitTxAndExpectFailureContaining failure

    -- Multiple-SubTx scope: 2-5 children, only implicit ordinary outputs, and
    -- spendingSubTxs = {subTx ∈ subTxs | storeBackedInputs(subTx) ≠ ∅}.
    -- TopTx has no own Store activity except in N07. Each spending child settles
    -- locally; all Σ terms range over subTxs and include each contribution once.
    -- Acceptance also requires the remaining ledger rules and exact declarations.

    -- Several SubTxs spend store-backed outputs and each declares its local release.
    -- TopTx declares their exact total. Every new ordinary output is implicit.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-N05 - |subTxs| ≥ 2 ∧ (∀ subTx ∈ subTxs: releasedDeposits(subTx) > 0 ∧ declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ⇒ accepted" $
      forAll SubTx.severalConsumingDeposits $ \scenario -> do
        fixture <- fundSubTxSpendingScenario scenario
        fixed <- fixupTx $ subTxSpendingTx fixture
        checkPreservedSubTxSpendingFixture fixture fixed
        before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        withNoFixup $ submitTx_ fixed
        after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        utxosDepositStore after `shouldBe`
          DepositStore
            (depositStoreBalance (utxosDepositStore before) <-> foldMap id (subTxRecordedDeposits fixture))
            (Map.withoutKeys (depositStoreAllocations $ utxosDepositStore before) (allSpentDepositInputs fixture))
        utxosUtxo after `shouldBe`
          UTxO (Map.union (createdOrdinaryOutputs fixed)
            (Map.withoutKeys (unUTxO $ utxosUtxo before) (ordinarySpendingInputs fixed)))

    -- One spending SubTx omits its declaration; TopTx and its siblings still declare.
    -- Try every child position separately, then submit the unchanged valid control.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-F04 - |subTxs| ≥ 2 ∧ (∃! subTx ∈ subTxs: ¬hasDeclaration(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ⇒ rejected ∧ ledgerAfter = ledgerBefore" $
      forAll SubTx.severalConsumingDeposits $ \scenario -> do
        fixture <- fundSubTxSpendingScenario scenario
        fixed <- fixupTx $ subTxSpendingTx fixture
        checkPreservedSubTxSpendingFixture fixture fixed
        forM_ (subTxSpendingInputs fixture) $ \input -> do
          invalid <- removeSubTxSpendingDeclarationByInput input fixed
          invalid ^. bodyTxL . netUTxODepositChangeTxBodyL
            `shouldBe` fixed ^. bodyTxL . netUTxODepositChangeTxBodyL
          forM_ (zip (OMap.elems $ fixed ^. bodyTxL . subTransactionsTxBodyL)
                     (OMap.elems $ invalid ^. bodyTxL . subTransactionsTxBodyL)) $ \(original, changed) ->
            changed ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL `shouldBe`
              if Set.member input (original ^. bodyTxL . inputsTxBodyL)
                then SubTxDeclaration.NoUTxODepositDeclaration
                else original ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL
          length (invalid ^. bodyTxL . subTransactionsTxBodyL) `shouldBe` length (subTxSpendingInputs fixture)
          submitTxAndExpectFailureContaining (injectFailure $ SubMissingUTxODepositDeclaration @DijkstraEra) invalid
        withNoFixup $ submitTx_ fixed

    -- Only some SubTxs spend store-backed outputs. Children without Store activity
    -- omit their declarations; spending children declare and settle their own releases.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-N06 - ∅ ⊂ spendingSubTxs ⊂ subTxs ∧ (∀ subTx ∈ spendingSubTxs: declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ (∀ subTx ∈ subTxs ∖ spendingSubTxs: ¬hasDeclaration(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ⇒ accepted" $
      forAll SubTx.someConsumingDeposits $ \scenario -> do
        fixture <- fundSubTxSpendingScenario scenario
        subTxRecordedDeposits fixture `shouldSatisfy` any (== Coin 0)
        subTxRecordedDeposits fixture `shouldSatisfy` any (> Coin 0)
        fixed <- fixupTx $ subTxSpendingTx fixture
        checkPreservedSubTxSpendingFixture fixture fixed
        forM_ (zip (OMap.elems $ fixed ^. bodyTxL . subTransactionsTxBodyL) (subTxRecordedDeposits fixture)) $ \(subTx, deposit) ->
          SubTxDeclaration.hasUTxODepositDeclaration (subTx ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL)
            `shouldBe` (deposit > Coin 0)
        before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        withNoFixup $ submitTx_ fixed
        after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        utxosDepositStore after `shouldBe`
          DepositStore
            (depositStoreBalance (utxosDepositStore before) <-> foldMap id (subTxRecordedDeposits fixture))
            (Map.withoutKeys (depositStoreAllocations $ utxosDepositStore before) (allSpentDepositInputs fixture))
        utxosUtxo after `shouldBe`
          UTxO (Map.union (createdOrdinaryOutputs fixed)
            (Map.withoutKeys (unUTxO $ utxosUtxo before) (ordinarySpendingInputs fixed)))

    -- TopTx and several SubTxs all spend store-backed outputs.
    -- Each body settles its own release; TopTx declares their combined total once.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-N07 - |subTxs| ≥ 2 ∧ releasedDeposits(topTx) > 0 ∧ (∀ subTx ∈ subTxs: declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ declaredNetDeposit(topTx) = -releasedDeposits(topTx) - Σ releasedDeposits(subTx) ⇒ accepted" $
      forAll SubTx.withTopTxConsumingDeposits $ \scenario -> do
        fixture <- fundSubTxSpendingScenario scenario
        _ <- expectJust $ topTxSpendingInput fixture
        topTxRecordedDeposit fixture `shouldSatisfy` (> Coin 0)
        fixed <- fixupTx $ subTxSpendingTx fixture
        checkPreservedSubTxSpendingFixture fixture fixed
        before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        let releasedDeposits = topTxRecordedDeposit fixture <> foldMap id (subTxRecordedDeposits fixture)
        withNoFixup $ submitTx_ fixed
        after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        utxosDepositStore after `shouldBe`
          DepositStore
            (depositStoreBalance (utxosDepositStore before) <-> releasedDeposits)
            (Map.withoutKeys (depositStoreAllocations $ utxosDepositStore before) (allSpentDepositInputs fixture))
        utxosUtxo after `shouldBe`
          UTxO (Map.union (createdOrdinaryOutputs fixed)
            (Map.withoutKeys (unUTxO $ utxosUtxo before) (ordinarySpendingInputs fixed)))

    -- Phase 2 fails with several correctly declared spending SubTxs.
    -- Ordinary inputs and every recorded deposit remain; only collateral is settled.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-N08 - |subTxs| ≥ 2 ∧ (∀ subTx ∈ subTxs: declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ∧ phase1Valid ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ accepted ∧ ordinaryEffects = ∅" $
      forAll SubTx.severalConsumingDeposits $ \scenario -> do
        fixture <- fundSubTxSpendingScenario scenario
        fixed <- preparePhase2InvalidSpendingTx $ subTxSpendingTx fixture
        checkPreservedSubTxSpendingFixture fixture fixed
        before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        collateralFee <- expectJust $ strictMaybeToMaybe (fixed ^. bodyTxL . totalCollateralTxBodyL)
        returnedCollateral <- expectJust $ strictMaybeToMaybe (fixed ^. bodyTxL . collateralReturnTxBodyL)
        let collateralInputs = fixed ^. bodyTxL . collateralInputsTxBodyL
            collateralReturnInput = txInAt (length (fixed ^. bodyTxL . outputsTxBodyL)) fixed
        collateralInputs `shouldSatisfy` (not . Set.null)
        fixed ^. isPhase2ValidTxL `shouldBe` Phase2Invalid
        withNoFixup $ submitTx_ fixed
        after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        utxosDepositStore after `shouldBe` utxosDepositStore before
        utxosUtxo after `shouldBe`
          UTxO (Map.insert collateralReturnInput returnedCollateral
            (Map.withoutKeys (unUTxO $ utxosUtxo before) collateralInputs))
        utxosFees after `shouldBe` utxosFees before <> collateralFee

    -- A phase-2-invalid proposal still requires every spending SubTx's declaration.
    -- Omit each child in turn: reject without applying even collateral effects.
    prop "DS-TX-PRESENCE-ACTIVITY-SPENDING-F05 - |subTxs| ≥ 2 ∧ (∃! subTx ∈ subTxs: ¬hasDeclaration(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ∧ phase2Script = AlwaysFails ∧ declaredPhase2 = Invalid ⇒ rejected ∧ ledgerAfter = ledgerBefore" $
      forAll SubTx.severalConsumingDeposits $ \scenario -> do
        fixture <- fundSubTxSpendingScenario scenario
        fixed <- preparePhase2InvalidSpendingTx $ subTxSpendingTx fixture
        checkPreservedSubTxSpendingFixture fixture fixed
        fixed ^. isPhase2ValidTxL `shouldBe` Phase2Invalid
        forM_ (subTxSpendingInputs fixture) $ \input -> do
          invalid <- removeSubTxSpendingDeclarationByInput input fixed
          invalid ^. bodyTxL . netUTxODepositChangeTxBodyL
            `shouldBe` fixed ^. bodyTxL . netUTxODepositChangeTxBodyL
          forM_ (zip (OMap.elems $ fixed ^. bodyTxL . subTransactionsTxBodyL)
                     (OMap.elems $ invalid ^. bodyTxL . subTransactionsTxBodyL)) $ \(original, changed) ->
            changed ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL `shouldBe`
              if Set.member input (original ^. bodyTxL . inputsTxBodyL)
                then SubTxDeclaration.NoUTxODepositDeclaration
                else original ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL
          length (invalid ^. bodyTxL . subTransactionsTxBodyL) `shouldBe` length (subTxSpendingInputs fixture)
          submitTxAndExpectFailureContaining (injectFailure $ SubMissingUTxODepositDeclaration @DijkstraEra) invalid
        withNoFixup $ submitTx_ fixed
{- FOURMOLU_ENABLE -}
