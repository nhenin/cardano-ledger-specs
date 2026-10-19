{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | A body proposing Store releases must declare its own deposit change.
-- Ordinary success consumes the output and releases its recorded Store deposit;
-- newly created store-backed outputs require new allocations. Gross releases can thus
-- result in a net allocation, a net release or zero, depending on those outputs.
-- TopTx declares the transaction total; each SubTx declares its own contribution.
--
-- ∀ body: storeBackedInputs(body) ≠ ∅ ⇒ hasDeclaration(body).
-- Resolve ordinary inputs in the live UTxO; use their recorded Store deposits.
-- releasedDeposits is the proposed release, applied only on ordinary success.
-- allocatedDeposits is the deposit required by created store-backed outputs.
-- Acceptance assumes exact declarations and all other ledger requirements met.
-- Implemented ledger scenarios fund each source output and its allocation
-- through real ledger transactions. Reference and collateral inputs do not
-- release ordinary deposits; a child declaration cannot supply the parent field.
-- These scenarios check transaction acceptance or the required rejection reason.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.Operations.ReleaseSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (
  DijkstraSubUtxoPredFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release as Release
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release

{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE - ∀ body: storeBackedInputs(body) ≠ ∅ ⇒ hasDeclaration(body)" $ do
    -- Apply the presence rule independently to TopTx and every SubTx:
    --
    -- Store-backed inputs | Own declaration | Presence result
    -- Present             | Absent          | Reject: missing declaration.
    -- Present             | Present         | Pass presence; check other rules.
    -- Absent              | Either          | No release-presence requirement.
    --
    -- releasePresenceValid(body) ⇔ storeBackedInputs(body) = ∅ ∨ hasDeclaration(body)
    -- Explicit zero counts as present. Presence alone never proves acceptance:
    -- exact amounts, settlement and all other ledger rules must also hold.
    -- With no store-backed inputs, allocation or an explicit SubTx declaration may still require
    -- a declaration. These obligations also hold on the phase-2 failure path.
    --
    -- N01-N08 exercise present declarations in otherwise valid release scenarios.
    -- F01-F05 omit a releasing body's declaration and require rejection.
    -- N09-N10 exclude reference and collateral access; F06 keeps the parent field mandatory.

    -- Standalone TopTx, any output form.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N01 - subTxs = ∅ ∧ releasedDeposits > 0 ∧ declaredNetDeposit = allocatedDeposits - releasedDeposits ⇒ accepted" $
      forAllStandaloneReleaseTx TopTx.standaloneTopTxAnyOutputForm $ \topTxWithoutTopDeclaration ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (case TopTx.netDeposit topTxWithoutTopDeclaration of
                Coin netDeposit
                  | netDeposit > 0 ->
                      TopTx.DeclaresNetUTxODepositAllocation
                        (positiveAmount netDeposit)
                  | netDeposit < 0 ->
                      TopTx.DeclaresNetUTxODepositRelease
                        (positiveAmount $ negate netDeposit)
                        (TopTx.TopTxSettlementOutput $ TxIx 0)
                  | otherwise ->
                      TopTx.DeclaresZeroNetUTxODeposit
              )
              [])
            topTxWithoutTopDeclaration)
          >>= submitTx >>= isAccepted

    -- Standalone TopTx, only implicit outputs.
    -- No new allocation is required; output zero receives application ADA plus the release.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N02 - subTxs = ∅ ∧ releasedDeposits > 0 ∧ storeBackedOutputs = ∅ ∧ declaredNetDeposit = -releasedDeposits ⇒ accepted" $
      forAllStandaloneReleaseTx TopTx.standaloneTopTxOnlyImplicitOutputs $ \topTxWithoutTopDeclaration ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutTopDeclaration)
                (TopTx.TopTxSettlementOutput $ TxIx 0))
              [])
            topTxWithoutTopDeclaration)
          >>= submitTx >>= isAccepted

    -- One SubTx releases its deposit into its own output.
    -- TopTx declares the matching total.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N03 - subTxs = {subTx} ∧ releasedDeposits(subTx) > 0 ∧ allocatedDeposits(subTx) = 0 ∧ declaredNetDeposit(topTx) = declaredNetDeposit(subTx) = -releasedDeposits(subTx) ⇒ accepted" $
      forAllSingleSubTxReleaseTx SubTx.oneSubTxReleasingDepositIntoOwnOutput $ \recordedDeposit topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease recordedDeposit TopTx.NoTopTxSettlement)
              [SubTx.DeclaresNetUTxODepositRelease recordedDeposit (SubTx.SubTxSettlementOutput $ TxIx 0)])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- Standalone TopTx spends store-backed outputs without its own declaration.
    -- With no SubTx, dependency passes; the proposed release requires the declaration.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F01 - subTxs = ∅ ∧ releasedDeposits(topTx) > 0 ∧ ¬hasDeclaration(topTx) ⇒ rejected" $
      forAllStandaloneReleaseTx TopTx.standaloneTopTxOnlyImplicitOutputs $ \topTxWithoutTopDeclaration ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutTopDeclaration)
                (TopTx.TopTxSettlementOutput $ TxIx 0))
              [])
            topTxWithoutTopDeclaration)
          >>= removeTopTxReleaseDeclaration
          >>= submitTx
          >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)

    -- SubTx spends a store-backed output without its own declaration, despite TopTx declaring.
    -- Use N03's generated inputs and settlement, but leave the SubTx declaration absent.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F02 - subTxs = {subTx} ∧ releasedDeposits(subTx) > 0 ∧ declaredNetDeposit(topTx) = -releasedDeposits(subTx) ∧ ¬hasDeclaration(subTx) ⇒ rejected" $
      forAllSingleSubTxReleaseTx SubTx.oneSubTxReleasingDepositIntoOwnOutput $ \recordedDeposit topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease recordedDeposit TopTx.NoTopTxSettlement)
              [SubTx.NoUTxODepositDeclaration])
            topTxWithoutDeclarations)
          >>= submitTx
          >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)

    -- Phase 2 fails with valid declarations.
    -- Every generated source is tested with both owners and must be accepted.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N04 - releasedDeposits(body) > 0 ∧ declaredNetDeposit(topTx) = declaredNetDeposit(body) = -releasedDeposits(body) ∧ phase1Valid ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ accepted" $
      forAll Release.oneBodyReleasingDepositIntoOwnOutput $ \scenario ->
        forM_ [TopTxReleasing, SubTxReleasing] $ \owner -> do
          SignedReleaseTx{signedTx} <-
            preparePhase2InvalidSingleBodyRelease owner scenario $ \recordedDeposit ->
              case owner of
                TopTxReleasing -> Declarations
                  (TopTx.DeclaresNetUTxODepositRelease recordedDeposit (TopTx.TopTxSettlementOutput $ TxIx 0)) []
                SubTxReleasing -> Declarations
                  (TopTx.DeclaresNetUTxODepositRelease recordedDeposit TopTx.NoTopTxSettlement)
                  [SubTx.DeclaresNetUTxODepositRelease recordedDeposit (SubTx.SubTxSettlementOutput $ TxIx 0)]
          submitTx signedTx >>= isAccepted

    -- Phase 2 fails with a missing release declaration.
    -- Both owners must be rejected for the missing release declaration.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F03 - releasedDeposits(body) > 0 ∧ ¬hasDeclaration(body) ∧ phase2Script = AlwaysFails ∧ declaredPhase2 = Invalid ⇒ rejected" $
      forAll Release.oneBodyReleasingDepositIntoOwnOutput $ \scenario ->
        forM_
          [ (TopTxReleasing, isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra))
          , (SubTxReleasing, isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra))
          ] $ \(owner, isRejected) -> do
            SignedReleaseTx{signedTx, sourceInput} <-
              preparePhase2InvalidSingleBodyRelease owner scenario $ \recordedDeposit ->
                case owner of
                  TopTxReleasing -> Declarations
                    (TopTx.DeclaresNetUTxODepositRelease recordedDeposit (TopTx.TopTxSettlementOutput $ TxIx 0)) []
                  SubTxReleasing -> Declarations
                    (TopTx.DeclaresNetUTxODepositRelease recordedDeposit TopTx.NoTopTxSettlement)
                    [SubTx.DeclaresNetUTxODepositRelease recordedDeposit (SubTx.SubTxSettlementOutput $ TxIx 0)]
            txWithoutDeclaration <- case owner of
              TopTxReleasing -> removeTopTxReleaseDeclaration signedTx
              SubTxReleasing -> removeSubTxReleaseDeclarationByInput sourceInput signedTx
            submitTx txWithoutDeclaration >>= isRejected

    -- Multiple-SubTx scope: 2-5 children, only implicit ordinary outputs, and
    -- releasingSubTxs = {subTx ∈ subTxs | storeBackedInputs(subTx) ≠ ∅}.
    -- TopTx has no own Store operations except in N07. Each child releasing a deposit settles
    -- locally; all Σ terms range over subTxs and include each contribution once.

    -- Several SubTxs release their deposits.
    -- Every child declares its own release; TopTx declares their sum.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N05 - |subTxs| ≥ 2 ∧ (∀ subTx ∈ subTxs: releasedDeposits(subTx) > 0 ∧ declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ⇒ accepted" $
      forAllSubTxReleaseTx SubTx.severalSubTxsReleasingDeposits $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                TopTx.NoTopTxSettlement)
              [ SubTx.DeclaresNetUTxODepositRelease
                  (positiveAmount $ unCoin recordedDeposit)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- One SubTx releasing deposits omits its declaration; TopTx and its siblings still declare.
    -- Try every child position separately, then submit the unchanged valid control.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F04 - |subTxs| ≥ 2 ∧ (∃! subTx ∈ subTxs: ¬hasDeclaration(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ⇒ rejected" $
      forAllSubTxReleaseTx SubTx.severalSubTxsReleasingDeposits $ \topTxWithoutDeclarations -> do
        signedTx <- buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                TopTx.NoTopTxSettlement)
              [ SubTx.DeclaresNetUTxODepositRelease
                  (positiveAmount $ unCoin recordedDeposit)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
        forM_ (SubTx.spendingInputs topTxWithoutDeclarations) $ \input ->
          removeSubTxReleaseDeclarationByInput input signedTx
            >>= submitTx
            >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)

        -- The original proposal with every declaration is accepted.
        submitTx signedTx >>= isAccepted

    -- Only some SubTxs release Store deposits.
    -- Children without Store releases omit their declaration; the others declare their release.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N06 - ∅ ⊂ releasingSubTxs ⊂ subTxs ∧ (∀ subTx ∈ releasingSubTxs: declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ (∀ subTx ∈ subTxs ∖ releasingSubTxs: ¬hasDeclaration(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ⇒ accepted" $
      forAllSubTxReleaseTx SubTx.onlySomeSubTxsReleasingDeposits $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                TopTx.NoTopTxSettlement)
              [ case recordedDeposit of
                  Coin 0 -> SubTx.NoUTxODepositDeclaration
                  Coin amount ->
                    SubTx.DeclaresNetUTxODepositRelease
                      (positiveAmount amount)
                      (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- TopTx and several SubTxs release deposits.
    -- Each body settles its own release; TopTx declares their combined total once.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N07 - |subTxs| ≥ 2 ∧ releasedDeposits(topTx) > 0 ∧ (∀ subTx ∈ subTxs: declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ declaredNetDeposit(topTx) = -releasedDeposits(topTx) - Σ releasedDeposits(subTx) ⇒ accepted" $
      forAllSubTxReleaseTx SubTx.topTxAndSeveralSubTxsReleasingDeposits $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                (TopTx.TopTxSettlementOutput $ TxIx 0))
              [ SubTx.DeclaresNetUTxODepositRelease
                  (positiveAmount $ unCoin recordedDeposit)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- Phase 2 fails with several correctly declared SubTx releases.
    -- Every SubTx proposing a release declares it; TopTx declares the total.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N08 - |subTxs| ≥ 2 ∧ (∀ subTx ∈ subTxs: declaredNetDeposit(subTx) = -releasedDeposits(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ∧ phase1Valid ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ accepted" $
      forAllSubTxReleaseTx SubTx.severalSubTxsReleasingDeposits $ \topTxWithoutDeclarations ->
        buildAndSignPhase2InvalidTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                TopTx.NoTopTxSettlement)
              [ SubTx.DeclaresNetUTxODepositRelease
                  (positiveAmount $ unCoin recordedDeposit)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- A phase-2-invalid proposal still requires every releasing SubTx's declaration.
    -- Omit each child in turn and require rejection.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F05 - |subTxs| ≥ 2 ∧ (∃! subTx ∈ subTxs: ¬hasDeclaration(subTx)) ∧ declaredNetDeposit(topTx) = -Σ releasedDeposits(subTx) ∧ phase2Script = AlwaysFails ∧ declaredPhase2 = Invalid ⇒ rejected" $
      forAllSubTxReleaseTx SubTx.severalSubTxsReleasingDeposits $ \topTxWithoutDeclarations -> do
        signedTx <- buildAndSignPhase2InvalidTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                TopTx.NoTopTxSettlement)
              [ SubTx.DeclaresNetUTxODepositRelease
                  (positiveAmount $ unCoin recordedDeposit)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
        forM_ (SubTx.spendingInputs topTxWithoutDeclarations) $ \input ->
          removeSubTxReleaseDeclarationByInput input signedTx
            >>= submitTx
            >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)

        -- The original phase-2-invalid proposal with every declaration is accepted.
        submitTx signedTx >>= isAccepted

    -- Store-backed reference inputs retain their allocations. Ordinary inputs and
    -- outputs are implicit, so the absent declaration is accepted.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N09 - Standalone TopTx, reference-only Store access" $
      forAllReferenceOnlyStoreTx TopTx.standaloneTopTxWithStoreBackedReferenceInputs $ \topTxWithoutDeclaration ->
        buildAndSignTx
          (TopTx.addDeclaration (Declarations TopTx.NoUTxODepositDeclaration []) topTxWithoutDeclaration)
          >>= submitTx >>= isAccepted

    -- Store-backed collateral input only, return only, or both. Every generated
    -- amount pair exercises all three placements with actual script success and
    -- failure. Ordinary Store operations remain absent on both execution paths.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N10 - Standalone TopTx, collateral-only Store operations" $
      forAll Release.collateralOnlyStoreOperations $ \scenarios ->
        forM_ scenarios $ \scenario ->
          buildAndSignCollateralOnlyTx scenario (Declarations TopTx.NoUTxODepositDeclaration [])
            >>= submitTx >>= isAccepted

    -- TopTx and its children each release recorded deposits into implicit outputs.
    -- Removing only the parent's declaration must produce its own release-presence
    -- failure, even though SubTx declarations also trigger the parent dependency.
    prop "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F06 - A SubTx declaration cannot satisfy TopTx release presence" $
      forAllSubTxReleaseTx SubTx.topTxAndSeveralSubTxsReleasingDeposits $ \topTxWithoutDeclarations -> do
        signedTx <- buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ unCoin $ TopTx.releasedDeposits topTxWithoutDeclarations)
                (TopTx.TopTxSettlementOutput $ TxIx 0))
              [ SubTx.DeclaresNetUTxODepositRelease
                  (positiveAmount $ unCoin recordedDeposit)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
              | recordedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
        removeTopTxReleaseDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
