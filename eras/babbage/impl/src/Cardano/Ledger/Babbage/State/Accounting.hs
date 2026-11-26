{-# OPTIONS_GHC -Wno-orphans #-}

-- | Babbage's amounts for shared transaction accounting:
--
-- @
-- collateralFee = collateralInputADA - proposedReturnADA
-- @
--
-- An absent return contributes zero. The return is the body's proposal, even
-- when a retained-key collision prevents insertion. Treasury donations are
-- unsupported; the shared flow selects when to apply these amounts.
module Cardano.Ledger.Babbage.State.Accounting () where

import Cardano.Ledger.Babbage.Collateral (collAdaBalance)
import Cardano.Ledger.Babbage.Era (BabbageEra)
import Cardano.Ledger.Babbage.Tx ()
import Cardano.Ledger.Coin (Coin (..), DeltaCoin (..))
import Cardano.Ledger.Core (EraTxBody (collateralInputsTxBodyG))
import Cardano.Ledger.State.Accounting (EraAccounting (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Lens.Micro ((^.))

instance EraAccounting BabbageEra where
  -- Select collateral from the original Store and retain collAdaBalance's
  -- proposed-return treatment and exact DeltaCoin-to-Coin conversion.
  collateralFee store txBody =
    let consumed =
          IndexedUTxOs.txOuts $
            IndexedUTxOs.restrictToInputs (txBody ^. collateralInputsTxBodyG) (Store.allocations store)
        DeltaCoin fee = collAdaBalance txBody consumed
     in Coin fee

  -- Zero convention for an era without treasury donations.
  treasuryDonation _ = mempty
