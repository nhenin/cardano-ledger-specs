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

-- | Apply the allocation's historical formula. For a min-ADA output, take the
-- minimum of the calculated deposit and the ADA present in the output.
-- A deposit-backed output's deposit is held separately and is not capped by its ADA.
computeDeposit ::
  DepositFormulaHistory ->
  Unspent (TxOut DijkstraEra) ->
  DepositAmount
computeDeposit history (Unspent output origin) =
  Formula.computeDeposit (allocationFormula history origin) output
    & capMinAdaDeposit output

-- | Only min-ADA reserves are capped by the ADA present in their output.
capMinAdaDeposit :: TxOut DijkstraEra -> DepositAmount -> DepositAmount
capMinAdaDeposit output deposit
  | MinAdaTxOut _ <- output = min deposit (DepositAmount $ output ^. coinTxOutL)
  | otherwise = deposit

-- | View application assets without modifying the stored output.
-- For a valid min-ADA output, application ADA is @max 0 (outputADA - formulaDeposit)@:
-- it is zero when the formula deposit meets or exceeds the output ADA, never negative.
-- Only the ADA reserve is deducted; every native asset remains unchanged.
computeApplicationAssets ::
  DepositFormulaHistory ->
  Unspent (TxOut DijkstraEra) ->
  ApplicationAssets DijkstraEra
computeApplicationAssets history entry = case toTxOut entry of
  MinAdaTxOut output ->
    ApplicationAssets . modifyCoin (<-> toCoin (computeDeposit history entry)) $ output ^. valueTxOutL
  DepositBackedTxOut output -> output ^. applicationAssetsTxOutL
