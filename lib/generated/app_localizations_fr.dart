// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get culturalPassportTitle => 'Passeport culturel';

  @override
  String get culturalPassportSubtitle =>
      'Les tampons que tu collectionnes auprès des cultures, langues et événements que tu explores';

  @override
  String get passportSectionCountries => 'Pays';

  @override
  String get passportSectionLanguages => 'Langues';

  @override
  String get passportSectionEvents => 'Événements';

  @override
  String get passportLoading => 'Chargement de ton passeport…';

  @override
  String get passportEarned => 'Obtenu';

  @override
  String get passportLocked => 'Verrouillé';

  @override
  String get passportEmpty =>
      'Commence à discuter, à apprendre des langues et à participer à des événements pour gagner tes premiers tampons.';

  @override
  String passportProgressSummary(int countries, int languages, int events) {
    return '$countries pays · $languages langues · $events événements';
  }

  @override
  String passportOverallProgress(int percent) {
    return '$percent% exploré';
  }

  @override
  String get passportEventDating => 'Sorties';

  @override
  String get passportEventSocial => 'Social';

  @override
  String get passportEventSports => 'Sports';

  @override
  String get passportEventFood => 'Cuisine';

  @override
  String get passportEventNightlife => 'Vie nocturne';

  @override
  String get passportEventOutdoor => 'Plein air';

  @override
  String get passportEventArts => 'Arts';

  @override
  String get passportEventGaming => 'Jeux vidéo';

  @override
  String get passportEventTravel => 'Voyage';

  @override
  String get passportEventWellness => 'Bien-être';

  @override
  String get passportEventLanguageExchange => 'Échange linguistique';

  @override
  String get passportEventOther => 'Autre';

  @override
  String get tourGotIt => 'Compris';

  @override
  String get tourWelcomeTitle => 'Bienvenue sur GreenGo !';

  @override
  String get tourWelcomeDesc =>
      'Voici ta grille Découverte : de vraies personnes autour de toi, triées par distance. Découvrons les gestes qui rendent GreenGo rapide à utiliser.';

  @override
  String get tourCardTapTitle => 'Touche une carte';

  @override
  String get tourCardTapDesc =>
      'Touchez le centre d\'une carte pour ouvrir le menu d\'actions — se connecter, Priority Connect ou voir le profil complet.';

  @override
  String get tourCardEdgeTitle => 'Parcours les photos';

  @override
  String get tourCardEdgeDesc =>
      'Touche le bord gauche ou droit d\'une carte pour faire défiler les photos de la personne sans quitter la grille.';

  @override
  String get tourCardHoldTitle => 'Maintiens pour prévisualiser';

  @override
  String get tourCardHoldDesc =>
      'Maintiens une carte appuyée pour voir les photos en plein écran.';

  @override
  String get tourRefreshTitle => 'Tire pour actualiser';

  @override
  String get tourRefreshDesc =>
      'Fais glisser la grille vers le bas à tout moment pour charger les nouvelles personnes autour de toi.';

  @override
  String get tourModeToggleTitle => 'Mode swipe';

  @override
  String get tourModeToggleDesc =>
      'Touchez ici pour passer de la grille au mode swipe. En mode swipe : glissez à droite pour vous connecter, à gauche pour passer, vers le haut pour envoyer un Priority Connect.';

  @override
  String get tourGlobeTitle => 'Explore le globe';

  @override
  String get tourGlobeDesc =>
      'Ouvre le globe 3D pour découvrir des personnes du monde entier, pas seulement à proximité.';

  @override
  String get tourSearchTitle => 'Recherche par pseudo';

  @override
  String get tourSearchDesc =>
      'Tu sais qui tu cherches ? Trouve des personnes directement par leur pseudo.';

  @override
  String get tourPrefsTitle => 'Filtres de découverte';

  @override
  String get tourPrefsDesc =>
      'Affine qui tu découvres : distance, âge, langues, pays et plus encore.';

  @override
  String get tourCoinsTitle => 'Tes pièces';

  @override
  String get tourCoinsDesc =>
      'Tu reçois des pièces gratuites chaque jour. Touche ton solde à tout moment pour ouvrir la Boutique.';

  @override
  String get tourHelpTitle => 'Besoin d\'un rappel ?';

  @override
  String get tourHelpDesc =>
      'Le guide de l\'app se trouve ici — y compris ce tutoriel, que tu peux rejouer à tout moment.';

  @override
  String get tourNavMessagesTitle => 'Messages';

  @override
  String get tourNavMessagesDesc =>
      'Discute sans barrière de langue : maintiens un message pour le traduire, touche-le deux fois pour l\'écouter.';

  @override
  String get tourNavLeaderboardTitle => 'Classement';

  @override
  String get tourNavLeaderboardDesc =>
      'Gagne de l\'XP et des badges en te connectant, en discutant et en apprenant. Vois ton rang.';

  @override
  String get tourNavShopTitle => 'Boutique';

  @override
  String get tourNavShopDesc =>
      'Des packs de pièces et des abonnements pour débloquer plus de GreenGo.';

  @override
  String get tourNavProfileTitle => 'Ton profil';

  @override
  String get tourNavProfileDesc =>
      'Complète ton profil et ta vérification pour être découvert par plus de personnes.';

  @override
  String get tourFinishTitle => 'Tout est prêt !';

  @override
  String get tourFinishDesc =>
      'Profite de la découverte de nouvelles personnes et cultures. Tu peux rejouer ce tutoriel à tout moment depuis le guide (icône ?).';

  @override
  String get tourSwipeHintTitle => 'Swipe pour te connecter';

  @override
  String get tourSwipeHintLike => 'J\'aime';

  @override
  String get tourSwipeHintPass => 'Passer';

  @override
  String get tourSwipeHintSuper => 'Priority Connect';

  @override
  String get tourChatHoldTitle => 'Maintiens un message';

  @override
  String get tourChatHoldDesc =>
      'Maintiens n\'importe quel message pour le traduire, le copier ou le transférer.';

  @override
  String get tourChatDoubleTapTitle => 'Écoute-le';

  @override
  String get tourChatDoubleTapDesc =>
      'Touche deux fois un message reçu pour entendre sa prononciation.';

  @override
  String get tourChatLanguageTitle => 'Langues et apprentissage';

  @override
  String get tourChatLanguageDesc =>
      'Ouvre le menu de traduction pour les outils de langue : paramètres de traduction, entraînement à la prononciation et fonctions d\'apprentissage.';

  @override
  String get tourChatSettingsTitle => 'Options du chat';

  @override
  String get tourChatSettingsDesc =>
      'Gère cette conversation : paramètres du chat, supprimer, bloquer ou signaler.';

  @override
  String get tourDetailDoubleTapTitle => 'Like une photo';

  @override
  String get tourDetailDoubleTapDesc =>
      'Touche deux fois n\'importe quelle photo pour la liker.';

  @override
  String get tourStoryHoldHint => 'Maintiens pour mettre en pause';

  @override
  String get guideReplayTour => 'Rejouer le tutoriel';

  @override
  String get abandonGame => 'Abandonner la Partie';

  @override
  String get about => 'À propos';

  @override
  String get aboutMe => 'À Propos de Moi';

  @override
  String get aboutMeTitle => 'À propos de moi';

  @override
  String get academicCategory => 'Académique';

  @override
  String get acceptPrivacyPolicy =>
      'J\'ai lu et j\'accepte la Politique de Confidentialité';

  @override
  String get acceptProfiling =>
      'Je consens au profilage pour des recommandations personnalisées';

  @override
  String get acceptTermsAndConditions =>
      'J\'ai lu et j\'accepte les Conditions Générales';

  @override
  String get acceptThirdPartyData =>
      'Je consens au partage de mes données avec des tiers';

  @override
  String get accessGranted => 'Accès accordé !';

  @override
  String accessGrantedBody(Object tierName) {
    return 'GreenGo est maintenant actif ! En tant que $tierName, vous avez désormais accès à toutes les fonctionnalités.';
  }

  @override
  String get accountApproved => 'Compte Approuvé';

  @override
  String get accountApprovedBody =>
      'Votre compte GreenGo a été approuvé. Bienvenue dans la communauté !';

  @override
  String get accountCreatedSuccess =>
      'Compte créé ! Veuillez vérifier votre e-mail pour valider votre compte.';

  @override
  String get accountPendingApproval => 'Compte en Attente d\'Approbation';

  @override
  String get accountRejected => 'Compte Refusé';

  @override
  String get accountSettings => 'Paramètres du Compte';

  @override
  String get accountUnderReview => 'Compte en Révision';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Succès';

  @override
  String get achievementsSubtitle => 'Voir vos badges et votre progression';

  @override
  String get achievementsTitle => 'Réalisations';

  @override
  String get addBio => 'Ajouter une biographie';

  @override
  String get addDealBreakerTitle => 'Ajouter un Critere Eliminatoire';

  @override
  String get addPhoto => 'Ajouter une Photo';

  @override
  String get adjustPreferences => 'Ajuster les Préférences';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Code envoyé à $email';
  }

  @override
  String get admin2faExpired => 'Code expiré. Veuillez en demander un nouveau.';

  @override
  String get admin2faInvalidCode => 'Code de vérification invalide';

  @override
  String get admin2faMaxAttempts =>
      'Trop de tentatives. Veuillez demander un nouveau code.';

  @override
  String get admin2faResend => 'Renvoyer le Code';

  @override
  String admin2faResendIn(String seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get admin2faSending => 'Envoi du code...';

  @override
  String get admin2faSignOut => 'Se Déconnecter';

  @override
  String get admin2faSubtitle =>
      'Entrez le code à 6 chiffres envoyé à votre e-mail';

  @override
  String get admin2faTitle => 'Vérification Admin';

  @override
  String get admin2faVerify => 'Vérifier';

  @override
  String get adminAccessDates => 'Dates d\'accès :';

  @override
  String get adminAccountLockedSuccessfully => 'Compte verrouillé avec succès';

  @override
  String get adminAccountUnlockedSuccessfully =>
      'Compte déverrouillé avec succès';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Les comptes admin ne peuvent pas être supprimés';

  @override
  String adminAchievementCount(Object count) {
    return '$count succès';
  }

  @override
  String get adminAchievementUpdated => 'Succès mis à jour';

  @override
  String get adminAchievements => 'Succès';

  @override
  String get adminAchievementsSubtitle => 'Gérer les succès et les badges';

  @override
  String get adminActive => 'ACTIF';

  @override
  String adminActiveCount(Object count) {
    return 'Actifs ($count)';
  }

  @override
  String get adminActiveEvent => 'Événement actif';

  @override
  String get adminActiveUsers => 'Utilisateurs actifs';

  @override
  String get adminAdd => 'Ajouter';

  @override
  String get adminAddCoins => 'Ajouter des pièces';

  @override
  String get adminAddPackage => 'Ajouter un forfait';

  @override
  String get adminAddResolutionNote => 'Ajouter une note de résolution...';

  @override
  String get adminAddSingleEmail => 'Ajouter un e-mail';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return '$amount pièces ajoutées à l\'utilisateur';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Ajouté le $date';
  }

  @override
  String get adminAdvancedFilters => 'Filtres avancés';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age ans - $gender';
  }

  @override
  String get adminAll => 'Tous';

  @override
  String get adminAllReports => 'Tous les signalements';

  @override
  String get adminAmount => 'Montant';

  @override
  String get adminAnalyticsAndReports => 'Analyses et rapports';

  @override
  String get adminAppSettings => 'Paramètres de l\'application';

  @override
  String get adminAppSettingsSubtitle =>
      'Paramètres généraux de l\'application';

  @override
  String get adminApproveSelected => 'Approuver la sélection';

  @override
  String get adminAssignToMe => 'M\'assigner';

  @override
  String get adminAssigned => 'Assigné';

  @override
  String get adminAvailable => 'Disponible';

  @override
  String get adminBadge => 'Badge';

  @override
  String get adminBaseCoins => 'Pièces de base';

  @override
  String get adminBaseXp => 'XP de base';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount pièces bonus';
  }

  @override
  String get adminBonusCoinsLabel => 'Pièces bonus';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes bonus';
  }

  @override
  String get adminBrowseProfilesAnonymously =>
      'Parcourir les profils anonymement';

  @override
  String get adminCanSendMedia => 'Peut envoyer des médias';

  @override
  String adminChallengeCount(Object count) {
    return '$count défis';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'Interface de création de défis bientôt disponible.';

  @override
  String get adminChallenges => 'Défis';

  @override
  String get adminChangesSaved => 'Modifications enregistrées';

  @override
  String get adminChatWithReporter => 'Discuter avec le signaleur';

  @override
  String get adminClear => 'Effacer';

  @override
  String get adminClosed => 'Fermé';

  @override
  String get adminCoinAmount => 'Montant en pièces';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount pièces';
  }

  @override
  String get adminCoinCost => 'Coût en pièces';

  @override
  String get adminCoinManagement => 'Gestion des pièces';

  @override
  String get adminCoinManagementSubtitle =>
      'Gérer les forfaits de pièces et les soldes utilisateurs';

  @override
  String get adminCoinPackages => 'Forfaits de pièces';

  @override
  String get adminCoinReward => 'Récompense en pièces';

  @override
  String adminComingSoon(Object route) {
    return '$route bientôt disponible';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Configurations réinitialisées aux valeurs par défaut. Enregistrez pour appliquer.';

  @override
  String get adminConfigureLimitsAndFeatures =>
      'Configurer les limites et les fonctionnalités';

  @override
  String get adminConfigureMilestoneRewards =>
      'Configurer les récompenses par palier pour les connexions consécutives';

  @override
  String get adminCreateChallenge => 'Créer un défi';

  @override
  String get adminCreateEvent => 'Créer un événement';

  @override
  String get adminCreateNewChallenge => 'Créer un nouveau défi';

  @override
  String get adminCreateSeasonalEvent => 'Créer un événement saisonnier';

  @override
  String get adminCsvFormat => 'Format CSV :';

  @override
  String get adminCsvFormatDescription =>
      'Un e-mail par ligne, ou valeurs séparées par des virgules. Les guillemets sont automatiquement supprimés. Les e-mails invalides sont ignorés.';

  @override
  String get adminCurrentBalance => 'Solde actuel';

  @override
  String get adminDailyChallenges => 'Défis quotidiens';

  @override
  String get adminDailyChallengesSubtitle =>
      'Configurer les défis quotidiens et les récompenses';

  @override
  String get adminDailyLimits => 'Limites quotidiennes';

  @override
  String get adminDailyLoginRewards => 'Récompenses de connexion quotidienne';

  @override
  String get adminDailyMessages => 'Messages quotidiens';

  @override
  String get adminDailySuperLikes => 'Connexions Prioritaires quotidiennes';

  @override
  String get adminDailySwipes => 'Swipes quotidiens';

  @override
  String get adminDashboard => 'Tableau de bord administrateur';

  @override
  String get adminDate => 'Date';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return 'Êtes-vous sûr de vouloir supprimer le forfait \"$amount pièces\" ?';
  }

  @override
  String get adminDeletePackageTitle => 'Supprimer le forfait ?';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminDeselectAll => 'Tout désélectionner';

  @override
  String get adminDisabled => 'Désactivé';

  @override
  String get adminDismiss => 'Rejeter';

  @override
  String get adminDismissReport => 'Rejeter le signalement';

  @override
  String get adminDismissReportConfirm =>
      'Êtes-vous sûr de vouloir rejeter ce signalement ?';

  @override
  String get adminEarlyAccessDate => '14 mars 2026';

  @override
  String get adminEarlyAccessDates =>
      'Les utilisateurs de cette liste obtiennent l\'accès le 14 mars 2026.\nTous les autres utilisateurs obtiennent l\'accès le 14 avril 2026.';

  @override
  String get adminEarlyAccessInList => 'Accès anticipé (dans la liste)';

  @override
  String get adminEarlyAccessInfo => 'Informations sur l\'accès anticipé';

  @override
  String get adminEarlyAccessList => 'Liste d\'accès anticipé';

  @override
  String get adminEarlyAccessProgram => 'Programme d\'accès anticipé';

  @override
  String get adminEditAchievement => 'Modifier le succès';

  @override
  String adminEditItem(Object name) {
    return 'Modifier $name';
  }

  @override
  String adminEditMilestone(Object name) {
    return 'Modifier $name';
  }

  @override
  String get adminEditPackage => 'Modifier le forfait';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email ajouté à la liste d\'accès anticipé';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count e-mails';
  }

  @override
  String get adminEmailList => 'Liste d\'e-mails';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email retiré de la liste d\'accès anticipé';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Activer les options de filtrage avancé';

  @override
  String get adminEngagementReports => 'Rapports d\'engagement';

  @override
  String get adminEngagementReportsSubtitle =>
      'Voir les statistiques de connexions et de messages';

  @override
  String get adminEnterEmailAddress => 'Saisir l\'adresse e-mail';

  @override
  String get adminEnterValidAmount => 'Veuillez saisir un montant valide';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Veuillez saisir un montant de pièces et un prix valides';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Erreur lors de l\'ajout de l\'e-mail : $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Erreur lors du chargement du contexte : $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Erreur lors du chargement des données : $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Erreur lors de l\'ouverture du chat : $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Erreur lors de la suppression de l\'e-mail : $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Erreur : $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Erreur lors du téléversement du fichier : $error';
  }

  @override
  String get adminErrors => 'Erreurs :';

  @override
  String get adminEventCreationComingSoon =>
      'Interface de création d\'événements bientôt disponible.';

  @override
  String get adminEvents => 'Événements';

  @override
  String adminFailedToSave(Object error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get adminFeatures => 'Fonctionnalités';

  @override
  String get adminFilterByInterests => 'Filtrer par centres d\'intérêt';

  @override
  String get adminFilterBySpecificLocation => 'Filtrer par lieu spécifique';

  @override
  String get adminFilterBySpokenLanguages => 'Filtrer par langues parlées';

  @override
  String get adminFilterByVerificationStatus =>
      'Filtrer par statut de vérification';

  @override
  String get adminFilterOptions => 'Options de filtre';

  @override
  String get adminGamification => 'Ludification';

  @override
  String get adminGamificationAndRewards => 'Ludification et récompenses';

  @override
  String get adminGeneralAccess => 'Accès général';

  @override
  String get adminGeneralAccessDate => '14 avril 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Priorité plus élevée = affiché en premier dans la découverte';

  @override
  String get adminImportResult => 'Résultat de l\'importation';

  @override
  String get adminInProgress => 'En cours';

  @override
  String get adminIncognitoMode => 'Mode incognito';

  @override
  String get adminInterestFilter => 'Filtre par intérêts';

  @override
  String get adminInvoices => 'Factures';

  @override
  String get adminLanguageFilter => 'Filtre par langue';

  @override
  String get adminLoading => 'Chargement...';

  @override
  String get adminLocationFilter => 'Filtre par lieu';

  @override
  String get adminLockAccount => 'Verrouiller le compte';

  @override
  String adminLockAccountConfirm(Object userId) {
    return 'Verrouiller le compte de l\'utilisateur $userId... ?';
  }

  @override
  String get adminLockDuration => 'Durée du verrouillage';

  @override
  String adminLockReasonLabel(Object reason) {
    return 'Motif : $reason';
  }

  @override
  String adminLockedCount(Object count) {
    return 'Verrouillés ($count)';
  }

  @override
  String adminLockedDate(Object date) {
    return 'Verrouillé le : $date';
  }

  @override
  String get adminLoginStreakSystem => 'Système de séries de connexion';

  @override
  String get adminLoginStreaks => 'Séries de connexion';

  @override
  String get adminLoginStreaksSubtitle =>
      'Configurer les paliers et récompenses de séries';

  @override
  String get adminManageAppSettings =>
      'Gérer les paramètres de votre application GreenGo';

  @override
  String get adminMatchPriority => 'Priorité de connexion';

  @override
  String get adminMatchingAndVisibility => 'Connexions et visibilité';

  @override
  String get adminMessageContext => 'Contexte du message (50 avant/après)';

  @override
  String get adminMilestoneUpdated => 'Palier mis à jour';

  @override
  String adminMoreErrors(Object count) {
    return '... et $count erreurs supplémentaires';
  }

  @override
  String get adminName => 'Nom';

  @override
  String get adminNinetyDays => '90 jours';

  @override
  String get adminNoEmailsInEarlyAccessList =>
      'Aucun e-mail dans la liste d\'accès anticipé';

  @override
  String get adminNoInvoicesFound => 'Aucune facture trouvée';

  @override
  String get adminNoLockedAccounts => 'Aucun compte verrouillé';

  @override
  String get adminNoMatchingEmailsFound => 'Aucun e-mail correspondant trouvé';

  @override
  String get adminNoOrdersFound => 'Aucune commande trouvée';

  @override
  String get adminNoPendingReports => 'Aucun signalement en attente';

  @override
  String get adminNoReportsYet => 'Aucun signalement pour le moment';

  @override
  String adminNoTickets(Object status) {
    return 'Aucun ticket $status';
  }

  @override
  String get adminNoValidEmailsFound =>
      'Aucune adresse e-mail valide trouvée dans le fichier';

  @override
  String get adminNoVerificationHistory => 'Aucun historique de vérification';

  @override
  String get adminOneDay => '1 jour';

  @override
  String get adminOpen => 'Ouvert';

  @override
  String adminOpenCount(Object count) {
    return 'Ouverts ($count)';
  }

  @override
  String get adminOpenTickets => 'Tickets ouverts';

  @override
  String get adminOrderDetails => 'Détails de la commande';

  @override
  String get adminOrderId => 'ID de commande';

  @override
  String get adminOrderRefunded => 'Commande remboursée';

  @override
  String get adminOrders => 'Commandes';

  @override
  String get adminPackages => 'Forfaits';

  @override
  String get adminPanel => 'Panneau Admin';

  @override
  String get adminPayment => 'Paiement';

  @override
  String get adminPending => 'En attente';

  @override
  String adminPendingCount(Object count) {
    return 'En attente ($count)';
  }

  @override
  String get adminPermanent => 'Permanent';

  @override
  String get adminPleaseEnterValidEmail =>
      'Veuillez saisir une adresse e-mail valide';

  @override
  String get adminPriceUsd => 'Prix (USD)';

  @override
  String get adminProductIdIap => 'ID produit (pour IAP)';

  @override
  String get adminProfileVisitors => 'Visiteurs du profil';

  @override
  String get adminPromotional => 'Promotionnel';

  @override
  String get adminPromotionalPackage => 'Forfait promotionnel';

  @override
  String get adminPromotions => 'Promotions';

  @override
  String get adminPromotionsSubtitle =>
      'Gérer les offres spéciales et les promotions';

  @override
  String get adminProvideReason => 'Veuillez fournir un motif';

  @override
  String get adminReadReceipts => 'Accusés de lecture';

  @override
  String get adminReason => 'Motif';

  @override
  String adminReasonLabel(Object reason) {
    return 'Motif : $reason';
  }

  @override
  String get adminReasonRequired => 'Motif (obligatoire)';

  @override
  String get adminRefund => 'Rembourser';

  @override
  String get adminRemove => 'Supprimer';

  @override
  String get adminRemoveCoins => 'Retirer des pièces';

  @override
  String get adminRemoveEmail => 'Supprimer l\'e-mail';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return 'Êtes-vous sûr de vouloir supprimer \"$email\" de la liste d\'accès anticipé ?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return '$amount pièces retirées de l\'utilisateur';
  }

  @override
  String get adminReportDismissed => 'Signalement rejeté';

  @override
  String get adminReportFollowupStarted =>
      'Conversation de suivi du signalement démarrée';

  @override
  String get adminReportedMessage => 'Message signalé :';

  @override
  String get adminReportedMessageMarker => '^ MESSAGE SIGNALÉ';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'ID utilisateur signalé : $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'ID du signaleur : $reporterId...';
  }

  @override
  String get adminReports => 'Signalements';

  @override
  String get adminReportsManagement => 'Gestion des signalements';

  @override
  String get adminRequestNewPhoto => 'Demander une nouvelle photo';

  @override
  String get adminRequiredCount => 'Nombre requis';

  @override
  String adminRequiresCount(Object count) {
    return 'Requiert : $count';
  }

  @override
  String get adminReset => 'Réinitialiser';

  @override
  String get adminResetToDefaults => 'Réinitialiser par défaut';

  @override
  String get adminResetToDefaultsConfirm =>
      'Cela réinitialisera toutes les configurations de niveaux à leurs valeurs par défaut. Cette action est irréversible.';

  @override
  String get adminResetToDefaultsTitle => 'Réinitialiser par défaut ?';

  @override
  String get adminResolutionNote => 'Note de résolution';

  @override
  String get adminResolve => 'Résoudre';

  @override
  String get adminResolved => 'Résolu';

  @override
  String adminResolvedCount(Object count) {
    return 'Résolus ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Analyses des revenus';

  @override
  String get adminRevenueAnalyticsSubtitle =>
      'Suivre les achats et les revenus';

  @override
  String get adminReviewedBy => 'Examiné par';

  @override
  String get adminRewardAmount => 'Montant de la récompense';

  @override
  String get adminSaving => 'Enregistrement...';

  @override
  String get adminScheduledEvents => 'Événements planifiés';

  @override
  String get adminSearchByUserIdOrEmail =>
      'Rechercher par ID utilisateur ou e-mail';

  @override
  String get adminSearchEmails => 'Rechercher des e-mails...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Rechercher un utilisateur pour gérer son solde de pièces';

  @override
  String get adminSearchOrders => 'Rechercher des commandes...';

  @override
  String get adminSeeWhenMessagesAreRead => 'Voir quand les messages sont lus';

  @override
  String get adminSeeWhoVisitedProfile => 'Voir qui a visité leur profil';

  @override
  String get adminSelectAll => 'Tout sélectionner';

  @override
  String get adminSelectCsvFile => 'Sélectionner un fichier CSV';

  @override
  String adminSelectedCount(Object count) {
    return '$count sélectionné(s)';
  }

  @override
  String get adminSendImagesAndVideosInChat =>
      'Envoyer des images et vidéos dans le chat';

  @override
  String get adminSevenDays => '7 jours';

  @override
  String get adminSpendItems => 'Articles à dépenser';

  @override
  String get adminStatistics => 'Statistiques';

  @override
  String get adminStatus => 'Statut';

  @override
  String get adminStreakMilestones => 'Paliers de série';

  @override
  String get adminStreakMultiplier => 'Multiplicateur de série';

  @override
  String get adminStreakMultiplierValue => '1,5x par jour';

  @override
  String get adminStreaks => 'Séries';

  @override
  String get adminSupport => 'Assistance';

  @override
  String get adminSupportAgents => 'Agents d\'assistance';

  @override
  String get adminSupportAgentsSubtitle =>
      'Gérer les comptes des agents d\'assistance';

  @override
  String get adminSupportManagement => 'Gestion de l\'assistance';

  @override
  String get adminSupportRequest => 'Demande d\'assistance';

  @override
  String get adminSupportTickets => 'Tickets d\'assistance';

  @override
  String get adminSupportTicketsSubtitle =>
      'Voir et gérer les conversations d\'assistance des utilisateurs';

  @override
  String get adminSystemConfiguration => 'Configuration du système';

  @override
  String get adminThirtyDays => '30 jours';

  @override
  String get adminTicketAssignedToYou => 'Ticket qui vous est assigné';

  @override
  String get adminTicketAssignment => 'Attribution des tickets';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Attribuer les tickets aux agents d\'assistance';

  @override
  String get adminTicketClosed => 'Ticket fermé';

  @override
  String get adminTicketResolved => 'Ticket résolu';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Configurations des niveaux enregistrées avec succès';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Gestion des niveaux';

  @override
  String get adminTierManagementSubtitle =>
      'Configurer les limites et fonctionnalités des niveaux';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Aujourd\'hui';

  @override
  String get adminTotalMinutes => 'Minutes totales';

  @override
  String get adminType => 'Type';

  @override
  String get adminUnassigned => 'Non assigné';

  @override
  String get adminUnknown => 'Inconnu';

  @override
  String get adminUnlimited => 'Illimité';

  @override
  String get adminUnlock => 'Déverrouiller';

  @override
  String get adminUnlockAccount => 'Déverrouiller le compte';

  @override
  String get adminUnlockAccountConfirm =>
      'Êtes-vous sûr de vouloir déverrouiller ce compte ?';

  @override
  String get adminUnresolved => 'Non résolu';

  @override
  String get adminUploadCsvDescription =>
      'Téléverser un fichier CSV contenant des adresses e-mail (une par ligne ou séparées par des virgules)';

  @override
  String get adminUploadCsvFile => 'Téléverser un fichier CSV';

  @override
  String get adminUploading => 'Téléversement...';

  @override
  String get adminUsedMinutes => 'Minutes utilisées';

  @override
  String get adminUser => 'Utilisateur';

  @override
  String get adminUserAnalytics => 'Analyses des utilisateurs';

  @override
  String get adminUserAnalyticsSubtitle =>
      'Voir les métriques d\'engagement et de croissance des utilisateurs';

  @override
  String get adminUserBalance => 'Solde de l\'utilisateur';

  @override
  String get adminUserId => 'ID utilisateur';

  @override
  String adminUserIdLabel(Object userId) {
    return 'ID utilisateur : $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'Utilisateur : $userId...';
  }

  @override
  String get adminUserManagement => 'Gestion des utilisateurs';

  @override
  String get adminUserModeration => 'Modération des utilisateurs';

  @override
  String get adminUserModerationSubtitle =>
      'Gérer les bannissements et suspensions des utilisateurs';

  @override
  String get adminUserReports => 'Signalements des utilisateurs';

  @override
  String get adminUserReportsSubtitle =>
      'Examiner et traiter les signalements des utilisateurs';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'Utilisateur : $senderId...';
  }

  @override
  String get adminUserVerifications => 'Vérifications des utilisateurs';

  @override
  String get adminUserVerificationsSubtitle =>
      'Approuver ou rejeter les demandes de vérification des utilisateurs';

  @override
  String get adminVerificationFilter => 'Filtre de vérification';

  @override
  String get adminVerifications => 'Vérifications';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get adminViewContext => 'Voir le contexte';

  @override
  String get adminViewDocument => 'Voir le document';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Violation des règles de la communauté';

  @override
  String get adminWaiting => 'En attente';

  @override
  String adminWaitingCount(Object count) {
    return 'En attente ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Défis hebdomadaires';

  @override
  String get adminWelcome => 'Bienvenue, Administrateur';

  @override
  String get adminXpReward => 'Récompense XP';

  @override
  String get ageRange => 'Tranche d\'Âge';

  @override
  String get aiCoachBenefitAllChapters =>
      'Tous les chapitres d\'apprentissage débloqués';

  @override
  String get aiCoachBenefitFeedback =>
      'Retour en temps réel sur la grammaire et la prononciation';

  @override
  String get aiCoachBenefitPersonalized =>
      'Parcours d\'apprentissage personnalisé';

  @override
  String get aiCoachBenefitUnlimited => 'Pratique de conversation IA illimitée';

  @override
  String get aiCoachLabel => 'Coach IA';

  @override
  String get aiCoachTrialEnded =>
      'Votre essai gratuit du Coach IA est terminé.';

  @override
  String get aiCoachUpgradePrompt =>
      'Passez à Silver, Gold ou Platinum pour débloquer.';

  @override
  String get aiCoachUpgradeTitle => 'Améliorez pour en apprendre plus';

  @override
  String get albumNotShared => 'Album non partagé';

  @override
  String get albumOption => 'Album';

  @override
  String albumRevokedMessage(String username) {
    return '$username a révoqué l\'accès à l\'album';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username a partagé son album avec vous';
  }

  @override
  String get allCategoriesFilter => 'Toutes';

  @override
  String get allDealBreakersAdded =>
      'Tous les critères éliminatoires ont été ajoutés';

  @override
  String get allLanguagesFilter => 'Toutes';

  @override
  String get allPlayersReady => 'Tous les joueurs sont prêts !';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte?';

  @override
  String get appLanguage => 'Langue de l\'App';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Découvrez des cultures et des gens du monde entier';

  @override
  String get approveVerification => 'Approuver';

  @override
  String get atLeast8Characters => 'Au moins 8 caractères';

  @override
  String get atLeastOneNumber => 'Au moins un chiffre';

  @override
  String get atLeastOneSpecialChar => 'Au moins un caractère spécial';

  @override
  String get authAppleSignInComingSoon => 'Connexion Apple bientôt disponible';

  @override
  String get authCancelVerification => 'Annuler la vérification ?';

  @override
  String get authCancelVerificationBody =>
      'Vous serez déconnecté si vous annulez la vérification.';

  @override
  String get authDisableInSettings =>
      'Vous pouvez désactiver cela dans Paramètres > Sécurité';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Un compte existe déjà avec cet e-mail.';

  @override
  String get authErrorGeneric => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail/pseudo ou mot de passe incorrect. Vérifiez vos identifiants et réessayez.';

  @override
  String get authErrorInvalidEmail =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get authErrorNetworkError =>
      'Pas de connexion internet. Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get authErrorUserNotFound =>
      'Aucun compte trouvé avec cet e-mail ou pseudo. Vérifiez et réessayez, ou inscrivez-vous.';

  @override
  String get authErrorWeakPassword =>
      'Le mot de passe est trop faible. Veuillez utiliser un mot de passe plus fort.';

  @override
  String get authErrorWrongPassword =>
      'Mot de passe incorrect. Veuillez réessayer.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'Échec de la prise de photo : $error';
  }

  @override
  String get authIdentityVerification => 'Vérification d\'identité';

  @override
  String get authPleaseEnterEmail => 'Veuillez saisir votre e-mail';

  @override
  String get authRetakePhoto => 'Reprendre la photo';

  @override
  String get authSecurityStep =>
      'Cette étape de sécurité supplémentaire aide à protéger votre compte';

  @override
  String get authSelfieInstruction =>
      'Regardez la caméra et appuyez pour capturer';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authSignOutInstead => 'Se déconnecter à la place';

  @override
  String get authStay => 'Rester';

  @override
  String get authTakeSelfie => 'Prendre un selfie';

  @override
  String get authTakeSelfieToVerify =>
      'Veuillez prendre un selfie pour vérifier votre identité';

  @override
  String get authVerifyAndContinue => 'Vérifier et continuer';

  @override
  String get authVerifyWithSelfie =>
      'Veuillez vérifier votre identité avec un selfie';

  @override
  String authWelcomeBack(Object name) {
    return 'Bon retour, $name !';
  }

  @override
  String get authenticationErrorTitle => 'Échec de Connexion';

  @override
  String get away => 'de distance';

  @override
  String get awesome => 'Super !';

  @override
  String get backToLobby => 'Retour au Salon';

  @override
  String get badgeLocked => 'Verrouillé';

  @override
  String get badgeUnlocked => 'Débloqué';

  @override
  String get achievementUnlockedTitle => 'SUCCÈS DÉBLOQUÉ !';

  @override
  String get achievementUnlockedAwesome => 'Génial !';

  @override
  String get achievementRarityCommon => 'COMMUN';

  @override
  String get achievementRarityUncommon => 'PEU COMMUN';

  @override
  String get achievementRarityRare => 'RARE';

  @override
  String get achievementRarityEpic => 'ÉPIQUE';

  @override
  String get achievementRarityLegendary => 'LÉGENDAIRE';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

  @override
  String get badges => 'Badges';

  @override
  String get basic => 'Basique';

  @override
  String get basicInformation => 'Informations de Base';

  @override
  String get betterPhotoRequested => 'Meilleure photo demandée';

  @override
  String get bio => 'Biographie';

  @override
  String get bioUpdatedMessage => 'La bio de votre profil a été enregistrée';

  @override
  String get bioUpdatedTitle => 'Bio mise à jour !';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonus bonus !)';
  }

  @override
  String get boost => 'Boost';

  @override
  String get boostActivated => 'Boost activé pour 30 minutes !';

  @override
  String get boostNow => 'Booster maintenant';

  @override
  String get boostProfile => 'Booster le Profil';

  @override
  String get boosted => 'BOOSTÉ !';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Pack';

  @override
  String get businessCategory => 'Affaires';

  @override
  String get buyCoins => 'Acheter des pièces';

  @override
  String get buyCoinsBtnLabel => 'Acheter des Coins';

  @override
  String get buyPackBtn => 'Acheter';

  @override
  String get cancel => 'Annuler';

  @override
  String get cancelLabel => 'Annuler';

  @override
  String get cannotAccessFeature =>
      'Cette fonctionnalité est disponible après la vérification de votre compte.';

  @override
  String get cantUndoMatched =>
      'Impossible d\'annuler — vous êtes déjà connectés !';

  @override
  String get casualDating => 'Sorties décontractées';

  @override
  String get categoryFlashcard => 'Carte Mémoire';

  @override
  String get categoryLearning => 'Apprentissage';

  @override
  String get categoryMultilingual => 'Multilingue';

  @override
  String get categoryName => 'Catégorie';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Saisonnier';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryStreak => 'Série';

  @override
  String get categoryTranslation => 'Traduction';

  @override
  String get challenges => 'Défis';

  @override
  String get changeLocation => 'Changer l\'emplacement';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordConfirm => 'Confirmer le nouveau mot de passe';

  @override
  String get changePasswordCurrent => 'Mot de passe actuel';

  @override
  String get changePasswordDescription =>
      'Pour des raisons de sécurité, veuillez vérifier votre identité avant de changer votre mot de passe.';

  @override
  String get changePasswordEmailConfirm => 'Confirmez votre adresse e-mail';

  @override
  String get changePasswordEmailHint => 'Votre e-mail';

  @override
  String get changePasswordEmailMismatch =>
      'L\'e-mail ne correspond pas à votre compte';

  @override
  String get changePasswordNew => 'Nouveau mot de passe';

  @override
  String get changePasswordReauthRequired =>
      'Veuillez vous déconnecter et vous reconnecter avant de changer votre mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Mettre à jour le mot de passe de votre compte';

  @override
  String get changePasswordSuccess => 'Mot de passe changé avec succès';

  @override
  String get changePasswordWrongCurrent =>
      'Le mot de passe actuel est incorrect';

  @override
  String get chatAddCaption => 'Ajouter une légende...';

  @override
  String get chatAddToStarred => 'Ajouter aux messages favoris';

  @override
  String get chatAlreadyInYourLanguage =>
      'Le message est déjà dans votre langue';

  @override
  String get chatAttachCamera => 'Appareil Photo';

  @override
  String get chatAttachGallery => 'Galerie';

  @override
  String get chatAttachRecord => 'Enregistrer';

  @override
  String get chatAttachVideo => 'Vidéo';

  @override
  String get chatBlock => 'Bloquer';

  @override
  String chatBlockUser(String name) {
    return 'Bloquer $name';
  }

  @override
  String chatBlockUserMessage(String name) {
    return 'Êtes-vous sûr de vouloir bloquer $name ? Ils ne pourront plus vous contacter.';
  }

  @override
  String get chatBlockUserTitle => 'Bloquer l\'Utilisateur';

  @override
  String get chatCannotBlockAdmin =>
      'Vous ne pouvez pas bloquer un administrateur.';

  @override
  String get chatCannotReportAdmin =>
      'Vous ne pouvez pas signaler un administrateur.';

  @override
  String get chatCategory => 'Catégorie';

  @override
  String get chatCategoryAccount => 'Aide Compte';

  @override
  String get chatCategoryBilling => 'Facturation & Paiements';

  @override
  String get chatCategoryFeedback => 'Commentaires';

  @override
  String get chatCategoryGeneral => 'Question Générale';

  @override
  String get chatCategorySafety => 'Préoccupation de Sécurité';

  @override
  String get chatCategoryTechnical => 'Problème Technique';

  @override
  String get chatCopy => 'Copier';

  @override
  String get chatCreate => 'Créer';

  @override
  String get chatCreateSupportTicket => 'Créer un Ticket de Support';

  @override
  String get chatCreateTicket => 'Créer un ticket';

  @override
  String chatDaysAgo(int count) {
    return 'il y a ${count}j';
  }

  @override
  String get chatDelete => 'Supprimer';

  @override
  String get chatDeleteChat => 'Supprimer le Chat';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Cela supprimera tous les messages pour vous et $name. Cette action est irréversible.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Supprimer le Chat pour Tous';

  @override
  String get chatDeleteChatForMeMessage =>
      'Cela supprimera le chat de votre appareil uniquement. L\'autre personne verra toujours les messages.';

  @override
  String chatDeleteConversationWith(String name) {
    return 'Supprimer la conversation avec $name ?';
  }

  @override
  String get chatDeleteForBoth => 'Supprimer le chat pour les deux';

  @override
  String get chatDeleteForBothDescription =>
      'Cela supprimera définitivement la conversation pour vous et l\'autre personne.';

  @override
  String get chatDeleteForEveryone => 'Supprimer pour Tous';

  @override
  String get chatDeleteForMe => 'Supprimer le chat pour moi';

  @override
  String get chatDeleteForMeDescription =>
      'Cela supprimera la conversation uniquement de votre liste de chats. L\'autre personne la verra toujours.';

  @override
  String get chatDeletedForBothMessage =>
      'Cette discussion a été définitivement supprimée';

  @override
  String get chatDeletedForMeMessage =>
      'Cette discussion a été retirée de votre boîte de réception';

  @override
  String get chatDeletedTitle => 'Discussion supprimée !';

  @override
  String get chatDescriptionOptional => 'Description (Optionnel)';

  @override
  String get chatDetailsHint => 'Donnez plus de détails sur votre problème...';

  @override
  String get chatDisableTranslation => 'Désactiver la traduction';

  @override
  String get chatEnableTranslation => 'Activer la traduction';

  @override
  String get chatErrorLoadingTickets => 'Erreur de chargement des tickets';

  @override
  String get chatFailedToCreateTicket => 'Impossible de créer le ticket';

  @override
  String get chatFailedToForwardMessage =>
      'Impossible de transférer le message';

  @override
  String get chatFailedToLoadAlbum => 'Impossible de charger l\'album';

  @override
  String get chatFailedToLoadConversations =>
      'Impossible de charger les conversations';

  @override
  String get chatFailedToLoadImage => 'Échec du chargement de l\'image';

  @override
  String get chatFailedToLoadVideo => 'Impossible de charger la vidéo';

  @override
  String chatFailedToPickImage(String error) {
    return 'Échec de la sélection d\'image : $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Échec de la sélection de vidéo : $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Échec du signalement du message : $error';
  }

  @override
  String get chatFailedToRevokeAccess => 'Impossible de révoquer l\'accès';

  @override
  String get chatFailedToSaveFlashcard => 'Impossible d\'enregistrer la carte';

  @override
  String get chatFailedToShareAlbum => 'Impossible de partager l\'album';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Échec du téléversement d\'image : $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Échec du téléversement de vidéo : $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Conseils culturels et contexte';

  @override
  String get chatFeatureGrammar => 'Retour grammatical en temps réel';

  @override
  String get chatFeatureVocabulary => 'Exercices de vocabulaire';

  @override
  String get chatForward => 'Transférer';

  @override
  String get chatForwardMessage => 'Transférer le Message';

  @override
  String get chatForwardToChat => 'Transférer vers un autre chat';

  @override
  String get chatGrammarSuggestion => 'Suggestion grammaticale';

  @override
  String chatHoursAgo(int count) {
    return 'il y a ${count}h';
  }

  @override
  String get chatIcebreakers => 'Brise-glaces';

  @override
  String chatIsTyping(String userName) {
    return '$userName écrit';
  }

  @override
  String get chatJustNow => 'À l\'instant';

  @override
  String get chatLanguagePickerHint =>
      'Choisissez la langue dans laquelle vous souhaitez lire cette conversation. Tous les messages seront traduits pour vous.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Langue du chat définie sur $language';
  }

  @override
  String get chatLanguages => 'Langues';

  @override
  String get chatLearnThis => 'Apprendre ceci';

  @override
  String get chatListen => 'Écouter';

  @override
  String get chatLoadingVideo => 'Chargement de la vidéo...';

  @override
  String get chatMaybeLater => 'Peut-être plus tard';

  @override
  String get chatMediaLimitReached => 'Limite de médias atteinte';

  @override
  String get chatMessage => 'Message';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Message bloqué : Contient $violations. Pour votre sécurité, le partage de coordonnées personnelles n\'est pas autorisé.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Message transféré à $count conversation(s)';
  }

  @override
  String get chatMessageOptions => 'Options du Message';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageReported =>
      'Message signalé. Nous l\'examinerons sous peu.';

  @override
  String get chatMessageStarred => 'Message mis en favori';

  @override
  String get chatMessageTranslated => 'Traduit';

  @override
  String get chatMessageUnstarred => 'Message retiré des favoris';

  @override
  String chatMinutesAgo(int count) {
    return 'il y a ${count}min';
  }

  @override
  String get chatMySupportTickets => 'Mes Tickets de Support';

  @override
  String get chatNeedHelpCreateTicket =>
      'Besoin d\'aide ? Créez un nouveau ticket.';

  @override
  String get chatNewTicket => 'Nouveau ticket';

  @override
  String get chatNoConversationsToForward =>
      'Aucune conversation pour transférer';

  @override
  String get chatNoMatchingConversations =>
      'Aucune conversation correspondante';

  @override
  String get chatNoMessagesToPractice =>
      'Pas encore de messages pour s\'entraîner';

  @override
  String get chatNoMessagesYet => 'Pas encore de messages';

  @override
  String get chatNoPrivatePhotos => 'Aucune photo privée disponible';

  @override
  String get chatNoSupportTickets => 'Aucun Ticket de Support';

  @override
  String get chatOffline => 'Hors ligne';

  @override
  String get chatOnline => 'En ligne';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'En ligne il y a ${days}j';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'En ligne il y a ${hours}h';
  }

  @override
  String get chatOnlineJustNow => 'En ligne à l\'instant';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'En ligne il y a ${minutes}min';
  }

  @override
  String get chatOptions => 'Options du Chat';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name a révoqué l\'accès à l\'album';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name a partagé son album privé';
  }

  @override
  String get chatPhoto => 'Photo';

  @override
  String get chatPhraseSaved => 'Phrase enregistrée dans votre jeu de cartes !';

  @override
  String get chatPleaseEnterSubject => 'Veuillez saisir un sujet';

  @override
  String get chatPractice => 'Pratiquer';

  @override
  String get chatPracticeMode => 'Mode Pratique';

  @override
  String get chatPracticeTrialStarted =>
      'Essai du mode pratique lancé ! Vous avez 3 sessions gratuites.';

  @override
  String get chatPreviewImage => 'Aperçu Image';

  @override
  String get chatPreviewVideo => 'Aperçu Vidéo';

  @override
  String get chatPronunciationChallenge => 'Défi de prononciation';

  @override
  String get chatPronunciationHint =>
      'Appuyez pour écouter, puis entraînez-vous à dire chaque phrase :';

  @override
  String get chatRemoveFromStarred => 'Retirer des messages favoris';

  @override
  String get chatReply => 'Répondre';

  @override
  String get chatReplyToMessage => 'Répondre à ce message';

  @override
  String chatReplyingTo(String name) {
    return 'Réponse à $name';
  }

  @override
  String get chatReportInappropriate => 'Signaler un contenu inapproprié';

  @override
  String get chatReportMessage => 'Signaler le Message';

  @override
  String get chatReportReasonFakeProfile => 'Faux profil / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Harcèlement ou intimidation';

  @override
  String get chatReportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get chatReportReasonOther => 'Autre';

  @override
  String get chatReportReasonPersonalInfo =>
      'Partage d\'informations personnelles';

  @override
  String get chatReportReasonSpam => 'Spam ou arnaque';

  @override
  String get chatReportReasonThreatening => 'Comportement menaçant';

  @override
  String get chatReportReasonUnderage => 'Utilisateur mineur';

  @override
  String chatReportUser(String name) {
    return 'Signaler $name';
  }

  @override
  String get chatReportUserTitle => 'Signaler l\'Utilisateur';

  @override
  String chatSeeExchangeDetails(String name) {
    return 'Voir les Détails de l\'Échange avec $name';
  }

  @override
  String get chatSafetyGotIt => 'Compris';

  @override
  String get chatSafetySubtitle =>
      'Votre sécurité est notre priorité. Gardez ces conseils à l\'esprit.';

  @override
  String get chatSafetyTip => 'Conseil de Sécurité';

  @override
  String get chatSafetyTip1Description =>
      'Ne partagez pas votre adresse, numéro de téléphone ou informations financières.';

  @override
  String get chatSafetyTip1Title => 'Gardez Vos Infos Personnelles Privées';

  @override
  String get chatSafetyTip2Description =>
      'N\'envoyez jamais d\'argent à quelqu\'un que vous n\'avez pas rencontré en personne.';

  @override
  String get chatSafetyTip2Title => 'Méfiez-vous des Demandes d\'Argent';

  @override
  String get chatSafetyTip3Description =>
      'Pour les premiers rendez-vous, choisissez toujours un lieu public et bien éclairé.';

  @override
  String get chatSafetyTip3Title => 'Rencontrez dans des Lieux Publics';

  @override
  String get chatSafetyTip4Description =>
      'Si quelque chose ne va pas, faites confiance à votre instinct et terminez la conversation.';

  @override
  String get chatSafetyTip4Title => 'Faites Confiance à Votre Instinct';

  @override
  String get chatSafetyTip5Description =>
      'Utilisez la fonction de signalement si quelqu\'un vous met mal à l\'aise.';

  @override
  String get chatSafetyTip5Title => 'Signalez les Comportements Suspects';

  @override
  String get chatSafetyTitle => 'Chattez en Toute Sécurité';

  @override
  String get chatSaving => 'Enregistrement...';

  @override
  String chatSayHiTo(String name) {
    return 'Dites bonjour à $name !';
  }

  @override
  String get chatScrollUpForOlder =>
      'Faites défiler vers le haut pour les anciens messages';

  @override
  String get chatSearchByNameOrNickname => 'Rechercher par nom ou @pseudo';

  @override
  String get chatSearchConversationsHint => 'Rechercher des conversations...';

  @override
  String get chatSelectPhotos => 'Sélectionner des photos à envoyer';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatSendAnyway => 'Envoyer quand même';

  @override
  String get chatSendAttachment => 'Envoyer une Pièce Jointe';

  @override
  String chatSendCount(int count) {
    return 'Envoyer ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Envoyez un message pour démarrer la conversation';

  @override
  String get chatSendMessagesForTips =>
      'Envoyez des messages pour obtenir des conseils linguistiques !';

  @override
  String get chatSetNativeLanguage =>
      'Définissez d\'abord votre langue maternelle dans les paramètres';

  @override
  String get chatSettingCulturalTips => 'Conseils culturels';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Afficher le contexte culturel des expressions';

  @override
  String get chatSettingDifficultyBadges => 'Badges de difficulté';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'Afficher le niveau CECR (A1-C2) sur les messages';

  @override
  String get chatSettingGrammarCheck => 'Vérification grammaticale';

  @override
  String get chatSettingGrammarCheckDesc =>
      'Vérifier la grammaire avant d\'envoyer';

  @override
  String get chatSettingLanguageFlags => 'Drapeaux de langue';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Afficher les drapeaux à côté du texte traduit et original';

  @override
  String get chatSettingPhraseOfDay => 'Phrase du jour';

  @override
  String get chatSettingPhraseOfDayDesc =>
      'Afficher une phrase quotidienne à pratiquer';

  @override
  String get chatSettingPronunciation => 'Prononciation (TTS)';

  @override
  String get chatSettingPronunciationDesc =>
      'Double-appui pour écouter la prononciation';

  @override
  String get chatSettingShowOriginal => 'Afficher le texte original';

  @override
  String get chatSettingShowOriginalDesc =>
      'Afficher le message original sous la traduction';

  @override
  String get chatSettingSmartReplies => 'Réponses intelligentes';

  @override
  String get chatSettingSmartRepliesDesc =>
      'Suggérer des réponses dans la langue cible';

  @override
  String get chatSettingTtsTranslation => 'TTS lit la traduction';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Lire le texte traduit au lieu de l\'original';

  @override
  String get chatSettingWordBreakdown => 'Décomposition des mots';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Appuyez sur les messages pour traduction mot à mot';

  @override
  String get chatSettingXpBar => 'Barre XP et série';

  @override
  String get chatSettingXpBarDesc => 'Afficher les XP de session et le progrès';

  @override
  String get chatSettingsSaveAllChats => 'Enregistrer pour tous les chats';

  @override
  String get chatSettingsSaveThisChat => 'Enregistrer pour ce chat';

  @override
  String get chatSettingsSavedAllChats =>
      'Paramètres enregistrés pour tous les chats';

  @override
  String get chatSettingsSavedThisChat => 'Paramètres enregistrés pour ce chat';

  @override
  String get chatSettingsSubtitle =>
      'Personnalisez votre expérience d\'apprentissage dans ce chat';

  @override
  String get chatSettingsTitle => 'Paramètres du chat';

  @override
  String get chatSomeone => 'Quelqu\'un';

  @override
  String get chatStarMessage => 'Mettre en Favori';

  @override
  String get chatStartSwipingToChat =>
      'Commencez à explorer et à vous connecter pour discuter avec des gens !';

  @override
  String get chatStatusAssigned => 'Assigné';

  @override
  String get chatStatusAwaitingReply => 'En attente de réponse';

  @override
  String get chatStatusClosed => 'Fermé';

  @override
  String get chatStatusInProgress => 'En cours';

  @override
  String get chatStatusOpen => 'Ouvert';

  @override
  String get chatStatusResolved => 'Résolu';

  @override
  String chatStreak(int count) {
    return 'Série : $count';
  }

  @override
  String get chatSubject => 'Sujet';

  @override
  String get chatSubjectHint => 'Brève description de votre problème';

  @override
  String get chatSupportAddAttachment => 'Ajouter une Pièce Jointe';

  @override
  String get chatSupportAddCaptionOptional =>
      'Ajouter une légende (optionnel)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agent : $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agent';

  @override
  String get chatSupportCategory => 'Catégorie';

  @override
  String get chatSupportClose => 'Fermer';

  @override
  String chatSupportDaysAgo(int days) {
    return 'il y a ${days}j';
  }

  @override
  String get chatSupportErrorLoading => 'Erreur de chargement des messages';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Échec de la réouverture du ticket : $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Échec de l\'envoi du message : $error';
  }

  @override
  String get chatSupportGeneral => 'Général';

  @override
  String get chatSupportGeneralSupport => 'Support Général';

  @override
  String chatSupportHoursAgo(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String get chatSupportJustNow => 'À l\'instant';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'il y a ${minutes}min';
  }

  @override
  String get chatSupportReopenTicket =>
      'Besoin d\'aide supplémentaire ? Appuyez pour rouvrir';

  @override
  String get chatSupportStartMessage =>
      'Envoyez un message pour démarrer la conversation.\nNotre équipe répondra dès que possible.';

  @override
  String get chatSupportStatus => 'Statut';

  @override
  String get chatSupportStatusClosed => 'Fermé';

  @override
  String get chatSupportStatusDefault => 'Support';

  @override
  String get chatSupportStatusOpen => 'Ouvert';

  @override
  String get chatSupportStatusPending => 'En attente';

  @override
  String get chatSupportStatusResolved => 'Résolu';

  @override
  String get chatSupportSubject => 'Sujet';

  @override
  String get chatSupportTicketCreated => 'Ticket Créé';

  @override
  String get chatSupportTicketId => 'ID du Ticket';

  @override
  String get chatSupportTicketInfo => 'Informations du Ticket';

  @override
  String get chatSupportTicketReopened =>
      'Ticket rouvert. Vous pouvez maintenant envoyer un message.';

  @override
  String get chatSupportTicketResolved => 'Ce ticket a été résolu';

  @override
  String get chatSupportTicketStart => 'Début du Ticket';

  @override
  String get chatSupportTitle => 'Support GreenGo';

  @override
  String get chatSupportTypeMessage => 'Tapez votre message...';

  @override
  String get chatSupportWaitingAssignment => 'En attente d\'attribution';

  @override
  String get chatSupportWelcome => 'Bienvenue au Support';

  @override
  String get chatTapToView => 'Appuyez pour voir';

  @override
  String get chatTapToViewAlbum => 'Appuyez pour voir l\'album';

  @override
  String get chatTranslate => 'Traduire';

  @override
  String get chatTranslated => 'Traduit';

  @override
  String get chatTranslating => 'Traduction...';

  @override
  String get chatTranslationDisabled => 'Traduction désactivée';

  @override
  String get chatTranslationEnabled => 'Traduction activée';

  @override
  String get chatTranslationFailed =>
      'Échec de la traduction. Veuillez réessayer.';

  @override
  String get translationFailedTapRetry =>
      'Traduction impossible · Touchez pour réessayer';

  @override
  String get chatTrialExpired => 'Votre essai gratuit a expiré.';

  @override
  String get chatTtsComingSoon => 'Synthèse vocale bientôt disponible !';

  @override
  String get chatTyping => 'en train d\'écrire...';

  @override
  String get chatUnableToForward => 'Impossible de transférer le message';

  @override
  String get chatUnknown => 'Inconnu';

  @override
  String get chatUnstarMessage => 'Retirer des Favoris';

  @override
  String get chatUpgrade => 'Mettre à niveau';

  @override
  String get chatUpgradePracticeMode =>
      'Passez à Silver VIP ou supérieur pour continuer à pratiquer les langues dans vos chats.';

  @override
  String get chatUploading => 'Téléversement...';

  @override
  String get chatUseCorrection => 'Utiliser la correction';

  @override
  String chatUserBlocked(String name) {
    return '$name a été bloqué';
  }

  @override
  String get chatUserReported =>
      'Utilisateur signalé. Nous examinerons votre signalement sous peu.';

  @override
  String get chatVideo => 'Vidéo';

  @override
  String get chatVideoPlayer => 'Lecteur Vidéo';

  @override
  String get chatVideoTooLarge =>
      'Vidéo trop volumineuse. La taille maximale est de 50 Mo.';

  @override
  String get chatWhyReportMessage => 'Pourquoi signalez-vous ce message ?';

  @override
  String chatWhyReportUser(String name) {
    return 'Pourquoi signalez-vous $name ?';
  }

  @override
  String chatWithName(String name) {
    return 'Discuter avec $name';
  }

  @override
  String chatWords(int count) {
    return '$count mots';
  }

  @override
  String get chatYou => 'Vous';

  @override
  String get chatYouRevokedAlbum => 'Vous avez révoqué l\'accès à l\'album';

  @override
  String get chatYouSharedAlbum => 'Vous avez partagé votre album privé';

  @override
  String get chatYourLanguage => 'Votre langue';

  @override
  String get checkBackLater =>
      'Revenez plus tard pour de nouvelles personnes, ou ajustez vos préférences';

  @override
  String get chooseCorrectAnswer => 'Choisis la bonne réponse';

  @override
  String get chooseFromGallery => 'Choisir dans la Galerie';

  @override
  String get chooseGame => 'Choisir un Jeu';

  @override
  String get claimReward => 'Récupérer la récompense';

  @override
  String get claimRewardBtn => 'Réclamer';

  @override
  String get clearFilters => 'Effacer les Filtres';

  @override
  String get close => 'Fermer';

  @override
  String get coins => 'Pièces';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins pièces ajoutées à votre compte$bonusText';
  }

  @override
  String get coinsAllTransactions => 'Toutes les transactions';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount pièces';
  }

  @override
  String get coinsApply => 'Appliquer';

  @override
  String coinsBalance(Object balance) {
    return 'Solde : $balance';
  }

  @override
  String coinsBonusCoins(Object amount) {
    return '+$amount coins bonus';
  }

  @override
  String get coinsCancelLabel => 'Annuler';

  @override
  String get coinsConfirmPurchase => 'Confirmer l\'achat';

  @override
  String coinsCost(int amount) {
    return '$amount pièces';
  }

  @override
  String get coinsCreditsOnly => 'Crédits uniquement';

  @override
  String get coinsDebitsOnly => 'Débits uniquement';

  @override
  String get coinsEnterReceiverId => 'Entrez l\'ID du destinataire';

  @override
  String get coinsFilterTransactions => 'Filtrer les transactions';

  @override
  String coinsGiftAccepted(Object amount) {
    return '$amount pièces acceptées !';
  }

  @override
  String get coinsGiftDeclined => 'Cadeau refusé';

  @override
  String get coinsGiftSendFailed => 'Impossible d\'envoyer le cadeau';

  @override
  String coinsGiftSent(Object amount) {
    return 'Cadeau de $amount pièces envoyé !';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Pièces insuffisantes';

  @override
  String get coinsLabel => 'Pièces';

  @override
  String get coinsMessageLabel => 'Message (optionnel)';

  @override
  String get coinsMins => 'min';

  @override
  String get coinsNoTransactionsYet => 'Aucune transaction pour le moment';

  @override
  String get coinsPendingGifts => 'Cadeaux en Attente';

  @override
  String get coinsPopular => 'POPULAIRE';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return 'Acheter $totalCoins coins pour $price ?';
  }

  @override
  String get coinsPurchaseFailed => 'Échec de l\'achat';

  @override
  String get coinsPurchaseLabel => 'Acheter';

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return '$totalCoins pièces achetées avec succès !';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return '$totalMinutes minutes vidéo achetées avec succès !';
  }

  @override
  String get coinsReceiverIdLabel => 'ID du destinataire';

  @override
  String coinsRequired(int amount) {
    return '$amount pièces requises';
  }

  @override
  String get coinsRetry => 'Reessayer';

  @override
  String get coinsSelectAmount => 'Choisir le Montant';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return 'Envoyer $amount Coins';
  }

  @override
  String get coinsSendGift => 'Envoyer un Cadeau';

  @override
  String get coinsSent => 'Pièces envoyées avec succès !';

  @override
  String get coinsShareCoins => 'Partagez des coins avec quelqu\'un de special';

  @override
  String get coinsShopLabel => 'Boutique';

  @override
  String get coinsTabCoins => 'Pièces';

  @override
  String get coinsTabGifts => 'Cadeaux';

  @override
  String get coinsToday => 'Aujourd\'hui';

  @override
  String get coinsTransactionHistory => 'Historique des transactions';

  @override
  String get coinsTransactionsAppearHere =>
      'Vos transactions de coins apparaitront ici';

  @override
  String get coinsUnlockPremium => 'Debloquer les fonctionnalites premium';

  @override
  String get coinsVideoCallMatches => 'Appel vidéo avec vos connexions';

  @override
  String get coinsVideoMinutes => 'Minutes Video';

  @override
  String get coinsYesterday => 'Hier';

  @override
  String get comingSoonLabel => 'Bientôt';

  @override
  String get communitiesAddTag => 'Ajouter un tag';

  @override
  String get communitiesAdjustSearch =>
      'Essayez d\'ajuster votre recherche ou vos filtres.';

  @override
  String get communitiesAllCommunities => 'Toutes les Communautes';

  @override
  String get communitiesAllFilter => 'Toutes';

  @override
  String get communitiesAnyoneCanJoin => 'Tout le monde peut rejoindre';

  @override
  String get communitiesBeFirstToSay =>
      'Soyez le premier a dire quelque chose !';

  @override
  String get communitiesCancelLabel => 'Annuler';

  @override
  String get communitiesCityLabel => 'Ville';

  @override
  String get communitiesCityTipLabel => 'Conseil Ville';

  @override
  String get communitiesCityTipUpper => 'CONSEIL VILLE';

  @override
  String get communitiesCommunityInfo => 'Info Communaute';

  @override
  String get communitiesCommunityName => 'Nom de la Communaute';

  @override
  String get communitiesCoverImageLabel => 'Image de couverture';

  @override
  String get communitiesCoverImageHint =>
      'Ajouter une photo de couverture (facultatif)';

  @override
  String get communitiesCommunityType => 'Type de Communaute';

  @override
  String get communitiesCountryLabel => 'Pays';

  @override
  String get communitiesCreateAction => 'Creer';

  @override
  String get communitiesCreateCommunity => 'Creer une Communaute';

  @override
  String get communitiesCreateCommunityAction => 'Creer une Communaute';

  @override
  String get communitiesCreateLabel => 'Creer';

  @override
  String get communitiesCreateLanguageCircle => 'Creer un Cercle Linguistique';

  @override
  String get communitiesCreated => 'Communauté créée !';

  @override
  String communitiesCreatedBy(String name) {
    return 'Cree par $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Cree';

  @override
  String get communitiesCulturalFactLabel => 'Fait Culturel';

  @override
  String get communitiesCulturalFactUpper => 'FAIT CULTUREL';

  @override
  String get communitiesDescription => 'Description';

  @override
  String get communitiesDescriptionHint => 'De quoi parle cette communaute ?';

  @override
  String get communitiesDescriptionLabel => 'Description';

  @override
  String get communitiesDescriptionMinLength =>
      'La description doit contenir au moins 10 caracteres';

  @override
  String get communitiesDescriptionRequired =>
      'Veuillez entrer une description';

  @override
  String get communitiesDiscoverCommunities => 'Decouvrir des Communautes';

  @override
  String get communitiesEditLabel => 'Modifier';

  @override
  String get communitiesGuide => 'Guide';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Sur invitation uniquement';

  @override
  String get communitiesJoinCommunity => 'Rejoindre la Communaute';

  @override
  String get communitiesJoinPrompt =>
      'Rejoignez des communautes pour vous connecter avec des personnes partageant vos interets et langues.';

  @override
  String get communitiesJoined => 'Communauté rejointe !';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'Les cercles linguistiques apparaitront ici quand ils seront disponibles. Creez-en un pour commencer !';

  @override
  String get communitiesLanguageTipLabel => 'Conseil Langue';

  @override
  String get communitiesLanguageTipUpper => 'CONSEIL LANGUE';

  @override
  String get communitiesLanguages => 'Langues';

  @override
  String get communitiesLanguagesLabel => 'Langues';

  @override
  String get communitiesLeaveCommunity => 'Quitter la Communaute';

  @override
  String get communitiesDeleteCommunity => 'Supprimer la communaute';

  @override
  String communitiesDeleteConfirm(String name) {
    return 'Supprimer definitivement \"$name\" ? Tous les messages, membres et contenus sont supprimes. Action irreversible.';
  }

  @override
  String get communitiesDeletedSuccess => 'Communaute supprimee';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Etes-vous sur de vouloir quitter \"$name\" ?';
  }

  @override
  String get communitiesLeaveLabel => 'Quitter';

  @override
  String get communitiesLeaveTitle => 'Quitter la Communaute';

  @override
  String get communitiesLocation => 'Localisation';

  @override
  String get communitiesLocationLabel => 'Localisation';

  @override
  String communitiesMembersCount(Object count) {
    return '$count membres';
  }

  @override
  String get communitiesMembersStatLabel => 'Membres';

  @override
  String get communitiesMembersTitle => 'Membres';

  @override
  String get communitiesNameHint => 'ex., Apprenants d\'Espagnol Paris';

  @override
  String get communitiesNameMinLength =>
      'Le nom doit contenir au moins 3 caracteres';

  @override
  String get communitiesNameRequired => 'Veuillez entrer un nom';

  @override
  String get communitiesNoCommunities => 'Pas Encore de Communautes';

  @override
  String get communitiesNoCommunitiesFound => 'Aucune Communaute Trouvee';

  @override
  String get communitiesNoLanguageCircles => 'Pas de Cercles Linguistiques';

  @override
  String get communitiesNoMessagesYet => 'Pas encore de messages';

  @override
  String get communitiesPreview => 'Apercu';

  @override
  String get communitiesPreviewSubtitle =>
      'Voici comment votre communaute apparaitra aux autres.';

  @override
  String get communitiesPrivate => 'Privee';

  @override
  String get communitiesPublic => 'Publique';

  @override
  String get communitiesRecommendedForYou => 'Recommande pour Vous';

  @override
  String get communitiesSearchHint => 'Rechercher des communautés...';

  @override
  String get communitiesSaveFavorite => 'Ajouter aux favoris';

  @override
  String get communitiesRemoveFavorite => 'Retirer des favoris';

  @override
  String get communitiesFavoritesSection => 'Favoris';

  @override
  String get communitiesShareCityTip => 'Partagez un conseil sur la ville...';

  @override
  String get communitiesShareCulturalFact => 'Partagez un fait culturel...';

  @override
  String get communitiesShareLanguageTip =>
      'Partagez un conseil linguistique...';

  @override
  String get communitiesStats => 'Statistiques';

  @override
  String get communitiesTabDiscover => 'Découvrir';

  @override
  String get communitiesTabLanguageCircles => 'Cercles linguistiques';

  @override
  String get communitiesTabMyGroups => 'Mes groupes';

  @override
  String get communitiesTabJoined => 'Communautés rejointes';

  @override
  String get communitiesTabManaged => 'Mes communautés';

  @override
  String get communitiesNoManaged => 'Vous ne gérez encore aucune communauté';

  @override
  String get communitiesNoManagedSubtitle =>
      'Créez une communauté pour rassembler les gens';

  @override
  String get communitiesTags => 'Tags';

  @override
  String get communitiesTagsLabel => 'Tags';

  @override
  String get communitiesTextLabel => 'Texte';

  @override
  String get communitiesTitle => 'Communautes';

  @override
  String get communitiesTypeAMessage => 'Tapez un message...';

  @override
  String get communitiesUnableToLoad => 'Impossible de charger la communaute';

  @override
  String get compatibilityLabel => 'Compatibilite';

  @override
  String compatiblePercent(String percent) {
    return '$percent% compatible';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      'Complétez des succès pour gagner des badges !';

  @override
  String get completeProfile => 'Complétez Votre Profil';

  @override
  String get complimentsCategory => 'Compliments';

  @override
  String get confirm => 'Confirmer';

  @override
  String get confirmLabel => 'Confirmer';

  @override
  String get confirmLocation => 'Confirmer l\'emplacement';

  @override
  String get confirmPassword => 'Confirmer le Mot de passe';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get connectSocialAccounts => 'Connectez vos comptes sociaux';

  @override
  String get connectionError => 'Erreur de connexion';

  @override
  String get connectionErrorMessage =>
      'Vérifiez votre connexion internet et réessayez.';

  @override
  String get connectionErrorTitle => 'Pas de Connexion Internet';

  @override
  String get consentRequired => 'Consentements Obligatoires';

  @override
  String get consentRequiredError =>
      'Vous devez accepter la Politique de Confidentialité et les Conditions Générales pour vous inscrire';

  @override
  String get contactSupport => 'Contacter le Support';

  @override
  String get continueLearningBtn => 'Continuer';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithFacebook => 'Continuer avec Facebook';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get conversationCategory => 'Conversation';

  @override
  String get correctAnswer => 'Correct !';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get culturalCategory => 'Culturel';

  @override
  String get culturalExchangeBeFirstTip =>
      'Soyez le premier à partager un conseil culturel !';

  @override
  String get culturalExchangeCategory => 'Catégorie';

  @override
  String get culturalExchangeCommunityTips => 'Conseils de la communauté';

  @override
  String get culturalExchangeCountry => 'Pays';

  @override
  String get culturalExchangeCountryHint => 'ex. Japon, Brésil, France';

  @override
  String get culturalExchangeCountrySpotlight => 'Pays à la une';

  @override
  String get culturalExchangeDailyInsight => 'Aperçu culturel du jour';

  @override
  String get culturalExchangeDatingEtiquette => 'Savoir-vivre';

  @override
  String get culturalExchangeDatingEtiquetteGuide => 'Guide du savoir-vivre';

  @override
  String get culturalExchangeLoadingCountries => 'Chargement des pays...';

  @override
  String get culturalExchangeNoTips => 'Pas encore de conseils';

  @override
  String get culturalExchangeShareCulturalTip => 'Partager un conseil culturel';

  @override
  String get culturalExchangeShareTip => 'Partager un conseil';

  @override
  String get culturalExchangeSubmitTip => 'Soumettre le conseil';

  @override
  String get culturalExchangeTipTitle => 'Titre';

  @override
  String get culturalExchangeTipTitleHint =>
      'Donnez un titre accrocheur à votre conseil';

  @override
  String get culturalExchangeTitle => 'Échange culturel';

  @override
  String get culturalExchangeViewAll => 'Voir tout';

  @override
  String get culturalExchangeYourTip => 'Votre conseil';

  @override
  String get culturalExchangeYourTipHint =>
      'Partagez vos connaissances culturelles...';

  @override
  String get dailyChallengesSubtitle =>
      'Completez des defis pour des recompenses';

  @override
  String get dailyChallengesTitle => 'Défis Quotidiens';

  @override
  String dailyLimitReached(int limit) {
    return 'Limite quotidienne de $limit atteinte';
  }

  @override
  String get dailyMessages => 'Messages quotidiens';

  @override
  String get dailyRewardHeader => 'Récompense quotidienne';

  @override
  String get dailySwipeLimitReached =>
      'Limite quotidienne de swipes atteinte. Passez à la version supérieure pour plus de swipes !';

  @override
  String get dailySwipes => 'Swipes quotidiens';

  @override
  String get dataExportSentToEmail => 'Export de données envoyé à votre email';

  @override
  String get dateOfBirth => 'Date de Naissance';

  @override
  String dayNumber(int day) {
    return 'Jour $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count jours de suite';
  }

  @override
  String dayStreakLabel(int days) {
    return 'Série de $days jours !';
  }

  @override
  String get days => 'Jours';

  @override
  String daysAgo(int count) {
    return 'il y a $count jours';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAccount => 'Supprimer le Compte';

  @override
  String get deleteAccountConfirmation =>
      'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront définitivement supprimées.';

  @override
  String get details => 'Détails';

  @override
  String get difficultyLabel => 'Difficulté';

  @override
  String directMessageCost(int cost) {
    return 'Les messages directs coutent $cost coins. Voulez-vous acheter plus de coins ?';
  }

  @override
  String get discover => 'Reseau';

  @override
  String discoveryError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get discoveryFilterAll => 'Tous';

  @override
  String get discoveryFilterGuides => 'Guides';

  @override
  String get discoveryFilterLiked => 'Connectés';

  @override
  String get discoveryFilterMatches => 'Connexions';

  @override
  String get discoveryFilterPassed => 'Refusés';

  @override
  String get discoveryFilterSkipped => 'Explorés';

  @override
  String get discoveryFilterSuperLiked => 'Prioritaire';

  @override
  String get discoveryFilterNetwork => 'Mon Réseau';

  @override
  String get discoveryFilterTravelers => 'Voyageurs';

  @override
  String get discoveryLimitReached =>
      'Vous avez atteint votre limite de découverte';

  @override
  String discoverySeeMoreCoins(int coins) {
    return 'Dépensez $coins pièces pour en voir plus';
  }

  @override
  String get discoveryPreferencesTitle => 'Preferences de Decouverte';

  @override
  String get discoveryPreferencesTooltip => 'Préférences de découverte';

  @override
  String get discoverySwitchToGrid => 'Passer en mode grille';

  @override
  String get discoverySwitchToSwipe => 'Passer en mode swipe';

  @override
  String get dismiss => 'Fermer';

  @override
  String get distance => 'Distance';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Document non disponible';

  @override
  String get documentNotAvailableDescription =>
      'Ce document n\'est pas encore disponible dans votre langue.';

  @override
  String get done => 'Terminé';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte?';

  @override
  String get download => 'Télécharger';

  @override
  String downloadProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String downloadingLanguage(String language) {
    return 'Téléchargement de $language...';
  }

  @override
  String get downloadingTranslationData =>
      'Téléchargement des données de traduction';

  @override
  String get edit => 'Modifier';

  @override
  String get editInterests => 'Modifier les Intérêts';

  @override
  String get editNickname => 'Modifier le Pseudo';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get editVoiceComingSoon => 'Modifier la voix bientôt disponible';

  @override
  String get education => 'Éducation';

  @override
  String get email => 'E-mail';

  @override
  String get emailInvalid => 'Veuillez entrer un e-mail valide';

  @override
  String get emailRequired => 'L\'e-mail est requis';

  @override
  String get emergencyCategory => 'Urgence';

  @override
  String get emptyStateErrorMessage =>
      'Nous n\'avons pas pu charger ce contenu. Veuillez réessayer.';

  @override
  String get emptyStateErrorTitle => 'Un problème est survenu';

  @override
  String get emptyStateNoInternetMessage =>
      'Veuillez vérifier votre connexion internet et réessayer.';

  @override
  String get emptyStateNoInternetTitle => 'Pas de connexion';

  @override
  String get emptyStateNoLikesMessage =>
      'Complétez votre profil pour recevoir plus de likes !';

  @override
  String get emptyStateNoLikesTitle => 'Pas encore de likes';

  @override
  String get emptyStateNoMatchesMessage =>
      'Commencez à explorer pour créer votre première connexion !';

  @override
  String get emptyStateNoMatchesTitle => 'Pas encore de connexions';

  @override
  String get emptyStateNoMessagesMessage =>
      'Quand vous vous connectez avec quelqu\'un, vous pouvez discuter ici.';

  @override
  String get emptyStateNoMessagesTitle => 'Pas de messages';

  @override
  String get emptyStateNoNotificationsMessage =>
      'Vous n\'avez aucune nouvelle notification.';

  @override
  String get emptyStateNoNotificationsTitle => 'Tout est à jour !';

  @override
  String get emptyStateNoResultsMessage =>
      'Essayez d\'ajuster votre recherche ou vos filtres.';

  @override
  String get emptyStateNoResultsTitle => 'Aucun résultat trouvé';

  @override
  String get enableAutoTranslation => 'Activer la traduction automatique';

  @override
  String get enableNotifications => 'Activer les Notifications';

  @override
  String get enterAmount => 'Entrer le montant';

  @override
  String get enterNickname => 'Entrez le pseudo';

  @override
  String get enterNicknameHint => 'Entrez un pseudo';

  @override
  String get enterNicknameToFind =>
      'Entrez un pseudo pour trouver quelqu\'un directement';

  @override
  String get enterRejectionReason => 'Entrez la raison du refus';

  @override
  String error(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get errorLoadingDocument => 'Erreur lors du chargement du document';

  @override
  String get errorSearchingTryAgain => 'Erreur de recherche. Réessayez.';

  @override
  String get eventsAboutThisEvent => 'A propos de cet evenement';

  @override
  String get eventsApplyFilters => 'Appliquer les filtres';

  @override
  String get eventsAttendees => 'Participants';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max participants';
  }

  @override
  String get eventsBeFirstToSay => 'Soyez le premier a dire quelque chose !';

  @override
  String get eventsCategory => 'Categorie';

  @override
  String get eventsChatWithAttendees => 'Discutez avec les autres participants';

  @override
  String get eventsCheckBackLater =>
      'Revenez plus tard ou creez votre propre evenement !';

  @override
  String get eventsCreateEvent => 'Créer un événement';

  @override
  String get eventsCreatedSuccessfully => 'Événement créé avec succès !';

  @override
  String get eventsDateRange => 'Plage de Dates';

  @override
  String get eventsDeleted => 'Événement supprimé';

  @override
  String get eventsDescription => 'Description';

  @override
  String get eventsDistance => 'Distance';

  @override
  String get eventsEndDateTime => 'Date et Heure de Fin';

  @override
  String get eventsErrorLoadingMessages =>
      'Erreur lors du chargement des messages';

  @override
  String get eventsEventFull => 'Evenement Complet';

  @override
  String get eventsEventTitle => 'Titre de l\'Evenement';

  @override
  String get eventsFilterEvents => 'Filtrer les Evenements';

  @override
  String get eventsFreeEvent => 'Evenement Gratuit';

  @override
  String get eventsFreeLabel => 'GRATUIT';

  @override
  String get eventsFullLabel => 'Complet';

  @override
  String eventsGoing(Object count) {
    return '$count participants';
  }

  @override
  String get eventsGoingLabel => 'J\'y vais';

  @override
  String get eventsGroupChatTooltip => 'Discussion de groupe de l\'événement';

  @override
  String get eventsJoinEvent => 'Rejoindre l\'Evenement';

  @override
  String get eventsJoinLabel => 'Rejoindre';

  @override
  String eventsKmAwayFormat(String km) {
    return 'a $km km';
  }

  @override
  String get eventsLanguageExchange => 'Echange Linguistique';

  @override
  String get eventsLanguagePairs =>
      'Paires de Langues (ex., Espagnol ↔ Anglais)';

  @override
  String eventsLanguages(String languages) {
    return 'Langues : $languages';
  }

  @override
  String get eventsLocation => 'Lieu';

  @override
  String eventsMAwayFormat(Object meters) {
    return 'a $meters m';
  }

  @override
  String get eventsMaxAttendees => 'Participants Max.';

  @override
  String get eventsCapacityAllowed => 'Capacité autorisée';

  @override
  String get eventsNoAttendeesYet =>
      'Pas encore de participants. Soyez le premier !';

  @override
  String get eventsNoEventsFound => 'Aucun evenement trouve';

  @override
  String get eventsNoMessagesYet => 'Pas encore de messages';

  @override
  String get eventsRequired => 'Requis';

  @override
  String get eventsRsvpCancelled => 'Participation annulee';

  @override
  String get eventsRsvpUpdated => 'Participation mise a jour !';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count places restantes';
  }

  @override
  String get eventsStartDateTime => 'Date et Heure de Debut';

  @override
  String get eventsTabMyEvents => 'Mes événements';

  @override
  String get eventsFilterOngoing => 'En cours';

  @override
  String get eventsFilterUpcoming => 'À venir';

  @override
  String get eventsFilterPast => 'Passés';

  @override
  String get eventsTabExperiences => 'Expériences';

  @override
  String get eventsTabAttractions => 'Attractions';

  @override
  String get eventsTabCommunity => 'Communauté';

  @override
  String get eventsDeleteEvent => 'Supprimer l\'événement';

  @override
  String get eventsDeleteConfirmBody =>
      'Voulez-vous vraiment supprimer cet événement ? Cette action est irréversible.';

  @override
  String get eventsBook => 'Réserver';

  @override
  String get eventsFromPrice => 'à partir de';

  @override
  String get eventsTabNearby => 'À proximité';

  @override
  String get eventsTabUpcoming => 'À venir';

  @override
  String get eventsThisMonth => 'Ce mois-ci';

  @override
  String get eventsDateUntil => 'Jusqu\'au';

  @override
  String get eventsDateFrom => 'À partir du';

  @override
  String get eventsCustomRange => 'Plage personnalisée';

  @override
  String get eventsDateAnyTime => 'À tout moment';

  @override
  String get eventsThisWeekFilter => 'Cette semaine';

  @override
  String get eventsTitle => 'Evenements';

  @override
  String get eventsAndPlacesTitle => 'Événements et lieux';

  @override
  String get eventsCategoryAll => 'Tous';

  @override
  String attractionVisitWebsite(String host) {
    return 'Ouvrir $host';
  }

  @override
  String get attractionVisitWikidata => 'Ouvrir wikidata.org';

  @override
  String get attractionOpenInMaps => 'Ouvrir dans Maps';

  @override
  String get attractionOpenLink => 'Ouvrir le lien';

  @override
  String get attractionOpenWebsite => 'Ouvrir le site officiel';

  @override
  String get attractionShareChat => 'Partager dans un chat';

  @override
  String get attractionShareGroup => 'Partager dans un groupe';

  @override
  String get attractionDescribedAt => 'En savoir plus';

  @override
  String get attractionReport => 'Signaler l\'événement';

  @override
  String get attractionReportConfirm =>
      'Signaler cet élément comme inapproprié ou incorrect ?';

  @override
  String get eventsToday => 'Aujourd\'hui';

  @override
  String get eventsTypeAMessage => 'Tapez un message...';

  @override
  String get exit => 'Quitter';

  @override
  String get exitApp => 'Quitter l\'App ?';

  @override
  String get exitAppConfirmation =>
      'Êtes-vous sûr de vouloir quitter GreenGo ?';

  @override
  String get exploreLanguages => 'Explorer les Langues';

  @override
  String get exploreTitle => 'Explorer';

  @override
  String get communityTabTitle => 'Communauté';

  @override
  String exploreHeadline(String city) {
    return 'Explorer $city';
  }

  @override
  String get exploreSubtitle =>
      'Expériences culturelles et partenaires linguistiques près de chez vous';

  @override
  String get explorePracticeLanguage => 'Pratiquer une langue';

  @override
  String get exploreNetworkDiscovery => 'Découverte du réseau';

  @override
  String exploreNetworkDiscoverySubtitle(String country) {
    return 'Des personnes à rencontrer en $country';
  }

  @override
  String get exploreSeeAll => 'Tout voir';

  @override
  String get explorePromotedBadge => 'Sponsorise';

  @override
  String get exploreHappeningThisWeek => 'Cette semaine';

  @override
  String get exploreHappeningToday => 'Aujourd\'hui';

  @override
  String get exploreJoin => 'Rejoindre';

  @override
  String get exploreFeatured => 'Expérience à la une';

  @override
  String exploreSpeaksLearning(String speaks, String learning) {
    return 'parle $speaks · apprend $learning';
  }

  @override
  String exploreSpeaks(String language) {
    return 'parle $language';
  }

  @override
  String get exploreAroundYou => 'Découvrir de nouvelles personnes';

  @override
  String get exploreSameInterests =>
      'Des personnes avec les mêmes centres d\'intérêt que toi';

  @override
  String get exploreBusinessAccounts => 'Comptes professionnels';

  @override
  String exploreSpeaksLanguage(String language) {
    return 'Des personnes qui parlent $language';
  }

  @override
  String get exploreCommunityEventsNearby =>
      'Événements communautaires près de toi';

  @override
  String get exploreNoPartners =>
      'Aucun partenaire linguistique à proximité pour l\'instant — revenez bientôt.';

  @override
  String get exploreNoEvents =>
      'Aucune expérience à afficher pour l\'instant — revenez bientôt.';

  @override
  String get exploreNoCommunities =>
      'Aucune communauté à rejoindre pour l\'instant — reviens bientôt.';

  @override
  String exploreGoingCount(int count) {
    return '$count participants';
  }

  @override
  String get exploreFeaturedEvents => 'Événements à la une';

  @override
  String get exploreFeaturedAttractions => 'Attractions à la une';

  @override
  String get exploreTopExperiences => 'Meilleures expériences';

  @override
  String get exploreMyNextEvents => 'Mes prochains événements';

  @override
  String get exploreCommunitiesTitle => 'Communautés à rejoindre';

  @override
  String exploreMembersCount(int count) {
    return '$count membres';
  }

  @override
  String get exploreCountrySpotlight => 'Pays à l\'honneur';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get greetingNight => 'Bonne nuit';

  @override
  String get statCoins => 'Pièces';

  @override
  String get statTier => 'Niveau';

  @override
  String get statCountries => 'Pays';

  @override
  String get statPeople => 'Personnes';

  @override
  String get networkWorldMap => 'Réseau mondial';

  @override
  String get discoveryShowPeople => 'Afficher les personnes';

  @override
  String get discoveryShowBusinesses => 'Afficher les entreprises';

  @override
  String networkDiscoveryDistanceKm(String distance) {
    return 'à $distance km';
  }

  @override
  String get connectAction => 'Se connecter';

  @override
  String get connectError =>
      'Impossible de démarrer la discussion. Veuillez réessayer.';

  @override
  String get sayHiAction => 'Dire bonjour';

  @override
  String get newConnectionLabel => 'Nouvelle connexion';

  @override
  String get connectionsTitle => 'Connexions';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km';
  }

  @override
  String get exploreMapError =>
      'Impossible de charger les utilisateurs à proximité';

  @override
  String get exploreMapExpandRadius => 'Élargir le rayon';

  @override
  String get exploreMapExpandRadiusHint =>
      'Essayez d\'augmenter votre rayon de recherche pour trouver plus de personnes.';

  @override
  String get exploreMapNearbyUser => 'Utilisateur à proximité';

  @override
  String get exploreMapNoOneNearby => 'Personne à proximité';

  @override
  String get exploreMapOnlineNow => 'En ligne maintenant';

  @override
  String get exploreMapPeopleNearYou => 'Personnes près de vous';

  @override
  String get exploreMapRadius => 'Rayon :';

  @override
  String get exploreMapVisible => 'Visible';

  @override
  String get exportMyDataGDPR => 'Exporter Mes Données (RGPD)';

  @override
  String get exportingYourData => 'Exportation de vos données...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Prolonger ($cost pièces)';
  }

  @override
  String get extendTooltip => 'Prolonger';

  @override
  String failedToDownloadModel(String language) {
    return 'Échec du téléchargement du modèle $language';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Impossible d\'enregistrer les préférences : $error';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Fonctionnalité non disponible pour $tier';
  }

  @override
  String get fillCategories => 'Remplis toutes les catégories';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterFromMatch => 'Connexion';

  @override
  String get filterFromSearch => 'Direct';

  @override
  String get filterMessaged => 'Avec Messages';

  @override
  String get filterNew => 'Nouveaux';

  @override
  String get filterNewMessages => 'Nouveaux';

  @override
  String get filterNotReplied => 'Non lu';

  @override
  String filteredFromTotal(int total) {
    return 'Filtre de $total';
  }

  @override
  String get filters => 'Filtres';

  @override
  String get finish => 'Terminer';

  @override
  String get firstName => 'Prénom';

  @override
  String get firstTo30Wins => 'Le premier à 30 gagne !';

  @override
  String get flashcardReviewLabel => 'Cartes Mémoire';

  @override
  String get foodDiningCategory => 'Gastronomie';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String freeActionsRemaining(int count) {
    return '$count actions gratuites restantes aujourd\'hui';
  }

  @override
  String get friendship => 'Amitié';

  @override
  String get gameAbandon => 'Abandonner';

  @override
  String get gameAbandonLoseMessage =>
      'Vous perdrez cette partie si vous quittez maintenant.';

  @override
  String get gameAbandonProgressMessage =>
      'Vous perdrez votre progression et retournerez au salon.';

  @override
  String get gameAbandonTitle => 'Abandonner la partie ?';

  @override
  String get gameAbandonTooltip => 'Abandonner la partie';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Entrez un mot commençant par « $letter »...';
  }

  @override
  String get gameCategoriesFilled => 'rempli';

  @override
  String get gameCategoriesNewLetter => 'Nouvelle lettre !';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — commence par « $letter »';
  }

  @override
  String get gameCategoriesTapToFill =>
      'Touchez une catégorie pour la remplir !';

  @override
  String get gameCategoriesTimesUp =>
      'Temps écoulé ! En attente de la manche suivante...';

  @override
  String get gameCategoriesTitle => 'Catégories';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      'Mot déjà utilisé dans une autre catégorie !';

  @override
  String get gameCategoryAnimals => 'Animaux';

  @override
  String get gameCategoryClothing => 'Vêtements';

  @override
  String get gameCategoryColors => 'Couleurs';

  @override
  String get gameCategoryCountries => 'Pays';

  @override
  String get gameCategoryFood => 'Nourriture';

  @override
  String get gameCategoryNature => 'Nature';

  @override
  String get gameCategoryProfessions => 'Métiers';

  @override
  String get gameCategorySports => 'Sports';

  @override
  String get gameCategoryTransport => 'Transport';

  @override
  String get gameChainBreak => 'CHAÎNE ROMPUE !';

  @override
  String get gameChainNextMustStartWith =>
      'Le prochain mot doit commencer par : ';

  @override
  String get gameChainNoWordsYet => 'Pas encore de mots !';

  @override
  String get gameChainStartWithAnyWord =>
      'Commencez la chaîne avec n\'importe quel mot';

  @override
  String get gameChainTitle => 'Chaîne de vocabulaire';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Tapez un mot commençant par « $letter »...';
  }

  @override
  String get gameChainTypeToStartHint =>
      'Tapez un mot pour commencer la chaîne...';

  @override
  String gameChainWordsChained(int count) {
    return '$count mots enchaînés';
  }

  @override
  String get gameCorrect => 'Correct !';

  @override
  String get gameDefaultPlayerName => 'Joueur';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff en avance';
  }

  @override
  String get gameGrammarDuelAnswered => 'Répondu';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff en retard';
  }

  @override
  String get gameGrammarDuelFast => 'RAPIDE !';

  @override
  String get gameGrammarDuelGrammarQuestion => 'QUESTION DE GRAMMAIRE';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '+$points points !';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return 'x$count série !';
  }

  @override
  String get gameGrammarDuelThinking => 'Réflexion...';

  @override
  String get gameGrammarDuelTitle => 'Duel de grammaire';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => 'Mauvaise réponse !';

  @override
  String get gameInvalidAnswer => 'Invalide !';

  @override
  String get gameLanguageBrazilianPortuguese => 'Portugais brésilien';

  @override
  String get gameLanguageEnglish => 'Anglais';

  @override
  String get gameLanguageFrench => 'Français';

  @override
  String get gameLanguageGerman => 'Allemand';

  @override
  String get gameLanguageItalian => 'Italien';

  @override
  String get gameLanguageJapanese => 'Japonais';

  @override
  String get gameLanguagePortuguese => 'Portugais';

  @override
  String get gameLanguageSpanish => 'Espagnol';

  @override
  String get gameLeave => 'Quitter';

  @override
  String get gameOpponent => 'Adversaire';

  @override
  String get gameOver => 'Partie Terminée';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Tentative $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      'Vous ne pouvez pas utiliser le mot lui-même dans votre indice !';

  @override
  String get gamePictureGuessClues => 'INDICES';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count indice(s) envoyé(s)';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return 'Correct ! +$points points';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      'Correct ! En attente de la fin de la manche...';

  @override
  String get gamePictureGuessDescriber => 'DESCRIPTEUR';

  @override
  String get gamePictureGuessDescriberRules =>
      'Donnez des indices pour aider les autres à deviner. Pas de traductions directes ni d\'indices d\'orthographe !';

  @override
  String get gamePictureGuessGuessTheWord => 'Devinez le mot !';

  @override
  String get gamePictureGuessGuessTheWordUpper => 'DEVINEZ LE MOT !';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'Plus de tentatives — en attente de la fin de la manche';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'Plus de tentatives pour cette manche';

  @override
  String get gamePictureGuessTheWordWas => 'Le mot était :';

  @override
  String get gamePictureGuessTitle => 'Devinez l\'image';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Tapez un indice (pas de traductions directes !)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Tapez votre réponse... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'En attente des indices...';

  @override
  String get gamePictureGuessWaitingForOthers => 'En attente des autres...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Mauvaise réponse : « $guess »';
  }

  @override
  String get gamePictureGuessYouAreDescriber => 'Vous êtes le DESCRIPTEUR !';

  @override
  String get gamePictureGuessYourWord => 'VOTRE MOT';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      'Réponse soumise ! En attente des autres...';

  @override
  String get gamePlayCategoriesHeader => 'CATÉGORIES';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Catégorie : $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return 'Correct ! +$points pts';
  }

  @override
  String get gamePlayDescribeThisWord => 'DÉCRIVEZ CE MOT !';

  @override
  String get gamePlayDescribeWordHint =>
      'Décrivez le mot (ne le dites pas !)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name décrit un mot...';
  }

  @override
  String get gamePlayDoNotSayWord => 'Ne dites pas le mot lui-même !';

  @override
  String get gamePlayGuessTheWord => 'DEVINEZ LE MOT';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Incorrect. La réponse était « $answer »';
  }

  @override
  String get gamePlayLeaderboard => 'CLASSEMENT';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Nommez un mot en $language commençant par « $letter »';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Nommez un mot dans « $category » commençant par « $letter »';
  }

  @override
  String get gamePlayNextWordMustStartWith =>
      'LE PROCHAIN MOT DOIT COMMENCER PAR';

  @override
  String get gamePlayNoWordsStartChain =>
      'Pas encore de mots — commencez la chaîne !';

  @override
  String get gamePlayPickLetterNameWord =>
      'Choisissez une lettre, puis nommez un mot !';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name choisit...';
  }

  @override
  String gamePlayPlayerIsThinking(String name) {
    return '$name réfléchit...';
  }

  @override
  String gamePlayThemeLabel(String theme) {
    return 'Thème : $theme';
  }

  @override
  String get gamePlayTranslateThisWord => 'TRADUISEZ CE MOT';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Tapez un mot contenant « $prompt »...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Tapez un mot commençant par « $prompt »...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Tapez la traduction...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      'Tapez un mot contenant ces lettres !';

  @override
  String get gamePlayTypeYourAnswerHint => 'Tapez votre réponse...';

  @override
  String get gamePlayTypeYourGuessBelow => 'Tapez votre réponse ci-dessous !';

  @override
  String get gamePlayTypeYourGuessHint => 'Tapez votre réponse...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Utilisez le chat pour décrire le mot aux autres joueurs';

  @override
  String get gamePlayWaitingForOpponent => 'En attente de l\'adversaire...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Mot commençant par « $letter »...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Mot commençant par « $prompt »...';
  }

  @override
  String get gamePlayYourTurnFlipCards =>
      'Votre tour — retournez deux cartes !';

  @override
  String gamePlayersTurn(String name) {
    return 'Tour de $name';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points pts';
  }

  @override
  String get gamePositionFirst => '1er';

  @override
  String gamePositionNth(int pos) {
    return '${pos}e';
  }

  @override
  String get gamePositionSecond => '2e';

  @override
  String get gamePositionThird => '3e';

  @override
  String get gameResultsBackToLobby => 'Retour au salon';

  @override
  String get gameResultsBaseXp => 'XP de base';

  @override
  String get gameResultsCoinsEarned => 'Pièces gagnées';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Bonus de difficulté (Niv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'CLASSEMENT FINAL';

  @override
  String get gameResultsGameOver => 'FIN DE PARTIE';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'Pas assez de pièces ($amount requises)';
  }

  @override
  String get gameResultsPlayAgain => 'Rejouer';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'RÉCOMPENSES OBTENUES';

  @override
  String get gameResultsTotalXp => 'XP total';

  @override
  String get gameResultsVictory => 'VICTOIRE !';

  @override
  String get gameResultsWhatYouLearned => 'CE QUE VOUS AVEZ APPRIS';

  @override
  String get gameResultsWinner => 'Gagnant';

  @override
  String get gameResultsWinnerBonus => 'Bonus du gagnant';

  @override
  String get gameResultsYouWon => 'Vous avez gagné !';

  @override
  String gameRoundCounter(int current, int total) {
    return 'Manche $current/$total';
  }

  @override
  String gameRoundNumber(int number) {
    return 'Manche $number';
  }

  @override
  String gameScorePts(int score) {
    return '$score pts';
  }

  @override
  String get gameSnapsNoMatch => 'Pas de paire';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total paires trouvées';
  }

  @override
  String get gameSnapsTitle => 'Snaps de langues';

  @override
  String get gameSnapsYourTurnFlipCards => 'VOTRE TOUR — Retournez 2 cartes !';

  @override
  String get gameSomeone => 'Quelqu\'un';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Nommez un mot commençant par « $letter »';
  }

  @override
  String get gameTapplesPickLetterFromWheel =>
      'Choisissez une lettre sur la roue !';

  @override
  String get gameTapplesPickLetterNameWord =>
      'Choisissez une lettre, nommez un mot';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name a perdu une vie';
  }

  @override
  String get gameTapplesTimeUp => 'TEMPS ÉCOULÉ !';

  @override
  String get gameTapplesTitle => 'Tapples de langues';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Mot commençant par « $letter »...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount mots utilisés  •  $lettersCount lettres restantes';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Correct';

  @override
  String get gameTranslationRaceFirstTo30 => 'Premier à 30 gagne !';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'M$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Course de traduction';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Traduire en $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'En attente des autres... $answered/$total ont répondu';
  }

  @override
  String get gameWaitForYourTurn => 'Attendez votre tour...';

  @override
  String get gameWaiting => 'En attente';

  @override
  String get gameWaitingCancelReady => 'Annuler prêt';

  @override
  String get gameWaitingCountdownGo => 'GO !';

  @override
  String get gameWaitingDisconnected => 'Déconnecté';

  @override
  String get gameWaitingEllipsis => 'En attente...';

  @override
  String get gameWaitingForPlayers => 'En attente des joueurs...';

  @override
  String get gameWaitingGetReady => 'Préparez-vous...';

  @override
  String get gameWaitingHost => 'HÔTE';

  @override
  String get gameWaitingInviteCodeCopied => 'Code d\'invitation copié !';

  @override
  String get gameWaitingInviteCodeHeader => 'CODE D\'INVITATION';

  @override
  String get gameWaitingInvitePlayer => 'Inviter un joueur';

  @override
  String get gameWaitingLeaveRoom => 'Quitter la salle';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Niveau $level';
  }

  @override
  String get gameWaitingNotReady => 'Pas prêt';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count pas prêts)';
  }

  @override
  String get gameWaitingPlayersHeader => 'JOUEURS';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count joueurs dans la salle';
  }

  @override
  String get gameWaitingReady => 'Prêt';

  @override
  String get gameWaitingReadyUp => 'Se préparer';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count manches';
  }

  @override
  String get gameWaitingShareCode =>
      'Partagez ce code avec vos amis pour rejoindre';

  @override
  String get gameWaitingStartGame => 'Lancer la partie';

  @override
  String get gameWordAlreadyUsed => 'Mot déjà utilisé !';

  @override
  String get gameWordBombBoom => 'BOUM !';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'Le mot doit contenir « $prompt »';
  }

  @override
  String get gameWordBombReport => 'Signaler';

  @override
  String get gameWordBombReportContent =>
      'Signaler ce mot comme invalide ou inapproprié.';

  @override
  String gameWordBombReportTitle(String word) {
    return 'Signaler « $word » ?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife =>
      'Temps écoulé ! Vous avez perdu une vie.';

  @override
  String get gameWordBombTitle => 'Bombe de mots';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Tapez un mot contenant « $prompt »...';
  }

  @override
  String get gameWordBombUsedWords => 'Mots utilisés';

  @override
  String get gameWordBombWordReported => 'Mot signalé';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count mots utilisés';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'Le mot doit commencer par « $letter »';
  }

  @override
  String get gameWrong => 'Faux';

  @override
  String get gameYou => 'Vous';

  @override
  String get gameYourTurn => 'VOTRE TOUR !';

  @override
  String get gamificationAchievements => 'Succès';

  @override
  String get gamificationAll => 'Tous';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '$name terminé !';
  }

  @override
  String get gamificationClaim => 'Réclamer';

  @override
  String get gamificationClaimReward => 'Réclamer la récompense';

  @override
  String get gamificationCoinsAvailable => 'Pièces disponibles';

  @override
  String get gamificationDaily => 'Quotidien';

  @override
  String get gamificationDailyChallenges => 'Défis quotidiens';

  @override
  String get gamificationDayStreak => 'Jours consécutifs';

  @override
  String get gamificationDone => 'Terminé';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Obtenu le $date';
  }

  @override
  String get gamificationEasy => 'Facile';

  @override
  String get gamificationEngagement => 'Engagement';

  @override
  String get gamificationEpic => 'Épique';

  @override
  String get gamificationExperiencePoints => 'Points d\'expérience';

  @override
  String get gamificationGlobal => 'Mondial';

  @override
  String get gamificationHard => 'Difficile';

  @override
  String get gamificationLeaderboard => 'Classement';

  @override
  String gamificationLevel(Object level) {
    return 'Niveau $level';
  }

  @override
  String get gamificationLevelLabel => 'NIVEAU';

  @override
  String gamificationLevelShort(Object level) {
    return 'Nv.$level';
  }

  @override
  String get gamificationLoadingAchievements => 'Chargement des succès...';

  @override
  String get gamificationLoadingChallenges => 'Chargement des défis...';

  @override
  String get gamificationLoadingRankings => 'Chargement du classement...';

  @override
  String get gamificationMedium => 'Moyen';

  @override
  String get gamificationMilestones => 'Paliers';

  @override
  String get gamificationMonthly => 'Mois';

  @override
  String get gamificationMyProgress => 'Ma progression';

  @override
  String get gamificationNoAchievements => 'Aucun succès trouvé';

  @override
  String get gamificationNoAchievementsInCategory =>
      'Aucun succès dans cette catégorie';

  @override
  String get gamificationNoChallenges => 'Aucun défi disponible';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'Aucun défi $type disponible';
  }

  @override
  String get gamificationNoLeaderboard => 'Aucune donnée de classement';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Membre Premium';

  @override
  String get gamificationProgress => 'Progression';

  @override
  String get gamificationRank => 'RANG';

  @override
  String get gamificationRankLabel => 'Rang';

  @override
  String get gamificationRegional => 'Régional';

  @override
  String gamificationReward(Object amount, Object type) {
    return 'Récompense : $amount $type';
  }

  @override
  String get gamificationSocial => 'Social';

  @override
  String get gamificationSpecial => 'Spécial';

  @override
  String get gamificationTotal => 'Total';

  @override
  String get gamificationUnlocked => 'Débloqué';

  @override
  String get gamificationVerifiedUser => 'Utilisateur vérifié';

  @override
  String get gamificationVipMember => 'Membre VIP';

  @override
  String get gamificationWeekly => 'Hebdomadaire';

  @override
  String get gamificationXpAvailable => 'XP disponible';

  @override
  String get gamificationYearly => 'Annee';

  @override
  String get gamificationYourPosition => 'Votre position';

  @override
  String get gender => 'Genre';

  @override
  String get getStarted => 'Commencer';

  @override
  String get giftCategoryAll => 'Tous';

  @override
  String giftFromSender(Object name) {
    return 'De $name';
  }

  @override
  String get giftGetCoins => 'Obtenir des pièces';

  @override
  String get giftNoGiftsAvailable => 'Aucun cadeau disponible';

  @override
  String get giftNoGiftsInCategory => 'Aucun cadeau dans cette catégorie';

  @override
  String get giftNoGiftsYet => 'Pas encore de cadeaux';

  @override
  String get giftNotEnoughCoins => 'Pas assez de pièces';

  @override
  String giftPriceCoins(Object price) {
    return '$price pièces';
  }

  @override
  String get giftReceivedGifts => 'Cadeaux reçus';

  @override
  String get giftReceivedGiftsEmpty =>
      'Les cadeaux que vous recevez apparaîtront ici';

  @override
  String get giftSendGift => 'Envoyer un cadeau';

  @override
  String giftSendGiftTo(Object name) {
    return 'Envoyer un cadeau à $name';
  }

  @override
  String get giftSending => 'Envoi...';

  @override
  String giftSentTo(Object name) {
    return 'Cadeau envoyé à $name !';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'Vous avez $available pièces.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'Vous avez besoin de $required pièces pour ce cadeau.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'Il vous manque $shortfall pièces.';
  }

  @override
  String get gold => 'Or';

  @override
  String get grantAlbumAccess => 'Partager mon album';

  @override
  String get greatInterestsHelp =>
      'Super ! Vos centres d\'intérêt nous aident à vous suggérer de meilleures connexions';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Salutations';

  @override
  String get guideBadge => 'Guide';

  @override
  String get height => 'Taille';

  @override
  String get helpAndSupport => 'Aide et Support';

  @override
  String get helpOthersFindYou =>
      'Aidez les autres à vous trouver sur les réseaux sociaux';

  @override
  String get hours => 'Heures';

  @override
  String get icebreakersCategoryCompliments => 'Compliments';

  @override
  String get icebreakersCategoryDeep => 'Profond';

  @override
  String get icebreakersCategoryDreams => 'Rêves';

  @override
  String get icebreakersCategoryFood => 'Cuisine';

  @override
  String get icebreakersCategoryFunny => 'Drôle';

  @override
  String get icebreakersCategoryHobbies => 'Loisirs';

  @override
  String get icebreakersCategoryHypothetical => 'Hypothétique';

  @override
  String get icebreakersCategoryMovies => 'Films';

  @override
  String get icebreakersCategoryMusic => 'Musique';

  @override
  String get icebreakersCategoryPersonality => 'Personnalité';

  @override
  String get icebreakersCategoryTravel => 'Voyage';

  @override
  String get icebreakersCategoryTwoTruths => 'Deux vérités';

  @override
  String get icebreakersCategoryWouldYouRather => 'Tu préfères';

  @override
  String get icebreakersLabel => 'Brise-glace';

  @override
  String get icebreakersNoneInCategory =>
      'Aucun brise-glace dans cette catégorie';

  @override
  String get icebreakersQuickAnswers => 'Réponses rapides :';

  @override
  String get icebreakersSendAnIcebreaker => 'Envoyer un brise-glace';

  @override
  String icebreakersSendTo(Object name) {
    return 'Envoyer à $name';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Envoyer sans réponse';

  @override
  String get icebreakersTitle => 'Brise-glaces';

  @override
  String get idiomsCategory => 'Expressions Idiomatiques';

  @override
  String get incognitoMode => 'Mode Incognito';

  @override
  String get incognitoModeDescription =>
      'Masquer votre profil de la découverte';

  @override
  String get incorrectAnswer => 'Incorrect';

  @override
  String get infoUpdatedMessage =>
      'Vos informations de base ont été enregistrées';

  @override
  String get infoUpdatedTitle => 'Infos mises à jour !';

  @override
  String get insufficientCoins => 'Pièces insuffisantes';

  @override
  String get insufficientCoinsTitle => 'Coins Insuffisants';

  @override
  String get interestArt => 'Art';

  @override
  String get interestBeach => 'Plage';

  @override
  String get interestBeer => 'Bière';

  @override
  String get interestBusiness => 'Affaires';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestCats => 'Chats';

  @override
  String get interestCoffee => 'Café';

  @override
  String get interestCooking => 'Cuisine';

  @override
  String get interestCycling => 'Cyclisme';

  @override
  String get interestDance => 'Danse';

  @override
  String get interestDancing => 'Danse';

  @override
  String get interestDogs => 'Chiens';

  @override
  String get interestEntrepreneurship => 'Entrepreneuriat';

  @override
  String get interestEnvironment => 'Environnement';

  @override
  String get interestFashion => 'Mode';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Nourriture';

  @override
  String get interestGaming => 'Jeux vidéo';

  @override
  String get interestHiking => 'Randonnée';

  @override
  String get interestHistory => 'Histoire';

  @override
  String get interestInvesting => 'Investissement';

  @override
  String get interestLanguages => 'Langues';

  @override
  String get interestMeditation => 'Méditation';

  @override
  String get interestMountains => 'Montagnes';

  @override
  String get interestMovies => 'Films';

  @override
  String get interestMusic => 'Musique';

  @override
  String get interestNature => 'Nature';

  @override
  String get interestPets => 'Animaux';

  @override
  String get interestPhotography => 'Photographie';

  @override
  String get interestPoetry => 'Poésie';

  @override
  String get interestPolitics => 'Politique';

  @override
  String get interestReading => 'Lecture';

  @override
  String get interestRunning => 'Course';

  @override
  String get interestScience => 'Science';

  @override
  String get interestSkiing => 'Ski';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestSpirituality => 'Spiritualité';

  @override
  String get interestSports => 'Sports';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSwimming => 'Natation';

  @override
  String get interestTeaching => 'Enseignement';

  @override
  String get interestTechnology => 'Technologie';

  @override
  String get interestTravel => 'Voyages';

  @override
  String get interestVegan => 'Végan';

  @override
  String get interestVegetarian => 'Végétarien';

  @override
  String get interestVolunteering => 'Bénévolat';

  @override
  String get interestWine => 'Vin';

  @override
  String get interestWriting => 'Écriture';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Centres d\'intérêt';

  @override
  String interestsCount(int count) {
    return '$count centres d\'intérêt';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max centres d\'intérêt sélectionnés';
  }

  @override
  String get interestsUpdatedMessage =>
      'Vos centres d\'intérêt ont été enregistrés';

  @override
  String get interestsUpdatedTitle => 'Centres d\'intérêt mis à jour !';

  @override
  String get invalidWord => 'Mot invalide';

  @override
  String get inviteCodeCopied => 'Code d\'invitation copié !';

  @override
  String get inviteFriends => 'Inviter des Amis';

  @override
  String get itsAMatch => 'Commencez à connecter !';

  @override
  String get joinMessage =>
      'Rejoignez GreenGoChat et échangez avec des gens du monde entier';

  @override
  String get keepSwiping => 'Continuer à Balayer';

  @override
  String get langMatchBadge => 'Langue Compatible';

  @override
  String get language => 'Langue';

  @override
  String languageChangedTo(String language) {
    return 'Langue changée en $language';
  }

  @override
  String get languagePacksBtn => 'Packs de Langues';

  @override
  String get languagePacksShopTitle => 'Boutique de Packs de Langues';

  @override
  String get languagesToDownloadLabel => 'Langues à télécharger :';

  @override
  String get lastName => 'Nom';

  @override
  String get lastUpdated => 'Derniere mise a jour';

  @override
  String get leaderboardSubtitle => 'Classements mondiaux et regionaux';

  @override
  String get leaderboardTitle => 'Classement';

  @override
  String get learn => 'Apprendre';

  @override
  String get learningAccuracy => 'Précision';

  @override
  String get learningActiveThisWeek => 'Actif cette semaine';

  @override
  String get learningAddLessonSection => 'Ajouter une section de leçon';

  @override
  String get learningAiConversationCoach => 'Coach de conversation AI';

  @override
  String get learningAllCategories => 'Toutes les catégories';

  @override
  String get learningAllLessons => 'Toutes les leçons';

  @override
  String get learningAllLevels => 'Tous les niveaux';

  @override
  String get learningAmount => 'Montant';

  @override
  String get learningAmountLabel => 'Montant';

  @override
  String get learningAnalytics => 'Analyses';

  @override
  String learningAnswer(Object answer) {
    return 'Réponse : $answer';
  }

  @override
  String get learningApplyFilters => 'Appliquer les filtres';

  @override
  String get learningAreasToImprove => 'Points à améliorer';

  @override
  String get learningAvailableBalance => 'Solde disponible';

  @override
  String get learningAverageRating => 'Note moyenne';

  @override
  String get learningBeginnerProgress => 'Progression débutant';

  @override
  String get learningBonusCoins => 'Pièces bonus';

  @override
  String get learningCategory => 'Catégorie';

  @override
  String get learningCategoryProgress => 'Progression par catégorie';

  @override
  String get learningCheck => 'Vérifier';

  @override
  String get learningCheckBackSoon => 'Revenez bientôt !';

  @override
  String get learningCoachSessionCost =>
      '10 pièces/session  |  25 XP en récompense';

  @override
  String get learningContinue => 'Continuer';

  @override
  String get learningCorrect => 'Correct !';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Correct : $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'La bonne réponse : $answer';
  }

  @override
  String get learningCorrectAnswers => 'Bonnes réponses';

  @override
  String get learningCorrectLabel => 'Correct';

  @override
  String get learningCorrections => 'Corrections';

  @override
  String get learningCreateLesson => 'Créer une leçon';

  @override
  String get learningCreateNewLesson => 'Créer une nouvelle leçon';

  @override
  String get learningCustomPackTitleHint =>
      'ex. : « Salutations en espagnol pour voyageurs »';

  @override
  String get learningDescribeImage => 'Décrivez cette image';

  @override
  String get learningDescriptionHint =>
      'Qu\'est-ce que les étudiants apprendront ?';

  @override
  String get learningDescriptionLabel => 'Description';

  @override
  String get learningDifficultyLevel => 'Niveau de difficulté';

  @override
  String get learningDone => 'Terminé';

  @override
  String get learningDraftSave => 'Enregistrer le brouillon';

  @override
  String get learningDraftSaved => 'Brouillon enregistré !';

  @override
  String get learningEarned => 'Gagné';

  @override
  String get learningEdit => 'Modifier';

  @override
  String get learningEndSession => 'Terminer la session';

  @override
  String get learningEndSessionBody =>
      'Votre progression actuelle sera perdue. Souhaitez-vous terminer la session et voir votre score d\'abord ?';

  @override
  String get learningEndSessionQuestion => 'Terminer la session ?';

  @override
  String get learningExit => 'Quitter';

  @override
  String get learningFalse => 'Faux';

  @override
  String get learningFilterAll => 'Tous';

  @override
  String get learningFilterDraft => 'Brouillon';

  @override
  String get learningFilterLessons => 'Filtrer les leçons';

  @override
  String get learningFilterPublished => 'Publié';

  @override
  String get learningFilterUnderReview => 'En cours de révision';

  @override
  String get learningFluency => 'Fluidité';

  @override
  String get learningFree => 'GRATUIT';

  @override
  String get learningGoBack => 'Retour';

  @override
  String get learningGoalCompleteLessons => 'Compléter 5 leçons';

  @override
  String get learningGoalEarnXp => 'Gagner 500 XP';

  @override
  String get learningGoalPracticeMinutes => 'Pratiquer 30 minutes';

  @override
  String get learningGrammar => 'Grammaire';

  @override
  String get learningHint => 'Indice';

  @override
  String get learningLangBrazilianPortuguese => 'Portugais brésilien';

  @override
  String get learningLangEnglish => 'Anglais';

  @override
  String get learningLangFrench => 'Français';

  @override
  String get learningLangGerman => 'Allemand';

  @override
  String get learningLangItalian => 'Italien';

  @override
  String get learningLangPortuguese => 'Portugais';

  @override
  String get learningLangSpanish => 'Espagnol';

  @override
  String get learningLanguagesSubtitle =>
      'Sélectionnez jusqu\'à 5 langues. Cela nous aide à vous connecter avec des locuteurs natifs et des partenaires d\'apprentissage.';

  @override
  String get learningLanguagesTitle =>
      'Quelles langues voulez-vous apprendre ?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Langues à apprendre ($count/5)';
  }

  @override
  String get learningLastMonth => 'Le mois dernier';

  @override
  String learningLearnLanguage(Object language) {
    return 'Apprendre $language';
  }

  @override
  String get learningLearned => 'Appris';

  @override
  String get learningLessonComplete => 'Leçon terminée !';

  @override
  String get learningLessonCompleteUpper => 'LEÇON TERMINÉE !';

  @override
  String get learningLessonContent => 'Contenu de la leçon';

  @override
  String learningLessonNumber(Object number) {
    return 'Leçon $number';
  }

  @override
  String get learningLessonSubmitted => 'Leçon soumise pour révision !';

  @override
  String get learningLessonTitle => 'Titre de la leçon';

  @override
  String get learningLessonTitleHint =>
      'ex. : « Salutations en espagnol pour voyageurs »';

  @override
  String get learningLessonTitleLabel => 'Titre de la leçon';

  @override
  String get learningLessonsLabel => 'Leçons';

  @override
  String get learningLetsStart => 'C\'est parti !';

  @override
  String get learningLevel => 'Niveau';

  @override
  String learningLevelBadge(Object level) {
    return 'NV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Niveau $level';
  }

  @override
  String get learningListen => 'Écouter';

  @override
  String get learningListening => 'Écoute...';

  @override
  String get learningLongPressForTranslation => 'Appui long pour la traduction';

  @override
  String get learningMessages => 'Messages';

  @override
  String get learningMessagesSent => 'Messages envoyés';

  @override
  String get learningMinimumWithdrawal => 'Retrait minimum : 50,00 \$';

  @override
  String get learningMonthlyEarnings => 'Revenus mensuels';

  @override
  String get learningMyProgress => 'Ma progression';

  @override
  String get learningNativeLabel => '(natif)';

  @override
  String get learningNativeLanguage => 'Votre langue maternelle';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'Vous devez obtenir au moins $threshold% pour réussir cette leçon.';
  }

  @override
  String get learningNext => 'Suivant';

  @override
  String get learningNoExercisesInSection =>
      'Aucun exercice dans cette section';

  @override
  String get learningNoLessonsAvailable =>
      'Aucune leçon disponible pour le moment';

  @override
  String get learningNoPacksFound => 'Aucun pack trouvé';

  @override
  String get learningNoQuestionsAvailable =>
      'Aucune question disponible pour le moment.';

  @override
  String get learningNotQuite => 'Pas tout à fait';

  @override
  String get learningNotQuiteTitle => 'Presque...';

  @override
  String get learningOpenAiCoach => 'Ouvrir le coach AI';

  @override
  String learningPackFilter(Object category) {
    return 'Pack : $category';
  }

  @override
  String get learningPackPurchased => 'Pack acheté avec succès !';

  @override
  String get learningPassageRevealed => 'Passage (révélé)';

  @override
  String get learningPathTitle => 'Parcours d\'Apprentissage';

  @override
  String get learningPlaying => 'Lecture...';

  @override
  String get learningPleaseEnterDescription =>
      'Veuillez saisir une description';

  @override
  String get learningPleaseEnterTitle => 'Veuillez saisir un titre';

  @override
  String get learningPracticeAgain => 'S\'entraîner à nouveau';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Leçons publiées';

  @override
  String get learningPurchased => 'Acheté';

  @override
  String get learningPurchasedLessonsEmpty =>
      'Vos leçons achetées apparaîtront ici';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count questions dans cette leçon';
  }

  @override
  String get learningQuickActions => 'Actions rapides';

  @override
  String get learningReadPassage => 'Lire le passage';

  @override
  String get learningRecentActivity => 'Activité récente';

  @override
  String get learningRecentMilestones => 'Paliers récents';

  @override
  String get learningRecentTransactions => 'Transactions récentes';

  @override
  String get learningRequired => 'Obligatoire';

  @override
  String get learningResponseRecorded => 'Réponse enregistrée';

  @override
  String get learningReview => 'Révision';

  @override
  String get learningSearchLanguages => 'Rechercher des langues...';

  @override
  String get learningSectionEditorComingSoon =>
      'Éditeur de section bientôt disponible !';

  @override
  String get learningSeeScore => 'Voir le score';

  @override
  String get learningSelectNativeLanguage =>
      'Sélectionnez votre langue maternelle';

  @override
  String get learningSelectScenario =>
      'Sélectionnez un scénario pour commencer';

  @override
  String get learningSelectScenarioFirst =>
      'Sélectionnez d\'abord un scénario...';

  @override
  String get learningSessionComplete => 'Session terminée !';

  @override
  String get learningSessionSummary => 'Résumé de la session';

  @override
  String get learningShowAll => 'Tout afficher';

  @override
  String get learningShowPassageText => 'Afficher le texte du passage';

  @override
  String get learningSkip => 'Passer';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return 'Dépenser $price pièces pour débloquer cette leçon ?';
  }

  @override
  String get learningStartFlashcards => 'Commencer les cartes mémoire';

  @override
  String get learningStartLesson => 'Commencer la leçon';

  @override
  String get learningStartPractice => 'Commencer l\'entraînement';

  @override
  String get learningStartQuiz => 'Commencer le quiz';

  @override
  String get learningStartingLesson => 'Démarrage de la leçon...';

  @override
  String get learningStop => 'Arrêter';

  @override
  String get learningStreak => 'Série';

  @override
  String get learningStrengths => 'Points forts';

  @override
  String get learningSubmit => 'Soumettre';

  @override
  String get learningSubmitForReview => 'Soumettre pour révision';

  @override
  String get learningSubmitForReviewBody =>
      'Votre leçon sera examinée par notre équipe avant sa mise en ligne. Cela prend généralement 24 à 48 heures.';

  @override
  String get learningSubmitForReviewQuestion => 'Soumettre pour révision ?';

  @override
  String get learningTabAllLessons => 'Toutes les leçons';

  @override
  String get learningTabEarnings => 'Revenus';

  @override
  String get learningTabFlashcards => 'Cartes mémoire';

  @override
  String get learningTabLessons => 'Leçons';

  @override
  String get learningTabMyLessons => 'Mes leçons';

  @override
  String get learningTabMyProgress => 'Ma progression';

  @override
  String get learningTabOverview => 'Aperçu';

  @override
  String get learningTabPhrases => 'Expressions';

  @override
  String get learningTabProgress => 'Progression';

  @override
  String get learningTabPurchased => 'Achetées';

  @override
  String get learningTabQuizzes => 'Quiz';

  @override
  String get learningTabStudents => 'Étudiants';

  @override
  String get learningTapToContinue => 'Appuyez pour continuer';

  @override
  String get learningTapToHearPassage => 'Appuyez pour écouter le passage';

  @override
  String get learningTapToListen => 'Appuyez pour écouter';

  @override
  String get learningTapToMatch => 'Appuyez sur les éléments pour les associer';

  @override
  String get learningTapToRevealTranslation =>
      'Appuyez pour révéler la traduction';

  @override
  String get learningTapWordsToBuild =>
      'Appuyez sur les mots ci-dessous pour construire la phrase';

  @override
  String get learningTargetLanguage => 'Langue cible';

  @override
  String get learningTeacherDashboardTitle => 'Tableau de bord enseignant';

  @override
  String get learningTeacherTiers => 'Niveaux enseignant';

  @override
  String get learningThisMonth => 'Ce mois-ci';

  @override
  String get learningTopPerformingStudents => 'Meilleurs étudiants';

  @override
  String get learningTotalStudents => 'Total des étudiants';

  @override
  String get learningTotalStudentsLabel => 'Total des étudiants';

  @override
  String get learningTotalXp => 'XP total';

  @override
  String get learningTranslatePhrase => 'Traduisez cette phrase';

  @override
  String get learningTrue => 'Vrai';

  @override
  String get learningTryAgain => 'Réessayer';

  @override
  String get learningTypeAnswerBelow => 'Tapez votre réponse ci-dessous';

  @override
  String get learningTypeAnswerHint => 'Tapez votre réponse...';

  @override
  String get learningTypeDescriptionHint => 'Tapez votre description...';

  @override
  String get learningTypeMessageHint => 'Tapez votre message...';

  @override
  String get learningTypeMissingWordHint => 'Tapez le mot manquant...';

  @override
  String get learningTypeSentenceHint => 'Tapez la phrase...';

  @override
  String get learningTypeTranslationHint => 'Tapez votre traduction...';

  @override
  String get learningTypeWhatYouHeardHint =>
      'Tapez ce que vous avez entendu...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Unité $unit - Leçon $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Unité $number';
  }

  @override
  String get learningUnlock => 'Débloquer';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Débloquer pour $price pièces';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Débloquer pour $price pièces';
  }

  @override
  String get learningUnlockLesson => 'Débloquer la leçon';

  @override
  String get learningViewAll => 'Voir tout';

  @override
  String get learningViewAnalytics => 'Voir les analyses';

  @override
  String get learningVocabulary => 'Vocabulaire';

  @override
  String learningWeek(Object week) {
    return 'Semaine $week';
  }

  @override
  String get learningWeeklyGoals => 'Objectifs hebdomadaires';

  @override
  String get learningWhatWillStudentsLearnHint =>
      'Qu\'est-ce que les étudiants apprendront ?';

  @override
  String get learningWhatYouWillLearn => 'Ce que vous apprendrez';

  @override
  String get learningWithdraw => 'Retirer';

  @override
  String get learningWithdrawFunds => 'Retirer des fonds';

  @override
  String get learningWithdrawalSubmitted => 'Demande de retrait soumise !';

  @override
  String get learningWordsAndPhrases => 'Mots et expressions';

  @override
  String get learningWriteAnswerFreely => 'Ecrivez votre reponse librement';

  @override
  String get learningWriteAnswerHint => 'Écrivez votre réponse...';

  @override
  String get learningXpEarned => 'XP gagnés';

  @override
  String learningYourAnswer(Object answer) {
    return 'Votre réponse : $answer';
  }

  @override
  String get learningYourScore => 'Votre score';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Leçon';

  @override
  String get letsChat => 'Discutons !';

  @override
  String get letsExchange => 'Commencez à connecter !';

  @override
  String get levelLabel => 'Niveau';

  @override
  String levelLabelN(String level) {
    return 'Niveau $level';
  }

  @override
  String get levelTitleEnthusiast => 'Enthousiaste';

  @override
  String get levelTitleExpert => 'Expert';

  @override
  String get levelTitleExplorer => 'Explorateur';

  @override
  String get levelTitleLegend => 'Légende';

  @override
  String get levelTitleMaster => 'Maître';

  @override
  String get levelTitleNewcomer => 'Débutant';

  @override
  String get levelTitleVeteran => 'Vétéran';

  @override
  String get levelUp => 'NIVEAU SUPÉRIEUR !';

  @override
  String get levelUpCongratulations =>
      'Félicitations pour avoir atteint un nouveau niveau !';

  @override
  String get levelUpContinue => 'Continuer';

  @override
  String get levelUpRewards => 'RÉCOMPENSES';

  @override
  String get levelUpTitle => 'NIVEAU SUPÉRIEUR !';

  @override
  String get levelUpVIPUnlocked => 'Statut VIP Débloqué !';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Vous avez atteint le Niveau $level';
  }

  @override
  String get likes => 'J\'aime';

  @override
  String get limitReachedTitle => 'Limite atteinte';

  @override
  String get listenMe => 'Écoute-moi !';

  @override
  String get loading => 'Chargement...';

  @override
  String get loadingLabel => 'Chargement...';

  @override
  String get localGuideBadge => 'Guide Local';

  @override
  String get location => 'Localisation';

  @override
  String get locationAndLanguages => 'Localisation et Langues';

  @override
  String get locationError => 'Erreur de localisation';

  @override
  String get locationNotFound => 'Lieu introuvable';

  @override
  String get locationNotFoundMessage =>
      'Nous n\'avons pas pu déterminer votre adresse. Veuillez réessayer ou définir votre lieu manuellement plus tard.';

  @override
  String get locationPermissionDenied => 'Permission refusée';

  @override
  String get locationPermissionDeniedMessage =>
      'La permission de localisation est nécessaire pour détecter votre position actuelle. Veuillez accorder la permission pour continuer.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permission définitivement refusée';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'La permission de localisation a été définitivement refusée. Veuillez l\'activer dans les paramètres de votre appareil pour utiliser cette fonctionnalité.';

  @override
  String get locationRequestTimeout => 'Délai d\'attente dépassé';

  @override
  String get locationRequestTimeoutMessage =>
      'La récupération de votre position a pris trop de temps. Veuillez vérifier votre connexion et réessayer.';

  @override
  String get locationServicesDisabled => 'Services de localisation désactivés';

  @override
  String get locationServicesDisabledMessage =>
      'Veuillez activer les services de localisation dans les paramètres de votre appareil pour utiliser cette fonctionnalité.';

  @override
  String get locationUnavailable =>
      'Impossible d\'obtenir votre position pour le moment. Vous pourrez la définir manuellement plus tard dans les paramètres.';

  @override
  String get locationUnavailableTitle => 'Position indisponible';

  @override
  String get locationUpdatedMessage =>
      'Vos paramètres de localisation ont été enregistrés';

  @override
  String get locationUpdatedTitle => 'Localisation mise à jour !';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get logOutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get login => 'Connexion';

  @override
  String get loginWithBiometrics => 'Connexion avec Biométrie';

  @override
  String get logout => 'Se Déconnecter';

  @override
  String get longTermRelationship => 'Amitiés durables';

  @override
  String get lookingFor => 'Recherche';

  @override
  String get lvl => 'NIV';

  @override
  String get manageCouponsTiersRules => 'Gérer coupons, niveaux et règles';

  @override
  String get matchDetailsTitle => 'Détails de l\'échange';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Vous et $name voulez echanger des langues !';
  }

  @override
  String get matchNotifKeepSwiping => 'Continuer';

  @override
  String get matchNotifLetsChat => 'Discutons !';

  @override
  String get matchNotifLetsExchange => 'COMMENCEZ À CONNECTER !';

  @override
  String get matchNotifViewProfile => 'Voir le Profil';

  @override
  String matchPercentage(String percentage) {
    return '$percentage en commun';
  }

  @override
  String matchedOnDate(String date) {
    return 'Connectés le $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Vous vous êtes connecté avec $name le $date';
  }

  @override
  String get matches => 'Connexions';

  @override
  String get matchesClearFilters => 'Effacer les Filtres';

  @override
  String matchesCount(int count) {
    return '$count connexions';
  }

  @override
  String get matchesFilterAll => 'Tous';

  @override
  String get matchesFilterMessaged => 'Avec Messages';

  @override
  String get matchesFilterNew => 'Nouveaux';

  @override
  String get matchesNoMatchesFound => 'Aucune connexion trouvée';

  @override
  String get matchesNoMatchesYet => 'Pas encore de connexions';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered sur $total connexions';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered sur $total connexions';
  }

  @override
  String get matchesStartSwiping =>
      'Commencez à explorer pour créer des connexions !';

  @override
  String get matchesTryDifferent => 'Essayez une autre recherche ou filtre';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Maximum $count centres d\'intérêt autorisés';
  }

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get discoverWorldwideTitle => 'Élargissez vos horizons !';

  @override
  String get discoverWorldwideMessage =>
      'Il n\'y a pas encore beaucoup de personnes dans votre région, mais GreenGo vous connecte avec des gens du monde entier ! Allez dans les Filtres et ajoutez d\'autres pays pour découvrir des personnes incroyables aux quatre coins du globe.';

  @override
  String get openFilters => 'Ouvrir les Filtres';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return 'Abonnement $tierName actif jusqu\'au $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => 'Abonnement activé !';

  @override
  String get membershipAdvancedFilters => 'Filtres avancés';

  @override
  String get membershipBase => 'Base';

  @override
  String get membershipBaseMembership => 'Abonnement de base';

  @override
  String get membershipBestValue =>
      'Meilleur rapport qualité-prix pour un engagement long terme !';

  @override
  String get membershipBoostsMonth => 'Boosts/mois';

  @override
  String get membershipBuyTitle => 'Acheter un abonnement';

  @override
  String get membershipCouponCodeLabel => 'Code promo *';

  @override
  String get membershipCouponHint => 'ex. : GOLD2024';

  @override
  String get membershipCurrent => 'Abonnement actuel';

  @override
  String get membershipDailyLikes => 'Connexions Quotidiennes';

  @override
  String get membershipDailyMessagesLabel =>
      'Messages quotidiens (vide = illimité)';

  @override
  String get membershipDailySwipesLabel =>
      'Swipes quotidiens (vide = illimité)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days jours restants';
  }

  @override
  String get membershipDurationLabel => 'Durée (jours)';

  @override
  String get membershipEnterCouponHint => 'Entrez un code promo';

  @override
  String get couponRedeemTitle => 'Utiliser un code promo';

  @override
  String get referralCodeTitle => 'Vous avez un code de parrainage ?';

  @override
  String get referralCodeLabel => 'Code de parrainage (facultatif)';

  @override
  String get referralCodeHint => 'Entrez le code d\'un ami';

  @override
  String get couponApplyButton => 'Appliquer';

  @override
  String get couponAppliedSuccess => 'Coupon appliqué';

  @override
  String get couponNotValid => 'Coupon non valide';

  @override
  String get freeBaseWeekInfo =>
      'Pas de coupon ? 1 semaine de membre Base offerte !';

  @override
  String get couponRedeemSubtitle =>
      'Saisissez votre code pour améliorer votre abonnement ou obtenir des pièces gratuites';

  @override
  String get couponRedeemButton => 'Utiliser le coupon';

  @override
  String couponRedeemedSuccess(String grantSummary) {
    return 'Utilisé : $grantSummary';
  }

  @override
  String get couponErrorInvalid => 'Ce code de coupon n\'est pas valide';

  @override
  String get couponErrorExpired => 'Ce coupon a expiré';

  @override
  String get couponErrorMaxUsesReached =>
      'Ce coupon a atteint sa limite d\'utilisation';

  @override
  String get couponErrorEmailMismatch =>
      'Ce coupon est réservé à un autre compte';

  @override
  String get couponErrorAlreadyRedeemed => 'Vous avez déjà utilisé ce coupon';

  @override
  String get couponErrorDisabled => 'Ce coupon n\'est plus actif';

  @override
  String get couponErrorGeneric =>
      'Impossible d\'utiliser le coupon. Veuillez réessayer.';

  @override
  String get registerCouponLabel => 'Code de coupon (facultatif)';

  @override
  String get registerCouponHint => 'Saisissez un code de coupon';

  @override
  String get welcomeGrantTitle => 'Bienvenue sur GreenGo !';

  @override
  String get welcomeGrantDismiss => 'Compris';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Équivalent à $price/mois';
  }

  @override
  String get membershipErrorLoadingData =>
      'Erreur lors du chargement des données';

  @override
  String membershipExpires(Object date) {
    return 'Expire le : $date';
  }

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get subscriptionAutoRenewInfo =>
      'Renouvellement automatique sauf annulation 24 h avant la fin de la période. Gérez dans votre compte boutique.';

  @override
  String get subscriptionFreeTrialInfo =>
      'Nouveaux abonnés : 7 jours gratuits, puis au prix indiqué. Annulez 24 h avant la fin.';

  @override
  String get purchasesRestored => 'Achats restaurés.';

  @override
  String get membershipExtendTitle => 'Prolonger votre adhésion';

  @override
  String get membershipFeatureComparison => 'Comparaison des fonctionnalités';

  @override
  String get membershipGeneric => 'Abonnement';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Base';

  @override
  String get membershipIncognitoMode => 'Mode incognito';

  @override
  String get membershipLeaveEmptyLifetime =>
      'Laisser vide pour une durée illimitée';

  @override
  String get membershipLeaveEmptyUnlimited => 'Laisser vide pour illimité';

  @override
  String get membershipLowerThanCurrent => 'Inférieur à votre niveau actuel';

  @override
  String get membershipMaxUsesLabel => 'Utilisations max';

  @override
  String get membershipMonthly => 'Abonnements mensuels';

  @override
  String get membershipNameDescriptionLabel => 'Nom/Description';

  @override
  String get membershipActive => 'Actif';

  @override
  String get membershipNoActive => 'Aucun abonnement actif';

  @override
  String get membershipNotesLabel => 'Notes';

  @override
  String get membershipOneMonth => '1 mois';

  @override
  String get membershipOneYear => '1 an';

  @override
  String get membershipPanel => 'Panneau des Abonnements';

  @override
  String get membershipPermanent => 'Permanent';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 PIÈCES';

  @override
  String get membershipPrioritySupport => 'Assistance prioritaire';

  @override
  String get membershipReadReceipts => 'Accusés de lecture';

  @override
  String get membershipRequired => 'Adhésion requise';

  @override
  String get membershipRequiredDescription =>
      'Vous devez être membre de GreenGo pour effectuer cette action.';

  @override
  String get membershipExtendDescription =>
      'Votre adhésion de base est active. Achetez une année supplémentaire pour prolonger votre date d\'expiration.';

  @override
  String get membershipRewinds => 'Retours en arrière';

  @override
  String membershipSavePercent(Object percent) {
    return 'ÉCONOMISEZ $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Voir qui se connecte';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Achetez une fois, profitez des fonctionnalités premium pendant 1 mois ou 1 an';

  @override
  String get membershipSuperLikes => 'Connexions Prioritaires';

  @override
  String get membershipSuperLikesLabel =>
      'Connexions Prioritaires/jour (vide = illimité)';

  @override
  String get membershipTerms =>
      'Achat unique. L\'abonnement sera prolongé à partir de votre date de fin actuelle.';

  @override
  String get membershipTermsExtended =>
      'Achat unique. L\'abonnement sera prolongé à partir de votre date de fin actuelle. Les achats de niveau supérieur remplacent les niveaux inférieurs.';

  @override
  String get membershipTierLabel => 'Niveau d\'abonnement *';

  @override
  String membershipTierName(Object tierName) {
    return 'Abonnement $tierName';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Abonnements annuels (Économisez jusqu\'à $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'Vous avez $tierName';
  }

  @override
  String get menu => 'Menu';

  @override
  String socialLinkInvalid(String platform) {
    return 'Saisis un lien ou un identifiant valide pour $platform';
  }

  @override
  String get messages => 'Echanges';

  @override
  String get messagesTabMessages => 'Messages';

  @override
  String get messagesTabGroups => 'Groupes';

  @override
  String get messagesTabBusiness => 'Business';

  @override
  String get messagesBusinessEmpty =>
      'Aucune demande de vitrine pour le moment';

  @override
  String get minutes => 'Minutes';

  @override
  String moreAchievements(int count) {
    return '+$count autres succès';
  }

  @override
  String get myBadges => 'Mes Badges';

  @override
  String get myProgress => 'Mes Progrès';

  @override
  String get myUsage => 'Mon Utilisation';

  @override
  String get navLearn => 'Apprendre';

  @override
  String get navPlay => 'Jouer';

  @override
  String get nearby => 'À proximité';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Vous avez besoin de $amount pièces pour débloquer plus de profils.';
  }

  @override
  String get newLabel => 'NOUVEAU';

  @override
  String get next => 'Suivant';

  @override
  String nextLevelXp(String xp) {
    return 'Prochain niveau dans $xp XP';
  }

  @override
  String get nickname => 'Pseudo';

  @override
  String get nicknameAlreadyTaken => 'Ce pseudo est déjà pris';

  @override
  String get nicknameCheckError =>
      'Erreur lors de la vérification de disponibilité';

  @override
  String nicknameInfoText(String nickname) {
    return 'Votre pseudo est unique et peut être utilisé pour vous trouver. Les autres peuvent vous rechercher avec @$nickname';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Doit contenir 3-20 caractères';

  @override
  String get nicknameNoConsecutiveUnderscores =>
      'Pas d\'underscores consécutifs';

  @override
  String get nicknameNoReservedWords => 'Ne peut pas contenir de mots réservés';

  @override
  String get nicknameOnlyAlphanumeric =>
      'Lettres, chiffres et underscores uniquement';

  @override
  String get nicknameRequirements =>
      '3-20 caractères. Lettres, chiffres et underscores uniquement.';

  @override
  String get nicknameRules => 'Règles du Pseudo';

  @override
  String get nicknameSearchChat => 'Discuter';

  @override
  String get nicknameSearchError => 'Erreur de recherche. Veuillez reessayer.';

  @override
  String get nicknameSearchHelp => 'Entrez un pseudo pour trouver quelqu\'un';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'Aucun profil trouve avec @$nickname';
  }

  @override
  String get nicknameSearchOwnProfile => 'C\'est votre propre profil !';

  @override
  String get nicknameSearchTitle => 'Rechercher par Pseudo';

  @override
  String get nicknameSearchView => 'Voir';

  @override
  String nicknameSearchActionNope(String nickname) {
    return 'Vous venez de sélectionner « Non » pour @$nickname';
  }

  @override
  String nicknameSearchActionSkip(String nickname) {
    return 'Vous venez de sélectionner « Passer » pour @$nickname';
  }

  @override
  String nicknameSearchActionPriorityConnect(String nickname) {
    return 'Vous venez de sélectionner « Connexion prioritaire » pour @$nickname';
  }

  @override
  String nicknameSearchActionConnect(String nickname) {
    return 'Vous venez de sélectionner « Connectons-nous » pour @$nickname';
  }

  @override
  String nicknameSearchActionMatch(String nickname) {
    return 'Vous êtes maintenant connecté avec @$nickname !';
  }

  @override
  String nicknameSearchLimitReached(String action) {
    return 'Vous avez atteint votre limite de $action. Réessayez plus tard.';
  }

  @override
  String get nicknameStartWithLetter => 'Commencer par une lettre';

  @override
  String get nicknameUpdatedMessage =>
      'Votre nouveau pseudo est maintenant actif';

  @override
  String get nicknameUpdatedSuccess => 'Pseudo mis à jour avec succès';

  @override
  String get nicknameUpdatedTitle => 'Pseudo mis à jour !';

  @override
  String get no => 'Non';

  @override
  String get noActiveGamesLabel => 'Aucun jeu actif';

  @override
  String get noBadgesEarnedYet => 'Aucun badge gagné';

  @override
  String get noInternetConnection => 'Pas de connexion internet';

  @override
  String get noLanguagesYet => 'Pas encore de langues. Commencez à apprendre !';

  @override
  String get noLeaderboardData => 'Pas encore de données de classement';

  @override
  String get noMatchesFound => 'Aucune connexion trouvée';

  @override
  String get noMatchesYet => 'Pas encore de connexions';

  @override
  String get noMessages => 'Pas encore de messages';

  @override
  String get noMoreProfiles => 'Plus de profils à afficher';

  @override
  String get noOthersToSee => 'Il n\'y a personne d\'autre à voir';

  @override
  String get noPendingVerifications => 'Aucune vérification en attente';

  @override
  String get noPhotoSubmitted => 'Aucune photo soumise';

  @override
  String get noPreviousProfile => 'Aucun profil précédent à revenir';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'Aucun profil trouvé avec @$nickname';
  }

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noSocialProfilesLinked => 'Aucun profil social lié';

  @override
  String get noVoiceRecording => 'Pas d\'enregistrement vocal';

  @override
  String get nodeAvailable => 'Disponible';

  @override
  String get nodeCompleted => 'Terminé';

  @override
  String get nodeInProgress => 'En Cours';

  @override
  String get nodeLocked => 'Verrouillé';

  @override
  String get notEnoughCoins => 'Pas assez de pièces';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get notSet => 'Non défini';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Succès Débloqué : $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Vous avez acheté $amount pièces avec succès.';
  }

  @override
  String get notificationDialogEnable => 'Activer';

  @override
  String get notificationDialogMessage =>
      'Activez les notifications pour savoir quand vous recevez de nouvelles connexions, des messages et des Priority Connects.';

  @override
  String get notificationDialogNotNow => 'Pas maintenant';

  @override
  String get notificationDialogTitle => 'Restez connecté';

  @override
  String get notificationEmailSubtitle =>
      'Recevoir les notifications par e-mail';

  @override
  String get notificationEmailTitle => 'Notifications par e-mail';

  @override
  String get notificationEnableQuietHours => 'Activer les heures calmes';

  @override
  String get notificationEndTime => 'Heure de fin';

  @override
  String get notificationMasterControls => 'Contrôles principaux';

  @override
  String get notificationMatchExpiring => 'Connexion bientôt expirée';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Quand une connexion est sur le point d\'expirer';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname a commencé une conversation avec vous.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'Vous avez reçu un j\'aime de @$nickname';
  }

  @override
  String get notificationNewLikes => 'Nouveaux likes';

  @override
  String get notificationNewLikesSubtitle =>
      'Quand quelqu\'un veut se connecter avec vous';

  @override
  String notificationNewMatch(String nickname) {
    return 'Nouvelle connexion ! Vous et @$nickname êtes maintenant connectés. Commencez à discuter.';
  }

  @override
  String get notificationNewMatches => 'Nouvelles connexions';

  @override
  String get notificationNewMatchesSubtitle =>
      'Quand vous avez une nouvelle connexion';

  @override
  String notificationNewMessage(String nickname) {
    return 'Nouveau message de @$nickname';
  }

  @override
  String get notificationNewMessages => 'Nouveaux messages';

  @override
  String get notificationNewMessagesSubtitle =>
      'Quand quelqu\'un vous envoie un message';

  @override
  String get notificationProfileViews => 'Vues du profil';

  @override
  String get notificationProfileViewsSubtitle =>
      'Quand quelqu\'un consulte votre profil';

  @override
  String get notificationPromotional => 'Promotionnel';

  @override
  String get notificationPromotionalSubtitle =>
      'Conseils, offres et promotions';

  @override
  String get notificationPushSubtitle =>
      'Recevoir les notifications sur cet appareil';

  @override
  String get notificationPushTitle => 'Notifications push';

  @override
  String get notificationQuietHours => 'Heures calmes';

  @override
  String get notificationQuietHoursDescription =>
      'Désactiver les notifications entre des heures définies';

  @override
  String get notificationQuietHoursSubtitle =>
      'Désactiver les notifications pendant certaines heures';

  @override
  String get notificationSettings => 'Paramètres des Notifications';

  @override
  String get notificationSettingsTitle => 'Paramètres de notifications';

  @override
  String get notificationCategories => 'Catégories de notifications';

  @override
  String get notificationCatExchanges => 'Discussions d\'échange';

  @override
  String get notificationCatExchangesSubtitle =>
      'Messages de vos échanges en tête-à-tête';

  @override
  String get notificationCatGroups => 'Discussions de groupe';

  @override
  String get notificationCatGroupsSubtitle =>
      'Messages dans vos discussions de groupe';

  @override
  String get notificationCatBusiness => 'Discussions professionnelles';

  @override
  String get notificationCatBusinessSubtitle =>
      'Messages des entreprises que vous contactez';

  @override
  String get notificationCatEventsChat => 'Discussions d\'événements';

  @override
  String get notificationCatEventsChatSubtitle =>
      'Messages dans les événements que vous avez rejoints';

  @override
  String get notificationCatCommunityChat => 'Discussions de communauté';

  @override
  String get notificationCatCommunityChatSubtitle =>
      'Messages dans le chat de la communauté';

  @override
  String get notificationCatAnnouncements => 'Annonces et événements';

  @override
  String get notificationCatAnnouncementsSubtitle =>
      'Annonces et événements de la communauté';

  @override
  String get notificationCatTips => 'Astuces';

  @override
  String get notificationCatTipsSubtitle =>
      'Astuces et suggestions de la communauté';

  @override
  String get notificationCatMessages => 'Messages';

  @override
  String get notificationCatMessagesSubtitle =>
      'Discussions directes, de groupe, professionnelles et d\'événements';

  @override
  String get notificationCatEvents => 'Événements';

  @override
  String get notificationCatEventsSubtitle =>
      'Événements, rappels, réponses et alertes de ville';

  @override
  String get notificationCatCommunities => 'Communautés';

  @override
  String get notificationCatCommunitiesSubtitle =>
      'Annonces et nouveaux membres';

  @override
  String get notificationCatSocial => 'Social';

  @override
  String get notificationCatSocialSubtitle =>
      'Vues de profil, abonnements, notes et boosts';

  @override
  String get notificationCatAccount => 'Compte';

  @override
  String get notificationCatAccountSubtitle =>
      'Vérification et mises à jour importantes du compte';

  @override
  String get notificationEventCities => 'Événements de communauté par ville';

  @override
  String get notificationEventCitiesSubtitle =>
      'Sois notifié lorsque des événements ont lieu dans ces villes';

  @override
  String get notificationAddCity => 'Ajouter une ville';

  @override
  String get notificationAddCityHint => 'p. ex. Rome';

  @override
  String get notificationNoCities =>
      'Aucune ville pour l\'instant — ajoutes-en une pour recevoir des alertes d\'événements';

  @override
  String get notificationEnableInSettingsBody =>
      'Les notifications sont désactivées. Active-les dans les Réglages pour recevoir messages, événements et alertes de communauté.';

  @override
  String get notificationOpenSettings => 'Ouvrir les Réglages';

  @override
  String get notificationSound => 'Son';

  @override
  String get notificationSoundSubtitle => 'Jouer un son pour les notifications';

  @override
  String get notificationSoundVibration => 'Son et vibration';

  @override
  String get notificationStartTime => 'Heure de début';

  @override
  String notificationSuperLike(String nickname) {
    return 'Vous avez reçu une connexion prioritaire de @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Connexions Prioritaires';

  @override
  String get notificationSuperLikesSubtitle =>
      'Quand quelqu\'un se connecte prioritairement avec vous';

  @override
  String get notificationTypes => 'Types de notifications';

  @override
  String get notificationVibration => 'Vibration';

  @override
  String get notificationVibrationSubtitle => 'Vibrer pour les notifications';

  @override
  String get notificationsEmpty => 'Pas encore de notifications';

  @override
  String get notificationsEmptySubtitle =>
      'Quand vous recevrez des notifications, elles apparaîtront ici';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get occupation => 'Profession';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Ajouter une photo';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Ajoutez des photos qui vous représentent vraiment';

  @override
  String get onboardingAiVerifiedDescription =>
      'Vos photos sont vérifiées par AI pour garantir leur authenticité';

  @override
  String get onboardingAiVerifiedPhotos => 'Photos vérifiées par AI';

  @override
  String get onboardingBioHint =>
      'Parlez-nous de vos centres d\'intérêt, des langues que vous parlez et des cultures que vous voulez découvrir...';

  @override
  String get onboardingBioMinLength =>
      'La bio doit contenir au moins 50 caractères';

  @override
  String get onboardingChooseFromGallery => 'Choisir depuis la galerie';

  @override
  String get onboardingCompleteAllFields =>
      'Veuillez compléter tous les champs';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingDateOfBirth => 'Date de naissance';

  @override
  String get onboardingDisplayName => 'Nom d\'affichage';

  @override
  String get onboardingDisplayNameHint => 'Comment devons-nous vous appeler ?';

  @override
  String get onboardingEnterYourName => 'Veuillez saisir votre nom';

  @override
  String get onboardingExpressYourself => 'Exprimez-vous';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Écrivez quelque chose qui vous représente';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'Échec de la sélection de l\'image : $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'Échec de la prise de photo : $error';
  }

  @override
  String get onboardingGenderFemale => 'Femme';

  @override
  String get onboardingGenderMale => 'Homme';

  @override
  String get onboardingGenderNonBinary => 'Non-binaire';

  @override
  String get onboardingGenderOther => 'Autre';

  @override
  String get onboardingHoldIdNextToFace =>
      'Tenez votre pièce d\'identité à côté de votre visage';

  @override
  String get onboardingIdentifyAs => 'Je m\'identifie comme';

  @override
  String get onboardingInterestsHelpMatches =>
      'Vos centres d\'intérêt nous aident à vous connecter avec des personnes qui partagent votre culture et vos langues';

  @override
  String get onboardingInterestsSubtitle =>
      'Sélectionnez au moins 3 centres d\'intérêt (max 10)';

  @override
  String get onboardingLanguages => 'Langues';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 sélectionnées';
  }

  @override
  String get onboardingLetsGetStarted => 'C\'est parti';

  @override
  String get onboardingLocation => 'Lieu';

  @override
  String get onboardingLocationLater =>
      'Vous pourrez définir votre lieu plus tard dans les paramètres';

  @override
  String get onboardingMainPhoto => 'PRINCIPALE';

  @override
  String get onboardingMaxInterests =>
      'Vous pouvez sélectionner jusqu\'à 10 centres d\'intérêt';

  @override
  String get onboardingMaxLanguages =>
      'Vous pouvez sélectionner jusqu\'à 3 langues';

  @override
  String get onboardingMinInterests =>
      'Veuillez sélectionner au moins 3 centres d\'intérêt';

  @override
  String get onboardingMinLanguage =>
      'Veuillez sélectionner au moins une langue';

  @override
  String get onboardingMinLocation =>
      'Veuillez définir votre position pour continuer';

  @override
  String get onboardingNameMinLength =>
      'Le nom doit contenir au moins 2 caractères';

  @override
  String get onboardingNoLocationSelected => 'Aucun lieu sélectionné';

  @override
  String get onboardingOptional => 'Facultatif';

  @override
  String get onboardingSelectFromPhotos => 'Sélectionner parmi vos photos';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 sélectionnés';
  }

  @override
  String get onboardingShowYourself => 'Montrez-vous';

  @override
  String get onboardingTakePhoto => 'Prendre une photo';

  @override
  String get onboardingTellUsAboutYourself => 'Parlez-nous un peu de vous';

  @override
  String get onboardingTipAuthentic => 'Soyez authentique et sincère';

  @override
  String get onboardingTipPassions => 'Partagez vos passions et vos loisirs';

  @override
  String get onboardingTipPositive => 'Restez positif';

  @override
  String get onboardingTipUnique => 'Qu\'est-ce qui vous rend unique ?';

  @override
  String get onboardingUploadAtLeastOnePhoto =>
      'Veuillez téléverser au moins une photo';

  @override
  String get onboardingUseCurrentLocation => 'Utiliser la position actuelle';

  @override
  String get onboardingUseYourCamera => 'Utiliser votre caméra';

  @override
  String get onboardingWhereAreYou => 'Où êtes-vous ?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Définissez vos langues préférées et votre lieu (facultatif)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Veuillez écrire quelque chose à propos de vous';

  @override
  String get onboardingWritingTips => 'Conseils de rédaction';

  @override
  String get onboardingYourInterests => 'Vos centres d\'intérêt';

  @override
  String oneTimeDownloadSize(int size) {
    return 'Ce téléchargement unique fait environ $size Mo.';
  }

  @override
  String get optionalConsents => 'Consentements Optionnels';

  @override
  String get orContinueWith => 'Ou continuez avec';

  @override
  String get origin => 'Origine';

  @override
  String packFocusMode(String packName) {
    return 'Pack : $packName';
  }

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordMustContain => 'Le mot de passe doit contenir:';

  @override
  String get passwordMustContainLowercase =>
      'Le mot de passe doit contenir au moins une lettre minuscule';

  @override
  String get passwordMustContainNumber =>
      'Le mot de passe doit contenir au moins un chiffre';

  @override
  String get passwordMustContainSpecialChar =>
      'Le mot de passe doit contenir au moins un caractère spécial';

  @override
  String get passwordMustContainUppercase =>
      'Le mot de passe doit contenir au moins une lettre majuscule';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordStrengthFair => 'Moyen';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get passwordStrengthVeryStrong => 'Très Fort';

  @override
  String get passwordStrengthVeryWeak => 'Très Faible';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get passwordWeak =>
      'Le mot de passe doit contenir des majuscules, des minuscules, des chiffres et des caractères spéciaux';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pendingVerifications => 'Vérifications en Attente';

  @override
  String get perMonth => '/mois';

  @override
  String get periodAllTime => 'Tout le Temps';

  @override
  String get periodMonthly => 'Ce Mois';

  @override
  String get periodWeekly => 'Cette Semaine';

  @override
  String get personalStatistics => 'Statistiques personnelles';

  @override
  String get personalStatisticsSubtitle =>
      'Graphiques, objectifs et progrès linguistique';

  @override
  String get personalStatsActivity => 'Activité récente';

  @override
  String get personalStatsChatStats => 'Statistiques de chat';

  @override
  String get personalStatsConversations => 'Conversations';

  @override
  String get personalStatsGoalsAchieved => 'Objectifs atteints';

  @override
  String get personalStatsLevel => 'Niveau';

  @override
  String get personalStatsLanguage => 'Langue';

  @override
  String get personalStatsTotal => 'Total';

  @override
  String get personalStatsNextLevel => 'Niveau suivant';

  @override
  String get personalStatsNoActivityYet => 'Aucune activité enregistrée';

  @override
  String get personalStatsNoWordsYet =>
      'Commencez à discuter pour découvrir de nouveaux mots';

  @override
  String get personalStatsTotalMessages => 'Messages envoyés';

  @override
  String get personalStatsWordsDiscovered => 'Mots découverts';

  @override
  String get personalStatsWordsLearned => 'Mots Appris';

  @override
  String get personalStatsXpOverview => 'Aperçu XP';

  @override
  String get photoAddPhoto => 'Ajouter une photo';

  @override
  String get photoAddPrivateDescription =>
      'Ajoutez des photos privées que vous pouvez partager dans le chat';

  @override
  String get photoAddPublicDescription =>
      'Ajoutez des photos pour compléter votre profil';

  @override
  String get photoAlreadyExistsInAlbum =>
      'La photo existe déjà dans l\'album cible';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 photos';
  }

  @override
  String get photoDeleteConfirm =>
      'Êtes-vous sûr(e) de vouloir supprimer cette photo ?';

  @override
  String get photoDeleteMainWarning =>
      'Ceci est votre photo principale. La photo suivante deviendra votre photo principale (elle doit montrer votre visage). Continuer ?';

  @override
  String get photoExplicitContent =>
      'Cette photo peut contenir du contenu inapproprié. Les photos dans l\'application ne doivent pas montrer de nudité, de sous-vêtements ou de contenu explicite.';

  @override
  String get photoExplicitNudity =>
      'Cette photo semble contenir de la nudité ou du contenu explicite. Toutes les photos dans l\'application doivent être appropriées et entièrement habillées.';

  @override
  String get photoPrivateAlbumSuggestion =>
      'Vous pouvez envoyer cette photo dans votre album prive, ou seules les personnes autorisees la verront.';

  @override
  String get photoUploadDeniedNudity =>
      'Envoi refuse - infraction : nudite. Les photos de votre profil public doivent montrer des personnes entierement habillees.';

  @override
  String photoFailedPickImage(Object error) {
    return 'Échec de la sélection de l\'image : $error';
  }

  @override
  String get photoLongPressReorder => 'Appui long et glisser pour réorganiser';

  @override
  String get photoMainNoFace =>
      'Votre photo principale doit montrer clairement votre visage. Aucun visage n\'a été détecté sur cette photo.';

  @override
  String get photoMainNotForward =>
      'Veuillez utiliser une photo où votre visage est clairement visible et tourné vers l\'avant.';

  @override
  String get photoManagePhotos => 'Gérer les photos';

  @override
  String get photoMaxPrivate => 'Maximum 6 photos privées autorisées';

  @override
  String get photoMaxPublic => 'Maximum 6 photos publiques autorisées';

  @override
  String get photoMustHaveOne =>
      'Vous devez avoir au moins une photo publique avec votre visage visible.';

  @override
  String get photoNoPhotos => 'Pas encore de photos';

  @override
  String get photoNoPrivatePhotos => 'Pas encore de photos privées';

  @override
  String get photoNotAccepted => 'Photo non acceptée';

  @override
  String get photoNotAllowedPublic =>
      'Cette photo n\'est pas autorisée dans l\'application.';

  @override
  String get photoPrimary => 'PRINCIPALE';

  @override
  String get photoPrivateShareInfo =>
      'Les photos privées peuvent être partagées dans le chat';

  @override
  String get photoTooLarge =>
      'La photo est trop volumineuse. La taille maximale est de 10 Mo.';

  @override
  String get photoTooMuchSkin =>
      'Cette photo montre trop de peau exposée. Veuillez utiliser une photo où vous êtes habillé(e) de manière appropriée.';

  @override
  String get photoUploadedMessage => 'Votre photo a été ajoutée à votre profil';

  @override
  String get photoUploadedTitle => 'Photo téléchargée !';

  @override
  String get photoValidating => 'Validation de la photo...';

  @override
  String get photos => 'Photos';

  @override
  String photosCount(int count) {
    return '$count/6 photos';
  }

  @override
  String photosPublicCount(int count) {
    return 'Photos : $count publiques';
  }

  @override
  String photosPublicPrivateCount(int publicCount, int privateCount) {
    return 'Photos : $publicCount publiques + $privateCount privees';
  }

  @override
  String get photosUpdatedMessage => 'Votre galerie photo a été enregistrée';

  @override
  String get photosUpdatedTitle => 'Photos mises à jour !';

  @override
  String phrasesCount(String count) {
    return '$count phrases';
  }

  @override
  String get phrasesLabel => 'phrases';

  @override
  String get platinum => 'Platine';

  @override
  String get playAgain => 'Rejouer';

  @override
  String playersRange(String min, String max) {
    return '$min-$max joueurs';
  }

  @override
  String get playing => 'Lecture...';

  @override
  String playingCountLabel(String count) {
    return '$count en jeu';
  }

  @override
  String get plusTaxes => '+ taxes';

  @override
  String get preferenceAddCountry => 'Ajouter un Pays';

  @override
  String get preferenceLanguageFilter => 'Langue';

  @override
  String get preferenceLanguageFilterDesc =>
      'Afficher uniquement les personnes qui parlent une langue spécifique';

  @override
  String get preferenceAnyLanguage => 'Toutes les langues';

  @override
  String get preferenceInterestFilter => 'Intérêts';

  @override
  String get preferenceInterestFilterDesc =>
      'Afficher uniquement les personnes qui partagent vos intérêts';

  @override
  String get preferenceNoInterestFilter =>
      'Pas de filtre d\'intérêts — afficher tout le monde';

  @override
  String get preferenceAddInterest => 'Ajouter un intérêt';

  @override
  String get preferenceSearchInterest => 'Rechercher des intérêts...';

  @override
  String get preferenceNoInterestsFound => 'Aucun intérêt trouvé';

  @override
  String get preferenceAddDealBreaker => 'Ajouter un Critere Eliminatoire';

  @override
  String get preferenceAdvancedFilters => 'Filtres Avances';

  @override
  String get preferenceAgeRange => 'Tranche d\'Age';

  @override
  String get preferenceAllCountries => 'Tous les Pays';

  @override
  String get preferenceAllVerified => 'Tous les profils doivent etre verifies';

  @override
  String get preferenceCountry => 'Pays';

  @override
  String get preferenceCountryDescription =>
      'Afficher uniquement les personnes de pays specifiques (laisser vide pour tous)';

  @override
  String get preferenceDealBreakers => 'Criteres Eliminatoires';

  @override
  String get preferenceDealBreakersDesc =>
      'Ne jamais me montrer de profils avec ces caracteristiques';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Tout le monde';

  @override
  String get preferenceMaxDistance => 'Distance Maximale';

  @override
  String get preferenceMen => 'Hommes';

  @override
  String get preferenceMostPopular => 'Plus Populaire';

  @override
  String get preferenceNoCountriesFound => 'Aucun pays trouve';

  @override
  String get preferenceNoCountryFilter =>
      'Pas de filtre de pays - affichage mondial';

  @override
  String get preferenceCountryRequired =>
      'Au moins un pays doit être sélectionné';

  @override
  String get preferenceByUsers => 'Par utilisateurs';

  @override
  String get preferenceNoDealBreakers => 'Aucun critere eliminatoire defini';

  @override
  String get preferenceNoDistanceLimit => 'Pas de limite de distance';

  @override
  String get preferenceOnlineNow => 'En Ligne Maintenant';

  @override
  String get preferenceOnlineNowDesc =>
      'Afficher uniquement les profils actuellement en ligne';

  @override
  String get preferenceOnlyVerified =>
      'Afficher uniquement les profils verifies';

  @override
  String get preferenceOrientationDescription =>
      'Filtrer par orientation (tout decocher pour tout afficher)';

  @override
  String get preferenceRecentlyActive => 'Recemment Actifs';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Afficher uniquement les profils actifs ces 7 derniers jours';

  @override
  String get preferenceSave => 'Enregistrer';

  @override
  String get preferenceSelectCountry => 'Selectionner un Pays';

  @override
  String get preferenceSexualOrientation => 'Orientation Sexuelle';

  @override
  String get preferenceShowMe => 'Me Montrer';

  @override
  String get preferenceUnlimited => 'Illimite';

  @override
  String preferenceUsersCount(int count) {
    return '$count utilisateurs';
  }

  @override
  String get preferenceWithin => 'Dans un rayon de';

  @override
  String get preferenceWomen => 'Femmes';

  @override
  String get preferencesSavedMessage =>
      'Vos préférences de découverte ont été mises à jour';

  @override
  String get preferencesSavedTitle => 'Préférences enregistrées !';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Origine Principale';

  @override
  String get priorityConnectNotificationMessage =>
      'Quelqu\'un veut se connecter avec vous !';

  @override
  String get priorityConnectNotificationTitle => 'Connexion prioritaire !';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get privacySettings => 'Paramètres de Confidentialité';

  @override
  String get privateAlbum => 'Privé';

  @override
  String get privateRoom => 'Salon Privé';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Profil';

  @override
  String get profileAboutMe => 'A Propos de Moi';

  @override
  String get profileAccountDeletedSuccess => 'Compte supprimé avec succès.';

  @override
  String get profileActivate => 'Activer';

  @override
  String get profileActivateIncognito => 'Activer le mode incognito ?';

  @override
  String get profileActivateTravelerMode => 'Activer le mode voyageur ?';

  @override
  String get profileActivatingBoost => 'Activation du boost...';

  @override
  String get profileActiveLabel => 'ACTIF';

  @override
  String get profileAdditionalDetails => 'Details Supplementaires';

  @override
  String profileAgeCannotChange(int age) {
    return 'Age $age - Ne peut pas etre modifie (verification)';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return 'Profil déjà boosté ! ${minutes}m restantes';
  }

  @override
  String get profileAuthenticationFailed => 'Échec de l\'authentification';

  @override
  String profileBioMinLength(int min) {
    return 'La bio doit contenir au moins $min caracteres';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Coût : $cost pièces';
  }

  @override
  String get profileBoostDescription =>
      'Votre profil apparaîtra en tête de la découverte pendant 30 minutes !';

  @override
  String get profileBoostNow => 'Booster maintenant';

  @override
  String get profileBoostProfile => 'Booster le profil';

  @override
  String get profileBoostSubtitle => 'Soyez vu en premier pendant 30 minutes';

  @override
  String get profileBoosted => 'Profil boosté !';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return 'Profil boosté pendant $minutes minutes !';
  }

  @override
  String get profileBuyCoins => 'Acheter des pièces';

  @override
  String get profileCoinShop => 'Boutique de pièces';

  @override
  String get profileCoinShopSubtitle =>
      'Acheter des pièces et un abonnement premium';

  @override
  String get profileConfirmYourPassword => 'Confirmez votre mot de passe';

  @override
  String get profileContinue => 'Continuer';

  @override
  String get profileDataExportSent => 'Export de données envoyé à votre e-mail';

  @override
  String get profileDateOfBirth => 'Date de Naissance';

  @override
  String get profileDeleteAccountWarning =>
      'Cette action est définitive et irréversible. Toutes vos données, connexions et messages seront supprimés. Saisissez votre mot de passe pour confirmer.';

  @override
  String get profileDiscoveryRestarted =>
      'Découverte redémarrée ! Vous pouvez à nouveau voir tous les profils.';

  @override
  String get profileDisplayName => 'Nom d\'Affichage';

  @override
  String get profileDobInfo =>
      'Votre date de naissance ne peut pas être modifiée pour des raisons de vérification de l\'âge. Votre âge exact est visible par vos connexions.';

  @override
  String get profileEditBasicInfo => 'Modifier les Infos de Base';

  @override
  String get profileEditLocation => 'Modifier Localisation et Langues';

  @override
  String get profileEditNickname => 'Modifier le Pseudo';

  @override
  String get profileEducation => 'Éducation';

  @override
  String get profileEducationHint => 'ex. Licence en Informatique';

  @override
  String get profileEnterNameHint => 'Entrez votre nom';

  @override
  String get profileEnterNicknameHint => 'Entrez un pseudo';

  @override
  String get profileEnterNicknameWith => 'Entrez un pseudo commencant par @';

  @override
  String get profileExportingData => 'Export de vos données en cours...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Échec du redémarrage de la découverte : $error';
  }

  @override
  String get profileFindUsers => 'Trouver des Utilisateurs';

  @override
  String get profileGender => 'Genre';

  @override
  String get profileGetCoins => 'Obtenir des pièces';

  @override
  String get profileGetMembership => 'Obtenir l\'abonnement GreenGo';

  @override
  String get profileGettingLocation => 'Obtention de la localisation...';

  @override
  String get profileGreengoMembership => 'Abonnement GreenGo';

  @override
  String get profileHeightCm => 'Taille (cm)';

  @override
  String get profileIncognitoActivated =>
      'Mode incognito activé pour 24 heures !';

  @override
  String profileIncognitoCost(Object cost) {
    return 'Le mode incognito coûte $cost pièces par jour.';
  }

  @override
  String get profileIncognitoDeactivated => 'Mode incognito désactivé.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'Le mode incognito masque votre profil de la découverte pendant 24 heures.\n\nCoût : $cost';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Gratuit avec Platinum - Masqué de la découverte';

  @override
  String get profileIncognitoMode => 'Mode incognito';

  @override
  String get profileInsufficientCoins => 'Pièces insuffisantes';

  @override
  String profileInterestsCount(Object count) {
    return '$count centres d\'intérêt';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Parlez-nous de vos centres d\'intérêt, loisirs, ce que vous recherchez...';

  @override
  String get profileLanguagesSectionTitle => 'Langues';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 langues selectionnees';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count profil(s) lié(s)';
  }

  @override
  String profileLocationFailed(String error) {
    return 'Impossible d\'obtenir la localisation : $error';
  }

  @override
  String get profileLocationSectionTitle => 'Localisation';

  @override
  String get profileLookingFor => 'Je Cherche';

  @override
  String get profileLookingForHint =>
      'ex. : partenaire d\'échange linguistique';

  @override
  String get profileMaxLanguagesAllowed => 'Maximum 3 langues autorisees';

  @override
  String get profileMembershipActive => 'Actif';

  @override
  String get profileMembershipExpired => 'Expiré';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Valide jusqu\'au $date';
  }

  @override
  String get profileMyUsage => 'Mon utilisation';

  @override
  String get profileMyUsageSubtitle =>
      'Voir votre utilisation quotidienne et les limites de votre niveau';

  @override
  String get profileNicknameAlreadyTaken => 'Ce pseudo est deja pris';

  @override
  String get profileNicknameCharRules =>
      '3-20 caracteres. Lettres, chiffres et underscores uniquement.';

  @override
  String get profileNicknameCheckError =>
      'Erreur lors de la verification de disponibilite';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'Votre pseudo est unique et peut etre utilise pour vous trouver. Les autres peuvent vous chercher avec @$nickname';
  }

  @override
  String get profileNicknameInfoWithout =>
      'Votre pseudo est unique et peut etre utilise pour vous trouver. Definissez-en un pour que les autres puissent vous decouvrir.';

  @override
  String get profileNicknameLabel => 'Pseudo';

  @override
  String get profileNicknameRefresh => 'Actualiser';

  @override
  String get profileNicknameRule1 => 'Doit contenir 3-20 caracteres';

  @override
  String get profileNicknameRule2 => 'Commencer par une lettre';

  @override
  String get profileNicknameRule3 =>
      'Uniquement lettres, chiffres et underscores';

  @override
  String get profileNicknameRule4 => 'Pas d\'underscores consecutifs';

  @override
  String get profileNicknameRule5 => 'Ne peut pas contenir de mots reserves';

  @override
  String get profileNicknameRules => 'Regles du Pseudo';

  @override
  String get profileNicknameSuggestions => 'Suggestions';

  @override
  String profileNoUsersFound(String query) {
    return 'Aucun utilisateur trouve pour \"@$query\"';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return 'Pas assez de pièces ! Besoin de $required, vous avez $available';
  }

  @override
  String get profileOccupation => 'Profession';

  @override
  String get profileOccupationHint => 'ex. Ingenieur Logiciel';

  @override
  String get profileOptionalDetails =>
      'Optionnel - aide les autres a vous connaitre';

  @override
  String get profileOrientationPrivate =>
      'Ceci est prive et n\'est pas affiche sur votre profil';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 photos';
  }

  @override
  String get profilePremiumFeatures => 'Fonctionnalités premium';

  @override
  String get profileProgressGrowth => 'Progression et évolution';

  @override
  String get profileRestart => 'Redémarrer';

  @override
  String get profileRestartDiscovery => 'Redémarrer la découverte';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Cela effacera tous vos swipes (connexions, rejets, connexions prioritaires) pour que vous puissiez redécouvrir tout le monde depuis le début.\n\nVos connexions et chats ne seront PAS affectés.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Redémarrer la découverte';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Réinitialiser tous les swipes et repartir à zéro';

  @override
  String get profileSearchByNickname => 'Rechercher par @pseudo';

  @override
  String get profileSearchByNicknameHint => 'Rechercher par @pseudo';

  @override
  String get profileSearchCityHint =>
      'Rechercher une ville, adresse ou lieu...';

  @override
  String get profileSearchForUsers => 'Rechercher des utilisateurs par pseudo';

  @override
  String get profileSearchLanguagesHint => 'Rechercher des langues...';

  @override
  String get profileSetLocationAndLanguage =>
      'Veuillez definir la localisation et selectionner au moins une langue';

  @override
  String get profileSexualOrientation => 'Orientation Sexuelle';

  @override
  String get profileStop => 'Arrêter';

  @override
  String get profileTellAboutYourselfHint => 'Parlez de vous...';

  @override
  String get profileTipAuthentic => 'Soyez authentique et sincere';

  @override
  String get profileTipHobbies => 'Mentionnez vos hobbies et passions';

  @override
  String get profileTipHumor => 'Ajoutez une touche d\'humour';

  @override
  String get profileTipPositive => 'Restez positif';

  @override
  String get profileTipsForGreatBio => 'Conseils pour une super bio';

  @override
  String profileTravelerActivated(Object city) {
    return 'Mode voyageur activé ! Vous apparaissez à $city pendant 24 heures.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'Le mode voyageur coûte $cost pièces par jour.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Mode voyageur désactivé. Retour à votre vrai lieu.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'Le mode voyageur vous permet d\'apparaître dans le fil de découverte d\'une autre ville pendant 24 heures.\n\nCoût : $cost';
  }

  @override
  String get profileTravelerMode => 'Mode voyageur';

  @override
  String get profileTryDifferentNickname => 'Essayez un autre pseudo';

  @override
  String get profileUnableToVerifyAccount => 'Impossible de vérifier le compte';

  @override
  String get profileReauthProviderMismatch =>
      'Ce compte a ete cree avec une connexion sociale (ex. Google), il n y a donc pas de mot de passe a confirmer ici. Supprimez-le depuis le compte utilise ou contactez le support.';

  @override
  String get profileTooManyAttempts =>
      'Trop de tentatives. Pour votre securite, cet appareil est temporairement bloque — patientez quelques minutes et reessayez.';

  @override
  String get profileUpdateCurrentLocation => 'Mettre a Jour la Localisation';

  @override
  String get profileUpdatedMessage => 'Vos modifications ont été enregistrées';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès';

  @override
  String get profileUpdatedTitle => 'Profil mis à jour !';

  @override
  String get profileWeightKg => 'Poids (kg)';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count profil$_temp0 lié$_temp1';
  }

  @override
  String get profilingDescription =>
      'Autorisez-nous à analyser vos préférences pour vous proposer de meilleures suggestions de connexion';

  @override
  String get progress => 'Progrès';

  @override
  String get progressAchievements => 'Badges';

  @override
  String get progressBadges => 'Badges';

  @override
  String get progressChallenges => 'Défis';

  @override
  String get progressComparison => 'Comparaison de Progres';

  @override
  String get progressCompleted => 'Complétés';

  @override
  String get progressJourneyDescription =>
      'Découvrez tout votre parcours GreenGo et vos étapes clés';

  @override
  String get progressLabel => 'Progression';

  @override
  String get progressLeaderboard => 'Classement';

  @override
  String progressLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Aperçu';

  @override
  String get progressRecentAchievements => 'Succès Récents';

  @override
  String get progressSeeAll => 'Voir Tout';

  @override
  String get progressTitle => 'Progrès';

  @override
  String get progressTodaysChallenges => 'Défis du Jour';

  @override
  String get progressTotalXP => 'XP Total';

  @override
  String get progressViewJourney => 'Voir Votre Parcours';

  @override
  String get publicAlbum => 'Public';

  @override
  String get purchaseSuccessfulTitle => 'Achat réussi !';

  @override
  String get purchasedLabel => 'Acheté';

  @override
  String get quickPlay => 'Partie Rapide';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Lire la Politique de Confidentialité';

  @override
  String get readTermsAndConditions => 'Lire les Conditions Générales';

  @override
  String get readyButton => 'Prêt';

  @override
  String get recipientNickname => 'Pseudo du destinataire';

  @override
  String get recordVoice => 'Enregistrer la Voix';

  @override
  String get refresh => 'Actualiser';

  @override
  String get register => 'S\'inscrire';

  @override
  String get rejectVerification => 'Refuser';

  @override
  String rejectionReason(String reason) {
    return 'Raison: $reason';
  }

  @override
  String get rejectionReasonRequired =>
      'Veuillez entrer une raison pour le refus';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $type restants aujourd\'hui';
  }

  @override
  String get reportSubmittedMessage =>
      'Merci de contribuer à la sécurité de notre communauté';

  @override
  String get reportSubmittedTitle => 'Signalement envoyé !';

  @override
  String get reportWord => 'Signaler le Mot';

  @override
  String get reportsPanel => 'Panneau des Signalements';

  @override
  String get requestBetterPhoto => 'Demander Meilleure Photo';

  @override
  String requiresTier(String tier) {
    return 'Nécessite $tier';
  }

  @override
  String get resetPassword => 'Réinitialiser le Mot de passe';

  @override
  String get resetToDefault => 'Réinitialiser par défaut';

  @override
  String get restartAppWizard => 'Redémarrer l\'Assistant de l\'App';

  @override
  String get restartWizard => 'Redémarrer l\'Assistant';

  @override
  String get restartWizardDialogContent =>
      'Cela redémarrera l\'assistant de configuration. Vous pourrez mettre à jour les informations de votre profil étape par étape. Vos données actuelles seront préservées.';

  @override
  String get retakePhoto => 'Reprendre la Photo';

  @override
  String get retry => 'Reessayer';

  @override
  String get reuploadVerification => 'Renvoyer la photo de vérification';

  @override
  String get reverificationCameraError => 'Impossible d\'ouvrir la caméra';

  @override
  String get reverificationDescription =>
      'Veuillez prendre un selfie clair pour vérifier votre identité. Assurez-vous d\'avoir un bon éclairage et que votre visage soit bien visible.';

  @override
  String get reverificationHeading => 'Nous devons vérifier votre identité';

  @override
  String get reverificationInfoText =>
      'Après soumission, votre profil sera examiné. Vous obtiendrez l\'accès une fois approuvé.';

  @override
  String get reverificationPhotoTips => 'Conseils photo';

  @override
  String get reverificationReasonLabel => 'Motif de la demande :';

  @override
  String get reverificationRetakePhoto => 'Reprendre la photo';

  @override
  String get reverificationSubmit => 'Soumettre pour examen';

  @override
  String get reverificationTapToSelfie => 'Appuyez pour prendre un selfie';

  @override
  String get reverificationTipCamera => 'Regardez directement l\'objectif';

  @override
  String get reverificationTipFullFace =>
      'Assurez-vous que votre visage entier est visible';

  @override
  String get reverificationTipLighting =>
      'Bon éclairage — faites face à la source de lumière';

  @override
  String get reverificationTipNoAccessories =>
      'Pas de lunettes de soleil, chapeaux ou masques';

  @override
  String get reverificationTitle => 'Vérification d\'identité';

  @override
  String get reverificationUploadFailed =>
      'Échec du téléchargement. Veuillez réessayer.';

  @override
  String get reviewReportedMessages =>
      'Examiner les messages signalés et gérer les comptes';

  @override
  String get reviewUserVerifications => 'Examiner les vérifications';

  @override
  String reviewedBy(String admin) {
    return 'Révisé par $admin';
  }

  @override
  String get revokeAccess => 'Révoquer l\'accès à l\'album';

  @override
  String get rewardsAndProgress => 'Récompenses et Progrès';

  @override
  String get roundTimer => 'Chrono de Manche';

  @override
  String roundXofY(String current, String total) {
    return 'Manche $current/$total';
  }

  @override
  String get rounds => 'Manches';

  @override
  String get safetyAdd => 'Ajouter';

  @override
  String get safetyAddAtLeastOneContact =>
      'Veuillez ajouter au moins un contact d\'urgence';

  @override
  String get safetyAddEmergencyContact => 'Ajouter un contact d\'urgence';

  @override
  String get safetyAddEmergencyContacts => 'Ajouter des contacts d\'urgence';

  @override
  String get safetyAdditionalDetailsHint => 'Détails supplémentaires...';

  @override
  String get safetyCheckInEvery => 'Check-in toutes les';

  @override
  String get safetyDateTime => 'Date et heure';

  @override
  String get safetyEmergencyContacts => 'Contacts d\'urgence';

  @override
  String get safetyEmergencyContactsHelp =>
      'Ils seront notifiés si vous avez besoin d\'aide';

  @override
  String get safetyEmergencyContactsLocation =>
      'Les contacts d\'urgence peuvent voir votre position';

  @override
  String get safetyInterval15Min => '15 min';

  @override
  String get safetyInterval1Hour => '1 heure';

  @override
  String get safetyInterval2Hours => '2 heures';

  @override
  String get safetyInterval30Min => '30 min';

  @override
  String get safetyLocation => 'Lieu';

  @override
  String get safetyMeetingLocationHint => 'Où vous rencontrez-vous ?';

  @override
  String get safetyMeetingWith => 'Rendez-vous avec';

  @override
  String get safetyNameLabel => 'Nom';

  @override
  String get safetyNotesOptional => 'Notes (facultatif)';

  @override
  String get safetyPhoneLabel => 'Numéro de téléphone';

  @override
  String get safetyPleaseEnterLocation => 'Veuillez saisir un lieu';

  @override
  String get safetyRelationshipFamily => 'Famille';

  @override
  String get safetyRelationshipFriend => 'Ami(e)';

  @override
  String get safetyRelationshipLabel => 'Relation';

  @override
  String get safetyRelationshipOther => 'Autre';

  @override
  String get safetyRelationshipPartner => 'Partenaire';

  @override
  String get safetyRelationshipRoommate => 'Colocataire';

  @override
  String get safetyScheduleCheckIn => 'Programmer le check-in';

  @override
  String get safetyShareLiveLocation => 'Partager la position en direct';

  @override
  String get safetyStaySafe => 'Restez en sécurité';

  @override
  String get save => 'Enregistrer';

  @override
  String get searchByNameOrNickname => 'Rechercher par nom ou @pseudo';

  @override
  String get searchByNickname => 'Rechercher par Pseudo';

  @override
  String get searchByNicknameTooltip => 'Rechercher par pseudo';

  @override
  String get searchCityPlaceholder => 'Rechercher ville, adresse ou lieu...';

  @override
  String get searchCountries => 'Rechercher des pays...';

  @override
  String get searchCountryHint => 'Rechercher un pays...';

  @override
  String get searchForCity => 'Rechercher une ville ou utiliser le GPS';

  @override
  String get searchMessagesHint => 'Rechercher des messages...';

  @override
  String get secondChanceDescription =>
      'Voyez les profils que vous avez passés et qui voulaient se connecter avec vous !';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km';
  }

  @override
  String get secondChanceEmpty => 'Aucune seconde chance disponible';

  @override
  String get secondChanceEmptySubtitle =>
      'Revenez plus tard pour plus d\'opportunités !';

  @override
  String get secondChanceFindButton => 'Trouver des secondes chances';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max gratuites';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Obtenir illimité ($cost)';
  }

  @override
  String get secondChanceLike => 'Aimer';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'A voulu se connecter $ago';
  }

  @override
  String get secondChanceMatchBody =>
      'Vous vous plaisez mutuellement ! Lancez une conversation.';

  @override
  String get secondChanceMatchTitle => 'Commencez à connecter !';

  @override
  String get secondChanceOutOf => 'Plus de secondes chances';

  @override
  String get secondChancePass => 'Passer';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'Vous avez utilisé toutes vos $freePerDay secondes chances gratuites pour aujourd\'hui.\n\nObtenez l\'illimité pour $cost pièces !';
  }

  @override
  String get secondChanceRefresh => 'Actualiser';

  @override
  String get secondChanceStartChat => 'Démarrer le chat';

  @override
  String get secondChanceTitle => 'Seconde chance';

  @override
  String get secondChanceUnlimited => 'Illimité';

  @override
  String get secondChanceUnlimitedUnlocked =>
      'Secondes chances illimitées débloquées !';

  @override
  String get secondaryOrigin => 'Origine Secondaire (optionnel)';

  @override
  String get seconds => 'Secondes';

  @override
  String get secretAchievement => 'Réalisation Secrète';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get seeHowOthersViewProfile =>
      'Voyez comment les autres voient votre profil';

  @override
  String seeMoreProfiles(int count) {
    return 'Voir $count de plus';
  }

  @override
  String get seeMoreProfilesTitle => 'Voir Plus de Profils';

  @override
  String get seeProfile => 'Voir le Profil';

  @override
  String selectAtLeastInterests(int count) {
    return 'Sélectionnez au moins $count centres d\'intérêt';
  }

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get selectTravelLocation => 'Sélectionner le lieu de voyage';

  @override
  String get sendCoins => 'Envoyer des pièces';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return 'Envoyer $amount pièces à @$nickname ?';
  }

  @override
  String get sendMedia => 'Envoyer un média';

  @override
  String get sendMessage => 'Envoyer un Message';

  @override
  String get serverUnavailableMessage =>
      'Nos serveurs sont temporairement indisponibles. Veuillez réessayer dans quelques instants.';

  @override
  String get serverUnavailableTitle => 'Serveur Indisponible';

  @override
  String get setYourUniqueNickname => 'Définissez votre pseudo unique';

  @override
  String get settings => 'Paramètres';

  @override
  String get shareAlbum => 'Partager l\'album';

  @override
  String get shop => 'Boutique';

  @override
  String get shopActive => 'ACTIF';

  @override
  String get shopAdvancedFilters => 'Filtres avancés';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount pièces';
  }

  @override
  String get shopBadge => 'Badge';

  @override
  String get shopBaseMembership => 'Adhésion de base GreenGo';

  @override
  String get shopBaseMembershipDescription =>
      'Nécessaire pour swiper, liker, discuter et interagir avec d\'autres utilisateurs.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus pièces bonus';
  }

  @override
  String get shopBoosts => 'Boosts';

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Acheter $tier ($duration)';
  }

  @override
  String get shopCannotSendToSelf =>
      'Vous ne pouvez pas vous envoyer des pièces';

  @override
  String get shopCheckInternet =>
      'Vérifiez votre connexion internet\net réessayez.';

  @override
  String get shopCoins => 'Pièces';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount pièces/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount pièces envoyées à @$nickname';
  }

  @override
  String get shopComingSoon => 'Bientôt disponible';

  @override
  String get shopConfirmSend => 'Confirmer l\'envoi';

  @override
  String get shopCurrent => 'ACTUEL';

  @override
  String shopCurrentExpires(Object date) {
    return 'ACTUEL - Expire le $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Plan actuel : $tier';
  }

  @override
  String get shopDailyLikes => 'Connexions Quotidiennes';

  @override
  String shopDaysLeft(Object days) {
    return '${days}j restants';
  }

  @override
  String get shopEnterAmount => 'Entrez le montant';

  @override
  String get shopEnterBothFields => 'Veuillez entrer le pseudo et le montant';

  @override
  String get shopEnterValidAmount => 'Veuillez entrer un montant valide';

  @override
  String shopExpired(String date) {
    return 'Expiré : $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expire le : $date ($days jours restants)';
  }

  @override
  String get shopFailedToInitiate => 'Impossible de lancer l\'achat';

  @override
  String get shopFailedToSendCoins => 'Échec de l\'envoi des pièces';

  @override
  String get shopGetNotified => 'Être notifié';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Mode incognito';

  @override
  String get shopInsufficientCoins => 'Pièces insuffisantes';

  @override
  String shopMembershipActivated(String date) {
    return 'Adhésion GreenGo activée ! +500 pièces bonus. Valable jusqu\'au $date.';
  }

  @override
  String get shopMonthly => 'Mensuel';

  @override
  String get shopNotifyMessage =>
      'Nous vous informerons quand les Video-Coins seront disponibles';

  @override
  String get shopOneMonth => '1 Mois';

  @override
  String get shopOneYear => '1 An';

  @override
  String get shopPerMonth => '/mois';

  @override
  String get shopPerYear => '/an';

  @override
  String get shopPopular => 'POPULAIRE';

  @override
  String get shopPreviousPurchaseFound =>
      'Achat précédent trouvé. Veuillez réessayer.';

  @override
  String get shopPriorityMatching => 'Connexions prioritaires';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Acheter $coins pièces pour $price';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Erreur d\'achat : $error';
  }

  @override
  String get shopReadReceipts => 'Accusés de lecture';

  @override
  String get shopRecipientNickname => 'Pseudo du destinataire';

  @override
  String get shopRetry => 'Réessayer';

  @override
  String shopSavePercent(String percent) {
    return 'ÉCONOMISEZ $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'Voir qui se connecte';

  @override
  String get shopSend => 'Envoyer';

  @override
  String get shopSendCoins => 'Envoyer des pièces';

  @override
  String get shopStoreNotAvailable =>
      'Boutique indisponible. Vérifiez les paramètres de votre appareil.';

  @override
  String get shopTemporarilyUnavailable =>
      'Les achats sont temporairement indisponibles. Veuillez réessayer plus tard.';

  @override
  String get shopSuperLikes => 'Connexions Prioritaires';

  @override
  String get shopTabCoins => 'Pièces';

  @override
  String shopTabError(Object tabName) {
    return 'Erreur de l\'onglet $tabName';
  }

  @override
  String get shopTabMembership => 'Adhésion';

  @override
  String get shopTabVideo => 'Vidéo';

  @override
  String get shopTitle => 'Boutique';

  @override
  String get shopTravelling => 'Voyage';

  @override
  String get shopUnableToLoadPackages => 'Impossible de charger les paquets';

  @override
  String get shopUnlimited => 'Illimité';

  @override
  String get shopUnlockPremium =>
      'Débloquez les fonctionnalités premium et profitez pleinement de GreenGo';

  @override
  String get shopUpgradeAndSave =>
      'Améliorez et économisez ! Réduction sur les niveaux supérieurs';

  @override
  String get shopUpgradeExperience => 'Améliorez votre expérience';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Passer à $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'Utilisateur introuvable';

  @override
  String shopValidUntil(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      'Regardez de courtes vidéos pour gagner des pièces gratuites !\nRestez à l\'écoute pour cette fonctionnalité passionnante.';

  @override
  String get shopVipBadge => 'Badge VIP';

  @override
  String get shopYearly => 'Annuel';

  @override
  String get shopYearlyPlan => 'Abonnement annuel';

  @override
  String get shopYouHave => 'Vous avez';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Vous économisez $amount/mois en passant de $tier';
  }

  @override
  String get shortTermRelationship => 'Nouvelles connaissances';

  @override
  String showingProfiles(int count) {
    return '$count profils';
  }

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get silver => 'Argent';

  @override
  String get skip => 'Passer';

  @override
  String get skipForNow => 'Passer pour l\'Instant';

  @override
  String get slangCategory => 'Argot';

  @override
  String get socialConnectAccounts => 'Connectez vos comptes sociaux';

  @override
  String get socialHintUsername => 'Nom d\'utilisateur (sans @)';

  @override
  String get socialHintUsernameOrUrl => 'Nom d\'utilisateur ou URL du profil';

  @override
  String get socialLinksUpdatedMessage =>
      'Vos profils sociaux ont été enregistrés';

  @override
  String get socialLinksUpdatedTitle => 'Liens sociaux mis à jour !';

  @override
  String get socialNotConnected => 'Non connecté';

  @override
  String get socialProfiles => 'Profils Sociaux';

  @override
  String get socialProfilesTip =>
      'Vos profils sociaux seront visibles sur votre profil GreenGo et aideront les autres à vérifier votre identité.';

  @override
  String get somethingWentWrong => 'Quelque chose s\'est mal passé';

  @override
  String get spotsAbout => 'À propos';

  @override
  String get spotsAddNewSpot => 'Ajouter un nouveau lieu';

  @override
  String get spotsAddSpot => 'Ajouter un lieu';

  @override
  String spotsAddedBy(Object name) {
    return 'Ajouté par $name';
  }

  @override
  String get spotsAll => 'Tous';

  @override
  String get spotsCategory => 'Catégorie';

  @override
  String get spotsCouldNotLoad => 'Impossible de charger les lieux';

  @override
  String get spotsCouldNotLoadSpot => 'Impossible de charger le lieu';

  @override
  String get spotsCreateSpot => 'Créer un lieu';

  @override
  String get spotsCulturalSpots => 'Lieux culturels';

  @override
  String spotsDateDaysAgo(Object count) {
    return 'Il y a $count jours';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return 'Il y a $count mois';
  }

  @override
  String get spotsDateToday => 'Aujourd\'hui';

  @override
  String spotsDateWeeksAgo(Object count) {
    return 'Il y a $count semaines';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return 'Il y a $count ans';
  }

  @override
  String get spotsDateYesterday => 'Hier';

  @override
  String get spotsDescriptionLabel => 'Description';

  @override
  String get spotsNameLabel => 'Nom du lieu';

  @override
  String get spotsNoReviews =>
      'Pas encore d\'avis. Soyez le premier à en écrire un !';

  @override
  String get spotsNoSpotsFound => 'Aucun lieu trouvé';

  @override
  String get spotsReviewAdded => 'Avis ajouté !';

  @override
  String spotsReviewsCount(Object count) {
    return 'Avis ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Partagez votre expérience...';

  @override
  String get spotsSubmitReview => 'Soumettre l\'avis';

  @override
  String get spotsWriteReview => 'Écrire un avis';

  @override
  String get spotsYourRating => 'Votre note';

  @override
  String get standardTier => 'Standard';

  @override
  String get startChat => 'Demarrer le Chat';

  @override
  String get startConversation => 'Démarrer une conversation';

  @override
  String get startGame => 'Commencer la Partie';

  @override
  String get startLearning => 'Commencer à Apprendre';

  @override
  String get startLessonBtn => 'Commencer la Leçon';

  @override
  String get startSwipingToFindMatches =>
      'Commencez à explorer pour créer des connexions !';

  @override
  String get step => 'Étape';

  @override
  String get stepOf => 'de';

  @override
  String get storiesAddCaptionHint => 'Ajouter une légende...';

  @override
  String get storiesCreateStory => 'Créer une story';

  @override
  String storiesDaysAgo(Object count) {
    return 'Il y a ${count}j';
  }

  @override
  String get storiesDisappearAfter24h =>
      'Votre story disparaîtra après 24 heures';

  @override
  String get storiesGallery => 'Galerie';

  @override
  String storiesHoursAgo(Object count) {
    return 'Il y a ${count}h';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return 'Il y a ${count}m';
  }

  @override
  String get storiesNoActive => 'Aucune story active';

  @override
  String get storiesNoStories => 'Aucune story disponible';

  @override
  String get storiesPhoto => 'Photo';

  @override
  String get storiesPost => 'Publier';

  @override
  String get storiesSendMessageHint => 'Envoyer un message...';

  @override
  String get storiesShareMoment => 'Partagez un moment';

  @override
  String get storiesVideo => 'Vidéo';

  @override
  String get storiesYourStory => 'Votre story';

  @override
  String get streakActiveToday => 'Actif aujourd\'hui';

  @override
  String get streakBonusHeader => 'Bonus de série !';

  @override
  String get streakInactive => 'Commencez votre série !';

  @override
  String get streakMessageIncredible => 'Dévouement incroyable !';

  @override
  String get streakMessageKeepItUp => 'Continuez comme ça !';

  @override
  String get streakMessageMomentum => 'L\'élan se construit !';

  @override
  String get streakMessageOneWeek => 'Cap d\'une semaine !';

  @override
  String get streakMessageTwoWeeks => 'Deux semaines de suite !';

  @override
  String get submitAnswer => 'Envoyer la Réponse';

  @override
  String get submitVerification => 'Soumettre pour Vérification';

  @override
  String submittedOn(String date) {
    return 'Soumis le $date';
  }

  @override
  String get subscribe => 'S\'abonner';

  @override
  String get subscribeNow => 'S\'abonner maintenant';

  @override
  String get subscriptionExpired => 'Abonnement expiré';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'Votre abonnement $tierName a expiré. Vous avez été rétrogradé au niveau Free.\n\nPassez à un niveau supérieur à tout moment pour retrouver vos fonctionnalités premium !';
  }

  @override
  String get suggestions => 'Suggestions';

  @override
  String get superLike => 'Connexion Prioritaire';

  @override
  String superLikedYou(String name) {
    return '$name s\'est connecté prioritairement avec vous !';
  }

  @override
  String get superLikes => 'Connexions Prioritaires';

  @override
  String get supportCenter => 'Centre d\'Aide';

  @override
  String get supportCenterSubtitle =>
      'Obtenir de l\'aide, signaler des problèmes, nous contacter';

  @override
  String get swipeIndicatorLike => 'CONNECTER';

  @override
  String get swipeIndicatorNope => 'PASSER';

  @override
  String get swipeIndicatorSkip => 'EXPLORER';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITAIRE';

  @override
  String get takePhoto => 'Prendre une Photo';

  @override
  String get takeVerificationPhoto => 'Prendre Photo de Vérification';

  @override
  String get tapToContinue => 'Appuyez pour continuer';

  @override
  String get targetLanguage => 'Langue Cible';

  @override
  String get termsAndConditions => 'Conditions Générales';

  @override
  String get thatsYourOwnProfile => 'C\'est votre propre profil !';

  @override
  String get thirdPartyDataDescription =>
      'Permettre le partage de données anonymisées avec des partenaires pour l\'amélioration du service';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get tierFree => 'Gratuit';

  @override
  String get timeRemaining => 'Temps restant';

  @override
  String get timeoutError => 'Délai d\'attente dépassé';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% au Niveau $level';
  }

  @override
  String get today => 'aujourd\'hui';

  @override
  String get totalXpLabel => 'XP Total';

  @override
  String get tourDiscoveryDescription =>
      'Parcourez les profils pour trouver des gens avec qui vous connecter. Glissez à droite pour vous connecter, à gauche pour passer.';

  @override
  String get tourDiscoveryTitle => 'Découvrir des gens';

  @override
  String get tourDone => 'Terminé';

  @override
  String get tourLearnDescription =>
      'Étudie le vocabulaire, la grammaire et les compétences de conversation';

  @override
  String get tourLearnTitle => 'Apprends les Langues';

  @override
  String get tourMatchesDescription =>
      'Voyez tous ceux qui se sont aussi connectés avec vous ! Lancez des conversations avec vos connexions mutuelles.';

  @override
  String get tourMatchesTitle => 'Vos connexions';

  @override
  String get tourMessagesDescription =>
      'Discutez ici avec vos connexions. Envoyez des messages, des photos et des notes vocales.';

  @override
  String get tourMessagesTitle => 'Messages';

  @override
  String get tourNext => 'Suivant';

  @override
  String get tourPlayDescription =>
      'Défie les autres dans des jeux de langues amusants';

  @override
  String get tourPlayTitle => 'Joue';

  @override
  String get tourProfileDescription =>
      'Personnalisez votre profil, gérez les paramètres et contrôlez votre vie privée.';

  @override
  String get tourProfileTitle => 'Votre Profil';

  @override
  String get tourProgressDescription =>
      'Gagnez des badges, complétez des défis et montez dans le classement !';

  @override
  String get tourProgressTitle => 'Suivez Vos Progrès';

  @override
  String get tourShopDescription =>
      'Obtenez des pièces et des fonctionnalités premium pour profiter pleinement de GreenGo.';

  @override
  String get tourShopTitle => 'Boutique et Pièces';

  @override
  String get tourSkip => 'Passer';

  @override
  String get trialWelcomeTitle => 'Bienvenue sur GreenGo !';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'Vous utilisez la version d\'essai. Votre abonnement de base gratuit est actif jusqu\'au $expirationDate. Profitez de GreenGo !';
  }

  @override
  String get trialWelcomeButton => 'Commencer';

  @override
  String get translateWord => 'Traduire ce mot';

  @override
  String get translationDownloadExplanation =>
      'Pour activer la traduction automatique des messages, nous devons télécharger les données linguistiques pour une utilisation hors ligne.';

  @override
  String get travelCategory => 'Voyage';

  @override
  String get travelLabel => 'Voyage';

  @override
  String get travelerAppearFor24Hours =>
      'Vous apparaîtrez dans les résultats de découverte de ce lieu pendant 24 heures.';

  @override
  String get travelerBadge => 'Voyageur';

  @override
  String get travelerChangeLocation => 'Changer de lieu';

  @override
  String get travelerConfirmLocation => 'Confirmer le lieu';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'Échec de la récupération du lieu : $error';
  }

  @override
  String get travelerGettingLocation => 'Récupération du lieu...';

  @override
  String travelerInCity(String city) {
    return 'A $city';
  }

  @override
  String get travelerLoadingAddress => 'Chargement de l\'adresse...';

  @override
  String get travelerLocationInfo =>
      'Vous apparaîtrez dans les résultats de découverte de cet emplacement pendant 24 heures.';

  @override
  String get travelerLocationPermissionsDenied =>
      'Permissions de localisation refusées';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Permissions de localisation définitivement refusées';

  @override
  String get travelerLocationServicesDisabled =>
      'Les services de localisation sont désactivés';

  @override
  String travelerModeActivated(String city) {
    return 'Mode voyageur activé ! Vous apparaissez à $city pendant 24 heures.';
  }

  @override
  String get travelerModeActive => 'Mode voyageur actif';

  @override
  String get travelerModeDeactivated =>
      'Mode voyageur désactivé. Retour à votre emplacement réel.';

  @override
  String get travelerModeDescription =>
      'Apparaissez dans le fil de découverte d\'une autre ville pendant 24 heures';

  @override
  String get travelerModeTitle => 'Mode Voyageur';

  @override
  String travelerNoResultsFor(Object query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Choisir sur la carte';

  @override
  String get travelerProfileAppearDescription =>
      'Votre profil apparaîtra dans le fil de découverte de ce lieu pendant 24 heures avec un badge Voyageur.';

  @override
  String get travelerSearchHint =>
      'Votre profil apparaîtra dans le fil de découverte de cet emplacement pendant 24 heures avec un badge Voyageur.';

  @override
  String get travelerSearchOrGps => 'Rechercher une ville ou utiliser le GPS';

  @override
  String get travelerSelectOnMap => 'Sélectionner sur la carte';

  @override
  String get travelerSelectThisLocation => 'Sélectionner ce lieu';

  @override
  String get travelerSelectTravelLocation => 'Sélectionner le lieu de voyage';

  @override
  String get travelerTapOnMap =>
      'Appuyez sur la carte pour sélectionner un lieu';

  @override
  String get travelerUseGps => 'Utiliser le GPS';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get tryDifferentSearchOrFilter =>
      'Essayez une recherche ou un filtre différent';

  @override
  String get twoFaDisabled => 'Authentification 2FA désactivée';

  @override
  String get twoFaEnabled => 'Authentification 2FA activée';

  @override
  String get twoFaToggleSubtitle =>
      'Exiger la vérification par code email à chaque connexion';

  @override
  String get twoFaToggleTitle => 'Activer l\'authentification 2FA';

  @override
  String get typeMessage => 'Tapez un message...';

  @override
  String get typeQuizzes => 'Quiz';

  @override
  String get typeStreak => 'Série';

  @override
  String typeWordStartingWith(String letter) {
    return 'Écris un mot commençant par \"$letter\"';
  }

  @override
  String get typeWordsLearned => 'Mots Appris';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'Impossible de charger le profil';

  @override
  String get unableToPlayVoiceIntro =>
      'Impossible de lire l\'introduction vocale';

  @override
  String get undoSwipe => 'Annuler le Swipe';

  @override
  String unitLabelN(String number) {
    return 'Unité $number';
  }

  @override
  String get unlimited => 'Illimité';

  @override
  String get unlock => 'Débloquer';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Débloquez $count profils supplémentaires en grille pour $cost pièces.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Voulez-vous vraiment supprimer votre connexion avec $name ? Cette action est irréversible.';
  }

  @override
  String get unmatchLabel => 'Supprimer la connexion';

  @override
  String unmatchedWith(String name) {
    return 'Vous n\'êtes plus connecté avec $name';
  }

  @override
  String get upgrade => 'Améliorer';

  @override
  String get upgradeForEarlyAccess =>
      'Passez à Argent, Or ou Platine pour un accès anticipé le 1er mars 2026!';

  @override
  String get upgradeNow => 'Améliorer maintenant';

  @override
  String get upgradeToPremium => 'Passer à Premium';

  @override
  String upgradeToTier(String tier) {
    return 'Passer à $tier';
  }

  @override
  String get uploadPhoto => 'Télécharger une Photo';

  @override
  String get uppercaseLowercase => 'Lettres majuscules et minuscules';

  @override
  String get useCurrentGpsLocation => 'Utiliser ma position GPS actuelle';

  @override
  String get usedToday => 'Utilisé aujourd\'hui';

  @override
  String get usedWords => 'Mots Utilisés';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName a été bloqué';
  }

  @override
  String get userBlockedTitle => 'Utilisateur bloqué !';

  @override
  String get userNotFound => 'Utilisateur non trouvé';

  @override
  String get usernameOrProfileUrl => 'Nom d\'utilisateur ou URL du profil';

  @override
  String get usernameWithoutAt => 'Nom d\'utilisateur (sans @)';

  @override
  String get verificationApproved => 'Vérification Approuvée';

  @override
  String get verificationApprovedMessage =>
      'Votre identité a été vérifiée. Vous avez maintenant un accès complet à l\'application.';

  @override
  String get verificationApprovedSuccess =>
      'Vérification approuvée avec succès';

  @override
  String get verificationDescription =>
      'Pour assurer la sécurité de notre communauté, nous demandons à tous les utilisateurs de vérifier leur identité. Prenez une photo de vous tenant votre pièce d\'identité.';

  @override
  String get verificationHistory => 'Historique des Vérifications';

  @override
  String get verificationInstructions =>
      'Tenez votre pièce d\'identité (passeport, permis de conduire ou carte d\'identité) à côté de votre visage et prenez une photo claire.';

  @override
  String get verificationNeedsResubmission => 'Meilleure Photo Requise';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Nous avons besoin d\'une photo plus claire pour la vérification. Veuillez renvoyer.';

  @override
  String get verificationPanel => 'Panneau de Vérification';

  @override
  String get verificationPending => 'Vérification en Cours';

  @override
  String get verificationPendingMessage =>
      'Votre compte est en cours de vérification. Cela prend généralement 24-48 heures. Vous serez notifié une fois la révision terminée.';

  @override
  String get verificationRejected => 'Vérification Refusée';

  @override
  String get verificationRejectedMessage =>
      'Votre vérification a été refusée. Veuillez soumettre une nouvelle photo.';

  @override
  String get verificationRejectedSuccess => 'Vérification refusée';

  @override
  String get verificationRequired => 'Vérification d\'Identité Requise';

  @override
  String get verificationSkipWarning =>
      'Vous pouvez parcourir l\'application, mais vous ne pourrez pas discuter ou voir d\'autres profils tant que vous n\'êtes pas vérifié.';

  @override
  String get verificationTip1 => 'Assurez-vous d\'avoir un bon éclairage';

  @override
  String get verificationTip2 =>
      'Votre visage et le document doivent être clairement visibles';

  @override
  String get verificationTip3 =>
      'Tenez le document à côté de votre visage, sans le couvrir';

  @override
  String get verificationTip4 => 'Le texte du document doit être lisible';

  @override
  String get verificationTips => 'Conseils pour une vérification réussie:';

  @override
  String get verificationTitle => 'Vérifiez Votre Identité';

  @override
  String get verificationPrivacyTitle =>
      'Vos données sont en sécurité avec nous';

  @override
  String get verificationPrivacyEncryption =>
      'Tous les documents sont protégés par un chiffrement de bout en bout. Même les ingénieurs de GreenGo ne peuvent pas accéder à vos données.';

  @override
  String get verificationPrivacyAccess =>
      'Vos informations ne peuvent être consultées que sur votre demande personnelle, via les canaux officiels ou par e-mail.';

  @override
  String get verificationPrivacySafety =>
      'Cette étape est essentielle pour protéger tous les membres. Nous vous invitons à signaler tout comportement suspect et à laisser GreenGo intervenir.';

  @override
  String get verificationPrivacyReporting =>
      'Si quelque chose se produit, signalez-le immédiatement. GreenGo enquêtera et agira pour préserver la sécurité de la communauté.';

  @override
  String get verificationChooseMethod =>
      'Choisissez votre méthode de vérification';

  @override
  String get verificationMethodPhoto => 'Pièce d\'identité';

  @override
  String get verificationMethodPhotoDesc =>
      'Prenez une photo en tenant votre pièce d\'identité à côté de votre visage';

  @override
  String get verificationMethodPhone => 'Numéro de téléphone';

  @override
  String get verificationMethodPhoneDesc =>
      'Vérifiez via un code SMS envoyé à votre téléphone';

  @override
  String get verificationPhoneTitle => 'Vérification par téléphone';

  @override
  String get verificationPhoneSubtitle =>
      'Saisissez votre numéro de téléphone pour recevoir un code de vérification par SMS';

  @override
  String get verificationPhoneLabel => 'Numéro de téléphone';

  @override
  String get verificationPhoneHint => '+33 6 12 34 56 78';

  @override
  String get verificationSendCode => 'Envoyer le code';

  @override
  String get verificationEnterCode =>
      'Saisissez le code à 6 chiffres envoyé à votre téléphone';

  @override
  String get verificationCodeLabel => 'Code de vérification';

  @override
  String get verificationVerifyCode => 'Vérifier le code';

  @override
  String get verificationPhoneSuccess =>
      'Numéro de téléphone vérifié avec succès !';

  @override
  String get verificationPhoneResponsibility =>
      'En vous vérifiant avec votre numéro de téléphone, vous reconnaissez que le titulaire de ce numéro est personnellement responsable de toutes les actions effectuées sur ce compte.';

  @override
  String get verificationResendCode => 'Renvoyer le code';

  @override
  String verificationCodeSent(String phoneNumber) {
    return 'Code envoyé au $phoneNumber';
  }

  @override
  String get verificationPhoneError =>
      'Échec de la vérification du numéro de téléphone. Veuillez réessayer.';

  @override
  String get verificationInvalidCode =>
      'Code invalide. Veuillez vérifier et réessayer.';

  @override
  String get verificationOr => 'ou';

  @override
  String get verifyNow => 'Vérifier Maintenant';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit tags sélectionnés';
  }

  @override
  String get vibeTagsGet5Tags => 'Obtenir 5 tags';

  @override
  String get vibeTagsGetAccessTo => 'Accédez à :';

  @override
  String get vibeTagsLimitReached => 'Limite de tags atteinte';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Les utilisateurs gratuits peuvent sélectionner jusqu\'à $limit tags. Passez à Premium pour 5 tags !';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'Vous avez atteint votre maximum de $limit tags. Supprimez-en un pour en ajouter un autre.';
  }

  @override
  String get vibeTagsNoTags => 'Aucun tag disponible';

  @override
  String get vibeTagsPremiumFeature1 => '5 tags vibe au lieu de 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Tags premium exclusifs';

  @override
  String get vibeTagsPremiumFeature3 =>
      'Priorité dans les résultats de recherche';

  @override
  String get vibeTagsPremiumFeature4 => 'Et bien plus encore !';

  @override
  String get vibeTagsRemoveTag => 'Supprimer le tag';

  @override
  String get vibeTagsSelectDescription =>
      'Sélectionnez les tags qui correspondent à votre humeur et vos intentions actuelles';

  @override
  String get vibeTagsSetTemporary => 'Définir comme tag temporaire (24h)';

  @override
  String get vibeTagsShowYourVibe => 'Montrez votre vibe';

  @override
  String get vibeTagsTemporaryDescription =>
      'Affichez cette vibe pendant les prochaines 24 heures';

  @override
  String get vibeTagsTemporaryTag => 'Tag temporaire (24h)';

  @override
  String get vibeTagsTitle => 'Votre vibe';

  @override
  String get vibeTagsUpgradeToPremium => 'Passer à Premium';

  @override
  String get vibeTagsViewPlans => 'Voir les forfaits';

  @override
  String get vibeTagsYourSelected => 'Vos tags sélectionnés';

  @override
  String get videoCallCategory => 'Appel Vidéo';

  @override
  String get view => 'Voir';

  @override
  String get viewAllChallenges => 'Voir Tous les Défis';

  @override
  String get viewAllLabel => 'Tout Voir';

  @override
  String get viewBadgesAchievementsLevel => 'Voir badges, succès et niveau';

  @override
  String get viewMyProfile => 'Voir Mon Profil';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'MEMBRE OR';

  @override
  String get vipPlatinumMember => 'PLATINE VIP';

  @override
  String get vipPremiumBenefitsActive => 'Avantages Premium Actifs';

  @override
  String get vipSilverMember => 'MEMBRE ARGENT';

  @override
  String get virtualGiftsAddMessageHint => 'Ajouter un message (optionnel)';

  @override
  String get voiceDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer votre présentation vocale ?';

  @override
  String get voiceDeleteRecording => 'Supprimer l\'Enregistrement';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'Échec du démarrage de l\'enregistrement : $error';
  }

  @override
  String get voiceMicPermissionDenied =>
      'L\'accès au microphone est nécessaire pour enregistrer votre présentation vocale';

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'Échec du téléversement de l\'enregistrement : $error';
  }

  @override
  String get voiceIntro => 'Présentation Vocale';

  @override
  String get voiceIntroSaved => 'Présentation vocale sauvegardée';

  @override
  String get voiceIntroShort => 'Intro vocale';

  @override
  String get voiceIntroduction => 'Introduction vocale';

  @override
  String get voiceIntroductionInfo =>
      'Les introductions vocales permettent aux autres de mieux vous connaître. Cette étape est facultative.';

  @override
  String get voiceIntroductionSubtitle =>
      'Enregistrez un court message vocal (facultatif)';

  @override
  String get voiceIntroductionTitle => 'Introduction vocale';

  @override
  String get voiceMicrophonePermissionRequired =>
      'L\'autorisation du microphone est requise';

  @override
  String get voiceMessageTooShort =>
      'Maintenez pour enregistrer, relâchez pour envoyer';

  @override
  String get voiceSlideToCancel => '‹ Glissez pour annuler';

  @override
  String get voiceReleaseToCancel => 'Relâchez pour annuler';

  @override
  String get voiceFailedToSend => 'Échec de l\'envoi du message vocal';

  @override
  String get voiceRecordAgain => 'Réenregistrer';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Enregistrez une courte présentation de $seconds secondes pour faire entendre votre personnalité.';
  }

  @override
  String get voiceRecorded => 'Voix enregistrée';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'Enregistrement... (max $maxDuration secondes)';
  }

  @override
  String get voiceRecordingReady => 'Enregistrement prêt';

  @override
  String get voiceRecordingSaved => 'Enregistrement sauvegardé';

  @override
  String get voiceRecordingTips => 'Conseils d\'Enregistrement';

  @override
  String get voiceSavedMessage => 'Votre introduction vocale a été mise à jour';

  @override
  String get voiceSavedTitle => 'Voix enregistrée !';

  @override
  String get voiceStandOutWithYourVoice => 'Démarquez-vous avec votre voix !';

  @override
  String get voiceTapToRecord => 'Appuyez pour enregistrer';

  @override
  String get voiceTipBeYourself => 'Soyez vous-même et naturel';

  @override
  String get voiceTipFindQuietPlace => 'Trouvez un endroit calme';

  @override
  String get voiceTipKeepItShort => 'Restez bref et concis';

  @override
  String get voiceTipShareWhatMakesYouUnique =>
      'Partagez ce qui vous rend unique';

  @override
  String get voiceUploadFailed =>
      'Échec du téléversement de l\'enregistrement vocal';

  @override
  String get voiceUploading => 'Téléversement...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic => 'Votre accès commencera le 15 mars 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'En tant que membre $tier, vous bénéficiez d\'un accès anticipé le 1er mars 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'Votre Date d\'Accès';

  @override
  String waitingCountLabel(String count) {
    return '$count en attente';
  }

  @override
  String get waitingCountdownLabel => 'Votre date de lancement';

  @override
  String get waitingCountdownSubtitle =>
      'Merci de vous être inscrit ! GreenGo Chat sera lancé bientôt. Préparez-vous pour une expérience exclusive.';

  @override
  String get waitingCountdownTitle => 'Compte à Rebours jusqu\'au Lancement';

  @override
  String waitingDaysRemaining(int days) {
    return '$days jours';
  }

  @override
  String get waitingEarlyAccessMember => 'Membre Accès Anticipé';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Activez les notifications pour être le premier à savoir quand vous pouvez accéder à l\'application.';

  @override
  String get waitingEnableNotificationsTitle => 'Restez informé';

  @override
  String get waitingExclusiveAccess =>
      'Temps restant avant de pouvoir utiliser l\'app';

  @override
  String get waitingGeneralLaunchDate => 'Date de lancement général';

  @override
  String get waitingYourAccessDate => 'Votre date d\'accès';

  @override
  String get waitingForPlayers => 'En attente des joueurs...';

  @override
  String get waitingForVerification => 'En attente de vérification...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours heures';
  }

  @override
  String get waitingMessageApproved =>
      'Bonne nouvelle! Votre compte a été approuvé. Vous pourrez accéder à GreenGoChat à la date indiquée ci-dessous.';

  @override
  String get waitingMessagePending =>
      'Votre compte est en attente d\'approbation par notre équipe. Nous vous informerons une fois que votre compte aura été examiné.';

  @override
  String get waitingMessageRejected =>
      'Malheureusement, votre compte n\'a pas pu être approuvé pour le moment. Veuillez contacter le support pour plus d\'informations.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get waitingNotificationEnabled =>
      'Notifications activées - nous vous préviendrons quand vous pourrez accéder à l\'application!';

  @override
  String get waitingProfileUnderReview => 'Profil en cours d\'examen';

  @override
  String get waitingReviewMessage =>
      'L\'application est maintenant en ligne ! Notre équipe examine votre profil pour garantir la meilleure expérience pour notre communauté. Cela prend généralement 24 à 48 heures.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds secondes';
  }

  @override
  String get waitingStayTuned =>
      'Restez à l\'écoute! Nous vous informerons quand il sera temps de commencer à vous connecter.';

  @override
  String get waitingStepActivation => 'Activation du compte';

  @override
  String get waitingStepRegistration => 'Inscription terminée';

  @override
  String get waitingStepReview => 'Examen du profil en cours';

  @override
  String get waitingSubtitle => 'Votre compte a été créé avec succès';

  @override
  String get waitingThankYouRegistration => 'Merci de vous être inscrit !';

  @override
  String get waitingTitle => 'Merci de Vous Être Inscrit!';

  @override
  String get weeklyChallengesTitle => 'Défis Hebdomadaires';

  @override
  String get weight => 'Poids';

  @override
  String get weightLabel => 'Poids';

  @override
  String get welcome => 'Bienvenue sur GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Mot déjà utilisé';

  @override
  String get wordReported => 'Mot signalé';

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
    return '$amount XP gagnés';
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
  String get yearlyMembership => 'Abonnement annuel';

  @override
  String yearsLabel(int age) {
    return '$age ans';
  }

  @override
  String get yes => 'Oui';

  @override
  String get yesterday => 'hier';

  @override
  String youAndMatched(String name) {
    return 'Vous et $name vous êtes aimés mutuellement';
  }

  @override
  String get youGotSuperLike => 'Vous avez reçu une Connexion Prioritaire !';

  @override
  String get youLabel => 'VOUS';

  @override
  String get youLose => 'Tu as Perdu';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Vous vous êtes connecté avec $name le $date';
  }

  @override
  String get youWin => 'Tu as Gagné !';

  @override
  String get yourLanguages => 'Vos Langues';

  @override
  String get yourRankLabel => 'Votre Rang';

  @override
  String get yourTurn => 'À Ton Tour !';

  @override
  String get achievementBadges => 'Badges de Réussite';

  @override
  String get achievementBadgesSubtitle =>
      'Appuyez pour sélectionner les badges à afficher sur votre profil (max 5)';

  @override
  String get noBadgesYet => 'Débloquez des succès pour gagner des badges !';

  @override
  String get guideTitle => 'Comment fonctionne GreenGo';

  @override
  String get guideSwipeTitle => 'Faire défiler les profils';

  @override
  String get guideSwipeItem1 =>
      'Glissez à droite pour Connect avec quelqu\'un, glissez à gauche pour Nope.';

  @override
  String get guideSwipeItem2 =>
      'Glissez vers le haut pour envoyer un Priority Connect (utilise des pièces).';

  @override
  String get guideSwipeItem3 =>
      'Glissez vers le bas pour Explore Next et passer un profil pour le moment.';

  @override
  String get guideSwipeItem4 =>
      'Vous pouvez basculer entre le mode glissement et le mode grille en utilisant l\'icône de basculement dans la barre supérieure.';

  @override
  String get guideGridTitle => 'Vue en grille';

  @override
  String get guideGridItem1 =>
      'Parcourez les profils dans une disposition en grille pour un aperçu rapide.';

  @override
  String get guideGridItem2 =>
      'Appuyez sur une image de profil pour afficher les quatre boutons d\'action : Connect, Priority Connect, Nope et Explore Next.';

  @override
  String get guideGridItem3 =>
      'Appuyez longuement sur une image de profil pour voir les détails sans ouvrir le profil complet.';

  @override
  String get guideConnectionsTitle => 'Se connecter avec les gens';

  @override
  String get guideConnectionsItem1 =>
      'Quand deux personnes font Connect mutuellement, c\'est une connexion !';

  @override
  String get guideConnectionsItem2 =>
      'Une fois connectés, vous pouvez commencer à discuter immédiatement.';

  @override
  String get guideConnectionsItem3 =>
      'Utilisez Priority Connect pour vous démarquer et augmenter vos chances.';

  @override
  String get guideConnectionsItem4 =>
      'Consultez l\'onglet Échanges pour voir toutes vos connexions et conversations.';

  @override
  String get guideChatTitle => 'Chat et messagerie';

  @override
  String get guideChatItem1 =>
      'Envoyez des messages texte, des photos et des notes vocales.';

  @override
  String get guideChatItem2 =>
      'Utilisez la fonction de traduction pour discuter dans différentes langues.';

  @override
  String get guideChatItem3 =>
      'Ouvrez les paramètres du chat pour personnaliser votre expérience : activez la vérification grammaticale, les réponses intelligentes, les conseils culturels, la décomposition des mots, l\'aide à la prononciation et plus encore.';

  @override
  String get guideChatItem4 =>
      'Activez la synthèse vocale pour écouter les traductions, afficher les drapeaux de langues et suivre vos XP d\'apprentissage des langues.';

  @override
  String get guideFiltersTitle => 'Filtres de découverte';

  @override
  String get guideFiltersItem1 =>
      'Appuyez sur l\'icône de filtre pour définir vos préférences : tranche d\'âge, distance, langues et plus encore.';

  @override
  String get guideFiltersItem2 =>
      'Mode Aléatoire : activez ce bouton pour découvrir des personnes aléatoires du monde entier. Chaque actualisation vous donne un nouveau groupe de profils. Lorsque le Mode Aléatoire est désactivé, seules les personnes proches de vous sont affichées. Vous pouvez également sélectionner des pays spécifiques pour affiner votre recherche.';

  @override
  String get guideFiltersItem3 =>
      'Les filtres vous aident à trouver des personnes qui correspondent à ce que vous recherchez. Vous pouvez les ajuster à tout moment.';

  @override
  String get guideTravelTitle => 'Voyage et exploration';

  @override
  String get guideTravelItem1 =>
      'Activez le mode Voyageur pour apparaître dans la découverte d\'une ville que vous prévoyez de visiter pendant 24 heures.';

  @override
  String get guideTravelItem2 =>
      'Les guides locaux peuvent aider les voyageurs à découvrir leur ville et leur culture.';

  @override
  String get guideTravelItem3 =>
      'Les partenaires d\'échange linguistique sont suggérés selon les langues que vous parlez et celles que vous voulez apprendre.';

  @override
  String get guideMembershipTitle => 'Abonnement de base';

  @override
  String get guideMembershipItem1 =>
      'Votre abonnement de base vous donne accès à toutes les fonctionnalités principales : swiper, discuter et vous connecter.';

  @override
  String get guideMembershipItem2 =>
      'L\'abonnement commence par un essai gratuit après votre première inscription.';

  @override
  String get guideMembershipItem3 =>
      'Lorsque votre abonnement expire, vous pouvez le renouveler pour continuer à utiliser l\'application.';

  @override
  String get guideTiersTitle => 'Niveaux VIP (Argent, Or, Platine)';

  @override
  String get guideTiersItem1 =>
      'Silver : Obtenez plus de connects quotidiens, voyez qui a fait Connect avec vous et un support prioritaire.';

  @override
  String get guideTiersItem2 =>
      'Gold : Tout ce qui est dans Silver plus des connects illimités, des filtres avancés et des accusés de lecture.';

  @override
  String get guideTiersItem3 =>
      'Platine : Tout ce qui est dans Or plus un boost de profil, les meilleurs choix et des fonctionnalités exclusives.';

  @override
  String get guideTiersItem4 =>
      'Les niveaux VIP sont indépendants de votre abonnement de base et offrent des avantages supplémentaires.';

  @override
  String get guideCoinsTitle => 'Pièces';

  @override
  String get guideCoinsItem1 =>
      'Les pièces sont utilisées pour les actions premium. Voici les coûts :';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect : 10 pièces  • Boost : 50 pièces  • Direct Connect : 2/jour gratuits, puis 50 pièces';

  @override
  String get guideCoinsItem3 =>
      '• Incognito : 30 pièces/jour  • Voyageur : 100 pièces/jour';

  @override
  String get guideCoinsItem4 =>
      '• Écouter (TTS) : 5 pièces  • Extension grille : 10 pièces  • Coach d\'apprentissage : 10 pièces/session';

  @override
  String get guideCoinsItem5 =>
      'Vous recevez 20 pièces gratuites par jour. Gagnez-en plus grâce aux succès, classements et la Boutique.';

  @override
  String get guideLeaderboardTitle => 'Classement';

  @override
  String get guideLeaderboardItem1 =>
      'Affrontez d\'autres utilisateurs pour grimper dans le classement et gagner des récompenses.';

  @override
  String get guideLeaderboardItem2 =>
      'Gagnez des points en étant actif, en complétant votre profil et en interagissant avec les autres.';

  @override
  String get guideGridFiltersTitle => 'Filtres de grille';

  @override
  String get guideGridFiltersItem1 =>
      'En mode grille, utilisez les puces de filtre en haut pour affiner les profils.';

  @override
  String get guideGridFiltersItem2 =>
      'Tous : Affiche tout le monde dans votre groupe de découverte.';

  @override
  String get guideGridFiltersItem3 =>
      'Connectés : Personnes à qui vous avez envoyé une demande de connexion.';

  @override
  String get guideGridFiltersItem4 =>
      'Prioritaire : Personnes à qui vous avez envoyé une Connexion Prioritaire.';

  @override
  String get guideGridFiltersItem5 =>
      'Refusés : Personnes que vous avez choisi de passer.';

  @override
  String get guideGridFiltersItem6 =>
      'Voyageurs : Personnes avec le Mode Voyageur actif, visitant une ville près de chez vous.';

  @override
  String get guideExchangesTitle => 'Échanges (Chat)';

  @override
  String get guideExchangesItem1 =>
      'Les Échanges regroupent toutes vos conversations. Vous les trouverez dans le menu inférieur.';

  @override
  String get guideExchangesItem2 =>
      'Le badge rouge sur l\'icône Échanges indique le nombre de conversations avec des messages non lus ou des approbations en attente.';

  @override
  String get guideExchangesItem3 =>
      'Utilisez les filtres pour organiser vos discussions : Toutes, Nouvelles, Sans réponse, Favoris, À approuver, Connexion et Recherche.';

  @override
  String get guideExchangesItem4 =>
      'Nouveau affiche les conversations avec de nouveaux messages non lus. Non répondu affiche les messages auxquels vous n\'avez pas encore répondu.';

  @override
  String get guideExchangesItem5 =>
      'À approuver affiche les demandes de Connexion Prioritaire en attente de votre décision. Acceptez ou refusez-les directement depuis la liste.';

  @override
  String get guideExchangesItem6 =>
      'Les conversations non lues sont mises en valeur avec du texte en gras et un effet doré scintillant pour les repérer facilement.';

  @override
  String get guideExchangesItem7 =>
      'Appuyez sur une conversation pour ouvrir le chat. Une fois ouverte, elle est marquée comme lue et le compteur du badge diminue.';

  @override
  String get guideExchangesItem8 =>
      'Appuyez longuement sur une conversation pour plus d\'options. Utilisez l\'icône étoile pour ajouter un chat à vos Favoris.';

  @override
  String get guideExchangesItem9 =>
      'Chaque conversation affiche les drapeaux de langue de l\'autre utilisateur, pour savoir quelles langues il parle.';

  @override
  String get guideGroupsTitle => 'Groupes (Culture Circles)';

  @override
  String get guideGroupsItem1 =>
      'Créez un groupe pour discuter avec plusieurs personnes à la fois autour d\'un intérêt ou d\'une langue en commun.';

  @override
  String get guideGroupsItem2 =>
      'Les administrateurs peuvent renommer le groupe, changer sa photo et ajouter ou retirer des membres.';

  @override
  String get guideGroupsItem3 =>
      'Invitez des personnes par leur pseudo depuis les infos du groupe.';

  @override
  String get guideGroupsItem4 =>
      'Ajoutez vos propres tags privés à un groupe dans les infos du groupe, puis filtrez votre liste de groupes par tag — vous seul voyez vos tags.';

  @override
  String get guideGroupsItem5 => 'Quittez ou signalez un groupe à tout moment.';

  @override
  String get guideEventsTitle => 'Événements';

  @override
  String get guideEventsItem1 =>
      'Découvrez des événements près de chez vous — fêtes, visites de musées, rencontres linguistiques et visites de la ville.';

  @override
  String get guideEventsItem2 =>
      'Parcourez des expériences et attractions sélectionnées, ou créez votre propre événement avec photos, lieu et date.';

  @override
  String get guideEventsItem3 =>
      'Marquez les événements comme Je participe ou Intéressé et retrouvez-les dans votre onglet Je participe.';

  @override
  String get guideEventsItem4 =>
      'Chaque événement a son propre chat ; les organisateurs peuvent diffuser des annonces à tous les participants.';

  @override
  String get guideEventsItem5 =>
      'Partagez n\'importe quel événement dans une conversation privée ou un groupe.';

  @override
  String get guideEventsItem6 =>
      'Explorez des événements du monde entier sur la carte, par lieu.';

  @override
  String get guideSafetyTitle => 'Sécurité et confidentialité';

  @override
  String get guideSafetyItem1 =>
      'Toutes les photos sont vérifiées par IA pour garantir des profils authentiques.';

  @override
  String get guideSafetyItem2 =>
      'Vous pouvez bloquer ou signaler n\'importe quel utilisateur à tout moment depuis son profil.';

  @override
  String get guideSafetyItem3 =>
      'Vos informations personnelles sont protégées et ne sont jamais partagées sans votre consentement.';

  @override
  String get firstStepsTitle => 'Premiers pas';

  @override
  String get firstStepsReview =>
      'Vos documents seront examinés sous 24 à 48 heures après leur envoi.';

  @override
  String get firstStepsStatusUpdate =>
      'L\'application a besoin d\'environ 15 minutes pour mettre à jour votre statut actuel après la première connexion.';

  @override
  String get firstStepsSupportChat =>
      'Vous pouvez contacter l\'assistance par chat ou en ouvrant un ticket directement.';

  @override
  String get showSupportUser => 'Afficher GreenGo Support';

  @override
  String get showSupportUserDescription =>
      'Afficher l\'utilisateur GreenGo Support dans la grille de découverte';

  @override
  String get preferenceShowMyNetwork => 'Mon Réseau';

  @override
  String get preferenceShowMyNetworkDesc =>
      'Afficher uniquement les personnes de votre reseau.';

  @override
  String get randomMode => 'Mode aléatoire';

  @override
  String get randomModeDescription =>
      'Découvrez des personnes au hasard du monde entier, triées par distance. Désactivé, seules les personnes proches de vous sont affichées.';

  @override
  String get yourProfile => 'Vous';

  @override
  String get loadingMsg1 =>
      'Recherche de profils incroyables à travers le monde...';

  @override
  String get loadingMsg2 =>
      'Nous connectons des gens de tous les continents...';

  @override
  String get loadingMsg3 =>
      'Découvrir des personnes incroyables près de chez vous...';

  @override
  String get loadingMsg4 => 'Préparation de vos suggestions personnalisées...';

  @override
  String get loadingMsg5 => 'Explorer des profils des quatre coins du monde...';

  @override
  String get loadingMsg6 =>
      'Trouver des personnes qui partagent vos intérêts...';

  @override
  String get loadingMsg7 => 'Configurer votre expérience de découverte...';

  @override
  String get loadingMsg8 => 'Charger de beaux profils rien que pour vous...';

  @override
  String get loadingMsg9 =>
      'Recherche de personnes qui partagent vos centres d\'intérêt...';

  @override
  String get loadingMsg10 => 'Rapprocher le monde de vous...';

  @override
  String get loadingMsg11 =>
      'Sélectionner des profils selon vos préférences...';

  @override
  String get loadingMsg12 =>
      'Presque prêt ! Les bonnes choses prennent un moment...';

  @override
  String get loadingMsg13 => 'Vous connecter à un monde de possibilités...';

  @override
  String get loadingMsg14 =>
      'Recherche de personnes géniales près de chez vous...';

  @override
  String get loadingMsg15 =>
      'Débloquer de nouvelles connexions autour de vous...';

  @override
  String get loadingMsg16 =>
      'Votre prochaine grande conversation n\'est qu\'un swipe...';

  @override
  String get loadingMsg17 => 'Rassembler des profils du monde entier...';

  @override
  String get loadingMsg18 => 'Préparer quelque chose de spécial pour vous...';

  @override
  String get loadingMsg19 => 'S\'assurer que tout est parfait...';

  @override
  String get loadingMsg20 =>
      'La curiosité n\'a pas de frontières, et nous non plus...';

  @override
  String get loadingMsg21 => 'Réchauffer votre fil de découverte...';

  @override
  String get loadingMsg22 =>
      'Scanner le globe à la recherche de personnes intéressantes...';

  @override
  String get loadingMsg23 => 'Les grandes connexions commencent ici...';

  @override
  String get loadingMsg24 => 'Votre aventure est sur le point de commencer...';

  @override
  String get filterFavorites => 'Favoris';

  @override
  String get filterToApprove => 'À approuver';

  @override
  String get priorityConnectAccept => 'Accepter';

  @override
  String get priorityConnectReject => 'Refuser';

  @override
  String get priorityConnectPending => 'En attente d\'approbation';

  @override
  String get membershipTrialTitle => 'Commencez votre essai gratuit !';

  @override
  String get membershipTrialSubtitle =>
      '7 jours gratuits, puis renouvellement annuel';

  @override
  String get membershipTrialFeature1 =>
      'Creez communautes, evenements et groupes illimites';

  @override
  String get membershipTrialFeature2 => 'Sans publicite — aucune annonce';

  @override
  String get membershipTrialFeature3 =>
      '500 pieces bonus + acces complet a tout';

  @override
  String get membershipHaveCoupon => 'Vous avez un code promo ?';

  @override
  String get membershipTrialCta => 'Démarrer l\'essai de 7 jours';

  @override
  String get membershipTrialFooter =>
      'Annulez à tout moment. Aucun frais avant le jour 8.';

  @override
  String get membershipTrialBadge => 'GRATUIT PENDANT 7 JOURS';

  @override
  String get globeMyNetwork => 'Mon réseau';

  @override
  String get globeMyWorldMap => 'Ma carte du monde';

  @override
  String get globeLayerContacts => 'Ma communauté';

  @override
  String get globeLayerExperiences => 'Expériences';

  @override
  String get globeYou => 'Vous';

  @override
  String get globeConnections => 'Connexions';

  @override
  String get globeTraveler => 'Voyageur';

  @override
  String globeConnectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'connexions',
      one: 'connexion',
    );
    return '$count $_temp0';
  }

  @override
  String globeConnectionsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'connexions',
      one: 'connexion',
    );
    return '$count $_temp0 ici';
  }

  @override
  String get globeThisIsYou => 'C\'est vous !';

  @override
  String globeTravelingTo(String country) {
    return 'En voyage vers $country';
  }

  @override
  String globeNoConnectionsInCountry(String country) {
    return 'Pas encore de connexions dans $country';
  }

  @override
  String get globeNoConnectionsHint =>
      'Continuez à vous connecter pour trouver des personnes ici !';

  @override
  String get globeProfile => 'Profil';

  @override
  String get globeChat => 'Chat';

  @override
  String get globeViewProfileTooltip => 'Voir le profil';

  @override
  String get globeOpenChatTooltip => 'Ouvrir le chat';

  @override
  String globeNoConnectionsInCountryTitle(String country) {
    return 'Aucune connexion dans $country';
  }

  @override
  String get discoverabilityExact => 'Exacte';

  @override
  String get discoverabilityExactDesc =>
      'Épingle à votre position exacte (< 1 km)';

  @override
  String get discoverabilityApproximate => 'Approximative';

  @override
  String get discoverabilityApproximateDesc =>
      'Épingle dans votre région (grille ~50 km, par défaut)';

  @override
  String get discoverabilityCountry => 'Pays';

  @override
  String get discoverabilityCountryDesc =>
      'Épingle quelque part dans votre pays';

  @override
  String get discoverabilityHidden => 'Masquée';

  @override
  String get discoverabilityHiddenDesc => 'Non visible sur la carte';

  @override
  String get discoverabilityTitle => 'Visibilité sur le globe';

  @override
  String get discoverabilityInfo =>
      'Vos connexions vous voient toujours sur la carte, quel que soit ce paramètre.';

  @override
  String get discoverabilityChangedExact => 'Position définie sur exacte';

  @override
  String get discoverabilityChangedApproximate =>
      'Position définie sur approximative';

  @override
  String get discoverabilityChangedCountry =>
      'Position définie au niveau du pays';

  @override
  String get discoverabilityChangedHidden =>
      'Vous êtes désormais masqué sur la carte';

  @override
  String get onboardingExitTitle => 'Quitter l\'inscription ?';

  @override
  String get onboardingExitMessage =>
      'Vous serez déconnecté. Vous pourrez terminer la configuration de votre profil à votre prochaine connexion.';

  @override
  String get onboardingExitConfirm => 'Se déconnecter';

  @override
  String get onboardingExitCancel => 'Annuler';

  @override
  String get loginEmailOrNickname => 'E-mail / Pseudo';

  @override
  String get paymentVerifying => 'Vérification de votre paiement...';

  @override
  String get paymentSuccess => 'Paiement réussi !';

  @override
  String get paymentSuccessMessage =>
      'Votre achat a été crédité sur votre compte.';

  @override
  String get paymentPending => 'Traitement du paiement';

  @override
  String get paymentPendingMessage =>
      'Votre paiement est en cours de traitement. Cela peut prendre quelques minutes.';

  @override
  String get paymentCancelled => 'Paiement annulé';

  @override
  String get paymentCancelledMessage =>
      'Votre paiement a été annulé. Aucun frais n\'a été prélevé.';

  @override
  String get continueToApp => 'Continuer';

  @override
  String get webCheckoutOpening => 'Ouverture du paiement sécurisé…';

  @override
  String get webCheckoutWaiting =>
      'Terminez votre paiement dans le nouvel onglet. Cette fenêtre se mettra à jour automatiquement une fois terminé.';

  @override
  String get webCheckoutTimeout =>
      'Nous n\'avons pas encore pu confirmer votre paiement. Si vous l\'avez effectué, votre solde sera mis à jour sous peu.';

  @override
  String get webCheckoutFailed =>
      'Impossible de démarrer le paiement. Veuillez réessayer.';

  @override
  String get groupNewGroup => 'Nouveau groupe';

  @override
  String get groupCreate => 'Créer';

  @override
  String get groupNameLabel => 'Nom du groupe';

  @override
  String groupSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get groupInviteByNickname => 'Inviter par pseudo';

  @override
  String get groupAddMembers => 'Ajouter des membres';

  @override
  String get groupTtsReadTranslated => 'Lire la traduction à voix haute';

  @override
  String get groupTtsReadTranslatedHint =>
      'Double-tapez un message pour l’écouter. Activé = votre langue, Désactivé = original.';

  @override
  String get ttsNotEnoughCoins =>
      'Pas assez de pièces pour le TTS (5 pièces requises)';

  @override
  String get groupRemoveMember => 'Retirer le membre';

  @override
  String groupRemoveMemberConfirm(String name) {
    return 'Retirer $name de ce groupe ?';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name retiré';
  }

  @override
  String groupAddSelected(int count) {
    return 'Ajouter $count sélectionnés';
  }

  @override
  String get groupNicknameHint => 'Saisir un pseudo';

  @override
  String get groupNoContacts => 'Aucun contact à ajouter pour l\'instant';

  @override
  String get groupNoOneFound => 'Aucun utilisateur trouvé avec ce pseudo';

  @override
  String get groupAlreadyAdded => 'Déjà ajouté';

  @override
  String groupAddedCount(int count) {
    return '$count ajouté(s)';
  }

  @override
  String get groupSearchFailed => 'Échec de la recherche';

  @override
  String get groupInfo => 'Infos du groupe';

  @override
  String groupMembersCount(int count) {
    return '$count membres';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupYou => 'Vous';

  @override
  String get groupLeave => 'Quitter le groupe';

  @override
  String get groupDelete => 'Supprimer le groupe';

  @override
  String get groupDeleteConfirmTitle => 'Supprimer le groupe ?';

  @override
  String get groupDeleteConfirmBody =>
      'Cela supprime definitivement le groupe et tous ses messages pour tout le monde. Action irreversible.';

  @override
  String get groupLeaveConfirmTitle => 'Quitter le groupe ?';

  @override
  String get groupLeaveConfirmBody =>
      'Vous ne recevrez plus les messages de ce groupe.';

  @override
  String get groupCancel => 'Annuler';

  @override
  String get groupLeaveAction => 'Quitter';

  @override
  String get groupReport => 'Signaler le groupe';

  @override
  String get groupReportConfirmBody =>
      'Signaler ce groupe à notre équipe de sécurité ?';

  @override
  String get groupReportAction => 'Signaler';

  @override
  String get groupReportSubmitted => 'Signalement envoyé';

  @override
  String get groupMessageHint => 'Message…';

  @override
  String get groupSayHello => 'Dites bonjour au groupe 👋';

  @override
  String get groupLoadError => 'Impossible de charger ce groupe';

  @override
  String get chatLocation => 'Position';

  @override
  String get chatShareLocation => 'Partager la position';

  @override
  String get chatLocationDenied =>
      'L\'autorisation de localisation est requise pour partager votre position';

  @override
  String get chatOpenInMaps => 'Ouvrir dans Maps';

  @override
  String get eventsSearchHint => 'Rechercher par pays, ville ou nom';

  @override
  String get eventsSortPopular => 'Populaire';

  @override
  String get eventsViewList => 'Vue liste';

  @override
  String get eventsViewGrid => 'Vue grille';

  @override
  String get eventViewEvent => 'Voir l\'événement';

  @override
  String get eventLoadError => 'Impossible de charger cet événement';

  @override
  String get eventShare => 'Partager l\'événement';

  @override
  String get eventReport => 'Signaler l\'événement';

  @override
  String get eventReportTitle => 'Signaler cet événement ?';

  @override
  String get eventReportBody =>
      'Notre équipe l\'examinera. Tu ne verras plus cet événement.';

  @override
  String get eventReported => 'Événement signalé';

  @override
  String get shareAsLink => 'Partager le lien';

  @override
  String get eventShared => 'Événement partagé';

  @override
  String get eventShareEmpty =>
      'Aucun chat ou groupe pour partager pour l\'instant';

  @override
  String get eventsUnlimitedAttendees => 'Participants illimités';

  @override
  String get eventsPrivateEvent => 'Événement privé';

  @override
  String get eventsExternalLinks => 'Liens';

  @override
  String get eventsLinkUrlHint => 'https://…';

  @override
  String get eventsAddLink => 'Ajouter un lien';

  @override
  String get tierLimitTitle => 'Améliorez votre offre pour en créer plus';

  @override
  String tierLimitEventsBody(int max) {
    return 'Votre offre autorise $max événements. Améliorez-la pour en créer plus.';
  }

  @override
  String tierLimitGroupsBody(int max) {
    return 'Votre offre autorise $max groupes. Améliorez-la pour en créer plus.';
  }

  @override
  String get groupsTitle => 'Groupes';

  @override
  String get profileRankingSubtitle => 'Voir le classement mondial';

  @override
  String get eventBroadcastTooltip => 'Diffuser à tous';

  @override
  String get eventBroadcastHint => 'Annonce à tous les participants…';

  @override
  String get eventBroadcastLabel => 'Annonce';

  @override
  String get eventsFeatured => 'À la une';

  @override
  String get eventsInsufficientCoins => 'Pas assez de pièces';

  @override
  String get eventsConfirmAction => 'Confirmer';

  @override
  String get eventsBoost => 'Booster';

  @override
  String get eventsBoosted => 'Événement mis en avant !';

  @override
  String eventsJoinForCoins(int cost) {
    return 'Rejoindre cet événement pour $cost pièces ?';
  }

  @override
  String eventsBoostConfirm(int cost) {
    return 'Mettre cet événement en avant pour $cost pièces pendant 7 jours ?';
  }

  @override
  String groupMemberLimit(int count) {
    return 'Jusqu\'à $count membres par groupe';
  }

  @override
  String get eventsPriceHint => 'Prix (1–1000)';

  @override
  String get eventsPriceRange => 'Entrez un prix entre 1 et 1000';

  @override
  String get eventsLinkLabelHint => 'Libellé (facultatif)';

  @override
  String get eventsPickLocation => 'Choisir le lieu';

  @override
  String get eventsSearchAddress => 'Rechercher une adresse';

  @override
  String get eventsUseThisLocation => 'Utiliser ce lieu';

  @override
  String get eventsEditEvent => 'Modifier l\'événement';

  @override
  String get groupEditName => 'Modifier le nom du groupe';

  @override
  String get groupChangePhoto => 'Changer la photo du groupe';

  @override
  String get groupUploadingPhoto => 'Téléversement de la photo…';

  @override
  String get groupPhotoUpdated => 'Photo du groupe mise à jour';

  @override
  String get groupPhotoUpdateFailed =>
      'Échec de la mise à jour de la photo du groupe';

  @override
  String get eventTextProhibited =>
      'Le titre ou la description contient un langage interdit et ne peut pas être utilisé';

  @override
  String get groupSearchHint => 'Rechercher des groupes';

  @override
  String get groupNoSearchResults => 'Aucun groupe trouvé';

  @override
  String get groupMyTags => 'Mes tags';

  @override
  String get groupMyTagsSubtitle => 'Privé — vous seul pouvez les voir';

  @override
  String get groupNoTagsYet => 'Aucun tag pour l\'instant';

  @override
  String get groupTagsEditTitle => 'Modifier mes tags';

  @override
  String get groupAddTagHint => 'Ajouter un tag';

  @override
  String get groupTagsSave => 'Enregistrer';

  @override
  String get groupTagsSaved => 'Tags enregistrés';

  @override
  String get groupTagsSaveFailed => 'Impossible d\'enregistrer les tags';

  @override
  String get groupTagsLimitReached => 'Limite de tags atteinte';

  @override
  String peopleTagsEditTitle(String name) {
    return 'Tags pour $name';
  }

  @override
  String get groupTranslationSettings => 'Traduction';

  @override
  String get groupTranslateMessages => 'Traduire les messages';

  @override
  String get groupShowOriginal => 'Afficher le texte original';

  @override
  String get eventsTabLiveEvents => 'Événements live';

  @override
  String get globeLayerLiveEvents => 'Événements live';

  @override
  String get eventsSortBy => 'Trier par';

  @override
  String get eventsSortDistance => 'Distance';

  @override
  String get eventsSortStars => 'Étoiles';

  @override
  String get eventsSortReviews => 'Avis';

  @override
  String get eventsSortDate => 'Date';

  @override
  String get catMuseums => 'Musées';

  @override
  String get catSights => 'Sites';

  @override
  String get catParks => 'Parcs';

  @override
  String get catNationalParks => 'Parcs nationaux';

  @override
  String get catThemeParks => 'Parcs d\'attractions';

  @override
  String get catTours => 'Visites & circuits';

  @override
  String get catCulture => 'Culture & musées';

  @override
  String get catFoodDrink => 'Gastronomie';

  @override
  String get catCruises => 'Croisières & eau';

  @override
  String get catNature => 'Nature & plein air';

  @override
  String get catDayTrips => 'Excursions à la journée';

  @override
  String get catTickets => 'Billets & pass';

  @override
  String get catOther => 'Autres';

  @override
  String get eventsUnlimited => 'Illimité';

  @override
  String get eventsTabGoing => 'Je participe';

  @override
  String get globeLayerCommunityEvents => 'Événements de la communauté';

  @override
  String get webMapUnavailableTitle =>
      'Carte interactive disponible sur l\'application mobile';

  @override
  String get webMapUnavailableBody =>
      'Recherchez une adresse pour définir votre position.';

  @override
  String get webLocationPickerTitle => 'Choisissez votre position';

  @override
  String get webLocationSearchHint => 'Rechercher une ville ou une adresse';

  @override
  String get webLocationConfirm => 'Utiliser cette position';

  @override
  String get webLocationTapHint => 'Touchez la carte pour placer un repère';

  @override
  String webLocationMonthlyLimit(String date) {
    return 'Vous pouvez mettre à jour votre position une fois par mois sur le web. Prochaine mise à jour disponible le $date.';
  }

  @override
  String get eventMyTicket => 'Mon billet';

  @override
  String get eventTicketDelete => 'Supprimer le billet';

  @override
  String get eventTicketDeleteConfirm =>
      'Supprimer definitivement ce billet ? L evenement est termine.';

  @override
  String get eventScanCheckIn => 'Scanner / Enregistrement';

  @override
  String get eventScanUseMobileApp =>
      'Le scan du QR code pour l\'enregistrement est disponible dans l\'application mobile GreenGo.';

  @override
  String get eventScanManageScanners => 'Gérer les scanners';

  @override
  String get eventScanInviteScannerHint =>
      'Invitez un membre à scanner les billets à l\'entrée.';

  @override
  String get eventScanNicknameHint => 'Pseudo';

  @override
  String get eventScanAddScanner => 'Ajouter';

  @override
  String get eventScanScannerNotFound => 'Aucun membre trouvé avec ce pseudo';

  @override
  String get eventScanScannerAddFailed =>
      'Impossible d\'ajouter le scanner. Réessayez.';

  @override
  String eventScanScannerAdded(String name) {
    return '$name peut maintenant scanner les billets';
  }

  @override
  String get eventAttendance => 'Présence';

  @override
  String get eventCheckedIn => 'Enregistré';

  @override
  String get eventNotCheckedIn => 'Pas encore là';

  @override
  String get eventGuestsAllowedLabel => 'Invités autorisés par participant';

  @override
  String get eventBringGuests => 'Amener des invités';

  @override
  String get eventInvalidTicket => 'Billet invalide pour cet événement';

  @override
  String get eventScanInstructions =>
      'Pointe la caméra vers le QR code d\'un participant';

  @override
  String get eventTotalHeadcount => 'Nombre total de participants';

  @override
  String get eventCameraPermission =>
      'L\'autorisation de la caméra est requise pour scanner';

  @override
  String get eventTicketSubtitle => 'Présente ce QR à l\'entrée';

  @override
  String eventGuestCount(int count, int max) {
    return '$count sur $max invités';
  }

  @override
  String eventCheckedInSuccess(String name) {
    return '$name enregistré';
  }

  @override
  String eventAlreadyCheckedIn(String name) {
    return '$name déjà enregistré';
  }

  @override
  String eventGuestsBringing(int count) {
    return '+$count invités';
  }

  @override
  String connectDailyLimitReached(int limit) {
    return 'Tu as atteint ta limite quotidienne de $limit nouvelles connexions. Passe à une offre supérieure pour te connecter avec plus de personnes !';
  }

  @override
  String get boostFeatureName => 'Boost de profil';

  @override
  String get boostRequiresTierDescription =>
      'Les boosts de profil sont un avantage réservé aux membres payants. Améliore ton offre pour booster ton profil et être vu par plus de personnes.';

  @override
  String boostMonthlyLimitReached(int limit) {
    return 'Tu as utilisé les $limit boosts de profil inclus dans ton offre ce mois-ci. Améliore ton offre pour en obtenir plus.';
  }

  @override
  String get travelModeFeatureName => 'Mode Voyageur';

  @override
  String get travelModeRequiresTierDescription =>
      'Le mode Voyageur te permet d\'apparaître dans le fil Découverte d\'une autre ville. Améliore ton offre pour le débloquer.';

  @override
  String get exploreRecommended => 'Recommandé pour toi';

  @override
  String get businessAccountTitle => 'Compte professionnel';

  @override
  String get becomeBusiness => 'Devenir professionnel';

  @override
  String get businessProfileLabel => 'Profil professionnel';

  @override
  String get businessCategoryLabel => 'Catégorie professionnelle';

  @override
  String get businessCategoryHint => 'Sélectionnez une catégorie';

  @override
  String get businessVerifiedLabel => 'Entreprise vérifiée';

  @override
  String get featureThisEvent => 'Mettre cet événement en avant';

  @override
  String featureEventCostLabel(int cost) {
    return 'Mettre cet événement en avant · $cost pièces';
  }

  @override
  String featureEventActive(String date) {
    return 'En avant jusqu\'au $date';
  }

  @override
  String featureEventConfirm(int cost) {
    return 'Mettre cet événement en avant pour $cost pièces ?';
  }

  @override
  String get referralTitle => 'Inviter des amis';

  @override
  String get referralInviteFriends => 'Inviter des amis';

  @override
  String get referralYourCode => 'Ton code de parrainage';

  @override
  String get referralShareCta => 'Partager';

  @override
  String get referralShareMessage => 'Rejoins-moi sur GreenGo !';

  @override
  String get referralRewardEarned => 'Pièces gagnées';

  @override
  String get referralCountLabel => 'Amis invités';

  @override
  String referralHowItWorks(int coins, int monthlyCap) {
    final intl.NumberFormat coinsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String coinsString = coinsNumberFormat.format(coins);
    final intl.NumberFormat monthlyCapNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthlyCapString = monthlyCapNumberFormat.format(monthlyCap);

    return 'Partage ton code — quand un ami s\'inscrit avec, tu gagnes $coinsString pièces (jusqu\'à $monthlyCapString par mois) et il reçoit 1 mois de Platinum.';
  }

  @override
  String get referralHowItWorksTitle => 'Comment ça marche';

  @override
  String get achievementsLoadError => 'Impossible de charger les réalisations';

  @override
  String get loadErrorCheckConnection => 'Vérifie ta connexion et réessaie.';

  @override
  String get streakTitle => 'Série';

  @override
  String get streakDaysLabel => 'jours de série';

  @override
  String get streakKeepGoing => 'Continue comme ça !';

  @override
  String get missionsTitle => 'Missions';

  @override
  String get missionsSubtitle =>
      'Accomplis des missions pour gagner des pièces';

  @override
  String get missionProgressLabel => 'Progression';

  @override
  String get missionRewardLabel => 'Récompense';

  @override
  String get missionCompleteLabel => 'Terminé';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue sur GreenGo';

  @override
  String get onboardingWelcomeBody =>
      'Découvre des cultures, pratique des langues, trouve des événements locaux et rencontre des personnes près de toi — sans barrière de langue.';

  @override
  String get onboardingPickInterests => 'Qu\'est-ce qui vous intéresse ?';

  @override
  String get onboardingPickLanguages => 'Langues que tu parles';

  @override
  String get savedSearchesTitle => 'Recherches enregistrées';

  @override
  String get saveThisSearch => 'Enregistrer cette recherche';

  @override
  String get savedSearchSaved => 'Recherche enregistrée';

  @override
  String get savedSearchRun => 'Lancer';

  @override
  String get savedSearchEmpty => 'Aucune recherche enregistrée pour l\'instant';

  @override
  String get savedSearchAlertsToggle => 'Alertes';

  @override
  String get exploreFeaturedCommunity => 'Événements communautaires à la une';

  @override
  String get notificationMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationsDeleteUnread => 'Supprimer les non lues';

  @override
  String get notificationsDeleteAll => 'Tout supprimer';

  @override
  String get notificationsDeleteAllConfirm =>
      'Supprimer definitivement toutes les notifications de cette page ? Cette action est irreversible.';

  @override
  String get notificationsDeleteUnreadConfirm =>
      'Supprimer definitivement toutes les notifications non lues ? Cette action est irreversible.';

  @override
  String get analyticsTitle => 'Statistiques';

  @override
  String get analyticsPlatinumOnly =>
      'Les statistiques sont une fonctionnalité Platinum.';

  @override
  String get analyticsEventsHosted => 'Événements organisés';

  @override
  String get analyticsTotalAttendees => 'Total des participants';

  @override
  String get analyticsReach => 'Portée';

  @override
  String get analyticsUpgradeCta => 'Passer à Platinum';

  @override
  String get safetyVerifiedBadge => 'Vérifié';

  @override
  String get safetyReportUser => 'Signaler';

  @override
  String get safetyBlockUser => 'Bloquer';

  @override
  String get safetyCheckInTitle => 'Contrôle de sécurité';

  @override
  String get safetyCheckInArrived => 'Je suis bien arrivé';

  @override
  String get safetyCheckInDone => 'Tu t\'es enregistré en toute sécurité';

  @override
  String get guidelinesTitle => 'Règles de la communauté';

  @override
  String get guidelinesAccept => 'J\'accepte';

  @override
  String get guidelinesBody =>
      'GreenGo est une communauté interculturelle dédiée à la découverte, à l\'échange linguistique, aux événements locaux et à l\'amitié. Sois respectueux et accueillant envers les personnes de toutes les cultures. Ce n\'est pas une application de rencontres. Aucun harcèlement, discours haineux, spam ou contenu explicite. Signale tout ce qui n\'a pas sa place.';

  @override
  String get businessSectionTitle => 'Professionnel';

  @override
  String get businessSectionSubtitle => 'Des outils pour ton entreprise';

  @override
  String get businessHubAccount => 'Compte professionnel';

  @override
  String get businessHubAnalytics => 'Statistiques';

  @override
  String get businessHubFeatured => 'Emplacements en avant';

  @override
  String get becomeBusinessAction => 'En devenir un';

  @override
  String get becomeBusinessConfirmTitle => 'Devenir un compte professionnel ?';

  @override
  String get becomeBusinessConfirmMessage =>
      'C\'est définitif : ton compte devient un compte professionnel public et ne peut pas redevenir un compte personnel. Les outils professionnels fonctionnent tant que ton abonnement Platinum est actif ; s\'il expire, ils sont mis en pause jusqu\'au renouvellement.';

  @override
  String get becomeBusinessConfirmAction => 'Rendre permanent';

  @override
  String get becomeBusinessSuccess =>
      'Ton compte est désormais un compte professionnel.';

  @override
  String get becomeBusinessError =>
      'Impossible de changer ton compte. Veuillez réessayer.';

  @override
  String get businessAccountActive => 'Compte professionnel actif (permanent)';

  @override
  String get businessRequiresPlatinum =>
      'Les comptes professionnels sont une fonctionnalité Platinum. Améliore ton offre pour débloquer ta vitrine, tes abonnés et la capture de prospects.';

  @override
  String get viewStorefront => 'Voir la vitrine';

  @override
  String get requestVerification => 'Demander la vérification';

  @override
  String get requestVerificationPending => 'Vérification en attente';

  @override
  String get requestVerificationTitle => 'Demander la vérification';

  @override
  String get verifyBusinessNameLabel => 'Nom de l\'entreprise';

  @override
  String get verifyLegalNameLabel => 'Nom légal';

  @override
  String get verifyLegalNameHint => 'Nom légal enregistré';

  @override
  String get verifyPhoneLabel => 'Numéro de téléphone';

  @override
  String get verifyPhoneHint => '+33 6 12 34 56 78';

  @override
  String get verifyPhoneFormatError =>
      'Saisissez votre numero au format international, ex. +33612345678';

  @override
  String get verifySendCode => 'Envoyer le code';

  @override
  String get verifyResendCode => 'Renvoyer';

  @override
  String get verifyEnterCodeLabel => 'Code à 6 chiffres';

  @override
  String get verifyConfirmCode => 'Vérifier';

  @override
  String get verifyPhoneVerified => 'Téléphone vérifié';

  @override
  String get verifyOwnerDocumentLabel => 'Pièce d\'identité du propriétaire';

  @override
  String get verifyUploadDocument => 'Téléverser le document';

  @override
  String get verifyDocumentUploaded => 'Document téléversé';

  @override
  String get verifyDocumentUploadError =>
      'Impossible de téléverser le document. Veuillez réessayer.';

  @override
  String get verifyWebsiteLabel => 'Site web (facultatif)';

  @override
  String get verifyWebsiteHint => 'https://exemple.com';

  @override
  String get verifyNotesLabel => 'Notes (facultatif)';

  @override
  String get verifyMissingFields =>
      'Veuillez remplir tous les champs obligatoires et vérifier votre téléphone.';

  @override
  String get requestVerificationMessage =>
      'Parle-nous un peu de ton entreprise afin que nous puissions la vérifier. Notre équipe examinera ta demande.';

  @override
  String get requestVerificationNoteHint =>
      'Ajoute une note (site web, adresse, tout ce qui nous aide à te vérifier)';

  @override
  String get requestVerificationSubmitted => 'Demande de vérification envoyée.';

  @override
  String get requestVerificationError =>
      'Impossible d\'envoyer ta demande. Veuillez réessayer.';

  @override
  String get submit => 'Envoyer';

  @override
  String get businessVerifiedBadgeTooltip => 'Entreprise vérifiée';

  @override
  String get businessLinks => 'Liens';

  @override
  String get businessOpeningHours => 'Horaires d\'ouverture';

  @override
  String get businessHoursNotProvided => 'Horaires d\'ouverture non fournis';

  @override
  String get businessGallery => 'Galerie';

  @override
  String get businessUpcomingEvents => 'Événements à venir';

  @override
  String get businessNoUpcomingEvents =>
      'Aucun événement à venir pour l\'instant.';

  @override
  String get businessCommunities => 'Communautés';

  @override
  String get businessNoCommunities => 'Aucune communauté pour l\'instant.';

  @override
  String get businessContact => 'Contact';

  @override
  String get businessFollow => 'Suivre';

  @override
  String get businessFollowing => 'Abonné';

  @override
  String get businessFollowError =>
      'Impossible de mettre à jour l\'abonnement. Veuillez réessayer.';

  @override
  String businessFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnés',
      one: '1 abonné',
      zero: 'Aucun abonné',
    );
    return '$_temp0';
  }

  @override
  String businessMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
      zero: 'Aucun membre',
    );
    return '$_temp0';
  }

  @override
  String get adminBusinessVerifications => 'Vérifications professionnelles';

  @override
  String get adminBusinessVerificationsSubtitle =>
      'Examiner et approuver les badges vérifiés des entreprises';

  @override
  String get adminApproveBusinessVerification => 'Approuver';

  @override
  String get adminRejectBusinessVerification =>
      'Rejeter la vérification professionnelle';

  @override
  String get adminBusinessRejectReasonHint => 'Motif du rejet (facultatif)';

  @override
  String get adminBusinessApproved => 'Entreprise vérifiée';

  @override
  String get adminBusinessRejected => 'Vérification professionnelle rejetée';

  @override
  String get adminNoPendingBusinessVerifications =>
      'Aucune vérification professionnelle en attente';

  @override
  String get adminAccessDenied => 'Accès refusé. Réservé aux administrateurs.';

  @override
  String get adminBusinessVerifiedNotificationTitle =>
      'Ton entreprise est vérifiée';

  @override
  String get adminBusinessVerifiedNotificationBody =>
      'Ton entreprise affiche désormais le badge vérifié doré.';

  @override
  String adminSubmittedLabel(String date) {
    return 'Envoyé le $date';
  }

  @override
  String get communitiesSponsored => 'Sponsorisé';

  @override
  String get communitiesSponsorThisCommunity => 'Sponsoriser cette communauté';

  @override
  String get communitiesSponsorSubtitle =>
      'Épingle une promo en haut pour les membres';

  @override
  String get communitiesSponsorFeatureName => 'Sponsoring de communauté';

  @override
  String get communitiesSponsorRequiresPlatinum =>
      'Sponsoriser une communauté et épingler une promo est une fonctionnalité professionnelle Platinum.';

  @override
  String get communitiesEditSponsorship => 'Modifier le sponsoring et la promo';

  @override
  String get communitiesMarkAsSponsored => 'Marquer comme sponsorisé';

  @override
  String get communitiesPromoTitleLabel => 'Titre de la promo';

  @override
  String get communitiesPromoTitleHint => 'ex. 20 % de réduction ce week-end';

  @override
  String get communitiesPromoBodyLabel => 'Message promo';

  @override
  String get communitiesPromoBodyHint => 'Parle de ton offre aux membres';

  @override
  String get communitiesPromoImageLabel => 'URL de l\'image (facultatif)';

  @override
  String get communitiesPromoLinkEventLabel =>
      'ID de l\'événement lié (facultatif)';

  @override
  String get communitiesPromoLinkUrlLabel => 'URL du lien (facultatif)';

  @override
  String get communitiesPromoTitleRequired =>
      'Veuillez saisir un titre de promo';

  @override
  String get communitiesSaveSponsorship => 'Enregistrer';

  @override
  String get communitiesRemovePromo => 'Supprimer la promo';

  @override
  String get exploreSearchTooltip => 'Rechercher';

  @override
  String get exploreQrTooltip => 'Mes QR codes';

  @override
  String get universalSearchTitle => 'Rechercher';

  @override
  String get universalSearchHint =>
      'Rechercher des personnes et des événements';

  @override
  String get universalSearchTabPeople => 'Personnes';

  @override
  String get universalSearchTabEvents => 'Événements';

  @override
  String get universalSearchEmptyPrompt =>
      'Trouve des personnes avec qui discuter et des événements à rejoindre';

  @override
  String get universalSearchNoPeople => 'Aucune personne trouvée';

  @override
  String get universalSearchNoEvents => 'Aucun événement trouvé';

  @override
  String get qrHubTitle => 'QR codes';

  @override
  String get qrHubTabMyTickets => 'Mes billets';

  @override
  String get qrHubTabScan => 'Scanner';

  @override
  String get qrHubNoTickets =>
      'Aucun billet à venir pour l\'instant. Rejoins un événement pour obtenir ton QR code.';

  @override
  String get qrHubTicketHint =>
      'Touche un billet pour ouvrir son QR code complet';

  @override
  String get qrHubScanInstructions =>
      'Pointe ta caméra vers un QR code GreenGo';

  @override
  String get qrHubInvalidCode => 'Ce n\'est pas un code GreenGo valide';

  @override
  String get qrScanApproved => 'Approuvé — enregistré';

  @override
  String get qrScanNotAuthorized =>
      'Seul le propriétaire ou un scanner invité peut valider les billets';

  @override
  String get qrHubJoinedEvent => 'Tu y participes ! Ouverture de l\'événement…';

  @override
  String get eventsRepeats => 'Répétitions';

  @override
  String get eventsRepeatNone => 'Ne se répète pas';

  @override
  String get eventsRepeatDaily => 'Quotidien';

  @override
  String get eventsRepeatWeekly => 'Hebdomadaire';

  @override
  String get eventsRepeatMonthly => 'Mensuel';

  @override
  String get eventsRepeatInterval => 'Tous les';

  @override
  String get eventsRepeatCount => 'Occurrences';

  @override
  String get eventsRecurringLabel => 'Récurrent';

  @override
  String get eventsCancelSeries => 'Annuler toute la série';

  @override
  String get eventsCancelSeriesConfirm =>
      'Annuler toutes les occurrences futures de cet événement récurrent ?';

  @override
  String get eventsSeriesCancelled => 'Série annulée';

  @override
  String get eventsSeriesCancelError => 'Impossible d\'annuler la série';

  @override
  String get eventsSaveAsDraft => 'Enregistrer comme brouillon';

  @override
  String get eventsSchedule => 'Planifier';

  @override
  String get eventsStatusDraft => 'Brouillon';

  @override
  String get eventsStatusScheduled => 'Planifié';

  @override
  String get eventsStatusCancelled => 'Annulé';

  @override
  String eventsScheduledForDate(String date) {
    return 'Planifié pour le $date';
  }

  @override
  String eventsRepeatCap(int max) {
    return 'Jusqu\'à $max occurrences';
  }

  @override
  String get eventsTicketTiers => 'Catégories de billets';

  @override
  String get eventsRepeatHelper =>
      '\'Tous les\' definit l\'intervalle entre les dates (ex. toutes les 2 semaines); \'Occurrences\' est le nombre total de dates creees.';

  @override
  String get eventsTicketTiersHelper =>
      'Niveaux de prix facultatifs (ex. Standard, VIP) qui definissent le prix et la capacite. Ils ne controlent pas l acces par pieces a l evenement.';

  @override
  String get eventsAddTier => 'Ajouter une catégorie';

  @override
  String get eventsTierName => 'Nom de la catégorie';

  @override
  String get eventsTierPriceCoins => 'Prix (pièces, 0 = gratuit)';

  @override
  String get eventsTierCapacity => 'Capacité (0 = illimité)';

  @override
  String get eventsFreeTier => 'Gratuit';

  @override
  String get eventsSelectTier => 'Sélectionne un billet';

  @override
  String get eventsJoinWaitlist => 'Rejoindre la liste d\'attente';

  @override
  String get eventsOnWaitlist => 'Sur la liste d\'attente';

  @override
  String eventsWaitlistPosition(int position) {
    return 'Tu es n°$position sur la liste d\'attente';
  }

  @override
  String eventsTierPriceValue(int coins) {
    return '$coins pièces';
  }

  @override
  String eventsTierCapacityValue(int capacity) {
    return '$capacity places';
  }

  @override
  String get eventsRsvpError => 'Impossible de mettre à jour ta participation';

  @override
  String get shareProfileTooltip => 'Partager le profil';

  @override
  String shareProfileMessage(String link) {
    return 'Discutez avec moi sur GreenGo : $link';
  }

  @override
  String shareEventMessage(String link) {
    return 'Découvrez cet événement sur GreenGo : $link';
  }

  @override
  String get guidelinesSubtitle =>
      'Un mot de bienvenue sur notre façon de nous connecter';

  @override
  String get guidelinesWelcomeTitle => 'Bienvenue entre les cultures';

  @override
  String get guidelinesWelcomeDesc =>
      'Rencontrez des gens du monde entier et partagez le vôtre avec ouverture.';

  @override
  String get guidelinesRespectTitle => 'Respectez chacun';

  @override
  String get guidelinesRespectDesc =>
      'La gentillesse et la curiosité d\'abord — traitez les autres comme vous aimeriez l\'être.';

  @override
  String get guidelinesAuthenticTitle => 'Restez authentique';

  @override
  String get guidelinesAuthenticDesc =>
      'GreenGo est fait pour des connexions culturelles authentiques — ce n\'est pas une application de rencontre.';

  @override
  String get guidelinesSafetyTitle => 'Pas de harcèlement ni de haine';

  @override
  String get guidelinesSafetyDesc =>
      'Le harcèlement, les discours haineux et les menaces n\'ont pas leur place ici.';

  @override
  String get guidelinesNoSpamTitle => 'Pas de spam ni de contenu explicite';

  @override
  String get guidelinesNoSpamDesc =>
      'Restez corrects — pas de spam, d\'arnaques ni de contenu sexuel.';

  @override
  String get guidelinesReportTitle => 'Signalez tout problème';

  @override
  String get guidelinesReportDesc =>
      'Quelque chose ne va pas ? Signalez-le et notre équipe s\'en occupera.';

  @override
  String get businessNewBadge => 'NOUVEAU';

  @override
  String get businessLeadsTitle => 'Prospects';

  @override
  String get businessLeadsEmpty =>
      'Aucun prospect pour l\'instant. Les personnes qui vous contactent ou enregistrent vos événements apparaîtront ici.';

  @override
  String get businessLeadContact => 'Vous a contacté';

  @override
  String get businessLeadSavedEvent => 'A enregistré votre événement';

  @override
  String get eventTicketWhen => 'Quand';

  @override
  String get eventTicketVenue => 'Lieu';

  @override
  String get eventTicketWhere => 'Où';

  @override
  String get eventTicketGuestsLabel => 'Invités';

  @override
  String eventTicketAdmits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Admet $count personnes',
      one: 'Admet 1 personne',
    );
    return '$_temp0';
  }

  @override
  String get shareEvent => 'Partager l\'événement';

  @override
  String get promoteTitle => 'Promouvoir';

  @override
  String get promoteSubtitle =>
      'Boostez votre visibilité avec des GreenGoCoins';

  @override
  String get promoteBusinessOption => 'Promouvoir l\'entreprise';

  @override
  String get promoteBusinessDesc =>
      'Mettez votre vitrine en avant en haut d\'Explorer';

  @override
  String get promoteEventsOption => 'Promouvoir un événement';

  @override
  String get promoteEventsDesc =>
      'Mettez un de vos événements en avant dans la découverte';

  @override
  String get promoteChooseDuration => 'Choisissez une durée';

  @override
  String get promoteNotActive => 'Pas de promotion en cours';

  @override
  String get promoteConfirmTitle => 'Confirmer la promotion';

  @override
  String get promoteConfirmCta => 'Promouvoir';

  @override
  String get promoteCancel => 'Annuler';

  @override
  String get promoteSelectEvent =>
      'Sélectionnez un événement à mettre en avant';

  @override
  String get promoteNoEvents =>
      'Vous n\'avez aucun événement à venir à mettre en avant';

  @override
  String get promoteEventAlreadyFeatured => 'Déjà mis en avant';

  @override
  String get promoteSuccess => 'Promotion active !';

  @override
  String get promoteError => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get promoteInsufficientCoins => 'Pièces insuffisantes';

  @override
  String get promoteInsufficientCoinsBody =>
      'Vous n\'avez pas assez de pièces pour cette promotion. Rechargez pour continuer.';

  @override
  String get promoteGetCoins => 'Obtenir des pièces';

  @override
  String promoteDurationDays(int days) {
    return '$days jours';
  }

  @override
  String promoteCostLabel(int cost) {
    return '$cost pièces';
  }

  @override
  String promoteActiveUntil(String date) {
    return 'Promu jusqu\'au $date';
  }

  @override
  String promoteBusinessConfirm(int days, int cost) {
    return 'Promouvoir votre entreprise pendant $days jours pour $cost pièces ?';
  }

  @override
  String promoteEventConfirm(int days, int cost) {
    return 'Mettre cet événement en avant pendant $days jours pour $cost pièces ?';
  }

  @override
  String get audienceSectionTitle => 'Aperçu de l\'audience';

  @override
  String get audiencePrivacyNote =>
      'Agrégé et anonymisé — les petits groupes sont masqués pour protéger la confidentialité.';

  @override
  String get audienceNotEnoughData =>
      'Pas encore assez de données pour l\'afficher tout en protégeant la confidentialité.';

  @override
  String get audienceAgeTitle => 'Répartition par âge';

  @override
  String get audienceCountriesTitle => 'Principaux pays';

  @override
  String get audienceInterestsTitle => 'Principaux centres d\'intérêt';

  @override
  String get eventAnalyticsTitle => 'Statistiques de l\'événement';

  @override
  String get eventAnalyticsGoing => 'Participants';

  @override
  String get eventAnalyticsWaitlist => 'Liste d\'attente';

  @override
  String get eventAnalyticsCheckedIn => 'Enregistrés';

  @override
  String get eventAnalyticsCheckInRate => 'Taux d\'enregistrement';

  @override
  String get eventAnalyticsTierBreakdown => 'Catégories de billets';

  @override
  String get businessEventsTitle => 'Gérer mes événements';

  @override
  String get businessEventsSearchHint => 'Rechercher par nom ou date';

  @override
  String get businessEventsEmpty =>
      'Vous n\'avez pas encore créé d\'événement.';

  @override
  String get businessEventsAnalytics => 'Statistiques';

  @override
  String get businessEventsCancelTitle => 'Annuler l\'événement';

  @override
  String get businessEventsCancelMessage =>
      'Annuler cet événement ? Les participants seront prévenus et il sera supprimé.';

  @override
  String get businessEventsCancelSeriesMessage =>
      'Annuler toutes les occurrences de cette série récurrente ?';

  @override
  String get businessEventsCancelConfirm => 'Annuler l\'événement';

  @override
  String get businessEventsCancelled => 'Événement annulé';

  @override
  String get businessPausedTitle => 'Entreprise en pause';

  @override
  String get businessPausedSubtitle =>
      'Vos fonctionnalités professionnelles sont en pause car votre abonnement Platinum a expiré. Renouvelez Platinum pour restaurer votre vitrine, vos statistiques, vos prospects et vos promotions.';

  @override
  String get businessReactivate => 'Renouveler Platinum';

  @override
  String get eventsBoostChooseDuration => 'Choisissez la durée du boost';

  @override
  String eventsBoostHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String eventBoostEndsIn(String time) {
    return 'Le boost se termine dans $time';
  }

  @override
  String get eventBoostEnded => 'Boost terminé';

  @override
  String get eventsBuyCoins => 'Acheter des pièces';

  @override
  String get eventsBuyCoinsPrompt =>
      'Vous n\'avez pas assez de pièces. Voulez-vous en acheter davantage ?';

  @override
  String get messageTooLong =>
      'Les messages peuvent contenir jusqu\'à 4096 caractères.';

  @override
  String get exploreBusinessesNearYou => 'Entreprises pres de vous';

  @override
  String get splashBusinessLabel => 'BUSINESS';

  @override
  String get rateThisBusiness => 'Évaluer cette entreprise';

  @override
  String get businessRatingError =>
      'Impossible d\'enregistrer votre note. Veuillez réessayer.';

  @override
  String businessRatingCount(int count) {
    return '($count)';
  }

  @override
  String rateStarsSemantic(int stars) {
    return 'Attribuer $stars étoiles';
  }

  @override
  String businessRatingSemantic(String avg, int count) {
    return 'Noté $avg sur 5, $count évaluations';
  }

  @override
  String get editStorefront => 'Modifier la vitrine';

  @override
  String get editStorefrontSubtitle =>
      'Gérez votre galerie, vos horaires, vos liens et vos infos';

  @override
  String get storefrontGallerySubtitle =>
      'Mettez en valeur votre lieu, vos produits ou votre équipe';

  @override
  String get storefrontOpeningHoursSubtitle =>
      'Définissez vos jours et heures d\'ouverture';

  @override
  String get storefrontDescriptionHint => 'Parlez de votre entreprise';

  @override
  String get storefrontCategoryHint => 'ex. Restaurant, Café, Musée';

  @override
  String get storefrontLinkHint => 'https://...';

  @override
  String get storefrontAddLink => 'Ajouter un lien';

  @override
  String get storefrontAddImage => 'Ajouter une image';

  @override
  String get storefrontSaved => 'Vitrine mise à jour';

  @override
  String get analyticsEventViews => 'Vues de l\'événement';

  @override
  String get analyticsCommunityReach => 'Portée communautaire';

  @override
  String get analyticsChatsInvolved => 'Conversations générées';

  @override
  String get eventAnalyticsViews => 'Vues';

  @override
  String get businessHubScanner => 'Scanner rapide';

  @override
  String get businessHubScannerSubtitle =>
      'Scannez les billets pour enregistrer les participants';

  @override
  String get businessHubFollowers => 'Abonnés';

  @override
  String get businessHubFollowersSubtitle => 'Voyez qui suit votre entreprise';

  @override
  String get businessFollowersTitle => 'Abonnés';

  @override
  String get businessNoFollowers =>
      'Pas encore d\'abonnés. Partagez votre vitrine pour développer votre audience.';

  @override
  String get membershipRequiredTitle => 'Abonnement requis';

  @override
  String get membershipRequiredBody =>
      'Vous avez besoin d\'un abonnement actif pour cela. Renouvelez pour continuer.';

  @override
  String get renewMembership => 'Renouveler l\'abonnement';

  @override
  String get extraEventTitle => 'Événement supplémentaire';

  @override
  String extraEventBody(int cost) {
    return 'Vous avez atteint votre limite d\'événements gratuits. Créer un événement supplémentaire pour $cost pièces ?';
  }

  @override
  String get accountBannedTitle => 'Compte banni définitivement';

  @override
  String get accountBannedBody =>
      'Ce compte a été banni définitivement pour violation de notre politique de contenu. Cette décision est définitive.';

  @override
  String get adminBanPermanently => 'Bannir définitivement';

  @override
  String get adminBanConfirm => 'Bannir définitivement ce compte ?';

  @override
  String get adminBanConfirmBody =>
      'Cela bannit définitivement le compte et bloque tout accès. Cette action est irréversible.';

  @override
  String get adminBanReasonHint => 'Motif (ex. nudité dans la galerie)';

  @override
  String get adminBanned => 'Compte banni définitivement';

  @override
  String get storefrontFeaturedImage => 'Image à la une';

  @override
  String get storefrontFeaturedImageSubtitle =>
      'La bannière principale affichée en haut de votre vitrine.';

  @override
  String get storefrontAddFeaturedImage => 'Ajouter une image à la une';

  @override
  String get storefrontProfileImage => 'Photo de profil';

  @override
  String get storefrontProfileImageSubtitle =>
      'Votre avatar, affiché à côté du nom de votre entreprise.';

  @override
  String get storefrontAddProfileImage => 'Ajouter une photo de profil';

  @override
  String get storefrontReplaceProfileImage => 'Remplacer la photo de profil';

  @override
  String get preferenceBusinessOnly => 'Comptes professionnels uniquement';

  @override
  String get preferenceBusinessOnlyDesc =>
      'Afficher uniquement les comptes professionnels dans la découverte';

  @override
  String get businessProfileNameLabel => 'Nom du profil professionnel';

  @override
  String get businessProfileNameHint => 'Affiché sur votre vitrine';

  @override
  String get businessLegalNameLabel => 'Raison sociale';

  @override
  String get businessLegalNameHint => 'Nom d\'entreprise enregistré';

  @override
  String get verifyOwnerNameLabel => 'Nom complet du propriétaire';

  @override
  String get verifyOwnerNameHint =>
      'Exactement comme sur la pièce d\'identité téléchargée';

  @override
  String get scanResultApproved => 'Approuvé';

  @override
  String get scanResultDenied => 'Refusé';

  @override
  String get communitiesTabChat => 'Discussion';

  @override
  String get communitiesTabTips => 'Astuces';

  @override
  String get communitiesTabAnnouncements => 'Annonces';

  @override
  String get communitiesTabEvents => 'Événements';

  @override
  String get communitiesJoinRequestSent =>
      'Demande envoyée – en attente d’approbation';

  @override
  String get communitiesJoinRequestsTitle => 'Demandes d’adhésion';

  @override
  String get communitiesTipsEmpty =>
      'Pas encore d’astuces. Partagez une astuce linguistique, un fait culturel ou un conseil local depuis le chat.';

  @override
  String get communitiesAnnouncementsEmpty => 'Pas encore d’annonces.';

  @override
  String get communitiesPostAnnouncement => 'Publier une annonce';

  @override
  String get communitiesRequestToJoin => 'Demander à rejoindre';

  @override
  String get communitiesMutedNotice =>
      'Vous avez été mis en sourdine dans cette communauté';

  @override
  String get communitiesRulesResourcesTitle => 'Règles et ressources';

  @override
  String get communitiesRulesLabel => 'Règles de la communauté';

  @override
  String get communitiesRulesHint => 'Consignes pour les membres…';

  @override
  String get communitiesResourcesLabel => 'Liens de ressources';

  @override
  String get communitiesResourceTitleHint => 'Titre';

  @override
  String get communitiesResourceUrlHint => 'https://…';

  @override
  String get communitiesAddResource => 'Ajouter un lien';

  @override
  String get communitiesSaveLabel => 'Enregistrer';

  @override
  String get communitiesAddRulesPrompt =>
      'Ajouter des règles et des ressources pour cette communauté';

  @override
  String get communitiesAnnouncementHint =>
      'Écrivez une annonce à tous les membres…';

  @override
  String get communitiesPostLabel => 'Publier';

  @override
  String get communitiesPromoteMember => 'Promouvoir administrateur';

  @override
  String get communitiesGrantTips => 'Autoriser a publier des Conseils';

  @override
  String get communitiesRevokeTips => 'Revoquer la publication de Conseils';

  @override
  String get communitiesGrantAnnouncements =>
      'Autoriser a publier des Annonces';

  @override
  String get communitiesRevokeAnnouncements =>
      'Revoquer la publication d Annonces';

  @override
  String get communitiesDemoteMember => 'Rétrograder en membre';

  @override
  String get communitiesRemoveMember => 'Retirer de la communauté';

  @override
  String get communitiesMuteMember => 'Mettre en sourdine';

  @override
  String get communitiesUnmuteMember => 'Réactiver';

  @override
  String get communitiesBanMember => 'Bannir';

  @override
  String get communitiesReportMember => 'Signaler';

  @override
  String get communitiesNoJoinRequests => 'Aucune demande en attente';

  @override
  String get communitiesApprove => 'Approuver';

  @override
  String get communitiesReject => 'Refuser';

  @override
  String get communitiesLinkToCommunity => 'Lier à une communauté (facultatif)';

  @override
  String get communitiesLinkNone => 'Aucune';

  @override
  String get communitiesCreateEvent => 'Créer un événement';

  @override
  String get communitiesEventsEmpty => 'Pas encore d’événements';

  @override
  String get communitiesTranslate => 'Traduire';

  @override
  String get communitiesShowOriginal => 'Voir l’original';

  @override
  String get communitiesTranslating => 'Traduction…';

  @override
  String get eventsFilterSoon => 'Bientôt';

  @override
  String get businessBadgeLabel => 'Entreprise';

  @override
  String get businessWhatsappLabel => 'Numéro WhatsApp';

  @override
  String get businessWhatsappSubtitle =>
      'Les visiteurs appuient pour discuter avec vous sur WhatsApp';

  @override
  String get businessWhatsappHint => 'ex. +351912345678';

  @override
  String get businessWhatsappButton => 'WhatsApp';

  @override
  String get locationLanguagesLabel => 'Lieu et langues';

  @override
  String get storefrontLocationLanguagesSubtitle =>
      'Où vous êtes et les langues que vous parlez';

  @override
  String get storefrontLocationNotSet => 'Non défini';

  @override
  String get universalSearchTabBusiness => 'Entreprises';

  @override
  String get universalSearchTabCommunity => 'Communautés';

  @override
  String get universalSearchNoBusiness => 'Aucune entreprise trouvée';

  @override
  String get universalSearchNoCommunities => 'Aucune communauté trouvée';

  @override
  String get communitiesSearchTips => 'Rechercher des astuces';

  @override
  String get communitiesAddTip => 'Ajouter une astuce';

  @override
  String get communitiesTipHint => 'Partagez une astuce utile…';

  @override
  String get shopEventsCreate => 'Evenements que vous pouvez creer';

  @override
  String get shopGroupsCreate => 'Groupes et communautes que vous pouvez creer';

  @override
  String get shopDailyConnects => 'Nouvelles connexions quotidiennes';

  @override
  String get shopMonthlyBoosts => 'Boosts de profil mensuels';

  @override
  String get shopMonthlyCoins => 'Pieces mensuelles';

  @override
  String get shopNoAds => 'Sans publicite';

  @override
  String get shopSeeWhoConnected => 'Voir qui s\'est connecte avec vous';

  @override
  String get shopTravelMode => 'Mode voyage';

  @override
  String get shopBusinessAccount => 'Compte professionnel';

  @override
  String get tourCommunitiesTabsTitle => 'Trois facons d\'explorer';

  @override
  String get tourCommunitiesTabsDesc =>
      'Basculez entre vos groupes, decouvrez-en de nouveaux et gerez les communautes que vous avez creees.';

  @override
  String get tourCommunitiesSearchTitle => 'Trouve tes groupes';

  @override
  String get tourCommunitiesSearchDesc =>
      'Tape ici pour filtrer tes communautés par nom — pratique une fois que tu en as rejoint plusieurs.';

  @override
  String get tourCommunitiesCardTitle => 'Ouvrir et mettre en favori';

  @override
  String get tourCommunitiesCardDesc =>
      'Touche une communauté pour ouvrir son chat, ses conseils, annonces et événements. Touche l\'étoile ⭐ pour l\'enregistrer — les favoris sont épinglés en haut.';

  @override
  String get tourCommunitiesCreateTitle => 'Creer une communaute';

  @override
  String get tourCommunitiesCreateDesc =>
      'Touchez ici pour creer votre propre communaute et rassembler les gens.';

  @override
  String get tourReplayGuide => 'Revoir le guide';

  @override
  String get tourExploreSearchTitle => 'Tout rechercher';

  @override
  String get tourExploreSearchDesc =>
      'Trouve des personnes, des entreprises, des événements et des communautés — le tout depuis une seule recherche.';

  @override
  String get tourExploreQrTitle => 'Ton code QR';

  @override
  String get tourExploreQrDesc =>
      'Scanne ou partage un code QR pour te connecter instantanément en personne.';

  @override
  String get tourEventsCreateTitle => 'Creer un evenement';

  @override
  String get tourEventsCreateDesc =>
      'Touchez le plus pour organiser votre propre evenement ou rencontre.';

  @override
  String get tourEventsSearchTitle => 'Rechercher des evenements';

  @override
  String get tourEventsSearchDesc =>
      'Trouvez des evenements par ville, pays ou nom, et triez-les a votre facon.';

  @override
  String get tourEventsTabsTitle => 'Explorez chaque onglet';

  @override
  String get tourEventsTabsDesc =>
      'Parcourez les evenements de la communaute, les evenements en direct, les attractions et les experiences pres de vous.';

  @override
  String get tourProfileHubTitle => 'Votre espace profil';

  @override
  String get tourProfileHubDesc =>
      'Tout sur votre compte se trouve ici : modifiez-le, gerez les parametres et debloquez les fonctions premium.';

  @override
  String get tourProfileViewTitle => 'Apercu de votre profil';

  @override
  String get tourProfileViewDesc =>
      'Voyez exactement comment les autres voient votre profil.';

  @override
  String get tourProfileEditTitle => 'Modifier vos infos';

  @override
  String get tourProfileEditDesc =>
      'Touchez pour mettre a jour vos photos, bio, centres d\'interet, lieu et plus.';

  @override
  String get tourNotifHubTitle => 'Vos notifications';

  @override
  String get tourNotifHubDesc =>
      'Chaque connexion, message et nouveauté d\'événement arrive ici.';

  @override
  String get tourNotifOpenTitle => 'Ouvrir et gerer';

  @override
  String get tourNotifOpenDesc =>
      'Touchez une notification pour l\'ouvrir, ou glissez vers la gauche pour la supprimer.';

  @override
  String get tourNotifMarkAllTitle => 'Vider les non lus';

  @override
  String get tourNotifMarkAllDesc => 'Marquez tout comme lu en un seul geste.';

  @override
  String get communitiesJoinAsPersonalTitle =>
      'Rejoindre avec votre profil personnel';

  @override
  String get communitiesJoinAsPersonalBody =>
      'Vous rejoindrez cette communaute avec votre profil personnel. Votre vitrine professionnelle ne sera pas affichee ici. Continuer?';

  @override
  String get communitiesJoinAsPersonalConfirm => 'Rejoindre';

  @override
  String get communitiesCreatedManageHint =>
      'Communaute creee! Ouvrez Membres pour ajouter des personnes et accorder des droits de conseils ou d\'annonces.';

  @override
  String get exploreHappeningSoon => 'Bientot';

  @override
  String get attrScoreLabel => 'GreenGo Score';

  @override
  String get attrTierIconic => 'Iconique';

  @override
  String get attrTierExceptional => 'Exceptionnel';

  @override
  String get attrTierExcellent => 'Excellent';

  @override
  String get attrTierGreat => 'Très bien';

  @override
  String get attrTierWorthVisit => 'Vaut le détour';

  @override
  String get attrImpWorldIcon => 'Icône mondiale';

  @override
  String get attrImpInternational => 'Monument international';

  @override
  String get attrImpNational => 'Monument national';

  @override
  String get attrImpRegional => 'Site régional';

  @override
  String get attrImpLocal => 'Site local';

  @override
  String get attrChipHome => 'Mon pays';

  @override
  String get attrChipHere => 'Vous êtes ici';

  @override
  String get attrFree => 'Gratuit';

  @override
  String get attrUnesco => 'UNESCO';

  @override
  String get attrMustVisit => 'Incontournable';

  @override
  String get attrTop10 => 'Top 10';

  @override
  String get attrPhotoSpot => 'Idéal pour les photos';

  @override
  String get attrAllCategories => 'Toutes';

  @override
  String get attrFilterCategory => 'Catégorie';

  @override
  String get attrFilterCountry => 'Pays';

  @override
  String get attrFilterCity => 'Ville';

  @override
  String get attrAllCities => 'Toutes les villes';

  @override
  String get attrSortDistance => 'Les plus proches';

  @override
  String get attrSortScore => 'GreenGo Score';

  @override
  String get attrSortRating => 'Note';

  @override
  String get attrSortPrice => 'Prix';

  @override
  String get attrSortName => 'Nom';

  @override
  String get attrNoResults => 'Aucun site ne correspond à vos filtres';

  @override
  String get attrNoCoverage =>
      'Nous ne couvrons pas encore votre pays — bientôt disponible';

  @override
  String get attrLoadFailed => 'Impossible de charger les sites';

  @override
  String attrKmAway(String km) {
    return 'à $km km';
  }

  @override
  String get attrAbout => 'À propos';

  @override
  String get attrHighlights => 'Points forts';

  @override
  String get attrWhyVisit => 'Pourquoi y aller';

  @override
  String get attrScoreHistorical => 'Historique';

  @override
  String get attrScoreArchitectural => 'Architecture';

  @override
  String get attrScoreNatural => 'Nature';

  @override
  String get attrScorePhotography => 'Photographie';

  @override
  String get attrBestTimeTitle => 'Meilleure période';

  @override
  String get attrHistoryTitle => 'Histoire';

  @override
  String get attrDidYouKnow => 'Le saviez-vous';

  @override
  String get attrPhotoTips => 'Conseils photo';

  @override
  String get attrPractical => 'Infos pratiques';

  @override
  String get attrOpeningHours => 'Horaires';

  @override
  String get attrVisitDuration => 'Durée de visite';

  @override
  String get attrAccessibility => 'Accessibilité';

  @override
  String get attrPets => 'Animaux';

  @override
  String get attrSafety => 'Sécurité';

  @override
  String get attrVisitorsPerYear => 'Visiteurs par an';

  @override
  String get attrTicketFrom => 'Billet';

  @override
  String get attrOpenInMaps => 'Ouvrir dans Maps';

  @override
  String attrPhotoBy(String author, String license) {
    return 'Photo : $author · $license';
  }

  @override
  String get attrIndoor => 'Intérieur';

  @override
  String get attrOutdoor => 'Extérieur';

  @override
  String attrCountAttractions(int count) {
    return '$count sites';
  }

  @override
  String get attrEnableLocation =>
      'Activez la localisation pour voir ce qui est le plus proche de vous';

  @override
  String get attrRetry => 'Réessayer';

  @override
  String get attrTranslate => 'Traduire';

  @override
  String get attrShowOriginal => 'Voir l\'original';

  @override
  String get attrCatReligious => 'Lieu religieux';

  @override
  String get attrCatHistoricSite => 'Site historique';

  @override
  String get attrCatMuseum => 'Musée';

  @override
  String get attrCatNature => 'Nature';

  @override
  String get attrCatNeighborhood => 'Quartier';

  @override
  String get attrCatBeach => 'Plage';

  @override
  String get attrCatGarden => 'Jardin';

  @override
  String get attrCatMonument => 'Monument';

  @override
  String get attrCatSquare => 'Place';

  @override
  String get attrCatStreet => 'Rue';

  @override
  String get attrCatArchitecture => 'Architecture';

  @override
  String get attrCatObservationDeck => 'Point de vue';

  @override
  String get attrCatCastle => 'Château';

  @override
  String get attrCatMarket => 'Marché';

  @override
  String get attrCatMountain => 'Montagne';

  @override
  String get attrCatPalace => 'Palais';

  @override
  String get attrCatIsland => 'Île';

  @override
  String get attrCatLake => 'Lac';

  @override
  String get attrCatNationalPark => 'Parc national';

  @override
  String get attrCatOther => 'Autre';

  @override
  String get attrCatBridge => 'Pont';

  @override
  String get attrCatThemePark => 'Parc d’attractions';

  @override
  String get attrCatWaterfall => 'Cascade';

  @override
  String get attrCatZoo => 'Zoo';

  @override
  String get attrCatShopping => 'Shopping';

  @override
  String get attrCatAquarium => 'Aquarium';

  @override
  String attrSearchResults(int count, String query) {
    return '$count résultats pour \"$query\"';
  }

  @override
  String get attendeesSeeAll => 'Voir tout';

  @override
  String attendeesCount(int count) {
    return '$count participants';
  }

  @override
  String attendeesCountWithGuests(int count, int guests) {
    return '$count participants · $guests invités';
  }

  @override
  String attendeesBringing(int count) {
    return 'Amène $count invités';
  }

  @override
  String get attendeesOrganizer => 'Organisateur';

  @override
  String get attendeesLoadFailed => 'Impossible de charger les participants';

  @override
  String get attendeesProfileFailed => 'Impossible d ouvrir ce profil';

  @override
  String get quizTitle => 'Test de personnalité';

  @override
  String get quizSubtitle => 'Aidez-nous à comprendre votre personnalité';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String get quizQuestionOpenness =>
      'J\'aime essayer des activités nouvelles et passionnantes';

  @override
  String get quizQuestionConscientiousness =>
      'Je préfère avoir une routine structurée et organisée';

  @override
  String get quizQuestionExtraversion =>
      'Je me sens plein d\'énergie lorsque je socialise avec les autres';

  @override
  String get quizQuestionAgreeableness =>
      'J\'essaie d\'être coopératif et d\'éviter les conflits';

  @override
  String get quizQuestionNeuroticism => 'Je me sens souvent anxieux ou inquiet';

  @override
  String get quizAnswerStronglyDisagree => 'Pas du tout d\'accord';

  @override
  String get quizAnswerDisagree => 'Pas d\'accord';

  @override
  String get quizAnswerNeutral => 'Neutre';

  @override
  String get quizAnswerAgree => 'D\'accord';

  @override
  String get quizAnswerStronglyAgree => 'Tout à fait d\'accord';

  @override
  String get quizBigFiveNote =>
      'Basé sur le modèle des cinq grands traits de personnalité';

  @override
  String get profilePreviewTitle => 'Aperçu du profil';

  @override
  String get profilePreviewSubtitle =>
      'Vérifiez votre profil avant de terminer';

  @override
  String get profilePreviewCompleteButton => 'Terminer le profil';

  @override
  String get profileFieldName => 'Nom';

  @override
  String get profileFieldAge => 'Âge';

  @override
  String profileAgeYearsOld(int age) {
    return '$age ans';
  }

  @override
  String get profileFieldStatus => 'Statut';

  @override
  String get profileNoBio => 'Aucune biographie fournie';

  @override
  String get profileCompleteBadgeTitle => 'Profil complet !';

  @override
  String get profileCompleteBadgeSubtitle =>
      'Votre profil est prêt à être publié';

  @override
  String get personalityTraitsTitle => 'Traits de personnalité';

  @override
  String get traitOpenness => 'Ouverture';

  @override
  String get traitConscientiousness => 'Conscience';

  @override
  String get traitExtraversion => 'Extraversion';

  @override
  String get traitAgreeableness => 'Agréabilité';

  @override
  String get traitNeuroticism => 'Névrosisme';

  @override
  String get socialLinksSubtitle =>
      'Connectez vos comptes sociaux (facultatif)';

  @override
  String get socialHintUsernameNoAt => 'Nom d\'utilisateur (sans @)';

  @override
  String get socialLinksVisibilityNote =>
      'Vos profils sociaux seront visibles sur votre profil public';

  @override
  String get travelPrefTitle => 'Comment souhaitez-vous utiliser GreenGo ?';

  @override
  String get travelPrefSubtitle =>
      'Parlez-nous de vos centres d\'intérêt afin que nous puissions personnaliser votre expérience.';

  @override
  String get travelPrefLearnTravelTitle => 'Apprendre et voyager';

  @override
  String get travelPrefLearnTravelDesc =>
      'Apprendre des langues et rencontrer des gens lorsque je voyage vers de nouveaux endroits';

  @override
  String get travelPrefLocalGuideTitle => 'Guide local';

  @override
  String get travelPrefLocalGuideDesc =>
      'Aider les voyageurs à découvrir ma ville et partager ma culture avec eux';

  @override
  String get travelPrefBothTitle => 'Les deux';

  @override
  String get travelPrefBothDesc =>
      'Je veux apprendre des langues, voyager dans le monde et aider les visiteurs dans ma ville';

  @override
  String get travelPrefChangeLater =>
      'Vous pouvez modifier cela à tout moment dans les paramètres de votre profil.';

  @override
  String get locationErrorPermissionDenied =>
      'L\'autorisation de localisation a été refusée. Veuillez l\'accorder dans les paramètres.';

  @override
  String get locationErrorServicesDisabled =>
      'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.';

  @override
  String get locationErrorUnableToGet =>
      'Impossible d\'obtenir votre position. Vérifiez les paramètres de votre appareil ou réessayez plus tard.';

  @override
  String get locationErrorCheckInternet =>
      'Veuillez vérifier votre connexion Internet et réessayer.';

  @override
  String get locationErrorPermissionRequired =>
      'L\'autorisation de localisation est requise. Veuillez l\'accorder dans les paramètres.';

  @override
  String get locationErrorTookTooLong =>
      'L\'obtention de votre position a pris trop de temps. Veuillez réessayer.';

  @override
  String get phoneErrorInvalidNumber =>
      'Format de numéro de téléphone invalide. Utilisez le format international (par ex. +1234567890).';

  @override
  String get phoneErrorTooManyRequests =>
      'Trop de tentatives. Veuillez patienter quelques minutes avant de réessayer.';

  @override
  String get phoneErrorQuotaExceeded =>
      'Quota de SMS dépassé. Veuillez réessayer plus tard.';

  @override
  String get phoneErrorCaptchaFailed =>
      'La vérification reCAPTCHA a échoué. Veuillez réessayer.';

  @override
  String get phoneErrorMissingNumber =>
      'Veuillez saisir un numéro de téléphone.';

  @override
  String phoneErrorGeneric(String code) {
    return 'Erreur de vérification du téléphone ($code). Veuillez réessayer.';
  }

  @override
  String get phoneErrorUnexpected =>
      'Erreur de vérification du téléphone. Veuillez réessayer.';

  @override
  String get phoneErrorAlreadyLinked =>
      'Ce numéro de téléphone est déjà lié à un autre compte.';

  @override
  String get languageNameEnglish => 'Anglais';

  @override
  String get languageNameSpanish => 'Espagnol';

  @override
  String get languageNameFrench => 'Français';

  @override
  String get languageNameGerman => 'Allemand';

  @override
  String get languageNameItalian => 'Italien';

  @override
  String get languageNamePortuguese => 'Portugais';

  @override
  String get languageNamePortugueseBrazil => 'Portugais (Brésil)';

  @override
  String get languageNameRussian => 'Russe';

  @override
  String get languageNameChinese => 'Chinois';

  @override
  String get languageNameJapanese => 'Japonais';

  @override
  String get languageNameKorean => 'Coréen';

  @override
  String get languageNameArabic => 'Arabe';

  @override
  String get languageNameHindi => 'Hindi';

  @override
  String get languageNameDutch => 'Néerlandais';

  @override
  String get languageNameSwedish => 'Suédois';

  @override
  String get languageNameNorwegian => 'Norvégien';

  @override
  String get languageNameDanish => 'Danois';

  @override
  String get languageNameFinnish => 'Finnois';

  @override
  String get languageNamePolish => 'Polonais';

  @override
  String get languageNameTurkish => 'Turc';

  @override
  String get languageNameGreek => 'Grec';

  @override
  String get resetPasswordTitle => 'Réinitialisez votre mot de passe';

  @override
  String get resetPasswordSubtitle =>
      'Saisissez votre adresse e-mail et nous vous enverrons les instructions pour réinitialiser votre mot de passe.';

  @override
  String get sendResetLink => 'Envoyer le lien de réinitialisation';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get resetLinkExpiryNote =>
      'Pour des raisons de sécurité, le lien de réinitialisation expirera dans 1 heure.';

  @override
  String get resetEmailSentTitle => 'E-mail envoyé !';

  @override
  String resetEmailSentBody(String email) {
    return 'Un lien de réinitialisation du mot de passe a été envoyé à $email.\n\nVeuillez vérifier votre boîte de réception et vos spams.';
  }

  @override
  String get resetErrorInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get resetErrorUnavailable =>
      'Service temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get resetErrorFailed =>
      'Échec de l\'envoi de l\'e-mail de réinitialisation. Veuillez réessayer.';

  @override
  String get onboardingSubmitCreatingProfile => 'Création de votre profil…';

  @override
  String get onboardingSubmitGrantingCoins => 'Configuration de vos pièces…';

  @override
  String get onboardingSubmitFinishingUp => 'Presque terminé…';

  @override
  String get onboardingSubmitPleaseWait => 'Cela ne prend qu\'un instant';

  @override
  String get chatSettingSilverPlusOnly => 'Disponible a partir de Silver';

  @override
  String get chatSettingXpBarHint =>
      'Apparaît dès que vous gagnez de l\'XP dans cette discussion';

  @override
  String get chatSettingLanguageFlagsHint =>
      'Affiché sur les messages traduits';

  @override
  String get chatSmartRepliesLoading => 'Préparation des réponses...';

  @override
  String get errorScreenTitle => 'Une erreur est survenue';

  @override
  String get errorScreenBody =>
      'Cet écran n\'a pas pu s\'ouvrir. Rechargez l\'application pour réessayer — votre compte n\'est pas affecté.';

  @override
  String get errorScreenReload => 'Recharger';

  @override
  String get ageVerifyTitle => 'Vérifiez votre âge';

  @override
  String get ageVerifyWhyPublish =>
      'Pour publier dans une communauté, nous devons confirmer que vous avez plus de 18 ans.';

  @override
  String get ageVerifyWhyPhone =>
      'Vous vous êtes inscrit avec un numéro de téléphone : il nous faut un document pour confirmer votre âge.';

  @override
  String get ageVerifyPrivacyNote =>
      'Nous lisons la date de naissance automatiquement. La photo est supprimée dès qu\'une décision est prise (au plus tard après 7 jours si une personne doit l\'examiner) et n\'est jamais affichée sur votre profil.';

  @override
  String get ageVerifyTakePhoto => 'Photographiez votre pièce d\'identité';

  @override
  String get ageVerifyChooseImage => 'Choisir dans la galerie';

  @override
  String get ageVerifyChecking => 'Vérification de votre document…';

  @override
  String get ageVerifyPending =>
      'Nous examinons votre document. Cela prend généralement moins d\'une journée.';

  @override
  String get ageVerifyVerified => 'Votre âge est vérifié.';

  @override
  String get ageVerifyRejected =>
      'Nous n\'avons pas pu lire votre document. Réessayez avec une photo plus nette.';

  @override
  String get ageVerifyRejectedUnderage =>
      'Le document indique que vous avez moins de 18 ans.';

  @override
  String get ageVerifyRejectedReused =>
      'Ce document est déjà lié à un autre compte.';

  @override
  String get ageVerifyCta => 'Vérifier maintenant';

  @override
  String get ageVerifyLater => 'Plus tard';

  @override
  String get ageVerifyNeededToPost => 'Vérifiez votre âge pour publier';

  @override
  String get contactSupportSubtitle =>
      'Questions, problèmes ou signalements — nous répondons par e-mail';

  @override
  String get offerPreRegisteredTitle => 'Vous êtes préinscrit';

  @override
  String get offerWelcomePackTitle => 'Votre pack de bienvenue';

  @override
  String offerTierLine(String tier, String duration) {
    return 'Abonnement $tier pendant $duration';
  }

  @override
  String offerBaseLine(String duration) {
    return 'Abonnement Base pendant $duration';
  }

  @override
  String get offerFreeMonthLine => 'Un mois d\'accès complet offert';

  @override
  String offerCoinsLine(int coins) {
    return '$coins pièces de bienvenue';
  }

  @override
  String get offerAppliedFromToday =>
      'Ajouté automatiquement dès aujourd\'hui, à votre première connexion.';

  @override
  String get offerDurationOneMonth => '1 mois';

  @override
  String offerDurationMonths(int count) {
    return '$count mois';
  }

  @override
  String get offerDurationOneYear => '1 an';

  @override
  String offerDurationDays(int count) {
    return '$count jours';
  }

  @override
  String get featureIncludedTitle => 'CE QUI EST INCLUS';

  @override
  String get featureUnlimited => 'Illimité';

  @override
  String featureDailyConnects(String count) {
    return '$count nouvelles connexions chaque jour';
  }

  @override
  String featureMonthlyCoins(int coins) {
    return '$coins pièces chaque mois';
  }

  @override
  String featureEvents(String count) {
    return '$count événements actifs en même temps';
  }

  @override
  String featureBoosts(int count) {
    return '$count boosts de profil par mois';
  }

  @override
  String featureDiscoveryReveals(int count) {
    return '$count profils révélés à la fois';
  }

  @override
  String get featureTravelMode => 'Mode voyage - découvrez des gens partout';

  @override
  String get featureWhoConnected => 'Voyez qui s\'est connecté avec vous';

  @override
  String get boostProfileCelebrationTitle => 'Profil mis en avant !';

  @override
  String get boostEventCelebrationTitle => 'Événement mis en avant !';

  @override
  String get eventsEnded => 'Événement terminé';

  @override
  String get eventsAttendeeListVisibility => 'Qui peut voir les participants';

  @override
  String get eventsAttendeeListPrivate => 'Personne';

  @override
  String get eventsAttendeeListParticipants => 'Participants';

  @override
  String get eventsAttendeeListPublic => 'Tout le monde';

  @override
  String get eventsAttendeeListPrivateHint =>
      'Vous seul pouvez voir la liste des participants.';

  @override
  String get eventsAttendeeListParticipantsHint =>
      'Les participants peuvent se voir entre eux.';

  @override
  String get eventsAttendeeListPublicHint =>
      'Toute personne voyant l\'événement peut voir la liste des participants.';

  @override
  String get eventsAttendeeListHidden =>
      'L\'organisateur a masqué la liste des participants.';

  @override
  String get eventsOrganizedBy => 'Organisé par';

  @override
  String eventsOrganizerYou(String name) {
    return '$name (vous)';
  }

  @override
  String eventsByOrganizer(String name) {
    return 'par $name';
  }

  @override
  String shareEventMessageTitled(String title, String link) {
    return '$title\nDécouvre cet événement sur GreenGo : $link';
  }

  @override
  String shareCommunityMessage(String name, String link) {
    return '$name\nRejoins cette communauté sur GreenGo : $link';
  }

  @override
  String shopMembershipExpiredOn(String tier, String date) {
    return 'Ton abonnement $tier a expiré le $date';
  }

  @override
  String get eventsLocationHelper =>
      'Saisis un lieu ou une adresse, ou choisis-le sur la carte';

  @override
  String get eventsPickOnMap => 'Choisir sur la carte';

  @override
  String get eventsLocationNotOnMap =>
      'Enregistré avec le lieu saisi. Nous n\'avons pas pu le placer sur la carte : il n\'apparaîtra pas dans les recherches à proximité.';

  @override
  String get eventsCoOwners => 'Co-organisateurs';

  @override
  String get eventsCoOwnersHelper =>
      'Les co-organisateurs peuvent modifier l\'événement, ouvrir la liste de présence, enregistrer les invités et voir la liste complète des participants. Toi seul peux supprimer l\'événement ou modifier les co-organisateurs.';

  @override
  String get eventsCoOwnersCreatorOnly =>
      'Seul le créateur de l\'événement peut modifier les co-organisateurs.';

  @override
  String get eventsAddCoOwner => 'Ajouter un co-organisateur';

  @override
  String eventsCoOwnerLimit(int max) {
    return 'Tu peux ajouter jusqu\'à $max co-organisateurs';
  }

  @override
  String get eventsCoOwnerSearchHint => 'Rechercher par pseudo';

  @override
  String get eventsCoOwnerSearch => 'Rechercher';

  @override
  String get eventsCoOwnerRecentChats => 'Discussions récentes';

  @override
  String get eventsCoOwnerNoRecentChats => 'Aucune discussion récente';

  @override
  String get eventsCoOwnerNotFound => 'Personne trouvé avec ce pseudo';

  @override
  String get eventsCoOwnerSearchFailed => 'La recherche a échoué. Réessaie.';

  @override
  String get eventsCoOwnerRemove => 'Retirer le co-organisateur';

  @override
  String eventsOrganizedWith(String names) {
    return 'avec $names';
  }

  @override
  String get eventsCoOwnerBadge => 'Co-organisateur';

  @override
  String get qrHubCancelRsvpConfirm =>
      'Supprimer ce billet ? Ta participation sera annulée et ta place libérée pour quelqu\'un d\'autre.';

  @override
  String get qrHubHideTicketConfirm =>
      'Retirer ce billet de ta liste ? Ton historique de présence est conservé.';

  @override
  String get qrHubTicketRemoved => 'Billet retiré';

  @override
  String get usageDailyUsageTitle => 'Utilisation du jour';

  @override
  String get usageConnectsThisHour => 'Connexions cette heure';

  @override
  String get usagePassesThisHour => 'Passes cette heure';

  @override
  String get usagePriorityConnectsThisHour =>
      'Connexions prioritaires cette heure';

  @override
  String get usageMessagesToday => 'Messages aujourd\'hui';

  @override
  String get usageMediaSentToday => 'Médias envoyés aujourd\'hui';

  @override
  String get usageUpgradeBenefitsTitle => 'Avantages de l\'upgrade';

  @override
  String get usageUpgradeButton => 'Améliorer mon abonnement';

  @override
  String usagePlanName(String tier) {
    return 'Offre $tier';
  }

  @override
  String get usageCurrentTierLabel => 'Niveau d\'abonnement actuel';

  @override
  String get usageNoBaseMembership => 'Aucun abonnement de base GreenGo';

  @override
  String usageExpiresOn(String date) {
    return 'Expire le : $date';
  }

  @override
  String usageExpiredOn(String date) {
    return 'Expiré le : $date';
  }

  @override
  String get usageStatusActive => 'Actif';

  @override
  String get usageStatusExpired => 'Expiré';

  @override
  String get usageCoinsAvailable => 'Pièces disponibles';

  @override
  String get usageNotAvailable => 'Non disponible';

  @override
  String usageWithTier(String tier) {
    return 'Avec $tier';
  }

  @override
  String get attrApplyFilter => 'Appliquer le filtre';

  @override
  String get userFollowFollow => 'Suivre';

  @override
  String get userFollowFollowing => 'Abonné';

  @override
  String get userFollowFollowBack => 'Suivre en retour';

  @override
  String get userFollowError =>
      'Impossible de mettre à jour l\'abonnement. Réessaie.';

  @override
  String get userFollowBlocked => 'Tu ne peux pas suivre cet utilisateur.';

  @override
  String get userFollowUnfollowTooltip => 'Ne plus suivre';

  @override
  String userFollowFollowersStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted abonnés',
      one: '$formatted abonné',
      zero: '$formatted abonné',
    );
    return '$_temp0';
  }

  @override
  String userFollowFollowingStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted abonnements',
      one: '$formatted abonnement',
      zero: '$formatted abonnement',
    );
    return '$_temp0';
  }

  @override
  String get userFollowTabFollowers => 'Abonnés';

  @override
  String get userFollowTabFollowing => 'Abonnements';

  @override
  String get userFollowEmptyFollowers => 'Pas encore d\'abonnés';

  @override
  String get userFollowEmptyFollowing => 'Ne suit encore personne';

  @override
  String get userFollowListError => 'Impossible de charger cette liste.';

  @override
  String attractionViewsCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted vues',
      one: '$formatted vue',
      zero: '$formatted vue',
    );
    return '$_temp0';
  }

  @override
  String get uexpCommunity => 'Communauté';

  @override
  String get uexpPartners => 'Partenaires';

  @override
  String get uexpCreate => 'Créer une expérience';

  @override
  String get uexpMine => 'Mes expériences';

  @override
  String get uexpEmpty =>
      'Aucune expérience de la communauté pour le moment. Soyez le premier à en proposer une !';

  @override
  String get uexpMineEmpty => 'Vous n\'avez encore créé aucune expérience.';

  @override
  String get uexpAll => 'Toutes';

  @override
  String get uexpFree => 'Gratuit';

  @override
  String get uexpCatFoodDrink => 'Cuisine et boissons';

  @override
  String get uexpCatCultureHistory => 'Culture et histoire';

  @override
  String get uexpCatNatureOutdoors => 'Nature et plein air';

  @override
  String get uexpCatNightlife => 'Vie nocturne';

  @override
  String get uexpCatSportsAdventure => 'Sport et aventure';

  @override
  String get uexpCatWellness => 'Bien-être';

  @override
  String get uexpCatLanguageLearning => 'Apprentissage des langues';

  @override
  String get uexpCatToursWalks => 'Visites et balades';

  @override
  String get uexpCatWorkshopsClasses => 'Ateliers et cours';

  @override
  String get uexpCatOther => 'Autre';

  @override
  String uexpReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
      zero: 'Aucun avis',
    );
    return '$_temp0';
  }

  @override
  String get uexpStatusDraft => 'Brouillon';

  @override
  String get uexpStatusPublished => 'Publiée';

  @override
  String get uexpStatusHidden => 'Masquée';

  @override
  String get uexpHiddenNotice =>
      'Cette expérience a été masquée car elle enfreint les règles de GreenGo. Modifiez le texte pour la rétablir.';

  @override
  String get uexpNewTitle => 'Nouvelle expérience';

  @override
  String get uexpEditTitle => 'Modifier l\'expérience';

  @override
  String get uexpSectionPhotos => 'Photos';

  @override
  String get uexpSectionBasics => 'À propos de l\'expérience';

  @override
  String get uexpSectionPractical => 'Infos pratiques';

  @override
  String get uexpMainPhoto => 'Photo principale (obligatoire)';

  @override
  String uexpMorePhotos(int max) {
    return 'jusqu\'à $max photos supplémentaires';
  }

  @override
  String get uexpFieldTitle => 'Titre';

  @override
  String get uexpFieldDescription => 'Description';

  @override
  String get uexpFieldCategory => 'Catégorie';

  @override
  String get uexpIncluded => 'Ce qui est inclus';

  @override
  String get uexpNotIncluded => 'Ce qui n\'est pas inclus';

  @override
  String get uexpAddItem => 'Ajouter un élément';

  @override
  String get uexpRemoveItem => 'Supprimer l\'élément';

  @override
  String get uexpItemHint => 'ex. Snacks locaux';

  @override
  String get uexpFieldLocation => 'Lieu';

  @override
  String get uexpLocationHint =>
      'Saisissez un lieu ou choisissez-le sur la carte';

  @override
  String get uexpPickOnMap => 'Choisir sur la carte';

  @override
  String get uexpMeetingPoint => 'Point de rendez-vous (facultatif)';

  @override
  String get uexpMeetingPointLabel => 'Point de rendez-vous';

  @override
  String get uexpLocationNotFound =>
      'Nous n\'avons pas trouvé ce lieu sur la carte. Il est enregistré tel quel et n\'apparaîtra pas dans les résultats à proximité.';

  @override
  String get uexpDuration => 'Durée';

  @override
  String get uexpHours => 'Heures';

  @override
  String get uexpMinutes => 'Minutes';

  @override
  String uexpDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String uexpDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get uexpLanguages => 'Langues parlées';

  @override
  String get uexpGroupSize => 'Taille du groupe';

  @override
  String get uexpMinGroup => 'Min. personnes (facultatif)';

  @override
  String get uexpMaxGroup => 'Max. personnes';

  @override
  String uexpGroupSizeRange(int min, int max) {
    return '$min–$max personnes';
  }

  @override
  String uexpGroupUpTo(int max) {
    return 'Jusqu\'à $max personnes';
  }

  @override
  String get uexpPrice => 'Prix';

  @override
  String get uexpCurrency => 'Devise';

  @override
  String get uexpIsFree => 'Cette expérience est gratuite';

  @override
  String get uexpPaymentLink => 'Comment les participants vous paient';

  @override
  String get uexpPaymentType => 'Moyen de paiement';

  @override
  String get uexpPayPix => 'PIX';

  @override
  String get uexpPayPaypal => 'PayPal';

  @override
  String get uexpPayVenmo => 'Venmo';

  @override
  String get uexpPayStripe => 'Lien de paiement Stripe';

  @override
  String get uexpPayOther => 'Autre lien de paiement';

  @override
  String get uexpPaymentValuePix => 'Clé PIX';

  @override
  String get uexpPaymentValueUrl => 'Lien de paiement';

  @override
  String get uexpPaymentValueHintPix =>
      'E-mail, téléphone, CPF ou clé aléatoire';

  @override
  String get uexpPaymentDisclaimer =>
      'Les paiements se font en dehors de GreenGo, directement entre les participants et l\'hôte. GreenGo ne les traite pas, ne les garantit pas et ne les rembourse pas.';

  @override
  String get uexpAvailability => 'Disponibilités (facultatif)';

  @override
  String get uexpAvailabilityLabel => 'Disponibilités';

  @override
  String get uexpAvailabilityHint => 'ex. le samedi 10:00–13:00';

  @override
  String get uexpCancellation => 'Conditions d\'annulation (facultatif)';

  @override
  String get uexpCancellationLabel => 'Conditions d\'annulation';

  @override
  String get uexpSaveDraft => 'Enregistrer comme brouillon';

  @override
  String get uexpPublish => 'Publier';

  @override
  String get uexpSaveChanges => 'Enregistrer';

  @override
  String get uexpUnpublish => 'Dépublier';

  @override
  String get uexpSaved => 'Expérience enregistrée';

  @override
  String get uexpPublished => 'Expérience publiée';

  @override
  String get uexpUnpublished => 'Expérience déplacée dans les brouillons';

  @override
  String get uexpSaveFailed =>
      'Impossible d\'enregistrer l\'expérience. Veuillez réessayer.';

  @override
  String get uexpPhotoUploadFailed =>
      'Impossible de téléverser les photos. Veuillez réessayer.';

  @override
  String uexpErrTitle(int min, int max) {
    return 'Le titre doit comporter entre $min et $max caractères';
  }

  @override
  String uexpErrDescription(int min, int max) {
    return 'La description doit comporter entre $min et $max caractères';
  }

  @override
  String get uexpErrMainPhoto => 'Ajoutez une photo principale';

  @override
  String uexpErrTooManyPhotos(int max) {
    return 'Jusqu\'à $max photos supplémentaires';
  }

  @override
  String get uexpErrIncluded => 'Ajoutez au moins un élément inclus';

  @override
  String uexpErrTooManyItems(int max) {
    return 'Jusqu\'à $max éléments';
  }

  @override
  String uexpErrItemTooLong(int max) {
    return 'Chaque élément peut comporter jusqu\'à $max caractères';
  }

  @override
  String get uexpErrLocation => 'Indiquez un lieu';

  @override
  String get uexpErrDuration =>
      'Indiquez une durée entre 15 minutes et 14 jours';

  @override
  String get uexpErrLanguages => 'Choisissez au moins une langue';

  @override
  String uexpErrMaxGroup(int max) {
    return 'Le nombre max. de personnes doit être compris entre 1 et $max';
  }

  @override
  String get uexpErrMinGroup =>
      'Le minimum doit être au moins 1 et ne pas dépasser le maximum';

  @override
  String get uexpErrPrice => 'Indiquez un prix valide';

  @override
  String get uexpErrPaymentRequired =>
      'Indiquez comment vous payer (ou marquez l\'expérience comme gratuite)';

  @override
  String get uexpErrPaymentInvalid =>
      'Saisissez un lien valide commençant par https://';

  @override
  String get uexpErrProhibited =>
      'Un texte contient des propos non autorisés sur GreenGo';

  @override
  String get uexpErrNoLinks =>
      'Les liens ne sont pas autorisés dans les avis et les réponses';

  @override
  String uexpErrTooLong(int max) {
    return 'Jusqu\'à $max caractères';
  }

  @override
  String get uexpErrFixFields => 'Veuillez corriger les champs signalés';

  @override
  String get uexpLimitFeature => 'Proposez des expériences';

  @override
  String get uexpLimitFreeBody =>
      'Proposer des expériences est disponible avec un abonnement Silver, Gold ou Platinum.';

  @override
  String uexpLimitReachedBody(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Votre formule permet $limit expériences.',
      one: 'Votre formule permet 1 expérience.',
    );
    return '$_temp0 Passez à une formule supérieure pour en créer davantage.';
  }

  @override
  String get uexpUpgradeToCreateMore =>
      'Passez à la formule supérieure pour créer plus d’expériences';

  @override
  String get shopExperiencesCreate => 'Expériences que vous pouvez créer';

  @override
  String get uexpHostedBy => 'Proposée par';

  @override
  String get uexpHostBadge => 'Hôte';

  @override
  String get uexpPayBook => 'Payer / Réserver';

  @override
  String get uexpPixCopied => 'Clé PIX copiée dans le presse-papiers';

  @override
  String get uexpOpenLinkFailed => 'Impossible d\'ouvrir le lien';

  @override
  String get uexpShare => 'Partager';

  @override
  String uexpShareText(String title, String link) {
    return '$title\nDécouvrez cette expérience sur GreenGo : $link';
  }

  @override
  String get uexpReport => 'Signaler';

  @override
  String get uexpReportTitle => 'Signaler cette expérience ?';

  @override
  String get uexpReportBody =>
      'Notre équipe la vérifiera au regard des règles de GreenGo.';

  @override
  String get uexpReported => 'Merci, nous allons vérifier.';

  @override
  String get uexpReportReview => 'Signaler l\'avis';

  @override
  String get uexpEdit => 'Modifier';

  @override
  String get uexpDelete => 'Supprimer';

  @override
  String get uexpDeleteConfirmTitle => 'Supprimer cette expérience ?';

  @override
  String get uexpDeleteConfirmBody =>
      'Ses avis seront aussi supprimés. Cette action est irréversible.';

  @override
  String get uexpDeleted => 'Expérience supprimée';

  @override
  String get uexpNotFound => 'Cette expérience n\'est plus disponible.';

  @override
  String get uexpReviews => 'Avis';

  @override
  String get uexpNoReviews => 'Pas encore d\'avis';

  @override
  String get uexpWriteReview => 'Écrire un avis';

  @override
  String get uexpEditReview => 'Modifier votre avis';

  @override
  String get uexpYourRating => 'Votre note';

  @override
  String get uexpSelectRating => 'Choisissez de 1 à 5 étoiles';

  @override
  String get uexpCommentHint => 'Dites ce qui vous a plu (facultatif)';

  @override
  String get uexpSubmit => 'Envoyer';

  @override
  String get uexpDeleteReview => 'Supprimer l\'avis';

  @override
  String get uexpDeleteReviewConfirm => 'Supprimer votre avis ?';

  @override
  String get uexpReviewSaved => 'Avis enregistré';

  @override
  String get uexpReviewDeleted => 'Avis supprimé';

  @override
  String get uexpReviewRemoved =>
      'Votre avis a été retiré car il enfreint les règles de GreenGo. Modifiez-le pour réessayer.';

  @override
  String get uexpReplyRemoved =>
      'Votre réponse a été retirée car elle enfreint les règles de GreenGo.';

  @override
  String get uexpPendingModeration => 'Vérification en cours…';

  @override
  String get uexpHostCannotReview =>
      'Les hôtes ne peuvent pas évaluer leur propre expérience.';

  @override
  String get uexpReply => 'Répondre';

  @override
  String get uexpReplyHint =>
      'Écrivez une réponse. Tapez @ pour identifier quelqu’un';

  @override
  String get uexpShowMoreReplies => 'Afficher plus de réponses';

  @override
  String get uexpLoadMoreReviews => 'Charger plus d\'avis';

  @override
  String get uexpEdited => 'modifié';

  @override
  String get feedFilterTooltip => 'Afficher';

  @override
  String get feedFilterAll => 'Tout';

  @override
  String get feedFilterCommunity => 'Communauté';

  @override
  String get feedFilterPartner => 'Partenaires';

  @override
  String get feedFilterMyEvents => 'Mes événements';

  @override
  String get feedFilterMyExperiences => 'Mes expériences';

  @override
  String get partnerBadge => 'Partenaire';

  @override
  String get createChooserTitle => 'Que voulez-vous créer ?';

  @override
  String get createChooserEventDesc =>
      'Organisez une rencontre ou une activité ouverte aux gens près de vous';

  @override
  String get createChooserExperienceDesc =>
      'Proposez une visite, un cours ou une expérience locale en tant qu\'hôte';

  @override
  String get uexpAddExperience => 'Ajouter une expérience';

  @override
  String get uexpNewHost => 'Nouvel hôte';

  @override
  String uexpHostRatings(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText notes',
      one: '$countText note',
    );
    return '$_temp0';
  }

  @override
  String get verifiedBadgeLabel => 'Vérifié';

  @override
  String get verifiedBadgeTooltip => 'Identité vérifiée par GreenGo';

  @override
  String get idDocumentRetentionNotice =>
      'À des fins de prévention de la fraude et pour la sécurité de la communauté, les documents d\'identité sont conservés jusqu\'à 30 jours après la suppression du compte, puis définitivement effacés.';

  @override
  String get uexpErrContactInfo =>
      'Retire numéros de téléphone, e-mails, @pseudos et coordonnées de paiement : les invités paient uniquement via les moyens indiqués sur ton annonce.';

  @override
  String get uexpErrPaymentMethods => 'Choisis au moins un moyen de paiement';

  @override
  String get uexpPaymentLinkDetails => 'Lien de paiement en ligne';

  @override
  String get uexpMethodCash => 'En espèces au rendez-vous';

  @override
  String get uexpMethodLink => 'Lien en ligne (PIX/PayPal/…)';

  @override
  String get uexpBook => 'Réserver';

  @override
  String get uexpBookedCash =>
      'C\'est noté. Paie l\'hôte en espèces au rendez-vous.';

  @override
  String get uexpIdDocTitle => 'Pièce d\'identité requise';

  @override
  String get uexpIdDocGuestBody =>
      'Pour garder GreenGo sûr, ajoute une pièce d\'identité avant de payer un hôte.';

  @override
  String get uexpIdDocHostBody =>
      'Les hôtes doivent ajouter une pièce d\'identité avant de créer une expérience.';

  @override
  String get uexpIdDocUpload => 'Ajouter le document';

  @override
  String get uexpPaidPendingTitle => 'Vérification de l\'identité en cours';

  @override
  String get uexpPaidPendingBody =>
      'Les expériences payantes exigent une pièce d\'identité approuvée. La tienne est encore en cours de vérification : enregistre celle-ci comme brouillon ou publie-la gratuitement pour l\'instant.';

  @override
  String get uexpPaidMissingBody =>
      'Les expériences payantes exigent une pièce d\'identité approuvée. Ajoutes-en une (ou une nouvelle si elle a été refusée), ou enregistre celle-ci comme brouillon ou publie-la gratuitement pour l\'instant.';

  @override
  String get uexpNewHostLimitTitle => 'Limite pour les nouveaux hôtes';

  @override
  String get uexpNewHostLimitBody =>
      'Tant que tu n\'as pas 3 avis, tu peux avoir une seule expérience payante publiée. Enregistre celle-ci comme brouillon ou publie-la gratuitement.';

  @override
  String get uexpPublishAsFree => 'Publier gratuitement';

  @override
  String get uexpHostBanned =>
      'Ton compte ne peut pas proposer d\'expériences.';

  @override
  String get hostAgreementTitle => 'Accord de l\'hôte';

  @override
  String get hostAgreementIntro =>
      'Avant de publier ta première expérience, lis et accepte ces règles.';

  @override
  String get hostAgreementClause1 =>
      'Tu organises et animes cette expérience et tu es responsable de celle-ci et de la sécurité de tes invités.';

  @override
  String get hostAgreementClause2 =>
      'Décris-la fidèlement : titre, photos, prix, durée, ce qui est inclus et le point de rendez-vous doivent être exacts et à jour.';

  @override
  String get hostAgreementClause3 =>
      'Respecte la loi : tu disposes des licences, autorisations, assurances ou immatriculations exigées pour ton activité là où elle a lieu, et tu déclares tes revenus comme requis.';

  @override
  String get hostAgreementClause4 =>
      'Rembourse les invités selon la politique d\'annulation choisie, et toujours intégralement si c\'est toi qui annules.';

  @override
  String get hostAgreementClause5 =>
      'Ne demande jamais aux invités de payer en dehors des moyens indiqués sur ton annonce, et ne mets jamais de numéros, d\'e-mails ou d\'identifiants de paiement dans le texte de l\'annonce.';

  @override
  String get hostAgreementClause6 =>
      'Traite les invités avec respect : aucune discrimination, aucun harcèlement, aucune situation dangereuse.';

  @override
  String get hostAgreementClause7 =>
      'GreenGo peut masquer ou supprimer des annonces et suspendre ou bannir les comptes qui enfreignent ces règles ou font l\'objet de signalements crédibles.';

  @override
  String get hostAgreementCheckbox =>
      'J\'ai lu et j\'accepte l\'accord de l\'hôte';

  @override
  String get hostAgreementAccept => 'Accepter et continuer';

  @override
  String get uexpConsentTitle => 'Avant de payer';

  @override
  String get uexpConsentBodyLink =>
      'Tu paies l\'hôte directement. GreenGo ne traite ni ne garantit ce paiement et ne peut pas le rembourser. Privilégie les moyens protégés (PayPal Biens et services, carte bancaire). Ne paie jamais en dehors du lien affiché ici.';

  @override
  String get uexpConsentBodyCash =>
      'Tu paieras l\'hôte en espèces au rendez-vous. GreenGo ne traite ni ne garantit ce paiement et ne peut pas le rembourser. Compte l\'argent, demande un reçu si besoin et ne paie jamais à l\'avance en dehors des moyens indiqués sur cette page.';

  @override
  String get uexpConsentPickMethod => 'Comment vas-tu payer ?';

  @override
  String uexpConsentPolicy(String policy) {
    return 'Politique d\'annulation : $policy';
  }

  @override
  String get uexpConsentUnderstand => 'J\'ai compris';

  @override
  String get uexpConsentContinue => 'Continuer';

  @override
  String get uexpGuidePix =>
      'PIX : si tu es victime d\'une arnaque, demande immédiatement à ta banque d\'ouvrir une réclamation MED (Mecanismo Especial de Devolução).';

  @override
  String get uexpGuidePaypal =>
      'PayPal : choisis « Biens et services », jamais « Amis et famille », pour garder la protection des achats.';

  @override
  String get uexpGuideVenmo =>
      'Venmo : utilise la protection des achats (biens et services) quand elle est disponible.';

  @override
  String get uexpGuideCard =>
      'Les paiements par carte peuvent être contestés auprès de l\'émetteur de ta carte.';

  @override
  String get uexpGuideCash =>
      'Ne paie qu\'au moment de rencontrer l\'hôte, comptez l\'argent ensemble et demande un reçu si besoin.';

  @override
  String get uexpPolicyFlexible => 'Flexible';

  @override
  String get uexpPolicyModerate => 'Modérée';

  @override
  String get uexpPolicyStrict => 'Stricte';

  @override
  String get uexpPolicyFlexibleDesc =>
      'Remboursement intégral si vous annulez au moins 24 h avant le début ; aucun remboursement ensuite.';

  @override
  String get uexpPolicyModerateDesc =>
      'Remboursement intégral si vous annulez au moins 7 jours avant ; 50 % si au moins 24 h avant ; aucun remboursement ensuite.';

  @override
  String get uexpPolicyStrictDesc =>
      'Remboursement intégral si vous annulez au moins 7 jours avant ; aucun remboursement ensuite.';

  @override
  String get uexpPolicyWhen => 'Si tu annules';

  @override
  String get uexpPolicyRefund => 'Remboursement';

  @override
  String get uexpPolicyMoreThan7d => '7 jours ou plus avant';

  @override
  String get uexpPolicy7dTo24h => 'Moins de 7 jours, mais au moins 24 h avant';

  @override
  String get uexpPolicyMoreThan24h => '24 h ou plus avant';

  @override
  String get uexpPolicyLess24h => 'Moins de 24 h avant';

  @override
  String get uexpPolicyLess7d => 'Moins de 7 jours avant';

  @override
  String get uexpPolicyAlwaysTitle => 'S\'applique toujours';

  @override
  String get uexpRuleHostCancels => 'L\'hôte annule : remboursement à 100 %.';

  @override
  String get uexpRuleGrace =>
      'Vous annulez dans les 24 h suivant la confirmation de votre réservation par l\'hôte, et l\'expérience a lieu dans plus de 48 h : remboursement à 100 %.';

  @override
  String get uexpRuleReport =>
      'Hôte absent ou expérience non conforme : signale-le dans les 24 h.';

  @override
  String get uexpPolicyNotes => 'Remarques sur ta politique (facultatif)';

  @override
  String get uexpPolicyHostNotes => 'Remarques de l\'hôte';

  @override
  String get uexpReportScamTitle => 'Signaler cette expérience';

  @override
  String get uexpReasonScam => 'Arnaque ou fraude';

  @override
  String get uexpReasonOffPlatform => 'Demande de payer hors de l\'app';

  @override
  String get uexpReasonMisleading => 'Non conforme à la description';

  @override
  String get uexpReasonNoShow => 'L\'hôte n\'est pas venu';

  @override
  String get uexpReasonInappropriate => 'Inapproprié';

  @override
  String get uexpReasonOther => 'Autre';

  @override
  String get uexpReportDetailsHint => 'Que s\'est-il passé ? (facultatif)';

  @override
  String get uexpReportSend => 'Envoyer le signalement';

  @override
  String get bkStatusRequested => 'Demandée';

  @override
  String get bkStatusConfirmed => 'Confirmée';

  @override
  String get bkStatusDeclined => 'Refusée';

  @override
  String get bkStatusExpired => 'Expirée';

  @override
  String get bkStatusCancelledGuest => 'Annulée par l\'invité';

  @override
  String get bkStatusCancelledHost => 'Annulée par l\'hôte';

  @override
  String get bkStatusCompleted => 'Terminée';

  @override
  String get bkStatusNoShow => 'Absent';

  @override
  String get bkStatusDisputed => 'Problème signalé';

  @override
  String get bkStatusResolved => 'Résolue';

  @override
  String get bkStatusUnknown => 'Inconnu';

  @override
  String get bkRequestToBook => 'Demander à réserver';

  @override
  String get bkChooseDate => 'Choisissez une date';

  @override
  String get bkNoDates => 'Aucune date disponible pour le moment.';

  @override
  String bkDatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates disponibles',
      one: '1 date disponible',
    );
    return '$_temp0';
  }

  @override
  String bkSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places restantes',
      one: '1 place restante',
    );
    return '$_temp0';
  }

  @override
  String get bkFull => 'Complet';

  @override
  String get bkGuests => 'Invités';

  @override
  String bkGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invités',
      one: '1 invité',
    );
    return '$_temp0';
  }

  @override
  String bkMaxGuests(int max) {
    return 'Jusqu\'à $max à cette date';
  }

  @override
  String get bkSummary => 'Récapitulatif';

  @override
  String get bkRequestInfo =>
      'L\'hôte a jusqu\'à 48 h pour accepter ta demande. Rien n\'est payé avant son accord.';

  @override
  String get bkInstantInfo =>
      'Réservation instantanée : confirmée immédiatement.';

  @override
  String get bkConfirmBooking => 'Confirmer la réservation';

  @override
  String get bkSendRequest => 'Envoyer la demande';

  @override
  String get bkRetry => 'Réessayer';

  @override
  String get bkResultConfirmedTitle => 'C\'est réservé !';

  @override
  String get bkResultConfirmedBody =>
      'Montre ton code d\'enregistrement à l\'hôte quand vous vous retrouvez. Tu le trouves dans Mes réservations.';

  @override
  String get bkResultRequestTitle => 'Demande envoyée';

  @override
  String get bkResultRequestBody =>
      'Nous te préviendrons dès que l\'hôte répondra (sous 48 h).';

  @override
  String get bkViewBooking => 'Voir la réservation';

  @override
  String get bkDone => 'Terminé';

  @override
  String get bkPayment => 'Paiement';

  @override
  String get bkCashAtMeeting => 'Paie l\'hôte en espèces lors de la rencontre.';

  @override
  String get bkPayLinkHint =>
      'Paie l\'hôte avec son lien, puis touche « Marquer comme payée » dans ta réservation.';

  @override
  String get bkPayAfterAccept =>
      'Tu paieras avec le lien de l\'hôte dès qu\'il aura accepté ta demande.';

  @override
  String get bkPayNow => 'Ouvrir le lien de paiement';

  @override
  String get bkCopyPixKey => 'Copier la clé PIX';

  @override
  String get bkMyBookings => 'Mes réservations';

  @override
  String get bkHostBookings => 'Réservations reçues';

  @override
  String get bkUpcoming => 'À venir';

  @override
  String get bkPast => 'Passées';

  @override
  String get bkNoUpcoming => 'Aucune réservation à venir.';

  @override
  String get bkNoPast => 'Aucune réservation passée.';

  @override
  String get bkBookings => 'Réservations';

  @override
  String get bkViewBookings => 'Voir les réservations';

  @override
  String get bkDetailTitle => 'Réservation';

  @override
  String get bkNotFound => 'Cette réservation n\'est pas disponible.';

  @override
  String get bkExperienceGone => 'Cette expérience n\'est plus en ligne.';

  @override
  String get bkOpenExperience => 'Ouvrir l\'expérience';

  @override
  String get bkGuest => 'Invité';

  @override
  String get bkCheckedIn => 'Enregistré';

  @override
  String bkAnswerBefore(String date) {
    return 'Réponds avant le $date';
  }

  @override
  String get bkWaitingForHost => 'En attente de la réponse de l\'hôte.';

  @override
  String get bkRequestTitle => 'Demande de réservation';

  @override
  String get bkRequestHostHint =>
      'Consulte le profil et la note de l\'invité, puis accepte ou refuse. Sans réponse, la demande expire après 48 h.';

  @override
  String get bkAccept => 'Accepter';

  @override
  String get bkDecline => 'Refuser';

  @override
  String get bkDeclineConfirm => 'Refuser cette demande ?';

  @override
  String get bkDeclineBody =>
      'L\'invité est prévenu et les places sont libérées.';

  @override
  String get bkAccepted => 'Réservation acceptée';

  @override
  String get bkDeclined => 'Demande refusée';

  @override
  String get bkCheckInTitle => 'Enregistrement';

  @override
  String get bkShowCode => 'Afficher le code d\'enregistrement';

  @override
  String get bkCodeTitle => 'Ton code d\'enregistrement';

  @override
  String get bkCodeHint =>
      'Montre ce QR code à l\'hôte lors de la rencontre. Il peut aussi saisir le code.';

  @override
  String get bkCheckInGuest => 'Enregistrer l\'invité';

  @override
  String get bkScanQr => 'Scanner le QR code';

  @override
  String get bkTypeCode => 'Saisir le code';

  @override
  String get bkCodeLabel => 'Code d\'enregistrement';

  @override
  String get bkScanInstructions =>
      'Dirige l\'appareil photo vers le QR code de l\'invité';

  @override
  String get bkWrongBooking => 'Ce QR code correspond à une autre réservation.';

  @override
  String get bkTorch => 'Flash';

  @override
  String get bkSwitchCamera => 'Changer de caméra';

  @override
  String get bkCashReceivedQuestion =>
      'As-tu aussi reçu le paiement en espèces ?';

  @override
  String get bkCashYes => 'Oui, reçu';

  @override
  String get bkCashNo => 'Pas encore';

  @override
  String get bkCheckedInSnack => 'Invité enregistré';

  @override
  String get bkMarkNoShow => 'Marquer comme absent';

  @override
  String get bkNoShowConfirm =>
      'Marquer l\'invité comme absent ? Aucun remboursement n\'est dû et il peut contester jusqu\'à 24 h après la fin.';

  @override
  String get bkNoShowMarked => 'Marqué comme absent';

  @override
  String get bkNotPaidYet => 'Pas encore marquée comme payée.';

  @override
  String get bkYouMarkedPaid =>
      'Tu l\'as marquée comme payée. En attente de la confirmation de l\'hôte.';

  @override
  String get bkGuestSaysPaid =>
      'L\'invité indique avoir payé. Confirme dès réception.';

  @override
  String get bkPaymentConfirmed => 'Paiement confirmé par l\'hôte.';

  @override
  String get bkCashConfirmed => 'Espèces reçues (confirmé par l\'hôte).';

  @override
  String get bkMarkPaid => 'Marquer comme payée';

  @override
  String get bkConfirmPayment => 'Paiement reçu';

  @override
  String get bkCashReceived => 'Espèces reçues';

  @override
  String get bkPaidMarked => 'Marquée comme payée';

  @override
  String get bkPaymentConfirmedSnack => 'Paiement confirmé';

  @override
  String get bkRefundTitle => 'Remboursement';

  @override
  String bkRefundOwed(String percent, String amount) {
    return 'L\'hôte te doit $percent de remboursement ($amount).';
  }

  @override
  String get bkRefundNone =>
      'Aucun remboursement n\'est dû selon les conditions d\'annulation.';

  @override
  String get bkRefundCashUnpaid =>
      'Aucun remboursement n\'est dû : les espèces n\'ont jamais été payées.';

  @override
  String get bkRefundOffPlatform =>
      'GreenGo ne gère pas l\'argent : l\'hôte te rembourse directement, par le moyen utilisé pour payer.';

  @override
  String bkIfCancelNow(String percent, String amount) {
    return 'Si tu annules maintenant : $percent remboursés ($amount).';
  }

  @override
  String get bkIfCancelNowNothing =>
      'Si tu annules maintenant, aucun remboursement n\'est dû.';

  @override
  String get bkIfCancelNowCash =>
      'Les espèces se paient lors de la rencontre : annuler maintenant ne coûte rien.';

  @override
  String get bkIfCancelNowFree =>
      'Expérience gratuite : tu peux annuler sans frais.';

  @override
  String get bkCancelRequestNoCharge =>
      'L\'hôte n\'a pas encore accepté : annuler la demande ne coûte rien.';

  @override
  String get bkHostCancelWarning =>
      'Si tu annules, l\'invité a droit à 100 % et cela compte comme annulation d\'hôte (GreenGo examine 3 annulations en 90 jours).';

  @override
  String get bkCancelBooking => 'Annuler la réservation';

  @override
  String get bkCancelConfirmTitle => 'Annuler cette réservation ?';

  @override
  String get bkCancelReasonHint => 'Raison (facultatif)';

  @override
  String get bkKeepBooking => 'Garder la réservation';

  @override
  String get bkCancelled => 'Réservation annulée';

  @override
  String get bkReportProblem => 'Signaler un problème';

  @override
  String get bkDisputeIntro =>
      'L\'hôte n\'est pas venu ou l\'expérience ne correspondait pas ? Préviens-nous dans les 24 h après la fin, notre équipe examinera.';

  @override
  String get bkDisputeHint => 'Que s\'est-il passé ? (10 caractères minimum)';

  @override
  String get bkSendReport => 'Envoyer le signalement';

  @override
  String get bkDisputeSent =>
      'Merci. Notre équipe va examiner et vous contacter tous les deux.';

  @override
  String get bkDisputeOpen =>
      'Un problème a été signalé. Notre équipe examine la situation.';

  @override
  String bkDisputeResolved(String percent) {
    return 'Examiné par GreenGo : $percent de remboursement dû.';
  }

  @override
  String get bkReviewGuest => 'Évalue ton invité';

  @override
  String get bkReviewGuestIntro =>
      'Aide les autres hôtes : comment s\'est passé l\'accueil de cet invité ? Les deux avis restent masqués jusqu\'à ce que ton invité évalue aussi, ou pendant 14 jours.';

  @override
  String get bkReviewGuestHint => 'Ponctuel, respectueux, sympa ? (facultatif)';

  @override
  String get bkGuestReviewSaved =>
      'Merci ! Les avis seront publiés quand ton invité aura évalué aussi, ou dans 14 jours.';

  @override
  String get bkGuestReviewed => 'Ton avis sur cet invité';

  @override
  String get bkGuestReviewHeld =>
      'Masqué jusqu\'à ce que ton invité évalue aussi, ou pendant 14 jours.';

  @override
  String get bkReviewExperience => 'Évaluer l\'expérience';

  @override
  String get bkReviewExperienceHint =>
      'Raconte comment ça s\'est passé : ton avis aide d\'autres voyageurs.';

  @override
  String get bkReviewHeld =>
      'Ton avis sera publié quand l\'hôte t\'aura évalué aussi, ou dans 14 jours.';

  @override
  String get bkReviewNeedsBooking =>
      'Seuls les invités ayant participé via une réservation peuvent évaluer cette expérience.';

  @override
  String get bkNewGuest => 'Nouvel invité';

  @override
  String get bkDatesTitle => 'Dates et disponibilités';

  @override
  String get bkAddDate => 'Ajouter une date';

  @override
  String get bkEditDate => 'Modifier la date';

  @override
  String get bkDeleteDate => 'Supprimer la date';

  @override
  String get bkCancelDate => 'Annuler la date';

  @override
  String get bkKeepDate => 'Garder la date';

  @override
  String get bkCancelDateTitle => 'Annuler cette date ?';

  @override
  String bkCancelDateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les $count places réservées à cette date sont annulées et chaque invité a droit à un remboursement de 100 %.',
      one:
          'La réservation de cette date est annulée et l\'invité a droit à un remboursement de 100 %.',
    );
    return '$_temp0 Cela compte comme une annulation d\'hôte.';
  }

  @override
  String get bkDateSaved => 'Date enregistrée';

  @override
  String get bkDateDeleted => 'Date supprimée';

  @override
  String bkDateCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Date annulée : $count réservations annulées',
      one: 'Date annulée : 1 réservation annulée',
      zero: 'Date annulée',
    );
    return '$_temp0';
  }

  @override
  String get bkNoDatesHost =>
      'Aucune date à venir. Ajoute les dates que les invités peuvent réserver.';

  @override
  String get bkRequestToBookToggle => 'Réservation sur demande';

  @override
  String get bkRequestToBookDesc =>
      'Tu acceptes ou refuses chaque réservation (sous 48 h). Désactivé : les invités réservent instantanément.';

  @override
  String get bkDatesAfterSave =>
      'Enregistre d\'abord l\'expérience, puis ajoute ses dates depuis Mes expériences.';

  @override
  String get bkDate => 'Date';

  @override
  String get bkStartTime => 'Début';

  @override
  String get bkEndTime => 'Fin';

  @override
  String get bkCapacity => 'Places';

  @override
  String bkBookedOf(int booked, int capacity) {
    return '$booked/$capacity réservées';
  }

  @override
  String get bkSlotCancelled => 'Annulée';

  @override
  String get bkTimesFrozen =>
      'Des invités ont réservé cette date : seul le nombre de places peut changer. Pour la déplacer, annule la date.';

  @override
  String get bkSlotSaveFailed =>
      'Impossible d\'enregistrer la date. Vérifie ta connexion et réessaie.';

  @override
  String get bkSlotErrPast => 'Choisis une heure de début future.';

  @override
  String get bkSlotErrEnd => 'La fin doit être après le début.';

  @override
  String get bkSlotErrTooLong => 'Une date peut durer 24 h maximum.';

  @override
  String get bkSlotErrTooFar =>
      'Les dates peuvent être fixées au maximum un an à l\'avance.';

  @override
  String bkSlotErrCapacity(int max) {
    return 'Places : de 1 à $max.';
  }

  @override
  String bkSlotErrBelowBooked(int count) {
    return '$count places sont déjà réservées : garde-en au moins autant.';
  }

  @override
  String bkErrSlotFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plus que $count places à cette date.',
      one: 'Plus qu\'1 place à cette date.',
      zero: 'Cette date est complète.',
    );
    return '$_temp0';
  }

  @override
  String get bkErrAlreadyBooked =>
      'Tu as déjà une réservation pour cette date.';

  @override
  String get bkErrIdRequired => 'Envoie une pièce d\'identité pour réserver.';

  @override
  String get bkErrHostNotVerified =>
      'Cet hôte ne peut pas encore accepter de réservations payantes (identité non vérifiée).';

  @override
  String get bkErrPaymentMethodRequired => 'Choisis comment tu vas payer.';

  @override
  String get bkErrPaymentMethodNotAccepted =>
      'L\'hôte n\'accepte plus ce moyen de paiement. Choisis-en un autre.';

  @override
  String get bkErrOwnExperience =>
      'Tu ne peux pas réserver ta propre expérience.';

  @override
  String get bkErrNotAvailable =>
      'Cette expérience n\'est pas disponible pour toi.';

  @override
  String get bkErrSlotStarted => 'Cette date a déjà commencé.';

  @override
  String get bkErrSlotClosed => 'Cette date n\'est plus disponible.';

  @override
  String get bkErrNotBookable =>
      'Cette expérience ne peut pas être réservée pour le moment.';

  @override
  String get bkErrPriceInvalid =>
      'Le prix de cette annonce est incomplet. Demande à l\'hôte de le mettre à jour.';

  @override
  String get bkErrHostUnavailable =>
      'L\'hôte n\'accepte pas de réservations pour le moment.';

  @override
  String get bkErrConsentRequired =>
      'Accepte d\'abord les conditions de réservation.';

  @override
  String bkErrTooManyGuests(int max) {
    return '$max invités maximum par réservation.';
  }

  @override
  String get bkErrAccountRestricted =>
      'Ton compte ne peut pas réserver pour le moment.';

  @override
  String get bkErrNetwork =>
      'Problème de connexion. Réessaie : tu ne seras pas réservé deux fois.';

  @override
  String get bkErrRequestExpired => 'Cette demande a expiré.';

  @override
  String get bkErrStateChanged =>
      'Cette réservation a changé entre-temps. Tire vers le bas pour actualiser.';

  @override
  String get bkErrInvalidCode =>
      'Ce code d\'enregistrement n\'est pas valable pour cette réservation.';

  @override
  String get bkErrOutsideCheckIn =>
      'L\'enregistrement ouvre 2 h avant le début et ferme 12 h après la fin.';

  @override
  String get bkErrTooEarlyNoShow =>
      'Tu peux marquer une absence à partir de 30 min après le début.';

  @override
  String get bkErrGuestCheckedIn => 'L\'invité est déjà enregistré.';

  @override
  String get bkErrCashBeforeMeeting =>
      'Les espèces peuvent être confirmées une fois l\'invité rencontré.';

  @override
  String get bkErrOutsideDispute =>
      'Les problèmes peuvent être signalés du début jusqu\'à 24 h après la fin.';

  @override
  String bkErrReasonRequired(int min) {
    return 'Décris le problème ($min caractères minimum).';
  }

  @override
  String get uexpDatesRequiredHint =>
      'Les participants ne peuvent réserver que les dates que vous définissez, et chaque réservation est une demande que vous acceptez ou refusez. Ajoutez au moins une date à venir pour publier.';

  @override
  String get uexpDatesRequiredToPublish =>
      'Ajoutez au moins une date à venir pour publier. Votre expérience est enregistrée comme brouillon.';

  @override
  String bkRefundIfPaid(String percent, String amount) {
    return 'Si vous avez déjà payé, l\'hôte vous doit $percent ($amount).';
  }

  @override
  String get shareLinkCopied => 'Lien copié dans le presse-papiers';

  @override
  String shareOtherProfileMessage(String name, String link) {
    return 'Découvre $name sur GreenGo : $link';
  }

  @override
  String get communitiesExperiencesEmpty => 'Aucune expérience pour l\'instant';

  @override
  String uexpPostedInCommunity(String community) {
    return 'Publiée dans $community';
  }

  @override
  String get uexpErrCommunityNotAllowed =>
      'Seuls le propriétaire et les administrateurs de cette communauté peuvent publier des expériences ici.';

  @override
  String attrRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get attrNoRatingsYet => 'Pas encore de notes';

  @override
  String get attrRateThis => 'Notez cette attraction';

  @override
  String get attrYourRating => 'Votre note';

  @override
  String get attrRatingRemove => 'Retirer ma note';

  @override
  String get attrRatingFailed =>
      'Impossible d\'enregistrer votre note. Réessayez.';

  @override
  String get attrRatingGreengoLabel => 'Communauté GreenGo';

  @override
  String get attrRatingGoogleLabel => 'Note Google';

  @override
  String get webUpdateAvailable =>
      'Une nouvelle version de GreenGo est disponible.';

  @override
  String get webUpdateRefresh => 'Actualiser';

  @override
  String get webUpdateLater => 'Plus tard';

  @override
  String get userErrorTitle => 'Oups !';

  @override
  String get userErrorGeneric =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get userErrorTimeout =>
      'Cela prend plus de temps que prévu. Veuillez réessayer.';

  @override
  String get userErrorPermissionDenied =>
      'Vous n\'avez pas l\'autorisation de faire cela.';

  @override
  String get userErrorNotFound => 'Ce contenu n\'est plus disponible.';

  @override
  String get userErrorTooManyRequests =>
      'Vous effectuez cette action trop souvent. Patientez un instant et réessayez.';

  @override
  String get userErrorSessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get userErrorInvalidInput =>
      'Certaines informations ne sont pas valides. Vérifiez-les et réessayez.';

  @override
  String get userErrorNotAllowed =>
      'Cette action n\'est pas disponible pour le moment.';

  @override
  String get userErrorUploadFailed =>
      'Le téléversement a échoué. Veuillez réessayer.';

  @override
  String videoMaxDurationError(int seconds) {
    return 'La vidéo doit durer $seconds secondes maximum';
  }

  @override
  String get exploreLoadingContent =>
      'Nous cherchons le meilleur autour de vous…';

  @override
  String get checkinWrongPlace =>
      'Ce code concerne un autre événement ou une autre expérience';

  @override
  String get checkinOutsideWindow =>
      'L\'enregistrement n\'est pas ouvert pour le moment';

  @override
  String get checkinNotConfirmed => 'Cette personne n\'est pas confirmée';

  @override
  String get checkinUpdateApp =>
      'Ancien billet : demandez de mettre à jour GreenGo et de montrer le nouveau code';

  @override
  String get checkinNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get expDoorTitle => 'Enregistrer les invités';

  @override
  String get expDoorInstructions =>
      'Scannez le QR code de réservation de chaque invité';

  @override
  String expDoorCheckedInNow(int count) {
    return '$count enregistrés';
  }

  @override
  String expDoorAdmits(int count) {
    return 'Entrée pour $count personnes';
  }

  @override
  String get expDoorHelpers => 'Aides à l\'entrée';

  @override
  String get expDoorHelpersHint =>
      'Les membres ajoutés ici peuvent enregistrer les invités de cette expérience.';

  @override
  String expDoorHelpersMax(int max) {
    return 'Jusqu\'à $max aides';
  }

  @override
  String get expAttendanceTitle => 'Présences';

  @override
  String get expAttendanceEmpty =>
      'Pas encore d\'invités confirmés pour les prochaines dates.';

  @override
  String expAttendanceCount(int checked, int total) {
    return '$checked/$total présents';
  }

  @override
  String get qrHubExperienceTicket => 'Expérience';

  @override
  String metInPersonOn(String date) {
    return 'Rencontré en personne · $date';
  }

  @override
  String metInPersonTimes(int count, String date) {
    return 'Rencontré $count fois · dernière $date';
  }

  @override
  String get paymentLinksTitle => 'Moyens de paiement';

  @override
  String get paymentLinksNone => 'Aucun moyen de paiement ajouté';

  @override
  String paymentLinksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moyens de paiement',
      one: '1 moyen de paiement',
    );
    return '$_temp0';
  }

  @override
  String get paymentLinksInfoTitle => 'Soyez payé directement';

  @override
  String get paymentLinksInfoBody =>
      'Faites-vous payer sur vos propres comptes. L\'argent vous parvient directement : GreenGo ne traite pas, ne retient pas et ne prélève aucun frais sur ces paiements.';

  @override
  String get paymentLinksHintHandle => 'Nom d\'utilisateur ou lien';

  @override
  String get paymentLinksHintPix =>
      'CPF, CNPJ, e-mail, téléphone +55 ou clé aléatoire';

  @override
  String get paymentLinksHintLink => 'Collez votre lien de paiement';

  @override
  String paymentLinkInvalid(String method) {
    return 'Valeur $method invalide : vérifiez-la et réessayez';
  }

  @override
  String get paymentLinksUpdated => 'Moyens de paiement mis à jour';

  @override
  String get paymentLinksRules =>
      'À utiliser uniquement pour les paiements entre personnes (cadeaux, pourboires, services et visites en personne). Les pièces et abonnements GreenGo s\'achètent uniquement dans l\'app.';

  @override
  String get paymentLinksSection => 'Payer directement';

  @override
  String paymentDisclaimerTitle(String name) {
    return 'Payer $name directement';
  }

  @override
  String paymentDisclaimerBody(String name, String method) {
    return 'Ce paiement va de vous à $name via $method. GreenGo n\'intervient pas et ne peut ni le rembourser, ni le protéger, ni le vérifier. Ne payez que des personnes de confiance.';
  }

  @override
  String paymentContinueTo(String method) {
    return 'Continuer vers $method';
  }

  @override
  String get pixInstructions =>
      'Scannez le QR code ou copiez le code Pix dans l\'app de votre banque, puis saisissez-y le montant.';

  @override
  String get pixKeyLabel => 'Clé Pix';

  @override
  String get pixCopyCode => 'Copier le code Pix';

  @override
  String get pixCopyKey => 'Copier la clé';

  @override
  String get pixCopied =>
      'Copié : collez-le dans l\'espace Pix de l\'app de votre banque';

  @override
  String get bkRepeat => 'Répéter';

  @override
  String get bkRepeatHint =>
      'Ajoutez ces horaires sur plusieurs dates à la fois';

  @override
  String get bkRepeatThisDate => 'Répéter cette date';

  @override
  String get bkRepeatDates => 'Appliquer aux dates';

  @override
  String get bkRepeatPickRange => 'Choisissez les dates sur le calendrier';

  @override
  String get bkRepeatOnDays => 'Ces jours-là';

  @override
  String get bkRepeatEveryDay => 'Tous les jours';

  @override
  String bkRepeatPreview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates seront ajoutées',
      one: '1 date sera ajoutée',
      zero:
          'Aucune date ne correspond — choisissez une période plus large ou plus de jours',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatCapped(int max) {
    return 'jusqu\'à $max dates à la fois';
  }

  @override
  String bkRepeatAddButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count dates',
      one: 'Ajouter 1 date',
      zero: 'Ajouter des dates',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates ajoutées',
      one: '1 date ajoutée',
      zero: 'Aucune nouvelle date ajoutée',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count existaient déjà',
      one: '1 existait déjà',
    );
    return '$_temp0';
  }

  @override
  String get bkChooseTime => 'Choisissez un horaire';

  @override
  String get bkNoFreeTimes => 'Plus d\'horaires libres à cette date';

  @override
  String bkTimesHint(String duration) {
    return 'Chaque créneau dure $duration et est réservé à vous et votre groupe.';
  }

  @override
  String bkWindowHint(String duration) {
    return 'C\'est la période où vous êtes disponible. Chaque invité y réserve son propre créneau de $duration, et vos réservations ne se chevauchent jamais, sur toutes vos expériences.';
  }

  @override
  String bkWindowPeopleBooked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes réservées',
      one: '1 personne réservée',
      zero: 'Pas encore de réservation',
    );
    return '$_temp0';
  }

  @override
  String get bkErrTimeTaken =>
      'Ce créneau vient d\'être pris. Choisissez-en un autre.';

  @override
  String get bkErrInvalidStart =>
      'Ce créneau n\'est pas disponible à cette date.';

  @override
  String get coinsGiftPurchaseHold =>
      'Les pièces achetées au cours des 72 dernières heures ne peuvent pas encore être offertes. Tu peux toujours les utiliser pour des fonctionnalités.';

  @override
  String get coinsGiftDailyLimit =>
      'Tu as atteint la limite de cadeaux du jour (10 cadeaux ou 5 000 pièces). Réessaie demain.';

  @override
  String get coinReasonRefundClawback => 'Achat remboursé annulé';

  @override
  String get chatMessageDeleted => 'Message supprimé';

  @override
  String get aiConsentTitle =>
      'Les fonctions d\'IA utilisent des services Google';

  @override
  String get aiConsentIntro =>
      'Les réponses suggérées, le coach linguistique IA, la traduction des messages que vous recevez et la lecture à voix haute ne fonctionnent que si GreenGo envoie le texte concerné à Google.';

  @override
  String get aiConsentProviders =>
      'Qui : Google Gemini (suggestions et coaching), Google Cloud Text-to-Speech (audio) et Google Traduction (traductions).';

  @override
  String get aiConsentWhatSent =>
      'Ce qui est envoyé : uniquement le texte du message sur lequel vous utilisez la fonction (y compris les messages que d\'autres personnes vous ont envoyés) et les langues. Jamais votre nom, vos photos ni votre profil.';

  @override
  String get aiConsentWhy =>
      'Pourquoi : uniquement pour produire la suggestion, la traduction ou l\'audio que vous avez demandé.';

  @override
  String get aiConsentDeclineInfo =>
      'Si vous refusez, ces fonctions restent désactivées et rien n\'est envoyé. Touchez l\'une d\'elles plus tard pour revoir votre choix.';

  @override
  String get aiConsentAccept => 'Autoriser';

  @override
  String get aiConsentDecline => 'Refuser';

  @override
  String get aiConsentDisabledNotice =>
      'Cette fonction est désactivée car vous avez choisi de ne pas envoyer de texte aux services d\'IA de Google.';

  @override
  String get aiConsentReview => 'Revoir';

  @override
  String get profileDeleteReauthRequired =>
      'Pour votre sécurité, confirmez à nouveau votre mot de passe pour supprimer votre compte.';

  @override
  String get profileDeleteNetworkError =>
      'Pas de connexion. Votre compte n\'a pas été supprimé. Veuillez réessayer.';

  @override
  String get profileDeleteFailed =>
      'Nous n\'avons pas pu supprimer votre compte et rien n\'a été supprimé. Réessayez ou contactez l\'assistance.';

  @override
  String get onboardingAgeBlockedTitle => 'GreenGo est réservé aux adultes';

  @override
  String get onboardingAgeBlockedBody =>
      'Vous devez avoir au moins 18 ans pour utiliser GreenGo, nous ne pouvons donc pas créer votre compte.';

  @override
  String get distanceBucketUnder2Km => 'à moins de 2 km';

  @override
  String get distanceBucket2To5Km => 'à 2-5 km';

  @override
  String get distanceBucket5To10Km => 'à 5-10 km';

  @override
  String get distanceBucket10To25Km => 'à 10-25 km';

  @override
  String get distanceBucketOver25Km => 'à plus de 25 km';

  @override
  String distanceUnderKm(String km) {
    return '< $km km';
  }

  @override
  String distanceOverKm(String km) {
    return '$km+ km';
  }

  @override
  String get idConsentTitle => 'Avant de téléverser votre pièce d\'identité';

  @override
  String get idConsentWhat =>
      'Ce que nous traitons : une photo de votre pièce d\'identité. Nous en lisons automatiquement votre date de naissance et le numéro du document (OCR).';

  @override
  String get idConsentWho =>
      'Qui le traite : GreenGo, avec Google Cloud Vision (Google agit en tant que notre sous-traitant).';

  @override
  String get idConsentRetention =>
      'Combien de temps : l\'image est supprimée dès qu\'une décision est prise, automatiquement ou par un vérificateur. Si une personne doit l\'examiner, elle est conservée 7 jours au maximum, puis supprimée, et il vous sera demandé de la téléverser à nouveau.';

  @override
  String get idConsentKept =>
      'Ce que nous conservons : uniquement si vous êtes vérifié, comment, la date de la décision, votre année de naissance et une empreinte à sens unique (avec clé) du numéro du document, afin qu\'un même document ne puisse pas vérifier plusieurs comptes.';

  @override
  String get idConsentAccess =>
      'Qui peut la voir : aucun autre utilisateur. Seulement le traitement automatique et, si nécessaire, un petit nombre de vérificateurs autorisés de GreenGo.';

  @override
  String get idConsentAccept => 'J\'accepte, continuer';

  @override
  String get idConsentRecordError =>
      'Nous n\'avons pas pu enregistrer votre consentement, rien n\'a donc été envoyé. Vérifiez votre connexion et réessayez.';

  @override
  String get ageVerifyRejectedExpired =>
      'Votre document n\'a pas pu être examiné à temps et a été supprimé. Veuillez le téléverser à nouveau.';

  @override
  String get analyticsConsentTitle => 'Aidez-nous à améliorer GreenGo';

  @override
  String get analyticsConsentBody =>
      'Avec votre accord, nous utilisons Google Firebase Analytics, Crashlytics et Performance Monitoring pour comprendre l\'utilisation de l\'app et corriger les plantages. Cela enregistre et lit des identifiants sur votre appareil. Rien n\'est collecté sans votre accord. Vous pouvez modifier ce choix à tout moment dans Paramètres > Confidentialité et données.';

  @override
  String get analyticsConsentAllow => 'Autoriser';

  @override
  String get analyticsConsentDecline => 'Refuser';

  @override
  String get privacySettingsTitle => 'Confidentialité et données';

  @override
  String get privacySettingsSubtitle =>
      'Statistiques, rapports de plantage et e-mails marketing';

  @override
  String get privacyAnalyticsToggle =>
      'Statistiques d\'utilisation et rapports de plantage';

  @override
  String get privacyAnalyticsToggleSubtitle =>
      'Partagez avec nous des statistiques d\'utilisation et des rapports de plantage (Google Firebase) pour améliorer l\'app.';

  @override
  String get privacyMarketingEmailToggle => 'Actualités et offres par e-mail';

  @override
  String get privacyMarketingEmailSubtitle =>
      'E-mails occasionnels sur les nouveautés, des conseils, des résumés d\'activité et des offres. Vous pouvez vous désabonner à tout moment.';

  @override
  String get privacySettingsSaveError =>
      'Impossible d\'enregistrer votre choix. Veuillez réessayer.';

  @override
  String get notificationCatMarketing => 'Marketing et promotions';

  @override
  String get notificationCatMarketingSubtitle =>
      'Actualités, offres et annonces de GreenGo. Désactivé tant que vous ne l\'activez pas.';

  @override
  String get signupMarketingEmailConsent =>
      'Envoyez-moi des actualités et des offres par e-mail';

  @override
  String get signupMarketingEmailConsentSubtitle =>
      'Facultatif. Vous pouvez vous désabonner à tout moment.';

  @override
  String get moderationDecisionTitle => 'Décision de modération';

  @override
  String get moderationDecisionIntro =>
      'Notre équipe a pris une mesure concernant votre compte ou votre contenu conformément à nos Règles de la communauté. Voici l\'exposé des motifs.';

  @override
  String get moderationDecisionActionLabel => 'Mesure prise';

  @override
  String get moderationDecisionReasonLabel => 'Motif';

  @override
  String get moderationDecisionExplanationLabel =>
      'Explication de notre équipe';

  @override
  String moderationDecisionAppealUntil(String date) {
    return 'Vous pouvez faire appel jusqu\'au $date.';
  }

  @override
  String get moderationDecisionAppealButton => 'Faire appel de cette décision';

  @override
  String get moderationDecisionAppealHint =>
      'Expliquez pourquoi vous pensez que cette décision est erronée (10 caractères minimum).';

  @override
  String get moderationDecisionAppealSubmit => 'Envoyer l\'appel';

  @override
  String get moderationDecisionAppealSent =>
      'Votre appel a été envoyé. Notre équipe va réexaminer la décision et vous informera.';

  @override
  String get moderationDecisionAppealAlready =>
      'Vous avez déjà fait appel de cette décision.';

  @override
  String get moderationDecisionAppealClosed =>
      'Il n\'est plus possible de faire appel de cette décision.';

  @override
  String get moderationDecisionAppealError =>
      'Votre appel n\'a pas pu être envoyé. Veuillez réessayer.';

  @override
  String get moderationDecisionAppealTooShort =>
      'Veuillez écrire au moins 10 caractères.';

  @override
  String get moderationDecisionNotAppealable =>
      'Il n\'est pas possible de faire appel de cette décision dans l\'app. Contactez l\'assistance si vous pensez qu\'elle est erronée.';

  @override
  String get moderationActionRemoveContent => 'Contenu supprimé';

  @override
  String get moderationActionWarning => 'Avertissement émis';

  @override
  String get moderationActionSuspend => 'Compte suspendu temporairement';

  @override
  String get moderationActionBan => 'Compte banni';

  @override
  String get moderationActionShadowBan => 'Visibilité de votre profil réduite';

  @override
  String get moderationActionRequireVerification =>
      'Vérification d\'identité requise';

  @override
  String get moderationActionOther => 'Restriction appliquée';

  @override
  String get moderationReasonCsae => 'Exploitation ou abus sexuel d\'enfants';

  @override
  String get moderationReasonUnderage => 'Utilisateur mineur';

  @override
  String get moderationReasonSexualContent => 'Contenu sexuel';

  @override
  String get moderationReasonInappropriate => 'Contenu inapproprié';

  @override
  String get moderationReasonThreats => 'Menaces';

  @override
  String get moderationReasonViolence => 'Violence';

  @override
  String get moderationReasonHarassment => 'Harcèlement ou intimidation';

  @override
  String get moderationReasonHate => 'Discours haineux';

  @override
  String get moderationReasonSpam => 'Spam';

  @override
  String get moderationReasonScam => 'Arnaque ou fraude';

  @override
  String get moderationReasonImpersonation =>
      'Usurpation d\'identité ou faux profil';

  @override
  String get moderationReasonPrivacy => 'Partage d\'informations personnelles';

  @override
  String get moderationReasonMisleading => 'Contenu trompeur';

  @override
  String get moderationReasonNoShow => 'Absence à une réservation';

  @override
  String get moderationReasonOffPlatformPayment =>
      'Paiement en dehors de la plateforme';

  @override
  String get moderationReasonOther =>
      'Autre infraction à nos Règles de la communauté';

  @override
  String get checkoutConsentTitle => 'Avant de payer';

  @override
  String get checkoutCoinWaiverCheckbox =>
      'J\'accepte que les pièces soient livrées immédiatement et je reconnais perdre mon droit de rétractation dès le début de la livraison.';

  @override
  String get checkoutMembershipWithdrawalInfo =>
      'Droit de rétractation : vous pouvez vous rétracter de cet abonnement dans les 14 jours suivant l\'achat (7 jours pour les achats effectués au Brésil) sans motif et être remboursé intégralement, via « Se rétracter du contrat » dans la Boutique ou sur notre site web. L\'abonnement se renouvelle automatiquement jusqu\'à résiliation ; vous pouvez résilier à tout moment dans le portail de facturation.';

  @override
  String get checkoutContinueToPayment => 'Continuer vers le paiement';

  @override
  String get withdrawFromContract => 'Se rétracter du contrat';

  @override
  String get withdrawalDialogIntro =>
      'Choisissez l\'achat dont vous souhaitez vous rétracter. Nous enverrons un lien de confirmation à l\'adresse utilisée pour l\'achat ; rien n\'est annulé ni remboursé avant votre confirmation.';

  @override
  String get withdrawalNothingEligible =>
      'Aucun de vos achats web ne peut faire l\'objet d\'une rétractation pour le moment. Les abonnements peuvent être rétractés dans les 14 jours suivant l\'achat (7 jours au Brésil) ; les achats de pièces uniquement si le droit n\'a pas été abandonné au paiement.';

  @override
  String withdrawalDeadline(String date) {
    return 'Rétractation jusqu\'au $date';
  }

  @override
  String get withdrawalRequestSent =>
      'Consultez vos e-mails et confirmez la rétractation avec le lien envoyé.';

  @override
  String get withdrawalRequestFailed =>
      'La demande de rétractation n\'a pas pu être envoyée. Réessayez ou écrivez à support@greengochat.com.';

  @override
  String webSubscriptionRenewsOn(
      String plan, String price, String interval, String date) {
    return '$plan : $price par $interval. Renouvellement automatique le $date.';
  }

  @override
  String webSubscriptionEndsOn(
      String plan, String price, String interval, String date) {
    return '$plan : $price par $interval. Résilié ; accès jusqu\'au $date.';
  }

  @override
  String get billingIntervalMonth => 'mois';

  @override
  String get billingIntervalYear => 'an';

  @override
  String get cancelAnytimeBillingPortal =>
      'Résiliez à tout moment dans le portail de facturation';

  @override
  String get billingPortalOpenFailed =>
      'Impossible d\'ouvrir le portail de facturation. Veuillez réessayer.';

  @override
  String get subscriptionAutoRenewInfoWeb =>
      'Les abonnements se renouvellent automatiquement au prix et à la périodicité indiqués jusqu\'à résiliation. Résiliez à tout moment dans le portail de facturation.';

  @override
  String get webBillingTitle => 'Facturation et rétractation';

  @override
  String get ageAssuranceTitle =>
      'Vérifiez votre âge pour utiliser cette fonctionnalité';

  @override
  String get ageAssuranceBody =>
      'Là où vous vivez, la loi nous oblige à confirmer que vous êtes majeur avant que vous puissiez découvrir des personnes ou commencer de nouvelles conversations privées. Le reste de GreenGo fonctionne normalement.';

  @override
  String get ageAssuranceExistingChats =>
      'Les conversations auxquelles vous avez déjà participé restent disponibles.';

  @override
  String get ageAssuranceStoreCheckAndroid => 'Confirmer avec Google Play';

  @override
  String get ageAssuranceStoreCheckIos => 'Confirmer avec l\'App Store';

  @override
  String get ageAssuranceStoreHint =>
      'Utilise l\'âge déjà confirmé par votre compte de la boutique. Nous recevons seulement une tranche d\'âge, jamais votre date de naissance.';

  @override
  String get ageAssuranceIdOption => 'Vérifier avec une pièce d\'identité';

  @override
  String get ageAssuranceStoreUnavailable =>
      'Votre compte de la boutique n\'a pas pu confirmer votre âge. Veuillez le vérifier avec une pièce d\'identité.';

  @override
  String get ageAssuranceVerified => 'Merci, votre âge est confirmé.';

  @override
  String get ageAssuranceWebNote =>
      'Sur le web, votre âge est confirmé avec une pièce d\'identité.';

  @override
  String get ageVerifyWhyRegional =>
      'Pour découvrir des personnes et commencer de nouvelles discussions privées là où vous vivez, nous devons confirmer que vous avez plus de 18 ans.';

  @override
  String get privacyDownloadDataTitle => 'Télécharger mes données';

  @override
  String get privacyDownloadDataSubtitle =>
      'Une copie de votre profil, de vos réglages, de vos photos et des messages que vous avez envoyés (fichier ZIP)';

  @override
  String get privacyDownloadDataConfirmBody =>
      'Nous allons préparer un fichier ZIP avec les données que nous détenons sur vous. Pour protéger les autres personnes, les messages qu\'elles vous ont envoyés ne sont pas inclus. Vous recevrez un lien de téléchargement ici et par e-mail. Le lien est valable 24 heures et vous pouvez demander une copie par jour.';

  @override
  String get privacyDownloadDataConfirmButton => 'Préparer mes données';

  @override
  String get privacyDownloadDataPreparing =>
      'Préparation de vos données. Cela peut prendre quelques minutes...';

  @override
  String get privacyDownloadDataReadyTitle => 'Vos données sont prêtes';

  @override
  String get privacyDownloadDataReadyBody =>
      'Téléchargez le fichier ZIP maintenant. Le lien est valable 24 heures.';

  @override
  String get privacyDownloadDataReadyEmailed =>
      'Nous vous avons aussi envoyé le lien par e-mail.';

  @override
  String get privacyDownloadDataOpen => 'Télécharger';

  @override
  String get privacyDownloadDataRateLimited =>
      'Vous pouvez télécharger vos données une fois toutes les 24 heures. Utilisez le lien envoyé par e-mail ou réessayez demain.';

  @override
  String get privacyDownloadDataInProgress =>
      'Vos données sont déjà en cours de préparation. Veuillez patienter quelques minutes.';

  @override
  String get privacyDownloadDataFailed =>
      'Impossible de préparer vos données. Veuillez réessayer plus tard.';

  @override
  String get reauthPasswordBody =>
      'Pour votre sécurité, saisissez à nouveau votre mot de passe pour continuer.';

  @override
  String get reauthContinue => 'Continuer';

  @override
  String get reauthSignInAgain =>
      'Pour votre sécurité, déconnectez-vous puis reconnectez-vous, et réessayez.';

  @override
  String get profilePhotoPrevious => 'Photo précédente';

  @override
  String get profilePhotoNext => 'Photo suivante';

  @override
  String get aiServicesTitle => 'Services d\'IA';

  @override
  String get aiServicesSubtitleOn =>
      'Activé : les fonctions d\'IA peuvent envoyer à Google le texte sur lequel vous les utilisez.';

  @override
  String get aiServicesSubtitleOff =>
      'Désactivé : aucun texte n\'est envoyé à des services d\'IA.';

  @override
  String get aiServicesWhatsIncluded => 'Ce que couvre cet interrupteur';

  @override
  String get aiServicesFeatureCoach =>
      'Réponses suggérées et le coach linguistique IA (grammaire, décomposition des mots, conseils culturels)';

  @override
  String get aiServicesFeatureTranslate =>
      'Traduction des messages de chat que vous recevez';

  @override
  String get aiServicesFeatureReadAloud =>
      'Lecture audio à voix haute et prononciation';

  @override
  String get aiServicesFeatureSupport =>
      'Réponses automatiques de l\'assistant d\'assistance (si désactivé, une personne vous répond)';

  @override
  String get aiServicesSafetyNote =>
      'Le contrôle de sécurité des photos et des messages reste toujours actif : il protège tout le monde et ne peut pas être désactivé.';

  @override
  String get aiServicesTurnedOff =>
      'Services d\'IA désactivés. Votre choix a été enregistré.';

  @override
  String get aiServicesTurnedOn =>
      'Services d\'IA activés. Votre choix a été enregistré.';

  @override
  String get aiServicesSyncPending =>
      'Enregistré sur cet appareil. Ce sera enregistré sur nos serveurs dès que vous serez en ligne.';

  @override
  String get tpAddTicketType => 'Ajouter un type de billet';

  @override
  String get tpAdviceLarge =>
      'Beaucoup de participants attendus : la confirmation instantanée est recommandée. Les billets sont confirmés automatiquement, sans vérifier chaque paiement.';

  @override
  String get tpAdviceSmall =>
      'Petit groupe : le plus simple est un lien de paiement, sans configuration ; vous confirmez chaque paiement d\'un geste.';

  @override
  String get tpAmountLabel => 'Montant';

  @override
  String get tpAttachReceipt => 'Joindre un justificatif (facultatif)';

  @override
  String get tpAwaitingOrganizerInfo =>
      'Vous avez indiqué à l\'organisateur avoir payé. Votre billet apparaîtra ici dès sa confirmation.';

  @override
  String get tpBadgeBrazil => 'Recommandé au Brésil';

  @override
  String get tpBadgeNoSetup => 'Sans configuration';

  @override
  String get tpBadgeRecommended => 'Recommandé';

  @override
  String get tpBankInstructionsLabel => 'Coordonnées bancaires et instructions';

  @override
  String tpBlockMinimum(String provider, String amount) {
    return '$provider exige au moins $amount par billet.';
  }

  @override
  String tpBlockMpCurrency(String currency) {
    return 'Mercado Pago ne facture qu\'en $currency : passez le prix en $currency ou utilisez Stripe.';
  }

  @override
  String get tpBlockMpCurrencyUnknown =>
      'Mercado Pago ne facture que dans la devise locale de votre compte. Utilisez-la ou Stripe.';

  @override
  String get tpBlockNotConfigured => 'Pas encore disponible.';

  @override
  String tpBlockNotConnected(String provider) {
    return 'Connectez $provider pour l\'utiliser.';
  }

  @override
  String get tpBuyMoreTickets => 'Acheter d\'autres billets';

  @override
  String get tpBuyTickets => 'Acheter des billets';

  @override
  String tpCanBuyMore(int count) {
    return 'Vous pouvez encore acheter $count billets';
  }

  @override
  String get tpCanBuyUnlimited => 'Pas de limite par personne';

  @override
  String get tpCancelOrder => 'Annuler';

  @override
  String get tpCashInstructionsLabel =>
      'Où et quand payer en espèces (facultatif)';

  @override
  String get tpChooseHowToGetPaid =>
      'Choisissez comment les acheteurs paient cette annonce payante.';

  @override
  String get tpClose => 'Fermer';

  @override
  String get tpCodeHint =>
      'Indiquez ce code dans le libellé du paiement pour que l\'organisateur le retrouve.';

  @override
  String get tpCodeLabel => 'Code de paiement';

  @override
  String get tpConfirm => 'Confirmer';

  @override
  String tpConfirmSelected(int count) {
    return 'Confirmer la sélection ($count)';
  }

  @override
  String tpConfirmedCount(int count) {
    return '$count paiements confirmés';
  }

  @override
  String tpConnectProvider(String provider) {
    return 'Connecter $provider';
  }

  @override
  String get tpConsentGuideInstant =>
      'Vous payez dans l\'app via un paiement sécurisé. Billet et QR apparaissent dès la confirmation. Les remboursements sont faits par l\'organisateur.';

  @override
  String get tpConsentGuideManual =>
      'Vous payez l\'hôte directement avec son moyen de paiement et un code. GreenGo ne vérifie pas ce paiement : l\'hôte le confirme, puis votre QR apparaît.';

  @override
  String get tpContinueSetup => 'Poursuivre la configuration';

  @override
  String tpContinueToPay(String amount) {
    return 'Continuer · $amount';
  }

  @override
  String get tpCopied => 'Copié';

  @override
  String get tpCopy => 'Copier';

  @override
  String get tpEditTicketType => 'Modifier le type de billet';

  @override
  String get tpErrAlreadyHasTicket => 'Vous avez déjà un billet pour cela.';

  @override
  String get tpErrEnded => 'La vente est terminée.';

  @override
  String get tpErrGeneric => 'Un problème est survenu. Réessayez.';

  @override
  String get tpErrLimit =>
      'Vous avez atteint la limite de billets par personne.';

  @override
  String get tpErrMinimum =>
      'Le prix est inférieur au minimum du prestataire de paiement.';

  @override
  String get tpErrNotAllowed => 'Vous ne pouvez pas faire cela.';

  @override
  String get tpErrNotOnSale =>
      'Les billets ne sont pas encore en vente : l\'organisateur n\'a pas terminé la configuration du paiement.';

  @override
  String get tpErrOwnListing =>
      'Vous ne pouvez pas acheter de billets pour votre propre annonce.';

  @override
  String get tpErrProvider =>
      'Le prestataire de paiement ne répond pas. Réessayez dans un instant.';

  @override
  String get tpErrSoldOut => 'Complet : il ne reste pas assez de places.';

  @override
  String get tpFree => 'Gratuit';

  @override
  String get tpGetPaidIntro =>
      'L\'argent va directement sur votre propre compte. GreenGo ne prend aucune commission sur les billets.';

  @override
  String get tpGetPaidSubtitle =>
      'Moyens de paiement, Stripe et Mercado Pago, paiements à confirmer';

  @override
  String get tpGetPaidTitle => 'Être payé';

  @override
  String tpGroupOf(int count) {
    return 'Groupe de $count';
  }

  @override
  String tpGroupPreview(String price, int size) {
    return '$price pour un groupe jusqu\'à $size';
  }

  @override
  String get tpGroupPrice => 'Prix par groupe';

  @override
  String tpHoldCountdown(String time) {
    return 'Votre place est réservée pendant $time';
  }

  @override
  String get tpInstantOptional => 'Confirmation instantanée (facultatif)';

  @override
  String get tpInstantSubtitle =>
      'Les acheteurs paient dans l\'app ; les billets sont confirmés automatiquement.';

  @override
  String get tpInstantTitle => 'Confirmation instantanée';

  @override
  String get tpIvePaid => 'J\'ai payé';

  @override
  String get tpLegacyPaymentPrompt =>
      'Cette annonce utilisait un ancien moyen de paiement. Choisissez comment les invités paient pour continuer à vendre.';

  @override
  String get tpManualAddMethodsHint =>
      'Ajoute ton Pix, PayPal… dans Profil > Professionnel > Être payé pour les voir ici.';

  @override
  String get tpManualDisclaimer =>
      'GreenGo ne vérifie pas ces paiements : l\'organisateur est responsable de leur confirmation.';

  @override
  String tpManualLargeWarning(String count) {
    return 'Avec $count personnes, vous devrez confirmer chaque paiement à la main.';
  }

  @override
  String get tpManualMethodLabel => 'Moyen de paiement';

  @override
  String get tpManualSubtitle =>
      'Votre propre moyen de paiement ; vous confirmez chaque paiement d\'un geste.';

  @override
  String get tpManualTitle => 'Lien de paiement — vous confirmez';

  @override
  String get tpMaxGroupBookingsPerUser =>
      'Max. réservations de groupe par personne';

  @override
  String get tpMaxTicketsPerUser => 'Max. billets par personne';

  @override
  String get tpMethodBankTransfer => 'Virement bancaire';

  @override
  String get tpMethodCash => 'Espèces (avant l\'événement)';

  @override
  String tpMpCurrencyInfo(String currency) {
    return 'Facture en $currency';
  }

  @override
  String get tpMpDescription =>
      'Pix, cartes et solde Mercado Pago. Les acheteurs n\'ont pas besoin de compte Mercado Pago.';

  @override
  String get tpMyPurchases => 'Mes achats';

  @override
  String get tpNoFeeNote =>
      'GreenGo ne prend aucune commission : l\'argent va directement à vous.';

  @override
  String get tpNoLimitHint => 'Vide = sans limite';

  @override
  String get tpNoPurchases => 'Aucun achat pour l\'instant.';

  @override
  String get tpNotOnSaleYet => 'Pas encore en vente';

  @override
  String get tpOpenPaymentLink => 'Ouvrir le lien de paiement';

  @override
  String get tpOpenProviderSettings => 'Mettre à jour le compte';

  @override
  String get tpOrderAwaitingConfirmation =>
      'En attente de la confirmation de l\'organisateur…';

  @override
  String get tpOrderCancelled => 'Commande annulée';

  @override
  String get tpOrderClosedInfo =>
      'Cette commande est close. Vous pouvez recommencer depuis l\'événement ou l\'expérience.';

  @override
  String get tpOrderDisputed => 'Paiement contesté — billet non valide';

  @override
  String get tpOrderExpired => 'Réservation expirée';

  @override
  String get tpOrderFailed => 'Paiement échoué';

  @override
  String get tpOrderPaid => 'Payé';

  @override
  String get tpOrderPendingPayment => 'En attente de votre paiement';

  @override
  String get tpOrderRefunded => 'Remboursé — billet plus valide';

  @override
  String get tpOrderRejected =>
      'L\'organisateur n\'a pas confirmé votre paiement';

  @override
  String get tpOrderTitle => 'Vos billets';

  @override
  String get tpOrderWaitingProvider =>
      'En attente de la confirmation du paiement…';

  @override
  String get tpPayAgain => 'Payer à nouveau';

  @override
  String get tpPayInApp => 'Paiement dans l\'app';

  @override
  String get tpPayInAppInfo =>
      'Payez dans l\'app une fois accepté par l\'hôte ; votre QR apparaît après confirmation.';

  @override
  String get tpPayNow => 'Payer maintenant';

  @override
  String tpPayWith(String method) {
    return 'Payer avec $method';
  }

  @override
  String get tpPaymentConfirmed => 'Paiement confirmé — vos billets sont prêts';

  @override
  String get tpPerGroup => 'Par groupe';

  @override
  String get tpPerGroupInfo =>
      'Un prix fixe par groupe (ex. visite privée), quelle que soit la taille jusqu\'au maximum.';

  @override
  String get tpPerPerson => 'Par personne';

  @override
  String get tpPerPersonInfo =>
      'Chaque personne paie le prix ; un billet par personne.';

  @override
  String get tpPixHint =>
      'Payé avec Pix ? La confirmation prend en général quelques secondes.';

  @override
  String get tpReceiptAttached => 'Justificatif joint';

  @override
  String get tpReconnectBanner =>
      'Connectez Mercado Pago / Stripe pour vendre des billets avec confirmation automatique. Les liens Stripe ou Mercado Pago collés ne servent pas aux billets.';

  @override
  String get tpRefresh => 'Actualiser';

  @override
  String get tpReject => 'Non reçu';

  @override
  String get tpRejectReason => 'Motif (visible par l\'acheteur)';

  @override
  String get tpRejectTitle => 'Paiement non reçu ?';

  @override
  String get tpSalesEnd => 'Fin des ventes';

  @override
  String get tpSalesStart => 'Début des ventes';

  @override
  String get tpSave => 'Enregistrer';

  @override
  String get tpScanNotPaid => 'Non payé — pas de billet valide';

  @override
  String get tpScanTicketNotValid => 'Billet remboursé ou annulé — non valide';

  @override
  String get tpSelectorTitle => 'Comment les invités paient-ils ?';

  @override
  String get tpShareTicket => 'Partager ce billet';

  @override
  String tpShareTicketText(String title, int index, int total) {
    return 'Billet $index/$total pour $title sur GreenGo. Montrez ce QR à l\'entrée (valable une fois).';
  }

  @override
  String get tpStatusNotConnected => 'Non connecté';

  @override
  String get tpStatusPending => 'Vérification en cours';

  @override
  String get tpStatusReady => 'Prêt';

  @override
  String get tpStatusReconnect => 'Reconnexion requise';

  @override
  String get tpStopSelling => 'Arrêter la vente';

  @override
  String get tpStripeDescription =>
      'Cartes, Apple Pay et Google Pay dans le monde entier. Aucun compte requis pour les acheteurs.';

  @override
  String tpTicketIndex(int index, int total) {
    return 'Billet $index sur $total';
  }

  @override
  String get tpTicketInvalid => 'Ce billet n\'est plus valide.';

  @override
  String get tpTicketTypes => 'Types de billets';

  @override
  String get tpTicketTypesEmpty =>
      'Aucun type de billet : le prix de l\'événement est le seul billet. Ajoutez VIP, prévente, etc.';

  @override
  String get tpTicketUsed => 'Déjà utilisé à l\'entrée';

  @override
  String tpTicketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count billets',
      one: '1 billet',
    );
    return '$_temp0';
  }

  @override
  String get tpTiredOfConfirming =>
      'Lassé de confirmer ? Connectez Mercado Pago ou Stripe pour la confirmation automatique.';

  @override
  String get tpToConfirmEmpty => 'Aucun paiement en attente.';

  @override
  String get tpToConfirmInfo =>
      'Vérifiez sur votre compte le montant et le code GG- avant de confirmer. La confirmation émet les billets.';

  @override
  String get tpToConfirmTitle => 'Paiements à confirmer';

  @override
  String get tpTotal => 'Total';

  @override
  String get tpTypeEnded => 'Ventes terminées';

  @override
  String get tpTypeHasSalesWarning =>
      'Des billets de ce type sont déjà vendus : ils gardent leur prix et leur type.';

  @override
  String get tpTypeHidden => 'Masqué';

  @override
  String get tpTypeMaxPerUser => 'Max. par personne';

  @override
  String get tpTypeName => 'Nom (ex. VIP)';

  @override
  String get tpTypeNotStarted => 'Les ventes n\'ont pas commencé';

  @override
  String tpTypeOnlyLeft(int count) {
    return 'Plus que $count';
  }

  @override
  String get tpTypePerks => 'Description / avantages';

  @override
  String get tpTypePrice => 'Prix';

  @override
  String get tpTypeQuantity => 'Quantité (vide = capacité de l\'événement)';

  @override
  String get tpTypeSelling => 'En vente';

  @override
  String tpTypeSold(int sold, String total) {
    return '$sold/$total vendus';
  }

  @override
  String get tpTypeSoldOut => 'Complet';

  @override
  String get tpTypeUnavailable => 'Pas en vente';

  @override
  String get tpViewPayment => 'Voir le paiement';

  @override
  String get tpViewReceipt => 'Justificatif';

  @override
  String get tpViewTickets => 'Voir les billets';

  @override
  String get mtAddTime => 'Ajouter un horaire';

  @override
  String get mtAdvanced => 'Avancé';

  @override
  String get mtApplyAll => 'Appliquer à tous les jours choisis';

  @override
  String get mtAvailableFrom => 'Disponible de';

  @override
  String get mtAvailableUntil => 'Jusqu\'à';

  @override
  String get mtBreak => 'Pause entre les sessions';

  @override
  String get mtBulkCloseRange => 'Fermer une période (vacances)';

  @override
  String get mtBulkHint =>
      'Les modifications sont enregistrées avec Enregistrer.';

  @override
  String get mtBulkRemoveTime =>
      'Retirer un horaire de chaque jour de semaine choisi';

  @override
  String get mtBulkTitle => 'Changements rapides';

  @override
  String get mtCalendarTitle => 'Calendrier';

  @override
  String get mtCapacity => 'Places par horaire';

  @override
  String get mtCloseDay => 'Fermé ce jour-là';

  @override
  String get mtClosed => 'Fermé';

  @override
  String mtConfirmBody(int count) {
    return '$count horaires réservés seraient supprimés. Ces réservations seront annulées, les invités prévenus et remboursés.';
  }

  @override
  String get mtConfirmCancelBookings => 'Annuler ces réservations';

  @override
  String get mtConfirmTitle => 'Des horaires sont réservés';

  @override
  String get mtCopyToMonth => 'Copier sur tout le mois';

  @override
  String mtCopyToWeekdays(String weekday) {
    return 'Copier sur chaque $weekday du mois';
  }

  @override
  String get mtDateFrom => 'À partir du';

  @override
  String get mtDateTo => 'Jusqu\'au';

  @override
  String get mtDaysOfWeek => 'Jours de la semaine';

  @override
  String get mtDone => 'Terminé';

  @override
  String get mtDuration => 'Durée';

  @override
  String get mtErrOverlap =>
      'Les horaires se chevaucheraient : « commencer toutes les » doit être au moins égal à la durée.';

  @override
  String get mtErrRules => 'Vérifiez les réglages du planning.';

  @override
  String get mtErrTimeExists => 'Cet horaire existe déjà.';

  @override
  String get mtErrTimeFit => 'La session finirait après minuit.';

  @override
  String get mtErrTimeOverlaps => 'Il chevauche un autre horaire de ce jour.';

  @override
  String get mtErrWeekdays => 'Choisissez au moins un jour.';

  @override
  String get mtErrWindow => '« Jusqu\'à » doit être après « Disponible de ».';

  @override
  String mtHours(int h) {
    return '$h h';
  }

  @override
  String mtHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get mtLegendChanged => 'jour modifié';

  @override
  String get mtLegendSpecialPrice => 'prix spécial';

  @override
  String get mtLegendWeekendPrice => 'prix du week-end';

  @override
  String mtMinutes(int m) {
    return '$m min';
  }

  @override
  String get mtNextMonth => 'Mois suivant';

  @override
  String get mtNoBreak => 'Sans pause';

  @override
  String get mtNoEnd => 'Sans date de fin';

  @override
  String get mtPrevMonth => 'Mois précédent';

  @override
  String get mtPreview => 'Horaires de chaque jour choisi';

  @override
  String get mtRemoveTime => 'Retirer l\'horaire';

  @override
  String get mtResetDay => 'Rétablir par défaut';

  @override
  String get mtSaved => 'Planning enregistré';

  @override
  String mtSavedCancelled(int count) {
    return 'Planning enregistré — $count réservations annulées et remboursées';
  }

  @override
  String get mtSetupTitle => 'Vos horaires';

  @override
  String get mtSpecialPrice => 'Prix spécial pour ce jour';

  @override
  String get mtSpecialPriceHint => 'Vide = prix normal';

  @override
  String get mtStartEvery => 'Commencer toutes les';

  @override
  String get mtStartEveryAuto => 'Automatique (durée + pause)';

  @override
  String get mtTime => 'Horaire';

  @override
  String get mtTimezone => 'Fuseau horaire';

  @override
  String get mtTitle => 'Gérer les horaires';

  @override
  String get mtWeekendPrice => 'Prix du week-end';

  @override
  String get mtWeekendPriceInfo =>
      'S\'applique aux jours choisis ; le prix spécial d\'un jour se règle dans Gérer les horaires.';

  @override
  String get mtWeekendPriceToggle => 'Prix différent le week-end';

  @override
  String rtGroupsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count créneaux de groupe restants',
      one: '1 créneau de groupe restant',
    );
    return '$_temp0';
  }

  @override
  String rtSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places restantes',
      one: '1 place restante',
    );
    return '$_temp0';
  }

  @override
  String get rtSpecialPrice => 'prix spécial';

  @override
  String rtTimesIn(String zone) {
    return 'Horaires dans le fuseau de l\'hôte ($zone)';
  }

  @override
  String get rtWeekendPrice => 'prix du week-end';

  @override
  String rtYourTime(String time) {
    return 'Votre heure : $time';
  }

  @override
  String get tpReorder => 'Glisser pour réordonner';

  @override
  String tpSalesRow(int sold, int held, String left) {
    return '$sold vendus · $held réservés · $left restants';
  }

  @override
  String get tpSalesSummary => 'Ventes par type de billet';

  @override
  String tpSalesTotal(int sold, int held) {
    return 'Total : $sold vendus, $held réservés';
  }

  @override
  String get wzAllGood => 'Tout est prêt.';

  @override
  String get wzAvailability => 'Disponibilités';

  @override
  String get wzBack => 'Retour';

  @override
  String get wzEdit => 'Modifier';

  @override
  String get wzErrCapacity => 'Indiquez combien de personnes peuvent venir.';

  @override
  String get wzErrDates => 'La fin doit être après le début.';

  @override
  String get wzErrDescription => 'Ajoutez une description.';

  @override
  String get wzErrLocation => 'Ajoutez le lieu.';

  @override
  String get wzErrTitle => 'Ajoutez un titre.';

  @override
  String get wzEventBasics => 'L\'essentiel';

  @override
  String get wzExpBasics => 'L\'essentiel';

  @override
  String get wzFineTuneLater =>
      'Vous pourrez ajuster des jours précis plus tard dans Gérer les horaires.';

  @override
  String get wzFix => 'Corriger';

  @override
  String get wzFormatPrice => 'Format et prix';

  @override
  String get wzLocation => 'Lieu';

  @override
  String get wzNext => 'Suivant';

  @override
  String get wzOverviewTitle => 'Que voulez-vous modifier ?';

  @override
  String get wzPayment => 'Paiement';

  @override
  String get wzPreviewTitle => 'Ce que verront les acheteurs';

  @override
  String get wzRecurringInfo =>
      'Les invités choisissent un des horaires générés. Désactivez pour garder des dates individuelles.';

  @override
  String get wzRecurringToggle => 'Répéter chaque semaine';

  @override
  String get wzResume => 'Reprendre';

  @override
  String get wzResumeBody =>
      'Vous avez un brouillon inachevé sur cet appareil. Reprendre là où vous en étiez ?';

  @override
  String get wzResumeTitle => 'Reprendre votre brouillon ?';

  @override
  String get wzReview => 'Vérifier et publier';

  @override
  String get wzStartOver => 'Recommencer';

  @override
  String wzStepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get wzTickets => 'Billets';

  @override
  String get wzWarnManualLarge =>
      'Beaucoup de monde avec des paiements manuels : vous confirmerez chacun. Envisagez la confirmation instantanée.';

  @override
  String get wzWarnNoAvailability =>
      'Pas encore de disponibilités : ajoutez des dates après l\'enregistrement ou activez « Répéter chaque semaine ».';

  @override
  String get wzWarnNoPhoto =>
      'Pas encore de photo de couverture : les annonces avec photo sont plus réservées.';

  @override
  String get wzWhenWhere => 'Quand et où';

  @override
  String get tpPaymentMethodsSectionHint =>
      'Tes propres moyens (Pix, PayPal, …) : on peut te payer directement, et tu peux les utiliser pour les billets que tu confirmes toi-même.';

  @override
  String get tpPaymentMethodsSaveFailed =>
      'Impossible d\'enregistrer tes moyens de paiement. Réessaie.';

  @override
  String wzNextTo(String step) {
    return 'Suivant : $step';
  }

  @override
  String get wzSteps => 'Étapes';

  @override
  String get wzAllStepsTitle => 'Toutes les étapes';

  @override
  String get wzStepsHint =>
      'Touchez une étape pour y aller. Vous pouvez revenir à tout moment.';

  @override
  String get wzStatusCurrent => 'Étape en cours';

  @override
  String get wzStatusDone => 'Terminé';

  @override
  String get wzStatusAttention => 'À compléter';

  @override
  String get wzStatusTodo => 'Pas commencé';

  @override
  String wzStepSemantics(int step, int total, String title, String status) {
    return 'Étape $step sur $total : $title. $status';
  }

  @override
  String get wzPaymentAppearsNote =>
      'L\'étape Paiement apparaît lorsque le prix est supérieur à 0.';

  @override
  String get wzPublishBlocked =>
      'Complétez les éléments obligatoires ci-dessus pour publier.';

  @override
  String get wzEvBasicsDesc =>
      'Donnez un titre clair à votre événement et expliquez à quoi s\'attendre. Une photo de couverture le met en valeur.';

  @override
  String get wzEvBasicsReq => 'Obligatoire : titre et description.';

  @override
  String get wzEvWhereDesc =>
      'Indiquez où il a lieu (saisissez l\'adresse ou choisissez-la sur la carte) et quand il commence et se termine.';

  @override
  String get wzEvWhereReq =>
      'Obligatoire : le lieu, et une fin après le début.';

  @override
  String get wzEvTicketsDesc =>
      'Choisissez si l\'événement est gratuit ou payant, fixez le prix et le nombre de participants.';

  @override
  String get wzEvTicketsReq =>
      'Obligatoire : le nombre de places (ou illimité) et, pour un événement payant, un prix.';

  @override
  String get wzEvPaymentDesc =>
      'Choisissez comment les participants vous paient leurs billets.';

  @override
  String get wzEvPaymentReq => 'Obligatoire : un moyen d\'être payé.';

  @override
  String get wzEvReviewDesc =>
      'Vérifiez l\'aperçu de votre événement. Corrigez ce qui est en rouge, puis publiez, enregistrez un brouillon ou programmez-le.';

  @override
  String get wzExBasicsDesc =>
      'Nommez votre expérience, décrivez-la et ajoutez des photos, vos langues et ce qui est inclus.';

  @override
  String get wzExBasicsReq =>
      'Obligatoire : titre, description, une photo principale, au moins une langue et ce qui est inclus.';

  @override
  String get wzExLocationDesc => 'Indiquez à vos invités où vous retrouver.';

  @override
  String get wzExLocationReq => 'Obligatoire : le point de rendez-vous.';

  @override
  String get wzExFormatDesc =>
      'Définissez la durée, la taille du groupe et si c\'est gratuit ou payant (par personne ou par groupe).';

  @override
  String get wzExFormatReq =>
      'Obligatoire : durée, taille du groupe et, si c\'est payant, un prix.';

  @override
  String get wzExAvailDesc =>
      'Choisissez quand les invités peuvent réserver : un planning hebdomadaire ou des dates ajoutées plus tard.';

  @override
  String get wzExAvailReq =>
      'Facultatif : vous pouvez aussi ajouter des dates après l\'enregistrement.';

  @override
  String get wzExPaymentDesc => 'Choisissez comment les invités vous paient.';

  @override
  String get wzExPaymentReq => 'Obligatoire : au moins un moyen d\'être payé.';

  @override
  String get wzExReviewDesc =>
      'Vérifiez ce que verront les invités. Corrigez ce qui est en rouge, puis publiez ou enregistrez un brouillon.';

  @override
  String verificationOrMethod(String method) {
    return 'ou $method';
  }

  @override
  String get safetyAcademyTitle => 'Académie de la sécurité';

  @override
  String get safetyAcademyLearningModules => 'Modules d\'apprentissage';

  @override
  String safetyAcademyModulesCompleted(int completed, int total) {
    return '$completed / $total modules terminés';
  }

  @override
  String get safetyAcademyChampionTitle => 'Champion de la sécurité';

  @override
  String get safetyAcademyChampionBody =>
      'Vous avez terminé tous les modules de sécurité !';

  @override
  String get safetyAcademyLessonCompletedToast => 'Leçon terminée !';

  @override
  String get safetyAcademyNoLessons =>
      'Aucune leçon disponible pour le moment.';

  @override
  String safetyAcademyLessonsProgress(int completed, int total) {
    return '$completed / $total leçons';
  }

  @override
  String safetyAcademyLessonXpWithQuiz(int xp) {
    return '+$xp XP | Quiz';
  }

  @override
  String get safetyAcademyTakeQuiz => 'Faire le quiz';

  @override
  String get safetyAcademyCompleteLesson => 'Terminer la leçon';

  @override
  String get safetyAcademyCompleted => 'Terminée';

  @override
  String safetyAcademyQuestionOf(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String safetyAcademyCorrectCount(int count) {
    return '$count correcte(s)';
  }

  @override
  String get safetyAcademyNextQuestion => 'Question suivante';

  @override
  String get safetyAcademySeeResults => 'Voir les résultats';

  @override
  String get safetyAcademyGreatJob => 'Bravo !';

  @override
  String get safetyAcademyKeepLearning => 'Continuez à apprendre !';

  @override
  String safetyAcademyScoreSummary(int correct, int total) {
    return '$correct bonnes réponses sur $total';
  }

  @override
  String safetyAcademyPassingScore(int score) {
    return 'Score requis : $score %';
  }

  @override
  String safetyAcademyCompleteLessonXp(int xp) {
    return 'Terminer la leçon (+$xp XP)';
  }

  @override
  String get safetyAcademyReviewLesson => 'Revoir la leçon';

  @override
  String get safetyAcademyExitQuizTitle => 'Quitter le quiz ?';

  @override
  String get safetyAcademyExitQuizBody => 'Votre progression sera perdue.';

  @override
  String get countryNameAF => 'Afghanistan';

  @override
  String get countryNameAL => 'Albanie';

  @override
  String get countryNameDZ => 'Algérie';

  @override
  String get countryNameAD => 'Andorre';

  @override
  String get countryNameAO => 'Angola';

  @override
  String get countryNameAG => 'Antigua-et-Barbuda';

  @override
  String get countryNameAR => 'Argentine';

  @override
  String get countryNameAM => 'Arménie';

  @override
  String get countryNameAU => 'Australie';

  @override
  String get countryNameAT => 'Autriche';

  @override
  String get countryNameAZ => 'Azerbaïdjan';

  @override
  String get countryNameBS => 'Bahamas';

  @override
  String get countryNameBH => 'Bahreïn';

  @override
  String get countryNameBD => 'Bangladesh';

  @override
  String get countryNameBB => 'Barbade';

  @override
  String get countryNameBY => 'Biélorussie';

  @override
  String get countryNameBE => 'Belgique';

  @override
  String get countryNameBZ => 'Belize';

  @override
  String get countryNameBJ => 'Bénin';

  @override
  String get countryNameBT => 'Bhoutan';

  @override
  String get countryNameBO => 'Bolivie';

  @override
  String get countryNameBA => 'Bosnie-Herzégovine';

  @override
  String get countryNameBW => 'Botswana';

  @override
  String get countryNameBR => 'Brésil';

  @override
  String get countryNameBN => 'Brunei';

  @override
  String get countryNameBG => 'Bulgarie';

  @override
  String get countryNameBF => 'Burkina Faso';

  @override
  String get countryNameBI => 'Burundi';

  @override
  String get countryNameCV => 'Cap-Vert';

  @override
  String get countryNameKH => 'Cambodge';

  @override
  String get countryNameCM => 'Cameroun';

  @override
  String get countryNameCA => 'Canada';

  @override
  String get countryNameCF => 'République centrafricaine';

  @override
  String get countryNameTD => 'Tchad';

  @override
  String get countryNameCL => 'Chili';

  @override
  String get countryNameCN => 'Chine';

  @override
  String get countryNameCO => 'Colombie';

  @override
  String get countryNameKM => 'Comores';

  @override
  String get countryNameCG => 'Congo';

  @override
  String get countryNameCD => 'République démocratique du Congo';

  @override
  String get countryNameCR => 'Costa Rica';

  @override
  String get countryNameHR => 'Croatie';

  @override
  String get countryNameCU => 'Cuba';

  @override
  String get countryNameCY => 'Chypre';

  @override
  String get countryNameCZ => 'Tchéquie';

  @override
  String get countryNameDK => 'Danemark';

  @override
  String get countryNameDJ => 'Djibouti';

  @override
  String get countryNameDM => 'Dominique';

  @override
  String get countryNameDO => 'République dominicaine';

  @override
  String get countryNameEC => 'Équateur';

  @override
  String get countryNameEG => 'Égypte';

  @override
  String get countryNameSV => 'Salvador';

  @override
  String get countryNameGQ => 'Guinée équatoriale';

  @override
  String get countryNameER => 'Érythrée';

  @override
  String get countryNameEE => 'Estonie';

  @override
  String get countryNameSZ => 'Eswatini';

  @override
  String get countryNameET => 'Éthiopie';

  @override
  String get countryNameFJ => 'Fidji';

  @override
  String get countryNameFI => 'Finlande';

  @override
  String get countryNameFR => 'France';

  @override
  String get countryNameGA => 'Gabon';

  @override
  String get countryNameGM => 'Gambie';

  @override
  String get countryNameGE => 'Géorgie';

  @override
  String get countryNameDE => 'Allemagne';

  @override
  String get countryNameGH => 'Ghana';

  @override
  String get countryNameGR => 'Grèce';

  @override
  String get countryNameGD => 'Grenade';

  @override
  String get countryNameGT => 'Guatemala';

  @override
  String get countryNameGN => 'Guinée';

  @override
  String get countryNameGW => 'Guinée-Bissau';

  @override
  String get countryNameGY => 'Guyana';

  @override
  String get countryNameHT => 'Haïti';

  @override
  String get countryNameHN => 'Honduras';

  @override
  String get countryNameHU => 'Hongrie';

  @override
  String get countryNameIS => 'Islande';

  @override
  String get countryNameIN => 'Inde';

  @override
  String get countryNameID => 'Indonésie';

  @override
  String get countryNameIR => 'Iran';

  @override
  String get countryNameIQ => 'Irak';

  @override
  String get countryNameIE => 'Irlande';

  @override
  String get countryNameIL => 'Israël';

  @override
  String get countryNameIT => 'Italie';

  @override
  String get countryNameCI => 'Côte d\'Ivoire';

  @override
  String get countryNameJM => 'Jamaïque';

  @override
  String get countryNameJP => 'Japon';

  @override
  String get countryNameJO => 'Jordanie';

  @override
  String get countryNameKZ => 'Kazakhstan';

  @override
  String get countryNameKE => 'Kenya';

  @override
  String get countryNameKI => 'Kiribati';

  @override
  String get countryNameXK => 'Kosovo';

  @override
  String get countryNameKW => 'Koweït';

  @override
  String get countryNameKG => 'Kirghizistan';

  @override
  String get countryNameLA => 'Laos';

  @override
  String get countryNameLV => 'Lettonie';

  @override
  String get countryNameLB => 'Liban';

  @override
  String get countryNameLS => 'Lesotho';

  @override
  String get countryNameLR => 'Liberia';

  @override
  String get countryNameLY => 'Libye';

  @override
  String get countryNameLI => 'Liechtenstein';

  @override
  String get countryNameLT => 'Lituanie';

  @override
  String get countryNameLU => 'Luxembourg';

  @override
  String get countryNameMG => 'Madagascar';

  @override
  String get countryNameMW => 'Malawi';

  @override
  String get countryNameMY => 'Malaisie';

  @override
  String get countryNameMV => 'Maldives';

  @override
  String get countryNameML => 'Mali';

  @override
  String get countryNameMT => 'Malte';

  @override
  String get countryNameMH => 'Îles Marshall';

  @override
  String get countryNameMR => 'Mauritanie';

  @override
  String get countryNameMU => 'Maurice';

  @override
  String get countryNameMX => 'Mexique';

  @override
  String get countryNameFM => 'Micronésie';

  @override
  String get countryNameMD => 'Moldavie';

  @override
  String get countryNameMC => 'Monaco';

  @override
  String get countryNameMN => 'Mongolie';

  @override
  String get countryNameME => 'Monténégro';

  @override
  String get countryNameMA => 'Maroc';

  @override
  String get countryNameMZ => 'Mozambique';

  @override
  String get countryNameMM => 'Myanmar';

  @override
  String get countryNameNA => 'Namibie';

  @override
  String get countryNameNR => 'Nauru';

  @override
  String get countryNameNP => 'Népal';

  @override
  String get countryNameNL => 'Pays-Bas';

  @override
  String get countryNameNZ => 'Nouvelle-Zélande';

  @override
  String get countryNameNI => 'Nicaragua';

  @override
  String get countryNameNE => 'Niger';

  @override
  String get countryNameNG => 'Nigeria';

  @override
  String get countryNameKP => 'Corée du Nord';

  @override
  String get countryNameMK => 'Macédoine du Nord';

  @override
  String get countryNameNO => 'Norvège';

  @override
  String get countryNameOM => 'Oman';

  @override
  String get countryNamePK => 'Pakistan';

  @override
  String get countryNamePW => 'Palaos';

  @override
  String get countryNamePS => 'Palestine';

  @override
  String get countryNamePA => 'Panama';

  @override
  String get countryNamePG => 'Papouasie-Nouvelle-Guinée';

  @override
  String get countryNamePY => 'Paraguay';

  @override
  String get countryNamePE => 'Pérou';

  @override
  String get countryNamePH => 'Philippines';

  @override
  String get countryNamePL => 'Pologne';

  @override
  String get countryNamePT => 'Portugal';

  @override
  String get countryNameQA => 'Qatar';

  @override
  String get countryNameRO => 'Roumanie';

  @override
  String get countryNameRU => 'Russie';

  @override
  String get countryNameRW => 'Rwanda';

  @override
  String get countryNameKN => 'Saint-Christophe-et-Niévès';

  @override
  String get countryNameLC => 'Sainte-Lucie';

  @override
  String get countryNameVC => 'Saint-Vincent-et-les-Grenadines';

  @override
  String get countryNameWS => 'Samoa';

  @override
  String get countryNameSM => 'Saint-Marin';

  @override
  String get countryNameST => 'Sao Tomé-et-Principe';

  @override
  String get countryNameSA => 'Arabie saoudite';

  @override
  String get countryNameSN => 'Sénégal';

  @override
  String get countryNameRS => 'Serbie';

  @override
  String get countryNameSC => 'Seychelles';

  @override
  String get countryNameSL => 'Sierra Leone';

  @override
  String get countryNameSG => 'Singapour';

  @override
  String get countryNameSK => 'Slovaquie';

  @override
  String get countryNameSI => 'Slovénie';

  @override
  String get countryNameSB => 'Îles Salomon';

  @override
  String get countryNameSO => 'Somalie';

  @override
  String get countryNameZA => 'Afrique du Sud';

  @override
  String get countryNameKR => 'Corée du Sud';

  @override
  String get countryNameSS => 'Soudan du Sud';

  @override
  String get countryNameES => 'Espagne';

  @override
  String get countryNameLK => 'Sri Lanka';

  @override
  String get countryNameSD => 'Soudan';

  @override
  String get countryNameSR => 'Suriname';

  @override
  String get countryNameSE => 'Suède';

  @override
  String get countryNameCH => 'Suisse';

  @override
  String get countryNameSY => 'Syrie';

  @override
  String get countryNameTW => 'Taïwan';

  @override
  String get countryNameTJ => 'Tadjikistan';

  @override
  String get countryNameTZ => 'Tanzanie';

  @override
  String get countryNameTH => 'Thaïlande';

  @override
  String get countryNameTL => 'Timor oriental';

  @override
  String get countryNameTG => 'Togo';

  @override
  String get countryNameTO => 'Tonga';

  @override
  String get countryNameTT => 'Trinité-et-Tobago';

  @override
  String get countryNameTN => 'Tunisie';

  @override
  String get countryNameTR => 'Turquie';

  @override
  String get countryNameTM => 'Turkménistan';

  @override
  String get countryNameTV => 'Tuvalu';

  @override
  String get countryNameUG => 'Ouganda';

  @override
  String get countryNameUA => 'Ukraine';

  @override
  String get countryNameAE => 'Émirats arabes unis';

  @override
  String get countryNameGB => 'Royaume-Uni';

  @override
  String get countryNameUS => 'États-Unis';

  @override
  String get countryNameUY => 'Uruguay';

  @override
  String get countryNameUZ => 'Ouzbékistan';

  @override
  String get countryNameVU => 'Vanuatu';

  @override
  String get countryNameVA => 'Vatican';

  @override
  String get countryNameVE => 'Venezuela';

  @override
  String get countryNameVN => 'Viêt Nam';

  @override
  String get countryNameYE => 'Yémen';

  @override
  String get countryNameZM => 'Zambie';

  @override
  String get countryNameZW => 'Zimbabwe';

  @override
  String get countryNameHK => 'Hong Kong';

  @override
  String get countryNamePR => 'Porto Rico';

  @override
  String get spotsCatRestaurant => 'Restaurant';

  @override
  String get spotsCatCafe => 'Café';

  @override
  String get spotsCatCulturalSite => 'Site culturel';

  @override
  String get spotsCatMarket => 'Marché';

  @override
  String get spotsCatViewpoint => 'Point de vue';

  @override
  String spotsCreatedNamed(String name) {
    return 'Lieu « $name » créé !';
  }

  @override
  String get spotsEmptyHint =>
      'Aucun lieu culturel dans cette ville pour l\'instant. Soyez le premier à en ajouter un !';

  @override
  String spotsEmptyCategoryHint(String category) {
    return 'Aucun lieu « $category » dans cette ville pour l\'instant. Soyez le premier à en ajouter un !';
  }

  @override
  String spotsReviewCountParen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count avis)',
      one: '(1 avis)',
    );
    return '$_temp0';
  }

  @override
  String get uexpLangHebrew => 'Hébreu';

  @override
  String get uexpLangThai => 'Thaï';

  @override
  String get uexpLangVietnamese => 'Vietnamien';

  @override
  String get safetyAcademyModCommunicationTitle =>
      'Compétences en communication';

  @override
  String get safetyAcademyModCommunicationDesc =>
      'Adoptez de bonnes habitudes de communication : consentement, limites et écoute active.';

  @override
  String get safetyAcademyLsnActiveListeningTitle => 'Écoute active';

  @override
  String get safetyAcademyLsnActiveListeningS0 =>
      'L\'écoute active est le fondement d\'une relation authentique. Elle va au-delà du simple fait d\'entendre des mots : il s\'agit de s\'impliquer pleinement auprès de votre interlocuteur et de lui faire sentir qu\'il compte.';

  @override
  String get safetyAcademyLsnActiveListeningS1 =>
      'Posez des questions de relance sur ce que l\'autre a dit, et pas seulement sur ce dont vous voulez parler. Cela montre un intérêt sincère.';

  @override
  String get safetyAcademyLsnActiveListeningS2 => 'Techniques d\'écoute active';

  @override
  String get safetyAcademyLsnActiveListeningS2I0 =>
      'Accordez toute votre attention (rangez votre téléphone)';

  @override
  String get safetyAcademyLsnActiveListeningS2I1 =>
      'Utilisez des signaux verbaux (« Je vois », « C\'est intéressant »)';

  @override
  String get safetyAcademyLsnActiveListeningS2I2 =>
      'Reformulez ce que vous avez entendu (« Si je comprends bien… »)';

  @override
  String get safetyAcademyLsnActiveListeningS2I3 =>
      'Posez des questions de relance ouvertes';

  @override
  String get safetyAcademyLsnActiveListeningS2I4 =>
      'Évitez d\'interrompre ou de préparer votre réponse pendant que l\'autre parle';

  @override
  String get safetyAcademyLsnActiveListeningS3 =>
      'Dans les conversations écrites, l\'écoute active consiste à lire attentivement les messages, à répondre à ce qui a réellement été dit et à poser des questions réfléchies plutôt que de tout ramener à vous.';

  @override
  String get safetyAcademyLsnActiveListeningQ0 =>
      'La personne que vous rencontrez raconte son dernier voyage. Quelle est la meilleure réponse d\'écoute active ?';

  @override
  String get safetyAcademyLsnActiveListeningQ0O0 =>
      '« Sympa. Bref, moi je suis allé à… »';

  @override
  String get safetyAcademyLsnActiveListeningQ0O1 =>
      '« Ça a l\'air génial ! Quel a été le meilleur moment du voyage ? »';

  @override
  String get safetyAcademyLsnActiveListeningQ0O2 =>
      '« J\'y suis allé aussi, laissez-moi vous raconter. »';

  @override
  String get safetyAcademyLsnActiveListeningQ0O3 => '« Sympa. »';

  @override
  String get safetyAcademyLsnActiveListeningQ0Exp =>
      'Poser une question de relance sur son expérience montre un intérêt sincère et fait vivre la conversation.';

  @override
  String get safetyAcademyLsnActiveListeningQ1 =>
      'Que devez-vous éviter lors de l\'écoute active ?';

  @override
  String get safetyAcademyLsnActiveListeningQ1O0 => 'Établir un contact visuel';

  @override
  String get safetyAcademyLsnActiveListeningQ1O1 =>
      'Préparer votre réponse pendant que l\'autre parle encore';

  @override
  String get safetyAcademyLsnActiveListeningQ1O2 =>
      'Hocher la tête de temps en temps';

  @override
  String get safetyAcademyLsnActiveListeningQ1O3 =>
      'Poser des questions de relance';

  @override
  String get safetyAcademyLsnActiveListeningQ1Exp =>
      'Si vous préparez déjà votre réponse, vous n\'écoutez pas vraiment. Cherchez d\'abord à comprendre, puis répondez.';

  @override
  String get safetyAcademyLsnBoundariesTitle => 'Poser ses limites';

  @override
  String get safetyAcademyLsnBoundariesS0 =>
      'Les limites sont les règles que vous fixez sur la manière dont vous voulez être traité(e). Elles sont essentielles à des relations saines et protègent votre bien-être émotionnel, physique et mental.';

  @override
  String get safetyAcademyLsnBoundariesS1 =>
      'Exprimez vos limites clairement et tôt. Par exemple : « Je préfère d\'abord apprendre à connaître quelqu\'un par messages avant de le rencontrer en personne » ou « Je ne suis pas à l\'aise pour partager des photos pour l\'instant. »';

  @override
  String get safetyAcademyLsnBoundariesS2 =>
      'Si quelqu\'un insiste à plusieurs reprises contre une limite que vous avez posée, c\'est un signal d\'alarme sérieux, quelles que soient ses excuses.';

  @override
  String get safetyAcademyLsnBoundariesS3 => 'Exemples de limites saines';

  @override
  String get safetyAcademyLsnBoundariesS3I0 =>
      'Décider quand vous êtes prêt(e) à partager votre numéro de téléphone';

  @override
  String get safetyAcademyLsnBoundariesS3I1 =>
      'Fixer une heure limite à laquelle on peut vous écrire';

  @override
  String get safetyAcademyLsnBoundariesS3I2 =>
      'Être clair sur votre espace personnel et votre niveau de confort lors d\'une rencontre';

  @override
  String get safetyAcademyLsnBoundariesS3I3 =>
      'Dire non aux projets qui vous semblent précipités ou inconfortables';

  @override
  String get safetyAcademyLsnBoundariesS3I4 =>
      'Faire une pause dans la conversation quand vous avez besoin d\'espace';

  @override
  String get safetyAcademyLsnBoundariesS4 =>
      'Rappelez-vous : poser des limites, ce n\'est pas être difficile. C\'est du respect de soi. Une personne qui vous apprécie respectera vos limites.';

  @override
  String get safetyAcademyLsnBoundariesQ0 =>
      'Vous dites à une nouvelle connexion que vous ne voulez pas encore partager votre numéro, et elle insiste. Qu\'est-ce que cela indique ?';

  @override
  String get safetyAcademyLsnBoundariesQ0O0 =>
      'Il ou elle s\'intéresse vraiment à vous';

  @override
  String get safetyAcademyLsnBoundariesQ0O1 =>
      'Il ou elle a juste hâte de faire avancer la conversation';

  @override
  String get safetyAcademyLsnBoundariesQ0O2 =>
      'Il ou elle ne respecte pas la limite que vous avez exprimée';

  @override
  String get safetyAcademyLsnBoundariesQ0O3 =>
      'C\'est un comportement normal quand on fait connaissance';

  @override
  String get safetyAcademyLsnBoundariesQ0Exp =>
      'Insister de manière répétée contre une limite clairement exprimée est irrespectueux et constitue un signal d\'alarme, quelle que soit la raison invoquée.';

  @override
  String get safetyAcademyLsnBoundariesQ1 =>
      'Quel est le meilleur moment pour exprimer une limite ?';

  @override
  String get safetyAcademyLsnBoundariesQ1O0 =>
      'Après qu\'elle a été franchie plusieurs fois';

  @override
  String get safetyAcademyLsnBoundariesQ1O1 =>
      'Clairement et tôt, avant que cela ne devienne un problème';

  @override
  String get safetyAcademyLsnBoundariesQ1O2 =>
      'Seulement si l\'autre personne le demande';

  @override
  String get safetyAcademyLsnBoundariesQ1O3 =>
      'Les limites ne sont pas nécessaires quand on rencontre de nouvelles personnes';

  @override
  String get safetyAcademyLsnBoundariesQ1Exp =>
      'Exprimer ses limites tôt et clairement évite les malentendus et pose les bases d\'un respect mutuel.';

  @override
  String get safetyAcademyLsnConsentTitle => 'Comprendre le consentement';

  @override
  String get safetyAcademyLsnConsentS0 =>
      'Le consentement est un accord clair, enthousiaste et continu. Il s\'applique à chaque interaction -- du partage d\'informations personnelles au contact physique.';

  @override
  String get safetyAcademyLsnConsentS1 =>
      'Le consentement ne concerne pas uniquement le contact physique. Partager les photos de quelqu\'un, transférer ses messages ou divulguer ses informations personnelles sans autorisation constitue aussi une violation du consentement.';

  @override
  String get safetyAcademyLsnConsentS2 => 'Principes clés du consentement';

  @override
  String get safetyAcademyLsnConsentS2I0 =>
      'Libre : sans pression, contrainte ni manipulation';

  @override
  String get safetyAcademyLsnConsentS2I1 =>
      'Réversible : chacun peut changer d\'avis à tout moment';

  @override
  String get safetyAcademyLsnConsentS2I2 =>
      'Éclairé : fondé sur des informations honnêtes et complètes';

  @override
  String get safetyAcademyLsnConsentS2I3 =>
      'Enthousiaste : recherchez un « oui » actif, pas seulement l\'absence de « non »';

  @override
  String get safetyAcademyLsnConsentS2I4 =>
      'Spécifique : consentir à une chose ne signifie pas consentir à tout';

  @override
  String get safetyAcademyLsnConsentS3 =>
      'Le silence ou l\'absence de « non » ne valent pas consentement. Recherchez toujours un accord clair et positif.';

  @override
  String get safetyAcademyLsnConsentS4 =>
      'Demander le consentement n\'a rien de gênant : cela montre de la maturité et du respect. De simples questions comme « Est-ce que ça vous va ? » ou « Aimeriez-vous… ? » font une grande différence.';

  @override
  String get safetyAcademyLsnConsentQ0 =>
      'Quelle affirmation décrit le mieux le consentement ?';

  @override
  String get safetyAcademyLsnConsentQ0O0 => 'L\'absence de « non »';

  @override
  String get safetyAcademyLsnConsentQ0O1 =>
      'Un accord clair, enthousiaste et continu';

  @override
  String get safetyAcademyLsnConsentQ0O2 =>
      'Quelque chose de nécessaire uniquement pour le contact physique';

  @override
  String get safetyAcademyLsnConsentQ0O3 =>
      'Un accord donné une fois pour toutes les interactions futures';

  @override
  String get safetyAcademyLsnConsentQ0Exp =>
      'Le consentement doit être clair, enthousiaste et continu, et peut être retiré à tout moment. Il s\'applique à toutes les interactions.';

  @override
  String get safetyAcademyLsnConsentQ1 =>
      'Une personne rencontrée sur l\'app a accepté de vous rejoindre à un événement mais semble mal à l\'aise en arrivant. Que devez-vous faire ?';

  @override
  String get safetyAcademyLsnConsentQ1O0 =>
      'Il ou elle a déjà accepté, donc continuer comme prévu';

  @override
  String get safetyAcademyLsnConsentQ1O1 =>
      'Lui demander comment il ou elle se sent et proposer d\'aller ailleurs';

  @override
  String get safetyAcademyLsnConsentQ1O2 =>
      'Ignorer le malaise : c\'est sûrement le stress';

  @override
  String get safetyAcademyLsnConsentQ1O3 =>
      'Lui dire qu\'il ou elle n\'aurait pas dû accepter s\'il ou elle ne voulait pas venir';

  @override
  String get safetyAcademyLsnConsentQ1Exp =>
      'Le consentement est réversible. Si quelqu\'un semble mal à l\'aise, prenez de ses nouvelles. Son bien-être compte plus que les projets.';

  @override
  String get safetyAcademyModCulturalSensitivityTitle =>
      'Sensibilité culturelle';

  @override
  String get safetyAcademyModCulturalSensitivityDesc =>
      'Vivez des amitiés interculturelles avec respect, curiosité et ouverture.';

  @override
  String get safetyAcademyLsnCulturalDosTitle =>
      'Les bonnes pratiques interculturelles';

  @override
  String get safetyAcademyLsnCulturalDosS0 =>
      'Faire connaissance avec quelqu\'un d\'une autre culture peut être l\'une des expériences les plus enrichissantes. Abordez-la avec une curiosité sincère, du respect et l\'envie d\'apprendre.';

  @override
  String get safetyAcademyLsnCulturalDosS1 =>
      'Posez des questions ouvertes sur sa culture avec une curiosité sincère, pas comme un interrogatoire. « Quelles traditions comptent pour ta famille ? » vaut bien mieux que « Chez vous, les gens font vraiment X ? »';

  @override
  String get safetyAcademyLsnCulturalDosS2 =>
      'Bonnes pratiques pour les connexions interculturelles';

  @override
  String get safetyAcademyLsnCulturalDosS2I0 =>
      'Renseignez-vous sur les coutumes culturelles de base avant de vous retrouver';

  @override
  String get safetyAcademyLsnCulturalDosS2I1 =>
      'Montrez un intérêt sincère pour ses origines et ses traditions';

  @override
  String get safetyAcademyLsnCulturalDosS2I2 =>
      'Soyez prêt à essayer de nouveaux plats, activités et expériences';

  @override
  String get safetyAcademyLsnCulturalDosS2I3 =>
      'Respectez les dynamiques familiales qui peuvent différer des vôtres';

  @override
  String get safetyAcademyLsnCulturalDosS2I4 =>
      'Apprenez quelques mots ou expressions dans sa langue';

  @override
  String get safetyAcademyLsnCulturalDosS2I5 =>
      'Demandez-lui comment elle préfère être appelée ou présentée';

  @override
  String get safetyAcademyLsnCulturalDosS3 =>
      'N\'oubliez pas que chaque personne est d\'abord un individu. La connaissance culturelle est un point de départ, mais apprenez à connaître la personne au-delà des stéréotypes.';

  @override
  String get safetyAcademyLsnCulturalDosQ0 =>
      'Quelle est la meilleure façon de découvrir la culture d\'un nouvel ami ?';

  @override
  String get safetyAcademyLsnCulturalDosQ0O0 =>
      'Faire des suppositions d\'après ce que vous avez vu dans des films';

  @override
  String get safetyAcademyLsnCulturalDosQ0O1 =>
      'Poser des questions ouvertes et réfléchies avec une curiosité sincère';

  @override
  String get safetyAcademyLsnCulturalDosQ0O2 =>
      'L\'interroger sur des faits culturels lus en ligne';

  @override
  String get safetyAcademyLsnCulturalDosQ0O3 =>
      'Éviter complètement le sujet pour ne pas offenser';

  @override
  String get safetyAcademyLsnCulturalDosQ0Exp =>
      'Une curiosité sincère et respectueuse est la meilleure approche. Laissez la personne partager ce qui compte pour elle.';

  @override
  String get safetyAcademyLsnCulturalDosQ1 =>
      'Un nouvel ami mentionne une tradition familiale que vous ne comprenez pas. Que devez-vous faire ?';

  @override
  String get safetyAcademyLsnCulturalDosQ1O0 =>
      'Hocher la tête et faire semblant de comprendre';

  @override
  String get safetyAcademyLsnCulturalDosQ1O1 =>
      'Lui demander d\'en dire plus et pourquoi c\'est important';

  @override
  String get safetyAcademyLsnCulturalDosQ1O2 =>
      'Lui dire que vos traditions sont différentes';

  @override
  String get safetyAcademyLsnCulturalDosQ1O3 => 'Changer de sujet';

  @override
  String get safetyAcademyLsnCulturalDosQ1Exp =>
      'Lui demander d\'en dire plus témoigne de votre respect et d\'un intérêt sincère pour son univers.';

  @override
  String get safetyAcademyLsnCulturalDontsTitle =>
      'Les erreurs interculturelles à éviter';

  @override
  String get safetyAcademyLsnCulturalDontsS0 =>
      'Des remarques bien intentionnées mais mal informées peuvent blesser ou sembler méprisantes. Connaître les pièges courants vous aide à vivre des amitiés interculturelles avec tact.';

  @override
  String get safetyAcademyLsnCulturalDontsS1 =>
      'Ne réduisez jamais quelqu\'un à son origine ou à sa nationalité. Des remarques comme « J\'ai toujours voulu un ami de [pays] » ou « Tu parles bien pour un [nationalité] » blessent plus qu\'elles ne flattent.';

  @override
  String get safetyAcademyLsnCulturalDontsS2 =>
      'À éviter dans les connexions interculturelles';

  @override
  String get safetyAcademyLsnCulturalDontsS2I0 =>
      'Ne fétichisez pas et n\'exotisez pas sa culture ou son apparence';

  @override
  String get safetyAcademyLsnCulturalDontsS2I1 =>
      'Ne partez pas du principe que la personne représente toute sa culture';

  @override
  String get safetyAcademyLsnCulturalDontsS2I2 =>
      'Ne plaisantez pas sur son accent ou sa langue';

  @override
  String get safetyAcademyLsnCulturalDontsS2I3 =>
      'Ne lui mettez pas la pression pour expliquer ou défendre ses pratiques culturelles';

  @override
  String get safetyAcademyLsnCulturalDontsS2I4 =>
      'Ne la comparez pas à des stéréotypes ou à des représentations médiatiques';

  @override
  String get safetyAcademyLsnCulturalDontsS2I5 =>
      'Ne minimisez pas les différences culturelles';

  @override
  String get safetyAcademyLsnCulturalDontsS3 =>
      'Si vous commettez un faux pas culturel, excusez-vous sincèrement, tirez-en une leçon et passez à autre chose. Ne vous excusez pas à outrance au point de tout ramener à vos propres sentiments.';

  @override
  String get safetyAcademyLsnCulturalDontsQ0 =>
      'Quelle remarque manque de sensibilité culturelle ?';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O0 =>
      '« J\'aimerais beaucoup goûter la cuisine de ton pays. »';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O1 =>
      '« Tu as un physique tellement exotique. »';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O2 =>
      '« Quelle langue parles-tu à la maison ? »';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O3 =>
      '« Parle-moi d\'une fête que ta famille célèbre. »';

  @override
  String get safetyAcademyLsnCulturalDontsQ0Exp =>
      'Qualifier quelqu\'un d\'« exotique » le réduit à son apparence et à ses origines culturelles. C\'est objectivant, pas flatteur.';

  @override
  String get safetyAcademyLsnCulturalDontsQ1 =>
      'Vous dites par mégarde quelque chose de culturellement maladroit. Quelle est la meilleure réaction ?';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O0 =>
      'Faire comme si de rien n\'était';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O1 =>
      'S\'excuser sincèrement, en tirer une leçon et passer à autre chose';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O2 =>
      'Expliquer que vous ne vouliez pas dire ça';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O3 =>
      'S\'excuser à outrance et y revenir sans cesse';

  @override
  String get safetyAcademyLsnCulturalDontsQ1Exp =>
      'Des excuses sincères et brèves, suivies d\'un réel effort pour mieux faire, sont la réaction la plus mature.';

  @override
  String get safetyAcademyLsnCulturalCommunicationTitle =>
      'Communiquer entre cultures';

  @override
  String get safetyAcademyLsnCulturalCommunicationS0 =>
      'Les styles de communication varient considérablement d\'une culture à l\'autre. Ce qui paraît direct et honnête dans une culture peut sembler impoli dans une autre. Comprendre ces différences évite les malentendus.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS1 =>
      'Si quelque chose que l\'autre personne dit ou fait vous déroute, supposez une intention positive et demandez des précisions plutôt que de tirer des conclusions hâtives.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2 =>
      'Différences culturelles de communication à connaître';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I0 =>
      'Styles de communication directs ou indirects';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I1 =>
      'Normes d\'espace personnel et de contact physique';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I2 =>
      'Attentes en matière de contact visuel (certaines cultures jugent le regard direct irrespectueux)';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I3 =>
      'Rapport à la ponctualité et au temps';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I4 =>
      'Coutumes et attentes liées aux cadeaux';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I5 =>
      'La place de l\'humour et les sujets tabous';

  @override
  String get safetyAcademyLsnCulturalCommunicationS3 =>
      'Dans le doute, communiquez ouvertement. Un simple « Je veux être sûr·e de bien te comprendre » aide beaucoup à combler les écarts culturels.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0 =>
      'La personne avec qui vous parlez évite le contact visuel direct. Que devez-vous en penser ?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O0 =>
      'Elle ne s\'intéresse pas à vous';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O1 =>
      'Elle n\'est pas honnête';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O2 =>
      'Ce peut être une norme culturelle – ne présumez pas d\'une mauvaise intention';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O3 =>
      'Elle est timide et a besoin d\'être davantage encouragée';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0Exp =>
      'Dans de nombreuses cultures, éviter le regard direct est une marque de respect, et non de désintérêt ou de malhonnêteté.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1 =>
      'Quelle est la meilleure approche lorsque des différences culturelles de communication créent de la confusion ?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O0 => 'Imaginer le pire';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O1 =>
      'L\'ignorer en espérant que ça s\'arrange';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O2 =>
      'Demander des précisions avec ouverture d\'esprit';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O3 =>
      'Lui dire de communiquer davantage comme vous';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1Exp =>
      'Une communication ouverte et sans jugement est la meilleure façon d\'aborder les différences culturelles.';

  @override
  String get safetyAcademyModOnlineSafetyTitle =>
      'Sécurité en ligne : les bases';

  @override
  String get safetyAcademyModOnlineSafetyDesc =>
      'Apprenez à protéger votre identité et à repérer les arnaques potentielles lorsque vous rencontrez des gens en ligne.';

  @override
  String get safetyAcademyLsnProfileProtectionTitle => 'Protection du profil';

  @override
  String get safetyAcademyLsnProfileProtectionS0 =>
      'Votre profil est votre première impression, mais il peut aussi exposer des informations personnelles si vous n\'êtes pas prudent. Partager juste ce qu\'il faut vous protège tout en montrant votre personnalité.';

  @override
  String get safetyAcademyLsnProfileProtectionS1 =>
      'Utilisez une photo unique qui ne figure pas sur vos autres profils de réseaux sociaux. Les recherches d\'image inversée peuvent relier vos comptes entre eux.';

  @override
  String get safetyAcademyLsnProfileProtectionS2 =>
      'N\'indiquez jamais votre nom complet, votre lieu de travail, votre adresse ou votre numéro de téléphone dans votre bio.';

  @override
  String get safetyAcademyLsnProfileProtectionS3 =>
      'Check-list de sécurité du profil';

  @override
  String get safetyAcademyLsnProfileProtectionS3I0 =>
      'Supprimer ou recadrer les repères identifiables proches de votre domicile';

  @override
  String get safetyAcademyLsnProfileProtectionS3I1 =>
      'Utiliser uniquement un prénom ou un surnom';

  @override
  String get safetyAcademyLsnProfileProtectionS3I2 =>
      'Désactiver les métadonnées de localisation des photos publiées';

  @override
  String get safetyAcademyLsnProfileProtectionS3I3 =>
      'Éviter les photos en tenue de travail ou avec un badge visible';

  @override
  String get safetyAcademyLsnProfileProtectionS3I4 =>
      'Relire votre profil du point de vue d\'un inconnu';

  @override
  String get safetyAcademyLsnProfileProtectionS4 =>
      'Un profil bien conçu trouve l\'équilibre entre ouverture et vie privée. Partagez vos centres d\'intérêt et vos valeurs, mais gardez les détails comme votre routine quotidienne ou votre quartier pour des conversations ultérieures.';

  @override
  String get safetyAcademyLsnProfileProtectionQ0 =>
      'Lequel de ces éléments pouvez-vous inclure sans risque dans votre profil ?';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O0 => 'Votre adresse';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O1 => 'Vos loisirs préférés';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O2 =>
      'Le nom de votre employeur et votre service';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O3 =>
      'Votre numéro de téléphone';

  @override
  String get safetyAcademyLsnProfileProtectionQ0Exp =>
      'Partager vos loisirs est idéal pour lancer la conversation sans révéler de détails personnels qui pourraient permettre de vous localiser.';

  @override
  String get safetyAcademyLsnProfileProtectionQ1 =>
      'Pourquoi utiliser des photos uniques sur votre profil ?';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O0 =>
      'Pour obtenir plus de vues de profil';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O1 =>
      'Parce que les applis sociales compressent les images';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O2 =>
      'Pour éviter qu\'une recherche d\'image inversée mène à vos autres comptes';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O3 =>
      'Les photos uniques obtiennent plus de likes';

  @override
  String get safetyAcademyLsnProfileProtectionQ1Exp =>
      'Les outils de recherche d\'image inversée peuvent relier votre profil à vos réseaux sociaux, blogs ou pages professionnelles et révéler votre identité complète.';

  @override
  String get safetyAcademyLsnProfileProtectionQ2 =>
      'Que devez-vous vérifier avant de publier une photo ?';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O0 =>
      'Qu\'elle a un joli filtre';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O1 =>
      'Que les métadonnées de localisation sont supprimées et qu\'aucun repère identifiable n\'est visible';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O2 =>
      'Qu\'elle a été prise récemment';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O3 => 'Que c\'est un selfie';

  @override
  String get safetyAcademyLsnProfileProtectionQ2Exp =>
      'Les métadonnées des photos (données EXIF) peuvent contenir des coordonnées GPS. Des repères comme des panneaux de rue ou des noms de bâtiments peuvent aussi révéler votre position.';

  @override
  String get safetyAcademyLsnScamRecognitionTitle => 'Reconnaître les arnaques';

  @override
  String get safetyAcademyLsnScamRecognitionS0 =>
      'Les arnaques à l\'usurpation d\'identité et à l\'argent coûtent des milliards aux victimes chaque année dans le monde. Les escrocs créent vite un lien émotionnel puis l\'exploitent pour obtenir de l\'argent ou des données personnelles. Connaître les signes peut vous protéger.';

  @override
  String get safetyAcademyLsnScamRecognitionS1 =>
      'Si quelqu\'un vous demande de l\'argent, des cartes cadeaux, des cryptomonnaies ou une aide financière peu après votre rencontre en ligne -- aussi convaincante que soit l\'histoire --, c\'est presque certainement une arnaque.';

  @override
  String get safetyAcademyLsnScamRecognitionS2 =>
      'Faites un appel vidéo assez tôt. Les escrocs évitent la vidéo en direct, car elle démasque les fausses identités. Si quelqu\'un évite la vidéo à plusieurs reprises, soyez vigilant.';

  @override
  String get safetyAcademyLsnScamRecognitionS3 =>
      'Signaux d\'alerte courants d\'arnaque';

  @override
  String get safetyAcademyLsnScamRecognitionS3I0 =>
      'Le profil semble trop parfait (photos dignes d\'un mannequin, carrière de rêve)';

  @override
  String get safetyAcademyLsnScamRecognitionS3I1 =>
      'Prétend être militaire en mission à l\'étranger, travailler sur une plateforme pétrolière ou dans les affaires à l\'international';

  @override
  String get safetyAcademyLsnScamRecognitionS3I2 =>
      'Montre un attachement intense ou des flatteries anormalement vite';

  @override
  String get safetyAcademyLsnScamRecognitionS3I3 =>
      'Évite les appels vidéo ou les rencontres en personne';

  @override
  String get safetyAcademyLsnScamRecognitionS3I4 =>
      'Demande de l\'argent pour des urgences, des voyages ou des frais médicaux';

  @override
  String get safetyAcademyLsnScamRecognitionS3I5 =>
      'Vous demande rapidement de poursuivre la conversation sur une autre plateforme';

  @override
  String get safetyAcademyLsnScamRecognitionS4 =>
      'Si vous soupçonnez une arnaque, cessez immédiatement toute communication. Signalez le profil dans l\'application et envisagez de porter plainte auprès des autorités locales.';

  @override
  String get safetyAcademyLsnScamRecognitionQ0 =>
      'Une personne avec qui vous vous êtes connecté il y a une semaine dit que vous comptez énormément pour elle et vous demande de l\'argent pour venir vous voir. Que devez-vous faire ?';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O0 =>
      'Envoyer l\'argent – la personne semble sincère';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O1 =>
      'Demander plus de détails sur la raison de ce besoin d\'argent';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O2 =>
      'Reconnaître un schéma classique d\'arnaque à l\'argent et la signaler';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O3 =>
      'Proposer d\'acheter directement son billet d\'avion';

  @override
  String get safetyAcademyLsnScamRecognitionQ0Exp =>
      'Créer très vite un attachement émotionnel intense puis demander de l\'argent est le schéma typique des arnaques financières. Signalez et bloquez.';

  @override
  String get safetyAcademyLsnScamRecognitionQ1 =>
      'Quelle profession les escrocs utilisent-ils souvent comme couverture ?';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O0 => 'Enseignant du coin';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O1 =>
      'Militaire en mission à l\'étranger';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O2 => 'Barista du quartier';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O3 => 'Employé de bureau du coin';

  @override
  String get safetyAcademyLsnScamRecognitionQ1Exp =>
      'Les escrocs invoquent souvent une mission militaire, un travail offshore ou des affaires internationales pour expliquer pourquoi ils ne peuvent ni vous rencontrer ni faire d\'appel vidéo.';

  @override
  String get safetyAcademyLsnScamRecognitionQ2 =>
      'Quelle est une bonne première étape pour vérifier qu\'une personne est réelle ?';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O0 => 'Demander son adresse';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O1 => 'Demander un appel vidéo';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O2 =>
      'Lui envoyer de l\'argent pour tester sa réaction';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O3 =>
      'La rechercher sur tous les réseaux sociaux';

  @override
  String get safetyAcademyLsnScamRecognitionQ2Exp =>
      'Un appel vidéo est l\'un des moyens les plus simples de vérifier qu\'une personne est bien celle qu\'elle prétend être. Les escrocs évitent généralement la vidéo en direct à tout prix.';

  @override
  String get safetyAcademyLsnRedFlagsTitle =>
      'Signaux d\'alerte comportementaux';

  @override
  String get safetyAcademyLsnRedFlagsS0 =>
      'Au-delà des arnaques, certains comportements peuvent révéler des personnes contrôlantes, manipulatrices ou potentiellement dangereuses. Apprendre à les repérer tôt peut vous éviter des situations néfastes.';

  @override
  String get safetyAcademyLsnRedFlagsS1 =>
      'Une personne qui vous pousse à partager des photos intimes, à vous rencontrer immédiatement ou à vous isoler de vos amis fait preuve d\'un comportement contrôlant.';

  @override
  String get safetyAcademyLsnRedFlagsS2 => 'Signaux d\'alerte comportementaux';

  @override
  String get safetyAcademyLsnRedFlagsS2I0 =>
      'Jalousie excessive ou possessivité avant même de vous être rencontrés';

  @override
  String get safetyAcademyLsnRedFlagsS2I1 =>
      'Pression pour obtenir des informations personnelles ou du contenu intime';

  @override
  String get safetyAcademyLsnRedFlagsS2I2 =>
      'Se mettre en colère quand vous ne répondez pas immédiatement';

  @override
  String get safetyAcademyLsnRedFlagsS2I3 =>
      'Ne pas respecter les limites que vous avez exprimées';

  @override
  String get safetyAcademyLsnRedFlagsS2I4 =>
      'Vous culpabiliser de passer du temps avec d\'autres personnes';

  @override
  String get safetyAcademyLsnRedFlagsS2I5 =>
      'Des histoires incohérentes à son propre sujet';

  @override
  String get safetyAcademyLsnRedFlagsS3 =>
      'Fiez-vous à votre instinct. Si une conversation vous met mal à l\'aise, vous ne devez d\'explication à personne. Vous avez toujours le droit d\'arrêter de répondre, de bloquer ou de signaler.';

  @override
  String get safetyAcademyLsnRedFlagsS4 =>
      'Les relations saines reposent sur le respect mutuel. Une personne qui tient vraiment à vous respectera votre rythme, vos limites et votre autonomie.';

  @override
  String get safetyAcademyLsnRedFlagsQ0 =>
      'Une nouvelle connexion s\'énerve quand vous mettez une heure à répondre. Qu\'est-ce que cela indique ?';

  @override
  String get safetyAcademyLsnRedFlagsQ0O0 =>
      'La personne vous apprécie vraiment';

  @override
  String get safetyAcademyLsnRedFlagsQ0O1 =>
      'La personne est enthousiaste à l\'idée de discuter';

  @override
  String get safetyAcademyLsnRedFlagsQ0O2 =>
      'Un comportement potentiellement contrôlant';

  @override
  String get safetyAcademyLsnRedFlagsQ0O3 =>
      'La personne est simplement anxieuse';

  @override
  String get safetyAcademyLsnRedFlagsQ0Exp =>
      'Se mettre en colère à cause des délais de réponse avant même de vous être rencontrés est un signe de comportement contrôlant. Chacun a le droit de gérer son emploi du temps.';

  @override
  String get safetyAcademyLsnRedFlagsQ1 =>
      'Quelle est la meilleure réaction lorsque quelqu\'un vous pousse à envoyer des photos intimes ?';

  @override
  String get safetyAcademyLsnRedFlagsQ1O0 =>
      'Les envoyer pour éviter les conflits';

  @override
  String get safetyAcademyLsnRedFlagsQ1O1 =>
      'Refuser fermement et, si la personne insiste, la bloquer et la signaler';

  @override
  String get safetyAcademyLsnRedFlagsQ1O2 =>
      'Lui demander d\'envoyer les siennes d\'abord';

  @override
  String get safetyAcademyLsnRedFlagsQ1O3 =>
      'Promettre de les envoyer plus tard';

  @override
  String get safetyAcademyLsnRedFlagsQ1Exp =>
      'Vous ne devriez jamais vous sentir obligé de partager du contenu intime. Une personne respectueuse acceptera votre décision sans insister.';

  @override
  String get safetyAcademyLsnRedFlagsQ2 =>
      'Lequel de ces signes est sain lors des premières conversations ?';

  @override
  String get safetyAcademyLsnRedFlagsQ2O0 =>
      'La personne veut connaître votre emploi du temps exact';

  @override
  String get safetyAcademyLsnRedFlagsQ2O1 =>
      'La personne respecte votre rythme et vos limites';

  @override
  String get safetyAcademyLsnRedFlagsQ2O2 =>
      'Ils vous déclarent des sentiments intenses dès les premiers jours';

  @override
  String get safetyAcademyLsnRedFlagsQ2O3 =>
      'La personne vous demande d\'arrêter de parler à d\'autres personnes sur l\'appli';

  @override
  String get safetyAcademyLsnRedFlagsQ2Exp =>
      'Le respect du rythme et des limites est la base d\'une relation saine. Tout le reste de cette liste est un signal d\'alerte potentiel.';

  @override
  String get safetyAcademyModEmotionalIntelligenceTitle =>
      'Intelligence émotionnelle';

  @override
  String get safetyAcademyModEmotionalIntelligenceDesc =>
      'Comprenez les styles d\'attachement et les langages de l\'appréciation, et développez votre conscience émotionnelle.';

  @override
  String get safetyAcademyLsnAttachmentStylesTitle => 'Styles d\'attachement';

  @override
  String get safetyAcademyLsnAttachmentStylesS0 =>
      'La théorie de l\'attachement explique comment nos premières relations façonnent notre manière de créer des liens avec les autres à l\'âge adulte. Comprendre votre style d\'attachement peut vous aider à construire des amitiés plus saines.';

  @override
  String get safetyAcademyLsnAttachmentStylesS1 =>
      'Les quatre principaux styles d\'attachement sont : sécure, anxieux, évitant et désorganisé. La plupart des gens présentent un mélange, et ces styles peuvent évoluer avec de la prise de conscience et des efforts.';

  @override
  String get safetyAcademyLsnAttachmentStylesS2 =>
      'Les quatre styles d\'attachement';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I0 =>
      'Sécure : à l\'aise avec la proximité, confiant, communicatif';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I1 =>
      'Anxieux : recherche la proximité mais craint le rejet, peut avoir besoin d\'être davantage rassuré';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I2 =>
      'Évitant : accorde une grande valeur à l\'indépendance, peut prendre ses distances quand la relation devient intime';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I3 =>
      'Désorganisé : mélange d\'anxieux et d\'évitant, souvent lié à des expériences précoces difficiles';

  @override
  String get safetyAcademyLsnAttachmentStylesS3 =>
      'Connaître votre style vous aide à comprendre vos réactions. Si vous tendez vers un attachement anxieux, vous reconnaîtrez peut-être que votre envie d\'envoyer message sur message vient de la peur, et non d\'un réel besoin. Si vous êtes plutôt évitant, vous remarquerez peut-être votre tendance à vous fermer quand les émotions montent.';

  @override
  String get safetyAcademyLsnAttachmentStylesS4 =>
      'Comprendre le style d\'attachement d\'un ami vous aide à réagir avec empathie plutôt qu\'avec frustration. Un ami évitant qui prend ses distances ne vous rejette pas -- c\'est son mécanisme d\'adaptation.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0 =>
      'Un ami a besoin de beaucoup d\'être rassuré et devient anxieux quand vous ne répondez pas vite. Quel style d\'attachement cela pourrait-il refléter ?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O0 => 'Sécure';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O1 => 'Anxieux';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O2 => 'Évitant';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O3 => 'Désorganisé';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0Exp =>
      'L\'attachement anxieux se caractérise par un fort désir de proximité et la peur du rejet, ce qui entraîne souvent un besoin fréquent d\'être rassuré.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1 =>
      'Quelle est la réaction la plus saine lorsque vous reconnaissez vos schémas d\'attachement ?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O0 =>
      'Accepter qu\'ils ne peuvent pas changer';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O1 =>
      'Rendre vos parents responsables de votre style';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O2 =>
      'Utiliser cette prise de conscience pour mieux communiquer et tendre vers un attachement sécure';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O3 =>
      'Ne passer du temps qu\'avec des personnes ayant le même style';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1Exp =>
      'Les styles d\'attachement peuvent évoluer grâce à la conscience de soi, à la communication et parfois à un accompagnement professionnel.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2 =>
      'Une personne au style d\'attachement évitant pourrait :';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O0 =>
      'Envoyer plusieurs messages si vous ne répondez pas vite';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O1 =>
      'Prendre ses distances ou se fermer quand une amitié devient émotionnellement proche';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O2 =>
      'Vouloir passer chaque instant ensemble';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O3 =>
      'Parler très ouvertement de ses sentiments dès le début';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2Exp =>
      'L\'attachement évitant se manifeste souvent par une prise de distance quand la proximité émotionnelle augmente, comme mécanisme d\'autoprotection.';

  @override
  String get safetyAcademyLsnLoveLanguagesTitle =>
      'Langages de l\'appréciation';

  @override
  String get safetyAcademyLsnLoveLanguagesS0 =>
      'Le concept des langages de l\'appréciation, adapté des travaux du Dr Gary Chapman, suggère que chacun exprime et reçoit l\'appréciation de cinq façons principales. Connaître le vôtre et celui de vos amis peut renforcer vos liens.';

  @override
  String get safetyAcademyLsnLoveLanguagesS1 =>
      'Les cinq langages de l\'appréciation';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I0 =>
      'Paroles valorisantes : compliments, encouragements et marques d\'appréciation';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I1 =>
      'Les moments de qualité : attention exclusive et présence';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I2 =>
      'Recevoir des cadeaux : des attentions réfléchies (peu importe le prix)';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I3 =>
      'Les services rendus : des gestes qui facilitent la vie ou témoignent de l\'attention';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I4 =>
      'Gestes amicaux : une poignée de main, un check ou une accolade quand c\'est bienvenu';

  @override
  String get safetyAcademyLsnLoveLanguagesS2 =>
      'Observez comment quelqu\'un exprime son appréciation -- c\'est probablement son langage. S\'il vous complimente toujours, il apprécie sans doute les paroles valorisantes.';

  @override
  String get safetyAcademyLsnLoveLanguagesS3 =>
      'Avoir des langages de l\'appréciation différents est courant et gérable. La clé, c\'est la communication : dites à vos amis ce qui vous fait vous sentir apprécié et posez-leur la même question.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0 =>
      'Un ami prend toujours du temps pour vous et range son téléphone pendant vos conversations. Son langage de l\'appréciation est probablement :';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O0 => 'Les paroles valorisantes';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O1 => 'Les moments de qualité';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O2 => 'Les cadeaux';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O3 => 'Gestes amicaux';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0Exp =>
      'Accorder une attention totale et privilégier la présence caractérise le temps de qualité comme langage de l\'appréciation.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1 =>
      'Vous appréciez les paroles valorisantes, mais un ami montre son appréciation par des services rendus. Que devez-vous faire ?';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O0 =>
      'Accepter que vous êtes incompatibles';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O1 =>
      'Lui dire ce dont vous avez besoin et apprendre à reconnaître sa façon de montrer son appréciation';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O2 =>
      'Changer votre langage de l\'appréciation pour qu\'il corresponde au sien';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O3 => 'Ignorer la différence';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1Exp =>
      'La communication est essentielle. Exprimez vos besoins tout en apprenant à apprécier la façon dont votre ami montre que vous comptez pour lui.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessTitle =>
      'Conscience émotionnelle';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS0 =>
      'La conscience émotionnelle est la capacité à reconnaître, comprendre et gérer vos propres émotions tout en étant attentif à celles des autres. Quand vous rencontrez de nouvelles personnes, elle évite les décisions impulsives et crée des liens plus profonds.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS1 =>
      'Avant de répondre à un message frustrant, faites une pause et identifiez ce que vous ressentez vraiment. Êtes-vous blessé ? Anxieux ? Déçu ? Nommer l\'émotion réduit son emprise.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2 =>
      'Développer sa conscience émotionnelle';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I0 =>
      'Entraînez-vous à nommer vos émotions tout au long de la journée';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I1 =>
      'Repérez les sensations physiques liées aux émotions (poitrine serrée = anxiété)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I2 =>
      'Tenez un journal de vos expériences sociales et de vos réactions émotionnelles';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I3 =>
      'Faites la différence entre réagir (impulsif) et répondre (réfléchi)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I4 =>
      'Prenez l\'habitude de faire une pause : attendez avant d\'envoyer des messages chargés d\'émotion';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS3 =>
      'La conscience émotionnelle ne consiste pas à réprimer ses émotions. Elle consiste à les comprendre suffisamment pour choisir comment agir face à elles.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS4 =>
      'Quand vous parvenez à dire « Je me suis senti blessé quand tu as annulé nos projets » plutôt que « De toute évidence, tu te fiches de moi », vous transformez le conflit en lien. C\'est cela, l\'intelligence émotionnelle en action.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0 =>
      'Un nouvel ami annule vos plans à la dernière minute et vous êtes en colère. Quelle est la réaction émotionnellement consciente ?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O0 =>
      'Envoyer immédiatement un message en colère';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O1 =>
      'Lui faire du ghosting pour le punir';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O2 =>
      'Faire une pause, identifier vos émotions, puis expliquer calmement ce que l\'annulation vous a fait ressentir';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O3 =>
      'Faire comme si cela vous était égal';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0Exp =>
      'Prendre le temps d\'identifier vos émotions puis les exprimer calmement mène à de meilleurs résultats qu\'une réaction impulsive.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1 =>
      'Que signifie la conscience émotionnelle ?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O0 =>
      'Ne jamais montrer ses émotions';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O1 => 'Être toujours heureux';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O2 =>
      'Reconnaître et comprendre ses émotions pour choisir comment agir face à elles';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O3 =>
      'Exprimer chaque émotion dès qu\'on la ressent';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1Exp =>
      'La conscience émotionnelle repose sur la reconnaissance et la compréhension, ce qui permet des réponses réfléchies plutôt que des réactions impulsives.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2 =>
      'Lequel est un exemple de « répondre » plutôt que de « réagir » ?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O0 =>
      'Taper une réponse en colère dès que vous êtes contrarié';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O1 =>
      'Attendre, réfléchir à ce que vous ressentez, puis rédiger un message réfléchi';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O2 =>
      'Ignorer complètement le message';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O3 =>
      'Vider votre sac auprès d\'amis avant de répondre';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2Exp =>
      'Répondre implique une pause délibérée pour réfléchir, alors que réagir est dicté par l\'émotion immédiate.';

  @override
  String get safetyAcademyModFirstMeetingTitle =>
      'Guide de la première rencontre';

  @override
  String get safetyAcademyModFirstMeetingDesc =>
      'Conseils essentiels pour des premières rencontres sûres et sereines avec des personnes connues en ligne.';

  @override
  String get safetyAcademyLsnPublicPlacesTitle =>
      'Se rencontrer dans des lieux publics';

  @override
  String get safetyAcademyLsnPublicPlacesS0 =>
      'Rencontrer pour la première fois une personne connue via une appli est excitant, mais la sécurité passe toujours en premier. Choisir le bon lieu pose les bases d\'une expérience sereine.';

  @override
  String get safetyAcademyLsnPublicPlacesS1 =>
      'Choisissez un café animé, un restaurant ou un parc public pour votre première rencontre. Connaître le lieu vous donne un avantage – vous savez où sont les sorties et vous connaissez le personnel.';

  @override
  String get safetyAcademyLsnPublicPlacesS2 =>
      'Pour une première rencontre, n\'acceptez jamais de vous retrouver chez quelqu\'un, dans un endroit isolé ou dans un lieu que vous ne connaissez pas.';

  @override
  String get safetyAcademyLsnPublicPlacesS3 =>
      'Check-list du lieu de la première rencontre';

  @override
  String get safetyAcademyLsnPublicPlacesS3I0 =>
      'Choisissez un lieu public et bien éclairé';

  @override
  String get safetyAcademyLsnPublicPlacesS3I1 =>
      'Choisissez un endroit que vous connaissez';

  @override
  String get safetyAcademyLsnPublicPlacesS3I2 =>
      'Assurez-vous qu\'il y a d\'autres personnes sur place';

  @override
  String get safetyAcademyLsnPublicPlacesS3I3 =>
      'Vérifiez que vous avez du réseau sur place';

  @override
  String get safetyAcademyLsnPublicPlacesS3I4 =>
      'Prévoyez un plan de repli si vous devez partir rapidement';

  @override
  String get safetyAcademyLsnPublicPlacesQ0 =>
      'Quel est le lieu le plus sûr pour une première rencontre ?';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O0 => 'Son appartement';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O1 =>
      'Un café animé du centre-ville';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O2 =>
      'Un sentier de randonnée isolé';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O3 => 'Votre domicile';

  @override
  String get safetyAcademyLsnPublicPlacesQ0Exp =>
      'Un café animé est un lieu public, avec du personnel à proximité, et vous pouvez partir facilement si besoin.';

  @override
  String get safetyAcademyLsnPublicPlacesQ1 =>
      'Pourquoi choisir un lieu que vous connaissez ?';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O0 =>
      'Pour impressionner l\'autre personne avec vos recommandations';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O1 =>
      'Parce que vous connaissez les sorties, le personnel et les environs';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O2 =>
      'C\'est moins cher si vous connaissez la carte';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O3 =>
      'Cela n\'apporte aucun avantage réel';

  @override
  String get safetyAcademyLsnPublicPlacesQ1Exp =>
      'Connaître le lieu, c\'est savoir comment partir rapidement et à qui demander de l\'aide si vous vous sentez mal à l\'aise.';

  @override
  String get safetyAcademyLsnSharingPlansTitle => 'Partager vos projets';

  @override
  String get safetyAcademyLsnSharingPlansS0 =>
      'Prévenir une personne de confiance que vous allez rencontrer quelqu\'un de nouveau est l\'une des mesures de sécurité les plus simples et efficaces. Un contact de confiance peut prendre de vos nouvelles et sait où chercher en cas de problème.';

  @override
  String get safetyAcademyLsnSharingPlansS1 =>
      'Partagez avec un ami de confiance le profil de l\'autre personne, le lieu et votre heure de retour prévue. Prévoyez un appel de contrôle 30 minutes après le début de la rencontre.';

  @override
  String get safetyAcademyLsnSharingPlansS2 =>
      'Informations à partager avec votre contact de sécurité';

  @override
  String get safetyAcademyLsnSharingPlansS2I0 =>
      'Capture d\'écran du profil de l\'autre personne';

  @override
  String get safetyAcademyLsnSharingPlansS2I1 =>
      'Nom (ou pseudo) de la personne que vous rencontrez';

  @override
  String get safetyAcademyLsnSharingPlansS2I2 =>
      'Jour, heure et lieu de la rencontre';

  @override
  String get safetyAcademyLsnSharingPlansS2I3 => 'Votre heure de retour prévue';

  @override
  String get safetyAcademyLsnSharingPlansS2I4 =>
      'Heure convenue pour donner des nouvelles (ex. : un appel ou un SMS)';

  @override
  String get safetyAcademyLsnSharingPlansS3 =>
      'Vous pouvez aussi envoyer les détails de la rencontre à un contact de confiance avant de partir. Il n\'y a aucune honte à être prudent -- la personne que vous rencontrez devrait le comprendre.';

  @override
  String get safetyAcademyLsnSharingPlansQ0 =>
      'Que devez-vous partager avec un ami de confiance avant une première rencontre ?';

  @override
  String get safetyAcademyLsnSharingPlansQ0O0 => 'Uniquement le nom du lieu';

  @override
  String get safetyAcademyLsnSharingPlansQ0O1 =>
      'Le profil de l\'autre personne, le lieu, l\'heure et le retour prévu';

  @override
  String get safetyAcademyLsnSharingPlansQ0O2 => 'Rien – c\'est privé';

  @override
  String get safetyAcademyLsnSharingPlansQ0O3 =>
      'Juste un message disant « je sors »';

  @override
  String get safetyAcademyLsnSharingPlansQ0Exp =>
      'Plus votre contact de sécurité dispose d\'informations, mieux il pourra vous aider en cas de problème.';

  @override
  String get safetyAcademyLsnSharingPlansQ1 =>
      'Quel est le bon moment pour un appel de contrôle ?';

  @override
  String get safetyAcademyLsnSharingPlansQ1O0 => 'Après la rencontre';

  @override
  String get safetyAcademyLsnSharingPlansQ1O1 =>
      'Environ 30 minutes après le début de la rencontre';

  @override
  String get safetyAcademyLsnSharingPlansQ1O2 =>
      'Un appel de contrôle n\'est pas nécessaire';

  @override
  String get safetyAcademyLsnSharingPlansQ1O3 =>
      'Avant de partir à la rencontre';

  @override
  String get safetyAcademyLsnSharingPlansQ1Exp =>
      'Un appel au bout de 30 minutes vous laisse assez de temps pour évaluer la situation et vous offre une porte de sortie facile si vous êtes mal à l\'aise.';

  @override
  String get safetyAcademyLsnTransportSafetyTitle =>
      'Sécurité des déplacements';

  @override
  String get safetyAcademyLsnTransportSafetyS0 =>
      'La façon dont vous vous rendez à une rencontre et en revenez compte autant que le lieu. Garder le contrôle de votre transport vous permet de partir quand vous le souhaitez.';

  @override
  String get safetyAcademyLsnTransportSafetyS1 =>
      'Ne laissez jamais une personne tout juste rencontrée en ligne venir vous chercher chez vous pour la première rencontre. Cela révèle votre adresse et vous rend dépendant d\'elle pour rentrer.';

  @override
  String get safetyAcademyLsnTransportSafetyS2 =>
      'Venez en voiture, en VTC ou en transports en commun. Gardez votre téléphone chargé et assez d\'argent pour rentrer chez vous en cas d\'urgence.';

  @override
  String get safetyAcademyLsnTransportSafetyS3 =>
      'Check-list sécurité des déplacements';

  @override
  String get safetyAcademyLsnTransportSafetyS3I0 =>
      'Organisez vous-même votre transport';

  @override
  String get safetyAcademyLsnTransportSafetyS3I1 =>
      'Gardez votre téléphone complètement chargé';

  @override
  String get safetyAcademyLsnTransportSafetyS3I2 =>
      'Prévoyez de l\'argent pour un trajet d\'urgence';

  @override
  String get safetyAcademyLsnTransportSafetyS3I3 =>
      'Partagez votre position en direct avec un contact de confiance';

  @override
  String get safetyAcademyLsnTransportSafetyS3I4 =>
      'Si vous venez en voiture, garez-vous dans un endroit bien éclairé';

  @override
  String get safetyAcademyLsnTransportSafetyS3I5 =>
      'Ne laissez pas votre verre sans surveillance si vous vous absentez';

  @override
  String get safetyAcademyLsnTransportSafetyQ0 =>
      'Pourquoi organiser votre propre transport pour une première rencontre ?';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O0 =>
      'Pour économiser de l\'essence';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O1 =>
      'Pour pouvoir partir quand vous voulez et garder votre adresse privée';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O2 =>
      'Pour éviter les embouteillages';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O3 =>
      'Parce qu\'il est plus facile de se garer seul';

  @override
  String get safetyAcademyLsnTransportSafetyQ0Exp =>
      'Avoir votre propre moyen de transport signifie que vous ne dépendez pas de l\'autre personne et que votre adresse reste privée.';

  @override
  String get safetyAcademyLsnTransportSafetyQ1 =>
      'Une personne que vous allez rencontrer pour la première fois propose de venir vous chercher chez vous. Que devez-vous faire ?';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O0 =>
      'Accepter – c\'est une gentille attention';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O1 =>
      'Refuser poliment et proposer de vous retrouver directement sur place';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O2 =>
      'Donner un carrefour à proximité plutôt que votre adresse exacte';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O3 =>
      'Accepter, mais demander à un ami de surveiller depuis la fenêtre';

  @override
  String get safetyAcademyLsnTransportSafetyQ1Exp =>
      'Se retrouver sur place garde votre adresse privée et vous assure un moyen de transport indépendant.';

  @override
  String get gamificationAchFirstMatchName => 'Première connexion';

  @override
  String get gamificationAchFirstMatchDesc =>
      'Obtenez votre premier like mutuel';

  @override
  String get gamificationAchConversationStarterName =>
      'Lanceur de conversations';

  @override
  String get gamificationAchConversationStarterDesc =>
      'Lancez 10 conversations';

  @override
  String get gamificationAchVideoChampionName => 'Champion de la vidéo';

  @override
  String get gamificationAchVideoChampionDesc => 'Effectuez 5 appels vidéo';

  @override
  String get gamificationAchProfileMasterName => 'Maître du profil';

  @override
  String get gamificationAchProfileMasterDesc =>
      'Complétez toutes les sections du profil à 100 %';

  @override
  String get gamificationAchGlobeTrotterName => 'Globe-trotter';

  @override
  String get gamificationAchGlobeTrotterDesc =>
      'Connectez-vous avec des gens de plus de 10 pays';

  @override
  String get gamificationAchGenerousHeartName => 'Âme généreuse';

  @override
  String get gamificationAchGenerousHeartDesc =>
      'Offrez des pièces à vos connexions';

  @override
  String get gamificationAchDailyDedicationName => 'Assiduité quotidienne';

  @override
  String get gamificationAchDailyDedicationDesc =>
      '7 jours de connexion consécutifs';

  @override
  String get gamificationAchSuperStarName => 'Superstar';

  @override
  String get gamificationAchSuperStarDesc =>
      'Recevez plus de 50 Priority Connects';

  @override
  String get gamificationAchSocialButterflyName => 'Papillon social';

  @override
  String get gamificationAchSocialButterflyDesc =>
      'Entretenez plus de 20 conversations actives';

  @override
  String get gamificationAchPerfectWeekName => 'Semaine parfaite';

  @override
  String get gamificationAchPerfectWeekDesc =>
      'Relevez tous les défis quotidiens pendant 7 jours';

  @override
  String get gamificationAchEarlyBirdName => 'Lève-tôt';

  @override
  String get gamificationAchEarlyBirdDesc =>
      'Envoyez des messages avant 9 h pendant 10 jours';

  @override
  String get gamificationAchNightOwlName => 'Oiseau de nuit';

  @override
  String get gamificationAchNightOwlDesc =>
      'Envoyez des messages après 22 h pendant 10 jours';

  @override
  String get gamificationAchCenturionName => 'Centurion';

  @override
  String get gamificationAchCenturionDesc =>
      'Atteignez 100 connexions au total';

  @override
  String get gamificationAchSpeedDaterName => 'Sprinteur social';

  @override
  String get gamificationAchSpeedDaterDesc =>
      'Connectez-vous avec 10 personnes en une journée';

  @override
  String get gamificationAchPhotoCollectorName => 'Collectionneur de photos';

  @override
  String get gamificationAchPhotoCollectorDesc =>
      'Ajoutez 6 photos à votre profil';

  @override
  String get gamificationAchTrendSetterName => 'Pionnier';

  @override
  String get gamificationAchTrendSetterDesc =>
      'Faites partie des 1000 premiers utilisateurs';

  @override
  String get gamificationAchVerifiedName => 'Vérifié';

  @override
  String get gamificationAchVerifiedDesc =>
      'Effectuez la vérification par photo';

  @override
  String get gamificationAchPremiumMemberName => 'Membre Premium';

  @override
  String get gamificationAchPremiumMemberDesc =>
      'Abonnez-vous au niveau Silver ou Gold';

  @override
  String get gamificationAchCoinCollectorName => 'Collectionneur de pièces';

  @override
  String get gamificationAchCoinCollectorDesc => 'Accumulez 1000 pièces';

  @override
  String get gamificationAchMonthlyStreakName => 'Assiduité mensuelle';

  @override
  String get gamificationAchMonthlyStreakDesc =>
      '30 jours de connexion consécutifs';

  @override
  String get gamificationAchVocabularyBeginnerName => 'Explorateur de mots';

  @override
  String get gamificationAchVocabularyBeginnerDesc =>
      'Utilisez 100 mots différents dans le chat';

  @override
  String get gamificationAchVocabularyIntermediateName => 'Orfèvre des mots';

  @override
  String get gamificationAchVocabularyIntermediateDesc =>
      'Utilisez 500 mots différents dans le chat';

  @override
  String get gamificationAchVocabularyAdvancedName => 'Expert du vocabulaire';

  @override
  String get gamificationAchVocabularyAdvancedDesc =>
      'Utilisez 1000 mots différents dans le chat';

  @override
  String get gamificationAchVocabularyMasterName => 'Maître du vocabulaire';

  @override
  String get gamificationAchVocabularyMasterDesc =>
      'Utilisez 5000 mots différents dans le chat';

  @override
  String get gamificationAchRareWordHunterName => 'Chasseur de mots rares';

  @override
  String get gamificationAchRareWordHunterDesc =>
      'Utilisez 50 mots rares (score de fréquence inférieur à 50)';

  @override
  String gamificationRewardCoinsPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count pièces',
      one: '+1 pièce',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardBadgePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count badges',
      one: '+1 badge',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardBoostPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count boosts',
      one: '+1 boost',
    );
    return '$_temp0';
  }

  @override
  String gamificationRewardWithValue(String reward) {
    return 'Récompense : $reward';
  }

  @override
  String get gamificationRewardBadge => 'Badge';

  @override
  String get gamificationVip => 'VIP';

  @override
  String get gamificationRewardsTitle => 'Récompenses';

  @override
  String gamificationXpToNextLevel(String xp) {
    return '$xp XP avant le niveau suivant';
  }

  @override
  String get gamificationStreakDayUnitOne => 'jour';

  @override
  String get gamificationStreakDayUnitOther => 'jours';

  @override
  String get gamificationOnFire => '🎉 En feu !';

  @override
  String gamificationUserFallback(String id) {
    return 'Utilisateur $id';
  }

  @override
  String gamificationNoticeAchievementUnlocked(String name, String reward) {
    return '$name débloqué ! $reward';
  }

  @override
  String gamificationNoticeAchievementReady(String name) {
    return 'Succès accompli ! Prêt à débloquer : $name';
  }

  @override
  String gamificationNoticeLevelUp(int level) {
    return 'Niveau supérieur ! Vous avez atteint le niveau $level !';
  }

  @override
  String get gamificationNoticeVip =>
      'Félicitations ! Vous avez obtenu le statut VIP ! 👑';

  @override
  String gamificationNoticeLevelRewardsClaimed(int level, String rewards) {
    return 'Récompenses du niveau $level récupérées ! $rewards';
  }

  @override
  String gamificationNoticeChallengeRewardsClaimed(
      String name, String rewards) {
    return 'Récompenses de $name récupérées ! $rewards';
  }

  @override
  String gamificationNoticeFeatureLocked(int count, String feature, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$feature se débloque au niveau $level. Plus que $count niveaux !',
      one: '$feature se débloque au niveau $level. Plus qu’1 niveau !',
    );
    return '$_temp0';
  }

  @override
  String get gamificationFeatureCustomChatThemes =>
      'Thèmes de chat personnalisés';

  @override
  String get gamificationFeatureProfileVideo => 'Vidéo de profil';

  @override
  String get gamificationFeatureAdvancedFilters => 'Filtres avancés';

  @override
  String get gamificationFeatureUnlimitedRewinds => 'Retours illimités';

  @override
  String get gamificationFeatureVipBadge => 'Badge VIP';

  @override
  String get gamificationFeaturePriorityLikes => 'Likes prioritaires';

  @override
  String get gamificationLevelRewardBronzeFrame => 'Cadre bronze';

  @override
  String get gamificationLevelRewardSilverFrame => 'Cadre argent';

  @override
  String get gamificationLevelRewardGoldFrame => 'Cadre or';

  @override
  String get gamificationLevelRewardPlatinumFrame => 'Cadre platine';

  @override
  String get gamificationLevelRewardDiamondFrame => 'Cadre diamant';

  @override
  String get gamificationLevelRewardLegendaryFrame => 'Cadre légendaire';

  @override
  String get gamificationLevelRewardVipCrown => 'Couronne VIP';

  @override
  String gamificationLevelRewardMaxLevelBadge(int level) {
    return 'Badge niveau $level';
  }

  @override
  String gamificationLevelRewardBonusCoins(int count) {
    return '$count pièces bonus';
  }

  @override
  String get gamificationMissionAttend3Events => 'Participez à 3 événements';

  @override
  String get gamificationMissionConnect3Countries =>
      'Connectez-vous avec des personnes de 3 pays';

  @override
  String get gamificationMissionJoinCommunity => 'Rejoignez une communauté';

  @override
  String get gamificationMissionCompleteProfile => 'Complétez votre profil';

  @override
  String get gamificationMissionAdd5People => 'Ajoutez 5 personnes';

  @override
  String get updateRequiredTitle => 'Mise à jour requise';

  @override
  String get updateRequiredMessage =>
      'Une nouvelle version de GreenGo est disponible. Veuillez mettre à jour pour continuer à utiliser l\'application.';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String get updateAvailableMessage =>
      'Une nouvelle version de GreenGo est disponible, avec des améliorations et de nouvelles fonctionnalités.';

  @override
  String get updateVersionCurrent => 'Actuelle';

  @override
  String get updateVersionRequired => 'Requise';

  @override
  String get updateVersionAvailable => 'Disponible';

  @override
  String get updateVersionLatest => 'Dernière';

  @override
  String get updateWhatsNew => 'Nouveautés';

  @override
  String get updateNowButton => 'Mettre à jour';

  @override
  String get updateButton => 'Mettre à jour';

  @override
  String get maintenanceTitle => 'Maintenance en cours';

  @override
  String get maintenanceCheckBackSoon => 'Revenez bientôt';

  @override
  String get maintenanceDefaultMessage =>
      'Nous effectuons actuellement une maintenance. Veuillez réessayer plus tard.';

  @override
  String get countdownAlmostThere => 'Presque prêt !';

  @override
  String get countdownVipEarlyAccess => 'Accès anticipé VIP';

  @override
  String countdownLaunchDate(String date) {
    return 'Date de lancement : $date';
  }

  @override
  String get countdownTimeUntilLaunch => 'Temps restant avant le lancement';

  @override
  String get countdownWantEarlierAccess => 'Envie d\'un accès anticipé ?';

  @override
  String countdownUpgradeForEarlierAccess(String date) {
    return 'Passez à une offre supérieure pour accéder à l\'application avant le $date !';
  }

  @override
  String get countdownLaunchDay => 'Jour du lancement !';

  @override
  String get countdownNowAvailable => 'GreenGo Chat est maintenant disponible';

  @override
  String celebrationWelcomeToTier(String tier) {
    return 'Bienvenue dans $tier !';
  }

  @override
  String get celebrationMembershipActive =>
      'Votre abonnement premium est maintenant actif';

  @override
  String get celebrationUnlimitedLikes => 'Likes illimités';

  @override
  String get celebrationSeeWhoLikedYou => 'Voyez qui veut se connecter';

  @override
  String celebrationPerDay(int count) {
    return '$count/jour';
  }

  @override
  String get celebrationExclusiveEvents => 'Événements exclusifs';

  @override
  String purchaseSuccessCoinsAdded(int count) {
    return '$count pièces GreenGo ajoutées !';
  }

  @override
  String get pushChannelMainName => 'Notifications GreenGo';

  @override
  String get pushChannelMainDescription =>
      'Messages, likes, événements et activité';

  @override
  String get pushChannelAnnouncementsName => 'Annonces';

  @override
  String get pushChannelAnnouncementsDescription =>
      'Communications et annonces de GreenGo';

  @override
  String get pushChannelSummaryName => 'Résumé d\'activité';

  @override
  String get pushChannelSummaryDescription =>
      'Notifications d\'activité regroupées';

  @override
  String get pushChannelGeneralName => 'Général';

  @override
  String get pushChannelGeneralDescription => 'Notifications générales';

  @override
  String get usageLimitTypeConnects => 'connexions';

  @override
  String get usageLimitTypePasses => 'passes';

  @override
  String get usageLimitTypePriorityConnects => 'Connexions Prioritaires';

  @override
  String get usageLimitTypeDailyPriorityConnects =>
      'Connexions Prioritaires quotidiennes';

  @override
  String get usageLimitTypeSwipes => 'swipes';

  @override
  String get usageLimitTypeMessages => 'messages';

  @override
  String get usageLimitTypeMediaSends => 'envois de médias';

  @override
  String get usageLimitTypeDirectMatches => 'Direct Connects';

  @override
  String get usageLimitTypeConnections => 'connexions';

  @override
  String usageLimitUnlimited(String type) {
    return '$type illimités';
  }

  @override
  String usageLimitRemainingThisHour(int remaining, String type) {
    return 'Il vous reste $remaining $type cette heure-ci';
  }

  @override
  String usageLimitRemainingToday(int remaining, String type) {
    return 'Il vous reste $remaining $type aujourd\'hui';
  }

  @override
  String usageLimitConnectsHourly(int limit) {
    return 'Vous avez utilisé vos $limit connexions de cette heure. Passez à une offre supérieure ou attendez l\'heure suivante.';
  }

  @override
  String usageLimitPassesHourly(int limit) {
    return 'Vous avez utilisé vos $limit passes de cette heure. Passez à une offre supérieure ou attendez l\'heure suivante.';
  }

  @override
  String usageLimitPriorityUnavailable(String tier) {
    return 'Les Connexions Prioritaires ne sont pas disponibles avec l\'offre $tier. Passez à une offre supérieure pour débloquer cette fonctionnalité !';
  }

  @override
  String usageLimitPriorityHourly(int limit) {
    return 'Vous avez utilisé vos $limit Connexions Prioritaires de cette heure. Passez à une offre supérieure ou attendez l\'heure suivante.';
  }

  @override
  String usageLimitPriorityDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'Vous avez utilisé vos $limit connexions prioritaires gratuites du jour. Utilisez des pièces pour en avoir plus ou attendez demain.',
      one:
          'Vous avez utilisé votre connexion prioritaire gratuite du jour. Utilisez des pièces pour en avoir plus ou attendez demain.',
    );
    return '$_temp0';
  }

  @override
  String usageLimitSwipesDaily(int limit) {
    return 'Vous avez utilisé vos $limit swipes du jour. Passez à une offre supérieure pour en avoir plus ou attendez demain.';
  }

  @override
  String usageLimitMessagesDaily(int limit) {
    return 'Vous avez atteint votre limite quotidienne de $limit messages. Passez à une offre supérieure pour envoyer des messages illimités !';
  }

  @override
  String usageLimitMediaUnavailable(String tier) {
    return 'L\'envoi de médias n\'est pas disponible avec l\'offre $tier. Passez à une offre supérieure pour envoyer des images et des vidéos !';
  }

  @override
  String usageLimitMediaDaily(int limit) {
    return 'Vous avez atteint votre limite quotidienne de $limit envois de médias. Passez à une offre supérieure ou attendez demain.';
  }

  @override
  String usageLimitDirectMatchDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'Vous avez utilisé vos $limit Direct Connects gratuits du jour. Utilisez des pièces pour en avoir plus ou attendez demain.',
      one:
          'Vous avez utilisé votre Direct Connect gratuit du jour. Utilisez des pièces pour en avoir plus ou attendez demain.',
    );
    return '$_temp0';
  }

  @override
  String get contentFilterViolationEmail => 'adresse e-mail';

  @override
  String get contentFilterViolationPhoneWords =>
      'numéro de téléphone (écrit en lettres)';

  @override
  String get contentFilterViolationPhone => 'numéro de téléphone';

  @override
  String get contentFilterViolationSocial => 'réseau social/lien';

  @override
  String adminImportSummary(int success, int duplicates, int errors) {
    return 'Importés : $success | Doublons : $duplicates | Erreurs : $errors';
  }

  @override
  String get tierBoostCadenceNone => 'Aucun';

  @override
  String get tierBoostCadenceMonthly => '1 par mois';

  @override
  String get tierBoostCadenceWeekly => '~1 par semaine';

  @override
  String get tierBoostCadenceDaily => '~1 par jour';

  @override
  String get tierFilterLevelBasic => 'Basiques';

  @override
  String get tierFilterLevelStandard => 'Standard';

  @override
  String get tierFilterLevelAdvanced => 'Avancés';

  @override
  String get tierFilterLevelAll => 'Tous les filtres';

  @override
  String tierTtsCostValue(int coins) {
    return '$coins pièces par traduction';
  }

  @override
  String chatLearningLiteral(String text) {
    return 'Littéral : $text';
  }

  @override
  String chatLearningMeaning(String text) {
    return 'Signification : $text';
  }

  @override
  String get validatorNameRequired => 'Le nom est obligatoire';

  @override
  String get validatorNameLettersOnly =>
      'Le nom ne peut contenir que des lettres et des espaces';

  @override
  String get validatorPhoneRequired => 'Le numéro de téléphone est obligatoire';

  @override
  String get validatorPhoneMinDigits =>
      'Le numéro de téléphone doit comporter au moins 10 chiffres';

  @override
  String get validatorAgeRequired => 'L\'âge est obligatoire';

  @override
  String validatorMinAge(int minAge) {
    return 'Vous devez avoir au moins $minAge ans';
  }

  @override
  String get validatorInvalidAge => 'Âge non valide';

  @override
  String validatorBioMaxLength(int max) {
    return 'La bio doit faire moins de $max caractères';
  }

  @override
  String get profileOnboardingIncompleteStep =>
      'Veuillez remplir tous les champs obligatoires';

  @override
  String get profileGenderPreferNotToSay => 'Je préfère ne pas le dire';

  @override
  String get profileOrientationStraight => 'Hétérosexuel(le)';

  @override
  String get profileOrientationGay => 'Gay';

  @override
  String get profileOrientationBisexual => 'Bisexuel(le)';

  @override
  String get profileLanguageHebrew => 'Hébreu';

  @override
  String get profileLanguageThai => 'Thaï';

  @override
  String get profileLanguageVietnamese => 'Vietnamien';

  @override
  String profileLatLon(String lat, String lon) {
    return 'Lat : $lat, Long : $lon';
  }

  @override
  String get profileNicknameInvalid => 'Pseudo invalide';

  @override
  String get profileNicknameErrorEmpty => 'Le pseudo ne peut pas être vide';

  @override
  String profileNicknameErrorTooShort(int min) {
    return 'Le pseudo doit contenir au moins $min caractères';
  }

  @override
  String profileNicknameErrorTooLong(int max) {
    return 'Le pseudo doit contenir $max caractères maximum';
  }

  @override
  String get profileNicknameErrorStartLetter =>
      'Le pseudo doit commencer par une lettre';

  @override
  String get profileNicknameErrorChars =>
      'Le pseudo ne peut contenir que des lettres, des chiffres et des tirets bas';

  @override
  String get profileNicknameErrorUnderscores =>
      'Le pseudo ne peut pas contenir de tirets bas consécutifs';

  @override
  String get profileNicknameErrorReserved =>
      'Le pseudo ne peut pas contenir de mots réservés';

  @override
  String get profileFreeUnlimited => 'Gratuit - Illimité';

  @override
  String get profileFreeWithPlatinum => 'Gratuit avec Platinum';

  @override
  String profileCoinsPerDay(int count) {
    return '$count pièces/jour';
  }

  @override
  String profileTravelerActiveSubtitle(
      String location, int hours, int minutes) {
    return '$location - $hours h $minutes min restantes';
  }

  @override
  String profileTravelerInactiveSubtitle(String cost) {
    return '$cost - Apparaissez dans une autre ville';
  }

  @override
  String profileMinutesRemaining(int minutes) {
    return '$minutes min restantes';
  }

  @override
  String profileHoursMinutesRemaining(int hours, int minutes) {
    return '$hours h $minutes min restantes';
  }

  @override
  String get profileGhostMode => 'Mode fantôme';

  @override
  String get profileGhostModeActiveSubtitle =>
      'Mode fantôme - Illimité - Masqué de la découverte et de la recherche';

  @override
  String get profileGhostModeInactiveSubtitle =>
      'Gratuit - Illimité - Masqué de la découverte et de la recherche par pseudo';

  @override
  String profileIncognitoCostSubtitle(int count) {
    return '$count pièces/24 h - Masqué de la découverte';
  }

  @override
  String get photoDeleteTitle => 'Supprimer la photo';

  @override
  String travelerCouldNotResolveAddress(String coordinates) {
    return '$coordinates — impossible de trouver l\'adresse';
  }

  @override
  String get membershipTierNameBasicFree => 'Basique (Gratuit)';

  @override
  String get membershipTierNameSilverPremium => 'Argent Premium';

  @override
  String get membershipTierNameGoldPremium => 'Or Premium';

  @override
  String get membershipTierNamePlatinumVip => 'Platine VIP';

  @override
  String get membershipTierNameSilverVip => 'Argent VIP';

  @override
  String get membershipTierNameGoldVip => 'Or VIP';

  @override
  String get membershipTierNameTester => 'Testeur';

  @override
  String membershipBuyProductPrice(String product, String price) {
    return 'Acheter $product – $price';
  }

  @override
  String get coinSpendCategoryMatching => 'Connexions';

  @override
  String get coinSpendCategoryMessaging => 'Messagerie';

  @override
  String get coinSpendCategoryGifts => 'Cadeaux virtuels';

  @override
  String get coinSpendSeeWhoLiked => 'Qui vous a liké';

  @override
  String get coinSpendReadReceiptsDay => 'Accusés de lecture (1 jour)';

  @override
  String get coinSpendRose => 'Rose';

  @override
  String get coinSpendTeddyBear => 'Ours en peluche';

  @override
  String get coinSpendDiamond => 'Diamant';

  @override
  String get coinSpendSuperLikeDesc =>
      'Envoyez un Priority Connect pour vous démarquer';

  @override
  String get coinSpendBoostDesc =>
      'Soyez vu par plus de personnes pendant 30 min';

  @override
  String get coinSpendUndoDesc => 'Annulez votre dernier swipe';

  @override
  String get coinSpendSeeWhoLikedDesc => 'Voyez qui a aimé votre profil';

  @override
  String get coinSpendReadReceiptsDesc => 'Voyez quand les messages sont lus';

  @override
  String get coinSpendRoseDesc => 'Envoyez une rose virtuelle';

  @override
  String get coinSpendTeddyBearDesc => 'Envoyez un adorable ours en peluche';

  @override
  String get coinSpendDiamondDesc => 'Envoyez un diamant étincelant';

  @override
  String get coinReasonFirstMatchReward => 'Récompense de première connexion';

  @override
  String get coinReasonCompleteProfileReward => 'Récompense profil complet';

  @override
  String get coinReasonDailyLoginStreak => 'Série de connexions quotidiennes';

  @override
  String get coinReasonAchievementUnlocked => 'Succès débloqué';

  @override
  String get coinReasonMonthlyAllowance => 'Allocation mensuelle';

  @override
  String get coinReasonGiftReceived => 'Cadeau reçu';

  @override
  String get coinReasonGiftSent => 'Cadeau envoyé';

  @override
  String get coinReasonPromotionalBonus => 'Bonus promotionnel';

  @override
  String get coinReasonReferralBonus => 'Bonus de parrainage';

  @override
  String get coinReasonCoinPurchase => 'Achat de pièces';

  @override
  String get coinReasonRefund => 'Remboursement';

  @override
  String get coinReasonUndoLastSwipe => 'Annuler le dernier swipe';

  @override
  String get coinReasonSeeWhoLikedYou => 'Voir qui veut se connecter';

  @override
  String get coinReasonDirectMessage => 'Message direct';

  @override
  String get coinReasonFeaturePurchase => 'Achat de fonctionnalité';

  @override
  String get coinReasonCoinsExpired => 'Pièces expirées';

  @override
  String get coinReasonAdminAdjustment => 'Ajustement administrateur';

  @override
  String coinTxDescFirstMatch(int amount) {
    return 'Félicitations pour votre première connexion ! $amount pièces gagnées.';
  }

  @override
  String coinTxDescCompleteProfile(int amount) {
    return 'Profil complété ! $amount pièces gagnées.';
  }

  @override
  String coinTxDescDailyStreak(String streak, int amount) {
    return 'Série de connexion jour $streak ! $amount pièces gagnées.';
  }

  @override
  String coinTxDescAchievement(String achievement, int amount) {
    return 'Succès débloqué : $achievement ! $amount pièces gagnées.';
  }

  @override
  String coinTxDescAchievementGeneric(int amount) {
    return 'Succès débloqué ! $amount pièces gagnées.';
  }

  @override
  String coinTxDescMonthlyAllowance(String tier, int amount) {
    return 'Allocation mensuelle $tier : $amount pièces.';
  }

  @override
  String coinTxDescGiftReceived(int amount, String user) {
    return '$amount pièces reçues de $user.';
  }

  @override
  String coinTxDescGiftSent(int amount, String user) {
    return '$amount pièces envoyées à $user.';
  }

  @override
  String coinTxDescPromotional(String campaign, int amount) {
    return 'Bonus promotionnel $campaign : $amount pièces.';
  }

  @override
  String coinTxDescPromotionalGeneric(int amount) {
    return 'Bonus promotionnel : $amount pièces.';
  }

  @override
  String coinTxDescReferral(int amount) {
    return 'Bonus de parrainage : $amount pièces gagnées.';
  }

  @override
  String coinTxDescPurchase(int amount) {
    return '$amount pièces achetées.';
  }

  @override
  String coinTxDescPurchasePackage(int amount, String package) {
    return '$amount pièces achetées ($package).';
  }

  @override
  String coinTxDescRefund(int amount) {
    return 'Remboursement : $amount pièces.';
  }

  @override
  String coinTxDescUsedFor(int amount, String feature) {
    return '$amount pièces utilisées pour $feature.';
  }

  @override
  String coinTxDescExpired(int amount) {
    return '$amount pièces ont expiré.';
  }

  @override
  String coinTxDescClawback(int amount) {
    return '$amount pièces retirées : l’achat a été remboursé.';
  }

  @override
  String coinTxDescAdmin(int amount, String reason) {
    return 'Ajustement administrateur : $amount pièces ($reason).';
  }

  @override
  String coinTxDescAdminGeneric(int amount) {
    return 'Ajustement administrateur : $amount pièces.';
  }

  @override
  String coinPromoPercentBonus(int percent) {
    return '+$percent % de pièces bonus';
  }

  @override
  String get businessFollowerFallbackName => 'Membre GreenGo';

  @override
  String get bizCatRestaurant => 'Restaurant';

  @override
  String get bizCatBar => 'Bar';

  @override
  String get bizCatCafe => 'Café';

  @override
  String get bizCatNightclub => 'Boîte de nuit';

  @override
  String get bizCatLounge => 'Lounge';

  @override
  String get bizCatHotel => 'Hôtel';

  @override
  String get bizCatHostel => 'Auberge de jeunesse';

  @override
  String get bizCatGuesthouse => 'Maison d\'hôtes';

  @override
  String get bizCatResort => 'Complexe hôtelier';

  @override
  String get bizCatBedAndBreakfast => 'Chambre d\'hôtes';

  @override
  String get bizCatGym => 'Salle de sport';

  @override
  String get bizCatYogaStudio => 'Studio de yoga';

  @override
  String get bizCatFitnessStudio => 'Studio de fitness';

  @override
  String get bizCatSpa => 'Spa';

  @override
  String get bizCatWellnessCenter => 'Centre de bien-être';

  @override
  String get bizCatBeautySalon => 'Salon de beauté';

  @override
  String get bizCatBarbershop => 'Barbier';

  @override
  String get bizCatMuseum => 'Musée';

  @override
  String get bizCatArtGallery => 'Galerie d\'art';

  @override
  String get bizCatTheater => 'Théâtre';

  @override
  String get bizCatCinema => 'Cinéma';

  @override
  String get bizCatLiveMusicVenue => 'Salle de concert';

  @override
  String get bizCatCulturalCenter => 'Centre culturel';

  @override
  String get bizCatTourOperator => 'Voyagiste';

  @override
  String get bizCatTravelAgency => 'Agence de voyages';

  @override
  String get bizCatLanguageSchool => 'École de langues';

  @override
  String get bizCatCookingSchool => 'École de cuisine';

  @override
  String get bizCatDanceStudio => 'École de danse';

  @override
  String get bizCatCoworkingSpace => 'Espace de coworking';

  @override
  String get bizCatEventVenue => 'Lieu d\'événements';

  @override
  String get bizCatConferenceCenter => 'Centre de conférences';

  @override
  String get bizCatShopRetail => 'Boutique / Commerce';

  @override
  String get bizCatBoutique => 'Boutique';

  @override
  String get bizCatBookstore => 'Librairie';

  @override
  String get bizCatMarket => 'Marché';

  @override
  String get bizCatWinery => 'Domaine viticole';

  @override
  String get bizCatBrewery => 'Brasserie';

  @override
  String get bizCatDistillery => 'Distillerie';

  @override
  String get bizCatFoodTruck => 'Food truck';

  @override
  String get bizCatBakery => 'Boulangerie';

  @override
  String get bizCatCoffeeRoastery => 'Torréfaction de café';

  @override
  String get bizCatSportsClub => 'Club de sport';

  @override
  String get bizCatAdventureAndOutdoor => 'Aventure et plein air';

  @override
  String get bizCatDivingCenter => 'Centre de plongée';

  @override
  String get bizCatPhotographyStudio => 'Studio photo';

  @override
  String get bizCatCoachingAndConsulting => 'Coaching et conseil';

  @override
  String get bizCatNonprofitAndNGO => 'Association et ONG';

  @override
  String get bizCatCommunityCenter => 'Centre communautaire';

  @override
  String get bizCatTransportationService => 'Service de transport';

  @override
  String get bizCatOther => 'Autre';

  @override
  String get bizCatGroupFoodAndDrink => 'Restauration';

  @override
  String get bizCatGroupNightlife => 'Vie nocturne';

  @override
  String get bizCatGroupStay => 'Hébergement';

  @override
  String get bizCatGroupWellness => 'Bien-être';

  @override
  String get bizCatGroupCulture => 'Culture';

  @override
  String get bizCatGroupTravelAndTours => 'Voyages et circuits';

  @override
  String get bizCatGroupLearnAndWork => 'Apprendre et travailler';

  @override
  String get bizCatGroupEvents => 'Événements';

  @override
  String get bizCatGroupRetail => 'Commerce';

  @override
  String get bizCatGroupCommunityAndServices => 'Communauté et services';

  @override
  String get gamificationJourneyTitle => 'Votre parcours';

  @override
  String gamificationJourneyMilestonesCompleted(int completed, int total) {
    return '$completed paliers sur $total atteints';
  }

  @override
  String get gamificationJourneyOverallProgress => 'Progression globale';

  @override
  String get gamificationJourneyNoMilestones => 'Pas encore de paliers';

  @override
  String get gamificationJourneyCompletePrevious =>
      'Terminez les catégories précédentes pour débloquer';

  @override
  String get gamificationJourneyTabStart => 'Début';

  @override
  String get gamificationJourneyTabMaster => 'Maître';

  @override
  String get gamificationJourneyCatGettingStarted => 'Premiers pas';

  @override
  String get gamificationJourneyCatSocializing => 'Socialiser';

  @override
  String get gamificationJourneyCatMastery => 'Maîtrise';

  @override
  String get gamificationJourneyCatGettingStartedDesc =>
      'Complétez votre profil et découvrez l’app';

  @override
  String get gamificationJourneyCatSocializingDesc =>
      'Connectez-vous avec d’autres et tissez des liens';

  @override
  String get gamificationJourneyCatPremiumDesc =>
      'Débloquez des fonctionnalités et récompenses premium';

  @override
  String get gamificationJourneyCatMasteryDesc =>
      'Devenez un maître des connexions';

  @override
  String get gamificationJourneyCatSpecialDesc => 'Paliers et succès exclusifs';

  @override
  String get gamificationJourneyCompleteProfileName => 'Pro du profil';

  @override
  String get gamificationJourneyCompleteProfileDesc =>
      'Complétez votre profil à 100 %';

  @override
  String get gamificationJourneyAddPhotosName => 'Photo parfaite';

  @override
  String get gamificationJourneyAddPhotosDesc =>
      'Ajoutez 5 photos à votre profil';

  @override
  String get gamificationJourneyGetVerifiedName => 'Utilisateur vérifié';

  @override
  String get gamificationJourneyGetVerifiedDesc =>
      'Effectuez la vérification par photo';

  @override
  String get gamificationJourneyFirstMatchName => 'Première connexion';

  @override
  String get gamificationJourneyFirstMatchDesc =>
      'Créez votre première connexion';

  @override
  String get gamificationJourneyTenMatchesName => 'Étoile montante';

  @override
  String get gamificationJourneyTenMatchesDesc => 'Créez 10 connexions';

  @override
  String get gamificationJourneyFiftyMatchesName => 'Papillon social';

  @override
  String get gamificationJourneyFiftyMatchesDesc => 'Créez 50 connexions';

  @override
  String get gamificationJourneyFirstMessageName => 'Brise-glace';

  @override
  String get gamificationJourneyFirstMessageDesc =>
      'Envoyez votre premier message';

  @override
  String get gamificationJourneyHundredMessagesName => 'Roi de la conversation';

  @override
  String get gamificationJourneyHundredMessagesDesc => 'Envoyez 100 messages';

  @override
  String get gamificationJourneyFirstVideoCallName => 'Face à face';

  @override
  String get gamificationJourneyFirstVideoCallDesc =>
      'Effectuez votre premier appel vidéo';

  @override
  String get gamificationJourneyTenVideoCallsName => 'Pro de la vidéo';

  @override
  String get gamificationJourneyTenVideoCallsDesc =>
      'Effectuez 10 appels vidéo';

  @override
  String get gamificationJourneyWeekStreakName => 'Utilisateur assidu';

  @override
  String get gamificationJourneyWeekStreakDesc =>
      'Maintenez une série de 7 jours de connexion';

  @override
  String get gamificationJourneyMonthStreakName => 'Super assidu';

  @override
  String get gamificationJourneyMonthStreakDesc =>
      'Maintenez une série de 30 jours de connexion';

  @override
  String get gamificationJourneyUpgradeSilverName => 'Membre Silver';

  @override
  String get gamificationJourneyUpgradeSilverDesc => 'Passez au VIP Silver';

  @override
  String get gamificationJourneyUpgradeGoldName => 'Membre Gold';

  @override
  String get gamificationJourneyUpgradeGoldDesc => 'Passez au VIP Gold';

  @override
  String get gamificationJourneyUpgradePlatinumName => 'Membre Platinum';

  @override
  String get gamificationJourneyUpgradePlatinumDesc => 'Passez au VIP Platinum';

  @override
  String get gamificationJourneyTenAchievementsName => 'Chasseur de succès';

  @override
  String get gamificationJourneyTenAchievementsDesc => 'Obtenez 10 succès';

  @override
  String get gamificationJourneyFiftyAchievementsName => 'Maître des succès';

  @override
  String get gamificationJourneyFiftyAchievementsDesc => 'Obtenez 50 succès';

  @override
  String get gamificationJourneyHundredMatchesName => 'Centurion';

  @override
  String get gamificationJourneyHundredMatchesDesc => 'Créez 100 connexions';

  @override
  String get gamificationStreakMilestone3Name => 'Bon début';

  @override
  String get gamificationStreakMilestone7Name => 'Guerrier de la semaine';

  @override
  String get gamificationStreakMilestone14Name => 'Champion de deux semaines';

  @override
  String get gamificationStreakMilestone30Name => 'Maître du mois';

  @override
  String get gamificationStreakMilestone60Name => 'Champion de deux mois';

  @override
  String get gamificationStreakMilestone90Name => 'Légende du trimestre';

  @override
  String get gamificationStreakMilestone180Name => 'Héros du semestre';

  @override
  String get gamificationStreakMilestone365Name => 'Année de découvertes';

  @override
  String gamificationStreakMilestoneDesc(int days) {
    return 'Connectez-vous $days jours d’affilée';
  }

  @override
  String get gamificationChallengeSend3MessagesName => 'Discussion rapide';

  @override
  String get gamificationChallengeSend3MessagesDesc => 'Envoyez 3 messages';

  @override
  String get gamificationChallengeSend5MessagesName => 'Maître des messages';

  @override
  String get gamificationChallengeSend5MessagesDesc =>
      'Envoyez 5 messages à vos connexions';

  @override
  String get gamificationChallengeSend10MessagesName =>
      'Roi de la conversation';

  @override
  String get gamificationChallengeSend10MessagesDesc =>
      'Envoyez 10 messages aujourd’hui';

  @override
  String get gamificationChallengeSend15MessagesName =>
      'Marathon de discussion';

  @override
  String get gamificationChallengeSend15MessagesDesc =>
      'Envoyez 15 messages aujourd’hui';

  @override
  String get gamificationChallengeGet1MatchName => 'Nouvelle connexion';

  @override
  String get gamificationChallengeGet1MatchDesc =>
      'Créez 1 nouvelle connexion aujourd\'hui';

  @override
  String get gamificationChallengeGet3MatchesName => 'Connecteur';

  @override
  String get gamificationChallengeGet3MatchesDesc =>
      'Créez 3 nouvelles connexions aujourd\'hui';

  @override
  String get gamificationChallengeGet5MatchesName => 'Aimant social';

  @override
  String get gamificationChallengeGet5MatchesDesc =>
      'Créez 5 nouvelles connexions aujourd\'hui';

  @override
  String get gamificationChallengeSend1SuperlikeName => 'Choix prioritaire';

  @override
  String get gamificationChallengeSend1SuperlikeDesc =>
      'Envoyez 1 Priority Connect';

  @override
  String get gamificationChallengeSend3SuperlikesName =>
      'Connecteur prioritaire';

  @override
  String get gamificationChallengeSend3SuperlikesDesc =>
      'Envoyez 3 Priority Connects';

  @override
  String get gamificationChallengeSend5SuperlikesName => 'Superstar';

  @override
  String get gamificationChallengeSend5SuperlikesDesc =>
      'Envoyez 5 Priority Connects';

  @override
  String get gamificationChallengeVideoCall1Name => 'Fan de vidéo';

  @override
  String get gamificationChallengeVideoCall1Desc => 'Effectuez 1 appel vidéo';

  @override
  String get gamificationChallengeVideoCall2Name => 'Pro de la vidéo';

  @override
  String get gamificationChallengeVideoCall2Desc => 'Effectuez 2 appels vidéo';

  @override
  String get gamificationChallengeAddPhotoName => 'Photo rafraîchie';

  @override
  String get gamificationChallengeAddPhotoDesc =>
      'Ajoutez ou mettez à jour une photo de profil';

  @override
  String get gamificationChallengeAdd2PhotosName => 'Galerie photo';

  @override
  String get gamificationChallengeAdd2PhotosDesc =>
      'Ajoutez 2 nouvelles photos de profil';

  @override
  String get gamificationChallengeSend1GiftName => 'Donateur';

  @override
  String get gamificationChallengeSend1GiftDesc =>
      'Envoyez 1 cadeau à une connexion';

  @override
  String get gamificationChallengeSend3GiftsName => 'Âme généreuse';

  @override
  String get gamificationChallengeSend3GiftsDesc =>
      'Envoyez 3 cadeaux aujourd’hui';

  @override
  String get gamificationChallengeSend5GiftsName => 'Maître des cadeaux';

  @override
  String get gamificationChallengeSend5GiftsDesc =>
      'Envoyez 5 cadeaux aujourd’hui';

  @override
  String get gamificationChallengeChatStarterName => 'Brise-glace';

  @override
  String get gamificationChallengeChatStarterDesc =>
      'Envoyez 7 messages à des connexions différentes';

  @override
  String get gamificationChallengeSocialButterflyName => 'Papillon social';

  @override
  String get gamificationChallengeSocialButterflyDesc =>
      'Envoyez 20 messages aujourd’hui';

  @override
  String get gamificationChallengeMatchRushName => 'Rafale de connexions';

  @override
  String get gamificationChallengeMatchRushDesc =>
      'Créez 7 connexions aujourd\'hui';

  @override
  String get gamificationChallengeVideoMarathonName => 'Marathon vidéo';

  @override
  String get gamificationChallengeVideoMarathonDesc =>
      'Effectuez 3 appels vidéo';

  @override
  String get gamificationChallengeWeeklyMessages30Name => 'Fan de discussion';

  @override
  String get gamificationChallengeWeeklyMessages30Desc =>
      'Envoyez 30 messages cette semaine';

  @override
  String get gamificationChallengeWeeklyMessages50Name =>
      'Maître de la discussion';

  @override
  String get gamificationChallengeWeeklyMessages50Desc =>
      'Envoyez 50 messages cette semaine';

  @override
  String get gamificationChallengeWeeklyMessages100Name =>
      'Légende de la discussion';

  @override
  String get gamificationChallengeWeeklyMessages100Desc =>
      'Envoyez 100 messages cette semaine';

  @override
  String get gamificationChallengeWeeklyMatches10Name =>
      'Connecteur de la semaine';

  @override
  String get gamificationChallengeWeeklyMatches10Desc =>
      'Créez 10 connexions cette semaine';

  @override
  String get gamificationChallengeWeeklyMatches20Name =>
      'Champion des connexions de la semaine';

  @override
  String get gamificationChallengeWeeklyMatches20Desc =>
      'Créez 20 connexions cette semaine';

  @override
  String get gamificationChallengeWeeklyMatches30Name => 'Machine à connexions';

  @override
  String get gamificationChallengeWeeklyMatches30Desc =>
      'Créez 30 connexions cette semaine';

  @override
  String get gamificationChallengeWeeklySuperlikes5Name =>
      'Connecteur prioritaire de la semaine';

  @override
  String get gamificationChallengeWeeklySuperlikes5Desc =>
      'Envoyez 5 Priority Connects cette semaine';

  @override
  String get gamificationChallengeWeeklySuperlikes10Name => 'Super fan';

  @override
  String get gamificationChallengeWeeklySuperlikes10Desc =>
      'Envoyez 10 Priority Connects cette semaine';

  @override
  String get gamificationChallengeWeeklySuperlikes15Name =>
      'Roi de la priorité';

  @override
  String get gamificationChallengeWeeklySuperlikes15Desc =>
      'Envoyez 15 Priority Connects cette semaine';

  @override
  String get gamificationChallengeWeeklyVideo3Name => 'Mondain de la vidéo';

  @override
  String get gamificationChallengeWeeklyVideo3Desc =>
      'Effectuez 3 appels vidéo cette semaine';

  @override
  String get gamificationChallengeWeeklyVideo5Name => 'Star de la vidéo';

  @override
  String get gamificationChallengeWeeklyVideo5Desc =>
      'Effectuez 5 appels vidéo cette semaine';

  @override
  String get gamificationChallengeWeeklyGifts5Name => 'Donateur de la semaine';

  @override
  String get gamificationChallengeWeeklyGifts5Desc =>
      'Envoyez 5 cadeaux cette semaine';

  @override
  String get gamificationChallengeWeeklyGifts10Name => 'Âme généreuse';

  @override
  String get gamificationChallengeWeeklyGifts10Desc =>
      'Envoyez 10 cadeaux cette semaine';

  @override
  String get gamificationChallengeWeeklyPhotos3Name => 'Semaine photo';

  @override
  String get gamificationChallengeWeeklyPhotos3Desc =>
      'Ajoutez 3 photos cette semaine';

  @override
  String get gamificationChallengeWeeklyPerfectName => 'Semaine parfaite';

  @override
  String get gamificationChallengeWeeklyPerfectDesc =>
      'Relevez tous les défis quotidiens 7 jours d’affilée';

  @override
  String get gamificationChallengeValentineMatchesName =>
      'Connexions d\'amitié';

  @override
  String get gamificationChallengeValentineMatchesDesc =>
      'Créez 14 connexions pendant la Semaine de l\'amitié (1 par jour)';

  @override
  String get gamificationChallengeValentineVideoName =>
      'Soirée culturelle virtuelle';

  @override
  String get gamificationChallengeValentineVideoDesc =>
      'Effectuez 3 appels vidéo';

  @override
  String get gamificationChallengeSummerMatchesName => 'Ambiance plage';

  @override
  String get gamificationChallengeSummerMatchesDesc =>
      'Créez 30 connexions cet été';

  @override
  String get gamificationChallengeHolidayGiftsName => 'Donateur';

  @override
  String get gamificationChallengeHolidayGiftsDesc =>
      'Envoyez 10 cadeaux en pièces à vos connexions';

  @override
  String get gamificationChallengeHolidayMessagesName => 'Esprit des fêtes';

  @override
  String get gamificationChallengeHolidayMessagesDesc => 'Envoyez 100 messages';

  @override
  String get gamificationEventValentinesName => 'Semaine de l\'amitié';

  @override
  String get gamificationEventValentinesDesc =>
      'Célébrez l\'amitié entre les cultures cette semaine !';

  @override
  String get gamificationEventSummerName => 'Été des découvertes';

  @override
  String get gamificationEventSummerDesc =>
      'Faites-vous de nouveaux amis du monde entier cet été !';

  @override
  String get gamificationEventHolidayName => 'Période des fêtes';

  @override
  String get gamificationEventHolidayDesc =>
      'Connectez-vous avec des gens du monde entier pendant les fêtes !';

  @override
  String get travelExploreTitle => 'Explorer les voyages';

  @override
  String get travelExploreInMyCity => 'Dans ma ville';

  @override
  String get travelExploreWorldwide => 'Monde entier';

  @override
  String travelExploreTravelersIn(String city) {
    return 'Voyageurs à $city';
  }

  @override
  String get travelExploreUnknownLocation => 'Lieu inconnu';

  @override
  String get travelExploreLocalGuides => 'Guides locaux';

  @override
  String get travelExploreCities => 'Villes';

  @override
  String travelExploreGuideIn(String city) {
    return 'Guide à $city';
  }

  @override
  String travelExploreNoTravelersInCity(String city) {
    return 'Aucun voyageur à $city pour le moment';
  }

  @override
  String get travelExploreNoTravelers => 'Aucun voyageur trouvé';

  @override
  String get travelExploreTryWorldwide =>
      'Passez à « Monde entier » pour voir tous les voyageurs';

  @override
  String get travelExploreCheckBack =>
      'Revenez plus tard pour voir des voyageurs actifs';

  @override
  String get travelExploreShowWorldwide => 'Afficher le monde entier';

  @override
  String get discoveryDealBreakerSmoking => 'Tabac';

  @override
  String get discoveryDealBreakerDrinking => 'Alcool';

  @override
  String get discoveryDealBreakerNoBio => 'Pas de bio';

  @override
  String get discoveryDealBreakerNoPhotos => 'Pas de photos';

  @override
  String get discoveryDealBreakerDifferentReligion => 'Religion différente';

  @override
  String get discoveryDealBreakerDifferentPolitics =>
      'Opinions politiques différentes';

  @override
  String get discoveryDealBreakerHasChildren => 'A des enfants';

  @override
  String get discoveryDealBreakerWantsChildren => 'Veut des enfants';

  @override
  String get discoveryDealBreakerLongDistance => 'Longue distance';

  @override
  String get discoveryDealBreakerNonMonogamy => 'Non-monogamie';

  @override
  String discoveryPrefCountryUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utilisateurs',
      one: '1 utilisateur',
    );
    return '$_temp0';
  }

  @override
  String get discoveryGridAuto => 'Auto';

  @override
  String get discoveryMatchFallbackName => 'Connexion';

  @override
  String get discoveryThisUser => 'cet utilisateur';

  @override
  String get discoveryActionNope => 'Non';

  @override
  String get exploreTierTester => 'Testeur';

  @override
  String get chatCulturalContextTitle => 'Contexte culturel';

  @override
  String get chatCulturalContextLink => 'Contexte culturel';

  @override
  String get chatWordBreakdownTierRequired =>
      'La décomposition des mots est réservée aux membres Silver, Gold et Platinum';

  @override
  String get chatPreviewSticker => 'Sticker';

  @override
  String get chatPreviewVoiceMessage => 'Message vocal';

  @override
  String get chatPreviewAlbumShared => 'Album partagé';

  @override
  String get chatPreviewAlbumRevoked => 'Accès à l\'album révoqué';

  @override
  String get chatPreviewEvent => 'Événement';

  @override
  String get chatPreviewSayHi => 'Dites bonjour à votre nouvelle connexion !';

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
    return '$count j';
  }

  @override
  String get chatNotificationsMutedForChat =>
      'Notifications désactivées pour cette conversation';

  @override
  String get chatNotificationsUnmuted => 'Notifications réactivées';

  @override
  String get chatMuteNotifications => 'Désactiver les notifications';

  @override
  String get chatUnmuteNotifications => 'Réactiver les notifications';

  @override
  String chatAlbumSelectCount(int count) {
    return 'Sélectionner ($count)';
  }

  @override
  String chatAlbumPhotosSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos sélectionnées',
      one: '1 photo sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String chatSessionXp(int xp) {
    return '$xp XP';
  }

  @override
  String get chatPhraseHowAreYou => 'Comment allez-vous ?';

  @override
  String get chatPhraseGoodMorning => 'Bonjour !';

  @override
  String get chatPhraseAllGood => 'Tout va bien ?';

  @override
  String get chatPhrasePleasedToMeetYou => 'Enchanté !';

  @override
  String get chatPhraseNiceToMeetYou => 'Ravi de vous rencontrer !';

  @override
  String get chatPhraseWhatsUp => 'Quoi de neuf ?';

  @override
  String get chatSupportAiBadge => 'IA';

  @override
  String get chatGroupFallbackName => 'Groupe';

  @override
  String get communitiesTypeLanguageCircle => 'Cercle linguistique';

  @override
  String get communitiesTypeCulturalInterest => 'Intérêt culturel';

  @override
  String get communitiesTypeTravelGroup => 'Groupe de voyage';

  @override
  String get communitiesTypeLocalGuides => 'Guides locaux';

  @override
  String get communitiesTypeStudyGroup => 'Groupe d\'étude';

  @override
  String get communitiesTypeGeneral => 'Général';

  @override
  String get communitiesRoleOwner => 'Propriétaire';

  @override
  String get communitiesRoleAdmin => 'Admin';

  @override
  String get communitiesRoleMember => 'Membre';

  @override
  String get communitiesNoActivityYet => 'Aucune activité pour l\'instant';

  @override
  String get communitiesLanguageMandarin => 'Mandarin';

  @override
  String get communitiesLanguageThai => 'Thaï';

  @override
  String get communitiesLanguageVietnamese => 'Vietnamien';

  @override
  String get communitiesLanguageCatalan => 'Catalan';

  @override
  String get communitiesLanguageHebrew => 'Hébreu';

  @override
  String get videoPromptSelectorTitle => 'Choisissez un thème';

  @override
  String get videoPromptSelectorSubtitle =>
      'Choisissez un thème pour votre vidéo de présentation';

  @override
  String get videoPromptIntroduceTitle => 'Présentez-vous';

  @override
  String get videoPromptIntroduceDesc =>
      'Dites bonjour et racontez-nous qui vous êtes';

  @override
  String get videoPromptIntroduceTemplate =>
      'Présentez-vous dans votre langue préférée';

  @override
  String get videoPromptNativeTitle => 'Langue maternelle';

  @override
  String get videoPromptNativeDesc =>
      'Mettez en valeur votre langue maternelle';

  @override
  String get videoPromptNativeTemplate =>
      'Dites quelque chose dans votre langue maternelle';

  @override
  String get videoPromptTeachTitle => 'Apprenez-nous une phrase';

  @override
  String get videoPromptTeachDesc => 'Partagez une expression amusante';

  @override
  String get videoPromptTeachTemplate =>
      'Apprenez-nous une phrase dans votre langue';

  @override
  String get videoPromptPlaceTitle => 'Lieu préféré';

  @override
  String get videoPromptPlaceDesc => 'Partagez un lieu qui compte pour vous';

  @override
  String get videoPromptPlaceTemplate =>
      'Quel est votre lieu préféré à visiter ?';

  @override
  String get videoPromptCultureTitle => 'Échange culturel';

  @override
  String get videoPromptCultureDesc =>
      'Que signifie l\'échange culturel pour vous ?';

  @override
  String get videoPromptCultureTemplate =>
      'Décrivez votre échange culturel idéal';

  @override
  String get videoPromptTalentTitle => 'Talent caché';

  @override
  String get videoPromptTalentDesc =>
      'Surprenez-nous avec quelque chose d\'inattendu';

  @override
  String get videoPromptTalentTemplate =>
      'Montrez-nous un talent caché ou une anecdote amusante sur vous';

  @override
  String get videoPromptTripTitle => 'Voyage de rêve';

  @override
  String get videoPromptTripDesc => 'Où iriez-vous dans le monde ?';

  @override
  String get videoPromptTripTemplate => 'Décrivez votre destination de rêve';

  @override
  String get videoPromptFreeTitle => 'Style libre';

  @override
  String get videoPromptFreeDesc => 'Dites ce que vous voulez !';

  @override
  String get videoPromptFreeTemplate => 'Style libre, sans thème';

  @override
  String get videoDiscoveryLiked => 'Aimé !';

  @override
  String get videoDiscoveryPassed => 'Passé';

  @override
  String get videoDiscoveryTitle => 'Vidéos de présentation';

  @override
  String get videoDiscoveryEmptyTitle =>
      'Aucune vidéo de présentation pour l\'instant';

  @override
  String get videoDiscoveryEmptySubtitle => 'Soyez le premier à en créer une !';

  @override
  String videoDiscoveryUserFallback(String id) {
    return 'Utilisateur $id';
  }

  @override
  String videoDiscoveryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vues',
      one: '1 vue',
    );
    return '$_temp0';
  }

  @override
  String get videoDiscoveryLike => 'J\'aime';

  @override
  String get videoDiscoveryPass => 'Passer';

  @override
  String get videoDiscoveryReport => 'Signaler';

  @override
  String get videoDiscoveryMute => 'Couper le son';

  @override
  String get videoDiscoveryUnmute => 'Activer le son';

  @override
  String get videoProfileUploadSuccess => 'Vidéo téléversée avec succès !';

  @override
  String get videoProfileDeleteTitle => 'Supprimer la vidéo ?';

  @override
  String get videoProfileDeleteConfirm =>
      'Voulez-vous vraiment supprimer votre vidéo de présentation ?';

  @override
  String get videoProfileDeleted => 'Vidéo supprimée';

  @override
  String get videoProfileScreenTitle => 'Vidéo de présentation';

  @override
  String get videoProfileFirstImpression =>
      'Faites une excellente première impression !';

  @override
  String videoProfileInfoBody(int seconds) {
    return 'Enregistrez une vidéo de $seconds secondes pour vous présenter. Les profils avec vidéo obtiennent 40 % de connexions en plus !';
  }

  @override
  String get videoProfileNoVideo => 'Pas encore de vidéo';

  @override
  String videoProfileMaxSeconds(int seconds) {
    return '$seconds secondes max.';
  }

  @override
  String get videoProfileRecord => 'Enregistrer une vidéo';

  @override
  String get videoProfileUploadFromGallery => 'Importer depuis la galerie';

  @override
  String get videoProfileSave => 'Enregistrer la vidéo';

  @override
  String get videoProfileRecordAgain => 'Enregistrer à nouveau';

  @override
  String get videoProfileTipsTitle => 'Conseils pour une super vidéo :';

  @override
  String get videoProfileTipLighting =>
      'Bon éclairage : placez-vous face à une fenêtre ou une source de lumière';

  @override
  String get videoProfileTipVertical => 'Tenez votre téléphone à la verticale';

  @override
  String get videoProfileTipSmile => 'Souriez et soyez vous-même !';

  @override
  String get videoProfileTipSpeak => 'Parlez clairement et présentez-vous';

  @override
  String get videoProfileTipHobbies =>
      'Mentionnez vos loisirs ou centres d\'intérêt';

  @override
  String adminVerificationBulkBetterPhotoTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utilisateurs',
      one: '1 utilisateur',
    );
    return 'Demander une meilleure photo ($_temp0)';
  }

  @override
  String adminVerificationBulkApproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vérifications approuvées',
      one: '1 vérification approuvée',
    );
    return '$_temp0';
  }

  @override
  String adminVerificationBulkBetterPhotoRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Meilleure photo demandée à $count utilisateurs',
      one: 'Meilleure photo demandée à 1 utilisateur',
    );
    return '$_temp0';
  }

  @override
  String get adminPreSaleTitle => 'Gestion de la prévente';

  @override
  String get adminPreSaleProgramTitle => 'Programme de niveaux de prévente';

  @override
  String get adminPreSaleProgramDescription =>
      'Gérez les utilisateurs de prévente avec compte à rebours par niveau et durée d\'abonnement.';

  @override
  String adminPreSaleCsvFormatHint(String columns, String tiers) {
    return 'Format CSV : $columns\nValeurs de niveau : $tiers';
  }

  @override
  String get adminPreSaleAddSingleEntry => 'Ajouter une entrée';

  @override
  String get adminPreSaleEntries => 'Entrées de prévente';

  @override
  String get adminPreSaleAllTiers => 'Tous les niveaux';

  @override
  String get adminPreSaleNoMatching => 'Aucune entrée correspondante';

  @override
  String get adminPreSaleEmpty =>
      'Aucune entrée de prévente pour l\'instant.\nImportez un CSV pour commencer.';

  @override
  String adminPreSaleDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String adminPreSaleEntryAdded(String email, String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$email ajouté en $tier ($_temp0)';
  }

  @override
  String get adminPreSaleRemoveEntryTitle => 'Supprimer l\'entrée';

  @override
  String adminPreSaleRemoveEntryConfirm(String email) {
    return 'Retirer $email de la liste de prévente ?';
  }

  @override
  String adminPreSaleEntryRemoved(String email) {
    return '$email retiré de la liste de prévente';
  }

  @override
  String get adminPreSaleCsvEmpty => 'Le fichier CSV est vide';

  @override
  String adminPreSaleCsvMissingHeaders(String expected, String found) {
    return 'Le CSV doit avoir les en-têtes : $expected\nTrouvés : $found';
  }

  @override
  String get adminPreSaleCsvNoRows =>
      'Aucune ligne de données valide dans le CSV';

  @override
  String get adminPreSaleInvalidDays =>
      'Veuillez saisir un nombre de jours valide';

  @override
  String get adminPreSaleInfoTitle => 'Infos prévente';

  @override
  String get adminPreSaleCsvFormatTitle => 'Format CSV';

  @override
  String get adminPreSaleCountdownDates =>
      'Dates de compte à rebours par niveau';

  @override
  String get adminPreSaleHowItWorks => 'Comment ça marche';

  @override
  String get adminPreSaleHowItWorksSteps =>
      '1. L\'utilisateur s\'inscrit avec son e-mail\n2. L\'app vérifie la liste de prévente\n3. Le compte à rebours affiche la date du niveau\n4. Après le compte à rebours : l\'abonnement s\'active\n5. Durée = NUMBER_OF_DAYS de la liste\n6. Abonnement de base = même expiration';

  @override
  String get adminStatusProcessing => 'En cours';

  @override
  String get adminStatusCompleted => 'Terminé';

  @override
  String get adminStatusFailed => 'Échoué';

  @override
  String get adminStatusCancelled => 'Annulé';

  @override
  String get adminStatusRefunded => 'Remboursé';

  @override
  String get adminStatusDraft => 'Brouillon';

  @override
  String get adminStatusIssued => 'Émise';

  @override
  String get adminStatusPaid => 'Payée';

  @override
  String get adminStatusOverdue => 'En retard';

  @override
  String get adminOrderTypeCoins => 'Achat de pièces';

  @override
  String get adminOrderTypeSubscription => 'Abonnement';

  @override
  String get adminOrderTypeGift => 'Achat de cadeau';

  @override
  String get adminRoleSuperAdmin => 'Super admin';

  @override
  String get adminRoleModerator => 'Modérateur';

  @override
  String get adminRoleAnalyst => 'Analyste';

  @override
  String get cityPickerTitle => 'Choisir une ville';

  @override
  String get cityPickerSearchHint => 'Rechercher une ville…';

  @override
  String get cityPickerEmptyHint => 'Recherchez une ville ou touchez la carte';

  @override
  String get cityPickerUseCity => 'Utiliser cette ville';

  @override
  String get notifServerViewedYourProfile => 'a consulté votre profil';

  @override
  String get notifServerStartedFollowingYou => 'a commencé à vous suivre';

  @override
  String get notifServerStartedFollowingBusiness =>
      'a commencé à suivre votre entreprise';

  @override
  String get notifServerRatedYourBusiness => 'a noté votre entreprise';

  @override
  String notifServerRatedYourBusinessStars(int stars) {
    return 'a noté votre entreprise $stars★';
  }

  @override
  String get notifServerReviewedYourExperience =>
      'a donné un avis sur votre expérience';

  @override
  String get notifServerTapToSeeWhoStoppedBy =>
      'Touchez pour voir qui est passé';

  @override
  String get notifServerTapToSeeTheirProfile => 'Touchez pour voir son profil';

  @override
  String get notifServerNewFollower => 'Vous avez un nouvel abonné';

  @override
  String get notifServerNewRating => 'Vous avez une nouvelle note';

  @override
  String get notifServerYourCommunity => 'Votre communauté';

  @override
  String get notifServerYourEvent => 'Votre événement';

  @override
  String get notifServerProfileBoostLive =>
      'Le boost de votre profil est actif';

  @override
  String get notifServerProfileBoostEnded =>
      'Le boost de votre profil est terminé';

  @override
  String get notifServerProfilePromoted =>
      'Votre profil est montré à plus de personnes';

  @override
  String get notifServerEventPromoted =>
      'Votre événement est mis en avant dans Explore';

  @override
  String get notifServerBoostAgainProfile =>
      'Boostez à nouveau pour toucher plus de personnes';

  @override
  String get notifServerBoostAgainEvent =>
      'Boostez à nouveau pour le garder en avant';

  @override
  String get notifServerCheckedIn => 'Vous êtes enregistré — profitez-en !';

  @override
  String get notifServerTicketReady => 'Votre billet est prêt';

  @override
  String get notifServerTicketSold => 'Billet vendu';

  @override
  String get notifServerPaymentToConfirm => 'Paiement à confirmer';

  @override
  String get notifServerPaymentNotConfirmed => 'Paiement non confirmé';

  @override
  String get notifServerPaymentsWaiting =>
      'Paiements en attente de votre confirmation';

  @override
  String get notifServerTicketRefunded => 'Billet remboursé';

  @override
  String get notifServerTicketDisputed => 'Paiement du billet contesté';

  @override
  String get notifServerRefundToPayBack => 'Remboursement à reverser';

  @override
  String get notifServerTicketReservationExpired =>
      'Réservation du billet expirée';

  @override
  String get notifServerExperienceHidden =>
      'Votre expérience a été masquée après plusieurs signalements';

  @override
  String get notifServerPendingReview =>
      'En attente de vérification par GreenGo';

  @override
  String get notifServerMonthlyCoinsAdded => 'Pièces mensuelles ajoutées';

  @override
  String get notifServerSupportReplied => 'Le support a répondu à votre ticket';

  @override
  String get notifServerSupportNewReply =>
      'Vous avez une nouvelle réponse du support.';

  @override
  String get notifServerIncognitoExpiring => 'Le mode incognito expire bientôt';

  @override
  String get notifServerIncognitoExpiringBody =>
      'Votre mode incognito expire dans moins d\'1 heure !';

  @override
  String get notifServerTravelerExpiring => 'Le mode voyageur expire bientôt';

  @override
  String get notifServerTravelerExpiringBody =>
      'Votre mode voyageur expire dans moins d\'1 heure !';

  @override
  String get notifServerProfileVerified => 'Profil vérifié !';

  @override
  String get notifServerProfileVerifiedBody =>
      'Votre profil a été vérifié ! Vous avez maintenant un badge vérifié.';

  @override
  String get notifServerNewVerificationPhoto =>
      'Nouvelle photo de vérification requise';

  @override
  String get notifServerVerificationUpdate => 'Mise à jour de la vérification';

  @override
  String notifServerJoinedYourCommunity(String name) {
    return 'a rejoint votre communauté $name';
  }

  @override
  String notifServerJoinedYourEvent(String name) {
    return 'a rejoint votre événement $name';
  }

  @override
  String notifServerLikedYourEvent(String name) {
    return 'a aimé votre événement $name';
  }

  @override
  String notifServerJoinedYourGroup(String name) {
    return 'a rejoint votre groupe $name';
  }

  @override
  String notifServerAddedYouAsCoOwner(String name) {
    return 'vous a ajouté comme copropriétaire de $name';
  }

  @override
  String notifServerAddedYouToGroup(String name) {
    return 'vous a ajouté à $name';
  }

  @override
  String notifServerEventBoostLive(String name) {
    return 'Le boost de votre événement $name est actif';
  }

  @override
  String notifServerEventBoostEnded(String name) {
    return 'Le boost de votre événement $name est terminé';
  }

  @override
  String notifServerTicketScanned(String name) {
    return 'Votre billet pour $name a été scanné';
  }

  @override
  String notifServerNewEventIn(String name) {
    return 'Nouvel événement à $name';
  }

  @override
  String notifServerEventCancelledIn(String name) {
    return 'Événement annulé dans $name';
  }

  @override
  String notifServerEventUpdatedIn(String name) {
    return 'Événement mis à jour dans $name';
  }

  @override
  String notifServerNewEventFrom(String name) {
    return 'Nouvel événement de $name';
  }

  @override
  String notifServerAnnouncement(String name) {
    return 'Annonce · $name';
  }

  @override
  String get culturalExchangeCategoryFood => 'Cuisine';

  @override
  String get culturalExchangeCategoryTransportation => 'Transports';

  @override
  String get culturalExchangeCategoryDating => 'Faire connaissance';

  @override
  String get culturalExchangeCategoryCustoms => 'Coutumes';

  @override
  String get culturalExchangeCategoryLanguage => 'Langue';

  @override
  String get culturalExchangeCategorySafety => 'Sécurité';

  @override
  String get culturalExchangeSectionCuisine => 'Cuisine';

  @override
  String get culturalExchangeSectionCustoms => 'Coutumes';

  @override
  String get culturalExchangeSectionKeyPhrases => 'Phrases clés';

  @override
  String get culturalExchangeSectionPhrases => 'Phrases';

  @override
  String get culturalExchangeSpotlightBadge => 'À LA UNE';

  @override
  String get culturalExchangeContentComingSoon => 'Contenu bientôt disponible';

  @override
  String get culturalExchangeContentComingSoonBody =>
      'Nous préparons un contenu détaillé pour cette mise en avant.';

  @override
  String get culturalExchangeLike => 'J\'aime';

  @override
  String culturalExchangeWeeksAgo(int count) {
    return 'il y a $count sem';
  }

  @override
  String culturalExchangeMonthsAgo(int count) {
    return 'il y a $count mois';
  }

  @override
  String get culturalExchangeDailyInsightJapanBow =>
      'Au Japon, il est d\'usage de s\'incliner pour saluer. Plus l\'inclinaison est profonde, plus vous montrez de respect.';

  @override
  String get culturalExchangeSelectCountry => 'Sélectionnez un pays';

  @override
  String get culturalExchangeChooseCountry => 'Choisissez un pays...';

  @override
  String get culturalExchangeSelectCountryAbove =>
      'Sélectionnez un pays ci-dessus';

  @override
  String get culturalExchangeLearnEtiquette =>
      'Découvrez le savoir-vivre de plus de 20 pays\ndu monde entier';

  @override
  String get culturalExchangeDos => 'À faire';

  @override
  String get culturalExchangeDonts => 'À éviter';

  @override
  String get notifNewConversationTitle => 'Nouvelle conversation';

  @override
  String notifNewMessageFrom(String name) {
    return 'Nouveau message de $name';
  }

  @override
  String notifStartedConversation(String name) {
    return '$name a commencé une conversation avec vous.';
  }

  @override
  String get notifNewPhotoLikeTitle => 'Nouveau j\'aime sur votre photo';

  @override
  String notifLikedYourPhoto(String name) {
    return '$name a aimé votre photo';
  }

  @override
  String get notifCoinsReceivedTitle => 'Vous avez reçu des pièces !';

  @override
  String chatSystemCoinsReceived(String name, int amount) {
    return '$name vous a envoyé $amount pièces !';
  }

  @override
  String chatSystemCoinsSent(int amount) {
    return 'Je viens de vous envoyer $amount pièces !';
  }

  @override
  String chatSystemSupportWelcome(String subject) {
    return 'Bienvenue au support GreenGo ! Un agent du support va vous répondre sous peu. Votre ticket : $subject';
  }

  @override
  String chatSystemSupportAgentJoined(String name) {
    return '$name a rejoint la conversation et va vous aider.';
  }

  @override
  String get chatSystemSupportAgentFallback => 'Agent du support';

  @override
  String get chatSystemSupportInProgress =>
      'Un agent du support traite votre demande.';

  @override
  String get chatSystemSupportWaitingOnUser => 'Nous attendons votre réponse.';

  @override
  String get chatSystemSupportResolved =>
      'Votre demande a été résolue. Merci d\'avoir contacté le support GreenGo !';

  @override
  String get chatSystemSupportClosed => 'Ce ticket de support a été fermé.';

  @override
  String get chatSystemSupportStatusUpdated => 'Statut du ticket mis à jour.';

  @override
  String get commonUnknownUser => 'Utilisateur inconnu';

  @override
  String get chatSupportDescription => 'Description';

  @override
  String get supportReportFollowUpTitle => 'Suivi du signalement';

  @override
  String supportReportFollowUpSubject(String reason) {
    return 'Suivi du signalement : $reason';
  }

  @override
  String supportReportFollowUpDetails(
      String reason, String message, String user, String date) {
    return 'Motif : $reason\nMessage signalé : « $message »\nUtilisateur signalé : $user\nSignalé le : $date';
  }

  @override
  String get supportChatWithGreenGoSubject =>
      'Discussion avec le support GreenGo';

  @override
  String invoiceLineCoins(int count) {
    return '$count pièces GreenGo';
  }

  @override
  String get invoiceLineSubscription => 'Abonnement';

  @override
  String get invoiceLineGiftPackage => 'Pack de pièces cadeau';

  @override
  String get srvSomeone => 'Quelqu’un';

  @override
  String get srvJoinedYourCommunity => 'a rejoint votre communauté';

  @override
  String get srvJoinedYourEvent => 'participe à votre événement';

  @override
  String get srvLikedYourEvent => 'a aimé votre événement';

  @override
  String get srvJoinedYourGroup => 'a rejoint votre groupe';

  @override
  String get srvAddedYouToAGroup => 'vous a ajouté à un groupe';

  @override
  String get srvGroup => 'Groupe';

  @override
  String srvGroupMembersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres ont quitté le groupe',
      one: 'Un membre a quitté le groupe',
    );
    return '$_temp0';
  }

  @override
  String get srvTicketScanned => 'Votre billet a été scanné';

  @override
  String get srvEventBoostLive => 'Le boost de votre événement est actif';

  @override
  String get srvEventBoostEnded => 'Le boost de votre événement est terminé';

  @override
  String get srvAddedYouAsCoOwnerOfEvent =>
      'vous a ajouté comme co-organisateur d’un événement';

  @override
  String get srvAnEvent => 'Un événement';

  @override
  String srvPaymentsWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements',
      one: '1 paiement',
    );
    return '$_temp0';
  }

  @override
  String get srvNewReview => 'Nouvel avis';

  @override
  String get srvMentionedYouInReviewReply =>
      'vous a mentionné dans une réponse à un avis';

  @override
  String get srvRepliedToYourReview => 'a répondu à votre avis';

  @override
  String get srvExperience => 'Expérience';

  @override
  String get srvBookingRequested => 'a demandé à réserver votre expérience';

  @override
  String get srvBookingBooked => 'a réservé votre expérience';

  @override
  String get srvBookingConfirmed => 'Réservation confirmée';

  @override
  String get srvBookingAccepted => 'a accepté votre demande de réservation';

  @override
  String get srvBookingDeclined => 'a refusé votre demande de réservation';

  @override
  String get srvBookingCancelledTheirs => 'a annulé sa réservation';

  @override
  String get srvBookingCancelledYours => 'a annulé votre réservation';

  @override
  String srvBookingRefundOwed(String title, int percent) {
    return '$title — remboursement dû : $percent %.';
  }

  @override
  String get srvBookingCheckedIn => 'Vous êtes enregistré';

  @override
  String get srvBookingCancelledByHost =>
      'Votre réservation a été annulée par l’hôte';

  @override
  String srvBookingCancelledByHostBody(String title) {
    return '$title — le créneau n’est plus disponible. Tout paiement est remboursé.';
  }

  @override
  String get srvBookingNoShow => 'vous a marqué comme absent';

  @override
  String srvBookingNoShowBody(String title, int hours) {
    return '$title — vous pouvez le contester dans les $hours h suivant la fin.';
  }

  @override
  String get srvBookingGuestSaysPaid => 'indique avoir payé sa réservation';

  @override
  String get srvBookingPaymentConfirmed => 'a confirmé votre paiement';

  @override
  String get srvBookingProblemReported =>
      'a signalé un problème avec sa réservation';

  @override
  String get srvBookingReportReviewed => 'Votre signalement a été examiné';

  @override
  String get srvBookingHostWarning =>
      'Avertissement concernant une de vos réservations';

  @override
  String get srvBookingReportReviewedHost =>
      'Un signalement de réservation a été examiné';

  @override
  String srvBookingReviewedBody(String title) {
    return '$title.';
  }

  @override
  String srvBookingReviewedRefundBody(String title, int percent) {
    return '$title. Remboursement dû : $percent %.';
  }

  @override
  String get srvBookingCancelled => 'Votre réservation a été annulée';

  @override
  String srvBookingNoLongerAvailable(String title) {
    return '$title n’est plus disponible.';
  }

  @override
  String get srvBookingComingUp => 'Votre expérience approche';

  @override
  String get srvBookingHostingSoon =>
      'Vous accueillez bientôt des participants';

  @override
  String get srvBookingRequestExpired =>
      'Votre demande de réservation a expiré';

  @override
  String srvBookingRequestExpiredBody(String title) {
    return '$title — l’hôte n’a pas répondu à temps.';
  }

  @override
  String get srvBookingHowWasIt => 'Comment s’est passée votre expérience ?';

  @override
  String srvBookingReviewIt(String title) {
    return 'Évaluez $title';
  }

  @override
  String get srvBookingReviewGuest => 'Évaluez votre participant';

  @override
  String srvBookingPayLink(String title) {
    return '$title — payez l’hôte avec son lien de paiement.';
  }

  @override
  String srvBookingPayOnline(String title) {
    return '$title — payez dans l’app pour obtenir votre billet.';
  }

  @override
  String srvBookingPayCash(String title) {
    return '$title — payez l’hôte en espèces sur place.';
  }

  @override
  String get srvHostReviewedYou => 'Votre hôte vous a évalué';

  @override
  String get srvHostReviewedYouBody =>
      'Évaluez votre expérience pour voir ce qu’il a écrit.';

  @override
  String get srvNewReviewFromHost => 'Vous avez un nouvel avis d’un hôte';

  @override
  String get srvGuestLeftReview => 'Votre participant a laissé un avis';

  @override
  String get srvGuestLeftReviewBody =>
      'Évaluez votre participant pour révéler les deux avis.';

  @override
  String get srvSupportNewMessageOnTicket =>
      'Nouveau message sur un ticket d’assistance';

  @override
  String get srvSupportUserSentMessage =>
      'Un utilisateur a envoyé un nouveau message.';

  @override
  String get srvVerificationResubmit =>
      'Veuillez envoyer une nouvelle photo de vérification.';

  @override
  String srvVerificationResubmitReason(String reason) {
    return 'Veuillez envoyer une nouvelle photo de vérification. Motif : $reason';
  }

  @override
  String get srvVerificationRejected =>
      'Votre vérification n’a pas été approuvée. Veuillez réessayer.';

  @override
  String srvVerificationRejectedReason(String reason) {
    return 'Votre vérification n’a pas été approuvée. Motif : $reason';
  }

  @override
  String srvBundleNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux messages',
      one: '1 nouveau message',
    );
    return '$_temp0';
  }

  @override
  String srvBundleLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes ont aimé votre profil',
      one: '1 personne a aimé votre profil',
    );
    return '$_temp0';
  }

  @override
  String srvBundleProfileViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vues de profil',
      one: '1 vue de profil',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNewConnections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles connexions',
      one: '1 nouvelle connexion',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications',
      one: '1 notification',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNamesAndOthers(String names, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres',
      one: '1 autre',
    );
    return '$names et $_temp0';
  }

  @override
  String srvLevelUpTitle(int level) {
    return 'Niveau supérieur ! Vous êtes maintenant niveau $level !';
  }

  @override
  String srvLevelUpBody(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: 'Félicitations ! Vous avez gagné $coins pièces.',
      one: 'Félicitations ! Vous avez gagné 1 pièce.',
    );
    return '$_temp0';
  }

  @override
  String srvAchievementUnlockedTitle(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Première connexion',
        'social_butterfly': 'Papillon social',
        'popular': 'Populaire',
        'video_enthusiast': 'Fan de vidéo',
        'daily_streak_7': 'Série de 7 jours',
        'daily_streak_30': 'Série de 30 jours',
        'other': 'Nouveau succès',
      },
    );
    return 'Succès débloqué : $_temp0 !';
  }

  @override
  String srvAchievementDescription(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Établissez votre première connexion',
        'social_butterfly': 'Envoyez 100 messages',
        'popular': 'Établissez 50 connexions',
        'video_enthusiast': 'Terminez 10 appels vidéo',
        'daily_streak_7': 'Connectez-vous 7 jours d’affilée',
        'daily_streak_30': 'Connectez-vous 30 jours d’affilée',
        'other': 'Continuez comme ça !',
      },
    );
    return '$_temp0';
  }

  @override
  String srvChallengeCompletedTitle(String challenge) {
    String _temp0 = intl.Intl.selectLogic(
      challenge,
      {
        'send_5_messages': 'Lanceur de conversations',
        'get_3_matches': 'Connecteur',
        'complete_profile': 'Profil parfait',
        'video_call_1': 'Face à face',
        'other': 'Défi du jour',
      },
    );
    return 'Défi relevé : $_temp0 !';
  }

  @override
  String srvChallengeRewardsBody(int xp, int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coins pièces',
      one: '1 pièce',
    );
    return 'Récupérez vos récompenses : $xp XP et $_temp0';
  }

  @override
  String srvSentYouCoins(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'vous a envoyé $amount pièces',
      one: 'vous a envoyé 1 pièce',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyFree(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'Vous avez reçu $amount pièces ce mois-ci avec votre abonnement gratuit.',
      one: 'Vous avez reçu 1 pièce ce mois-ci avec votre abonnement gratuit.',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyTier(int amount, String tier) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'Vous avez reçu $amount pièces ce mois-ci avec votre abonnement $tier.',
      one: 'Vous avez reçu 1 pièce ce mois-ci avec votre abonnement $tier.',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiringTitle => 'Votre abonnement expire bientôt';

  @override
  String srvMembershipExpiringBody(String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Votre abonnement $tier expire dans $days jours. Prolongez-le pour garder vos fonctionnalités premium !',
      one:
          'Votre abonnement $tier expire dans 1 jour. Prolongez-le pour garder vos fonctionnalités premium !',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiredTitle => 'Abonnement expiré';

  @override
  String get srvMembershipExpiredBody =>
      'Votre abonnement a expiré. Souscrivez un nouvel abonnement pour retrouver les fonctionnalités premium.';

  @override
  String get srvSubscriptionCancelledTitle => 'Abonnement résilié';

  @override
  String get srvSubscriptionEndedBody =>
      'Votre abonnement a pris fin. Vous pouvez vous réabonner à tout moment depuis la Boutique.';

  @override
  String get srvPaymentFailedTitle => 'Échec du paiement';

  @override
  String get srvSubscriptionPaymentFailedBody =>
      'Le paiement de votre abonnement a échoué. Mettez à jour votre moyen de paiement pour garder votre abonnement actif.';

  @override
  String get srvGiftFromGreenGo => 'Un cadeau de GreenGo';

  @override
  String get srvAccountNotApprovedTitle => 'Compte non approuvé';

  @override
  String srvAccountNotApprovedReason(String reason) {
    return 'Votre compte n’a pas pu être approuvé. Motif : $reason';
  }

  @override
  String get srvAccountNotApprovedContactSupport =>
      'Votre compte n’a pas pu être approuvé. Veuillez contacter l’assistance.';

  @override
  String get srvEvent => 'Événement';

  @override
  String get srvNewEvent => 'Nouvel événement';

  @override
  String get srvEventStartingNow => 'commence maintenant — profitez-en !';

  @override
  String get srvEventStartsIn6h => 'commence dans environ 6 heures';

  @override
  String get srvEventIsTomorrow => 'c’est demain — à bientôt !';

  @override
  String get srvNewEventInYourCommunity =>
      'Nouvel événement dans votre communauté';

  @override
  String get srvEventCancelledInYourCommunity =>
      'Événement annulé dans votre communauté';

  @override
  String get srvEventUpdatedInYourCommunity =>
      'Événement modifié dans votre communauté';

  @override
  String srvEventHasBeenCancelled(String event) {
    return '« $event » a été annulé';
  }

  @override
  String srvEventNewTime(String event) {
    return 'Nouvel horaire pour « $event »';
  }

  @override
  String srvEventNewLocation(String event) {
    return 'Nouveau lieu pour « $event »';
  }

  @override
  String srvAnnouncementTitle(String name) {
    return '📣 $name';
  }

  @override
  String get srvAnnouncementACommunity => '📣 Une communauté';

  @override
  String get srvAnnouncementAnEvent => '📣 Annonce de l’événement';

  @override
  String get srvReportReviewedTitle => 'Votre signalement a été examiné';

  @override
  String get srvReportReviewedActionTaken =>
      'Merci pour votre signalement. Notre équipe l\'a examiné et a pris des mesures conformément aux Règles de la communauté.';

  @override
  String get srvReportReviewedNoViolation =>
      'Merci pour votre signalement. Notre équipe l\'a examiné et n\'a constaté aucune infraction aux Règles de la communauté.';

  @override
  String get srvModerationDecisionTitle =>
      'Une décision de modération concernant votre compte';

  @override
  String get srvModerationDecisionBody =>
      'Nous avons pris des mesures conformément aux Règles de la communauté. Touchez pour lire les motifs et comment faire appel.';

  @override
  String get srvNewMessage => 'Nouveau message';

  @override
  String get srvGroupCreated => 'Groupe créé';

  @override
  String get srvYouWereAddedToGroup => 'Vous avez été ajouté au groupe';

  @override
  String srvGroupMembersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux membres ont rejoint le groupe',
      one: 'Un nouveau membre a rejoint le groupe',
    );
    return '$_temp0';
  }

  @override
  String get srvUnknownUser => 'Utilisateur inconnu';

  @override
  String srvCoinsReceivedBody(String name, int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount pièces',
      one: '1 pièce',
    );
    return '$name vous a envoyé $_temp0 !';
  }

  @override
  String get srvNewEventFromFollowedBusiness =>
      'Nouvel événement d’une entreprise que vous suivez';

  @override
  String get srvMessageRemovedByModerator =>
      'Ce message a été supprimé par un modérateur';

  @override
  String get srvSupportAiHandoff =>
      'Je comprends que vous souhaitez parler à un conseiller. Je vous mets en relation. Un membre de l’équipe d’assistance vous répondra rapidement.';

  @override
  String get becomeBusinessOneWayHint =>
      'Nécessite Platinum. Passage unique : il ne peut pas être annulé.';

  @override
  String get businessPermanentInfo =>
      'Ton compte est définitivement un compte professionnel et ne peut pas redevenir personnel. Les outils professionnels fonctionnent tant que Platinum est actif ; s\'il expire, ils sont en pause jusqu\'au renouvellement.';

  @override
  String get paidBusinessOnlyNote =>
      'Les billets payants sont disponibles pour les comptes professionnels.';

  @override
  String get paidBusinessOnlyBody =>
      'Les événements et expériences gratuits sont ouverts à tous. Pour faire payer des billets ou des réservations, il te faut un compte professionnel actif (Platinum).';

  @override
  String get paidBusinessPausedNote =>
      'Ton entreprise est en pause : renouvelle Platinum pour vendre à nouveau des billets payants.';

  @override
  String get uexpBusinessRequiredTitle =>
      'Les annonces payantes sont réservées aux comptes professionnels';

  @override
  String get tpErrSellerNotBusiness =>
      'Les ventes sont en pause : les billets et réservations payants ne sont proposés que par des comptes professionnels actifs.';

  @override
  String get tpAutoSectionTitle => 'Paiement et validation automatiques';

  @override
  String get tpAutoSectionHint =>
      'Connecte Stripe ou Mercado Pago : les acheteurs paient dans l’app et leurs billets sont confirmés instantanément, sans vérification manuelle.';

  @override
  String get tpManualSectionTitle => 'Paiement et validation manuels';

  @override
  String get tpManualSectionHint =>
      'Sans configuration : les acheteurs te paient directement avec l’un des moyens de paiement ci-dessous (ou espèces / virement). Tu confirmes chaque paiement toi-même avec le bouton Paiements à confirmer en haut ; le billet est émis dès ta confirmation.';

  @override
  String get paymentMethodsSettingsSubtitle =>
      'Comment on peut te payer directement (Pix, PayPal…)';

  @override
  String get communitiesBusinessCannotJoin =>
      'Les comptes professionnels ne peuvent pas rejoindre de communautes. Desactivez le mode business pour rejoindre.';

  @override
  String get becomeBusinessPermanentHint =>
      'Amélioration unique. Cette action est irréversible.';

  @override
  String get storefrontEnabled => 'Vitrine activee';

  @override
  String get storefrontDisabled => 'Vitrine desactivee';

  @override
  String get storefrontToggleHint =>
      'Activez ou desactivez votre vitrine a tout moment';

  @override
  String get tpGetPaidManualInfo =>
      'Sans configuration : choisissez un de vos moyens de paiement du profil (ou espèces / virement) dans l\'événement ou l\'expérience et confirmez chaque paiement vous-même.';

  @override
  String emailTicketSubject(String title) {
    return 'Votre billet pour $title';
  }

  @override
  String get emailTicketIntro =>
      'Votre réservation est confirmée. Présentez le code QR à l’entrée : chaque code n’est valable qu’une fois.';

  @override
  String get emailTicketWhen => 'Quand';

  @override
  String get emailTicketWhere => 'Où';

  @override
  String get emailTicketTypeLabel => 'Type de billet';

  @override
  String get emailTicketPartySizeLabel => 'Nombre de personnes';

  @override
  String get emailTicketCodeLabel => 'Code de réservation';

  @override
  String emailTicketQrCaption(int index, int count) {
    return 'Billet $index sur $count';
  }

  @override
  String get emailTicketFooter =>
      'Vous retrouverez aussi vos billets dans l’app GreenGo. Ne partagez pas ces codes QR.';

  @override
  String emailParticipantsSubject(String title) {
    return 'Liste des participants : $title';
  }

  @override
  String emailParticipantsIntro(String title, String when, int count) {
    return 'Vous trouverez en pièce jointe la liste des participants de $title ($when). Participants : $count.';
  }

  @override
  String get emailParticipantsPrivacy =>
      'Ce fichier contient des données personnelles partagées uniquement pour l’entrée. Ne le partagez pas et supprimez-le après l’événement.';

  @override
  String get csvColName => 'Nom';

  @override
  String get csvColEmail => 'E-mail';

  @override
  String get csvColBookingCode => 'Code de réservation';

  @override
  String get csvColTicket => 'Type de billet / personnes';

  @override
  String get csvColStatus => 'Statut';

  @override
  String get csvStatusPaid => 'payé';

  @override
  String get csvStatusConfirmed => 'confirmé';

  @override
  String get csvStatusCheckedIn => 'enregistré';

  @override
  String get participantsEmailButton => 'M’envoyer la liste des participants';

  @override
  String get participantsEmailSent =>
      'Liste des participants envoyée à l’e-mail de votre compte';

  @override
  String get participantsEmailRateLimited =>
      'Vous venez de la demander. Réessayez dans quelques minutes.';

  @override
  String get participantsEmailFailed =>
      'Impossible d’envoyer la liste des participants. Réessayez plus tard.';

  @override
  String get participantsEmailNoEmail =>
      'Votre compte n’a pas d’adresse e-mail pour recevoir la liste.';

  @override
  String get checkoutOrganizerShareNotice =>
      'Votre nom et votre e-mail seront communiqués à l’organisateur pour l’entrée.';

  @override
  String get openSourceLicensesTitle => 'Licences open source';

  @override
  String get openSourceLicensesSubtitle =>
      'Polices et composants logiciels utilisés dans cette application';
}
