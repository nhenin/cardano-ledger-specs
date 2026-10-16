-- | Well-formed declarations and their use of StrictlyPositiveCoin amounts.
-- The amount type's invariant and scalar codecs are tested in ledger-core.
-- No transaction inputs, outputs or Store balance are needed to check grammar.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.GrammarSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Grammar.SubTxSpec as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Grammar.TopTxSpec as TopTx

spec :: Spec
spec = describe "DS-TX-GRAMMAR - Grammar" $ do
  TopTx.spec
  SubTx.spec
