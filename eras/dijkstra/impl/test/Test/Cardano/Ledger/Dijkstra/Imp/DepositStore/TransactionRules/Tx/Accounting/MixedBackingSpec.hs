{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Accounting.MixedBackingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  DijkstraUtxoPredFailure (DepositStoreFailure),
 )
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript)
import Cardano.Ledger.Shelley.LedgerState (nesEsL)
import Cardano.Ledger.State
import qualified Cardano.Ledger.State.Accounting.UTxOs.IndexedUTxOs as IndexedUTxOs
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject, (<->))
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Data.Word (Word64)
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, describe, it)
import Test.Cardano.Ledger.Core.Utils (legacyIndexedUTxOs, txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.ADA (actualAda)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (storedDepositTotal)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission as Submission
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  mutateSubTxDeclaration,
  mutateTopTxDeclaration,
  subTxIdAt,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe, withImpInit)
import Test.Cardano.Ledger.Plutus.Examples (alwaysSucceedsWithDatum)

spec :: Spec
spec = describe "Signed backing change for mixed output forms" $
  withImpInit @(LedgerSpec DijkstraEra) $ do
    it "credits 1.6 ADA of historical minimum toward a 2 ADA external deposit" $ do
      address <- freshKeyAddrNoPtr_
      setPrice 6_400
      input <- sendCoinTo address $ Coin 10_000_000
      setPrice 8_000
      -- Renew the fee input at the creation price so its backing cancels change.
      submitTx_ $ mkBasicTx mkBasicTxBody
      checkSettlement input (externalOutput address $ Coin 8_000_000) (Coin 400_000) (Coin 2_000_000)
    it "charges a legacy-mode parent only the delegated 0.4 ADA" $ do
      address <- freshKeyAddrNoPtr_
      setPrice 6_400
      input <- sendCoinTo address $ Coin 10_000_000
      setPrice 8_000
      scriptInput <- produceScript . hashPlutusScript $ alwaysSucceedsWithDatum SPlutusV3
      scriptOutput <- impGetUTxO scriptInput
      let required = Coin 400_000
          child =
            mkBasicTx mkBasicTxBody
              & bodyTxL . inputsTxBodyL .~ Set.singleton input
              & bodyTxL . outputsTxBodyL .~ SSeq.singleton (externalOutput address $ Coin 8_400_000)
              & bodyTxL . subTxNetUTxODepositChangeTxBodyL
                .~ SubTx.RequestsUTxODepositFromTopTx (positiveAmount 400_000)
      signed <-
        fixupTx $
          TopTx.declareNetDeposit required $
            mkTopTxWithSubTxs [child]
              & bodyTxL . inputsTxBodyL .~ Set.singleton scriptInput
              & bodyTxL . outputsTxBodyL .~ SSeq.singleton scriptOutput
      -- The child's ten ADA covers 8.4 ADA of value and 1.6 ADA of backing.
      -- No balancing SubTx should be added by the legacy-mode fixture.
      length (signed ^. bodyTxL . subTransactionsTxBodyL) `shouldBe` 1
      checkSignedSettlement required (Coin 2_000_000) signed
    it "checks TopTx settlement when a minimum-ADA-only child omits its declaration" $ do
      address <- freshKeyAddrNoPtr_
      setPrice 8_000
      input <- sendCoinTo address $ Coin 10_000_000
      let release = Coin 2_000_000
          child = mkBasicTx mkBasicTxBody & bodyTxL . inputsTxBodyL .~ Set.singleton input
      signed <- fixupTx $ TopTx.declareNetDeposit (mempty <-> release) $ mkTopTxWithSubTxs [child]
      missing <-
        mutateTopTxDeclaration
          (TopTx.DeclaresNetUTxODepositRelease (positiveAmount 2_000_000) TopTx.NoTopTxSettlement)
          signed
      Submission.submitTx missing
        >>= Submission.isRejectedOnlyWith (DepositStoreFailure @DijkstraEra $ MissingTopTxSettlement release)
      Submission.submitTx signed >>= Submission.isAccepted
    it "caps an imported input's 3 ADA minimum at its 2 ADA balance" $ do
      address <- freshKeyAddrNoPtr_
      setPrice 4_000
      input <- sendCoinTo address $ Coin 2_000_000
      setPrice 12_000
      -- A fork retains all minimum-ADA UTxOs and assigns the initial formula
      -- to them, including outputs admitted under an older, lower minimum.
      let initialHistory = mkDepositFormulaHistory $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 12_000
      modifyNES $
        utxoStoreL
          %~ mkUTxOStore initialHistory . legacyIndexedUTxOs . IndexedUTxOs.mapTxOuts id . allocations
      checkSettlement input (externalOutput address mempty) (Coin 1_000_000) (Coin 3_000_000)
    it "declares zero and releases 2 ADA from the Store into a minimum-ADA output" $ do
      address <- freshKeyAddrNoPtr_
      setPrice 8_000
      submitTx_ $ mkBasicTx mkBasicTxBody
      funding <-
        submitTx $
          TopTx.declareNetDeposit (Coin 2_000_000) $
            mkBasicTx mkBasicTxBody
              & bodyTxL . outputsTxBodyL .~ SSeq.singleton (externalOutput address $ Coin 10_000_000)
      checkSettlement
        (txInAt (0 :: Int) funding)
        (mkBasicTxOutWithMinAda address $ inject $ Coin 12_000_000)
        mempty
        (Coin (-2_000_000))

setPrice :: Word64 -> ImpTestM DijkstraEra ()
setPrice rate = modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin rate)

externalOutput :: Addr -> Coin -> TxOut DijkstraEra
externalOutput address = mkBasicTxOutWithDeposit address . ApplicationAssets . inject

-- | The child owns the conversion. The parent funds fees separately, declares
-- the same batch net and covers any shortfall in the child's serialized values.
checkSettlement :: TxIn -> TxOut DijkstraEra -> Coin -> Coin -> ImpTestM DijkstraEra ()
checkSettlement input output required movement = do
  let child =
        mkBasicTx mkBasicTxBody
          & bodyTxL . inputsTxBodyL .~ Set.singleton input
          & bodyTxL . outputsTxBodyL .~ SSeq.singleton output
          & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ childDeclaration required
  signed <- fixupTx $ TopTx.declareNetDeposit required $ mkTopTxWithSubTxs [child]
  checkSignedSettlement required movement signed

checkSignedSettlement :: Coin -> Coin -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkSignedSettlement required movement signed = do
  wrongParent <- mutateTopTxDeclaration (TopTx.netDepositDeclaration movement) signed
  Submission.submitTx wrongParent
    >>= Submission.isRejectedWith
      (DepositStoreFailure @DijkstraEra $ InexactTopTxDepositChange movement required)
  wrongChild <- mutateSubTxDeclaration 0 (childDeclaration movement) signed
  Submission.submitTx wrongChild
    >>= Submission.isRejectedWith
      ( DepositStoreFailure @DijkstraEra $
          InexactSubTxDepositChange (subTxIdAt 0 wrongChild) movement required
      )
  before <- getsNES nesEsL
  beforeStore <- storedDepositTotal <$> getUTxOStore
  Submission.submitTx signed >>= Submission.isAccepted
  storedDepositTotal <$> getUTxOStore >>= (`shouldBe` (beforeStore <> movement))
  actualAda <$> getsNES nesEsL >>= (`shouldBe` actualAda before)

childDeclaration :: Coin -> SubTx.SubTxUTxODepositDeclaration
childDeclaration (Coin amount)
  | amount > 0 = SubTx.DeclaresNetUTxODepositAllocation $ positiveAmount amount
  | amount < 0 =
      SubTx.DeclaresNetUTxODepositRelease (positiveAmount $ negate amount) SubTx.DelegateToTopTx
  | otherwise = SubTx.DeclaresZeroNetUTxODeposit
