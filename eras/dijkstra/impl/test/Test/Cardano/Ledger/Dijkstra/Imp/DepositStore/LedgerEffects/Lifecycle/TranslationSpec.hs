{-# LANGUAGE TypeApplications #-}

-- | Translation preserves existing assets and introduces no retroactive Store
-- obligation. The expected output fields come directly from the Conway state.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.TranslationSpec (spec) where

import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
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
  outputs,
  recordedAmounts,
 )

{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STATE-TRANSLATION - Translation" $
  prop "DS-STATE-TRANSLATION-N01 - Conway → Dijkstra ⇒ (outputsAfter, externalDepositsAfter, existingPotsAfter) = (implicit(outputsBefore), zero, existingPotsBefore)" $
    forAll Lifecycle.conwayStates $ \states ->
      forM_ states $ \previousState -> do
        let translatedState = translateEra' @DijkstraEra exampleDijkstraGenesis previousState
            previousAccountingState = previousState ^. nesEsL . esLStateL . lsAccountingStateL
            accountingState = translatedState ^. nesEsL . esLStateL . lsAccountingStateL
            previousOutputs = outputs previousAccountingState
            translatedOutputs = outputs accountingState
        Map.keysSet translatedOutputs `shouldBe` Map.keysSet previousOutputs
        forM_ (Map.toList previousOutputs) $ \(input, previousOutput) ->
          case (previousOutput, Map.lookup input translatedOutputs) of
            (LegacyTxOut previousImplicit, Just output@(LegacyTxOut implicit)) -> do
              output ^. addrTxOutL `shouldBe` previousOutput ^. addrTxOutL
              implicit ^. valueTxOutL `shouldBe` previousImplicit ^. valueTxOutL
              -- Compare datum semantics and script identity across their era types.
              Aeson.toJSON (output ^. datumTxOutL) `shouldBe` Aeson.toJSON (previousOutput ^. datumTxOutL)
              fmap hashScript (output ^. referenceScriptTxOutL)
                `shouldBe` fmap hashScript (previousOutput ^. referenceScriptTxOutL)
            _ -> expectationFailure "Every translated Conway output must remain present and implicit"
        recordedAmounts (liveOutputStore accountingState) `shouldBe` Map.empty
        -- Translation activates the effective Dijkstra rate for future outputs;
        -- imported legacy outputs retain their zero-deposit historical metadata.
        currentCalculation (liveOutputStore accountingState)
          `shouldBe` DepositCalculationV1 (translatedState ^. nesEsL . curPParamsEpochStateL . ppCoinsPerUTxOByteL)
        let entries = allocations $ liveOutputStore accountingState
        IndexedUTxOs.inputIds entries `shouldBe` Map.keysSet translatedOutputs
        forM_ (IndexedUTxOs.unspentOutputs entries) $ \entry -> case Unspent.toTxOut entry of
          LegacyTxOut _ -> do
            -- Imported legacy outputs use explicit compatibility metadata; their
            -- historical accepted size cannot be recovered from the Conway state.
            sizedOutput entry `shouldBe` Binary.mkSized (eraProtVerLow @DijkstraEra) (Unspent.toTxOut entry)
            depositCalculation entry `shouldBe` DepositCalculationV1 (CoinPerByte $ CompactCoin 0)
          NewTxOut _ -> expectationFailure "Every translated Conway output must remain a LegacyTxOut"
        toCoin (totalDepositAmount $ liveOutputStore accountingState)
          `shouldBe` expectedDepositTotal (liveOutputStore accountingState)
        -- Check each actual monetary pot, so a swapped or reset pot is visible.
        translatedState ^. treasuryL `shouldBe` previousState ^. treasuryL
        translatedState ^. reservesL `shouldBe` previousState ^. reservesL
        asDeposited accountingState `shouldBe` asDeposited previousAccountingState
        asFees accountingState `shouldBe` asFees previousAccountingState
        asDonation accountingState `shouldBe` asDonation previousAccountingState
        let previousAccounts = previousState ^. nesEsL . esLStateL . lsCertStateL . certDStateL . accountsL . accountsMapL
            accounts = translatedState ^. nesEsL . esLStateL . lsCertStateL . certDStateL . accountsL . accountsMapL
        Map.map (\account -> (account ^. balanceAccountStateL, account ^. depositAccountStateL)) accounts
          `shouldBe` Map.map (\account -> (account ^. balanceAccountStateL, account ^. depositAccountStateL)) previousAccounts
{- FOURMOLU_ENABLE -}
