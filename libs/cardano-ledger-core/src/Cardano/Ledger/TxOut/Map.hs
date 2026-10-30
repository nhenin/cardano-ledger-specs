{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Output payloads indexed by their transaction input references.
-- This view contains no accepted sizes or historical deposit calculations.
module Cardano.Ledger.TxOut.Map (
  TxOutMap (..),
) where

import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (Share, decShareCBOR),
  EncCBOR (..),
  FromCBOR (..),
  Interns,
  ToCBOR (..),
  decNoShareCBOR,
  decodeMap,
 )
import Cardano.Ledger.Core.Era (Era, fromEraCBOR, toEraCBOR)
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Hashes (KeyRole (Staking))
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.TxOut (TxOut)
import Control.DeepSeq (NFData)
import Control.Monad ((<$!>))
import Data.Aeson (ToJSON)
import Data.Default (Default)
import qualified Data.Map.Strict as Map
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks (..))
import Quiet (Quiet (Quiet))

-- | Indexed output payloads, whether proposed by a body or projected from a Store.
newtype TxOutMap era = TxOutMap {unTxOutMap :: Map.Map TxIn (TxOut era)}
  deriving (Default, Generic, Semigroup)

instance (Era era, EncCBOR (TxOut era)) => ToCBOR (TxOutMap era) where
  toCBOR = toEraCBOR @era

instance
  (Era era, DecShareCBOR (TxOut era), Share (TxOut era) ~ Interns (Credential Staking)) =>
  FromCBOR (TxOutMap era)
  where
  fromCBOR = fromEraCBOR @era

deriving instance NoThunks (TxOut era) => NoThunks (TxOutMap era)

deriving instance (Era era, NFData (TxOut era)) => NFData (TxOutMap era)

deriving newtype instance (Era era, Eq (TxOut era)) => Eq (TxOutMap era)

deriving newtype instance Era era => Monoid (TxOutMap era)

deriving newtype instance (Era era, EncCBOR (TxOut era)) => EncCBOR (TxOutMap era)

instance
  (Era era, DecShareCBOR (TxOut era), Share (TxOut era) ~ Interns (Credential Staking)) =>
  DecCBOR (TxOutMap era)
  where
  decCBOR = decNoShareCBOR

instance
  ( DecShareCBOR (TxOut era)
  , Share (TxOut era) ~ Interns (Credential Staking)
  ) =>
  DecShareCBOR (TxOutMap era)
  where
  type Share (TxOutMap era) = Interns (Credential Staking)
  decShareCBOR credsInterns =
    TxOutMap <$!> decodeMap decNoShareCBOR (decShareCBOR credsInterns)

deriving via
  Quiet (TxOutMap era)
  instance
    Show (TxOut era) => Show (TxOutMap era)

deriving newtype instance ToJSON (TxOut era) => ToJSON (TxOutMap era)
