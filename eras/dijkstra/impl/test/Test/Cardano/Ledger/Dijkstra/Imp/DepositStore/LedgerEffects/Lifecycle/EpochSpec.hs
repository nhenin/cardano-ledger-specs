module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.EpochSpec (spec) where

import Cardano.Ledger.Coin (CoinPerByte (..), CompactForm (..))
import Cardano.Ledger.Dijkstra.Core (ppCoinsPerUTxOByteL)
import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.State
import qualified Data.Map.Strict as Map
import Lens.Micro ((%~), (&), (.~), (^.))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Lifecycle as Lifecycle
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  assertDepositTotal,
  liveOutputStore,
  recordedAmounts,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (getsNES, modifyNES, passEpoch)
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Cross two ordinary epoch boundaries with live allocations and unchanged
-- protocol parameters. Epoch processing must preserve every recorded deposit.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-EPOCH - Epoch" $ do
  prop "DS-STATE-EPOCH-N01 - ordinaryEpochTransition ⇒ allocationsAfter = allocationsBefore" $
    forAll Lifecycle.populatedStore $ \fundingScenario -> do
      -- Submit only the funding transaction: its Store-backed outputs remain unspent.
      _ <- fundAccountingScenario fundingScenario
      forM_ [1 :: Int, 2] $ \_ -> do
        previousState <- getsNES id
        let previousUTxOState = previousState ^. nesEsL . esLStateL . lsUTxOStateL
            previousStore = liveOutputStore previousUTxOState
        Map.null (recordedAmounts $ liveOutputStore previousUTxOState) `shouldBe` False
        assertDepositTotal previousUTxOState
        passEpoch
        state <- getsNES id
        state ^. nesELL `shouldBe` succ (previousState ^. nesELL)
        state ^. nesEsL . curPParamsEpochStateL `shouldBe` previousState ^. nesEsL . curPParamsEpochStateL
        let utxoState = state ^. nesEsL . esLStateL . lsUTxOStateL
        liveOutputStore utxoState `shouldBe` previousStore
        assertDepositTotal utxoState

  -- A scheduled parameter update becomes effective at the real epoch boundary.
  -- Activation keeps the formula version and changes only its parameter;
  -- existing outputs retain the calculation that determined their refund.
  prop "DS-STATE-EPOCH-N02 - effectiveRate' = rate' ⇒ currentCalculation' = V(rate') ∧ allocations' = allocations ∧ totalDepositAmount' = totalDepositAmount" $
    forAll Lifecycle.populatedStore $ \fundingScenario -> do
      _ <- fundAccountingScenario fundingScenario
      forM_ [DepositCalculationV1, DepositCalculationV2] $ \version -> do
        parameters <- getsNES $ nesEsL . curPParamsEpochStateL
        let CoinPerByte (CompactCoin rate) = parameters ^. ppCoinsPerUTxOByteL
            nextRate = CoinPerByte $ CompactCoin $ rate + 1000
            nextParameters = parameters & ppCoinsPerUTxOByteL .~ nextRate
        modifyNES $
          (utxoStoreL %~ activateNewCalculation (version $ CoinPerByte $ CompactCoin rate))
            . (newEpochStateGovStateL . futurePParamsGovStateL .~ DefinitePParamsUpdate nextParameters)
        previousStore <- getsNES utxoStoreG

        passEpoch

        utxoState <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
        let store = liveOutputStore utxoState
        getsNES (nesEsL . curPParamsEpochStateL) >>= (`shouldBe` nextParameters)
        currentCalculation store `shouldBe` version nextRate
        allocations store `shouldBe` allocations previousStore
        totalDepositAmount store `shouldBe` totalDepositAmount previousStore
        assertDepositTotal utxoState
{- FOURMOLU_ENABLE -}
