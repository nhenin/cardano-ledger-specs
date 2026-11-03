{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

-- | Donations awaiting transfer to the treasury. Only phase-2-valid
-- transactions contribute; a failed transaction leaves this pot unchanged.
module Cardano.Ledger.State.Accounting.Donation (
  projectTx,
) where

import Cardano.Ledger.Core (EraTx (Tx, bodyTxL, isPhase2ValidTxG), IsPhase2Valid (..), TopTx)
import Cardano.Ledger.State.Accounting.Era (EraAccounting (treasuryDonation))
import Cardano.Ledger.State.Accounting.State (AccountingState, asDonationL)
import Lens.Micro ((&), (<>~), (^.))

-- | Credit the era's declared donation when ordinary transaction effects apply.
projectTx ::
  (EraAccounting era, Applicative m) =>
  Tx TopTx era ->
  AccountingState era ->
  m (AccountingState era)
projectTx tx accountingState =
  case tx ^. isPhase2ValidTxG of
    Phase2Valid ->
      pure $ accountingState & asDonationL <>~ treasuryDonation (tx ^. bodyTxL)
    Phase2Invalid -> pure accountingState
