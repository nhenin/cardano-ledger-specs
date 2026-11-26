{-# LANGUAGE FlexibleContexts #-}

-- | Activate deposit parameters without repricing existing unspent outputs.
module Cardano.Ledger.Dijkstra.UTxOs.Deposit (
  activateDepositParameters,
) where

import Cardano.Ledger.Babbage.Core (BabbageEraPParams, PParams, ppCoinsPerUTxOByteL)
import Cardano.Ledger.Slot (SlotNo)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositFormula (..))
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore)
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Lens.Micro ((&), (^.))

-- | Apply the effective byte price to the Store's active formula version.
-- Record the actual activation slot. Dijkstra starts with V1; parameter changes
-- preserve an explicitly selected V2. Earlier history and allocations stay fixed.
activateDepositParameters ::
  BabbageEraPParams era => SlotNo -> PParams era -> UTxOStore era -> UTxOStore era
activateDepositParameters slot pp store =
  ( case Store.currentFormula store of
      DepositFormulaV1 _ -> DepositFormulaV1 $ pp ^. ppCoinsPerUTxOByteL
      DepositFormulaV2 _ -> DepositFormulaV2 $ pp ^. ppCoinsPerUTxOByteL
  )
    & \formula -> Store.activateNewFormula slot formula store
