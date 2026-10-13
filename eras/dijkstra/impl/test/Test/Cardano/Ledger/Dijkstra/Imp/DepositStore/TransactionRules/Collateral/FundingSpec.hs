{-# LANGUAGE TypeApplications #-}

-- | Collateral coins fund the specified return, additional capacity deposit and minimum fee.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.FundingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..), toDeltaCoin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure (InsufficientCollateral))
import Cardano.Ledger.Shelley.LedgerState (
  esLStateL,
  lsUTxOStateL,
  nesEsL,
  utxosDepositStore,
  utxosFees,
  utxosUtxo,
 )
import Cardano.Ledger.State (DepositStore (..), UTxO (..))
import Cardano.Ledger.Val (Val ((<->)))
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (strictMaybeToMaybe)
import Lens.Micro
import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Collateral as Collateral
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Spending (
  submitTxAndExpectFailureContaining,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe, shouldSatisfy, withImpInit)

-- | N04, F02, F03 and F05 exercise real ledger funding; the other cases remain
-- deliberate executable backlog.
-- Keep each requirement and its named check on one line.
-- Both output variants are fixture coverage across these funding cases and the
-- authorization, settlement and conservation checks; they are not a separate rule.
-- Funding validation covers both script outcomes whenever any body has redeemers.
-- Observe required amounts and acceptance here; State owns applied Store records.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-FUNDING - Funding" $ do
  it "DS-COLLATERAL-FUNDING-F01 - rejects insufficient collateral funding when redeemers trigger validation even if all scripts succeed" successfulScriptsDoNotBypassCollateralFunding
  it "DS-COLLATERAL-FUNDING-N01 - accepts a batch whose scripts succeed when its required collateral is fully funded and all other rules hold" successfulScriptsAcceptValidCollateral
  it "DS-COLLATERAL-FUNDING-N02 - accepts funded collateral with implicit or store-backed inputs and returns" supportsBothOutputVariants
  it "DS-COLLATERAL-FUNDING-N03 - reuses released UTxO capacity deposits when the collateral return requires the same amount" reusesReleasedDeposits
  withImpInit @(LedgerSpec DijkstraEra) $
    it "DS-COLLATERAL-FUNDING-N04 - funds additional return UTxO capacity deposits from collateral coins" $ do
      fixture <- Collateral.implicitInputWithStoreBackedReturn
      tx <- Collateral.withCoinFee (Collateral.minimumFee fixture) fixture
      collateralReturn <- expectJust $ strictMaybeToMaybe $ tx ^. bodyTxL . collateralReturnTxBodyL
      before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
      let storeBefore = utxosDepositStore before
          newDeposit = Collateral.returnDeposit fixture
          returnInput = txInAt (length $ tx ^. bodyTxL . outputsTxBodyL) tx
      Collateral.releasedDeposit fixture `shouldBe` Coin 0
      newDeposit `shouldSatisfy` (> Coin 0)
      Collateral.inputCoins fixture `shouldBe` (collateralReturn ^. coinTxOutL) <> newDeposit <> Collateral.minimumFee fixture
      withNoFixup $ submitTx_ tx
      after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
      let storeAfter = utxosDepositStore after
      utxosFees after `shouldBe` utxosFees before <> Collateral.minimumFee fixture
      depositStoreBalance storeAfter `shouldBe` depositStoreBalance storeBefore <> newDeposit
      depositStoreAllocations storeAfter `shouldBe` Map.insert returnInput newDeposit (depositStoreAllocations storeBefore)
      Map.lookup (Collateral.input fixture) (unUTxO $ utxosUtxo after) `shouldBe` Nothing
      Map.lookup returnInput (unUTxO $ utxosUtxo after) `shouldBe` Just collateralReturn
  withImpInit @(LedgerSpec DijkstraEra) $
    it "DS-COLLATERAL-FUNDING-F02 - rejects collateral coins below the minimum fee after funding the return and additional UTxO capacity deposits" $ do
      fixture <- Collateral.implicitInputWithStoreBackedReturn
      tx <- Collateral.withCoinFee (Coin 0) fixture
      Collateral.returnDeposit fixture `shouldSatisfy` (> Coin 0)
      submitTxAndExpectFailureContaining
        (injectFailure $ InsufficientCollateral @DijkstraEra (toDeltaCoin $ Coin 0) (Collateral.minimumFee fixture)) tx
  prop "DS-COLLATERAL-FUNDING-P01 - accepted batch with redeemers ⇒ collateralCoinFee ≥ ceil(txFee * collateralPercentage / 100)" fundsMinimumFeeIndependently
  withImpInit @(LedgerSpec DijkstraEra) $
    it "DS-COLLATERAL-FUNDING-F03 - rejects collateral whose minimum fee depends on released UTxO capacity deposit surplus" $ do
      fixture <- Collateral.storeBackedInputWithImplicitReturn
      let coinFee = Collateral.minimumFee fixture <-> Coin 1
          releasedSurplus = Collateral.releasedDeposit fixture
      tx <- Collateral.withCoinFee coinFee fixture
      Collateral.returnDeposit fixture `shouldBe` Coin 0
      coinFee <> releasedSurplus `shouldSatisfy` (>= Collateral.minimumFee fixture)
      submitTxAndExpectFailureContaining
        (injectFailure $ InsufficientCollateral @DijkstraEra (toDeltaCoin coinFee) (Collateral.minimumFee fixture)) tx
  it "DS-COLLATERAL-FUNDING-F04 - rejects a collateral return whose funding depends on released UTxO capacity deposit surplus" surplusCannotFundLargerReturn
  withImpInit @(LedgerSpec DijkstraEra) $
    it "DS-COLLATERAL-FUNDING-F05 - rejects collateral funding one lovelace below a rounded-up minimum fee" $ do
      fixture <- Collateral.implicitInputWithStoreBackedReturn
      let coinFee = Collateral.minimumFee fixture <-> Coin 1
          Coin txFee = Collateral.tx fixture ^. bodyTxL . feeTxBodyL
          collateralPercentage = toInteger $ Collateral.protocolParameters fixture ^. ppCollateralPercentageL
      (txFee * collateralPercentage) `mod` 100 `shouldBe` 50
      tx <- Collateral.withCoinFee coinFee fixture
      submitTxAndExpectFailureContaining
        (injectFailure $ InsufficientCollateral @DijkstraEra (toDeltaCoin coinFee) (Collateral.minimumFee fixture)) tx
  it "DS-COLLATERAL-FUNDING-N05 - counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs" mixedInputsCountImplicitCoinsWithoutStoreRelease
  it "DS-COLLATERAL-FUNDING-N06 - requires zero Store deposit for an implicit collateral return even with store-backed collateral inputs" implicitReturnRequiresNoStoreDeposit
  it "DS-COLLATERAL-FUNDING-N07 - accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded" zeroApplicationAdaReturnIsAccepted
  it "DS-COLLATERAL-FUNDING-F06 - rejects underfunded collateral when the optional total is absent" checksFundingWithoutDeclaredTotal
  it "DS-COLLATERAL-FUNDING-N08 - accepts collateral funding exactly at a rounded-up minimum fee" acceptsRoundedUpMinimumFee
{- FOURMOLU_ENABLE -}

successfulScriptsDoNotBypassCollateralFunding :: Expectation
successfulScriptsDoNotBypassCollateralFunding = False `shouldBe` True

successfulScriptsAcceptValidCollateral :: Expectation
successfulScriptsAcceptValidCollateral = False `shouldBe` True

supportsBothOutputVariants :: Expectation
supportsBothOutputVariants = False `shouldBe` True

reusesReleasedDeposits :: Expectation
reusesReleasedDeposits = False `shouldBe` True

fundsMinimumFeeIndependently :: Bool
fundsMinimumFeeIndependently = False

surplusCannotFundLargerReturn :: Expectation
surplusCannotFundLargerReturn = False `shouldBe` True

mixedInputsCountImplicitCoinsWithoutStoreRelease :: Expectation
mixedInputsCountImplicitCoinsWithoutStoreRelease = False `shouldBe` True

implicitReturnRequiresNoStoreDeposit :: Expectation
implicitReturnRequiresNoStoreDeposit = False `shouldBe` True

zeroApplicationAdaReturnIsAccepted :: Expectation
zeroApplicationAdaReturnIsAccepted = False `shouldBe` True

checksFundingWithoutDeclaredTotal :: Expectation
checksFundingWithoutDeclaredTotal = False `shouldBe` True

acceptsRoundedUpMinimumFee :: Expectation
acceptsRoundedUpMinimumFee = False `shouldBe` True
