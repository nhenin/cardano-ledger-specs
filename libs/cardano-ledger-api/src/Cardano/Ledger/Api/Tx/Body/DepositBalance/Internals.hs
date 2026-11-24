{-# LANGUAGE DataKinds #-}

-- | Internal preparation, accounting and declaration construction.
module Cardano.Ledger.Api.Tx.Body.DepositBalance.Internals (
  balanceTopTx,
  applyTopTxNetBalance,
  prepareSubTxBody,
  subTxNetBalance,
  writeSubTxNetBalance,
) where

import Cardano.Ledger.Api.Tx.Body.DepositBalance.Error (NetBalanceError (..))
import Cardano.Ledger.Api.Tx.Body.DepositBalance.Strategy (
  DepositTopUp (..),
  SubTxDepositSettlement (..),
  TopTxDepositSettlement (..),
  UTxODepositStrategy (..),
 )
import Cardano.Ledger.BaseTypes (TxIx, txIxFromIntegral, txIxToInt)
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core (TxBody, TxLevel (..), TxOut, bodyTxL, inputsTxBodyL, outputsTxBodyL)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (
  declaredSubTxNetUTxODeposit,
  locallyAccountedSubTxNetUTxODeposit,
  netUTxOBacking,
  requiredUTxOBacking,
 )
import Cardano.Ledger.Dijkstra.TxBody (
  netUTxODepositChangeTxBodyL,
  subTransactionsTxBodyL,
  subTxNetUTxODepositChangeTxBodyL,
 )
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositFormulaHistory, latestFormula)
import Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs (IndexedUTxOs)
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin, mkStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val ((<->))
import Data.Foldable (find, toList)
import Data.Maybe (fromJust)
import qualified Data.Sequence.Strict as SSeq
import Data.Set (Set)
import qualified Data.Set as Set
import Lens.Micro ((%~), (&), (.~), (^.))
import Lens.Micro.Extras (view)

balanceTopTx ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (TopTxDepositSettlement DijkstraEra) ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError (TxBody TopTx DijkstraEra, TopTx.NetUTxODepositChange)
balanceTopTx history utxos strategy body = do
  children <- subTxBackingTotal history utxos body
  spent <- prepareTopTxInputs history utxos (depositTopUp strategy) children body
  let settlement = depositSettlement strategy
      batchBacking txBody = netUTxOBacking history txBody spent <> children
      fundedBody = body & inputsTxBodyL .~ IndexedUTxOs.inputIds spent
  prepared <- prepareTopTxRefund history settlement (batchBacking fundedBody) fundedBody
  change <- topTxDepositChange prepared settlement (batchBacking prepared)
  pure (prepared, change)

prepareSubTxBody ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (SubTxDepositSettlement DijkstraEra) ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (TxBody SubTx DijkstraEra)
prepareSubTxBody history utxos strategy body = do
  spent <- prepareSubTxInputs history utxos strategy body
  prepareSubTxRefund history (depositSettlement strategy) spent $
    body & inputsTxBodyL .~ IndexedUTxOs.inputIds spent

prepareTopTxInputs ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  DepositTopUp ->
  Coin ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError (IndexedUTxOs DijkstraEra)
prepareTopTxInputs history utxos topUp children body = do
  spent <- resolveSpendingInputs utxos body
  let total = netUTxOBacking history body spent <> children
  fundDeposit utxos (subTxSpendingInputs body) topUp (topTxDepositShare body total) spent

prepareSubTxInputs ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  UTxODepositStrategy (SubTxDepositSettlement DijkstraEra) ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (IndexedUTxOs DijkstraEra)
prepareSubTxInputs history utxos strategy body = do
  spent <- resolveSpendingInputs utxos body
  fundDeposit
    utxos
    mempty
    (depositTopUp strategy)
    (subTxFundingRequirement (depositSettlement strategy) $ netUTxOBacking history body spent)
    spent

resolveSpendingInputs ::
  IndexedUTxOs DijkstraEra ->
  TxBody txLevel DijkstraEra ->
  Either NetBalanceError (IndexedUTxOs DijkstraEra)
resolveSpendingInputs utxos body =
  let inputs = body ^. inputsTxBodyL
   in case find (not . (`IndexedUTxOs.member` utxos)) inputs of
        Just input -> Left $ UnresolvedSpendingInput input
        Nothing -> Right $ IndexedUTxOs.restrictToInputs inputs utxos

subTxSpendingInputs :: TxBody TopTx DijkstraEra -> Set TxIn
subTxSpendingInputs = foldMap (view $ bodyTxL . inputsTxBodyL) . view subTransactionsTxBodyL

subTxFundingRequirement :: SubTxDepositSettlement era -> Coin -> Coin
subTxFundingRequirement DelegateDepositToTopTx _ = mempty
subTxFundingRequirement _ amount = amount

fundDeposit ::
  IndexedUTxOs DijkstraEra ->
  Set TxIn ->
  DepositTopUp ->
  Coin ->
  IndexedUTxOs DijkstraEra ->
  Either NetBalanceError (IndexedUTxOs DijkstraEra)
fundDeposit _ _ TopUpAlreadyIncluded _ spent = Right spent
fundDeposit utxos childInputs (TopUpFromInput input) required spent
  | required <= mempty || IndexedUTxOs.member input spent = Right spent
  | Set.member input childInputs = Left $ TopUpInputUsedBySubTx input
  | otherwise =
      maybe (Left $ UnresolvedTopUpInput input) (Right . (spent <>) . IndexedUTxOs.singleton input) $
        IndexedUTxOs.lookupUTxO input utxos

prepareTopTxRefund ::
  DepositFormulaHistory ->
  TopTxDepositSettlement DijkstraEra ->
  Coin ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError (TxBody TopTx DijkstraEra)
prepareTopTxRefund history (TopTxRefundToNewOutput output) total body
  | total < mempty && topTxDepositShare body total < mempty =
      appendRefundOutput
        history
        (min (mempty <-> total) (mempty <-> topTxDepositShare body total))
        output
        body
prepareTopTxRefund _ _ _ body = Right body

prepareSubTxRefund ::
  DepositFormulaHistory ->
  SubTxDepositSettlement DijkstraEra ->
  IndexedUTxOs DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (TxBody SubTx DijkstraEra)
prepareSubTxRefund history (SubTxRefundToNewOutput output) spent body =
  let amount = netUTxOBacking history body spent
   in if amount < mempty
        then appendRefundOutput history (mempty <-> amount) output body
        else Right body
prepareSubTxRefund _ _ _ body = Right body

appendRefundOutput ::
  DepositFormulaHistory ->
  Coin ->
  TxOut DijkstraEra ->
  TxBody txLevel DijkstraEra ->
  Either NetBalanceError (TxBody txLevel DijkstraEra)
appendRefundOutput history available output body = do
  validateRefundDeposit available $ requiredUTxOBacking (latestFormula history) output
  _ <- refundOutputIndex $ length (body ^. outputsTxBodyL)
  Right $ body & outputsTxBodyL %~ (SSeq.|> output)

validateRefundDeposit :: Coin -> Coin -> Either NetBalanceError ()
validateRefundDeposit available required
  | required < available = Right ()
  | otherwise = Left $ RefundOutputConsumesRelease available required

refundOutputIndex :: Int -> Either NetBalanceError TxIx
refundOutputIndex count =
  maybe (Left $ RefundOutputIndexOutOfRange count) Right $ txIxFromIntegral count

subTxNetBalance ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  SubTxDepositSettlement DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError SubTx.SubTxNetUTxODepositChange
subTxNetBalance history utxos settlement body =
  (subTxDepositChange body settlement . netUTxOBacking history body)
    =<< resolveSpendingInputs utxos body

-- Explicit children have already signed their contributions. A minimum-ADA
-- child may omit its declaration, so recover its contribution from its body.
subTxBackingTotal ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError Coin
subTxBackingTotal history utxos =
  fmap mconcat
    . traverse (subTxBacking history utxos . view bodyTxL)
    . toList
    . view subTransactionsTxBodyL

subTxBacking ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError Coin
subTxBacking history utxos body = case body ^. subTxNetUTxODepositChangeTxBodyL of
  SubTx.NoUTxODepositDeclaration -> netUTxOBacking history body <$> resolveSpendingInputs utxos body
  declaration -> Right $ declaredSubTxNetUTxODeposit declaration

topTxDepositShare :: TxBody TopTx DijkstraEra -> Coin -> Coin
topTxDepositShare body =
  let localChange = locallyAccountedSubTxNetUTxODeposit . view (bodyTxL . subTxNetUTxODepositChangeTxBodyL)
   in (<-> foldMap localChange (body ^. subTransactionsTxBodyL))

topTxDepositChange ::
  TxBody TopTx DijkstraEra ->
  TopTxDepositSettlement DijkstraEra ->
  Coin ->
  Either NetBalanceError TopTx.NetUTxODepositChange
topTxDepositChange body settlement amount
  | amount == mempty = Right TopTx.NoUTxODepositChange
  | amount > mempty = Right . TopTx.AllocateUTxODeposit . fromJust $ mkStrictlyPositiveCoin amount
  | otherwise =
      TopTx.ReleaseUTxODeposit (fromJust $ mkStrictlyPositiveCoin (mempty <-> amount))
        <$> topTxReleaseSettlement body settlement amount

topTxReleaseSettlement ::
  TxBody TopTx DijkstraEra ->
  TopTxDepositSettlement DijkstraEra ->
  Coin ->
  Either NetBalanceError TopTx.TopTxReleaseSettlement
topTxReleaseSettlement body settlement amount
  | topTxDepositShare body amount < mempty =
      TopTx.TopTxSettlementOutput
        <$> resolveTopTxRefund body settlement (mempty <-> topTxDepositShare body amount)
  | otherwise = Right TopTx.NoTopTxSettlement

resolveTopTxRefund ::
  TxBody TopTx DijkstraEra ->
  TopTxDepositSettlement DijkstraEra ->
  Coin ->
  Either NetBalanceError TxIx
resolveTopTxRefund body (TopTxRefundToNewOutput _) _ = appendedRefundOutputIndex body
resolveTopTxRefund body (TopTxRefundToExistingOutput index) _ = resolveDepositOutput body index
resolveTopTxRefund _ NoTopTxRefund required = Left $ MissingTopTxRefund required

subTxDepositChange ::
  TxBody SubTx DijkstraEra ->
  SubTxDepositSettlement DijkstraEra ->
  Coin ->
  Either NetBalanceError SubTx.SubTxNetUTxODepositChange
subTxDepositChange body target amount
  | amount == mempty = Right SubTx.SubTxNoUTxODepositChange
  | amount > mempty = Right . subTxAllocation target . fromJust $ mkStrictlyPositiveCoin amount
  | otherwise =
      SubTx.SubTxReleaseUTxODeposit (fromJust $ mkStrictlyPositiveCoin (mempty <-> amount))
        <$> resolveSubTxReleaseTarget body target

subTxAllocation ::
  SubTxDepositSettlement era -> StrictlyPositiveCoin -> SubTx.SubTxNetUTxODepositChange
subTxAllocation DelegateDepositToTopTx = SubTx.SubTxRequestUTxODepositFromTopTx
subTxAllocation _ = SubTx.SubTxAllocateUTxODeposit

resolveSubTxReleaseTarget ::
  TxBody SubTx DijkstraEra ->
  SubTxDepositSettlement DijkstraEra ->
  Either NetBalanceError SubTx.SubTxReleaseTarget
resolveSubTxReleaseTarget _ DelegateDepositToTopTx = Right SubTx.DelegateToTopTx
resolveSubTxReleaseTarget body (SubTxRefundToNewOutput _) =
  SubTx.SubTxSettlementOutput <$> appendedRefundOutputIndex body
resolveSubTxReleaseTarget body (SubTxRefundToExistingOutput index) =
  SubTx.SubTxSettlementOutput <$> resolveDepositOutput body index

-- | Preparation has appended exactly one output whenever this branch is used.
appendedRefundOutputIndex :: TxBody txLevel DijkstraEra -> Either NetBalanceError TxIx
appendedRefundOutputIndex body = refundOutputIndex $ length (body ^. outputsTxBodyL) - 1

resolveDepositOutput :: TxBody txLevel DijkstraEra -> TxIx -> Either NetBalanceError TxIx
resolveDepositOutput body index
  | txIxToInt index < length (body ^. outputsTxBodyL) = Right index
  | otherwise = Left $ UnresolvedDepositOutput index

applyTopTxNetBalance ::
  TxBody TopTx DijkstraEra ->
  TopTx.NetUTxODepositChange ->
  TxBody TopTx DijkstraEra
applyTopTxNetBalance body change =
  body
    & netUTxODepositChangeTxBodyL .~ TopTx.declareUTxODepositChange change

writeSubTxNetBalance ::
  DepositFormulaHistory ->
  IndexedUTxOs DijkstraEra ->
  SubTxDepositSettlement DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (TxBody SubTx DijkstraEra)
writeSubTxNetBalance history utxos settlement body =
  applySubTxNetBalance body <$> subTxNetBalance history utxos settlement body

applySubTxNetBalance ::
  TxBody SubTx DijkstraEra ->
  SubTx.SubTxNetUTxODepositChange ->
  TxBody SubTx DijkstraEra
applySubTxNetBalance body change =
  body
    & subTxNetUTxODepositChangeTxBodyL .~ SubTx.declareUTxODepositChange change
