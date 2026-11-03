{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeFamilies #-}

-- | Collected fees. A valid transaction pays its declared fee; a phase-2-invalid
-- transaction pays the era's collateral fee using the original Store snapshot.
module Cardano.Ledger.State.Accounting.Fees (
  projectTx,
) where

import Cardano.Ledger.Core (
  EraTx (Tx, bodyTxL, isPhase2ValidTxG),
  EraTxBody (feeTxBodyL),
  IsPhase2Valid (..),
  TopTx,
 )
import Cardano.Ledger.State.Accounting.Era (EraAccounting (collateralFee))
import Cardano.Ledger.State.Accounting.State (asFeesL)
import Cardano.Ledger.State.Accounting.TxProjected (TxProjected (..))
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore)
import Lens.Micro ((&), (<>~), (^.))

-- | Credit exactly one fee. Historical collateral pricing uses the original
-- Store even when the accounting state's live Store has already changed.
-- Preserve the projection's actual consumed and produced entries.
projectTx ::
  (EraAccounting era, Applicative m) =>
  UTxOStore era ->
  Tx TopTx era ->
  TxProjected era ->
  m (TxProjected era)
projectTx previousStore tx projection@TxProjected {updatedAccountingState} =
  pure $!
    projection
      { updatedAccountingState =
          updatedAccountingState
            & asFeesL <>~ case tx ^. isPhase2ValidTxG of
              Phase2Valid -> tx ^. bodyTxL . feeTxBodyL
              Phase2Invalid -> collateralFee previousStore $ tx ^. bodyTxL
      }
