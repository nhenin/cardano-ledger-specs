{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | SubTx declaration grammar, including explicit funding requests and release targets.
-- These checks establish representation, without resolving transaction activity.
-- Shared Codecs assertions cover both CBOR and JSON.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Grammar.SubTxSpec (spec) where

import Cardano.Ledger.Dijkstra.UTxODeposit.SubTx (SubTxNetUTxODepositChange, SubTxReleaseTarget)
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin)
import Data.Either (isLeft)
import Test.Cardano.Ledger.Common (
  Spec,
  describe,
  forAll,
  forAllShrink,
  forM_,
  prop,
  shrink,
 )
import Test.Cardano.Ledger.Core.Arbitrary ()
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding as Codecs
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Assertions (
  shouldAllBe,
  shouldAllSatisfy,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "SubTx" $ do
  describe "Amounts: allocation, release and funding-request declarations require Coins > 0 (StrictlyPositiveCoin)" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-P02 - preserves StrictlyPositiveCoin amounts in every SubTx declaration form" $ \(strictlyPositiveAmount :: StrictlyPositiveCoin) ->
      forAll (SubTx.allDeclarationsWithAmount strictlyPositiveAmount) $ \declarations ->
        forM_ declarations $ \originalDeclaration ->
          Codecs.roundTrips originalDeclaration `shouldAllBe` Right originalDeclaration
    prop "DS-TX-DECLARATIONS-GRAMMAR-F07 - rejects zero amounts in SubTx declarations" $
      forAll (SubTx.allDeclarationInputsWithAmount 0) $ \inputs ->
        Codecs.decodeInputs @SubTxNetUTxODepositChange inputs `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F08 - rejects negative amounts in SubTx declarations" $
      forAll (SubTx.allDeclarationInputsWithAmount (-1)) $ \inputs ->
        Codecs.decodeInputs @SubTxNetUTxODepositChange inputs `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F09 - rejects overflowing amounts in SubTx declarations" $
      forAll (SubTx.allDeclarationInputsWithAmount (2 ^ (64 :: Int))) $ \inputs ->
        Codecs.decodeInputs @SubTxNetUTxODepositChange inputs `shouldAllSatisfy` isLeft

  describe "Absence: Absent ≠ ExplicitZero Declarations for SubTx" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-N04 - preserves the distinction between an absent SubTx declaration and explicit zero" $
      forAll SubTx.absentAndExplicitZero $ \(absentBody, explicitZeroBody) -> do
        forM_ [absentBody, explicitZeroBody] $ \body ->
          Codecs.bodyRoundTrips body `shouldAllBe` Right body
        Codecs.encodingsEqual absentBody explicitZeroBody `shouldAllBe` False

  describe "Forms: Preserve each SubTx operation, including funding requests" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-N06 - preserves every SubTx declaration form, amount and target" $
      forAll SubTx.declarationsAtBounds $ \declarations ->
        forM_ declarations $ \declaration ->
          Codecs.roundTrips declaration `shouldAllBe` Right declaration

  describe "Structure: Reject unknown operations and missing required fields" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-F03 - rejects unknown SubTx operations, missing required fields and invalid declaration structures" $
      forAll SubTx.declarationsWithInvalidStructure $ \inputs ->
        Codecs.decodeInputs @SubTxNetUTxODepositChange inputs `shouldAllSatisfy` isLeft

  describe "Destinations: release to TopTx or a local output index in 0…65535" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-F05 - rejects unknown release targets, missing local indices and invalid target structures" $
      forAll SubTx.releaseTargetsWithInvalidStructure $ \inputs ->
        Codecs.decodeInputs @SubTxReleaseTarget inputs `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F10 - rejects negative SubTx release output indices" $
      forAllShrink SubTx.negativeOutputIndex (filter (< 0) . shrink) $ \outputIndex ->
        Codecs.decodeInputs @SubTxReleaseTarget (SubTx.localReleaseTargetWithIndex outputIndex)
          `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F11 - rejects SubTx release output indices above 65535" $
      forAllShrink SubTx.overflowingOutputIndex (filter (> 65535) . shrink) $ \outputIndex ->
        Codecs.decodeInputs @SubTxReleaseTarget (SubTx.localReleaseTargetWithIndex outputIndex)
          `shouldAllSatisfy` isLeft
{- FOURMOLU_ENABLE -}
