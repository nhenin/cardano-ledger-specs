{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | Collateral application coins fund the return, any deposit shortfall and the
-- existing minimum fee. Released deposits first cover the return's deposit;
-- their surplus cannot replace those application coins.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.FundingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..), toDeltaCoin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  CollateralDepositSettlement (..),
  DijkstraUtxoPredFailure (BabbageOutputTooSmallUTxO, InsufficientCollateral),
  collateralDepositSettlement,
 )
import Cardano.Ledger.Shelley.LedgerState (utxoStoreL)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositFormula (..))
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import Cardano.Ledger.Val ((<->))
import Data.List.NonEmpty (NonEmpty (..))
import Data.Maybe.Strict (StrictMaybe (..), strictMaybeToMaybe)
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (
  Fixture (..),
  OutputForm (..),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (liveOutputStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (declarationToTxBody)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (
  getCurSlotNo,
  modifyNES,
  passTick,
  rederiveAddrTxWits,
  simulateThenRestore,
 )
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe, shouldSatisfy)

-- | Every sample includes both real script outcomes and every deposit relationship.
-- Changing only the return's application ADA preserves its deposit, even at zero.
-- Other collateral and ordinary requirements hold throughout these funded fixtures.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-FUNDING - Application coins fund the deposit shortfall before the minimum fee" $ do
  -- The Store needs more funding, reuses the same amount, or releases a surplus.
  -- Check the rounded minimum and one lovelace above; an absent return allocates
  -- nothing. A Store-backed return can contain zero application ADA.
  prop "DS-COLLATERAL-FUNDING-N01 - inputCoins - returnCoins - max(0, returnDeposit - releasedDeposits) ≥ minimumFee ⇒ accepted" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        fixture@Fixture{signedTx, minimumFee} <- Collateral.buildAndSign scenario
        case signedTx ^. bodyTxL . collateralReturnTxBodyL of
          SNothing -> submitTx signedTx >>= isAccepted
          SJust _ -> do
            forM_ [minimumFee, minimumFee <> Coin 1] $ \coinFee ->
              simulateThenRestore $ do
                funded <- Collateral.withCoinFee coinFee fixture
                let returnCoins = foldMap (^. coinTxOutL) $ Collateral.signedTx funded ^. bodyTxL . collateralReturnTxBodyL
                    additionalDeposit = max (Coin 0) (returnDeposit funded <-> releasedDeposits funded)
                inputCoins funded <-> returnCoins <-> additionalDeposit `shouldBe` coinFee
                submitTx (Collateral.signedTx funded) >>= isAccepted
            case Collateral.returnForm scenario of
              Just StoreBacked -> do
                zeroAdaReturn <- Collateral.withReturnCoins (Coin 0) fixture
                submitTx (Collateral.signedTx zeroAdaReturn) >>= isAccepted
              _ -> pure ()

  -- A released surplus cannot pay the minimum fee or enlarge the signed return.
  -- Reject exactly the funding error; accept the corresponding funded controls.
  prop "DS-COLLATERAL-FUNDING-F01 - inputCoins - returnCoins - max(0, returnDeposit - releasedDeposits) < minimumFee ⇒ rejectedWith(InsufficientCollateral)" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        fixture@Fixture{signedTx, inputCoins, releasedDeposits, minimumFee, protocolParameters} <- Collateral.buildAndSign scenario
        case signedTx ^. bodyTxL . collateralReturnTxBodyL of
          SNothing -> do
            -- Without a return, releasing ample Store ADA still cannot fund the
            -- minimum fee when the collateral outputs carry no application coins.
            if all (== StoreBacked) (Collateral.inputForms scenario)
              then simulateThenRestore $ do
                underfunded <- Collateral.buildAndSign $
                  scenario
                    { Collateral.inputCoinsPerOutput = Coin 0
                    , Collateral.sourceBytePrice = 10 * Collateral.bytePrice scenario
                    }
                Collateral.releasedDeposits underfunded `shouldSatisfy` (>= Collateral.minimumFee underfunded)
                forM_ [SNothing, SJust (Coin 0)] $ \declaredTotal -> do
                  rejected <- rederiveAddrTxWits $
                    Collateral.signedTx underfunded & bodyTxL . totalCollateralTxBodyL .~ declaredTotal
                  submitTx rejected >>= isRejectedOnlyWith
                    (InsufficientCollateral @DijkstraEra (toDeltaCoin $ Coin 0) (Collateral.minimumFee underfunded))
              else pure ()
            submitTx signedTx >>= isAccepted
          SJust returned -> do
            underfunded <- Collateral.withCoinFee (minimumFee <-> Coin 1) fixture
            forM_ [SNothing, Collateral.signedTx underfunded ^. bodyTxL . totalCollateralTxBodyL] $ \declaredTotal -> do
              rejected <- rederiveAddrTxWits $
                Collateral.signedTx underfunded & bodyTxL . totalCollateralTxBodyL .~ declaredTotal
              submitTx rejected >>= isRejectedOnlyWith
                (InsufficientCollateral @DijkstraEra (toDeltaCoin $ minimumFee <-> Coin 1) minimumFee)
            let releasedSurplus = max (Coin 0) (releasedDeposits <-> returnDeposit underfunded)
            if releasedSurplus > Coin 0
              then do
                (minimumFee <-> Coin 1) <> releasedSurplus `shouldSatisfy` (>= minimumFee)
                let largerReturn = returned & coinTxOutL .~ (inputCoins <> Coin 1)
                    additionalDeposit = max (Coin 0) (Pricing.outputDeposit protocolParameters largerReturn <-> releasedDeposits)
                    availableCoinFee = Coin (-1) <-> additionalDeposit
                rejected <- rederiveAddrTxWits $
                  signedTx
                    & bodyTxL . collateralReturnTxBodyL .~ SJust largerReturn
                    & bodyTxL . totalCollateralTxBodyL .~ SNothing
                submitTx rejected >>= isRejectedOnlyWith
                  (InsufficientCollateral @DijkstraEra (toDeltaCoin availableCoinFee) minimumFee)
              else pure ()
            funded <- Collateral.withCoinFee minimumFee fixture
            submitTx (Collateral.signedTx funded) >>= isAccepted

  -- Isolate the collateral calculation: arbitrary ordinary declarations need not
  -- describe a valid ordinary transaction. No ledger acceptance is claimed here.
  -- Only recorded collateral inputs and the priced collateral return participate.
  prop "DS-COLLATERAL-FUNDING-P02 - fixed collateral inputs, return, fee and prices ⇒ ordinary declarations do not change collateral deposit funding" $
    forAll ((,) <$> Collateral.fundingScenarios <*> Collateral.ordinaryDeclarationCases) $ \(scenarios, declarations) ->
      forM_ scenarios $ \scenario -> do
        Fixture{signedTx, previousAccountingState, inputCoins, releasedDeposits, returnDeposit} <- Collateral.buildAndSign scenario
        let originalBody = signedTx ^. bodyTxL
            returnCoins = foldMap (^. coinTxOutL) $ originalBody ^. collateralReturnTxBodyL
            additionalDeposit = max (Coin 0) (returnDeposit <-> releasedDeposits)
        forM_ declarations $ \ordinaryDeclarations -> do
          let body = declarationToTxBody ordinaryDeclarations
                & collateralInputsTxBodyL .~ (originalBody ^. collateralInputsTxBodyL)
                & collateralReturnTxBodyL .~ (originalBody ^. collateralReturnTxBodyL)
                & feeTxBodyL .~ (originalBody ^. feeTxBodyL)
                & totalCollateralTxBodyL .~ (originalBody ^. totalCollateralTxBodyL)
              settlement = collateralDepositSettlement (liveOutputStore previousAccountingState) body
          collateralReleasedDeposits settlement `shouldBe` releasedDeposits
          collateralReturnDeposit settlement `shouldBe` returnDeposit
          collateralAdditionalDeposit settlement `shouldBe` additionalDeposit
          collateralCoinFee settlement `shouldBe` inputCoins <-> returnCoins <-> additionalDeposit

  -- The input is allocated before the selected formula is activated. Its release
  -- stays historical; the newly proposed legacy return must contain the full
  -- current reserve. N = R = 0; its inline byte-string datum contributes its
  -- payload plus one CBOR header byte below 24 bytes, otherwise two (up to 48).
  -- withReturnCoins adjusts total collateral and re-signs without repairing the return.
  prop "DS-COLLATERAL-FUNDING-P03 - legacy(return) ∧ activeFormula ∈ {V1, V2} ⇒ exact reserve accepted ∧ reserve − 1 rejected" $
    forAll (Collateral.scenarios [StoreBacked] (Just Implicit) Phase2Invalid) $ \scenario ->
      forM_ [(DepositFormulaV1, 250), (DepositFormulaV2, 260)] $ \(version, baseBytes) ->
        simulateThenRestore $ do
          fixture <- Collateral.buildAndSign scenario
          passTick
          activationSlot <- getCurSlotNo
          let price = Collateral.bytePrice scenario
              payloadBytes = toInteger $ Collateral.returnBytes scenario
              datumBytes = payloadBytes + if payloadBytes < 24 then 1 else 2
              requiredDeposit = Coin $ price * (baseBytes + datumBytes)
          modifyNES $ utxoStoreL %~ Store.activateNewFormula activationSlot
            (version $ CoinPerByte $ CompactCoin $ fromInteger price)

          underfunded <- Collateral.withReturnCoins (requiredDeposit <-> Coin 1) fixture
          returned <- expectJust . strictMaybeToMaybe $
            Collateral.signedTx underfunded ^. bodyTxL . collateralReturnTxBodyL
          submitTx (Collateral.signedTx underfunded) >>= isRejectedOnlyWith
            (BabbageOutputTooSmallUTxO @DijkstraEra $ (returned, requiredDeposit) :| [])

          funded <- Collateral.withReturnCoins requiredDeposit fixture
          submitTx (Collateral.signedTx funded) >>= isAccepted
{- FOURMOLU_ENABLE -}
