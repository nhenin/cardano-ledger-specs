{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
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
#if __GLASGOW_HASKELL__ >= 910
-- See https://gitlab.haskell.org/ghc/ghc/-/issues/27342
{-# OPTIONS_GHC -fno-spec-eval #-}
#endif

module Cardano.Ledger.Dijkstra.Rules.Utxo (
  UTXO,
  UtxoEnv (..),
  DijkstraUtxoPredFailure (..),
  conwayToDijkstraUtxoPredFailure,
) where

import qualified Cardano.Ledger.Allegra.Rules as Allegra
import qualified Cardano.Ledger.Alonzo.Rules as Alonzo
import Cardano.Ledger.Alonzo.TxWits (unRedeemersL)
import Cardano.Ledger.Babbage.Collateral (collOuts)
import qualified Cardano.Ledger.Babbage.Rules as Babbage
import Cardano.Ledger.BaseTypes (
  Mismatch (..),
  Network,
  Relation (..),
  ShelleyBase,
  SlotNo,
  StrictMaybe (..),
  epochInfo,
  networkId,
  systemStart,
 )
import Cardano.Ledger.Binary (
  DecCBOR (..),
  EncCBOR (..),
  Sized (..),
 )
import Cardano.Ledger.Binary.Coders (
  Decode (..),
  Encode (..),
  decode,
  encode,
  (!>),
  (<!),
 )
import Cardano.Ledger.Coin (Coin (..), DeltaCoin)
import Cardano.Ledger.Conway.Core
import qualified Cardano.Ledger.Conway.Rules as Conway
import Cardano.Ledger.Conway.State
import Cardano.Ledger.Credential (StakeReference (..))
import Cardano.Ledger.Dijkstra.Era (DijkstraEra, UTXO)
import qualified Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting as DepositStore
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Collateral (validateCollateralFunding)
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Declaration (
  DepositStoreDeclarationFailure (..),
  DepositStoreOutputDeclarationFailure (..),
  validateTopTxAllocationDeclarationPresence,
  validateTopTxNetUTxODepositDeclaration,
  validateTopTxReleaseDeclarationPresence,
 )
import Cardano.Ledger.Dijkstra.Rules.Utxos ()
import Cardano.Ledger.Dijkstra.TxBody (DijkstraEraTxBody (..))
import Cardano.Ledger.Dijkstra.UTxO (
  DijkstraEraUTxO,
  dijkstraConsumed,
  plutusLegacyModeStAnnTxG,
 )
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.Plutus (OrdExUnits)
import Cardano.Ledger.Rules.ValidationMode (Test, failOnJustStatic, runTest, runTestOnSignal)
import Cardano.Ledger.Shelley.LedgerState (UTxOState (..), utxosFeesL, utxosUtxo)
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import Cardano.Ledger.Shelley.UTxO (produced)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject)
import Control.DeepSeq (NFData)
import Control.Exception (throw)
import Control.Monad (when)
import Control.Monad.Trans.Reader (asks)
import Control.State.Transition.Extended (
  AssertionException (..),
  AssertionViolation (..),
  Embed (..),
  Rule,
  STS (..),
  TRC (..),
  TransitionRule,
  judgmentContext,
  liftSTS,
  tellEvent,
  trans,
  validate,
 )
import Data.Bifunctor
import Data.Foldable (toList)
import Data.List.NonEmpty (NonEmpty)
import Data.Map.NonEmpty (NonEmptyMap)
import Data.Set.NonEmpty (NonEmptySet)
import Data.Word (Word16, Word32)
import GHC.Generics (Generic)
import Lens.Micro
import Validation (Validation, failureUnless)

data UtxoEnv era = UtxoEnv
  { ueSlot :: SlotNo
  , uePParams :: PParams era
  , uePState :: PState era
  , ueOriginalCertState :: CertState era
  , uePreviousUTxOStore :: UTxOStore era
  }

-- | Predicate failure for the Dijkstra Era
data DijkstraUtxoPredFailure era
  = -- | Subtransition Failures
    UtxosFailure (PredicateFailure (EraRule "UTXOS" era))
  | -- | The bad transaction inputs
    BadInputsUTxO (NonEmptySet TxIn)
  | OutsideValidityIntervalUTxO
      -- | transaction's validity interval
      ValidityInterval
      -- | current slot
      SlotNo
  | MaxTxSizeUTxO (Mismatch RelLTEQ Word32)
  | InputSetEmptyUTxO
  | FeeTooSmallUTxO
      (Mismatch RelGTEQ Coin)
  | ValueNotConservedUTxO
      (Mismatch RelEQ (Value era)) -- Serialise consumed first, then produced
  | -- | the set of addresses with incorrect network IDs
    WrongNetwork
      -- | the expected network id
      Network
      -- | the set of addresses with incorrect network IDs
      (NonEmptySet Addr)
  | -- | list of supplied bad transaction outputs
    OutputBootAddrAttrsTooBig (NonEmpty (TxOut era))
  | -- | list of supplied bad transaction output triples (actualSize,PParameterMaxValue,TxOut)
    OutputTooBigUTxO (NonEmpty (Int, Int, TxOut era))
  | InsufficientCollateral
      -- | balance computed
      DeltaCoin
      -- | the required collateral for the given fee
      Coin
  | -- | The UTxO entries which have the wrong kind of script
    ScriptsNotPaidUTxO (NonEmptyMap TxIn (TxOut era))
  | ExUnitsTooBigUTxO
      (Mismatch RelLTEQ OrdExUnits)
  | -- | The inputs marked for use as fees contain non-ADA tokens
    CollateralContainsNonADA (Value era)
  | -- | Wrong Network ID in body
    WrongNetworkInTxBody
      (Mismatch RelEQ Network)
  | -- | slot number outside consensus forecast range
    OutsideForecast SlotNo
  | -- | There are too many collateral inputs
    TooManyCollateralInputs
      (Mismatch RelLTEQ Word16)
  | NoCollateralInputs
  | -- | The collateral is not equivalent to the total collateral asserted by the transaction
    IncorrectTotalCollateralField
      -- | collateral provided
      DeltaCoin
      -- | collateral amount declared in transaction body
      Coin
  | -- | list of supplied transaction outputs that are too small,
    -- together with the minimum value for the given output.
    BabbageOutputTooSmallUTxO (NonEmpty (TxOut era, Coin))
  | -- | TxIns that appear in both inputs and reference inputs
    BabbageNonDisjointRefInputs (NonEmpty TxIn)
  | PtrPresentInCollateralReturn (TxOut era)
  | -- | Legacy-mode top-level transaction does not self-balance
    ValueNotConservedInLegacyMode
      (Mismatch RelEQ (Value era))
  | -- | A SubTx declares a net UTxO capacity deposit change but TopTx does not.
    MissingTopTxUTxODepositDeclaration
  | -- | This body creates or spends a store-backed output without its own UTxO deposit declaration.
    MissingUTxODepositDeclaration
  | DepositStoreFailure !DepositStore.DepositStoreAccountingFailure
  deriving (Generic)

type instance EraRuleFailure "UTXO" DijkstraEra = DijkstraUtxoPredFailure DijkstraEra

type instance EraRuleEvent "UTXO" DijkstraEra = Alonzo.AlonzoUtxoEvent DijkstraEra

instance InjectRuleFailure "UTXO" DijkstraUtxoPredFailure DijkstraEra

instance InjectRuleFailure "UTXO" Conway.ConwayUtxoPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraUtxoPredFailure

instance InjectRuleFailure "UTXO" Babbage.BabbageUtxoPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraUtxoPredFailure . Conway.babbageToConwayUtxoPredFailure

instance InjectRuleFailure "UTXO" Alonzo.AlonzoUtxoPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraUtxoPredFailure . Conway.alonzoToConwayUtxoPredFailure

instance InjectRuleFailure "UTXO" Shelley.ShelleyUtxoPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraUtxoPredFailure
      . Conway.allegraToConwayUtxoPredFailure
      . Allegra.shelleyToAllegraUtxoPredFailure

instance InjectRuleFailure "UTXO" Allegra.AllegraUtxoPredFailure DijkstraEra where
  injectFailure = conwayToDijkstraUtxoPredFailure . Conway.allegraToConwayUtxoPredFailure

instance InjectRuleFailure "UTXO" Conway.ConwayUtxosPredFailure DijkstraEra where
  injectFailure = UtxosFailure

instance InjectRuleFailure "UTXO" Alonzo.AlonzoUtxosPredFailure DijkstraEra where
  injectFailure =
    conwayToDijkstraUtxoPredFailure
      . Conway.alonzoToConwayUtxoPredFailure
      . Alonzo.UtxosFailure
      . injectFailure

deriving instance
  ( Era era
  , Show (Value era)
  , Show (PredicateFailure (EraRule "UTXOS" era))
  , Show (TxOut era)
  , Show (Script era)
  , Show TxIn
  ) =>
  Show (DijkstraUtxoPredFailure era)

deriving instance
  ( Era era
  , Eq (Value era)
  , Eq (PredicateFailure (EraRule "UTXOS" era))
  , Eq (TxOut era)
  , Eq (Script era)
  , Eq TxIn
  ) =>
  Eq (DijkstraUtxoPredFailure era)

deriving instance
  ( Era era
  , Ord (Value era)
  , Ord (PredicateFailure (EraRule "UTXOS" era))
  , Ord (TxOut era)
  , Ord (Script era)
  , Ord TxIn
  ) =>
  Ord (DijkstraUtxoPredFailure era)

instance
  ( Era era
  , NFData (Value era)
  , NFData (TxOut era)
  , NFData (PredicateFailure (EraRule "UTXOS" era))
  ) =>
  NFData (DijkstraUtxoPredFailure era)

depositStoreDeclarationToUtxoPredFailure ::
  DepositStoreDeclarationFailure -> DijkstraUtxoPredFailure era
depositStoreDeclarationToUtxoPredFailure = \case
  MissingTopTxDeclaration -> MissingTopTxUTxODepositDeclaration

depositStoreOutputDeclarationToUtxoPredFailure ::
  DepositStoreOutputDeclarationFailure -> DijkstraUtxoPredFailure era
depositStoreOutputDeclarationToUtxoPredFailure MissingBodyUTxODepositDeclaration =
  MissingUTxODepositDeclaration

validateNoPtrInCollateralReturn ::
  ( BabbageEraTxBody era
  , InjectRuleFailure rule DijkstraUtxoPredFailure era
  ) =>
  TxBody TopTx era ->
  Rule (EraRule rule era) ctx ()
validateNoPtrInCollateralReturn txBody = do
  let hasCollateralTxOut = do
        SJust collateralReturn <- pure $ txBody ^. collateralReturnTxBodyL
        Addr _ _ (StakeRefPtr {}) <- pure $ collateralReturn ^. addrTxOutL
        Just collateralReturn
  failOnJustStatic hasCollateralTxOut (injectFailure . PtrPresentInCollateralReturn)

-- | Validate collateral if any transaction in the batch has redeemers.
validateBatchCollateral ::
  forall era rule.
  ( AlonzoEraTx era
  , DijkstraEraTxBody era
  , InjectRuleFailure rule Alonzo.AlonzoUtxoPredFailure era
  , InjectRuleFailure rule Babbage.BabbageUtxoPredFailure era
  ) =>
  PParams era ->
  Tx TopTx era ->
  UTxOStore era ->
  Test (EraRuleFailure rule era)
validateBatchCollateral pp tx store
  | hasBatchRedeemers tx = validateCollateralFunding pp (tx ^. bodyTxL) store
  | otherwise = pure ()

-- | A SubTx's redeemers trigger collateral validation for the complete batch.
hasBatchRedeemers :: (AlonzoEraTx era, DijkstraEraTxBody era) => Tx TopTx era -> Bool
hasBatchRedeemers tx =
  hasRedeemers tx || any hasRedeemers (tx ^. bodyTxL . subTransactionsTxBodyL)

hasRedeemers :: AlonzoEraTx era => Tx l era -> Bool
hasRedeemers = not . null . (^. witsTxL . rdmrsTxWitsL . unRedeemersL)

-- | Ensure that value consumed and produced matches up exactly,  aggregated across the entire batch
-- (top-level transaction and all its sub-transactions).
--
-- > consumed pp utxo txb = produced pp poolParams txb
validateValueNotConservedUTxO ::
  EraUTxO era =>
  PParams era ->
  UTxO era ->
  PState era ->
  TxBody TopTx era ->
  Test (Mismatch RelEQ (Value era))
validateValueNotConservedUTxO pp utxo pState txBody =
  failureUnless (consumedValue == producedValue) $
    Mismatch
      { mismatchSupplied = consumedValue
      , mismatchExpected = producedValue
      }
  where
    consumedValue = dijkstraConsumed pp utxo txBody
    producedValue = produced pp pState txBody

-- | Legacy self-balance uses TopTx's attributed share, excluding locally
-- accounted SubTx contributions while retaining explicitly delegated amounts.
validateLegacyValueNotConservedUTxO ::
  (EraUTxO era, DijkstraEraTxBody era) =>
  PParams era ->
  UTxO era ->
  PState era ->
  TxBody TopTx era ->
  Validation (NonEmpty (Mismatch RelEQ (Value era))) ()
validateLegacyValueNotConservedUTxO pp utxo pState body =
  let Coin topTxNetDeposit = DepositStore.attributedTopTxNetUTxODeposit body
      ordinaryBody =
        body
          & subTransactionsTxBodyL .~ mempty
          & netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
      consumedValue = dijkstraConsumed pp utxo ordinaryBody <> inject (Coin $ max 0 $ negate topTxNetDeposit)
      producedValue = produced pp pState ordinaryBody <> inject (Coin $ max 0 topTxNetDeposit)
   in failureUnless (consumedValue == producedValue) $ Mismatch consumedValue producedValue

dijkstraUtxoTransition ::
  forall era.
  ( DijkstraEraUTxO era
  , EraCertState era
  , DijkstraEraTxBody era
  , AlonzoEraTx era
  , EraStake era
  , InjectRuleFailure "UTXO" Shelley.ShelleyUtxoPredFailure era
  , InjectRuleFailure "UTXO" Allegra.AllegraUtxoPredFailure era
  , InjectRuleFailure "UTXO" Alonzo.AlonzoUtxoPredFailure era
  , InjectRuleFailure "UTXO" Babbage.BabbageUtxoPredFailure era
  , InjectRuleFailure "UTXO" DijkstraUtxoPredFailure era
  , Environment (EraRule "UTXO" era) ~ UtxoEnv era
  , State (EraRule "UTXO" era) ~ UTxOState era
  , Signal (EraRule "UTXO" era) ~ StAnnTx TopTx era
  , BaseM (EraRule "UTXO" era) ~ ShelleyBase
  , STS (EraRule "UTXO" era)
  , Event (EraRule "UTXO" era) ~ Alonzo.AlonzoUtxoEvent era
  , -- In this function we call the UTXOS rule, so we need some assumptions
    Environment (EraRule "UTXOS" era) ~ ()
  , State (EraRule "UTXOS" era) ~ ()
  , Signal (EraRule "UTXOS" era) ~ StAnnTx TopTx era
  , Embed (EraRule "UTXOS" era) (EraRule "UTXO" era)
  ) =>
  TransitionRule (EraRule "UTXO" era)
dijkstraUtxoTransition = do
  ctx@( TRC
          ( UtxoEnv slot pp postSubsPState originalCertState previousUTxOStore
            , utxos
            , stAnnTx
            )
        ) <-
    judgmentContext
  let invariantFailure :: String -> a
      invariantFailure message =
        throw $
          AssertionException $
            AssertionViolation
              { avSTS = "Dijkstra UTXO"
              , avMsg = message
              , avCtx = ctx
              , avState = Nothing
              }
      utxoStore = case utxosUTxOs utxos of
        UTxOs store -> store
        LegacyUTxOMap _ -> invariantFailure "Dijkstra state must contain UTxOStore"
  -- Accounting reads the original historical allocations even after children
  -- have updated the live store. Checked state construction excludes invalid metadata.
  let originalUtxo = toUTxO previousUTxOStore
  let tx = stAnnTx ^. txStAnnTxG
  let originalPState = originalCertState ^. certPStateL

  let txBody = tx ^. bodyTxL

  runTestOnSignal $
    first (fmap depositStoreOutputDeclarationToUtxoPredFailure) $
      validateTopTxAllocationDeclarationPresence txBody

  runTestOnSignal $
    first (fmap depositStoreDeclarationToUtxoPredFailure) $
      validateTopTxNetUTxODepositDeclaration txBody

  {- inInterval (SlotOf Γ) (ValidIntervalOf txTop) -}
  runTest $ Allegra.validateOutsideValidityIntervalUTxO slot txBody

  sysSt <- liftSTS $ asks systemStart
  ei <- liftSTS $ asks epochInfo

  runTest $ Alonzo.validateOutsideForecast ei slot sysSt tx

  {- SpendInputs ≠ ∅ -}
  runTestOnSignal $ Shelley.validateInputSetEmptyUTxO txBody

  let
    -- allInputs finds all inputs in a transaction, including sub-transactions
    allInputs = txBody ^. allInputsTxBodyF
    inputs = txBody ^. inputsTxBodyL

  {- SpendInputsOf txTop ∪ RefInputsOf txTop ∪ CollInputsOf txTop ⊆ dom(utxo₀) -}
  runTest $ Shelley.validateBadInputsUTxO originalUtxo allInputs

  {- SpendInputsOf txTop ⊆ dom(utxo_s) — prevents double-spend with subtxs -}
  runTest $ Shelley.validateBadInputsUTxO (utxosUtxo utxos) inputs

  -- Release declaration presence uses the original allocations on both phase-2 paths.
  runTest $
    first (fmap depositStoreOutputDeclarationToUtxoPredFailure) $
      validateTopTxReleaseDeclarationPresence (allocations previousUTxOStore) txBody

  -- Whole-batch exactness uses the original store on both phase-2 paths.
  -- SubTx changes have already been applied only to the live store.
  runTest $
    first (fmap DepositStoreFailure) $
      DepositStore.validateOrdinaryDepositStore pp previousUTxOStore txBody

  {- minfee pp txTop utxo₀ ≤ txfee txb -}
  runTest $ Shelley.validateFeeTooSmallUTxO pp tx originalUtxo

  {- (RedeemersOf txTop ≠ ∅ ⊎ Any (λ txSub → RedeemersOf txSub ≠ ∅) subtxs) → collateralCheck -}
  validate $ validateBatchCollateral pp tx previousUTxOStore

  -- If the transaction is phase2-invalid, the `produced` value in legacy mode will
  -- wrongly include a deposit for a pool that a sub-transaction already registered,
  -- because the Phase2Invalid flag prevents `postSubsPState` from being updated.
  -- It is safe to skip the value conservation check here, because we know
  -- that none of the modifications to the ledger state will happen
  -- that affect conservation of value when a transaction is phase-2 invalid.
  -- For consistency, we're skipping the check in both normal and legacy mode.
  when (tx ^. isPhase2ValidTxL == Phase2Valid) $ do
    {- consumed pp utxo₀ txb = produced pp certState txb -}
    runTest $
      first (fmap Shelley.ValueNotConservedUTxO) $
        validateValueNotConservedUTxO
          pp
          originalUtxo
          originalPState
          txBody

    {- legacyMode ≡ true → consumedLegacy ≡ producedLegacy -}
    when (stAnnTx ^. plutusLegacyModeStAnnTxG) $
      runTest $
        first (fmap ValueNotConservedInLegacyMode) $
          validateLegacyValueNotConservedUTxO
            pp
            originalUtxo
            postSubsPState
            txBody

  -- Apply the byte-based minimum only to implicit-deposit outputs, preserving their cached size.
  let allSizedOutputs = txBody ^. allSizedOutputsTxBodyF
  runTest $
    Babbage.validateImplicitDeposits
      pp
      [Sized output size | Sized (LegacyTxOut output) size <- toList allSizedOutputs]

  let allOutputs = fmap sizedValue allSizedOutputs
  {- ∀ txout ∈ allOuts txb, serSize (getValue txout) ≤ maxValSize pp -}
  runTest $ Alonzo.validateOutputTooBigUTxO pp allOutputs

  {- ∀ ( _ ↦ (a,_)) ∈ allOuts txb, a ∈ Addrbootstrap → bootstrapAttrsSize a ≤ 64 -}
  runTestOnSignal $ Shelley.validateOutputBootAddrAttrsTooBig allOutputs

  netId <- liftSTS $ asks networkId

  {- ∀(_ → (a, _)) ∈ allOuts txb, netId a = NetworkId -}
  runTestOnSignal $ Shelley.validateWrongNetwork netId allOutputs

  {- (txnetworkid txb = NetworkId) ∨ (txnetworkid txb = ◇) -}
  runTestOnSignal $ Alonzo.validateWrongNetworkInTxBody netId txBody

  {- no Ptr in collateral return -}
  validateNoPtrInCollateralReturn txBody

  {- txsize tx ≤ maxTxSize pp -}
  runTest $ Shelley.validateMaxTxSizeUTxO pp tx

  {- totExunits tx ≤ maxTxExUnits pp -}
  runTest $ Alonzo.validateExUnitsTooBigUTxO pp tx

  {- ‖collateral tx‖ ≤ maxCollInputs pp -}
  runTest $ Alonzo.validateTooManyCollateralInputs pp txBody

  () <- trans @(EraRule "UTXOS" era) $ TRC ((), (), stAnnTx)
  case tx ^. isPhase2ValidTxL of
    Phase2Valid ->
      case DepositStore.applyBodyAllocations pp txBody utxoStore of
        Left err ->
          invariantFailure $ "Ordinary allocation invariant violated: " <> show err
        Right store -> do
          withDeposits <-
            Shelley.updateUTxOStateDeposits
              pp
              originalCertState
              txBody
              (tellEvent . Alonzo.TotalDeposits (hashAnnotated txBody))
              (Conway.updateTreasuryDonation tx utxos)
          withOutputs <-
            Shelley.updateUTxOAndInstantStakeWithStorage
              (UTxOs store)
              txBody
              (\removed created -> tellEvent $ Alonzo.TxUTxODiff removed created)
              withDeposits
          pure $ withOutputs & utxosFeesL <>~ txBody ^. feeTxBodyL
    Phase2Invalid ->
      case DepositStore.applyCollateralAllocations pp txBody utxoStore of
        Left err ->
          invariantFailure $ "Collateral allocation invariant violated: " <> show err
        Right store ->
          let settlement =
                DepositStore.collateralDepositSettlement pp previousUTxOStore txBody
              removed = txInsFilter (utxosUtxo utxos) (txBody ^. collateralInputsTxBodyL)
              created = collOuts txBody
           in pure $
                utxos
                  { utxosUTxOs = UTxOs store
                  , utxosFees = utxosFees utxos <> DepositStore.collateralFee settlement
                  , utxosInstantStake =
                      deleteInstantStake removed $ addInstantStake created (utxosInstantStake utxos)
                  }

--------------------------------------------------------------------------------
-- UTXO STS
--------------------------------------------------------------------------------

instance
  forall era.
  ( EraTx era
  , DijkstraEraUTxO era
  , EraStake era
  , DijkstraEraTxBody era
  , AlonzoEraTx era
  , EraRule "UTXO" era ~ UTXO era
  , InjectRuleFailure "UTXO" Shelley.ShelleyUtxoPredFailure era
  , InjectRuleFailure "UTXO" Allegra.AllegraUtxoPredFailure era
  , InjectRuleFailure "UTXO" Alonzo.AlonzoUtxoPredFailure era
  , InjectRuleFailure "UTXO" Babbage.BabbageUtxoPredFailure era
  , InjectRuleFailure "UTXO" Conway.ConwayUtxoPredFailure era
  , InjectRuleFailure "UTXO" DijkstraUtxoPredFailure era
  , Environment (EraRule "UTXO" era) ~ UtxoEnv era
  , State (EraRule "UTXO" era) ~ UTxOState era
  , Signal (EraRule "UTXO" era) ~ StAnnTx TopTx era
  , BaseM (EraRule "UTXO" era) ~ ShelleyBase
  , STS (EraRule "UTXO" era)
  , -- In this function we we call the UTXOS rule, so we need some assumptions
    Embed (EraRule "UTXOS" era) (UTXO era)
  , Environment (EraRule "UTXOS" era) ~ ()
  , State (EraRule "UTXOS" era) ~ ()
  , Signal (EraRule "UTXOS" era) ~ StAnnTx TopTx era
  , EraCertState era
  , EraRule "UTXO" era ~ UTXO era
  , SafeToHash (TxWits era)
  ) =>
  STS (UTXO era)
  where
  type State (UTXO era) = UTxOState era
  type Signal (UTXO era) = StAnnTx TopTx era
  type Environment (UTXO era) = UtxoEnv era
  type BaseM (UTXO era) = ShelleyBase
  type PredicateFailure (UTXO era) = DijkstraUtxoPredFailure era
  type Event (UTXO era) = Alonzo.AlonzoUtxoEvent era

  initialRules = []

  transitionRules = [dijkstraUtxoTransition @era]

  assertions = [Shelley.validSizeComputationCheck]

instance
  ( STS (Conway.UTXOS era)
  , PredicateFailure (EraRule "UTXOS" era) ~ Conway.ConwayUtxosPredFailure era
  , Event (EraRule "UTXOS" era) ~ Event (Conway.UTXOS era)
  ) =>
  Embed (Conway.UTXOS era) (UTXO era)
  where
  wrapFailed = UtxosFailure
  wrapEvent = Alonzo.UtxosEvent

--------------------------------------------------------------------------------
-- Serialisation
--------------------------------------------------------------------------------

instance
  ( Era era
  , EncCBOR (TxOut era)
  , EncCBOR (Value era)
  , EncCBOR (PredicateFailure (EraRule "UTXOS" era))
  ) =>
  EncCBOR (DijkstraUtxoPredFailure era)
  where
  encCBOR =
    encode . \case
      UtxosFailure a -> Sum (UtxosFailure @era) 0 !> To a
      BadInputsUTxO ins -> Sum (BadInputsUTxO @era) 1 !> To ins
      OutsideValidityIntervalUTxO a b -> Sum OutsideValidityIntervalUTxO 2 !> To a !> To b
      MaxTxSizeUTxO mm -> Sum MaxTxSizeUTxO 3 !> To mm
      InputSetEmptyUTxO -> Sum InputSetEmptyUTxO 4
      FeeTooSmallUTxO mm -> Sum FeeTooSmallUTxO 5 !> To mm
      ValueNotConservedUTxO mm -> Sum (ValueNotConservedUTxO @era) 6 !> To mm
      WrongNetwork right wrongs -> Sum (WrongNetwork @era) 7 !> To right !> To wrongs
      OutputBootAddrAttrsTooBig outs -> Sum (OutputBootAddrAttrsTooBig @era) 9 !> To outs
      OutputTooBigUTxO outs -> Sum (OutputTooBigUTxO @era) 10 !> To outs
      InsufficientCollateral a b -> Sum InsufficientCollateral 11 !> To a !> To b
      ScriptsNotPaidUTxO a -> Sum ScriptsNotPaidUTxO 12 !> To a
      ExUnitsTooBigUTxO mm -> Sum ExUnitsTooBigUTxO 13 !> To mm
      CollateralContainsNonADA a -> Sum CollateralContainsNonADA 14 !> To a
      WrongNetworkInTxBody mm -> Sum WrongNetworkInTxBody 15 !> To mm
      OutsideForecast a -> Sum OutsideForecast 16 !> To a
      TooManyCollateralInputs mm -> Sum TooManyCollateralInputs 17 !> To mm
      NoCollateralInputs -> Sum NoCollateralInputs 18
      IncorrectTotalCollateralField c1 c2 -> Sum IncorrectTotalCollateralField 19 !> To c1 !> To c2
      BabbageOutputTooSmallUTxO x -> Sum BabbageOutputTooSmallUTxO 20 !> To x
      BabbageNonDisjointRefInputs x -> Sum BabbageNonDisjointRefInputs 21 !> To x
      PtrPresentInCollateralReturn x -> Sum PtrPresentInCollateralReturn 22 !> To x
      ValueNotConservedInLegacyMode mm -> Sum ValueNotConservedInLegacyMode 23 !> To mm
      MissingTopTxUTxODepositDeclaration -> Sum MissingTopTxUTxODepositDeclaration 24
      MissingUTxODepositDeclaration -> Sum MissingUTxODepositDeclaration 25
      DepositStoreFailure failure -> Sum DepositStoreFailure 26 !> To failure

instance
  ( Era era
  , DecCBOR (TxOut era)
  , EncCBOR (Value era)
  , DecCBOR (Value era)
  , DecCBOR (PredicateFailure (EraRule "UTXOS" era))
  ) =>
  DecCBOR (DijkstraUtxoPredFailure era)
  where
  decCBOR = decode . Summands "DijkstraUtxoPredFailure" $ \case
    0 -> SumD UtxosFailure <! From
    1 -> SumD BadInputsUTxO <! From
    2 -> SumD OutsideValidityIntervalUTxO <! From <! From
    3 -> SumD MaxTxSizeUTxO <! From
    4 -> SumD InputSetEmptyUTxO
    5 -> SumD FeeTooSmallUTxO <! From
    6 -> SumD ValueNotConservedUTxO <! From
    7 -> SumD WrongNetwork <! From <! From
    9 -> SumD OutputBootAddrAttrsTooBig <! From
    10 -> SumD OutputTooBigUTxO <! From
    11 -> SumD InsufficientCollateral <! From <! From
    12 -> SumD ScriptsNotPaidUTxO <! From
    13 -> SumD ExUnitsTooBigUTxO <! From
    14 -> SumD CollateralContainsNonADA <! From
    15 -> SumD WrongNetworkInTxBody <! From
    16 -> SumD OutsideForecast <! From
    17 -> SumD TooManyCollateralInputs <! From
    18 -> SumD NoCollateralInputs
    19 -> SumD IncorrectTotalCollateralField <! From <! From
    20 -> SumD BabbageOutputTooSmallUTxO <! From
    21 -> SumD BabbageNonDisjointRefInputs <! From
    22 -> SumD PtrPresentInCollateralReturn <! From
    23 -> SumD ValueNotConservedInLegacyMode <! From
    24 -> SumD MissingTopTxUTxODepositDeclaration
    25 -> SumD MissingUTxODepositDeclaration
    26 -> SumD DepositStoreFailure <! From
    n -> Invalid n

-- =====================================================
-- Injecting from one PredicateFailure to another

conwayToDijkstraUtxoPredFailure ::
  forall era.
  Conway.ConwayUtxoPredFailure era ->
  DijkstraUtxoPredFailure era
conwayToDijkstraUtxoPredFailure = \case
  Conway.BadInputsUTxO x -> BadInputsUTxO x
  Conway.OutsideValidityIntervalUTxO vi slotNo -> OutsideValidityIntervalUTxO vi slotNo
  Conway.MaxTxSizeUTxO m -> MaxTxSizeUTxO m
  Conway.InputSetEmptyUTxO -> InputSetEmptyUTxO
  Conway.FeeTooSmallUTxO m -> FeeTooSmallUTxO m
  Conway.ValueNotConservedUTxO m -> ValueNotConservedUTxO m
  Conway.WrongNetwork x y -> WrongNetwork x y
  Conway.WrongNetworkWithdrawal _ _ -> error "Impossible: `WrongNetworkWithdrawal` for UTXO"
  Conway.OutputTooSmallUTxO _ -> error "Impossible: `OutputTooSmallUTxO` for UTXO"
  Conway.UtxosFailure x -> UtxosFailure x
  Conway.OutputBootAddrAttrsTooBig xs -> OutputBootAddrAttrsTooBig xs
  Conway.OutputTooBigUTxO xs -> OutputTooBigUTxO xs
  Conway.InsufficientCollateral c1 c2 -> InsufficientCollateral c1 c2
  Conway.ScriptsNotPaidUTxO u -> ScriptsNotPaidUTxO u
  Conway.ExUnitsTooBigUTxO m -> ExUnitsTooBigUTxO m
  Conway.CollateralContainsNonADA v -> CollateralContainsNonADA v
  Conway.WrongNetworkInTxBody m -> WrongNetworkInTxBody m
  Conway.OutsideForecast sno -> OutsideForecast sno
  Conway.TooManyCollateralInputs m -> TooManyCollateralInputs m
  Conway.NoCollateralInputs -> NoCollateralInputs
  Conway.IncorrectTotalCollateralField dc c -> IncorrectTotalCollateralField dc c
  Conway.BabbageOutputTooSmallUTxO x -> BabbageOutputTooSmallUTxO x
  Conway.BabbageNonDisjointRefInputs txin -> BabbageNonDisjointRefInputs txin
