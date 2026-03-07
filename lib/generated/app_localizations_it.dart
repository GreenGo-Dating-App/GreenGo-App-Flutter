// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get abandonGame => 'Abbandona Partita';

  @override
  String get about => 'Info';

  @override
  String get aboutMe => 'Su di Me';

  @override
  String get aboutMeTitle => 'Su di me';

  @override
  String get academicCategory => 'Accademico';

  @override
  String get acceptPrivacyPolicy =>
      'Ho letto e accetto l\'Informativa sulla Privacy';

  @override
  String get acceptProfiling =>
      'Acconsento alla profilazione per raccomandazioni personalizzate';

  @override
  String get acceptTermsAndConditions =>
      'Ho letto e accetto i Termini e Condizioni';

  @override
  String get acceptThirdPartyData =>
      'Acconsento alla condivisione dei miei dati con terze parti';

  @override
  String get accessGranted => 'Accesso concesso!';

  @override
  String accessGrantedBody(Object tierName) {
    return 'GreenGo è ora attivo! Come $tierName, hai ora accesso completo a tutte le funzionalità.';
  }

  @override
  String get accountApproved => 'Account Approvato';

  @override
  String get accountApprovedBody =>
      'Il tuo account GreenGo è stato approvato. Benvenuto nella community!';

  @override
  String get accountCreatedSuccess =>
      'Account creato! Controlla la tua email per verificare il tuo account.';

  @override
  String get accountPendingApproval => 'Account in Attesa di Approvazione';

  @override
  String get accountRejected => 'Account Rifiutato';

  @override
  String get accountSettings => 'Impostazioni Account';

  @override
  String get accountUnderReview => 'Account in Revisione';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Traguardi';

  @override
  String get achievementsTitle => 'Traguardi';

  @override
  String get addBio => 'Aggiungi una biografia';

  @override
  String get addDealBreakerTitle => 'Aggiungi Criterio Eliminatorio';

  @override
  String get addPhoto => 'Aggiungi Foto';

  @override
  String get adjustPreferences => 'Modifica Preferenze';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Codice inviato a $email';
  }

  @override
  String get admin2faExpired => 'Codice scaduto. Richiedine uno nuovo.';

  @override
  String get admin2faInvalidCode => 'Codice di verifica non valido';

  @override
  String get admin2faMaxAttempts =>
      'Troppi tentativi. Richiedi un nuovo codice.';

  @override
  String get admin2faResend => 'Reinvia Codice';

  @override
  String admin2faResendIn(String seconds) {
    return 'Reinvia tra ${seconds}s';
  }

  @override
  String get admin2faSending => 'Invio codice...';

  @override
  String get admin2faSignOut => 'Esci';

  @override
  String get admin2faSubtitle =>
      'Inserisci il codice a 6 cifre inviato alla tua email';

  @override
  String get admin2faTitle => 'Verifica Admin';

  @override
  String get admin2faVerify => 'Verifica';

  @override
  String get adminAccessDates => 'Date di accesso:';

  @override
  String get adminAccountLockedSuccessfully => 'Account bloccato con successo';

  @override
  String get adminAccountUnlockedSuccessfully =>
      'Account sbloccato con successo';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Gli account admin non possono essere eliminati';

  @override
  String adminAchievementCount(Object count) {
    return '$count traguardi';
  }

  @override
  String get adminAchievementUpdated => 'Traguardo aggiornato';

  @override
  String get adminAchievements => 'Traguardi';

  @override
  String get adminAchievementsSubtitle => 'Gestisci traguardi e badge';

  @override
  String get adminActive => 'ATTIVO';

  @override
  String adminActiveCount(Object count) {
    return 'Attivi ($count)';
  }

  @override
  String get adminActiveEvent => 'Evento attivo';

  @override
  String get adminActiveUsers => 'Utenti attivi';

  @override
  String get adminAdd => 'Aggiungi';

  @override
  String get adminAddCoins => 'Aggiungi monete';

  @override
  String get adminAddPackage => 'Aggiungi pacchetto';

  @override
  String get adminAddResolutionNote => 'Aggiungi una nota di risoluzione...';

  @override
  String get adminAddSingleEmail => 'Aggiungi singola e-mail';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return '$amount monete aggiunte all\'utente';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Aggiunto il $date';
  }

  @override
  String get adminAdvancedFilters => 'Filtri avanzati';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age anni - $gender';
  }

  @override
  String get adminAll => 'Tutti';

  @override
  String get adminAllReports => 'Tutte le segnalazioni';

  @override
  String get adminAmount => 'Importo';

  @override
  String get adminAnalyticsAndReports => 'Analisi e report';

  @override
  String get adminAppSettings => 'Impostazioni app';

  @override
  String get adminAppSettingsSubtitle =>
      'Impostazioni generali dell\'applicazione';

  @override
  String get adminApproveSelected => 'Approva selezionati';

  @override
  String get adminAssignToMe => 'Assegna a me';

  @override
  String get adminAssigned => 'Assegnato';

  @override
  String get adminAvailable => 'Disponibile';

  @override
  String get adminBadge => 'Badge';

  @override
  String get adminBaseCoins => 'Monete base';

  @override
  String get adminBaseXp => 'XP base';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount monete bonus';
  }

  @override
  String get adminBonusCoinsLabel => 'Monete bonus';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes bonus';
  }

  @override
  String get adminBrowseProfilesAnonymously =>
      'Sfoglia i profili in modo anonimo';

  @override
  String get adminCanSendMedia => 'Può inviare media';

  @override
  String adminChallengeCount(Object count) {
    return '$count sfide';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'Interfaccia di creazione sfide in arrivo.';

  @override
  String get adminChallenges => 'Sfide';

  @override
  String get adminChangesSaved => 'Modifiche salvate';

  @override
  String get adminChatWithReporter => 'Chatta con il segnalatore';

  @override
  String get adminClear => 'Cancella';

  @override
  String get adminClosed => 'Chiuso';

  @override
  String get adminCoinAmount => 'Importo monete';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount monete';
  }

  @override
  String get adminCoinCost => 'Costo in monete';

  @override
  String get adminCoinManagement => 'Gestione monete';

  @override
  String get adminCoinManagementSubtitle =>
      'Gestisci pacchetti monete e saldi utenti';

  @override
  String get adminCoinPackages => 'Pacchetti monete';

  @override
  String get adminCoinReward => 'Ricompensa in monete';

  @override
  String adminComingSoon(Object route) {
    return '$route in arrivo';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Configurazioni ripristinate ai valori predefiniti. Salva per applicare.';

  @override
  String get adminConfigureLimitsAndFeatures =>
      'Configura limiti e funzionalità';

  @override
  String get adminConfigureMilestoneRewards =>
      'Configura le ricompense per i traguardi di accessi consecutivi';

  @override
  String get adminCreateChallenge => 'Crea sfida';

  @override
  String get adminCreateEvent => 'Crea evento';

  @override
  String get adminCreateNewChallenge => 'Crea nuova sfida';

  @override
  String get adminCreateSeasonalEvent => 'Crea evento stagionale';

  @override
  String get adminCsvFormat => 'Formato CSV:';

  @override
  String get adminCsvFormatDescription =>
      'Un\'e-mail per riga, o valori separati da virgole. Le virgolette vengono rimosse automaticamente. Le e-mail non valide vengono ignorate.';

  @override
  String get adminCurrentBalance => 'Saldo attuale';

  @override
  String get adminDailyChallenges => 'Sfide giornaliere';

  @override
  String get adminDailyChallengesSubtitle =>
      'Configura sfide giornaliere e ricompense';

  @override
  String get adminDailyLimits => 'Limiti giornalieri';

  @override
  String get adminDailyLoginRewards => 'Ricompense accesso giornaliero';

  @override
  String get adminDailyMessages => 'Messaggi giornalieri';

  @override
  String get adminDailySuperLikes => 'Super Like giornalieri';

  @override
  String get adminDailySwipes => 'Swipe giornalieri';

  @override
  String get adminDashboard => 'Pannello di amministrazione';

  @override
  String get adminDate => 'Data';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return 'Sei sicuro di voler eliminare il pacchetto \"$amount monete\"?';
  }

  @override
  String get adminDeletePackageTitle => 'Eliminare il pacchetto?';

  @override
  String get adminDescription => 'Descrizione';

  @override
  String get adminDeselectAll => 'Deseleziona tutto';

  @override
  String get adminDisabled => 'Disabilitato';

  @override
  String get adminDismiss => 'Archivia';

  @override
  String get adminDismissReport => 'Archivia segnalazione';

  @override
  String get adminDismissReportConfirm =>
      'Sei sicuro di voler archiviare questa segnalazione?';

  @override
  String get adminEarlyAccessDate => '14 marzo 2026';

  @override
  String get adminEarlyAccessDates =>
      'Gli utenti in questa lista ottengono l\'accesso il 14 marzo 2026.\nTutti gli altri utenti ottengono l\'accesso il 14 aprile 2026.';

  @override
  String get adminEarlyAccessInList => 'Accesso anticipato (nella lista)';

  @override
  String get adminEarlyAccessInfo => 'Informazioni accesso anticipato';

  @override
  String get adminEarlyAccessList => 'Lista accesso anticipato';

  @override
  String get adminEarlyAccessProgram => 'Programma accesso anticipato';

  @override
  String get adminEditAchievement => 'Modifica traguardo';

  @override
  String adminEditItem(Object name) {
    return 'Modifica $name';
  }

  @override
  String adminEditMilestone(Object name) {
    return 'Modifica $name';
  }

  @override
  String get adminEditPackage => 'Modifica pacchetto';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email aggiunto alla lista di accesso anticipato';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count e-mail';
  }

  @override
  String get adminEmailList => 'Lista e-mail';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email rimosso dalla lista di accesso anticipato';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Abilita opzioni di filtro avanzate';

  @override
  String get adminEngagementReports => 'Report di engagement';

  @override
  String get adminEngagementReportsSubtitle =>
      'Visualizza statistiche di matching e messaggistica';

  @override
  String get adminEnterEmailAddress => 'Inserisci indirizzo e-mail';

  @override
  String get adminEnterValidAmount => 'Inserisci un importo valido';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Inserisci un importo di monete e un prezzo validi';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Errore durante l\'aggiunta dell\'e-mail: $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Errore durante il caricamento del contesto: $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Errore durante il caricamento dei dati: $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Errore durante l\'apertura della chat: $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Errore durante la rimozione dell\'e-mail: $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Errore: $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Errore durante il caricamento del file: $error';
  }

  @override
  String get adminErrors => 'Errori:';

  @override
  String get adminEventCreationComingSoon =>
      'Interfaccia di creazione eventi in arrivo.';

  @override
  String get adminEvents => 'Eventi';

  @override
  String adminFailedToSave(Object error) {
    return 'Salvataggio fallito: $error';
  }

  @override
  String get adminFeatures => 'Funzionalità';

  @override
  String get adminFilterByInterests => 'Filtra per interessi';

  @override
  String get adminFilterBySpecificLocation => 'Filtra per posizione specifica';

  @override
  String get adminFilterBySpokenLanguages => 'Filtra per lingue parlate';

  @override
  String get adminFilterByVerificationStatus => 'Filtra per stato di verifica';

  @override
  String get adminFilterOptions => 'Opzioni filtro';

  @override
  String get adminGamification => 'Gamification';

  @override
  String get adminGamificationAndRewards => 'Gamification e ricompense';

  @override
  String get adminGeneralAccess => 'Accesso generale';

  @override
  String get adminGeneralAccessDate => '14 aprile 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Priorità più alta = mostrato per primo nella scoperta';

  @override
  String get adminImportResult => 'Risultato importazione';

  @override
  String get adminInProgress => 'In corso';

  @override
  String get adminIncognitoMode => 'Modalità incognito';

  @override
  String get adminInterestFilter => 'Filtro interessi';

  @override
  String get adminInvoices => 'Fatture';

  @override
  String get adminLanguageFilter => 'Filtro lingua';

  @override
  String get adminLoading => 'Caricamento...';

  @override
  String get adminLocationFilter => 'Filtro posizione';

  @override
  String get adminLockAccount => 'Blocca account';

  @override
  String adminLockAccountConfirm(Object userId) {
    return 'Bloccare l\'account dell\'utente $userId...?';
  }

  @override
  String get adminLockDuration => 'Durata del blocco';

  @override
  String adminLockReasonLabel(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String adminLockedCount(Object count) {
    return 'Bloccati ($count)';
  }

  @override
  String adminLockedDate(Object date) {
    return 'Bloccato il: $date';
  }

  @override
  String get adminLoginStreakSystem => 'Sistema di serie di accessi';

  @override
  String get adminLoginStreaks => 'Serie di accessi';

  @override
  String get adminLoginStreaksSubtitle =>
      'Configura traguardi e ricompense delle serie';

  @override
  String get adminManageAppSettings =>
      'Gestisci le impostazioni dell\'applicazione GreenGo';

  @override
  String get adminMatchPriority => 'Priorità matching';

  @override
  String get adminMatchingAndVisibility => 'Matching e visibilità';

  @override
  String get adminMessageContext => 'Contesto del messaggio (50 prima/dopo)';

  @override
  String get adminMilestoneUpdated => 'Traguardo aggiornato';

  @override
  String adminMoreErrors(Object count) {
    return '... e altri $count errori';
  }

  @override
  String get adminName => 'Nome';

  @override
  String get adminNinetyDays => '90 giorni';

  @override
  String get adminNoEmailsInEarlyAccessList =>
      'Nessuna e-mail nella lista di accesso anticipato';

  @override
  String get adminNoInvoicesFound => 'Nessuna fattura trovata';

  @override
  String get adminNoLockedAccounts => 'Nessun account bloccato';

  @override
  String get adminNoMatchingEmailsFound =>
      'Nessuna e-mail corrispondente trovata';

  @override
  String get adminNoOrdersFound => 'Nessun ordine trovato';

  @override
  String get adminNoPendingReports => 'Nessuna segnalazione in sospeso';

  @override
  String get adminNoReportsYet => 'Nessuna segnalazione al momento';

  @override
  String adminNoTickets(Object status) {
    return 'Nessun ticket $status';
  }

  @override
  String get adminNoValidEmailsFound =>
      'Nessun indirizzo e-mail valido trovato nel file';

  @override
  String get adminNoVerificationHistory => 'Nessuno storico di verifica';

  @override
  String get adminOneDay => '1 giorno';

  @override
  String get adminOpen => 'Aperto';

  @override
  String adminOpenCount(Object count) {
    return 'Aperti ($count)';
  }

  @override
  String get adminOpenTickets => 'Ticket aperti';

  @override
  String get adminOrderDetails => 'Dettagli ordine';

  @override
  String get adminOrderId => 'ID ordine';

  @override
  String get adminOrderRefunded => 'Ordine rimborsato';

  @override
  String get adminOrders => 'Ordini';

  @override
  String get adminPackages => 'Pacchetti';

  @override
  String get adminPanel => 'Pannello Admin';

  @override
  String get adminPayment => 'Pagamento';

  @override
  String get adminPending => 'In sospeso';

  @override
  String adminPendingCount(Object count) {
    return 'In sospeso ($count)';
  }

  @override
  String get adminPermanent => 'Permanente';

  @override
  String get adminPleaseEnterValidEmail =>
      'Inserisci un indirizzo e-mail valido';

  @override
  String get adminPriceUsd => 'Prezzo (USD)';

  @override
  String get adminProductIdIap => 'ID prodotto (per IAP)';

  @override
  String get adminProfileVisitors => 'Visitatori del profilo';

  @override
  String get adminPromotional => 'Promozionale';

  @override
  String get adminPromotionalPackage => 'Pacchetto promozionale';

  @override
  String get adminPromotions => 'Promozioni';

  @override
  String get adminPromotionsSubtitle =>
      'Gestisci offerte speciali e promozioni';

  @override
  String get adminProvideReason => 'Fornisci un motivo';

  @override
  String get adminReadReceipts => 'Conferme di lettura';

  @override
  String get adminReason => 'Motivo';

  @override
  String adminReasonLabel(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String get adminReasonRequired => 'Motivo (obbligatorio)';

  @override
  String get adminRefund => 'Rimborsa';

  @override
  String get adminRemove => 'Rimuovi';

  @override
  String get adminRemoveCoins => 'Rimuovi monete';

  @override
  String get adminRemoveEmail => 'Rimuovi e-mail';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return 'Sei sicuro di voler rimuovere \"$email\" dalla lista di accesso anticipato?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return '$amount monete rimosse dall\'utente';
  }

  @override
  String get adminReportDismissed => 'Segnalazione archiviata';

  @override
  String get adminReportFollowupStarted =>
      'Conversazione di follow-up della segnalazione avviata';

  @override
  String get adminReportedMessage => 'Messaggio segnalato:';

  @override
  String get adminReportedMessageMarker => '^ MESSAGGIO SEGNALATO';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'ID utente segnalato: $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'ID segnalatore: $reporterId...';
  }

  @override
  String get adminReports => 'Segnalazioni';

  @override
  String get adminReportsManagement => 'Gestione segnalazioni';

  @override
  String get adminRequestNewPhoto => 'Richiedi nuova foto';

  @override
  String get adminRequiredCount => 'Numero richiesto';

  @override
  String adminRequiresCount(Object count) {
    return 'Richiede: $count';
  }

  @override
  String get adminReset => 'Ripristina';

  @override
  String get adminResetToDefaults => 'Ripristina valori predefiniti';

  @override
  String get adminResetToDefaultsConfirm =>
      'Questo ripristinerà tutte le configurazioni dei livelli ai valori predefiniti. Questa azione non può essere annullata.';

  @override
  String get adminResetToDefaultsTitle => 'Ripristinare i valori predefiniti?';

  @override
  String get adminResolutionNote => 'Nota di risoluzione';

  @override
  String get adminResolve => 'Risolvi';

  @override
  String get adminResolved => 'Risolto';

  @override
  String adminResolvedCount(Object count) {
    return 'Risolti ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Analisi dei ricavi';

  @override
  String get adminRevenueAnalyticsSubtitle => 'Monitora acquisti e ricavi';

  @override
  String get adminReviewedBy => 'Esaminato da';

  @override
  String get adminRewardAmount => 'Importo ricompensa';

  @override
  String get adminSaving => 'Salvataggio...';

  @override
  String get adminScheduledEvents => 'Eventi programmati';

  @override
  String get adminSearchByUserIdOrEmail => 'Cerca per ID utente o e-mail';

  @override
  String get adminSearchEmails => 'Cerca e-mail...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Cerca un utente per gestire il suo saldo monete';

  @override
  String get adminSearchOrders => 'Cerca ordini...';

  @override
  String get adminSeeWhenMessagesAreRead =>
      'Vedi quando i messaggi vengono letti';

  @override
  String get adminSeeWhoVisitedProfile =>
      'Vedi chi ha visitato il loro profilo';

  @override
  String get adminSelectAll => 'Seleziona tutto';

  @override
  String get adminSelectCsvFile => 'Seleziona file CSV';

  @override
  String adminSelectedCount(Object count) {
    return '$count selezionati';
  }

  @override
  String get adminSendImagesAndVideosInChat => 'Invia immagini e video in chat';

  @override
  String get adminSevenDays => '7 giorni';

  @override
  String get adminSpendItems => 'Articoli da spendere';

  @override
  String get adminStatistics => 'Statistiche';

  @override
  String get adminStatus => 'Stato';

  @override
  String get adminStreakMilestones => 'Traguardi serie';

  @override
  String get adminStreakMultiplier => 'Moltiplicatore serie';

  @override
  String get adminStreakMultiplierValue => '1,5x al giorno';

  @override
  String get adminStreaks => 'Serie';

  @override
  String get adminSupport => 'Assistenza';

  @override
  String get adminSupportAgents => 'Agenti di assistenza';

  @override
  String get adminSupportAgentsSubtitle =>
      'Gestisci gli account degli agenti di assistenza';

  @override
  String get adminSupportManagement => 'Gestione assistenza';

  @override
  String get adminSupportRequest => 'Richiesta di assistenza';

  @override
  String get adminSupportTickets => 'Ticket di assistenza';

  @override
  String get adminSupportTicketsSubtitle =>
      'Visualizza e gestisci le conversazioni di assistenza degli utenti';

  @override
  String get adminSystemConfiguration => 'Configurazione di sistema';

  @override
  String get adminThirtyDays => '30 giorni';

  @override
  String get adminTicketAssignedToYou => 'Ticket assegnato a te';

  @override
  String get adminTicketAssignment => 'Assegnazione ticket';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Assegna ticket agli agenti di assistenza';

  @override
  String get adminTicketClosed => 'Ticket chiuso';

  @override
  String get adminTicketResolved => 'Ticket risolto';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Configurazioni dei livelli salvate con successo';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Gestione livelli';

  @override
  String get adminTierManagementSubtitle =>
      'Configura limiti e funzionalità dei livelli';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Oggi';

  @override
  String get adminTotalMinutes => 'Minuti totali';

  @override
  String get adminType => 'Tipo';

  @override
  String get adminUnassigned => 'Non assegnato';

  @override
  String get adminUnknown => 'Sconosciuto';

  @override
  String get adminUnlimited => 'Illimitato';

  @override
  String get adminUnlock => 'Sblocca';

  @override
  String get adminUnlockAccount => 'Sblocca account';

  @override
  String get adminUnlockAccountConfirm =>
      'Sei sicuro di voler sbloccare questo account?';

  @override
  String get adminUnresolved => 'Non risolto';

  @override
  String get adminUploadCsvDescription =>
      'Carica un file CSV contenente indirizzi e-mail (uno per riga o separati da virgole)';

  @override
  String get adminUploadCsvFile => 'Carica file CSV';

  @override
  String get adminUploading => 'Caricamento...';

  @override
  String get adminUseVideoCallingFeature =>
      'Utilizza la funzione di videochiamata';

  @override
  String get adminUsedMinutes => 'Minuti utilizzati';

  @override
  String get adminUser => 'Utente';

  @override
  String get adminUserAnalytics => 'Analisi utenti';

  @override
  String get adminUserAnalyticsSubtitle =>
      'Visualizza le metriche di engagement e crescita degli utenti';

  @override
  String get adminUserBalance => 'Saldo utente';

  @override
  String get adminUserId => 'ID utente';

  @override
  String adminUserIdLabel(Object userId) {
    return 'ID utente: $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'Utente: $userId...';
  }

  @override
  String get adminUserManagement => 'Gestione utenti';

  @override
  String get adminUserModeration => 'Moderazione utenti';

  @override
  String get adminUserModerationSubtitle =>
      'Gestisci ban e sospensioni degli utenti';

  @override
  String get adminUserReports => 'Segnalazioni utenti';

  @override
  String get adminUserReportsSubtitle =>
      'Esamina e gestisci le segnalazioni degli utenti';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'Utente: $senderId...';
  }

  @override
  String get adminUserVerifications => 'Verifiche utenti';

  @override
  String get adminUserVerificationsSubtitle =>
      'Approva o rifiuta le richieste di verifica degli utenti';

  @override
  String get adminVerificationFilter => 'Filtro verifica';

  @override
  String get adminVerifications => 'Verifiche';

  @override
  String get adminVideoChat => 'Video chat';

  @override
  String get adminVideoCoinPackages => 'Pacchetti monete video';

  @override
  String get adminVideoCoins => 'Monete video';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes minuti';
  }

  @override
  String get adminViewContext => 'Visualizza contesto';

  @override
  String get adminViewDocument => 'Visualizza documento';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Violazione delle linee guida della community';

  @override
  String get adminWaiting => 'In attesa';

  @override
  String adminWaitingCount(Object count) {
    return 'In attesa ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Sfide settimanali';

  @override
  String get adminWelcome => 'Benvenuto, Amministratore';

  @override
  String get adminXpReward => 'Ricompensa XP';

  @override
  String get ageRange => 'Fascia d\'Età';

  @override
  String get aiCoachBenefitAllChapters =>
      'Tutti i capitoli di apprendimento sbloccati';

  @override
  String get aiCoachBenefitFeedback =>
      'Feedback in tempo reale su grammatica e pronuncia';

  @override
  String get aiCoachBenefitPersonalized =>
      'Percorso di apprendimento personalizzato';

  @override
  String get aiCoachBenefitUnlimited =>
      'Pratica di conversazione AI illimitata';

  @override
  String get aiCoachLabel => 'Coach IA';

  @override
  String get aiCoachTrialEnded =>
      'La tua prova gratuita di AI Coach è terminata.';

  @override
  String get aiCoachUpgradePrompt =>
      'Passa a Silver, Gold o Platinum per sbloccare.';

  @override
  String get aiCoachUpgradeTitle => 'Aggiorna per Saperne di Più';

  @override
  String get albumNotShared => 'Album non condiviso';

  @override
  String get albumOption => 'Album';

  @override
  String albumRevokedMessage(String username) {
    return '$username ha revocato l\'accesso all\'album';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username ha condiviso il suo album con te';
  }

  @override
  String get allCategoriesFilter => 'Tutte';

  @override
  String get allDealBreakersAdded =>
      'Tutti i criteri esclusivi sono stati aggiunti';

  @override
  String get allLanguagesFilter => 'Tutte';

  @override
  String get allPlayersReady => 'Tutti i giocatori sono pronti!';

  @override
  String get alreadyHaveAccount => 'Hai già un account?';

  @override
  String get appLanguage => 'Lingua App';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Scopri il Tuo Partner Perfetto';

  @override
  String get approveVerification => 'Approva';

  @override
  String get atLeast8Characters => 'Almeno 8 caratteri';

  @override
  String get atLeastOneNumber => 'Almeno un numero';

  @override
  String get atLeastOneSpecialChar => 'Almeno un carattere speciale';

  @override
  String get authAppleSignInComingSoon => 'Accesso con Apple in arrivo';

  @override
  String get authCancelVerification => 'Annullare la verifica?';

  @override
  String get authCancelVerificationBody =>
      'Verrai disconnesso se annulli la verifica.';

  @override
  String get authDisableInSettings =>
      'Puoi disabilitare questa funzione in Impostazioni > Sicurezza';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Esiste già un account con questa email.';

  @override
  String get authErrorGeneric => 'Si è verificato un errore. Riprova.';

  @override
  String get authErrorInvalidCredentials =>
      'Email/nickname o password errati. Controlla le tue credenziali e riprova.';

  @override
  String get authErrorInvalidEmail => 'Inserisci un indirizzo email valido.';

  @override
  String get authErrorNetworkError =>
      'Nessuna connessione internet. Controlla la connessione e riprova.';

  @override
  String get authErrorTooManyRequests => 'Troppi tentativi. Riprova più tardi.';

  @override
  String get authErrorUserNotFound =>
      'Nessun account trovato con questa email o nickname. Controlla e riprova, oppure registrati.';

  @override
  String get authErrorWeakPassword =>
      'La password è troppo debole. Usa una password più forte.';

  @override
  String get authErrorWrongPassword => 'Password errata. Riprova.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'Impossibile scattare la foto: $error';
  }

  @override
  String get authIdentityVerification => 'Verifica dell\'identità';

  @override
  String get authPleaseEnterEmail => 'Inserisci la tua e-mail';

  @override
  String get authRetakePhoto => 'Scatta di nuovo';

  @override
  String get authSecurityStep =>
      'Questo passaggio di sicurezza aggiuntivo aiuta a proteggere il tuo account';

  @override
  String get authSelfieInstruction =>
      'Guarda la fotocamera e tocca per scattare';

  @override
  String get authSignOut => 'Esci';

  @override
  String get authSignOutInstead => 'Esci invece';

  @override
  String get authStay => 'Resta';

  @override
  String get authTakeSelfie => 'Scatta un selfie';

  @override
  String get authTakeSelfieToVerify =>
      'Scatta un selfie per verificare la tua identità';

  @override
  String get authVerifyAndContinue => 'Verifica e continua';

  @override
  String get authVerifyWithSelfie => 'Verifica la tua identità con un selfie';

  @override
  String authWelcomeBack(Object name) {
    return 'Bentornato, $name!';
  }

  @override
  String get authenticationErrorTitle => 'Accesso Fallito';

  @override
  String get away => 'di distanza';

  @override
  String get awesome => 'Fantastico!';

  @override
  String get backToLobby => 'Torna alla Lobby';

  @override
  String get badgeLocked => 'Bloccato';

  @override
  String get badgeUnlocked => 'Sbloccato';

  @override
  String get badges => 'Badge';

  @override
  String get basic => 'Base';

  @override
  String get basicInformation => 'Informazioni Base';

  @override
  String get betterPhotoRequested => 'Foto migliore richiesta';

  @override
  String get bio => 'Biografia';

  @override
  String get bioUpdatedMessage => 'La bio del tuo profilo è stata salvata';

  @override
  String get bioUpdatedTitle => 'Bio Aggiornata!';

  @override
  String get blindDateActivate => 'Attiva Modalità Appuntamento al Buio';

  @override
  String get blindDateDeactivate => 'Disattiva';

  @override
  String get blindDateDeactivateMessage =>
      'Tornerai alla modalità di scoperta normale.';

  @override
  String get blindDateDeactivateTitle =>
      'Disattivare Modalità Appuntamento al Buio?';

  @override
  String get blindDateDeactivateTooltip =>
      'Disattiva Modalità Appuntamento al Buio';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Rivelazione istantanea per $cost monete';
  }

  @override
  String get blindDateFeatureNoPhotos =>
      'Nessuna foto del profilo visibile inizialmente';

  @override
  String get blindDateFeaturePersonality => 'Focus su personalità e interessi';

  @override
  String get blindDateFeatureUnlock =>
      'Le foto si sbloccano dopo aver chattato';

  @override
  String get blindDateGetCoins => 'Ottieni Monete';

  @override
  String get blindDateInstantReveal => 'Rivelazione Istantanea';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return 'Rivelare tutte le foto di questo match per $cost monete?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Rivelazione istantanea ($cost monete)';
  }

  @override
  String get blindDateInsufficientCoins => 'Monete Insufficienti';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'Ti servono $cost monete per rivelare istantaneamente le foto.';
  }

  @override
  String get blindDateInterests => 'Interessi';

  @override
  String blindDateKmAway(String distance) {
    return 'a $distance km';
  }

  @override
  String get blindDateLetsExchange => 'Scambiamoci!';

  @override
  String get blindDateMatchMessage =>
      'Vi piacete a vicenda! Iniziate a chattare per rivelare le vostre foto.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total messaggi';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return 'ancora $count';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count messaggi alla rivelazione';
  }

  @override
  String get blindDateModeActivated =>
      'Modalità Appuntamento al Buio attivata!';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Trova il match in base alla personalità, non all\'aspetto.\nLe foto si svelano dopo $threshold messaggi.';
  }

  @override
  String get blindDateModeTitle => 'Modalità Appuntamento al Buio';

  @override
  String get blindDateMysteryPerson => 'Persona Misteriosa';

  @override
  String get blindDateNoCandidates => 'Nessun candidato disponibile';

  @override
  String get blindDateNoMatches => 'Nessun match ancora';

  @override
  String blindDatePendingReveal(int count) {
    return 'In attesa di rivelazione ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Progresso Rivelazione Foto';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'Le foto si rivelano dopo $threshold messaggi';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return 'Foto rivelate! $coinsSpent monete spese.';
  }

  @override
  String get blindDatePhotosRevealedLabel => 'Foto rivelate!';

  @override
  String get blindDateReveal => 'Rivela';

  @override
  String blindDateRevealed(int count) {
    return 'Rivelati ($count)';
  }

  @override
  String get blindDateRevealedMatch => 'Match Rivelato';

  @override
  String get blindDateStartSwiping =>
      'Inizia a scorrere per trovare il tuo appuntamento al buio!';

  @override
  String get blindDateTabDiscover => 'Scopri';

  @override
  String get blindDateTabMatches => 'Match';

  @override
  String get blindDateTitle => 'Appuntamento al Buio';

  @override
  String get blindDateViewMatch => 'Vedi Match';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonusCoins bonus!)';
  }

  @override
  String get boost => 'Boost';

  @override
  String get boostActivated => 'Boost attivato per 30 minuti!';

  @override
  String get boostNow => 'Potenzia Ora';

  @override
  String get boostProfile => 'Potenzia Profilo';

  @override
  String get boosted => 'POTENZIATO!';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Pacchetto';

  @override
  String get businessCategory => 'Affari';

  @override
  String get buyCoins => 'Acquista Monete';

  @override
  String get buyCoinsBtnLabel => 'Acquista Monete';

  @override
  String get buyPackBtn => 'Acquista';

  @override
  String get cancel => 'Annulla';

  @override
  String get cancelLabel => 'Annulla';

  @override
  String get cannotAccessFeature =>
      'Questa funzione è disponibile dopo la verifica del tuo account.';

  @override
  String get cantUndoMatched => 'Non puoi annullare — hai già un match!';

  @override
  String get casualCategory => 'Informale';

  @override
  String get casualDating => 'Incontri casuali';

  @override
  String get categoryFlashcard => 'Scheda';

  @override
  String get categoryLearning => 'Apprendimento';

  @override
  String get categoryMultilingual => 'Multilingue';

  @override
  String get categoryName => 'Categoria';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Stagionale';

  @override
  String get categorySocial => 'Sociale';

  @override
  String get categoryStreak => 'Serie';

  @override
  String get categoryTranslation => 'Traduzione';

  @override
  String get challenges => 'Sfide';

  @override
  String get changeLocation => 'Cambia posizione';

  @override
  String get changePassword => 'Cambia Password';

  @override
  String get changePasswordConfirm => 'Conferma Nuova Password';

  @override
  String get changePasswordCurrent => 'Password Attuale';

  @override
  String get changePasswordDescription =>
      'Per sicurezza, verifica la tua identità prima di cambiare la password.';

  @override
  String get changePasswordEmailConfirm => 'Conferma il tuo indirizzo email';

  @override
  String get changePasswordEmailHint => 'La tua email';

  @override
  String get changePasswordEmailMismatch =>
      'L\'email non corrisponde al tuo account';

  @override
  String get changePasswordNew => 'Nuova Password';

  @override
  String get changePasswordReauthRequired =>
      'Disconnettiti e accedi di nuovo prima di cambiare la password';

  @override
  String get changePasswordSubtitle => 'Aggiorna la password del tuo account';

  @override
  String get changePasswordSuccess => 'Password cambiata con successo';

  @override
  String get changePasswordWrongCurrent => 'La password attuale non è corretta';

  @override
  String get chatAddCaption => 'Aggiungi una didascalia...';

  @override
  String get chatAddToStarred => 'Aggiungi ai messaggi preferiti';

  @override
  String get chatAlreadyInYourLanguage => 'Il messaggio è già nella tua lingua';

  @override
  String get chatAttachCamera => 'Fotocamera';

  @override
  String get chatAttachGallery => 'Galleria';

  @override
  String get chatAttachRecord => 'Registra';

  @override
  String get chatAttachVideo => 'Video';

  @override
  String get chatBlock => 'Blocca';

  @override
  String chatBlockUser(String name) {
    return 'Blocca $name';
  }

  @override
  String chatBlockUserMessage(String name) {
    return 'Sei sicuro di voler bloccare $name? Non potranno più contattarti.';
  }

  @override
  String get chatBlockUserTitle => 'Blocca Utente';

  @override
  String get chatCannotBlockAdmin => 'Non puoi bloccare un amministratore.';

  @override
  String get chatCannotReportAdmin => 'Non puoi segnalare un amministratore.';

  @override
  String get chatCategory => 'Categoria';

  @override
  String get chatCategoryAccount => 'Assistenza Account';

  @override
  String get chatCategoryBilling => 'Fatturazione e Pagamenti';

  @override
  String get chatCategoryFeedback => 'Feedback';

  @override
  String get chatCategoryGeneral => 'Domanda Generale';

  @override
  String get chatCategorySafety => 'Segnalazione Sicurezza';

  @override
  String get chatCategoryTechnical => 'Problema Tecnico';

  @override
  String get chatCopy => 'Copia';

  @override
  String get chatCreate => 'Crea';

  @override
  String get chatCreateSupportTicket => 'Crea Ticket di Supporto';

  @override
  String get chatCreateTicket => 'Crea Ticket';

  @override
  String chatDaysAgo(int count) {
    return '${count}g fa';
  }

  @override
  String get chatDelete => 'Elimina';

  @override
  String get chatDeleteChat => 'Elimina Chat';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Questo eliminerà tutti i messaggi per te e $name. Questa azione non può essere annullata.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Elimina Chat per Tutti';

  @override
  String get chatDeleteChatForMeMessage =>
      'Questo eliminerà la chat solo dal tuo dispositivo. L\'altra persona vedrà ancora i messaggi.';

  @override
  String chatDeleteConversationWith(String name) {
    return 'Eliminare la conversazione con $name?';
  }

  @override
  String get chatDeleteForBoth => 'Elimina chat per entrambi';

  @override
  String get chatDeleteForBothDescription =>
      'Questo eliminerà permanentemente la conversazione per te e l\'altra persona.';

  @override
  String get chatDeleteForEveryone => 'Elimina per Tutti';

  @override
  String get chatDeleteForMe => 'Elimina chat per me';

  @override
  String get chatDeleteForMeDescription =>
      'Questo eliminerà la conversazione solo dalla tua lista chat. L\'altra persona la vedrà ancora.';

  @override
  String get chatDeletedForBothMessage =>
      'Questa chat è stata eliminata definitivamente';

  @override
  String get chatDeletedForMeMessage =>
      'Questa chat è stata rimossa dalla tua posta';

  @override
  String get chatDeletedTitle => 'Chat Eliminata!';

  @override
  String get chatDescriptionOptional => 'Descrizione (Opzionale)';

  @override
  String get chatDetailsHint =>
      'Fornisci maggiori dettagli sul tuo problema...';

  @override
  String get chatDisableTranslation => 'Disattiva traduzione';

  @override
  String get chatEnableTranslation => 'Attiva traduzione';

  @override
  String get chatErrorLoadingTickets => 'Errore nel caricamento dei ticket';

  @override
  String get chatFailedToCreateTicket => 'Impossibile creare il ticket';

  @override
  String get chatFailedToForwardMessage => 'Impossibile inoltrare il messaggio';

  @override
  String get chatFailedToLoadAlbum => 'Impossibile caricare l\'album';

  @override
  String get chatFailedToLoadConversations =>
      'Impossibile caricare le conversazioni';

  @override
  String get chatFailedToLoadImage => 'Impossibile caricare l\'immagine';

  @override
  String get chatFailedToLoadVideo => 'Impossibile caricare il video';

  @override
  String chatFailedToPickImage(String error) {
    return 'Impossibile selezionare l\'immagine: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Impossibile selezionare il video: $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Impossibile segnalare il messaggio: $error';
  }

  @override
  String get chatFailedToRevokeAccess => 'Impossibile revocare l\'accesso';

  @override
  String get chatFailedToSaveFlashcard => 'Impossibile salvare la carta';

  @override
  String get chatFailedToShareAlbum => 'Impossibile condividere l\'album';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Impossibile caricare l\'immagine: $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Impossibile caricare il video: $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Consigli culturali e contesto';

  @override
  String get chatFeatureGrammar => 'Feedback grammaticale in tempo reale';

  @override
  String get chatFeatureVocabulary => 'Esercizi di vocabolario';

  @override
  String get chatForward => 'Inoltra';

  @override
  String get chatForwardMessage => 'Inoltra Messaggio';

  @override
  String get chatForwardToChat => 'Inoltra a un\'altra chat';

  @override
  String chatHoursAgo(int count) {
    return '${count}h fa';
  }

  @override
  String get chatIcebreakers => 'Rompighiaccio';

  @override
  String chatIsTyping(String userName) {
    return '$userName sta scrivendo';
  }

  @override
  String get chatJustNow => 'Proprio ora';

  @override
  String get chatLearnThis => 'Impara Questo';

  @override
  String get chatListen => 'Ascolta';

  @override
  String get chatLoadingVideo => 'Caricamento video...';

  @override
  String get chatMaybeLater => 'Forse più tardi';

  @override
  String get chatMediaLimitReached => 'Limite media raggiunto';

  @override
  String get chatMessage => 'Messaggio';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Messaggio bloccato: Contiene $violations. Per la tua sicurezza, non è consentito condividere dati di contatto personali.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Messaggio inoltrato a $count conversazione/i';
  }

  @override
  String get chatMessageOptions => 'Opzioni Messaggio';

  @override
  String get chatMessageOriginal => 'Originale';

  @override
  String get chatMessageReported =>
      'Messaggio segnalato. Lo esamineremo a breve.';

  @override
  String get chatMessageStarred => 'Messaggio aggiunto ai preferiti';

  @override
  String get chatMessageTranslated => 'Tradotto';

  @override
  String get chatMessageUnstarred => 'Messaggio rimosso dai preferiti';

  @override
  String chatMinutesAgo(int count) {
    return '${count}min fa';
  }

  @override
  String get chatMySupportTickets => 'I Miei Ticket di Supporto';

  @override
  String get chatNeedHelpCreateTicket =>
      'Hai bisogno di aiuto? Crea un nuovo ticket.';

  @override
  String get chatNewTicket => 'Nuovo Ticket';

  @override
  String get chatNoConversationsToForward =>
      'Nessuna conversazione per l\'inoltro';

  @override
  String get chatNoMatchingConversations =>
      'Nessuna conversazione corrispondente';

  @override
  String get chatNoMessagesYet => 'Nessun messaggio ancora';

  @override
  String get chatNoPrivatePhotos => 'Nessuna foto privata disponibile';

  @override
  String get chatNoSupportTickets => 'Nessun Ticket di Supporto';

  @override
  String get chatOptions => 'Opzioni Chat';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name ha revocato l\'accesso all\'album';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name ha condiviso il suo album privato';
  }

  @override
  String get chatPhoto => 'Foto';

  @override
  String get chatPhraseSaved => 'Frase salvata nel tuo mazzo di carte!';

  @override
  String get chatPleaseEnterSubject => 'Inserisci un oggetto';

  @override
  String get chatPractice => 'Pratica';

  @override
  String get chatPracticeMode => 'Modalità Pratica';

  @override
  String get chatPracticeTrialStarted =>
      'Prova della modalità pratica avviata! Hai 3 sessioni gratuite.';

  @override
  String get chatPreviewImage => 'Anteprima Immagine';

  @override
  String get chatPreviewVideo => 'Anteprima Video';

  @override
  String get chatRemoveFromStarred => 'Rimuovi dai messaggi preferiti';

  @override
  String get chatReply => 'Rispondi';

  @override
  String get chatReplyToMessage => 'Rispondi a questo messaggio';

  @override
  String chatReplyingTo(String name) {
    return 'In risposta a $name';
  }

  @override
  String get chatReportInappropriate => 'Segnala contenuto inappropriato';

  @override
  String get chatReportMessage => 'Segnala Messaggio';

  @override
  String get chatReportReasonFakeProfile => 'Profilo falso / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Molestie o bullismo';

  @override
  String get chatReportReasonInappropriate => 'Contenuto inappropriato';

  @override
  String get chatReportReasonOther => 'Altro';

  @override
  String get chatReportReasonPersonalInfo =>
      'Condivisione di informazioni personali';

  @override
  String get chatReportReasonSpam => 'Spam o truffa';

  @override
  String get chatReportReasonThreatening => 'Comportamento minaccioso';

  @override
  String get chatReportReasonUnderage => 'Utente minorenne';

  @override
  String chatReportUser(String name) {
    return 'Segnala $name';
  }

  @override
  String get chatReportUserTitle => 'Segnala Utente';

  @override
  String get chatSafetyGotIt => 'Capito';

  @override
  String get chatSafetySubtitle =>
      'La tua sicurezza è la nostra priorità. Tieni a mente questi consigli.';

  @override
  String get chatSafetyTip => 'Consiglio di Sicurezza';

  @override
  String get chatSafetyTip1Description =>
      'Non condividere indirizzo, numero di telefono o informazioni finanziarie.';

  @override
  String get chatSafetyTip1Title => 'Mantieni Private le Info Personali';

  @override
  String get chatSafetyTip2Description =>
      'Non inviare mai denaro a qualcuno che non hai incontrato di persona.';

  @override
  String get chatSafetyTip2Title => 'Attenzione alle Richieste di Denaro';

  @override
  String get chatSafetyTip3Description =>
      'Per i primi incontri, scegli sempre un luogo pubblico e ben illuminato.';

  @override
  String get chatSafetyTip3Title => 'Incontra in Luoghi Pubblici';

  @override
  String get chatSafetyTip4Description =>
      'Se qualcosa non ti sembra giusto, fidati del tuo istinto e termina la conversazione.';

  @override
  String get chatSafetyTip4Title => 'Fidati del Tuo Istinto';

  @override
  String get chatSafetyTip5Description =>
      'Usa la funzione di segnalazione se qualcuno ti mette a disagio.';

  @override
  String get chatSafetyTip5Title => 'Segnala Comportamenti Sospetti';

  @override
  String get chatSafetyTitle => 'Chatta in Sicurezza';

  @override
  String get chatSaving => 'Salvataggio...';

  @override
  String chatSayHiTo(String name) {
    return 'Saluta $name!';
  }

  @override
  String get chatSearchByNameOrNickname => 'Cerca per nome o @nickname';

  @override
  String get chatSearchConversationsHint => 'Cerca conversazioni...';

  @override
  String get chatSend => 'Invia';

  @override
  String get chatSendAttachment => 'Invia Allegato';

  @override
  String chatSendCount(int count) {
    return 'Invia ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Invia un messaggio per iniziare la conversazione';

  @override
  String get chatSendMessagesForTips =>
      'Invia messaggi per ricevere consigli sulle lingue!';

  @override
  String get chatSetNativeLanguage =>
      'Imposta prima la tua lingua madre nelle impostazioni';

  @override
  String get chatSomeone => 'Qualcuno';

  @override
  String get chatStarMessage => 'Aggiungi ai Preferiti';

  @override
  String get chatStartSwipingToChat =>
      'Scorri e fai match per chattare con le persone!';

  @override
  String get chatStatusAssigned => 'Assegnato';

  @override
  String get chatStatusAwaitingReply => 'In attesa di risposta';

  @override
  String get chatStatusClosed => 'Chiuso';

  @override
  String get chatStatusInProgress => 'In corso';

  @override
  String get chatStatusOpen => 'Aperto';

  @override
  String get chatStatusResolved => 'Risolto';

  @override
  String get chatSubject => 'Oggetto';

  @override
  String get chatSubjectHint => 'Breve descrizione del tuo problema';

  @override
  String get chatSupportAddAttachment => 'Aggiungi Allegato';

  @override
  String get chatSupportAddCaptionOptional =>
      'Aggiungi didascalia (opzionale)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agente: $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agente';

  @override
  String get chatSupportCategory => 'Categoria';

  @override
  String get chatSupportClose => 'Chiudi';

  @override
  String chatSupportDaysAgo(int days) {
    return '${days}g fa';
  }

  @override
  String get chatSupportErrorLoading => 'Errore nel caricamento dei messaggi';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Impossibile riaprire il ticket: $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Impossibile inviare il messaggio: $error';
  }

  @override
  String get chatSupportGeneral => 'Generale';

  @override
  String get chatSupportGeneralSupport => 'Supporto Generale';

  @override
  String chatSupportHoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String get chatSupportJustNow => 'Adesso';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return '${minutes}min fa';
  }

  @override
  String get chatSupportReopenTicket =>
      'Hai bisogno di ulteriore aiuto? Tocca per riaprire';

  @override
  String get chatSupportStartMessage =>
      'Invia un messaggio per iniziare la conversazione.\nIl nostro team risponderà il prima possibile.';

  @override
  String get chatSupportStatus => 'Stato';

  @override
  String get chatSupportStatusClosed => 'Chiuso';

  @override
  String get chatSupportStatusDefault => 'Supporto';

  @override
  String get chatSupportStatusOpen => 'Aperto';

  @override
  String get chatSupportStatusPending => 'In attesa';

  @override
  String get chatSupportStatusResolved => 'Risolto';

  @override
  String get chatSupportSubject => 'Oggetto';

  @override
  String get chatSupportTicketCreated => 'Ticket Creato';

  @override
  String get chatSupportTicketId => 'ID Ticket';

  @override
  String get chatSupportTicketInfo => 'Informazioni Ticket';

  @override
  String get chatSupportTicketReopened =>
      'Ticket riaperto. Puoi inviare un messaggio ora.';

  @override
  String get chatSupportTicketResolved => 'Questo ticket è stato risolto';

  @override
  String get chatSupportTicketStart => 'Inizio Ticket';

  @override
  String get chatSupportTitle => 'Supporto GreenGo';

  @override
  String get chatSupportTypeMessage => 'Scrivi il tuo messaggio...';

  @override
  String get chatSupportWaitingAssignment => 'In attesa di assegnazione';

  @override
  String get chatSupportWelcome => 'Benvenuto al Supporto';

  @override
  String get chatTapToView => 'Tocca per vedere';

  @override
  String get chatTapToViewAlbum => 'Tocca per vedere l\'album';

  @override
  String get chatTranslate => 'Traduci';

  @override
  String get chatTranslated => 'Tradotto';

  @override
  String get chatTranslating => 'Traduzione...';

  @override
  String get chatTranslationDisabled => 'Traduzione disattivata';

  @override
  String get chatTranslationEnabled => 'Traduzione attivata';

  @override
  String get chatTranslationFailed => 'Traduzione fallita. Riprova.';

  @override
  String get chatTrialExpired => 'La tua prova gratuita è scaduta.';

  @override
  String get chatTtsComingSoon => 'Sintesi vocale in arrivo!';

  @override
  String get chatTyping => 'sta scrivendo...';

  @override
  String get chatUnableToForward => 'Impossibile inoltrare il messaggio';

  @override
  String get chatUnknown => 'Sconosciuto';

  @override
  String get chatUnstarMessage => 'Rimuovi dai Preferiti';

  @override
  String get chatUpgrade => 'Aggiorna';

  @override
  String get chatUpgradePracticeMode =>
      'Passa a Silver VIP o superiore per continuare a praticare le lingue nelle tue chat.';

  @override
  String get chatUploading => 'Caricamento...';

  @override
  String chatUserBlocked(String name) {
    return '$name è stato bloccato';
  }

  @override
  String get chatUserReported =>
      'Utente segnalato. Esamineremo la tua segnalazione a breve.';

  @override
  String get chatVideo => 'Video';

  @override
  String get chatVideoPlayer => 'Lettore Video';

  @override
  String get chatVideoTooLarge =>
      'Video troppo grande. La dimensione massima è 50MB.';

  @override
  String get chatWhyReportMessage => 'Perché segnali questo messaggio?';

  @override
  String chatWhyReportUser(String name) {
    return 'Perché segnali $name?';
  }

  @override
  String chatWithName(String name) {
    return 'Chatta con $name';
  }

  @override
  String get chatYou => 'Tu';

  @override
  String get chatYouRevokedAlbum => 'Hai revocato l\'accesso all\'album';

  @override
  String get chatYouSharedAlbum => 'Hai condiviso il tuo album privato';

  @override
  String get checkBackLater =>
      'Torna più tardi per nuove persone, o modifica le tue preferenze';

  @override
  String get chooseCorrectAnswer => 'Scegli la risposta corretta';

  @override
  String get chooseFromGallery => 'Scegli dalla Galleria';

  @override
  String get chooseGame => 'Scegli un Gioco';

  @override
  String get claimReward => 'Riscuoti Ricompensa';

  @override
  String get claimRewardBtn => 'Riscatta';

  @override
  String get clearFilters => 'Cancella Filtri';

  @override
  String get close => 'Chiudi';

  @override
  String get coins => 'Monete';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins monete aggiunte al tuo account$bonusText';
  }

  @override
  String get coinsAllTransactions => 'Tutte le Transazioni';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount Monete';
  }

  @override
  String coinsAmountVideoMinutes(Object amount) {
    return '$amount Minuti Video';
  }

  @override
  String get coinsApply => 'Applica';

  @override
  String coinsBalance(Object balance) {
    return 'Saldo: $balance';
  }

  @override
  String coinsBonusCoins(Object amount) {
    return '+$amount monete bonus';
  }

  @override
  String get coinsCancelLabel => 'Annulla';

  @override
  String get coinsConfirmPurchase => 'Conferma Acquisto';

  @override
  String coinsCost(int amount) {
    return '$amount monete';
  }

  @override
  String get coinsCreditsOnly => 'Solo Accrediti';

  @override
  String get coinsDebitsOnly => 'Solo Addebiti';

  @override
  String get coinsEnterReceiverId => 'Inserisci l\'ID del destinatario';

  @override
  String coinsExpiring(Object count) {
    return '$count in scadenza';
  }

  @override
  String get coinsFilterTransactions => 'Filtra Transazioni';

  @override
  String coinsGiftAccepted(Object amount) {
    return '$amount monete accettate!';
  }

  @override
  String get coinsGiftDeclined => 'Regalo rifiutato';

  @override
  String get coinsGiftSendFailed => 'Invio regalo non riuscito';

  @override
  String coinsGiftSent(Object amount) {
    return 'Regalo di $amount monete inviato!';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Monete insufficienti';

  @override
  String get coinsLabel => 'Monete';

  @override
  String get coinsMessageLabel => 'Messaggio (facoltativo)';

  @override
  String get coinsMins => 'min';

  @override
  String get coinsNoTransactionsYet => 'Nessuna transazione ancora';

  @override
  String get coinsPendingGifts => 'Regali in Sospeso';

  @override
  String get coinsPopular => 'POPOLARE';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return 'Acquistare $totalCoins monete per $price?';
  }

  @override
  String get coinsPurchaseFailed => 'Acquisto non riuscito';

  @override
  String get coinsPurchaseLabel => 'Acquista';

  @override
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return 'Acquistare $totalMinutes minuti video per $price?';
  }

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return 'Acquistate con successo $totalCoins monete!';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return 'Acquistati con successo $totalMinutes minuti video!';
  }

  @override
  String get coinsReceiverIdLabel => 'ID Utente Destinatario';

  @override
  String coinsRequired(int amount) {
    return '$amount monete richieste';
  }

  @override
  String get coinsRetry => 'Riprova';

  @override
  String get coinsSelectAmount => 'Seleziona Importo';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return 'Invia $amount Monete';
  }

  @override
  String get coinsSendGift => 'Invia Regalo';

  @override
  String get coinsSent => 'Monete inviate con successo!';

  @override
  String get coinsShareCoins => 'Condividi monete con qualcuno di speciale';

  @override
  String get coinsShopLabel => 'Negozio';

  @override
  String get coinsTabCoins => 'Monete';

  @override
  String get coinsTabGifts => 'Regali';

  @override
  String get coinsTabVideoCoins => 'Video Monete';

  @override
  String get coinsToday => 'Oggi';

  @override
  String get coinsTransactionHistory => 'Cronologia Transazioni';

  @override
  String get coinsTransactionsAppearHere =>
      'Le tue transazioni di monete appariranno qui';

  @override
  String get coinsUnlockPremium => 'Sblocca funzionalita premium';

  @override
  String get coinsVideoCallMatches => 'Videochiamata con i tuoi match';

  @override
  String get coinsVideoCoinInfo => '1 Video Coin = 1 minuto di videochiamata';

  @override
  String get coinsVideoMin => 'Min Video';

  @override
  String get coinsVideoMinutes => 'Minuti Video';

  @override
  String get coinsYesterday => 'Ieri';

  @override
  String get comingSoonLabel => 'Prossimamente';

  @override
  String get communitiesAddTag => 'Aggiungi tag';

  @override
  String get communitiesAdjustSearch =>
      'Prova a modificare la ricerca o i filtri.';

  @override
  String get communitiesAllCommunities => 'Tutte le Comunita';

  @override
  String get communitiesAllFilter => 'Tutte';

  @override
  String get communitiesAnyoneCanJoin => 'Chiunque puo unirsi';

  @override
  String get communitiesBeFirstToSay => 'Sii il primo a scrivere qualcosa!';

  @override
  String get communitiesCancelLabel => 'Annulla';

  @override
  String get communitiesCityLabel => 'Citta';

  @override
  String get communitiesCityTipLabel => 'Consiglio Citta';

  @override
  String get communitiesCityTipUpper => 'CONSIGLIO CITTA';

  @override
  String get communitiesCommunityInfo => 'Info Comunita';

  @override
  String get communitiesCommunityName => 'Nome Comunita';

  @override
  String get communitiesCommunityType => 'Tipo Comunita';

  @override
  String get communitiesCountryLabel => 'Paese';

  @override
  String get communitiesCreateAction => 'Crea';

  @override
  String get communitiesCreateCommunity => 'Crea Comunita';

  @override
  String get communitiesCreateCommunityAction => 'Crea Comunita';

  @override
  String get communitiesCreateLabel => 'Crea';

  @override
  String get communitiesCreateLanguageCircle => 'Crea Circolo Linguistico';

  @override
  String get communitiesCreated => 'Community creata!';

  @override
  String communitiesCreatedBy(String name) {
    return 'Creato da $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Creato';

  @override
  String get communitiesCulturalFactLabel => 'Curiosita Culturale';

  @override
  String get communitiesCulturalFactUpper => 'CURIOSITA CULTURALE';

  @override
  String get communitiesDescription => 'Descrizione';

  @override
  String get communitiesDescriptionHint => 'Di cosa tratta questa comunita?';

  @override
  String get communitiesDescriptionLabel => 'Descrizione';

  @override
  String get communitiesDescriptionMinLength =>
      'La descrizione deve avere almeno 10 caratteri';

  @override
  String get communitiesDescriptionRequired => 'Inserisci una descrizione';

  @override
  String get communitiesDiscoverCommunities => 'Scopri Comunita';

  @override
  String get communitiesEditLabel => 'Modifica';

  @override
  String get communitiesGuide => 'Guida';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Solo su invito';

  @override
  String get communitiesJoinCommunity => 'Unisciti alla Comunita';

  @override
  String get communitiesJoinPrompt =>
      'Unisciti alle comunita per connetterti con persone che condividono i tuoi interessi e le tue lingue.';

  @override
  String get communitiesJoined => 'Community raggiunta!';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'I circoli linguistici appariranno qui quando disponibili. Creane uno per iniziare!';

  @override
  String get communitiesLanguageTipLabel => 'Consiglio Lingua';

  @override
  String get communitiesLanguageTipUpper => 'CONSIGLIO LINGUA';

  @override
  String get communitiesLanguages => 'Lingue';

  @override
  String get communitiesLanguagesLabel => 'Lingue';

  @override
  String get communitiesLeaveCommunity => 'Lascia la Comunita';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Sei sicuro di voler lasciare \"$name\"?';
  }

  @override
  String get communitiesLeaveLabel => 'Lascia';

  @override
  String get communitiesLeaveTitle => 'Lascia la Comunita';

  @override
  String get communitiesLocation => 'Posizione';

  @override
  String get communitiesLocationLabel => 'Posizione';

  @override
  String communitiesMembersCount(Object count) {
    return '$count membri';
  }

  @override
  String get communitiesMembersStatLabel => 'Membri';

  @override
  String get communitiesMembersTitle => 'Membri';

  @override
  String get communitiesNameHint => 'es., Studenti di Spagnolo Roma';

  @override
  String get communitiesNameMinLength =>
      'Il nome deve avere almeno 3 caratteri';

  @override
  String get communitiesNameRequired => 'Inserisci un nome';

  @override
  String get communitiesNoCommunities => 'Nessuna Comunita Ancora';

  @override
  String get communitiesNoCommunitiesFound => 'Nessuna Comunita Trovata';

  @override
  String get communitiesNoLanguageCircles => 'Nessun Circolo Linguistico';

  @override
  String get communitiesNoMessagesYet => 'Nessun messaggio ancora';

  @override
  String get communitiesPreview => 'Anteprima';

  @override
  String get communitiesPreviewSubtitle =>
      'Ecco come apparira la tua comunita agli altri.';

  @override
  String get communitiesPrivate => 'Privata';

  @override
  String get communitiesPublic => 'Pubblica';

  @override
  String get communitiesRecommendedForYou => 'Consigliato per Te';

  @override
  String get communitiesSearchHint => 'Cerca community...';

  @override
  String get communitiesShareCityTip => 'Condividi un consiglio sulla citta...';

  @override
  String get communitiesShareCulturalFact =>
      'Condividi una curiosita culturale...';

  @override
  String get communitiesShareLanguageTip =>
      'Condividi un consiglio linguistico...';

  @override
  String get communitiesStats => 'Statistiche';

  @override
  String get communitiesTabDiscover => 'Scopri';

  @override
  String get communitiesTabLanguageCircles => 'Circoli Linguistici';

  @override
  String get communitiesTabMyGroups => 'I Miei Gruppi';

  @override
  String get communitiesTags => 'Tag';

  @override
  String get communitiesTagsLabel => 'Tag';

  @override
  String get communitiesTextLabel => 'Testo';

  @override
  String get communitiesTitle => 'Comunita';

  @override
  String get communitiesTypeAMessage => 'Scrivi un messaggio...';

  @override
  String get communitiesUnableToLoad => 'Impossibile caricare la comunita';

  @override
  String get compatibilityLabel => 'Compatibilita';

  @override
  String compatiblePercent(String percent) {
    return '$percent% compatibile';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      'Completa traguardi per ottenere badge!';

  @override
  String get completeProfile => 'Completa il Tuo Profilo';

  @override
  String get complimentsCategory => 'Complimenti';

  @override
  String get confirm => 'Conferma';

  @override
  String get confirmLabel => 'Conferma';

  @override
  String get confirmLocation => 'Conferma posizione';

  @override
  String get confirmPassword => 'Conferma Password';

  @override
  String get confirmPasswordRequired => 'Si prega di confermare la password';

  @override
  String get connectSocialAccounts => 'Collega i tuoi account social';

  @override
  String get connectionError => 'Errore di connessione';

  @override
  String get connectionErrorMessage =>
      'Controlla la tua connessione internet e riprova.';

  @override
  String get connectionErrorTitle => 'Nessuna Connessione Internet';

  @override
  String get consentRequired => 'Consensi Obbligatori';

  @override
  String get consentRequiredError =>
      'Devi accettare l\'Informativa sulla Privacy e i Termini e Condizioni per registrarti';

  @override
  String get contactSupport => 'Contatta Supporto';

  @override
  String get continueLearningBtn => 'Continua';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get continueWithFacebook => 'Continua con Facebook';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get conversationCategory => 'Conversazione';

  @override
  String get correctAnswer => 'Corretto!';

  @override
  String get couldNotOpenLink => 'Impossibile aprire il link';

  @override
  String get createAccount => 'Crea Account';

  @override
  String get culturalCategory => 'Culturale';

  @override
  String get culturalExchangeBeFirstTip =>
      'Sii il primo a condividere un consiglio culturale!';

  @override
  String get culturalExchangeCategory => 'Categoria';

  @override
  String get culturalExchangeCommunityTips => 'Consigli della community';

  @override
  String get culturalExchangeCountry => 'Paese';

  @override
  String get culturalExchangeCountryHint => 'es. Giappone, Brasile, Francia';

  @override
  String get culturalExchangeCountrySpotlight => 'Paese in evidenza';

  @override
  String get culturalExchangeDailyInsight => 'Curiosità culturale del giorno';

  @override
  String get culturalExchangeDatingEtiquette => 'Galateo degli appuntamenti';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Guida al galateo degli appuntamenti';

  @override
  String get culturalExchangeLoadingCountries => 'Caricamento paesi...';

  @override
  String get culturalExchangeNoTips => 'Ancora nessun consiglio';

  @override
  String get culturalExchangeShareCulturalTip =>
      'Condividi un consiglio culturale';

  @override
  String get culturalExchangeShareTip => 'Condividi un consiglio';

  @override
  String get culturalExchangeSubmitTip => 'Invia consiglio';

  @override
  String get culturalExchangeTipTitle => 'Titolo';

  @override
  String get culturalExchangeTipTitleHint =>
      'Dai un titolo accattivante al tuo consiglio';

  @override
  String get culturalExchangeTitle => 'Scambio culturale';

  @override
  String get culturalExchangeViewAll => 'Vedi tutto';

  @override
  String get culturalExchangeYourTip => 'Il tuo consiglio';

  @override
  String get culturalExchangeYourTipHint =>
      'Condividi le tue conoscenze culturali...';

  @override
  String get dailyChallengesTitle => 'Sfide Giornaliere';

  @override
  String dailyLimitReached(int limit) {
    return 'Limite giornaliero di $limit raggiunto';
  }

  @override
  String get dailyMessages => 'Messaggi Giornalieri';

  @override
  String get dailyRewardHeader => 'Ricompensa Giornaliera';

  @override
  String get dailySwipeLimitReached =>
      'Limite giornaliero di swipe raggiunto. Aggiorna per più swipe!';

  @override
  String get dailySwipes => 'Swipe Giornalieri';

  @override
  String get dataExportSentToEmail =>
      'Esportazione dati inviata alla tua email';

  @override
  String get dateOfBirth => 'Data di Nascita';

  @override
  String get datePlanningCategory => 'Pianifica Appuntamento';

  @override
  String get dateSchedulerAccept => 'Accetta';

  @override
  String get dateSchedulerCancelConfirm =>
      'Sei sicuro di voler annullare questo appuntamento?';

  @override
  String get dateSchedulerCancelTitle => 'Annulla Appuntamento';

  @override
  String get dateSchedulerConfirmed => 'Appuntamento confermato!';

  @override
  String get dateSchedulerDecline => 'Rifiuta';

  @override
  String get dateSchedulerEnterTitle => 'Inserisci un titolo';

  @override
  String get dateSchedulerKeepDate => 'Mantieni Appuntamento';

  @override
  String get dateSchedulerNotesLabel => 'Note (facoltativo)';

  @override
  String get dateSchedulerPlanningHint => 'es. Caffè, Cena, Cinema...';

  @override
  String get dateSchedulerReasonLabel => 'Motivo (facoltativo)';

  @override
  String get dateSchedulerReschedule => 'Riprogramma';

  @override
  String get dateSchedulerRescheduleTitle => 'Riprogramma Appuntamento';

  @override
  String get dateSchedulerSchedule => 'Programma';

  @override
  String get dateSchedulerScheduled => 'Appuntamento programmato!';

  @override
  String get dateSchedulerTabPast => 'Passati';

  @override
  String get dateSchedulerTabPending => 'In Attesa';

  @override
  String get dateSchedulerTabUpcoming => 'In Arrivo';

  @override
  String get dateSchedulerTitle => 'I Miei Appuntamenti';

  @override
  String get dateSchedulerWhatPlanning => 'Cosa stai organizzando?';

  @override
  String dayNumber(int day) {
    return 'Giorno $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count giorni consecutivi';
  }

  @override
  String dayStreakLabel(int days) {
    return '$days Giorni di Serie!';
  }

  @override
  String get days => 'Giorni';

  @override
  String daysAgo(int count) {
    return '$count giorni fa';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get deleteAccount => 'Elimina Account';

  @override
  String get deleteAccountConfirmation =>
      'Sei sicuro di voler eliminare il tuo account? Questa azione non può essere annullata e tutti i tuoi dati verranno eliminati definitivamente.';

  @override
  String get details => 'Dettagli';

  @override
  String get difficultyLabel => 'Difficoltà';

  @override
  String directMessageCost(int cost) {
    return 'I messaggi diretti costano $cost monete. Vuoi acquistarne di piu?';
  }

  @override
  String get discover => 'Scambio';

  @override
  String discoveryError(String error) {
    return 'Errore: $error';
  }

  @override
  String get discoveryFilterAll => 'Tutti';

  @override
  String get discoveryFilterGuides => 'Guide';

  @override
  String get discoveryFilterLiked => 'Piaciuti';

  @override
  String get discoveryFilterMatches => 'Match';

  @override
  String get discoveryFilterPassed => 'Rifiutati';

  @override
  String get discoveryFilterSkipped => 'Saltati';

  @override
  String get discoveryFilterSuperLiked => 'Super Like';

  @override
  String get discoveryFilterTravelers => 'Viaggiatori';

  @override
  String get discoveryPreferencesTitle => 'Preferenze di Scoperta';

  @override
  String get discoveryPreferencesTooltip => 'Preferenze di Scoperta';

  @override
  String get discoverySwitchToGrid => 'Passa alla modalità griglia';

  @override
  String get discoverySwitchToSwipe => 'Passa alla modalità swipe';

  @override
  String get dismiss => 'Chiudi';

  @override
  String get distance => 'Distanza';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Documento non disponibile';

  @override
  String get documentNotAvailableDescription =>
      'Questo documento non e ancora disponibile nella tua lingua.';

  @override
  String get done => 'Fatto';

  @override
  String get dontHaveAccount => 'Non hai un account?';

  @override
  String get download => 'Scarica';

  @override
  String downloadProgress(int current, int total) {
    return '$current di $total';
  }

  @override
  String downloadingLanguage(String language) {
    return 'Download di $language in corso...';
  }

  @override
  String get downloadingTranslationData => 'Download Dati di Traduzione';

  @override
  String get edit => 'Modifica';

  @override
  String get editInterests => 'Modifica Interessi';

  @override
  String get editNickname => 'Modifica Nickname';

  @override
  String get editProfile => 'Modifica Profilo';

  @override
  String get editVoiceComingSoon => 'Modifica voce in arrivo';

  @override
  String get education => 'Istruzione';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Inserisci un\'email valida';

  @override
  String get emailRequired => 'Email richiesta';

  @override
  String get emergencyCategory => 'Emergenza';

  @override
  String get emptyStateErrorMessage =>
      'Non siamo riusciti a caricare questo contenuto. Riprova.';

  @override
  String get emptyStateErrorTitle => 'Qualcosa è andato storto';

  @override
  String get emptyStateNoInternetMessage =>
      'Controlla la tua connessione internet e riprova.';

  @override
  String get emptyStateNoInternetTitle => 'Nessuna connessione';

  @override
  String get emptyStateNoLikesMessage =>
      'Completa il tuo profilo per ricevere più like!';

  @override
  String get emptyStateNoLikesTitle => 'Nessun like ancora';

  @override
  String get emptyStateNoMatchesMessage =>
      'Inizia a scorrere per trovare il tuo match perfetto!';

  @override
  String get emptyStateNoMatchesTitle => 'Nessun match ancora';

  @override
  String get emptyStateNoMessagesMessage =>
      'Quando fai match con qualcuno, potrai iniziare a chattare qui.';

  @override
  String get emptyStateNoMessagesTitle => 'Nessun messaggio';

  @override
  String get emptyStateNoNotificationsMessage => 'Non hai nuove notifiche.';

  @override
  String get emptyStateNoNotificationsTitle => 'Tutto in ordine!';

  @override
  String get emptyStateNoResultsMessage =>
      'Prova a modificare la ricerca o i filtri.';

  @override
  String get emptyStateNoResultsTitle => 'Nessun risultato trovato';

  @override
  String get enableAutoTranslation => 'Attiva Traduzione Automatica';

  @override
  String get enableNotifications => 'Attiva Notifiche';

  @override
  String get enterAmount => 'Inserisci l\'importo';

  @override
  String get enterNickname => 'Inserisci nickname';

  @override
  String get enterNicknameHint => 'Inserisci nickname';

  @override
  String get enterNicknameToFind =>
      'Inserisci un nickname per trovare qualcuno direttamente';

  @override
  String get enterRejectionReason => 'Inserisci il motivo del rifiuto';

  @override
  String error(Object error) {
    return 'Errore: $error';
  }

  @override
  String get errorLoadingDocument => 'Errore nel caricamento del documento';

  @override
  String get errorSearchingTryAgain => 'Errore nella ricerca. Riprova.';

  @override
  String get eventsAboutThisEvent => 'Info sull\'evento';

  @override
  String get eventsApplyFilters => 'Applica Filtri';

  @override
  String get eventsAttendees => 'Partecipanti';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max partecipanti';
  }

  @override
  String get eventsBeFirstToSay => 'Sii il primo a scrivere qualcosa!';

  @override
  String get eventsCategory => 'Categoria';

  @override
  String get eventsChatWithAttendees => 'Chatta con gli altri partecipanti';

  @override
  String get eventsCheckBackLater =>
      'Ricontrolla piu tardi o crea il tuo evento!';

  @override
  String get eventsCreateEvent => 'Crea Evento';

  @override
  String get eventsCreatedSuccessfully => 'Evento creato con successo!';

  @override
  String get eventsDateRange => 'Intervallo Date';

  @override
  String get eventsDeleted => 'Evento eliminato';

  @override
  String get eventsDescription => 'Descrizione';

  @override
  String get eventsDistance => 'Distanza';

  @override
  String get eventsEndDateTime => 'Data e Ora di Fine';

  @override
  String get eventsErrorLoadingMessages =>
      'Errore nel caricamento dei messaggi';

  @override
  String get eventsEventFull => 'Evento Completo';

  @override
  String get eventsEventTitle => 'Titolo Evento';

  @override
  String get eventsFilterEvents => 'Filtra Eventi';

  @override
  String get eventsFreeEvent => 'Evento Gratuito';

  @override
  String get eventsFreeLabel => 'GRATUITO';

  @override
  String get eventsFullLabel => 'Completo';

  @override
  String eventsGoing(Object count) {
    return '$count parteciperanno';
  }

  @override
  String get eventsGoingLabel => 'Partecipo';

  @override
  String get eventsGroupChatTooltip => 'Chat di Gruppo dell\'Evento';

  @override
  String get eventsJoinEvent => 'Unisciti all\'Evento';

  @override
  String get eventsJoinLabel => 'Unisciti';

  @override
  String eventsKmAwayFormat(String km) {
    return 'a $km km';
  }

  @override
  String get eventsLanguageExchange => 'Scambio Linguistico';

  @override
  String get eventsLanguagePairs =>
      'Coppie Linguistiche (es., Spagnolo ↔ Inglese)';

  @override
  String eventsLanguages(String languages) {
    return 'Lingue: $languages';
  }

  @override
  String get eventsLocation => 'Luogo';

  @override
  String eventsMAwayFormat(Object meters) {
    return 'a $meters m';
  }

  @override
  String get eventsMaxAttendees => 'Max Partecipanti';

  @override
  String get eventsNoAttendeesYet =>
      'Nessun partecipante ancora. Sii il primo!';

  @override
  String get eventsNoEventsFound => 'Nessun evento trovato';

  @override
  String get eventsNoMessagesYet => 'Nessun messaggio ancora';

  @override
  String get eventsRequired => 'Obbligatorio';

  @override
  String get eventsRsvpCancelled => 'Partecipazione annullata';

  @override
  String get eventsRsvpUpdated => 'Partecipazione aggiornata!';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count posti rimasti';
  }

  @override
  String get eventsStartDateTime => 'Data e Ora di Inizio';

  @override
  String get eventsTabMyEvents => 'I Miei Eventi';

  @override
  String get eventsTabNearby => 'Nelle Vicinanze';

  @override
  String get eventsTabUpcoming => 'In Arrivo';

  @override
  String get eventsThisMonth => 'Questo Mese';

  @override
  String get eventsThisWeekFilter => 'Questa Settimana';

  @override
  String get eventsTitle => 'Eventi';

  @override
  String get eventsToday => 'Oggi';

  @override
  String get eventsTypeAMessage => 'Scrivi un messaggio...';

  @override
  String get exit => 'Esci';

  @override
  String get exitApp => 'Uscire dall\'App?';

  @override
  String get exitAppConfirmation => 'Sei sicuro di voler uscire da GreenGo?';

  @override
  String get exploreLanguages => 'Esplora le Lingue';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km';
  }

  @override
  String get exploreMapError =>
      'Impossibile caricare gli utenti nelle vicinanze';

  @override
  String get exploreMapExpandRadius => 'Espandi il raggio';

  @override
  String get exploreMapExpandRadiusHint =>
      'Prova ad aumentare il raggio di ricerca per trovare più persone.';

  @override
  String get exploreMapNearbyUser => 'Utente vicino';

  @override
  String get exploreMapNoOneNearby => 'Nessuno nelle vicinanze';

  @override
  String get exploreMapOnlineNow => 'Online adesso';

  @override
  String get exploreMapPeopleNearYou => 'Persone vicino a te';

  @override
  String get exploreMapRadius => 'Raggio:';

  @override
  String get exploreMapVisible => 'Visibile';

  @override
  String get exportMyDataGDPR => 'Esporta i Miei Dati (GDPR)';

  @override
  String get exportingYourData => 'Esportazione dati in corso...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Estendi ($cost monete)';
  }

  @override
  String get extendTooltip => 'Estendi';

  @override
  String failedToDownloadModel(String language) {
    return 'Download del modello $language non riuscito';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Impossibile salvare le preferenze';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Funzione non disponibile con $tier';
  }

  @override
  String get fillCategories => 'Compila tutte le categorie';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Diretto';

  @override
  String get filterMessaged => 'Con Messaggi';

  @override
  String get filterNew => 'Nuovi';

  @override
  String get filterNewMessages => 'Nuovi';

  @override
  String get filterNotReplied => 'Senza risposta';

  @override
  String filteredFromTotal(int total) {
    return 'Filtrato da $total';
  }

  @override
  String get filters => 'Filtri';

  @override
  String get finish => 'Termina';

  @override
  String get firstName => 'Nome';

  @override
  String get firstTo30Wins => 'Il primo a 30 vince!';

  @override
  String get flashcardReviewLabel => 'Schede';

  @override
  String get flirtyCategory => 'Civettuolo';

  @override
  String get foodDiningCategory => 'Cibo e Ristorazione';

  @override
  String get forgotPassword => 'Password Dimenticata?';

  @override
  String freeActionsRemaining(int count) {
    return '$count azioni gratuite rimanenti oggi';
  }

  @override
  String get friendship => 'Amicizia';

  @override
  String get gameAbandon => 'Abbandona';

  @override
  String get gameAbandonLoseMessage =>
      'Perderai questa partita se esci adesso.';

  @override
  String get gameAbandonProgressMessage =>
      'Perderai i tuoi progressi e tornerai alla lobby.';

  @override
  String get gameAbandonTitle => 'Abbandonare la partita?';

  @override
  String get gameAbandonTooltip => 'Abbandona partita';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Inserisci una parola che inizia con \"$letter\"...';
  }

  @override
  String get gameCategoriesFilled => 'completato';

  @override
  String get gameCategoriesNewLetter => 'Nuova Lettera!';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — inizia con \"$letter\"';
  }

  @override
  String get gameCategoriesTapToFill => 'Tocca una categoria per compilarla!';

  @override
  String get gameCategoriesTimesUp =>
      'Tempo scaduto! In attesa del prossimo round...';

  @override
  String get gameCategoriesTitle => 'Categorie';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      'Parola già usata in un\'altra categoria!';

  @override
  String get gameCategoryAnimals => 'Animali';

  @override
  String get gameCategoryClothing => 'Abbigliamento';

  @override
  String get gameCategoryColors => 'Colori';

  @override
  String get gameCategoryCountries => 'Paesi';

  @override
  String get gameCategoryFood => 'Cibo';

  @override
  String get gameCategoryNature => 'Natura';

  @override
  String get gameCategoryProfessions => 'Professioni';

  @override
  String get gameCategorySports => 'Sport';

  @override
  String get gameCategoryTransport => 'Trasporti';

  @override
  String get gameChainBreak => 'CATENA SPEZZATA!';

  @override
  String get gameChainNextMustStartWith =>
      'La prossima parola deve iniziare con: ';

  @override
  String get gameChainNoWordsYet => 'Nessuna parola ancora!';

  @override
  String get gameChainStartWithAnyWord =>
      'Inizia la catena con una parola qualsiasi';

  @override
  String get gameChainTitle => 'Catena di Vocaboli';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Scrivi una parola che inizia con \"$letter\"...';
  }

  @override
  String get gameChainTypeToStartHint =>
      'Scrivi una parola per iniziare la catena...';

  @override
  String gameChainWordsChained(int count) {
    return '$count parole concatenate';
  }

  @override
  String get gameCorrect => 'Corretto!';

  @override
  String get gameDefaultPlayerName => 'Giocatore';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff in vantaggio';
  }

  @override
  String get gameGrammarDuelAnswered => 'Ha risposto';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff in svantaggio';
  }

  @override
  String get gameGrammarDuelFast => 'VELOCE!';

  @override
  String get gameGrammarDuelGrammarQuestion => 'DOMANDA DI GRAMMATICA';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '+$points punti!';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return 'x$count serie!';
  }

  @override
  String get gameGrammarDuelThinking => 'Sta pensando...';

  @override
  String get gameGrammarDuelTitle => 'Duello di Grammatica';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => 'Risposta sbagliata!';

  @override
  String get gameInvalidAnswer => 'Non valido!';

  @override
  String get gameLanguageBrazilianPortuguese => 'Portoghese Brasiliano';

  @override
  String get gameLanguageEnglish => 'Inglese';

  @override
  String get gameLanguageFrench => 'Francese';

  @override
  String get gameLanguageGerman => 'Tedesco';

  @override
  String get gameLanguageItalian => 'Italiano';

  @override
  String get gameLanguageJapanese => 'Giapponese';

  @override
  String get gameLanguagePortuguese => 'Portoghese';

  @override
  String get gameLanguageSpanish => 'Spagnolo';

  @override
  String get gameLeave => 'Esci';

  @override
  String get gameOpponent => 'Avversario';

  @override
  String get gameOver => 'Partita Finita';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Tentativo $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      'Non puoi usare la parola stessa nel tuo indizio!';

  @override
  String get gamePictureGuessClues => 'INDIZI';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count indizio/i inviato/i';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return 'Corretto! +$points punti';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      'Corretto! In attesa della fine del round...';

  @override
  String get gamePictureGuessDescriber => 'DESCRITTORE';

  @override
  String get gamePictureGuessDescriberRules =>
      'Dai indizi per aiutare gli altri a indovinare. Niente traduzioni dirette o suggerimenti sull\'ortografia!';

  @override
  String get gamePictureGuessGuessTheWord => 'Indovina la parola!';

  @override
  String get gamePictureGuessGuessTheWordUpper => 'INDOVINA LA PAROLA!';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'Nessun altro tentativo — in attesa della fine del round';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'Nessun altro tentativo per questo round';

  @override
  String get gamePictureGuessTheWordWas => 'La parola era:';

  @override
  String get gamePictureGuessTitle => 'Indovina l\'Immagine';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Scrivi un indizio (niente traduzioni dirette!)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Scrivi la tua risposta... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'In attesa degli indizi...';

  @override
  String get gamePictureGuessWaitingForOthers => 'In attesa degli altri...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Risposta sbagliata: \"$guess\"';
  }

  @override
  String get gamePictureGuessYouAreDescriber => 'Sei il DESCRITTORE!';

  @override
  String get gamePictureGuessYourWord => 'LA TUA PAROLA';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      'Risposta inviata! In attesa degli altri...';

  @override
  String get gamePlayCategoriesHeader => 'CATEGORIE';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Categoria: $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return 'Corretto! +$points punti';
  }

  @override
  String get gamePlayDescribeThisWord => 'DESCRIVI QUESTA PAROLA!';

  @override
  String get gamePlayDescribeWordHint => 'Descrivi la parola (non dirla!)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name sta descrivendo una parola...';
  }

  @override
  String get gamePlayDoNotSayWord => 'Non dire la parola stessa!';

  @override
  String get gamePlayGuessTheWord => 'INDOVINA LA PAROLA';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Sbagliato. La risposta era \"$answer\"';
  }

  @override
  String get gamePlayLeaderboard => 'CLASSIFICA';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Nomina una parola in $language che inizia con \"$letter\"';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Nomina una parola in \"$category\" che inizia con \"$letter\"';
  }

  @override
  String get gamePlayNextWordMustStartWith =>
      'LA PROSSIMA PAROLA DEVE INIZIARE CON';

  @override
  String get gamePlayNoWordsStartChain =>
      'Nessuna parola ancora — inizia la catena!';

  @override
  String get gamePlayPickLetterNameWord =>
      'Scegli una lettera, poi nomina una parola!';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name sta scegliendo...';
  }

  @override
  String gamePlayPlayerIsThinking(String name) {
    return '$name sta pensando...';
  }

  @override
  String gamePlayThemeLabel(String theme) {
    return 'Tema: $theme';
  }

  @override
  String get gamePlayTranslateThisWord => 'TRADUCI QUESTA PAROLA';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Scrivi una parola che contiene \"$prompt\"...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Scrivi una parola che inizia con \"$prompt\"...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Scrivi la traduzione...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      'Scrivi una parola che contiene queste lettere!';

  @override
  String get gamePlayTypeYourAnswerHint => 'Scrivi la tua risposta...';

  @override
  String get gamePlayTypeYourGuessBelow => 'Scrivi la tua risposta qui sotto!';

  @override
  String get gamePlayTypeYourGuessHint => 'Scrivi la tua risposta...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Usa la chat per descrivere la parola agli altri giocatori';

  @override
  String get gamePlayWaitingForOpponent => 'In attesa dell\'avversario...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Parola che inizia con \"$letter\"...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Parola che inizia con \"$prompt\"...';
  }

  @override
  String get gamePlayYourTurnFlipCards => 'Tocca a te — gira due carte!';

  @override
  String gamePlayersTurn(String name) {
    return 'Turno di $name';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points punti';
  }

  @override
  String get gamePositionFirst => '1°';

  @override
  String gamePositionNth(int pos) {
    return '$pos°';
  }

  @override
  String get gamePositionSecond => '2°';

  @override
  String get gamePositionThird => '3°';

  @override
  String get gameResultsBackToLobby => 'Torna alla Lobby';

  @override
  String get gameResultsBaseXp => 'XP Base';

  @override
  String get gameResultsCoinsEarned => 'Monete Guadagnate';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Bonus Difficoltà (Lv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'CLASSIFICA FINALE';

  @override
  String get gameResultsGameOver => 'FINE PARTITA';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'Monete insufficienti ($amount necessarie)';
  }

  @override
  String get gameResultsPlayAgain => 'Gioca Ancora';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'RICOMPENSE OTTENUTE';

  @override
  String get gameResultsTotalXp => 'XP Totale';

  @override
  String get gameResultsVictory => 'VITTORIA!';

  @override
  String get gameResultsWhatYouLearned => 'COSA HAI IMPARATO';

  @override
  String get gameResultsWinner => 'Vincitore';

  @override
  String get gameResultsWinnerBonus => 'Bonus Vincitore';

  @override
  String get gameResultsYouWon => 'Hai vinto!';

  @override
  String gameRoundCounter(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String gameRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String gameScorePts(int score) {
    return '$score punti';
  }

  @override
  String get gameSnapsNoMatch => 'Nessuna corrispondenza';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total coppie trovate';
  }

  @override
  String get gameSnapsTitle => 'Language Snaps';

  @override
  String get gameSnapsYourTurnFlipCards => 'TOCCA A TE — Gira 2 carte!';

  @override
  String get gameSomeone => 'Qualcuno';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Nomina una parola che inizia con \"$letter\"';
  }

  @override
  String get gameTapplesPickLetterFromWheel =>
      'Scegli una lettera dalla ruota!';

  @override
  String get gameTapplesPickLetterNameWord =>
      'Scegli una lettera, nomina una parola';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name ha perso una vita';
  }

  @override
  String get gameTapplesTimeUp => 'TEMPO SCADUTO!';

  @override
  String get gameTapplesTitle => 'Language Tapples';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Parola che inizia con \"$letter\"...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount parole usate  •  $lettersCount lettere rimaste';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Corretto';

  @override
  String get gameTranslationRaceFirstTo30 => 'Il primo a 30 vince!';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'R$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Gara di Traduzione';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Traduci in $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'In attesa degli altri... $answered/$total hanno risposto';
  }

  @override
  String get gameWaitForYourTurn => 'Aspetta il tuo turno...';

  @override
  String get gameWaiting => 'In attesa';

  @override
  String get gameWaitingCancelReady => 'Annulla Pronto';

  @override
  String get gameWaitingCountdownGo => 'VIA!';

  @override
  String get gameWaitingDisconnected => 'Disconnesso';

  @override
  String get gameWaitingEllipsis => 'In attesa...';

  @override
  String get gameWaitingForPlayers => 'In Attesa dei Giocatori...';

  @override
  String get gameWaitingGetReady => 'Preparati...';

  @override
  String get gameWaitingHost => 'OSPITE';

  @override
  String get gameWaitingInviteCodeCopied => 'Codice invito copiato!';

  @override
  String get gameWaitingInviteCodeHeader => 'CODICE INVITO';

  @override
  String get gameWaitingInvitePlayer => 'Invita Giocatore';

  @override
  String get gameWaitingLeaveRoom => 'Esci dalla Stanza';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Livello $level';
  }

  @override
  String get gameWaitingNotReady => 'Non Pronto';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count non pronti)';
  }

  @override
  String get gameWaitingPlayersHeader => 'GIOCATORI';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count giocatori nella stanza';
  }

  @override
  String get gameWaitingReady => 'Pronto';

  @override
  String get gameWaitingReadyUp => 'Pronto';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count round';
  }

  @override
  String get gameWaitingShareCode =>
      'Condividi questo codice con gli amici per unirsi';

  @override
  String get gameWaitingStartGame => 'Inizia Partita';

  @override
  String get gameWordAlreadyUsed => 'Parola già usata!';

  @override
  String get gameWordBombBoom => 'BOOM!';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'La parola deve contenere \"$prompt\"';
  }

  @override
  String get gameWordBombReport => 'Segnala';

  @override
  String get gameWordBombReportContent =>
      'Segnala questa parola come non valida o inappropriata.';

  @override
  String gameWordBombReportTitle(String word) {
    return 'Segnalare \"$word\"?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife =>
      'Tempo scaduto! Hai perso una vita.';

  @override
  String get gameWordBombTitle => 'Bomba di Parole';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Scrivi una parola che contiene \"$prompt\"...';
  }

  @override
  String get gameWordBombUsedWords => 'Parole Usate';

  @override
  String get gameWordBombWordReported => 'Parola segnalata';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count parole usate';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'La parola deve iniziare con \"$letter\"';
  }

  @override
  String get gameWrong => 'Sbagliato';

  @override
  String get gameYou => 'Tu';

  @override
  String get gameYourTurn => 'TOCCA A TE!';

  @override
  String get gamificationAchievements => 'Traguardi';

  @override
  String get gamificationAll => 'Tutti';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '$name completata!';
  }

  @override
  String get gamificationClaim => 'Riscuoti';

  @override
  String get gamificationClaimReward => 'Riscuoti ricompensa';

  @override
  String get gamificationCoinsAvailable => 'Monete disponibili';

  @override
  String get gamificationDaily => 'Giornaliero';

  @override
  String get gamificationDailyChallenges => 'Sfide giornaliere';

  @override
  String get gamificationDayStreak => 'Giorni consecutivi';

  @override
  String get gamificationDone => 'Fatto';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Ottenuto il $date';
  }

  @override
  String get gamificationEasy => 'Facile';

  @override
  String get gamificationEngagement => 'Engagement';

  @override
  String get gamificationEpic => 'Epico';

  @override
  String get gamificationExperiencePoints => 'Punti esperienza';

  @override
  String get gamificationGlobal => 'Globale';

  @override
  String get gamificationHard => 'Difficile';

  @override
  String get gamificationLeaderboard => 'Classifica';

  @override
  String gamificationLevel(Object level) {
    return 'Livello $level';
  }

  @override
  String get gamificationLevelLabel => 'LIVELLO';

  @override
  String gamificationLevelShort(Object level) {
    return 'Lv.$level';
  }

  @override
  String get gamificationLoadingAchievements => 'Caricamento traguardi...';

  @override
  String get gamificationLoadingChallenges => 'Caricamento sfide...';

  @override
  String get gamificationLoadingRankings => 'Caricamento classifica...';

  @override
  String get gamificationMedium => 'Medio';

  @override
  String get gamificationMilestones => 'Traguardi';

  @override
  String get gamificationMyProgress => 'I miei progressi';

  @override
  String get gamificationNoAchievements => 'Nessun traguardo trovato';

  @override
  String get gamificationNoAchievementsInCategory =>
      'Nessun traguardo in questa categoria';

  @override
  String get gamificationNoChallenges => 'Nessuna sfida disponibile';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'Nessuna sfida $type disponibile';
  }

  @override
  String get gamificationNoLeaderboard => 'Nessun dato di classifica';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Membro Premium';

  @override
  String get gamificationProgress => 'Progressi';

  @override
  String get gamificationRank => 'RANGO';

  @override
  String get gamificationRankLabel => 'Rango';

  @override
  String get gamificationRegional => 'Regionale';

  @override
  String gamificationReward(Object amount, Object type) {
    return 'Ricompensa: $amount $type';
  }

  @override
  String get gamificationSocial => 'Social';

  @override
  String get gamificationSpecial => 'Speciale';

  @override
  String get gamificationTotal => 'Totale';

  @override
  String get gamificationUnlocked => 'Sbloccato';

  @override
  String get gamificationVerifiedUser => 'Utente verificato';

  @override
  String get gamificationVipMember => 'Membro VIP';

  @override
  String get gamificationWeekly => 'Settimanale';

  @override
  String get gamificationXpAvailable => 'XP disponibili';

  @override
  String get gamificationYourPosition => 'La tua posizione';

  @override
  String get gender => 'Genere';

  @override
  String get getStarted => 'Inizia';

  @override
  String get giftCategoryAll => 'Tutti';

  @override
  String giftFromSender(Object name) {
    return 'Da $name';
  }

  @override
  String get giftGetCoins => 'Ottieni monete';

  @override
  String get giftNoGiftsAvailable => 'Nessun regalo disponibile';

  @override
  String get giftNoGiftsInCategory => 'Nessun regalo in questa categoria';

  @override
  String get giftNoGiftsYet => 'Ancora nessun regalo';

  @override
  String get giftNotEnoughCoins => 'Monete insufficienti';

  @override
  String giftPriceCoins(Object price) {
    return '$price monete';
  }

  @override
  String get giftReceivedGifts => 'Regali ricevuti';

  @override
  String get giftReceivedGiftsEmpty => 'I regali che ricevi appariranno qui';

  @override
  String get giftSendGift => 'Invia regalo';

  @override
  String giftSendGiftTo(Object name) {
    return 'Invia regalo a $name';
  }

  @override
  String get giftSending => 'Invio...';

  @override
  String giftSentTo(Object name) {
    return 'Regalo inviato a $name!';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'Hai $available monete.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'Hai bisogno di $required monete per questo regalo.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'Ti servono altre $shortfall monete.';
  }

  @override
  String get gold => 'Oro';

  @override
  String get grantAlbumAccess => 'Condividi il mio album';

  @override
  String get greatInterestsHelp =>
      'Ottimo! I tuoi interessi ci aiutano a trovare match migliori';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Saluti';

  @override
  String get guideBadge => 'Guida';

  @override
  String get height => 'Altezza';

  @override
  String get helpAndSupport => 'Aiuto e Supporto';

  @override
  String get helpOthersFindYou => 'Aiuta gli altri a trovarti sui social media';

  @override
  String get hours => 'Ore';

  @override
  String get icebreakersCategoryCompliments => 'Complimenti';

  @override
  String get icebreakersCategoryDateIdeas => 'Idee per appuntamenti';

  @override
  String get icebreakersCategoryDeep => 'Profondi';

  @override
  String get icebreakersCategoryDreams => 'Sogni';

  @override
  String get icebreakersCategoryFood => 'Cucina';

  @override
  String get icebreakersCategoryFunny => 'Divertenti';

  @override
  String get icebreakersCategoryHobbies => 'Hobby';

  @override
  String get icebreakersCategoryHypothetical => 'Ipotetici';

  @override
  String get icebreakersCategoryMovies => 'Film';

  @override
  String get icebreakersCategoryMusic => 'Musica';

  @override
  String get icebreakersCategoryPersonality => 'Personalità';

  @override
  String get icebreakersCategoryTravel => 'Viaggi';

  @override
  String get icebreakersCategoryTwoTruths => 'Due verità';

  @override
  String get icebreakersCategoryWouldYouRather => 'Preferiresti';

  @override
  String get icebreakersLabel => 'Rompighiaccio';

  @override
  String get icebreakersNoneInCategory =>
      'Nessun rompighiaccio in questa categoria';

  @override
  String get icebreakersQuickAnswers => 'Risposte rapide:';

  @override
  String get icebreakersSendAnIcebreaker => 'Invia un rompighiaccio';

  @override
  String icebreakersSendTo(Object name) {
    return 'Invia a $name';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Invia senza risposta';

  @override
  String get icebreakersTitle => 'Rompighiaccio';

  @override
  String get idiomsCategory => 'Modi di Dire';

  @override
  String get incognitoMode => 'Modalità Incognito';

  @override
  String get incognitoModeDescription =>
      'Nascondi il tuo profilo dalla scoperta';

  @override
  String get incorrectAnswer => 'Sbagliato';

  @override
  String get infoUpdatedMessage =>
      'Le tue informazioni di base sono state salvate';

  @override
  String get infoUpdatedTitle => 'Informazioni Aggiornate!';

  @override
  String get insufficientCoins => 'Monete insufficienti';

  @override
  String get insufficientCoinsTitle => 'Monete Insufficienti';

  @override
  String get interestArt => 'Arte';

  @override
  String get interestBeach => 'Spiaggia';

  @override
  String get interestBeer => 'Birra';

  @override
  String get interestBusiness => 'Business';

  @override
  String get interestCamping => 'Campeggio';

  @override
  String get interestCats => 'Gatti';

  @override
  String get interestCoffee => 'Caffè';

  @override
  String get interestCooking => 'Cucina';

  @override
  String get interestCycling => 'Ciclismo';

  @override
  String get interestDance => 'Danza';

  @override
  String get interestDancing => 'Ballo';

  @override
  String get interestDogs => 'Cani';

  @override
  String get interestEntrepreneurship => 'Imprenditoria';

  @override
  String get interestEnvironment => 'Ambiente';

  @override
  String get interestFashion => 'Moda';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Cibo';

  @override
  String get interestGaming => 'Videogiochi';

  @override
  String get interestHiking => 'Escursionismo';

  @override
  String get interestHistory => 'Storia';

  @override
  String get interestInvesting => 'Investimenti';

  @override
  String get interestLanguages => 'Lingue';

  @override
  String get interestMeditation => 'Meditazione';

  @override
  String get interestMountains => 'Montagne';

  @override
  String get interestMovies => 'Film';

  @override
  String get interestMusic => 'Musica';

  @override
  String get interestNature => 'Natura';

  @override
  String get interestPets => 'Animali domestici';

  @override
  String get interestPhotography => 'Fotografia';

  @override
  String get interestPoetry => 'Poesia';

  @override
  String get interestPolitics => 'Politica';

  @override
  String get interestReading => 'Lettura';

  @override
  String get interestRunning => 'Corsa';

  @override
  String get interestScience => 'Scienza';

  @override
  String get interestSkiing => 'Sci';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestSpirituality => 'Spiritualità';

  @override
  String get interestSports => 'Sport';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSwimming => 'Nuoto';

  @override
  String get interestTeaching => 'Insegnamento';

  @override
  String get interestTechnology => 'Tecnologia';

  @override
  String get interestTravel => 'Viaggi';

  @override
  String get interestVegan => 'Vegano';

  @override
  String get interestVegetarian => 'Vegetariano';

  @override
  String get interestVolunteering => 'Volontariato';

  @override
  String get interestWine => 'Vino';

  @override
  String get interestWriting => 'Scrittura';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Interessi';

  @override
  String interestsCount(int count) {
    return '$count interessi';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max interessi selezionati';
  }

  @override
  String get interestsUpdatedMessage => 'I tuoi interessi sono stati salvati';

  @override
  String get interestsUpdatedTitle => 'Interessi Aggiornati!';

  @override
  String get invalidWord => 'Parola non valida';

  @override
  String get inviteCodeCopied => 'Codice invito copiato!';

  @override
  String get inviteFriends => 'Invita Amici';

  @override
  String get itsAMatch => 'Scambiamoci!';

  @override
  String get joinMessage =>
      'Unisciti a GreenGoChat e trova il tuo partner perfetto';

  @override
  String get keepSwiping => 'Continua a Scorrere';

  @override
  String get langMatchBadge => 'Lingua Compatibile';

  @override
  String get language => 'Lingua';

  @override
  String languageChangedTo(String language) {
    return 'Lingua cambiata in $language';
  }

  @override
  String get languagePacksBtn => 'Pacchetti Lingue';

  @override
  String get languagePacksShopTitle => 'Negozio Pacchetti Lingue';

  @override
  String get languagesToDownloadLabel => 'Lingue da scaricare:';

  @override
  String get lastName => 'Cognome';

  @override
  String get lastUpdated => 'Ultimo aggiornamento';

  @override
  String get leaderboardTitle => 'Classifica';

  @override
  String get learn => 'Impara';

  @override
  String get learningAccuracy => 'Precisione';

  @override
  String get learningActiveThisWeek => 'Attivo questa settimana';

  @override
  String get learningAddLessonSection => 'Aggiungi sezione lezione';

  @override
  String get learningAiConversationCoach => 'Coach di conversazione AI';

  @override
  String get learningAllCategories => 'Tutte le categorie';

  @override
  String get learningAllLessons => 'Tutte le lezioni';

  @override
  String get learningAllLevels => 'Tutti i livelli';

  @override
  String get learningAmount => 'Importo';

  @override
  String get learningAmountLabel => 'Importo';

  @override
  String get learningAnalytics => 'Analisi';

  @override
  String learningAnswer(Object answer) {
    return 'Risposta: $answer';
  }

  @override
  String get learningApplyFilters => 'Applica filtri';

  @override
  String get learningAreasToImprove => 'Aree da migliorare';

  @override
  String get learningAvailableBalance => 'Saldo disponibile';

  @override
  String get learningAverageRating => 'Valutazione media';

  @override
  String get learningBeginnerProgress => 'Progresso principiante';

  @override
  String get learningBonusCoins => 'Monete bonus';

  @override
  String get learningCategory => 'Categoria';

  @override
  String get learningCategoryProgress => 'Progresso per categoria';

  @override
  String get learningCheck => 'Verifica';

  @override
  String get learningCheckBackSoon => 'Torna presto!';

  @override
  String get learningCoachSessionCost =>
      '10 monete/sessione  |  25 XP di ricompensa';

  @override
  String get learningContinue => 'Continua';

  @override
  String get learningCorrect => 'Corretto!';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Corretto: $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'La risposta corretta: $answer';
  }

  @override
  String get learningCorrectAnswers => 'Risposte corrette';

  @override
  String get learningCorrectLabel => 'Corretto';

  @override
  String get learningCorrections => 'Correzioni';

  @override
  String get learningCreateLesson => 'Crea lezione';

  @override
  String get learningCreateNewLesson => 'Crea nuova lezione';

  @override
  String get learningCustomPackTitleHint =>
      'es. \"Saluti in Spagnolo per Appuntamenti\"';

  @override
  String get learningDescribeImage => 'Descrivi questa immagine';

  @override
  String get learningDescriptionHint => 'Cosa impareranno gli studenti?';

  @override
  String get learningDescriptionLabel => 'Descrizione';

  @override
  String get learningDifficultyLevel => 'Livello di difficoltà';

  @override
  String get learningDone => 'Fatto';

  @override
  String get learningDraftSave => 'Salva bozza';

  @override
  String get learningDraftSaved => 'Bozza salvata!';

  @override
  String get learningEarned => 'Guadagnato';

  @override
  String get learningEdit => 'Modifica';

  @override
  String get learningEndSession => 'Termina sessione';

  @override
  String get learningEndSessionBody =>
      'Il progresso attuale andrà perso. Vuoi terminare la sessione e vedere il tuo punteggio prima?';

  @override
  String get learningEndSessionQuestion => 'Terminare la sessione?';

  @override
  String get learningExit => 'Esci';

  @override
  String get learningFalse => 'Falso';

  @override
  String get learningFilterAll => 'Tutti';

  @override
  String get learningFilterDraft => 'Bozza';

  @override
  String get learningFilterLessons => 'Filtra lezioni';

  @override
  String get learningFilterPublished => 'Pubblicato';

  @override
  String get learningFilterUnderReview => 'In revisione';

  @override
  String get learningFluency => 'Fluidità';

  @override
  String get learningFree => 'GRATIS';

  @override
  String get learningGoBack => 'Torna Indietro';

  @override
  String get learningGoalCompleteLessons => 'Completa 5 lezioni';

  @override
  String get learningGoalEarnXp => 'Guadagna 500 XP';

  @override
  String get learningGoalPracticeMinutes => 'Esercitati 30 minuti';

  @override
  String get learningGrammar => 'Grammatica';

  @override
  String get learningHint => 'Suggerimento';

  @override
  String get learningLangBrazilianPortuguese => 'Portoghese brasiliano';

  @override
  String get learningLangEnglish => 'Inglese';

  @override
  String get learningLangFrench => 'Francese';

  @override
  String get learningLangGerman => 'Tedesco';

  @override
  String get learningLangItalian => 'Italiano';

  @override
  String get learningLangPortuguese => 'Portoghese';

  @override
  String get learningLangSpanish => 'Spagnolo';

  @override
  String get learningLanguagesSubtitle =>
      'Seleziona fino a 5 lingue. Questo ci aiuta a metterti in contatto con madrelingua e partner di apprendimento.';

  @override
  String get learningLanguagesTitle => 'Quali lingue vuoi imparare?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Lingue da imparare ($count/5)';
  }

  @override
  String get learningLastMonth => 'Il mese scorso';

  @override
  String learningLearnLanguage(Object language) {
    return 'Impara $language';
  }

  @override
  String get learningLearned => 'Imparato';

  @override
  String get learningLessonComplete => 'Lezione completata!';

  @override
  String get learningLessonCompleteUpper => 'LEZIONE COMPLETATA!';

  @override
  String get learningLessonContent => 'Contenuto della lezione';

  @override
  String learningLessonNumber(Object number) {
    return 'Lezione $number';
  }

  @override
  String get learningLessonSubmitted => 'Lezione inviata per la revisione!';

  @override
  String get learningLessonTitle => 'Titolo della lezione';

  @override
  String get learningLessonTitleHint =>
      'es. \"Saluti spagnoli per gli appuntamenti\"';

  @override
  String get learningLessonTitleLabel => 'Titolo della Lezione';

  @override
  String get learningLessonsLabel => 'Lezioni';

  @override
  String get learningLetsStart => 'Iniziamo!';

  @override
  String get learningLevel => 'Livello';

  @override
  String learningLevelBadge(Object level) {
    return 'LV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Livello $level';
  }

  @override
  String get learningListen => 'Ascolta';

  @override
  String get learningListening => 'In ascolto...';

  @override
  String get learningLongPressForTranslation =>
      'Pressione prolungata per la traduzione';

  @override
  String get learningMessages => 'Messaggi';

  @override
  String get learningMessagesSent => 'Messaggi inviati';

  @override
  String get learningMinimumWithdrawal => 'Prelievo minimo: 50,00 \$';

  @override
  String get learningMonthlyEarnings => 'Guadagni mensili';

  @override
  String get learningMyProgress => 'I miei progressi';

  @override
  String get learningNativeLabel => '(madrelingua)';

  @override
  String get learningNativeLanguage => 'La tua lingua madre';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'Devi raggiungere almeno il $threshold% per superare questa lezione.';
  }

  @override
  String get learningNext => 'Avanti';

  @override
  String get learningNoExercisesInSection =>
      'Nessun esercizio in questa sezione';

  @override
  String get learningNoLessonsAvailable =>
      'Nessuna lezione disponibile al momento';

  @override
  String get learningNoPacksFound => 'Nessun pacchetto trovato';

  @override
  String get learningNoQuestionsAvailable =>
      'Nessuna domanda disponibile al momento.';

  @override
  String get learningNotQuite => 'Non proprio';

  @override
  String get learningNotQuiteTitle => 'Quasi...';

  @override
  String get learningOpenAiCoach => 'Apri coach AI';

  @override
  String learningPackFilter(Object category) {
    return 'Pacchetto: $category';
  }

  @override
  String get learningPackPurchased => 'Pacchetto acquistato con successo!';

  @override
  String get learningPassageRevealed => 'Passaggio (rivelato)';

  @override
  String get learningPathTitle => 'Percorso di Apprendimento';

  @override
  String get learningPlaying => 'Riproduzione...';

  @override
  String get learningPleaseEnterDescription => 'Inserisci una descrizione';

  @override
  String get learningPleaseEnterTitle => 'Inserisci un titolo';

  @override
  String get learningPracticeAgain => 'Esercitati di nuovo';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Lezioni pubblicate';

  @override
  String get learningPurchased => 'Acquistato';

  @override
  String get learningPurchasedLessonsEmpty =>
      'Le lezioni acquistate appariranno qui';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count domande in questa lezione';
  }

  @override
  String get learningQuickActions => 'Azioni rapide';

  @override
  String get learningReadPassage => 'Leggi il passaggio';

  @override
  String get learningRecentActivity => 'Attività recente';

  @override
  String get learningRecentMilestones => 'Traguardi recenti';

  @override
  String get learningRecentTransactions => 'Transazioni recenti';

  @override
  String get learningRequired => 'Obbligatorio';

  @override
  String get learningResponseRecorded => 'Risposta registrata';

  @override
  String get learningReview => 'Revisione';

  @override
  String get learningSearchLanguages => 'Cerca lingue...';

  @override
  String get learningSectionEditorComingSoon => 'Editor di sezione in arrivo!';

  @override
  String get learningSeeScore => 'Vedi punteggio';

  @override
  String get learningSelectNativeLanguage => 'Seleziona la tua lingua madre';

  @override
  String get learningSelectScenario => 'Seleziona uno scenario per iniziare';

  @override
  String get learningSelectScenarioFirst => 'Seleziona prima uno scenario...';

  @override
  String get learningSessionComplete => 'Sessione completata!';

  @override
  String get learningSessionSummary => 'Riepilogo sessione';

  @override
  String get learningShowAll => 'Mostra tutto';

  @override
  String get learningShowPassageText => 'Mostra testo del passaggio';

  @override
  String get learningSkip => 'Salta';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return 'Spendi $price monete per sbloccare questa lezione?';
  }

  @override
  String get learningStartFlashcards => 'Inizia flashcard';

  @override
  String get learningStartLesson => 'Inizia lezione';

  @override
  String get learningStartPractice => 'Inizia esercizio';

  @override
  String get learningStartQuiz => 'Inizia quiz';

  @override
  String get learningStartingLesson => 'Avvio lezione...';

  @override
  String get learningStop => 'Ferma';

  @override
  String get learningStreak => 'Serie';

  @override
  String get learningStrengths => 'Punti di forza';

  @override
  String get learningSubmit => 'Invia';

  @override
  String get learningSubmitForReview => 'Invia per revisione';

  @override
  String get learningSubmitForReviewBody =>
      'La tua lezione sarà esaminata dal nostro team prima della pubblicazione. Questo richiede generalmente 24-48 ore.';

  @override
  String get learningSubmitForReviewQuestion => 'Inviare per la revisione?';

  @override
  String get learningTabAllLessons => 'Tutte le Lezioni';

  @override
  String get learningTabEarnings => 'Guadagni';

  @override
  String get learningTabFlashcards => 'Flashcard';

  @override
  String get learningTabLessons => 'Lezioni';

  @override
  String get learningTabMyLessons => 'Le mie lezioni';

  @override
  String get learningTabMyProgress => 'I Miei Progressi';

  @override
  String get learningTabOverview => 'Panoramica';

  @override
  String get learningTabPhrases => 'Frasi';

  @override
  String get learningTabProgress => 'Progressi';

  @override
  String get learningTabPurchased => 'Acquistati';

  @override
  String get learningTabQuizzes => 'Quiz';

  @override
  String get learningTabStudents => 'Studenti';

  @override
  String get learningTapToContinue => 'Tocca per continuare';

  @override
  String get learningTapToHearPassage => 'Tocca per ascoltare il passaggio';

  @override
  String get learningTapToListen => 'Tocca per ascoltare';

  @override
  String get learningTapToMatch => 'Tocca gli elementi per abbinarli';

  @override
  String get learningTapToRevealTranslation =>
      'Tocca per rivelare la traduzione';

  @override
  String get learningTapWordsToBuild =>
      'Tocca le parole qui sotto per costruire la frase';

  @override
  String get learningTargetLanguage => 'Lingua obiettivo';

  @override
  String get learningTeacherDashboardTitle => 'Pannello insegnante';

  @override
  String get learningTeacherTiers => 'Livelli insegnante';

  @override
  String get learningThisMonth => 'Questo mese';

  @override
  String get learningTopPerformingStudents => 'Studenti migliori';

  @override
  String get learningTotalStudents => 'Studenti totali';

  @override
  String get learningTotalStudentsLabel => 'Studenti totali';

  @override
  String get learningTotalXp => 'XP totali';

  @override
  String get learningTranslatePhrase => 'Traduci questa frase';

  @override
  String get learningTrue => 'Vero';

  @override
  String get learningTryAgain => 'Riprova';

  @override
  String get learningTypeAnswerBelow => 'Scrivi la tua risposta qui sotto';

  @override
  String get learningTypeAnswerHint => 'Scrivi la tua risposta...';

  @override
  String get learningTypeDescriptionHint => 'Scrivi la tua descrizione...';

  @override
  String get learningTypeMessageHint => 'Scrivi il tuo messaggio...';

  @override
  String get learningTypeMissingWordHint => 'Scrivi la parola mancante...';

  @override
  String get learningTypeSentenceHint => 'Scrivi la frase...';

  @override
  String get learningTypeTranslationHint => 'Scrivi la tua traduzione...';

  @override
  String get learningTypeWhatYouHeardHint => 'Scrivi ciò che hai sentito...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Unità $unit - Lezione $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Unità $number';
  }

  @override
  String get learningUnlock => 'Sblocca';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Sblocca per $price monete';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Sblocca per $price monete';
  }

  @override
  String get learningUnlockLesson => 'Sblocca lezione';

  @override
  String get learningViewAll => 'Vedi tutto';

  @override
  String get learningViewAnalytics => 'Vedi analisi';

  @override
  String get learningVocabulary => 'Vocabolario';

  @override
  String learningWeek(Object week) {
    return 'Settimana $week';
  }

  @override
  String get learningWeeklyGoals => 'Obiettivi settimanali';

  @override
  String get learningWhatWillStudentsLearnHint =>
      'Cosa impareranno gli studenti?';

  @override
  String get learningWhatYouWillLearn => 'Cosa imparerai';

  @override
  String get learningWithdraw => 'Preleva';

  @override
  String get learningWithdrawFunds => 'Preleva fondi';

  @override
  String get learningWithdrawalSubmitted => 'Richiesta di prelievo inviata!';

  @override
  String get learningWordsAndPhrases => 'Parole e frasi';

  @override
  String get learningWriteAnswerFreely => 'Scrivi la tua risposta liberamente';

  @override
  String get learningWriteAnswerHint => 'Scrivi la tua risposta...';

  @override
  String get learningXpEarned => 'XP guadagnati';

  @override
  String learningYourAnswer(Object answer) {
    return 'La tua risposta: $answer';
  }

  @override
  String get learningYourScore => 'Il tuo punteggio';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Lezione';

  @override
  String get letsChat => 'Chattiamo!';

  @override
  String get letsExchange => 'Scambiamoci!';

  @override
  String get levelLabel => 'Livello';

  @override
  String levelLabelN(String level) {
    return 'Livello $level';
  }

  @override
  String get levelTitleEnthusiast => 'Entusiasta';

  @override
  String get levelTitleExpert => 'Esperto';

  @override
  String get levelTitleExplorer => 'Esploratore';

  @override
  String get levelTitleLegend => 'Leggenda';

  @override
  String get levelTitleMaster => 'Maestro';

  @override
  String get levelTitleNewcomer => 'Novizio';

  @override
  String get levelTitleVeteran => 'Veterano';

  @override
  String get levelUp => 'LIVELLO SU!';

  @override
  String get levelUpCongratulations =>
      'Congratulazioni per aver raggiunto un nuovo livello!';

  @override
  String get levelUpContinue => 'Continua';

  @override
  String get levelUpRewards => 'RICOMPENSE';

  @override
  String get levelUpTitle => 'LIVELLO SUPERIORE!';

  @override
  String get levelUpVIPUnlocked => 'Status VIP Sbloccato!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Hai raggiunto il Livello $level';
  }

  @override
  String get likes => 'Mi Piace';

  @override
  String get limitReachedTitle => 'Limite Raggiunto';

  @override
  String get listenMe => 'Ascoltami!';

  @override
  String get loading => 'Caricamento...';

  @override
  String get loadingLabel => 'Caricamento...';

  @override
  String get localGuideBadge => 'Guida Locale';

  @override
  String get location => 'Posizione';

  @override
  String get locationAndLanguages => 'Posizione e Lingue';

  @override
  String get locationError => 'Errore di posizione';

  @override
  String get locationNotFound => 'Posizione non trovata';

  @override
  String get locationNotFoundMessage =>
      'Non siamo riusciti a determinare il tuo indirizzo. Riprova o imposta la tua posizione manualmente in seguito.';

  @override
  String get locationPermissionDenied => 'Permesso negato';

  @override
  String get locationPermissionDeniedMessage =>
      'Il permesso di localizzazione è necessario per rilevare la tua posizione attuale. Concedi il permesso per continuare.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permesso negato permanentemente';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'Il permesso di localizzazione è stato negato permanentemente. Abilitalo nelle impostazioni del dispositivo per utilizzare questa funzionalità.';

  @override
  String get locationRequestTimeout => 'Timeout della richiesta';

  @override
  String get locationRequestTimeoutMessage =>
      'Il rilevamento della tua posizione ha richiesto troppo tempo. Controlla la connessione e riprova.';

  @override
  String get locationServicesDisabled =>
      'Servizi di localizzazione disabilitati';

  @override
  String get locationServicesDisabledMessage =>
      'Abilita i servizi di localizzazione nelle impostazioni del dispositivo per utilizzare questa funzionalità.';

  @override
  String get locationUnavailable =>
      'Impossibile ottenere la tua posizione al momento. Puoi impostarla manualmente in seguito nelle impostazioni.';

  @override
  String get locationUnavailableTitle => 'Posizione non disponibile';

  @override
  String get locationUpdatedMessage =>
      'Le impostazioni della tua posizione sono state salvate';

  @override
  String get locationUpdatedTitle => 'Posizione Aggiornata!';

  @override
  String get logOut => 'Esci';

  @override
  String get logOutConfirmation => 'Sei sicuro di voler uscire?';

  @override
  String get login => 'Accedi';

  @override
  String get loginWithBiometrics => 'Accedi con Biometria';

  @override
  String get logout => 'Disconnetti';

  @override
  String get longTermRelationship => 'Relazione a lungo termine';

  @override
  String get lookingFor => 'Cerca';

  @override
  String get lvl => 'LIV';

  @override
  String get manageCouponsTiersRules => 'Gestisci coupon, livelli e regole';

  @override
  String get matchDetailsTitle => 'Dettagli Match';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Tu e $name volete scambiare le lingue!';
  }

  @override
  String get matchNotifKeepSwiping => 'Continua a Swipare';

  @override
  String get matchNotifLetsChat => 'Chattiamo!';

  @override
  String get matchNotifLetsExchange => 'SCAMBIAMOCI!';

  @override
  String get matchNotifViewProfile => 'Vedi Profilo';

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilità';
  }

  @override
  String matchedOnDate(String date) {
    return 'Match il $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Hai fatto match con $name il $date';
  }

  @override
  String get matches => 'Match';

  @override
  String get matchesClearFilters => 'Cancella Filtri';

  @override
  String matchesCount(int count) {
    return '$count match';
  }

  @override
  String get matchesFilterAll => 'Tutti';

  @override
  String get matchesFilterMessaged => 'Con Messaggi';

  @override
  String get matchesFilterNew => 'Nuovi';

  @override
  String get matchesNoMatchesFound => 'Nessun match trovato';

  @override
  String get matchesNoMatchesYet => 'Nessun match ancora';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered di $total match';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered di $total match';
  }

  @override
  String get matchesStartSwiping =>
      'Inizia a swipare per trovare i tuoi match!';

  @override
  String get matchesTryDifferent => 'Prova una ricerca o un filtro diverso';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Massimo $count interessi consentiti';
  }

  @override
  String get maybeLater => 'Forse Più Tardi';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return 'Abbonamento $tierName attivo fino al $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => 'Abbonamento Attivato!';

  @override
  String get membershipAdvancedFilters => 'Filtri avanzati';

  @override
  String get membershipBase => 'Base';

  @override
  String get membershipBaseMembership => 'Abbonamento base';

  @override
  String get membershipBestValue =>
      'Miglior rapporto qualità-prezzo per un impegno a lungo termine!';

  @override
  String get membershipBoostsMonth => 'Boost/mese';

  @override
  String get membershipBuyTitle => 'Acquista abbonamento';

  @override
  String get membershipCouponCodeLabel => 'Codice Coupon *';

  @override
  String get membershipCouponHint => 'es. GOLD2024';

  @override
  String get membershipCurrent => 'Abbonamento attuale';

  @override
  String get membershipDailyLikes => 'Like giornalieri';

  @override
  String get membershipDailyMessagesLabel =>
      'Messaggi Giornalieri (vuoto = illimitati)';

  @override
  String get membershipDailySwipesLabel =>
      'Swipe Giornalieri (vuoto = illimitati)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days giorni rimanenti';
  }

  @override
  String get membershipDurationLabel => 'Durata (giorni)';

  @override
  String get membershipEnterCouponHint => 'Inserisci codice coupon';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Equivalente a $price/mese';
  }

  @override
  String get membershipErrorLoadingData => 'Errore nel caricamento dei dati';

  @override
  String membershipExpires(Object date) {
    return 'Scade il: $date';
  }

  @override
  String get membershipExtendTitle => 'Estendi il tuo abbonamento';

  @override
  String get membershipFeatureComparison => 'Confronto funzionalità';

  @override
  String get membershipGeneric => 'Abbonamento';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Base';

  @override
  String get membershipIncognitoMode => 'Modalità incognito';

  @override
  String get membershipLeaveEmptyLifetime =>
      'Lascia vuoto per durata illimitata';

  @override
  String get membershipLeaveEmptyUnlimited => 'Lascia vuoto per illimitati';

  @override
  String get membershipLowerThanCurrent => 'Inferiore al tuo livello attuale';

  @override
  String get membershipMaxUsesLabel => 'Utilizzi Massimi';

  @override
  String get membershipMonthly => 'Abbonamenti mensili';

  @override
  String get membershipNameDescriptionLabel => 'Nome/Descrizione';

  @override
  String get membershipNoActive => 'Nessun abbonamento attivo';

  @override
  String get membershipNotesLabel => 'Note';

  @override
  String get membershipOneMonth => '1 mese';

  @override
  String get membershipOneYear => '1 anno';

  @override
  String get membershipPanel => 'Pannello Abbonamenti';

  @override
  String get membershipPermanent => 'Permanente';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 MONETE';

  @override
  String get membershipPrioritySupport => 'Assistenza prioritaria';

  @override
  String get membershipReadReceipts => 'Conferme di lettura';

  @override
  String get membershipRequired => 'Iscrizione richiesta';

  @override
  String get membershipRequiredDescription =>
      'Devi essere un membro di GreenGo per eseguire questa azione.';

  @override
  String get membershipRewinds => 'Ripristini';

  @override
  String membershipSavePercent(Object percent) {
    return 'RISPARMIA $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Vedi chi ti ha messo like';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Acquista una volta, goditi le funzionalità premium per 1 mese o 1 anno';

  @override
  String get membershipSuperLikes => 'Super Like';

  @override
  String get membershipSuperLikesLabel =>
      'Super Like/Giorno (vuoto = illimitati)';

  @override
  String get membershipTerms =>
      'Acquisto singolo. L\'abbonamento verrà esteso dalla data di scadenza attuale.';

  @override
  String get membershipTermsExtended =>
      'Acquisto singolo. L\'abbonamento verrà esteso dalla data di scadenza attuale. Gli acquisti di livello superiore sostituiscono i livelli inferiori.';

  @override
  String get membershipTierLabel => 'Livello Abbonamento *';

  @override
  String membershipTierName(Object tierName) {
    return 'Abbonamento $tierName';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Abbonamenti annuali (Risparmia fino al $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'Hai $tierName';
  }

  @override
  String get messages => 'Messaggi';

  @override
  String get minutes => 'Minuti';

  @override
  String moreAchievements(int count) {
    return '+$count altri traguardi';
  }

  @override
  String get myBadges => 'I Miei Badge';

  @override
  String get myProgress => 'I Miei Progressi';

  @override
  String get myUsage => 'Il Mio Utilizzo';

  @override
  String get navLearn => 'Impara';

  @override
  String get navPlay => 'Gioca';

  @override
  String get nearby => 'Nelle vicinanze';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Hai bisogno di $amount monete per sbloccare altri profili.';
  }

  @override
  String get newLabel => 'NUOVO';

  @override
  String get next => 'Avanti';

  @override
  String nextLevelXp(String xp) {
    return 'Prossimo livello tra $xp XP';
  }

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameAlreadyTaken => 'Questo nickname è già in uso';

  @override
  String get nicknameCheckError => 'Errore nel controllo disponibilità';

  @override
  String nicknameInfoText(String nickname) {
    return 'Il tuo nickname è unico e può essere usato per trovarti. Altri possono cercarti usando @$nickname';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Deve essere di 3-20 caratteri';

  @override
  String get nicknameNoConsecutiveUnderscores =>
      'Nessun underscore consecutivo';

  @override
  String get nicknameNoReservedWords => 'Non può contenere parole riservate';

  @override
  String get nicknameOnlyAlphanumeric => 'Solo lettere, numeri e underscore';

  @override
  String get nicknameRequirements =>
      '3-20 caratteri. Solo lettere, numeri e underscore.';

  @override
  String get nicknameRules => 'Regole Nickname';

  @override
  String get nicknameSearchChat => 'Chatta';

  @override
  String get nicknameSearchError => 'Errore nella ricerca. Riprova.';

  @override
  String get nicknameSearchHelp => 'Inserisci un nickname per trovare qualcuno';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'Nessun profilo trovato con @$nickname';
  }

  @override
  String get nicknameSearchOwnProfile => 'Quello e il tuo profilo!';

  @override
  String get nicknameSearchTitle => 'Cerca per Nickname';

  @override
  String get nicknameSearchView => 'Vedi';

  @override
  String get nicknameStartWithLetter => 'Inizia con una lettera';

  @override
  String get nicknameUpdatedMessage => 'Il tuo nuovo nickname è ora attivo';

  @override
  String get nicknameUpdatedSuccess => 'Nickname aggiornato con successo';

  @override
  String get nicknameUpdatedTitle => 'Nickname Aggiornato!';

  @override
  String get no => 'No';

  @override
  String get noActiveGamesLabel => 'Nessun gioco attivo';

  @override
  String get noBadgesEarnedYet => 'Nessun badge ottenuto';

  @override
  String get noInternetConnection => 'Nessuna connessione internet';

  @override
  String get noLanguagesYet => 'Ancora nessuna lingua. Inizia a imparare!';

  @override
  String get noLeaderboardData => 'Ancora nessun dato in classifica';

  @override
  String get noMatchesFound => 'Nessun match trovato';

  @override
  String get noMatchesYet => 'Nessun match ancora';

  @override
  String get noMessages => 'Nessun messaggio ancora';

  @override
  String get noMoreProfiles => 'Nessun altro profilo da mostrare';

  @override
  String get noOthersToSee => 'Non ci sono altri da vedere';

  @override
  String get noPendingVerifications => 'Nessuna verifica in attesa';

  @override
  String get noPhotoSubmitted => 'Nessuna foto inviata';

  @override
  String get noPreviousProfile => 'Nessun profilo precedente da ripristinare';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'Nessun profilo trovato con @$nickname';
  }

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get noSocialProfilesLinked => 'Nessun profilo social collegato';

  @override
  String get noVoiceRecording => 'Nessuna registrazione vocale';

  @override
  String get nodeAvailable => 'Disponibile';

  @override
  String get nodeCompleted => 'Completato';

  @override
  String get nodeInProgress => 'In Corso';

  @override
  String get nodeLocked => 'Bloccato';

  @override
  String get notEnoughCoins => 'Monete insufficienti';

  @override
  String get notNow => 'Non Ora';

  @override
  String get notSet => 'Non impostato';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Traguardo Sbloccato: $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Hai acquistato con successo $amount monete.';
  }

  @override
  String get notificationDialogEnable => 'Attiva';

  @override
  String get notificationDialogMessage =>
      'Attiva le notifiche per sapere quando ricevi match, messaggi e super like.';

  @override
  String get notificationDialogNotNow => 'Non ora';

  @override
  String get notificationDialogTitle => 'Resta connesso';

  @override
  String get notificationEmailSubtitle => 'Ricevi notifiche via e-mail';

  @override
  String get notificationEmailTitle => 'Notifiche e-mail';

  @override
  String get notificationEnableQuietHours => 'Abilita ore silenziose';

  @override
  String get notificationEndTime => 'Ora di fine';

  @override
  String get notificationMasterControls => 'Controlli principali';

  @override
  String get notificationMatchExpiring => 'Match in scadenza';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Quando un match sta per scadere';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname ha iniziato una conversazione con te.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'Hai ricevuto un mi piace da @$nickname';
  }

  @override
  String get notificationNewLikes => 'Nuovi like';

  @override
  String get notificationNewLikesSubtitle => 'Quando qualcuno ti mette like';

  @override
  String notificationNewMatch(String nickname) {
    return 'È un Match! Hai fatto match con @$nickname. Inizia a chattare ora.';
  }

  @override
  String get notificationNewMatches => 'Nuovi match';

  @override
  String get notificationNewMatchesSubtitle => 'Quando ottieni un nuovo match';

  @override
  String notificationNewMessage(String nickname) {
    return 'Nuovo messaggio da @$nickname';
  }

  @override
  String get notificationNewMessages => 'Nuovi messaggi';

  @override
  String get notificationNewMessagesSubtitle =>
      'Quando qualcuno ti invia un messaggio';

  @override
  String get notificationProfileViews => 'Visite al profilo';

  @override
  String get notificationProfileViewsSubtitle =>
      'Quando qualcuno visita il tuo profilo';

  @override
  String get notificationPromotional => 'Promozionale';

  @override
  String get notificationPromotionalSubtitle =>
      'Consigli, offerte e promozioni';

  @override
  String get notificationPushSubtitle =>
      'Ricevi notifiche su questo dispositivo';

  @override
  String get notificationPushTitle => 'Notifiche push';

  @override
  String get notificationQuietHours => 'Ore silenziose';

  @override
  String get notificationQuietHoursDescription =>
      'Silenzia le notifiche tra orari prestabiliti';

  @override
  String get notificationQuietHoursSubtitle =>
      'Silenzia le notifiche durante determinate ore';

  @override
  String get notificationSettings => 'Impostazioni Notifiche';

  @override
  String get notificationSettingsTitle => 'Impostazioni notifiche';

  @override
  String get notificationSound => 'Suono';

  @override
  String get notificationSoundSubtitle => 'Riproduci suono per le notifiche';

  @override
  String get notificationSoundVibration => 'Suono e vibrazione';

  @override
  String get notificationStartTime => 'Ora di inizio';

  @override
  String notificationSuperLike(String nickname) {
    return 'Hai ricevuto un super mi piace da @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Super Like';

  @override
  String get notificationSuperLikesSubtitle =>
      'Quando qualcuno ti manda un Super Like';

  @override
  String get notificationTypes => 'Tipi di notifiche';

  @override
  String get notificationVibration => 'Vibrazione';

  @override
  String get notificationVibrationSubtitle => 'Vibra per le notifiche';

  @override
  String get notificationsEmpty => 'Ancora nessuna notifica';

  @override
  String get notificationsEmptySubtitle =>
      'Quando riceverai notifiche, appariranno qui';

  @override
  String get notificationsMarkAllRead => 'Segna tutto come letto';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get occupation => 'Professione';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Aggiungi foto';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Aggiungi foto che ti rappresentano davvero';

  @override
  String get onboardingAiVerifiedDescription =>
      'Le tue foto vengono verificate tramite AI per garantire l\'autenticità';

  @override
  String get onboardingAiVerifiedPhotos => 'Foto verificate con AI';

  @override
  String get onboardingBioHint =>
      'Parlaci dei tuoi interessi, hobby, cosa cerchi...';

  @override
  String get onboardingBioMinLength =>
      'La bio deve contenere almeno 50 caratteri';

  @override
  String get onboardingChooseFromGallery => 'Scegli dalla galleria';

  @override
  String get onboardingCompleteAllFields => 'Completa tutti i campi';

  @override
  String get onboardingContinue => 'Continua';

  @override
  String get onboardingDateOfBirth => 'Data di nascita';

  @override
  String get onboardingDisplayName => 'Nome visualizzato';

  @override
  String get onboardingDisplayNameHint => 'Come dovremmo chiamarti?';

  @override
  String get onboardingEnterYourName => 'Inserisci il tuo nome';

  @override
  String get onboardingExpressYourself => 'Esprimi te stesso';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Scrivi qualcosa che ti rappresenta';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'Impossibile selezionare l\'immagine: $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'Impossibile scattare la foto: $error';
  }

  @override
  String get onboardingGenderFemale => 'Donna';

  @override
  String get onboardingGenderMale => 'Uomo';

  @override
  String get onboardingGenderNonBinary => 'Non-binario';

  @override
  String get onboardingGenderOther => 'Altro';

  @override
  String get onboardingHoldIdNextToFace =>
      'Tieni il documento d\'identità accanto al viso';

  @override
  String get onboardingIdentifyAs => 'Mi identifico come';

  @override
  String get onboardingInterestsHelpMatches =>
      'I tuoi interessi ci aiutano a trovare match migliori per te';

  @override
  String get onboardingInterestsSubtitle =>
      'Seleziona almeno 3 interessi (max 10)';

  @override
  String get onboardingLanguages => 'Lingue';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 selezionate';
  }

  @override
  String get onboardingLetsGetStarted => 'Iniziamo';

  @override
  String get onboardingLocation => 'Posizione';

  @override
  String get onboardingLocationLater =>
      'Puoi impostare la posizione in seguito nelle impostazioni';

  @override
  String get onboardingMainPhoto => 'PRINCIPALE';

  @override
  String get onboardingMaxInterests => 'Puoi selezionare fino a 10 interessi';

  @override
  String get onboardingMaxLanguages => 'Puoi selezionare fino a 3 lingue';

  @override
  String get onboardingMinInterests => 'Seleziona almeno 3 interessi';

  @override
  String get onboardingMinLanguage => 'Seleziona almeno una lingua';

  @override
  String get onboardingNameMinLength =>
      'Il nome deve contenere almeno 2 caratteri';

  @override
  String get onboardingNoLocationSelected => 'Nessuna posizione selezionata';

  @override
  String get onboardingOptional => 'Facoltativo';

  @override
  String get onboardingSelectFromPhotos => 'Seleziona dalle tue foto';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 selezionati';
  }

  @override
  String get onboardingShowYourself => 'Mostra te stesso';

  @override
  String get onboardingTakePhoto => 'Scatta foto';

  @override
  String get onboardingTellUsAboutYourself => 'Raccontaci un po\' di te';

  @override
  String get onboardingTipAuthentic => 'Sii autentico e genuino';

  @override
  String get onboardingTipPassions =>
      'Condividi le tue passioni e i tuoi hobby';

  @override
  String get onboardingTipPositive => 'Mantieni un tono positivo';

  @override
  String get onboardingTipUnique => 'Cosa ti rende unico?';

  @override
  String get onboardingUploadAtLeastOnePhoto => 'Carica almeno una foto';

  @override
  String get onboardingUseCurrentLocation => 'Usa posizione attuale';

  @override
  String get onboardingUseYourCamera => 'Usa la tua fotocamera';

  @override
  String get onboardingWhereAreYou => 'Dove ti trovi?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Imposta le tue lingue preferite e la posizione (facoltativo)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Scrivi qualcosa su di te';

  @override
  String get onboardingWritingTips => 'Consigli di scrittura';

  @override
  String get onboardingYourInterests => 'I tuoi interessi';

  @override
  String oneTimeDownloadSize(int size) {
    return 'Download una tantum di circa ${size}MB.';
  }

  @override
  String get optionalConsents => 'Consensi Opzionali';

  @override
  String get orContinueWith => 'Oppure continua con';

  @override
  String get origin => 'Origine';

  @override
  String packFocusMode(String packName) {
    return 'Pacchetto: $packName';
  }

  @override
  String get password => 'Password';

  @override
  String get passwordMustContain => 'La password deve contenere:';

  @override
  String get passwordMustContainLowercase =>
      'La password deve contenere almeno una lettera minuscola';

  @override
  String get passwordMustContainNumber =>
      'La password deve contenere almeno un numero';

  @override
  String get passwordMustContainSpecialChar =>
      'La password deve contenere almeno un carattere speciale';

  @override
  String get passwordMustContainUppercase =>
      'La password deve contenere almeno una lettera maiuscola';

  @override
  String get passwordRequired => 'Password richiesta';

  @override
  String get passwordStrengthFair => 'Discreta';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordStrengthVeryStrong => 'Molto Forte';

  @override
  String get passwordStrengthVeryWeak => 'Molto Debole';

  @override
  String get passwordStrengthWeak => 'Debole';

  @override
  String get passwordTooShort =>
      'La password deve contenere almeno 8 caratteri';

  @override
  String get passwordWeak =>
      'La password deve contenere maiuscole, minuscole, numeri e caratteri speciali';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get pendingVerifications => 'Verifiche in Attesa';

  @override
  String get perMonth => '/mese';

  @override
  String get periodAllTime => 'Di Sempre';

  @override
  String get periodMonthly => 'Questo Mese';

  @override
  String get periodWeekly => 'Questa Settimana';

  @override
  String get photoAddPhoto => 'Aggiungi foto';

  @override
  String get photoAddPrivateDescription =>
      'Aggiungi foto private che puoi condividere in chat';

  @override
  String get photoAddPublicDescription =>
      'Aggiungi foto per completare il tuo profilo';

  @override
  String get photoAlreadyExistsInAlbum =>
      'La foto esiste già nell\'album di destinazione';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 foto';
  }

  @override
  String get photoDeleteConfirm =>
      'Sei sicuro/a di voler eliminare questa foto?';

  @override
  String get photoDeleteMainWarning =>
      'Questa è la tua foto principale. La prossima foto diventerà la tua foto principale (deve mostrare il tuo viso). Continuare?';

  @override
  String get photoExplicitContent =>
      'Questa foto potrebbe contenere contenuti inappropriati. Le foto nell\'app non devono mostrare nudità, biancheria intima o contenuti espliciti.';

  @override
  String get photoExplicitNudity =>
      'Questa foto sembra contenere nudità o contenuti espliciti. Tutte le foto nell\'app devono essere appropriate e completamente vestite.';

  @override
  String photoFailedPickImage(Object error) {
    return 'Impossibile selezionare l\'immagine: $error';
  }

  @override
  String get photoLongPressReorder =>
      'Pressione prolungata e trascina per riordinare';

  @override
  String get photoMainNoFace =>
      'La tua foto principale deve mostrare chiaramente il tuo viso. Nessun viso è stato rilevato in questa foto.';

  @override
  String get photoMainNotForward =>
      'Per favore, usa una foto in cui il tuo viso sia chiaramente visibile e rivolto in avanti.';

  @override
  String get photoManagePhotos => 'Gestisci foto';

  @override
  String get photoMaxPrivate => 'Massimo 6 foto private consentite';

  @override
  String get photoMaxPublic => 'Massimo 6 foto pubbliche consentite';

  @override
  String get photoMustHaveOne =>
      'Devi avere almeno una foto pubblica con il tuo viso visibile.';

  @override
  String get photoNoPhotos => 'Ancora nessuna foto';

  @override
  String get photoNoPrivatePhotos => 'Ancora nessuna foto privata';

  @override
  String get photoNotAccepted => 'Foto non accettata';

  @override
  String get photoNotAllowedPublic =>
      'Questa foto non è consentita in nessuna parte dell\'app.';

  @override
  String get photoPrimary => 'PRINCIPALE';

  @override
  String get photoPrivateShareInfo =>
      'Le foto private possono essere condivise in chat';

  @override
  String get photoTooLarge =>
      'La foto è troppo grande. La dimensione massima è 10 MB.';

  @override
  String get photoTooMuchSkin =>
      'Questa foto mostra troppa pelle scoperta. Per favore, usa una foto in cui sei vestito/a in modo appropriato.';

  @override
  String get photoUploadedMessage => 'La tua foto è stata aggiunta al profilo';

  @override
  String get photoUploadedTitle => 'Foto Caricata!';

  @override
  String get photoValidating => 'Validazione foto in corso...';

  @override
  String get photos => 'Foto';

  @override
  String photosCount(int count) {
    return '$count/6 foto';
  }

  @override
  String photosPublicCount(int count) {
    return 'Foto: $count pubbliche';
  }

  @override
  String photosPublicPrivateCount(int publicCount, int privateCount) {
    return 'Foto: $publicCount pubbliche + $privateCount private';
  }

  @override
  String get photosUpdatedMessage =>
      'La tua galleria fotografica è stata salvata';

  @override
  String get photosUpdatedTitle => 'Foto Aggiornate!';

  @override
  String phrasesCount(String count) {
    return '$count frasi';
  }

  @override
  String get phrasesLabel => 'frasi';

  @override
  String get platinum => 'Platino';

  @override
  String get playAgain => 'Gioca Ancora';

  @override
  String playersRange(String min, String max) {
    return '$min-$max giocatori';
  }

  @override
  String get playing => 'In riproduzione...';

  @override
  String playingCountLabel(String count) {
    return '$count in gioco';
  }

  @override
  String get plusTaxes => '+ tasse';

  @override
  String get preferenceAddCountry => 'Aggiungi Paese';

  @override
  String get preferenceAddDealBreaker => 'Aggiungi Criterio Eliminatorio';

  @override
  String get preferenceAdvancedFilters => 'Filtri Avanzati';

  @override
  String get preferenceAgeRange => 'Fascia d\'Eta';

  @override
  String get preferenceAllCountries => 'Tutti i Paesi';

  @override
  String get preferenceAllVerified =>
      'Tutti i profili devono essere verificati';

  @override
  String get preferenceCountry => 'Paese';

  @override
  String get preferenceCountryDescription =>
      'Mostra solo persone da paesi specifici (lascia vuoto per tutti)';

  @override
  String get preferenceDealBreakers => 'Criteri Eliminatori';

  @override
  String get preferenceDealBreakersDesc =>
      'Non mostrarmi mai profili con queste caratteristiche';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Tutti';

  @override
  String get preferenceMaxDistance => 'Distanza Massima';

  @override
  String get preferenceMen => 'Uomini';

  @override
  String get preferenceMostPopular => 'Piu Popolare';

  @override
  String get preferenceNoCountriesFound => 'Nessun paese trovato';

  @override
  String get preferenceNoCountryFilter =>
      'Nessun filtro paese - mostra globalmente';

  @override
  String get preferenceNoDealBreakers =>
      'Nessun criterio eliminatorio impostato';

  @override
  String get preferenceNoDistanceLimit => 'Nessun limite di distanza';

  @override
  String get preferenceOnlineNow => 'Online Adesso';

  @override
  String get preferenceOnlineNowDesc =>
      'Mostra solo profili attualmente online';

  @override
  String get preferenceOnlyVerified => 'Mostra solo profili verificati';

  @override
  String get preferenceOrientationDescription =>
      'Filtra per orientamento (deseleziona tutto per mostrare tutti)';

  @override
  String get preferenceRecentlyActive => 'Attivi di Recente';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Mostra solo profili attivi negli ultimi 7 giorni';

  @override
  String get preferenceSave => 'Salva';

  @override
  String get preferenceSelectCountry => 'Seleziona Paese';

  @override
  String get preferenceSexualOrientation => 'Orientamento Sessuale';

  @override
  String get preferenceShowMe => 'Mostrami';

  @override
  String get preferenceUnlimited => 'Illimitato';

  @override
  String preferenceUsersCount(int count) {
    return '$count utenti';
  }

  @override
  String get preferenceWithin => 'Entro';

  @override
  String get preferenceWomen => 'Donne';

  @override
  String get preferencesSavedMessage =>
      'Le tue preferenze di scoperta sono state aggiornate';

  @override
  String get preferencesSavedTitle => 'Preferenze Salvate!';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Origine Principale';

  @override
  String get privacyPolicy => 'Informativa sulla Privacy';

  @override
  String get privacySettings => 'Impostazioni Privacy';

  @override
  String get privateAlbum => 'Privato';

  @override
  String get privateRoom => 'Stanza Privata';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Profilo';

  @override
  String get profileAboutMe => 'Chi Sono';

  @override
  String get profileAccountDeletedSuccess => 'Account eliminato con successo.';

  @override
  String get profileActivate => 'Attiva';

  @override
  String get profileActivateIncognito => 'Attivare la modalità incognito?';

  @override
  String get profileActivateTravelerMode => 'Attivare la modalità viaggiatore?';

  @override
  String get profileActivatingBoost => 'Attivazione boost...';

  @override
  String get profileActiveLabel => 'ATTIVO';

  @override
  String get profileAdditionalDetails => 'Dettagli Aggiuntivi';

  @override
  String profileAgeCannotChange(int age) {
    return 'Eta $age - Non modificabile (verifica)';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return 'Profilo già potenziato! ${minutes}m rimanenti';
  }

  @override
  String get profileAuthenticationFailed => 'Autenticazione fallita';

  @override
  String profileBioMinLength(int min) {
    return 'La bio deve avere almeno $min caratteri';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Costo: $cost monete';
  }

  @override
  String get profileBoostDescription =>
      'Il tuo profilo apparirà in cima alla scoperta per 30 minuti!';

  @override
  String get profileBoostNow => 'Potenzia ora';

  @override
  String get profileBoostProfile => 'Potenzia profilo';

  @override
  String get profileBoostSubtitle => 'Fatti vedere per primo per 30 minuti';

  @override
  String get profileBoosted => 'Profilo potenziato!';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return 'Profilo potenziato per $minutes minuti!';
  }

  @override
  String get profileBuyCoins => 'Acquista monete';

  @override
  String get profileCoinShop => 'Negozio monete';

  @override
  String get profileCoinShopSubtitle => 'Acquista monete e abbonamento premium';

  @override
  String get profileConfirmYourPassword => 'Conferma la tua password';

  @override
  String get profileContinue => 'Continua';

  @override
  String get profileDataExportSent =>
      'Esportazione dati inviata alla tua e-mail';

  @override
  String get profileDateOfBirth => 'Data di Nascita';

  @override
  String get profileDeleteAccountWarning =>
      'Questa azione è permanente e irreversibile. Tutti i tuoi dati, match e messaggi verranno eliminati. Inserisci la tua password per confermare.';

  @override
  String get profileDiscoveryRestarted =>
      'Scoperta riavviata! Puoi vedere di nuovo tutti i profili.';

  @override
  String get profileDisplayName => 'Nome Visualizzato';

  @override
  String get profileDobInfo =>
      'La tua data di nascita non puo essere modificata per la verifica dell\'eta. La tua eta esatta e visibile ai match.';

  @override
  String get profileEditBasicInfo => 'Modifica Info Base';

  @override
  String get profileEditLocation => 'Modifica Posizione e Lingue';

  @override
  String get profileEditNickname => 'Modifica Nickname';

  @override
  String get profileEducation => 'Istruzione';

  @override
  String get profileEducationHint => 'es. Laurea in Informatica';

  @override
  String get profileEnterNameHint => 'Inserisci il tuo nome';

  @override
  String get profileEnterNicknameHint => 'Inserisci nickname';

  @override
  String get profileEnterNicknameWith =>
      'Inserisci un nickname che inizia con @';

  @override
  String get profileExportingData => 'Esportazione dei tuoi dati...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Impossibile riavviare la scoperta: $error';
  }

  @override
  String get profileFindUsers => 'Trova Utenti';

  @override
  String get profileGender => 'Genere';

  @override
  String get profileGetCoins => 'Ottieni monete';

  @override
  String get profileGetMembership => 'Ottieni l\'abbonamento GreenGo';

  @override
  String get profileGettingLocation => 'Ottenendo la posizione...';

  @override
  String get profileGreengoMembership => 'Abbonamento GreenGo';

  @override
  String get profileHeightCm => 'Altezza (cm)';

  @override
  String get profileIncognitoActivated =>
      'Modalità incognito attivata per 24 ore!';

  @override
  String profileIncognitoCost(Object cost) {
    return 'La modalità incognito costa $cost monete al giorno.';
  }

  @override
  String get profileIncognitoDeactivated => 'Modalità incognito disattivata.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'La modalità incognito nasconde il tuo profilo dalla scoperta per 24 ore.\n\nCosto: $cost';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Gratis con Platinum - Nascosto dalla scoperta';

  @override
  String get profileIncognitoMode => 'Modalità incognito';

  @override
  String get profileInsufficientCoins => 'Monete insufficienti';

  @override
  String profileInterestsCount(Object count) {
    return '$count interessi';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Raccontaci dei tuoi interessi, hobby, cosa cerchi...';

  @override
  String get profileLanguagesSectionTitle => 'Lingue';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 lingue selezionate';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count profilo/i collegato/i';
  }

  @override
  String profileLocationFailed(String error) {
    return 'Impossibile ottenere la posizione: $error';
  }

  @override
  String get profileLocationSectionTitle => 'Posizione';

  @override
  String get profileLookingFor => 'Cerco';

  @override
  String get profileLookingForHint => 'es. Relazione a lungo termine';

  @override
  String get profileMaxLanguagesAllowed => 'Massimo 3 lingue consentite';

  @override
  String get profileMembershipActive => 'Attivo';

  @override
  String get profileMembershipExpired => 'Scaduto';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Valido fino al $date';
  }

  @override
  String get profileMyUsage => 'Il mio utilizzo';

  @override
  String get profileMyUsageSubtitle =>
      'Visualizza il tuo utilizzo giornaliero e i limiti del livello';

  @override
  String get profileNicknameAlreadyTaken => 'Questo nickname e gia in uso';

  @override
  String get profileNicknameCharRules =>
      '3-20 caratteri. Solo lettere, numeri e underscore.';

  @override
  String get profileNicknameCheckError =>
      'Errore nella verifica della disponibilita';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'Il tuo nickname e unico e puo essere usato per trovarti. Altri possono cercarti con @$nickname';
  }

  @override
  String get profileNicknameInfoWithout =>
      'Il tuo nickname e unico e puo essere usato per trovarti. Impostane uno per farti scoprire dagli altri.';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileNicknameRefresh => 'Aggiorna';

  @override
  String get profileNicknameRule1 => 'Deve avere 3-20 caratteri';

  @override
  String get profileNicknameRule2 => 'Iniziare con una lettera';

  @override
  String get profileNicknameRule3 => 'Solo lettere, numeri e underscore';

  @override
  String get profileNicknameRule4 => 'Nessun underscore consecutivo';

  @override
  String get profileNicknameRule5 => 'Non puo contenere parole riservate';

  @override
  String get profileNicknameRules => 'Regole Nickname';

  @override
  String get profileNicknameSuggestions => 'Suggerimenti';

  @override
  String profileNoUsersFound(String query) {
    return 'Nessun utente trovato per \"@$query\"';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return 'Monete insufficienti! Necessarie $required, hai $available';
  }

  @override
  String get profileOccupation => 'Professione';

  @override
  String get profileOccupationHint => 'es. Ingegnere del Software';

  @override
  String get profileOptionalDetails =>
      'Opzionale - aiuta gli altri a conoscerti';

  @override
  String get profileOrientationPrivate =>
      'Questo e privato e non viene mostrato nel tuo profilo';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 foto';
  }

  @override
  String get profilePremiumFeatures => 'Funzionalità premium';

  @override
  String get profileRestart => 'Riavvia';

  @override
  String get profileRestartDiscovery => 'Riavvia scoperta';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Questo cancellerà tutti i tuoi swipe (like, nope, super like) in modo da poter riscoprire tutti da zero.\n\nI tuoi match e le chat NON saranno influenzati.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Riavvia scoperta';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Reimposta tutti gli swipe e ricomincia da capo';

  @override
  String get profileSearchByNickname => 'Cerca per @nickname';

  @override
  String get profileSearchByNicknameHint => 'Cerca per @nickname';

  @override
  String get profileSearchCityHint => 'Cerca città, indirizzo o luogo...';

  @override
  String get profileSearchForUsers => 'Cerca utenti per nickname';

  @override
  String get profileSearchLanguagesHint => 'Cerca lingue...';

  @override
  String get profileSetLocationAndLanguage =>
      'Imposta la posizione e seleziona almeno una lingua';

  @override
  String get profileSexualOrientation => 'Orientamento Sessuale';

  @override
  String get profileStop => 'Ferma';

  @override
  String get profileTellAboutYourselfHint => 'Racconta qualcosa di te...';

  @override
  String get profileTipAuthentic => 'Sii autentico e genuino';

  @override
  String get profileTipHobbies => 'Menziona i tuoi hobby e passioni';

  @override
  String get profileTipHumor => 'Aggiungi un tocco di umorismo';

  @override
  String get profileTipPositive => 'Mantieni un tono positivo';

  @override
  String get profileTipsForGreatBio => 'Consigli per un\'ottima bio';

  @override
  String profileTravelerActivated(Object city) {
    return 'Modalità viaggiatore attivata! Appari a $city per 24 ore.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'La modalità viaggiatore costa $cost monete al giorno.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Modalità viaggiatore disattivata. Ritorno alla posizione reale.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'La modalità viaggiatore ti permette di apparire nel feed di scoperta di un\'altra città per 24 ore.\n\nCosto: $cost';
  }

  @override
  String get profileTravelerMode => 'Modalità viaggiatore';

  @override
  String get profileTryDifferentNickname => 'Prova un altro nickname';

  @override
  String get profileUnableToVerifyAccount =>
      'Impossibile verificare l\'account';

  @override
  String get profileUpdateCurrentLocation => 'Aggiorna Posizione Attuale';

  @override
  String get profileUpdatedMessage => 'Le tue modifiche sono state salvate';

  @override
  String get profileUpdatedSuccess => 'Profilo aggiornato con successo';

  @override
  String get profileUpdatedTitle => 'Profilo Aggiornato!';

  @override
  String get profileWeightKg => 'Peso (kg)';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'i collegati',
      one: 'o collegato',
    );
    return '$count profil$_temp0';
  }

  @override
  String get profilingDescription =>
      'Permettici di analizzare le tue preferenze per fornire migliori suggerimenti di corrispondenza';

  @override
  String get progress => 'Progressi';

  @override
  String get progressAchievements => 'Badge';

  @override
  String get progressBadges => 'Badge';

  @override
  String get progressChallenges => 'Sfide';

  @override
  String get progressComparison => 'Confronto Progressi';

  @override
  String get progressCompleted => 'Completati';

  @override
  String get progressJourneyDescription =>
      'Visualizza il tuo percorso completo e i traguardi';

  @override
  String get progressLabel => 'Progresso';

  @override
  String get progressLeaderboard => 'Classifica';

  @override
  String progressLevel(int level) {
    return 'Livello $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Panoramica';

  @override
  String get progressRecentAchievements => 'Traguardi Recenti';

  @override
  String get progressSeeAll => 'Vedi Tutto';

  @override
  String get progressTitle => 'Progressi';

  @override
  String get progressTodaysChallenges => 'Sfide di Oggi';

  @override
  String get progressTotalXP => 'XP Totali';

  @override
  String get progressViewJourney => 'Vedi il Tuo Percorso';

  @override
  String get publicAlbum => 'Pubblico';

  @override
  String get purchaseSuccessfulTitle => 'Acquisto Riuscito!';

  @override
  String get purchasedLabel => 'Acquistato';

  @override
  String get quickPlay => 'Partita Veloce';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Leggi Informativa sulla Privacy';

  @override
  String get readTermsAndConditions => 'Leggi Termini e Condizioni';

  @override
  String get readyButton => 'Pronto';

  @override
  String get recipientNickname => 'Nickname del destinatario';

  @override
  String get recordVoice => 'Registra Voce';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get register => 'Registrati';

  @override
  String get rejectVerification => 'Rifiuta';

  @override
  String rejectionReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get rejectionReasonRequired => 'Inserisci un motivo per il rifiuto';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $limitType rimasti oggi';
  }

  @override
  String get reportSubmittedMessage =>
      'Grazie per aiutarci a mantenere sicura la nostra community';

  @override
  String get reportSubmittedTitle => 'Segnalazione Inviata!';

  @override
  String get reportWord => 'Segnala Parola';

  @override
  String get reportsPanel => 'Pannello Segnalazioni';

  @override
  String get requestBetterPhoto => 'Richiedi Foto Migliore';

  @override
  String requiresTier(String tier) {
    return 'Richiede $tier';
  }

  @override
  String get resetPassword => 'Reimposta Password';

  @override
  String get resetToDefault => 'Ripristina Predefiniti';

  @override
  String get restartAppWizard => 'Riavvia Configurazione App';

  @override
  String get restartWizard => 'Riavvia Configurazione';

  @override
  String get restartWizardDialogContent =>
      'Questo riavvierà la configurazione guidata. Potrai aggiornare le informazioni del tuo profilo passo dopo passo. I tuoi dati attuali saranno conservati.';

  @override
  String get retakePhoto => 'Scatta di Nuovo';

  @override
  String get retry => 'Riprova';

  @override
  String get reuploadVerification => 'Ricarica foto di verifica';

  @override
  String get reverificationCameraError => 'Impossibile aprire la fotocamera';

  @override
  String get reverificationDescription =>
      'Scatta un selfie chiaro per verificare la tua identità. Assicurati di avere una buona illuminazione e che il tuo viso sia ben visibile.';

  @override
  String get reverificationHeading => 'Dobbiamo verificare la tua identità';

  @override
  String get reverificationInfoText =>
      'Dopo l\'invio, il tuo profilo sarà in revisione. Otterrai l\'accesso una volta approvato.';

  @override
  String get reverificationPhotoTips => 'Consigli per la foto';

  @override
  String get reverificationReasonLabel => 'Motivo della richiesta:';

  @override
  String get reverificationRetakePhoto => 'Rifai la foto';

  @override
  String get reverificationSubmit => 'Invia per la revisione';

  @override
  String get reverificationTapToSelfie => 'Tocca per scattare un selfie';

  @override
  String get reverificationTipCamera => 'Guarda direttamente la fotocamera';

  @override
  String get reverificationTipFullFace =>
      'Assicurati che il tuo viso sia completamente visibile';

  @override
  String get reverificationTipLighting =>
      'Buona illuminazione — rivolgiti verso la fonte di luce';

  @override
  String get reverificationTipNoAccessories =>
      'Niente occhiali da sole, cappelli o maschere';

  @override
  String get reverificationTitle => 'Verifica dell\'identità';

  @override
  String get reverificationUploadFailed => 'Caricamento fallito. Riprova.';

  @override
  String get reviewReportedMessages =>
      'Rivedi messaggi segnalati e gestisci account';

  @override
  String get reviewUserVerifications => 'Rivedi verifiche utenti';

  @override
  String reviewedBy(String admin) {
    return 'Revisionato da $admin';
  }

  @override
  String get revokeAccess => 'Revocare l\'accesso all\'album';

  @override
  String get rewardsAndProgress => 'Ricompense e Progressi';

  @override
  String get romanticCategory => 'Romantico';

  @override
  String get roundTimer => 'Timer del Round';

  @override
  String roundXofY(String current, String total) {
    return 'Round $current/$total';
  }

  @override
  String get rounds => 'Round';

  @override
  String get safetyAdd => 'Aggiungi';

  @override
  String get safetyAddAtLeastOneContact =>
      'Aggiungi almeno un contatto di emergenza';

  @override
  String get safetyAddEmergencyContact => 'Aggiungi contatto di emergenza';

  @override
  String get safetyAddEmergencyContacts => 'Aggiungi contatti di emergenza';

  @override
  String get safetyAdditionalDetailsHint => 'Eventuali dettagli aggiuntivi...';

  @override
  String get safetyCheckInDescription =>
      'Programma un check-in per il tuo appuntamento. Ti ricorderemo di fare il check-in e avviseremo i tuoi contatti se non rispondi.';

  @override
  String get safetyCheckInEvery => 'Check-in ogni';

  @override
  String get safetyCheckInScheduled =>
      'Check-in dell\'appuntamento programmato!';

  @override
  String get safetyDateCheckIn => 'Check-in appuntamento';

  @override
  String get safetyDateTime => 'Data e ora';

  @override
  String get safetyEmergencyContacts => 'Contatti di emergenza';

  @override
  String get safetyEmergencyContactsHelp =>
      'Verranno avvisati se hai bisogno di aiuto';

  @override
  String get safetyEmergencyContactsLocation =>
      'I contatti di emergenza possono vedere la tua posizione';

  @override
  String get safetyInterval15Min => '15 min';

  @override
  String get safetyInterval1Hour => '1 ora';

  @override
  String get safetyInterval2Hours => '2 ore';

  @override
  String get safetyInterval30Min => '30 min';

  @override
  String get safetyLocation => 'Posizione';

  @override
  String get safetyMeetingLocationHint => 'Dove vi incontrate?';

  @override
  String get safetyMeetingWith => 'Appuntamento con';

  @override
  String get safetyNameLabel => 'Nome';

  @override
  String get safetyNotesOptional => 'Note (facoltativo)';

  @override
  String get safetyPhoneLabel => 'Numero di Telefono';

  @override
  String get safetyPleaseEnterLocation => 'Inserisci una posizione';

  @override
  String get safetyRelationshipFamily => 'Famiglia';

  @override
  String get safetyRelationshipFriend => 'Amico/a';

  @override
  String get safetyRelationshipLabel => 'Relazione';

  @override
  String get safetyRelationshipOther => 'Altro';

  @override
  String get safetyRelationshipPartner => 'Partner';

  @override
  String get safetyRelationshipRoommate => 'Coinquilino/a';

  @override
  String get safetyScheduleCheckIn => 'Programma check-in';

  @override
  String get safetyShareLiveLocation => 'Condividi posizione in tempo reale';

  @override
  String get safetyStaySafe => 'Stai al sicuro';

  @override
  String get save => 'Salva';

  @override
  String get searchByNameOrNickname => 'Cerca per nome o @nickname';

  @override
  String get searchByNickname => 'Cerca per Nickname';

  @override
  String get searchByNicknameTooltip => 'Cerca per nickname';

  @override
  String get searchCityPlaceholder => 'Cerca città, indirizzo o luogo...';

  @override
  String get searchCountries => 'Cerca paesi...';

  @override
  String get searchCountryHint => 'Cerca paese...';

  @override
  String get searchForCity => 'Cerca una città o usa il GPS';

  @override
  String get searchMessagesHint => 'Cerca messaggi...';

  @override
  String get secondChanceDescription =>
      'Rivedi i profili che hai scartato e che in realtà ti hanno messo like!';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km';
  }

  @override
  String get secondChanceEmpty => 'Nessuna seconda possibilità disponibile';

  @override
  String get secondChanceEmptySubtitle =>
      'Ricontrolla più tardi per altre opportunità!';

  @override
  String get secondChanceFindButton => 'Trova seconde possibilità';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max gratuite';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Ottieni illimitato ($cost)';
  }

  @override
  String get secondChanceLike => 'Like';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'Ti ha messo like $ago';
  }

  @override
  String get secondChanceMatchBody =>
      'Vi piacete a vicenda! Inizia una conversazione.';

  @override
  String get secondChanceMatchTitle => 'È un match!';

  @override
  String get secondChanceOutOf => 'Seconde possibilità esaurite';

  @override
  String get secondChancePass => 'Passa';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'Hai usato tutte le $freePerDay seconde possibilità gratuite per oggi.\n\nOttieni l\'illimitato per $cost monete!';
  }

  @override
  String get secondChanceRefresh => 'Aggiorna';

  @override
  String get secondChanceStartChat => 'Inizia chat';

  @override
  String get secondChanceTitle => 'Seconda possibilità';

  @override
  String get secondChanceUnlimited => 'Illimitato';

  @override
  String get secondChanceUnlimitedUnlocked =>
      'Seconde possibilità illimitate sbloccate!';

  @override
  String get secondaryOrigin => 'Origine Secondaria (opzionale)';

  @override
  String get seconds => 'Secondi';

  @override
  String get secretAchievement => 'Traguardo Segreto';

  @override
  String get seeAll => 'Vedi tutto';

  @override
  String get seeHowOthersViewProfile =>
      'Vedi come gli altri vedono il tuo profilo';

  @override
  String seeMoreProfiles(int count) {
    return 'Vedi altri $count';
  }

  @override
  String get seeMoreProfilesTitle => 'Vedi Altri Profili';

  @override
  String get seeProfile => 'Vedi Profilo';

  @override
  String selectAtLeastInterests(int count) {
    return 'Seleziona almeno $count interessi';
  }

  @override
  String get selectLanguage => 'Seleziona Lingua';

  @override
  String get selectTravelLocation => 'Seleziona la destinazione di viaggio';

  @override
  String get sendCoins => 'Invia monete';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return 'Inviare $amount monete a @$nickname?';
  }

  @override
  String get sendMedia => 'Invia Media';

  @override
  String get sendMessage => 'Invia Messaggio';

  @override
  String get serverUnavailableMessage =>
      'I nostri server sono temporaneamente non disponibili. Riprova tra qualche momento.';

  @override
  String get serverUnavailableTitle => 'Server Non Disponibile';

  @override
  String get setYourUniqueNickname => 'Imposta il tuo nickname unico';

  @override
  String get settings => 'Impostazioni';

  @override
  String get shareAlbum => 'Condividi album';

  @override
  String get shop => 'Negozio';

  @override
  String get shopActive => 'ATTIVA';

  @override
  String get shopAdvancedFilters => 'Filtri avanzati';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount monete';
  }

  @override
  String get shopBadge => 'Badge';

  @override
  String get shopBaseMembership => 'Iscrizione Base GreenGo';

  @override
  String get shopBaseMembershipDescription =>
      'Necessaria per scorrere, mettere like, chattare e interagire con altri utenti.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus monete bonus';
  }

  @override
  String get shopBoosts => 'Boost';

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Acquista $tier ($duration)';
  }

  @override
  String get shopCannotSendToSelf => 'Non puoi inviare monete a te stesso';

  @override
  String get shopCheckInternet =>
      'Assicurati di avere una connessione internet\ne riprova.';

  @override
  String get shopCoins => 'Monete';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount monete/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount monete inviate a @$nickname';
  }

  @override
  String get shopComingSoon => 'Prossimamente';

  @override
  String get shopConfirmSend => 'Conferma invio';

  @override
  String get shopCurrent => 'ATTUALE';

  @override
  String shopCurrentExpires(Object date) {
    return 'ATTUALE - Scade il $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Piano attuale: $tier';
  }

  @override
  String get shopDailyLikes => 'Like giornalieri';

  @override
  String shopDaysLeft(Object days) {
    return '${days}g rimanenti';
  }

  @override
  String get shopEnterAmount => 'Inserisci l\'importo';

  @override
  String get shopEnterBothFields => 'Inserisci nickname e importo';

  @override
  String get shopEnterValidAmount => 'Inserisci un importo valido';

  @override
  String shopExpired(String date) {
    return 'Scaduto: $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Scade: $date ($days giorni rimanenti)';
  }

  @override
  String get shopFailedToInitiate => 'Impossibile avviare l\'acquisto';

  @override
  String get shopFailedToSendCoins => 'Invio monete fallito';

  @override
  String get shopGetNotified => 'Ricevi notifica';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Modalità incognito';

  @override
  String get shopInsufficientCoins => 'Monete insufficienti';

  @override
  String shopMembershipActivated(String date) {
    return 'Iscrizione GreenGo attivata! +500 monete bonus. Valida fino al $date.';
  }

  @override
  String get shopMonthly => 'Mensile';

  @override
  String get shopNotifyMessage =>
      'Ti avviseremo quando i Video-Coins saranno disponibili';

  @override
  String get shopOneMonth => '1 Mese';

  @override
  String get shopOneYear => '1 Anno';

  @override
  String get shopPerMonth => '/mese';

  @override
  String get shopPerYear => '/anno';

  @override
  String get shopPopular => 'POPOLARE';

  @override
  String get shopPreviousPurchaseFound =>
      'Acquisto precedente trovato. Riprova.';

  @override
  String get shopPriorityMatching => 'Matching prioritario';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Acquista $coins monete per $price';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Errore di acquisto: $error';
  }

  @override
  String get shopReadReceipts => 'Conferme di lettura';

  @override
  String get shopRecipientNickname => 'Nickname del destinatario';

  @override
  String get shopRetry => 'Riprova';

  @override
  String shopSavePercent(String percent) {
    return 'RISPARMIA $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'Vedi chi ti piace';

  @override
  String get shopSend => 'Invia';

  @override
  String get shopSendCoins => 'Invia monete';

  @override
  String get shopStoreNotAvailable =>
      'Negozio non disponibile. Controlla le impostazioni del dispositivo.';

  @override
  String get shopSuperLikes => 'Super Like';

  @override
  String get shopTabCoins => 'Monete';

  @override
  String shopTabError(Object tabName) {
    return 'Errore scheda $tabName';
  }

  @override
  String get shopTabMembership => 'Iscrizione';

  @override
  String get shopTabVideo => 'Video';

  @override
  String get shopTitle => 'Negozio';

  @override
  String get shopTravelling => 'Viaggi';

  @override
  String get shopUnableToLoadPackages => 'Impossibile caricare i pacchetti';

  @override
  String get shopUnlimited => 'Illimitato';

  @override
  String get shopUnlockPremium =>
      'Sblocca le funzionalità premium e migliora la tua esperienza di incontri';

  @override
  String get shopUpgradeAndSave =>
      'Migliora e risparmia! Sconto sui livelli superiori';

  @override
  String get shopUpgradeExperience => 'Migliora la tua esperienza';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Passa a $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'Utente non trovato';

  @override
  String shopValidUntil(String date) {
    return 'Valida fino al $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      'Guarda brevi video per guadagnare monete gratis!\nResta sintonizzato per questa entusiasmante funzionalità.';

  @override
  String get shopVipBadge => 'Badge VIP';

  @override
  String get shopYearly => 'Annuale';

  @override
  String get shopYearlyPlan => 'Abbonamento annuale';

  @override
  String get shopYouHave => 'Hai';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Risparmi $amount/mese passando da $tier';
  }

  @override
  String get shortTermRelationship => 'Relazione a breve termine';

  @override
  String showingProfiles(int count) {
    return '$count profili';
  }

  @override
  String get signIn => 'Accedi';

  @override
  String get signOut => 'Esci';

  @override
  String get signUp => 'Iscriviti';

  @override
  String get silver => 'Argento';

  @override
  String get skip => 'Salta';

  @override
  String get skipForNow => 'Salta per Ora';

  @override
  String get slangCategory => 'Gergo';

  @override
  String get socialConnectAccounts => 'Collega i tuoi account social';

  @override
  String get socialHintUsername => 'Nome utente (senza @)';

  @override
  String get socialHintUsernameOrUrl => 'Nome utente o URL del profilo';

  @override
  String get socialLinksUpdatedMessage =>
      'I tuoi profili social sono stati salvati';

  @override
  String get socialLinksUpdatedTitle => 'Link Social Aggiornati!';

  @override
  String get socialNotConnected => 'Non collegato';

  @override
  String get socialProfiles => 'Profili Social';

  @override
  String get socialProfilesTip =>
      'I tuoi profili social saranno visibili nel tuo profilo di incontri e aiuteranno gli altri a verificare la tua identità.';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get spotsAbout => 'Info';

  @override
  String get spotsAddNewSpot => 'Aggiungi un nuovo luogo';

  @override
  String get spotsAddSpot => 'Aggiungi un luogo';

  @override
  String spotsAddedBy(Object name) {
    return 'Aggiunto da $name';
  }

  @override
  String get spotsAll => 'Tutti';

  @override
  String get spotsCategory => 'Categoria';

  @override
  String get spotsCouldNotLoad => 'Impossibile caricare i luoghi';

  @override
  String get spotsCouldNotLoadSpot => 'Impossibile caricare il luogo';

  @override
  String get spotsCreateSpot => 'Crea luogo';

  @override
  String get spotsCulturalSpots => 'Luoghi culturali';

  @override
  String spotsDateDaysAgo(Object count) {
    return '$count giorni fa';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return '$count mesi fa';
  }

  @override
  String get spotsDateToday => 'Oggi';

  @override
  String spotsDateWeeksAgo(Object count) {
    return '$count settimane fa';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return '$count anni fa';
  }

  @override
  String get spotsDateYesterday => 'Ieri';

  @override
  String get spotsDescriptionLabel => 'Descrizione';

  @override
  String get spotsNameLabel => 'Nome del Luogo';

  @override
  String get spotsNoReviews =>
      'Ancora nessuna recensione. Sii il primo a scriverne una!';

  @override
  String get spotsNoSpotsFound => 'Nessun luogo trovato';

  @override
  String get spotsReviewAdded => 'Recensione aggiunta!';

  @override
  String spotsReviewsCount(Object count) {
    return 'Recensioni ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Condividi la tua esperienza...';

  @override
  String get spotsSubmitReview => 'Invia recensione';

  @override
  String get spotsWriteReview => 'Scrivi una recensione';

  @override
  String get spotsYourRating => 'La tua valutazione';

  @override
  String get standardTier => 'Standard';

  @override
  String get startChat => 'Inizia Chat';

  @override
  String get startConversation => 'Inizia una conversazione';

  @override
  String get startGame => 'Inizia Partita';

  @override
  String get startLearning => 'Inizia a Imparare';

  @override
  String get startLessonBtn => 'Inizia Lezione';

  @override
  String get startSwipingToFindMatches =>
      'Inizia a scorrere per trovare i tuoi match!';

  @override
  String get step => 'Passo';

  @override
  String get stepOf => 'di';

  @override
  String get storiesAddCaptionHint => 'Aggiungi una didascalia...';

  @override
  String get storiesCreateStory => 'Crea storia';

  @override
  String storiesDaysAgo(Object count) {
    return '${count}g fa';
  }

  @override
  String get storiesDisappearAfter24h => 'La tua storia scomparirà dopo 24 ore';

  @override
  String get storiesGallery => 'Galleria';

  @override
  String storiesHoursAgo(Object count) {
    return '${count}h fa';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return '${count}m fa';
  }

  @override
  String get storiesNoActive => 'Nessuna storia attiva';

  @override
  String get storiesNoStories => 'Nessuna storia disponibile';

  @override
  String get storiesPhoto => 'Foto';

  @override
  String get storiesPost => 'Pubblica';

  @override
  String get storiesSendMessageHint => 'Invia un messaggio...';

  @override
  String get storiesShareMoment => 'Condividi un momento';

  @override
  String get storiesVideo => 'Video';

  @override
  String get storiesYourStory => 'La tua storia';

  @override
  String get streakActiveToday => 'Attivo oggi';

  @override
  String get streakBonusHeader => 'Bonus Serie!';

  @override
  String get streakInactive => 'Inizia la tua serie!';

  @override
  String get streakMessageIncredible => 'Dedizione incredibile!';

  @override
  String get streakMessageKeepItUp => 'Continua così!';

  @override
  String get streakMessageMomentum => 'Stai prendendo slancio!';

  @override
  String get streakMessageOneWeek => 'Traguardo di una settimana!';

  @override
  String get streakMessageTwoWeeks => 'Due settimane alla grande!';

  @override
  String get submitAnswer => 'Invia Risposta';

  @override
  String get submitVerification => 'Invia per la Verifica';

  @override
  String submittedOn(String date) {
    return 'Inviato il $date';
  }

  @override
  String get subscribe => 'Abbonati';

  @override
  String get subscribeNow => 'Iscriviti ora';

  @override
  String get subscriptionExpired => 'Abbonamento scaduto';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'Il tuo abbonamento $tierName è scaduto. Sei stato spostato al livello Free.\n\nEffettua l\'upgrade in qualsiasi momento per ripristinare le funzionalità premium!';
  }

  @override
  String get suggestions => 'Suggerimenti';

  @override
  String get superLike => 'Super Like';

  @override
  String superLikedYou(String name) {
    return '$name ti ha messo Super Like!';
  }

  @override
  String get superLikes => 'Super Mi Piace';

  @override
  String get supportCenter => 'Centro Supporto';

  @override
  String get supportCenterSubtitle =>
      'Ottieni aiuto, segnala problemi, contattaci';

  @override
  String get swipeIndicatorLike => 'LIKE';

  @override
  String get swipeIndicatorNope => 'NOPE';

  @override
  String get swipeIndicatorSkip => 'SKIP';

  @override
  String get swipeIndicatorSuperLike => 'SUPER LIKE';

  @override
  String get takePhoto => 'Scatta Foto';

  @override
  String get takeVerificationPhoto => 'Scatta Foto di Verifica';

  @override
  String get tapToContinue => 'Tocca per continuare';

  @override
  String get targetLanguage => 'Lingua di Destinazione';

  @override
  String get termsAndConditions => 'Termini e Condizioni';

  @override
  String get thatsYourOwnProfile => 'Quello è il tuo profilo!';

  @override
  String get thirdPartyDataDescription =>
      'Permetti la condivisione di dati anonimizzati con partner per il miglioramento del servizio';

  @override
  String get thisWeek => 'Questa Settimana';

  @override
  String get tierFree => 'Gratuito';

  @override
  String get timeRemaining => 'Tempo rimanente';

  @override
  String get timeoutError => 'Richiesta scaduta';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% al Livello $level';
  }

  @override
  String get today => 'oggi';

  @override
  String get totalXpLabel => 'XP Totali';

  @override
  String get tourDiscoveryDescription =>
      'Scorri i profili per trovare il tuo match perfetto. Scorri a destra se sei interessato, a sinistra per passare.';

  @override
  String get tourDiscoveryTitle => 'Scopri Match';

  @override
  String get tourDone => 'Fatto';

  @override
  String get tourLearnDescription =>
      'Studia vocabolario, grammatica e abilità di conversazione';

  @override
  String get tourLearnTitle => 'Impara le Lingue';

  @override
  String get tourMatchesDescription =>
      'Vedi tutti quelli a cui piaci anche tu! Inizia conversazioni con i tuoi match reciproci.';

  @override
  String get tourMatchesTitle => 'I Tuoi Match';

  @override
  String get tourMessagesDescription =>
      'Chatta con i tuoi match qui. Invia messaggi, foto e note vocali per connetterti.';

  @override
  String get tourMessagesTitle => 'Messaggi';

  @override
  String get tourNext => 'Avanti';

  @override
  String get tourPlayDescription =>
      'Sfida gli altri in divertenti giochi linguistici';

  @override
  String get tourPlayTitle => 'Gioca';

  @override
  String get tourProfileDescription =>
      'Personalizza il tuo profilo, gestisci le impostazioni e controlla la tua privacy.';

  @override
  String get tourProfileTitle => 'Il Tuo Profilo';

  @override
  String get tourProgressDescription =>
      'Guadagna badge, completa sfide e scala la classifica!';

  @override
  String get tourProgressTitle => 'Monitora i Progressi';

  @override
  String get tourShopDescription =>
      'Ottieni monete e funzionalità premium per migliorare la tua esperienza.';

  @override
  String get tourShopTitle => 'Shop e Monete';

  @override
  String get tourSkip => 'Salta';

  @override
  String get translateWord => 'Traduci questa parola';

  @override
  String get translationDownloadExplanation =>
      'Per attivare la traduzione automatica dei messaggi, dobbiamo scaricare i dati linguistici per l\'uso offline.';

  @override
  String get travelCategory => 'Viaggio';

  @override
  String get travelLabel => 'Viaggio';

  @override
  String get travelerAppearFor24Hours =>
      'Apparirai nei risultati di scoperta per questa posizione per 24 ore.';

  @override
  String get travelerBadge => 'Viaggiatore';

  @override
  String get travelerChangeLocation => 'Cambia posizione';

  @override
  String get travelerConfirmLocation => 'Conferma posizione';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'Impossibile ottenere la posizione: $error';
  }

  @override
  String get travelerGettingLocation => 'Rilevamento posizione...';

  @override
  String travelerInCity(String city) {
    return 'A $city';
  }

  @override
  String get travelerLoadingAddress => 'Caricamento indirizzo...';

  @override
  String get travelerLocationInfo =>
      'Apparirai nei risultati di scoperta per questa posizione per 24 ore.';

  @override
  String get travelerLocationPermissionsDenied =>
      'Permessi di localizzazione negati';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Permessi di localizzazione negati permanentemente';

  @override
  String get travelerLocationServicesDisabled =>
      'I servizi di localizzazione sono disabilitati';

  @override
  String travelerModeActivated(String city) {
    return 'Modalità viaggiatore attivata! Apparirai a $city per 24 ore.';
  }

  @override
  String get travelerModeActive => 'Modalità viaggiatore attiva';

  @override
  String get travelerModeDeactivated =>
      'Modalità viaggiatore disattivata. Tornato alla tua posizione reale.';

  @override
  String get travelerModeDescription =>
      'Appari nel feed di scoperta di un\'altra città per 24 ore';

  @override
  String get travelerModeTitle => 'Modalità Viaggiatore';

  @override
  String travelerNoResultsFor(Object query) {
    return 'Nessun risultato per \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Scegli sulla mappa';

  @override
  String get travelerProfileAppearDescription =>
      'Il tuo profilo apparirà nel feed di scoperta di quella posizione per 24 ore con un badge Viaggiatore.';

  @override
  String get travelerSearchHint =>
      'Il tuo profilo apparirà nel feed di scoperta di quella posizione per 24 ore con un badge Viaggiatore.';

  @override
  String get travelerSearchOrGps => 'Cerca una città o usa il GPS';

  @override
  String get travelerSelectOnMap => 'Seleziona sulla mappa';

  @override
  String get travelerSelectThisLocation => 'Seleziona questa posizione';

  @override
  String get travelerSelectTravelLocation => 'Seleziona posizione di viaggio';

  @override
  String get travelerTapOnMap =>
      'Tocca sulla mappa per selezionare una posizione';

  @override
  String get travelerUseGps => 'Usa il GPS';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get tryDifferentSearchOrFilter => 'Prova una ricerca o filtro diverso';

  @override
  String get twoFaDisabled => 'Autenticazione 2FA disattivata';

  @override
  String get twoFaEnabled => 'Autenticazione 2FA attivata';

  @override
  String get twoFaToggleSubtitle =>
      'Richiedi la verifica tramite codice email ad ogni accesso';

  @override
  String get twoFaToggleTitle => 'Attiva Autenticazione 2FA';

  @override
  String get typeMessage => 'Scrivi un messaggio...';

  @override
  String get typeQuizzes => 'Quiz';

  @override
  String get typeStreak => 'Serie';

  @override
  String typeWordStartingWith(String letter) {
    return 'Scrivi una parola che inizia con \"$letter\"';
  }

  @override
  String get typeWordsLearned => 'Parole Imparate';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'Impossibile caricare il profilo';

  @override
  String get unableToPlayVoiceIntro =>
      'Impossibile riprodurre l\'introduzione vocale';

  @override
  String get undoSwipe => 'Annulla Swipe';

  @override
  String unitLabelN(String number) {
    return 'Unità $number';
  }

  @override
  String get unlimited => 'Illimitato';

  @override
  String get unlock => 'Sblocca';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Sblocca altri $count profili nella griglia per $cost monete.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Sei sicuro di voler annullare il match con $name? Questa azione e irreversibile.';
  }

  @override
  String get unmatchLabel => 'Annulla Match';

  @override
  String unmatchedWith(String name) {
    return 'Match annullato con $name';
  }

  @override
  String get upgrade => 'Aggiorna';

  @override
  String get upgradeForEarlyAccess =>
      'Passa ad Argento, Oro o Platino per l\'accesso anticipato il 1° marzo 2026!';

  @override
  String get upgradeNow => 'Aggiorna Ora';

  @override
  String get upgradeToPremium => 'Passa a Premium';

  @override
  String upgradeToTier(String tier) {
    return 'Passa a $tier';
  }

  @override
  String get uploadPhoto => 'Carica Foto';

  @override
  String get uppercaseLowercase => 'Lettere maiuscole e minuscole';

  @override
  String get useCurrentGpsLocation => 'Usa la mia posizione GPS attuale';

  @override
  String get usedToday => 'Usati oggi';

  @override
  String get usedWords => 'Parole Usate';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName è stato bloccato';
  }

  @override
  String get userBlockedTitle => 'Utente Bloccato!';

  @override
  String get userNotFound => 'Utente non trovato';

  @override
  String get usernameOrProfileUrl => 'Nome utente o URL del profilo';

  @override
  String get usernameWithoutAt => 'Nome utente (senza @)';

  @override
  String get verificationApproved => 'Verifica Approvata';

  @override
  String get verificationApprovedMessage =>
      'La tua identità è stata verificata. Ora hai accesso completo all\'app.';

  @override
  String get verificationApprovedSuccess => 'Verifica approvata con successo';

  @override
  String get verificationDescription =>
      'Per garantire la sicurezza della nostra comunità, richiediamo a tutti gli utenti di verificare la propria identità. Scatta una foto di te stesso con il tuo documento d\'identità in mano.';

  @override
  String get verificationHistory => 'Storico Verifiche';

  @override
  String get verificationInstructions =>
      'Tieni il tuo documento d\'identità (passaporto, patente o carta d\'identità) accanto al viso e scatta una foto chiara.';

  @override
  String get verificationNeedsResubmission => 'Foto Migliore Richiesta';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Abbiamo bisogno di una foto più chiara per la verifica. Invia di nuovo.';

  @override
  String get verificationPanel => 'Pannello Verifiche';

  @override
  String get verificationPending => 'Verifica in Corso';

  @override
  String get verificationPendingMessage =>
      'Il tuo account è in fase di verifica. Di solito richiede 24-48 ore. Sarai avvisato quando la revisione sarà completata.';

  @override
  String get verificationRejected => 'Verifica Rifiutata';

  @override
  String get verificationRejectedMessage =>
      'La tua verifica è stata rifiutata. Invia una nuova foto.';

  @override
  String get verificationRejectedSuccess => 'Verifica rifiutata';

  @override
  String get verificationRequired => 'Verifica dell\'Identità Richiesta';

  @override
  String get verificationSkipWarning =>
      'Puoi esplorare l\'app, ma non potrai chattare o vedere altri profili finché non sarai verificato.';

  @override
  String get verificationTip1 => 'Assicurati di avere una buona illuminazione';

  @override
  String get verificationTip2 =>
      'Il tuo viso e il documento devono essere ben visibili';

  @override
  String get verificationTip3 =>
      'Tieni il documento accanto al viso, non coprendolo';

  @override
  String get verificationTip4 => 'Il testo sul documento deve essere leggibile';

  @override
  String get verificationTips => 'Consigli per una verifica corretta:';

  @override
  String get verificationTitle => 'Verifica la Tua Identità';

  @override
  String get verifyNow => 'Verifica Ora';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit tag selezionati';
  }

  @override
  String get vibeTagsGet5Tags => 'Ottieni 5 tag';

  @override
  String get vibeTagsGetAccessTo => 'Ottieni accesso a:';

  @override
  String get vibeTagsLimitReached => 'Limite tag raggiunto';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Gli utenti gratuiti possono selezionare fino a $limit tag. Passa a Premium per 5 tag!';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'Hai raggiunto il massimo di $limit tag. Rimuovine uno per aggiungerne un altro.';
  }

  @override
  String get vibeTagsNoTags => 'Nessun tag disponibile';

  @override
  String get vibeTagsPremiumFeature1 => '5 tag vibe invece di 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Tag premium esclusivi';

  @override
  String get vibeTagsPremiumFeature3 => 'Priorità nei risultati di ricerca';

  @override
  String get vibeTagsPremiumFeature4 => 'E molto altro!';

  @override
  String get vibeTagsRemoveTag => 'Rimuovi tag';

  @override
  String get vibeTagsSelectDescription =>
      'Seleziona i tag che corrispondono al tuo umore e alle tue intenzioni attuali';

  @override
  String get vibeTagsSetTemporary => 'Imposta come tag temporaneo (24h)';

  @override
  String get vibeTagsShowYourVibe => 'Mostra la tua vibe';

  @override
  String get vibeTagsTemporaryDescription =>
      'Mostra questa vibe per le prossime 24 ore';

  @override
  String get vibeTagsTemporaryTag => 'Tag temporaneo (24h)';

  @override
  String get vibeTagsTitle => 'La tua vibe';

  @override
  String get vibeTagsUpgradeToPremium => 'Passa a Premium';

  @override
  String get vibeTagsViewPlans => 'Vedi piani';

  @override
  String get vibeTagsYourSelected => 'I tuoi tag selezionati';

  @override
  String get videoCallCategory => 'Videochiamata';

  @override
  String get view => 'Visualizza';

  @override
  String get viewAllChallenges => 'Vedi Tutte le Sfide';

  @override
  String get viewAllLabel => 'Vedi Tutto';

  @override
  String get viewBadgesAchievementsLevel =>
      'Visualizza badge, traguardi e livello';

  @override
  String get viewMyProfile => 'Visualizza il Mio Profilo';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'MEMBRO ORO';

  @override
  String get vipPlatinumMember => 'PLATINO VIP';

  @override
  String get vipPremiumBenefitsActive => 'Vantaggi Premium Attivi';

  @override
  String get vipSilverMember => 'MEMBRO ARGENTO';

  @override
  String get virtualGiftsAddMessageHint =>
      'Aggiungi un messaggio (facoltativo)';

  @override
  String get voiceDeleteConfirm =>
      'Sei sicuro di voler eliminare la tua presentazione vocale?';

  @override
  String get voiceDeleteRecording => 'Elimina Registrazione';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'Impossibile avviare la registrazione: $error';
  }

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'Impossibile caricare la registrazione: $error';
  }

  @override
  String get voiceIntro => 'Presentazione Vocale';

  @override
  String get voiceIntroSaved => 'Presentazione vocale salvata';

  @override
  String get voiceIntroShort => 'Intro Vocale';

  @override
  String get voiceIntroduction => 'Introduzione Vocale';

  @override
  String get voiceIntroductionInfo =>
      'Le presentazioni vocali aiutano gli altri a conoscerti meglio. Questo passaggio è facoltativo.';

  @override
  String get voiceIntroductionSubtitle =>
      'Registra un breve messaggio vocale (facoltativo)';

  @override
  String get voiceIntroductionTitle => 'Presentazione vocale';

  @override
  String get voiceMicrophonePermissionRequired =>
      'È richiesto il permesso del microfono';

  @override
  String get voiceRecordAgain => 'Registra di Nuovo';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Registra una breve presentazione di $seconds secondi per far sentire la tua personalità.';
  }

  @override
  String get voiceRecorded => 'Voce registrata';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'Registrazione... (max $maxDuration secondi)';
  }

  @override
  String get voiceRecordingReady => 'Registrazione pronta';

  @override
  String get voiceRecordingSaved => 'Registrazione salvata';

  @override
  String get voiceRecordingTips => 'Suggerimenti per la Registrazione';

  @override
  String get voiceSavedMessage =>
      'La tua introduzione vocale è stata aggiornata';

  @override
  String get voiceSavedTitle => 'Voce Salvata!';

  @override
  String get voiceStandOutWithYourVoice => 'Fatti notare con la tua voce!';

  @override
  String get voiceTapToRecord => 'Tocca per registrare';

  @override
  String get voiceTipBeYourself => 'Sii te stesso e naturale';

  @override
  String get voiceTipFindQuietPlace => 'Trova un posto tranquillo';

  @override
  String get voiceTipKeepItShort => 'Mantienilo breve e dolce';

  @override
  String get voiceTipShareWhatMakesYouUnique =>
      'Condividi ciò che ti rende unico';

  @override
  String get voiceUploadFailed =>
      'Caricamento della registrazione vocale fallito';

  @override
  String get voiceUploading => 'Caricamento...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic =>
      'Il tuo accesso inizierà il 15 marzo 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'Come membro $tier, hai accesso anticipato il 1° marzo 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'La Tua Data di Accesso';

  @override
  String waitingCountLabel(String count) {
    return '$count in attesa';
  }

  @override
  String get waitingCountdownLabel => 'Conto alla rovescia per il lancio';

  @override
  String get waitingCountdownSubtitle =>
      'Grazie per la registrazione! GreenGo Chat sta per essere lanciato. Preparati per un\'esperienza esclusiva.';

  @override
  String get waitingCountdownTitle => 'Conto alla Rovescia per il Lancio';

  @override
  String waitingDaysRemaining(int days) {
    return '$days giorni';
  }

  @override
  String get waitingEarlyAccessMember => 'Membro Accesso Anticipato';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Attiva le notifiche per essere il primo a sapere quando puoi accedere all\'app.';

  @override
  String get waitingEnableNotificationsTitle => 'Rimani aggiornato';

  @override
  String get waitingExclusiveAccess => 'La tua data di accesso esclusivo';

  @override
  String get waitingForPlayers => 'In attesa dei giocatori...';

  @override
  String get waitingForVerification => 'In attesa di verifica...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours ore';
  }

  @override
  String get waitingMessageApproved =>
      'Ottime notizie! Il tuo account è stato approvato. Potrai accedere a GreenGoChat nella data indicata qui sotto.';

  @override
  String get waitingMessagePending =>
      'Il tuo account è in attesa di approvazione dal nostro team. Ti avviseremo una volta che il tuo account sarà stato esaminato.';

  @override
  String get waitingMessageRejected =>
      'Purtroppo il tuo account non può essere approvato al momento. Contatta il supporto per maggiori informazioni.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minuti';
  }

  @override
  String get waitingNotificationEnabled =>
      'Notifiche attivate - ti faremo sapere quando potrai accedere all\'app!';

  @override
  String get waitingProfileUnderReview => 'Profilo in revisione';

  @override
  String get waitingReviewMessage =>
      'L\'app è ora attiva! Il nostro team sta esaminando il tuo profilo per garantire la migliore esperienza per la nostra comunità. Questo richiede solitamente 24-48 ore.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds secondi';
  }

  @override
  String get waitingStayTuned =>
      'Resta sintonizzato! Ti avviseremo quando sarà il momento di iniziare a connetterti.';

  @override
  String get waitingStepActivation => 'Attivazione account';

  @override
  String get waitingStepRegistration => 'Registrazione completata';

  @override
  String get waitingStepReview => 'Revisione profilo in corso';

  @override
  String get waitingSubtitle => 'Il tuo account è stato creato con successo';

  @override
  String get waitingThankYouRegistration => 'Grazie per la registrazione!';

  @override
  String get waitingTitle => 'Grazie per la Registrazione!';

  @override
  String get weeklyChallengesTitle => 'Sfide Settimanali';

  @override
  String get weight => 'Peso';

  @override
  String get weightLabel => 'Peso';

  @override
  String get welcome => 'Benvenuto su GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Parola già usata';

  @override
  String get wordReported => 'Parola segnalata';

  @override
  String get xTwitter => 'X (Twitter)';

  @override
  String get xp => 'XP';

  @override
  String xpAmountLabel(String amount) {
    return '$amount XP';
  }

  @override
  String xpEarned(String amount) {
    return '$amount XP guadagnati';
  }

  @override
  String get xpLabel => 'XP';

  @override
  String xpProgressLabel(String current, String max) {
    return '$current / $max XP';
  }

  @override
  String xpRewardLabel(String xp) {
    return '+$xp XP';
  }

  @override
  String get yearlyMembership => 'Iscrizione annuale';

  @override
  String yearsLabel(int age) {
    return '$age anni';
  }

  @override
  String get yes => 'Sì';

  @override
  String get yesterday => 'ieri';

  @override
  String youAndMatched(String name) {
    return 'Tu e $name vi siete piaciuti';
  }

  @override
  String get youGotSuperLike => 'Hai ricevuto un Super Like!';

  @override
  String get youLabel => 'TU';

  @override
  String get youLose => 'Hai Perso';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Hai fatto match con $name il $date';
  }

  @override
  String get youWin => 'Hai Vinto!';

  @override
  String get yourLanguages => 'Le Tue Lingue';

  @override
  String get yourRankLabel => 'La Tua Posizione';

  @override
  String get yourTurn => 'Tocca a Te!';
}
