{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Unspent outputs and the metadata retained for their deposit calculation.
module Cardano.Ledger.State.Accounting.UTxOs.Unspent (
  Unspent (..),
  toTxOut,
  depositAmount,
  encodeWith,
  fromLegacyTxOut,
) where

import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (..),
  Decoder,
  EncCBOR (..),
  Encoding,
  Sized (..),
  decodeRecordNamed,
  encodeListLen,
  mkSized,
 )
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core.Era (eraProtVerLow)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  ByteSize (..),
  DepositCalculation,
  calculateDeposit,
  legacyDepositCalculation,
 )
import Cardano.Ledger.TxOut (EraTxOut (..), TxOut (..))
import Control.DeepSeq (NFData)
import Control.Monad (when)
import Data.Aeson (ToJSON (..), object, (.=))
import GHC.Generics (Generic)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- | An unspent value retaining its FULL accepted output size and the deposit
-- calculation chosen at creation. Construction does not re-encode the output.
-- The wrapped TxOut determines whether its deposit is separately held.
data Unspent output = Unspent
  { sizedOutput :: !(Sized output)
  , depositCalculation :: !DepositCalculation
  }
  deriving (Eq, Show, Generic)

-- | Import an output from a legacy format that did not store deposit metadata.
-- The canonical size and zero-rate calculation are compatibility values; they
-- are never used to reconstruct a store-backed output's historical deposit.
fromLegacyTxOut :: forall era. EraTxOut era => LegacyTxOut era -> Unspent (TxOut era)
fromLegacyTxOut output =
  let sized = mkSized (eraProtVerLow @era) . LegacyTxOut $ output
   in sizedSize sized `seq`
        Unspent {sizedOutput = sized, depositCalculation = legacyDepositCalculation}

toTxOut :: Unspent (TxOut era) -> TxOut era
toTxOut = sizedValue . sizedOutput

depositAmount :: Unspent (TxOut era) -> Coin
depositAmount (Unspent (Sized output size) calculation) =
  case output of
    LegacyTxOut _ -> mempty
    NewTxOut _ -> calculateDeposit calculation $ ByteSize size

instance NFData a => NFData (Unspent a)

deriving via
  InspectHeapNamed "Unspent" (Unspent a)
  instance
    NoThunks (Unspent a)

instance ToJSON a => ToJSON (Unspent a) where
  toJSON (Unspent (Sized output size) calculation) =
    object
      [ "output" .= output
      , "acceptedSize" .= size
      , "calculation" .= calculation
      ]

instance EncCBOR a => EncCBOR (Unspent a) where
  encCBOR = encodeWith encCBOR

instance DecCBOR a => DecCBOR (Unspent a) where
  decCBOR = decodeUnspent decCBOR

instance DecShareCBOR a => DecShareCBOR (Unspent a) where
  type Share (Unspent a) = Share a
  decShareCBOR sharing = decodeUnspent $ decShareCBOR sharing

-- Preserve the recorded size explicitly: Sized's ordinary codec recalculates it.
decodeUnspent :: Decoder s a -> Decoder s (Unspent a)
decodeUnspent decodeOutput = decodeRecordNamed "Unspent" (const 3) $ do
  output <- decodeOutput
  size <- decCBOR
  when (size < 0) $ fail $ "Unspent: negative output size " <> show size
  Unspent (Sized output size) <$> decCBOR

encodeWith :: (a -> Encoding) -> Unspent a -> Encoding
encodeWith encodeOutput (Unspent (Sized output size) calculation) =
  encodeListLen 3
    <> encodeOutput output
    <> encCBOR size
    <> encCBOR calculation
