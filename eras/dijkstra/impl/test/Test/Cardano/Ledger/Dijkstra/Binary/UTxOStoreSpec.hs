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
import qualified Cardano.Ledger.State.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Cardano.Ledger.TxOut.IndexedTxOs as IndexedTxOs
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
  choose,
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
  prop "selection ⇒ acceptedSize and historical calculation are preserved exactly" $ \txId ->
    forAll storeOutput $ \output -> do
      accepted <- acceptedOutput output
      let first = TxIn txId $ TxIx 0
          second = TxIn txId $ TxIx 1
          absent = TxIn txId $ TxIx 2
          old = Unspent accepted (DepositCalculationV1 oldRate)
          new = Unspent accepted (DepositCalculationV2 newRate)
          entries = IndexedUTxOs.fromList [(first, old), (second, new)]
          selected = IndexedUTxOs.singleton first old
          retained = IndexedUTxOs.singleton second new
      IndexedUTxOs.lookupUTxO first entries `shouldBe` Just old
      IndexedUTxOs.restrictToInputs (Set.fromList [first, absent]) entries `shouldBe` selected
      IndexedUTxOs.withoutInputs (Set.fromList [first, absent]) entries `shouldBe` retained
      IndexedUTxOs.extractInputs (Set.fromList [first, absent]) entries `shouldBe` (retained, selected)
      IndexedUTxOs.filterByTxOut (== output) entries `shouldBe` entries
      restored <-
        expectRight . Binary.decodeFull @(IndexedUTxOs DijkstraEra) version $
          Binary.serialize version entries
      restored `shouldBe` entries

  prop
    "activation ⇒ historical entries and total unchanged; only subsequent allocations use the new calculation"
    $ \txId ->
      forAll storeOutput $ \output -> do
        accepted <- acceptedOutput output
        let oldInput = TxIn txId $ TxIx 0
            newInput = TxIn txId $ TxIx 1
            oldCalculation = DepositCalculationV1 oldRate
            oldEntry = Unspent accepted oldCalculation
            previous = allocate (IndexedTxOs.singleton oldInput accepted) (emptyUTxOStore oldCalculation)
        forM_ [DepositCalculationV1 newRate, DepositCalculationV2 newRate] $ \newCalculation -> do
          let activated = activateNewCalculation newCalculation previous
          currentCalculation activated `shouldBe` newCalculation
          allocations activated `shouldBe` allocations previous
          totalDepositAmount activated `shouldBe` totalDepositAmount previous
          let updated = allocate (IndexedTxOs.singleton newInput accepted) activated
          lookupUTxO oldInput (allocations updated) `shouldBe` Just oldEntry
          lookupUTxO newInput (allocations updated) `shouldBe` Just (Unspent accepted newCalculation)
          allocatedDepositTotalAmount (Set.singleton oldInput) (allocations updated)
            `shouldBe` DepositAmount (price 1000 accepted)
          let released = release (Set.singleton oldInput) updated
          cachedTotal released `shouldBe` price 2000 accepted
          currentCalculation released `shouldBe` newCalculation
          Binary.decodeFull version (Binary.serialize version released) `shouldBe` Right released

  prop "empty Store snapshot ⇒ current calculation preserved without inferring it from entries" $ \calculation -> do
    let store = emptyUTxOStore calculation :: UTxOStore DijkstraEra
    forM_ [Binary.encCBOR store, encodeUTxOStore store] $ \encoding -> do
      restored <-
        expectRight $ Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version encoding)
      currentCalculation restored `shouldBe` calculation
      restored `shouldBe` store

  prop
    "snapshotRestore ⇒ acceptedSize and creationPrice preserved, even when canonicalSize is shorter"
    $ \txId ->
      forAll storeOutput $ \backed ->
        forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output -> do
          accepted <- acceptedOutput output
          let entry = Unspent {sizedOutput = accepted, depositCalculation = DepositCalculationV1 oldRate}
              canonical = Binary.mkSized version $ Binary.sizedValue accepted
              expectedDeposit = case output of
                LegacyTxOut _ -> Coin 0
                NewTxOut _ -> price 1000 accepted
          Binary.sizedSize canonical `shouldBe` Binary.sizedSize accepted - 1
          entry
            `shouldSatisfy` (/= Unspent {sizedOutput = canonical, depositCalculation = DepositCalculationV1 oldRate})
          let store =
                mkUTxOStore (DepositCalculationV1 newRate) . IndexedUTxOs $
                  Map.singleton (TxIn txId $ TxIx 0) entry
          mapM_
            ( \encoding -> do
                restored <-
                  expectRight $
                    Binary.decodeFull @(UTxOStore DijkstraEra) version $
                      Binary.serialize version encoding
                restored `shouldBe` store
                restoredEntry <- expectJust $ lookupUTxO (TxIn txId $ TxIx 0) $ allocations restored
                Binary.sizedValue (sizedOutput restoredEntry) `shouldBe` output
                Binary.sizedSize (sizedOutput restoredEntry) `shouldBe` Binary.sizedSize accepted
                depositCalculation restoredEntry `shouldBe` DepositCalculationV1 oldRate
                Unspent.depositAmount restoredEntry `shouldBe` expectedDeposit
                cachedTotal restored `shouldBe` expectedDeposit
            )
            [Binary.encCBOR store, encodeUTxOStore store]

  prop
    "mixed creationPrices ⇒ release and allocate preserve unrelated metadata and exact cached total"
    $ \txId ->
      forAll storeOutput $ \output -> do
        accepted <- acceptedOutput output
        let old = Unspent {sizedOutput = accepted, depositCalculation = DepositCalculationV1 oldRate}
            newer = Unspent {sizedOutput = accepted, depositCalculation = DepositCalculationV1 newRate}
            oldInput = TxIn txId $ TxIx 0
            newInput = TxIn txId $ TxIx 1
            createdInput = TxIn txId $ TxIx 2
        old `shouldSatisfy` (/= newer)
        let store =
              mkUTxOStore (DepositCalculationV1 newRate) . IndexedUTxOs $
                Map.fromList [(oldInput, old), (newInput, newer)]
        allocatedDepositTotalAmount (Set.fromList [oldInput, newInput]) (allocations store)
          `shouldBe` DepositAmount (price 1000 accepted <> price 2000 accepted)
        allocatedDepositTotalAmount (Set.singleton oldInput) (allocations store)
          `shouldBe` DepositAmount (price 1000 accepted)

        -- Release removes the historical deposit and leaves the newer entry intact.
        let storeAfterRelease = release (Set.singleton oldInput) store
        cachedTotal storeAfterRelease `shouldBe` price 2000 accepted
        allocations storeAfterRelease `shouldBe` IndexedUTxOs (Map.singleton newInput newer)

        let updated =
              allocate (IndexedTxOs.singleton createdInput accepted)
                . release (Set.singleton oldInput)
                $ store
        cachedTotal updated `shouldBe` price 4000 accepted
        lookupUTxO oldInput (allocations updated) `shouldBe` Nothing
        lookupUTxO newInput (allocations updated) `shouldBe` Just newer
        lookupUTxO createdInput (allocations updated) `shouldBe` Just newer
        -- Allocation at an existing input replaces its historical deposit.
        let replaced = allocate (IndexedTxOs.singleton oldInput accepted) store
        cachedTotal replaced `shouldBe` price 4000 accepted
        allocations replaced
          `shouldBe` IndexedUTxOs (Map.fromList [(oldInput, newer), (newInput, newer)])

        -- Releasing that input first must not subtract its old deposit twice.
        let storeAfterReallocation =
              allocate (IndexedTxOs.singleton oldInput accepted)
                . release (Set.singleton oldInput)
                $ store
        storeAfterReallocation `shouldBe` replaced

  prop
    "legacy outputs at any valid price and zero-price new outputs retain metadata with zero external deposits"
    $ \txId address creationRate -> do
      let implicit = mkBasicTxOutWithImplicitDeposit address mempty :: TxOut DijkstraEra
          backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
          legacyInput = TxIn txId $ TxIx 0
          backedInput = TxIn txId $ TxIx 1
          legacy =
            Unspent
              { sizedOutput = Binary.mkSized version implicit
              , depositCalculation = DepositCalculationV1 creationRate
              }
          zero =
            Unspent
              { sizedOutput = Binary.mkSized version backed
              , depositCalculation = DepositCalculationV1 $ rate 0
              }
          store =
            mkUTxOStore (DepositCalculationV1 newRate) . IndexedUTxOs $
              Map.fromList [(legacyInput, legacy), (backedInput, zero)]
      cachedTotal store `shouldBe` Coin 0
      case (Unspent.toTxOut legacy, Unspent.toTxOut zero) of
        (LegacyTxOut _, NewTxOut _) -> do
          sizedOutput legacy `shouldBe` Binary.mkSized version implicit
          depositCalculation legacy `shouldBe` DepositCalculationV1 creationRate
          sizedOutput zero `shouldBe` Binary.mkSized version backed
          depositCalculation zero `shouldBe` DepositCalculationV1 (rate 0)
        _ -> expectationFailure "Expected distinct legacy and zero-priced Store-backed allocations"
      Unspent.depositAmount legacy `shouldBe` Coin 0
      Unspent.depositAmount zero `shouldBe` Coin 0
      IndexedUTxOs.inputIds (allocations store) `shouldBe` Set.fromList [legacyInput, backedInput]
      Binary.decodeFull version (Binary.serialize version store) `shouldBe` Right store

  prop "legacy import preserves references and output values with no external deposits" $ \txId ->
    forAll (arbitrary @(LegacyTxOut DijkstraEra)) $ \output -> do
      let input = TxIn txId $ TxIx 0
          store = fromLegacyAllocations @DijkstraEra $ Map.singleton input output
      allocations store `shouldBe` IndexedUTxOs.singleton input (Unspent.fromLegacyTxOut output)
      cachedTotal store `shouldBe` Coin 0
      Binary.decodeFull version (Binary.serialize version store) `shouldBe` Right store

  prop "negative persisted output size ⇒ decoding rejected" $
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output ->
        forM_ [DepositCalculationV1 oldRate, DepositCalculationV2 oldRate] $ \calculation ->
          forM_ [-1, minBound] $ \size ->
            decodeAllocation (unspentEncoding output size calculation) `shouldSatisfy` isLeft

  prop "V1 and V2 use the same pure formula at generated sizes, zero and numeric boundaries" $
    \(CoinPerByte (CompactCoin generatedRate)) ->
      forAll (choose (0, maxBound :: Int64)) $ \generatedSize ->
        forM_ [0, 1, maxBound, generatedSize] $ \size ->
          forM_ [0, 1, maxBound, generatedRate] $ \coinsPerByte -> do
            let expected = Coin $ (160 + toInteger size) * toInteger coinsPerByte
                calculationRate = rate coinsPerByte
            calculateDeposit (DepositCalculationV1 calculationRate) (ByteSize size)
              `shouldBe` expected
            calculateDeposit (DepositCalculationV2 calculationRate) (ByteSize size)
              `shouldBe` expected

  prop "V2 allocations retain accepted metadata through construction, allocation and codecs" $
    \txId creationRate@(CoinPerByte (CompactCoin coinsPerByte)) ->
      forAll storeOutput $ \backed ->
        forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output -> do
          accepted <- acceptedOutput output
          let calculation = DepositCalculationV2 creationRate
              entry = Unspent accepted calculation
              input = TxIn txId $ TxIx 0
              created = IndexedUTxOs $ Map.singleton input entry
              expected = case output of
                LegacyTxOut _ -> Coin 0
                NewTxOut _ -> price (toInteger coinsPerByte) accepted
          let store = mkUTxOStore calculation created
          cachedTotal store `shouldBe` expected
          Unspent.depositAmount entry `shouldBe` expected
          allocate (IndexedTxOs.singleton input accepted) (emptyUTxOStore calculation) `shouldBe` store
          allocatedDepositTotalAmount (Set.singleton input) (allocations store)
            `shouldBe` DepositAmount expected
          Binary.decodeFull @DepositCalculation version (Binary.serialize version calculation)
            `shouldBe` Right calculation
          decodeAllocation (unspentEncoding output (Binary.sizedSize accepted) calculation)
            `shouldBe` Right entry
          forM_ [Binary.encCBOR store, encodeUTxOStore store] $ \encoding ->
            Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version encoding)
              `shouldBe` Right store

  prop "unknown calculation version 3 is rejected by calculation and entry decoders" $
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithImplicitDeposit (backed ^. addrTxOutL) mempty, backed] $ \output -> do
        let unknownCalculation =
              Binary.encodeListLen 2 <> Binary.encodeWord 3 <> Binary.encCBOR oldRate
        Binary.decodeFull @DepositCalculation
          version
          (Binary.serialize version unknownCalculation)
          `shouldSatisfy` isLeft
        decodeAllocation
          ( Binary.encodeListLen 3
              <> Binary.encCBOR output
              <> Binary.encCBOR (1 :: Int64)
              <> unknownCalculation
          )
          `shouldSatisfy` isLeft

  prop "cachedTotal differing from the sum of historical deposits is rejected" $ \txId ->
    forAll storeOutput $ \output -> do
      accepted <- acceptedOutput output
      let entry = Unspent {sizedOutput = accepted, depositCalculation = DepositCalculationV1 oldRate}
          wire =
            Binary.encodeListLen 3
              <> Binary.encCBOR (DepositCalculationV1 newRate)
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
  -- The retired two-field schema has no current calculation, even when empty.

  prop
    "retired two-field Store snapshots are rejected even when historical entries are valid or empty"
    $ \txId ->
      forAll storeOutput $ \output -> do
        accepted <- acceptedOutput output
        let entry = Unspent accepted (DepositCalculationV1 oldRate)
        forM_ [(Coin 0, Map.empty), (price 1000 accepted, Map.singleton (TxIn txId $ TxIx 0) entry)] $ \retired ->
          Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version retired)
            `shouldSatisfy` isLeft

  prop "rejects retired seven-field Dijkstra snapshots, including an empty old deposit store" $
    forAll (arbitrary @(UTxOState DijkstraEra)) $ \state -> do
      let retired =
            Binary.encodeListLen 7
              <> Binary.encCBOR (IndexedUTxOs Map.empty :: IndexedUTxOs DijkstraEra)
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
            Binary.encodeListLen 3
              <> Binary.encCBOR (DepositCalculationV1 newRate)
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
    cachedTotal = toCoin . totalDepositAmount
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
  case map (toList . (^. sizedOutputsTxBodyL)) bodies of
    [accepted] : _ -> do
      Binary.sizedSize accepted `shouldBe` acceptedBytes
      acceptedBytes `shouldBe` Binary.sizedSize (Binary.mkSized version output) + 1
      pure accepted
    _ -> fail "Expected precisely one decoded output"
