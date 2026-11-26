-- | Well-formed declarations and their use of StrictlyPositiveCoin amounts.
-- The amount type's invariant and scalar codecs are tested in ledger-core.
-- No transaction inputs, outputs or Store balance are needed to check grammar.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.GrammarSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Grammar.SubTxSpec as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Grammar.TopTxSpec as TopTx

spec :: Spec
spec = describe "DS-TX-DECLARATIONS-GRAMMAR - Grammar" $ do
  TopTx.spec
  SubTx.spec
