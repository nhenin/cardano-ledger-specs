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
import Cardano.Ledger.BaseTypes (TxIx (..), txIxFromIntegral)
import Cardano.Ledger.Coin (DeltaCoin, toDeltaCoin)
import Cardano.Ledger.Core
import Cardano.Ledger.TxIn (TxIn (..))
import Cardano.Ledger.TxOut (sumAllCoin)
import qualified Cardano.Ledger.TxOut.IndexedTxOs as IndexedTxOs
import Cardano.Ledger.Val ((<->))
import Data.Maybe.Strict (StrictMaybe (..))
import Data.Word (Word16)
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
-- The Store records its calculation only when the return is allocated.
collOuts ::
  BabbageEraTxBody era =>
  TxBody TopTx era ->
  IndexedTxOs era
collOuts txBody =
  case txBody ^. sizedCollateralReturnTxBodyL of
    SNothing -> mempty
    SJust output -> IndexedTxOs.singleton (mkCollateralTxIn txBody) output

mkCollateralTxIn :: EraTxBody era => TxBody l era -> TxIn
mkCollateralTxIn txBody = TxIn (txIdTxBody txBody) txIx
  where
    txIx = case txIxFromIntegral (length (txBody ^. outputsTxBodyL)) of
      Just i -> i
      -- In the impossible event that there are more transaction outputs
      -- in the transaction than will fit into a Word16 (which backs the TxIx),
      -- we give the collateral return output an index of maxBound.
      Nothing -> TxIx (maxBound :: Word16)
