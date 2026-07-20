{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Test.Cardano.Ledger.Dijkstra.Imp.UtxoSpec (spec) where

import Cardano.Ledger.Address (AccountAddress (..), AccountId (..), Addr (..))
import Cardano.Ledger.BaseTypes (Inject (..), Mismatch (..), Network (..), StrictMaybe (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Credential (Credential (..), StakeReference (..))
import Cardano.Ledger.Dijkstra.Core (
  BabbageEraTxBody (..),
  EraTx (..),
  EraTxBody (..),
  EraTxOut (..),
  InjectRuleFailure (..),
 )
import Cardano.Ledger.Dijkstra.Rules (DijkstraUtxoPredFailure (..))
import Cardano.Ledger.Dijkstra.TxBody (DijkstraEraTxBody (..))
import Cardano.Ledger.DynamicPricing (
  DynamicPricing (..),
  Inclusion (..),
  InclusionPrice (..),
  InclusionPrices (..),
  MinimumTxFee (..),
  PricingState,
  Quote (..),
  currentPrice,
  drainRefunds,
  minimumTxFee,
  pendingRefunds,
  quoteFor,
 )
import Cardano.Ledger.Shelley.LedgerState (UTxOState (..), esLStateL, lsUTxOStateL, nesEsL, utxosPricingL)
import Cardano.Ledger.Tools (ensureMinCoinTxOut)
import Cardano.Ledger.Val ((<->))
import qualified Data.Map.Strict as Map
import Lens.Micro ((%~), (&), (.~), (^.))
import Test.Cardano.Ledger.Dijkstra.ImpTest (
  DijkstraEraImp,
  ImpInit,
  LedgerSpec,
  freshKeyAddr,
  freshKeyHash,
  getsNES,
  getsPParams,
  modifyNES,
  sendCoinTo,
  submitFailingTx,
  submitFailingTxM,
  submitTx,
 )
import Test.Cardano.Ledger.Imp.Common (SpecWith, arbitrary, describe, it, shouldBe)

spec ::
  forall era.
  ( DijkstraEraImp era
  , PricingState era ~ DynamicPricing era
  ) =>
  SpecWith (ImpInit (LedgerSpec era))
spec = do
  describe "Dynamic pricing" $ do
    it "U1: rejects a bid below the lane's quote" $ do
      (_, addr) <- freshKeyAddr
      txIn <- sendCoinTo addr (Coin 10000000)
      -- Pin the urgent rate well above the classic min-fee rate: the fixup
      -- raises the bid only to the CLASSIC min fee, so declaring Urgent
      -- leaves the fixed-up bid under the quote and U1 fires, with no
      -- hand-set fee — whatever the genesis calibration happens to be.
      modifyNES $
        nesEsL . esLStateL . lsUTxOStateL . utxosPricingL
          %~ \ps -> ps {publishedPrices = InclusionPrices (InclusionPrice (Coin 440)) (optimistic (publishedPrices ps))}
      pp <- getsPParams id
      pricing <- utxosPricing <$> getsNES (nesEsL . esLStateL . lsUTxOStateL)
      let tx =
            mkBasicTx mkBasicTxBody
              & bodyTxL . inputsTxBodyL .~ [txIn]
              & bodyTxL . inclusionTxBodyL .~ Urgent
      submitFailingTxM tx $ \txFixed -> do
        let bid = txFixed ^. bodyTxL . feeTxBodyL
            Quote quote = quoteFor pp txFixed (currentPrice Urgent pricing)
        pure [injectFailure $ BidBelowQuote Mismatch{mismatchSupplied = bid, mismatchExpected = quote}]

    it "U2: splits the bid — base stays in the fee pot, premium donated, the rest owed back" $ do
      (_, addr) <- freshKeyAddr
      txIn <- sendCoinTo addr (Coin 20000000)
      refundCred <- KeyHashObj <$> freshKeyHash
      pp <- getsPParams id
      utxosBefore <- getsNES (nesEsL . esLStateL . lsUTxOStateL)
      -- An explicit generous bid keeps the urgent quote covered (the fixup keeps
      -- a nonzero supplied fee), so the tx is accepted and the split runs with a
      -- premium that is genuinely positive: urgent rate 2x44 > minFeeA.
      let tx =
            mkBasicTx mkBasicTxBody
              & bodyTxL . inputsTxBodyL .~ [txIn]
              & bodyTxL . feeTxBodyL .~ Coin 5000000
              & bodyTxL . inclusionTxBodyL .~ Urgent
              & bodyTxL . feeRefundAccountTxBodyL .~ SJust (AccountAddress Testnet (AccountId refundCred))
      txFixed <- submitTx tx
      utxosAfter <- getsNES (nesEsL . esLStateL . lsUTxOStateL)
      let bid = txFixed ^. bodyTxL . feeTxBodyL
          MinimumTxFee base = minimumTxFee pp txFixed
          Quote quote = quoteFor pp txFixed (currentPrice Urgent (utxosPricing utxosBefore))
          (owed, _) = drainRefunds (pendingRefunds (utxosPricing utxosAfter))
      -- Value conservation across the pots: base + premium + refund = bid, and
      -- nothing else may drain them. The refund credential is unregistered on
      -- purpose: the refund must sit in the pending pot, not vanish.
      (utxosFees utxosAfter <-> utxosFees utxosBefore) `shouldBe` base
      (utxosDonation utxosAfter <-> utxosDonation utxosBefore) `shouldBe` (quote <-> base)
      Map.lookup refundCred owed `shouldBe` Just (bid <-> quote)

  describe "Collaterals" $ do
    it "Fails to submit a transaction containing a Ptr in collateral return" $ do
      cred <- KeyHashObj <$> freshKeyHash
      ptr <- arbitrary
      pp <- getsPParams id
      let
        ptrAddr = Addr Testnet cred (StakeRefPtr ptr)
        ptrOutput = ensureMinCoinTxOut pp $ mkBasicTxOut ptrAddr . inject $ Coin 100
        tx =
          mkBasicTx mkBasicTxBody
            & bodyTxL . collateralReturnTxBodyL .~ SJust ptrOutput
      submitFailingTx tx [injectFailure $ PtrPresentInCollateralReturn ptrOutput]
