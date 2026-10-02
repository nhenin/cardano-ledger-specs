{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Conway.TxOut (upgradeBabbageTxOut) where

import Cardano.Ledger.Babbage.Core
import Cardano.Ledger.Babbage.TxOut (
  BabbageTxOut (..),
  addrEitherBabbageTxOutL,
  babbageMinUTxOValue,
  dataBabbageTxOutL,
  dataHashBabbageTxOutL,
  datumBabbageTxOutL,
  getDatumBabbageTxOut,
  referenceScriptBabbageTxOutL,
  valueEitherBabbageTxOutL,
 )
import Cardano.Ledger.Binary (DecCBOR (..), DecShareCBOR (..), EncCBOR (..), Interns)
import Cardano.Ledger.Conway.Era (ConwayEra)
import Cardano.Ledger.Conway.PParams ()
import Cardano.Ledger.Conway.Scripts ()
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Plutus.Data (Datum (..), translateDatum)
import Control.DeepSeq (NFData (..))
import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Coerce (coerce)
import Data.Function (on)
import Data.Maybe.Strict (StrictMaybe (..))
import Data.MemPack (MemPack (..))
import Lens.Micro
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

instance EraTxOut ConwayEra where
  type ImplicitDepositTxOut ConwayEra = BabbageTxOut ConwayEra
  type StoreBackedTxOut ConwayEra = NoStoreBackedTxOut ConwayEra

  upgradeTxOut (ImplicitDepositTxOut output) =
    ImplicitDepositTxOut $ upgradeBabbageTxOut output

  addrEitherTxOutL =
    lens conwayTxOut (const ImplicitDepositTxOut) . addrEitherBabbageTxOutL
  {-# INLINE addrEitherTxOutL #-}

instance EraImplicitDepositTxOut ConwayEra where
  mkBasicImplicitDepositTxOut addr vl = BabbageTxOut addr vl NoDatum SNothing

  valueEitherTxOutL = valueEitherBabbageTxOutL
  {-# INLINE valueEitherTxOutL #-}

  getMinCoinSizedTxOut = babbageMinUTxOValue

instance EraStoreBackedTxOut ConwayEra where
  mkBasicStoreBackedTxOut = notSupportedInThisEra

  applicationAssetsTxOutL _ unavailable = case unavailable of {}

-- | Private: recover the historical representation from Conway's only supported variant.
conwayTxOut :: TxOut ConwayEra -> BabbageTxOut ConwayEra
conwayTxOut (ImplicitDepositTxOut output) = output
{-# INLINE conwayTxOut #-}

-- The wrapper retains the historical instances and encodings without a variant tag.
instance Eq (TxOut ConwayEra) where
  (==) = (==) `on` conwayTxOut

instance Ord (TxOut ConwayEra) where
  compare = compare `on` conwayTxOut

instance Show (TxOut ConwayEra) where
  showsPrec precedence = showsPrec precedence . conwayTxOut

instance NFData (TxOut ConwayEra) where
  rnf = rnf . conwayTxOut

deriving via InspectHeapNamed "TxOut" (TxOut ConwayEra) instance NoThunks (TxOut ConwayEra)

instance EncCBOR (TxOut ConwayEra) where
  encCBOR = encCBOR . conwayTxOut

instance DecCBOR (TxOut ConwayEra) where
  decCBOR = ImplicitDepositTxOut <$> decCBOR

instance DecShareCBOR (TxOut ConwayEra) where
  type Share (TxOut ConwayEra) = Interns (Credential Staking)
  decShareCBOR = fmap ImplicitDepositTxOut . decShareCBOR

instance MemPack (TxOut ConwayEra) where
  packedByteCount = packedByteCount . conwayTxOut
  packM = packM . conwayTxOut
  unpackM = ImplicitDepositTxOut <$> unpackM

instance ToJSON (TxOut ConwayEra) where
  toJSON = toJSON . conwayTxOut
  toEncoding = toEncoding . conwayTxOut

instance FromJSON (TxOut ConwayEra) where
  parseJSON = fmap ImplicitDepositTxOut . parseJSON

instance AlonzoEraTxOut ConwayEra where
  dataHashTxOutL =
    lens conwayTxOut (const ImplicitDepositTxOut) . dataHashBabbageTxOutL
  {-# INLINE dataHashTxOutL #-}

  datumTxOutF = to $ getDatumBabbageTxOut . conwayTxOut
  {-# INLINE datumTxOutF #-}

instance BabbageEraTxOut ConwayEra where
  dataTxOutL =
    lens conwayTxOut (const ImplicitDepositTxOut) . dataBabbageTxOutL
  {-# INLINE dataTxOutL #-}

  datumTxOutL =
    lens conwayTxOut (const ImplicitDepositTxOut) . datumBabbageTxOutL
  {-# INLINE datumTxOutL #-}

  referenceScriptTxOutL =
    lens conwayTxOut (const ImplicitDepositTxOut) . referenceScriptBabbageTxOutL
  {-# INLINE referenceScriptTxOutL #-}

upgradeBabbageTxOut ::
  ( Value era ~ Value (PreviousEra era)
  , EraScript (PreviousEra era)
  , EraScript era
  ) =>
  BabbageTxOut (PreviousEra era) ->
  BabbageTxOut era
upgradeBabbageTxOut = \case
  TxOutCompact' ca cv -> TxOutCompact' ca cv
  TxOutCompactDH' ca cv dh -> TxOutCompactDH' ca cv dh
  TxOutCompactDatum ca cv bd -> TxOutCompactDatum ca cv (coerce bd)
  TxOutCompactRefScript ca cv d s -> TxOutCompactRefScript ca cv (translateDatum d) (upgradeScript s)
  TxOut_AddrHash28_AdaOnly c a28e cc -> TxOut_AddrHash28_AdaOnly c a28e cc
  TxOut_AddrHash28_AdaOnly_DataHash32 c a28e cc dh32 -> TxOut_AddrHash28_AdaOnly_DataHash32 c a28e cc dh32
