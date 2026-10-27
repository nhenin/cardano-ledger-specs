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
import Cardano.Ledger.Shelley.LedgerState (UTxOState, utxosUTxOs)
import Cardano.Ledger.State
import Cardano.Ledger.TxIn (TxIn)
import qualified Data.Map.Strict as Map
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM)
import Test.Cardano.Ledger.Imp.Common (expectJust, expectationFailure, shouldBe)

liveOutputStore :: UTxOState DijkstraEra -> UTxOStore DijkstraEra
liveOutputStore state = case utxosUTxOs state of
  UTxOs store -> store
  LegacyUTxOMap _ -> error "Dijkstra test state must use allocation-bearing output storage"

-- | Independent DepositCalculationV1 specification formula. It deliberately does not call the
-- production calculation or read the cached total. V2 has no specified formula.
expectedAllocationDeposit :: Unspent (TxOut DijkstraEra) -> Coin
expectedAllocationDeposit allocation =
  case depositCalculation allocation of
    DepositCalculationV1 (CoinPerByte (CompactCoin price)) -> case allocationOutput allocation of
      LegacyTxOut _ -> Coin 0
      NewTxOut _ ->
        Coin $ toInteger price * (160 + toInteger (sizedSize $ unspentOutput allocation))
    DepositCalculationV2 _ -> error "Test allocation contains unsupported V2 historical metadata"

-- | Independent test observation of external deposits. Legacy entries contribute
-- no external record; a zero-priced Store-backed allocation remains present.
-- This map is never installed as ledger state or passed to production accounting.
recordedAmounts :: UTxOStore DijkstraEra -> Map.Map TxIn Coin
recordedAmounts = Map.mapMaybe recordedAmount . unAllocations . allocations
  where
    recordedAmount allocation = case allocationOutput allocation of
      LegacyTxOut _ -> Nothing
      NewTxOut _ -> Just $ expectedAllocationDeposit allocation

storedDepositTotal :: UTxOStore DijkstraEra -> Coin
storedDepositTotal = unspentOutputDepositsAmount . totalDepositAmount

expectedDepositTotal :: UTxOStore DijkstraEra -> Coin
expectedDepositTotal = foldMap expectedAllocationDeposit . unAllocations . allocations

assertDepositTotal :: UTxOState DijkstraEra -> ImpTestM DijkstraEra ()
assertDepositTotal state =
  let store = liveOutputStore state
   in unspentOutputDepositsAmount (totalDepositAmount store) `shouldBe` expectedDepositTotal store

retainsCreationMetadata ::
  TxIn -> Int -> CoinPerByte -> UTxOState DijkstraEra -> ImpTestM DijkstraEra ()
retainsCreationMetadata input acceptedBytes rate state = do
  entry <- expectJust $ lookupAllocation input $ liveOutputStore state
  case allocationOutput entry of
    LegacyTxOut _ -> expectationFailure "Expected a Store-backed allocation with creation metadata"
    NewTxOut _ -> do
      sizedSize (unspentOutput entry) `shouldBe` fromIntegral acceptedBytes
      depositCalculation entry `shouldBe` DepositCalculationV1 rate
  assertDepositTotal state
