{-# LANGUAGE DataKinds #-}

-- | An unsigned release proposal together with its funded input context.
-- Accounting queries use the real recorded deposits and pricing parameters;
-- the calling spec supplies the declaration before building and signing.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (
  module Cardano.Ledger.Dijkstra.UTxODeposit.TopTx,
  ReleaseTx (..),
  standaloneTopTxAnyOutputForm,
  standaloneTopTxOnlyImplicitOutputs,
  standaloneTopTxWithStoreBackedReferenceInputs,
  standaloneTopTxWithEqualAllocationsAndReleases,
  allocatedDeposits,
  releasedDeposits,
  netDeposit,
  addDeclaration,
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxODeposit.TopTx
import Cardano.Ledger.Shelley.LedgerState (utxosDepositStore)
import Cardano.Ledger.State (depositStoreAllocations)
import Cardano.Ledger.Val (Val ((<->)))
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (
  createdOrdinaryOutputs,
  ordinarySpendingInputs,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx (
  standaloneTopTxAnyOutputForm,
  standaloneTopTxOnlyImplicitOutputs,
  standaloneTopTxWithEqualAllocationsAndReleases,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx

-- | A proposal whose source outputs already exist on the real ledger.
-- The snapshot supplies recorded input deposits and the current output price.
-- Neither changing its declaration nor querying it changes the ledger.
data ReleaseTx = ReleaseTx
  { ledgerState :: TopTx.LedgerState
  , unsignedTx :: Tx TopTx DijkstraEra
  }
  deriving (Show)

-- | Required deposits for all new store-backed outputs, including SubTx outputs.
allocatedDeposits :: ReleaseTx -> Coin
allocatedDeposits proposal =
  foldMap (TopTx.outputDeposit $ TopTx.protocolParameters $ ledgerState proposal) $
    createdOrdinaryOutputs (unsignedTx proposal)

-- | Recorded deposits consumed by TopTx and its SubTxs, excluding unrelated inputs.
releasedDeposits :: ReleaseTx -> Coin
releasedDeposits proposal =
  foldMap id $
    Map.restrictKeys
      (depositStoreAllocations $ utxosDepositStore $ TopTx.utxoState $ ledgerState proposal)
      (ordinarySpendingInputs $ unsignedTx proposal)

-- | Required net change: allocations minus releases. Positive allocates, negative
-- releases and zero declares no net change. This does not read the declaration.
netDeposit :: ReleaseTx -> Coin
netDeposit proposal = allocatedDeposits proposal <-> releasedDeposits proposal

-- | Apply exactly the declarations supplied for TopTx and its ordered SubTxs.
-- Preserve the proposal's inputs, outputs and funding context. A declaration count
-- mismatch is a fixture error: no child may be dropped or silently left unchanged.
addDeclaration :: Declarations -> ReleaseTx -> ReleaseTx
addDeclaration (Declarations topDeclaration childDeclarations) proposal =
  let tx = unsignedTx proposal
      children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
      declaredChildren =
        zipWith
          (\declaration child -> child & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ declaration)
          childDeclarations
          children
   in if length children /= length childDeclarations
        then error "addDeclaration requires one declaration for every SubTx"
        else
          proposal
            { unsignedTx =
                tx
                  & bodyTxL . netUTxODepositChangeTxBodyL .~ topDeclaration
                  & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable declaredChildren
            }

-- | One to five Store-backed sources and unrelated allocations. Submission support
-- places the selected sources exclusively in reference inputs and creates no Store
-- outputs, so their recorded deposits do not become ordinary releases.
standaloneTopTxWithStoreBackedReferenceInputs :: Gen TopTx.ReleaseScenario
standaloneTopTxWithStoreBackedReferenceInputs = TopTx.standaloneTopTxOnlyImplicitOutputs
