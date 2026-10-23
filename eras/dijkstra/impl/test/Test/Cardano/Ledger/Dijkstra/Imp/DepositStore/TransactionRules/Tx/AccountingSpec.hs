-- | Accounting checks the declared net changes and the complete transaction balance.
-- NetChange checks each SubTx's own change and TopTx's total on both phase-2 paths.
-- Attribution assigns local and delegated shares without changing the total.
-- Balance integrates the Store transfer into value conservation when phase 2 is valid.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AccountingSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.AttributionSpec as Attribution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.BalanceSpec as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.NetChangeSpec as NetChange

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-ACCOUNTING - Accounting" $ do
  NetChange.spec
  Attribution.spec
  Balance.spec
