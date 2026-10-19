-- | Two independent obligations require declaration fields:
-- a body proposes its own Store operations, or one of its SubTxs declares.
-- TopTx declares the complete transaction total; each SubTx its own contribution.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.RequiredDeclarationsSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.RequiredDeclarations.OperationsSpec as Operations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.RequiredDeclarations.SubTxDeclarationsSpec as SubTxDeclarations

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-REQUIRED-DECLARATIONS - When a body must declare its deposit change" $ do
  Operations.spec
  SubTxDeclarations.spec
