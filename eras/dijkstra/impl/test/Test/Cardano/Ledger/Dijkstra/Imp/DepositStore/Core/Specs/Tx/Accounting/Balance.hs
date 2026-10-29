{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Generated balance scenarios and independent value observations. These
-- proposals contain ordinary inputs, outputs, TopTx fees and Store transfers;
-- submission support rejects unsupported financial flows before using the oracle.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.Balance (
  Balance (..),
  balance,
  isBalanced,
  allocation,
  release,
  twoChildren,
  delegatedAllocation,
  offsettingDelegations,
  transferAmount,
  topFunding,
  changeTopOutputCoins,
  changeSubTxOutputCoins,
  transferBetweenSubTxs,
  contributeSubTxCoinsToFees,
  changeNativeAssetOutput,
  differentAsset,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.Mary.Value (AssetName (..), MaryValue (..), MultiAsset (..))
import Cardano.Ledger.Shelley.LedgerState (UTxO (..))
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val (isAdaOnly, (<->)), inject)
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario,
  bodyOperations,
  scenario,
 )

-- | Independent sides of the complete transaction equation. Values retain every
-- asset identity and quantity; the signed TopTx Store term adds only ADA once.
data Balance = Balance
  { consumedValue :: MaryValue
  , producedValue :: MaryValue
  }
  deriving (Eq, Show)

-- | Sum resolved application inputs and proposed outputs directly, without the
-- production consumed/produced or deposit-accounting helpers. Missing or repeated
-- ordinary inputs are fixture errors, not silently omitted values.
balance :: UTxO DijkstraEra -> Tx TopTx DijkstraEra -> Balance
balance (UTxO sources) tx =
  let children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
      inputs =
        toList (tx ^. bodyTxL . inputsTxBodyL) <> concatMap (toList . (^. bodyTxL . inputsTxBodyL)) children
      inputValues = map (inputValue sources) inputs
      outputValues = outputsValue tx <> foldMap outputsValue children
      Coin declared = declaredChange $ tx ^. bodyTxL . netUTxODepositChangeTxBodyL
   in if Set.size (Set.fromList inputs) /= length inputs
        then error "Balance oracle requires distinct ordinary inputs across bodies"
        else
          Balance
            (foldMap id inputValues <> inject (Coin $ max 0 $ negate declared))
            (outputValues <> inject (tx ^. bodyTxL . feeTxBodyL) <> inject (Coin $ max 0 declared))

-- | Look up an actual funded input; an unresolved input cannot establish balance.
inputValue :: Map.Map TxIn (TxOut DijkstraEra) -> TxIn -> MaryValue
inputValue sources input =
  case Map.lookup input sources of
    Just output -> outputValue output
    Nothing -> error "Balance oracle encountered an unfunded ordinary input"

-- | Application value of this body's own outputs, excluding nested bodies.
outputsValue :: Tx l DijkstraEra -> MaryValue
outputsValue tx = foldMap outputValue $ tx ^. bodyTxL . outputsTxBodyL

-- | Read application assets from either output form. A recorded Store deposit
-- is external to these values and enters the equation through TopTx's total.
outputValue :: TxOut DijkstraEra -> MaryValue
outputValue (LegacyTxOut output) = output ^. valueTxOutL
outputValue (NewTxOut output) =
  case output ^. applicationAssetsTxOutL of
    ApplicationAssets assets -> assets

-- | Interpret the supplied declaration directly. Every balance scenario supplies
-- an explicit total; absence is not silently treated as an explicit zero.
declaredChange :: TopTx.TopTxUTxODepositDeclaration -> Coin
declaredChange declaration = case declaration of
  TopTx.DeclaresNetUTxODepositAllocation amount -> unStrictlyPositiveCoin amount
  TopTx.DeclaresNetUTxODepositRelease amount _ -> Coin 0 <-> unStrictlyPositiveCoin amount
  TopTx.DeclaresZeroNetUTxODeposit -> Coin 0
  TopTx.NoUTxODepositDeclaration -> error "Balance scenarios require an explicit TopTx declaration"

-- | Equality of complete values, including native assets as well as ADA.
isBalanced :: Balance -> Bool
isBalanced observed = consumedValue observed == producedValue observed

-- | Both bodies allocate positive amounts, making a repeated child contribution
-- observably different from the complete transaction's net allocation.
allocation :: Gen AccountingScenario
allocation = do
  parent <- chooseInt (1, 3)
  child <- chooseInt (1, 3)
  scenario (bodyOperations parent 0) [bodyOperations child 0]

-- | Both bodies release positive recorded amounts into their own outputs.
release :: Gen AccountingScenario
release = do
  parent <- chooseInt (1, 3)
  child <- chooseInt (1, 3)
  scenario (bodyOperations 0 parent) [bodyOperations 0 child]

-- | Two children allocate positive amounts and retain ample application ADA.
-- Post-signing transfers can make each child imbalanced while preserving the total.
twoChildren :: Gen AccountingScenario
twoChildren = do
  first <- chooseInt (1, 3)
  second <- chooseInt (1, 3)
  scenario (bodyOperations 0 0) [bodyOperations first 0, bodyOperations second 0]

-- | A child requests a positive allocation from TopTx; the parent has no own
-- Store operation, so its total equals the delegated request exactly.
delegatedAllocation :: Gen AccountingScenario
delegatedAllocation = do
  amount <- chooseInt (1, 3)
  scenario (bodyOperations 0 0) [bodyOperations amount 0]

-- | One allocation and one release of the same positive size, both delegated.
-- TopTx has no own Store operation and must explicitly declare a zero total.
offsettingDelegations :: Gen AccountingScenario
offsettingDelegations = do
  amount <- chooseInt (1, 3)
  scenario (bodyOperations 0 0) [bodyOperations amount 0, bodyOperations 0 amount]

-- | Positive application ADA moved between bodies or into TopTx fees, below
-- the available fixture funds and safely above zero in every generated case.
transferAmount :: Gen Coin
transferAmount = Coin <$> chooseInteger (1_000_000, 3_000_000)

-- | Separate parent funding for the fixed child example: ten application ADA
-- plus two released ADA. The child amounts stay fixed while funding varies.
topFunding :: Gen Coin
topFunding = Coin <$> chooseInteger (200_000_000, 210_000_000)

-- | Change only application ADA in parent output zero. Its implicit form keeps
-- the declared Store obligation unchanged even when the output value changes.
changeTopOutputCoins :: Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
changeTopOutputCoins difference = bodyTxL . outputsTxBodyL %~ changeFirstImplicitCoins difference

-- | Change only application ADA in output zero of the selected ordered child.
-- Every other child, output and declaration remains intact; signing is separate.
changeSubTxOutputCoins :: Int -> Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
changeSubTxOutputCoins index difference tx =
  let children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
   in if index < 0 || index >= length children
        then error "Balance fixture child index is outside the transaction"
        else
          tx
            & bodyTxL . subTransactionsTxBodyL
              .~ OMap.fromFoldable
                [ if position == index
                    then child & bodyTxL . outputsTxBodyL %~ changeFirstImplicitCoins difference
                    else child
                | (position, child) <- zip [0 ..] children
                ]

-- | Add the signed amount to implicit output zero, retaining all other outputs.
changeFirstImplicitCoins ::
  Coin -> SSeq.StrictSeq (TxOut DijkstraEra) -> SSeq.StrictSeq (TxOut DijkstraEra)
changeFirstImplicitCoins difference outputs = case toList outputs of
  first@(LegacyTxOut _) : rest -> SSeq.fromList ((first & coinTxOutL <>~ difference) : rest)
  _ -> error "Balance mutation requires an implicit output at index zero"

-- | Child zero exports the amount to child one. The complete transaction value
-- is unchanged; independent child balance is deliberately broken.
transferBetweenSubTxs :: Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
transferBetweenSubTxs amount = changeSubTxOutputCoins 1 amount . changeSubTxOutputCoins 0 (Coin 0 <-> amount)

-- | Redirect child zero's application ADA into the TopTx fee, preserving the
-- complete transaction equation and every Store declaration.
contributeSubTxCoinsToFees :: Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
contributeSubTxCoinsToFees amount tx =
  changeSubTxOutputCoins 0 (Coin 0 <-> amount) tx & bodyTxL . feeTxBodyL <>~ amount

-- | Change the sole token-bearing parent output's value. Its implicit form does
-- not change Store pricing. The caller chooses the native-asset mismatch explicitly.
changeNativeAssetOutput :: (MaryValue -> MaryValue) -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
changeNativeAssetOutput change tx =
  let outputs = toList $ tx ^. bodyTxL . outputsTxBodyL
      tokenOutputs = filter (not . isAdaOnly . outputValue) outputs
   in if length tokenOutputs /= 1
        then error "Native-asset balance fixture requires exactly one token output"
        else
          tx
            & bodyTxL . outputsTxBodyL
              .~ SSeq.fromList
                (map (changeImplicitNativeAssets change) outputs)

-- | Apply an asset mutation only to an implicit token output, so it cannot
-- reprice a Store allocation. ADA-only outputs retain their original value.
changeImplicitNativeAssets :: (MaryValue -> MaryValue) -> TxOut DijkstraEra -> TxOut DijkstraEra
changeImplicitNativeAssets change output
  | isAdaOnly (outputValue output) = output
  | otherwise = case output of
      LegacyTxOut implicit -> LegacyTxOut $ implicit & valueTxOutL %~ change
      NewTxOut _ -> error "Native-asset balance mutation requires an implicit output"

-- | Preserve the policy and quantity while changing only the asset name to
-- another equal-width name. This isolates asset identity from ADA and encoded size.
differentAsset :: MaryValue -> MaryValue
differentAsset (MaryValue ada (MultiAsset policies)) =
  MaryValue ada $ MultiAsset $ fmap (Map.mapKeys $ const $ AssetName "balance-b") policies
