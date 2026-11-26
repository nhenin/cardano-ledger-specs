{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE LambdaCase #-}

module Cardano.Ledger.Core.TxValidity (
  IsPhase2Valid (..),
  isPhase2Valid,
  toIsPhase2Valid,
) where

import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..), ToCBOR (..))
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON (..), ToJSON (..))
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | Tag indicating whether the non-native (phase-2) scripts in this transaction
-- are expected to validate. This is added by the block creator when constructing
-- the block.
data IsPhase2Valid
  = Phase2Invalid
  | Phase2Valid
  deriving stock (Eq, Ord, Show, Generic)
  deriving anyclass (NoThunks, NFData)

instance Semigroup IsPhase2Valid where
  Phase2Valid <> x = x
  Phase2Invalid <> _ = Phase2Invalid

instance Monoid IsPhase2Valid where
  mempty = Phase2Valid

isPhase2Valid :: IsPhase2Valid -> Bool
isPhase2Valid = \case
  Phase2Invalid -> False
  Phase2Valid -> True

toIsPhase2Valid :: Bool -> IsPhase2Valid
toIsPhase2Valid b = if b then Phase2Valid else Phase2Invalid

instance EncCBOR IsPhase2Valid where
  encCBOR = encCBOR . isPhase2Valid

instance DecCBOR IsPhase2Valid where
  decCBOR = toIsPhase2Valid <$> decCBOR

instance ToCBOR IsPhase2Valid where
  toCBOR = toCBOR . isPhase2Valid

instance ToJSON IsPhase2Valid where
  toJSON = toJSON . isPhase2Valid
  toEncoding = toEncoding . isPhase2Valid

instance FromJSON IsPhase2Valid where
  parseJSON = fmap toIsPhase2Valid . parseJSON
