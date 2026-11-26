{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Era-specific amounts used by transaction accounting. The shared field
-- projections decide when to collect them according to the transaction's validity.
module Cardano.Ledger.State.Accounting.Era (
  EraAccounting (..),
) where

import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core (EraTx, TopTx, TxBody)
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore)

class EraTx era => EraAccounting era where
  -- | Fee credited on phase-2 failure, using the original allocation snapshot.
  -- The era's calculation retains its treatment of the proposed collateral return.
  collateralFee :: UTxOStore era -> TxBody TopTx era -> Coin

  -- | Treasury donation credited on success; zero for eras without donations.
  treasuryDonation :: TxBody TopTx era -> Coin
