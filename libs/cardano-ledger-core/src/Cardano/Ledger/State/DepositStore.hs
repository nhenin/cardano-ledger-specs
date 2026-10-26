{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Cardano.Ledger.State.DepositStore (
  DepositStore (..),
  depositStoreBalance,
  depositStoreAllocationsL,
) where

import Cardano.Ledger.BaseTypes (KeyValuePairs (..), ToKeyValuePairs (..))
import Cardano.Ledger.Binary
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.TxIn (TxIn)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON, (.=))
import Data.Default (Default (def))
import Data.Foldable (fold)
import Data.Map.Strict (Map)
import GHC.Generics (Generic)
import Lens.Micro (Lens', lens)
import NoThunks.Class (NoThunks)

-- | Read-only historical deposit amounts projected from ledger state for
-- accounting and compatibility. Each entry gives a store-backed output's deposit
-- at creation; spending releases that amount without repricing the output.
--
-- This map is not authoritative persistent ledger storage.
-- @InMemoryUnspentTxOutputStore@ owns the live outputs, their historical pricing
-- metadata and the cached deposit total. A projection can contain all allocations
-- or only those needed by a transaction. Its balance is derived from these
-- entries; changing the projection does not update ledger state.
newtype DepositStore = DepositStore
  { depositStoreAllocations :: Map TxIn Coin
  }
  deriving (Eq, Show, Generic)
  deriving (ToJSON) via KeyValuePairs DepositStore

instance NFData DepositStore

instance NoThunks DepositStore

instance Default DepositStore where
  def = DepositStore mempty

instance EncCBOR DepositStore where
  encCBOR = encCBOR . depositStoreAllocations

instance DecCBOR DepositStore where
  decCBOR = DepositStore <$> decCBOR

instance ToKeyValuePairs DepositStore where
  toKeyValuePairs DepositStore {depositStoreAllocations} =
    ["allocations" .= depositStoreAllocations]

-- | Sum of the projected deposit amounts. Computing it traverses this map;
-- a projection restricted to selected inputs is not the ledger's total deposit.
depositStoreBalance :: DepositStore -> Coin
depositStoreBalance = fold . depositStoreAllocations

depositStoreAllocationsL :: Lens' DepositStore (Map TxIn Coin)
depositStoreAllocationsL =
  lens depositStoreAllocations (\store allocations -> store {depositStoreAllocations = allocations})
{-# INLINE depositStoreAllocationsL #-}
