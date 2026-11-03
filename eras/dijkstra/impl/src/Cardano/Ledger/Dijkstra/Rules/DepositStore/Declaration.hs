{-# LANGUAGE DataKinds #-}

-- | Rules for declaring UTxO capacity deposit changes across TopTx and SubTx.
-- Allocation and release concern proposed ordinary-path Store operations before
-- netting: a body may require both, including when their net change is zero.
-- Presence follows the 'NewTxOut' form, even when its deposit amount is
-- zero. These checks establish neither amount exactness nor ledger acceptance.
-- They apply on both phase-2 paths; ordinary Store effects require phase-2 success.
-- Ledger predicate failures are assigned by the calling transition rule.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.Declaration (
  DepositStoreDeclarationFailure (..),
  DepositStoreOutputDeclarationFailure (..),
  hasSubTxNetUTxODepositDeclaration,
  validateTopTxNetUTxODepositDeclaration,
  validateTopTxAllocationDeclarationPresence,
  validateSubTxAllocationDeclarationPresence,
  validateTopTxReleaseDeclarationPresence,
  validateSubTxReleaseDeclarationPresence,
) where

import Cardano.Ledger.Dijkstra.Core (
  DijkstraEraTxBody (..),
  EraTx (bodyTxL),
  EraTxBody (inputsTxBodyL, outputsTxBodyL),
  SubTx,
  TopTx,
  Tx,
  TxBody,
  TxOut (..),
 )
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Data.List.NonEmpty (NonEmpty)
import Lens.Micro ((^.))
import Validation (Validation, failureUnless)

data DepositStoreDeclarationFailure
  = MissingTopTxDeclaration
  deriving (Eq, Show)

-- | A body proposing a Store allocation or release has not declared its deposit
-- change. Independent of the TopTx/SubTx declaration dependency.
data DepositStoreOutputDeclarationFailure
  = MissingBodyUTxODepositDeclaration
  deriving (Eq, Show)

-- | DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION: require TopTx's declaration for allocations
-- proposed by its own regular store-backed outputs. SubTx outputs and collateral
-- return are outside this check. Released deposits do not remove this requirement.
validateTopTxAllocationDeclarationPresence ::
  DijkstraEraTxBody era =>
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateTopTxAllocationDeclarationPresence txBody =
  validateStoreBackedOutputsDeclaration
    (TopTx.hasUTxODepositDeclaration $ txBody ^. netUTxODepositChangeTxBodyL)
    (txBody ^. outputsTxBodyL)

-- | DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION: require SubTx's own declaration for
-- allocations proposed by its regular store-backed outputs. A TopTx declaration
-- cannot substitute for it, even if the SubTx's net change is zero.
validateSubTxAllocationDeclarationPresence ::
  DijkstraEraTxBody era =>
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateSubTxAllocationDeclarationPresence txBody =
  validateStoreBackedOutputsDeclaration
    (SubTx.hasUTxODepositDeclaration $ txBody ^. subTxNetUTxODepositChangeTxBodyL)
    (txBody ^. outputsTxBodyL)

-- | DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE: require TopTx's declaration for releases
-- proposed by its own ordinary inputs, resolved against the original allocations.
-- Reference and collateral inputs do not count. No recorded amount is needed.
-- Missing inputs remain the responsibility of the existing BadInputs check.
validateTopTxReleaseDeclarationPresence ::
  DijkstraEraTxBody era =>
  IndexedUTxOs era ->
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateTopTxReleaseDeclarationPresence originalAllocations txBody =
  validateStoreBackedOutputsDeclaration
    (TopTx.hasUTxODepositDeclaration $ txBody ^. netUTxODepositChangeTxBodyL)
    (IndexedUTxOs.txOuts . IndexedUTxOs.restrictToInputs (txBody ^. inputsTxBodyL) $ originalAllocations)

-- | DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE: require SubTx's own declaration for releases
-- proposed by its ordinary inputs, even when its new outputs are all implicit.
-- Allocations do not remove this requirement. No recorded amount is needed.
validateSubTxReleaseDeclarationPresence ::
  DijkstraEraTxBody era =>
  IndexedUTxOs era ->
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateSubTxReleaseDeclarationPresence originalAllocations txBody =
  validateStoreBackedOutputsDeclaration
    (SubTx.hasUTxODepositDeclaration $ txBody ^. subTxNetUTxODepositChangeTxBodyL)
    (IndexedUTxOs.txOuts . IndexedUTxOs.restrictToInputs (txBody ^. inputsTxBodyL) $ originalAllocations)

-- | Shared structural presence check over proposed outputs or resolved inputs.
-- Any store-backed output requires a declaration, regardless of deposit amount.
validateStoreBackedOutputsDeclaration ::
  Foldable f =>
  Bool ->
  f (TxOut era) ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateStoreBackedOutputsDeclaration hasDeclaration outputs =
  failureUnless
    (hasDeclaration || not (any isStoreBackedOutput outputs))
    MissingBodyUTxODepositDeclaration

isStoreBackedOutput :: TxOut era -> Bool
isStoreBackedOutput (LegacyTxOut _) = False
isStoreBackedOutput (NewTxOut _) = True

-- | Whether a SubTx explicitly declares a net UTxO capacity deposit change,
-- including zero.
hasSubTxNetUTxODepositDeclaration ::
  (EraTx era, DijkstraEraTxBody era) =>
  Tx SubTx era ->
  Bool
hasSubTxNetUTxODepositDeclaration subTx =
  SubTx.hasUTxODepositDeclaration $ subTx ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL

-- | DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS: any SubTx declaration requires a TopTx declaration.
-- Explicit zero counts as a declaration, regardless of local or delegated accounting.
validateTopTxNetUTxODepositDeclaration ::
  (EraTx era, DijkstraEraTxBody era) =>
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreDeclarationFailure) ()
validateTopTxNetUTxODepositDeclaration txBody =
  failureUnless
    ( TopTx.hasUTxODepositDeclaration (txBody ^. netUTxODepositChangeTxBodyL)
        || not (any hasSubTxNetUTxODepositDeclaration (txBody ^. subTransactionsTxBodyL))
    )
    MissingTopTxDeclaration
