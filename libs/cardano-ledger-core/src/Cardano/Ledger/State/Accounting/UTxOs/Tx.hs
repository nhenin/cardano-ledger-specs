{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}

-- | Install a transaction's Store projection into the live accounting state.
module Cardano.Ledger.State.Accounting.UTxOs.Tx (
  projectTx,
) where

import Cardano.Ledger.Core (EraTx (Tx), TopTx)
import Cardano.Ledger.State.Accounting.State (AccountingState (asUTxOStore), asUTxOStoreL)
import Cardano.Ledger.State.Accounting.TxProjected (TxProjected (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Lens.Micro ((&), (.~))

-- | Project this transaction's own valid or collateral effects onto the live
-- Store and carry its actual consumed and produced entries through accounting.
projectTx ::
  (EraTx era, Applicative m) =>
  Tx TopTx era ->
  AccountingState era ->
  m (TxProjected era)
projectTx tx accountingState =
  case Store.projectTx tx . asUTxOStore $ accountingState of
    Store.TxProjected {..} ->
      pure
        TxProjected
          { updatedAccountingState = accountingState & asUTxOStoreL .~ updatedStore
          , ..
          }
