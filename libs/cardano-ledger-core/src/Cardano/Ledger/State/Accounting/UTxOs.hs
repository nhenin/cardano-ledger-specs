{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DefaultSignatures #-}

-- | Access the output store owned by a ledger state.
module Cardano.Ledger.State.Accounting.UTxOs (
  CanGetUTxOStore (..),
  CanSetUTxOStore (..),
) where

import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore)
import Lens.Micro (Lens', SimpleGetter)

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
