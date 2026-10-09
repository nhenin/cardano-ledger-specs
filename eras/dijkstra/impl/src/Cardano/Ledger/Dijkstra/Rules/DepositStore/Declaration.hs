{-# LANGUAGE DataKinds #-}

-- | Rules for declaring UTxO capacity deposit changes across TopTx and SubTx.
-- Ledger predicate failures are assigned by the calling transition rule.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.Declaration (
  DepositStoreDeclarationFailure (..),
  DepositStoreOutputDeclarationFailure (..),
  hasSubTxNetUTxODepositDeclaration,
  validateTopTxNetUTxODepositDeclaration,
  validateTopTxCreatedOutputsDeclaration,
  validateSubTxCreatedOutputsDeclaration,
) where

import Cardano.Ledger.Dijkstra.Core (
  DijkstraEraTxBody (..),
  EraTx (bodyTxL),
  EraTxBody (outputsTxBodyL),
  SubTx,
  TopTx,
  Tx,
  TxBody,
  TxOut (..),
 )
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Data.List.NonEmpty (NonEmpty)
import Lens.Micro ((^.))
import Validation (Validation, failureUnless)

data DepositStoreDeclarationFailure
  = MissingTopTxDeclaration
  deriving (Eq, Show)

-- | A body creating store-backed outputs has not declared its UTxO capacity
-- deposit change. Independent of the TopTx/SubTx declaration dependency.
data DepositStoreOutputDeclarationFailure
  = MissingBodyUTxODepositDeclaration
  deriving (Eq, Show)

-- | DS-TX-001, creation: check only TopTx's own regular outputs. SubTx outputs
-- and collateral return do not establish Store activity for this check.
-- Success establishes declaration presence, not the correctness of its amount.
validateTopTxCreatedOutputsDeclaration ::
  DijkstraEraTxBody era =>
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateTopTxCreatedOutputsDeclaration txBody =
  validateCreatedOutputsDeclaration
    (TopTx.hasUTxODepositDeclaration $ txBody ^. netUTxODepositChangeTxBodyL)
    (txBody ^. outputsTxBodyL)

-- | DS-TX-001, creation: a SubTx must declare its own change when it creates
-- store-backed outputs. A TopTx declaration cannot substitute for it.
validateSubTxCreatedOutputsDeclaration ::
  DijkstraEraTxBody era =>
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateSubTxCreatedOutputsDeclaration txBody =
  validateCreatedOutputsDeclaration
    (SubTx.hasUTxODepositDeclaration $ txBody ^. subTxNetUTxODepositChangeTxBodyL)
    (txBody ^. outputsTxBodyL)

-- | Creating any store-backed output requires the creating body's declaration.
validateCreatedOutputsDeclaration ::
  Foldable f =>
  Bool ->
  f (TxOut era) ->
  Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
validateCreatedOutputsDeclaration hasDeclaration outputs =
  failureUnless
    (hasDeclaration || not (any isStoreBackedOutput outputs))
    MissingBodyUTxODepositDeclaration

isStoreBackedOutput :: TxOut era -> Bool
isStoreBackedOutput (ImplicitDepositTxOut _) = False
isStoreBackedOutput (StoreBackedTxOut _) = True

-- | Whether a SubTx explicitly declares a net UTxO capacity deposit change,
-- including zero.
hasSubTxNetUTxODepositDeclaration ::
  (EraTx era, DijkstraEraTxBody era) =>
  Tx SubTx era ->
  Bool
hasSubTxNetUTxODepositDeclaration subTx =
  SubTx.hasUTxODepositDeclaration $ subTx ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL

-- | DS-TX-009: any SubTx declaration requires a TopTx declaration.
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
