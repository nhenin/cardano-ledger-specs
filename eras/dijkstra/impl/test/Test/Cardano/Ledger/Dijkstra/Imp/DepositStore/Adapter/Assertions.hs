-- | Assertions shared across independent domain specifications.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Assertions (conformsTo) where

import Test.Cardano.Ledger.Common (Property, (===))

-- | Compare implementation and independent domain rule on the same fixture,
-- including the complete validation failure when rejected.
conformsTo ::
  (Eq result, Show result) => (input -> result) -> (input -> result) -> input -> Property
conformsTo implementation rule input = implementation input === rule input
