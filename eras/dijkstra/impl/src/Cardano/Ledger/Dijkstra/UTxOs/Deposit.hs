{-# LANGUAGE FlexibleContexts #-}

-- | Activate deposit parameters without repricing existing unspent outputs.
module Cardano.Ledger.Dijkstra.UTxOs.Deposit (
  activateDepositParameters,
) where

import Cardano.Ledger.Babbage.Core (BabbageEraPParams, PParams, ppCoinsPerUTxOByteL)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositCalculation (..))
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore)
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Lens.Micro ((^.))

-- | Apply the effective byte price to the Store's active formula version.
-- Dijkstra starts with V1; activating new parameters preserves an explicitly
-- selected V2. Existing allocations and their recorded calculations are unchanged.
activateDepositParameters ::
  BabbageEraPParams era => PParams era -> UTxOStore era -> UTxOStore era
activateDepositParameters pp store
  | calculation == Store.currentCalculation store = store
  | otherwise = Store.activateNewCalculation calculation store
  where
    calculation = case Store.currentCalculation store of
      DepositCalculationV1 _ -> DepositCalculationV1 rate
      DepositCalculationV2 _ -> DepositCalculationV2 rate
    rate = pp ^. ppCoinsPerUTxOByteL
