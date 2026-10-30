module Main where

import qualified Test.Cardano.Ledger.AddressSpec as AddressSpec
import qualified Test.Cardano.Ledger.BaseTypesSpec as BaseTypesSpec
import qualified Test.Cardano.Ledger.BinarySpec as BinarySpec
import Test.Cardano.Ledger.Common
import qualified Test.Cardano.Ledger.JsonSpec as JsonSpec
import qualified Test.Cardano.Ledger.PlutusSpec as PlutusSpec
import qualified Test.Cardano.Ledger.State.Certificates.StakePoolSpec as StakePoolSpec
import qualified Test.Cardano.Ledger.State.Epoch.LeiosCommitteeSpec as LeiosCommitteeSpec
import qualified Test.Cardano.Ledger.State.Epoch.SnapShotsSpec as SnapShotsSpec
import qualified Test.Cardano.Ledger.StorableSpec as StorableSpec
import qualified Test.Cardano.Ledger.StrictlyPositiveCoinSpec as StrictlyPositiveCoinSpec
import qualified Test.Cardano.Ledger.ToolsSpec as ToolsSpec

main :: IO ()
main =
  ledgerTestMain $
    describe "Core" $ do
      AddressSpec.spec
      BaseTypesSpec.spec
      BinarySpec.spec
      JsonSpec.spec
      LeiosCommitteeSpec.spec
      PlutusSpec.spec
      SnapShotsSpec.spec
      StakePoolSpec.spec
      StorableSpec.spec
      StrictlyPositiveCoinSpec.spec
      ToolsSpec.spec
