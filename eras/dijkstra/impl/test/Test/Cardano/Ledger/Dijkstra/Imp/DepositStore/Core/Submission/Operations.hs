{-# LANGUAGE DataKinds #-}

-- | Fund arbitrary ordinary operation forms at zero deposit price. Zero pricing
-- separates structural declaration requirements from monetary accounting.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Operations (
  fundOperations,
) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (
  curPParamsEpochStateL,
  esLStateL,
  lsUTxOStateL,
  nesEsL,
 )
import Cardano.Ledger.TxIn (TxIn)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Typeable (Typeable)
import Lens.Micro
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Operations as Operations
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx (LedgerState (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (forM_, shouldBe)

-- | Create every source through a real ledger transaction. Parent and children
-- each own one distinct source and return its application ADA to their own output.
-- All declarations remain absent for the spec. The zero price is deliberate:
-- store-backed forms still require a declaration despite zero recorded amounts.
fundOperations :: Operations.OperationsScenario -> ImpTestM DijkstraEra ReleaseTx
fundOperations scenario = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 0)
  address <- freshKeyAddrNoPtr_
  let operations = Operations.topTxOperations scenario : Operations.subTxOperations scenario
      sourceOutputs =
        [ Operations.outputWithForm address (Operations.sourceForm body) (Operations.applicationCoins body)
        | body <- operations
        ]
  funded <-
    submitTx $
      mkBasicTx mkBasicTxBody
        & bodyTxL . outputsTxBodyL .~ SSeq.fromList sourceOutputs
        & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.DeclaresZeroNetUTxODeposit
  let children =
        [ proposalBody address (txInAt index funded) body
        | (index, body) <- zip [1 ..] (Operations.subTxOperations scenario)
        ]
      proposal =
        proposalBody address (txInAt 0 funded) (Operations.topTxOperations scenario)
          & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable children
  length (proposal ^. bodyTxL . subTransactionsTxBodyL)
    `shouldBe` length (Operations.subTxOperations scenario)
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  state <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  forM_ (zip [0 ..] sourceOutputs) $ \(index, source) -> do
    let input = txInAt index funded
    impGetUTxO input >>= (`shouldBe` source)
    Map.lookup input (recordedAmounts $ liveOutputStore state)
      `shouldBe` case source of
        NewTxOut _ -> Just (Coin 0)
        LegacyTxOut _ -> Nothing
  pure $ ReleaseTx (LedgerState state parameters) proposal

-- | Construct one undeclared body retaining its source's application ADA. Its
-- ordinary input is unique; changing deposit form cannot collapse sibling bodies.
proposalBody :: Typeable l => Addr -> TxIn -> Operations.BodyOperations -> Tx l DijkstraEra
proposalBody address input operations =
  mkBasicTx mkBasicTxBody
    & bodyTxL . inputsTxBodyL .~ Set.singleton input
    & bodyTxL . outputsTxBodyL
      .~ SSeq.singleton
        ( Operations.outputWithForm address (Operations.createdForm operations) $
            Operations.applicationCoins operations
        )
