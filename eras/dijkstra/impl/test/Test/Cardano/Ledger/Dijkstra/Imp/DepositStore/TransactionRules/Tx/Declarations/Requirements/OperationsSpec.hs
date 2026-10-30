{-# LANGUAGE TypeApplications #-}

-- | Declaration presence for Store operations proposed by each body.
-- Allocation creates deposit records for new store-backed outputs; release removes
-- records for consumed store-backed outputs. Both may occur in one transaction.
-- These are gross operations: netDepositChange = allocatedDeposits - releasedDeposits.
-- Presence depends on store-backed output form, including when its priced amount is zero.
--
-- Contract: for accepted transactions on either phase-2 outcome, inspect each
-- body's hypothetical ordinary inputs and outputs. Presence requires its own
-- field; TopTx's amount still declares the complete batch, not its own contribution.
-- Accepted-case coverage must include both outcomes and both body levels.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.OperationsSpec (spec) where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core (IsPhase2Valid (..))
import Cardano.Ledger.Dijkstra.Rules (DijkstraSubUtxoPredFailure (..), DijkstraUtxoPredFailure (..))
import Test.Cardano.Ledger.Common (Spec, describe, forAll, forM_, prop)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Operations as Operations
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Operations (fundOperations)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  buildAndSignPhase2InvalidTx,
  buildAndSignTx,
  isAccepted,
  isRejectedWith,
  removeSubTxReleaseDeclarationByInput,
  removeTopTxReleaseDeclaration,
  submitTx,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.Operations.AllocationSpec as Allocation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.Operations.ReleaseSpec as Release
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Declarations.Requirements.Operations.ZeroNetChangeSpec as ZeroNetChange
import Test.Cardano.Ledger.Dijkstra.ImpTest (getIndexedUTxOs)

-- | Register the requirements in domain order.
spec :: Spec
spec = describe
  "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS - Each body performing Store operations must declare"
  $ do
    prop
      "DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-P01 - accepted transaction ⇒ every body requiring Store allocations or releases has its own declaration"
      $ forAll Operations.independentBodyOperations
      $ \scenario ->
        -- Zero price makes every exact amount zero, but never removes an output's
        -- store-backed form. Each body independently allocates, releases, does both,
        -- or does neither. Ordinary success and actual phase-2 failure run for
        -- every scenario; the failure path includes a genuinely failing script.
        forM_ [Phase2Valid, Phase2Invalid] $ \phase2 -> do
          proposal <- fundOperations scenario
          let declaredTx =
                TopTx.addDeclaration
                  ( Declarations
                      TopTx.DeclaresZeroNetUTxODeposit
                      (replicate (length $ Operations.subTxOperations scenario) SubTx.DeclaresZeroNetUTxODeposit)
                  )
                  proposal
          signedTx <- case phase2 of
            Phase2Valid -> buildAndSignTx declaredTx
            Phase2Invalid -> buildAndSignPhase2InvalidTx declaredTx
          previousAllocations <- getIndexedUTxOs
          -- Read activity from each body's own resolved inputs and proposed outputs.
          -- Remove each required field independently: other bodies still declare.
          forM_ (Operations.requiredDeclarationOwners previousAllocations signedTx) $ \owner ->
            case owner of
              Operations.TopTxBody ->
                removeTopTxReleaseDeclaration signedTx
                  >>= submitTx
                  >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
              Operations.SubTxBody input ->
                removeSubTxReleaseDeclarationByInput input signedTx
                  >>= submitTx
                  >>= isRejectedWith (SubMissingUTxODepositDeclaration @DijkstraEra)
          -- Acceptance is checked for every generated scenario, never inferred
          -- from the fact that its incomplete variants were rejected.
          submitTx signedTx >>= isAccepted
    Allocation.spec
    Release.spec
    ZeroNetChange.spec
