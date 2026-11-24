{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Api.Tx.Body.DepositBalance.Fixture (
  history,
  zeroActivePrice,
  highHistoricalPrice,
  resolvedInputs,
  MixedTransfer (..),
  embeddedToExternal,
  importedToExternal,
  externalToEmbedded,
  mixedTransferBody,
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
import Data.Typeable (Typeable)
import Data.Word (Word64)
import Lens.Micro ((%~), (&), (.~))
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)

-- A plain output costs 250 × 3 = 750 lovelace before slot 20 and
-- 260 × 7 = 1820 lovelace from slot 20 onward.
history :: DepositFormulaHistory
history =
  fromJust $
    appendFormula (SlotNo 20) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7) $
      mkDepositFormulaHistory (DepositFormulaV1 $ CoinPerByte $ CompactCoin 3)

-- Histories for the output-index limit and large top-up tests.
zeroActivePrice, highHistoricalPrice :: DepositFormulaHistory
zeroActivePrice = fromJust $ appendFormula (SlotNo 21) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 0) history
highHistoricalPrice =
  fromJust $
    appendFormula (SlotNo 20) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7) $
      mkDepositFormulaHistory (DepositFormulaV1 $ CoinPerByte $ CompactCoin 20)

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
    <> IndexedUTxOs.fromList
      [ (input, Unspent minAdaOutput (AtSlot $ SlotNo 20)) | input <- parentChangeInputs <> subChangeInputs
      ]

-- Each change output replaces an equally priced input. Parent and child use
-- distinct inputs so both can return change in the same batch.
parentChangeInputs, subChangeInputs :: [TxIn]
parentChangeInputs = map (outputAt . TxIx) [4, 5]
subChangeInputs = map (outputAt . TxIx) [6, 7]

withMinAdaChange :: [TxIn] -> TxBody txLevel DijkstraEra -> TxBody txLevel DijkstraEra
withMinAdaChange inputs body =
  body
    & inputsTxBodyL %~ Set.union (Set.fromList inputs)
    & outputsTxBodyL %~ (<> SSeq.fromList (map (const minAdaOutput) inputs))

data MixedTransfer = MixedTransfer
  { transferHistory :: DepositFormulaHistory
  , transferInputs :: IndexedUTxOs DijkstraEra
  , transferOutputs :: SSeq.StrictSeq (TxOut DijkstraEra)
  }

-- With a 0.2 ADA fee, serialized inputs cover the outputs plus the external
-- Store movement in each transfer. The fee input and change have equal backing.
embeddedToExternal, importedToExternal, externalToEmbedded :: MixedTransfer
embeddedToExternal =
  mixedTransfer
    6400
    8000
    (minAdaOutput & coinTxOutL .~ Coin 6_600_000)
    (depositBackedOutput & coinTxOutL .~ Coin 5_000_000)
    (Coin 4_400_000)
importedToExternal =
  mixedTransfer
    12000
    12000
    (minAdaOutput & coinTxOutL .~ Coin 2_000_000)
    depositBackedOutput
    (Coin 3_800_000)
externalToEmbedded =
  mixedTransfer
    8000
    8000
    (depositBackedOutput & coinTxOutL .~ Coin 5_000_000)
    (minAdaOutput & coinTxOutL .~ Coin 7_000_000)
    (Coin 4_800_000)

mixedTransfer :: Word64 -> Word64 -> TxOut DijkstraEra -> TxOut DijkstraEra -> Coin -> MixedTransfer
mixedTransfer historicalRate activeRate spent created change =
  let price = DepositFormulaV1 . CoinPerByte . CompactCoin
      feeInput = minAdaOutput & coinTxOutL .~ Coin 5_000_000
   in MixedTransfer
        { transferHistory =
            fromJust $
              appendFormula (SlotNo 20) (price activeRate) (mkDepositFormulaHistory $ price historicalRate)
        , transferInputs =
            IndexedUTxOs.fromList
              [ (historicalInput, Unspent spent AtStoreMigration)
              , (currentInput, Unspent feeInput (AtSlot $ SlotNo 20))
              ]
        , transferOutputs = SSeq.fromList [created, minAdaOutput & coinTxOutL .~ change]
        }

mixedTransferBody :: Typeable l => MixedTransfer -> TxBody l DijkstraEra
mixedTransferBody transfer =
  mkBasicTxBody
    & inputsTxBodyL .~ IndexedUTxOs.inputIds (transferInputs transfer)
    & outputsTxBodyL .~ transferOutputs transfer

allocation :: TxBody SubTx DijkstraEra
allocation =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton minAdaInput
    & outputsTxBodyL .~ SSeq.singleton depositBackedOutput

historicalRelease :: TxBody SubTx DijkstraEra
historicalRelease =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton historicalInput
    & withMinAdaChange subChangeInputs

replacement :: TxBody SubTx DijkstraEra
replacement = allocation & inputsTxBodyL .~ Set.singleton currentInput

minAdaTransfer :: TxBody SubTx DijkstraEra
minAdaTransfer = allocation & outputsTxBodyL .~ SSeq.singleton minAdaOutput

changedOutput :: TxBody SubTx DijkstraEra
changedOutput = allocation & outputsTxBodyL .~ SSeq.singleton (depositBackedOutput & coinTxOutL .~ Coin 5000)

localAllocation :: TxBody SubTx DijkstraEra
localAllocation =
  allocation
    & subTxNetUTxODepositChangeTxBodyL .~ SubTx.DeclaresNetUTxODepositAllocation (depositAmount 1070)

delegatedAllocation :: TxBody SubTx DijkstraEra
delegatedAllocation =
  allocation
    & subTxNetUTxODepositChangeTxBodyL .~ SubTx.RequestsUTxODepositFromTopTx (depositAmount 1070)

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
  mkBasicTxBody
    & withInput currentInput
    & withMinAdaChange subChangeInputs
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
parentRelease = mkBasicTxBody & withInput currentInput & withMinAdaChange parentChangeInputs

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
    & appendOutput depositBackedOutput
    & withMinAdaChange (take 1 parentChangeInputs)

subAllocationBeforeRefund :: TxBody SubTx DijkstraEra
subAllocationBeforeRefund =
  mkBasicTxBody
    & withInput historicalInput
    & appendOutput depositBackedOutput
    & withMinAdaChange (take 1 subChangeInputs)

missingTopInput :: TxBody TopTx DijkstraEra
missingTopInput = parentAllocation & inputsTxBodyL .~ Set.singleton missingInput

mixedBatch :: TxBody TopTx DijkstraEra
mixedBatch = parentAllocation & withChildren [localRelease, delegatedAllocation]

localReleaseBatch :: TxBody TopTx DijkstraEra
localReleaseBatch = mkBasicTxBody & withChildren [localRelease]

delegatedReleaseBatch :: TxBody TopTx DijkstraEra
delegatedReleaseBatch =
  mkBasicTxBody
    & withMinAdaChange parentChangeInputs
    & withChildren [delegatedRelease]

locallyReleasedBatchWithParentAllocation :: TxBody TopTx DijkstraEra
locallyReleasedBatchWithParentAllocation =
  mkBasicTxBody
    & inputsTxBodyL .~ Set.singleton historicalInput
    & outputsTxBodyL .~ SSeq.singleton depositBackedOutput
    & withChildren [currentRelease]

-- The batch releases 1500, while TopTx settles its own release of 1820.
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
