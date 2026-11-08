{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Test.Cardano.Ledger.Api.Transition.InitialFundsSpec (spec) where

import Cardano.Ledger.BaseTypes (Network (..), SlotNo (..), StrictMaybe (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Shelley (ShelleyEra)
import Cardano.Ledger.Shelley.Genesis (
  InjectionData (..),
  InjectionError (..),
  ShelleyExtraConfig (..),
  ShelleyGenesis (..),
  initialFundsPseudoTxIn,
 )
import Cardano.Ledger.Shelley.LedgerState (NewEpochState)
import Cardano.Ledger.Shelley.Transition (EraTransition (..), registerInitialFunds, tcInitialFundsL)
import Cardano.Ledger.Slot (EpochSize (..))
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
import Cardano.Ledger.Val (inject)
import Data.Default (def)
import qualified Data.ListMap as ListMap
import qualified Data.Map.Strict as Map
import Data.Maybe (fromJust)
import Lens.Micro
import qualified System.FS.Sim.MockFS as MockFS
import System.FS.Sim.STM (simHasFS')
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()
import Test.Cardano.Ledger.Shelley.Arbitrary ()

spec :: Spec
spec = describe "Initial funds" $ do
  initialFundsSpec @ShelleyEra
  initialFundsSpec @DijkstraEra

  describe "Dijkstra historical deposits"
    $ prop
      "initial funds use AtStoreMigration and preserve accepted entries with nonzero history"
    $ forAll ((,) <$> resize 0 (arbitrary @(TransitionConfig DijkstraEra)) <*> choose (1, 1000))
    $ \(transitionConfig, epochLength) -> do
      let stakingCredential = KeyHashObj $ mkKeyHash @Staking 1
          existingAddress = mkAddr (mkKeyHash @Payment 1) stakingCredential
          fundedAddress = mkAddr (mkKeyHash @Payment 2) stakingCredential
          existingInput = initialFundsPseudoTxIn existingAddress
          fundedInput = initialFundsPseudoTxIn fundedAddress
          existingOutput =
            mkBasicTxOutWithStoreBackedDeposit @DijkstraEra
              existingAddress
              (ApplicationAssets . inject $ Coin 4)
          existingAllocation =
            Unspent
              { Unspent.output = existingOutput
              , allocatedAt = AtSlot (SlotNo 1234)
              }
          initialFunds = ListMap.ListMap [(fundedAddress, Coin 7)]
          fundingConfig =
            transitionConfig
              & tcShelleyGenesisL %~ \genesis ->
                genesis
                  { sgNetworkId = Testnet
                  , sgInitialFunds = initialFunds
                  , sgExtraConfig = SNothing
                  , -- Full injection computes committee key ages in epochs.
                    sgEpochLength = EpochSize epochLength
                  }
          history =
            fromJust $
              appendFormula
                (SlotNo 1000)
                (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7)
                (mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3)
          previousStore = Store.mkUTxOStore history $ IndexedUTxOs.singleton existingInput existingAllocation
          previousState =
            def @(NewEpochState DijkstraEra)
              & utxoStoreL .~ previousStore
              & reservesL .~ Coin 100
              & instantStakeL . instantStakeCredentialsL .~ Map.singleton stakingCredential (CompactCoin 99)
      fs <- simHasFS' MockFS.empty
      fundedState <- registerInitialFunds fs fundingConfig previousState
      let fundedStore = fundedState ^. utxoStoreG
      IndexedUTxOs.lookupUTxO existingInput (Store.allocations fundedStore)
        `shouldBe` Just existingAllocation
      (allocatedAt <$> IndexedUTxOs.lookupUTxO fundedInput (Store.allocations fundedStore))
        `shouldBe` Just AtStoreMigration
      Store.totalDepositAmount fundedStore `shouldBe` Store.totalDepositAmount previousStore
      Store.depositFormulaHistory fundedStore `shouldBe` Store.depositFormulaHistory previousStore
      fundedState ^. reservesL `shouldBe` Coin 93
      fundedState
        ^. instantStakeG
          . instantStakeCredentialsL
          `shouldBe` Map.singleton stakingCredential (CompactCoin 11)
      -- Re-entering the complete injection path must not migrate the Store again.
      initializedState <-
        injectIntoTestState fs (fundingConfig & tcInitialFundsL .~ mempty) fundedState
      initializedState ^. utxoStoreG `shouldBe` fundedStore

initialFundsSpec ::
  forall era.
  (EraTransition era, Arbitrary (TransitionConfig era)) =>
  Spec
initialFundsSpec = describe (eraName @era) $ do
  let stakingCredential = KeyHashObj $ mkKeyHash @Staking 1
      existingAddress = mkAddr (mkKeyHash @Payment 1) stakingCredential
      fundedAddress = mkAddr (mkKeyHash @Payment 2) stakingCredential
      existingInput = initialFundsPseudoTxIn existingAddress
      fundedInput = initialFundsPseudoTxIn fundedAddress
      history = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
  prop "disjoint initial funds preserve existing outputs and reconstruct stake from all outputs" $
    forAll (resize 0 $ arbitrary @(TransitionConfig era)) $ \transitionConfig -> do
      let existingOutput = mkCoinTxOut @era existingAddress (Coin 4)
          previousStore =
            Store.mkUTxOStore history . IndexedUTxOs.fromLegacyTxOuts $
              Map.singleton existingInput existingOutput
          previousState =
            def @(NewEpochState era)
              & utxoStoreL .~ previousStore
              & reservesL .~ Coin 100
              & treasuryL .~ Coin 23
              & instantStakeL . instantStakeCredentialsL .~ Map.singleton stakingCredential (CompactCoin 99)
          initialFunds = ListMap.ListMap [(fundedAddress, Coin 7)]
          fundingConfig =
            transitionConfig
              & tcShelleyGenesisL %~ \genesis ->
                genesis {sgNetworkId = Testnet, sgInitialFunds = initialFunds, sgExtraConfig = SNothing}
      fs <- simHasFS' MockFS.empty
      fundedState <- registerInitialFunds fs fundingConfig previousState
      let fundedStore = fundedState ^. utxoStoreG
      IndexedUTxOs.mapTxOuts id (Store.allocations fundedStore)
        `shouldBe` ( Map.fromList
                       [ (existingInput, LegacyTxOut existingOutput)
                       , (fundedInput, LegacyTxOut $ mkCoinTxOut @era fundedAddress (Coin 7))
                       ]
                   )
      Store.totalDepositAmount fundedStore `shouldBe` Store.totalDepositAmount previousStore
      (allocatedAt <$> IndexedUTxOs.lookupUTxO fundedInput (Store.allocations fundedStore))
        `shouldBe` Just AtStoreMigration
      fundedState ^. reservesL `shouldBe` Coin 93
      fundedState ^. treasuryL `shouldBe` Coin 23
      fundedState
        ^. instantStakeG
          . instantStakeCredentialsL
          `shouldBe` Map.singleton stakingCredential (CompactCoin 11)

  prop "a repeated imported address keeps its last output while reserves pay both amounts" $
    forAll (resize 0 $ arbitrary @(TransitionConfig era)) $ \transitionConfig -> do
      let initialFunds = ListMap.ListMap [(fundedAddress, Coin 3), (fundedAddress, Coin 7)]
          fundingConfig =
            transitionConfig
              & tcShelleyGenesisL %~ \genesis ->
                genesis {sgNetworkId = Testnet, sgInitialFunds = initialFunds, sgExtraConfig = SNothing}
          previousState =
            def @(NewEpochState era)
              & utxoStoreL .~ Store.mkEmptyUTxOStore history
              & reservesL .~ Coin 100
      fs <- simHasFS' MockFS.empty
      fundedState <- registerInitialFunds fs fundingConfig previousState
      IndexedUTxOs.mapTxOuts id (Store.allocations $ fundedState ^. utxoStoreG)
        `shouldBe` Map.singleton fundedInput (LegacyTxOut $ mkCoinTxOut @era fundedAddress (Coin 7))
      fundedState ^. reservesL `shouldBe` Coin 90
      fundedState
        ^. instantStakeG
          . instantStakeCredentialsL
          `shouldBe` Map.singleton stakingCredential (CompactCoin 7)

  prop "an already allocated input rejects initial funds with the existing collision error" $
    forAll (resize 0 $ arbitrary @(TransitionConfig era)) $ \transitionConfig -> do
      let initialFunds = ListMap.ListMap [(existingAddress, Coin 7)]
          fundingConfig =
            transitionConfig
              & tcShelleyGenesisL %~ \genesis ->
                genesis {sgNetworkId = Testnet, sgInitialFunds = initialFunds, sgExtraConfig = SNothing}
          previousStore =
            Store.mkUTxOStore history
              . IndexedUTxOs.fromLegacyTxOuts
              . Map.singleton existingInput
              $ mkCoinTxOut @era existingAddress (Coin 4)
          previousState = def @(NewEpochState era) & utxoStoreL .~ previousStore
      fs <- simHasFS' MockFS.empty
      registerInitialFunds fs fundingConfig previousState
        `shouldThrow` errorCall ("initial fund part of UTxO: " <> show existingInput)

  prop "Mainnet rejects initial funds before resolving conflicting injection sources" $
    forAll (resize 0 $ arbitrary @(TransitionConfig era)) $ \transitionConfig -> do
      let initialFunds = ListMap.ListMap [(fundedAddress, Coin 7)]
          mainnetConfig =
            transitionConfig
              & tcShelleyGenesisL %~ \genesis ->
                genesis
                  { sgNetworkId = Mainnet
                  , sgInitialFunds = initialFunds
                  , sgExtraConfig = SJust $ def {secInitialFunds = EmbeddedInjection initialFunds}
                  }
      fs <- simHasFS' MockFS.empty
      registerInitialFunds fs mainnetConfig (def @(NewEpochState era))
        `shouldThrow` (== InjectionNotAllowedOnMainnet)
