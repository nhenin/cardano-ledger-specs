{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Accepted outputs together with the immutable inputs to their deposit calculation.
-- Checked construction, updates and decoding maintain the cached deposit total.
module Cardano.Ledger.State.UTxOs.Store (
  -- * Model
  UTxOStore (totalDepositAmount, allocations),

  -- * Construction
  emptyUTxOStore,
  fromAllocations,

  -- * Updates
  allocate,
  release,

  -- * Legacy compatibility
  fromLegacyTxOutMap,
  fromLegacyAllocations,
  translateLegacyStore,
  applyLegacyOutputDelta,

  -- * Serialization
  encodeUTxOStore,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (CompactCoin))
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.UTxOs.Allocations (Allocations (..))
import qualified Cardano.Ledger.State.UTxOs.Allocations as Allocations
import Cardano.Ledger.State.UTxOs.Allocations.UTxO (Unspent (..))
import qualified Cardano.Ledger.State.UTxOs.Allocations.UTxO as UTxO
import Cardano.Ledger.State.UTxOs.Deposit
import Cardano.Ledger.State.UTxOs.Store.Error
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val ((<->))
import Control.DeepSeq (NFData (..))
import Control.Monad (unless, when)
import Data.Aeson (ToJSON (..), ToJSON1 (liftToJSON), object, (.=))
import Data.Default (Default (def))
import Data.Foldable (traverse_)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- Model

data UTxOStore era = UTxOStore
  { totalDepositAmount :: !DepositAmount
  , allocations :: !(Allocations era)
  }

-- Operations

emptyUTxOStore :: UTxOStore era
emptyUTxOStore =
  UTxOStore
    { totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = Allocations {unAllocations = Map.empty}
    }

-- | Construct a Store from complete entries and derive its deposit total.
fromAllocations :: Allocations era -> Either OutputStoreError (UTxOStore era)
fromAllocations entries = allocate entries emptyUTxOStore

-- Check externally supplied metadata before it becomes part of a Store.
-- Reading deposits from an accepted Store requires no validation.
validateAcceptedSizes :: Allocations era -> Either OutputStoreError ()
validateAcceptedSizes = traverse_ validateSize . unAllocations
  where
    validateSize entry =
      let size = sizedSize $ sizedOutput entry
       in when (size < 0) $ Left $ NegativeOutputSize size

-- | Insert complete allocations and add their deposits to the total.
-- Existing entries at the same inputs are replaced: their deposits are released
-- before the new amounts are added. Unaffected historical metadata is retained.
allocate ::
  Allocations era ->
  UTxOStore era ->
  Either OutputStoreError (UTxOStore era)
allocate newAllocations previousStore = do
  validateAcceptedSizes newAllocations
  let retainedStore = release (Map.keysSet . unAllocations $ newAllocations) previousStore
      allocatedDepositAmount = toCoin . Allocations.sumDepositAmounts $ newAllocations
  pure $
    retainedStore
      { totalDepositAmount =
          DepositAmount {toCoin = (toCoin . totalDepositAmount $ retainedStore) <> allocatedDepositAmount}
      , allocations =
          Allocations $
            Map.union (unAllocations newAllocations) (unAllocations . allocations $ retainedStore)
      }

-- | Remove the selected allocations and subtract their historical deposits.
-- Inputs absent from the Store have no effect; retained entries are unchanged.
release :: Set TxIn -> UTxOStore era -> UTxOStore era
release inputs previousStore =
  case Allocations.extractInputs inputs (allocations previousStore) of
    (remainingAllocations, releasedAllocations) ->
      previousStore
        { totalDepositAmount =
            DepositAmount
              { toCoin =
                  (toCoin . totalDepositAmount $ previousStore)
                    <-> (toCoin . Allocations.sumDepositAmounts $ releasedAllocations)
              }
        , allocations = remainingAllocations
        }

-- Legacy compatibility

-- | Replace legacy outputs while retaining the metadata of every unaffected entry.
-- Newly inserted outputs must use implicit deposits.
applyLegacyOutputDelta ::
  EraTxOut era =>
  Set TxIn ->
  TxOutMap era ->
  UTxOStore era ->
  Either OutputStoreError (UTxOStore era)
applyLegacyOutputDelta consumed created previous = do
  newStore <- fromLegacyTxOutMap created
  allocate (allocations newStore) . release consumed $ previous

-- | This conversion is only for legacy outputs. It cannot reconstruct the
-- accepted size or historical rate of an existing store-backed output.
fromLegacyTxOutMap :: EraTxOut era => TxOutMap era -> Either OutputStoreError (UTxOStore era)
fromLegacyTxOutMap (TxOutMap outputs) =
  fromLegacyAllocations <$> Map.traverseWithKey requireLegacyOutput outputs
  where
    requireLegacyOutput input = \case
      LegacyTxOut output -> Right output
      NewTxOut _ -> Left $ MissingHistoricalAllocation input

-- | Import legacy output payloads without historical deposit metadata.
-- Re-encoded size and V1 with a zero rate are NOT historical pricing inputs.
-- Legacy outputs contribute zero to the Store regardless of this metadata.
-- Outputs accepted in Dijkstra construct 'Unspent' directly, preserving
-- their actual accepted size and the calculation in force at creation.
fromLegacyAllocations :: forall era. EraTxOut era => Map TxIn (LegacyTxOut era) -> UTxOStore era
fromLegacyAllocations outputs =
  UTxOStore
    { totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = Allocations {unAllocations = Map.map legacyOutput outputs}
    }

-- | Translate legacy entries using the era's output conversion. The callback
-- must produce legacy outputs. As with legacy decoding, the target size is
-- canonical and the deposit rate is zero; neither is historical pricing metadata.
-- This operation is for legacy-era transitions, not existing Dijkstra allocations.
translateLegacyStore ::
  EraTxOut target =>
  (TxOut source -> LegacyTxOut target) ->
  UTxOStore source ->
  UTxOStore target
translateLegacyStore translateOutput store =
  UTxOStore
    { totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations =
        Allocations . Allocations.mapTxOuts (legacyOutput . translateOutput) . allocations $ store
    }

legacyOutput :: forall era. EraTxOut era => LegacyTxOut era -> Unspent (TxOut era)
legacyOutput output =
  let sized = mkSized (eraProtVerLow @era) . LegacyTxOut $ output
   in sizedSize sized `seq`
        Unspent
          { sizedOutput = sized
          , depositCalculation = DepositCalculationV1 . CoinPerByte . CompactCoin $ 0
          }

-- Instances

instance Default (UTxOStore era) where
  def = emptyUTxOStore

deriving instance Eq (TxOut era) => Eq (UTxOStore era)

deriving instance Show (TxOut era) => Show (UTxOStore era)

instance NFData (TxOut era) => NFData (UTxOStore era) where
  rnf store = rnf (totalDepositAmount store) `seq` rnf (allocations store)

deriving via
  InspectHeapNamed "UTxOStore" (UTxOStore era)
  instance
    NoThunks (UTxOStore era)

-- Serialization

instance (Era era, ToJSON (TxOut era)) => ToJSON (UTxOStore era) where
  toJSON store
    | eraProtVerLow @era < natVersion @12 =
        liftToJSON
          (omitField . UTxO.toTxOut)
          (toJSON . UTxO.toTxOut)
          (toJSONList . map UTxO.toTxOut)
          (unAllocations . allocations $ store)
    | otherwise =
        object ["totalDepositAmount" .= totalDepositAmount store, "allocations" .= allocations store]

instance EraTxOut era => EncCBOR (UTxOStore era) where
  encCBOR store
    | eraProtVerLow @era < natVersion @12 =
        encodeMap encCBOR (encCBOR . UTxO.toTxOut) . unAllocations . allocations $ store
    | otherwise = encodeStoreWith encCBOR encCBOR store

instance EraTxOut era => DecCBOR (UTxOStore era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (UTxOStore era) where
  type Share (UTxOStore era) = Interns (Credential Staking)
  decShareCBOR credentials
    | eraProtVerLow @era < natVersion @12 = do
        outputs <- decShareCBOR credentials
        either (fail . show) pure $ fromLegacyTxOutMap outputs
    | otherwise = decodeRecordNamed "UTxOStore" (const 2) $ do
        supplied <- Coin <$> decCBOR
        entries <- decodeMap decNoShareCBOR (decShareCBOR credentials)
        store <- either (fail . show) pure . fromAllocations $ Allocations entries
        let expected = toCoin $ totalDepositAmount store
        unless (supplied == expected) $
          fail $
            "UTxOStore deposit total mismatch: supplied " <> show supplied <> ", expected " <> show expected
        pure store

instance EraTxOut era => ToCBOR (UTxOStore era) where
  toCBOR = toEraCBOR @era

instance EraTxOut era => FromCBOR (UTxOStore era) where
  fromCBOR = fromEraCBOR @era

-- | Ledger snapshots retain the usual MemPack output representation and encode
-- the original charged size separately. The ordinary Sized codec discards it.
encodeUTxOStore :: forall era. EraTxOut era => UTxOStore era -> Encoding
encodeUTxOStore store
  | eraProtVerLow @era < natVersion @12 =
      encodeMap encodeMemPack (encodeMemPack . UTxO.toTxOut) . unAllocations . allocations $ store
  | otherwise = encodeStoreWith encodeMemPack encodeMemPack store

encodeStoreWith ::
  (TxIn -> Encoding) ->
  (TxOut era -> Encoding) ->
  UTxOStore era ->
  Encoding
encodeStoreWith encodeInput encodeOutput store =
  encodeListLen 2
    <> encCBOR (toCoin $ totalDepositAmount store)
    <> encodeMap encodeInput (UTxO.encodeWith encodeOutput) (unAllocations $ allocations store)
