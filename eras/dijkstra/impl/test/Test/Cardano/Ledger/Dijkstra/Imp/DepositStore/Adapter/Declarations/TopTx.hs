module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.TopTx (
  module Cardano.Ledger.Dijkstra.UTxODeposit.TopTx,
  allDeclarations,
  onlyExplicitDeclarations,
) where

import Cardano.Ledger.BaseTypes (TxIx)
import Cardano.Ledger.Coin (PositiveCoin)
import Cardano.Ledger.Dijkstra.UTxODeposit.TopTx

-- | All TopTx declaration forms for the supplied amount and settlement output
-- index: absence, explicit zero, net allocation, and net release with or without
-- TopTx settlement. These are validator fixtures, not necessarily valid batches.
allDeclarations :: PositiveCoin -> TxIx -> [TopTxUTxODepositDeclaration]
allDeclarations amount outputIndex =
  NoUTxODepositDeclaration : onlyExplicitDeclarations amount outputIndex

-- | Every explicit TopTx declaration form, including zero but excluding absence.
onlyExplicitDeclarations :: PositiveCoin -> TxIx -> [TopTxUTxODepositDeclaration]
onlyExplicitDeclarations amount outputIndex =
  [ DeclaresZeroNetUTxODeposit
  , DeclaresNetUTxODepositAllocation amount
  , DeclaresNetUTxODepositRelease amount NoTopTxSettlement
  , DeclaresNetUTxODepositRelease amount (TopTxSettlementOutput outputIndex)
  ]
