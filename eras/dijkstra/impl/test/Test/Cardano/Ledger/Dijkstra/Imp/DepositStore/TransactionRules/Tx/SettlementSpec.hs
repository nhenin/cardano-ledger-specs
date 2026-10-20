-- | Settlement requirements: designation, output index, then application ADA.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.SettlementSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.DesignationSpec as Designation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.OutputCoinSpec as OutputCoin
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.OutputIndexSpec as OutputIndex

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-SETTLEMENT - Settlement" $ do
  Designation.spec
  OutputIndex.spec
  OutputCoin.spec
