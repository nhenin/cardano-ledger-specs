-- | Creation activity determines whether each body needs its own declaration.
-- Isolated-validator success establishes presence only. Ledger acceptance uses
-- implicit outputs; pending spending and accounting rules remain explicit backlog.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.Activity.CreationSpec (spec) where

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
  describe "DS-TX-PRESENCE-ACTIVITY-CREATION - Creation" $ do
    prop "DS-TX-PRESENCE-ACTIVITY-CREATION-N01 - accepts every explicit TopTx and SubTx declaration for creation presence, including zero and delegation" $ \amount outputIndex ->
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
    prop "DS-TX-PRESENCE-ACTIVITY-CREATION-N02 - accepts absent declarations for empty or implicit-only own outputs" $
      forAll Fixture.implicitOutputCases $ \cases ->
        conjoin
          [ conjoin
              [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBody outputs TopTx.NoUTxODepositDeclaration) === Success ()
              , validateSubTxCreatedOutputsDeclaration (Adapter.subTxBody outputs SubTx.NoUTxODepositDeclaration) === Success ()
              ]
          | outputs <- cases
          ]
    prop "DS-TX-PRESENCE-ACTIVITY-CREATION-F01 - rejects a missing own declaration when a store-backed output appears at any own-output position" $
      forAll Fixture.storeBackedOutputCases $ \cases ->
        conjoin
          [ counterexample (show outputs) $ conjoin
              [ validateTopTxCreatedOutputsDeclaration (Adapter.topTxBody outputs TopTx.NoUTxODepositDeclaration) === missingOwnDeclaration
              , validateSubTxCreatedOutputsDeclaration (Adapter.subTxBody outputs SubTx.NoUTxODepositDeclaration) === missingOwnDeclaration
              ]
          | outputs <- cases
          ]
    outputCreationScenarios
      [ ( "DS-TX-PRESENCE-ACTIVITY-CREATION-N03 - accepts a TopTx creating only implicit outputs without a declaration"
        , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [Fixture.ImplicitOutput] []
        , Phase2Valid, Accepted
        )
      , ( "DS-TX-PRESENCE-ACTIVITY-CREATION-N04 - accepts a SubTx creating only implicit outputs without either body's declaration"
        , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Fixture.ImplicitOutput])]
        , Phase2Valid, Accepted
        )
      , ( "DS-TX-PRESENCE-ACTIVITY-CREATION-F02 - rejects a TopTx creating a store-backed output without its own declaration"
        , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [Fixture.StoreBackedOutput] []
        , Phase2Valid, RejectedTopTx MissingUTxODepositDeclaration
        )
      , ( "DS-TX-PRESENCE-ACTIVITY-CREATION-F03 - rejects a SubTx creating a store-backed output without its own declaration"
        , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Fixture.StoreBackedOutput])]
        , Phase2Valid, RejectedSubTx SubMissingUTxODepositDeclaration
        )
      , ( "DS-TX-PRESENCE-ACTIVITY-CREATION-F04 - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails"
        , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [Fixture.StoreBackedOutput] []
        , Phase2Invalid, RejectedTopTx MissingUTxODepositDeclaration
        )
      , ( "DS-TX-PRESENCE-ACTIVITY-CREATION-F05 - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails"
        , Fixture.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Fixture.StoreBackedOutput])]
        , Phase2Invalid, RejectedSubTx SubMissingUTxODepositDeclaration
        )
      ]
    it "DS-TX-PRESENCE-ACTIVITY-CREATION-F06 - rejects a missing allocation declaration when spending a translated implicit output to create store-backed outputs" rejectsMissingPostConwayAllocation
{- FOURMOLU_ENABLE -}

-- | Expected isolated-validator failure for a missing declaration on an active body.
missingOwnDeclaration :: Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
missingOwnDeclaration = Failure (MissingBodyUTxODepositDeclaration :| [])

-- | Rejects a missing allocation declaration when spending a translated implicit output to create store-backed outputs
-- Executable backlog: replace with a ledger check against independent expectations.
rejectsMissingPostConwayAllocation :: Expectation
rejectsMissingPostConwayAllocation = False `shouldBe` True
