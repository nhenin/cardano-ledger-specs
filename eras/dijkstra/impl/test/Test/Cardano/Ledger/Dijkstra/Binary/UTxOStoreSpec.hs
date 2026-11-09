{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Snapshots retain outputs, allocation origins and historical formulas for exact refunds.
module Test.Cardano.Ledger.Dijkstra.Binary.UTxOStoreSpec (spec) where

import Cardano.Ledger.BaseTypes (SlotNo (..), TxIx (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula as Formula
import qualified Cardano.Ledger.Dijkstra.UTxOs.Unspent as DijkstraUnspent
import Cardano.Ledger.Shelley.LedgerState (LedgerState (..))
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store.Internals as StoreInternals
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Cardano.Ledger.TxOut.IndexedTxOs as IndexedTxOs
import qualified Cardano.Ledger.Val as Val
import Control.Exception (evaluate)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import Data.Either (isLeft)
import Data.Foldable (toList)
import Data.Int (Int64)
import qualified Data.Map.Strict as Map
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Word (Word64)
import Lens.Micro
import Test.Cardano.Ledger.Common (
  Spec,
  arbitrary,
  describe,
  errorCall,
  expectJust,
  expectRight,
  expectationFailure,
  forAll,
  forM_,
  prop,
  shouldBe,
  shouldSatisfy,
  shouldThrow,
 )
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()
import Test.Cardano.Ledger.Dijkstra.Binary.Annotator ()
import Test.Cardano.Ledger.Dijkstra.Binary.TxBodySpec (
  decodedBodies,
  storeOutput,
 )

spec :: Spec
spec = describe "UTxOStore historical metadata" $ do
  prop "selection ⇒ output and allocatedAt are preserved exactly" $ \txId ->
    forAll storeOutput $ \output -> do
      let first = TxIn txId $ TxIx 0
          second = TxIn txId $ TxIx 1
          absent = TxIn txId $ TxIx 2
          old = Unspent output (AtSlot oldSlot)
          newer = Unspent output (AtSlot newSlot)
          entries = IndexedUTxOs.fromList [(first, old), (second, newer)]
          selected = IndexedUTxOs.singleton first old
          retained = IndexedUTxOs.singleton second newer
      IndexedUTxOs.lookupUTxO first entries `shouldBe` Just old
      IndexedUTxOs.restrictToInputs (Set.fromList [first, absent]) entries `shouldBe` selected
      IndexedUTxOs.withoutInputs (Set.fromList [first, absent]) entries `shouldBe` retained
      IndexedUTxOs.extractInputs (Set.fromList [first, absent]) entries `shouldBe` (retained, selected)
      IndexedUTxOs.filterByTxOut (== output) entries `shouldBe` entries
      restored <-
        expectRight . Binary.decodeFull @(IndexedUTxOs DijkstraEra) version $
          Binary.serialize version entries
      restored `shouldBe` entries

  prop "activation at t ⇒ old refunds unchanged; allocations at t use the new formula" $ \txId ->
    forAll storeOutput $ \output -> do
      let accepted = Binary.mkSized version output
      let oldInput = TxIn txId $ TxIx 0
          newInput = TxIn txId $ TxIx 1
          oldEntry = Unspent output (AtSlot oldSlot)
          initialHistory = mkDepositFormulaHistory $ DepositFormulaV1 oldRate
          previous =
            StoreInternals.allocate oldSlot (IndexedTxOs.singleton oldInput accepted) $
              mkEmptyUTxOStore initialHistory
      forM_ [(DepositFormulaV1 newRate, 250), (DepositFormulaV2 newRate, 260)] $ \(newFormula, base) -> do
        let activated = activateNewFormula newSlot newFormula previous
        currentFormula activated `shouldBe` newFormula
        formulaAt oldSlot (depositFormulaHistory activated) `shouldBe` DepositFormulaV1 oldRate
        allocations activated `shouldBe` allocations previous
        totalDepositAmount activated `shouldBe` totalDepositAmount previous
        let updated = StoreInternals.allocate newSlot (IndexedTxOs.singleton newInput accepted) activated
        lookupUTxO oldInput (allocations updated) `shouldBe` Just oldEntry
        lookupUTxO newInput (allocations updated) `shouldBe` Just (Unspent output (AtSlot newSlot))
        allocatedDepositTotalAmount
          (depositFormulaHistory updated)
          (Set.singleton oldInput)
          (allocations updated)
          `shouldBe` DepositAmount (Coin (250 * 1000))
        let released = StoreInternals.release (Set.singleton oldInput) updated
        cachedTotal released `shouldBe` Coin (2000 * base)
        depositFormulaHistory released `shouldBe` depositFormulaHistory activated
        Binary.decodeFull version (Binary.serialize version released) `shouldBe` Right released

  prop "changed activation at or before an existing allocation ⇒ repricing is rejected" $ \txId ->
    forAll storeOutput $ \output -> do
      let previous =
            mkUTxOStore (mkDepositFormulaHistory $ DepositFormulaV1 oldRate) $
              IndexedUTxOs.singleton (TxIn txId $ TxIx 0) (Unspent output (AtSlot laterSlot))
      forM_ [oldSlot, newSlot, laterSlot] $ \activationSlot ->
        evaluate (activateNewFormula activationSlot (DepositFormulaV1 newRate) previous)
          `shouldThrow` errorCall "Deposit formula activation would reprice existing allocations"
      activateNewFormula newSlot (DepositFormulaV1 oldRate) previous `shouldBe` previous

  prop "empty Store snapshot ⇒ complete history retained without inferring it from entries" $ \history -> do
    let store = mkEmptyUTxOStore history :: UTxOStore DijkstraEra
    restored <-
      expectRight $ Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version store)
    depositFormulaHistory restored `shouldBe` history
    restored `shouldBe` store

  prop "two wire encodings of one output yield identical Store snapshots and refunds" $ \txId ->
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithLegacyTxOut (backed ^. addrTxOutL) mempty, backed] $ \output -> do
        accepted <- acceptedOutput output
        history <-
          expectJust $
            appendFormula newSlot (DepositFormulaV1 newRate) $
              mkDepositFormulaHistory (DepositFormulaV1 oldRate)
        let canonical = Binary.mkSized version output
            input = TxIn txId $ TxIx 0
            allocate bodyOutput =
              StoreInternals.allocate oldSlot (IndexedTxOs.singleton input bodyOutput) $ mkEmptyUTxOStore history
            expectedDeposit = case output of
              LegacyTxOut _ -> Coin 0
              NewTxOut _ -> Coin (250 * 1000)
            store = allocate accepted
        Binary.sizedSize canonical `shouldBe` Binary.sizedSize accepted - 1
        Binary.serialize version store `shouldBe` Binary.serialize version (allocate canonical)
        restored <-
          expectRight $ Binary.decodeFull @(UTxOStore DijkstraEra) version $ Binary.serialize version store
        restored `shouldBe` store
        restoredEntry <- expectJust $ lookupUTxO (TxIn txId $ TxIx 0) $ allocations restored
        Unspent.output restoredEntry `shouldBe` output
        allocatedAt restoredEntry `shouldBe` AtSlot oldSlot
        Unspent.computeExternalDeposit (depositFormulaHistory restored) restoredEntry
          `shouldBe` expectedDeposit
        cachedTotal restored `shouldBe` expectedDeposit

  prop "mixed allocation slots ⇒ release and allocate preserve unrelated entries and exact total" $ \txId ->
    forAll storeOutput $ \output -> do
      let accepted = Binary.mkSized version output
      history <-
        expectJust $
          appendFormula newSlot (DepositFormulaV1 newRate) $
            mkDepositFormulaHistory (DepositFormulaV1 oldRate)
      let old = Unspent {Unspent.output = output, allocatedAt = AtSlot oldSlot}
          newer = Unspent {Unspent.output = output, allocatedAt = AtSlot newSlot}
          oldInput = TxIn txId $ TxIx 0
          newInput = TxIn txId $ TxIx 1
          createdInput = TxIn txId $ TxIx 2
          store = mkUTxOStore history $ IndexedUTxOs.fromList [(oldInput, old), (newInput, newer)]
      old `shouldSatisfy` (/= newer)
      allocatedDepositTotalAmount history (Set.fromList [oldInput, newInput]) (allocations store)
        `shouldBe` DepositAmount (Coin (250 * 1000) <> Coin (250 * 2000))
      allocatedDepositTotalAmount history (Set.singleton oldInput) (allocations store)
        `shouldBe` DepositAmount (Coin (250 * 1000))
      let storeAfterRelease = StoreInternals.release (Set.singleton oldInput) store
      cachedTotal storeAfterRelease `shouldBe` Coin (250 * 2000)
      allocations storeAfterRelease `shouldBe` IndexedUTxOs.singleton newInput newer
      let updated = StoreInternals.allocate laterSlot (IndexedTxOs.singleton createdInput accepted) storeAfterRelease
      cachedTotal updated `shouldBe` Coin (250 * 4000)
      lookupUTxO oldInput (allocations updated) `shouldBe` Nothing
      lookupUTxO newInput (allocations updated) `shouldBe` Just newer
      lookupUTxO createdInput (allocations updated) `shouldBe` Just (Unspent output (AtSlot laterSlot))
      -- Occupied references keep their output and allocation slot.
      let proposedOutput = accepted {Binary.sizedSize = Binary.sizedSize accepted + 1}
          proposed = IndexedTxOs.singleton oldInput proposedOutput
          preserved = StoreInternals.allocate laterSlot proposed store
      preserved `shouldBe` store
      StoreInternals.allocate laterSlot proposed preserved `shouldBe` preserved
      -- Release permits a new allocation with a new slot at the current price.
      let reallocated =
            StoreInternals.allocate laterSlot proposed $ StoreInternals.release (Set.singleton oldInput) store
          recreated = Unspent (Binary.sizedValue proposedOutput) (AtSlot laterSlot)
      cachedTotal reallocated `shouldBe` Coin (250 * 2000) <> Coin (250 * 2000)
      allocations reallocated `shouldBe` IndexedUTxOs.fromList [(oldInput, recreated), (newInput, newer)]
      StoreInternals.allocate laterSlot proposed reallocated `shouldBe` reallocated

  prop "legacy and zero-priced new allocations retain their slots with zero external deposits" $ \txId address creationRate -> do
    let implicit = mkBasicTxOutWithLegacyTxOut address mempty :: TxOut DijkstraEra
        backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
        legacyInput = TxIn txId $ TxIx 0
        backedInput = TxIn txId $ TxIx 1
        legacy = Unspent implicit (AtSlot oldSlot)
        zero = Unspent backed (AtSlot newSlot)
    history <-
      expectJust $
        appendFormula newSlot (DepositFormulaV1 $ rate 0) $
          mkDepositFormulaHistory (DepositFormulaV1 creationRate)
    let store = mkUTxOStore history $ IndexedUTxOs.fromList [(legacyInput, legacy), (backedInput, zero)]
    cachedTotal store `shouldBe` Coin 0
    allocatedAt legacy `shouldBe` AtSlot oldSlot
    allocatedAt zero `shouldBe` AtSlot newSlot
    Unspent.computeExternalDeposit history legacy `shouldBe` Coin 0
    Unspent.computeExternalDeposit history zero `shouldBe` Coin 0
    IndexedUTxOs.inputIds (allocations store) `shouldBe` Set.fromList [legacyInput, backedInput]
    Binary.decodeFull version (Binary.serialize version store) `shouldBe` Right store

  prop "legacy import preserves references and uses the supplied baseline with no external deposits" $ \txId baseline ->
    forAll (arbitrary @(LegacyTxOut DijkstraEra)) $ \output -> do
      let input = TxIn txId $ TxIx 0
          entry = Unspent.fromLegacyTxOut output
          history = mkDepositFormulaHistory baseline
          store = mkUTxOStore history $ IndexedUTxOs.fromLegacyTxOuts $ Map.singleton input output
          expectedReserve =
            min (Unspent.toTxOut entry ^. coinTxOutL) . toCoin $
              Formula.computeDeposit baseline (Unspent.output entry)
      allocations store `shouldBe` IndexedUTxOs.singleton input entry
      allocatedAt entry `shouldBe` AtStoreMigration
      depositFormulaHistory store `shouldBe` history
      currentFormula store `shouldBe` baseline
      cachedTotal store `shouldBe` Coin 0
      DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount expectedReserve
      Unspent.computeExternalDeposit history entry `shouldBe` Coin 0
      Binary.decodeFull version (Binary.serialize version store) `shouldBe` Right store

  prop "baseline-only history ⇒ Dijkstra snapshots preserve empty and populated stores" $ \txId address baseline -> do
    let output = mkBasicTxOutWithLegacyTxOut address mempty :: TxOut DijkstraEra
        entry = Unspent output AtStoreMigration
    forM_ [mempty, IndexedUTxOs.singleton (TxIn txId $ TxIx 0) entry] $ \entries -> do
      let store = mkUTxOStore (mkDepositFormulaHistory baseline) entries
      Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version store)
        `shouldBe` Right store

  prop "AtStoreMigration ⇒ the initial formula remains in force after later activations" $ \txId address -> do
    let output = mkBasicTxOutWithLegacyTxOut address (Val.inject $ Coin 100000000) :: TxOut DijkstraEra
        entry = Unspent output AtStoreMigration
        previous =
          mkUTxOStore (mkDepositFormulaHistory $ DepositFormulaV1 oldRate) $
            IndexedUTxOs.singleton (TxIn txId $ TxIx 0) entry
        updated = activateNewFormula newSlot (DepositFormulaV2 newRate) previous
        expectedReserve = min (output ^. coinTxOutL) $ Coin (250 * 1000)
    DijkstraUnspent.computeDeposit (depositFormulaHistory previous) entry
      `shouldBe` DepositAmount expectedReserve
    DijkstraUnspent.computeApplicationAssets (depositFormulaHistory previous) entry
      `shouldBe` ApplicationAssets (Val.inject $ (output ^. coinTxOutL) Val.<-> expectedReserve)
    DijkstraUnspent.computeDeposit (depositFormulaHistory updated) entry
      `shouldBe` DepositAmount expectedReserve
    Unspent.computeExternalDeposit (depositFormulaHistory updated) entry `shouldBe` Coin 0
    allocations updated `shouldBe` allocations previous
    cachedTotal updated `shouldBe` Coin 0
    restored <-
      expectRight $ Binary.decodeFull @(UTxOStore DijkstraEra) version $ Binary.serialize version updated
    restored `shouldBe` updated
    restoredEntry <- expectJust $ lookupUTxO (TxIn txId $ TxIx 0) $ allocations restored
    allocatedAt restoredEntry `shouldBe` AtStoreMigration
    DijkstraUnspent.computeDeposit (depositFormulaHistory restored) restoredEntry
      `shouldBe` DepositAmount expectedReserve

  prop "allocation marker roundtrip ⇒ migration remains distinct from a real allocation at slot zero" $ \slot ->
    forAll storeOutput $ \output -> do
      forM_ [AtStoreMigration, AtSlot $ SlotNo 0, AtSlot slot] $ \origin -> do
        Binary.decodeFull @AllocatedAt version (Binary.serialize version origin) `shouldBe` Right origin
        decodeAllocation (unspentEncoding output origin)
          `shouldBe` Right (Unspent output origin)
      Binary.serialize version AtStoreMigration
        `shouldSatisfy` (/= Binary.serialize version (AtSlot $ SlotNo 0))

  prop "retired bare allocation slots and unknown allocation markers ⇒ decoding rejected" $
    forAll storeOutput $ \output ->
      forM_
        [ Binary.encCBOR $ SlotNo 0
        , Binary.encCBOR oldSlot
        , Binary.encodeListLen 1 <> Binary.encodeWord 255
        ]
        $ \invalidOrigin -> do
          Binary.decodeFull @AllocatedAt version (Binary.serialize version invalidOrigin)
            `shouldSatisfy` isLeft
          decodeAllocation
            ( Binary.encodeListLen 2
                <> Binary.encCBOR output
                <> invalidOrigin
            )
            `shouldSatisfy` isLeft

  prop "retired three-field entry with accepted size ⇒ decoding rejected" $
    forAll storeOutput $ \output ->
      decodeAllocation
        ( Binary.encodeListLen 3
            <> Binary.encCBOR output
            <> Binary.encCBOR (40 :: Int64)
            <> Binary.encCBOR (AtSlot oldSlot)
        )
        `shouldSatisfy` isLeft

  prop "ADA-only output ⇒ V1 = 250p ∧ V2 = 260p, including the maximum rate" $
    \(CoinPerByte (CompactCoin generatedRate)) ->
      forAll storeOutput $ \output ->
        forM_ [0, 1, maxBound, generatedRate] $ \coinsPerByte -> do
          let p = rate coinsPerByte
          Formula.computeDeposit (DepositFormulaV1 p) output
            `shouldBe` DepositAmount (Coin (250 * toInteger coinsPerByte))
          Formula.computeDeposit (DepositFormulaV2 p) output
            `shouldBe` DepositAmount (Coin (260 * toInteger coinsPerByte))

  prop "V2 allocation ⇒ output and origin survive construction, queries and codecs" $ \txId creationRate@(CoinPerByte (CompactCoin coinsPerByte)) ->
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithLegacyTxOut (backed ^. addrTxOutL) mempty, backed] $ \output -> do
        let accepted = Binary.mkSized version output
        let pricing = DepositFormulaV2 creationRate
            history = mkDepositFormulaHistory pricing
            entry = Unspent output (AtSlot oldSlot)
            input = TxIn txId $ TxIx 0
            entries = IndexedUTxOs.singleton input entry
            expected = case output of
              LegacyTxOut _ -> Coin 0
              NewTxOut _ -> Coin (260 * toInteger coinsPerByte)
            store = mkUTxOStore history entries
        cachedTotal store `shouldBe` expected
        Unspent.computeExternalDeposit history entry `shouldBe` expected
        StoreInternals.allocate oldSlot (IndexedTxOs.singleton input accepted) (mkEmptyUTxOStore history)
          `shouldBe` store
        allocatedDepositTotalAmount history (Set.singleton input) entries `shouldBe` DepositAmount expected
        Binary.decodeFull @DepositFormula version (Binary.serialize version pricing)
          `shouldBe` Right pricing
        decodeAllocation (unspentEncoding output (AtSlot oldSlot))
          `shouldBe` Right entry
        Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version store)
          `shouldBe` Right store

  prop "legacy reserve = min(output ADA, historical price); reserve + application ADA = output ADA" $ \address ->
    forM_ [0, 1, 1000000, 100000000] $ \coins -> do
      let output = mkBasicTxOutWithLegacyTxOut address (Val.inject $ Coin coins) :: TxOut DijkstraEra
          entry = Unspent output (AtSlot oldSlot)
          history = mkDepositFormulaHistory $ DepositFormulaV1 $ rate 4310
          expectedReserve = min (Coin coins) $ Coin (250 * 4310)
          reserve = toCoin $ DijkstraUnspent.computeDeposit history entry
          ApplicationAssets application = DijkstraUnspent.computeApplicationAssets history entry
      reserve `shouldBe` expectedReserve
      reserve <> Val.coin application `shouldBe` Coin coins
      Val.coin application `shouldSatisfy` (>= Coin 0)
      Unspent.computeExternalDeposit history entry `shouldBe` Coin 0
      Unspent.toTxOut entry `shouldBe` output

  prop "new output ⇒ full historical deposit is external; application assets are unchanged" $
    forAll storeOutput $ \output -> do
      let entry = Unspent output (AtSlot oldSlot)
          history = mkDepositFormulaHistory $ DepositFormulaV1 oldRate
      DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin (250 * 1000))
      Unspent.computeExternalDeposit history entry `shouldBe` Coin (250 * 1000)
      case output of
        NewTxOut application ->
          DijkstraUnspent.computeApplicationAssets history entry
            `shouldBe` (application ^. applicationAssetsTxOutL)
        LegacyTxOut _ -> expectationFailure "Expected a Store-backed output"

  prop "allocation before the first change ⇒ baseline deposit and application value" $
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithLegacyTxOut (backed ^. addrTxOutL) (Val.inject $ Coin 100000000), backed] $ \output -> do
        history <-
          expectJust $
            appendFormula newSlot (DepositFormulaV2 newRate) $
              mkDepositFormulaHistory (DepositFormulaV1 oldRate)
        let entry = Unspent output (AtSlot oldSlot)
            baselinePrice = Coin (250 * 1000)
        case output of
          LegacyTxOut legacy -> do
            let reserve = min (output ^. coinTxOutL) baselinePrice
            DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount reserve
            Unspent.computeExternalDeposit history entry `shouldBe` Coin 0
            DijkstraUnspent.computeApplicationAssets history entry
              `shouldBe` ApplicationAssets (Val.modifyCoin (Val.<-> reserve) $ legacy ^. valueTxOutL)
          NewTxOut created -> do
            DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount baselinePrice
            Unspent.computeExternalDeposit history entry `shouldBe` baselinePrice
            DijkstraUnspent.computeApplicationAssets history entry
              `shouldBe` (created ^. applicationAssetsTxOutL)

  prop "allocation before the first change ⇒ snapshot retains the baseline refund" $ \txId ->
    forAll storeOutput $ \backed ->
      forM_ [mkBasicTxOutWithLegacyTxOut (backed ^. addrTxOutL) mempty, backed] $ \output -> do
        history <-
          expectJust $
            appendFormula newSlot (DepositFormulaV2 newRate) $
              mkDepositFormulaHistory (DepositFormulaV1 oldRate)
        let entry = Unspent output (AtSlot oldSlot)
            store = mkUTxOStore history $ IndexedUTxOs.singleton (TxIn txId $ TxIx 0) entry
            expected = DijkstraUnspent.computeDeposit history entry
        restored <-
          expectRight $ Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version store)
        restored `shouldBe` store
        DijkstraUnspent.computeDeposit (depositFormulaHistory restored) entry `shouldBe` expected

  prop "cachedTotal differs from historical external deposits ⇒ decoding rejected" $ \txId ->
    forAll storeOutput $ \output -> do
      let entry = Unspent output (AtSlot oldSlot)
          history = mkDepositFormulaHistory $ DepositFormulaV1 oldRate
          wire =
            Binary.encodeListLen 3
              <> Binary.encCBOR history
              <> Binary.encCBOR (Coin 0)
              <> Binary.encCBOR (Map.singleton (TxIn txId $ TxIx 0) entry)
      Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version wire)
        `shouldSatisfy` isLeft

  prop
    "retired per-entry formula metadata ⇒ decoding rejected instead of inventing allocation slots"
    $ forAll storeOutput
    $ \backed ->
      forM_ [mkBasicTxOutWithLegacyTxOut (backed ^. addrTxOutL) mempty, backed] $ \output ->
        forM_ [DepositFormulaV1 oldRate, DepositFormulaV2 oldRate] $ \pricing ->
          decodeAllocation
            ( Binary.encodeListLen 3
                <> Binary.encCBOR output
                <> Binary.encCBOR (1 :: Int64)
                <> Binary.encCBOR pricing
            )
            `shouldSatisfy` isLeft

  prop "retired map-only and two-field Dijkstra stores ⇒ decoding rejected" $ \txId -> do
    let coinMap = Map.singleton (TxIn txId $ TxIx 0) (Coin 1)
    Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version coinMap)
      `shouldSatisfy` isLeft
    Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version (Coin 1, coinMap))
      `shouldSatisfy` isLeft
    Binary.decodeFull @(UTxOStore DijkstraEra)
      version
      (Binary.serialize version (Coin 0, Map.empty :: Map.Map TxIn (Unspent (TxOut DijkstraEra))))
      `shouldSatisfy` isLeft

  prop "retired current-formula Store schema ⇒ decoding rejected" $ \txId ->
    forAll storeOutput $ \output -> do
      forM_ [Map.empty, Map.singleton (TxIn txId $ TxIx 0) (Unspent output (AtSlot oldSlot))] $ \entries -> do
        let wire =
              Binary.encodeListLen 3
                <> Binary.encCBOR (DepositFormulaV1 oldRate)
                <> Binary.encCBOR (Coin 0)
                <> Binary.encCBOR entries
        Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version wire)
          `shouldSatisfy` isLeft

  prop "retired null or map-only formula history ⇒ Store snapshot rejected" $ \baseline ->
    forM_
      [ Binary.encodeNull
      , Binary.encCBOR $ Map.singleton oldSlot (baseline :: DepositFormula)
      ]
      $ \retiredHistory -> do
        let wire =
              Binary.encodeListLen 3
                <> retiredHistory
                <> Binary.encCBOR (Coin 0)
                <> Binary.encCBOR (mempty :: IndexedUTxOs DijkstraEra)
        Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version wire)
          `shouldSatisfy` isLeft

  prop "retired seven-field Dijkstra snapshots ⇒ decoding rejected" $
    forAll (arbitrary @(LedgerState DijkstraEra)) $ \ledgerState -> do
      let state = lsAccountingState ledgerState
          retired =
            Binary.encodeListLen 2
              <> Binary.encCBOR (lsCertState ledgerState)
              <> Binary.encodeListLen 7
              <> Binary.encCBOR (IndexedUTxOs Map.empty :: IndexedUTxOs DijkstraEra)
              <> Binary.encCBOR (asDeposited state)
              <> Binary.encCBOR (asFees state)
              <> Binary.encCBOR (lsGovState ledgerState)
              <> Binary.encCBOR (asInstantStake state)
              <> Binary.encCBOR (asDonation state)
              <> Binary.encCBOR (Map.empty :: Map.Map TxIn Coin)
      Binary.decodeFullDecoder
        version
        "retired Dijkstra LedgerState"
        (Binary.decNoShareCBOR @(LedgerState DijkstraEra))
        (Binary.serialize version retired)
        `shouldSatisfy` isLeft

  prop "retired tagged-sum entries and snapshots ⇒ decoding rejected for both output variants" $ \txId address -> do
    let implicit = mkBasicTxOutWithLegacyTxOut address mempty :: TxOut DijkstraEra
        backed = mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets mempty) :: TxOut DijkstraEra
        retiredLegacy = Binary.encodeListLen 2 <> Binary.encodeWord 0 <> Binary.encCBOR implicit
        retiredNew =
          Binary.encodeListLen 4
            <> Binary.encodeWord 1
            <> Binary.encCBOR backed
            <> Binary.encCBOR (1 :: Int64)
            <> Binary.encCBOR (DepositFormulaV1 oldRate)
        history = mkDepositFormulaHistory $ DepositFormulaV1 oldRate
    forM_ [(Coin 0, retiredLegacy), (Coin 161000, retiredNew)] $ \(total, retired) -> do
      decodeAllocation retired `shouldSatisfy` isLeft
      let snapshot =
            Binary.encodeListLen 3
              <> Binary.encCBOR history
              <> Binary.encCBOR total
              <> Binary.encodeMapLen 1
              <> Binary.encCBOR (TxIn txId $ TxIx 0)
              <> retired
      Binary.decodeFull @(UTxOStore DijkstraEra) version (Binary.serialize version snapshot)
        `shouldSatisfy` isLeft

version :: Binary.Version
version = eraProtVerLow @DijkstraEra

oldSlot, newSlot, laterSlot :: SlotNo
oldSlot = SlotNo 100
newSlot = SlotNo 200
laterSlot = SlotNo 300

rate :: Word64 -> CoinPerByte
rate = CoinPerByte . CompactCoin

oldRate, newRate :: CoinPerByte
oldRate = rate 1000
newRate = rate 2000

cachedTotal :: UTxOStore era -> Coin
cachedTotal = toCoin . totalDepositAmount

decodeAllocation :: Binary.Encoding -> Either Binary.DecoderError (Unspent (TxOut DijkstraEra))
decodeAllocation = Binary.decodeFull @(Unspent (TxOut DijkstraEra)) version . Binary.serialize version

unspentEncoding :: TxOut DijkstraEra -> AllocatedAt -> Binary.Encoding
unspentEncoding output origin =
  Binary.encodeListLen 2 <> Binary.encCBOR output <> Binary.encCBOR origin

-- The size comes from an actual accepted, noncanonical transaction body, never
-- from synthesising metadata for an output that has already entered the store.
acceptedOutput :: TxOut DijkstraEra -> IO (Binary.Sized (TxOut DijkstraEra))
acceptedOutput output = do
  let body = (mkBasicTxBody :: TxBody TopTx DijkstraEra) & outputsTxBodyL .~ SSeq.singleton output
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
