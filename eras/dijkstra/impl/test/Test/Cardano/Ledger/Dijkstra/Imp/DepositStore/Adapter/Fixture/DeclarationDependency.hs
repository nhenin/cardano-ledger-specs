-- | Declaration combinations for DS-TX-009. These fixtures describe what TopTx
-- and its SubTxs declare, without asserting financial validity or an expected
-- validation result. The spec defines the rule independently.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.DeclarationDependency (
  Declarations (..),
  equalLocalAllocationAndRelease,
  onlyExplicitSubTxDeclarations,
  generateCases,
  forAllCases,
) where

import Cardano.Ledger.BaseTypes (TxIx)
import Cardano.Ledger.Coin (PositiveCoin)
import Test.Cardano.Ledger.Common (
  Gen,
  Property,
  arbitrary,
  chooseInt,
  conjoin,
  counterexample,
  elements,
  forAllBlind,
  vectorOf,
 )
import Test.Cardano.Ledger.Core.Arbitrary ()
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Declarations.TopTx as TopTx

-- | The declarations carried by one TopTx and its ordered SubTxs. An empty
-- SubTx list represents a TopTx without SubTxs, not an absent TopTx.
data Declarations = Declarations
  { topTxDeclaration :: TopTx.TopTxUTxODepositDeclaration
  , subTxDeclarations :: [SubTx.SubTxUTxODepositDeclaration]
  }
  deriving (Show)

-- | Generate two explicit SubTx declarations from one arbitrary strictly positive
-- amount: a local allocation and an equal local release targeting output zero.
-- Their declared net amount is always zero. These are presence-validator inputs;
-- no settlement output is constructed or funded.
equalLocalAllocationAndRelease :: Gen [SubTx.SubTxUTxODepositDeclaration]
equalLocalAllocationAndRelease = SubTx.equalLocalAllocationAndRelease <$> arbitrary

-- | Generate all five explicit SubTx forms: zero, local allocation, allocation
-- requested from TopTx, local release and release delegated to TopTx. Each sample
-- includes every form, using one arbitrary strictly positive amount and settlement
-- output index. The spec validates each declaration separately, not as one batch.
-- The index is only a declared target; no settlement output is constructed.
onlyExplicitSubTxDeclarations :: Gen [SubTx.SubTxUTxODepositDeclaration]
onlyExplicitSubTxDeclarations = SubTx.onlyExplicitDeclarations <$> arbitrary <*> arbitrary

-- | Sample a list of zero to four SubTx declarations, then pair every TopTx
-- declaration form with that list and all of these boundary cases:
--
-- * No SubTxs.
-- * One SubTx with no declaration.
-- * Each explicit declaration at each position among four SubTxs, with the
--   other three making no declaration.
--
-- Every generated sample therefore includes all declaration forms and positions;
-- random lists add combinations of multiple explicit declarations. The supplied
-- amount and settlement output index populate the operations without validating
-- their amounts or whether a settlement output exists.
generateCases :: PositiveCoin -> TxIx -> Gen [Declarations]
generateCases amount outputIndex = do
  subTxCount <- chooseInt (0, 4)
  generated <- vectorOf subTxCount (elements (SubTx.allDeclarations amount outputIndex))
  pure
    [ Declarations topDeclaration subDeclarations
    | topDeclaration <- TopTx.allDeclarations amount outputIndex
    , subDeclarations <-
        [generated, [], [SubTx.NoUTxODepositDeclaration]]
          <> SubTx.singleExplicitDeclarationAtEachPosition amount outputIndex
    ]

-- | Apply the supplied property to every generated combination and boundary case.
-- Amount and output index remain arguments for QuickCheck to generate and shrink.
-- Report the individual declarations when a check fails, without printing the
-- entire list of generated cases. The supplied property can focus on its assertion.
forAllCases :: (Declarations -> Property) -> PositiveCoin -> TxIx -> Property
forAllCases check amount outputIndex =
  forAllBlind (generateCases amount outputIndex) $
    conjoin . map (\declarations -> counterexample (show declarations) (check declarations))
