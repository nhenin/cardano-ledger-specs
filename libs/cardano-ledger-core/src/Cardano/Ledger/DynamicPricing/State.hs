{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | The era-indexed pricing state, following the codebase's established
-- pattern for era-varying state (@EraGov\/GovState@, @EraCertState\/CertState@,
-- @EraStake\/InstantStake@): a class bundling all the instances the state
-- must provide, with an injective associated type family. Pre-dynamic-pricing
-- eras instantiate the inert 'NoPricing'; the era that activates the
-- mechanism instantiates 'DynamicPricing'.
module Cardano.Ledger.DynamicPricing.State (
  -- * The era family
  EraPricing (..),

  -- * Pre-dynamic-pricing eras
  NoPricing (..),

  -- * The live pricing state
  DynamicPricing (..),
  initialPricingState,
  recordTx,
  currentPrice,
  setBlockDelivery,
  addPendingRefund,
  drainPendingRefunds,
  retainPendingRefunds,

  -- * Per-block usage accounting
  BlockUsage (..),
  InclusionUsage (..),
  emptyBlockUsage,
  emptyInclusionUsage,
  recordInclusionUsage,
  usageOf,

  -- * Fee refunds
  PendingRefunds (..),
  emptyPendingRefunds,

  -- * End-of-block repricing (DIVUP)
  BlockCapacity (..),
  InclusionCapacities (..),
  defaultControllerParams,
  reprice,
  endOfBlock,
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
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.DynamicPricing.Controller (ControllerParams)
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion, InclusionDelivery (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  InclusionPrices (..),
  TxSizeInBytes,
  priceOf,
 )
import Cardano.Ledger.DynamicPricing.Refunds (
  PendingRefunds (..),
  drainRefunds,
  emptyPendingRefunds,
  pendingRefundsFromMap,
  recordPendingRefund,
 )
import Cardano.Ledger.DynamicPricing.Repricing (
  BlockCapacity (..),
  InclusionCapacities (..),
  defaultControllerParams,
  repriceBlockUsage,
 )
import Cardano.Ledger.DynamicPricing.Signal (PricingSignals, emptyPricingSignals)
import Cardano.Ledger.DynamicPricing.Usage (
  BlockUsage (..),
  InclusionUsage (..),
  emptyBlockUsage,
  emptyInclusionUsage,
  recordInclusionUsage,
  usageOf,
 )
import Cardano.Ledger.Keys (KeyRole (Staking))
import Cardano.Ledger.Plutus.ExUnits (ExUnits)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Default (Default (..))
import Data.Kind (Type)
import Data.Map.Strict (Map)
import Data.Typeable (Typeable)
import Data.Word (Word8)
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | Every era carries a pricing state; its shape is the era's choice.
class
  ( Eq (PricingState era)
  , Show (PricingState era)
  , NFData (PricingState era)
  , NoThunks (PricingState era)
  , Typeable (PricingState era)
  , EncCBOR (PricingState era)
  , DecCBOR (PricingState era)
  , Default (PricingState era)
  , ToJSON (PricingState era)
  ) =>
  EraPricing era
  where
  type PricingState era = (r :: Type) | r -> era

  -- | The pricing state an era starts with.
  emptyPricing :: PricingState era
  emptyPricing = def

-- | The inert pricing state of the eras that predate dynamic pricing.
data NoPricing era = NoPricing
  deriving (Eq, Ord, Show, Generic)

instance NoThunks (NoPricing era)

instance NFData (NoPricing era)

instance Default (NoPricing era) where
  def = NoPricing

instance ToJSON (NoPricing era) where
  toJSON NoPricing = toJSON ()

instance EncCBOR (NoPricing era) where
  encCBOR NoPricing = encCBOR (0 :: Word8)

instance Typeable era => DecCBOR (NoPricing era) where
  decCBOR =
    decCBOR >>= \case
      (0 :: Word8) -> pure NoPricing
      n -> fail $ "Invalid NoPricing encoding: " <> show n

-- | The live pricing state (spec: @SDPolicy@): the published prices plus the
-- usage counters of the block being processed.
data DynamicPricing era = DynamicPricing
  { publishedPrices :: !InclusionPrices
  -- ^ The price of each inclusion strategy (deck: DP1\/DP2).
  , blockUsage :: !BlockUsage
  -- ^ Usage of the block currently being processed (spec: the
  -- @totalSize\/totalFees\/totalExUnits@ maps).
  , pendingRefunds :: !PendingRefunds
  -- ^ Refunds owed to bidders (the unused headroom of their bids), flushed
  -- into account balances by the LEDGER rule after every transaction
  -- (spec: @feeRewards@).
  , pricingSignals :: !PricingSignals
  -- ^ Each lane's window of recent controller samples (the CIP's signals),
  -- rolled forward by every sample-carrying reprice.
  , blockDelivery :: !InclusionDelivery
  -- ^ How the block currently being processed delivers its transactions
  -- (the CIP's rb-only premium scope prices by delivery, not declaration).
  -- Stamped by the BBODY rule before the block's transactions run; reset
  -- to 'Immediate' at the block boundary, so the state between blocks —
  -- and the mempool's view at admission — always reads 'Immediate'.
  }
  deriving (Eq, Show, Generic)

instance NoThunks (DynamicPricing era)

instance NFData (DynamicPricing era)

instance Default (DynamicPricing era) where
  def = initialPricingState

instance ToJSON (DynamicPricing era) where
  toJSON dp =
    object
      [ "urgent" .= unInclusionPrice (urgent (publishedPrices dp))
      , "optimistic" .= unInclusionPrice (optimistic (publishedPrices dp))
      , "blockUsage" .= blockUsage dp
      , "pendingRefunds" .= pendingRefunds dp
      ]

instance EncCBOR (DynamicPricing era) where
  encCBOR (DynamicPricing prices usage refunds signals delivery) =
    encode $
      Rec mkDynamicPricing
        !> To (urgent prices)
        !> To (optimistic prices)
        !> To usage
        !> To refunds
        !> To signals
        !> To delivery

instance Typeable era => DecCBOR (DynamicPricing era) where
  decCBOR = decode $ RecD mkDynamicPricing <! From <! From <! From <! From <! From <! From

-- The signal windows and the delivery are encoded LAST: the measured-pots
-- poller pins the leading array indices (urgent, optimistic, usage, refunds).
mkDynamicPricing ::
  InclusionPrice ->
  InclusionPrice ->
  BlockUsage ->
  PendingRefunds ->
  PricingSignals ->
  InclusionDelivery ->
  DynamicPricing era
mkDynamicPricing u o = DynamicPricing (InclusionPrices u o)

-- | Starting state. 'Optimistic' opens at today's @minFeeA@ rate
-- (44 lovelace\/byte); 'Urgent' opens at 2× that (the CIP's initial
-- coefficient for the urgent controller).
initialPricingState :: DynamicPricing era
initialPricingState =
  DynamicPricing
    { publishedPrices =
        InclusionPrices (InclusionPrice (Coin (2 * 44))) (InclusionPrice (Coin 44))
    , blockUsage = emptyBlockUsage
    , pendingRefunds = emptyPendingRefunds
    , pricingSignals = emptyPricingSignals
    , blockDelivery = Immediate
    }

-- | Stamp how the block being processed delivers its transactions. The
-- BBODY rule calls this before the block's transactions run.
setBlockDelivery :: InclusionDelivery -> DynamicPricing era -> DynamicPricing era
setBlockDelivery delivery ps = ps {blockDelivery = delivery}

-- | Record a refund owed to a bidder (U3 of the fee split): the unused
-- headroom between the bid and the charged quote.
addPendingRefund :: Credential Staking -> Coin -> DynamicPricing era -> DynamicPricing era
addPendingRefund cred amount ps =
  ps {pendingRefunds = recordPendingRefund cred amount (pendingRefunds ps)}

-- | Hand over all pending refunds (the LEDGER rule credits them to account
-- balances after every transaction; spec: the @feeRewards@ flush).
drainPendingRefunds :: DynamicPricing era -> (Map (Credential Staking) Coin, DynamicPricing era)
drainPendingRefunds ps =
  (refunds, ps {pendingRefunds = drained})
  where
    (refunds, drained) = drainRefunds (pendingRefunds ps)

-- | Keep refunds that could not yet be credited. The LEDGER rule uses this
-- for unregistered refund accounts.
retainPendingRefunds :: Map (Credential Staking) Coin -> DynamicPricing era -> DynamicPricing era
retainPendingRefunds refunds ps =
  ps {pendingRefunds = pendingRefundsFromMap refunds}

-- | Account for one transaction delivered under an inclusion strategy
-- (spec: @processTxTiers@).
recordTx ::
  Inclusion -> TxSizeInBytes -> Coin -> ExUnits -> DynamicPricing era -> DynamicPricing era
recordTx strategy size fee exUnits ps =
  ps {blockUsage = recordInclusionUsage strategy size fee exUnits (blockUsage ps)}

-- | The current public price of an inclusion strategy. Total — the protocol
-- always has a price for every strategy.
currentPrice :: Inclusion -> DynamicPricing era -> InclusionPrice
currentPrice strategy = priceOf strategy . publishedPrices

-- | End-of-block repricing (spec: @updateTiers@): one EIP-1559 controller step
-- per lane (Will's mechanism-design doc). The lanes publish independently —
-- no cross-lane floor (the CIP's recommended construction).
--
-- Each lane's utilisation is its OWN fill against its pricing target
-- ('InclusionCapacities'; Praos-only steers both against the shared RB). See
-- 'repriceBlockUsage' for the signal; this wrapper only supplies the published
-- prices and block usage from the pricing state.
reprice ::
  ControllerParams ->
  -- | The lane floor price (today's @minFeeA@; the controller's @c = 1@).
  InclusionPrice ->
  -- | The per-lane block-body capacities to measure utilisation against.
  InclusionCapacities ->
  DynamicPricing era ->
  (InclusionPrices, PricingSignals)
reprice params floorPrice capacities ps =
  repriceBlockUsage
    params
    floorPrice
    capacities
    (blockDelivery ps)
    (publishedPrices ps)
    (pricingSignals ps)
    (blockUsage ps)

-- | Block boundary (spec: the @DIVUP@ rule): apply 'reprice', roll the
-- signal windows forward, reset usage. The spec's @sdChecks@ premise (the
-- optimistic usage fits RB limits) lives with the BBODY rule, not here.
endOfBlock ::
  ControllerParams ->
  InclusionPrice ->
  InclusionCapacities ->
  DynamicPricing era ->
  DynamicPricing era
endOfBlock params floorPrice capacities ps =
  ps
    { publishedPrices = prices
    , pricingSignals = signals
    , blockUsage = emptyBlockUsage
    , blockDelivery = Immediate
    }
  where
    (prices, signals) = reprice params floorPrice capacities ps
