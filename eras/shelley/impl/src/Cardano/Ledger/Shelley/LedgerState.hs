{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- |
-- Module      : LedgerState
-- Description : Operational Rules
--
-- This module implements the operation rules for treating UTxO transactions ('Tx')
-- as state transformations on a ledger state ('LedgerState'),
-- as specified in /A Simplified Formal Specification of a UTxO Ledger/.
module Cardano.Ledger.Shelley.LedgerState (
  -- * UTxO
  IndexedUTxOs (..),
  CanGetUTxOStore (..),
  CanSetUTxOStore (..),

  -- * Ledger state
  LedgerState (..),
  lsAccountingStateL,
  lsCertStateL,
  lsGovStateL,

  -- * Accounting
  AccountingState (..),
  smartAccountingState,
  asDepositedL,
  asFeesL,
  asDonationL,
  asUTxOStoreL,
  asInstantStakeL,

  -- * Certificates
  AccountState,
  EraCertState (..),
  DState (..),
  FutureGenDeleg (..),
  InstantaneousRewards (..),
  PState (..),
  mkShelleyCertState,
  ShelleyCertState (..),

  -- * Genesis State
  genesisState,

  -- * DelegationState
  totalObligation,
  allObligations,

  -- * Epoch boundary
  ChainAccountState,
  EpochState (..),
  PulsingRewUpdate (..),
  RewardUpdate (..),
  RewardSnapShot (..),
  applyRUpd,
  applyRUpdFiltered,
  filterAllRewards,
  FilteredRewards (..),
  createRUpd,
  completeRupd,
  startStep,
  pulseStep,
  completeStep,
  NewEpochState (NewEpochState, nesEL, nesEs, nesRu, nesBprev, nesBcur),
  StashedAVVMAddresses,
  stashedAVVMAddresses,
  getGKeys,
  updateNES,
  circulation,

  -- * Decay
  decayFactor,

  -- * Remove Bootstrap Redeem Addresses
  returnRedeemAddrsToReserves,
  updateNonMyopic,
  emptyRewardUpdate,
  pvCanFollow,
  availableAfterMIR,
  ShelleyGovState (..),

  -- * Lenses from Types
  nesEsL,
  nesELL,
  nesBprevL,
  nesBcurL,
  nesRuL,
  nesStashedAVVMAddressesL,
  nesEpochStateL,
  esSnapshotsL,
  esLStateL,
  esNonMyopicL,
  curPParamsEpochStateL,
  prevPParamsEpochStateL,
  futurePParamsEpochStateL,
  epochStateGovStateL,
  epochStateStakeDistrL,
  epochStateStakePoolsL,
  epochStateDonationL,
  newEpochStateGovStateL,
  nesStakePoolDistrG,

  -- * Lenses from CertState
  dsGenDelegsL,
  dsIRewardsL,
  dsFutureGenDelegsL,
  psStakePoolsL,
  psFutureStakePoolParamsL,
  psRetiringL,
  psVRFKeyHashesL,

  -- * Lenses from SnapShot(s)
  ssStakeMarkL,
  ssStakeSetL,
  ssStakeGoL,
  ssFeeL,
  ssStakeL,
  msSnapShotL,
  ssSnapShotL,
  gsSnapShotL,
) where

import Cardano.Ledger.Shelley.LedgerState.IncrementalStake
import Cardano.Ledger.Shelley.LedgerState.NewEpochState
import Cardano.Ledger.Shelley.LedgerState.PulsingReward
import Cardano.Ledger.Shelley.LedgerState.Types
import Cardano.Ledger.Shelley.PParams (pvCanFollow)
import Cardano.Ledger.Shelley.RewardUpdate
import Cardano.Ledger.Shelley.Rules.Ppup (ShelleyGovState (..))
import Cardano.Ledger.Shelley.State
