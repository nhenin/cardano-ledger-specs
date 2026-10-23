{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Decoding a body must retain each output's accepted wire size. Re-encoding an
-- equivalent output can use fewer bytes and must not redefine that stored size.
module Test.Cardano.Ledger.Dijkstra.Binary.TxBodySpec (spec) where

import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Val (inject)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import Data.Foldable (toList)
import Data.Int (Int64)
import Data.Maybe.Strict (StrictMaybe (..))
import qualified Data.Sequence.Strict as SSeq
import Data.Typeable (Typeable)
import Data.Word (Word64)
import Lens.Micro
import Test.Cardano.Ledger.Common (
  Gen,
  Spec,
  arbitrary,
  chooseInteger,
  describe,
  forAll,
  prop,
  shouldBe,
 )
import Test.Cardano.Ledger.Dijkstra.Arbitrary ()
import Test.Cardano.Ledger.Dijkstra.Binary.Annotator ()
import Test.Cardano.Ledger.Imp.Common (expectRight)

spec :: Spec
spec = describe "TxBody accepted output sizes" $ do
  prop "TopTx output: decodedSize = acceptedBytes = canonicalBytes + 1" $
    forAll storeOutput $ \output -> do
      let body = (mkBasicTxBody :: TxBody TopTx DijkstraEra) & outputsTxBodyL .~ SSeq.singleton output
      (wireBody, acceptedBytes) <- withIndefiniteOutput output body
      decodedBodies @TopTx wireBody
        >>= mapM_
          ( \decoded -> do
              map
                (\sized -> (Binary.sizedValue sized, Binary.sizedSize sized))
                (toList $ decoded ^. sizedOutputsTxBodyL)
                `shouldBe` [(output, acceptedBytes)]
              Binary.serialize (eraProtVerLow @DijkstraEra) decoded `shouldBe` wireBody
          )

  prop "SubTx output: decodedSize = acceptedBytes = canonicalBytes + 1" $
    forAll storeOutput $ \output -> do
      let body = (mkBasicTxBody :: TxBody SubTx DijkstraEra) & outputsTxBodyL .~ SSeq.singleton output
      (wireBody, acceptedBytes) <- withIndefiniteOutput output body
      decodedBodies @SubTx wireBody
        >>= mapM_
          ( \decoded -> do
              map
                (\sized -> (Binary.sizedValue sized, Binary.sizedSize sized))
                (toList $ decoded ^. sizedOutputsTxBodyL)
                `shouldBe` [(output, acceptedBytes)]
              Binary.serialize (eraProtVerLow @DijkstraEra) decoded `shouldBe` wireBody
          )

  prop "TopTx collateral return: decodedSize = acceptedBytes = canonicalBytes + 1" $
    forAll storeOutput $ \output -> do
      let body = (mkBasicTxBody :: TxBody TopTx DijkstraEra) & collateralReturnTxBodyL .~ SJust output
      (wireBody, acceptedBytes) <- withIndefiniteOutput output body
      decodedBodies @TopTx wireBody
        >>= mapM_
          ( \decoded -> do
              map
                (\sized -> (Binary.sizedValue sized, Binary.sizedSize sized))
                (toList $ decoded ^. sizedCollateralReturnTxBodyL)
                `shouldBe` [(output, acceptedBytes)]
              Binary.serialize (eraProtVerLow @DijkstraEra) decoded `shouldBe` wireBody
          )

-- | Vary the address and application ADA while retaining a two-field Store map.
-- No cached size is supplied by the fixture; it must come from the body decoder.
storeOutput :: Gen (TxOut DijkstraEra)
storeOutput = do
  address <- arbitrary
  amount <- Coin <$> chooseInteger (0, toInteger (maxBound :: Word64))
  pure $ mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject amount

-- | Replace the output's definite map with an equivalent indefinite map in the
-- actual encoded body. The closing break adds one accepted byte. Check that the
-- wire output decodes normally before using the complete body as decoder input.
withIndefiniteOutput ::
  Binary.EncCBOR body => TxOut DijkstraEra -> body -> IO (BSL.ByteString, Int64)
withIndefiniteOutput output body = do
  let version = eraProtVerLow @DijkstraEra
      canonical = BSL.toStrict $ Binary.serialize version output
      indefinite = BS.cons 0xbf (BS.tail canonical) <> BS.singleton 0xff
      bodyBytes = BSL.toStrict $ Binary.serialize version body
      (prefix, suffix) = BS.breakSubstring canonical bodyBytes
      acceptedBytes = fromIntegral $ BS.length indefinite
  BS.head canonical `shouldBe` 0xa2
  BS.null suffix `shouldBe` False
  acceptedBytes `shouldBe` fromIntegral (BS.length canonical) + 1
  Binary.decodeFull @(TxOut DijkstraEra) version (BSL.fromStrict indefinite) `shouldBe` Right output
  pure (BSL.fromStrict $ prefix <> indefinite <> BS.drop (BS.length canonical) suffix, acceptedBytes)

-- | Exercise both the production annotating decoder and the independent plain
-- decoder used by binary equivalence tests. Neither may remeasure serialized data.
decodedBodies :: forall l. Typeable l => BSL.ByteString -> IO [TxBody l DijkstraEra]
decodedBodies bytes =
  traverse
    expectRight
    [ Binary.decodeFullAnnotator version "TxBody accepted output sizes" Binary.decCBOR bytes
    , Binary.decodeFull version bytes
    ]
  where
    version = eraProtVerLow @DijkstraEra
