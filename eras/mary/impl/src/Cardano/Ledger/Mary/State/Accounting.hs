{-# OPTIONS_GHC -Wno-orphans #-}

-- | Mary's amounts for shared transaction accounting. Its phase-2 getter
-- is always valid, so the collateral path is unreachable. This era has no
-- treasury donation field.
module Cardano.Ledger.Mary.State.Accounting () where

import Cardano.Ledger.Mary.Era (MaryEra)
import Cardano.Ledger.Mary.Tx ()
import Cardano.Ledger.State.Accounting (EraAccounting (..))

instance EraAccounting MaryEra where
  -- Zero convention for the unreachable phase-2 failure path.
  collateralFee _ _ = mempty

  -- Zero convention for an era without treasury donations.
  treasuryDonation _ = mempty
