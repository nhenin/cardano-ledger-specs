{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}

-- | The end-of-block price controller (spec: @updateTiers@, identity there).
--
-- One per-lane EIP-1559 step, taken from Will's mechanism-design doc
-- (@tiered-pricing:docs\/phase-2\/mechanism-design.md@, "Live mechanisms"):
--
-- @
--   price' = price · (1 + clamp((u − target) \/ (target · D), −1\/D, +1\/D))
-- @
--
-- floored at a lower bound. @u@ is the lane's utilisation, @target@ the load
-- the controller aims at, and @D@ the max-change denominator: a single step
-- can never move the price by more than @1\/D@ of its current value (e.g. 25%
-- at @D = 4@, Will's sweep winner). The @±1\/D@ clamp keeps the step
-- symmetric even when @target ≠ 0.5@.
--
-- This module is the controller only: the utilisation signal is computed by
-- the BBODY rule, and the cross-lane price-discrimination floor (16×) is
-- re-imposed by 'Cardano.Ledger.DynamicPricing.Pricing.mkInclusionPrices'
-- after both lanes have stepped.
module Cardano.Ledger.DynamicPricing.Controller (
  -- * The signal and the knobs
  Utilisation (..),
  TargetUtilisation (..),
  MaxChangeDenominator (..),
  ControllerParams (..),

  -- * One controller step
  stepPrice,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.DynamicPricing.Pricing (InclusionPrice (..))
import Data.Ratio ((%))
import GHC.Generics (Generic)

-- | A lane's utilisation over the block(s) the controller reads: bytes
-- delivered as a fraction of the capacity that could carry them. Kept exact
-- (a 'Rational') so the controller is deterministic; never floating point.
newtype Utilisation = Utilisation {unUtilisation :: Rational}
  deriving stock (Eq, Ord, Show, Generic)

-- | The load the controller steers towards. At this utilisation the price
-- does not move. Will's sweep winner uses @1 \% 2@.
newtype TargetUtilisation = TargetUtilisation {unTargetUtilisation :: Rational}
  deriving stock (Eq, Ord, Show, Generic)

-- | The max-change denominator @D@: the largest fractional move one step may
-- make is @1 \/ D@. Will's sweep winner uses @4@ (±25%\/block); the spec doc
-- illustrates with @8@ (±12.5%). Must be @≥ 1@.
newtype MaxChangeDenominator = MaxChangeDenominator {unMaxChangeDenominator :: Int}
  deriving stock (Eq, Ord, Show, Generic)

-- | The controller's calibration: where it aims and how fast it may move.
-- Eventually a protocol parameter; carried explicitly for now.
data ControllerParams = ControllerParams
  { target :: !TargetUtilisation
  , maxChange :: !MaxChangeDenominator
  }
  deriving stock (Eq, Show, Generic)

-- | One end-of-block step for a single lane.
--
-- @stepPrice params lowerBound u price@ moves @price@ towards balancing
-- @u@ against @params.target@, by at most @1 \/ D@ of its current value, then
-- floors the result at @lowerBound@ (the lane's @c = 1@ price, i.e. today's
-- @minFeeA@). The lovelace result is rounded deterministically.
stepPrice ::
  ControllerParams ->
  -- | Lower bound (the lane's floor price; e.g. @minFeeA@).
  InclusionPrice ->
  -- | The lane's utilisation signal for this step.
  Utilisation ->
  -- | The price to move.
  InclusionPrice ->
  InclusionPrice
stepPrice
  (ControllerParams (TargetUtilisation t) (MaxChangeDenominator d))
  lowerBound
  (Utilisation u)
  (InclusionPrice (Coin price)) =
    max lowerBound (InclusionPrice (Coin moved))
    where
      d' = toInteger (max 1 d)
      step = 1 % d'
      signal = (u - t) / (t * fromInteger d')
      move = clamp (negate step) step signal
      moved = round (fromInteger price * (1 + move))

-- | @clamp lo hi@ confines a value to @[lo, hi]@.
clamp :: Ord a => a -> a -> a -> a
clamp lo hi = max lo . min hi
