{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Real deposit funding by Alice, followed by an independently authorized Bob
-- spend. These fixtures retain the funding provenance without making it part of
-- ledger state: the Store records an output obligation, not a separate owner.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Authorization (
  Mode (..),
  Scenario (..),
  Fixture (..),
  scenarios,
  fund,
  buildAndSignTx,
  spendingWitnesses,
  allWitnesses,
  replaceSpenderWitnessWithFunder,
) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Credential (StakeReference (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Keys (asWitness, witVKeyHash)
import Cardano.Ledger.Shelley.LedgerState (curPParamsEpochStateL, nesEsL)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject, (<->))
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Typeable (Typeable)
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInteger)
import Test.Cardano.Ledger.Core.KeyPair (KeyPair, mkAddr, mkWitnessVKey)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release as Release
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe, shouldNotBe)

-- | The same Bob-owned source is spent by TopTx, by a locally settling child,
-- or by a child delegating its release to TopTx. None changes spending authority.
data Mode = StandaloneTopTx | LocalSubTx | DelegatedSubTx
  deriving (Eq, Show)

-- | Generated application ADA and byte price vary the real source/deposit amounts.
data Scenario = Scenario
  { scenarioMode :: Mode
  , applicationCoins :: Coin
  , bytePrice :: Integer
  }
  deriving (Show)

-- | An undeclared spending proposal and the provenance of its sole Store source.
-- Key hashes use the witness role so tests can compare them directly with signatures.
data Fixture = Fixture
  { mode :: Mode
  , proposal :: ReleaseTx
  , recordedDeposit :: Coin
  , funderKeyHash :: KeyHash Witness
  , spenderKeyHash :: KeyHash Witness
  , sourceInput :: TxIn
  }
  deriving (Show)

-- | Every generated sample exercises standalone, local-child and delegated-child
-- spending. Distinct fixtures are funded separately so accepted cases never reuse inputs.
scenarios :: Gen [Scenario]
scenarios = do
  application <- Coin <$> chooseInteger (10_000_000, 30_000_000)
  price <- chooseInteger (1_000, 4_000)
  pure
    [Scenario selected application price | selected <- [StandaloneTopTx, LocalSubTx, DelegatedSubTx]]

-- | Alice alone funds Bob's new Store-backed output: the creating transaction has
-- exactly one Alice-controlled input and one valid Alice witness, returns her change,
-- and pays its Store allocation plus a generous fixed fee. A separate accepted
-- transaction refreshes the unrelated fee source, because ImpTest otherwise selects
-- Alice's final change output as its next funding root. The accepted allocation
-- transaction establishes the exact Store record consumed by the later release.
fund :: Scenario -> ImpTestM DijkstraEra Fixture
fund Scenario {scenarioMode, applicationCoins, bytePrice} = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin $ fromInteger bytePrice)
  alice <- freshKeyHash @Payment
  bob <- freshKeyHash @Payment
  alice `shouldNotBe` bob
  let aliceAddress = mkAddr alice StakeRefNull
      bobAddress = mkAddr bob StakeRefNull
      aliceFundingCoins = applicationCoins <> Coin 10_000_000
  aliceInput <- sendCoinTo aliceAddress aliceFundingCoins
  feeSource <- getImpRootTxOut
  parameters <- getsNES $ nesEsL . curPParamsEpochStateL
  let source = mkBasicTxOutWithStoreBackedDeposit bobAddress $ ApplicationAssets $ inject applicationCoins
      allocated = Pricing.outputDeposit parameters source
      fee = Coin 2_000_000
      aliceChange = ((aliceFundingCoins <-> applicationCoins) <-> allocated) <-> fee
      funding =
        Pricing.declareNetDeposit allocated $
          mkBasicTx mkBasicTxBody
            & bodyTxL
              . inputsTxBodyL
              .~ Set.singleton aliceInput
            & bodyTxL
              . outputsTxBodyL
              .~ SSeq.fromList
                [ source
                , mkBasicTxOutWithImplicitDeposit aliceAddress $ inject aliceChange
                ]
            & bodyTxL
              . feeTxBodyL
              .~ fee
  signedFunding <- rederiveAddrTxWits funding
  witnessHashes signedFunding `shouldBe` Set.singleton (asWitness alice)
  created <- withNoFixup $ submitTx signedFunding
  created ^. bodyTxL . inputsTxBodyL `shouldBe` Set.singleton aliceInput
  let input = txInAt (0 :: Int) created
  impGetUTxO input >>= (`shouldBe` source)
  refreshFeeSource feeSource
  state <- Release.readLedger
  recorded <- expectJust $ Map.lookup input $ recordedAmounts $ liveOutputStore state
  recorded `shouldBe` allocated
  parentAddress <- freshKeyAddrNoPtr_
  let parent = case scenarioMode of
        StandaloneTopTx -> spendingTx bobAddress input applicationCoins
        _ ->
          mkBasicTx mkBasicTxBody
            & bodyTxL
              . outputsTxBodyL
              .~ SSeq.singleton
                (mkBasicTxOutWithImplicitDeposit parentAddress $ inject $ Coin 10_000_000)
            & bodyTxL
              . subTransactionsTxBodyL
              .~ OMap.fromFoldable
                [spendingTx bobAddress input applicationCoins]
  pure $
    Fixture
      scenarioMode
      (ReleaseTx (Pricing.LedgerState state parameters) parent)
      recorded
      (asWitness alice)
      (asWitness bob)
      input

-- | Consume the still-unspent Imp root saved after Alice's initial funding and
-- return its change with a fixed sufficient fee. This is a separate accepted
-- transaction, never part of Alice's deposit allocation. It restores ample funding
-- under the unrelated original root key for this spend and later generated modes.
refreshFeeSource :: (TxIn, TxOut DijkstraEra) -> ImpTestM DijkstraEra ()
refreshFeeSource (input, output) = do
  let fee = Coin 2_000_000
      feeFunding =
        mkBasicTx mkBasicTxBody
          & bodyTxL . inputsTxBodyL .~ Set.singleton input
          & bodyTxL . outputsTxBodyL .~ SSeq.singleton (output & coinTxOutL %~ (<-> fee))
          & bodyTxL . feeTxBodyL .~ fee
  signed <- rederiveAddrTxWits feeFunding
  withNoFixup $ submitTx_ signed

-- | An undeclared body consumes Bob's source and retains its application ADA in
-- implicit output zero. Declaration-aware preparation adds a local release there
-- or leaves the delegated amount for TopTx, as selected explicitly by the spec.
spendingTx :: Typeable l => Addr -> TxIn -> Coin -> Tx l DijkstraEra
spendingTx address input amount =
  mkBasicTx mkBasicTxBody
    & bodyTxL
      . inputsTxBodyL
      .~ Set.singleton input
    & bodyTxL
      . outputsTxBodyL
      .~ SSeq.singleton
        (mkBasicTxOutWithImplicitDeposit address $ inject amount)

-- | Prepare the explicitly declared proposal using normal fees and witnesses,
-- retaining the source in its selected owner body. The real spender signs there;
-- Alice signs no part of this later transaction.
buildAndSignTx :: Fixture -> ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignTx fixture declared = do
  signed <- Balance.buildAndSignTx declared
  Set.member (spenderKeyHash fixture) (spendingWitnesses fixture signed) `shouldBe` True
  Set.member (funderKeyHash fixture) (allWitnesses signed) `shouldBe` False
  Set.member (sourceInput fixture) (spendingInputs fixture signed) `shouldBe` True
  pure signed

-- | Witnesses on the body that consumes Bob's Store-backed output. Parent fee
-- signatures cannot stand in for a missing signature on the child body.
spendingWitnesses :: Fixture -> Tx TopTx DijkstraEra -> Set (KeyHash Witness)
spendingWitnesses fixture tx = case mode fixture of
  StandaloneTopTx -> witnessHashes tx
  _ -> witnessHashes $ onlyChild tx

-- | Signature key hashes from TopTx and all ordered SubTxs, for proving that the
-- original funder signs nowhere in an accepted spending transaction.
allWitnesses :: Tx TopTx DijkstraEra -> Set (KeyHash Witness)
allWitnesses tx = witnessHashes tx <> foldMap witnessHashes (tx ^. bodyTxL . subTransactionsTxBodyL)

-- | Read a body's address-witness hashes without interpreting deposit declarations.
witnessHashes :: Tx l DijkstraEra -> Set (KeyHash Witness)
witnessHashes tx = Set.map witVKeyHash $ tx ^. witsTxL . addrTxWitsL

-- | Inputs of the body selected by the scenario; the ownership premise survives fixup.
spendingInputs :: Fixture -> Tx TopTx DijkstraEra -> Set TxIn
spendingInputs fixture tx = case mode fixture of
  StandaloneTopTx -> tx ^. bodyTxL . inputsTxBodyL
  _ -> onlyChild tx ^. bodyTxL . inputsTxBodyL

-- | Child scenarios contain exactly the one body that consumes Bob's output.
onlyChild :: Tx TopTx DijkstraEra -> Tx SubTx DijkstraEra
onlyChild tx = case OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL of
  [child] -> child
  _ -> error "Authorization fixture requires exactly one spending SubTx"

-- | Replace Bob's witness with Alice's valid signature over that SAME spending
-- body, retaining all other witnesses. For a child replacement, re-sign only TopTx:
-- its encoded body includes child witnesses, but regenerating child witnesses would
-- silently restore Bob. Witness count, encoded size and fee remain unchanged.
replaceSpenderWitnessWithFunder ::
  Fixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
replaceSpenderWitnessWithFunder fixture signed = do
  alicePair <- getKeyPair $ funderKeyHash fixture
  replaced <- case mode fixture of
    StandaloneTopTx -> pure $ replaceWitness (spenderKeyHash fixture) alicePair signed
    _ -> do
      let child = onlyChild signed
          changedChild = replaceWitness (spenderKeyHash fixture) alicePair child
      changedChild ^. bodyTxL `shouldBe` (child ^. bodyTxL)
      rederiveAddrTxWits $ signed & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable [changedChild]
  Set.member (spenderKeyHash fixture) (allWitnesses replaced) `shouldBe` False
  Set.member (funderKeyHash fixture) (spendingWitnesses fixture replaced) `shouldBe` True
  replaced ^. bodyTxL . feeTxBodyL `shouldBe` (signed ^. bodyTxL . feeTxBodyL)
  replaced ^. sizeTxF `shouldBe` (signed ^. sizeTxF)
  pure replaced

-- | Preserve a body's transaction content while exchanging one equally sized
-- witness. The original key must actually be present: otherwise the fixture is invalid.
replaceWitness :: KeyHash Witness -> KeyPair Witness -> Tx l DijkstraEra -> Tx l DijkstraEra
replaceWitness removed replacement tx =
  let existing = tx ^. witsTxL . addrTxWitsL
      retained = Set.filter ((/= removed) . witVKeyHash) existing
      inserted = Set.insert (mkWitnessVKey (hashAnnotated $ tx ^. bodyTxL) replacement) retained
   in if Set.size retained + 1 /= Set.size existing || Set.size inserted /= Set.size existing
        then error "Authorization witness substitution must exchange exactly one key"
        else tx & witsTxL . addrTxWitsL .~ inserted
