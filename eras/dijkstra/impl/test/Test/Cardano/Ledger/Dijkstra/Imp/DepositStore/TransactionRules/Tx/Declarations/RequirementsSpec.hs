-- | Two independent obligations require declaration fields:
-- a body proposes its own Store operations, or one of its SubTxs declares.
-- TopTx declares the complete transaction total; each SubTx its own contribution.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.RequirementsSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.OperationsSpec as Operations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.SubTxDeclarationsSpec as SubTxDeclarations

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-DECLARATIONS-REQUIREMENTS - Requirements" $ do
  Operations.spec
  SubTxDeclarations.spec
