module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.EpochSpec (spec) where

import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.State (depositStoreAllocations, depositStoreBalance)
import Cardano.Ledger.Val (Val ((<->)))
import qualified Data.Map.Strict as Map
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Lifecycle as Lifecycle
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  addStoreSurplus,
  fundAccountingScenario,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (getsNES, passEpoch)
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Cross an ordinary epoch boundary with live allocations, unchanged protocol
-- parameters and zero or positive Store surplus. Observe the actual Store fields.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-EPOCH - Epoch" $
  prop "DS-STATE-EPOCH-N01 - ordinaryEpochTransition ⇒ (storeBalanceAfter, allocationsAfter) = (storeBalanceBefore, allocationsBefore)" $
    forAll Lifecycle.populatedStore $ \(fundingScenario, surplus) -> do
      -- Submit only the funding transaction: its Store-backed outputs remain unspent.
      _ <- fundAccountingScenario fundingScenario
      forM_ [mempty, surplus] $ \addedSurplus -> do
        addStoreSurplus addedSurplus
        previousState <- getsNES id
        let previousStore = previousState ^. nesEsL . esLStateL . lsUTxOStateL . utxosDepositStoreL
        Map.null (depositStoreAllocations previousStore) `shouldBe` False
        depositStoreBalance previousStore <-> foldMap id (depositStoreAllocations previousStore)
          `shouldBe` addedSurplus
        passEpoch
        state <- getsNES id
        state ^. nesELL `shouldBe` succ (previousState ^. nesELL)
        state ^. nesEsL . curPParamsEpochStateL `shouldBe` previousState ^. nesEsL . curPParamsEpochStateL
        state ^. nesEsL . esLStateL . lsUTxOStateL . utxosDepositStoreL `shouldBe` previousStore
{- FOURMOLU_ENABLE -}
