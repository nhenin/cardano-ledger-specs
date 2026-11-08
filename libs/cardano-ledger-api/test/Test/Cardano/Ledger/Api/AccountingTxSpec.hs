{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Api.AccountingTxSpec (spec) where

import Cardano.Ledger.Alonzo (AlonzoEra)
import Cardano.Ledger.Babbage (BabbageEra)
import Cardano.Ledger.BaseTypes (SlotNo (..), StrictMaybe (..), TxIx (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Credential (Credential (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting as Accounting
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Cardano.Ledger.TxIn (TxIn (..))
import Cardano.Ledger.Val (inject)
import Data.Default (def)
import Data.Maybe (fromJust)
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common hiding (output)
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()

spec :: Spec
spec = describe "Accounting transaction projection" $ do
  let credential = KeyHashObj $ mkKeyHash @Staking 1
  accountingPolicySpec @AlonzoEra
    (def & ppKeyDepositL .~ Coin 29)
    (mkBasicTxBody & certsTxBodyL .~ SSeq.singleton (RegTxCert credential))
    Nothing
    mempty
  accountingPolicySpec @BabbageEra
    (def & ppKeyDepositL .~ Coin 29)
    ( mkBasicTxBody
        & certsTxBodyL
          .~ SSeq.singleton (RegTxCert credential)
        & collateralReturnTxBodyL
          .~ SJust (testOutput $ Coin 23)
    )
    (Just $ testOutput $ Coin 23)
    mempty
  accountingPolicySpec @ConwayEra
    (def & ppKeyDepositL .~ Coin 29)
    ( mkBasicTxBody
        & certsTxBodyL
          .~ SSeq.singleton (RegDepositTxCert credential $ Coin 29)
        & collateralReturnTxBodyL
          .~ SJust (testOutput $ Coin 23)
        & treasuryDonationTxBodyL
          .~ Coin 13
    )
    (Just $ testOutput $ Coin 23)
    (Coin 13)
  accountingPolicySpec @DijkstraEra
    (def & ppKeyDepositL .~ Coin 29)
    ( mkBasicTxBody
        & certsTxBodyL
          .~ SSeq.singleton (RegDepositTxCert credential $ Coin 29)
        & collateralReturnTxBodyL
          .~ SJust (testOutput $ Coin 23)
        & treasuryDonationTxBodyL
          .~ Coin 13
    )
    (Just $ testOutput $ Coin 23)
    (Coin 13)

  describe "Dijkstra"
    $ prop
      "invalid fees use incoming collateral and historical deposits before projection, including retained return collisions"
    $ \sourceId -> do
      let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
          outputWithCoins coins =
            mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets . inject $ Coin coins)
          collateralEntry = Unspent (outputWithCoins 1_000_000) (AtSlot $ SlotNo 10)
          untouchedEntry = Unspent (outputWithCoins 1_000) (AtSlot $ SlotNo 20)
          returned = outputWithCoins 50_000
          collidingEntry = Unspent (outputWithCoins 7_000) (AtSlot $ SlotNo 20)
          activeFormula = DepositFormulaV2 $ CoinPerByte $ CompactCoin 13
          history =
            fromJust $
              appendFormula (SlotNo 30) activeFormula
                =<< appendFormula
                  (SlotNo 20)
                  (DepositFormulaV1 $ CoinPerByte $ CompactCoin 5)
                  (mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3)
          collateralInput = TxIn sourceId (TxIx 0)
          untouchedInput = TxIn sourceId (TxIx 1)
          body =
            mkBasicTxBody @DijkstraEra @TopTx
              & inputsTxBodyL
                .~ Set.singleton untouchedInput
              & collateralInputsTxBodyL
                .~ Set.singleton collateralInput
              & outputsTxBodyL
                .~ SSeq.fromList [returned, returned]
              & collateralReturnTxBodyL
                .~ SJust returned
              & feeTxBodyL
                .~ Coin 11
              & treasuryDonationTxBodyL
                .~ Coin 13
              & certsTxBodyL
                .~ SSeq.singleton (RegDepositTxCert credential $ Coin 29)
          returnInput = TxIn (txIdTxBody body) (TxIx 2)
          expectedFee =
            Coin $
              1_000_000
                - 50_000
                + 250 * 3
                - 260 * 13
      forM_ [False, True] $ \hasCollision -> do
        let retained = (untouchedInput, untouchedEntry) : [(returnInput, collidingEntry) | hasCollision]
            incomingEntries = IndexedUTxOs.fromList $ (collateralInput, collateralEntry) : retained
            incomingStore = Store.mkUTxOStore history incomingEntries
            previousAccountingState =
              AccountingState
                incomingStore
                (Coin 19)
                (Coin 17)
                (addInstantStake (IndexedUTxOs.txOuts incomingEntries) mempty)
                (Coin 23)
            expectedEntries =
              IndexedUTxOs.fromList $
                retained <> [(returnInput, Unspent returned (AtSlot $ SlotNo 30)) | not hasCollision]
            expectedTotal =
              Coin $
                250 * 5
                  + if hasCollision then 250 * 5 else 260 * 13
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
                  previousAccountingState
                  (mkBasicTx body & isPhase2ValidTxL .~ Phase2Invalid)
        change `shouldBe` Coin 0
        consumed `shouldBe` IndexedUTxOs.singleton collateralInput collateralEntry
        created
          `shouldBe` IndexedUTxOs.fromList
            [(returnInput, Unspent returned (AtSlot $ SlotNo 30)) | not hasCollision]
        accountingState
          `shouldBe` previousAccountingState
            { asUTxOStore = Store.mkUTxOStore history expectedEntries
            , asFees = Coin 17 <> expectedFee
            , asInstantStake = addInstantStake (IndexedUTxOs.txOuts expectedEntries) mempty
            }
        toCoin (Store.totalDepositAmount $ asUTxOStore accountingState) `shouldBe` expectedTotal

-- Concrete era bodies above keep certificate and donation policy visible; this
-- shared assertion checks the returned output changes, state and deposit change.
accountingPolicySpec ::
  forall era.
  (AlonzoEraTx era, Accounting.EraAccounting era, EraCertState era, EraStake era) =>
  PParams era ->
  TxBody TopTx era ->
  Maybe (TxOut era) ->
  Coin ->
  Spec
accountingPolicySpec parameters template collateralReturn donation = describe (eraName @era)
  $ prop
    "accounting returns exact output changes and applies fee, deposit and donation policies for both validity flags"
  $ \sourceId -> do
    let previousAllocation = if isBeforeDijkstra @era then AtStoreMigration else AtSlot (SlotNo 10)
        newAllocation = if isBeforeDijkstra @era then AtStoreMigration else AtSlot (SlotNo 30)
        entry allocation coins = Unspent (testOutput coins) allocation
        regularInput = TxIn sourceId (TxIx 0)
        sharedInput = TxIn sourceId (TxIx 1)
        collateralInput = TxIn sourceId (TxIx 2)
        untouchedInput = TxIn sourceId (TxIx 3)
        regularEntry = entry previousAllocation $ Coin 71
        sharedEntry = entry previousAllocation $ Coin 73
        collateralEntry = entry previousAllocation $ Coin 79
        untouchedEntry = entry previousAllocation $ Coin 83
        body =
          template
            & inputsTxBodyL
              .~ Set.fromList [regularInput, sharedInput]
            & collateralInputsTxBodyL
              .~ Set.fromList [sharedInput, collateralInput]
            & outputsTxBodyL
              .~ SSeq.fromList [testOutput $ Coin 31, testOutput $ Coin 37]
            & feeTxBodyL
              .~ Coin 11
        bodyId = txIdTxBody body
        entries =
          IndexedUTxOs.fromList
            [ (regularInput, regularEntry)
            , (sharedInput, sharedEntry)
            , (collateralInput, collateralEntry)
            , (untouchedInput, untouchedEntry)
            ]
        history = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
        store = Store.mkUTxOStore history entries
        previousAccountingState =
          AccountingState
            store
            (Coin 19)
            (Coin 17)
            (addInstantStake (IndexedUTxOs.txOuts entries) mempty)
            (Coin 23)
    forM_ [Phase2Valid, Phase2Invalid] $ \validity -> do
      let (retained, expectedConsumed, expectedCreated, expectedFee, expectedDeposited, expectedDonation) = case validity of
            Phase2Valid ->
              ( [(collateralInput, collateralEntry), (untouchedInput, untouchedEntry)]
              , [(regularInput, regularEntry), (sharedInput, sharedEntry)]
              ,
                [ (TxIn bodyId (TxIx 0), entry newAllocation $ Coin 31)
                , (TxIn bodyId (TxIx 1), entry newAllocation $ Coin 37)
                ]
              , Coin 11
              , Coin 48
              , Coin 23 <> donation
              )
            Phase2Invalid ->
              ( [(regularInput, regularEntry), (untouchedInput, untouchedEntry)]
              , [(sharedInput, sharedEntry), (collateralInput, collateralEntry)]
              , [ (TxIn bodyId (TxIx 2), Unspent output newAllocation)
                | output <- maybe [] pure collateralReturn
                ]
              , Coin $ 73 + 79 - maybe 0 (const 23) collateralReturn
              , Coin 19
              , Coin 23
              )
          expectedEntries = IndexedUTxOs.fromList $ retained <> expectedCreated
          Accounting.TxProjected
            { Accounting.updatedAccountingState = accountingState
            , Accounting.consumedOutputs = consumed
            , Accounting.producedOutputs = created
            , Accounting.depositChange = change
            } =
              Accounting.projectTx
                (SlotNo 30)
                parameters
                def
                previousAccountingState
                (mkBasicTx body & isPhase2ValidTxL .~ validity)
      change
        `shouldBe` case validity of
          Phase2Valid -> Coin 29
          Phase2Invalid -> Coin 0
      consumed `shouldBe` IndexedUTxOs.fromList expectedConsumed
      created `shouldBe` IndexedUTxOs.fromList expectedCreated
      accountingState
        `shouldBe` AccountingState
          (Store.mkUTxOStore history expectedEntries)
          expectedDeposited
          (Coin 17 <> expectedFee)
          (addInstantStake (IndexedUTxOs.txOuts expectedEntries) mempty)
          expectedDonation
      toCoin (Store.totalDepositAmount $ asUTxOStore accountingState) `shouldBe` Coin 0

testOutput :: EraTxOut era => Coin -> TxOut era
testOutput =
  mkBasicTxOutWithImplicitDeposit
    (mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1))
    . inject
