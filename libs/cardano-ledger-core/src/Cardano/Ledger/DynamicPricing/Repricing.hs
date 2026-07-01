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
  optimisticBlockFactor,
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
import Numeric.Natural (Natural)

-- | A block-body capacity the utilisation signal is measured against, in bytes.
newtype BlockCapacity = BlockCapacity {unBlockCapacity :: Integer}
  deriving stock (Eq, Show, Generic)

-- | The block-body capacity each lane's pricing utilisation is measured against
-- — one target per inclusion strategy. Praos-only has one physical block, so
-- both default to the Praos block (the RB) the lanes share: measuring each lane
-- against its OWN fill (not the aggregate) is what lets the two lanes price
-- independently and dynamically. Once endorser-block transport exists,
-- 'optimisticCapacity' becomes the EB's own (larger) budget.
data InclusionCapacities = InclusionCapacities
  { urgentCapacity :: !BlockCapacity
  , optimisticCapacity :: !BlockCapacity
  }
  deriving stock (Eq, Show, Generic)

-- | Prototype endorser-block (EB) sizing: the optimistic lane's hard overflow
-- ceiling is this multiple of the RB budget — its future EB hard cap. Dormant in
-- Praos-only (the shared RB and the block-total checks bind first); it bites once
-- optimistic txs move to a separate endorser block. Distinct from the pricing
-- target, which steers against the RB so the lane prices dynamically (the
-- EIP-1559 limit-vs-target split).
optimisticBlockFactor :: Natural
optimisticBlockFactor = 2

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
  publishFloored
    (stepPrice params floorPrice (utilOf Urgent (urgentCapacity capacities)) (urgent prices))
    (stepPrice params floorPrice (utilOf Optimistic (optimisticCapacity capacities)) (optimistic prices))
  where
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
