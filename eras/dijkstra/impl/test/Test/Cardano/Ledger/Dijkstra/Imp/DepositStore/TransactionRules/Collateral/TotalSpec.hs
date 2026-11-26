{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeApplications #-}

-- | The optional total keeps its existing application-coin meaning. It includes
-- coins funding a new Store deposit and excludes deposits released from the Store.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.TotalSpec (spec) where

import Cardano.Ledger.Coin (Coin (..), toDeltaCoin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure (IncorrectTotalCollateralField))
import Cardano.Ledger.Val ((<->))
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  isAccepted,
  isRejectedOnlyWith,
  submitTx,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (rederiveAddrTxWits, simulateThenRestore)

-- | All other rules hold. Both script outcomes use real V4 execution.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-COLLATERAL-TOTAL - The optional total measures application coins, including any deposit funding" $ do
  -- Allocation, reuse, surplus and no-return scenarios retain the same equality.
  -- Omission removes only this comparison; every fixture remains fully funded.
  prop "DS-COLLATERAL-TOTAL-N01 - declaredTotal ∈ {Absent, inputCoins - returnCoins} ⇒ accepted" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        Fixture{signedTx, inputCoins} <- Collateral.buildAndSign scenario
        let returnCoins = foldMap (^. coinTxOutL) $ signedTx ^. bodyTxL . collateralReturnTxBodyL
        forM_ [SNothing, SJust (inputCoins <-> returnCoins)] $ \declaredTotal ->
          simulateThenRestore $
            rederiveAddrTxWits (signedTx & bodyTxL . totalCollateralTxBodyL .~ declaredTotal)
              >>= submitTx >>= isAccepted

  -- Test both one-lovelace directions, including with real successful scripts.
  -- Releasing an external deposit does not excuse an incorrect application total.
  prop "DS-COLLATERAL-TOTAL-F01 - declaredTotal = inputCoins - returnCoins ± 1 lovelace ⇒ rejectedWith(IncorrectTotalCollateralField)" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        Fixture{signedTx, inputCoins} <- Collateral.buildAndSign scenario
        let returnCoins = foldMap (^. coinTxOutL) $ signedTx ^. bodyTxL . collateralReturnTxBodyL
            expectedTotal = inputCoins <-> returnCoins
        forM_ [expectedTotal <-> Coin 1, expectedTotal <> Coin 1] $ \incorrectTotal -> do
          rejected <- rederiveAddrTxWits $ signedTx & bodyTxL . totalCollateralTxBodyL .~ SJust incorrectTotal
          submitTx rejected >>= isRejectedOnlyWith
            (IncorrectTotalCollateralField @DijkstraEra (toDeltaCoin expectedTotal) incorrectTotal)
        submitTx signedTx >>= isAccepted
{- FOURMOLU_ENABLE -}
