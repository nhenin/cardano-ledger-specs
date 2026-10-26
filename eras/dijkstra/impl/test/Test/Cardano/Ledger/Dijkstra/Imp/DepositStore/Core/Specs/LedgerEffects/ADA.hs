-- | Sum actual ADA independently of the production pot projection. Every Store
-- deposit is counted once from the allocation map; certificate deposits use
-- their deposited pot, not a recomputed obligation.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.ADA (
  actualAda,
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (EpochState (..), LedgerState (..), UTxOState (..))
import Cardano.Ledger.State
import Lens.Micro ((^.))

actualAda :: EpochState DijkstraEra -> Coin
actualAda epoch =
  foldMap (^. coinTxOutL) (unUTxO $ utxosUtxo state)
    <> foldMap id (depositStoreAllocations $ utxosDepositStore state)
    <> utxosFees state
    <> utxosDeposited state
    <> sumBalancesAccounts (lsCertState ledger ^. certDStateL . accountsL)
    <> casTreasury (esChainAccountState epoch)
    <> casReserves (esChainAccountState epoch)
    <> utxosDonation state
  where
    ledger = esLState epoch
    state = lsUTxOState ledger
