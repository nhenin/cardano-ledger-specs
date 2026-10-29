{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DefaultSignatures #-}

-- | Access to the complete unspent-output Store.
module Cardano.Ledger.State.UTxOs (
  CanGetUTxOStore (..),
  CanSetUTxOStore (..),

  -- * Read-only compatibility projection
  utxoG,
) where

import Cardano.Ledger.State.UTxOs.LegacyUTxOMap (UTxO)
import Cardano.Ledger.State.UTxOs.Store (UTxOStore, toUTxO)
import Lens.Micro (Lens', SimpleGetter, to)

class CanGetUTxOStore t where
  utxoStoreG :: SimpleGetter (t era) (UTxOStore era)
  default utxoStoreG :: CanSetUTxOStore t => SimpleGetter (t era) (UTxOStore era)
  utxoStoreG = utxoStoreL
  {-# INLINE utxoStoreG #-}

class CanGetUTxOStore t => CanSetUTxOStore t where
  utxoStoreL :: Lens' (t era) (UTxOStore era)

instance CanGetUTxOStore UTxOStore

instance CanSetUTxOStore UTxOStore where
  utxoStoreL = id

-- | Compatibility view for validators that still consume an output-only map.
-- This projects all allocations; Store queries should read allocations directly.
-- There is deliberately no setter: an output map lacks historical deposit metadata.
utxoG :: CanGetUTxOStore t => SimpleGetter (t era) (UTxO era)
utxoG = utxoStoreG . to toUTxO
{-# INLINE utxoG #-}
