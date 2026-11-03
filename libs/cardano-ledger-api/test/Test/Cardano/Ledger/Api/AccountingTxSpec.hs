{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Api.AccountingTxSpec (spec) where

import Cardano.Ledger.Alonzo (AlonzoEra)
import Cardano.Ledger.Babbage (BabbageEra)
import Cardano.Ledger.BaseTypes (StrictMaybe (..), TxIx (..))
import Cardano.Ledger.Binary (Sized (..), mkSized)
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
import Data.IORef (modifyIORef', newIORef, readIORef)
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
      "invalid fees use the original snapshot while Store and stake use live entries, including retained return collisions"
    $ \sourceId ->
      forAll (choose (1, 1000)) $ \extraBytes -> do
        let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
            accepted coins extra =
              let canonical =
                    mkSized (eraProtVerLow @DijkstraEra) $
                      mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets . inject $ Coin coins)
               in canonical {sizedSize = sizedSize canonical + extra}
            originalEntry = Unspent (accepted 1_000_000 extraBytes) (DepositCalculationV1 $ CoinPerByte $ CompactCoin 3)
            liveEntry =
              Unspent (accepted 2_000_000 (extraBytes + 1)) (DepositCalculationV1 $ CoinPerByte $ CompactCoin 5)
            untouchedEntry = Unspent (accepted 1_000 (extraBytes + 2)) (DepositCalculationV1 $ CoinPerByte $ CompactCoin 5)
            returned = accepted 50_000 (extraBytes + 3)
            collidingEntry = Unspent (accepted 7_000 (extraBytes + 4)) (DepositCalculationV1 $ CoinPerByte $ CompactCoin 5)
            originalCalculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 7
            liveCalculation = DepositCalculationV2 $ CoinPerByte $ CompactCoin 13
            collateralInput = TxIn sourceId (TxIx 0)
            untouchedInput = TxIn sourceId (TxIx 1)
            body =
              mkBasicTxBody @DijkstraEra @TopTx
                & inputsTxBodyL
                  .~ Set.singleton untouchedInput
                & collateralInputsTxBodyL
                  .~ Set.singleton collateralInput
                & sizedOutputsTxBodyL
                  .~ SSeq.fromList [returned, returned]
                & sizedCollateralReturnTxBodyL
                  .~ SJust returned
                & feeTxBodyL
                  .~ Coin 11
                & treasuryDonationTxBodyL
                  .~ Coin 13
                & certsTxBodyL
                  .~ SSeq.singleton (RegDepositTxCert credential $ Coin 29)
            returnInput = TxIn (txIdTxBody body) (TxIx 2)
            originalStore = Store.mkUTxOStore originalCalculation $ IndexedUTxOs.singleton collateralInput originalEntry
            storagePrice rate acceptedOutput = (160 + toInteger (sizedSize acceptedOutput)) * rate
            expectedFee =
              Coin $
                1_000_000
                  - 50_000
                  + storagePrice 3 (sizedOutput originalEntry)
                  - storagePrice 7 returned
        forM_ [False, True] $ \hasCollision -> do
          let retained = (untouchedInput, untouchedEntry) : [(returnInput, collidingEntry) | hasCollision]
              liveEntries = IndexedUTxOs.fromList $ (collateralInput, liveEntry) : retained
              liveStore = Store.mkUTxOStore liveCalculation liveEntries
              previousAccountingState =
                AccountingState
                  liveStore
                  (Coin 19)
                  (Coin 17)
                  (addInstantStake (IndexedUTxOs.txOuts liveEntries) mempty)
                  (Coin 23)
              expectedEntries =
                IndexedUTxOs.fromList $
                  retained <> [(returnInput, Unspent returned liveCalculation) | not hasCollision]
              expectedTotal =
                Coin $
                  storagePrice 5 (sizedOutput untouchedEntry)
                    + if hasCollision then storagePrice 5 (sizedOutput collidingEntry) else storagePrice 13 returned
          depositChanges <- newIORef []
          Accounting.TxProjected
            { Accounting.updatedAccountingState = accountingState
            , Accounting.consumedOutputs = consumed
            , Accounting.producedOutputs = created
            } <-
            Accounting.projectTx
              def
              (mkBasicTx body & isPhase2ValidTxL .~ Phase2Invalid)
              def
              originalStore
              (\amount -> modifyIORef' depositChanges (<> [amount]))
              previousAccountingState
          readIORef depositChanges `shouldReturn` []
          consumed `shouldBe` IndexedUTxOs.singleton collateralInput liveEntry
          created
            `shouldBe` IndexedUTxOs.fromList
              [(returnInput, Unspent returned liveCalculation) | not hasCollision]
          accountingState
            `shouldBe` previousAccountingState
              { asUTxOStore = Store.mkUTxOStore liveCalculation expectedEntries
              , asFees = Coin 17 <> expectedFee
              , asInstantStake = addInstantStake (IndexedUTxOs.txOuts expectedEntries) mempty
              }
          toCoin (Store.totalDepositAmount $ asUTxOStore accountingState) `shouldBe` expectedTotal

-- Concrete era bodies above keep certificate and donation policy visible; this
-- shared assertion checks the returned changes, state and deposit notification.
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
    let entry coins = Unspent (mkSized (eraProtVerLow @era) $ testOutput coins) legacyDepositCalculation
        regularInput = TxIn sourceId (TxIx 0)
        sharedInput = TxIn sourceId (TxIx 1)
        collateralInput = TxIn sourceId (TxIx 2)
        untouchedInput = TxIn sourceId (TxIx 3)
        regularEntry = entry $ Coin 71
        sharedEntry = entry $ Coin 73
        collateralEntry = entry $ Coin 79
        untouchedEntry = entry $ Coin 83
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
        store = Store.mkUTxOStore legacyDepositCalculation entries
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
              , [(TxIn bodyId (TxIx 0), entry $ Coin 31), (TxIn bodyId (TxIx 1), entry $ Coin 37)]
              , Coin 11
              , Coin 48
              , Coin 23 <> donation
              )
            Phase2Invalid ->
              ( [(regularInput, regularEntry), (untouchedInput, untouchedEntry)]
              , [(sharedInput, sharedEntry), (collateralInput, collateralEntry)]
              , [ (TxIn bodyId (TxIx 2), Unspent (mkSized (eraProtVerLow @era) output) legacyDepositCalculation)
                | output <- maybe [] pure collateralReturn
                ]
              , Coin $ 73 + 79 - maybe 0 (const 23) collateralReturn
              , Coin 19
              , Coin 23
              )
          expectedEntries = IndexedUTxOs.fromList $ retained <> expectedCreated
      depositChanges <- newIORef []
      Accounting.TxProjected
        { Accounting.updatedAccountingState = accountingState
        , Accounting.consumedOutputs = consumed
        , Accounting.producedOutputs = created
        } <-
        Accounting.projectTx
          parameters
          (mkBasicTx body & isPhase2ValidTxL .~ validity)
          def
          store
          (\amount -> modifyIORef' depositChanges (<> [amount]))
          previousAccountingState
      readIORef depositChanges
        `shouldReturn` case validity of
          Phase2Valid -> [Coin 29]
          Phase2Invalid -> []
      consumed `shouldBe` IndexedUTxOs.fromList expectedConsumed
      created `shouldBe` IndexedUTxOs.fromList expectedCreated
      accountingState
        `shouldBe` AccountingState
          (Store.mkUTxOStore legacyDepositCalculation expectedEntries)
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
