{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Excess released collateral capacity deposits are credited to the fee pot.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.SurplusSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (
  esLStateL,
  lsUTxOStateL,
  nesEsL,
  utxosDepositStore,
  utxosFees,
  utxosUtxo,
 )
import Cardano.Ledger.State (DepositStore (..), UTxO (..), treasuryL)
import Cardano.Ledger.Val (Val ((<->)), inject)
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, describe, forM_, it, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (preparePhase2InvalidTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Spending (
  SpendingBody (TopTxSpending),
  SpendingFixture (..),
  buildTxSpendingStoreBackedOutput,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe, shouldSatisfy, withImpInit)

-- | A real phase-2 failure returns 5 ADA from 10 ADA of collateral application
-- coins. Its recorded deposit is released entirely to fees because the return is
-- implicit. Ordinary inputs and outputs do not execute. Universal properties
-- remain in the executable backlog until their generators are implemented.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-SURPLUS - Surplus" $ do
  withImpInit @(LedgerSpec DijkstraEra) $
    it "DS-COLLATERAL-SURPLUS-N01 - credits excess released UTxO capacity deposits to fees rather than the treasury" $ do
      fixture <- buildTxSpendingStoreBackedOutput TopTxSpending
      address <- freshKeyAddrNoPtr_
      let collateralInput = spendingInput fixture
          releasedDeposit = spendingDeposit fixture
          collateralCoinFee = Coin 5_000_000
          collateralReturn = mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 5_000_000
      tx <- preparePhase2InvalidTx $
        mkBasicTx mkBasicTxBody
          & bodyTxL . collateralInputsTxBodyL .~ Set.singleton collateralInput
          & bodyTxL . totalCollateralTxBodyL .~ SJust collateralCoinFee
          & bodyTxL . collateralReturnTxBodyL .~ SJust collateralReturn
      tx ^. bodyTxL . collateralInputsTxBodyL `shouldBe` Set.singleton collateralInput
      tx ^. bodyTxL . collateralReturnTxBodyL `shouldBe` SJust collateralReturn
      before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
      treasuryBefore <- getsNES treasuryL
      let storeBefore = utxosDepositStore before
          ordinaryInputs = tx ^. bodyTxL . inputsTxBodyL
          returnInput = txInAt (length $ tx ^. bodyTxL . outputsTxBodyL) tx
      releasedDeposit `shouldSatisfy` (> Coin 0)
      Map.lookup collateralInput (depositStoreAllocations storeBefore) `shouldBe` Just releasedDeposit
      withNoFixup $ submitTx_ tx
      after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
      treasuryAfter <- getsNES treasuryL
      let storeAfter = utxosDepositStore after
          outputsAfter = unUTxO $ utxosUtxo after
      utxosFees after `shouldBe` utxosFees before <> collateralCoinFee <> releasedDeposit
      treasuryAfter `shouldBe` treasuryBefore
      depositStoreBalance storeAfter `shouldBe` depositStoreBalance storeBefore <-> releasedDeposit
      depositStoreAllocations storeAfter `shouldBe` Map.delete collateralInput (depositStoreAllocations storeBefore)
      Map.lookup collateralInput outputsAfter `shouldBe` Nothing
      Map.lookup returnInput outputsAfter `shouldBe` Just collateralReturn
      Map.restrictKeys outputsAfter ordinaryInputs `shouldBe` Map.restrictKeys (unUTxO $ utxosUtxo before) ordinaryInputs
      forM_ [0 .. length (tx ^. bodyTxL . outputsTxBodyL) - 1] $ \index ->
        Map.lookup (txInAt index tx) outputsAfter `shouldBe` Nothing
  prop "DS-COLLATERAL-SURPLUS-P01 - accepted phase-2 failure ⇒ feesAfter = feesBefore + collateralCoinFee + releasedUTxODepositFee" addsReleasedSurplusToFees
  prop "DS-COLLATERAL-SURPLUS-P02 - accepted phase-2 failure ⇒ treasuryAfter = treasuryBefore" preservesTreasury
{- FOURMOLU_ENABLE -}

addsReleasedSurplusToFees :: Bool
addsReleasedSurplusToFees = False

preservesTreasury :: Bool
preservesTreasury = False
