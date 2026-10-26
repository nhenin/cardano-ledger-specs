{-# LANGUAGE NamedFieldPuns #-}

-- | Count each live Store deposit exactly once in total ADA, then preserve that
-- total when transactions allocate or release deposits on either execution path.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.ConservationSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.AdaPots (totalAdaES)
import Cardano.Ledger.Shelley.LedgerState (
  epochStateDonationL,
  esLState,
  lsUTxOState,
  nesEsL,
  utxosDonation,
 )
import Cardano.Ledger.State (depositStoreAllocations, reservesL)
import Cardano.Ledger.Val ((<->))
import Lens.Micro ((%~), (&))
import Test.Cardano.Ledger.Common (Spec, chooseInteger, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects as Effects
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.ADA (actualAda)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (recordedDepositStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.ImpTest (getsNES, modifyNES)
import Test.Cardano.Ledger.Imp.Common (shouldBe, shouldSatisfy)

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-CONSERVATION - ADA conservation" $ do
  -- Positive live deposits expose an omitted or double-counted Store. Donations
  -- are also positive, so leaving out that separate pot cannot satisfy the oracle.
  prop "DS-STATE-CONSERVATION-N01 - ΣrecordedDeposits > 0 ⇒ totalAdaES + donations = actualAda" $
    forAll ((,)
      <$> Collateral.scenarios [Collateral.StoreBacked] (Just Collateral.StoreBacked) Phase2Valid
      <*> chooseInteger (1, 1000000)) $ \(scenario, donation) -> do
        Fixture{signedTx} <- Collateral.buildAndSign scenario
        reserves <- getsNES reservesL
        reserves `shouldSatisfy` (>= Coin donation)
        modifyNES $ \state -> state
          & reservesL %~ (<-> Coin donation)
          & nesEsL . epochStateDonationL %~ (<> Coin donation)
        before <- getsNES nesEsL
        submitTx signedTx >>= isAccepted
        after <- getsNES nesEsL
        forM_ [before, after] $ \epoch -> do
          let utxoState = lsUTxOState $ esLState epoch
              store = recordedDepositStore utxoState
              obligations = foldMap id $ depositStoreAllocations store
          obligations `shouldSatisfy` (> Coin 0)
          totalAdaES epoch <> utxosDonation utxoState `shouldBe` actualAda epoch

  -- Local and delegated children move ADA between application outputs and the
  -- Store; neither funding responsibility nor a zero net change creates coins.
  prop "DS-STATE-CONSERVATION-N02 - accepted ∧ phase2Valid ⇒ actualAdaAfter = actualAdaBefore" $
    forAll Effects.ordinaryScenarios $ \scenarios ->
      forM_ scenarios $ \scenario ->
        forM_ [Effects.buildAndSignOrdinary, Effects.buildAndSignDelegatedOrdinary] $ \build -> do
          signedTx <- build scenario
          previousEpochState <- getsNES nesEsL
          submitTx signedTx >>= isAccepted
          epochState <- getsNES nesEsL
          actualAda epochState `shouldBe` actualAda previousEpochState

  -- Actual script failure selects collateral only. Cover mixed inputs, missing
  -- returns and a return deposit smaller than, equal to or greater than releases.
  prop "DS-STATE-CONSERVATION-N03 - accepted ∧ phase2Invalid ⇒ actualAdaAfter = actualAdaBefore" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ (filter ((== Phase2Invalid) . Collateral.phase2) scenarios) $ \scenario -> do
        Fixture{signedTx} <- Collateral.buildAndSign scenario
        previousEpochState <- getsNES nesEsL
        submitTx signedTx >>= isAccepted
        epochState <- getsNES nesEsL
        actualAda epochState `shouldBe` actualAda previousEpochState
{- FOURMOLU_ENABLE -}
