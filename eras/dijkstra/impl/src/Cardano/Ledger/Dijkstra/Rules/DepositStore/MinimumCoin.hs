{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Proposed legacy outputs must contain the deposit priced by the active
-- Store formula. New outputs fund it externally through declaration accounting.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.MinimumCoin (
  validateMinimumCoin,
) where

import Cardano.Ledger.Babbage.Rules (BabbageUtxoPredFailure (BabbageOutputTooSmallUTxO))
import Cardano.Ledger.Babbage.TxOut (BabbageEraTxOut)
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula as Formula
import Cardano.Ledger.Mary.Value (MaryValue)
import Cardano.Ledger.Rules.ValidationMode (Test)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositAmount (toCoin), DepositFormula)
import Cardano.Ledger.TxOut (EraLegacyTxOut (valueTxOutL), TxOut (..), Value)
import qualified Cardano.Ledger.Val as Val
import Control.State.Transition.Extended (failureOnNonEmpty)
import Data.Foldable (toList)
import Data.Maybe (mapMaybe)
import Lens.Micro ((&), (^.))

-- | The full required deposit is checked before allocation; it is never capped
-- by the proposed ADA. Preserve the existing pointwise check so negative native
-- asset quantities also fail. Callers include TopTx's collateral return.
validateMinimumCoin ::
  (BabbageEraTxOut era, Value era ~ MaryValue, Foldable f) =>
  DepositFormula ->
  f (TxOut era) ->
  Test (BabbageUtxoPredFailure era)
validateMinimumCoin pricing outputs =
  failureOnNonEmpty
    ( mapMaybe
        ( \case
            NewTxOut _ -> Nothing
            output@(LegacyTxOut legacy) ->
              toCoin (Formula.computeDeposit pricing output)
                & \requiredDeposit ->
                  if Val.pointwise (>=) (legacy ^. valueTxOutL) (Val.inject requiredDeposit)
                    then Nothing
                    else Just (output, requiredDeposit)
        )
        (toList outputs)
    )
    BabbageOutputTooSmallUTxO
