{-# LANGUAGE DataKinds #-}

module Test.Cardano.Ledger.Api.Tx.Body.DepositBalance.Spec (spec) where

import Cardano.Ledger.Api.Era (DijkstraEra)
import Cardano.Ledger.Api.Tx.Body
import Cardano.Ledger.BaseTypes (StrictMaybe (SJust))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Core (TxLevel (..))
import Cardano.Ledger.Dijkstra.Rules (validateOrdinaryDepositStore)
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.State (mkUTxOStore)
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro ((&), (.~))
import Lens.Micro.Extras (view)
import qualified Test.Cardano.Ledger.Api.Tx.Body.DepositBalance.Fixture as Fixture
import Test.Cardano.Ledger.Common (Spec, describe, expectRight, it, shouldBe)

spec :: Spec
spec = describe "computeNetBalance and body updates" $ do
  bodyInputsAndOutputsSpec
  subTxSpec
  topTxSpec
  ordinaryInputsAndOutputsSpec
  refundTargetSpec
  newRefundOutputSpec
  updateTopTxSpec
  updateSubTxSpec
  topUpTopTxSpec
  topUpSubTxSpec
  ledgerAccountingSpec

bodyInputsAndOutputsSpec :: Spec
bodyInputsAndOutputsSpec = describe "body inputs and outputs" $ do
  it "computes a declaration from the SubTx body's selected inputs and outputs" $
    subNetBalance Fixture.localSettlement Fixture.allocation
      `shouldBe` Right (SubTx.SubTxAllocateUTxODeposit $ Fixture.depositAmount 1820)
  it "combines the TopTx body's outputs with already balanced child declarations" $ do
    let body =
          mkBasicTxBody
            & outputsTxBodyL .~ SSeq.singleton Fixture.depositBackedOutput
            & Fixture.withChildren [Fixture.localRelease]
    topNetBalance body `shouldBe` Right (TopTx.AllocateUTxODeposit $ Fixture.depositAmount 1070)

subTxSpec :: Spec
subTxSpec = describe "computeSubTxNetBalance" $ do
  it "allocates the active-price deposit locally" $
    subNetBalance Fixture.localSettlement Fixture.allocation
      `shouldBe` Right (SubTx.SubTxAllocateUTxODeposit $ Fixture.depositAmount 1820)
  it "requests the active-price allocation from TopTx when delegated" $
    subNetBalance DelegateDepositToTopTx Fixture.allocation
      `shouldBe` Right (SubTx.SubTxRequestUTxODepositFromTopTx $ Fixture.depositAmount 1820)
  it "releases the historical deposit into the supplied local output" $
    subNetBalance Fixture.localSettlement Fixture.historicalRelease
      `shouldBe` Right (SubTx.SubTxReleaseUTxODeposit (Fixture.depositAmount 750) Fixture.localTarget)
  it "delegates the historical release to TopTx" $
    subNetBalance DelegateDepositToTopTx Fixture.historicalRelease
      `shouldBe` Right (SubTx.SubTxReleaseUTxODeposit (Fixture.depositAmount 750) SubTx.DelegateToTopTx)
  it "returns explicit zero for an equally priced replacement" $
    subNetBalance Fixture.localSettlement Fixture.replacement
      `shouldBe` Right SubTx.SubTxNoUTxODepositChange
  it "returns explicit zero when the delegation choice has no amount to delegate" $
    subNetBalance DelegateDepositToTopTx Fixture.replacement
      `shouldBe` Right SubTx.SubTxNoUTxODepositChange
  it "returns zero for a transfer between min-ADA outputs" $
    subNetBalance Fixture.localSettlement Fixture.minAdaTransfer
      `shouldBe` Right SubTx.SubTxNoUTxODepositChange
  it "preserves the deposit when the application ADA in an output changes" $
    subNetBalance Fixture.localSettlement Fixture.changedOutput
      `shouldBe` Right (SubTx.SubTxAllocateUTxODeposit $ Fixture.depositAmount 1820)

topTxSpec :: Spec
topTxSpec = describe "computeNetBalance" $ do
  it "uses the parent's own allocation when there are no children" $
    topNetBalance Fixture.parentAllocation
      `shouldBe` Right (TopTx.AllocateUTxODeposit $ Fixture.depositAmount 1820)
  it "selects the supplied TopTx output for the parent's release" $
    topNetBalance Fixture.parentRelease
      `shouldBe` Right
        ( TopTx.ReleaseUTxODeposit (Fixture.depositAmount 1820) $
            TopTx.TopTxSettlementOutput Fixture.refundIndex
        )
  it "adds local and delegated child declarations to the parent's balance once" $
    topNetBalance Fixture.mixedBatch
      `shouldBe` Right (TopTx.AllocateUTxODeposit $ Fixture.depositAmount 2890)
  it "trusts a balanced child's declaration without resolving its inputs again" $
    updateTxBodyWithNetBalance
      Fixture.history
      mempty
      UTxODepositStrategy
        { depositTopUp = TopUpAlreadyIncluded
        , depositSettlement = Fixture.topSettlement
        }
      Fixture.declaredMissingChildBatch
      `shouldBe` Right
        ( Fixture.declaredMissingChildBatch
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease (Fixture.depositAmount 750) TopTx.NoTopTxSettlement
        )
  it "ignores the previous TopTx declaration" $ do
    let body = Fixture.parentAllocation & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresZeroNetUTxODeposit
    topDeclarationAfterUpdate body
      `shouldBe` Right (TopTx.DeclaresNetUTxODepositAllocation $ Fixture.depositAmount 1820)
  it "omits TopTx settlement when the release is entirely settled by a child" $
    topNetBalance Fixture.localReleaseBatch
      `shouldBe` Right (TopTx.ReleaseUTxODeposit (Fixture.depositAmount 750) TopTx.NoTopTxSettlement)
  it "omits TopTx settlement when a local child release exceeds the parent's allocation" $
    topNetBalance Fixture.locallyReleasedBatchWithParentAllocation
      `shouldBe` Right (TopTx.ReleaseUTxODeposit (Fixture.depositAmount 750) TopTx.NoTopTxSettlement)
  it "selects the TopTx output when a child's release is delegated" $
    topNetBalance Fixture.delegatedReleaseBatch
      `shouldBe` Right
        ( TopTx.ReleaseUTxODeposit (Fixture.depositAmount 750) $
            TopTx.TopTxSettlementOutput Fixture.refundIndex
        )
  it "selects the TopTx output when its attributed release exceeds the batch release" $
    topNetBalance Fixture.settlementLargerThanBatch
      `shouldBe` Right
        ( TopTx.ReleaseUTxODeposit (Fixture.depositAmount 750) $
            TopTx.TopTxSettlementOutput Fixture.refundIndex
        )
  it "returns explicit zero for offsetting parent and child balances" $ do
    let body = Fixture.parentRelease & Fixture.withChildren [Fixture.localAllocation]
    topNetBalance body `shouldBe` Right TopTx.NoUTxODepositChange

ordinaryInputsAndOutputsSpec :: Spec
ordinaryInputsAndOutputsSpec = describe "ordinary deposit operations" $ do
  it "ignores an unresolved reference input" $ do
    let body = Fixture.parentAllocation & referenceInputsTxBodyL .~ Set.singleton Fixture.missingInput
    topDeclarationAfterUpdate body
      `shouldBe` Right (TopTx.DeclaresNetUTxODepositAllocation $ Fixture.depositAmount 1820)
  it "ignores an unresolved collateral input" $ do
    let body = Fixture.parentAllocation & collateralInputsTxBodyL .~ Set.singleton Fixture.missingInput
    topDeclarationAfterUpdate body
      `shouldBe` Right (TopTx.DeclaresNetUTxODepositAllocation $ Fixture.depositAmount 1820)
  it "excludes the deposit of a collateral return" $ do
    let body = Fixture.parentAllocation & collateralReturnTxBodyL .~ SJust Fixture.depositBackedOutput
    topDeclarationAfterUpdate body
      `shouldBe` Right (TopTx.DeclaresNetUTxODepositAllocation $ Fixture.depositAmount 1820)

refundTargetSpec :: Spec
refundTargetSpec = describe "refund output index" $ do
  it "identifies a missing TopTx output when the parent receives a release" $ do
    let body = Fixture.parentRelease & outputsTxBodyL .~ mempty
    topNetBalance body `shouldBe` Left (UnresolvedDepositOutput Fixture.refundIndex)
  it "identifies a missing SubTx output for a local release" $ do
    let body = Fixture.historicalRelease & outputsTxBodyL .~ mempty
    subNetBalance Fixture.localSettlement body
      `shouldBe` Left (UnresolvedDepositOutput Fixture.refundIndex)
  it "accepts delegated SubTx releases without a local refund output" $ do
    let body = Fixture.historicalRelease & outputsTxBodyL .~ mempty
    subNetBalance DelegateDepositToTopTx body
      `shouldBe` Right (SubTx.SubTxReleaseUTxODeposit (Fixture.depositAmount 750) SubTx.DelegateToTopTx)
  it "propagates a missing refund output through the TopTx updater" $ do
    let body = Fixture.parentRelease & outputsTxBodyL .~ mempty
    updateTopBalance body `shouldBe` Left (UnresolvedDepositOutput Fixture.refundIndex)
  it "propagates a missing refund output through the SubTx updater" $ do
    let body = Fixture.historicalRelease & outputsTxBodyL .~ mempty
    updateSubBalance Fixture.localSettlement body
      `shouldBe` Left (UnresolvedDepositOutput Fixture.refundIndex)

newRefundOutputSpec :: Spec
newRefundOutputSpec = describe "refund settlement policy" $ do
  it "appends the supplied TopTx refund output unchanged and selects its index" $
    updateTopSettling (TopTxRefundToNewOutput Fixture.refundOutput) Fixture.parentRelease
      `shouldBe` Right
        ( Fixture.parentRelease
            & Fixture.appendOutput Fixture.refundOutput
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 1820)
                (TopTx.TopTxSettlementOutput Fixture.appendedRefundIndex)
        )
  it "appends the supplied SubTx refund output unchanged and selects its index" $
    updateSubBalance (SubTxRefundToNewOutput Fixture.refundOutput) Fixture.historicalRelease
      `shouldBe` Right
        ( Fixture.historicalRelease
            & Fixture.appendOutput Fixture.refundOutput
            & subTxNetUTxODepositChangeTxBodyL
              .~ SubTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 750)
                (SubTx.SubTxSettlementOutput Fixture.appendedRefundIndex)
        )
  it "computes the TopTx declaration for the appended output before updating the body" $
    topNetBalanceSettling (TopTxRefundToNewOutput Fixture.refundOutput) Fixture.parentRelease
      `shouldBe` Right
        ( TopTx.ReleaseUTxODeposit (Fixture.depositAmount 1820) $
            TopTx.TopTxSettlementOutput Fixture.appendedRefundIndex
        )
  it "computes the SubTx declaration for the appended output before updating the body" $
    subNetBalance (SubTxRefundToNewOutput Fixture.refundOutput) Fixture.historicalRelease
      `shouldBe` Right
        ( SubTx.SubTxReleaseUTxODeposit (Fixture.depositAmount 750) $
            SubTx.SubTxSettlementOutput Fixture.appendedRefundIndex
        )
  it "appends a refund output after the top-up changes allocation into release" $
    updateTxBodyWithNetBalance
      Fixture.history
      Fixture.resolvedInputs
      UTxODepositStrategy
        { depositTopUp = TopUpFromInput Fixture.currentInput
        , depositSettlement = TopTxRefundToNewOutput Fixture.refundOutput
        }
      Fixture.parentAllocationBeforeRefund
      `shouldBe` Right
        ( Fixture.parentAllocationBeforeRefund
            & Fixture.withInput Fixture.currentInput
            & Fixture.appendOutput Fixture.refundOutput
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 750)
                (TopTx.TopTxSettlementOutput Fixture.appendedRefundIndex)
        )
  it "rejects a new refund output whose appended index cannot be represented" $
    topNetBalanceSettling (TopTxRefundToNewOutput Fixture.refundOutput) Fixture.parentAtOutputIndexLimit
      `shouldBe` Left (RefundOutputIndexOutOfRange 65536)
  it "deducts the new refund output's deposit from the TopTx release" $
    updateTopSettling
      (TopTxRefundToNewOutput Fixture.depositBackedRefundOutput)
      Fixture.parentMultipleRelease
      `shouldBe` Right
        ( Fixture.parentMultipleRelease
            & Fixture.appendOutput Fixture.depositBackedRefundOutput
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 750)
                (TopTx.TopTxSettlementOutput Fixture.appendedRefundIndex)
        )
  it "deducts the new refund output's deposit from the SubTx release" $
    updateSubBalance
      (SubTxRefundToNewOutput Fixture.depositBackedRefundOutput)
      Fixture.subMultipleRelease
      `shouldBe` Right
        ( Fixture.subMultipleRelease
            & Fixture.appendOutput Fixture.depositBackedRefundOutput
            & subTxNetUTxODepositChangeTxBodyL
              .~ SubTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 750)
                (SubTx.SubTxSettlementOutput Fixture.appendedRefundIndex)
        )
  it "rejects a refund output whose deposit exceeds the TopTx release" $
    topNetBalanceSettling
      (TopTxRefundToNewOutput Fixture.depositBackedRefundOutput)
      Fixture.delegatedReleaseBatch
      `shouldBe` Left (RefundOutputConsumesRelease (Coin 750) (Coin 1820))
  it "rejects a refund output whose deposit exceeds the SubTx release" $
    subNetBalance (SubTxRefundToNewOutput Fixture.depositBackedRefundOutput) Fixture.historicalRelease
      `shouldBe` Left (RefundOutputConsumesRelease (Coin 750) (Coin 1820))
  it "rejects a refund output whose deposit exactly consumes the TopTx release" $
    topNetBalanceSettling
      (TopTxRefundToNewOutput Fixture.depositBackedRefundOutput)
      Fixture.parentRelease
      `shouldBe` Left (RefundOutputConsumesRelease (Coin 1820) (Coin 1820))
  it "rejects a refund output whose deposit exactly consumes the SubTx release" $
    subNetBalance (SubTxRefundToNewOutput Fixture.depositBackedRefundOutput) Fixture.currentRelease
      `shouldBe` Left (RefundOutputConsumesRelease (Coin 1820) (Coin 1820))
  it "limits the new output's deposit by the batch release when it is smaller than the parent's share" $
    topNetBalanceSettling
      (TopTxRefundToNewOutput Fixture.depositBackedRefundOutput)
      Fixture.settlementLargerThanBatch
      `shouldBe` Left (RefundOutputConsumesRelease (Coin 750) (Coin 1820))
  it "limits the new output's deposit by the parent's share when it is smaller than the batch release" $ do
    let body = Fixture.parentRelease & Fixture.withChildren [Fixture.localRelease]
    topNetBalanceSettling (TopTxRefundToNewOutput Fixture.depositBackedRefundOutput) body
      `shouldBe` Left (RefundOutputConsumesRelease (Coin 1820) (Coin 1820))
  it "keeps TopTx outputs unchanged when the computed result is an allocation" $
    updateTopSettling (TopTxRefundToNewOutput Fixture.refundOutput) Fixture.parentAllocation
      `shouldBe` updateTopBalance Fixture.parentAllocation
  it "keeps SubTx outputs unchanged when the computed result is an allocation" $
    updateSubBalance (SubTxRefundToNewOutput Fixture.refundOutput) Fixture.allocation
      `shouldBe` Right Fixture.localAllocation
  it "keeps TopTx outputs unchanged when the computed result is zero" $
    updateTopSettling (TopTxRefundToNewOutput Fixture.refundOutput) mkBasicTxBody
      `shouldBe` Right (mkBasicTxBody & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresZeroNetUTxODeposit)
  it "keeps SubTx outputs unchanged when the computed result is zero" $
    updateSubBalance (SubTxRefundToNewOutput Fixture.refundOutput) Fixture.replacement
      `shouldBe` Right (Fixture.replacement & subTxNetUTxODepositChangeTxBodyL .~ SubTx.DeclaresZeroNetUTxODeposit)
  it "keeps TopTx outputs unchanged when the refund is settled entirely by a child" $
    updateTopSettling (TopTxRefundToNewOutput Fixture.refundOutput) Fixture.localReleaseBatch
      `shouldBe` updateTopBalance Fixture.localReleaseBatch
  it "accepts NoTopTxRefund for a release settled entirely by a child" $
    topNetBalanceSettling NoTopTxRefund Fixture.localReleaseBatch
      `shouldBe` Right (TopTx.ReleaseUTxODeposit (Fixture.depositAmount 750) TopTx.NoTopTxSettlement)
  it
    "reports the missing settlement amount when NoTopTxRefund would leave the parent's release unsettled"
    $ topNetBalanceSettling NoTopTxRefund Fixture.parentRelease
      `shouldBe` Left (MissingTopTxRefund $ Coin 1820)

updateTopTxSpec :: Spec
updateTopTxSpec = describe "updateTxBodyWithNetBalance" $ do
  it "updates the declaration while preserving the complete body and balanced children" $
    updateTopBalance Fixture.mixedBatch
      `shouldBe` Right
        ( Fixture.mixedBatch
            & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresNetUTxODepositAllocation (Fixture.depositAmount 2890)
        )
  it "writes the supplied refund target into a release declaration" $
    updateTopBalance Fixture.parentRelease
      `shouldBe` Right
        ( Fixture.parentRelease
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 1820)
                (TopTx.TopTxSettlementOutput Fixture.refundIndex)
        )
  it "replaces a stale allocation with an explicit zero declaration" $ do
    let body =
          mkBasicTxBody
            & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresNetUTxODepositAllocation (Fixture.depositAmount 1)
    updateTopBalance body
      `shouldBe` Right (body & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresZeroNetUTxODeposit)
  it "propagates an unresolved TopTx input" $
    updateTopBalance Fixture.missingTopInput
      `shouldBe` Left (UnresolvedSpendingInput Fixture.missingInput)

updateSubTxSpec :: Spec
updateSubTxSpec = describe "updateSubTxBodyWithNetBalance" $ do
  it "updates the declaration while preserving the complete SubTx body" $
    updateSubBalance Fixture.localSettlement Fixture.allocation
      `shouldBe` Right Fixture.localAllocation
  it "writes an allocation request when delegation is explicitly selected" $
    updateSubBalance DelegateDepositToTopTx Fixture.localAllocation
      `shouldBe` Right Fixture.delegatedAllocation
  it "replaces a delegated release with the supplied local output" $
    updateSubBalance Fixture.localSettlement Fixture.delegatedRelease
      `shouldBe` Right Fixture.localRelease
  it "replaces a local release with explicit delegation" $
    updateSubBalance DelegateDepositToTopTx Fixture.localRelease
      `shouldBe` Right Fixture.delegatedRelease
  it "writes an explicit zero declaration" $
    updateSubBalance Fixture.localSettlement Fixture.replacement
      `shouldBe` Right (Fixture.replacement & subTxNetUTxODepositChangeTxBodyL .~ SubTx.DeclaresZeroNetUTxODeposit)
  it "propagates an unresolved SubTx input" $
    updateSubBalance Fixture.localSettlement Fixture.missingSubInput
      `shouldBe` Left (UnresolvedSpendingInput Fixture.missingInput)

topUpTopTxSpec :: Spec
topUpTopTxSpec = describe "optional TopTx top-up input" $ do
  it "adds the candidate and subtracts its historical deposit" $
    updateTopWithCandidate (TopUpFromInput Fixture.historicalInput) Fixture.parentAllocation
      `shouldBe` Right
        ( Fixture.parentAllocation
            & Fixture.withInput Fixture.historicalInput
            & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresNetUTxODepositAllocation (Fixture.depositAmount 1070)
        )
  it "changes allocation into a refund when the top-up releases a larger deposit" $
    updateTopWithCandidate (TopUpFromInput Fixture.currentInput) Fixture.parentAllocationBeforeRefund
      `shouldBe` Right
        ( Fixture.parentAllocationBeforeRefund
            & Fixture.withInput Fixture.currentInput
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease
                (Fixture.depositAmount 750)
                (TopTx.TopTxSettlementOutput Fixture.refundIndex)
        )
  it "funds an allocation delegated by a balanced child" $ do
    let body = mkBasicTxBody & Fixture.withChildren [Fixture.delegatedAllocation]
    updateTopWithCandidate (TopUpFromInput Fixture.currentInput) body
      `shouldBe` Right
        ( body
            & Fixture.withInput Fixture.currentInput
            & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresZeroNetUTxODeposit
        )
  it "uses the attributed TopTx share even when the batch total is a release" $
    updateTopWithCandidate
      (TopUpFromInput Fixture.minAdaInput)
      Fixture.locallyReleasedBatchWithParentAllocation
      `shouldBe` Right
        ( Fixture.locallyReleasedBatchWithParentAllocation
            & Fixture.withInput Fixture.minAdaInput
            & netUTxODepositChangeTxBodyL
              .~ TopTx.DeclaresNetUTxODepositRelease (Fixture.depositAmount 750) TopTx.NoTopTxSettlement
        )
  it "leaves a child's local allocation to that child" $ do
    let body = mkBasicTxBody & Fixture.withChildren [Fixture.localAllocation]
    updateTopWithCandidate (TopUpFromInput Fixture.missingInput) body
      `shouldBe` Right
        ( body
            & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresNetUTxODepositAllocation (Fixture.depositAmount 1820)
        )
  it "ignores an unresolved candidate when TopTx releases a deposit" $
    updateTopWithCandidate (TopUpFromInput Fixture.missingInput) Fixture.parentRelease
      `shouldBe` updateTopBalance Fixture.parentRelease
  it "identifies an unresolved candidate when TopTx needs allocation funding" $
    updateTopWithCandidate (TopUpFromInput Fixture.missingInput) Fixture.parentAllocation
      `shouldBe` Left (UnresolvedTopUpInput Fixture.missingInput)
  it "counts a candidate already in the parent's inputs once" $
    updateTopWithCandidate (TopUpFromInput Fixture.currentInput) Fixture.parentAllocation
      `shouldBe` updateTopBalance Fixture.parentAllocation
  it "rejects a selected top-up input already consumed by a SubTx" $ do
    let body = mkBasicTxBody & Fixture.withChildren [Fixture.delegatedAllocation]
    updateTopWithCandidate (TopUpFromInput Fixture.minAdaInput) body
      `shouldBe` Left (TopUpInputUsedBySubTx Fixture.minAdaInput)
  it "ignores a child's input when TopTx has no allocation to fund" $ do
    let body = mkBasicTxBody & Fixture.withChildren [Fixture.localAllocation]
    updateTopWithCandidate (TopUpFromInput Fixture.minAdaInput) body
      `shouldBe` Right
        ( body
            & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresNetUTxODepositAllocation (Fixture.depositAmount 1820)
        )
  it "includes the candidate's historical release in a pure calculation" $
    computeNetBalance
      Fixture.history
      Fixture.resolvedInputs
      UTxODepositStrategy
        { depositTopUp = TopUpFromInput Fixture.historicalInput
        , depositSettlement = Fixture.topSettlement
        }
      Fixture.parentAllocation
      `shouldBe` Right (TopTx.AllocateUTxODeposit $ Fixture.depositAmount 1070)
  it "is idempotent after adding the candidate" $ do
    body <-
      expectRight $
        updateTopWithCandidate (TopUpFromInput Fixture.historicalInput) Fixture.parentAllocation
    updateTopWithCandidate (TopUpFromInput Fixture.historicalInput) body `shouldBe` Right body

topUpSubTxSpec :: Spec
topUpSubTxSpec = describe "optional SubTx top-up input" $ do
  it "adds the candidate and subtracts its historical deposit from a local allocation" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.historicalInput)
      Fixture.localSettlement
      Fixture.allocation
      `shouldBe` Right
        ( Fixture.allocation
            & Fixture.withInput Fixture.historicalInput
            & subTxNetUTxODepositChangeTxBodyL
              .~ SubTx.DeclaresNetUTxODepositAllocation (Fixture.depositAmount 1070)
        )
  it "writes explicit zero when the candidate's deposit covers the allocation" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.currentInput)
      Fixture.localSettlement
      Fixture.allocation
      `shouldBe` Right
        ( Fixture.allocation
            & Fixture.withInput Fixture.currentInput
            & subTxNetUTxODepositChangeTxBodyL .~ SubTx.DeclaresZeroNetUTxODeposit
        )
  it "changes allocation into a local refund when the top-up releases a larger deposit" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.currentInput)
      Fixture.localSettlement
      Fixture.subAllocationBeforeRefund
      `shouldBe` Right
        ( Fixture.subAllocationBeforeRefund
            & Fixture.withInput Fixture.currentInput
            & subTxNetUTxODepositChangeTxBodyL
              .~ SubTx.DeclaresNetUTxODepositRelease (Fixture.depositAmount 750) Fixture.localTarget
        )
  it "ignores an unresolved candidate when allocation is delegated" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.missingInput)
      DelegateDepositToTopTx
      Fixture.allocation
      `shouldBe` Right Fixture.delegatedAllocation
  it "ignores an unresolved candidate when SubTx releases a deposit" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.missingInput)
      Fixture.localSettlement
      Fixture.historicalRelease
      `shouldBe` Right Fixture.localRelease
  it "identifies an unresolved candidate for a local allocation" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.missingInput)
      Fixture.localSettlement
      Fixture.allocation
      `shouldBe` Left (UnresolvedTopUpInput Fixture.missingInput)
  it "counts a candidate already in the SubTx inputs once" $
    updateSubWithCandidate
      (TopUpFromInput Fixture.minAdaInput)
      Fixture.localSettlement
      Fixture.allocation
      `shouldBe` Right Fixture.localAllocation
  it "includes the candidate's historical release in a pure calculation" $
    computeSubTxNetBalance
      Fixture.history
      Fixture.resolvedInputs
      UTxODepositStrategy
        { depositTopUp = TopUpFromInput Fixture.historicalInput
        , depositSettlement = Fixture.localSettlement
        }
      Fixture.allocation
      `shouldBe` Right (SubTx.SubTxAllocateUTxODeposit $ Fixture.depositAmount 1070)
  it "is idempotent after adding the candidate" $ do
    body <-
      expectRight $
        updateSubWithCandidate
          (TopUpFromInput Fixture.historicalInput)
          Fixture.localSettlement
          Fixture.allocation
    updateSubWithCandidate (TopUpFromInput Fixture.historicalInput) Fixture.localSettlement body
      `shouldBe` Right body

ledgerAccountingSpec :: Spec
ledgerAccountingSpec = describe "ledger accounting integration" $ do
  it "accepts a release entirely settled in a SubTx output" $ do
    body <- expectRight $ updateTopBalance Fixture.localReleaseBatch
    validateOrdinaryDepositStore (mkUTxOStore Fixture.history Fixture.resolvedInputs) body
      `shouldBe` pure ()
  it "accepts a child release delegated to a TopTx output" $ do
    child <- expectRight $ updateSubBalance DelegateDepositToTopTx Fixture.historicalRelease
    body <-
      expectRight $ updateTopBalance (Fixture.delegatedReleaseBatch & Fixture.withChildren [child])
    validateOrdinaryDepositStore (mkUTxOStore Fixture.history Fixture.resolvedInputs) body
      `shouldBe` pure ()
  it "accepts the repriced declaration and appended refund output in the ledger" $ do
    body <-
      expectRight $
        updateTopSettling
          (TopTxRefundToNewOutput Fixture.depositBackedRefundOutput)
          Fixture.parentMultipleRelease
    validateOrdinaryDepositStore (mkUTxOStore Fixture.history Fixture.resolvedInputs) body
      `shouldBe` pure ()
  it "accepts a TopTx settlement larger than the complete batch release" $ do
    body <- expectRight $ updateTopBalance Fixture.settlementLargerThanBatch
    validateOrdinaryDepositStore (mkUTxOStore Fixture.history Fixture.resolvedInputs) body
      `shouldBe` pure ()

-- Private helpers

topNetBalance :: TxBody TopTx DijkstraEra -> Either NetBalanceError TopTx.NetUTxODepositChange
topNetBalance =
  computeNetBalance
    Fixture.history
    Fixture.resolvedInputs
    UTxODepositStrategy
      { depositTopUp = TopUpAlreadyIncluded
      , depositSettlement = Fixture.topSettlement
      }

topNetBalanceSettling ::
  TopTxDepositSettlement DijkstraEra ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError TopTx.NetUTxODepositChange
topNetBalanceSettling =
  computeNetBalance Fixture.history Fixture.resolvedInputs . UTxODepositStrategy TopUpAlreadyIncluded

subNetBalance ::
  SubTxDepositSettlement DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError SubTx.SubTxNetUTxODepositChange
subNetBalance =
  computeSubTxNetBalance Fixture.history Fixture.resolvedInputs
    . UTxODepositStrategy TopUpAlreadyIncluded

topDeclarationAfterUpdate ::
  TxBody TopTx DijkstraEra -> Either NetBalanceError TopTx.TopTxUTxODepositDeclaration
topDeclarationAfterUpdate = fmap (view netUTxODepositChangeTxBodyL) . updateTopBalance

updateTopBalance :: TxBody TopTx DijkstraEra -> Either NetBalanceError (TxBody TopTx DijkstraEra)
updateTopBalance = updateTopWithCandidate TopUpAlreadyIncluded

updateTopWithCandidate ::
  DepositTopUp -> TxBody TopTx DijkstraEra -> Either NetBalanceError (TxBody TopTx DijkstraEra)
updateTopWithCandidate candidate =
  updateTxBodyWithNetBalance
    Fixture.history
    Fixture.resolvedInputs
    UTxODepositStrategy
      { depositTopUp = candidate
      , depositSettlement = Fixture.topSettlement
      }

updateTopSettling ::
  TopTxDepositSettlement DijkstraEra ->
  TxBody TopTx DijkstraEra ->
  Either NetBalanceError (TxBody TopTx DijkstraEra)
updateTopSettling =
  updateTxBodyWithNetBalance Fixture.history Fixture.resolvedInputs
    . UTxODepositStrategy TopUpAlreadyIncluded

updateSubBalance ::
  SubTxDepositSettlement DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (TxBody SubTx DijkstraEra)
updateSubBalance = updateSubWithCandidate TopUpAlreadyIncluded

updateSubWithCandidate ::
  DepositTopUp ->
  SubTxDepositSettlement DijkstraEra ->
  TxBody SubTx DijkstraEra ->
  Either NetBalanceError (TxBody SubTx DijkstraEra)
updateSubWithCandidate candidate =
  updateSubTxBodyWithNetBalance Fixture.history Fixture.resolvedInputs . UTxODepositStrategy candidate
