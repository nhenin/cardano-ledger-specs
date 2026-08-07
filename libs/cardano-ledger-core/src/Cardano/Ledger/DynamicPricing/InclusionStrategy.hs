{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeApplications #-}

-- | The inclusion strategy a transaction purchases.
--
-- The /lanes/ (RB vs EB transport) are infrastructure: the consensus-layer
-- mechanism that delivers each strategy. They are deliberately absent from
-- this vocabulary.
--
-- Spec correspondence (@formal-ledger-specifications\@polina\/dynamic@):
-- 'Inclusion' \<-\> @TierNo@ (@fastTier@ = 0, @slowTier@ = 1).
--
-- Implementation choice (flagged to Polina): the spec keeps @TierNo = ℕ@
-- open (N tiers); we close the domain to exactly two strategies per the
-- phase-2 down-select.
module Cardano.Ledger.DynamicPricing.InclusionStrategy (
  Inclusion (..),
  InclusionDelivery (..),
  chargedStrategy,
) where

import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Control.DeepSeq (NFData)
import Data.Word (Word8)
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | The kind of inclusion a transaction purchases:
-- guaranteed-and-serialized, or cheaper-but-conditional.
--
-- Wire format note: serializes as the spec's @TierNo@ — 'Urgent' = 0
-- (@fastTier@), 'Optimistic' = 1 (@slowTier@).
data Inclusion
  = -- | Urgent, serialized inclusion — included whatever happens to EB
    -- certification. Infra: direct RB inclusion (in the certified EB
    -- otherwise).
    Urgent
  | -- | Optimistic inclusion — cheaper, carries the certification risk.
    -- Infra: via EBs.
    Optimistic
  deriving (Eq, Ord, Show, Enum, Bounded, Generic)

instance NoThunks Inclusion

instance NFData Inclusion

instance EncCBOR Inclusion where
  encCBOR =
    encCBOR @Word8 . \case
      Urgent -> 0
      Optimistic -> 1

instance DecCBOR Inclusion where
  decCBOR =
    decCBOR @Word8 >>= \case
      0 -> pure Urgent
      1 -> pure Optimistic
      n -> fail $ "Invalid Inclusion (expected 0 or 1): " <> show n

-- | How a block delivered its transactions to the ledger: as its own
-- immediate payload, or through a certified optimistic batch spliced in
-- when its certificate landed. Block-scoped by construction — a
-- certificate-carrying block is payload-free, so every transaction in one
-- application shares one delivery. Infra: 'Immediate' = the ranking
-- block's own txs, 'Certified' = the endorser block's.
data InclusionDelivery
  = Immediate
  | Certified
  deriving (Eq, Ord, Show, Enum, Bounded, Generic)

instance NoThunks InclusionDelivery

instance NFData InclusionDelivery

instance EncCBOR InclusionDelivery where
  encCBOR =
    encCBOR @Word8 . \case
      Immediate -> 0
      Certified -> 1

instance DecCBOR InclusionDelivery where
  decCBOR =
    decCBOR @Word8 >>= \case
      0 -> pure Immediate
      1 -> pure Certified
      n -> fail $ "Invalid InclusionDelivery (expected 0 or 1): " <> show n

-- | The strategy whose price a transaction pays at inclusion (the CIP's
-- rb-only premium scope): an 'Urgent' transaction that arrives through a
-- certified batch pays the 'Optimistic' price. The premium buys immediate
-- delivery; a transaction that did not receive it is not charged for it.
chargedStrategy :: Inclusion -> InclusionDelivery -> Inclusion
chargedStrategy Urgent Certified = Optimistic
chargedStrategy declared _ = declared
