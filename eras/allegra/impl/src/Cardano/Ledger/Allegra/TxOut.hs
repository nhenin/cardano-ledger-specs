{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Allegra.TxOut () where

import Cardano.Ledger.Allegra.Era (AllegraEra)
import Cardano.Ledger.Allegra.PParams ()
import Cardano.Ledger.Binary (DecCBOR (..), DecShareCBOR (..), EncCBOR (..), Interns)
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Shelley.TxOut (
  ShelleyTxOut (..),
  addrEitherShelleyTxOutL,
  valueEitherShelleyTxOutL,
 )
import Control.DeepSeq (NFData (rnf))
import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Coerce (coerce)
import Data.Function (on)
import Data.MemPack (MemPack (..))
import Lens.Micro (lens, (^.))
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

instance EraTxOut AllegraEra where
  type LegacyTxOut AllegraEra = ShelleyTxOut AllegraEra
  type NewTxOut AllegraEra = NoNewTxOut AllegraEra

  upgradeTxOut (LegacyTxOut (TxOutCompact addr cfval)) =
    LegacyTxOut $ TxOutCompact (coerce addr) cfval

  addrEitherTxOutL =
    lens allegraTxOut (const LegacyTxOut) . addrEitherShelleyTxOutL
  {-# INLINE addrEitherTxOutL #-}

instance EraLegacyTxOut AllegraEra where
  mkBasicLegacyTxOut = ShelleyTxOut

  valueEitherTxOutL = valueEitherShelleyTxOutL
  {-# INLINE valueEitherTxOutL #-}

  getMinCoinTxOut pp _txOut = pp ^. ppMinUTxOValueL

instance EraNewTxOut AllegraEra where
  mkBasicNewTxOut = notSupportedInThisEra

  applicationAssetsTxOutL _ unavailable = case unavailable of {}

-- | Private: recover the historical representation from Allegra's only supported variant.
allegraTxOut :: TxOut AllegraEra -> ShelleyTxOut AllegraEra
allegraTxOut (LegacyTxOut output) = output
{-# INLINE allegraTxOut #-}

-- The wrapper retains the historical instances and encodings without a variant tag.
instance Eq (TxOut AllegraEra) where
  (==) = (==) `on` allegraTxOut

instance Ord (TxOut AllegraEra) where
  compare = compare `on` allegraTxOut

instance Show (TxOut AllegraEra) where
  showsPrec precedence = showsPrec precedence . allegraTxOut

instance NFData (TxOut AllegraEra) where
  rnf = rnf . allegraTxOut

deriving via InspectHeapNamed "TxOut" (TxOut AllegraEra) instance NoThunks (TxOut AllegraEra)

instance EncCBOR (TxOut AllegraEra) where
  encCBOR = encCBOR . allegraTxOut

instance DecCBOR (TxOut AllegraEra) where
  decCBOR = LegacyTxOut <$> decCBOR

instance DecShareCBOR (TxOut AllegraEra) where
  type Share (TxOut AllegraEra) = Interns (Credential Staking)
  decShareCBOR = fmap LegacyTxOut . decShareCBOR

instance MemPack (TxOut AllegraEra) where
  packedByteCount = packedByteCount . allegraTxOut
  packM = packM . allegraTxOut
  unpackM = LegacyTxOut <$> unpackM

instance ToJSON (TxOut AllegraEra) where
  toJSON = toJSON . allegraTxOut
  toEncoding = toEncoding . allegraTxOut

instance FromJSON (TxOut AllegraEra) where
  parseJSON = fmap LegacyTxOut . parseJSON
