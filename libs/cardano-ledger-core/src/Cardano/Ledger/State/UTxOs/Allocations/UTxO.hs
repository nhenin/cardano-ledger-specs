{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Unspent outputs and the metadata retained for their deposit calculation.
module Cardano.Ledger.State.UTxOs.Allocations.UTxO (
  Unspent (..),
  toTxOut,
  depositAmount,
  encodeWith,
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
 )
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core (TxOut (..))
import Cardano.Ledger.State.UTxOs.Deposit (
  ByteSize (..),
  DepositCalculation,
  calculateDeposit,
 )
import Cardano.Ledger.State.UTxOs.Store.Error (OutputStoreError (NegativeOutputSize))
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
  when (size < 0) $ fail $ show $ NegativeOutputSize size
  calculation <- decCBOR
  pure $ Unspent (Sized output size) calculation

encodeWith :: (a -> Encoding) -> Unspent a -> Encoding
encodeWith encodeOutput (Unspent (Sized output size) calculation) =
  encodeListLen 3
    <> encodeOutput output
    <> encCBOR size
    <> encCBOR calculation
