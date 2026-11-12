{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

-- | Dijkstra's min-ADA and deposit-backed output representations and accessors.
module Cardano.Ledger.Dijkstra.TxOut (
  -- * Deposit-backed outputs
  DijkstraDepositBackedTxOut,
) where

import Cardano.Base.Typeable (TypeName (TypeName))
import Cardano.Ledger.Address (
  Addr (..),
  CompactAddr,
  compactAddr,
  decompactAddr,
  fromCborBackwardsBothAddr,
  fromCborBothAddr,
 )
import Cardano.Ledger.Alonzo.Core (AlonzoEraTxOut (..))
import Cardano.Ledger.Babbage.Core (ppCoinsPerUTxOByteL)
import Cardano.Ledger.Babbage.TxOut (
  BabbageEraTxOut (..),
  BabbageTxOut (BabbageTxOut),
  addrEitherBabbageTxOutL,
  datumBabbageTxOutL,
  internBabbageTxOut,
  referenceScriptBabbageTxOutL,
  valueEitherBabbageTxOutL,
 )
import qualified Cardano.Ledger.Babbage.TxOut as Babbage
import Cardano.Ledger.BaseTypes (KeyValuePairs (..), ToKeyValuePairs (..))
import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (..),
  Decoder,
  EncCBOR (..),
  Interns,
  TokenType (..),
  decodeFullAnnotator,
  decodeMemPack,
  decodeNestedCborBytes,
  decodeSparseKeyed,
  encodeNestedCbor,
  getDecoderVersion,
  interns,
  peekTokenType,
 )
import Cardano.Ledger.Binary.Coders (Encode (..), encode, encodeKeyedStrictMaybeWith, (!>))
import Cardano.Ledger.Compactible (Compactible (..), toCompactPartial)
import Cardano.Ledger.Conway.TxBody (upgradeBabbageTxOut)
import Cardano.Ledger.Core (
  ApplicationAssets (..),
  EraDepositBackedTxOut (..),
  EraMinAdaTxOut (..),
  EraTxOut (..),
  Script,
  TxOut (..),
 )
import Cardano.Ledger.Credential (Credential, StakeReference (..))
import Cardano.Ledger.Dijkstra.Era (DijkstraEra)
import Cardano.Ledger.Dijkstra.Scripts ()
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula as Deposit
import Cardano.Ledger.Keys (KeyRole (Staking))
import Cardano.Ledger.Mary.Value (MaryValue)
import Cardano.Ledger.Plutus.Data (Datum (..), binaryDataToData, dataToBinaryData)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  DepositAmount (toCoin),
  DepositFormula (DepositFormulaV1),
 )
import Control.DeepSeq (NFData (..), rwhnf)
import Data.Aeson (FromJSON (..), ToJSON (..), (.:), (.=))
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.KeyMap as KeyMap
import qualified Data.ByteString.Lazy as BSL
import Data.Maybe.Strict (StrictMaybe (..), maybeToStrictMaybe, strictMaybeToMaybe)
import Data.MemPack (MemPack (..), packTagM, packedTagByteCount, unknownTagM, unpackTagM)
import Lens.Micro (Lens', lens, to, (^.))
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- | Application assets and their spending conditions, without a capacity deposit.
-- The constructor and fields are private; use the era's constructors and accessors.
data DijkstraDepositBackedTxOut = DijkstraDepositBackedTxOut
  { depositBackedAddress :: !Addr
  , depositBackedApplicationAssets :: !(ApplicationAssets DijkstraEra)
  , depositBackedDatum :: !(Datum DijkstraEra)
  , depositBackedReferenceScript :: !(StrictMaybe (Script DijkstraEra))
  }
  deriving stock (Eq, Ord, Show)

instance NFData DijkstraDepositBackedTxOut where
  -- Datum contains only a strict hash or compact bytes, already in normal form.
  rnf (DijkstraDepositBackedTxOut address assets datum script) =
    rnf address `seq` rnf assets `seq` rwhnf datum `seq` rnf script

deriving via
  InspectHeapNamed "DijkstraDepositBackedTxOut" DijkstraDepositBackedTxOut
  instance
    NoThunks DijkstraDepositBackedTxOut

deriving stock instance Eq (TxOut DijkstraEra)

deriving stock instance Ord (TxOut DijkstraEra)

deriving stock instance Show (TxOut DijkstraEra)

instance NFData (TxOut DijkstraEra) where
  rnf = \case
    MinAdaTxOut output -> rnf output
    DepositBackedTxOut output -> rnf output

deriving via InspectHeapNamed "TxOut" (TxOut DijkstraEra) instance NoThunks (TxOut DijkstraEra)

-- Min-ADA outputs retain their historical encoding. Key 4 identifies application
-- assets backed by the store; it replaces the min-ADA output's value at key 1.
instance EncCBOR (TxOut DijkstraEra) where
  encCBOR = \case
    MinAdaTxOut output -> encCBOR output
    DepositBackedTxOut (DijkstraDepositBackedTxOut address (ApplicationAssets assets) datum script) ->
      encode $
        Keyed (,,,,)
          !> Key 0 (To address)
          !> Omit (== NoDatum) (Key 2 (To datum))
          !> encodeKeyedStrictMaybeWith 3 encodeNestedCbor script
          !> Key 4 (To assets)

instance DecCBOR (TxOut DijkstraEra) where
  decCBOR =
    decodeDijkstraTxOut fromCborBothAddr (MinAdaTxOut <$> decCBOR)

instance DecShareCBOR (TxOut DijkstraEra) where
  type Share (TxOut DijkstraEra) = Interns (Credential Staking)
  decShareCBOR credentials =
    internDijkstraTxOut (interns credentials) <$> do
      peekTokenType >>= \case
        TypeBytes -> decodeMemPack
        TypeBytesIndef -> decodeMemPack
        _ ->
          decodeDijkstraTxOut
            fromCborBackwardsBothAddr
            (MinAdaTxOut <$> decShareCBOR credentials)

-- JSON keeps the historical min-ADA object shape and distinguishes deposit-backed
-- outputs by their applicationAssets field instead of value.
instance ToKeyValuePairs DijkstraDepositBackedTxOut where
  toKeyValuePairs (DijkstraDepositBackedTxOut address (ApplicationAssets assets) datum script) =
    [ "address" .= address
    , "applicationAssets" .= assets
    , "datum" .= datum
    , "referenceScript" .= script
    ]

deriving via KeyValuePairs DijkstraDepositBackedTxOut instance ToJSON DijkstraDepositBackedTxOut

instance ToJSON (TxOut DijkstraEra) where
  toJSON = \case
    MinAdaTxOut output -> toJSON output
    DepositBackedTxOut output -> toJSON output
  toEncoding = \case
    MinAdaTxOut output -> toEncoding output
    DepositBackedTxOut output -> toEncoding output

instance FromJSON (TxOut DijkstraEra) where
  parseJSON = Aeson.withObject "DijkstraTxOut" $ \fields ->
    case (KeyMap.member "value" fields, KeyMap.member "applicationAssets" fields) of
      (True, False) -> MinAdaTxOut <$> parseJSON (Aeson.Object fields)
      (False, True) ->
        DepositBackedTxOut
          <$> ( DijkstraDepositBackedTxOut
                  <$> fields .: "address"
                  <*> (ApplicationAssets <$> fields .: "applicationAssets")
                  <*> fields .: "datum"
                  <*> fields .: "referenceScript"
              )
      _ -> fail "DijkstraTxOut: expected exactly one of value or applicationAssets"

instance MemPack DijkstraDepositBackedTxOut where
  packedByteCount = packedByteCount . depositBackedPackedFields
  packM = packM . depositBackedPackedFields
  unpackM =
    (DijkstraDepositBackedTxOut . decompactAddr <$> unpackM)
      <*> (ApplicationAssets . fromCompact <$> unpackM)
      <*> unpackM
      <*> (maybeToStrictMaybe <$> unpackM)

instance MemPack (TxOut DijkstraEra) where
  packedByteCount = \case
    MinAdaTxOut output -> packedByteCount output
    DepositBackedTxOut output -> packedTagByteCount + packedByteCount output
  packM = \case
    MinAdaTxOut output -> packM output
    DepositBackedTxOut output -> packTagM 6 >> packM output
  unpackM =
    unpackTagM >>= \case
      0 -> MinAdaTxOut <$> (Babbage.TxOutCompact' <$> unpackM <*> unpackM)
      1 -> MinAdaTxOut <$> (Babbage.TxOutCompactDH' <$> unpackM <*> unpackM <*> unpackM)
      2 -> MinAdaTxOut <$> (Babbage.TxOut_AddrHash28_AdaOnly <$> unpackM <*> unpackM <*> unpackM)
      3 ->
        MinAdaTxOut
          <$> (Babbage.TxOut_AddrHash28_AdaOnly_DataHash32 <$> unpackM <*> unpackM <*> unpackM <*> unpackM)
      4 -> MinAdaTxOut <$> (Babbage.TxOutCompactDatum <$> unpackM <*> unpackM <*> unpackM)
      5 ->
        MinAdaTxOut
          <$> (Babbage.TxOutCompactRefScript <$> unpackM <*> unpackM <*> unpackM <*> unpackM)
      6 -> DepositBackedTxOut <$> unpackM
      tag -> unknownTagM @(TxOut DijkstraEra) tag

instance EraTxOut DijkstraEra where
  type MinAdaTxOut DijkstraEra = BabbageTxOut DijkstraEra
  type DepositBackedTxOut DijkstraEra = DijkstraDepositBackedTxOut

  upgradeTxOut (MinAdaTxOut output) =
    MinAdaTxOut $ upgradeBabbageTxOut output

  addrEitherTxOutL =
    variantTxOutL
      addrEitherBabbageTxOutL
      ( lens
          (Left . depositBackedAddress)
          (\output address -> output {depositBackedAddress = either id decompactAddr address})
      )
  {-# INLINE addrEitherTxOutL #-}

instance EraMinAdaTxOut DijkstraEra where
  mkBasicMinAdaTxOut addr vl = BabbageTxOut addr vl NoDatum SNothing

  valueEitherTxOutL = valueEitherBabbageTxOutL
  {-# INLINE valueEitherTxOutL #-}

  -- This parameter-only helper uses Dijkstra's initial formula. Ledger validation
  -- uses the Store's active formula, which also supports later V2 activations.
  -- The default sized method discards the enclosing output size.
  getMinCoinTxOut pp =
    toCoin . Deposit.computeDeposit (DepositFormulaV1 $ pp ^. ppCoinsPerUTxOByteL) . MinAdaTxOut

instance EraDepositBackedTxOut DijkstraEra where
  mkBasicDepositBackedTxOut address assets =
    DijkstraDepositBackedTxOut address assets NoDatum SNothing

  applicationAssetsTxOutL =
    lens
      depositBackedApplicationAssets
      (\output assets -> output {depositBackedApplicationAssets = assets})
  {-# INLINE applicationAssetsTxOutL #-}

  getDepositTxOut pricing = toCoin . Deposit.computeDeposit pricing . DepositBackedTxOut

instance AlonzoEraTxOut DijkstraEra where
  dataHashTxOutL =
    datumTxOutL
      . lens
        ( \case
            DatumHash datumHash -> SJust datumHash
            _ -> SNothing
        )
        ( const $ \case
            SNothing -> NoDatum
            SJust datumHash -> DatumHash datumHash
        )
  {-# INLINE dataHashTxOutL #-}

  datumTxOutF = to (^. datumTxOutL)
  {-# INLINE datumTxOutF #-}

instance BabbageEraTxOut DijkstraEra where
  dataTxOutL =
    datumTxOutL
      . lens
        ( \case
            Datum binaryData -> SJust $ binaryDataToData binaryData
            _ -> SNothing
        )
        ( const $ \case
            SNothing -> NoDatum
            SJust datum -> Datum $ dataToBinaryData datum
        )
  {-# INLINE dataTxOutL #-}

  datumTxOutL =
    variantTxOutL
      datumBabbageTxOutL
      (lens depositBackedDatum (\output datum -> output {depositBackedDatum = datum}))
  {-# INLINE datumTxOutL #-}

  referenceScriptTxOutL =
    variantTxOutL
      referenceScriptBabbageTxOutL
      (lens depositBackedReferenceScript (\output script -> output {depositBackedReferenceScript = script}))
  {-# INLINE referenceScriptTxOutL #-}

-- | Private: apply each variant's accessor without changing the output variant.
variantTxOutL ::
  Lens' (MinAdaTxOut DijkstraEra) field ->
  Lens' (DepositBackedTxOut DijkstraEra) field ->
  Lens' (TxOut DijkstraEra) field
variantTxOutL minAdaLens depositBackedLens update = \case
  MinAdaTxOut output -> MinAdaTxOut <$> minAdaLens update output
  DepositBackedTxOut output -> DepositBackedTxOut <$> depositBackedLens update output
{-# INLINE variantTxOutL #-}

-- | Private: dispatch map outputs locally and retain the historical list decoder.
decodeDijkstraTxOut ::
  Decoder s (Addr, CompactAddr) ->
  Decoder s (TxOut DijkstraEra) ->
  Decoder s (TxOut DijkstraEra)
decodeDijkstraTxOut decodeAddress decodeMinAda =
  peekTokenType >>= \case
    TypeMapLen -> decodeDijkstraOutputMap decodeAddress
    TypeMapLenIndef -> decodeDijkstraOutputMap decodeAddress
    _ -> decodeMinAda

-- | Private: accumulate map fields before selecting exactly one output variant.
data DecodingDijkstraTxOut = DecodingDijkstraTxOut
  { decodingAddress :: !(StrictMaybe (Addr, CompactAddr))
  , decodingValue :: !(StrictMaybe MaryValue)
  , decodingApplicationAssets :: !(StrictMaybe (ApplicationAssets DijkstraEra))
  , decodingDatum :: !(Datum DijkstraEra)
  , decodingReferenceScript :: !(StrictMaybe (Script DijkstraEra))
  }

-- | Private: key 0 is required, together with exactly one of keys 1 and 4.
decodeDijkstraOutputMap :: forall s. Decoder s (Addr, CompactAddr) -> Decoder s (TxOut DijkstraEra)
decodeDijkstraOutputMap decodeAddress = do
  fields <- decodeSparseKeyed TypeName [(0, "address")] initial decoderByKey
  case (decodingAddress fields, decodingValue fields, decodingApplicationAssets fields) of
    (SJust (address, compactAddress), SJust value, SNothing) ->
      pure $
        MinAdaTxOut $
          preserveDecodedCompactAddress compactAddress $
            BabbageTxOut address value (decodingDatum fields) (decodingReferenceScript fields)
    (SJust (address, _), SNothing, SJust assets) ->
      pure $
        DepositBackedTxOut $
          DijkstraDepositBackedTxOut address assets (decodingDatum fields) (decodingReferenceScript fields)
    (_, SJust _, SJust _) -> fail "Dijkstra.TxOut: value and applicationAssets are mutually exclusive"
    (_, SNothing, SNothing) -> fail "Dijkstra.TxOut: value or applicationAssets is required"
    (SNothing, _, _) -> fail "Dijkstra.TxOut: address is required"
  where
    initial = DecodingDijkstraTxOut SNothing SNothing SNothing NoDatum SNothing
    decoderByKey :: DecodingDijkstraTxOut -> Word -> Maybe (Decoder s DecodingDijkstraTxOut)
    decoderByKey fields = \case
      0 -> Just $ do
        !address <- decodeAddress
        pure fields {decodingAddress = SJust address}
      1 -> Just $ do
        !value <- decCBOR
        pure fields {decodingValue = SJust value}
      2 -> Just $ do
        !datum <- decCBOR
        pure fields {decodingDatum = datum}
      3 -> Just $ do
        !script <- decodeReferenceScript
        pure fields {decodingReferenceScript = SJust script}
      4 -> Just $ do
        !assets <- ApplicationAssets <$> decCBOR
        pure fields {decodingApplicationAssets = SJust assets}
      _ -> Nothing

-- | Private: retain the compact address returned by the historical state decoder.
-- Its unpacked address can contain a normalized pointer while these bytes do not.
preserveDecodedCompactAddress :: CompactAddr -> BabbageTxOut DijkstraEra -> BabbageTxOut DijkstraEra
preserveDecodedCompactAddress address = \case
  Babbage.TxOutCompact' _ value -> Babbage.TxOutCompact' address value
  Babbage.TxOutCompactDH' _ value datumHash -> Babbage.TxOutCompactDH' address value datumHash
  Babbage.TxOutCompactDatum _ value datum -> Babbage.TxOutCompactDatum address value datum
  Babbage.TxOutCompactRefScript _ value datum script -> Babbage.TxOutCompactRefScript address value datum script
  output -> output

-- | Private: decode the annotated reference script from its nested CBOR bytes.
decodeReferenceScript :: Decoder s (Script DijkstraEra)
decodeReferenceScript = do
  version <- getDecoderVersion
  bytes <- decodeNestedCborBytes
  either (fail . show) pure $ decodeFullAnnotator version "Script" decCBOR (BSL.fromStrict bytes)

-- | Private: share staking credentials in either storage representation.
internDijkstraTxOut ::
  (Credential Staking -> Credential Staking) -> TxOut DijkstraEra -> TxOut DijkstraEra
internDijkstraTxOut internCredential = \case
  MinAdaTxOut output -> MinAdaTxOut $ internBabbageTxOut internCredential output
  DepositBackedTxOut output ->
    DepositBackedTxOut $
      output
        { depositBackedAddress = case depositBackedAddress output of
            Addr network paymentCredential (StakeRefBase stakingCredential) ->
              Addr network paymentCredential (StakeRefBase $ internCredential stakingCredential)
            address -> address
        }

-- | Private: compact the deposit-backed fields for packing without changing their meaning.
depositBackedPackedFields ::
  DijkstraDepositBackedTxOut ->
  ( CompactAddr
  , CompactForm MaryValue
  , Datum DijkstraEra
  , Maybe (Script DijkstraEra)
  )
depositBackedPackedFields (DijkstraDepositBackedTxOut address (ApplicationAssets assets) datum script) =
  (compactAddr address, toCompactPartial assets, datum, strictMaybeToMaybe script)
