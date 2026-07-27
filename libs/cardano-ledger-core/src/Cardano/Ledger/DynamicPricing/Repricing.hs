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
  stepPrice,
 )
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..), InclusionDelivery (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  InclusionPrices (..),
  TxSizeInBytes (..),
 )
import Cardano.Ledger.DynamicPricing.Signal (
  PricingSignals (..),
  Sample (..),
  pushSample,
  standardSignalWindowLength,
  urgentSignalWindowLength,
  windowUtilisation,
 )
import Cardano.Ledger.DynamicPricing.Usage (BlockUsage, bytesUsed, exUnitsUsed, usageOf)
import Cardano.Ledger.Plutus.ExUnits (ExUnits (..))
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
  , urgentExUnitsCapacity :: !ExUnits
  , optimisticExUnitsCapacity :: !ExUnits
  }
  deriving stock (Eq, Show, Generic)

-- | The optimistic inclusion's own block-body budget: mainnet's CIP-164
-- closure THROUGHPUT at the demo's block cadence — 12 MB per 20-second
-- round on mainnet is 3 MB per 5-second round here, the same bytes per
-- second. An absolute budget — unlike the urgent one it is not a
-- protocol-parameter multiple of the regular block. Eventually a protocol
-- parameter; a constant for the prototype.
optimisticBlockCapacity :: BlockCapacity
optimisticBlockCapacity = BlockCapacity 3000000

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
-- Each lane reads its utilisation from a WINDOW of recent samples (the
-- CIP's signals), not from the latest block alone. Two block kinds carry a
-- sample: a transaction-carrying ranking block and a certified endorser
-- block — each reprice here is exactly one of the two (a certificate-
-- carrying ranking block is payload-free by construction and never reaches
-- this function with bytes of its own).
--
-- The samples, per the CIP:
--
-- * A ranking-block reprice adds an urgent sample (the RB's urgent fill
--   against the reservation capacity) and a ZERO standard sample carrying
--   the RB's full capacity — standard transactions cannot occupy a ranking
--   block, yet its capacity still weighs the standard denominator down.
-- * A certification reprice adds a standard sample (the endorser block's
--   fill against its own 3 MB devnet budget, throughput-equivalent to 12 MB
--   per mainnet round) and an urgent sample measuring the
--   EB's urgent traffic against the RESERVATION capacity — how many ranking
--   blocks' worth of urgent traffic the EB carried, not how full it was. An
--   EB can carry urgent riders beyond the reservation, so each urgent sample
--   is capped at one reservation before it enters the five-sample window.
--
-- Both lanes step on every sample-carrying reprice; a lane with an empty
-- window (genesis) holds.
repriceBlockUsage ::
  ControllerParams ->
  -- | The lane floor price (today's @minFeeA@; the controller's @c = 1@).
  InclusionPrice ->
  -- | The per-lane block-body capacities to measure utilisation against.
  InclusionCapacities ->
  -- | How the closing block delivered its transactions — the round kind.
  InclusionDelivery ->
  InclusionPrices ->
  PricingSignals ->
  BlockUsage ->
  (InclusionPrices, PricingSignals)
repriceBlockUsage params floorPrice capacities delivery prices signals usage =
  (InclusionPrices steppedUrgent steppedOptimistic, signals')
  where
    certificationReprice = delivery == Certified
    signals' =
      PricingSignals
        { urgentWindow =
            pushSample urgentSignalWindowLength urgentSample (urgentWindow signals)
        , standardWindow =
            pushSample standardSignalWindowLength standardSample (standardWindow signals)
        }
    urgentSample =
      Sample
        { sampleBytes = min urgentBytesCapacity (laneBytes Urgent)
        , sampleByteCapacity = urgentBytesCapacity
        , sampleExUnits = capExUnits urgentExUnitsLimit (laneExUnits Urgent)
        , sampleExUnitsCapacity = urgentExUnitsLimit
        }
    standardSample
      | certificationReprice =
          Sample
            { sampleBytes = laneBytes Optimistic
            , sampleByteCapacity = unBlockCapacity (optimisticCapacity capacities)
            , sampleExUnits = laneExUnits Optimistic
            , sampleExUnitsCapacity = optimisticExUnitsCapacity capacities
            }
      | otherwise =
          Sample
            { sampleBytes = 0
            , sampleByteCapacity = unBlockCapacity (urgentCapacity capacities)
            , sampleExUnits = mempty
            , sampleExUnitsCapacity = urgentExUnitsCapacity capacities
            }
    steppedUrgent = step (urgentWindow signals') (urgent prices)
    steppedOptimistic = step (standardWindow signals') (optimistic prices)
    step window price =
      maybe price (\u -> stepPrice params floorPrice u price) (windowUtilisation window)
    laneBytes strategy =
      toInteger . unTxSizeInBytes . bytesUsed $ usageOf strategy usage
    laneExUnits strategy = exUnitsUsed (usageOf strategy usage)
    urgentBytesCapacity = unBlockCapacity (urgentCapacity capacities)
    urgentExUnitsLimit = urgentExUnitsCapacity capacities
    capExUnits (ExUnits capMem capSteps) (ExUnits usedMem usedSteps) =
      ExUnits (min capMem usedMem) (min capSteps usedSteps)
