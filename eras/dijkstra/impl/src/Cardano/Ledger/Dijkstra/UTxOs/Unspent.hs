-- | Historical deposit queries for outputs in the Dijkstra Store.
module Cardano.Ledger.Dijkstra.UTxOs.Unspent (
  computeDeposit,
  computeApplicationAssets,
) where

import Cardano.Ledger.Core
import Cardano.Ledger.Dijkstra.Era (DijkstraEra)
import Cardano.Ledger.Dijkstra.TxOut ()
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula as Formula
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositAmount (..), DepositFormulaHistory)
import Cardano.Ledger.State.Accounting.UTxOs.Unspent (
  Unspent (Unspent),
  allocationFormula,
  toTxOut,
 )
import Cardano.Ledger.Val (modifyCoin, (<->))
import Lens.Micro ((&), (^.))

-- | Apply the allocation's historical formula. A migrated legacy reserve is
-- included in its output ADA and capped by that amount; a new deposit is external.
computeDeposit ::
  DepositFormulaHistory ->
  Unspent (TxOut DijkstraEra) ->
  DepositAmount
computeDeposit history (Unspent output origin) =
  Formula.computeDeposit (allocationFormula history origin) output
    & \deposit -> case output of
      LegacyTxOut _ -> DepositAmount . min (output ^. coinTxOutL) $ toCoin deposit
      NewTxOut _ -> deposit

-- | View application assets without modifying the stored output. Only the ADA
-- reserve is removed from a legacy value; every native asset remains unchanged.
computeApplicationAssets ::
  DepositFormulaHistory ->
  Unspent (TxOut DijkstraEra) ->
  ApplicationAssets DijkstraEra
computeApplicationAssets history entry = case toTxOut entry of
  LegacyTxOut output ->
    ApplicationAssets . modifyCoin (<-> toCoin (computeDeposit history entry)) $ output ^. valueTxOutL
  NewTxOut output -> output ^. applicationAssetsTxOutL
