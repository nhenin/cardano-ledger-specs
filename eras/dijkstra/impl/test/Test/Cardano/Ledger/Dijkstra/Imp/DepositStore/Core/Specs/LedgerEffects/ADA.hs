-- | Sum actual ADA independently of the production pot projection. Allocation
-- records are obligations, not extra coins; certificate deposits use their
-- actual deposited pot, not a recomputed obligation.
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
    <> depositStoreBalance (utxosDepositStore state)
    <> utxosFees state
    <> utxosDeposited state
    <> sumBalancesAccounts (lsCertState ledger ^. certDStateL . accountsL)
    <> casTreasury (esChainAccountState epoch)
    <> casReserves (esChainAccountState epoch)
    <> utxosDonation state
  where
    ledger = esLState epoch
    state = lsUTxOState ledger
