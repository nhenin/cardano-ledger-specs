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

-- | Era-specific transaction queries over accepted unspent outputs.
module Cardano.Ledger.UTxO (
  EraUTxO (..),
  consumedAndProducedValue,
  ScriptsProvided (..),
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore, allocations)
import Cardano.Ledger.State.Certificates (CertState)
import Cardano.Ledger.Val (inject, (<->))
import Control.DeepSeq (NFData)
import Data.Kind (Type)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)

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

  -- | Consumed value before accounting for externally held UTxO deposits.
  getConsumedValue ::
    PParams era ->
    -- | Function that can lookup current delegation deposits
    (Credential Staking -> Maybe Coin) ->
    IndexedUTxOs era ->
    TxBody t era ->
    Value era

  -- | Produced value before accounting for externally held UTxO deposits.
  getProducedValue ::
    PParams era ->
    -- | Check whether a pool with a supplied PoolStakeId is already registered.
    (KeyHash StakePool -> Bool) ->
    TxBody TopTx era ->
    Value era

  -- | Change in externally held deposits on ordinary inputs and outputs of the batch.
  getNetUTxOStoreChange :: UTxOStore era -> TxBody TopTx era -> Coin
  getNetUTxOStoreChange _ _ = mempty

  -- | Initial eras will look into witness set to find all of the available scripts, but
  -- starting with Babbage we can look for available scripts in accepted allocations using reference
  -- inputs.
  getScriptsProvided ::
    -- | For some era it is necessary to look into accepted allocations to find all of the available
    -- scripts for the transaction
    IndexedUTxOs era ->
    Tx t era ->
    ScriptsProvided era

  -- | Produce all the information required for figuring out which scripts are required
  -- for the transaction to be valid, once those scripts are evaluated
  getScriptsNeeded :: IndexedUTxOs era -> TxBody t era -> ScriptsNeeded era

  -- | Extract the set of all script hashes that are needed for script validation.
  getScriptsHashesNeeded :: ScriptsNeeded era -> Set ScriptHash

  -- | Extract all of the KeyHash witnesses that are required for validating the transaction
  getWitsVKeyNeeded ::
    CertState era -> IndexedUTxOs era -> TxBody t era -> Set (KeyHash Witness)

  -- | Minimum fee computation, excluding witnesses and including ref scripts size
  getMinFeeTxUtxo :: PParams era -> Tx t era -> IndexedUTxOs era -> Coin

-- | Financial balance uses the actual Store movement. Embedded reserves already
-- travel with the serialized input and output values.
consumedAndProducedValue ::
  EraUTxO era =>
  PParams era ->
  (Credential Staking -> Maybe Coin) ->
  (KeyHash StakePool -> Bool) ->
  UTxOStore era ->
  TxBody TopTx era ->
  (Value era, Value era)
consumedAndProducedValue pp lookupRefund isRegistered store body =
  let consumed = getConsumedValue pp lookupRefund (allocations store) body
      produced = getProducedValue pp isRegistered body
      change = getNetUTxOStoreChange store body
   in case compare change mempty of
        LT -> (consumed <> inject (mempty <-> change), produced)
        EQ -> (consumed, produced)
        GT -> (consumed, produced <> inject change)
