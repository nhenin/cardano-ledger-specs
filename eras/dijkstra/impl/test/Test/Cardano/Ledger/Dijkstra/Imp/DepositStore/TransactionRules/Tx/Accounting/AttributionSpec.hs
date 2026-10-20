{-# LANGUAGE NamedFieldPuns #-}

-- | Signed accounting responsibility: local changes remain with their SubTx;
-- delegated changes join TopTx's own change. These checks apply to all net signs,
-- independently of the settlement designation required for a net-release total.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.AttributionSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Val ((<->))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.Attribution (
  AttributionAmounts (..),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.Attribution as Attribution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx as Parent
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance as Balance
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Exact originating amounts and their signed attribution are separate contracts.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-ACCOUNTING-ATTRIBUTION - Local and delegated accounting responsibility" $ do
    -- Every declaration form has an independently observed originating amount.
    -- Local allocation/release stays with the child; requests/delegated releases
    -- belong to TopTx, alongside its own priced allocations and recorded releases.
    -- These signed projections apply to positive, zero and negative batch totals.
    prop "DS-TX-ACCOUNTING-ATTRIBUTION-P01 - attributedTopTxChange = ownTopTxChange + Σ delegatedSubTxChange ∧ localSubTxChanges = expectedLocalChanges" $
      forAll Attribution.everyDeclarationForm $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let AttributionAmounts{ownTopTxChange, localAllocationAmount, delegatedAllocationAmount, localReleaseAmount, delegatedReleaseAmount} = Attribution.attributionAmounts proposal
            expectedTopTxChange = (ownTopTxChange <> Coin delegatedAllocationAmount) <-> Coin delegatedReleaseAmount
            declared = TopTx.addDeclaration
              (Declarations
                (case TopTx.netDeposit proposal of
                  Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                  Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                    (if expectedTopTxChange < Coin 0 then TopTx.TopTxSettlementOutput $ TxIx 0 else TopTx.NoTopTxSettlement)
                  _ -> TopTx.DeclaresZeroNetUTxODeposit)
                [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount localAllocationAmount
                , SubTx.RequestsUTxODepositFromTopTx $ positiveAmount delegatedAllocationAmount
                , SubTx.DeclaresNetUTxODepositRelease (positiveAmount localReleaseAmount) (SubTx.SubTxSettlementOutput $ TxIx 0)
                , SubTx.DeclaresNetUTxODepositRelease (positiveAmount delegatedReleaseAmount) SubTx.DelegateToTopTx
                , SubTx.DeclaresZeroNetUTxODeposit
                , SubTx.NoUTxODepositDeclaration
                ]) proposal
        Attribution.observedOriginatingSubTxChanges declared `shouldBe` Attribution.subTxNetChanges proposal
        Attribution.observedLocalSubTxChanges declared
          `shouldBe` [Coin localAllocationAmount, Coin 0, Coin (negate localReleaseAmount), Coin 0, Coin 0, Coin 0]
        Attribution.observedTopTxChange declared `shouldBe` expectedTopTxChange

    -- Switching the same originating operation from local accounting to delegation
    -- moves its signed amount from the child to TopTx. Inputs/outputs and the declared
    -- total stay fixed. This isolated comparison does not promise unchanged acceptance:
    -- the settlement selector and application funding may also need adjustment.
    prop "DS-TX-ACCOUNTING-ATTRIBUTION-P02 - local → delegated ⇒ ΔlocalSubTxChange = -originatingChange ∧ ΔattributedTopTxChange = originatingChange" $
      forAll Parent.allocationAndReleaseDelegation $ \(allocationScenario, releaseScenario) ->
        forM_ [allocationScenario, releaseScenario] $ \scenario -> do
          proposal <- fundAccountingScenario scenario
          let Coin originatingChange = foldMap id $ Attribution.subTxNetChanges proposal
              totalDeclaration = case TopTx.netDeposit proposal of
                Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) TopTx.NoTopTxSettlement
                _ -> TopTx.DeclaresZeroNetUTxODeposit
              local = TopTx.addDeclaration
                (Declarations totalDeclaration
                  [ if originatingChange > 0
                      then SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount originatingChange
                      else SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate originatingChange) (SubTx.SubTxSettlementOutput $ TxIx 0)
                  ]) proposal
              delegated = TopTx.addDeclaration
                (Declarations totalDeclaration
                  [ if originatingChange > 0
                      then SubTx.RequestsUTxODepositFromTopTx $ positiveAmount originatingChange
                      else SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate originatingChange) SubTx.DelegateToTopTx
                  ]) proposal
          (foldMap id (Attribution.observedLocalSubTxChanges delegated) <-> foldMap id (Attribution.observedLocalSubTxChanges local))
            `shouldBe` Coin (negate originatingChange)
          (Attribution.observedTopTxChange delegated <-> Attribution.observedTopTxChange local)
            `shouldBe` Coin originatingChange
          Attribution.observedOriginatingSubTxChanges local `shouldBe` [Coin originatingChange]
          Attribution.observedOriginatingSubTxChanges delegated `shouldBe` [Coin originatingChange]

    -- Explicit zero is not a request: both an active child with equal positive
    -- allocations/releases and an inactive child contribute zero everywhere.
    -- Their parent's independently measured own amount remains its responsibility.
    prop "DS-TX-ACCOUNTING-ATTRIBUTION-N01 - allocatedDeposits(subTx) = releasedDeposits(subTx) ∧ explicitZero ⇒ originatingChange = localChange = delegatedChange = 0" $
      forAll Attribution.activeAndInactiveZeroChildren $ \scenario -> do
        proposal <- fundAccountingScenario scenario
        let declared = TopTx.addDeclaration
              (Declarations
                (case Parent.ownNetDeposit proposal of
                  Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
                  Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (TopTx.TopTxSettlementOutput $ TxIx 0)
                  _ -> TopTx.DeclaresZeroNetUTxODeposit)
                [SubTx.DeclaresZeroNetUTxODeposit, SubTx.DeclaresZeroNetUTxODeposit]) proposal
        Attribution.observedOriginatingSubTxChanges declared `shouldBe` [Coin 0, Coin 0]
        Attribution.observedLocalSubTxChanges declared `shouldBe` [Coin 0, Coin 0]
        Attribution.observedTopTxChange declared `shouldBe` Parent.ownNetDeposit proposal
        Balance.buildAndSignTx declared >>= submitTx >>= isAccepted

{- FOURMOLU_ENABLE -}
