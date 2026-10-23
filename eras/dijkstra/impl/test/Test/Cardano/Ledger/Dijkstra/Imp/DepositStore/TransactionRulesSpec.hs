-- | Transaction validity rules, grouped by ordinary and collateral responsibilities.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRulesSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.CollateralSpec as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.TxSpec as Tx

spec :: Spec
spec = describe "Transaction rules" $ do
  Tx.spec
  Collateral.spec
