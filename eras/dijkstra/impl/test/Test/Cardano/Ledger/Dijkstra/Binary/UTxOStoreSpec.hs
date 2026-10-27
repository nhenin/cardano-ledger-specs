{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Historical pricing inputs are snapshot data. Recovering them by re-encoding
-- an output or applying the current byte price would change legitimate refunds.
module Test.Cardano.Ledger.Dijkstra.Binary.UTxOStoreSpec (spec) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (UTxOState (..))
import Cardano.Ledger.State
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
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
  expectationFailure,
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
 )

spec :: Spec
spec = describe "UTxOStore historical metadata" $ do
  prop
    "snapshotRestore ⇒ acceptedSize and creationPrice preserved, even when canonicalSize is shorter"
    $ \txId ->
      forAll storeOutput $ \backed ->
        forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output -> do
          accepted <- acceptedOutput output
          let entry = allocationFromOutput (DepositCalculationV1 oldRate) accepted
              canonical = Binary.mkSized version $ Binary.sizedValue accepted
              expectedDeposit = case output of
                LegacyTxOut _ -> Coin 0
                NewTxOut _ -> price 1000 accepted
          Binary.sizedSize canonical `shouldBe` Binary.sizedSize accepted - 1
          entry `shouldSatisfy` (/= allocationFromOutput (DepositCalculationV1 oldRate) canonical)
          store <- expectRight $ fromAllocations $ Map.singleton (TxIn txId $ TxIx 0) entry
          mapM_
            ( \encoding -> do
                restored <-
                  expectRight $
                    Binary.decodeFull @(UTxOStore DijkstraEra) version $
                      Binary.serialize version encoding
                restored `shouldBe` store
                restoredEntry <- expectJust $ lookupAllocation (TxIn txId $ TxIx 0) restored
                Binary.sizedValue (sizedOutput restoredEntry) `shouldBe` output
                Binary.sizedSize (sizedOutput restoredEntry) `shouldBe` Binary.sizedSize accepted
                depositCalculation restoredEntry `shouldBe` DepositCalculationV1 oldRate
                allocationDeposit restoredEntry `shouldBe` Right expectedDeposit
                cachedTotal restored `shouldBe` expectedDeposit
            )
            [Binary.encCBOR store, encodeUTxOStore store]

  prop
    "mixed creationPrices ⇒ refund = sum historical deposits; applied delta preserves unrelated metadata and exact cached total"
    $ \txId ->
      forAll storeOutput $ \output -> do
        accepted <- acceptedOutput output
        let old = allocationFromOutput (DepositCalculationV1 oldRate) accepted
            newer = allocationFromOutput (DepositCalculationV1 newRate) accepted
            oldInput = TxIn txId $ TxIx 0
            newInput = TxIn txId $ TxIx 1
            createdInput = TxIn txId $ TxIx 2
        old `shouldSatisfy` (/= newer)
        store <- expectRight $ fromAllocations $ Map.fromList [(oldInput, old), (newInput, newer)]
        refundForInputs (Set.fromList [oldInput, newInput]) store
          `shouldBe` Right (price 1000 accepted <> price 2000 accepted)
        refundForInputs (Set.singleton oldInput) store
          `shouldBe` Right (price 1000 accepted)
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
    "legacy outputs at any valid price and zero-price new outputs retain metadata with zero external deposits"
    $ \txId address creationRate -> do
      let implicit = mkBasicTxOutWithImplicitDeposit address mempty :: TxOut DijkstraEra
          backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
          legacyInput = TxIn txId $ TxIx 0
          backedInput = TxIn txId $ TxIx 1
          legacy = allocationFromOutput (DepositCalculationV1 creationRate) $ Binary.mkSized version implicit
          zero = allocationFromOutput (DepositCalculationV1 $ rate 0) $ Binary.mkSized version backed
      store <- expectRight $ fromAllocations $ Map.fromList [(legacyInput, legacy), (backedInput, zero)]
      cachedTotal store `shouldBe` Coin 0
      case (allocationOutput legacy, allocationOutput zero) of
        (LegacyTxOut _, NewTxOut _) -> do
          sizedOutput legacy `shouldBe` Binary.mkSized version implicit
          depositCalculation legacy `shouldBe` DepositCalculationV1 creationRate
          sizedOutput zero `shouldBe` Binary.mkSized version backed
          depositCalculation zero `shouldBe` DepositCalculationV1 (rate 0)
        _ -> expectationFailure "Expected distinct legacy and zero-priced Store-backed allocations"
      allocationDeposit legacy `shouldBe` Right (Coin 0)
      allocationDeposit zero `shouldBe` Right (Coin 0)
      Map.keysSet (unAllocations $ allocations store) `shouldBe` Set.fromList [legacyInput, backedInput]
      Binary.decodeFull version (Binary.serialize version store) `shouldBe` Right store

  prop "missing creation metadata cannot be reconstructed from a Store-backed UTxO" $ \txId ->
    forAll storeOutput $ \output -> do
      let input = TxIn txId $ TxIx 0
      fromLegacyUTxO (UTxO $ Map.singleton input output)
        `shouldBe` Left (MissingHistoricalAllocation input)

  prop "negative acceptedSize is rejected by checked insertion and decoding" $ \txId ->
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output -> do
        let entry = Unspent (Binary.Sized output (-1)) $ DepositCalculationV1 oldRate
            created = Map.singleton (TxIn txId $ TxIx 0) entry
        fromAllocations created `shouldBe` Left (NegativeOutputSize (-1))
        applyAllocationDelta Set.empty created emptyUTxOStore
          `shouldBe` Left (NegativeOutputSize (-1))
        decodeAllocation (unspentEncoding output (-1) $ DepositCalculationV1 oldRate) `shouldSatisfy` isLeft

  prop "reserved V2 has no formula and is rejected by checked insertion and decoding" $ \txId ->
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output -> do
        let entry = Unspent (Binary.Sized output 1) $ DepositCalculationV2 oldRate
            input = TxIn txId $ TxIx 0
            created = Map.singleton input entry
            v1 = Unspent (Binary.Sized output 1) $ DepositCalculationV1 oldRate
        fromAllocations created `shouldBe` Left (UnsupportedDepositCalculation 2)
        applyAllocationDelta Set.empty created emptyUTxOStore
          `shouldBe` Left (UnsupportedDepositCalculation 2)
        control <- expectRight $ fromAllocations $ Map.singleton input v1
        cachedTotal control `shouldBe` case output of
          LegacyTxOut _ -> Coin 0
          NewTxOut _ -> Coin 161000
        calculateDeposit (DepositCalculationV2 oldRate) 1 `shouldBe` Left (UnsupportedDepositCalculation 2)
        Binary.decodeFull @DepositCalculation
          version
          (Binary.serialize version $ DepositCalculationV2 oldRate)
          `shouldSatisfy` isLeft
        decodeAllocation (unspentEncoding output 1 $ DepositCalculationV2 oldRate) `shouldSatisfy` isLeft

  prop "cachedTotal differing from the sum of historical deposits is rejected" $ \txId ->
    forAll storeOutput $ \output -> do
      accepted <- acceptedOutput output
      let entry = allocationFromOutput (DepositCalculationV1 oldRate) accepted
          wire =
            Binary.encodeListLen 2
              <> Binary.encCBOR (Coin 0)
              <> Binary.encCBOR (Map.singleton (TxIn txId $ TxIx 0) entry)
      Binary.decodeFull @(UTxOStore DijkstraEra)
        version
        (Binary.serialize version wire)
        `shouldSatisfy` isLeft

  prop "the retired map-only and nonempty [balance, Coin-map] Dijkstra stores are rejected" $ \txId -> do
    let coinMap = Map.singleton (TxIn txId $ TxIx 0) (Coin 1)
    Binary.decodeFull @(UTxOStore DijkstraEra)
      version
      (Binary.serialize version coinMap)
      `shouldSatisfy` isLeft
    Binary.decodeFull @(UTxOStore DijkstraEra)
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
              <> Binary.encCBOR (Map.empty :: Map.Map TxIn Coin)
      Binary.decodeFullDecoder
        version
        "retired Dijkstra UTxOState"
        (Binary.decNoShareCBOR @(UTxOState DijkstraEra))
        (Binary.serialize version retired)
        `shouldSatisfy` isLeft

  prop
    "historical-metadata construction errors preserve every payload through their codec"
    $ \txId -> do
      forM_
        [ NegativeOutputSize (-1)
        , UnsupportedDepositCalculation 2
        , MissingHistoricalAllocation (TxIn txId $ TxIx 0)
        , CachedDepositTotalMismatch (Coin 1) (Coin 2)
        ]
        $ \failure -> do
          Binary.decodeFull @OutputStoreError version (Binary.serialize version failure)
            `shouldBe` Right failure
      forM_ [4, 5] $ \tag ->
        Binary.decodeFull @OutputStoreError
          version
          (Binary.serialize version $ Binary.encodeListLen 1 <> Binary.encodeWord tag)
          `shouldSatisfy` isLeft

  prop "retired tagged-sum entries and snapshots are rejected for both output variants" $ \txId address -> do
    let implicit = mkBasicTxOutWithImplicitDeposit address mempty :: TxOut DijkstraEra
        backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
        retiredLegacy = Binary.encodeListLen 2 <> Binary.encodeWord 0 <> Binary.encCBOR implicit
        retiredNew =
          Binary.encodeListLen 4
            <> Binary.encodeWord 1
            <> Binary.encCBOR backed
            <> Binary.encCBOR (1 :: Int64)
            <> Binary.encCBOR (DepositCalculationV1 oldRate)
    forM_ [(Coin 0, retiredLegacy), (Coin 161000, retiredNew)] $ \(total, retired) -> do
      decodeAllocation retired `shouldSatisfy` isLeft
      let snapshot =
            Binary.encodeListLen 2
              <> Binary.encCBOR total
              <> Binary.encodeMapLen 1
              <> Binary.encCBOR (TxIn txId $ TxIx 0)
              <> retired
      Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version snapshot)
        `shouldSatisfy` isLeft
  where
    version = eraProtVerLow @DijkstraEra
    rate = CoinPerByte . CompactCoin
    oldRate = rate 1000
    newRate = rate 2000
    cachedTotal = unspentOutputDepositsAmount . totalDepositAmount
    price n accepted = Coin $ n * (160 + toInteger (Binary.sizedSize accepted))
    decodeAllocation = Binary.decodeFull @(Unspent (TxOut DijkstraEra)) version . Binary.serialize version
    unspentEncoding output size calculation =
      Binary.encodeListLen 3
        <> Binary.encCBOR output
        <> Binary.encCBOR (size :: Int64)
        <> Binary.encCBOR calculation

-- The size comes from an actual accepted, noncanonical transaction body, never
-- from synthesising metadata for an output that has already entered the store.
acceptedOutput :: TxOut DijkstraEra -> IO (Binary.Sized (TxOut DijkstraEra))
acceptedOutput output = do
  let version = eraProtVerLow @DijkstraEra
      body = (mkBasicTxBody :: TxBody TopTx DijkstraEra) & outputsTxBodyL .~ SSeq.singleton output
      canonical = BSL.toStrict $ Binary.serialize version output
      (definiteTag, indefiniteTag) = case output of
        LegacyTxOut _ -> (0x82, 0x9f)
        NewTxOut _ -> (0xa2, 0xbf)
      indefinite = BS.cons indefiniteTag (BS.tail canonical) <> BS.singleton 0xff
      bodyBytes = BSL.toStrict $ Binary.serialize version body
      (prefix, suffix) = BS.breakSubstring canonical bodyBytes
      acceptedBytes = fromIntegral $ BS.length indefinite
      wireBody = BSL.fromStrict $ prefix <> indefinite <> BS.drop (BS.length canonical) suffix
  BS.head canonical `shouldBe` definiteTag
  BS.null suffix `shouldBe` False
  Binary.decodeFull @(TxOut DijkstraEra) version (BSL.fromStrict indefinite) `shouldBe` Right output
  bodies <- decodedBodies @TopTx wireBody
  case toList $ head bodies ^. sizedOutputsTxBodyL of
    [accepted] -> do
      Binary.sizedSize accepted `shouldBe` acceptedBytes
      acceptedBytes `shouldBe` Binary.sizedSize (Binary.mkSized version output) + 1
      pure accepted
    _ -> fail "Expected precisely one decoded output"
