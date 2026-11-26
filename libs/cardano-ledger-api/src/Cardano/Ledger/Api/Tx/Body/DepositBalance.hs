{-# LANGUAGE DataKinds #-}

module Cardano.Ledger.Api.Tx.Body.DepositBalance (
  UTxODepositStrategy (..),
  DepositTopUp (..),
  TopTxDepositSettlement (..),
  SubTxDepositSettlement (..),
  NetBalanceError (..),
  computeNetBalance,
  updateTxBodyWithNetBalance,
  computeSubTxNetBalance,
  updateSubTxBodyWithNetBalance,
) where

import Cardano.Ledger.Api.Tx.Body.DepositBalance.Error (NetBalanceError (..))
import Cardano.Ledger.Api.Tx.Body.DepositBalance.Internals (
  applyTopTxNetBalance,
  balanceTopTx,
  prepareSubTxBody,
  subTxNetBalance,
  writeSubTxNetBalance,
 )
import Cardano.Ledger.Api.Tx.Body.DepositBalance.Strategy (
  DepositTopUp (..),
  SubTxDepositSettlement (..),
  TopTxDepositSettlement (..),
  UTxODepositStrategy (..),
 )
import Cardano.Ledger.Core (TxBody, TxLevel (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositFormulaHistory)
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import Control.Monad ((<=<))

-- | Compute the complete batch's deposit declaration from a built TopTx.
-- Explicit child declarations supply their signed contributions. For a child
-- that omits its declaration, this also resolves its inputs and prices its outputs.
-- Both output forms contribute backing. Minimum-ADA inputs credit at most the
-- ADA they carry, using the formula recorded at their creation.
-- The existing TopTx declaration does not affect the result.
--
-- Supply the formula history and available UTxOs from the same ledger snapshot.
-- Final deposit magnitudes must satisfy the builder's @StrictlyPositiveCoin@
-- invariant. Zero is handled explicitly before constructing a positive amount.
-- A 'TopUpFromInput' candidate is selected when TopTx's attributed deposit allocation
-- is positive, then its historical backing is included in the final calculation.
-- 'TopUpAlreadyIncluded' uses the spending inputs already present in the body.
-- A candidate already spent by TopTx is counted once. A new refund output is
-- appended only when both the batch and TopTx's attributed share release backing.
-- Its active backing is included before computing the final amount and output index.
-- That backing must leave both releases positive. Existing output indices are
-- checked only when TopTx receives a net-release share.
--
-- This computes the declaration that 'updateTxBodyWithNetBalance' would write.
-- When balancing serialized ADA, change and fees, account for the full change
-- in external Store deposits. Embedded backing is already in the ordinary values.
computeNetBalance ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (TopTxDepositSettlement DijkstraEra) ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError TopTx.NetUTxODepositChange
computeNetBalance history utxos strategy =
  fmap snd . balanceTopTx history utxos strategy

-- | Add the selected top-up input and any new refund output, then write the
-- computed TopTx declaration. The supplied refund output is appended unchanged.
updateTxBodyWithNetBalance ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (TopTxDepositSettlement DijkstraEra) ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError (TxBody TopTx DijkstraEra)
updateTxBodyWithNetBalance history utxos strategy =
  fmap (uncurry applyTopTxNetBalance) . balanceTopTx history utxos strategy

-- | Compute a SubTx's own deposit declaration. Either local output variant
-- chooses local allocation funding or a local refund. 'DelegateDepositToTopTx'
-- requests allocation funding from TopTx or delegates the release to it.
-- An explicit zero makes no funding request.
--
-- A 'TopUpFromInput' candidate is selected only for a positive, locally funded
-- allocation. As with 'computeNetBalance', it is included before computing the
-- final declaration. A new local refund output is appended unchanged only for
-- a release, and its active backing must leave a positive release. Output ADA and fees
-- remain the TxBuilder's responsibility.
computeSubTxNetBalance ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (SubTxDepositSettlement DijkstraEra) ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError SubTx.SubTxNetUTxODepositChange
computeSubTxNetBalance history utxos strategy =
  subTxNetBalance history utxos (depositSettlement strategy)
    <=< prepareSubTxBody history utxos strategy

-- | Add the selected top-up input and any new refund output, then write the
-- computed SubTx declaration. The supplied policy determines local funding or
-- delegation on every call.
updateSubTxBodyWithNetBalance ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (SubTxDepositSettlement DijkstraEra) ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (TxBody SubTx DijkstraEra)
updateSubTxBodyWithNetBalance history utxos strategy =
  writeSubTxNetBalance history utxos (depositSettlement strategy)
    <=< prepareSubTxBody history utxos strategy
