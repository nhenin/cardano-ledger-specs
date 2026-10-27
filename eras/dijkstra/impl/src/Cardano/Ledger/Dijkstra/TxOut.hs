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

-- | Dijkstra's implicit-deposit and store-backed output representations and accessors.
module Cardano.Ledger.Dijkstra.TxOut (
  -- * Store-backed outputs
  DijkstraNewTxOut,
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
import Cardano.Ledger.Babbage.TxOut (
  BabbageEraTxOut (..),
  BabbageTxOut (BabbageTxOut),
  addrEitherBabbageTxOutL,
  babbageMinUTxOValue,
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
  EraLegacyTxOut (..),
  EraNewTxOut (..),
  EraTxOut (..),
  Script,
  TxOut (..),
 )
import Cardano.Ledger.Credential (Credential, StakeReference (..))
import Cardano.Ledger.Dijkstra.Era (DijkstraEra)
import Cardano.Ledger.Dijkstra.Scripts ()
import Cardano.Ledger.Keys (KeyRole (Staking))
import Cardano.Ledger.Mary.Value (MaryValue)
import Cardano.Ledger.Plutus.Data (Datum (..), binaryDataToData, dataToBinaryData)
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
data DijkstraNewTxOut = DijkstraNewTxOut
  { storeBackedAddress :: !Addr
  , storeBackedApplicationAssets :: !(ApplicationAssets DijkstraEra)
  , storeBackedDatum :: !(Datum DijkstraEra)
  , storeBackedReferenceScript :: !(StrictMaybe (Script DijkstraEra))
  }
  deriving stock (Eq, Ord, Show)

instance NFData DijkstraNewTxOut where
  -- Datum contains only a strict hash or compact bytes, already in normal form.
  rnf (DijkstraNewTxOut address assets datum script) =
    rnf address `seq` rnf assets `seq` rwhnf datum `seq` rnf script

deriving via
  InspectHeapNamed "DijkstraNewTxOut" DijkstraNewTxOut
  instance
    NoThunks DijkstraNewTxOut

deriving stock instance Eq (TxOut DijkstraEra)

deriving stock instance Ord (TxOut DijkstraEra)

deriving stock instance Show (TxOut DijkstraEra)

instance NFData (TxOut DijkstraEra) where
  rnf = \case
    LegacyTxOut output -> rnf output
    NewTxOut output -> rnf output

deriving via InspectHeapNamed "TxOut" (TxOut DijkstraEra) instance NoThunks (TxOut DijkstraEra)

-- Implicit outputs retain their historical encoding. Key 4 identifies application
-- assets backed by the store; it replaces the implicit value at key 1.
instance EncCBOR (TxOut DijkstraEra) where
  encCBOR = \case
    LegacyTxOut output -> encCBOR output
    NewTxOut (DijkstraNewTxOut address (ApplicationAssets assets) datum script) ->
      encode $
        Keyed (,,,,)
          !> Key 0 (To address)
          !> Omit (== NoDatum) (Key 2 (To datum))
          !> encodeKeyedStrictMaybeWith 3 encodeNestedCbor script
          !> Key 4 (To assets)

instance DecCBOR (TxOut DijkstraEra) where
  decCBOR =
    decodeDijkstraTxOut fromCborBothAddr (LegacyTxOut <$> decCBOR)

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
            (LegacyTxOut <$> decShareCBOR credentials)

-- JSON keeps the historical implicit object shape and distinguishes store-backed
-- outputs by their applicationAssets field instead of value.
instance ToKeyValuePairs DijkstraNewTxOut where
  toKeyValuePairs (DijkstraNewTxOut address (ApplicationAssets assets) datum script) =
    [ "address" .= address
    , "applicationAssets" .= assets
    , "datum" .= datum
    , "referenceScript" .= script
    ]

deriving via KeyValuePairs DijkstraNewTxOut instance ToJSON DijkstraNewTxOut

instance ToJSON (TxOut DijkstraEra) where
  toJSON = \case
    LegacyTxOut output -> toJSON output
    NewTxOut output -> toJSON output
  toEncoding = \case
    LegacyTxOut output -> toEncoding output
    NewTxOut output -> toEncoding output

instance FromJSON (TxOut DijkstraEra) where
  parseJSON = Aeson.withObject "DijkstraTxOut" $ \fields ->
    case (KeyMap.member "value" fields, KeyMap.member "applicationAssets" fields) of
      (True, False) -> LegacyTxOut <$> parseJSON (Aeson.Object fields)
      (False, True) ->
        NewTxOut
          <$> ( DijkstraNewTxOut
                  <$> fields .: "address"
                  <*> (ApplicationAssets <$> fields .: "applicationAssets")
                  <*> fields .: "datum"
                  <*> fields .: "referenceScript"
              )
      _ -> fail "DijkstraTxOut: expected exactly one of value or applicationAssets"

instance MemPack DijkstraNewTxOut where
  packedByteCount = packedByteCount . storeBackedPackedFields
  packM = packM . storeBackedPackedFields
  unpackM =
    (DijkstraNewTxOut . decompactAddr <$> unpackM)
      <*> (ApplicationAssets . fromCompact <$> unpackM)
      <*> unpackM
      <*> (maybeToStrictMaybe <$> unpackM)

instance MemPack (TxOut DijkstraEra) where
  packedByteCount = \case
    LegacyTxOut output -> packedByteCount output
    NewTxOut output -> packedTagByteCount + packedByteCount output
  packM = \case
    LegacyTxOut output -> packM output
    NewTxOut output -> packTagM 6 >> packM output
  unpackM =
    unpackTagM >>= \case
      0 -> LegacyTxOut <$> (Babbage.TxOutCompact' <$> unpackM <*> unpackM)
      1 -> LegacyTxOut <$> (Babbage.TxOutCompactDH' <$> unpackM <*> unpackM <*> unpackM)
      2 -> LegacyTxOut <$> (Babbage.TxOut_AddrHash28_AdaOnly <$> unpackM <*> unpackM <*> unpackM)
      3 ->
        LegacyTxOut
          <$> (Babbage.TxOut_AddrHash28_AdaOnly_DataHash32 <$> unpackM <*> unpackM <*> unpackM <*> unpackM)
      4 -> LegacyTxOut <$> (Babbage.TxOutCompactDatum <$> unpackM <*> unpackM <*> unpackM)
      5 ->
        LegacyTxOut
          <$> (Babbage.TxOutCompactRefScript <$> unpackM <*> unpackM <*> unpackM <*> unpackM)
      6 -> NewTxOut <$> unpackM
      tag -> unknownTagM @(TxOut DijkstraEra) tag

instance EraTxOut DijkstraEra where
  type LegacyTxOut DijkstraEra = BabbageTxOut DijkstraEra
  type NewTxOut DijkstraEra = DijkstraNewTxOut

  upgradeTxOut (LegacyTxOut output) =
    LegacyTxOut $ upgradeBabbageTxOut output

  addrEitherTxOutL =
    variantTxOutL
      addrEitherBabbageTxOutL
      ( lens
          (Left . storeBackedAddress)
          (\output address -> output {storeBackedAddress = either id decompactAddr address})
      )
  {-# INLINE addrEitherTxOutL #-}

instance EraLegacyTxOut DijkstraEra where
  mkBasicLegacyTxOut addr vl = BabbageTxOut addr vl NoDatum SNothing

  valueEitherTxOutL = valueEitherBabbageTxOutL
  {-# INLINE valueEitherTxOutL #-}

  getMinCoinSizedTxOut = babbageMinUTxOValue

instance EraNewTxOut DijkstraEra where
  mkBasicNewTxOut address assets =
    DijkstraNewTxOut address assets NoDatum SNothing

  applicationAssetsTxOutL =
    lens storeBackedApplicationAssets (\output assets -> output {storeBackedApplicationAssets = assets})
  {-# INLINE applicationAssetsTxOutL #-}

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
      (lens storeBackedDatum (\output datum -> output {storeBackedDatum = datum}))
  {-# INLINE datumTxOutL #-}

  referenceScriptTxOutL =
    variantTxOutL
      referenceScriptBabbageTxOutL
      (lens storeBackedReferenceScript (\output script -> output {storeBackedReferenceScript = script}))
  {-# INLINE referenceScriptTxOutL #-}

-- | Private: apply each variant's accessor without changing the output variant.
variantTxOutL ::
  Lens' (LegacyTxOut DijkstraEra) field ->
  Lens' (NewTxOut DijkstraEra) field ->
  Lens' (TxOut DijkstraEra) field
variantTxOutL implicitLens storeBackedLens update = \case
  LegacyTxOut output -> LegacyTxOut <$> implicitLens update output
  NewTxOut output -> NewTxOut <$> storeBackedLens update output
{-# INLINE variantTxOutL #-}

-- | Private: dispatch map outputs locally and retain the historical list decoder.
decodeDijkstraTxOut ::
  Decoder s (Addr, CompactAddr) ->
  Decoder s (TxOut DijkstraEra) ->
  Decoder s (TxOut DijkstraEra)
decodeDijkstraTxOut decodeAddress decodeImplicit =
  peekTokenType >>= \case
    TypeMapLen -> decodeDijkstraOutputMap decodeAddress
    TypeMapLenIndef -> decodeDijkstraOutputMap decodeAddress
    _ -> decodeImplicit

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
        LegacyTxOut $
          preserveDecodedCompactAddress compactAddress $
            BabbageTxOut address value (decodingDatum fields) (decodingReferenceScript fields)
    (SJust (address, _), SNothing, SJust assets) ->
      pure $
        NewTxOut $
          DijkstraNewTxOut address assets (decodingDatum fields) (decodingReferenceScript fields)
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
  LegacyTxOut output -> LegacyTxOut $ internBabbageTxOut internCredential output
  NewTxOut output ->
    NewTxOut $
      output
        { storeBackedAddress = case storeBackedAddress output of
            Addr network paymentCredential (StakeRefBase stakingCredential) ->
              Addr network paymentCredential (StakeRefBase $ internCredential stakingCredential)
            address -> address
        }

-- | Private: compact the store-backed fields for packing without changing their meaning.
storeBackedPackedFields ::
  DijkstraNewTxOut ->
  ( CompactAddr
  , CompactForm MaryValue
  , Datum DijkstraEra
  , Maybe (Script DijkstraEra)
  )
storeBackedPackedFields (DijkstraNewTxOut address (ApplicationAssets assets) datum script) =
  (compactAddr address, toCompactPartial assets, datum, strictMaybeToMaybe script)
