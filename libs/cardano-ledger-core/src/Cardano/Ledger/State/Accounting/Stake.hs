{-# LANGUAGE RecordWildCards #-}

-- | Update accounting's stake index from the actual transaction output changes.
module Cardano.Ledger.State.Accounting.Stake (
  projectTx,
) where

import Cardano.Ledger.State.Accounting.InstantStake (EraStake, updateInstantStake)
import Cardano.Ledger.State.Accounting.State (asInstantStakeL)
import Cardano.Ledger.State.Accounting.TxProjected (TxProjected (..))
import Lens.Micro ((%~), (&))

-- | Apply the consumed and produced entries, preserving the projection for the
-- remaining accounting fields and the calling rule's event handling.
projectTx ::
  (EraStake era, Applicative m) =>
  TxProjected era ->
  m (TxProjected era)
projectTx projection@TxProjected {..} =
  pure $
    projection
      { updatedAccountingState =
          updatedAccountingState
            & asInstantStakeL
              %~ updateInstantStake consumedOutputs producedOutputs
      }
