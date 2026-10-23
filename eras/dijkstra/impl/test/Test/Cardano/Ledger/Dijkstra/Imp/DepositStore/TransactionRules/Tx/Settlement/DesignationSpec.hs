-- | TopTx designates an output exactly when a net-release total leaves it a
-- positive release share. Let totalChange include every body and topTxChange
-- include TopTx's own and delegated changes. For totalChange < 0:
-- designationValid ⇔ (hasTopTxOutput ⇔ topTxChange < 0).
-- Allocation and explicit-zero total declarations have no designation field.
-- All amounts are exact, output zero is eligible and sufficiently funded, and
-- the remaining ledger requirements hold. Both phase-2 outcomes enforce this rule.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.DesignationSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import Cardano.Ledger.Val ((<->))
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx as Parent
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement.Designation as Scenario
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  buildAndSignPhase2InvalidTx,
  buildAndSignTx,
  fundAccountingScenario,
 )
import Test.Cardano.Ledger.Imp.Common (shouldBe)
import Validation (Validation (..))

-- | Test the requirement independently of index validity and output amounts.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-SETTLEMENT-DESIGNATION - A net release requires a TopTx output iff TopTx has a release share" $ do
    -- Explore both designation choices and both local/delegated child release forms.
    -- The expectation comes from funded operations, not the production projection.
    prop "DS-TX-SETTLEMENT-DESIGNATION-P01 - totalChange < 0 ⇒ (designationValid ⇔ (hasTopTxOutput ⇔ topTxChange < 0))" $
      forAll Scenario.netReleaseWithAnyTopTxShare $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        forM_ [False, True] $ \delegated -> do
          let topTxChange = Parent.ownNetDeposit proposal <->
                (if delegated then foldMap id $ SubTx.releasedDeposits proposal else Coin 0)
              requiredRelease = max (Coin 0) (Coin 0 <-> topTxChange)
          forM_ [False, True] $ \hasTopTxOutput ->
            Scenario.validateDesignation (TopTx.addDeclaration
              (Declarations
                (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total)
                  (if hasTopTxOutput then TopTx.TopTxSettlementOutput $ TxIx 0 else TopTx.NoTopTxSettlement))
                [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount)
                    (if delegated then SubTx.DelegateToTopTx else SubTx.SubTxSettlementOutput $ TxIx 0)
                | Coin amount <- SubTx.releasedDeposits proposal
                ]) proposal)
              `shouldBe` if hasTopTxOutput == (topTxChange < Coin 0) then Success ()
                else Failure ((if hasTopTxOutput then UnexpectedTopTxSettlement $ TxIx 0
                  else MissingTopTxSettlement requiredRelease) :| [])

    -- All children settle locally; TopTx has no release share.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N01 - totalChange < 0 ∧ topTxChange = 0 ∧ noTopTxOutput ⇒ accepted" $
      forAll Scenario.allReleasesSettledBySubTxs $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) TopTx.NoTopTxSettlement)
            [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
            | Coin amount <- SubTx.releasedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- Standalone TopTx settles its own release in output zero.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N02 - totalChange < 0 ∧ topTxChange < 0 ∧ hasTopTxOutput ⇒ accepted" $
      forAll Scenario.topTxReleasesDeposits $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) (TopTx.TopTxSettlementOutput $ TxIx 0))
            []) proposal)
          >>= submitTx >>= isAccepted

    -- TopTx and the children each designate an output for their own release.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N03 - topTxChange < 0 ∧ (∀ subTx: localChange(subTx) < 0) ∧ allRequiredOutputsDesignated ⇒ accepted" $
      forAll Scenario.releasesSplitAcrossBodies $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
            | Coin amount <- SubTx.releasedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- A child allocation reduces the batch release, not TopTx's release share.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N04 - totalChange < 0 ∧ localSubTxChange > 0 ⇒ requiredTopTxOutputADA > -totalChange ∧ accepted" $
      forAll Scenario.localAllocationsReduceBatchRelease $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        (Coin 0 <-> Parent.ownNetDeposit proposal > Coin (negate total)) `shouldBe` True
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- Exact amounts and valid funding cannot compensate for a missing designation.
    prop "DS-TX-SETTLEMENT-DESIGNATION-F01 - totalChange < 0 ∧ topTxChange < 0 ∧ noTopTxOutput ⇒ rejectedWith(MissingTopTxSettlement)" $
      forAll Scenario.topTxReleasesDeposits $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) TopTx.NoTopTxSettlement)
            []) proposal)
          >>= submitTx >>= isRejectedOnlyWith (DepositStoreFailure $ MissingTopTxSettlement $ Coin (negate total))

    -- Children settle the complete release; an additional TopTx designation is forbidden.
    prop "DS-TX-SETTLEMENT-DESIGNATION-F02 - totalChange < 0 ∧ topTxChange = 0 ∧ hasTopTxOutput ⇒ rejectedWith(UnexpectedTopTxSettlement)" $
      forAll Scenario.allReleasesSettledBySubTxs $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
            | Coin amount <- SubTx.releasedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isRejectedOnlyWith (DepositStoreFailure $ UnexpectedTopTxSettlement $ TxIx 0)

    -- The total is an allocation even though TopTx itself releases deposits.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N05 - totalChange > 0 ∧ topTxChange < 0 ∧ noTopTxOutput ⇒ accepted" $
      forAll Scenario.netAllocation $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount total)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- Equal opposite body changes give explicit zero, which has no designation field.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N06 - totalChange = 0 ∧ topTxChange < 0 ∧ noTopTxOutput ⇒ accepted" $
      forAll Scenario.zeroTotalWithTopTxRelease $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        TopTx.netDeposit proposal `shouldBe` Coin 0
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            TopTx.DeclaresZeroNetUTxODeposit
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- The transaction releases overall, but TopTx itself allocates.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N07 - totalChange < 0 ∧ topTxChange > 0 ∧ noTopTxOutput ⇒ accepted" $
      forAll Scenario.positiveTopTxShare $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let Coin total = TopTx.netDeposit proposal
        buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total) TopTx.NoTopTxSettlement)
            [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
            | Coin amount <- SubTx.releasedDeposits proposal
            ]) proposal)
          >>= submitTx >>= isAccepted

    -- Both required and correctly absent designations survive a real failing script.
    prop "DS-TX-SETTLEMENT-DESIGNATION-N08 - phase2 = invalid ∧ totalChange < 0 ∧ (hasTopTxOutput ⇔ topTxChange < 0) ⇒ accepted" $
      forAll Scenario.bothDesignationBranches $ \(topTxRelease, localSubTxReleases) ->
        forM_ [topTxRelease, localSubTxReleases] $ \scenario -> do
          proposal <- fundAccountingScenario scenario
          let Coin total = TopTx.netDeposit proposal
              topTxReleases = Parent.ownNetDeposit proposal < Coin 0
          buildAndSignPhase2InvalidTx (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total)
                (if topTxReleases then TopTx.TopTxSettlementOutput $ TxIx 0 else TopTx.NoTopTxSettlement))
              [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
              | Coin amount <- SubTx.releasedDeposits proposal
              ]) proposal)
            >>= submitTx >>= isAccepted

    -- Reject both missing and unexpected designations before collateral-only effects apply.
    prop "DS-TX-SETTLEMENT-DESIGNATION-F03 - phase2 = invalid ∧ totalChange < 0 ∧ ¬(hasTopTxOutput ⇔ topTxChange < 0) ⇒ rejectedWith(MissingTopTxSettlement or UnexpectedTopTxSettlement)" $
      forAll Scenario.bothDesignationBranches $ \(topTxRelease, localSubTxReleases) ->
        forM_ [topTxRelease, localSubTxReleases] $ \scenario -> do
          proposal <- fundAccountingScenario scenario
          let Coin total = TopTx.netDeposit proposal
              topTxReleases = Parent.ownNetDeposit proposal < Coin 0
          buildAndSignPhase2InvalidTx (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate total)
                (if topTxReleases then TopTx.NoTopTxSettlement else TopTx.TopTxSettlementOutput $ TxIx 0))
              [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
              | Coin amount <- SubTx.releasedDeposits proposal
              ]) proposal)
            >>= submitTx >>= isRejectedOnlyWith (DepositStoreFailure $
              if topTxReleases then MissingTopTxSettlement $ Coin (negate total)
              else UnexpectedTopTxSettlement $ TxIx 0)
{- FOURMOLU_ENABLE -}
