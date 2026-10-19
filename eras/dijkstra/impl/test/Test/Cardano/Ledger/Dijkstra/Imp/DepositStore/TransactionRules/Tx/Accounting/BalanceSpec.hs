{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Integrate the declared Store transfer into the complete transaction balance.
-- NetChange validates the amount independently; these cases keep declarations exact.
-- Every ordinary proposal has only funded inputs, outputs, fees and Store transfers.
-- Certificates, withdrawals, mint, governance proposals, donations and direct deposits
-- are absent. Native assets are minted in a separate accepted funding transaction.
--
-- Valid controls are independently balanced after normal fee preparation. Mutations
-- change implicit application outputs or fees, then re-sign without any fixup.
-- Key-only scenarios allow financial imbalance between bodies in normal mode.
-- Ordinary balance is required only when phase 2 is valid. N08 is an acceptance
-- control with genuine script failure, not a claim that ordinary balance is enforced.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.BalanceSpec (spec) where

import Cardano.Ledger.BaseTypes (Mismatch (..), TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import Cardano.Ledger.Val (Val ((<->)))
import Test.Cardano.Ledger.Common (Spec, chooseInteger, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.Balance as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx as Parent
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedWith,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance (
  buildAndSignPhase2InvalidTx,
  buildAndSignTx,
  fundNativeAssets,
  fundTenAdaWithTwoAdaDeposit,
  observeBalance,
  resignTx,
 )
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Keep each declaration and acceptance decision beside the financial scenario.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-TX-ACCOUNTING-BALANCE - Balance" $ do
  -- Common premises: exact declarations and every non-balance rule satisfied.
  -- Phase 2 is valid except N08. Values include all asset quantities and identities.
  -- inputValue/outputValue sum application values across TopTx and all its SubTxs.
  -- fees is TopTx's fee; declaredNetDeposit is its signed complete Store total.
  -- consumedValue = inputValue + inject(max(0, -declaredNetDeposit)).
  -- producedValue = outputValue + inject(fees + max(0, declaredNetDeposit)).
  -- transactionBalance = consumedValue - producedValue (a full asset Value).
  -- adaBalance/nativeAssetBalance are its ADA/native-asset components.
  -- Δ denotes a change from the independently balanced control. Only the listed
  -- outputs/fees change; inputs and declarations stay fixed. outputAdjustment
  -- changes TopTx output zero. Unqualified coin amounts are lovelace.
  -- N06/N07/F04 use a single child with no new allocation and no other child flows;
  -- TopTx funds its base fee separately, and only the stated fee contribution varies.
  -- feeContribution(subTx) is ADA redirected from its output to increased TopTx
  -- fees; it is an observed financial flow, not another declaration field.

  -- Every ordinary input/output asset and the signed Store transfer balances.
  -- Funding mints native assets separately; this proposed transaction does not mint.
  prop "DS-TX-ACCOUNTING-BALANCE-P01 - phase2Valid ∧ accepted ⇒ inputValue + inject(max(0, -declaredNetDeposit)) = outputValue + inject(fees + max(0, declaredNetDeposit))" $
    forAll ((,) <$> Accounting.arbitraryScenario <*> chooseInteger (1, 10)) $ \(scenario, quantity) -> do
      funded <- fundAccountingScenario scenario
      (_, proposal) <- fundNativeAssets quantity funded
      signedTx <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.netDeposit proposal of
              Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
              Coin amount | amount < 0 -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount)
                (if Parent.ownNetDeposit proposal < Coin 0 then TopTx.TopTxSettlementOutput $ TxIx 0 else TopTx.NoTopTxSettlement)
              _ -> TopTx.DeclaresZeroNetUTxODeposit)
            [ case allocated <-> released of
               Coin amount | amount > 0 -> SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
               Coin amount | amount < 0 -> SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
               _ -> SubTx.DeclaresZeroNetUTxODeposit
            | (allocated, released) <- zip (SubTx.allocatedDeposits proposal) (SubTx.releasedDeposits proposal)
            ]) proposal)
      observed <- observeBalance signedTx
      submitTx signedTx >>= isAccepted
      Balance.consumedValue observed `shouldBe` Balance.producedValue observed

  -- Child zero funds child one; neither must balance independently.
  -- ΔoutputCoins(subTx₀) = -transfer; ΔoutputCoins(subTx₁) = transfer.
  -- All three perturbations retain exact declarations and the same ordinary inputs.
  prop "DS-TX-ACCOUNTING-BALANCE-P02 - phase2Valid ∧ transfer > 0 ∧ outputAdjustment ∈ {-1, 0, 1} ⇒ (accepted ⇔ transactionBalance = 0)" $
    forAll ((,) <$> Balance.twoChildren <*> Balance.transferAmount) $ \(scenario, transfer) -> do
      proposal <- fundAccountingScenario scenario
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.allocatedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
      forM_ [Coin (-1), Coin 1, Coin 0] $ \difference -> do
        signedTx <- resignTx $ Balance.changeTopOutputCoins difference $ Balance.transferBetweenSubTxs transfer control
        observed <- observeBalance signedTx
        submitTx signedTx >>= if Balance.isBalanced observed
          then isAccepted
          else isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
              Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))

  -- Net allocation is funded exactly once.
  -- Omitting or duplicating the financial Store transfer changes only application
  -- output ADA. The exact declarations and independently balanced control are retained.
  prop "DS-TX-ACCOUNTING-BALANCE-N01 - declaredNetDeposit > 0 ∧ outputAdjustment ∈ {-declaredNetDeposit, 0, declaredNetDeposit} ⇒ (accepted ⇔ outputAdjustment = 0)" $
    forAll Balance.allocation $ \scenario -> do
      proposal <- fundAccountingScenario scenario
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.allocatedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
      forM_ [TopTx.netDeposit proposal, Coin 0 <-> TopTx.netDeposit proposal] $ \difference -> do
        signedTx <- resignTx $ Balance.changeTopOutputCoins difference control
        observed <- observeBalance signedTx
        submitTx signedTx >>= isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
            Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))
      submitTx control >>= isAccepted

  -- Net release is available exactly once.
  -- Omitting or duplicating the financial Store transfer changes only application
  -- output ADA. The exact declarations and independently balanced control are retained.
  prop "DS-TX-ACCOUNTING-BALANCE-N02 - declaredNetDeposit < 0 ∧ outputAdjustment ∈ {-declaredNetDeposit, 0, declaredNetDeposit} ⇒ (accepted ⇔ outputAdjustment = 0)" $
    forAll Balance.release $ \scenario -> do
      proposal <- fundAccountingScenario scenario
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.releasedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
            | Coin amount <- SubTx.releasedDeposits proposal
            ]) proposal)
      forM_ [TopTx.netDeposit proposal, Coin 0 <-> TopTx.netDeposit proposal] $ \difference -> do
        signedTx <- resignTx $ Balance.changeTopOutputCoins difference control
        observed <- observeBalance signedTx
        submitTx signedTx >>= isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
            Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))
      submitTx control >>= isAccepted

  -- One SubTx funds another without changing the complete transaction balance.
  prop "DS-TX-ACCOUNTING-BALANCE-N03 - transfer > 0 ∧ ΔoutputCoins(subTx₀) = -transfer ∧ ΔoutputCoins(subTx₁) = transfer ⇒ accepted" $
    forAll ((,) <$> Balance.twoChildren <*> Balance.transferAmount) $ \(scenario, transfer) -> do
      proposal <- fundAccountingScenario scenario
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.allocatedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
      resignTx (Balance.transferBetweenSubTxs transfer control) >>= submitTx >>= isAccepted

  -- A SubTx contributes application ADA to TopTx fees.
  prop "DS-TX-ACCOUNTING-BALANCE-N04 - contribution > 0 ∧ ΔoutputCoins(subTx) = -contribution ∧ Δfees = contribution ⇒ accepted" $
    forAll ((,) <$> Balance.allocation <*> Balance.transferAmount) $ \(scenario, transfer) -> do
      proposal <- fundAccountingScenario scenario
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.allocatedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
      resignTx (Balance.contributeSubTxCoinsToFees transfer control) >>= submitTx >>= isAccepted

  -- Check both a deficit and an unaccounted surplus of exactly one lovelace.
  prop "DS-TX-ACCOUNTING-BALANCE-F01 - ΔoutputCoins(topTx) ∈ {-1, 1} ⇒ rejected" $
    forAll Balance.allocation $ \scenario -> do
      proposal <- fundAccountingScenario scenario
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.allocatedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
      forM_ [Coin (-1), Coin 1] $ \difference -> do
        signedTx <- resignTx $ Balance.changeTopOutputCoins difference control
        observed <- observeBalance signedTx
        submitTx signedTx >>= isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
            Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))
      submitTx control >>= isAccepted

  -- Missing, extra and different native assets all fail; ADA and declarations stay exact.
  prop "DS-TX-ACCOUNTING-BALANCE-F02 - adaBalance = 0 ∧ nativeAssetBalance ≠ 0 ⇒ rejected" $
    forAll ((,) <$> Balance.allocation <*> chooseInteger (1, 10)) $ \(scenario, quantity) -> do
      funded <- fundAccountingScenario scenario
      (tokens, proposal) <- fundNativeAssets quantity funded
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.allocatedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount)
            [ SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
            | Coin amount <- SubTx.allocatedDeposits proposal
            ]) proposal)
      forM_ [(<-> tokens), (<> tokens), Balance.differentAsset] $ \change -> do
        signedTx <- resignTx $ Balance.changeNativeAssetOutput change control
        observed <- observeBalance signedTx
        submitTx signedTx >>= isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
            Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))
      submitTx control >>= isAccepted

  -- The request remains exact, but allocating the same funds to another ordinary
  -- output leaves the declared Store allocation unfunded.
  prop "DS-TX-ACCOUNTING-BALANCE-F03 - requestedAllocation > 0 ∧ ΔoutputCoins(topTx) = requestedAllocation ⇒ rejected" $
    forAll Balance.delegatedAllocation $ \scenario -> do
      proposal <- fundAccountingScenario scenario
      let Coin requiredAllocation = TopTx.allocatedDeposits proposal
      control <- buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount requiredAllocation)
          [SubTx.RequestsUTxODepositFromTopTx $ positiveAmount requiredAllocation]) proposal)
      signedTx <- resignTx $ Balance.changeTopOutputCoins (Coin requiredAllocation) control
      observed <- observeBalance signedTx
      submitTx signedTx >>= isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
          Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))
      submitTx control >>= isAccepted

  -- The two delegated amounts cancel in TopTx's total, while both operations exist.
  prop "DS-TX-ACCOUNTING-BALANCE-N05 - requestedAllocation = delegatedRelease > 0 ∧ declaredNetDeposit = 0 ∧ transactionBalance = 0 ⇒ accepted" $
    forAll Balance.offsettingDelegations $ \scenario -> do
      proposal <- fundAccountingScenario scenario
      let Coin amount = TopTx.allocatedDeposits proposal
      buildAndSignTx (TopTx.addDeclaration
        (Declarations TopTx.DeclaresZeroNetUTxODeposit
          [ SubTx.RequestsUTxODepositFromTopTx $ positiveAmount amount
          , SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) SubTx.DelegateToTopTx
          ]) proposal) >>= submitTx >>= isAccepted

  -- One SubTx: application input 10 ADA + recorded Store release 2 ADA → output 12 ADA.
  -- TopTx's independently funded inputs pay the fee; the child has no other flows.
  prop "DS-TX-ACCOUNTING-BALANCE-N06 - inputCoins(subTx) = 10 ADA ∧ releasedDeposits(subTx) = 2 ADA ∧ outputCoins(subTx) = 12 ADA ∧ feeContribution(subTx) = 0 ⇒ accepted" $
    forAll Balance.topFunding $ \funding -> do
      proposal <- fundTenAdaWithTwoAdaDeposit funding
      buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal) >>= submitTx >>= isAccepted

  -- The child receives 10 ADA; exactly the released 2 ADA increases TopTx's fee.
  prop "DS-TX-ACCOUNTING-BALANCE-N07 - inputCoins(subTx) = 10 ADA ∧ releasedDeposits(subTx) = 2 ADA ∧ outputCoins(subTx) = 10 ADA ∧ feeContribution(subTx) = 2 ADA ⇒ accepted" $
    forAll Balance.topFunding $ \funding -> do
      proposal <- fundTenAdaWithTwoAdaDeposit funding
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal)
      resignTx (Balance.contributeSubTxCoinsToFees (Coin 2_000_000) control) >>= submitTx >>= isAccepted

  -- Removing the same 2 ADA without any fee export leaves an unaccounted surplus.
  prop "DS-TX-ACCOUNTING-BALANCE-F04 - inputCoins(subTx) = 10 ADA ∧ releasedDeposits(subTx) = 2 ADA ∧ outputCoins(subTx) = 10 ADA ∧ feeContribution(subTx) = 0 ⇒ rejected" $
    forAll Balance.topFunding $ \funding -> do
      proposal <- fundTenAdaWithTwoAdaDeposit funding
      control <- buildAndSignTx (TopTx.addDeclaration
          (Declarations
            (TopTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) TopTx.NoTopTxSettlement)
            [SubTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) (SubTx.SubTxSettlementOutput $ TxIx 0)]) proposal)
      signedTx <- resignTx $ Balance.changeSubTxOutputCoins 0 (Coin (-2_000_000)) control
      observed <- observeBalance signedTx
      submitTx signedTx >>= isRejectedWith (Shelley.ValueNotConservedUTxO @DijkstraEra $
          Mismatch (Balance.consumedValue observed) (Balance.producedValue observed))
      submitTx control >>= isAccepted

  -- A genuinely failing phase-2 script takes the collateral outcome. This accepted
  -- balanced control does not claim that ordinary balance is checked on that path.
  prop "DS-TX-ACCOUNTING-BALANCE-N08 - phase2Invalid ∧ transactionBalance = 0 ⇒ accepted" $
    forAll Balance.release $ \scenario -> do
      proposal <- fundAccountingScenario scenario
      buildAndSignPhase2InvalidTx (TopTx.addDeclaration
          (Declarations
            (case TopTx.releasedDeposits proposal of
              Coin amount -> TopTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (TopTx.TopTxSettlementOutput $ TxIx 0))
            [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) (SubTx.SubTxSettlementOutput $ TxIx 0)
            | Coin amount <- SubTx.releasedDeposits proposal
            ]) proposal) >>= submitTx >>= isAccepted
{- FOURMOLU_ENABLE -}
