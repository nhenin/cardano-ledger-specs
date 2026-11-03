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

-- | Store representation, instances and operations used by ledger transitions.
-- Use the public Store module for transaction projection and ordinary access.
module Cardano.Ledger.State.Accounting.UTxOs.Store.Internals (
  -- * Model
  UTxOStore (..),
  TxProjected (..),

  -- * Body projections
  projectValidTxBody,
  projectInvalidTxBody,

  -- * Allocation changes
  allocate,
  release,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Core (
  EraTxBody (..),
  TxLevel (TopTx),
  collateralOutputsTxBody,
  outputsTxBody,
 )
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
import Data.Set (Set)
import Lens.Micro ((^.))
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- Model

data UTxOStore era = UTxOStore
  { currentCalculation :: !DepositCalculation
  , totalDepositAmount :: !DepositAmount
  , allocations :: !(IndexedUTxOs era)
  }

-- | Result of projecting one transaction body into the Store. Produced outputs
-- are newly inserted entries; retained collisions are excluded. This result is
-- not a ledger-admission verdict or an emitted event containing the whole Store.
data TxProjected era = TxProjected
  { updatedStore :: !(UTxOStore era)
  , consumedOutputs :: !(IndexedUTxOs era)
  , producedOutputs :: !(IndexedUTxOs era)
  }

-- Operations

-- | Apply one body's regular input and output changes on the successful path.
-- The ledger chooses the execution path and applies each SubTx separately.
-- New outputs record the current calculation; releases use the stored entries.
-- Retained entries take priority on key collisions in every era, matching the
-- original output-map union.
projectValidTxBody :: EraTxBody era => TxBody l era -> UTxOStore era -> TxProjected era
projectValidTxBody body = project (body ^. inputsTxBodyL) (outputsTxBody body)

-- | On phase-2 failure, release this body's collateral inputs and allocate its
-- collateral return. Entries outside that input set remain untouched, and regular
-- outputs are not allocated. Retained entries take priority on key collisions.
projectInvalidTxBody :: EraTxBody era => TxBody TopTx era -> UTxOStore era -> TxProjected era
projectInvalidTxBody body = project (body ^. collateralInputsTxBodyG) (collateralOutputsTxBody body)

-- | Project the selected inputs and proposed outputs, reporting only real changes.
-- Inspect proposed references in the remaining Store to exclude retained entries.
project :: EraTxOut era => Set TxIn -> IndexedTxOs era -> UTxOStore era -> TxProjected era
project inputs proposedOutputs previousStore =
  let remainingStore = release inputs previousStore
      store = allocate proposedOutputs remainingStore
      proposedOutputIds = IndexedTxOs.inputIds proposedOutputs
      retained = IndexedUTxOs.restrictToInputs proposedOutputIds . allocations $ remainingStore
   in TxProjected
        { updatedStore = store
        , consumedOutputs = IndexedUTxOs.restrictToInputs inputs . allocations $ previousStore
        , producedOutputs =
            IndexedUTxOs.withoutInputs (IndexedUTxOs.inputIds retained)
              . IndexedUTxOs.restrictToInputs proposedOutputIds
              . allocations
              $ store
        }

-- | Allocate proposed outputs only at unoccupied references, recording their
-- sizes and the current calculation. Existing entries and deposits are unchanged;
-- a reference must be released before it can be allocated again.
-- Earlier eras use canonical legacy metadata to match their payload-only state
-- format. Dijkstra retains the supplied size and calculation for both forms.
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
            , case (isBeforeDijkstra @era, sizedValue output) of
                (True, LegacyTxOut legacy) -> Unspent.fromLegacyTxOut legacy
                _ -> Unspent {sizedOutput = output, depositCalculation = calculation}
            )
          | (input, output) <- IndexedTxOs.toList proposedOutputs
          , not . IndexedUTxOs.member input . allocations $ previousStore
          ]
      allocatedDepositAmount = toCoin . IndexedUTxOs.sumDepositAmounts $ newAllocations
   in previousStore
        { totalDepositAmount =
            DepositAmount {toCoin = (toCoin . totalDepositAmount $ previousStore) <> allocatedDepositAmount}
        , allocations = allocations previousStore <> newAllocations
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

-- Instances

instance Default (UTxOStore era) where
  def =
    UTxOStore
      { currentCalculation = legacyDepositCalculation
      , totalDepositAmount = DepositAmount {toCoin = mempty}
      , allocations = mempty
      }

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
    | isBeforeDijkstra @era = toJSON . allocations $ store
    | otherwise =
        object
          [ "currentCalculation" .= currentCalculation store
          , "totalDepositAmount" .= totalDepositAmount store
          , "allocations" .= allocations store
          ]

-- Store CBOR uses the snapshot format: MemPack inputs and output payloads,
-- with accepted sizes and historical calculations retained for Dijkstra.
-- IndexedUTxOs keeps its ordinary CBOR encoding for queries.
instance EraTxOut era => EncCBOR (UTxOStore era) where
  encCBOR = encodeStoreWith encodeMemPack encodeMemPack

instance EraTxOut era => DecCBOR (UTxOStore era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (UTxOStore era) where
  type Share (UTxOStore era) = Interns (Credential Staking)
  decShareCBOR credentials
    | isBeforeDijkstra @era = do
        entries <- decShareCBOR credentials
        pure
          UTxOStore
            { currentCalculation = legacyDepositCalculation
            , totalDepositAmount = IndexedUTxOs.sumDepositAmounts entries
            , allocations = entries
            }
    | otherwise = decodeRecordNamed "UTxOStore" (const 3) $ do
        calculation <- decCBOR
        supplied <- Coin <$> decCBOR
        entries <- decShareCBOR credentials
        let total = IndexedUTxOs.sumDepositAmounts entries
            expected = toCoin total
        unless (supplied == expected) $
          fail $
            "UTxOStore deposit total mismatch: supplied " <> show supplied <> ", expected " <> show expected
        pure
          UTxOStore
            { currentCalculation = calculation
            , totalDepositAmount = total
            , allocations = entries
            }

instance EraTxOut era => ToCBOR (UTxOStore era) where
  toCBOR = toEraCBOR @era

instance EraTxOut era => FromCBOR (UTxOStore era) where
  fromCBOR = fromEraCBOR @era

encodeStoreWith ::
  forall era.
  Era era =>
  (TxIn -> Encoding) ->
  (TxOut era -> Encoding) ->
  UTxOStore era ->
  Encoding
encodeStoreWith encodeInput encodeOutput store
  | isBeforeDijkstra @era = encodeEntries
  | otherwise =
      encodeListLen 3
        <> encCBOR (currentCalculation store)
        <> encCBOR (toCoin $ totalDepositAmount store)
        <> encodeEntries
  where
    encodeEntries = IndexedUTxOs.encodeWith encodeInput encodeOutput . allocations $ store
