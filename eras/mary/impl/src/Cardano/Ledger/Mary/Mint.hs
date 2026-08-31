{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Cardano.Ledger.Mary.Mint (
  MintDelta (..),
  MintedAssets,
  unMintedAssets,
  BurnedAssets,
  unBurnedAssets,
  mintedAssets,
  burnedAssets,
) where

import Cardano.Ledger.Mary.Value (MultiAsset, filterMultiAsset, mapMaybeMultiAsset)
import Control.DeepSeq (NFData)
import Data.Group (Group)
import NoThunks.Class (NoThunks)

-- | The signed native-asset quantities carried by the transaction mint field.
-- Positive quantities mint assets and negative quantities burn assets. Ada is
-- not part of this domain.
newtype MintDelta = MintDelta {unMintDelta :: MultiAsset}
  deriving stock (Eq, Show)
  deriving newtype (NFData, NoThunks, Semigroup, Monoid, Group)

-- | The positive quantities selected from a 'MintDelta'.
newtype MintedAssets = MintedAssets {unMintedAssets :: MultiAsset}
  deriving stock (Eq, Show)
  deriving newtype (NFData, NoThunks, Semigroup, Monoid)

-- | The positive magnitudes of the negative quantities in a 'MintDelta'.
newtype BurnedAssets = BurnedAssets {unBurnedAssets :: MultiAsset}
  deriving stock (Eq, Show)
  deriving newtype (NFData, NoThunks, Semigroup, Monoid)

mintedAssets :: MintDelta -> MintedAssets
mintedAssets = MintedAssets . filterMultiAsset (\_ _ -> (> 0)) . unMintDelta

burnedAssets :: MintDelta -> BurnedAssets
burnedAssets =
  BurnedAssets
    . mapMaybeMultiAsset (\_ _ quantity -> if quantity < 0 then Just (negate quantity) else Nothing)
    . unMintDelta
