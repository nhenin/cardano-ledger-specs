{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Sized outputs indexed by their references, without deposit history.
module Cardano.Ledger.TxOut.IndexedTxOs (
  -- * Model
  IndexedTxOs (..),

  -- * Construction
  singleton,
  fromList,

  -- * Inspection
  inputIds,
  member,
  null,
  size,
  toList,
  sizedOutputs,
  txOuts,
  mapTxOuts,

  -- * Selection
  restrictToInputs,
  withoutInputs,
  filterByTxOut,
) where

import Cardano.Ledger.Binary (Sized (..))
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.TxOut (TxOut)
import Control.DeepSeq (NFData (..))
import Data.Default (Default)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)
import Prelude hiding (null)

-- | Proposed outputs or an explicit output-only view of accepted entries.
-- Retain their original sizes without claiming historical deposit calculations.
newtype IndexedTxOs era = IndexedTxOs
  { unIndexedTxOs :: Map TxIn (Sized (TxOut era))
  }
  deriving (Default, Generic, Semigroup, Monoid)

singleton :: TxIn -> Sized (TxOut era) -> IndexedTxOs era
singleton input = IndexedTxOs . Map.singleton input

-- | Index sized outputs. The last output wins when an input is repeated.
fromList :: [(TxIn, Sized (TxOut era))] -> IndexedTxOs era
fromList = IndexedTxOs . Map.fromList

inputIds :: IndexedTxOs era -> Set TxIn
inputIds = Map.keysSet . unIndexedTxOs

member :: TxIn -> IndexedTxOs era -> Bool
member input = Map.member input . unIndexedTxOs

null :: IndexedTxOs era -> Bool
null = Map.null . unIndexedTxOs

size :: IndexedTxOs era -> Int
size = Map.size . unIndexedTxOs

-- | Read references and sized outputs in ascending reference order.
toList :: IndexedTxOs era -> [(TxIn, Sized (TxOut era))]
toList = Map.toList . unIndexedTxOs

sizedOutputs :: IndexedTxOs era -> [Sized (TxOut era)]
sizedOutputs = Map.elems . unIndexedTxOs

-- | Inspect output payloads without constructing another indexed collection.
txOuts :: IndexedTxOs era -> [TxOut era]
txOuts = map sizedValue . sizedOutputs

-- | Project payloads for an external result or diagnostic keyed by reference.
mapTxOuts :: (TxOut era -> output) -> IndexedTxOs era -> Map TxIn output
mapTxOuts transform = Map.map (transform . sizedValue) . unIndexedTxOs

-- | Select output references without recomputing their supplied sizes.
restrictToInputs :: Set TxIn -> IndexedTxOs era -> IndexedTxOs era
restrictToInputs inputs = IndexedTxOs . (`Map.restrictKeys` inputs) . unIndexedTxOs

withoutInputs :: Set TxIn -> IndexedTxOs era -> IndexedTxOs era
withoutInputs inputs = IndexedTxOs . (`Map.withoutKeys` inputs) . unIndexedTxOs

filterByTxOut :: (TxOut era -> Bool) -> IndexedTxOs era -> IndexedTxOs era
filterByTxOut predicate = IndexedTxOs . Map.filter (predicate . sizedValue) . unIndexedTxOs

deriving instance Eq (TxOut era) => Eq (IndexedTxOs era)

deriving instance Show (TxOut era) => Show (IndexedTxOs era)

instance NFData (TxOut era) => NFData (IndexedTxOs era) where
  rnf = rnf . unIndexedTxOs

deriving via InspectHeapNamed "IndexedTxOs" (IndexedTxOs era) instance NoThunks (IndexedTxOs era)
