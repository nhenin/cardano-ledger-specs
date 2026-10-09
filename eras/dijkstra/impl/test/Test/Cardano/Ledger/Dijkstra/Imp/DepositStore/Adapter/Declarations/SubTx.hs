module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.SubTx (
  module Cardano.Ledger.Dijkstra.UTxODeposit.SubTx,
  allDeclarations,
  onlyExplicitDeclarations,
  equalLocalAllocationAndRelease,
  isExplicitDeclaration,
  singleExplicitDeclarationAtEachPosition,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (PositiveCoin)
import Cardano.Ledger.Dijkstra.UTxODeposit.SubTx

-- | All SubTx declaration forms for the supplied amount and settlement output
-- index, including absence. These are validator fixtures, not necessarily valid
-- batches.
allDeclarations :: PositiveCoin -> TxIx -> [SubTxUTxODepositDeclaration]
allDeclarations amount outputIndex =
  NoUTxODepositDeclaration : onlyExplicitDeclarations amount outputIndex

-- | Every explicit SubTx declaration form: zero, local allocation, funding
-- requested from TopTx, local release and release delegated to TopTx.
onlyExplicitDeclarations :: PositiveCoin -> TxIx -> [SubTxUTxODepositDeclaration]
onlyExplicitDeclarations amount outputIndex =
  [ DeclaresZeroNetUTxODeposit
  , DeclaresNetUTxODepositAllocation amount
  , RequestsUTxODepositFromTopTx amount
  , DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput outputIndex)
  , DeclaresNetUTxODepositRelease amount DelegateToTopTx
  ]

-- | Two SubTxs declare the same positive amount: one allocates a UTxO capacity
-- deposit locally, the other releases it locally to output zero. Their declared
-- net amount is zero, but both declarations are explicit. This builds declarations
-- for the presence validator; it does not construct or fund settlement outputs.
equalLocalAllocationAndRelease :: PositiveCoin -> [SubTxUTxODepositDeclaration]
equalLocalAllocationAndRelease amount =
  [ DeclaresNetUTxODepositAllocation amount
  , DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput (TxIx 0))
  ]

-- | Recognize explicit declarations, including zero, for the test's expected
-- result. Match the forms independently of the production presence predicate.
isExplicitDeclaration :: SubTxUTxODepositDeclaration -> Bool
isExplicitDeclaration NoUTxODepositDeclaration = False
isExplicitDeclaration _ = True

-- | Put one explicit declaration at each position in a list of four SubTxs;
-- the other three make no declaration. Repeat for all five explicit forms,
-- producing twenty lists. This checks that validation examines every SubTx.
-- The supplied output index is a release settlement target, not a SubTx position.
singleExplicitDeclarationAtEachPosition ::
  PositiveCoin -> TxIx -> [[SubTxUTxODepositDeclaration]]
singleExplicitDeclarationAtEachPosition amount outputIndex =
  [ replicate position NoUTxODepositDeclaration
      <> [declaration]
      <> replicate (3 - position) NoUTxODepositDeclaration
  | declaration <- onlyExplicitDeclarations amount outputIndex
  , position <- [0 .. 3]
  ]
