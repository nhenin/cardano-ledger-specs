{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

-- | Active pricing and accepted outputs with immutable historical formulas.
-- Construction and transaction projection maintain the cached deposit total.
module Cardano.Ledger.State.Accounting.UTxOs.Store (
  -- * Store and queries
  UTxOStore (depositFormulaHistory, totalDepositAmount, allocations),
  currentFormula,

  -- * Construction
  mkEmptyUTxOStore,
  mkUTxOStore,

  -- * Transaction projection
  TxProjected (..),
  projectTx,

  -- * Formula activation
  activateNewFormula,

  -- * Snapshot loading
  decodeUTxOStoreWithFormula,
) where

import Cardano.Ledger.BaseTypes (SlotNo)
import Cardano.Ledger.Core (EraNewTxOut, EraTx (..), IsPhase2Valid (..), TxLevel (TopTx))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  DepositAmount (..),
  DepositFormula,
  DepositFormulaHistory,
  appendFormula,
  latestFormula,
 )
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.State.Accounting.UTxOs.Store.Internals (
  TxProjected (..),
  UTxOStore (..),
  decodeUTxOStoreWithFormula,
 )
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store.Internals as Internals
import Cardano.Ledger.State.Accounting.UTxOs.Unspent (AllocatedAt (..), allocatedAt)
import Data.Maybe (fromMaybe)
import Lens.Micro ((^.))

-- | Start an empty Store with a known formula history.
mkEmptyUTxOStore :: DepositFormulaHistory -> UTxOStore era
mkEmptyUTxOStore history =
  UTxOStore
    { depositFormulaHistory = history
    , totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = mempty
    }

-- | Restore entries with their baseline and dated formulas. Derive the
-- external total from the outputs and their allocation origins.
mkUTxOStore :: EraNewTxOut era => DepositFormulaHistory -> IndexedUTxOs era -> UTxOStore era
mkUTxOStore history entries =
  UTxOStore
    { depositFormulaHistory = history
    , totalDepositAmount = IndexedUTxOs.sumDepositAmounts history entries
    , allocations = entries
    }

-- | The most recently activated formula. Historical entries resolve their
-- own allocation slots instead of consulting this current price. With no dated
-- changes, the current formula is the baseline.
currentFormula :: UTxOStore era -> DepositFormula
currentFormula = latestFormula . depositFormulaHistory

-- | Append a later activation without rewriting any historical period.
-- Reapplying the current formula is a no-op. Callers supply the actual
-- activation boundary, before allocating outputs under the new formula.
activateNewFormula :: SlotNo -> DepositFormula -> UTxOStore era -> UTxOStore era
activateNewFormula slot formula store
  | formula == currentFormula store = store
  | any
      ( \entry -> case allocatedAt entry of
          AtStoreMigration -> False
          AtSlot allocationSlot -> allocationSlot >= slot
      )
      . IndexedUTxOs.unspentOutputs
      . allocations
      $ store =
      error "Deposit formula activation would reprice existing allocations"
  | otherwise =
      store
        { depositFormulaHistory =
            fromMaybe
              (error "Deposit formula activation must follow the last historical activation")
              (appendFormula slot formula $ depositFormulaHistory store)
        }

-- | Project this TopTx's own Store effects according to its phase-2 validity tag.
-- Return the updated Store and its actual consumed/produced entries.
-- Validation and SubTx execution remain the ledger's responsibility.
projectTx :: EraTx era => SlotNo -> Tx TopTx era -> UTxOStore era -> TxProjected era
projectTx slot tx =
  case tx ^. isPhase2ValidTxG of
    Phase2Valid -> Internals.projectValidTxBody slot (tx ^. bodyTxL)
    Phase2Invalid -> Internals.projectInvalidTxBody slot (tx ^. bodyTxL)
