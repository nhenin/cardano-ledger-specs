-- | The creation slice of DS-TX-001 checks each body's own ordinary outputs.
-- Isolated-validator success proves declaration presence only. Full-ledger
-- acceptance controls use implicit outputs; no unfunded Store allocation is
-- presented as valid. Spending and complete input/collateral rules remain pending.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DeclarationSpec (spec) where

import Cardano.Ledger.Dijkstra.Core (IsPhase2Valid (..))
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreOutputDeclarationFailure (..),
  DijkstraSubUtxoPredFailure (..),
  DijkstraUtxoPredFailure (..),
  validateSubTxCreatedOutputsDeclaration,
  validateTopTxCreatedOutputsDeclaration,
 )
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Common (
  Expectation,
  Spec,
  conjoin,
  counterexample,
  describe,
  forAll,
  it,
  prop,
  shouldBe,
  (===),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.TopTx as TopTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.OutputCreation as Fixture
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.OutputCreation (
  ExpectedSubmission (..),
  outputCreationScenarios,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.OutputCreation as Adapter
import Validation (Validation (..))

{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-001 - Each body declares its own Store activity" $ do
    describe "Declaration rule (nominal and failure cases)" $
      prop "A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change." storeActivityRequiresDeclaration
    describe "Created outputs" $ do
      describe "Nominal cases" $ do
        prop "accepts every explicit TopTx and SubTx declaration for creation presence, including zero and delegation" $ \amount outputIndex ->
          forAll Fixture.storeBackedOutputCases $ \cases ->
            conjoin
              [ counterexample (show outputs) $ conjoin
                  [ conjoin
                      [ counterexample (show declaration) $
                          validateTopTxCreatedOutputsDeclaration (Adapter.topTxBody outputs declaration) === Success ()
                      | declaration <- TopTx.onlyExplicitDeclarations amount outputIndex
                      ]
                  , conjoin
                      [ counterexample (show declaration) $
                          validateSubTxCreatedOutputsDeclaration (Adapter.subTxBody outputs declaration) === Success ()
                      | declaration <- SubTx.onlyExplicitDeclarations amount outputIndex
                      ]
                  ]
              | outputs <- cases
              ]
        prop "accepts absent declarations for empty or implicit-only own outputs" $
          forAll Fixture.implicitOutputCases $ \cases ->
            conjoin
              [ conjoin
                  [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBody outputs TopTx.NoUTxODepositDeclaration) === Success ()
                  , validateSubTxCreatedOutputsDeclaration (Adapter.subTxBody outputs SubTx.NoUTxODepositDeclaration) === Success ()
                  ]
              | outputs <- cases
              ]
        prop "accepts an absent TopTx declaration for creation presence when only its nested SubTx creates store-backed outputs" $
          forAll Fixture.storeBackedOutputCases $ \cases ->
            conjoin
              [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithNestedOutputs (outputs {Fixture.outputVariants = []}) outputs) === Success ()
              | outputs <- cases
              ]
        prop "accepts an absent declaration for creation presence when only collateral return is store-backed" $ \address ->
          validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithCollateralReturn address) === Success ()
        prop "accepts an absent declaration for creation presence with reference or collateral input identifiers alone" $ \input ->
          validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithReferenceAndCollateralInputs input) === Success ()
        outputCreationScenarios
          [ ( "accepts a TopTx creating only implicit outputs without a declaration"
            , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [Fixture.ImplicitOutput] []
            , Phase2Valid, Accepted
            )
          , ( "accepts a SubTx creating only implicit outputs without either body's declaration"
            , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Fixture.ImplicitOutput])]
            , Phase2Valid, Accepted
            )
          ]
      describe "Failure cases" $ do
        prop "rejects a missing own declaration when a store-backed output appears at any own-output position" $
          forAll Fixture.storeBackedOutputCases $ \cases ->
            conjoin
              [ counterexample (show outputs) $ conjoin
                  [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBody outputs TopTx.NoUTxODepositDeclaration) === missingOwnDeclaration
                  , validateSubTxCreatedOutputsDeclaration (Adapter.subTxBody outputs SubTx.NoUTxODepositDeclaration) === missingOwnDeclaration
                  ]
              | outputs <- cases
              ]
        prop "rejects a missing TopTx declaration for its own store-backed outputs even when its nested SubTx declares" $
          forAll Fixture.storeBackedOutputCases $ \cases ->
            conjoin
              [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBodyWithNestedOutputs outputs outputs) === missingOwnDeclaration
              | outputs <- cases
              ]
        outputCreationScenarios
          [ ( "rejects a TopTx creating a store-backed output without its own declaration"
            , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [Fixture.StoreBackedOutput] []
            , Phase2Valid, RejectedTopTx MissingUTxODepositDeclaration
            )
          , ( "rejects a SubTx creating a store-backed output without its own declaration"
            , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Fixture.StoreBackedOutput])]
            , Phase2Valid, RejectedSubTx SubMissingUTxODepositDeclaration
            )
          , ( "rejects a creating SubTx's missing declaration even when TopTx explicitly declares zero"
            , Fixture.TxOutputs TopTx.DeclaresZeroNetUTxODeposit [] [(SubTx.NoUTxODepositDeclaration, [Fixture.StoreBackedOutput])]
            , Phase2Valid, RejectedSubTx SubMissingUTxODepositDeclaration
            )
          , ( "rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails"
            , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [Fixture.StoreBackedOutput] []
            , Phase2Invalid, RejectedTopTx MissingUTxODepositDeclaration
            )
          , ( "rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails"
            , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Fixture.StoreBackedOutput])]
            , Phase2Invalid, RejectedSubTx SubMissingUTxODepositDeclaration
            )
          ]
    describe "Spent outputs" $ do
      describe "Nominal cases" $ do
        it "accepts a TopTx spending a store-backed input with its own declaration" acceptsSpendingTopTxWithOwnDeclaration
        it "accepts a SubTx spending a store-backed input with its own declaration" acceptsSpendingSubTxWithOwnDeclaration
      describe "Failure cases" $ do
        it "rejects a TopTx spending a store-backed input without a declaration" spendingTopTxInputRequiresDeclaration
        it "rejects a SubTx spending a store-backed input without its own declaration" spendingSubTxInputRequiresDeclaration
    describe "Reference inputs" $
      describe "Nominal cases" $
        it "does not require a declaration merely for referencing a store-backed output" referenceInputsNeedNoDeclaration
    describe "Collateral" $
      describe "Nominal cases" $
        it "does not treat collateral inputs or collateral return as ordinary Store activity" collateralIsNotOrdinaryStoreActivity
    describe "Declaration ownership" $ do
      describe "Nominal cases" $
        it "accepts Store activity in both TopTx and SubTx when each provides its own declaration" acceptsEachActiveBodyWithOwnDeclaration
      describe "Failure cases" $
        it "does not let a SubTx declaration replace a missing TopTx declaration" subTxDeclarationCannotReplaceTopTxDeclaration
{- FOURMOLU_ENABLE -}

missingOwnDeclaration :: Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
missingOwnDeclaration = Failure (MissingBodyUTxODepositDeclaration :| [])

-- | Deliberately failing executable backlog, outside the focused creation slice.
storeActivityRequiresDeclaration :: Bool
storeActivityRequiresDeclaration = False

-- | Nominal control for spendingTopTxInputRequiresDeclaration: retain TopTx's
-- required declaration in an otherwise valid store-backed spending transaction.
acceptsSpendingTopTxWithOwnDeclaration :: Expectation
acceptsSpendingTopTxWithOwnDeclaration = False `shouldBe` True

-- | Nominal control for spendingSubTxInputRequiresDeclaration: retain SubTx's
-- required declaration in an otherwise valid store-backed spending transaction.
acceptsSpendingSubTxWithOwnDeclaration :: Expectation
acceptsSpendingSubTxWithOwnDeclaration = False `shouldBe` True

spendingTopTxInputRequiresDeclaration :: Expectation
spendingTopTxInputRequiresDeclaration = False `shouldBe` True

spendingSubTxInputRequiresDeclaration :: Expectation
spendingSubTxInputRequiresDeclaration = False `shouldBe` True

-- | Both bodies have Store activity and each carries its required declaration.
-- Removing TopTx's declaration yields the corresponding ownership failure case.
acceptsEachActiveBodyWithOwnDeclaration :: Expectation
acceptsEachActiveBodyWithOwnDeclaration = False `shouldBe` True

subTxDeclarationCannotReplaceTopTxDeclaration :: Expectation
subTxDeclarationCannotReplaceTopTxDeclaration = False `shouldBe` True

referenceInputsNeedNoDeclaration :: Expectation
referenceInputsNeedNoDeclaration = False `shouldBe` True

collateralIsNotOrdinaryStoreActivity :: Expectation
collateralIsNotOrdinaryStoreActivity = False `shouldBe` True
