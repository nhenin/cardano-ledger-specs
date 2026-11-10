{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Output descriptions and transaction bodies for presence specifications.
-- Deposit-backed variants do not imply funded capacity deposits.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (
  OutputVariant (..),
  CreatedOutputs (..),
  TxOutputs (..),
  depositBackedOutputCases,
  implicitOutputCases,
  topTxBody,
  subTxBody,
  topTxBodyWithNestedOutputs,
  topTxBodyWithCollateralReturn,
  topTxBodyWithReferenceAndCollateralInputs,
  isImplicitOutput,
) where

import Cardano.Ledger.BaseTypes (StrictMaybe (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, arbitrary, chooseInt, elements, vectorOf)
import Test.Cardano.Ledger.Core.Arbitrary ()

-- | The output constructor relevant to declaration presence.
data OutputVariant = ImplicitOutput | DepositBackedOutput
  deriving (Eq, Show)

-- | One address and an ordered sequence of own-output variants.
data CreatedOutputs = CreatedOutputs
  { outputAddress :: Addr
  , outputVariants :: [OutputVariant]
  }
  deriving (Show)

-- | A TopTx's declaration and own outputs, followed by each SubTx's declaration
-- and own outputs. An empty SubTx list means the batch has no SubTxs.
data TxOutputs
  = TxOutputs
      TopTx.TopTxUTxODepositDeclaration
      [OutputVariant]
      [(SubTx.SubTxUTxODepositDeclaration, [OutputVariant])]
  deriving (Show)

-- | Every sample includes a single deposit-backed output at each position among
-- implicit outputs, an entirely deposit-backed sequence, and a random mixture
-- containing at least one deposit-backed output. Vary the address and length.
depositBackedOutputCases :: Gen [CreatedOutputs]
depositBackedOutputCases = do
  address <- arbitrary
  count <- chooseInt (1, 5)
  mixture <- vectorOf count $ elements [ImplicitOutput, DepositBackedOutput]
  pure $
    [ CreatedOutputs address $
        replicate position ImplicitOutput
          <> [DepositBackedOutput]
          <> replicate (count - position - 1) ImplicitOutput
    | position <- [0 .. count - 1]
    ]
      <> [ CreatedOutputs address (replicate count DepositBackedOutput)
         , CreatedOutputs address (DepositBackedOutput : mixture)
         ]

-- | Cover empty output sequences as well as nonempty implicit-only sequences.
implicitOutputCases :: Gen [CreatedOutputs]
implicitOutputCases = do
  address <- arbitrary
  count <- chooseInt (1, 5)
  pure [CreatedOutputs address [], CreatedOutputs address (replicate count ImplicitOutput)]

-- | Construct a TopTx's own outputs and declaration for an isolated presence check.
topTxBody :: CreatedOutputs -> TopTx.TopTxUTxODepositDeclaration -> TxBody TopTx DijkstraEra
topTxBody outputs declaration =
  mkBasicTxBody
    & outputsTxBodyL
      .~ SSeq.fromList (createdOutputs outputs)
    & netUTxODepositChangeTxBodyL
      .~ declaration

-- | Construct a SubTx's own outputs and declaration without claiming financial validity.
subTxBody :: CreatedOutputs -> SubTx.SubTxUTxODepositDeclaration -> TxBody SubTx DijkstraEra
subTxBody outputs declaration =
  mkBasicTxBody
    & outputsTxBodyL
      .~ SSeq.fromList (createdOutputs outputs)
    & subTxNetUTxODepositChangeTxBodyL
      .~ declaration

-- | Keep TopTx's own outputs distinct from the explicitly declared nested SubTx outputs.
topTxBodyWithNestedOutputs ::
  CreatedOutputs -> CreatedOutputs -> TxBody TopTx DijkstraEra
topTxBodyWithNestedOutputs ownOutputs nestedOutputs =
  topTxBody ownOutputs TopTx.NoUTxODepositDeclaration
    & subTransactionsTxBodyL
      .~ OMap.fromFoldable [mkBasicTx $ subTxBody nestedOutputs SubTx.DeclaresZeroNetUTxODeposit]

-- | Place a deposit-backed output only in collateral return, outside ordinary created outputs.
topTxBodyWithCollateralReturn :: Addr -> TxBody TopTx DijkstraEra
topTxBodyWithCollateralReturn address =
  mkBasicTxBody
    & collateralReturnTxBodyL
      .~ SJust (outputAtAddress address DepositBackedOutput)

-- | Input identifiers alone are not created outputs. Resolution and the rules
-- governing spent, referenced, or collateral UTxOs remain separate work.
topTxBodyWithReferenceAndCollateralInputs :: TxIn -> TxBody TopTx DijkstraEra
topTxBodyWithReferenceAndCollateralInputs input =
  mkBasicTxBody
    & referenceInputsTxBodyL
      .~ Set.singleton input
    & collateralInputsTxBodyL
      .~ Set.singleton input

-- | Interpret the fixture's ordered output variants at its supplied address.
createdOutputs :: CreatedOutputs -> [TxOut DijkstraEra]
createdOutputs (CreatedOutputs address variants) = map (outputAtAddress address) variants

-- | Give implicit outputs ordinary ADA; deposit-backed outputs carry empty application assets.
outputAtAddress :: Addr -> OutputVariant -> TxOut DijkstraEra
outputAtAddress address ImplicitOutput =
  mkBasicTxOutWithMinAda address $ inject (Coin 2_000_000)
outputAtAddress address DepositBackedOutput =
  mkBasicTxOutWithDeposit address $ ApplicationAssets mempty

-- | Recognize change outputs that do not introduce Store operations.
isImplicitOutput :: TxOut DijkstraEra -> Bool
isImplicitOutput (MinAdaTxOut _) = True
isImplicitOutput (DepositBackedTxOut _) = False
