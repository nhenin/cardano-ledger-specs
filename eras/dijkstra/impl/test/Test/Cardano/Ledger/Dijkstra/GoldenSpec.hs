{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Dijkstra.GoldenSpec (spec) where

import Cardano.Ledger.Binary (Tokens (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules (
  DijkstraSubUtxoPredFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import Paths_cardano_ledger_dijkstra (getDataFileName)
import Test.Cardano.Ledger.Binary.Plain.Golden (DiffView (DiffCBOR), Enc (..), expectGoldenToCBOR)
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Core.JSON (goldenJsonPParamsSpec, goldenJsonPParamsUpdateSpec)
import Test.Cardano.Ledger.Dijkstra.Era ()

spec :: Spec
spec =
  describe "Golden" $ do
    beforeAll (getDataFileName "golden/pparams.json") $
      goldenJsonPParamsSpec @DijkstraEra
    beforeAll (getDataFileName "golden/pparams-update.json") $
      goldenJsonPParamsUpdateSpec @DijkstraEra
    describe "UTXO predicate failures" . forEachEraVersion @DijkstraEra $ \version -> do
      it "Encodes and decodes a missing TopTx UTxO capacity deposit declaration" $ do
        let failure = MissingTopTxUTxODepositDeclaration @DijkstraEra
            encoding = Em [E $ TkListLen 1, E @Int 24]
        expectGoldenToCBOR DiffCBOR (Ev version failure) encoding
        Binary.decodeFull @(DijkstraUtxoPredFailure DijkstraEra)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldBe` Right failure
      it "Encodes and decodes a missing declaration for TopTx's own store-backed outputs" $ do
        let failure = MissingUTxODepositDeclaration @DijkstraEra
            encoding = Em [E $ TkListLen 1, E @Int 25]
        expectGoldenToCBOR DiffCBOR (Ev version failure) encoding
        Binary.decodeFull @(DijkstraUtxoPredFailure DijkstraEra)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldBe` Right failure
    describe "SUBUTXO predicate failures" . forEachEraVersion @DijkstraEra $ \version ->
      it "Encodes and decodes a missing declaration for SubTx's own store-backed outputs" $ do
        let failure = SubMissingUTxODepositDeclaration @DijkstraEra
            encoding = Em [E $ TkListLen 1, E @Int 11]
        expectGoldenToCBOR DiffCBOR (Ev version failure) encoding
        Binary.decodeFull @(DijkstraSubUtxoPredFailure DijkstraEra)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldBe` Right failure
