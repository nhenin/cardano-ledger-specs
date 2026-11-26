-- | Observe applied state after validation. Each responsibility owns a different
-- observation: UTxOs, allocation records, the Store pot, fees or total ADA.
-- Translation and epoch processing establish and preserve the same Store state.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffectsSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.FeesSpec as Fees
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.EpochSpec as Epoch
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Lifecycle.TranslationSpec as Translation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Store.AllocationsSpec as Allocations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.Store.BalanceSpec as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.LedgerEffects.UTxOSpec as UTxO

spec :: Spec
spec = describe "Ledger effects" $ do
  UTxO.spec
  describe "Store" $ do
    Allocations.spec
    Balance.spec
  Fees.spec
  Conservation.spec
  describe "Lifecycle" $ do
    Translation.spec
    Epoch.spec
