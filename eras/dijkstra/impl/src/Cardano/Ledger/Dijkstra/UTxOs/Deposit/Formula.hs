{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Dijkstra's deposit formulas for both migrated and newly created outputs.
-- The components are measured from the output itself, independently of its
-- enclosing CBOR encoding. Earlier eras retain their own minimum-coin rules.
module Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula (
  calculateDeposit,
) where

import Cardano.Ledger.Babbage.TxOut (BabbageEraTxOut (..))
import Cardano.Ledger.Coin (Coin (..), CoinPerByte (..), CompactForm (CompactCoin))
import Cardano.Ledger.Hashes (SafeToHash (originalBytesSize))
import Cardano.Ledger.Mary.Value (
  CompactForm (CompactValue),
  CompactValue (..),
  MaryValue (..),
  MultiAsset (..),
 )
import Cardano.Ledger.Plutus.Data (Datum (..))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (DepositFormula (..))
import Cardano.Ledger.TxOut (
  ApplicationAssets (..),
  EraLegacyTxOut (..),
  EraNewTxOut (..),
  EraTxOut,
  TxOut (..),
  Value,
 )
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro ((^.))

-- | V1: @p * (250 + 74*N + D + R)@.
-- V2: @p * (260 + 80*N + D + R)@, for the formula-evolution experiment.
-- N counts distinct native assets; D and R count original datum and script bytes.
calculateDeposit ::
  (BabbageEraTxOut era, Value era ~ MaryValue) =>
  DepositFormula ->
  TxOut era ->
  Coin
calculateDeposit pricing output = case pricing of
  DepositFormulaV1 rate -> priceOutput rate 250 74 output
  DepositFormulaV2 rate -> priceOutput rate 260 80 output

priceOutput ::
  (BabbageEraTxOut era, Value era ~ MaryValue) =>
  CoinPerByte -> Integer -> Integer -> TxOut era -> Coin
priceOutput (CoinPerByte (CompactCoin rate)) baseBytes bytesPerAsset output =
  Coin $
    toInteger rate
      * ( baseBytes
            + bytesPerAsset * toInteger (assetCount output)
            + toInteger (datumSize output)
            + toInteger (referenceScriptSize output)
        )

-- | Count identities (policy, asset name), not quantities or ADA. Compact
-- legacy values already retain this count, so they need not be decompressed.
assetCount :: (EraTxOut era, Value era ~ MaryValue) => TxOut era -> Int
assetCount output = case output of
  LegacyTxOut legacy -> case legacy ^. valueEitherTxOutL of
    Left value -> countAssetNames value
    Right (CompactValue (CompactValueAdaOnly _)) -> 0
    Right (CompactValue (CompactValueMultiAsset _ count _)) -> fromIntegral count
  NewTxOut new -> countAssetNames . unApplicationAssets $ new ^. applicationAssetsTxOutL

countAssetNames :: MaryValue -> Int
countAssetNames (MaryValue _ (MultiAsset assets)) =
  Map.foldl' (\count names -> count + Map.size names) 0 assets

-- | A datum hash contributes its digest bytes; inline data contributes its
-- accepted payload bytes. The enclosing output field is not part of D.
datumSize :: BabbageEraTxOut era => TxOut era -> Int
datumSize output = case output ^. datumTxOutL of
  NoDatum -> 0
  DatumHash datumHash -> originalBytesSize datumHash
  Datum binaryData -> originalBytesSize binaryData

-- | Use the native or Plutus script's original bytes, without the output's
-- enclosing CBOR fields. An absent reference script contributes zero.
referenceScriptSize :: BabbageEraTxOut era => TxOut era -> Int
referenceScriptSize output = case output ^. referenceScriptTxOutL of
  SNothing -> 0
  SJust script -> originalBytesSize script
