{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Real ledger funding, codec-sized outputs and witness preparation for the
-- accounting specs. This adapter never supplies or repairs a deposit declaration.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
  buildAndSignTx,
  buildAndSignPhase2InvalidTx,
  mutateTopTxDeclaration,
  mutateSubTxDeclaration,
  replaceSubTxDeclarations,
  subTxIdAt,
) where

import Cardano.Ledger.Binary (Sized (sizedSize), mkSized)
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Plutus (mkInlineDatum)
import Cardano.Ledger.Shelley.LedgerState (
  curPParamsEpochStateL,
  nesEsL,
  utxosUtxo,
 )
import Cardano.Ledger.State (unUTxO)
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxId, TxIn)
import Cardano.Ledger.Val (Val ((<->)), inject)
import qualified Data.ByteString as BS
import Data.Foldable (toList)
import Data.List (find)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Typeable (Typeable)
import Lens.Micro
import qualified PlutusLedgerApi.V1 as Plutus
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as Children
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release as Release
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (forM_, shouldBe)

-- | Establish every input and its deposit with a real accepted funding
-- transaction. Source and output deposits are exactly one ADA each: byte price
-- 1000 times a measured priced size of 1000. Parent and children are undeclared.
fundAccountingScenario :: Accounting.AccountingScenario -> ImpTestM DijkstraEra ReleaseTx
fundAccountingScenario plan = do
  modifyPParams $
    (ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 1_000))
      . (ppMaxTxSizeL .~ 100_000)
  address <- freshKeyAddrNoPtr_
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  let operations = Accounting.topOperations plan : Accounting.subOperations plan
      sourceGroups = map (sourcesForBody address $ Accounting.applicationCoins plan) operations
      sources = concat sourceGroups
      sourceAllocation = foldMap (Pricing.outputDeposit parameters) sources
  funded <-
    submitTx $
      Pricing.declareNetDeposit sourceAllocation $
        mkBasicTx mkBasicTxBody & bodyTxL . outputsTxBodyL .~ SSeq.fromList sources
  state <- Release.readLedger
  let inputGroups =
        [ [txInAt index funded | index <- [offset .. offset + length outputs - 1]]
        | (offset, outputs) <- zip (scanl (+) 0 $ map length sourceGroups) sourceGroups
        ]
      top = proposalBody address (head inputGroups) (Accounting.topOperations plan)
      children = zipWith (proposalBody address) (tail inputGroups) (Accounting.subOperations plan)
      tx = top & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable children
      context = ReleaseTx (Pricing.LedgerState state parameters) tx
      records = recordedAmounts $ liveOutputStore state
  length children `shouldBe` length (tx ^. bodyTxL . subTransactionsTxBodyL)
  forM_ (zip [0 ..] sources) $ \(index, source) -> do
    impGetUTxO (txInAt index funded) >>= (`shouldBe` source)
    Map.lookup (txInAt index funded) records
      `shouldBe` case source of
        LegacyTxOut _ -> Nothing
        NewTxOut _ -> Just Accounting.depositUnit
  Pricing.allocatedDeposits (ledgerState context) tx
    `shouldBe` units (Accounting.allocatedDepositUnits $ Accounting.topOperations plan)
  Pricing.releasedDeposits (ledgerState context) tx
    `shouldBe` units (Accounting.releasedDepositUnits $ Accounting.topOperations plan)
  Children.allocatedDeposits context
    `shouldBe` map (units . Accounting.allocatedDepositUnits) (Accounting.subOperations plan)
  Children.releasedDeposits context
    `shouldBe` map (units . Accounting.releasedDepositUnits) (Accounting.subOperations plan)
  pure context

-- | Convert a fixture count to its specified deposit amount.
units :: Int -> Coin
units count = Coin $ toInteger count * 1_000_000

-- | One implicit funding input followed by the body's Store-backed sources.
-- The translated variant uses the actual Conway-to-Dijkstra output conversion.
sourcesForBody :: Addr -> Coin -> Accounting.BodyOperations -> [TxOut DijkstraEra]
sourcesForBody address application operations =
  implicitSource address application (Accounting.sourceTranslation operations)
    : replicate (Accounting.releasedDepositUnits operations) (unitDepositOutput address $ Coin 10_000_000)

-- | Preserve application ADA while selecting the source's production era conversion.
implicitSource :: Addr -> Coin -> Bool -> TxOut DijkstraEra
implicitSource address amount translated =
  if translated
    then upgradeTxOut @DijkstraEra $ mkBasicTxOutWithImplicitDeposit @ConwayEra address $ inject amount
    else mkBasicTxOutWithImplicitDeposit address $ inject amount

-- | Undeclared body with an implicit settlement output at index zero and the
-- requested Store-backed outputs. Signing later balances application ADA in output
-- zero according to the explicitly supplied local/delegated declaration.
proposalBody :: Typeable l => Addr -> [TxIn] -> Accounting.BodyOperations -> Tx l DijkstraEra
proposalBody address inputs operations =
  mkBasicTx mkBasicTxBody
    & bodyTxL . inputsTxBodyL .~ Set.fromList inputs
    & bodyTxL . outputsTxBodyL
      .~ SSeq.fromList
        ( mkBasicTxOutWithImplicitDeposit address (inject $ Coin 200_000_000)
            : replicate
              (Accounting.allocatedDepositUnits operations)
              ( unitDepositOutput address $
                  if Accounting.emptyApplicationAssets operations then Coin 0 else Coin 10_000_000
              )
        )

-- | Choose an inline byte-string length whose actual encoded output size is 840
-- bytes. Adding the fixed 160-byte charge gives exactly 1000 priced bytes. The
-- search crosses CBOR chunk boundaries instead of assuming a padding length.
unitDepositOutput :: Addr -> Coin -> TxOut DijkstraEra
unitDepositOutput address amount =
  case find ((== 840) . sizedSize . mkSized (eraProtVerLow @DijkstraEra)) (paddedOutputs address amount) of
    Just output -> output
    Nothing -> error "No inline datum length gives the exact one-ADA fixture deposit"

-- | Estimate the byte-string length from a nearby encoded output, then search
-- a small neighborhood. A second CBOR integer width fills any size skipped at a
-- byte-string chunk boundary, so the deposit does not depend on address encoding.
paddedOutputs :: Addr -> Coin -> [TxOut DijkstraEra]
paddedOutputs address amount =
  let measured = sizedSize $ mkSized (eraProtVerLow @DijkstraEra) $ paddedOutput address amount 700 0
      estimatedPadding = 700 + 840 - fromIntegral measured
   in [ paddedOutput address amount padding marker
      | padding <- [estimatedPadding - 4 .. estimatedPadding + 4]
      , marker <- [0, 24]
      ]

-- | Keep datum contents semantically irrelevant while controlling encoded width.
paddedOutput :: Addr -> Coin -> Int -> Integer -> TxOut DijkstraEra
paddedOutput address amount padding marker =
  mkBasicTxOutWithStoreBackedDeposit address (ApplicationAssets $ inject amount)
    & datumTxOutL .~ mkInlineDatum (Plutus.List [Plutus.B $ BS.replicate padding 0, Plutus.I marker])

-- | Balance only child application ADA, then preserve the supplied declarations
-- and Store-backed outputs while ordinary fee fixup adds parent funding/witnesses.
-- NetChange cases use this to prepare funded controls. Balance rejection cases
-- must introduce their imbalance after this preparation or use another builder.
buildAndSignTx :: ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignTx = Release.buildAndSignTx . balanceChildApplicationCoins

-- | Use a genuinely failing script and disjoint collateral after balancing the
-- child application ADA. The supplied ordinary declarations remain unchanged.
buildAndSignPhase2InvalidTx :: ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignPhase2InvalidTx = Release.buildAndSignPhase2InvalidTx . balanceChildApplicationCoins

-- | Prepare individually balanced children using their locally accounted deposits;
-- delegated amounts are left for TopTx funding. This fixture choice does not impose
-- an independent SubTx balance rule. Change only implicit output zero; no Store
-- output is repriced and no declaration is inferred from its operations.
balanceChildApplicationCoins :: ReleaseTx -> ReleaseTx
balanceChildApplicationCoins context =
  context
    { unsignedTx =
        unsignedTx context
          & bodyTxL . subTransactionsTxBodyL
            .~ OMap.fromFoldable
              ( map (balanceChild $ ledgerState context) $
                  OMap.elems $
                    unsignedTx context ^. bodyTxL . subTransactionsTxBodyL
              )
    }

-- | Assign the residual application ADA to the child's implicit settlement output.
balanceChild :: Pricing.LedgerState -> Tx SubTx DijkstraEra -> Tx SubTx DijkstraEra
balanceChild state child =
  case toList $ child ^. bodyTxL . outputsTxBodyL of
    first : rest ->
      let sources = unUTxO $ utxosUtxo $ Pricing.utxoState state
          inputCoins = foldMap (^. coinTxOutL) $ Map.restrictKeys sources (child ^. bodyTxL . inputsTxBodyL)
          outputCoins = foldMap (^. coinTxOutL) rest
          localDeposit = localDeclaredAmount $ child ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL
          settlementCoins = (inputCoins <-> outputCoins) <-> localDeposit
       in child & bodyTxL . outputsTxBodyL .~ SSeq.fromList ((first & coinTxOutL .~ settlementCoins) : rest)
    [] -> error "Accounting child must retain its implicit settlement output"

-- | Funding interpretation of the declaration supplied by the spec. This is
-- solely application balance preparation; required deposits use an independent
-- oracle over the funded Store records and priced output bytes.
localDeclaredAmount :: SubTx.SubTxUTxODepositDeclaration -> Coin
localDeclaredAmount declaration = case declaration of
  SubTx.NoUTxODepositDeclaration -> Coin 0
  SubTx.DeclaresZeroNetUTxODeposit -> Coin 0
  SubTx.DeclaresNetUTxODepositAllocation amount -> unStrictlyPositiveCoin amount
  SubTx.RequestsUTxODepositFromTopTx _ -> Coin 0
  SubTx.DeclaresNetUTxODepositRelease _ SubTx.DelegateToTopTx -> Coin 0
  SubTx.DeclaresNetUTxODepositRelease amount (SubTx.SubTxSettlementOutput _) -> Coin 0 <-> unStrictlyPositiveCoin amount

-- | Change the parent declaration after valid transaction preparation. Re-sign
-- only; keep application amounts and all ordinary inputs/outputs unchanged.
mutateTopTxDeclaration ::
  TopTx.TopTxUTxODepositDeclaration ->
  Tx TopTx DijkstraEra ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
mutateTopTxDeclaration declaration tx =
  rederiveAddrTxWits $ tx & bodyTxL . netUTxODepositChangeTxBodyL .~ declaration

-- | Replace one child's declaration by its preserved order, then re-sign children
-- and parent. No balance fixup can silently repair the intended mismatch.
mutateSubTxDeclaration ::
  Int ->
  SubTx.SubTxUTxODepositDeclaration ->
  Tx TopTx DijkstraEra ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
mutateSubTxDeclaration index declaration tx =
  replaceSubTxDeclarations
    [ if position == index then declaration else child ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL
    | (position, child) <- zip [0 ..] $ OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
    ]
    tx

-- | Replace every ordered child declaration without changing its funded inputs
-- or outputs. Explicitly reject a length mismatch instead of dropping children.
replaceSubTxDeclarations ::
  [SubTx.SubTxUTxODepositDeclaration] ->
  Tx TopTx DijkstraEra ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
replaceSubTxDeclarations declarations tx = do
  let children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
  length declarations `shouldBe` length children
  signedChildren <-
    traverse rederiveAddrTxWits $
      zipWith
        (\declaration child -> child & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ declaration)
        declarations
        children
  rederiveAddrTxWits $ tx & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable signedChildren

-- | Final child identifier after declaration mutation and witness regeneration.
subTxIdAt :: Int -> Tx TopTx DijkstraEra -> TxId
subTxIdAt index tx = txIdTxBody $ (OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL) !! index ^. bodyTxL
