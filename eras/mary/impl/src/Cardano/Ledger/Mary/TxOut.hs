{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Mary.TxOut (scaledMinDeposit) where

import Cardano.Ledger.Binary (DecCBOR (..), DecShareCBOR (..), EncCBOR (..), Interns)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Mary.Era (MaryEra)
import Cardano.Ledger.Mary.PParams ()
import Cardano.Ledger.Shelley.TxOut (
  ShelleyTxOut (..),
  addrEitherShelleyTxOutL,
  valueEitherShelleyTxOutL,
 )
import Cardano.Ledger.Val (Val (isAdaOnly, size), injectCompact)
import Control.DeepSeq (NFData (rnf))
import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Coerce (coerce)
import Data.Function (on)
import Data.MemPack (MemPack (..))
import Lens.Micro (lens, (^.))
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

instance EraTxOut MaryEra where
  type ImplicitDepositTxOut MaryEra = ShelleyTxOut MaryEra
  type StoreBackedTxOut MaryEra = NoStoreBackedTxOut MaryEra

  upgradeTxOut (ImplicitDepositTxOut (TxOutCompact addr cfval)) =
    ImplicitDepositTxOut $ TxOutCompact (coerce addr) (injectCompact cfval)

  addrEitherTxOutL =
    lens maryTxOut (const ImplicitDepositTxOut) . addrEitherShelleyTxOutL
  {-# INLINE addrEitherTxOutL #-}

instance EraImplicitDepositTxOut MaryEra where
  mkBasicImplicitDepositTxOut = ShelleyTxOut

  valueEitherTxOutL = valueEitherShelleyTxOutL
  {-# INLINE valueEitherTxOutL #-}

  getMinCoinTxOut pp txOut = scaledMinDeposit (txOut ^. valueTxOutL) (pp ^. ppMinUTxOValueL)

instance EraStoreBackedTxOut MaryEra where
  mkBasicStoreBackedTxOut = notSupportedInThisEra

  applicationAssetsTxOutL _ unavailable = case unavailable of {}

-- | Private: recover the historical representation from Mary's only supported variant.
maryTxOut :: TxOut MaryEra -> ShelleyTxOut MaryEra
maryTxOut (ImplicitDepositTxOut output) = output
{-# INLINE maryTxOut #-}

-- The wrapper retains the historical instances and encodings without a variant tag.
instance Eq (TxOut MaryEra) where
  (==) = (==) `on` maryTxOut

instance Ord (TxOut MaryEra) where
  compare = compare `on` maryTxOut

instance Show (TxOut MaryEra) where
  showsPrec precedence = showsPrec precedence . maryTxOut

instance NFData (TxOut MaryEra) where
  rnf = rnf . maryTxOut

deriving via InspectHeapNamed "TxOut" (TxOut MaryEra) instance NoThunks (TxOut MaryEra)

instance EncCBOR (TxOut MaryEra) where
  encCBOR = encCBOR . maryTxOut

instance DecCBOR (TxOut MaryEra) where
  decCBOR = ImplicitDepositTxOut <$> decCBOR

instance DecShareCBOR (TxOut MaryEra) where
  type Share (TxOut MaryEra) = Interns (Credential Staking)
  decShareCBOR = fmap ImplicitDepositTxOut . decShareCBOR

instance MemPack (TxOut MaryEra) where
  packedByteCount = packedByteCount . maryTxOut
  packM = packM . maryTxOut
  unpackM = ImplicitDepositTxOut <$> unpackM

instance ToJSON (TxOut MaryEra) where
  toJSON = toJSON . maryTxOut
  toEncoding = toEncoding . maryTxOut

instance FromJSON (TxOut MaryEra) where
  parseJSON = fmap ImplicitDepositTxOut . parseJSON

-- | The `scaledMinDeposit` calculation uses the minUTxOValue protocol parameter
-- (passed to it as Coin mv) as a specification of "the cost of making a
-- Shelley-sized UTxO entry", calculated here by "utxoEntrySizeWithoutVal +
-- uint", using the constants in the "where" clause.  In the case when a UTxO
-- entry contains coins only (and the Shelley UTxO entry format is used - we
-- will extend this to be correct for other UTxO formats shortly), the deposit
-- should be exactly the minUTxOValue.  This is the "inject (coin v) == v" case.
-- Otherwise, we calculate the per-byte deposit by multiplying the minimum
-- deposit (which is for the number of Shelley UTxO-entry bytes) by the size of
-- a Shelley UTxO entry.  This is the "(mv * (utxoEntrySizeWithoutVal + uint))"
-- calculation.  We then calculate the total deposit required for making a UTxO
-- entry with a Val-class member v by dividing "(mv * (utxoEntrySizeWithoutVal +
-- uint))" by the estimated total size of the UTxO entry containing v, ie by
-- "(utxoEntrySizeWithoutVal + size v)".  See the formal specification for
-- details.
--
-- This scaling function is right for UTxO, not EUTxO
scaledMinDeposit :: Val v => v -> Coin -> Coin
scaledMinDeposit v (Coin mv)
  | isAdaOnly v = Coin mv -- without non-Coin assets, scaled deposit should be exactly minUTxOValue
  -- The calculation should represent this equation
  -- minValueParameter / coinUTxOSize = actualMinValue / valueUTxOSize
  -- actualMinValue = (minValueParameter / coinUTxOSize) * valueUTxOSize
  | otherwise = Coin $ max mv (coinsPerUTxOWord * (utxoEntrySizeWithoutVal + size v))
  where
    -- lengths obtained from tracing on HeapWords of inputs and outputs
    -- obtained experimentally, and number used here
    -- units are Word64s
    txoutLenNoVal = 14
    txinLen = 7

    -- unpacked CompactCoin Word64 size in Word64s
    coinSize :: Integer
    coinSize = 0

    utxoEntrySizeWithoutVal :: Integer
    utxoEntrySizeWithoutVal = 6 + txoutLenNoVal + txinLen

    -- how much ada does a Word64 of UTxO space cost, calculated from minAdaValue PP
    -- round down
    coinsPerUTxOWord :: Integer
    coinsPerUTxOWord = quot mv (utxoEntrySizeWithoutVal + coinSize)
