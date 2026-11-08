-- | Queries over reachable test state. Historical metadata comes from the live
-- allocation, never from current parameters or canonical output re-encoding.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  outputs,
  recordedAmounts,
  storedDepositTotal,
  liveOutputStore,
  expectedAllocationDeposit,
  expectedOutputDeposit,
  expectedDepositTotal,
  assertDepositTotal,
  retainsCreationMetadata,
) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Mary.Value (MaryValue (..), flattenMultiAsset)
import Cardano.Ledger.Plutus (Datum (..))
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import qualified Cardano.Ledger.State.Accounting.UTxOs.Unspent as Unspent
import Cardano.Ledger.TxIn (TxIn)
import qualified Data.ByteString as BS
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Maybe.Strict (strictMaybe)
import Lens.Micro ((&), (^.))
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM)
import Test.Cardano.Ledger.Imp.Common (expectJust, expectationFailure, shouldBe)

liveOutputStore :: AccountingState DijkstraEra -> UTxOStore DijkstraEra
liveOutputStore = asUTxOStore

-- | Complete output observation for ledger-effect assertions. This projection
-- belongs to the test oracle; production reads use allocations directly.
outputs :: AccountingState era -> Map.Map TxIn (TxOut era)
outputs = IndexedUTxOs.mapTxOuts id . allocations . asUTxOStore

-- | Select the historical price independently of the Store and its cached total.
expectedAllocationDeposit :: DepositFormulaHistory -> Unspent (TxOut DijkstraEra) -> Coin
expectedAllocationDeposit history allocation =
  expectedOutputDeposit pricing (Unspent.output allocation)
  where
    pricing = case allocatedAt allocation of
      AtStoreMigration -> initialFormula history
      AtSlot slot -> fromMaybe (initialFormula history) (snd <$> Map.lookupLE slot (formulaChanges history))

-- | Count distinct assets and measure the stored payloads for an external deposit.
expectedOutputDeposit :: DepositFormula -> TxOut DijkstraEra -> Coin
expectedOutputDeposit _ (LegacyTxOut _) = Coin 0
expectedOutputDeposit pricing output@(NewTxOut newOutput) =
  Coin $ toInteger price * (base + perAsset * assetCount + datumBytes + scriptBytes)
  where
    (CoinPerByte (CompactCoin price), base, perAsset) = case pricing of
      DepositFormulaV1 rate -> (rate, 250, 74)
      DepositFormulaV2 rate -> (rate, 260, 80)
    MaryValue _ assets = unApplicationAssets (newOutput ^. applicationAssetsTxOutL)
    assetCount = toInteger $ length $ flattenMultiAsset assets
    datumBytes = case output ^. datumTxOutL of
      NoDatum -> 0
      DatumHash hash -> toInteger $ BS.length $ originalBytes hash
      Datum datum -> toInteger $ BS.length $ originalBytes datum
    scriptBytes = strictMaybe 0 (toInteger . BS.length . originalBytes) (output ^. referenceScriptTxOutL)

-- | Independent test observation of external deposits. Legacy entries contribute
-- no external record; a zero-priced Store-backed allocation remains present.
-- This map is never installed as ledger state or passed to production accounting.
recordedAmounts :: UTxOStore DijkstraEra -> Map.Map TxIn Coin
recordedAmounts store =
  unIndexedUTxOs (allocations store)
    & Map.mapMaybe
      ( \allocation -> case Unspent.toTxOut allocation of
          LegacyTxOut _ -> Nothing
          NewTxOut _ -> Just $ expectedAllocationDeposit (depositFormulaHistory store) allocation
      )

storedDepositTotal :: UTxOStore DijkstraEra -> Coin
storedDepositTotal = toCoin . totalDepositAmount

expectedDepositTotal :: UTxOStore DijkstraEra -> Coin
expectedDepositTotal store =
  foldMap (expectedAllocationDeposit $ depositFormulaHistory store)
    . IndexedUTxOs.unspentOutputs
    . allocations
    $ store

assertDepositTotal :: AccountingState DijkstraEra -> ImpTestM DijkstraEra ()
assertDepositTotal state =
  liveOutputStore state
    & \store -> toCoin (totalDepositAmount store) `shouldBe` expectedDepositTotal store

retainsCreationMetadata ::
  TxIn -> CoinPerByte -> AccountingState DijkstraEra -> ImpTestM DijkstraEra ()
retainsCreationMetadata input rate state = do
  entry <- expectJust $ lookupUTxO input $ allocations $ liveOutputStore state
  case Unspent.toTxOut entry of
    LegacyTxOut _ -> expectationFailure "Expected a Store-backed allocation with creation metadata"
    NewTxOut _ -> case allocatedAt entry of
      AtStoreMigration -> expectationFailure "A newly accepted output must record its actual allocation slot"
      AtSlot slot ->
        formulaAt slot (depositFormulaHistory $ liveOutputStore state)
          `shouldBe` DepositFormulaV1 rate
  assertDepositTotal state
