{-# LANGUAGE TypeApplications #-}

-- | Equal allocations and releases still require a declaration: zero net change
-- does not mean no Store operations. Each active body independently allocates and
-- releases the same positive amount; equality of the transaction total alone is
-- insufficient. Cover a standalone parent, one or several children, inactive
-- siblings, parent and children together, and the phase-2 failure path.
-- Sources are funded through the ledger before declarations are supplied here.
-- Every omitted declaration is removed from a signed valid control and re-signed.
-- Rejection checks the responsible body's failure; the original control is accepted.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.RequiredDeclarations.Operations.ZeroNetChangeSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (DijkstraSubUtxoPredFailure (..), DijkstraUtxoPredFailure (..))
import Test.Cardano.Ledger.Common (Spec, describe, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  buildAndSignPhase2InvalidTx,
  buildAndSignTx,
  forAllStandaloneZeroNetChangeTx,
  forAllSubTxZeroNetChangeTx,
  isAccepted,
  isRejectedWith,
  removeSubTxReleaseDeclarationByInput,
  removeTopTxReleaseDeclaration,
  submitTx,
 )

{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE - Equal allocations and releases still require a declaration" $ do
    -- N01/F01 context: subTxs = ∅ ∧ allocatedDeposits = releasedDeposits > 0.
    -- Recorded input deposits and independently priced outputs establish equality;
    -- the declaration never supplies the expected amount.

    -- Standalone TopTx, equal allocations and releases with explicit zero.
    -- Both operations are present; their exact net amount is zero.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-N01 - subTxs = ∅ ∧ allocatedDeposits = releasedDeposits > 0 ∧ declaration(topTx) = ExplicitZero ⇒ accepted" $
      forAllStandaloneZeroNetChangeTx TopTx.standaloneTopTxWithEqualAllocationsAndReleases $ \topTxWithoutTopDeclaration ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations TopTx.DeclaresZeroNetUTxODeposit [])
            topTxWithoutTopDeclaration)
          >>= submitTx >>= isAccepted

    -- Standalone TopTx, equal allocations and releases without a declaration.
    -- Remove only the declaration and re-sign; zero net change cannot exempt it.
    -- The original explicitly declared transaction remains an accepted control.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F01 - subTxs = ∅ ∧ allocatedDeposits = releasedDeposits > 0 ∧ ¬hasDeclaration(topTx) ⇒ rejected ∧ MissingUTxODepositDeclaration ∈ failures" $
      forAllStandaloneZeroNetChangeTx TopTx.standaloneTopTxWithEqualAllocationsAndReleases $ \topTxWithoutTopDeclaration -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit [])
              topTxWithoutTopDeclaration)
        removeTopTxReleaseDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- SubTx scenarios recreate each funded source as an output of the same body.
    -- Active bodies have allocatedDeposits(body) = releasedDeposits(body) > 0;
    -- inactive bodies have no ordinary Store operations and contribute zero.
    -- activeSubTxs = {subTx ∈ subTxs | releasedDeposits(subTx) > 0}.
    -- TopTx's zero declares the complete transaction total, including its children.

    -- One SubTx, equal allocations and releases with explicit zero at both levels.
    -- TopTx has no own Store operations; the child declaration still requires its field.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-N02 - subTxs = {subTx} ∧ allocatedDeposits(subTx) = releasedDeposits(subTx) > 0 ∧ ¬ownStoreOperations(topTx) ∧ declaration(topTx) = declaration(subTx) = ExplicitZero ⇒ accepted" $
      forAllSubTxZeroNetChangeTx SubTx.oneSubTxWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations TopTx.DeclaresZeroNetUTxODeposit
              [SubTx.DeclaresZeroNetUTxODeposit])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- One SubTx omits its declaration despite its zero net change.
    -- TopTx's zero cannot replace the active child's declaration.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F02 - subTxs = {subTx} ∧ allocatedDeposits(subTx) = releasedDeposits(subTx) > 0 ∧ declaration(topTx) = ExplicitZero ∧ ¬hasDeclaration(subTx) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.oneSubTxWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                [SubTx.DeclaresZeroNetUTxODeposit])
              topTxWithoutDeclarations)
        forM_ (SubTx.storeBackedInputs topTxWithoutDeclarations) $ \input ->
          removeSubTxReleaseDeclarationByInput input signedTx
            >>= submitTx >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- TopTx omits the declaration required by its zero-net SubTx.
    -- The parent has no own Store operations: require the SubTx-to-TopTx failure.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F03 - subTxs = {subTx} ∧ allocatedDeposits(subTx) = releasedDeposits(subTx) > 0 ∧ ¬ownStoreOperations(topTx) ∧ declaration(subTx) = ExplicitZero ∧ ¬hasDeclaration(topTx) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.oneSubTxWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                [SubTx.DeclaresZeroNetUTxODeposit])
              topTxWithoutDeclarations)
        removeTopTxReleaseDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingTopTxUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- Several SubTxs each have zero net change, all with explicit zero.
    -- Every child has both positive operations; their own zero is checked independently.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-N03 - |subTxs| ≥ 2 ∧ ¬ownStoreOperations(topTx) ∧ (∀ subTx ∈ subTxs: allocatedDeposits(subTx) = releasedDeposits(subTx) > 0 ∧ declaration(subTx) = ExplicitZero) ∧ declaration(topTx) = ExplicitZero ⇒ accepted" $
      forAllSubTxZeroNetChangeTx SubTx.severalSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations TopTx.DeclaresZeroNetUTxODeposit
              (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- One zero-net SubTx omits its declaration while its siblings still declare zero.
    -- Omit each child in turn; neither parent nor sibling declarations supply its field.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F04 - |subTxs| ≥ 2 ∧ (∀ subTx ∈ subTxs: allocatedDeposits(subTx) = releasedDeposits(subTx) > 0) ∧ declaration(topTx) = ExplicitZero ∧ (∃! subTx ∈ subTxs: ¬hasDeclaration(subTx)) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.severalSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
              topTxWithoutDeclarations)
        forM_ (SubTx.storeBackedInputs topTxWithoutDeclarations) $ \input ->
          removeSubTxReleaseDeclarationByInput input signedTx
            >>= submitTx >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- Only some SubTxs have Store operations; each active child has zero net change.
    -- Active children declare zero. Implicit-only siblings remain undeclared.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-N04 - ∅ ⊂ activeSubTxs ⊂ subTxs ∧ (∀ subTx ∈ activeSubTxs: allocatedDeposits(subTx) = releasedDeposits(subTx) > 0 ∧ declaration(subTx) = ExplicitZero) ∧ (∀ subTx ∈ subTxs ∖ activeSubTxs: ¬hasDeclaration(subTx)) ∧ declaration(topTx) = ExplicitZero ⇒ accepted" $
      forAllSubTxZeroNetChangeTx SubTx.onlySomeSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations TopTx.DeclaresZeroNetUTxODeposit
              [ case releasedDeposit of
                  Coin 0 -> SubTx.NoUTxODepositDeclaration
                  _ -> SubTx.DeclaresZeroNetUTxODeposit
              | releasedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- An active zero-net SubTx omits its declaration among inactive siblings.
    -- Omit each active child separately. Inactive siblings legitimately stay undeclared.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F05 - ∅ ⊂ activeSubTxs ⊂ subTxs ∧ (∀ subTx ∈ activeSubTxs: allocatedDeposits(subTx) = releasedDeposits(subTx) > 0) ∧ declaration(topTx) = ExplicitZero ∧ (∃! subTx ∈ activeSubTxs: ¬hasDeclaration(subTx)) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.onlySomeSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                [ case releasedDeposit of
                    Coin 0 -> SubTx.NoUTxODepositDeclaration
                    _ -> SubTx.DeclaresZeroNetUTxODeposit
                | releasedDeposit <- SubTx.releasedDeposits topTxWithoutDeclarations
                ])
              topTxWithoutDeclarations)
        forM_ (SubTx.storeBackedInputs topTxWithoutDeclarations) $ \input ->
          removeSubTxReleaseDeclarationByInput input signedTx
            >>= submitTx >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- TopTx and several SubTxs each have zero net change and declare zero.
    -- The parent has its own positive allocations and releases, as does every child.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-N05 - |subTxs| ≥ 2 ∧ (∀ body ∈ {topTx} ∪ subTxs: allocatedDeposits(body) = releasedDeposits(body) > 0 ∧ declaration(body) = ExplicitZero) ⇒ accepted" $
      forAllSubTxZeroNetChangeTx SubTx.topTxAndSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations TopTx.DeclaresZeroNetUTxODeposit
              (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- TopTx omits its declaration despite its own zero-net Store operations.
    -- Require the own-operations failure even if child declarations also require TopTx.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F06 - |subTxs| ≥ 2 ∧ (∀ body ∈ {topTx} ∪ subTxs: allocatedDeposits(body) = releasedDeposits(body) > 0) ∧ (∀ subTx ∈ subTxs: declaration(subTx) = ExplicitZero) ∧ ¬hasDeclaration(topTx) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.topTxAndSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
              topTxWithoutDeclarations)
        removeTopTxReleaseDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- Phase 2 fails with explicit zero for TopTx and every active SubTx.
    -- A real failing script and valid collateral select the collateral execution path.
    -- The hypothetical ordinary Store operations still require all declarations.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-N06 - phase2Result = Failed ∧ declaredPhase2 = Invalid ∧ |subTxs| ≥ 2 ∧ (∀ body ∈ {topTx} ∪ subTxs: allocatedDeposits(body) = releasedDeposits(body) > 0 ∧ declaration(body) = ExplicitZero) ⇒ accepted" $
      forAllSubTxZeroNetChangeTx SubTx.topTxAndSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations ->
        buildAndSignPhase2InvalidTx
          (TopTx.addDeclaration
            (Declarations TopTx.DeclaresZeroNetUTxODeposit
              (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted

    -- A zero-net SubTx omits its declaration on a phase-2-invalid proposal.
    -- Omit each child separately; the fully declared control is accepted.
    -- Declaration rejection may occur before script evaluation.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F07 - phase2Script = AlwaysFails ∧ declaredPhase2 = Invalid ∧ |subTxs| ≥ 2 ∧ (∀ body ∈ {topTx} ∪ subTxs: allocatedDeposits(body) = releasedDeposits(body) > 0) ∧ declaration(topTx) = ExplicitZero ∧ (∃! subTx ∈ subTxs: ¬hasDeclaration(subTx)) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.topTxAndSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignPhase2InvalidTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
              topTxWithoutDeclarations)
        forM_ (SubTx.storeBackedInputs topTxWithoutDeclarations) $ \input ->
          removeSubTxReleaseDeclarationByInput input signedTx
            >>= submitTx >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- TopTx omits its own required declaration on a phase-2-invalid proposal.
    -- Child declarations and the zero net amount do not supply the parent field.
    -- The unchanged explicitly declared control is accepted on the failure path.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE-F08 - phase2Script = AlwaysFails ∧ declaredPhase2 = Invalid ∧ |subTxs| ≥ 2 ∧ (∀ body ∈ {topTx} ∪ subTxs: allocatedDeposits(body) = releasedDeposits(body) > 0) ∧ (∀ subTx ∈ subTxs: declaration(subTx) = ExplicitZero) ∧ ¬hasDeclaration(topTx) ⇒ rejected" $
      forAllSubTxZeroNetChangeTx SubTx.topTxAndSubTxsWithEqualAllocationsAndReleases $ \topTxWithoutDeclarations -> do
        signedTx <-
          buildAndSignPhase2InvalidTx
            (TopTx.addDeclaration
              (Declarations TopTx.DeclaresZeroNetUTxODeposit
                (replicate (SubTx.count $ TopTx.unsignedTx topTxWithoutDeclarations) SubTx.DeclaresZeroNetUTxODeposit))
              topTxWithoutDeclarations)
        removeTopTxReleaseDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
