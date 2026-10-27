{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Era-specific unspent-output storage: a legacy map or a deposit-aware store.
module Cardano.Ledger.State.UTxOs (
  UTxOs (..),

  -- * Access
  CanGetUTxOs (..),
  CanSetUTxOs (..),
  utxosUTxO,

  -- * Legacy compatibility
  fromLegacyUTxOs,
  fromLegacyAllocationStorage,
  applyLegacyOutputDelta,

  -- * Serialization
  encodeUTxOs,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.UTxOs.Allocations (unAllocations)
import Cardano.Ledger.State.UTxOs.LegacyUTxOMap (UTxO (..))
import Cardano.Ledger.State.UTxOs.Store
import Cardano.Ledger.State.UTxOs.Store.Error (OutputStoreError)
import Cardano.Ledger.TxIn (TxIn)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..))
import Data.Default (Default (def))
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)
import Lens.Micro (Lens', SimpleGetter)
import NoThunks.Class (NoThunks)

-- | Earlier eras retain their existing UTxO representation and constant-time
-- projection. Dijkstra owns outputs and historical allocations in one store.
data UTxOs era
  = LegacyUTxOMap !(UTxO era)
  | UTxOs !(UTxOStore era)
  deriving (Generic)

-- Access

class CanGetUTxOs t where
  utxosG :: SimpleGetter (t era) (UTxOs era)
  default utxosG ::
    CanSetUTxOs t => SimpleGetter (t era) (UTxOs era)
  utxosG = utxosL
  {-# INLINE utxosG #-}

class CanGetUTxOs t => CanSetUTxOs t where
  utxosL :: Lens' (t era) (UTxOs era)

instance CanGetUTxOs UTxOs

instance CanSetUTxOs UTxOs where
  utxosL = id

utxosUTxO :: UTxOs era -> UTxO era
utxosUTxO (LegacyUTxOMap outputs) = outputs
utxosUTxO (UTxOs store) = toUTxO store

-- Legacy compatibility

-- | Construct storage from outputs whose type proves they use implicit deposits.
-- Earlier eras keep the plain map; Dijkstra uses 'fromLegacyAllocations'.
fromLegacyAllocationStorage ::
  forall era. EraTxOut era => Map.Map TxIn (LegacyTxOut era) -> UTxOs era
fromLegacyAllocationStorage outputs
  | eraProtVerLow @era >= natVersion @12 = UTxOs $ fromLegacyAllocations outputs
  | otherwise = LegacyUTxOMap $ UTxO $ Map.map LegacyTxOut outputs

-- | Initialize or translate outputs known to have legacy implicit deposits.
-- A store-backed output needs historical metadata and is rejected here.
fromLegacyUTxOs ::
  forall era. EraTxOut era => UTxO era -> Either OutputStoreError (UTxOs era)
fromLegacyUTxOs outputs
  | eraProtVerLow @era >= natVersion @12 = UTxOs <$> fromLegacyUTxO outputs
  | otherwise = Right $ LegacyUTxOMap outputs

-- | Apply an explicit legacy-output delta. Existing stored allocations retain
-- their metadata; newly inserted outputs must have implicit deposits.
applyLegacyOutputDelta ::
  EraTxOut era =>
  Set TxIn ->
  UTxO era ->
  UTxOs era ->
  Either OutputStoreError (UTxOs era)
applyLegacyOutputDelta consumed (UTxO created) (LegacyUTxOMap (UTxO previous)) =
  Right $ LegacyUTxOMap $ UTxO $ Map.union created $ Map.withoutKeys previous consumed
applyLegacyOutputDelta consumed created (UTxOs previous) = do
  newStore <- fromLegacyUTxO created
  UTxOs <$> applyAllocationDelta consumed (unAllocations $ allocations newStore) previous

-- Instances

deriving instance (Era era, Eq (TxOut era)) => Eq (UTxOs era)

deriving instance Show (TxOut era) => Show (UTxOs era)

instance (Era era, NFData (TxOut era)) => NFData (UTxOs era)

instance NoThunks (UTxO era) => NoThunks (UTxOs era)

instance Era era => Default (UTxOs era) where
  def
    | eraProtVerLow @era >= natVersion @12 = UTxOs emptyUTxOStore
    | otherwise = LegacyUTxOMap mempty

-- Serialization

instance ToJSON (TxOut era) => ToJSON (UTxOs era) where
  toJSON (LegacyUTxOMap outputs) = toJSON outputs
  toJSON (UTxOs store) = toJSON store

instance EraTxOut era => EncCBOR (UTxOs era) where
  encCBOR (LegacyUTxOMap outputs) = encCBOR outputs
  encCBOR (UTxOs store) = encCBOR store

instance EraTxOut era => DecCBOR (UTxOs era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (UTxOs era) where
  type Share (UTxOs era) = Interns (Credential Staking)
  decShareCBOR credentials
    | eraProtVerLow @era >= natVersion @12 = UTxOs <$> decShareCBOR credentials
    | otherwise = LegacyUTxOMap <$> decShareCBOR credentials

-- | State snapshots preserve the historical pre-Dijkstra MemPack map bytes.
-- Dijkstra's store codec explicitly persists its cached total and allocations.
encodeUTxOs :: EraTxOut era => UTxOs era -> Encoding
encodeUTxOs (LegacyUTxOMap (UTxO outputs)) = encodeMap encodeMemPack encodeMemPack outputs
encodeUTxOs (UTxOs store) = encodeUTxOStore store
