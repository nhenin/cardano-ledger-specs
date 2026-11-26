{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Figure 2: Functions related to fees and collateral
--   Babbage Specification
module Cardano.Ledger.Babbage.Collateral (
  collAdaBalance,
  collOuts,
  mkCollateralTxIn,
) where

import Cardano.Ledger.Babbage.PParams ()
import Cardano.Ledger.Babbage.TxBody (BabbageEraTxBody (..))
import Cardano.Ledger.Coin (DeltaCoin, toDeltaCoin)
import Cardano.Ledger.Core
import Cardano.Ledger.TxOut (sumAllCoin)
import Cardano.Ledger.Val ((<->))
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro

-- ============================================================

collAdaBalance ::
  forall era f.
  (BabbageEraTxBody era, Foldable f) =>
  TxBody TopTx era ->
  f (TxOut era) ->
  DeltaCoin
collAdaBalance txBody utxoCollateral = toDeltaCoin $
  case txBody ^. collateralReturnTxBodyL of
    SNothing -> colbal
    SJust txOut -> colbal <-> (txOut ^. coinTxOutL @era)
  where
    colbal = sumAllCoin utxoCollateral

-- | Index the proposed collateral return, preserving its supplied size.
-- The Store records its allocation origin only when the return is allocated.
collOuts ::
  BabbageEraTxBody era =>
  TxBody TopTx era ->
  IndexedTxOs era
collOuts = collateralOutputsTxBody
