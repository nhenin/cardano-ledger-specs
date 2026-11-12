{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

-- | The certificate and governance deposit pot. Valid transactions collect
-- deposits and pay refunds; phase-2-invalid transactions preserve the pot.
-- Output deposits are maintained separately by the UTxO Store.
module Cardano.Ledger.State.Accounting.Deposits (
  projectTx,
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core (
  EraTx (Tx, bodyTxL, isPhase2ValidTxG),
  IsPhase2Valid (..),
  PParams,
  TopTx,
 )
import Cardano.Ledger.State.Accounting.State (AccountingState, asDepositedL)
import Cardano.Ledger.State.Certificates (
  EraCertState (CertState, certDStateL, certsTotalDepositsTxBody, certsTotalRefundsTxBody),
 )
import Cardano.Ledger.State.Certificates.Account (CanSetAccounts (accountsL))
import Cardano.Ledger.Val ((<->))
import Lens.Micro ((&), (<>~), (^.))

-- | Use the supplied original certificate state to calculate refunds. Preserve
-- the net change for event emission, including zero. Invalid transactions leave
-- the pot unchanged and return a zero delta; the calling rule emits no event.
projectTx ::
  (EraTx era, EraCertState era) =>
  PParams era ->
  CertState era ->
  Tx TopTx era ->
  AccountingState era ->
  (Coin, AccountingState era)
projectTx pp certState tx accountingState =
  case tx ^. isPhase2ValidTxG of
    Phase2Valid ->
      let netDepositChange =
            certsTotalDepositsTxBody pp certState (tx ^. bodyTxL)
              <-> certsTotalRefundsTxBody pp (certState ^. certDStateL . accountsL) (tx ^. bodyTxL)
       in (netDepositChange, accountingState & asDepositedL <>~ netDepositChange)
    Phase2Invalid -> (mempty, accountingState)
