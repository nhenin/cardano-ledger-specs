{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableSuperClasses #-}
-- some GHC bug wrongfully complains about CanGetInstantStake constraint being redundant.
{-# OPTIONS_GHC -Wno-redundant-constraints #-}

-- | Maintain the output-derived stake index and resolve it against registered accounts.
module Cardano.Ledger.State.Accounting.InstantStake (
  EraStake (..),
  CanGetInstantStake (..),
  CanSetInstantStake (..),
  resolveActiveInstantStakeCredentials,
) where

import Cardano.Ledger.BaseTypes (nonZero, unsafeNonZero)
import Cardano.Ledger.Binary (DecShareCBOR (..), EncCBOR, Interns)
import Cardano.Ledger.Coin (Coin, CompactForm)
import Cardano.Ledger.Core (KeyRole (Staking), TxOut)
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.Certificates.Account
import Cardano.Ledger.State.Stake (ActiveStake, StakeWithDelegation (..))
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON)
import Data.Default (Default)
import Data.Functor.Identity (Identity (..))
import Data.Kind (Type)
import qualified Data.Map.Merge.Strict as Map
import Data.Map.Strict (Map)
import Lens.Micro (Lens', SimpleGetter, (^.))
import NoThunks.Class (NoThunks)

class
  ( EraAccounts era
  , Ord (InstantStake era)
  , Show (InstantStake era)
  , Monoid (InstantStake era)
  , Default (InstantStake era)
  , NFData (InstantStake era)
  , NoThunks (InstantStake era)
  , ToJSON (InstantStake era)
  , EncCBOR (InstantStake era)
  , DecShareCBOR (InstantStake era)
  , Share (InstantStake era) ~ Interns (Credential Staking)
  ) =>
  EraStake era
  where
  -- | This is the current stake in the system. The important part of this stake is that not all of
  -- it is active. Any stake credential that is not registred will not contribute to the active
  -- stake, however it will be part of the instant stake. Throughout an epoch it is not relevant
  -- which part of the stake is active, because it is only when we take the snaphot that we resolve
  -- all the active stake.
  type InstantStake era = (r :: Type) | r -> era

  instantStakeCredentialsL :: Lens' (InstantStake era) (Map (Credential Staking) (CompactForm Coin))

  -- | Add outputs to the `InstantStake`. This is invoked for every new TxOut that is added to the
  -- ledger state
  addInstantStake :: Foldable f => f (TxOut era) -> InstantStake era -> InstantStake era

  -- | Delete spent outputs from the `InstantStake`. This is invoked for every TxOut that is removed
  -- from the ledger state
  deleteInstantStake :: Foldable f => f (TxOut era) -> InstantStake era -> InstantStake era

  -- TODO: This functionality will be removed and switched to use a pulser

  -- | Using known stake credential registrations and delegations resolve the instant stake into
  -- `ActiveStake` that will be used for `SnapShot` creation by
  -- `Cardano.Ledger.State.snapShotFromInstantStake`.
  resolveInstantStake :: InstantStake era -> Accounts era -> ActiveStake

class CanGetInstantStake t where
  instantStakeG :: SimpleGetter (t era) (InstantStake era)
  default instantStakeG :: CanSetInstantStake t => SimpleGetter (t era) (InstantStake era)
  instantStakeG = instantStakeL
  {-# INLINE instantStakeG #-}

class CanGetInstantStake t => CanSetInstantStake t where
  instantStakeL :: Lens' (t era) (InstantStake era)

-- | This is the total active stake including the rewards, but ignoring all the stake coming from
-- the pointers. Where "active" stake means any stake credential that is registered and delegated to
-- a stake pool.
resolveActiveInstantStakeCredentials ::
  EraStake era =>
  InstantStake era ->
  Accounts era ->
  Map (Credential Staking) StakeWithDelegation
resolveActiveInstantStakeCredentials instantStake accounts =
  Map.merge
    Map.dropMissing -- ignore non-registered stake credentials
    (Map.mapMaybeMissing (const getNonZeroActiveStakeWithDelegation)) -- use the account balance, unless it is zero
    (Map.zipWithMaybeAMatched addInstantActiveStakeWithDelegation) -- combine the stake with the account balance
    (instantStake ^. instantStakeCredentialsL)
    (accounts ^. accountsMapL)
  where
    -- Only return non-zero balance bundled with delegation for active accounts.
    getNonZeroActiveStakeWithDelegation accountState = do
      poolId <- accountState ^. stakePoolDelegationAccountStateL
      nzBalance <- nonZero $ accountState ^. balanceAccountStateL
      pure $! StakeWithDelegation nzBalance poolId
    {-# INLINE getNonZeroActiveStakeWithDelegation #-}
    -- Adds instant stake to any active staking credential, bundling with delegation
    addInstantActiveStakeWithDelegation _ stake accountState = Identity $ do
      poolId <- accountState ^. stakePoolDelegationAccountStateL
      let balance = accountState ^. balanceAccountStateL
      -- instant stake is guaranteed to be non-zero due to minUTxO, so no need to guard against mempty
      pure $! StakeWithDelegation (unsafeNonZero $ stake <> balance) poolId
    {-# INLINE addInstantActiveStakeWithDelegation #-}
{-# INLINEABLE resolveActiveInstantStakeCredentials #-}
