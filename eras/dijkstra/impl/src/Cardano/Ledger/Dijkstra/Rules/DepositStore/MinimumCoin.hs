{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Proposed min-ADA outputs must contain the deposit priced by the active
-- Store formula. New outputs fund it externally through declaration accounting.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.MinimumCoin (
  validateMinimumCoin,
) where

import Cardano.Ledger.Babbage.Rules (BabbageUtxoPredFailure (BabbageOutputTooSmallUTxO))
import Cardano.Ledger.Babbage.TxBody (BabbageEraTxBody (allSizedOutputsTxBodyF))
import Cardano.Ledger.Binary (Sized (sizedValue))
import Cardano.Ledger.Core (TxBody)
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula as Formula
import Cardano.Ledger.Mary.Value (MaryValue)
import Cardano.Ledger.Rules.ValidationMode (Test)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositAmount (toCoin), DepositFormula)
import Cardano.Ledger.TxOut (EraMinAdaTxOut (valueTxOutL), TxOut (..), Value)
import qualified Cardano.Ledger.Val as Val
import Control.State.Transition.Extended (failureOnNonEmpty)
import Data.Foldable (toList)
import Data.Maybe (mapMaybe)
import Lens.Micro ((&), (^.))

-- | The full required deposit is checked before allocation; it is never capped
-- by the proposed ADA. Preserve the existing pointwise check so negative native
-- asset quantities also fail. The TopTx output collection includes its collateral return.
validateMinimumCoin ::
  (BabbageEraTxBody era, Value era ~ MaryValue) =>
  DepositFormula ->
  TxBody l era ->
  Test (BabbageUtxoPredFailure era)
validateMinimumCoin pricing body =
  failureOnNonEmpty
    ( mapMaybe
        ( \case
            DepositBackedTxOut _ -> Nothing
            output@(MinAdaTxOut legacy) ->
              toCoin (Formula.computeDeposit pricing output)
                & \requiredDeposit ->
                  if Val.pointwise (>=) (legacy ^. valueTxOutL) (Val.inject requiredDeposit)
                    then Nothing
                    else Just (output, requiredDeposit)
        )
        (map sizedValue . toList $ body ^. allSizedOutputsTxBodyF)
    )
    BabbageOutputTooSmallUTxO
