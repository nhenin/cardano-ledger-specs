{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Ordinary transactions sign the change in backing across minimum-ADA and
-- deposit-backed outputs. For example, replacing 1.6 ADA of embedded backing
-- with a 2 ADA external deposit signs an allocation of 0.4 ADA and adds 2 ADA
-- to the Store.
module Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting (
  -- * Ordinary transaction validation

  -- | Check the batch declaration, each declared SubTx contribution and the
  -- outputs designated to receive releases.
  validateOrdinaryDepositStore,
  DepositStoreAccountingFailure (..),
  validateTopTxExactness,
  validateSubTxExactness,
  validateTopTxSettlement,
  validateSettlementOutput,

  -- * Required backing

  -- | Price new outputs at the active formula and credit ordinary inputs at
  -- their historical formula. A minimum-ADA input contributes at most its ADA.
  requiredTxTotalNetUTxODeposit,
  requiredNetUTxODeposit,
  netUTxOBacking,
  requiredUTxOBacking,

  -- * Declared backing and settlement responsibility

  -- | A TopTx declaration gives the batch total. A SubTx declaration gives
  -- the child's own change, which it can settle locally or delegate to TopTx.
  declaredTopTxNetUTxODeposit,
  declaredSubTxNetUTxODeposit,
  locallyAccountedSubTxNetUTxODeposit,
  delegatedSubTxNetUTxODeposit,
  attributedTopTxNetUTxODeposit,

  -- * External Store deposits

  -- | A deposit-backed output moves ADA into the Store on creation and out
  -- on spend. A minimum-ADA output carries its backing in its serialized value.
  requiredUTxODeposit,
  allocatedUTxODeposits,
  releasedUTxODeposits,

  -- * Collateral settlement

  -- | Account for collateral inputs, the optional return and the fee credited
  -- when the ledger applies the phase-2 failure path.
  CollateralDepositSettlement (..),
  collateralDepositSettlement,
) where

import Cardano.Ledger.BaseTypes (TxIx, txIxToInt)
import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Declaration (
  validateSubTxAllocationDeclarationPresence,
  validateSubTxReleaseDeclarationPresence,
 )
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula as Formula
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Unspent as Unspent
import Cardano.Ledger.Mary.Value (MaryValue)
import Cardano.Ledger.State (UTxOStore)
import qualified Cardano.Ledger.State as Store
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  DepositFormula,
  DepositFormulaHistory,
  latestFormula,
 )
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxId, TxIn)
import Cardano.Ledger.TxOut (sumAllCoin)
import Cardano.Ledger.Val ((<->))
import Control.DeepSeq (NFData)
import Control.Monad (when)
import Data.Foldable (foldMap', sequenceA_, toList)
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

-- | A deposit-backed output allocates a deposit under the active formula.
-- A min-ADA output carries its reserve in its own ADA.
requiredUTxODeposit :: EraTxOut era => DepositFormula -> TxOut era -> Coin
requiredUTxODeposit formula output = case output of
  MinAdaTxOut _ -> mempty
  DepositBackedTxOut depositBacked -> getDepositTxOut formula depositBacked

-- | The body's own regular outputs only; collateral and nested bodies are
-- accounted separately.
allocatedUTxODeposits :: DijkstraEraTxBody era => DepositFormula -> TxBody l era -> Coin
allocatedUTxODeposits formula body = foldMap (requiredUTxODeposit formula) (body ^. outputsTxBodyL)

-- | Release historical deposits selected by this body's ordinary inputs.
-- The same allocation owns the output and its formula inputs. Unknown
-- references remain the existing BadInputs rule's responsibility.
releasedUTxODeposits ::
  EraTxBody era =>
  UTxOStore era -> TxBody l era -> Coin
releasedUTxODeposits store body =
  Store.toCoin $
    IndexedUTxOs.allocatedDepositTotalAmount (Store.depositFormulaHistory store) (body ^. inputsTxBodyL) $
      Store.allocations store

-- | New ordinary outputs require their full active price, including minimum-ADA outputs.
requiredUTxOBacking ::
  (BabbageEraTxOut era, Value era ~ MaryValue) => DepositFormula -> TxOut era -> Coin
requiredUTxOBacking formula = Store.toCoin . Formula.computeDeposit formula

-- | Subtract historical input backing from the active backing of the body's
-- outputs. The caller supplies only the resolved ordinary spending inputs.
netUTxOBacking ::
  DijkstraEraTxBody era =>
  DepositFormulaHistory -> TxBody l era -> IndexedUTxOs era -> Coin
netUTxOBacking history body =
  (foldMap' (requiredUTxOBacking $ latestFormula history) (body ^. outputsTxBodyL) <->)
    . foldMap' (Store.toCoin . Unspent.computeDeposit history)
    . IndexedUTxOs.unspentOutputs

-- | Resolve one body's ordinary spending inputs in the original Store and
-- compute its signed backing change.
requiredNetUTxODeposit ::
  DijkstraEraTxBody era =>
  UTxOStore era -> TxBody l era -> Coin
requiredNetUTxODeposit store body =
  netUTxOBacking (Store.depositFormulaHistory store) body $
    IndexedUTxOs.restrictToInputs (body ^. inputsTxBodyL) (Store.allocations store)

-- | Sum the required backing changes of TopTx and every SubTx, each counted once.
requiredTxTotalNetUTxODeposit ::
  (EraTx era, DijkstraEraTxBody era) =>
  UTxOStore era -> TxBody TopTx era -> Coin
requiredTxTotalNetUTxODeposit store body =
  requiredNetUTxODeposit store body
    <> foldMap (requiredNetUTxODeposit store . (^. bodyTxL)) (body ^. subTransactionsTxBodyL)

-- | Signed batch backing change authorized by TopTx.
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

-- | Signed funding or release that a child assigns to TopTx.
delegatedSubTxNetUTxODeposit :: SubTx.SubTxUTxODepositDeclaration -> Coin
delegatedSubTxNetUTxODeposit declaration =
  declaredSubTxNetUTxODeposit declaration <-> locallyAccountedSubTxNetUTxODeposit declaration

-- | TopTx owns the declared total after removing locally accounted child shares.
-- Requested allocations and delegated releases therefore remain with TopTx. This
-- signed amount determines TopTx's settlement destination and coverage.
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

-- | Missing mandatory child declarations leave the local/delegated choice unknown.
-- A minimum-ADA-only child may omit its declaration and still contribute backing
-- to the batch total. Such a child must not suppress TopTx settlement validation.
hasKnownSubTxContribution ::
  DijkstraEraTxBody era =>
  UTxOStore era -> TxBody SubTx era -> Bool
hasKnownSubTxContribution store body =
  validateSubTxAllocationDeclarationPresence body == pure ()
    && validateSubTxReleaseDeclarationPresence (Store.allocations store) body == pure ()

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

-- | The selected ordinary output's serialized ADA must cover the release.
-- A minimum-ADA output carries its reserve in that value.
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

-- | Price the collateral return at the active formula and release the
-- historical external deposits on the collateral inputs.
collateralDepositSettlement ::
  DijkstraEraTxBody era =>
  UTxOStore era ->
  TxBody TopTx era ->
  CollateralDepositSettlement
collateralDepositSettlement store body =
  let consumed = body ^. collateralInputsTxBodyL
      consumedAllocations = IndexedUTxOs.restrictToInputs consumed $ Store.allocations store
      collateralOutputs = IndexedUTxOs.txOuts consumedAllocations
      released =
        Store.toCoin $
          IndexedUTxOs.sumDepositAmounts (Store.depositFormulaHistory store) consumedAllocations
      returnDeposit =
        foldMap
          (requiredUTxODeposit $ Store.currentFormula store)
          (body ^. collateralReturnTxBodyL)
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
