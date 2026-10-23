-- | Executable DepositStore specification. Domain groups follow the business
-- specification in docs/dijkstra-deposit-store-rules.md; semantic tags identify
-- each invariant and case independently of document section numbers.
--
-- Scenario tables and properties stay with the invariant they check. Adapters
-- prepare ledger fixtures without repairing the defect under test. Expected
-- outcomes must come from the independent domain rule.
--
-- Agreed contracts awaiting implementation are explicitly pending, not passing
-- checks or fabricated failures. Existing coverage is referenced rather than copied.
-- Implementation evidence belongs in docs/dijkstra-deposit-store-verification.md.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStoreSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffectsSpec as LedgerEffects
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRulesSpec as TransactionRules

spec :: Spec
spec = describe "DepositStore" $ do
  TransactionRules.spec
  LedgerEffects.spec

-- Pricing, stake and voting rules remain documented but are outside the current
-- executable scope. Historical pricing, Plutus context projection and stronger
-- local settlement guarantees remain design work.
