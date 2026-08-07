{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Per-block resource accounting for the dynamic-pricing domain.
--
-- The ledger prices the inclusion strategy a transaction declares. These
-- counters record the resources consumed by each declared strategy within the
-- block currently being processed; the BBODY rule reads them at the block
-- boundary and then resets them.
module Cardano.Ledger.DynamicPricing.Usage (
  -- * Per-block usage
  BlockUsage (..),
  emptyBlockUsage,
  recordInclusionUsage,
  usageOf,

  -- * Per-strategy usage
  InclusionUsage (..),
  emptyInclusionUsage,
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
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion)
import Cardano.Ledger.DynamicPricing.Pricing (TxSizeInBytes (..))
import Cardano.Ledger.Plutus.ExUnits (ExUnits (..))
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | Usage counters for every inclusion strategy observed in the current
-- block. Missing strategies mean zero usage, by construction.
newtype BlockUsage = BlockUsage {unBlockUsage :: Map Inclusion InclusionUsage}
  deriving stock (Eq, Show, Generic)

instance NoThunks BlockUsage

instance NFData BlockUsage

instance Semigroup BlockUsage where
  BlockUsage left <> BlockUsage right =
    BlockUsage (Map.unionWith (<>) left right)

instance Monoid BlockUsage where
  mempty = emptyBlockUsage

instance ToJSON BlockUsage where
  toJSON (BlockUsage usage) =
    toJSON (Map.toList (Map.mapKeys show usage))

instance EncCBOR BlockUsage where
  encCBOR (BlockUsage usage) = encCBOR usage

instance DecCBOR BlockUsage where
  decCBOR = BlockUsage <$> decCBOR

-- | No resources have been consumed in the current block.
emptyBlockUsage :: BlockUsage
emptyBlockUsage = BlockUsage Map.empty

-- | Add one transaction's usage to the counters of its declared inclusion
-- strategy (spec: @processTxTiers@).
recordInclusionUsage ::
  Inclusion ->
  -- | Transaction size, in bytes.
  TxSizeInBytes ->
  -- | Fee bid collected for the transaction.
  Coin ->
  -- | Execution units consumed by the transaction.
  ExUnits ->
  BlockUsage ->
  BlockUsage
recordInclusionUsage strategy size fee exUnits (BlockUsage usage) =
  BlockUsage $
    Map.insertWith
      (<>)
      strategy
      (InclusionUsage size fee exUnits)
      usage

-- | Read one strategy's usage. Total: absent counters are zero counters.
usageOf :: Inclusion -> BlockUsage -> InclusionUsage
usageOf strategy (BlockUsage usage) =
  Map.findWithDefault mempty strategy usage

-- | Resources consumed within the current block by the transactions of one
-- inclusion strategy. Reset at every block boundary.
data InclusionUsage = InclusionUsage
  { bytesUsed :: !TxSizeInBytes
  -- ^ Block bytes used by this strategy.
  , feesCollected :: !Coin
  -- ^ Fees bid by transactions of this strategy.
  , exUnitsUsed :: !ExUnits
  -- ^ Execution units used by this strategy.
  }
  deriving stock (Eq, Show, Generic)

instance NoThunks InclusionUsage

instance NFData InclusionUsage

instance ToJSON InclusionUsage where
  toJSON (InclusionUsage b f e) =
    object ["bytes" .= unTxSizeInBytes b, "fees" .= f, "exUnits" .= e]

instance EncCBOR InclusionUsage where
  encCBOR (InclusionUsage b f e) =
    encode $ Rec InclusionUsage !> To b !> To f !> To e

instance DecCBOR InclusionUsage where
  decCBOR = decode $ RecD InclusionUsage <! From <! From <! From

-- | Zero usage for one inclusion strategy.
emptyInclusionUsage :: InclusionUsage
emptyInclusionUsage = InclusionUsage 0 (Coin 0) mempty

instance Semigroup InclusionUsage where
  InclusionUsage b1 f1 e1 <> InclusionUsage b2 f2 e2 =
    InclusionUsage (b1 + b2) (f1 <> f2) (e1 <> e2)

instance Monoid InclusionUsage where
  mempty = emptyInclusionUsage
