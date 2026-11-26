{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Api.Tx.Out (spec) where

import Cardano.Ledger.Allegra.Scripts (AllegraEraScript (mkTimeStart))
import Cardano.Ledger.Api.Era
import Cardano.Ledger.Api.Tx.Out
import Cardano.Ledger.Babbage.TxOut (datumBabbageTxOutL, referenceScriptBabbageTxOutL)
import Cardano.Ledger.BaseTypes (SlotNo (..), StrictMaybe (..), pvMajor, strictMaybeToMaybe)
import Cardano.Ledger.Binary (Sized (sizedValue), mkSized, serialize)
import Cardano.Ledger.Coin
import Cardano.Ledger.Conway.Core
import Cardano.Ledger.Mary.Value (AssetName (..), MaryValue (..), multiAssetFromList)
import Cardano.Ledger.Plutus.Data (hashBinaryData, makeBinaryData)
import qualified Cardano.Ledger.Val as Val
import qualified Data.ByteString.Lazy as BSL
import qualified Data.ByteString.Short as SBS
import Data.Default (Default (def))
import Data.Functor.Identity
import Data.Word (Word64)
import Lens.Micro
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()

genCompactCoin ::
  (Testable prop, EraTxOut era) => MinAdaTxOut era -> (CompactForm Coin -> prop) -> Property
genCompactCoin txOut =
  let
    val = txOut ^. valueTxOutL
    -- NOTE: Came up with this by solving for `scaledMinDeposit`,
    -- using the part that can get out of bounds. I.e:
    -- `coinsPerUTxOWord * (utxoEntrySizeWithoutVal + size v)`
    -- where
    -- `coinsPerUTxOWord = quot mv (utxoEntrySizeWithoutVal + coinSize)`
    -- `utxoEntrySizeWithoutVal = 27`
    -- `coinSize = 0`
    -- Substituting `maxBound` for `mv` yields the formula below:
    maxCoin = 27 * quot (maxBound :: Word64) (27 + fromIntegral (Val.size val))
   in
    forAll
      ( CompactCoin
          <$> oneof [choose (0, 1000000), choose (0, maxCoin), fromIntegral <$> (arbitrary :: Gen Word)]
      )

genCoinPerByte ::
  (Testable prop, EraTxOut era) => MinAdaTxOut era -> (CoinPerByte -> prop) -> Property
genCoinPerByte txOut =
  let
    val = txOut ^. valueTxOutL
    -- NOTE: As per the UTxO rule:
    -- ∀ txout ∈ allOuts txb, getValue txout ≥ inject (serSize txout ∗ coinsPerUTxOByte pp)
    -- Solving for `coinsPerUTxOByte` we get:
    -- `size (getValue txout) / serSize txout >= coinsPerUTxOByte`
    -- `serSize txout = 160 + length (serialize protver txout)`, so by substitution:
    -- `size (getValue txout) / 160 + length (serialize protver txout) >= coinsPerUTxOByte`.
    -- If we want to maximise this, we can set `length (serialize protver txout)` to `0`, thus:
    -- `size (getValue txout) / 160 >= coinsPerUTxOByte`
    maxCoin = quot (fromIntegral $ Val.size val) 160
   in
    forAll
      ( CoinPerByte . CompactCoin
          <$> oneof [choose (0, 1000000), choose (0, maxCoin), fromIntegral <$> (arbitrary :: Gen Word)]
      )

propSetShelleyMinTxOut ::
  forall era.
  ( EraTxOut era
  , Arbitrary (MinAdaTxOut era)
  , Show (MinAdaTxOut era)
  , AtMostEra "Mary" era
  ) =>
  Spec
propSetShelleyMinTxOut =
  prop "setShelleyMinTxOut" $ \(txOut0 :: MinAdaTxOut era) ->
    genCompactCoin txOut0 $ \cc ->
      within 1000000 $ -- just in case if there is a problem with termination
        let pp = def & ppMinUTxOValueCompactL .~ cc
            txOut1 = setMinCoinTxOut pp txOut0
            val = txOut1 ^. valueTxOutL
            minUTxOValue = unCoin $ pp ^. ppMinUTxOValueL
            minVal
              | Val.isAdaOnly val = 0
              | otherwise = (27 + Val.size val) * (minUTxOValue `quot` 27)
         in Val.coin val `shouldBe` Coin (max minVal minUTxOValue)
  where
    _atMostMary = atMostEra @"Mary" @era

propSetAlonzoMinTxOut :: Spec
propSetAlonzoMinTxOut =
  prop "setAlonzoMinTxOut" $ \(pp :: PParams AlonzoEra) (txOut :: MinAdaTxOut AlonzoEra) ->
    within 1000000 $ -- just in case if there is a problem with termination
      let txOut' = setMinCoinTxOut pp txOut
          valSize = Val.size (txOut' ^. valueTxOutL)
          dataHashSize = maybe 0 (const 10) $ strictMaybeToMaybe (MinAdaTxOut txOut' ^. dataHashTxOutL)
          sz = 27 + valSize + dataHashSize
       in Val.coin (txOut' ^. valueTxOutL)
            `shouldBe` Coin (sz * unCoin (unCoinPerWord (pp ^. ppCoinsPerUTxOWordL)))

propSetBabbageMinTxOut ::
  forall era.
  ( EraTxOut era
  , BabbageEraPParams era
  , Arbitrary (PParamsHKD Identity era)
  , Arbitrary (MinAdaTxOut era)
  , Show (MinAdaTxOut era)
  ) =>
  Spec
propSetBabbageMinTxOut =
  prop "setBabbageMinTxOut" $ \(pp' :: PParams era) (txOut :: MinAdaTxOut era) ->
    genCoinPerByte txOut $ \cc ->
      within 1000000 $ -- just in case if there is a problem with termination
        let pp = pp' & ppCoinsPerUTxOByteL .~ cc
            txOut' = setMinCoinTxOut pp txOut
            sz = fromIntegral $ BSL.length (serialize (pvMajor (pp ^. ppProtocolVersionL)) txOut')
         in Val.coin (txOut' ^. valueTxOutL)
              `shouldBe` Coin (fromIntegral $ (160 + sz) * (unCompactCoin . unCoinPerByte) (pp ^. ppCoinsPerUTxOByteL))

propSetDijkstraMinTxOut :: Spec
propSetDijkstraMinTxOut =
  prop "setDijkstraMinTxOut: ADA = p × (250 + 74N + D + R)" $ \(original :: MinAdaTxOut DijkstraEra) policy ->
    forAll (oneof [pure 0, choose (1, 1_000_000)]) $ \rate -> do
      inline <- expectRight $ makeBinaryData @DijkstraEra $ SBS.pack [0x43, 1, 2, 3]
      let pp = def & ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin rate)
          nativeScript = fromNativeScript @DijkstraEra $ mkTimeStart @DijkstraEra (SlotNo 0)
          -- The datum payload takes four bytes; its hash takes 32; the native script [4,0] takes three.
          datumCases = [(NoDatum, 0), (DatumHash $ hashBinaryData inline, 32), (Datum inline, 4)]
      forM_
        [ (mempty, 0)
        , (multiAssetFromList [(policy, AssetName "A", 1)], 1)
        , (multiAssetFromList [(policy, AssetName "A", 1), (policy, AssetName "B", 2)], 2)
        ]
        $ \(assets, n) ->
          forM_ datumCases $ \(datum, d) ->
            forM_ [(SNothing, 0), (SJust nativeScript, 3)] $ \(script, r) -> do
              let txOut =
                    original
                      & valueTxOutL .~ MaryValue mempty assets
                      & datumBabbageTxOutL .~ datum
                      & referenceScriptBabbageTxOutL .~ script
                  expectedMinimum = Coin $ toInteger rate * (250 + 74 * n + d + r)
                  expectedOutput = txOut & valueTxOutL %~ Val.modifyCoin (const expectedMinimum)
              setMinCoinTxOut pp txOut `shouldBe` expectedOutput
              sizedValue (setMinCoinSizedTxOut pp $ mkSized (eraProtVerHigh @DijkstraEra) txOut)
                `shouldBe` expectedOutput

propSetDijkstraEnsureMinTxOut :: Spec
propSetDijkstraEnsureMinTxOut =
  prop "setEnsureMinTxOut" $ \(pp :: PParams DijkstraEra) txOut ->
    forAll (choose (0, 1_000_000)) $ \rate ->
      propSetEnsureMinTxOutWith @DijkstraEra
        (pp & ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin rate))
        txOut

propSetEnsureMinTxOutWith ::
  forall era.
  (EraTxOut era, Eq (MinAdaTxOut era), Show (MinAdaTxOut era)) =>
  PParams era ->
  MinAdaTxOut era ->
  IO ()
propSetEnsureMinTxOutWith pp txOut = do
  ensureMinCoinTxOut pp (txOut & valueTxOutL %~ Val.modifyCoin (const mempty))
    `shouldBe` setMinCoinTxOut pp (txOut & valueTxOutL %~ Val.modifyCoin (const mempty))
  Val.coin (ensureMinCoinTxOut pp txOut ^. valueTxOutL)
    `shouldSatisfy` (>= Val.coin (setMinCoinTxOut pp txOut ^. valueTxOutL))
  let v = eraProtVerHigh @era
      txOutSz = mkSized v txOut
  ensureMinCoinSizedTxOut pp (mkSized v (txOut & valueTxOutL %~ Val.modifyCoin (const mempty)))
    `shouldBe` setMinCoinSizedTxOut pp (mkSized v (txOut & valueTxOutL %~ Val.modifyCoin (const mempty)))
  Val.coin (sizedValue (ensureMinCoinSizedTxOut pp txOutSz) ^. valueTxOutL)
    `shouldSatisfy` (>= Val.coin (sizedValue (setMinCoinSizedTxOut pp txOutSz) ^. valueTxOutL))

propSetEnsureMinTxOut ::
  forall era.
  ( EraTxOut era
  , Arbitrary (PParamsHKD Identity era)
  , Arbitrary (MinAdaTxOut era)
  , Show (MinAdaTxOut era)
  , Eq (MinAdaTxOut era)
  ) =>
  Spec
propSetEnsureMinTxOut =
  prop "setEnsureMinTxOut" $ propSetEnsureMinTxOutWith @era

propSetBabbageEnsureMinTxOut ::
  forall era.
  ( EraTxOut era
  , Arbitrary (PParamsHKD Identity era)
  , Arbitrary (MinAdaTxOut era)
  , Show (MinAdaTxOut era)
  , Eq (MinAdaTxOut era)
  , BabbageEraPParams era
  ) =>
  Spec
propSetBabbageEnsureMinTxOut =
  prop "setBabbageEnsureMinTxOut" $ \(pp :: PParams era) (txOut :: MinAdaTxOut era) ->
    genCoinPerByte txOut $ \cc -> do
      let pp' = pp & ppCoinsPerUTxOByteL .~ cc
      propSetEnsureMinTxOutWith @era pp' txOut

propSetMaryEnsureMinTxOut :: Spec
propSetMaryEnsureMinTxOut =
  prop "setMaryEnsureMinTxOut" $ \(txOut :: MinAdaTxOut MaryEra) ->
    genCompactCoin txOut $ \cc -> do
      let pp = def & ppMinUTxOValueCompactL .~ cc
      propSetEnsureMinTxOutWith pp txOut

spec :: Spec
spec =
  describe "TxOut" $ do
    describe "ShelleyEra" $ do
      propSetShelleyMinTxOut @ShelleyEra
      propSetEnsureMinTxOut @ShelleyEra
    describe "AllegraEra" $ do
      propSetShelleyMinTxOut @AllegraEra
      propSetEnsureMinTxOut @AllegraEra
    describe "MaryEra" $ do
      propSetShelleyMinTxOut @MaryEra
      propSetMaryEnsureMinTxOut
    describe "AlonzoEra" $ do
      propSetAlonzoMinTxOut
      propSetEnsureMinTxOut @AlonzoEra
    describe "BabbageEra" $ do
      propSetBabbageMinTxOut @BabbageEra
      propSetBabbageEnsureMinTxOut @BabbageEra
    describe "ConwayEra" $ do
      propSetBabbageMinTxOut @ConwayEra
      propSetBabbageEnsureMinTxOut @ConwayEra
    describe "DijkstraEra" $ do
      propSetDijkstraMinTxOut
      propSetDijkstraEnsureMinTxOut
