{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | Exact UTxO capacity deposit accounting. Input allocations are recorded
-- ledger obligations; only newly created outputs are priced. Transaction
-- declarations authorize the resulting net transfer, never a second transfer
-- alongside their SubTx contributions.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting (
  DepositStoreAccountingFailure (..),
  requiredUTxODeposit,
  allocatedUTxODeposits,
  releasedUTxODeposits,
  requiredNetUTxODeposit,
  requiredTxTotalNetUTxODeposit,
  declaredTopTxNetUTxODeposit,
  declaredSubTxNetUTxODeposit,
  locallyAccountedSubTxNetUTxODeposit,
  attributedTopTxNetUTxODeposit,
  validateTopTxExactness,
  validateSubTxExactness,
  validateTopTxSettlement,
  validateSettlementOutput,
  validateOrdinaryDepositStore,
  applyBodyAllocations,
  applyCollateralAllocations,
  CollateralDepositSettlement (..),
  collateralDepositSettlement,
) where

import Cardano.Ledger.Babbage.Collateral (mkCollateralTxIn)
import Cardano.Ledger.Babbage.TxOut (babbageMinUTxOValue)
import Cardano.Ledger.BaseTypes (TxIx, txIxToInt)
import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..), Sized (..))
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.State (
  OutputStoreError,
  UTxOStore,
  Unspent,
 )
import qualified Cardano.Ledger.State as Store
import qualified Cardano.Ledger.State.UTxOs.Allocations as Allocations
import qualified Cardano.Ledger.State.UTxOs.Allocations.UTxO as UTxO
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxId, TxIn (..))
import Cardano.Ledger.TxOut (sumAllCoin)
import Cardano.Ledger.Val ((<->))
import Control.DeepSeq (NFData)
import Control.Monad (when)
import Data.Foldable (sequenceA_, toList)
import Data.List.NonEmpty (NonEmpty)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import GHC.Generics (Generic)
import Lens.Micro ((^.))
import Validation (Validation, failureUnless)

-- | Supplied and required amounts are signed: allocations are positive and
-- releases are negative. The first three constructors retain historical codec
-- tags; the owning allocation map now guarantees their former consistency
-- conditions. Declaration failures describe the transaction being validated.
data DepositStoreAccountingFailure
  = MissingDepositAllocation !TxIn
  | UnexpectedDepositAllocation !TxIn
  | NegativeDepositAllocation !TxIn !Coin
  | InexactTopTxDepositChange !Coin !Coin
  | InexactSubTxDepositChange !TxId !Coin !Coin
  | MissingTopTxSettlement !Coin
  | UnexpectedTopTxSettlement !TxIx
  | InvalidSettlementOutput !TxId !TxIx
  | InsufficientSettlementOutput !TxId !TxIx !Coin !Coin
  deriving (Eq, Ord, Show, Generic)

instance NFData DepositStoreAccountingFailure

instance EncCBOR DepositStoreAccountingFailure where
  encCBOR =
    encode . \case
      MissingDepositAllocation input -> Sum MissingDepositAllocation 0 !> To input
      UnexpectedDepositAllocation input -> Sum UnexpectedDepositAllocation 1 !> To input
      NegativeDepositAllocation input amount -> Sum NegativeDepositAllocation 2 !> To input !> To amount
      InexactTopTxDepositChange supplied required -> Sum InexactTopTxDepositChange 3 !> To supplied !> To required
      InexactSubTxDepositChange body supplied required -> Sum InexactSubTxDepositChange 4 !> To body !> To supplied !> To required
      MissingTopTxSettlement required -> Sum MissingTopTxSettlement 5 !> To required
      UnexpectedTopTxSettlement index -> Sum UnexpectedTopTxSettlement 6 !> To index
      InvalidSettlementOutput body index -> Sum InvalidSettlementOutput 7 !> To body !> To index
      InsufficientSettlementOutput body index supplied required -> Sum InsufficientSettlementOutput 8 !> To body !> To index !> To supplied !> To required

instance DecCBOR DepositStoreAccountingFailure where
  decCBOR = decode $ Summands "DepositStoreAccountingFailure" $ \case
    0 -> SumD MissingDepositAllocation <! From
    1 -> SumD UnexpectedDepositAllocation <! From
    2 -> SumD (\input amount -> NegativeDepositAllocation input (Coin amount)) <! From <! From
    3 ->
      SumD (\supplied required -> InexactTopTxDepositChange (Coin supplied) (Coin required))
        <! From
        <! From
    4 ->
      SumD (\body supplied required -> InexactSubTxDepositChange body (Coin supplied) (Coin required))
        <! From
        <! From
        <! From
    5 -> SumD MissingTopTxSettlement <! From
    6 -> SumD UnexpectedTopTxSettlement <! From
    7 -> SumD InvalidSettlementOutput <! From <! From
    8 -> SumD InsufficientSettlementOutput <! From <! From <! From <! From
    -- Tag 9 belonged to the removed independent-balance solvency failure.
    tag -> Invalid tag

-- | Price the accepted serialized size of a new output, including its output
-- variant. Implicit deposits are already in the output coins and add no Store
-- obligation. The byte-price formula and 160-byte overhead match Babbage.
requiredUTxODeposit :: BabbageEraPParams era => PParams era -> Sized (TxOut era) -> Coin
requiredUTxODeposit pp output = case sizedValue output of
  LegacyTxOut _ -> mempty
  NewTxOut _ -> babbageMinUTxOValue pp output

-- | The body's own regular outputs only; collateral and nested bodies are
-- accounted separately.
allocatedUTxODeposits :: DijkstraEraTxBody era => PParams era -> TxBody l era -> Coin
allocatedUTxODeposits pp body = foldMap (requiredUTxODeposit pp) (body ^. sizedOutputsTxBodyL)

-- | Release historical deposits selected by this body's ordinary inputs.
-- The same allocation owns the output and its calculation inputs. Unknown
-- references remain the existing BadInputs rule's responsibility.
releasedUTxODeposits ::
  EraTxBody era =>
  UTxOStore era -> TxBody l era -> Coin
releasedUTxODeposits store body =
  Store.toCoin $
    Allocations.allocatedDepositTotalAmount (body ^. inputsTxBodyL) $
      Store.allocations store

requiredNetUTxODeposit ::
  DijkstraEraTxBody era =>
  PParams era -> UTxOStore era -> TxBody l era -> Coin
requiredNetUTxODeposit pp store body =
  allocatedUTxODeposits pp body <-> releasedUTxODeposits store body

requiredTxTotalNetUTxODeposit ::
  (EraTx era, DijkstraEraTxBody era) =>
  PParams era -> UTxOStore era -> TxBody TopTx era -> Coin
requiredTxTotalNetUTxODeposit pp store body =
  requiredNetUTxODeposit pp store body
    <> foldMap (requiredNetUTxODeposit pp store . (^. bodyTxL)) (body ^. subTransactionsTxBodyL)

-- | Monetary transfer described by TopTx. Absence contributes no transfer;
-- presence and exactness are validated independently.
declaredTopTxNetUTxODeposit :: TopTx.TopTxUTxODepositDeclaration -> Coin
declaredTopTxNetUTxODeposit = \case
  TopTx.NoUTxODepositDeclaration -> mempty
  TopTx.DeclaresZeroNetUTxODeposit -> mempty
  TopTx.DeclaresNetUTxODepositAllocation amount -> unStrictlyPositiveCoin amount
  TopTx.DeclaresNetUTxODepositRelease amount _ -> mempty <-> unStrictlyPositiveCoin amount

-- | The originating SubTx contribution, unchanged by delegation.
declaredSubTxNetUTxODeposit :: SubTx.SubTxUTxODepositDeclaration -> Coin
declaredSubTxNetUTxODeposit = \case
  SubTx.NoUTxODepositDeclaration -> mempty
  SubTx.DeclaresZeroNetUTxODeposit -> mempty
  SubTx.DeclaresNetUTxODepositAllocation amount -> unStrictlyPositiveCoin amount
  SubTx.RequestsUTxODepositFromTopTx amount -> unStrictlyPositiveCoin amount
  SubTx.DeclaresNetUTxODepositRelease amount _ -> mempty <-> unStrictlyPositiveCoin amount

-- | Delegation changes attribution, not the batch contribution or its amount.
locallyAccountedSubTxNetUTxODeposit :: SubTx.SubTxUTxODepositDeclaration -> Coin
locallyAccountedSubTxNetUTxODeposit = \case
  SubTx.RequestsUTxODepositFromTopTx _ -> mempty
  SubTx.DeclaresNetUTxODepositRelease _ SubTx.DelegateToTopTx -> mempty
  declaration -> declaredSubTxNetUTxODeposit declaration

-- | TopTx owns the declared total after removing locally accounted child shares.
-- Requested allocations and delegated releases therefore remain with TopTx. This
-- signed amount is shared by settlement selection and legacy self-balance; exactness
-- separately establishes that the total and every originating contribution are valid.
attributedTopTxNetUTxODeposit ::
  (EraTx era, DijkstraEraTxBody era) => TxBody TopTx era -> Coin
attributedTopTxNetUTxODeposit body =
  declaredTopTxNetUTxODeposit (body ^. netUTxODepositChangeTxBodyL)
    <-> foldMap
      (locallyAccountedSubTxNetUTxODeposit . (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL))
      (body ^. subTransactionsTxBodyL)

-- | Validate the hypothetical ordinary transaction regardless of the eventual
-- script outcome. Missing declarations are owned by presence rules; amount
-- and settlement validation do not manufacture further failures for absence.
validateOrdinaryDepositStore ::
  (EraTx era, DijkstraEraTxBody era) =>
  PParams era ->
  UTxOStore era ->
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateOrdinaryDepositStore pp store body =
  validateTopTxExactness pp store body
    *> sequenceA_ (map (validateSubTxAccounting pp store . (^. bodyTxL)) children)
    *> when
      (all (hasKnownSubTxContribution pp store . (^. bodyTxL)) children)
      (validateTopTxSettlement body)
  where
    children = toList $ body ^. subTransactionsTxBodyL

-- | An absent nonzero contribution is already a presence failure. Do not
-- derive a misleading TopTx settlement share by treating that contribution as
-- zero. A body without a net contribution does not change the derived share.
hasKnownSubTxContribution ::
  DijkstraEraTxBody era =>
  PParams era -> UTxOStore era -> TxBody SubTx era -> Bool
hasKnownSubTxContribution pp store body
  | SubTx.hasUTxODepositDeclaration (body ^. subTxNetUTxODepositChangeTxBodyL) = True
  | otherwise = requiredNetUTxODeposit pp store body == mempty

-- | An explicit TopTx declaration describes the complete transaction's net
-- deposit change, including every SubTx exactly once.
validateTopTxExactness ::
  (EraTx era, DijkstraEraTxBody era) =>
  PParams era ->
  UTxOStore era ->
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateTopTxExactness pp store body
  | TopTx.hasUTxODepositDeclaration declaration =
      failureUnless (supplied == required) (InexactTopTxDepositChange supplied required)
  | otherwise = pure ()
  where
    declaration = body ^. netUTxODepositChangeTxBodyL
    supplied = declaredTopTxNetUTxODeposit declaration
    required = requiredTxTotalNetUTxODeposit pp store body

-- | An explicit SubTx declaration describes only that body's own net deposit
-- change. Delegation affects responsibility, not the required signed amount.
validateSubTxExactness ::
  DijkstraEraTxBody era =>
  PParams era ->
  UTxOStore era ->
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateSubTxExactness pp store body
  | SubTx.hasUTxODepositDeclaration declaration =
      failureUnless (supplied == required) (InexactSubTxDepositChange (txIdTxBody body) supplied required)
  | otherwise = pure ()
  where
    declaration = body ^. subTxNetUTxODepositChangeTxBodyL
    supplied = declaredSubTxNetUTxODeposit declaration
    required = requiredNetUTxODeposit pp store body

-- | Validate the originating amount before checking its local settlement target.
validateSubTxAccounting ::
  DijkstraEraTxBody era =>
  PParams era ->
  UTxOStore era ->
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateSubTxAccounting pp store body =
  validateSubTxExactness pp store body
    *> case body ^. subTxNetUTxODepositChangeTxBodyL of
      SubTx.DeclaresNetUTxODepositRelease amount (SubTx.SubTxSettlementOutput index) ->
        validateSettlementOutput body index (unStrictlyPositiveCoin amount)
      _ -> pure ()

-- | For a net-release total, designate an output exactly when TopTx's attributed
-- share is a release. Other total declaration forms carry no settlement selector.
validateTopTxSettlement ::
  (EraTx era, DijkstraEraTxBody era) =>
  TxBody TopTx era -> Validation (NonEmpty DepositStoreAccountingFailure) ()
validateTopTxSettlement body =
  case body ^. netUTxODepositChangeTxBodyL of
    TopTx.DeclaresNetUTxODepositRelease _ settlement ->
      let requiredRelease = max mempty (mempty <-> attributedTopTxNetUTxODeposit body)
       in case settlement of
            TopTx.NoTopTxSettlement -> failureUnless (requiredRelease == mempty) (MissingTopTxSettlement requiredRelease)
            TopTx.TopTxSettlementOutput index ->
              failureUnless (requiredRelease > mempty) (UnexpectedTopTxSettlement index)
                *> validateSettlementOutput body index requiredRelease
    _ -> pure ()

-- | Resolve the index within this body's regular outputs and check application ADA.
-- The output's external Store deposit does not count toward this lower bound.
validateSettlementOutput ::
  EraTxBody era =>
  TxBody l era -> TxIx -> Coin -> Validation (NonEmpty DepositStoreAccountingFailure) ()
validateSettlementOutput body index required =
  case drop (txIxToInt index) (toList $ body ^. outputsTxBodyL) of
    [] -> failureUnless False (InvalidSettlementOutput (txIdTxBody body) index)
    output : _ ->
      let supplied = output ^. coinTxOutL
       in failureUnless
            (supplied >= required)
            (InsufficientSettlementOutput (txIdTxBody body) index supplied required)

-- | Keep accepted serialized sizes when creating records. The output-reference
-- enumeration is identical to the regular UTxO output enumeration.
createdOutputAllocations ::
  DijkstraEraTxBody era =>
  PParams era -> TxBody l era -> Map TxIn (Unspent (TxOut era))
createdOutputAllocations pp body =
  let calculation = Store.DepositCalculationV1 $ pp ^. ppCoinsPerUTxOByteL
   in Map.fromList
        [ ( TxIn (txIdTxBody body) index
          , Store.Unspent {Store.sizedOutput = output, Store.depositCalculation = calculation}
          )
        | (index, output) <- zip [minBound .. maxBound] (toList $ body ^. sizedOutputsTxBodyL)
        ]

-- | Apply only this body's effects. SubTxs and TopTx each update their own
-- inputs/outputs once; complete-batch validation reads the original store.
-- The accepted size and current rate are captured for every new allocation.
applyBodyAllocations ::
  DijkstraEraTxBody era =>
  PParams era ->
  TxBody l era ->
  UTxOStore era ->
  Either OutputStoreError (UTxOStore era)
applyBodyAllocations pp body store =
  Store.applyAllocationDelta (body ^. inputsTxBodyL) (createdOutputAllocations pp body) store

-- | On phase-2 failure only the collateral inputs and return are applied.
-- The return retains the accepted size from the signed body, just like a
-- regular output. Ordinary TopTx/SubTx allocations remain untouched.
applyCollateralAllocations ::
  DijkstraEraTxBody era =>
  PParams era ->
  TxBody TopTx era ->
  UTxOStore era ->
  Either OutputStoreError (UTxOStore era)
applyCollateralAllocations pp body store =
  let created = case body ^. sizedCollateralReturnTxBodyL of
        SNothing -> mempty
        SJust output ->
          Map.singleton (mkCollateralTxIn body) $
            Store.Unspent
              { Store.sizedOutput = output
              , Store.depositCalculation = Store.DepositCalculationV1 $ pp ^. ppCoinsPerUTxOByteL
              }
   in Store.applyAllocationDelta (body ^. collateralInputsTxBodyL) created store

-- | Collateral funding distinguishes the coin-funded minimum fee from the
-- complete fee credit. Released deposit surplus is credited to fees but cannot
-- fund either the minimum fee or a larger signed return.
data CollateralDepositSettlement = CollateralDepositSettlement
  { collateralReleasedDeposits :: !Coin
  , collateralReturnDeposit :: !Coin
  , collateralAdditionalDeposit :: !Coin
  , collateralReleasedSurplus :: !Coin
  , collateralCoinFee :: !Coin
  , collateralFee :: !Coin
  }
  deriving (Eq, Show, Generic)

instance NFData CollateralDepositSettlement

collateralDepositSettlement ::
  DijkstraEraTxBody era =>
  PParams era ->
  UTxOStore era ->
  TxBody TopTx era ->
  CollateralDepositSettlement
collateralDepositSettlement pp store body =
  let consumed = body ^. collateralInputsTxBodyL
      collateralOutputs =
        Map.map UTxO.toTxOut $
          Map.restrictKeys (Store.unAllocations $ Store.allocations store) consumed
      released = Store.toCoin $ Allocations.allocatedDepositTotalAmount consumed $ Store.allocations store
      returnDeposit = foldMap (requiredUTxODeposit pp) (body ^. sizedCollateralReturnTxBodyL)
      inputCoins = sumAllCoin collateralOutputs
      returnCoins = foldMap (^. coinTxOutL) (body ^. collateralReturnTxBodyL)
      additionalDeposit = max mempty (returnDeposit <-> released)
      releasedSurplus = max mempty (released <-> returnDeposit)
      coinFee = inputCoins <-> returnCoins <-> additionalDeposit
   in CollateralDepositSettlement
        { collateralReleasedDeposits = released
        , collateralReturnDeposit = returnDeposit
        , collateralAdditionalDeposit = additionalDeposit
        , collateralReleasedSurplus = releasedSurplus
        , collateralCoinFee = coinFee
        , collateralFee = coinFee <> releasedSurplus
        }
