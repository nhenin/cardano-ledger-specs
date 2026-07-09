{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}

-- | End-of-block price publication for the dynamic-pricing domain.
--
-- This module is deliberately state-agnostic: it reads the public prices and
-- the current block's usage counters, then computes the next public prices.
-- The era-indexed aggregate in "Cardano.Ledger.DynamicPricing.State" decides
-- where those values live in ledger state.
module Cardano.Ledger.DynamicPricing.Repricing (
  BlockCapacity (..),
  InclusionCapacities (..),
  optimisticBlockCapacity,
  defaultControllerParams,
  repriceBlockUsage,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.DynamicPricing.Controller (
  ControllerParams (..),
  MaxChangeDenominator (..),
  TargetUtilisation (..),
  Utilisation (..),
  stepPrice,
 )
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  InclusionPrices,
  TxSizeInBytes (..),
  mkInclusionPrices,
  optimistic,
  priceDiscriminationFloor,
  urgent,
 )
import Cardano.Ledger.DynamicPricing.Usage (BlockUsage, bytesUsed, usageOf)
import Data.Maybe (fromMaybe)
import Data.Ratio ((%))
import GHC.Generics (Generic)

-- | A block-body capacity the utilisation signal is measured against, in bytes.
newtype BlockCapacity = BlockCapacity {unBlockCapacity :: Integer}
  deriving stock (Eq, Show, Generic)

-- | The block-body capacity each lane's pricing utilisation is measured against
-- — one target per inclusion strategy. Each inclusion steers against its OWN
-- budget with its own fill: the urgent one against the regular block's, the
-- optimistic one against 'optimisticBlockCapacity' (the endorser block's own,
-- much larger, budget). Measuring per lane is what lets the two prices move
-- independently; at realistic traffic the optimistic budget is far from its
-- target, so that price rests at the floor — the mechanism's real behaviour.
data InclusionCapacities = InclusionCapacities
  { urgentCapacity :: !BlockCapacity
  , optimisticCapacity :: !BlockCapacity
  }
  deriving stock (Eq, Show, Generic)

-- | The optimistic inclusion's own block-body budget: the real mainnet
-- calibration (the CIP-164 endorser-block closure-size limit, 12 MB), an
-- absolute budget — unlike the urgent one it is not a protocol-parameter
-- multiple of the regular block. Eventually a protocol parameter; a constant
-- for the prototype.
optimisticBlockCapacity :: BlockCapacity
optimisticBlockCapacity = BlockCapacity 12000000

-- | The controller calibration the ledger runs: Will's sweep winner
-- (@target = 1/2@, @D = 4@, so at most +/-25% per block). Eventually a
-- protocol parameter; a constant for the prototype.
defaultControllerParams :: ControllerParams
defaultControllerParams =
  ControllerParams (TargetUtilisation (1 % 2)) (MaxChangeDenominator 4)

-- | End-of-block repricing (spec: @updateTiers@): one EIP-1559 controller step
-- per lane (Will's mechanism-design doc), republished through
-- 'mkInclusionPrices' so the price-discrimination floor always holds.
--
-- The utilisation signal is capacity-weighted, per lane: each lane's OWN fill
-- against its own pricing target ('InclusionCapacities'). Praos-only steers both
-- against the shared RB, so an urgent flood moves only the urgent price and the
-- optimistic price tracks optimistic demand alone (no aggregate cross-talk).
--
-- Window smoothing over several blocks is deferred (a calibration choice).
repriceBlockUsage ::
  ControllerParams ->
  -- | The lane floor price (today's @minFeeA@; the controller's @c = 1@).
  InclusionPrice ->
  -- | The per-lane block-body capacities to measure utilisation against.
  InclusionCapacities ->
  InclusionPrices ->
  BlockUsage ->
  InclusionPrices
repriceBlockUsage params floorPrice capacities prices usage =
  publishFloored steppedUrgent steppedOptimistic
  where
    steppedUrgent =
      stepPrice params floorPrice (utilOf Urgent (urgentCapacity capacities)) (urgent prices)
    -- Each lane's price moves on ITS OWN block's verdict. The urgent lane is
    -- judged every block (a regular block comes every round, an empty one
    -- really means an idle lane). The optimistic lane is judged only when one
    -- of its endorser blocks actually COUNTS in this block — certification
    -- pacing leaves most rounds with no optimistic block to judge, and
    -- treating those as "the lane ran empty" made the price ping-pong at the
    -- floor while the pool sat full (measured live). No verdict, no move.
    steppedOptimistic
      | laneBytes Optimistic == 0 = optimistic prices
      | otherwise =
          stepPrice params floorPrice (utilOf Optimistic (optimisticCapacity capacities)) (optimistic prices)
    laneBytes strategy =
      toInteger . unTxSizeInBytes . bytesUsed $ usageOf strategy usage
    utilOf strategy (BlockCapacity capacity) =
      Utilisation (laneBytes strategy % max 1 capacity)

-- | Publish two stepped prices, re-imposing the discrimination floor: if the
-- controller pushed 'Urgent' below @priceDiscriminationFloor * Optimistic@,
-- raise it back so 'mkInclusionPrices' always succeeds.
publishFloored :: InclusionPrice -> InclusionPrice -> InclusionPrices
publishFloored steppedUrgent o@(InclusionPrice (Coin op)) =
  fromMaybe
    (error "DynamicPricing.reprice: floored prices still violate the discrimination floor")
    (mkInclusionPrices (max steppedUrgent flooredUrgent) o)
  where
    flooredUrgent = InclusionPrice (Coin (priceDiscriminationFloor * op))
