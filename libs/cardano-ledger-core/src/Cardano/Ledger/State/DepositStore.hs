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

-- | ADA held outside outputs to fund their UTxO capacity deposits. Allocations
-- record each live store-backed output's deposit at creation; spending releases
-- that recorded amount, without pricing the consumed output again.
--
-- The Store holds exactly the sum of its recorded deposits. Its balance is
-- derived from this map, never stored or updated independently. Count that sum
-- once when computing total ledger ADA; it is not part of the outputs' coins.
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

-- | Total ADA held by the Store. Computing it traverses the allocation map.
depositStoreBalance :: DepositStore -> Coin
depositStoreBalance = fold . depositStoreAllocations

depositStoreAllocationsL :: Lens' DepositStore (Map TxIn Coin)
depositStoreAllocationsL =
  lens depositStoreAllocations (\store allocations -> store {depositStoreAllocations = allocations})
{-# INLINE depositStoreAllocationsL #-}
