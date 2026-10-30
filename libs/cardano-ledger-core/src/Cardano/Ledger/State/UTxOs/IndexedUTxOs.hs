{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Complete unspent outputs indexed by the inputs that can spend them.
module Cardano.Ledger.State.UTxOs.IndexedUTxOs (
  -- * Model
  IndexedUTxOs (..),

  -- * Construction
  singleton,
  fromList,

  -- * Entries
  inputIds,
  member,
  null,
  size,
  lookupUTxO,
  toList,
  unspentOutputs,

  -- * Selection
  restrictToInputs,
  extractInputs,
  withoutInputs,
  filterByTxOut,

  -- * Output inspection
  toIndexedTxOs,
  txOuts,
  mapTxOuts,

  -- * Deposit amounts
  allocatedDepositTotalAmount,
  sumDepositAmounts,

  -- * Legacy import and translation
  fromLegacyTxOuts,
  translateLegacyOutputs,

  -- * Serialization
  encodeWith,
) where

import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (..),
  EncCBOR (..),
  Encoding,
  FromCBOR (..),
  Interns,
  ToCBOR (..),
  decNoShareCBOR,
  decodeMap,
  encodeMap,
  natVersion,
 )
import Cardano.Ledger.Core.Era (Era, eraProtVerLow, fromEraCBOR, toEraCBOR)
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Hashes (KeyRole (Staking))
import Cardano.Ledger.State.UTxOs.Deposit (DepositAmount (..))
import Cardano.Ledger.State.UTxOs.Unspent (Unspent)
import qualified Cardano.Ledger.State.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.TxOut (EraTxOut (..), TxOut (..))
import Cardano.Ledger.TxOut.IndexedTxOs (IndexedTxOs (..))
import Control.DeepSeq (NFData (..))
import Control.Monad ((<$!>))
import Data.Aeson (ToJSON (..), ToJSON1 (liftToJSON))
import Data.Default (Default)
import Data.Foldable (foldMap')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.MapExtras (extractKeys)
import Data.Set (Set)
import GHC.Generics (Generic)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)
import Prelude hiding (null)

-- | Each indexed entry retains its full output size and deposit calculation.
newtype IndexedUTxOs era = IndexedUTxOs
  { unIndexedUTxOs :: Map TxIn (Unspent (TxOut era))
  }
  deriving (Default, Generic, Semigroup, Monoid)

-- Construction

singleton :: TxIn -> Unspent (TxOut era) -> IndexedUTxOs era
singleton input = IndexedUTxOs . Map.singleton input

-- | Index complete entries. The last entry wins when an input is repeated.
fromList :: [(TxIn, Unspent (TxOut era))] -> IndexedUTxOs era
fromList = IndexedUTxOs . Map.fromList

-- Entries

inputIds :: IndexedUTxOs era -> Set TxIn
inputIds = Map.keysSet . unIndexedUTxOs

member :: TxIn -> IndexedUTxOs era -> Bool
member input = Map.member input . unIndexedUTxOs

null :: IndexedUTxOs era -> Bool
null = Map.null . unIndexedUTxOs

size :: IndexedUTxOs era -> Int
size = Map.size . unIndexedUTxOs

-- | Look up one complete entry. An absent input returns 'Nothing'.
lookupUTxO :: TxIn -> IndexedUTxOs era -> Maybe (Unspent (TxOut era))
lookupUTxO input = Map.lookup input . unIndexedUTxOs

-- | Read input references and complete entries in ascending input order.
toList :: IndexedUTxOs era -> [(TxIn, Unspent (TxOut era))]
toList = Map.toList . unIndexedUTxOs

-- | Read complete entries in ascending input order, retaining their metadata.
unspentOutputs :: IndexedUTxOs era -> [Unspent (TxOut era)]
unspentOutputs = Map.elems . unIndexedUTxOs

-- Selection

-- | Select existing inputs, retaining their accepted sizes and calculations.
-- Unknown inputs are left to the ledger's BadInputs check.
restrictToInputs :: Set TxIn -> IndexedUTxOs era -> IndexedUTxOs era
restrictToInputs inputs = IndexedUTxOs . (`Map.restrictKeys` inputs) . unIndexedUTxOs

-- | Split into (remaining, extracted) complete entries in one traversal.
extractInputs :: Set TxIn -> IndexedUTxOs era -> (IndexedUTxOs era, IndexedUTxOs era)
extractInputs inputs entries =
  case extractKeys (unIndexedUTxOs entries) inputs of
    (remaining, extracted) -> (IndexedUTxOs remaining, IndexedUTxOs extracted)

withoutInputs :: Set TxIn -> IndexedUTxOs era -> IndexedUTxOs era
withoutInputs inputs = IndexedUTxOs . (`Map.withoutKeys` inputs) . unIndexedUTxOs

-- | Inspect output payloads while retaining each selected entry's metadata.
filterByTxOut :: (TxOut era -> Bool) -> IndexedUTxOs era -> IndexedUTxOs era
filterByTxOut predicate = IndexedUTxOs . Map.filter (predicate . Unspent.toTxOut) . unIndexedUTxOs

-- Output inspection

-- | Read selected unspent outputs as sized outputs, without their deposit
-- calculations. The original sizes are retained; the view cannot recover the
-- discarded historical pricing and must not replace accepted Store records.
toIndexedTxOs :: IndexedUTxOs era -> IndexedTxOs era
toIndexedTxOs = IndexedTxOs . Map.map Unspent.sizedOutput . unIndexedUTxOs

-- | Inspect payloads in input order without constructing another collection.
txOuts :: IndexedUTxOs era -> [TxOut era]
txOuts = map Unspent.toTxOut . unspentOutputs

-- | Project payloads for an external result or diagnostic keyed by input.
-- Store reads and updates continue to use complete entries.
mapTxOuts :: (TxOut era -> output) -> IndexedUTxOs era -> Map TxIn output
mapTxOuts transform = Map.map (transform . Unspent.toTxOut) . unIndexedUTxOs

-- Deposit amounts

-- | Sum the recorded deposits released by the selected existing inputs.
allocatedDepositTotalAmount :: Set TxIn -> IndexedUTxOs era -> DepositAmount
allocatedDepositTotalAmount inputs = sumDepositAmounts . restrictToInputs inputs

-- | Sum historical deposits. Legacy outputs contribute zero.
sumDepositAmounts :: IndexedUTxOs era -> DepositAmount
sumDepositAmounts entries =
  DepositAmount {toCoin = foldMap' Unspent.depositAmount . unIndexedUTxOs $ entries}

-- Legacy import and translation

-- | Import typed legacy payloads with canonical compatibility metadata.
fromLegacyTxOuts :: EraTxOut era => Map TxIn (LegacyTxOut era) -> IndexedUTxOs era
fromLegacyTxOuts = IndexedUTxOs . Map.map Unspent.fromLegacyTxOut

-- | Translate legacy entries and reconstruct canonical target-era metadata.
-- This is not a migration for existing store-backed historical records.
translateLegacyOutputs ::
  EraTxOut target =>
  (TxOut source -> LegacyTxOut target) ->
  IndexedUTxOs source ->
  IndexedUTxOs target
translateLegacyOutputs translateOutput =
  IndexedUTxOs . mapTxOuts (Unspent.fromLegacyTxOut . translateOutput)

-- Instances

deriving instance Eq (TxOut era) => Eq (IndexedUTxOs era)

deriving instance Show (TxOut era) => Show (IndexedUTxOs era)

instance NFData (TxOut era) => NFData (IndexedUTxOs era) where
  rnf = rnf . unIndexedUTxOs

deriving via InspectHeapNamed "IndexedUTxOs" (IndexedUTxOs era) instance NoThunks (IndexedUTxOs era)

-- Legacy formats contain payloads only. Dijkstra persists complete entries.
instance (Era era, ToJSON (TxOut era)) => ToJSON (IndexedUTxOs era) where
  toJSON entries
    | eraProtVerLow @era < natVersion @12 =
        liftToJSON
          (omitField . Unspent.toTxOut)
          (toJSON . Unspent.toTxOut)
          (toJSONList . map Unspent.toTxOut)
          (unIndexedUTxOs entries)
    | otherwise = toJSON . unIndexedUTxOs $ entries

instance (Era era, EncCBOR (TxOut era)) => EncCBOR (IndexedUTxOs era) where
  encCBOR = encodeWith encCBOR encCBOR

instance EraTxOut era => DecCBOR (IndexedUTxOs era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (IndexedUTxOs era) where
  type Share (IndexedUTxOs era) = Interns (Credential Staking)
  decShareCBOR credentials
    | eraProtVerLow @era < natVersion @12 =
        fromLegacyTxOuts <$!> decodeMap decNoShareCBOR decodeLegacyOutput
    | otherwise = IndexedUTxOs <$!> decodeMap decNoShareCBOR (decShareCBOR credentials)
    where
      decodeLegacyOutput =
        decShareCBOR credentials >>= \case
          LegacyTxOut output -> pure output
          NewTxOut _ -> fail "IndexedUTxOs: legacy format cannot contain a store-backed output"

instance (Era era, EncCBOR (TxOut era)) => ToCBOR (IndexedUTxOs era) where
  toCBOR = toEraCBOR @era

instance EraTxOut era => FromCBOR (IndexedUTxOs era) where
  fromCBOR = fromEraCBOR @era

-- | Retain the era's collection format while selecting payload encoders.
encodeWith ::
  forall era.
  Era era =>
  (TxIn -> Encoding) ->
  (TxOut era -> Encoding) ->
  IndexedUTxOs era ->
  Encoding
encodeWith encodeInput encodeOutput
  | eraProtVerLow @era < natVersion @12 =
      encodeMap encodeInput (encodeOutput . Unspent.toTxOut) . unIndexedUTxOs
  | otherwise =
      encodeMap encodeInput (Unspent.encodeWith encodeOutput) . unIndexedUTxOs
