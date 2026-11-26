{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

-- | Coin amounts whose checked construction and decoding preserve the strictly
-- positive unsigned 64-bit range.
module Cardano.Ledger.StrictlyPositiveCoin (
  StrictlyPositiveCoin,
  mkStrictlyPositiveCoin,
  unStrictlyPositiveCoin,
) where

import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR)
import Cardano.Ledger.Coin (Coin (..), decodePositiveCoin)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON (..), ToJSON)
import Data.Word (Word64)
import NoThunks.Class (NoThunks)

-- | A strictly positive coin amount within the CBOR 'Coin' range.
-- Construct with 'mkStrictlyPositiveCoin'; the constructor is private to preserve the invariant.
newtype StrictlyPositiveCoin = StrictlyPositiveCoin Coin
  deriving newtype (Eq, Ord, Show, NFData, NoThunks, EncCBOR, ToJSON)

-- | Reject zero, negative amounts and amounts exceeding the unsigned 64-bit range.
mkStrictlyPositiveCoin :: Coin -> Maybe StrictlyPositiveCoin
mkStrictlyPositiveCoin amount@(Coin value)
  | value > 0 && value <= toInteger (maxBound :: Word64) = Just $ StrictlyPositiveCoin amount
  | otherwise = Nothing

-- | Recover the amount without weakening the construction invariant.
unStrictlyPositiveCoin :: StrictlyPositiveCoin -> Coin
unStrictlyPositiveCoin (StrictlyPositiveCoin amount) = amount

instance DecCBOR StrictlyPositiveCoin where
  decCBOR = StrictlyPositiveCoin <$> decodePositiveCoin "StrictlyPositiveCoin"

instance FromJSON StrictlyPositiveCoin where
  parseJSON value =
    parseJSON value
      >>= maybe (fail "StrictlyPositiveCoin must be between 1 and 18446744073709551615 lovelace") pure
        . mkStrictlyPositiveCoin
