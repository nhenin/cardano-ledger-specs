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
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Plutus (SLanguage (..))
import Cardano.Ledger.TxIn (TxIn (..))
import Control.Monad (forM_)
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.KeyMap as KeyMap
import Data.Data (Proxy (..))
import Data.Either (isLeft)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Alonzo.Arbitrary (alwaysSucceedsLang)
import Test.Cardano.Ledger.Binary.Plain.Golden (DiffView (DiffCBOR), Enc (..), expectGoldenToCBOR)
import Test.Cardano.Ledger.Common (
  Spec,
  ToExpr,
  describe,
  expectationFailure,
  it,
  shouldBe,
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

-- | Private. Check the optional TopTx operation without assuming a store policy.
goldenDepositStoreChange :: forall era. DijkstraEraTest era => Version -> Spec
goldenDepositStoreChange version = do
  it "Omitting the operation preserves the existing body encoding" $ do
    basicBody ^. depositStoreChangeTxBodyL `shouldBe` SNothing
    expectGoldenToCBOR DiffCBOR (Ev version basicBody) basicBodyEncoding
    decodeEnc @(TxBody TopTx era) version basicBodyEncoding `shouldBe` Right basicBody
  forM_
    [ ("zero deposit", DepositToStore (Coin 0), Em [E $ TkListLen 2, E @Int 0, E @Int 0])
    , ("deposit", DepositToStore (Coin 10), Em [E $ TkListLen 2, E @Int 0, E @Int 10])
    ,
      ( "withdrawal to the first output"
      , WithdrawFromStore (Coin 10) (TxIx 0)
      , Em [E $ TkListLen 3, E @Int 1, E @Int 10, E @Int 0]
      )
    ,
      ( "withdrawal to the largest output index"
      , WithdrawFromStore (Coin 10) maxBound
      , Em [E $ TkListLen 3, E @Int 1, E @Int 10, E @Int 65535]
      )
    ]
    $ \(name, operation, operationEncoding) ->
      it ("Round-trips a " <> name <> " in TopTx field 28") $ do
        let body = basicBody & depositStoreChangeTxBodyL .~ SJust operation
            encoding = bodyWithOperationEncoding operationEncoding
        expectGoldenToCBOR DiffCBOR (Ev version body) encoding
        decodeEnc @(TxBody TopTx era) version encoding `shouldBe` Right body
        Binary.decodeFull @(TxBody TopTx era) version (Binary.serialize version body) `shouldBe` Right body
  forM_
    [ ("unknown operation", Em [E $ TkListLen 2, E @Int 3, E @Int 10])
    , ("deposit request from TopTx", Em [E $ TkListLen 2, E @Int 2, E @Int 10])
    , ("negative deposit", Em [E $ TkListLen 2, E @Int 0, E @Int (-1)])
    , ("deposit with an output index", Em [E $ TkListLen 3, E @Int 0, E @Int 10, E @Int 0])
    , ("withdrawal without an output index", Em [E $ TkListLen 2, E @Int 1, E @Int 10])
    , ("output index exceeding Word16", Em [E $ TkListLen 3, E @Int 1, E @Int 10, E @Int 65536])
    , ("delegation from TopTx", Em [E $ TkListLen 3, E @Int 1, E @Int 10, E $ TkListLen 1, E @Int 1])
    ]
    $ \(name, operationEncoding) ->
      it ("Rejects " <> name <> " in both TopTx decoders") $ do
        let encoding = bodyWithOperationEncoding operationEncoding
        decodeEnc @(TxBody TopTx era) version encoding `shouldSatisfy` isLeft
        Binary.decodeFull @(TxBody TopTx era)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldSatisfy` isLeft
  where
    basicBody = mkBasicTxBody @era @TopTx
    outputFields =
      Em
        [ Em [E @Int 0, Ev version $ Set.empty @TxIn]
        , Em [E @Int 1, Ev version $ [] @(TxOut era)]
        ]
    basicBodyEncoding = Em [E $ TkMapLen 3, outputFields, E @Int 2, E $ Coin 0]
    bodyWithOperationEncoding operationEncoding =
      Em [E $ TkMapLen 4, outputFields, E @Int 2, E $ Coin 0, E @Int 28, operationEncoding]

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
    let request = SubTxRequestDepositFromTopTx (Coin 10)
    Aeson.toJSON request
      `shouldBe` Aeson.object
        [ "kind" Aeson..= ("requestDepositFromTopTx" :: String)
        , "amount" Aeson..= Coin 10
        ]
    Aeson.eitherDecode @DepositStoreChange (Aeson.encode request) `shouldSatisfy` isLeft
  forM_
    [ ("zero deposit", SubTxDepositToStore (Coin 0), Em [E $ TkListLen 2, E @Int 0, E @Int 0])
    , ("deposit", SubTxDepositToStore (Coin 10), Em [E $ TkListLen 2, E @Int 0, E @Int 10])
    ,
      ( "zero deposit requested from TopTx"
      , SubTxRequestDepositFromTopTx (Coin 0)
      , Em [E $ TkListLen 2, E @Int 2, E @Int 0]
      )
    ,
      ( "deposit requested from TopTx"
      , SubTxRequestDepositFromTopTx (Coin 10)
      , Em [E $ TkListLen 2, E @Int 2, E @Int 10]
      )
    ,
      ( "local withdrawal to the first output"
      , SubTxWithdrawFromStore (Coin 10) (SubTxOutput $ TxIx 0)
      , withdrawalEncoding (Em [E $ TkListLen 2, E @Int 0, E @Int 0])
      )
    ,
      ( "local withdrawal to the largest output index"
      , SubTxWithdrawFromStore (Coin 10) (SubTxOutput maxBound)
      , withdrawalEncoding (Em [E $ TkListLen 2, E @Int 0, E @Int 65535])
      )
    ,
      ( "withdrawal explicitly delegated to TopTx"
      , SubTxWithdrawFromStore (Coin 10) DelegateToTopTx
      , withdrawalEncoding (Em [E $ TkListLen 1, E @Int 1])
      )
    ]
    $ \(name, operation, operationEncoding) ->
      it ("Round-trips a " <> name <> " in SubTx field 28 and JSON") $ do
        let body = basicBody & depositStoreSubTxChangeTxBodyL .~ SJust operation
            encoding = bodyWithOperationEncoding operationEncoding
        expectGoldenToCBOR DiffCBOR (Ev version body) encoding
        decodeEnc @(TxBody SubTx era) version encoding `shouldBe` Right body
        Binary.decodeFull @(TxBody SubTx era) version (Binary.serialize version body) `shouldBe` Right body
        Aeson.eitherDecode (Aeson.encode body) `shouldBe` Right body
  forM_
    [ ("unknown operation", Em [E $ TkListLen 2, E @Int 3, E @Int 10])
    , ("negative deposit", Em [E $ TkListLen 2, E @Int 0, E @Int (-1)])
    , ("negative deposit request", Em [E $ TkListLen 2, E @Int 2, E @Int (-1)])
    , ("deposit request without an amount", Em [E $ TkListLen 1, E @Int 2])
    ,
      ( "deposit request with a target"
      , Em [E $ TkListLen 3, E @Int 2, E @Int 10, E $ TkListLen 1, E @Int 1]
      )
    , ("negative withdrawal", Em [E $ TkListLen 3, E @Int 1, E @Int (-1), E $ TkListLen 1, E @Int 1])
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
  where
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
