{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | External deposits do not change the native assets a collateral return owes.
-- Every generated sample covers implicit and Store-backed returns, mixed inputs,
-- and real successful and failing scripts. The tokens come from accepted minting.
-- Common premises: valid inputs, witnesses, output forms, total and coin funding.
-- Each rejected variant changes only native-asset conservation.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.AssetsSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure (CollateralContainsNonADA))
import Cardano.Ledger.Mary.Value (MaryValue (..))
import Control.Monad (when)
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (
  Fixture (..),
  OutputForm (StoreBacked),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (simulateThenRestore)

-- | Compare native assets independently of the ADA used for deposits and fees.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-ASSETS - Assets" $ do
  -- The return keeps every consumed token, while its Store deposit is funded separately.
  -- A Store-backed return can retain those tokens with zero application ADA.
  prop "DS-COLLATERAL-ASSETS-N01 - consumedAssets = returnAssets ⇒ accepted" $
    forAll Collateral.assetScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        fixture <- Collateral.buildAndSign scenario
        when (Collateral.returnForm scenario == Just StoreBacked) $
          simulateThenRestore $
            Collateral.withReturnCoins (Coin 0) fixture >>= submitTx . signedTx >>= isAccepted
        Collateral.withCoinFee (minimumFee fixture) fixture
          >>= submitTx . signedTx >>= isAccepted

  -- Remove every token, change its quantity, or add an unconsumed token.
  -- Reprice and fund each changed return so asset imbalance is the only failure.
  -- An absent return also loses the tokens; the unchanged control must be accepted.
  prop "DS-COLLATERAL-ASSETS-F01 - consumedAssets ≠ returnAssets ⇒ rejectedWith(CollateralContainsNonADA)" $
    forAll Collateral.assetScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        fixture@Fixture{inputCoins, collateralAssets, minimumFee} <- Collateral.buildAndSign scenario
        forM_ [mempty, collateralAssets <> collateralAssets, Collateral.additionalAsset collateralAssets] $ \returnedAssets ->
          Collateral.withReturnAssets returnedAssets fixture
            >>= Collateral.withCoinFee minimumFee
            >>= submitTx . signedTx
            >>= isRejectedOnlyWith (CollateralContainsNonADA @DijkstraEra $ MaryValue inputCoins collateralAssets)
        when (StoreBacked `elem` Collateral.inputForms scenario) $
          Collateral.withoutReturn fixture
            >>= submitTx . signedTx
            >>= isRejectedOnlyWith (CollateralContainsNonADA @DijkstraEra $ MaryValue inputCoins collateralAssets)
        Collateral.withCoinFee minimumFee fixture >>= submitTx . signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
