{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Unspent outputs indexed by their transaction inputs, with historical deposit metadata.
module Cardano.Ledger.State.UTxOs.Allocations (
  Allocations (..),
  lookupUTxO,
  restrictToInputs,
  unspentOutputs,
  allocatedDepositTotalAmount,
  sumDepositAmounts,
) where

import Cardano.Ledger.Core (TxOut)
import Cardano.Ledger.State.UTxOs.Allocations.UTxO (Unspent)
import qualified Cardano.Ledger.State.UTxOs.Allocations.UTxO as UTxO
import Cardano.Ledger.State.UTxOs.Deposit (DepositAmount (..))
import Cardano.Ledger.TxIn (TxIn)
import Control.DeepSeq (NFData (..))
import Data.Aeson (ToJSON (..))
import Data.Foldable (foldMap')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

newtype Allocations era = Allocations
  { unAllocations :: Map TxIn (Unspent (TxOut era))
  }

lookupUTxO :: TxIn -> Allocations era -> Maybe (Unspent (TxOut era))
lookupUTxO input = Map.lookup input . unAllocations

-- | Select existing inputs, retaining each output's accepted size and historical
-- deposit calculation. Unknown inputs are left to the ledger's BadInputs check.
restrictToInputs :: Set TxIn -> Allocations era -> Allocations era
restrictToInputs inputs = Allocations . (`Map.restrictKeys` inputs) . unAllocations

-- | Read the complete unspent entries without discarding their deposit metadata.
unspentOutputs :: Allocations era -> [Unspent (TxOut era)]
unspentOutputs = Map.elems . unAllocations

-- | Refund using each selected output's recorded calculation and accepted size.
-- Legacy outputs contribute zero; inputs absent from the collection contribute nothing.
allocatedDepositTotalAmount :: Set TxIn -> Allocations era -> DepositAmount
allocatedDepositTotalAmount inputs =
  sumDepositAmounts . restrictToInputs inputs

sumDepositAmounts :: Allocations era -> DepositAmount
sumDepositAmounts entries = DepositAmount {toCoin = foldMap' UTxO.depositAmount $ unAllocations entries}

deriving instance Eq (TxOut era) => Eq (Allocations era)

deriving instance Show (TxOut era) => Show (Allocations era)

instance NFData (TxOut era) => NFData (Allocations era) where
  rnf = rnf . unAllocations

deriving via InspectHeapNamed "Allocations" (Allocations era) instance NoThunks (Allocations era)

instance ToJSON (TxOut era) => ToJSON (Allocations era) where
  toJSON = toJSON . unAllocations
