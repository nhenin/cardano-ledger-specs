-- | Scope activity determines whether each body needs its own declaration.
-- Isolated-validator success establishes presence only. Ledger acceptance uses
-- implicit outputs; pending spending and accounting rules remain explicit backlog.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.Activity.ScopeSpec (spec) where

import Cardano.Ledger.Dijkstra.Core (IsPhase2Valid (..))
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreOutputDeclarationFailure (..),
  DijkstraSubUtxoPredFailure (..),
  validateTopTxCreatedOutputsDeclaration,
 )
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Common (
  Expectation,
  Spec,
  conjoin,
  describe,
  forAll,
  it,
  prop,
  shouldBe,
  (===),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.TopTx as TopTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Fixture as Fixture
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Scenarios (
  ExpectedSubmission (..),
  outputCreationScenarios,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Transaction as Adapter
import Validation (Validation (..))

-- | Compare declaration presence with the explicit result in each domain case.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-PRESENCE-ACTIVITY-SCOPE - Scope" $ do
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-N01 - accepts an absent TopTx declaration for creation presence when only its nested SubTx creates store-backed outputs" $
      forAll Fixture.storeBackedOutputCases $ \cases ->
        conjoin
          [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithNestedOutputs (outputs {Fixture.outputVariants = []}) outputs) === Success ()
          | outputs <- cases
          ]
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-N02 - accepts an absent declaration for creation presence when only collateral return is store-backed" $ \address ->
      validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithCollateralReturn address) === Success ()
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-N03 - accepts an absent declaration for creation presence with reference or collateral input identifiers alone" $ \input ->
      validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithReferenceAndCollateralInputs input) === Success ()
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-F01 - rejects a missing TopTx declaration for its own store-backed outputs even when its nested SubTx declares" $
      forAll Fixture.storeBackedOutputCases $ \cases ->
        conjoin
          [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithNestedOutputs outputs outputs) === missingOwnDeclaration
          | outputs <- cases
          ]
    outputCreationScenarios
      [ ( "DS-TX-PRESENCE-ACTIVITY-SCOPE-F02 - rejects a creating SubTx's missing declaration even when TopTx explicitly declares zero"
        , Fixture.TxOutputs TopTx.DeclaresZeroNetUTxODeposit [] [(SubTx.NoUTxODepositDeclaration, [Fixture.StoreBackedOutput])]
        , Phase2Valid, RejectedSubTx SubMissingUTxODepositDeclaration
        )
      ]
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-N04 - does not require a declaration merely for referencing a store-backed output" referenceInputsNeedNoDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-N05 - does not treat collateral inputs or collateral return as ordinary Store activity" collateralIsNotOrdinaryStoreActivity
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-N06 - accepts Store activity in both TopTx and SubTx when each provides its own declaration" acceptsEachActiveBodyWithOwnDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-F03 - does not let a SubTx declaration replace a missing TopTx declaration" subTxDeclarationCannotReplaceTopTxDeclaration
{- FOURMOLU_ENABLE -}

-- | Expected isolated-validator failure for a missing declaration on an active body.
missingOwnDeclaration :: Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
missingOwnDeclaration = Failure (MissingBodyUTxODepositDeclaration :| [])

-- | Does not require a declaration merely for referencing a store-backed output
-- Executable backlog: replace with a ledger check against independent expectations.
referenceInputsNeedNoDeclaration :: Expectation
referenceInputsNeedNoDeclaration = False `shouldBe` True

-- | Does not treat collateral inputs or collateral return as ordinary Store activity
-- Executable backlog: replace with a ledger check against independent expectations.
collateralIsNotOrdinaryStoreActivity :: Expectation
collateralIsNotOrdinaryStoreActivity = False `shouldBe` True

-- | Accepts Store activity in both TopTx and SubTx when each provides its own declaration
-- Executable backlog: replace with a ledger check against independent expectations.
acceptsEachActiveBodyWithOwnDeclaration :: Expectation
acceptsEachActiveBodyWithOwnDeclaration = False `shouldBe` True

-- | Does not let a SubTx declaration replace a missing TopTx declaration
-- Executable backlog: replace with a ledger check against independent expectations.
subTxDeclarationCannotReplaceTopTxDeclaration :: Expectation
subTxDeclarationCannotReplaceTopTxDeclaration = False `shouldBe` True
