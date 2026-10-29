{-# LANGUAGE NamedFieldPuns #-}

-- | Acceptance selects one set of consumed inputs and one set of created outputs.
-- Compare the complete resulting UTxO, including every preserved source, against
-- the signed transaction's ordinary or collateral transition.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.UTxOSpec (spec) where

import Cardano.Ledger.Dijkstra.Core
import qualified Data.Map.Strict as Map
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects as Effects
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.UTxO as InputRoles
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store as Store
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (isAccepted, submitTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  createdOrdinaryOutputs,
  ordinarySpendingInputs,
  readLedger,
 )
import Test.Cardano.Ledger.Imp.Common (shouldBe)

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-UTXO - UTxO" $ do
  describe "Ordinary success: consume and create outputs across TopTx and its SubTxs" $ do
    -- Standalone and multi-child transactions allocate, release or replace Store
    -- deposits. Output references use their own body's identifier and index;
    -- settlement ADA is already part of the signed output, not added again.
    prop "DS-STATE-UTXO-N01 - accepted ∧ phase2Valid ⇒ utxoAfter = (utxoBefore without ordinaryInputs) ∪ ordinaryOutputs" $
      forAll Effects.ordinaryScenarios $ \scenarios ->
        forM_ scenarios $ \scenario -> do
          signedTx <- Effects.buildAndSignOrdinary scenario
          previousUTxOState <- readLedger
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          Store.outputs utxoState
            `shouldBe` createdOrdinaryOutputs signedTx
              <> Map.withoutKeys (Store.outputs previousUTxOState) (ordinarySpendingInputs signedTx)

    -- Actual successful scripts activate the ordinary path even when collateral
    -- proposes Store allocations or releases. Its sources remain unspent and its
    -- return is not created; unrelated outputs retain their exact contents.
    prop "DS-STATE-UTXO-N02 - accepted ∧ phase2Valid ⇒ collateralOnlyInputs survive ∧ collateralReturn is not created" $
      forAll Collateral.fundingScenarios $ \scenarios ->
        forM_ (filter ((== Phase2Valid) . Collateral.phase2) scenarios) $ \scenario -> do
          Fixture{signedTx, previousUTxOState} <- Collateral.buildAndSign scenario >>= InputRoles.withReferenceOnlyInput
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          Store.outputs utxoState
            `shouldBe` createdOrdinaryOutputs signedTx
              <> Map.withoutKeys (Store.outputs previousUTxOState) (ordinarySpendingInputs signedTx)

  describe "Phase-2 failure: consume only collateral and create only its return" $ do
    -- Real failing scripts cover absent, implicit and Store-backed returns.
    -- Ordinary inputs survive, ordinary outputs are not created, and every
    -- unrelated output is preserved by equality of the complete UTxO map.
    prop "DS-STATE-UTXO-N03 - accepted ∧ phase2Invalid ⇒ utxoAfter = (utxoBefore without collateralInputs) ∪ collateralReturn" $
      forAll Collateral.fundingScenarios $ \scenarios ->
        forM_ (filter ((== Phase2Invalid) . Collateral.phase2) scenarios) $ \scenario -> do
          Fixture{signedTx, previousUTxOState, collateralInputs} <- Collateral.buildAndSign scenario >>= InputRoles.withReferenceOnlyInput
          let collateralReturn = signedTx ^. bodyTxL . collateralReturnTxBodyL
              returnInput = txInAt (length $ signedTx ^. bodyTxL . outputsTxBodyL) signedTx
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          Store.outputs utxoState
            `shouldBe` foldMap (Map.singleton returnInput) collateralReturn
              <> Map.withoutKeys (Store.outputs previousUTxOState) collateralInputs

    -- A failing TopTx script suppresses all ordinary effects, including several
    -- children with real Store allocations and releases. This does not assume
    -- propagation of child-script failures, which is a separate upstream concern.
    prop "DS-STATE-UTXO-N04 - accepted ∧ phase2Invalid ∧ |subTxs| > 1 ⇒ utxoAfter = (utxoBefore without collateralInputs) ∪ collateralReturn" $
      forAll Effects.ordinaryScenarios $ \scenarios ->
        forM_ (filter ((> 1) . length . Accounting.subOperations) scenarios) $ \scenario -> do
          signedTx <- Effects.buildAndSignOrdinaryPhase2Invalid scenario
          previousUTxOState <- readLedger
          let collateralInputs = signedTx ^. bodyTxL . collateralInputsTxBodyL
              collateralReturn = signedTx ^. bodyTxL . collateralReturnTxBodyL
              returnInput = txInAt (length $ signedTx ^. bodyTxL . outputsTxBodyL) signedTx
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          Store.outputs utxoState
            `shouldBe` foldMap (Map.singleton returnInput) collateralReturn
              <> Map.withoutKeys (Store.outputs previousUTxOState) collateralInputs

  describe "Shared input: the selected path consumes it exactly once" $
    -- A real Store-backed source serves both roles. Its ordinary settlement is
    -- balanced before signing; the script outcome decides which outputs exist.
    -- A separate reference-only Store output survives both outcomes.
    prop "DS-STATE-UTXO-N05 - accepted ∧ ordinaryInputs ∩ collateralInputs ≠ ∅ ⇒ utxoAfter = (utxoBefore without selectedInputs) ∪ selectedOutputs" $
      forAll (Collateral.scenarios [Collateral.StoreBacked] (Just Collateral.StoreBacked) Phase2Invalid) $ \generated ->
        forM_ [Phase2Valid, Phase2Invalid] $ \phase2 -> do
          Fixture{signedTx, previousUTxOState, collateralInputs} <-
            Collateral.buildAndSign generated{Collateral.phase2 = phase2}
              >>= InputRoles.withSharedOrdinaryInput
              >>= InputRoles.withReferenceOnlyInput
          submitTx signedTx >>= isAccepted
          utxoState <- readLedger
          let previousOutputs = Store.outputs previousUTxOState
          case phase2 of
            Phase2Valid ->
              Store.outputs utxoState
                `shouldBe` createdOrdinaryOutputs signedTx <> Map.withoutKeys previousOutputs (ordinarySpendingInputs signedTx)
            Phase2Invalid -> do
              let collateralReturn = signedTx ^. bodyTxL . collateralReturnTxBodyL
                  returnInput = txInAt (length $ signedTx ^. bodyTxL . outputsTxBodyL) signedTx
              Store.outputs utxoState
                `shouldBe` foldMap (Map.singleton returnInput) collateralReturn <> Map.withoutKeys previousOutputs collateralInputs
{- FOURMOLU_ENABLE -}
