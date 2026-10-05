{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Dijkstra.Binary.Golden (
  spec,
  module Test.Cardano.Ledger.Conway.Binary.Golden,
) where

import Cardano.Ledger.Alonzo.Plutus.Context (EraPlutusTxInfo, SupportedLanguage (..))
import Cardano.Ledger.Alonzo.Scripts (plutusScriptBinary)
import Cardano.Ledger.Alonzo.TxWits (Redeemers)
import Cardano.Ledger.BaseTypes (StrictMaybe (..), TxIx (..), Version)
import Cardano.Ledger.Binary (
  Annotator,
  DecoderError (..),
  DeserialiseFailure (..),
  Tokens (..),
  shelleyProtVer,
 )
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), PositiveCoin, mkPositiveCoin, unPositiveCoin)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Plutus (SLanguage (..))
import Cardano.Ledger.TxIn (TxIn (..))
import Control.Monad (forM_)
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.KeyMap as KeyMap
import Data.Data (Proxy (..))
import Data.Either (isLeft)
import Data.Maybe (fromMaybe)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Word (Word64)
import Lens.Micro
import Test.Cardano.Ledger.Alonzo.Arbitrary (alwaysSucceedsLang)
import Test.Cardano.Ledger.Binary.Plain.Golden (DiffView (DiffCBOR), Enc (..), expectGoldenToCBOR)
import Test.Cardano.Ledger.Common (
  Spec,
  ToExpr,
  describe,
  expectationFailure,
  it,
  prop,
  shouldBe,
  shouldNotBe,
  shouldSatisfy,
 )
import Test.Cardano.Ledger.Conway.Binary.Golden hiding (spec)
import Test.Cardano.Ledger.Core.KeyPair (mkKeyPair, mkWitnessVKey)
import Test.Cardano.Ledger.Core.Utils (mkDummySafeHash)
import Test.Cardano.Ledger.Dijkstra.Era (DijkstraEraTest)
import Test.Cardano.Ledger.Imp.Common (forEachEraVersion)

spec ::
  forall era.
  (DijkstraEraTest era, ToExpr (BlockBody era), Binary.DecCBOR (TxBody SubTx era)) =>
  Spec
spec = describe "Golden" . forEachEraVersion @era $ \version -> do
  describe "Redeemers" $ do
    goldenListRedeemersDisallowed @era version
  describe "TxCert" $ do
    conwayDecodeDuplicateDelegCertFails @era version
  describe "TxWits" $ do
    goldenDuplicateVKeyWitsDisallowed @era version
    goldenDuplicateNativeScriptsDisallowed @era version
    goldenDuplicatePlutusScriptsDisallowed @era version SPlutusV1
    goldenDuplicatePlutusScriptsDisallowed @era version SPlutusV2
    goldenDuplicatePlutusScriptsDisallowed @era version SPlutusV3
    goldenDuplicatePlutusDataDisallowed @era version
    goldenEmptyFields @era version
  describe "Subtransactions" $ do
    goldenSubTransactions @era
  describe "DepositStoreChange" $
    goldenDepositStoreChange @era version
  describe "DepositStoreSubTxChange" $
    goldenDepositStoreSubTxChange @era version
  describe "IsPhase2Valid flag" $ do
    goldenIsPhase2ValidFlag @era
  describe "Block transactions" $ do
    goldenBlockTransaction @era

-- | Private. Construct a positive amount for the codec fixtures.
positiveCoin :: Integer -> PositiveCoin
positiveCoin = fromMaybe (error "Invalid PositiveCoin test fixture") . mkPositiveCoin . Coin

-- | Private. Check the optional TopTx operation without assuming a store policy.
goldenDepositStoreChange :: forall era. DijkstraEraTest era => Version -> Spec
goldenDepositStoreChange version = do
  describe "PositiveCoin" $ do
    forM_ [1, maxCoin] $ \amount ->
      it ("Accepts and round-trips the boundary amount " <> show amount) $ do
        let coin = Coin amount
            positive = positiveCoin amount
        fmap unPositiveCoin (mkPositiveCoin coin) `shouldBe` Just coin
        Binary.decodeFull @PositiveCoin version (Binary.serialize version coin) `shouldBe` Right positive
        Aeson.eitherDecode @PositiveCoin (Aeson.encode coin) `shouldBe` Right positive
    forM_ [-1, 0, maxCoin + 1] $ \amount ->
      it ("Rejects the invalid amount " <> show amount <> " in the constructor and codecs") $ do
        mkPositiveCoin (Coin amount) `shouldBe` Nothing
        Binary.decodeFull @PositiveCoin version (Binary.serialize version amount) `shouldSatisfy` isLeft
        Aeson.eitherDecode @PositiveCoin (Aeson.encode amount) `shouldSatisfy` isLeft
    prop "Round-trips generated positive amounts through CBOR and JSON" $ \(coin :: PositiveCoin) -> do
      Binary.decodeFull @PositiveCoin version (Binary.serialize version coin) `shouldBe` Right coin
      Aeson.eitherDecode @PositiveCoin (Aeson.encode coin) `shouldBe` Right coin
  describe "TopTxWithdrawalSettlement" $ do
    forM_
      [
        ( "no TopTx withdrawal"
        , NoTopTxWithdrawal
        , Em [E $ TkListLen 1, E @Int 0]
        , Aeson.object ["kind" Aeson..= ("noTopTxWithdrawal" :: String)]
        )
      ,
        ( "settlement in a TopTx output"
        , TopTxWithdrawalTo (TxIx 0)
        , Em [E $ TkListLen 2, E @Int 1, E @Int 0]
        , Aeson.object ["kind" Aeson..= ("topTxOutput" :: String), "outputIndex" Aeson..= (0 :: Int)]
        )
      ]
      $ \(name, settlement, encoding, json) ->
        it ("Encodes and decodes " <> name) $ do
          expectGoldenToCBOR DiffCBOR (Ev version settlement) encoding
          Binary.decodeFull @TopTxWithdrawalSettlement
            version
            (Binary.toLazyByteString $ Binary.toCBOR encoding)
            `shouldBe` Right settlement
          Aeson.toJSON settlement `shouldBe` json
          Aeson.eitherDecode @TopTxWithdrawalSettlement (Aeson.encode json) `shouldBe` Right settlement
          Aeson.toJSON (WithdrawFromStore (positiveCoin 10) settlement)
            `shouldBe` Aeson.object
              [ "kind" Aeson..= ("withdraw" :: String)
              , "amount" Aeson..= (10 :: Int)
              , "settlement" Aeson..= json
              ]
    prop "Round-trips generated withdrawal settlements through CBOR and JSON" $
      \(settlement :: TopTxWithdrawalSettlement) -> do
        Binary.decodeFull @TopTxWithdrawalSettlement version (Binary.serialize version settlement)
          `shouldBe` Right settlement
        Aeson.eitherDecode @TopTxWithdrawalSettlement (Aeson.encode settlement) `shouldBe` Right settlement
  it "Omitting the operation preserves the existing body encoding" $ do
    basicBody ^. depositStoreChangeTxBodyL `shouldBe` SNothing
    expectGoldenToCBOR DiffCBOR (Ev version basicBody) basicBodyEncoding
    decodeEnc @(TxBody TopTx era) version basicBodyEncoding `shouldBe` Right basicBody
  it "Decodes historical JSON without an operation as no declaration" $
    case Aeson.toJSON basicBody of
      Aeson.Object fields ->
        Aeson.fromJSON (Aeson.Object $ KeyMap.delete "depositStoreChange" fields)
          `shouldBe` Aeson.Success basicBody
      _ -> expectationFailure "Expected a JSON object for the transaction body"
  it "Distinguishes an explicit zero net change from an absent declaration" $ do
    let noChangeBody = basicBody & depositStoreChangeTxBodyL .~ SJust NoDepositStoreChange
    Aeson.toJSON NoDepositStoreChange
      `shouldBe` Aeson.object ["kind" Aeson..= ("noChange" :: String)]
    noChangeBody ^. depositStoreChangeTxBodyL `shouldBe` SJust NoDepositStoreChange
    Aeson.toJSON noChangeBody `shouldNotBe` Aeson.toJSON basicBody
    Binary.serialize version noChangeBody `shouldNotBe` Binary.serialize version basicBody
  forM_
    [ ("zero net change", NoDepositStoreChange, Em [E $ TkListLen 1, E @Int 2])
    , ("one-lovelace deposit", DepositToStore (positiveCoin 1), Em [E $ TkListLen 2, E @Int 0, E @Int 1])
    , ("deposit", DepositToStore (positiveCoin 10), Em [E $ TkListLen 2, E @Int 0, E @Int 10])
    ,
      ( "largest deposit"
      , DepositToStore (positiveCoin maxCoin)
      , Em [E $ TkListLen 2, E @Int 0, E maxCoin]
      )
    ,
      ( "withdrawal with no TopTx settlement"
      , WithdrawFromStore (positiveCoin 10) NoTopTxWithdrawal
      , withdrawalEncoding 10 (Em [E $ TkListLen 1, E @Int 0])
      )
    ,
      ( "withdrawal to the first output"
      , WithdrawFromStore (positiveCoin 10) (TopTxWithdrawalTo $ TxIx 0)
      , withdrawalEncoding 10 (Em [E $ TkListLen 2, E @Int 1, E @Int 0])
      )
    ,
      ( "largest withdrawal"
      , WithdrawFromStore (positiveCoin maxCoin) (TopTxWithdrawalTo $ TxIx 0)
      , withdrawalEncoding maxCoin (Em [E $ TkListLen 2, E @Int 1, E @Int 0])
      )
    ,
      ( "withdrawal to the largest output index"
      , WithdrawFromStore (positiveCoin 10) (TopTxWithdrawalTo maxBound)
      , withdrawalEncoding 10 (Em [E $ TkListLen 2, E @Int 1, E @Int 65535])
      )
    ]
    $ \(name, operation, operationEncoding) ->
      it ("Round-trips a " <> name <> " in TopTx field 28 and JSON") $ do
        let body = basicBody & depositStoreChangeTxBodyL .~ SJust operation
            encoding = bodyWithOperationEncoding operationEncoding
        expectGoldenToCBOR DiffCBOR (Ev version body) encoding
        decodeEnc @(TxBody TopTx era) version encoding `shouldBe` Right body
        Binary.decodeFull @(TxBody TopTx era) version (Binary.serialize version body) `shouldBe` Right body
        Aeson.eitherDecode (Aeson.encode body) `shouldBe` Right body
  forM_
    [ ("unknown operation", Em [E $ TkListLen 2, E @Int 3, E @Int 10])
    , ("no-change operation with an amount", Em [E $ TkListLen 2, E @Int 2, E @Int 10])
    , ("zero deposit", Em [E $ TkListLen 2, E @Int 0, E @Int 0])
    , ("negative deposit", Em [E $ TkListLen 2, E @Int 0, E @Int (-1)])
    , ("deposit exceeding Word64", Em [E $ TkListLen 2, E @Int 0, E $ maxCoin + 1])
    , ("zero withdrawal", withdrawalEncoding 0 noTopTxWithdrawalEncoding)
    , ("negative withdrawal", withdrawalEncoding (-1) noTopTxWithdrawalEncoding)
    , ("withdrawal exceeding Word64", withdrawalEncoding (maxCoin + 1) noTopTxWithdrawalEncoding)
    , ("deposit with an output index", Em [E $ TkListLen 3, E @Int 0, E @Int 10, E @Int 0])
    , ("withdrawal without settlement", Em [E $ TkListLen 2, E @Int 1, E @Int 10])
    ]
    $ \(name, operationEncoding) ->
      it ("Rejects " <> name <> " in both TopTx decoders") $ do
        let encoding = bodyWithOperationEncoding operationEncoding
        decodeEnc @(TxBody TopTx era) version encoding `shouldSatisfy` isLeft
        Binary.decodeFull @(TxBody TopTx era)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldSatisfy` isLeft
  forM_
    [ ("bare output index", E @Int 0)
    , ("unknown settlement", Em [E $ TkListLen 1, E @Int 2])
    , ("empty settlement", E $ TkListLen 0)
    , ("no TopTx withdrawal with an index", Em [E $ TkListLen 2, E @Int 0, E @Int 0])
    , ("TopTx settlement without an index", Em [E $ TkListLen 1, E @Int 1])
    , ("TopTx settlement with an extra index", Em [E $ TkListLen 3, E @Int 1, E @Int 0, E @Int 1])
    , ("negative output index", Em [E $ TkListLen 2, E @Int 1, E @Int (-1)])
    , ("output index exceeding Word16", Em [E $ TkListLen 2, E @Int 1, E @Int 65536])
    ]
    $ \(name, settlementEncoding) ->
      it ("Rejects " <> name <> " as a settlement and in both TopTx decoders") $ do
        Binary.decodeFull @TopTxWithdrawalSettlement
          version
          (Binary.toLazyByteString $ Binary.toCBOR settlementEncoding)
          `shouldSatisfy` isLeft
        let encoding = bodyWithOperationEncoding $ withdrawalEncoding 10 settlementEncoding
        decodeEnc @(TxBody TopTx era) version encoding `shouldSatisfy` isLeft
        Binary.decodeFull @(TxBody TopTx era)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldSatisfy` isLeft
  forM_ ["deposit", "withdraw"] $ \kind ->
    forM_ [-1, 0, maxCoin + 1] $ \amount ->
      it ("Rejects a JSON " <> kind <> " with amount " <> show amount) $ do
        let operation =
              Aeson.object $
                ["kind" Aeson..= kind, "amount" Aeson..= amount]
                  <> ["settlement" Aeson..= NoTopTxWithdrawal | kind == "withdraw"]
        expectRejectedJsonOperation operation
  it "Rejects a JSON withdrawal without an explicit settlement" $
    expectRejectedJsonOperation $
      Aeson.object ["kind" Aeson..= ("withdraw" :: String), "amount" Aeson..= (10 :: Int)]
  forM_
    [ ("bare output index", Aeson.toJSON (0 :: Int))
    , ("null settlement", Aeson.Null)
    , ("missing kind", Aeson.object [])
    , ("unknown kind", Aeson.object ["kind" Aeson..= ("unknown" :: String)])
    , ("missing output index", Aeson.object ["kind" Aeson..= ("topTxOutput" :: String)])
    ,
      ( "negative output index"
      , Aeson.object ["kind" Aeson..= ("topTxOutput" :: String), "outputIndex" Aeson..= (-1 :: Int)]
      )
    ,
      ( "output index exceeding Word16"
      , Aeson.object ["kind" Aeson..= ("topTxOutput" :: String), "outputIndex" Aeson..= (65536 :: Int)]
      )
    ]
    $ \(name, settlement) ->
      it ("Rejects a JSON withdrawal settlement with " <> name) $ do
        Aeson.eitherDecode @TopTxWithdrawalSettlement (Aeson.encode settlement) `shouldSatisfy` isLeft
        expectRejectedJsonOperation $
          Aeson.object
            [ "kind" Aeson..= ("withdraw" :: String)
            , "amount" Aeson..= (10 :: Int)
            , "settlement" Aeson..= settlement
            ]
  where
    maxCoin = toInteger (maxBound :: Word64)
    basicBody = mkBasicTxBody @era @TopTx
    outputFields =
      Em
        [ Em [E @Int 0, Ev version $ Set.empty @TxIn]
        , Em [E @Int 1, Ev version $ [] @(TxOut era)]
        ]
    basicBodyEncoding = Em [E $ TkMapLen 3, outputFields, E @Int 2, E $ Coin 0]
    bodyWithOperationEncoding operationEncoding =
      Em [E $ TkMapLen 4, outputFields, E @Int 2, E $ Coin 0, E @Int 28, operationEncoding]
    withdrawalEncoding amount settlementEncoding =
      Em [E $ TkListLen 3, E @Int 1, E @Integer amount, settlementEncoding]
    noTopTxWithdrawalEncoding = Em [E $ TkListLen 1, E @Int 0]
    expectRejectedJsonOperation operation = do
      Aeson.eitherDecode @DepositStoreChange (Aeson.encode operation) `shouldSatisfy` isLeft
      case Aeson.toJSON basicBody of
        Aeson.Object fields ->
          Aeson.eitherDecode @(TxBody TopTx era)
            (Aeson.encode $ Aeson.Object $ KeyMap.insert "depositStoreChange" operation fields)
            `shouldSatisfy` isLeft
        _ -> expectationFailure "Expected a JSON object for the transaction body"

-- | Private. Delegation must be declared explicitly by the subtransaction.
goldenDepositStoreSubTxChange ::
  forall era.
  (DijkstraEraTest era, Binary.DecCBOR (TxBody SubTx era)) =>
  Version ->
  Spec
goldenDepositStoreSubTxChange version = do
  it "Omitting the operation preserves the existing body encoding and does not delegate" $ do
    basicBody ^. depositStoreSubTxChangeTxBodyL `shouldBe` SNothing
    expectGoldenToCBOR DiffCBOR (Ev version basicBody) basicBodyEncoding
    decodeEnc @(TxBody SubTx era) version basicBodyEncoding `shouldBe` Right basicBody
    Binary.decodeFull @(TxBody SubTx era)
      version
      (Binary.serialize version basicBody)
      `shouldBe` Right basicBody
  it "Decodes historical JSON without an operation as no request" $
    case Aeson.toJSON basicBody of
      Aeson.Object fields ->
        Aeson.fromJSON (Aeson.Object $ KeyMap.delete "depositStoreChange" fields)
          `shouldBe` Aeson.Success basicBody
      _ -> expectationFailure "Expected a JSON object for the subtransaction body"
  it "Identifies a deposit request explicitly in JSON and rejects it as a TopTx operation" $ do
    let request = SubTxRequestDepositFromTopTx (positiveCoin 10)
    Aeson.toJSON request
      `shouldBe` Aeson.object
        [ "kind" Aeson..= ("requestDepositFromTopTx" :: String)
        , "amount" Aeson..= Coin 10
        ]
    Aeson.eitherDecode @DepositStoreChange (Aeson.encode request) `shouldSatisfy` isLeft
  it "Distinguishes an explicit zero change from an absent declaration" $ do
    let noChangeBody = basicBody & depositStoreSubTxChangeTxBodyL .~ SJust SubTxNoDepositStoreChange
    Aeson.toJSON SubTxNoDepositStoreChange
      `shouldBe` Aeson.object ["kind" Aeson..= ("noChange" :: String)]
    noChangeBody ^. depositStoreSubTxChangeTxBodyL `shouldBe` SJust SubTxNoDepositStoreChange
    Aeson.toJSON noChangeBody `shouldNotBe` Aeson.toJSON basicBody
    Binary.serialize version noChangeBody `shouldNotBe` Binary.serialize version basicBody
  forM_
    [ ("zero change", SubTxNoDepositStoreChange, Em [E $ TkListLen 1, E @Int 3])
    , ("deposit", SubTxDepositToStore (positiveCoin 10), Em [E $ TkListLen 2, E @Int 0, E @Int 10])
    ,
      ( "deposit requested from TopTx"
      , SubTxRequestDepositFromTopTx (positiveCoin 10)
      , Em [E $ TkListLen 2, E @Int 2, E @Int 10]
      )
    ,
      ( "local withdrawal to the first output"
      , SubTxWithdrawFromStore (positiveCoin 10) (SubTxOutput $ TxIx 0)
      , withdrawalEncoding (Em [E $ TkListLen 2, E @Int 0, E @Int 0])
      )
    ,
      ( "local withdrawal to the largest output index"
      , SubTxWithdrawFromStore (positiveCoin 10) (SubTxOutput maxBound)
      , withdrawalEncoding (Em [E $ TkListLen 2, E @Int 0, E @Int 65535])
      )
    ,
      ( "withdrawal explicitly delegated to TopTx"
      , SubTxWithdrawFromStore (positiveCoin 10) DelegateToTopTx
      , withdrawalEncoding (Em [E $ TkListLen 1, E @Int 1])
      )
    ]
    $ \(name, operation, operationEncoding) ->
      it ("Round-trips a " <> name <> " in SubTx field 28 and JSON") $
        expectOperationRoundTrip operation operationEncoding
  forM_ [1, maxCoin] $ \amount ->
    forM_
      [
        ( "deposit"
        , SubTxDepositToStore (positiveCoin amount)
        , Em [E $ TkListLen 2, E @Int 0, E amount]
        )
      ,
        ( "deposit requested from TopTx"
        , SubTxRequestDepositFromTopTx (positiveCoin amount)
        , Em [E $ TkListLen 2, E @Int 2, E amount]
        )
      ,
        ( "local withdrawal"
        , SubTxWithdrawFromStore (positiveCoin amount) (SubTxOutput $ TxIx 0)
        , Em [E $ TkListLen 3, E @Int 1, E amount, E $ TkListLen 2, E @Int 0, E @Int 0]
        )
      ,
        ( "delegated withdrawal"
        , SubTxWithdrawFromStore (positiveCoin amount) DelegateToTopTx
        , Em [E $ TkListLen 3, E @Int 1, E amount, E $ TkListLen 1, E @Int 1]
        )
      ]
      $ \(name, operation, operationEncoding) ->
        it ("Round-trips a " <> name <> " at the positive boundary " <> show amount) $
          expectOperationRoundTrip operation operationEncoding
  forM_
    [ ("unknown operation", Em [E $ TkListLen 2, E @Int 4, E @Int 10])
    , ("no-change operation with an amount", Em [E $ TkListLen 2, E @Int 3, E @Int 0])
    , ("deposit request without an amount", Em [E $ TkListLen 1, E @Int 2])
    ,
      ( "deposit request with a target"
      , Em [E $ TkListLen 3, E @Int 2, E @Int 10, E $ TkListLen 1, E @Int 1]
      )
    , ("deposit with a target", Em [E $ TkListLen 3, E @Int 0, E @Int 10, E $ TkListLen 1, E @Int 1])
    , ("withdrawal without a target", Em [E $ TkListLen 2, E @Int 1, E @Int 10])
    , ("TopTx output index in SubTx", withdrawalEncoding (E @Int 0))
    , ("unknown target", withdrawalEncoding (Em [E $ TkListLen 1, E @Int 2]))
    , ("local target without an index", withdrawalEncoding (Em [E $ TkListLen 1, E @Int 0]))
    , ("delegation with an index", withdrawalEncoding (Em [E $ TkListLen 2, E @Int 1, E @Int 0]))
    , ("output index exceeding Word16", withdrawalEncoding (Em [E $ TkListLen 2, E @Int 0, E @Int 65536]))
    ]
    $ \(name, operationEncoding) ->
      it ("Rejects " <> name <> " in both SubTx decoders") $ do
        let encoding = bodyWithOperationEncoding operationEncoding
        decodeEnc @(TxBody SubTx era) version encoding `shouldSatisfy` isLeft
        Binary.decodeFull @(TxBody SubTx era)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldSatisfy` isLeft
  forM_ [("deposit", 0), ("requestDepositFromTopTx", 2), ("withdraw", 1)] $ \(kind, tag) ->
    forM_ [-1, 0, maxCoin + 1] $ \amount ->
      it ("Rejects a SubTx " <> kind <> " with amount " <> show amount <> " in CBOR and JSON") $ do
        let isWithdrawal = tag == 1
            operationEncoding =
              Em $
                [E $ TkListLen (if isWithdrawal then 3 else 2), E @Int tag, E amount]
                  <> [Em [E $ TkListLen 1, E @Int 1] | isWithdrawal]
            encoding = bodyWithOperationEncoding operationEncoding
            operationJson =
              Aeson.object $
                ["kind" Aeson..= kind, "amount" Aeson..= amount]
                  <> ["target" Aeson..= DelegateToTopTx | isWithdrawal]
        Binary.decodeFull @DepositStoreSubTxChange
          version
          (Binary.toLazyByteString $ Binary.toCBOR operationEncoding)
          `shouldSatisfy` isLeft
        decodeEnc @(TxBody SubTx era) version encoding `shouldSatisfy` isLeft
        Binary.decodeFull @(TxBody SubTx era)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldSatisfy` isLeft
        Aeson.eitherDecode @DepositStoreSubTxChange (Aeson.encode operationJson) `shouldSatisfy` isLeft
        case Aeson.toJSON basicBody of
          Aeson.Object fields ->
            Aeson.eitherDecode @(TxBody SubTx era)
              (Aeson.encode $ Aeson.Object $ KeyMap.insert "depositStoreChange" operationJson fields)
              `shouldSatisfy` isLeft
          _ -> expectationFailure "Expected a JSON object for the subtransaction body"
  where
    maxCoin = toInteger (maxBound :: Word64)
    basicBody = mkBasicTxBody @era @SubTx
    outputFields =
      Em
        [ Em [E @Int 0, Ev version $ Set.empty @TxIn]
        , Em [E @Int 1, Ev version $ [] @(TxOut era)]
        ]
    basicBodyEncoding = Em [E $ TkMapLen 2, outputFields]
    bodyWithOperationEncoding operationEncoding =
      Em [E $ TkMapLen 3, outputFields, E @Int 28, operationEncoding]
    withdrawalEncoding targetEncoding =
      Em [E $ TkListLen 3, E @Int 1, E @Int 10, targetEncoding]
    expectOperationRoundTrip operation operationEncoding = do
      let body = basicBody & depositStoreSubTxChangeTxBodyL .~ SJust operation
          encoding = bodyWithOperationEncoding operationEncoding
      expectGoldenToCBOR DiffCBOR (Ev version body) encoding
      decodeEnc @(TxBody SubTx era) version encoding `shouldBe` Right body
      Binary.decodeFull @(TxBody SubTx era) version (Binary.serialize version body) `shouldBe` Right body
      Aeson.eitherDecode (Aeson.encode body) `shouldBe` Right body

goldenEmptyFields :: forall era. DijkstraEraTest era => Version -> Spec
goldenEmptyFields version =
  describe "Empty fields not allowed" $ do
    let
      decoderFailure n msg =
        DecoderErrorDeserialiseFailure
          (Binary.label $ Proxy @(Annotator (TxWits era)))
          (DeserialiseFailure n msg)
    describe "Untagged" $ do
      it "addrTxWits" . expectFailureOnTxWitsEmptyField @era version 0 $
        decoderFailure 4 "Expected a non-empty set, but got an empty set"
      it "nativeScripts" . expectFailureOnTxWitsEmptyField @era version 1 $
        decoderFailure 4 "Empty list found, expected non-empty"
      it "bootstrapWitness" . expectFailureOnTxWitsEmptyField @era version 2 $
        decoderFailure 4 "Expected a non-empty set, but got an empty set"
      it "plutusV1Script" . expectFailureOnTxWitsEmptyField @era version 3 $
        decoderFailure 4 "Empty list of scripts is not allowed"
      it "plutusData" . expectFailureOnTxWitsEmptyField @era version 4 $
        decoderFailure 4 "Empty list found, expected non-empty"
      it "redeemers" . expectFailureOnTxWitsEmptyField @era version 5 $
        decoderFailure 2 "List encoding of redeemers not supported starting with PV 12"
      it "plutusV2Script" . expectFailureOnTxWitsEmptyField @era version 6 $
        decoderFailure 4 "Empty list of scripts is not allowed"
      it "plutusV3Script" . expectFailureOnTxWitsEmptyField @era version 7 $
        decoderFailure 4 "Empty list of scripts is not allowed"
    describe "Tagged" $ do
      it "addrTxWits" . expectFailureOnTxWitsEmptyFieldWithTag @era version 0 $
        decoderFailure 7 "Expected a non-empty set, but got an empty set"
      it "nativeScripts" . expectFailureOnTxWitsEmptyFieldWithTag @era version 1 $
        decoderFailure 7 "Empty list found, expected non-empty"
      it "bootstrapWitness" . expectFailureOnTxWitsEmptyFieldWithTag @era version 2 $
        decoderFailure 7 "Expected a non-empty set, but got an empty set"
      it "plutusV1Script" . expectFailureOnTxWitsEmptyFieldWithTag @era version 3 $
        decoderFailure 7 "Empty list of scripts is not allowed"
      it "plutusData" . expectFailureOnTxWitsEmptyFieldWithTag @era version 4 $
        decoderFailure 7 "Empty list found, expected non-empty"
      it "plutusV2Script" . expectFailureOnTxWitsEmptyFieldWithTag @era version 6 $
        decoderFailure 7 "Empty list of scripts is not allowed"
      it "plutusV3Script" . expectFailureOnTxWitsEmptyFieldWithTag @era version 7 $
        decoderFailure 7 "Empty list of scripts is not allowed"
    txWitsDecodingFailsOnInvalidField @era version [0 .. 7]

witsDuplicateVKeyWits :: Enc
witsDuplicateVKeyWits =
  mconcat
    [ E $ TkMapLen 1
    , E @Int 0
    , Em
        [ E $ TkTag 258
        , E $ TkListLen 2
        , Ev shelleyProtVer vkeywit
        , Ev shelleyProtVer vkeywit
        ]
    ]
  where
    vkeywit = mkWitnessVKey (mkDummySafeHash 0) (mkKeyPair 0)

witsDuplicateNativeScripts :: Enc
witsDuplicateNativeScripts =
  mconcat
    [ E $ TkMapLen 1
    , E @Int 1
    , Em
        [ E $ TkTag 258
        , E $ TkListLen 2
        , nativeScript
        , nativeScript
        ]
    ]
  where
    nativeScript = Em [E $ TkListLen 2, E @Int 1, E $ TkListLen 0]

witsDuplicatePlutus ::
  forall era l.
  EraPlutusTxInfo l era =>
  SLanguage l -> Enc
witsDuplicatePlutus slang =
  mconcat
    [ E $ TkMapLen 1
    , E @Int $ case slang of
        SPlutusV1 -> 3
        SPlutusV2 -> 6
        SPlutusV3 -> 7
        -- TODO add PlutusV4 support once the CDDL for TxWits is updated to include V4 scripts
        l -> error $ "Unsupported plutus version: " <> show l
    , Em
        [ E $ TkTag 258
        , E $ TkListLen 2
        , plutus
        , plutus
        ]
    ]
  where
    plutus = E . plutusScriptBinary $ alwaysSucceedsLang @era (SupportedLanguage slang) 0

witsDuplicatePlutusData :: Enc
witsDuplicatePlutusData =
  mconcat
    [ E $ TkMapLen 1
    , E @Int 4
    , Em
        [ E $ TkTag 258
        , E $ TkListLen 2
        , dat
        , dat
        ]
    ]
  where
    dat = E @Int 0

goldenListRedeemersDisallowed :: forall era. DijkstraEraTest era => Version -> Spec
goldenListRedeemersDisallowed version =
  it "Decoding Redeemers encoded as a list fails" $
    expectDecoderFailureAnn @(Redeemers era)
      version
      listRedeemersEnc
      ( DecoderErrorDeserialiseFailure
          "Annotator (MemoBytes (RedeemersRaw DijkstraEra))"
          (DeserialiseFailure 0 "List encoding of redeemers not supported starting with PV 12")
      )

goldenDuplicateVKeyWitsDisallowed :: forall era. DijkstraEraTest era => Version -> Spec
goldenDuplicateVKeyWitsDisallowed version =
  it "Decoding a TxWits with duplicate VKeyWits fails" $
    expectDecoderFailureAnn @(TxWits era)
      version
      witsDuplicateVKeyWits
      ( DecoderErrorDeserialiseFailure
          (Binary.label $ Proxy @(Annotator (TxWits era)))
          ( DeserialiseFailure
              208
              "Final number of elements: 1 does not match the total count that was decoded: 2"
          )
      )

goldenDuplicateNativeScriptsDisallowed :: forall era. DijkstraEraTest era => Version -> Spec
goldenDuplicateNativeScriptsDisallowed version =
  it "Decoding a TxWits with duplicate native scripts fails" $
    expectDecoderFailureAnn @(TxWits era)
      version
      witsDuplicateNativeScripts
      ( DecoderErrorCustom
          "Annotator"
          "Duplicates found, expected no duplicates"
      )

goldenDuplicatePlutusScriptsDisallowed ::
  forall era l.
  ( DijkstraEraTest era
  , EraPlutusTxInfo l era
  ) =>
  Version -> SLanguage l -> Spec
goldenDuplicatePlutusScriptsDisallowed version slang =
  it ("Decoding a TxWits with duplicate " <> show slang <> " scripts fails") $
    expectDecoderFailureAnn @(TxWits era)
      version
      (witsDuplicatePlutus @era slang)
      ( DecoderErrorDeserialiseFailure
          "Annotator (MemoBytes (AlonzoTxWitsRaw DijkstraEra))"
          ( DeserialiseFailure
              22
              "Final number of elements: 1 does not match the total count that was decoded: 2"
          )
      )

goldenDuplicatePlutusDataDisallowed :: forall era. DijkstraEraTest era => Version -> Spec
goldenDuplicatePlutusDataDisallowed version =
  it "Decoding a TxWits with duplicate plutus data fails" $
    expectDecoderFailureAnn @(TxWits era)
      version
      witsDuplicatePlutusData
      ( DecoderErrorCustom
          "Annotator"
          "Duplicates found, expected no duplicates"
      )

goldenSubTransactions :: forall era. DijkstraEraTest era => Spec
goldenSubTransactions = do
  it "TxBody with subtransactions decoded as expected" $
    expectDecoderResultOn @(TxBody TopTx era)
      (eraProtVerLow @era)
      txBodySubTransactionsEnc
      ( mkBasicTxBody @era @TopTx
          & subTransactionsTxBodyL
            .~ OMap.singleton
              (mkBasicTx @era @SubTx (mkBasicTxBody @era @SubTx))
      )
      id
  it "Subtransactions have to be non-empty if the field is present" $
    expectDecoderFailureAnn @(TxBody TopTx era)
      version
      txBodyEmptySubTransactionsEnc
      ( DecoderErrorDeserialiseFailure
          "Annotator (MemoBytes (DijkstraTxBodyRaw TopTx DijkstraEra))"
          (DeserialiseFailure 12 "Empty list found, expected non-empty")
      )
  it "Subtransactions have to be distinct" $
    expectDecoderFailureAnn @(TxBody TopTx era)
      version
      txBodyDuplicateSubTransactionsEnc
      (DecoderErrorCustom "Annotator" "Duplicates found, expected no duplicates")
  where
    version = eraProtVerLow @era
    txBodyEnc =
      mconcat
        [ E $ TkMapLen 4
        , Em [E @Int 0, Ev version $ Set.empty @TxIn]
        , Em [E @Int 1, Ev version $ [] @(TxOut era)]
        , Em [E @Int 2, E $ Coin 0]
        ]
    txBodySubTransactionsEnc =
      txBodyEnc <> Em [E @Int 23, E (TkListLen 1), subTxEnc]
    txBodyEmptySubTransactionsEnc =
      txBodyEnc <> Em [E @Int 23, E (TkListLen 0)]
    txBodyDuplicateSubTransactionsEnc =
      txBodyEnc <> Em [E @Int 23, E (TkListLen 2), subTxEnc, subTxEnc]
    subTxEnc =
      mconcat
        [ E $ TkListLen 3
        , mconcat
            [ E $ TkMapLen 2
            , Em [E @Int 0, Ev version $ Set.empty @TxIn]
            , Em [E @Int 1, Ev version $ [] @(TxOut era)]
            ]
        , E (TkMapLen 0)
        , E TkNull
        ]

goldenIsPhase2ValidFlag :: forall era. DijkstraEraTest era => Spec
goldenIsPhase2ValidFlag = do
  it "Deserialize transactions with missing `isPhase2Valid` flag" $
    expectDecoderResultOn @(Tx TopTx era)
      version
      txWithoutFlagEnc
      basicValidTx
      id
  it "Deserialize transactions with `isPhase2Valid` flag set to true" $
    expectDecoderResultOn @(Tx TopTx era)
      version
      txWithFlagTrueEnc
      basicValidTx
      id
  it "Fail to deserialize transactions with `isPhase2Valid` flag set to false" $
    expectDecoderFailureAnn @(Tx TopTx era)
      version
      txWithFlagFalseEnc
      ( DecoderErrorDeserialiseFailure
          "Annotator (Tx TopTx DijkstraEra)"
          (DeserialiseFailure 13 "Value `false` not allowed for `isPhase2Valid`")
      )
  where
    version = eraProtVerLow @era
    basicValidTx = mkBasicTx @era @TopTx (mkBasicTxBody @era @TopTx) & isPhase2ValidTxL .~ Phase2Valid
    txWithoutFlagEnc =
      mconcat
        [ E $ TkListLen 3
        , txBodyEnc
        , E (TkMapLen 0)
        , E TkNull
        ]
    txWithFlagTrueEnc =
      mconcat
        [ E $ TkListLen 4
        , txBodyEnc
        , E (TkMapLen 0)
        , E (TkBool True)
        , E TkNull
        ]
    txWithFlagFalseEnc =
      mconcat
        [ E $ TkListLen 4
        , txBodyEnc
        , E (TkMapLen 0)
        , E (TkBool False)
        , E TkNull
        ]
    txBodyEnc =
      mconcat
        [ E $ TkMapLen 3
        , Em [E @Int 0, Ev version $ Set.empty @TxIn]
        , Em [E @Int 1, Ev version $ [] @(TxOut era)]
        , Em [E @Int 2, E $ Coin 0]
        ]

goldenBlockTransaction ::
  forall era. (DijkstraEraTest era, ToExpr (BlockBody era)) => Spec
goldenBlockTransaction = do
  it "Deserialize a block body with a valid transaction" $
    expectDecoderResultOn @(BlockBody era)
      version
      (blockBodyEnc True)
      (blockBodyWithFlag Phase2Valid)
      id
  it "Deserialize a block body with an invalid transaction" $
    expectDecoderResultOn @(BlockBody era)
      version
      (blockBodyEnc False)
      (blockBodyWithFlag Phase2Invalid)
      id
  it "Fail to deserialize a block transaction with `isPhase2Valid` before auxiliary data" $
    expectDecoderFailureAnn @(BlockBody era)
      version
      blockBodyLegacyFlagEnc
      ( DecoderErrorDeserialiseFailure
          "Annotator (MemoBytes (DijkstraBlockBodyRaw DijkstraEra))"
          (DeserialiseFailure 14 "Failed to decode AlonzoTxAuxData")
      )
  where
    version = eraProtVerLow @era
    blockBodyWithFlag isPhase2Valid =
      mkBasicBlockBody @era
        & txSeqBlockBodyL
          .~ SSeq.singleton
            (mkBasicTx @era @TopTx (mkBasicTxBody @era @TopTx) & isPhase2ValidTxL .~ isPhase2Valid)
    blockBodyEnc isValid =
      mconcat
        [ E $ TkListLen 3
        , E $ TkListLen 1
        , txInBlockEnc isValid
        , E TkNull
        , E TkNull
        ]
    -- The `isPhase2Valid` flag comes after the auxiliary data in a block transaction
    txInBlockEnc isPhase2Valid =
      mconcat
        [ E $ TkListLen 4
        , txBodyEnc
        , E (TkMapLen 0)
        , E TkNull
        , E (TkBool isPhase2Valid)
        ]
    -- The mempool position of the `isPhase2Valid` flag (before the auxiliary data)
    -- is not allowed in a block transaction
    blockBodyLegacyFlagEnc =
      mconcat
        [ E $ TkListLen 3
        , E $ TkListLen 1
        , E $ TkListLen 4
        , txBodyEnc
        , E (TkMapLen 0)
        , E (TkBool True)
        , E TkNull
        , E TkNull
        , E TkNull
        ]
    txBodyEnc =
      mconcat
        [ E $ TkMapLen 3
        , Em [E @Int 0, Ev version $ Set.empty @TxIn]
        , Em [E @Int 1, Ev version $ [] @(TxOut era)]
        , Em [E @Int 2, E $ Coin 0]
        ]
