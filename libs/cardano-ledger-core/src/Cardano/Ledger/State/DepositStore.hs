{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Cardano.Ledger.State.DepositStore (
  DepositStore (..),
  depositStoreBalanceL,
  depositStoreAllocationsL,
) where

import Cardano.Ledger.BaseTypes (KeyValuePairs (..), ToKeyValuePairs (..))
import Cardano.Ledger.Binary
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.TxIn (TxIn)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON, (.=))
import Data.Default (Default (def))
import Data.Map.Strict (Map)
import GHC.Generics (Generic)
import Lens.Micro (Lens', lens)
import NoThunks.Class (NoThunks)

-- | ADA held outside outputs to fund their UTxO capacity deposits. Allocations
-- record each live store-backed output's deposit at creation; spending releases
-- that recorded amount, without pricing the consumed output again.
--
-- The balance is a separate ADA pot. Allocations describe its obligations and
-- must not be counted a second time when computing the total ledger balance.
data DepositStore = DepositStore
  { depositStoreBalance :: !Coin
  , depositStoreAllocations :: !(Map TxIn Coin)
  }
  deriving (Eq, Show, Generic)
  deriving (ToJSON) via KeyValuePairs DepositStore

instance NFData DepositStore

instance NoThunks DepositStore

instance Default DepositStore where
  def = DepositStore (Coin 0) mempty

instance EncCBOR DepositStore where
  encCBOR DepositStore {depositStoreBalance, depositStoreAllocations} =
    encodeListLen 2 <> encCBOR depositStoreBalance <> encCBOR depositStoreAllocations

instance DecCBOR DepositStore where
  decCBOR =
    decodeRecordNamed "DepositStore" (const 2) $
      DepositStore <$> decCBOR <*> decCBOR

instance ToKeyValuePairs DepositStore where
  toKeyValuePairs DepositStore {depositStoreBalance, depositStoreAllocations} =
    [ "balance" .= depositStoreBalance
    , "allocations" .= depositStoreAllocations
    ]

depositStoreBalanceL :: Lens' DepositStore Coin
depositStoreBalanceL = lens depositStoreBalance (\store balance -> store {depositStoreBalance = balance})
{-# INLINE depositStoreBalanceL #-}

depositStoreAllocationsL :: Lens' DepositStore (Map TxIn Coin)
depositStoreAllocationsL =
  lens depositStoreAllocations (\store allocations -> store {depositStoreAllocations = allocations})
{-# INLINE depositStoreAllocationsL #-}
