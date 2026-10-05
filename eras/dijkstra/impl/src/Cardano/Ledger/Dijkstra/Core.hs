{-# LANGUAGE PatternSynonyms #-}

module Cardano.Ledger.Dijkstra.Core (
  DijkstraEraTxBody (..),
  DepositStoreChange (..),
  TopTxWithdrawalSettlement (..),
  DepositStoreSubTxChange (..),
  SubTxWithdrawalTarget (..),
  DijkstraBlockBody (..),
  module Cardano.Ledger.Conway.Core,
  DirectDeposits (..),
  pattern GuardingPurpose,
) where

import Cardano.Ledger.Address (DirectDeposits (..))
import Cardano.Ledger.Conway.Core
import Cardano.Ledger.Dijkstra.BlockBody (DijkstraBlockBody (..))
import Cardano.Ledger.Dijkstra.Scripts (pattern GuardingPurpose)
import Cardano.Ledger.Dijkstra.TxBody (
  DepositStoreChange (..),
  DepositStoreSubTxChange (..),
  DijkstraEraTxBody (..),
  SubTxWithdrawalTarget (..),
  TopTxWithdrawalSettlement (..),
 )
