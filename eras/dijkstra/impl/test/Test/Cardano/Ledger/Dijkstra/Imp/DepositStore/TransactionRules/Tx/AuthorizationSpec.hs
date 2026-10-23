{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | Existing spending conditions authorize release of a consumed output's deposit.
-- These key-controlled cases establish a real Alice-to-Bob funding lifecycle;
-- they do not claim to exercise script authorization. Each generated sample covers
-- standalone TopTx, a locally settling SubTx and a SubTx delegating to TopTx.
--
-- Common premises: distinct funding and spending keys, a positive recorded deposit,
-- exact declarations, valid settlement, complete financial balance and phase-2 success.
-- spendingSignatures refers to the consuming body; transactionSignatures includes
-- TopTx and every SubTx. Only witnesses change in the rejected variant. Its unchanged
-- inputs, amounts and declarations remain valid, as the accepted control establishes.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AuthorizationSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (
  DijkstraSubUtxowPredFailure (SubMissingVKeyWitnessesUTXOW),
  DijkstraUtxowPredFailure (MissingVKeyWitnessesUTXOW),
 )
import qualified Data.Set as Set
import qualified Data.Set.NonEmpty as NES
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Authorization (
  Fixture (..),
  Mode (..),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Authorization as Authorization
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import Test.Cardano.Ledger.Imp.Common (shouldNotBe, shouldSatisfy)

-- | Keep the declared release, witness premises and ledger outcome visible together.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-AUTHORIZATION - Spending authority authorizes the deposit release" $ do
    -- Alice pays for Bob's output. Bob consumes it without Alice's signature,
    -- whether he settles locally or delegates his release to TopTx.
    prop "DS-TX-AUTHORIZATION-N01 - funder ≠ spender ∧ spender ∈ spendingSignatures ∧ funder ∉ transactionSignatures ⇒ accepted" $
      forAll Authorization.scenarios $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          fundedRelease@Fixture{mode, proposal, recordedDeposit = Coin releasedDeposit, funderKeyHash, spenderKeyHash} <- Authorization.fund scenario
          funderKeyHash `shouldNotBe` spenderKeyHash
          signedTx <- Authorization.buildAndSignTx fundedRelease (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease (positiveAmount releasedDeposit)
                (case mode of
                  LocalSubTx -> TopTx.NoTopTxSettlement
                  _ -> TopTx.TopTxSettlementOutput $ TxIx 0))
              (case mode of
                StandaloneTopTx -> []
                LocalSubTx -> [SubTx.DeclaresNetUTxODepositRelease (positiveAmount releasedDeposit) (SubTx.SubTxSettlementOutput $ TxIx 0)]
                DelegatedSubTx -> [SubTx.DeclaresNetUTxODepositRelease (positiveAmount releasedDeposit) SubTx.DelegateToTopTx])) proposal)
          Authorization.spendingWitnesses fundedRelease signedTx `shouldSatisfy` Set.member spenderKeyHash
          Authorization.allWitnesses signedTx `shouldSatisfy` Set.notMember funderKeyHash
          submitTx signedTx >>= isAccepted

    -- Alice's valid signature cannot replace Bob's required spending signature.
    -- Rejection must contain only the missing-Bob-witness failure. Submit the
    -- original control afterward to prove the same financial proposal is valid.
    prop "DS-TX-AUTHORIZATION-F01 - funder ≠ spender ∧ funder ∈ spendingSignatures ∧ spender ∉ spendingSignatures ⇒ rejectedWith(MissingVKeyWitnessesUTXOW or SubMissingVKeyWitnessesUTXOW)" $
      forAll Authorization.scenarios $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          fundedRelease@Fixture{mode, proposal, recordedDeposit = Coin releasedDeposit, funderKeyHash, spenderKeyHash} <- Authorization.fund scenario
          funderKeyHash `shouldNotBe` spenderKeyHash
          signedTx <- Authorization.buildAndSignTx fundedRelease (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositRelease (positiveAmount releasedDeposit)
                (case mode of
                  LocalSubTx -> TopTx.NoTopTxSettlement
                  _ -> TopTx.TopTxSettlementOutput $ TxIx 0))
              (case mode of
                StandaloneTopTx -> []
                LocalSubTx -> [SubTx.DeclaresNetUTxODepositRelease (positiveAmount releasedDeposit) (SubTx.SubTxSettlementOutput $ TxIx 0)]
                DelegatedSubTx -> [SubTx.DeclaresNetUTxODepositRelease (positiveAmount releasedDeposit) SubTx.DelegateToTopTx])) proposal)
          withoutSpender <- Authorization.replaceSpenderWitnessWithFunder fundedRelease signedTx
          Authorization.spendingWitnesses fundedRelease withoutSpender `shouldSatisfy` Set.member funderKeyHash
          Authorization.spendingWitnesses fundedRelease withoutSpender `shouldSatisfy` Set.notMember spenderKeyHash
          outcome <- submitTx withoutSpender
          case mode of
            StandaloneTopTx -> isRejectedOnlyWith (MissingVKeyWitnessesUTXOW @DijkstraEra $ NES.singleton spenderKeyHash) outcome
            _ -> isRejectedOnlyWith (SubMissingVKeyWitnessesUTXOW @DijkstraEra $ NES.singleton spenderKeyHash) outcome
          submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
