{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | TopTx declaration grammar, including its boundary with SubTx funding requests.
-- These checks establish representation, without resolving transaction activity.
-- Shared Codecs assertions cover both CBOR and JSON.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Grammar.TopTxSpec (spec) where

import Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx (NetUTxODepositChange, TopTxReleaseSettlement)
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin)
import Data.Either (isLeft)
import Test.Cardano.Ledger.Common (
  Spec,
  describe,
  forAll,
  forAllShrink,
  forM_,
  prop,
  shouldSatisfy,
  shrink,
 )
import Test.Cardano.Ledger.Core.Arbitrary ()
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding as Codecs
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.JSON as JSON
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Assertions (
  shouldAllBe,
  shouldAllSatisfy,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.TopTx as TopTx

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "TopTx" $ do
  describe "Amounts: allocation and release declarations require Coins > 0 (StrictlyPositiveCoin)" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-P01 - preserves StrictlyPositiveCoin amounts in every TopTx declaration form" $ \(strictlyPositiveAmount :: StrictlyPositiveCoin) ->
      forAll (TopTx.allDeclarationsWithAmount strictlyPositiveAmount) $ \declarations ->
        forM_ declarations $ \originalDeclaration ->
          Codecs.roundTrips originalDeclaration `shouldAllBe` Right originalDeclaration
    prop "DS-TX-DECLARATIONS-GRAMMAR-F01 - rejects zero amounts in TopTx declarations" $
      forAll (TopTx.allDeclarationInputsWithAmount 0) $ \inputs ->
        Codecs.decodeInputs @NetUTxODepositChange inputs `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F12 - rejects negative amounts in TopTx declarations" $
      forAll (TopTx.allDeclarationInputsWithAmount (-1)) $ \inputs ->
        Codecs.decodeInputs @NetUTxODepositChange inputs `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F13 - rejects overflowing amounts in TopTx declarations" $
      forAll (TopTx.allDeclarationInputsWithAmount (2 ^ (64 :: Int))) $ \inputs ->
        Codecs.decodeInputs @NetUTxODepositChange inputs `shouldAllSatisfy` isLeft

  describe "Absence: Absent ≠ ExplicitZero Declarations for TopTx" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-N03 - preserves the distinction between an absent TopTx declaration and explicit zero" $
      forAll TopTx.absentAndExplicitZero $ \(absentBody, explicitZeroBody) -> do
        forM_ [absentBody, explicitZeroBody] $ \body ->
          Codecs.bodyRoundTrips body `shouldAllBe` Right body
        Codecs.encodingsEqual absentBody explicitZeroBody `shouldAllBe` False

  describe "Forms: Preserve each TopTx operation; funding requests belong to SubTx" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-N05 - preserves every TopTx declaration form, amount and settlement" $
      forAll TopTx.declarationsAtBounds $ \declarations ->
        forM_ declarations $ \declaration ->
          Codecs.roundTrips declaration `shouldAllBe` Right declaration
    prop "DS-TX-DECLARATIONS-GRAMMAR-F06 - rejects a SubTx funding request as a TopTx operation" $
      forAll SubTx.fundingRequest $ \request -> do
        Codecs.roundTrips request `shouldAllBe` Right request
        JSON.decodeAs @NetUTxODepositChange request `shouldSatisfy` isLeft

  describe "Structure: Reject unknown operations and missing required fields" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-F02 - rejects unknown TopTx operations, missing required fields and invalid declaration structures" $
      forAll TopTx.declarationsWithInvalidStructure $ \inputs ->
        Codecs.decodeInputs @NetUTxODepositChange inputs `shouldAllSatisfy` isLeft

  describe "Destinations: no TopTx settlement or a local output index in 0…65535" $ do
    prop "DS-TX-DECLARATIONS-GRAMMAR-F04 - rejects unknown release settlements, missing local indices and invalid settlement structures" $
      forAll TopTx.releaseSettlementsWithInvalidStructure $ \inputs ->
        Codecs.decodeInputs @TopTxReleaseSettlement inputs `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F14 - rejects negative TopTx release output indices" $
      forAllShrink TopTx.negativeOutputIndex (filter (< 0) . shrink) $ \outputIndex ->
        Codecs.decodeInputs @TopTxReleaseSettlement (TopTx.localReleaseSettlementWithIndex outputIndex)
          `shouldAllSatisfy` isLeft
    prop "DS-TX-DECLARATIONS-GRAMMAR-F15 - rejects TopTx release output indices above 65535" $
      forAllShrink TopTx.overflowingOutputIndex (filter (> 65535) . shrink) $ \outputIndex ->
        Codecs.decodeInputs @TopTxReleaseSettlement (TopTx.localReleaseSettlementWithIndex outputIndex)
          `shouldAllSatisfy` isLeft
{- FOURMOLU_ENABLE -}
