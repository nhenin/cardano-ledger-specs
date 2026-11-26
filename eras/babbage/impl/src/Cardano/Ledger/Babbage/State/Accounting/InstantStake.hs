{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Babbage.State.Accounting.InstantStake () where

import Cardano.Ledger.Babbage.Core ()
import Cardano.Ledger.Babbage.Era (BabbageEra)
import Cardano.Ledger.Babbage.State.Certificates.Account ()
import Cardano.Ledger.Shelley.State (
  EraStake (..),
  ShelleyInstantStake,
  addShelleyInstantStake,
  deleteShelleyInstantStake,
  resolveShelleyInstantStake,
  shelleyInstantStakeCredentialsL,
 )

instance EraStake BabbageEra where
  type InstantStake BabbageEra = ShelleyInstantStake BabbageEra
  instantStakeCredentialsL = shelleyInstantStakeCredentialsL
  addInstantStake = addShelleyInstantStake
  deleteInstantStake = deleteShelleyInstantStake
  resolveInstantStake = resolveShelleyInstantStake
