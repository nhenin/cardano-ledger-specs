{-# OPTIONS_GHC -Wno-orphans #-}

-- | Dijkstra's amounts for shared transaction accounting. Collateral settlement
-- uses historical input deposits from the original Store and prices the proposed
-- return using its accepted size and the Store's current calculation:
--
-- @
-- collateralFee = inputADA - returnADA - max 0 (returnDeposit - releasedDeposit)
--               + max 0 (releasedDeposit - returnDeposit)
-- @
--
-- Return terms describe the proposal, even when a retained-key collision prevents
-- insertion; an absent return contributes zero. The shared flow credits the
-- body's declared treasury donation only on the valid path.
module Cardano.Ledger.Dijkstra.State.Accounting () where

import Cardano.Ledger.Conway.TxBody (ConwayEraTxBody (treasuryDonationTxBodyL))
import Cardano.Ledger.Dijkstra.Era (DijkstraEra)
import qualified Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting as DepositStore
import Cardano.Ledger.Dijkstra.Tx ()
import Cardano.Ledger.State.Accounting (EraAccounting (..))
import Lens.Micro ((^.))

instance EraAccounting DijkstraEra where
  -- Reuse the settlement's coin fee plus released deposit surplus unchanged.
  -- Historical deposits remain in the Store's entries, with no duplicate state.
  collateralFee store = DepositStore.collateralFee . DepositStore.collateralDepositSettlement store

  -- Read the declared amount; the shared flow decides whether to credit it.
  treasuryDonation txBody = txBody ^. treasuryDonationTxBodyL
