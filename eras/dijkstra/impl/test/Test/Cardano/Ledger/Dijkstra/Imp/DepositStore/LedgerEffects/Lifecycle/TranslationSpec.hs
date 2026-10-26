{-# LANGUAGE TypeApplications #-}

-- | Translation preserves existing assets and introduces no retroactive Store
-- obligation. The expected output fields come directly from the Conway state.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.TranslationSpec (spec) where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.State
import qualified Data.Aeson as Aeson
import qualified Data.Map.Strict as Map
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (
  Spec,
  describe,
  expectationFailure,
  forAll,
  forM_,
  prop,
  shouldBe,
 )
import Test.Cardano.Ledger.Dijkstra.Examples (exampleDijkstraGenesis)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Lifecycle as Lifecycle
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  expectedDepositTotal,
  liveOutputStore,
  recordedDepositStore,
 )

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-TRANSLATION - Translation" $
  prop "DS-STATE-TRANSLATION-N01 - Conway → Dijkstra ⇒ (outputsAfter, externalDepositsAfter, existingPotsAfter) = (implicit(outputsBefore), zero, existingPotsBefore)" $
    forAll Lifecycle.conwayStates $ \states ->
      forM_ states $ \previousState -> do
        let translatedState = translateEra' @DijkstraEra exampleDijkstraGenesis previousState
            previousUTxOState = previousState ^. nesEsL . esLStateL . lsUTxOStateL
            utxoState = translatedState ^. nesEsL . esLStateL . lsUTxOStateL
            previousOutputs = unUTxO $ utxosUtxo previousUTxOState
            outputs = unUTxO $ utxosUtxo utxoState
        Map.keysSet outputs `shouldBe` Map.keysSet previousOutputs
        forM_ (Map.toList previousOutputs) $ \(input, previousOutput) ->
          case (previousOutput, Map.lookup input outputs) of
            (ImplicitDepositTxOut previousImplicit, Just output@(ImplicitDepositTxOut implicit)) -> do
              output ^. addrTxOutL `shouldBe` previousOutput ^. addrTxOutL
              implicit ^. valueTxOutL `shouldBe` previousImplicit ^. valueTxOutL
              -- Compare datum semantics and script identity across their era types.
              Aeson.toJSON (output ^. datumTxOutL) `shouldBe` Aeson.toJSON (previousOutput ^. datumTxOutL)
              fmap hashScript (output ^. referenceScriptTxOutL)
                `shouldBe` fmap hashScript (previousOutput ^. referenceScriptTxOutL)
            _ -> expectationFailure "Every translated Conway output must remain present and implicit"
        recordedDepositStore utxoState `shouldBe` DepositStore Map.empty
        let entries = unAllocations $ allocations $ liveOutputStore utxoState
        Map.keysSet entries `shouldBe` Map.keysSet outputs
        forM_ (Map.elems entries) $ \entry -> do
          allocationCalculation entry `shouldBe` Nothing
          fmap (const ()) (allocationSizedOutput entry) `shouldBe` Nothing
        unInMemoryOutputDepositAmount (totalDepositAmount $ liveOutputStore utxoState)
          `shouldBe` expectedDepositTotal (liveOutputStore utxoState)
        -- Check each actual monetary pot, so a swapped or reset pot is visible.
        translatedState ^. treasuryL `shouldBe` previousState ^. treasuryL
        translatedState ^. reservesL `shouldBe` previousState ^. reservesL
        utxosDeposited utxoState `shouldBe` utxosDeposited previousUTxOState
        utxosFees utxoState `shouldBe` utxosFees previousUTxOState
        utxosDonation utxoState `shouldBe` utxosDonation previousUTxOState
        let previousAccounts = previousState ^. nesEsL . esLStateL . lsCertStateL . certDStateL . accountsL . accountsMapL
            accounts = translatedState ^. nesEsL . esLStateL . lsCertStateL . certDStateL . accountsL . accountsMapL
        Map.map (\account -> (account ^. balanceAccountStateL, account ^. depositAccountStateL)) accounts
          `shouldBe` Map.map (\account -> (account ^. balanceAccountStateL, account ^. depositAccountStateL)) previousAccounts
{- FOURMOLU_ENABLE -}
