{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Dijkstra.GoldenSpec (spec) where

import Cardano.Ledger.Binary (Tokens (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Tx (DijkstraEraTx (hashTx))
import Cardano.Ledger.Hashes (extractHash)
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraSubUtxoPredFailure (..),
  DijkstraUtxoPredFailure (..),
 )
import Cardano.Ledger.TxIn (TxIn (..))
import Paths_cardano_ledger_dijkstra (getDataFileName)
import Test.Cardano.Ledger.Binary.Golden (goldenForHashHex)
import Test.Cardano.Ledger.Binary.Plain.Golden (DiffView (DiffCBOR), Enc (..), expectGoldenToCBOR)
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Core.JSON (goldenJsonPParamsSpec, goldenJsonPParamsUpdateSpec)
import Test.Cardano.Ledger.Dijkstra.Era ()
import Test.Cardano.Ledger.Dijkstra.Examples (exampleDijkstraTx)

spec :: Spec
spec =
  describe "Golden" $ do
    beforeAll (getDataFileName "golden/pparams.json") $
      goldenJsonPParamsSpec @DijkstraEra
    beforeAll (getDataFileName "golden/pparams-update.json") $
      goldenJsonPParamsUpdateSpec @DijkstraEra
    it "hashTx" $
      toPackageGolden getDataFileName $
        goldenForHashHex
          "golden/hashtx.hex"
          (extractHash $ hashTx exampleDijkstraTx)
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
      prop "Preserves negative amounts in DepositStore failures" $ \(Positive amount :: Positive Integer) input@(TxIn txId _) ->
        forM_
          [ InexactTopTxDepositChange (Coin $ negate amount) (Coin $ negate amount - 1)
          , InexactSubTxDepositChange txId (Coin $ negate amount) (Coin $ negate amount - 1)
          , NegativeDepositAllocation input (Coin $ negate amount)
          , DepositStoreInsolvent (Coin $ negate amount) (Coin $ amount + 1)
          ]
          $ \accountingFailure -> do
            let failure = DepositStoreFailure accountingFailure :: DijkstraUtxoPredFailure DijkstraEra
            Binary.decodeFull version (Binary.serialize version failure) `shouldBe` Right failure
    describe "SUBUTXO predicate failures" . forEachEraVersion @DijkstraEra $ \version ->
      it "Encodes and decodes a missing declaration for SubTx's own store-backed outputs" $ do
        let failure = SubMissingUTxODepositDeclaration @DijkstraEra
            encoding = Em [E $ TkListLen 1, E @Int 11]
        expectGoldenToCBOR DiffCBOR (Ev version failure) encoding
        Binary.decodeFull @(DijkstraSubUtxoPredFailure DijkstraEra)
          version
          (Binary.toLazyByteString $ Binary.toCBOR encoding)
          `shouldBe` Right failure
