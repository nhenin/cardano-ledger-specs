{-# LANGUAGE DataKinds #-}

-- | Rules for declaring UTxO capacity deposit changes across TopTx and SubTx.
-- Ledger predicate failures are assigned by the calling transition rule.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.Declaration (
  DepositStoreDeclarationFailure (..),
  hasSubTxNetUTxODepositDeclaration,
  validateTopTxNetUTxODepositDeclaration,
) where

import Cardano.Ledger.Dijkstra.Core (
  DijkstraEraTxBody (..),
  EraTx (bodyTxL),
  SubTx,
  TopTx,
  Tx,
  TxBody,
 )
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Data.List.NonEmpty (NonEmpty)
import Lens.Micro ((^.))
import Validation (Validation, failureUnless)

data DepositStoreDeclarationFailure
  = MissingTopTxDeclaration
  deriving (Eq, Show)

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
