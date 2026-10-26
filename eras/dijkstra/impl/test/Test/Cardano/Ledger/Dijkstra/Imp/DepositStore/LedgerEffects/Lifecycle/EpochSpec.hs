module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.EpochSpec (spec) where

import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.State (depositStoreAllocations)
import qualified Data.Map.Strict as Map
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Lifecycle as Lifecycle
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  assertDepositTotal,
  liveOutputStore,
  recordedDepositStore,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (getsNES, passEpoch)
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Cross two ordinary epoch boundaries with live allocations and unchanged
-- protocol parameters. Epoch processing must preserve every recorded deposit.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-EPOCH - Epoch" $
  prop "DS-STATE-EPOCH-N01 - ordinaryEpochTransition ⇒ allocationsAfter = allocationsBefore" $
    forAll Lifecycle.populatedStore $ \fundingScenario -> do
      -- Submit only the funding transaction: its Store-backed outputs remain unspent.
      _ <- fundAccountingScenario fundingScenario
      forM_ [1 :: Int, 2] $ \_ -> do
        previousState <- getsNES id
        let previousUTxOState = previousState ^. nesEsL . esLStateL . lsUTxOStateL
            previousStore = liveOutputStore previousUTxOState
        Map.null (depositStoreAllocations $ recordedDepositStore previousUTxOState) `shouldBe` False
        assertDepositTotal previousUTxOState
        passEpoch
        state <- getsNES id
        state ^. nesELL `shouldBe` succ (previousState ^. nesELL)
        state ^. nesEsL . curPParamsEpochStateL `shouldBe` previousState ^. nesEsL . curPParamsEpochStateL
        let utxoState = state ^. nesEsL . esLStateL . lsUTxOStateL
        liveOutputStore utxoState `shouldBe` previousStore
        assertDepositTotal utxoState
{- FOURMOLU_ENABLE -}
