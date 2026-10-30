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

-- | Active pricing and accepted outputs with immutable historical calculations.
-- Construction and updates maintain the cached deposit total; decoding checks it.
module Cardano.Ledger.State.Accounting.UTxOs.Store (
  -- * Model
  UTxOStore (currentCalculation, totalDepositAmount, allocations),

  -- * Construction
  emptyUTxOStore,
  mkUTxOStore,

  -- * Updates
  activateNewCalculation,
  update,
  allocate,
  release,

  -- * Legacy compatibility
  fromLegacyAllocations,
  translateLegacyStore,

  -- * Serialization
  encodeUTxOStore,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Core (EraTxBody (..), outputsTxBody)
import Cardano.Ledger.Core.Era
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Hashes (KeyRole (Staking))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.State.Accounting.UTxOs.Unspent (Unspent (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.TxOut (EraTxOut (..), TxOut (..))
import Cardano.Ledger.TxOut.IndexedTxOs (IndexedTxOs)
import qualified Cardano.Ledger.TxOut.IndexedTxOs as IndexedTxOs
import Cardano.Ledger.Val ((<->))
import Control.DeepSeq (NFData (..))
import Control.Monad (unless)
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Default (Default (def))
import Data.Map.Strict (Map)
import Data.Set (Set)
import Lens.Micro ((^.))
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- Model

data UTxOStore era = UTxOStore
  { currentCalculation :: !DepositCalculation
  , totalDepositAmount :: !DepositAmount
  , allocations :: !(IndexedUTxOs era)
  }

-- Operations

-- | Start an empty Store with the calculation to record on future allocations.
emptyUTxOStore :: DepositCalculation -> UTxOStore era
emptyUTxOStore calculation =
  UTxOStore
    { currentCalculation = calculation
    , totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = mempty
    }

-- | Restore complete historical entries with an explicit current calculation.
-- Derive the total without replacing any entry's recorded size or calculation.
mkUTxOStore :: DepositCalculation -> IndexedUTxOs era -> UTxOStore era
mkUTxOStore calculation entries =
  UTxOStore
    { currentCalculation = calculation
    , totalDepositAmount = IndexedUTxOs.sumDepositAmounts entries
    , allocations = entries
    }

-- | Select the calculation for future allocations. Existing records and their
-- deposits remain unchanged, including when the Store is empty.
activateNewCalculation :: DepositCalculation -> UTxOStore era -> UTxOStore era
activateNewCalculation calculation store = store {currentCalculation = calculation}

-- | Apply one body's regular input and output changes on the successful path.
-- The ledger chooses the execution path and applies each SubTx separately.
-- New outputs record the current calculation; releases use the stored entries.
-- Earlier eras retain existing entries on key collisions, matching their
-- original output-map union. Dijkstra uses 'allocate' replacement semantics.
update :: forall era l. EraTxBody era => TxBody l era -> UTxOStore era -> UTxOStore era
update body previousStore =
  let remainingStore = release (body ^. inputsTxBodyL) previousStore
      proposedOutputs = outputsTxBody body
      created =
        if eraProtVerLow @era < natVersion @12
          then
            IndexedTxOs.withoutInputs
              (IndexedUTxOs.inputIds . allocations $ remainingStore)
              proposedOutputs
          else proposedOutputs
   in allocate created remainingStore

-- | Accept proposed outputs, recording their sizes and the current calculation.
-- Earlier eras use canonical legacy metadata to match their payload-only state
-- format. Dijkstra retains the supplied size and calculation for both forms.
-- A replacement releases the previous entry's deposit before adding the new one.
allocate ::
  forall era.
  EraTxOut era =>
  IndexedTxOs era ->
  UTxOStore era ->
  UTxOStore era
allocate proposedOutputs previousStore =
  let calculation = currentCalculation previousStore
      newAllocations =
        IndexedUTxOs.fromList
          [ ( input
            , case (eraProtVerLow @era < natVersion @12, sizedValue output) of
                (True, LegacyTxOut legacy) -> Unspent.fromLegacyTxOut legacy
                _ -> Unspent {sizedOutput = output, depositCalculation = calculation}
            )
          | (input, output) <- IndexedTxOs.toList proposedOutputs
          ]
      retainedStore = release (IndexedTxOs.inputIds proposedOutputs) previousStore
      allocatedDepositAmount = toCoin . IndexedUTxOs.sumDepositAmounts $ newAllocations
   in retainedStore
        { totalDepositAmount =
            DepositAmount {toCoin = (toCoin . totalDepositAmount $ retainedStore) <> allocatedDepositAmount}
        , allocations = newAllocations <> allocations retainedStore
        }

-- | Remove the selected allocations and subtract their historical deposits.
-- Inputs absent from the Store have no effect; retained entries are unchanged.
release :: Set TxIn -> UTxOStore era -> UTxOStore era
release inputs previousStore =
  case IndexedUTxOs.extractInputs inputs (allocations previousStore) of
    (remainingAllocations, releasedAllocations) ->
      previousStore
        { totalDepositAmount =
            DepositAmount
              { toCoin =
                  (toCoin . totalDepositAmount $ previousStore)
                    <-> (toCoin . IndexedUTxOs.sumDepositAmounts $ releasedAllocations)
              }
        , allocations = remainingAllocations
        }

-- Legacy compatibility

-- | Import legacy output payloads without historical deposit metadata.
-- Re-encoded size and V1 with a zero rate are NOT historical pricing inputs.
-- Legacy outputs contribute zero to the Store regardless of this metadata.
-- Outputs accepted in Dijkstra construct 'Unspent' directly, preserving
-- their actual accepted size and the calculation in force at creation.
fromLegacyAllocations :: forall era. EraTxOut era => Map TxIn (LegacyTxOut era) -> UTxOStore era
fromLegacyAllocations outputs =
  UTxOStore
    { currentCalculation = legacyDepositCalculation
    , totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = IndexedUTxOs.fromLegacyTxOuts outputs
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
    { currentCalculation = legacyDepositCalculation
    , totalDepositAmount = DepositAmount {toCoin = mempty}
    , allocations = IndexedUTxOs.translateLegacyOutputs translateOutput . allocations $ store
    }

-- Instances

instance Default (UTxOStore era) where
  def = emptyUTxOStore legacyDepositCalculation

deriving instance Eq (TxOut era) => Eq (UTxOStore era)

deriving instance Show (TxOut era) => Show (UTxOStore era)

instance NFData (TxOut era) => NFData (UTxOStore era) where
  rnf store =
    rnf (currentCalculation store) `seq`
      rnf (totalDepositAmount store) `seq`
        rnf (allocations store)

deriving via
  InspectHeapNamed "UTxOStore" (UTxOStore era)
  instance
    NoThunks (UTxOStore era)

-- Serialization

instance (Era era, ToJSON (TxOut era)) => ToJSON (UTxOStore era) where
  toJSON store
    | eraProtVerLow @era < natVersion @12 = toJSON . allocations $ store
    | otherwise =
        object
          [ "currentCalculation" .= currentCalculation store
          , "totalDepositAmount" .= totalDepositAmount store
          , "allocations" .= allocations store
          ]

instance EraTxOut era => EncCBOR (UTxOStore era) where
  encCBOR = encodeStoreWith encCBOR encCBOR

instance EraTxOut era => DecCBOR (UTxOStore era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (UTxOStore era) where
  type Share (UTxOStore era) = Interns (Credential Staking)
  decShareCBOR credentials
    | eraProtVerLow @era < natVersion @12 =
        mkUTxOStore legacyDepositCalculation <$> decShareCBOR credentials
    | otherwise = decodeRecordNamed "UTxOStore" (const 3) $ do
        calculation <- decCBOR
        supplied <- Coin <$> decCBOR
        entries <- decShareCBOR credentials
        let store = mkUTxOStore calculation entries
            expected = toCoin $ totalDepositAmount store
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
encodeUTxOStore = encodeStoreWith encodeMemPack encodeMemPack

encodeStoreWith ::
  forall era.
  Era era =>
  (TxIn -> Encoding) ->
  (TxOut era -> Encoding) ->
  UTxOStore era ->
  Encoding
encodeStoreWith encodeInput encodeOutput store
  | eraProtVerLow @era < natVersion @12 = encodeEntries
  | otherwise =
      encodeListLen 3
        <> encCBOR (currentCalculation store)
        <> encCBOR (toCoin $ totalDepositAmount store)
        <> encodeEntries
  where
    encodeEntries = IndexedUTxOs.encodeWith encodeInput encodeOutput . allocations $ store
