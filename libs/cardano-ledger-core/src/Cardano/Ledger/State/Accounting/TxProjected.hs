{-# LANGUAGE DeriveGeneric #-}

-- | The completed accounting state and the output changes used to derive it.
-- Rules decide which events to emit from this result.
module Cardano.Ledger.State.Accounting.TxProjected (
  TxProjected (..),
) where

import Cardano.Ledger.State.Accounting.State (AccountingState)
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import GHC.Generics (Generic)

-- | Actual historical entries changed by the transaction. Invalid projections
-- contain collateral changes too, even when the rule emits no UTxO diff event.
data TxProjected era = TxProjected
  { updatedAccountingState :: !(AccountingState era)
  , consumedOutputs :: !(IndexedUTxOs era)
  , producedOutputs :: !(IndexedUTxOs era)
  }
  deriving (Generic)
