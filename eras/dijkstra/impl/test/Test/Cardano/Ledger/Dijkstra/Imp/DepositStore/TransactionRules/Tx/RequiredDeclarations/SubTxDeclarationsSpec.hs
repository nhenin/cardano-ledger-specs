-- | DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS: an explicit SubTx UTxO capacity deposit declaration requires a
-- TopTx declaration. Declaring zero still counts, and delegating an operation
-- to TopTx does not remove this requirement.
--
-- This obligation follows the explicit child declaration even when TopTx has
-- no own Store operations. TopTx declaring does not require an inactive child
-- to declare. Each active body must still supply its own declaration field.
--
-- This module checks declaration presence. Exact amounts, settlement outputs
-- and Deposit Store accounting are covered by separate rules.
--
-- The ledger scenarios submit funded batches with implicit-deposit outputs and
-- no Store operations. The domain properties exercise the
-- declaration validator directly, including nonzero operations, without submitting
-- a batch. Fixture integrity is checked separately in the technical fixture test.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.RequiredDeclarations.SubTxDeclarationsSpec (spec) where

import Cardano.Ledger.Dijkstra.Core (
  IsPhase2Valid (..),
 )
import Cardano.Ledger.Dijkstra.Rules (
  DijkstraUtxoPredFailure (..),
 )
import Test.Cardano.Ledger.Common (
  Spec,
  conjoin,
  describe,
  forAll,
  prop,
  (===),
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Assertions (conformsTo)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (
  Declarations (Declarations),
  missingTopDeclarationFailure,
  subTxDeclarationImpliesATopTxOne,
  validateDeclaration,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration as Declaration
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.TopTx as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Declaration (
  ExpectedSubmission (..),
  declarationScenarios,
 )
import Validation (Validation (..))

-- | The table states each requirement alongside its declarations, phase-2
-- outcome and expected result. All rows have implicit-deposit outputs and no
-- Store operations; absence and explicit zero remain distinct.
--
-- Category names, case titles and order mirror DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS in the rules document.
-- Cases remain together within each domain category, with IDs identifying their
-- outcomes. The adapter registers a separate ledger test for each row. The universal
-- property covers both outcomes; fixture integrity is checked separately.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS - A SubTx declaration requires a TopTx declaration" $ do
    describe "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C01 - TopTx requirement" $
      prop "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C01-P01 - any SubTx has a declaration ⇒ TopTx has a declaration" $
        Declaration.forAllCases $ validateDeclaration `conformsTo` subTxDeclarationImpliesATopTxOne

    describe "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C02 - Absence and explicit zero" $
      declarationScenarios
        [ ( "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C02-N01 - accepts absent declarations at both levels"
          , Declarations TopTx.NoUTxODepositDeclaration [SubTx.NoUTxODepositDeclaration]
          , Phase2Valid, Accepted
          )
        , ( "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C02-N02 - accepts explicit zero at both levels"
          , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Valid, Accepted
          )
        , ( "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C02-N03 - accepts TopTx zero without a SubTx declaration"
          , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.NoUTxODepositDeclaration]
          , Phase2Valid, Accepted
          )
        , ( "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C02-F01 - rejects SubTx zero without a TopTx declaration"
          , Declarations TopTx.NoUTxODepositDeclaration [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Valid, Rejected MissingTopTxUTxODepositDeclaration
          )
        ]
    -- Two SubTxs declare opposite nonzero contributions. Their sum is zero,
    -- but both explicit declarations still require TopTx to declare.
    describe "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C03 - Offsetting SubTx contributions" $ do
      prop "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C03-N01 - passes declaration presence with TopTx declaring the zero net amount" $
        forAll Declaration.equalLocalAllocationAndRelease $ \subTxDeclarations ->
          validateDeclaration (Declarations TopTx.DeclaresZeroNetUTxODeposit subTxDeclarations) === Success ()
      prop "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C03-F01 - rejects an absent TopTx declaration despite the zero net amount" $
        forAll Declaration.equalLocalAllocationAndRelease $ \subTxDeclarations ->
          validateDeclaration (Declarations TopTx.NoUTxODepositDeclaration subTxDeclarations) === missingTopDeclarationFailure

    describe "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C04 - Local and delegated accounting" $ do
      prop "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C04-N01 - passes declaration presence with TopTx zero for every explicit SubTx form" $
        forAll Declaration.onlyExplicitSubTxDeclarations $ \subTxDeclarations ->
          conjoin
            [ validateDeclaration (Declarations TopTx.DeclaresZeroNetUTxODeposit [subTxDeclaration]) === Success ()
            | subTxDeclaration <- subTxDeclarations
            ]
      prop "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C04-F01 - rejects an absent TopTx declaration for every explicit SubTx form" $
        forAll Declaration.onlyExplicitSubTxDeclarations $ \subTxDeclarations ->
          conjoin
            [ validateDeclaration (Declarations TopTx.NoUTxODepositDeclaration [subTxDeclaration]) === missingTopDeclarationFailure
            | subTxDeclaration <- subTxDeclarations
            ]

    describe "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C05 - Phase-2 failure" $
      declarationScenarios
        [ ( "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C05-N01 - accepts zero declarations at both levels on the phase-2 failure path"
          , Declarations TopTx.DeclaresZeroNetUTxODeposit [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Invalid, Accepted
          )
        , ( "DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS-C05-F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path"
          , Declarations TopTx.NoUTxODepositDeclaration [SubTx.DeclaresZeroNetUTxODeposit]
          , Phase2Invalid, Rejected MissingTopTxUTxODepositDeclaration
          )
        ]

{- FOURMOLU_ENABLE -}
