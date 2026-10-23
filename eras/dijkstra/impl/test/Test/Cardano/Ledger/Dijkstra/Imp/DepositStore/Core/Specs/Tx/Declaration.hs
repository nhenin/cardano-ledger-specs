{-# LANGUAGE DataKinds #-}

-- | Declaration fixtures and isolated validation support for one TopTx and its
-- ordered SubTxs. Generated cases cover declaration presence without asserting
-- financial validity; the independent expectation remains separate from the
-- production validator adapter.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (
  Declarations (..),
  equalLocalAllocationAndRelease,
  onlyExplicitSubTxDeclarations,
  generateCases,
  forAllCases,
  declarationToTxBody,
  subTxWithDepositDeclaration,
  subTxDeclarationImpliesATopTxOne,
  validateDeclaration,
  missingTopDeclarationFailure,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreDeclarationFailure (..),
  validateTopTxNetUTxODepositDeclaration,
 )
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxId (..), TxIn (..))
import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.Set as Set
import Lens.Micro
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
import Test.Cardano.Ledger.Core.Utils (mkDummySafeHash)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx as SubTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.TopTx as TopTx
import Test.Cardano.Ledger.Dijkstra.ImpTest (mkTopTxWithSubTxs)
import Validation (Validation (..))

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
generateCases :: StrictlyPositiveCoin -> TxIx -> Gen [Declarations]
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
forAllCases :: (Declarations -> Property) -> StrictlyPositiveCoin -> TxIx -> Property
forAllCases check amount outputIndex =
  forAllBlind (generateCases amount outputIndex) $
    conjoin . map (\declarations -> counterexample (show declarations) (check declarations))

-- | Convert a declarations fixture into a body for the declaration-only checker.
-- Distinct inputs prevent OMap from merging SubTxs. This does not claim financial validity.
declarationToTxBody :: Declarations -> TxBody TopTx DijkstraEra
declarationToTxBody (Declarations topDeclaration subDeclarations) =
  mkTopTxWithSubTxs (zipWith declarationOnlySubTx [0 ..] subDeclarations)
    ^. bodyTxL
    & netUTxODepositChangeTxBodyL
      .~ topDeclaration

-- | Use a distinct fictitious input to prevent equal declarations from merging in OMap.
declarationOnlySubTx :: Int -> SubTx.SubTxUTxODepositDeclaration -> Tx SubTx DijkstraEra
declarationOnlySubTx index =
  subTxWithDepositDeclaration (TxIn (TxId $ mkDummySafeHash index) (TxIx 0))

-- | Attach the supplied declaration to a SubTx spending the supplied input.
subTxWithDepositDeclaration :: TxIn -> SubTx.SubTxUTxODepositDeclaration -> Tx SubTx DijkstraEra
subTxWithDepositDeclaration input declaration =
  mkBasicTx $
    mkBasicTxBody
      & inputsTxBodyL
        .~ Set.singleton input
      & subTxNetUTxODepositChangeTxBodyL
        .~ declaration

-- | Compute the expected result without using the production presence predicate.
-- Reject exactly when TopTx has no declaration and at least one SubTx declares
-- an operation, including zero. Success means only that DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS is satisfied.
subTxDeclarationImpliesATopTxOne ::
  Declarations ->
  Validation (NonEmpty DepositStoreDeclarationFailure) ()
subTxDeclarationImpliesATopTxOne (Declarations TopTx.NoUTxODepositDeclaration subDeclarations)
  | any SubTx.isExplicitDeclaration subDeclarations = missingTopDeclarationFailure
  | otherwise = Success ()
subTxDeclarationImpliesATopTxOne _ = Success ()

-- | Build a body from the declarations fixture, run only the production
-- SubTx-to-TopTx declaration validator, and return its 'Validation' result for assertions.
-- The fixture uses distinct fictitious inputs; it is not a funded ledger batch.
validateDeclaration ::
  Declarations ->
  Validation (NonEmpty DepositStoreDeclarationFailure) ()
validateDeclaration =
  validateTopTxNetUTxODepositDeclaration . declarationToTxBody

-- | Expected isolated-validator failure when a SubTx declares but TopTx does not.
-- Ledger submission scenarios assert @MissingTopTxUTxODepositDeclaration@, the
-- corresponding failure exposed by the UTXO rule.
missingTopDeclarationFailure :: Validation (NonEmpty DepositStoreDeclarationFailure) ()
missingTopDeclarationFailure = Failure (MissingTopTxDeclaration :| [])
