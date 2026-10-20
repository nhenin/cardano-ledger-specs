{-# LANGUAGE NumericUnderscores #-}

-- | Application ADA in a designated output covers its own settlement obligation.
-- A Store-backed output's external deposit is excluded. This is a lower bound,
-- not a stronger guarantee about refund recipients or independent SubTx balance.
-- Ledger cases keep declarations exact and every non-coverage rule satisfied.
-- Boundary mutations redistribute ADA to another implicit output, preserving the
-- complete transaction balance. The same ordinary check runs on the phase-2-invalid path.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.OutputCoinSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure (DepositStoreFailure))
import Cardano.Ledger.Val ((<->))
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Common (Spec, chooseInteger, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement.OutputCoin as OutputCoin
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance as Balance
import Test.Cardano.Ledger.Imp.Common (shouldBe)
import Validation (Validation (..))

-- | Keep the declaration DSL and the tested output-coin relation in each case.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-TX-SETTLEMENT-OUTPUT-COIN - Each designated output contains at least its required settlement ADA" $ do
  -- Common premises: a real selected output and correct settlement designation.
  -- requiredSettlement is the positive own release of a locally accounting body.
  -- For TopTx it is its attributed share, which may differ from the batch release.
  -- applicationADA excludes the external deposit attached to a Store-backed output.

  -- Generated boundary oracle, for TopTx/SubTx and implicit/Store-backed outputs.
  -- This isolated check tests the lower bound directly, without claiming ledger validity.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-P01 - validOutputIndex ⇒ (passesOutputCoinValidation ⇔ applicationADA(selectedOutput) ≥ requiredSettlement)" $
    forAll OutputCoin.anyRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let required = OutputCoin.requiredSettlement scenario proposal
      forM_ [Coin (-1), Coin 0, Coin 1] $ \difference -> do
        let supplied = required <> difference
            tx = OutputCoin.setOutputCoins scenario supplied $ TopTx.unsignedTx proposal
        OutputCoin.validateOutputCoins scenario required tx `shouldBe`
          if supplied >= required
            then Success ()
            else Failure (OutputCoin.insufficientOutputFailure scenario supplied required tx :| [])

  -- One lovelace below the implicit-output bound; the displaced funds remain in the batch.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-F01 - implicitOutput ∧ applicationADA = requiredSettlement - 1 lovelace ⇒ rejectedWith(InsufficientSettlementOutput)" $
    forAll OutputCoin.implicitRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required <> Coin (-1)
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isRejectedOnlyWith
        (DepositStoreFailure $ OutputCoin.insufficientOutputFailure scenario supplied (Coin required) signedTx)

  -- The selected implicit output contains exactly the body's required settlement amount.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-N01 - implicitOutput ∧ applicationADA = requiredSettlement ⇒ accepted" $
    forAll OutputCoin.implicitRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isAccepted

  -- Generated extra ADA is allowed; coverage is a lower bound rather than equality.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-N02 - implicitOutput ∧ applicationADA > requiredSettlement ⇒ accepted" $
    forAll ((,) <$> OutputCoin.implicitRelease <*> chooseInteger (1, 1_000_000)) $ \(scenario, extra) -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required <> Coin extra
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isAccepted

  -- The external deposit covers the numerical deficit but does not count as application ADA.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-F02 - storeBackedOutput ∧ applicationADA < requiredSettlement ≤ applicationADA + externalDeposit ⇒ rejectedWith(InsufficientSettlementOutput)" $
    forAll OutputCoin.storeBackedRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required <> Coin (-1)
      (supplied < Coin required && supplied <> OutputCoin.selectedExternalDeposit scenario proposal >= Coin required)
        `shouldBe` True
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isRejectedOnlyWith
        (DepositStoreFailure $ OutputCoin.insufficientOutputFailure scenario supplied (Coin required) signedTx)

  -- A Store-backed output satisfies the bound using only its application ADA.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-N03 - storeBackedOutput ∧ applicationADA = requiredSettlement ⇒ accepted" $
    forAll OutputCoin.storeBackedRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isAccepted

  -- Parent and child settle their own releases locally. TopTx's declaration is
  -- the complete total, but its selected output needs only its own smaller share.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-N04 - 0 < topTxSettlement < batchRelease ∧ applicationADA(topTxOutput) = topTxSettlement ⇒ accepted" $
    forAll OutputCoin.smallerTopTxShare $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          Coin childRelease = Coin 0 <-> OutputCoin.childNetChange proposal
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario))
          [SubTx.DeclaresNetUTxODepositRelease (positiveAmount childRelease)
            (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)]) proposal)
      OutputCoin.redistributeOutputCoins scenario proposal (Coin required) control
        >>= submitTx >>= isAccepted

  -- A genuinely failing script retains covered ordinary outputs at either body level and in either form.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-N05 - phase2Invalid ∧ applicationADA = requiredSettlement ⇒ accepted" $
    forAll OutputCoin.anyRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required
      control <- Balance.buildAndSignPhase2InvalidTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isAccepted

  -- Phase-2 failure does not waive the ordinary settlement-output lower bound.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-F03 - phase2Invalid ∧ applicationADA = requiredSettlement - 1 lovelace ⇒ rejectedWith(InsufficientSettlementOutput)" $
    forAll OutputCoin.anyRelease $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let Coin required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          supplied = Coin required <> Coin (-1)
      control <- Balance.buildAndSignPhase2InvalidTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (if OutputCoin.body scenario == OutputCoin.TopTxBody
              then TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario
              else TopTx.NoTopTxSettlement))
          [ SubTx.DeclaresNetUTxODepositRelease (positiveAmount required)
              (SubTx.SubTxSettlementOutput $ OutputCoin.outputIndex scenario)
          | OutputCoin.body scenario == OutputCoin.SubTxBody
          ]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal supplied control
      submitTx signedTx >>= isRejectedOnlyWith
        (DepositStoreFailure $ OutputCoin.insufficientOutputFailure scenario supplied (Coin required) signedTx)

  -- The child allocates locally while TopTx releases. The smaller batch release
  -- cannot replace TopTx's larger own settlement amount; the transaction still balances.
  prop "DS-TX-SETTLEMENT-OUTPUT-COIN-F04 - batchRelease < topTxSettlement ∧ applicationADA(topTxOutput) = batchRelease ⇒ rejectedWith(InsufficientSettlementOutput)" $
    forAll OutputCoin.largerTopTxShare $ \scenario -> do
      proposal <- OutputCoin.fund scenario
      let required = OutputCoin.requiredSettlement scenario proposal
          Coin totalRelease = Coin 0 <-> TopTx.netDeposit proposal
          Coin childAllocation = OutputCoin.childNetChange proposal
      control <- Balance.buildAndSignTx (TopTx.addDeclaration
        (Declarations
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease)
            (TopTx.TopTxSettlementOutput $ OutputCoin.outputIndex scenario))
          [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount childAllocation]) proposal)
      signedTx <- OutputCoin.redistributeOutputCoins scenario proposal (Coin totalRelease) control
      submitTx signedTx >>= isRejectedOnlyWith
        (DepositStoreFailure $ OutputCoin.insufficientOutputFailure scenario (Coin totalRelease) required signedTx)
{- FOURMOLU_ENABLE -}
