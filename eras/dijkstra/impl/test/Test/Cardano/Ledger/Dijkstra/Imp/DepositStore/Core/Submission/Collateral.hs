{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Real collateral funding and phase-2 preparation. These helpers retain the
-- signed ordinary transaction while changing only its collateral settlement.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Collateral (
  FundingFixture (..),
  implicitInputWithStoreBackedReturn,
  storeBackedInputWithImplicitReturn,
  withCoinFee,
) where

import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Shelley.LedgerState (curPParamsEpochStateL, nesEsL)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val ((<->)), inject)
import Data.Maybe.Strict (StrictMaybe (..), strictMaybeToMaybe)
import qualified Data.Set as Set
import Lens.Micro
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (preparePhase2InvalidTx)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  ReleaseBody (TopTxReleasing),
  ReleaseFixture (..),
  buildTxSpendingStoreBackedOutput,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe)

data FundingFixture = FundingFixture
  { tx :: !(Tx TopTx DijkstraEra)
  , input :: !TxIn
  , inputCoins :: !Coin
  , releasedDeposit :: !Coin
  , returnDeposit :: !Coin
  , minimumFee :: !Coin
  , protocolParameters :: !(PParams DijkstraEra)
  }

-- | Ten ADA of ordinary coins fund a new external return deposit. All source
-- funds come from accepted transactions; the input has no Store record.
implicitInputWithStoreBackedReturn :: ImpTestM DijkstraEra FundingFixture
implicitInputWithStoreBackedReturn = do
  configureFundingPolicy
  address <- freshKeyAddrNoPtr_
  source <- sendCoinTo address $ Coin 10_000_000
  let collateralReturn = mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject $ Coin 5_000_000
  prepareFundingFixture source mempty collateralReturn

-- | The ten application ADA are separate from the input's recorded deposit.
-- An implicit return needs no Store allocation, so that deposit is fee surplus.
storeBackedInputWithImplicitReturn :: ImpTestM DijkstraEra FundingFixture
storeBackedInputWithImplicitReturn = do
  configureFundingPolicy
  source <- buildTxSpendingStoreBackedOutput TopTxReleasing
  address <- freshKeyAddrNoPtr_
  let collateralReturn = mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 5_000_000
  prepareFundingFixture (spendingInput source) (sourceDeposit source) collateralReturn

configureFundingPolicy :: ImpTestM DijkstraEra ()
configureFundingPolicy =
  modifyPParams $
    (ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310))
      . (ppCollateralPercentageL .~ 150)

-- | Supply a fee that remains safely above the minimum and, after the existing
-- 10% fixup buffer, is odd. At 150% this requires rounding up the collateral
-- minimum, allowing the one-lovelace boundary to be checked exactly.
prepareFundingFixture :: TxIn -> Coin -> TxOut DijkstraEra -> ImpTestM DijkstraEra FundingFixture
prepareFundingFixture source released collateralReturn = do
  pp <- getsNES $ nesEsL . curPParamsEpochStateL
  -- The inherited Babbage fixup only handles implicit collateral returns.
  -- Prepare ordinary funding and the script with an implicit return, then
  -- install the tested output variant and sign the final body without fixup.
  let preparationReturn = case collateralReturn of
        ImplicitDepositTxOut _ -> collateralReturn
        StoreBackedTxOut _ ->
          mkBasicTxOutWithImplicitDeposit (collateralReturn ^. addrTxOutL) $
            inject $
              collateralReturn ^. coinTxOutL
  fixed <-
    preparePhase2InvalidTx $
      mkBasicTx mkBasicTxBody
        & bodyTxL . feeTxBodyL .~ Coin 2_000_011
        & bodyTxL . collateralInputsTxBodyL .~ Set.singleton source
        & bodyTxL . totalCollateralTxBodyL .~ SJust (Coin 5_000_000)
        & bodyTxL . collateralReturnTxBodyL .~ SJust preparationReturn
  prepared <- rederiveAddrTxWits $ fixed & bodyTxL . collateralReturnTxBodyL .~ SJust collateralReturn
  prepared ^. bodyTxL . collateralInputsTxBodyL `shouldBe` Set.singleton source
  prepared ^. bodyTxL . collateralReturnTxBodyL `shouldBe` SJust collateralReturn
  let Coin fee = prepared ^. bodyTxL . feeTxBodyL
      percentage = toInteger $ pp ^. ppCollateralPercentageL
  pure
    FundingFixture
      { tx = prepared
      , input = source
      , inputCoins = Coin 10_000_000
      , releasedDeposit = released
      , returnDeposit = TopTx.outputDeposit pp collateralReturn
      , minimumFee = Coin $ (fee * percentage + 99) `div` 100
      , protocolParameters = pp
      }

-- | Choose the signed return so that its coins and any additional deposit leave
-- exactly the requested coin fee. The optional total remains input coins minus
-- return coins, which includes any additional deposit. Re-sign without fixup;
-- otherwise fixup could repair the intentional funding shortfall.
withCoinFee :: Coin -> FundingFixture -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
withCoinFee requestedCoinFee fixture = do
  originalReturn <- expectJust $ strictMaybeToMaybe $ tx fixture ^. bodyTxL . collateralReturnTxBodyL
  let additionalDeposit = max mempty (returnDeposit fixture <-> releasedDeposit fixture)
      returnCoins = inputCoins fixture <-> additionalDeposit <-> requestedCoinFee
      collateralReturn = originalReturn & coinTxOutL .~ returnCoins
  -- These fixtures keep all changed coin amounts in the same CBOR width.
  TopTx.outputDeposit (protocolParameters fixture) collateralReturn `shouldBe` returnDeposit fixture
  rederiveAddrTxWits $
    tx fixture
      & bodyTxL . collateralReturnTxBodyL .~ SJust collateralReturn
      & bodyTxL . totalCollateralTxBodyL .~ SJust (inputCoins fixture <-> returnCoins)
