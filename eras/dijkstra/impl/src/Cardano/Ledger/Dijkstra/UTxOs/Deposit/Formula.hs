{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

-- | Measure Dijkstra outputs for the shared deposit formulas. Measurements are
-- independent of the enclosing output encoding; earlier minimum-coin rules remain
-- unchanged. Both migrated and newly created outputs use the same measurements.
module Cardano.Ledger.Dijkstra.UTxOs.Deposit.Formula (
  computeDeposit,
) where

import Cardano.Ledger.Babbage.TxOut (BabbageEraTxOut (..))
import Cardano.Ledger.Hashes (SafeToHash (originalBytesSize))
import Cardano.Ledger.Mary.Value (
  CompactForm (CompactValue),
  CompactValue (..),
  MaryValue (..),
  MultiAsset (..),
 )
import Cardano.Ledger.Plutus.Data (Datum (..))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  DatumBytes (..),
  DepositAmount,
  DepositFormula,
  NativeAssetCount (..),
  ReferenceScriptBytes (..),
 )
import qualified Cardano.Ledger.State.Accounting.UTxOs.Deposit as Deposit
import Cardano.Ledger.TxOut (
  ApplicationAssets (..),
  EraDepositBackedTxOut (..),
  EraMinAdaTxOut (..),
  EraTxOut,
  TxOut (..),
  Value,
 )
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro ((^.))

-- | Read the asset count, datum bytes and reference-script bytes, then apply
-- the shared formula. This amount is not yet capped by a min-ADA output's ADA.
computeDeposit ::
  (BabbageEraTxOut era, Value era ~ MaryValue) =>
  DepositFormula ->
  TxOut era ->
  DepositAmount
computeDeposit pricing output =
  Deposit.computeDeposit pricing (assetCount output) (datumBytes output) (referenceScriptBytes output)

-- | Count identities (policy, asset name), not quantities or ADA. Compact
-- min-ADA output values already retain this count, so they need not be decompressed.
assetCount :: (EraTxOut era, Value era ~ MaryValue) => TxOut era -> NativeAssetCount
assetCount output = case output of
  MinAdaTxOut minAda -> case minAda ^. valueEitherTxOutL of
    Left value -> countAssetNames value
    Right (CompactValue (CompactValueAdaOnly _)) -> NativeAssetCount 0
    Right (CompactValue (CompactValueMultiAsset _ count _)) -> NativeAssetCount $ fromIntegral count
  DepositBackedTxOut depositBacked -> countAssetNames . unApplicationAssets $ depositBacked ^. applicationAssetsTxOutL

countAssetNames :: MaryValue -> NativeAssetCount
countAssetNames (MaryValue _ (MultiAsset assets)) =
  NativeAssetCount $ Map.foldl' (\count names -> count + fromIntegral (Map.size names)) 0 assets

-- | A datum hash contributes its digest bytes; inline data contributes its
-- accepted payload bytes. The enclosing output field is not part of D.
datumBytes :: BabbageEraTxOut era => TxOut era -> DatumBytes
datumBytes output = DatumBytes . fromIntegral $ case output ^. datumTxOutL of
  NoDatum -> 0
  DatumHash datumHash -> originalBytesSize datumHash
  Datum binaryData -> originalBytesSize binaryData

-- | Use the native or Plutus script's original bytes, without the output's
-- enclosing CBOR fields. An absent reference script contributes zero.
referenceScriptBytes :: BabbageEraTxOut era => TxOut era -> ReferenceScriptBytes
referenceScriptBytes output = ReferenceScriptBytes . fromIntegral $ case output ^. referenceScriptTxOutL of
  SNothing -> 0
  SJust script -> originalBytesSize script
