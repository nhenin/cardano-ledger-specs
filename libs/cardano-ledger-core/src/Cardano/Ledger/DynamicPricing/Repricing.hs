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
  InclusionPrices (..),
  TxSizeInBytes (..),
 )
import Cardano.Ledger.DynamicPricing.Usage (BlockUsage, bytesUsed, usageOf)
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

-- | The controller calibration the ledger runs: the CIP's recommended
-- construction (@target = 1/2@, @D = 16@, so at most +/-6.25% per block).
-- We ran @D = 4@ then @D = 8@ earlier for a livelier demo staircase; both
-- sit inside the CIP's validated 8-16 envelope. Eventually a protocol
-- parameter; a constant for the prototype.
defaultControllerParams :: ControllerParams
defaultControllerParams =
  ControllerParams (TargetUtilisation (1 % 2)) (MaxChangeDenominator 16)

-- | End-of-block repricing (spec: @updateTiers@): one EIP-1559 controller step
-- per lane (Will's mechanism-design doc). The lanes publish independently —
-- no cross-lane floor, temporary quote crossings permitted (the CIP's
-- recommended construction).
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
  InclusionPrices steppedUrgent steppedOptimistic
  where
    -- Each lane's price moves only on a reprice that carries ITS OWN transport's
    -- bytes. The ranking block (urgent) and a certified endorser block
    -- (optimistic) are applied in SEPARATE reprices: a ranking-block reprice
    -- carries urgent bytes and zero optimistic; a certification reprice carries
    -- the endorser block's optimistic bytes and zero urgent (measured live).
    --
    -- Urgent holds on a pure certification reprice — zero urgent bytes but
    -- optimistic bytes present. Otherwise it steps: a full ranking block raises
    -- the price, and a genuinely empty ranking block (both lanes zero, no urgent
    -- demand) decays it. Without this, every certification was read as "the
    -- urgent lane ran empty" and dropped the price 25% between full blocks — the
    -- sawtooth seen under saturation, the mirror of the optimistic ping-pong.
    steppedUrgent
      | laneBytes Urgent == 0 && laneBytes Optimistic > 0 = urgent prices
      | otherwise =
          stepPrice params floorPrice (utilOf Urgent (urgentCapacity capacities)) (urgent prices)
    -- The optimistic lane is judged only when one of its endorser blocks
    -- actually COUNTS (a certification reprice with optimistic bytes). Rounds
    -- with no optimistic block to judge — ranking-block reprices and idle rounds
    -- — hold, instead of reading "the lane ran empty" and ping-ponging at the
    -- floor while the pool sat full (Giorgos's rule; measured live).
    steppedOptimistic
      | laneBytes Optimistic == 0 = optimistic prices
      | otherwise =
          stepPrice params floorPrice (utilOf Optimistic (optimisticCapacity capacities)) (optimistic prices)
    laneBytes strategy =
      toInteger . unTxSizeInBytes . bytesUsed $ usageOf strategy usage
    utilOf strategy (BlockCapacity capacity) =
      Utilisation (laneBytes strategy % max 1 capacity)
