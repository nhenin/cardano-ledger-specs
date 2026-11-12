{-# OPTIONS_GHC -Wno-orphans #-}

-- | Allegra's amounts for shared transaction accounting. Its phase-2 getter
-- is always valid, so the collateral path is unreachable. This era has no
-- treasury donation field.
module Cardano.Ledger.Allegra.State.Accounting () where

import Cardano.Ledger.Allegra.Era (AllegraEra)
import Cardano.Ledger.Allegra.Tx ()
import Cardano.Ledger.State.Accounting (EraAccounting (..))

instance EraAccounting AllegraEra where
  -- Zero convention for the unreachable phase-2 failure path.
  collateralFee _ _ = mempty

  -- Zero convention for an era without treasury donations.
  treasuryDonation _ = mempty
