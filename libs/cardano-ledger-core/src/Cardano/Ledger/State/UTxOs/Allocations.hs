{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Unspent outputs indexed by 'TxIn'. Each entry retains its output,
-- stored size and deposit calculation.
module Cardano.Ledger.State.UTxOs.Allocations (
  -- * Model
  Allocations (..),

  -- * Entries

  -- | Read complete entries, including their historical deposit metadata.
  lookupUTxO,
  unspentOutputs,

  -- * Selection

  -- | Select existing allocations without changing their entries.
  restrictToInputs,
  extractInputs,
  withoutInputs,
  filterByTxOut,

  -- * Collision filtering

  -- | Keep proposed entries only where no allocation already exists.
  excludeAllocatedInputs,

  -- * Output views

  -- | Read output payloads without their stored sizes or deposit calculations.
  txOuts,
  toTxOutMap,
  txOutsForInputs,
  mapTxOuts,

  -- * Deposit amounts

  -- | Sum deposits using each entry's historical size and calculation.
  allocatedDepositTotalAmount,
  sumDepositAmounts,
) where

import Cardano.Ledger.Core (TxOut)
import Cardano.Ledger.State.UTxOs.Allocations.UTxO (Unspent)
import qualified Cardano.Ledger.State.UTxOs.Allocations.UTxO as UTxO
import Cardano.Ledger.State.UTxOs.Deposit (DepositAmount (..))
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.TxOut.Map (TxOutMap (..))
import Control.DeepSeq (NFData (..))
import Data.Aeson (ToJSON (..))
import Data.Foldable (foldMap')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.MapExtras (extractKeys)
import Data.Set (Set)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- Model

-- | Complete accepted entries, keyed by the input that can spend them.
newtype Allocations era = Allocations
  { unAllocations :: Map TxIn (Unspent (TxOut era))
  }

-- Entries

-- | Look up one complete entry. An absent input returns 'Nothing'.
lookupUTxO :: TxIn -> Allocations era -> Maybe (Unspent (TxOut era))
lookupUTxO input = Map.lookup input . unAllocations

-- | Read all complete entries in ascending input order, retaining their metadata.
unspentOutputs :: Allocations era -> [Unspent (TxOut era)]
unspentOutputs = Map.elems . unAllocations

-- Selection

-- | Select existing inputs, retaining each output's accepted size and historical
-- deposit calculation. Unknown inputs are left to the ledger's BadInputs check.
restrictToInputs :: Set TxIn -> Allocations era -> Allocations era
restrictToInputs inputs = Allocations . (`Map.restrictKeys` inputs) . unAllocations

-- | Split into (remaining, extracted) allocations in one traversal. Both
-- collections retain their outputs' accepted sizes and historical calculations.
extractInputs :: Set TxIn -> Allocations era -> (Allocations era, Allocations era)
extractInputs inputs entries =
  case extractKeys (unAllocations entries) inputs of
    (remaining, extracted) -> (Allocations remaining, Allocations extracted)

-- | Exclude inputs while retaining the remaining entries' historical metadata.
withoutInputs :: Set TxIn -> Allocations era -> Allocations era
withoutInputs inputs = Allocations . (`Map.withoutKeys` inputs) . unAllocations

-- | Select entries by their output, retaining each entry's historical metadata.
filterByTxOut :: (TxOut era -> Bool) -> Allocations era -> Allocations era
filterByTxOut predicate = Allocations . Map.filter (predicate . UTxO.toTxOut) . unAllocations

-- Collision filtering

-- | Exclude proposed entries whose inputs are already allocated. This preserves
-- existing-entry precedence without constructing the complete set of inputs.
excludeAllocatedInputs :: Allocations era -> Map TxIn output -> Map TxIn output
excludeAllocatedInputs entries proposed = Map.difference proposed (unAllocations entries)

-- Output views

-- | Read output payloads in input order, without building an intermediate map.
txOuts :: Allocations era -> [TxOut era]
txOuts = map UTxO.toTxOut . unspentOutputs

-- | Read output payloads keyed by input. Historical sizes and calculations remain
-- in the allocations; this view is for APIs that consume only transaction outputs.
toTxOutMap :: Allocations era -> TxOutMap era
toTxOutMap = TxOutMap . mapTxOuts id

-- | Read existing outputs for the requested inputs. Select allocations before
-- projecting them, so unrelated outputs are not traversed. Missing inputs are omitted.
txOutsForInputs :: Set TxIn -> Allocations era -> TxOutMap era
txOutsForInputs inputs = toTxOutMap . restrictToInputs inputs

-- | Transform output payloads in one traversal, preserving their input keys.
-- The result is an output view, not a replacement for the historical allocations.
mapTxOuts :: (TxOut era -> output) -> Allocations era -> Map TxIn output
mapTxOuts transform = Map.map (transform . UTxO.toTxOut) . unAllocations

-- Deposit amounts

-- | Refund using each selected output's recorded calculation and accepted size.
-- Legacy outputs contribute zero; inputs absent from the collection contribute nothing.
allocatedDepositTotalAmount :: Set TxIn -> Allocations era -> DepositAmount
allocatedDepositTotalAmount inputs =
  sumDepositAmounts . restrictToInputs inputs

-- | Sum deposits from every entry's stored size and calculation.
-- Legacy outputs contribute zero; current protocol parameters are not consulted.
sumDepositAmounts :: Allocations era -> DepositAmount
sumDepositAmounts entries = DepositAmount {toCoin = foldMap' UTxO.depositAmount . unAllocations $ entries}

-- Instances

deriving instance Eq (TxOut era) => Eq (Allocations era)

deriving instance Show (TxOut era) => Show (Allocations era)

instance NFData (TxOut era) => NFData (Allocations era) where
  rnf = rnf . unAllocations

deriving via InspectHeapNamed "Allocations" (Allocations era) instance NoThunks (Allocations era)

instance ToJSON (TxOut era) => ToJSON (Allocations era) where
  toJSON = toJSON . unAllocations
