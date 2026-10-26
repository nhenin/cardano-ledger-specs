{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.BinarySpec (spec) where

import Cardano.Ledger.BaseTypes
import Cardano.Ledger.Binary
import Cardano.Ledger.Block (BlockHeaderVersionInfo)
import Cardano.Ledger.Coin
import Cardano.Ledger.Compactible
import Cardano.Ledger.DRep (DRep (..), DRepState (..))
import Cardano.Ledger.Hashes (EraIndependentData, SafeHash, ScriptHash)
import Cardano.Ledger.Keys
import Cardano.Ledger.State (DepositStore (..))
import Cardano.Ledger.TxIn
import Data.Either (isLeft)
import qualified Data.Map.Strict as Map
import Data.Word (Word64)
import qualified PlutusLedgerApi.V1 as PV1
import Test.Cardano.Ledger.Binary (decoderEquivalenceSpec)
import Test.Cardano.Ledger.Binary.RoundTrip
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Core.Arbitrary ()
import Test.Cardano.Ledger.Core.Binary.Annotator ()

spec :: Spec
spec = do
  describe "RoundTrip" $ do
    roundTripCborSpec @Coin
    roundTripCborSpec @DepositStore
    roundTripCborSpec @(CompactForm Coin)
    prop "Encode CompactCoin - Decode Coin" $
      roundTripExpectation @Coin (mkTrip (encCBOR . compactCoinOrError) decCBOR)
    prop "Encode Coin - Decode CompactCoin" $
      roundTripExpectation @Coin (mkTrip encCBOR (fromCompact <$> decCBOR))
    roundTripCborSpec @ProtVer
    roundTripCborSpec @BlockHeaderVersionInfo
    roundTripCborSpec @Nonce
    roundTripCborSpec @Url
    roundTripCborSpec @DnsName
    roundTripCborSpec @Port
    roundTripCborSpec @ActiveSlotCoeff
    roundTripCborSpec @Network
    roundTripCborSpec @BlocksMade
    roundTripCborSpec @TxIx
    roundTripCborSpec @CertIx
    roundTripCborSpec @Anchor
    roundTripCborSpec @BootstrapWitness
    roundTripCborSpec @TxId
    roundTripCborSpec @GenDelegPair
    roundTripCborSpec @GenDelegs
    roundTripCborSpec @DRepState
    roundTripCborSpec @DRep
    roundTripCborSpec @ScriptHash
    roundTripCborSpec @(SafeHash EraIndependentData)

  describe "DepositStore encoding" $ do
    it "Encodes the empty Store as an empty allocation map" $
      forM_ allVersions $ \version -> do
        let allocations = Map.empty :: Map.Map TxIn Coin
        serialize version (DepositStore allocations) `shouldBe` serialize version allocations
        decodeFull @DepositStore version (serialize version allocations)
          `shouldBe` Right (DepositStore allocations)

    prop "Preserves zero and positive deposits, including equal amounts at distinct references" $ \txId ->
      forAll (chooseInteger (1, toInteger (maxBound :: Word64))) $ \amount ->
        forM_ allVersions $ \version -> do
          let allocations =
                Map.fromList
                  [ (TxIn txId $ TxIx 0, Coin 0)
                  , (TxIn txId $ TxIx 1, Coin amount)
                  , (TxIn txId $ TxIx 2, Coin amount)
                  , (TxIn txId $ TxIx 3, Coin $ toInteger (maxBound :: Word64))
                  ]
          -- The wire value is the map itself; no independently encoded total exists.
          serialize version (DepositStore allocations) `shouldBe` serialize version allocations
          decodeFull @DepositStore version (serialize version allocations)
            `shouldBe` Right (DepositStore allocations)

    it "Rejects the retired [balance, allocations] representation" $
      forM_ allVersions $ \version ->
        decodeFull @DepositStore version (serialize version (Coin 1, Map.empty :: Map.Map TxIn Coin))
          `shouldSatisfy` isLeft

  describe "DecCBOR instances equivalence" $ do
    decoderEquivalenceSpec @PV1.Data minBound maxBound
