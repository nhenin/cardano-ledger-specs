{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-redundant-constraints #-}

module Cardano.Ledger.Shelley.API.ByronTranslation (
  translateToShelleyLedgerState,
  translateToShelleyLedgerStateFromUtxo,

  -- * Exported for testing purposes
  translateCompactTxOutByronToShelley,
  translateTxIdByronToShelley,
) where

import qualified Cardano.Chain.Block as Byron
import qualified Cardano.Chain.Common as Byron
import qualified Cardano.Chain.UTxO as Byron
import qualified Cardano.Crypto.Hash as Crypto
import qualified Cardano.Crypto.Hashing as Hashing
import Cardano.Ledger.Address (fromBoostrapCompactAddress, isBootstrapRedeemer)
import Cardano.Ledger.BaseTypes (BlocksMade (..), EpochNo, TxIx (..))
import Cardano.Ledger.Coin (CompactForm (CompactCoin))
import Cardano.Ledger.Hashes (unsafeMakeSafeHash)
import Cardano.Ledger.Shelley (ShelleyEra)
import Cardano.Ledger.Shelley.API.Types
import Cardano.Ledger.Shelley.Core
import Cardano.Ledger.Shelley.LedgerState.Types (curPParamsEpochStateL, prevPParamsEpochStateL)
import Cardano.Ledger.Shelley.Rules ()
import Cardano.Ledger.Shelley.State
import Cardano.Ledger.Shelley.Translation (FromByronTranslationContext (..))
import qualified Cardano.Ledger.State.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.UTxOs.Store as Store
import Cardano.Ledger.TxOut (sumAllCoin)
import Cardano.Ledger.Val (zero, (<->))
import qualified Data.ByteString.Short as SBS
import Data.Default (def)
import qualified Data.Map.Strict as Map
import GHC.Stack (HasCallStack)
import Lens.Micro ((&), (.~), (^.))
import Lens.Micro.Extras (view)

-- | We use the same hashing algorithm so we can unwrap and rewrap the bytes.
-- We don't care about the type that is hashed, which will differ going from
-- Byron to Shelley, we just use the hashes as IDs.
translateTxIdByronToShelley ::
  Byron.TxId ->
  TxId
translateTxIdByronToShelley =
  TxId . unsafeMakeSafeHash . hashFromShortBytesE . Hashing.abstractHashToShort

hashFromShortBytesE ::
  forall h a.
  (Crypto.HashAlgorithm h, HasCallStack) =>
  SBS.ShortByteString ->
  Crypto.Hash h a
hashFromShortBytesE sbs =
  case Crypto.hashFromBytesShort sbs of
    Just !h -> h
    Nothing ->
      error $ "hashFromBytesShort called with ShortByteString of the wrong length: " <> show sbs

translateCompactTxOutByronToShelley :: Byron.CompactTxOut -> ShelleyTxOut ShelleyEra
translateCompactTxOutByronToShelley (Byron.CompactTxOut compactAddr amount) =
  TxOutCompact
    (fromBoostrapCompactAddress compactAddr)
    (CompactCoin (Byron.unsafeGetLovelace amount))

translateCompactTxInByronToShelley ::
  Byron.CompactTxIn ->
  TxIn
translateCompactTxInByronToShelley (Byron.CompactTxInUtxo compactTxId idx) =
  TxIn
    (translateTxIdByronToShelley (Byron.fromCompactTxId compactTxId))
    (TxIx idx)

translateUTxOByronToShelley ::
  Byron.UTxO ->
  IndexedUTxOs ShelleyEra
translateUTxOByronToShelley (Byron.UTxO utxoByron) =
  IndexedUTxOs.fromLegacyTxOuts $
    Map.fromList
      [ (txInShelley, txOutShelley)
      | (txInByron, txOutByron) <- Map.toList utxoByron
      , let txInShelley = translateCompactTxInByronToShelley txInByron
            txOutShelley = translateCompactTxOutByronToShelley txOutByron
      , -- In some testnets there are a few TxOuts with zero values injected at
      -- initialization of Byron. We do not allow zero values in TxOuts in Shelley
      -- onwards.
      LegacyTxOut txOutShelley ^. coinTxOutL /= zero
      ]

translateToShelleyLedgerState ::
  FromByronTranslationContext ->
  EpochNo ->
  Byron.ChainValidationState ->
  NewEpochState ShelleyEra
translateToShelleyLedgerState transContext epochNo cvs =
  translateToShelleyLedgerStateFromUtxo transContext epochNo (Byron.cvsUtxo cvs)

translateToShelleyLedgerStateFromUtxo ::
  FromByronTranslationContext ->
  EpochNo ->
  Byron.UTxO ->
  NewEpochState ShelleyEra
translateToShelleyLedgerStateFromUtxo transCtxt epochNo utxoByron =
  NewEpochState
    { nesEL = epochNo
    , nesBprev = BlocksMade Map.empty
    , nesBcur = BlocksMade Map.empty
    , nesEs = epochState
    , nesRu = SNothing
    , -- At this point, we compute the stashed AVVM addresses, while we are able
      -- to do a linear scan of the UTxO, and stash them away for use at the
      -- Shelley/Allegra boundary.
      stashedAVVMAddresses =
        let storedAllocations =
              Store.allocations . utxosUTxOStore . lsUTxOState . esLState $ epochState
            redeemers =
              IndexedUTxOs.filterByTxOut
                (maybe False isBootstrapRedeemer . view bootAddrTxOutF)
                storedAllocations
         in redeemers
    }
  where
    pparams :: PParams ShelleyEra
    pparams = fbtcProtocolParams transCtxt

    -- NOTE: we ignore the Byron delegation map because the genesis and
    -- delegation verification keys are hashed using a different hashing
    -- scheme. This means we can't simply convert them, as Byron nowhere stores
    -- the original verification keys.
    --
    -- Fortunately, no Byron genesis delegations have happened yet, and if
    -- they did, we would be aware of them before the hard fork, as we
    -- instigate the hard fork. We just have to make sure that the hard-coded
    -- Shelley genesis contains the same genesis and delegation verification
    -- keys, but hashed with the right algorithm.
    genDelegs :: GenDelegs
    genDelegs = GenDelegs $ fbtcGenDelegs transCtxt

    reserves :: Coin
    reserves =
      word64ToCoin (fbtcMaxLovelaceSupply transCtxt) <-> (sumAllCoin . IndexedUTxOs.txOuts $ utxoShelley)

    epochState :: EpochState ShelleyEra
    epochState =
      EpochState
        { esChainAccountState =
            ChainAccountState
              { casTreasury = Coin 0
              , casReserves = reserves
              }
        , esSnapshots = emptySnapShots
        , esLState = ledgerState
        , esNonMyopic = def
        }
        & prevPParamsEpochStateL .~ pparams
        & curPParamsEpochStateL .~ pparams

    utxoShelley :: IndexedUTxOs ShelleyEra
    utxoShelley = translateUTxOByronToShelley utxoByron

    ledgerState :: LedgerState ShelleyEra
    ledgerState =
      LedgerState
        { lsUTxOState =
            UTxOState
              { utxosUTxOStore = fromAllocations legacyDepositCalculation utxoShelley
              , utxosDeposited = Coin 0
              , utxosFees = Coin 0
              , utxosGovState = emptyGovState
              , utxosInstantStake = mempty
              , utxosDonation = mempty
              }
        , lsCertState = mkShelleyCertState def dState
        }

    dState :: DState ShelleyEra
    dState =
      DState
        { dsAccounts = def
        , dsFutureGenDelegs = Map.empty
        , dsGenDelegs = genDelegs
        , dsIRewards = def
        }
