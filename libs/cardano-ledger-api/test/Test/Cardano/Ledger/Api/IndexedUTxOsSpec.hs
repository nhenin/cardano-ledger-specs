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
import Cardano.Ledger.Shelley.LedgerState (NewEpochState, UTxOState (..))
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.UTxOs.Store as Store
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
        let store = Store.update body (Store.emptyUTxOStore calculation)
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
      let store = Store.allocate proposed (Store.emptyUTxOStore calculation)
      Store.allocations store
        `shouldBe` IndexedUTxOs.singleton input Unspent {sizedOutput = accepted, depositCalculation = calculation}

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
            (def @(UTxOState DijkstraEra))
              { utxosUTxOStore = Store.mkUTxOStore activeCalculation entries
              , utxosInstantStake = addInstantStake (IndexedUTxOs.txOuts entries) mempty
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
      (Store.allocations . utxosUTxOStore $ updatedState)
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
        let store = Store.allocate proposed (Store.emptyUTxOStore calculation)
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
          (def @(UTxOState era))
      readIORef events `shouldReturn` [(mempty, expected)]
      (Store.allocations . utxosUTxOStore $ updatedState) `shouldBe` expected

  -- Preserve the old UTxO map union's existing-entry priority, even for a
  -- deliberately colliding output reference at this Store-operation boundary.
  prop "body update consumes inputs and preserves existing entries at colliding output references" $ \sourceId (output :: TxOut era) -> do
    let version = eraProtVerLow @era
        legacyEntry coins =
          Unspent
            { sizedOutput = mkSized version $ output & coinTxOutL .~ Coin coins
            , depositCalculation = legacyDepositCalculation
            }
        consumedInput = TxIn sourceId (TxIx 2)
        untouchedInput = TxIn sourceId (TxIx 3)
        consumedEntry = legacyEntry 40
        collidingEntry = legacyEntry 10
        untouchedEntry = legacyEntry 50
        createdEntry = legacyEntry 30
        body =
          mkBasicTxBody @era @TopTx
            & inputsTxBodyL .~ Set.singleton consumedInput
            & sizedOutputsTxBodyL .~ SSeq.fromList [sizedOutput $ legacyEntry 20, sizedOutput createdEntry]
        collidingInput = TxIn (txIdTxBody body) (TxIx 0)
        createdInput = TxIn (txIdTxBody body) (TxIx 1)
        previousStore =
          Store.mkUTxOStore legacyDepositCalculation . IndexedUTxOs.fromList $
            [ (consumedInput, consumedEntry)
            , (collidingInput, collidingEntry)
            , (untouchedInput, untouchedEntry)
            ]
        store = Store.update body previousStore
    Store.allocations store
      `shouldBe` IndexedUTxOs.fromList
        [ (collidingInput, collidingEntry)
        , (createdInput, createdEntry)
        , (untouchedInput, untouchedEntry)
        ]
    toCoin (Store.totalDepositAmount store) `shouldBe` Coin 0
