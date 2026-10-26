{-# LANGUAGE NamedFieldPuns #-}

-- | The total held by the Store follows allocations and recorded releases exactly
-- once. Expected changes come from the applied transaction and its live inputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Store.BalanceSpec (spec) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (curPParamsEpochStateL, nesEsL, utxosDepositStore)
import Cardano.Ledger.State (depositStoreAllocations, depositStoreBalance)
import Cardano.Ledger.Val (inject, (<->))
import qualified Data.Map.Strict as Map
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, chooseInteger, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects as Effects
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.UTxO as InputRoles
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  createdOrdinaryOutputs,
  ordinarySpendingInputs,
  readLedger,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (fixupTx, freshKeyAddrNoPtr_, getsNES, modifyPParams)
import Test.Cardano.Ledger.Imp.Common (shouldBe)

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
          previousUTxOState <- readLedger
          parameters <- getsNES $ nesEsL . curPParamsEpochStateL
          let previousStore = utxosDepositStore previousUTxOState
              newDeposits = foldMap (Pricing.outputDeposit parameters) $ createdOrdinaryOutputs signedTx
              recordedReleases = foldMap id $ Map.restrictKeys
                (depositStoreAllocations previousStore) (ordinarySpendingInputs signedTx)
          submitTx signedTx >>= isAccepted
          store <- utxosDepositStore <$> readLedger
          depositStoreBalance store `shouldBe` (depositStoreBalance previousStore <> newDeposits) <-> recordedReleases

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
          previousStore <- utxosDepositStore <$> readLedger
          let change = case signedTx ^. isPhase2ValidTxL of
                Phase2Valid -> Coin 0 <-> foldMap id (Map.restrictKeys
                  (depositStoreAllocations previousStore) (ordinarySpendingInputs signedTx))
                Phase2Invalid -> returnDeposit <-> releasedDeposits
          submitTx signedTx >>= isAccepted
          store <- utxosDepositStore <$> readLedger
          depositStoreBalance store `shouldBe` depositStoreBalance previousStore <> change

  -- Recorded releases survive snapshot restoration, changed prices and a shorter re-encoding.
  -- Releasing the source returns its actual creation-time contribution,
  -- independently of the current cost of recreating an equal output.
  prop "DS-STATE-BALANCE-P03 - priceChanged ∧ consumedRecordedDeposit > 0 ∧ newDeposits = 0 ⇒ ΔstoreBalance = -consumedRecordedDeposit" $
    forAll (chooseInteger (50000000, 60000000)) $ \coins -> do
      (allocationTx, acceptedBytes) <- Effects.buildAndSignNoncanonicalAllocation $ Coin coins
      submitTx allocationTx >>= isAccepted
      readLedger >>= Effects.restoreUTxOState
      modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 2000)
      address <- freshKeyAddrNoPtr_
      let recordedDeposit = Coin $ 1000 * (160 + toInteger acceptedBytes)
          source = txInAt 0 allocationTx
      spendingTx <- fixupTx $
        Pricing.declareNetDeposit (Coin 0 <-> recordedDeposit) $
          mkBasicTx mkBasicTxBody
            & bodyTxL . inputsTxBodyL .~ Set.singleton source
            & bodyTxL . outputsTxBodyL .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit address $ inject $ Coin coins)
      previousStore <- utxosDepositStore <$> readLedger
      Map.lookup source (depositStoreAllocations previousStore) `shouldBe` Just recordedDeposit
      submitTx spendingTx >>= isAccepted
      store <- utxosDepositStore <$> readLedger
      depositStoreBalance store `shouldBe` depositStoreBalance previousStore <-> recordedDeposit

  -- Ordinary multi-body declarations can describe allocations and releases, but
  -- a real failing parent script applies neither transfer. Its collateral is implicit.
  prop "DS-STATE-BALANCE-P04 - accepted ∧ phase2Invalid ∧ implicitOnlyCollateral ⇒ storeBalanceAfter = storeBalanceBefore" $
    forAll Effects.ordinaryScenarios $ \scenarios ->
      forM_ (filter (not . null . Accounting.subOperations) scenarios) $ \scenario -> do
        signedTx <- Effects.buildAndSignOrdinaryPhase2Invalid scenario
        balanceBefore <- depositStoreBalance . utxosDepositStore <$> readLedger
        submitTx signedTx >>= isAccepted
        balanceAfter <- depositStoreBalance . utxosDepositStore <$> readLedger
        balanceAfter `shouldBe` balanceBefore
{- FOURMOLU_ENABLE -}
