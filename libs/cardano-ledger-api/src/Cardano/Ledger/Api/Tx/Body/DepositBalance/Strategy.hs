{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Funding and settlement choices supplied by the transaction builder.
module Cardano.Ledger.Api.Tx.Body.DepositBalance.Strategy (
  UTxODepositStrategy (..),
  DepositTopUp (..),
  TopTxDepositSettlement (..),
  SubTxDepositSettlement (..),
) where

import Cardano.Ledger.BaseTypes (TxIx)
import Cardano.Ledger.Core (TxOut)
import Cardano.Ledger.TxIn (TxIn)
import GHC.Generics (Generic)

-- | The builder's funding and refund choices for a transaction body.
-- The settlement type distinguishes TopTx and SubTx strategies.
data UTxODepositStrategy settlement = UTxODepositStrategy
  { depositTopUp :: !DepositTopUp
  , depositSettlement :: !settlement
  }
  deriving (Eq, Show, Generic)

-- | The builder has already included the funding inputs, or supplies a candidate
-- to add when this body has a positive deposit allocation to fund.
data DepositTopUp
  = TopUpAlreadyIncluded
  | TopUpFromInput !TxIn
  deriving (Eq, Show)

-- | Choose a new refund output, an existing output, or no TopTx settlement.
-- A new output is appended unchanged only when TopTx receives a batch release.
-- Use the existing-output variant when rebalancing a body that already includes it.
data TopTxDepositSettlement era
  = TopTxRefundToNewOutput !(TxOut era)
  | TopTxRefundToExistingOutput !TxIx
  | NoTopTxRefund
  deriving (Generic)

deriving instance Eq (TxOut era) => Eq (TopTxDepositSettlement era)

deriving instance Show (TxOut era) => Show (TopTxDepositSettlement era)

-- | Settle locally in a new or existing output, or delegate deposit accounting
-- to TopTx. The local choices also select local funding for an allocation.
data SubTxDepositSettlement era
  = SubTxRefundToNewOutput !(TxOut era)
  | SubTxRefundToExistingOutput !TxIx
  | DelegateDepositToTopTx
  deriving (Generic)

deriving instance Eq (TxOut era) => Eq (SubTxDepositSettlement era)

deriving instance Show (TxOut era) => Show (SubTxDepositSettlement era)
