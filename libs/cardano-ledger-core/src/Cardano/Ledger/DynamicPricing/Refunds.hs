{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}

-- | Pending fee refunds owed by the dynamic-pricing fee split.
--
-- The UTXO rule records the unused headroom between a transaction's bid and
-- the quote charged for its declared inclusion strategy. The LEDGER rule later
-- credits registered accounts and keeps unregistered accounts pending.
module Cardano.Ledger.DynamicPricing.Refunds (
  PendingRefunds (..),
  emptyPendingRefunds,
  recordPendingRefund,
  drainRefunds,
  pendingRefundsFromMap,
) where

import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Keys (KeyRole (Staking))
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..))
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | Refunds that have been earned by valid transactions but have not yet been
-- credited to an account balance.
newtype PendingRefunds = PendingRefunds
  { unPendingRefunds :: Map (Credential Staking) Coin
  -- ^ Refund amount per staking credential.
  }
  deriving stock (Eq, Show, Generic)

instance NoThunks PendingRefunds

instance NFData PendingRefunds

instance ToJSON PendingRefunds where
  toJSON (PendingRefunds refunds) = toJSON refunds

instance EncCBOR PendingRefunds where
  encCBOR (PendingRefunds refunds) = encCBOR refunds

instance DecCBOR PendingRefunds where
  decCBOR = PendingRefunds <$> decCBOR

-- | No refunds are waiting to be delivered.
emptyPendingRefunds :: PendingRefunds
emptyPendingRefunds = PendingRefunds Map.empty

-- | Add an owed refund to the pending map, accumulating multiple refunds for
-- the same credential.
recordPendingRefund :: Credential Staking -> Coin -> PendingRefunds -> PendingRefunds
recordPendingRefund cred amount (PendingRefunds refunds) =
  PendingRefunds (Map.insertWith (<>) cred amount refunds)

-- | Drain all pending refunds. The caller decides which credentials can be
-- credited and which must remain pending.
drainRefunds :: PendingRefunds -> (Map (Credential Staking) Coin, PendingRefunds)
drainRefunds (PendingRefunds refunds) =
  (refunds, emptyPendingRefunds)

-- | Rebuild pending refunds from the credentials that could not yet be
-- credited.
pendingRefundsFromMap :: Map (Credential Staking) Coin -> PendingRefunds
pendingRefundsFromMap = PendingRefunds
