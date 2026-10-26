-- | Queries over reachable test state. Historical metadata comes from the live
-- allocation, never from current parameters or canonical output re-encoding.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  recordedDepositStore,
  liveOutputStore,
  expectedAllocationDeposit,
  expectedDepositTotal,
  assertDepositTotal,
  retainsCreationMetadata,
) where

import Cardano.Ledger.Binary (sizedSize)
import Cardano.Ledger.Coin (Coin (..), CoinPerByte (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Shelley.LedgerState (UTxOState, utxosOutputStorage)
import qualified Cardano.Ledger.Shelley.LedgerState as Ledger
import Cardano.Ledger.State
import Cardano.Ledger.TxIn (TxIn)
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM)
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe)

-- | Existing transaction specifications use a read-only amount view. Invalid
-- historical state fails the fixture instead of supplying an invented deposit.
recordedDepositStore :: UTxOState DijkstraEra -> DepositStore
recordedDepositStore = either (error . ("Invalid test output store: " <>) . show) id . Ledger.utxosDepositStore

liveOutputStore :: UTxOState DijkstraEra -> InMemoryUnspentTxOutputStore DijkstraEra
liveOutputStore state = case utxosOutputStorage state of
  StoredOutputs store -> store
  LegacyOutputs _ -> error "Dijkstra test state must use allocation-bearing output storage"

-- | Independent DepositCalculationV1 specification formula. It deliberately does not call the
-- production calculation or read the cached total. V2 has no specified formula.
expectedAllocationDeposit :: Allocation DijkstraEra -> Coin
expectedAllocationDeposit allocation =
  case (allocationCalculation allocation, allocationSizedOutput allocation) of
    (Nothing, Nothing) -> Coin 0
    (Just (DepositCalculationV1 (CoinPerByte (CompactCoin price))), Just output) ->
      Coin $ toInteger price * (160 + toInteger (sizedSize output))
    _ -> error "Test allocation contains unsupported or inconsistent historical metadata"

expectedDepositTotal :: InMemoryUnspentTxOutputStore DijkstraEra -> Coin
expectedDepositTotal = foldMap expectedAllocationDeposit . unAllocations . allocations

assertDepositTotal :: UTxOState DijkstraEra -> ImpTestM DijkstraEra ()
assertDepositTotal state =
  let store = liveOutputStore state
   in unInMemoryOutputDepositAmount (totalDepositAmount store) `shouldBe` expectedDepositTotal store

retainsCreationMetadata ::
  TxIn -> Int -> CoinPerByte -> UTxOState DijkstraEra -> ImpTestM DijkstraEra ()
retainsCreationMetadata input acceptedBytes rate state = do
  entry <- expectJust $ lookupAllocation input $ liveOutputStore state
  fmap sizedSize (allocationSizedOutput entry) `shouldBe` Just (fromIntegral acceptedBytes)
  allocationCalculation entry `shouldBe` Just (DepositCalculationV1 rate)
  assertDepositTotal state
