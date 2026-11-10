-- | Failures while preparing deposit funding and settlement.
module Cardano.Ledger.Api.Tx.Body.DepositBalance.Error (NetBalanceError (..)) where

import Cardano.Ledger.BaseTypes (TxIx)
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.TxIn (TxIn)

data NetBalanceError
  = UnresolvedSpendingInput !TxIn
  | UnresolvedTopUpInput !TxIn
  | UnresolvedDepositOutput !TxIx
  | MissingTopTxRefund !Coin
  | RefundOutputConsumesRelease !Coin !Coin
  | RefundOutputIndexOutOfRange !Int
  | TopUpInputUsedBySubTx !TxIn
  deriving (Eq, Show)
