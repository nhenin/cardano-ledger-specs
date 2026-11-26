{-# LANGUAGE FlexibleContexts #-}

-- | Combined CBOR and JSON observations for the DepositStore specifications.
-- The calling spec supplies the expected results for both formats.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding (
  DecoderInputs (..),
  roundTrips,
  bodyRoundTrips,
  decodeInputs,
  encodingsEqual,
) where

import Cardano.Ledger.Binary (Annotator, DecCBOR, EncCBOR)
import Cardano.Ledger.Binary.Plain (serializeAsHexText)
import qualified Data.Aeson as Aeson
import Test.Cardano.Ledger.Binary.Plain.Golden (Enc)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.CBOR as CBOR
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.JSON as JSON

-- | Independently constructed inputs for the CBOR and JSON decoders.
data DecoderInputs = DecoderInputs
  { cborInputs :: [Enc]
  , jsonInputs :: [Aeson.Value]
  }

-- | Include the generated inputs in QuickCheck counterexamples.
-- CBOR is shown as hex bytes; JSON retains its structured representation.
instance Show DecoderInputs where
  show (DecoderInputs cbor json) =
    "DecoderInputs {cborInputs (hex) = "
      <> show (map serializeAsHexText cbor)
      <> ", jsonInputs = "
      <> show json
      <> "}"

-- | Read a value back through CBOR at every supported Dijkstra version, then JSON.
roundTrips ::
  (EncCBOR value, DecCBOR value, Aeson.ToJSON value, Aeson.FromJSON value) =>
  value -> [Either String value]
roundTrips value = CBOR.roundTrips value <> [JSON.roundTrip value]

-- | Read a whole body through the production annotated CBOR decoder at every
-- supported Dijkstra version, then through JSON.
bodyRoundTrips ::
  (EncCBOR body, DecCBOR (Annotator body), Aeson.ToJSON body, Aeson.FromJSON body) =>
  body -> [Either String body]
bodyRoundTrips body = CBOR.bodyRoundTrips body <> [JSON.roundTrip body]

-- | Decode raw CBOR fixtures at every supported Dijkstra version and raw JSON
-- fixtures through their corresponding decoders.
decodeInputs ::
  (DecCBOR decoded, Aeson.FromJSON decoded) =>
  DecoderInputs -> [Either String decoded]
decodeInputs (DecoderInputs cbor json) = CBOR.decodeInputs cbor <> JSON.decodeInputs json

-- | Compare CBOR bytes at every supported Dijkstra version and JSON values.
-- Keep each result separate so the spec can require equality or inequality in both formats.
encodingsEqual :: (EncCBOR value, Aeson.ToJSON value) => value -> value -> [Bool]
encodingsEqual first second = CBOR.encodingsEqual first second <> [JSON.encodingsEqual first second]
