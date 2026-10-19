-- | Compose the accounting domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AccountingSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.SubTxSpec as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.TopTxSpec as TopTx

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-ACCOUNTING - Accounting" $ do
  SubTx.spec
  TopTx.spec
