{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Cardano.Ledger.State.Stake (
  Stake (..),
  sumAllStake,
  sumAllStakeCompact,
  sumCredentialsCompactStake,
  StakeWithDelegation (..),
  ActiveStake (..),
  sumAllActiveStake,
  sumCredentialsCompactActiveStake,
) where

import Cardano.Ledger.BaseTypes (
  NonZero (..),
  nonZeroOr,
 )
import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (..),
  EncCBOR (..),
  Interns,
  decodeRecordNamed,
  encodeListLen,
 )
import Cardano.Ledger.Coin
import Cardano.Ledger.Compactible (fromCompact)
import Cardano.Ledger.Core
import Cardano.Ledger.Credential
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON)
import Data.Foldable (foldMap')
import Data.Maybe (fromMaybe)
import Data.VMap (VB, VMap, VP, VS)
import qualified Data.VMap as VMap
import Foreign.Ptr (castPtr)
import Foreign.Storable (Storable (..))
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | Type of stake as map from staking credential to coins associated. Any staking credential that
-- has no stake will not appear in this Map, even if it is registered. For this reason, this data
-- type should not be used for infering whether credential is registered or not.
newtype Stake = Stake
  { unStake :: VMap VB VP (Credential Staking) (CompactForm Coin)
  }
  deriving (Show, Eq, NFData, Generic, ToJSON, NoThunks, EncCBOR)

instance Monoid Stake where
  mempty = Stake VMap.empty

instance Semigroup Stake where
  Stake s1 <> Stake s2 = Stake $ VMap.unionWith (<>) s1 s2

instance DecShareCBOR Stake where
  type Share Stake = Share (VMap VB VP (Credential Staking) (CompactForm Coin))
  getShare = getShare . unStake
  decShareCBOR = fmap Stake . decShareCBOR

sumAllStake :: Stake -> Coin
sumAllStake = fromCompact . sumAllStakeCompact
{-# INLINE sumAllStake #-}

sumAllStakeCompact :: Stake -> CompactForm Coin
sumAllStakeCompact = VMap.foldl (<>) mempty . unStake
{-# INLINE sumAllStakeCompact #-}

sumCredentialsCompactStake :: Foldable f => Stake -> f (Credential Staking) -> CompactForm Coin
sumCredentialsCompactStake (Stake stake) = foldMap' (fromMaybe mempty . (`VMap.lookup` stake))
{-# INLINE sumCredentialsCompactStake #-}

-- | Combination of non-zero stake with the pool delegation for a single credential.
data StakeWithDelegation = StakeWithDelegation
  { swdStake :: {-# UNPACK #-} !(NonZero (CompactForm Coin))
  , swdDelegation :: !(KeyHash StakePool)
  }
  deriving (Eq, Show, Generic)

instance NoThunks StakeWithDelegation

instance NFData StakeWithDelegation

instance ToJSON StakeWithDelegation

instance EncCBOR StakeWithDelegation where
  encCBOR (StakeWithDelegation s d) = encodeListLen 2 <> encCBOR s <> encCBOR d

instance DecCBOR StakeWithDelegation where
  decCBOR =
    decodeRecordNamed "SnapShot" (const 2) $
      StakeWithDelegation <$> decCBOR <*> decCBOR

instance DecShareCBOR StakeWithDelegation where
  type Share StakeWithDelegation = Interns (Credential Staking)
  decShareCBOR _si = decCBOR

instance Storable StakeWithDelegation where
  sizeOf _ =
    sizeOf (undefined :: (NonZero (CompactForm Coin)))
      + sizeOf (undefined :: KeyHash StakePool)
  alignment _ = 8
  poke ptr swd@(StakeWithDelegation _ _) = do
    let StakeWithDelegation {..} = swd
    poke (castPtr ptr) swdStake
    pokeByteOff (castPtr ptr) (sizeOf swdStake) swdDelegation
  {-# INLINE poke #-}
  peek ptr = do
    swdStake <- peek (castPtr ptr)
    swdDelegation <- peekByteOff (castPtr ptr) (sizeOf swdStake)
    pure StakeWithDelegation {..}
  {-# INLINE peek #-}

-- | Active stake: maps staking credentials to their non-zero stake paired with delegation.
-- Only credentials that are registered, delegated, and have non-zero stake appear here.
newtype ActiveStake = ActiveStake
  { unActiveStake :: VMap VB VS (Credential Staking) StakeWithDelegation
  }
  deriving (Show, Eq, NFData, Generic, ToJSON, NoThunks, EncCBOR)

instance DecShareCBOR ActiveStake where
  type Share ActiveStake = Interns (Credential Staking)
  getShare (ActiveStake m) = getShare m
  decShareCBOR si = ActiveStake <$> decShareCBOR si

-- | Sum all active stake. Returns @NonZero Coin@, defaulting to 1 lovelace if empty.
sumAllActiveStake :: ActiveStake -> NonZero Coin
sumAllActiveStake (ActiveStake m) =
  VMap.foldMap (fromCompact . unNonZero . swdStake) m `nonZeroOr` knownNonZeroCoin @1
{-# INLINE sumAllActiveStake #-}

-- | Sum the compact stake for a set of credentials from an @ActiveStake@.
sumCredentialsCompactActiveStake ::
  Foldable f => ActiveStake -> f (Credential Staking) -> CompactForm Coin
sumCredentialsCompactActiveStake (ActiveStake m) =
  foldMap' (\cred -> maybe mempty (unNonZero . swdStake) (VMap.lookup cred m))
{-# INLINE sumCredentialsCompactActiveStake #-}
