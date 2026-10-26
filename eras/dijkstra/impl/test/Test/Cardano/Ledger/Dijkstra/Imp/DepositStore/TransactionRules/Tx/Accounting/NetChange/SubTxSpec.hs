-- | Each SubTx declares the change caused by its own inputs and outputs.
-- Generated operation plans are funded on the ledger; the declarations under test
-- remain visible here. Invalid mutations are rejected before their exact controls
-- are submitted, so both outcomes use the same live inputs.
--
-- ownNetDeposit(body) = allocatedDeposits(body) - releasedDeposits(body).
-- declaredNetDeposit is signed: allocation is positive, release negative,
-- and explicit zero is zero. An absent declaration has no declared value.
-- Derive allocations from independently priced outputs and releases from the
-- live input allocation records. All amounts below are measured in lovelace.
--
-- Common setup: declarations satisfy grammar and Required declarations;
-- TopTx declares transactionNetDeposit(topTx), the sum of every body's own change.
-- SubTx declarations outside the case under test remain exact; all inputs resolve.
-- Accepted cases satisfy settlement, authorization and all other rules.
-- Rejection fixtures preserve financial balance or require the specific
-- InexactSubTxDepositChange failure even if conservation also fails. An unrelated
-- rejection cannot demonstrate SubTx exactness.
-- P01 checks only isolated SubTx exactness. N/F cases specify ledger outcomes.
--
-- declarationError(subTx) = declaredNetDeposit(subTx) - ownNetDeposit(subTx).
-- delegatesAllocation means RequestsUTxODepositFromTopTx;
-- delegatesRelease means a release with the DelegateToTopTx target.
-- translatedImplicitInput denotes a live previous-era output translated to the
-- implicit form, with no Store deposit. Every named SubTx belongs to TopTx.
-- Unless stated otherwise, phase 2 succeeds. Phase-2 failure cases use a real
-- failing-script control marked Invalid; a rejection does not claim that ledger
-- validation reaches script execution after the exactness check fails.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.NetChange.SubTxSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraUtxoPredFailure (..),
  validateSubTxExactness,
 )
import Cardano.Ledger.State (depositStoreAllocations)
import Cardano.Ledger.Val ((<->))
import Data.Foldable (traverse_)
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Set as Set
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (
  Spec,
  describe,
  elements,
  forAll,
  forM_,
  prop,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (recordedDepositStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.SubTx as Cases
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Ledger
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  buildAndSignPhase2InvalidTx,
  buildAndSignTx,
  fundAccountingScenario,
  mutateSubTxDeclaration,
  replaceSubTxDeclarations,
  subTxIdAt,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  isAccepted,
  isRejectedWith,
  ordinarySpendingInputs,
  submitTx,
 )
import Test.Cardano.Ledger.Imp.Common (shouldBe, shouldSatisfy)
import Validation (Validation (..))

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX - Each SubTx declares its exact own change" $ do
    -- Each SubTx declares its own exact change.
    -- Compare the isolated SubTx exactness result with independent input records and output prices; include exact and inexact declarations.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-P01 - subTxNetChangeValid ⇔ (∀ subTx ∈ declaredSubTxs: declaredNetDeposit(subTx) = ownNetDeposit(subTx))" $
      forAll Cases.declarationErrors $ \(scenario, errors, delegatedForms) -> do
        proposal <- fundAccountingScenario scenario
        let requiredChanges = zipWith (<->) (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
            suppliedChanges = zipWith (<>) requiredChanges (map Coin errors)
            declaredProposal = TopTx.addDeclaration
              (Declarations
                (case TopTx.netDeposit proposal of
                  Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                  Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                    TopTx.NoTopTxSettlement
                  _ -> TopTx.DeclaresZeroNetUTxODeposit)
                [ case ownChange of
                    Coin amount | amount > 0 ->
                      if delegated then SubTx.RequestsUTxODepositFromTopTx $ positiveAmount amount
                      else SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                    Coin amount | amount < 0 -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                      (if delegated then SubTx.DelegateToTopTx else SubTx.SubTxSettlementOutput $ TxIx 0)
                    _ -> SubTx.DeclaresZeroNetUTxODeposit
                | (ownChange, delegated) <- zip suppliedChanges delegatedForms
                ]) proposal
            children = OMap.elems $ TopTx.unsignedTx declaredProposal ^. bodyTxL . subTransactionsTxBodyL
            expected = case NonEmpty.nonEmpty
              [ InexactSubTxDepositChange (txIdTxBody $ child ^. bodyTxL) supplied required
              | (child, supplied, required) <- zip3 children suppliedChanges requiredChanges
              , supplied /= required
              ] of
                Nothing -> Success ()
                Just failures -> Failure failures
            ledgerState = TopTx.ledgerState proposal
        traverse_ (validateSubTxExactness (Ledger.protocolParameters ledgerState)
          (recordedDepositStore $ Ledger.utxoState ledgerState) . (^. bodyTxL)) children
          `shouldBe` expected

    -- Exact own change, with any allocation and release combination.
    -- Exercise positive allocation, negative release and explicit zero with local accounting; N03/N04 cover the delegated forms.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N01 - declaredNetDeposit(subTx) = allocatedDeposits(subTx) - releasedDeposits(subTx) ⇒ accepted" $
      forAll Cases.anyOwnNetChange $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let requiredChanges = zipWith (<->) (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.netDeposit proposal of
              Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                TopTx.NoTopTxSettlement
              _ -> TopTx.DeclaresZeroNetUTxODeposit)
            [ case ownChange of
                Coin amount | amount > 0 -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                Coin amount | amount < 0 -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
                _ -> SubTx.DeclaresZeroNetUTxODeposit
            | ownChange <- requiredChanges
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- Net allocation understated by one lovelace.
    -- The required allocation exceeds one lovelace so the mutated declaration remains a positive allocation.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F01 - ownNetDeposit(subTx) > 1 ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) - 1 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netAllocation $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
        let declared = required - 1
        invalidTx <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount declared) signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Net allocation overstated by one lovelace.
    -- Keep the increased amount representable; this checks exactness rather than decoder overflow.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F02 - ownNetDeposit(subTx) > 0 ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) + 1 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netAllocation $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
        let declared = required + 1
        invalidTx <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount declared) signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Net release understated by one lovelace.
    -- Reducing the positive release magnitude increases its signed declaration; the required release exceeds one lovelace.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F03 - ownNetDeposit(subTx) < -1 ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) + 1 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netRelease $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal
        let declared = required + 1
        invalidTx <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate declared) (SubTx.SubTxSettlementOutput $ TxIx 0)) signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Net release overstated by one lovelace.
    -- Increasing the positive release magnitude decreases its signed declaration; keep the magnitude representable.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F04 - ownNetDeposit(subTx) < 0 ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) - 1 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netRelease $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal
        let declared = required - 1
        invalidTx <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate declared) (SubTx.SubTxSettlementOutput $ TxIx 0)) signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Opposing SubTx errors cancel in the total.
    -- Both distinct SubTxs are in the transaction. Their errors cancel, but require a SubTx exactness failure.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F05 - firstSubTx ≠ secondSubTx ∧ declarationError(firstSubTx) = -declarationError(secondSubTx) ≠ 0 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.twoAllocatingSubTxs $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let requiredChanges = zipWith (<->) (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
            suppliedChanges = zipWith (<>) requiredChanges [Coin 1, Coin (-1)]
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (case TopTx.netDeposit proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount | Coin amount <- requiredChanges]) proposal
        invalidTx <- replaceSubTxDeclarations
          [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount | Coin amount <- suppliedChanges] signedTx
        forM_ (zip3 [0..] suppliedChanges requiredChanges) $ \(index, supplied, required) ->
          submitTx invalidTx >>= isRejectedWith
            (DepositStoreFailure $ InexactSubTxDepositChange (subTxIdAt index invalidTx) supplied required)
        submitTx signedTx >>= isAccepted

    -- Equal own allocations and releases, explicit zero.
    -- Use an explicit-zero declaration, including both zero operations and nonzero allocations equal to releases.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N02 - allocatedDeposits(subTx) = releasedDeposits(subTx) ∧ declaredNetDeposit(subTx) = 0 ⇒ accepted" $
      forAll Cases.equalAllocationsAndReleases $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        buildAndSignTx (TopTx.addDeclaration
          (Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]) proposal)
          >>= submitTx >>= isAccepted

    -- Explicit zero cannot replace a required allocation.
    -- The field is present as explicit zero; its amount is incorrect.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F06 - ownNetDeposit(subTx) > 0 ∧ declaredNetDeposit(subTx) = 0 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netAllocation $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
        let declared = 0
        invalidTx <- mutateSubTxDeclaration 0
          SubTx.DeclaresZeroNetUTxODeposit signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Exact allocation requested from TopTx.
    -- RequestsUTxODepositFromTopTx carries the requesting SubTx own net allocation, while TopTx declares the transaction total.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N03 - ownNetDeposit(subTx) > 0 ∧ delegatesAllocation(subTx) ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) ⇒ accepted" $
      forAll Cases.netAllocation $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.RequestsUTxODepositFromTopTx $ positiveAmount required]) proposal
        submitTx signedTx >>= isAccepted

    -- Exact release delegated to TopTx.
    -- The release targets DelegateToTopTx; its magnitude remains exactly the originating SubTx own net release.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N04 - ownNetDeposit(subTx) < 0 ∧ delegatesRelease(subTx) ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) ⇒ accepted" $
      forAll Cases.netRelease $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) SubTx.DelegateToTopTx]) proposal
        submitTx signedTx >>= isAccepted

    -- Released deposits, only implicit outputs.
    -- Implicit outputs require no new Store allocation, so the declaration releases the complete recorded input deposit.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N05 - releasedDeposits(subTx) > 0 ∧ storeBackedOutputs(subTx) = ∅ ∧ declaredNetDeposit(subTx) = -releasedDeposits(subTx) ⇒ accepted" $
      forAll Cases.onlyImplicitOutputs $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin released = foldMap id $ SubTx.releasedDeposits proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount released) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal)
          >>= submitTx >>= isAccepted

    -- Explicit zero cannot replace a required release.
    -- The field is present as explicit zero; a negative own change still requires a release declaration.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F07 - ownNetDeposit(subTx) < 0 ∧ declaredNetDeposit(subTx) = 0 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netRelease $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal
        let declared = 0
        invalidTx <- mutateSubTxDeclaration 0
          SubTx.DeclaresZeroNetUTxODeposit signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Another body offsets the SubTx release.
    -- The other body is TopTx or another SubTx. Cover partial, equal and greater offsets; none changes this SubTx own release.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N06 - otherBody ≠ subTx ∧ ownNetDeposit(subTx) < 0 < ownNetDeposit(otherBody) ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) ⇒ accepted" $
      forAll Cases.releaseWithAnotherBodyAllocation $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let requiredChanges = zipWith (<->) (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.netDeposit proposal of
              Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                TopTx.NoTopTxSettlement
              _ -> TopTx.DeclaresZeroNetUTxODeposit)
            [ case ownChange of
                Coin amount | amount > 0 -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                Coin amount | amount < 0 -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
                _ -> SubTx.DeclaresZeroNetUTxODeposit
            | ownChange <- requiredChanges
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- An output without application assets still requires a deposit.
    -- The output still has an address and encoding overhead. Use positive pricing and declare the exact allocation.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N07 - storeBackedOutputs(subTx) = {output} ∧ applicationAssets(output) = ∅ ∧ releasedDeposits(subTx) = 0 ∧ declaredNetDeposit(subTx) = allocatedDeposits(subTx) > 0 ⇒ accepted" $
      forAll Cases.outputWithoutApplicationAssets $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
        submitTx signedTx >>= isAccepted

    -- A translated implicit input funds an exact allocation.
    -- The live input was translated from the previous era into an implicit output. Its coins fund new Store obligations, but it releases no Store deposit.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N08 - ordinaryInputs(subTx) = {translatedImplicitInput} ∧ storeBackedOutputs(subTx) ≠ ∅ ∧ releasedDeposits(subTx) = 0 ∧ declaredNetDeposit(subTx) = allocatedDeposits(subTx) > 0 ⇒ accepted" $
      forAll Cases.translatedImplicitInput $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
        submitTx signedTx >>= isAccepted

    -- A translated implicit input does not excuse an inexact allocation.
    -- Use the N08 allocation scenario, changing only the positive SubTx declaration to a different representable amount.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F08 - ordinaryInputs(subTx) = {translatedImplicitInput} ∧ storeBackedOutputs(subTx) ≠ ∅ ∧ releasedDeposits(subTx) = 0 ∧ allocatedDeposits(subTx) > 0 ∧ declaredNetDeposit(subTx) > 0 ∧ declaredNetDeposit(subTx) ≠ allocatedDeposits(subTx) ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.translatedImplicitInput $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
            [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
        let declared = required + 1
        invalidTx <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount declared) signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- Unspent outputs cannot increase a SubTx release.
    -- Real funding leaves other outputs' deposits in the Store. The transaction
    -- consumes none of those outputs, so their deposits cannot fund its declaration.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F09 - unspentInputs ∩ consumedInputs = ∅ ∧ 0 < unrelatedRelease ≤ recordedDeposits(unspentInputs) ∧ ownNetDeposit(subTx) ≤ 0 ∧ declaredNetDeposit(subTx) = ownNetDeposit(subTx) - unrelatedRelease ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.releaseFromUnspentOutputs $ \(scenario, unrelatedFunding, unrelatedRelease) -> do
        unrelatedProposal <- fundAccountingScenario unrelatedFunding
        proposal <- fundAccountingScenario scenario
        let Coin required = TopTx.netDeposit proposal
            records = depositStoreAllocations $ recordedDepositStore $ Ledger.utxoState $ TopTx.ledgerState proposal
            unspentRecords = Map.restrictKeys records $ ordinarySpendingInputs $ TopTx.unsignedTx unrelatedProposal
        Coin unrelatedRelease `shouldSatisfy` (\amount -> amount > Coin 0 && amount <= foldMap id unspentRecords)
        signedTx <- buildAndSignTx $ TopTx.addDeclaration
          (Declarations
            (if required == 0 then TopTx.DeclaresZeroNetUTxODeposit
              else TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) TopTx.NoTopTxSettlement)
            [if required == 0 then SubTx.DeclaresZeroNetUTxODeposit
              else SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal
        Set.disjoint (Map.keysSet unspentRecords) (ordinarySpendingInputs signedTx) `shouldBe` True
        let declared = required - unrelatedRelease
        invalidTx <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate declared) (SubTx.SubTxSettlementOutput $ TxIx 0)) signedTx
        submitTx invalidTx >>= isRejectedWith
          (DepositStoreFailure $ InexactSubTxDepositChange
            (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted

    -- A release cannot replace a required allocation.
    -- Exercise valid local and delegated release forms; their sign contradicts the independently required own change.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F10 - ownNetDeposit(subTx) > 0 ∧ declaredNetDeposit(subTx) < 0 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netAllocation $ \scenario ->
        forAll (elements [False, True]) $ \delegateRelease -> do
          proposal <- fundAccountingScenario scenario
          let Coin required = TopTx.netDeposit proposal
          signedTx <- buildAndSignTx $ TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount required)
              [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount required]) proposal
          let declared = negate required
          invalidTx <- mutateSubTxDeclaration 0
            (SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (if delegateRelease then SubTx.DelegateToTopTx else SubTx.SubTxSettlementOutput $ TxIx 0)) signedTx
          submitTx invalidTx >>= isRejectedWith
            (DepositStoreFailure $ InexactSubTxDepositChange (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
          submitTx signedTx >>= isAccepted

    -- An allocation cannot replace a required release.
    -- Exercise a local allocation and a funding request to TopTx; neither can represent the required own release.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F11 - ownNetDeposit(subTx) < 0 ∧ declaredNetDeposit(subTx) > 0 ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.netRelease $ \scenario ->
        forAll (elements [False, True]) $ \requestFunding -> do
          proposal <- fundAccountingScenario scenario
          let Coin required = TopTx.netDeposit proposal
          signedTx <- buildAndSignTx $ TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) TopTx.NoTopTxSettlement)
              [SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate required) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal
          let declared = negate required
          invalidTx <- mutateSubTxDeclaration 0
            (if requestFunding
              then SubTx.RequestsUTxODepositFromTopTx $ positiveAmount declared
              else SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount declared) signedTx
          submitTx invalidTx >>= isRejectedWith
            (DepositStoreFailure $ InexactSubTxDepositChange (subTxIdAt 0 invalidTx) (Coin declared) (Coin required))
          submitTx signedTx >>= isAccepted

    -- Exact SubTx declarations when phase 2 fails.
    -- Use a real failing script with otherwise valid declarations and transaction terms. Acceptance follows the collateral outcome, without ordinary Store effects.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-N09 - declaredSubTxs ≠ ∅ ∧ (∀ subTx ∈ declaredSubTxs: declaredNetDeposit(subTx) = ownNetDeposit(subTx)) ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ accepted" $
      forAll Cases.anyOwnNetChange $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let requiredChanges = zipWith (<->) (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
        buildAndSignPhase2InvalidTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.netDeposit proposal of
              Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                TopTx.NoTopTxSettlement
              _ -> TopTx.DeclaresZeroNetUTxODeposit)
            [ case ownChange of
                Coin amount | amount > 0 -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                Coin amount | amount < 0 -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
                _ -> SubTx.DeclaresZeroNetUTxODeposit
            | ownChange <- requiredChanges
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- An inexact SubTx declaration still fails before the collateral outcome.
    -- Start from N09 failing-script controls and mutate a SubTx amount. The independently established script failure does not waive the earlier exactness check.
    prop "DS-TX-ACCOUNTING-NET-CHANGE-SUBTX-F12 - declaredNetDeposit(subTx) ≠ ownNetDeposit(subTx) ∧ phase2Result = Failed ∧ declaredPhase2 = Invalid ⇒ rejectedWith(InexactSubTxDepositChange)" $
      forAll Cases.anyOwnNetChange $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let requiredChanges = zipWith (<->) (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
        signedTx <- buildAndSignPhase2InvalidTx $ TopTx.addDeclaration
          (Declarations
            (case TopTx.netDeposit proposal of
              Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                TopTx.NoTopTxSettlement
              _ -> TopTx.DeclaresZeroNetUTxODeposit)
            [ case ownChange of
                Coin amount | amount > 0 -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                Coin amount | amount < 0 -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                  (SubTx.SubTxSettlementOutput $ TxIx 0)
                _ -> SubTx.DeclaresZeroNetUTxODeposit
            | ownChange <- requiredChanges
            ]) proposal
        forM_ (zip [0..] requiredChanges) $ \(index, Coin required) -> do
          let declared = required + 1
          invalidTx <- mutateSubTxDeclaration index
            (case compare declared 0 of
              GT -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount declared
              LT -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate declared)
                (SubTx.SubTxSettlementOutput $ TxIx 0)
              EQ -> SubTx.DeclaresZeroNetUTxODeposit) signedTx
          submitTx invalidTx >>= isRejectedWith
            (DepositStoreFailure $ InexactSubTxDepositChange (subTxIdAt index invalidTx) (Coin declared) (Coin required))
        submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
