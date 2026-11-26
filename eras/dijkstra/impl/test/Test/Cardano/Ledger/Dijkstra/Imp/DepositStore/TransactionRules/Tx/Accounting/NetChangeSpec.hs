-- | Check declared net changes against independently required Store operations.
-- Each SubTx declares its own allocations minus releases. TopTx declares the
-- complete transaction total, including its own operations and every SubTx once.
-- Amount checks apply on both phase-2 outcomes; Balance checks transaction funding.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.NetChangeSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.NetChange.SubTxSpec as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.NetChange.TopTxSpec as TopTx

-- | Check own SubTx changes before the complete TopTx total.
spec :: Spec
spec = describe "DS-TX-ACCOUNTING-NET-CHANGE - Net change" $ do
  SubTx.spec
  TopTx.spec
