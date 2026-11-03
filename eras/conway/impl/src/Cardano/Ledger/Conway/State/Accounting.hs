{-# OPTIONS_GHC -Wno-orphans #-}

-- | Conway's amounts for shared transaction accounting:
--
-- @
-- collateralFee = collateralInputADA - proposedReturnADA
-- @
--
-- An absent return contributes zero. The return is the body's proposal, even
-- when a retained-key collision prevents insertion. The shared flow credits
-- the body's declared treasury donation only on the valid path.
module Cardano.Ledger.Conway.State.Accounting () where

import Cardano.Ledger.Babbage.Collateral (collAdaBalance)
import Cardano.Ledger.Coin (Coin (..), DeltaCoin (..))
import Cardano.Ledger.Conway.Era (ConwayEra)
import Cardano.Ledger.Conway.Tx ()
import Cardano.Ledger.Conway.TxBody (ConwayEraTxBody (treasuryDonationTxBodyL))
import Cardano.Ledger.Core (EraTxBody (collateralInputsTxBodyG))
import Cardano.Ledger.State.Accounting (EraAccounting (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Lens.Micro ((^.))

instance EraAccounting ConwayEra where
  -- Select collateral from the original Store and retain collAdaBalance's
  -- proposed-return treatment and exact DeltaCoin-to-Coin conversion.
  collateralFee store txBody =
    let consumed =
          IndexedUTxOs.txOuts $
            IndexedUTxOs.restrictToInputs (txBody ^. collateralInputsTxBodyG) (Store.allocations store)
        DeltaCoin fee = collAdaBalance txBody consumed
     in Coin fee

  -- Read the declared amount; the shared flow decides whether to credit it.
  treasuryDonation txBody = txBody ^. treasuryDonationTxBodyL
