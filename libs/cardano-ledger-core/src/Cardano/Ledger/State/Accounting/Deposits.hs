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

-- | Report the deposit change before applying it. Use the supplied original
-- certificate state for refunds. Invalid transactions neither change this pot
-- nor report a deposit event.
projectTx ::
  (EraTx era, EraCertState era, Monad m) =>
  PParams era ->
  CertState era ->
  Tx TopTx era ->
  (Coin -> m ()) ->
  AccountingState era ->
  m (AccountingState era)
projectTx pp certState tx depositChangeEvent accountingState =
  case tx ^. isPhase2ValidTxG of
    Phase2Valid -> do
      let depositChange =
            certsTotalDepositsTxBody pp certState (tx ^. bodyTxL)
              <-> certsTotalRefundsTxBody pp (certState ^. certDStateL . accountsL) (tx ^. bodyTxL)
      depositChangeEvent depositChange
      pure $! accountingState & asDepositedL <>~ depositChange
    Phase2Invalid -> pure $! accountingState
