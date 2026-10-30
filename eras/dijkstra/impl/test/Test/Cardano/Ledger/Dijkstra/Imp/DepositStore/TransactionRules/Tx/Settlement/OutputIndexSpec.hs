{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | A settlement index belongs to the declaring body's own regular outputs.
-- All ledger cases use exact declarations, sufficient output coins and globally
-- balanced application value. Only the selected index changes in rejection cases.
-- TopTx, children, siblings and collateral return are separate namespaces.
-- P01 isolates index resolution with sufficient coins; other cases submit real
-- funded transactions. Index validation applies even when phase 2 fails and the
-- ordinary outputs will not be created.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.OutputIndexSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import qualified Cardano.Ledger.Dijkstra.Rules as Rules
import Cardano.Ledger.Val (inject)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Maybe (listToMaybe)
import Data.Maybe.Strict (StrictMaybe (..))
import qualified Data.Sequence.Strict as SSeq
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement as Settlement
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement.OutputIndex as Index
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
  mutateSubTxDeclaration,
  mutateTopTxDeclaration,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release as Release
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM, freshKeyAddrNoPtr_)
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe, shouldSatisfy)
import Validation (Validation (..))

{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-OUTPUT-INDEX - The index selects an own regular output" $ do
    -- Every selected output has enough ADA, so only sequence membership can fail.
    -- Each generated sequence checks its first/last position and out-of-range positions.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-P01 - outputCoins ≥ requiredRelease ⇒ (indexValid(body, index) ⇔ 0 ≤ index < |ownOutputs(body)|)" $
      forAll Index.indexBoundaries $ \(count, gap) -> do
        address <- freshKeyAddrNoPtr_ :: ImpTestM DijkstraEra Addr
        let outputs = SSeq.fromList $ replicate count $ mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 10_000_000
            topBody = mkBasicTxBody & outputsTxBodyL .~ outputs :: TxBody TopTx DijkstraEra
            childBody = mkBasicTxBody & outputsTxBodyL .~ outputs :: TxBody SubTx DijkstraEra
        forM_ [0, max 0 (count - 1), count, count + gap] $ \position -> do
          let index = TxIx $ fromIntegral position
          Rules.validateSettlementOutput topBody index (Coin 3_000_000)
            `shouldBe` if position < count then Success ()
              else Failure (InvalidSettlementOutput (txIdTxBody topBody) index :| [])
          Rules.validateSettlementOutput childBody index (Coin 3_000_000)
            `shouldBe` if position < count then Success ()
              else Failure (InvalidSettlementOutput (txIdTxBody childBody) index :| [])

    -- The first missing own index is invalid for both TopTx and a child.
    -- Rejection preserves the valid control, which is accepted afterward.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F01 - index = |ownOutputs(body)| ⇒ rejectedWith(InvalidSettlementOutput)" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts count [count, count] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
            childReleases = SubTx.releasedDeposits proposal
        control <- Balance.buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0) | Coin amount <- childReleases]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs count [count, count]
        let index = TxIx $ fromIntegral count
        invalidTop <- mutateTopTxDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput index)) control
        submitTx invalidTop >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.topBodyId invalidTop) index)
        forM_ (zip [0 ..] childReleases) $ \(position, Coin released) -> do
          invalidChild <- mutateSubTxDeclaration position
            (SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) (SubTx.SubTxSettlementOutput index)) control
          submitTx invalidChild >>= isRejectedOnlyWith
            (DepositStoreFailure $ InvalidSettlementOutput (Index.childBodyId position invalidChild) index)
        submitTx control >>= isAccepted

    -- An existing TopTx output cannot satisfy a child's missing own index.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F02 - |ownOutputs(subTx)| ≤ index < |ownOutputs(topTx)| ⇒ rejectedWith(InvalidSettlementOutput(subTx))" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts (count + 1) [count, count] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
            childReleases = SubTx.releasedDeposits proposal
        control <- Balance.buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0) | Coin amount <- childReleases]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs (count + 1) [count, count]
        Coin released <- expectJust $ listToMaybe childReleases
        let index = TxIx $ fromIntegral count
        (Index.childOutputCount 0 control, Index.topOutputCount control) `shouldBe` (count, count + 1)
        invalid <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) (SubTx.SubTxSettlementOutput index)) control
        submitTx invalid >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.childBodyId 0 invalid) index)
        submitTx control >>= isAccepted

    -- Collateral return receives the reference immediately after ordinary TopTx
    -- outputs, but that reference is not an ordinary settlement destination.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F03 - collateralReturn ≠ ∅ ∧ index = |ownOutputs(topTx)| ⇒ rejectedWith(InvalidSettlementOutput(topTx))" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts count [count, count] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
            childReleases = SubTx.releasedDeposits proposal
        control <- Balance.buildAndSignPhase2InvalidTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0) | Coin amount <- childReleases]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs count [count, count]
        control ^. bodyTxL . collateralReturnTxBodyL `shouldSatisfy` (/= SNothing)
        let index = TxIx $ fromIntegral count
        invalid <- mutateTopTxDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput index)) control
        submitTx invalid >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.topBodyId invalid) index)
        submitTx control >>= isAccepted

    -- A child with no outputs cannot select output zero locally. Changing its
    -- responsibility also removes TopTx's now-unnecessary settlement selector;
    -- the total declaration and all application value stay unchanged.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F04 - ownOutputs(subTx) = ∅ ∧ releasedDeposits(subTx) > 0 ∧ localIndex = 0 ⇒ rejectedWith(InvalidSettlementOutput(subTx))" $
      forAll Settlement.finalInputsWithoutOutputs $ \scenario -> do
        proposal <- Settlement.withoutSubTxOutputs <$> fundAccountingScenario scenario
        let Coin released = TopTx.releasedDeposits proposal
        control <- Release.buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount released) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) SubTx.DelegateToTopTx]) proposal)
        Index.childOutputCount 0 control `shouldBe` 0
        invalid <- mutateTopTxDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount released) TopTx.NoTopTxSettlement) control
          >>= mutateSubTxDeclaration 0
            (SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) (SubTx.SubTxSettlementOutput $ TxIx 0))
        submitTx invalid >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.childBodyId 0 invalid) (TxIx 0))
        submitTx control >>= isAccepted

    -- First and last own outputs are valid at both body levels. Each choice
    -- runs on fresh inputs, so acceptance of the first cannot consume the last's fixture.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-N01 - |ownOutputs(body)| > 0 ∧ index ∈ {0, |ownOutputs(body)| - 1} ⇒ accepted" $
      forAll Index.localReleases $ \(scenario, count) ->
        forM_ [0, count - 1] $ \position -> do
          proposal <- Index.withOutputCounts count [count, count] <$> fundAccountingScenario scenario
          let Coin totalRelease = TopTx.releasedDeposits proposal
              index = TxIx $ fromIntegral position
          Balance.buildAndSignTx (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput index))
              [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput index) | Coin amount <- SubTx.releasedDeposits proposal]) proposal)
            >>= Balance.resignTx . Index.resizeOutputs count [count, count]
            >>= submitTx >>= isAccepted

    -- A nested child's larger output sequence does not extend TopTx's sequence.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F05 - |ownOutputs(topTx)| ≤ index < |ownOutputs(subTx)| ⇒ rejectedWith(InvalidSettlementOutput(topTx))" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts count [count + 1, count] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
        control <- Balance.buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0) | Coin amount <- SubTx.releasedDeposits proposal]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs count [count + 1, count]
        let index = TxIx $ fromIntegral count
        (Index.topOutputCount control, Index.childOutputCount 0 control) `shouldBe` (count, count + 1)
        invalid <- mutateTopTxDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput index)) control
        submitTx invalid >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.topBodyId invalid) index)
        submitTx control >>= isAccepted

    -- Child zero cannot borrow child one's longer sequence, even though both
    -- children release deposits in the same globally balanced transaction.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F06 - |ownOutputs(subTx)| ≤ index < |ownOutputs(sibling)| ⇒ rejectedWith(InvalidSettlementOutput(subTx))" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts count [count, count + 1] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
            childReleases = SubTx.releasedDeposits proposal
        control <- Balance.buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0) | Coin amount <- childReleases]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs count [count, count + 1]
        Coin released <- expectJust $ listToMaybe childReleases
        let index = TxIx $ fromIntegral count
        (Index.childOutputCount 0 control, Index.childOutputCount 1 control) `shouldBe` (count, count + 1)
        invalid <- mutateSubTxDeclaration 0
          (SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) (SubTx.SubTxSettlementOutput index)) control
        submitTx invalid >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.childBodyId 0 invalid) index)
        submitTx control >>= isAccepted

    -- Real phase-2 failure still validates the ordinary destination selectors.
    -- The selected ordinary outputs are proposals; their creation does not execute.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-N02 - phase2 = invalid ∧ ∀ body: 0 ≤ selectedIndex(body) < |ownOutputs(body)| ⇒ accepted" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts count [count, count] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
            index = TxIx $ fromIntegral $ count - 1
        Balance.buildAndSignPhase2InvalidTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput index))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput index) | Coin amount <- SubTx.releasedDeposits proposal]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs count [count, count]
          >>= submitTx >>= isAccepted

    -- An out-of-range ordinary selector rejects both TopTx and child proposals
    -- on the phase-2 failure path. Only the index changes; collateral stays valid.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-F07 - phase2 = invalid ∧ selectedIndex(body) = |ownOutputs(body)| ⇒ rejectedWith(InvalidSettlementOutput)" $
      forAll Index.localReleases $ \(scenario, count) -> do
        proposal <- Index.withOutputCounts count [count, count] <$> fundAccountingScenario scenario
        let Coin totalRelease = TopTx.releasedDeposits proposal
            childReleases = SubTx.releasedDeposits proposal
        control <- Balance.buildAndSignPhase2InvalidTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0) | Coin amount <- childReleases]) proposal)
          >>= Balance.resignTx . Index.resizeOutputs count [count, count]
        let index = TxIx $ fromIntegral count
        invalidTop <- mutateTopTxDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) (TopTx.TopTxSettlementOutput index)) control
        submitTx invalidTop >>= isRejectedOnlyWith
          (DepositStoreFailure $ InvalidSettlementOutput (Index.topBodyId invalidTop) index)
        forM_ (zip [0 ..] childReleases) $ \(position, Coin released) -> do
          invalidChild <- mutateSubTxDeclaration position
            (SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) (SubTx.SubTxSettlementOutput index)) control
          submitTx invalidChild >>= isRejectedOnlyWith
            (DepositStoreFailure $ InvalidSettlementOutput (Index.childBodyId position invalidChild) index)
        submitTx control >>= isAccepted

    -- A child with no output explicitly delegates its release. TopTx declares
    -- the same total and selects its own ordinary output for that responsibility.
    prop "DS-TX-SETTLEMENT-OUTPUT-INDEX-N03 - ownOutputs(subTx) = ∅ ∧ releasedDeposits(subTx) > 0 ∧ delegatesReleaseToTopTx ⇒ accepted" $
      forAll Settlement.finalInputsWithoutOutputs $ \scenario -> do
        proposal <- Settlement.withoutSubTxOutputs <$> fundAccountingScenario scenario
        let Coin released = TopTx.releasedDeposits proposal
        signedTx <- Release.buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount released) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount released) SubTx.DelegateToTopTx]) proposal)
        Index.childOutputCount 0 signedTx `shouldBe` 0
        submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
