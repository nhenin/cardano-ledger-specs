-- | Executable DepositStore specification. Domain groups follow the business
-- specification in docs/dijkstra-deposit-store-rules.md; semantic tags identify
-- each invariant and case independently of document section numbers.
--
-- Scenario tables and properties stay with the invariant they check. Adapters
-- prepare ledger fixtures without repairing the defect under test. Expected
-- outcomes must come from the independent domain rule.
--
-- Agreed rules awaiting implementation remain deliberately failing assertions.
-- Implementation evidence belongs in docs/dijkstra-deposit-store-verification.md.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStoreSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.CollateralSpec as Collateral
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.PricingSpec as Pricing
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.StakeSpec as Stake
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.StateSpec as State
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TxSpec as Tx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.VotingSpec as Voting

spec :: Spec
spec = describe "DepositStore" $ do
  Pricing.spec
  Tx.spec
  Collateral.spec
  State.spec
  Stake.spec
  Voting.spec

-- Deferred: historical pricing, Plutus context projection and stronger local
-- settlement guarantees, as described under Remaining design work.
