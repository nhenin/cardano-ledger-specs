{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Alonzo.State.Accounting.InstantStake () where

import Cardano.Ledger.Alonzo.Core ()
import Cardano.Ledger.Alonzo.Era (AlonzoEra)
import Cardano.Ledger.Alonzo.State.Certificates.Account ()
import Cardano.Ledger.Shelley.State (
  EraStake (..),
  ShelleyInstantStake,
  addShelleyInstantStake,
  deleteShelleyInstantStake,
  resolveShelleyInstantStake,
  shelleyInstantStakeCredentialsL,
 )

instance EraStake AlonzoEra where
  type InstantStake AlonzoEra = ShelleyInstantStake AlonzoEra
  instantStakeCredentialsL = shelleyInstantStakeCredentialsL
  addInstantStake = addShelleyInstantStake
  deleteInstantStake = deleteShelleyInstantStake
  resolveInstantStake = resolveShelleyInstantStake
