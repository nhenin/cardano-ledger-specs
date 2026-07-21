{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Dijkstra.Rules.Bbody (
  DijkstraBBODY,
  DijkstraBbodyPredFailure (..),
  conwayToDijkstraBbodyPredFailure,
) where

import Cardano.Ledger.Allegra.Rules (AllegraUtxoPredFailure)
import Cardano.Ledger.Alonzo.PParams (AlonzoEraPParams, ppMaxBlockExUnitsL)
import Cardano.Ledger.Alonzo.Rules (
  AlonzoBbodyEvent (ShelleyInAlonzoEvent),
  AlonzoBbodyPredFailure,
  AlonzoUtxoPredFailure,
  AlonzoUtxosPredFailure,
  AlonzoUtxowPredFailure,
 )
import qualified Cardano.Ledger.Alonzo.Rules as Alonzo
import Cardano.Ledger.Alonzo.Scripts (ExUnits (..))
import Cardano.Ledger.Alonzo.Tx (AlonzoEraTx, totExUnits)
import Cardano.Ledger.Alonzo.TxWits (AlonzoEraTxWits (..))
import Cardano.Ledger.BHeaderView (BHeaderView (..), isOverlaySlot)
import Cardano.Ledger.Babbage.Core (BabbageEraTxBody)
import Cardano.Ledger.Babbage.Rules (BabbageUtxoPredFailure, BabbageUtxowPredFailure)
import Cardano.Ledger.BaseTypes (
  Mismatch (..),
  Nonce,
  PerasCert,
  PerasKey (..),
  Relation (..),
  ShelleyBase,
  StrictMaybe (..),
  epochInfoPure,
  validatePerasCert,
 )
import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Cardano.Ledger.Binary.Coders (Decode (..), Encode (..), decode, encode, (!>), (<!))
import Cardano.Ledger.Block (Block (..))
import Cardano.Ledger.Compactible (fromCompact)
import Cardano.Ledger.Conway.PParams (ConwayEraPParams (..))
import Cardano.Ledger.Conway.Rules (
  ConwayBbodyPredFailure,
  ConwayCertPredFailure,
  ConwayCertsPredFailure,
  ConwayDelegPredFailure,
  ConwayGovPredFailure,
  ConwayUtxosPredFailure,
  alonzoToConwayBbodyPredFailure,
  shelleyToConwayBbodyPredFailure,
 )
import qualified Cardano.Ledger.Conway.Rules as Conway
import Cardano.Ledger.Core
import Cardano.Ledger.Dijkstra.BlockBody (DijkstraEraBlockBody (..))
import Cardano.Ledger.Dijkstra.Era (DijkstraBBODY, DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules.Gov (DijkstraGovPredFailure)
import Cardano.Ledger.Dijkstra.Rules.GovCert (DijkstraGovCertPredFailure)
import Cardano.Ledger.Dijkstra.Rules.Ledger (DijkstraLedgerPredFailure)
import Cardano.Ledger.Dijkstra.Rules.Ledgers ()
import Cardano.Ledger.Dijkstra.Rules.Utxo (DijkstraUtxoPredFailure)
import Cardano.Ledger.Dijkstra.Rules.Utxow (DijkstraUtxowPredFailure)
import Cardano.Ledger.DynamicPricing (
  BlockCapacity (..),
  DynamicPricing (..),
  Inclusion (..),
  InclusionCapacities (..),
  InclusionDelivery (..),
  InclusionPrice (..),
  InclusionUsage (..),
  TxSizeInBytes (..),
  defaultControllerParams,
  endOfBlock,
  optimisticBlockCapacity,
  setBlockDelivery,
  usageOf,
 )
import Cardano.Ledger.DynamicPricing.State (PricingState)
import Cardano.Ledger.Plutus.ExUnits (pointWiseExUnits)
import Cardano.Ledger.Keys (coerceKeyRole)
import Cardano.Ledger.Shelley.BlockBody (incrBlocks)
import Cardano.Ledger.Shelley.LedgerState (LedgerState (..), lsUTxOStateL, utxosPricingL)
import Cardano.Ledger.Slot (epochInfoEpoch, epochInfoFirst)
import Cardano.Ledger.Shelley.Rules (
  BbodyEnv (..),
  ShelleyBbodyPredFailure,
  ShelleyBbodyState (..),
  ShelleyLedgersEnv (..),
  ShelleyLedgersPredFailure,
  ShelleyPoolPredFailure,
  ShelleyUtxoPredFailure,
  ShelleyUtxowPredFailure,
 )
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import Control.DeepSeq (NFData)
import Control.Monad.Trans.Reader (asks)
import Control.State.Transition (
  Embed (..),
  STS (..),
  TransitionRule,
  judgmentContext,
  liftSTS,
  trans,
 )
import qualified Data.Sequence.Strict as StrictSeq
import Control.State.Transition.Extended (TRC (..), failBecause, (?!))
import Data.Sequence (Seq)
import Data.Word (Word32)
import GHC.Generics (Generic)
import Lens.Micro ((%~), (&), (^.))
import NoThunks.Class (NoThunks (..))

data DijkstraBbodyPredFailure era
  = WrongBlockBodySizeBBODY (Mismatch RelEQ Int)
  | InvalidBodyHashBBODY (Mismatch RelEQ (Hash HASH EraIndependentBlockBody))
  | -- | LEDGERS rule subtransition Failures
    LedgersFailure (PredicateFailure (EraRule "LEDGERS" era))
  | TooManyExUnits (Mismatch RelLTEQ ExUnits)
  | BodyRefScriptsSizeTooBig (Mismatch RelLTEQ Int)
  | PrevEpochNonceNotPresent
  | PerasCertValidationFailed PerasCert Nonce
  | -- | Dynamic pricing (B1, spec: @sdChecks@): the optimistic usage exceeds the
    -- endorser-block (EB) byte budget — the optimistic lane's own budget, not the
    -- RB's. The RB byte budget stays the inherited block-body-size check.
    OptimisticOverflowsBlock (Mismatch RelLTEQ Word32)
  | -- | Dynamic pricing (B1, spec: @sdChecks@): the optimistic usage exceeds the
    -- endorser-block (EB) ExUnits budget. The RB ExUnits budget stays the
    -- inherited 'TooManyExUnits' check over the whole block.
    OptimisticOverflowsBlockExUnits (Mismatch RelLTEQ ExUnits)
  deriving (Generic)

instance NFData (PredicateFailure (EraRule "LEDGERS" era)) => NFData (DijkstraBbodyPredFailure era)

deriving instance
  (Era era, Show (PredicateFailure (EraRule "LEDGERS" era))) =>
  Show (DijkstraBbodyPredFailure era)

deriving instance
  (Era era, Eq (PredicateFailure (EraRule "LEDGERS" era))) =>
  Eq (DijkstraBbodyPredFailure era)

deriving anyclass instance
  (Era era, NoThunks (PredicateFailure (EraRule "LEDGERS" era))) =>
  NoThunks (DijkstraBbodyPredFailure era)

instance
  ( Era era
  , EncCBOR (PredicateFailure (EraRule "LEDGERS" era))
  ) =>
  EncCBOR (DijkstraBbodyPredFailure era)
  where
  encCBOR =
    encode . \case
      WrongBlockBodySizeBBODY mm -> Sum WrongBlockBodySizeBBODY 0 !> To mm
      InvalidBodyHashBBODY mm -> Sum (InvalidBodyHashBBODY @era) 1 !> To mm
      LedgersFailure x -> Sum (LedgersFailure @era) 2 !> To x
      TooManyExUnits mm -> Sum TooManyExUnits 3 !> To mm
      BodyRefScriptsSizeTooBig mm -> Sum BodyRefScriptsSizeTooBig 4 !> To mm
      PrevEpochNonceNotPresent -> Sum PrevEpochNonceNotPresent 5
      PerasCertValidationFailed cert nonce ->
        Sum PerasCertValidationFailed 6 !> To cert !> To nonce
      OptimisticOverflowsBlock mm -> Sum OptimisticOverflowsBlock 7 !> To mm
      OptimisticOverflowsBlockExUnits mm -> Sum OptimisticOverflowsBlockExUnits 8 !> To mm

instance
  ( Era era
  , DecCBOR (PredicateFailure (EraRule "LEDGERS" era))
  ) =>
  DecCBOR (DijkstraBbodyPredFailure era)
  where
  decCBOR = decode . Summands "ConwayBbodyPred" $ \case
    0 -> SumD WrongBlockBodySizeBBODY <! From
    1 -> SumD InvalidBodyHashBBODY <! From
    2 -> SumD LedgersFailure <! From
    3 -> SumD TooManyExUnits <! From
    4 -> SumD BodyRefScriptsSizeTooBig <! From
    5 -> SumD PrevEpochNonceNotPresent
    6 -> SumD PerasCertValidationFailed <! From <! From
    7 -> SumD OptimisticOverflowsBlock <! From
    8 -> SumD OptimisticOverflowsBlockExUnits <! From
    n -> Invalid n

type instance EraRuleFailure "BBODY" DijkstraEra = DijkstraBbodyPredFailure DijkstraEra

type instance EraRuleEvent "BBODY" DijkstraEra = AlonzoBbodyEvent DijkstraEra

instance InjectRuleFailure "BBODY" DijkstraBbodyPredFailure DijkstraEra

instance InjectRuleFailure "BBODY" ConwayBbodyPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraBbodyPredFailure

instance InjectRuleFailure "BBODY" AlonzoBbodyPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraBbodyPredFailure . alonzoToConwayBbodyPredFailure

instance InjectRuleFailure "BBODY" ShelleyBbodyPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraBbodyPredFailure . shelleyToConwayBbodyPredFailure

instance InjectRuleFailure "BBODY" ShelleyLedgersPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraBbodyPredFailure . shelleyToConwayBbodyPredFailure . Shelley.LedgersFailure

instance InjectRuleFailure "BBODY" DijkstraLedgerPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" DijkstraUtxowPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" BabbageUtxowPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" AlonzoUtxowPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ShelleyUtxowPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" DijkstraUtxoPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" BabbageUtxoPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" AlonzoUtxoPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" AlonzoUtxosPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ConwayUtxosPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ShelleyUtxoPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" AllegraUtxoPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ConwayCertsPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ConwayCertPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ConwayDelegPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ShelleyPoolPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" DijkstraGovCertPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" ConwayGovPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance InjectRuleFailure "BBODY" DijkstraGovPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraBbodyPredFailure
      . shelleyToConwayBbodyPredFailure
      . Shelley.LedgersFailure
      . injectFailure

instance
  ( Embed (EraRule "LEDGERS" era) (EraRule "BBODY" era)
  , Environment (EraRule "LEDGERS" era) ~ ShelleyLedgersEnv era
  , State (EraRule "LEDGERS" era) ~ LedgerState era
  , Signal (EraRule "LEDGERS" era) ~ Seq (Tx TopTx era)
  , AlonzoEraTxWits era
  , EraBlockBody era
  , AlonzoEraPParams era
  , InjectRuleFailure "BBODY" AlonzoBbodyPredFailure era
  , InjectRuleFailure "BBODY" ConwayBbodyPredFailure era
  , InjectRuleFailure "BBODY" DijkstraBbodyPredFailure era
  , EraRule "BBODY" era ~ DijkstraBBODY era
  , AlonzoEraTx era
  , BabbageEraTxBody era
  , ConwayEraPParams era
  , DijkstraEraBlockBody era
  , PricingState era ~ DynamicPricing era
  ) =>
  STS (DijkstraBBODY era)
  where
  type State (DijkstraBBODY era) = ShelleyBbodyState era

  type Signal (DijkstraBBODY era) = Block BHeaderView era

  type Environment (DijkstraBBODY era) = BbodyEnv era

  type BaseM (DijkstraBBODY era) = ShelleyBase

  type PredicateFailure (DijkstraBBODY era) = DijkstraBbodyPredFailure era

  type Event (DijkstraBBODY era) = AlonzoBbodyEvent era

  initialRules = []
  transitionRules =
    [ dijkstraBbodyTransition @era
        >> Conway.conwayBbodyTransition @era
        >> dijkstraLedgersBbodyTransition @era
        >>= divupTransition @era
    ]

-- | Alonzo's body transition with one Dijkstra addition: before the block's
-- transactions run, the pricing state is stamped with how this block
-- DELIVERS them ('Immediate' payload, or the 'Certified' batch spliced in
-- when a Leios certificate is present) — the UTXO rule prices each
-- transaction by that delivery (the CIP's rb-only premium scope). Forked
-- rather than chained because only the rule that owns the LEDGERS call can
-- alter the state it passes; the sub-rules before it read the original TRC.
dijkstraLedgersBbodyTransition ::
  forall era.
  ( STS (EraRule "BBODY" era)
  , Signal (EraRule "BBODY" era) ~ Block BHeaderView era
  , InjectRuleFailure "BBODY" AlonzoBbodyPredFailure era
  , BaseM (EraRule "BBODY" era) ~ ShelleyBase
  , State (EraRule "BBODY" era) ~ ShelleyBbodyState era
  , Environment (EraRule "BBODY" era) ~ BbodyEnv era
  , Embed (EraRule "LEDGERS" era) (EraRule "BBODY" era)
  , Environment (EraRule "LEDGERS" era) ~ ShelleyLedgersEnv era
  , State (EraRule "LEDGERS" era) ~ LedgerState era
  , Signal (EraRule "LEDGERS" era) ~ Seq (Tx TopTx era)
  , AlonzoEraTxWits era
  , AlonzoEraPParams era
  , DijkstraEraBlockBody era
  , PricingState era ~ DynamicPricing era
  ) =>
  TransitionRule (EraRule "BBODY" era)
dijkstraLedgersBbodyTransition =
  judgmentContext
    >>= \( TRC
             ( BbodyEnv pp account
               , BbodyState ls b
               , Block bh txsSeq
               )
           ) -> do
        let txs = txsSeq ^. txSeqBlockBodyL
            actualBodySize = bBodySize (pp ^. ppProtocolVersionL) txsSeq
            actualBodyHash = hashBlockBody @era txsSeq

        actualBodySize
          == fromIntegral (bhviewBSize bh)
            ?! injectFailure
              ( Alonzo.ShelleyInAlonzoBbodyPredFailure
                  ( Shelley.WrongBlockBodySizeBBODY $
                      Mismatch
                        { mismatchSupplied = actualBodySize
                        , mismatchExpected = fromIntegral $ bhviewBSize bh
                        }
                  )
              )

        actualBodyHash
          == bhviewBHash bh
            ?! injectFailure
              ( Alonzo.ShelleyInAlonzoBbodyPredFailure
                  ( Shelley.InvalidBodyHashBBODY @era $
                      Mismatch
                        { mismatchSupplied = actualBodyHash
                        , mismatchExpected = bhviewBHash bh
                        }
                  )
              )

        let hkAsStakePool = coerceKeyRole $ bhviewID bh
            slot = bhviewSlot bh
        (firstSlotNo, curEpochNo) <- liftSTS $ do
          ei <- asks epochInfoPure
          let curEpochNo = epochInfoEpoch ei slot
          pure (epochInfoFirst ei curEpochNo, curEpochNo)

        -- The Dijkstra addition: stamp the block's delivery before its
        -- transactions are judged and settled.
        let delivery = case txsSeq ^. leiosCertBlockBodyL of
              SJust _ -> Certified
              SNothing -> Immediate
            lsStamped = ls & lsUTxOStateL . utxosPricingL %~ setBlockDelivery delivery

        ls' <-
          trans @(EraRule "LEDGERS" era) $
            TRC (LedgersEnv (bhviewSlot bh) curEpochNo pp account, lsStamped, StrictSeq.fromStrict txs)

        let txTotal, ppMax :: ExUnits
            txTotal = foldMap totExUnits txs
            ppMax = pp ^. ppMaxBlockExUnitsL
        pointWiseExUnits (<=) txTotal ppMax
          ?! injectFailure (Alonzo.TooManyExUnits Mismatch {mismatchSupplied = txTotal, mismatchExpected = ppMax})

        pure $
          BbodyState @era
            ls'
            ( incrBlocks
                (isOverlaySlot firstSlotNo (pp ^. ppDG) slot)
                hkAsStakePool
                b
            )

-- | Close the block for dynamic pricing (spec: the @DIVUP@ rule), running
-- AFTER the block's transactions so it sees the accumulated usage:
--
-- * B1 (@sdChecks@): the optimistic usage fits the endorser-block (EB) hard cap
--   ('optimisticBlockCapacity' — the CIP-164 closure-size limit, the real
--   mainnet budget). Dormant in Praos-only — the shared RB and the inherited
--   'TooManyExUnits' (whole-block ExUnits) bind first — it bites once
--   optimistic txs move to a separate EB in the consensus phase.
-- * B2 (@endOfBlock@): republish the prices ('reprice' — Will's per-lane
--   EIP-1559 controller). Each lane prices on its OWN fill against its OWN
--   budget (urgent: the RB; optimistic: the EB's), so the two lanes move
--   independently and an urgent flood no longer drags the optimistic price up. The prices published here are what the UTXO
--   rule judges the NEXT block's transactions against.
divupTransition ::
  forall era.
  ( State (EraRule "BBODY" era) ~ ShelleyBbodyState era
  , State (EraRule "LEDGERS" era) ~ LedgerState era
  , Environment (EraRule "BBODY" era) ~ BbodyEnv era
  , AlonzoEraPParams era
  , PricingState era ~ DynamicPricing era
  , InjectRuleFailure "BBODY" DijkstraBbodyPredFailure era
  ) =>
  ShelleyBbodyState era ->
  TransitionRule (EraRule "BBODY" era)
divupTransition (BbodyState ls blocksMade) = do
  TRC (BbodyEnv pp _, _, _) <- judgmentContext
  let pricing = ls ^. lsUTxOStateL . utxosPricingL
      -- On a certified round the WHOLE block is the endorser block's cargo
      -- (the certificate-carrying ranking block is payload-free), so B1
      -- bounds the total usage — urgent riders included — against the EB
      -- budgets. On an immediate round the optimistic usage is the check's
      -- subject as before (and zero in practice).
      optimisticUsage = case blockDelivery pricing of
        Certified -> usageOf Urgent (blockUsage pricing) <> usageOf Optimistic (blockUsage pricing)
        Immediate -> usageOf Optimistic (blockUsage pricing)
      TxSizeInBytes optimisticBytes = bytesUsed optimisticUsage
      maxBytes = pp ^. ppMaxBBSizeL
      maxExUnits = pp ^. ppMaxBlockExUnitsL
      floorPrice = InclusionPrice (fromCompact (unCoinPerByte (pp ^. ppTxFeePerByteL)))
      ExUnits maxMem maxSteps = maxExUnits
      -- Pricing target: each lane steers against its OWN budget — the urgent
      -- one against the regular block, the optimistic one against
      -- 'optimisticBlockCapacity' (the endorser block's real mainnet budget).
      -- At realistic traffic the optimistic fill sits far below its target, so
      -- that price rests at the floor: the mechanism's real behaviour.
      capacities =
        InclusionCapacities
          { urgentCapacity = BlockCapacity (toInteger maxBytes)
          , optimisticCapacity = optimisticBlockCapacity
          , urgentExUnitsCapacity = maxExUnits
          , optimisticExUnitsCapacity = optimisticMaxExUnits
          }
      -- Overflow hard cap: the endorser block's own byte budget
      -- ('optimisticBlockCapacity', the CIP-164 closure-size limit). The
      -- execution-unit ceiling scales with how many regular blocks fit in that
      -- budget, pending a real per-endorser-block execution budget.
      optimisticMaxBytes = fromInteger (unBlockCapacity optimisticBlockCapacity)
      optimisticExUnitsFactor =
        fromInteger $ unBlockCapacity optimisticBlockCapacity `div` max 1 (toInteger maxBytes)
      optimisticMaxExUnits =
        ExUnits (optimisticExUnitsFactor * maxMem) (optimisticExUnitsFactor * maxSteps)
  optimisticBytes
    <= optimisticMaxBytes
      ?! injectFailure
        ( OptimisticOverflowsBlock
            Mismatch {mismatchSupplied = optimisticBytes, mismatchExpected = optimisticMaxBytes}
        )
  pointWiseExUnits (<=) (exUnitsUsed optimisticUsage) optimisticMaxExUnits
    ?! injectFailure
      ( OptimisticOverflowsBlockExUnits
          Mismatch {mismatchSupplied = exUnitsUsed optimisticUsage, mismatchExpected = optimisticMaxExUnits}
      )
  pure $!
    BbodyState
      (ls & lsUTxOStateL . utxosPricingL %~ endOfBlock defaultControllerParams floorPrice capacities)
      blocksMade

dijkstraBbodyTransition ::
  forall era.
  ( Signal (EraRule "BBODY" era) ~ Block BHeaderView era
  , State (EraRule "BBODY" era) ~ ShelleyBbodyState era
  , InjectRuleFailure "BBODY" DijkstraBbodyPredFailure era
  , DijkstraEraBlockBody era
  ) =>
  TransitionRule (EraRule "BBODY" era)
dijkstraBbodyTransition = do
  judgmentContext
    >>= \( TRC
             ( _
               , state
               , Block bh bbody
               )
           ) -> do
        case bbody ^. perasCertBlockBodyL of
          SNothing ->
            -- No certificate is present, so no validation is needed.
            --
            -- NOTE: this currently allows the previous epoch nonce to be
            -- missing until an actual certificate appears in a block body.
            -- This could be tightened in the future.
            pure ()
          SJust cert ->
            case bhviewPrevEpochNonce bh of
              Nothing ->
                -- Certificate is present, but previous epoch nonce is missing.
                failBecause (injectFailure PrevEpochNonceNotPresent)
              Just nonce ->
                -- Both certificate and previous epoch nonce are present, so we
                -- can go ahead and validate it.
                validatePerasCert nonce PerasKey cert
                  ?! injectFailure (PerasCertValidationFailed cert nonce)
        pure state

conwayToDijkstraBbodyPredFailure ::
  forall era. ConwayBbodyPredFailure era -> DijkstraBbodyPredFailure era
conwayToDijkstraBbodyPredFailure = \case
  Conway.WrongBlockBodySizeBBODY mm -> WrongBlockBodySizeBBODY mm
  Conway.InvalidBodyHashBBODY mm -> InvalidBodyHashBBODY mm
  Conway.LedgersFailure f -> LedgersFailure f
  Conway.TooManyExUnits mm -> TooManyExUnits mm
  Conway.BodyRefScriptsSizeTooBig mm -> BodyRefScriptsSizeTooBig mm
  Conway.HeaderProtVerTooHigh {} -> error "Impossible: HeaderProtVerTooHigh cannot be triggered in Dijkstra era"

instance
  ( Era era
  , BaseM ledgers ~ ShelleyBase
  , ledgers ~ EraRule "LEDGERS" era
  , STS ledgers
  ) =>
  Embed ledgers (DijkstraBBODY era)
  where
  wrapFailed = LedgersFailure
  wrapEvent = ShelleyInAlonzoEvent . Shelley.LedgersEvent
