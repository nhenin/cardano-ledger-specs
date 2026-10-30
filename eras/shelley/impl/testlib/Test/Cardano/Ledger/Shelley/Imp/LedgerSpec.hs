{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Shelley.Imp.LedgerSpec (
  spec,
) where

import Cardano.Ledger.BaseTypes (inject)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Shelley.Core
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro ((&), (.~), (^.))
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Imp.Common
import Test.Cardano.Ledger.Shelley.ImpTest

spec ::
  forall era.
  ShelleyEraImp era =>
  SpecWith (ImpInit (LedgerSpec era))
spec = describe "LEDGER" $ do
  it "Transactions update UTxO" $ do
    addr1 <- freshKeyAddr_
    let coin1 = Coin 2000000
    tx1 <-
      submitTxAnn "First transaction" . mkBasicTx $
        mkBasicTxBody
          & outputsTxBodyL @era
            .~ SSeq.singleton
              (mkBasicTxOutWithImplicitDeposit addr1 $ inject coin1)
    out1 <- impGetUTxO $ txInAt 0 tx1
    out1 ^. coinTxOutL `shouldBe` coin1
    addr2 <- freshKeyAddr_
    let coin2 = Coin 3000000
    tx2 <-
      submitTxAnn "Second transaction" . mkBasicTx $
        mkBasicTxBody
          & inputsTxBodyL
            .~ Set.singleton
              (txInAt 0 tx1)
          & outputsTxBodyL @era
            .~ SSeq.singleton (mkBasicTxOutWithImplicitDeposit addr2 $ inject coin2)
    out2 <- impGetUTxO $ txInAt 0 tx2
    out2 ^. coinTxOutL `shouldBe` coin2
