-- | Sum actual ADA independently of the production pot projection. Every Store
-- deposit is calculated once from its historical metadata; certificate deposits use
-- their deposited pot, not a recomputed obligation.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.ADA (
  actualAda,
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (
  EpochState (..),
  LedgerState (..),
 )
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  expectedDepositTotal,
  liveOutputStore,
 )

actualAda :: EpochState DijkstraEra -> Coin
actualAda epoch =
  (foldMap (^. coinTxOutL) . IndexedUTxOs.txOuts . allocations . asUTxOStore $ state)
    <> expectedDepositTotal (liveOutputStore state)
    <> asFees state
    <> asDeposited state
    <> sumBalancesAccounts (lsCertState ledger ^. certDStateL . accountsL)
    <> casTreasury (esChainAccountState epoch)
    <> casReserves (esChainAccountState epoch)
    <> asDonation state
  where
    ledger = esLState epoch
    state = lsAccountingState ledger
