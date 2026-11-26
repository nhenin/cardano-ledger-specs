{-# OPTIONS_GHC -Wno-orphans #-}

-- | Alonzo's amounts for shared transaction accounting. All ADA in the selected
-- collateral inputs becomes fees; this era has no collateral return or treasury
-- donation field. The shared flow selects when to apply these amounts.
module Cardano.Ledger.Alonzo.State.Accounting () where

import Cardano.Ledger.Alonzo.Era (AlonzoEra)
import Cardano.Ledger.Alonzo.Tx ()
import Cardano.Ledger.Core (EraTxBody (collateralInputsTxBodyG))
import Cardano.Ledger.State.Accounting (EraAccounting (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Cardano.Ledger.TxOut (sumAllCoin)
import Lens.Micro ((^.))

instance EraAccounting AlonzoEra where
  -- Fee = sum of collateral-input ADA in the supplied original Store.
  -- Retain sumAllCoin's existing arithmetic.
  collateralFee store txBody =
    sumAllCoin
      . IndexedUTxOs.txOuts
      . IndexedUTxOs.restrictToInputs (txBody ^. collateralInputsTxBodyG)
      $ Store.allocations store

  -- Zero convention for an era without treasury donations.
  treasuryDonation _ = mempty
