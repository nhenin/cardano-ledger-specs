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

import Cardano.Ledger.Babbage.Collateral (collOuts)
import Cardano.Ledger.BaseTypes (TxIx, txIxToInt)
import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..), Sized (..))
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.State (UTxOStore)
import qualified Cardano.Ledger.State as Store
import Cardano.Ledger.State.UTxOs.Deposit (ByteSize (..), DepositCalculation, calculateDeposit)
import qualified Cardano.Ledger.State.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxId, TxIn)
import Cardano.Ledger.TxOut (sumAllCoin)
import Cardano.Ledger.Val ((<->))
import Control.DeepSeq (NFData)
import Control.Monad (when)
import Data.Foldable (sequenceA_, toList)
import Data.List.NonEmpty (NonEmpty)
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
-- obligation. The supplied calculation is the Store's current pricing policy.
requiredUTxODeposit :: DepositCalculation -> Sized (TxOut era) -> Coin
requiredUTxODeposit calculation output = case sizedValue output of
  LegacyTxOut _ -> mempty
  NewTxOut _ -> calculateDeposit calculation . ByteSize $ sizedSize output

-- | The body's own regular outputs only; collateral and nested bodies are
-- accounted separately.
allocatedUTxODeposits :: DijkstraEraTxBody era => DepositCalculation -> TxBody l era -> Coin
allocatedUTxODeposits calculation body = foldMap (requiredUTxODeposit calculation) (body ^. sizedOutputsTxBodyL)

-- | Release historical deposits selected by this body's ordinary inputs.
-- The same allocation owns the output and its calculation inputs. Unknown
-- references remain the existing BadInputs rule's responsibility.
releasedUTxODeposits ::
  EraTxBody era =>
  UTxOStore era -> TxBody l era -> Coin
releasedUTxODeposits store body =
  Store.toCoin $
    IndexedUTxOs.allocatedDepositTotalAmount (body ^. inputsTxBodyL) $
      Store.allocations store

requiredNetUTxODeposit ::
  DijkstraEraTxBody era =>
  UTxOStore era -> TxBody l era -> Coin
requiredNetUTxODeposit store body =
  allocatedUTxODeposits (Store.currentCalculation store) body <-> releasedUTxODeposits store body

requiredTxTotalNetUTxODeposit ::
  (EraTx era, DijkstraEraTxBody era) =>
  UTxOStore era -> TxBody TopTx era -> Coin
requiredTxTotalNetUTxODeposit store body =
  requiredNetUTxODeposit store body
    <> foldMap (requiredNetUTxODeposit store . (^. bodyTxL)) (body ^. subTransactionsTxBodyL)

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
  UTxOStore era ->
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateOrdinaryDepositStore store body =
  validateTopTxExactness store body
    *> sequenceA_ (map (validateSubTxAccounting store . (^. bodyTxL)) children)
    *> when
      (all (hasKnownSubTxContribution store . (^. bodyTxL)) children)
      (validateTopTxSettlement body)
  where
    children = toList $ body ^. subTransactionsTxBodyL

-- | An absent nonzero contribution is already a presence failure. Do not
-- derive a misleading TopTx settlement share by treating that contribution as
-- zero. A body without a net contribution does not change the derived share.
hasKnownSubTxContribution ::
  DijkstraEraTxBody era =>
  UTxOStore era -> TxBody SubTx era -> Bool
hasKnownSubTxContribution store body
  | SubTx.hasUTxODepositDeclaration (body ^. subTxNetUTxODepositChangeTxBodyL) = True
  | otherwise = requiredNetUTxODeposit store body == mempty

-- | An explicit TopTx declaration describes the complete transaction's net
-- deposit change, including every SubTx exactly once.
validateTopTxExactness ::
  (EraTx era, DijkstraEraTxBody era) =>
  UTxOStore era ->
  TxBody TopTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateTopTxExactness store body
  | TopTx.hasUTxODepositDeclaration declaration =
      failureUnless (supplied == required) (InexactTopTxDepositChange supplied required)
  | otherwise = pure ()
  where
    declaration = body ^. netUTxODepositChangeTxBodyL
    supplied = declaredTopTxNetUTxODeposit declaration
    required = requiredTxTotalNetUTxODeposit store body

-- | An explicit SubTx declaration describes only that body's own net deposit
-- change. Delegation affects responsibility, not the required signed amount.
validateSubTxExactness ::
  DijkstraEraTxBody era =>
  UTxOStore era ->
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateSubTxExactness store body
  | SubTx.hasUTxODepositDeclaration declaration =
      failureUnless (supplied == required) (InexactSubTxDepositChange (txIdTxBody body) supplied required)
  | otherwise = pure ()
  where
    declaration = body ^. subTxNetUTxODepositChangeTxBodyL
    supplied = declaredSubTxNetUTxODeposit declaration
    required = requiredNetUTxODeposit store body

-- | Validate the originating amount before checking its local settlement target.
validateSubTxAccounting ::
  DijkstraEraTxBody era =>
  UTxOStore era ->
  TxBody SubTx era ->
  Validation (NonEmpty DepositStoreAccountingFailure) ()
validateSubTxAccounting store body =
  validateSubTxExactness store body
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

-- | Release this body's inputs and allocate its regular outputs. SubTxs and
-- TopTx each apply their own effects once; complete-batch validation reads the
-- original store. Every new allocation records its accepted size and current rate.
applyBodyAllocations ::
  DijkstraEraTxBody era =>
  TxBody l era ->
  UTxOStore era ->
  UTxOStore era
applyBodyAllocations body =
  Store.allocate (outputsTxBody body)
    . Store.release (body ^. inputsTxBodyL)

-- | On phase-2 failure, release only the collateral inputs and allocate the
-- collateral return. Ordinary TopTx/SubTx allocations remain untouched.
applyCollateralAllocations ::
  DijkstraEraTxBody era =>
  TxBody TopTx era ->
  UTxOStore era ->
  UTxOStore era
applyCollateralAllocations body =
  Store.allocate (collOuts body)
    . Store.release (body ^. collateralInputsTxBodyL)

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
  UTxOStore era ->
  TxBody TopTx era ->
  CollateralDepositSettlement
collateralDepositSettlement store body =
  let consumed = body ^. collateralInputsTxBodyL
      consumedAllocations = IndexedUTxOs.restrictToInputs consumed $ Store.allocations store
      collateralOutputs = IndexedUTxOs.txOuts consumedAllocations
      released = Store.toCoin $ IndexedUTxOs.sumDepositAmounts consumedAllocations
      returnDeposit =
        foldMap
          (requiredUTxODeposit $ Store.currentCalculation store)
          (body ^. sizedCollateralReturnTxBodyL)
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
