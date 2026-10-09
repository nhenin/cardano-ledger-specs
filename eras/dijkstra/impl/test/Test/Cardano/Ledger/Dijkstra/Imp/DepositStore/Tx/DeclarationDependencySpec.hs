-- | DS-TX-009: an explicit SubTx UTxO capacity deposit declaration requires a
-- TopTx declaration. Declaring zero still counts, and delegating an operation
-- to TopTx does not remove this requirement.
--
-- This module checks declaration presence. Exact amounts, settlement outputs
-- and Deposit Store accounting are covered by separate rules.
--
-- The ledger scenarios submit funded batches with implicit-deposit outputs and
-- no Store activity. The domain properties exercise the
-- declaration validator directly, including nonzero operations, without submitting
-- a batch. A separate fixture property checks that body construction retains the
-- number of SubTxs, including those with repeated declarations.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DeclarationDependencySpec (spec) where

import Cardano.Ledger.Dijkstra.Core (
  IsPhase2Valid (..),
  subTransactionsTxBodyL,
 )
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreDeclarationFailure (..),
  DijkstraUtxoPredFailure (..),
  validateTopTxNetUTxODepositDeclaration,
 )
import Data.List.NonEmpty (NonEmpty (..))
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (
  Spec,
  conjoin,
  describe,
  forAll,
  prop,
  (===),
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Assertions (conformsTo)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.DeclarationScenarios (
  ExpectedSubmission (..),
  declarationScenarios,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.TopTx as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.DeclarationDependency (
  Declarations (Declarations),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.DeclarationDependency as Fixture
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Transaction (declarationToTxBody)
import Validation (Validation (..))

-- | The table states each requirement alongside its declarations, phase-2
-- outcome and expected result. All rows have implicit-deposit outputs and no
-- Store activity; absence and explicit zero remain distinct.
--
-- The adapter registers a separate ledger test for each row. The domain property
-- compares the validator with the rule; fixture construction is checked separately.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "A SubTx declaration requires a TopTx declaration (DS-TX-009)" $ do
    prop "any SubTx has a declaration ⇒ TopTx has a declaration" $
      Fixture.forAllCases $ validateDeclaration `conformsTo` subTxDeclarationImpliesATopTxOne
    prop "requires a TopTx declaration even when SubTx allocations equal releases, resulting in a zero net amount" $
      forAll Fixture.equalLocalAllocationAndRelease $ \subTxDeclarations ->
        conjoin
          [ validateDeclaration (Declarations TopTx.NoUTxODepositDeclaration subTxDeclarations) === missingTopDeclarationFailure
          , validateDeclaration (Declarations TopTx.DeclaresZeroNetUTxODeposit subTxDeclarations) === Success ()
          ]
    prop "requires a TopTx declaration whether SubTx allocations and releases are accounted for locally or delegated to TopTx" $
      forAll Fixture.onlyExplicitSubTxDeclarations $ \subTxDeclarations ->
        conjoin
          [ conjoin
              [ validateDeclaration (Declarations TopTx.NoUTxODepositDeclaration [subTxDeclaration]) === missingTopDeclarationFailure
              , validateDeclaration (Declarations TopTx.DeclaresZeroNetUTxODeposit [subTxDeclaration]) === Success ()
              ]
          | subTxDeclaration <- subTxDeclarations
          ]
    declarationScenarios
        [ ( "accepts absent declarations on both levels when there is no Store activity"
            , Declarations TopTx.NoUTxODepositDeclaration [SubTx.NoUTxODepositDeclaration]
            , Phase2Valid, Accepted
            )
          , ( "rejects a SubTx zero declaration when TopTx declares nothing"
            , Declarations TopTx.NoUTxODepositDeclaration [SubTx.DeclaresZeroNetUTxODeposit]
            , Phase2Valid, Rejected MissingTopTxUTxODepositDeclaration
            )
          , ( "accepts zero declarations on both levels when there is no Store activity"
            , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]
            , Phase2Valid, Accepted
            )
          , ( "accepts a TopTx zero declaration without SubTx declarations when there is no Store activity"
            , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.NoUTxODepositDeclaration]
            , Phase2Valid, Accepted
            )
          , ( "accepts zero declarations on both levels when phase 2 fails and there is no Store activity"
            , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]
            , Phase2Invalid, Accepted
            )
          , ( "rejects a SubTx zero declaration without a TopTx declaration even when phase 2 fails"
            , Declarations TopTx.NoUTxODepositDeclaration [SubTx.DeclaresZeroNetUTxODeposit]
            , Phase2Invalid, Rejected MissingTopTxUTxODepositDeclaration
            )
          ]
    describe "Declaration fixture construction" $
      prop "preserves the number of SubTxs, including those with repeated declarations" $
        Fixture.forAllCases $ \declarations ->
          length (declarationToTxBody declarations ^. subTransactionsTxBodyL) === length (Fixture.subTxDeclarations declarations)
{- FOURMOLU_ENABLE -}

-- | Compute the expected result without using the production presence predicate.
-- Reject exactly when TopTx has no declaration and at least one SubTx declares
-- an operation, including zero. Success means only that DS-TX-009 is satisfied.
subTxDeclarationImpliesATopTxOne ::
  Declarations ->
  Validation (NonEmpty DepositStoreDeclarationFailure) ()
subTxDeclarationImpliesATopTxOne (Declarations TopTx.NoUTxODepositDeclaration subDeclarations)
  | any SubTx.isExplicitDeclaration subDeclarations = missingTopDeclarationFailure
  | otherwise = Success ()
subTxDeclarationImpliesATopTxOne _ = Success ()

-- | Build a body from the declarations fixture, run only the production
-- declaration dependency validator, and return its 'Validation' result for assertions.
-- The fixture uses distinct fictitious inputs; it is not a funded ledger batch.
validateDeclaration ::
  Declarations ->
  Validation (NonEmpty DepositStoreDeclarationFailure) ()
validateDeclaration =
  validateTopTxNetUTxODepositDeclaration . declarationToTxBody

-- | Expected isolated-validator failure when a SubTx declares but TopTx does not.
-- Ledger submission scenarios assert 'MissingTopTxUTxODepositDeclaration', the
-- corresponding failure exposed by the UTXO rule.
missingTopDeclarationFailure :: Validation (NonEmpty DepositStoreDeclarationFailure) ()
missingTopDeclarationFailure = Failure (MissingTopTxDeclaration :| [])
