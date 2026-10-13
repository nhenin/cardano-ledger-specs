-- | Scope activity determines whether each body needs its own declaration.
-- Isolated-validator success establishes presence only. Ledger acceptance uses
-- implicit outputs; pending spending and accounting rules remain explicit backlog.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.Activity.ScopeSpec (spec) where

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
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.TopTx as TopTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output as Output
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Output (
  ExpectedSubmission (..),
  outputCreationScenarios,
 )
import Validation (Validation (..))

-- | Compare declaration presence with the explicit result in each domain case.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-PRESENCE-ACTIVITY-SCOPE - Scope" $ do
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-N01 - accepts an absent TopTx declaration for creation presence when only its nested SubTx creates store-backed outputs" $
      forAll Output.storeBackedOutputCases $ \cases ->
        conjoin
          [ validateTopTxCreatedOutputsDeclaration (Output.topTxBodyWithNestedOutputs (outputs {Output.outputVariants = []}) outputs) === Success ()
          | outputs <- cases
          ]
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-N02 - accepts an absent declaration for creation presence when only collateral return is store-backed" $ \address ->
      validateTopTxCreatedOutputsDeclaration (Output.topTxBodyWithCollateralReturn address) === Success ()
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-N03 - accepts an absent declaration for creation presence with reference or collateral input identifiers alone" $ \input ->
      validateTopTxCreatedOutputsDeclaration (Output.topTxBodyWithReferenceAndCollateralInputs input) === Success ()
    prop "DS-TX-PRESENCE-ACTIVITY-SCOPE-F01 - rejects a missing TopTx declaration for its own store-backed outputs even when its nested SubTx declares" $
      forAll Output.storeBackedOutputCases $ \cases ->
        conjoin
          [ validateTopTxCreatedOutputsDeclaration (Output.topTxBodyWithNestedOutputs outputs outputs) === missingOwnDeclaration
          | outputs <- cases
          ]
    outputCreationScenarios
      [ ( "DS-TX-PRESENCE-ACTIVITY-SCOPE-F02 - rejects a creating SubTx's missing declaration even when TopTx explicitly declares zero"
        , Output.TxOutputs TopTx.DeclaresZeroNetUTxODeposit [] [(SubTx.NoUTxODepositDeclaration, [Output.StoreBackedOutput])]
        , Phase2Valid, RejectedSubTx SubMissingUTxODepositDeclaration
        )
      ]
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-N04 - does not require a declaration merely for referencing a store-backed output" referenceInputsNeedNoDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-N05 - does not treat collateral inputs or collateral return as ordinary Store activity" collateralIsNotOrdinaryStoreActivity
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-N06 - accepts Store activity in both TopTx and SubTx when each provides its own declaration" acceptsEachActiveBodyWithOwnDeclaration
    it "DS-TX-PRESENCE-ACTIVITY-SCOPE-F03 - rejects a missing TopTx spending declaration even when a SubTx declares" subTxDeclarationCannotReplaceTopTxDeclaration
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

-- | Rejects a missing TopTx spending declaration even when a SubTx declares
-- Executable backlog: replace with a ledger check against independent expectations.
subTxDeclarationCannotReplaceTopTxDeclaration :: Expectation
subTxDeclarationCannotReplaceTopTxDeclaration = False `shouldBe` True
