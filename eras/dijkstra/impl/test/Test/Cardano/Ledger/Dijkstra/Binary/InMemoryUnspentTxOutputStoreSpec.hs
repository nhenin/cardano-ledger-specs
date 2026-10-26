{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Historical pricing inputs are snapshot data. Recovering them by re-encoding
-- an output or applying the current byte price would change legitimate refunds.
module Test.Cardano.Ledger.Dijkstra.Binary.InMemoryUnspentTxOutputStoreSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (UTxOState (..))
import Cardano.Ledger.State
import Cardano.Ledger.TxIn (TxIn (..))
import Data.Either (isLeft)
import Data.Foldable (toList)
import Data.Int (Int64)
import qualified Data.Map.Strict as Map
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (
  Spec,
  arbitrary,
  describe,
  expectJust,
  expectRight,
  forAll,
  forM_,
  prop,
  shouldBe,
  shouldSatisfy,
 )
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()
import Test.Cardano.Ledger.Dijkstra.Binary.Annotator ()
import Test.Cardano.Ledger.Dijkstra.Binary.TxBodySpec (
  decodedBodies,
  storeOutput,
  withIndefiniteOutput,
 )

spec :: Spec
spec = describe "InMemoryUnspentTxOutputStore historical metadata" $ do
  prop
    "snapshotRestore ⇒ acceptedSize and creationPrice preserved, even when canonicalSize is shorter"
    $ \txId ->
      forAll storeOutput $ \output -> do
        accepted <- acceptedOutput output
        entry <- expectRight $ mkV1Allocation oldRate accepted
        store <- expectRight $ fromAllocations $ Map.singleton (TxIn txId $ TxIx 0) entry
        mapM_
          ( \encoding -> do
              restored <-
                expectRight $
                  Binary.decodeFull @(InMemoryUnspentTxOutputStore DijkstraEra) version $
                    Binary.serialize version encoding
              restored `shouldBe` store
              restoredEntry <- expectJust $ lookupAllocation (TxIn txId $ TxIx 0) restored
              fmap Binary.sizedSize (allocationSizedOutput restoredEntry)
                `shouldBe` Just (Binary.sizedSize accepted)
              allocationCalculation restoredEntry `shouldBe` Just (DepositCalculationV1 oldRate)
              allocationDeposit restoredEntry `shouldBe` Right (price 1000 accepted)
              cachedTotal restored `shouldBe` price 1000 accepted
          )
          [Binary.encCBOR store, encodeInMemoryOutputStore store]

  prop
    "mixed creationPrices ⇒ refund = sum historical deposits; applied delta preserves unrelated metadata and exact cached total"
    $ \txId ->
      forAll storeOutput $ \output -> do
        accepted <- acceptedOutput output
        old <- expectRight $ mkV1Allocation oldRate accepted
        newer <- expectRight $ mkV1Allocation newRate accepted
        let oldInput = TxIn txId $ TxIx 0
            newInput = TxIn txId $ TxIx 1
            createdInput = TxIn txId $ TxIx 2
        store <- expectRight $ fromAllocations $ Map.fromList [(oldInput, old), (newInput, newer)]
        refundForInputs (Set.fromList [oldInput, newInput]) store
          `shouldBe` Right (price 1000 accepted <> price 2000 accepted)
        allocationDepositsForInputs (Set.singleton oldInput) store
          `shouldBe` fmap (\entries -> Map.restrictKeys entries $ Set.singleton oldInput) (allocationDeposits store)
        updated <-
          expectRight $ applyAllocationDelta (Set.singleton oldInput) (Map.singleton createdInput newer) store
        cachedTotal updated `shouldBe` price 4000 accepted
        lookupAllocation oldInput updated `shouldBe` Nothing
        lookupAllocation newInput updated `shouldBe` Just newer
        lookupAllocation createdInput updated `shouldBe` Just newer
        -- A replacement must subtract the old entry exactly once, even when it is
        -- also explicitly consumed. This keeps the public delta operation atomic.
        replaced <-
          expectRight $ applyAllocationDelta (Set.singleton oldInput) (Map.singleton oldInput newer) store
        cachedTotal replaced `shouldBe` price 4000 accepted

  prop
    "legacy and zero-price allocations are valid; only the zero-price Store allocation has an external-deposit record"
    $ \txId address -> do
      let implicit = mkBasicTxOutWithImplicitDeposit address mempty :: TxOut DijkstraEra
          backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
          legacyInput = TxIn txId $ TxIx 0
          backedInput = TxIn txId $ TxIx 1
      legacy <- expectRight $ mkV1Allocation oldRate $ Binary.mkSized version implicit
      zero <- expectRight $ mkV1Allocation (rate 0) $ Binary.mkSized version backed
      store <- expectRight $ fromAllocations $ Map.fromList [(legacyInput, legacy), (backedInput, zero)]
      cachedTotal store `shouldBe` Coin 0
      allocationCalculation legacy `shouldBe` Nothing
      allocationDeposits store `shouldBe` Right (Map.singleton backedInput $ Coin 0)
      Binary.decodeFull version (Binary.serialize version store) `shouldBe` Right store

  prop "missing creation metadata cannot be reconstructed from a Store-backed UTxO" $ \txId ->
    forAll storeOutput $ \output -> do
      let input = TxIn txId $ TxIx 0
      fromLegacyUTxO (UTxO $ Map.singleton input output)
        `shouldBe` Left (MissingHistoricalAllocation input)

  prop "negative acceptedSize is rejected by construction and decoding" $
    forAll storeOutput $ \output -> do
      mkV1Allocation oldRate (Binary.Sized output (-1)) `shouldBe` Left (NegativeOutputSize (-1))
      decodeAllocation (pricedEncoding output (-1) $ DepositCalculationV1 oldRate) `shouldSatisfy` isLeft

  prop "reserved V2 has no formula and cannot enter a decoded allocation" $
    forAll storeOutput $ \output -> do
      calculateDeposit (DepositCalculationV2 oldRate) 1 `shouldBe` Left (UnsupportedDepositCalculation 2)
      Binary.decodeFull @DepositCalculation
        version
        (Binary.serialize version $ DepositCalculationV2 oldRate)
        `shouldSatisfy` isLeft
      decodeAllocation (pricedEncoding output 1 $ DepositCalculationV2 oldRate) `shouldSatisfy` isLeft

  prop "cachedTotal differing from the sum of historical deposits is rejected" $ \txId ->
    forAll storeOutput $ \output -> do
      accepted <- acceptedOutput output
      entry <- expectRight $ mkV1Allocation oldRate accepted
      let wire =
            Binary.encodeListLen 2
              <> Binary.encCBOR (Coin 0)
              <> Binary.encCBOR (Map.singleton (TxIn txId $ TxIx 0) entry)
      Binary.decodeFull @(InMemoryUnspentTxOutputStore DijkstraEra)
        version
        (Binary.serialize version wire)
        `shouldSatisfy` isLeft

  prop "the retired map-only and nonempty [balance, Coin-map] Dijkstra stores are rejected" $ \txId -> do
    let coinMap = Map.singleton (TxIn txId $ TxIx 0) (Coin 1)
    Binary.decodeFull @(InMemoryUnspentTxOutputStore DijkstraEra)
      version
      (Binary.serialize version coinMap)
      `shouldSatisfy` isLeft
    Binary.decodeFull @(InMemoryUnspentTxOutputStore DijkstraEra)
      version
      (Binary.serialize version (Coin 1, coinMap))
      `shouldSatisfy` isLeft
  -- A nonempty historical Coin map has no output, original size or rate.
  -- Empty [0,{}] is structurally the empty new store; era-state schema rejection
  -- is enforced separately by the changed UTxOState schema.

  prop "rejects retired seven-field Dijkstra snapshots, including an empty old deposit store" $
    forAll (arbitrary @(UTxOState DijkstraEra)) $ \state -> do
      let retired =
            Binary.encodeListLen 7
              <> Binary.encCBOR (UTxO Map.empty :: UTxO DijkstraEra)
              <> Binary.encCBOR (utxosDeposited state)
              <> Binary.encCBOR (utxosFees state)
              <> Binary.encCBOR (utxosGovState state)
              <> Binary.encCBOR (utxosInstantStake state)
              <> Binary.encCBOR (utxosDonation state)
              <> Binary.encCBOR (DepositStore Map.empty)
      Binary.decodeFullDecoder
        version
        "retired Dijkstra UTxOState"
        (Binary.decNoShareCBOR @(UTxOState DijkstraEra))
        (Binary.serialize version retired)
        `shouldSatisfy` isLeft

  prop
    "historical-metadata construction errors preserve every payload through their codec"
    $ \txId ->
      forM_
        [ NegativeOutputSize (-1)
        , UnsupportedDepositCalculation 2
        , MissingHistoricalAllocation (TxIn txId $ TxIx 0)
        , CachedDepositTotalMismatch (Coin 1) (Coin 2)
        , ExpectedStoredOutputs
        , ExpectedLegacyOutputs
        ]
        $ \failure -> do
          Binary.decodeFull @OutputStoreError version (Binary.serialize version failure)
            `shouldBe` Right failure

  prop "allocation tags must agree with the actual output variant" $ \address -> do
    let implicit = mkBasicTxOutWithImplicitDeposit address mempty :: TxOut DijkstraEra
        backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
    decodeAllocation (pricedEncoding implicit 1 $ DepositCalculationV1 oldRate) `shouldSatisfy` isLeft
    decodeAllocation (Binary.encodeListLen 2 <> Binary.encodeWord 0 <> Binary.encCBOR backed)
      `shouldSatisfy` isLeft
  where
    version = eraProtVerLow @DijkstraEra
    rate = CoinPerByte . CompactCoin
    oldRate = rate 1000
    newRate = rate 2000
    cachedTotal = unInMemoryOutputDepositAmount . totalDepositAmount
    price n accepted = Coin $ n * (160 + toInteger (Binary.sizedSize accepted))
    decodeAllocation = Binary.decodeFull @(Allocation DijkstraEra) version . Binary.serialize version
    pricedEncoding output size calculation =
      Binary.encodeListLen 4
        <> Binary.encodeWord 1
        <> Binary.encCBOR output
        <> Binary.encCBOR (size :: Int64)
        <> Binary.encCBOR calculation

-- The size comes from an actual accepted, noncanonical transaction body, never
-- from synthesising metadata for an output that has already entered the store.
acceptedOutput :: TxOut DijkstraEra -> IO (Binary.Sized (TxOut DijkstraEra))
acceptedOutput output = do
  let version = eraProtVerLow @DijkstraEra
      body = (mkBasicTxBody :: TxBody TopTx DijkstraEra) & outputsTxBodyL .~ SSeq.singleton output
  (wireBody, acceptedBytes) <- withIndefiniteOutput output body
  bodies <- decodedBodies @TopTx wireBody
  case toList $ head bodies ^. sizedOutputsTxBodyL of
    [accepted] -> do
      Binary.sizedSize accepted `shouldBe` acceptedBytes
      acceptedBytes `shouldBe` Binary.sizedSize (Binary.mkSized version output) + 1
      pure accepted
    _ -> fail "Expected precisely one decoded Store-backed output"
