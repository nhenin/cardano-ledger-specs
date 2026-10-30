{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Funded transactions for observing ledger effects. Exact declarations and
-- signatures are preparation here: their validation belongs to TransactionRules.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects (
  ordinaryScenarios,
  buildAndSignOrdinary,
  buildAndSignDelegatedOrdinary,
  buildAndSignOrdinaryPhase2Invalid,
  declaredOrdinaryProposal,
  buildAndSignNoncanonicalAllocation,
  buildAndSignNoncanonicalAllocationAtRate,
  buildAndSignNoncanonicalSubAllocation,
  withNoncanonicalOutput,
  restoreAccountingState,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import qualified Cardano.Ledger.Binary as Binary
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (AccountingState, esLStateL, lsAccountingStateL, nesEsL)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import Data.Foldable (toList)
import Data.Maybe (listToMaybe)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import Data.Typeable (Typeable)
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario,
  bodyOperations,
  scenario,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx as Accounting
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as Context
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting as Submission
import Test.Cardano.Ledger.Dijkstra.ImpTest (
  ImpTestM,
  fixupTx,
  freshKeyAddrNoPtr_,
  modifyNES,
  modifyPParams,
  rederiveAddrTxWits,
 )
import Test.Cardano.Ledger.Imp.Common (expectJust, expectRight, shouldBe)

-- | Every sample contains absent activity, allocation, release, mixed batch
-- activity and a zero-net replacement. Equal outputs occupy distinct indices;
-- the batch variants also repeat output values in different child bodies.
ordinaryScenarios :: Gen [AccountingScenario]
ordinaryScenarios = do
  magnitude <- chooseInt (1, 3)
  sequence
    [ scenario (bodyOperations 0 0) []
    , scenario (bodyOperations magnitude 0) []
    , scenario (bodyOperations 0 magnitude) []
    , scenario
        (bodyOperations magnitude magnitude)
        [bodyOperations magnitude 0, bodyOperations 0 magnitude, bodyOperations 0 0]
    , scenario
        (bodyOperations (magnitude + 1) magnitude)
        [bodyOperations 2 1, bodyOperations 0 1, bodyOperations 1 1]
    ]

-- | Establish every source with an accepted funding transaction, then sign an
-- exact, application-balanced ordinary batch. Do not submit the returned tx.
buildAndSignOrdinary :: AccountingScenario -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignOrdinary plan =
  Submission.fundAccountingScenario plan >>= Submission.buildAndSignTx . declaredOrdinaryProposal

-- | Keep the complete ordinary batch, including its Store operations, while an
-- actual failing TopTx script selects the disjoint collateral-only transition.
buildAndSignOrdinaryPhase2Invalid ::
  AccountingScenario -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignOrdinaryPhase2Invalid plan =
  Submission.fundAccountingScenario plan
    >>= Submission.buildAndSignPhase2InvalidTx . declaredOrdinaryProposal

-- | The same independently funded operations, with nonzero child changes
-- delegated to TopTx. Delegation changes funding responsibility, not Store effects.
buildAndSignDelegatedOrdinary :: AccountingScenario -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignDelegatedOrdinary plan = do
  proposal <- declaredOrdinaryProposal <$> Submission.fundAccountingScenario plan
  let total = Context.netDeposit proposal
      parent = case total of
        Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
        Coin amount
          | amount < 0 ->
              TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ negate amount)
                (TopTx.TopTxSettlementOutput $ TxIx 0)
        _ -> TopTx.DeclaresZeroNetUTxODeposit
      children =
        [ case child ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL of
            SubTx.DeclaresNetUTxODepositAllocation amount -> SubTx.RequestsUTxODepositFromTopTx amount
            SubTx.DeclaresNetUTxODepositRelease amount _ -> SubTx.DeclaresNetUTxODepositRelease amount SubTx.DelegateToTopTx
            declaration -> declaration
        | child <- OMap.elems $ Context.unsignedTx proposal ^. bodyTxL . subTransactionsTxBodyL
        ]
  Submission.buildAndSignTx $ Context.addDeclaration (Declarations parent children) proposal

-- | Give children their local exact changes and TopTx the aggregate. A negative
-- total selects TopTx output zero only if TopTx itself receives a net release;
-- otherwise the locally settling children receive the complete release.
declaredOrdinaryProposal :: ReleaseTx -> ReleaseTx
declaredOrdinaryProposal proposal =
  Accounting.addTopDeclaration
    ( case Context.netDeposit proposal of
        Coin amount | amount > 0 -> TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
        Coin amount
          | amount < 0 ->
              TopTx.DeclaresNetUTxODepositRelease
                (positiveAmount $ negate amount)
                ( if Accounting.ownNetDeposit proposal < Coin 0
                    then TopTx.TopTxSettlementOutput $ TxIx 0
                    else TopTx.NoTopTxSettlement
                )
        _ -> TopTx.DeclaresZeroNetUTxODeposit
    )
    (Accounting.withExactLocalSubTxDeclarations proposal)

-- | Create a real signed body whose Store output uses an indefinite CBOR map.
-- It decodes to the same output as the canonical definite map, but costs one
-- additional accepted byte. Decode the complete modified body before signing;
-- never manufacture a 'Binary.Sized' value or edit its cached size.
-- The returned byte count is measured directly from the supplied wire encoding.
buildAndSignNoncanonicalAllocation :: Coin -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra, Int)
buildAndSignNoncanonicalAllocation = buildAndSignNoncanonicalAllocationAtRate (CoinPerByte $ CompactCoin 1000)

-- | Allocate under the supplied rate so one reachable ledger can retain several
-- creation prices. The size still comes from decoding the actual accepted bytes.
buildAndSignNoncanonicalAllocationAtRate ::
  CoinPerByte -> Coin -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra, Int)
buildAndSignNoncanonicalAllocationAtRate rate@(CoinPerByte (CompactCoin price)) coins = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ rate
  address <- freshKeyAddrNoPtr_
  let output = mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject coins
      version = eraProtVerLow @DijkstraEra
      canonical = BSL.toStrict $ Binary.serialize version output
      noncanonical = BS.cons 0xbf (BS.tail canonical) <> BS.singleton 0xff
      acceptedBytes = BS.length noncanonical
      requiredDeposit = Coin $ toInteger price * (160 + toInteger acceptedBytes)
  -- The fixture has just address and applicationAssets, hence a two-field map.
  BS.head canonical `shouldBe` 0xa2
  Binary.decodeFull @(TxOut DijkstraEra) version (BSL.fromStrict noncanonical) `shouldBe` Right output
  prepared <-
    fixupTx $
      Pricing.declareNetDeposit requiredDeposit $
        mkBasicTx mkBasicTxBody
          & bodyTxL . outputsTxBodyL .~ SSeq.singleton output
          & bodyTxL . feeTxBodyL .~ Coin 2000000
  let bodyBytes = BSL.toStrict $ Binary.serialize version $ prepared ^. bodyTxL
      (prefix, suffix) = BS.breakSubstring canonical bodyBytes
      modifiedBytes = prefix <> noncanonical <> BS.drop (BS.length canonical) suffix
  BS.null suffix `shouldBe` False
  decoded <-
    expectRight $
      Binary.decodeFullAnnotator
        version
        "noncanonical allocation body"
        Binary.decCBOR
        (BSL.fromStrict modifiedBytes)
  acceptedOutput <- expectJust $ listToMaybe $ toList $ decoded ^. sizedOutputsTxBodyL
  fromIntegral (Binary.sizedSize acceptedOutput) `shouldBe` acceptedBytes
  Binary.sizedValue acceptedOutput `shouldBe` output
  Binary.serialize version decoded `shouldBe` BSL.fromStrict modifiedBytes
  signed <- rederiveAddrTxWits $ prepared & bodyTxL .~ decoded
  Binary.serialize version (signed ^. bodyTxL) `shouldBe` BSL.fromStrict modifiedBytes
  pure (signed, acceptedBytes)

-- | The child creates a noncanonical output and delegates its deposit funding to
-- TopTx. Decode and sign the child first, then sign the parent with its final ID.
buildAndSignNoncanonicalSubAllocation ::
  Coin -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra, TxIn, Int)
buildAndSignNoncanonicalSubAllocation coins = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 1000)
  address <- freshKeyAddrNoPtr_
  let output = mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject coins
      acceptedBytes = fromIntegral (BSL.length $ Binary.serialize (eraProtVerLow @DijkstraEra) output) + 1
      deposit = 1000 * (160 + toInteger acceptedBytes)
      child =
        mkBasicTx mkBasicTxBody
          & bodyTxL . outputsTxBodyL .~ SSeq.singleton output
          & bodyTxL . subTxNetUTxODepositChangeTxBodyL
            .~ SubTx.RequestsUTxODepositFromTopTx (positiveAmount deposit)
  prepared <-
    fixupTx $
      Pricing.declareNetDeposit (Coin deposit) $
        mkBasicTx mkBasicTxBody
          & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable [child]
          & bodyTxL . feeTxBodyL .~ Coin 2000000
  preparedChild <-
    expectJust $ listToMaybe $ OMap.elems $ prepared ^. bodyTxL . subTransactionsTxBodyL
  (signedChild, measuredBytes) <- withNoncanonicalOutput preparedChild output
  measuredBytes `shouldBe` acceptedBytes
  accepted <- expectJust $ listToMaybe $ toList $ signedChild ^. bodyTxL . sizedOutputsTxBodyL
  fromIntegral (Binary.sizedSize accepted) `shouldBe` measuredBytes
  signed <-
    rederiveAddrTxWits $
      prepared & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable [signedChild]
  pure (signed, txInAt 0 signedChild, measuredBytes)

-- | Change only an output's CBOR map framing inside a prepared transaction.
-- Witnesses are rederived without balancing or replacing the decoded body.
withNoncanonicalOutput ::
  forall l.
  Typeable l =>
  Tx l DijkstraEra ->
  TxOut DijkstraEra ->
  ImpTestM DijkstraEra (Tx l DijkstraEra, Int)
withNoncanonicalOutput prepared output = do
  let version = eraProtVerLow @DijkstraEra
      canonical = BSL.toStrict $ Binary.serialize version output
      noncanonical = BS.cons 0xbf (BS.tail canonical) <> BS.singleton 0xff
      acceptedBytes = BS.length noncanonical
      bodyBytes = BSL.toStrict $ Binary.serialize version $ prepared ^. bodyTxL
      (prefix, suffix) = BS.breakSubstring canonical bodyBytes
      modifiedBytes = prefix <> noncanonical <> BS.drop (BS.length canonical) suffix
  (BS.head canonical >= 0xa0 && BS.head canonical <= 0xb7) `shouldBe` True
  BS.null suffix `shouldBe` False
  Binary.decodeFull @(TxOut DijkstraEra) version (BSL.fromStrict noncanonical) `shouldBe` Right output
  decoded <-
    expectRight $
      Binary.decodeFullAnnotator
        version
        "noncanonical stored output"
        Binary.decCBOR
        (BSL.fromStrict modifiedBytes)
  signed <- rederiveAddrTxWits $ prepared & bodyTxL .~ decoded
  Binary.serialize version (signed ^. bodyTxL) `shouldBe` BSL.fromStrict modifiedBytes
  pure (signed, acceptedBytes)

-- | Restore the accounting snapshot through its CBOR codec. Sharing starts with
-- an empty interning table; certificate and governance state remain unchanged.
restoreAccountingState :: AccountingState DijkstraEra -> ImpTestM DijkstraEra ()
restoreAccountingState snapshot = do
  let version = eraProtVerLow @DijkstraEra
  restored <-
    expectRight
      $ Binary.decodeFullDecoder
        version
        "AccountingState"
        (Binary.decNoShareCBOR @(AccountingState DijkstraEra))
      $ Binary.serialize version snapshot
  modifyNES $ nesEsL . esLStateL . lsAccountingStateL .~ restored
