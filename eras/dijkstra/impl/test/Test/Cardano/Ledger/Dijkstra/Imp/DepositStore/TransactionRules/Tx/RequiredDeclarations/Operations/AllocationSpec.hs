{-# LANGUAGE TypeApplications #-}

-- | A body requiring Store allocations must declare its own deposit change.
-- Every new store-backed output requires an allocation. This concerns gross
-- allocations, regardless of whether releases make the net amount positive, zero
-- or negative. Phase-2 failure still checks presence but does not apply these allocations.
-- ∀ body: createdStoreBackedOutputs(body) ≠ ∅ ⇒ hasDeclaration(body).
-- Only the body's own regular outputs count, excluding collateral return and
-- outputs belonging to other bodies. The cases also distinguish own declarations
-- from parent or child declarations, which cannot substitute for the required field.
-- Isolated-validator success establishes presence only. Ledger scenarios must
-- also supply exact declarations, funding and witnesses. The standalone allocation
-- pair consumes only implicit inputs, so release cannot trigger presence.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.RequiredDeclarations.Operations.AllocationSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (IsPhase2Valid (..))
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreOutputDeclarationFailure (..),
  DijkstraSubUtxoPredFailure (..),
  DijkstraUtxoPredFailure (..),
  validateSubTxAllocationDeclarationPresence,
  validateTopTxAllocationDeclarationPresence,
 )
import Data.List.NonEmpty (NonEmpty (..))
import Test.Cardano.Ledger.Common (
  Spec,
  conjoin,
  counterexample,
  describe,
  forAll,
  prop,
  (===),
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.TopTx as TopTxDeclarations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output as Output
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Allocation as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Allocation
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Output (
  ExpectedSubmission (..),
  allocationPresenceScenarios,
 )
import Validation (Validation (..))

-- | Compare declaration presence with the explicit result in each domain case.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION - ∀ body: createdStoreBackedOutputs(body) ≠ ∅ ⇒ hasDeclaration(body)" $ do
    -- Presence alone does not establish ledger acceptance. An explicit operation
    -- may satisfy this predicate while failing amount, funding or settlement rules.
    -- N01, N02 and F01 exercise only this presence predicate for both body levels.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N01 - Every explicit declaration satisfies allocation presence" $ \amount outputIndex ->
      forAll Output.storeBackedOutputCases $ \cases ->
        conjoin
          [ counterexample (show outputs) $ conjoin
              [ conjoin
                  [ counterexample (show declaration) $
                      validateTopTxAllocationDeclarationPresence (Output.topTxBody outputs declaration) === Success ()
                  | declaration <- TopTxDeclarations.onlyExplicitDeclarations amount outputIndex
                  ]
              , conjoin
                  [ counterexample (show declaration) $
                      validateSubTxAllocationDeclarationPresence (Output.subTxBody outputs declaration) === Success ()
                  | declaration <- SubTx.onlyExplicitDeclarations amount outputIndex
                  ]
              ]
          | outputs <- cases
          ]
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N02 - Absence satisfies allocation presence for empty or implicit-only own outputs" $
      forAll Output.implicitOutputCases $ \cases ->
        conjoin
          [ conjoin
              [ validateTopTxAllocationDeclarationPresence (Output.topTxBody outputs TopTx.NoUTxODepositDeclaration) === Success ()
              , validateSubTxAllocationDeclarationPresence (Output.subTxBody outputs SubTx.NoUTxODepositDeclaration) === Success ()
              ]
          | outputs <- cases
          ]
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F01 - Missing declaration fails allocation presence at every own-output position" $
      forAll Output.storeBackedOutputCases $ \cases ->
        conjoin
          [ counterexample (show outputs) $ conjoin
              [ validateTopTxAllocationDeclarationPresence (Output.topTxBody outputs TopTx.NoUTxODepositDeclaration) === missingOwnDeclaration
              , validateSubTxAllocationDeclarationPresence (Output.subTxBody outputs SubTx.NoUTxODepositDeclaration) === missingOwnDeclaration
              ]
          | outputs <- cases
          ]
    allocationPresenceScenarios
      [ ( "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N03 - accepts a TopTx creating only implicit outputs without a declaration"
        , Output.TxOutputs TopTx.NoUTxODepositDeclaration [Output.ImplicitOutput] []
        , Phase2Valid, Accepted
        )
      , ( "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N04 - accepts a SubTx creating only implicit outputs without either body's declaration"
        , Output.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Output.ImplicitOutput])]
        , Phase2Valid, Accepted
        )
      ]

    -- Shared context for N05 and F02:
    -- subTxs = ∅
    -- spentStoreBackedOutputs(topTx) = ∅
    -- createdStoreBackedOutputs(topTx) ≠ ∅
    -- No existing deposit is released; all newly required deposits must be funded.
    --
    -- Standalone TopTx, exact allocation declaration.
    -- declaredNetDeposit(topTx) = allocatedDeposits(topTx) ⇒ Accepted.
    -- Funding, fees, witnesses and all other ledger requirements are satisfied.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N05 - subTxs = ∅ ∧ spentStoreBackedOutputs(topTx) = ∅ ∧ createdStoreBackedOutputs(topTx) ≠ ∅ ∧ declaredNetDeposit(topTx) = allocatedDeposits(topTx) ⇒ Accepted" $
      forAllStandaloneAllocationTx TopTx.standaloneTopTxAllocatingDeposits $ \topTxWithoutTopDeclaration ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositAllocation
                (positiveAmount $ unCoin $ TopTx.allocatedDeposits topTxWithoutTopDeclaration))
              [])
            topTxWithoutTopDeclaration)
          >>= submitTx >>= isAccepted

    -- Standalone TopTx, allocation without a declaration.
    -- ¬hasDeclaration(topTx) ⇒ RejectedWith(MissingUTxODepositDeclaration).
    -- Remove only the declaration from the valid signed proposal, then re-sign.
    -- Inputs, outputs and fees stay unchanged. Other failures may accompany the
    -- required presence failure; the original signed control must be accepted.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F02 - subTxs = ∅ ∧ spentStoreBackedOutputs(topTx) = ∅ ∧ createdStoreBackedOutputs(topTx) ≠ ∅ ∧ ¬hasDeclaration(topTx) ⇒ RejectedWith(MissingUTxODepositDeclaration)" $
      forAllStandaloneAllocationTx TopTx.standaloneTopTxAllocatingDeposits $ \topTxWithoutTopDeclaration -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations
                (TopTx.DeclaresNetUTxODepositAllocation
                  (positiveAmount $ unCoin $ TopTx.allocatedDeposits topTxWithoutTopDeclaration))
                [])
              topTxWithoutTopDeclaration)
        removeTopTxDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    allocationPresenceScenarios
      [ ( "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F03 - rejects a SubTx creating a store-backed output without its own declaration"
        , Output.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Output.StoreBackedOutput])]
        , Phase2Valid, RejectedSubTx SubMissingUTxODepositDeclaration
        )
      , ( "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F04 - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails"
        , Output.TxOutputs TopTx.NoUTxODepositDeclaration [Output.StoreBackedOutput] []
        , Phase2Invalid, RejectedTopTx MissingUTxODepositDeclaration
        )
      , ( "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F05 - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails"
        , Output.TxOutputs TopTx.NoUTxODepositDeclaration [] [(SubTx.NoUTxODepositDeclaration, [Output.StoreBackedOutput])]
        , Phase2Invalid, RejectedSubTx SubMissingUTxODepositDeclaration
        )
      ]
    -- A translated Conway output has no recorded Store deposit. Consuming it
    -- releases nothing, but the new store-backed outputs still require allocation.
    -- Remove only the declaration, then submit the exact declared control.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F06 - rejects a missing own declaration when spending a translated implicit output to create store-backed outputs" $
      forAllPostConwayAllocationTx TopTx.standaloneTopTxAllocatingDeposits $ \topTxWithoutTopDeclaration -> do
        signedTx <-
          buildAndSignTx
            (TopTx.addDeclaration
              (Declarations
                (TopTx.DeclaresNetUTxODepositAllocation
                  (positiveAmount $ unCoin $ TopTx.allocatedDeposits topTxWithoutTopDeclaration))
                [])
              topTxWithoutTopDeclaration)
        removeTopTxDeclaration signedTx
          >>= submitTx >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
        submitTx signedTx >>= isAccepted

    -- Only the SubTx creates store-backed outputs; TopTx has no own outputs.
    -- createdStoreBackedOutputs(topTx) = ∅ ⇒ AllocationPresenceSatisfied(topTx).
    -- The child declares zero, so its declaration still requires TopTx's declaration.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N06 - SubTx outputs do not trigger TopTx allocation presence" $
      forAll Output.storeBackedOutputCases $ \cases ->
        conjoin
          [ validateTopTxAllocationDeclarationPresence (Output.topTxBodyWithNestedOutputs (outputs {Output.outputVariants = []}) outputs) === Success ()
          | outputs <- cases
          ]

    -- A store-backed collateral return is not a regular created output.
    -- createdStoreBackedOutputs(topTx) = ∅ ⇒ AllocationPresenceSatisfied(topTx).
    -- This does not validate collateral funding or settlement.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N07 - Collateral return does not trigger allocation presence" $ \address ->
      validateTopTxAllocationDeclarationPresence (Output.topTxBodyWithCollateralReturn address) === Success ()

    -- The same generated identifier populates reference and collateral inputs.
    -- No UTxO lookup occurs: this checks field exclusion by the allocation-presence validator,
    -- not the validity or deposit form of any referenced or collateral output.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N08 - Reference and collateral input identifiers do not trigger allocation presence" $ \input ->
      validateTopTxAllocationDeclarationPresence (Output.topTxBodyWithReferenceAndCollateralInputs input) === Success ()

    -- Both bodies create store-backed outputs, but only the SubTx declares.
    -- createdStoreBackedOutputs(topTx) ≠ ∅ ∧ ¬hasDeclaration(topTx)
    --   ⇒ AllocationPresenceFails(topTx, MissingBodyUTxODepositDeclaration).
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F07 - A SubTx declaration cannot satisfy TopTx allocation presence" $
      forAll Output.storeBackedOutputCases $ \cases ->
        conjoin
          [ validateTopTxAllocationDeclarationPresence (Output.topTxBodyWithNestedOutputs outputs outputs) === missingOwnDeclaration
          | outputs <- cases
          ]

    -- TopTx declares zero; its allocating SubTx omits its own declaration.
    -- createdStoreBackedOutputs(subTx) ≠ ∅ ∧ ¬hasDeclaration(subTx)
    --   ⇒ RejectedWith(SubMissingUTxODepositDeclaration).
    -- Parent exactness can also fail; that cannot replace the child's presence failure.
    allocationPresenceScenarios
      [ ( "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-F08 - TopTx zero cannot satisfy its allocating SubTx's declaration requirement"
        , Output.TxOutputs TopTx.DeclaresZeroNetUTxODeposit [] [(SubTx.NoUTxODepositDeclaration, [Output.StoreBackedOutput])]
        , Phase2Valid, RejectedIncludingSubTx SubMissingUTxODepositDeclaration
        )
      ]

    -- Both bodies create store-backed outputs and release no deposits.
    -- Each declares: TopTx the complete allocation, SubTx its own contribution.
    -- subTxs = {subTx} ∧ ∀ body ∈ {topTx, subTx}:
    -- createdStoreBackedOutputs(body) ≠ ∅ ∧ spentStoreBackedOutputs(body) = ∅.
    -- Accepted requires exact amounts, sufficient funding, fees and witnesses.
    prop "DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ALLOCATION-N09 - TopTx and SubTx allocate deposits, each with an exact declaration" $
      forAllTopTxAndSubTxAllocationTx TopTx.topTxAndSubTxAllocatingDeposits $ \topTxWithoutDeclarations ->
        buildAndSignTx
          (TopTx.addDeclaration
            (Declarations
              (TopTx.DeclaresNetUTxODepositAllocation
                (positiveAmount $ unCoin $ TopTx.allocatedDeposits topTxWithoutDeclarations))
              [ SubTx.DeclaresNetUTxODepositAllocation (positiveAmount $ unCoin $ allocation)
              | allocation <- TopTx.subTxAllocatedDeposits topTxWithoutDeclarations
              ])
            topTxWithoutDeclarations)
          >>= submitTx >>= isAccepted
{- FOURMOLU_ENABLE -}

-- | Expected isolated-validator failure for a missing declaration on an active body.
missingOwnDeclaration :: Validation (NonEmpty DepositStoreOutputDeclarationFailure) ()
missingOwnDeclaration = Failure (MissingBodyUTxODepositDeclaration :| [])
