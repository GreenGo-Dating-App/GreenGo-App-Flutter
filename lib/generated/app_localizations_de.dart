// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get abandonGame => 'Spiel Verlassen';

  @override
  String get about => 'Über';

  @override
  String get aboutMe => 'Über Mich';

  @override
  String get aboutMeTitle => 'Über mich';

  @override
  String get academicCategory => 'Akademisch';

  @override
  String get acceptPrivacyPolicy =>
      'Ich habe die Datenschutzerklärung gelesen und akzeptiere sie';

  @override
  String get acceptProfiling =>
      'Ich stimme der Profilerstellung für personalisierte Empfehlungen zu';

  @override
  String get acceptTermsAndConditions =>
      'Ich habe die Allgemeinen Geschäftsbedingungen gelesen und akzeptiere sie';

  @override
  String get acceptThirdPartyData =>
      'Ich stimme der Weitergabe meiner Daten an Dritte zu';

  @override
  String get accessGranted => 'Zugang gewährt!';

  @override
  String accessGrantedBody(Object tierName) {
    return 'GreenGo ist jetzt aktiv! Als $tierName hast du vollen Zugang zu allen Funktionen.';
  }

  @override
  String get accountApproved => 'Konto Genehmigt';

  @override
  String get accountApprovedBody =>
      'Dein GreenGo-Konto wurde genehmigt. Willkommen in der Community!';

  @override
  String get accountCreatedSuccess =>
      'Konto erstellt! Bitte überprüfen Sie Ihre E-Mail, um Ihr Konto zu verifizieren.';

  @override
  String get accountPendingApproval => 'Konto wartet auf Genehmigung';

  @override
  String get accountRejected => 'Konto Abgelehnt';

  @override
  String get accountSettings => 'Kontoeinstellungen';

  @override
  String get accountUnderReview => 'Konto wird Überprüft';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Erfolge';

  @override
  String get achievementsSubtitle => 'Abzeichen und Fortschritt ansehen';

  @override
  String get achievementsTitle => 'Erfolge';

  @override
  String get addBio => 'Biografie hinzufügen';

  @override
  String get addDealBreakerTitle => 'Ausschlusskriterium hinzufuegen';

  @override
  String get addPhoto => 'Foto Hinzufügen';

  @override
  String get adjustPreferences => 'Präferenzen anpassen';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Code gesendet an $email';
  }

  @override
  String get admin2faExpired =>
      'Code abgelaufen. Bitte fordern Sie einen neuen an.';

  @override
  String get admin2faInvalidCode => 'Ungültiger Verifizierungscode';

  @override
  String get admin2faMaxAttempts =>
      'Zu viele Versuche. Bitte fordern Sie einen neuen Code an.';

  @override
  String get admin2faResend => 'Code erneut senden';

  @override
  String admin2faResendIn(String seconds) {
    return 'Erneut senden in ${seconds}s';
  }

  @override
  String get admin2faSending => 'Code wird gesendet...';

  @override
  String get admin2faSignOut => 'Abmelden';

  @override
  String get admin2faSubtitle =>
      'Geben Sie den 6-stelligen Code ein, der an Ihre E-Mail gesendet wurde';

  @override
  String get admin2faTitle => 'Admin-Verifizierung';

  @override
  String get admin2faVerify => 'Verifizieren';

  @override
  String get adminAccessDates => 'Zugangsdaten:';

  @override
  String get adminAccountLockedSuccessfully => 'Konto erfolgreich gesperrt';

  @override
  String get adminAccountUnlockedSuccessfully => 'Konto erfolgreich entsperrt';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Admin-Konten können nicht gelöscht werden';

  @override
  String adminAchievementCount(Object count) {
    return '$count Erfolge';
  }

  @override
  String get adminAchievementUpdated => 'Erfolg aktualisiert';

  @override
  String get adminAchievements => 'Erfolge';

  @override
  String get adminAchievementsSubtitle => 'Erfolge und Abzeichen verwalten';

  @override
  String get adminActive => 'AKTIV';

  @override
  String adminActiveCount(Object count) {
    return 'Aktiv ($count)';
  }

  @override
  String get adminActiveEvent => 'Aktives Event';

  @override
  String get adminActiveUsers => 'Aktive Nutzer';

  @override
  String get adminAdd => 'Hinzufügen';

  @override
  String get adminAddCoins => 'Münzen hinzufügen';

  @override
  String get adminAddPackage => 'Paket hinzufügen';

  @override
  String get adminAddResolutionNote => 'Lösungsnotiz hinzufügen...';

  @override
  String get adminAddSingleEmail => 'Einzelne E-Mail hinzufügen';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return '$amount Münzen dem Nutzer hinzugefügt';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Hinzugefügt $date';
  }

  @override
  String get adminAdvancedFilters => 'Erweiterte Filter';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age Jahre alt - $gender';
  }

  @override
  String get adminAll => 'Alle';

  @override
  String get adminAllReports => 'Alle Meldungen';

  @override
  String get adminAmount => 'Betrag';

  @override
  String get adminAnalyticsAndReports => 'Analysen & Berichte';

  @override
  String get adminAppSettings => 'App-Einstellungen';

  @override
  String get adminAppSettingsSubtitle => 'Allgemeine App-Einstellungen';

  @override
  String get adminApproveSelected => 'Ausgewählte genehmigen';

  @override
  String get adminAssignToMe => 'Mir zuweisen';

  @override
  String get adminAssigned => 'Zugewiesen';

  @override
  String get adminAvailable => 'Verfügbar';

  @override
  String get adminBadge => 'Abzeichen';

  @override
  String get adminBaseCoins => 'Basis-Münzen';

  @override
  String get adminBaseXp => 'Basis-XP';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount Bonusmünzen';
  }

  @override
  String get adminBonusCoinsLabel => 'Bonusmünzen';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes Bonus';
  }

  @override
  String get adminBrowseProfilesAnonymously => 'Profile anonym durchsuchen';

  @override
  String get adminCanSendMedia => 'Kann Medien senden';

  @override
  String adminChallengeCount(Object count) {
    return '$count Herausforderungen';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'Herausforderungserstellung demnächst verfügbar.';

  @override
  String get adminChallenges => 'Herausforderungen';

  @override
  String get adminChangesSaved => 'Änderungen gespeichert';

  @override
  String get adminChatWithReporter => 'Chat mit Melder';

  @override
  String get adminClear => 'Löschen';

  @override
  String get adminClosed => 'Geschlossen';

  @override
  String get adminCoinAmount => 'Münzanzahl';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount Münzen';
  }

  @override
  String get adminCoinCost => 'Münzkosten';

  @override
  String get adminCoinManagement => 'Münzverwaltung';

  @override
  String get adminCoinManagementSubtitle =>
      'Münzpakete und Nutzerguthaben verwalten';

  @override
  String get adminCoinPackages => 'Münzpakete';

  @override
  String get adminCoinReward => 'Münzbelohnung';

  @override
  String adminComingSoon(Object route) {
    return '$route demnächst verfügbar';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Konfigurationen auf Standard zurückgesetzt. Speichern zum Übernehmen.';

  @override
  String get adminConfigureLimitsAndFeatures =>
      'Limits und Funktionen konfigurieren';

  @override
  String get adminConfigureMilestoneRewards =>
      'Meilensteinbelohnungen für aufeinanderfolgende Anmeldungen konfigurieren';

  @override
  String get adminCreateChallenge => 'Herausforderung erstellen';

  @override
  String get adminCreateEvent => 'Event erstellen';

  @override
  String get adminCreateNewChallenge => 'Neue Herausforderung erstellen';

  @override
  String get adminCreateSeasonalEvent => 'Saisonales Event erstellen';

  @override
  String get adminCsvFormat => 'CSV-Format:';

  @override
  String get adminCsvFormatDescription =>
      'Eine E-Mail pro Zeile oder kommagetrennte Werte. Anführungszeichen werden automatisch entfernt. Ungültige E-Mails werden übersprungen.';

  @override
  String get adminCurrentBalance => 'Aktuelles Guthaben';

  @override
  String get adminDailyChallenges => 'Tägliche Herausforderungen';

  @override
  String get adminDailyChallengesSubtitle =>
      'Tägliche Herausforderungen und Belohnungen konfigurieren';

  @override
  String get adminDailyLimits => 'Tägliche Limits';

  @override
  String get adminDailyLoginRewards => 'Tägliche Anmeldebelohnungen';

  @override
  String get adminDailyMessages => 'Tägliche Nachrichten';

  @override
  String get adminDailySuperLikes => 'Tägliche Prioritätsverbindungen';

  @override
  String get adminDailySwipes => 'Tägliche Swipes';

  @override
  String get adminDashboard => 'Admin-Dashboard';

  @override
  String get adminDate => 'Datum';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return 'Möchtest du das Paket \"$amount Münzen\" wirklich löschen?';
  }

  @override
  String get adminDeletePackageTitle => 'Paket löschen?';

  @override
  String get adminDescription => 'Beschreibung';

  @override
  String get adminDeselectAll => 'Alle abwählen';

  @override
  String get adminDisabled => 'Deaktiviert';

  @override
  String get adminDismiss => 'Verwerfen';

  @override
  String get adminDismissReport => 'Meldung verwerfen';

  @override
  String get adminDismissReportConfirm =>
      'Möchtest du diese Meldung wirklich verwerfen?';

  @override
  String get adminEarlyAccessDate => '14. März 2026';

  @override
  String get adminEarlyAccessDates =>
      'Nutzer auf dieser Liste erhalten Zugang am 14. März 2026.\nAlle anderen Nutzer erhalten Zugang am 14. April 2026.';

  @override
  String get adminEarlyAccessInList => 'Frühzugang (in der Liste)';

  @override
  String get adminEarlyAccessInfo => 'Frühzugang-Info';

  @override
  String get adminEarlyAccessList => 'Frühzugangsliste';

  @override
  String get adminEarlyAccessProgram => 'Frühzugangsprogramm';

  @override
  String get adminEditAchievement => 'Erfolg bearbeiten';

  @override
  String adminEditItem(Object name) {
    return '$name bearbeiten';
  }

  @override
  String adminEditMilestone(Object name) {
    return '$name bearbeiten';
  }

  @override
  String get adminEditPackage => 'Paket bearbeiten';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email zur Frühzugangsliste hinzugefügt';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count E-Mails';
  }

  @override
  String get adminEmailList => 'E-Mail-Liste';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email von der Frühzugangsliste entfernt';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Erweiterte Filteroptionen aktivieren';

  @override
  String get adminEngagementReports => 'Engagement-Berichte';

  @override
  String get adminEngagementReportsSubtitle =>
      'Matching- und Nachrichtenstatistiken anzeigen';

  @override
  String get adminEnterEmailAddress => 'E-Mail-Adresse eingeben';

  @override
  String get adminEnterValidAmount => 'Bitte gültigen Betrag eingeben';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Bitte gültige Münzanzahl und Preis eingeben';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Fehler beim Hinzufügen der E-Mail: $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Fehler beim Laden des Kontexts: $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Fehler beim Laden der Daten: $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Fehler beim Öffnen des Chats: $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Fehler beim Entfernen der E-Mail: $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Fehler: $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Fehler beim Hochladen der Datei: $error';
  }

  @override
  String get adminErrors => 'Fehler:';

  @override
  String get adminEventCreationComingSoon =>
      'Event-Erstellung demnächst verfügbar.';

  @override
  String get adminEvents => 'Events';

  @override
  String adminFailedToSave(Object error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get adminFeatures => 'Funktionen';

  @override
  String get adminFilterByInterests => 'Nach Interessen filtern';

  @override
  String get adminFilterBySpecificLocation =>
      'Nach bestimmtem Standort filtern';

  @override
  String get adminFilterBySpokenLanguages =>
      'Nach gesprochenen Sprachen filtern';

  @override
  String get adminFilterByVerificationStatus =>
      'Nach Verifizierungsstatus filtern';

  @override
  String get adminFilterOptions => 'Filteroptionen';

  @override
  String get adminGamification => 'Gamifizierung';

  @override
  String get adminGamificationAndRewards => 'Gamifizierung & Belohnungen';

  @override
  String get adminGeneralAccess => 'Allgemeiner Zugang';

  @override
  String get adminGeneralAccessDate => '14. April 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Höhere Priorität = wird zuerst in der Suche angezeigt';

  @override
  String get adminImportResult => 'Import-Ergebnis';

  @override
  String get adminInProgress => 'In Bearbeitung';

  @override
  String get adminIncognitoMode => 'Inkognito-Modus';

  @override
  String get adminInterestFilter => 'Interessenfilter';

  @override
  String get adminInvoices => 'Rechnungen';

  @override
  String get adminLanguageFilter => 'Sprachfilter';

  @override
  String get adminLoading => 'Laden...';

  @override
  String get adminLocationFilter => 'Standortfilter';

  @override
  String get adminLockAccount => 'Konto sperren';

  @override
  String adminLockAccountConfirm(Object userId) {
    return 'Konto für Nutzer $userId sperren...?';
  }

  @override
  String get adminLockDuration => 'Sperrdauer';

  @override
  String adminLockReasonLabel(Object reason) {
    return 'Grund: $reason';
  }

  @override
  String adminLockedCount(Object count) {
    return 'Gesperrt ($count)';
  }

  @override
  String adminLockedDate(Object date) {
    return 'Gesperrt: $date';
  }

  @override
  String get adminLoginStreakSystem => 'Anmeldeserien-System';

  @override
  String get adminLoginStreaks => 'Anmeldeserien';

  @override
  String get adminLoginStreaksSubtitle =>
      'Serien-Meilensteine und Belohnungen konfigurieren';

  @override
  String get adminManageAppSettings =>
      'Verwalte deine GreenGo App-Einstellungen';

  @override
  String get adminMatchPriority => 'Match-Priorität';

  @override
  String get adminMatchingAndVisibility => 'Matching & Sichtbarkeit';

  @override
  String get adminMessageContext => 'Nachrichtenkontext (50 davor/danach)';

  @override
  String get adminMilestoneUpdated => 'Meilenstein aktualisiert';

  @override
  String adminMoreErrors(Object count) {
    return '... und $count weitere Fehler';
  }

  @override
  String get adminName => 'Name';

  @override
  String get adminNinetyDays => '90 Tage';

  @override
  String get adminNoEmailsInEarlyAccessList =>
      'Keine E-Mails in der Frühzugangsliste';

  @override
  String get adminNoInvoicesFound => 'Keine Rechnungen gefunden';

  @override
  String get adminNoLockedAccounts => 'Keine gesperrten Konten';

  @override
  String get adminNoMatchingEmailsFound => 'Keine passenden E-Mails gefunden';

  @override
  String get adminNoOrdersFound => 'Keine Bestellungen gefunden';

  @override
  String get adminNoPendingReports => 'Keine ausstehenden Meldungen';

  @override
  String get adminNoReportsYet => 'Noch keine Meldungen';

  @override
  String adminNoTickets(Object status) {
    return 'Keine $status Tickets';
  }

  @override
  String get adminNoValidEmailsFound =>
      'Keine gültigen E-Mail-Adressen in der Datei gefunden';

  @override
  String get adminNoVerificationHistory => 'Kein Verifizierungsverlauf';

  @override
  String get adminOneDay => '1 Tag';

  @override
  String get adminOpen => 'Offen';

  @override
  String adminOpenCount(Object count) {
    return 'Offen ($count)';
  }

  @override
  String get adminOpenTickets => 'Offene Tickets';

  @override
  String get adminOrderDetails => 'Bestelldetails';

  @override
  String get adminOrderId => 'Bestell-ID';

  @override
  String get adminOrderRefunded => 'Bestellung erstattet';

  @override
  String get adminOrders => 'Bestellungen';

  @override
  String get adminPackages => 'Pakete';

  @override
  String get adminPanel => 'Admin-Bereich';

  @override
  String get adminPayment => 'Zahlung';

  @override
  String get adminPending => 'Ausstehend';

  @override
  String adminPendingCount(Object count) {
    return 'Ausstehend ($count)';
  }

  @override
  String get adminPermanent => 'Dauerhaft';

  @override
  String get adminPleaseEnterValidEmail =>
      'Bitte gültige E-Mail-Adresse eingeben';

  @override
  String get adminPriceUsd => 'Preis (USD)';

  @override
  String get adminProductIdIap => 'Produkt-ID (für IAP)';

  @override
  String get adminProfileVisitors => 'Profilbesucher';

  @override
  String get adminPromotional => 'Werbeangebot';

  @override
  String get adminPromotionalPackage => 'Werbepaket';

  @override
  String get adminPromotions => 'Werbeaktionen';

  @override
  String get adminPromotionsSubtitle =>
      'Sonderangebote und Werbeaktionen verwalten';

  @override
  String get adminProvideReason => 'Bitte einen Grund angeben';

  @override
  String get adminReadReceipts => 'Lesebestätigungen';

  @override
  String get adminReason => 'Grund';

  @override
  String adminReasonLabel(Object reason) {
    return 'Grund: $reason';
  }

  @override
  String get adminReasonRequired => 'Grund (erforderlich)';

  @override
  String get adminRefund => 'Erstattung';

  @override
  String get adminRemove => 'Entfernen';

  @override
  String get adminRemoveCoins => 'Münzen entfernen';

  @override
  String get adminRemoveEmail => 'E-Mail entfernen';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return 'Möchtest du \"$email\" wirklich von der Frühzugangsliste entfernen?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return '$amount Münzen vom Nutzer entfernt';
  }

  @override
  String get adminReportDismissed => 'Meldung verworfen';

  @override
  String get adminReportFollowupStarted =>
      'Nachverfolgungsgespräch zur Meldung gestartet';

  @override
  String get adminReportedMessage => 'Gemeldete Nachricht:';

  @override
  String get adminReportedMessageMarker => '^ GEMELDETE NACHRICHT';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'Gemeldeter Nutzer-ID: $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'Melder-ID: $reporterId...';
  }

  @override
  String get adminReports => 'Meldungen';

  @override
  String get adminReportsManagement => 'Meldungsverwaltung';

  @override
  String get adminRequestNewPhoto => 'Neues Foto anfordern';

  @override
  String get adminRequiredCount => 'Erforderliche Anzahl';

  @override
  String adminRequiresCount(Object count) {
    return 'Erfordert: $count';
  }

  @override
  String get adminReset => 'Zurücksetzen';

  @override
  String get adminResetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get adminResetToDefaultsConfirm =>
      'Dadurch werden alle Tier-Konfigurationen auf ihre Standardwerte zurückgesetzt. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get adminResetToDefaultsTitle => 'Auf Standard zurücksetzen?';

  @override
  String get adminResolutionNote => 'Lösungsnotiz';

  @override
  String get adminResolve => 'Lösen';

  @override
  String get adminResolved => 'Gelöst';

  @override
  String adminResolvedCount(Object count) {
    return 'Gelöst ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Umsatzanalysen';

  @override
  String get adminRevenueAnalyticsSubtitle => 'Käufe und Umsätze verfolgen';

  @override
  String get adminReviewedBy => 'Überprüft von';

  @override
  String get adminRewardAmount => 'Belohnungsbetrag';

  @override
  String get adminSaving => 'Speichern...';

  @override
  String get adminScheduledEvents => 'Geplante Events';

  @override
  String get adminSearchByUserIdOrEmail => 'Nach Nutzer-ID oder E-Mail suchen';

  @override
  String get adminSearchEmails => 'E-Mails suchen...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Nutzer suchen, um Münzguthaben zu verwalten';

  @override
  String get adminSearchOrders => 'Bestellungen suchen...';

  @override
  String get adminSeeWhenMessagesAreRead =>
      'Sehen, wann Nachrichten gelesen wurden';

  @override
  String get adminSeeWhoVisitedProfile => 'Sehen, wer das Profil besucht hat';

  @override
  String get adminSelectAll => 'Alle auswählen';

  @override
  String get adminSelectCsvFile => 'CSV-Datei auswählen';

  @override
  String adminSelectedCount(Object count) {
    return '$count ausgewählt';
  }

  @override
  String get adminSendImagesAndVideosInChat =>
      'Bilder und Videos im Chat senden';

  @override
  String get adminSevenDays => '7 Tage';

  @override
  String get adminSpendItems => 'Ausgabenartikel';

  @override
  String get adminStatistics => 'Statistiken';

  @override
  String get adminStatus => 'Status';

  @override
  String get adminStreakMilestones => 'Serien-Meilensteine';

  @override
  String get adminStreakMultiplier => 'Serien-Multiplikator';

  @override
  String get adminStreakMultiplierValue => '1,5x pro Tag';

  @override
  String get adminStreaks => 'Serien';

  @override
  String get adminSupport => 'Support';

  @override
  String get adminSupportAgents => 'Support-Mitarbeiter';

  @override
  String get adminSupportAgentsSubtitle =>
      'Support-Mitarbeiterkonten verwalten';

  @override
  String get adminSupportManagement => 'Support-Verwaltung';

  @override
  String get adminSupportRequest => 'Supportanfrage';

  @override
  String get adminSupportTickets => 'Support-Tickets';

  @override
  String get adminSupportTicketsSubtitle =>
      'Support-Gespräche der Nutzer anzeigen und verwalten';

  @override
  String get adminSystemConfiguration => 'Systemkonfiguration';

  @override
  String get adminThirtyDays => '30 Tage';

  @override
  String get adminTicketAssignedToYou => 'Ticket dir zugewiesen';

  @override
  String get adminTicketAssignment => 'Ticketzuweisung';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Tickets den Support-Mitarbeitern zuweisen';

  @override
  String get adminTicketClosed => 'Ticket geschlossen';

  @override
  String get adminTicketResolved => 'Ticket gelöst';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Tier-Konfigurationen erfolgreich gespeichert';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Tier-Verwaltung';

  @override
  String get adminTierManagementSubtitle =>
      'Tier-Limits und Funktionen konfigurieren';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Heute';

  @override
  String get adminTotalMinutes => 'Gesamtminuten';

  @override
  String get adminType => 'Typ';

  @override
  String get adminUnassigned => 'Nicht zugewiesen';

  @override
  String get adminUnknown => 'Unbekannt';

  @override
  String get adminUnlimited => 'Unbegrenzt';

  @override
  String get adminUnlock => 'Entsperren';

  @override
  String get adminUnlockAccount => 'Konto entsperren';

  @override
  String get adminUnlockAccountConfirm =>
      'Möchtest du dieses Konto wirklich entsperren?';

  @override
  String get adminUnresolved => 'Ungelöst';

  @override
  String get adminUploadCsvDescription =>
      'CSV-Datei mit E-Mail-Adressen hochladen (eine pro Zeile oder kommagetrennt)';

  @override
  String get adminUploadCsvFile => 'CSV-Datei hochladen';

  @override
  String get adminUploading => 'Hochladen...';

  @override
  String get adminUseVideoCallingFeature => 'Videoanruf-Funktion nutzen';

  @override
  String get adminUsedMinutes => 'Verbrauchte Minuten';

  @override
  String get adminUser => 'Nutzer';

  @override
  String get adminUserAnalytics => 'Nutzeranalysen';

  @override
  String get adminUserAnalyticsSubtitle =>
      'Nutzerengagement und Wachstumsmetriken anzeigen';

  @override
  String get adminUserBalance => 'Nutzerguthaben';

  @override
  String get adminUserId => 'Nutzer-ID';

  @override
  String adminUserIdLabel(Object userId) {
    return 'Nutzer-ID: $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'Nutzer: $userId...';
  }

  @override
  String get adminUserManagement => 'Nutzerverwaltung';

  @override
  String get adminUserModeration => 'Nutzermoderation';

  @override
  String get adminUserModerationSubtitle =>
      'Nutzersperren und -suspendierungen verwalten';

  @override
  String get adminUserReports => 'Nutzermeldungen';

  @override
  String get adminUserReportsSubtitle =>
      'Nutzermeldungen überprüfen und bearbeiten';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'Nutzer: $senderId...';
  }

  @override
  String get adminUserVerifications => 'Nutzerverifizierungen';

  @override
  String get adminUserVerificationsSubtitle =>
      'Verifizierungsanfragen genehmigen oder ablehnen';

  @override
  String get adminVerificationFilter => 'Verifizierungsfilter';

  @override
  String get adminVerifications => 'Verifizierungen';

  @override
  String get adminVideoChat => 'Videochat';

  @override
  String get adminVideoCoinPackages => 'Video-Münzpakete';

  @override
  String get adminVideoCoins => 'Videomünzen';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes Minuten';
  }

  @override
  String get adminViewContext => 'Kontext anzeigen';

  @override
  String get adminViewDocument => 'Dokument anzeigen';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Verstoß gegen Community-Richtlinien';

  @override
  String get adminWaiting => 'Wartend';

  @override
  String adminWaitingCount(Object count) {
    return 'Wartend ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Wöchentliche Herausforderungen';

  @override
  String get adminWelcome => 'Willkommen, Admin';

  @override
  String get adminXpReward => 'XP-Belohnung';

  @override
  String get ageRange => 'Altersbereich';

  @override
  String get aiCoachBenefitAllChapters => 'Alle Lernkapitel freigeschaltet';

  @override
  String get aiCoachBenefitFeedback =>
      'Echtzeit-Grammatik- und Aussprachefeedback';

  @override
  String get aiCoachBenefitPersonalized => 'Personalisierter Lernpfad';

  @override
  String get aiCoachBenefitUnlimited => 'Unbegrenztes KI-Konversationstraining';

  @override
  String get aiCoachLabel => 'KI-Coach';

  @override
  String get aiCoachTrialEnded =>
      'Deine kostenlose KI-Coach-Testphase ist abgelaufen.';

  @override
  String get aiCoachUpgradePrompt =>
      'Upgrade auf Silber, Gold oder Platin zum Freischalten.';

  @override
  String get aiCoachUpgradeTitle => 'Upgrade für mehr Lerninhalte';

  @override
  String get albumNotShared => 'Album nicht geteilt';

  @override
  String get albumOption => 'Album';

  @override
  String albumRevokedMessage(String username) {
    return '$username hat den Albumzugang widerrufen';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username hat sein Album mit dir geteilt';
  }

  @override
  String get allCategoriesFilter => 'Alle';

  @override
  String get allDealBreakersAdded =>
      'Alle Ausschlusskriterien wurden hinzugefügt';

  @override
  String get allLanguagesFilter => 'Alle';

  @override
  String get allPlayersReady => 'Alle Spieler sind bereit!';

  @override
  String get alreadyHaveAccount => 'Haben Sie bereits ein Konto?';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Entdecken Sie Ihren Perfekten Partner';

  @override
  String get approveVerification => 'Genehmigen';

  @override
  String get atLeast8Characters => 'Mindestens 8 Zeichen';

  @override
  String get atLeastOneNumber => 'Mindestens eine Zahl';

  @override
  String get atLeastOneSpecialChar => 'Mindestens ein Sonderzeichen';

  @override
  String get authAppleSignInComingSoon => 'Apple-Anmeldung demnächst verfügbar';

  @override
  String get authCancelVerification => 'Verifizierung abbrechen?';

  @override
  String get authCancelVerificationBody =>
      'Du wirst abgemeldet, wenn du die Verifizierung abbrichst.';

  @override
  String get authDisableInSettings =>
      'Du kannst dies unter Einstellungen > Sicherheit deaktivieren';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Ein Konto mit dieser E-Mail existiert bereits.';

  @override
  String get authErrorGeneric =>
      'Ein Fehler ist aufgetreten. Bitte versuche es erneut.';

  @override
  String get authErrorInvalidCredentials =>
      'Falsche E-Mail/Nickname oder Passwort. Überprüfe deine Anmeldedaten und versuche es erneut.';

  @override
  String get authErrorInvalidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get authErrorNetworkError =>
      'Keine Internetverbindung. Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get authErrorTooManyRequests =>
      'Zu viele Versuche. Bitte versuche es später erneut.';

  @override
  String get authErrorUserNotFound =>
      'Kein Konto mit dieser E-Mail oder diesem Nickname gefunden. Überprüfe und versuche es erneut, oder registriere dich.';

  @override
  String get authErrorWeakPassword =>
      'Das Passwort ist zu schwach. Bitte verwende ein stärkeres Passwort.';

  @override
  String get authErrorWrongPassword =>
      'Falsches Passwort. Bitte versuche es erneut.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'Foto konnte nicht aufgenommen werden: $error';
  }

  @override
  String get authIdentityVerification => 'Identitätsverifizierung';

  @override
  String get authPleaseEnterEmail => 'Bitte gib deine E-Mail-Adresse ein';

  @override
  String get authRetakePhoto => 'Foto erneut aufnehmen';

  @override
  String get authSecurityStep =>
      'Dieser zusätzliche Sicherheitsschritt schützt dein Konto';

  @override
  String get authSelfieInstruction =>
      'Schau in die Kamera und tippe zum Aufnehmen';

  @override
  String get authSignOut => 'Abmelden';

  @override
  String get authSignOutInstead => 'Stattdessen abmelden';

  @override
  String get authStay => 'Bleiben';

  @override
  String get authTakeSelfie => 'Selfie aufnehmen';

  @override
  String get authTakeSelfieToVerify =>
      'Bitte nimm ein Selfie auf, um deine Identität zu bestätigen';

  @override
  String get authVerifyAndContinue => 'Verifizieren & Fortfahren';

  @override
  String get authVerifyWithSelfie =>
      'Bitte verifiziere deine Identität mit einem Selfie';

  @override
  String authWelcomeBack(Object name) {
    return 'Willkommen zurück, $name!';
  }

  @override
  String get authenticationErrorTitle => 'Anmeldung fehlgeschlagen';

  @override
  String get away => 'entfernt';

  @override
  String get awesome => 'Super!';

  @override
  String get backToLobby => 'Zurück zur Lobby';

  @override
  String get badgeLocked => 'Gesperrt';

  @override
  String get badgeUnlocked => 'Freigeschaltet';

  @override
  String get badges => 'Abzeichen';

  @override
  String get basic => 'Basis';

  @override
  String get basicInformation => 'Grundinformationen';

  @override
  String get betterPhotoRequested => 'Besseres Foto angefordert';

  @override
  String get bio => 'Biografie';

  @override
  String get bioUpdatedMessage => 'Deine Profil-Bio wurde gespeichert';

  @override
  String get bioUpdatedTitle => 'Bio aktualisiert!';

  @override
  String get blindDateActivate => 'Blind-Date-Modus aktivieren';

  @override
  String get blindDateDeactivate => 'Deaktivieren';

  @override
  String get blindDateDeactivateMessage =>
      'Du kehrst zum normalen Entdeckungsmodus zurück.';

  @override
  String get blindDateDeactivateTitle => 'Blind-Date-Modus deaktivieren?';

  @override
  String get blindDateDeactivateTooltip => 'Blind-Date-Modus deaktivieren';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Sofortige Enthüllung für $cost Münzen';
  }

  @override
  String get blindDateFeatureNoPhotos => 'Profilfotos zunächst nicht sichtbar';

  @override
  String get blindDateFeaturePersonality =>
      'Fokus auf Persönlichkeit und Interessen';

  @override
  String get blindDateFeatureUnlock => 'Fotos werden nach dem Chatten sichtbar';

  @override
  String get blindDateGetCoins => 'Münzen holen';

  @override
  String get blindDateInstantReveal => 'Sofort enthüllen';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return 'Alle Fotos dieses Matches für $cost Münzen enthüllen?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Sofort enthüllen ($cost Münzen)';
  }

  @override
  String get blindDateInsufficientCoins => 'Nicht genug Münzen';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'Du brauchst $cost Münzen, um Fotos sofort zu enthüllen.';
  }

  @override
  String get blindDateInterests => 'Interessen';

  @override
  String blindDateKmAway(String distance) {
    return '$distance km entfernt';
  }

  @override
  String get blindDateLetsExchange => 'Tauschen wir uns aus!';

  @override
  String get blindDateMatchMessage =>
      'Ihr mögt euch beide! Beginnt zu chatten, um eure Fotos zu enthüllen.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total Nachrichten';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return 'noch $count';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count Nachrichten bis zur Enthüllung';
  }

  @override
  String get blindDateModeActivated => 'Blind-Date-Modus aktiviert!';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Matche nach Persönlichkeit, nicht nach Aussehen.\nFotos werden nach $threshold Nachrichten sichtbar.';
  }

  @override
  String get blindDateModeTitle => 'Blind-Date-Modus';

  @override
  String get blindDateMysteryPerson => 'Geheimnisvolle Person';

  @override
  String get blindDateNoCandidates => 'Keine Kandidaten verfügbar';

  @override
  String get blindDateNoMatches => 'Noch keine Matches';

  @override
  String blindDatePendingReveal(int count) {
    return 'Ausstehende Enthüllung ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Foto-Enthüllungsfortschritt';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'Fotos enthüllen sich nach $threshold Nachrichten';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return 'Fotos enthüllt! $coinsSpent Münzen ausgegeben.';
  }

  @override
  String get blindDatePhotosRevealedLabel => 'Fotos enthüllt!';

  @override
  String get blindDateReveal => 'Enthüllen';

  @override
  String blindDateRevealed(int count) {
    return 'Enthüllt ($count)';
  }

  @override
  String get blindDateRevealedMatch => 'Enthülltes Match';

  @override
  String get blindDateStartSwiping =>
      'Fang an zu swipen und finde dein Blind Date!';

  @override
  String get blindDateTabDiscover => 'Entdecken';

  @override
  String get blindDateTabMatches => 'Matches';

  @override
  String get blindDateTitle => 'Blind Date';

  @override
  String get blindDateViewMatch => 'Match ansehen';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonusCoins Bonus!)';
  }

  @override
  String get boost => 'Boost';

  @override
  String get boostActivated => 'Boost für 30 Minuten aktiviert!';

  @override
  String get boostNow => 'Jetzt boosten';

  @override
  String get boostProfile => 'Profil boosten';

  @override
  String get boosted => 'GEBOOSTET!';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Paket';

  @override
  String get businessCategory => 'Geschäft';

  @override
  String get buyCoins => 'Münzen kaufen';

  @override
  String get buyCoinsBtnLabel => 'Coins kaufen';

  @override
  String get buyPackBtn => 'Kaufen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get cancelLabel => 'Abbrechen';

  @override
  String get cannotAccessFeature =>
      'Diese Funktion ist nach der Verifizierung deines Kontos verfügbar.';

  @override
  String get cantUndoMatched =>
      'Rückgängig nicht möglich — ihr habt bereits gematcht!';

  @override
  String get casualCategory => 'Locker';

  @override
  String get casualDating => 'Unverbindliches Dating';

  @override
  String get categoryFlashcard => 'Karteikarte';

  @override
  String get categoryLearning => 'Lernen';

  @override
  String get categoryMultilingual => 'Mehrsprachig';

  @override
  String get categoryName => 'Kategorie';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Saisonal';

  @override
  String get categorySocial => 'Sozial';

  @override
  String get categoryStreak => 'Serie';

  @override
  String get categoryTranslation => 'Übersetzung';

  @override
  String get challenges => 'Herausforderungen';

  @override
  String get changeLocation => 'Standort ändern';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordConfirm => 'Neues Passwort bestätigen';

  @override
  String get changePasswordCurrent => 'Aktuelles Passwort';

  @override
  String get changePasswordDescription =>
      'Bitte bestätige aus Sicherheitsgründen deine Identität, bevor du dein Passwort änderst.';

  @override
  String get changePasswordEmailConfirm => 'Bestätige deine E-Mail-Adresse';

  @override
  String get changePasswordEmailHint => 'Deine E-Mail';

  @override
  String get changePasswordEmailMismatch =>
      'E-Mail stimmt nicht mit deinem Konto überein';

  @override
  String get changePasswordNew => 'Neues Passwort';

  @override
  String get changePasswordReauthRequired =>
      'Bitte melde dich ab und wieder an, bevor du dein Passwort änderst';

  @override
  String get changePasswordSubtitle => 'Aktualisiere dein Kontopasswort';

  @override
  String get changePasswordSuccess => 'Passwort erfolgreich geändert';

  @override
  String get changePasswordWrongCurrent => 'Aktuelles Passwort ist falsch';

  @override
  String get chatAddCaption => 'Beschriftung hinzufügen...';

  @override
  String get chatAddToStarred => 'Zu markierten Nachrichten hinzufügen';

  @override
  String get chatAlreadyInYourLanguage =>
      'Nachricht ist bereits in deiner Sprache';

  @override
  String get chatAttachCamera => 'Kamera';

  @override
  String get chatAttachGallery => 'Galerie';

  @override
  String get chatAttachRecord => 'Aufnehmen';

  @override
  String get chatAttachVideo => 'Video';

  @override
  String get chatBlock => 'Blockieren';

  @override
  String chatBlockUser(String name) {
    return '$name blockieren';
  }

  @override
  String chatBlockUserMessage(String name) {
    return 'Bist du sicher, dass du $name blockieren möchtest? Sie können dich nicht mehr kontaktieren.';
  }

  @override
  String get chatBlockUserTitle => 'Benutzer blockieren';

  @override
  String get chatCannotBlockAdmin =>
      'Du kannst keinen Administrator blockieren.';

  @override
  String get chatCannotReportAdmin => 'Du kannst keinen Administrator melden.';

  @override
  String get chatCategory => 'Kategorie';

  @override
  String get chatCategoryAccount => 'Kontohilfe';

  @override
  String get chatCategoryBilling => 'Abrechnung & Zahlungen';

  @override
  String get chatCategoryFeedback => 'Feedback';

  @override
  String get chatCategoryGeneral => 'Allgemeine Frage';

  @override
  String get chatCategorySafety => 'Sicherheitsbedenken';

  @override
  String get chatCategoryTechnical => 'Technisches Problem';

  @override
  String get chatCopy => 'Kopieren';

  @override
  String get chatCreate => 'Erstellen';

  @override
  String get chatCreateSupportTicket => 'Support-Ticket erstellen';

  @override
  String get chatCreateTicket => 'Ticket erstellen';

  @override
  String chatDaysAgo(int count) {
    return 'vor ${count}T';
  }

  @override
  String get chatDelete => 'Löschen';

  @override
  String get chatDeleteChat => 'Chat löschen';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Dies löscht alle Nachrichten für dich und $name. Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Chat für alle löschen';

  @override
  String get chatDeleteChatForMeMessage =>
      'Dies löscht den Chat nur von deinem Gerät. Die andere Person sieht die Nachrichten weiterhin.';

  @override
  String chatDeleteConversationWith(String name) {
    return 'Unterhaltung mit $name löschen?';
  }

  @override
  String get chatDeleteForBoth => 'Chat für beide löschen';

  @override
  String get chatDeleteForBothDescription =>
      'Dies löscht die Unterhaltung dauerhaft für dich und die andere Person.';

  @override
  String get chatDeleteForEveryone => 'Für alle löschen';

  @override
  String get chatDeleteForMe => 'Chat für mich löschen';

  @override
  String get chatDeleteForMeDescription =>
      'Dies löscht die Unterhaltung nur aus deiner Chat-Liste. Die andere Person sieht sie weiterhin.';

  @override
  String get chatDeletedForBothMessage =>
      'Dieser Chat wurde endgültig gelöscht';

  @override
  String get chatDeletedForMeMessage =>
      'Dieser Chat wurde aus deinem Posteingang entfernt';

  @override
  String get chatDeletedTitle => 'Chat gelöscht!';

  @override
  String get chatDescriptionOptional => 'Beschreibung (Optional)';

  @override
  String get chatDetailsHint => 'Beschreibe dein Problem genauer...';

  @override
  String get chatDisableTranslation => 'Übersetzung deaktivieren';

  @override
  String get chatEnableTranslation => 'Übersetzung aktivieren';

  @override
  String get chatErrorLoadingTickets => 'Fehler beim Laden der Tickets';

  @override
  String get chatFailedToCreateTicket => 'Ticket konnte nicht erstellt werden';

  @override
  String get chatFailedToForwardMessage =>
      'Nachricht konnte nicht weitergeleitet werden';

  @override
  String get chatFailedToLoadAlbum => 'Album konnte nicht geladen werden';

  @override
  String get chatFailedToLoadConversations =>
      'Unterhaltungen konnten nicht geladen werden';

  @override
  String get chatFailedToLoadImage => 'Bild konnte nicht geladen werden';

  @override
  String get chatFailedToLoadVideo => 'Video konnte nicht geladen werden';

  @override
  String chatFailedToPickImage(String error) {
    return 'Bild konnte nicht ausgewählt werden: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Video konnte nicht ausgewählt werden: $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Nachricht konnte nicht gemeldet werden: $error';
  }

  @override
  String get chatFailedToRevokeAccess =>
      'Zugriff konnte nicht widerrufen werden';

  @override
  String get chatFailedToSaveFlashcard =>
      'Karteikarte konnte nicht gespeichert werden';

  @override
  String get chatFailedToShareAlbum => 'Album konnte nicht geteilt werden';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Bild konnte nicht hochgeladen werden: $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Video konnte nicht hochgeladen werden: $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Kulturtipps & Kontext';

  @override
  String get chatFeatureGrammar => 'Echtzeit-Grammatikfeedback';

  @override
  String get chatFeatureVocabulary => 'Wortschatzübungen';

  @override
  String get chatForward => 'Weiterleiten';

  @override
  String get chatForwardMessage => 'Nachricht weiterleiten';

  @override
  String get chatForwardToChat => 'An einen anderen Chat weiterleiten';

  @override
  String get chatGrammarSuggestion => 'Grammatikvorschlag';

  @override
  String chatHoursAgo(int count) {
    return 'vor ${count}Std';
  }

  @override
  String get chatIcebreakers => 'Gesprächsstarter';

  @override
  String chatIsTyping(String userName) {
    return '$userName tippt';
  }

  @override
  String get chatJustNow => 'Gerade eben';

  @override
  String get chatLanguagePickerHint =>
      'Wähle die Sprache, in der du diese Unterhaltung lesen möchtest. Alle Nachrichten werden für dich übersetzt.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Chat-Sprache auf $language gesetzt';
  }

  @override
  String get chatLanguages => 'Sprachen';

  @override
  String get chatLearnThis => 'Das lernen';

  @override
  String get chatListen => 'Anhören';

  @override
  String get chatLoadingVideo => 'Video wird geladen...';

  @override
  String get chatMaybeLater => 'Vielleicht später';

  @override
  String get chatMediaLimitReached => 'Medienlimit erreicht';

  @override
  String get chatMessage => 'Nachricht';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Nachricht blockiert: Enthält $violations. Zu Ihrer Sicherheit ist das Teilen persönlicher Kontaktdaten nicht erlaubt.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Nachricht an $count Unterhaltung(en) weitergeleitet';
  }

  @override
  String get chatMessageOptions => 'Nachrichtenoptionen';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageReported =>
      'Nachricht gemeldet. Wir werden sie in Kürze überprüfen.';

  @override
  String get chatMessageStarred => 'Nachricht markiert';

  @override
  String get chatMessageTranslated => 'Übersetzt';

  @override
  String get chatMessageUnstarred => 'Markierung entfernt';

  @override
  String chatMinutesAgo(int count) {
    return 'vor ${count}Min';
  }

  @override
  String get chatMySupportTickets => 'Meine Support-Tickets';

  @override
  String get chatNeedHelpCreateTicket =>
      'Brauchst du Hilfe? Erstelle ein neues Ticket.';

  @override
  String get chatNewTicket => 'Neues Ticket';

  @override
  String get chatNoConversationsToForward =>
      'Keine Unterhaltungen zum Weiterleiten';

  @override
  String get chatNoMatchingConversations => 'Keine passenden Unterhaltungen';

  @override
  String get chatNoMessagesToPractice => 'Noch keine Nachrichten zum Üben';

  @override
  String get chatNoMessagesYet => 'Noch keine Nachrichten';

  @override
  String get chatNoPrivatePhotos => 'Keine privaten Fotos verfügbar';

  @override
  String get chatNoSupportTickets => 'Keine Support-Tickets';

  @override
  String get chatOffline => 'Offline';

  @override
  String get chatOnline => 'Online';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'Online vor ${days}T';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'Online vor ${hours}Std';
  }

  @override
  String get chatOnlineJustNow => 'Gerade online';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'Online vor ${minutes}Min';
  }

  @override
  String get chatOptions => 'Chat-Optionen';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name hat den Albumzugriff widerrufen';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name hat sein privates Album geteilt';
  }

  @override
  String get chatPhoto => 'Foto';

  @override
  String get chatPhraseSaved =>
      'Phrase in deinem Karteikarten-Deck gespeichert!';

  @override
  String get chatPleaseEnterSubject => 'Bitte gib einen Betreff ein';

  @override
  String get chatPractice => 'Üben';

  @override
  String get chatPracticeMode => 'Übungsmodus';

  @override
  String get chatPracticeTrialStarted =>
      'Übungsmodus-Testversion gestartet! Du hast 3 kostenlose Sitzungen.';

  @override
  String get chatPreviewImage => 'Bildvorschau';

  @override
  String get chatPreviewVideo => 'Videovorschau';

  @override
  String get chatPronunciationChallenge => 'Aussprache-Challenge';

  @override
  String get chatPronunciationHint =>
      'Tippe zum Anhören und übe dann jeden Satz:';

  @override
  String get chatRemoveFromStarred => 'Aus markierten Nachrichten entfernen';

  @override
  String get chatReply => 'Antworten';

  @override
  String get chatReplyToMessage => 'Auf diese Nachricht antworten';

  @override
  String chatReplyingTo(String name) {
    return 'Antwort an $name';
  }

  @override
  String get chatReportInappropriate => 'Unangemessenen Inhalt melden';

  @override
  String get chatReportMessage => 'Nachricht melden';

  @override
  String get chatReportReasonFakeProfile => 'Falsches Profil / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Belästigung oder Mobbing';

  @override
  String get chatReportReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get chatReportReasonOther => 'Sonstiges';

  @override
  String get chatReportReasonPersonalInfo =>
      'Teilen persönlicher Informationen';

  @override
  String get chatReportReasonSpam => 'Spam oder Betrug';

  @override
  String get chatReportReasonThreatening => 'Bedrohliches Verhalten';

  @override
  String get chatReportReasonUnderage => 'Minderjähriger Benutzer';

  @override
  String chatReportUser(String name) {
    return '$name melden';
  }

  @override
  String get chatReportUserTitle => 'Benutzer melden';

  @override
  String get chatSafetyGotIt => 'Verstanden';

  @override
  String get chatSafetySubtitle =>
      'Deine Sicherheit hat Priorität. Behalte diese Tipps im Kopf.';

  @override
  String get chatSafetyTip => 'Sicherheitstipp';

  @override
  String get chatSafetyTip1Description =>
      'Teile keine Adresse, Telefonnummer oder Finanzinformationen.';

  @override
  String get chatSafetyTip1Title => 'Halte Persönliche Infos Privat';

  @override
  String get chatSafetyTip2Description =>
      'Sende niemals Geld an jemanden, den du nicht persönlich getroffen hast.';

  @override
  String get chatSafetyTip2Title => 'Vorsicht bei Geldanfragen';

  @override
  String get chatSafetyTip3Description =>
      'Wähle für erste Treffen immer einen öffentlichen, gut beleuchteten Ort.';

  @override
  String get chatSafetyTip3Title => 'Treffen an Öffentlichen Orten';

  @override
  String get chatSafetyTip4Description =>
      'Wenn sich etwas falsch anfühlt, vertraue deinem Bauchgefühl und beende das Gespräch.';

  @override
  String get chatSafetyTip4Title => 'Vertraue Deinem Instinkt';

  @override
  String get chatSafetyTip5Description =>
      'Nutze die Meldefunktion, wenn dich jemand unwohl fühlen lässt.';

  @override
  String get chatSafetyTip5Title => 'Verdächtiges Verhalten Melden';

  @override
  String get chatSafetyTitle => 'Sicher Chatten';

  @override
  String get chatSaving => 'Speichere...';

  @override
  String chatSayHiTo(String name) {
    return 'Sag Hallo zu $name!';
  }

  @override
  String get chatScrollUpForOlder =>
      'Nach oben scrollen für ältere Nachrichten';

  @override
  String get chatSearchByNameOrNickname => 'Nach Name oder @Spitzname suchen';

  @override
  String get chatSearchConversationsHint => 'Unterhaltungen suchen...';

  @override
  String get chatSelectPhotos => 'Fotos zum Senden auswählen';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatSendAnyway => 'Trotzdem senden';

  @override
  String get chatSendAttachment => 'Anhang senden';

  @override
  String chatSendCount(int count) {
    return 'Senden ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Sende eine Nachricht, um die Unterhaltung zu beginnen';

  @override
  String get chatSendMessagesForTips =>
      'Sende Nachrichten, um Sprachtipps zu erhalten!';

  @override
  String get chatSetNativeLanguage =>
      'Setze zuerst deine Muttersprache in den Einstellungen';

  @override
  String get chatSettingCulturalTips => 'Kulturtipps';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Kulturellen Kontext für Redewendungen anzeigen';

  @override
  String get chatSettingDifficultyBadges => 'Schwierigkeitsabzeichen';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'CEFR-Niveau (A1-C2) auf Nachrichten anzeigen';

  @override
  String get chatSettingGrammarCheck => 'Grammatikprüfung';

  @override
  String get chatSettingGrammarCheckDesc => 'Grammatik vor dem Senden prüfen';

  @override
  String get chatSettingLanguageFlags => 'Sprachflaggen';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Flaggen-Emoji neben übersetztem und Originaltext anzeigen';

  @override
  String get chatSettingPhraseOfDay => 'Phrase des Tages';

  @override
  String get chatSettingPhraseOfDayDesc => 'Tägliche Übungsphrase anzeigen';

  @override
  String get chatSettingPronunciation => 'Aussprache (TTS)';

  @override
  String get chatSettingPronunciationDesc => 'Doppeltippen für Aussprache';

  @override
  String get chatSettingShowOriginal => 'Originaltext anzeigen';

  @override
  String get chatSettingShowOriginalDesc =>
      'Originalnachricht unter der Übersetzung anzeigen';

  @override
  String get chatSettingSmartReplies => 'Intelligente Antworten';

  @override
  String get chatSettingSmartRepliesDesc =>
      'Antworten in der Zielsprache vorschlagen';

  @override
  String get chatSettingTtsTranslation => 'TTS liest Übersetzung';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Übersetzten Text statt Original vorlesen';

  @override
  String get chatSettingWordBreakdown => 'Wortzerlegung';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Nachrichten antippen für Wort-für-Wort-Übersetzung';

  @override
  String get chatSettingXpBar => 'XP & Streak-Leiste';

  @override
  String get chatSettingXpBarDesc => 'Sitzungs-XP und Wortanzahl anzeigen';

  @override
  String get chatSettingsSaveAllChats =>
      'Einstellungen für alle Chats speichern';

  @override
  String get chatSettingsSaveThisChat =>
      'Einstellungen für diesen Chat speichern';

  @override
  String get chatSettingsSavedAllChats =>
      'Einstellungen für alle Chats gespeichert';

  @override
  String get chatSettingsSavedThisChat =>
      'Einstellungen für diesen Chat gespeichert';

  @override
  String get chatSettingsSubtitle =>
      'Passe dein Lernerlebnis in diesem Chat an';

  @override
  String get chatSettingsTitle => 'Chat-Einstellungen';

  @override
  String get chatSomeone => 'Jemand';

  @override
  String get chatStarMessage => 'Nachricht markieren';

  @override
  String get chatStartSwipingToChat =>
      'Wische und matche, um mit Leuten zu chatten!';

  @override
  String get chatStatusAssigned => 'Zugewiesen';

  @override
  String get chatStatusAwaitingReply => 'Warte auf Antwort';

  @override
  String get chatStatusClosed => 'Geschlossen';

  @override
  String get chatStatusInProgress => 'In Bearbeitung';

  @override
  String get chatStatusOpen => 'Offen';

  @override
  String get chatStatusResolved => 'Gelöst';

  @override
  String chatStreak(int count) {
    return 'Serie: $count';
  }

  @override
  String get chatSubject => 'Betreff';

  @override
  String get chatSubjectHint => 'Kurze Beschreibung deines Problems';

  @override
  String get chatSupportAddAttachment => 'Anhang hinzufügen';

  @override
  String get chatSupportAddCaptionOptional =>
      'Beschriftung hinzufügen (optional)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agent: $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agent';

  @override
  String get chatSupportCategory => 'Kategorie';

  @override
  String get chatSupportClose => 'Schließen';

  @override
  String chatSupportDaysAgo(int days) {
    return 'vor ${days}T.';
  }

  @override
  String get chatSupportErrorLoading => 'Fehler beim Laden der Nachrichten';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Ticket konnte nicht erneut geöffnet werden: $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Nachricht konnte nicht gesendet werden: $error';
  }

  @override
  String get chatSupportGeneral => 'Allgemein';

  @override
  String get chatSupportGeneralSupport => 'Allgemeiner Support';

  @override
  String chatSupportHoursAgo(int hours) {
    return 'vor ${hours}Std.';
  }

  @override
  String get chatSupportJustNow => 'Gerade eben';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'vor ${minutes}Min.';
  }

  @override
  String get chatSupportReopenTicket =>
      'Brauchst du weitere Hilfe? Tippe, um erneut zu öffnen';

  @override
  String get chatSupportStartMessage =>
      'Sende eine Nachricht, um die Unterhaltung zu beginnen.\nUnser Team wird so schnell wie möglich antworten.';

  @override
  String get chatSupportStatus => 'Status';

  @override
  String get chatSupportStatusClosed => 'Geschlossen';

  @override
  String get chatSupportStatusDefault => 'Support';

  @override
  String get chatSupportStatusOpen => 'Offen';

  @override
  String get chatSupportStatusPending => 'Ausstehend';

  @override
  String get chatSupportStatusResolved => 'Gelöst';

  @override
  String get chatSupportSubject => 'Betreff';

  @override
  String get chatSupportTicketCreated => 'Ticket erstellt';

  @override
  String get chatSupportTicketId => 'Ticket-ID';

  @override
  String get chatSupportTicketInfo => 'Ticket-Informationen';

  @override
  String get chatSupportTicketReopened =>
      'Ticket erneut geöffnet. Du kannst jetzt eine Nachricht senden.';

  @override
  String get chatSupportTicketResolved => 'Dieses Ticket wurde gelöst';

  @override
  String get chatSupportTicketStart => 'Ticket-Anfang';

  @override
  String get chatSupportTitle => 'GreenGo Support';

  @override
  String get chatSupportTypeMessage => 'Nachricht eingeben...';

  @override
  String get chatSupportWaitingAssignment => 'Warte auf Zuweisung';

  @override
  String get chatSupportWelcome => 'Willkommen beim Support';

  @override
  String get chatTapToView => 'Tippe zum Ansehen';

  @override
  String get chatTapToViewAlbum => 'Tippe zum Album ansehen';

  @override
  String get chatTranslate => 'Übersetzen';

  @override
  String get chatTranslated => 'Übersetzt';

  @override
  String get chatTranslating => 'Übersetze...';

  @override
  String get chatTranslationDisabled => 'Übersetzung deaktiviert';

  @override
  String get chatTranslationEnabled => 'Übersetzung aktiviert';

  @override
  String get chatTranslationFailed =>
      'Übersetzung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get chatTrialExpired => 'Deine kostenlose Testversion ist abgelaufen.';

  @override
  String get chatTtsComingSoon => 'Text-zu-Sprache kommt bald!';

  @override
  String get chatTyping => 'tippt...';

  @override
  String get chatUnableToForward =>
      'Nachricht kann nicht weitergeleitet werden';

  @override
  String get chatUnknown => 'Unbekannt';

  @override
  String get chatUnstarMessage => 'Markierung entfernen';

  @override
  String get chatUpgrade => 'Upgrade';

  @override
  String get chatUpgradePracticeMode =>
      'Upgrade auf Silver VIP oder höher, um weiter Sprachen in deinen Chats zu üben.';

  @override
  String get chatUploading => 'Wird hochgeladen...';

  @override
  String get chatUseCorrection => 'Korrektur verwenden';

  @override
  String chatUserBlocked(String name) {
    return '$name wurde blockiert';
  }

  @override
  String get chatUserReported =>
      'Benutzer gemeldet. Wir werden deinen Bericht in Kürze überprüfen.';

  @override
  String get chatVideo => 'Video';

  @override
  String get chatVideoPlayer => 'Videoplayer';

  @override
  String get chatVideoTooLarge => 'Video zu groß. Maximale Größe ist 50MB.';

  @override
  String get chatWhyReportMessage => 'Warum melden Sie diese Nachricht?';

  @override
  String chatWhyReportUser(String name) {
    return 'Warum meldest du $name?';
  }

  @override
  String chatWithName(String name) {
    return 'Mit $name chatten';
  }

  @override
  String chatWords(int count) {
    return '$count Wörter';
  }

  @override
  String get chatYou => 'Du';

  @override
  String get chatYouRevokedAlbum => 'Du hast den Albumzugriff widerrufen';

  @override
  String get chatYouSharedAlbum => 'Du hast dein privates Album geteilt';

  @override
  String get chatYourLanguage => 'Deine Sprache';

  @override
  String get checkBackLater =>
      'Komm später wieder für neue Leute, oder passe deine Präferenzen an';

  @override
  String get chooseCorrectAnswer => 'Wähle die richtige Antwort';

  @override
  String get chooseFromGallery => 'Aus Galerie Wählen';

  @override
  String get chooseGame => 'Wähle ein Spiel';

  @override
  String get claimReward => 'Belohnung einlösen';

  @override
  String get claimRewardBtn => 'Einlösen';

  @override
  String get clearFilters => 'Filter Löschen';

  @override
  String get close => 'Schließen';

  @override
  String get coins => 'Münzen';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins Münzen zu deinem Konto hinzugefügt$bonusText';
  }

  @override
  String get coinsAllTransactions => 'Alle Transaktionen';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount Coins';
  }

  @override
  String coinsAmountVideoMinutes(Object amount) {
    return '$amount Videominuten';
  }

  @override
  String get coinsApply => 'Anwenden';

  @override
  String coinsBalance(Object balance) {
    return 'Guthaben: $balance';
  }

  @override
  String coinsBonusCoins(Object amount) {
    return '+$amount Bonus-Coins';
  }

  @override
  String get coinsCancelLabel => 'Abbrechen';

  @override
  String get coinsConfirmPurchase => 'Kauf bestätigen';

  @override
  String coinsCost(int amount) {
    return '$amount Münzen';
  }

  @override
  String get coinsCreditsOnly => 'Nur Gutschriften';

  @override
  String get coinsDebitsOnly => 'Nur Abbuchungen';

  @override
  String get coinsEnterReceiverId => 'Empfänger-ID eingeben';

  @override
  String coinsExpiring(Object count) {
    return '$count laufen ab';
  }

  @override
  String get coinsFilterTransactions => 'Transaktionen filtern';

  @override
  String coinsGiftAccepted(Object amount) {
    return '$amount Münzen angenommen!';
  }

  @override
  String get coinsGiftDeclined => 'Geschenk abgelehnt';

  @override
  String get coinsGiftSendFailed => 'Geschenk konnte nicht gesendet werden';

  @override
  String coinsGiftSent(Object amount) {
    return 'Geschenk von $amount Münzen gesendet!';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Nicht genug Münzen';

  @override
  String get coinsLabel => 'Coins';

  @override
  String get coinsMessageLabel => 'Nachricht (optional)';

  @override
  String get coinsMins => 'Min.';

  @override
  String get coinsNoTransactionsYet => 'Noch keine Transaktionen';

  @override
  String get coinsPendingGifts => 'Ausstehende Geschenke';

  @override
  String get coinsPopular => 'BELIEBT';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return '$totalCoins Coins fuer $price kaufen?';
  }

  @override
  String get coinsPurchaseFailed => 'Kauf fehlgeschlagen';

  @override
  String get coinsPurchaseLabel => 'Kaufen';

  @override
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return '$totalMinutes Videominuten fuer $price kaufen?';
  }

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return '$totalCoins Münzen erfolgreich gekauft!';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return '$totalMinutes Videominuten erfolgreich gekauft!';
  }

  @override
  String get coinsReceiverIdLabel => 'Empfänger-Benutzer-ID';

  @override
  String coinsRequired(int amount) {
    return '$amount Münzen erforderlich';
  }

  @override
  String get coinsRetry => 'Erneut versuchen';

  @override
  String get coinsSelectAmount => 'Betrag waehlen';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return '$amount Coins senden';
  }

  @override
  String get coinsSendGift => 'Geschenk senden';

  @override
  String get coinsSent => 'Münzen erfolgreich gesendet!';

  @override
  String get coinsShareCoins => 'Teile Coins mit jemandem Besonderen';

  @override
  String get coinsShopLabel => 'Shop';

  @override
  String get coinsTabCoins => 'Münzen';

  @override
  String get coinsTabGifts => 'Geschenke';

  @override
  String get coinsTabVideoCoins => 'Video-Münzen';

  @override
  String get coinsToday => 'Heute';

  @override
  String get coinsTransactionHistory => 'Transaktionsverlauf';

  @override
  String get coinsTransactionsAppearHere =>
      'Deine Coin-Transaktionen werden hier angezeigt';

  @override
  String get coinsUnlockPremium => 'Premium-Funktionen freischalten';

  @override
  String get coinsVideoCallMatches => 'Videoanruf mit deinen Matches';

  @override
  String get coinsVideoCoinInfo => '1 Video-Coin = 1 Minute Videoanruf';

  @override
  String get coinsVideoMin => 'Video Min.';

  @override
  String get coinsVideoMinutes => 'Videominuten';

  @override
  String get coinsYesterday => 'Gestern';

  @override
  String get comingSoonLabel => 'Demnächst';

  @override
  String get communitiesAddTag => 'Tag hinzufuegen';

  @override
  String get communitiesAdjustSearch =>
      'Versuche deine Suche oder Filter anzupassen.';

  @override
  String get communitiesAllCommunities => 'Alle Communities';

  @override
  String get communitiesAllFilter => 'Alle';

  @override
  String get communitiesAnyoneCanJoin => 'Jeder kann beitreten';

  @override
  String get communitiesBeFirstToSay => 'Schreib die erste Nachricht!';

  @override
  String get communitiesCancelLabel => 'Abbrechen';

  @override
  String get communitiesCityLabel => 'Stadt';

  @override
  String get communitiesCityTipLabel => 'Stadttipp';

  @override
  String get communitiesCityTipUpper => 'STADTTIPP';

  @override
  String get communitiesCommunityInfo => 'Community-Info';

  @override
  String get communitiesCommunityName => 'Community-Name';

  @override
  String get communitiesCommunityType => 'Community-Typ';

  @override
  String get communitiesCountryLabel => 'Land';

  @override
  String get communitiesCreateAction => 'Erstellen';

  @override
  String get communitiesCreateCommunity => 'Community erstellen';

  @override
  String get communitiesCreateCommunityAction => 'Community erstellen';

  @override
  String get communitiesCreateLabel => 'Erstellen';

  @override
  String get communitiesCreateLanguageCircle => 'Sprachkreis erstellen';

  @override
  String get communitiesCreated => 'Community erstellt!';

  @override
  String communitiesCreatedBy(String name) {
    return 'Erstellt von $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Erstellt';

  @override
  String get communitiesCulturalFactLabel => 'Kulturfakt';

  @override
  String get communitiesCulturalFactUpper => 'KULTURFAKT';

  @override
  String get communitiesDescription => 'Beschreibung';

  @override
  String get communitiesDescriptionHint => 'Worum geht es in dieser Community?';

  @override
  String get communitiesDescriptionLabel => 'Beschreibung';

  @override
  String get communitiesDescriptionMinLength =>
      'Beschreibung muss mindestens 10 Zeichen lang sein';

  @override
  String get communitiesDescriptionRequired =>
      'Bitte gib eine Beschreibung ein';

  @override
  String get communitiesDiscoverCommunities => 'Communities entdecken';

  @override
  String get communitiesEditLabel => 'Bearbeiten';

  @override
  String get communitiesGuide => 'Guide';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Nur mit Einladung';

  @override
  String get communitiesJoinCommunity => 'Community beitreten';

  @override
  String get communitiesJoinPrompt =>
      'Tritt Communities bei, um Menschen mit gleichen Interessen und Sprachen zu finden.';

  @override
  String get communitiesJoined => 'Community beigetreten!';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'Sprachkreise werden hier angezeigt, sobald verfuegbar. Erstelle einen, um loszulegen!';

  @override
  String get communitiesLanguageTipLabel => 'Sprachtipp';

  @override
  String get communitiesLanguageTipUpper => 'SPRACHTIPP';

  @override
  String get communitiesLanguages => 'Sprachen';

  @override
  String get communitiesLanguagesLabel => 'Sprachen';

  @override
  String get communitiesLeaveCommunity => 'Community verlassen';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Bist du sicher, dass du \"$name\" verlassen moechtest?';
  }

  @override
  String get communitiesLeaveLabel => 'Verlassen';

  @override
  String get communitiesLeaveTitle => 'Community verlassen';

  @override
  String get communitiesLocation => 'Standort';

  @override
  String get communitiesLocationLabel => 'Standort';

  @override
  String communitiesMembersCount(Object count) {
    return '$count Mitglieder';
  }

  @override
  String get communitiesMembersStatLabel => 'Mitglieder';

  @override
  String get communitiesMembersTitle => 'Mitglieder';

  @override
  String get communitiesNameHint => 'z.B. Spanischlerner Berlin';

  @override
  String get communitiesNameMinLength =>
      'Name muss mindestens 3 Zeichen lang sein';

  @override
  String get communitiesNameRequired => 'Bitte gib einen Namen ein';

  @override
  String get communitiesNoCommunities => 'Noch keine Communities';

  @override
  String get communitiesNoCommunitiesFound => 'Keine Communities gefunden';

  @override
  String get communitiesNoLanguageCircles => 'Keine Sprachkreise';

  @override
  String get communitiesNoMessagesYet => 'Noch keine Nachrichten';

  @override
  String get communitiesPreview => 'Vorschau';

  @override
  String get communitiesPreviewSubtitle =>
      'So wird deine Community anderen angezeigt.';

  @override
  String get communitiesPrivate => 'Privat';

  @override
  String get communitiesPublic => 'Oeffentlich';

  @override
  String get communitiesRecommendedForYou => 'Fuer dich empfohlen';

  @override
  String get communitiesSearchHint => 'Communities suchen...';

  @override
  String get communitiesShareCityTip => 'Teile einen Stadttipp...';

  @override
  String get communitiesShareCulturalFact => 'Teile einen Kulturfakt...';

  @override
  String get communitiesShareLanguageTip => 'Teile einen Sprachtipp...';

  @override
  String get communitiesStats => 'Statistiken';

  @override
  String get communitiesTabDiscover => 'Entdecken';

  @override
  String get communitiesTabLanguageCircles => 'Sprachzirkel';

  @override
  String get communitiesTabMyGroups => 'Meine Gruppen';

  @override
  String get communitiesTags => 'Tags';

  @override
  String get communitiesTagsLabel => 'Tags';

  @override
  String get communitiesTextLabel => 'Text';

  @override
  String get communitiesTitle => 'Communities';

  @override
  String get communitiesTypeAMessage => 'Nachricht eingeben...';

  @override
  String get communitiesUnableToLoad =>
      'Communauty konnte nicht geladen werden';

  @override
  String get compatibilityLabel => 'Kompatibilitaet';

  @override
  String compatiblePercent(String percent) {
    return '$percent% kompatibel';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      'Schließe Erfolge ab, um Abzeichen zu verdienen!';

  @override
  String get completeProfile => 'Vervollständigen Sie Ihr Profil';

  @override
  String get complimentsCategory => 'Komplimente';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get confirmLabel => 'Bestätigen';

  @override
  String get confirmLocation => 'Standort bestätigen';

  @override
  String get confirmPassword => 'Passwort Bestätigen';

  @override
  String get confirmPasswordRequired => 'Bitte bestätigen Sie Ihr Passwort';

  @override
  String get connectSocialAccounts => 'Verbinde deine sozialen Konten';

  @override
  String get connectionError => 'Verbindungsfehler';

  @override
  String get connectionErrorMessage =>
      'Überprüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get connectionErrorTitle => 'Keine Internetverbindung';

  @override
  String get consentRequired => 'Erforderliche Einwilligungen';

  @override
  String get consentRequiredError =>
      'Sie müssen die Datenschutzerklärung und die Allgemeinen Geschäftsbedingungen akzeptieren, um sich zu registrieren';

  @override
  String get contactSupport => 'Support Kontaktieren';

  @override
  String get continueLearningBtn => 'Weiter';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get continueWithFacebook => 'Mit Facebook fortfahren';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get conversationCategory => 'Unterhaltung';

  @override
  String get correctAnswer => 'Richtig!';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get createAccount => 'Konto Erstellen';

  @override
  String get culturalCategory => 'Kulturell';

  @override
  String get culturalExchangeBeFirstTip =>
      'Sei der Erste, der einen Kulturtipp teilt!';

  @override
  String get culturalExchangeCategory => 'Kategorie';

  @override
  String get culturalExchangeCommunityTips => 'Community-Tipps';

  @override
  String get culturalExchangeCountry => 'Land';

  @override
  String get culturalExchangeCountryHint => 'z.B. Japan, Brasilien, Frankreich';

  @override
  String get culturalExchangeCountrySpotlight => 'Land im Fokus';

  @override
  String get culturalExchangeDailyInsight => 'Tägliche kulturelle Erkenntnis';

  @override
  String get culturalExchangeDatingEtiquette => 'Dating-Etikette';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Dating-Etikette-Leitfaden';

  @override
  String get culturalExchangeLoadingCountries => 'Länder werden geladen...';

  @override
  String get culturalExchangeNoTips => 'Noch keine Tipps';

  @override
  String get culturalExchangeShareCulturalTip => 'Einen Kulturtipp teilen';

  @override
  String get culturalExchangeShareTip => 'Tipp teilen';

  @override
  String get culturalExchangeSubmitTip => 'Tipp einreichen';

  @override
  String get culturalExchangeTipTitle => 'Titel';

  @override
  String get culturalExchangeTipTitleHint =>
      'Gib deinem Tipp einen einprägsamen Titel';

  @override
  String get culturalExchangeTitle => 'Kulturaustausch';

  @override
  String get culturalExchangeViewAll => 'Alle anzeigen';

  @override
  String get culturalExchangeYourTip => 'Dein Tipp';

  @override
  String get culturalExchangeYourTipHint => 'Teile dein kulturelles Wissen...';

  @override
  String get dailyChallengesSubtitle =>
      'Herausforderungen fuer Belohnungen abschliessen';

  @override
  String get dailyChallengesTitle => 'Tägliche Herausforderungen';

  @override
  String dailyLimitReached(int limit) {
    return 'Tageslimit von $limit erreicht';
  }

  @override
  String get dailyMessages => 'Tägliche Nachrichten';

  @override
  String get dailyRewardHeader => 'Tägliche Belohnung';

  @override
  String get dailySwipeLimitReached =>
      'Tägliches Swipe-Limit erreicht. Upgrade für mehr Swipes!';

  @override
  String get dailySwipes => 'Tägliche Swipes';

  @override
  String get dataExportSentToEmail => 'Datenexport an deine E-Mail gesendet';

  @override
  String get dateOfBirth => 'Geburtsdatum';

  @override
  String get datePlanningCategory => 'Date-Planung';

  @override
  String get dateSchedulerAccept => 'Annehmen';

  @override
  String get dateSchedulerCancelConfirm =>
      'Bist du sicher, dass du dieses Date absagen möchtest?';

  @override
  String get dateSchedulerCancelTitle => 'Date absagen';

  @override
  String get dateSchedulerConfirmed => 'Date bestätigt!';

  @override
  String get dateSchedulerDecline => 'Ablehnen';

  @override
  String get dateSchedulerEnterTitle => 'Bitte gib einen Titel ein';

  @override
  String get dateSchedulerKeepDate => 'Date beibehalten';

  @override
  String get dateSchedulerNotesLabel => 'Notizen (optional)';

  @override
  String get dateSchedulerPlanningHint => 'z. B. Kaffee, Abendessen, Kino...';

  @override
  String get dateSchedulerReasonLabel => 'Grund (optional)';

  @override
  String get dateSchedulerReschedule => 'Verschieben';

  @override
  String get dateSchedulerRescheduleTitle => 'Date verschieben';

  @override
  String get dateSchedulerSchedule => 'Planen';

  @override
  String get dateSchedulerScheduled => 'Date geplant!';

  @override
  String get dateSchedulerTabPast => 'Vergangen';

  @override
  String get dateSchedulerTabPending => 'Ausstehend';

  @override
  String get dateSchedulerTabUpcoming => 'Bevorstehend';

  @override
  String get dateSchedulerTitle => 'Meine Dates';

  @override
  String get dateSchedulerWhatPlanning => 'Was hast du vor?';

  @override
  String dayNumber(int day) {
    return 'Tag $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count Tage Serie';
  }

  @override
  String dayStreakLabel(int days) {
    return '$days-Tage-Streak!';
  }

  @override
  String get days => 'Tage';

  @override
  String daysAgo(int count) {
    return 'vor $count Tagen';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAccount => 'Konto Löschen';

  @override
  String get deleteAccountConfirmation =>
      'Bist du sicher, dass du dein Konto löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden und alle deine Daten werden dauerhaft gelöscht.';

  @override
  String get details => 'Details';

  @override
  String get difficultyLabel => 'Schwierigkeit';

  @override
  String directMessageCost(int cost) {
    return 'Direktnachrichten kosten $cost Coins. Moechtest du mehr Coins kaufen?';
  }

  @override
  String get discover => 'Netzwerk';

  @override
  String discoveryError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get discoveryFilterAll => 'Alle';

  @override
  String get discoveryFilterGuides => 'Guides';

  @override
  String get discoveryFilterLiked => 'Verbunden';

  @override
  String get discoveryFilterMatches => 'Matches';

  @override
  String get discoveryFilterPassed => 'Abgelehnt';

  @override
  String get discoveryFilterSkipped => 'Erkundet';

  @override
  String get discoveryFilterSuperLiked => 'Priorität';

  @override
  String get discoveryFilterTravelers => 'Reisende';

  @override
  String get discoveryPreferencesTitle => 'Entdeckungseinstellungen';

  @override
  String get discoveryPreferencesTooltip => 'Entdeckungseinstellungen';

  @override
  String get discoverySwitchToGrid => 'Zum Rastermodus wechseln';

  @override
  String get discoverySwitchToSwipe => 'Zum Wischmodus wechseln';

  @override
  String get dismiss => 'Schließen';

  @override
  String get distance => 'Entfernung';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Dokument nicht verfuegbar';

  @override
  String get documentNotAvailableDescription =>
      'Dieses Dokument ist noch nicht in deiner Sprache verfuegbar.';

  @override
  String get done => 'Fertig';

  @override
  String get dontHaveAccount => 'Haben Sie noch kein Konto?';

  @override
  String get download => 'Herunterladen';

  @override
  String downloadProgress(int current, int total) {
    return '$current von $total';
  }

  @override
  String downloadingLanguage(String language) {
    return '$language wird heruntergeladen...';
  }

  @override
  String get downloadingTranslationData =>
      'Übersetzungsdaten werden heruntergeladen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editInterests => 'Interessen bearbeiten';

  @override
  String get editNickname => 'Spitzname Bearbeiten';

  @override
  String get editProfile => 'Profil Bearbeiten';

  @override
  String get editVoiceComingSoon => 'Stimme bearbeiten kommt bald';

  @override
  String get education => 'Bildung';

  @override
  String get email => 'E-Mail';

  @override
  String get emailInvalid => 'Bitte geben Sie eine gültige E-Mail ein';

  @override
  String get emailRequired => 'E-Mail ist erforderlich';

  @override
  String get emergencyCategory => 'Notfall';

  @override
  String get emptyStateErrorMessage =>
      'Wir konnten diesen Inhalt nicht laden. Bitte versuche es erneut.';

  @override
  String get emptyStateErrorTitle => 'Etwas ist schiefgelaufen';

  @override
  String get emptyStateNoInternetMessage =>
      'Bitte überprüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get emptyStateNoInternetTitle => 'Keine Verbindung';

  @override
  String get emptyStateNoLikesMessage =>
      'Vervollständige dein Profil, um mehr Likes zu bekommen!';

  @override
  String get emptyStateNoLikesTitle => 'Noch keine Likes';

  @override
  String get emptyStateNoMatchesMessage =>
      'Fang an zu swipen und finde dein perfektes Match!';

  @override
  String get emptyStateNoMatchesTitle => 'Noch keine Matches';

  @override
  String get emptyStateNoMessagesMessage =>
      'Wenn du mit jemandem matchst, kannst du hier chatten.';

  @override
  String get emptyStateNoMessagesTitle => 'Keine Nachrichten';

  @override
  String get emptyStateNoNotificationsMessage =>
      'Du hast keine neuen Benachrichtigungen.';

  @override
  String get emptyStateNoNotificationsTitle => 'Alles erledigt!';

  @override
  String get emptyStateNoResultsMessage =>
      'Versuche, deine Suche oder Filter anzupassen.';

  @override
  String get emptyStateNoResultsTitle => 'Keine Ergebnisse gefunden';

  @override
  String get enableAutoTranslation => 'Automatische Übersetzung aktivieren';

  @override
  String get enableNotifications => 'Benachrichtigungen Aktivieren';

  @override
  String get enterAmount => 'Betrag eingeben';

  @override
  String get enterNickname => 'Spitzname eingeben';

  @override
  String get enterNicknameHint => 'Nickname eingeben';

  @override
  String get enterNicknameToFind =>
      'Gib einen Spitznamen ein, um jemanden direkt zu finden';

  @override
  String get enterRejectionReason => 'Ablehnungsgrund eingeben';

  @override
  String error(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get errorLoadingDocument => 'Fehler beim Laden des Dokuments';

  @override
  String get errorSearchingTryAgain => 'Suchfehler. Bitte erneut versuchen.';

  @override
  String get eventsAboutThisEvent => 'Ueber dieses Event';

  @override
  String get eventsApplyFilters => 'Filter anwenden';

  @override
  String get eventsAttendees => 'Teilnehmer';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max nehmen teil';
  }

  @override
  String get eventsBeFirstToSay => 'Schreib die erste Nachricht!';

  @override
  String get eventsCategory => 'Kategorie';

  @override
  String get eventsChatWithAttendees => 'Mit anderen Teilnehmern chatten';

  @override
  String get eventsCheckBackLater =>
      'Schau spaeter nochmal vorbei oder erstelle dein eigenes Event!';

  @override
  String get eventsCreateEvent => 'Event erstellen';

  @override
  String get eventsCreatedSuccessfully => 'Event erfolgreich erstellt!';

  @override
  String get eventsDateRange => 'Zeitraum';

  @override
  String get eventsDeleted => 'Event gelöscht';

  @override
  String get eventsDescription => 'Beschreibung';

  @override
  String get eventsDistance => 'Entfernung';

  @override
  String get eventsEndDateTime => 'Enddatum & Uhrzeit';

  @override
  String get eventsErrorLoadingMessages => 'Fehler beim Laden der Nachrichten';

  @override
  String get eventsEventFull => 'Event voll';

  @override
  String get eventsEventTitle => 'Event-Titel';

  @override
  String get eventsFilterEvents => 'Events filtern';

  @override
  String get eventsFreeEvent => 'Kostenloses Event';

  @override
  String get eventsFreeLabel => 'KOSTENLOS';

  @override
  String get eventsFullLabel => 'Voll';

  @override
  String eventsGoing(Object count) {
    return '$count nehmen teil';
  }

  @override
  String get eventsGoingLabel => 'Dabei';

  @override
  String get eventsGroupChatTooltip => 'Event-Gruppenchat';

  @override
  String get eventsJoinEvent => 'Event beitreten';

  @override
  String get eventsJoinLabel => 'Beitreten';

  @override
  String eventsKmAwayFormat(String km) {
    return '$km km entfernt';
  }

  @override
  String get eventsLanguageExchange => 'Sprachaustausch';

  @override
  String get eventsLanguagePairs => 'Sprachpaare (z.B. Spanisch ↔ Englisch)';

  @override
  String eventsLanguages(String languages) {
    return 'Sprachen: $languages';
  }

  @override
  String get eventsLocation => 'Standort';

  @override
  String eventsMAwayFormat(Object meters) {
    return '$meters m entfernt';
  }

  @override
  String get eventsMaxAttendees => 'Max. Teilnehmer';

  @override
  String get eventsNoAttendeesYet => 'Noch keine Teilnehmer. Sei der Erste!';

  @override
  String get eventsNoEventsFound => 'Keine Events gefunden';

  @override
  String get eventsNoMessagesYet => 'Noch keine Nachrichten';

  @override
  String get eventsRequired => 'Erforderlich';

  @override
  String get eventsRsvpCancelled => 'Teilnahme abgesagt';

  @override
  String get eventsRsvpUpdated => 'Teilnahme aktualisiert!';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count Plaetze uebrig';
  }

  @override
  String get eventsStartDateTime => 'Startdatum & Uhrzeit';

  @override
  String get eventsTabMyEvents => 'Meine Events';

  @override
  String get eventsTabNearby => 'In der Nähe';

  @override
  String get eventsTabUpcoming => 'Bevorstehend';

  @override
  String get eventsThisMonth => 'Diesen Monat';

  @override
  String get eventsThisWeekFilter => 'Diese Woche';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsToday => 'Heute';

  @override
  String get eventsTypeAMessage => 'Nachricht eingeben...';

  @override
  String get exit => 'Beenden';

  @override
  String get exitApp => 'App beenden?';

  @override
  String get exitAppConfirmation =>
      'Bist du sicher, dass du GreenGo beenden möchtest?';

  @override
  String get exploreLanguages => 'Sprachen entdecken';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km entfernt';
  }

  @override
  String get exploreMapError =>
      'Nutzer in der Nähe konnten nicht geladen werden';

  @override
  String get exploreMapExpandRadius => 'Radius erweitern';

  @override
  String get exploreMapExpandRadiusHint =>
      'Versuche deinen Suchradius zu vergrößern, um mehr Leute zu finden.';

  @override
  String get exploreMapNearbyUser => 'Nutzer in der Nähe';

  @override
  String get exploreMapNoOneNearby => 'Niemand in der Nähe';

  @override
  String get exploreMapOnlineNow => 'Jetzt online';

  @override
  String get exploreMapPeopleNearYou => 'Leute in deiner Nähe';

  @override
  String get exploreMapRadius => 'Radius:';

  @override
  String get exploreMapVisible => 'Sichtbar';

  @override
  String get exportMyDataGDPR => 'Meine Daten Exportieren (DSGVO)';

  @override
  String get exportingYourData => 'Daten werden exportiert...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Verlängern ($cost Münzen)';
  }

  @override
  String get extendTooltip => 'Verlängern';

  @override
  String failedToDownloadModel(String language) {
    return 'Download des $language-Modells fehlgeschlagen';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Einstellungen konnten nicht gespeichert werden';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Funktion nicht verfügbar bei $tier';
  }

  @override
  String get fillCategories => 'Fülle alle Kategorien aus';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Direkt';

  @override
  String get filterMessaged => 'Mit Nachrichten';

  @override
  String get filterNew => 'Neu';

  @override
  String get filterNewMessages => 'Neue';

  @override
  String get filterNotReplied => 'Ohne Antwort';

  @override
  String filteredFromTotal(int total) {
    return 'Gefiltert von $total';
  }

  @override
  String get filters => 'Filter';

  @override
  String get finish => 'Beenden';

  @override
  String get firstName => 'Vorname';

  @override
  String get firstTo30Wins => 'Wer zuerst 30 hat, gewinnt!';

  @override
  String get flashcardReviewLabel => 'Karteikarten';

  @override
  String get flirtyCategory => 'Flirtend';

  @override
  String get foodDiningCategory => 'Essen & Trinken';

  @override
  String get forgotPassword => 'Passwort Vergessen?';

  @override
  String freeActionsRemaining(int count) {
    return '$count kostenlose Aktionen heute verbleibend';
  }

  @override
  String get friendship => 'Freundschaft';

  @override
  String get gameAbandon => 'Aufgeben';

  @override
  String get gameAbandonLoseMessage =>
      'Du verlierst dieses Spiel, wenn du jetzt gehst.';

  @override
  String get gameAbandonProgressMessage =>
      'Du verlierst deinen Fortschritt und kehrst zur Lobby zurück.';

  @override
  String get gameAbandonTitle => 'Spiel aufgeben?';

  @override
  String get gameAbandonTooltip => 'Spiel aufgeben';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Gib ein Wort mit \"$letter\" ein...';
  }

  @override
  String get gameCategoriesFilled => 'ausgefüllt';

  @override
  String get gameCategoriesNewLetter => 'Neuer Buchstabe!';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — beginnt mit \"$letter\"';
  }

  @override
  String get gameCategoriesTapToFill =>
      'Tippe auf eine Kategorie, um sie auszufüllen!';

  @override
  String get gameCategoriesTimesUp =>
      'Zeit abgelaufen! Warte auf die nächste Runde...';

  @override
  String get gameCategoriesTitle => 'Kategorien';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      'Wort bereits in einer anderen Kategorie verwendet!';

  @override
  String get gameCategoryAnimals => 'Tiere';

  @override
  String get gameCategoryClothing => 'Kleidung';

  @override
  String get gameCategoryColors => 'Farben';

  @override
  String get gameCategoryCountries => 'Länder';

  @override
  String get gameCategoryFood => 'Essen';

  @override
  String get gameCategoryNature => 'Natur';

  @override
  String get gameCategoryProfessions => 'Berufe';

  @override
  String get gameCategorySports => 'Sport';

  @override
  String get gameCategoryTransport => 'Verkehrsmittel';

  @override
  String get gameChainBreak => 'KETTENBRUCH!';

  @override
  String get gameChainNextMustStartWith =>
      'Das nächste Wort muss beginnen mit: ';

  @override
  String get gameChainNoWordsYet => 'Noch keine Wörter!';

  @override
  String get gameChainStartWithAnyWord =>
      'Starte die Kette mit einem beliebigen Wort';

  @override
  String get gameChainTitle => 'Vokabelkette';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Gib ein Wort mit \"$letter\" ein...';
  }

  @override
  String get gameChainTypeToStartHint =>
      'Gib ein Wort ein, um die Kette zu starten...';

  @override
  String gameChainWordsChained(int count) {
    return '$count Wörter verkettet';
  }

  @override
  String get gameCorrect => 'Richtig!';

  @override
  String get gameDefaultPlayerName => 'Spieler';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff vorne';
  }

  @override
  String get gameGrammarDuelAnswered => 'Beantwortet';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff hinten';
  }

  @override
  String get gameGrammarDuelFast => 'SCHNELL!';

  @override
  String get gameGrammarDuelGrammarQuestion => 'GRAMMATIKFRAGE';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '+$points Punkte!';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return 'x$count Serie!';
  }

  @override
  String get gameGrammarDuelThinking => 'Überlegt...';

  @override
  String get gameGrammarDuelTitle => 'Grammatik-Duell';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => 'Falsche Antwort!';

  @override
  String get gameInvalidAnswer => 'Ungültig!';

  @override
  String get gameLanguageBrazilianPortuguese => 'Brasilianisches Portugiesisch';

  @override
  String get gameLanguageEnglish => 'Englisch';

  @override
  String get gameLanguageFrench => 'Französisch';

  @override
  String get gameLanguageGerman => 'Deutsch';

  @override
  String get gameLanguageItalian => 'Italienisch';

  @override
  String get gameLanguageJapanese => 'Japanisch';

  @override
  String get gameLanguagePortuguese => 'Portugiesisch';

  @override
  String get gameLanguageSpanish => 'Spanisch';

  @override
  String get gameLeave => 'Verlassen';

  @override
  String get gameOpponent => 'Gegner';

  @override
  String get gameOver => 'Spiel Vorbei';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Versuch $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      'Du darfst das Wort selbst nicht in deinem Hinweis verwenden!';

  @override
  String get gamePictureGuessClues => 'HINWEISE';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count Hinweis(e) gesendet';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return 'Richtig! +$points Punkte';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      'Richtig! Warte auf Rundenende...';

  @override
  String get gamePictureGuessDescriber => 'BESCHREIBER';

  @override
  String get gamePictureGuessDescriberRules =>
      'Gib Hinweise, damit die anderen raten können. Keine direkten Übersetzungen oder Buchstabierhilfen!';

  @override
  String get gamePictureGuessGuessTheWord => 'Errate das Wort!';

  @override
  String get gamePictureGuessGuessTheWordUpper => 'ERRATE DAS WORT!';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'Keine Versuche mehr — warte auf Rundenende';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'Keine Versuche mehr in dieser Runde';

  @override
  String get gamePictureGuessTheWordWas => 'Das Wort war:';

  @override
  String get gamePictureGuessTitle => 'Bilderraten';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Gib einen Hinweis ein (keine direkten Übersetzungen!)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Gib deine Antwort ein... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'Warte auf Hinweise...';

  @override
  String get gamePictureGuessWaitingForOthers => 'Warte auf andere...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Falsch geraten: \"$guess\"';
  }

  @override
  String get gamePictureGuessYouAreDescriber => 'Du bist der BESCHREIBER!';

  @override
  String get gamePictureGuessYourWord => 'DEIN WORT';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      'Antwort abgeschickt! Warte auf andere...';

  @override
  String get gamePlayCategoriesHeader => 'KATEGORIEN';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Kategorie: $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return 'Richtig! +$points Pkt.';
  }

  @override
  String get gamePlayDescribeThisWord => 'BESCHREIBE DIESES WORT!';

  @override
  String get gamePlayDescribeWordHint =>
      'Beschreibe das Wort (nicht aussprechen!)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name beschreibt ein Wort...';
  }

  @override
  String get gamePlayDoNotSayWord => 'Sage das Wort selbst nicht!';

  @override
  String get gamePlayGuessTheWord => 'ERRATE DAS WORT';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Falsch. Die Antwort war \"$answer\"';
  }

  @override
  String get gamePlayLeaderboard => 'BESTENLISTE';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Nenne ein $language-Wort mit \"$letter\"';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Nenne ein Wort in \"$category\" mit \"$letter\"';
  }

  @override
  String get gamePlayNextWordMustStartWith =>
      'DAS NÄCHSTE WORT MUSS BEGINNEN MIT';

  @override
  String get gamePlayNoWordsStartChain =>
      'Noch keine Wörter – starte die Kette!';

  @override
  String get gamePlayPickLetterNameWord =>
      'Wähle einen Buchstaben und nenne ein Wort!';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name wählt aus...';
  }

  @override
  String gamePlayPlayerIsThinking(String name) {
    return '$name überlegt...';
  }

  @override
  String gamePlayThemeLabel(String theme) {
    return 'Thema: $theme';
  }

  @override
  String get gamePlayTranslateThisWord => 'ÜBERSETZE DIESES WORT';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Gib ein Wort mit \"$prompt\" ein...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Gib ein Wort mit \"$prompt\" ein...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Gib die Übersetzung ein...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      'Gib ein Wort ein, das diese Buchstaben enthält!';

  @override
  String get gamePlayTypeYourAnswerHint => 'Gib deine Antwort ein...';

  @override
  String get gamePlayTypeYourGuessBelow => 'Gib unten deine Antwort ein!';

  @override
  String get gamePlayTypeYourGuessHint => 'Gib deine Antwort ein...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Nutze den Chat, um das Wort für andere Spieler zu beschreiben';

  @override
  String get gamePlayWaitingForOpponent => 'Warte auf Gegner...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Wort mit \"$letter\"...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Wort mit \"$prompt\"...';
  }

  @override
  String get gamePlayYourTurnFlipCards =>
      'Du bist dran – decke zwei Karten auf!';

  @override
  String gamePlayersTurn(String name) {
    return '$name ist dran';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points Pkt.';
  }

  @override
  String get gamePositionFirst => '1.';

  @override
  String gamePositionNth(int pos) {
    return '$pos.';
  }

  @override
  String get gamePositionSecond => '2.';

  @override
  String get gamePositionThird => '3.';

  @override
  String get gameResultsBackToLobby => 'Zurück zur Lobby';

  @override
  String get gameResultsBaseXp => 'Basis-XP';

  @override
  String get gameResultsCoinsEarned => 'Verdiente Münzen';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Schwierigkeitsbonus (Lv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'ENDSTAND';

  @override
  String get gameResultsGameOver => 'SPIEL VORBEI';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'Nicht genug Münzen ($amount benötigt)';
  }

  @override
  String get gameResultsPlayAgain => 'Nochmal spielen';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'ERHALTENE BELOHNUNGEN';

  @override
  String get gameResultsTotalXp => 'Gesamt-XP';

  @override
  String get gameResultsVictory => 'SIEG!';

  @override
  String get gameResultsWhatYouLearned => 'WAS DU GELERNT HAST';

  @override
  String get gameResultsWinner => 'Gewinner';

  @override
  String get gameResultsWinnerBonus => 'Siegerbonus';

  @override
  String get gameResultsYouWon => 'Du hast gewonnen!';

  @override
  String gameRoundCounter(int current, int total) {
    return 'Runde $current/$total';
  }

  @override
  String gameRoundNumber(int number) {
    return 'Runde $number';
  }

  @override
  String gameScorePts(int score) {
    return '$score Pkt.';
  }

  @override
  String get gameSnapsNoMatch => 'Kein Paar';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total Paare gefunden';
  }

  @override
  String get gameSnapsTitle => 'Sprach-Snaps';

  @override
  String get gameSnapsYourTurnFlipCards => 'DU BIST DRAN — Decke 2 Karten auf!';

  @override
  String get gameSomeone => 'Jemand';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Nenne ein Wort mit \"$letter\"';
  }

  @override
  String get gameTapplesPickLetterFromWheel =>
      'Wähle einen Buchstaben vom Rad!';

  @override
  String get gameTapplesPickLetterNameWord =>
      'Wähle einen Buchstaben, nenne ein Wort';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name hat ein Leben verloren';
  }

  @override
  String get gameTapplesTimeUp => 'ZEIT UM!';

  @override
  String get gameTapplesTitle => 'Sprach-Tapples';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Wort mit \"$letter\"...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount Wörter verwendet  •  $lettersCount Buchstaben übrig';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Richtig';

  @override
  String get gameTranslationRaceFirstTo30 => 'Wer zuerst 30 hat, gewinnt!';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'R$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Übersetzungswettlauf';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Übersetze auf $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'Warte auf andere... $answered/$total haben geantwortet';
  }

  @override
  String get gameWaitForYourTurn => 'Warte, bis du dran bist...';

  @override
  String get gameWaiting => 'Warten';

  @override
  String get gameWaitingCancelReady => 'Bereitschaft zurückziehen';

  @override
  String get gameWaitingCountdownGo => 'LOS!';

  @override
  String get gameWaitingDisconnected => 'Getrennt';

  @override
  String get gameWaitingEllipsis => 'Warten...';

  @override
  String get gameWaitingForPlayers => 'Warte auf Spieler...';

  @override
  String get gameWaitingGetReady => 'Mach dich bereit...';

  @override
  String get gameWaitingHost => 'GASTGEBER';

  @override
  String get gameWaitingInviteCodeCopied => 'Einladungscode kopiert!';

  @override
  String get gameWaitingInviteCodeHeader => 'EINLADUNGSCODE';

  @override
  String get gameWaitingInvitePlayer => 'Spieler einladen';

  @override
  String get gameWaitingLeaveRoom => 'Raum verlassen';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Level $level';
  }

  @override
  String get gameWaitingNotReady => 'Nicht bereit';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count nicht bereit)';
  }

  @override
  String get gameWaitingPlayersHeader => 'SPIELER';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count Spieler im Raum';
  }

  @override
  String get gameWaitingReady => 'Bereit';

  @override
  String get gameWaitingReadyUp => 'Bereit machen';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count Runden';
  }

  @override
  String get gameWaitingShareCode =>
      'Teile diesen Code mit Freunden zum Beitreten';

  @override
  String get gameWaitingStartGame => 'Spiel starten';

  @override
  String get gameWordAlreadyUsed => 'Wort bereits verwendet!';

  @override
  String get gameWordBombBoom => 'BUMM!';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'Das Wort muss \"$prompt\" enthalten';
  }

  @override
  String get gameWordBombReport => 'Melden';

  @override
  String get gameWordBombReportContent =>
      'Dieses Wort als ungültig oder unangemessen melden.';

  @override
  String gameWordBombReportTitle(String word) {
    return '\"$word\" melden?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife =>
      'Zeit abgelaufen! Du hast ein Leben verloren.';

  @override
  String get gameWordBombTitle => 'Wortbombe';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Gib ein Wort mit \"$prompt\" ein...';
  }

  @override
  String get gameWordBombUsedWords => 'Verwendete Wörter';

  @override
  String get gameWordBombWordReported => 'Wort gemeldet';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count Wörter verwendet';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'Das Wort muss mit \"$letter\" beginnen';
  }

  @override
  String get gameWrong => 'Falsch';

  @override
  String get gameYou => 'Du';

  @override
  String get gameYourTurn => 'DU BIST DRAN!';

  @override
  String get gamificationAchievements => 'Erfolge';

  @override
  String get gamificationAll => 'Alle';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '$name abgeschlossen!';
  }

  @override
  String get gamificationClaim => 'Einfordern';

  @override
  String get gamificationClaimReward => 'Belohnung einfordern';

  @override
  String get gamificationCoinsAvailable => 'Verfügbare Münzen';

  @override
  String get gamificationDaily => 'Täglich';

  @override
  String get gamificationDailyChallenges => 'Tägliche Herausforderungen';

  @override
  String get gamificationDayStreak => 'Tages-Serie';

  @override
  String get gamificationDone => 'Fertig';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Verdient am $date';
  }

  @override
  String get gamificationEasy => 'Einfach';

  @override
  String get gamificationEngagement => 'Engagement';

  @override
  String get gamificationEpic => 'Episch';

  @override
  String get gamificationExperiencePoints => 'Erfahrungspunkte';

  @override
  String get gamificationGlobal => 'Global';

  @override
  String get gamificationHard => 'Schwer';

  @override
  String get gamificationLeaderboard => 'Rangliste';

  @override
  String gamificationLevel(Object level) {
    return 'Level $level';
  }

  @override
  String get gamificationLevelLabel => 'LEVEL';

  @override
  String gamificationLevelShort(Object level) {
    return 'Lv.$level';
  }

  @override
  String get gamificationLoadingAchievements => 'Erfolge werden geladen...';

  @override
  String get gamificationLoadingChallenges =>
      'Herausforderungen werden geladen...';

  @override
  String get gamificationLoadingRankings => 'Rangliste wird geladen...';

  @override
  String get gamificationMedium => 'Mittel';

  @override
  String get gamificationMilestones => 'Meilensteine';

  @override
  String get gamificationMonthly => 'Monat';

  @override
  String get gamificationMyProgress => 'Mein Fortschritt';

  @override
  String get gamificationNoAchievements => 'Keine Erfolge gefunden';

  @override
  String get gamificationNoAchievementsInCategory =>
      'Keine Erfolge in dieser Kategorie';

  @override
  String get gamificationNoChallenges => 'Keine Herausforderungen verfügbar';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'Keine $type Herausforderungen verfügbar';
  }

  @override
  String get gamificationNoLeaderboard => 'Keine Ranglistendaten';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Premium-Mitglied';

  @override
  String get gamificationProgress => 'Fortschritt';

  @override
  String get gamificationRank => 'RANG';

  @override
  String get gamificationRankLabel => 'Rang';

  @override
  String get gamificationRegional => 'Regional';

  @override
  String gamificationReward(Object amount, Object type) {
    return 'Belohnung: $amount $type';
  }

  @override
  String get gamificationSocial => 'Sozial';

  @override
  String get gamificationSpecial => 'Spezial';

  @override
  String get gamificationTotal => 'Gesamt';

  @override
  String get gamificationUnlocked => 'Freigeschaltet';

  @override
  String get gamificationVerifiedUser => 'Verifizierter Nutzer';

  @override
  String get gamificationVipMember => 'VIP-Mitglied';

  @override
  String get gamificationWeekly => 'Wöchentlich';

  @override
  String get gamificationXpAvailable => 'Verfügbare XP';

  @override
  String get gamificationYearly => 'Jahr';

  @override
  String get gamificationYourPosition => 'Deine Position';

  @override
  String get gender => 'Geschlecht';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get giftCategoryAll => 'Alle';

  @override
  String giftFromSender(Object name) {
    return 'Von $name';
  }

  @override
  String get giftGetCoins => 'Münzen holen';

  @override
  String get giftNoGiftsAvailable => 'Keine Geschenke verfügbar';

  @override
  String get giftNoGiftsInCategory => 'Keine Geschenke in dieser Kategorie';

  @override
  String get giftNoGiftsYet => 'Noch keine Geschenke';

  @override
  String get giftNotEnoughCoins => 'Nicht genügend Münzen';

  @override
  String giftPriceCoins(Object price) {
    return '$price Münzen';
  }

  @override
  String get giftReceivedGifts => 'Erhaltene Geschenke';

  @override
  String get giftReceivedGiftsEmpty =>
      'Geschenke, die du erhältst, erscheinen hier';

  @override
  String get giftSendGift => 'Geschenk senden';

  @override
  String giftSendGiftTo(Object name) {
    return 'Geschenk an $name senden';
  }

  @override
  String get giftSending => 'Wird gesendet...';

  @override
  String giftSentTo(Object name) {
    return 'Geschenk an $name gesendet!';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'Du hast $available Münzen.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'Du brauchst $required Münzen für dieses Geschenk.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'Du brauchst $shortfall weitere Münzen.';
  }

  @override
  String get gold => 'Gold';

  @override
  String get grantAlbumAccess => 'Mein Album teilen';

  @override
  String get greatInterestsHelp =>
      'Super! Deine Interessen helfen uns, bessere Matches zu finden';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Begrüßungen';

  @override
  String get guideBadge => 'Guide';

  @override
  String get height => 'Größe';

  @override
  String get helpAndSupport => 'Hilfe & Support';

  @override
  String get helpOthersFindYou =>
      'Hilf anderen, dich in sozialen Medien zu finden';

  @override
  String get hours => 'Stunden';

  @override
  String get icebreakersCategoryCompliments => 'Komplimente';

  @override
  String get icebreakersCategoryDateIdeas => 'Date-Ideen';

  @override
  String get icebreakersCategoryDeep => 'Tiefgründig';

  @override
  String get icebreakersCategoryDreams => 'Träume';

  @override
  String get icebreakersCategoryFood => 'Essen';

  @override
  String get icebreakersCategoryFunny => 'Lustig';

  @override
  String get icebreakersCategoryHobbies => 'Hobbys';

  @override
  String get icebreakersCategoryHypothetical => 'Hypothetisch';

  @override
  String get icebreakersCategoryMovies => 'Filme';

  @override
  String get icebreakersCategoryMusic => 'Musik';

  @override
  String get icebreakersCategoryPersonality => 'Persönlichkeit';

  @override
  String get icebreakersCategoryTravel => 'Reisen';

  @override
  String get icebreakersCategoryTwoTruths => 'Zwei Wahrheiten';

  @override
  String get icebreakersCategoryWouldYouRather => 'Würdest du lieber';

  @override
  String get icebreakersLabel => 'Eisbrecher';

  @override
  String get icebreakersNoneInCategory =>
      'Keine Eisbrecher in dieser Kategorie';

  @override
  String get icebreakersQuickAnswers => 'Schnellantworten:';

  @override
  String get icebreakersSendAnIcebreaker => 'Einen Eisbrecher senden';

  @override
  String icebreakersSendTo(Object name) {
    return 'An $name senden';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Ohne Antwort senden';

  @override
  String get icebreakersTitle => 'Eisbrecher';

  @override
  String get idiomsCategory => 'Redewendungen';

  @override
  String get incognitoMode => 'Inkognito-Modus';

  @override
  String get incognitoModeDescription =>
      'Verstecke dein Profil in der Entdeckung';

  @override
  String get incorrectAnswer => 'Falsch';

  @override
  String get infoUpdatedMessage =>
      'Deine Basisinformationen wurden gespeichert';

  @override
  String get infoUpdatedTitle => 'Info aktualisiert!';

  @override
  String get insufficientCoins => 'Nicht genügend Münzen';

  @override
  String get insufficientCoinsTitle => 'Nicht genuegend Coins';

  @override
  String get interestArt => 'Kunst';

  @override
  String get interestBeach => 'Strand';

  @override
  String get interestBeer => 'Bier';

  @override
  String get interestBusiness => 'Geschäft';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestCats => 'Katzen';

  @override
  String get interestCoffee => 'Kaffee';

  @override
  String get interestCooking => 'Kochen';

  @override
  String get interestCycling => 'Radfahren';

  @override
  String get interestDance => 'Tanzen';

  @override
  String get interestDancing => 'Tanzen';

  @override
  String get interestDogs => 'Hunde';

  @override
  String get interestEntrepreneurship => 'Unternehmertum';

  @override
  String get interestEnvironment => 'Umwelt';

  @override
  String get interestFashion => 'Mode';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Essen';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestHiking => 'Wandern';

  @override
  String get interestHistory => 'Geschichte';

  @override
  String get interestInvesting => 'Investieren';

  @override
  String get interestLanguages => 'Sprachen';

  @override
  String get interestMeditation => 'Meditation';

  @override
  String get interestMountains => 'Berge';

  @override
  String get interestMovies => 'Filme';

  @override
  String get interestMusic => 'Musik';

  @override
  String get interestNature => 'Natur';

  @override
  String get interestPets => 'Haustiere';

  @override
  String get interestPhotography => 'Fotografie';

  @override
  String get interestPoetry => 'Poesie';

  @override
  String get interestPolitics => 'Politik';

  @override
  String get interestReading => 'Lesen';

  @override
  String get interestRunning => 'Laufen';

  @override
  String get interestScience => 'Wissenschaft';

  @override
  String get interestSkiing => 'Skifahren';

  @override
  String get interestSnowboarding => 'Snowboarden';

  @override
  String get interestSpirituality => 'Spiritualität';

  @override
  String get interestSports => 'Sport';

  @override
  String get interestSurfing => 'Surfen';

  @override
  String get interestSwimming => 'Schwimmen';

  @override
  String get interestTeaching => 'Lehren';

  @override
  String get interestTechnology => 'Technologie';

  @override
  String get interestTravel => 'Reisen';

  @override
  String get interestVegan => 'Vegan';

  @override
  String get interestVegetarian => 'Vegetarisch';

  @override
  String get interestVolunteering => 'Freiwilligenarbeit';

  @override
  String get interestWine => 'Wein';

  @override
  String get interestWriting => 'Schreiben';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Interessen';

  @override
  String interestsCount(int count) {
    return '$count Interessen';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max Interessen ausgewählt';
  }

  @override
  String get interestsUpdatedMessage => 'Deine Interessen wurden gespeichert';

  @override
  String get interestsUpdatedTitle => 'Interessen aktualisiert!';

  @override
  String get invalidWord => 'Ungültiges Wort';

  @override
  String get inviteCodeCopied => 'Einladungscode kopiert!';

  @override
  String get inviteFriends => 'Freunde Einladen';

  @override
  String get itsAMatch => 'Lass uns tauschen!';

  @override
  String get joinMessage =>
      'Treten Sie GreenGoChat bei und finden Sie Ihren perfekten Partner';

  @override
  String get keepSwiping => 'Weiter Wischen';

  @override
  String get langMatchBadge => 'Sprachmatch';

  @override
  String get language => 'Sprache';

  @override
  String languageChangedTo(String language) {
    return 'Sprache geändert zu $language';
  }

  @override
  String get languagePacksBtn => 'Sprachpakete';

  @override
  String get languagePacksShopTitle => 'Sprachpakete-Shop';

  @override
  String get languagesToDownloadLabel => 'Sprachen zum Herunterladen:';

  @override
  String get lastName => 'Nachname';

  @override
  String get lastUpdated => 'Zuletzt aktualisiert';

  @override
  String get leaderboardSubtitle => 'Globale und regionale Ranglisten';

  @override
  String get leaderboardTitle => 'Bestenliste';

  @override
  String get learn => 'Lernen';

  @override
  String get learningAccuracy => 'Genauigkeit';

  @override
  String get learningActiveThisWeek => 'Diese Woche aktiv';

  @override
  String get learningAddLessonSection => 'Lektionsabschnitt hinzufügen';

  @override
  String get learningAiConversationCoach => 'AI Konversations-Coach';

  @override
  String get learningAllCategories => 'Alle Kategorien';

  @override
  String get learningAllLessons => 'Alle Lektionen';

  @override
  String get learningAllLevels => 'Alle Stufen';

  @override
  String get learningAmount => 'Betrag';

  @override
  String get learningAmountLabel => 'Betrag';

  @override
  String get learningAnalytics => 'Analysen';

  @override
  String learningAnswer(Object answer) {
    return 'Antwort: $answer';
  }

  @override
  String get learningApplyFilters => 'Filter anwenden';

  @override
  String get learningAreasToImprove => 'Verbesserungsbereiche';

  @override
  String get learningAvailableBalance => 'Verfügbares Guthaben';

  @override
  String get learningAverageRating => 'Durchschnittliche Bewertung';

  @override
  String get learningBeginnerProgress => 'Anfänger-Fortschritt';

  @override
  String get learningBonusCoins => 'Bonusmünzen';

  @override
  String get learningCategory => 'Kategorie';

  @override
  String get learningCategoryProgress => 'Kategoriefortschritt';

  @override
  String get learningCheck => 'Prüfen';

  @override
  String get learningCheckBackSoon => 'Schau bald wieder vorbei!';

  @override
  String get learningCoachSessionCost =>
      '10 Münzen/Sitzung  |  25 XP Belohnung';

  @override
  String get learningContinue => 'Weiter';

  @override
  String get learningCorrect => 'Richtig!';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Richtig: $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'Richtige Antwort: $answer';
  }

  @override
  String get learningCorrectAnswers => 'Richtige Antworten';

  @override
  String get learningCorrectLabel => 'Richtig';

  @override
  String get learningCorrections => 'Korrekturen';

  @override
  String get learningCreateLesson => 'Lektion erstellen';

  @override
  String get learningCreateNewLesson => 'Neue Lektion erstellen';

  @override
  String get learningCustomPackTitleHint =>
      'z. B. \"Spanische Begrüßungen fürs Dating\"';

  @override
  String get learningDescribeImage => 'Beschreibe dieses Bild';

  @override
  String get learningDescriptionHint => 'Was werden die Schüler lernen?';

  @override
  String get learningDescriptionLabel => 'Beschreibung';

  @override
  String get learningDifficultyLevel => 'Schwierigkeitsgrad';

  @override
  String get learningDone => 'Fertig';

  @override
  String get learningDraftSave => 'Entwurf speichern';

  @override
  String get learningDraftSaved => 'Entwurf gespeichert!';

  @override
  String get learningEarned => 'Verdient';

  @override
  String get learningEdit => 'Bearbeiten';

  @override
  String get learningEndSession => 'Sitzung beenden';

  @override
  String get learningEndSessionBody =>
      'Dein aktueller Sitzungsfortschritt geht verloren. Möchtest du die Sitzung beenden und zuerst dein Ergebnis sehen?';

  @override
  String get learningEndSessionQuestion => 'Sitzung beenden?';

  @override
  String get learningExit => 'Beenden';

  @override
  String get learningFalse => 'Falsch';

  @override
  String get learningFilterAll => 'Alle';

  @override
  String get learningFilterDraft => 'Entwurf';

  @override
  String get learningFilterLessons => 'Lektionen filtern';

  @override
  String get learningFilterPublished => 'Veröffentlicht';

  @override
  String get learningFilterUnderReview => 'In Überprüfung';

  @override
  String get learningFluency => 'Sprachfluss';

  @override
  String get learningFree => 'KOSTENLOS';

  @override
  String get learningGoBack => 'Zurück';

  @override
  String get learningGoalCompleteLessons => '5 Lektionen abschließen';

  @override
  String get learningGoalEarnXp => '500 XP verdienen';

  @override
  String get learningGoalPracticeMinutes => '30 Minuten üben';

  @override
  String get learningGrammar => 'Grammatik';

  @override
  String get learningHint => 'Hinweis';

  @override
  String get learningLangBrazilianPortuguese => 'Brasilianisches Portugiesisch';

  @override
  String get learningLangEnglish => 'Englisch';

  @override
  String get learningLangFrench => 'Französisch';

  @override
  String get learningLangGerman => 'Deutsch';

  @override
  String get learningLangItalian => 'Italienisch';

  @override
  String get learningLangPortuguese => 'Portugiesisch';

  @override
  String get learningLangSpanish => 'Spanisch';

  @override
  String get learningLanguagesSubtitle =>
      'Wähle bis zu 5 Sprachen aus. Das hilft uns, dich mit Muttersprachlern und Lernpartnern zu verbinden.';

  @override
  String get learningLanguagesTitle => 'Welche Sprachen möchtest du lernen?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Sprachen zum Lernen ($count/5)';
  }

  @override
  String get learningLastMonth => 'Letzter Monat';

  @override
  String learningLearnLanguage(Object language) {
    return '$language lernen';
  }

  @override
  String get learningLearned => 'Gelernt';

  @override
  String get learningLessonComplete => 'Lektion abgeschlossen!';

  @override
  String get learningLessonCompleteUpper => 'LEKTION ABGESCHLOSSEN!';

  @override
  String get learningLessonContent => 'Lektionsinhalt';

  @override
  String learningLessonNumber(Object number) {
    return 'Lektion $number';
  }

  @override
  String get learningLessonSubmitted => 'Lektion zur Überprüfung eingereicht!';

  @override
  String get learningLessonTitle => 'Lektionstitel';

  @override
  String get learningLessonTitleHint =>
      'z.B. \"Spanische Begrüßungen fürs Dating\"';

  @override
  String get learningLessonTitleLabel => 'Lektionstitel';

  @override
  String get learningLessonsLabel => 'Lektionen';

  @override
  String get learningLetsStart => 'Los geht\'s!';

  @override
  String get learningLevel => 'Stufe';

  @override
  String learningLevelBadge(Object level) {
    return 'LV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Stufe $level';
  }

  @override
  String get learningListen => 'Anhören';

  @override
  String get learningListening => 'Hört zu...';

  @override
  String get learningLongPressForTranslation => 'Lange drücken für Übersetzung';

  @override
  String get learningMessages => 'Nachrichten';

  @override
  String get learningMessagesSent => 'Nachrichten gesendet';

  @override
  String get learningMinimumWithdrawal => 'Mindestauszahlung: 50,00 \$';

  @override
  String get learningMonthlyEarnings => 'Monatliche Einnahmen';

  @override
  String get learningMyProgress => 'Mein Fortschritt';

  @override
  String get learningNativeLabel => '(Muttersprache)';

  @override
  String get learningNativeLanguage => 'Deine Muttersprache';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'Du brauchst mindestens $threshold%, um diese Lektion zu bestehen.';
  }

  @override
  String get learningNext => 'Weiter';

  @override
  String get learningNoExercisesInSection =>
      'Keine Übungen in diesem Abschnitt';

  @override
  String get learningNoLessonsAvailable => 'Noch keine Lektionen verfügbar';

  @override
  String get learningNoPacksFound => 'Keine Pakete gefunden';

  @override
  String get learningNoQuestionsAvailable => 'Noch keine Fragen verfügbar.';

  @override
  String get learningNotQuite => 'Nicht ganz';

  @override
  String get learningNotQuiteTitle => 'Noch nicht ganz...';

  @override
  String get learningOpenAiCoach => 'AI Coach öffnen';

  @override
  String learningPackFilter(Object category) {
    return 'Paket: $category';
  }

  @override
  String get learningPackPurchased => 'Paket erfolgreich gekauft!';

  @override
  String get learningPassageRevealed => 'Text (aufgedeckt)';

  @override
  String get learningPathTitle => 'Lernpfad';

  @override
  String get learningPlaying => 'Wiedergabe...';

  @override
  String get learningPleaseEnterDescription =>
      'Bitte eine Beschreibung eingeben';

  @override
  String get learningPleaseEnterTitle => 'Bitte einen Titel eingeben';

  @override
  String get learningPracticeAgain => 'Nochmal üben';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Veröffentlichte Lektionen';

  @override
  String get learningPurchased => 'Gekauft';

  @override
  String get learningPurchasedLessonsEmpty =>
      'Deine gekauften Lektionen erscheinen hier';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count Fragen in dieser Lektion';
  }

  @override
  String get learningQuickActions => 'Schnellaktionen';

  @override
  String get learningReadPassage => 'Lies den Text';

  @override
  String get learningRecentActivity => 'Letzte Aktivität';

  @override
  String get learningRecentMilestones => 'Letzte Meilensteine';

  @override
  String get learningRecentTransactions => 'Letzte Transaktionen';

  @override
  String get learningRequired => 'Erforderlich';

  @override
  String get learningResponseRecorded => 'Antwort aufgezeichnet';

  @override
  String get learningReview => 'Überprüfung';

  @override
  String get learningSearchLanguages => 'Sprachen suchen...';

  @override
  String get learningSectionEditorComingSoon =>
      'Abschnitts-Editor demnächst verfügbar!';

  @override
  String get learningSeeScore => 'Ergebnis anzeigen';

  @override
  String get learningSelectNativeLanguage => 'Wähle deine Muttersprache';

  @override
  String get learningSelectScenario => 'Wähle ein Szenario zum Beginnen';

  @override
  String get learningSelectScenarioFirst => 'Wähle zuerst ein Szenario...';

  @override
  String get learningSessionComplete => 'Sitzung abgeschlossen!';

  @override
  String get learningSessionSummary => 'Sitzungszusammenfassung';

  @override
  String get learningShowAll => 'Alle anzeigen';

  @override
  String get learningShowPassageText => 'Text anzeigen';

  @override
  String get learningSkip => 'Überspringen';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return '$price Münzen ausgeben, um diese Lektion freizuschalten?';
  }

  @override
  String get learningStartFlashcards => 'Karteikarten starten';

  @override
  String get learningStartLesson => 'Lektion starten';

  @override
  String get learningStartPractice => 'Übung starten';

  @override
  String get learningStartQuiz => 'Quiz starten';

  @override
  String get learningStartingLesson => 'Lektion wird gestartet...';

  @override
  String get learningStop => 'Stopp';

  @override
  String get learningStreak => 'Serie';

  @override
  String get learningStrengths => 'Stärken';

  @override
  String get learningSubmit => 'Absenden';

  @override
  String get learningSubmitForReview => 'Zur Überprüfung einreichen';

  @override
  String get learningSubmitForReviewBody =>
      'Deine Lektion wird von unserem Team überprüft, bevor sie veröffentlicht wird. Dies dauert in der Regel 24-48 Stunden.';

  @override
  String get learningSubmitForReviewQuestion => 'Zur Überprüfung einreichen?';

  @override
  String get learningTabAllLessons => 'Alle Lektionen';

  @override
  String get learningTabEarnings => 'Einnahmen';

  @override
  String get learningTabFlashcards => 'Karteikarten';

  @override
  String get learningTabLessons => 'Lektionen';

  @override
  String get learningTabMyLessons => 'Meine Lektionen';

  @override
  String get learningTabMyProgress => 'Mein Fortschritt';

  @override
  String get learningTabOverview => 'Übersicht';

  @override
  String get learningTabPhrases => 'Redewendungen';

  @override
  String get learningTabProgress => 'Fortschritt';

  @override
  String get learningTabPurchased => 'Gekauft';

  @override
  String get learningTabQuizzes => 'Quiz';

  @override
  String get learningTabStudents => 'Schüler';

  @override
  String get learningTapToContinue => 'Tippen zum Fortfahren';

  @override
  String get learningTapToHearPassage => 'Tippen, um den Text zu hören';

  @override
  String get learningTapToListen => 'Tippen zum Anhören';

  @override
  String get learningTapToMatch => 'Tippe auf Elemente zum Zuordnen';

  @override
  String get learningTapToRevealTranslation =>
      'Tippen, um Übersetzung anzuzeigen';

  @override
  String get learningTapWordsToBuild =>
      'Tippe auf die Wörter unten, um den Satz zu bilden';

  @override
  String get learningTargetLanguage => 'Zielsprache';

  @override
  String get learningTeacherDashboardTitle => 'Lehrer-Dashboard';

  @override
  String get learningTeacherTiers => 'Lehrer-Stufen';

  @override
  String get learningThisMonth => 'Diesen Monat';

  @override
  String get learningTopPerformingStudents => 'Beste Schüler';

  @override
  String get learningTotalStudents => 'Schüler insgesamt';

  @override
  String get learningTotalStudentsLabel => 'Schüler insgesamt';

  @override
  String get learningTotalXp => 'XP insgesamt';

  @override
  String get learningTranslatePhrase => 'Übersetze diesen Satz';

  @override
  String get learningTrue => 'Wahr';

  @override
  String get learningTryAgain => 'Nochmal versuchen';

  @override
  String get learningTypeAnswerBelow => 'Gib deine Antwort unten ein';

  @override
  String get learningTypeAnswerHint => 'Gib deine Antwort ein...';

  @override
  String get learningTypeDescriptionHint => 'Gib deine Beschreibung ein...';

  @override
  String get learningTypeMessageHint => 'Gib deine Nachricht ein...';

  @override
  String get learningTypeMissingWordHint => 'Gib das fehlende Wort ein...';

  @override
  String get learningTypeSentenceHint => 'Gib den Satz ein...';

  @override
  String get learningTypeTranslationHint => 'Gib deine Übersetzung ein...';

  @override
  String get learningTypeWhatYouHeardHint => 'Gib ein, was du gehört hast...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Einheit $unit - Lektion $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Einheit $number';
  }

  @override
  String get learningUnlock => 'Freischalten';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Für $price Münzen freischalten';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Für $price Münzen freischalten';
  }

  @override
  String get learningUnlockLesson => 'Lektion freischalten';

  @override
  String get learningViewAll => 'Alle anzeigen';

  @override
  String get learningViewAnalytics => 'Analysen anzeigen';

  @override
  String get learningVocabulary => 'Vokabeln';

  @override
  String learningWeek(Object week) {
    return 'Woche $week';
  }

  @override
  String get learningWeeklyGoals => 'Wöchentliche Ziele';

  @override
  String get learningWhatWillStudentsLearnHint =>
      'Was werden die Lernenden lernen?';

  @override
  String get learningWhatYouWillLearn => 'Was du lernen wirst';

  @override
  String get learningWithdraw => 'Auszahlen';

  @override
  String get learningWithdrawFunds => 'Guthaben auszahlen';

  @override
  String get learningWithdrawalSubmitted => 'Auszahlungsanfrage eingereicht!';

  @override
  String get learningWordsAndPhrases => 'Wörter & Redewendungen';

  @override
  String get learningWriteAnswerFreely => 'Schreib deine Antwort frei';

  @override
  String get learningWriteAnswerHint => 'Schreibe deine Antwort...';

  @override
  String get learningXpEarned => 'Verdiente XP';

  @override
  String learningYourAnswer(Object answer) {
    return 'Deine Antwort: $answer';
  }

  @override
  String get learningYourScore => 'Dein Ergebnis';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Lektion';

  @override
  String get letsChat => 'Lass uns chatten!';

  @override
  String get letsExchange => 'Lass uns austauschen!';

  @override
  String get levelLabel => 'Level';

  @override
  String levelLabelN(String level) {
    return 'Stufe $level';
  }

  @override
  String get levelTitleEnthusiast => 'Enthusiast';

  @override
  String get levelTitleExpert => 'Experte';

  @override
  String get levelTitleExplorer => 'Entdecker';

  @override
  String get levelTitleLegend => 'Legende';

  @override
  String get levelTitleMaster => 'Meister';

  @override
  String get levelTitleNewcomer => 'Neuling';

  @override
  String get levelTitleVeteran => 'Veteran';

  @override
  String get levelUp => 'LEVEL UP!';

  @override
  String get levelUpCongratulations =>
      'Herzlichen Glückwunsch zum Erreichen eines neuen Levels!';

  @override
  String get levelUpContinue => 'Weiter';

  @override
  String get levelUpRewards => 'BELOHNUNGEN';

  @override
  String get levelUpTitle => 'AUFGESTIEGEN!';

  @override
  String get levelUpVIPUnlocked => 'VIP-Status Freigeschaltet!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Du hast Level $level erreicht';
  }

  @override
  String get likes => 'Gefällt mir';

  @override
  String get limitReachedTitle => 'Limit erreicht';

  @override
  String get listenMe => 'Hör mich an!';

  @override
  String get loading => 'Laden...';

  @override
  String get loadingLabel => 'Laden...';

  @override
  String get localGuideBadge => 'Lokaler Guide';

  @override
  String get location => 'Standort';

  @override
  String get locationAndLanguages => 'Standort und Sprachen';

  @override
  String get locationError => 'Standortfehler';

  @override
  String get locationNotFound => 'Standort nicht gefunden';

  @override
  String get locationNotFoundMessage =>
      'Wir konnten deine Adresse nicht ermitteln. Bitte versuche es erneut oder stelle deinen Standort später manuell ein.';

  @override
  String get locationPermissionDenied => 'Berechtigung verweigert';

  @override
  String get locationPermissionDeniedMessage =>
      'Die Standortberechtigung wird benötigt, um deinen aktuellen Standort zu erkennen. Bitte erteile die Berechtigung, um fortzufahren.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Berechtigung dauerhaft verweigert';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'Die Standortberechtigung wurde dauerhaft verweigert. Bitte aktiviere sie in deinen Geräteeinstellungen, um diese Funktion zu nutzen.';

  @override
  String get locationRequestTimeout => 'Zeitüberschreitung';

  @override
  String get locationRequestTimeoutMessage =>
      'Die Standortbestimmung hat zu lange gedauert. Bitte überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get locationServicesDisabled => 'Standortdienste deaktiviert';

  @override
  String get locationServicesDisabledMessage =>
      'Bitte aktiviere die Standortdienste in deinen Geräteeinstellungen, um diese Funktion zu nutzen.';

  @override
  String get locationUnavailable =>
      'Dein Standort konnte momentan nicht ermittelt werden. Du kannst ihn später in den Einstellungen manuell einstellen.';

  @override
  String get locationUnavailableTitle => 'Standort nicht verfügbar';

  @override
  String get locationUpdatedMessage =>
      'Deine Standorteinstellungen wurden gespeichert';

  @override
  String get locationUpdatedTitle => 'Standort aktualisiert!';

  @override
  String get logOut => 'Abmelden';

  @override
  String get logOutConfirmation =>
      'Bist du sicher, dass du dich abmelden möchtest?';

  @override
  String get login => 'Anmelden';

  @override
  String get loginWithBiometrics => 'Mit Biometrie Anmelden';

  @override
  String get logout => 'Ausloggen';

  @override
  String get longTermRelationship => 'Langfristige Beziehung';

  @override
  String get lookingFor => 'Sucht';

  @override
  String get lvl => 'LVL';

  @override
  String get manageCouponsTiersRules =>
      'Gutscheine, Stufen und Regeln verwalten';

  @override
  String get matchDetailsTitle => 'Match-Details';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Du und $name moechtet Sprachen austauschen!';
  }

  @override
  String get matchNotifKeepSwiping => 'Weiter swipen';

  @override
  String get matchNotifLetsChat => 'Lass uns chatten!';

  @override
  String get matchNotifLetsExchange => 'LASS UNS AUSTAUSCHEN!';

  @override
  String get matchNotifViewProfile => 'Profil ansehen';

  @override
  String matchPercentage(String percentage) {
    return '$percentage Übereinstimmung';
  }

  @override
  String matchedOnDate(String date) {
    return 'Gematcht am $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Du hast $name am $date gematcht';
  }

  @override
  String get matches => 'Übereinstimmungen';

  @override
  String get matchesClearFilters => 'Filter loeschen';

  @override
  String matchesCount(int count) {
    return '$count Übereinstimmungen';
  }

  @override
  String get matchesFilterAll => 'Alle';

  @override
  String get matchesFilterMessaged => 'Geschrieben';

  @override
  String get matchesFilterNew => 'Neu';

  @override
  String get matchesNoMatchesFound => 'Keine Matches gefunden';

  @override
  String get matchesNoMatchesYet => 'Noch keine Matches';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered von $total Matches';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered von $total Übereinstimmungen';
  }

  @override
  String get matchesStartSwiping =>
      'Fang an zu swipen, um deine Matches zu finden!';

  @override
  String get matchesTryDifferent => 'Versuche eine andere Suche oder Filter';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Maximal $count Interessen erlaubt';
  }

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return '$tierName-Mitgliedschaft aktiv bis $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => 'Mitgliedschaft aktiviert!';

  @override
  String get membershipAdvancedFilters => 'Erweiterte Filter';

  @override
  String get membershipBase => 'Basis';

  @override
  String get membershipBaseMembership => 'Basis-Mitgliedschaft';

  @override
  String get membershipBestValue =>
      'Bestes Preis-Leistungs-Verhältnis für langfristiges Engagement!';

  @override
  String get membershipBoostsMonth => 'Boosts/Monat';

  @override
  String get membershipBuyTitle => 'Mitgliedschaft kaufen';

  @override
  String get membershipCouponCodeLabel => 'Gutscheincode *';

  @override
  String get membershipCouponHint => 'z. B. GOLD2024';

  @override
  String get membershipCurrent => 'Aktuelle Mitgliedschaft';

  @override
  String get membershipDailyLikes => 'Tägliche Verbindungen';

  @override
  String get membershipDailyMessagesLabel =>
      'Tägliche Nachrichten (leer = unbegrenzt)';

  @override
  String get membershipDailySwipesLabel =>
      'Tägliche Swipes (leer = unbegrenzt)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days Tage verbleibend';
  }

  @override
  String get membershipDurationLabel => 'Dauer (Tage)';

  @override
  String get membershipEnterCouponHint => 'Gutscheincode eingeben';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Entspricht $price/Monat';
  }

  @override
  String get membershipErrorLoadingData => 'Fehler beim Laden der Daten';

  @override
  String membershipExpires(Object date) {
    return 'Läuft ab: $date';
  }

  @override
  String get membershipExtendTitle => 'Deine Mitgliedschaft verlängern';

  @override
  String get membershipFeatureComparison => 'Funktionsvergleich';

  @override
  String get membershipGeneric => 'Mitgliedschaft';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Basis';

  @override
  String get membershipIncognitoMode => 'Inkognito-Modus';

  @override
  String get membershipLeaveEmptyLifetime => 'Leer lassen für lebenslang';

  @override
  String get membershipLeaveEmptyUnlimited => 'Leer lassen für unbegrenzt';

  @override
  String get membershipLowerThanCurrent => 'Niedriger als deine aktuelle Stufe';

  @override
  String get membershipMaxUsesLabel => 'Maximale Nutzungen';

  @override
  String get membershipMonthly => 'Monatliche Mitgliedschaften';

  @override
  String get membershipNameDescriptionLabel => 'Name/Beschreibung';

  @override
  String get membershipNoActive => 'Keine aktive Mitgliedschaft';

  @override
  String get membershipNotesLabel => 'Notizen';

  @override
  String get membershipOneMonth => '1 Monat';

  @override
  String get membershipOneYear => '1 Jahr';

  @override
  String get membershipPanel => 'Mitgliedschaftsbereich';

  @override
  String get membershipPermanent => 'Dauerhaft';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 MÜNZEN';

  @override
  String get membershipPrioritySupport => 'Prioritäts-Support';

  @override
  String get membershipReadReceipts => 'Lesebestätigungen';

  @override
  String get membershipRequired => 'Mitgliedschaft erforderlich';

  @override
  String get membershipRequiredDescription =>
      'Du musst Mitglied bei GreenGo sein, um diese Aktion durchzuführen.';

  @override
  String get membershipRewinds => 'Zurückspulen';

  @override
  String membershipSavePercent(Object percent) {
    return 'SPARE $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Sehen wer sich verbindet';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Einmal kaufen, Premium-Funktionen für 1 Monat oder 1 Jahr genießen';

  @override
  String get membershipSuperLikes => 'Prioritätsverbindungen';

  @override
  String get membershipSuperLikesLabel =>
      'Prioritätsverbindungen/Tag (leer = unbegrenzt)';

  @override
  String get membershipTerms =>
      'Einmalkauf. Die Mitgliedschaft wird ab deinem aktuellen Enddatum verlängert.';

  @override
  String get membershipTermsExtended =>
      'Einmalkauf. Die Mitgliedschaft wird ab deinem aktuellen Enddatum verlängert. Käufe höherer Stufen überschreiben niedrigere.';

  @override
  String get membershipTierLabel => 'Mitgliedschaftsstufe *';

  @override
  String membershipTierName(Object tierName) {
    return '$tierName-Mitgliedschaft';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Jährliche Mitgliedschaften (Spare bis zu $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'Du hast $tierName';
  }

  @override
  String get messages => 'Austausch';

  @override
  String get minutes => 'Minuten';

  @override
  String moreAchievements(int count) {
    return '+$count weitere Erfolge';
  }

  @override
  String get myBadges => 'Meine Abzeichen';

  @override
  String get myProgress => 'Mein Fortschritt';

  @override
  String get myUsage => 'Meine Nutzung';

  @override
  String get navLearn => 'Lernen';

  @override
  String get navPlay => 'Spielen';

  @override
  String get nearby => 'In der Nähe';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Du brauchst $amount Münzen, um mehr Profile freizuschalten.';
  }

  @override
  String get newLabel => 'NEU';

  @override
  String get next => 'Weiter';

  @override
  String nextLevelXp(String xp) {
    return 'Nächste Stufe in $xp XP';
  }

  @override
  String get nickname => 'Spitzname';

  @override
  String get nicknameAlreadyTaken => 'Dieser Spitzname ist bereits vergeben';

  @override
  String get nicknameCheckError => 'Fehler bei der Verfügbarkeitsprüfung';

  @override
  String nicknameInfoText(String nickname) {
    return 'Dein Spitzname ist einzigartig und kann verwendet werden, um dich zu finden. Andere können dich mit @$nickname suchen';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Muss 3-20 Zeichen haben';

  @override
  String get nicknameNoConsecutiveUnderscores =>
      'Keine aufeinanderfolgenden Unterstriche';

  @override
  String get nicknameNoReservedWords =>
      'Kann keine reservierten Wörter enthalten';

  @override
  String get nicknameOnlyAlphanumeric =>
      'Nur Buchstaben, Zahlen und Unterstriche';

  @override
  String get nicknameRequirements =>
      '3-20 Zeichen. Nur Buchstaben, Zahlen und Unterstriche.';

  @override
  String get nicknameRules => 'Spitzname-Regeln';

  @override
  String get nicknameSearchChat => 'Chat';

  @override
  String get nicknameSearchError =>
      'Fehler bei der Suche. Bitte erneut versuchen.';

  @override
  String get nicknameSearchHelp =>
      'Gib einen Spitznamen ein, um jemanden zu finden';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'Kein Profil mit @$nickname gefunden';
  }

  @override
  String get nicknameSearchOwnProfile => 'Das ist dein eigenes Profil!';

  @override
  String get nicknameSearchTitle => 'Nach Spitzname suchen';

  @override
  String get nicknameSearchView => 'Ansehen';

  @override
  String get nicknameStartWithLetter => 'Mit einem Buchstaben beginnen';

  @override
  String get nicknameUpdatedMessage => 'Dein neuer Nickname ist jetzt aktiv';

  @override
  String get nicknameUpdatedSuccess => 'Spitzname erfolgreich aktualisiert';

  @override
  String get nicknameUpdatedTitle => 'Nickname aktualisiert!';

  @override
  String get no => 'Nein';

  @override
  String get noActiveGamesLabel => 'Keine aktiven Spiele';

  @override
  String get noBadgesEarnedYet => 'Noch keine Abzeichen verdient';

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  @override
  String get noLanguagesYet => 'Noch keine Sprachen. Fang an zu lernen!';

  @override
  String get noLeaderboardData => 'Noch keine Bestenlisten-Daten';

  @override
  String get noMatchesFound => 'Keine Übereinstimmungen gefunden';

  @override
  String get noMatchesYet => 'Noch keine Übereinstimmungen';

  @override
  String get noMessages => 'Noch keine Nachrichten';

  @override
  String get noMoreProfiles => 'Keine weiteren Profile zum Anzeigen';

  @override
  String get noOthersToSee => 'Es gibt niemanden mehr zu sehen';

  @override
  String get noPendingVerifications => 'Keine ausstehenden Verifizierungen';

  @override
  String get noPhotoSubmitted => 'Kein Foto eingereicht';

  @override
  String get noPreviousProfile => 'Kein vorheriges Profil zum Zurückspulen';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'Kein Profil mit @$nickname gefunden';
  }

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get noSocialProfilesLinked => 'Keine sozialen Profile verknüpft';

  @override
  String get noVoiceRecording => 'Keine Sprachaufnahme';

  @override
  String get nodeAvailable => 'Verfügbar';

  @override
  String get nodeCompleted => 'Abgeschlossen';

  @override
  String get nodeInProgress => 'In Bearbeitung';

  @override
  String get nodeLocked => 'Gesperrt';

  @override
  String get notEnoughCoins => 'Nicht genug Münzen';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Erfolg Freigeschaltet: $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Du hast erfolgreich $amount Münzen gekauft.';
  }

  @override
  String get notificationDialogEnable => 'Aktivieren';

  @override
  String get notificationDialogMessage =>
      'Aktiviere Benachrichtigungen, um über Matches, Nachrichten und Prioritätsverbindungen informiert zu werden.';

  @override
  String get notificationDialogNotNow => 'Nicht jetzt';

  @override
  String get notificationDialogTitle => 'Bleib verbunden';

  @override
  String get notificationEmailSubtitle =>
      'Benachrichtigungen per E-Mail erhalten';

  @override
  String get notificationEmailTitle => 'E-Mail-Benachrichtigungen';

  @override
  String get notificationEnableQuietHours => 'Ruhezeiten aktivieren';

  @override
  String get notificationEndTime => 'Endzeit';

  @override
  String get notificationMasterControls => 'Hauptsteuerung';

  @override
  String get notificationMatchExpiring => 'Match läuft ab';

  @override
  String get notificationMatchExpiringSubtitle => 'Wenn ein Match bald abläuft';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname hat eine Unterhaltung mit dir gestartet.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'Du hast ein Gefällt mir von @$nickname erhalten';
  }

  @override
  String get notificationNewLikes => 'Neue Likes';

  @override
  String get notificationNewLikesSubtitle => 'Wenn jemand dich liked';

  @override
  String notificationNewMatch(String nickname) {
    return 'Es ist ein Match! Du hast mit @$nickname gematcht. Starte jetzt einen Chat.';
  }

  @override
  String get notificationNewMatches => 'Neue Matches';

  @override
  String get notificationNewMatchesSubtitle =>
      'Wenn du ein neues Match bekommst';

  @override
  String notificationNewMessage(String nickname) {
    return 'Neue Nachricht von @$nickname';
  }

  @override
  String get notificationNewMessages => 'Neue Nachrichten';

  @override
  String get notificationNewMessagesSubtitle =>
      'Wenn dir jemand eine Nachricht sendet';

  @override
  String get notificationProfileViews => 'Profilaufrufe';

  @override
  String get notificationProfileViewsSubtitle =>
      'Wenn jemand dein Profil ansieht';

  @override
  String get notificationPromotional => 'Werbung';

  @override
  String get notificationPromotionalSubtitle =>
      'Tipps, Angebote und Werbeaktionen';

  @override
  String get notificationPushSubtitle =>
      'Benachrichtigungen auf diesem Gerät erhalten';

  @override
  String get notificationPushTitle => 'Push-Benachrichtigungen';

  @override
  String get notificationQuietHours => 'Ruhezeiten';

  @override
  String get notificationQuietHoursDescription =>
      'Benachrichtigungen zu bestimmten Zeiten stummschalten';

  @override
  String get notificationQuietHoursSubtitle =>
      'Benachrichtigungen während bestimmter Stunden stummschalten';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get notificationSettingsTitle => 'Benachrichtigungseinstellungen';

  @override
  String get notificationSound => 'Ton';

  @override
  String get notificationSoundSubtitle =>
      'Ton bei Benachrichtigungen abspielen';

  @override
  String get notificationSoundVibration => 'Ton & Vibration';

  @override
  String get notificationStartTime => 'Startzeit';

  @override
  String notificationSuperLike(String nickname) {
    return 'Du hast eine Prioritätsverbindung von @$nickname erhalten';
  }

  @override
  String get notificationSuperLikes => 'Prioritätsverbindungen';

  @override
  String get notificationSuperLikesSubtitle =>
      'Wenn sich jemand prioritär mit dir verbindet';

  @override
  String get notificationTypes => 'Benachrichtigungstypen';

  @override
  String get notificationVibration => 'Vibration';

  @override
  String get notificationVibrationSubtitle =>
      'Vibration bei Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Noch keine Benachrichtigungen';

  @override
  String get notificationsEmptySubtitle =>
      'Wenn du Benachrichtigungen erhältst, erscheinen sie hier';

  @override
  String get notificationsMarkAllRead => 'Alle als gelesen markieren';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get occupation => 'Beruf';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Foto hinzufügen';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Füge Fotos hinzu, die das echte Du zeigen';

  @override
  String get onboardingAiVerifiedDescription =>
      'Deine Fotos werden mittels AI verifiziert, um Echtheit sicherzustellen';

  @override
  String get onboardingAiVerifiedPhotos => 'AI-verifizierte Fotos';

  @override
  String get onboardingBioHint =>
      'Erzähle uns von deinen Interessen, Hobbys, wonach du suchst...';

  @override
  String get onboardingBioMinLength =>
      'Die Bio muss mindestens 50 Zeichen lang sein';

  @override
  String get onboardingChooseFromGallery => 'Aus Galerie wählen';

  @override
  String get onboardingCompleteAllFields => 'Bitte fülle alle Felder aus';

  @override
  String get onboardingContinue => 'Weiter';

  @override
  String get onboardingDateOfBirth => 'Geburtsdatum';

  @override
  String get onboardingDisplayName => 'Anzeigename';

  @override
  String get onboardingDisplayNameHint => 'Wie sollen wir dich nennen?';

  @override
  String get onboardingEnterYourName => 'Bitte gib deinen Namen ein';

  @override
  String get onboardingExpressYourself => 'Drücke dich aus';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Schreibe etwas, das zeigt, wer du bist';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'Bild konnte nicht ausgewählt werden: $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'Foto konnte nicht aufgenommen werden: $error';
  }

  @override
  String get onboardingGenderFemale => 'Weiblich';

  @override
  String get onboardingGenderMale => 'Männlich';

  @override
  String get onboardingGenderNonBinary => 'Nicht-binär';

  @override
  String get onboardingGenderOther => 'Andere';

  @override
  String get onboardingHoldIdNextToFace =>
      'Halte deinen Ausweis neben dein Gesicht';

  @override
  String get onboardingIdentifyAs => 'Ich identifiziere mich als';

  @override
  String get onboardingInterestsHelpMatches =>
      'Deine Interessen helfen uns, bessere Matches für dich zu finden';

  @override
  String get onboardingInterestsSubtitle =>
      'Wähle mindestens 3 Interessen (max. 10)';

  @override
  String get onboardingLanguages => 'Sprachen';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 ausgewählt';
  }

  @override
  String get onboardingLetsGetStarted => 'Lass uns loslegen';

  @override
  String get onboardingLocation => 'Standort';

  @override
  String get onboardingLocationLater =>
      'Du kannst deinen Standort später in den Einstellungen festlegen';

  @override
  String get onboardingMainPhoto => 'HAUPT';

  @override
  String get onboardingMaxInterests =>
      'Du kannst bis zu 10 Interessen auswählen';

  @override
  String get onboardingMaxLanguages => 'Du kannst bis zu 3 Sprachen auswählen';

  @override
  String get onboardingMinInterests => 'Bitte wähle mindestens 3 Interessen';

  @override
  String get onboardingMinLanguage => 'Bitte wähle mindestens eine Sprache';

  @override
  String get onboardingNameMinLength =>
      'Der Name muss mindestens 2 Zeichen lang sein';

  @override
  String get onboardingNoLocationSelected => 'Kein Standort ausgewählt';

  @override
  String get onboardingOptional => 'Optional';

  @override
  String get onboardingSelectFromPhotos => 'Aus deinen Fotos auswählen';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 ausgewählt';
  }

  @override
  String get onboardingShowYourself => 'Zeig dich';

  @override
  String get onboardingTakePhoto => 'Foto aufnehmen';

  @override
  String get onboardingTellUsAboutYourself => 'Erzähl uns etwas über dich';

  @override
  String get onboardingTipAuthentic => 'Sei authentisch und echt';

  @override
  String get onboardingTipPassions => 'Teile deine Leidenschaften und Hobbys';

  @override
  String get onboardingTipPositive => 'Bleib positiv';

  @override
  String get onboardingTipUnique => 'Was macht dich einzigartig?';

  @override
  String get onboardingUploadAtLeastOnePhoto =>
      'Bitte lade mindestens ein Foto hoch';

  @override
  String get onboardingUseCurrentLocation => 'Aktuellen Standort verwenden';

  @override
  String get onboardingUseYourCamera => 'Verwende deine Kamera';

  @override
  String get onboardingWhereAreYou => 'Wo bist du?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Stelle deine bevorzugten Sprachen und deinen Standort ein (optional)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Bitte schreibe etwas über dich';

  @override
  String get onboardingWritingTips => 'Schreibtipps';

  @override
  String get onboardingYourInterests => 'Deine Interessen';

  @override
  String oneTimeDownloadSize(int size) {
    return 'Dies ist ein einmaliger Download von ca. $size MB.';
  }

  @override
  String get optionalConsents => 'Optionale Einwilligungen';

  @override
  String get orContinueWith => 'Oder fortfahren mit';

  @override
  String get origin => 'Herkunft';

  @override
  String packFocusMode(String packName) {
    return 'Paket: $packName';
  }

  @override
  String get password => 'Passwort';

  @override
  String get passwordMustContain => 'Das Passwort muss enthalten:';

  @override
  String get passwordMustContainLowercase =>
      'Das Passwort muss mindestens einen Kleinbuchstaben enthalten';

  @override
  String get passwordMustContainNumber =>
      'Das Passwort muss mindestens eine Zahl enthalten';

  @override
  String get passwordMustContainSpecialChar =>
      'Das Passwort muss mindestens ein Sonderzeichen enthalten';

  @override
  String get passwordMustContainUppercase =>
      'Das Passwort muss mindestens einen Großbuchstaben enthalten';

  @override
  String get passwordRequired => 'Passwort ist erforderlich';

  @override
  String get passwordStrengthFair => 'Akzeptabel';

  @override
  String get passwordStrengthStrong => 'Stark';

  @override
  String get passwordStrengthVeryStrong => 'Sehr Stark';

  @override
  String get passwordStrengthVeryWeak => 'Sehr Schwach';

  @override
  String get passwordStrengthWeak => 'Schwach';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get passwordWeak =>
      'Das Passwort muss Großbuchstaben, Kleinbuchstaben, Zahlen und Sonderzeichen enthalten';

  @override
  String get passwordsDoNotMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get pendingVerifications => 'Ausstehende Verifizierungen';

  @override
  String get perMonth => '/Monat';

  @override
  String get periodAllTime => 'Gesamtzeit';

  @override
  String get periodMonthly => 'Dieser Monat';

  @override
  String get periodWeekly => 'Diese Woche';

  @override
  String get personalStatistics => 'Persönliche Statistiken';

  @override
  String get personalStatisticsSubtitle =>
      'Diagramme, Ziele und Sprachfortschritt';

  @override
  String get personalStatsActivity => 'Letzte Aktivität';

  @override
  String get personalStatsChatStats => 'Chat-Statistiken';

  @override
  String get personalStatsConversations => 'Unterhaltungen';

  @override
  String get personalStatsGoalsAchieved => 'Erreichte Ziele';

  @override
  String get personalStatsLevel => 'Stufe';

  @override
  String get personalStatsLanguage => 'Sprache';

  @override
  String get personalStatsTotal => 'Gesamt';

  @override
  String get personalStatsNextLevel => 'Nächste Stufe';

  @override
  String get personalStatsNoActivityYet => 'Noch keine Aktivität aufgezeichnet';

  @override
  String get personalStatsNoWordsYet =>
      'Beginne zu chatten, um neue Wörter zu entdecken';

  @override
  String get personalStatsTotalMessages => 'Gesendete Nachrichten';

  @override
  String get personalStatsWordsDiscovered => 'Entdeckte Wörter';

  @override
  String get personalStatsWordsLearned => 'Gelernte Wörter';

  @override
  String get personalStatsXpOverview => 'XP-Übersicht';

  @override
  String get photoAddPhoto => 'Foto hinzufügen';

  @override
  String get photoAddPrivateDescription =>
      'Füge private Fotos hinzu, die du im Chat teilen kannst';

  @override
  String get photoAddPublicDescription =>
      'Füge Fotos hinzu, um dein Profil zu vervollständigen';

  @override
  String get photoAlreadyExistsInAlbum => 'Foto existiert bereits im Zielalbum';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 Fotos';
  }

  @override
  String get photoDeleteConfirm =>
      'Bist du sicher, dass du dieses Foto löschen möchtest?';

  @override
  String get photoDeleteMainWarning =>
      'Dies ist dein Hauptfoto. Das nächste Foto wird zu deinem Hauptfoto (muss dein Gesicht zeigen). Fortfahren?';

  @override
  String get photoExplicitContent =>
      'Dieses Foto könnte unangemessene Inhalte enthalten. Fotos in der App dürfen keine Nacktheit, Unterwäsche oder explizite Inhalte zeigen.';

  @override
  String get photoExplicitNudity =>
      'Dieses Foto scheint Nacktheit oder explizite Inhalte zu enthalten. Alle Fotos in der App müssen angemessen und vollständig bekleidet sein.';

  @override
  String photoFailedPickImage(Object error) {
    return 'Bild konnte nicht ausgewählt werden: $error';
  }

  @override
  String get photoLongPressReorder => 'Lange drücken und ziehen zum Umordnen';

  @override
  String get photoMainNoFace =>
      'Dein Hauptfoto muss dein Gesicht deutlich zeigen. Auf diesem Foto wurde kein Gesicht erkannt.';

  @override
  String get photoMainNotForward =>
      'Bitte verwende ein Foto, auf dem dein Gesicht deutlich sichtbar und nach vorne gerichtet ist.';

  @override
  String get photoManagePhotos => 'Fotos verwalten';

  @override
  String get photoMaxPrivate => 'Maximal 6 private Fotos erlaubt';

  @override
  String get photoMaxPublic => 'Maximal 6 öffentliche Fotos erlaubt';

  @override
  String get photoMustHaveOne =>
      'Du musst mindestens ein öffentliches Foto haben, auf dem dein Gesicht sichtbar ist.';

  @override
  String get photoNoPhotos => 'Noch keine Fotos';

  @override
  String get photoNoPrivatePhotos => 'Noch keine privaten Fotos';

  @override
  String get photoNotAccepted => 'Foto nicht akzeptiert';

  @override
  String get photoNotAllowedPublic =>
      'Dieses Foto ist in der App nicht erlaubt.';

  @override
  String get photoPrimary => 'PRIMÄR';

  @override
  String get photoPrivateShareInfo =>
      'Private Fotos können im Chat geteilt werden';

  @override
  String get photoTooLarge => 'Foto ist zu groß. Maximale Größe beträgt 10 MB.';

  @override
  String get photoTooMuchSkin =>
      'Dieses Foto zeigt zu viel Haut. Bitte verwende ein Foto, auf dem du angemessen gekleidet bist.';

  @override
  String get photoUploadedMessage =>
      'Dein Foto wurde zu deinem Profil hinzugefügt';

  @override
  String get photoUploadedTitle => 'Foto hochgeladen!';

  @override
  String get photoValidating => 'Foto wird überprüft...';

  @override
  String get photos => 'Fotos';

  @override
  String photosCount(int count) {
    return '$count/6 Fotos';
  }

  @override
  String photosPublicCount(int count) {
    return 'Fotos: $count oeffentlich';
  }

  @override
  String photosPublicPrivateCount(int publicCount, int privateCount) {
    return 'Fotos: $publicCount oeffentlich + $privateCount privat';
  }

  @override
  String get photosUpdatedMessage => 'Deine Fotogalerie wurde gespeichert';

  @override
  String get photosUpdatedTitle => 'Fotos aktualisiert!';

  @override
  String phrasesCount(String count) {
    return '$count Sätze';
  }

  @override
  String get phrasesLabel => 'Sätze';

  @override
  String get platinum => 'Platin';

  @override
  String get playAgain => 'Nochmal Spielen';

  @override
  String playersRange(String min, String max) {
    return '$min-$max Spieler';
  }

  @override
  String get playing => 'Wird abgespielt...';

  @override
  String playingCountLabel(String count) {
    return '$count spielen';
  }

  @override
  String get plusTaxes => '+ Steuern';

  @override
  String get preferenceAddCountry => 'Land hinzufuegen';

  @override
  String get preferenceAddDealBreaker => 'Ausschlusskriterium hinzufuegen';

  @override
  String get preferenceAdvancedFilters => 'Erweiterte Filter';

  @override
  String get preferenceAgeRange => 'Altersbereich';

  @override
  String get preferenceAllCountries => 'Alle Laender';

  @override
  String get preferenceAllVerified => 'Alle Profile muessen verifiziert sein';

  @override
  String get preferenceCountry => 'Land';

  @override
  String get preferenceCountryDescription =>
      'Nur Personen aus bestimmten Laendern anzeigen (leer lassen fuer alle)';

  @override
  String get preferenceDealBreakers => 'Ausschlusskriterien';

  @override
  String get preferenceDealBreakersDesc =>
      'Zeige mir niemals Profile mit diesen Eigenschaften';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Alle';

  @override
  String get preferenceMaxDistance => 'Maximale Entfernung';

  @override
  String get preferenceMen => 'Maenner';

  @override
  String get preferenceMostPopular => 'Am beliebtesten';

  @override
  String get preferenceNoCountriesFound => 'Keine Laender gefunden';

  @override
  String get preferenceNoCountryFilter => 'Kein Laenderfilter - zeige weltweit';

  @override
  String get preferenceNoDealBreakers => 'Keine Ausschlusskriterien gesetzt';

  @override
  String get preferenceNoDistanceLimit => 'Keine Entfernungsbegrenzung';

  @override
  String get preferenceOnlineNow => 'Jetzt online';

  @override
  String get preferenceOnlineNowDesc => 'Nur aktuell online Profile anzeigen';

  @override
  String get preferenceOnlyVerified => 'Nur verifizierte Profile anzeigen';

  @override
  String get preferenceOrientationDescription =>
      'Nach Orientierung filtern (alle deaktiviert = alle anzeigen)';

  @override
  String get preferenceRecentlyActive => 'Kuerzlich aktiv';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Nur in den letzten 7 Tagen aktive Profile anzeigen';

  @override
  String get preferenceSave => 'Speichern';

  @override
  String get preferenceSelectCountry => 'Land auswaehlen';

  @override
  String get preferenceSexualOrientation => 'Sexuelle Orientierung';

  @override
  String get preferenceShowMe => 'Zeige mir';

  @override
  String get preferenceUnlimited => 'Unbegrenzt';

  @override
  String preferenceUsersCount(int count) {
    return '$count Nutzer';
  }

  @override
  String get preferenceWithin => 'Innerhalb';

  @override
  String get preferenceWomen => 'Frauen';

  @override
  String get preferencesSavedMessage =>
      'Deine Entdeckungseinstellungen wurden aktualisiert';

  @override
  String get preferencesSavedTitle => 'Einstellungen gespeichert!';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Primäre Herkunft';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get privacySettings => 'Datenschutzeinstellungen';

  @override
  String get privateAlbum => 'Privat';

  @override
  String get privateRoom => 'Privater Raum';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Profil';

  @override
  String get profileAboutMe => 'Ueber mich';

  @override
  String get profileAccountDeletedSuccess => 'Konto erfolgreich gelöscht.';

  @override
  String get profileActivate => 'Aktivieren';

  @override
  String get profileActivateIncognito => 'Inkognito aktivieren?';

  @override
  String get profileActivateTravelerMode => 'Reisemodus aktivieren?';

  @override
  String get profileActivatingBoost => 'Boost wird aktiviert...';

  @override
  String get profileActiveLabel => 'AKTIV';

  @override
  String get profileAdditionalDetails => 'Weitere Details';

  @override
  String profileAgeCannotChange(int age) {
    return 'Alter $age - Kann nicht geaendert werden (Verifizierung)';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return 'Profil bereits geboostet! $minutes Min. verbleibend';
  }

  @override
  String get profileAuthenticationFailed => 'Authentifizierung fehlgeschlagen';

  @override
  String profileBioMinLength(int min) {
    return 'Bio muss mindestens $min Zeichen lang sein';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Kosten: $cost Münzen';
  }

  @override
  String get profileBoostDescription =>
      'Dein Profil erscheint 30 Minuten lang ganz oben in der Suche!';

  @override
  String get profileBoostNow => 'Jetzt boosten';

  @override
  String get profileBoostProfile => 'Profil boosten';

  @override
  String get profileBoostSubtitle => 'Werde 30 Minuten lang zuerst gesehen';

  @override
  String get profileBoosted => 'Profil geboostet!';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return 'Profil für $minutes Minuten geboostet!';
  }

  @override
  String get profileBuyCoins => 'Münzen kaufen';

  @override
  String get profileCoinShop => 'Münzshop';

  @override
  String get profileCoinShopSubtitle =>
      'Münzen und Premium-Mitgliedschaft kaufen';

  @override
  String get profileConfirmYourPassword => 'Bestätige dein Passwort';

  @override
  String get profileContinue => 'Weiter';

  @override
  String get profileDataExportSent => 'Datenexport an deine E-Mail gesendet';

  @override
  String get profileDateOfBirth => 'Geburtsdatum';

  @override
  String get profileDeleteAccountWarning =>
      'Diese Aktion ist dauerhaft und kann nicht rückgängig gemacht werden. Alle deine Daten, Matches und Nachrichten werden gelöscht. Bitte gib dein Passwort zur Bestätigung ein.';

  @override
  String get profileDiscoveryRestarted =>
      'Suche neu gestartet! Du kannst jetzt wieder alle Profile sehen.';

  @override
  String get profileDisplayName => 'Anzeigename';

  @override
  String get profileDobInfo =>
      'Dein Geburtsdatum kann zur Altersverifizierung nicht geaendert werden. Dein genaues Alter ist fuer Matches sichtbar.';

  @override
  String get profileEditBasicInfo => 'Grundinfos bearbeiten';

  @override
  String get profileEditLocation => 'Standort & Sprachen bearbeiten';

  @override
  String get profileEditNickname => 'Spitzname bearbeiten';

  @override
  String get profileEducation => 'Bildung';

  @override
  String get profileEducationHint => 'z.B. Bachelor in Informatik';

  @override
  String get profileEnterNameHint => 'Gib deinen Namen ein';

  @override
  String get profileEnterNicknameHint => 'Nickname eingeben';

  @override
  String get profileEnterNicknameWith => 'Gib einen Spitznamen mit @ ein';

  @override
  String get profileExportingData => 'Deine Daten werden exportiert...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Neustart der Suche fehlgeschlagen: $error';
  }

  @override
  String get profileFindUsers => 'Nutzer finden';

  @override
  String get profileGender => 'Geschlecht';

  @override
  String get profileGetCoins => 'Münzen holen';

  @override
  String get profileGetMembership => 'GreenGo-Mitgliedschaft holen';

  @override
  String get profileGettingLocation => 'Standort wird ermittelt...';

  @override
  String get profileGreengoMembership => 'GreenGo-Mitgliedschaft';

  @override
  String get profileHeightCm => 'Groesse (cm)';

  @override
  String get profileIncognitoActivated =>
      'Inkognito-Modus für 24 Stunden aktiviert!';

  @override
  String profileIncognitoCost(Object cost) {
    return 'Der Inkognito-Modus kostet $cost Münzen pro Tag.';
  }

  @override
  String get profileIncognitoDeactivated => 'Inkognito-Modus deaktiviert.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'Der Inkognito-Modus verbirgt dein Profil für 24 Stunden aus der Suche.\n\nKosten: $cost';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Kostenlos mit Platinum - Aus der Suche verborgen';

  @override
  String get profileIncognitoMode => 'Inkognito-Modus';

  @override
  String get profileInsufficientCoins => 'Nicht genügend Münzen';

  @override
  String profileInterestsCount(Object count) {
    return '$count Interessen';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Erzähl uns von deinen Interessen, Hobbys und wonach du suchst...';

  @override
  String get profileLanguagesSectionTitle => 'Sprachen';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 Sprachen ausgewaehlt';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count Profil(e) verknüpft';
  }

  @override
  String profileLocationFailed(String error) {
    return 'Standort konnte nicht ermittelt werden: $error';
  }

  @override
  String get profileLocationSectionTitle => 'Standort';

  @override
  String get profileLookingFor => 'Suche nach';

  @override
  String get profileLookingForHint => 'z.B. Langfristige Beziehung';

  @override
  String get profileMaxLanguagesAllowed => 'Maximal 3 Sprachen erlaubt';

  @override
  String get profileMembershipActive => 'Aktiv';

  @override
  String get profileMembershipExpired => 'Abgelaufen';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Gültig bis $date';
  }

  @override
  String get profileMyUsage => 'Meine Nutzung';

  @override
  String get profileMyUsageSubtitle =>
      'Tägliche Nutzung und Tier-Limits anzeigen';

  @override
  String get profileNicknameAlreadyTaken =>
      'Dieser Spitzname ist bereits vergeben';

  @override
  String get profileNicknameCharRules =>
      '3-20 Zeichen. Nur Buchstaben, Zahlen und Unterstriche.';

  @override
  String get profileNicknameCheckError =>
      'Fehler bei der Verfuegbarkeitspruefung';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'Dein Spitzname ist einzigartig und kann verwendet werden, um dich zu finden. Andere koennen dich mit @$nickname suchen';
  }

  @override
  String get profileNicknameInfoWithout =>
      'Dein Spitzname ist einzigartig und kann verwendet werden, um dich zu finden. Lege einen fest, damit andere dich entdecken koennen.';

  @override
  String get profileNicknameLabel => 'Spitzname';

  @override
  String get profileNicknameRefresh => 'Aktualisieren';

  @override
  String get profileNicknameRule1 => 'Muss 3-20 Zeichen lang sein';

  @override
  String get profileNicknameRule2 => 'Mit einem Buchstaben beginnen';

  @override
  String get profileNicknameRule3 => 'Nur Buchstaben, Zahlen und Unterstriche';

  @override
  String get profileNicknameRule4 => 'Keine aufeinanderfolgenden Unterstriche';

  @override
  String get profileNicknameRule5 =>
      'Darf keine reservierten Woerter enthalten';

  @override
  String get profileNicknameRules => 'Spitzname-Regeln';

  @override
  String get profileNicknameSuggestions => 'Vorschlaege';

  @override
  String profileNoUsersFound(String query) {
    return 'Keine Nutzer fuer \"@$query\" gefunden';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return 'Nicht genügend Münzen! Benötigt $required, verfügbar $available';
  }

  @override
  String get profileOccupation => 'Beruf';

  @override
  String get profileOccupationHint => 'z.B. Softwareentwickler';

  @override
  String get profileOptionalDetails =>
      'Optional - hilft anderen dich kennenzulernen';

  @override
  String get profileOrientationPrivate =>
      'Dies ist privat und wird nicht auf deinem Profil angezeigt';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 Fotos';
  }

  @override
  String get profilePremiumFeatures => 'Premium-Funktionen';

  @override
  String get profileProgressGrowth => 'Fortschritt & Wachstum';

  @override
  String get profileRestart => 'Neu starten';

  @override
  String get profileRestartDiscovery => 'Suche neu starten';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Dadurch werden alle deine Swipes (Verbindungen, Ablehnungen, Prioritätsverbindungen) gelöscht, sodass du alle wieder von vorne entdecken kannst.\n\nDeine Matches und Chats werden NICHT beeinflusst.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Suche neu starten';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Alle Swipes zurücksetzen und neu beginnen';

  @override
  String get profileSearchByNickname => 'Nach @Spitzname suchen';

  @override
  String get profileSearchByNicknameHint => 'Nach @Nickname suchen';

  @override
  String get profileSearchCityHint => 'Stadt, Adresse oder Ort suchen...';

  @override
  String get profileSearchForUsers => 'Nutzer nach Spitzname suchen';

  @override
  String get profileSearchLanguagesHint => 'Sprachen suchen...';

  @override
  String get profileSetLocationAndLanguage =>
      'Bitte Standort und mindestens eine Sprache festlegen';

  @override
  String get profileSexualOrientation => 'Sexuelle Orientierung';

  @override
  String get profileStop => 'Stopp';

  @override
  String get profileTellAboutYourselfHint => 'Erzähl etwas über dich...';

  @override
  String get profileTipAuthentic => 'Sei authentisch und echt';

  @override
  String get profileTipHobbies => 'Erwaehne deine Hobbys und Leidenschaften';

  @override
  String get profileTipHumor => 'Fuege etwas Humor hinzu';

  @override
  String get profileTipPositive => 'Bleib positiv';

  @override
  String get profileTipsForGreatBio => 'Tipps fuer eine tolle Bio';

  @override
  String profileTravelerActivated(Object city) {
    return 'Reisemodus aktiviert! Du erscheinst 24 Stunden lang in $city.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'Der Reisemodus kostet $cost Münzen pro Tag.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Reisemodus deaktiviert. Zurück an deinem echten Standort.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'Der Reisemodus lässt dich 24 Stunden lang im Entdeckungs-Feed einer anderen Stadt erscheinen.\n\nKosten: $cost';
  }

  @override
  String get profileTravelerMode => 'Reisemodus';

  @override
  String get profileTryDifferentNickname => 'Versuche einen anderen Spitznamen';

  @override
  String get profileUnableToVerifyAccount =>
      'Konto konnte nicht verifiziert werden';

  @override
  String get profileUpdateCurrentLocation => 'Aktuellen Standort aktualisieren';

  @override
  String get profileUpdatedMessage => 'Deine Änderungen wurden gespeichert';

  @override
  String get profileUpdatedSuccess => 'Profil erfolgreich aktualisiert';

  @override
  String get profileUpdatedTitle => 'Profil aktualisiert!';

  @override
  String get profileWeightKg => 'Gewicht (kg)';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e',
      one: '',
    );
    return '$count Profil$_temp0 verknüpft';
  }

  @override
  String get profilingDescription =>
      'Erlauben Sie uns, Ihre Präferenzen zu analysieren, um bessere Übereinstimmungsvorschläge zu machen';

  @override
  String get progress => 'Fortschritt';

  @override
  String get progressAchievements => 'Abzeichen';

  @override
  String get progressBadges => 'Abzeichen';

  @override
  String get progressChallenges => 'Herausforderungen';

  @override
  String get progressComparison => 'Fortschrittsvergleich';

  @override
  String get progressCompleted => 'Abgeschlossen';

  @override
  String get progressJourneyDescription =>
      'Sieh deine komplette Dating-Reise und Meilensteine';

  @override
  String get progressLabel => 'Fortschritt';

  @override
  String get progressLeaderboard => 'Rangliste';

  @override
  String progressLevel(int level) {
    return 'Level $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Übersicht';

  @override
  String get progressRecentAchievements => 'Aktuelle Erfolge';

  @override
  String get progressSeeAll => 'Alle Anzeigen';

  @override
  String get progressTitle => 'Fortschritt';

  @override
  String get progressTodaysChallenges => 'Heutige Herausforderungen';

  @override
  String get progressTotalXP => 'Gesamt-XP';

  @override
  String get progressViewJourney => 'Deine Reise Anzeigen';

  @override
  String get publicAlbum => 'Öffentlich';

  @override
  String get purchaseSuccessfulTitle => 'Kauf erfolgreich!';

  @override
  String get purchasedLabel => 'Gekauft';

  @override
  String get quickPlay => 'Schnelles Spiel';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Datenschutzerklärung lesen';

  @override
  String get readTermsAndConditions => 'Allgemeine Geschäftsbedingungen lesen';

  @override
  String get readyButton => 'Bereit';

  @override
  String get recipientNickname => 'Empfänger-Nickname';

  @override
  String get recordVoice => 'Stimme Aufnehmen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get register => 'Registrieren';

  @override
  String get rejectVerification => 'Ablehnen';

  @override
  String rejectionReason(String reason) {
    return 'Grund: $reason';
  }

  @override
  String get rejectionReasonRequired =>
      'Bitte gib einen Grund für die Ablehnung ein';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $limitType heute verbleibend';
  }

  @override
  String get reportSubmittedMessage =>
      'Danke, dass du hilfst, unsere Community sicher zu halten';

  @override
  String get reportSubmittedTitle => 'Meldung eingereicht!';

  @override
  String get reportWord => 'Wort Melden';

  @override
  String get reportsPanel => 'Meldebereich';

  @override
  String get requestBetterPhoto => 'Besseres Foto Anfordern';

  @override
  String requiresTier(String tier) {
    return 'Erfordert $tier';
  }

  @override
  String get resetPassword => 'Passwort Zurücksetzen';

  @override
  String get resetToDefault => 'Auf Standard zurücksetzen';

  @override
  String get restartAppWizard => 'App-Assistenten Neu Starten';

  @override
  String get restartWizard => 'Assistenten Neu Starten';

  @override
  String get restartWizardDialogContent =>
      'Dies startet den Einrichtungsassistenten neu. Du kannst deine Profilinformationen Schritt für Schritt aktualisieren. Deine aktuellen Daten werden beibehalten.';

  @override
  String get retakePhoto => 'Foto Wiederholen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get reuploadVerification => 'Verifizierungsfoto erneut hochladen';

  @override
  String get reverificationCameraError => 'Kamera konnte nicht geöffnet werden';

  @override
  String get reverificationDescription =>
      'Bitte mache ein klares Selfie, damit wir deine Identität verifizieren können. Achte auf gute Beleuchtung und dass dein Gesicht gut sichtbar ist.';

  @override
  String get reverificationHeading => 'Wir müssen deine Identität verifizieren';

  @override
  String get reverificationInfoText =>
      'Nach dem Einreichen wird dein Profil überprüft. Du erhältst Zugang nach der Genehmigung.';

  @override
  String get reverificationPhotoTips => 'Fototipps';

  @override
  String get reverificationReasonLabel => 'Grund der Anfrage:';

  @override
  String get reverificationRetakePhoto => 'Foto wiederholen';

  @override
  String get reverificationSubmit => 'Zur Überprüfung einreichen';

  @override
  String get reverificationTapToSelfie => 'Tippe, um ein Selfie zu machen';

  @override
  String get reverificationTipCamera => 'Schaue direkt in die Kamera';

  @override
  String get reverificationTipFullFace =>
      'Dein ganzes Gesicht muss sichtbar sein';

  @override
  String get reverificationTipLighting =>
      'Gute Beleuchtung — wende dich der Lichtquelle zu';

  @override
  String get reverificationTipNoAccessories =>
      'Keine Sonnenbrillen, Hüte oder Masken';

  @override
  String get reverificationTitle => 'Identitätsverifizierung';

  @override
  String get reverificationUploadFailed =>
      'Upload fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get reviewReportedMessages =>
      'Gemeldete Nachrichten prüfen und Konten verwalten';

  @override
  String get reviewUserVerifications => 'Benutzerverifizierungen prüfen';

  @override
  String reviewedBy(String admin) {
    return 'Überprüft von $admin';
  }

  @override
  String get revokeAccess => 'Albumzugriff entziehen';

  @override
  String get rewardsAndProgress => 'Belohnungen und Fortschritt';

  @override
  String get romanticCategory => 'Romantisch';

  @override
  String get roundTimer => 'Runden-Timer';

  @override
  String roundXofY(String current, String total) {
    return 'Runde $current/$total';
  }

  @override
  String get rounds => 'Runden';

  @override
  String get safetyAdd => 'Hinzufügen';

  @override
  String get safetyAddAtLeastOneContact =>
      'Bitte füge mindestens einen Notfallkontakt hinzu';

  @override
  String get safetyAddEmergencyContact => 'Notfallkontakt hinzufügen';

  @override
  String get safetyAddEmergencyContacts => 'Notfallkontakte hinzufügen';

  @override
  String get safetyAdditionalDetailsHint => 'Weitere Details...';

  @override
  String get safetyCheckInDescription =>
      'Richte einen Check-in für dein Date ein. Wir erinnern dich daran einzuchecken und alarmieren deine Kontakte, wenn du nicht antwortest.';

  @override
  String get safetyCheckInEvery => 'Einchecken alle';

  @override
  String get safetyCheckInScheduled => 'Date-Check-in geplant!';

  @override
  String get safetyDateCheckIn => 'Date-Check-in';

  @override
  String get safetyDateTime => 'Datum & Uhrzeit';

  @override
  String get safetyEmergencyContacts => 'Notfallkontakte';

  @override
  String get safetyEmergencyContactsHelp =>
      'Sie werden benachrichtigt, wenn du Hilfe brauchst';

  @override
  String get safetyEmergencyContactsLocation =>
      'Notfallkontakte können deinen Standort sehen';

  @override
  String get safetyInterval15Min => '15 Min.';

  @override
  String get safetyInterval1Hour => '1 Stunde';

  @override
  String get safetyInterval2Hours => '2 Stunden';

  @override
  String get safetyInterval30Min => '30 Min.';

  @override
  String get safetyLocation => 'Standort';

  @override
  String get safetyMeetingLocationHint => 'Wo triffst du dich?';

  @override
  String get safetyMeetingWith => 'Treffen mit';

  @override
  String get safetyNameLabel => 'Name';

  @override
  String get safetyNotesOptional => 'Notizen (optional)';

  @override
  String get safetyPhoneLabel => 'Telefonnummer';

  @override
  String get safetyPleaseEnterLocation => 'Bitte gib einen Standort ein';

  @override
  String get safetyRelationshipFamily => 'Familie';

  @override
  String get safetyRelationshipFriend => 'Freund/in';

  @override
  String get safetyRelationshipLabel => 'Beziehung';

  @override
  String get safetyRelationshipOther => 'Sonstige';

  @override
  String get safetyRelationshipPartner => 'Partner/in';

  @override
  String get safetyRelationshipRoommate => 'Mitbewohner/in';

  @override
  String get safetyScheduleCheckIn => 'Check-in planen';

  @override
  String get safetyShareLiveLocation => 'Live-Standort teilen';

  @override
  String get safetyStaySafe => 'Bleib sicher';

  @override
  String get save => 'Speichern';

  @override
  String get searchByNameOrNickname => 'Nach Name oder @Nickname suchen';

  @override
  String get searchByNickname => 'Nach Spitzname Suchen';

  @override
  String get searchByNicknameTooltip => 'Nach Nickname suchen';

  @override
  String get searchCityPlaceholder => 'Stadt, Adresse oder Ort suchen...';

  @override
  String get searchCountries => 'Länder suchen...';

  @override
  String get searchCountryHint => 'Land suchen...';

  @override
  String get searchForCity => 'Suche eine Stadt oder verwende GPS';

  @override
  String get searchMessagesHint => 'Nachrichten suchen...';

  @override
  String get secondChanceDescription =>
      'Sieh Profile, die du übersprungen hast und die dich geliked haben!';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km entfernt';
  }

  @override
  String get secondChanceEmpty => 'Keine zweiten Chancen verfügbar';

  @override
  String get secondChanceEmptySubtitle =>
      'Schau später nochmal für mehr Möglichkeiten!';

  @override
  String get secondChanceFindButton => 'Zweite Chancen finden';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max kostenlos';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Unbegrenzt erhalten ($cost)';
  }

  @override
  String get secondChanceLike => 'Like';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'Hat dich vor $ago geliked';
  }

  @override
  String get secondChanceMatchBody =>
      'Ihr mögt euch gegenseitig! Starte eine Unterhaltung.';

  @override
  String get secondChanceMatchTitle => 'Auf geht\'s zum Austausch!';

  @override
  String get secondChanceOutOf => 'Keine zweiten Chancen mehr';

  @override
  String get secondChancePass => 'Weiter';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'Du hast heute alle $freePerDay kostenlosen zweiten Chancen verbraucht.\n\nHol dir unbegrenzt für $cost Münzen!';
  }

  @override
  String get secondChanceRefresh => 'Aktualisieren';

  @override
  String get secondChanceStartChat => 'Chat starten';

  @override
  String get secondChanceTitle => 'Zweite Chance';

  @override
  String get secondChanceUnlimited => 'Unbegrenzt';

  @override
  String get secondChanceUnlimitedUnlocked =>
      'Unbegrenzte zweite Chancen freigeschaltet!';

  @override
  String get secondaryOrigin => 'Sekundäre Herkunft (optional)';

  @override
  String get seconds => 'Sekunden';

  @override
  String get secretAchievement => 'Geheimer Erfolg';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get seeHowOthersViewProfile => 'Sieh, wie andere dein Profil sehen';

  @override
  String seeMoreProfiles(int count) {
    return '$count weitere anzeigen';
  }

  @override
  String get seeMoreProfilesTitle => 'Mehr Profile anzeigen';

  @override
  String get seeProfile => 'Profil ansehen';

  @override
  String selectAtLeastInterests(int count) {
    return 'Wähle mindestens $count Interessen';
  }

  @override
  String get selectLanguage => 'Sprache Auswählen';

  @override
  String get selectTravelLocation => 'Reiseort auswählen';

  @override
  String get sendCoins => 'Münzen senden';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return '$amount Münzen an @$nickname senden?';
  }

  @override
  String get sendMedia => 'Medien senden';

  @override
  String get sendMessage => 'Nachricht Senden';

  @override
  String get serverUnavailableMessage =>
      'Unsere Server sind vorübergehend nicht verfügbar. Bitte versuche es in wenigen Momenten erneut.';

  @override
  String get serverUnavailableTitle => 'Server nicht verfügbar';

  @override
  String get setYourUniqueNickname =>
      'Lege deinen einzigartigen Spitznamen fest';

  @override
  String get settings => 'Einstellungen';

  @override
  String get shareAlbum => 'Album teilen';

  @override
  String get shop => 'Shop';

  @override
  String get shopActive => 'AKTIV';

  @override
  String get shopAdvancedFilters => 'Erweiterte Filter';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount Münzen';
  }

  @override
  String get shopBadge => 'Abzeichen';

  @override
  String get shopBaseMembership => 'GreenGo Basis-Mitgliedschaft';

  @override
  String get shopBaseMembershipDescription =>
      'Erforderlich zum Swipen, Liken, Chatten und Interagieren mit anderen Nutzern.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus Bonusmünzen';
  }

  @override
  String get shopBoosts => 'Boosts';

  @override
  String shopBuyTier(String tier, String duration) {
    return '$tier kaufen ($duration)';
  }

  @override
  String get shopCannotSendToSelf => 'Du kannst dir selbst keine Münzen senden';

  @override
  String get shopCheckInternet =>
      'Stelle sicher, dass du eine Internetverbindung hast\nund versuche es erneut.';

  @override
  String get shopCoins => 'Münzen';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount Münzen/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount Münzen an @$nickname gesendet';
  }

  @override
  String get shopComingSoon => 'Demnächst verfügbar';

  @override
  String get shopConfirmSend => 'Senden bestätigen';

  @override
  String get shopCurrent => 'AKTUELL';

  @override
  String shopCurrentExpires(Object date) {
    return 'AKTUELL - Läuft ab $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Aktueller Plan: $tier';
  }

  @override
  String get shopDailyLikes => 'Tägliche Verbindungen';

  @override
  String shopDaysLeft(Object days) {
    return '${days}T übrig';
  }

  @override
  String get shopEnterAmount => 'Betrag eingeben';

  @override
  String get shopEnterBothFields => 'Bitte gib Nickname und Betrag ein';

  @override
  String get shopEnterValidAmount => 'Bitte gib einen gültigen Betrag ein';

  @override
  String shopExpired(String date) {
    return 'Abgelaufen: $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Läuft ab: $date ($days Tage verbleibend)';
  }

  @override
  String get shopFailedToInitiate => 'Kauf konnte nicht gestartet werden';

  @override
  String get shopFailedToSendCoins => 'Münzen senden fehlgeschlagen';

  @override
  String get shopGetNotified => 'Benachrichtigt werden';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Inkognito-Modus';

  @override
  String get shopInsufficientCoins => 'Nicht genügend Münzen';

  @override
  String shopMembershipActivated(String date) {
    return 'GreenGo Mitgliedschaft aktiviert! +500 Bonusmünzen. Gültig bis $date.';
  }

  @override
  String get shopMonthly => 'Monatlich';

  @override
  String get shopNotifyMessage =>
      'Wir informieren dich, wenn Video-Coins verfügbar sind';

  @override
  String get shopOneMonth => '1 Monat';

  @override
  String get shopOneYear => '1 Jahr';

  @override
  String get shopPerMonth => '/Monat';

  @override
  String get shopPerYear => '/Jahr';

  @override
  String get shopPopular => 'BELIEBT';

  @override
  String get shopPreviousPurchaseFound =>
      'Vorheriger Kauf gefunden. Bitte versuche es erneut.';

  @override
  String get shopPriorityMatching => 'Prioritäts-Matching';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return '$coins Münzen für $price kaufen';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Kauffehler: $error';
  }

  @override
  String get shopReadReceipts => 'Lesebestätigungen';

  @override
  String get shopRecipientNickname => 'Empfänger-Nickname';

  @override
  String get shopRetry => 'Erneut versuchen';

  @override
  String shopSavePercent(String percent) {
    return 'SPARE $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'Sehen wer sich verbindet';

  @override
  String get shopSend => 'Senden';

  @override
  String get shopSendCoins => 'Münzen senden';

  @override
  String get shopStoreNotAvailable =>
      'Store nicht verfügbar. Bitte überprüfe deine Geräteeinstellungen.';

  @override
  String get shopSuperLikes => 'Prioritätsverbindungen';

  @override
  String get shopTabCoins => 'Münzen';

  @override
  String shopTabError(Object tabName) {
    return 'Fehler im Tab $tabName';
  }

  @override
  String get shopTabMembership => 'Mitgliedschaft';

  @override
  String get shopTabVideo => 'Video';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopTravelling => 'Reisen';

  @override
  String get shopUnableToLoadPackages => 'Pakete können nicht geladen werden';

  @override
  String get shopUnlimited => 'Unbegrenzt';

  @override
  String get shopUnlockPremium =>
      'Schalte Premium-Funktionen frei und verbessere dein Dating-Erlebnis';

  @override
  String get shopUpgradeAndSave => 'Upgrade & Spare! Rabatt auf höhere Stufen';

  @override
  String get shopUpgradeExperience => 'Verbessere dein Erlebnis';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Upgrade auf $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'Benutzer nicht gefunden';

  @override
  String shopValidUntil(String date) {
    return 'Gültig bis $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      'Schau kurze Videos, um kostenlose Münzen zu verdienen!\nBleib dran für dieses spannende Feature.';

  @override
  String get shopVipBadge => 'VIP-Abzeichen';

  @override
  String get shopYearly => 'Jährlich';

  @override
  String get shopYearlyPlan => 'Jahresabonnement';

  @override
  String get shopYouHave => 'Du hast';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Du sparst $amount/Monat beim Upgrade von $tier';
  }

  @override
  String get shortTermRelationship => 'Kurzfristige Beziehung';

  @override
  String showingProfiles(int count) {
    return '$count Profile';
  }

  @override
  String get signIn => 'Einloggen';

  @override
  String get signOut => 'Ausloggen';

  @override
  String get signUp => 'Anmelden';

  @override
  String get silver => 'Silber';

  @override
  String get skip => 'Überspringen';

  @override
  String get skipForNow => 'Vorerst Überspringen';

  @override
  String get slangCategory => 'Umgangssprache';

  @override
  String get socialConnectAccounts => 'Verbinde deine sozialen Konten';

  @override
  String get socialHintUsername => 'Benutzername (ohne @)';

  @override
  String get socialHintUsernameOrUrl => 'Benutzername oder Profil-URL';

  @override
  String get socialLinksUpdatedMessage =>
      'Deine sozialen Profile wurden gespeichert';

  @override
  String get socialLinksUpdatedTitle => 'Social Links aktualisiert!';

  @override
  String get socialNotConnected => 'Nicht verbunden';

  @override
  String get socialProfiles => 'Soziale Profile';

  @override
  String get socialProfilesTip =>
      'Deine sozialen Profile sind in deinem Dating-Profil sichtbar und helfen anderen, deine Identität zu überprüfen.';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String get spotsAbout => 'Über';

  @override
  String get spotsAddNewSpot => 'Einen neuen Ort hinzufügen';

  @override
  String get spotsAddSpot => 'Ort hinzufügen';

  @override
  String spotsAddedBy(Object name) {
    return 'Hinzugefügt von $name';
  }

  @override
  String get spotsAll => 'Alle';

  @override
  String get spotsCategory => 'Kategorie';

  @override
  String get spotsCouldNotLoad => 'Orte konnten nicht geladen werden';

  @override
  String get spotsCouldNotLoadSpot => 'Ort konnte nicht geladen werden';

  @override
  String get spotsCreateSpot => 'Ort erstellen';

  @override
  String get spotsCulturalSpots => 'Kulturelle Orte';

  @override
  String spotsDateDaysAgo(Object count) {
    return 'Vor $count Tagen';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return 'Vor $count Monaten';
  }

  @override
  String get spotsDateToday => 'Heute';

  @override
  String spotsDateWeeksAgo(Object count) {
    return 'Vor $count Wochen';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return 'Vor $count Jahren';
  }

  @override
  String get spotsDateYesterday => 'Gestern';

  @override
  String get spotsDescriptionLabel => 'Beschreibung';

  @override
  String get spotsNameLabel => 'Spot-Name';

  @override
  String get spotsNoReviews =>
      'Noch keine Bewertungen. Sei der Erste, der eine schreibt!';

  @override
  String get spotsNoSpotsFound => 'Keine Orte gefunden';

  @override
  String get spotsReviewAdded => 'Bewertung hinzugefügt!';

  @override
  String spotsReviewsCount(Object count) {
    return 'Bewertungen ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Teile deine Erfahrung...';

  @override
  String get spotsSubmitReview => 'Bewertung abschicken';

  @override
  String get spotsWriteReview => 'Bewertung schreiben';

  @override
  String get spotsYourRating => 'Deine Bewertung';

  @override
  String get standardTier => 'Standard';

  @override
  String get startChat => 'Chat starten';

  @override
  String get startConversation => 'Gespräch Beginnen';

  @override
  String get startGame => 'Spiel Starten';

  @override
  String get startLearning => 'Lernen starten';

  @override
  String get startLessonBtn => 'Lektion starten';

  @override
  String get startSwipingToFindMatches =>
      'Wische los, um deine Matches zu finden!';

  @override
  String get step => 'Schritt';

  @override
  String get stepOf => 'von';

  @override
  String get storiesAddCaptionHint => 'Beschriftung hinzufügen...';

  @override
  String get storiesCreateStory => 'Story erstellen';

  @override
  String storiesDaysAgo(Object count) {
    return 'Vor ${count}T';
  }

  @override
  String get storiesDisappearAfter24h =>
      'Deine Story verschwindet nach 24 Stunden';

  @override
  String get storiesGallery => 'Galerie';

  @override
  String storiesHoursAgo(Object count) {
    return 'Vor ${count}Std';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return 'Vor ${count}Min';
  }

  @override
  String get storiesNoActive => 'Keine aktiven Storys';

  @override
  String get storiesNoStories => 'Keine Storys verfügbar';

  @override
  String get storiesPhoto => 'Foto';

  @override
  String get storiesPost => 'Posten';

  @override
  String get storiesSendMessageHint => 'Nachricht senden...';

  @override
  String get storiesShareMoment => 'Teile einen Moment';

  @override
  String get storiesVideo => 'Video';

  @override
  String get storiesYourStory => 'Deine Story';

  @override
  String get streakActiveToday => 'Heute aktiv';

  @override
  String get streakBonusHeader => 'Streak-Bonus!';

  @override
  String get streakInactive => 'Starte deine Serie!';

  @override
  String get streakMessageIncredible => 'Unglaubliches Engagement!';

  @override
  String get streakMessageKeepItUp => 'Weiter so!';

  @override
  String get streakMessageMomentum => 'Du bist in Fahrt!';

  @override
  String get streakMessageOneWeek => 'Eine Woche geschafft!';

  @override
  String get streakMessageTwoWeeks => 'Zwei Wochen am Stück!';

  @override
  String get submitAnswer => 'Antwort Senden';

  @override
  String get submitVerification => 'Zur Verifizierung Einreichen';

  @override
  String submittedOn(String date) {
    return 'Eingereicht am $date';
  }

  @override
  String get subscribe => 'Abonnieren';

  @override
  String get subscribeNow => 'Jetzt abonnieren';

  @override
  String get subscriptionExpired => 'Abonnement abgelaufen';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'Dein $tierName-Abonnement ist abgelaufen. Du wurdest in die Free-Stufe verschoben.\n\nUpgrade jederzeit, um deine Premium-Funktionen wiederherzustellen!';
  }

  @override
  String get suggestions => 'Vorschläge';

  @override
  String get superLike => 'Prioritätsverbindung';

  @override
  String superLikedYou(String name) {
    return '$name hat sich prioritär mit dir verbunden!';
  }

  @override
  String get superLikes => 'Prioritätsverbindungen';

  @override
  String get supportCenter => 'Support-Center';

  @override
  String get supportCenterSubtitle =>
      'Hilfe erhalten, Probleme melden, kontaktiere uns';

  @override
  String get swipeIndicatorLike => 'VERBINDEN';

  @override
  String get swipeIndicatorNope => 'WEITER';

  @override
  String get swipeIndicatorSkip => 'WEITER';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITAT';

  @override
  String get takePhoto => 'Foto Aufnehmen';

  @override
  String get takeVerificationPhoto => 'Verifizierungsfoto Aufnehmen';

  @override
  String get tapToContinue => 'Tippen zum Fortfahren';

  @override
  String get targetLanguage => 'Zielsprache';

  @override
  String get termsAndConditions => 'Allgemeine Geschäftsbedingungen';

  @override
  String get thatsYourOwnProfile => 'Das ist dein eigenes Profil!';

  @override
  String get thirdPartyDataDescription =>
      'Erlauben Sie die Weitergabe anonymisierter Daten an Partner zur Serviceverbesserung';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get tierFree => 'Kostenlos';

  @override
  String get timeRemaining => 'Verbleibende Zeit';

  @override
  String get timeoutError => 'Zeitüberschreitung';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% zu Level $level';
  }

  @override
  String get today => 'heute';

  @override
  String get totalXpLabel => 'Gesamt-XP';

  @override
  String get tourDiscoveryDescription =>
      'Wische durch Profile, um deinen perfekten Match zu finden. Wische nach rechts wenn interessiert, nach links zum Überspringen.';

  @override
  String get tourDiscoveryTitle => 'Matches Entdecken';

  @override
  String get tourDone => 'Fertig';

  @override
  String get tourLearnDescription =>
      'Lerne Vokabeln, Grammatik und Konversationsfähigkeiten';

  @override
  String get tourLearnTitle => 'Sprachen Lernen';

  @override
  String get tourMatchesDescription =>
      'Sieh alle, die dich auch geliked haben! Starte Unterhaltungen mit deinen gegenseitigen Matches.';

  @override
  String get tourMatchesTitle => 'Deine Matches';

  @override
  String get tourMessagesDescription =>
      'Chatte hier mit deinen Matches. Sende Nachrichten, Fotos und Sprachnachrichten zum Verbinden.';

  @override
  String get tourMessagesTitle => 'Nachrichten';

  @override
  String get tourNext => 'Weiter';

  @override
  String get tourPlayDescription =>
      'Fordere andere in lustigen Sprachspielen heraus';

  @override
  String get tourPlayTitle => 'Spiele';

  @override
  String get tourProfileDescription =>
      'Passe dein Profil an, verwalte Einstellungen und kontrolliere deine Privatsphäre.';

  @override
  String get tourProfileTitle => 'Dein Profil';

  @override
  String get tourProgressDescription =>
      'Verdiene Abzeichen, schließe Herausforderungen ab und steige in der Rangliste auf!';

  @override
  String get tourProgressTitle => 'Fortschritt Verfolgen';

  @override
  String get tourShopDescription =>
      'Hole dir Münzen und Premium-Funktionen für ein besseres Erlebnis.';

  @override
  String get tourShopTitle => 'Shop und Münzen';

  @override
  String get tourSkip => 'Überspringen';

  @override
  String get translateWord => 'Übersetze dieses Wort';

  @override
  String get translationDownloadExplanation =>
      'Um die automatische Nachrichtenübersetzung zu aktivieren, müssen wir Sprachdaten für die Offline-Nutzung herunterladen.';

  @override
  String get travelCategory => 'Reise';

  @override
  String get travelLabel => 'Reise';

  @override
  String get travelerAppearFor24Hours =>
      'Du erscheinst 24 Stunden lang in den Suchergebnissen für diesen Standort.';

  @override
  String get travelerBadge => 'Reisender';

  @override
  String get travelerChangeLocation => 'Standort ändern';

  @override
  String get travelerConfirmLocation => 'Standort bestätigen';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'Standort konnte nicht ermittelt werden: $error';
  }

  @override
  String get travelerGettingLocation => 'Standort wird ermittelt...';

  @override
  String travelerInCity(String city) {
    return 'In $city';
  }

  @override
  String get travelerLoadingAddress => 'Adresse wird geladen...';

  @override
  String get travelerLocationInfo =>
      'Du erscheinst 24 Stunden lang in den Entdeckungsergebnissen für diesen Standort.';

  @override
  String get travelerLocationPermissionsDenied =>
      'Standortberechtigungen verweigert';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Standortberechtigungen dauerhaft verweigert';

  @override
  String get travelerLocationServicesDisabled =>
      'Standortdienste sind deaktiviert';

  @override
  String travelerModeActivated(String city) {
    return 'Reisemodus aktiviert! Du erscheinst 24 Stunden in $city.';
  }

  @override
  String get travelerModeActive => 'Reisemodus aktiv';

  @override
  String get travelerModeDeactivated =>
      'Reisemodus deaktiviert. Zurück zu deinem echten Standort.';

  @override
  String get travelerModeDescription =>
      'Erscheine 24 Stunden lang im Entdeckungs-Feed einer anderen Stadt';

  @override
  String get travelerModeTitle => 'Reisemodus';

  @override
  String travelerNoResultsFor(Object query) {
    return 'Keine Ergebnisse für \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Auf der Karte wählen';

  @override
  String get travelerProfileAppearDescription =>
      'Dein Profil erscheint 24 Stunden lang im Entdeckungs-Feed dieses Standorts mit einem Reise-Abzeichen.';

  @override
  String get travelerSearchHint =>
      'Dein Profil erscheint 24 Stunden lang im Entdeckungs-Feed dieses Standorts mit einem Reisenden-Abzeichen.';

  @override
  String get travelerSearchOrGps =>
      'Nach einer Stadt suchen oder GPS verwenden';

  @override
  String get travelerSelectOnMap => 'Auf der Karte auswählen';

  @override
  String get travelerSelectThisLocation => 'Diesen Standort auswählen';

  @override
  String get travelerSelectTravelLocation => 'Reiseziel auswählen';

  @override
  String get travelerTapOnMap =>
      'Tippe auf die Karte, um einen Standort auszuwählen';

  @override
  String get travelerUseGps => 'GPS verwenden';

  @override
  String get tryAgain => 'Erneut Versuchen';

  @override
  String get tryDifferentSearchOrFilter =>
      'Versuche eine andere Suche oder Filter';

  @override
  String get twoFaDisabled => '2FA-Authentifizierung deaktiviert';

  @override
  String get twoFaEnabled => '2FA-Authentifizierung aktiviert';

  @override
  String get twoFaToggleSubtitle =>
      'E-Mail-Code-Verifizierung bei jeder Anmeldung erforderlich';

  @override
  String get twoFaToggleTitle => '2FA-Authentifizierung aktivieren';

  @override
  String get typeMessage => 'Nachricht eingeben...';

  @override
  String get typeQuizzes => 'Quizze';

  @override
  String get typeStreak => 'Serie';

  @override
  String typeWordStartingWith(String letter) {
    return 'Schreibe ein Wort, das mit \"$letter\" beginnt';
  }

  @override
  String get typeWordsLearned => 'Gelernte Wörter';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'Profil kann nicht geladen werden';

  @override
  String get unableToPlayVoiceIntro =>
      'Sprachvorstellung kann nicht abgespielt werden';

  @override
  String get undoSwipe => 'Swipe rückgängig';

  @override
  String unitLabelN(String number) {
    return 'Einheit $number';
  }

  @override
  String get unlimited => 'Unbegrenzt';

  @override
  String get unlock => 'Freischalten';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return '$count weitere Profile in der Rasteransicht für $cost Münzen freischalten.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Bist du sicher, dass du das Match mit $name aufloesen moechtest? Dies kann nicht rueckgaengig gemacht werden.';
  }

  @override
  String get unmatchLabel => 'Match aufloesen';

  @override
  String unmatchedWith(String name) {
    return 'Entmatcht mit $name';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeForEarlyAccess =>
      'Upgraden Sie auf Silber, Gold oder Platin für frühen Zugang am 1. März 2026!';

  @override
  String get upgradeNow => 'Jetzt upgraden';

  @override
  String get upgradeToPremium => 'Auf Premium Upgraden';

  @override
  String upgradeToTier(String tier) {
    return 'Upgrade auf $tier';
  }

  @override
  String get uploadPhoto => 'Foto Hochladen';

  @override
  String get uppercaseLowercase => 'Groß- und Kleinbuchstaben';

  @override
  String get useCurrentGpsLocation => 'Meinen aktuellen GPS-Standort verwenden';

  @override
  String get usedToday => 'Heute verwendet';

  @override
  String get usedWords => 'Verwendete Wörter';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName wurde blockiert';
  }

  @override
  String get userBlockedTitle => 'Benutzer blockiert!';

  @override
  String get userNotFound => 'Benutzer nicht gefunden';

  @override
  String get usernameOrProfileUrl => 'Benutzername oder Profil-URL';

  @override
  String get usernameWithoutAt => 'Benutzername (ohne @)';

  @override
  String get verificationApproved => 'Verifizierung Genehmigt';

  @override
  String get verificationApprovedMessage =>
      'Deine Identität wurde verifiziert. Du hast jetzt vollen Zugriff auf die App.';

  @override
  String get verificationApprovedSuccess =>
      'Verifizierung erfolgreich genehmigt';

  @override
  String get verificationDescription =>
      'Um die Sicherheit unserer Community zu gewährleisten, müssen alle Benutzer ihre Identität verifizieren. Bitte mache ein Foto von dir mit deinem Ausweisdokument in der Hand.';

  @override
  String get verificationHistory => 'Verifizierungsverlauf';

  @override
  String get verificationInstructions =>
      'Halte dein Ausweisdokument (Reisepass, Führerschein oder Personalausweis) neben dein Gesicht und mache ein klares Foto.';

  @override
  String get verificationNeedsResubmission => 'Besseres Foto Erforderlich';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Wir benötigen ein klareres Foto zur Verifizierung. Bitte erneut einreichen.';

  @override
  String get verificationPanel => 'Verifizierungsbereich';

  @override
  String get verificationPending => 'Verifizierung Ausstehend';

  @override
  String get verificationPendingMessage =>
      'Dein Konto wird verifiziert. Dies dauert normalerweise 24-48 Stunden. Du wirst benachrichtigt, sobald die Prüfung abgeschlossen ist.';

  @override
  String get verificationRejected => 'Verifizierung Abgelehnt';

  @override
  String get verificationRejectedMessage =>
      'Deine Verifizierung wurde abgelehnt. Bitte reiche ein neues Foto ein.';

  @override
  String get verificationRejectedSuccess => 'Verifizierung abgelehnt';

  @override
  String get verificationRequired => 'Identitätsprüfung Erforderlich';

  @override
  String get verificationSkipWarning =>
      'Du kannst die App durchsuchen, aber du kannst nicht chatten oder andere Profile sehen, bis du verifiziert bist.';

  @override
  String get verificationTip1 => 'Sorge für gute Beleuchtung';

  @override
  String get verificationTip2 =>
      'Dein Gesicht und das Dokument müssen klar sichtbar sein';

  @override
  String get verificationTip3 =>
      'Halte das Dokument neben dein Gesicht, nicht davor';

  @override
  String get verificationTip4 => 'Der Text auf dem Dokument muss lesbar sein';

  @override
  String get verificationTips => 'Tipps für eine erfolgreiche Verifizierung:';

  @override
  String get verificationTitle => 'Verifiziere Deine Identität';

  @override
  String get verifyNow => 'Jetzt Verifizieren';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit Tags ausgewählt';
  }

  @override
  String get vibeTagsGet5Tags => '5 Tags erhalten';

  @override
  String get vibeTagsGetAccessTo => 'Zugang erhalten zu:';

  @override
  String get vibeTagsLimitReached => 'Tag-Limit erreicht';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Kostenlose Nutzer können bis zu $limit Tags auswählen. Upgrade auf Premium für 5 Tags!';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'Du hast dein Maximum von $limit Tags erreicht. Entferne eines, um ein neues hinzuzufügen.';
  }

  @override
  String get vibeTagsNoTags => 'Keine Tags verfügbar';

  @override
  String get vibeTagsPremiumFeature1 => '5 Vibe-Tags statt 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Exklusive Premium-Tags';

  @override
  String get vibeTagsPremiumFeature3 => 'Priorität in Suchergebnissen';

  @override
  String get vibeTagsPremiumFeature4 => 'Und vieles mehr!';

  @override
  String get vibeTagsRemoveTag => 'Tag entfernen';

  @override
  String get vibeTagsSelectDescription =>
      'Wähle Tags, die zu deiner aktuellen Stimmung und Absichten passen';

  @override
  String get vibeTagsSetTemporary => 'Als temporären Tag setzen (24 Std.)';

  @override
  String get vibeTagsShowYourVibe => 'Zeig deine Stimmung';

  @override
  String get vibeTagsTemporaryDescription =>
      'Zeige diese Stimmung für die nächsten 24 Stunden';

  @override
  String get vibeTagsTemporaryTag => 'Temporärer Tag (24 Std.)';

  @override
  String get vibeTagsTitle => 'Dein Vibe';

  @override
  String get vibeTagsUpgradeToPremium => 'Auf Premium upgraden';

  @override
  String get vibeTagsViewPlans => 'Tarife ansehen';

  @override
  String get vibeTagsYourSelected => 'Deine ausgewählten Tags';

  @override
  String get videoCallCategory => 'Videoanruf';

  @override
  String get view => 'Ansehen';

  @override
  String get viewAllChallenges => 'Alle Herausforderungen anzeigen';

  @override
  String get viewAllLabel => 'Alle anzeigen';

  @override
  String get viewBadgesAchievementsLevel =>
      'Abzeichen, Erfolge und Level anzeigen';

  @override
  String get viewMyProfile => 'Mein Profil Anzeigen';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'GOLD MITGLIED';

  @override
  String get vipPlatinumMember => 'PLATIN VIP';

  @override
  String get vipPremiumBenefitsActive => 'Premium-Vorteile Aktiv';

  @override
  String get vipSilverMember => 'SILBER MITGLIED';

  @override
  String get virtualGiftsAddMessageHint => 'Nachricht hinzufügen (optional)';

  @override
  String get voiceDeleteConfirm =>
      'Bist du sicher, dass du deine Sprachvorstellung löschen möchtest?';

  @override
  String get voiceDeleteRecording => 'Aufnahme Löschen';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'Aufnahme konnte nicht gestartet werden: $error';
  }

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'Aufnahme konnte nicht hochgeladen werden: $error';
  }

  @override
  String get voiceIntro => 'Sprachvorstellung';

  @override
  String get voiceIntroSaved => 'Sprachvorstellung gespeichert';

  @override
  String get voiceIntroShort => 'Sprachintro';

  @override
  String get voiceIntroduction => 'Sprachvorstellung';

  @override
  String get voiceIntroductionInfo =>
      'Sprachvorstellungen helfen anderen, dich besser kennenzulernen. Dieser Schritt ist optional.';

  @override
  String get voiceIntroductionSubtitle =>
      'Nimm eine kurze Sprachnachricht auf (optional)';

  @override
  String get voiceIntroductionTitle => 'Sprachvorstellung';

  @override
  String get voiceMicrophonePermissionRequired =>
      'Mikrofonberechtigung erforderlich';

  @override
  String get voiceRecordAgain => 'Erneut Aufnehmen';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Nimm eine kurze $seconds Sekunden Vorstellung auf, damit andere deine Persönlichkeit hören können.';
  }

  @override
  String get voiceRecorded => 'Stimme aufgenommen';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'Aufnahme... (max. $maxDuration Sekunden)';
  }

  @override
  String get voiceRecordingReady => 'Aufnahme bereit';

  @override
  String get voiceRecordingSaved => 'Aufnahme gespeichert';

  @override
  String get voiceRecordingTips => 'Aufnahmetipps';

  @override
  String get voiceSavedMessage => 'Deine Sprachvorstellung wurde aktualisiert';

  @override
  String get voiceSavedTitle => 'Sprachaufnahme gespeichert!';

  @override
  String get voiceStandOutWithYourVoice => 'Hebe dich mit deiner Stimme ab!';

  @override
  String get voiceTapToRecord => 'Tippen zum Aufnehmen';

  @override
  String get voiceTipBeYourself => 'Sei du selbst und natürlich';

  @override
  String get voiceTipFindQuietPlace => 'Finde einen ruhigen Ort';

  @override
  String get voiceTipKeepItShort => 'Halte es kurz und knapp';

  @override
  String get voiceTipShareWhatMakesYouUnique =>
      'Teile was dich einzigartig macht';

  @override
  String get voiceUploadFailed => 'Hochladen der Sprachaufnahme fehlgeschlagen';

  @override
  String get voiceUploading => 'Wird hochgeladen...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic => 'Ihr Zugang beginnt am 15. März 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'Als $tier-Mitglied erhalten Sie frühen Zugang am 1. März 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'Ihr Zugangsdatum';

  @override
  String waitingCountLabel(String count) {
    return '$count warten';
  }

  @override
  String get waitingCountdownLabel => 'Countdown zum Start';

  @override
  String get waitingCountdownSubtitle =>
      'Vielen Dank für Ihre Registrierung! GreenGo Chat startet bald. Freuen Sie sich auf ein exklusives Erlebnis.';

  @override
  String get waitingCountdownTitle => 'Countdown bis zum Start';

  @override
  String waitingDaysRemaining(int days) {
    return '$days Tage';
  }

  @override
  String get waitingEarlyAccessMember => 'Early Access Mitglied';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Aktivieren Sie Benachrichtigungen, um als Erster zu erfahren, wann Sie auf die App zugreifen können.';

  @override
  String get waitingEnableNotificationsTitle => 'Bleiben Sie auf dem Laufenden';

  @override
  String get waitingExclusiveAccess => 'Ihr exklusives Zugangsdatum';

  @override
  String get waitingForPlayers => 'Warte auf Spieler...';

  @override
  String get waitingForVerification => 'Warte auf Verifizierung...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours Stunden';
  }

  @override
  String get waitingMessageApproved =>
      'Gute Nachrichten! Ihr Konto wurde genehmigt. Sie können GreenGoChat ab dem unten angezeigten Datum nutzen.';

  @override
  String get waitingMessagePending =>
      'Ihr Konto wartet auf die Genehmigung durch unser Team. Wir werden Sie benachrichtigen, sobald Ihr Konto überprüft wurde.';

  @override
  String get waitingMessageRejected =>
      'Leider konnte Ihr Konto derzeit nicht genehmigt werden. Bitte kontaktieren Sie den Support für weitere Informationen.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes Minuten';
  }

  @override
  String get waitingNotificationEnabled =>
      'Benachrichtigungen aktiviert - wir informieren Sie, wenn Sie auf die App zugreifen können!';

  @override
  String get waitingProfileUnderReview => 'Profil wird überprüft';

  @override
  String get waitingReviewMessage =>
      'Die App ist jetzt live! Unser Team überprüft Ihr Profil, um das beste Erlebnis für unsere Community zu gewährleisten. Dies dauert normalerweise 24-48 Stunden.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds Sekunden';
  }

  @override
  String get waitingStayTuned =>
      'Bleiben Sie dran! Wir werden Sie benachrichtigen, wenn es Zeit ist, sich zu verbinden.';

  @override
  String get waitingStepActivation => 'Kontoaktivierung';

  @override
  String get waitingStepRegistration => 'Registrierung abgeschlossen';

  @override
  String get waitingStepReview => 'Profilüberprüfung läuft';

  @override
  String get waitingSubtitle => 'Ihr Konto wurde erfolgreich erstellt';

  @override
  String get waitingThankYouRegistration =>
      'Vielen Dank für Ihre Registrierung!';

  @override
  String get waitingTitle => 'Vielen Dank für Ihre Registrierung!';

  @override
  String get weeklyChallengesTitle => 'Wöchentliche Herausforderungen';

  @override
  String get weight => 'Gewicht';

  @override
  String get weightLabel => 'Gewicht';

  @override
  String get welcome => 'Willkommen bei GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Wort bereits verwendet';

  @override
  String get wordReported => 'Wort gemeldet';

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
    return '$amount XP verdient';
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
  String get yearlyMembership => 'Jahresmitgliedschaft';

  @override
  String yearsLabel(int age) {
    return '$age Jahre';
  }

  @override
  String get yes => 'Ja';

  @override
  String get yesterday => 'gestern';

  @override
  String youAndMatched(String name) {
    return 'Sie und $name mögen sich gegenseitig';
  }

  @override
  String get youGotSuperLike => 'Du hast eine Prioritätsverbindung erhalten!';

  @override
  String get youLabel => 'DU';

  @override
  String get youLose => 'Du hast Verloren';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Du hast mit $name am $date gematcht';
  }

  @override
  String get youWin => 'Du hast Gewonnen!';

  @override
  String get yourLanguages => 'Deine Sprachen';

  @override
  String get yourRankLabel => 'Dein Rang';

  @override
  String get yourTurn => 'Du bist dran!';

  @override
  String get achievementBadges => 'Abzeichen';

  @override
  String get achievementBadgesSubtitle =>
      'Tippe, um auszuwählen, welche Abzeichen auf deinem Profil angezeigt werden (max. 5)';

  @override
  String get noBadgesYet => 'Schalte Erfolge frei, um Abzeichen zu verdienen!';
}
