{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

-- | The total held by the Store follows allocations and recorded releases exactly
-- once. Expected changes come from the applied transaction and its live inputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Store.BalanceSpec (spec) where

import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Mary.Value (AssetName (..), MaryValue (..), PolicyID (..), multiAssetFromList)
import Cardano.Ledger.Shelley.LedgerState (curPParamsEpochStateL, nesEsL)
import Cardano.Ledger.Shelley.Scripts (ShelleyEraScript (mkRequireSignature))
import Cardano.Ledger.State (DepositFormula (..), activateNewFormula, utxoStoreL)
import Cardano.Ledger.TxOut (sumAllAssets)
import Cardano.Ledger.Val (inject, (<->))
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (strictMaybeToMaybe)
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, chooseInteger, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects as Effects
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.UTxO as InputRoles
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  assertDepositTotal,
  liveOutputStore,
  recordedAmounts,
  retainsCreationMetadata,
  storedDepositTotal,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  ordinarySpendingInputs,
  readAccountingState,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (
  fixupTx,
  freshKeyAddrNoPtr_,
  freshKeyHash,
  getCurSlotNo,
  getsNES,
  impAddNativeScript,
  modifyNES,
  modifyPParams,
  passTick,
 )
import qualified Test.Cardano.Ledger.Dijkstra.ImpTest as Imp
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe)

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-BALANCE - Store balance" $ do
  -- Allocation, release, neutral replacement and implicit-only batches execute with
  -- local/delegated children. Unconsumed outputs keep their recorded deposits.
  prop "DS-STATE-BALANCE-P01 - accepted ∧ phase2Valid ⇒ ΔstoreBalance = newDeposits - recordedReleases" $
    forAll Effects.ordinaryScenarios $ \scenarios ->
      forM_ scenarios $ \scenario ->
        forM_ [Effects.buildAndSignOrdinary, Effects.buildAndSignDelegatedOrdinary] $ \build -> do
          signedTx <- build scenario
          previousAccountingState <- readAccountingState
          parameters <- getsNES $ nesEsL . curPParamsEpochStateL
          let previousStore = liveOutputStore previousAccountingState
              newDeposits = foldMap id $ Pricing.createdAllocations
                (Pricing.LedgerState previousAccountingState parameters) signedTx
              recordedReleases = foldMap id $ Map.restrictKeys
                (recordedAmounts previousStore) (ordinarySpendingInputs signedTx)
          submitTx signedTx >>= isAccepted
          state <- readAccountingState
          assertDepositTotal state
          let store = liveOutputStore state
          storedDepositTotal store `shouldBe` (storedDepositTotal previousStore <> newDeposits) <-> recordedReleases

  -- Real failures release historical collateral records and fund only the actual
  -- return. Real successes release only ordinary sources, including a source shared
  -- with collateral. The inactive path never charges it again.
  prop "DS-STATE-BALANCE-P02 - accepted ⇒ ΔstoreBalance = (if phase2Valid then -ordinaryReleases else returnDeposit - collateralReleases)" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario ->
        forM_ ([False] <> [True | Collateral.StoreBacked `elem` Collateral.inputForms scenario]) $ \shared -> do
          fixture <- Collateral.buildAndSign scenario >>= InputRoles.withReferenceOnlyInput
          Fixture{signedTx, releasedDeposits, returnDeposit} <-
            if shared then InputRoles.withSharedOrdinaryInput fixture else pure fixture
          previousStore <- liveOutputStore <$> readAccountingState
          let change = case signedTx ^. isPhase2ValidTxL of
                Phase2Valid -> Coin 0 <-> foldMap id (Map.restrictKeys
                  (recordedAmounts previousStore) (ordinarySpendingInputs signedTx))
                Phase2Invalid -> returnDeposit <-> releasedDeposits
          submitTx signedTx >>= isAccepted
          state <- readAccountingState
          assertDepositTotal state
          let store = liveOutputStore state
          storedDepositTotal store `shouldBe` storedDepositTotal previousStore <> change

  -- Recorded releases survive snapshot restoration, changed prices and a shorter re-encoding.
  -- Releasing the source returns its actual creation-time contribution,
  -- independently of the current cost of recreating an equal output.
  prop "DS-STATE-BALANCE-P03 - priceChanged ∧ consumedRecordedDeposit > 0 ∧ newDeposits = 0 ⇒ ΔstoreBalance = -consumedRecordedDeposit" $
    forAll (chooseInteger (50000000, 60000000)) $ \coins -> do
      (allocationTx, _) <- Effects.buildAndSignNoncanonicalAllocation $ Coin coins
      submitTx allocationTx >>= isAccepted
      readAccountingState >>= Effects.restoreAccountingState
      modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 2000)
      address <- freshKeyAddrNoPtr_
      let recordedDeposit = Coin $ 1000 * 250
          source = txInAt 0 allocationTx
      spendingTx <- fixupTx $
        Pricing.declareNetDeposit (Coin 0 <-> recordedDeposit) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.singleton source
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address $ inject $ Coin coins)
      previousStore <- liveOutputStore <$> readAccountingState
      Map.lookup source (recordedAmounts previousStore) `shouldBe` Just recordedDeposit
      submitTx spendingTx >>= isAccepted
      state <- readAccountingState
      assertDepositTotal state
      let store = liveOutputStore state
      storedDepositTotal store `shouldBe` storedDepositTotal previousStore <-> recordedDeposit

  -- Ordinary multi-body declarations can describe allocations and releases, but
  -- a real failing parent script applies neither transfer. Its collateral is implicit.
  prop "DS-STATE-BALANCE-P04 - accepted ∧ phase2Invalid ∧ implicitOnlyCollateral ⇒ storeBalanceAfter = storeBalanceBefore" $
    forAll Effects.ordinaryScenarios $ \scenarios ->
      forM_ (filter (not . null . Accounting.subOperations) scenarios) $ \scenario -> do
        signedTx <- Effects.buildAndSignOrdinaryPhase2Invalid scenario
        balanceBefore <- storedDepositTotal . liveOutputStore <$> readAccountingState
        submitTx signedTx >>= isAccepted
        state <- readAccountingState
        assertDepositTotal state
        let balanceAfter = storedDepositTotal $ liveOutputStore state
        balanceAfter `shouldBe` balanceBefore

  -- Two independently accepted outputs retain distinct historical prices, while
  -- a replacement is charged at the new current price. Restore before spending
  -- both so this covers the state codec and the live refund calculation together.
  prop "DS-STATE-BALANCE-P05 - mixedCreationPrices ∧ snapshotRestore ⇒ ΔstoreBalance = currentNewDeposit - sum historicalReleases" $
    forAll (chooseInteger (50000000, 60000000)) $ \coins -> do
      (oldTx, _) <- Effects.buildAndSignNoncanonicalAllocationAtRate (CoinPerByte $ CompactCoin 1000) $ Coin coins
      submitTx oldTx >>= isAccepted
      (newerTx, _) <- Effects.buildAndSignNoncanonicalAllocationAtRate (CoinPerByte $ CompactCoin 2000) $ Coin coins
      submitTx newerTx >>= isAccepted
      before <- readAccountingState
      let oldInput = txInAt 0 oldTx
          newerInput = txInAt 0 newerTx
          releases = Coin $ (1000 + 2000) * 250
      retainsCreationMetadata oldInput (CoinPerByte $ CompactCoin 1000) before
      retainsCreationMetadata newerInput (CoinPerByte $ CompactCoin 2000) before
      Effects.restoreAccountingState before
      modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 3000)
      address <- freshKeyAddrNoPtr_
      parameters <- getsNES $ nesEsL . curPParamsEpochStateL
      let output = mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject $ Coin coins
          newDeposit = Pricing.outputDeposit parameters output
      signedTx <- fixupTx $
        Pricing.declareNetDeposit (newDeposit <-> releases) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.fromList [oldInput, newerInput]
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton output
      submitTx signedTx >>= isAccepted
      after <- readAccountingState
      retainsCreationMetadata (txInAt 0 signedTx) (CoinPerByte $ CompactCoin 3000) after
      let beforeStore = liveOutputStore before
          afterStore = liveOutputStore after
      storedDepositTotal afterStore `shouldBe` (storedDepositTotal beforeStore <> newDeposit) <-> releases
      Map.lookup oldInput (recordedAmounts afterStore) `shouldBe` Nothing
      Map.lookup newerInput (recordedAmounts afterStore) `shouldBe` Nothing

  -- A child's output and allocation origin must enter the same store as parent outputs.
  -- A later ordinary spend uses the child's own output reference after restoration.
  prop "DS-STATE-BALANCE-P06 - noncanonicalSubTxOutput ∧ snapshotRestore ∧ priceChanged ⇒ refund = childCreationDeposit" $
    forAll (chooseInteger (50000000, 60000000)) $ \coins -> do
      (allocationTx, source) <- Effects.buildAndSignNoncanonicalSubAllocation $ Coin coins
      submitTx allocationTx >>= isAccepted
      before <- readAccountingState
      retainsCreationMetadata source (CoinPerByte $ CompactCoin 1000) before
      Effects.restoreAccountingState before
      modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 2000)
      address <- freshKeyAddrNoPtr_
      let release = Coin $ 1000 * 250
      spendingTx <- fixupTx $
        Pricing.declareNetDeposit (Coin 0 <-> release) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.singleton source
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address $ inject $ Coin coins)
      submitTx spendingTx >>= isAccepted
      after <- readAccountingState
      assertDepositTotal after
      storedDepositTotal (liveOutputStore after) `shouldBe` storedDepositTotal (liveOutputStore before) <-> release
      Map.lookup source (recordedAmounts $ liveOutputStore after) `shouldBe` Nothing

  -- Changing the return's CBOR map framing preserves its original deposit.
  -- Only the applied collateral return enters the Store on this path.
  prop "DS-STATE-BALANCE-P07 - noncanonicalCollateralReturn ∧ snapshotRestore ∧ priceChanged ⇒ refund = returnCreationDeposit" $
    forAll (Collateral.scenarios [Collateral.StoreBacked] (Just Collateral.StoreBacked) Phase2Invalid) $ \scenario -> do
      let currentPrice = Collateral.bytePrice scenario
      Fixture{signedTx = prepared, returnDeposit = release} <- Collateral.buildAndSign scenario
        { Collateral.sourceBytePrice = 2 * currentPrice }
      returned <- expectJust $ strictMaybeToMaybe $ prepared ^. bodyTxL . collateralReturnTxBodyL
      (signedTx, acceptedBytes) <- Effects.withNoncanonicalOutput prepared returned
      let source = txInAt (length $ signedTx ^. bodyTxL . outputsTxBodyL) signedTx
      fmap Binary.sizedSize (strictMaybeToMaybe $ signedTx ^. bodyTxL . sizedCollateralReturnTxBodyL)
        `shouldBe` Just (fromIntegral acceptedBytes)
      submitTx signedTx >>= isAccepted
      before <- readAccountingState
      retainsCreationMetadata source (CoinPerByte $ CompactCoin $ fromInteger currentPrice) before
      Effects.restoreAccountingState before
      modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin $ fromInteger $ 3 * currentPrice)
      address <- freshKeyAddrNoPtr_
      spendingTx <- fixupTx $
        Pricing.declareNetDeposit (Coin 0 <-> release) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.singleton source
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address $ unAssets $ sumAllAssets [returned])
      submitTx spendingTx >>= isAccepted
      after <- readAccountingState
      assertDepositTotal after
      storedDepositTotal (liveOutputStore after) `shouldBe` storedDepositTotal (liveOutputStore before) <-> release
      Map.lookup source (recordedAmounts $ liveOutputStore after) `shouldBe` Nothing

  -- Two identical outputs are accepted on either side of the version change.
  -- Spend them together under V2: each returns exactly the deposit paid.
  prop "DS-STATE-BALANCE-P08 - same output ∧ allocation slots straddle V2 activation ⇒ refund = V1(output) + V2(output)" $
    forAll (chooseInteger (1, 100)) $ \quantity -> do
      let rate = CoinPerByte $ CompactCoin 4310
      modifyPParams $ ppCoinsPerUTxOByteL .~ rate
      address <- freshKeyAddrNoPtr_
      policy <- PolicyID <$> (impAddNativeScript . mkRequireSignature =<< freshKeyHash)
      let assets = multiAssetFromList [(policy, AssetName "A", quantity), (policy, AssetName "B", 1)]
          value = MaryValue (Coin 50000000) assets
          output = mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets value
          allocateAt amount = Imp.submitTx $
            Pricing.declareNetDeposit amount $
              mkBasicTx mkBasicTxBody
                & bodyTxL . outputsTxBodyL .~ SSeq.singleton output
                & bodyTxL . mintTxBodyL .~ assets
          v1 = Coin $ 4310 * (250 + 74 * 2)
          v2 = Coin $ 4310 * (260 + 80 * 2)
      oldTx <- allocateAt v1
      passTick
      activationSlot <- getCurSlotNo
      modifyNES $ utxoStoreL %~ activateNewFormula activationSlot (DepositFormulaV2 rate)
      newTx <- allocateAt v2
      readAccountingState >>= Effects.restoreAccountingState
      before <- liveOutputStore <$> readAccountingState
      let oldInput = txInAt 0 oldTx
          newInput = txInAt 0 newTx
          inputs = Set.fromList [oldInput, newInput]
      Map.restrictKeys (recordedAmounts before) inputs `shouldBe` Map.fromList [(oldInput, v1), (newInput, v2)]
      signed <- fixupTx $
        Pricing.declareNetDeposit (Coin 0 <-> (v1 <> v2)) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ inputs
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address (value <> value))
      submitTx signed >>= isAccepted
      after <- readAccountingState
      storedDepositTotal (liveOutputStore after) `shouldBe` storedDepositTotal before <-> (v1 <> v2)
      assertDepositTotal after
{- FOURMOLU_ENABLE -}
