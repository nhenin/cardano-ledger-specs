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

module Cardano.Ledger.State.OutputStorage (
  OutputStorage (..),
  CanGetOutputStorage (..),
  CanSetOutputStorage (..),
  outputStorageUTxO,
  outputStorageTotalDeposit,
  outputStorageDepositStore,
  outputStorageDepositStoreForInputs,
  fromLegacyOutputStorage,
  fromLegacyAllocationStorage,
  applyLegacyOutputDelta,
  encodeOutputStorage,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.DepositStore (DepositStore (..))
import Cardano.Ledger.State.InMemoryUnspentTxOutputStore
import Cardano.Ledger.State.UTxO (UTxO (..))
import Cardano.Ledger.TxIn (TxIn)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..))
import Data.Default (Default (..))
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)
import Lens.Micro (Lens', SimpleGetter)
import NoThunks.Class (NoThunks)

-- | Earlier eras retain their existing UTxO representation and constant-time
-- projection. Dijkstra owns outputs and historical allocations in one store.
data OutputStorage era
  = LegacyOutputs !(UTxO era)
  | StoredOutputs !(InMemoryUnspentTxOutputStore era)
  deriving (Generic)

deriving instance (Era era, Eq (TxOut era)) => Eq (OutputStorage era)

deriving instance Show (TxOut era) => Show (OutputStorage era)

instance (Era era, NFData (TxOut era)) => NFData (OutputStorage era)

instance NoThunks (UTxO era) => NoThunks (OutputStorage era)

instance Era era => Default (OutputStorage era) where
  def
    | eraProtVerLow @era >= natVersion @12 = StoredOutputs emptyInMemoryOutputStore
    | otherwise = LegacyOutputs mempty

class CanGetOutputStorage t where
  outputStorageG :: SimpleGetter (t era) (OutputStorage era)
  default outputStorageG :: CanSetOutputStorage t => SimpleGetter (t era) (OutputStorage era)
  outputStorageG = outputStorageL
  {-# INLINE outputStorageG #-}

class CanGetOutputStorage t => CanSetOutputStorage t where
  outputStorageL :: Lens' (t era) (OutputStorage era)

instance CanGetOutputStorage OutputStorage

instance CanSetOutputStorage OutputStorage where
  outputStorageL = id

outputStorageUTxO :: OutputStorage era -> UTxO era
outputStorageUTxO (LegacyOutputs outputs) = outputs
outputStorageUTxO (StoredOutputs store) = storeUTxO store

-- | The separately held deposit total; application ADA remains in the outputs.
outputStorageTotalDeposit :: OutputStorage era -> Coin
outputStorageTotalDeposit (LegacyOutputs _) = Coin 0
outputStorageTotalDeposit (StoredOutputs store) = unInMemoryOutputDepositAmount $ totalDepositAmount store

-- | A checked, read-only compatibility view. Unknown calculation versions must
-- never be interpreted with current parameters or another version's formula.
outputStorageDepositStore :: OutputStorage era -> Either OutputStoreError DepositStore
outputStorageDepositStore (LegacyOutputs _) = Right $ DepositStore mempty
outputStorageDepositStore (StoredOutputs store) = DepositStore <$> allocationDeposits store

-- | Restrict the compatibility view before evaluating historical deposits.
-- Transaction validation only needs the references it can actually consume.
outputStorageDepositStoreForInputs ::
  Set TxIn -> OutputStorage era -> Either OutputStoreError DepositStore
outputStorageDepositStoreForInputs _ (LegacyOutputs _) = Right $ DepositStore mempty
outputStorageDepositStoreForInputs inputs (StoredOutputs store) =
  DepositStore <$> allocationDepositsForInputs inputs store

-- | Construct storage from outputs whose type proves they use implicit deposits.
-- This is total and does not assign a price to any output.
fromLegacyAllocationStorage ::
  forall era. Era era => Map.Map TxIn (ImplicitDepositTxOut era) -> OutputStorage era
fromLegacyAllocationStorage outputs
  | eraProtVerLow @era >= natVersion @12 = StoredOutputs $ fromLegacyAllocations outputs
  | otherwise = LegacyOutputs $ UTxO $ Map.map ImplicitDepositTxOut outputs

-- | Initialize or translate outputs known to have legacy implicit deposits.
-- A store-backed output needs historical metadata and is rejected here.
fromLegacyOutputStorage ::
  forall era. Era era => UTxO era -> Either OutputStoreError (OutputStorage era)
fromLegacyOutputStorage outputs
  | eraProtVerLow @era >= natVersion @12 = StoredOutputs <$> fromLegacyUTxO outputs
  | otherwise = Right $ LegacyOutputs outputs

-- | Apply an explicit legacy-output delta. Existing stored allocations retain
-- their metadata; newly inserted outputs must have implicit deposits.
applyLegacyOutputDelta ::
  Set TxIn -> UTxO era -> OutputStorage era -> Either OutputStoreError (OutputStorage era)
applyLegacyOutputDelta consumed (UTxO created) (LegacyOutputs (UTxO previous)) =
  Right $ LegacyOutputs $ UTxO $ Map.union created $ Map.withoutKeys previous consumed
applyLegacyOutputDelta consumed created (StoredOutputs previous) = do
  newStore <- fromLegacyUTxO created
  StoredOutputs <$> applyAllocationDelta consumed (unAllocations $ allocations newStore) previous

instance ToJSON (TxOut era) => ToJSON (OutputStorage era) where
  toJSON (LegacyOutputs outputs) = toJSON outputs
  toJSON (StoredOutputs store) = toJSON store

instance EraTxOut era => EncCBOR (OutputStorage era) where
  encCBOR (LegacyOutputs outputs) = encCBOR outputs
  encCBOR (StoredOutputs store) = encCBOR store

instance EraTxOut era => DecCBOR (OutputStorage era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (OutputStorage era) where
  type Share (OutputStorage era) = Interns (Credential Staking)
  decShareCBOR credentials
    | eraProtVerLow @era >= natVersion @12 = StoredOutputs <$> decShareCBOR credentials
    | otherwise = LegacyOutputs <$> decShareCBOR credentials

-- | State snapshots preserve the historical pre-Dijkstra MemPack map bytes.
-- Dijkstra's store codec explicitly persists its cached total and allocations.
encodeOutputStorage :: EraTxOut era => OutputStorage era -> Encoding
encodeOutputStorage (LegacyOutputs (UTxO outputs)) = encodeMap encodeMemPack encodeMemPack outputs
encodeOutputStorage (StoredOutputs store) = encodeInMemoryOutputStore store
