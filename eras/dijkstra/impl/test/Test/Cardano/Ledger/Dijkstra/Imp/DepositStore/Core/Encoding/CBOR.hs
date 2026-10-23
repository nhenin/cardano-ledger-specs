{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | CBOR observations at every supported Dijkstra protocol version.
-- The calling spec supplies the expected results and validity rules.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.CBOR (
  cborList,
  decodeAs,
  decodeInputs,
  roundTrips,
  bodyRoundTrips,
  encodingsEqual,
) where

import Cardano.Ledger.Binary (DecCBOR, EncCBOR, Tokens (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (eraProtVersions)
import Data.Bifunctor (first)
import Test.Cardano.Ledger.Binary.Plain.Golden (Enc (..))

-- | Assemble raw CBOR arrays independently of the encoder under test.
cborList :: [Enc] -> Enc
cborList fields = Em (E (TkListLen (fromIntegral (length fields))) : fields)

-- | Encode a source value and decode it as the requested type at each version.
decodeAs ::
  forall decoded source.
  (DecCBOR decoded, EncCBOR source) =>
  source -> [Either String decoded]
decodeAs value =
  [ first show $ Binary.decodeFull @decoded version (Binary.serialize version value)
  | version <- eraProtVersions @DijkstraEra
  ]

-- | Decode each raw CBOR input at every supported Dijkstra version.
decodeInputs ::
  forall decoded.
  DecCBOR decoded =>
  [Enc] -> [Either String decoded]
decodeInputs inputs =
  [ first show $
      Binary.decodeFull @decoded version (Binary.toLazyByteString (Binary.toCBOR input))
  | input <- inputs
  , version <- eraProtVersions @DijkstraEra
  ]

-- | Read a value back at every version. Equality with the original value is
-- asserted by the calling test, rather than assumed here.
roundTrips ::
  (EncCBOR value, DecCBOR value) =>
  value -> [Either String value]
roundTrips = decodeAs

-- | Whole bodies use the production annotated CBOR decoder. Keep this distinct
-- from the plain declaration decoder.
bodyRoundTrips ::
  (EncCBOR body, DecCBOR (Binary.Annotator body)) =>
  body -> [Either String body]
bodyRoundTrips body =
  [ first show $
      Binary.decodeFullAnnotator version "declaration body" Binary.decCBOR (Binary.serialize version body)
  | version <- eraProtVersions @DijkstraEra
  ]

-- | Compare encoded bytes separately at every supported version. The calling
-- test decides whether each pair must be equal or different.
encodingsEqual :: EncCBOR value => value -> value -> [Bool]
encodingsEqual firstValue secondValue =
  [ Binary.serialize version firstValue == Binary.serialize version secondValue
  | version <- eraProtVersions @DijkstraEra
  ]
