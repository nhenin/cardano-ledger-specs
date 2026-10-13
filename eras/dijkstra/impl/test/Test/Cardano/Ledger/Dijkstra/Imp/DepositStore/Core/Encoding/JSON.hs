-- | JSON observations shared by the DepositStore specifications.
-- Expected results and validity rules remain in the calling spec.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.JSON (
  decodeAs,
  roundTrip,
  decodeInputs,
  encodingsEqual,
) where

import qualified Data.Aeson as Aeson

-- | Encode a source value and decode it as the requested type.
decodeAs ::
  (Aeson.FromJSON decoded, Aeson.ToJSON source) =>
  source -> Either String decoded
decodeAs = Aeson.eitherDecode . Aeson.encode

-- | Read a value back through JSON; the spec compares it with the original.
roundTrip ::
  (Aeson.ToJSON value, Aeson.FromJSON value) =>
  value -> Either String value
roundTrip = decodeAs

-- | Decode independently supplied JSON fixtures without a declaration encoder.
decodeInputs :: Aeson.FromJSON decoded => [Aeson.Value] -> [Either String decoded]
decodeInputs = map decodeAs

-- | Compare JSON representations as values, independent of object-key order.
encodingsEqual :: Aeson.ToJSON value => value -> value -> Bool
encodingsEqual first second = Aeson.toJSON first == Aeson.toJSON second
