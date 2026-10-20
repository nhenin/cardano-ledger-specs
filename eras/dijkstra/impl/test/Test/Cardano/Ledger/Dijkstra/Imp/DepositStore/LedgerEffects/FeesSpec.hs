{-# LANGUAGE NamedFieldPuns #-}

-- | The accepted execution path selects the fee credit. Collateral deposit
-- surplus reaches fees only on phase-2 failure; the treasury remains unchanged.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.FeesSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (utxosDepositStore, utxosFees, utxosUtxo)
import Cardano.Ledger.State (DepositStore (..), UTxO (..), treasuryL)
import Cardano.Ledger.Val (Val ((<->)))
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  createdOrdinaryOutputs,
  ordinarySpendingInputs,
  readLedger,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (getsNES)
import Test.Cardano.Ledger.Imp.Common (shouldBe)

-- | Generated allocations, equal deposits, surplus releases and absent returns
-- exercise both real script outcomes. Ordinary inputs and outputs are implicit,
-- so only collateral can change the Store. Preserve unrelated UTxOs and records.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-FEES - Fees" $
  prop "DS-STATE-FEES-P01 - Δfees = (if phase2Valid then txFee else collateralCoinFee + releasedSurplus) ∧ Δtreasury = 0" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ scenarios $ \scenario -> do
        Fixture{signedTx, previousUTxOState, collateralInputs, inputCoins, releasedDeposits, returnDeposit} <- Collateral.buildAndSign scenario
        previousTreasury <- getsNES treasuryL
        let previousStore = utxosDepositStore previousUTxOState
            previousOutputs = unUTxO $ utxosUtxo previousUTxOState
            collateralReturn = signedTx ^. bodyTxL . collateralReturnTxBodyL
            returnCoins = foldMap (^. coinTxOutL) collateralReturn
            additionalDeposit = max (Coin 0) (returnDeposit <-> releasedDeposits)
            releasedSurplus = max (Coin 0) (releasedDeposits <-> returnDeposit)
            collateralCoinFee = inputCoins <-> returnCoins <-> additionalDeposit
            returnInput = txInAt (length $ signedTx ^. bodyTxL . outputsTxBodyL) signedTx
        submitTx signedTx >>= isAccepted
        utxoState <- readLedger
        treasury <- getsNES treasuryL
        treasury `shouldBe` previousTreasury
        case signedTx ^. isPhase2ValidTxL of
          Phase2Valid -> do
            -- Successful scripts execute ordinary effects and leave collateral untouched.
            utxosFees utxoState `shouldBe` utxosFees previousUTxOState <> (signedTx ^. bodyTxL . feeTxBodyL)
            utxosDepositStore utxoState `shouldBe` previousStore
            unUTxO (utxosUtxo utxoState)
              `shouldBe` createdOrdinaryOutputs signedTx <> Map.withoutKeys previousOutputs (ordinarySpendingInputs signedTx)
          Phase2Invalid -> do
            -- Failure consumes only collateral. External deposit surplus goes to fees.
            utxosFees utxoState `shouldBe` utxosFees previousUTxOState <> collateralCoinFee <> releasedSurplus
            depositStoreBalance (utxosDepositStore utxoState)
              `shouldBe` (depositStoreBalance previousStore <> returnDeposit) <-> releasedDeposits
            depositStoreAllocations (utxosDepositStore utxoState)
              `shouldBe` (case collateralReturn of
                SJust (StoreBackedTxOut _) -> Map.singleton returnInput returnDeposit
                _ -> Map.empty) <> Map.withoutKeys (depositStoreAllocations previousStore) collateralInputs
            unUTxO (utxosUtxo utxoState)
              `shouldBe` foldMap (Map.singleton returnInput) collateralReturn <> Map.withoutKeys previousOutputs collateralInputs
{- FOURMOLU_ENABLE -}
