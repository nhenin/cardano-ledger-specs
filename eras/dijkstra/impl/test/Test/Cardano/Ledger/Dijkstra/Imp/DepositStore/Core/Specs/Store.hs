-- | Queries over reachable test state. Historical metadata comes from the live
-- allocation, never from current parameters or canonical output re-encoding.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  outputs,
  recordedAmounts,
  storedDepositTotal,
  liveOutputStore,
  expectedAllocationDeposit,
  expectedOutputDeposit,
  expectedOutputBacking,
  expectedBackingChange,
  externalDepositChange,
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
import Cardano.Ledger.Val ((<->))
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
  expectedOutputDeposit (creationFormula history allocation) (Unspent.output allocation)

creationFormula :: DepositFormulaHistory -> Unspent output -> DepositFormula
creationFormula history allocation = case allocatedAt allocation of
  AtStoreMigration -> initialFormula history
  AtSlot slot -> fromMaybe (initialFormula history) (snd <$> Map.lookupLE slot (formulaChanges history))

creditedInputBacking :: DepositFormulaHistory -> Unspent (TxOut DijkstraEra) -> Coin
creditedInputBacking history allocation =
  let output = Unspent.output allocation
      backing = expectedOutputBacking (creationFormula history allocation) output
   in case output of
        MinAdaTxOut _ -> min backing (output ^. coinTxOutL)
        DepositBackedTxOut _ -> backing

-- | Count distinct assets and measure the stored payloads for an external deposit.
expectedOutputDeposit :: DepositFormula -> TxOut DijkstraEra -> Coin
expectedOutputDeposit _ (MinAdaTxOut _) = Coin 0
expectedOutputDeposit pricing output = expectedOutputBacking pricing output

expectedOutputBacking :: DepositFormula -> TxOut DijkstraEra -> Coin
expectedOutputBacking pricing output =
  Coin $ toInteger price * (base + perAsset * assetCount + datumBytes + scriptBytes)
  where
    (CoinPerByte (CompactCoin price), base, perAsset) = case pricing of
      DepositFormulaV1 rate -> (rate, 250, 74)
      DepositFormulaV2 rate -> (rate, 260, 80)
    MaryValue _ assets = case output of
      MinAdaTxOut legacy -> legacy ^. valueTxOutL
      DepositBackedTxOut newOutput -> unApplicationAssets (newOutput ^. applicationAssetsTxOutL)
    assetCount = toInteger $ length $ flattenMultiAsset assets
    datumBytes = case output ^. datumTxOutL of
      NoDatum -> 0
      DatumHash hash -> toInteger $ BS.length $ originalBytes hash
      Datum datum -> toInteger $ BS.length $ originalBytes datum
    scriptBytes = strictMaybe 0 (toInteger . BS.length . originalBytes) (output ^. referenceScriptTxOutL)

-- | Signed reserve of a body's own outputs less the credited historical
-- reserve of its ordinary spending inputs.
expectedBackingChange :: UTxOStore DijkstraEra -> TxBody l DijkstraEra -> Coin
expectedBackingChange store body =
  foldMap (expectedOutputBacking $ currentFormula store) (body ^. outputsTxBodyL)
    <-> foldMap
      (creditedInputBacking $ depositFormulaHistory store)
      (IndexedUTxOs.unspentOutputs $ restrictToInputs (body ^. inputsTxBodyL) $ allocations store)

-- | Change in externally held ADA for one body, priced from the fixture's
-- independent historical and active formulas. Embedded reserves stay in values.
externalDepositChange :: UTxOStore DijkstraEra -> TxBody l DijkstraEra -> Coin
externalDepositChange store body =
  foldMap (expectedOutputDeposit $ currentFormula store) (body ^. outputsTxBodyL)
    <-> foldMap id (Map.restrictKeys (recordedAmounts store) (body ^. inputsTxBodyL))

-- | Independent test observation of external deposits. Legacy entries contribute
-- no external record; a zero-priced Deposit-backed allocation remains present.
-- This map is never installed as ledger state or passed to production accounting.
recordedAmounts :: UTxOStore DijkstraEra -> Map.Map TxIn Coin
recordedAmounts store =
  unIndexedUTxOs (allocations store)
    & Map.mapMaybe
      ( \allocation -> case Unspent.toTxOut allocation of
          MinAdaTxOut _ -> Nothing
          DepositBackedTxOut _ -> Just $ expectedAllocationDeposit (depositFormulaHistory store) allocation
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
    MinAdaTxOut _ -> expectationFailure "Expected a Deposit-backed allocation with creation metadata"
    DepositBackedTxOut _ -> case allocatedAt entry of
      AtStoreMigration -> expectationFailure "A newly accepted output must record its actual allocation slot"
      AtSlot slot ->
        formulaAt slot (depositFormulaHistory $ liveOutputStore state)
          `shouldBe` DepositFormulaV1 rate
  assertDepositTotal state
