{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
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
import qualified Cardano.Ledger.State.Accounting.Deposits as Deposits
import qualified Cardano.Ledger.State.Accounting.Donation as Donation
import Cardano.Ledger.State.Accounting.Era (EraAccounting (..))
import qualified Cardano.Ledger.State.Accounting.Fees as Fees
import Cardano.Ledger.State.Accounting.InstantStake (EraStake)
import qualified Cardano.Ledger.State.Accounting.Stake as Stake
import Cardano.Ledger.State.Accounting.State
import Cardano.Ledger.State.Accounting.TxProjected (TxProjected (..))
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore)
import qualified Cardano.Ledger.State.Accounting.UTxOs.Tx as UTxOs
import Cardano.Ledger.State.Certificates (EraCertState (CertState))
import Control.Monad ((>=>))

-- | Project only this body's Store effects onto the live accounting state;
-- SubTx execution remains the ledger's responsibility. Deposit calculations
-- follow 'EraCertState' and may include SubTx certificates and proposals.
--
-- The separate original Store is used only for collateral fees. In Dijkstra it
-- is captured before SubTx execution, after activating the current calculation.
-- Only valid transactions invoke the deposit-change callback. Actual output
-- changes are returned for both paths, leaving event emission to the calling rule.
projectTx ::
  ( EraAccounting era
  , EraStake era
  , EraCertState era
  , Monad m
  ) =>
  PParams era ->
  Tx TopTx era ->
  CertState era ->
  UTxOStore era ->
  (Coin -> m ()) ->
  AccountingState era ->
  m (TxProjected era)
projectTx pp tx certState previousStore depositChangeEvent =
  Donation.projectTx tx
    >=> Deposits.projectTx pp certState tx depositChangeEvent
    >=> UTxOs.projectTx tx
    >=> Stake.projectTx
    >=> Fees.projectTx previousStore tx
