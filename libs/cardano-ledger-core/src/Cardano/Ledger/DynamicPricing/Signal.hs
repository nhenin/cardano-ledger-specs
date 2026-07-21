{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}

-- | The controller's utilisation signals (the CIP's construction): each lane
-- reads its demand over a window of recent samples, not from the latest
-- block alone. A sample records what one sample-carrying block delivered
-- against the capacity it was measured over, in bytes and execution units;
-- a window's utilisation is the larger of the two summed ratios.
module Cardano.Ledger.DynamicPricing.Signal (
  Sample (..),
  SignalWindow (..),
  PricingSignals (..),
  emptySignalWindow,
  emptyPricingSignals,
  pushSample,
  windowUtilisation,
  urgentSignalWindowLength,
  standardSignalWindowLength,
) where

import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Cardano.Ledger.Binary.Coders (
  Decode (..),
  Encode (..),
  decode,
  encode,
  (!>),
  (<!),
 )
import Cardano.Ledger.DynamicPricing.Controller (Utilisation (..))
import Cardano.Ledger.Plutus.ExUnits (ExUnits (..))
import Control.DeepSeq (NFData)
import Data.Ratio ((%))
import Data.Sequence.Strict (StrictSeq)
import qualified Data.Sequence.Strict as SSeq
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | One sample-carrying block's contribution to a lane's signal: usage
-- against the capacity it was measured over. The urgent lane measures a
-- certified endorser block against the RESERVATION capacity (a ranking
-- block's), never the endorser block's own — the sample asks how many
-- ranking blocks' worth of urgent traffic the block carried.
data Sample = Sample
  { sampleBytes :: !Integer
  , sampleByteCapacity :: !Integer
  , sampleExUnits :: !ExUnits
  , sampleExUnitsCapacity :: !ExUnits
  }
  deriving stock (Eq, Show, Generic)

instance NoThunks Sample

instance NFData Sample

instance EncCBOR Sample where
  encCBOR (Sample b bc e ec) =
    encode $ Rec Sample !> To b !> To bc !> To e !> To ec

instance DecCBOR Sample where
  decCBOR = decode $ RecD Sample <! From <! From <! From <! From

-- | A lane's most recent samples, newest first, trimmed to the lane's
-- window length by 'pushSample'.
newtype SignalWindow = SignalWindow {windowSamples :: StrictSeq Sample}
  deriving stock (Eq, Show, Generic)

instance NoThunks SignalWindow

instance NFData SignalWindow

instance EncCBOR SignalWindow where
  encCBOR (SignalWindow samples) = encCBOR samples

instance DecCBOR SignalWindow where
  decCBOR = SignalWindow <$> decCBOR

emptySignalWindow :: SignalWindow
emptySignalWindow = SignalWindow mempty

-- | The two lanes' windows, carried in the pricing state and rolled forward
-- by every sample-carrying reprice.
data PricingSignals = PricingSignals
  { urgentWindow :: !SignalWindow
  , standardWindow :: !SignalWindow
  }
  deriving stock (Eq, Show, Generic)

instance NoThunks PricingSignals

instance NFData PricingSignals

instance EncCBOR PricingSignals where
  encCBOR (PricingSignals uw sw) =
    encode $ Rec PricingSignals !> To uw !> To sw

instance DecCBOR PricingSignals where
  decCBOR = decode $ RecD PricingSignals <! From <! From

emptyPricingSignals :: PricingSignals
emptyPricingSignals = PricingSignals emptySignalWindow emptySignalWindow

-- | The CIP's window lengths: a short reservation window for the urgent
-- lane, a longer capacity-weighted one for the standard lane. Eventually
-- protocol parameters; constants for the prototype.
urgentSignalWindowLength :: Int
urgentSignalWindowLength = 5

standardSignalWindowLength :: Int
standardSignalWindowLength = 20

-- | Append the newest sample and trim to the window length.
pushSample :: Int -> Sample -> SignalWindow -> SignalWindow
pushSample keep sample (SignalWindow samples) =
  SignalWindow (SSeq.take keep (sample SSeq.<| samples))

-- | The window's utilisation: summed usage over summed capacity, bytes and
-- execution units separately, whichever ratio is larger (the CIP's rule).
-- 'Nothing' while the window is empty — at genesis the price holds rather
-- than reading silence as an empty lane.
windowUtilisation :: SignalWindow -> Maybe Utilisation
windowUtilisation (SignalWindow samples)
  | SSeq.null samples = Nothing
  | otherwise = Just . Utilisation $ maximum [byteRatio, memRatio, stepsRatio]
  where
    total f = sum (fmap f samples)
    ratio used capacity
      | capacity <= 0 = 0
      | otherwise = used % capacity
    byteRatio = ratio (total sampleBytes) (total sampleByteCapacity)
    memRatio =
      ratio
        (total (toInteger . exUnitsMem . sampleExUnits))
        (total (toInteger . exUnitsMem . sampleExUnitsCapacity))
    stepsRatio =
      ratio
        (total (toInteger . exUnitsSteps . sampleExUnits))
        (total (toInteger . exUnitsSteps . sampleExUnitsCapacity))
