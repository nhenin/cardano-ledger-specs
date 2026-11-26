{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | SubTx declarations used by the specifications: operation forms, generators
-- and raw decoder inputs. Generated samples retain every required form or defect;
-- local indices describe representation and do not require transaction outputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.SubTx (
  module Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx,
  allDeclarations,
  onlyExplicitDeclarations,
  equalLocalAllocationAndRelease,
  singleExplicitDeclarationAtEachPosition,
  localReleaseTargetWithIndex,
  declarationsAtBounds,
  allDeclarationsWithAmount,
  absentAndExplicitZero,
  fundingRequest,
  allDeclarationInputsWithAmount,
  declarationsWithInvalidStructure,
  releaseTargetsWithInvalidStructure,
  negativeOutputIndex,
  overflowingOutputIndex,
  isExplicitDeclaration,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin)
import qualified Data.Aeson as Aeson
import Data.Word (Word64)
import Lens.Micro ((&), (.~))
import Test.Cardano.Ledger.Binary.Plain.Golden (Enc (..))
import Test.Cardano.Ledger.Common (Gen, arbitrary, choose, chooseInteger, elements, listOf1)
import Test.Cardano.Ledger.Core.Arbitrary ()
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding (DecoderInputs (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.CBOR (cborList)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.OutputIndex (
  negativeOutputIndex,
  overflowingOutputIndex,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin as StrictlyPositiveCoin

-- | All SubTx declaration forms for the supplied amount and settlement output
-- index, including absence. These are validator fixtures, not necessarily valid
-- batches.
allDeclarations :: StrictlyPositiveCoin -> TxIx -> [SubTxUTxODepositDeclaration]
allDeclarations amount outputIndex =
  NoUTxODepositDeclaration : onlyExplicitDeclarations amount outputIndex

-- | Every explicit SubTx declaration form: zero, local allocation, funding
-- requested from TopTx, local release and release delegated to TopTx.
onlyExplicitDeclarations :: StrictlyPositiveCoin -> TxIx -> [SubTxUTxODepositDeclaration]
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
equalLocalAllocationAndRelease :: StrictlyPositiveCoin -> [SubTxUTxODepositDeclaration]
equalLocalAllocationAndRelease amount =
  [ DeclaresNetUTxODepositAllocation amount
  , DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput (TxIx 0))
  ]

-- | Put one explicit declaration at each position in a list of four SubTxs;
-- the other three make no declaration. Repeat for all five explicit forms,
-- producing twenty lists. This checks that validation examines every SubTx.
-- The supplied output index is a release settlement target, not a SubTx position.
singleExplicitDeclarationAtEachPosition ::
  StrictlyPositiveCoin -> TxIx -> [[SubTxUTxODepositDeclaration]]
singleExplicitDeclarationAtEachPosition amount outputIndex =
  [ replicate position NoUTxODepositDeclaration
      <> [declaration]
      <> replicate (3 - position) NoUTxODepositDeclaration
  | declaration <- onlyExplicitDeclarations amount outputIndex
  , position <- [0 .. 3]
  ]

-- | Deterministic supporting builder for a supplied raw index in both formats.
-- Keeping the Integer argument visible lets the spec generate and shrink indices
-- outside 0..65535. Decoding does not check whether the output exists in a body.
localReleaseTargetWithIndex :: Integer -> DecoderInputs
localReleaseTargetWithIndex outputIndex =
  DecoderInputs
    { cborInputs = [cborList [E @Int 0, E outputIndex]]
    , jsonInputs =
        [ Aeson.object
            [ "kind" Aeson..= ("subTxSettlementOutput" :: String)
            , "outputIndex" Aeson..= outputIndex
            ]
        ]
    }

-- | Explicit zero and every operation form at both positive amount bounds.
-- Each bound includes local releases at both index bounds and a generated interior index.
declarationsAtBounds :: Gen [SubTx.SubTxNetUTxODepositChange]
declarationsAtBounds =
  case StrictlyPositiveCoin.positiveAmountBounds of
    (minimumAmount, maximumAmount) ->
      (SubTx.SubTxNoUTxODepositChange :) . concat
        <$> traverse
          (allDeclarationsWithAmount . StrictlyPositiveCoin.positiveAmount)
          [minimumAmount, maximumAmount]

-- | Put the supplied amount in every amount-bearing SubTx form, retaining local index bounds
-- and adding one independently generated interior index in 1..65534.
allDeclarationsWithAmount :: StrictlyPositiveCoin -> Gen [SubTx.SubTxNetUTxODepositChange]
allDeclarationsWithAmount amount = do
  outputIndex <- TxIx <$> choose (1, 65534)
  pure $
    [ SubTx.SubTxAllocateUTxODeposit amount
    , SubTx.SubTxRequestUTxODepositFromTopTx amount
    ]
      <> [ SubTx.SubTxReleaseUTxODeposit amount target
         | target <-
             [ SubTx.DelegateToTopTx
             , SubTx.SubTxSettlementOutput (TxIx 0)
             , SubTx.SubTxSettlementOutput maxBound
             , SubTx.SubTxSettlementOutput outputIndex
             ]
         ]

-- | One body with generated spending inputs, reference inputs and auxiliary-data
-- hash, paired with the same body carrying explicit zero instead of absence.
-- Other fields retain their basic defaults, isolating the declaration difference.
absentAndExplicitZero :: Gen (TxBody SubTx DijkstraEra, TxBody SubTx DijkstraEra)
absentAndExplicitZero = do
  spendingInputs <- arbitrary
  referenceInputs <- arbitrary
  auxiliaryDataHash <- arbitrary
  let absentBody =
        mkBasicTxBody @DijkstraEra @SubTx
          & inputsTxBodyL
            .~ spendingInputs
          & referenceInputsTxBodyL
            .~ referenceInputs
          & auxDataHashTxBodyL
            .~ auxiliaryDataHash
  pure
    ( absentBody & subTxNetUTxODepositChangeTxBodyL .~ SubTx.NoUTxODepositDeclaration
    , absentBody & subTxNetUTxODepositChangeTxBodyL .~ SubTx.DeclaresZeroNetUTxODeposit
    )

-- | A SubTx-only funding request with an arbitrary strictly positive amount.
fundingRequest :: Gen SubTx.SubTxNetUTxODepositChange
fundingRequest = SubTx.SubTxRequestUTxODepositFromTopTx <$> arbitrary

-- | Generate six CBOR and six JSON inputs carrying the supplied raw amount.
-- Every sample includes allocation, funding request, delegated release and local
-- release at indices 0 and 65535, plus one local release at a generated index
-- in 1..65534. The targets remain valid while the unchecked amount is decoded.
allDeclarationInputsWithAmount :: Integer -> Gen DecoderInputs
allDeclarationInputsWithAmount amount = do
  outputIndex <- chooseInteger (1, 65534)
  pure
    DecoderInputs
      { cborInputs =
          [ cborList [E @Int 0, E amount]
          , cborList [E @Int 2, E amount]
          ]
            <> [ cborList [E @Int 1, E amount, target]
               | target <-
                   cborList [E @Int 1]
                     : [ cborList [E @Int 0, E index]
                       | index <- [0, 65535, outputIndex]
                       ]
               ]
      , jsonInputs =
          [ Aeson.object ["kind" Aeson..= ("allocate" :: String), "amount" Aeson..= amount]
          , Aeson.object ["kind" Aeson..= ("requestUTxODepositFromTopTx" :: String), "amount" Aeson..= amount]
          ]
            <> [ Aeson.object
                   [ "kind" Aeson..= ("release" :: String)
                   , "amount" Aeson..= amount
                   , "target" Aeson..= target
                   ]
               | target <-
                   Aeson.object ["kind" Aeson..= ("delegateToTopTx" :: String)]
                     : [ Aeson.object
                           [ "kind" Aeson..= ("subTxSettlementOutput" :: String)
                           , "outputIndex" Aeson..= index
                           ]
                       | index <- [0, 65535, outputIndex]
                       ]
               ]
      }

-- | Each sample contains nine CBOR and eight JSON structural failures.
-- Valid CBOR declarations are @[0, amount]@, @[1, amount, target]@,
-- @[2, amount]@ and @[3]@. Amounts and local indices here remain in range,
-- so rejection tests the structure rather than an unrelated numeric bound.
-- Additional JSON keys remain permitted and are not treated as defects.
declarationsWithInvalidStructure :: Gen DecoderInputs
declarationsWithInvalidStructure = do
  amount <- chooseInteger (1, toInteger (maxBound :: Word64))
  outputIndex <- chooseInteger (0, 65535)
  unknownTag <- chooseInteger (4, toInteger (maxBound :: Word64))
  unknownKind <- ("unknown:" <>) <$> arbitrary @String
  scalar <- arbitrary @Integer
  extraFields <- map (E @Integer) <$> listOf1 arbitrary
  target <-
    elements
      [ Aeson.object ["kind" Aeson..= ("delegateToTopTx" :: String)]
      , Aeson.object
          ["kind" Aeson..= ("subTxSettlementOutput" :: String), "outputIndex" Aeson..= outputIndex]
      ]
  pure
    DecoderInputs
      { cborInputs =
          [ E scalar -- A declaration must be a tagged array, not a scalar.
          , cborList [] -- The operation tag is missing.
          , cborList [E @Int 0] -- Allocation is missing its amount.
          , cborList [E unknownTag, E amount] -- Only operation tags 0 through 3 are known.
          , cborList (E @Int 3 : extraFields) -- Explicit zero takes no fields.
          , cborList [E @Int 2] -- Funding request is missing its amount.
          , cborList ([E @Int 2, E amount] <> extraFields) -- Funding request has extra fields.
          , cborList ([E @Int 0, E amount] <> extraFields) -- Allocation has extra fields.
          , cborList [E @Int 1, E amount] -- Release is missing its target.
          ]
      , jsonInputs =
          [ Aeson.Null -- A declaration must be an object, not null.
          , Aeson.toJSON scalar -- A number is not a declaration object.
          , Aeson.object [] -- The required kind is missing.
          , Aeson.object ["kind" Aeson..= ("allocate" :: String)] -- Allocation is missing its amount.
          , Aeson.object ["kind" Aeson..= ("release" :: String), "target" Aeson..= target] -- Release is missing its amount.
          , Aeson.object ["kind" Aeson..= ("release" :: String), "amount" Aeson..= amount] -- Release is missing its target.
          , Aeson.object ["kind" Aeson..= ("requestUTxODepositFromTopTx" :: String)] -- Funding request is missing its amount.
          , Aeson.object ["kind" Aeson..= unknownKind] -- The prefix cannot name a recognized kind.
          ]
      }

-- | Each sample contains six CBOR and five JSON structural failures.
-- Valid CBOR targets are @[0, outputIndex]@ for a local output and @[1]@
-- for delegation. The local index remains in 0..65535 to isolate structure.
-- JSON requires a recognized kind and, for local settlement, an outputIndex;
-- additional object keys remain permitted.
releaseTargetsWithInvalidStructure :: Gen DecoderInputs
releaseTargetsWithInvalidStructure = do
  outputIndex <- chooseInteger (0, 65535)
  unknownTag <- chooseInteger (2, toInteger (maxBound :: Word64))
  unknownKind <- ("unknown:" <>) <$> arbitrary @String
  scalar <- arbitrary @Integer
  extraFields <- map (E @Integer) <$> listOf1 arbitrary
  pure
    DecoderInputs
      { cborInputs =
          [ E scalar -- A target must be a tagged array, not a scalar.
          , cborList [] -- The target tag is missing.
          , cborList [E unknownTag] -- Only target tags 0 and 1 are known.
          , cborList [E @Int 1, E outputIndex] -- Delegation takes no output index.
          , cborList [E @Int 0] -- Local settlement is missing its output index.
          , cborList ([E @Int 0, E outputIndex] <> extraFields) -- Local settlement has extra fields.
          ]
      , jsonInputs =
          [ Aeson.Null -- A target must be an object, not null.
          , Aeson.toJSON scalar -- A number is not a target object.
          , Aeson.object [] -- The required kind is missing.
          , Aeson.object ["kind" Aeson..= unknownKind] -- The prefix cannot name a recognized kind.
          , Aeson.object ["kind" Aeson..= ("subTxSettlementOutput" :: String)] -- Local settlement is missing its outputIndex.
          ]
      }

-- | Recognize explicit declarations, including zero, for the test's expected
-- result. Match the forms independently of the production presence predicate.
isExplicitDeclaration :: SubTxUTxODepositDeclaration -> Bool
isExplicitDeclaration NoUTxODepositDeclaration = False
isExplicitDeclaration _ = True
