{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Api.Tx.Body.DepositBalance.Fixture (
  history,
  resolvedInputs,
  depositAmount,
  refundIndex,
  localTarget,
  localSettlement,
  topSettlement,
  appendedRefundIndex,
  refundOutput,
  depositBackedRefundOutput,
  minAdaOutput,
  depositBackedOutput,
  currentInput,
  historicalInput,
  minAdaInput,
  missingInput,
  allocation,
  historicalRelease,
  replacement,
  minAdaTransfer,
  changedOutput,
  localAllocation,
  delegatedAllocation,
  localRelease,
  delegatedRelease,
  currentRelease,
  missingSubInput,
  parentAllocation,
  parentRelease,
  parentMultipleRelease,
  parentAtOutputIndexLimit,
  subMultipleRelease,
  parentAllocationBeforeRefund,
  subAllocationBeforeRefund,
  missingTopInput,
  mixedBatch,
  localReleaseBatch,
  delegatedReleaseBatch,
  locallyReleasedBatchWithParentAllocation,
  settlementLargerThanBatch,
  declaredMissingChildBatch,
  withChildren,
  withInput,
  appendOutput,
) where

import Cardano.Ledger.Api.Era (DijkstraEra)
import Cardano.Ledger.Api.Tx.Body (SubTxDepositSettlement (..), TopTxDepositSettlement (..))
import Cardano.Ledger.BaseTypes (SlotNo (..), TxIx (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (CompactCoin))
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import Cardano.Ledger.State (
  AllocatedAt (..),
  DepositFormula (..),
  DepositFormulaHistory,
  Unspent (Unspent),
  appendFormula,
  mkDepositFormulaHistory,
 )
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin, mkStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxIn (..))
import Cardano.Ledger.Val (inject)
import Data.Maybe (fromJust)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro ((%~), (&), (.~))
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)

-- A plain output costs 250 × 3 = 750 lovelace before slot 20 and
-- 260 × 7 = 1820 lovelace from slot 20 onward.
history :: DepositFormulaHistory
history =
  fromJust $
    appendFormula (SlotNo 20) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7) $
      mkDepositFormulaHistory (DepositFormulaV1 $ CoinPerByte $ CompactCoin 3)

depositAmount :: Integer -> StrictlyPositiveCoin
depositAmount = fromJust . mkStrictlyPositiveCoin . Coin

refundIndex :: TxIx
refundIndex = TxIx 1

localTarget :: SubTx.SubTxReleaseTarget
localTarget = SubTx.SubTxSettlementOutput refundIndex

localSettlement :: SubTxDepositSettlement DijkstraEra
localSettlement = SubTxRefundToExistingOutput refundIndex

topSettlement :: TopTxDepositSettlement DijkstraEra
topSettlement = TopTxRefundToExistingOutput refundIndex

appendedRefundIndex :: TxIx
appendedRefundIndex = TxIx 2

refundOutput :: TxOut DijkstraEra
refundOutput = minAdaOutput & coinTxOutL .~ Coin 6000

depositBackedRefundOutput :: TxOut DijkstraEra
depositBackedRefundOutput = depositBackedOutput & coinTxOutL .~ Coin 6000

address :: Addr
address = mkAddr (mkKeyHash @Payment 1) (mkKeyHash @Staking 1)

minAdaOutput, depositBackedOutput :: TxOut DijkstraEra
minAdaOutput = mkBasicTxOutWithMinAda address (inject $ Coin 5000)
depositBackedOutput = mkBasicTxOutWithDeposit address (ApplicationAssets mempty)

historicalInput, currentInput, minAdaInput, missingInput :: TxIn
historicalInput = outputAt (TxIx 0)
currentInput = outputAt (TxIx 1)
minAdaInput = outputAt (TxIx 2)
missingInput = outputAt (TxIx 3)

outputAt :: TxIx -> TxIn
outputAt = TxIn (txIdTxBody $ mkBasicTxBody @DijkstraEra @TopTx)

resolvedInputs :: IndexedUTxOs DijkstraEra
resolvedInputs =
  IndexedUTxOs.fromList
    [ (historicalInput, Unspent depositBackedOutput (AtSlot $ SlotNo 19))
    , (currentInput, Unspent depositBackedOutput (AtSlot $ SlotNo 20))
    , (minAdaInput, Unspent minAdaOutput AtStoreMigration)
    ]

allocation :: TxBody SubTx DijkstraEra
allocation =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton minAdaInput
    & outputsTxBodyL .~ SSeq.singleton depositBackedOutput

historicalRelease :: TxBody SubTx DijkstraEra
historicalRelease =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton historicalInput
    & outputsTxBodyL .~ SSeq.fromList [minAdaOutput, minAdaOutput]

replacement :: TxBody SubTx DijkstraEra
replacement = allocation & inputsTxBodyL .~ Set.singleton currentInput

minAdaTransfer :: TxBody SubTx DijkstraEra
minAdaTransfer = allocation & outputsTxBodyL .~ SSeq.singleton minAdaOutput

changedOutput :: TxBody SubTx DijkstraEra
changedOutput = allocation & outputsTxBodyL .~ SSeq.singleton (depositBackedOutput & coinTxOutL .~ Coin 5000)

localAllocation :: TxBody SubTx DijkstraEra
localAllocation =
  allocation
    & subTxNetUTxODepositChangeTxBodyL .~ SubTx.DeclaresNetUTxODepositAllocation (depositAmount 1820)

delegatedAllocation :: TxBody SubTx DijkstraEra
delegatedAllocation =
  allocation
    & subTxNetUTxODepositChangeTxBodyL .~ SubTx.RequestsUTxODepositFromTopTx (depositAmount 1820)

localRelease :: TxBody SubTx DijkstraEra
localRelease =
  historicalRelease
    & subTxNetUTxODepositChangeTxBodyL
      .~ SubTx.DeclaresNetUTxODepositRelease (depositAmount 750) localTarget

delegatedRelease :: TxBody SubTx DijkstraEra
delegatedRelease =
  historicalRelease
    & subTxNetUTxODepositChangeTxBodyL
      .~ SubTx.DeclaresNetUTxODepositRelease (depositAmount 750) SubTx.DelegateToTopTx

currentRelease :: TxBody SubTx DijkstraEra
currentRelease =
  historicalRelease
    & inputsTxBodyL .~ Set.singleton currentInput
    & subTxNetUTxODepositChangeTxBodyL
      .~ SubTx.DeclaresNetUTxODepositRelease (depositAmount 1820) localTarget

missingSubInput :: TxBody SubTx DijkstraEra
missingSubInput = historicalRelease & inputsTxBodyL .~ Set.singleton missingInput

-- The parent releases one active-price deposit and allocates two.
parentAllocation :: TxBody TopTx DijkstraEra
parentAllocation =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton currentInput
    & outputsTxBodyL .~ SSeq.fromList [depositBackedOutput, depositBackedOutput]

parentRelease :: TxBody TopTx DijkstraEra
parentRelease = parentAllocation & outputsTxBodyL .~ SSeq.fromList [minAdaOutput, minAdaOutput]

parentMultipleRelease :: TxBody TopTx DijkstraEra
parentMultipleRelease = parentRelease & withInput historicalInput

parentAtOutputIndexLimit :: TxBody TopTx DijkstraEra
parentAtOutputIndexLimit =
  parentRelease & outputsTxBodyL .~ SSeq.fromList (replicate 65536 minAdaOutput)

subMultipleRelease :: TxBody SubTx DijkstraEra
subMultipleRelease = historicalRelease & withInput currentInput

-- A 1070-lovelace allocation becomes a 750-lovelace release when currentInput is added.
parentAllocationBeforeRefund :: TxBody TopTx DijkstraEra
parentAllocationBeforeRefund =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton historicalInput
    & outputsTxBodyL .~ SSeq.fromList [depositBackedOutput, minAdaOutput]

subAllocationBeforeRefund :: TxBody SubTx DijkstraEra
subAllocationBeforeRefund =
  historicalRelease & outputsTxBodyL .~ SSeq.fromList [depositBackedOutput, minAdaOutput]

missingTopInput :: TxBody TopTx DijkstraEra
missingTopInput = parentAllocation & inputsTxBodyL .~ Set.singleton missingInput

mixedBatch :: TxBody TopTx DijkstraEra
mixedBatch = parentAllocation & withChildren [localRelease, delegatedAllocation]

localReleaseBatch :: TxBody TopTx DijkstraEra
localReleaseBatch = mkBasicTxBody & withChildren [localRelease]

delegatedReleaseBatch :: TxBody TopTx DijkstraEra
delegatedReleaseBatch =
  mkBasicTxBody
    & outputsTxBodyL .~ SSeq.fromList [minAdaOutput, minAdaOutput]
    & withChildren [delegatedRelease]

locallyReleasedBatchWithParentAllocation :: TxBody TopTx DijkstraEra
locallyReleasedBatchWithParentAllocation =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton historicalInput
    & outputsTxBodyL .~ SSeq.singleton depositBackedOutput
    & withChildren [currentRelease]

-- The batch releases 750, while TopTx settles its own release of 1820.
settlementLargerThanBatch :: TxBody TopTx DijkstraEra
settlementLargerThanBatch = parentRelease & withChildren [localAllocation, localRelease]

declaredMissingChildBatch :: TxBody TopTx DijkstraEra
declaredMissingChildBatch =
  mkBasicTxBody
    & withChildren [localRelease & inputsTxBodyL .~ Set.singleton missingInput]

withChildren :: [TxBody SubTx DijkstraEra] -> TxBody TopTx DijkstraEra -> TxBody TopTx DijkstraEra
withChildren children = subTransactionsTxBodyL .~ OMap.fromFoldable (map mkBasicTx children)

withInput :: TxIn -> TxBody txLevel DijkstraEra -> TxBody txLevel DijkstraEra
withInput input = inputsTxBodyL %~ Set.insert input

appendOutput :: TxOut DijkstraEra -> TxBody txLevel DijkstraEra -> TxBody txLevel DijkstraEra
appendOutput output = outputsTxBodyL %~ (<> SSeq.singleton output)
