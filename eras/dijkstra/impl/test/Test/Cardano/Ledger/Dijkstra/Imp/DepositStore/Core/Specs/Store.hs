-- | Queries over reachable test state. Historical metadata comes from the live
-- allocation, never from current parameters or canonical output re-encoding.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  recordedAmounts,
  storedDepositTotal,
  liveOutputStore,
  expectedAllocationDeposit,
  expectedDepositTotal,
  assertDepositTotal,
  retainsCreationMetadata,
) where

import Cardano.Ledger.Binary (sizedSize)
import Cardano.Ledger.Coin (Coin (..), CoinPerByte (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (TxOut (..))
import Cardano.Ledger.Shelley.LedgerState (UTxOState, utxosUTxOStore)
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.UTxOs.Allocations.UTxO as UTxO
import Cardano.Ledger.TxIn (TxIn)
import qualified Data.Map.Strict as Map
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM)
import Test.Cardano.Ledger.Imp.Common (expectJust, expectationFailure, shouldBe)

liveOutputStore :: UTxOState DijkstraEra -> UTxOStore DijkstraEra
liveOutputStore = utxosUTxOStore

-- | Independent specification formula for both calculation versions. V2 uses
-- the same formula as V1 for now. This does not call the production calculation
-- or read the cached total.
expectedAllocationDeposit :: Unspent (TxOut DijkstraEra) -> Coin
expectedAllocationDeposit allocation = case UTxO.toTxOut allocation of
  LegacyTxOut _ -> Coin 0
  NewTxOut _ ->
    Coin $ toInteger price * (160 + toInteger (sizedSize $ sizedOutput allocation))
  where
    CoinPerByte (CompactCoin price) = case depositCalculation allocation of
      DepositCalculationV1 rate -> rate
      DepositCalculationV2 rate -> rate

-- | Independent test observation of external deposits. Legacy entries contribute
-- no external record; a zero-priced Store-backed allocation remains present.
-- This map is never installed as ledger state or passed to production accounting.
recordedAmounts :: UTxOStore DijkstraEra -> Map.Map TxIn Coin
recordedAmounts = Map.mapMaybe recordedAmount . unAllocations . allocations
  where
    recordedAmount allocation = case UTxO.toTxOut allocation of
      LegacyTxOut _ -> Nothing
      NewTxOut _ -> Just $ expectedAllocationDeposit allocation

storedDepositTotal :: UTxOStore DijkstraEra -> Coin
storedDepositTotal = toCoin . totalDepositAmount

expectedDepositTotal :: UTxOStore DijkstraEra -> Coin
expectedDepositTotal = foldMap expectedAllocationDeposit . unAllocations . allocations

assertDepositTotal :: UTxOState DijkstraEra -> ImpTestM DijkstraEra ()
assertDepositTotal state =
  let store = liveOutputStore state
   in toCoin (totalDepositAmount store) `shouldBe` expectedDepositTotal store

retainsCreationMetadata ::
  TxIn -> Int -> CoinPerByte -> UTxOState DijkstraEra -> ImpTestM DijkstraEra ()
retainsCreationMetadata input acceptedBytes rate state = do
  entry <- expectJust $ lookupUTxO input $ allocations $ liveOutputStore state
  case UTxO.toTxOut entry of
    LegacyTxOut _ -> expectationFailure "Expected a Store-backed allocation with creation metadata"
    NewTxOut _ -> do
      sizedSize (sizedOutput entry) `shouldBe` fromIntegral acceptedBytes
      depositCalculation entry `shouldBe` DepositCalculationV1 rate
  assertDepositTotal state
