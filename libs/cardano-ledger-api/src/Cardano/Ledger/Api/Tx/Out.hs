{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE ExplicitNamespaces #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | This module is used for building and inspecting transaction outputs.
--
-- You'll find some examples below.
--
-- Let's start by defining the GHC extensions and imports.
--
-- >>> :set -XTypeApplications
-- >>> import Cardano.Ledger.Api.Era (BabbageEra)
-- >>> import Lens.Micro
-- >>> import Test.Cardano.Ledger.Babbage.Arbitrary() -- Needed for doctests only
-- >>> import Test.QuickCheck -- Needed for doctests only
--
-- Here's an example on how to build a very basic Babbage era transaction output with a random
-- address and value, and without any datum or reference script.
--
-- >>> :{
-- quickCheck $ \addr val ->
--     case mkBasicTxOutWithImplicitDeposit @BabbageEra addr val of
--         txOut@(ImplicitDepositTxOut output) ->
--             txOut ^. addrTxOutL == addr && output ^. valueTxOutL == val
--         StoreBackedTxOut _ -> False
-- :}
-- +++ OK, passed 100 tests.
module Cardano.Ledger.Api.Tx.Out (
  module Cardano.Ledger.Api.Tx.Address,
  TxOut (..),
  EraTxOut,
  mkBasicTxOutWithImplicitDeposit,
  mkBasicTxOutWithStoreBackedDeposit,
  upgradeTxOut,

  -- * Any Era
  AnyEraTxOut (..),

  -- ** Value
  coinTxOutL,
  isAdaOnlyTxOutF,

  -- ** Address
  addrTxOutL,
  bootAddrTxOutF,

  -- * Implicit-deposit outputs
  EraImplicitDepositTxOut,
  type ImplicitDepositTxOut,
  mkBasicImplicitDepositTxOut,
  valueTxOutL,

  -- ** Minimum coin
  getMinCoinTxOut,
  setMinCoinTxOut,
  getMinCoinSizedTxOut,
  setMinCoinSizedTxOut,
  ensureMinCoinTxOut,
  ensureMinCoinSizedTxOut,

  -- * Store-backed outputs
  EraStoreBackedTxOut,
  type StoreBackedTxOut,
  mkBasicStoreBackedTxOut,
  ApplicationAssets (..),
  applicationAssetsTxOutL,

  -- * Shelley, Allegra and Mary Era

  -- * Alonzo Era
  AlonzoEraTxOut,
  dataHashTxOutL,
  DataHash,
  datumTxOutF,

  -- * Babbage Era
  BabbageEraTxOut,
  dataTxOutL,
  Data (..),
  datumTxOutL,
  Datum (..),
  referenceScriptTxOutL,
) where

import Cardano.Ledger.Alonzo.Core (AlonzoEraTxOut (..))
import Cardano.Ledger.Api.Era
import Cardano.Ledger.Api.Scripts (AnyEraScript, Script)
import Cardano.Ledger.Api.Scripts.Data (Data (..), DataHash, Datum (..))
import Cardano.Ledger.Api.Tx.Address
import Cardano.Ledger.Babbage.Core (BabbageEraTxOut (..))
import Cardano.Ledger.BaseTypes (strictMaybeToMaybe)
import Cardano.Ledger.Binary
import Cardano.Ledger.Coin
import Cardano.Ledger.Core (
  ApplicationAssets (..),
  EraImplicitDepositTxOut (..),
  EraStoreBackedTxOut (..),
  EraTxOut (..),
  PParams,
  TxOut (..),
  bootAddrTxOutF,
  coinTxOutL,
  isAdaOnlyTxOutF,
  mkBasicTxOutWithImplicitDeposit,
  mkBasicTxOutWithStoreBackedDeposit,
 )
import Cardano.Ledger.Tools (ensureMinCoinTxOut, setMinCoinTxOut)
import Cardano.Ledger.Val (coin, modifyCoin)
import Lens.Micro

class (EraTxOut era, AnyEraScript era) => AnyEraTxOut era where
  datumTxOutG :: SimpleGetter (TxOut era) (Maybe (Datum era))
  default datumTxOutG ::
    AlonzoEraTxOut era =>
    SimpleGetter (TxOut era) (Maybe (Datum era))
  datumTxOutG = datumTxOutF . to Just

  referenceScriptTxOutG :: SimpleGetter (TxOut era) (Maybe (Maybe (Script era)))
  default referenceScriptTxOutG ::
    BabbageEraTxOut era =>
    SimpleGetter (TxOut era) (Maybe (Maybe (Script era)))
  referenceScriptTxOutG = referenceScriptTxOutL . to (Just . strictMaybeToMaybe)

instance AnyEraTxOut ShelleyEra where
  datumTxOutG = to (const Nothing)
  referenceScriptTxOutG = to (const Nothing)

instance AnyEraTxOut AllegraEra where
  datumTxOutG = to (const Nothing)
  referenceScriptTxOutG = to (const Nothing)

instance AnyEraTxOut MaryEra where
  datumTxOutG = to (const Nothing)
  referenceScriptTxOutG = to (const Nothing)

instance AnyEraTxOut AlonzoEra where
  referenceScriptTxOutG = to (const Nothing)

instance AnyEraTxOut BabbageEra

instance AnyEraTxOut ConwayEra

instance AnyEraTxOut DijkstraEra

-- | Private. Adjust an implicit deposit while keeping the cached size current.
setMinCoinSizedTxOutInternal ::
  forall era.
  EraImplicitDepositTxOut era =>
  (Coin -> Coin -> Bool) ->
  PParams era ->
  Sized (ImplicitDepositTxOut era) ->
  Sized (ImplicitDepositTxOut era)
setMinCoinSizedTxOutInternal f pp = go
  where
    version = eraProtVerLow @era
    go !txOut =
      let curMinCoin = getMinCoinSizedTxOut pp txOut
          curCoin = coin (txOut ^. toSizedL version valueTxOutL)
       in if curCoin `f` curMinCoin
            then txOut
            else go (txOut & toSizedL version valueTxOutL %~ modifyCoin (const curMinCoin))

-- | This function will adjust an implicit-deposit output's `Coin` value to the smallest amount
-- allowed by the UTXO rule. Initial amount is not important.
setMinCoinSizedTxOut ::
  forall era.
  EraImplicitDepositTxOut era =>
  PParams era ->
  Sized (ImplicitDepositTxOut era) ->
  Sized (ImplicitDepositTxOut era)
setMinCoinSizedTxOut = setMinCoinSizedTxOutInternal (==)

-- | Similar to `setMinCoinSizedTxOut` it will guarantee that the minimum requirement for the
-- output amount is satisified, however it makes it possible to set a higher amount than
-- the minimaly required.
--
-- `ensureMinCoinSizedTxOut` relates to `setMinCoinSizedTxOut` in the same way that
-- `ensureMinCoinTxOut` relates to `setMinCoinTxOut`.
ensureMinCoinSizedTxOut ::
  forall era.
  EraImplicitDepositTxOut era =>
  PParams era ->
  Sized (ImplicitDepositTxOut era) ->
  Sized (ImplicitDepositTxOut era)
ensureMinCoinSizedTxOut = setMinCoinSizedTxOutInternal (>=)
