{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Store access and era-specific transaction queries over accepted allocations.
module Cardano.Ledger.State.UTxOs (
  -- * Store access
  CanGetUTxOStore (..),
  CanSetUTxOStore (..),

  -- * Transaction validation queries
  EraUTxO (..),
  ScriptsProvided (..),
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.CertState (CertState)
import Cardano.Ledger.State.UTxOs.Allocations (Allocations)
import Cardano.Ledger.State.UTxOs.Store (UTxOStore)
import Control.DeepSeq (NFData)
import Data.Kind (Type)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)
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

-- | The only reason it is a newtype instead of just a Map is because for later eras it is
-- expensive to compute the actual map, so we want to use the type safety guidance to
-- avoid redundant work.
newtype ScriptsProvided era = ScriptsProvided
  { unScriptsProvided :: Map.Map ScriptHash (Script era)
  }
  deriving (Generic)

deriving instance (Era era, Eq (Script era)) => Eq (ScriptsProvided era)

deriving instance (Era era, Ord (Script era)) => Ord (ScriptsProvided era)

deriving instance (Era era, Show (Script era)) => Show (ScriptsProvided era)

deriving instance (Era era, NFData (Script era)) => NFData (ScriptsProvided era)

class EraTx era => EraUTxO era where
  -- | A customizable type on per era basis for the information required to find all
  -- scripts needed for the transaction.
  type ScriptsNeeded era = (r :: Type) | r -> era

  -- | Calculate all the value that is being consumed by the transaction.
  getConsumedValue ::
    PParams era ->
    -- | Function that can lookup current delegation deposits
    (Credential Staking -> Maybe Coin) ->
    Allocations era ->
    TxBody t era ->
    Value era

  getProducedValue ::
    PParams era ->
    -- | Check whether a pool with a supplied PoolStakeId is already registered.
    (KeyHash StakePool -> Bool) ->
    TxBody TopTx era ->
    Value era

  -- | Initial eras will look into witness set to find all of the available scripts, but
  -- starting with Babbage we can look for available scripts in accepted allocations using reference
  -- inputs.
  getScriptsProvided ::
    -- | For some era it is necessary to look into accepted allocations to find all of the available
    -- scripts for the transaction
    Allocations era ->
    Tx t era ->
    ScriptsProvided era

  -- | Produce all the information required for figuring out which scripts are required
  -- for the transaction to be valid, once those scripts are evaluated
  getScriptsNeeded :: Allocations era -> TxBody t era -> ScriptsNeeded era

  -- | Extract the set of all script hashes that are needed for script validation.
  getScriptsHashesNeeded :: ScriptsNeeded era -> Set ScriptHash

  -- | Extract all of the KeyHash witnesses that are required for validating the transaction
  getWitsVKeyNeeded ::
    CertState era -> Allocations era -> TxBody t era -> Set (KeyHash Witness)

  -- | Minimum fee computation, excluding witnesses and including ref scripts size
  getMinFeeTxUtxo :: PParams era -> Tx t era -> Allocations era -> Coin
