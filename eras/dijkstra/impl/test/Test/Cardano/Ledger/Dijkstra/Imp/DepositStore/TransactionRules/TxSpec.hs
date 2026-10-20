-- | Compose the tx domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.TxSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AccountingSpec as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AuthorizationSpec as Authorization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.DeclarationsSpec as Declarations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.MinimumCoinSpec as MinimumCoin
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.SettlementSpec as Settlement

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX - Tx" $ do
  Declarations.spec
  Accounting.spec
  Authorization.spec
  Settlement.spec
  MinimumCoin.spec
