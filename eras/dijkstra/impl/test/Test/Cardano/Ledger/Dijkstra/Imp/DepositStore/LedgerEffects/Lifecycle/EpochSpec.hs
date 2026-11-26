module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.EpochSpec (spec) where

import Cardano.Ledger.BaseTypes (epochInfoPure)
import Cardano.Ledger.Coin (CoinPerByte (..), CompactForm (..))
import Cardano.Ledger.Dijkstra.Core (ppCoinsPerUTxOByteL)
import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.Slot (epochInfoFirst)
import Cardano.Ledger.State
import qualified Data.Map.Strict as Map
import Lens.Micro ((%~), (&), (.~), (^.))
import Lens.Micro.Mtl (use)
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
import Test.Cardano.Ledger.Dijkstra.ImpTest (
  getCurSlotNo,
  getsNES,
  impGlobalsL,
  modifyNES,
  passEpoch,
  passTick,
 )
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Cross two ordinary epoch boundaries with live allocations and unchanged
-- protocol parameters. Epoch processing must preserve every recorded deposit.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-EPOCH - Epoch" $ do
  prop "DS-STATE-EPOCH-N01 - ordinaryEpochTransition ⇒ allocationsAfter = allocationsBefore" $
    forAll Lifecycle.populatedStore $ \fundingScenario -> do
      -- Submit only the funding transaction: its Deposit-backed outputs remain unspent.
      _ <- fundAccountingScenario fundingScenario
      forM_ [1 :: Int, 2] $ \_ -> do
        previousState <- getsNES id
        let previousAccountingState = previousState ^. nesEsL . esLStateL . lsAccountingStateL
            previousStore = liveOutputStore previousAccountingState
        Map.null (recordedAmounts $ liveOutputStore previousAccountingState) `shouldBe` False
        assertDepositTotal previousAccountingState
        passEpoch
        state <- getsNES id
        state ^. nesELL `shouldBe` succ (previousState ^. nesELL)
        state ^. nesEsL . curPParamsEpochStateL `shouldBe` previousState ^. nesEsL . curPParamsEpochStateL
        let accountingState = state ^. nesEsL . esLStateL . lsAccountingStateL
        liveOutputStore accountingState `shouldBe` previousStore
        assertDepositTotal accountingState

  -- A scheduled parameter update becomes effective at the real epoch boundary.
  -- Activation keeps the formula version and changes only its parameter;
  -- existing outputs retain the formula that determined their refund.
  -- The old interval excludes the boundary; the new one includes it.
  prop "DS-STATE-EPOCH-N02 - effectiveRate' = rate' ⇒ currentFormula' = V(rate') ∧ activatedAt' = firstSlot(epoch') ∧ allocations' = allocations ∧ totalDepositAmount' = totalDepositAmount" $
    forAll Lifecycle.populatedStore $ \fundingScenario -> do
      _ <- fundAccountingScenario fundingScenario
      forM_ [DepositFormulaV1, DepositFormulaV2] $ \version -> do
        parameters <- getsNES $ nesEsL . curPParamsEpochStateL
        let CoinPerByte (CompactCoin rate) = parameters ^. ppCoinsPerUTxOByteL
            nextRate = CoinPerByte $ CompactCoin $ rate + 1000
            nextParameters = parameters & ppCoinsPerUTxOByteL .~ nextRate
        passTick
        activationSlot <- getCurSlotNo
        modifyNES $
          (utxoStoreL %~ activateNewFormula activationSlot (version $ CoinPerByte $ CompactCoin rate))
            . (newEpochStateGovStateL . futurePParamsGovStateL .~ DefinitePParamsUpdate nextParameters)
        previousStore <- getsNES utxoStoreG

        passEpoch

        epoch <- getsNES nesELL
        globals <- use impGlobalsL
        accountingState <- getsNES $ nesEsL . esLStateL . lsAccountingStateL
        let store = liveOutputStore accountingState
            history = depositFormulaHistory store
            epochStart = epochInfoFirst (epochInfoPure globals) epoch
        getsNES (nesEsL . curPParamsEpochStateL) >>= (`shouldBe` nextParameters)
        currentFormula store `shouldBe` version nextRate
        map fromInclusive (periods history)
          `shouldBe` map fromInclusive (periods $ depositFormulaHistory previousStore) <> [Just epochStart]
        formulaAt (pred epochStart) history `shouldBe` currentFormula previousStore
        formulaAt epochStart history `shouldBe` version nextRate
        allocations store `shouldBe` allocations previousStore
        totalDepositAmount store `shouldBe` totalDepositAmount previousStore
        assertDepositTotal accountingState
{- FOURMOLU_ENABLE -}
