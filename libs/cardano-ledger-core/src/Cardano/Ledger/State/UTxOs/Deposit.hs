{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Versioned deposit calculations using recorded pricing inputs.
module Cardano.Ledger.State.UTxOs.Deposit (
  DepositCalculation (..),
  DepositAmount (..),
  ByteSize (..),
  calculateDeposit,
) where

import Cardano.Ledger.Binary (
  DecCBOR (..),
  EncCBOR (..),
  decodeRecordSum,
  encodeListLen,
  encodeWord,
 )
import Cardano.Ledger.Coin (Coin (..), CoinPerByte (..), CompactForm (CompactCoin))
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Int (Int64)
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | The separately held deposit total; application ADA remains in the outputs.
newtype DepositAmount = DepositAmount
  { toCoin :: Coin
  }
  deriving (Eq, Ord, Show, Generic, NFData, NoThunks)

instance ToJSON DepositAmount where
  toJSON = toJSON . toCoin

-- | Each version carries the pricing parameters recorded at allocation.
-- V2 provisionally uses the same formula as V1.
data DepositCalculation
  = DepositCalculationV1 !CoinPerByte
  | DepositCalculationV2 !CoinPerByte
  deriving (Eq, Ord, Show, Generic)

-- | An output size measured in bytes. Accepted sizes are validated at insertion
-- and decoding before they are passed to the pricing calculation.
newtype ByteSize = ByteSize
  { unByteSize :: Int64
  }
  deriving (Eq, Ord, Show, Generic)

-- | Deposit = (160 + output bytes) × recorded coins per byte.
-- Integer arithmetic preserves the result even at the Int64 size bound.
calculateDeposit :: DepositCalculation -> ByteSize -> Coin
calculateDeposit calculation (ByteSize size) = case calculation of
  DepositCalculationV1 (CoinPerByte (CompactCoin rate)) ->
    Coin $ (160 + toInteger size) * toInteger rate
  DepositCalculationV2 (CoinPerByte (CompactCoin rate)) ->
    Coin $ (160 + toInteger size) * toInteger rate

instance NFData ByteSize

instance NoThunks ByteSize

instance NFData DepositCalculation

instance NoThunks DepositCalculation

instance ToJSON DepositCalculation where
  toJSON = \case
    DepositCalculationV1 rate -> object ["version" .= (1 :: Word), "coinsPerByte" .= rate]
    DepositCalculationV2 rate -> object ["version" .= (2 :: Word), "coinsPerByte" .= rate]

instance EncCBOR DepositCalculation where
  encCBOR = \case
    DepositCalculationV1 rate -> encodeListLen 2 <> encodeWord 1 <> encCBOR rate
    DepositCalculationV2 rate -> encodeListLen 2 <> encodeWord 2 <> encCBOR rate

instance DecCBOR DepositCalculation where
  decCBOR = decodeRecordSum "DepositCalculation" $ \case
    1 -> do
      rate <- decCBOR
      pure (2, DepositCalculationV1 rate)
    2 -> do
      rate <- decCBOR
      pure (2, DepositCalculationV2 rate)
    version -> fail $ "Unknown DepositCalculation version: " <> show version
