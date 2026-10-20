{-# LANGUAGE DataKinds #-}

-- | Generated output-index shapes and value-preserving sequence adapters.
-- These helpers never infer or repair settlement declarations.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement.OutputIndex (
  localReleases,
  indexBoundaries,
  withOutputCounts,
  resizeOutputs,
  topOutputCount,
  childAt,
  childOutputCount,
  topBodyId,
  childBodyId,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.TxIn (TxId)
import Data.Foldable (toList)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario,
  bodyOperations,
  scenario,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (isImplicitOutput)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))

-- | TopTx and two children independently release one to three deposits. Every
-- output is implicit; generated sequence lengths leave room for both boundaries
-- and for a foreign body to have an output beyond the owner's last position.
localReleases :: Gen (AccountingScenario, Int)
localReleases = do
  topRelease <- chooseInt (1, 3)
  firstRelease <- chooseInt (1, 3)
  secondRelease <- chooseInt (1, 3)
  count <- chooseInt (2, 4)
  plan <-
    scenario
      (bodyOperations 0 topRelease)
      [bodyOperations 0 firstRelease, bodyOperations 0 secondRelease]
  pure (plan, count)

-- | Include empty output sequences. Each sample checks valid boundaries when
-- present, the first invalid index and a more distant representable index.
indexBoundaries :: Gen (Int, Int)
indexBoundaries = (,) <$> chooseInt (0, 6) <*> chooseInt (1, 6)

-- | Change only the implicit ordinary-output sequences of an unsigned proposal.
-- Funding context, source inputs, declarations and the sum of each body's ADA stay fixed.
withOutputCounts :: Int -> [Int] -> ReleaseTx -> ReleaseTx
withOutputCounts topCount childCounts proposal =
  proposal {unsignedTx = resizeOutputs topCount childCounts $ unsignedTx proposal}

-- | Redistribute each body's application ADA across its requested own sequence.
-- Call before fee preparation to reserve the desired serialized output space;
-- repeating afterward removes any additional TopTx change output without changing
-- value. The caller must re-sign. No Store output may enter this adapter.
resizeOutputs :: Int -> [Int] -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
resizeOutputs topCount childCounts tx =
  let children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
   in if length children /= length childCounts
        then error "resizeOutputs requires one count for every child"
        else
          resizeBody topCount tx
            & bodyTxL . subTransactionsTxBodyL
              .~ OMap.fromFoldable (zipWith resizeBody childCounts children)

-- | Preserve one body's full application ADA while distributing it across
-- implicit outputs. Additional financial flows and Store outputs are unsupported.
resizeBody :: Int -> Tx l DijkstraEra -> Tx l DijkstraEra
resizeBody count tx =
  case toList $ tx ^. bodyTxL . outputsTxBodyL of
    outputs@(first : _)
      | count > 0 && all isImplicitOutput outputs ->
          let Coin total = foldMap (^. coinTxOutL) outputs
              (share, remainder) = total `quotRem` toInteger count
           in tx
                & bodyTxL . outputsTxBodyL
                  .~ SSeq.fromList
                    [ first & coinTxOutL .~ Coin (share + if position == 0 then remainder else 0)
                    | position <- [0 .. count - 1]
                    ]
    _ -> error "resizeBody requires positive count and nonempty implicit-only outputs"

-- | Observe the finalized owning sequence, including any fee-preparation change.
topOutputCount :: Tx TopTx DijkstraEra -> Int
topOutputCount = length . (^. bodyTxL . outputsTxBodyL)

-- | Select a child by the stable order established by the funding fixture.
childAt :: Int -> Tx TopTx DijkstraEra -> Tx SubTx DijkstraEra
childAt position tx = (OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL) !! position

-- | Count only this child's regular outputs, excluding siblings and TopTx.
childOutputCount :: Int -> Tx TopTx DijkstraEra -> Int
childOutputCount position = length . (^. bodyTxL . outputsTxBodyL) . childAt position

-- | Read the current parent identifier after any signed declaration mutation.
topBodyId :: Tx TopTx DijkstraEra -> TxId
topBodyId = txIdTxBody . (^. bodyTxL)

-- | Read the current identifier of the child that owns a failing selector.
childBodyId :: Int -> Tx TopTx DijkstraEra -> TxId
childBodyId position = txIdTxBody . (^. bodyTxL) . childAt position
