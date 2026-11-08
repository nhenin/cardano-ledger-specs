{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Test.Cardano.Ledger.Api.IndexedUTxOsSpec (spec) where

import Cardano.Ledger.Allegra (AllegraEra)
import Cardano.Ledger.Alonzo (AlonzoEra)
import Cardano.Ledger.Api.Tx (producedTxOuts)
import Cardano.Ledger.Babbage (BabbageEra)
import Cardano.Ledger.Babbage.Collateral (collOuts)
import Cardano.Ledger.BaseTypes (SlotNo (..), StrictMaybe (..), TxIx (..))
import Cardano.Ledger.Binary (Sized (..), mkSized)
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Credential (Credential (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Genesis (NoGenesis (..))
import Cardano.Ledger.Mary (MaryEra)
import Cardano.Ledger.Shelley.API.Wallet (
  getFilteredIndexedUTxOs,
  getIndexedUTxOs,
  getIndexedUTxOsSubset,
 )
import Cardano.Ledger.Shelley.LedgerState (NewEpochState)
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting as Accounting
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store.Internals as StoreInternals
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Cardano.Ledger.TxOut.IndexedTxOs as IndexedTxOs
import Cardano.Ledger.Val (inject)
import Data.Default (def)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromJust)
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Void (Void)
import Lens.Micro
import qualified Test.Cardano.Ledger.Alonzo.Examples as Alonzo
import Test.Cardano.Ledger.Common hiding (output)
import qualified Test.Cardano.Ledger.Conway.Examples as Conway
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()
import Test.Cardano.Ledger.Shelley.Examples (LedgerExamples (leTranslationContext))

spec :: Spec
spec = describe "IndexedUTxOs metadata" $ do
  legacyAllocationSpec @BabbageEra
  legacyAllocationSpec @ConwayEra
  storeTranslationSpec @AllegraEra NoGenesis
  storeTranslationSpec @MaryEra NoGenesis
  storeTranslationSpec @AlonzoEra $ leTranslationContext Alonzo.ledgerExamples
  storeTranslationSpec @BabbageEra NoGenesis
  storeTranslationSpec @ConwayEra $ leTranslationContext Conway.ledgerExamples
  bodyProjectionCollisionSpec "TopTx" (mkBasicTxBody @BabbageEra @TopTx)
  bodyProjectionCollisionSpec "TopTx" (mkBasicTxBody @ConwayEra @TopTx)
  bodyProjectionCollisionSpec "TopTx" (mkBasicTxBody @DijkstraEra @TopTx)
  bodyProjectionCollisionSpec "SubTx" (mkBasicTxBody @DijkstraEra @SubTx)
  bodyUpdateDeltaSpec "TopTx" (mkBasicTxBody @DijkstraEra @TopTx)
  bodyUpdateDeltaSpec "SubTx" (mkBasicTxBody @DijkstraEra @SubTx)

  prop "wallet queries and selections preserve outputs and allocation slots" $ \txId -> do
    let address1 = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
        address2 = mkAddr (mkKeyHash @Payment 2) (KeyHashObj $ mkKeyHash @Staking 2)
        output1 = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address1 (ApplicationAssets . inject $ Coin 4)
        output2 = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address2 (ApplicationAssets . inject $ Coin 9)
        entry1 = Unspent output1 (AtSlot $ SlotNo 10)
        entry2 = Unspent output2 (AtSlot $ SlotNo 20)
        input1 = TxIn txId (TxIx 0)
        input2 = TxIn txId (TxIx 1)
        entries = IndexedUTxOs.fromList [(input1, entry1), (input2, entry2)]
        selected = IndexedUTxOs.singleton input1 entry1
        remaining = IndexedUTxOs.singleton input2 entry2
        inputs = Set.singleton input1
        history =
          fromJust $
            appendFormula (SlotNo 30) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 11)
              =<< appendFormula
                (SlotNo 20)
                (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7)
                (mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3)
        store = Store.mkUTxOStore history entries
        state = def @(NewEpochState DijkstraEra) & utxoStoreL .~ store
    getIndexedUTxOs state `shouldBe` entries
    getIndexedUTxOsSubset state inputs `shouldBe` selected
    getFilteredIndexedUTxOs state (Set.singleton address1) `shouldBe` selected
    IndexedUTxOs.restrictToInputs inputs entries `shouldBe` selected
    IndexedUTxOs.withoutInputs inputs entries `shouldBe` remaining
    IndexedUTxOs.extractInputs inputs entries `shouldBe` (remaining, selected)

  prop "body indexing preserves sizes; allocation records the supplied ledger slot" $ \(output :: TxOut DijkstraEra) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @DijkstraEra) output
          accepted = canonical {sizedSize = sizedSize canonical + extraBytes}
          body = mkBasicTxBody @DijkstraEra & sizedOutputsTxBodyL .~ SSeq.singleton accepted
          input = TxIn (txIdTxBody body) (TxIx 0)
      forM_ [DepositFormulaV1, DepositFormulaV2] $ \version -> do
        let pricing = version $ CoinPerByte $ CompactCoin 13
            expected =
              IndexedUTxOs.singleton
                input
                Unspent {Unspent.output = output, allocatedAt = AtSlot (SlotNo 30)}
        let proposed = outputsTxBody body
        proposed `shouldBe` IndexedTxOs.singleton input accepted
        producedTxOuts (mkBasicTx body) `shouldBe` proposed
        let Store.TxProjected
              { Store.updatedStore = store
              , Store.consumedOutputs = consumed
              , Store.producedOutputs = produced
              } =
                StoreInternals.projectValidTxBody
                  (SlotNo 30)
                  body
                  (Store.mkEmptyUTxOStore $ mkDepositFormulaHistory pricing)
        consumed `shouldBe` mempty
        produced `shouldBe` expected
        Store.allocations store `shouldBe` expected
        IndexedUTxOs.mapTxOuts id (Store.allocations store) `shouldBe` Map.singleton input output

  prop "phase-2 failure selects only the collateral return and preserves its metadata" $ \(output :: TxOut DijkstraEra) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @DijkstraEra) output
          accepted = canonical {sizedSize = sizedSize canonical + extraBytes}
          pricing = DepositFormulaV2 $ CoinPerByte $ CompactCoin 19
          body =
            mkBasicTxBody @DijkstraEra
              & sizedOutputsTxBodyL .~ SSeq.fromList [canonical, canonical]
              & sizedCollateralReturnTxBodyL .~ SJust accepted
          tx = mkBasicTx body & isPhase2ValidTxL .~ Phase2Invalid
          input = TxIn (txIdTxBody body) (TxIx 2)
      let proposed = producedTxOuts tx
      proposed `shouldBe` IndexedTxOs.singleton input accepted
      let Store.TxProjected
            { Store.updatedStore = store
            , Store.consumedOutputs = consumed
            , Store.producedOutputs = produced
            } =
              StoreInternals.projectInvalidTxBody
                (SlotNo 30)
                body
                (Store.mkEmptyUTxOStore $ mkDepositFormulaHistory pricing)
          expected =
            IndexedUTxOs.singleton
              input
              Unspent {Unspent.output = output, allocatedAt = AtSlot (SlotNo 30)}
      consumed `shouldBe` mempty
      produced `shouldBe` expected
      Store.allocations store `shouldBe` expected

  -- The return reference comes from the body hash and follows its regular outputs.
  -- An existing entry may occupy that reference, or it may be available.
  prop
    "collateral projection preserves retained collisions and allocates fresh body-derived returns at current prices"
    $ \sourceId -> do
      let stakingCredential = KeyHashObj $ mkKeyHash @Staking 1
          address = mkAddr (mkKeyHash @Payment 1) stakingCredential
          outputWithCoins coins =
            mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets . inject $ Coin coins)
          historicalFormula = DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
          activeFormula = DepositFormulaV2 $ CoinPerByte $ CompactCoin 13
          history =
            fromJust $
              appendFormula (SlotNo 30) activeFormula (mkDepositFormulaHistory historicalFormula)
          consumedInput = TxIn sourceId (TxIx 0)
          untouchedInput = TxIn sourceId (TxIx 2)
          consumedEntry = Unspent (outputWithCoins 40) (AtSlot $ SlotNo 10)
          collidingEntry = Unspent (outputWithCoins 10) (AtSlot $ SlotNo 10)
          untouchedEntry = Unspent (outputWithCoins 50) (AtSlot $ SlotNo 10)
          returnOutput = outputWithCoins 20
          createdEntry = Unspent returnOutput (AtSlot $ SlotNo 30)
          body =
            mkBasicTxBody @DijkstraEra @TopTx
              & collateralInputsTxBodyL .~ Set.singleton consumedInput
              & outputsTxBodyL .~ SSeq.fromList [returnOutput, returnOutput]
              & collateralReturnTxBodyL .~ SJust returnOutput
          returnInput = TxIn (txIdTxBody body) (TxIx 2)
          historicalDeposit = Coin (250 * 3)
          createdDeposit = Coin (260 * 13)
      forM_ [False, True] $ \hasCollision -> do
        let retainedEntries = (untouchedInput, untouchedEntry) : [(returnInput, collidingEntry) | hasCollision]
            previousEntries = IndexedUTxOs.fromList $ (consumedInput, consumedEntry) : retainedEntries
            previousStore = Store.mkUTxOStore history previousEntries
            previousStake = addInstantStake (IndexedUTxOs.txOuts previousEntries) mempty
            Store.TxProjected
              { Store.updatedStore = store
              , Store.consumedOutputs = consumed
              , Store.producedOutputs = produced
              } = StoreInternals.projectInvalidTxBody (SlotNo 30) body previousStore
            expectedProduced = IndexedUTxOs.fromList [(returnInput, createdEntry) | not hasCollision]
            expectedDeposit =
              historicalDeposit
                <> if hasCollision then historicalDeposit else createdDeposit
            stake = updateInstantStake consumed produced previousStake
            expectedStakeCoin = 50 + if hasCollision then 10 else 20
        consumed `shouldBe` IndexedUTxOs.singleton consumedInput consumedEntry
        produced `shouldBe` expectedProduced
        Store.allocations store
          `shouldBe` IndexedUTxOs.fromList retainedEntries
          <> expectedProduced
        toCoin (Store.totalDepositAmount store) `shouldBe` expectedDeposit
        Store.currentFormula store `shouldBe` activeFormula
        stake `shouldBe` addInstantStake (IndexedUTxOs.txOuts $ Store.allocations store) mempty
        Map.lookup stakingCredential (stake ^. instantStakeCredentialsL)
          `shouldBe` Just (CompactCoin expectedStakeCoin)

  prop
    "transaction projection dispatches phase-2 validity with overlapping regular and collateral inputs"
    $ \sourceId -> do
      let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
          outputWithCoins coins =
            mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets . inject $ Coin coins)
          historicalFormula = DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
          activeFormula = DepositFormulaV2 $ CoinPerByte $ CompactCoin 13
          history =
            fromJust $
              appendFormula (SlotNo 30) activeFormula (mkDepositFormulaHistory historicalFormula)
          regularInput = TxIn sourceId (TxIx 0)
          sharedInput = TxIn sourceId (TxIx 1)
          collateralInput = TxIn sourceId (TxIx 2)
          untouchedInput = TxIn sourceId (TxIx 3)
          regularEntry = Unspent (outputWithCoins 40) (AtSlot $ SlotNo 10)
          sharedEntry = Unspent (outputWithCoins 50) (AtSlot $ SlotNo 10)
          collateralEntry = Unspent (outputWithCoins 60) (AtSlot $ SlotNo 10)
          untouchedEntry = Unspent (outputWithCoins 70) (AtSlot $ SlotNo 10)
          ordinaryOutputs = [outputWithCoins 20, outputWithCoins 21]
          returnOutput = outputWithCoins 22
          body =
            mkBasicTxBody @DijkstraEra @TopTx
              & inputsTxBodyL .~ Set.fromList [regularInput, sharedInput]
              & collateralInputsTxBodyL .~ Set.fromList [sharedInput, collateralInput]
              & outputsTxBodyL .~ SSeq.fromList ordinaryOutputs
              & collateralReturnTxBodyL .~ SJust returnOutput
          txId = txIdTxBody body
          previousStore =
            Store.mkUTxOStore history . IndexedUTxOs.fromList $
              [ (regularInput, regularEntry)
              , (sharedInput, sharedEntry)
              , (collateralInput, collateralEntry)
              , (untouchedInput, untouchedEntry)
              ]
      forM_ [Phase2Valid, Phase2Invalid] $ \validity -> do
        let tx = mkBasicTx body & isPhase2ValidTxL .~ validity
            Store.TxProjected
              { Store.updatedStore = store
              , Store.consumedOutputs = consumed
              , Store.producedOutputs = produced
              } = Store.projectTx (SlotNo 30) tx previousStore
            (expectedRetained, expectedConsumed, expectedProduced, expectedDeposit) = case validity of
              Phase2Valid ->
                ( [(collateralInput, collateralEntry), (untouchedInput, untouchedEntry)]
                , [(regularInput, regularEntry), (sharedInput, sharedEntry)]
                , zipWith
                    (\index output -> (TxIn txId (TxIx index), Unspent output (AtSlot $ SlotNo 30)))
                    [0, 1]
                    ordinaryOutputs
                , Coin (2 * 250 * 3 + 2 * 260 * 13)
                )
              Phase2Invalid ->
                ( [(regularInput, regularEntry), (untouchedInput, untouchedEntry)]
                , [(sharedInput, sharedEntry), (collateralInput, collateralEntry)]
                , [(TxIn txId (TxIx 2), Unspent returnOutput (AtSlot $ SlotNo 30))]
                , Coin (2 * 250 * 3 + 260 * 13)
                )
            previousStake = addInstantStake (IndexedUTxOs.txOuts $ Store.allocations previousStore) mempty
            stake = updateInstantStake consumed produced previousStake
        consumed `shouldBe` IndexedUTxOs.fromList expectedConsumed
        produced `shouldBe` IndexedUTxOs.fromList expectedProduced
        Store.allocations store `shouldBe` IndexedUTxOs.fromList (expectedRetained <> expectedProduced)
        toCoin (Store.totalDepositAmount store) `shouldBe` expectedDeposit
        Store.currentFormula store `shouldBe` activeFormula
        stake `shouldBe` addInstantStake (IndexedUTxOs.txOuts $ Store.allocations store) mempty

bodyUpdateDeltaSpec :: String -> TxBody l DijkstraEra -> Spec
bodyUpdateDeltaSpec bodyName emptyBody = describe bodyName $
  prop "Store delta preserves consumed history and records newly allocated metadata" $ \sourceId (output :: TxOut DijkstraEra) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
          canonical = mkSized (eraProtVerLow @DijkstraEra) $ output & addrTxOutL .~ address
          suppliedSize = canonical {sizedSize = sizedSize canonical + extraBytes + 1}
          historicalFormula = DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
          activeFormula = DepositFormulaV2 $ CoinPerByte $ CompactCoin 13
          history =
            fromJust $
              appendFormula (SlotNo 30) activeFormula (mkDepositFormulaHistory historicalFormula)
          consumedInput = TxIn sourceId (TxIx 1)
          untouchedInput = TxIn sourceId (TxIx 2)
          consumedEntry = Unspent {Unspent.output = sizedValue canonical, allocatedAt = AtSlot (SlotNo 10)}
          untouchedEntry = Unspent {Unspent.output = sizedValue canonical, allocatedAt = AtSlot (SlotNo 10)}
          entries = IndexedUTxOs.fromList [(consumedInput, consumedEntry), (untouchedInput, untouchedEntry)]
          body =
            emptyBody
              & inputsTxBodyL .~ Set.singleton consumedInput
              & sizedOutputsTxBodyL .~ SSeq.singleton suppliedSize
          createdInput = TxIn (txIdTxBody body) (TxIx 0)
          createdEntry = Unspent {Unspent.output = sizedValue canonical, allocatedAt = AtSlot (SlotNo 30)}
          previousStore = Store.mkUTxOStore history entries
          previousStake = addInstantStake (IndexedUTxOs.txOuts entries) mempty
          Store.TxProjected
            { Store.updatedStore = store
            , Store.consumedOutputs = consumed
            , Store.producedOutputs = created
            } = StoreInternals.projectValidTxBody (SlotNo 30) body previousStore
          stake = updateInstantStake consumed created previousStake
      consumed `shouldBe` IndexedUTxOs.singleton consumedInput consumedEntry
      created `shouldBe` IndexedUTxOs.singleton createdInput createdEntry
      Store.allocations store
        `shouldBe` IndexedUTxOs.fromList [(untouchedInput, untouchedEntry), (createdInput, createdEntry)]
      stake `shouldBe` addInstantStake (IndexedUTxOs.txOuts $ Store.allocations store) mempty

-- Earlier-era snapshots contain output payloads only. Creation must retain their
-- canonical compatibility convention, even when the body supplies a longer size.
legacyAllocationSpec ::
  forall era.
  ( BabbageEraTxBody era
  , Accounting.EraAccounting era
  , EraCertState era
  , EraStake era
  , Arbitrary (TxOut era)
  ) =>
  Spec
legacyAllocationSpec = describe (eraName @era) $ do
  prop "legacy snapshots preserve outputs with either default or supplied pricing" $ \(output :: TxOut era) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @era) output
          supplied = canonical {sizedSize = sizedSize canonical + extraBytes}
          history = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
          body =
            mkBasicTxBody @era
              & sizedOutputsTxBodyL .~ SSeq.singleton supplied
              & sizedCollateralReturnTxBodyL .~ SJust supplied
      forM_ [outputsTxBody body, collOuts body] $ \proposed -> do
        let store = StoreInternals.allocate (SlotNo 30) proposed (Store.mkEmptyUTxOStore history)
        IndexedUTxOs.inputIds (Store.allocations store) `shouldBe` IndexedTxOs.inputIds proposed
        forM_ (IndexedUTxOs.unspentOutputs $ Store.allocations store) $ \entry -> do
          Unspent.output entry `shouldBe` output
          allocatedAt entry `shouldBe` AtStoreMigration
        restored <-
          expectRight $
            Binary.decodeFullDecoder
              (eraProtVerLow @era)
              "UTxOStore with supplied baseline"
              (Store.decodeUTxOStoreWithFormula @era (initialFormula history) mempty)
              (Binary.serialize (eraProtVerLow @era) store)
        restored `shouldBe` store
        restoredWithDefault <-
          expectRight . Binary.decodeFull @(UTxOStore era) (eraProtVerLow @era) $
            Binary.serialize (eraProtVerLow @era) store
        Store.currentFormula restoredWithDefault
          `shouldBe` (DepositFormulaV1 $ CoinPerByte $ CompactCoin 4310)
        Store.allocations restoredWithDefault `shouldBe` Store.allocations store
        Store.totalDepositAmount restoredWithDefault `shouldBe` DepositAmount {toCoin = Coin 0}

  prop "accounting projection reports the legacy output and migration origin regardless of wire size" $ \(output :: TxOut era) ->
    forAll (choose (1, 1000)) $ \extraBytes -> do
      let canonical = mkSized (eraProtVerLow @era) output
          supplied = canonical {sizedSize = sizedSize canonical + extraBytes}
          body = mkBasicTxBody @era @TopTx & sizedOutputsTxBodyL .~ SSeq.singleton supplied
          createdInput = TxIn (txIdTxBody body) (TxIx 0)
          expected =
            IndexedUTxOs.singleton createdInput $
              Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
          Accounting.TxProjected
            { Accounting.updatedAccountingState = accountingState
            , Accounting.consumedOutputs = consumed
            , Accounting.producedOutputs = created
            , Accounting.depositChange = change
            } =
              Accounting.projectTx
                (SlotNo 30)
                def
                def
                (def @(AccountingState era))
                (mkBasicTx body)
      change `shouldBe` Coin 0
      consumed `shouldBe` mempty
      created `shouldBe` expected
      (Store.allocations . asUTxOStore $ accountingState) `shouldBe` expected
      asInstantStake accountingState `shouldBe` addInstantStake (IndexedUTxOs.txOuts expected) mempty

-- Preserve the upstream map union's retained-entry priority in every era, even
-- for a deliberately colliding output reference at this Store-operation boundary.
bodyProjectionCollisionSpec ::
  forall era l.
  (BabbageEraTxBody era, EraStake era, Arbitrary (TxOut era)) =>
  String ->
  TxBody l era ->
  Spec
bodyProjectionCollisionSpec bodyName emptyBody = describe (eraName @era) $
  describe bodyName $
    prop "body update reports only accepted creations and keeps stake consistent on collisions" $ \sourceId (output :: TxOut era) ->
      forM_ [(False, True), (True, True), (True, False)] $ \(hasCollision, hasFreshOutput) -> do
        let stakingCredential = KeyHashObj $ mkKeyHash @Staking 1
            address = mkAddr (mkKeyHash @Payment 1) stakingCredential
            previousAllocation = if isBeforeDijkstra @era then AtStoreMigration else AtSlot (SlotNo 10)
            newAllocation = if isBeforeDijkstra @era then AtStoreMigration else AtSlot (SlotNo 30)
            entry allocation coins =
              Unspent
                { Unspent.output = output & addrTxOutL .~ address & coinTxOutL .~ Coin coins
                , allocatedAt = allocation
                }
            consumedInput = TxIn sourceId (TxIx 2)
            untouchedInput = TxIn sourceId (TxIx 3)
            consumedEntry = entry previousAllocation 40
            collidingEntry = entry previousAllocation 10
            untouchedEntry = entry previousAllocation 50
            proposedEntry = entry newAllocation 20
            freshEntry = entry newAllocation 30
            body =
              emptyBody
                & inputsTxBodyL .~ Set.singleton consumedInput
                & outputsTxBodyL
                  .~ SSeq.fromList
                    (Unspent.output proposedEntry : [Unspent.output freshEntry | hasFreshOutput])
            collidingInput = TxIn (txIdTxBody body) (TxIx 0)
            freshInput = TxIn (txIdTxBody body) (TxIx 1)
            retainedEntries = (untouchedInput, untouchedEntry) : [(collidingInput, collidingEntry) | hasCollision]
            previousEntries = IndexedUTxOs.fromList $ (consumedInput, consumedEntry) : retainedEntries
            -- Zero pricing keeps this Dijkstra collision check independent of deposit amounts.
            history = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 0
            previousStore = Store.mkUTxOStore history previousEntries
            previousStake = addInstantStake (IndexedUTxOs.txOuts previousEntries) mempty
            expectedCreated =
              IndexedUTxOs.fromList $
                [(collidingInput, proposedEntry) | not hasCollision] <> [(freshInput, freshEntry) | hasFreshOutput]
            Store.TxProjected
              { Store.updatedStore = store
              , Store.consumedOutputs = consumed
              , Store.producedOutputs = created
              } = StoreInternals.projectValidTxBody (SlotNo 30) body previousStore
            stake = updateInstantStake consumed created previousStake
            expectedStakeCoin = 50 + (if hasCollision then 10 else 20) + (if hasFreshOutput then 30 else 0)
        consumed `shouldBe` IndexedUTxOs.singleton consumedInput consumedEntry
        created `shouldBe` expectedCreated
        Store.allocations store `shouldBe` IndexedUTxOs.fromList retainedEntries <> expectedCreated
        toCoin (Store.totalDepositAmount store) `shouldBe` Coin 0
        stake `shouldBe` addInstantStake (IndexedUTxOs.txOuts $ Store.allocations store) mempty
        Map.lookup stakingCredential (stake ^. instantStakeCredentialsL)
          `shouldBe` Just (CompactCoin expectedStakeCoin)

-- Era translation changes output representation; the supplied pricing history survives.
storeTranslationSpec ::
  forall era.
  ( EraTxOut (PreviousEra era)
  , TranslateEra era UTxOStore
  , TranslationError era UTxOStore ~ Void
  , Arbitrary (IndexedUTxOs (PreviousEra era))
  ) =>
  TranslationContext era ->
  Spec
storeTranslationSpec translationContext = describe (eraName @era) $
  prop "Store translation preserves the initial formula and every dated change" $
    forAll (resize 5 arbitrary) $ \(entries :: IndexedUTxOs (PreviousEra era)) -> do
      let history =
            DepositFormulaHistory
              { initialFormula = DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
              , formulaChanges = Map.singleton (SlotNo 20) $ DepositFormulaV2 $ CoinPerByte $ CompactCoin 7
              }
          previousStore = Store.mkUTxOStore history entries
          store = translateEra' @era translationContext previousStore
      Store.depositFormulaHistory store `shouldBe` history
      IndexedUTxOs.inputIds (Store.allocations store) `shouldBe` IndexedUTxOs.inputIds entries
      Store.totalDepositAmount store `shouldBe` DepositAmount {toCoin = Coin 0}
