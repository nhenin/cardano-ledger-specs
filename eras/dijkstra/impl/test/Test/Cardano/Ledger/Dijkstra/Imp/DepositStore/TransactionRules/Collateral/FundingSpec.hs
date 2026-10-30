{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | Collateral application coins fund the return, any deposit shortfall and the
-- existing minimum fee. Released deposits first cover the return's deposit;
-- their surplus cannot replace those application coins.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.FundingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..), toDeltaCoin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  CollateralDepositSettlement (..),
  DijkstraUtxoPredFailure (InsufficientCollateral),
  collateralDepositSettlement,
 )
import Cardano.Ledger.Val ((<->))
import Data.Maybe.Strict (StrictMaybe (..))
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
import Test.Cardano.Ledger.Dijkstra.ImpTest (rederiveAddrTxWits, simulateThenRestore)
import Test.Cardano.Ledger.Imp.Common (shouldBe, shouldSatisfy)

-- | Every sample includes both real script outcomes and every deposit relationship.
-- The return's final serialized bytes determine its deposit, including at zero ADA.
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
        Fixture{signedTx, previousUTxOState, inputCoins, releasedDeposits, returnDeposit} <- Collateral.buildAndSign scenario
        let originalBody = signedTx ^. bodyTxL
            returnCoins = foldMap (^. coinTxOutL) $ originalBody ^. collateralReturnTxBodyL
            additionalDeposit = max (Coin 0) (returnDeposit <-> releasedDeposits)
        forM_ declarations $ \ordinaryDeclarations -> do
          let body = declarationToTxBody ordinaryDeclarations
                & collateralInputsTxBodyL .~ (originalBody ^. collateralInputsTxBodyL)
                & collateralReturnTxBodyL .~ (originalBody ^. collateralReturnTxBodyL)
                & feeTxBodyL .~ (originalBody ^. feeTxBodyL)
                & totalCollateralTxBodyL .~ (originalBody ^. totalCollateralTxBodyL)
              settlement = collateralDepositSettlement (liveOutputStore previousUTxOState) body
          collateralReleasedDeposits settlement `shouldBe` releasedDeposits
          collateralReturnDeposit settlement `shouldBe` returnDeposit
          collateralAdditionalDeposit settlement `shouldBe` additionalDeposit
          collateralCoinFee settlement `shouldBe` inputCoins <-> returnCoins <-> additionalDeposit
{- FOURMOLU_ENABLE -}
