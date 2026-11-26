-- | Declaration forms and the conditions requiring a body to declare.
-- Grammar accepts well-formed representations, including absence. Requirements
-- determine when Store operations or a SubTx declaration make absence invalid.
-- Accounting checks the declared amounts separately.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.DeclarationsSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.GrammarSpec as Grammar
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.RequirementsSpec as Requirements

-- | Read valid forms before the obligations that require their use.
spec :: Spec
spec = describe "DS-TX-DECLARATIONS - Declarations" $ do
  Grammar.spec
  Requirements.spec
