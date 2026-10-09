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
-- Category names, case titles and order mirror DS-TX-009 in the rules document.
-- Cases remain together within each domain category, with IDs identifying their
-- outcomes. The adapter registers a separate ledger test for each row. The universal
-- property covers both outcomes; fixture integrity is checked separately.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-009 - A SubTx declaration requires a TopTx declaration" $ do
    describe "DS-TX-009-C01 - Declaration dependency" $
      prop "DS-TX-009-C01-P01 - any SubTx has a declaration ⇒ TopTx has a declaration" $
        Fixture.forAllCases $ validateDeclaration `conformsTo` subTxDeclarationImpliesATopTxOne

    describe "DS-TX-009-C02 - Absence and explicit zero" $
      declarationScenarios
        [ ( "DS-TX-009-C02-N01 - accepts absent declarations at both levels"
          , Declarations TopTx.NoUTxODepositDeclaration [SubTx.NoUTxODepositDeclaration]
          , Phase2Valid, Accepted
          )
        , ( "DS-TX-009-C02-N02 - accepts explicit zero at both levels"
          , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Valid, Accepted
          )
        , ( "DS-TX-009-C02-N03 - accepts TopTx zero without a SubTx declaration"
          , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.NoUTxODepositDeclaration]
          , Phase2Valid, Accepted
          )
        , ( "DS-TX-009-C02-F01 - rejects SubTx zero without a TopTx declaration"
          , Declarations TopTx.NoUTxODepositDeclaration [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Valid, Rejected MissingTopTxUTxODepositDeclaration
          )
        ]
    describe "DS-TX-009-C03 - Equal allocations and releases" $ do
      prop "DS-TX-009-C03-N01 - passes declaration presence with TopTx declaring the zero net amount" $
        forAll Fixture.equalLocalAllocationAndRelease $ \subTxDeclarations ->
          validateDeclaration (Declarations TopTx.DeclaresZeroNetUTxODeposit subTxDeclarations) === Success ()
      prop "DS-TX-009-C03-F01 - rejects an absent TopTx declaration despite the zero net amount" $
        forAll Fixture.equalLocalAllocationAndRelease $ \subTxDeclarations ->
          validateDeclaration (Declarations TopTx.NoUTxODepositDeclaration subTxDeclarations) === missingTopDeclarationFailure

    describe "DS-TX-009-C04 - Local and delegated accounting" $ do
      prop "DS-TX-009-C04-N01 - passes declaration presence with TopTx zero for every explicit SubTx form" $
        forAll Fixture.onlyExplicitSubTxDeclarations $ \subTxDeclarations ->
          conjoin
            [ validateDeclaration (Declarations TopTx.DeclaresZeroNetUTxODeposit [subTxDeclaration]) === Success ()
            | subTxDeclaration <- subTxDeclarations
            ]
      prop "DS-TX-009-C04-F01 - rejects an absent TopTx declaration for every explicit SubTx form" $
        forAll Fixture.onlyExplicitSubTxDeclarations $ \subTxDeclarations ->
          conjoin
            [ validateDeclaration (Declarations TopTx.NoUTxODepositDeclaration [subTxDeclaration]) === missingTopDeclarationFailure
            | subTxDeclaration <- subTxDeclarations
            ]

    describe "DS-TX-009-C05 - Phase-2 failure" $
      declarationScenarios
        [ ( "DS-TX-009-C05-N01 - accepts zero declarations at both levels on the phase-2 failure path"
          , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Invalid, Accepted
          )
        , ( "DS-TX-009-C05-F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path"
          , Declarations TopTx.NoUTxODepositDeclaration [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Invalid, Rejected MissingTopTxUTxODepositDeclaration
          )
        ]

    describe "DS-TX-009-C06 - Fixture integrity" $
      prop "DS-TX-009-C06-P01 - preserves the number of SubTxs, including those with repeated declarations" $
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
