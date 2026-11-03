{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

-- | Active pricing and accepted outputs with immutable historical calculations.
-- Construction and transaction projection maintain the cached deposit total.
module Cardano.Ledger.State.Accounting.UTxOs.Store (
  -- * Store and queries
  UTxOStore (currentCalculation, totalDepositAmount, allocations),

  -- * Construction
  mkEmptyUTxOStore,
  mkUTxOStore,

  -- * Transaction projection
  TxProjected (..),
  projectTx,

  -- * Calculation activation
  activateNewCalculation,
) where

import Cardano.Ledger.Core (EraTx (..), IsPhase2Valid (..), TxLevel (TopTx))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositAmount (..), DepositCalculation)
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.State.Accounting.UTxOs.Store.Internals (TxProjected (..), UTxOStore (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store.Internals as Internals
import Lens.Micro ((^.))

-- | Start an empty Store with the calculation to record on future allocations.
mkEmptyUTxOStore :: DepositCalculation -> UTxOStore era
mkEmptyUTxOStore calculation =
  UTxOStore
    { currentCalculation = calculation
    , totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = mempty
    }

-- | Restore complete historical entries with an explicit current calculation.
-- Derive the total without replacing any entry's recorded size or calculation.
mkUTxOStore :: DepositCalculation -> IndexedUTxOs era -> UTxOStore era
mkUTxOStore calculation entries =
  UTxOStore
    { currentCalculation = calculation
    , totalDepositAmount = IndexedUTxOs.sumDepositAmounts entries
    , allocations = entries
    }

-- | Select the calculation for future allocations. Existing records and their
-- deposits remain unchanged, including when the Store is empty.
activateNewCalculation :: DepositCalculation -> UTxOStore era -> UTxOStore era
activateNewCalculation calculation store = store {currentCalculation = calculation}

-- | Project this TopTx's own Store effects according to its phase-2 validity tag.
-- Return the updated Store and its actual consumed/produced entries.
-- Validation and SubTx execution remain the ledger's responsibility.
projectTx :: EraTx era => Tx TopTx era -> UTxOStore era -> TxProjected era
projectTx tx =
  case tx ^. isPhase2ValidTxG of
    Phase2Valid -> Internals.projectValidTxBody (tx ^. bodyTxL)
    Phase2Invalid -> Internals.projectInvalidTxBody (tx ^. bodyTxL)
