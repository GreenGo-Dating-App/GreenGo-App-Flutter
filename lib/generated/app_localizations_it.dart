// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get culturalPassportTitle => 'Passaporto culturale';

  @override
  String get culturalPassportSubtitle =>
      'I timbri che collezioni dalle culture, lingue ed eventi che esplori';

  @override
  String get passportSectionCountries => 'Paesi';

  @override
  String get passportSectionLanguages => 'Lingue';

  @override
  String get passportSectionEvents => 'Eventi';

  @override
  String get passportLoading => 'Caricamento del tuo passaporto…';

  @override
  String get passportEarned => 'Ottenuto';

  @override
  String get passportLocked => 'Bloccato';

  @override
  String get passportEmpty =>
      'Inizia a chattare, imparare le lingue e partecipare a eventi per guadagnare i tuoi primi timbri.';

  @override
  String passportProgressSummary(int countries, int languages, int events) {
    return '$countries paesi · $languages lingue · $events eventi';
  }

  @override
  String passportOverallProgress(int percent) {
    return '$percent% esplorato';
  }

  @override
  String get passportEventDating => 'Incontri';

  @override
  String get passportEventSocial => 'Social';

  @override
  String get passportEventSports => 'Sport';

  @override
  String get passportEventFood => 'Cibo';

  @override
  String get passportEventNightlife => 'Vita notturna';

  @override
  String get passportEventOutdoor => 'All\'aperto';

  @override
  String get passportEventArts => 'Arte';

  @override
  String get passportEventGaming => 'Gaming';

  @override
  String get passportEventTravel => 'Viaggi';

  @override
  String get passportEventWellness => 'Benessere';

  @override
  String get passportEventLanguageExchange => 'Scambio linguistico';

  @override
  String get passportEventOther => 'Altro';

  @override
  String get tourGotIt => 'Capito';

  @override
  String get tourWelcomeTitle => 'Benvenuto su GreenGo!';

  @override
  String get tourWelcomeDesc =>
      'Questa è la tua griglia Scoperta: persone reali intorno a te, ordinate per distanza. Impariamo i gesti che rendono GreenGo veloce da usare.';

  @override
  String get tourCardTapTitle => 'Tocca una scheda';

  @override
  String get tourCardTapDesc =>
      'Tocca il centro di una scheda per aprire il menu azioni: like, super like o profilo completo.';

  @override
  String get tourCardEdgeTitle => 'Sfoglia le foto';

  @override
  String get tourCardEdgeDesc =>
      'Tocca il bordo sinistro o destro di una scheda per sfogliare le foto della persona senza uscire dalla griglia.';

  @override
  String get tourCardHoldTitle => 'Tieni premuto per l\'anteprima';

  @override
  String get tourCardHoldDesc =>
      'Tieni premuta una scheda per vedere le foto a schermo intero.';

  @override
  String get tourRefreshTitle => 'Trascina per aggiornare';

  @override
  String get tourRefreshDesc =>
      'Trascina la griglia verso il basso in qualsiasi momento per caricare le persone più recenti vicino a te.';

  @override
  String get tourModeToggleTitle => 'Modalità swipe';

  @override
  String get tourModeToggleDesc =>
      'Tocca qui per passare dalla griglia alla modalità swipe. In modalità swipe: scorri a destra per like, a sinistra per passare, verso l\'alto per super like.';

  @override
  String get tourGlobeTitle => 'Esplora il globo';

  @override
  String get tourGlobeDesc =>
      'Apri il globo 3D per scoprire persone in tutto il mondo, non solo vicino a te.';

  @override
  String get tourSearchTitle => 'Cerca per nickname';

  @override
  String get tourSearchDesc =>
      'Sai chi stai cercando? Trova le persone direttamente tramite il loro nickname.';

  @override
  String get tourPrefsTitle => 'Filtri di scoperta';

  @override
  String get tourPrefsDesc =>
      'Regola chi scopri: distanza, età, lingue, paese e altro.';

  @override
  String get tourCoinsTitle => 'Le tue monete';

  @override
  String get tourCoinsDesc =>
      'Ricevi monete gratis ogni giorno. Tocca il tuo saldo in qualsiasi momento per aprire il Negozio.';

  @override
  String get tourHelpTitle => 'Serve un promemoria?';

  @override
  String get tourHelpDesc =>
      'La guida dell\'app è qui — incluso questo tutorial, che puoi rivedere quando vuoi.';

  @override
  String get tourNavMessagesTitle => 'Messaggi';

  @override
  String get tourNavMessagesDesc =>
      'Chatta senza barriere linguistiche: tieni premuto un messaggio per tradurlo, toccalo due volte per ascoltarlo.';

  @override
  String get tourNavLeaderboardTitle => 'Classifica';

  @override
  String get tourNavLeaderboardDesc =>
      'Guadagna XP e badge mentre ti connetti, chatti e impari. Guarda la tua posizione.';

  @override
  String get tourNavShopTitle => 'Negozio';

  @override
  String get tourNavShopDesc =>
      'Pacchetti di monete e abbonamenti per sbloccare di più di GreenGo.';

  @override
  String get tourNavProfileTitle => 'Il tuo profilo';

  @override
  String get tourNavProfileDesc =>
      'Completa il tuo profilo e la verifica per farti scoprire da più persone.';

  @override
  String get tourFinishTitle => 'Tutto pronto!';

  @override
  String get tourFinishDesc =>
      'Divertiti a scoprire nuove persone e culture. Puoi rivedere questo tutorial in qualsiasi momento dalla guida (icona ?).';

  @override
  String get tourSwipeHintTitle => 'Scorri per connetterti';

  @override
  String get tourSwipeHintLike => 'Mi piace';

  @override
  String get tourSwipeHintPass => 'Passa';

  @override
  String get tourSwipeHintSuper => 'Super like';

  @override
  String get tourChatHoldTitle => 'Tieni premuto un messaggio';

  @override
  String get tourChatHoldDesc =>
      'Tieni premuto qualsiasi messaggio per tradurlo, copiarlo o inoltrarlo.';

  @override
  String get tourChatDoubleTapTitle => 'Ascoltalo';

  @override
  String get tourChatDoubleTapDesc =>
      'Tocca due volte un messaggio ricevuto per sentirne la pronuncia.';

  @override
  String get tourChatLanguageTitle => 'Lingue e apprendimento';

  @override
  String get tourChatLanguageDesc =>
      'Apri il menu di traduzione per gli strumenti linguistici: impostazioni di traduzione, pratica della pronuncia e funzioni di apprendimento.';

  @override
  String get tourChatSettingsTitle => 'Opzioni chat';

  @override
  String get tourChatSettingsDesc =>
      'Gestisci questa conversazione: impostazioni della chat, elimina, blocca o segnala.';

  @override
  String get tourDetailDoubleTapTitle => 'Metti like a una foto';

  @override
  String get tourDetailDoubleTapDesc =>
      'Tocca due volte qualsiasi foto per metterle like.';

  @override
  String get tourStoryHoldHint => 'Tieni premuto per mettere in pausa';

  @override
  String get guideReplayTour => 'Rivedi il tutorial';

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
  String get achievementsSubtitle => 'Visualizza i tuoi badge e progressi';

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
  String get adminDailySuperLikes => 'Connessioni Prioritarie giornaliere';

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
  String get achievementUnlockedTitle => 'OBIETTIVO SBLOCCATO!';

  @override
  String get achievementUnlockedAwesome => 'Fantastico!';

  @override
  String get achievementRarityCommon => 'COMUNE';

  @override
  String get achievementRarityUncommon => 'NON COMUNE';

  @override
  String get achievementRarityRare => 'RARO';

  @override
  String get achievementRarityEpic => 'EPICO';

  @override
  String get achievementRarityLegendary => 'LEGGENDARIO';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

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
  String get blindDateLetsExchange => 'Inizia a connetterti!';

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
    return ' (+$bonus bonus!)';
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
  String get chatGrammarSuggestion => 'Suggerimento grammaticale';

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
  String get chatLanguagePickerHint =>
      'Scegli la lingua in cui vuoi leggere questa conversazione. Tutti i messaggi saranno tradotti per te.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Lingua della chat impostata su $language';
  }

  @override
  String get chatLanguages => 'Lingue';

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
  String get chatNoMessagesToPractice =>
      'Ancora nessun messaggio con cui esercitarsi';

  @override
  String get chatNoMessagesYet => 'Nessun messaggio ancora';

  @override
  String get chatNoPrivatePhotos => 'Nessuna foto privata disponibile';

  @override
  String get chatNoSupportTickets => 'Nessun Ticket di Supporto';

  @override
  String get chatOffline => 'Offline';

  @override
  String get chatOnline => 'Online';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'Online ${days}g fa';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'Online ${hours}h fa';
  }

  @override
  String get chatOnlineJustNow => 'Online adesso';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'Online ${minutes}min fa';
  }

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
  String get chatPronunciationChallenge => 'Sfida di pronuncia';

  @override
  String get chatPronunciationHint =>
      'Tocca per ascoltare, poi esercitati a dire ogni frase:';

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
  String chatSeeExchangeDetails(String name) {
    return 'Vedi Dettagli dello Scambio con $name';
  }

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
  String get chatScrollUpForOlder => 'Scorri in alto per i messaggi precedenti';

  @override
  String get chatSearchByNameOrNickname => 'Cerca per nome o @nickname';

  @override
  String get chatSearchConversationsHint => 'Cerca conversazioni...';

  @override
  String get chatSelectPhotos => 'Seleziona foto da inviare';

  @override
  String get chatSend => 'Invia';

  @override
  String get chatSendAnyway => 'Invia comunque';

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
  String get chatSettingCulturalTips => 'Consigli culturali';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Mostra contesto culturale per modi di dire';

  @override
  String get chatSettingDifficultyBadges => 'Badge di difficoltà';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'Mostra livello QCER (A1-C2) sui messaggi';

  @override
  String get chatSettingGrammarCheck => 'Controllo grammaticale';

  @override
  String get chatSettingGrammarCheckDesc =>
      'Controlla la grammatica prima di inviare';

  @override
  String get chatSettingLanguageFlags => 'Bandiere lingua';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Mostra emoji bandiera accanto al testo tradotto e originale';

  @override
  String get chatSettingPhraseOfDay => 'Frase del giorno';

  @override
  String get chatSettingPhraseOfDayDesc =>
      'Mostra una frase quotidiana da praticare';

  @override
  String get chatSettingPronunciation => 'Pronuncia (TTS)';

  @override
  String get chatSettingPronunciationDesc =>
      'Doppio tocco per ascoltare la pronuncia';

  @override
  String get chatSettingShowOriginal => 'Mostra testo originale';

  @override
  String get chatSettingShowOriginalDesc =>
      'Mostra il messaggio originale sotto la traduzione';

  @override
  String get chatSettingSmartReplies => 'Risposte intelligenti';

  @override
  String get chatSettingSmartRepliesDesc =>
      'Suggerisci risposte nella lingua obiettivo';

  @override
  String get chatSettingTtsTranslation => 'TTS legge traduzione';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Leggi il testo tradotto invece dell\'originale';

  @override
  String get chatSettingWordBreakdown => 'Scomposizione parole';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Tocca i messaggi per traduzione parola per parola';

  @override
  String get chatSettingXpBar => 'Barra XP e serie';

  @override
  String get chatSettingXpBarDesc => 'Mostra XP sessione e progresso parole';

  @override
  String get chatSettingsSaveAllChats => 'Salva per tutte le chat';

  @override
  String get chatSettingsSaveThisChat => 'Salva per questa chat';

  @override
  String get chatSettingsSavedAllChats =>
      'Impostazioni salvate per tutte le chat';

  @override
  String get chatSettingsSavedThisChat =>
      'Impostazioni salvate per questa chat';

  @override
  String get chatSettingsSubtitle =>
      'Personalizza la tua esperienza di apprendimento in questa chat';

  @override
  String get chatSettingsTitle => 'Impostazioni chat';

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
  String chatStreak(int count) {
    return 'Serie: $count';
  }

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
  String get translationFailedTapRetry =>
      'Traduzione non riuscita · Tocca per riprovare';

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
  String get chatUseCorrection => 'Usa correzione';

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
  String chatWords(int count) {
    return '$count parole';
  }

  @override
  String get chatYou => 'Tu';

  @override
  String get chatYouRevokedAlbum => 'Hai revocato l\'accesso all\'album';

  @override
  String get chatYouSharedAlbum => 'Hai condiviso il tuo album privato';

  @override
  String get chatYourLanguage => 'La tua lingua';

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
  String get communitiesCoverImageLabel => 'Immagine di copertina';

  @override
  String get communitiesCoverImageHint =>
      'Aggiungi una foto di copertina (facoltativo)';

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
  String get communitiesDeleteCommunity => 'Elimina community';

  @override
  String communitiesDeleteConfirm(String name) {
    return 'Eliminare definitivamente \"$name\"? Tutti i messaggi, i membri e i contenuti verranno rimossi. Operazione irreversibile.';
  }

  @override
  String get communitiesDeletedSuccess => 'Community eliminata';

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
  String get communitiesSaveFavorite => 'Salva nei preferiti';

  @override
  String get communitiesRemoveFavorite => 'Rimuovi dai preferiti';

  @override
  String get communitiesFavoritesSection => 'Preferiti';

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
  String get communitiesTabJoined => 'Community iscritte';

  @override
  String get communitiesTabManaged => 'Le mie community';

  @override
  String get communitiesNoManaged => 'Non gestisci ancora nessuna community';

  @override
  String get communitiesNoManagedSubtitle =>
      'Crea una community per riunire le persone';

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
  String get dailyChallengesSubtitle => 'Completa le sfide per ottenere premi';

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
  String get discover => 'Rete';

  @override
  String discoveryError(String error) {
    return 'Errore: $error';
  }

  @override
  String get discoveryFilterAll => 'Tutti';

  @override
  String get discoveryFilterGuides => 'Guide';

  @override
  String get discoveryFilterLiked => 'Connessi';

  @override
  String get discoveryFilterMatches => 'Match';

  @override
  String get discoveryFilterPassed => 'Rifiutati';

  @override
  String get discoveryFilterSkipped => 'Esplorati';

  @override
  String get discoveryFilterSuperLiked => 'Prioritario';

  @override
  String get discoveryFilterNetwork => 'La Mia Rete';

  @override
  String get discoveryFilterTravelers => 'Viaggiatori';

  @override
  String get discoveryLimitReached => 'Hai raggiunto il tuo limite di scoperta';

  @override
  String discoverySeeMoreCoins(int coins) {
    return 'Spendi $coins monete per vederne altri';
  }

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
  String get eventsCapacityAllowed => 'Capacità consentita';

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
  String get eventsFilterOngoing => 'In corso';

  @override
  String get eventsFilterUpcoming => 'In arrivo';

  @override
  String get eventsFilterPast => 'Passati';

  @override
  String get eventsTabExperiences => 'Esperienze';

  @override
  String get eventsTabAttractions => 'Attrazioni';

  @override
  String get eventsTabCommunity => 'Comunità';

  @override
  String get eventsDeleteEvent => 'Elimina evento';

  @override
  String get eventsDeleteConfirmBody =>
      'Vuoi davvero eliminare questo evento? L\'azione è irreversibile.';

  @override
  String get eventsBook => 'Prenota';

  @override
  String get eventsFromPrice => 'da';

  @override
  String get eventsTabNearby => 'Nelle Vicinanze';

  @override
  String get eventsTabUpcoming => 'In Arrivo';

  @override
  String get eventsThisMonth => 'Questo Mese';

  @override
  String get eventsDateUntil => 'Fino al';

  @override
  String get eventsDateFrom => 'Dal';

  @override
  String get eventsCustomRange => 'Intervallo personalizzato';

  @override
  String get eventsDateAnyTime => 'In qualsiasi momento';

  @override
  String get eventsThisWeekFilter => 'Questa Settimana';

  @override
  String get eventsTitle => 'Eventi';

  @override
  String get eventsAndPlacesTitle => 'Eventi e luoghi';

  @override
  String get eventsCategoryAll => 'Tutti';

  @override
  String attractionVisitWebsite(String host) {
    return 'Apri $host';
  }

  @override
  String get attractionVisitWikidata => 'Apri wikidata.org';

  @override
  String get attractionOpenInMaps => 'Apri in Mappe';

  @override
  String get attractionOpenLink => 'Apri link';

  @override
  String get attractionOpenWebsite => 'Apri sito ufficiale';

  @override
  String get attractionShareChat => 'Condividi in chat';

  @override
  String get attractionShareGroup => 'Condividi nel gruppo';

  @override
  String get attractionDescribedAt => 'Scopri di più';

  @override
  String get attractionReport => 'Segnala evento';

  @override
  String get attractionReportConfirm =>
      'Segnalare questo elemento come inappropriato o errato?';

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
  String get exploreTitle => 'Esplora';

  @override
  String get communityTabTitle => 'Community';

  @override
  String exploreHeadline(String city) {
    return 'Esplora $city';
  }

  @override
  String get exploreSubtitle =>
      'Esperienze culturali e partner linguistici vicino a te';

  @override
  String get explorePracticeLanguage => 'Pratica una lingua';

  @override
  String get exploreNetworkDiscovery => 'Scopri la rete';

  @override
  String exploreNetworkDiscoverySubtitle(String country) {
    return 'Persone con cui connetterti in $country';
  }

  @override
  String get exploreSeeAll => 'Vedi tutto';

  @override
  String get explorePromotedBadge => 'Promosso';

  @override
  String get exploreHappeningThisWeek => 'Questa settimana';

  @override
  String get exploreHappeningToday => 'Oggi';

  @override
  String get exploreJoin => 'Partecipa';

  @override
  String get exploreFeatured => 'Esperienza in evidenza';

  @override
  String exploreSpeaksLearning(String speaks, String learning) {
    return 'parla $speaks · sta imparando $learning';
  }

  @override
  String exploreSpeaks(String language) {
    return 'parla $language';
  }

  @override
  String get exploreAroundYou => 'Scopri nuove persone';

  @override
  String get exploreSameInterests => 'Persone con i tuoi stessi interessi';

  @override
  String get exploreBusinessAccounts => 'Account aziendali';

  @override
  String exploreSpeaksLanguage(String language) {
    return 'Persone che parlano $language';
  }

  @override
  String get exploreCommunityEventsNearby =>
      'Eventi della community vicino a te';

  @override
  String get exploreNoPartners =>
      'Ancora nessun partner linguistico nelle vicinanze — torna presto.';

  @override
  String get exploreNoEvents =>
      'Ancora nessuna esperienza da mostrare — torna presto.';

  @override
  String get exploreNoCommunities =>
      'Ancora nessuna community da unirti — torna presto.';

  @override
  String exploreGoingCount(int count) {
    return '$count partecipanti';
  }

  @override
  String get exploreFeaturedEvents => 'Eventi in evidenza';

  @override
  String get exploreFeaturedAttractions => 'Attrazioni in evidenza';

  @override
  String get exploreTopExperiences => 'Esperienze top';

  @override
  String get exploreMyNextEvents => 'I miei prossimi eventi';

  @override
  String get exploreCommunitiesTitle => 'Community a cui unirti';

  @override
  String exploreMembersCount(int count) {
    return '$count membri';
  }

  @override
  String get exploreCountrySpotlight => 'Paese in evidenza';

  @override
  String get greetingMorning => 'Buongiorno';

  @override
  String get greetingAfternoon => 'Buon pomeriggio';

  @override
  String get greetingEvening => 'Buonasera';

  @override
  String get greetingNight => 'Buonanotte';

  @override
  String get statCoins => 'Monete';

  @override
  String get statTier => 'Livello';

  @override
  String get statCountries => 'Paesi';

  @override
  String get statPeople => 'Persone';

  @override
  String get networkWorldMap => 'Rete mondiale';

  @override
  String get discoveryShowPeople => 'Mostra persone';

  @override
  String get discoveryShowBusinesses => 'Mostra attivita';

  @override
  String networkDiscoveryDistanceKm(String distance) {
    return 'a $distance km';
  }

  @override
  String get connectAction => 'Connetti';

  @override
  String get connectError => 'Impossibile avviare la chat. Riprova.';

  @override
  String get sayHiAction => 'Saluta';

  @override
  String get newConnectionLabel => 'Nuova connessione';

  @override
  String get connectionsTitle => 'Connessioni';

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
    return 'Impossibile salvare le preferenze: $error';
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
  String get filterNotReplied => 'Non letto';

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
  String get gamificationMonthly => 'Mese';

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
  String get gamificationYearly => 'Anno';

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
  String get itsAMatch => 'Inizia a connetterti!';

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
  String get leaderboardSubtitle => 'Classifiche globali e regionali';

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
  String get letsExchange => 'Inizia a connetterti!';

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
  String get matchDetailsTitle => 'Dettagli Scambio';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Tu e $name volete scambiare le lingue!';
  }

  @override
  String get matchNotifKeepSwiping => 'Continua a Swipare';

  @override
  String get matchNotifLetsChat => 'Chattiamo!';

  @override
  String get matchNotifLetsExchange => 'INIZIA A CONNETTERTI!';

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
  String get discoverWorldwideTitle => 'Amplia i tuoi orizzonti!';

  @override
  String get discoverWorldwideMessage =>
      'Non ci sono ancora molte persone nella tua zona, ma GreenGo ti connette con persone in tutto il mondo! Vai ai Filtri e aggiungi altri paesi per scoprire persone fantastiche da ogni angolo del pianeta.';

  @override
  String get openFilters => 'Apri Filtri';

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
  String get membershipDailyLikes => 'Connessioni Giornaliere';

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
  String get couponRedeemTitle => 'Riscatta codice coupon';

  @override
  String get referralCodeTitle => 'Hai un codice di invito?';

  @override
  String get referralCodeLabel => 'Codice di invito (facoltativo)';

  @override
  String get referralCodeHint => 'Inserisci il codice di un amico';

  @override
  String get couponApplyButton => 'Applica';

  @override
  String get couponAppliedSuccess => 'Coupon applicato';

  @override
  String get couponNotValid => 'Coupon non valido';

  @override
  String get freeBaseWeekInfo => 'Niente coupon? 1 settimana di Base gratis!';

  @override
  String get couponRedeemSubtitle =>
      'Inserisci il tuo codice per aggiornare l\'abbonamento o ottenere monete gratis';

  @override
  String get couponRedeemButton => 'Riscatta coupon';

  @override
  String couponRedeemedSuccess(String grantSummary) {
    return 'Riscattato: $grantSummary';
  }

  @override
  String get couponErrorInvalid => 'Questo codice coupon non è valido';

  @override
  String get couponErrorExpired => 'Questo coupon è scaduto';

  @override
  String get couponErrorMaxUsesReached =>
      'Questo coupon ha raggiunto il suo limite di utilizzo';

  @override
  String get couponErrorEmailMismatch =>
      'Questo coupon è riservato a un altro account';

  @override
  String get couponErrorAlreadyRedeemed => 'Hai già utilizzato questo coupon';

  @override
  String get couponErrorDisabled => 'Questo coupon non è più attivo';

  @override
  String get couponErrorGeneric => 'Impossibile riscattare il coupon. Riprova.';

  @override
  String get registerCouponLabel => 'Codice coupon (opzionale)';

  @override
  String get registerCouponHint => 'Inserisci un codice coupon';

  @override
  String get welcomeGrantTitle => 'Benvenuto su GreenGo!';

  @override
  String get welcomeGrantDismiss => 'Capito';

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
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get subscriptionAutoRenewInfo =>
      'Si rinnova automaticamente salvo disdetta 24 h prima della fine del periodo. Gestisci nell\'account dello store.';

  @override
  String get subscriptionFreeTrialInfo =>
      'Nuovi abbonati: 7 giorni gratis, poi si rinnova al prezzo indicato. Disdici 24 h prima.';

  @override
  String get purchasesRestored => 'Acquisti ripristinati.';

  @override
  String get membershipExtendTitle => 'Estendi la tua iscrizione';

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
  String get membershipActive => 'Attivo';

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
  String get membershipExtendDescription =>
      'La tua iscrizione base è attiva. Acquista un altro anno per estendere la data di scadenza.';

  @override
  String get membershipRewinds => 'Ripristini';

  @override
  String membershipSavePercent(Object percent) {
    return 'RISPARMIA $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Vedi chi si connette';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Acquista una volta, goditi le funzionalità premium per 1 mese o 1 anno';

  @override
  String get membershipSuperLikes => 'Connessioni Prioritarie';

  @override
  String get membershipSuperLikesLabel =>
      'Connessioni Prioritarie/Giorno (vuoto = illimitati)';

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
  String get menu => 'Menu';

  @override
  String socialLinkInvalid(String platform) {
    return 'Inserisci un link o un nome utente valido per $platform';
  }

  @override
  String get messages => 'Scambi';

  @override
  String get messagesTabMessages => 'Messaggi';

  @override
  String get messagesTabGroups => 'Gruppi';

  @override
  String get messagesTabBusiness => 'Business';

  @override
  String get messagesBusinessEmpty => 'Ancora nessuna richiesta alla vetrina';

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
  String nicknameSearchActionNope(String nickname) {
    return 'Hai appena selezionato \"No\" per @$nickname';
  }

  @override
  String nicknameSearchActionSkip(String nickname) {
    return 'Hai appena selezionato \"Salta\" per @$nickname';
  }

  @override
  String nicknameSearchActionPriorityConnect(String nickname) {
    return 'Hai appena selezionato \"Connessione Prioritaria\" per @$nickname';
  }

  @override
  String nicknameSearchActionConnect(String nickname) {
    return 'Hai appena selezionato \"Connettiamoci\" per @$nickname';
  }

  @override
  String nicknameSearchActionMatch(String nickname) {
    return 'È un match con @$nickname!';
  }

  @override
  String nicknameSearchLimitReached(String action) {
    return 'Hai raggiunto il tuo limite di $action. Riprova più tardi.';
  }

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
      'Attiva le notifiche per sapere quando ricevi match, messaggi e connessioni prioritarie.';

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
  String get notificationCategories => 'Categorie di notifica';

  @override
  String get notificationCatExchanges => 'Chat di scambio';

  @override
  String get notificationCatExchangesSubtitle =>
      'Messaggi dalle tue conversazioni 1:1';

  @override
  String get notificationCatGroups => 'Chat di gruppo';

  @override
  String get notificationCatGroupsSubtitle =>
      'Messaggi nelle tue chat di gruppo';

  @override
  String get notificationCatBusiness => 'Chat aziendali';

  @override
  String get notificationCatBusinessSubtitle =>
      'Messaggi dalle attività che contatti';

  @override
  String get notificationCatEventsChat => 'Chat degli eventi';

  @override
  String get notificationCatEventsChatSubtitle =>
      'Messaggi negli eventi a cui partecipi';

  @override
  String get notificationCatCommunityChat => 'Chat della community';

  @override
  String get notificationCatCommunityChatSubtitle =>
      'Messaggi nella chat della community';

  @override
  String get notificationCatAnnouncements => 'Annunci ed eventi';

  @override
  String get notificationCatAnnouncementsSubtitle =>
      'Annunci ed eventi della community';

  @override
  String get notificationCatTips => 'Consigli';

  @override
  String get notificationCatTipsSubtitle =>
      'Consigli e suggerimenti della community';

  @override
  String get notificationCatMessages => 'Messaggi';

  @override
  String get notificationCatMessagesSubtitle =>
      'Chat dirette, di gruppo, business ed eventi';

  @override
  String get notificationCatEvents => 'Eventi';

  @override
  String get notificationCatEventsSubtitle =>
      'Eventi, promemoria, adesioni e avvisi città';

  @override
  String get notificationCatCommunities => 'Community';

  @override
  String get notificationCatCommunitiesSubtitle => 'Annunci e nuovi membri';

  @override
  String get notificationCatSocial => 'Social';

  @override
  String get notificationCatSocialSubtitle =>
      'Visualizzazioni del profilo, follower, valutazioni e boost';

  @override
  String get notificationCatAccount => 'Account';

  @override
  String get notificationCatAccountSubtitle =>
      'Verifica e aggiornamenti importanti dell\'account';

  @override
  String get notificationEventCities => 'Eventi della community per città';

  @override
  String get notificationEventCitiesSubtitle =>
      'Ricevi una notifica quando ci sono eventi in queste città';

  @override
  String get notificationAddCity => 'Aggiungi una città';

  @override
  String get notificationAddCityHint => 'es. Roma';

  @override
  String get notificationNoCities =>
      'Ancora nessuna città — aggiungine una per ricevere avvisi sugli eventi';

  @override
  String get notificationEnableInSettingsBody =>
      'Le notifiche sono disattivate. Attivale nelle Impostazioni per ricevere messaggi, eventi e avvisi della community.';

  @override
  String get notificationOpenSettings => 'Apri Impostazioni';

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
    return 'Hai ricevuto una connessione prioritaria da @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Connessioni Prioritarie';

  @override
  String get notificationSuperLikesSubtitle =>
      'Quando qualcuno si connette prioritariamente con te';

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
  String get onboardingMinLocation => 'Imposta la tua posizione per continuare';

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
  String get personalStatistics => 'Statistiche personali';

  @override
  String get personalStatisticsSubtitle =>
      'Grafici, obiettivi e progressi linguistici';

  @override
  String get personalStatsActivity => 'Attività recente';

  @override
  String get personalStatsChatStats => 'Statistiche chat';

  @override
  String get personalStatsConversations => 'Conversazioni';

  @override
  String get personalStatsGoalsAchieved => 'Obiettivi raggiunti';

  @override
  String get personalStatsLevel => 'Livello';

  @override
  String get personalStatsLanguage => 'Lingua';

  @override
  String get personalStatsTotal => 'Totale';

  @override
  String get personalStatsNextLevel => 'Prossimo livello';

  @override
  String get personalStatsNoActivityYet => 'Nessuna attività registrata';

  @override
  String get personalStatsNoWordsYet =>
      'Inizia a chattare per scoprire nuove parole';

  @override
  String get personalStatsTotalMessages => 'Messaggi inviati';

  @override
  String get personalStatsWordsDiscovered => 'Parole scoperte';

  @override
  String get personalStatsWordsLearned => 'Parole Imparate';

  @override
  String get personalStatsXpOverview => 'Panoramica XP';

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
  String get photoPrivateAlbumSuggestion =>
      'Puoi caricare questa foto nel tuo album privato, dove la vedono solo le persone a cui dai accesso.';

  @override
  String get photoUploadDeniedNudity =>
      'Caricamento negato - violazione: nudita. Le foto del profilo pubblico devono ritrarre persone completamente vestite.';

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
  String get preferenceLanguageFilter => 'Lingua';

  @override
  String get preferenceLanguageFilterDesc =>
      'Mostra solo le persone che parlano una lingua specifica';

  @override
  String get preferenceAnyLanguage => 'Qualsiasi lingua';

  @override
  String get preferenceInterestFilter => 'Interessi';

  @override
  String get preferenceInterestFilterDesc =>
      'Mostra solo le persone che condividono i tuoi interessi';

  @override
  String get preferenceNoInterestFilter =>
      'Nessun filtro interessi — mostrando tutti';

  @override
  String get preferenceAddInterest => 'Aggiungi interesse';

  @override
  String get preferenceSearchInterest => 'Cerca interessi...';

  @override
  String get preferenceNoInterestsFound => 'Nessun interesse trovato';

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
  String get preferenceCountryRequired =>
      'Deve essere selezionato almeno un paese';

  @override
  String get preferenceByUsers => 'Per utenti';

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
  String get priorityConnectNotificationMessage =>
      'Qualcuno vuole connettersi con te!';

  @override
  String get priorityConnectNotificationTitle => 'Connessione Prioritaria!';

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
  String get profileProgressGrowth => 'Progressi e crescita';

  @override
  String get profileRestart => 'Riavvia';

  @override
  String get profileRestartDiscovery => 'Riavvia scoperta';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Questo cancellerà tutti i tuoi swipe (connessioni, rifiuti, connessioni prioritarie) in modo da poter riscoprire tutti da zero.\n\nI tuoi match e le chat NON saranno influenzati.';

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
  String get profileReauthProviderMismatch =>
      'Questo account e stato creato con un accesso social (es. Google), quindi non c e una password da confermare qui. Eliminalo dall account con cui hai effettuato l accesso o contatta l assistenza.';

  @override
  String get profileTooManyAttempts =>
      'Troppi tentativi. Per sicurezza questo dispositivo e temporaneamente bloccato — attendi qualche minuto e riprova.';

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
    return '$remaining $type rimasti oggi';
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
  String get secondChanceMatchTitle => 'Inizia a connetterti!';

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
  String get shopDailyLikes => 'Connessioni Giornaliere';

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
  String get shopSeeWhoLikesYou => 'Vedi chi si connette';

  @override
  String get shopSend => 'Invia';

  @override
  String get shopSendCoins => 'Invia monete';

  @override
  String get shopStoreNotAvailable =>
      'Negozio non disponibile. Controlla le impostazioni del dispositivo.';

  @override
  String get shopTemporarilyUnavailable =>
      'Gli acquisti non sono al momento disponibili. Riprova più tardi.';

  @override
  String get shopSuperLikes => 'Connessioni Prioritarie';

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
  String get superLike => 'Connessione Prioritaria';

  @override
  String superLikedYou(String name) {
    return '$name si è connesso prioritariamente con te!';
  }

  @override
  String get superLikes => 'Connessioni Prioritarie';

  @override
  String get supportCenter => 'Centro Supporto';

  @override
  String get supportCenterSubtitle =>
      'Ottieni aiuto, segnala problemi, contattaci';

  @override
  String get swipeIndicatorLike => 'CONNETTI';

  @override
  String get swipeIndicatorNope => 'PASSA';

  @override
  String get swipeIndicatorSkip => 'ESPLORA';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITARIO';

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
  String get trialWelcomeTitle => 'Benvenuto su GreenGo!';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'Stai utilizzando la versione di prova. La tua iscrizione base gratuita è attiva fino al $expirationDate. Buona esplorazione su GreenGo!';
  }

  @override
  String get trialWelcomeButton => 'Inizia';

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
  String get verificationPrivacyTitle => 'I tuoi dati sono al sicuro con noi';

  @override
  String get verificationPrivacyEncryption =>
      'Tutti i documenti sono protetti con crittografia end-to-end. Nemmeno gli ingegneri di GreenGo possono accedere ai tuoi dati.';

  @override
  String get verificationPrivacyAccess =>
      'Le tue informazioni sono accessibili solo tramite una tua richiesta personale attraverso i canali ufficiali o via email.';

  @override
  String get verificationPrivacySafety =>
      'Questo passaggio è essenziale per proteggere tutti i membri. Ti invitiamo a segnalare qualsiasi comportamento sospetto e lasciare che GreenGo intervenga.';

  @override
  String get verificationPrivacyReporting =>
      'Se succede qualcosa, segnalalo immediatamente. GreenGo indagherà e agirà per mantenere la community sicura.';

  @override
  String get verificationChooseMethod => 'Scegli il tuo metodo di verifica';

  @override
  String get verificationMethodPhoto => 'Documento d\'identità';

  @override
  String get verificationMethodPhotoDesc =>
      'Scatta una foto tenendo il tuo documento accanto al viso';

  @override
  String get verificationMethodPhone => 'Numero di telefono';

  @override
  String get verificationMethodPhoneDesc =>
      'Verifica tramite codice SMS inviato al tuo telefono';

  @override
  String get verificationPhoneTitle => 'Verifica telefonica';

  @override
  String get verificationPhoneSubtitle =>
      'Inserisci il tuo numero di telefono per ricevere un codice di verifica via SMS';

  @override
  String get verificationPhoneLabel => 'Numero di telefono';

  @override
  String get verificationPhoneHint => '+1 234 567 8900';

  @override
  String get verificationSendCode => 'Invia codice';

  @override
  String get verificationEnterCode =>
      'Inserisci il codice a 6 cifre inviato al tuo telefono';

  @override
  String get verificationCodeLabel => 'Codice di verifica';

  @override
  String get verificationVerifyCode => 'Verifica codice';

  @override
  String get verificationPhoneSuccess =>
      'Numero di telefono verificato con successo!';

  @override
  String get verificationPhoneResponsibility =>
      'Verificando con il tuo numero di telefono, riconosci che il proprietario di questo numero è personalmente responsabile di tutte le azioni eseguite su questo account.';

  @override
  String get verificationResendCode => 'Invia di nuovo il codice';

  @override
  String verificationCodeSent(String phoneNumber) {
    return 'Codice inviato a $phoneNumber';
  }

  @override
  String get verificationPhoneError =>
      'Verifica del numero di telefono non riuscita. Riprova.';

  @override
  String get verificationInvalidCode =>
      'Codice non valido. Controlla e riprova.';

  @override
  String get verificationOr => 'oppure';

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
  String get voiceMicPermissionDenied =>
      'È necessario l\'accesso al microfono per registrare la tua presentazione vocale';

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
  String get voiceMessageTooShort =>
      'Tieni premuto per registrare, rilascia per inviare';

  @override
  String get voiceSlideToCancel => '‹ Scorri per annullare';

  @override
  String get voiceReleaseToCancel => 'Rilascia per annullare';

  @override
  String get voiceFailedToSend => 'Invio del messaggio vocale non riuscito';

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
  String get waitingCountdownLabel => 'La tua data di lancio';

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
  String get waitingExclusiveAccess => 'Tempo rimanente per poter usare l\'app';

  @override
  String get waitingGeneralLaunchDate => 'Data di lancio generale';

  @override
  String get waitingYourAccessDate => 'La tua data di accesso';

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
  String get yearlyMembership => 'Abbonamento annuale';

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
  String get youGotSuperLike => 'Hai ricevuto una Connessione Prioritaria!';

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

  @override
  String get achievementBadges => 'Badge dei Traguardi';

  @override
  String get achievementBadgesSubtitle =>
      'Tocca per selezionare quali badge mostrare sul tuo profilo (max 5)';

  @override
  String get noBadgesYet => 'Sblocca traguardi per guadagnare badge!';

  @override
  String get guideTitle => 'Come funziona GreenGo';

  @override
  String get guideSwipeTitle => 'Scorrere i profili';

  @override
  String get guideSwipeItem1 =>
      'Scorri a destra per Connect con qualcuno, scorri a sinistra per Nope.';

  @override
  String get guideSwipeItem2 =>
      'Scorri verso l\'alto per inviare un Priority Connect (usa monete).';

  @override
  String get guideSwipeItem3 =>
      'Scorri verso il basso per Explore Next e salta un profilo per ora.';

  @override
  String get guideSwipeItem4 =>
      'Puoi passare dalla modalità scorrimento alla modalità griglia usando l\'icona di commutazione nella barra superiore.';

  @override
  String get guideGridTitle => 'Vista a griglia';

  @override
  String get guideGridItem1 =>
      'Sfoglia i profili in una disposizione a griglia per una panoramica rapida.';

  @override
  String get guideGridItem2 =>
      'Tocca un\'immagine del profilo per mostrare i quattro pulsanti di azione: Connect, Priority Connect, Nope ed Explore Next.';

  @override
  String get guideGridItem3 =>
      'Tieni premuto su un\'immagine del profilo per vedere i dettagli senza aprire il profilo completo.';

  @override
  String get guideConnectionsTitle => 'Connettersi con le persone';

  @override
  String get guideConnectionsItem1 =>
      'Quando due persone fanno Connect a vicenda, è un match!';

  @override
  String get guideConnectionsItem2 =>
      'Dopo il match, puoi iniziare a chattare subito.';

  @override
  String get guideConnectionsItem3 =>
      'Usa Priority Connect per distinguerti e aumentare le tue possibilità.';

  @override
  String get guideConnectionsItem4 =>
      'Controlla la scheda Scambi per vedere tutti i tuoi match e le conversazioni.';

  @override
  String get guideChatTitle => 'Chat e messaggistica';

  @override
  String get guideChatItem1 => 'Invia messaggi di testo, foto e note vocali.';

  @override
  String get guideChatItem2 =>
      'Usa la funzione di traduzione per chattare in diverse lingue.';

  @override
  String get guideChatItem3 =>
      'Apri le impostazioni della chat per personalizzare la tua esperienza: attiva il controllo grammaticale, le risposte intelligenti, i consigli culturali, la scomposizione delle parole, l\'aiuto alla pronuncia e altro ancora.';

  @override
  String get guideChatItem4 =>
      'Attiva la sintesi vocale per ascoltare le traduzioni, mostrare le bandiere delle lingue e monitorare i tuoi XP di apprendimento linguistico.';

  @override
  String get guideFiltersTitle => 'Filtri di scoperta';

  @override
  String get guideFiltersItem1 =>
      'Tocca l\'icona del filtro per impostare le tue preferenze: fascia d\'età, distanza, lingue e altro.';

  @override
  String get guideFiltersItem2 =>
      'Modalità Casuale: attiva questo interruttore per scoprire persone casuali da tutto il mondo. Ogni aggiornamento ti mostra un nuovo gruppo di profili. Quando la Modalità Casuale è disattivata, vengono mostrate solo le persone vicine a te. Puoi anche selezionare paesi specifici per restringere la ricerca.';

  @override
  String get guideFiltersItem3 =>
      'I filtri ti aiutano a trovare persone che corrispondono a ciò che cerchi. Puoi modificarli in qualsiasi momento.';

  @override
  String get guideTravelTitle => 'Viaggi ed esplorazione';

  @override
  String get guideTravelItem1 =>
      'Attiva la Modalità Viaggiatore per apparire nella scoperta di una città che intendi visitare per 24 ore.';

  @override
  String get guideTravelItem2 =>
      'Le guide locali possono aiutare i viaggiatori a scoprire la loro città e cultura.';

  @override
  String get guideTravelItem3 =>
      'I partner di scambio linguistico vengono abbinati in base a ciò che parli e a ciò che vuoi imparare.';

  @override
  String get guideMembershipTitle => 'Abbonamento base';

  @override
  String get guideMembershipItem1 =>
      'Il tuo abbonamento base ti dà accesso a tutte le funzionalità principali: scorrere, chattare e fare match.';

  @override
  String get guideMembershipItem2 =>
      'L\'abbonamento inizia con una prova gratuita dopo la prima registrazione.';

  @override
  String get guideMembershipItem3 =>
      'Quando il tuo abbonamento scade, puoi rinnovarlo per continuare a usare l\'app.';

  @override
  String get guideTiersTitle => 'Livelli VIP (Argento, Oro, Platino)';

  @override
  String get guideTiersItem1 =>
      'Argento: Ottieni più connect giornalieri, vedi chi ha fatto Connect con te e supporto prioritario.';

  @override
  String get guideTiersItem2 =>
      'Oro: Tutto ciò che è in Argento più connect illimitati, filtri avanzati e conferme di lettura.';

  @override
  String get guideTiersItem3 =>
      'Platino: Tutto ciò che è in Oro più boost del profilo, migliori scelte e funzionalità esclusive.';

  @override
  String get guideTiersItem4 =>
      'I livelli VIP sono indipendenti dal tuo abbonamento base e offrono vantaggi extra.';

  @override
  String get guideCoinsTitle => 'Monete';

  @override
  String get guideCoinsItem1 =>
      'Le monete vengono usate per le azioni premium. Ecco i costi:';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect: 10 monete  • Boost: 50 monete  • Messaggio diretto: 2/giorno gratis, poi 50 monete';

  @override
  String get guideCoinsItem3 =>
      '• Incognito: 30 monete/giorno  • Viaggiatore: 100 monete/giorno';

  @override
  String get guideCoinsItem4 =>
      '• Ascolta (TTS): 5 monete  • Estendi griglia: 10 monete  • Coach di apprendimento: 10 monete/sessione';

  @override
  String get guideCoinsItem5 =>
      'Ricevi 20 monete gratis al giorno. Guadagna di più con traguardi, classifiche e il Negozio.';

  @override
  String get guideLeaderboardTitle => 'Classifica';

  @override
  String get guideLeaderboardItem1 =>
      'Competi con altri utenti per scalare la classifica e guadagnare ricompense.';

  @override
  String get guideLeaderboardItem2 =>
      'Guadagna punti essendo attivo, completando il tuo profilo e interagendo con gli altri.';

  @override
  String get guideGridFiltersTitle => 'Filtri griglia';

  @override
  String get guideGridFiltersItem1 =>
      'In modalità griglia, usa i chip filtro in alto per restringere i profili.';

  @override
  String get guideGridFiltersItem2 =>
      'Tutti: Mostra tutti nel tuo gruppo di scoperta.';

  @override
  String get guideGridFiltersItem3 =>
      'Connessi: Persone a cui hai inviato una richiesta di connessione.';

  @override
  String get guideGridFiltersItem4 =>
      'Prioritario: Persone a cui hai inviato una Connessione Prioritaria.';

  @override
  String get guideGridFiltersItem5 =>
      'Rifiutati: Persone che hai scelto di saltare.';

  @override
  String get guideGridFiltersItem6 =>
      'Viaggiatori: Persone con la Modalità Viaggiatore attiva, in visita in una città vicino a te.';

  @override
  String get guideExchangesTitle => 'Scambi (Chat)';

  @override
  String get guideExchangesItem1 =>
      'Gli Scambi sono dove si trovano tutte le tue conversazioni. Li trovi nel menu in basso.';

  @override
  String get guideExchangesItem2 =>
      'Il badge rosso sull\'icona Scambi mostra il numero di conversazioni con messaggi non letti o approvazioni in sospeso.';

  @override
  String get guideExchangesItem3 =>
      'Usa i filtri per organizzare le tue chat: Tutti, Nuovi, Senza risposta, Preferiti, Da approvare, Match e Ricerca.';

  @override
  String get guideExchangesItem4 =>
      'Nuovi mostra le conversazioni con nuovi messaggi non letti. Senza risposta mostra i messaggi a cui non hai ancora risposto.';

  @override
  String get guideExchangesItem5 =>
      'Da approvare mostra le richieste di Connessione Prioritaria in attesa della tua decisione. Accettale o rifiutale direttamente dalla lista.';

  @override
  String get guideExchangesItem6 =>
      'Le conversazioni non lette sono evidenziate con testo in grassetto e un effetto dorato luccicante per trovarle facilmente.';

  @override
  String get guideExchangesItem7 =>
      'Tocca una conversazione per aprire la chat. Una volta aperta, viene segnata come letta e il conteggio del badge diminuisce.';

  @override
  String get guideExchangesItem8 =>
      'Tieni premuta una conversazione per altre opzioni. Usa l\'icona stella per aggiungere una chat ai tuoi Preferiti.';

  @override
  String get guideExchangesItem9 =>
      'Ogni conversazione mostra le bandiere linguistiche dell\'altro utente, così sai quali lingue parla.';

  @override
  String get guideGroupsTitle => 'Gruppi (Culture Circles)';

  @override
  String get guideGroupsItem1 =>
      'Crea un gruppo per chattare con più persone contemporaneamente attorno a un interesse o una lingua comune.';

  @override
  String get guideGroupsItem2 =>
      'Gli amministratori possono rinominare il gruppo, cambiarne la foto e aggiungere o rimuovere membri.';

  @override
  String get guideGroupsItem3 =>
      'Invita persone tramite il loro soprannome dalle info del gruppo.';

  @override
  String get guideGroupsItem4 =>
      'Aggiungi i tuoi tag privati a un gruppo nelle info del gruppo, poi filtra la lista dei gruppi per tag — solo tu vedi i tuoi tag.';

  @override
  String get guideGroupsItem5 =>
      'Esci o segnala un gruppo in qualsiasi momento.';

  @override
  String get guideEventsTitle => 'Eventi';

  @override
  String get guideEventsItem1 =>
      'Scopri eventi vicino a te — feste, visite ai musei, incontri linguistici e tour della città.';

  @override
  String get guideEventsItem2 =>
      'Sfoglia esperienze e attrazioni selezionate, o crea il tuo evento con foto, luogo e data.';

  @override
  String get guideEventsItem3 =>
      'Segna gli eventi come Partecipo o Interessato e ritrovali nella scheda Partecipo.';

  @override
  String get guideEventsItem4 =>
      'Ogni evento ha la propria chat; gli organizzatori possono inviare annunci a tutti i partecipanti.';

  @override
  String get guideEventsItem5 =>
      'Condividi qualsiasi evento in una chat privata o in un gruppo.';

  @override
  String get guideEventsItem6 =>
      'Esplora eventi in tutto il mondo sulla mappa, per posizione.';

  @override
  String get guideSafetyTitle => 'Sicurezza e privacy';

  @override
  String get guideSafetyItem1 =>
      'Tutte le foto sono verificate dall\'IA per garantire profili autentici.';

  @override
  String get guideSafetyItem2 =>
      'Puoi bloccare o segnalare qualsiasi utente in qualsiasi momento dal suo profilo.';

  @override
  String get guideSafetyItem3 =>
      'Le tue informazioni personali sono protette e non vengono mai condivise senza il tuo consenso.';

  @override
  String get firstStepsTitle => 'Primi passi';

  @override
  String get firstStepsReview =>
      'I tuoi documenti saranno esaminati entro 24-48 ore dall\'invio.';

  @override
  String get firstStepsStatusUpdate =>
      'L\'app impiega circa 15 minuti per aggiornare il tuo stato attuale dopo il primo accesso.';

  @override
  String get firstStepsSupportChat =>
      'Puoi contattare l\'assistenza tramite chat o aprendo direttamente un ticket.';

  @override
  String get showSupportUser => 'Mostra Assistenza GreenGo';

  @override
  String get showSupportUserDescription =>
      'Mostra l\'utente Assistenza GreenGo nella griglia di scoperta';

  @override
  String get preferenceShowMyNetwork => 'La Mia Rete';

  @override
  String get preferenceShowMyNetworkDesc =>
      'Mostra solo le persone della tua rete.';

  @override
  String get randomMode => 'Modalità casuale';

  @override
  String get randomModeDescription =>
      'Scopri persone casuali da tutto il mondo, ordinate per distanza. Se disattivata, vengono mostrate solo le persone vicine a te.';

  @override
  String get yourProfile => 'Tu';

  @override
  String get loadingMsg1 =>
      'Alla ricerca di profili fantastici in tutto il mondo...';

  @override
  String get loadingMsg2 => 'Connettere cuori attraverso i continenti...';

  @override
  String get loadingMsg3 => 'Scoprire persone incredibili vicino a te...';

  @override
  String get loadingMsg4 => 'Preparare le tue corrispondenze personalizzate...';

  @override
  String get loadingMsg5 => 'Esplorare profili da ogni angolo del mondo...';

  @override
  String get loadingMsg6 =>
      'Trovare persone che condividono i tuoi interessi...';

  @override
  String get loadingMsg7 => 'Configurare la tua esperienza di scoperta...';

  @override
  String get loadingMsg8 => 'Caricare bellissimi profili solo per te...';

  @override
  String get loadingMsg9 => 'Alla ricerca del tuo match perfetto...';

  @override
  String get loadingMsg10 => 'Avvicinare il mondo a te...';

  @override
  String get loadingMsg11 =>
      'Selezionare profili in base alle tue preferenze...';

  @override
  String get loadingMsg12 =>
      'Quasi fatto! Le cose belle richiedono un momento...';

  @override
  String get loadingMsg13 => 'Connetterti a un mondo di possibilità...';

  @override
  String get loadingMsg14 =>
      'Trovare le migliori corrispondenze nella tua zona...';

  @override
  String get loadingMsg15 => 'Sbloccare nuove connessioni intorno a te...';

  @override
  String get loadingMsg16 =>
      'La tua prossima grande conversazione è a un swipe di distanza...';

  @override
  String get loadingMsg17 => 'Raccogliere profili da tutto il mondo...';

  @override
  String get loadingMsg18 => 'Preparare qualcosa di speciale per te...';

  @override
  String get loadingMsg19 => 'Assicurarsi che tutto sia perfetto...';

  @override
  String get loadingMsg20 => 'L\'amore non conosce confini, e nemmeno noi...';

  @override
  String get loadingMsg21 => 'Riscaldare il tuo feed di scoperta...';

  @override
  String get loadingMsg22 =>
      'Scansionare il globo alla ricerca di persone interessanti...';

  @override
  String get loadingMsg23 => 'Le grandi connessioni iniziano qui...';

  @override
  String get loadingMsg24 => 'La tua avventura sta per iniziare...';

  @override
  String get filterFavorites => 'Preferiti';

  @override
  String get filterToApprove => 'Da approvare';

  @override
  String get priorityConnectAccept => 'Accetta';

  @override
  String get priorityConnectReject => 'Rifiuta';

  @override
  String get priorityConnectPending => 'In attesa di approvazione';

  @override
  String get membershipTrialTitle => 'Inizia la tua prova gratuita!';

  @override
  String get membershipTrialSubtitle => '7 giorni gratis, poi rinnovo annuale';

  @override
  String get membershipTrialFeature1 =>
      'Crea community, eventi e gruppi illimitati';

  @override
  String get membershipTrialFeature2 => 'Senza pubblicita — nessun annuncio';

  @override
  String get membershipTrialFeature3 =>
      '500 monete bonus + accesso completo a tutto';

  @override
  String get membershipHaveCoupon => 'Hai un codice coupon?';

  @override
  String get membershipTrialCta => 'Inizia la prova di 7 giorni';

  @override
  String get membershipTrialFooter =>
      'Disdici quando vuoi. Nessun addebito fino al giorno 8.';

  @override
  String get membershipTrialBadge => 'GRATIS PER 7 GIORNI';

  @override
  String get globeMyNetwork => 'La mia rete';

  @override
  String get globeMyWorldMap => 'La mia mappa del mondo';

  @override
  String get globeLayerContacts => 'La mia community';

  @override
  String get globeLayerExperiences => 'Esperienze';

  @override
  String get globeYou => 'Tu';

  @override
  String get globeConnections => 'Connessioni';

  @override
  String get globeTraveler => 'Viaggiatore';

  @override
  String globeConnectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'connessioni',
      one: 'connessione',
    );
    return '$count $_temp0';
  }

  @override
  String globeConnectionsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'connessioni',
      one: 'connessione',
    );
    return '$count $_temp0 qui';
  }

  @override
  String get globeThisIsYou => 'Questo sei tu!';

  @override
  String globeTravelingTo(String country) {
    return 'In viaggio verso $country';
  }

  @override
  String globeNoConnectionsInCountry(String country) {
    return 'Ancora nessuna connessione in $country';
  }

  @override
  String get globeNoConnectionsHint =>
      'Continua a connetterti per trovare persone qui!';

  @override
  String get globeProfile => 'Profilo';

  @override
  String get globeChat => 'Chat';

  @override
  String get globeViewProfileTooltip => 'Vedi profilo';

  @override
  String get globeOpenChatTooltip => 'Apri chat';

  @override
  String globeNoConnectionsInCountryTitle(String country) {
    return 'Nessuna connessione in $country';
  }

  @override
  String get discoverabilityExact => 'Esatta';

  @override
  String get discoverabilityExactDesc =>
      'Segnaposto nella tua posizione esatta (<1km)';

  @override
  String get discoverabilityApproximate => 'Approssimativa';

  @override
  String get discoverabilityApproximateDesc =>
      'Segnaposto nella tua regione (griglia ~50km, predefinito)';

  @override
  String get discoverabilityCountry => 'Paese';

  @override
  String get discoverabilityCountryDesc =>
      'Segnaposto da qualche parte nel tuo paese';

  @override
  String get discoverabilityHidden => 'Nascosta';

  @override
  String get discoverabilityHiddenDesc => 'Non individuabile sulla Mappa';

  @override
  String get discoverabilityTitle => 'Individuabilità sul globo';

  @override
  String get discoverabilityInfo =>
      'Le tue connessioni ti vedono sempre sulla Mappa, indipendentemente da questa impostazione.';

  @override
  String get discoverabilityChangedExact => 'Posizione impostata su esatta';

  @override
  String get discoverabilityChangedApproximate =>
      'Posizione impostata su approssimativa';

  @override
  String get discoverabilityChangedCountry =>
      'Posizione impostata a livello di paese';

  @override
  String get discoverabilityChangedHidden => 'Ora sei nascosto dalla mappa';

  @override
  String get onboardingExitTitle => 'Uscire dalla registrazione?';

  @override
  String get onboardingExitMessage =>
      'Verrai disconnesso. Potrai completare la configurazione del profilo al prossimo accesso.';

  @override
  String get onboardingExitConfirm => 'Esci';

  @override
  String get onboardingExitCancel => 'Annulla';

  @override
  String get loginEmailOrNickname => 'Email / Nickname';

  @override
  String get paymentVerifying => 'Verifica del pagamento in corso...';

  @override
  String get paymentSuccess => 'Pagamento riuscito!';

  @override
  String get paymentSuccessMessage =>
      'Il tuo acquisto è stato accreditato sul tuo account.';

  @override
  String get paymentPending => 'Elaborazione del pagamento';

  @override
  String get paymentPendingMessage =>
      'Il pagamento è in elaborazione. Potrebbero volerci alcuni minuti.';

  @override
  String get paymentCancelled => 'Pagamento annullato';

  @override
  String get paymentCancelledMessage =>
      'Il pagamento è stato annullato. Nessun addebito effettuato.';

  @override
  String get continueToApp => 'Continua';

  @override
  String get webCheckoutOpening => 'Apertura del pagamento sicuro…';

  @override
  String get webCheckoutWaiting =>
      'Completa il pagamento nella nuova scheda. Questa finestra si aggiornerà automaticamente al termine.';

  @override
  String get webCheckoutTimeout =>
      'Non siamo ancora riusciti a confermare il pagamento. Se l\'hai completato, il tuo saldo verrà aggiornato a breve.';

  @override
  String get webCheckoutFailed => 'Impossibile avviare il pagamento. Riprova.';

  @override
  String get groupNewGroup => 'Nuovo gruppo';

  @override
  String get groupCreate => 'Crea';

  @override
  String get groupNameLabel => 'Nome del gruppo';

  @override
  String groupSelectedCount(int count) {
    return '$count selezionati';
  }

  @override
  String get groupInviteByNickname => 'Invita per nickname';

  @override
  String get groupAddMembers => 'Aggiungi membri';

  @override
  String get groupTtsReadTranslated => 'Leggi ad alta voce la traduzione';

  @override
  String get groupTtsReadTranslatedHint =>
      'Tocca due volte un messaggio per ascoltarlo. Sì = la tua lingua, No = originale.';

  @override
  String get ttsNotEnoughCoins =>
      'Monete insufficienti per il TTS (servono 5 monete)';

  @override
  String get groupRemoveMember => 'Rimuovi membro';

  @override
  String groupRemoveMemberConfirm(String name) {
    return 'Rimuovere $name da questo gruppo?';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name rimosso';
  }

  @override
  String groupAddSelected(int count) {
    return 'Aggiungi $count selezionati';
  }

  @override
  String get groupNicknameHint => 'Inserisci un nickname';

  @override
  String get groupNoContacts => 'Ancora nessun contatto da aggiungere';

  @override
  String get groupNoOneFound => 'Nessuno trovato con quel nickname';

  @override
  String get groupAlreadyAdded => 'Già aggiunto';

  @override
  String groupAddedCount(int count) {
    return '$count aggiunti';
  }

  @override
  String get groupSearchFailed => 'Ricerca non riuscita';

  @override
  String get groupInfo => 'Info gruppo';

  @override
  String groupMembersCount(int count) {
    return '$count membri';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupYou => 'Tu';

  @override
  String get groupLeave => 'Esci dal gruppo';

  @override
  String get groupDelete => 'Elimina gruppo';

  @override
  String get groupDeleteConfirmTitle => 'Eliminare il gruppo?';

  @override
  String get groupDeleteConfirmBody =>
      'Questo elimina definitivamente il gruppo e tutti i suoi messaggi per tutti. Operazione irreversibile.';

  @override
  String get groupLeaveConfirmTitle => 'Uscire dal gruppo?';

  @override
  String get groupLeaveConfirmBody =>
      'Non riceverai più i messaggi di questo gruppo.';

  @override
  String get groupCancel => 'Annulla';

  @override
  String get groupLeaveAction => 'Esci';

  @override
  String get groupReport => 'Segnala gruppo';

  @override
  String get groupReportConfirmBody =>
      'Segnalare questo gruppo al nostro team di sicurezza?';

  @override
  String get groupReportAction => 'Segnala';

  @override
  String get groupReportSubmitted => 'Segnalazione inviata';

  @override
  String get groupMessageHint => 'Messaggio…';

  @override
  String get groupSayHello => 'Saluta il gruppo 👋';

  @override
  String get groupLoadError => 'Impossibile caricare questo gruppo';

  @override
  String get chatLocation => 'Posizione';

  @override
  String get chatShareLocation => 'Condividi posizione';

  @override
  String get chatLocationDenied =>
      'È necessaria l\'autorizzazione alla posizione per condividere la tua posizione';

  @override
  String get chatOpenInMaps => 'Apri in Mappe';

  @override
  String get eventsSearchHint => 'Cerca per paese, città o nome';

  @override
  String get eventsSortPopular => 'Popolari';

  @override
  String get eventsViewList => 'Vista elenco';

  @override
  String get eventsViewGrid => 'Vista griglia';

  @override
  String get eventViewEvent => 'Vedi evento';

  @override
  String get eventLoadError => 'Impossibile caricare questo evento';

  @override
  String get eventShare => 'Condividi evento';

  @override
  String get eventReport => 'Segnala evento';

  @override
  String get eventReportTitle => 'Segnalare questo evento?';

  @override
  String get eventReportBody =>
      'Il nostro team lo esaminerà. Non vedrai più questo evento.';

  @override
  String get eventReported => 'Evento segnalato';

  @override
  String get shareAsLink => 'Condividi come link';

  @override
  String get eventShared => 'Evento condiviso';

  @override
  String get eventShareEmpty =>
      'Ancora nessuna chat o gruppo con cui condividere';

  @override
  String get eventsUnlimitedAttendees => 'Partecipanti illimitati';

  @override
  String get eventsPrivateEvent => 'Evento privato';

  @override
  String get eventsExternalLinks => 'Link';

  @override
  String get eventsLinkUrlHint => 'https://…';

  @override
  String get eventsAddLink => 'Aggiungi link';

  @override
  String get tierLimitTitle => 'Esegui l\'upgrade per crearne di più';

  @override
  String tierLimitEventsBody(int max) {
    return 'Il tuo piano consente $max eventi. Esegui l\'upgrade per crearne di più.';
  }

  @override
  String tierLimitGroupsBody(int max) {
    return 'Il tuo piano consente $max gruppi. Esegui l\'upgrade per crearne di più.';
  }

  @override
  String get groupsTitle => 'Gruppi';

  @override
  String get profileRankingSubtitle => 'Vedi la classifica globale';

  @override
  String get eventBroadcastTooltip => 'Annuncia a tutti';

  @override
  String get eventBroadcastHint => 'Annuncio a tutti i partecipanti…';

  @override
  String get eventBroadcastLabel => 'Annuncio';

  @override
  String get eventsFeatured => 'In evidenza';

  @override
  String get eventsInsufficientCoins => 'Monete insufficienti';

  @override
  String get eventsConfirmAction => 'Conferma';

  @override
  String get eventsBoost => 'Metti in evidenza';

  @override
  String get eventsBoosted => 'Evento in evidenza!';

  @override
  String eventsJoinForCoins(int cost) {
    return 'Partecipare a questo evento per $cost monete?';
  }

  @override
  String eventsBoostConfirm(int cost) {
    return 'Mettere in evidenza questo evento per $cost monete per 7 giorni?';
  }

  @override
  String groupMemberLimit(int count) {
    return 'Fino a $count membri per gruppo';
  }

  @override
  String get eventsPriceHint => 'Prezzo (1–1000)';

  @override
  String get eventsPriceRange => 'Inserisci un prezzo tra 1 e 1000';

  @override
  String get eventsLinkLabelHint => 'Etichetta (facoltativa)';

  @override
  String get eventsPickLocation => 'Scegli luogo';

  @override
  String get eventsSearchAddress => 'Cerca indirizzo';

  @override
  String get eventsUseThisLocation => 'Usa questo luogo';

  @override
  String get eventsEditEvent => 'Modifica evento';

  @override
  String get groupEditName => 'Modifica nome del gruppo';

  @override
  String get groupChangePhoto => 'Cambia foto del gruppo';

  @override
  String get groupUploadingPhoto => 'Caricamento foto…';

  @override
  String get groupPhotoUpdated => 'Foto del gruppo aggiornata';

  @override
  String get groupPhotoUpdateFailed =>
      'Impossibile aggiornare la foto del gruppo';

  @override
  String get eventTextProhibited =>
      'Il titolo o la descrizione contiene linguaggio vietato e non può essere usato';

  @override
  String get groupSearchHint => 'Cerca gruppi';

  @override
  String get groupNoSearchResults => 'Nessun gruppo trovato';

  @override
  String get groupMyTags => 'I miei tag';

  @override
  String get groupMyTagsSubtitle => 'Privati — solo tu puoi vederli';

  @override
  String get groupNoTagsYet => 'Ancora nessun tag';

  @override
  String get groupTagsEditTitle => 'Modifica i miei tag';

  @override
  String get groupAddTagHint => 'Aggiungi un tag';

  @override
  String get groupTagsSave => 'Salva';

  @override
  String get groupTagsSaved => 'Tag salvati';

  @override
  String get groupTagsSaveFailed => 'Impossibile salvare i tag';

  @override
  String get groupTagsLimitReached => 'Limite di tag raggiunto';

  @override
  String peopleTagsEditTitle(String name) {
    return 'Tag per $name';
  }

  @override
  String get groupTranslationSettings => 'Traduzione';

  @override
  String get groupTranslateMessages => 'Traduci messaggi';

  @override
  String get groupShowOriginal => 'Mostra testo originale';

  @override
  String get eventsTabLiveEvents => 'Eventi dal vivo';

  @override
  String get globeLayerLiveEvents => 'Eventi dal vivo';

  @override
  String get eventsSortBy => 'Ordina per';

  @override
  String get eventsSortDistance => 'Distanza';

  @override
  String get eventsSortStars => 'Stelle';

  @override
  String get eventsSortReviews => 'Recensioni';

  @override
  String get eventsSortDate => 'Data';

  @override
  String get catMuseums => 'Musei';

  @override
  String get catSights => 'Attrazioni';

  @override
  String get catParks => 'Parchi';

  @override
  String get catNationalParks => 'Parchi nazionali';

  @override
  String get catThemeParks => 'Parchi a tema';

  @override
  String get catTours => 'Tour e visite';

  @override
  String get catCulture => 'Cultura e musei';

  @override
  String get catFoodDrink => 'Cibo e bevande';

  @override
  String get catCruises => 'Crociere e acqua';

  @override
  String get catNature => 'Natura e aria aperta';

  @override
  String get catDayTrips => 'Gite di un giorno';

  @override
  String get catTickets => 'Biglietti e pass';

  @override
  String get catOther => 'Altro';

  @override
  String get eventsUnlimited => 'Illimitato';

  @override
  String get eventsTabGoing => 'Partecipo';

  @override
  String get globeLayerCommunityEvents => 'Eventi della community';

  @override
  String get webMapUnavailableTitle =>
      'Mappa interattiva disponibile sull\'app mobile';

  @override
  String get webMapUnavailableBody =>
      'Cerca un indirizzo per impostare la tua posizione.';

  @override
  String get webLocationPickerTitle => 'Scegli la tua posizione';

  @override
  String get webLocationSearchHint => 'Cerca città o indirizzo';

  @override
  String get webLocationConfirm => 'Usa questa posizione';

  @override
  String get webLocationTapHint =>
      'Tocca la mappa per posizionare un segnaposto';

  @override
  String webLocationMonthlyLimit(String date) {
    return 'Puoi aggiornare la tua posizione una volta al mese sul web. Prossimo aggiornamento disponibile $date.';
  }

  @override
  String get eventMyTicket => 'Il mio biglietto';

  @override
  String get eventTicketDelete => 'Elimina biglietto';

  @override
  String get eventTicketDeleteConfirm =>
      'Eliminare definitivamente questo biglietto? L evento e gia terminato.';

  @override
  String get eventScanCheckIn => 'Scansiona / Check-in';

  @override
  String get eventScanUseMobileApp =>
      'La scansione del QR per il check-in è disponibile nell\'app mobile GreenGo.';

  @override
  String get eventScanManageScanners => 'Gestisci scanner';

  @override
  String get eventScanInviteScannerHint =>
      'Invita un membro a scansionare i biglietti all\'ingresso.';

  @override
  String get eventScanNicknameHint => 'Nickname';

  @override
  String get eventScanAddScanner => 'Aggiungi';

  @override
  String get eventScanScannerNotFound =>
      'Nessun membro trovato con quel nickname';

  @override
  String get eventScanScannerAddFailed =>
      'Impossibile aggiungere lo scanner. Riprova.';

  @override
  String eventScanScannerAdded(String name) {
    return '$name ora può scansionare i biglietti';
  }

  @override
  String get eventAttendance => 'Presenze';

  @override
  String get eventCheckedIn => 'Registrato';

  @override
  String get eventNotCheckedIn => 'Non ancora qui';

  @override
  String get eventGuestsAllowedLabel => 'Ospiti consentiti per partecipante';

  @override
  String get eventBringGuests => 'Porta ospiti';

  @override
  String get eventInvalidTicket => 'Biglietto non valido per questo evento';

  @override
  String get eventScanInstructions =>
      'Punta la fotocamera sul codice QR di un partecipante';

  @override
  String get eventTotalHeadcount => 'Numero totale di presenze';

  @override
  String get eventCameraPermission =>
      'È necessaria l\'autorizzazione della fotocamera per scansionare';

  @override
  String get eventTicketSubtitle => 'Mostra questo QR all\'ingresso';

  @override
  String eventGuestCount(int count, int max) {
    return '$count di $max ospiti';
  }

  @override
  String eventCheckedInSuccess(String name) {
    return '$name registrato';
  }

  @override
  String eventAlreadyCheckedIn(String name) {
    return '$name già registrato';
  }

  @override
  String eventGuestsBringing(int count) {
    return '+$count ospiti';
  }

  @override
  String connectDailyLimitReached(int limit) {
    return 'Hai raggiunto il tuo limite giornaliero di $limit nuove connessioni. Passa a un piano superiore per connetterti con più persone!';
  }

  @override
  String get boostFeatureName => 'Boost del profilo';

  @override
  String get boostRequiresTierDescription =>
      'I boost del profilo sono un vantaggio riservato agli abbonati. Aggiorna il tuo piano per potenziare il tuo profilo e farti vedere da più persone.';

  @override
  String boostMonthlyLimitReached(int limit) {
    return 'Hai usato tutti i $limit boost del profilo inclusi nel tuo piano questo mese. Aggiorna per averne di più.';
  }

  @override
  String get travelModeFeatureName => 'Modalità Viaggiatore';

  @override
  String get travelModeRequiresTierDescription =>
      'La modalità Viaggiatore ti permette di apparire nel feed Scoperta di un\'altra città. Aggiorna il tuo piano per sbloccarla.';

  @override
  String get exploreRecommended => 'Consigliato per te';

  @override
  String get businessAccountTitle => 'Account aziendale';

  @override
  String get becomeBusiness => 'Diventa un\'azienda';

  @override
  String get businessProfileLabel => 'Profilo aziendale';

  @override
  String get businessCategoryLabel => 'Categoria aziendale';

  @override
  String get businessCategoryHint => 'Seleziona una categoria';

  @override
  String get businessVerifiedLabel => 'Azienda verificata';

  @override
  String get featureThisEvent => 'Metti in evidenza questo evento';

  @override
  String featureEventCostLabel(int cost) {
    return 'Metti in evidenza questo evento · $cost monete';
  }

  @override
  String featureEventActive(String date) {
    return 'In evidenza fino al $date';
  }

  @override
  String featureEventConfirm(int cost) {
    return 'Mettere in evidenza questo evento per $cost monete?';
  }

  @override
  String get referralTitle => 'Invita amici';

  @override
  String get referralInviteFriends => 'Invita amici';

  @override
  String get referralYourCode => 'Il tuo codice di invito';

  @override
  String get referralShareCta => 'Condividi';

  @override
  String get referralShareMessage => 'Unisciti a me su GreenGo!';

  @override
  String get referralRewardEarned => 'Monete guadagnate';

  @override
  String get referralCountLabel => 'Amici invitati';

  @override
  String referralHowItWorks(int coins, int monthlyCap) {
    final intl.NumberFormat coinsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String coinsString = coinsNumberFormat.format(coins);
    final intl.NumberFormat monthlyCapNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthlyCapString = monthlyCapNumberFormat.format(monthlyCap);

    return 'Condividi il tuo codice — quando un amico si iscrive con esso, tu guadagni $coinsString monete (fino a $monthlyCapString al mese) e lui riceve 1 mese di Platinum.';
  }

  @override
  String get referralHowItWorksTitle => 'Come funziona';

  @override
  String get achievementsLoadError => 'Impossibile caricare i traguardi';

  @override
  String get loadErrorCheckConnection => 'Controlla la connessione e riprova.';

  @override
  String get streakTitle => 'Serie';

  @override
  String get streakDaysLabel => 'giorni di serie';

  @override
  String get streakKeepGoing => 'Continua così!';

  @override
  String get missionsTitle => 'Missioni';

  @override
  String get missionsSubtitle => 'Completa le missioni per guadagnare monete';

  @override
  String get missionProgressLabel => 'Progresso';

  @override
  String get missionRewardLabel => 'Ricompensa';

  @override
  String get missionCompleteLabel => 'Completata';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto su GreenGo';

  @override
  String get onboardingWelcomeBody =>
      'Scopri culture, pratica le lingue, trova eventi locali e incontra persone vicino a te — senza barriere linguistiche.';

  @override
  String get onboardingPickInterests => 'Cosa ami?';

  @override
  String get onboardingPickLanguages => 'Lingue che parli';

  @override
  String get savedSearchesTitle => 'Ricerche salvate';

  @override
  String get saveThisSearch => 'Salva questa ricerca';

  @override
  String get savedSearchSaved => 'Ricerca salvata';

  @override
  String get savedSearchRun => 'Esegui';

  @override
  String get savedSearchEmpty => 'Ancora nessuna ricerca salvata';

  @override
  String get savedSearchAlertsToggle => 'Avvisi';

  @override
  String get exploreFeaturedCommunity => 'Eventi della community in evidenza';

  @override
  String get notificationMarkAllRead => 'Segna tutti come letti';

  @override
  String get notificationsDeleteUnread => 'Elimina non lette';

  @override
  String get notificationsDeleteAll => 'Elimina tutto';

  @override
  String get notificationsDeleteAllConfirm =>
      'Eliminare definitivamente tutte le notifiche di questa pagina? L operazione non puo essere annullata.';

  @override
  String get notificationsDeleteUnreadConfirm =>
      'Eliminare definitivamente tutte le notifiche non lette? L operazione non puo essere annullata.';

  @override
  String get analyticsTitle => 'Statistiche';

  @override
  String get analyticsPlatinumOnly =>
      'Le statistiche sono una funzionalità Platinum.';

  @override
  String get analyticsEventsHosted => 'Eventi organizzati';

  @override
  String get analyticsTotalAttendees => 'Totale partecipanti';

  @override
  String get analyticsReach => 'Copertura';

  @override
  String get analyticsUpgradeCta => 'Passa a Platinum';

  @override
  String get safetyVerifiedBadge => 'Verificato';

  @override
  String get safetyReportUser => 'Segnala';

  @override
  String get safetyBlockUser => 'Blocca';

  @override
  String get safetyCheckInTitle => 'Check-in di sicurezza';

  @override
  String get safetyCheckInArrived => 'Sono arrivato al sicuro';

  @override
  String get safetyCheckInDone => 'Hai effettuato il check-in in sicurezza';

  @override
  String get guidelinesTitle => 'Linee guida della community';

  @override
  String get guidelinesAccept => 'Accetto';

  @override
  String get guidelinesBody =>
      'GreenGo è una community interculturale dedicata alla scoperta, allo scambio linguistico, agli eventi locali e all\'amicizia. Sii rispettoso e accogliente verso le persone di ogni cultura. Questa non è un\'app di incontri. Nessuna molestia, incitamento all\'odio, spam o contenuto esplicito. Segnala tutto ciò che non è appropriato.';

  @override
  String get businessSectionTitle => 'Azienda';

  @override
  String get businessSectionSubtitle => 'Strumenti per la tua azienda';

  @override
  String get businessHubAccount => 'Account aziendale';

  @override
  String get businessHubAnalytics => 'Statistiche';

  @override
  String get businessHubFeatured => 'Posizionamenti in evidenza';

  @override
  String get becomeBusinessAction => 'Diventa un\'azienda';

  @override
  String get becomeBusinessConfirmTitle => 'Diventare un account aziendale?';

  @override
  String get becomeBusinessConfirmMessage =>
      'È permanente: il tuo account diventa un account aziendale pubblico e non può tornare a essere un account personale. Gli strumenti aziendali funzionano finché la tua iscrizione Platinum è attiva; se scade, vengono sospesi fino al rinnovo.';

  @override
  String get becomeBusinessConfirmAction => 'Rendi permanente';

  @override
  String get becomeBusinessSuccess =>
      'Il tuo account è ora un account aziendale.';

  @override
  String get becomeBusinessError =>
      'Impossibile cambiare il tuo account. Riprova.';

  @override
  String get businessAccountActive => 'Account aziendale attivo (permanente)';

  @override
  String get businessRequiresPlatinum =>
      'Gli account aziendali sono una funzionalità Platinum. Aggiorna per sbloccare la tua vetrina, i follower e l\'acquisizione di contatti.';

  @override
  String get viewStorefront => 'Vedi vetrina';

  @override
  String get requestVerification => 'Richiedi verifica';

  @override
  String get requestVerificationPending => 'Verifica in sospeso';

  @override
  String get requestVerificationTitle => 'Richiedi verifica';

  @override
  String get verifyBusinessNameLabel => 'Nome dell\'attività';

  @override
  String get verifyLegalNameLabel => 'Nome legale';

  @override
  String get verifyLegalNameHint => 'Ragione sociale registrata';

  @override
  String get verifyPhoneLabel => 'Numero di telefono';

  @override
  String get verifyPhoneHint => '+39 312 345 6789';

  @override
  String get verifyPhoneFormatError =>
      'Inserisci il numero in formato internazionale, es. +393401234567';

  @override
  String get verifySendCode => 'Invia codice';

  @override
  String get verifyResendCode => 'Invia di nuovo';

  @override
  String get verifyEnterCodeLabel => 'Codice a 6 cifre';

  @override
  String get verifyConfirmCode => 'Verifica';

  @override
  String get verifyPhoneVerified => 'Telefono verificato';

  @override
  String get verifyOwnerDocumentLabel => 'Documento d\'identità del titolare';

  @override
  String get verifyUploadDocument => 'Carica documento';

  @override
  String get verifyDocumentUploaded => 'Documento caricato';

  @override
  String get verifyDocumentUploadError =>
      'Impossibile caricare il documento. Riprova.';

  @override
  String get verifyWebsiteLabel => 'Sito web (facoltativo)';

  @override
  String get verifyWebsiteHint => 'https://esempio.com';

  @override
  String get verifyNotesLabel => 'Note (facoltativo)';

  @override
  String get verifyMissingFields =>
      'Compila tutti i campi obbligatori e verifica il telefono.';

  @override
  String get requestVerificationMessage =>
      'Raccontaci qualcosa sulla tua azienda così possiamo verificarla. Il nostro team esaminerà la tua richiesta.';

  @override
  String get requestVerificationNoteHint =>
      'Aggiungi una nota (sito web, indirizzo, qualsiasi cosa ci aiuti a verificarti)';

  @override
  String get requestVerificationSubmitted => 'Richiesta di verifica inviata.';

  @override
  String get requestVerificationError =>
      'Impossibile inviare la tua richiesta. Riprova.';

  @override
  String get submit => 'Invia';

  @override
  String get businessVerifiedBadgeTooltip => 'Azienda verificata';

  @override
  String get businessLinks => 'Link';

  @override
  String get businessOpeningHours => 'Orari di apertura';

  @override
  String get businessHoursNotProvided => 'Orari di apertura non forniti';

  @override
  String get businessGallery => 'Galleria';

  @override
  String get businessUpcomingEvents => 'Prossimi eventi';

  @override
  String get businessNoUpcomingEvents => 'Ancora nessun evento in programma.';

  @override
  String get businessCommunities => 'Community';

  @override
  String get businessNoCommunities => 'Ancora nessuna community.';

  @override
  String get businessContact => 'Contatto';

  @override
  String get businessFollow => 'Segui';

  @override
  String get businessFollowing => 'Segui già';

  @override
  String get businessFollowError =>
      'Impossibile aggiornare il follow. Riprova.';

  @override
  String businessFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count follower',
      one: '1 follower',
      zero: 'Nessun follower',
    );
    return '$_temp0';
  }

  @override
  String businessMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
      zero: 'Nessun membro',
    );
    return '$_temp0';
  }

  @override
  String get adminBusinessVerifications => 'Verifiche aziendali';

  @override
  String get adminBusinessVerificationsSubtitle =>
      'Esamina e approva i badge verificati delle aziende';

  @override
  String get adminApproveBusinessVerification => 'Approva';

  @override
  String get adminRejectBusinessVerification => 'Rifiuta verifica aziendale';

  @override
  String get adminBusinessRejectReasonHint =>
      'Motivo del rifiuto (facoltativo)';

  @override
  String get adminBusinessApproved => 'Azienda verificata';

  @override
  String get adminBusinessRejected => 'Verifica aziendale rifiutata';

  @override
  String get adminNoPendingBusinessVerifications =>
      'Nessuna verifica aziendale in sospeso';

  @override
  String get adminAccessDenied => 'Accesso negato. Solo amministratori.';

  @override
  String get adminBusinessVerifiedNotificationTitle =>
      'La tua azienda è verificata';

  @override
  String get adminBusinessVerifiedNotificationBody =>
      'La tua azienda ora mostra il badge verificato dorato.';

  @override
  String adminSubmittedLabel(String date) {
    return 'Inviato il $date';
  }

  @override
  String get communitiesSponsored => 'Sponsorizzato';

  @override
  String get communitiesSponsorThisCommunity => 'Sponsorizza questa community';

  @override
  String get communitiesSponsorSubtitle =>
      'Fissa una promo in cima per i membri';

  @override
  String get communitiesSponsorFeatureName => 'Sponsorizzazione community';

  @override
  String get communitiesSponsorRequiresPlatinum =>
      'Sponsorizzare una community e fissare una promo è una funzionalità aziendale Platinum.';

  @override
  String get communitiesEditSponsorship => 'Modifica sponsorizzazione e promo';

  @override
  String get communitiesMarkAsSponsored => 'Segna come sponsorizzato';

  @override
  String get communitiesPromoTitleLabel => 'Titolo promo';

  @override
  String get communitiesPromoTitleHint => 'es. 20% di sconto questo weekend';

  @override
  String get communitiesPromoBodyLabel => 'Messaggio promo';

  @override
  String get communitiesPromoBodyHint => 'Racconta ai membri della tua offerta';

  @override
  String get communitiesPromoImageLabel => 'URL immagine (facoltativo)';

  @override
  String get communitiesPromoLinkEventLabel =>
      'ID evento collegato (facoltativo)';

  @override
  String get communitiesPromoLinkUrlLabel => 'URL link (facoltativo)';

  @override
  String get communitiesPromoTitleRequired =>
      'Inserisci un titolo per la promo';

  @override
  String get communitiesSaveSponsorship => 'Salva';

  @override
  String get communitiesRemovePromo => 'Rimuovi promo';

  @override
  String get exploreSearchTooltip => 'Cerca';

  @override
  String get exploreQrTooltip => 'I miei codici QR';

  @override
  String get universalSearchTitle => 'Cerca';

  @override
  String get universalSearchHint => 'Cerca persone ed eventi';

  @override
  String get universalSearchTabPeople => 'Persone';

  @override
  String get universalSearchTabEvents => 'Eventi';

  @override
  String get universalSearchEmptyPrompt =>
      'Trova persone con cui chattare ed eventi a cui partecipare';

  @override
  String get universalSearchNoPeople => 'Nessuna persona trovata';

  @override
  String get universalSearchNoEvents => 'Nessun evento trovato';

  @override
  String get qrHubTitle => 'Codici QR';

  @override
  String get qrHubTabMyTickets => 'I miei biglietti';

  @override
  String get qrHubTabScan => 'Scansiona';

  @override
  String get qrHubNoTickets =>
      'Ancora nessun biglietto in arrivo. Partecipa a un evento per ottenere il tuo codice QR.';

  @override
  String get qrHubTicketHint =>
      'Tocca un biglietto per aprire il suo codice QR completo';

  @override
  String get qrHubScanInstructions =>
      'Punta la fotocamera su un codice QR GreenGo';

  @override
  String get qrHubInvalidCode => 'Questo non è un codice GreenGo valido';

  @override
  String get qrScanApproved => 'Approvato — check-in effettuato';

  @override
  String get qrScanNotAuthorized =>
      'Solo il proprietario o uno scanner invitato può convalidare i biglietti';

  @override
  String get qrHubJoinedEvent => 'Ci sei! Apertura dell\'evento…';

  @override
  String get eventsRepeats => 'Ripetizioni';

  @override
  String get eventsRepeatNone => 'Non si ripete';

  @override
  String get eventsRepeatDaily => 'Giornaliero';

  @override
  String get eventsRepeatWeekly => 'Settimanale';

  @override
  String get eventsRepeatMonthly => 'Mensile';

  @override
  String get eventsRepeatInterval => 'Ogni';

  @override
  String get eventsRepeatCount => 'Occorrenze';

  @override
  String get eventsRecurringLabel => 'Ricorrente';

  @override
  String get eventsCancelSeries => 'Annulla intera serie';

  @override
  String get eventsCancelSeriesConfirm =>
      'Annullare tutte le occorrenze future di questo evento ricorrente?';

  @override
  String get eventsSeriesCancelled => 'Serie annullata';

  @override
  String get eventsSeriesCancelError => 'Impossibile annullare la serie';

  @override
  String get eventsSaveAsDraft => 'Salva come bozza';

  @override
  String get eventsSchedule => 'Pianifica';

  @override
  String get eventsStatusDraft => 'Bozza';

  @override
  String get eventsStatusScheduled => 'Pianificato';

  @override
  String get eventsStatusCancelled => 'Annullato';

  @override
  String eventsScheduledForDate(String date) {
    return 'Pianificato per il $date';
  }

  @override
  String eventsRepeatCap(int max) {
    return 'Fino a $max occorrenze';
  }

  @override
  String get eventsTicketTiers => 'Categorie di biglietti';

  @override
  String get eventsRepeatHelper =>
      '\'Ogni\' imposta l\'intervallo tra le date (es. ogni 2 settimane); \'Occorrenze\' e quante date vengono create in totale.';

  @override
  String get eventsTicketTiersHelper =>
      'Livelli di prezzo opzionali (es. Standard, VIP) che impostano prezzo e capienza. Non controllano l accesso con monete all evento.';

  @override
  String get eventsAddTier => 'Aggiungi categoria';

  @override
  String get eventsTierName => 'Nome categoria';

  @override
  String get eventsTierPriceCoins => 'Prezzo (monete, 0 = gratis)';

  @override
  String get eventsTierCapacity => 'Capienza (0 = illimitata)';

  @override
  String get eventsFreeTier => 'Gratis';

  @override
  String get eventsSelectTier => 'Seleziona un biglietto';

  @override
  String get eventsJoinWaitlist => 'Unisciti alla lista d\'attesa';

  @override
  String get eventsOnWaitlist => 'In lista d\'attesa';

  @override
  String eventsWaitlistPosition(int position) {
    return 'Sei il #$position nella lista d\'attesa';
  }

  @override
  String eventsTierPriceValue(int coins) {
    return '$coins monete';
  }

  @override
  String eventsTierCapacityValue(int capacity) {
    return '$capacity posti';
  }

  @override
  String get eventsRsvpError => 'Impossibile aggiornare la tua partecipazione';

  @override
  String get shareProfileTooltip => 'Condividi profilo';

  @override
  String shareProfileMessage(String link) {
    return 'Chatta con me su GreenGo: $link';
  }

  @override
  String shareEventMessage(String link) {
    return 'Dai un\'occhiata a questo evento su GreenGo: $link';
  }

  @override
  String get guidelinesSubtitle =>
      'Un breve benvenuto al nostro modo di connetterci';

  @override
  String get guidelinesWelcomeTitle => 'Benvenuto tra le culture';

  @override
  String get guidelinesWelcomeDesc =>
      'Incontra persone da ogni dove e condividi il tuo mondo con apertura.';

  @override
  String get guidelinesRespectTitle => 'Rispetta tutti';

  @override
  String get guidelinesRespectDesc =>
      'Prima di tutto gentilezza e curiosità — tratta gli altri come vorresti essere trattato.';

  @override
  String get guidelinesAuthenticTitle => 'Resta autentico';

  @override
  String get guidelinesAuthenticDesc =>
      'GreenGo è per connessioni culturali autentiche — non è un\'app di incontri.';

  @override
  String get guidelinesSafetyTitle => 'Niente molestie o odio';

  @override
  String get guidelinesSafetyDesc =>
      'Molestie, incitamento all\'odio e minacce non hanno posto qui.';

  @override
  String get guidelinesNoSpamTitle => 'Niente spam o contenuti espliciti';

  @override
  String get guidelinesNoSpamDesc =>
      'Mantieni tutto pulito — niente spam, truffe o contenuti sessuali.';

  @override
  String get guidelinesReportTitle => 'Segnala qualsiasi problema';

  @override
  String get guidelinesReportDesc =>
      'Noti qualcosa di strano? Segnalalo e il nostro team darà un\'occhiata.';

  @override
  String get businessNewBadge => 'NUOVO';

  @override
  String get businessLeadsTitle => 'Contatti';

  @override
  String get businessLeadsEmpty =>
      'Ancora nessun contatto. Le persone che ti contattano o salvano i tuoi eventi appariranno qui.';

  @override
  String get businessLeadContact => 'Ti ha contattato';

  @override
  String get businessLeadSavedEvent => 'Ha salvato il tuo evento';

  @override
  String get eventTicketWhen => 'Quando';

  @override
  String get eventTicketVenue => 'Sede';

  @override
  String get eventTicketWhere => 'Dove';

  @override
  String get eventTicketGuestsLabel => 'Ospiti';

  @override
  String eventTicketAdmits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ammette $count persone',
      one: 'Ammette 1 persona',
    );
    return '$_temp0';
  }

  @override
  String get shareEvent => 'Condividi evento';

  @override
  String get promoteTitle => 'Promuovi';

  @override
  String get promoteSubtitle => 'Aumenta la tua visibilità con i GreenGoCoin';

  @override
  String get promoteBusinessOption => 'Promuovi l\'attività';

  @override
  String get promoteBusinessDesc =>
      'Metti in evidenza la tua vetrina in cima a Esplora';

  @override
  String get promoteEventsOption => 'Promuovi un evento';

  @override
  String get promoteEventsDesc =>
      'Metti in evidenza uno dei tuoi eventi nella scoperta';

  @override
  String get promoteChooseDuration => 'Scegli una durata';

  @override
  String get promoteNotActive => 'Nessuna promozione attiva';

  @override
  String get promoteConfirmTitle => 'Conferma promozione';

  @override
  String get promoteConfirmCta => 'Promuovi';

  @override
  String get promoteCancel => 'Annulla';

  @override
  String get promoteSelectEvent => 'Seleziona un evento da mettere in evidenza';

  @override
  String get promoteNoEvents =>
      'Non hai eventi in programma da mettere in evidenza';

  @override
  String get promoteEventAlreadyFeatured => 'Già in evidenza';

  @override
  String get promoteSuccess => 'Promozione attiva!';

  @override
  String get promoteError => 'Qualcosa è andato storto. Riprova.';

  @override
  String get promoteInsufficientCoins => 'Monete insufficienti';

  @override
  String get promoteInsufficientCoinsBody =>
      'Non hai abbastanza monete per questa promozione. Ricarica per continuare.';

  @override
  String get promoteGetCoins => 'Ottieni monete';

  @override
  String promoteDurationDays(int days) {
    return '$days giorni';
  }

  @override
  String promoteCostLabel(int cost) {
    return '$cost monete';
  }

  @override
  String promoteActiveUntil(String date) {
    return 'Promosso fino al $date';
  }

  @override
  String promoteBusinessConfirm(int days, int cost) {
    return 'Promuovere la tua attività per $days giorni con $cost monete?';
  }

  @override
  String promoteEventConfirm(int days, int cost) {
    return 'Mettere in evidenza questo evento per $days giorni con $cost monete?';
  }

  @override
  String get audienceSectionTitle => 'Analisi del pubblico';

  @override
  String get audiencePrivacyNote =>
      'Aggregati e anonimizzati — i piccoli gruppi sono nascosti per proteggere la privacy.';

  @override
  String get audienceNotEnoughData =>
      'Ancora troppo pochi dati per mostrarlo proteggendo la privacy.';

  @override
  String get audienceAgeTitle => 'Distribuzione per età';

  @override
  String get audienceCountriesTitle => 'Principali paesi';

  @override
  String get audienceInterestsTitle => 'Principali interessi';

  @override
  String get eventAnalyticsTitle => 'Statistiche dell\'evento';

  @override
  String get eventAnalyticsGoing => 'Partecipanti';

  @override
  String get eventAnalyticsWaitlist => 'Lista d\'attesa';

  @override
  String get eventAnalyticsCheckedIn => 'Registrati';

  @override
  String get eventAnalyticsCheckInRate => 'Tasso di check-in';

  @override
  String get eventAnalyticsTierBreakdown => 'Categorie di biglietti';

  @override
  String get businessEventsTitle => 'Gestisci i miei eventi';

  @override
  String get businessEventsSearchHint => 'Cerca per nome o data';

  @override
  String get businessEventsEmpty => 'Non hai ancora creato alcun evento.';

  @override
  String get businessEventsAnalytics => 'Statistiche';

  @override
  String get businessEventsCancelTitle => 'Annulla evento';

  @override
  String get businessEventsCancelMessage =>
      'Annullare questo evento? I partecipanti verranno avvisati e sarà rimosso.';

  @override
  String get businessEventsCancelSeriesMessage =>
      'Annullare ogni occorrenza di questa serie ricorrente?';

  @override
  String get businessEventsCancelConfirm => 'Annulla evento';

  @override
  String get businessEventsCancelled => 'Evento annullato';

  @override
  String get businessPausedTitle => 'Attività in pausa';

  @override
  String get businessPausedSubtitle =>
      'Le tue funzionalità aziendali sono in pausa perché il tuo abbonamento Platinum è scaduto. Rinnova Platinum per ripristinare la tua vetrina, le statistiche, i contatti e le promozioni.';

  @override
  String get businessReactivate => 'Rinnova Platinum';

  @override
  String get eventsBoostChooseDuration => 'Scegli la durata del boost';

  @override
  String eventsBoostHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settimane',
      one: '1 settimana',
    );
    return '$_temp0';
  }

  @override
  String eventBoostEndsIn(String time) {
    return 'Il boost termina tra $time';
  }

  @override
  String get eventBoostEnded => 'Boost terminato';

  @override
  String get eventsBuyCoins => 'Acquista monete';

  @override
  String get eventsBuyCoinsPrompt =>
      'Non hai abbastanza monete. Vuoi acquistarne altre?';

  @override
  String get messageTooLong =>
      'I messaggi possono contenere fino a 4096 caratteri.';

  @override
  String get exploreBusinessesNearYou => 'Attivita vicino a te';

  @override
  String get splashBusinessLabel => 'BUSINESS';

  @override
  String get rateThisBusiness => 'Valuta questa attività';

  @override
  String get businessRatingError =>
      'Impossibile salvare la tua valutazione. Riprova.';

  @override
  String businessRatingCount(int count) {
    return '($count)';
  }

  @override
  String rateStarsSemantic(int stars) {
    return 'Assegna $stars stelle';
  }

  @override
  String businessRatingSemantic(String avg, int count) {
    return 'Valutato $avg su 5, $count valutazioni';
  }

  @override
  String get editStorefront => 'Modifica vetrina';

  @override
  String get editStorefrontSubtitle =>
      'Gestisci galleria, orari, link e informazioni';

  @override
  String get storefrontGallerySubtitle =>
      'Metti in mostra il tuo locale, i prodotti o il team';

  @override
  String get storefrontOpeningHoursSubtitle =>
      'Imposta i giorni e gli orari di apertura';

  @override
  String get storefrontDescriptionHint => 'Racconta la tua attività';

  @override
  String get storefrontCategoryHint => 'es. Ristorante, Caffè, Museo';

  @override
  String get storefrontLinkHint => 'https://...';

  @override
  String get storefrontAddLink => 'Aggiungi link';

  @override
  String get storefrontAddImage => 'Aggiungi immagine';

  @override
  String get storefrontSaved => 'Vetrina aggiornata';

  @override
  String get analyticsEventViews => 'Visualizzazioni evento';

  @override
  String get analyticsCommunityReach => 'Portata nella community';

  @override
  String get analyticsChatsInvolved => 'Chat generate';

  @override
  String get eventAnalyticsViews => 'Visualizzazioni';

  @override
  String get businessHubScanner => 'Scanner rapido';

  @override
  String get businessHubScannerSubtitle =>
      'Scansiona i biglietti per registrare i partecipanti';

  @override
  String get businessHubFollowers => 'Follower';

  @override
  String get businessHubFollowersSubtitle => 'Vedi chi segue la tua attività';

  @override
  String get businessFollowersTitle => 'Follower';

  @override
  String get businessNoFollowers =>
      'Ancora nessun follower. Condividi la tua vetrina per far crescere il pubblico.';

  @override
  String get membershipRequiredTitle => 'Abbonamento richiesto';

  @override
  String get membershipRequiredBody =>
      'Serve un abbonamento attivo per farlo. Rinnova per continuare.';

  @override
  String get renewMembership => 'Rinnova abbonamento';

  @override
  String get extraEventTitle => 'Evento extra';

  @override
  String extraEventBody(int cost) {
    return 'Hai raggiunto il limite di eventi gratuiti. Creare un evento extra per $cost monete?';
  }

  @override
  String get accountBannedTitle => 'Account bannato definitivamente';

  @override
  String get accountBannedBody =>
      'Questo account è stato bannato definitivamente per violazione delle nostre norme sui contenuti. Questa decisione è definitiva.';

  @override
  String get adminBanPermanently => 'Banna definitivamente';

  @override
  String get adminBanConfirm => 'Bannare definitivamente questo account?';

  @override
  String get adminBanConfirmBody =>
      'Questo banna definitivamente l\'account e blocca ogni accesso. Non può essere annullato.';

  @override
  String get adminBanReasonHint => 'Motivo (es. nudità nella galleria)';

  @override
  String get adminBanned => 'Account bannato definitivamente';

  @override
  String get storefrontFeaturedImage => 'Immagine in evidenza';

  @override
  String get storefrontFeaturedImageSubtitle =>
      'Il banner principale mostrato in cima alla tua vetrina.';

  @override
  String get storefrontAddFeaturedImage => 'Aggiungi immagine in evidenza';

  @override
  String get storefrontProfileImage => 'Immagine del profilo';

  @override
  String get storefrontProfileImageSubtitle =>
      'Il tuo avatar, mostrato accanto al nome della tua attività.';

  @override
  String get storefrontAddProfileImage => 'Aggiungi immagine del profilo';

  @override
  String get storefrontReplaceProfileImage =>
      'Sostituisci immagine del profilo';

  @override
  String get preferenceBusinessOnly => 'Solo account business';

  @override
  String get preferenceBusinessOnlyDesc =>
      'Mostra solo account business nella scoperta';

  @override
  String get businessProfileNameLabel => 'Nome del profilo business';

  @override
  String get businessProfileNameHint => 'Mostrato sulla tua vetrina';

  @override
  String get businessLegalNameLabel => 'Ragione sociale';

  @override
  String get businessLegalNameHint => 'Nome dell\'azienda registrata';

  @override
  String get verifyOwnerNameLabel => 'Nome completo del titolare';

  @override
  String get verifyOwnerNameHint =>
      'Esattamente come nel documento d\'identità caricato';

  @override
  String get scanResultApproved => 'Approvato';

  @override
  String get scanResultDenied => 'Negato';

  @override
  String get communitiesTabChat => 'Chat';

  @override
  String get communitiesTabTips => 'Consigli';

  @override
  String get communitiesTabAnnouncements => 'Annunci';

  @override
  String get communitiesTabEvents => 'Eventi';

  @override
  String get communitiesJoinRequestSent =>
      'Richiesta inviata — in attesa di approvazione';

  @override
  String get communitiesJoinRequestsTitle => 'Richieste di adesione';

  @override
  String get communitiesTipsEmpty =>
      'Ancora nessun consiglio. Condividi un consiglio linguistico, una curiosità culturale o un consiglio sulla città dalla chat.';

  @override
  String get communitiesAnnouncementsEmpty => 'Ancora nessun annuncio.';

  @override
  String get communitiesPostAnnouncement => 'Pubblica annuncio';

  @override
  String get communitiesRequestToJoin => 'Richiedi di unirti';

  @override
  String get communitiesMutedNotice =>
      'Sei stato silenziato in questa community';

  @override
  String get communitiesRulesResourcesTitle => 'Regole e risorse';

  @override
  String get communitiesRulesLabel => 'Regole della community';

  @override
  String get communitiesRulesHint => 'Linee guida per i membri…';

  @override
  String get communitiesResourcesLabel => 'Link alle risorse';

  @override
  String get communitiesResourceTitleHint => 'Titolo';

  @override
  String get communitiesResourceUrlHint => 'https://…';

  @override
  String get communitiesAddResource => 'Aggiungi link';

  @override
  String get communitiesSaveLabel => 'Salva';

  @override
  String get communitiesAddRulesPrompt =>
      'Aggiungi regole e risorse per questa community';

  @override
  String get communitiesAnnouncementHint =>
      'Scrivi un annuncio per tutti i membri…';

  @override
  String get communitiesPostLabel => 'Pubblica';

  @override
  String get communitiesPromoteMember => 'Promuovi ad admin';

  @override
  String get communitiesGrantTips => 'Consenti di pubblicare Consigli';

  @override
  String get communitiesRevokeTips => 'Revoca pubblicazione Consigli';

  @override
  String get communitiesGrantAnnouncements => 'Consenti di pubblicare Annunci';

  @override
  String get communitiesRevokeAnnouncements => 'Revoca pubblicazione Annunci';

  @override
  String get communitiesDemoteMember => 'Retrocedi a membro';

  @override
  String get communitiesRemoveMember => 'Rimuovi dalla community';

  @override
  String get communitiesMuteMember => 'Silenzia';

  @override
  String get communitiesUnmuteMember => 'Riattiva';

  @override
  String get communitiesBanMember => 'Banna';

  @override
  String get communitiesReportMember => 'Segnala';

  @override
  String get communitiesNoJoinRequests => 'Nessuna richiesta in sospeso';

  @override
  String get communitiesApprove => 'Approva';

  @override
  String get communitiesReject => 'Rifiuta';

  @override
  String get communitiesLinkToCommunity =>
      'Collega a una community (facoltativo)';

  @override
  String get communitiesLinkNone => 'Nessuna';

  @override
  String get communitiesCreateEvent => 'Crea evento';

  @override
  String get communitiesEventsEmpty => 'Ancora nessun evento';

  @override
  String get communitiesTranslate => 'Traduci';

  @override
  String get communitiesShowOriginal => 'Mostra originale';

  @override
  String get communitiesTranslating => 'Traduzione…';

  @override
  String get eventsFilterSoon => 'Presto';

  @override
  String get businessBadgeLabel => 'Business';

  @override
  String get businessWhatsappLabel => 'Numero WhatsApp';

  @override
  String get businessWhatsappSubtitle =>
      'I visitatori toccano per chattare con te su WhatsApp';

  @override
  String get businessWhatsappHint => 'es. +351912345678';

  @override
  String get businessWhatsappButton => 'WhatsApp';

  @override
  String get locationLanguagesLabel => 'Posizione e lingue';

  @override
  String get storefrontLocationLanguagesSubtitle =>
      'Dove sei e le lingue che parli';

  @override
  String get storefrontLocationNotSet => 'Non impostato';

  @override
  String get universalSearchTabBusiness => 'Business';

  @override
  String get universalSearchTabCommunity => 'Community';

  @override
  String get universalSearchNoBusiness => 'Nessun business trovato';

  @override
  String get universalSearchNoCommunities => 'Nessuna community trovata';

  @override
  String get communitiesSearchTips => 'Cerca consigli';

  @override
  String get communitiesAddTip => 'Aggiungi consiglio';

  @override
  String get communitiesTipHint => 'Condividi un consiglio utile…';

  @override
  String get shopEventsCreate => 'Eventi che puoi creare';

  @override
  String get shopGroupsCreate => 'Gruppi e community che puoi creare';

  @override
  String get shopDailyConnects => 'Nuove connessioni giornaliere';

  @override
  String get shopMonthlyBoosts => 'Boost del profilo mensili';

  @override
  String get shopMonthlyCoins => 'Monete mensili';

  @override
  String get shopNoAds => 'Senza pubblicita';

  @override
  String get shopSeeWhoConnected => 'Guarda chi si e connesso con te';

  @override
  String get shopTravelMode => 'Modalita viaggio';

  @override
  String get shopBusinessAccount => 'Account aziendale';

  @override
  String get tourCommunitiesTabsTitle => 'Tre modi per esplorare';

  @override
  String get tourCommunitiesTabsDesc =>
      'Passa dai gruppi a cui ti sei unito, scopri quelli nuovi e gestisci le community che hai creato.';

  @override
  String get tourCommunitiesSearchTitle => 'Trova i tuoi gruppi';

  @override
  String get tourCommunitiesSearchDesc =>
      'Scrivi qui per filtrare le tue community per nome — utile dopo che ne hai seguite alcune.';

  @override
  String get tourCommunitiesCardTitle => 'Apri e aggiungi ai preferiti';

  @override
  String get tourCommunitiesCardDesc =>
      'Tocca una community per aprire chat, consigli, annunci ed eventi. Tocca la stella ⭐ per salvarla — i preferiti vengono fissati in alto.';

  @override
  String get tourCommunitiesCreateTitle => 'Crea una community';

  @override
  String get tourCommunitiesCreateDesc =>
      'Tocca qui per creare la tua community e riunire le persone.';

  @override
  String get tourReplayGuide => 'Rivedi la guida';

  @override
  String get tourExploreSearchTitle => 'Cerca ovunque';

  @override
  String get tourExploreSearchDesc =>
      'Trova persone, attività, eventi e community — tutto da un\'unica ricerca.';

  @override
  String get tourExploreQrTitle => 'Il tuo codice QR';

  @override
  String get tourExploreQrDesc =>
      'Scansiona o condividi un codice QR per connetterti subito di persona.';

  @override
  String get tourEventsCreateTitle => 'Crea un evento';

  @override
  String get tourEventsCreateDesc =>
      'Tocca il piu per organizzare il tuo evento o incontro.';

  @override
  String get tourEventsSearchTitle => 'Cerca eventi';

  @override
  String get tourEventsSearchDesc =>
      'Trova eventi per citta, paese o nome e ordinali come preferisci.';

  @override
  String get tourEventsTabsTitle => 'Esplora ogni scheda';

  @override
  String get tourEventsTabsDesc =>
      'Sfoglia eventi della community, eventi dal vivo, attrazioni ed esperienze vicino a te.';

  @override
  String get tourProfileHubTitle => 'Il tuo centro profilo';

  @override
  String get tourProfileHubDesc =>
      'Tutto sul tuo account e qui: modificalo, gestisci le impostazioni e sblocca le funzioni premium.';

  @override
  String get tourProfileViewTitle => 'Anteprima del profilo';

  @override
  String get tourProfileViewDesc =>
      'Guarda esattamente come gli altri vedono il tuo profilo.';

  @override
  String get tourProfileEditTitle => 'Modifica i tuoi dati';

  @override
  String get tourProfileEditDesc =>
      'Tocca per aggiornare foto, bio, interessi, posizione e altro.';

  @override
  String get tourNotifHubTitle => 'Le tue notifiche';

  @override
  String get tourNotifHubDesc =>
      'Ogni like, match, messaggio e aggiornamento di eventi arriva qui.';

  @override
  String get tourNotifOpenTitle => 'Apri e gestisci';

  @override
  String get tourNotifOpenDesc =>
      'Tocca una notifica per aprirla o scorri a sinistra per eliminarla.';

  @override
  String get tourNotifMarkAllTitle => 'Svuota i non letti';

  @override
  String get tourNotifMarkAllDesc =>
      'Segna tutto come letto con un solo tocco.';

  @override
  String get communitiesJoinAsPersonalTitle =>
      'Unisciti con il tuo profilo personale';

  @override
  String get communitiesJoinAsPersonalBody =>
      'Ti unirai a questa community con il tuo profilo personale. La tua vetrina business non verra mostrata qui. Continuare?';

  @override
  String get communitiesJoinAsPersonalConfirm => 'Unisciti';

  @override
  String get communitiesCreatedManageHint =>
      'Community creata! Apri Membri per aggiungere persone e concedere diritti per consigli o annunci.';

  @override
  String get exploreHappeningSoon => 'Prossimamente';

  @override
  String get attrScoreLabel => 'GreenGo Score';

  @override
  String get attrTierIconic => 'Iconico';

  @override
  String get attrTierExceptional => 'Eccezionale';

  @override
  String get attrTierExcellent => 'Eccellente';

  @override
  String get attrTierGreat => 'Ottimo';

  @override
  String get attrTierWorthVisit => 'Vale una visita';

  @override
  String get attrImpWorldIcon => 'Icona mondiale';

  @override
  String get attrImpInternational => 'Monumento internazionale';

  @override
  String get attrImpNational => 'Monumento nazionale';

  @override
  String get attrImpRegional => 'Attrazione regionale';

  @override
  String get attrImpLocal => 'Attrazione locale';

  @override
  String get attrChipHome => 'Il mio Paese';

  @override
  String get attrChipHere => 'Sei qui';

  @override
  String get attrFree => 'Gratis';

  @override
  String get attrUnesco => 'UNESCO';

  @override
  String get attrMustVisit => 'Da non perdere';

  @override
  String get attrTop10 => 'Top 10';

  @override
  String get attrPhotoSpot => 'Perfetto per le foto';

  @override
  String get attrAllCategories => 'Tutte';

  @override
  String get attrFilterCategory => 'Categoria';

  @override
  String get attrFilterCountry => 'Paese';

  @override
  String get attrFilterCity => 'Città';

  @override
  String get attrAllCities => 'Tutte le città';

  @override
  String get attrSortDistance => 'Più vicine';

  @override
  String get attrSortScore => 'GreenGo Score';

  @override
  String get attrSortRating => 'Valutazione';

  @override
  String get attrSortPrice => 'Prezzo';

  @override
  String get attrSortName => 'Nome';

  @override
  String get attrNoResults => 'Nessuna attrazione corrisponde ai filtri';

  @override
  String get attrNoCoverage =>
      'Non copriamo ancora attrazioni nel tuo Paese — presto altre';

  @override
  String get attrLoadFailed => 'Impossibile caricare le attrazioni';

  @override
  String attrKmAway(String km) {
    return 'a $km km';
  }

  @override
  String get attrAbout => 'Informazioni';

  @override
  String get attrHighlights => 'In evidenza';

  @override
  String get attrWhyVisit => 'Perché visitarla';

  @override
  String get attrScoreHistorical => 'Storico';

  @override
  String get attrScoreArchitectural => 'Architettonico';

  @override
  String get attrScoreNatural => 'Natura';

  @override
  String get attrScorePhotography => 'Fotografia';

  @override
  String get attrBestTimeTitle => 'Periodo migliore';

  @override
  String get attrHistoryTitle => 'Storia';

  @override
  String get attrDidYouKnow => 'Lo sapevi';

  @override
  String get attrPhotoTips => 'Consigli fotografici';

  @override
  String get attrPractical => 'Informazioni pratiche';

  @override
  String get attrOpeningHours => 'Orari';

  @override
  String get attrVisitDuration => 'Visita tipica';

  @override
  String get attrAccessibility => 'Accessibilità';

  @override
  String get attrPets => 'Animali';

  @override
  String get attrSafety => 'Sicurezza';

  @override
  String get attrVisitorsPerYear => 'Visitatori all’anno';

  @override
  String get attrTicketFrom => 'Biglietto';

  @override
  String get attrOpenInMaps => 'Apri in Maps';

  @override
  String attrPhotoBy(String author, String license) {
    return 'Foto: $author · $license';
  }

  @override
  String get attrIndoor => 'Al chiuso';

  @override
  String get attrOutdoor => 'All’aperto';

  @override
  String attrCountAttractions(int count) {
    return '$count attrazioni';
  }

  @override
  String get attrEnableLocation =>
      'Attiva la posizione per vedere cosa hai più vicino ora';

  @override
  String get attrRetry => 'Riprova';

  @override
  String get attrTranslate => 'Traduci';

  @override
  String get attrShowOriginal => 'Mostra originale';

  @override
  String get attrCatReligious => 'Luogo religioso';

  @override
  String get attrCatHistoricSite => 'Sito storico';

  @override
  String get attrCatMuseum => 'Museo';

  @override
  String get attrCatNature => 'Natura';

  @override
  String get attrCatNeighborhood => 'Quartiere';

  @override
  String get attrCatBeach => 'Spiaggia';

  @override
  String get attrCatGarden => 'Giardino';

  @override
  String get attrCatMonument => 'Monumento';

  @override
  String get attrCatSquare => 'Piazza';

  @override
  String get attrCatStreet => 'Via';

  @override
  String get attrCatArchitecture => 'Architettura';

  @override
  String get attrCatObservationDeck => 'Punto panoramico';

  @override
  String get attrCatCastle => 'Castello';

  @override
  String get attrCatMarket => 'Mercato';

  @override
  String get attrCatMountain => 'Montagna';

  @override
  String get attrCatPalace => 'Palazzo';

  @override
  String get attrCatIsland => 'Isola';

  @override
  String get attrCatLake => 'Lago';

  @override
  String get attrCatNationalPark => 'Parco nazionale';

  @override
  String get attrCatOther => 'Altro';

  @override
  String get attrCatBridge => 'Ponte';

  @override
  String get attrCatThemePark => 'Parco a tema';

  @override
  String get attrCatWaterfall => 'Cascata';

  @override
  String get attrCatZoo => 'Zoo';

  @override
  String get attrCatShopping => 'Shopping';

  @override
  String get attrCatAquarium => 'Acquario';

  @override
  String attrSearchResults(int count, String query) {
    return '$count risultati per \"$query\"';
  }

  @override
  String get attendeesSeeAll => 'Vedi tutti';

  @override
  String attendeesCount(int count) {
    return '$count partecipanti';
  }

  @override
  String attendeesCountWithGuests(int count, int guests) {
    return '$count partecipanti · $guests ospiti';
  }

  @override
  String attendeesBringing(int count) {
    return 'Porta $count ospiti';
  }

  @override
  String get attendeesOrganizer => 'Organizzatore';

  @override
  String get attendeesLoadFailed => 'Impossibile caricare i partecipanti';

  @override
  String get attendeesProfileFailed => 'Impossibile aprire questo profilo';

  @override
  String get quizTitle => 'Test della personalità';

  @override
  String get quizSubtitle => 'Aiutaci a capire la tua personalità';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Domanda $current di $total';
  }

  @override
  String get quizQuestionOpenness =>
      'Mi piace provare attività nuove ed entusiasmanti';

  @override
  String get quizQuestionConscientiousness =>
      'Preferisco avere una routine strutturata e organizzata';

  @override
  String get quizQuestionExtraversion =>
      'Mi sento pieno di energia quando socializzo con gli altri';

  @override
  String get quizQuestionAgreeableness =>
      'Cerco di essere collaborativo ed evitare i conflitti';

  @override
  String get quizQuestionNeuroticism => 'Spesso mi sento ansioso o preoccupato';

  @override
  String get quizAnswerStronglyDisagree => 'Fortemente in disaccordo';

  @override
  String get quizAnswerDisagree => 'In disaccordo';

  @override
  String get quizAnswerNeutral => 'Neutrale';

  @override
  String get quizAnswerAgree => 'D\'accordo';

  @override
  String get quizAnswerStronglyAgree => 'Fortemente d\'accordo';

  @override
  String get quizBigFiveNote =>
      'Basato sul modello dei Big Five della personalità';

  @override
  String get profilePreviewTitle => 'Anteprima del profilo';

  @override
  String get profilePreviewSubtitle =>
      'Controlla il tuo profilo prima di completare';

  @override
  String get profilePreviewCompleteButton => 'Completa profilo';

  @override
  String get profileFieldName => 'Nome';

  @override
  String get profileFieldAge => 'Età';

  @override
  String profileAgeYearsOld(int age) {
    return '$age anni';
  }

  @override
  String get profileFieldStatus => 'Stato';

  @override
  String get profileNoBio => 'Nessuna biografia inserita';

  @override
  String get profileCompleteBadgeTitle => 'Profilo completo!';

  @override
  String get profileCompleteBadgeSubtitle =>
      'Il tuo profilo è pronto per essere pubblicato';

  @override
  String get personalityTraitsTitle => 'Tratti della personalità';

  @override
  String get traitOpenness => 'Apertura';

  @override
  String get traitConscientiousness => 'Coscienziosità';

  @override
  String get traitExtraversion => 'Estroversione';

  @override
  String get traitAgreeableness => 'Amicalità';

  @override
  String get traitNeuroticism => 'Nevroticismo';

  @override
  String get socialLinksSubtitle =>
      'Collega i tuoi account social (facoltativo)';

  @override
  String get socialHintUsernameNoAt => 'Nome utente (senza @)';

  @override
  String get socialLinksVisibilityNote =>
      'I tuoi profili social saranno visibili sul tuo profilo pubblico';

  @override
  String get travelPrefTitle => 'Come vuoi usare GreenGo?';

  @override
  String get travelPrefSubtitle =>
      'Raccontaci i tuoi interessi così possiamo personalizzare la tua esperienza.';

  @override
  String get travelPrefLearnTravelTitle => 'Imparare e viaggiare';

  @override
  String get travelPrefLearnTravelDesc =>
      'Imparare le lingue e conoscere persone quando viaggio in posti nuovi';

  @override
  String get travelPrefLocalGuideTitle => 'Guida locale';

  @override
  String get travelPrefLocalGuideDesc =>
      'Aiutare i viaggiatori a scoprire la mia città e condividere la mia cultura con loro';

  @override
  String get travelPrefBothTitle => 'Entrambi';

  @override
  String get travelPrefBothDesc =>
      'Voglio imparare le lingue, viaggiare per il mondo e aiutare i visitatori nella mia città';

  @override
  String get travelPrefChangeLater =>
      'Puoi cambiarlo in qualsiasi momento nelle impostazioni del profilo.';

  @override
  String get locationErrorPermissionDenied =>
      'L\'autorizzazione alla posizione è stata negata. Concedila nelle impostazioni.';

  @override
  String get locationErrorServicesDisabled =>
      'I servizi di localizzazione sono disattivati. Attivali nelle impostazioni.';

  @override
  String get locationErrorUnableToGet =>
      'Impossibile ottenere la tua posizione. Controlla le impostazioni del dispositivo o riprova più tardi.';

  @override
  String get locationErrorCheckInternet =>
      'Controlla la tua connessione a Internet e riprova.';

  @override
  String get locationErrorPermissionRequired =>
      'È necessaria l\'autorizzazione alla posizione. Concedila nelle impostazioni.';

  @override
  String get locationErrorTookTooLong =>
      'Il rilevamento della posizione ha richiesto troppo tempo. Riprova.';

  @override
  String get phoneErrorInvalidNumber =>
      'Formato del numero di telefono non valido. Usa il formato internazionale (es. +1234567890).';

  @override
  String get phoneErrorTooManyRequests =>
      'Troppi tentativi. Attendi qualche minuto prima di riprovare.';

  @override
  String get phoneErrorQuotaExceeded =>
      'Quota SMS superata. Riprova più tardi.';

  @override
  String get phoneErrorCaptchaFailed =>
      'Verifica reCAPTCHA non riuscita. Riprova.';

  @override
  String get phoneErrorMissingNumber => 'Inserisci un numero di telefono.';

  @override
  String phoneErrorGeneric(String code) {
    return 'Errore di verifica del telefono ($code). Riprova.';
  }

  @override
  String get phoneErrorUnexpected =>
      'Errore di verifica del telefono. Riprova.';

  @override
  String get phoneErrorAlreadyLinked =>
      'Questo numero di telefono è già collegato a un altro account.';

  @override
  String get languageNameEnglish => 'Inglese';

  @override
  String get languageNameSpanish => 'Spagnolo';

  @override
  String get languageNameFrench => 'Francese';

  @override
  String get languageNameGerman => 'Tedesco';

  @override
  String get languageNameItalian => 'Italiano';

  @override
  String get languageNamePortuguese => 'Portoghese';

  @override
  String get languageNamePortugueseBrazil => 'Portoghese (Brasile)';

  @override
  String get languageNameRussian => 'Russo';

  @override
  String get languageNameChinese => 'Cinese';

  @override
  String get languageNameJapanese => 'Giapponese';

  @override
  String get languageNameKorean => 'Coreano';

  @override
  String get languageNameArabic => 'Arabo';

  @override
  String get languageNameHindi => 'Hindi';

  @override
  String get languageNameDutch => 'Olandese';

  @override
  String get languageNameSwedish => 'Svedese';

  @override
  String get languageNameNorwegian => 'Norvegese';

  @override
  String get languageNameDanish => 'Danese';

  @override
  String get languageNameFinnish => 'Finlandese';

  @override
  String get languageNamePolish => 'Polacco';

  @override
  String get languageNameTurkish => 'Turco';

  @override
  String get languageNameGreek => 'Greco';

  @override
  String get resetPasswordTitle => 'Reimposta la tua password';

  @override
  String get resetPasswordSubtitle =>
      'Inserisci il tuo indirizzo email e ti invieremo le istruzioni per reimpostare la password.';

  @override
  String get sendResetLink => 'Invia link di reimpostazione';

  @override
  String get backToLogin => 'Torna al login';

  @override
  String get resetLinkExpiryNote =>
      'Per motivi di sicurezza, il link di reimpostazione scadrà tra 1 ora.';

  @override
  String get resetEmailSentTitle => 'Email inviata!';

  @override
  String resetEmailSentBody(String email) {
    return 'Un link per reimpostare la password è stato inviato a $email.\n\nControlla la posta in arrivo e la cartella spam.';
  }

  @override
  String get resetErrorInvalidEmail => 'Indirizzo email non valido.';

  @override
  String get resetErrorUnavailable =>
      'Servizio temporaneamente non disponibile. Riprova più tardi.';

  @override
  String get resetErrorFailed =>
      'Impossibile inviare l\'email di reimpostazione. Riprova.';

  @override
  String get onboardingSubmitCreatingProfile => 'Creazione del tuo profilo…';

  @override
  String get onboardingSubmitGrantingCoins => 'Preparazione delle tue monete…';

  @override
  String get onboardingSubmitFinishingUp => 'Ci siamo quasi…';

  @override
  String get onboardingSubmitPleaseWait => 'Ci vuole solo un momento';

  @override
  String get chatSettingSilverPlusOnly => 'Disponibile da Silver in su';

  @override
  String get chatSettingXpBarHint =>
      'Compare quando guadagni XP in questa chat';

  @override
  String get chatSettingLanguageFlagsHint => 'Mostrato sui messaggi tradotti';

  @override
  String get chatSmartRepliesLoading => 'Sto pensando alle risposte...';

  @override
  String get errorScreenTitle => 'Qualcosa è andato storto';

  @override
  String get errorScreenBody =>
      'Impossibile aprire questa schermata. Ricarica l\'app per riprovare — il tuo account non è stato modificato.';

  @override
  String get errorScreenReload => 'Ricarica';

  @override
  String get ageVerifyTitle => 'Verifica la tua età';

  @override
  String get ageVerifyWhyPublish =>
      'Per pubblicare in una community dobbiamo confermare che hai più di 18 anni.';

  @override
  String get ageVerifyWhyPhone =>
      'Ti sei registrato con un numero di telefono, quindi ci serve un documento per confermare la tua età.';

  @override
  String get ageVerifyPrivacyNote =>
      'Leggiamo la data di nascita in automatico. La foto viene eliminata appena viene presa una decisione (al massimo dopo 7 giorni se serve una revisione umana) e non viene mai mostrata sul tuo profilo.';

  @override
  String get ageVerifyTakePhoto => 'Fotografa il tuo documento';

  @override
  String get ageVerifyChooseImage => 'Scegli dalla galleria';

  @override
  String get ageVerifyChecking => 'Controllo del documento…';

  @override
  String get ageVerifyPending =>
      'Stiamo esaminando il tuo documento. Di solito ci vuole meno di un giorno.';

  @override
  String get ageVerifyVerified => 'La tua età è verificata.';

  @override
  String get ageVerifyRejected =>
      'Non siamo riusciti a leggere il documento. Riprova con una foto più nitida.';

  @override
  String get ageVerifyRejectedUnderage =>
      'Il documento indica che hai meno di 18 anni.';

  @override
  String get ageVerifyRejectedReused =>
      'Questo documento è già collegato a un altro account.';

  @override
  String get ageVerifyCta => 'Verifica ora';

  @override
  String get ageVerifyLater => 'Non ora';

  @override
  String get ageVerifyNeededToPost => 'Verifica l\'età per pubblicare';

  @override
  String get contactSupportSubtitle =>
      'Domande, problemi o segnalazioni — rispondiamo via email';

  @override
  String get offerPreRegisteredTitle => 'Sei pre-registrato';

  @override
  String get offerWelcomePackTitle => 'Il tuo pacchetto di benvenuto';

  @override
  String offerTierLine(String tier, String duration) {
    return 'Abbonamento $tier per $duration';
  }

  @override
  String offerBaseLine(String duration) {
    return 'Abbonamento Base per $duration';
  }

  @override
  String get offerFreeMonthLine => 'Un mese di accesso completo gratuito';

  @override
  String offerCoinsLine(int coins) {
    return '$coins monete di benvenuto';
  }

  @override
  String get offerAppliedFromToday =>
      'Aggiunto automaticamente da oggi, al primo accesso.';

  @override
  String get offerDurationOneMonth => '1 mese';

  @override
  String offerDurationMonths(int count) {
    return '$count mesi';
  }

  @override
  String get offerDurationOneYear => '1 anno';

  @override
  String offerDurationDays(int count) {
    return '$count giorni';
  }

  @override
  String get featureIncludedTitle => 'COSA INCLUDE';

  @override
  String get featureUnlimited => 'Illimitati';

  @override
  String featureDailyConnects(String count) {
    return '$count nuovi contatti ogni giorno';
  }

  @override
  String featureMonthlyCoins(int coins) {
    return '$coins monete ogni mese';
  }

  @override
  String featureEvents(String count) {
    return '$count eventi attivi contemporaneamente';
  }

  @override
  String featureBoosts(int count) {
    return '$count boost del profilo al mese';
  }

  @override
  String featureDiscoveryReveals(int count) {
    return '$count profili visibili per volta';
  }

  @override
  String get featureTravelMode => 'Modalità viaggio - scopri persone ovunque';

  @override
  String get featureWhoConnected => 'Scopri chi si è connesso con te';

  @override
  String get boostProfileCelebrationTitle => 'Profilo in evidenza!';

  @override
  String get boostEventCelebrationTitle => 'Evento in evidenza!';

  @override
  String get eventsEnded => 'Evento concluso';

  @override
  String get eventsAttendeeListVisibility => 'Chi può vedere i partecipanti';

  @override
  String get eventsAttendeeListPrivate => 'Nessuno';

  @override
  String get eventsAttendeeListParticipants => 'Partecipanti';

  @override
  String get eventsAttendeeListPublic => 'Tutti';

  @override
  String get eventsAttendeeListPrivateHint =>
      'Solo tu puoi vedere l\'elenco dei partecipanti.';

  @override
  String get eventsAttendeeListParticipantsHint =>
      'Chi partecipa può vedere gli altri partecipanti.';

  @override
  String get eventsAttendeeListPublicHint =>
      'Chiunque veda l\'evento può vedere l\'elenco dei partecipanti.';

  @override
  String get eventsAttendeeListHidden =>
      'L\'organizzatore ha nascosto l\'elenco dei partecipanti.';

  @override
  String get eventsOrganizedBy => 'Organizzato da';

  @override
  String eventsOrganizerYou(String name) {
    return '$name (tu)';
  }

  @override
  String eventsByOrganizer(String name) {
    return 'di $name';
  }

  @override
  String shareEventMessageTitled(String title, String link) {
    return '$title\nGuarda questo evento su GreenGo: $link';
  }

  @override
  String shareCommunityMessage(String name, String link) {
    return '$name\nUnisciti a questa community su GreenGo: $link';
  }

  @override
  String shopMembershipExpiredOn(String tier, String date) {
    return 'La tua membership $tier è scaduta il $date';
  }

  @override
  String get eventsLocationHelper =>
      'Scrivi un luogo o un indirizzo, oppure sceglilo sulla mappa';

  @override
  String get eventsPickOnMap => 'Scegli sulla mappa';

  @override
  String get eventsLocationNotOnMap =>
      'Salvato con il luogo che hai scritto. Non siamo riusciti a trovarlo sulla mappa, quindi non comparirà nelle ricerche nei dintorni.';

  @override
  String get eventsCoOwners => 'Co-organizzatori';

  @override
  String get eventsCoOwnersHelper =>
      'I co-organizzatori possono modificare l\'evento, aprire l\'elenco presenze, registrare l\'ingresso degli ospiti e vedere l\'elenco completo dei partecipanti. Solo tu puoi eliminare l\'evento o cambiare i co-organizzatori.';

  @override
  String get eventsCoOwnersCreatorOnly =>
      'Solo chi ha creato l\'evento può cambiare i co-organizzatori.';

  @override
  String get eventsAddCoOwner => 'Aggiungi co-organizzatore';

  @override
  String eventsCoOwnerLimit(int max) {
    return 'Puoi aggiungere fino a $max co-organizzatori';
  }

  @override
  String get eventsCoOwnerSearchHint => 'Cerca per nickname';

  @override
  String get eventsCoOwnerSearch => 'Cerca';

  @override
  String get eventsCoOwnerRecentChats => 'Chat recenti';

  @override
  String get eventsCoOwnerNoRecentChats => 'Ancora nessuna chat recente';

  @override
  String get eventsCoOwnerNotFound => 'Nessuno trovato con questo nickname';

  @override
  String get eventsCoOwnerSearchFailed => 'Ricerca non riuscita. Riprova.';

  @override
  String get eventsCoOwnerRemove => 'Rimuovi co-organizzatore';

  @override
  String eventsOrganizedWith(String names) {
    return 'con $names';
  }

  @override
  String get eventsCoOwnerBadge => 'Co-organizzatore';

  @override
  String get qrHubCancelRsvpConfirm =>
      'Eliminare questo biglietto? La tua partecipazione verrà annullata e il tuo posto sarà libero per qualcun altro.';

  @override
  String get qrHubHideTicketConfirm =>
      'Rimuovere questo biglietto dalla tua lista? La tua presenza resta registrata.';

  @override
  String get qrHubTicketRemoved => 'Biglietto rimosso';

  @override
  String get usageDailyUsageTitle => 'Utilizzo giornaliero';

  @override
  String get usageConnectsThisHour => 'Connessioni quest\'ora';

  @override
  String get usagePassesThisHour => 'Passaggi quest\'ora';

  @override
  String get usagePriorityConnectsThisHour =>
      'Connessioni prioritarie quest\'ora';

  @override
  String get usageMessagesToday => 'Messaggi oggi';

  @override
  String get usageMediaSentToday => 'Media inviati oggi';

  @override
  String get usageUpgradeBenefitsTitle => 'Vantaggi dell\'upgrade';

  @override
  String get usageUpgradeButton => 'Passa a un piano superiore';

  @override
  String usagePlanName(String tier) {
    return 'Piano $tier';
  }

  @override
  String get usageCurrentTierLabel => 'Livello di abbonamento attuale';

  @override
  String get usageNoBaseMembership => 'Nessuna membership base GreenGo';

  @override
  String usageExpiresOn(String date) {
    return 'Scade: $date';
  }

  @override
  String usageExpiredOn(String date) {
    return 'Scaduta: $date';
  }

  @override
  String get usageStatusActive => 'Attiva';

  @override
  String get usageStatusExpired => 'Scaduta';

  @override
  String get usageCoinsAvailable => 'Monete disponibili';

  @override
  String get usageNotAvailable => 'Non disponibile';

  @override
  String usageWithTier(String tier) {
    return 'Con $tier';
  }

  @override
  String get attrApplyFilter => 'Applica filtro';

  @override
  String get userFollowFollow => 'Segui';

  @override
  String get userFollowFollowing => 'Segui già';

  @override
  String get userFollowFollowBack => 'Ricambia';

  @override
  String get userFollowError => 'Impossibile aggiornare. Riprova.';

  @override
  String get userFollowBlocked => 'Non puoi seguire questo utente.';

  @override
  String get userFollowUnfollowTooltip => 'Smetti di seguire';

  @override
  String userFollowFollowersStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted follower',
    );
    return '$_temp0';
  }

  @override
  String userFollowFollowingStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted seguiti',
    );
    return '$_temp0';
  }

  @override
  String get userFollowTabFollowers => 'Follower';

  @override
  String get userFollowTabFollowing => 'Seguiti';

  @override
  String get userFollowEmptyFollowers => 'Ancora nessun follower';

  @override
  String get userFollowEmptyFollowing => 'Non segue ancora nessuno';

  @override
  String get userFollowListError => 'Impossibile caricare questo elenco.';

  @override
  String attractionViewsCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted visualizzazioni',
      one: '$formatted visualizzazione',
    );
    return '$_temp0';
  }

  @override
  String get uexpCommunity => 'Community';

  @override
  String get uexpPartners => 'Partner';

  @override
  String get uexpCreate => 'Crea esperienza';

  @override
  String get uexpMine => 'Le mie esperienze';

  @override
  String get uexpEmpty =>
      'Ancora nessuna esperienza della community. Sii il primo a proporne una!';

  @override
  String get uexpMineEmpty => 'Non hai ancora creato nessuna esperienza.';

  @override
  String get uexpAll => 'Tutte';

  @override
  String get uexpFree => 'Gratis';

  @override
  String get uexpCatFoodDrink => 'Cibo e bevande';

  @override
  String get uexpCatCultureHistory => 'Cultura e storia';

  @override
  String get uexpCatNatureOutdoors => 'Natura e aria aperta';

  @override
  String get uexpCatNightlife => 'Vita notturna';

  @override
  String get uexpCatSportsAdventure => 'Sport e avventura';

  @override
  String get uexpCatWellness => 'Benessere';

  @override
  String get uexpCatLanguageLearning => 'Apprendimento delle lingue';

  @override
  String get uexpCatToursWalks => 'Tour e passeggiate';

  @override
  String get uexpCatWorkshopsClasses => 'Workshop e corsi';

  @override
  String get uexpCatOther => 'Altro';

  @override
  String uexpReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recensioni',
      one: '1 recensione',
      zero: 'Nessuna recensione',
    );
    return '$_temp0';
  }

  @override
  String get uexpStatusDraft => 'Bozza';

  @override
  String get uexpStatusPublished => 'Pubblicata';

  @override
  String get uexpStatusHidden => 'Nascosta';

  @override
  String get uexpHiddenNotice =>
      'Questa esperienza è stata nascosta perché viola gli standard di GreenGo. Modifica il testo per ripristinarla.';

  @override
  String get uexpNewTitle => 'Nuova esperienza';

  @override
  String get uexpEditTitle => 'Modifica l\'esperienza';

  @override
  String get uexpSectionPhotos => 'Foto';

  @override
  String get uexpSectionBasics => 'Informazioni sull\'esperienza';

  @override
  String get uexpSectionPractical => 'Informazioni pratiche';

  @override
  String get uexpMainPhoto => 'Foto principale (obbligatoria)';

  @override
  String uexpMorePhotos(int max) {
    return 'fino a $max foto in più';
  }

  @override
  String get uexpFieldTitle => 'Titolo';

  @override
  String get uexpFieldDescription => 'Descrizione';

  @override
  String get uexpFieldCategory => 'Categoria';

  @override
  String get uexpIncluded => 'Cosa è incluso';

  @override
  String get uexpNotIncluded => 'Cosa non è incluso';

  @override
  String get uexpAddItem => 'Aggiungi voce';

  @override
  String get uexpRemoveItem => 'Rimuovi voce';

  @override
  String get uexpItemHint => 'es. Snack locali';

  @override
  String get uexpFieldLocation => 'Luogo';

  @override
  String get uexpLocationHint => 'Scrivi un luogo o sceglilo sulla mappa';

  @override
  String get uexpPickOnMap => 'Scegli sulla mappa';

  @override
  String get uexpMeetingPoint => 'Punto di incontro (facoltativo)';

  @override
  String get uexpMeetingPointLabel => 'Punto di incontro';

  @override
  String get uexpLocationNotFound =>
      'Non abbiamo trovato questo luogo sulla mappa. Viene salvato come scritto e non comparirà nei risultati vicini.';

  @override
  String get uexpDuration => 'Durata';

  @override
  String get uexpHours => 'Ore';

  @override
  String get uexpMinutes => 'Minuti';

  @override
  String uexpDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String uexpDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get uexpLanguages => 'Lingue parlate';

  @override
  String get uexpGroupSize => 'Dimensione del gruppo';

  @override
  String get uexpMinGroup => 'Min. persone (facoltativo)';

  @override
  String get uexpMaxGroup => 'Max. persone';

  @override
  String uexpGroupSizeRange(int min, int max) {
    return '$min–$max persone';
  }

  @override
  String uexpGroupUpTo(int max) {
    return 'Fino a $max persone';
  }

  @override
  String get uexpPrice => 'Prezzo';

  @override
  String get uexpCurrency => 'Valuta';

  @override
  String get uexpIsFree => 'Questa esperienza è gratuita';

  @override
  String get uexpPaymentLink => 'Come ti pagano i partecipanti';

  @override
  String get uexpPaymentType => 'Metodo di pagamento';

  @override
  String get uexpPayPix => 'PIX';

  @override
  String get uexpPayPaypal => 'PayPal';

  @override
  String get uexpPayVenmo => 'Venmo';

  @override
  String get uexpPayStripe => 'Link di pagamento Stripe';

  @override
  String get uexpPayOther => 'Altro link di pagamento';

  @override
  String get uexpPaymentValuePix => 'Chiave PIX';

  @override
  String get uexpPaymentValueUrl => 'Link di pagamento';

  @override
  String get uexpPaymentValueHintPix => 'Email, telefono, CPF o chiave casuale';

  @override
  String get uexpPaymentDisclaimer =>
      'I pagamenti avvengono fuori da GreenGo, direttamente tra i partecipanti e l\'host. GreenGo non li elabora, non li garantisce e non li rimborsa.';

  @override
  String get uexpAvailability => 'Disponibilità (facoltativo)';

  @override
  String get uexpAvailabilityLabel => 'Disponibilità';

  @override
  String get uexpAvailabilityHint => 'es. il sabato 10:00–13:00';

  @override
  String get uexpCancellation => 'Politica di cancellazione (facoltativo)';

  @override
  String get uexpCancellationLabel => 'Politica di cancellazione';

  @override
  String get uexpSaveDraft => 'Salva come bozza';

  @override
  String get uexpPublish => 'Pubblica';

  @override
  String get uexpSaveChanges => 'Salva modifiche';

  @override
  String get uexpUnpublish => 'Annulla pubblicazione';

  @override
  String get uexpSaved => 'Esperienza salvata';

  @override
  String get uexpPublished => 'Esperienza pubblicata';

  @override
  String get uexpUnpublished => 'Esperienza spostata nelle bozze';

  @override
  String get uexpSaveFailed => 'Impossibile salvare l\'esperienza. Riprova.';

  @override
  String get uexpPhotoUploadFailed => 'Impossibile caricare le foto. Riprova.';

  @override
  String uexpErrTitle(int min, int max) {
    return 'Il titolo deve avere da $min a $max caratteri';
  }

  @override
  String uexpErrDescription(int min, int max) {
    return 'La descrizione deve avere da $min a $max caratteri';
  }

  @override
  String get uexpErrMainPhoto => 'Aggiungi una foto principale';

  @override
  String uexpErrTooManyPhotos(int max) {
    return 'Fino a $max foto aggiuntive';
  }

  @override
  String get uexpErrIncluded => 'Aggiungi almeno una voce inclusa';

  @override
  String uexpErrTooManyItems(int max) {
    return 'Fino a $max voci';
  }

  @override
  String uexpErrItemTooLong(int max) {
    return 'Ogni voce può avere fino a $max caratteri';
  }

  @override
  String get uexpErrLocation => 'Inserisci un luogo';

  @override
  String get uexpErrDuration =>
      'Inserisci una durata tra 15 minuti e 14 giorni';

  @override
  String get uexpErrLanguages => 'Scegli almeno una lingua';

  @override
  String uexpErrMaxGroup(int max) {
    return 'Il numero massimo di persone deve essere tra 1 e $max';
  }

  @override
  String get uexpErrMinGroup =>
      'Il minimo deve essere almeno 1 e non superare il massimo';

  @override
  String get uexpErrPrice => 'Inserisci un prezzo valido';

  @override
  String get uexpErrPaymentRequired =>
      'Indica come pagarti (o segna l\'esperienza come gratuita)';

  @override
  String get uexpErrPaymentInvalid =>
      'Inserisci un link valido che inizi con https://';

  @override
  String get uexpErrProhibited =>
      'Un testo contiene un linguaggio non consentito su GreenGo';

  @override
  String get uexpErrNoLinks =>
      'I link non sono consentiti nelle recensioni e nelle risposte';

  @override
  String uexpErrTooLong(int max) {
    return 'Fino a $max caratteri';
  }

  @override
  String get uexpErrFixFields => 'Correggi i campi evidenziati';

  @override
  String get uexpLimitFeature => 'Proponi esperienze';

  @override
  String get uexpLimitFreeBody =>
      'Proporre esperienze è disponibile con un abbonamento Silver, Gold o Platinum.';

  @override
  String uexpLimitReachedBody(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Il tuo piano consente $limit esperienze.',
      one: 'Il tuo piano consente 1 esperienza.',
    );
    return '$_temp0 Passa a un piano superiore per crearne altre.';
  }

  @override
  String get uexpUpgradeToCreateMore =>
      'Passa a un piano superiore per creare più esperienze';

  @override
  String get shopExperiencesCreate => 'Esperienze che puoi creare';

  @override
  String get uexpHostedBy => 'Organizzata da';

  @override
  String get uexpHostBadge => 'Host';

  @override
  String get uexpPayBook => 'Paga / Prenota';

  @override
  String get uexpPixCopied => 'Chiave PIX copiata negli appunti';

  @override
  String get uexpOpenLinkFailed => 'Impossibile aprire il link';

  @override
  String get uexpShare => 'Condividi';

  @override
  String uexpShareText(String title, String link) {
    return '$title\nScopri questa esperienza su GreenGo: $link';
  }

  @override
  String get uexpReport => 'Segnala';

  @override
  String get uexpReportTitle => 'Segnalare questa esperienza?';

  @override
  String get uexpReportBody =>
      'Il nostro team la verificherà secondo gli standard di GreenGo.';

  @override
  String get uexpReported => 'Grazie, lo verificheremo.';

  @override
  String get uexpReportReview => 'Segnala recensione';

  @override
  String get uexpEdit => 'Modifica';

  @override
  String get uexpDelete => 'Elimina';

  @override
  String get uexpDeleteConfirmTitle => 'Eliminare questa esperienza?';

  @override
  String get uexpDeleteConfirmBody =>
      'Verranno eliminate anche le recensioni. Non si può annullare.';

  @override
  String get uexpDeleted => 'Esperienza eliminata';

  @override
  String get uexpNotFound => 'Questa esperienza non è più disponibile.';

  @override
  String get uexpReviews => 'Recensioni';

  @override
  String get uexpNoReviews => 'Ancora nessuna recensione';

  @override
  String get uexpWriteReview => 'Scrivi una recensione';

  @override
  String get uexpEditReview => 'Modifica la tua recensione';

  @override
  String get uexpYourRating => 'Il tuo voto';

  @override
  String get uexpSelectRating => 'Scegli da 1 a 5 stelle';

  @override
  String get uexpCommentHint => 'Racconta cosa ti è piaciuto (facoltativo)';

  @override
  String get uexpSubmit => 'Invia';

  @override
  String get uexpDeleteReview => 'Elimina recensione';

  @override
  String get uexpDeleteReviewConfirm => 'Eliminare la tua recensione?';

  @override
  String get uexpReviewSaved => 'Recensione salvata';

  @override
  String get uexpReviewDeleted => 'Recensione eliminata';

  @override
  String get uexpReviewRemoved =>
      'La tua recensione è stata rimossa perché viola gli standard di GreenGo. Modificala per riprovare.';

  @override
  String get uexpReplyRemoved =>
      'La tua risposta è stata rimossa perché viola gli standard di GreenGo.';

  @override
  String get uexpPendingModeration => 'In verifica…';

  @override
  String get uexpHostCannotReview =>
      'Gli host non possono recensire la propria esperienza.';

  @override
  String get uexpReply => 'Rispondi';

  @override
  String get uexpReplyHint =>
      'Scrivi una risposta. Digita @ per taggare qualcuno';

  @override
  String get uexpShowMoreReplies => 'Mostra altre risposte';

  @override
  String get uexpLoadMoreReviews => 'Carica altre recensioni';

  @override
  String get uexpEdited => 'modificata';

  @override
  String get feedFilterTooltip => 'Mostra';

  @override
  String get feedFilterAll => 'Tutto';

  @override
  String get feedFilterCommunity => 'Community';

  @override
  String get feedFilterPartner => 'Partner';

  @override
  String get feedFilterMyEvents => 'I miei eventi';

  @override
  String get feedFilterMyExperiences => 'Le mie esperienze';

  @override
  String get partnerBadge => 'Partner';

  @override
  String get createChooserTitle => 'Cosa vuoi creare?';

  @override
  String get createChooserEventDesc =>
      'Organizza un incontro o un\'attività a cui possono unirsi persone vicine';

  @override
  String get createChooserExperienceDesc =>
      'Offri come host un tour, un corso o un\'esperienza locale';

  @override
  String get uexpAddExperience => 'Aggiungi esperienza';

  @override
  String get uexpNewHost => 'Nuovo host';

  @override
  String uexpHostRatings(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText valutazioni',
      one: '$countText valutazione',
    );
    return '$_temp0';
  }

  @override
  String get verifiedBadgeLabel => 'Verificato';

  @override
  String get verifiedBadgeTooltip => 'Documento verificato da GreenGo';

  @override
  String get idDocumentRetentionNotice =>
      'Per la prevenzione delle frodi e la sicurezza della community, i documenti di identità vengono conservati fino a 30 giorni dopo l\'eliminazione dell\'account e poi cancellati definitivamente.';

  @override
  String get uexpErrContactInfo =>
      'Rimuovi numeri di telefono, e-mail, @nomi utente e dati di pagamento: gli ospiti pagano solo con i metodi del tuo annuncio.';

  @override
  String get uexpErrPaymentMethods => 'Scegli almeno un metodo di pagamento';

  @override
  String get uexpPaymentLinkDetails => 'Link di pagamento online';

  @override
  String get uexpMethodCash => 'In contanti all\'incontro';

  @override
  String get uexpMethodLink => 'Link online (PIX/PayPal/…)';

  @override
  String get uexpBook => 'Prenota';

  @override
  String get uexpBookedCash => 'Fatto. Paga l\'host in contanti all\'incontro.';

  @override
  String get uexpIdDocTitle => 'Serve un documento d\'identità';

  @override
  String get uexpIdDocGuestBody =>
      'Per mantenere GreenGo sicuro, carica un documento d\'identità prima di pagare un host.';

  @override
  String get uexpIdDocHostBody =>
      'Gli host devono caricare un documento d\'identità prima di creare un\'esperienza.';

  @override
  String get uexpIdDocUpload => 'Carica documento';

  @override
  String get uexpPaidPendingTitle => 'Verifica del documento in corso';

  @override
  String get uexpPaidPendingBody =>
      'Le esperienze a pagamento richiedono un documento approvato. Il tuo è ancora in verifica: per ora salvala come bozza o pubblicala gratis.';

  @override
  String get uexpPaidMissingBody =>
      'Le esperienze a pagamento richiedono un documento approvato. Caricane uno (o uno nuovo se non è stato approvato), oppure per ora salvala come bozza o pubblicala gratis.';

  @override
  String get uexpNewHostLimitTitle => 'Limite per i nuovi host';

  @override
  String get uexpNewHostLimitBody =>
      'Finché non hai 3 recensioni puoi avere una sola esperienza a pagamento pubblicata. Salva questa come bozza o pubblicala gratis.';

  @override
  String get uexpPublishAsFree => 'Pubblica gratis';

  @override
  String get uexpHostBanned => 'Il tuo account non può ospitare esperienze.';

  @override
  String get hostAgreementTitle => 'Accordo per gli host';

  @override
  String get hostAgreementIntro =>
      'Prima di pubblicare la tua prima esperienza, leggi e accetta queste regole.';

  @override
  String get hostAgreementClause1 =>
      'Organizzi e conduci questa esperienza e sei responsabile di essa e della sicurezza dei tuoi ospiti.';

  @override
  String get hostAgreementClause2 =>
      'Descrivila con precisione: titolo, foto, prezzo, durata, cosa è incluso e punto d\'incontro devono essere veri e aggiornati.';

  @override
  String get hostAgreementClause3 =>
      'Rispetta la legge: possiedi licenze, permessi, assicurazioni o registrazioni richiesti per la tua attività nel luogo in cui si svolge e dichiari i tuoi redditi come previsto.';

  @override
  String get hostAgreementClause4 =>
      'Rimborsa gli ospiti secondo la politica di cancellazione scelta, e sempre per intero se sei tu ad annullare.';

  @override
  String get hostAgreementClause5 =>
      'Non chiedere mai agli ospiti di pagare al di fuori dei metodi indicati nel tuo annuncio e non inserire numeri di telefono, e-mail o account di pagamento nel testo dell\'annuncio.';

  @override
  String get hostAgreementClause6 =>
      'Tratta gli ospiti con rispetto: niente discriminazioni, molestie o situazioni pericolose.';

  @override
  String get hostAgreementClause7 =>
      'GreenGo può nascondere o rimuovere annunci e sospendere o bannare gli account che violano queste regole o ricevono segnalazioni credibili.';

  @override
  String get hostAgreementCheckbox =>
      'Ho letto e accetto l\'accordo per gli host';

  @override
  String get hostAgreementAccept => 'Accetta e continua';

  @override
  String get uexpConsentTitle => 'Prima di pagare';

  @override
  String get uexpConsentBodyLink =>
      'Stai pagando direttamente l\'host. GreenGo non gestisce né garantisce questo pagamento e non può rimborsarlo. Preferisci metodi protetti (PayPal Beni e servizi, carta di credito). Non pagare mai al di fuori del link mostrato qui.';

  @override
  String get uexpConsentBodyCash =>
      'Pagherai l\'host in contanti all\'incontro. GreenGo non gestisce né garantisce questo pagamento e non può rimborsarlo. Conta il denaro, chiedi una ricevuta se serve e non pagare mai in anticipo al di fuori dei metodi indicati in questa pagina.';

  @override
  String get uexpConsentPickMethod => 'Come pagherai?';

  @override
  String uexpConsentPolicy(String policy) {
    return 'Politica di cancellazione: $policy';
  }

  @override
  String get uexpConsentUnderstand => 'Ho capito';

  @override
  String get uexpConsentContinue => 'Continua';

  @override
  String get uexpGuidePix =>
      'PIX: se sei vittima di una truffa, chiedi subito alla tua banca di aprire una richiesta MED (Mecanismo Especial de Devolução).';

  @override
  String get uexpGuidePaypal =>
      'PayPal: scegli «Beni e servizi», mai «Amici e familiari», per mantenere la protezione acquisti.';

  @override
  String get uexpGuideVenmo =>
      'Venmo: usa la protezione acquisti (beni e servizi) quando disponibile.';

  @override
  String get uexpGuideCard =>
      'I pagamenti con carta possono essere contestati presso l\'emittente della carta.';

  @override
  String get uexpGuideCash =>
      'Paga solo quando incontri l\'host, contate insieme il denaro e chiedi una ricevuta se serve.';

  @override
  String get uexpPolicyFlexible => 'Flessibile';

  @override
  String get uexpPolicyModerate => 'Moderata';

  @override
  String get uexpPolicyStrict => 'Rigida';

  @override
  String get uexpPolicyFlexibleDesc =>
      'Rimborso completo se annulli almeno 24 h prima dell\'inizio; nessun rimborso dopo.';

  @override
  String get uexpPolicyModerateDesc =>
      'Rimborso completo se annulli almeno 7 giorni prima; 50% se almeno 24 h prima; nessun rimborso dopo.';

  @override
  String get uexpPolicyStrictDesc =>
      'Rimborso completo se annulli almeno 7 giorni prima; nessun rimborso dopo.';

  @override
  String get uexpPolicyWhen => 'Se annulli';

  @override
  String get uexpPolicyRefund => 'Rimborso';

  @override
  String get uexpPolicyMoreThan7d => '7 giorni o più prima';

  @override
  String get uexpPolicy7dTo24h => 'Meno di 7 giorni, ma almeno 24 h prima';

  @override
  String get uexpPolicyMoreThan24h => '24 h o più prima';

  @override
  String get uexpPolicyLess24h => 'Meno di 24 ore prima';

  @override
  String get uexpPolicyLess7d => 'Meno di 7 giorni prima';

  @override
  String get uexpPolicyAlwaysTitle => 'Vale sempre';

  @override
  String get uexpRuleHostCancels => 'L\'host annulla: rimborso del 100%.';

  @override
  String get uexpRuleGrace =>
      'Annulli entro 24 h dalla conferma della prenotazione da parte dell\'host e mancano più di 48 h all\'esperienza: rimborso del 100%.';

  @override
  String get uexpRuleReport =>
      'L\'host non si è presentato o non era come descritto: segnalalo entro 24 ore.';

  @override
  String get uexpPolicyNotes => 'Note sulla tua politica (facoltative)';

  @override
  String get uexpPolicyHostNotes => 'Note dell\'host';

  @override
  String get uexpReportScamTitle => 'Segnala questa esperienza';

  @override
  String get uexpReasonScam => 'Truffa o frode';

  @override
  String get uexpReasonOffPlatform => 'Ha chiesto di pagare fuori dall\'app';

  @override
  String get uexpReasonMisleading => 'Non come descritto';

  @override
  String get uexpReasonNoShow => 'L\'host non si è presentato';

  @override
  String get uexpReasonInappropriate => 'Inappropriato';

  @override
  String get uexpReasonOther => 'Altro';

  @override
  String get uexpReportDetailsHint => 'Cosa è successo? (facoltativo)';

  @override
  String get uexpReportSend => 'Invia segnalazione';

  @override
  String get bkStatusRequested => 'Richiesta';

  @override
  String get bkStatusConfirmed => 'Confermata';

  @override
  String get bkStatusDeclined => 'Rifiutata';

  @override
  String get bkStatusExpired => 'Scaduta';

  @override
  String get bkStatusCancelledGuest => 'Annullata dall\'ospite';

  @override
  String get bkStatusCancelledHost => 'Annullata dall\'host';

  @override
  String get bkStatusCompleted => 'Completata';

  @override
  String get bkStatusNoShow => 'Mancata presenza';

  @override
  String get bkStatusDisputed => 'Problema segnalato';

  @override
  String get bkStatusResolved => 'Risolta';

  @override
  String get bkStatusUnknown => 'Sconosciuto';

  @override
  String get bkRequestToBook => 'Richiedi prenotazione';

  @override
  String get bkChooseDate => 'Scegli una data';

  @override
  String get bkNoDates => 'Ancora nessuna data disponibile.';

  @override
  String bkDatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count date disponibili',
      one: '1 data disponibile',
    );
    return '$_temp0';
  }

  @override
  String bkSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posti liberi',
      one: '1 posto libero',
    );
    return '$_temp0';
  }

  @override
  String get bkFull => 'Al completo';

  @override
  String get bkGuests => 'Ospiti';

  @override
  String bkGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ospiti',
      one: '1 ospite',
    );
    return '$_temp0';
  }

  @override
  String bkMaxGuests(int max) {
    return 'Fino a $max in questa data';
  }

  @override
  String get bkSummary => 'Riepilogo';

  @override
  String get bkRequestInfo =>
      'L\'host ha fino a 48 ore per accettare la richiesta. Non si paga nulla prima dell\'accettazione.';

  @override
  String get bkInstantInfo => 'Prenotazione immediata: confermata subito.';

  @override
  String get bkConfirmBooking => 'Conferma prenotazione';

  @override
  String get bkSendRequest => 'Invia richiesta';

  @override
  String get bkRetry => 'Riprova';

  @override
  String get bkResultConfirmedTitle => 'Prenotazione fatta!';

  @override
  String get bkResultConfirmedBody =>
      'Mostra il codice di check-in all\'host quando vi incontrate. Lo trovi in Le mie prenotazioni.';

  @override
  String get bkResultRequestTitle => 'Richiesta inviata';

  @override
  String get bkResultRequestBody =>
      'Ti avviseremo appena l\'host risponde (entro 48 ore).';

  @override
  String get bkViewBooking => 'Vedi prenotazione';

  @override
  String get bkDone => 'Fatto';

  @override
  String get bkPayment => 'Pagamento';

  @override
  String get bkCashAtMeeting =>
      'Paga l\'host in contanti quando vi incontrate.';

  @override
  String get bkPayLinkHint =>
      'Paga l\'host con il suo link, poi tocca \"Segna come pagata\" nella prenotazione.';

  @override
  String get bkPayAfterAccept =>
      'Pagherai con il link dell\'host quando accetterà la richiesta.';

  @override
  String get bkPayNow => 'Apri link di pagamento';

  @override
  String get bkCopyPixKey => 'Copia chiave PIX';

  @override
  String get bkMyBookings => 'Le mie prenotazioni';

  @override
  String get bkHostBookings => 'Prenotazioni ricevute';

  @override
  String get bkUpcoming => 'In arrivo';

  @override
  String get bkPast => 'Passate';

  @override
  String get bkNoUpcoming => 'Nessuna prenotazione in arrivo.';

  @override
  String get bkNoPast => 'Nessuna prenotazione passata.';

  @override
  String get bkBookings => 'Prenotazioni';

  @override
  String get bkViewBookings => 'Vedi prenotazioni';

  @override
  String get bkDetailTitle => 'Prenotazione';

  @override
  String get bkNotFound => 'Questa prenotazione non è disponibile.';

  @override
  String get bkExperienceGone => 'Questa esperienza non è più pubblicata.';

  @override
  String get bkOpenExperience => 'Apri l\'esperienza';

  @override
  String get bkGuest => 'Ospite';

  @override
  String get bkCheckedIn => 'Check-in fatto';

  @override
  String bkAnswerBefore(String date) {
    return 'Rispondi entro $date';
  }

  @override
  String get bkWaitingForHost => 'In attesa della risposta dell\'host.';

  @override
  String get bkRequestTitle => 'Richiesta di prenotazione';

  @override
  String get bkRequestHostHint =>
      'Controlla profilo e valutazione dell\'ospite, poi accetta o rifiuta. Le richieste senza risposta scadono dopo 48 ore.';

  @override
  String get bkAccept => 'Accetta';

  @override
  String get bkDecline => 'Rifiuta';

  @override
  String get bkDeclineConfirm => 'Rifiutare questa richiesta?';

  @override
  String get bkDeclineBody =>
      'L\'ospite viene avvisato e i posti tornano liberi.';

  @override
  String get bkAccepted => 'Prenotazione accettata';

  @override
  String get bkDeclined => 'Richiesta rifiutata';

  @override
  String get bkCheckInTitle => 'Check-in';

  @override
  String get bkShowCode => 'Mostra codice di check-in';

  @override
  String get bkCodeTitle => 'Il tuo codice di check-in';

  @override
  String get bkCodeHint =>
      'Mostra questo codice QR all\'host quando vi incontrate. Può anche digitare il codice.';

  @override
  String get bkCheckInGuest => 'Fai il check-in dell\'ospite';

  @override
  String get bkScanQr => 'Scansiona codice QR';

  @override
  String get bkTypeCode => 'Digita il codice';

  @override
  String get bkCodeLabel => 'Codice di check-in';

  @override
  String get bkScanInstructions => 'Inquadra il codice QR dell\'ospite';

  @override
  String get bkWrongBooking => 'Questo codice QR è di un\'altra prenotazione.';

  @override
  String get bkTorch => 'Flash';

  @override
  String get bkSwitchCamera => 'Cambia fotocamera';

  @override
  String get bkCashReceivedQuestion =>
      'Hai ricevuto anche il pagamento in contanti?';

  @override
  String get bkCashYes => 'Sì, ricevuto';

  @override
  String get bkCashNo => 'Non ancora';

  @override
  String get bkCheckedInSnack => 'Check-in ospite fatto';

  @override
  String get bkMarkNoShow => 'Segna mancata presenza';

  @override
  String get bkNoShowConfirm =>
      'Segnare l\'ospite come non presentato? Nessun rimborso è dovuto e potrà contestare fino a 24 ore dopo la fine.';

  @override
  String get bkNoShowMarked => 'Segnato come non presentato';

  @override
  String get bkNotPaidYet => 'Non ancora segnata come pagata.';

  @override
  String get bkYouMarkedPaid =>
      'L\'hai segnata come pagata. In attesa della conferma dell\'host.';

  @override
  String get bkGuestSaysPaid =>
      'L\'ospite dice di aver pagato. Conferma quando lo ricevi.';

  @override
  String get bkPaymentConfirmed => 'Pagamento confermato dall\'host.';

  @override
  String get bkCashConfirmed => 'Contanti ricevuti (confermato dall\'host).';

  @override
  String get bkMarkPaid => 'Segna come pagata';

  @override
  String get bkConfirmPayment => 'Pagamento ricevuto';

  @override
  String get bkCashReceived => 'Contanti ricevuti';

  @override
  String get bkPaidMarked => 'Segnata come pagata';

  @override
  String get bkPaymentConfirmedSnack => 'Pagamento confermato';

  @override
  String get bkRefundTitle => 'Rimborso';

  @override
  String bkRefundOwed(String percent, String amount) {
    return 'L\'host ti deve rimborsare il $percent ($amount).';
  }

  @override
  String get bkRefundNone =>
      'Secondo la politica di cancellazione non è dovuto alcun rimborso.';

  @override
  String get bkRefundCashUnpaid =>
      'Nessun rimborso dovuto: i contanti non sono mai stati pagati.';

  @override
  String get bkRefundOffPlatform =>
      'GreenGo non gestisce il denaro: l\'host ti rimborsa direttamente, con lo stesso metodo usato per pagare.';

  @override
  String bkIfCancelNow(String percent, String amount) {
    return 'Se annulli ora: rimborso del $percent ($amount).';
  }

  @override
  String get bkIfCancelNowNothing =>
      'Se annulli ora, non è dovuto alcun rimborso.';

  @override
  String get bkIfCancelNowCash =>
      'I contanti si pagano all\'incontro, quindi annullare ora non costa nulla.';

  @override
  String get bkIfCancelNowFree =>
      'Esperienza gratuita: puoi annullare senza costi.';

  @override
  String get bkCancelRequestNoCharge =>
      'L\'host non ha ancora accettato: annullare la richiesta non costa nulla.';

  @override
  String get bkHostCancelWarning =>
      'Se annulli tu, all\'ospite spetta il 100% e conta come cancellazione dell\'host (GreenGo verifica 3 cancellazioni in 90 giorni).';

  @override
  String get bkCancelBooking => 'Annulla prenotazione';

  @override
  String get bkCancelConfirmTitle => 'Annullare questa prenotazione?';

  @override
  String get bkCancelReasonHint => 'Motivo (facoltativo)';

  @override
  String get bkKeepBooking => 'Mantieni prenotazione';

  @override
  String get bkCancelled => 'Prenotazione annullata';

  @override
  String get bkReportProblem => 'Segnala un problema';

  @override
  String get bkDisputeIntro =>
      'L\'host non si è presentato o l\'esperienza non era come descritta? Segnalalo entro 24 ore dalla fine e il nostro team verificherà.';

  @override
  String get bkDisputeHint => 'Cosa è successo? (almeno 10 caratteri)';

  @override
  String get bkSendReport => 'Invia segnalazione';

  @override
  String get bkDisputeSent =>
      'Grazie. Il nostro team verificherà e vi contatterà entrambi.';

  @override
  String get bkDisputeOpen =>
      'È stato segnalato un problema. Il nostro team lo sta verificando.';

  @override
  String bkDisputeResolved(String percent) {
    return 'Verificato da GreenGo: rimborso dovuto del $percent.';
  }

  @override
  String get bkReviewGuest => 'Valuta il tuo ospite';

  @override
  String get bkReviewGuestIntro =>
      'Aiuta gli altri host: com\'è andata con questo ospite? Entrambe le recensioni restano nascoste finché anche l\'ospite valuta, o per 14 giorni.';

  @override
  String get bkReviewGuestHint =>
      'Puntuale, rispettoso, simpatico? (facoltativo)';

  @override
  String get bkGuestReviewSaved =>
      'Grazie! Le recensioni saranno visibili quando anche l\'ospite avrà valutato, o tra 14 giorni.';

  @override
  String get bkGuestReviewed => 'La tua recensione di questo ospite';

  @override
  String get bkGuestReviewHeld =>
      'Nascosta finché anche l\'ospite valuta, o per 14 giorni.';

  @override
  String get bkReviewExperience => 'Valuta l\'esperienza';

  @override
  String get bkReviewExperienceHint =>
      'Racconta com\'è andata: la tua recensione aiuta altri viaggiatori.';

  @override
  String get bkReviewHeld =>
      'La tua recensione sarà pubblicata quando anche l\'host ti avrà valutato, o tra 14 giorni.';

  @override
  String get bkReviewNeedsBooking =>
      'Solo gli ospiti che hanno partecipato con una prenotazione possono valutare questa esperienza.';

  @override
  String get bkNewGuest => 'Nuovo ospite';

  @override
  String get bkDatesTitle => 'Date e disponibilità';

  @override
  String get bkAddDate => 'Aggiungi data';

  @override
  String get bkEditDate => 'Modifica data';

  @override
  String get bkDeleteDate => 'Elimina data';

  @override
  String get bkCancelDate => 'Annulla data';

  @override
  String get bkKeepDate => 'Mantieni data';

  @override
  String get bkCancelDateTitle => 'Annullare questa data?';

  @override
  String bkCancelDateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tutti i $count posti prenotati in questa data vengono annullati e a ogni ospite spetta un rimborso del 100%.',
      one:
          'La prenotazione di questa data viene annullata e all\'ospite spetta un rimborso del 100%.',
    );
    return '$_temp0 Conta come cancellazione dell\'host.';
  }

  @override
  String get bkDateSaved => 'Data salvata';

  @override
  String get bkDateDeleted => 'Data eliminata';

  @override
  String bkDateCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Data annullata: $count prenotazioni annullate',
      one: 'Data annullata: 1 prenotazione annullata',
      zero: 'Data annullata',
    );
    return '$_temp0';
  }

  @override
  String get bkNoDatesHost =>
      'Nessuna data in arrivo. Aggiungi le date che gli ospiti possono prenotare.';

  @override
  String get bkRequestToBookToggle => 'Prenotazione su richiesta';

  @override
  String get bkRequestToBookDesc =>
      'Accetti o rifiuti ogni prenotazione (entro 48 ore). Disattivato: gli ospiti prenotano subito.';

  @override
  String get bkDatesAfterSave =>
      'Salva prima l\'esperienza, poi aggiungi le date da Le mie esperienze.';

  @override
  String get bkDate => 'Data';

  @override
  String get bkStartTime => 'Inizio';

  @override
  String get bkEndTime => 'Fine';

  @override
  String get bkCapacity => 'Posti';

  @override
  String bkBookedOf(int booked, int capacity) {
    return '$booked/$capacity prenotati';
  }

  @override
  String get bkSlotCancelled => 'Annullata';

  @override
  String get bkTimesFrozen =>
      'Ci sono ospiti prenotati in questa data: si può cambiare solo il numero di posti. Per spostarla, annulla la data.';

  @override
  String get bkSlotSaveFailed =>
      'Impossibile salvare la data. Controlla la connessione e riprova.';

  @override
  String get bkSlotErrPast => 'Scegli un orario d\'inizio futuro.';

  @override
  String get bkSlotErrEnd => 'La fine deve essere dopo l\'inizio.';

  @override
  String get bkSlotErrTooLong => 'Una data può durare al massimo 24 ore.';

  @override
  String get bkSlotErrTooFar =>
      'Le date possono essere al massimo un anno avanti.';

  @override
  String bkSlotErrCapacity(int max) {
    return 'Posti: da 1 a $max.';
  }

  @override
  String bkSlotErrBelowBooked(int count) {
    return 'Sono già prenotati $count posti: mantienine almeno altrettanti.';
  }

  @override
  String bkErrSlotFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restano solo $count posti in questa data.',
      one: 'Resta solo 1 posto in questa data.',
      zero: 'Questa data è al completo.',
    );
    return '$_temp0';
  }

  @override
  String get bkErrAlreadyBooked => 'Hai già una prenotazione per questa data.';

  @override
  String get bkErrIdRequired =>
      'Carica un documento d\'identità per prenotare.';

  @override
  String get bkErrHostNotVerified =>
      'Questo host non può ancora accettare prenotazioni a pagamento (identità non verificata).';

  @override
  String get bkErrPaymentMethodRequired => 'Scegli come pagherai.';

  @override
  String get bkErrPaymentMethodNotAccepted =>
      'L\'host non accetta più questo metodo di pagamento. Scegline un altro.';

  @override
  String get bkErrOwnExperience => 'Non puoi prenotare la tua esperienza.';

  @override
  String get bkErrNotAvailable => 'Questa esperienza non è disponibile per te.';

  @override
  String get bkErrSlotStarted => 'Questa data è già iniziata.';

  @override
  String get bkErrSlotClosed => 'Questa data non è più disponibile.';

  @override
  String get bkErrNotBookable => 'Questa esperienza non è prenotabile ora.';

  @override
  String get bkErrPriceInvalid =>
      'Il prezzo di questo annuncio è incompleto. Chiedi all\'host di aggiornarlo.';

  @override
  String get bkErrHostUnavailable =>
      'L\'host non accetta prenotazioni in questo momento.';

  @override
  String get bkErrConsentRequired =>
      'Accetta prima le condizioni di prenotazione.';

  @override
  String bkErrTooManyGuests(int max) {
    return 'Al massimo $max ospiti per prenotazione.';
  }

  @override
  String get bkErrAccountRestricted =>
      'Il tuo account non può prenotare in questo momento.';

  @override
  String get bkErrNetwork =>
      'Problema di connessione. Riprova: non verrai prenotato due volte.';

  @override
  String get bkErrRequestExpired => 'Questa richiesta è scaduta.';

  @override
  String get bkErrStateChanged =>
      'Questa prenotazione è cambiata nel frattempo. Trascina giù per aggiornare.';

  @override
  String get bkErrInvalidCode =>
      'Questo codice di check-in non è valido per questa prenotazione.';

  @override
  String get bkErrOutsideCheckIn =>
      'Il check-in apre 2 ore prima e chiude 12 ore dopo la fine.';

  @override
  String get bkErrTooEarlyNoShow =>
      'Puoi segnare la mancata presenza da 30 minuti dopo l\'inizio.';

  @override
  String get bkErrGuestCheckedIn => 'L\'ospite ha già fatto il check-in.';

  @override
  String get bkErrCashBeforeMeeting =>
      'I contanti si possono confermare dopo aver incontrato l\'ospite.';

  @override
  String get bkErrOutsideDispute =>
      'I problemi si possono segnalare dall\'inizio fino a 24 ore dopo la fine.';

  @override
  String bkErrReasonRequired(int min) {
    return 'Descrivi il problema (almeno $min caratteri).';
  }

  @override
  String get uexpDatesRequiredHint =>
      'Gli ospiti possono prenotare solo le date che imposti e ogni prenotazione è una richiesta che accetti o rifiuti. Aggiungi almeno una data futura per pubblicare.';

  @override
  String get uexpDatesRequiredToPublish =>
      'Aggiungi almeno una data futura per pubblicare. La tua esperienza è salvata come bozza.';

  @override
  String bkRefundIfPaid(String percent, String amount) {
    return 'Se hai già pagato, l\'host ti deve restituire $percent ($amount).';
  }

  @override
  String get shareLinkCopied => 'Link copiato negli appunti';

  @override
  String shareOtherProfileMessage(String name, String link) {
    return 'Scopri $name su GreenGo: $link';
  }

  @override
  String get communitiesExperiencesEmpty => 'Ancora nessuna esperienza';

  @override
  String uexpPostedInCommunity(String community) {
    return 'Pubblicata in $community';
  }

  @override
  String get uexpErrCommunityNotAllowed =>
      'Solo il proprietario e gli amministratori di questa community possono pubblicare esperienze qui.';

  @override
  String attrRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valutazioni',
      one: '1 valutazione',
    );
    return '$_temp0';
  }

  @override
  String get attrNoRatingsYet => 'Ancora nessuna valutazione';

  @override
  String get attrRateThis => 'Valuta questa attrazione';

  @override
  String get attrYourRating => 'La tua valutazione';

  @override
  String get attrRatingRemove => 'Rimuovi la mia valutazione';

  @override
  String get attrRatingFailed => 'Impossibile salvare la valutazione. Riprova.';

  @override
  String get attrRatingGreengoLabel => 'Community GreenGo';

  @override
  String get attrRatingGoogleLabel => 'Valutazione Google';

  @override
  String get webUpdateAvailable =>
      'È disponibile una nuova versione di GreenGo.';

  @override
  String get webUpdateRefresh => 'Aggiorna';

  @override
  String get webUpdateLater => 'Più tardi';

  @override
  String get userErrorTitle => 'Ops!';

  @override
  String get userErrorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get userErrorTimeout =>
      'L\'operazione sta richiedendo più tempo del previsto. Riprova.';

  @override
  String get userErrorPermissionDenied => 'Non hai il permesso di farlo.';

  @override
  String get userErrorNotFound => 'Questo contenuto non è più disponibile.';

  @override
  String get userErrorTooManyRequests =>
      'Stai ripetendo questa azione troppo spesso. Attendi un momento e riprova.';

  @override
  String get userErrorSessionExpired =>
      'La tua sessione è scaduta. Accedi di nuovo.';

  @override
  String get userErrorInvalidInput =>
      'Alcune informazioni non sono valide. Controllale e riprova.';

  @override
  String get userErrorNotAllowed =>
      'Questa azione non è disponibile al momento.';

  @override
  String get userErrorUploadFailed => 'Il caricamento non è riuscito. Riprova.';

  @override
  String videoMaxDurationError(int seconds) {
    return 'Il video deve durare al massimo $seconds secondi';
  }

  @override
  String get exploreLoadingContent => 'Cerchiamo il meglio intorno a te…';

  @override
  String get checkinWrongPlace =>
      'Questo codice è per un altro evento o esperienza';

  @override
  String get checkinOutsideWindow =>
      'Il check-in non è aperto in questo momento';

  @override
  String get checkinNotConfirmed => 'Questa persona non è confermata';

  @override
  String get checkinUpdateApp =>
      'Biglietto vecchio: chiedi di aggiornare GreenGo e mostrare il nuovo codice';

  @override
  String get checkinNetwork => 'Nessuna connessione. Riprova.';

  @override
  String get expDoorTitle => 'Check-in ospiti';

  @override
  String get expDoorInstructions =>
      'Scansiona il QR della prenotazione di ogni ospite';

  @override
  String expDoorCheckedInNow(int count) {
    return '$count registrati';
  }

  @override
  String expDoorAdmits(int count) {
    return 'Ingresso per $count persone';
  }

  @override
  String get expDoorHelpers => 'Aiutanti all\'ingresso';

  @override
  String get expDoorHelpersHint =>
      'I membri che aggiungi qui possono registrare gli ospiti di questa esperienza.';

  @override
  String expDoorHelpersMax(int max) {
    return 'Massimo $max aiutanti';
  }

  @override
  String get expAttendanceTitle => 'Presenze';

  @override
  String get expAttendanceEmpty =>
      'Ancora nessun ospite confermato per le prossime date.';

  @override
  String expAttendanceCount(int checked, int total) {
    return '$checked/$total presenti';
  }

  @override
  String get qrHubExperienceTicket => 'Esperienza';

  @override
  String metInPersonOn(String date) {
    return 'Vi siete incontrati · $date';
  }

  @override
  String metInPersonTimes(int count, String date) {
    return 'Incontrati $count volte · ultima $date';
  }

  @override
  String get paymentLinksTitle => 'Metodi di pagamento';

  @override
  String get paymentLinksNone => 'Nessun metodo di pagamento aggiunto';

  @override
  String paymentLinksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metodi di pagamento',
      one: '1 metodo di pagamento',
    );
    return '$_temp0';
  }

  @override
  String get paymentLinksInfoTitle => 'Ricevi pagamenti diretti';

  @override
  String get paymentLinksInfoBody =>
      'Fatti pagare sui tuoi conti. Il denaro arriva direttamente a te: GreenGo non elabora, non trattiene e non prende commissioni su questi pagamenti.';

  @override
  String get paymentLinksHintHandle => 'Nome utente o link';

  @override
  String get paymentLinksHintPix =>
      'CPF, CNPJ, e-mail, telefono +55 o chiave casuale';

  @override
  String get paymentLinksHintLink => 'Incolla il tuo link di pagamento';

  @override
  String paymentLinkInvalid(String method) {
    return 'Valore $method non valido: controllalo e riprova';
  }

  @override
  String get paymentLinksUpdated => 'Metodi di pagamento aggiornati';

  @override
  String get paymentLinksRules =>
      'Usali solo per pagamenti tra persone (regali, mance, servizi e tour di persona). Monete e abbonamenti GreenGo si acquistano solo nell\'app.';

  @override
  String get paymentLinksSection => 'Paga direttamente';

  @override
  String paymentDisclaimerTitle(String name) {
    return 'Paga $name direttamente';
  }

  @override
  String paymentDisclaimerBody(String name, String method) {
    return 'Questo pagamento va da te a $name tramite $method. GreenGo non è coinvolto e non può rimborsarlo, proteggerlo o verificarlo. Paga solo persone di cui ti fidi.';
  }

  @override
  String paymentContinueTo(String method) {
    return 'Continua su $method';
  }

  @override
  String get pixInstructions =>
      'Scansiona il QR code o copia il codice Pix nell\'app della tua banca, poi inserisci lì l\'importo.';

  @override
  String get pixKeyLabel => 'Chiave Pix';

  @override
  String get pixCopyCode => 'Copia codice Pix';

  @override
  String get pixCopyKey => 'Copia chiave';

  @override
  String get pixCopied =>
      'Copiato: incollalo nell\'area Pix dell\'app della tua banca';

  @override
  String get bkRepeat => 'Ripeti';

  @override
  String get bkRepeatHint => 'Aggiungi questi orari su più date in una volta';

  @override
  String get bkRepeatThisDate => 'Ripeti questa data';

  @override
  String get bkRepeatDates => 'Applica alle date';

  @override
  String get bkRepeatPickRange => 'Scegli le date sul calendario';

  @override
  String get bkRepeatOnDays => 'In questi giorni';

  @override
  String get bkRepeatEveryDay => 'Tutti i giorni';

  @override
  String bkRepeatPreview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verranno aggiunte $count date',
      one: 'Verrà aggiunta 1 data',
      zero:
          'Nessuna data corrisponde — scegli un periodo più ampio o più giorni',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatCapped(int max) {
    return 'fino a $max date alla volta';
  }

  @override
  String bkRepeatAddButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiungi $count date',
      one: 'Aggiungi 1 data',
      zero: 'Aggiungi date',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count date aggiunte',
      one: '1 data aggiunta',
      zero: 'Nessuna nuova data aggiunta',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esistevano già',
      one: '1 esisteva già',
    );
    return '$_temp0';
  }

  @override
  String get bkChooseTime => 'Scegli un orario';

  @override
  String get bkNoFreeTimes => 'Nessun orario libero in questa data';

  @override
  String bkTimesHint(String duration) {
    return 'Ogni orario dura $duration ed è solo per te e il tuo gruppo.';
  }

  @override
  String bkWindowHint(String duration) {
    return 'È il periodo in cui sei disponibile. Ogni ospite prenota il proprio orario di $duration al suo interno e le tue prenotazioni non si sovrappongono mai, in tutte le tue esperienze.';
  }

  @override
  String bkWindowPeopleBooked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone prenotate',
      one: '1 persona prenotata',
      zero: 'Ancora nessuna prenotazione',
    );
    return '$_temp0';
  }

  @override
  String get bkErrTimeTaken =>
      'Quell\'orario è appena stato preso. Scegline un altro.';

  @override
  String get bkErrInvalidStart =>
      'Quell\'orario non è disponibile in questa data.';

  @override
  String get coinsGiftPurchaseHold =>
      'Le monete acquistate nelle ultime 72 ore non possono ancora essere regalate. Puoi comunque usarle per le funzioni.';

  @override
  String get coinsGiftDailyLimit =>
      'Hai raggiunto il limite di regali di oggi (10 regali o 5.000 monete). Riprova domani.';

  @override
  String get coinReasonRefundClawback => 'Acquisto rimborsato stornato';

  @override
  String get chatMessageDeleted => 'Messaggio eliminato';

  @override
  String get aiConsentTitle => 'Le funzioni IA usano servizi Google';

  @override
  String get aiConsentIntro =>
      'Le risposte intelligenti, il coach linguistico IA, la traduzione dei messaggi che ricevi e la lettura ad alta voce funzionano solo se GreenGo invia a Google il testo interessato.';

  @override
  String get aiConsentProviders =>
      'Chi: Google Gemini (suggerimenti e coaching), Google Cloud Text-to-Speech (audio) e Google Traduttore (traduzioni).';

  @override
  String get aiConsentWhatSent =>
      'Cosa viene inviato: solo il testo del messaggio su cui usi la funzione (compresi i messaggi che altre persone ti hanno inviato) e le lingue. Mai il tuo nome, le tue foto o il tuo profilo.';

  @override
  String get aiConsentWhy =>
      'Perché: solo per produrre il suggerimento, la traduzione o l\'audio che hai richiesto.';

  @override
  String get aiConsentDeclineInfo =>
      'Se rifiuti, queste funzioni restano disattivate e non viene inviato nulla. Tocca una di esse in seguito per rivedere la tua scelta.';

  @override
  String get aiConsentAccept => 'Consenti';

  @override
  String get aiConsentDecline => 'Rifiuta';

  @override
  String get aiConsentDisabledNotice =>
      'Questa funzione è disattivata perché hai scelto di non inviare testo ai servizi IA di Google.';

  @override
  String get aiConsentReview => 'Rivedi';

  @override
  String get profileDeleteReauthRequired =>
      'Per la tua sicurezza, conferma di nuovo la password per eliminare il tuo account.';

  @override
  String get profileDeleteNetworkError =>
      'Nessuna connessione. Il tuo account non è stato eliminato. Riprova.';

  @override
  String get profileDeleteFailed =>
      'Non siamo riusciti a eliminare il tuo account e non è stato eliminato nulla. Riprova o contatta l\'assistenza.';

  @override
  String get onboardingAgeBlockedTitle => 'GreenGo è per adulti';

  @override
  String get onboardingAgeBlockedBody =>
      'Devi avere almeno 18 anni per usare GreenGo, quindi non possiamo creare il tuo account.';

  @override
  String get distanceBucketUnder2Km => 'a meno di 2 km';

  @override
  String get distanceBucket2To5Km => 'a 2-5 km';

  @override
  String get distanceBucket5To10Km => 'a 5-10 km';

  @override
  String get distanceBucket10To25Km => 'a 10-25 km';

  @override
  String get distanceBucketOver25Km => 'a oltre 25 km';

  @override
  String distanceUnderKm(String km) {
    return '< $km km';
  }

  @override
  String distanceOverKm(String km) {
    return '$km+ km';
  }

  @override
  String get idConsentTitle => 'Prima di caricare il documento';

  @override
  String get idConsentWhat =>
      'Cosa trattiamo: una foto del tuo documento d\'identità. Leggiamo automaticamente la data di nascita e il numero del documento (OCR).';

  @override
  String get idConsentWho =>
      'Chi lo tratta: GreenGo, con Google Cloud Vision (Google agisce come nostro responsabile del trattamento).';

  @override
  String get idConsentRetention =>
      'Per quanto tempo: l\'immagine viene eliminata appena viene presa una decisione, in automatico o da un revisore. Se serve una revisione umana, viene conservata al massimo 7 giorni, poi eliminata, e ti chiederemo di caricarla di nuovo.';

  @override
  String get idConsentKept =>
      'Cosa conserviamo: solo se sei verificato, come, la data della decisione, il tuo anno di nascita e un\'impronta unidirezionale con chiave del numero del documento, così che un documento non possa verificare molti account.';

  @override
  String get idConsentAccess =>
      'Chi può vederlo: nessun altro utente. Solo il trattamento automatico e, se necessario, pochi revisori autorizzati di GreenGo.';

  @override
  String get idConsentAccept => 'Accetto, continua';

  @override
  String get idConsentRecordError =>
      'Non siamo riusciti a registrare il tuo consenso, quindi non è stato caricato nulla. Controlla la connessione e riprova.';

  @override
  String get ageVerifyRejectedExpired =>
      'Non è stato possibile esaminare il documento in tempo ed è stato eliminato. Caricalo di nuovo.';

  @override
  String get analyticsConsentTitle => 'Aiutaci a migliorare GreenGo';

  @override
  String get analyticsConsentBody =>
      'Con il tuo permesso usiamo Google Firebase Analytics, Crashlytics e Performance Monitoring per capire come viene usata l\'app e correggere gli arresti anomali. Questo memorizza e legge identificatori sul tuo dispositivo. Non raccogliamo nulla senza il tuo permesso. Puoi cambiare idea in qualsiasi momento in Impostazioni > Privacy e dati.';

  @override
  String get analyticsConsentAllow => 'Consenti';

  @override
  String get analyticsConsentDecline => 'Rifiuta';

  @override
  String get privacySettingsTitle => 'Privacy e dati';

  @override
  String get privacySettingsSubtitle =>
      'Statistiche, report sugli arresti anomali ed email di marketing';

  @override
  String get privacyAnalyticsToggle =>
      'Statistiche d\'uso e report sugli arresti anomali';

  @override
  String get privacyAnalyticsToggleSubtitle =>
      'Condividi con noi statistiche d\'uso e report sugli arresti anomali (Google Firebase) per migliorare l\'app.';

  @override
  String get privacyMarketingEmailToggle => 'Novità e offerte via email';

  @override
  String get privacyMarketingEmailSubtitle =>
      'Email occasionali su nuove funzioni, consigli, riepiloghi delle attività e offerte. Puoi annullare l\'iscrizione in qualsiasi momento.';

  @override
  String get privacySettingsSaveError =>
      'Impossibile salvare la tua scelta. Riprova.';

  @override
  String get notificationCatMarketing => 'Marketing e promozioni';

  @override
  String get notificationCatMarketingSubtitle =>
      'Novità, offerte e annunci di GreenGo. Disattivato finché non lo attivi.';

  @override
  String get signupMarketingEmailConsent =>
      'Inviatemi novità e offerte via email';

  @override
  String get signupMarketingEmailConsentSubtitle =>
      'Facoltativo. Puoi annullare l\'iscrizione in qualsiasi momento.';

  @override
  String get moderationDecisionTitle => 'Decisione di moderazione';

  @override
  String get moderationDecisionIntro =>
      'Il nostro team ha preso un provvedimento sul tuo account o contenuto secondo le Linee guida della community. Ecco la motivazione.';

  @override
  String get moderationDecisionActionLabel => 'Provvedimento';

  @override
  String get moderationDecisionReasonLabel => 'Motivo';

  @override
  String get moderationDecisionExplanationLabel =>
      'Spiegazione del nostro team';

  @override
  String moderationDecisionAppealUntil(String date) {
    return 'Puoi presentare ricorso fino al $date.';
  }

  @override
  String get moderationDecisionAppealButton => 'Presenta ricorso';

  @override
  String get moderationDecisionAppealHint =>
      'Spiega perché ritieni che la decisione sia sbagliata (almeno 10 caratteri).';

  @override
  String get moderationDecisionAppealSubmit => 'Invia ricorso';

  @override
  String get moderationDecisionAppealSent =>
      'Il ricorso è stato inviato. Il nostro team riesaminerà la decisione e ti avviserà.';

  @override
  String get moderationDecisionAppealAlready =>
      'Hai già presentato ricorso contro questa decisione.';

  @override
  String get moderationDecisionAppealClosed =>
      'Non è più possibile presentare ricorso contro questa decisione.';

  @override
  String get moderationDecisionAppealError =>
      'Impossibile inviare il ricorso. Riprova.';

  @override
  String get moderationDecisionAppealTooShort => 'Scrivi almeno 10 caratteri.';

  @override
  String get moderationDecisionNotAppealable =>
      'Non è possibile presentare ricorso nell\'app contro questa decisione. Contatta l\'assistenza se ritieni che sia sbagliata.';

  @override
  String get moderationActionRemoveContent => 'Contenuto rimosso';

  @override
  String get moderationActionWarning => 'Avvertimento emesso';

  @override
  String get moderationActionSuspend => 'Account sospeso temporaneamente';

  @override
  String get moderationActionBan => 'Account bloccato';

  @override
  String get moderationActionShadowBan => 'Visibilità del profilo ridotta';

  @override
  String get moderationActionRequireVerification =>
      'Verifica dell\'identità richiesta';

  @override
  String get moderationActionOther => 'Restrizione applicata';

  @override
  String get moderationReasonCsae => 'Sfruttamento o abuso sessuale di minori';

  @override
  String get moderationReasonUnderage => 'Utente minorenne';

  @override
  String get moderationReasonSexualContent => 'Contenuti sessuali';

  @override
  String get moderationReasonInappropriate => 'Contenuto inappropriato';

  @override
  String get moderationReasonThreats => 'Minacce';

  @override
  String get moderationReasonViolence => 'Violenza';

  @override
  String get moderationReasonHarassment => 'Molestie o bullismo';

  @override
  String get moderationReasonHate => 'Incitamento all\'odio';

  @override
  String get moderationReasonSpam => 'Spam';

  @override
  String get moderationReasonScam => 'Truffa o frode';

  @override
  String get moderationReasonImpersonation =>
      'Furto d\'identità o profilo falso';

  @override
  String get moderationReasonPrivacy =>
      'Condivisione di informazioni personali';

  @override
  String get moderationReasonMisleading => 'Contenuto ingannevole';

  @override
  String get moderationReasonNoShow =>
      'Mancata presentazione a una prenotazione';

  @override
  String get moderationReasonOffPlatformPayment =>
      'Pagamento al di fuori della piattaforma';

  @override
  String get moderationReasonOther =>
      'Altra violazione delle Linee guida della community';

  @override
  String get checkoutConsentTitle => 'Prima di pagare';

  @override
  String get checkoutCoinWaiverCheckbox =>
      'Accetto che le monete vengano consegnate immediatamente e riconosco di perdere il diritto di recesso una volta iniziata la consegna.';

  @override
  String get checkoutMembershipWithdrawalInfo =>
      'Diritto di recesso: puoi recedere da questo abbonamento entro 14 giorni dall\'acquisto (7 giorni per gli acquisti effettuati in Brasile) senza indicarne il motivo e ricevere il rimborso completo, tramite «Recedi dal contratto» nello Shop o sul nostro sito. L\'abbonamento si rinnova automaticamente finché non lo annulli; puoi annullarlo in qualsiasi momento nel portale di fatturazione.';

  @override
  String get checkoutContinueToPayment => 'Continua al pagamento';

  @override
  String get withdrawFromContract => 'Recedi dal contratto';

  @override
  String get withdrawalDialogIntro =>
      'Scegli l\'acquisto da cui vuoi recedere. Invieremo un link di conferma all\'indirizzo usato per l\'acquisto; nulla viene annullato o rimborsato finché non confermi.';

  @override
  String get withdrawalNothingEligible =>
      'Nessuno dei tuoi acquisti web consente il recesso in questo momento. Gli abbonamenti consentono il recesso entro 14 giorni dall\'acquisto (7 giorni in Brasile); gli acquisti di monete solo se al pagamento non si è rinunciato al diritto.';

  @override
  String withdrawalDeadline(String date) {
    return 'Recedi entro il $date';
  }

  @override
  String get withdrawalRequestSent =>
      'Controlla la tua email e conferma il recesso con il link che ti abbiamo inviato.';

  @override
  String get withdrawalRequestFailed =>
      'Impossibile inviare la richiesta di recesso. Riprova o scrivi a support@greengochat.com.';

  @override
  String webSubscriptionRenewsOn(
      String plan, String price, String interval, String date) {
    return '$plan: $price ogni $interval. Si rinnova automaticamente il $date.';
  }

  @override
  String webSubscriptionEndsOn(
      String plan, String price, String interval, String date) {
    return '$plan: $price ogni $interval. Annullato; accesso fino al $date.';
  }

  @override
  String get billingIntervalMonth => 'mese';

  @override
  String get billingIntervalYear => 'anno';

  @override
  String get cancelAnytimeBillingPortal =>
      'Annulla in qualsiasi momento nel portale di fatturazione';

  @override
  String get billingPortalOpenFailed =>
      'Impossibile aprire il portale di fatturazione. Riprova.';

  @override
  String get subscriptionAutoRenewInfoWeb =>
      'Gli abbonamenti si rinnovano automaticamente al prezzo e con la cadenza indicati finché non li annulli. Annulla in qualsiasi momento nel portale di fatturazione.';

  @override
  String get webBillingTitle => 'Fatturazione e recesso';

  @override
  String get ageAssuranceTitle =>
      'Verifica la tua età per usare questa funzione';

  @override
  String get ageAssuranceBody =>
      'Dove vivi, la legge ci chiede di confermare che sei maggiorenne prima che tu possa scoprire persone o iniziare nuove conversazioni private. Il resto di GreenGo funziona come sempre.';

  @override
  String get ageAssuranceExistingChats =>
      'Le conversazioni a cui hai già partecipato restano disponibili.';

  @override
  String get ageAssuranceStoreCheckAndroid => 'Conferma con Google Play';

  @override
  String get ageAssuranceStoreCheckIos => 'Conferma con l\'App Store';

  @override
  String get ageAssuranceStoreHint =>
      'Usa l\'età già confermata dal tuo account dello store. Riceviamo solo una fascia d\'età, mai la tua data di nascita.';

  @override
  String get ageAssuranceIdOption => 'Verifica con un documento d\'identità';

  @override
  String get ageAssuranceStoreUnavailable =>
      'Il tuo account dello store non ha potuto confermare la tua età. Verificala con un documento d\'identità.';

  @override
  String get ageAssuranceVerified => 'Grazie, la tua età è confermata.';

  @override
  String get ageAssuranceWebNote =>
      'Sul web, la tua età viene confermata con un documento d\'identità.';

  @override
  String get ageVerifyWhyRegional =>
      'Per scoprire persone e iniziare nuove chat private dove vivi, dobbiamo confermare che hai più di 18 anni.';

  @override
  String get privacyDownloadDataTitle => 'Scarica i miei dati';

  @override
  String get privacyDownloadDataSubtitle =>
      'Una copia del tuo profilo, delle impostazioni, delle foto e dei messaggi che hai inviato (file ZIP)';

  @override
  String get privacyDownloadDataConfirmBody =>
      'Prepareremo un file ZIP con i dati che conserviamo su di te. Per proteggere le altre persone, i messaggi che ti hanno inviato non sono inclusi. Riceverai un link per il download qui e via email. Il link vale 24 ore e puoi richiedere una copia al giorno.';

  @override
  String get privacyDownloadDataConfirmButton => 'Prepara i miei dati';

  @override
  String get privacyDownloadDataPreparing =>
      'Stiamo preparando i tuoi dati. Può richiedere qualche minuto...';

  @override
  String get privacyDownloadDataReadyTitle => 'I tuoi dati sono pronti';

  @override
  String get privacyDownloadDataReadyBody =>
      'Scarica ora il file ZIP. Il link vale 24 ore.';

  @override
  String get privacyDownloadDataReadyEmailed =>
      'Ti abbiamo inviato il link anche via email.';

  @override
  String get privacyDownloadDataOpen => 'Scarica';

  @override
  String get privacyDownloadDataRateLimited =>
      'Puoi scaricare i tuoi dati una volta ogni 24 ore. Usa il link che ti abbiamo inviato via email o riprova domani.';

  @override
  String get privacyDownloadDataInProgress =>
      'Stiamo già preparando i tuoi dati. Attendi qualche minuto.';

  @override
  String get privacyDownloadDataFailed =>
      'Non è stato possibile preparare i tuoi dati. Riprova più tardi.';

  @override
  String get reauthPasswordBody =>
      'Per la tua sicurezza, inserisci di nuovo la password per continuare.';

  @override
  String get reauthContinue => 'Continua';

  @override
  String get reauthSignInAgain =>
      'Per la tua sicurezza, esci e accedi di nuovo, poi riprova.';

  @override
  String get profilePhotoPrevious => 'Foto precedente';

  @override
  String get profilePhotoNext => 'Foto successiva';

  @override
  String get aiServicesTitle => 'Servizi IA';

  @override
  String get aiServicesSubtitleOn =>
      'Attivo: le funzioni IA possono inviare a Google il testo su cui le usi.';

  @override
  String get aiServicesSubtitleOff =>
      'Disattivo: nessun testo viene inviato ai servizi IA.';

  @override
  String get aiServicesWhatsIncluded => 'Cosa include questo interruttore';

  @override
  String get aiServicesFeatureCoach =>
      'Risposte suggerite e il coach linguistico IA (grammatica, analisi delle parole, note culturali)';

  @override
  String get aiServicesFeatureTranslate =>
      'Traduzione dei messaggi di chat che ricevi';

  @override
  String get aiServicesFeatureReadAloud => 'Lettura ad alta voce e pronuncia';

  @override
  String get aiServicesFeatureSupport =>
      'Risposte automatiche dell\'assistente di supporto (se disattivo, ti risponde una persona)';

  @override
  String get aiServicesSafetyNote =>
      'Il controllo di sicurezza di foto e messaggi resta sempre attivo: protegge tutti e non può essere disattivato.';

  @override
  String get aiServicesTurnedOff =>
      'Servizi IA disattivati. La tua scelta è stata registrata.';

  @override
  String get aiServicesTurnedOn =>
      'Servizi IA attivati. La tua scelta è stata registrata.';

  @override
  String get aiServicesSyncPending =>
      'Salvato su questo dispositivo. Verrà registrato sui nostri server appena sarai online.';

  @override
  String get tpAddTicketType => 'Aggiungi tipo di biglietto';

  @override
  String get tpAdviceLarge =>
      'Molte persone previste: è consigliata la conferma istantanea. I biglietti vengono confermati automaticamente, senza controllare ogni pagamento.';

  @override
  String get tpAdviceSmall =>
      'Gruppo piccolo: la cosa più semplice è un link di pagamento, senza configurazione; confermi ogni pagamento con un tocco.';

  @override
  String get tpAmountLabel => 'Importo';

  @override
  String get tpAttachReceipt => 'Allega ricevuta (facoltativo)';

  @override
  String get tpAwaitingOrganizerInfo =>
      'Hai comunicato all\'organizzatore di aver pagato. Il biglietto apparirà qui appena conferma.';

  @override
  String get tpBadgeBrazil => 'Consigliato in Brasile';

  @override
  String get tpBadgeNoSetup => 'Nessuna configurazione';

  @override
  String get tpBadgeRecommended => 'Consigliato';

  @override
  String get tpBankInstructionsLabel => 'Dati bancari e istruzioni';

  @override
  String tpBlockMinimum(String provider, String amount) {
    return '$provider richiede almeno $amount per biglietto.';
  }

  @override
  String tpBlockMpCurrency(String currency) {
    return 'Mercado Pago addebita solo in $currency: imposta il prezzo in $currency o usa Stripe.';
  }

  @override
  String get tpBlockMpCurrencyUnknown =>
      'Mercado Pago addebita solo nella valuta locale del tuo account. Usa quella valuta o Stripe.';

  @override
  String get tpBlockNotConfigured => 'Non ancora disponibile.';

  @override
  String tpBlockNotConnected(String provider) {
    return 'Collega $provider per usarlo.';
  }

  @override
  String get tpBuyMoreTickets => 'Acquista altri biglietti';

  @override
  String get tpBuyTickets => 'Acquista biglietti';

  @override
  String tpCanBuyMore(int count) {
    return 'Puoi acquistare ancora $count biglietti';
  }

  @override
  String get tpCanBuyUnlimited => 'Nessun limite per persona';

  @override
  String get tpCancelOrder => 'Annulla';

  @override
  String get tpCashInstructionsLabel =>
      'Dove e quando pagare in contanti (facoltativo)';

  @override
  String get tpChooseHowToGetPaid =>
      'Scegli come pagano gli acquirenti per questo annuncio a pagamento.';

  @override
  String get tpClose => 'Chiudi';

  @override
  String get tpCodeHint =>
      'Inserisci questo codice nella causale per aiutare l\'organizzatore a trovare il pagamento.';

  @override
  String get tpCodeLabel => 'Codice di pagamento';

  @override
  String get tpConfirm => 'Conferma';

  @override
  String tpConfirmSelected(int count) {
    return 'Conferma selezionati ($count)';
  }

  @override
  String tpConfirmedCount(int count) {
    return '$count pagamenti confermati';
  }

  @override
  String tpConnectProvider(String provider) {
    return 'Collega $provider';
  }

  @override
  String get tpConsentGuideInstant =>
      'Paghi nell\'app con un checkout sicuro. Biglietto e QR appaiono appena il pagamento è confermato. I rimborsi sono a cura dell\'organizzatore.';

  @override
  String get tpConsentGuideManual =>
      'Paghi direttamente l\'host con il suo metodo e un codice. GreenGo non verifica il pagamento: l\'host lo conferma, poi appare il QR.';

  @override
  String get tpContinueSetup => 'Continua la configurazione';

  @override
  String tpContinueToPay(String amount) {
    return 'Continua · $amount';
  }

  @override
  String get tpCopied => 'Copiato';

  @override
  String get tpCopy => 'Copia';

  @override
  String get tpEditTicketType => 'Modifica tipo di biglietto';

  @override
  String get tpErrAlreadyHasTicket => 'Hai già un biglietto per questo.';

  @override
  String get tpErrEnded => 'Le vendite sono terminate.';

  @override
  String get tpErrGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get tpErrLimit => 'Hai raggiunto il limite di biglietti per persona.';

  @override
  String get tpErrMinimum =>
      'Il prezzo è inferiore al minimo del fornitore di pagamento.';

  @override
  String get tpErrNotAllowed => 'Non puoi farlo.';

  @override
  String get tpErrNotOnSale =>
      'I biglietti non sono ancora in vendita: l\'organizzatore non ha completato la configurazione dei pagamenti.';

  @override
  String get tpErrOwnListing =>
      'Non puoi acquistare biglietti per il tuo annuncio.';

  @override
  String get tpErrProvider =>
      'Il fornitore di pagamento non risponde. Riprova tra poco.';

  @override
  String get tpErrSoldOut => 'Esaurito: posti insufficienti.';

  @override
  String get tpFree => 'Gratis';

  @override
  String get tpGetPaidIntro =>
      'Il denaro va direttamente sul tuo conto. GreenGo non trattiene commissioni sulla vendita dei biglietti.';

  @override
  String get tpGetPaidSubtitle =>
      'Metodi di pagamento, Stripe e Mercado Pago, pagamenti da confermare';

  @override
  String get tpGetPaidTitle => 'Ricevi pagamenti';

  @override
  String tpGroupOf(int count) {
    return 'Gruppo di $count';
  }

  @override
  String tpGroupPreview(String price, int size) {
    return '$price per un gruppo fino a $size';
  }

  @override
  String get tpGroupPrice => 'Prezzo per gruppo';

  @override
  String tpHoldCountdown(String time) {
    return 'Il tuo posto è riservato per $time';
  }

  @override
  String get tpInstantOptional => 'Conferma istantanea (facoltativa)';

  @override
  String get tpInstantSubtitle =>
      'Gli acquirenti pagano nell\'app; i biglietti sono confermati automaticamente.';

  @override
  String get tpInstantTitle => 'Conferma istantanea';

  @override
  String get tpIvePaid => 'Ho pagato';

  @override
  String get tpLegacyPaymentPrompt =>
      'Questo annuncio usava un vecchio metodo di pagamento. Scegli come pagano gli ospiti per continuare a vendere.';

  @override
  String get tpManualAddMethodsHint =>
      'Aggiungi Pix, PayPal… in Profilo > Azienda > Ricevi pagamenti per vederli qui.';

  @override
  String get tpManualDisclaimer =>
      'GreenGo non verifica questi pagamenti: l\'organizzatore è responsabile della conferma.';

  @override
  String tpManualLargeWarning(String count) {
    return 'Con $count persone dovrai confermare ogni pagamento a mano.';
  }

  @override
  String get tpManualMethodLabel => 'Metodo di pagamento';

  @override
  String get tpManualSubtitle =>
      'Il tuo metodo di pagamento; confermi ogni pagamento con un tocco.';

  @override
  String get tpManualTitle => 'Link di pagamento: confermi tu';

  @override
  String get tpMaxGroupBookingsPerUser =>
      'Max prenotazioni di gruppo per persona';

  @override
  String get tpMaxTicketsPerUser => 'Max biglietti per persona';

  @override
  String get tpMethodBankTransfer => 'Bonifico bancario';

  @override
  String get tpMethodCash => 'Contanti (prima dell\'evento)';

  @override
  String tpMpCurrencyInfo(String currency) {
    return 'Addebita in $currency';
  }

  @override
  String get tpMpDescription =>
      'Pix, carte e saldo Mercado Pago. Gli acquirenti non serve un account Mercado Pago.';

  @override
  String get tpMyPurchases => 'I miei acquisti';

  @override
  String get tpNoFeeNote =>
      'GreenGo non trattiene commissioni: il denaro va direttamente a te.';

  @override
  String get tpNoLimitHint => 'Vuoto = nessun limite';

  @override
  String get tpNoPurchases => 'Nessun acquisto ancora.';

  @override
  String get tpNotOnSaleYet => 'Non ancora in vendita';

  @override
  String get tpOpenPaymentLink => 'Apri il link di pagamento';

  @override
  String get tpOpenProviderSettings => 'Aggiorna i dati dell\'account';

  @override
  String get tpOrderAwaitingConfirmation =>
      'In attesa della conferma dell\'organizzatore…';

  @override
  String get tpOrderCancelled => 'Ordine annullato';

  @override
  String get tpOrderClosedInfo =>
      'Questo ordine è chiuso. Puoi iniziare un nuovo acquisto dall\'evento o esperienza.';

  @override
  String get tpOrderDisputed => 'Pagamento contestato: biglietto non valido';

  @override
  String get tpOrderExpired => 'Prenotazione scaduta';

  @override
  String get tpOrderFailed => 'Pagamento non riuscito';

  @override
  String get tpOrderPaid => 'Pagato';

  @override
  String get tpOrderPendingPayment => 'In attesa del tuo pagamento';

  @override
  String get tpOrderRefunded => 'Rimborsato: biglietto non più valido';

  @override
  String get tpOrderRejected =>
      'L\'organizzatore non ha confermato il pagamento';

  @override
  String get tpOrderTitle => 'I tuoi biglietti';

  @override
  String get tpOrderWaitingProvider =>
      'In attesa della conferma del pagamento…';

  @override
  String get tpPayAgain => 'Paga di nuovo';

  @override
  String get tpPayInApp => 'Pagamento nell\'app';

  @override
  String get tpPayInAppInfo =>
      'Paga nell\'app quando l\'host accetta; il QR appare dopo la conferma.';

  @override
  String get tpPayNow => 'Paga ora';

  @override
  String tpPayWith(String method) {
    return 'Paga con $method';
  }

  @override
  String get tpPaymentConfirmed =>
      'Pagamento confermato: i biglietti sono pronti';

  @override
  String get tpPerGroup => 'Per gruppo';

  @override
  String get tpPerGroupInfo =>
      'Un prezzo fisso per gruppo (es. tour privato), qualunque sia la dimensione fino al massimo.';

  @override
  String get tpPerPerson => 'Per persona';

  @override
  String get tpPerPersonInfo =>
      'Ogni persona paga il prezzo; un biglietto a persona.';

  @override
  String get tpPixHint =>
      'Pagato con Pix? La conferma di solito richiede pochi secondi.';

  @override
  String get tpReceiptAttached => 'Ricevuta allegata';

  @override
  String get tpReconnectBanner =>
      'Collega Mercado Pago / Stripe per vendere biglietti con conferma automatica. I link Stripe o Mercado Pago incollati non valgono per i biglietti.';

  @override
  String get tpRefresh => 'Aggiorna';

  @override
  String get tpReject => 'Non ricevuto';

  @override
  String get tpRejectReason => 'Motivo (visibile all\'acquirente)';

  @override
  String get tpRejectTitle => 'Pagamento non ricevuto?';

  @override
  String get tpSalesEnd => 'Fine vendite';

  @override
  String get tpSalesStart => 'Inizio vendite';

  @override
  String get tpSave => 'Salva';

  @override
  String get tpScanNotPaid => 'Non pagato: nessun biglietto valido';

  @override
  String get tpScanTicketNotValid =>
      'Biglietto rimborsato o annullato: non valido';

  @override
  String get tpSelectorTitle => 'Come pagano gli ospiti?';

  @override
  String get tpShareTicket => 'Condividi questo biglietto';

  @override
  String tpShareTicketText(String title, int index, int total) {
    return 'Biglietto $index/$total per $title su GreenGo. Mostra questo QR all\'ingresso (valido una volta).';
  }

  @override
  String get tpStatusNotConnected => 'Non collegato';

  @override
  String get tpStatusPending => 'Verifica in corso';

  @override
  String get tpStatusReady => 'Pronto';

  @override
  String get tpStatusReconnect => 'Ricollegare';

  @override
  String get tpStopSelling => 'Interrompi vendita';

  @override
  String get tpStripeDescription =>
      'Carte, Apple Pay e Google Pay in tutto il mondo. Agli acquirenti non serve un account.';

  @override
  String tpTicketIndex(int index, int total) {
    return 'Biglietto $index di $total';
  }

  @override
  String get tpTicketInvalid => 'Questo biglietto non è più valido.';

  @override
  String get tpTicketTypes => 'Tipi di biglietto';

  @override
  String get tpTicketTypesEmpty =>
      'Nessun tipo di biglietto: il prezzo dell\'evento è l\'unico biglietto. Aggiungi VIP, early bird e altro.';

  @override
  String get tpTicketUsed => 'Già usato all\'ingresso';

  @override
  String tpTicketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biglietti',
      one: '1 biglietto',
    );
    return '$_temp0';
  }

  @override
  String get tpTiredOfConfirming =>
      'Stanco di confermare? Collega Mercado Pago o Stripe per la conferma automatica.';

  @override
  String get tpToConfirmEmpty => 'Nessun pagamento in attesa.';

  @override
  String get tpToConfirmInfo =>
      'Controlla sul tuo conto importo e codice GG- prima di confermare. La conferma emette i biglietti.';

  @override
  String get tpToConfirmTitle => 'Pagamenti da confermare';

  @override
  String get tpTotal => 'Totale';

  @override
  String get tpTypeEnded => 'Vendite terminate';

  @override
  String get tpTypeHasSalesWarning =>
      'Biglietti di questo tipo già venduti: mantengono prezzo e tipo.';

  @override
  String get tpTypeHidden => 'Nascosto';

  @override
  String get tpTypeMaxPerUser => 'Max per persona';

  @override
  String get tpTypeName => 'Nome (es. VIP)';

  @override
  String get tpTypeNotStarted => 'Le vendite non sono iniziate';

  @override
  String tpTypeOnlyLeft(int count) {
    return 'Solo $count rimasti';
  }

  @override
  String get tpTypePerks => 'Descrizione / vantaggi';

  @override
  String get tpTypePrice => 'Prezzo';

  @override
  String get tpTypeQuantity => 'Quantità (vuoto = capienza evento)';

  @override
  String get tpTypeSelling => 'In vendita';

  @override
  String tpTypeSold(int sold, String total) {
    return '$sold/$total venduti';
  }

  @override
  String get tpTypeSoldOut => 'Esaurito';

  @override
  String get tpTypeUnavailable => 'Non in vendita';

  @override
  String get tpViewPayment => 'Vedi pagamento';

  @override
  String get tpViewReceipt => 'Ricevuta';

  @override
  String get tpViewTickets => 'Vedi biglietti';

  @override
  String get mtAddTime => 'Aggiungi orario';

  @override
  String get mtAdvanced => 'Avanzate';

  @override
  String get mtApplyAll => 'Applica a tutti i giorni scelti';

  @override
  String get mtAvailableFrom => 'Disponibile dalle';

  @override
  String get mtAvailableUntil => 'Fino alle';

  @override
  String get mtBreak => 'Pausa tra le sessioni';

  @override
  String get mtBulkCloseRange => 'Chiudi un periodo (ferie)';

  @override
  String get mtBulkHint => 'Le modifiche si salvano con Salva.';

  @override
  String get mtBulkRemoveTime =>
      'Rimuovi un orario da ogni giorno della settimana scelto';

  @override
  String get mtBulkTitle => 'Modifiche rapide';

  @override
  String get mtCalendarTitle => 'Calendario';

  @override
  String get mtCapacity => 'Posti per orario';

  @override
  String get mtCloseDay => 'Chiuso questo giorno';

  @override
  String get mtClosed => 'Chiuso';

  @override
  String mtConfirmBody(int count) {
    return 'Verrebbero rimossi $count orari prenotati. Le prenotazioni saranno annullate e gli ospiti avvisati e rimborsati.';
  }

  @override
  String get mtConfirmCancelBookings => 'Annulla quelle prenotazioni';

  @override
  String get mtConfirmTitle => 'Alcuni orari sono prenotati';

  @override
  String get mtCopyToMonth => 'Copia su tutto il mese';

  @override
  String mtCopyToWeekdays(String weekday) {
    return 'Copia su ogni $weekday del mese';
  }

  @override
  String get mtDateFrom => 'Dalla data';

  @override
  String get mtDateTo => 'Fino alla data';

  @override
  String get mtDaysOfWeek => 'Giorni della settimana';

  @override
  String get mtDone => 'Fatto';

  @override
  String get mtDuration => 'Durata';

  @override
  String get mtErrOverlap =>
      'Gli orari si sovrapporrebbero: \"inizia ogni\" deve essere almeno la durata.';

  @override
  String get mtErrRules => 'Controlla le impostazioni degli orari.';

  @override
  String get mtErrTimeExists => 'Questo orario c\'è già.';

  @override
  String get mtErrTimeFit => 'La sessione finirebbe dopo mezzanotte.';

  @override
  String get mtErrTimeOverlaps =>
      'Si sovrappone a un altro orario di quel giorno.';

  @override
  String get mtErrWeekdays => 'Scegli almeno un giorno della settimana.';

  @override
  String get mtErrWindow =>
      '\"Fino alle\" deve essere dopo \"Disponibile dalle\".';

  @override
  String mtHours(int h) {
    return '$h h';
  }

  @override
  String mtHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get mtLegendChanged => 'giorno modificato';

  @override
  String get mtLegendSpecialPrice => 'prezzo speciale';

  @override
  String get mtLegendWeekendPrice => 'prezzo weekend';

  @override
  String mtMinutes(int m) {
    return '$m min';
  }

  @override
  String get mtNextMonth => 'Mese successivo';

  @override
  String get mtNoBreak => 'Nessuna pausa';

  @override
  String get mtNoEnd => 'Nessuna data di fine';

  @override
  String get mtPrevMonth => 'Mese precedente';

  @override
  String get mtPreview => 'Orari di ogni giorno scelto';

  @override
  String get mtRemoveTime => 'Rimuovi orario';

  @override
  String get mtResetDay => 'Ripristina predefinito';

  @override
  String get mtSaved => 'Orari salvati';

  @override
  String mtSavedCancelled(int count) {
    return 'Orari salvati: $count prenotazioni annullate e rimborsate';
  }

  @override
  String get mtSetupTitle => 'I tuoi orari';

  @override
  String get mtSpecialPrice => 'Prezzo speciale per questo giorno';

  @override
  String get mtSpecialPriceHint => 'Vuoto = prezzo normale';

  @override
  String get mtStartEvery => 'Inizia ogni';

  @override
  String get mtStartEveryAuto => 'Automatico (durata + pausa)';

  @override
  String get mtTime => 'Orario';

  @override
  String get mtTimezone => 'Fuso orario';

  @override
  String get mtTitle => 'Gestisci orari';

  @override
  String get mtWeekendPrice => 'Prezzo weekend';

  @override
  String get mtWeekendPriceInfo =>
      'Vale nei giorni scelti; il prezzo speciale di un giorno si imposta in Gestisci orari.';

  @override
  String get mtWeekendPriceToggle => 'Prezzo diverso nel weekend';

  @override
  String rtGroupsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posti gruppo rimasti',
      one: '1 posto gruppo rimasto',
    );
    return '$_temp0';
  }

  @override
  String rtSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posti rimasti',
      one: '1 posto rimasto',
    );
    return '$_temp0';
  }

  @override
  String get rtSpecialPrice => 'prezzo speciale';

  @override
  String rtTimesIn(String zone) {
    return 'Orari nel fuso dell\'host ($zone)';
  }

  @override
  String get rtWeekendPrice => 'prezzo weekend';

  @override
  String rtYourTime(String time) {
    return 'Tua ora: $time';
  }

  @override
  String get tpReorder => 'Trascina per riordinare';

  @override
  String tpSalesRow(int sold, int held, String left) {
    return '$sold venduti · $held riservati · $left liberi';
  }

  @override
  String get tpSalesSummary => 'Vendite per tipo di biglietto';

  @override
  String tpSalesTotal(int sold, int held) {
    return 'Totale: $sold venduti, $held riservati';
  }

  @override
  String get wzAllGood => 'È tutto pronto.';

  @override
  String get wzAvailability => 'Disponibilità';

  @override
  String get wzBack => 'Indietro';

  @override
  String get wzEdit => 'Modifica';

  @override
  String get wzErrCapacity => 'Indica quante persone possono venire.';

  @override
  String get wzErrDates => 'La fine deve essere dopo l\'inizio.';

  @override
  String get wzErrDescription => 'Aggiungi una descrizione.';

  @override
  String get wzErrLocation => 'Aggiungi il luogo.';

  @override
  String get wzErrTitle => 'Aggiungi un titolo.';

  @override
  String get wzEventBasics => 'Informazioni di base';

  @override
  String get wzExpBasics => 'Informazioni di base';

  @override
  String get wzFineTuneLater =>
      'Potrai rifinire singoli giorni più tardi in Gestisci orari.';

  @override
  String get wzFix => 'Correggi';

  @override
  String get wzFormatPrice => 'Formato e prezzo';

  @override
  String get wzLocation => 'Luogo';

  @override
  String get wzNext => 'Avanti';

  @override
  String get wzOverviewTitle => 'Cosa vuoi modificare?';

  @override
  String get wzPayment => 'Pagamento';

  @override
  String get wzPreviewTitle => 'Come lo vedranno gli acquirenti';

  @override
  String get wzRecurringInfo =>
      'Gli ospiti scelgono uno degli orari generati. Disattiva per usare date singole.';

  @override
  String get wzRecurringToggle => 'Ripeti ogni settimana';

  @override
  String get wzResume => 'Riprendi';

  @override
  String get wzResumeBody =>
      'Hai una bozza non finita su questo dispositivo. Riprendere da dove eri rimasto?';

  @override
  String get wzResumeTitle => 'Riprendere la bozza?';

  @override
  String get wzReview => 'Rivedi e pubblica';

  @override
  String get wzStartOver => 'Ricomincia';

  @override
  String wzStepOf(int step, int total) {
    return 'Passo $step di $total';
  }

  @override
  String get wzTickets => 'Biglietti';

  @override
  String get wzWarnManualLarge =>
      'Molte persone con pagamenti manuali: dovrai confermarli uno per uno. Valuta la conferma istantanea.';

  @override
  String get wzWarnNoAvailability =>
      'Nessuna disponibilità: aggiungi date dopo il salvataggio o attiva \"Ripeti ogni settimana\".';

  @override
  String get wzWarnNoPhoto =>
      'Nessuna foto di copertina: gli annunci con foto ricevono più prenotazioni.';

  @override
  String get wzWhenWhere => 'Quando e dove';

  @override
  String get tpPaymentMethodsSectionHint =>
      'I tuoi metodi (Pix, PayPal, …): le persone possono pagarti direttamente e puoi usarli per i biglietti che confermi a mano.';

  @override
  String get tpPaymentMethodsSaveFailed =>
      'Impossibile salvare i metodi di pagamento. Riprova.';

  @override
  String wzNextTo(String step) {
    return 'Avanti: $step';
  }

  @override
  String get wzSteps => 'Passi';

  @override
  String get wzAllStepsTitle => 'Tutti i passi';

  @override
  String get wzStepsHint =>
      'Tocca un passo per andarci. Puoi tornare indietro quando vuoi.';

  @override
  String get wzStatusCurrent => 'Passo attuale';

  @override
  String get wzStatusDone => 'Completato';

  @override
  String get wzStatusAttention => 'Da completare';

  @override
  String get wzStatusTodo => 'Non iniziato';

  @override
  String wzStepSemantics(int step, int total, String title, String status) {
    return 'Passo $step di $total: $title. $status';
  }

  @override
  String get wzPaymentAppearsNote =>
      'Il passo Pagamento compare quando il prezzo è superiore a 0.';

  @override
  String get wzPublishBlocked =>
      'Completa gli elementi obbligatori qui sopra per pubblicare.';

  @override
  String get wzEvBasicsDesc =>
      'Dai al tuo evento un titolo chiaro e racconta cosa aspettarsi. Una foto di copertina lo fa risaltare.';

  @override
  String get wzEvBasicsReq => 'Obbligatori: titolo e descrizione.';

  @override
  String get wzEvWhereDesc =>
      'Indica dove si svolge (scrivi l\'indirizzo o sceglilo sulla mappa) e quando inizia e finisce.';

  @override
  String get wzEvWhereReq =>
      'Obbligatori: il luogo e una fine successiva all\'inizio.';

  @override
  String get wzEvTicketsDesc =>
      'Scegli se l\'evento è gratuito o a pagamento, imposta il prezzo e quante persone possono partecipare.';

  @override
  String get wzEvTicketsReq =>
      'Obbligatori: quante persone possono venire (o illimitato) e, se a pagamento, un prezzo.';

  @override
  String get wzEvPaymentDesc =>
      'Scegli come i partecipanti ti pagano i biglietti.';

  @override
  String get wzEvPaymentReq => 'Obbligatorio: un modo per essere pagato.';

  @override
  String get wzEvReviewDesc =>
      'Controlla come apparirà il tuo evento. Correggi ciò che è segnato in rosso, poi pubblica, salva una bozza o programmalo.';

  @override
  String get wzExBasicsDesc =>
      'Dai un nome alla tua esperienza, descrivila e aggiungi foto, le lingue che parli e cosa è incluso.';

  @override
  String get wzExBasicsReq =>
      'Obbligatori: titolo, descrizione, una foto principale, almeno una lingua e cosa è incluso.';

  @override
  String get wzExLocationDesc => 'Indica agli ospiti dove incontrarvi.';

  @override
  String get wzExLocationReq => 'Obbligatorio: il punto d\'incontro.';

  @override
  String get wzExFormatDesc =>
      'Imposta la durata, la dimensione del gruppo e se è gratuita o a pagamento (a persona o a gruppo).';

  @override
  String get wzExFormatReq =>
      'Obbligatori: durata, dimensione del gruppo e, se a pagamento, un prezzo.';

  @override
  String get wzExAvailDesc =>
      'Scegli quando gli ospiti possono prenotare: un orario settimanale ricorrente o date singole da aggiungere dopo.';

  @override
  String get wzExAvailReq =>
      'Facoltativo: puoi aggiungere le date anche dopo aver salvato.';

  @override
  String get wzExPaymentDesc => 'Scegli come ti pagano gli ospiti.';

  @override
  String get wzExPaymentReq =>
      'Obbligatorio: almeno un modo per essere pagato.';

  @override
  String get wzExReviewDesc =>
      'Controlla come lo vedranno gli ospiti. Correggi ciò che è segnato in rosso, poi pubblica o salva una bozza.';

  @override
  String verificationOrMethod(String method) {
    return 'o $method';
  }

  @override
  String get safetyAcademyTitle => 'Accademia della sicurezza';

  @override
  String get safetyAcademyLearningModules => 'Moduli di apprendimento';

  @override
  String safetyAcademyModulesCompleted(int completed, int total) {
    return '$completed / $total moduli completati';
  }

  @override
  String get safetyAcademyChampionTitle => 'Campione della sicurezza';

  @override
  String get safetyAcademyChampionBody =>
      'Hai completato tutti i moduli sulla sicurezza!';

  @override
  String get safetyAcademyLessonCompletedToast => 'Lezione completata!';

  @override
  String get safetyAcademyNoLessons => 'Nessuna lezione ancora disponibile.';

  @override
  String safetyAcademyLessonsProgress(int completed, int total) {
    return '$completed / $total lezioni';
  }

  @override
  String safetyAcademyLessonXpWithQuiz(int xp) {
    return '+$xp XP | Quiz';
  }

  @override
  String get safetyAcademyTakeQuiz => 'Fai il quiz';

  @override
  String get safetyAcademyCompleteLesson => 'Completa la lezione';

  @override
  String get safetyAcademyCompleted => 'Completata';

  @override
  String safetyAcademyQuestionOf(int current, int total) {
    return 'Domanda $current di $total';
  }

  @override
  String safetyAcademyCorrectCount(int count) {
    return '$count corrette';
  }

  @override
  String get safetyAcademyNextQuestion => 'Prossima domanda';

  @override
  String get safetyAcademySeeResults => 'Vedi i risultati';

  @override
  String get safetyAcademyGreatJob => 'Ottimo lavoro!';

  @override
  String get safetyAcademyKeepLearning => 'Continua a imparare!';

  @override
  String safetyAcademyScoreSummary(int correct, int total) {
    return '$correct risposte corrette su $total';
  }

  @override
  String safetyAcademyPassingScore(int score) {
    return 'Punteggio minimo: $score%';
  }

  @override
  String safetyAcademyCompleteLessonXp(int xp) {
    return 'Completa la lezione (+$xp XP)';
  }

  @override
  String get safetyAcademyReviewLesson => 'Ripassa la lezione';

  @override
  String get safetyAcademyExitQuizTitle => 'Uscire dal quiz?';

  @override
  String get safetyAcademyExitQuizBody => 'I tuoi progressi andranno persi.';

  @override
  String get countryNameAF => 'Afghanistan';

  @override
  String get countryNameAL => 'Albania';

  @override
  String get countryNameDZ => 'Algeria';

  @override
  String get countryNameAD => 'Andorra';

  @override
  String get countryNameAO => 'Angola';

  @override
  String get countryNameAG => 'Antigua e Barbuda';

  @override
  String get countryNameAR => 'Argentina';

  @override
  String get countryNameAM => 'Armenia';

  @override
  String get countryNameAU => 'Australia';

  @override
  String get countryNameAT => 'Austria';

  @override
  String get countryNameAZ => 'Azerbaigian';

  @override
  String get countryNameBS => 'Bahamas';

  @override
  String get countryNameBH => 'Bahrein';

  @override
  String get countryNameBD => 'Bangladesh';

  @override
  String get countryNameBB => 'Barbados';

  @override
  String get countryNameBY => 'Bielorussia';

  @override
  String get countryNameBE => 'Belgio';

  @override
  String get countryNameBZ => 'Belize';

  @override
  String get countryNameBJ => 'Benin';

  @override
  String get countryNameBT => 'Bhutan';

  @override
  String get countryNameBO => 'Bolivia';

  @override
  String get countryNameBA => 'Bosnia ed Erzegovina';

  @override
  String get countryNameBW => 'Botswana';

  @override
  String get countryNameBR => 'Brasile';

  @override
  String get countryNameBN => 'Brunei';

  @override
  String get countryNameBG => 'Bulgaria';

  @override
  String get countryNameBF => 'Burkina Faso';

  @override
  String get countryNameBI => 'Burundi';

  @override
  String get countryNameCV => 'Capo Verde';

  @override
  String get countryNameKH => 'Cambogia';

  @override
  String get countryNameCM => 'Camerun';

  @override
  String get countryNameCA => 'Canada';

  @override
  String get countryNameCF => 'Repubblica Centrafricana';

  @override
  String get countryNameTD => 'Ciad';

  @override
  String get countryNameCL => 'Cile';

  @override
  String get countryNameCN => 'Cina';

  @override
  String get countryNameCO => 'Colombia';

  @override
  String get countryNameKM => 'Comore';

  @override
  String get countryNameCG => 'Congo';

  @override
  String get countryNameCD => 'Repubblica Democratica del Congo';

  @override
  String get countryNameCR => 'Costa Rica';

  @override
  String get countryNameHR => 'Croazia';

  @override
  String get countryNameCU => 'Cuba';

  @override
  String get countryNameCY => 'Cipro';

  @override
  String get countryNameCZ => 'Cechia';

  @override
  String get countryNameDK => 'Danimarca';

  @override
  String get countryNameDJ => 'Gibuti';

  @override
  String get countryNameDM => 'Dominica';

  @override
  String get countryNameDO => 'Repubblica Dominicana';

  @override
  String get countryNameEC => 'Ecuador';

  @override
  String get countryNameEG => 'Egitto';

  @override
  String get countryNameSV => 'El Salvador';

  @override
  String get countryNameGQ => 'Guinea Equatoriale';

  @override
  String get countryNameER => 'Eritrea';

  @override
  String get countryNameEE => 'Estonia';

  @override
  String get countryNameSZ => 'Eswatini';

  @override
  String get countryNameET => 'Etiopia';

  @override
  String get countryNameFJ => 'Figi';

  @override
  String get countryNameFI => 'Finlandia';

  @override
  String get countryNameFR => 'Francia';

  @override
  String get countryNameGA => 'Gabon';

  @override
  String get countryNameGM => 'Gambia';

  @override
  String get countryNameGE => 'Georgia';

  @override
  String get countryNameDE => 'Germania';

  @override
  String get countryNameGH => 'Ghana';

  @override
  String get countryNameGR => 'Grecia';

  @override
  String get countryNameGD => 'Grenada';

  @override
  String get countryNameGT => 'Guatemala';

  @override
  String get countryNameGN => 'Guinea';

  @override
  String get countryNameGW => 'Guinea-Bissau';

  @override
  String get countryNameGY => 'Guyana';

  @override
  String get countryNameHT => 'Haiti';

  @override
  String get countryNameHN => 'Honduras';

  @override
  String get countryNameHU => 'Ungheria';

  @override
  String get countryNameIS => 'Islanda';

  @override
  String get countryNameIN => 'India';

  @override
  String get countryNameID => 'Indonesia';

  @override
  String get countryNameIR => 'Iran';

  @override
  String get countryNameIQ => 'Iraq';

  @override
  String get countryNameIE => 'Irlanda';

  @override
  String get countryNameIL => 'Israele';

  @override
  String get countryNameIT => 'Italia';

  @override
  String get countryNameCI => 'Costa d\'Avorio';

  @override
  String get countryNameJM => 'Giamaica';

  @override
  String get countryNameJP => 'Giappone';

  @override
  String get countryNameJO => 'Giordania';

  @override
  String get countryNameKZ => 'Kazakistan';

  @override
  String get countryNameKE => 'Kenya';

  @override
  String get countryNameKI => 'Kiribati';

  @override
  String get countryNameXK => 'Kosovo';

  @override
  String get countryNameKW => 'Kuwait';

  @override
  String get countryNameKG => 'Kirghizistan';

  @override
  String get countryNameLA => 'Laos';

  @override
  String get countryNameLV => 'Lettonia';

  @override
  String get countryNameLB => 'Libano';

  @override
  String get countryNameLS => 'Lesotho';

  @override
  String get countryNameLR => 'Liberia';

  @override
  String get countryNameLY => 'Libia';

  @override
  String get countryNameLI => 'Liechtenstein';

  @override
  String get countryNameLT => 'Lituania';

  @override
  String get countryNameLU => 'Lussemburgo';

  @override
  String get countryNameMG => 'Madagascar';

  @override
  String get countryNameMW => 'Malawi';

  @override
  String get countryNameMY => 'Malaysia';

  @override
  String get countryNameMV => 'Maldive';

  @override
  String get countryNameML => 'Mali';

  @override
  String get countryNameMT => 'Malta';

  @override
  String get countryNameMH => 'Isole Marshall';

  @override
  String get countryNameMR => 'Mauritania';

  @override
  String get countryNameMU => 'Mauritius';

  @override
  String get countryNameMX => 'Messico';

  @override
  String get countryNameFM => 'Micronesia';

  @override
  String get countryNameMD => 'Moldavia';

  @override
  String get countryNameMC => 'Monaco';

  @override
  String get countryNameMN => 'Mongolia';

  @override
  String get countryNameME => 'Montenegro';

  @override
  String get countryNameMA => 'Marocco';

  @override
  String get countryNameMZ => 'Mozambico';

  @override
  String get countryNameMM => 'Myanmar';

  @override
  String get countryNameNA => 'Namibia';

  @override
  String get countryNameNR => 'Nauru';

  @override
  String get countryNameNP => 'Nepal';

  @override
  String get countryNameNL => 'Paesi Bassi';

  @override
  String get countryNameNZ => 'Nuova Zelanda';

  @override
  String get countryNameNI => 'Nicaragua';

  @override
  String get countryNameNE => 'Niger';

  @override
  String get countryNameNG => 'Nigeria';

  @override
  String get countryNameKP => 'Corea del Nord';

  @override
  String get countryNameMK => 'Macedonia del Nord';

  @override
  String get countryNameNO => 'Norvegia';

  @override
  String get countryNameOM => 'Oman';

  @override
  String get countryNamePK => 'Pakistan';

  @override
  String get countryNamePW => 'Palau';

  @override
  String get countryNamePS => 'Palestina';

  @override
  String get countryNamePA => 'Panama';

  @override
  String get countryNamePG => 'Papua Nuova Guinea';

  @override
  String get countryNamePY => 'Paraguay';

  @override
  String get countryNamePE => 'Perù';

  @override
  String get countryNamePH => 'Filippine';

  @override
  String get countryNamePL => 'Polonia';

  @override
  String get countryNamePT => 'Portogallo';

  @override
  String get countryNameQA => 'Qatar';

  @override
  String get countryNameRO => 'Romania';

  @override
  String get countryNameRU => 'Russia';

  @override
  String get countryNameRW => 'Ruanda';

  @override
  String get countryNameKN => 'Saint Kitts e Nevis';

  @override
  String get countryNameLC => 'Santa Lucia';

  @override
  String get countryNameVC => 'Saint Vincent e Grenadine';

  @override
  String get countryNameWS => 'Samoa';

  @override
  String get countryNameSM => 'San Marino';

  @override
  String get countryNameST => 'São Tomé e Príncipe';

  @override
  String get countryNameSA => 'Arabia Saudita';

  @override
  String get countryNameSN => 'Senegal';

  @override
  String get countryNameRS => 'Serbia';

  @override
  String get countryNameSC => 'Seychelles';

  @override
  String get countryNameSL => 'Sierra Leone';

  @override
  String get countryNameSG => 'Singapore';

  @override
  String get countryNameSK => 'Slovacchia';

  @override
  String get countryNameSI => 'Slovenia';

  @override
  String get countryNameSB => 'Isole Salomone';

  @override
  String get countryNameSO => 'Somalia';

  @override
  String get countryNameZA => 'Sudafrica';

  @override
  String get countryNameKR => 'Corea del Sud';

  @override
  String get countryNameSS => 'Sudan del Sud';

  @override
  String get countryNameES => 'Spagna';

  @override
  String get countryNameLK => 'Sri Lanka';

  @override
  String get countryNameSD => 'Sudan';

  @override
  String get countryNameSR => 'Suriname';

  @override
  String get countryNameSE => 'Svezia';

  @override
  String get countryNameCH => 'Svizzera';

  @override
  String get countryNameSY => 'Siria';

  @override
  String get countryNameTW => 'Taiwan';

  @override
  String get countryNameTJ => 'Tagikistan';

  @override
  String get countryNameTZ => 'Tanzania';

  @override
  String get countryNameTH => 'Thailandia';

  @override
  String get countryNameTL => 'Timor Est';

  @override
  String get countryNameTG => 'Togo';

  @override
  String get countryNameTO => 'Tonga';

  @override
  String get countryNameTT => 'Trinidad e Tobago';

  @override
  String get countryNameTN => 'Tunisia';

  @override
  String get countryNameTR => 'Turchia';

  @override
  String get countryNameTM => 'Turkmenistan';

  @override
  String get countryNameTV => 'Tuvalu';

  @override
  String get countryNameUG => 'Uganda';

  @override
  String get countryNameUA => 'Ucraina';

  @override
  String get countryNameAE => 'Emirati Arabi Uniti';

  @override
  String get countryNameGB => 'Regno Unito';

  @override
  String get countryNameUS => 'Stati Uniti';

  @override
  String get countryNameUY => 'Uruguay';

  @override
  String get countryNameUZ => 'Uzbekistan';

  @override
  String get countryNameVU => 'Vanuatu';

  @override
  String get countryNameVA => 'Città del Vaticano';

  @override
  String get countryNameVE => 'Venezuela';

  @override
  String get countryNameVN => 'Vietnam';

  @override
  String get countryNameYE => 'Yemen';

  @override
  String get countryNameZM => 'Zambia';

  @override
  String get countryNameZW => 'Zimbabwe';

  @override
  String get countryNameHK => 'Hong Kong';

  @override
  String get countryNamePR => 'Porto Rico';

  @override
  String get spotsCatRestaurant => 'Ristorante';

  @override
  String get spotsCatCafe => 'Caffè';

  @override
  String get spotsCatCulturalSite => 'Luogo culturale';

  @override
  String get spotsCatMarket => 'Mercato';

  @override
  String get spotsCatViewpoint => 'Belvedere';

  @override
  String spotsCreatedNamed(String name) {
    return 'Luogo «$name» creato!';
  }

  @override
  String get spotsEmptyHint =>
      'Ancora nessun luogo culturale in questa città. Aggiungi tu il primo!';

  @override
  String spotsEmptyCategoryHint(String category) {
    return 'Ancora nessun luogo in «$category» in questa città. Aggiungi tu il primo!';
  }

  @override
  String spotsReviewCountParen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count recensioni)',
      one: '(1 recensione)',
    );
    return '$_temp0';
  }

  @override
  String get uexpLangHebrew => 'Ebraico';

  @override
  String get uexpLangThai => 'Thailandese';

  @override
  String get uexpLangVietnamese => 'Vietnamita';

  @override
  String get safetyAcademyModCommunicationTitle => 'Capacità comunicative';

  @override
  String get safetyAcademyModCommunicationDesc =>
      'Sviluppa abitudini comunicative sane, tra cui consenso, limiti e ascolto attivo.';

  @override
  String get safetyAcademyLsnActiveListeningTitle => 'Ascolto attivo';

  @override
  String get safetyAcademyLsnActiveListeningS0 =>
      'L\'ascolto attivo è la base di un legame autentico. Va oltre il semplice sentire le parole: significa coinvolgersi pienamente con l\'altra persona e farla sentire apprezzata.';

  @override
  String get safetyAcademyLsnActiveListeningS1 =>
      'Fai domande di approfondimento su ciò che l\'altra persona ha detto, non solo su ciò di cui vuoi parlare tu. Dimostra un interesse sincero.';

  @override
  String get safetyAcademyLsnActiveListeningS2 => 'Tecniche di ascolto attivo';

  @override
  String get safetyAcademyLsnActiveListeningS2I0 =>
      'Dai tutta la tua attenzione (metti via il telefono)';

  @override
  String get safetyAcademyLsnActiveListeningS2I1 =>
      'Usa segnali verbali (“Capisco”, “Interessante”)';

  @override
  String get safetyAcademyLsnActiveListeningS2I2 =>
      'Riformula ciò che hai sentito (“Quindi mi stai dicendo che…”)';

  @override
  String get safetyAcademyLsnActiveListeningS2I3 =>
      'Fai domande aperte di approfondimento';

  @override
  String get safetyAcademyLsnActiveListeningS2I4 =>
      'Evita di interrompere o di preparare la risposta mentre l\'altra persona parla';

  @override
  String get safetyAcademyLsnActiveListeningS3 =>
      'Nelle conversazioni via chat, ascoltare attivamente significa leggere i messaggi con attenzione, rispondere a ciò che è stato effettivamente detto e fare domande ponderate invece di riportare ogni argomento su di te.';

  @override
  String get safetyAcademyLsnActiveListeningQ0 =>
      'La persona con cui esci racconta del suo ultimo viaggio. Qual è la risposta migliore in termini di ascolto attivo?';

  @override
  String get safetyAcademyLsnActiveListeningQ0O0 =>
      '“Figo. Comunque, io sono andato a…”';

  @override
  String get safetyAcademyLsnActiveListeningQ0O1 =>
      '“Sembra fantastico! Qual è stato il momento più bello del viaggio?”';

  @override
  String get safetyAcademyLsnActiveListeningQ0O2 =>
      '“Ci sono stato anch\'io, lascia che ti racconti.”';

  @override
  String get safetyAcademyLsnActiveListeningQ0O3 => '“Bello.”';

  @override
  String get safetyAcademyLsnActiveListeningQ0Exp =>
      'Fare una domanda di approfondimento sulla sua esperienza dimostra un interesse sincero e mantiene viva la conversazione.';

  @override
  String get safetyAcademyLsnActiveListeningQ1 =>
      'Cosa dovresti evitare durante l\'ascolto attivo?';

  @override
  String get safetyAcademyLsnActiveListeningQ1O0 =>
      'Mantenere il contatto visivo';

  @override
  String get safetyAcademyLsnActiveListeningQ1O1 =>
      'Preparare la risposta mentre l\'altra persona sta ancora parlando';

  @override
  String get safetyAcademyLsnActiveListeningQ1O2 => 'Annuire ogni tanto';

  @override
  String get safetyAcademyLsnActiveListeningQ1O3 =>
      'Fare domande di approfondimento';

  @override
  String get safetyAcademyLsnActiveListeningQ1Exp =>
      'Se stai preparando la prossima risposta, non stai ascoltando davvero. Concentrati prima sul capire, poi rispondi.';

  @override
  String get safetyAcademyLsnBoundariesTitle => 'Stabilire dei limiti';

  @override
  String get safetyAcademyLsnBoundariesS0 =>
      'I limiti sono le regole che stabilisci su come vuoi essere trattato. Sono essenziali per relazioni sane e proteggono il tuo benessere emotivo, fisico e mentale.';

  @override
  String get safetyAcademyLsnBoundariesS1 =>
      'Esprimi i tuoi limiti in modo chiaro e fin da subito. Per esempio: “Preferisco conoscere qualcuno in chat prima di incontrarlo di persona” oppure “Al momento non mi sento a mio agio a condividere foto”.';

  @override
  String get safetyAcademyLsnBoundariesS2 =>
      'Se qualcuno forza ripetutamente un limite che hai stabilito, è un serio campanello d\'allarme, a prescindere dalle sue giustificazioni.';

  @override
  String get safetyAcademyLsnBoundariesS3 => 'Esempi di limiti sani';

  @override
  String get safetyAcademyLsnBoundariesS3I0 =>
      'Decidere quando sei pronto a condividere il tuo numero di telefono';

  @override
  String get safetyAcademyLsnBoundariesS3I1 =>
      'Stabilire fino a che ora qualcuno può scriverti';

  @override
  String get safetyAcademyLsnBoundariesS3I2 =>
      'Essere chiaro su quale contatto fisico ti mette a tuo agio durante gli appuntamenti';

  @override
  String get safetyAcademyLsnBoundariesS3I3 =>
      'Dire di no a programmi che ti sembrano affrettati o scomodi';

  @override
  String get safetyAcademyLsnBoundariesS3I4 =>
      'Prenderti una pausa dalla conversazione quando hai bisogno di spazio';

  @override
  String get safetyAcademyLsnBoundariesS4 =>
      'Ricorda: stabilire dei limiti non significa essere difficili. È rispetto per te stesso. Una persona che ti apprezza capirà e rispetterà i tuoi limiti.';

  @override
  String get safetyAcademyLsnBoundariesQ0 =>
      'Dici al tuo match che non ti senti ancora a tuo agio a condividere il tuo numero, ma continua a chiedertelo. Cosa indica?';

  @override
  String get safetyAcademyLsnBoundariesQ0O0 => 'È davvero interessato a te';

  @override
  String get safetyAcademyLsnBoundariesQ0O1 =>
      'Ha solo fretta di far proseguire la conversazione';

  @override
  String get safetyAcademyLsnBoundariesQ0O2 =>
      'Non sta rispettando il limite che hai espresso';

  @override
  String get safetyAcademyLsnBoundariesQ0O3 =>
      'È un comportamento normale negli appuntamenti';

  @override
  String get safetyAcademyLsnBoundariesQ0Exp =>
      'Forzare ripetutamente un limite espresso chiaramente è una mancanza di rispetto e un campanello d\'allarme, qualunque sia il motivo addotto.';

  @override
  String get safetyAcademyLsnBoundariesQ1 =>
      'Qual è il momento migliore per comunicare un limite?';

  @override
  String get safetyAcademyLsnBoundariesQ1O0 =>
      'Dopo che è stato superato più volte';

  @override
  String get safetyAcademyLsnBoundariesQ1O1 =>
      'In modo chiaro e presto, prima che diventi un problema';

  @override
  String get safetyAcademyLsnBoundariesQ1O2 =>
      'Solo se l\'altra persona lo chiede';

  @override
  String get safetyAcademyLsnBoundariesQ1O3 =>
      'Negli appuntamenti i limiti non sono necessari';

  @override
  String get safetyAcademyLsnBoundariesQ1Exp =>
      'Esprimere i limiti presto e chiaramente previene i malintesi e imposta un clima di rispetto reciproco.';

  @override
  String get safetyAcademyLsnConsentTitle => 'Capire il consenso';

  @override
  String get safetyAcademyLsnConsentS0 =>
      'Il consenso è un accordo chiaro, entusiasta e continuo. Riguarda ogni aspetto degli appuntamenti: dalla condivisione di informazioni personali all\'intimità fisica.';

  @override
  String get safetyAcademyLsnConsentS1 =>
      'Il consenso non riguarda solo il contatto fisico. Condividere le foto di qualcuno, inoltrare i suoi messaggi o diffondere i suoi dati personali senza permesso è anch\'esso una violazione del consenso.';

  @override
  String get safetyAcademyLsnConsentS2 => 'Principi chiave del consenso';

  @override
  String get safetyAcademyLsnConsentS2I0 =>
      'Libero: senza pressioni, coercizione o manipolazione';

  @override
  String get safetyAcademyLsnConsentS2I1 =>
      'Revocabile: chiunque può cambiare idea in qualsiasi momento';

  @override
  String get safetyAcademyLsnConsentS2I2 =>
      'Informato: basato su informazioni oneste e complete';

  @override
  String get safetyAcademyLsnConsentS2I3 =>
      'Entusiasta: cerca un “sì” attivo, non solo l\'assenza di un “no”';

  @override
  String get safetyAcademyLsnConsentS2I4 =>
      'Specifico: acconsentire a una cosa non significa acconsentire a tutto';

  @override
  String get safetyAcademyLsnConsentS3 =>
      'Il silenzio o la mancanza di un “no” non equivalgono al consenso. Cerca sempre un accordo chiaro e positivo.';

  @override
  String get safetyAcademyLsnConsentS4 =>
      'Chiedere il consenso non è imbarazzante: dimostra maturità e rispetto. Semplici domande come “Ti senti a tuo agio?” o “Ti andrebbe di…?” fanno una grande differenza.';

  @override
  String get safetyAcademyLsnConsentQ0 =>
      'Quale affermazione descrive meglio il consenso?';

  @override
  String get safetyAcademyLsnConsentQ0O0 => 'L\'assenza di un “no”';

  @override
  String get safetyAcademyLsnConsentQ0O1 =>
      'Un accordo chiaro, entusiasta e continuo';

  @override
  String get safetyAcademyLsnConsentQ0O2 =>
      'Qualcosa di necessario solo per il contatto fisico';

  @override
  String get safetyAcademyLsnConsentQ0O3 =>
      'Un accordo dato una volta sola che vale per tutte le interazioni future';

  @override
  String get safetyAcademyLsnConsentQ0Exp =>
      'Il consenso deve essere chiaro, entusiasta e continuo, e può essere revocato in qualsiasi momento. Vale per tutte le interazioni.';

  @override
  String get safetyAcademyLsnConsentQ1 =>
      'La persona con cui esci ha accettato di venire a casa tua, ma una volta arrivata sembra a disagio. Cosa dovresti fare?';

  @override
  String get safetyAcademyLsnConsentQ1O0 =>
      'Ha già accettato, quindi continua come previsto';

  @override
  String get safetyAcademyLsnConsentQ1O1 =>
      'Chiederle come si sente e proporre di andare da un\'altra parte';

  @override
  String get safetyAcademyLsnConsentQ1O2 =>
      'Ignorare il disagio: probabilmente è solo nervosismo';

  @override
  String get safetyAcademyLsnConsentQ1O3 =>
      'Dirle che non avrebbe dovuto accettare se non voleva venire';

  @override
  String get safetyAcademyLsnConsentQ1Exp =>
      'Il consenso è revocabile. Se qualcuno sembra a disagio, chiedigli come sta. Il suo benessere conta più dei programmi.';

  @override
  String get safetyAcademyModCulturalSensitivityTitle =>
      'Sensibilità culturale';

  @override
  String get safetyAcademyModCulturalSensitivityDesc =>
      'Vivi gli appuntamenti interculturali con rispetto, curiosità e consapevolezza.';

  @override
  String get safetyAcademyLsnCulturalDosTitle =>
      'Appuntamenti interculturali: cosa fare';

  @override
  String get safetyAcademyLsnCulturalDosS0 =>
      'Frequentare una persona di un\'altra cultura può essere una delle esperienze più arricchenti. Affrontala con curiosità sincera, rispetto e voglia di imparare.';

  @override
  String get safetyAcademyLsnCulturalDosS1 =>
      'Fai domande aperte sulla sua cultura con curiosità sincera, non come un interrogatorio. “Quali tradizioni sono importanti per la tua famiglia?” è molto meglio di “Ma voi fate davvero X?”';

  @override
  String get safetyAcademyLsnCulturalDosS2 =>
      'Cosa fare negli appuntamenti interculturali';

  @override
  String get safetyAcademyLsnCulturalDosS2I0 =>
      'Informati sulle usanze culturali di base prima di un appuntamento';

  @override
  String get safetyAcademyLsnCulturalDosS2I1 =>
      'Mostra un interesse sincero per le sue origini e tradizioni';

  @override
  String get safetyAcademyLsnCulturalDosS2I2 =>
      'Sii aperto a provare nuovi cibi, attività ed esperienze';

  @override
  String get safetyAcademyLsnCulturalDosS2I3 =>
      'Rispetta le dinamiche familiari che possono essere diverse dalle tue';

  @override
  String get safetyAcademyLsnCulturalDosS2I4 =>
      'Impara qualche parola o frase nella sua lingua';

  @override
  String get safetyAcademyLsnCulturalDosS2I5 =>
      'Chiedi come preferisce essere chiamata o presentata';

  @override
  String get safetyAcademyLsnCulturalDosS3 =>
      'Ricorda che ogni persona è prima di tutto un individuo. La consapevolezza culturale è un punto di partenza, ma conosci la persona al di là degli stereotipi.';

  @override
  String get safetyAcademyLsnCulturalDosQ0 =>
      'Qual è il modo migliore per conoscere la cultura della persona con cui esci?';

  @override
  String get safetyAcademyLsnCulturalDosQ0O0 =>
      'Fare supposizioni basate su ciò che hai visto nei film';

  @override
  String get safetyAcademyLsnCulturalDosQ0O1 =>
      'Fare domande aperte e ponderate con curiosità sincera';

  @override
  String get safetyAcademyLsnCulturalDosQ0O2 =>
      'Interrogarla su curiosità culturali lette online';

  @override
  String get safetyAcademyLsnCulturalDosQ0O3 =>
      'Evitare del tutto l\'argomento per non offendere';

  @override
  String get safetyAcademyLsnCulturalDosQ0Exp =>
      'La curiosità sincera e rispettosa è l\'approccio migliore. Lascia che condivida ciò che per lei è importante.';

  @override
  String get safetyAcademyLsnCulturalDosQ1 =>
      'La persona con cui esci menziona una tradizione di famiglia che non capisci. Cosa dovresti fare?';

  @override
  String get safetyAcademyLsnCulturalDosQ1O0 => 'Annuire e fingere di capire';

  @override
  String get safetyAcademyLsnCulturalDosQ1O1 =>
      'Chiederle di spiegarti di più e perché è importante';

  @override
  String get safetyAcademyLsnCulturalDosQ1O2 =>
      'Dirle che le tue tradizioni sono diverse';

  @override
  String get safetyAcademyLsnCulturalDosQ1O3 => 'Cambiare argomento';

  @override
  String get safetyAcademyLsnCulturalDosQ1Exp =>
      'Chiederle di raccontarti di più dimostra rispetto e interesse sincero per il suo mondo.';

  @override
  String get safetyAcademyLsnCulturalDontsTitle =>
      'Appuntamenti interculturali: cosa evitare';

  @override
  String get safetyAcademyLsnCulturalDontsS0 =>
      'Commenti ben intenzionati ma poco informati possono risultare offensivi o sminuenti. Conoscere gli errori più comuni ti aiuta a vivere gli appuntamenti interculturali con delicatezza.';

  @override
  String get safetyAcademyLsnCulturalDontsS1 =>
      'Non ridurre mai qualcuno alla sua etnia o nazionalità. Commenti come “Ho sempre voluto uscire con un/una [nazionalità]” o “Sei carino/a per essere [etnia]” sono offensivi, non complimenti.';

  @override
  String get safetyAcademyLsnCulturalDontsS2 =>
      'Cosa evitare negli appuntamenti interculturali';

  @override
  String get safetyAcademyLsnCulturalDontsS2I0 =>
      'Non feticizzare né esotizzare la sua cultura o il suo aspetto';

  @override
  String get safetyAcademyLsnCulturalDontsS2I1 =>
      'Non dare per scontato che rappresenti tutta la sua cultura';

  @override
  String get safetyAcademyLsnCulturalDontsS2I2 =>
      'Non scherzare sul suo accento o sulla sua lingua';

  @override
  String get safetyAcademyLsnCulturalDontsS2I3 =>
      'Non metterle pressione perché spieghi o difenda le sue pratiche culturali';

  @override
  String get safetyAcademyLsnCulturalDontsS2I4 =>
      'Non paragonarla a stereotipi o a rappresentazioni dei media';

  @override
  String get safetyAcademyLsnCulturalDontsS2I5 =>
      'Non liquidare le differenze culturali come poco importanti';

  @override
  String get safetyAcademyLsnCulturalDontsS3 =>
      'Se commetti un passo falso culturale, scusati sinceramente, impara dall\'errore e vai avanti. Non scusarti in modo eccessivo, fino a spostare l\'attenzione sui tuoi sentimenti.';

  @override
  String get safetyAcademyLsnCulturalDontsQ0 =>
      'Quale commento è culturalmente insensibile?';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O0 =>
      '“Mi piacerebbe tanto assaggiare la cucina del tuo paese.”';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O1 =>
      '“Hai un aspetto così esotico.”';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O2 => '“Che lingua parli a casa?”';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O3 =>
      '“Raccontami di una festa che celebra la tua famiglia.”';

  @override
  String get safetyAcademyLsnCulturalDontsQ0Exp =>
      'Definire qualcuno “esotico” lo riduce al suo aspetto e alle sue origini culturali. È oggettivante, non un complimento.';

  @override
  String get safetyAcademyLsnCulturalDontsQ1 =>
      'Ti scappa per sbaglio qualcosa di culturalmente insensibile. Qual è la reazione migliore?';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O0 =>
      'Fingere che non sia successo nulla';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O1 =>
      'Scusarsi sinceramente, imparare dall\'errore e andare avanti';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O2 =>
      'Spiegare che non intendevi dirlo in quel senso';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O3 =>
      'Scusarsi in modo eccessivo e continuare a tirarlo fuori';

  @override
  String get safetyAcademyLsnCulturalDontsQ1Exp =>
      'Delle scuse sincere e brevi, seguite da un impegno reale a fare meglio, sono la reazione più matura.';

  @override
  String get safetyAcademyLsnCulturalCommunicationTitle =>
      'Comunicare tra culture';

  @override
  String get safetyAcademyLsnCulturalCommunicationS0 =>
      'Gli stili comunicativi variano molto da una cultura all\'altra. Ciò che in una cultura sembra diretto e sincero, in un\'altra può risultare scortese. Capire queste differenze evita i malintesi.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS1 =>
      'Se qualcosa che la persona con cui esci dice o fa ti confonde, presumi buone intenzioni e chiedi chiarimenti invece di trarre conclusioni affrettate.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2 =>
      'Differenze culturali nella comunicazione da tenere presenti';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I0 =>
      'Stili comunicativi diretti e indiretti';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I1 =>
      'Norme sullo spazio personale e sul contatto fisico';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I2 =>
      'Aspettative sul contatto visivo (in alcune culture guardare dritto negli occhi è considerato irrispettoso)';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I3 =>
      'Atteggiamenti verso la puntualità e il tempo';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I4 =>
      'Usanze e aspettative sui regali';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I5 =>
      'Il ruolo dell\'umorismo e quali argomenti sono tabù';

  @override
  String get safetyAcademyLsnCulturalCommunicationS3 =>
      'Nel dubbio, comunica apertamente. Un semplice “Voglio essere sicuro/a di aver capito bene” aiuta molto a colmare le distanze culturali.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0 =>
      'La persona con cui esci evita il contatto visivo diretto. Cosa dovresti pensare?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O0 =>
      'Non è interessata a te';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O1 => 'Non è sincera';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O2 =>
      'Può essere una norma culturale: non presumere cattive intenzioni';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O3 =>
      'È timida e ha bisogno di più incoraggiamento';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0Exp =>
      'In molte culture evitare il contatto visivo diretto è un segno di rispetto, non di disinteresse o disonestà.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1 =>
      'Qual è l\'approccio migliore quando le differenze culturali nella comunicazione creano confusione?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O0 => 'Pensare al peggio';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O1 =>
      'Ignorare la cosa e sperare che si risolva';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O2 =>
      'Chiedere chiarimenti con mente aperta';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O3 =>
      'Dirle di comunicare più come fai tu';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1Exp =>
      'Una comunicazione aperta e senza giudizi è il modo migliore per affrontare le differenze culturali.';

  @override
  String get safetyAcademyModOnlineSafetyTitle => 'Sicurezza online: le basi';

  @override
  String get safetyAcademyModOnlineSafetyDesc =>
      'Impara a proteggere la tua identità e a riconoscere possibili truffe negli incontri online.';

  @override
  String get safetyAcademyLsnProfileProtectionTitle => 'Protezione del profilo';

  @override
  String get safetyAcademyLsnProfileProtectionS0 =>
      'Il tuo profilo è la tua prima impressione, ma può anche esporre informazioni personali se non fai attenzione. Imparare a condividere il giusto ti mantiene al sicuro pur mostrando la tua personalità.';

  @override
  String get safetyAcademyLsnProfileProtectionS1 =>
      'Usa una foto unica che non compaia sugli altri tuoi profili social. Le ricerche inverse per immagini possono collegare tra loro i tuoi account.';

  @override
  String get safetyAcademyLsnProfileProtectionS2 =>
      'Non inserire mai nella tua bio il tuo nome completo, il luogo di lavoro, l\'indirizzo di casa o il numero di telefono.';

  @override
  String get safetyAcademyLsnProfileProtectionS3 =>
      'Checklist di sicurezza del profilo';

  @override
  String get safetyAcademyLsnProfileProtectionS3I0 =>
      'Rimuovi o ritaglia i punti di riferimento riconoscibili vicino a casa tua';

  @override
  String get safetyAcademyLsnProfileProtectionS3I1 =>
      'Usa solo il nome di battesimo o un soprannome';

  @override
  String get safetyAcademyLsnProfileProtectionS3I2 =>
      'Disattiva i metadati di posizione nelle foto caricate';

  @override
  String get safetyAcademyLsnProfileProtectionS3I3 =>
      'Evita foto in divisa da lavoro o con badge identificativi visibili';

  @override
  String get safetyAcademyLsnProfileProtectionS3I4 =>
      'Rivedi il tuo profilo dal punto di vista di un estraneo';

  @override
  String get safetyAcademyLsnProfileProtectionS4 =>
      'Un profilo ben fatto bilancia apertura e privacy. Condividi i tuoi interessi e valori, ma tieni i dettagli come la tua routine quotidiana o il tuo quartiere per conversazioni successive.';

  @override
  String get safetyAcademyLsnProfileProtectionQ0 =>
      'Quale di queste informazioni è sicuro inserire nel tuo profilo?';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O0 =>
      'Il tuo indirizzo di casa';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O1 => 'I tuoi hobby preferiti';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O2 =>
      'Il nome della tua azienda e il tuo reparto';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O3 =>
      'Il tuo numero di telefono';

  @override
  String get safetyAcademyLsnProfileProtectionQ0Exp =>
      'Condividere i tuoi hobby è ottimo per avviare una conversazione senza rivelare dettagli personali che potrebbero servire a rintracciarti.';

  @override
  String get safetyAcademyLsnProfileProtectionQ1 =>
      'Perché dovresti usare foto uniche nel tuo profilo?';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O0 =>
      'Per sembrare più attraente';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O1 =>
      'Perché le app di incontri comprimono le immagini';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O2 =>
      'Per evitare che una ricerca inversa per immagini porti ai tuoi altri account';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O3 =>
      'Le foto uniche ricevono più like';

  @override
  String get safetyAcademyLsnProfileProtectionQ1Exp =>
      'Gli strumenti di ricerca inversa per immagini possono collegare il tuo profilo a social, blog o pagine professionali, rivelando la tua identità completa.';

  @override
  String get safetyAcademyLsnProfileProtectionQ2 =>
      'Cosa dovresti controllare prima di caricare una foto?';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O0 => 'Che abbia un bel filtro';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O1 =>
      'Che i metadati di posizione siano stati rimossi e non siano visibili punti di riferimento riconoscibili';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O2 =>
      'Che sia stata scattata di recente';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O3 => 'Che sia un selfie';

  @override
  String get safetyAcademyLsnProfileProtectionQ2Exp =>
      'I metadati delle foto (dati EXIF) possono contenere coordinate GPS. Anche punti di riferimento come cartelli stradali o nomi di edifici possono rivelare dove ti trovi.';

  @override
  String get safetyAcademyLsnScamRecognitionTitle => 'Riconoscere le truffe';

  @override
  String get safetyAcademyLsnScamRecognitionS0 =>
      'Le truffe romantiche costano ogni anno miliardi alle vittime in tutto il mondo. I truffatori creano rapidamente un legame emotivo e poi lo sfruttano per ottenere denaro o dati personali. Conoscere i segnali può proteggerti.';

  @override
  String get safetyAcademyLsnScamRecognitionS1 =>
      'Se qualcuno ti chiede denaro, carte regalo, criptovalute o aiuto economico all\'inizio di una relazione – per quanto convincente sia la storia – è quasi certamente una truffa.';

  @override
  String get safetyAcademyLsnScamRecognitionS2 =>
      'Fai presto una videochiamata. I truffatori evitano i video in diretta perché smascherano le identità false. Se qualcuno evita ripetutamente le videochiamate, fai attenzione.';

  @override
  String get safetyAcademyLsnScamRecognitionS3 =>
      'Segnali d\'allarme tipici di una truffa';

  @override
  String get safetyAcademyLsnScamRecognitionS3I0 =>
      'Il profilo sembra troppo perfetto (foto da modello, carriera da sogno)';

  @override
  String get safetyAcademyLsnScamRecognitionS3I1 =>
      'Dice di essere un militare all\'estero, di lavorare su una piattaforma petrolifera o di essere un uomo o una donna d\'affari internazionale';

  @override
  String get safetyAcademyLsnScamRecognitionS3I2 =>
      'Si innamora con una rapidità insolita («love bombing»)';

  @override
  String get safetyAcademyLsnScamRecognitionS3I3 =>
      'Evita le videochiamate o gli incontri di persona';

  @override
  String get safetyAcademyLsnScamRecognitionS3I4 =>
      'Chiede denaro per emergenze, viaggi o spese mediche';

  @override
  String get safetyAcademyLsnScamRecognitionS3I5 =>
      'Ti chiede presto di spostare la conversazione su un\'altra piattaforma';

  @override
  String get safetyAcademyLsnScamRecognitionS4 =>
      'Se sospetti una truffa, interrompi subito ogni comunicazione. Segnala il profilo nell\'app e valuta di sporgere denuncia alle autorità locali.';

  @override
  String get safetyAcademyLsnScamRecognitionQ0 =>
      'Una persona con cui hai fatto match una settimana fa dice di amarti e ti chiede soldi per venire a trovarti. Cosa dovresti fare?';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O0 =>
      'Mandare i soldi – sembra sincero';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O1 =>
      'Chiedere più dettagli sul perché ha bisogno di soldi';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O2 =>
      'Riconoscere lo schema classico di una truffa romantica e segnalare la persona';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O3 =>
      'Offrirti di comprargli direttamente il biglietto aereo';

  @override
  String get safetyAcademyLsnScamRecognitionQ0Exp =>
      'Dichiarare amore molto in fretta e poi chiedere soldi è lo schema tipico delle truffe romantiche. Segnala e blocca.';

  @override
  String get safetyAcademyLsnScamRecognitionQ1 =>
      'Quale professione viene spesso usata dai truffatori come copertura?';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O0 => 'Insegnante della zona';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O1 =>
      'Militare in missione all\'estero';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O2 => 'Barista del quartiere';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O3 => 'Impiegato della zona';

  @override
  String get safetyAcademyLsnScamRecognitionQ1Exp =>
      'I truffatori dicono spesso di essere in missione militare, di lavorare offshore o di viaggiare per affari per giustificare il fatto di non potersi incontrare di persona né fare videochiamate.';

  @override
  String get safetyAcademyLsnScamRecognitionQ2 =>
      'Qual è un buon primo passo per verificare che qualcuno sia reale?';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O0 =>
      'Chiedere il suo indirizzo di casa';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O1 =>
      'Chiedere una videochiamata';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O2 =>
      'Mandargli dei soldi per vedere come reagisce';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O3 =>
      'Cercarlo su tutti i social network';

  @override
  String get safetyAcademyLsnScamRecognitionQ2Exp =>
      'Una videochiamata è uno dei modi più semplici per verificare che qualcuno sia chi dice di essere. Di solito i truffatori evitano i video in diretta a ogni costo.';

  @override
  String get safetyAcademyLsnRedFlagsTitle =>
      'Segnali d\'allarme nel comportamento';

  @override
  String get safetyAcademyLsnRedFlagsS0 =>
      'Oltre alle truffe, esistono schemi di comportamento che possono indicare persone controllanti, manipolatrici o potenzialmente pericolose. Imparare a riconoscerli presto può evitarti situazioni dannose.';

  @override
  String get safetyAcademyLsnRedFlagsS1 =>
      'Chi ti fa pressione per condividere foto intime, incontrarvi subito o allontanarti dagli amici sta mostrando un comportamento controllante.';

  @override
  String get safetyAcademyLsnRedFlagsS2 =>
      'Segnali d\'allarme nel comportamento';

  @override
  String get safetyAcademyLsnRedFlagsS2I0 =>
      'Gelosia eccessiva o possessività ancora prima di essersi incontrati';

  @override
  String get safetyAcademyLsnRedFlagsS2I1 =>
      'Pressioni per ottenere informazioni personali o contenuti intimi';

  @override
  String get safetyAcademyLsnRedFlagsS2I2 =>
      'Arrabbiarsi se non rispondi subito';

  @override
  String get safetyAcademyLsnRedFlagsS2I3 =>
      'Non rispettare i limiti che hai espresso';

  @override
  String get safetyAcademyLsnRedFlagsS2I4 =>
      'Farti sentire in colpa perché passi del tempo con altre persone';

  @override
  String get safetyAcademyLsnRedFlagsS2I5 => 'Racconti incoerenti su se stessi';

  @override
  String get safetyAcademyLsnRedFlagsS3 =>
      'Fidati del tuo istinto. Se una conversazione ti mette a disagio, non devi spiegazioni a nessuno. Va sempre bene smettere di rispondere, bloccare o segnalare.';

  @override
  String get safetyAcademyLsnRedFlagsS4 =>
      'Le relazioni sane si basano sul rispetto reciproco. Chi tiene davvero a te rispetterà i tuoi tempi, i tuoi limiti e la tua autonomia.';

  @override
  String get safetyAcademyLsnRedFlagsQ0 =>
      'Il tuo match si arrabbia perché ci metti un\'ora a rispondere. Cosa indica?';

  @override
  String get safetyAcademyLsnRedFlagsQ0O0 => 'Gli piaci davvero';

  @override
  String get safetyAcademyLsnRedFlagsQ0O1 => 'È entusiasta della conversazione';

  @override
  String get safetyAcademyLsnRedFlagsQ0O2 =>
      'Un comportamento potenzialmente controllante';

  @override
  String get safetyAcademyLsnRedFlagsQ0O3 => 'È solo ansioso';

  @override
  String get safetyAcademyLsnRedFlagsQ0Exp =>
      'Arrabbiarsi per i tempi di risposta prima ancora di essersi incontrati è un segnale di comportamento controllante. Ognuno ha diritto ai propri tempi.';

  @override
  String get safetyAcademyLsnRedFlagsQ1 =>
      'Qual è la reazione migliore quando qualcuno ti fa pressione per avere foto intime?';

  @override
  String get safetyAcademyLsnRedFlagsQ1O0 => 'Mandarle per evitare discussioni';

  @override
  String get safetyAcademyLsnRedFlagsQ1O1 =>
      'Rifiutare con fermezza e, se insiste, bloccarlo e segnalarlo';

  @override
  String get safetyAcademyLsnRedFlagsQ1O2 =>
      'Chiedergli di mandare prima le sue';

  @override
  String get safetyAcademyLsnRedFlagsQ1O3 => 'Promettere di mandarle più tardi';

  @override
  String get safetyAcademyLsnRedFlagsQ1Exp =>
      'Non dovresti mai sentirti sotto pressione per condividere contenuti intimi. Una persona rispettosa accetterà la tua decisione senza insistere.';

  @override
  String get safetyAcademyLsnRedFlagsQ2 =>
      'Quale di questi è un segnale sano nelle prime conversazioni?';

  @override
  String get safetyAcademyLsnRedFlagsQ2O0 =>
      'Vuole sapere esattamente come trascorri le tue giornate';

  @override
  String get safetyAcademyLsnRedFlagsQ2O1 =>
      'Rispetta i tuoi tempi e i tuoi limiti';

  @override
  String get safetyAcademyLsnRedFlagsQ2O2 =>
      'Ti dice «ti amo» già nei primi giorni';

  @override
  String get safetyAcademyLsnRedFlagsQ2O3 =>
      'Ti chiede di smettere di parlare con altre persone sull\'app';

  @override
  String get safetyAcademyLsnRedFlagsQ2Exp =>
      'Il rispetto dei tempi e dei limiti è la base di un legame sano. Tutto il resto di questo elenco è un potenziale segnale d\'allarme.';

  @override
  String get safetyAcademyModEmotionalIntelligenceTitle =>
      'Intelligenza emotiva';

  @override
  String get safetyAcademyModEmotionalIntelligenceDesc =>
      'Comprendi gli stili di attaccamento e i linguaggi dell\'amore e sviluppa la consapevolezza emotiva.';

  @override
  String get safetyAcademyLsnAttachmentStylesTitle => 'Stili di attaccamento';

  @override
  String get safetyAcademyLsnAttachmentStylesS0 =>
      'La teoria dell\'attaccamento spiega come le nostre prime relazioni influenzano il modo in cui ci leghiamo ai partner. Comprendere il tuo stile di attaccamento può aiutarti a costruire relazioni più sane.';

  @override
  String get safetyAcademyLsnAttachmentStylesS1 =>
      'I quattro principali stili di attaccamento sono: sicuro, ansioso, evitante e disorganizzato. La maggior parte delle persone è un mix, e gli stili possono cambiare con consapevolezza e impegno.';

  @override
  String get safetyAcademyLsnAttachmentStylesS2 =>
      'I quattro stili di attaccamento';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I0 =>
      'Sicuro: a proprio agio con la vicinanza, fiducioso, comunicativo';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I1 =>
      'Ansioso: desidera la vicinanza ma teme il rifiuto, può aver bisogno di più rassicurazioni';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I2 =>
      'Evitante: dà molto valore all\'indipendenza, può allontanarsi quando il rapporto diventa intimo';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I3 =>
      'Disorganizzato: un mix di ansioso ed evitante, spesso dovuto a esperienze infantili difficili';

  @override
  String get safetyAcademyLsnAttachmentStylesS3 =>
      'Conoscere il tuo stile ti aiuta a capire le tue reazioni. Se tendi all\'attaccamento ansioso, potresti renderti conto che l\'impulso di scrivere di continuo nasce dalla paura, non da un bisogno reale. Se sei evitante, potresti notare la tendenza a chiuderti quando le emozioni si fanno intense.';

  @override
  String get safetyAcademyLsnAttachmentStylesS4 =>
      'Comprendere lo stile di attaccamento del partner ti aiuta a rispondere con empatia anziché con frustrazione. Un partner evitante che si allontana non ti sta rifiutando: è il suo meccanismo di difesa.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0 =>
      'Il tuo partner ha bisogno di molte rassicurazioni e va in ansia quando non rispondi subito. Quale stile di attaccamento potrebbe riflettere?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O0 => 'Sicuro';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O1 => 'Ansioso';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O2 => 'Evitante';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O3 => 'Disorganizzato';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0Exp =>
      'L\'attaccamento ansioso è caratterizzato da un forte desiderio di vicinanza e dalla paura del rifiuto, che spesso portano al bisogno di frequenti rassicurazioni.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1 =>
      'Qual è la reazione più sana quando riconosci i tuoi schemi di attaccamento?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O0 =>
      'Accettare che non possono cambiare';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O1 =>
      'Dare la colpa ai tuoi genitori per il tuo stile';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O2 =>
      'Usare la consapevolezza per comunicare meglio e lavorare verso un attaccamento sicuro';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O3 =>
      'Uscire solo con persone che hanno il tuo stesso stile';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1Exp =>
      'Gli stili di attaccamento possono evolvere con la consapevolezza di sé, la comunicazione e, a volte, un supporto professionale.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2 =>
      'Una persona con uno stile di attaccamento evitante potrebbe:';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O0 =>
      'Mandare più messaggi se non rispondi subito';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O1 =>
      'Allontanarsi o chiudersi quando la relazione diventa emotivamente intima';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O2 =>
      'Voler passare ogni momento insieme';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O3 =>
      'Essere molto aperto sui propri sentimenti fin dall\'inizio';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2Exp =>
      'L\'attaccamento evitante si manifesta spesso con un allontanamento quando l\'intimità emotiva aumenta, come meccanismo di autoprotezione.';

  @override
  String get safetyAcademyLsnLoveLanguagesTitle => 'I linguaggi dell\'amore';

  @override
  String get safetyAcademyLsnLoveLanguagesS0 =>
      'Il concetto dei linguaggi dell\'amore, reso popolare dal Dr. Gary Chapman, suggerisce che le persone esprimono e ricevono amore in cinque modi principali. Capire il tuo e quello del partner può trasformare la vostra relazione.';

  @override
  String get safetyAcademyLsnLoveLanguagesS1 =>
      'I cinque linguaggi dell\'amore';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I0 =>
      'Parole di rassicurazione: complimenti, incoraggiamenti ed espressioni d\'amore';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I1 =>
      'Momenti speciali: attenzione esclusiva e presenza';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I2 =>
      'Ricevere regali: pensieri attenti come segno d\'affetto (non conta il prezzo)';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I3 =>
      'Gesti di servizio: azioni che semplificano la vita o dimostrano premura';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I4 =>
      'Contatto fisico: abbracci, tenersi per mano e altre manifestazioni fisiche d\'affetto';

  @override
  String get safetyAcademyLsnLoveLanguagesS2 =>
      'Fai attenzione a come la persona con cui esci esprime affetto: probabilmente è il suo linguaggio dell\'amore. Se ti fa sempre complimenti, con ogni probabilità dà valore alle parole di rassicurazione.';

  @override
  String get safetyAcademyLsnLoveLanguagesS3 =>
      'Avere linguaggi dell\'amore diversi è comune e gestibile. La chiave è la comunicazione: di\' al partner cosa ti fa sentire amato e fagli la stessa domanda.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0 =>
      'Il tuo partner trova sempre tempo per te e mette via il telefono quando parlate. Il suo linguaggio dell\'amore è probabilmente:';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O0 => 'Parole di rassicurazione';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O1 => 'Momenti speciali';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O2 => 'Ricevere regali';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O3 => 'Contatto fisico';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0Exp =>
      'Dare attenzione esclusiva e privilegiare la presenza è il tratto distintivo dei momenti speciali come linguaggio dell\'amore.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1 =>
      'Tu dai valore alle parole di rassicurazione, ma il tuo partner dimostra amore con i gesti di servizio. Cosa dovresti fare?';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O0 =>
      'Accettare che siete incompatibili';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O1 =>
      'Dire al partner di cosa hai bisogno e imparare a riconoscere il suo modo di dimostrare amore';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O2 =>
      'Cambiare il tuo linguaggio dell\'amore per adattarlo al suo';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O3 => 'Ignorare la differenza';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1Exp =>
      'La comunicazione è fondamentale. Esprimi ciò di cui hai bisogno e impara anche ad apprezzare il modo in cui il partner dimostra amore.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessTitle =>
      'Consapevolezza emotiva';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS0 =>
      'La consapevolezza emotiva è la capacità di riconoscere, comprendere e gestire le proprie emozioni restando sintonizzati su quelle degli altri. Negli appuntamenti, questa abilità evita decisioni impulsive e crea legami più profondi.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS1 =>
      'Prima di rispondere a un messaggio frustrante, fermati e individua cosa provi davvero. Ti senti ferito? In ansia? Deluso? Dare un nome all\'emozione ne riduce la forza.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2 =>
      'Sviluppare la consapevolezza emotiva';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I0 =>
      'Esercitati a dare un nome alle tue emozioni durante la giornata';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I1 =>
      'Nota le sensazioni fisiche legate alle emozioni (petto stretto = ansia)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I2 =>
      'Tieni un diario delle tue esperienze di appuntamenti e delle tue reazioni emotive';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I3 =>
      'Distingui tra reagire (impulsivo) e rispondere (ponderato)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I4 =>
      'Prendi l\'abitudine della pausa: aspetta prima di inviare messaggi carichi di emozione';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS3 =>
      'Consapevolezza emotiva non significa reprimere le emozioni. Significa comprenderle abbastanza bene da scegliere come agire di conseguenza.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS4 =>
      'Quando riesci a dire «Mi sono sentito ferito quando hai annullato i nostri piani» invece di «È chiaro che non ti importa di me», trasformi il conflitto in connessione. Questa è l\'intelligenza emotiva in azione.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0 =>
      'La persona con cui esci annulla i piani all\'ultimo minuto e ti arrabbi. Qual è la risposta emotivamente consapevole?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O0 =>
      'Mandare subito un messaggio arrabbiato';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O1 =>
      'Fare ghosting per punizione';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O2 =>
      'Fermarti, riconoscere i tuoi sentimenti e poi comunicare con calma come ti ha fatto sentire l\'annullamento';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O3 =>
      'Fingere che non ti importi';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0Exp =>
      'Fermarti a riconoscere le tue emozioni e poi comunicarle con calma porta a risultati migliori che reagire d\'impulso.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1 =>
      'Che cosa significa consapevolezza emotiva?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O0 =>
      'Non mostrare mai le emozioni';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O1 => 'Essere sempre felici';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O2 =>
      'Riconoscere e comprendere le emozioni per scegliere come agire di conseguenza';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O3 =>
      'Esprimere ogni emozione non appena la provi';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1Exp =>
      'La consapevolezza emotiva riguarda il riconoscere e il comprendere, il che permette risposte ponderate anziché reazioni impulsive.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2 =>
      'Quale di questi è un esempio di «rispondere» anziché «reagire»?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O0 =>
      'Scrivere una risposta arrabbiata appena ti senti turbato';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O1 =>
      'Aspettare, riflettere su ciò che provi e poi scrivere un messaggio ponderato';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O2 =>
      'Ignorare completamente il messaggio';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O3 =>
      'Sfogarti con gli amici prima di rispondere';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2Exp =>
      'Rispondere implica una pausa intenzionale per riflettere, mentre reagire è guidato dall\'emozione del momento.';

  @override
  String get safetyAcademyModFirstMeetingTitle => 'Guida al primo incontro';

  @override
  String get safetyAcademyModFirstMeetingDesc =>
      'Consigli essenziali per primi appuntamenti sicuri e sereni con persone conosciute online.';

  @override
  String get safetyAcademyLsnPublicPlacesTitle =>
      'Incontrarsi in luoghi pubblici';

  @override
  String get safetyAcademyLsnPublicPlacesS0 =>
      'Incontrare per la prima volta qualcuno conosciuto su un\'app di incontri è emozionante, ma la sicurezza deve sempre venire prima di tutto. Scegliere il posto giusto è la base per un\'esperienza serena.';

  @override
  String get safetyAcademyLsnPublicPlacesS1 =>
      'Per il primo incontro scegli un bar affollato, un ristorante o un parco pubblico. Conoscere il locale ti dà un vantaggio – sai dove sono le uscite e conosci il personale.';

  @override
  String get safetyAcademyLsnPublicPlacesS2 =>
      'Per un primo appuntamento non accettare mai di vederti a casa di qualcuno, in un luogo isolato o in un posto che non conosci.';

  @override
  String get safetyAcademyLsnPublicPlacesS3 =>
      'Checklist del luogo del primo incontro';

  @override
  String get safetyAcademyLsnPublicPlacesS3I0 =>
      'Scegli un luogo pubblico e ben illuminato';

  @override
  String get safetyAcademyLsnPublicPlacesS3I1 => 'Scegli un posto che conosci';

  @override
  String get safetyAcademyLsnPublicPlacesS3I2 =>
      'Assicurati che nel locale ci siano altre persone';

  @override
  String get safetyAcademyLsnPublicPlacesS3I3 =>
      'Verifica che nel locale il telefono abbia campo';

  @override
  String get safetyAcademyLsnPublicPlacesS3I4 =>
      'Tieni pronto un piano B se devi andartene in fretta';

  @override
  String get safetyAcademyLsnPublicPlacesQ0 =>
      'Qual è il luogo più sicuro per un primo appuntamento?';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O0 => 'Il suo appartamento';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O1 => 'Un bar affollato in centro';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O2 =>
      'Un sentiero escursionistico isolato';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O3 => 'Casa tua';

  @override
  String get safetyAcademyLsnPublicPlacesQ0Exp =>
      'Un bar affollato è pubblico, c\'è personale intorno e puoi andartene facilmente se necessario.';

  @override
  String get safetyAcademyLsnPublicPlacesQ1 =>
      'Perché dovresti scegliere un posto che conosci?';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O0 =>
      'Per fare colpo sull\'altra persona con i tuoi consigli';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O1 =>
      'Perché conosci le uscite, il personale e i dintorni';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O2 =>
      'Costa meno se conosci il menù';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O3 => 'Non c\'è un vero vantaggio';

  @override
  String get safetyAcademyLsnPublicPlacesQ1Exp =>
      'Conoscere il locale significa sapere come andartene in fretta e a chi chiedere aiuto se ti senti a disagio.';

  @override
  String get safetyAcademyLsnSharingPlansTitle => 'Condividere i tuoi piani';

  @override
  String get safetyAcademyLsnSharingPlansS0 =>
      'Avvisare una persona di fiducia del tuo appuntamento è una delle misure di sicurezza più semplici ed efficaci. Il tuo contatto di sicurezza può sentire come stai e sa dove cercarti se qualcosa va storto.';

  @override
  String get safetyAcademyLsnSharingPlansS1 =>
      'Condividi con un amico fidato il profilo della persona che incontri, il luogo e l\'orario previsto di rientro. Organizza una chiamata di controllo 30 minuti dopo l\'inizio dell\'appuntamento.';

  @override
  String get safetyAcademyLsnSharingPlansS2 =>
      'Informazioni da condividere con il tuo contatto di sicurezza';

  @override
  String get safetyAcademyLsnSharingPlansS2I0 =>
      'Screenshot del profilo della persona che incontri';

  @override
  String get safetyAcademyLsnSharingPlansS2I1 =>
      'Nome (o nome utente) della persona che incontri';

  @override
  String get safetyAcademyLsnSharingPlansS2I2 =>
      'Data, ora e luogo dell\'incontro';

  @override
  String get safetyAcademyLsnSharingPlansS2I3 =>
      'Il tuo orario previsto di rientro';

  @override
  String get safetyAcademyLsnSharingPlansS2I4 =>
      'Orario concordato per sentirvi (ad es. una chiamata o un messaggio)';

  @override
  String get safetyAcademyLsnSharingPlansS3 =>
      'Puoi anche usare la funzione Share My Date di GreenGo per inviare facilmente i dettagli dell\'appuntamento a un contatto fidato. Non c\'è niente di cui vergognarsi nel voler stare al sicuro – chi incontri dovrebbe capirlo.';

  @override
  String get safetyAcademyLsnSharingPlansQ0 =>
      'Cosa dovresti condividere con un amico fidato prima di un primo appuntamento?';

  @override
  String get safetyAcademyLsnSharingPlansQ0O0 => 'Solo il nome del locale';

  @override
  String get safetyAcademyLsnSharingPlansQ0O1 =>
      'Profilo della persona, luogo, orario e rientro previsto';

  @override
  String get safetyAcademyLsnSharingPlansQ0O2 => 'Niente – è una cosa privata';

  @override
  String get safetyAcademyLsnSharingPlansQ0O3 =>
      'Solo un messaggio con scritto “ho un appuntamento”';

  @override
  String get safetyAcademyLsnSharingPlansQ0Exp =>
      'Più informazioni ha il tuo contatto di sicurezza, meglio potrà aiutarti se qualcosa va storto.';

  @override
  String get safetyAcademyLsnSharingPlansQ1 =>
      'Qual è un buon momento per la chiamata di controllo?';

  @override
  String get safetyAcademyLsnSharingPlansQ1O0 => 'Dopo l\'appuntamento';

  @override
  String get safetyAcademyLsnSharingPlansQ1O1 =>
      'Circa 30 minuti dopo l\'inizio dell\'appuntamento';

  @override
  String get safetyAcademyLsnSharingPlansQ1O2 =>
      'La chiamata di controllo non serve';

  @override
  String get safetyAcademyLsnSharingPlansQ1O3 =>
      'Prima di uscire per l\'appuntamento';

  @override
  String get safetyAcademyLsnSharingPlansQ1Exp =>
      'Una chiamata dopo 30 minuti ti dà abbastanza tempo per valutare la situazione e una via d\'uscita facile se ti senti a disagio.';

  @override
  String get safetyAcademyLsnTransportSafetyTitle =>
      'Sicurezza negli spostamenti';

  @override
  String get safetyAcademyLsnTransportSafetyS0 =>
      'Come arrivi a un appuntamento e come torni a casa conta tanto quanto il luogo dell\'incontro. Mantenere il controllo dei tuoi spostamenti ti permette di andartene quando vuoi.';

  @override
  String get safetyAcademyLsnTransportSafetyS1 =>
      'Al primo incontro non farti mai venire a prendere a casa. Riveleresti il tuo indirizzo e dipenderesti dall\'altra persona per tornare a casa.';

  @override
  String get safetyAcademyLsnTransportSafetyS2 =>
      'Guida tu, usa un servizio di ride-sharing o i mezzi pubblici. Tieni il telefono carico e abbi abbastanza soldi per tornare a casa in caso di emergenza.';

  @override
  String get safetyAcademyLsnTransportSafetyS3 =>
      'Checklist per spostamenti sicuri';

  @override
  String get safetyAcademyLsnTransportSafetyS3I0 =>
      'Organizza i tuoi spostamenti in autonomia';

  @override
  String get safetyAcademyLsnTransportSafetyS3I1 =>
      'Tieni il telefono completamente carico';

  @override
  String get safetyAcademyLsnTransportSafetyS3I2 =>
      'Tieni a disposizione soldi per una corsa d\'emergenza';

  @override
  String get safetyAcademyLsnTransportSafetyS3I3 =>
      'Condividi la tua posizione in tempo reale con un contatto fidato';

  @override
  String get safetyAcademyLsnTransportSafetyS3I4 =>
      'Se vai in auto, parcheggia in una zona ben illuminata';

  @override
  String get safetyAcademyLsnTransportSafetyS3I5 =>
      'Non lasciare il tuo drink incustodito se ti allontani';

  @override
  String get safetyAcademyLsnTransportSafetyQ0 =>
      'Perché dovresti organizzare i tuoi spostamenti in autonomia per un primo appuntamento?';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O0 =>
      'Per risparmiare sulla benzina';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O1 =>
      'Per poter andare via quando vuoi e mantenere privato il tuo indirizzo';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O2 => 'Per evitare il traffico';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O3 =>
      'Perché da soli è più facile parcheggiare';

  @override
  String get safetyAcademyLsnTransportSafetyQ0Exp =>
      'Avere un mezzo tuo significa non dipendere dall\'altra persona e mantenere privato il tuo indirizzo di casa.';

  @override
  String get safetyAcademyLsnTransportSafetyQ1 =>
      'La persona che devi incontrare si offre di passarti a prendere a casa. Cosa dovresti fare?';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O0 =>
      'Accettare – è un bel gesto';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O1 =>
      'Rifiutare gentilmente e proporre di vedervi direttamente sul posto';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O2 =>
      'Indicare un incrocio vicino invece del tuo indirizzo esatto';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O3 =>
      'Accettare, ma chiedere a un amico di guardare dalla finestra';

  @override
  String get safetyAcademyLsnTransportSafetyQ1Exp =>
      'Vedersi sul posto mantiene privato il tuo indirizzo e ti garantisce di spostarti in autonomia.';

  @override
  String get gamificationAchFirstMatchName => 'Primo match';

  @override
  String get gamificationAchFirstMatchDesc =>
      'Ottieni il tuo primo like reciproco';

  @override
  String get gamificationAchConversationStarterName => 'Attacca bottone';

  @override
  String get gamificationAchConversationStarterDesc => 'Avvia 10 conversazioni';

  @override
  String get gamificationAchVideoChampionName => 'Campione video';

  @override
  String get gamificationAchVideoChampionDesc => 'Completa 5 videochiamate';

  @override
  String get gamificationAchProfileMasterName => 'Maestro del profilo';

  @override
  String get gamificationAchProfileMasterDesc =>
      'Completa al 100% tutte le sezioni del profilo';

  @override
  String get gamificationAchGlobeTrotterName => 'Giramondo';

  @override
  String get gamificationAchGlobeTrotterDesc =>
      'Fai match con utenti di oltre 10 paesi';

  @override
  String get gamificationAchGenerousHeartName => 'Cuore generoso';

  @override
  String get gamificationAchGenerousHeartDesc => 'Regala monete ai tuoi match';

  @override
  String get gamificationAchDailyDedicationName => 'Costanza quotidiana';

  @override
  String get gamificationAchDailyDedicationDesc =>
      '7 giorni di accesso consecutivi';

  @override
  String get gamificationAchSuperStarName => 'Superstar';

  @override
  String get gamificationAchSuperStarDesc => 'Ricevi oltre 50 super like';

  @override
  String get gamificationAchSocialButterflyName => 'Farfalla sociale';

  @override
  String get gamificationAchSocialButterflyDesc =>
      'Mantieni oltre 20 conversazioni attive';

  @override
  String get gamificationAchPerfectWeekName => 'Settimana perfetta';

  @override
  String get gamificationAchPerfectWeekDesc =>
      'Completa tutte le sfide giornaliere per 7 giorni';

  @override
  String get gamificationAchEarlyBirdName => 'Mattiniero';

  @override
  String get gamificationAchEarlyBirdDesc =>
      'Invia messaggi prima delle 9:00 per 10 giorni';

  @override
  String get gamificationAchNightOwlName => 'Nottambulo';

  @override
  String get gamificationAchNightOwlDesc =>
      'Invia messaggi dopo le 22:00 per 10 giorni';

  @override
  String get gamificationAchCenturionName => 'Centurione';

  @override
  String get gamificationAchCenturionDesc => 'Raggiungi 100 match in totale';

  @override
  String get gamificationAchSpeedDaterName => 'Fulmine';

  @override
  String get gamificationAchSpeedDaterDesc =>
      'Fai match con 10 persone in un giorno';

  @override
  String get gamificationAchPhotoCollectorName => 'Collezionista di foto';

  @override
  String get gamificationAchPhotoCollectorDesc =>
      'Aggiungi 6 foto al tuo profilo';

  @override
  String get gamificationAchTrendSetterName => 'Pioniere';

  @override
  String get gamificationAchTrendSetterDesc => 'Sii tra i primi 1000 utenti';

  @override
  String get gamificationAchVerifiedName => 'Verificato';

  @override
  String get gamificationAchVerifiedDesc => 'Completa la verifica con foto';

  @override
  String get gamificationAchPremiumMemberName => 'Membro Premium';

  @override
  String get gamificationAchPremiumMemberDesc =>
      'Abbonati al livello Silver o Gold';

  @override
  String get gamificationAchCoinCollectorName => 'Collezionista di monete';

  @override
  String get gamificationAchCoinCollectorDesc => 'Accumula 1000 monete';

  @override
  String get gamificationAchMonthlyStreakName => 'Costanza mensile';

  @override
  String get gamificationAchMonthlyStreakDesc =>
      '30 giorni di accesso consecutivi';

  @override
  String get gamificationAchVocabularyBeginnerName => 'Esploratore di parole';

  @override
  String get gamificationAchVocabularyBeginnerDesc =>
      'Usa 100 parole diverse in chat';

  @override
  String get gamificationAchVocabularyIntermediateName => 'Fabbro di parole';

  @override
  String get gamificationAchVocabularyIntermediateDesc =>
      'Usa 500 parole diverse in chat';

  @override
  String get gamificationAchVocabularyAdvancedName => 'Esperto di vocabolario';

  @override
  String get gamificationAchVocabularyAdvancedDesc =>
      'Usa 1000 parole diverse in chat';

  @override
  String get gamificationAchVocabularyMasterName => 'Maestro del vocabolario';

  @override
  String get gamificationAchVocabularyMasterDesc =>
      'Usa 5000 parole diverse in chat';

  @override
  String get gamificationAchRareWordHunterName => 'Cacciatore di parole rare';

  @override
  String get gamificationAchRareWordHunterDesc =>
      'Usa 50 parole rare (punteggio di frequenza sotto 50)';

  @override
  String gamificationRewardCoinsPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count monete',
      one: '+1 moneta',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardBadgePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count badge',
      one: '+1 badge',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardBoostPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count boost',
      one: '+1 boost',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardWithValue(String reward) {
    return 'Ricompensa: $reward';
  }

  @override
  String get gamificationRewardBadge => 'Badge';

  @override
  String get gamificationVip => 'VIP';

  @override
  String get gamificationRewardsTitle => 'Ricompense';

  @override
  String gamificationXpToNextLevel(String xp) {
    return '$xp XP al livello successivo';
  }

  @override
  String get gamificationStreakDayUnitOne => 'giorno';

  @override
  String get gamificationStreakDayUnitOther => 'giorni';

  @override
  String get gamificationOnFire => '🎉 Inarrestabile!';

  @override
  String gamificationUserFallback(String id) {
    return 'Utente $id';
  }

  @override
  String gamificationNoticeAchievementUnlocked(String name, String reward) {
    return '$name sbloccato! $reward';
  }

  @override
  String gamificationNoticeAchievementReady(String name) {
    return 'Obiettivo completato! Pronto da sbloccare: $name';
  }

  @override
  String gamificationNoticeLevelUp(int level) {
    return 'Livello superiore! Hai raggiunto il livello $level!';
  }

  @override
  String get gamificationNoticeVip =>
      'Congratulazioni! Hai ottenuto lo status VIP! 👑';

  @override
  String gamificationNoticeLevelRewardsClaimed(int level, String rewards) {
    return 'Ricompense del livello $level riscattate! $rewards';
  }

  @override
  String gamificationNoticeChallengeRewardsClaimed(
      String name, String rewards) {
    return 'Ricompense di $name riscattate! $rewards';
  }

  @override
  String gamificationNoticeFeatureLocked(int count, String feature, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$feature si sblocca al livello $level. Mancano $count livelli!',
      one: '$feature si sblocca al livello $level. Manca 1 livello!',
    );
    return '$_temp0';
  }

  @override
  String get gamificationFeatureCustomChatThemes => 'Temi chat personalizzati';

  @override
  String get gamificationFeatureProfileVideo => 'Video del profilo';

  @override
  String get gamificationFeatureAdvancedFilters => 'Filtri avanzati';

  @override
  String get gamificationFeatureUnlimitedRewinds => 'Annullamenti illimitati';

  @override
  String get gamificationFeatureVipBadge => 'Badge VIP';

  @override
  String get gamificationFeaturePriorityLikes => 'Like prioritari';

  @override
  String get gamificationLevelRewardBronzeFrame => 'Cornice di bronzo';

  @override
  String get gamificationLevelRewardSilverFrame => 'Cornice d’argento';

  @override
  String get gamificationLevelRewardGoldFrame => 'Cornice d’oro';

  @override
  String get gamificationLevelRewardPlatinumFrame => 'Cornice di platino';

  @override
  String get gamificationLevelRewardDiamondFrame => 'Cornice di diamante';

  @override
  String get gamificationLevelRewardLegendaryFrame => 'Cornice leggendaria';

  @override
  String get gamificationLevelRewardVipCrown => 'Corona VIP';

  @override
  String gamificationLevelRewardMaxLevelBadge(int level) {
    return 'Badge livello $level';
  }

  @override
  String gamificationLevelRewardBonusCoins(int count) {
    return '$count monete bonus';
  }

  @override
  String get gamificationMissionAttend3Events => 'Partecipa a 3 eventi';

  @override
  String get gamificationMissionConnect3Countries =>
      'Connettiti con persone di 3 paesi';

  @override
  String get gamificationMissionJoinCommunity => 'Unisciti a una community';

  @override
  String get gamificationMissionCompleteProfile => 'Completa il tuo profilo';

  @override
  String get gamificationMissionAdd5People => 'Aggiungi 5 persone';

  @override
  String get updateRequiredTitle => 'Aggiornamento richiesto';

  @override
  String get updateRequiredMessage =>
      'È disponibile una nuova versione di GreenGo. Aggiorna per continuare a usare l\'app.';

  @override
  String get updateAvailableTitle => 'Aggiornamento disponibile';

  @override
  String get updateAvailableMessage =>
      'È disponibile una nuova versione di GreenGo con miglioramenti e nuove funzionalità.';

  @override
  String get updateVersionCurrent => 'Attuale';

  @override
  String get updateVersionRequired => 'Richiesta';

  @override
  String get updateVersionAvailable => 'Disponibile';

  @override
  String get updateVersionLatest => 'Ultima';

  @override
  String get updateWhatsNew => 'Novità';

  @override
  String get updateNowButton => 'Aggiorna ora';

  @override
  String get updateButton => 'Aggiorna';

  @override
  String get maintenanceTitle => 'In manutenzione';

  @override
  String get maintenanceCheckBackSoon => 'Torna a trovarci presto';

  @override
  String get maintenanceDefaultMessage =>
      'Stiamo effettuando interventi di manutenzione. Riprova più tardi.';

  @override
  String get countdownAlmostThere => 'Ci siamo quasi!';

  @override
  String get countdownVipEarlyAccess => 'Accesso anticipato VIP';

  @override
  String countdownLaunchDate(String date) {
    return 'Data di lancio: $date';
  }

  @override
  String get countdownTimeUntilLaunch => 'Tempo al lancio';

  @override
  String get countdownWantEarlierAccess => 'Vuoi accedere prima?';

  @override
  String countdownUpgradeForEarlierAccess(String date) {
    return 'Passa a un piano superiore per accedere prima del $date!';
  }

  @override
  String get countdownLaunchDay => 'Giorno del lancio!';

  @override
  String get countdownNowAvailable => 'GreenGo Chat è ora disponibile';

  @override
  String celebrationWelcomeToTier(String tier) {
    return 'Benvenuto in $tier!';
  }

  @override
  String get celebrationMembershipActive =>
      'Il tuo abbonamento premium è ora attivo';

  @override
  String get celebrationUnlimitedLikes => 'Like illimitati';

  @override
  String get celebrationSeeWhoLikedYou => 'Scopri a chi piaci';

  @override
  String celebrationPerDay(int count) {
    return '$count/giorno';
  }

  @override
  String get celebrationExclusiveEvents => 'Eventi esclusivi';

  @override
  String purchaseSuccessCoinsAdded(int count) {
    return '$count monete GreenGo aggiunte!';
  }

  @override
  String get pushChannelMainName => 'Notifiche GreenGo';

  @override
  String get pushChannelMainDescription => 'Messaggi, like, eventi e attività';

  @override
  String get pushChannelAnnouncementsName => 'Annunci';

  @override
  String get pushChannelAnnouncementsDescription =>
      'Comunicazioni e annunci di GreenGo';

  @override
  String get pushChannelSummaryName => 'Riepilogo attività';

  @override
  String get pushChannelSummaryDescription =>
      'Notifiche di attività raggruppate';

  @override
  String get pushChannelGeneralName => 'Generale';

  @override
  String get pushChannelGeneralDescription => 'Notifiche generali';

  @override
  String get usageLimitTypeConnects => 'connessioni';

  @override
  String get usageLimitTypePasses => 'passaggi';

  @override
  String get usageLimitTypePriorityConnects => 'Connessioni Prioritarie';

  @override
  String get usageLimitTypeDailyPriorityConnects =>
      'Connessioni Prioritarie giornaliere';

  @override
  String get usageLimitTypeSwipes => 'swipe';

  @override
  String get usageLimitTypeMessages => 'messaggi';

  @override
  String get usageLimitTypeMediaSends => 'invii multimediali';

  @override
  String get usageLimitTypeDirectMatches => 'match diretti';

  @override
  String get usageLimitTypeConnections => 'connessioni';

  @override
  String usageLimitUnlimited(String type) {
    return '$type illimitati';
  }

  @override
  String usageLimitRemainingThisHour(int remaining, String type) {
    return 'Ti restano $remaining $type in quest\'ora';
  }

  @override
  String usageLimitRemainingToday(int remaining, String type) {
    return 'Ti restano $remaining $type oggi';
  }

  @override
  String usageLimitConnectsHourly(int limit) {
    return 'Hai usato tutte le $limit connessioni di quest\'ora. Passa a un piano superiore o attendi l\'ora successiva.';
  }

  @override
  String usageLimitPassesHourly(int limit) {
    return 'Hai usato tutti i $limit passaggi di quest\'ora. Passa a un piano superiore o attendi l\'ora successiva.';
  }

  @override
  String usageLimitPriorityUnavailable(String tier) {
    return 'Le Connessioni Prioritarie non sono disponibili con il piano $tier. Passa a un piano superiore per sbloccare questa funzione!';
  }

  @override
  String usageLimitPriorityHourly(int limit) {
    return 'Hai usato tutte le $limit Connessioni Prioritarie di quest\'ora. Passa a un piano superiore o attendi l\'ora successiva.';
  }

  @override
  String usageLimitPriorityDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'Hai usato le tue $limit connessioni prioritarie gratuite di oggi. Usa le monete per averne altre o attendi domani.',
      one:
          'Hai usato la tua connessione prioritaria gratuita di oggi. Usa le monete per averne altre o attendi domani.',
    );
    return '$_temp0';
  }

  @override
  String usageLimitSwipesDaily(int limit) {
    return 'Hai usato tutti i $limit swipe di oggi. Passa a un piano superiore per averne di più o attendi domani.';
  }

  @override
  String usageLimitMessagesDaily(int limit) {
    return 'Hai raggiunto il limite giornaliero di $limit messaggi. Passa a un piano superiore per messaggi illimitati!';
  }

  @override
  String usageLimitMediaUnavailable(String tier) {
    return 'L\'invio di contenuti multimediali non è disponibile con il piano $tier. Passa a un piano superiore per inviare foto e video!';
  }

  @override
  String usageLimitMediaDaily(int limit) {
    return 'Hai raggiunto il limite giornaliero di $limit invii multimediali. Passa a un piano superiore o attendi domani.';
  }

  @override
  String usageLimitDirectMatchDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'Hai usato i tuoi $limit match diretti gratuiti di oggi. Usa le monete per averne altri o attendi domani.',
      one:
          'Hai usato il tuo match diretto gratuito di oggi. Usa le monete per averne altri o attendi domani.',
    );
    return '$_temp0';
  }

  @override
  String get contentFilterViolationEmail => 'indirizzo email';

  @override
  String get contentFilterViolationPhoneWords =>
      'numero di telefono (scritto in lettere)';

  @override
  String get contentFilterViolationPhone => 'numero di telefono';

  @override
  String get contentFilterViolationSocial => 'social/link';

  @override
  String adminImportSummary(int success, int duplicates, int errors) {
    return 'Importati: $success | Duplicati: $duplicates | Errori: $errors';
  }

  @override
  String get tierBoostCadenceNone => 'Nessuno';

  @override
  String get tierBoostCadenceMonthly => '1 al mese';

  @override
  String get tierBoostCadenceWeekly => '~1 a settimana';

  @override
  String get tierBoostCadenceDaily => '~1 al giorno';

  @override
  String get tierFilterLevelBasic => 'Base';

  @override
  String get tierFilterLevelStandard => 'Standard';

  @override
  String get tierFilterLevelAdvanced => 'Avanzati';

  @override
  String get tierFilterLevelAll => 'Tutti i filtri';

  @override
  String tierTtsCostValue(int coins) {
    return '$coins monete per traduzione';
  }

  @override
  String chatLearningLiteral(String text) {
    return 'Letterale: $text';
  }

  @override
  String chatLearningMeaning(String text) {
    return 'Significato: $text';
  }

  @override
  String get validatorNameRequired => 'Il nome è obbligatorio';

  @override
  String get validatorNameLettersOnly =>
      'Il nome può contenere solo lettere e spazi';

  @override
  String get validatorPhoneRequired => 'Il numero di telefono è obbligatorio';

  @override
  String get validatorPhoneMinDigits =>
      'Il numero di telefono deve avere almeno 10 cifre';

  @override
  String get validatorAgeRequired => 'L\'età è obbligatoria';

  @override
  String validatorMinAge(int minAge) {
    return 'Devi avere almeno $minAge anni';
  }

  @override
  String get validatorInvalidAge => 'Età non valida';

  @override
  String validatorBioMaxLength(int max) {
    return 'La bio deve avere meno di $max caratteri';
  }

  @override
  String get profileOnboardingIncompleteStep =>
      'Compila tutti i campi obbligatori';

  @override
  String get profileGenderPreferNotToSay => 'Preferisco non dirlo';

  @override
  String get profileOrientationStraight => 'Eterosessuale';

  @override
  String get profileOrientationGay => 'Gay';

  @override
  String get profileOrientationBisexual => 'Bisessuale';

  @override
  String get profileLanguageHebrew => 'Ebraico';

  @override
  String get profileLanguageThai => 'Thailandese';

  @override
  String get profileLanguageVietnamese => 'Vietnamita';

  @override
  String profileLatLon(String lat, String lon) {
    return 'Lat: $lat, Lon: $lon';
  }

  @override
  String get profileNicknameInvalid => 'Nickname non valido';

  @override
  String get profileNicknameErrorEmpty => 'Il nickname non può essere vuoto';

  @override
  String profileNicknameErrorTooShort(int min) {
    return 'Il nickname deve avere almeno $min caratteri';
  }

  @override
  String profileNicknameErrorTooLong(int max) {
    return 'Il nickname deve avere al massimo $max caratteri';
  }

  @override
  String get profileNicknameErrorStartLetter =>
      'Il nickname deve iniziare con una lettera';

  @override
  String get profileNicknameErrorChars =>
      'Il nickname può contenere solo lettere, numeri e underscore';

  @override
  String get profileNicknameErrorUnderscores =>
      'Il nickname non può contenere underscore consecutivi';

  @override
  String get profileNicknameErrorReserved =>
      'Il nickname non può contenere parole riservate';

  @override
  String get profileFreeUnlimited => 'Gratis - Illimitato';

  @override
  String get profileFreeWithPlatinum => 'Gratis con Platinum';

  @override
  String profileCoinsPerDay(int count) {
    return '$count monete/giorno';
  }

  @override
  String profileTravelerActiveSubtitle(
      String location, int hours, int minutes) {
    return '$location - ${hours}h ${minutes}m rimanenti';
  }

  @override
  String profileTravelerInactiveSubtitle(String cost) {
    return '$cost - Appari in un\'altra città';
  }

  @override
  String profileMinutesRemaining(int minutes) {
    return '${minutes}m rimanenti';
  }

  @override
  String profileHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m rimanenti';
  }

  @override
  String get profileGhostMode => 'Modalità fantasma';

  @override
  String get profileGhostModeActiveSubtitle =>
      'Modalità fantasma - Illimitata - Nascosto da scoperta e ricerca';

  @override
  String get profileGhostModeInactiveSubtitle =>
      'Gratis - Illimitato - Nascosto da scoperta e ricerca per nickname';

  @override
  String profileIncognitoCostSubtitle(int count) {
    return '$count monete/24h - Nascosto dalla scoperta';
  }

  @override
  String get photoDeleteTitle => 'Elimina foto';

  @override
  String travelerCouldNotResolveAddress(String coordinates) {
    return '$coordinates — impossibile trovare l\'indirizzo';
  }

  @override
  String get membershipTierNameBasicFree => 'Base (Gratuito)';

  @override
  String get membershipTierNameSilverPremium => 'Argento Premium';

  @override
  String get membershipTierNameGoldPremium => 'Oro Premium';

  @override
  String get membershipTierNamePlatinumVip => 'Platino VIP';

  @override
  String get membershipTierNameSilverVip => 'Argento VIP';

  @override
  String get membershipTierNameGoldVip => 'Oro VIP';

  @override
  String get membershipTierNameTester => 'Tester';

  @override
  String membershipBuyProductPrice(String product, String price) {
    return 'Acquista $product – $price';
  }

  @override
  String get coinSpendCategoryMatching => 'Abbinamenti';

  @override
  String get coinSpendCategoryMessaging => 'Messaggi';

  @override
  String get coinSpendCategoryGifts => 'Regali virtuali';

  @override
  String get coinSpendSeeWhoLiked => 'Chi ti ha messo like';

  @override
  String get coinSpendReadReceiptsDay => 'Conferme di lettura (1 giorno)';

  @override
  String get coinSpendRose => 'Rosa';

  @override
  String get coinSpendTeddyBear => 'Orsacchiotto';

  @override
  String get coinSpendDiamond => 'Diamante';

  @override
  String get coinSpendSuperLikeDesc => 'Invia un super like per farti notare';

  @override
  String get coinSpendBoostDesc => 'Fatti vedere da più persone per 30 min';

  @override
  String get coinSpendUndoDesc => 'Annulla il tuo ultimo swipe';

  @override
  String get coinSpendSeeWhoLikedDesc =>
      'Scopri a chi è piaciuto il tuo profilo';

  @override
  String get coinSpendReadReceiptsDesc =>
      'Scopri quando i messaggi vengono letti';

  @override
  String get coinSpendRoseDesc => 'Invia una rosa virtuale';

  @override
  String get coinSpendTeddyBearDesc => 'Invia un tenero orsacchiotto';

  @override
  String get coinSpendDiamondDesc => 'Invia un diamante scintillante';

  @override
  String get coinReasonFirstMatchReward => 'Premio per il primo match';

  @override
  String get coinReasonCompleteProfileReward => 'Premio profilo completo';

  @override
  String get coinReasonDailyLoginStreak => 'Serie di accessi giornalieri';

  @override
  String get coinReasonAchievementUnlocked => 'Traguardo sbloccato';

  @override
  String get coinReasonMonthlyAllowance => 'Bonus mensile';

  @override
  String get coinReasonGiftReceived => 'Regalo ricevuto';

  @override
  String get coinReasonGiftSent => 'Regalo inviato';

  @override
  String get coinReasonPromotionalBonus => 'Bonus promozionale';

  @override
  String get coinReasonReferralBonus => 'Bonus invito';

  @override
  String get coinReasonCoinPurchase => 'Acquisto di monete';

  @override
  String get coinReasonRefund => 'Rimborso';

  @override
  String get coinReasonUndoLastSwipe => 'Annulla ultimo swipe';

  @override
  String get coinReasonSeeWhoLikedYou => 'Scopri chi ti ha messo like';

  @override
  String get coinReasonDirectMessage => 'Messaggio diretto';

  @override
  String get coinReasonFeaturePurchase => 'Acquisto funzione';

  @override
  String get coinReasonCoinsExpired => 'Monete scadute';

  @override
  String get coinReasonAdminAdjustment => 'Rettifica amministratore';

  @override
  String coinTxDescFirstMatch(int amount) {
    return 'Congratulazioni per il tuo primo match! Hai guadagnato $amount monete.';
  }

  @override
  String coinTxDescCompleteProfile(int amount) {
    return 'Profilo completato! Hai guadagnato $amount monete.';
  }

  @override
  String coinTxDescDailyStreak(String streak, int amount) {
    return 'Serie di accessi: giorno $streak! Hai guadagnato $amount monete.';
  }

  @override
  String coinTxDescAchievement(String achievement, int amount) {
    return 'Traguardo sbloccato: $achievement! Hai guadagnato $amount monete.';
  }

  @override
  String coinTxDescAchievementGeneric(int amount) {
    return 'Traguardo sbloccato! Hai guadagnato $amount monete.';
  }

  @override
  String coinTxDescMonthlyAllowance(String tier, int amount) {
    return 'Bonus mensile $tier: $amount monete.';
  }

  @override
  String coinTxDescGiftReceived(int amount, String user) {
    return 'Hai ricevuto $amount monete da $user.';
  }

  @override
  String coinTxDescGiftSent(int amount, String user) {
    return 'Hai inviato $amount monete a $user.';
  }

  @override
  String coinTxDescPromotional(String campaign, int amount) {
    return 'Bonus promozionale $campaign: $amount monete.';
  }

  @override
  String coinTxDescPromotionalGeneric(int amount) {
    return 'Bonus promozionale: $amount monete.';
  }

  @override
  String coinTxDescReferral(int amount) {
    return 'Bonus invito: hai guadagnato $amount monete.';
  }

  @override
  String coinTxDescPurchase(int amount) {
    return 'Hai acquistato $amount monete.';
  }

  @override
  String coinTxDescPurchasePackage(int amount, String package) {
    return 'Hai acquistato $amount monete ($package).';
  }

  @override
  String coinTxDescRefund(int amount) {
    return 'Rimborso: $amount monete.';
  }

  @override
  String coinTxDescUsedFor(int amount, String feature) {
    return 'Hai usato $amount monete per $feature.';
  }

  @override
  String coinTxDescExpired(int amount) {
    return '$amount monete sono scadute.';
  }

  @override
  String coinTxDescClawback(int amount) {
    return '$amount monete rimosse: l’acquisto è stato rimborsato.';
  }

  @override
  String coinTxDescAdmin(int amount, String reason) {
    return 'Rettifica amministratore: $amount monete ($reason).';
  }

  @override
  String coinTxDescAdminGeneric(int amount) {
    return 'Rettifica amministratore: $amount monete.';
  }

  @override
  String coinPromoPercentBonus(int percent) {
    return '+$percent% monete bonus';
  }

  @override
  String get businessFollowerFallbackName => 'Membro GreenGo';

  @override
  String get bizCatRestaurant => 'Ristorante';

  @override
  String get bizCatBar => 'Bar';

  @override
  String get bizCatCafe => 'Caffè';

  @override
  String get bizCatNightclub => 'Discoteca';

  @override
  String get bizCatLounge => 'Lounge';

  @override
  String get bizCatHotel => 'Hotel';

  @override
  String get bizCatHostel => 'Ostello';

  @override
  String get bizCatGuesthouse => 'Pensione';

  @override
  String get bizCatResort => 'Resort';

  @override
  String get bizCatBedAndBreakfast => 'Bed & Breakfast';

  @override
  String get bizCatGym => 'Palestra';

  @override
  String get bizCatYogaStudio => 'Studio di yoga';

  @override
  String get bizCatFitnessStudio => 'Studio fitness';

  @override
  String get bizCatSpa => 'Spa';

  @override
  String get bizCatWellnessCenter => 'Centro benessere';

  @override
  String get bizCatBeautySalon => 'Centro estetico';

  @override
  String get bizCatBarbershop => 'Barbiere';

  @override
  String get bizCatMuseum => 'Museo';

  @override
  String get bizCatArtGallery => 'Galleria d\'arte';

  @override
  String get bizCatTheater => 'Teatro';

  @override
  String get bizCatCinema => 'Cinema';

  @override
  String get bizCatLiveMusicVenue => 'Locale con musica dal vivo';

  @override
  String get bizCatCulturalCenter => 'Centro culturale';

  @override
  String get bizCatTourOperator => 'Tour operator';

  @override
  String get bizCatTravelAgency => 'Agenzia di viaggi';

  @override
  String get bizCatLanguageSchool => 'Scuola di lingue';

  @override
  String get bizCatCookingSchool => 'Scuola di cucina';

  @override
  String get bizCatDanceStudio => 'Scuola di danza';

  @override
  String get bizCatCoworkingSpace => 'Spazio di coworking';

  @override
  String get bizCatEventVenue => 'Location per eventi';

  @override
  String get bizCatConferenceCenter => 'Centro congressi';

  @override
  String get bizCatShopRetail => 'Negozio / Vendita al dettaglio';

  @override
  String get bizCatBoutique => 'Boutique';

  @override
  String get bizCatBookstore => 'Libreria';

  @override
  String get bizCatMarket => 'Mercato';

  @override
  String get bizCatWinery => 'Cantina';

  @override
  String get bizCatBrewery => 'Birrificio';

  @override
  String get bizCatDistillery => 'Distilleria';

  @override
  String get bizCatFoodTruck => 'Food truck';

  @override
  String get bizCatBakery => 'Panetteria';

  @override
  String get bizCatCoffeeRoastery => 'Torrefazione';

  @override
  String get bizCatSportsClub => 'Club sportivo';

  @override
  String get bizCatAdventureAndOutdoor => 'Avventura e outdoor';

  @override
  String get bizCatDivingCenter => 'Centro immersioni';

  @override
  String get bizCatPhotographyStudio => 'Studio fotografico';

  @override
  String get bizCatCoachingAndConsulting => 'Coaching e consulenza';

  @override
  String get bizCatNonprofitAndNGO => 'No profit e ONG';

  @override
  String get bizCatCommunityCenter => 'Centro comunitario';

  @override
  String get bizCatTransportationService => 'Servizio di trasporto';

  @override
  String get bizCatOther => 'Altro';

  @override
  String get bizCatGroupFoodAndDrink => 'Cibo e bevande';

  @override
  String get bizCatGroupNightlife => 'Vita notturna';

  @override
  String get bizCatGroupStay => 'Alloggi';

  @override
  String get bizCatGroupWellness => 'Benessere';

  @override
  String get bizCatGroupCulture => 'Cultura';

  @override
  String get bizCatGroupTravelAndTours => 'Viaggi e tour';

  @override
  String get bizCatGroupLearnAndWork => 'Imparare e lavorare';

  @override
  String get bizCatGroupEvents => 'Eventi';

  @override
  String get bizCatGroupRetail => 'Negozi';

  @override
  String get bizCatGroupCommunityAndServices => 'Comunità e servizi';

  @override
  String get gamificationJourneyTitle => 'Il tuo percorso';

  @override
  String gamificationJourneyMilestonesCompleted(int completed, int total) {
    return '$completed di $total traguardi completati';
  }

  @override
  String get gamificationJourneyOverallProgress => 'Progresso complessivo';

  @override
  String get gamificationJourneyNoMilestones => 'Ancora nessun traguardo';

  @override
  String get gamificationJourneyCompletePrevious =>
      'Completa le categorie precedenti per sbloccare';

  @override
  String get gamificationJourneyTabStart => 'Inizio';

  @override
  String get gamificationJourneyTabMaster => 'Maestro';

  @override
  String get gamificationJourneyCatGettingStarted => 'Primi passi';

  @override
  String get gamificationJourneyCatSocializing => 'Socializzare';

  @override
  String get gamificationJourneyCatMastery => 'Maestria';

  @override
  String get gamificationJourneyCatGettingStartedDesc =>
      'Completa il tuo profilo e prendi confidenza con l’app';

  @override
  String get gamificationJourneyCatSocializingDesc =>
      'Connettiti con gli altri e crea legami';

  @override
  String get gamificationJourneyCatPremiumDesc =>
      'Sblocca funzioni e ricompense premium';

  @override
  String get gamificationJourneyCatMasteryDesc =>
      'Diventa un maestro degli appuntamenti';

  @override
  String get gamificationJourneyCatSpecialDesc =>
      'Traguardi e obiettivi esclusivi';

  @override
  String get gamificationJourneyCompleteProfileName => 'Profilo pro';

  @override
  String get gamificationJourneyCompleteProfileDesc =>
      'Completa il tuo profilo al 100%';

  @override
  String get gamificationJourneyAddPhotosName => 'Foto perfetta';

  @override
  String get gamificationJourneyAddPhotosDesc =>
      'Aggiungi 5 foto al tuo profilo';

  @override
  String get gamificationJourneyGetVerifiedName => 'Utente verificato';

  @override
  String get gamificationJourneyGetVerifiedDesc =>
      'Completa la verifica con foto';

  @override
  String get gamificationJourneyFirstMatchName => 'Prima connessione';

  @override
  String get gamificationJourneyFirstMatchDesc => 'Ottieni il tuo primo match';

  @override
  String get gamificationJourneyTenMatchesName => 'Stella nascente';

  @override
  String get gamificationJourneyTenMatchesDesc => 'Ottieni 10 match';

  @override
  String get gamificationJourneyFiftyMatchesName => 'Farfalla sociale';

  @override
  String get gamificationJourneyFiftyMatchesDesc => 'Ottieni 50 match';

  @override
  String get gamificationJourneyFirstMessageName => 'Rompighiaccio';

  @override
  String get gamificationJourneyFirstMessageDesc =>
      'Invia il tuo primo messaggio';

  @override
  String get gamificationJourneyHundredMessagesName => 'Re della conversazione';

  @override
  String get gamificationJourneyHundredMessagesDesc => 'Invia 100 messaggi';

  @override
  String get gamificationJourneyFirstVideoCallName => 'Faccia a faccia';

  @override
  String get gamificationJourneyFirstVideoCallDesc =>
      'Completa la tua prima videochiamata';

  @override
  String get gamificationJourneyTenVideoCallsName => 'Pro dei video';

  @override
  String get gamificationJourneyTenVideoCallsDesc =>
      'Completa 10 videochiamate';

  @override
  String get gamificationJourneyWeekStreakName => 'Utente costante';

  @override
  String get gamificationJourneyWeekStreakDesc =>
      'Mantieni una serie di 7 giorni di accesso';

  @override
  String get gamificationJourneyMonthStreakName => 'Super costante';

  @override
  String get gamificationJourneyMonthStreakDesc =>
      'Mantieni una serie di 30 giorni di accesso';

  @override
  String get gamificationJourneyUpgradeSilverName => 'Membro Silver';

  @override
  String get gamificationJourneyUpgradeSilverDesc => 'Passa a VIP Silver';

  @override
  String get gamificationJourneyUpgradeGoldName => 'Membro Gold';

  @override
  String get gamificationJourneyUpgradeGoldDesc => 'Passa a VIP Gold';

  @override
  String get gamificationJourneyUpgradePlatinumName => 'Membro Platinum';

  @override
  String get gamificationJourneyUpgradePlatinumDesc => 'Passa a VIP Platinum';

  @override
  String get gamificationJourneyTenAchievementsName =>
      'Cacciatore di obiettivi';

  @override
  String get gamificationJourneyTenAchievementsDesc => 'Ottieni 10 obiettivi';

  @override
  String get gamificationJourneyFiftyAchievementsName =>
      'Maestro degli obiettivi';

  @override
  String get gamificationJourneyFiftyAchievementsDesc => 'Ottieni 50 obiettivi';

  @override
  String get gamificationJourneyHundredMatchesName => 'Centurione';

  @override
  String get gamificationJourneyHundredMatchesDesc => 'Ottieni 100 match';

  @override
  String get gamificationStreakMilestone3Name => 'Buon inizio';

  @override
  String get gamificationStreakMilestone7Name => 'Guerriero della settimana';

  @override
  String get gamificationStreakMilestone14Name => 'Campione di due settimane';

  @override
  String get gamificationStreakMilestone30Name => 'Maestro del mese';

  @override
  String get gamificationStreakMilestone60Name => 'Campione di due mesi';

  @override
  String get gamificationStreakMilestone90Name => 'Leggenda del trimestre';

  @override
  String get gamificationStreakMilestone180Name => 'Eroe del semestre';

  @override
  String get gamificationStreakMilestone365Name => 'Un anno d’amore';

  @override
  String gamificationStreakMilestoneDesc(int days) {
    return 'Accedi per $days giorni consecutivi';
  }

  @override
  String get gamificationChallengeSend3MessagesName => 'Chiacchierata veloce';

  @override
  String get gamificationChallengeSend3MessagesDesc => 'Invia 3 messaggi';

  @override
  String get gamificationChallengeSend5MessagesName => 'Maestro dei messaggi';

  @override
  String get gamificationChallengeSend5MessagesDesc =>
      'Invia 5 messaggi ai tuoi match';

  @override
  String get gamificationChallengeSend10MessagesName =>
      'Re della conversazione';

  @override
  String get gamificationChallengeSend10MessagesDesc =>
      'Invia 10 messaggi oggi';

  @override
  String get gamificationChallengeSend15MessagesName => 'Maratona di chat';

  @override
  String get gamificationChallengeSend15MessagesDesc =>
      'Invia 15 messaggi oggi';

  @override
  String get gamificationChallengeGet1MatchName => 'Prima scintilla';

  @override
  String get gamificationChallengeGet1MatchDesc => 'Ottieni 1 nuovo match oggi';

  @override
  String get gamificationChallengeGet3MatchesName => 'Combinatore';

  @override
  String get gamificationChallengeGet3MatchesDesc =>
      'Ottieni 3 nuovi match oggi';

  @override
  String get gamificationChallengeGet5MatchesName => 'Calamita d’amore';

  @override
  String get gamificationChallengeGet5MatchesDesc =>
      'Ottieni 5 nuovi match oggi';

  @override
  String get gamificationChallengeSend1SuperlikeName => 'Scelta prioritaria';

  @override
  String get gamificationChallengeSend1SuperlikeDesc => 'Invia 1 super like';

  @override
  String get gamificationChallengeSend3SuperlikesName => 'Super liker';

  @override
  String get gamificationChallengeSend3SuperlikesDesc => 'Invia 3 super like';

  @override
  String get gamificationChallengeSend5SuperlikesName => 'Superstar';

  @override
  String get gamificationChallengeSend5SuperlikesDesc => 'Invia 5 super like';

  @override
  String get gamificationChallengeVideoCall1Name => 'Appassionato di video';

  @override
  String get gamificationChallengeVideoCall1Desc => 'Completa 1 videochiamata';

  @override
  String get gamificationChallengeVideoCall2Name => 'Pro dei video';

  @override
  String get gamificationChallengeVideoCall2Desc => 'Completa 2 videochiamate';

  @override
  String get gamificationChallengeAddPhotoName => 'Foto rinnovata';

  @override
  String get gamificationChallengeAddPhotoDesc =>
      'Aggiungi o aggiorna una foto del profilo';

  @override
  String get gamificationChallengeAdd2PhotosName => 'Galleria fotografica';

  @override
  String get gamificationChallengeAdd2PhotosDesc =>
      'Aggiungi 2 nuove foto del profilo';

  @override
  String get gamificationChallengeSend1GiftName => 'Donatore';

  @override
  String get gamificationChallengeSend1GiftDesc => 'Invia 1 regalo a un match';

  @override
  String get gamificationChallengeSend3GiftsName => 'Cuore generoso';

  @override
  String get gamificationChallengeSend3GiftsDesc => 'Invia 3 regali oggi';

  @override
  String get gamificationChallengeSend5GiftsName => 'Maestro dei regali';

  @override
  String get gamificationChallengeSend5GiftsDesc => 'Invia 5 regali oggi';

  @override
  String get gamificationChallengeChatStarterName => 'Rompighiaccio';

  @override
  String get gamificationChallengeChatStarterDesc =>
      'Invia 7 messaggi a match diversi';

  @override
  String get gamificationChallengeSocialButterflyName => 'Farfalla sociale';

  @override
  String get gamificationChallengeSocialButterflyDesc =>
      'Invia 20 messaggi oggi';

  @override
  String get gamificationChallengeMatchRushName => 'Corsa ai match';

  @override
  String get gamificationChallengeMatchRushDesc => 'Ottieni 7 match oggi';

  @override
  String get gamificationChallengeVideoMarathonName => 'Maratona video';

  @override
  String get gamificationChallengeVideoMarathonDesc =>
      'Completa 3 videochiamate';

  @override
  String get gamificationChallengeWeeklyMessages30Name =>
      'Appassionato di chat';

  @override
  String get gamificationChallengeWeeklyMessages30Desc =>
      'Invia 30 messaggi questa settimana';

  @override
  String get gamificationChallengeWeeklyMessages50Name => 'Maestro della chat';

  @override
  String get gamificationChallengeWeeklyMessages50Desc =>
      'Invia 50 messaggi questa settimana';

  @override
  String get gamificationChallengeWeeklyMessages100Name =>
      'Leggenda della chat';

  @override
  String get gamificationChallengeWeeklyMessages100Desc =>
      'Invia 100 messaggi questa settimana';

  @override
  String get gamificationChallengeWeeklyMatches10Name =>
      'Connettore della settimana';

  @override
  String get gamificationChallengeWeeklyMatches10Desc =>
      'Ottieni 10 match questa settimana';

  @override
  String get gamificationChallengeWeeklyMatches20Name =>
      'Campione di match della settimana';

  @override
  String get gamificationChallengeWeeklyMatches20Desc =>
      'Ottieni 20 match questa settimana';

  @override
  String get gamificationChallengeWeeklyMatches30Name => 'Macchina da match';

  @override
  String get gamificationChallengeWeeklyMatches30Desc =>
      'Ottieni 30 match questa settimana';

  @override
  String get gamificationChallengeWeeklySuperlikes5Name =>
      'Super liker della settimana';

  @override
  String get gamificationChallengeWeeklySuperlikes5Desc =>
      'Invia 5 super like questa settimana';

  @override
  String get gamificationChallengeWeeklySuperlikes10Name => 'Super fan';

  @override
  String get gamificationChallengeWeeklySuperlikes10Desc =>
      'Invia 10 super like questa settimana';

  @override
  String get gamificationChallengeWeeklySuperlikes15Name => 'Re della priorità';

  @override
  String get gamificationChallengeWeeklySuperlikes15Desc =>
      'Invia 15 super like questa settimana';

  @override
  String get gamificationChallengeWeeklyVideo3Name => 'Socievole in video';

  @override
  String get gamificationChallengeWeeklyVideo3Desc =>
      'Completa 3 videochiamate questa settimana';

  @override
  String get gamificationChallengeWeeklyVideo5Name => 'Star dei video';

  @override
  String get gamificationChallengeWeeklyVideo5Desc =>
      'Completa 5 videochiamate questa settimana';

  @override
  String get gamificationChallengeWeeklyGifts5Name =>
      'Donatore della settimana';

  @override
  String get gamificationChallengeWeeklyGifts5Desc =>
      'Invia 5 regali questa settimana';

  @override
  String get gamificationChallengeWeeklyGifts10Name => 'Anima generosa';

  @override
  String get gamificationChallengeWeeklyGifts10Desc =>
      'Invia 10 regali questa settimana';

  @override
  String get gamificationChallengeWeeklyPhotos3Name => 'Settimana delle foto';

  @override
  String get gamificationChallengeWeeklyPhotos3Desc =>
      'Aggiungi 3 foto questa settimana';

  @override
  String get gamificationChallengeWeeklyPerfectName => 'Settimana perfetta';

  @override
  String get gamificationChallengeWeeklyPerfectDesc =>
      'Completa tutte le sfide giornaliere per 7 giorni di fila';

  @override
  String get gamificationChallengeValentineMatchesName =>
      'Connessioni del cuore';

  @override
  String get gamificationChallengeValentineMatchesDesc =>
      'Ottieni 14 match durante la settimana di San Valentino (1 al giorno)';

  @override
  String get gamificationChallengeValentineVideoName => 'Serata virtuale';

  @override
  String get gamificationChallengeValentineVideoDesc =>
      'Completa 3 videochiamate';

  @override
  String get gamificationChallengeSummerMatchesName => 'Atmosfera da spiaggia';

  @override
  String get gamificationChallengeSummerMatchesDesc =>
      'Ottieni 30 match quest’estate';

  @override
  String get gamificationChallengeHolidayGiftsName => 'Donatore';

  @override
  String get gamificationChallengeHolidayGiftsDesc =>
      'Invia 10 regali in monete ai tuoi match';

  @override
  String get gamificationChallengeHolidayMessagesName => 'Spirito delle feste';

  @override
  String get gamificationChallengeHolidayMessagesDesc => 'Invia 100 messaggi';

  @override
  String get gamificationEventValentinesName => 'Settimana di San Valentino';

  @override
  String get gamificationEventValentinesDesc =>
      'Diffondi l’amore questa settimana di San Valentino!';

  @override
  String get gamificationEventSummerName => 'Amore estivo';

  @override
  String get gamificationEventSummerDesc =>
      'Trova la tua storia d’amore estiva!';

  @override
  String get gamificationEventHolidayName => 'Periodo delle feste';

  @override
  String get gamificationEventHolidayDesc => 'Trova l’amore in queste feste!';

  @override
  String get travelExploreTitle => 'Esplora viaggi';

  @override
  String get travelExploreInMyCity => 'Nella mia città';

  @override
  String get travelExploreWorldwide => 'In tutto il mondo';

  @override
  String travelExploreTravelersIn(String city) {
    return 'Viaggiatori a $city';
  }

  @override
  String get travelExploreUnknownLocation => 'Luogo sconosciuto';

  @override
  String get travelExploreLocalGuides => 'Guide locali';

  @override
  String get travelExploreCities => 'Città';

  @override
  String travelExploreGuideIn(String city) {
    return 'Guida a $city';
  }

  @override
  String travelExploreNoTravelersInCity(String city) {
    return 'Nessun viaggiatore a $city al momento';
  }

  @override
  String get travelExploreNoTravelers => 'Nessun viaggiatore trovato';

  @override
  String get travelExploreTryWorldwide =>
      'Passa a «In tutto il mondo» per vedere tutti i viaggiatori';

  @override
  String get travelExploreCheckBack =>
      'Torna più tardi per vedere i viaggiatori attivi';

  @override
  String get travelExploreShowWorldwide => 'Mostra in tutto il mondo';

  @override
  String get discoveryDealBreakerSmoking => 'Fumo';

  @override
  String get discoveryDealBreakerDrinking => 'Alcol';

  @override
  String get discoveryDealBreakerNoBio => 'Nessuna bio';

  @override
  String get discoveryDealBreakerNoPhotos => 'Nessuna foto';

  @override
  String get discoveryDealBreakerDifferentReligion => 'Religione diversa';

  @override
  String get discoveryDealBreakerDifferentPolitics => 'Idee politiche diverse';

  @override
  String get discoveryDealBreakerHasChildren => 'Ha figli';

  @override
  String get discoveryDealBreakerWantsChildren => 'Vuole figli';

  @override
  String get discoveryDealBreakerLongDistance => 'Lunga distanza';

  @override
  String get discoveryDealBreakerNonMonogamy => 'Non monogamia';

  @override
  String discoveryPrefCountryUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utenti',
      one: '1 utente',
    );
    return '$_temp0';
  }

  @override
  String get discoveryGridAuto => 'Auto';

  @override
  String get discoveryMatchFallbackName => 'Match';

  @override
  String get discoveryThisUser => 'questo utente';

  @override
  String get discoveryActionNope => 'No';

  @override
  String get exploreTierTester => 'Tester';

  @override
  String get chatCulturalContextTitle => 'Contesto culturale';

  @override
  String get chatCulturalContextLink => 'Contesto culturale';

  @override
  String get chatWordBreakdownTierRequired =>
      'La scomposizione delle parole è disponibile per i membri Silver, Gold e Platinum';

  @override
  String get chatPreviewSticker => 'Sticker';

  @override
  String get chatPreviewVoiceMessage => 'Messaggio vocale';

  @override
  String get chatPreviewAlbumShared => 'Album condiviso';

  @override
  String get chatPreviewAlbumRevoked => 'Accesso all\'album revocato';

  @override
  String get chatPreviewEvent => 'Evento';

  @override
  String get chatPreviewSayHi => 'Saluta il tuo match!';

  @override
  String chatTimeShortMinutes(int count) {
    return '$count min';
  }

  @override
  String chatTimeShortHours(int count) {
    return '$count h';
  }

  @override
  String chatTimeShortDays(int count) {
    return '$count g';
  }

  @override
  String get chatNotificationsMutedForChat =>
      'Notifiche silenziate per questa chat';

  @override
  String get chatNotificationsUnmuted => 'Notifiche riattivate';

  @override
  String get chatMuteNotifications => 'Silenzia notifiche';

  @override
  String get chatUnmuteNotifications => 'Riattiva notifiche';

  @override
  String chatAlbumSelectCount(int count) {
    return 'Seleziona ($count)';
  }

  @override
  String chatAlbumPhotosSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto selezionate',
      one: '1 foto selezionata',
    );
    return '$_temp0';
  }

  @override
  String chatSessionXp(int xp) {
    return '$xp XP';
  }

  @override
  String get chatPhraseHowAreYou => 'Come stai?';

  @override
  String get chatPhraseGoodMorning => 'Buongiorno!';

  @override
  String get chatPhraseAllGood => 'Tutto bene?';

  @override
  String get chatPhrasePleasedToMeetYou => 'Lieto di conoscerti!';

  @override
  String get chatPhraseNiceToMeetYou => 'Piacere di conoscerti!';

  @override
  String get chatPhraseWhatsUp => 'Come va?';

  @override
  String get chatSupportAiBadge => 'IA';

  @override
  String get chatGroupFallbackName => 'Gruppo';

  @override
  String get communitiesTypeLanguageCircle => 'Circolo linguistico';

  @override
  String get communitiesTypeCulturalInterest => 'Interesse culturale';

  @override
  String get communitiesTypeTravelGroup => 'Gruppo di viaggio';

  @override
  String get communitiesTypeLocalGuides => 'Guide locali';

  @override
  String get communitiesTypeStudyGroup => 'Gruppo di studio';

  @override
  String get communitiesTypeGeneral => 'Generale';

  @override
  String get communitiesRoleOwner => 'Proprietario';

  @override
  String get communitiesRoleAdmin => 'Admin';

  @override
  String get communitiesRoleMember => 'Membro';

  @override
  String get communitiesNoActivityYet => 'Ancora nessuna attività';

  @override
  String get communitiesLanguageMandarin => 'Mandarino';

  @override
  String get communitiesLanguageThai => 'Thailandese';

  @override
  String get communitiesLanguageVietnamese => 'Vietnamita';

  @override
  String get communitiesLanguageCatalan => 'Catalano';

  @override
  String get communitiesLanguageHebrew => 'Ebraico';

  @override
  String get videoPromptSelectorTitle => 'Scegli un tema';

  @override
  String get videoPromptSelectorSubtitle =>
      'Scegli un tema per il tuo video di presentazione';

  @override
  String get videoPromptIntroduceTitle => 'Presentati';

  @override
  String get videoPromptIntroduceDesc => 'Saluta e raccontaci chi sei';

  @override
  String get videoPromptIntroduceTemplate =>
      'Presentati nella tua lingua preferita';

  @override
  String get videoPromptNativeTitle => 'Lingua madre';

  @override
  String get videoPromptNativeDesc => 'Mostra la tua lingua madre';

  @override
  String get videoPromptNativeTemplate =>
      'Di\' qualcosa nella tua lingua madre';

  @override
  String get videoPromptTeachTitle => 'Insegna una frase';

  @override
  String get videoPromptTeachDesc => 'Condividi qualcosa di divertente da dire';

  @override
  String get videoPromptTeachTemplate => 'Insegnaci una frase nella tua lingua';

  @override
  String get videoPromptPlaceTitle => 'Luogo preferito';

  @override
  String get videoPromptPlaceDesc =>
      'Condividi un luogo che significa qualcosa per te';

  @override
  String get videoPromptPlaceTemplate =>
      'Qual è il tuo posto preferito da visitare?';

  @override
  String get videoPromptCultureTitle => 'Scambio culturale';

  @override
  String get videoPromptCultureDesc =>
      'Cosa significa per te lo scambio culturale?';

  @override
  String get videoPromptCultureTemplate =>
      'Descrivi il tuo scambio culturale ideale';

  @override
  String get videoPromptTalentTitle => 'Talento nascosto';

  @override
  String get videoPromptTalentDesc => 'Sorprendici con qualcosa di inaspettato';

  @override
  String get videoPromptTalentTemplate =>
      'Mostraci un talento nascosto o una curiosità su di te';

  @override
  String get videoPromptTripTitle => 'Viaggio dei sogni';

  @override
  String get videoPromptTripDesc => 'Dove andresti nel mondo?';

  @override
  String get videoPromptTripTemplate =>
      'Descrivi la tua destinazione dei sogni';

  @override
  String get videoPromptFreeTitle => 'Stile libero';

  @override
  String get videoPromptFreeDesc => 'Di\' quello che vuoi!';

  @override
  String get videoPromptFreeTemplate => 'Stile libero, senza tema';

  @override
  String get videoDiscoveryLiked => 'Ti piace!';

  @override
  String get videoDiscoveryPassed => 'Saltato';

  @override
  String get videoDiscoveryTitle => 'Video di presentazione';

  @override
  String get videoDiscoveryEmptyTitle => 'Ancora nessun video di presentazione';

  @override
  String get videoDiscoveryEmptySubtitle => 'Sii il primo a crearne uno!';

  @override
  String videoDiscoveryUserFallback(String id) {
    return 'Utente $id';
  }

  @override
  String videoDiscoveryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visualizzazioni',
      one: '1 visualizzazione',
    );
    return '$_temp0';
  }

  @override
  String get videoDiscoveryLike => 'Mi piace';

  @override
  String get videoDiscoveryPass => 'Passa';

  @override
  String get videoDiscoveryReport => 'Segnala';

  @override
  String get videoDiscoveryMute => 'Silenzia';

  @override
  String get videoDiscoveryUnmute => 'Riattiva audio';

  @override
  String get videoProfileUploadSuccess => 'Video caricato con successo!';

  @override
  String get videoProfileDeleteTitle => 'Eliminare il video?';

  @override
  String get videoProfileDeleteConfirm =>
      'Vuoi davvero eliminare il tuo video di presentazione?';

  @override
  String get videoProfileDeleted => 'Video eliminato';

  @override
  String get videoProfileScreenTitle => 'Video di presentazione';

  @override
  String get videoProfileFirstImpression => 'Fai un\'ottima prima impressione!';

  @override
  String videoProfileInfoBody(int seconds) {
    return 'Registra un video di $seconds secondi per presentarti. I profili con video ottengono il 40% di match in più!';
  }

  @override
  String get videoProfileNoVideo => 'Ancora nessun video';

  @override
  String videoProfileMaxSeconds(int seconds) {
    return 'Max $seconds secondi';
  }

  @override
  String get videoProfileRecord => 'Registra video';

  @override
  String get videoProfileUploadFromGallery => 'Carica dalla galleria';

  @override
  String get videoProfileSave => 'Salva video';

  @override
  String get videoProfileRecordAgain => 'Registra di nuovo';

  @override
  String get videoProfileTipsTitle => 'Consigli per un ottimo video:';

  @override
  String get videoProfileTipLighting =>
      'Buona illuminazione: mettiti di fronte a una finestra o a una fonte di luce';

  @override
  String get videoProfileTipVertical => 'Tieni il telefono in verticale';

  @override
  String get videoProfileTipSmile => 'Sorridi e sii te stesso!';

  @override
  String get videoProfileTipSpeak => 'Parla chiaramente e presentati';

  @override
  String get videoProfileTipHobbies => 'Menziona i tuoi hobby o interessi';

  @override
  String adminVerificationBulkBetterPhotoTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utenti',
      one: '1 utente',
    );
    return 'Richiedi foto migliore ($_temp0)';
  }

  @override
  String adminVerificationBulkApproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verifiche approvate',
      one: '1 verifica approvata',
    );
    return '$_temp0';
  }

  @override
  String adminVerificationBulkBetterPhotoRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foto migliore richiesta a $count utenti',
      one: 'Foto migliore richiesta a 1 utente',
    );
    return '$_temp0';
  }

  @override
  String get adminPreSaleTitle => 'Gestione prevendita';

  @override
  String get adminPreSaleProgramTitle => 'Programma livelli prevendita';

  @override
  String get adminPreSaleProgramDescription =>
      'Gestisci gli utenti in prevendita con conto alla rovescia per livello e durata dell\'abbonamento.';

  @override
  String adminPreSaleCsvFormatHint(String columns, String tiers) {
    return 'Formato CSV: $columns\nValori livello: $tiers';
  }

  @override
  String get adminPreSaleAddSingleEntry => 'Aggiungi singola voce';

  @override
  String get adminPreSaleEntries => 'Voci prevendita';

  @override
  String get adminPreSaleAllTiers => 'Tutti i livelli';

  @override
  String get adminPreSaleNoMatching => 'Nessuna voce corrispondente';

  @override
  String get adminPreSaleEmpty =>
      'Nessuna voce di prevendita.\nCarica un CSV per iniziare.';

  @override
  String adminPreSaleDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String adminPreSaleEntryAdded(String email, String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni',
      one: '1 giorno',
    );
    return '$email aggiunto come $tier ($_temp0)';
  }

  @override
  String get adminPreSaleRemoveEntryTitle => 'Rimuovi voce';

  @override
  String adminPreSaleRemoveEntryConfirm(String email) {
    return 'Rimuovere $email dalla lista di prevendita?';
  }

  @override
  String adminPreSaleEntryRemoved(String email) {
    return '$email rimosso dalla lista di prevendita';
  }

  @override
  String get adminPreSaleCsvEmpty => 'Il file CSV è vuoto';

  @override
  String adminPreSaleCsvMissingHeaders(String expected, String found) {
    return 'Il CSV deve avere le intestazioni: $expected\nTrovate: $found';
  }

  @override
  String get adminPreSaleCsvNoRows => 'Nessuna riga di dati valida nel CSV';

  @override
  String get adminPreSaleInvalidDays => 'Inserisci un numero di giorni valido';

  @override
  String get adminPreSaleInfoTitle => 'Info prevendita';

  @override
  String get adminPreSaleCsvFormatTitle => 'Formato CSV';

  @override
  String get adminPreSaleCountdownDates =>
      'Date del conto alla rovescia per livello';

  @override
  String get adminPreSaleHowItWorks => 'Come funziona';

  @override
  String get adminPreSaleHowItWorksSteps =>
      '1. L\'utente si registra con l\'email\n2. L\'app controlla la lista di prevendita\n3. Il conto alla rovescia mostra la data del livello\n4. Dopo il conto alla rovescia: l\'abbonamento si attiva\n5. Durata = NUMBER_OF_DAYS dalla lista\n6. Abbonamento base = stessa scadenza';

  @override
  String get adminStatusProcessing => 'In elaborazione';

  @override
  String get adminStatusCompleted => 'Completato';

  @override
  String get adminStatusFailed => 'Non riuscito';

  @override
  String get adminStatusCancelled => 'Annullato';

  @override
  String get adminStatusRefunded => 'Rimborsato';

  @override
  String get adminStatusDraft => 'Bozza';

  @override
  String get adminStatusIssued => 'Emessa';

  @override
  String get adminStatusPaid => 'Pagata';

  @override
  String get adminStatusOverdue => 'Scaduta';

  @override
  String get adminOrderTypeCoins => 'Acquisto di monete';

  @override
  String get adminOrderTypeSubscription => 'Abbonamento';

  @override
  String get adminOrderTypeGift => 'Acquisto regalo';

  @override
  String get adminRoleSuperAdmin => 'Super amministratore';

  @override
  String get adminRoleModerator => 'Moderatore';

  @override
  String get adminRoleAnalyst => 'Analista';

  @override
  String get cityPickerTitle => 'Scegli una città';

  @override
  String get cityPickerSearchHint => 'Cerca una città…';

  @override
  String get cityPickerEmptyHint => 'Cerca una città o tocca la mappa';

  @override
  String get cityPickerUseCity => 'Usa questa città';

  @override
  String get notifServerViewedYourProfile => 'ha visto il tuo profilo';

  @override
  String get notifServerStartedFollowingYou => 'ha iniziato a seguirti';

  @override
  String get notifServerStartedFollowingBusiness =>
      'ha iniziato a seguire la tua attività';

  @override
  String get notifServerRatedYourBusiness => 'ha valutato la tua attività';

  @override
  String notifServerRatedYourBusinessStars(int stars) {
    return 'ha valutato la tua attività $stars★';
  }

  @override
  String get notifServerReviewedYourExperience =>
      'ha recensito la tua esperienza';

  @override
  String get notifServerTapToSeeWhoStoppedBy =>
      'Tocca per vedere chi è passato';

  @override
  String get notifServerTapToSeeTheirProfile => 'Tocca per vedere il profilo';

  @override
  String get notifServerNewFollower => 'Hai un nuovo follower';

  @override
  String get notifServerNewRating => 'Hai una nuova valutazione';

  @override
  String get notifServerYourCommunity => 'La tua community';

  @override
  String get notifServerYourEvent => 'Il tuo evento';

  @override
  String get notifServerProfileBoostLive => 'Il boost del tuo profilo è attivo';

  @override
  String get notifServerProfileBoostEnded =>
      'Il boost del tuo profilo è terminato';

  @override
  String get notifServerProfilePromoted =>
      'Il tuo profilo viene mostrato a più persone';

  @override
  String get notifServerEventPromoted =>
      'Il tuo evento è in evidenza in Explore';

  @override
  String get notifServerBoostAgainProfile =>
      'Fai un nuovo boost per raggiungere più persone';

  @override
  String get notifServerBoostAgainEvent =>
      'Fai un nuovo boost per tenerlo in evidenza';

  @override
  String get notifServerCheckedIn => 'Check-in fatto, divertiti!';

  @override
  String get notifServerTicketReady => 'Il tuo biglietto è pronto';

  @override
  String get notifServerTicketSold => 'Biglietto venduto';

  @override
  String get notifServerPaymentToConfirm => 'Pagamento da confermare';

  @override
  String get notifServerPaymentNotConfirmed => 'Pagamento non confermato';

  @override
  String get notifServerPaymentsWaiting =>
      'Pagamenti in attesa della tua conferma';

  @override
  String get notifServerTicketRefunded => 'Biglietto rimborsato';

  @override
  String get notifServerTicketDisputed => 'Pagamento del biglietto contestato';

  @override
  String get notifServerRefundToPayBack => 'Rimborso da restituire';

  @override
  String get notifServerTicketReservationExpired =>
      'Prenotazione del biglietto scaduta';

  @override
  String get notifServerExperienceHidden =>
      'La tua esperienza è stata nascosta dopo diverse segnalazioni';

  @override
  String get notifServerPendingReview => 'In attesa di revisione da GreenGo';

  @override
  String get notifServerMonthlyCoinsAdded => 'Monete mensili aggiunte';

  @override
  String get notifServerSupportReplied =>
      'Il supporto ha risposto al tuo ticket';

  @override
  String get notifServerSupportNewReply =>
      'Hai una nuova risposta dal supporto.';

  @override
  String get notifServerIncognitoExpiring =>
      'La modalità incognito sta per scadere';

  @override
  String get notifServerIncognitoExpiringBody =>
      'La tua modalità incognito scade tra meno di 1 ora!';

  @override
  String get notifServerTravelerExpiring =>
      'La modalità viaggiatore sta per scadere';

  @override
  String get notifServerTravelerExpiringBody =>
      'La tua modalità viaggiatore scade tra meno di 1 ora!';

  @override
  String get notifServerProfileVerified => 'Profilo verificato!';

  @override
  String get notifServerProfileVerifiedBody =>
      'Il tuo profilo è stato verificato! Ora hai il badge di verifica.';

  @override
  String get notifServerNewVerificationPhoto =>
      'Serve una nuova foto di verifica';

  @override
  String get notifServerVerificationUpdate => 'Aggiornamento verifica';

  @override
  String notifServerJoinedYourCommunity(String name) {
    return 'si è unito alla tua community $name';
  }

  @override
  String notifServerJoinedYourEvent(String name) {
    return 'partecipa al tuo evento $name';
  }

  @override
  String notifServerLikedYourEvent(String name) {
    return 'ha messo mi piace al tuo evento $name';
  }

  @override
  String notifServerJoinedYourGroup(String name) {
    return 'si è unito al tuo gruppo $name';
  }

  @override
  String notifServerAddedYouAsCoOwner(String name) {
    return 'ti ha aggiunto come co-proprietario di $name';
  }

  @override
  String notifServerAddedYouToGroup(String name) {
    return 'ti ha aggiunto a $name';
  }

  @override
  String notifServerEventBoostLive(String name) {
    return 'Il boost del tuo evento $name è attivo';
  }

  @override
  String notifServerEventBoostEnded(String name) {
    return 'Il boost del tuo evento $name è terminato';
  }

  @override
  String notifServerTicketScanned(String name) {
    return 'Il tuo biglietto per $name è stato scansionato';
  }

  @override
  String notifServerNewEventIn(String name) {
    return 'Nuovo evento a $name';
  }

  @override
  String notifServerEventCancelledIn(String name) {
    return 'Evento annullato in $name';
  }

  @override
  String notifServerEventUpdatedIn(String name) {
    return 'Evento aggiornato in $name';
  }

  @override
  String notifServerNewEventFrom(String name) {
    return 'Nuovo evento da $name';
  }

  @override
  String notifServerAnnouncement(String name) {
    return 'Annuncio · $name';
  }

  @override
  String get culturalExchangeCategoryFood => 'Cibo';

  @override
  String get culturalExchangeCategoryTransportation => 'Trasporti';

  @override
  String get culturalExchangeCategoryDating => 'Appuntamenti';

  @override
  String get culturalExchangeCategoryCustoms => 'Usanze';

  @override
  String get culturalExchangeCategoryLanguage => 'Lingua';

  @override
  String get culturalExchangeCategorySafety => 'Sicurezza';

  @override
  String get culturalExchangeSectionCuisine => 'Cucina';

  @override
  String get culturalExchangeSectionCustoms => 'Usanze';

  @override
  String get culturalExchangeSectionKeyPhrases => 'Frasi utili';

  @override
  String get culturalExchangeSectionPhrases => 'Frasi';

  @override
  String get culturalExchangeSpotlightBadge => 'IN EVIDENZA';

  @override
  String get culturalExchangeContentComingSoon => 'Contenuti in arrivo';

  @override
  String get culturalExchangeContentComingSoonBody =>
      'Stiamo preparando contenuti dettagliati per questo approfondimento.';

  @override
  String get culturalExchangeLike => 'Mi piace';

  @override
  String culturalExchangeWeeksAgo(int count) {
    return '$count sett fa';
  }

  @override
  String culturalExchangeMonthsAgo(int count) {
    return '$count mesi fa';
  }

  @override
  String get culturalExchangeDailyInsightJapanBow =>
      'In Giappone è consuetudine inchinarsi quando si saluta qualcuno. Più profondo è l\'inchino, più rispetto mostri.';

  @override
  String get culturalExchangeSelectCountry => 'Seleziona un paese';

  @override
  String get culturalExchangeChooseCountry => 'Scegli un paese...';

  @override
  String get culturalExchangeSelectCountryAbove =>
      'Seleziona un paese qui sopra';

  @override
  String get culturalExchangeLearnEtiquette =>
      'Scopri il galateo degli appuntamenti di oltre 20 paesi\nnel mondo';

  @override
  String get culturalExchangeDos => 'Cosa fare';

  @override
  String get culturalExchangeDonts => 'Cosa evitare';

  @override
  String get notifNewConversationTitle => 'Nuova conversazione';

  @override
  String notifNewMessageFrom(String name) {
    return 'Nuovo messaggio da $name';
  }

  @override
  String notifStartedConversation(String name) {
    return '$name ha iniziato una conversazione con te.';
  }

  @override
  String get notifNewPhotoLikeTitle => 'Nuovo mi piace alla foto';

  @override
  String notifLikedYourPhoto(String name) {
    return 'A $name piace la tua foto';
  }

  @override
  String get notifCoinsReceivedTitle => 'Hai ricevuto delle monete!';

  @override
  String chatSystemCoinsReceived(String name, int amount) {
    return '$name ti ha inviato $amount monete!';
  }

  @override
  String chatSystemCoinsSent(int amount) {
    return 'Ti ho appena inviato $amount monete!';
  }

  @override
  String chatSystemSupportWelcome(String subject) {
    return 'Benvenuto nel supporto GreenGo! Un operatore ti risponderà a breve. Il tuo ticket: $subject';
  }

  @override
  String chatSystemSupportAgentJoined(String name) {
    return '$name si è unito alla conversazione e ti aiuterà.';
  }

  @override
  String get chatSystemSupportAgentFallback => 'Operatore di supporto';

  @override
  String get chatSystemSupportInProgress =>
      'Un operatore di supporto sta lavorando alla tua richiesta.';

  @override
  String get chatSystemSupportWaitingOnUser =>
      'Siamo in attesa della tua risposta.';

  @override
  String get chatSystemSupportResolved =>
      'La tua richiesta è stata risolta. Grazie per aver contattato il supporto GreenGo!';

  @override
  String get chatSystemSupportClosed =>
      'Questo ticket di supporto è stato chiuso.';

  @override
  String get chatSystemSupportStatusUpdated => 'Stato del ticket aggiornato.';

  @override
  String get commonUnknownUser => 'Utente sconosciuto';

  @override
  String get chatSupportDescription => 'Descrizione';

  @override
  String get supportReportFollowUpTitle => 'Follow-up della segnalazione';

  @override
  String supportReportFollowUpSubject(String reason) {
    return 'Follow-up della segnalazione: $reason';
  }

  @override
  String supportReportFollowUpDetails(
      String reason, String message, String user, String date) {
    return 'Motivo: $reason\nMessaggio segnalato: «$message»\nUtente segnalato: $user\nSegnalato il: $date';
  }

  @override
  String get supportChatWithGreenGoSubject => 'Chat con il supporto GreenGo';

  @override
  String invoiceLineCoins(int count) {
    return '$count monete GreenGo';
  }

  @override
  String get invoiceLineSubscription => 'Piano di abbonamento';

  @override
  String get invoiceLineGiftPackage => 'Pacchetto di monete regalo';

  @override
  String get srvSomeone => 'Qualcuno';

  @override
  String get srvJoinedYourCommunity => 'si è unito alla tua community';

  @override
  String get srvJoinedYourEvent => 'partecipa al tuo evento';

  @override
  String get srvLikedYourEvent => 'ha messo mi piace al tuo evento';

  @override
  String get srvJoinedYourGroup => 'si è unito al tuo gruppo';

  @override
  String get srvAddedYouToAGroup => 'ti ha aggiunto a un gruppo';

  @override
  String get srvGroup => 'Gruppo';

  @override
  String srvGroupMembersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri hanno lasciato il gruppo',
      one: 'Un membro ha lasciato il gruppo',
    );
    return '$_temp0';
  }

  @override
  String get srvTicketScanned => 'Il tuo biglietto è stato scansionato';

  @override
  String get srvEventBoostLive => 'Il boost del tuo evento è attivo';

  @override
  String get srvEventBoostEnded => 'Il boost del tuo evento è terminato';

  @override
  String get srvAddedYouAsCoOwnerOfEvent =>
      'ti ha aggiunto come co-organizzatore di un evento';

  @override
  String get srvAnEvent => 'Un evento';

  @override
  String srvPaymentsWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamenti',
      one: '1 pagamento',
    );
    return '$_temp0';
  }

  @override
  String get srvNewReview => 'Nuova recensione';

  @override
  String get srvMentionedYouInReviewReply =>
      'ti ha menzionato in una risposta a una recensione';

  @override
  String get srvRepliedToYourReview => 'ha risposto alla tua recensione';

  @override
  String get srvExperience => 'Esperienza';

  @override
  String get srvBookingRequested => 'ha chiesto di prenotare la tua esperienza';

  @override
  String get srvBookingBooked => 'ha prenotato la tua esperienza';

  @override
  String get srvBookingConfirmed => 'Prenotazione confermata';

  @override
  String get srvBookingAccepted =>
      'ha accettato la tua richiesta di prenotazione';

  @override
  String get srvBookingDeclined =>
      'ha rifiutato la tua richiesta di prenotazione';

  @override
  String get srvBookingCancelledTheirs => 'ha annullato la sua prenotazione';

  @override
  String get srvBookingCancelledYours => 'ha annullato la tua prenotazione';

  @override
  String srvBookingRefundOwed(String title, int percent) {
    return '$title — rimborso dovuto: $percent%.';
  }

  @override
  String get srvBookingCheckedIn => 'Check-in effettuato';

  @override
  String get srvBookingCancelledByHost =>
      'La tua prenotazione è stata annullata dall’host';

  @override
  String srvBookingCancelledByHostBody(String title) {
    return '$title — l’orario non è più disponibile. Eventuali pagamenti vengono rimborsati.';
  }

  @override
  String get srvBookingNoShow => 'ti ha segnato come assente';

  @override
  String srvBookingNoShowBody(String title, int hours) {
    return '$title — puoi contestarlo entro $hours h dalla fine.';
  }

  @override
  String get srvBookingGuestSaysPaid => 'dice di aver pagato la prenotazione';

  @override
  String get srvBookingPaymentConfirmed => 'ha confermato il tuo pagamento';

  @override
  String get srvBookingProblemReported =>
      'ha segnalato un problema con la prenotazione';

  @override
  String get srvBookingReportReviewed =>
      'La tua segnalazione è stata esaminata';

  @override
  String get srvBookingHostWarning => 'Avviso su una delle tue prenotazioni';

  @override
  String get srvBookingReportReviewedHost =>
      'Una segnalazione su una prenotazione è stata esaminata';

  @override
  String srvBookingReviewedBody(String title) {
    return '$title.';
  }

  @override
  String srvBookingReviewedRefundBody(String title, int percent) {
    return '$title. Rimborso dovuto: $percent%.';
  }

  @override
  String get srvBookingCancelled => 'La tua prenotazione è stata annullata';

  @override
  String srvBookingNoLongerAvailable(String title) {
    return '$title non è più disponibile.';
  }

  @override
  String get srvBookingComingUp => 'La tua esperienza si avvicina';

  @override
  String get srvBookingHostingSoon => 'Presto sarai l’host';

  @override
  String get srvBookingRequestExpired =>
      'La tua richiesta di prenotazione è scaduta';

  @override
  String srvBookingRequestExpiredBody(String title) {
    return '$title — l’host non ha risposto in tempo.';
  }

  @override
  String get srvBookingHowWasIt => 'Com’è andata la tua esperienza?';

  @override
  String srvBookingReviewIt(String title) {
    return 'Recensisci $title';
  }

  @override
  String get srvBookingReviewGuest => 'Recensisci il tuo ospite';

  @override
  String srvBookingPayLink(String title) {
    return '$title — paga l’host con il suo link di pagamento.';
  }

  @override
  String srvBookingPayOnline(String title) {
    return '$title — paga nell’app per ricevere il biglietto.';
  }

  @override
  String srvBookingPayCash(String title) {
    return '$title — paga l’host in contanti quando vi incontrate.';
  }

  @override
  String get srvHostReviewedYou => 'Il tuo host ti ha recensito';

  @override
  String get srvHostReviewedYouBody =>
      'Recensisci la tua esperienza per vedere cosa ha scritto.';

  @override
  String get srvNewReviewFromHost => 'Hai una nuova recensione da un host';

  @override
  String get srvGuestLeftReview => 'Il tuo ospite ha lasciato una recensione';

  @override
  String get srvGuestLeftReviewBody =>
      'Recensisci il tuo ospite per vedere entrambe le recensioni.';

  @override
  String get srvSupportNewMessageOnTicket =>
      'Nuovo messaggio su un ticket di supporto';

  @override
  String get srvSupportUserSentMessage =>
      'Un utente ha inviato un nuovo messaggio.';

  @override
  String get srvVerificationResubmit => 'Invia una nuova foto di verifica.';

  @override
  String srvVerificationResubmitReason(String reason) {
    return 'Invia una nuova foto di verifica. Motivo: $reason';
  }

  @override
  String get srvVerificationRejected =>
      'La tua verifica non è stata approvata. Riprova.';

  @override
  String srvVerificationRejectedReason(String reason) {
    return 'La tua verifica non è stata approvata. Motivo: $reason';
  }

  @override
  String srvBundleNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuovi messaggi',
      one: '1 nuovo messaggio',
    );
    return '$_temp0';
  }

  @override
  String srvBundleLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A $count persone piace il tuo profilo',
      one: 'A 1 persona piace il tuo profilo',
    );
    return '$_temp0';
  }

  @override
  String srvBundleProfileViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visite al profilo',
      one: '1 visita al profilo',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNewConnections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuovi contatti',
      one: '1 nuovo contatto',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifiche',
      one: '1 notifica',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNamesAndOthers(String names, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'altri $count',
      one: '1 altro',
    );
    return '$names e $_temp0';
  }

  @override
  String srvLevelUpTitle(int level) {
    return 'Livello superiore! Ora sei al livello $level!';
  }

  @override
  String srvLevelUpBody(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: 'Complimenti! Hai guadagnato $coins monete.',
      one: 'Complimenti! Hai guadagnato 1 moneta.',
    );
    return '$_temp0';
  }

  @override
  String srvAchievementUnlockedTitle(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Primo match',
        'social_butterfly': 'Farfalla sociale',
        'popular': 'Popolare',
        'video_enthusiast': 'Appassionato di video',
        'daily_streak_7': 'Serie di 7 giorni',
        'daily_streak_30': 'Serie di 30 giorni',
        'other': 'Nuovo traguardo',
      },
    );
    return 'Traguardo sbloccato: $_temp0!';
  }

  @override
  String srvAchievementDescription(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Crea il tuo primo contatto',
        'social_butterfly': 'Invia 100 messaggi',
        'popular': 'Crea 50 contatti',
        'video_enthusiast': 'Completa 10 videochiamate',
        'daily_streak_7': 'Accedi per 7 giorni di fila',
        'daily_streak_30': 'Accedi per 30 giorni di fila',
        'other': 'Continua così!',
      },
    );
    return '$_temp0';
  }

  @override
  String srvChallengeCompletedTitle(String challenge) {
    String _temp0 = intl.Intl.selectLogic(
      challenge,
      {
        'send_5_messages': 'Attacca bottone',
        'get_3_matches': 'Combinatore',
        'complete_profile': 'Profilo perfetto',
        'video_call_1': 'Faccia a faccia',
        'other': 'Sfida del giorno',
      },
    );
    return 'Sfida completata: $_temp0!';
  }

  @override
  String srvChallengeRewardsBody(int xp, int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coins monete',
      one: '1 moneta',
    );
    return 'Riscatta i tuoi premi: $xp XP e $_temp0';
  }

  @override
  String srvSentYouCoins(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'ti ha inviato $amount monete',
      one: 'ti ha inviato 1 moneta',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyFree(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'Questo mese hai ricevuto $amount monete con la tua iscrizione gratuita.',
      one: 'Questo mese hai ricevuto 1 moneta con la tua iscrizione gratuita.',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyTier(int amount, String tier) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'Questo mese hai ricevuto $amount monete con la tua iscrizione $tier.',
      one: 'Questo mese hai ricevuto 1 moneta con la tua iscrizione $tier.',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiringTitle => 'L’iscrizione scade a breve';

  @override
  String srvMembershipExpiringBody(String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'La tua iscrizione $tier scade tra $days giorni. Rinnova ora per mantenere le funzioni premium!',
      one:
          'La tua iscrizione $tier scade tra 1 giorno. Rinnova ora per mantenere le funzioni premium!',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiredTitle => 'Iscrizione scaduta';

  @override
  String get srvMembershipExpiredBody =>
      'La tua iscrizione è scaduta. Acquistane una nuova per riattivare le funzioni premium.';

  @override
  String get srvSubscriptionCancelledTitle => 'Abbonamento annullato';

  @override
  String get srvSubscriptionEndedBody =>
      'La tua iscrizione è terminata. Puoi riabbonarti quando vuoi dallo Shop.';

  @override
  String get srvPaymentFailedTitle => 'Pagamento non riuscito';

  @override
  String get srvSubscriptionPaymentFailedBody =>
      'Il pagamento dell’abbonamento non è riuscito. Aggiorna il metodo di pagamento per mantenere attiva l’iscrizione.';

  @override
  String get srvGiftFromGreenGo => 'Un regalo da GreenGo';

  @override
  String get srvAccountNotApprovedTitle => 'Account non approvato';

  @override
  String srvAccountNotApprovedReason(String reason) {
    return 'Non è stato possibile approvare il tuo account. Motivo: $reason';
  }

  @override
  String get srvAccountNotApprovedContactSupport =>
      'Non è stato possibile approvare il tuo account. Contatta il supporto.';

  @override
  String get srvEvent => 'Evento';

  @override
  String get srvNewEvent => 'Nuovo evento';

  @override
  String get srvEventStartingNow => 'sta iniziando, divertiti!';

  @override
  String get srvEventStartsIn6h => 'inizia tra circa 6 ore';

  @override
  String get srvEventIsTomorrow => 'è domani, ci vediamo lì!';

  @override
  String get srvNewEventInYourCommunity => 'Nuovo evento nella tua community';

  @override
  String get srvEventCancelledInYourCommunity =>
      'Evento annullato nella tua community';

  @override
  String get srvEventUpdatedInYourCommunity =>
      'Evento aggiornato nella tua community';

  @override
  String srvEventHasBeenCancelled(String event) {
    return '«$event» è stato annullato';
  }

  @override
  String srvEventNewTime(String event) {
    return 'Nuovo orario per «$event»';
  }

  @override
  String srvEventNewLocation(String event) {
    return 'Nuovo luogo per «$event»';
  }

  @override
  String srvAnnouncementTitle(String name) {
    return '📣 $name';
  }

  @override
  String get srvAnnouncementACommunity => '📣 Una community';

  @override
  String get srvAnnouncementAnEvent => '📣 Annuncio dell’evento';

  @override
  String get srvReportReviewedTitle => 'La tua segnalazione è stata esaminata';

  @override
  String get srvReportReviewedActionTaken =>
      'Grazie per la segnalazione. Il nostro team l\'ha esaminata e ha preso provvedimenti secondo le Linee guida della community.';

  @override
  String get srvReportReviewedNoViolation =>
      'Grazie per la segnalazione. Il nostro team l\'ha esaminata e non ha riscontrato violazioni delle Linee guida della community.';

  @override
  String get srvModerationDecisionTitle =>
      'Una decisione di moderazione sul tuo account';

  @override
  String get srvModerationDecisionBody =>
      'Abbiamo preso provvedimenti secondo le Linee guida della community. Tocca per leggere i motivi e come presentare ricorso.';

  @override
  String get srvNewMessage => 'Nuovo messaggio';

  @override
  String get srvGroupCreated => 'Gruppo creato';

  @override
  String get srvYouWereAddedToGroup => 'Sei stato aggiunto al gruppo';

  @override
  String srvGroupMembersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Si sono uniti $count nuovi membri',
      one: 'Si è unito un nuovo membro',
    );
    return '$_temp0';
  }

  @override
  String get srvUnknownUser => 'Utente sconosciuto';

  @override
  String srvCoinsReceivedBody(String name, int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount monete',
      one: '1 moneta',
    );
    return '$name ti ha inviato $_temp0!';
  }

  @override
  String get srvNewEventFromFollowedBusiness =>
      'Nuovo evento da un’attività che segui';

  @override
  String get srvMessageRemovedByModerator =>
      'Questo messaggio è stato rimosso da un moderatore';

  @override
  String get srvSupportAiHandoff =>
      'Capisco che vuoi parlare con una persona. Ti sto mettendo in contatto. Un membro del team di supporto ti risponderà a breve.';

  @override
  String get becomeBusinessOneWayHint =>
      'Richiede Platinum. Upgrade una tantum: non può essere annullato.';

  @override
  String get businessPermanentInfo =>
      'Il tuo account è definitivamente un account aziendale e non può tornare personale. Gli strumenti aziendali funzionano finché Platinum è attivo; se scade, vengono sospesi fino al rinnovo.';

  @override
  String get paidBusinessOnlyNote =>
      'I biglietti a pagamento sono disponibili per gli account aziendali.';

  @override
  String get paidBusinessOnlyBody =>
      'Eventi ed esperienze gratuiti sono aperti a tutti. Per far pagare biglietti o prenotazioni ti serve un account aziendale attivo (Platinum).';

  @override
  String get paidBusinessPausedNote =>
      'La tua attività è sospesa: rinnova Platinum per vendere di nuovo biglietti a pagamento.';

  @override
  String get uexpBusinessRequiredTitle =>
      'Gli annunci a pagamento sono per gli account aziendali';

  @override
  String get tpErrSellerNotBusiness =>
      'Le vendite sono sospese: biglietti e prenotazioni a pagamento sono disponibili solo da account aziendali attivi.';

  @override
  String get tpAutoSectionTitle => 'Pagamento e approvazione automatici';

  @override
  String get tpAutoSectionHint =>
      'Collega Stripe o Mercado Pago: gli acquirenti pagano nell’app e i biglietti vengono confermati subito, senza controlli manuali.';

  @override
  String get tpManualSectionTitle => 'Pagamento e approvazione manuali';

  @override
  String get tpManualSectionHint =>
      'Nessuna configurazione: gli acquirenti ti pagano direttamente con uno dei metodi di pagamento qui sotto (o contanti / bonifico). Confermi tu ogni pagamento con il pulsante Pagamenti da confermare in alto; il biglietto viene emesso quando confermi.';

  @override
  String get paymentMethodsSettingsSubtitle =>
      'Come possono pagarti direttamente (Pix, PayPal…)';

  @override
  String get communitiesBusinessCannotJoin =>
      'Gli account business non possono unirsi alle community. Disattiva la modalita business per unirti.';

  @override
  String get becomeBusinessPermanentHint =>
      'Aggiornamento una tantum. Non può essere annullato.';

  @override
  String get storefrontEnabled => 'Vetrina attiva';

  @override
  String get storefrontDisabled => 'Vetrina disattivata';

  @override
  String get storefrontToggleHint =>
      'Attiva o disattiva la tua vetrina quando vuoi';

  @override
  String get tpGetPaidManualInfo =>
      'Nessuna configurazione: scegli uno dei tuoi metodi di pagamento del profilo (o contanti / bonifico) nell\'evento o esperienza e conferma tu ogni pagamento.';

  @override
  String emailTicketSubject(String title) {
    return 'Il tuo biglietto per $title';
  }

  @override
  String get emailTicketIntro =>
      'La tua prenotazione è confermata. Mostra il codice QR all’ingresso: ogni codice vale per un solo ingresso.';

  @override
  String get emailTicketWhen => 'Quando';

  @override
  String get emailTicketWhere => 'Dove';

  @override
  String get emailTicketTypeLabel => 'Tipo di biglietto';

  @override
  String get emailTicketPartySizeLabel => 'Numero di persone';

  @override
  String get emailTicketCodeLabel => 'Codice di prenotazione';

  @override
  String emailTicketQrCaption(int index, int count) {
    return 'Biglietto $index di $count';
  }

  @override
  String get emailTicketFooter =>
      'Trovi i tuoi biglietti anche nell’app GreenGo. Non condividere questi codici QR.';

  @override
  String emailParticipantsSubject(String title) {
    return 'Elenco partecipanti: $title';
  }

  @override
  String emailParticipantsIntro(String title, String when, int count) {
    return 'In allegato trovi l’elenco dei partecipanti di $title ($when). Partecipanti: $count.';
  }

  @override
  String get emailParticipantsPrivacy =>
      'Questo file contiene dati personali condivisi solo per l’ingresso. Non condividerlo ed eliminalo dopo l’evento.';

  @override
  String get csvColName => 'Nome';

  @override
  String get csvColEmail => 'Email';

  @override
  String get csvColBookingCode => 'Codice di prenotazione';

  @override
  String get csvColTicket => 'Tipo di biglietto / persone';

  @override
  String get csvColStatus => 'Stato';

  @override
  String get csvStatusPaid => 'pagato';

  @override
  String get csvStatusConfirmed => 'confermato';

  @override
  String get csvStatusCheckedIn => 'check-in fatto';

  @override
  String get participantsEmailButton => 'Inviami l’elenco dei partecipanti';

  @override
  String get participantsEmailSent =>
      'Elenco dei partecipanti inviato all’email del tuo account';

  @override
  String get participantsEmailRateLimited =>
      'L’hai appena richiesto. Riprova tra qualche minuto.';

  @override
  String get participantsEmailFailed =>
      'Impossibile inviare l’elenco dei partecipanti. Riprova più tardi.';

  @override
  String get participantsEmailNoEmail =>
      'Il tuo account non ha un indirizzo email a cui inviare l’elenco.';

  @override
  String get checkoutOrganizerShareNotice =>
      'Il tuo nome e la tua email saranno condivisi con l’organizzatore per l’ingresso.';

  @override
  String get openSourceLicensesTitle => 'Licenze open source';

  @override
  String get openSourceLicensesSubtitle =>
      'Font e componenti software usati in questa app';
}
