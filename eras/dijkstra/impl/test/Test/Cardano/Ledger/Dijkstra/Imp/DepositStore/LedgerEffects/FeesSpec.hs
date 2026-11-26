{-# LANGUAGE NamedFieldPuns #-}

-- | Ordinary success credits the declared transaction fee. Accepted phase-2
-- failure credits the collateral fee and any released Store deposit surplus.
-- Neither path redirects these amounts to the treasury.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.FeesSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (asFees)
import Cardano.Ledger.State (treasuryL)
import Cardano.Ledger.Val (Val ((<->)))
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects as Effects
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (readAccountingState)
import Test.Cardano.Ledger.Dijkstra.ImpTest (getsNES)
import Test.Cardano.Ledger.Imp.Common (shouldBe)

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-FEES - Fees" $ do
  -- Allocation, release and zero-net batches use both local and delegated child
  -- declarations. Successful scripts additionally cover inactive collateral
  -- proposals: neither ordinary deposits nor collateral alter the declared fee.
  prop "DS-STATE-FEES-P01 - accepted ∧ phase2Valid ⇒ Δfees = txFee ∧ Δtreasury = 0" $
    forAll ((,) <$> Effects.ordinaryScenarios <*> Collateral.fundingScenarios) $ \(ordinary, collateral) ->
      forM_
        ( [ buildAndSign scenario
          | scenario <- ordinary
          , buildAndSign <- [Effects.buildAndSignOrdinary, Effects.buildAndSignDelegatedOrdinary]
          ]
          <> [ signedTx <$> Collateral.buildAndSign scenario
             | scenario <- collateral
             , Collateral.phase2 scenario == Phase2Valid
             ]
        ) $ \buildAndSign -> do
          tx <- buildAndSign
          previousAccountingState <- readAccountingState
          previousTreasury <- getsNES treasuryL
          submitTx tx >>= isAccepted
          accountingState <- readAccountingState
          treasury <- getsNES treasuryL
          asFees accountingState `shouldBe` asFees previousAccountingState <> (tx ^. bodyTxL . feeTxBodyL)
          treasury `shouldBe` previousTreasury

  -- Collateral application ADA first funds its return and any extra deposit.
  -- Remaining application ADA plus unused recorded deposits go to fees. The
  -- deposit release uses its recorded amount even after the byte price changes.
  prop "DS-STATE-FEES-P02 - accepted ∧ phase2Invalid ⇒ Δfees = collateralCoinFee + releasedSurplus ∧ Δtreasury = 0" $
    forAll Collateral.fundingScenarios $ \scenarios ->
      forM_ (filter ((== Phase2Invalid) . Collateral.phase2) scenarios) $ \scenario -> do
        Fixture{signedTx, previousAccountingState, inputCoins, releasedDeposits, returnDeposit} <- Collateral.buildAndSign scenario
        previousTreasury <- getsNES treasuryL
        let returnCoins = foldMap (^. coinTxOutL) (signedTx ^. bodyTxL . collateralReturnTxBodyL)
            additionalDeposit = max (Coin 0) (returnDeposit <-> releasedDeposits)
            releasedSurplus = max (Coin 0) (releasedDeposits <-> returnDeposit)
            collateralCoinFee = inputCoins <-> returnCoins <-> additionalDeposit
        submitTx signedTx >>= isAccepted
        accountingState <- readAccountingState
        treasury <- getsNES treasuryL
        asFees accountingState `shouldBe` asFees previousAccountingState <> collateralCoinFee <> releasedSurplus
        treasury `shouldBe` previousTreasury
{- FOURMOLU_ENABLE -}
