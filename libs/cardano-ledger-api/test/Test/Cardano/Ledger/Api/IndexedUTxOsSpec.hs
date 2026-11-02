{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Api.IndexedUTxOsSpec (spec) where

import Cardano.Ledger.Api.Tx (producedTxOuts)
import Cardano.Ledger.Babbage (BabbageEra)
import Cardano.Ledger.Babbage.Collateral (collOuts)
import Cardano.Ledger.BaseTypes (StrictMaybe (..), TxIx (..))
import Cardano.Ledger.Binary (Sized (..), mkSized)
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Credential (Credential (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.API.Wallet (
  getFilteredIndexedUTxOs,
  getIndexedUTxOs,
  getIndexedUTxOsSubset,
 )
import Cardano.Ledger.Shelley.LedgerState (NewEpochState)
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store.Internals as StoreInternals
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Cardano.Ledger.TxOut.IndexedTxOs as IndexedTxOs
import Cardano.Ledger.Val (inject)
import Data.Default (def)
import Data.IORef (modifyIORef', newIORef, readIORef)
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common hiding (output)
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()

spec :: Spec
spec = describe "IndexedUTxOs metadata" $ do
  legacyAllocationSpec @BabbageEra
  legacyAllocationSpec @ConwayEra
  bodyProjectionCollisionSpec "TopTx" (mkBasicTxBody @BabbageEra @TopTx)
  bodyProjectionCollisionSpec "TopTx" (mkBasicTxBody @ConwayEra @TopTx)
  bodyProjectionCollisionSpec "TopTx" (mkBasicTxBody @DijkstraEra @TopTx)
  bodyProjectionCollisionSpec "SubTx" (mkBasicTxBody @DijkstraEra @SubTx)
  bodyUpdateEventSpec "TopTx" (mkBasicTxBody @DijkstraEra @TopTx)
  bodyUpdateEventSpec "SubTx" (mkBasicTxBody @DijkstraEra @SubTx)

  prop "wallet queries and selections preserve accepted sizes and mixed historical calculations" $ \txId ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let address1 = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
          address2 = mkAddr (mkKeyHash @Payment 2) (KeyHashObj $ mkKeyHash @Staking 2)
          output1 = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address1 (ApplicationAssets . inject $ Coin 4)
          output2 = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address2 (ApplicationAssets . inject $ Coin 9)
          sized1 = mkSized (eraProtVerLow @DijkstraEra) output1
          sized2 = mkSized (eraProtVerLow @DijkstraEra) output2
          entry1 =
            Unspent
              { sizedOutput = sized1 {sizedSize = sizedSize sized1 + extraBytes}
              , depositCalculation = DepositCalculationV1 $ CoinPerByte $ CompactCoin 3
              }
          entry2 =
            Unspent
              { sizedOutput = sized2 {sizedSize = sizedSize sized2 + extraBytes + 1}
              , depositCalculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 7
              }
          input1 = TxIn txId (TxIx 0)
          input2 = TxIn txId (TxIx 1)
          entries = IndexedUTxOs.fromList [(input1, entry1), (input2, entry2)]
          selected = IndexedUTxOs.singleton input1 entry1
          remaining = IndexedUTxOs.singleton input2 entry2
          inputs = Set.singleton input1
          store = Store.mkUTxOStore (DepositCalculationV2 $ CoinPerByte $ CompactCoin 11) entries
          state = def @(NewEpochState DijkstraEra) & utxoStoreL .~ store
      getIndexedUTxOs state `shouldBe` entries
      getIndexedUTxOsSubset state inputs `shouldBe` selected
      getFilteredIndexedUTxOs state (Set.singleton address1) `shouldBe` selected
      IndexedUTxOs.restrictToInputs inputs entries `shouldBe` selected
      IndexedUTxOs.withoutInputs inputs entries `shouldBe` remaining
      IndexedUTxOs.extractInputs inputs entries `shouldBe` (remaining, selected)

  prop "body indexing preserves sizes; allocation records the Store's current calculation" $ \(output :: TxOut DijkstraEra) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @DijkstraEra) output
          accepted = canonical {sizedSize = sizedSize canonical + extraBytes}
          body = mkBasicTxBody @DijkstraEra & sizedOutputsTxBodyL .~ SSeq.singleton accepted
          input = TxIn (txIdTxBody body) (TxIx 0)
      forM_ [DepositCalculationV1, DepositCalculationV2] $ \version -> do
        let calculation = version $ CoinPerByte $ CompactCoin 13
            expected = IndexedUTxOs.singleton input Unspent {sizedOutput = accepted, depositCalculation = calculation}
        let proposed = outputsTxBody body
        proposed `shouldBe` IndexedTxOs.singleton input accepted
        producedTxOuts (mkBasicTx body) `shouldBe` proposed
        let store = StoreInternals.projectValidTxBody body (Store.mkEmptyUTxOStore calculation)
        Store.allocations store `shouldBe` expected
        IndexedUTxOs.toIndexedTxOs (Store.allocations store) `shouldBe` proposed

  prop "phase-2 failure selects only the collateral return and preserves its metadata" $ \(output :: TxOut DijkstraEra) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @DijkstraEra) output
          accepted = canonical {sizedSize = sizedSize canonical + extraBytes}
          calculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 19
          body =
            mkBasicTxBody @DijkstraEra
              & sizedOutputsTxBodyL .~ SSeq.fromList [canonical, canonical]
              & sizedCollateralReturnTxBodyL .~ SJust accepted
          tx = mkBasicTx body & isPhase2ValidTxL .~ Phase2Invalid
          input = TxIn (txIdTxBody body) (TxIx 2)
      let proposed = producedTxOuts tx
      proposed `shouldBe` IndexedTxOs.singleton input accepted
      let store = StoreInternals.projectInvalidTxBody body (Store.mkEmptyUTxOStore calculation)
      Store.allocations store
        `shouldBe` IndexedUTxOs.singleton input Unspent {sizedOutput = accepted, depositCalculation = calculation}

  -- The return reference comes from the body hash and follows its regular outputs.
  -- An existing entry may occupy that reference, or it may be available.
  prop
    "collateral projection preserves retained collisions and allocates fresh body-derived returns at current prices"
    $ \sourceId ->
      forAll (choose (1, 1000)) $ \extraBytes -> do
        let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
            accepted coins extra =
              let output = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets . inject $ Coin coins)
                  canonical = mkSized (eraProtVerLow @DijkstraEra) output
               in canonical {sizedSize = sizedSize canonical + extra}
            historicalCalculation = DepositCalculationV1 $ CoinPerByte $ CompactCoin 3
            activeCalculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 13
            consumedInput = TxIn sourceId (TxIx 0)
            untouchedInput = TxIn sourceId (TxIx 2)
            consumedEntry = Unspent (accepted 40 extraBytes) historicalCalculation
            collidingEntry = Unspent (accepted 10 (extraBytes + 1)) historicalCalculation
            untouchedEntry = Unspent (accepted 50 (extraBytes + 2)) historicalCalculation
            returnOutput = accepted 20 (extraBytes + 3)
            createdEntry = Unspent returnOutput activeCalculation
            body =
              mkBasicTxBody @DijkstraEra @TopTx
                & collateralInputsTxBodyL .~ Set.singleton consumedInput
                & sizedOutputsTxBodyL .~ SSeq.fromList [returnOutput, returnOutput]
                & sizedCollateralReturnTxBodyL .~ SJust returnOutput
            returnInput = TxIn (txIdTxBody body) (TxIx 2)
            historicalDeposit entry = Coin $ (160 + toInteger (sizedSize $ sizedOutput entry)) * 3
            createdDeposit = Coin $ (160 + toInteger (sizedSize returnOutput)) * 13
        forM_ [False, True] $ \hasCollision -> do
          let retainedEntries = (untouchedInput, untouchedEntry) : [(returnInput, collidingEntry) | hasCollision]
              previousStore =
                Store.mkUTxOStore activeCalculation . IndexedUTxOs.fromList $
                  (consumedInput, consumedEntry) : retainedEntries
              store = StoreInternals.projectInvalidTxBody body previousStore
              expectedDeposit =
                historicalDeposit untouchedEntry
                  <> if hasCollision then historicalDeposit collidingEntry else createdDeposit
          Store.allocations store
            `shouldBe` IndexedUTxOs.fromList (retainedEntries <> [(returnInput, createdEntry) | not hasCollision])
          toCoin (Store.totalDepositAmount store) `shouldBe` expectedDeposit
          Store.currentCalculation store `shouldBe` activeCalculation

  prop
    "transaction projection dispatches phase-2 validity with overlapping regular and collateral inputs"
    $ \sourceId ->
      forAll (choose (1, 1000)) $ \extraBytes -> do
        let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
            accepted coins extra =
              let output = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets . inject $ Coin coins)
                  canonical = mkSized (eraProtVerLow @DijkstraEra) output
               in canonical {sizedSize = sizedSize canonical + extra}
            historicalCalculation = DepositCalculationV1 $ CoinPerByte $ CompactCoin 3
            activeCalculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 13
            regularInput = TxIn sourceId (TxIx 0)
            sharedInput = TxIn sourceId (TxIx 1)
            collateralInput = TxIn sourceId (TxIx 2)
            untouchedInput = TxIn sourceId (TxIx 3)
            regularEntry = Unspent (accepted 40 extraBytes) historicalCalculation
            sharedEntry = Unspent (accepted 50 (extraBytes + 1)) historicalCalculation
            collateralEntry = Unspent (accepted 60 (extraBytes + 2)) historicalCalculation
            untouchedEntry = Unspent (accepted 70 (extraBytes + 3)) historicalCalculation
            ordinaryOutputs = [accepted 20 (extraBytes + 4), accepted 21 (extraBytes + 5)]
            returnOutput = accepted 22 (extraBytes + 6)
            body =
              mkBasicTxBody @DijkstraEra @TopTx
                & inputsTxBodyL .~ Set.fromList [regularInput, sharedInput]
                & collateralInputsTxBodyL .~ Set.fromList [sharedInput, collateralInput]
                & sizedOutputsTxBodyL .~ SSeq.fromList ordinaryOutputs
                & sizedCollateralReturnTxBodyL .~ SJust returnOutput
            txId = txIdTxBody body
            previousStore =
              Store.mkUTxOStore activeCalculation . IndexedUTxOs.fromList $
                [ (regularInput, regularEntry)
                , (sharedInput, sharedEntry)
                , (collateralInput, collateralEntry)
                , (untouchedInput, untouchedEntry)
                ]
            price rate outputWithSize = Coin $ (160 + toInteger (sizedSize outputWithSize)) * rate
        forM_ [Phase2Valid, Phase2Invalid] $ \validity -> do
          let tx = mkBasicTx body & isPhase2ValidTxL .~ validity
              store = Store.projectTx tx previousStore
              (expectedEntries, expectedDeposit) = case validity of
                Phase2Valid ->
                  ( [(collateralInput, collateralEntry), (untouchedInput, untouchedEntry)]
                      <> zipWith
                        (\index output -> (TxIn txId (TxIx index), Unspent output activeCalculation))
                        [0, 1]
                        ordinaryOutputs
                  , price 3 (sizedOutput collateralEntry)
                      <> price 3 (sizedOutput untouchedEntry)
                      <> foldMap (price 13) ordinaryOutputs
                  )
                Phase2Invalid ->
                  (
                    [ (regularInput, regularEntry)
                    , (untouchedInput, untouchedEntry)
                    , (TxIn txId (TxIx 2), Unspent returnOutput activeCalculation)
                    ]
                  , price 3 (sizedOutput regularEntry)
                      <> price 3 (sizedOutput untouchedEntry)
                      <> price 13 returnOutput
                  )
          Store.allocations store `shouldBe` IndexedUTxOs.fromList expectedEntries
          toCoin (Store.totalDepositAmount store) `shouldBe` expectedDeposit
          Store.currentCalculation store `shouldBe` activeCalculation

bodyUpdateEventSpec :: String -> TxBody l DijkstraEra -> Spec
bodyUpdateEventSpec bodyName emptyBody = describe bodyName $
  prop "TxUTxODiff reports consumed historical entries and newly allocated entries" $ \sourceId (output :: TxOut DijkstraEra) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @DijkstraEra) output
          historicalSize = canonical {sizedSize = sizedSize canonical + extraBytes}
          suppliedSize = canonical {sizedSize = sizedSize canonical + extraBytes + 1}
          historicalCalculation = DepositCalculationV1 $ CoinPerByte $ CompactCoin 3
          activeCalculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 13
          consumedInput = TxIn sourceId (TxIx 1)
          untouchedInput = TxIn sourceId (TxIx 2)
          consumedEntry = Unspent {sizedOutput = historicalSize, depositCalculation = historicalCalculation}
          untouchedEntry = Unspent {sizedOutput = canonical, depositCalculation = historicalCalculation}
          entries = IndexedUTxOs.fromList [(consumedInput, consumedEntry), (untouchedInput, untouchedEntry)]
          body =
            emptyBody
              & inputsTxBodyL .~ Set.singleton consumedInput
              & sizedOutputsTxBodyL .~ SSeq.singleton suppliedSize
          createdInput = TxIn (txIdTxBody body) (TxIx 0)
          createdEntry = Unspent {sizedOutput = suppliedSize, depositCalculation = activeCalculation}
          previousState =
            (def @(AccountingState DijkstraEra))
              { asUTxOStore = Store.mkUTxOStore activeCalculation entries
              , asInstantStake = addInstantStake (IndexedUTxOs.txOuts entries) mempty
              }
      events <- newIORef []
      updatedState <-
        Shelley.updateUTxOsAndInstantStakeWithTxBody
          body
          (\consumed created -> modifyIORef' events (<> [(consumed, created)]))
          previousState
      readIORef events
        `shouldReturn` [
                         ( IndexedUTxOs.singleton consumedInput consumedEntry
                         , IndexedUTxOs.singleton createdInput createdEntry
                         )
                       ]
      (Store.allocations . asUTxOStore $ updatedState)
        `shouldBe` IndexedUTxOs.fromList [(untouchedInput, untouchedEntry), (createdInput, createdEntry)]

-- Earlier-era snapshots contain output payloads only. Creation must retain their
-- canonical compatibility convention, even when the body supplies a longer size.
legacyAllocationSpec ::
  forall era.
  (BabbageEraTxBody era, EraGov era, EraStake era, Arbitrary (TxOut era)) =>
  Spec
legacyAllocationSpec = describe (eraName @era) $ do
  prop "allocated ordinary and collateral outputs retain the legacy snapshot roundtrip" $ \(output :: TxOut era) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @era) output
          supplied = canonical {sizedSize = sizedSize canonical + extraBytes}
          calculation = legacyDepositCalculation
          body =
            mkBasicTxBody @era
              & sizedOutputsTxBodyL .~ SSeq.singleton supplied
              & sizedCollateralReturnTxBodyL .~ SJust supplied
      forM_ [outputsTxBody body, collOuts body] $ \proposed -> do
        let store = StoreInternals.allocate proposed (Store.mkEmptyUTxOStore calculation)
        IndexedUTxOs.inputIds (Store.allocations store) `shouldBe` IndexedTxOs.inputIds proposed
        forM_ (IndexedUTxOs.unspentOutputs $ Store.allocations store) $ \entry -> do
          sizedOutput entry `shouldBe` canonical
          depositCalculation entry `shouldBe` legacyDepositCalculation
        restored <-
          expectRight . Binary.decodeFull @(UTxOStore era) (eraProtVerLow @era) $
            Binary.serialize (eraProtVerLow @era) store
        restored `shouldBe` store

  prop "TxUTxODiff reports the stored creation size rather than the body's supplied size" $ \(output :: TxOut era) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @era) output
          supplied = canonical {sizedSize = sizedSize canonical + extraBytes}
          body = mkBasicTxBody @era @TopTx & sizedOutputsTxBodyL .~ SSeq.singleton supplied
          createdInput = TxIn (txIdTxBody body) (TxIx 0)
          expected =
            IndexedUTxOs.singleton createdInput $
              Unspent {sizedOutput = canonical, depositCalculation = legacyDepositCalculation}
      events <- newIORef []
      updatedState <-
        Shelley.updateUTxOsAndInstantStakeWithTxBody
          body
          (\consumed created -> modifyIORef' events (<> [(consumed, created)]))
          (def @(AccountingState era))
      readIORef events `shouldReturn` [(mempty, expected)]
      (Store.allocations . asUTxOStore $ updatedState) `shouldBe` expected

-- Preserve the upstream map union's retained-entry priority in every era, even
-- for a deliberately colliding output reference at this Store-operation boundary.
bodyProjectionCollisionSpec ::
  forall era l.
  (BabbageEraTxBody era, Arbitrary (TxOut era)) =>
  String ->
  TxBody l era ->
  Spec
bodyProjectionCollisionSpec bodyName emptyBody = describe (eraName @era) $
  describe bodyName $
    prop "body update consumes inputs and preserves existing entries at colliding output references" $ \sourceId (output :: TxOut era) -> do
      let version = eraProtVerLow @era
          entry coins =
            Unspent
              { sizedOutput = mkSized version $ output & coinTxOutL .~ Coin coins
              , depositCalculation = legacyDepositCalculation
              }
          consumedInput = TxIn sourceId (TxIx 2)
          untouchedInput = TxIn sourceId (TxIx 3)
          consumedEntry = entry 40
          collidingEntry = entry 10
          untouchedEntry = entry 50
          createdEntry = entry 30
          body =
            emptyBody
              & inputsTxBodyL .~ Set.singleton consumedInput
              & sizedOutputsTxBodyL .~ SSeq.fromList [sizedOutput $ entry 20, sizedOutput createdEntry]
          collidingInput = TxIn (txIdTxBody body) (TxIx 0)
          createdInput = TxIn (txIdTxBody body) (TxIx 1)
          previousStore =
            Store.mkUTxOStore legacyDepositCalculation . IndexedUTxOs.fromList $
              [ (consumedInput, consumedEntry)
              , (collidingInput, collidingEntry)
              , (untouchedInput, untouchedEntry)
              ]
          store = StoreInternals.projectValidTxBody body previousStore
      Store.allocations store
        `shouldBe` IndexedUTxOs.fromList
          [ (collidingInput, collidingEntry)
          , (createdInput, createdEntry)
          , (untouchedInput, untouchedEntry)
          ]
      toCoin (Store.totalDepositAmount store) `shouldBe` Coin 0
