{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | Store-backed outputs pay for storage externally; implicit outputs must retain
-- their minimum ADA. These cases isolate that distinction with fully funded,
-- exactly declared deposits and otherwise valid transactions.
--
-- Each generated sample covers TopTx and SubTx outputs, on both phase-2 outcomes.
-- Invalid phase 2 uses a genuinely failing script and valid collateral. Acceptance
-- then means the collateral outcome, not creation of the proposed ordinary output.
-- Every selected output survives preparation unchanged. Minimum coin is calculated
-- independently from its final encoded size, including the coin's own encoded width.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.MinimumCoinSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (
  DijkstraSubUtxoPredFailure (SubBabbageOutputTooSmallUTxO),
  DijkstraUtxoPredFailure (BabbageOutputTooSmallUTxO),
 )
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.MinimumCoin (
  Body (..),
  Fixture (..),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.MinimumCoin as MinimumCoin
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )

-- | Keep the output condition, exact declaration and submission result together.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-MINIMUM-COIN - Minimum coin" $ do
    -- Native assets need no accompanying application ADA when their storage
    -- deposit is funded externally. Tokens come from an accepted funding transaction.
    prop "DS-TX-MINIMUM-COIN-N01 - storeBacked(output) ∧ nativeAssets(output) ≠ ∅ ∧ applicationADA(output) = 0 ⇒ accepted" $
      forAll MinimumCoin.storeBackedNativeAssets $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          Fixture{proposal, allocatedDeposit = Coin deposit} <- MinimumCoin.fund scenario
          MinimumCoin.buildAndSignTx scenario (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount deposit)
              (case MinimumCoin.body scenario of
                TopTxOutput -> []
                SubTxOutput -> [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount deposit])) proposal)
            >>= submitTx >>= isAccepted

    -- Datum-only and reference-script-only are exercised separately in every
    -- sample. Neither needs application assets; both still require a full deposit.
    prop "DS-TX-MINIMUM-COIN-N02 - storeBacked(output) ∧ applicationAssets(output) = ∅ ∧ payload(output) ∈ {datumOnly, referenceScriptOnly} ⇒ accepted" $
      forAll MinimumCoin.storeBackedDatumOrReferenceScript $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          Fixture{proposal, allocatedDeposit = Coin deposit} <- MinimumCoin.fund scenario
          MinimumCoin.buildAndSignTx scenario (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount deposit)
              (case MinimumCoin.body scenario of
                TopTxOutput -> []
                SubTxOutput -> [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount deposit])) proposal)
            >>= submitTx >>= isAccepted

    -- An address-only output also occupies storage. Empty application assets,
    -- absent datum and absent reference script do not impose an ADA minimum.
    prop "DS-TX-MINIMUM-COIN-N03 - storeBacked(output) ∧ addressOnly(output) ⇒ accepted" $
      forAll MinimumCoin.storeBackedAddressOnly $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          Fixture{proposal, allocatedDeposit = Coin deposit} <- MinimumCoin.fund scenario
          MinimumCoin.buildAndSignTx scenario (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount deposit)
              (case MinimumCoin.body scenario of
                TopTxOutput -> []
                SubTxOutput -> [SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount deposit])) proposal)
            >>= submitTx >>= isAccepted

    -- Implicit outputs pay for their storage through ADA in the output itself.
    -- Equality is sufficient; there is no external allocation or declaration.
    prop "DS-TX-MINIMUM-COIN-N04 - implicit(output) ∧ outputADA(output) = minimumCoin(output) ⇒ accepted" $
      forAll MinimumCoin.implicitMinimum $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          Fixture{proposal} <- MinimumCoin.fund scenario
          MinimumCoin.buildAndSignTx scenario proposal >>= submitTx >>= isAccepted

    -- Move one lovelace from the selected output to another implicit output.
    -- Balance and encoded width stay unchanged: only the minimum-coin bound fails.
    -- The original exact-minimum control is accepted after the rejected variant.
    prop "DS-TX-MINIMUM-COIN-F01 - implicit(output) ∧ outputADA(output) = minimumCoin(output) - 1 ⇒ rejected" $
      forAll MinimumCoin.implicitMinimum $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          Fixture{proposal, requiredMinimum} <- MinimumCoin.fund scenario
          control <- MinimumCoin.buildAndSignTx scenario proposal
          belowMinimum <- MinimumCoin.oneLovelaceBelowMinimum scenario control
          outcome <- submitTx belowMinimum
          case MinimumCoin.body scenario of
            TopTxOutput -> isRejectedOnlyWith
              (BabbageOutputTooSmallUTxO @DijkstraEra $ (MinimumCoin.selectedOutput scenario belowMinimum, requiredMinimum) :| []) outcome
            SubTxOutput -> isRejectedOnlyWith
              (SubBabbageOutputTooSmallUTxO @DijkstraEra $ (MinimumCoin.selectedOutput scenario belowMinimum, requiredMinimum) :| []) outcome
          submitTx control >>= isAccepted
{- FOURMOLU_ENABLE -}
