{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}

-- | Compose transaction accounting from each field's projection. Field modules
-- own their phase-specific rules; era instances supply collateral and donation
-- amounts. The calling rule emits output events from the returned projection.
module Cardano.Ledger.State.Accounting (
  -- * Model
  AccountingState (..),

  -- * Era accounting amounts
  EraAccounting (..),

  -- * Transaction projection
  TxProjected (..),
  projectTx,

  -- * Field lenses
  asUTxOStoreL,
  asDepositedL,
  asFeesL,
  asInstantStakeL,
  asDonationL,
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core (EraTx (Tx), PParams, TopTx)
import Cardano.Ledger.Slot (SlotNo)
import qualified Cardano.Ledger.State.Accounting.Deposits as Deposits
import qualified Cardano.Ledger.State.Accounting.Donation as Donation
import Cardano.Ledger.State.Accounting.Era (EraAccounting (..))
import qualified Cardano.Ledger.State.Accounting.Fees as Fees
import Cardano.Ledger.State.Accounting.InstantStake (EraStake)
import qualified Cardano.Ledger.State.Accounting.Stake as Stake
import Cardano.Ledger.State.Accounting.State
import Cardano.Ledger.State.Accounting.TxProjected (TxProjected (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Cardano.Ledger.State.Certificates (EraCertState (CertState))
import Lens.Micro ((&), (.~))

-- | Project only this body's Store effects onto the live accounting state;
-- SubTx execution remains the ledger's responsibility. Deposit calculations
-- follow 'EraCertState' and may include SubTx certificates and proposals.
--
-- Capture the incoming Store for collateral fees before projecting any outputs.
-- Invalid SubTxs leave this Store unchanged; valid fees use the declared fee.
-- Return the actual deposit and output changes. Projection is pure;
-- the calling rule emits accounting events only for phase-2-valid transactions.
projectTx ::
  ( EraAccounting era
  , EraStake era
  , EraCertState era
  ) =>
  SlotNo ->
  PParams era ->
  CertState era ->
  AccountingState era ->
  Tx TopTx era ->
  TxProjected era
projectTx slot pp certState accountingState tx =
  accountingState
    & Donation.projectTx tx
    & Deposits.projectTx pp certState tx
    & \(depositChange, withDeposits) ->
      withDeposits
        & asUTxOStore
        & Store.projectTx slot tx
        & adaptProjectedTxModels depositChange withDeposits
        & Stake.projectTx
        & Fees.projectTx (asUTxOStore accountingState) tx

-- | Assemble the accounting result from the deposit delta and actual Store effects.
adaptProjectedTxModels ::
  Coin ->
  AccountingState era ->
  Store.TxProjected era ->
  TxProjected era
adaptProjectedTxModels depositChange accountingState Store.TxProjected {..} =
  TxProjected
    { updatedAccountingState = accountingState & asUTxOStoreL .~ updatedStore
    , ..
    }
