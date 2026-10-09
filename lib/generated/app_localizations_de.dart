// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get culturalPassportTitle => 'Kulturpass';

  @override
  String get culturalPassportSubtitle =>
      'Stempel, die du aus den Kulturen, Sprachen und Events sammelst, die du erkundest';

  @override
  String get passportSectionCountries => 'Länder';

  @override
  String get passportSectionLanguages => 'Sprachen';

  @override
  String get passportSectionEvents => 'Events';

  @override
  String get passportLoading => 'Dein Pass wird geladen…';

  @override
  String get passportEarned => 'Erhalten';

  @override
  String get passportLocked => 'Gesperrt';

  @override
  String get passportEmpty =>
      'Fang an zu chatten, Sprachen zu lernen und an Events teilzunehmen, um deine ersten Stempel zu verdienen.';

  @override
  String passportProgressSummary(int countries, int languages, int events) {
    return '$countries Länder · $languages Sprachen · $events Events';
  }

  @override
  String passportOverallProgress(int percent) {
    return '$percent% erkundet';
  }

  @override
  String get passportEventDating => 'Treffen';

  @override
  String get passportEventSocial => 'Sozial';

  @override
  String get passportEventSports => 'Sport';

  @override
  String get passportEventFood => 'Essen';

  @override
  String get passportEventNightlife => 'Nachtleben';

  @override
  String get passportEventOutdoor => 'Outdoor';

  @override
  String get passportEventArts => 'Kunst';

  @override
  String get passportEventGaming => 'Gaming';

  @override
  String get passportEventTravel => 'Reisen';

  @override
  String get passportEventWellness => 'Wellness';

  @override
  String get passportEventLanguageExchange => 'Sprachaustausch';

  @override
  String get passportEventOther => 'Sonstiges';

  @override
  String get tourGotIt => 'Verstanden';

  @override
  String get tourWelcomeTitle => 'Willkommen bei GreenGo!';

  @override
  String get tourWelcomeDesc =>
      'Das ist dein Discovery-Raster — echte Menschen in deiner Nähe, nach Entfernung sortiert. Lerne die Gesten kennen, mit denen GreenGo schnell zu bedienen ist.';

  @override
  String get tourCardTapTitle => 'Karte antippen';

  @override
  String get tourCardTapDesc =>
      'Tippe auf die Mitte einer Karte, um das Aktionsmenü zu öffnen – verbinden, Priority Connect oder das ganze Profil ansehen.';

  @override
  String get tourCardEdgeTitle => 'Fotos durchblättern';

  @override
  String get tourCardEdgeDesc =>
      'Tippe auf den linken oder rechten Rand einer Karte, um durch die Fotos der Person zu blättern, ohne das Raster zu verlassen.';

  @override
  String get tourCardHoldTitle => 'Halten für Vorschau';

  @override
  String get tourCardHoldDesc =>
      'Halte eine Karte gedrückt, um Fotos im Vollbild anzusehen.';

  @override
  String get tourRefreshTitle => 'Zum Aktualisieren ziehen';

  @override
  String get tourRefreshDesc =>
      'Ziehe das Raster jederzeit nach unten, um die neuesten Menschen in deiner Nähe zu laden.';

  @override
  String get tourModeToggleTitle => 'Swipe-Modus';

  @override
  String get tourModeToggleDesc =>
      'Tippe hier, um zwischen Raster- und Swipe-Modus zu wechseln. Im Swipe-Modus: nach rechts wischen zum Verbinden, nach links zum Überspringen, nach oben für ein Priority Connect.';

  @override
  String get tourGlobeTitle => 'Den Globus erkunden';

  @override
  String get tourGlobeDesc =>
      'Öffne den 3D-Globus und entdecke Menschen auf der ganzen Welt — nicht nur in deiner Nähe.';

  @override
  String get tourSearchTitle => 'Per Spitzname finden';

  @override
  String get tourSearchDesc =>
      'Du weißt, wen du suchst? Suche Personen direkt über ihren Spitznamen.';

  @override
  String get tourPrefsTitle => 'Discovery-Filter';

  @override
  String get tourPrefsDesc =>
      'Lege fest, wen du entdeckst: Entfernung, Alter, Sprachen, Land und mehr.';

  @override
  String get tourCoinsTitle => 'Deine Coins';

  @override
  String get tourCoinsDesc =>
      'Du erhältst jeden Tag Gratis-Coins. Tippe jederzeit auf dein Guthaben, um den Shop zu öffnen.';

  @override
  String get tourHelpTitle => 'Brauchst du Hilfe?';

  @override
  String get tourHelpDesc =>
      'Hier findest du den App-Guide — inklusive dieses Tutorials, das du jederzeit wiederholen kannst.';

  @override
  String get tourNavMessagesTitle => 'Nachrichten';

  @override
  String get tourNavMessagesDesc =>
      'Chatte ohne Sprachbarrieren — halte eine Nachricht gedrückt, um sie zu übersetzen, oder tippe doppelt, um sie anzuhören.';

  @override
  String get tourNavLeaderboardTitle => 'Rangliste';

  @override
  String get tourNavLeaderboardDesc =>
      'Sammle XP und Abzeichen, während du Kontakte knüpfst, chattest und lernst. Sieh, wo du stehst.';

  @override
  String get tourNavShopTitle => 'Shop';

  @override
  String get tourNavShopDesc =>
      'Coin-Pakete und Mitgliedschaften, um mehr von GreenGo freizuschalten.';

  @override
  String get tourNavProfileTitle => 'Dein Profil';

  @override
  String get tourNavProfileDesc =>
      'Vervollständige dein Profil und die Verifizierung, um von mehr Menschen entdeckt zu werden.';

  @override
  String get tourFinishTitle => 'Alles bereit!';

  @override
  String get tourFinishDesc =>
      'Viel Spaß beim Entdecken neuer Menschen und Kulturen. Du kannst dieses Tutorial jederzeit über den Guide (?-Symbol) wiederholen.';

  @override
  String get tourSwipeHintTitle => 'Wischen und verbinden';

  @override
  String get tourSwipeHintLike => 'Like';

  @override
  String get tourSwipeHintPass => 'Passen';

  @override
  String get tourSwipeHintSuper => 'Priority Connect';

  @override
  String get tourChatHoldTitle => 'Nachricht halten';

  @override
  String get tourChatHoldDesc =>
      'Halte eine Nachricht gedrückt, um sie zu übersetzen, zu kopieren oder weiterzuleiten.';

  @override
  String get tourChatDoubleTapTitle => 'Anhören';

  @override
  String get tourChatDoubleTapDesc =>
      'Tippe doppelt auf eine empfangene Nachricht, um die Aussprache zu hören.';

  @override
  String get tourChatLanguageTitle => 'Sprachen & Lernen';

  @override
  String get tourChatLanguageDesc =>
      'Öffne das Übersetzungsmenü für Sprachtools: Übersetzungseinstellungen, Aussprachetraining und Lernfunktionen.';

  @override
  String get tourChatSettingsTitle => 'Chat-Optionen';

  @override
  String get tourChatSettingsDesc =>
      'Verwalte diese Unterhaltung: Chat-Einstellungen, löschen, blockieren oder melden.';

  @override
  String get tourDetailDoubleTapTitle => 'Foto liken';

  @override
  String get tourDetailDoubleTapDesc =>
      'Tippe doppelt auf ein Foto, um es zu liken.';

  @override
  String get tourStoryHoldHint => 'Halten zum Pausieren';

  @override
  String get guideReplayTour => 'Tutorial wiederholen';

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
      'Verbindungs- und Nachrichtenstatistiken ansehen';

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
  String get adminMatchPriority => 'Verbindungspriorität';

  @override
  String get adminMatchingAndVisibility => 'Verbindungen & Sichtbarkeit';

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
  String get appTagline => 'Entdecke Kulturen und Menschen weltweit';

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
  String get achievementUnlockedTitle => 'ERFOLG FREIGESCHALTET!';

  @override
  String get achievementUnlockedAwesome => 'Super!';

  @override
  String get achievementRarityCommon => 'GEWÖHNLICH';

  @override
  String get achievementRarityUncommon => 'UNGEWÖHNLICH';

  @override
  String get achievementRarityRare => 'SELTEN';

  @override
  String get achievementRarityEpic => 'EPISCH';

  @override
  String get achievementRarityLegendary => 'LEGENDÄR';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

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
      'Rückgängig nicht möglich – ihr seid bereits verbunden!';

  @override
  String get casualDating => 'Lockere Treffen';

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
  String chatSeeExchangeDetails(String name) {
    return 'Austauschdetails mit $name anzeigen';
  }

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
      'Entdecke Menschen und verbinde dich, um zu chatten!';

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
  String get translationFailedTapRetry =>
      'Übersetzung fehlgeschlagen · Tippe, um es erneut zu versuchen';

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
  String get coinsToday => 'Heute';

  @override
  String get coinsTransactionHistory => 'Transaktionsverlauf';

  @override
  String get coinsTransactionsAppearHere =>
      'Deine Coin-Transaktionen werden hier angezeigt';

  @override
  String get coinsUnlockPremium => 'Premium-Funktionen freischalten';

  @override
  String get coinsVideoCallMatches => 'Videoanruf mit deinen Kontakten';

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
  String get communitiesCoverImageLabel => 'Titelbild';

  @override
  String get communitiesCoverImageHint => 'Titelbild hinzufuegen (optional)';

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
  String get communitiesDeleteCommunity => 'Community loeschen';

  @override
  String communitiesDeleteConfirm(String name) {
    return '\"$name\" dauerhaft loeschen? Alle Nachrichten, Mitglieder und Inhalte werden entfernt. Dies kann nicht rueckgaengig gemacht werden.';
  }

  @override
  String get communitiesDeletedSuccess => 'Community geloescht';

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
  String get communitiesSaveFavorite => 'In Favoriten speichern';

  @override
  String get communitiesRemoveFavorite => 'Aus Favoriten entfernen';

  @override
  String get communitiesFavoritesSection => 'Favoriten';

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
  String get communitiesTabJoined => 'Beigetretene Communities';

  @override
  String get communitiesTabManaged => 'Meine Communities';

  @override
  String get communitiesNoManaged => 'Du verwaltest noch keine Communities';

  @override
  String get communitiesNoManagedSubtitle =>
      'Erstelle eine Community, um Menschen zusammenzubringen';

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
  String get culturalExchangeDatingEtiquette => 'Umgangsformen';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Leitfaden für Umgangsformen';

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
  String get discoveryFilterMatches => 'Verbindungen';

  @override
  String get discoveryFilterPassed => 'Abgelehnt';

  @override
  String get discoveryFilterSkipped => 'Erkundet';

  @override
  String get discoveryFilterSuperLiked => 'Priorität';

  @override
  String get discoveryFilterNetwork => 'Mein Netzwerk';

  @override
  String get discoveryFilterTravelers => 'Reisende';

  @override
  String get discoveryLimitReached => 'Du hast dein Entdeckungslimit erreicht';

  @override
  String discoverySeeMoreCoins(int coins) {
    return 'Gib $coins Münzen aus, um mehr zu sehen';
  }

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
      'Entdecke Menschen und knüpfe deine erste Verbindung!';

  @override
  String get emptyStateNoMatchesTitle => 'Noch keine Verbindungen';

  @override
  String get emptyStateNoMessagesMessage =>
      'Sobald du dich mit jemandem verbindest, kannst du hier chatten.';

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
  String get eventsCapacityAllowed => 'Erlaubte Kapazität';

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
  String get eventsFilterOngoing => 'Laufend';

  @override
  String get eventsFilterUpcoming => 'Bevorstehend';

  @override
  String get eventsFilterPast => 'Vergangen';

  @override
  String get eventsTabExperiences => 'Erlebnisse';

  @override
  String get eventsTabAttractions => 'Sehenswürdigkeiten';

  @override
  String get eventsTabCommunity => 'Community';

  @override
  String get eventsDeleteEvent => 'Event löschen';

  @override
  String get eventsDeleteConfirmBody =>
      'Möchten Sie dieses Event wirklich löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get eventsBook => 'Buchen';

  @override
  String get eventsFromPrice => 'ab';

  @override
  String get eventsTabNearby => 'In der Nähe';

  @override
  String get eventsTabUpcoming => 'Bevorstehend';

  @override
  String get eventsThisMonth => 'Diesen Monat';

  @override
  String get eventsDateUntil => 'Bis';

  @override
  String get eventsDateFrom => 'Ab';

  @override
  String get eventsCustomRange => 'Eigener Zeitraum';

  @override
  String get eventsDateAnyTime => 'Jederzeit';

  @override
  String get eventsThisWeekFilter => 'Diese Woche';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsAndPlacesTitle => 'Events & Orte';

  @override
  String get eventsCategoryAll => 'Alle';

  @override
  String attractionVisitWebsite(String host) {
    return '$host öffnen';
  }

  @override
  String get attractionVisitWikidata => 'wikidata.org öffnen';

  @override
  String get attractionOpenInMaps => 'In Karten öffnen';

  @override
  String get attractionOpenLink => 'Link öffnen';

  @override
  String get attractionOpenWebsite => 'Offizielle Website öffnen';

  @override
  String get attractionShareChat => 'In Chat teilen';

  @override
  String get attractionShareGroup => 'In Gruppe teilen';

  @override
  String get attractionDescribedAt => 'Mehr erfahren';

  @override
  String get attractionReport => 'Event melden';

  @override
  String get attractionReportConfirm =>
      'Diesen Eintrag als unangemessen oder falsch melden?';

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
  String get exploreTitle => 'Entdecken';

  @override
  String get communityTabTitle => 'Community';

  @override
  String exploreHeadline(String city) {
    return '$city entdecken';
  }

  @override
  String get exploreSubtitle =>
      'Kulturelle Erlebnisse und Sprachpartner in deiner Nähe';

  @override
  String get explorePracticeLanguage => 'Eine Sprache üben';

  @override
  String get exploreNetworkDiscovery => 'Netzwerk-Entdeckung';

  @override
  String exploreNetworkDiscoverySubtitle(String country) {
    return 'Menschen zum Vernetzen in $country';
  }

  @override
  String get exploreSeeAll => 'Alle ansehen';

  @override
  String get explorePromotedBadge => 'Gefoerdert';

  @override
  String get exploreHappeningThisWeek => 'Diese Woche';

  @override
  String get exploreHappeningToday => 'Heute los';

  @override
  String get exploreJoin => 'Beitreten';

  @override
  String get exploreFeatured => 'Empfohlenes Erlebnis';

  @override
  String exploreSpeaksLearning(String speaks, String learning) {
    return 'spricht $speaks · lernt $learning';
  }

  @override
  String exploreSpeaks(String language) {
    return 'spricht $language';
  }

  @override
  String get exploreAroundYou => 'Neue Leute entdecken';

  @override
  String get exploreSameInterests => 'Menschen mit denselben Interessen';

  @override
  String get exploreBusinessAccounts => 'Unternehmenskonten';

  @override
  String exploreSpeaksLanguage(String language) {
    return 'Menschen, die $language sprechen';
  }

  @override
  String get exploreCommunityEventsNearby => 'Community-Events in deiner Nähe';

  @override
  String get exploreNoPartners =>
      'Noch keine Sprachpartner in der Nähe — schau bald wieder vorbei.';

  @override
  String get exploreNoEvents =>
      'Noch keine Erlebnisse verfügbar — schau bald wieder vorbei.';

  @override
  String get exploreNoCommunities =>
      'Noch keine Communities zum Beitreten — schau bald wieder vorbei.';

  @override
  String exploreGoingCount(int count) {
    return '$count nehmen teil';
  }

  @override
  String get exploreFeaturedEvents => 'Empfohlene Events';

  @override
  String get exploreFeaturedAttractions => 'Empfohlene Attraktionen';

  @override
  String get exploreTopExperiences => 'Top-Erlebnisse';

  @override
  String get exploreMyNextEvents => 'Meine nächsten Events';

  @override
  String get exploreCommunitiesTitle => 'Communities zum Beitreten';

  @override
  String exploreMembersCount(int count) {
    return '$count Mitglieder';
  }

  @override
  String get exploreCountrySpotlight => 'Länder-Spotlight';

  @override
  String get greetingMorning => 'Guten Morgen';

  @override
  String get greetingAfternoon => 'Guten Tag';

  @override
  String get greetingEvening => 'Guten Abend';

  @override
  String get greetingNight => 'Gute Nacht';

  @override
  String get statCoins => 'Coins';

  @override
  String get statTier => 'Stufe';

  @override
  String get statCountries => 'Länder';

  @override
  String get statPeople => 'Menschen';

  @override
  String get networkWorldMap => 'Welt-Netzwerk';

  @override
  String get discoveryShowPeople => 'Personen anzeigen';

  @override
  String get discoveryShowBusinesses => 'Unternehmen anzeigen';

  @override
  String networkDiscoveryDistanceKm(String distance) {
    return '$distance km entfernt';
  }

  @override
  String get connectAction => 'Verbinden';

  @override
  String get connectError =>
      'Chat konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get sayHiAction => 'Hallo sagen';

  @override
  String get newConnectionLabel => 'Neue Verbindung';

  @override
  String get connectionsTitle => 'Verbindungen';

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
  String get filterFromMatch => 'Verbindung';

  @override
  String get filterFromSearch => 'Direkt';

  @override
  String get filterMessaged => 'Mit Nachrichten';

  @override
  String get filterNew => 'Neu';

  @override
  String get filterNewMessages => 'Neue';

  @override
  String get filterNotReplied => 'Ungelesen';

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
      'Super! Deine Interessen helfen uns, passendere Kontakte vorzuschlagen';

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
  String get itsAMatch => 'Jetzt verbinden!';

  @override
  String get joinMessage =>
      'Tritt GreenGoChat bei und vernetze dich mit Menschen aus aller Welt';

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
      'z. B. „Spanische Begrüßungen für Reisende“';

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
      'z. B. „Spanische Begrüßungen für Reisende“';

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
  String get letsExchange => 'Jetzt verbinden!';

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
  String get longTermRelationship => 'Langfristige Freundschaften';

  @override
  String get lookingFor => 'Sucht';

  @override
  String get lvl => 'LVL';

  @override
  String get manageCouponsTiersRules =>
      'Gutscheine, Stufen und Regeln verwalten';

  @override
  String get matchDetailsTitle => 'Austausch-Details';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Du und $name moechtet Sprachen austauschen!';
  }

  @override
  String get matchNotifKeepSwiping => 'Weiter swipen';

  @override
  String get matchNotifLetsChat => 'Lass uns chatten!';

  @override
  String get matchNotifLetsExchange => 'JETZT VERBINDEN!';

  @override
  String get matchNotifViewProfile => 'Profil ansehen';

  @override
  String matchPercentage(String percentage) {
    return '$percentage gemeinsam';
  }

  @override
  String matchedOnDate(String date) {
    return 'Verbunden am $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Du hast dich am $date mit $name verbunden';
  }

  @override
  String get matches => 'Verbindungen';

  @override
  String get matchesClearFilters => 'Filter loeschen';

  @override
  String matchesCount(int count) {
    return '$count Verbindungen';
  }

  @override
  String get matchesFilterAll => 'Alle';

  @override
  String get matchesFilterMessaged => 'Geschrieben';

  @override
  String get matchesFilterNew => 'Neu';

  @override
  String get matchesNoMatchesFound => 'Keine Verbindungen gefunden';

  @override
  String get matchesNoMatchesYet => 'Noch keine Verbindungen';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered von $total Verbindungen';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered von $total Verbindungen';
  }

  @override
  String get matchesStartSwiping =>
      'Entdecke Menschen und knüpfe Verbindungen!';

  @override
  String get matchesTryDifferent => 'Versuche eine andere Suche oder Filter';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Maximal $count Interessen erlaubt';
  }

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get discoverWorldwideTitle => 'Erweitere deinen Horizont!';

  @override
  String get discoverWorldwideMessage =>
      'Es gibt noch nicht viele Leute in deiner Nähe, aber GreenGo verbindet dich mit Menschen weltweit! Gehe zu den Filtern und füge weitere Länder hinzu, um tolle Menschen aus der ganzen Welt zu entdecken.';

  @override
  String get openFilters => 'Filter öffnen';

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
  String get couponRedeemTitle => 'Gutscheincode einlösen';

  @override
  String get referralCodeTitle => 'Hast du einen Empfehlungscode?';

  @override
  String get referralCodeLabel => 'Empfehlungscode (optional)';

  @override
  String get referralCodeHint => 'Code eines Freundes eingeben';

  @override
  String get couponApplyButton => 'Anwenden';

  @override
  String get couponAppliedSuccess => 'Gutschein angewendet';

  @override
  String get couponNotValid => 'Gutschein ungültig';

  @override
  String get freeBaseWeekInfo =>
      'Kein Gutschein? 1 Woche Base-Mitgliedschaft gratis!';

  @override
  String get couponRedeemSubtitle =>
      'Gib deinen Code ein, um deine Mitgliedschaft zu erweitern oder Gratis-Münzen zu erhalten';

  @override
  String get couponRedeemButton => 'Gutschein einlösen';

  @override
  String couponRedeemedSuccess(String grantSummary) {
    return 'Eingelöst: $grantSummary';
  }

  @override
  String get couponErrorInvalid => 'Dieser Gutscheincode ist ungültig';

  @override
  String get couponErrorExpired => 'Dieser Gutschein ist abgelaufen';

  @override
  String get couponErrorMaxUsesReached =>
      'Dieser Gutschein hat sein Nutzungslimit erreicht';

  @override
  String get couponErrorEmailMismatch =>
      'Dieser Gutschein ist auf ein anderes Konto beschränkt';

  @override
  String get couponErrorAlreadyRedeemed =>
      'Du hast diesen Gutschein bereits verwendet';

  @override
  String get couponErrorDisabled => 'Dieser Gutschein ist nicht mehr aktiv';

  @override
  String get couponErrorGeneric =>
      'Gutschein konnte nicht eingelöst werden. Bitte versuche es erneut.';

  @override
  String get registerCouponLabel => 'Gutscheincode (optional)';

  @override
  String get registerCouponHint => 'Gutscheincode eingeben';

  @override
  String get welcomeGrantTitle => 'Willkommen bei GreenGo!';

  @override
  String get welcomeGrantDismiss => 'Verstanden';

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
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get subscriptionAutoRenewInfo =>
      'Verlängert sich automatisch, sofern nicht 24 Std. vor Periodenende gekündigt. Verwaltung im Store-Konto.';

  @override
  String get subscriptionFreeTrialInfo =>
      'Neuabonnenten: 7 Tage kostenlos, danach zum angezeigten Preis. Kündigung 24 Std. vor Ablauf.';

  @override
  String get purchasesRestored => 'Käufe wiederhergestellt.';

  @override
  String get membershipExtendTitle => 'Mitgliedschaft verlängern';

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
  String get membershipActive => 'Aktiv';

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
  String get membershipExtendDescription =>
      'Deine Basismitgliedschaft ist aktiv. Kaufe ein weiteres Jahr, um dein Ablaufdatum zu verlängern.';

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
  String get menu => 'Menü';

  @override
  String socialLinkInvalid(String platform) {
    return 'Gib einen gültigen Link oder Benutzernamen für $platform ein';
  }

  @override
  String get messages => 'Austausch';

  @override
  String get messagesTabMessages => 'Nachrichten';

  @override
  String get messagesTabGroups => 'Gruppen';

  @override
  String get messagesTabBusiness => 'Business';

  @override
  String get messagesBusinessEmpty => 'Noch keine Storefront-Anfragen';

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
  String nicknameSearchActionNope(String nickname) {
    return 'Du hast für @$nickname gerade \"Nein\" gewählt';
  }

  @override
  String nicknameSearchActionSkip(String nickname) {
    return 'Du hast für @$nickname gerade \"Überspringen\" gewählt';
  }

  @override
  String nicknameSearchActionPriorityConnect(String nickname) {
    return 'Du hast für @$nickname gerade \"Priority Connect\" gewählt';
  }

  @override
  String nicknameSearchActionConnect(String nickname) {
    return 'Du hast für @$nickname gerade \"Verbinden\" gewählt';
  }

  @override
  String nicknameSearchActionMatch(String nickname) {
    return 'Du bist jetzt mit @$nickname verbunden!';
  }

  @override
  String nicknameSearchLimitReached(String action) {
    return 'Du hast dein $action-Limit erreicht. Versuche es später erneut.';
  }

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
  String get noMatchesFound => 'Keine Verbindungen gefunden';

  @override
  String get noMatchesYet => 'Noch keine Verbindungen';

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
      'Aktiviere Benachrichtigungen, um zu erfahren, wann du neue Verbindungen, Nachrichten und Priority Connects erhältst.';

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
  String get notificationMatchExpiring => 'Verbindung läuft ab';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Wenn eine Verbindung bald abläuft';

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
  String get notificationNewLikesSubtitle =>
      'Wenn sich jemand mit dir verbinden möchte';

  @override
  String notificationNewMatch(String nickname) {
    return 'Neue Verbindung! Du und @$nickname seid jetzt verbunden. Starte jetzt einen Chat.';
  }

  @override
  String get notificationNewMatches => 'Neue Verbindungen';

  @override
  String get notificationNewMatchesSubtitle =>
      'Wenn du eine neue Verbindung hast';

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
  String get notificationCategories => 'Benachrichtigungskategorien';

  @override
  String get notificationCatExchanges => 'Austausch-Chats';

  @override
  String get notificationCatExchangesSubtitle =>
      'Nachrichten aus deinen 1:1-Unterhaltungen';

  @override
  String get notificationCatGroups => 'Gruppenchats';

  @override
  String get notificationCatGroupsSubtitle =>
      'Nachrichten in deinen Gruppenchats';

  @override
  String get notificationCatBusiness => 'Business-Chats';

  @override
  String get notificationCatBusinessSubtitle =>
      'Nachrichten von Unternehmen, die du kontaktierst';

  @override
  String get notificationCatEventsChat => 'Event-Chats';

  @override
  String get notificationCatEventsChatSubtitle =>
      'Nachrichten in Events, denen du beigetreten bist';

  @override
  String get notificationCatCommunityChat => 'Community-Chats';

  @override
  String get notificationCatCommunityChatSubtitle =>
      'Nachrichten im Community-Chat';

  @override
  String get notificationCatAnnouncements => 'Ankündigungen & Events';

  @override
  String get notificationCatAnnouncementsSubtitle =>
      'Community-Ankündigungen und Events';

  @override
  String get notificationCatTips => 'Tipps';

  @override
  String get notificationCatTipsSubtitle => 'Community-Tipps und Vorschläge';

  @override
  String get notificationCatMessages => 'Nachrichten';

  @override
  String get notificationCatMessagesSubtitle =>
      'Direkt-, Gruppen-, Business- und Event-Chats';

  @override
  String get notificationCatEvents => 'Events';

  @override
  String get notificationCatEventsSubtitle =>
      'Events, Erinnerungen, Zusagen und Stadt-Benachrichtigungen';

  @override
  String get notificationCatCommunities => 'Communitys';

  @override
  String get notificationCatCommunitiesSubtitle =>
      'Ankündigungen und neue Mitglieder';

  @override
  String get notificationCatSocial => 'Soziales';

  @override
  String get notificationCatSocialSubtitle =>
      'Profilaufrufe, Follower, Bewertungen und Boosts';

  @override
  String get notificationCatAccount => 'Konto';

  @override
  String get notificationCatAccountSubtitle =>
      'Verifizierung und wichtige Kontoaktualisierungen';

  @override
  String get notificationEventCities => 'Community-Events nach Stadt';

  @override
  String get notificationEventCitiesSubtitle =>
      'Werde benachrichtigt, wenn in diesen Städten Events stattfinden';

  @override
  String get notificationAddCity => 'Stadt hinzufügen';

  @override
  String get notificationAddCityHint => 'z. B. Rom';

  @override
  String get notificationNoCities =>
      'Noch keine Städte — füge eine hinzu, um Event-Benachrichtigungen zu erhalten';

  @override
  String get notificationEnableInSettingsBody =>
      'Benachrichtigungen sind aus. Aktiviere sie in den Einstellungen, um Nachrichten, Events und Community-Benachrichtigungen zu erhalten.';

  @override
  String get notificationOpenSettings => 'Einstellungen öffnen';

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
      'Erzähle uns von deinen Interessen, deinen Sprachen und den Kulturen, die du entdecken möchtest...';

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
      'Deine Interessen helfen uns, dich mit Menschen zu verbinden, die deine Kultur und Sprachen teilen';

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
  String get onboardingMinLocation =>
      'Bitte lege deinen Standort fest, um fortzufahren';

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
  String get photoPrivateAlbumSuggestion =>
      'Du kannst dieses Foto stattdessen in dein privates Album hochladen, wo es nur Personen sehen, denen du Zugriff gibst.';

  @override
  String get photoUploadDeniedNudity =>
      'Upload abgelehnt - Verstoss: Nacktheit. Fotos in deinem oeffentlichen Profil muessen vollstaendig bekleidet sein.';

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
  String get preferenceLanguageFilter => 'Sprache';

  @override
  String get preferenceLanguageFilterDesc =>
      'Nur Personen anzeigen, die eine bestimmte Sprache sprechen';

  @override
  String get preferenceAnyLanguage => 'Alle Sprachen';

  @override
  String get preferenceInterestFilter => 'Interessen';

  @override
  String get preferenceInterestFilterDesc =>
      'Nur Personen anzeigen, die Ihre Interessen teilen';

  @override
  String get preferenceNoInterestFilter =>
      'Kein Interessenfilter — alle anzeigen';

  @override
  String get preferenceAddInterest => 'Interesse hinzufügen';

  @override
  String get preferenceSearchInterest => 'Interessen suchen...';

  @override
  String get preferenceNoInterestsFound => 'Keine Interessen gefunden';

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
  String get preferenceCountryRequired =>
      'Mindestens ein Land muss ausgewählt sein';

  @override
  String get preferenceByUsers => 'Nach Nutzern';

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
  String get priorityConnectNotificationMessage =>
      'Jemand möchte sich mit dir verbinden!';

  @override
  String get priorityConnectNotificationTitle => 'Priority Connect!';

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
      'Diese Aktion ist dauerhaft und kann nicht rückgängig gemacht werden. Alle deine Daten, Verbindungen und Nachrichten werden gelöscht. Bitte gib zur Bestätigung dein Passwort ein.';

  @override
  String get profileDiscoveryRestarted =>
      'Suche neu gestartet! Du kannst jetzt wieder alle Profile sehen.';

  @override
  String get profileDisplayName => 'Anzeigename';

  @override
  String get profileDobInfo =>
      'Dein Geburtsdatum kann aus Gründen der Altersverifizierung nicht geändert werden. Dein genaues Alter ist für deine Kontakte sichtbar.';

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
  String get profileLookingForHint => 'z. B. Sprachtandem-Partner';

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
      'Dadurch werden alle deine Swipes (Verbindungen, Ablehnungen, Prioritätsverbindungen) gelöscht, sodass du alle wieder von vorne entdecken kannst.\n\nDeine Verbindungen und Chats werden NICHT beeinflusst.';

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
  String get profileReauthProviderMismatch =>
      'Dieses Konto wurde mit einer sozialen Anmeldung (z. B. Google) erstellt, daher gibt es hier kein Passwort. Bitte loesche es ueber das verwendete Konto oder kontaktiere den Support.';

  @override
  String get profileTooManyAttempts =>
      'Zu viele Versuche. Aus Sicherheitsgruenden ist dieses Geraet voruebergehend gesperrt — bitte warte einige Minuten und versuche es erneut.';

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
      'Erlaube uns, deine Präferenzen zu analysieren, um bessere Kontaktvorschläge zu machen';

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
      'Sieh dir deine gesamte GreenGo-Reise und Meilensteine an';

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
  String get safetyCheckInEvery => 'Einchecken alle';

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
      'Sieh dir Profile an, die du übersprungen hast und die sich mit dir verbinden wollten!';

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
    return 'Wollte sich $ago verbinden';
  }

  @override
  String get secondChanceMatchBody =>
      'Ihr mögt euch gegenseitig! Starte eine Unterhaltung.';

  @override
  String get secondChanceMatchTitle => 'Jetzt verbinden!';

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
  String get shopPriorityMatching => 'Priorisierte Verbindungen';

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
  String get shopTemporarilyUnavailable =>
      'Käufe sind vorübergehend nicht verfügbar. Bitte versuche es später erneut.';

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
      'Schalte Premium-Funktionen frei und hol mehr aus GreenGo heraus';

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
  String get shortTermRelationship => 'Neue Bekanntschaften';

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
      'Deine Social-Media-Profile sind auf deinem GreenGo-Profil sichtbar und helfen anderen, deine Identität zu überprüfen.';

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
      'Entdecke Menschen und knüpfe Verbindungen!';

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
      'Stöbere durch Profile und finde Menschen zum Verbinden. Wische nach rechts zum Verbinden, nach links zum Überspringen.';

  @override
  String get tourDiscoveryTitle => 'Menschen entdecken';

  @override
  String get tourDone => 'Fertig';

  @override
  String get tourLearnDescription =>
      'Lerne Vokabeln, Grammatik und Konversationsfähigkeiten';

  @override
  String get tourLearnTitle => 'Sprachen Lernen';

  @override
  String get tourMatchesDescription =>
      'Sieh alle, die sich auch mit dir verbunden haben! Starte Gespräche mit deinen gegenseitigen Verbindungen.';

  @override
  String get tourMatchesTitle => 'Deine Verbindungen';

  @override
  String get tourMessagesDescription =>
      'Chatte hier mit deinen Kontakten. Sende Nachrichten, Fotos und Sprachnachrichten.';

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
      'Hol dir Münzen und Premium-Funktionen, um mehr aus GreenGo herauszuholen.';

  @override
  String get tourShopTitle => 'Shop und Münzen';

  @override
  String get tourSkip => 'Überspringen';

  @override
  String get trialWelcomeTitle => 'Willkommen bei GreenGo!';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'Du nutzt derzeit die Testversion. Deine kostenlose Basismitgliedschaft ist bis $expirationDate aktiv. Viel Spaß beim Entdecken von GreenGo!';
  }

  @override
  String get trialWelcomeButton => 'Los geht\'s';

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
    return 'Bist du sicher, dass du die Verbindung mit $name entfernen möchtest? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get unmatchLabel => 'Verbindung entfernen';

  @override
  String unmatchedWith(String name) {
    return 'Du bist nicht mehr mit $name verbunden';
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
  String get verificationPrivacyTitle => 'Deine Daten sind bei uns sicher';

  @override
  String get verificationPrivacyEncryption =>
      'Alle Dokumente werden mit Ende-zu-Ende-Verschlüsselung verschlüsselt. Nicht einmal GreenGo-Entwickler können auf deine Daten zugreifen.';

  @override
  String get verificationPrivacyAccess =>
      'Auf deine Informationen kann nur auf deine persönliche Anfrage über offizielle Kanäle oder per E-Mail zugegriffen werden.';

  @override
  String get verificationPrivacySafety =>
      'Dieser Schritt ist entscheidend, um alle Mitglieder zu schützen. Wir bitten dich, verdächtiges Verhalten zu melden, damit GreenGo eingreifen kann.';

  @override
  String get verificationPrivacyReporting =>
      'Wenn etwas passiert, melde es sofort. GreenGo wird ermitteln und handeln, um die Community sicher zu halten.';

  @override
  String get verificationChooseMethod => 'Wähle deine Verifizierungsmethode';

  @override
  String get verificationMethodPhoto => 'Ausweisdokument';

  @override
  String get verificationMethodPhotoDesc =>
      'Mache ein Foto, während du deinen Ausweis neben dein Gesicht hältst';

  @override
  String get verificationMethodPhone => 'Telefonnummer';

  @override
  String get verificationMethodPhoneDesc =>
      'Verifiziere per SMS-Code, der an dein Telefon gesendet wird';

  @override
  String get verificationPhoneTitle => 'Telefonverifizierung';

  @override
  String get verificationPhoneSubtitle =>
      'Gib deine Telefonnummer ein, um einen Verifizierungscode per SMS zu erhalten';

  @override
  String get verificationPhoneLabel => 'Telefonnummer';

  @override
  String get verificationPhoneHint => '+1 234 567 8900';

  @override
  String get verificationSendCode => 'Code senden';

  @override
  String get verificationEnterCode =>
      'Gib den 6-stelligen Code ein, der an dein Telefon gesendet wurde';

  @override
  String get verificationCodeLabel => 'Verifizierungscode';

  @override
  String get verificationVerifyCode => 'Code verifizieren';

  @override
  String get verificationPhoneSuccess =>
      'Telefonnummer erfolgreich verifiziert!';

  @override
  String get verificationPhoneResponsibility =>
      'Mit der Verifizierung deiner Telefonnummer bestätigst du, dass der Inhaber dieser Nummer persönlich für alle Aktionen verantwortlich ist, die mit diesem Konto durchgeführt werden.';

  @override
  String get verificationResendCode => 'Code erneut senden';

  @override
  String verificationCodeSent(String phoneNumber) {
    return 'Code gesendet an $phoneNumber';
  }

  @override
  String get verificationPhoneError =>
      'Telefonnummer konnte nicht verifiziert werden. Bitte versuche es erneut.';

  @override
  String get verificationInvalidCode =>
      'Ungültiger Code. Bitte überprüfe ihn und versuche es erneut.';

  @override
  String get verificationOr => 'oder';

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
  String get voiceMicPermissionDenied =>
      'Für die Sprachaufnahme wird Mikrofonzugriff benötigt';

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
  String get voiceMessageTooShort =>
      'Zum Aufnehmen halten, zum Senden loslassen';

  @override
  String get voiceSlideToCancel => '‹ Zum Abbrechen wischen';

  @override
  String get voiceReleaseToCancel => 'Zum Abbrechen loslassen';

  @override
  String get voiceFailedToSend =>
      'Sprachnachricht konnte nicht gesendet werden';

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
  String get waitingCountdownLabel => 'Ihr Startdatum';

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
  String get waitingExclusiveAccess => 'Zeit bis Sie die App nutzen können';

  @override
  String get waitingGeneralLaunchDate => 'Allgemeines Startdatum';

  @override
  String get waitingYourAccessDate => 'Ihr Zugangsdatum';

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
  String get yearlyMembership => 'Jahresabo';

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
    return 'Du hast dich am $date mit $name verbunden';
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

  @override
  String get guideTitle => 'So funktioniert GreenGo';

  @override
  String get guideSwipeTitle => 'Profile durchblättern';

  @override
  String get guideSwipeItem1 =>
      'Wische nach rechts, um jemanden zu Connect, wische nach links, um Nope zu wählen.';

  @override
  String get guideSwipeItem2 =>
      'Wische nach oben, um ein Priority Connect zu senden (kostet Münzen).';

  @override
  String get guideSwipeItem3 =>
      'Wische nach unten, um Explore Next zu wählen und ein Profil vorerst zu überspringen.';

  @override
  String get guideSwipeItem4 =>
      'Du kannst zwischen Wisch- und Rastermodus wechseln, indem du das Umschaltsymbol in der oberen Leiste verwendest.';

  @override
  String get guideGridTitle => 'Rasteransicht';

  @override
  String get guideGridItem1 =>
      'Durchsuche Profile in einer Rasteransicht für einen schnellen Überblick.';

  @override
  String get guideGridItem2 =>
      'Tippe auf ein Profilbild, um die vier Aktionsschaltflächen anzuzeigen: Connect, Priority Connect, Nope und Explore Next.';

  @override
  String get guideGridItem3 =>
      'Halte ein Profilbild lange gedrückt, um die Details zu sehen, ohne das vollständige Profil zu öffnen.';

  @override
  String get guideConnectionsTitle => 'Mit Menschen in Kontakt treten';

  @override
  String get guideConnectionsItem1 =>
      'Wenn zwei Personen sich gegenseitig Connect geben, entsteht eine Verbindung!';

  @override
  String get guideConnectionsItem2 =>
      'Sobald ihr verbunden seid, könnt ihr sofort chatten.';

  @override
  String get guideConnectionsItem3 =>
      'Verwende Priority Connect, um aufzufallen und deine Chancen zu erhöhen.';

  @override
  String get guideConnectionsItem4 =>
      'Überprüfe den Austausch-Tab, um all deine Verbindungen und Unterhaltungen zu sehen.';

  @override
  String get guideChatTitle => 'Chat & Nachrichten';

  @override
  String get guideChatItem1 =>
      'Sende Textnachrichten, Fotos und Sprachnachrichten.';

  @override
  String get guideChatItem2 =>
      'Nutze die Übersetzungsfunktion, um in verschiedenen Sprachen zu chatten.';

  @override
  String get guideChatItem3 =>
      'Öffne die Chat-Einstellungen, um dein Erlebnis anzupassen: aktiviere Grammatikprüfung, intelligente Antworten, Kulturtipps, Wortzerlegung, Aussprachehilfe und mehr.';

  @override
  String get guideChatItem4 =>
      'Aktiviere Text-to-Speech, um Übersetzungen anzuhören, Sprachflaggen anzuzeigen und deine Sprachlern-XP zu verfolgen.';

  @override
  String get guideFiltersTitle => 'Entdeckungsfilter';

  @override
  String get guideFiltersItem1 =>
      'Tippe auf das Filtersymbol, um deine Präferenzen einzustellen: Altersbereich, Entfernung, Sprachen und mehr.';

  @override
  String get guideFiltersItem2 =>
      'Zufallsmodus: Aktiviere diesen Schalter, um zufällige Personen aus der ganzen Welt zu entdecken. Jede Aktualisierung zeigt dir neue Profile. Wenn der Zufallsmodus deaktiviert ist, werden nur Personen in deiner Nähe angezeigt. Du kannst auch bestimmte Länder auswählen, um deine Suche einzugrenzen.';

  @override
  String get guideFiltersItem3 =>
      'Filter helfen dir, Menschen zu finden, die zu dem passen, was du suchst. Du kannst sie jederzeit anpassen.';

  @override
  String get guideTravelTitle => 'Reisen & Entdecken';

  @override
  String get guideTravelItem1 =>
      'Aktiviere den Traveler Mode, um 24 Stunden lang in der Entdeckung einer Stadt zu erscheinen, die du besuchen möchtest.';

  @override
  String get guideTravelItem2 =>
      'Lokale Guides können Reisenden helfen, ihre Stadt und Kultur zu entdecken.';

  @override
  String get guideTravelItem3 =>
      'Sprachtandem-Partner werden danach vorgeschlagen, was du sprichst und was du lernen möchtest.';

  @override
  String get guideMembershipTitle => 'Basismitgliedschaft';

  @override
  String get guideMembershipItem1 =>
      'Deine Basismitgliedschaft gibt dir Zugang zu allen Kernfunktionen: Swipen, Chatten und Verbinden.';

  @override
  String get guideMembershipItem2 =>
      'Die Mitgliedschaft beginnt mit einer kostenlosen Testphase nach deiner ersten Anmeldung.';

  @override
  String get guideMembershipItem3 =>
      'Wenn deine Mitgliedschaft abläuft, kannst du sie verlängern, um die App weiter zu nutzen.';

  @override
  String get guideTiersTitle => 'VIP-Stufen (Silber, Gold, Platin)';

  @override
  String get guideTiersItem1 =>
      'Silber: Erhalte mehr tägliche Connects, sieh wer dir ein Connect gesendet hat, und Prioritäts-Support.';

  @override
  String get guideTiersItem2 =>
      'Gold: Alles in Silber plus unbegrenzte Connects, erweiterte Filter und Lesebestätigungen.';

  @override
  String get guideTiersItem3 =>
      'Platin: Alles in Gold plus Profil-Boost, Top-Auswahl und exklusive Funktionen.';

  @override
  String get guideTiersItem4 =>
      'VIP-Stufen sind unabhängig von deiner Basismitgliedschaft und bieten zusätzliche Vorteile.';

  @override
  String get guideCoinsTitle => 'Münzen';

  @override
  String get guideCoinsItem1 =>
      'Münzen werden für Premium-Aktionen verwendet. Hier sind die Kosten:';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect: 10 Münzen  • Boost: 50 Münzen  • Direct Connect: 2/Tag gratis, danach 50 Münzen';

  @override
  String get guideCoinsItem3 =>
      '• Inkognito: 30 Münzen/Tag  • Reisemodus: 100 Münzen/Tag';

  @override
  String get guideCoinsItem4 =>
      '• Anhören (TTS): 5 Münzen  • Raster erweitern: 10 Münzen  • Lerncoach: 10 Münzen/Sitzung';

  @override
  String get guideCoinsItem5 =>
      'Du erhältst täglich 20 Gratis-Münzen. Verdiene mehr durch Erfolge, Ranglisten und den Shop.';

  @override
  String get guideLeaderboardTitle => 'Bestenliste';

  @override
  String get guideLeaderboardItem1 =>
      'Tritt gegen andere Nutzer an, um die Bestenliste zu erklimmen und Belohnungen zu verdienen.';

  @override
  String get guideLeaderboardItem2 =>
      'Sammle Punkte, indem du aktiv bist, dein Profil vervollständigst und mit anderen interagierst.';

  @override
  String get guideGridFiltersTitle => 'Rasterfilter';

  @override
  String get guideGridFiltersItem1 =>
      'Verwende im Rastermodus die Filterchips oben, um Profile einzugrenzen.';

  @override
  String get guideGridFiltersItem2 =>
      'Alle: Zeigt alle Personen in deinem Entdeckungspool.';

  @override
  String get guideGridFiltersItem3 =>
      'Verbunden: Personen, denen du eine Verbindungsanfrage gesendet hast.';

  @override
  String get guideGridFiltersItem4 =>
      'Priorität: Personen, denen du eine Prioritätsverbindung gesendet hast.';

  @override
  String get guideGridFiltersItem5 =>
      'Abgelehnt: Personen, die du übersprungen hast.';

  @override
  String get guideGridFiltersItem6 =>
      'Reisende: Personen mit aktivem Reisemodus, die eine Stadt in deiner Nähe besuchen.';

  @override
  String get guideExchangesTitle => 'Austausch (Chat)';

  @override
  String get guideExchangesItem1 =>
      'Im Austausch befinden sich alle deine Unterhaltungen. Du findest ihn im unteren Menü.';

  @override
  String get guideExchangesItem2 =>
      'Das rote Abzeichen am Austausch-Symbol zeigt die Anzahl der Unterhaltungen mit ungelesenen Nachrichten oder ausstehenden Genehmigungen.';

  @override
  String get guideExchangesItem3 =>
      'Nutze die Filter-Chips, um deine Chats zu organisieren: Alle, Neu, Nicht beantwortet, Favoriten, Zu genehmigen, Verbindung und Suche.';

  @override
  String get guideExchangesItem4 =>
      'Neu zeigt Unterhaltungen mit neuen Nachrichten, die du nicht gelesen hast. Nicht beantwortet zeigt Nachrichten, auf die du noch nicht geantwortet hast.';

  @override
  String get guideExchangesItem5 =>
      'Zu genehmigen zeigt Prioritätsverbindungsanfragen, die auf deine Entscheidung warten. Akzeptiere oder lehne sie direkt aus der Liste ab.';

  @override
  String get guideExchangesItem6 =>
      'Ungelesene Unterhaltungen werden mit fettem Text und einem goldenen Schimmereffekt hervorgehoben.';

  @override
  String get guideExchangesItem7 =>
      'Tippe auf eine Unterhaltung, um den Chat zu öffnen. Nach dem Öffnen wird sie als gelesen markiert und die Abzeichenzahl verringert sich.';

  @override
  String get guideExchangesItem8 =>
      'Halte eine Unterhaltung lang gedrückt für weitere Optionen. Verwende das Sternsymbol, um einen Chat zu deinen Favoriten hinzuzufügen.';

  @override
  String get guideExchangesItem9 =>
      'Jede Unterhaltung zeigt die Sprachflaggen des anderen Benutzers, damit du weißt, welche Sprachen er spricht.';

  @override
  String get guideGroupsTitle => 'Gruppen (Culture Circles)';

  @override
  String get guideGroupsItem1 =>
      'Erstelle eine Gruppe, um mit mehreren Personen gleichzeitig über ein gemeinsames Interesse oder eine Sprache zu chatten.';

  @override
  String get guideGroupsItem2 =>
      'Admins können die Gruppe umbenennen, das Foto ändern und Mitglieder hinzufügen oder entfernen.';

  @override
  String get guideGroupsItem3 =>
      'Lade Personen über ihren Spitznamen in den Gruppeninfos ein.';

  @override
  String get guideGroupsItem4 =>
      'Füge in den Gruppeninfos eigene private Tags zu einer Gruppe hinzu und filtere deine Gruppenliste nach Tags – nur du siehst deine Tags.';

  @override
  String get guideGroupsItem5 => 'Verlasse oder melde eine Gruppe jederzeit.';

  @override
  String get guideEventsTitle => 'Events';

  @override
  String get guideEventsItem1 =>
      'Entdecke Events in deiner Nähe – Partys, Museumsbesuche, Sprach-Treffen und Stadtrundgänge.';

  @override
  String get guideEventsItem2 =>
      'Stöbere in kuratierten Erlebnissen und Sehenswürdigkeiten oder erstelle dein eigenes Event mit Fotos, Ort und Datum.';

  @override
  String get guideEventsItem3 =>
      'Markiere Events als „Nehme teil“ oder „Interessiert“ und finde sie im Tab „Nehme teil“ wieder.';

  @override
  String get guideEventsItem4 =>
      'Jedes Event hat einen eigenen Chat; Organisatoren können Ankündigungen an alle Teilnehmer senden.';

  @override
  String get guideEventsItem5 =>
      'Teile jedes Event in einem privaten Chat oder einer Gruppe.';

  @override
  String get guideEventsItem6 =>
      'Entdecke Events weltweit auf der Karte nach Standort.';

  @override
  String get guideSafetyTitle => 'Sicherheit & Datenschutz';

  @override
  String get guideSafetyItem1 =>
      'Alle Fotos werden KI-verifiziert, um authentische Profile zu gewährleisten.';

  @override
  String get guideSafetyItem2 =>
      'Du kannst jeden Nutzer jederzeit über sein Profil blockieren oder melden.';

  @override
  String get guideSafetyItem3 =>
      'Deine persönlichen Daten sind geschützt und werden niemals ohne deine Zustimmung weitergegeben.';

  @override
  String get firstStepsTitle => 'Erste Schritte';

  @override
  String get firstStepsReview =>
      'Deine Dokumente werden innerhalb von 24–48 Stunden nach der Einreichung überprüft.';

  @override
  String get firstStepsStatusUpdate =>
      'Die App benötigt nach der ersten Anmeldung etwa 15 Minuten, um deinen aktuellen Status zu aktualisieren.';

  @override
  String get firstStepsSupportChat =>
      'Du kannst den Support über den Chat oder durch das Öffnen eines Tickets kontaktieren.';

  @override
  String get showSupportUser => 'GreenGo Support anzeigen';

  @override
  String get showSupportUserDescription =>
      'GreenGo-Support-Nutzer im Discovery-Raster anzeigen';

  @override
  String get preferenceShowMyNetwork => 'Mein Netzwerk';

  @override
  String get preferenceShowMyNetworkDesc =>
      'Nur Personen in deinem Netzwerk anzeigen.';

  @override
  String get randomMode => 'Zufallsmodus';

  @override
  String get randomModeDescription =>
      'Entdecke zufällige Menschen aus aller Welt, nach Entfernung sortiert. Wenn deaktiviert, werden nur Menschen in deiner Nähe angezeigt.';

  @override
  String get yourProfile => 'Du';

  @override
  String get loadingMsg1 =>
      'Auf der Suche nach tollen Profilen auf der ganzen Welt...';

  @override
  String get loadingMsg2 => 'Wir verbinden Menschen über Kontinente hinweg...';

  @override
  String get loadingMsg3 => 'Entdecke unglaubliche Menschen in deiner Nähe...';

  @override
  String get loadingMsg4 =>
      'Deine persönlichen Vorschläge werden vorbereitet...';

  @override
  String get loadingMsg5 => 'Profile aus allen Ecken der Welt erkunden...';

  @override
  String get loadingMsg6 => 'Menschen finden, die deine Interessen teilen...';

  @override
  String get loadingMsg7 => 'Dein Entdeckungserlebnis wird eingerichtet...';

  @override
  String get loadingMsg8 => 'Wunderschöne Profile werden für dich geladen...';

  @override
  String get loadingMsg9 => 'Wir suchen Menschen mit deinen Interessen...';

  @override
  String get loadingMsg10 => 'Die Welt näher zu dir bringen...';

  @override
  String get loadingMsg11 =>
      'Profile basierend auf deinen Vorlieben zusammenstellen...';

  @override
  String get loadingMsg12 =>
      'Fast geschafft! Gute Dinge brauchen einen Moment...';

  @override
  String get loadingMsg13 =>
      'Dich mit einer Welt voller Möglichkeiten verbinden...';

  @override
  String get loadingMsg14 => 'Wir finden tolle Menschen in deiner Nähe...';

  @override
  String get loadingMsg15 => 'Neue Verbindungen in deiner Nähe entdecken...';

  @override
  String get loadingMsg16 =>
      'Dein nächstes tolles Gespräch ist nur einen Swipe entfernt...';

  @override
  String get loadingMsg17 => 'Profile aus aller Welt sammeln...';

  @override
  String get loadingMsg18 => 'Etwas Besonderes für dich vorbereiten...';

  @override
  String get loadingMsg19 => 'Sicherstellen, dass alles perfekt ist...';

  @override
  String get loadingMsg20 =>
      'Neugier kennt keine Grenzen – und wir auch nicht...';

  @override
  String get loadingMsg21 => 'Deinen Discovery-Feed aufwärmen...';

  @override
  String get loadingMsg22 =>
      'Den Globus nach interessanten Menschen durchsuchen...';

  @override
  String get loadingMsg23 => 'Großartige Verbindungen beginnen hier...';

  @override
  String get loadingMsg24 => 'Dein Abenteuer beginnt gleich...';

  @override
  String get filterFavorites => 'Favoriten';

  @override
  String get filterToApprove => 'Zu genehmigen';

  @override
  String get priorityConnectAccept => 'Annehmen';

  @override
  String get priorityConnectReject => 'Ablehnen';

  @override
  String get priorityConnectPending => 'Genehmigung ausstehend';

  @override
  String get membershipTrialTitle => 'Starte deine Gratis-Testphase!';

  @override
  String get membershipTrialSubtitle =>
      '7 Tage kostenlos, danach jährliche Verlängerung';

  @override
  String get membershipTrialFeature1 =>
      'Unbegrenzt Communities, Events & Gruppen erstellen';

  @override
  String get membershipTrialFeature2 => 'Werbefrei — keine Anzeigen';

  @override
  String get membershipTrialFeature3 =>
      '500 Bonus-Coins + voller Zugriff auf alle Funktionen';

  @override
  String get membershipHaveCoupon => 'Hast du einen Gutscheincode?';

  @override
  String get membershipTrialCta => '7-Tage-Testphase starten';

  @override
  String get membershipTrialFooter =>
      'Jederzeit kündbar. Keine Gebühr bis Tag 8.';

  @override
  String get membershipTrialBadge => '7 TAGE GRATIS';

  @override
  String get globeMyNetwork => 'Mein Netzwerk';

  @override
  String get globeMyWorldMap => 'Meine Weltkarte';

  @override
  String get globeLayerContacts => 'Meine Community';

  @override
  String get globeLayerExperiences => 'Erlebnisse';

  @override
  String get globeYou => 'Du';

  @override
  String get globeConnections => 'Verbindungen';

  @override
  String get globeTraveler => 'Reisender';

  @override
  String globeConnectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbindungen',
      one: 'Verbindung',
    );
    return '$count $_temp0';
  }

  @override
  String globeConnectionsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbindungen',
      one: 'Verbindung',
    );
    return '$count $_temp0 hier';
  }

  @override
  String get globeThisIsYou => 'Das bist du!';

  @override
  String globeTravelingTo(String country) {
    return 'Unterwegs nach $country';
  }

  @override
  String globeNoConnectionsInCountry(String country) {
    return 'Noch keine Verbindungen in $country';
  }

  @override
  String get globeNoConnectionsHint =>
      'Knüpfe weiter Kontakte, um hier Menschen zu finden!';

  @override
  String get globeProfile => 'Profil';

  @override
  String get globeChat => 'Chat';

  @override
  String get globeViewProfileTooltip => 'Profil ansehen';

  @override
  String get globeOpenChatTooltip => 'Chat öffnen';

  @override
  String globeNoConnectionsInCountryTitle(String country) {
    return 'Keine Verbindungen in $country';
  }

  @override
  String get discoverabilityExact => 'Genau';

  @override
  String get discoverabilityExactDesc =>
      'Pin an deinem genauen Standort (<1 km)';

  @override
  String get discoverabilityApproximate => 'Ungefähr';

  @override
  String get discoverabilityApproximateDesc =>
      'Pin in deiner Region (~50-km-Raster, Standard)';

  @override
  String get discoverabilityCountry => 'Land';

  @override
  String get discoverabilityCountryDesc => 'Pin irgendwo in deinem Land';

  @override
  String get discoverabilityHidden => 'Verborgen';

  @override
  String get discoverabilityHiddenDesc => 'Auf der Karte nicht auffindbar';

  @override
  String get discoverabilityTitle => 'Globus-Sichtbarkeit';

  @override
  String get discoverabilityInfo =>
      'Deine Verbindungen sehen dich immer auf der Karte, unabhängig von dieser Einstellung.';

  @override
  String get discoverabilityChangedExact => 'Standort auf genau gesetzt';

  @override
  String get discoverabilityChangedApproximate =>
      'Standort auf ungefähr gesetzt';

  @override
  String get discoverabilityChangedCountry =>
      'Standort auf Landesebene gesetzt';

  @override
  String get discoverabilityChangedHidden =>
      'Du bist jetzt auf der Karte verborgen';

  @override
  String get onboardingExitTitle => 'Registrierung beenden?';

  @override
  String get onboardingExitMessage =>
      'Du wirst abgemeldet. Du kannst dein Profil beim nächsten Login fertig einrichten.';

  @override
  String get onboardingExitConfirm => 'Abmelden';

  @override
  String get onboardingExitCancel => 'Abbrechen';

  @override
  String get loginEmailOrNickname => 'E-Mail / Spitzname';

  @override
  String get paymentVerifying => 'Zahlung wird überprüft...';

  @override
  String get paymentSuccess => 'Zahlung erfolgreich!';

  @override
  String get paymentSuccessMessage =>
      'Dein Kauf wurde deinem Konto gutgeschrieben.';

  @override
  String get paymentPending => 'Zahlung wird verarbeitet';

  @override
  String get paymentPendingMessage =>
      'Deine Zahlung wird verarbeitet. Es kann einige Minuten dauern, bis sie erscheint.';

  @override
  String get paymentCancelled => 'Zahlung abgebrochen';

  @override
  String get paymentCancelledMessage =>
      'Deine Zahlung wurde abgebrochen. Es wurden keine Kosten berechnet.';

  @override
  String get continueToApp => 'Weiter';

  @override
  String get webCheckoutOpening => 'Sicherer Bezahlvorgang wird geöffnet …';

  @override
  String get webCheckoutWaiting =>
      'Schließe deine Zahlung im neuen Tab ab. Dieses Fenster wird automatisch aktualisiert, sobald sie abgeschlossen ist.';

  @override
  String get webCheckoutTimeout =>
      'Wir konnten deine Zahlung noch nicht bestätigen. Falls du sie abgeschlossen hast, wird dein Guthaben in Kürze aktualisiert.';

  @override
  String get webCheckoutFailed =>
      'Bezahlvorgang konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get groupNewGroup => 'Neue Gruppe';

  @override
  String get groupCreate => 'Erstellen';

  @override
  String get groupNameLabel => 'Gruppenname';

  @override
  String groupSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get groupInviteByNickname => 'Per Spitzname einladen';

  @override
  String get groupAddMembers => 'Mitglieder hinzufügen';

  @override
  String get groupTtsReadTranslated => 'Übersetzung vorlesen';

  @override
  String get groupTtsReadTranslatedHint =>
      'Doppeltippe eine Nachricht, um sie zu hören. An = deine Sprache, Aus = Original.';

  @override
  String get ttsNotEnoughCoins => 'Nicht genug Münzen für TTS (5 Münzen nötig)';

  @override
  String get groupRemoveMember => 'Mitglied entfernen';

  @override
  String groupRemoveMemberConfirm(String name) {
    return '$name aus dieser Gruppe entfernen?';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name entfernt';
  }

  @override
  String groupAddSelected(int count) {
    return '$count ausgewählte hinzufügen';
  }

  @override
  String get groupNicknameHint => 'Spitznamen eingeben';

  @override
  String get groupNoContacts => 'Noch keine Kontakte zum Hinzufügen';

  @override
  String get groupNoOneFound => 'Niemand mit diesem Spitznamen gefunden';

  @override
  String get groupAlreadyAdded => 'Bereits hinzugefügt';

  @override
  String groupAddedCount(int count) {
    return '$count hinzugefügt';
  }

  @override
  String get groupSearchFailed => 'Suche fehlgeschlagen';

  @override
  String get groupInfo => 'Gruppeninfo';

  @override
  String groupMembersCount(int count) {
    return '$count Mitglieder';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupYou => 'Du';

  @override
  String get groupLeave => 'Gruppe verlassen';

  @override
  String get groupDelete => 'Gruppe loeschen';

  @override
  String get groupDeleteConfirmTitle => 'Gruppe loeschen?';

  @override
  String get groupDeleteConfirmBody =>
      'Dies loescht die Gruppe und alle Nachrichten dauerhaft fuer alle. Dies kann nicht rueckgaengig gemacht werden.';

  @override
  String get groupLeaveConfirmTitle => 'Gruppe verlassen?';

  @override
  String get groupLeaveConfirmBody =>
      'Du erhältst keine Nachrichten mehr aus dieser Gruppe.';

  @override
  String get groupCancel => 'Abbrechen';

  @override
  String get groupLeaveAction => 'Verlassen';

  @override
  String get groupReport => 'Gruppe melden';

  @override
  String get groupReportConfirmBody =>
      'Diese Gruppe unserem Sicherheitsteam melden?';

  @override
  String get groupReportAction => 'Melden';

  @override
  String get groupReportSubmitted => 'Meldung gesendet';

  @override
  String get groupMessageHint => 'Nachricht…';

  @override
  String get groupSayHello => 'Begrüße die Gruppe 👋';

  @override
  String get groupLoadError => 'Diese Gruppe konnte nicht geladen werden';

  @override
  String get chatLocation => 'Standort';

  @override
  String get chatShareLocation => 'Standort teilen';

  @override
  String get chatLocationDenied =>
      'Zum Teilen deines Standorts ist die Standortberechtigung erforderlich';

  @override
  String get chatOpenInMaps => 'In Karten öffnen';

  @override
  String get eventsSearchHint => 'Nach Land, Stadt oder Name suchen';

  @override
  String get eventsSortPopular => 'Beliebt';

  @override
  String get eventsViewList => 'Listenansicht';

  @override
  String get eventsViewGrid => 'Rasteransicht';

  @override
  String get eventViewEvent => 'Veranstaltung ansehen';

  @override
  String get eventLoadError =>
      'Diese Veranstaltung konnte nicht geladen werden';

  @override
  String get eventShare => 'Veranstaltung teilen';

  @override
  String get eventReport => 'Event melden';

  @override
  String get eventReportTitle => 'Dieses Event melden?';

  @override
  String get eventReportBody =>
      'Unser Team prüft es. Du siehst dieses Event dann nicht mehr.';

  @override
  String get eventReported => 'Event gemeldet';

  @override
  String get shareAsLink => 'Als Link teilen';

  @override
  String get eventShared => 'Veranstaltung geteilt';

  @override
  String get eventShareEmpty => 'Noch keine Chats oder Gruppen zum Teilen';

  @override
  String get eventsUnlimitedAttendees => 'Unbegrenzte Teilnehmer';

  @override
  String get eventsPrivateEvent => 'Private Veranstaltung';

  @override
  String get eventsExternalLinks => 'Links';

  @override
  String get eventsLinkUrlHint => 'https://…';

  @override
  String get eventsAddLink => 'Link hinzufügen';

  @override
  String get tierLimitTitle => 'Upgrade für mehr';

  @override
  String tierLimitEventsBody(int max) {
    return 'Dein Tarif erlaubt $max Veranstaltungen. Upgrade für mehr.';
  }

  @override
  String tierLimitGroupsBody(int max) {
    return 'Dein Tarif erlaubt $max Gruppen. Upgrade für mehr.';
  }

  @override
  String get groupsTitle => 'Gruppen';

  @override
  String get profileRankingSubtitle => 'Globale Rangliste ansehen';

  @override
  String get eventBroadcastTooltip => 'An alle senden';

  @override
  String get eventBroadcastHint => 'Ankündigung an alle Teilnehmer…';

  @override
  String get eventBroadcastLabel => 'Ankündigung';

  @override
  String get eventsFeatured => 'Empfohlen';

  @override
  String get eventsInsufficientCoins => 'Nicht genügend Münzen';

  @override
  String get eventsConfirmAction => 'Bestätigen';

  @override
  String get eventsBoost => 'Boosten';

  @override
  String get eventsBoosted => 'Event hervorgehoben!';

  @override
  String eventsJoinForCoins(int cost) {
    return 'An diesem Event für $cost Münzen teilnehmen?';
  }

  @override
  String eventsBoostConfirm(int cost) {
    return 'Dieses Event für $cost Münzen 7 Tage lang hervorheben?';
  }

  @override
  String groupMemberLimit(int count) {
    return 'Bis zu $count Mitglieder pro Gruppe';
  }

  @override
  String get eventsPriceHint => 'Preis (1–1000)';

  @override
  String get eventsPriceRange => 'Gib einen Preis zwischen 1 und 1000 ein';

  @override
  String get eventsLinkLabelHint => 'Bezeichnung (optional)';

  @override
  String get eventsPickLocation => 'Ort wählen';

  @override
  String get eventsSearchAddress => 'Adresse suchen';

  @override
  String get eventsUseThisLocation => 'Diesen Ort verwenden';

  @override
  String get eventsEditEvent => 'Veranstaltung bearbeiten';

  @override
  String get groupEditName => 'Gruppenname bearbeiten';

  @override
  String get groupChangePhoto => 'Gruppenfoto ändern';

  @override
  String get groupUploadingPhoto => 'Foto wird hochgeladen…';

  @override
  String get groupPhotoUpdated => 'Gruppenfoto aktualisiert';

  @override
  String get groupPhotoUpdateFailed =>
      'Gruppenfoto konnte nicht aktualisiert werden';

  @override
  String get eventTextProhibited =>
      'Titel oder Beschreibung enthält unzulässige Sprache und kann nicht verwendet werden';

  @override
  String get groupSearchHint => 'Gruppen suchen';

  @override
  String get groupNoSearchResults => 'Keine Gruppen gefunden';

  @override
  String get groupMyTags => 'Meine Tags';

  @override
  String get groupMyTagsSubtitle => 'Privat – nur du siehst sie';

  @override
  String get groupNoTagsYet => 'Noch keine Tags';

  @override
  String get groupTagsEditTitle => 'Meine Tags bearbeiten';

  @override
  String get groupAddTagHint => 'Tag hinzufügen';

  @override
  String get groupTagsSave => 'Speichern';

  @override
  String get groupTagsSaved => 'Tags gespeichert';

  @override
  String get groupTagsSaveFailed => 'Tags konnten nicht gespeichert werden';

  @override
  String get groupTagsLimitReached => 'Tag-Limit erreicht';

  @override
  String peopleTagsEditTitle(String name) {
    return 'Tags für $name';
  }

  @override
  String get groupTranslationSettings => 'Übersetzung';

  @override
  String get groupTranslateMessages => 'Nachrichten übersetzen';

  @override
  String get groupShowOriginal => 'Originaltext anzeigen';

  @override
  String get eventsTabLiveEvents => 'Live-Events';

  @override
  String get globeLayerLiveEvents => 'Live-Events';

  @override
  String get eventsSortBy => 'Sortieren';

  @override
  String get eventsSortDistance => 'Entfernung';

  @override
  String get eventsSortStars => 'Bewertung';

  @override
  String get eventsSortReviews => 'Rezensionen';

  @override
  String get eventsSortDate => 'Datum';

  @override
  String get catMuseums => 'Museen';

  @override
  String get catSights => 'Sehenswürdigkeiten';

  @override
  String get catParks => 'Parks';

  @override
  String get catNationalParks => 'Nationalparks';

  @override
  String get catThemeParks => 'Freizeitparks';

  @override
  String get catTours => 'Touren & Sightseeing';

  @override
  String get catCulture => 'Kultur & Museen';

  @override
  String get catFoodDrink => 'Essen & Trinken';

  @override
  String get catCruises => 'Kreuzfahrten & Wasser';

  @override
  String get catNature => 'Natur & Outdoor';

  @override
  String get catDayTrips => 'Tagesausflüge';

  @override
  String get catTickets => 'Tickets & Pässe';

  @override
  String get catOther => 'Sonstiges';

  @override
  String get eventsUnlimited => 'Unbegrenzt';

  @override
  String get eventsTabGoing => 'Zugesagt';

  @override
  String get globeLayerCommunityEvents => 'Community-Events';

  @override
  String get webMapUnavailableTitle =>
      'Interaktive Karte in der mobilen App verfügbar';

  @override
  String get webMapUnavailableBody =>
      'Suche nach einer Adresse, um deinen Standort festzulegen.';

  @override
  String get webLocationPickerTitle => 'Wähle deinen Standort';

  @override
  String get webLocationSearchHint => 'Stadt oder Adresse suchen';

  @override
  String get webLocationConfirm => 'Diesen Standort verwenden';

  @override
  String get webLocationTapHint =>
      'Tippe auf die Karte, um einen Pin zu setzen';

  @override
  String webLocationMonthlyLimit(String date) {
    return 'Du kannst deinen Standort im Web einmal im Monat aktualisieren. Nächste Aktualisierung verfügbar am $date.';
  }

  @override
  String get eventMyTicket => 'Mein Ticket';

  @override
  String get eventTicketDelete => 'Ticket loeschen';

  @override
  String get eventTicketDeleteConfirm =>
      'Dieses Ticket dauerhaft loeschen? Das Event ist bereits vorbei.';

  @override
  String get eventScanCheckIn => 'Scannen / Check-in';

  @override
  String get eventScanUseMobileApp =>
      'Das Scannen des QR-Codes für den Check-in ist in der GreenGo-App verfügbar.';

  @override
  String get eventScanManageScanners => 'Scanner verwalten';

  @override
  String get eventScanInviteScannerHint =>
      'Lade ein Mitglied ein, Tickets am Eingang zu scannen.';

  @override
  String get eventScanNicknameHint => 'Spitzname';

  @override
  String get eventScanAddScanner => 'Hinzufügen';

  @override
  String get eventScanScannerNotFound =>
      'Kein Mitglied mit diesem Spitznamen gefunden';

  @override
  String get eventScanScannerAddFailed =>
      'Scanner konnte nicht hinzugefügt werden. Erneut versuchen.';

  @override
  String eventScanScannerAdded(String name) {
    return '$name kann jetzt Tickets scannen';
  }

  @override
  String get eventAttendance => 'Teilnahme';

  @override
  String get eventCheckedIn => 'Eingecheckt';

  @override
  String get eventNotCheckedIn => 'Noch nicht da';

  @override
  String get eventGuestsAllowedLabel => 'Erlaubte Gäste pro Teilnehmer';

  @override
  String get eventBringGuests => 'Gäste mitbringen';

  @override
  String get eventInvalidTicket => 'Ungültiges Ticket für dieses Event';

  @override
  String get eventScanInstructions =>
      'Richte die Kamera auf den QR-Code eines Teilnehmers';

  @override
  String get eventTotalHeadcount => 'Gesamtzahl der Personen';

  @override
  String get eventCameraPermission =>
      'Zum Scannen ist die Kameraberechtigung erforderlich';

  @override
  String get eventTicketSubtitle => 'Zeige diesen QR-Code am Eingang';

  @override
  String eventGuestCount(int count, int max) {
    return '$count von $max Gästen';
  }

  @override
  String eventCheckedInSuccess(String name) {
    return '$name eingecheckt';
  }

  @override
  String eventAlreadyCheckedIn(String name) {
    return '$name bereits eingecheckt';
  }

  @override
  String eventGuestsBringing(int count) {
    return '+$count Gäste';
  }

  @override
  String connectDailyLimitReached(int limit) {
    return 'Du hast dein Tageslimit von $limit neuen Verbindungen erreicht. Führe ein Upgrade durch, um mit mehr Menschen in Kontakt zu treten!';
  }

  @override
  String get boostFeatureName => 'Profil-Boost';

  @override
  String get boostRequiresTierDescription =>
      'Profil-Boosts sind ein Vorteil der kostenpflichtigen Mitgliedschaft. Führe ein Upgrade durch, um dein Profil zu boosten und von mehr Menschen gesehen zu werden.';

  @override
  String boostMonthlyLimitReached(int limit) {
    return 'Du hast diesen Monat alle $limit in deinem Plan enthaltenen Profil-Boosts genutzt. Upgrade für mehr.';
  }

  @override
  String get travelModeFeatureName => 'Reisemodus';

  @override
  String get travelModeRequiresTierDescription =>
      'Mit dem Reisemodus erscheinst du im Discovery-Feed einer anderen Stadt. Führe ein Upgrade durch, um ihn freizuschalten.';

  @override
  String get exploreRecommended => 'Für dich empfohlen';

  @override
  String get businessAccountTitle => 'Unternehmenskonto';

  @override
  String get becomeBusiness => 'Unternehmen werden';

  @override
  String get businessProfileLabel => 'Unternehmensprofil';

  @override
  String get businessCategoryLabel => 'Unternehmenskategorie';

  @override
  String get businessCategoryHint => 'Kategorie auswählen';

  @override
  String get businessVerifiedLabel => 'Verifiziertes Unternehmen';

  @override
  String get featureThisEvent => 'Dieses Event hervorheben';

  @override
  String featureEventCostLabel(int cost) {
    return 'Dieses Event hervorheben · $cost Coins';
  }

  @override
  String featureEventActive(String date) {
    return 'Hervorgehoben bis $date';
  }

  @override
  String featureEventConfirm(int cost) {
    return 'Dieses Event für $cost Coins hervorheben?';
  }

  @override
  String get referralTitle => 'Freunde einladen';

  @override
  String get referralInviteFriends => 'Freunde einladen';

  @override
  String get referralYourCode => 'Dein Empfehlungscode';

  @override
  String get referralShareCta => 'Teilen';

  @override
  String get referralShareMessage => 'Mach mit bei GreenGo!';

  @override
  String get referralRewardEarned => 'Verdiente Coins';

  @override
  String get referralCountLabel => 'Eingeladene Freunde';

  @override
  String referralHowItWorks(int coins, int monthlyCap) {
    final intl.NumberFormat coinsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String coinsString = coinsNumberFormat.format(coins);
    final intl.NumberFormat monthlyCapNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthlyCapString = monthlyCapNumberFormat.format(monthlyCap);

    return 'Teile deinen Code — wenn ein Freund damit beitritt, erhältst du $coinsString Coins (bis zu $monthlyCapString pro Monat) und er bekommt 1 Monat Platinum.';
  }

  @override
  String get referralHowItWorksTitle => 'So funktioniert\'s';

  @override
  String get achievementsLoadError => 'Erfolge konnten nicht geladen werden';

  @override
  String get loadErrorCheckConnection =>
      'Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get streakTitle => 'Serie';

  @override
  String get streakDaysLabel => 'Tage-Serie';

  @override
  String get streakKeepGoing => 'Bleib dran!';

  @override
  String get missionsTitle => 'Missionen';

  @override
  String get missionsSubtitle => 'Schließe Missionen ab, um Coins zu verdienen';

  @override
  String get missionProgressLabel => 'Fortschritt';

  @override
  String get missionRewardLabel => 'Belohnung';

  @override
  String get missionCompleteLabel => 'Abgeschlossen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei GreenGo';

  @override
  String get onboardingWelcomeBody =>
      'Entdecke Kulturen, übe Sprachen, finde lokale Events und triff Menschen in deiner Nähe — ohne Sprachbarrieren.';

  @override
  String get onboardingPickInterests => 'Was interessiert dich?';

  @override
  String get onboardingPickLanguages => 'Sprachen, die du sprichst';

  @override
  String get savedSearchesTitle => 'Gespeicherte Suchen';

  @override
  String get saveThisSearch => 'Diese Suche speichern';

  @override
  String get savedSearchSaved => 'Suche gespeichert';

  @override
  String get savedSearchRun => 'Ausführen';

  @override
  String get savedSearchEmpty => 'Noch keine gespeicherten Suchen';

  @override
  String get savedSearchAlertsToggle => 'Benachrichtigungen';

  @override
  String get exploreFeaturedCommunity => 'Empfohlene Community-Events';

  @override
  String get notificationMarkAllRead => 'Alle als gelesen markieren';

  @override
  String get notificationsDeleteUnread => 'Ungelesene loeschen';

  @override
  String get notificationsDeleteAll => 'Alle loeschen';

  @override
  String get notificationsDeleteAllConfirm =>
      'Alle Benachrichtigungen auf dieser Seite dauerhaft loeschen? Dies kann nicht rueckgaengig gemacht werden.';

  @override
  String get notificationsDeleteUnreadConfirm =>
      'Alle ungelesenen Benachrichtigungen dauerhaft loeschen? Dies kann nicht rueckgaengig gemacht werden.';

  @override
  String get analyticsTitle => 'Analysen';

  @override
  String get analyticsPlatinumOnly => 'Analysen sind eine Platinum-Funktion.';

  @override
  String get analyticsEventsHosted => 'Veranstaltete Events';

  @override
  String get analyticsTotalAttendees => 'Teilnehmer insgesamt';

  @override
  String get analyticsReach => 'Reichweite';

  @override
  String get analyticsUpgradeCta => 'Auf Platinum upgraden';

  @override
  String get safetyVerifiedBadge => 'Verifiziert';

  @override
  String get safetyReportUser => 'Melden';

  @override
  String get safetyBlockUser => 'Blockieren';

  @override
  String get safetyCheckInTitle => 'Sicherheits-Check-in';

  @override
  String get safetyCheckInArrived => 'Ich bin sicher angekommen';

  @override
  String get safetyCheckInDone => 'Du hast dich sicher eingecheckt';

  @override
  String get guidelinesTitle => 'Community-Richtlinien';

  @override
  String get guidelinesAccept => 'Ich stimme zu';

  @override
  String get guidelinesBody =>
      'GreenGo ist eine interkulturelle Community für Entdeckungen, Sprachaustausch, lokale Events und Freundschaften. Sei respektvoll und offen gegenüber Menschen aus allen Kulturen. Dies ist keine Dating-App. Keine Belästigung, Hassrede, Spam oder explizite Inhalte. Melde alles, was hier nicht hingehört.';

  @override
  String get businessSectionTitle => 'Unternehmen';

  @override
  String get businessSectionSubtitle => 'Tools für dein Unternehmen';

  @override
  String get businessHubAccount => 'Unternehmenskonto';

  @override
  String get businessHubAnalytics => 'Analysen';

  @override
  String get businessHubFeatured => 'Hervorgehobene Platzierungen';

  @override
  String get becomeBusinessAction => 'Eines werden';

  @override
  String get becomeBusinessConfirmTitle => 'Unternehmenskonto werden?';

  @override
  String get becomeBusinessConfirmMessage =>
      'Das ist dauerhaft: Dein Konto wird zu einem öffentlichen Unternehmenskonto und kann nicht wieder in ein persönliches Konto umgewandelt werden. Die Business-Tools funktionieren, solange deine Platinum-Mitgliedschaft aktiv ist; läuft sie ab, werden sie pausiert, bis du verlängerst.';

  @override
  String get becomeBusinessConfirmAction => 'Dauerhaft machen';

  @override
  String get becomeBusinessSuccess =>
      'Dein Konto ist jetzt ein Unternehmenskonto.';

  @override
  String get becomeBusinessError =>
      'Dein Konto konnte nicht umgestellt werden. Bitte versuche es erneut.';

  @override
  String get businessAccountActive => 'Unternehmenskonto aktiv (dauerhaft)';

  @override
  String get businessRequiresPlatinum =>
      'Unternehmenskonten sind eine Platinum-Funktion. Führe ein Upgrade durch, um deinen Storefront, Follower und Lead-Erfassung freizuschalten.';

  @override
  String get viewStorefront => 'Storefront ansehen';

  @override
  String get requestVerification => 'Verifizierung anfordern';

  @override
  String get requestVerificationPending => 'Verifizierung ausstehend';

  @override
  String get requestVerificationTitle => 'Verifizierung anfordern';

  @override
  String get verifyBusinessNameLabel => 'Firmenname';

  @override
  String get verifyLegalNameLabel => 'Rechtlicher Name';

  @override
  String get verifyLegalNameHint => 'Eingetragener Name des Unternehmens';

  @override
  String get verifyPhoneLabel => 'Telefonnummer';

  @override
  String get verifyPhoneHint => '+49 151 1234567';

  @override
  String get verifyPhoneFormatError =>
      'Nummer im internationalen Format eingeben, z. B. +491701234567';

  @override
  String get verifySendCode => 'Code senden';

  @override
  String get verifyResendCode => 'Erneut senden';

  @override
  String get verifyEnterCodeLabel => '6-stelliger Code';

  @override
  String get verifyConfirmCode => 'Bestätigen';

  @override
  String get verifyPhoneVerified => 'Telefon bestätigt';

  @override
  String get verifyOwnerDocumentLabel => 'Ausweis des Inhabers';

  @override
  String get verifyUploadDocument => 'Dokument hochladen';

  @override
  String get verifyDocumentUploaded => 'Dokument hochgeladen';

  @override
  String get verifyDocumentUploadError =>
      'Dokument konnte nicht hochgeladen werden. Bitte erneut versuchen.';

  @override
  String get verifyWebsiteLabel => 'Website (optional)';

  @override
  String get verifyWebsiteHint => 'https://beispiel.de';

  @override
  String get verifyNotesLabel => 'Notizen (optional)';

  @override
  String get verifyMissingFields =>
      'Bitte alle Pflichtfelder ausfüllen und Telefon bestätigen.';

  @override
  String get requestVerificationMessage =>
      'Erzähle uns ein wenig über dein Unternehmen, damit wir es verifizieren können. Unser Team prüft deine Anfrage.';

  @override
  String get requestVerificationNoteHint =>
      'Füge eine Notiz hinzu (Website, Adresse, alles, was uns bei der Verifizierung hilft)';

  @override
  String get requestVerificationSubmitted =>
      'Verifizierungsanfrage eingereicht.';

  @override
  String get requestVerificationError =>
      'Deine Anfrage konnte nicht eingereicht werden. Bitte versuche es erneut.';

  @override
  String get submit => 'Absenden';

  @override
  String get businessVerifiedBadgeTooltip => 'Verifiziertes Unternehmen';

  @override
  String get businessLinks => 'Links';

  @override
  String get businessOpeningHours => 'Öffnungszeiten';

  @override
  String get businessHoursNotProvided => 'Keine Öffnungszeiten angegeben';

  @override
  String get businessGallery => 'Galerie';

  @override
  String get businessUpcomingEvents => 'Kommende Events';

  @override
  String get businessNoUpcomingEvents => 'Noch keine kommenden Events.';

  @override
  String get businessCommunities => 'Communities';

  @override
  String get businessNoCommunities => 'Noch keine Communities.';

  @override
  String get businessContact => 'Kontakt';

  @override
  String get businessFollow => 'Folgen';

  @override
  String get businessFollowing => 'Gefolgt';

  @override
  String get businessFollowError =>
      'Folgen konnte nicht aktualisiert werden. Bitte versuche es erneut.';

  @override
  String businessFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Follower',
      one: '1 Follower',
      zero: 'Keine Follower',
    );
    return '$_temp0';
  }

  @override
  String businessMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
      zero: 'Keine Mitglieder',
    );
    return '$_temp0';
  }

  @override
  String get adminBusinessVerifications => 'Unternehmensverifizierungen';

  @override
  String get adminBusinessVerificationsSubtitle =>
      'Verifizierte Unternehmensabzeichen überprüfen und genehmigen';

  @override
  String get adminApproveBusinessVerification => 'Genehmigen';

  @override
  String get adminRejectBusinessVerification =>
      'Unternehmensverifizierung ablehnen';

  @override
  String get adminBusinessRejectReasonHint =>
      'Grund für die Ablehnung (optional)';

  @override
  String get adminBusinessApproved => 'Unternehmen verifiziert';

  @override
  String get adminBusinessRejected => 'Unternehmensverifizierung abgelehnt';

  @override
  String get adminNoPendingBusinessVerifications =>
      'Keine ausstehenden Unternehmensverifizierungen';

  @override
  String get adminAccessDenied => 'Zugriff verweigert. Nur für Admins.';

  @override
  String get adminBusinessVerifiedNotificationTitle =>
      'Dein Unternehmen ist verifiziert';

  @override
  String get adminBusinessVerifiedNotificationBody =>
      'Dein Unternehmen zeigt jetzt das goldene Verifizierungsabzeichen.';

  @override
  String adminSubmittedLabel(String date) {
    return 'Eingereicht $date';
  }

  @override
  String get communitiesSponsored => 'Gesponsert';

  @override
  String get communitiesSponsorThisCommunity => 'Diese Community sponsern';

  @override
  String get communitiesSponsorSubtitle =>
      'Hefte eine Promo für Mitglieder oben an';

  @override
  String get communitiesSponsorFeatureName => 'Community-Sponsoring';

  @override
  String get communitiesSponsorRequiresPlatinum =>
      'Eine Community zu sponsern und eine Promo anzuheften ist eine Platinum-Unternehmensfunktion.';

  @override
  String get communitiesEditSponsorship => 'Sponsoring & Promo bearbeiten';

  @override
  String get communitiesMarkAsSponsored => 'Als gesponsert markieren';

  @override
  String get communitiesPromoTitleLabel => 'Promo-Titel';

  @override
  String get communitiesPromoTitleHint => 'z. B. 20 % Rabatt dieses Wochenende';

  @override
  String get communitiesPromoBodyLabel => 'Promo-Nachricht';

  @override
  String get communitiesPromoBodyHint =>
      'Informiere Mitglieder über dein Angebot';

  @override
  String get communitiesPromoImageLabel => 'Bild-URL (optional)';

  @override
  String get communitiesPromoLinkEventLabel => 'Verknüpfte Event-ID (optional)';

  @override
  String get communitiesPromoLinkUrlLabel => 'Link-URL (optional)';

  @override
  String get communitiesPromoTitleRequired => 'Bitte gib einen Promo-Titel ein';

  @override
  String get communitiesSaveSponsorship => 'Speichern';

  @override
  String get communitiesRemovePromo => 'Promo entfernen';

  @override
  String get exploreSearchTooltip => 'Suchen';

  @override
  String get exploreQrTooltip => 'Meine QR-Codes';

  @override
  String get universalSearchTitle => 'Suchen';

  @override
  String get universalSearchHint => 'Menschen und Events suchen';

  @override
  String get universalSearchTabPeople => 'Menschen';

  @override
  String get universalSearchTabEvents => 'Events';

  @override
  String get universalSearchEmptyPrompt =>
      'Finde Menschen zum Chatten und Events zum Teilnehmen';

  @override
  String get universalSearchNoPeople => 'Keine Menschen gefunden';

  @override
  String get universalSearchNoEvents => 'Keine Events gefunden';

  @override
  String get qrHubTitle => 'QR-Codes';

  @override
  String get qrHubTabMyTickets => 'Meine Tickets';

  @override
  String get qrHubTabScan => 'Scannen';

  @override
  String get qrHubNoTickets =>
      'Noch keine kommenden Tickets. Nimm an einem Event teil, um deinen QR-Code zu erhalten.';

  @override
  String get qrHubTicketHint =>
      'Tippe auf ein Ticket, um seinen vollständigen QR-Code zu öffnen';

  @override
  String get qrHubScanInstructions =>
      'Richte deine Kamera auf einen GreenGo-QR-Code';

  @override
  String get qrHubInvalidCode => 'Das ist kein gültiger GreenGo-Code';

  @override
  String get qrScanApproved => 'Genehmigt — eingecheckt';

  @override
  String get qrScanNotAuthorized =>
      'Nur der Veranstalter oder ein eingeladener Scanner kann Tickets einlösen';

  @override
  String get qrHubJoinedEvent => 'Du bist dabei! Event wird geöffnet…';

  @override
  String get eventsRepeats => 'Wiederholungen';

  @override
  String get eventsRepeatNone => 'Keine Wiederholung';

  @override
  String get eventsRepeatDaily => 'Täglich';

  @override
  String get eventsRepeatWeekly => 'Wöchentlich';

  @override
  String get eventsRepeatMonthly => 'Monatlich';

  @override
  String get eventsRepeatInterval => 'Alle';

  @override
  String get eventsRepeatCount => 'Wiederholungen';

  @override
  String get eventsRecurringLabel => 'Wiederkehrend';

  @override
  String get eventsCancelSeries => 'Gesamte Serie absagen';

  @override
  String get eventsCancelSeriesConfirm =>
      'Alle zukünftigen Termine dieses wiederkehrenden Events absagen?';

  @override
  String get eventsSeriesCancelled => 'Serie abgesagt';

  @override
  String get eventsSeriesCancelError =>
      'Die Serie konnte nicht abgesagt werden';

  @override
  String get eventsSaveAsDraft => 'Als Entwurf speichern';

  @override
  String get eventsSchedule => 'Planen';

  @override
  String get eventsStatusDraft => 'Entwurf';

  @override
  String get eventsStatusScheduled => 'Geplant';

  @override
  String get eventsStatusCancelled => 'Abgesagt';

  @override
  String eventsScheduledForDate(String date) {
    return 'Geplant für $date';
  }

  @override
  String eventsRepeatCap(int max) {
    return 'Bis zu $max Wiederholungen';
  }

  @override
  String get eventsTicketTiers => 'Ticket-Stufen';

  @override
  String get eventsRepeatHelper =>
      '\'Alle\' legt den Abstand zwischen den Terminen fest (z. B. alle 2 Wochen); \'Termine\' ist die Gesamtzahl der erstellten Termine.';

  @override
  String get eventsTicketTiersHelper =>
      'Optionale Preisstufen (z. B. Standard, VIP), die Ticketpreis und Kapazitaet festlegen. Sie steuern nicht den Coin-Zugang zum Event.';

  @override
  String get eventsAddTier => 'Stufe hinzufügen';

  @override
  String get eventsTierName => 'Stufenname';

  @override
  String get eventsTierPriceCoins => 'Preis (Coins, 0 = gratis)';

  @override
  String get eventsTierCapacity => 'Kapazität (0 = unbegrenzt)';

  @override
  String get eventsFreeTier => 'Gratis';

  @override
  String get eventsSelectTier => 'Ticket auswählen';

  @override
  String get eventsJoinWaitlist => 'Warteliste beitreten';

  @override
  String get eventsOnWaitlist => 'Auf der Warteliste';

  @override
  String eventsWaitlistPosition(int position) {
    return 'Du bist #$position auf der Warteliste';
  }

  @override
  String eventsTierPriceValue(int coins) {
    return '$coins Coins';
  }

  @override
  String eventsTierCapacityValue(int capacity) {
    return '$capacity Plätze';
  }

  @override
  String get eventsRsvpError => 'Deine Zusage konnte nicht aktualisiert werden';

  @override
  String get shareProfileTooltip => 'Profil teilen';

  @override
  String shareProfileMessage(String link) {
    return 'Chatte mit mir auf GreenGo: $link';
  }

  @override
  String shareEventMessage(String link) {
    return 'Sieh dir dieses Event auf GreenGo an: $link';
  }

  @override
  String get guidelinesSubtitle =>
      'Eine kurze Einführung, wie wir hier in Kontakt treten';

  @override
  String get guidelinesWelcomeTitle => 'Willkommen über Kulturen hinweg';

  @override
  String get guidelinesWelcomeDesc =>
      'Triff Menschen aus aller Welt und teile deine Welt mit Offenheit.';

  @override
  String get guidelinesRespectTitle => 'Respektiere alle';

  @override
  String get guidelinesRespectDesc =>
      'Freundlichkeit und Neugier zuerst – behandle andere so, wie du behandelt werden möchtest.';

  @override
  String get guidelinesAuthenticTitle => 'Bleib authentisch';

  @override
  String get guidelinesAuthenticDesc =>
      'GreenGo ist für echte kulturelle Verbindungen – es ist keine Dating-App.';

  @override
  String get guidelinesSafetyTitle => 'Keine Belästigung oder Hass';

  @override
  String get guidelinesSafetyDesc =>
      'Belästigung, Hassrede und Drohungen haben hier keinen Platz.';

  @override
  String get guidelinesNoSpamTitle => 'Kein Spam und keine expliziten Inhalte';

  @override
  String get guidelinesNoSpamDesc =>
      'Halte es sauber – kein Spam, keine Betrügereien, keine sexuellen Inhalte.';

  @override
  String get guidelinesReportTitle => 'Melde alles Unangemessene';

  @override
  String get guidelinesReportDesc =>
      'Etwas stimmt nicht? Melde es und unser Team sieht es sich an.';

  @override
  String get businessNewBadge => 'NEU';

  @override
  String get businessLeadsTitle => 'Leads';

  @override
  String get businessLeadsEmpty =>
      'Noch keine Leads. Personen, die dich kontaktieren oder deine Events speichern, erscheinen hier.';

  @override
  String get businessLeadContact => 'Hat dich kontaktiert';

  @override
  String get businessLeadSavedEvent => 'Hat dein Event gespeichert';

  @override
  String get eventTicketWhen => 'Wann';

  @override
  String get eventTicketVenue => 'Veranstaltungsort';

  @override
  String get eventTicketWhere => 'Wo';

  @override
  String get eventTicketGuestsLabel => 'Gäste';

  @override
  String eventTicketAdmits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zutritt für $count Personen',
      one: 'Zutritt für 1 Person',
    );
    return '$_temp0';
  }

  @override
  String get shareEvent => 'Event teilen';

  @override
  String get promoteTitle => 'Bewerben';

  @override
  String get promoteSubtitle => 'Steigere deine Sichtbarkeit mit GreenGoCoins';

  @override
  String get promoteBusinessOption => 'Unternehmen bewerben';

  @override
  String get promoteBusinessDesc =>
      'Präsentiere dein Schaufenster ganz oben in Entdecken';

  @override
  String get promoteEventsOption => 'Ein Event bewerben';

  @override
  String get promoteEventsDesc =>
      'Präsentiere eines deiner Events in der Entdeckung';

  @override
  String get promoteChooseDuration => 'Dauer wählen';

  @override
  String get promoteNotActive => 'Derzeit nicht beworben';

  @override
  String get promoteConfirmTitle => 'Bewerbung bestätigen';

  @override
  String get promoteConfirmCta => 'Bewerben';

  @override
  String get promoteCancel => 'Abbrechen';

  @override
  String get promoteSelectEvent => 'Wähle ein Event zum Hervorheben';

  @override
  String get promoteNoEvents =>
      'Du hast keine bevorstehenden Events zum Hervorheben';

  @override
  String get promoteEventAlreadyFeatured => 'Bereits hervorgehoben';

  @override
  String get promoteSuccess => 'Bewerbung aktiv!';

  @override
  String get promoteError =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get promoteInsufficientCoins => 'Nicht genügend Coins';

  @override
  String get promoteInsufficientCoinsBody =>
      'Du hast nicht genügend Coins für diese Bewerbung. Lade auf, um fortzufahren.';

  @override
  String get promoteGetCoins => 'Coins holen';

  @override
  String promoteDurationDays(int days) {
    return '$days Tage';
  }

  @override
  String promoteCostLabel(int cost) {
    return '$cost Coins';
  }

  @override
  String promoteActiveUntil(String date) {
    return 'Beworben bis $date';
  }

  @override
  String promoteBusinessConfirm(int days, int cost) {
    return 'Dein Unternehmen für $days Tage für $cost Coins bewerben?';
  }

  @override
  String promoteEventConfirm(int days, int cost) {
    return 'Dieses Event für $days Tage für $cost Coins hervorheben?';
  }

  @override
  String get audienceSectionTitle => 'Zielgruppen-Insights';

  @override
  String get audiencePrivacyNote =>
      'Aggregiert und anonymisiert – kleine Gruppen werden zum Schutz der Privatsphäre ausgeblendet.';

  @override
  String get audienceNotEnoughData =>
      'Noch nicht genügend Daten, um dies unter Wahrung der Privatsphäre anzuzeigen.';

  @override
  String get audienceAgeTitle => 'Altersverteilung';

  @override
  String get audienceCountriesTitle => 'Top-Länder';

  @override
  String get audienceInterestsTitle => 'Top-Interessen';

  @override
  String get eventAnalyticsTitle => 'Event-Analysen';

  @override
  String get eventAnalyticsGoing => 'Zusagen';

  @override
  String get eventAnalyticsWaitlist => 'Warteliste';

  @override
  String get eventAnalyticsCheckedIn => 'Eingecheckt';

  @override
  String get eventAnalyticsCheckInRate => 'Check-in-Rate';

  @override
  String get eventAnalyticsTierBreakdown => 'Ticketkategorien';

  @override
  String get businessEventsTitle => 'Meine Events verwalten';

  @override
  String get businessEventsSearchHint => 'Nach Name oder Datum suchen';

  @override
  String get businessEventsEmpty => 'Du hast noch keine Events erstellt.';

  @override
  String get businessEventsAnalytics => 'Analysen';

  @override
  String get businessEventsCancelTitle => 'Event absagen';

  @override
  String get businessEventsCancelMessage =>
      'Dieses Event absagen? Teilnehmer werden benachrichtigt und es wird entfernt.';

  @override
  String get businessEventsCancelSeriesMessage =>
      'Jeden Termin dieser wiederkehrenden Serie absagen?';

  @override
  String get businessEventsCancelConfirm => 'Event absagen';

  @override
  String get businessEventsCancelled => 'Event abgesagt';

  @override
  String get businessPausedTitle => 'Unternehmen pausiert';

  @override
  String get businessPausedSubtitle =>
      'Deine Unternehmensfunktionen sind pausiert, weil deine Platinum-Mitgliedschaft abgelaufen ist. Erneuere Platinum, um dein Schaufenster, Analysen, Leads und Bewerbungen wiederherzustellen.';

  @override
  String get businessReactivate => 'Platinum erneuern';

  @override
  String get eventsBoostChooseDuration => 'Boost-Dauer wählen';

  @override
  String eventsBoostHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wochen',
      one: '1 Woche',
    );
    return '$_temp0';
  }

  @override
  String eventBoostEndsIn(String time) {
    return 'Boost endet in $time';
  }

  @override
  String get eventBoostEnded => 'Boost beendet';

  @override
  String get eventsBuyCoins => 'Coins kaufen';

  @override
  String get eventsBuyCoinsPrompt =>
      'Du hast nicht genügend Coins. Möchtest du mehr kaufen?';

  @override
  String get messageTooLong =>
      'Nachrichten dürfen bis zu 4096 Zeichen lang sein.';

  @override
  String get exploreBusinessesNearYou => 'Unternehmen in deiner Naehe';

  @override
  String get splashBusinessLabel => 'BUSINESS';

  @override
  String get rateThisBusiness => 'Dieses Unternehmen bewerten';

  @override
  String get businessRatingError =>
      'Deine Bewertung konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String businessRatingCount(int count) {
    return '($count)';
  }

  @override
  String rateStarsSemantic(int stars) {
    return 'Mit $stars Sternen bewerten';
  }

  @override
  String businessRatingSemantic(String avg, int count) {
    return 'Bewertet mit $avg von 5, $count Bewertungen';
  }

  @override
  String get editStorefront => 'Schaufenster bearbeiten';

  @override
  String get editStorefrontSubtitle =>
      'Verwalte deine Galerie, Öffnungszeiten, Links und Infos';

  @override
  String get storefrontGallerySubtitle =>
      'Zeige dein Lokal, deine Produkte oder dein Team';

  @override
  String get storefrontOpeningHoursSubtitle =>
      'Lege deine Öffnungstage und -zeiten fest';

  @override
  String get storefrontDescriptionHint =>
      'Erzähle den Leuten von deinem Unternehmen';

  @override
  String get storefrontCategoryHint => 'z. B. Restaurant, Café, Museum';

  @override
  String get storefrontLinkHint => 'https://...';

  @override
  String get storefrontAddLink => 'Link hinzufügen';

  @override
  String get storefrontAddImage => 'Bild hinzufügen';

  @override
  String get storefrontSaved => 'Schaufenster aktualisiert';

  @override
  String get analyticsEventViews => 'Event-Aufrufe';

  @override
  String get analyticsCommunityReach => 'Community-Reichweite';

  @override
  String get analyticsChatsInvolved => 'Beteiligte Chats';

  @override
  String get eventAnalyticsViews => 'Aufrufe';

  @override
  String get businessHubScanner => 'Schnell-Scanner';

  @override
  String get businessHubScannerSubtitle =>
      'Tickets scannen, um Gäste einzuchecken';

  @override
  String get businessHubFollowers => 'Follower';

  @override
  String get businessHubFollowersSubtitle =>
      'Sieh, wer deinem Unternehmen folgt';

  @override
  String get businessFollowersTitle => 'Follower';

  @override
  String get businessNoFollowers =>
      'Noch keine Follower. Teile dein Schaufenster, um dein Publikum zu vergrößern.';

  @override
  String get membershipRequiredTitle => 'Mitgliedschaft erforderlich';

  @override
  String get membershipRequiredBody =>
      'Dafür brauchst du eine aktive Mitgliedschaft. Erneuere sie, um fortzufahren.';

  @override
  String get renewMembership => 'Mitgliedschaft erneuern';

  @override
  String get extraEventTitle => 'Zusätzliches Event';

  @override
  String extraEventBody(int cost) {
    return 'Du hast dein kostenloses Event-Limit erreicht. Ein zusätzliches Event für $cost Coins erstellen?';
  }

  @override
  String get accountBannedTitle => 'Konto dauerhaft gesperrt';

  @override
  String get accountBannedBody =>
      'Dieses Konto wurde wegen Verstoßes gegen unsere Inhaltsrichtlinien dauerhaft gesperrt. Diese Entscheidung ist endgültig.';

  @override
  String get adminBanPermanently => 'Dauerhaft sperren';

  @override
  String get adminBanConfirm => 'Dieses Konto dauerhaft sperren?';

  @override
  String get adminBanConfirmBody =>
      'Dies sperrt das Konto dauerhaft und blockiert jeglichen Zugriff. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get adminBanReasonHint => 'Grund (z. B. Nacktheit in der Galerie)';

  @override
  String get adminBanned => 'Konto dauerhaft gesperrt';

  @override
  String get storefrontFeaturedImage => 'Titelbild';

  @override
  String get storefrontFeaturedImageSubtitle =>
      'Das Hauptbanner oben in deinem Schaufenster.';

  @override
  String get storefrontAddFeaturedImage => 'Titelbild hinzufügen';

  @override
  String get storefrontProfileImage => 'Profilbild';

  @override
  String get storefrontProfileImageSubtitle =>
      'Dein Avatar, der neben deinem Firmennamen angezeigt wird.';

  @override
  String get storefrontAddProfileImage => 'Profilbild hinzufügen';

  @override
  String get storefrontReplaceProfileImage => 'Profilbild ersetzen';

  @override
  String get preferenceBusinessOnly => 'Nur Business-Konten';

  @override
  String get preferenceBusinessOnlyDesc =>
      'Nur Business-Konten in der Entdeckung anzeigen';

  @override
  String get businessProfileNameLabel => 'Name des Business-Profils';

  @override
  String get businessProfileNameHint => 'Wird in deinem Schaufenster angezeigt';

  @override
  String get businessLegalNameLabel => 'Rechtlicher Firmenname';

  @override
  String get businessLegalNameHint => 'Eingetragener Firmenname';

  @override
  String get verifyOwnerNameLabel => 'Vollständiger Name des Inhabers';

  @override
  String get verifyOwnerNameHint =>
      'Genau wie im hochgeladenen Ausweisdokument';

  @override
  String get scanResultApproved => 'Genehmigt';

  @override
  String get scanResultDenied => 'Abgelehnt';

  @override
  String get communitiesTabChat => 'Chat';

  @override
  String get communitiesTabTips => 'Tipps';

  @override
  String get communitiesTabAnnouncements => 'Ankündigungen';

  @override
  String get communitiesTabEvents => 'Events';

  @override
  String get communitiesJoinRequestSent =>
      'Anfrage gesendet – wartet auf Genehmigung';

  @override
  String get communitiesJoinRequestsTitle => 'Beitrittsanfragen';

  @override
  String get communitiesTipsEmpty =>
      'Noch keine Tipps. Teile einen Sprachtipp, eine kulturelle Info oder einen Stadttipp im Chat.';

  @override
  String get communitiesAnnouncementsEmpty => 'Noch keine Ankündigungen.';

  @override
  String get communitiesPostAnnouncement => 'Ankündigung posten';

  @override
  String get communitiesRequestToJoin => 'Beitritt anfragen';

  @override
  String get communitiesMutedNotice =>
      'Du wurdest in dieser Community stummgeschaltet';

  @override
  String get communitiesRulesResourcesTitle => 'Regeln & Ressourcen';

  @override
  String get communitiesRulesLabel => 'Community-Regeln';

  @override
  String get communitiesRulesHint => 'Richtlinien für Mitglieder…';

  @override
  String get communitiesResourcesLabel => 'Ressourcen-Links';

  @override
  String get communitiesResourceTitleHint => 'Titel';

  @override
  String get communitiesResourceUrlHint => 'https://…';

  @override
  String get communitiesAddResource => 'Link hinzufügen';

  @override
  String get communitiesSaveLabel => 'Speichern';

  @override
  String get communitiesAddRulesPrompt =>
      'Regeln & Ressourcen für diese Community hinzufügen';

  @override
  String get communitiesAnnouncementHint =>
      'Schreibe eine Ankündigung an alle Mitglieder…';

  @override
  String get communitiesPostLabel => 'Posten';

  @override
  String get communitiesPromoteMember => 'Zum Admin machen';

  @override
  String get communitiesGrantTips => 'Tipps posten erlauben';

  @override
  String get communitiesRevokeTips => 'Tipps-Posten entziehen';

  @override
  String get communitiesGrantAnnouncements => 'Ankuendigungen posten erlauben';

  @override
  String get communitiesRevokeAnnouncements =>
      'Ankuendigungen-Posten entziehen';

  @override
  String get communitiesDemoteMember => 'Zum Mitglied herabstufen';

  @override
  String get communitiesRemoveMember => 'Aus Community entfernen';

  @override
  String get communitiesMuteMember => 'Stummschalten';

  @override
  String get communitiesUnmuteMember => 'Stummschaltung aufheben';

  @override
  String get communitiesBanMember => 'Sperren';

  @override
  String get communitiesReportMember => 'Melden';

  @override
  String get communitiesNoJoinRequests => 'Keine ausstehenden Anfragen';

  @override
  String get communitiesApprove => 'Genehmigen';

  @override
  String get communitiesReject => 'Ablehnen';

  @override
  String get communitiesLinkToCommunity =>
      'Mit Community verknüpfen (optional)';

  @override
  String get communitiesLinkNone => 'Keine';

  @override
  String get communitiesCreateEvent => 'Event erstellen';

  @override
  String get communitiesEventsEmpty => 'Noch keine Events';

  @override
  String get communitiesTranslate => 'Übersetzen';

  @override
  String get communitiesShowOriginal => 'Original anzeigen';

  @override
  String get communitiesTranslating => 'Übersetze…';

  @override
  String get eventsFilterSoon => 'Bald';

  @override
  String get businessBadgeLabel => 'Business';

  @override
  String get businessWhatsappLabel => 'WhatsApp-Nummer';

  @override
  String get businessWhatsappSubtitle =>
      'Besucher tippen, um mit dir auf WhatsApp zu chatten';

  @override
  String get businessWhatsappHint => 'z. B. +351912345678';

  @override
  String get businessWhatsappButton => 'WhatsApp';

  @override
  String get locationLanguagesLabel => 'Standort & Sprachen';

  @override
  String get storefrontLocationLanguagesSubtitle =>
      'Wo du bist und welche Sprachen du sprichst';

  @override
  String get storefrontLocationNotSet => 'Nicht festgelegt';

  @override
  String get universalSearchTabBusiness => 'Business';

  @override
  String get universalSearchTabCommunity => 'Communities';

  @override
  String get universalSearchNoBusiness => 'Keine Unternehmen gefunden';

  @override
  String get universalSearchNoCommunities => 'Keine Communities gefunden';

  @override
  String get communitiesSearchTips => 'Tipps suchen';

  @override
  String get communitiesAddTip => 'Tipp hinzufügen';

  @override
  String get communitiesTipHint => 'Teile einen hilfreichen Tipp…';

  @override
  String get shopEventsCreate => 'Events, die du erstellen kannst';

  @override
  String get shopGroupsCreate =>
      'Gruppen & Communitys, die du erstellen kannst';

  @override
  String get shopDailyConnects => 'Taegliche neue Kontakte';

  @override
  String get shopMonthlyBoosts => 'Monatliche Profil-Boosts';

  @override
  String get shopMonthlyCoins => 'Monatliche Coins';

  @override
  String get shopNoAds => 'Werbefrei';

  @override
  String get shopSeeWhoConnected => 'Sieh, wer sich mit dir verbunden hat';

  @override
  String get shopTravelMode => 'Reisemodus';

  @override
  String get shopBusinessAccount => 'Business-Konto';

  @override
  String get tourCommunitiesTabsTitle => 'Drei Wege zum Stoebern';

  @override
  String get tourCommunitiesTabsDesc =>
      'Wechsle zwischen deinen Gruppen, entdecke neue und verwalte die Communities, die du erstellt hast.';

  @override
  String get tourCommunitiesSearchTitle => 'Finde deine Gruppen';

  @override
  String get tourCommunitiesSearchDesc =>
      'Tippe hier, um deine Communitys nach Namen zu filtern — praktisch, sobald du einigen beigetreten bist.';

  @override
  String get tourCommunitiesCardTitle => 'Öffnen & favorisieren';

  @override
  String get tourCommunitiesCardDesc =>
      'Tippe auf eine Community, um Chat, Tipps, Ankündigungen und Events zu öffnen. Tippe auf den ⭐ Stern, um sie zu speichern — Favoriten werden oben angeheftet.';

  @override
  String get tourCommunitiesCreateTitle => 'Community starten';

  @override
  String get tourCommunitiesCreateDesc =>
      'Tippe hier, um deine eigene Community zu erstellen und Menschen zusammenzubringen.';

  @override
  String get tourReplayGuide => 'Anleitung erneut ansehen';

  @override
  String get tourExploreSearchTitle => 'Alles durchsuchen';

  @override
  String get tourExploreSearchDesc =>
      'Finde Personen, Unternehmen, Events und Communitys — alles über eine Suche.';

  @override
  String get tourExploreQrTitle => 'Dein QR-Code';

  @override
  String get tourExploreQrDesc =>
      'Scanne oder teile einen QR-Code, um dich sofort persönlich zu verbinden.';

  @override
  String get tourEventsCreateTitle => 'Event erstellen';

  @override
  String get tourEventsCreateDesc =>
      'Tippe auf das Plus, um dein eigenes Event oder Treffen zu veranstalten.';

  @override
  String get tourEventsSearchTitle => 'Events suchen';

  @override
  String get tourEventsSearchDesc =>
      'Finde Events nach Stadt, Land oder Name und sortiere sie nach deinen Wuenschen.';

  @override
  String get tourEventsTabsTitle => 'Alle Tabs entdecken';

  @override
  String get tourEventsTabsDesc =>
      'Durchstoebere Community-Events, Live-Events, Sehenswuerdigkeiten und Erlebnisse in deiner Naehe.';

  @override
  String get tourProfileHubTitle => 'Dein Profil-Hub';

  @override
  String get tourProfileHubDesc =>
      'Alles rund um dein Konto findest du hier - bearbeite es, verwalte Einstellungen und schalte Premium-Funktionen frei.';

  @override
  String get tourProfileViewTitle => 'Profil ansehen';

  @override
  String get tourProfileViewDesc => 'Sieh genau, wie andere dein Profil sehen.';

  @override
  String get tourProfileEditTitle => 'Details bearbeiten';

  @override
  String get tourProfileEditDesc =>
      'Tippe, um Fotos, Bio, Interessen, Ort und mehr zu aktualisieren.';

  @override
  String get tourNotifHubTitle => 'Deine Benachrichtigungen';

  @override
  String get tourNotifHubDesc =>
      'Jede Verbindung, Nachricht und Event-Neuigkeit landet hier.';

  @override
  String get tourNotifOpenTitle => 'Oeffnen und verwalten';

  @override
  String get tourNotifOpenDesc =>
      'Tippe auf eine Benachrichtigung, um sie zu oeffnen, oder wische nach links, um sie zu loeschen.';

  @override
  String get tourNotifMarkAllTitle => 'Ungelesene leeren';

  @override
  String get tourNotifMarkAllDesc =>
      'Markiere alles mit einem Tippen als gelesen.';

  @override
  String get communitiesJoinAsPersonalTitle =>
      'Mit deinem persoenlichen Profil beitreten';

  @override
  String get communitiesJoinAsPersonalBody =>
      'Du trittst dieser Community mit deinem persoenlichen Profil bei. Dein Business-Schaufenster wird hier nicht angezeigt. Fortfahren?';

  @override
  String get communitiesJoinAsPersonalConfirm => 'Beitreten';

  @override
  String get communitiesCreatedManageHint =>
      'Community erstellt! Oeffne Mitglieder, um Personen hinzuzufuegen und Tipp- oder Ankuendigungsrechte zu vergeben.';

  @override
  String get exploreHappeningSoon => 'Demnaechst';

  @override
  String get attrScoreLabel => 'GreenGo Score';

  @override
  String get attrTierIconic => 'Ikonisch';

  @override
  String get attrTierExceptional => 'Außergewöhnlich';

  @override
  String get attrTierExcellent => 'Hervorragend';

  @override
  String get attrTierGreat => 'Sehr gut';

  @override
  String get attrTierWorthVisit => 'Einen Besuch wert';

  @override
  String get attrImpWorldIcon => 'Weltikone';

  @override
  String get attrImpInternational => 'Internationales Wahrzeichen';

  @override
  String get attrImpNational => 'Nationales Wahrzeichen';

  @override
  String get attrImpRegional => 'Regionale Sehenswürdigkeit';

  @override
  String get attrImpLocal => 'Lokale Sehenswürdigkeit';

  @override
  String get attrChipHome => 'Mein Land';

  @override
  String get attrChipHere => 'Du bist hier';

  @override
  String get attrFree => 'Kostenlos';

  @override
  String get attrUnesco => 'UNESCO';

  @override
  String get attrMustVisit => 'Unbedingt sehen';

  @override
  String get attrTop10 => 'Top 10';

  @override
  String get attrPhotoSpot => 'Ideal für Fotos';

  @override
  String get attrAllCategories => 'Alle';

  @override
  String get attrFilterCategory => 'Kategorie';

  @override
  String get attrFilterCountry => 'Land';

  @override
  String get attrFilterCity => 'Stadt';

  @override
  String get attrAllCities => 'Alle Städte';

  @override
  String get attrSortDistance => 'Nächstgelegene';

  @override
  String get attrSortScore => 'GreenGo Score';

  @override
  String get attrSortRating => 'Bewertung';

  @override
  String get attrSortPrice => 'Preis';

  @override
  String get attrSortName => 'Name';

  @override
  String get attrNoResults =>
      'Keine Sehenswürdigkeit entspricht deinen Filtern';

  @override
  String get attrNoCoverage =>
      'Wir haben noch keine Sehenswürdigkeiten in deinem Land – bald mehr';

  @override
  String get attrLoadFailed =>
      'Sehenswürdigkeiten konnten nicht geladen werden';

  @override
  String attrKmAway(String km) {
    return '$km km entfernt';
  }

  @override
  String get attrAbout => 'Über';

  @override
  String get attrHighlights => 'Highlights';

  @override
  String get attrWhyVisit => 'Warum hingehen';

  @override
  String get attrScoreHistorical => 'Historisch';

  @override
  String get attrScoreArchitectural => 'Architektur';

  @override
  String get attrScoreNatural => 'Natur';

  @override
  String get attrScorePhotography => 'Fotografie';

  @override
  String get attrBestTimeTitle => 'Beste Reisezeit';

  @override
  String get attrHistoryTitle => 'Geschichte';

  @override
  String get attrDidYouKnow => 'Wusstest du schon';

  @override
  String get attrPhotoTips => 'Fototipps';

  @override
  String get attrPractical => 'Praktische Infos';

  @override
  String get attrOpeningHours => 'Öffnungszeiten';

  @override
  String get attrVisitDuration => 'Typischer Besuch';

  @override
  String get attrAccessibility => 'Barrierefreiheit';

  @override
  String get attrPets => 'Haustiere';

  @override
  String get attrSafety => 'Sicherheit';

  @override
  String get attrVisitorsPerYear => 'Besucher pro Jahr';

  @override
  String get attrTicketFrom => 'Ticket';

  @override
  String get attrOpenInMaps => 'In Maps öffnen';

  @override
  String attrPhotoBy(String author, String license) {
    return 'Foto: $author · $license';
  }

  @override
  String get attrIndoor => 'Innen';

  @override
  String get attrOutdoor => 'Außen';

  @override
  String attrCountAttractions(int count) {
    return '$count Sehenswürdigkeiten';
  }

  @override
  String get attrEnableLocation =>
      'Standort aktivieren, um zu sehen, was gerade in deiner Nähe ist';

  @override
  String get attrRetry => 'Erneut versuchen';

  @override
  String get attrTranslate => 'Übersetzen';

  @override
  String get attrShowOriginal => 'Original anzeigen';

  @override
  String get attrCatReligious => 'Sakralbau';

  @override
  String get attrCatHistoricSite => 'Historische Stätte';

  @override
  String get attrCatMuseum => 'Museum';

  @override
  String get attrCatNature => 'Natur';

  @override
  String get attrCatNeighborhood => 'Viertel';

  @override
  String get attrCatBeach => 'Strand';

  @override
  String get attrCatGarden => 'Garten';

  @override
  String get attrCatMonument => 'Denkmal';

  @override
  String get attrCatSquare => 'Platz';

  @override
  String get attrCatStreet => 'Straße';

  @override
  String get attrCatArchitecture => 'Architektur';

  @override
  String get attrCatObservationDeck => 'Aussichtspunkt';

  @override
  String get attrCatCastle => 'Burg';

  @override
  String get attrCatMarket => 'Markt';

  @override
  String get attrCatMountain => 'Berg';

  @override
  String get attrCatPalace => 'Palast';

  @override
  String get attrCatIsland => 'Insel';

  @override
  String get attrCatLake => 'See';

  @override
  String get attrCatNationalPark => 'Nationalpark';

  @override
  String get attrCatOther => 'Sonstiges';

  @override
  String get attrCatBridge => 'Brücke';

  @override
  String get attrCatThemePark => 'Freizeitpark';

  @override
  String get attrCatWaterfall => 'Wasserfall';

  @override
  String get attrCatZoo => 'Zoo';

  @override
  String get attrCatShopping => 'Shopping';

  @override
  String get attrCatAquarium => 'Aquarium';

  @override
  String attrSearchResults(int count, String query) {
    return '$count Ergebnisse für \"$query\"';
  }

  @override
  String get attendeesSeeAll => 'Alle ansehen';

  @override
  String attendeesCount(int count) {
    return '$count nehmen teil';
  }

  @override
  String attendeesCountWithGuests(int count, int guests) {
    return '$count nehmen teil · $guests Gäste';
  }

  @override
  String attendeesBringing(int count) {
    return 'Bringt $count Gäste mit';
  }

  @override
  String get attendeesOrganizer => 'Veranstalter';

  @override
  String get attendeesLoadFailed => 'Teilnehmer konnten nicht geladen werden';

  @override
  String get attendeesProfileFailed => 'Profil konnte nicht geöffnet werden';

  @override
  String get quizTitle => 'Persönlichkeitstest';

  @override
  String get quizSubtitle => 'Hilf uns, deine Persönlichkeit zu verstehen';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Frage $current von $total';
  }

  @override
  String get quizQuestionOpenness =>
      'Ich probiere gerne neue und aufregende Aktivitäten aus';

  @override
  String get quizQuestionConscientiousness =>
      'Ich bevorzuge eine strukturierte und organisierte Routine';

  @override
  String get quizQuestionExtraversion =>
      'Ich fühle mich energiegeladen, wenn ich mit anderen zusammen bin';

  @override
  String get quizQuestionAgreeableness =>
      'Ich versuche, kooperativ zu sein und Konflikte zu vermeiden';

  @override
  String get quizQuestionNeuroticism =>
      'Ich fühle mich oft ängstlich oder mache mir Sorgen';

  @override
  String get quizAnswerStronglyDisagree => 'Stimme überhaupt nicht zu';

  @override
  String get quizAnswerDisagree => 'Stimme nicht zu';

  @override
  String get quizAnswerNeutral => 'Neutral';

  @override
  String get quizAnswerAgree => 'Stimme zu';

  @override
  String get quizAnswerStronglyAgree => 'Stimme voll und ganz zu';

  @override
  String get quizBigFiveNote =>
      'Basierend auf dem Big-Five-Persönlichkeitsmodell';

  @override
  String get profilePreviewTitle => 'Profilvorschau';

  @override
  String get profilePreviewSubtitle =>
      'Überprüfe dein Profil, bevor du abschließt';

  @override
  String get profilePreviewCompleteButton => 'Profil abschließen';

  @override
  String get profileFieldName => 'Name';

  @override
  String get profileFieldAge => 'Alter';

  @override
  String profileAgeYearsOld(int age) {
    return '$age Jahre alt';
  }

  @override
  String get profileFieldStatus => 'Status';

  @override
  String get profileNoBio => 'Keine Biografie angegeben';

  @override
  String get profileCompleteBadgeTitle => 'Profil vollständig!';

  @override
  String get profileCompleteBadgeSubtitle =>
      'Dein Profil ist bereit zur Veröffentlichung';

  @override
  String get personalityTraitsTitle => 'Persönlichkeitsmerkmale';

  @override
  String get traitOpenness => 'Offenheit';

  @override
  String get traitConscientiousness => 'Gewissenhaftigkeit';

  @override
  String get traitExtraversion => 'Extraversion';

  @override
  String get traitAgreeableness => 'Verträglichkeit';

  @override
  String get traitNeuroticism => 'Neurotizismus';

  @override
  String get socialLinksSubtitle =>
      'Verbinde deine Social-Media-Konten (optional)';

  @override
  String get socialHintUsernameNoAt => 'Benutzername (ohne @)';

  @override
  String get socialLinksVisibilityNote =>
      'Deine sozialen Profile werden in deinem öffentlichen Profil angezeigt';

  @override
  String get travelPrefTitle => 'Wie möchtest du GreenGo nutzen?';

  @override
  String get travelPrefSubtitle =>
      'Erzähl uns von deinen Interessen, damit wir dein Erlebnis personalisieren können.';

  @override
  String get travelPrefLearnTravelTitle => 'Lernen & Reisen';

  @override
  String get travelPrefLearnTravelDesc =>
      'Sprachen lernen und Menschen kennenlernen, wenn ich an neue Orte reise';

  @override
  String get travelPrefLocalGuideTitle => 'Lokaler Guide';

  @override
  String get travelPrefLocalGuideDesc =>
      'Reisenden helfen, meine Stadt zu entdecken, und meine Kultur mit ihnen teilen';

  @override
  String get travelPrefBothTitle => 'Beides';

  @override
  String get travelPrefBothDesc =>
      'Ich möchte Sprachen lernen, die Welt bereisen und Besuchern in meiner Stadt helfen';

  @override
  String get travelPrefChangeLater =>
      'Du kannst dies jederzeit in deinen Profileinstellungen ändern.';

  @override
  String get locationErrorPermissionDenied =>
      'Standortberechtigung wurde verweigert. Bitte erteile die Berechtigung in den Einstellungen.';

  @override
  String get locationErrorServicesDisabled =>
      'Standortdienste sind deaktiviert. Bitte aktiviere sie in den Einstellungen.';

  @override
  String get locationErrorUnableToGet =>
      'Dein Standort konnte nicht ermittelt werden. Bitte überprüfe deine Geräteeinstellungen oder versuche es später erneut.';

  @override
  String get locationErrorCheckInternet =>
      'Bitte überprüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get locationErrorPermissionRequired =>
      'Standortberechtigung ist erforderlich. Bitte erteile die Berechtigung in den Einstellungen.';

  @override
  String get locationErrorTookTooLong =>
      'Die Standortermittlung hat zu lange gedauert. Bitte versuche es erneut.';

  @override
  String get phoneErrorInvalidNumber =>
      'Ungültiges Telefonnummernformat. Bitte verwende das internationale Format (z. B. +1234567890).';

  @override
  String get phoneErrorTooManyRequests =>
      'Zu viele Versuche. Bitte warte einige Minuten, bevor du es erneut versuchst.';

  @override
  String get phoneErrorQuotaExceeded =>
      'SMS-Kontingent überschritten. Bitte versuche es später erneut.';

  @override
  String get phoneErrorCaptchaFailed =>
      'reCAPTCHA-Überprüfung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get phoneErrorMissingNumber => 'Bitte gib eine Telefonnummer ein.';

  @override
  String phoneErrorGeneric(String code) {
    return 'Fehler bei der Telefonverifizierung ($code). Bitte versuche es erneut.';
  }

  @override
  String get phoneErrorUnexpected =>
      'Fehler bei der Telefonverifizierung. Bitte versuche es erneut.';

  @override
  String get phoneErrorAlreadyLinked =>
      'Diese Telefonnummer ist bereits mit einem anderen Konto verknüpft.';

  @override
  String get languageNameEnglish => 'Englisch';

  @override
  String get languageNameSpanish => 'Spanisch';

  @override
  String get languageNameFrench => 'Französisch';

  @override
  String get languageNameGerman => 'Deutsch';

  @override
  String get languageNameItalian => 'Italienisch';

  @override
  String get languageNamePortuguese => 'Portugiesisch';

  @override
  String get languageNamePortugueseBrazil => 'Portugiesisch (Brasilien)';

  @override
  String get languageNameRussian => 'Russisch';

  @override
  String get languageNameChinese => 'Chinesisch';

  @override
  String get languageNameJapanese => 'Japanisch';

  @override
  String get languageNameKorean => 'Koreanisch';

  @override
  String get languageNameArabic => 'Arabisch';

  @override
  String get languageNameHindi => 'Hindi';

  @override
  String get languageNameDutch => 'Niederländisch';

  @override
  String get languageNameSwedish => 'Schwedisch';

  @override
  String get languageNameNorwegian => 'Norwegisch';

  @override
  String get languageNameDanish => 'Dänisch';

  @override
  String get languageNameFinnish => 'Finnisch';

  @override
  String get languageNamePolish => 'Polnisch';

  @override
  String get languageNameTurkish => 'Türkisch';

  @override
  String get languageNameGreek => 'Griechisch';

  @override
  String get resetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get resetPasswordSubtitle =>
      'Gib deine E-Mail-Adresse ein und wir senden dir eine Anleitung zum Zurücksetzen deines Passworts.';

  @override
  String get sendResetLink => 'Link zum Zurücksetzen senden';

  @override
  String get backToLogin => 'Zurück zur Anmeldung';

  @override
  String get resetLinkExpiryNote =>
      'Der Link zum Zurücksetzen läuft aus Sicherheitsgründen nach 1 Stunde ab.';

  @override
  String get resetEmailSentTitle => 'E-Mail gesendet!';

  @override
  String resetEmailSentBody(String email) {
    return 'Ein Link zum Zurücksetzen des Passworts wurde an $email gesendet.\n\nBitte überprüfe deinen Posteingang und den Spam-Ordner.';
  }

  @override
  String get resetErrorInvalidEmail => 'Ungültige E-Mail-Adresse.';

  @override
  String get resetErrorUnavailable =>
      'Dienst vorübergehend nicht verfügbar. Bitte versuche es später erneut.';

  @override
  String get resetErrorFailed =>
      'Die E-Mail zum Zurücksetzen konnte nicht gesendet werden. Bitte versuche es erneut.';

  @override
  String get onboardingSubmitCreatingProfile => 'Dein Profil wird erstellt…';

  @override
  String get onboardingSubmitGrantingCoins =>
      'Deine Coins werden eingerichtet…';

  @override
  String get onboardingSubmitFinishingUp => 'Fast geschafft…';

  @override
  String get onboardingSubmitPleaseWait => 'Das dauert nur einen Moment';

  @override
  String get chatSettingSilverPlusOnly => 'Ab Silber verfügbar';

  @override
  String get chatSettingXpBarHint =>
      'Erscheint, sobald du in diesem Chat XP sammelst';

  @override
  String get chatSettingLanguageFlagsHint =>
      'Wird bei übersetzten Nachrichten angezeigt';

  @override
  String get chatSmartRepliesLoading => 'Antworten werden vorbereitet...';

  @override
  String get errorScreenTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorScreenBody =>
      'Dieser Bildschirm konnte nicht geöffnet werden. Lade die App neu, um es erneut zu versuchen — dein Konto ist nicht betroffen.';

  @override
  String get errorScreenReload => 'Neu laden';

  @override
  String get ageVerifyTitle => 'Alter bestätigen';

  @override
  String get ageVerifyWhyPublish =>
      'Um in einer Community zu posten, müssen wir bestätigen, dass du über 18 bist.';

  @override
  String get ageVerifyWhyPhone =>
      'Du hast dich mit einer Telefonnummer registriert, daher brauchen wir ein Dokument zur Altersbestätigung.';

  @override
  String get ageVerifyPrivacyNote =>
      'Wir lesen das Geburtsdatum automatisch aus. Das Foto wird gelöscht, sobald eine Entscheidung gefallen ist (spätestens nach 7 Tagen, wenn eine Person es prüfen muss), und wird nie in deinem Profil angezeigt.';

  @override
  String get ageVerifyTakePhoto => 'Ausweis fotografieren';

  @override
  String get ageVerifyChooseImage => 'Aus der Galerie wählen';

  @override
  String get ageVerifyChecking => 'Dokument wird geprüft…';

  @override
  String get ageVerifyPending =>
      'Wir prüfen dein Dokument. Das dauert meist weniger als einen Tag.';

  @override
  String get ageVerifyVerified => 'Dein Alter ist bestätigt.';

  @override
  String get ageVerifyRejected =>
      'Wir konnten dein Dokument nicht lesen. Bitte versuche es mit einem schärferen Foto.';

  @override
  String get ageVerifyRejectedUnderage =>
      'Das Dokument zeigt, dass du unter 18 bist.';

  @override
  String get ageVerifyRejectedReused =>
      'Dieses Dokument ist bereits mit einem anderen Konto verknüpft.';

  @override
  String get ageVerifyCta => 'Jetzt bestätigen';

  @override
  String get ageVerifyLater => 'Später';

  @override
  String get ageVerifyNeededToPost => 'Alter bestätigen, um zu posten';

  @override
  String get contactSupportSubtitle =>
      'Fragen, Probleme oder Meldungen — wir antworten per E-Mail';

  @override
  String get offerPreRegisteredTitle => 'Du bist vorregistriert';

  @override
  String get offerWelcomePackTitle => 'Dein Willkommenspaket';

  @override
  String offerTierLine(String tier, String duration) {
    return '$tier-Mitgliedschaft für $duration';
  }

  @override
  String offerBaseLine(String duration) {
    return 'Base-Mitgliedschaft für $duration';
  }

  @override
  String get offerFreeMonthLine => 'Ein Monat voller Zugriff, kostenlos';

  @override
  String offerCoinsLine(int coins) {
    return '$coins Willkommensmünzen';
  }

  @override
  String get offerAppliedFromToday =>
      'Wird ab heute automatisch hinzugefügt, bei deiner ersten Anmeldung.';

  @override
  String get offerDurationOneMonth => '1 Monat';

  @override
  String offerDurationMonths(int count) {
    return '$count Monate';
  }

  @override
  String get offerDurationOneYear => '1 Jahr';

  @override
  String offerDurationDays(int count) {
    return '$count Tage';
  }

  @override
  String get featureIncludedTitle => 'WAS ENTHALTEN IST';

  @override
  String get featureUnlimited => 'Unbegrenzt';

  @override
  String featureDailyConnects(String count) {
    return '$count neue Kontakte pro Tag';
  }

  @override
  String featureMonthlyCoins(int coins) {
    return '$coins Münzen pro Monat';
  }

  @override
  String featureEvents(String count) {
    return '$count gleichzeitig laufende Events';
  }

  @override
  String featureBoosts(int count) {
    return '$count Profil-Boosts pro Monat';
  }

  @override
  String featureDiscoveryReveals(int count) {
    return '$count Profile auf einmal sichtbar';
  }

  @override
  String get featureTravelMode => 'Reisemodus - entdecke Menschen überall';

  @override
  String get featureWhoConnected => 'Sieh, wer sich mit dir verbunden hat';

  @override
  String get boostProfileCelebrationTitle => 'Profil geboostet!';

  @override
  String get boostEventCelebrationTitle => 'Event geboostet!';

  @override
  String get eventsEnded => 'Event beendet';

  @override
  String get eventsAttendeeListVisibility => 'Wer sehen darf, wer kommt';

  @override
  String get eventsAttendeeListPrivate => 'Niemand';

  @override
  String get eventsAttendeeListParticipants => 'Teilnehmende';

  @override
  String get eventsAttendeeListPublic => 'Alle';

  @override
  String get eventsAttendeeListPrivateHint => 'Nur du siehst die Gästeliste.';

  @override
  String get eventsAttendeeListParticipantsHint =>
      'Teilnehmende sehen einander.';

  @override
  String get eventsAttendeeListPublicHint =>
      'Alle, die das Event sehen, sehen auch die Gästeliste.';

  @override
  String get eventsAttendeeListHidden =>
      'Die Organisation hat die Gästeliste ausgeblendet.';

  @override
  String get eventsOrganizedBy => 'Organisiert von';

  @override
  String eventsOrganizerYou(String name) {
    return '$name (du)';
  }

  @override
  String eventsByOrganizer(String name) {
    return 'von $name';
  }

  @override
  String shareEventMessageTitled(String title, String link) {
    return '$title\nSieh dir dieses Event auf GreenGo an: $link';
  }

  @override
  String shareCommunityMessage(String name, String link) {
    return '$name\nTritt dieser Community auf GreenGo bei: $link';
  }

  @override
  String shopMembershipExpiredOn(String tier, String date) {
    return 'Deine $tier-Mitgliedschaft ist am $date abgelaufen';
  }

  @override
  String get eventsLocationHelper =>
      'Gib einen Ort oder eine Adresse ein oder wähle ihn auf der Karte';

  @override
  String get eventsPickOnMap => 'Auf der Karte wählen';

  @override
  String get eventsLocationNotOnMap =>
      'Mit dem eingegebenen Ort gespeichert. Wir konnten ihn nicht auf der Karte finden, daher erscheint er nicht in der Umkreissuche.';

  @override
  String get eventsCoOwners => 'Mitveranstalter';

  @override
  String get eventsCoOwnersHelper =>
      'Mitveranstalter können das Event bearbeiten, die Anwesenheitsliste öffnen, Gäste einchecken und die vollständige Gästeliste sehen. Nur du kannst das Event löschen oder Mitveranstalter ändern.';

  @override
  String get eventsCoOwnersCreatorOnly =>
      'Nur der Ersteller des Events kann Mitveranstalter ändern.';

  @override
  String get eventsAddCoOwner => 'Mitveranstalter hinzufügen';

  @override
  String eventsCoOwnerLimit(int max) {
    return 'Du kannst bis zu $max Mitveranstalter hinzufügen';
  }

  @override
  String get eventsCoOwnerSearchHint => 'Nach Nickname suchen';

  @override
  String get eventsCoOwnerSearch => 'Suchen';

  @override
  String get eventsCoOwnerRecentChats => 'Letzte Chats';

  @override
  String get eventsCoOwnerNoRecentChats => 'Noch keine letzten Chats';

  @override
  String get eventsCoOwnerNotFound => 'Niemand mit diesem Nickname gefunden';

  @override
  String get eventsCoOwnerSearchFailed =>
      'Suche fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get eventsCoOwnerRemove => 'Mitveranstalter entfernen';

  @override
  String eventsOrganizedWith(String names) {
    return 'mit $names';
  }

  @override
  String get eventsCoOwnerBadge => 'Mitveranstalter';

  @override
  String get qrHubCancelRsvpConfirm =>
      'Dieses Ticket löschen? Damit wird deine Zusage storniert und dein Platz für jemand anderen frei.';

  @override
  String get qrHubHideTicketConfirm =>
      'Dieses Ticket aus deiner Liste entfernen? Dein Teilnahmenachweis bleibt erhalten.';

  @override
  String get qrHubTicketRemoved => 'Ticket entfernt';

  @override
  String get usageDailyUsageTitle => 'Tägliche Nutzung';

  @override
  String get usageConnectsThisHour => 'Verbindungen diese Stunde';

  @override
  String get usagePassesThisHour => 'Übersprungen diese Stunde';

  @override
  String get usagePriorityConnectsThisHour =>
      'Priority-Verbindungen diese Stunde';

  @override
  String get usageMessagesToday => 'Nachrichten heute';

  @override
  String get usageMediaSentToday => 'Heute gesendete Medien';

  @override
  String get usageUpgradeBenefitsTitle => 'Vorteile beim Upgrade';

  @override
  String get usageUpgradeButton => 'Mitgliedschaft upgraden';

  @override
  String usagePlanName(String tier) {
    return '$tier-Plan';
  }

  @override
  String get usageCurrentTierLabel => 'Aktuelle Mitgliedschaftsstufe';

  @override
  String get usageNoBaseMembership => 'Keine GreenGo-Basismitgliedschaft';

  @override
  String usageExpiresOn(String date) {
    return 'Läuft ab: $date';
  }

  @override
  String usageExpiredOn(String date) {
    return 'Abgelaufen: $date';
  }

  @override
  String get usageStatusActive => 'Aktiv';

  @override
  String get usageStatusExpired => 'Abgelaufen';

  @override
  String get usageCoinsAvailable => 'Verfügbare Münzen';

  @override
  String get usageNotAvailable => 'Nicht verfügbar';

  @override
  String usageWithTier(String tier) {
    return 'Mit $tier';
  }

  @override
  String get attrApplyFilter => 'Filter anwenden';

  @override
  String get userFollowFollow => 'Folgen';

  @override
  String get userFollowFollowing => 'Gefolgt';

  @override
  String get userFollowFollowBack => 'Zurückfolgen';

  @override
  String get userFollowError =>
      'Folgen konnte nicht aktualisiert werden. Bitte versuche es erneut.';

  @override
  String get userFollowBlocked => 'Du kannst diesem Nutzer nicht folgen.';

  @override
  String get userFollowUnfollowTooltip => 'Nicht mehr folgen';

  @override
  String userFollowFollowersStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted Follower',
    );
    return '$_temp0';
  }

  @override
  String userFollowFollowingStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted gefolgt',
    );
    return '$_temp0';
  }

  @override
  String get userFollowTabFollowers => 'Follower';

  @override
  String get userFollowTabFollowing => 'Gefolgt';

  @override
  String get userFollowEmptyFollowers => 'Noch keine Follower';

  @override
  String get userFollowEmptyFollowing => 'Folgt noch niemandem';

  @override
  String get userFollowListError => 'Diese Liste konnte nicht geladen werden.';

  @override
  String attractionViewsCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted Aufrufe',
      one: '$formatted Aufruf',
    );
    return '$_temp0';
  }

  @override
  String get uexpCommunity => 'Community';

  @override
  String get uexpPartners => 'Partner';

  @override
  String get uexpCreate => 'Erlebnis erstellen';

  @override
  String get uexpMine => 'Meine Erlebnisse';

  @override
  String get uexpEmpty =>
      'Noch keine Community-Erlebnisse. Biete als Erste:r eines an!';

  @override
  String get uexpMineEmpty => 'Du hast noch keine Erlebnisse erstellt.';

  @override
  String get uexpAll => 'Alle';

  @override
  String get uexpFree => 'Kostenlos';

  @override
  String get uexpCatFoodDrink => 'Essen & Trinken';

  @override
  String get uexpCatCultureHistory => 'Kultur & Geschichte';

  @override
  String get uexpCatNatureOutdoors => 'Natur & Outdoor';

  @override
  String get uexpCatNightlife => 'Nachtleben';

  @override
  String get uexpCatSportsAdventure => 'Sport & Abenteuer';

  @override
  String get uexpCatWellness => 'Wellness';

  @override
  String get uexpCatLanguageLearning => 'Sprachen lernen';

  @override
  String get uexpCatToursWalks => 'Touren & Spaziergänge';

  @override
  String get uexpCatWorkshopsClasses => 'Workshops & Kurse';

  @override
  String get uexpCatOther => 'Sonstiges';

  @override
  String uexpReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bewertungen',
      one: '1 Bewertung',
      zero: 'Keine Bewertungen',
    );
    return '$_temp0';
  }

  @override
  String get uexpStatusDraft => 'Entwurf';

  @override
  String get uexpStatusPublished => 'Veröffentlicht';

  @override
  String get uexpStatusHidden => 'Ausgeblendet';

  @override
  String get uexpHiddenNotice =>
      'Dieses Erlebnis wurde ausgeblendet, weil es gegen die GreenGo-Standards verstößt. Bearbeite den Text, um es wiederherzustellen.';

  @override
  String get uexpNewTitle => 'Neues Erlebnis';

  @override
  String get uexpEditTitle => 'Erlebnis bearbeiten';

  @override
  String get uexpSectionPhotos => 'Fotos';

  @override
  String get uexpSectionBasics => 'Über das Erlebnis';

  @override
  String get uexpSectionPractical => 'Praktische Infos';

  @override
  String get uexpMainPhoto => 'Hauptfoto (erforderlich)';

  @override
  String uexpMorePhotos(int max) {
    return 'bis zu $max weitere Fotos';
  }

  @override
  String get uexpFieldTitle => 'Titel';

  @override
  String get uexpFieldDescription => 'Beschreibung';

  @override
  String get uexpFieldCategory => 'Kategorie';

  @override
  String get uexpIncluded => 'Was ist inbegriffen';

  @override
  String get uexpNotIncluded => 'Was ist nicht inbegriffen';

  @override
  String get uexpAddItem => 'Punkt hinzufügen';

  @override
  String get uexpRemoveItem => 'Punkt entfernen';

  @override
  String get uexpItemHint => 'z. B. Lokale Snacks';

  @override
  String get uexpFieldLocation => 'Ort';

  @override
  String get uexpLocationHint => 'Ort eingeben oder auf der Karte wählen';

  @override
  String get uexpPickOnMap => 'Auf der Karte wählen';

  @override
  String get uexpMeetingPoint => 'Treffpunkt (optional)';

  @override
  String get uexpMeetingPointLabel => 'Treffpunkt';

  @override
  String get uexpLocationNotFound =>
      'Wir konnten diesen Ort nicht auf der Karte finden. Er wird wie eingegeben gespeichert und erscheint nicht in Ergebnissen in der Nähe.';

  @override
  String get uexpDuration => 'Dauer';

  @override
  String get uexpHours => 'Stunden';

  @override
  String get uexpMinutes => 'Minuten';

  @override
  String uexpDurationHours(int hours) {
    return '$hours Std.';
  }

  @override
  String uexpDurationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get uexpLanguages => 'Gesprochene Sprachen';

  @override
  String get uexpGroupSize => 'Gruppengröße';

  @override
  String get uexpMinGroup => 'Min. Personen (optional)';

  @override
  String get uexpMaxGroup => 'Max. Personen';

  @override
  String uexpGroupSizeRange(int min, int max) {
    return '$min–$max Personen';
  }

  @override
  String uexpGroupUpTo(int max) {
    return 'Bis zu $max Personen';
  }

  @override
  String get uexpPrice => 'Preis';

  @override
  String get uexpCurrency => 'Währung';

  @override
  String get uexpIsFree => 'Dieses Erlebnis ist kostenlos';

  @override
  String get uexpPaymentLink => 'Wie Gäste dich bezahlen';

  @override
  String get uexpPaymentType => 'Zahlungsmethode';

  @override
  String get uexpPayPix => 'PIX';

  @override
  String get uexpPayPaypal => 'PayPal';

  @override
  String get uexpPayVenmo => 'Venmo';

  @override
  String get uexpPayStripe => 'Stripe-Zahlungslink';

  @override
  String get uexpPayOther => 'Anderer Zahlungslink';

  @override
  String get uexpPaymentValuePix => 'PIX-Schlüssel';

  @override
  String get uexpPaymentValueUrl => 'Zahlungslink';

  @override
  String get uexpPaymentValueHintPix =>
      'E-Mail, Telefon, CPF oder Zufallsschlüssel';

  @override
  String get uexpPaymentDisclaimer =>
      'Zahlungen erfolgen außerhalb von GreenGo, direkt zwischen Gästen und Gastgeber:in. GreenGo wickelt sie nicht ab, garantiert sie nicht und erstattet sie nicht.';

  @override
  String get uexpAvailability => 'Verfügbarkeit (optional)';

  @override
  String get uexpAvailabilityLabel => 'Verfügbarkeit';

  @override
  String get uexpAvailabilityHint => 'z. B. samstags 10:00–13:00';

  @override
  String get uexpCancellation => 'Stornobedingungen (optional)';

  @override
  String get uexpCancellationLabel => 'Stornobedingungen';

  @override
  String get uexpSaveDraft => 'Als Entwurf speichern';

  @override
  String get uexpPublish => 'Veröffentlichen';

  @override
  String get uexpSaveChanges => 'Änderungen speichern';

  @override
  String get uexpUnpublish => 'Nicht mehr veröffentlichen';

  @override
  String get uexpSaved => 'Erlebnis gespeichert';

  @override
  String get uexpPublished => 'Erlebnis veröffentlicht';

  @override
  String get uexpUnpublished => 'Erlebnis in Entwürfe verschoben';

  @override
  String get uexpSaveFailed =>
      'Das Erlebnis konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get uexpPhotoUploadFailed =>
      'Die Fotos konnten nicht hochgeladen werden. Bitte versuche es erneut.';

  @override
  String uexpErrTitle(int min, int max) {
    return 'Der Titel muss $min–$max Zeichen lang sein';
  }

  @override
  String uexpErrDescription(int min, int max) {
    return 'Die Beschreibung muss $min–$max Zeichen lang sein';
  }

  @override
  String get uexpErrMainPhoto => 'Füge ein Hauptfoto hinzu';

  @override
  String uexpErrTooManyPhotos(int max) {
    return 'Bis zu $max zusätzliche Fotos';
  }

  @override
  String get uexpErrIncluded =>
      'Füge mindestens einen inbegriffenen Punkt hinzu';

  @override
  String uexpErrTooManyItems(int max) {
    return 'Bis zu $max Punkte';
  }

  @override
  String uexpErrItemTooLong(int max) {
    return 'Jeder Punkt darf bis zu $max Zeichen haben';
  }

  @override
  String get uexpErrLocation => 'Gib einen Ort ein';

  @override
  String get uexpErrDuration =>
      'Gib eine Dauer zwischen 15 Minuten und 14 Tagen ein';

  @override
  String get uexpErrLanguages => 'Wähle mindestens eine Sprache';

  @override
  String uexpErrMaxGroup(int max) {
    return 'Max. Personen muss zwischen 1 und $max liegen';
  }

  @override
  String get uexpErrMinGroup =>
      'Min. Personen muss mindestens 1 und darf nicht größer als das Maximum sein';

  @override
  String get uexpErrPrice => 'Gib einen gültigen Preis ein';

  @override
  String get uexpErrPaymentRequired =>
      'Gib an, wie Gäste dich bezahlen (oder markiere das Erlebnis als kostenlos)';

  @override
  String get uexpErrPaymentInvalid =>
      'Gib einen gültigen Link ein, der mit https:// beginnt';

  @override
  String get uexpErrProhibited =>
      'Ein Text enthält Formulierungen, die auf GreenGo nicht erlaubt sind';

  @override
  String get uexpErrNoLinks =>
      'Links sind in Bewertungen und Antworten nicht erlaubt';

  @override
  String uexpErrTooLong(int max) {
    return 'Bis zu $max Zeichen';
  }

  @override
  String get uexpErrFixFields => 'Bitte korrigiere die markierten Felder';

  @override
  String get uexpLimitFeature => 'Erlebnisse anbieten';

  @override
  String get uexpLimitFreeBody =>
      'Erlebnisse anbieten ist mit einer Silver-, Gold- oder Platinum-Mitgliedschaft möglich.';

  @override
  String uexpLimitReachedBody(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Dein Tarif erlaubt $limit Erlebnisse.',
      one: 'Dein Tarif erlaubt 1 Erlebnis.',
    );
    return '$_temp0 Upgrade, um weitere Erlebnisse zu erstellen.';
  }

  @override
  String get uexpUpgradeToCreateMore => 'Upgrade für mehr Erlebnisse';

  @override
  String get shopExperiencesCreate => 'Erlebnisse, die du erstellen kannst';

  @override
  String get uexpHostedBy => 'Gastgeber:in';

  @override
  String get uexpHostBadge => 'Gastgeber:in';

  @override
  String get uexpPayBook => 'Bezahlen / Buchen';

  @override
  String get uexpPixCopied => 'PIX-Schlüssel in die Zwischenablage kopiert';

  @override
  String get uexpOpenLinkFailed => 'Der Link konnte nicht geöffnet werden';

  @override
  String get uexpShare => 'Teilen';

  @override
  String uexpShareText(String title, String link) {
    return '$title\nEntdecke dieses Erlebnis auf GreenGo: $link';
  }

  @override
  String get uexpReport => 'Melden';

  @override
  String get uexpReportTitle => 'Dieses Erlebnis melden?';

  @override
  String get uexpReportBody =>
      'Unser Team prüft es anhand der GreenGo-Standards.';

  @override
  String get uexpReported => 'Danke, wir prüfen das.';

  @override
  String get uexpReportReview => 'Bewertung melden';

  @override
  String get uexpEdit => 'Bearbeiten';

  @override
  String get uexpDelete => 'Löschen';

  @override
  String get uexpDeleteConfirmTitle => 'Dieses Erlebnis löschen?';

  @override
  String get uexpDeleteConfirmBody =>
      'Die Bewertungen werden ebenfalls gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get uexpDeleted => 'Erlebnis gelöscht';

  @override
  String get uexpNotFound => 'Dieses Erlebnis ist nicht mehr verfügbar.';

  @override
  String get uexpReviews => 'Bewertungen';

  @override
  String get uexpNoReviews => 'Noch keine Bewertungen';

  @override
  String get uexpWriteReview => 'Bewertung schreiben';

  @override
  String get uexpEditReview => 'Bewertung bearbeiten';

  @override
  String get uexpYourRating => 'Deine Bewertung';

  @override
  String get uexpSelectRating => 'Wähle 1 bis 5 Sterne';

  @override
  String get uexpCommentHint => 'Was hat dir gefallen? (optional)';

  @override
  String get uexpSubmit => 'Senden';

  @override
  String get uexpDeleteReview => 'Bewertung löschen';

  @override
  String get uexpDeleteReviewConfirm => 'Deine Bewertung löschen?';

  @override
  String get uexpReviewSaved => 'Bewertung gespeichert';

  @override
  String get uexpReviewDeleted => 'Bewertung gelöscht';

  @override
  String get uexpReviewRemoved =>
      'Deine Bewertung wurde wegen eines Verstoßes gegen die GreenGo-Standards entfernt. Bearbeite sie, um es erneut zu versuchen.';

  @override
  String get uexpReplyRemoved =>
      'Deine Antwort wurde wegen eines Verstoßes gegen die GreenGo-Standards entfernt.';

  @override
  String get uexpPendingModeration => 'Wird geprüft…';

  @override
  String get uexpHostCannotReview =>
      'Gastgeber:innen können ihr eigenes Erlebnis nicht bewerten.';

  @override
  String get uexpReply => 'Antworten';

  @override
  String get uexpReplyHint =>
      'Antwort schreiben. Tippe @, um jemanden zu markieren';

  @override
  String get uexpShowMoreReplies => 'Weitere Antworten anzeigen';

  @override
  String get uexpLoadMoreReviews => 'Weitere Bewertungen laden';

  @override
  String get uexpEdited => 'bearbeitet';

  @override
  String get feedFilterTooltip => 'Anzeigen';

  @override
  String get feedFilterAll => 'Alle';

  @override
  String get feedFilterCommunity => 'Community';

  @override
  String get feedFilterPartner => 'Partner';

  @override
  String get feedFilterMyEvents => 'Meine Events';

  @override
  String get feedFilterMyExperiences => 'Meine Erlebnisse';

  @override
  String get partnerBadge => 'Partner';

  @override
  String get createChooserTitle => 'Was möchtest du erstellen?';

  @override
  String get createChooserEventDesc =>
      'Organisiere ein Treffen oder eine Aktivität für Leute in deiner Nähe';

  @override
  String get createChooserExperienceDesc =>
      'Biete als Gastgeber eine Tour, einen Kurs oder ein lokales Erlebnis an';

  @override
  String get uexpAddExperience => 'Erlebnis hinzufügen';

  @override
  String get uexpNewHost => 'Neuer Gastgeber';

  @override
  String uexpHostRatings(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText Bewertungen',
      one: '$countText Bewertung',
    );
    return '$_temp0';
  }

  @override
  String get verifiedBadgeLabel => 'Verifiziert';

  @override
  String get verifiedBadgeTooltip => 'Ausweis von GreenGo verifiziert';

  @override
  String get idDocumentRetentionNotice =>
      'Zur Betrugsprävention und zur Sicherheit der Community werden Ausweisdokumente bis zu 30 Tage nach der Kontolöschung aufbewahrt und danach endgültig gelöscht.';

  @override
  String get uexpErrContactInfo =>
      'Entferne Telefonnummern, E-Mail-Adressen, @Handles und Zahlungsdaten: Gäste zahlen nur über die Zahlungsarten deines Angebots.';

  @override
  String get uexpErrPaymentMethods => 'Wähle mindestens eine Zahlungsart';

  @override
  String get uexpPaymentLinkDetails => 'Online-Zahlungslink';

  @override
  String get uexpMethodCash => 'Bar beim Treffen';

  @override
  String get uexpMethodLink => 'Online-Link (PIX/PayPal/…)';

  @override
  String get uexpBook => 'Buchen';

  @override
  String get uexpBookedCash =>
      'Notiert. Bezahle den Gastgeber beim Treffen in bar.';

  @override
  String get uexpIdDocTitle => 'Ausweisdokument erforderlich';

  @override
  String get uexpIdDocGuestBody =>
      'Damit GreenGo sicher bleibt, lade bitte ein Ausweisdokument hoch, bevor du einen Gastgeber bezahlst.';

  @override
  String get uexpIdDocHostBody =>
      'Gastgeber müssen ein Ausweisdokument hochladen, bevor sie ein Erlebnis erstellen.';

  @override
  String get uexpIdDocUpload => 'Dokument hochladen';

  @override
  String get uexpPaidPendingTitle => 'Ausweisprüfung läuft';

  @override
  String get uexpPaidPendingBody =>
      'Bezahlte Erlebnisse brauchen ein bestätigtes Ausweisdokument. Deines wird noch geprüft: Speichere dieses Erlebnis vorerst als Entwurf oder veröffentliche es kostenlos.';

  @override
  String get uexpPaidMissingBody =>
      'Bezahlte Erlebnisse brauchen ein bestätigtes Ausweisdokument. Lade eines hoch (oder ein neues, falls es abgelehnt wurde), oder speichere dieses Erlebnis vorerst als Entwurf oder veröffentliche es kostenlos.';

  @override
  String get uexpNewHostLimitTitle => 'Limit für neue Gastgeber';

  @override
  String get uexpNewHostLimitBody =>
      'Bis du 3 Bewertungen hast, kannst du ein bezahltes Erlebnis veröffentlicht haben. Speichere dieses als Entwurf oder veröffentliche es kostenlos.';

  @override
  String get uexpPublishAsFree => 'Kostenlos veröffentlichen';

  @override
  String get uexpHostBanned => 'Dein Konto kann keine Erlebnisse anbieten.';

  @override
  String get hostAgreementTitle => 'Gastgebervereinbarung';

  @override
  String get hostAgreementIntro =>
      'Bevor du dein erstes Erlebnis veröffentlichst, lies und akzeptiere bitte diese Regeln.';

  @override
  String get hostAgreementClause1 =>
      'Du organisierst und leitest dieses Erlebnis und bist für das Erlebnis und die Sicherheit deiner Gäste verantwortlich.';

  @override
  String get hostAgreementClause2 =>
      'Beschreibe es korrekt: Titel, Fotos, Preis, Dauer, Leistungen und Treffpunkt müssen stimmen und aktuell sein.';

  @override
  String get hostAgreementClause3 =>
      'Halte dich an das Gesetz: Du besitzt alle Lizenzen, Genehmigungen, Versicherungen oder Anmeldungen, die deine Tätigkeit vor Ort erfordert, und gibst deine Einnahmen wie vorgeschrieben an.';

  @override
  String get hostAgreementClause4 =>
      'Erstatte Gästen gemäß der gewählten Stornierungsrichtlinie und immer vollständig, wenn du absagst.';

  @override
  String get hostAgreementClause5 =>
      'Bitte Gäste nie, außerhalb der in deinem Angebot angezeigten Zahlungsarten zu zahlen, und schreibe keine Telefonnummern, E-Mail-Adressen oder Zahlungs-Handles in den Angebotstext.';

  @override
  String get hostAgreementClause6 =>
      'Behandle Gäste respektvoll: keine Diskriminierung, keine Belästigung, keine unsicheren Situationen.';

  @override
  String get hostAgreementClause7 =>
      'GreenGo kann Angebote ausblenden oder entfernen und Konten sperren, die gegen diese Regeln verstoßen oder glaubwürdig gemeldet werden.';

  @override
  String get hostAgreementCheckbox =>
      'Ich habe die Gastgebervereinbarung gelesen und akzeptiere sie';

  @override
  String get hostAgreementAccept => 'Akzeptieren und fortfahren';

  @override
  String get uexpConsentTitle => 'Bevor du zahlst';

  @override
  String get uexpConsentBodyLink =>
      'Du bezahlst den Gastgeber direkt. GreenGo wickelt diese Zahlung nicht ab, garantiert sie nicht und kann sie nicht erstatten. Nutze bevorzugt geschützte Zahlungsarten (PayPal Waren & Dienstleistungen, Kreditkarte). Zahle nie außerhalb des hier angezeigten Links.';

  @override
  String get uexpConsentBodyCash =>
      'Du bezahlst den Gastgeber beim Treffen in bar. GreenGo wickelt diese Zahlung nicht ab, garantiert sie nicht und kann sie nicht erstatten. Zähle das Geld, verlange bei Bedarf eine Quittung und zahle nie im Voraus außerhalb der hier aufgeführten Zahlungsarten.';

  @override
  String get uexpConsentPickMethod => 'Wie möchtest du zahlen?';

  @override
  String uexpConsentPolicy(String policy) {
    return 'Stornierungsrichtlinie: $policy';
  }

  @override
  String get uexpConsentUnderstand => 'Ich habe verstanden';

  @override
  String get uexpConsentContinue => 'Weiter';

  @override
  String get uexpGuidePix =>
      'PIX: Wenn du Opfer eines Betrugs wirst, bitte deine Bank sofort, einen MED-Antrag (Mecanismo Especial de Devolução) zu stellen.';

  @override
  String get uexpGuidePaypal =>
      'PayPal: Wähle „Waren & Dienstleistungen“, nie „Freunde & Familie“, damit der Käuferschutz gilt.';

  @override
  String get uexpGuideVenmo =>
      'Venmo: Nutze den Käuferschutz (Waren und Dienstleistungen), wenn verfügbar.';

  @override
  String get uexpGuideCard =>
      'Kartenzahlungen können bei deinem Kartenaussteller angefochten werden.';

  @override
  String get uexpGuideCash =>
      'Zahle erst beim Treffen mit dem Gastgeber, zählt das Geld gemeinsam und verlange bei Bedarf eine Quittung.';

  @override
  String get uexpPolicyFlexible => 'Flexibel';

  @override
  String get uexpPolicyModerate => 'Moderat';

  @override
  String get uexpPolicyStrict => 'Streng';

  @override
  String get uexpPolicyFlexibleDesc =>
      'Volle Erstattung bei Stornierung mindestens 24 Std. vor Beginn; danach keine Erstattung.';

  @override
  String get uexpPolicyModerateDesc =>
      'Volle Erstattung bei Stornierung mindestens 7 Tage vorher; 50 % bei mindestens 24 Std. vorher; danach keine Erstattung.';

  @override
  String get uexpPolicyStrictDesc =>
      'Volle Erstattung bei Stornierung mindestens 7 Tage vorher; danach keine Erstattung.';

  @override
  String get uexpPolicyWhen => 'Bei Stornierung';

  @override
  String get uexpPolicyRefund => 'Erstattung';

  @override
  String get uexpPolicyMoreThan7d => '7 Tage oder mehr vorher';

  @override
  String get uexpPolicy7dTo24h =>
      'Weniger als 7 Tage, aber mindestens 24 Std. vorher';

  @override
  String get uexpPolicyMoreThan24h => '24 Std. oder mehr vorher';

  @override
  String get uexpPolicyLess24h => 'Weniger als 24 Std. vorher';

  @override
  String get uexpPolicyLess7d => 'Weniger als 7 Tage vorher';

  @override
  String get uexpPolicyAlwaysTitle => 'Gilt immer';

  @override
  String get uexpRuleHostCancels => 'Der Gastgeber sagt ab: 100 % Erstattung.';

  @override
  String get uexpRuleGrace =>
      'Du stornierst innerhalb von 24 Std., nachdem der Gastgeber deine Buchung bestätigt hat, und das Erlebnis ist mehr als 48 Std. entfernt: 100 % Erstattung.';

  @override
  String get uexpRuleReport =>
      'Gastgeber nicht erschienen oder nicht wie beschrieben: Melde es innerhalb von 24 Std.';

  @override
  String get uexpPolicyNotes => 'Hinweise zu deiner Richtlinie (optional)';

  @override
  String get uexpPolicyHostNotes => 'Hinweise des Gastgebers';

  @override
  String get uexpReportScamTitle => 'Dieses Erlebnis melden';

  @override
  String get uexpReasonScam => 'Betrug';

  @override
  String get uexpReasonOffPlatform => 'Zahlung außerhalb der App verlangt';

  @override
  String get uexpReasonMisleading => 'Nicht wie beschrieben';

  @override
  String get uexpReasonNoShow => 'Gastgeber ist nicht erschienen';

  @override
  String get uexpReasonInappropriate => 'Unangemessen';

  @override
  String get uexpReasonOther => 'Sonstiges';

  @override
  String get uexpReportDetailsHint => 'Was ist passiert? (optional)';

  @override
  String get uexpReportSend => 'Meldung senden';

  @override
  String get bkStatusRequested => 'Angefragt';

  @override
  String get bkStatusConfirmed => 'Bestätigt';

  @override
  String get bkStatusDeclined => 'Abgelehnt';

  @override
  String get bkStatusExpired => 'Abgelaufen';

  @override
  String get bkStatusCancelledGuest => 'Vom Gast storniert';

  @override
  String get bkStatusCancelledHost => 'Vom Gastgeber storniert';

  @override
  String get bkStatusCompleted => 'Abgeschlossen';

  @override
  String get bkStatusNoShow => 'Nicht erschienen';

  @override
  String get bkStatusDisputed => 'Problem gemeldet';

  @override
  String get bkStatusResolved => 'Geklärt';

  @override
  String get bkStatusUnknown => 'Unbekannt';

  @override
  String get bkRequestToBook => 'Buchung anfragen';

  @override
  String get bkChooseDate => 'Datum wählen';

  @override
  String get bkNoDates => 'Noch keine Termine verfügbar.';

  @override
  String bkDatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Termine verfügbar',
      one: '1 Termin verfügbar',
    );
    return '$_temp0';
  }

  @override
  String bkSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Plätze frei',
      one: '1 Platz frei',
    );
    return '$_temp0';
  }

  @override
  String get bkFull => 'Ausgebucht';

  @override
  String get bkGuests => 'Gäste';

  @override
  String bkGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gäste',
      one: '1 Gast',
    );
    return '$_temp0';
  }

  @override
  String bkMaxGuests(int max) {
    return 'Bis zu $max an diesem Termin';
  }

  @override
  String get bkSummary => 'Übersicht';

  @override
  String get bkRequestInfo =>
      'Der Gastgeber hat bis zu 48 Std., um deine Anfrage anzunehmen. Vorher wird nichts bezahlt.';

  @override
  String get bkInstantInfo => 'Sofortbuchung: sofort bestätigt.';

  @override
  String get bkConfirmBooking => 'Buchung bestätigen';

  @override
  String get bkSendRequest => 'Anfrage senden';

  @override
  String get bkRetry => 'Erneut versuchen';

  @override
  String get bkResultConfirmedTitle => 'Du hast gebucht!';

  @override
  String get bkResultConfirmedBody =>
      'Zeige dem Gastgeber beim Treffen deinen Check-in-Code. Du findest ihn unter Meine Buchungen.';

  @override
  String get bkResultRequestTitle => 'Anfrage gesendet';

  @override
  String get bkResultRequestBody =>
      'Wir benachrichtigen dich, sobald der Gastgeber antwortet (innerhalb von 48 Std.).';

  @override
  String get bkViewBooking => 'Buchung ansehen';

  @override
  String get bkDone => 'Fertig';

  @override
  String get bkPayment => 'Zahlung';

  @override
  String get bkCashAtMeeting => 'Bezahle den Gastgeber beim Treffen in bar.';

  @override
  String get bkPayLinkHint =>
      'Bezahle den Gastgeber über seinen Link und tippe dann in deiner Buchung auf \"Als bezahlt markieren\".';

  @override
  String get bkPayAfterAccept =>
      'Du bezahlst über den Link des Gastgebers, sobald er deine Anfrage annimmt.';

  @override
  String get bkPayNow => 'Zahlungslink öffnen';

  @override
  String get bkCopyPixKey => 'PIX-Schlüssel kopieren';

  @override
  String get bkMyBookings => 'Meine Buchungen';

  @override
  String get bkHostBookings => 'Erhaltene Buchungen';

  @override
  String get bkUpcoming => 'Bevorstehend';

  @override
  String get bkPast => 'Vergangen';

  @override
  String get bkNoUpcoming => 'Keine bevorstehenden Buchungen.';

  @override
  String get bkNoPast => 'Keine vergangenen Buchungen.';

  @override
  String get bkBookings => 'Buchungen';

  @override
  String get bkViewBookings => 'Buchungen ansehen';

  @override
  String get bkDetailTitle => 'Buchung';

  @override
  String get bkNotFound => 'Diese Buchung ist nicht verfügbar.';

  @override
  String get bkExperienceGone => 'Dieses Erlebnis ist nicht mehr gelistet.';

  @override
  String get bkOpenExperience => 'Erlebnis öffnen';

  @override
  String get bkGuest => 'Gast';

  @override
  String get bkCheckedIn => 'Eingecheckt';

  @override
  String bkAnswerBefore(String date) {
    return 'Antworte bis $date';
  }

  @override
  String get bkWaitingForHost => 'Warten auf die Antwort des Gastgebers.';

  @override
  String get bkRequestTitle => 'Buchungsanfrage';

  @override
  String get bkRequestHostHint =>
      'Sieh dir Profil und Bewertung des Gastes an und nimm an oder lehne ab. Unbeantwortete Anfragen verfallen nach 48 Std.';

  @override
  String get bkAccept => 'Annehmen';

  @override
  String get bkDecline => 'Ablehnen';

  @override
  String get bkDeclineConfirm => 'Diese Anfrage ablehnen?';

  @override
  String get bkDeclineBody =>
      'Der Gast wird benachrichtigt und die Plätze werden freigegeben.';

  @override
  String get bkAccepted => 'Buchung angenommen';

  @override
  String get bkDeclined => 'Anfrage abgelehnt';

  @override
  String get bkCheckInTitle => 'Check-in';

  @override
  String get bkShowCode => 'Check-in-Code zeigen';

  @override
  String get bkCodeTitle => 'Dein Check-in-Code';

  @override
  String get bkCodeHint =>
      'Zeige diesen QR-Code dem Gastgeber beim Treffen. Er kann den Code auch eintippen.';

  @override
  String get bkCheckInGuest => 'Gast einchecken';

  @override
  String get bkScanQr => 'QR-Code scannen';

  @override
  String get bkTypeCode => 'Code eingeben';

  @override
  String get bkCodeLabel => 'Check-in-Code';

  @override
  String get bkScanInstructions =>
      'Richte die Kamera auf den QR-Code des Gastes';

  @override
  String get bkWrongBooking =>
      'Dieser QR-Code gehört zu einer anderen Buchung.';

  @override
  String get bkTorch => 'Blitz';

  @override
  String get bkSwitchCamera => 'Kamera wechseln';

  @override
  String get bkCashReceivedQuestion => 'Hast du auch die Barzahlung erhalten?';

  @override
  String get bkCashYes => 'Ja, erhalten';

  @override
  String get bkCashNo => 'Noch nicht';

  @override
  String get bkCheckedInSnack => 'Gast eingecheckt';

  @override
  String get bkMarkNoShow => 'Als nicht erschienen markieren';

  @override
  String get bkNoShowConfirm =>
      'Den Gast als nicht erschienen markieren? Es ist keine Erstattung fällig; er kann bis 24 Std. nach dem Ende widersprechen.';

  @override
  String get bkNoShowMarked => 'Als nicht erschienen markiert';

  @override
  String get bkNotPaidYet => 'Noch nicht als bezahlt markiert.';

  @override
  String get bkYouMarkedPaid =>
      'Du hast als bezahlt markiert. Warten auf die Bestätigung des Gastgebers.';

  @override
  String get bkGuestSaysPaid =>
      'Der Gast gibt an, bezahlt zu haben. Bestätige, sobald du es erhalten hast.';

  @override
  String get bkPaymentConfirmed => 'Zahlung vom Gastgeber bestätigt.';

  @override
  String get bkCashConfirmed => 'Bargeld erhalten (vom Gastgeber bestätigt).';

  @override
  String get bkMarkPaid => 'Als bezahlt markieren';

  @override
  String get bkConfirmPayment => 'Zahlung erhalten';

  @override
  String get bkCashReceived => 'Bargeld erhalten';

  @override
  String get bkPaidMarked => 'Als bezahlt markiert';

  @override
  String get bkPaymentConfirmedSnack => 'Zahlung bestätigt';

  @override
  String get bkRefundTitle => 'Erstattung';

  @override
  String bkRefundOwed(String percent, String amount) {
    return 'Der Gastgeber schuldet dir $percent zurück ($amount).';
  }

  @override
  String get bkRefundNone =>
      'Laut Stornobedingungen ist keine Erstattung fällig.';

  @override
  String get bkRefundCashUnpaid =>
      'Keine Erstattung fällig: Das Bargeld wurde nie bezahlt.';

  @override
  String get bkRefundOffPlatform =>
      'GreenGo wickelt kein Geld ab: Der Gastgeber erstattet direkt, auf dem Weg, auf dem du bezahlt hast.';

  @override
  String bkIfCancelNow(String percent, String amount) {
    return 'Wenn du jetzt stornierst: $percent zurück ($amount).';
  }

  @override
  String get bkIfCancelNowNothing =>
      'Wenn du jetzt stornierst, ist keine Erstattung fällig.';

  @override
  String get bkIfCancelNowCash =>
      'Bar wird beim Treffen bezahlt, eine Stornierung kostet jetzt also nichts.';

  @override
  String get bkIfCancelNowFree =>
      'Kostenloses Erlebnis: Du kannst kostenlos stornieren.';

  @override
  String get bkCancelRequestNoCharge =>
      'Der Gastgeber hat noch nicht angenommen: Die Anfrage zu stornieren kostet nichts.';

  @override
  String get bkHostCancelWarning =>
      'Du stornierst: Dem Gast stehen 100 % zu, und es zählt als Gastgeber-Stornierung (3 in 90 Tagen prüft GreenGo).';

  @override
  String get bkCancelBooking => 'Buchung stornieren';

  @override
  String get bkCancelConfirmTitle => 'Diese Buchung stornieren?';

  @override
  String get bkCancelReasonHint => 'Grund (optional)';

  @override
  String get bkKeepBooking => 'Buchung behalten';

  @override
  String get bkCancelled => 'Buchung storniert';

  @override
  String get bkReportProblem => 'Problem melden';

  @override
  String get bkDisputeIntro =>
      'Gastgeber nicht erschienen oder Erlebnis nicht wie beschrieben? Melde es bis 24 Std. nach dem Ende, unser Team prüft es.';

  @override
  String get bkDisputeHint => 'Was ist passiert? (mindestens 10 Zeichen)';

  @override
  String get bkSendReport => 'Meldung senden';

  @override
  String get bkDisputeSent =>
      'Danke. Unser Team prüft es und meldet sich bei euch beiden.';

  @override
  String get bkDisputeOpen =>
      'Ein Problem wurde gemeldet. Unser Team prüft es.';

  @override
  String bkDisputeResolved(String percent) {
    return 'Von GreenGo geprüft: $percent Erstattung fällig.';
  }

  @override
  String get bkReviewGuest => 'Gast bewerten';

  @override
  String get bkReviewGuestIntro =>
      'Hilf anderen Gastgebern: Wie war es mit diesem Gast? Beide Bewertungen bleiben verborgen, bis dein Gast ebenfalls bewertet oder 14 Tage vergehen.';

  @override
  String get bkReviewGuestHint =>
      'Pünktlich, respektvoll, unterhaltsam? (optional)';

  @override
  String get bkGuestReviewSaved =>
      'Danke! Die Bewertungen werden sichtbar, wenn dein Gast ebenfalls bewertet hat, oder in 14 Tagen.';

  @override
  String get bkGuestReviewed => 'Deine Bewertung dieses Gastes';

  @override
  String get bkGuestReviewHeld =>
      'Verborgen, bis dein Gast ebenfalls bewertet oder 14 Tage vergehen.';

  @override
  String get bkReviewExperience => 'Erlebnis bewerten';

  @override
  String get bkReviewExperienceHint =>
      'Erzähle, wie es war: Deine Bewertung hilft anderen Reisenden.';

  @override
  String get bkReviewHeld =>
      'Deine Bewertung wird veröffentlicht, wenn der Gastgeber dich ebenfalls bewertet hat, oder in 14 Tagen.';

  @override
  String get bkReviewNeedsBooking =>
      'Nur Gäste, die über eine Buchung teilgenommen haben, können dieses Erlebnis bewerten.';

  @override
  String get bkNewGuest => 'Neuer Gast';

  @override
  String get bkDatesTitle => 'Termine & Verfügbarkeit';

  @override
  String get bkAddDate => 'Termin hinzufügen';

  @override
  String get bkEditDate => 'Termin bearbeiten';

  @override
  String get bkDeleteDate => 'Termin löschen';

  @override
  String get bkCancelDate => 'Termin absagen';

  @override
  String get bkKeepDate => 'Termin behalten';

  @override
  String get bkCancelDateTitle => 'Diesen Termin absagen?';

  @override
  String bkCancelDateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle $count gebuchten Plätze an diesem Termin werden storniert, jedem Gast stehen 100 % Erstattung zu.',
      one:
          'Die Buchung an diesem Termin wird storniert, dem Gast stehen 100 % Erstattung zu.',
    );
    return '$_temp0 Das zählt als Gastgeber-Stornierung.';
  }

  @override
  String get bkDateSaved => 'Termin gespeichert';

  @override
  String get bkDateDeleted => 'Termin gelöscht';

  @override
  String bkDateCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Termin abgesagt: $count Buchungen storniert',
      one: 'Termin abgesagt: 1 Buchung storniert',
      zero: 'Termin abgesagt',
    );
    return '$_temp0';
  }

  @override
  String get bkNoDatesHost =>
      'Keine bevorstehenden Termine. Füge die Termine hinzu, die Gäste buchen können.';

  @override
  String get bkRequestToBookToggle => 'Buchung auf Anfrage';

  @override
  String get bkRequestToBookDesc =>
      'Du nimmst jede Buchung an oder lehnst sie ab (innerhalb von 48 Std.). Aus: Gäste buchen sofort.';

  @override
  String get bkDatesAfterSave =>
      'Speichere zuerst das Erlebnis und füge dann unter Meine Erlebnisse die Termine hinzu.';

  @override
  String get bkDate => 'Datum';

  @override
  String get bkStartTime => 'Beginn';

  @override
  String get bkEndTime => 'Ende';

  @override
  String get bkCapacity => 'Plätze';

  @override
  String bkBookedOf(int booked, int capacity) {
    return '$booked/$capacity gebucht';
  }

  @override
  String get bkSlotCancelled => 'Abgesagt';

  @override
  String get bkTimesFrozen =>
      'An diesem Termin sind Gäste gebucht: Nur die Anzahl der Plätze kann geändert werden. Zum Verschieben den Termin absagen.';

  @override
  String get bkSlotSaveFailed =>
      'Termin konnte nicht gespeichert werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get bkSlotErrPast => 'Wähle einen Beginn in der Zukunft.';

  @override
  String get bkSlotErrEnd => 'Das Ende muss nach dem Beginn liegen.';

  @override
  String get bkSlotErrTooLong => 'Ein Termin darf höchstens 24 Std. dauern.';

  @override
  String get bkSlotErrTooFar =>
      'Termine können höchstens ein Jahr im Voraus liegen.';

  @override
  String bkSlotErrCapacity(int max) {
    return 'Plätze: 1 bis $max.';
  }

  @override
  String bkSlotErrBelowBooked(int count) {
    return 'Bereits $count Plätze gebucht: Behalte mindestens so viele.';
  }

  @override
  String bkErrSlotFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nur noch $count Plätze an diesem Termin.',
      one: 'Nur noch 1 Platz an diesem Termin.',
      zero: 'Dieser Termin ist ausgebucht.',
    );
    return '$_temp0';
  }

  @override
  String get bkErrAlreadyBooked =>
      'Du hast für diesen Termin bereits eine Buchung.';

  @override
  String get bkErrIdRequired => 'Lade ein Ausweisdokument hoch, um zu buchen.';

  @override
  String get bkErrHostNotVerified =>
      'Dieser Gastgeber kann noch keine bezahlten Buchungen annehmen (Identität nicht verifiziert).';

  @override
  String get bkErrPaymentMethodRequired => 'Wähle, wie du bezahlst.';

  @override
  String get bkErrPaymentMethodNotAccepted =>
      'Der Gastgeber akzeptiert diese Zahlungsart nicht mehr. Wähle eine andere.';

  @override
  String get bkErrOwnExperience =>
      'Du kannst dein eigenes Erlebnis nicht buchen.';

  @override
  String get bkErrNotAvailable =>
      'Dieses Erlebnis ist für dich nicht verfügbar.';

  @override
  String get bkErrSlotStarted => 'Dieser Termin hat bereits begonnen.';

  @override
  String get bkErrSlotClosed => 'Dieser Termin ist nicht mehr verfügbar.';

  @override
  String get bkErrNotBookable =>
      'Dieses Erlebnis kann gerade nicht gebucht werden.';

  @override
  String get bkErrPriceInvalid =>
      'Der Preis dieses Angebots ist unvollständig. Bitte den Gastgeber, ihn zu aktualisieren.';

  @override
  String get bkErrHostUnavailable =>
      'Der Gastgeber nimmt gerade keine Buchungen an.';

  @override
  String get bkErrConsentRequired =>
      'Bitte akzeptiere zuerst die Buchungsbedingungen.';

  @override
  String bkErrTooManyGuests(int max) {
    return 'Höchstens $max Gäste pro Buchung.';
  }

  @override
  String get bkErrAccountRestricted =>
      'Dein Konto kann gerade keine Buchungen vornehmen.';

  @override
  String get bkErrNetwork =>
      'Verbindungsproblem. Versuche es erneut: Du wirst nicht doppelt gebucht.';

  @override
  String get bkErrRequestExpired => 'Diese Anfrage ist abgelaufen.';

  @override
  String get bkErrStateChanged =>
      'Diese Buchung hat sich inzwischen geändert. Zum Aktualisieren nach unten ziehen.';

  @override
  String get bkErrInvalidCode =>
      'Dieser Check-in-Code ist für diese Buchung nicht gültig.';

  @override
  String get bkErrOutsideCheckIn =>
      'Der Check-in öffnet 2 Std. vor Beginn und schließt 12 Std. nach dem Ende.';

  @override
  String get bkErrTooEarlyNoShow =>
      'Du kannst ab 30 Min. nach Beginn „nicht erschienen“ markieren.';

  @override
  String get bkErrGuestCheckedIn => 'Der Gast ist bereits eingecheckt.';

  @override
  String get bkErrCashBeforeMeeting =>
      'Bargeld kann bestätigt werden, sobald du den Gast triffst.';

  @override
  String get bkErrOutsideDispute =>
      'Probleme können ab Beginn bis 24 Std. nach dem Ende gemeldet werden.';

  @override
  String bkErrReasonRequired(int min) {
    return 'Beschreibe das Problem (mindestens $min Zeichen).';
  }

  @override
  String get uexpDatesRequiredHint =>
      'Gäste können nur die von dir festgelegten Termine buchen, und jede Buchung ist eine Anfrage, die du annimmst oder ablehnst. Füge mindestens einen kommenden Termin hinzu, um zu veröffentlichen.';

  @override
  String get uexpDatesRequiredToPublish =>
      'Füge mindestens einen kommenden Termin hinzu, um zu veröffentlichen. Dein Erlebnis ist als Entwurf gespeichert.';

  @override
  String bkRefundIfPaid(String percent, String amount) {
    return 'Wenn du bereits bezahlt hast, schuldet dir der Gastgeber $percent ($amount).';
  }

  @override
  String get shareLinkCopied => 'Link in die Zwischenablage kopiert';

  @override
  String shareOtherProfileMessage(String name, String link) {
    return 'Lerne $name auf GreenGo kennen: $link';
  }

  @override
  String get communitiesExperiencesEmpty => 'Noch keine Erlebnisse';

  @override
  String uexpPostedInCommunity(String community) {
    return 'Gepostet in $community';
  }

  @override
  String get uexpErrCommunityNotAllowed =>
      'Nur der Inhaber und die Admins dieser Community können hier Erlebnisse veröffentlichen.';

  @override
  String attrRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bewertungen',
      one: '1 Bewertung',
    );
    return '$_temp0';
  }

  @override
  String get attrNoRatingsYet => 'Noch keine Bewertungen';

  @override
  String get attrRateThis => 'Bewerte diese Sehenswürdigkeit';

  @override
  String get attrYourRating => 'Deine Bewertung';

  @override
  String get attrRatingRemove => 'Meine Bewertung entfernen';

  @override
  String get attrRatingFailed =>
      'Deine Bewertung konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get attrRatingGreengoLabel => 'GreenGo-Community';

  @override
  String get attrRatingGoogleLabel => 'Google-Bewertung';

  @override
  String get webUpdateAvailable =>
      'Eine neue Version von GreenGo ist verfügbar.';

  @override
  String get webUpdateRefresh => 'Aktualisieren';

  @override
  String get webUpdateLater => 'Später';

  @override
  String get userErrorTitle => 'Hoppla!';

  @override
  String get userErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get userErrorTimeout =>
      'Das dauert länger als erwartet. Bitte versuche es erneut.';

  @override
  String get userErrorPermissionDenied => 'Du hast keine Berechtigung dafür.';

  @override
  String get userErrorNotFound => 'Dieser Inhalt ist nicht mehr verfügbar.';

  @override
  String get userErrorTooManyRequests =>
      'Du machst das zu oft. Bitte warte einen Moment und versuche es erneut.';

  @override
  String get userErrorSessionExpired =>
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

  @override
  String get userErrorInvalidInput =>
      'Einige Angaben sind ungültig. Bitte überprüfe sie und versuche es erneut.';

  @override
  String get userErrorNotAllowed => 'Diese Aktion ist gerade nicht verfügbar.';

  @override
  String get userErrorUploadFailed =>
      'Der Upload ist fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String videoMaxDurationError(int seconds) {
    return 'Das Video darf höchstens $seconds Sekunden lang sein';
  }

  @override
  String get exploreLoadingContent => 'Wir suchen das Beste in deiner Nähe…';

  @override
  String get checkinWrongPlace =>
      'Dieser Code gehört zu einem anderen Event oder Erlebnis';

  @override
  String get checkinOutsideWindow => 'Der Check-in ist gerade nicht geöffnet';

  @override
  String get checkinNotConfirmed => 'Diese Person ist nicht bestätigt';

  @override
  String get checkinUpdateApp =>
      'Altes Ticket: Bitte GreenGo aktualisieren und den neuen Code zeigen';

  @override
  String get checkinNetwork => 'Keine Verbindung. Bitte erneut versuchen.';

  @override
  String get expDoorTitle => 'Gäste einchecken';

  @override
  String get expDoorInstructions => 'Scanne den Buchungs-QR-Code jedes Gastes';

  @override
  String expDoorCheckedInNow(int count) {
    return '$count eingecheckt';
  }

  @override
  String expDoorAdmits(int count) {
    return 'Einlass für $count Personen';
  }

  @override
  String get expDoorHelpers => 'Einlass-Helfer';

  @override
  String get expDoorHelpersHint =>
      'Mitglieder, die du hier hinzufügst, können Gäste dieses Erlebnisses einchecken.';

  @override
  String expDoorHelpersMax(int max) {
    return 'Höchstens $max Helfer';
  }

  @override
  String get expAttendanceTitle => 'Anwesenheit';

  @override
  String get expAttendanceEmpty =>
      'Noch keine bestätigten Gäste für kommende Termine.';

  @override
  String expAttendanceCount(int checked, int total) {
    return '$checked/$total da';
  }

  @override
  String get qrHubExperienceTicket => 'Erlebnis';

  @override
  String metInPersonOn(String date) {
    return 'Persönlich getroffen · $date';
  }

  @override
  String metInPersonTimes(int count, String date) {
    return '$count-mal persönlich getroffen · zuletzt $date';
  }

  @override
  String get paymentLinksTitle => 'Zahlungsmethoden';

  @override
  String get paymentLinksNone => 'Keine Zahlungsmethoden hinzugefügt';

  @override
  String paymentLinksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungsmethoden',
      one: '1 Zahlungsmethode',
    );
    return '$_temp0';
  }

  @override
  String get paymentLinksInfoTitle => 'Direkt bezahlt werden';

  @override
  String get paymentLinksInfoBody =>
      'Lass dich über deine eigenen Konten bezahlen. Das Geld geht direkt an dich: GreenGo verarbeitet diese Zahlungen nicht, hält sie nicht zurück und nimmt keine Gebühr.';

  @override
  String get paymentLinksHintHandle => 'Benutzername oder Link';

  @override
  String get paymentLinksHintPix =>
      'CPF, CNPJ, E-Mail, Telefon +55 oder Zufallsschlüssel';

  @override
  String get paymentLinksHintLink => 'Füge deinen Zahlungslink ein';

  @override
  String paymentLinkInvalid(String method) {
    return 'Ungültiger $method-Wert: bitte prüfen und erneut versuchen';
  }

  @override
  String get paymentLinksUpdated => 'Zahlungsmethoden aktualisiert';

  @override
  String get paymentLinksRules =>
      'Nur für Zahlungen zwischen Personen verwenden (Geschenke, Trinkgeld, persönliche Dienstleistungen und Touren). GreenGo-Münzen und Mitgliedschaften gibt es nur in der App.';

  @override
  String get paymentLinksSection => 'Direkt bezahlen';

  @override
  String paymentDisclaimerTitle(String name) {
    return '$name direkt bezahlen';
  }

  @override
  String paymentDisclaimerBody(String name, String method) {
    return 'Diese Zahlung geht von dir an $name über $method. GreenGo ist nicht beteiligt und kann sie weder erstatten, schützen noch prüfen. Bezahle nur Personen, denen du vertraust.';
  }

  @override
  String paymentContinueTo(String method) {
    return 'Weiter zu $method';
  }

  @override
  String get pixInstructions =>
      'Scanne den QR-Code oder kopiere den Pix-Code in deine Banking-App und gib dort den Betrag ein.';

  @override
  String get pixKeyLabel => 'Pix-Schlüssel';

  @override
  String get pixCopyCode => 'Pix-Code kopieren';

  @override
  String get pixCopyKey => 'Schlüssel kopieren';

  @override
  String get pixCopied =>
      'Kopiert: füge ihn im Pix-Bereich deiner Banking-App ein';

  @override
  String get bkRepeat => 'Wiederholen';

  @override
  String get bkRepeatHint =>
      'Diese Zeiten an mehreren Terminen auf einmal hinzufügen';

  @override
  String get bkRepeatThisDate => 'Diesen Termin wiederholen';

  @override
  String get bkRepeatDates => 'Auf Termine anwenden';

  @override
  String get bkRepeatPickRange => 'Wähle die Daten im Kalender';

  @override
  String get bkRepeatOnDays => 'An diesen Tagen';

  @override
  String get bkRepeatEveryDay => 'Jeden Tag';

  @override
  String bkRepeatPreview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Termine werden hinzugefügt',
      one: '1 Termin wird hinzugefügt',
      zero: 'Kein Datum passt — wähle einen längeren Zeitraum oder mehr Tage',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatCapped(int max) {
    return 'bis zu $max Termine auf einmal';
  }

  @override
  String bkRepeatAddButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Termine hinzufügen',
      one: '1 Termin hinzufügen',
      zero: 'Termine hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Termine hinzugefügt',
      one: '1 Termin hinzugefügt',
      zero: 'Keine neuen Termine hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gab es bereits',
      one: '1 gab es bereits',
    );
    return '$_temp0';
  }

  @override
  String get bkChooseTime => 'Uhrzeit wählen';

  @override
  String get bkNoFreeTimes => 'An diesem Termin sind keine Zeiten mehr frei';

  @override
  String bkTimesHint(String duration) {
    return 'Jede Zeit dauert $duration und gehört nur dir und deiner Gruppe.';
  }

  @override
  String bkWindowHint(String duration) {
    return 'Das ist deine verfügbare Zeit. Jeder Gast bucht darin seine eigene Zeit von $duration, und deine Buchungen überschneiden sich nie, über alle deine Erlebnisse hinweg.';
  }

  @override
  String bkWindowPeopleBooked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen gebucht',
      one: '1 Person gebucht',
      zero: 'Noch keine Buchungen',
    );
    return '$_temp0';
  }

  @override
  String get bkErrTimeTaken =>
      'Diese Zeit wurde gerade gebucht. Bitte wähle eine andere.';

  @override
  String get bkErrInvalidStart =>
      'Diese Zeit ist an diesem Termin nicht verfügbar.';

  @override
  String get coinsGiftPurchaseHold =>
      'Coins, die du in den letzten 72 Stunden gekauft hast, können noch nicht verschenkt werden. Du kannst sie aber für Funktionen ausgeben.';

  @override
  String get coinsGiftDailyLimit =>
      'Du hast dein heutiges Geschenklimit erreicht (10 Geschenke oder 5.000 Coins). Bitte versuche es morgen erneut.';

  @override
  String get coinReasonRefundClawback => 'Erstatteter Kauf zurückgebucht';

  @override
  String get chatMessageDeleted => 'Nachricht gelöscht';

  @override
  String get aiConsentTitle => 'KI-Funktionen nutzen Google-Dienste';

  @override
  String get aiConsentIntro =>
      'Antwortvorschläge, der KI-Sprachcoach, das Übersetzen empfangener Nachrichten und das Vorlesen funktionieren nur, wenn GreenGo den betreffenden Text an Google sendet.';

  @override
  String get aiConsentProviders =>
      'Wer: Google Gemini (Vorschläge und Coaching), Google Cloud Text-to-Speech (Audio) und Google Übersetzer (Übersetzungen).';

  @override
  String get aiConsentWhatSent =>
      'Was gesendet wird: nur der Text der Nachricht, auf die du die Funktion anwendest (auch Nachrichten, die andere dir geschickt haben), und die Sprachen. Nie dein Name, deine Fotos oder dein Profil.';

  @override
  String get aiConsentWhy =>
      'Warum: nur um den Vorschlag, die Übersetzung oder das Audio zu erstellen, das du angefordert hast.';

  @override
  String get aiConsentDeclineInfo =>
      'Wenn du ablehnst, bleiben diese Funktionen aus und es wird nichts gesendet. Tippe später auf eine davon, um deine Wahl zu ändern.';

  @override
  String get aiConsentAccept => 'Erlauben';

  @override
  String get aiConsentDecline => 'Ablehnen';

  @override
  String get aiConsentDisabledNotice =>
      'Diese Funktion ist aus, weil du keinen Text an Google-KI-Dienste senden möchtest.';

  @override
  String get aiConsentReview => 'Ändern';

  @override
  String get profileDeleteReauthRequired =>
      'Bitte bestätige zu deiner Sicherheit erneut dein Passwort, um dein Konto zu löschen.';

  @override
  String get profileDeleteNetworkError =>
      'Keine Verbindung. Dein Konto wurde nicht gelöscht. Bitte versuche es erneut.';

  @override
  String get profileDeleteFailed =>
      'Wir konnten dein Konto nicht löschen, es wurde nichts gelöscht. Bitte versuche es erneut oder kontaktiere den Support.';

  @override
  String get onboardingAgeBlockedTitle => 'GreenGo ist für Erwachsene';

  @override
  String get onboardingAgeBlockedBody =>
      'Du musst mindestens 18 Jahre alt sein, um GreenGo zu nutzen. Daher können wir dein Konto nicht erstellen.';

  @override
  String get distanceBucketUnder2Km => 'unter 2 km';

  @override
  String get distanceBucket2To5Km => '2-5 km';

  @override
  String get distanceBucket5To10Km => '5-10 km';

  @override
  String get distanceBucket10To25Km => '10-25 km';

  @override
  String get distanceBucketOver25Km => 'über 25 km';

  @override
  String distanceUnderKm(String km) {
    return '< $km km';
  }

  @override
  String distanceOverKm(String km) {
    return '$km+ km';
  }

  @override
  String get idConsentTitle => 'Bevor du deinen Ausweis hochlädst';

  @override
  String get idConsentWhat =>
      'Was wir verarbeiten: ein Foto deines Ausweisdokuments. Geburtsdatum und Dokumentnummer lesen wir automatisch aus (OCR).';

  @override
  String get idConsentWho =>
      'Wer es verarbeitet: GreenGo mit Google Cloud Vision (Google ist unser Auftragsverarbeiter).';

  @override
  String get idConsentRetention =>
      'Wie lange: Das Bild wird gelöscht, sobald eine Entscheidung gefallen ist, automatisch oder durch eine prüfende Person. Muss eine Person es prüfen, bleibt es höchstens 7 Tage gespeichert und wird dann gelöscht; du wirst dann gebeten, es erneut hochzuladen.';

  @override
  String get idConsentKept =>
      'Was wir behalten: nur, ob du verifiziert bist, wie, das Entscheidungsdatum, dein Geburtsjahr und einen verschlüsselten Einweg-Fingerabdruck der Dokumentnummer, damit ein Dokument nicht viele Konten verifizieren kann.';

  @override
  String get idConsentAccess =>
      'Wer es sehen kann: keine anderen Nutzer. Nur die automatische Verarbeitung und, falls nötig, wenige autorisierte GreenGo-Prüfer.';

  @override
  String get idConsentAccept => 'Einverstanden, weiter';

  @override
  String get idConsentRecordError =>
      'Wir konnten deine Einwilligung nicht speichern, daher wurde nichts hochgeladen. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get ageVerifyRejectedExpired =>
      'Dein Dokument konnte nicht rechtzeitig geprüft werden und wurde gelöscht. Bitte lade es erneut hoch.';

  @override
  String get analyticsConsentTitle => 'Hilf uns, GreenGo zu verbessern';

  @override
  String get analyticsConsentBody =>
      'Mit deiner Erlaubnis nutzen wir Google Firebase Analytics, Crashlytics und Performance Monitoring, um zu verstehen, wie die App genutzt wird, und Abstürze zu beheben. Dabei werden Kennungen auf deinem Gerät gespeichert und gelesen. Ohne deine Erlaubnis wird nichts erfasst. Du kannst das jederzeit unter Einstellungen > Datenschutz & Daten ändern.';

  @override
  String get analyticsConsentAllow => 'Erlauben';

  @override
  String get analyticsConsentDecline => 'Ablehnen';

  @override
  String get privacySettingsTitle => 'Datenschutz & Daten';

  @override
  String get privacySettingsSubtitle =>
      'Analysen, Absturzberichte und Marketing-E-Mails';

  @override
  String get privacyAnalyticsToggle => 'Nutzungsanalyse & Absturzberichte';

  @override
  String get privacyAnalyticsToggleSubtitle =>
      'Teile Nutzungsstatistiken und Absturzberichte mit uns (Google Firebase), um die App zu verbessern.';

  @override
  String get privacyMarketingEmailToggle =>
      'Neuigkeiten und Angebote per E-Mail';

  @override
  String get privacyMarketingEmailSubtitle =>
      'Gelegentliche E-Mails zu neuen Funktionen, Tipps, Aktivitätsübersichten und Angeboten. Du kannst dich jederzeit abmelden.';

  @override
  String get privacySettingsSaveError =>
      'Deine Auswahl konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get notificationCatMarketing => 'Marketing & Aktionen';

  @override
  String get notificationCatMarketingSubtitle =>
      'Neuigkeiten, Angebote und Ankündigungen von GreenGo. Aus, bis du es einschaltest.';

  @override
  String get signupMarketingEmailConsent =>
      'Schickt mir Neuigkeiten und Angebote per E-Mail';

  @override
  String get signupMarketingEmailConsentSubtitle =>
      'Optional. Du kannst dich jederzeit abmelden.';

  @override
  String get moderationDecisionTitle => 'Moderationsentscheidung';

  @override
  String get moderationDecisionIntro =>
      'Unser Team hat gemäß unseren Community-Richtlinien eine Maßnahme zu deinem Konto oder Inhalt ergriffen. Hier ist die Begründung.';

  @override
  String get moderationDecisionActionLabel => 'Ergriffene Maßnahme';

  @override
  String get moderationDecisionReasonLabel => 'Grund';

  @override
  String get moderationDecisionExplanationLabel => 'Erklärung unseres Teams';

  @override
  String moderationDecisionAppealUntil(String date) {
    return 'Du kannst bis $date Einspruch einlegen.';
  }

  @override
  String get moderationDecisionAppealButton => 'Einspruch einlegen';

  @override
  String get moderationDecisionAppealHint =>
      'Erkläre, warum du die Entscheidung für falsch hältst (mindestens 10 Zeichen).';

  @override
  String get moderationDecisionAppealSubmit => 'Einspruch senden';

  @override
  String get moderationDecisionAppealSent =>
      'Dein Einspruch wurde gesendet. Unser Team prüft ihn erneut und informiert dich.';

  @override
  String get moderationDecisionAppealAlready =>
      'Du hast gegen diese Entscheidung bereits Einspruch eingelegt.';

  @override
  String get moderationDecisionAppealClosed =>
      'Gegen diese Entscheidung ist kein Einspruch mehr möglich.';

  @override
  String get moderationDecisionAppealError =>
      'Dein Einspruch konnte nicht gesendet werden. Bitte versuche es erneut.';

  @override
  String get moderationDecisionAppealTooShort =>
      'Bitte schreibe mindestens 10 Zeichen.';

  @override
  String get moderationDecisionNotAppealable =>
      'Gegen diese Entscheidung kann in der App kein Einspruch eingelegt werden. Wende dich an den Support, wenn du sie für falsch hältst.';

  @override
  String get moderationActionRemoveContent => 'Inhalt entfernt';

  @override
  String get moderationActionWarning => 'Verwarnung erteilt';

  @override
  String get moderationActionSuspend => 'Konto vorübergehend gesperrt';

  @override
  String get moderationActionBan => 'Konto gesperrt';

  @override
  String get moderationActionShadowBan =>
      'Eingeschränkte Sichtbarkeit deines Profils';

  @override
  String get moderationActionRequireVerification =>
      'Identitätsprüfung erforderlich';

  @override
  String get moderationActionOther => 'Einschränkung angewendet';

  @override
  String get moderationReasonCsae =>
      'Sexuelle Ausbeutung oder Missbrauch von Kindern';

  @override
  String get moderationReasonUnderage => 'Minderjähriger Benutzer';

  @override
  String get moderationReasonSexualContent => 'Sexuelle Inhalte';

  @override
  String get moderationReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get moderationReasonThreats => 'Drohungen';

  @override
  String get moderationReasonViolence => 'Gewalt';

  @override
  String get moderationReasonHarassment => 'Belästigung oder Mobbing';

  @override
  String get moderationReasonHate => 'Hassrede';

  @override
  String get moderationReasonSpam => 'Spam';

  @override
  String get moderationReasonScam => 'Betrug';

  @override
  String get moderationReasonImpersonation =>
      'Identitätsbetrug oder falsches Profil';

  @override
  String get moderationReasonPrivacy => 'Teilen persönlicher Informationen';

  @override
  String get moderationReasonMisleading => 'Irreführender Inhalt';

  @override
  String get moderationReasonNoShow => 'Nicht zu einer Buchung erschienen';

  @override
  String get moderationReasonOffPlatformPayment =>
      'Zahlung außerhalb der Plattform';

  @override
  String get moderationReasonOther =>
      'Sonstiger Verstoß gegen unsere Community-Richtlinien';

  @override
  String get checkoutConsentTitle => 'Vor der Zahlung';

  @override
  String get checkoutCoinWaiverCheckbox =>
      'Ich stimme zu, dass die Coins sofort geliefert werden, und ich nehme zur Kenntnis, dass ich mein Widerrufsrecht verliere, sobald die Lieferung beginnt.';

  @override
  String get checkoutMembershipWithdrawalInfo =>
      'Widerrufsrecht: Du kannst diese Mitgliedschaft innerhalb von 14 Tagen nach dem Kauf (7 Tage bei Käufen in Brasilien) ohne Angabe von Gründen widerrufen und erhältst den vollen Betrag zurück, über „Vertrag widerrufen“ im Shop oder auf unserer Website. Die Mitgliedschaft verlängert sich automatisch, bis du kündigst; du kannst jederzeit im Abrechnungsportal kündigen.';

  @override
  String get checkoutContinueToPayment => 'Weiter zur Zahlung';

  @override
  String get withdrawFromContract => 'Vertrag widerrufen';

  @override
  String get withdrawalDialogIntro =>
      'Wähle den Kauf, den du widerrufen möchtest. Wir senden einen Bestätigungslink an die beim Kauf verwendete E-Mail-Adresse; erst nach deiner Bestätigung wird etwas storniert oder erstattet.';

  @override
  String get withdrawalNothingEligible =>
      'Keiner deiner Web-Käufe kann derzeit widerrufen werden. Mitgliedschaften können innerhalb von 14 Tagen nach dem Kauf widerrufen werden (7 Tage in Brasilien); Coin-Käufe nur, wenn beim Kauf nicht auf das Widerrufsrecht verzichtet wurde.';

  @override
  String withdrawalDeadline(String date) {
    return 'Widerruf bis $date';
  }

  @override
  String get withdrawalRequestSent =>
      'Prüfe deine E-Mails und bestätige den Widerruf über den gesendeten Link.';

  @override
  String get withdrawalRequestFailed =>
      'Der Widerruf konnte nicht gesendet werden. Bitte versuche es erneut oder schreibe an support@greengochat.com.';

  @override
  String webSubscriptionRenewsOn(
      String plan, String price, String interval, String date) {
    return '$plan: $price pro $interval. Verlängert sich automatisch am $date.';
  }

  @override
  String webSubscriptionEndsOn(
      String plan, String price, String interval, String date) {
    return '$plan: $price pro $interval. Gekündigt; Zugang endet am $date.';
  }

  @override
  String get billingIntervalMonth => 'Monat';

  @override
  String get billingIntervalYear => 'Jahr';

  @override
  String get cancelAnytimeBillingPortal =>
      'Jederzeit im Abrechnungsportal kündigen';

  @override
  String get billingPortalOpenFailed =>
      'Das Abrechnungsportal konnte nicht geöffnet werden. Bitte versuche es erneut.';

  @override
  String get subscriptionAutoRenewInfoWeb =>
      'Abos verlängern sich automatisch zum angezeigten Preis und Intervall, bis du kündigst. Jederzeit im Abrechnungsportal kündbar.';

  @override
  String get webBillingTitle => 'Abrechnung und Widerruf';

  @override
  String get ageAssuranceTitle =>
      'Bestätige dein Alter, um diese Funktion zu nutzen';

  @override
  String get ageAssuranceBody =>
      'An deinem Wohnort verlangt das Gesetz, dass wir bestätigen, dass du volljährig bist, bevor du Menschen entdecken oder neue private Unterhaltungen beginnen kannst. Der Rest von GreenGo funktioniert wie gewohnt.';

  @override
  String get ageAssuranceExistingChats =>
      'Unterhaltungen, an denen du bereits teilgenommen hast, bleiben verfügbar.';

  @override
  String get ageAssuranceStoreCheckAndroid => 'Mit Google Play bestätigen';

  @override
  String get ageAssuranceStoreCheckIos => 'Mit dem App Store bestätigen';

  @override
  String get ageAssuranceStoreHint =>
      'Verwendet das Alter, das dein Store-Konto bereits bestätigt hat. Wir erhalten nur eine Altersspanne, nie dein Geburtsdatum.';

  @override
  String get ageAssuranceIdOption => 'Mit einem Ausweisdokument bestätigen';

  @override
  String get ageAssuranceStoreUnavailable =>
      'Dein Store-Konto konnte dein Alter nicht bestätigen. Bitte bestätige es stattdessen mit einem Ausweisdokument.';

  @override
  String get ageAssuranceVerified => 'Danke, dein Alter ist bestätigt.';

  @override
  String get ageAssuranceWebNote =>
      'Im Web wird dein Alter mit einem Ausweisdokument bestätigt.';

  @override
  String get ageVerifyWhyRegional =>
      'Um an deinem Wohnort Menschen zu entdecken und neue private Chats zu beginnen, müssen wir bestätigen, dass du über 18 bist.';

  @override
  String get privacyDownloadDataTitle => 'Meine Daten herunterladen';

  @override
  String get privacyDownloadDataSubtitle =>
      'Eine Kopie deines Profils, deiner Einstellungen, Fotos und der Nachrichten, die du gesendet hast (ZIP-Datei)';

  @override
  String get privacyDownloadDataConfirmBody =>
      'Wir erstellen eine ZIP-Datei mit den Daten, die wir über dich speichern. Zum Schutz anderer Personen sind Nachrichten, die sie dir geschickt haben, nicht enthalten. Du erhältst hier und per E-Mail einen Download-Link. Der Link ist 24 Stunden gültig, und du kannst eine Kopie pro Tag anfordern.';

  @override
  String get privacyDownloadDataConfirmButton => 'Meine Daten vorbereiten';

  @override
  String get privacyDownloadDataPreparing =>
      'Deine Daten werden vorbereitet. Das kann einige Minuten dauern...';

  @override
  String get privacyDownloadDataReadyTitle => 'Deine Daten sind bereit';

  @override
  String get privacyDownloadDataReadyBody =>
      'Lade die ZIP-Datei jetzt herunter. Der Link ist 24 Stunden gültig.';

  @override
  String get privacyDownloadDataReadyEmailed =>
      'Wir haben dir den Link auch per E-Mail geschickt.';

  @override
  String get privacyDownloadDataOpen => 'Herunterladen';

  @override
  String get privacyDownloadDataRateLimited =>
      'Du kannst deine Daten einmal alle 24 Stunden herunterladen. Nutze den Link aus unserer E-Mail oder versuche es morgen erneut.';

  @override
  String get privacyDownloadDataInProgress =>
      'Deine Daten werden bereits vorbereitet. Bitte warte einige Minuten.';

  @override
  String get privacyDownloadDataFailed =>
      'Wir konnten deine Daten nicht vorbereiten. Bitte versuche es später erneut.';

  @override
  String get reauthPasswordBody =>
      'Gib zu deiner Sicherheit dein Passwort erneut ein, um fortzufahren.';

  @override
  String get reauthContinue => 'Weiter';

  @override
  String get reauthSignInAgain =>
      'Melde dich zu deiner Sicherheit ab und wieder an und versuche es dann erneut.';

  @override
  String get profilePhotoPrevious => 'Vorheriges Foto';

  @override
  String get profilePhotoNext => 'Nächstes Foto';

  @override
  String get aiServicesTitle => 'KI-Dienste';

  @override
  String get aiServicesSubtitleOn =>
      'An: KI-Funktionen dürfen den Text, für den du sie nutzt, an Google senden.';

  @override
  String get aiServicesSubtitleOff =>
      'Aus: Es wird kein Text an KI-Dienste gesendet.';

  @override
  String get aiServicesWhatsIncluded => 'Was dieser Schalter umfasst';

  @override
  String get aiServicesFeatureCoach =>
      'Antwortvorschläge und der KI-Sprachcoach (Grammatik, Wortanalyse, kulturelle Hinweise)';

  @override
  String get aiServicesFeatureTranslate =>
      'Übersetzen von Chatnachrichten, die du erhältst';

  @override
  String get aiServicesFeatureReadAloud => 'Vorlese-Audio und Aussprache';

  @override
  String get aiServicesFeatureSupport =>
      'Automatische Antworten des Support-Assistenten (wenn aus, antwortet dir ein Mensch)';

  @override
  String get aiServicesSafetyNote =>
      'Die Sicherheitsprüfung von Fotos und Nachrichten bleibt immer aktiv: Sie schützt alle und kann nicht deaktiviert werden.';

  @override
  String get aiServicesTurnedOff =>
      'KI-Dienste deaktiviert. Deine Entscheidung wurde gespeichert.';

  @override
  String get aiServicesTurnedOn =>
      'KI-Dienste aktiviert. Deine Entscheidung wurde gespeichert.';

  @override
  String get aiServicesSyncPending =>
      'Auf diesem Gerät gespeichert. Sobald du online bist, wird es auf unseren Servern erfasst.';

  @override
  String get tpAddTicketType => 'Ticketart hinzufügen';

  @override
  String get tpAdviceLarge =>
      'Viele Teilnehmende erwartet: Sofortbestätigung empfohlen. Tickets werden automatisch bestätigt, du musst nicht jede Zahlung prüfen.';

  @override
  String get tpAdviceSmall =>
      'Kleine Gruppe: Am einfachsten ist ein Zahlungslink – ohne Einrichtung, du bestätigst jede Zahlung mit einem Tipp.';

  @override
  String get tpAmountLabel => 'Betrag';

  @override
  String get tpAttachReceipt => 'Beleg anhängen (optional)';

  @override
  String get tpAwaitingOrganizerInfo =>
      'Du hast dem Veranstalter die Zahlung gemeldet. Dein Ticket erscheint hier, sobald er bestätigt.';

  @override
  String get tpBadgeBrazil => 'Empfohlen in Brasilien';

  @override
  String get tpBadgeNoSetup => 'Ohne Einrichtung';

  @override
  String get tpBadgeRecommended => 'Empfohlen';

  @override
  String get tpBankInstructionsLabel => 'Bankdaten und Hinweise';

  @override
  String tpBlockMinimum(String provider, String amount) {
    return '$provider verlangt mindestens $amount pro Ticket.';
  }

  @override
  String tpBlockMpCurrency(String currency) {
    return 'Mercado Pago rechnet nur in $currency ab: Preis auf $currency ändern oder Stripe nutzen.';
  }

  @override
  String get tpBlockMpCurrencyUnknown =>
      'Mercado Pago rechnet nur in der Landeswährung deines Kontos ab. Nutze diese Währung oder Stripe.';

  @override
  String get tpBlockNotConfigured => 'Noch nicht verfügbar.';

  @override
  String tpBlockNotConnected(String provider) {
    return 'Verbinde $provider, um es zu nutzen.';
  }

  @override
  String get tpBuyMoreTickets => 'Weitere Tickets kaufen';

  @override
  String get tpBuyTickets => 'Tickets kaufen';

  @override
  String tpCanBuyMore(int count) {
    return 'Du kannst noch $count Tickets kaufen';
  }

  @override
  String get tpCanBuyUnlimited => 'Kein Limit pro Person';

  @override
  String get tpCancelOrder => 'Abbrechen';

  @override
  String get tpCashInstructionsLabel => 'Wo und wann bar zahlen (optional)';

  @override
  String get tpChooseHowToGetPaid =>
      'Wähle, wie Käufer für dieses kostenpflichtige Angebot bezahlen.';

  @override
  String get tpClose => 'Schließen';

  @override
  String get tpCodeHint =>
      'Gib diesen Code im Verwendungszweck an, damit der Veranstalter deine Zahlung findet.';

  @override
  String get tpCodeLabel => 'Zahlungscode';

  @override
  String get tpConfirm => 'Bestätigen';

  @override
  String tpConfirmSelected(int count) {
    return 'Auswahl bestätigen ($count)';
  }

  @override
  String tpConfirmedCount(int count) {
    return '$count Zahlungen bestätigt';
  }

  @override
  String tpConnectProvider(String provider) {
    return '$provider verbinden';
  }

  @override
  String get tpConsentGuideInstant =>
      'Du zahlst in der App über einen sicheren Checkout. Ticket und QR erscheinen, sobald die Zahlung bestätigt ist. Erstattungen erfolgen durch den Veranstalter.';

  @override
  String get tpConsentGuideManual =>
      'Du zahlst direkt an den Gastgeber mit dessen Zahlungsmethode und einem Code. GreenGo prüft die Zahlung nicht: Der Gastgeber bestätigt sie, dann erscheint dein QR.';

  @override
  String get tpContinueSetup => 'Einrichtung fortsetzen';

  @override
  String tpContinueToPay(String amount) {
    return 'Weiter · $amount';
  }

  @override
  String get tpCopied => 'Kopiert';

  @override
  String get tpCopy => 'Kopieren';

  @override
  String get tpEditTicketType => 'Ticketart bearbeiten';

  @override
  String get tpErrAlreadyHasTicket => 'Du hast dafür bereits ein Ticket.';

  @override
  String get tpErrEnded => 'Der Verkauf ist beendet.';

  @override
  String get tpErrGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get tpErrLimit => 'Du hast das Ticketlimit pro Person erreicht.';

  @override
  String get tpErrMinimum =>
      'Der Preis liegt unter dem Minimum des Zahlungsanbieters.';

  @override
  String get tpErrNotAllowed => 'Das ist dir nicht erlaubt.';

  @override
  String get tpErrNotOnSale =>
      'Tickets sind noch nicht im Verkauf: Der Veranstalter hat die Zahlung noch nicht eingerichtet.';

  @override
  String get tpErrOwnListing =>
      'Du kannst keine Tickets für dein eigenes Angebot kaufen.';

  @override
  String get tpErrProvider =>
      'Der Zahlungsanbieter antwortet nicht. Versuche es gleich noch einmal.';

  @override
  String get tpErrSoldOut => 'Ausverkauft – nicht genug Plätze frei.';

  @override
  String get tpFree => 'Kostenlos';

  @override
  String get tpGetPaidIntro =>
      'Das Geld geht direkt auf dein eigenes Konto. GreenGo nimmt keine Gebühr auf Ticketverkäufe.';

  @override
  String get tpGetPaidSubtitle =>
      'Zahlungsmethoden, Stripe und Mercado Pago, zu bestätigende Zahlungen';

  @override
  String get tpGetPaidTitle => 'Bezahlt werden';

  @override
  String tpGroupOf(int count) {
    return 'Gruppe mit $count Personen';
  }

  @override
  String tpGroupPreview(String price, int size) {
    return '$price für eine Gruppe von bis zu $size';
  }

  @override
  String get tpGroupPrice => 'Preis pro Gruppe';

  @override
  String tpHoldCountdown(String time) {
    return 'Dein Platz ist noch $time reserviert';
  }

  @override
  String get tpInstantOptional => 'Sofortbestätigung (optional)';

  @override
  String get tpInstantSubtitle =>
      'Käufer zahlen in der App; Tickets werden automatisch bestätigt.';

  @override
  String get tpInstantTitle => 'Sofortbestätigung';

  @override
  String get tpIvePaid => 'Ich habe bezahlt';

  @override
  String get tpLegacyPaymentPrompt =>
      'Dieses Angebot nutzte eine alte Zahlungsmethode. Wähle, wie Gäste zahlen, um weiter zu verkaufen.';

  @override
  String get tpManualAddMethodsHint =>
      'Füge Pix, PayPal… unter Profil > Unternehmen > Bezahlt werden hinzu, um sie hier zu sehen.';

  @override
  String get tpManualDisclaimer =>
      'GreenGo prüft diese Zahlungen nicht: Der Veranstalter ist für die Bestätigung verantwortlich.';

  @override
  String tpManualLargeWarning(String count) {
    return 'Bei $count Personen musst du jede Zahlung von Hand bestätigen.';
  }

  @override
  String get tpManualMethodLabel => 'Zahlungsmethode';

  @override
  String get tpManualSubtitle =>
      'Deine eigene Zahlungsmethode; du bestätigst jede Zahlung mit einem Tipp.';

  @override
  String get tpManualTitle => 'Zahlungslink – du bestätigst';

  @override
  String get tpMaxGroupBookingsPerUser => 'Max. Gruppenbuchungen pro Person';

  @override
  String get tpMaxTicketsPerUser => 'Max. Tickets pro Person';

  @override
  String get tpMethodBankTransfer => 'Banküberweisung';

  @override
  String get tpMethodCash => 'Bar (vor dem Event)';

  @override
  String tpMpCurrencyInfo(String currency) {
    return 'Abrechnung in $currency';
  }

  @override
  String get tpMpDescription =>
      'Pix, Karten und Mercado-Pago-Guthaben. Käufer brauchen kein Mercado-Pago-Konto.';

  @override
  String get tpMyPurchases => 'Meine Käufe';

  @override
  String get tpNoFeeNote =>
      'GreenGo nimmt keine Gebühr: Das Geld geht direkt an dich.';

  @override
  String get tpNoLimitHint => 'Leer = kein Limit';

  @override
  String get tpNoPurchases => 'Noch keine Käufe.';

  @override
  String get tpNotOnSaleYet => 'Noch nicht im Verkauf';

  @override
  String get tpOpenPaymentLink => 'Zahlungslink öffnen';

  @override
  String get tpOpenProviderSettings => 'Kontodaten aktualisieren';

  @override
  String get tpOrderAwaitingConfirmation =>
      'Warten auf die Bestätigung des Veranstalters…';

  @override
  String get tpOrderCancelled => 'Bestellung storniert';

  @override
  String get tpOrderClosedInfo =>
      'Diese Bestellung ist abgeschlossen. Du kannst über das Event oder Erlebnis neu kaufen.';

  @override
  String get tpOrderDisputed => 'Zahlung angefochten – Ticket ungültig';

  @override
  String get tpOrderExpired => 'Reservierung abgelaufen';

  @override
  String get tpOrderFailed => 'Zahlung fehlgeschlagen';

  @override
  String get tpOrderPaid => 'Bezahlt';

  @override
  String get tpOrderPendingPayment => 'Warten auf deine Zahlung';

  @override
  String get tpOrderRefunded => 'Erstattet – Ticket nicht mehr gültig';

  @override
  String get tpOrderRejected =>
      'Der Veranstalter hat deine Zahlung nicht bestätigt';

  @override
  String get tpOrderTitle => 'Deine Tickets';

  @override
  String get tpOrderWaitingProvider => 'Warten auf die Zahlungsbestätigung…';

  @override
  String get tpPayAgain => 'Erneut bezahlen';

  @override
  String get tpPayInApp => 'In der App bezahlen';

  @override
  String get tpPayInAppInfo =>
      'Bezahle in der App, sobald der Gastgeber annimmt; dein QR erscheint nach der Bestätigung.';

  @override
  String get tpPayNow => 'Jetzt bezahlen';

  @override
  String tpPayWith(String method) {
    return 'Mit $method bezahlen';
  }

  @override
  String get tpPaymentConfirmed =>
      'Zahlung bestätigt – deine Tickets sind bereit';

  @override
  String get tpPerGroup => 'Pro Gruppe';

  @override
  String get tpPerGroupInfo =>
      'Ein Festpreis pro Gruppe (z. B. Privattour), egal wie groß bis zum Maximum.';

  @override
  String get tpPerPerson => 'Pro Person';

  @override
  String get tpPerPersonInfo =>
      'Jede Person zahlt den Preis; ein Ticket pro Person.';

  @override
  String get tpPixHint =>
      'Mit Pix bezahlt? Die Bestätigung dauert meist nur Sekunden.';

  @override
  String get tpReceiptAttached => 'Beleg angehängt';

  @override
  String get tpReconnectBanner =>
      'Verbinde Mercado Pago / Stripe, um Tickets mit automatischer Bestätigung zu verkaufen. Eingefügte Stripe- oder Mercado-Pago-Links gehen nicht für Tickets.';

  @override
  String get tpRefresh => 'Aktualisieren';

  @override
  String get tpReject => 'Nicht erhalten';

  @override
  String get tpRejectReason => 'Grund (wird dem Käufer angezeigt)';

  @override
  String get tpRejectTitle => 'Zahlung nicht erhalten?';

  @override
  String get tpSalesEnd => 'Verkaufsende';

  @override
  String get tpSalesStart => 'Verkaufsstart';

  @override
  String get tpSave => 'Speichern';

  @override
  String get tpScanNotPaid => 'Nicht bezahlt – kein gültiges Ticket';

  @override
  String get tpScanTicketNotValid =>
      'Ticket erstattet oder storniert – ungültig';

  @override
  String get tpSelectorTitle => 'Wie zahlen die Gäste?';

  @override
  String get tpShareTicket => 'Dieses Ticket teilen';

  @override
  String tpShareTicketText(String title, int index, int total) {
    return 'Ticket $index/$total für $title auf GreenGo. Zeige diesen QR am Eingang (einmal gültig).';
  }

  @override
  String get tpStatusNotConnected => 'Nicht verbunden';

  @override
  String get tpStatusPending => 'Prüfung ausstehend';

  @override
  String get tpStatusReady => 'Bereit';

  @override
  String get tpStatusReconnect => 'Neu verbinden';

  @override
  String get tpStopSelling => 'Verkauf stoppen';

  @override
  String get tpStripeDescription =>
      'Karten, Apple Pay und Google Pay weltweit. Käufer brauchen kein Konto.';

  @override
  String tpTicketIndex(int index, int total) {
    return 'Ticket $index von $total';
  }

  @override
  String get tpTicketInvalid => 'Dieses Ticket ist nicht mehr gültig.';

  @override
  String get tpTicketTypes => 'Ticketarten';

  @override
  String get tpTicketTypesEmpty =>
      'Keine Ticketarten: Der Eventpreis ist das einzige Ticket. Füge Arten wie VIP oder Frühbucher hinzu.';

  @override
  String get tpTicketUsed => 'Bereits am Eingang verwendet';

  @override
  String tpTicketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tickets',
      one: '1 Ticket',
    );
    return '$_temp0';
  }

  @override
  String get tpTiredOfConfirming =>
      'Keine Lust mehr zu bestätigen? Verbinde Mercado Pago oder Stripe für automatische Bestätigung.';

  @override
  String get tpToConfirmEmpty => 'Keine Zahlungen warten auf dich.';

  @override
  String get tpToConfirmInfo =>
      'Prüfe Betrag und GG-Code auf deinem Konto, bevor du bestätigst. Die Bestätigung stellt die Tickets aus.';

  @override
  String get tpToConfirmTitle => 'Zu bestätigende Zahlungen';

  @override
  String get tpTotal => 'Gesamt';

  @override
  String get tpTypeEnded => 'Verkauf beendet';

  @override
  String get tpTypeHasSalesWarning =>
      'Von dieser Art wurden schon Tickets verkauft: Sie behalten Preis und Art.';

  @override
  String get tpTypeHidden => 'Versteckt';

  @override
  String get tpTypeMaxPerUser => 'Max. pro Person';

  @override
  String get tpTypeName => 'Name (z. B. VIP)';

  @override
  String get tpTypeNotStarted => 'Verkauf noch nicht gestartet';

  @override
  String tpTypeOnlyLeft(int count) {
    return 'Nur noch $count';
  }

  @override
  String get tpTypePerks => 'Beschreibung / Vorteile';

  @override
  String get tpTypePrice => 'Preis';

  @override
  String get tpTypeQuantity => 'Anzahl (leer = Eventkapazität)';

  @override
  String get tpTypeSelling => 'Im Verkauf';

  @override
  String tpTypeSold(int sold, String total) {
    return '$sold/$total verkauft';
  }

  @override
  String get tpTypeSoldOut => 'Ausverkauft';

  @override
  String get tpTypeUnavailable => 'Nicht im Verkauf';

  @override
  String get tpViewPayment => 'Zahlung ansehen';

  @override
  String get tpViewReceipt => 'Beleg';

  @override
  String get tpViewTickets => 'Tickets ansehen';

  @override
  String get mtAddTime => 'Uhrzeit hinzufügen';

  @override
  String get mtAdvanced => 'Erweitert';

  @override
  String get mtApplyAll => 'Auf alle gewählten Tage anwenden';

  @override
  String get mtAvailableFrom => 'Verfügbar ab';

  @override
  String get mtAvailableUntil => 'Bis';

  @override
  String get mtBreak => 'Pause zwischen Terminen';

  @override
  String get mtBulkCloseRange => 'Zeitraum schließen (Urlaub)';

  @override
  String get mtBulkHint => 'Änderungen werden mit „Speichern\" übernommen.';

  @override
  String get mtBulkRemoveTime =>
      'Uhrzeit an jedem gewählten Wochentag entfernen';

  @override
  String get mtBulkTitle => 'Schnelle Änderungen';

  @override
  String get mtCalendarTitle => 'Kalender';

  @override
  String get mtCapacity => 'Plätze pro Termin';

  @override
  String get mtCloseDay => 'An diesem Tag geschlossen';

  @override
  String get mtClosed => 'Geschlossen';

  @override
  String mtConfirmBody(int count) {
    return '$count gebuchte Termine würden entfernt. Diese Buchungen werden storniert, die Gäste benachrichtigt und erstattet.';
  }

  @override
  String get mtConfirmCancelBookings => 'Diese Buchungen stornieren';

  @override
  String get mtConfirmTitle => 'Einige Termine sind gebucht';

  @override
  String get mtCopyToMonth => 'Auf den ganzen Monat kopieren';

  @override
  String mtCopyToWeekdays(String weekday) {
    return 'Auf jeden $weekday in diesem Monat kopieren';
  }

  @override
  String get mtDateFrom => 'Ab Datum';

  @override
  String get mtDateTo => 'Bis Datum';

  @override
  String get mtDaysOfWeek => 'Wochentage';

  @override
  String get mtDone => 'Fertig';

  @override
  String get mtDuration => 'Dauer';

  @override
  String get mtErrOverlap =>
      'Termine würden sich überschneiden: „Start alle\" muss mindestens die Dauer sein.';

  @override
  String get mtErrRules => 'Bitte prüfe die Zeitplan-Einstellungen.';

  @override
  String get mtErrTimeExists => 'Diese Uhrzeit ist schon vorhanden.';

  @override
  String get mtErrTimeFit => 'Der Termin würde nach Mitternacht enden.';

  @override
  String get mtErrTimeOverlaps =>
      'Überschneidet sich mit einem anderen Termin an diesem Tag.';

  @override
  String get mtErrWeekdays => 'Wähle mindestens einen Wochentag.';

  @override
  String get mtErrWindow => '„Bis\" muss nach „Verfügbar ab\" liegen.';

  @override
  String mtHours(int h) {
    return '$h Std.';
  }

  @override
  String mtHoursMinutes(int h, int m) {
    return '$h Std. $m Min.';
  }

  @override
  String get mtLegendChanged => 'geänderter Tag';

  @override
  String get mtLegendSpecialPrice => 'Sonderpreis';

  @override
  String get mtLegendWeekendPrice => 'Wochenendpreis';

  @override
  String mtMinutes(int m) {
    return '$m Min.';
  }

  @override
  String get mtNextMonth => 'Nächster Monat';

  @override
  String get mtNoBreak => 'Keine Pause';

  @override
  String get mtNoEnd => 'Kein Enddatum';

  @override
  String get mtPrevMonth => 'Vorheriger Monat';

  @override
  String get mtPreview => 'Termine an jedem gewählten Tag';

  @override
  String get mtRemoveTime => 'Uhrzeit entfernen';

  @override
  String get mtResetDay => 'Auf Standard zurücksetzen';

  @override
  String get mtSaved => 'Zeitplan gespeichert';

  @override
  String mtSavedCancelled(int count) {
    return 'Zeitplan gespeichert – $count Buchungen storniert und erstattet';
  }

  @override
  String get mtSetupTitle => 'Deine Zeiten';

  @override
  String get mtSpecialPrice => 'Sonderpreis für diesen Tag';

  @override
  String get mtSpecialPriceHint => 'Leer = normaler Preis';

  @override
  String get mtStartEvery => 'Start alle';

  @override
  String get mtStartEveryAuto => 'Automatisch (Dauer + Pause)';

  @override
  String get mtTime => 'Uhrzeit';

  @override
  String get mtTimezone => 'Zeitzone';

  @override
  String get mtTitle => 'Zeiten verwalten';

  @override
  String get mtWeekendPrice => 'Wochenendpreis';

  @override
  String get mtWeekendPriceInfo =>
      'Gilt an den gewählten Tagen; Sonderpreise für einzelne Tage setzt du unter „Zeiten verwalten\".';

  @override
  String get mtWeekendPriceToggle => 'Anderer Preis am Wochenende';

  @override
  String rtGroupsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Gruppentermine',
      one: 'noch 1 Gruppentermin',
    );
    return '$_temp0';
  }

  @override
  String rtSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Plätze',
      one: 'noch 1 Platz',
    );
    return '$_temp0';
  }

  @override
  String get rtSpecialPrice => 'Sonderpreis';

  @override
  String rtTimesIn(String zone) {
    return 'Zeiten in der Zeitzone des Gastgebers ($zone)';
  }

  @override
  String get rtWeekendPrice => 'Wochenendpreis';

  @override
  String rtYourTime(String time) {
    return 'Deine Zeit: $time';
  }

  @override
  String get tpReorder => 'Zum Sortieren ziehen';

  @override
  String tpSalesRow(int sold, int held, String left) {
    return '$sold verkauft · $held reserviert · $left frei';
  }

  @override
  String get tpSalesSummary => 'Verkäufe nach Ticketart';

  @override
  String tpSalesTotal(int sold, int held) {
    return 'Gesamt: $sold verkauft, $held reserviert';
  }

  @override
  String get wzAllGood => 'Alles ist bereit.';

  @override
  String get wzAvailability => 'Verfügbarkeit';

  @override
  String get wzBack => 'Zurück';

  @override
  String get wzEdit => 'Bearbeiten';

  @override
  String get wzErrCapacity => 'Gib an, wie viele Personen kommen können.';

  @override
  String get wzErrDates => 'Das Ende muss nach dem Beginn liegen.';

  @override
  String get wzErrDescription => 'Füge eine Beschreibung hinzu.';

  @override
  String get wzErrLocation => 'Gib den Ort an.';

  @override
  String get wzErrTitle => 'Füge einen Titel hinzu.';

  @override
  String get wzEventBasics => 'Grundlagen';

  @override
  String get wzExpBasics => 'Grundlagen';

  @override
  String get wzFineTuneLater =>
      'Einzelne Tage kannst du später unter „Zeiten verwalten\" anpassen.';

  @override
  String get wzFix => 'Beheben';

  @override
  String get wzFormatPrice => 'Format & Preis';

  @override
  String get wzLocation => 'Ort';

  @override
  String get wzNext => 'Weiter';

  @override
  String get wzOverviewTitle => 'Was möchtest du ändern?';

  @override
  String get wzPayment => 'Zahlung';

  @override
  String get wzPreviewTitle => 'So sehen es Käufer';

  @override
  String get wzRecurringInfo =>
      'Gäste wählen eine der erzeugten Zeiten. Ausschalten, um einzelne Termine zu nutzen.';

  @override
  String get wzRecurringToggle => 'Jede Woche wiederholen';

  @override
  String get wzResume => 'Fortsetzen';

  @override
  String get wzResumeBody =>
      'Auf diesem Gerät gibt es einen unfertigen Entwurf. Dort weitermachen?';

  @override
  String get wzResumeTitle => 'Entwurf fortsetzen?';

  @override
  String get wzReview => 'Prüfen & veröffentlichen';

  @override
  String get wzStartOver => 'Neu beginnen';

  @override
  String wzStepOf(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get wzTickets => 'Tickets';

  @override
  String get wzWarnManualLarge =>
      'Viele Personen mit manuellen Zahlungen: Du bestätigst jede einzeln. Erwäge die Sofortbestätigung.';

  @override
  String get wzWarnNoAvailability =>
      'Noch keine Verfügbarkeit: Füge nach dem Speichern Termine hinzu oder aktiviere „Jede Woche wiederholen\".';

  @override
  String get wzWarnNoPhoto =>
      'Noch kein Titelbild: Angebote mit Foto werden öfter gebucht.';

  @override
  String get wzWhenWhere => 'Wann & wo';

  @override
  String get tpPaymentMethodsSectionHint =>
      'Deine eigenen Methoden (Pix, PayPal, …): Andere können dich direkt bezahlen, und du kannst sie für Tickets nutzen, die du selbst bestätigst.';

  @override
  String get tpPaymentMethodsSaveFailed =>
      'Zahlungsmethoden konnten nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String wzNextTo(String step) {
    return 'Weiter: $step';
  }

  @override
  String get wzSteps => 'Schritte';

  @override
  String get wzAllStepsTitle => 'Alle Schritte';

  @override
  String get wzStepsHint =>
      'Tippe auf einen Schritt, um dorthin zu springen. Du kannst jederzeit zurückkehren.';

  @override
  String get wzStatusCurrent => 'Aktueller Schritt';

  @override
  String get wzStatusDone => 'Erledigt';

  @override
  String get wzStatusAttention => 'Braucht Aufmerksamkeit';

  @override
  String get wzStatusTodo => 'Noch nicht begonnen';

  @override
  String wzStepSemantics(int step, int total, String title, String status) {
    return 'Schritt $step von $total: $title. $status';
  }

  @override
  String get wzPaymentAppearsNote =>
      'Der Schritt Zahlung erscheint, sobald der Preis über 0 liegt.';

  @override
  String get wzPublishBlocked =>
      'Erledige die Pflichtangaben oben, um zu veröffentlichen.';

  @override
  String get wzEvBasicsDesc =>
      'Gib deinem Event einen klaren Titel und beschreibe, was die Leute erwartet. Ein Titelbild macht es auffälliger.';

  @override
  String get wzEvBasicsReq => 'Pflicht: Titel und Beschreibung.';

  @override
  String get wzEvWhereDesc =>
      'Gib an, wo es stattfindet (Adresse eingeben oder auf der Karte wählen) und wann es beginnt und endet.';

  @override
  String get wzEvWhereReq => 'Pflicht: der Ort und ein Ende nach dem Beginn.';

  @override
  String get wzEvTicketsDesc =>
      'Wähle, ob das Event kostenlos oder kostenpflichtig ist, lege den Preis fest und wie viele teilnehmen können.';

  @override
  String get wzEvTicketsReq =>
      'Pflicht: wie viele kommen können (oder unbegrenzt) und bei kostenpflichtigen Events ein Preis.';

  @override
  String get wzEvPaymentDesc =>
      'Wähle, wie Teilnehmende dich für ihre Tickets bezahlen.';

  @override
  String get wzEvPaymentReq => 'Pflicht: eine Zahlungsmethode.';

  @override
  String get wzEvReviewDesc =>
      'Prüfe, wie dein Event aussehen wird. Behebe alles, was rot markiert ist, und veröffentliche, speichere einen Entwurf oder plane es.';

  @override
  String get wzExBasicsDesc =>
      'Benenne dein Erlebnis, beschreibe es und füge Fotos, deine Sprachen und die Leistungen hinzu.';

  @override
  String get wzExBasicsReq =>
      'Pflicht: Titel, Beschreibung, ein Hauptfoto, mindestens eine Sprache und die Leistungen.';

  @override
  String get wzExLocationDesc => 'Sag deinen Gästen, wo ihr euch trefft.';

  @override
  String get wzExLocationReq => 'Pflicht: der Treffpunkt.';

  @override
  String get wzExFormatDesc =>
      'Lege Dauer und Gruppengröße fest und ob es kostenlos oder kostenpflichtig ist (pro Person oder pro Gruppe).';

  @override
  String get wzExFormatReq =>
      'Pflicht: Dauer, Gruppengröße und bei kostenpflichtigen Erlebnissen ein Preis.';

  @override
  String get wzExAvailDesc =>
      'Wähle, wann Gäste buchen können: ein wöchentlicher Zeitplan oder einzelne Termine, die du später hinzufügst.';

  @override
  String get wzExAvailReq =>
      'Optional: Termine kannst du auch nach dem Speichern hinzufügen.';

  @override
  String get wzExPaymentDesc => 'Wähle, wie Gäste dich bezahlen.';

  @override
  String get wzExPaymentReq => 'Pflicht: mindestens eine Zahlungsmethode.';

  @override
  String get wzExReviewDesc =>
      'Prüfe, wie Gäste es sehen. Behebe alles, was rot markiert ist, und veröffentliche oder speichere einen Entwurf.';

  @override
  String verificationOrMethod(String method) {
    return 'oder $method';
  }

  @override
  String get safetyAcademyTitle => 'Sicherheitsakademie';

  @override
  String get safetyAcademyLearningModules => 'Lernmodule';

  @override
  String safetyAcademyModulesCompleted(int completed, int total) {
    return '$completed / $total Module abgeschlossen';
  }

  @override
  String get safetyAcademyChampionTitle => 'Sicherheits-Champion';

  @override
  String get safetyAcademyChampionBody =>
      'Du hast alle Sicherheitsmodule abgeschlossen!';

  @override
  String get safetyAcademyLessonCompletedToast => 'Lektion abgeschlossen!';

  @override
  String get safetyAcademyNoLessons => 'Noch keine Lektionen verfügbar.';

  @override
  String safetyAcademyLessonsProgress(int completed, int total) {
    return '$completed / $total Lektionen';
  }

  @override
  String safetyAcademyLessonXpWithQuiz(int xp) {
    return '+$xp XP | Quiz';
  }

  @override
  String get safetyAcademyTakeQuiz => 'Quiz starten';

  @override
  String get safetyAcademyCompleteLesson => 'Lektion abschließen';

  @override
  String get safetyAcademyCompleted => 'Abgeschlossen';

  @override
  String safetyAcademyQuestionOf(int current, int total) {
    return 'Frage $current von $total';
  }

  @override
  String safetyAcademyCorrectCount(int count) {
    return '$count richtig';
  }

  @override
  String get safetyAcademyNextQuestion => 'Nächste Frage';

  @override
  String get safetyAcademySeeResults => 'Ergebnis ansehen';

  @override
  String get safetyAcademyGreatJob => 'Super gemacht!';

  @override
  String get safetyAcademyKeepLearning => 'Lern weiter!';

  @override
  String safetyAcademyScoreSummary(int correct, int total) {
    return '$correct von $total richtig';
  }

  @override
  String safetyAcademyPassingScore(int score) {
    return 'Bestehensgrenze: $score %';
  }

  @override
  String safetyAcademyCompleteLessonXp(int xp) {
    return 'Lektion abschließen (+$xp XP)';
  }

  @override
  String get safetyAcademyReviewLesson => 'Lektion wiederholen';

  @override
  String get safetyAcademyExitQuizTitle => 'Quiz verlassen?';

  @override
  String get safetyAcademyExitQuizBody => 'Dein Fortschritt geht verloren.';

  @override
  String get countryNameAF => 'Afghanistan';

  @override
  String get countryNameAL => 'Albanien';

  @override
  String get countryNameDZ => 'Algerien';

  @override
  String get countryNameAD => 'Andorra';

  @override
  String get countryNameAO => 'Angola';

  @override
  String get countryNameAG => 'Antigua und Barbuda';

  @override
  String get countryNameAR => 'Argentinien';

  @override
  String get countryNameAM => 'Armenien';

  @override
  String get countryNameAU => 'Australien';

  @override
  String get countryNameAT => 'Österreich';

  @override
  String get countryNameAZ => 'Aserbaidschan';

  @override
  String get countryNameBS => 'Bahamas';

  @override
  String get countryNameBH => 'Bahrain';

  @override
  String get countryNameBD => 'Bangladesch';

  @override
  String get countryNameBB => 'Barbados';

  @override
  String get countryNameBY => 'Belarus';

  @override
  String get countryNameBE => 'Belgien';

  @override
  String get countryNameBZ => 'Belize';

  @override
  String get countryNameBJ => 'Benin';

  @override
  String get countryNameBT => 'Bhutan';

  @override
  String get countryNameBO => 'Bolivien';

  @override
  String get countryNameBA => 'Bosnien und Herzegowina';

  @override
  String get countryNameBW => 'Botswana';

  @override
  String get countryNameBR => 'Brasilien';

  @override
  String get countryNameBN => 'Brunei';

  @override
  String get countryNameBG => 'Bulgarien';

  @override
  String get countryNameBF => 'Burkina Faso';

  @override
  String get countryNameBI => 'Burundi';

  @override
  String get countryNameCV => 'Kap Verde';

  @override
  String get countryNameKH => 'Kambodscha';

  @override
  String get countryNameCM => 'Kamerun';

  @override
  String get countryNameCA => 'Kanada';

  @override
  String get countryNameCF => 'Zentralafrikanische Republik';

  @override
  String get countryNameTD => 'Tschad';

  @override
  String get countryNameCL => 'Chile';

  @override
  String get countryNameCN => 'China';

  @override
  String get countryNameCO => 'Kolumbien';

  @override
  String get countryNameKM => 'Komoren';

  @override
  String get countryNameCG => 'Kongo';

  @override
  String get countryNameCD => 'Demokratische Republik Kongo';

  @override
  String get countryNameCR => 'Costa Rica';

  @override
  String get countryNameHR => 'Kroatien';

  @override
  String get countryNameCU => 'Kuba';

  @override
  String get countryNameCY => 'Zypern';

  @override
  String get countryNameCZ => 'Tschechien';

  @override
  String get countryNameDK => 'Dänemark';

  @override
  String get countryNameDJ => 'Dschibuti';

  @override
  String get countryNameDM => 'Dominica';

  @override
  String get countryNameDO => 'Dominikanische Republik';

  @override
  String get countryNameEC => 'Ecuador';

  @override
  String get countryNameEG => 'Ägypten';

  @override
  String get countryNameSV => 'El Salvador';

  @override
  String get countryNameGQ => 'Äquatorialguinea';

  @override
  String get countryNameER => 'Eritrea';

  @override
  String get countryNameEE => 'Estland';

  @override
  String get countryNameSZ => 'Eswatini';

  @override
  String get countryNameET => 'Äthiopien';

  @override
  String get countryNameFJ => 'Fidschi';

  @override
  String get countryNameFI => 'Finnland';

  @override
  String get countryNameFR => 'Frankreich';

  @override
  String get countryNameGA => 'Gabun';

  @override
  String get countryNameGM => 'Gambia';

  @override
  String get countryNameGE => 'Georgien';

  @override
  String get countryNameDE => 'Deutschland';

  @override
  String get countryNameGH => 'Ghana';

  @override
  String get countryNameGR => 'Griechenland';

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
  String get countryNameHU => 'Ungarn';

  @override
  String get countryNameIS => 'Island';

  @override
  String get countryNameIN => 'Indien';

  @override
  String get countryNameID => 'Indonesien';

  @override
  String get countryNameIR => 'Iran';

  @override
  String get countryNameIQ => 'Irak';

  @override
  String get countryNameIE => 'Irland';

  @override
  String get countryNameIL => 'Israel';

  @override
  String get countryNameIT => 'Italien';

  @override
  String get countryNameCI => 'Elfenbeinküste';

  @override
  String get countryNameJM => 'Jamaika';

  @override
  String get countryNameJP => 'Japan';

  @override
  String get countryNameJO => 'Jordanien';

  @override
  String get countryNameKZ => 'Kasachstan';

  @override
  String get countryNameKE => 'Kenia';

  @override
  String get countryNameKI => 'Kiribati';

  @override
  String get countryNameXK => 'Kosovo';

  @override
  String get countryNameKW => 'Kuwait';

  @override
  String get countryNameKG => 'Kirgisistan';

  @override
  String get countryNameLA => 'Laos';

  @override
  String get countryNameLV => 'Lettland';

  @override
  String get countryNameLB => 'Libanon';

  @override
  String get countryNameLS => 'Lesotho';

  @override
  String get countryNameLR => 'Liberia';

  @override
  String get countryNameLY => 'Libyen';

  @override
  String get countryNameLI => 'Liechtenstein';

  @override
  String get countryNameLT => 'Litauen';

  @override
  String get countryNameLU => 'Luxemburg';

  @override
  String get countryNameMG => 'Madagaskar';

  @override
  String get countryNameMW => 'Malawi';

  @override
  String get countryNameMY => 'Malaysia';

  @override
  String get countryNameMV => 'Malediven';

  @override
  String get countryNameML => 'Mali';

  @override
  String get countryNameMT => 'Malta';

  @override
  String get countryNameMH => 'Marshallinseln';

  @override
  String get countryNameMR => 'Mauretanien';

  @override
  String get countryNameMU => 'Mauritius';

  @override
  String get countryNameMX => 'Mexiko';

  @override
  String get countryNameFM => 'Mikronesien';

  @override
  String get countryNameMD => 'Moldau';

  @override
  String get countryNameMC => 'Monaco';

  @override
  String get countryNameMN => 'Mongolei';

  @override
  String get countryNameME => 'Montenegro';

  @override
  String get countryNameMA => 'Marokko';

  @override
  String get countryNameMZ => 'Mosambik';

  @override
  String get countryNameMM => 'Myanmar';

  @override
  String get countryNameNA => 'Namibia';

  @override
  String get countryNameNR => 'Nauru';

  @override
  String get countryNameNP => 'Nepal';

  @override
  String get countryNameNL => 'Niederlande';

  @override
  String get countryNameNZ => 'Neuseeland';

  @override
  String get countryNameNI => 'Nicaragua';

  @override
  String get countryNameNE => 'Niger';

  @override
  String get countryNameNG => 'Nigeria';

  @override
  String get countryNameKP => 'Nordkorea';

  @override
  String get countryNameMK => 'Nordmazedonien';

  @override
  String get countryNameNO => 'Norwegen';

  @override
  String get countryNameOM => 'Oman';

  @override
  String get countryNamePK => 'Pakistan';

  @override
  String get countryNamePW => 'Palau';

  @override
  String get countryNamePS => 'Palästina';

  @override
  String get countryNamePA => 'Panama';

  @override
  String get countryNamePG => 'Papua-Neuguinea';

  @override
  String get countryNamePY => 'Paraguay';

  @override
  String get countryNamePE => 'Peru';

  @override
  String get countryNamePH => 'Philippinen';

  @override
  String get countryNamePL => 'Polen';

  @override
  String get countryNamePT => 'Portugal';

  @override
  String get countryNameQA => 'Katar';

  @override
  String get countryNameRO => 'Rumänien';

  @override
  String get countryNameRU => 'Russland';

  @override
  String get countryNameRW => 'Ruanda';

  @override
  String get countryNameKN => 'St. Kitts und Nevis';

  @override
  String get countryNameLC => 'St. Lucia';

  @override
  String get countryNameVC => 'St. Vincent und die Grenadinen';

  @override
  String get countryNameWS => 'Samoa';

  @override
  String get countryNameSM => 'San Marino';

  @override
  String get countryNameST => 'São Tomé und Príncipe';

  @override
  String get countryNameSA => 'Saudi-Arabien';

  @override
  String get countryNameSN => 'Senegal';

  @override
  String get countryNameRS => 'Serbien';

  @override
  String get countryNameSC => 'Seychellen';

  @override
  String get countryNameSL => 'Sierra Leone';

  @override
  String get countryNameSG => 'Singapur';

  @override
  String get countryNameSK => 'Slowakei';

  @override
  String get countryNameSI => 'Slowenien';

  @override
  String get countryNameSB => 'Salomonen';

  @override
  String get countryNameSO => 'Somalia';

  @override
  String get countryNameZA => 'Südafrika';

  @override
  String get countryNameKR => 'Südkorea';

  @override
  String get countryNameSS => 'Südsudan';

  @override
  String get countryNameES => 'Spanien';

  @override
  String get countryNameLK => 'Sri Lanka';

  @override
  String get countryNameSD => 'Sudan';

  @override
  String get countryNameSR => 'Suriname';

  @override
  String get countryNameSE => 'Schweden';

  @override
  String get countryNameCH => 'Schweiz';

  @override
  String get countryNameSY => 'Syrien';

  @override
  String get countryNameTW => 'Taiwan';

  @override
  String get countryNameTJ => 'Tadschikistan';

  @override
  String get countryNameTZ => 'Tansania';

  @override
  String get countryNameTH => 'Thailand';

  @override
  String get countryNameTL => 'Osttimor';

  @override
  String get countryNameTG => 'Togo';

  @override
  String get countryNameTO => 'Tonga';

  @override
  String get countryNameTT => 'Trinidad und Tobago';

  @override
  String get countryNameTN => 'Tunesien';

  @override
  String get countryNameTR => 'Türkei';

  @override
  String get countryNameTM => 'Turkmenistan';

  @override
  String get countryNameTV => 'Tuvalu';

  @override
  String get countryNameUG => 'Uganda';

  @override
  String get countryNameUA => 'Ukraine';

  @override
  String get countryNameAE => 'Vereinigte Arabische Emirate';

  @override
  String get countryNameGB => 'Vereinigtes Königreich';

  @override
  String get countryNameUS => 'Vereinigte Staaten';

  @override
  String get countryNameUY => 'Uruguay';

  @override
  String get countryNameUZ => 'Usbekistan';

  @override
  String get countryNameVU => 'Vanuatu';

  @override
  String get countryNameVA => 'Vatikanstadt';

  @override
  String get countryNameVE => 'Venezuela';

  @override
  String get countryNameVN => 'Vietnam';

  @override
  String get countryNameYE => 'Jemen';

  @override
  String get countryNameZM => 'Sambia';

  @override
  String get countryNameZW => 'Simbabwe';

  @override
  String get countryNameHK => 'Hongkong';

  @override
  String get countryNamePR => 'Puerto Rico';

  @override
  String get spotsCatRestaurant => 'Restaurant';

  @override
  String get spotsCatCafe => 'Café';

  @override
  String get spotsCatCulturalSite => 'Kulturstätte';

  @override
  String get spotsCatMarket => 'Markt';

  @override
  String get spotsCatViewpoint => 'Aussichtspunkt';

  @override
  String spotsCreatedNamed(String name) {
    return 'Ort „$name“ erstellt!';
  }

  @override
  String get spotsEmptyHint =>
      'Noch keine Kulturorte in dieser Stadt. Füge als Erste:r einen hinzu!';

  @override
  String spotsEmptyCategoryHint(String category) {
    return 'Noch keine Orte in „$category“ in dieser Stadt. Füge als Erste:r einen hinzu!';
  }

  @override
  String spotsReviewCountParen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count Bewertungen)',
      one: '(1 Bewertung)',
    );
    return '$_temp0';
  }

  @override
  String get uexpLangHebrew => 'Hebräisch';

  @override
  String get uexpLangThai => 'Thailändisch';

  @override
  String get uexpLangVietnamese => 'Vietnamesisch';

  @override
  String get safetyAcademyModCommunicationTitle => 'Kommunikationsfähigkeiten';

  @override
  String get safetyAcademyModCommunicationDesc =>
      'Entwickle gesunde Kommunikationsgewohnheiten – mit Einvernehmen, Grenzen und aktivem Zuhören.';

  @override
  String get safetyAcademyLsnActiveListeningTitle => 'Aktives Zuhören';

  @override
  String get safetyAcademyLsnActiveListeningS0 =>
      'Aktives Zuhören ist die Grundlage für echte Verbindung. Es geht über das bloße Hören von Worten hinaus – es bedeutet, sich ganz auf dein Gegenüber einzulassen und ihm das Gefühl zu geben, wertgeschätzt zu werden.';

  @override
  String get safetyAcademyLsnActiveListeningS1 =>
      'Stelle Anschlussfragen zu dem, was die andere Person gesagt hat – nicht nur zu dem, worüber du reden willst. Das zeigt echtes Interesse.';

  @override
  String get safetyAcademyLsnActiveListeningS2 =>
      'Techniken für aktives Zuhören';

  @override
  String get safetyAcademyLsnActiveListeningS2I0 =>
      'Schenke volle Aufmerksamkeit (leg dein Handy weg)';

  @override
  String get safetyAcademyLsnActiveListeningS2I1 =>
      'Nutze verbale Signale („Verstehe“, „Das ist interessant“)';

  @override
  String get safetyAcademyLsnActiveListeningS2I2 =>
      'Gib wieder, was du gehört hast („Du meinst also …“)';

  @override
  String get safetyAcademyLsnActiveListeningS2I3 =>
      'Stelle offene Anschlussfragen';

  @override
  String get safetyAcademyLsnActiveListeningS2I4 =>
      'Unterbrich nicht und plane deine Antwort nicht, während die andere Person spricht';

  @override
  String get safetyAcademyLsnActiveListeningS3 =>
      'In Chats bedeutet aktives Zuhören, Nachrichten aufmerksam zu lesen, auf das tatsächlich Gesagte einzugehen und durchdachte Fragen zu stellen, statt jedes Thema auf dich selbst zu lenken.';

  @override
  String get safetyAcademyLsnActiveListeningQ0 =>
      'Die Person, die du triffst, erzählt von ihrer letzten Reise. Was ist die beste Reaktion im Sinne des aktiven Zuhörens?';

  @override
  String get safetyAcademyLsnActiveListeningQ0O0 =>
      '„Cool. Na ja, ich war jedenfalls in …“';

  @override
  String get safetyAcademyLsnActiveListeningQ0O1 =>
      '„Das klingt toll! Was war das Highlight der Reise?“';

  @override
  String get safetyAcademyLsnActiveListeningQ0O2 =>
      '„Da war ich auch schon, lass mich davon erzählen.“';

  @override
  String get safetyAcademyLsnActiveListeningQ0O3 => '„Schön.“';

  @override
  String get safetyAcademyLsnActiveListeningQ0Exp =>
      'Eine Anschlussfrage zu ihrem Erlebnis zeigt echtes Interesse und hält das Gespräch im Fluss.';

  @override
  String get safetyAcademyLsnActiveListeningQ1 =>
      'Was solltest du beim aktiven Zuhören vermeiden?';

  @override
  String get safetyAcademyLsnActiveListeningQ1O0 => 'Blickkontakt halten';

  @override
  String get safetyAcademyLsnActiveListeningQ1O1 =>
      'Deine Antwort planen, während die andere Person noch spricht';

  @override
  String get safetyAcademyLsnActiveListeningQ1O2 => 'Gelegentlich nicken';

  @override
  String get safetyAcademyLsnActiveListeningQ1O3 => 'Anschlussfragen stellen';

  @override
  String get safetyAcademyLsnActiveListeningQ1Exp =>
      'Wenn du schon deine nächste Antwort planst, hörst du nicht wirklich zu. Konzentriere dich zuerst aufs Verstehen, dann antworte.';

  @override
  String get safetyAcademyLsnBoundariesTitle => 'Grenzen setzen';

  @override
  String get safetyAcademyLsnBoundariesS0 =>
      'Grenzen sind die Regeln, die du dafür festlegst, wie du behandelt werden möchtest. Sie sind essenziell für gesunde Beziehungen und schützen dein emotionales, körperliches und psychisches Wohlbefinden.';

  @override
  String get safetyAcademyLsnBoundariesS1 =>
      'Kommuniziere deine Grenzen klar und frühzeitig. Zum Beispiel: „Ich lerne jemanden lieber erst im Chat kennen, bevor wir uns persönlich treffen“ oder „Ich möchte gerade keine Fotos teilen.“';

  @override
  String get safetyAcademyLsnBoundariesS2 =>
      'Wenn jemand wiederholt eine Grenze übergeht, die du gesetzt hast, ist das ein ernstes Warnsignal – egal, welche Ausreden die Person hat.';

  @override
  String get safetyAcademyLsnBoundariesS3 => 'Beispiele für gesunde Grenzen';

  @override
  String get safetyAcademyLsnBoundariesS3I0 =>
      'Selbst entscheiden, wann du bereit bist, deine Telefonnummer zu teilen';

  @override
  String get safetyAcademyLsnBoundariesS3I1 =>
      'Festlegen, bis wie spät dir jemand schreiben darf';

  @override
  String get safetyAcademyLsnBoundariesS3I2 =>
      'Klar sagen, wie viel persönlichen Freiraum du beim Treffen brauchst';

  @override
  String get safetyAcademyLsnBoundariesS3I3 =>
      'Nein sagen zu Plänen, die sich überstürzt oder unangenehm anfühlen';

  @override
  String get safetyAcademyLsnBoundariesS3I4 =>
      'Gesprächspausen einlegen, wenn du Abstand brauchst';

  @override
  String get safetyAcademyLsnBoundariesS4 =>
      'Denk daran: Grenzen zu setzen heißt nicht, schwierig zu sein. Es ist Selbstachtung. Ein Mensch, der dich schätzt, wird deine Grenzen respektieren.';

  @override
  String get safetyAcademyLsnBoundariesQ0 =>
      'Du sagst einem neuen Kontakt, dass du deine Nummer noch nicht teilen möchtest, und er fragt immer wieder. Was bedeutet das?';

  @override
  String get safetyAcademyLsnBoundariesQ0O0 =>
      'Die Person ist wirklich an dir interessiert';

  @override
  String get safetyAcademyLsnBoundariesQ0O1 =>
      'Die Person will das Gespräch einfach voranbringen';

  @override
  String get safetyAcademyLsnBoundariesQ0O2 =>
      'Die Person respektiert die Grenze nicht, die du klar geäußert hast';

  @override
  String get safetyAcademyLsnBoundariesQ0O3 =>
      'Das ist normales Verhalten beim Kennenlernen';

  @override
  String get safetyAcademyLsnBoundariesQ0Exp =>
      'Eine klar geäußerte Grenze immer wieder zu übergehen ist respektlos und ein Warnsignal – egal, welcher Grund genannt wird.';

  @override
  String get safetyAcademyLsnBoundariesQ1 =>
      'Wann ist der beste Zeitpunkt, eine Grenze zu kommunizieren?';

  @override
  String get safetyAcademyLsnBoundariesQ1O0 =>
      'Nachdem sie mehrmals überschritten wurde';

  @override
  String get safetyAcademyLsnBoundariesQ1O1 =>
      'Klar und frühzeitig, bevor es zum Problem wird';

  @override
  String get safetyAcademyLsnBoundariesQ1O2 =>
      'Nur wenn die andere Person danach fragt';

  @override
  String get safetyAcademyLsnBoundariesQ1O3 =>
      'Grenzen sind beim Kennenlernen neuer Menschen nicht nötig';

  @override
  String get safetyAcademyLsnBoundariesQ1Exp =>
      'Grenzen früh und klar zu benennen beugt Missverständnissen vor und gibt den Ton für gegenseitigen Respekt an.';

  @override
  String get safetyAcademyLsnConsentTitle => 'Einvernehmen verstehen';

  @override
  String get safetyAcademyLsnConsentS0 =>
      'Einverständnis ist eine klare, begeisterte und fortlaufende Zustimmung. Es gilt für jede Interaktion -- vom Teilen persönlicher Informationen bis zu körperlichem Kontakt.';

  @override
  String get safetyAcademyLsnConsentS1 =>
      'Beim Einvernehmen geht es nicht nur um Körperkontakt. Die Fotos einer Person zu teilen, ihre Nachrichten weiterzuleiten oder ihre persönlichen Daten ohne Erlaubnis weiterzugeben, verletzt ebenfalls das Einvernehmen.';

  @override
  String get safetyAcademyLsnConsentS2 => 'Grundprinzipien des Einvernehmens';

  @override
  String get safetyAcademyLsnConsentS2I0 =>
      'Freiwillig – ohne Druck, Zwang oder Manipulation';

  @override
  String get safetyAcademyLsnConsentS2I1 =>
      'Widerrufbar – jede Person kann jederzeit ihre Meinung ändern';

  @override
  String get safetyAcademyLsnConsentS2I2 =>
      'Informiert – auf Grundlage ehrlicher, vollständiger Informationen';

  @override
  String get safetyAcademyLsnConsentS2I3 =>
      'Begeistert – achte auf ein aktives „Ja“, nicht nur auf das Fehlen eines „Nein“';

  @override
  String get safetyAcademyLsnConsentS2I4 =>
      'Konkret – die Zustimmung zu einer Sache bedeutet keine Zustimmung zu allem';

  @override
  String get safetyAcademyLsnConsentS3 =>
      'Schweigen oder das Fehlen eines „Nein“ ist kein Einvernehmen. Achte immer auf eine klare, positive Zustimmung.';

  @override
  String get safetyAcademyLsnConsentS4 =>
      'Nach Einvernehmen zu fragen ist nicht peinlich – es zeigt Reife und Respekt. Einfache Nachfragen wie „Ist das okay für dich?“ oder „Möchtest du …?“ machen einen großen Unterschied.';

  @override
  String get safetyAcademyLsnConsentQ0 =>
      'Welche Aussage beschreibt Einvernehmen am besten?';

  @override
  String get safetyAcademyLsnConsentQ0O0 => 'Das Fehlen eines „Nein“';

  @override
  String get safetyAcademyLsnConsentQ0O1 =>
      'Eine klare, begeisterte und fortlaufende Zustimmung';

  @override
  String get safetyAcademyLsnConsentQ0O2 =>
      'Etwas, das nur bei Körperkontakt nötig ist';

  @override
  String get safetyAcademyLsnConsentQ0O3 =>
      'Eine einmalige Zustimmung, die für alle künftigen Situationen gilt';

  @override
  String get safetyAcademyLsnConsentQ0Exp =>
      'Einvernehmen muss klar, begeistert und fortlaufend sein und kann jederzeit widerrufen werden. Es gilt für alle Interaktionen.';

  @override
  String get safetyAcademyLsnConsentQ1 =>
      'Jemand, den du über die App kennengelernt hast, hat zugesagt, dich zu einem Event zu begleiten, wirkt aber nach der Ankunft unwohl. Was solltest du tun?';

  @override
  String get safetyAcademyLsnConsentQ1O0 =>
      'Die Person hat ja schon zugestimmt, also weiter wie geplant';

  @override
  String get safetyAcademyLsnConsentQ1O1 =>
      'Nachfragen, wie es der Person geht, und anbieten, woanders hinzugehen';

  @override
  String get safetyAcademyLsnConsentQ1O2 =>
      'Das Unbehagen ignorieren – das ist wahrscheinlich nur Nervosität';

  @override
  String get safetyAcademyLsnConsentQ1O3 =>
      'Sagen, dass die Person nicht hätte zustimmen sollen, wenn sie nicht kommen wollte';

  @override
  String get safetyAcademyLsnConsentQ1Exp =>
      'Einvernehmen ist widerrufbar. Wenn sich jemand unwohl zu fühlen scheint, frag nach. Das Wohlbefinden der Person ist wichtiger als jeder Plan.';

  @override
  String get safetyAcademyModCulturalSensitivityTitle =>
      'Kulturelle Sensibilität';

  @override
  String get safetyAcademyModCulturalSensitivityDesc =>
      'Gestalte interkulturelle Freundschaften mit Respekt, Neugier und Achtsamkeit.';

  @override
  String get safetyAcademyLsnCulturalDosTitle => 'Interkulturelle Dos';

  @override
  String get safetyAcademyLsnCulturalDosS0 =>
      'Jemanden mit einem anderen kulturellen Hintergrund kennenzulernen, kann eine der bereicherndsten Erfahrungen sein. Begegne ihm mit echter Neugier, Respekt und Lernbereitschaft.';

  @override
  String get safetyAcademyLsnCulturalDosS1 =>
      'Stell offene Fragen zu ihrer Kultur – aus echter Neugier, nicht wie in einem Quiz. „Welche Traditionen sind deiner Familie wichtig?“ ist viel besser als „Macht ihr Leute wirklich X?“';

  @override
  String get safetyAcademyLsnCulturalDosS2 =>
      'Dos für interkulturelle Kontakte';

  @override
  String get safetyAcademyLsnCulturalDosS2I0 =>
      'Informiere dich vor dem Treffen über grundlegende kulturelle Gepflogenheiten';

  @override
  String get safetyAcademyLsnCulturalDosS2I1 =>
      'Zeig echtes Interesse an ihrer Herkunft und ihren Traditionen';

  @override
  String get safetyAcademyLsnCulturalDosS2I2 =>
      'Sei offen für neues Essen, neue Aktivitäten und Erfahrungen';

  @override
  String get safetyAcademyLsnCulturalDosS2I3 =>
      'Respektiere Familiendynamiken, die sich von deinen unterscheiden können';

  @override
  String get safetyAcademyLsnCulturalDosS2I4 =>
      'Lerne ein paar Wörter oder Sätze in ihrer Sprache';

  @override
  String get safetyAcademyLsnCulturalDosS2I5 =>
      'Frag, wie sie angesprochen oder vorgestellt werden möchten';

  @override
  String get safetyAcademyLsnCulturalDosS3 =>
      'Denk daran: Jeder Mensch ist zuerst ein Individuum. Kulturelles Bewusstsein ist ein Ausgangspunkt – lerne die Person aber jenseits von Stereotypen kennen.';

  @override
  String get safetyAcademyLsnCulturalDosQ0 =>
      'Wie lernst du die Kultur eines neuen Freundes am besten kennen?';

  @override
  String get safetyAcademyLsnCulturalDosQ0O0 =>
      'Annahmen treffen, basierend auf dem, was du in Filmen gesehen hast';

  @override
  String get safetyAcademyLsnCulturalDosQ0O1 =>
      'Durchdachte, offene Fragen mit echter Neugier stellen';

  @override
  String get safetyAcademyLsnCulturalDosQ0O2 =>
      'Sie über kulturelle Fakten abfragen, die du online gelesen hast';

  @override
  String get safetyAcademyLsnCulturalDosQ0O3 =>
      'Das Thema ganz meiden, um niemanden zu kränken';

  @override
  String get safetyAcademyLsnCulturalDosQ0Exp =>
      'Echte, respektvolle Neugier ist der beste Weg. Lass sie erzählen, was ihnen wichtig ist.';

  @override
  String get safetyAcademyLsnCulturalDosQ1 =>
      'Ein neuer Freund erwähnt eine Familientradition, die du nicht verstehst. Was solltest du tun?';

  @override
  String get safetyAcademyLsnCulturalDosQ1O0 =>
      'Nicken und so tun, als würdest du es verstehen';

  @override
  String get safetyAcademyLsnCulturalDosQ1O1 =>
      'Bitten, mehr darüber zu erzählen und warum es wichtig ist';

  @override
  String get safetyAcademyLsnCulturalDosQ1O2 =>
      'Sagen, dass deine Traditionen anders sind';

  @override
  String get safetyAcademyLsnCulturalDosQ1O3 => 'Das Thema wechseln';

  @override
  String get safetyAcademyLsnCulturalDosQ1Exp =>
      'Wenn du nachfragst, zeigst du Respekt und echtes Interesse an ihrer Welt.';

  @override
  String get safetyAcademyLsnCulturalDontsTitle => 'Interkulturelle Don\'ts';

  @override
  String get safetyAcademyLsnCulturalDontsS0 =>
      'Gut gemeinte, aber uninformierte Kommentare können verletzend oder abwertend wirken. Wer die typischen Fallstricke kennt, gestaltet interkulturelle Freundschaften souverän.';

  @override
  String get safetyAcademyLsnCulturalDontsS1 =>
      'Reduziere niemanden auf seine Herkunft oder Nationalität. Kommentare wie „Ich wollte schon immer einen Freund aus [Land]“ oder „Du sprichst gut für einen [Nationalität]“ sind verletzend, nicht schmeichelhaft.';

  @override
  String get safetyAcademyLsnCulturalDontsS2 =>
      'Don\'ts für interkulturelle Kontakte';

  @override
  String get safetyAcademyLsnCulturalDontsS2I0 =>
      'Fetischisiere oder exotisiere weder ihre Kultur noch ihr Aussehen';

  @override
  String get safetyAcademyLsnCulturalDontsS2I1 =>
      'Geh nicht davon aus, dass sie für ihre gesamte Kultur stehen';

  @override
  String get safetyAcademyLsnCulturalDontsS2I2 =>
      'Mach keine Witze über ihren Akzent oder ihre Sprache';

  @override
  String get safetyAcademyLsnCulturalDontsS2I3 =>
      'Setz sie nicht unter Druck, kulturelle Bräuche zu erklären oder zu verteidigen';

  @override
  String get safetyAcademyLsnCulturalDontsS2I4 =>
      'Vergleiche sie nicht mit Stereotypen oder Darstellungen aus den Medien';

  @override
  String get safetyAcademyLsnCulturalDontsS2I5 =>
      'Tu kulturelle Unterschiede nicht als unwichtig ab';

  @override
  String get safetyAcademyLsnCulturalDontsS3 =>
      'Wenn dir ein kultureller Fehltritt passiert, entschuldige dich aufrichtig, lerne daraus und mach weiter. Entschuldige dich nicht so übertrieben, dass es plötzlich um deine Gefühle geht.';

  @override
  String get safetyAcademyLsnCulturalDontsQ0 =>
      'Welcher Kommentar ist kulturell unsensibel?';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O0 =>
      '„Ich würde sehr gern das Essen aus deinem Land probieren.“';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O1 =>
      '„Du siehst so exotisch aus.“';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O2 =>
      '„Welche Sprache sprichst du zu Hause?“';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O3 =>
      '„Erzähl mir von einem Fest, das deine Familie feiert.“';

  @override
  String get safetyAcademyLsnCulturalDontsQ0Exp =>
      'Jemanden „exotisch“ zu nennen, reduziert ihn auf sein Aussehen und seine kulturelle Herkunft. Das ist objektifizierend, kein Kompliment.';

  @override
  String get safetyAcademyLsnCulturalDontsQ1 =>
      'Dir rutscht versehentlich etwas kulturell Unsensibles heraus. Wie reagierst du am besten?';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O0 =>
      'So tun, als wäre nichts passiert';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O1 =>
      'Sich aufrichtig entschuldigen, daraus lernen und weitermachen';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O2 =>
      'Erklären, dass du es nicht so gemeint hast';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O3 =>
      'Sich übertrieben entschuldigen und es immer wieder ansprechen';

  @override
  String get safetyAcademyLsnCulturalDontsQ1Exp =>
      'Eine aufrichtige, kurze Entschuldigung und das ehrliche Bemühen, es besser zu machen, sind die reifste Reaktion.';

  @override
  String get safetyAcademyLsnCulturalCommunicationTitle =>
      'Kommunikation über Kulturen hinweg';

  @override
  String get safetyAcademyLsnCulturalCommunicationS0 =>
      'Kommunikationsstile unterscheiden sich von Kultur zu Kultur stark. Was in einer Kultur direkt und ehrlich wirkt, kann in einer anderen unhöflich rüberkommen. Wer diese Unterschiede versteht, vermeidet Missverständnisse.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS1 =>
      'Wenn dich etwas verwirrt, was die andere Person sagt oder tut, geh von guter Absicht aus und frag nach, statt voreilige Schlüsse zu ziehen.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2 =>
      'Kulturelle Kommunikationsunterschiede, die du kennen solltest';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I0 =>
      'Direkter vs. indirekter Kommunikationsstil';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I1 =>
      'Normen zu persönlichem Abstand und Körperkontakt';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I2 =>
      'Erwartungen an Blickkontakt (in manchen Kulturen gilt direkter Blickkontakt als respektlos)';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I3 =>
      'Einstellungen zu Pünktlichkeit und Zeit';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I4 =>
      'Bräuche und Erwartungen rund ums Schenken';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I5 =>
      'Die Rolle von Humor und welche Themen tabu sind';

  @override
  String get safetyAcademyLsnCulturalCommunicationS3 =>
      'Im Zweifel: offen kommunizieren. Ein einfaches „Ich möchte sichergehen, dass ich dich richtig verstehe“ hilft enorm, kulturelle Gräben zu überbrücken.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0 =>
      'Die Person, mit der du sprichst, vermeidet direkten Blickkontakt. Was solltest du denken?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O0 =>
      'Sie hat kein Interesse an dir';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O1 => 'Sie ist unehrlich';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O2 =>
      'Es kann eine kulturelle Norm sein – unterstelle keine schlechte Absicht';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O3 =>
      'Sie ist schüchtern und braucht mehr Ermutigung';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0Exp =>
      'In vielen Kulturen ist es ein Zeichen von Respekt, direkten Blickkontakt zu meiden – nicht von Desinteresse oder Unehrlichkeit.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1 =>
      'Was ist der beste Ansatz, wenn kulturelle Kommunikationsunterschiede für Verwirrung sorgen?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O0 =>
      'Vom Schlimmsten ausgehen';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O1 =>
      'Es ignorieren und hoffen, dass es sich von selbst klärt';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O2 =>
      'Mit offenem Geist um Klärung bitten';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O3 =>
      'Ihr sagen, sie solle mehr so kommunizieren wie du';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1Exp =>
      'Offene, wertfreie Kommunikation ist der beste Weg, mit kulturellen Unterschieden umzugehen.';

  @override
  String get safetyAcademyModOnlineSafetyTitle =>
      'Online-Sicherheit: Grundlagen';

  @override
  String get safetyAcademyModOnlineSafetyDesc =>
      'Lerne, deine Identität zu schützen und mögliche Betrugsversuche zu erkennen, wenn du Menschen online kennenlernst.';

  @override
  String get safetyAcademyLsnProfileProtectionTitle => 'Profilschutz';

  @override
  String get safetyAcademyLsnProfileProtectionS0 =>
      'Dein Profil ist dein erster Eindruck, kann aber auch persönliche Informationen preisgeben, wenn du nicht aufpasst. Wer das richtige Maß findet, bleibt sicher und zeigt trotzdem seine Persönlichkeit.';

  @override
  String get safetyAcademyLsnProfileProtectionS1 =>
      'Verwende ein Foto, das du nicht in deinen anderen Social-Media-Profilen nutzt. Über die umgekehrte Bildersuche lassen sich Konten miteinander verknüpfen.';

  @override
  String get safetyAcademyLsnProfileProtectionS2 =>
      'Gib in deiner Bio niemals deinen vollständigen Namen, deinen Arbeitsplatz, deine Wohnadresse oder deine Telefonnummer an.';

  @override
  String get safetyAcademyLsnProfileProtectionS3 =>
      'Checkliste für ein sicheres Profil';

  @override
  String get safetyAcademyLsnProfileProtectionS3I0 =>
      'Erkennbare Orientierungspunkte in der Nähe deines Zuhauses entfernen oder herausschneiden';

  @override
  String get safetyAcademyLsnProfileProtectionS3I1 =>
      'Nur Vornamen oder Spitznamen verwenden';

  @override
  String get safetyAcademyLsnProfileProtectionS3I2 =>
      'Standort-Metadaten in hochgeladenen Fotos deaktivieren';

  @override
  String get safetyAcademyLsnProfileProtectionS3I3 =>
      'Fotos in Arbeitskleidung oder mit sichtbarem Dienstausweis vermeiden';

  @override
  String get safetyAcademyLsnProfileProtectionS3I4 =>
      'Dein Profil aus der Sicht einer fremden Person prüfen';

  @override
  String get safetyAcademyLsnProfileProtectionS4 =>
      'Ein gut gestaltetes Profil verbindet Offenheit mit Privatsphäre. Teile deine Interessen und Werte, aber heb dir Details wie deinen Tagesablauf oder dein Wohnviertel für spätere Gespräche auf.';

  @override
  String get safetyAcademyLsnProfileProtectionQ0 =>
      'Was davon kannst du bedenkenlos in dein Profil aufnehmen?';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O0 => 'Deine Wohnadresse';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O1 => 'Deine Lieblingshobbys';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O2 =>
      'Name und Abteilung deines Arbeitgebers';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O3 => 'Deine Telefonnummer';

  @override
  String get safetyAcademyLsnProfileProtectionQ0Exp =>
      'Hobbys sind ideale Gesprächsaufhänger, ohne persönliche Details preiszugeben, mit denen man dich ausfindig machen könnte.';

  @override
  String get safetyAcademyLsnProfileProtectionQ1 =>
      'Warum solltest du in deinem Profil einzigartige Fotos verwenden?';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O0 =>
      'Um mehr Profilaufrufe zu bekommen';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O1 =>
      'Weil soziale Apps Bilder komprimieren';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O2 =>
      'Damit die umgekehrte Bildersuche nicht zu deinen anderen Konten führt';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O3 =>
      'Einzigartige Fotos bekommen mehr Likes';

  @override
  String get safetyAcademyLsnProfileProtectionQ1Exp =>
      'Tools zur umgekehrten Bildersuche können dein Profil mit sozialen Medien, Blogs oder beruflichen Seiten verknüpfen und so deine volle Identität offenlegen.';

  @override
  String get safetyAcademyLsnProfileProtectionQ2 =>
      'Was solltest du prüfen, bevor du ein Foto hochlädst?';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O0 =>
      'Dass es einen schönen Filter hat';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O1 =>
      'Dass die Standort-Metadaten entfernt und keine erkennbaren Orientierungspunkte zu sehen sind';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O2 =>
      'Dass es kürzlich aufgenommen wurde';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O3 => 'Dass es ein Selfie ist';

  @override
  String get safetyAcademyLsnProfileProtectionQ2Exp =>
      'Foto-Metadaten (EXIF-Daten) können GPS-Koordinaten enthalten. Auch Orientierungspunkte wie Straßenschilder oder Gebäudenamen können verraten, wo du bist.';

  @override
  String get safetyAcademyLsnScamRecognitionTitle => 'Betrug erkennen';

  @override
  String get safetyAcademyLsnScamRecognitionS0 =>
      'Identitäts- und Geldbetrug kostet Opfer weltweit jedes Jahr Milliarden. Betrüger bauen schnell eine emotionale Bindung auf und nutzen sie dann für Geld oder persönliche Daten aus. Wer die Anzeichen kennt, kann sich schützen.';

  @override
  String get safetyAcademyLsnScamRecognitionS1 =>
      'Wenn dich jemand kurz nach dem Kennenlernen online um Geld, Gutscheinkarten, Kryptowährung oder finanzielle Hilfe bittet -- egal wie überzeugend die Geschichte ist --, handelt es sich fast sicher um Betrug.';

  @override
  String get safetyAcademyLsnScamRecognitionS2 =>
      'Mach früh einen Videoanruf. Betrüger meiden Live-Videos, weil dabei falsche Identitäten auffliegen. Wenn jemand Videoanrufen immer wieder ausweicht, sei vorsichtig.';

  @override
  String get safetyAcademyLsnScamRecognitionS3 =>
      'Typische Warnzeichen für Betrug';

  @override
  String get safetyAcademyLsnScamRecognitionS3I0 =>
      'Das Profil wirkt zu perfekt (Fotos wie von einem Model, Traumkarriere)';

  @override
  String get safetyAcademyLsnScamRecognitionS3I1 =>
      'Gibt an, im Auslandseinsatz beim Militär, auf einer Bohrinsel oder international geschäftlich tätig zu sein';

  @override
  String get safetyAcademyLsnScamRecognitionS3I2 =>
      'Zeigt ungewöhnlich schnell intensive Zuneigung oder Schmeicheleien';

  @override
  String get safetyAcademyLsnScamRecognitionS3I3 =>
      'Weicht Videoanrufen oder persönlichen Treffen aus';

  @override
  String get safetyAcademyLsnScamRecognitionS3I4 =>
      'Bittet um Geld für Notfälle, Reisen oder Arztrechnungen';

  @override
  String get safetyAcademyLsnScamRecognitionS3I5 =>
      'Drängt darauf, das Gespräch schnell auf eine andere Plattform zu verlagern';

  @override
  String get safetyAcademyLsnScamRecognitionS4 =>
      'Wenn du Betrug vermutest, brich den Kontakt sofort ab. Melde das Profil in der App und erwäge, Anzeige bei den örtlichen Behörden zu erstatten.';

  @override
  String get safetyAcademyLsnScamRecognitionQ0 =>
      'Jemand, mit dem du dich vor einer Woche verbunden hast, sagt, du bedeutest ihm alles, und bittet um Geld, um dich zu besuchen. Was solltest du tun?';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O0 =>
      'Das Geld schicken – die Person wirkt aufrichtig';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O1 =>
      'Genauer nachfragen, wofür das Geld gebraucht wird';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O2 =>
      'Das als typisches Betrugsmuster erkennen und die Person melden';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O3 =>
      'Anbieten, das Flugticket direkt zu kaufen';

  @override
  String get safetyAcademyLsnScamRecognitionQ0Exp =>
      'Sehr schnell eine intensive emotionale Bindung aufzubauen und dann um Geld zu bitten, ist das typische Muster von Geldbetrug. Melden und blockieren.';

  @override
  String get safetyAcademyLsnScamRecognitionQ1 =>
      'Welcher Beruf wird von Betrügern häufig als Tarngeschichte benutzt?';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O0 => 'Lehrkraft vor Ort';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O1 => 'Soldat im Auslandseinsatz';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O2 =>
      'Barista aus der Nachbarschaft';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O3 =>
      'Büroangestellte in der Nähe';

  @override
  String get safetyAcademyLsnScamRecognitionQ1Exp =>
      'Betrüger geben oft einen Militäreinsatz, Offshore-Arbeit oder internationale Geschäfte an, um zu erklären, warum sie sich nicht persönlich treffen oder per Video telefonieren können.';

  @override
  String get safetyAcademyLsnScamRecognitionQ2 =>
      'Was ist ein guter erster Schritt, um zu prüfen, ob jemand echt ist?';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O0 =>
      'Nach der Wohnadresse fragen';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O1 =>
      'Einen Videoanruf vorschlagen';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O2 =>
      'Geld schicken, um die Reaktion zu testen';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O3 =>
      'Auf allen Social-Media-Plattformen nach der Person suchen';

  @override
  String get safetyAcademyLsnScamRecognitionQ2Exp =>
      'Ein Videoanruf ist eine der einfachsten Möglichkeiten zu prüfen, ob jemand wirklich der ist, für den er sich ausgibt. Betrüger meiden Live-Videos in der Regel um jeden Preis.';

  @override
  String get safetyAcademyLsnRedFlagsTitle => 'Warnzeichen im Verhalten';

  @override
  String get safetyAcademyLsnRedFlagsS0 =>
      'Neben Betrug gibt es Verhaltensmuster, die auf kontrollierende, manipulative oder potenziell gefährliche Menschen hinweisen können. Wenn du sie früh erkennst, kannst du dich vor schädlichen Situationen bewahren.';

  @override
  String get safetyAcademyLsnRedFlagsS1 =>
      'Wer dich drängt, intime Fotos zu schicken, dich sofort zu treffen oder dich von Freunden zurückzuziehen, zeigt kontrollierendes Verhalten.';

  @override
  String get safetyAcademyLsnRedFlagsS2 => 'Warnzeichen im Verhalten';

  @override
  String get safetyAcademyLsnRedFlagsS2I0 =>
      'Übertriebene Eifersucht oder Besitzansprüche, noch bevor ihr euch getroffen habt';

  @override
  String get safetyAcademyLsnRedFlagsS2I1 =>
      'Druck, persönliche Informationen oder intime Inhalte preiszugeben';

  @override
  String get safetyAcademyLsnRedFlagsS2I2 =>
      'Wütend werden, wenn du nicht sofort antwortest';

  @override
  String get safetyAcademyLsnRedFlagsS2I3 =>
      'Deine klar geäußerten Grenzen missachten';

  @override
  String get safetyAcademyLsnRedFlagsS2I4 =>
      'Dir Schuldgefühle machen, wenn du Zeit mit anderen verbringst';

  @override
  String get safetyAcademyLsnRedFlagsS2I5 =>
      'Widersprüchliche Geschichten über sich selbst';

  @override
  String get safetyAcademyLsnRedFlagsS3 =>
      'Vertrau deinem Bauchgefühl. Wenn dir ein Gespräch unangenehm ist, schuldest du niemandem eine Erklärung. Es ist immer in Ordnung, nicht mehr zu antworten, zu blockieren oder zu melden.';

  @override
  String get safetyAcademyLsnRedFlagsS4 =>
      'Gesunde Verbindungen beruhen auf gegenseitigem Respekt. Wer dich wirklich mag, respektiert dein Tempo, deine Grenzen und deine Selbstbestimmung.';

  @override
  String get safetyAcademyLsnRedFlagsQ0 =>
      'Ein neuer Kontakt ist verärgert, wenn du eine Stunde für eine Antwort brauchst. Was bedeutet das?';

  @override
  String get safetyAcademyLsnRedFlagsQ0O0 => 'Die Person mag dich wirklich';

  @override
  String get safetyAcademyLsnRedFlagsQ0O1 =>
      'Die Person ist von dem Gespräch begeistert';

  @override
  String get safetyAcademyLsnRedFlagsQ0O2 =>
      'Möglicherweise kontrollierendes Verhalten';

  @override
  String get safetyAcademyLsnRedFlagsQ0O3 =>
      'Die Person ist einfach nur ängstlich';

  @override
  String get safetyAcademyLsnRedFlagsQ0Exp =>
      'Sich über Antwortzeiten zu ärgern, bevor ihr euch überhaupt getroffen habt, ist ein Zeichen für kontrollierendes Verhalten. Jeder hat das Recht auf seinen eigenen Zeitplan.';

  @override
  String get safetyAcademyLsnRedFlagsQ1 =>
      'Wie reagierst du am besten, wenn dich jemand zu intimen Fotos drängt?';

  @override
  String get safetyAcademyLsnRedFlagsQ1O0 =>
      'Sie schicken, um den Frieden zu wahren';

  @override
  String get safetyAcademyLsnRedFlagsQ1O1 =>
      'Entschieden ablehnen und die Person blockieren und melden, wenn sie nicht lockerlässt';

  @override
  String get safetyAcademyLsnRedFlagsQ1O2 =>
      'Die Person bitten, zuerst ihre zu schicken';

  @override
  String get safetyAcademyLsnRedFlagsQ1O3 =>
      'Versprechen, sie später zu schicken';

  @override
  String get safetyAcademyLsnRedFlagsQ1Exp =>
      'Du solltest dich nie unter Druck gesetzt fühlen, intime Inhalte zu teilen. Ein respektvoller Mensch akzeptiert deine Entscheidung, ohne zu drängen.';

  @override
  String get safetyAcademyLsnRedFlagsQ2 =>
      'Was ist in den ersten Gesprächen ein gesundes Zeichen?';

  @override
  String get safetyAcademyLsnRedFlagsQ2O0 =>
      'Die Person will deinen genauen Tagesablauf wissen';

  @override
  String get safetyAcademyLsnRedFlagsQ2O1 =>
      'Die Person respektiert dein Tempo und deine Grenzen';

  @override
  String get safetyAcademyLsnRedFlagsQ2O2 =>
      'Sie erklären dir schon in den ersten Tagen intensive Gefühle';

  @override
  String get safetyAcademyLsnRedFlagsQ2O3 =>
      'Die Person verlangt, dass du in der App mit niemand anderem mehr schreibst';

  @override
  String get safetyAcademyLsnRedFlagsQ2Exp =>
      'Respekt vor Tempo und Grenzen ist die Grundlage einer gesunden Verbindung. Alles andere in dieser Liste ist ein mögliches Warnzeichen.';

  @override
  String get safetyAcademyModEmotionalIntelligenceTitle =>
      'Emotionale Intelligenz';

  @override
  String get safetyAcademyModEmotionalIntelligenceDesc =>
      'Verstehe Bindungsstile und Sprachen der Wertschätzung und stärke dein emotionales Bewusstsein.';

  @override
  String get safetyAcademyLsnAttachmentStylesTitle => 'Bindungsstile';

  @override
  String get safetyAcademyLsnAttachmentStylesS0 =>
      'Die Bindungstheorie erklärt, wie unsere frühen Beziehungen prägen, wie wir uns als Erwachsene mit anderen Menschen verbinden. Wenn du deinen Bindungsstil kennst, kannst du gesündere Freundschaften aufbauen.';

  @override
  String get safetyAcademyLsnAttachmentStylesS1 =>
      'Die vier wichtigsten Bindungsstile sind: sicher, ängstlich, vermeidend und desorganisiert. Die meisten Menschen sind eine Mischung, und Bindungsstile können sich mit Bewusstsein und Arbeit an sich selbst verändern.';

  @override
  String get safetyAcademyLsnAttachmentStylesS2 => 'Die vier Bindungsstile';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I0 =>
      'Sicher: fühlt sich mit Nähe wohl, vertrauensvoll, kommunikativ';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I1 =>
      'Ängstlich: sehnt sich nach Nähe, fürchtet aber Zurückweisung, braucht oft zusätzliche Bestätigung';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I2 =>
      'Vermeidend: legt großen Wert auf Unabhängigkeit, zieht sich eventuell zurück, wenn es enger wird';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I3 =>
      'Desorganisiert: Mischung aus ängstlich und vermeidend, oft durch schwierige frühe Erfahrungen';

  @override
  String get safetyAcademyLsnAttachmentStylesS3 =>
      'Wenn du deinen Stil kennst, verstehst du deine Reaktionen besser. Neigst du zu einem ängstlichen Bindungsstil, erkennst du vielleicht, dass dein Drang, ständig zu schreiben, aus Angst entsteht und nicht aus echtem Bedürfnis. Bist du eher vermeidend, bemerkst du vielleicht, dass du dich verschließt, wenn die Gefühle hochkochen.';

  @override
  String get safetyAcademyLsnAttachmentStylesS4 =>
      'Den Bindungsstil eines Freundes zu verstehen, hilft dir, mit Empathie statt Frust zu reagieren. Wenn sich ein vermeidender Freund zurückzieht, ist das keine Ablehnung -- es ist seine Bewältigungsstrategie.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0 =>
      'Ein Freund braucht viel Bestätigung und wird unruhig, wenn du nicht schnell antwortest. Welcher Bindungsstil könnte das sein?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O0 => 'Sicher';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O1 => 'Ängstlich';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O2 => 'Vermeidend';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O3 => 'Desorganisiert';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0Exp =>
      'Ein ängstlicher Bindungsstil ist geprägt von einem starken Wunsch nach Nähe und der Angst vor Zurückweisung, was oft zu einem Bedürfnis nach häufiger Bestätigung führt.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1 =>
      'Was ist die gesündeste Reaktion, wenn du deine Bindungsmuster erkennst?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O0 =>
      'Akzeptieren, dass sie sich nicht ändern lassen';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O1 =>
      'Deinen Eltern die Schuld an deinem Stil geben';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O2 =>
      'Das Bewusstsein nutzen, um besser zu kommunizieren und auf eine sichere Bindung hinzuarbeiten';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O3 =>
      'Nur Zeit mit Menschen verbringen, die denselben Stil haben';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1Exp =>
      'Bindungsstile können sich durch Selbstreflexion, Kommunikation und manchmal professionelle Unterstützung weiterentwickeln.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2 =>
      'Jemand mit einem vermeidenden Bindungsstil könnte:';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O0 =>
      'Mehrere Nachrichten schicken, wenn du nicht schnell antwortest';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O1 =>
      'Sich zurückziehen oder verschließen, wenn eine Freundschaft emotional eng wird';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O2 =>
      'Jeden Moment gemeinsam verbringen wollen';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O3 =>
      'Von Anfang an sehr offen über die eigenen Gefühle sprechen';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2Exp =>
      'Vermeidende Bindung zeigt sich oft im Rückzug, wenn die emotionale Nähe wächst -- als Selbstschutzmechanismus.';

  @override
  String get safetyAcademyLsnLoveLanguagesTitle => 'Sprachen der Wertschätzung';

  @override
  String get safetyAcademyLsnLoveLanguagesS0 =>
      'Das Konzept der Sprachen der Wertschätzung, angelehnt an die Arbeit von Dr. Gary Chapman, besagt, dass Menschen Wertschätzung auf fünf grundlegende Arten ausdrücken und empfangen. Wenn du deine und die deiner Freunde kennst, stärkst du eure Verbindungen.';

  @override
  String get safetyAcademyLsnLoveLanguagesS1 =>
      'Die fünf Sprachen der Wertschätzung';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I0 =>
      'Worte der Anerkennung: Komplimente, Ermutigung und ausgesprochene Wertschätzung';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I1 =>
      'Zweisamkeit: ungeteilte Aufmerksamkeit und echte Präsenz';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I2 =>
      'Geschenke erhalten: Aufmerksame Zeichen der Wertschätzung (nicht eine Frage des Preises)';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I3 =>
      'Hilfsbereitschaft: Taten, die das Leben leichter machen oder Fürsorge zeigen';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I4 =>
      'Freundliche Gesten: Ein Händedruck, ein High Five oder eine Umarmung, wenn sie willkommen ist';

  @override
  String get safetyAcademyLsnLoveLanguagesS2 =>
      'Achte darauf, wie jemand Wertschätzung zeigt -- das ist wahrscheinlich seine Sprache der Wertschätzung. Wer dir ständig Komplimente macht, schätzt vermutlich Worte der Anerkennung.';

  @override
  String get safetyAcademyLsnLoveLanguagesS3 =>
      'Unterschiedliche Sprachen der Wertschätzung sind häufig und gut zu bewältigen. Der Schlüssel ist Kommunikation: Sag deinen Freunden, wodurch du dich wertgeschätzt fühlst, und stell ihnen dieselbe Frage.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0 =>
      'Ein Freund nimmt sich immer Zeit für dich und legt beim Gespräch das Handy weg. Seine Sprache der Wertschätzung ist wahrscheinlich:';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O0 => 'Lob und Anerkennung';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O1 => 'Zweisamkeit';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O2 => 'Geschenke';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O3 => 'Freundliche Gesten';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0Exp =>
      'Ungeteilte Aufmerksamkeit und echte Präsenz sind das Kennzeichen von Zeit zu zweit als Sprache der Wertschätzung.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1 =>
      'Dir sind Worte der Anerkennung wichtig, aber ein Freund zeigt Wertschätzung durch Hilfsbereitschaft. Was solltest du tun?';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O0 =>
      'Akzeptieren, dass ihr nicht zusammenpasst';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O1 =>
      'Sag ihm, was du brauchst, und lerne zu erkennen, wie er Wertschätzung zeigt';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O2 =>
      'Deine Sprache der Wertschätzung an seine anpassen';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O3 => 'Den Unterschied ignorieren';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1Exp =>
      'Kommunikation ist der Schlüssel. Sag, was du brauchst, und lerne gleichzeitig zu schätzen, wie dein Freund zeigt, dass du ihm wichtig bist.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessTitle =>
      'Emotionales Bewusstsein';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS0 =>
      'Emotionales Bewusstsein ist die Fähigkeit, die eigenen Gefühle zu erkennen, zu verstehen und zu steuern und dabei auf die Gefühle anderer zu achten. Beim Kennenlernen neuer Menschen verhindert diese Fähigkeit impulsive Entscheidungen und schafft tiefere Verbindungen.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS1 =>
      'Bevor du auf eine frustrierende Nachricht antwortest, halte inne und finde heraus, was du eigentlich fühlst. Bist du verletzt? Ängstlich? Enttäuscht? Ein Gefühl zu benennen nimmt ihm seine Macht.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2 =>
      'Emotionales Bewusstsein entwickeln';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I0 =>
      'Übe, deine Gefühle im Laufe des Tages zu benennen';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I1 =>
      'Achte auf körperliche Empfindungen, die mit Gefühlen verbunden sind (Enge in der Brust = Angst)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I2 =>
      'Schreibe Tagebuch über deine sozialen Erlebnisse und emotionalen Reaktionen';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I3 =>
      'Unterscheide zwischen Reagieren (impulsiv) und Antworten (überlegt)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I4 =>
      'Gewöhne dir eine Pause an: Warte, bevor du emotionale Nachrichten abschickst';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS3 =>
      'Emotionales Bewusstsein bedeutet nicht, Gefühle zu unterdrücken. Es bedeutet, sie gut genug zu verstehen, um selbst zu entscheiden, wie du mit ihnen umgehst.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS4 =>
      'Wenn du sagen kannst: „Ich war verletzt, als du unsere Pläne abgesagt hast“ statt „Ich bin dir offensichtlich egal“, verwandelst du Konflikt in Verbindung. Das ist emotionale Intelligenz in Aktion.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0 =>
      'Ein neuer Freund sagt kurzfristig ab und du bist wütend. Was ist die emotional bewusste Reaktion?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O0 =>
      'Sofort eine wütende Nachricht schicken';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O1 =>
      'Die Person zur Strafe ghosten';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O2 =>
      'Innehalten, deine Gefühle erkennen und dann ruhig mitteilen, wie dich die Absage getroffen hat';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O3 =>
      'So tun, als wäre es dir egal';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0Exp =>
      'Innezuhalten, deine Gefühle zu erkennen und sie dann ruhig mitzuteilen, führt zu besseren Ergebnissen als impulsives Reagieren.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1 =>
      'Was bedeutet emotionales Bewusstsein?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O0 => 'Niemals Gefühle zeigen';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O1 => 'Immer glücklich sein';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O2 =>
      'Gefühle erkennen und verstehen, um zu entscheiden, wie man mit ihnen umgeht';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O3 =>
      'Jedes Gefühl sofort ausdrücken, sobald du es spürst';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1Exp =>
      'Bei emotionalem Bewusstsein geht es ums Erkennen und Verstehen – das ermöglicht überlegte Antworten statt impulsiver Reaktionen.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2 =>
      'Was ist ein Beispiel für „Antworten“ statt „Reagieren“?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O0 =>
      'Sofort eine wütende Antwort tippen, sobald du dich aufregst';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O1 =>
      'Abwarten, über deine Gefühle nachdenken und dann eine durchdachte Nachricht formulieren';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O2 =>
      'Die Nachricht komplett ignorieren';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O3 =>
      'Vor dem Antworten bei Freunden Dampf ablassen';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2Exp =>
      'Antworten bedeutet, bewusst innezuhalten und nachzudenken, während Reagieren von der unmittelbaren Emotion gesteuert wird.';

  @override
  String get safetyAcademyModFirstMeetingTitle =>
      'Leitfaden fürs erste Treffen';

  @override
  String get safetyAcademyModFirstMeetingDesc =>
      'Wichtige Tipps für sichere, selbstbewusste erste Treffen mit Menschen, die du online kennenlernst.';

  @override
  String get safetyAcademyLsnPublicPlacesTitle =>
      'Treffen an öffentlichen Orten';

  @override
  String get safetyAcademyLsnPublicPlacesS0 =>
      'Jemanden aus einer App zum ersten Mal zu treffen, ist aufregend, aber Sicherheit geht immer vor. Der richtige Ort legt den Grundstein für ein angenehmes Treffen.';

  @override
  String get safetyAcademyLsnPublicPlacesS1 =>
      'Wähle für euer erstes Treffen ein belebtes Café, ein Restaurant oder einen öffentlichen Park. Wenn du den Ort kennst, bist du im Vorteil – du kennst die Ausgänge und das Personal.';

  @override
  String get safetyAcademyLsnPublicPlacesS2 =>
      'Willige für ein erstes Treffen nie ein, dich bei jemandem zu Hause, an einem abgelegenen Ort oder an einem dir unbekannten Ort zu treffen.';

  @override
  String get safetyAcademyLsnPublicPlacesS3 =>
      'Checkliste: Ort fürs erste Treffen';

  @override
  String get safetyAcademyLsnPublicPlacesS3I0 =>
      'Wähle einen öffentlichen, gut beleuchteten Ort';

  @override
  String get safetyAcademyLsnPublicPlacesS3I1 =>
      'Such dir einen Ort aus, den du kennst';

  @override
  String get safetyAcademyLsnPublicPlacesS3I2 =>
      'Achte darauf, dass andere Menschen vor Ort sind';

  @override
  String get safetyAcademyLsnPublicPlacesS3I3 =>
      'Prüfe, ob du vor Ort Handyempfang hast';

  @override
  String get safetyAcademyLsnPublicPlacesS3I4 =>
      'Hab einen Plan B, falls du schnell gehen musst';

  @override
  String get safetyAcademyLsnPublicPlacesQ0 =>
      'Welcher Ort ist für ein erstes Treffen am sichersten?';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O0 =>
      'Die Wohnung der anderen Person';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O1 =>
      'Ein belebtes Café in der Innenstadt';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O2 => 'Ein abgelegener Wanderweg';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O3 => 'Deine Wohnung';

  @override
  String get safetyAcademyLsnPublicPlacesQ0Exp =>
      'Ein belebtes Café ist öffentlich, es ist Personal vor Ort und du kannst bei Bedarf problemlos gehen.';

  @override
  String get safetyAcademyLsnPublicPlacesQ1 =>
      'Warum solltest du einen Ort wählen, den du kennst?';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O0 =>
      'Damit du die andere Person mit Empfehlungen beeindrucken kannst';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O1 =>
      'Weil du die Ausgänge, das Personal und die Umgebung kennst';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O2 =>
      'Es ist günstiger, wenn du die Karte kennst';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O3 =>
      'Es bringt keinen echten Vorteil';

  @override
  String get safetyAcademyLsnPublicPlacesQ1Exp =>
      'Wenn du den Ort kennst, weißt du, wie du schnell wegkommst und wen du um Hilfe bitten kannst, falls du dich unwohl fühlst.';

  @override
  String get safetyAcademyLsnSharingPlansTitle => 'Deine Pläne teilen';

  @override
  String get safetyAcademyLsnSharingPlansS0 =>
      'Einer Vertrauensperson von deinem Treffen mit jemand Neuem zu erzählen, ist eine der einfachsten und wirksamsten Sicherheitsmaßnahmen. Ein Sicherheitsbuddy kann sich bei dir melden und weiß, wo er suchen muss, falls etwas schiefgeht.';

  @override
  String get safetyAcademyLsnSharingPlansS1 =>
      'Teile das Profil der anderen Person, den Treffpunkt und deine voraussichtliche Rückkehrzeit mit einer Vertrauensperson. Vereinbart einen Kontrollanruf 30 Minuten nach Beginn des Treffens.';

  @override
  String get safetyAcademyLsnSharingPlansS2 =>
      'Infos für deine Vertrauensperson';

  @override
  String get safetyAcademyLsnSharingPlansS2I0 =>
      'Screenshot vom Profil der anderen Person';

  @override
  String get safetyAcademyLsnSharingPlansS2I1 =>
      'Name (oder Benutzername) der Person, die du triffst';

  @override
  String get safetyAcademyLsnSharingPlansS2I2 =>
      'Tag, Uhrzeit und Ort des Treffens';

  @override
  String get safetyAcademyLsnSharingPlansS2I3 =>
      'Deine voraussichtliche Rückkehrzeit';

  @override
  String get safetyAcademyLsnSharingPlansS2I4 =>
      'Vereinbarte Zeit, um dich zu melden (z. B. Anruf oder Nachricht)';

  @override
  String get safetyAcademyLsnSharingPlansS3 =>
      'Du kannst die Details des Treffens auch vorher an eine Vertrauensperson schicken. Vorsicht ist keine Schande -- die Person, die du triffst, sollte das verstehen.';

  @override
  String get safetyAcademyLsnSharingPlansQ0 =>
      'Was solltest du vor einem ersten Treffen mit einer Vertrauensperson teilen?';

  @override
  String get safetyAcademyLsnSharingPlansQ0O0 => 'Nur den Namen des Lokals';

  @override
  String get safetyAcademyLsnSharingPlansQ0O1 =>
      'Profil der anderen Person, Treffpunkt, Uhrzeit und voraussichtliche Rückkehr';

  @override
  String get safetyAcademyLsnSharingPlansQ0O2 => 'Nichts – das ist privat';

  @override
  String get safetyAcademyLsnSharingPlansQ0O3 =>
      'Nur eine Nachricht mit „Bin unterwegs“';

  @override
  String get safetyAcademyLsnSharingPlansQ0Exp =>
      'Je mehr Infos deine Vertrauensperson hat, desto besser kann sie helfen, falls etwas schiefgeht.';

  @override
  String get safetyAcademyLsnSharingPlansQ1 =>
      'Wann ist ein guter Zeitpunkt für einen Kontrollanruf?';

  @override
  String get safetyAcademyLsnSharingPlansQ1O0 => 'Nach dem Treffen';

  @override
  String get safetyAcademyLsnSharingPlansQ1O1 =>
      'Etwa 30 Minuten nach Beginn des Treffens';

  @override
  String get safetyAcademyLsnSharingPlansQ1O2 =>
      'Ein Kontrollanruf ist nicht nötig';

  @override
  String get safetyAcademyLsnSharingPlansQ1O3 =>
      'Bevor du zum Treffen aufbrichst';

  @override
  String get safetyAcademyLsnSharingPlansQ1Exp =>
      'Ein Kontrollanruf nach 30 Minuten gibt dir genug Zeit, die Situation einzuschätzen, und einen einfachen Ausweg, falls du dich unwohl fühlst.';

  @override
  String get safetyAcademyLsnTransportSafetyTitle => 'Sicher unterwegs';

  @override
  String get safetyAcademyLsnTransportSafetyS0 =>
      'Wie du zu einem Treffen hin- und zurückkommst, ist genauso wichtig wie der Treffpunkt. Wer die Kontrolle über seinen Transport behält, kann jederzeit gehen.';

  @override
  String get safetyAcademyLsnTransportSafetyS1 =>
      'Lass dich beim ersten Treffen nie von jemandem, den du gerade erst online kennengelernt hast, zu Hause abholen. Das verrät deine Adresse und macht dich für den Heimweg von ihm abhängig.';

  @override
  String get safetyAcademyLsnTransportSafetyS2 =>
      'Fahr selbst, nutze einen Fahrdienst oder öffentliche Verkehrsmittel. Halte dein Handy geladen und hab genug Geld für eine Notfall-Fahrt nach Hause dabei.';

  @override
  String get safetyAcademyLsnTransportSafetyS3 =>
      'Checkliste: Sicher unterwegs';

  @override
  String get safetyAcademyLsnTransportSafetyS3I0 =>
      'Organisiere deine Fahrt selbst';

  @override
  String get safetyAcademyLsnTransportSafetyS3I1 =>
      'Halte dein Handy voll aufgeladen';

  @override
  String get safetyAcademyLsnTransportSafetyS3I2 =>
      'Hab Geld für eine Notfall-Fahrt dabei';

  @override
  String get safetyAcademyLsnTransportSafetyS3I3 =>
      'Teile deinen Live-Standort mit einer Vertrauensperson';

  @override
  String get safetyAcademyLsnTransportSafetyS3I4 =>
      'Park an einem gut beleuchteten Ort, wenn du mit dem Auto kommst';

  @override
  String get safetyAcademyLsnTransportSafetyS3I5 =>
      'Lass deine Getränke nicht unbeaufsichtigt, wenn du kurz weggehst';

  @override
  String get safetyAcademyLsnTransportSafetyQ0 =>
      'Warum solltest du für ein erstes Treffen deinen eigenen Transport organisieren?';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O0 => 'Um Spritgeld zu sparen';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O1 =>
      'Damit du jederzeit gehen kannst und deine Adresse privat bleibt';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O2 => 'Um Staus zu vermeiden';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O3 =>
      'Weil man allein leichter einen Parkplatz findet';

  @override
  String get safetyAcademyLsnTransportSafetyQ0Exp =>
      'Mit eigenem Transport bist du nicht von der anderen Person abhängig und deine Wohnadresse bleibt privat.';

  @override
  String get safetyAcademyLsnTransportSafetyQ1 =>
      'Jemand, den du zum ersten Mal treffen wirst, bietet an, dich zu Hause abzuholen. Was solltest du tun?';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O0 =>
      'Annehmen – das ist eine nette Geste';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O1 =>
      'Höflich ablehnen und vorschlagen, euch direkt vor Ort zu treffen';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O2 =>
      'Statt deiner genauen Adresse eine Kreuzung in der Nähe angeben';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O3 =>
      'Annehmen, aber jemanden aus deinem Freundeskreis vom Fenster aus zusehen lassen';

  @override
  String get safetyAcademyLsnTransportSafetyQ1Exp =>
      'Wenn ihr euch direkt vor Ort trefft, bleibt deine Adresse privat und du bist unabhängig unterwegs.';

  @override
  String get gamificationAchFirstMatchName => 'Erste Verbindung';

  @override
  String get gamificationAchFirstMatchDesc =>
      'Erhalte dein erstes gegenseitiges Like';

  @override
  String get gamificationAchConversationStarterName => 'Gesprächsstarter';

  @override
  String get gamificationAchConversationStarterDesc => 'Starte 10 Gespräche';

  @override
  String get gamificationAchVideoChampionName => 'Video-Champion';

  @override
  String get gamificationAchVideoChampionDesc => 'Schließe 5 Videoanrufe ab';

  @override
  String get gamificationAchProfileMasterName => 'Profil-Meister';

  @override
  String get gamificationAchProfileMasterDesc =>
      'Fülle alle Profilbereiche zu 100 % aus';

  @override
  String get gamificationAchGlobeTrotterName => 'Weltenbummler';

  @override
  String get gamificationAchGlobeTrotterDesc =>
      'Verbinde dich mit Menschen aus 10+ Ländern';

  @override
  String get gamificationAchGenerousHeartName => 'Großzügige Seele';

  @override
  String get gamificationAchGenerousHeartDesc =>
      'Verschenke Münzen an deine Kontakte';

  @override
  String get gamificationAchDailyDedicationName => 'Tägliche Hingabe';

  @override
  String get gamificationAchDailyDedicationDesc => '7 Tage in Folge eingeloggt';

  @override
  String get gamificationAchSuperStarName => 'Superstar';

  @override
  String get gamificationAchSuperStarDesc => 'Erhalte 50+ Priority Connects';

  @override
  String get gamificationAchSocialButterflyName => 'Gesellige Seele';

  @override
  String get gamificationAchSocialButterflyDesc =>
      'Führe über 20 aktive Gespräche';

  @override
  String get gamificationAchPerfectWeekName => 'Perfekte Woche';

  @override
  String get gamificationAchPerfectWeekDesc =>
      'Schließe 7 Tage lang alle täglichen Herausforderungen ab';

  @override
  String get gamificationAchEarlyBirdName => 'Frühaufsteher';

  @override
  String get gamificationAchEarlyBirdDesc =>
      'Sende an 10 Tagen vor 9 Uhr Nachrichten';

  @override
  String get gamificationAchNightOwlName => 'Nachteule';

  @override
  String get gamificationAchNightOwlDesc =>
      'Sende an 10 Tagen nach 22 Uhr Nachrichten';

  @override
  String get gamificationAchCenturionName => 'Zenturio';

  @override
  String get gamificationAchCenturionDesc =>
      'Erreiche insgesamt 100 Verbindungen';

  @override
  String get gamificationAchSpeedDaterName => 'Kontakt-Sprinter';

  @override
  String get gamificationAchSpeedDaterDesc =>
      'Verbinde dich an einem Tag mit 10 Menschen';

  @override
  String get gamificationAchPhotoCollectorName => 'Fotosammler';

  @override
  String get gamificationAchPhotoCollectorDesc =>
      'Füge deinem Profil 6 Fotos hinzu';

  @override
  String get gamificationAchTrendSetterName => 'Trendsetter';

  @override
  String get gamificationAchTrendSetterDesc =>
      'Gehöre zu den ersten 1000 Nutzern';

  @override
  String get gamificationAchVerifiedName => 'Verifiziert';

  @override
  String get gamificationAchVerifiedDesc => 'Schließe die Fotoverifizierung ab';

  @override
  String get gamificationAchPremiumMemberName => 'Premium-Mitglied';

  @override
  String get gamificationAchPremiumMemberDesc => 'Abonniere Silber oder Gold';

  @override
  String get gamificationAchCoinCollectorName => 'Münzsammler';

  @override
  String get gamificationAchCoinCollectorDesc => 'Sammle 1000 Münzen';

  @override
  String get gamificationAchMonthlyStreakName => 'Monatliche Hingabe';

  @override
  String get gamificationAchMonthlyStreakDesc => '30 Tage in Folge eingeloggt';

  @override
  String get gamificationAchVocabularyBeginnerName => 'Wortentdecker';

  @override
  String get gamificationAchVocabularyBeginnerDesc =>
      'Verwende 100 verschiedene Wörter im Chat';

  @override
  String get gamificationAchVocabularyIntermediateName => 'Wortschmied';

  @override
  String get gamificationAchVocabularyIntermediateDesc =>
      'Verwende 500 verschiedene Wörter im Chat';

  @override
  String get gamificationAchVocabularyAdvancedName => 'Wortschatz-Experte';

  @override
  String get gamificationAchVocabularyAdvancedDesc =>
      'Verwende 1000 verschiedene Wörter im Chat';

  @override
  String get gamificationAchVocabularyMasterName => 'Wortschatz-Meister';

  @override
  String get gamificationAchVocabularyMasterDesc =>
      'Verwende 5000 verschiedene Wörter im Chat';

  @override
  String get gamificationAchRareWordHunterName => 'Jäger seltener Wörter';

  @override
  String get gamificationAchRareWordHunterDesc =>
      'Verwende 50 seltene Wörter (Häufigkeitswert unter 50)';

  @override
  String gamificationRewardCoinsPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count Münzen',
      one: '+1 Münze',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardBadgePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count Abzeichen',
      one: '+1 Abzeichen',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardBoostPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count Boosts',
      one: '+1 Boost',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardWithValue(String reward) {
    return 'Belohnung: $reward';
  }

  @override
  String get gamificationRewardBadge => 'Abzeichen';

  @override
  String get gamificationVip => 'VIP';

  @override
  String get gamificationRewardsTitle => 'Belohnungen';

  @override
  String gamificationXpToNextLevel(String xp) {
    return 'Noch $xp XP bis zum nächsten Level';
  }

  @override
  String get gamificationStreakDayUnitOne => 'Tag';

  @override
  String get gamificationStreakDayUnitOther => 'Tage';

  @override
  String get gamificationOnFire => '🎉 Du bist on fire!';

  @override
  String gamificationUserFallback(String id) {
    return 'Nutzer $id';
  }

  @override
  String gamificationNoticeAchievementUnlocked(String name, String reward) {
    return '$name freigeschaltet! $reward';
  }

  @override
  String gamificationNoticeAchievementReady(String name) {
    return 'Erfolg geschafft! Bereit zum Freischalten: $name';
  }

  @override
  String gamificationNoticeLevelUp(int level) {
    return 'Level-up! Du hast Level $level erreicht!';
  }

  @override
  String get gamificationNoticeVip =>
      'Glückwunsch! Du hast den VIP-Status erreicht! 👑';

  @override
  String gamificationNoticeLevelRewardsClaimed(int level, String rewards) {
    return 'Belohnungen für Level $level abgeholt! $rewards';
  }

  @override
  String gamificationNoticeChallengeRewardsClaimed(
      String name, String rewards) {
    return 'Belohnungen für $name abgeholt! $rewards';
  }

  @override
  String gamificationNoticeFeatureLocked(int count, String feature, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$feature wird ab Level $level freigeschaltet. Noch $count Level!',
      one: '$feature wird ab Level $level freigeschaltet. Noch 1 Level!',
    );
    return '$_temp0';
  }

  @override
  String get gamificationFeatureCustomChatThemes => 'Eigene Chat-Designs';

  @override
  String get gamificationFeatureProfileVideo => 'Profilvideo';

  @override
  String get gamificationFeatureAdvancedFilters => 'Erweiterte Filter';

  @override
  String get gamificationFeatureUnlimitedRewinds => 'Unbegrenztes Zurückspulen';

  @override
  String get gamificationFeatureVipBadge => 'VIP-Abzeichen';

  @override
  String get gamificationFeaturePriorityLikes => 'Prioritäts-Likes';

  @override
  String get gamificationLevelRewardBronzeFrame => 'Bronze-Rahmen';

  @override
  String get gamificationLevelRewardSilverFrame => 'Silber-Rahmen';

  @override
  String get gamificationLevelRewardGoldFrame => 'Gold-Rahmen';

  @override
  String get gamificationLevelRewardPlatinumFrame => 'Platin-Rahmen';

  @override
  String get gamificationLevelRewardDiamondFrame => 'Diamant-Rahmen';

  @override
  String get gamificationLevelRewardLegendaryFrame => 'Legendärer Rahmen';

  @override
  String get gamificationLevelRewardVipCrown => 'VIP-Krone';

  @override
  String gamificationLevelRewardMaxLevelBadge(int level) {
    return 'Level-$level-Abzeichen';
  }

  @override
  String gamificationLevelRewardBonusCoins(int count) {
    return '$count Bonus-Münzen';
  }

  @override
  String get gamificationMissionAttend3Events => 'Besuche 3 Events';

  @override
  String get gamificationMissionConnect3Countries =>
      'Vernetze dich mit Menschen aus 3 Ländern';

  @override
  String get gamificationMissionJoinCommunity => 'Tritt einer Community bei';

  @override
  String get gamificationMissionCompleteProfile =>
      'Vervollständige dein Profil';

  @override
  String get gamificationMissionAdd5People => 'Füge 5 Personen hinzu';

  @override
  String get updateRequiredTitle => 'Update erforderlich';

  @override
  String get updateRequiredMessage =>
      'Eine neue Version von GreenGo ist verfügbar. Bitte aktualisiere, um die App weiter zu nutzen.';

  @override
  String get updateAvailableTitle => 'Update verfügbar';

  @override
  String get updateAvailableMessage =>
      'Eine neue Version von GreenGo mit Verbesserungen und neuen Funktionen ist verfügbar.';

  @override
  String get updateVersionCurrent => 'Aktuell';

  @override
  String get updateVersionRequired => 'Erforderlich';

  @override
  String get updateVersionAvailable => 'Verfügbar';

  @override
  String get updateVersionLatest => 'Neueste';

  @override
  String get updateWhatsNew => 'Neuigkeiten';

  @override
  String get updateNowButton => 'Jetzt aktualisieren';

  @override
  String get updateButton => 'Aktualisieren';

  @override
  String get maintenanceTitle => 'Wartungsarbeiten';

  @override
  String get maintenanceCheckBackSoon => 'Schau bald wieder vorbei';

  @override
  String get maintenanceDefaultMessage =>
      'Wir führen gerade Wartungsarbeiten durch. Bitte versuche es später erneut.';

  @override
  String get countdownAlmostThere => 'Fast geschafft!';

  @override
  String get countdownVipEarlyAccess => 'VIP-Frühzugang';

  @override
  String countdownLaunchDate(String date) {
    return 'Starttermin: $date';
  }

  @override
  String get countdownTimeUntilLaunch => 'Zeit bis zum Start';

  @override
  String get countdownWantEarlierAccess => 'Früher rein?';

  @override
  String countdownUpgradeForEarlierAccess(String date) {
    return 'Upgrade dein Paket, um schon vor dem $date Zugang zu bekommen!';
  }

  @override
  String get countdownLaunchDay => 'Starttag!';

  @override
  String get countdownNowAvailable => 'GreenGo Chat ist jetzt verfügbar';

  @override
  String celebrationWelcomeToTier(String tier) {
    return 'Willkommen bei $tier!';
  }

  @override
  String get celebrationMembershipActive =>
      'Deine Premium-Mitgliedschaft ist jetzt aktiv';

  @override
  String get celebrationUnlimitedLikes => 'Unbegrenzte Likes';

  @override
  String get celebrationSeeWhoLikedYou => 'Sieh, wer sich verbinden möchte';

  @override
  String celebrationPerDay(int count) {
    return '$count/Tag';
  }

  @override
  String get celebrationExclusiveEvents => 'Exklusive Events';

  @override
  String purchaseSuccessCoinsAdded(int count) {
    return '$count GreenGo-Münzen hinzugefügt!';
  }

  @override
  String get pushChannelMainName => 'GreenGo-Benachrichtigungen';

  @override
  String get pushChannelMainDescription =>
      'Nachrichten, Likes, Events und Aktivitäten';

  @override
  String get pushChannelAnnouncementsName => 'Ankündigungen';

  @override
  String get pushChannelAnnouncementsDescription =>
      'Mitteilungen und Ankündigungen von GreenGo';

  @override
  String get pushChannelSummaryName => 'Aktivitätsübersicht';

  @override
  String get pushChannelSummaryDescription =>
      'Gebündelte Aktivitätsbenachrichtigungen';

  @override
  String get pushChannelGeneralName => 'Allgemein';

  @override
  String get pushChannelGeneralDescription => 'Allgemeine Benachrichtigungen';

  @override
  String get usageLimitTypeConnects => 'Verbindungen';

  @override
  String get usageLimitTypePasses => 'Passes';

  @override
  String get usageLimitTypePriorityConnects => 'Prioritätsverbindungen';

  @override
  String get usageLimitTypeDailyPriorityConnects =>
      'tägliche Prioritätsverbindungen';

  @override
  String get usageLimitTypeSwipes => 'Swipes';

  @override
  String get usageLimitTypeMessages => 'Nachrichten';

  @override
  String get usageLimitTypeMediaSends => 'Medien-Sendungen';

  @override
  String get usageLimitTypeDirectMatches => 'Direct Connects';

  @override
  String get usageLimitTypeConnections => 'Verbindungen';

  @override
  String usageLimitUnlimited(String type) {
    return 'Unbegrenzt: $type';
  }

  @override
  String usageLimitRemainingThisHour(int remaining, String type) {
    return 'Noch $remaining $type in dieser Stunde';
  }

  @override
  String usageLimitRemainingToday(int remaining, String type) {
    return 'Noch $remaining $type heute';
  }

  @override
  String usageLimitConnectsHourly(int limit) {
    return 'Du hast alle $limit Verbindungen dieser Stunde genutzt. Mach ein Upgrade für mehr oder warte bis zur nächsten Stunde.';
  }

  @override
  String usageLimitPassesHourly(int limit) {
    return 'Du hast alle $limit Passes dieser Stunde genutzt. Mach ein Upgrade für mehr oder warte bis zur nächsten Stunde.';
  }

  @override
  String usageLimitPriorityUnavailable(String tier) {
    return 'Prioritätsverbindungen sind im $tier-Paket nicht verfügbar. Mach ein Upgrade, um diese Funktion freizuschalten!';
  }

  @override
  String usageLimitPriorityHourly(int limit) {
    return 'Du hast alle $limit Prioritätsverbindungen dieser Stunde genutzt. Mach ein Upgrade für mehr oder warte bis zur nächsten Stunde.';
  }

  @override
  String usageLimitPriorityDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'Du hast deine $limit kostenlosen Prioritätsverbindungen für heute genutzt. Nutze Münzen für mehr oder warte bis morgen.',
      one:
          'Du hast deine 1 kostenlose Prioritätsverbindung für heute genutzt. Nutze Münzen für mehr oder warte bis morgen.',
    );
    return '$_temp0';
  }

  @override
  String usageLimitSwipesDaily(int limit) {
    return 'Du hast alle $limit Swipes für heute genutzt. Mach ein Upgrade für mehr Swipes oder warte bis morgen.';
  }

  @override
  String usageLimitMessagesDaily(int limit) {
    return 'Du hast dein Tageslimit von $limit Nachrichten erreicht. Mach ein Upgrade für unbegrenzte Nachrichten!';
  }

  @override
  String usageLimitMediaUnavailable(String tier) {
    return 'Das Senden von Medien ist im $tier-Paket nicht verfügbar. Mach ein Upgrade, um Bilder und Videos zu senden!';
  }

  @override
  String usageLimitMediaDaily(int limit) {
    return 'Du hast dein Tageslimit von $limit Medien-Sendungen erreicht. Mach ein Upgrade für mehr oder warte bis morgen.';
  }

  @override
  String usageLimitDirectMatchDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'Du hast deine $limit kostenlosen Direct Connects für heute genutzt. Nutze Münzen für mehr oder warte bis morgen.',
      one:
          'Du hast dein 1 kostenloses Direct Connect für heute genutzt. Nutze Münzen für mehr oder warte bis morgen.',
    );
    return '$_temp0';
  }

  @override
  String get contentFilterViolationEmail => 'E-Mail-Adresse';

  @override
  String get contentFilterViolationPhoneWords =>
      'Telefonnummer (in Worten geschrieben)';

  @override
  String get contentFilterViolationPhone => 'Telefonnummer';

  @override
  String get contentFilterViolationSocial => 'Social Media/Link';

  @override
  String adminImportSummary(int success, int duplicates, int errors) {
    return 'Importiert: $success | Duplikate: $duplicates | Fehler: $errors';
  }

  @override
  String get tierBoostCadenceNone => 'Keine';

  @override
  String get tierBoostCadenceMonthly => '1 pro Monat';

  @override
  String get tierBoostCadenceWeekly => '~1 pro Woche';

  @override
  String get tierBoostCadenceDaily => '~1 pro Tag';

  @override
  String get tierFilterLevelBasic => 'Einfach';

  @override
  String get tierFilterLevelStandard => 'Standard';

  @override
  String get tierFilterLevelAdvanced => 'Erweitert';

  @override
  String get tierFilterLevelAll => 'Alle Filter';

  @override
  String tierTtsCostValue(int coins) {
    return '$coins Münzen pro Übersetzung';
  }

  @override
  String chatLearningLiteral(String text) {
    return 'Wörtlich: $text';
  }

  @override
  String chatLearningMeaning(String text) {
    return 'Bedeutung: $text';
  }

  @override
  String get validatorNameRequired => 'Name ist erforderlich';

  @override
  String get validatorNameLettersOnly =>
      'Der Name darf nur Buchstaben und Leerzeichen enthalten';

  @override
  String get validatorPhoneRequired => 'Telefonnummer ist erforderlich';

  @override
  String get validatorPhoneMinDigits =>
      'Die Telefonnummer muss mindestens 10 Ziffern haben';

  @override
  String get validatorAgeRequired => 'Alter ist erforderlich';

  @override
  String validatorMinAge(int minAge) {
    return 'Du musst mindestens $minAge Jahre alt sein';
  }

  @override
  String get validatorInvalidAge => 'Ungültiges Alter';

  @override
  String validatorBioMaxLength(int max) {
    return 'Die Bio muss kürzer als $max Zeichen sein';
  }

  @override
  String get profileOnboardingIncompleteStep =>
      'Bitte fülle alle Pflichtfelder aus';

  @override
  String get profileGenderPreferNotToSay => 'Keine Angabe';

  @override
  String get profileOrientationStraight => 'Hetero';

  @override
  String get profileOrientationGay => 'Schwul/Lesbisch';

  @override
  String get profileOrientationBisexual => 'Bisexuell';

  @override
  String get profileLanguageHebrew => 'Hebräisch';

  @override
  String get profileLanguageThai => 'Thailändisch';

  @override
  String get profileLanguageVietnamese => 'Vietnamesisch';

  @override
  String profileLatLon(String lat, String lon) {
    return 'Breite: $lat, Länge: $lon';
  }

  @override
  String get profileNicknameInvalid => 'Ungültiger Spitzname';

  @override
  String get profileNicknameErrorEmpty => 'Der Spitzname darf nicht leer sein';

  @override
  String profileNicknameErrorTooShort(int min) {
    return 'Der Spitzname muss mindestens $min Zeichen haben';
  }

  @override
  String profileNicknameErrorTooLong(int max) {
    return 'Der Spitzname darf höchstens $max Zeichen haben';
  }

  @override
  String get profileNicknameErrorStartLetter =>
      'Der Spitzname muss mit einem Buchstaben beginnen';

  @override
  String get profileNicknameErrorChars =>
      'Der Spitzname darf nur Buchstaben, Zahlen und Unterstriche enthalten';

  @override
  String get profileNicknameErrorUnderscores =>
      'Der Spitzname darf keine aufeinanderfolgenden Unterstriche enthalten';

  @override
  String get profileNicknameErrorReserved =>
      'Der Spitzname darf keine reservierten Wörter enthalten';

  @override
  String get profileFreeUnlimited => 'Kostenlos - Unbegrenzt';

  @override
  String get profileFreeWithPlatinum => 'Kostenlos mit Platinum';

  @override
  String profileCoinsPerDay(int count) {
    return '$count Münzen/Tag';
  }

  @override
  String profileTravelerActiveSubtitle(
      String location, int hours, int minutes) {
    return '$location - noch $hours Std. $minutes Min.';
  }

  @override
  String profileTravelerInactiveSubtitle(String cost) {
    return '$cost - In einer anderen Stadt erscheinen';
  }

  @override
  String profileMinutesRemaining(int minutes) {
    return 'noch $minutes Min.';
  }

  @override
  String profileHoursMinutesRemaining(int hours, int minutes) {
    return 'noch $hours Std. $minutes Min.';
  }

  @override
  String get profileGhostMode => 'Geistermodus';

  @override
  String get profileGhostModeActiveSubtitle =>
      'Geistermodus - Unbegrenzt - Verborgen in Entdecken & Suche';

  @override
  String get profileGhostModeInactiveSubtitle =>
      'Kostenlos - Unbegrenzt - Verborgen in Entdecken & Spitznamensuche';

  @override
  String profileIncognitoCostSubtitle(int count) {
    return '$count Münzen/24 Std. - Verborgen in Entdecken';
  }

  @override
  String get photoDeleteTitle => 'Foto löschen';

  @override
  String travelerCouldNotResolveAddress(String coordinates) {
    return '$coordinates — Adresse konnte nicht ermittelt werden';
  }

  @override
  String get membershipTierNameBasicFree => 'Basis (Kostenlos)';

  @override
  String get membershipTierNameSilverPremium => 'Silber Premium';

  @override
  String get membershipTierNameGoldPremium => 'Gold Premium';

  @override
  String get membershipTierNamePlatinumVip => 'Platin VIP';

  @override
  String get membershipTierNameSilverVip => 'Silber VIP';

  @override
  String get membershipTierNameGoldVip => 'Gold VIP';

  @override
  String get membershipTierNameTester => 'Tester';

  @override
  String membershipBuyProductPrice(String product, String price) {
    return '$product kaufen – $price';
  }

  @override
  String get coinSpendCategoryMatching => 'Verbinden';

  @override
  String get coinSpendCategoryMessaging => 'Nachrichten';

  @override
  String get coinSpendCategoryGifts => 'Virtuelle Geschenke';

  @override
  String get coinSpendSeeWhoLiked => 'Wer dich geliked hat';

  @override
  String get coinSpendReadReceiptsDay => 'Lesebestätigungen (1 Tag)';

  @override
  String get coinSpendRose => 'Rose';

  @override
  String get coinSpendTeddyBear => 'Teddybär';

  @override
  String get coinSpendDiamond => 'Diamant';

  @override
  String get coinSpendSuperLikeDesc =>
      'Sende ein Priority Connect, um aufzufallen';

  @override
  String get coinSpendBoostDesc =>
      'Werde 30 Minuten lang von mehr Leuten gesehen';

  @override
  String get coinSpendUndoDesc => 'Mach deinen letzten Swipe rückgängig';

  @override
  String get coinSpendSeeWhoLikedDesc => 'Sieh, wem dein Profil gefällt';

  @override
  String get coinSpendReadReceiptsDesc =>
      'Sieh, wann Nachrichten gelesen wurden';

  @override
  String get coinSpendRoseDesc => 'Sende eine virtuelle Rose';

  @override
  String get coinSpendTeddyBearDesc => 'Sende einen süßen Teddybären';

  @override
  String get coinSpendDiamondDesc => 'Sende einen funkelnden Diamanten';

  @override
  String get coinReasonFirstMatchReward => 'Belohnung für die erste Verbindung';

  @override
  String get coinReasonCompleteProfileReward =>
      'Belohnung für vollständiges Profil';

  @override
  String get coinReasonDailyLoginStreak => 'Tägliche Login-Serie';

  @override
  String get coinReasonAchievementUnlocked => 'Erfolg freigeschaltet';

  @override
  String get coinReasonMonthlyAllowance => 'Monatliches Guthaben';

  @override
  String get coinReasonGiftReceived => 'Geschenk erhalten';

  @override
  String get coinReasonGiftSent => 'Geschenk gesendet';

  @override
  String get coinReasonPromotionalBonus => 'Aktionsbonus';

  @override
  String get coinReasonReferralBonus => 'Empfehlungsbonus';

  @override
  String get coinReasonCoinPurchase => 'Münzkauf';

  @override
  String get coinReasonRefund => 'Erstattung';

  @override
  String get coinReasonUndoLastSwipe => 'Letzten Swipe rückgängig machen';

  @override
  String get coinReasonSeeWhoLikedYou => 'Sehen, wer sich verbinden möchte';

  @override
  String get coinReasonDirectMessage => 'Direktnachricht';

  @override
  String get coinReasonFeaturePurchase => 'Funktionskauf';

  @override
  String get coinReasonCoinsExpired => 'Münzen abgelaufen';

  @override
  String get coinReasonAdminAdjustment => 'Admin-Korrektur';

  @override
  String coinTxDescFirstMatch(int amount) {
    return 'Glückwunsch zu deiner ersten Verbindung! $amount Münzen erhalten.';
  }

  @override
  String coinTxDescCompleteProfile(int amount) {
    return 'Profil vervollständigt! $amount Münzen verdient.';
  }

  @override
  String coinTxDescDailyStreak(String streak, int amount) {
    return 'Login-Serie Tag $streak! $amount Münzen verdient.';
  }

  @override
  String coinTxDescAchievement(String achievement, int amount) {
    return 'Erfolg freigeschaltet: $achievement! $amount Münzen verdient.';
  }

  @override
  String coinTxDescAchievementGeneric(int amount) {
    return 'Erfolg freigeschaltet! $amount Münzen verdient.';
  }

  @override
  String coinTxDescMonthlyAllowance(String tier, int amount) {
    return 'Monatliches $tier-Guthaben: $amount Münzen.';
  }

  @override
  String coinTxDescGiftReceived(int amount, String user) {
    return '$amount Münzen von $user erhalten.';
  }

  @override
  String coinTxDescGiftSent(int amount, String user) {
    return '$amount Münzen an $user gesendet.';
  }

  @override
  String coinTxDescPromotional(String campaign, int amount) {
    return 'Aktionsbonus von $campaign: $amount Münzen.';
  }

  @override
  String coinTxDescPromotionalGeneric(int amount) {
    return 'Aktionsbonus: $amount Münzen.';
  }

  @override
  String coinTxDescReferral(int amount) {
    return 'Empfehlungsbonus: $amount Münzen verdient.';
  }

  @override
  String coinTxDescPurchase(int amount) {
    return '$amount Münzen gekauft.';
  }

  @override
  String coinTxDescPurchasePackage(int amount, String package) {
    return '$amount Münzen gekauft ($package).';
  }

  @override
  String coinTxDescRefund(int amount) {
    return 'Erstattung: $amount Münzen.';
  }

  @override
  String coinTxDescUsedFor(int amount, String feature) {
    return '$amount Münzen für $feature verwendet.';
  }

  @override
  String coinTxDescExpired(int amount) {
    return '$amount Münzen sind abgelaufen.';
  }

  @override
  String coinTxDescClawback(int amount) {
    return '$amount Münzen entfernt: Der Kauf wurde erstattet.';
  }

  @override
  String coinTxDescAdmin(int amount, String reason) {
    return 'Admin-Korrektur: $amount Münzen ($reason).';
  }

  @override
  String coinTxDescAdminGeneric(int amount) {
    return 'Admin-Korrektur: $amount Münzen.';
  }

  @override
  String coinPromoPercentBonus(int percent) {
    return '+$percent % Bonus-Münzen';
  }

  @override
  String get businessFollowerFallbackName => 'GreenGo-Mitglied';

  @override
  String get bizCatRestaurant => 'Restaurant';

  @override
  String get bizCatBar => 'Bar';

  @override
  String get bizCatCafe => 'Café';

  @override
  String get bizCatNightclub => 'Nachtclub';

  @override
  String get bizCatLounge => 'Lounge';

  @override
  String get bizCatHotel => 'Hotel';

  @override
  String get bizCatHostel => 'Hostel';

  @override
  String get bizCatGuesthouse => 'Pension';

  @override
  String get bizCatResort => 'Resort';

  @override
  String get bizCatBedAndBreakfast => 'Bed & Breakfast';

  @override
  String get bizCatGym => 'Fitnessstudio';

  @override
  String get bizCatYogaStudio => 'Yogastudio';

  @override
  String get bizCatFitnessStudio => 'Fitnesskursstudio';

  @override
  String get bizCatSpa => 'Spa';

  @override
  String get bizCatWellnessCenter => 'Wellnesszentrum';

  @override
  String get bizCatBeautySalon => 'Schönheitssalon';

  @override
  String get bizCatBarbershop => 'Barbershop';

  @override
  String get bizCatMuseum => 'Museum';

  @override
  String get bizCatArtGallery => 'Kunstgalerie';

  @override
  String get bizCatTheater => 'Theater';

  @override
  String get bizCatCinema => 'Kino';

  @override
  String get bizCatLiveMusicVenue => 'Livemusik-Location';

  @override
  String get bizCatCulturalCenter => 'Kulturzentrum';

  @override
  String get bizCatTourOperator => 'Reiseveranstalter';

  @override
  String get bizCatTravelAgency => 'Reisebüro';

  @override
  String get bizCatLanguageSchool => 'Sprachschule';

  @override
  String get bizCatCookingSchool => 'Kochschule';

  @override
  String get bizCatDanceStudio => 'Tanzstudio';

  @override
  String get bizCatCoworkingSpace => 'Coworking-Space';

  @override
  String get bizCatEventVenue => 'Eventlocation';

  @override
  String get bizCatConferenceCenter => 'Konferenzzentrum';

  @override
  String get bizCatShopRetail => 'Geschäft / Einzelhandel';

  @override
  String get bizCatBoutique => 'Boutique';

  @override
  String get bizCatBookstore => 'Buchhandlung';

  @override
  String get bizCatMarket => 'Markt';

  @override
  String get bizCatWinery => 'Weingut';

  @override
  String get bizCatBrewery => 'Brauerei';

  @override
  String get bizCatDistillery => 'Destillerie';

  @override
  String get bizCatFoodTruck => 'Foodtruck';

  @override
  String get bizCatBakery => 'Bäckerei';

  @override
  String get bizCatCoffeeRoastery => 'Kaffeerösterei';

  @override
  String get bizCatSportsClub => 'Sportverein';

  @override
  String get bizCatAdventureAndOutdoor => 'Abenteuer & Outdoor';

  @override
  String get bizCatDivingCenter => 'Tauchzentrum';

  @override
  String get bizCatPhotographyStudio => 'Fotostudio';

  @override
  String get bizCatCoachingAndConsulting => 'Coaching & Beratung';

  @override
  String get bizCatNonprofitAndNGO => 'Gemeinnützig & NGO';

  @override
  String get bizCatCommunityCenter => 'Gemeindezentrum';

  @override
  String get bizCatTransportationService => 'Transportdienst';

  @override
  String get bizCatOther => 'Sonstiges';

  @override
  String get bizCatGroupFoodAndDrink => 'Essen & Trinken';

  @override
  String get bizCatGroupNightlife => 'Nachtleben';

  @override
  String get bizCatGroupStay => 'Übernachten';

  @override
  String get bizCatGroupWellness => 'Wellness';

  @override
  String get bizCatGroupCulture => 'Kultur';

  @override
  String get bizCatGroupTravelAndTours => 'Reisen & Touren';

  @override
  String get bizCatGroupLearnAndWork => 'Lernen & Arbeiten';

  @override
  String get bizCatGroupEvents => 'Events';

  @override
  String get bizCatGroupRetail => 'Einzelhandel';

  @override
  String get bizCatGroupCommunityAndServices => 'Gemeinschaft & Dienste';

  @override
  String get gamificationJourneyTitle => 'Deine Reise';

  @override
  String gamificationJourneyMilestonesCompleted(int completed, int total) {
    return '$completed von $total Meilensteinen erreicht';
  }

  @override
  String get gamificationJourneyOverallProgress => 'Gesamtfortschritt';

  @override
  String get gamificationJourneyNoMilestones => 'Noch keine Meilensteine';

  @override
  String get gamificationJourneyCompletePrevious =>
      'Schließe die vorherigen Kategorien ab, um freizuschalten';

  @override
  String get gamificationJourneyTabStart => 'Start';

  @override
  String get gamificationJourneyTabMaster => 'Meister';

  @override
  String get gamificationJourneyCatGettingStarted => 'Erste Schritte';

  @override
  String get gamificationJourneyCatSocializing => 'Kontakte knüpfen';

  @override
  String get gamificationJourneyCatMastery => 'Meisterschaft';

  @override
  String get gamificationJourneyCatGettingStartedDesc =>
      'Vervollständige dein Profil und lerne die App kennen';

  @override
  String get gamificationJourneyCatSocializingDesc =>
      'Vernetze dich mit anderen und knüpfe Beziehungen';

  @override
  String get gamificationJourneyCatPremiumDesc =>
      'Schalte Premium-Funktionen und Belohnungen frei';

  @override
  String get gamificationJourneyCatMasteryDesc =>
      'Werde zum Meister-Netzwerker';

  @override
  String get gamificationJourneyCatSpecialDesc =>
      'Exklusive Meilensteine und Erfolge';

  @override
  String get gamificationJourneyCompleteProfileName => 'Profil-Profi';

  @override
  String get gamificationJourneyCompleteProfileDesc =>
      'Vervollständige dein Profil zu 100 %';

  @override
  String get gamificationJourneyAddPhotosName => 'Bildschön';

  @override
  String get gamificationJourneyAddPhotosDesc =>
      'Füge deinem Profil 5 Fotos hinzu';

  @override
  String get gamificationJourneyGetVerifiedName => 'Verifizierter Nutzer';

  @override
  String get gamificationJourneyGetVerifiedDesc =>
      'Schließe die Fotoverifizierung ab';

  @override
  String get gamificationJourneyFirstMatchName => 'Erste Verbindung';

  @override
  String get gamificationJourneyFirstMatchDesc =>
      'Knüpfe deine erste Verbindung';

  @override
  String get gamificationJourneyTenMatchesName => 'Aufsteigender Stern';

  @override
  String get gamificationJourneyTenMatchesDesc => 'Knüpfe 10 Verbindungen';

  @override
  String get gamificationJourneyFiftyMatchesName => 'Gesellige Seele';

  @override
  String get gamificationJourneyFiftyMatchesDesc => 'Knüpfe 50 Verbindungen';

  @override
  String get gamificationJourneyFirstMessageName => 'Eisbrecher';

  @override
  String get gamificationJourneyFirstMessageDesc =>
      'Sende deine erste Nachricht';

  @override
  String get gamificationJourneyHundredMessagesName => 'Gesprächskönig';

  @override
  String get gamificationJourneyHundredMessagesDesc => 'Sende 100 Nachrichten';

  @override
  String get gamificationJourneyFirstVideoCallName =>
      'Von Angesicht zu Angesicht';

  @override
  String get gamificationJourneyFirstVideoCallDesc =>
      'Führe deinen ersten Videoanruf';

  @override
  String get gamificationJourneyTenVideoCallsName => 'Video-Profi';

  @override
  String get gamificationJourneyTenVideoCallsDesc => 'Führe 10 Videoanrufe';

  @override
  String get gamificationJourneyWeekStreakName => 'Engagierter Nutzer';

  @override
  String get gamificationJourneyWeekStreakDesc =>
      'Halte eine 7-Tage-Login-Serie';

  @override
  String get gamificationJourneyMonthStreakName => 'Super engagiert';

  @override
  String get gamificationJourneyMonthStreakDesc =>
      'Halte eine 30-Tage-Login-Serie';

  @override
  String get gamificationJourneyUpgradeSilverName => 'Silber-Mitglied';

  @override
  String get gamificationJourneyUpgradeSilverDesc => 'Upgrade auf Silber-VIP';

  @override
  String get gamificationJourneyUpgradeGoldName => 'Gold-Mitglied';

  @override
  String get gamificationJourneyUpgradeGoldDesc => 'Upgrade auf Gold-VIP';

  @override
  String get gamificationJourneyUpgradePlatinumName => 'Platin-Mitglied';

  @override
  String get gamificationJourneyUpgradePlatinumDesc => 'Upgrade auf Platin-VIP';

  @override
  String get gamificationJourneyTenAchievementsName => 'Erfolgsjäger';

  @override
  String get gamificationJourneyTenAchievementsDesc => 'Verdiene 10 Erfolge';

  @override
  String get gamificationJourneyFiftyAchievementsName => 'Erfolgsmeister';

  @override
  String get gamificationJourneyFiftyAchievementsDesc => 'Verdiene 50 Erfolge';

  @override
  String get gamificationJourneyHundredMatchesName => 'Zenturio';

  @override
  String get gamificationJourneyHundredMatchesDesc => 'Knüpfe 100 Verbindungen';

  @override
  String get gamificationStreakMilestone3Name => 'Guter Start';

  @override
  String get gamificationStreakMilestone7Name => 'Wochenkrieger';

  @override
  String get gamificationStreakMilestone14Name => 'Zwei-Wochen-Champ';

  @override
  String get gamificationStreakMilestone30Name => 'Monatsmeister';

  @override
  String get gamificationStreakMilestone60Name => 'Zwei-Monats-Champion';

  @override
  String get gamificationStreakMilestone90Name => 'Quartalslegende';

  @override
  String get gamificationStreakMilestone180Name => 'Halbjahresheld';

  @override
  String get gamificationStreakMilestone365Name => 'Jahr der Entdeckungen';

  @override
  String gamificationStreakMilestoneDesc(int days) {
    return 'Melde dich $days Tage in Folge an';
  }

  @override
  String get gamificationChallengeSend3MessagesName => 'Kurzer Chat';

  @override
  String get gamificationChallengeSend3MessagesDesc => 'Sende 3 Nachrichten';

  @override
  String get gamificationChallengeSend5MessagesName => 'Nachrichten-Meister';

  @override
  String get gamificationChallengeSend5MessagesDesc =>
      'Sende 5 Nachrichten an deine Kontakte';

  @override
  String get gamificationChallengeSend10MessagesName => 'Gesprächskönig';

  @override
  String get gamificationChallengeSend10MessagesDesc =>
      'Sende heute 10 Nachrichten';

  @override
  String get gamificationChallengeSend15MessagesName => 'Chat-Marathon';

  @override
  String get gamificationChallengeSend15MessagesDesc =>
      'Sende heute 15 Nachrichten';

  @override
  String get gamificationChallengeGet1MatchName => 'Neue Verbindung';

  @override
  String get gamificationChallengeGet1MatchDesc =>
      'Knüpfe heute 1 neue Verbindung';

  @override
  String get gamificationChallengeGet3MatchesName => 'Netzwerker';

  @override
  String get gamificationChallengeGet3MatchesDesc =>
      'Knüpfe heute 3 neue Verbindungen';

  @override
  String get gamificationChallengeGet5MatchesName => 'Menschenmagnet';

  @override
  String get gamificationChallengeGet5MatchesDesc =>
      'Knüpfe heute 5 neue Verbindungen';

  @override
  String get gamificationChallengeSend1SuperlikeName => 'Top-Wahl';

  @override
  String get gamificationChallengeSend1SuperlikeDesc =>
      'Sende 1 Priority Connect';

  @override
  String get gamificationChallengeSend3SuperlikesName => 'Priority-Netzwerker';

  @override
  String get gamificationChallengeSend3SuperlikesDesc =>
      'Sende 3 Priority Connects';

  @override
  String get gamificationChallengeSend5SuperlikesName => 'Superstar';

  @override
  String get gamificationChallengeSend5SuperlikesDesc =>
      'Sende 5 Priority Connects';

  @override
  String get gamificationChallengeVideoCall1Name => 'Video-Fan';

  @override
  String get gamificationChallengeVideoCall1Desc => 'Führe 1 Videoanruf';

  @override
  String get gamificationChallengeVideoCall2Name => 'Video-Profi';

  @override
  String get gamificationChallengeVideoCall2Desc => 'Führe 2 Videoanrufe';

  @override
  String get gamificationChallengeAddPhotoName => 'Foto-Update';

  @override
  String get gamificationChallengeAddPhotoDesc =>
      'Füge ein Profilfoto hinzu oder aktualisiere es';

  @override
  String get gamificationChallengeAdd2PhotosName => 'Fotogalerie';

  @override
  String get gamificationChallengeAdd2PhotosDesc =>
      'Füge 2 neue Profilfotos hinzu';

  @override
  String get gamificationChallengeSend1GiftName => 'Schenker';

  @override
  String get gamificationChallengeSend1GiftDesc =>
      'Sende 1 Geschenk an einen Kontakt';

  @override
  String get gamificationChallengeSend3GiftsName => 'Großzügige Seele';

  @override
  String get gamificationChallengeSend3GiftsDesc => 'Sende heute 3 Geschenke';

  @override
  String get gamificationChallengeSend5GiftsName => 'Geschenke-Meister';

  @override
  String get gamificationChallengeSend5GiftsDesc => 'Sende heute 5 Geschenke';

  @override
  String get gamificationChallengeChatStarterName => 'Eisbrecher';

  @override
  String get gamificationChallengeChatStarterDesc =>
      'Sende 7 Nachrichten an verschiedene Kontakte';

  @override
  String get gamificationChallengeSocialButterflyName => 'Gesellige Seele';

  @override
  String get gamificationChallengeSocialButterflyDesc =>
      'Sende heute 20 Nachrichten';

  @override
  String get gamificationChallengeMatchRushName => 'Verbindungs-Rausch';

  @override
  String get gamificationChallengeMatchRushDesc =>
      'Knüpfe heute 7 Verbindungen';

  @override
  String get gamificationChallengeVideoMarathonName => 'Video-Marathon';

  @override
  String get gamificationChallengeVideoMarathonDesc => 'Führe 3 Videoanrufe';

  @override
  String get gamificationChallengeWeeklyMessages30Name => 'Chat-Fan';

  @override
  String get gamificationChallengeWeeklyMessages30Desc =>
      'Sende diese Woche 30 Nachrichten';

  @override
  String get gamificationChallengeWeeklyMessages50Name => 'Chat-Meister';

  @override
  String get gamificationChallengeWeeklyMessages50Desc =>
      'Sende diese Woche 50 Nachrichten';

  @override
  String get gamificationChallengeWeeklyMessages100Name => 'Chat-Legende';

  @override
  String get gamificationChallengeWeeklyMessages100Desc =>
      'Sende diese Woche 100 Nachrichten';

  @override
  String get gamificationChallengeWeeklyMatches10Name => 'Wochen-Connector';

  @override
  String get gamificationChallengeWeeklyMatches10Desc =>
      'Knüpfe diese Woche 10 Verbindungen';

  @override
  String get gamificationChallengeWeeklyMatches20Name =>
      'Verbindungs-Champion der Woche';

  @override
  String get gamificationChallengeWeeklyMatches20Desc =>
      'Knüpfe diese Woche 20 Verbindungen';

  @override
  String get gamificationChallengeWeeklyMatches30Name => 'Verbindungsmaschine';

  @override
  String get gamificationChallengeWeeklyMatches30Desc =>
      'Knüpfe diese Woche 30 Verbindungen';

  @override
  String get gamificationChallengeWeeklySuperlikes5Name =>
      'Priority-Netzwerker der Woche';

  @override
  String get gamificationChallengeWeeklySuperlikes5Desc =>
      'Sende diese Woche 5 Priority Connects';

  @override
  String get gamificationChallengeWeeklySuperlikes10Name => 'Superfan';

  @override
  String get gamificationChallengeWeeklySuperlikes10Desc =>
      'Sende diese Woche 10 Priority Connects';

  @override
  String get gamificationChallengeWeeklySuperlikes15Name => 'Prioritäts-König';

  @override
  String get gamificationChallengeWeeklySuperlikes15Desc =>
      'Sende diese Woche 15 Priority Connects';

  @override
  String get gamificationChallengeWeeklyVideo3Name => 'Video-Plaudertasche';

  @override
  String get gamificationChallengeWeeklyVideo3Desc =>
      'Führe diese Woche 3 Videoanrufe';

  @override
  String get gamificationChallengeWeeklyVideo5Name => 'Video-Star';

  @override
  String get gamificationChallengeWeeklyVideo5Desc =>
      'Führe diese Woche 5 Videoanrufe';

  @override
  String get gamificationChallengeWeeklyGifts5Name => 'Schenker der Woche';

  @override
  String get gamificationChallengeWeeklyGifts5Desc =>
      'Sende diese Woche 5 Geschenke';

  @override
  String get gamificationChallengeWeeklyGifts10Name => 'Großzügige Seele';

  @override
  String get gamificationChallengeWeeklyGifts10Desc =>
      'Sende diese Woche 10 Geschenke';

  @override
  String get gamificationChallengeWeeklyPhotos3Name => 'Fotowoche';

  @override
  String get gamificationChallengeWeeklyPhotos3Desc =>
      'Füge diese Woche 3 Fotos hinzu';

  @override
  String get gamificationChallengeWeeklyPerfectName => 'Perfekte Woche';

  @override
  String get gamificationChallengeWeeklyPerfectDesc =>
      'Schließe 7 Tage in Folge alle täglichen Herausforderungen ab';

  @override
  String get gamificationChallengeValentineMatchesName =>
      'Freundschafts-Verbindungen';

  @override
  String get gamificationChallengeValentineMatchesDesc =>
      'Knüpfe 14 Verbindungen in der Freundschaftswoche (1 pro Tag)';

  @override
  String get gamificationChallengeValentineVideoName =>
      'Virtueller Kulturabend';

  @override
  String get gamificationChallengeValentineVideoDesc => 'Führe 3 Videoanrufe';

  @override
  String get gamificationChallengeSummerMatchesName => 'Strand-Feeling';

  @override
  String get gamificationChallengeSummerMatchesDesc =>
      'Knüpfe diesen Sommer 30 Verbindungen';

  @override
  String get gamificationChallengeHolidayGiftsName => 'Schenker';

  @override
  String get gamificationChallengeHolidayGiftsDesc =>
      'Sende 10 Münzgeschenke an deine Kontakte';

  @override
  String get gamificationChallengeHolidayMessagesName => 'Festtagsfreude';

  @override
  String get gamificationChallengeHolidayMessagesDesc =>
      'Sende 100 Nachrichten';

  @override
  String get gamificationEventValentinesName => 'Freundschaftswoche';

  @override
  String get gamificationEventValentinesDesc =>
      'Feiere diese Woche Freundschaft über Kulturen hinweg!';

  @override
  String get gamificationEventSummerName => 'Sommer der Entdeckungen';

  @override
  String get gamificationEventSummerDesc =>
      'Finde diesen Sommer neue Freunde aus aller Welt!';

  @override
  String get gamificationEventHolidayName => 'Festtage';

  @override
  String get gamificationEventHolidayDesc =>
      'Verbinde dich in dieser Feiertagszeit mit Menschen aus aller Welt!';

  @override
  String get travelExploreTitle => 'Reisen entdecken';

  @override
  String get travelExploreInMyCity => 'In meiner Stadt';

  @override
  String get travelExploreWorldwide => 'Weltweit';

  @override
  String travelExploreTravelersIn(String city) {
    return 'Reisende in $city';
  }

  @override
  String get travelExploreUnknownLocation => 'Unbekannter Ort';

  @override
  String get travelExploreLocalGuides => 'Lokale Guides';

  @override
  String get travelExploreCities => 'Städte';

  @override
  String travelExploreGuideIn(String city) {
    return 'Guide in $city';
  }

  @override
  String travelExploreNoTravelersInCity(String city) {
    return 'Gerade keine Reisenden in $city';
  }

  @override
  String get travelExploreNoTravelers => 'Keine Reisenden gefunden';

  @override
  String get travelExploreTryWorldwide =>
      'Wechsle zu „Weltweit“, um alle Reisenden zu sehen';

  @override
  String get travelExploreCheckBack =>
      'Schau später wieder nach aktiven Reisenden';

  @override
  String get travelExploreShowWorldwide => 'Weltweit anzeigen';

  @override
  String get discoveryDealBreakerSmoking => 'Rauchen';

  @override
  String get discoveryDealBreakerDrinking => 'Alkohol';

  @override
  String get discoveryDealBreakerNoBio => 'Keine Bio';

  @override
  String get discoveryDealBreakerNoPhotos => 'Keine Fotos';

  @override
  String get discoveryDealBreakerDifferentReligion => 'Andere Religion';

  @override
  String get discoveryDealBreakerDifferentPolitics =>
      'Andere politische Ansichten';

  @override
  String get discoveryDealBreakerHasChildren => 'Hat Kinder';

  @override
  String get discoveryDealBreakerWantsChildren => 'Möchte Kinder';

  @override
  String get discoveryDealBreakerLongDistance => 'Große Entfernung';

  @override
  String get discoveryDealBreakerNonMonogamy => 'Nicht-Monogamie';

  @override
  String discoveryPrefCountryUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nutzer',
      one: '1 Nutzer',
    );
    return '$_temp0';
  }

  @override
  String get discoveryGridAuto => 'Auto';

  @override
  String get discoveryMatchFallbackName => 'Verbindung';

  @override
  String get discoveryThisUser => 'dieser Person';

  @override
  String get discoveryActionNope => 'Nein';

  @override
  String get exploreTierTester => 'Tester';

  @override
  String get chatCulturalContextTitle => 'Kultureller Kontext';

  @override
  String get chatCulturalContextLink => 'Kultureller Kontext';

  @override
  String get chatWordBreakdownTierRequired =>
      'Die Wortzerlegung ist für Silver-, Gold- und Platinum-Mitglieder verfügbar';

  @override
  String get chatPreviewSticker => 'Sticker';

  @override
  String get chatPreviewVoiceMessage => 'Sprachnachricht';

  @override
  String get chatPreviewAlbumShared => 'Album geteilt';

  @override
  String get chatPreviewAlbumRevoked => 'Albumzugriff entzogen';

  @override
  String get chatPreviewEvent => 'Event';

  @override
  String get chatPreviewSayHi => 'Sag hallo zu deiner neuen Verbindung!';

  @override
  String chatTimeShortMinutes(int count) {
    return '$count Min.';
  }

  @override
  String chatTimeShortHours(int count) {
    return '$count Std.';
  }

  @override
  String chatTimeShortDays(int count) {
    return '$count T.';
  }

  @override
  String get chatNotificationsMutedForChat =>
      'Benachrichtigungen für diesen Chat stummgeschaltet';

  @override
  String get chatNotificationsUnmuted => 'Benachrichtigungen wieder aktiviert';

  @override
  String get chatMuteNotifications => 'Benachrichtigungen stummschalten';

  @override
  String get chatUnmuteNotifications => 'Benachrichtigungen aktivieren';

  @override
  String chatAlbumSelectCount(int count) {
    return 'Auswählen ($count)';
  }

  @override
  String chatAlbumPhotosSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos ausgewählt',
      one: '1 Foto ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String chatSessionXp(int xp) {
    return '$xp XP';
  }

  @override
  String get chatPhraseHowAreYou => 'Wie geht\'s?';

  @override
  String get chatPhraseGoodMorning => 'Guten Morgen!';

  @override
  String get chatPhraseAllGood => 'Alles gut?';

  @override
  String get chatPhrasePleasedToMeetYou => 'Sehr erfreut!';

  @override
  String get chatPhraseNiceToMeetYou => 'Freut mich, dich kennenzulernen!';

  @override
  String get chatPhraseWhatsUp => 'Was geht?';

  @override
  String get chatSupportAiBadge => 'KI';

  @override
  String get chatGroupFallbackName => 'Gruppe';

  @override
  String get communitiesTypeLanguageCircle => 'Sprachzirkel';

  @override
  String get communitiesTypeCulturalInterest => 'Kulturelles Interesse';

  @override
  String get communitiesTypeTravelGroup => 'Reisegruppe';

  @override
  String get communitiesTypeLocalGuides => 'Lokale Guides';

  @override
  String get communitiesTypeStudyGroup => 'Lerngruppe';

  @override
  String get communitiesTypeGeneral => 'Allgemein';

  @override
  String get communitiesRoleOwner => 'Inhaber';

  @override
  String get communitiesRoleAdmin => 'Admin';

  @override
  String get communitiesRoleMember => 'Mitglied';

  @override
  String get communitiesNoActivityYet => 'Noch keine Aktivität';

  @override
  String get communitiesLanguageMandarin => 'Mandarin';

  @override
  String get communitiesLanguageThai => 'Thailändisch';

  @override
  String get communitiesLanguageVietnamese => 'Vietnamesisch';

  @override
  String get communitiesLanguageCatalan => 'Katalanisch';

  @override
  String get communitiesLanguageHebrew => 'Hebräisch';

  @override
  String get videoPromptSelectorTitle => 'Wähle ein Thema';

  @override
  String get videoPromptSelectorSubtitle =>
      'Wähle ein Thema für dein Vorstellungsvideo';

  @override
  String get videoPromptIntroduceTitle => 'Stell dich vor';

  @override
  String get videoPromptIntroduceDesc =>
      'Sag Hallo und erzähl uns, wer du bist';

  @override
  String get videoPromptIntroduceTemplate =>
      'Stell dich in deiner Lieblingssprache vor';

  @override
  String get videoPromptNativeTitle => 'Muttersprache';

  @override
  String get videoPromptNativeDesc => 'Zeig deine Muttersprache';

  @override
  String get videoPromptNativeTemplate => 'Sag etwas in deiner Muttersprache';

  @override
  String get videoPromptTeachTitle => 'Bring uns einen Satz bei';

  @override
  String get videoPromptTeachDesc => 'Teile einen lustigen Ausdruck';

  @override
  String get videoPromptTeachTemplate =>
      'Bring uns einen Satz in deiner Sprache bei';

  @override
  String get videoPromptPlaceTitle => 'Lieblingsort';

  @override
  String get videoPromptPlaceDesc => 'Teile einen Ort, der dir etwas bedeutet';

  @override
  String get videoPromptPlaceTemplate => 'Welchen Ort besuchst du am liebsten?';

  @override
  String get videoPromptCultureTitle => 'Kulturaustausch';

  @override
  String get videoPromptCultureDesc => 'Was bedeutet Kulturaustausch für dich?';

  @override
  String get videoPromptCultureTemplate =>
      'Beschreibe deinen idealen Kulturaustausch';

  @override
  String get videoPromptTalentTitle => 'Verstecktes Talent';

  @override
  String get videoPromptTalentDesc => 'Überrasche uns mit etwas Unerwartetem';

  @override
  String get videoPromptTalentTemplate =>
      'Zeig uns ein verstecktes Talent oder einen witzigen Fakt über dich';

  @override
  String get videoPromptTripTitle => 'Traumreise';

  @override
  String get videoPromptTripDesc => 'Wohin auf der Welt würdest du reisen?';

  @override
  String get videoPromptTripTemplate => 'Beschreibe dein Traumreiseziel';

  @override
  String get videoPromptFreeTitle => 'Freestyle';

  @override
  String get videoPromptFreeDesc => 'Sag, was du willst!';

  @override
  String get videoPromptFreeTemplate => 'Freestyle – ohne Thema';

  @override
  String get videoDiscoveryLiked => 'Gefällt dir!';

  @override
  String get videoDiscoveryPassed => 'Übersprungen';

  @override
  String get videoDiscoveryTitle => 'Video-Vorstellungen';

  @override
  String get videoDiscoveryEmptyTitle => 'Noch keine Vorstellungsvideos';

  @override
  String get videoDiscoveryEmptySubtitle => 'Sei der Erste, der eins erstellt!';

  @override
  String videoDiscoveryUserFallback(String id) {
    return 'Nutzer $id';
  }

  @override
  String videoDiscoveryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufrufe',
      one: '1 Aufruf',
    );
    return '$_temp0';
  }

  @override
  String get videoDiscoveryLike => 'Like';

  @override
  String get videoDiscoveryPass => 'Weiter';

  @override
  String get videoDiscoveryReport => 'Melden';

  @override
  String get videoDiscoveryMute => 'Ton aus';

  @override
  String get videoDiscoveryUnmute => 'Ton an';

  @override
  String get videoProfileUploadSuccess => 'Video erfolgreich hochgeladen!';

  @override
  String get videoProfileDeleteTitle => 'Video löschen?';

  @override
  String get videoProfileDeleteConfirm =>
      'Möchtest du dein Vorstellungsvideo wirklich löschen?';

  @override
  String get videoProfileDeleted => 'Video gelöscht';

  @override
  String get videoProfileScreenTitle => 'Vorstellungsvideo';

  @override
  String get videoProfileFirstImpression =>
      'Mach einen tollen ersten Eindruck!';

  @override
  String videoProfileInfoBody(int seconds) {
    return 'Nimm ein $seconds-Sekunden-Video auf, um dich vorzustellen. Profile mit Videos bekommen 40 % mehr Verbindungen!';
  }

  @override
  String get videoProfileNoVideo => 'Noch kein Video';

  @override
  String videoProfileMaxSeconds(int seconds) {
    return 'Max. $seconds Sekunden';
  }

  @override
  String get videoProfileRecord => 'Video aufnehmen';

  @override
  String get videoProfileUploadFromGallery => 'Aus Galerie hochladen';

  @override
  String get videoProfileSave => 'Video speichern';

  @override
  String get videoProfileRecordAgain => 'Erneut aufnehmen';

  @override
  String get videoProfileTipsTitle => 'Tipps für ein tolles Video:';

  @override
  String get videoProfileTipLighting =>
      'Gutes Licht – schau zu einem Fenster oder einer Lichtquelle';

  @override
  String get videoProfileTipVertical => 'Halte dein Handy hochkant';

  @override
  String get videoProfileTipSmile => 'Lächle und sei du selbst!';

  @override
  String get videoProfileTipSpeak => 'Sprich deutlich – stell dich vor';

  @override
  String get videoProfileTipHobbies => 'Erwähne deine Hobbys oder Interessen';

  @override
  String adminVerificationBulkBetterPhotoTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nutzer',
      one: '1 Nutzer',
    );
    return 'Besseres Foto anfordern ($_temp0)';
  }

  @override
  String adminVerificationBulkApproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Verifizierungen genehmigt',
      one: '1 Verifizierung genehmigt',
    );
    return '$_temp0';
  }

  @override
  String adminVerificationBulkBetterPhotoRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Besseres Foto für $count Nutzer angefordert',
      one: 'Besseres Foto für 1 Nutzer angefordert',
    );
    return '$_temp0';
  }

  @override
  String get adminPreSaleTitle => 'Vorverkauf verwalten';

  @override
  String get adminPreSaleProgramTitle => 'Vorverkaufs-Stufenprogramm';

  @override
  String get adminPreSaleProgramDescription =>
      'Verwalte Vorverkaufsnutzer mit stufenbasiertem Countdown und Abo-Dauer.';

  @override
  String adminPreSaleCsvFormatHint(String columns, String tiers) {
    return 'CSV-Format: $columns\nStufenwerte: $tiers';
  }

  @override
  String get adminPreSaleAddSingleEntry => 'Einzelnen Eintrag hinzufügen';

  @override
  String get adminPreSaleEntries => 'Vorverkaufseinträge';

  @override
  String get adminPreSaleAllTiers => 'Alle Stufen';

  @override
  String get adminPreSaleNoMatching => 'Keine passenden Einträge gefunden';

  @override
  String get adminPreSaleEmpty =>
      'Noch keine Vorverkaufseinträge.\nLade eine CSV hoch, um zu starten.';

  @override
  String adminPreSaleDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String adminPreSaleEntryAdded(String email, String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$email als $tier hinzugefügt ($_temp0)';
  }

  @override
  String get adminPreSaleRemoveEntryTitle => 'Eintrag entfernen';

  @override
  String adminPreSaleRemoveEntryConfirm(String email) {
    return '$email aus der Vorverkaufsliste entfernen?';
  }

  @override
  String adminPreSaleEntryRemoved(String email) {
    return '$email aus der Vorverkaufsliste entfernt';
  }

  @override
  String get adminPreSaleCsvEmpty => 'CSV-Datei ist leer';

  @override
  String adminPreSaleCsvMissingHeaders(String expected, String found) {
    return 'CSV muss diese Kopfzeilen haben: $expected\nGefunden: $found';
  }

  @override
  String get adminPreSaleCsvNoRows =>
      'Keine gültigen Datenzeilen in der CSV gefunden';

  @override
  String get adminPreSaleInvalidDays =>
      'Bitte gib eine gültige Anzahl an Tagen ein';

  @override
  String get adminPreSaleInfoTitle => 'Vorverkaufsinfo';

  @override
  String get adminPreSaleCsvFormatTitle => 'CSV-Format';

  @override
  String get adminPreSaleCountdownDates => 'Countdown-Daten pro Stufe';

  @override
  String get adminPreSaleHowItWorks => 'So funktioniert\'s';

  @override
  String get adminPreSaleHowItWorksSteps =>
      '1. Nutzer registriert sich per E-Mail\n2. App prüft die Vorverkaufsliste\n3. Countdown zeigt das Stufendatum\n4. Nach dem Countdown: Abo wird aktiviert\n5. Dauer = NUMBER_OF_DAYS aus der Liste\n6. Basis-Mitgliedschaft = gleiches Ablaufdatum';

  @override
  String get adminStatusProcessing => 'In Bearbeitung';

  @override
  String get adminStatusCompleted => 'Abgeschlossen';

  @override
  String get adminStatusFailed => 'Fehlgeschlagen';

  @override
  String get adminStatusCancelled => 'Storniert';

  @override
  String get adminStatusRefunded => 'Erstattet';

  @override
  String get adminStatusDraft => 'Entwurf';

  @override
  String get adminStatusIssued => 'Ausgestellt';

  @override
  String get adminStatusPaid => 'Bezahlt';

  @override
  String get adminStatusOverdue => 'Überfällig';

  @override
  String get adminOrderTypeCoins => 'Münzkauf';

  @override
  String get adminOrderTypeSubscription => 'Abo';

  @override
  String get adminOrderTypeGift => 'Geschenkkauf';

  @override
  String get adminRoleSuperAdmin => 'Super-Admin';

  @override
  String get adminRoleModerator => 'Moderator';

  @override
  String get adminRoleAnalyst => 'Analyst';

  @override
  String get cityPickerTitle => 'Stadt auswählen';

  @override
  String get cityPickerSearchHint => 'Stadt suchen…';

  @override
  String get cityPickerEmptyHint => 'Suche eine Stadt oder tippe auf die Karte';

  @override
  String get cityPickerUseCity => 'Diese Stadt verwenden';

  @override
  String get notifServerViewedYourProfile => 'hat dein Profil angesehen';

  @override
  String get notifServerStartedFollowingYou => 'folgt dir jetzt';

  @override
  String get notifServerStartedFollowingBusiness =>
      'folgt jetzt deinem Unternehmen';

  @override
  String get notifServerRatedYourBusiness => 'hat dein Unternehmen bewertet';

  @override
  String notifServerRatedYourBusinessStars(int stars) {
    return 'hat dein Unternehmen mit $stars★ bewertet';
  }

  @override
  String get notifServerReviewedYourExperience => 'hat dein Erlebnis bewertet';

  @override
  String get notifServerTapToSeeWhoStoppedBy =>
      'Tippe, um zu sehen, wer vorbeigeschaut hat';

  @override
  String get notifServerTapToSeeTheirProfile => 'Tippe, um das Profil zu sehen';

  @override
  String get notifServerNewFollower => 'Du hast einen neuen Follower';

  @override
  String get notifServerNewRating => 'Du hast eine neue Bewertung';

  @override
  String get notifServerYourCommunity => 'Deine Community';

  @override
  String get notifServerYourEvent => 'Dein Event';

  @override
  String get notifServerProfileBoostLive => 'Dein Profil-Boost ist jetzt aktiv';

  @override
  String get notifServerProfileBoostEnded => 'Dein Profil-Boost ist beendet';

  @override
  String get notifServerProfilePromoted =>
      'Dein Profil wird mehr Leuten gezeigt';

  @override
  String get notifServerEventPromoted =>
      'Dein Event wird in Explore hervorgehoben';

  @override
  String get notifServerBoostAgainProfile =>
      'Booste erneut, um weiter mehr Leute zu erreichen';

  @override
  String get notifServerBoostAgainEvent =>
      'Booste erneut, damit es hervorgehoben bleibt';

  @override
  String get notifServerCheckedIn => 'Du bist eingecheckt – viel Spaß!';

  @override
  String get notifServerTicketReady => 'Dein Ticket ist bereit';

  @override
  String get notifServerTicketSold => 'Ticket verkauft';

  @override
  String get notifServerPaymentToConfirm => 'Zahlung zu bestätigen';

  @override
  String get notifServerPaymentNotConfirmed => 'Zahlung nicht bestätigt';

  @override
  String get notifServerPaymentsWaiting =>
      'Zahlungen warten auf deine Bestätigung';

  @override
  String get notifServerTicketRefunded => 'Ticket erstattet';

  @override
  String get notifServerTicketDisputed => 'Ticketzahlung angefochten';

  @override
  String get notifServerRefundToPayBack => 'Rückerstattung zu zahlen';

  @override
  String get notifServerTicketReservationExpired =>
      'Ticketreservierung abgelaufen';

  @override
  String get notifServerExperienceHidden =>
      'Dein Erlebnis wurde nach mehreren Meldungen ausgeblendet';

  @override
  String get notifServerPendingReview => 'Wird von GreenGo geprüft';

  @override
  String get notifServerMonthlyCoinsAdded => 'Monatliche Münzen gutgeschrieben';

  @override
  String get notifServerSupportReplied =>
      'Der Support hat auf dein Ticket geantwortet';

  @override
  String get notifServerSupportNewReply =>
      'Du hast eine neue Antwort vom Support.';

  @override
  String get notifServerIncognitoExpiring => 'Inkognito-Modus läuft bald ab';

  @override
  String get notifServerIncognitoExpiringBody =>
      'Dein Inkognito-Modus läuft in weniger als 1 Stunde ab!';

  @override
  String get notifServerTravelerExpiring => 'Reisemodus läuft bald ab';

  @override
  String get notifServerTravelerExpiringBody =>
      'Dein Reisemodus läuft in weniger als 1 Stunde ab!';

  @override
  String get notifServerProfileVerified => 'Profil verifiziert!';

  @override
  String get notifServerProfileVerifiedBody =>
      'Dein Profil wurde verifiziert! Du hast jetzt ein Verifiziert-Abzeichen.';

  @override
  String get notifServerNewVerificationPhoto =>
      'Neues Verifizierungsfoto benötigt';

  @override
  String get notifServerVerificationUpdate => 'Verifizierungs-Update';

  @override
  String notifServerJoinedYourCommunity(String name) {
    return 'ist deiner Community $name beigetreten';
  }

  @override
  String notifServerJoinedYourEvent(String name) {
    return 'nimmt an deinem Event $name teil';
  }

  @override
  String notifServerLikedYourEvent(String name) {
    return 'gefällt dein Event $name';
  }

  @override
  String notifServerJoinedYourGroup(String name) {
    return 'ist deiner Gruppe $name beigetreten';
  }

  @override
  String notifServerAddedYouAsCoOwner(String name) {
    return 'hat dich als Mitinhaber von $name hinzugefügt';
  }

  @override
  String notifServerAddedYouToGroup(String name) {
    return 'hat dich zu $name hinzugefügt';
  }

  @override
  String notifServerEventBoostLive(String name) {
    return 'Der Boost für dein Event $name ist jetzt aktiv';
  }

  @override
  String notifServerEventBoostEnded(String name) {
    return 'Der Boost für dein Event $name ist beendet';
  }

  @override
  String notifServerTicketScanned(String name) {
    return 'Dein Ticket für $name wurde gescannt';
  }

  @override
  String notifServerNewEventIn(String name) {
    return 'Neues Event in $name';
  }

  @override
  String notifServerEventCancelledIn(String name) {
    return 'Event in $name abgesagt';
  }

  @override
  String notifServerEventUpdatedIn(String name) {
    return 'Event in $name aktualisiert';
  }

  @override
  String notifServerNewEventFrom(String name) {
    return 'Neues Event von $name';
  }

  @override
  String notifServerAnnouncement(String name) {
    return 'Ankündigung · $name';
  }

  @override
  String get culturalExchangeCategoryFood => 'Essen';

  @override
  String get culturalExchangeCategoryTransportation => 'Verkehr';

  @override
  String get culturalExchangeCategoryDating => 'Leute kennenlernen';

  @override
  String get culturalExchangeCategoryCustoms => 'Bräuche';

  @override
  String get culturalExchangeCategoryLanguage => 'Sprache';

  @override
  String get culturalExchangeCategorySafety => 'Sicherheit';

  @override
  String get culturalExchangeSectionCuisine => 'Küche';

  @override
  String get culturalExchangeSectionCustoms => 'Bräuche';

  @override
  String get culturalExchangeSectionKeyPhrases => 'Wichtige Sätze';

  @override
  String get culturalExchangeSectionPhrases => 'Sätze';

  @override
  String get culturalExchangeSpotlightBadge => 'IM FOKUS';

  @override
  String get culturalExchangeContentComingSoon => 'Inhalte folgen bald';

  @override
  String get culturalExchangeContentComingSoonBody =>
      'Wir bereiten ausführliche Inhalte für diesen Fokus vor.';

  @override
  String get culturalExchangeLike => 'Gefällt mir';

  @override
  String culturalExchangeWeeksAgo(int count) {
    return 'vor $count Wo.';
  }

  @override
  String culturalExchangeMonthsAgo(int count) {
    return 'vor $count Mon.';
  }

  @override
  String get culturalExchangeDailyInsightJapanBow =>
      'In Japan verbeugt man sich üblicherweise zur Begrüßung. Je tiefer die Verbeugung, desto mehr Respekt zeigst du.';

  @override
  String get culturalExchangeSelectCountry => 'Land auswählen';

  @override
  String get culturalExchangeChooseCountry => 'Wähle ein Land...';

  @override
  String get culturalExchangeSelectCountryAbove => 'Wähle oben ein Land';

  @override
  String get culturalExchangeLearnEtiquette =>
      'Lerne Umgangsformen aus über 20 Ländern\nweltweit';

  @override
  String get culturalExchangeDos => 'Was du tun solltest';

  @override
  String get culturalExchangeDonts => 'Was du lassen solltest';

  @override
  String get notifNewConversationTitle => 'Neue Unterhaltung';

  @override
  String notifNewMessageFrom(String name) {
    return 'Neue Nachricht von $name';
  }

  @override
  String notifStartedConversation(String name) {
    return '$name hat eine Unterhaltung mit dir begonnen.';
  }

  @override
  String get notifNewPhotoLikeTitle => 'Neues Like für dein Foto';

  @override
  String notifLikedYourPhoto(String name) {
    return '$name gefällt dein Foto';
  }

  @override
  String get notifCoinsReceivedTitle => 'Du hast Münzen erhalten!';

  @override
  String chatSystemCoinsReceived(String name, int amount) {
    return '$name hat dir $amount Münzen geschickt!';
  }

  @override
  String chatSystemCoinsSent(int amount) {
    return 'Ich habe dir gerade $amount Münzen geschickt!';
  }

  @override
  String chatSystemSupportWelcome(String subject) {
    return 'Willkommen beim GreenGo-Support! Ein Support-Mitarbeiter ist gleich für dich da. Dein Ticket: $subject';
  }

  @override
  String chatSystemSupportAgentJoined(String name) {
    return '$name ist dem Gespräch beigetreten und hilft dir weiter.';
  }

  @override
  String get chatSystemSupportAgentFallback => 'Support-Mitarbeiter';

  @override
  String get chatSystemSupportInProgress =>
      'Ein Support-Mitarbeiter kümmert sich um dein Anliegen.';

  @override
  String get chatSystemSupportWaitingOnUser => 'Wir warten auf deine Antwort.';

  @override
  String get chatSystemSupportResolved =>
      'Dein Anliegen wurde gelöst. Danke, dass du den GreenGo-Support kontaktiert hast!';

  @override
  String get chatSystemSupportClosed =>
      'Dieses Support-Ticket wurde geschlossen.';

  @override
  String get chatSystemSupportStatusUpdated => 'Ticket-Status aktualisiert.';

  @override
  String get commonUnknownUser => 'Unbekannter Nutzer';

  @override
  String get chatSupportDescription => 'Beschreibung';

  @override
  String get supportReportFollowUpTitle => 'Nachverfolgung der Meldung';

  @override
  String supportReportFollowUpSubject(String reason) {
    return 'Nachverfolgung der Meldung: $reason';
  }

  @override
  String supportReportFollowUpDetails(
      String reason, String message, String user, String date) {
    return 'Grund: $reason\nGemeldete Nachricht: „$message“\nGemeldeter Nutzer: $user\nGemeldet am: $date';
  }

  @override
  String get supportChatWithGreenGoSubject => 'Chat mit dem GreenGo-Support';

  @override
  String invoiceLineCoins(int count) {
    return '$count GreenGo-Münzen';
  }

  @override
  String get invoiceLineSubscription => 'Abonnement';

  @override
  String get invoiceLineGiftPackage => 'Münz-Geschenkpaket';

  @override
  String get srvSomeone => 'Jemand';

  @override
  String get srvJoinedYourCommunity => 'ist deiner Community beigetreten';

  @override
  String get srvJoinedYourEvent => 'nimmt an deinem Event teil';

  @override
  String get srvLikedYourEvent => 'mag dein Event';

  @override
  String get srvJoinedYourGroup => 'ist deiner Gruppe beigetreten';

  @override
  String get srvAddedYouToAGroup => 'hat dich zu einer Gruppe hinzugefügt';

  @override
  String get srvGroup => 'Gruppe';

  @override
  String srvGroupMembersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder haben die Gruppe verlassen',
      one: 'Ein Mitglied hat die Gruppe verlassen',
    );
    return '$_temp0';
  }

  @override
  String get srvTicketScanned => 'Dein Ticket wurde gescannt';

  @override
  String get srvEventBoostLive => 'Dein Event-Boost ist jetzt aktiv';

  @override
  String get srvEventBoostEnded => 'Dein Event-Boost ist beendet';

  @override
  String get srvAddedYouAsCoOwnerOfEvent =>
      'hat dich als Mitorganisator eines Events hinzugefügt';

  @override
  String get srvAnEvent => 'Ein Event';

  @override
  String srvPaymentsWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen',
      one: '1 Zahlung',
    );
    return '$_temp0';
  }

  @override
  String get srvNewReview => 'Neue Bewertung';

  @override
  String get srvMentionedYouInReviewReply =>
      'hat dich in einer Antwort auf eine Bewertung erwähnt';

  @override
  String get srvRepliedToYourReview => 'hat auf deine Bewertung geantwortet';

  @override
  String get srvExperience => 'Erlebnis';

  @override
  String get srvBookingRequested => 'möchte dein Erlebnis buchen';

  @override
  String get srvBookingBooked => 'hat dein Erlebnis gebucht';

  @override
  String get srvBookingConfirmed => 'Buchung bestätigt';

  @override
  String get srvBookingAccepted => 'hat deine Buchungsanfrage angenommen';

  @override
  String get srvBookingDeclined => 'hat deine Buchungsanfrage abgelehnt';

  @override
  String get srvBookingCancelledTheirs => 'hat die Buchung storniert';

  @override
  String get srvBookingCancelledYours => 'hat deine Buchung storniert';

  @override
  String srvBookingRefundOwed(String title, int percent) {
    return '$title – zu erstattender Betrag: $percent %.';
  }

  @override
  String get srvBookingCheckedIn => 'Du bist eingecheckt';

  @override
  String get srvBookingCancelledByHost =>
      'Deine Buchung wurde vom Gastgeber storniert';

  @override
  String srvBookingCancelledByHostBody(String title) {
    return '$title – der Termin ist nicht mehr verfügbar. Zahlungen werden erstattet.';
  }

  @override
  String get srvBookingNoShow => 'hat dich als nicht erschienen markiert';

  @override
  String srvBookingNoShowBody(String title, int hours) {
    return '$title – du kannst innerhalb von $hours Std. nach dem Ende widersprechen.';
  }

  @override
  String get srvBookingGuestSaysPaid => 'gibt an, die Buchung bezahlt zu haben';

  @override
  String get srvBookingPaymentConfirmed => 'hat deine Zahlung bestätigt';

  @override
  String get srvBookingProblemReported =>
      'hat ein Problem mit der Buchung gemeldet';

  @override
  String get srvBookingReportReviewed => 'Deine Meldung wurde geprüft';

  @override
  String get srvBookingHostWarning => 'Warnung zu einer deiner Buchungen';

  @override
  String get srvBookingReportReviewedHost =>
      'Eine Buchungsmeldung wurde geprüft';

  @override
  String srvBookingReviewedBody(String title) {
    return '$title.';
  }

  @override
  String srvBookingReviewedRefundBody(String title, int percent) {
    return '$title. Zu erstattender Betrag: $percent %.';
  }

  @override
  String get srvBookingCancelled => 'Deine Buchung wurde storniert';

  @override
  String srvBookingNoLongerAvailable(String title) {
    return '$title ist nicht mehr verfügbar.';
  }

  @override
  String get srvBookingComingUp => 'Dein Erlebnis steht bevor';

  @override
  String get srvBookingHostingSoon => 'Du bist bald Gastgeber';

  @override
  String get srvBookingRequestExpired => 'Deine Buchungsanfrage ist abgelaufen';

  @override
  String srvBookingRequestExpiredBody(String title) {
    return '$title – der Gastgeber hat nicht rechtzeitig geantwortet.';
  }

  @override
  String get srvBookingHowWasIt => 'Wie war dein Erlebnis?';

  @override
  String srvBookingReviewIt(String title) {
    return 'Bewerte $title';
  }

  @override
  String get srvBookingReviewGuest => 'Bewerte deinen Gast';

  @override
  String srvBookingPayLink(String title) {
    return '$title – bezahle den Gastgeber über seinen Zahlungslink.';
  }

  @override
  String srvBookingPayOnline(String title) {
    return '$title – bezahle in der App, um dein Ticket zu erhalten.';
  }

  @override
  String srvBookingPayCash(String title) {
    return '$title – bezahle den Gastgeber beim Treffen in bar.';
  }

  @override
  String get srvHostReviewedYou => 'Dein Gastgeber hat dich bewertet';

  @override
  String get srvHostReviewedYouBody =>
      'Bewerte dein Erlebnis, um zu sehen, was er geschrieben hat.';

  @override
  String get srvNewReviewFromHost =>
      'Du hast eine neue Bewertung von einem Gastgeber';

  @override
  String get srvGuestLeftReview => 'Dein Gast hat eine Bewertung hinterlassen';

  @override
  String get srvGuestLeftReviewBody =>
      'Bewerte deinen Gast, um beide Bewertungen zu sehen.';

  @override
  String get srvSupportNewMessageOnTicket =>
      'Neue Nachricht zu einem Support-Ticket';

  @override
  String get srvSupportUserSentMessage =>
      'Ein Nutzer hat eine neue Nachricht gesendet.';

  @override
  String get srvVerificationResubmit =>
      'Bitte reiche ein neues Verifizierungsfoto ein.';

  @override
  String srvVerificationResubmitReason(String reason) {
    return 'Bitte reiche ein neues Verifizierungsfoto ein. Grund: $reason';
  }

  @override
  String get srvVerificationRejected =>
      'Deine Verifizierung wurde nicht genehmigt. Bitte versuche es erneut.';

  @override
  String srvVerificationRejectedReason(String reason) {
    return 'Deine Verifizierung wurde nicht genehmigt. Grund: $reason';
  }

  @override
  String srvBundleNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Nachrichten',
      one: '1 neue Nachricht',
    );
    return '$_temp0';
  }

  @override
  String srvBundleLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dein Profil gefällt $count Personen',
      one: 'Dein Profil gefällt 1 Person',
    );
    return '$_temp0';
  }

  @override
  String srvBundleProfileViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Profilaufrufe',
      one: '1 Profilaufruf',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNewConnections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Verbindungen',
      one: '1 neue Verbindung',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benachrichtigungen',
      one: '1 Benachrichtigung',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNamesAndOthers(String names, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere',
      one: '1 weitere Person',
    );
    return '$names und $_temp0';
  }

  @override
  String srvLevelUpTitle(int level) {
    return 'Level-Aufstieg! Du bist jetzt Level $level!';
  }

  @override
  String srvLevelUpBody(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: 'Glückwunsch! Du hast $coins Münzen verdient.',
      one: 'Glückwunsch! Du hast 1 Münze verdient.',
    );
    return '$_temp0';
  }

  @override
  String srvAchievementUnlockedTitle(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Erste Verbindung',
        'social_butterfly': 'Gesellige Seele',
        'popular': 'Beliebt',
        'video_enthusiast': 'Video-Fan',
        'daily_streak_7': '7-Tage-Serie',
        'daily_streak_30': '30-Tage-Serie',
        'other': 'Neuer Erfolg',
      },
    );
    return 'Erfolg freigeschaltet: $_temp0!';
  }

  @override
  String srvAchievementDescription(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Knüpfe deine erste Verbindung',
        'social_butterfly': 'Sende 100 Nachrichten',
        'popular': 'Knüpfe 50 Verbindungen',
        'video_enthusiast': 'Führe 10 Videoanrufe',
        'daily_streak_7': 'Melde dich 7 Tage in Folge an',
        'daily_streak_30': 'Melde dich 30 Tage in Folge an',
        'other': 'Weiter so!',
      },
    );
    return '$_temp0';
  }

  @override
  String srvChallengeCompletedTitle(String challenge) {
    String _temp0 = intl.Intl.selectLogic(
      challenge,
      {
        'send_5_messages': 'Gesprächsstarter',
        'get_3_matches': 'Netzwerker',
        'complete_profile': 'Profil-Perfektionist',
        'video_call_1': 'Von Angesicht zu Angesicht',
        'other': 'Tägliche Herausforderung',
      },
    );
    return 'Herausforderung geschafft: $_temp0!';
  }

  @override
  String srvChallengeRewardsBody(int xp, int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coins Münzen',
      one: '1 Münze',
    );
    return 'Hol dir deine Belohnungen: $xp XP und $_temp0';
  }

  @override
  String srvSentYouCoins(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'hat dir $amount Münzen geschickt',
      one: 'hat dir 1 Münze geschickt',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyFree(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'Du hast diesen Monat mit deiner kostenlosen Mitgliedschaft $amount Münzen erhalten.',
      one:
          'Du hast diesen Monat mit deiner kostenlosen Mitgliedschaft 1 Münze erhalten.',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyTier(int amount, String tier) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'Du hast diesen Monat mit deiner $tier-Mitgliedschaft $amount Münzen erhalten.',
      one:
          'Du hast diesen Monat mit deiner $tier-Mitgliedschaft 1 Münze erhalten.',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiringTitle => 'Mitgliedschaft läuft bald ab';

  @override
  String srvMembershipExpiringBody(String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Deine $tier-Mitgliedschaft läuft in $days Tagen ab. Verlängere jetzt, um deine Premium-Funktionen zu behalten!',
      one:
          'Deine $tier-Mitgliedschaft läuft in 1 Tag ab. Verlängere jetzt, um deine Premium-Funktionen zu behalten!',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiredTitle => 'Mitgliedschaft abgelaufen';

  @override
  String get srvMembershipExpiredBody =>
      'Deine Mitgliedschaft ist abgelaufen. Schließe eine neue ab, um die Premium-Funktionen wiederherzustellen.';

  @override
  String get srvSubscriptionCancelledTitle => 'Abo gekündigt';

  @override
  String get srvSubscriptionEndedBody =>
      'Deine Mitgliedschaft ist beendet. Du kannst jederzeit im Shop erneut abonnieren.';

  @override
  String get srvPaymentFailedTitle => 'Zahlung fehlgeschlagen';

  @override
  String get srvSubscriptionPaymentFailedBody =>
      'Die Zahlung für dein Abo ist fehlgeschlagen. Aktualisiere deine Zahlungsmethode, damit deine Mitgliedschaft aktiv bleibt.';

  @override
  String get srvGiftFromGreenGo => 'Ein Geschenk von GreenGo';

  @override
  String get srvAccountNotApprovedTitle => 'Konto nicht freigegeben';

  @override
  String srvAccountNotApprovedReason(String reason) {
    return 'Dein Konto konnte nicht freigegeben werden. Grund: $reason';
  }

  @override
  String get srvAccountNotApprovedContactSupport =>
      'Dein Konto konnte nicht freigegeben werden. Bitte kontaktiere den Support.';

  @override
  String get srvEvent => 'Event';

  @override
  String get srvNewEvent => 'Neues Event';

  @override
  String get srvEventStartingNow => 'beginnt jetzt – viel Spaß!';

  @override
  String get srvEventStartsIn6h => 'beginnt in etwa 6 Stunden';

  @override
  String get srvEventIsTomorrow => 'ist morgen – bis dann!';

  @override
  String get srvNewEventInYourCommunity => 'Neues Event in deiner Community';

  @override
  String get srvEventCancelledInYourCommunity =>
      'Event in deiner Community abgesagt';

  @override
  String get srvEventUpdatedInYourCommunity =>
      'Event in deiner Community aktualisiert';

  @override
  String srvEventHasBeenCancelled(String event) {
    return '„$event“ wurde abgesagt';
  }

  @override
  String srvEventNewTime(String event) {
    return 'Neue Uhrzeit für „$event“';
  }

  @override
  String srvEventNewLocation(String event) {
    return 'Neuer Ort für „$event“';
  }

  @override
  String srvAnnouncementTitle(String name) {
    return '📣 $name';
  }

  @override
  String get srvAnnouncementACommunity => '📣 Eine Community';

  @override
  String get srvAnnouncementAnEvent => '📣 Event-Ankündigung';

  @override
  String get srvReportReviewedTitle => 'Deine Meldung wurde geprüft';

  @override
  String get srvReportReviewedActionTaken =>
      'Danke für deine Meldung. Unser Team hat sie geprüft und gemäß den Community-Richtlinien Maßnahmen ergriffen.';

  @override
  String get srvReportReviewedNoViolation =>
      'Danke für deine Meldung. Unser Team hat sie geprüft und keinen Verstoß gegen die Community-Richtlinien festgestellt.';

  @override
  String get srvModerationDecisionTitle =>
      'Eine Moderationsentscheidung zu deinem Konto';

  @override
  String get srvModerationDecisionBody =>
      'Wir haben gemäß den Community-Richtlinien Maßnahmen ergriffen. Tippe, um die Gründe und die Einspruchsmöglichkeit zu sehen.';

  @override
  String get srvNewMessage => 'Neue Nachricht';

  @override
  String get srvGroupCreated => 'Gruppe erstellt';

  @override
  String get srvYouWereAddedToGroup => 'Du wurdest zur Gruppe hinzugefügt';

  @override
  String srvGroupMembersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Mitglieder sind beigetreten',
      one: 'Ein neues Mitglied ist beigetreten',
    );
    return '$_temp0';
  }

  @override
  String get srvUnknownUser => 'Unbekannter Nutzer';

  @override
  String srvCoinsReceivedBody(String name, int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount Münzen',
      one: '1 Münze',
    );
    return '$name hat dir $_temp0 geschickt!';
  }

  @override
  String get srvNewEventFromFollowedBusiness =>
      'Neues Event von einem Unternehmen, dem du folgst';

  @override
  String get srvMessageRemovedByModerator =>
      'Diese Nachricht wurde von einem Moderator entfernt';

  @override
  String get srvSupportAiHandoff =>
      'Ich verstehe, dass du mit einem Menschen sprechen möchtest. Ich verbinde dich jetzt. Ein Mitglied des Support-Teams antwortet in Kürze.';

  @override
  String get becomeBusinessOneWayHint =>
      'Erfordert Platinum. Einmaliges Upgrade: Es kann nicht rückgängig gemacht werden.';

  @override
  String get businessPermanentInfo =>
      'Dein Konto ist dauerhaft ein Unternehmenskonto und kann nicht wieder ein persönliches Konto werden. Die Business-Tools funktionieren, solange Platinum aktiv ist; läuft es ab, werden sie pausiert, bis du verlängerst.';

  @override
  String get paidBusinessOnlyNote =>
      'Kostenpflichtige Tickets sind für Unternehmenskonten verfügbar.';

  @override
  String get paidBusinessOnlyBody =>
      'Kostenlose Events und Erlebnisse stehen allen offen. Um Geld für Tickets oder Buchungen zu verlangen, brauchst du ein aktives Unternehmenskonto (Platinum).';

  @override
  String get paidBusinessPausedNote =>
      'Dein Business ist pausiert: Verlängere Platinum, um wieder kostenpflichtige Tickets zu verkaufen.';

  @override
  String get uexpBusinessRequiredTitle =>
      'Kostenpflichtige Angebote sind für Unternehmenskonten';

  @override
  String get tpErrSellerNotBusiness =>
      'Der Verkauf ist pausiert: Kostenpflichtige Tickets und Buchungen gibt es nur bei aktiven Unternehmenskonten.';

  @override
  String get tpAutoSectionTitle => 'Automatische Zahlung und Bestätigung';

  @override
  String get tpAutoSectionHint =>
      'Verbinde Stripe oder Mercado Pago: Käufer zahlen in der App und ihre Tickets werden sofort bestätigt, ohne manuelle Prüfung.';

  @override
  String get tpManualSectionTitle => 'Manuelle Zahlung und Bestätigung';

  @override
  String get tpManualSectionHint =>
      'Ohne Einrichtung: Käufer zahlen dich direkt mit einer der Zahlungsmethoden unten (oder bar / per Überweisung). Du bestätigst jede Zahlung selbst über die Schaltfläche „Zu bestätigende Zahlungen“ oben; das Ticket wird nach deiner Bestätigung ausgestellt.';

  @override
  String get paymentMethodsSettingsSubtitle =>
      'Wie andere dich direkt bezahlen können (Pix, PayPal…)';

  @override
  String get communitiesBusinessCannotJoin =>
      'Business-Konten koennen keinen Communities beitreten. Schalte den Business-Modus aus, um beizutreten.';

  @override
  String get becomeBusinessPermanentHint =>
      'Einmaliges Upgrade. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get storefrontEnabled => 'Schaufenster ist an';

  @override
  String get storefrontDisabled => 'Schaufenster ist aus';

  @override
  String get storefrontToggleHint =>
      'Schalte dein Schaufenster jederzeit an oder aus';

  @override
  String get tpGetPaidManualInfo =>
      'Ohne Einrichtung: Wähle im Event oder Erlebnis eine deiner Zahlungsmethoden (Profil) oder bar / Überweisung und bestätige jede Zahlung selbst.';

  @override
  String emailTicketSubject(String title) {
    return 'Dein Ticket für $title';
  }

  @override
  String get emailTicketIntro =>
      'Deine Buchung ist bestätigt. Zeig den QR-Code am Eingang: Jeder Code gilt für einen Einlass.';

  @override
  String get emailTicketWhen => 'Wann';

  @override
  String get emailTicketWhere => 'Wo';

  @override
  String get emailTicketTypeLabel => 'Ticketart';

  @override
  String get emailTicketPartySizeLabel => 'Personenzahl';

  @override
  String get emailTicketCodeLabel => 'Buchungscode';

  @override
  String emailTicketQrCaption(int index, int count) {
    return 'Ticket $index von $count';
  }

  @override
  String get emailTicketFooter =>
      'Deine Tickets findest du auch in der GreenGo-App. Teile diese QR-Codes nicht.';

  @override
  String emailParticipantsSubject(String title) {
    return 'Teilnehmerliste: $title';
  }

  @override
  String emailParticipantsIntro(String title, String when, int count) {
    return 'Im Anhang findest du die Teilnehmerliste für $title ($when). Teilnehmende: $count.';
  }

  @override
  String get emailParticipantsPrivacy =>
      'Diese Datei enthält personenbezogene Daten, die nur für den Einlass geteilt werden. Gib sie nicht weiter und lösche sie nach der Veranstaltung.';

  @override
  String get csvColName => 'Name';

  @override
  String get csvColEmail => 'E-Mail';

  @override
  String get csvColBookingCode => 'Buchungscode';

  @override
  String get csvColTicket => 'Ticketart / Personenzahl';

  @override
  String get csvColStatus => 'Status';

  @override
  String get csvStatusPaid => 'bezahlt';

  @override
  String get csvStatusConfirmed => 'bestätigt';

  @override
  String get csvStatusCheckedIn => 'eingecheckt';

  @override
  String get participantsEmailButton => 'Teilnehmerliste per E-Mail senden';

  @override
  String get participantsEmailSent =>
      'Teilnehmerliste an deine Konto-E-Mail gesendet';

  @override
  String get participantsEmailRateLimited =>
      'Du hast sie gerade angefordert. Versuch es in ein paar Minuten erneut.';

  @override
  String get participantsEmailFailed =>
      'Die Teilnehmerliste konnte nicht gesendet werden. Bitte versuch es später erneut.';

  @override
  String get participantsEmailNoEmail =>
      'Dein Konto hat keine E-Mail-Adresse für den Versand.';

  @override
  String get checkoutOrganizerShareNotice =>
      'Dein Name und deine E-Mail-Adresse werden für den Einlass an den Veranstalter weitergegeben.';

  @override
  String get openSourceLicensesTitle => 'Open-Source-Lizenzen';

  @override
  String get openSourceLicensesSubtitle =>
      'In dieser App verwendete Schriftarten und Softwarekomponenten';

  @override
  String get screenProtectionRecordingTitle =>
      'Bildschirmaufnahme ist nicht erlaubt';

  @override
  String get screenProtectionRecordingBody =>
      'Beende die Aufnahme oder Bildschirmspiegelung, um GreenGo weiter zu nutzen.';

  @override
  String get screenProtectionHiddenTitle => 'Inhalt ausgeblendet';

  @override
  String get screenProtectionHiddenBody =>
      'GreenGo blendet Inhalte aus, solange das Fenster nicht im Fokus ist. Klicke hier, um fortzufahren.';

  @override
  String get screenProtectionScreenshotsNotAllowed =>
      'Screenshots sind nicht erlaubt';

  @override
  String get screenProtectionAppOnlyTitle =>
      'In der GreenGo-App öffnen, um es anzusehen';

  @override
  String get screenProtectionAppOnlyBody =>
      'Zum Schutz der Privatsphäre sind private Fotos und die Ausweisprüfung nur in der GreenGo-App verfügbar.';

  @override
  String get screenProtectionOpenApp => 'App öffnen';

  @override
  String chatSystemScreenshotTaken(String name) {
    return '$name hat einen Screenshot gemacht';
  }

  @override
  String get guidelinesPrivacyCaptureTitle => 'Privatsphäre respektieren';

  @override
  String get guidelinesPrivacyCaptureDesc =>
      'Screenshots und Aufnahmen von Inhalten anderer werden blockiert oder gemeldet; Fotos anderer ohne Einwilligung zu teilen ist verboten.';
}
