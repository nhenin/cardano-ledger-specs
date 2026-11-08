{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Test.Cardano.Ledger.Api.UnspentSpec (spec) where

import Cardano.Ledger.Allegra.Scripts (AllegraEraScript (mkTimeStart))
import Cardano.Ledger.Babbage.TxOut (datumBabbageTxOutL, referenceScriptBabbageTxOutL)
import Cardano.Ledger.BaseTypes (SlotNo (..), StrictMaybe (..), TxIx (..))
import Cardano.Ledger.Binary (Sized (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Credential (Credential (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Unspent as DijkstraUnspent
import Cardano.Ledger.Mary.Value (
  AssetName (..),
  MaryValue (..),
  MultiAsset (..),
  multiAssetFromList,
 )
import Cardano.Ledger.Plutus.Data (Datum (..), hashBinaryData, makeBinaryData)
import Cardano.Ledger.Plutus.Language (SLanguage (SPlutusV3))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store as Store
import qualified Cardano.Ledger.State.Accounting.UTxOs.Store.Internals as StoreInternals
import Cardano.Ledger.State.Accounting.UTxOs.Unspent (
  AllocatedAt (..),
  Unspent (Unspent, allocatedAt),
 )
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Cardano.Ledger.Val as Val
import qualified Data.ByteString.Short as SBS
import Data.Default (def)
import Data.Int (Int64)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromJust)
import qualified Data.Set as Set
import Lens.Micro ((&), (.~))
import Test.Cardano.Ledger.Common hiding (output)
import Test.Cardano.Ledger.Core.KeyPair (mkAddr, mkKeyHash)
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()
import Test.Cardano.Ledger.Plutus.Examples (alwaysSucceedsNoDatum)

spec :: Spec
spec = describe "Unspent deposit formula" $ do
  let address = mkAddr (mkKeyHash @Payment 1) (KeyHashObj $ mkKeyHash @Staking 1)
      allocationSlot = SlotNo 100
      pricing = DepositFormulaV1 $ CoinPerByte $ CompactCoin 4310
      history = mkDepositFormulaHistory pricing

  it "no dated changes ⇒ the explicit baseline prices every allocation" $ do
    let output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 2_000_000)
    initialFormula history `shouldBe` pricing
    latestFormula history `shouldBe` pricing
    formulaAt allocationSlot history `shouldBe` pricing
    forM_ [AtStoreMigration, AtSlot (SlotNo 0), AtSlot allocationSlot] $ \origin -> do
      let entry = Unspent {Unspent.output = output, allocatedAt = origin}
      DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin 1_077_500)
      DijkstraUnspent.computeApplicationAssets history entry
        `shouldBe` (ApplicationAssets $ Val.inject $ Coin 922_500)
      Unspent.computeExternalDeposit history entry `shouldBe` Coin 0
      Unspent.toTxOut entry `shouldBe` output

  it "zero-priced baseline ⇒ zero reserve and unchanged application assets" $ do
    let zeroPricedHistory = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 0
        legacy = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 2_000_000)
        new =
          mkBasicTxOutWithStoreBackedDeposit @DijkstraEra
            address
            (ApplicationAssets $ Val.inject $ Coin 2_000_000)
    forM_ [legacy, new] $ \output -> do
      let entry = Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
      DijkstraUnspent.computeDeposit zeroPricedHistory entry `shouldBe` DepositAmount (Coin 0)
      DijkstraUnspent.computeApplicationAssets zeroPricedHistory entry
        `shouldBe` (ApplicationAssets $ Val.inject $ Coin 2_000_000)
      Unspent.computeExternalDeposit zeroPricedHistory entry `shouldBe` Coin 0

  describe "Allocation price = p × (base + perAsset × N + datumBytes + scriptBytes)" $ do
    prop "N = 2 regardless of quantities, name lengths or policy grouping; V1 and V2 price D and R" $ \policy ->
      forAll (arbitrary `suchThat` (/= policy)) $ \otherPolicy ->
        forAll (chooseInteger (1, 1_000_000)) $ \quantity -> do
          inline <- expectRight $ makeBinaryData @DijkstraEra $ SBS.pack [0x43, 1, 2, 3]
          let nativeScript = fromNativeScript @DijkstraEra $ mkTimeStart @DijkstraEra (SlotNo 0)
              -- The inline datum is four payload bytes; the native script [4,0] takes three.
              datumCases = [(NoDatum, 0), (DatumHash $ hashBinaryData inline, 32), (Datum inline, 4)]
          forM_
            [ [(policy, AssetName "A", quantity), (policy, AssetName "B", 1)]
            , [(policy, AssetName "A", quantity), (policy, AssetName "12345678901234567890123456789012", 1)]
            , [(policy, AssetName "A", quantity), (otherPolicy, AssetName "A", 1)]
            ]
            $ \tokens -> do
              let assets = MaryValue (Coin 10_000_000) $ multiAssetFromList tokens
              forM_
                [ mkBasicTxOutWithImplicitDeposit address assets
                , mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets assets)
                ]
                $ \output ->
                  forM_ datumCases $ \(datum, d) ->
                    forM_ [(SNothing, 0), (SJust nativeScript, 3)] $ \(script, r) -> do
                      let entry = Unspent (output & datumTxOutL .~ datum & referenceScriptTxOutL .~ script) AtStoreMigration
                          v2 = mkDepositFormulaHistory $ DepositFormulaV2 $ CoinPerByte $ CompactCoin 4310
                      DijkstraUnspent.computeDeposit history entry
                        `shouldBe` DepositAmount (Coin (4310 * (250 + 74 * 2 + d + r)))
                      DijkstraUnspent.computeDeposit v2 entry
                        `shouldBe` DepositAmount (Coin (4310 * (260 + 80 * 2 + d + r)))

    it
      "Plutus reference script ⇒ R = payload bytes, without the enclosing language tag or output fields"
      $ do
        plutus <- expectJust $ mkPlutusScript @DijkstraEra $ alwaysSucceedsNoDatum SPlutusV3
        -- The existing V3 fixture contains 173 bytes (its hex starts 58ab).
        -- This expected count is independent of the production size accessor.
        forM_
          [ mkBasicTxOutWithImplicitDeposit address (Val.inject $ Coin 10_000_000)
          , mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets $ Val.inject $ Coin 10_000_000)
          ]
          $ \output -> do
            let entry = Unspent (output & referenceScriptTxOutL .~ SJust (fromPlutusScript plutus)) AtStoreMigration
                v2 = mkDepositFormulaHistory $ DepositFormulaV2 $ CoinPerByte $ CompactCoin 4310
            DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin (4310 * (250 + 173)))
            DijkstraUnspent.computeDeposit v2 entry `shouldBe` DepositAmount (Coin (4310 * (260 + 173)))

    prop "two identical allocations spent after V2 activation refund their own V1 and V2 amounts" $ \policy txId -> do
      let assets =
            MaryValue (Coin 10_000_000) $
              multiAssetFromList [(policy, AssetName "A", 10), (policy, AssetName "B", 1)]
          output = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets assets)
          first = TxIn txId (TxIx 0)
          second = TxIn txId (TxIx 1)
          entries =
            IndexedUTxOs.fromList
              [(first, Unspent output (AtSlot $ SlotNo 99)), (second, Unspent output (AtSlot allocationSlot))]
          v2 = DepositFormulaV2 $ CoinPerByte $ CompactCoin 4310
      evolved <- expectJust $ appendFormula allocationSlot v2 history
      IndexedUTxOs.allocatedDepositTotalAmount evolved (Set.singleton first) entries
        `shouldBe` DepositAmount (Coin 1_715_380)
      IndexedUTxOs.allocatedDepositTotalAmount evolved (Set.singleton second) entries
        `shouldBe` DepositAmount (Coin 1_810_200)
      let store = Store.mkUTxOStore evolved entries
          afterFirst = StoreInternals.release (Set.singleton first) store
          afterBoth = StoreInternals.release (Set.singleton second) afterFirst
      Store.totalDepositAmount store `shouldBe` DepositAmount (Coin 3_525_580)
      Store.totalDepositAmount afterFirst `shouldBe` DepositAmount (Coin 1_810_200)
      Store.totalDepositAmount afterBoth `shouldBe` DepositAmount (Coin 0)

  prop
    "new legacy output: minimum = V1(N,D,R), without capping by output ADA or pricing its supplied size"
    $ \policy ->
      forAll
        ((,,) <$> chooseInteger (1, 10_000) <*> chooseInteger (0, 100) <*> choose (0, maxBound :: Int64))
        $ \(price, lovelace, suppliedSize) -> do
          inline <- expectRight $ makeBinaryData @DijkstraEra $ SBS.pack [0x43, 1, 2, 3]
          let parameters = def & ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin $ fromInteger price)
              assets =
                MaryValue (Coin lovelace) $
                  multiAssetFromList [(policy, AssetName "A", 1), (policy, AssetName "B", 2)]
              legacy =
                mkBasicLegacyTxOut @DijkstraEra address assets
                  & datumBabbageTxOutL .~ Datum inline
                  & referenceScriptBabbageTxOutL .~ SJust (fromNativeScript $ mkTimeStart @DijkstraEra $ SlotNo 0)
              -- N = 2, D = 4, R = 3: the required reserve is 405p, even with only 0–100 lovelace present.
              expectedMinimum = Coin $ 405 * price
          getMinCoinTxOut @DijkstraEra parameters legacy `shouldBe` expectedMinimum
          getMinCoinSizedTxOut @DijkstraEra parameters (Sized legacy suppliedSize) `shouldBe` expectedMinimum

  describe "Legacy: reserve = min(output ADA, calculated deposit)" $ do
    -- An ADA-only output needs 250 × 4310 lovelace. Only 1 ADA is available here.
    it "requiredDeposit > outputADA ⇒ reserve = outputADA ∧ applicationADA = 0" $ do
      let output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 1_000_000)
          entry = Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
      DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin 1_000_000)
      DijkstraUnspent.computeApplicationAssets history entry
        `shouldBe` (ApplicationAssets $ Val.inject $ Coin 0)
      Unspent.computeExternalDeposit history entry `shouldBe` Coin 0
      Unspent.toTxOut entry `shouldBe` output

    it "requiredDeposit < outputADA ⇒ reserve = requiredDeposit ∧ applicationADA = outputADA − reserve" $ do
      let output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 2_000_000)
          entry = Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
      DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin 1_077_500)
      DijkstraUnspent.computeApplicationAssets history entry
        `shouldBe` (ApplicationAssets $ Val.inject $ Coin 922_500)
      Unspent.computeExternalDeposit history entry `shouldBe` Coin 0

    prop "application assets + embedded reserve = original value; every native asset is preserved" $
      forAll (arbitrary @(Value DijkstraEra)) $ \value ->
        forAll (choose (0, 3_000_000)) $ \lovelace -> do
          let originalValue = Val.modifyCoin (const $ Coin lovelace) value
              output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address originalValue
              entry = Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
              reserve = min lovelace $ (250 + 74 * nativeAssetsIn originalValue) * 4310
          DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin reserve)
          DijkstraUnspent.computeApplicationAssets history entry
            `shouldBe` (ApplicationAssets $ Val.modifyCoin (const $ Coin $ lovelace - reserve) originalValue)
          Unspent.computeExternalDeposit history entry `shouldBe` Coin 0
          Unspent.toTxOut entry `shouldBe` output

    it "outputADA = 0 ⇒ reserve = 0 ∧ applicationADA = 0" $ do
      let output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 0)
          entry =
            Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
      DijkstraUnspent.computeDeposit history entry `shouldBe` DepositAmount (Coin 0)
      DijkstraUnspent.computeApplicationAssets history entry
        `shouldBe` (ApplicationAssets $ Val.inject $ Coin 0)

    prop "an embedded legacy reserve adds no separately held ADA to the Store" $ \txId -> do
      let output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 2_000_000)
          entry = Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
          store = Store.mkUTxOStore history $ IndexedUTxOs.singleton (TxIn txId $ TxIx 0) entry
      DijkstraUnspent.computeDeposit (Store.depositFormulaHistory store) entry
        `shouldBe` DepositAmount (Coin 1_077_500)
      Store.totalDepositAmount store `shouldBe` DepositAmount {toCoin = Coin 0}

  describe "New: reserve is external; application assets are unchanged" $
    prop "allocatedAt < activation ⇒ baseline price; allocatedAt ≥ activation ⇒ new price" $
      forAll (arbitrary @(Value DijkstraEra)) $ \value -> do
        let originalValue = Val.modifyCoin (const $ Coin 2_000_000) value
            output = mkBasicTxOutWithStoreBackedDeposit @DijkstraEra address (ApplicationAssets originalValue)
            baseline = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 3
            evolved =
              fromJust $
                appendFormula (SlotNo 20) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7) baseline
        let n = nativeAssetsIn originalValue
            beforeChange = Coin $ 3 * (250 + 74 * n)
            afterChange = Coin $ 7 * (260 + 80 * n)
        forM_
          [ (SlotNo 0, beforeChange)
          , (SlotNo 19, beforeChange)
          , (SlotNo 20, afterChange)
          , (SlotNo 21, afterChange)
          ]
          $ \(slot, reserve) -> do
            let entry = Unspent {Unspent.output = output, allocatedAt = AtSlot slot}
            DijkstraUnspent.computeDeposit evolved entry `shouldBe` DepositAmount reserve
            Unspent.computeExternalDeposit evolved entry `shouldBe` reserve
            DijkstraUnspent.computeApplicationAssets evolved entry `shouldBe` ApplicationAssets originalValue

  it "a dated allocation before the first change retains baseline pricing for either output form" $ do
    let legacy = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 2_000_000)
        new =
          mkBasicTxOutWithStoreBackedDeposit @DijkstraEra
            address
            (ApplicationAssets $ Val.inject $ Coin 2_000_000)
        evolved =
          fromJust $
            appendFormula (SlotNo 200) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7000) history
    forM_ [(legacy, Coin 922_500, Coin 0), (new, Coin 2_000_000, Coin 1_077_500)] $
      \(output, applicationCoin, externalDeposit) -> do
        let entry = Unspent {Unspent.output = output, allocatedAt = AtSlot allocationSlot}
        DijkstraUnspent.computeDeposit evolved entry `shouldBe` DepositAmount (Coin 1_077_500)
        DijkstraUnspent.computeApplicationAssets evolved entry
          `shouldBe` (ApplicationAssets $ Val.inject applicationCoin)
        Unspent.computeExternalDeposit evolved entry `shouldBe` externalDeposit

  prop "a later activation leaves existing reserves and application assets unchanged" $
    forAll (arbitrary @(TxOut DijkstraEra)) $ \output -> do
      let entry =
            Unspent
              { Unspent.output = output & coinTxOutL .~ Coin 2_000_000
              , allocatedAt = AtSlot allocationSlot
              }
          evolved =
            fromJust $
              appendFormula (SlotNo 200) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7000) history
      DijkstraUnspent.computeDeposit evolved entry `shouldBe` DijkstraUnspent.computeDeposit history entry
      DijkstraUnspent.computeApplicationAssets evolved entry
        `shouldBe` DijkstraUnspent.computeApplicationAssets history entry
      Unspent.computeExternalDeposit evolved entry `shouldBe` Unspent.computeExternalDeposit history entry

  it "AtStoreMigration ⇒ baseline pricing remains effective after later activations" $ do
    let output = mkBasicTxOutWithImplicitDeposit @DijkstraEra address (Val.inject $ Coin 2_000_000)
        entry = Unspent {Unspent.output = output, allocatedAt = AtStoreMigration}
        evolved =
          fromJust $
            appendFormula (SlotNo 200) (DepositFormulaV2 $ CoinPerByte $ CompactCoin 7000) history
    DijkstraUnspent.computeDeposit evolved entry `shouldBe` DepositAmount (Coin 1_077_500)
    DijkstraUnspent.computeApplicationAssets evolved entry
      `shouldBe` (ApplicationAssets $ Val.inject $ Coin 922_500)
    Unspent.computeExternalDeposit evolved entry `shouldBe` Coin 0

nativeAssetsIn :: MaryValue -> Integer
nativeAssetsIn (MaryValue _ (MultiAsset policies)) =
  toInteger . sum $ Map.size <$> policies
