{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Collateral funds its own storage before covering the minimum fee. Released
-- deposits left after funding the return reach the fee pot without relaxing
-- either requirement.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.Collateral (
  validateCollateralFunding,
) where

import qualified Cardano.Ledger.Alonzo.Rules as Alonzo
import Cardano.Ledger.Babbage.Collateral (collAdaBalance)
import qualified Cardano.Ledger.Babbage.Rules as Babbage
import Cardano.Ledger.Coin (toDeltaCoin)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting (
  CollateralDepositSettlement (..),
  collateralDepositSettlement,
 )
import Cardano.Ledger.State (UTxOStore)
import qualified Cardano.Ledger.State as Store
import qualified Cardano.Ledger.State.UTxOs.Allocations as Allocations
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.TxOut (sumAllAssets)
import qualified Cardano.Ledger.Val as Val
import Data.Bifunctor (first)
import Data.Foldable (sequenceA_)
import Data.List.NonEmpty (NonEmpty)
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro ((^.))
import Validation (Validation, failureUnless)

-- | Preserve existing collateral eligibility, native-asset conservation and
-- optional-total semantics for both output variants. The minimum fee is funded
-- by application coins after any additional return deposit; released deposit
-- surplus cannot satisfy that minimum or pay for a larger return output.
validateCollateralFunding ::
  forall era rule.
  ( DijkstraEraTxBody era
  , InjectRuleFailure rule Alonzo.AlonzoUtxoPredFailure era
  , InjectRuleFailure rule Babbage.BabbageUtxoPredFailure era
  ) =>
  PParams era ->
  TxBody TopTx era ->
  UTxOStore era ->
  Validation (NonEmpty (EraRuleFailure rule era)) ()
validateCollateralFunding pp body store =
  let settlement = collateralDepositSettlement pp store body
      collateralAllocations =
        Allocations.restrictToInputs (body ^. collateralInputsTxBodyL) $ Store.allocations store
      -- The inherited collateral validators require a keyed output map, including
      -- the offending inputs in predicate failures. Project only selected entries.
      collateralInputs =
        Allocations.toTxOutMap collateralAllocations
   in sequenceA_
        [ first (fmap injectFailure) $ Alonzo.validateScriptsNotPaidUTxO collateralInputs
        , first (fmap injectFailure) $ validateCollateralAssets body collateralInputs
        , first (fmap injectFailure) $
            Alonzo.validateInsufficientCollateral pp body $
              toDeltaCoin $
                collateralCoinFee settlement
        , first (fmap injectFailure) $
            Babbage.validateCollateralEqBalance
              (collAdaBalance body collateralInputs)
              (body ^. totalCollateralTxBodyL)
        , failureUnless (not $ Map.null collateralInputs) (injectFailure $ Alonzo.NoCollateralInputs @era)
        ]

-- | Both output forms carry application assets. Every non-ADA asset consumed as
-- collateral must be returned with its exact quantity, including when the
-- collateral return itself is store-backed.
validateCollateralAssets ::
  BabbageEraTxBody era =>
  TxBody TopTx era ->
  Map.Map TxIn (TxOut era) ->
  Validation (NonEmpty (Alonzo.AlonzoUtxoPredFailure era)) ()
validateCollateralAssets body collateralInputs =
  let consumedAssets = unAssets $ sumAllAssets collateralInputs
      returnAssets = unAssets $ sumAllAssets (body ^. collateralReturnTxBodyL)
      reportedAssets = case body ^. collateralReturnTxBodyL of
        SJust _ | Val.isAdaOnly consumedAssets -> returnAssets
        _ -> consumedAssets
   in failureUnless
        (Val.isAdaOnly $ consumedAssets Val.<-> returnAssets)
        (Alonzo.CollateralContainsNonADA reportedAssets)
