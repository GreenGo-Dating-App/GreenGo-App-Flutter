// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get adminDailySuperLikes => 'Super Likes quotidiens';

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
      'Voir les statistiques de matching et de messagerie';

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
  String get adminMatchPriority => 'Priorité de matching';

  @override
  String get adminMatchingAndVisibility => 'Matching et visibilité';

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
  String get adminUseVideoCallingFeature =>
      'Utiliser la fonction d\'appel vidéo';

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
  String get adminVideoChat => 'Chat vidéo';

  @override
  String get adminVideoCoinPackages => 'Forfaits de pièces vidéo';

  @override
  String get adminVideoCoins => 'Pièces vidéo';

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
  String get appTagline => 'Découvrez Votre Partenaire Parfait';

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
  String get blindDateActivate => 'Activer le mode Rendez-vous à l\'aveugle';

  @override
  String get blindDateDeactivate => 'Désactiver';

  @override
  String get blindDateDeactivateMessage =>
      'Vous retournerez au mode découverte normal.';

  @override
  String get blindDateDeactivateTitle =>
      'Désactiver le mode Rendez-vous à l\'aveugle ?';

  @override
  String get blindDateDeactivateTooltip =>
      'Désactiver le mode Rendez-vous à l\'aveugle';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Révélation instantanée pour $cost pièces';
  }

  @override
  String get blindDateFeatureNoPhotos =>
      'Aucune photo de profil visible au départ';

  @override
  String get blindDateFeaturePersonality =>
      'Focus sur la personnalité et les centres d\'intérêt';

  @override
  String get blindDateFeatureUnlock => 'Les photos se débloquent en discutant';

  @override
  String get blindDateGetCoins => 'Obtenir des pièces';

  @override
  String get blindDateInstantReveal => 'Révélation instantanée';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return 'Révéler toutes les photos de ce match pour $cost pièces ?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Révélation instantanée ($cost pièces)';
  }

  @override
  String get blindDateInsufficientCoins => 'Pièces insuffisantes';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'Vous avez besoin de $cost pièces pour révéler les photos instantanément.';
  }

  @override
  String get blindDateInterests => 'Centres d\'intérêt';

  @override
  String blindDateKmAway(String distance) {
    return 'à $distance km';
  }

  @override
  String get blindDateLetsExchange => 'Échangeons !';

  @override
  String get blindDateMatchMessage =>
      'Vous vous plaisez mutuellement ! Commencez à discuter pour révéler vos photos.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total messages';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return 'encore $count';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count messages avant la révélation';
  }

  @override
  String get blindDateModeActivated => 'Mode Rendez-vous à l\'aveugle activé !';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Matchez selon la personnalité, pas le physique.\nLes photos se révèlent après $threshold messages.';
  }

  @override
  String get blindDateModeTitle => 'Mode Rendez-vous à l\'aveugle';

  @override
  String get blindDateMysteryPerson => 'Personne mystère';

  @override
  String get blindDateNoCandidates => 'Aucun candidat disponible';

  @override
  String get blindDateNoMatches => 'Pas encore de matchs';

  @override
  String blindDatePendingReveal(int count) {
    return 'Révélation en attente ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Progression de la Révélation';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'Les photos se révèlent après $threshold messages';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return 'Photos révélées ! $coinsSpent pièces dépensées.';
  }

  @override
  String get blindDatePhotosRevealedLabel => 'Photos révélées !';

  @override
  String get blindDateReveal => 'Révéler';

  @override
  String blindDateRevealed(int count) {
    return 'Révélé ($count)';
  }

  @override
  String get blindDateRevealedMatch => 'Match Révélé';

  @override
  String get blindDateStartSwiping =>
      'Commencez à swiper pour trouver votre rendez-vous à l\'aveugle !';

  @override
  String get blindDateTabDiscover => 'Découvrir';

  @override
  String get blindDateTabMatches => 'Matchs';

  @override
  String get blindDateTitle => 'Rendez-vous à l\'aveugle';

  @override
  String get blindDateViewMatch => 'Voir le match';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonusCoins bonus !)';
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
      'Impossible d\'annuler — vous avez déjà matché !';

  @override
  String get casualCategory => 'Décontracté';

  @override
  String get casualDating => 'Rencontres occasionnelles';

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
  String get chatNoMessagesYet => 'Pas encore de messages';

  @override
  String get chatNoPrivatePhotos => 'Aucune photo privée disponible';

  @override
  String get chatNoSupportTickets => 'Aucun Ticket de Support';

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
  String get chatSearchByNameOrNickname => 'Rechercher par nom ou @pseudo';

  @override
  String get chatSearchConversationsHint => 'Rechercher des conversations...';

  @override
  String get chatSend => 'Envoyer';

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
  String get chatSomeone => 'Quelqu\'un';

  @override
  String get chatStarMessage => 'Mettre en Favori';

  @override
  String get chatStartSwipingToChat =>
      'Balayez et matchez pour discuter avec des personnes !';

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
  String get chatYou => 'Vous';

  @override
  String get chatYouRevokedAlbum => 'Vous avez révoqué l\'accès à l\'album';

  @override
  String get chatYouSharedAlbum => 'Vous avez partagé votre album privé';

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
    return '$amount Coins';
  }

  @override
  String coinsAmountVideoMinutes(Object amount) {
    return '$amount Minutes Video';
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
  String coinsExpiring(Object count) {
    return '$count expirent bientot';
  }

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
  String get coinsLabel => 'Coins';

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
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return 'Acheter $totalMinutes minutes video pour $price ?';
  }

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
  String get coinsTabVideoCoins => 'Pièces vidéo';

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
  String get coinsVideoCallMatches => 'Appel video avec vos matchs';

  @override
  String get coinsVideoCoinInfo => '1 Video Coin = 1 minute d\'appel video';

  @override
  String get coinsVideoMin => 'Min Video';

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
  String get culturalExchangeDatingEtiquette => 'Étiquette des rencontres';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Guide d\'étiquette des rencontres';

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
  String get datePlanningCategory => 'Planifier un Rendez-vous';

  @override
  String get dateSchedulerAccept => 'Accepter';

  @override
  String get dateSchedulerCancelConfirm =>
      'Êtes-vous sûr de vouloir annuler ce rendez-vous ?';

  @override
  String get dateSchedulerCancelTitle => 'Annuler le rendez-vous';

  @override
  String get dateSchedulerConfirmed => 'Rendez-vous confirmé !';

  @override
  String get dateSchedulerDecline => 'Refuser';

  @override
  String get dateSchedulerEnterTitle => 'Veuillez saisir un titre';

  @override
  String get dateSchedulerKeepDate => 'Garder le rendez-vous';

  @override
  String get dateSchedulerNotesLabel => 'Notes (optionnel)';

  @override
  String get dateSchedulerPlanningHint => 'ex. : Café, Dîner, Cinéma...';

  @override
  String get dateSchedulerReasonLabel => 'Raison (optionnel)';

  @override
  String get dateSchedulerReschedule => 'Reprogrammer';

  @override
  String get dateSchedulerRescheduleTitle => 'Reprogrammer le rendez-vous';

  @override
  String get dateSchedulerSchedule => 'Planifier';

  @override
  String get dateSchedulerScheduled => 'Rendez-vous planifié !';

  @override
  String get dateSchedulerTabPast => 'Passés';

  @override
  String get dateSchedulerTabPending => 'En attente';

  @override
  String get dateSchedulerTabUpcoming => 'À venir';

  @override
  String get dateSchedulerTitle => 'Mes rendez-vous';

  @override
  String get dateSchedulerWhatPlanning => 'Qu\'est-ce que vous prévoyez ?';

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
  String get discoveryFilterLiked => 'Aimés';

  @override
  String get discoveryFilterMatches => 'Matchs';

  @override
  String get discoveryFilterPassed => 'Refusés';

  @override
  String get discoveryFilterSkipped => 'Ignorés';

  @override
  String get discoveryFilterSuperLiked => 'Super Like';

  @override
  String get discoveryFilterTravelers => 'Voyageurs';

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
      'Commencez à swiper pour trouver votre match parfait !';

  @override
  String get emptyStateNoMatchesTitle => 'Pas encore de matchs';

  @override
  String get emptyStateNoMessagesMessage =>
      'Quand vous aurez un match, vous pourrez discuter ici.';

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
  String get eventsTabNearby => 'À proximité';

  @override
  String get eventsTabUpcoming => 'À venir';

  @override
  String get eventsThisMonth => 'Ce mois-ci';

  @override
  String get eventsThisWeekFilter => 'Cette semaine';

  @override
  String get eventsTitle => 'Evenements';

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
    return 'Impossible d\'enregistrer les préférences';
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
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Direct';

  @override
  String get filterMessaged => 'Avec Messages';

  @override
  String get filterNew => 'Nouveaux';

  @override
  String get filterNewMessages => 'Nouveaux';

  @override
  String get filterNotReplied => 'Sans réponse';

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
  String get flirtyCategory => 'Flirteur';

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
  String get gamificationYearly => 'Annee';

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
      'Super ! Vos intérêts nous aident à trouver de meilleures correspondances';

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
  String get icebreakersCategoryDateIdeas => 'Idées de rendez-vous';

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
  String get interestBusiness => 'Business';

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
  String get itsAMatch => 'Échangeons !';

  @override
  String get joinMessage =>
      'Rejoignez GreenGoChat et trouvez votre partenaire parfait';

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
      'ex. : « Salutations en espagnol pour les rencontres »';

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
      'ex. « Salutations espagnoles pour les rencontres »';

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
  String get letsExchange => 'Echangeons !';

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
  String get longTermRelationship => 'Relation à long terme';

  @override
  String get lookingFor => 'Recherche';

  @override
  String get lvl => 'NIV';

  @override
  String get manageCouponsTiersRules => 'Gérer coupons, niveaux et règles';

  @override
  String get matchDetailsTitle => 'Details du Match';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Vous et $name voulez echanger des langues !';
  }

  @override
  String get matchNotifKeepSwiping => 'Continuer';

  @override
  String get matchNotifLetsChat => 'Discutons !';

  @override
  String get matchNotifLetsExchange => 'ECHANGEONS !';

  @override
  String get matchNotifViewProfile => 'Voir le Profil';

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilité';
  }

  @override
  String matchedOnDate(String date) {
    return 'Match le $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Vous avez matche avec $name le $date';
  }

  @override
  String get matches => 'Correspondances';

  @override
  String get matchesClearFilters => 'Effacer les Filtres';

  @override
  String matchesCount(int count) {
    return '$count correspondances';
  }

  @override
  String get matchesFilterAll => 'Tous';

  @override
  String get matchesFilterMessaged => 'Avec Messages';

  @override
  String get matchesFilterNew => 'Nouveaux';

  @override
  String get matchesNoMatchesFound => 'Aucun match trouve';

  @override
  String get matchesNoMatchesYet => 'Pas encore de matchs';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered sur $total matchs';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered sur $total correspondances';
  }

  @override
  String get matchesStartSwiping =>
      'Commencez a swiper pour trouver vos matchs !';

  @override
  String get matchesTryDifferent => 'Essayez une autre recherche ou filtre';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Maximum $count centres d\'intérêt autorisés';
  }

  @override
  String get maybeLater => 'Peut-être plus tard';

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
  String get membershipDailyLikes => 'Likes quotidiens';

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
  String get membershipExtendTitle => 'Prolonger votre abonnement';

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
  String get membershipRewinds => 'Retours en arrière';

  @override
  String membershipSavePercent(Object percent) {
    return 'ÉCONOMISEZ $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Voir qui vous aime';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Achetez une fois, profitez des fonctionnalités premium pendant 1 mois ou 1 an';

  @override
  String get membershipSuperLikes => 'Super Likes';

  @override
  String get membershipSuperLikesLabel => 'Super Likes/jour (vide = illimité)';

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
  String get messages => 'Echanges';

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
  String get noMatchesFound => 'Aucune correspondance trouvée';

  @override
  String get noMatchesYet => 'Pas encore de correspondances';

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
      'Activez les notifications pour être informé de vos matchs, messages et super likes.';

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
  String get notificationMatchExpiring => 'Match expirant';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Quand un match est sur le point d\'expirer';

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
  String get notificationNewLikesSubtitle => 'Quand quelqu\'un vous aime';

  @override
  String notificationNewMatch(String nickname) {
    return 'C\'est un Match ! Vous avez matché avec @$nickname. Commencez à discuter.';
  }

  @override
  String get notificationNewMatches => 'Nouveaux matchs';

  @override
  String get notificationNewMatchesSubtitle =>
      'Quand vous obtenez un nouveau match';

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
  String get notificationSound => 'Son';

  @override
  String get notificationSoundSubtitle => 'Jouer un son pour les notifications';

  @override
  String get notificationSoundVibration => 'Son et vibration';

  @override
  String get notificationStartTime => 'Heure de début';

  @override
  String notificationSuperLike(String nickname) {
    return 'Vous avez reçu un super j\'aime de @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Super Likes';

  @override
  String get notificationSuperLikesSubtitle =>
      'Quand quelqu\'un vous envoie un Super Like';

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
      'Parlez-nous de vos centres d\'intérêt, vos loisirs, ce que vous recherchez...';

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
      'Vos centres d\'intérêt nous aident à trouver de meilleurs matchs pour vous';

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
      'Cette action est permanente et irréversible. Toutes vos données, matchs et messages seront supprimés. Veuillez saisir votre mot de passe pour confirmer.';

  @override
  String get profileDiscoveryRestarted =>
      'Découverte redémarrée ! Vous pouvez à nouveau voir tous les profils.';

  @override
  String get profileDisplayName => 'Nom d\'Affichage';

  @override
  String get profileDobInfo =>
      'Votre date de naissance ne peut pas etre modifiee pour la verification de l\'age. Votre age exact est visible par vos matchs.';

  @override
  String get profileEditBasicInfo => 'Modifier les Infos de Base';

  @override
  String get profileEditLocation => 'Modifier Localisation et Langues';

  @override
  String get profileEditNickname => 'Modifier le Pseudo';

  @override
  String get profileEducation => 'Education';

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
  String get profileLookingForHint => 'ex. Relation a long terme';

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
  String get profileRestart => 'Redémarrer';

  @override
  String get profileRestartDiscovery => 'Redémarrer la découverte';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Cela effacera tous vos swipes (likes, nopes, super likes) pour que vous puissiez redécouvrir tout le monde depuis le début.\n\nVos matchs et chats ne seront PAS affectés.';

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
      'Nous permettre d\'analyser vos préférences pour fournir de meilleures suggestions de correspondance';

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
      'Voir votre parcours de rencontres complet et vos jalons';

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
    return '$remaining $limitType restants aujourd\'hui';
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
  String get romanticCategory => 'Romantique';

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
  String get safetyCheckInDescription =>
      'Programmez un check-in pour votre rendez-vous. Nous vous rappellerons de faire le check-in et alerterons vos contacts si vous ne répondez pas.';

  @override
  String get safetyCheckInEvery => 'Check-in toutes les';

  @override
  String get safetyCheckInScheduled => 'Check-in de rendez-vous programmé !';

  @override
  String get safetyDateCheckIn => 'Check-in de rendez-vous';

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
      'Retrouvez les profils que vous avez refusés mais qui vous ont aimé !';

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
    return 'Vous a aimé $ago';
  }

  @override
  String get secondChanceMatchBody =>
      'Vous vous plaisez mutuellement ! Lancez une conversation.';

  @override
  String get secondChanceMatchTitle => 'C\'est un match !';

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
  String get shopDailyLikes => 'Likes quotidiens';

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
  String get shopPriorityMatching => 'Matching prioritaire';

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
  String get shopSeeWhoLikesYou => 'Voir qui vous aime';

  @override
  String get shopSend => 'Envoyer';

  @override
  String get shopSendCoins => 'Envoyer des pièces';

  @override
  String get shopStoreNotAvailable =>
      'Boutique indisponible. Vérifiez les paramètres de votre appareil.';

  @override
  String get shopSuperLikes => 'Super Likes';

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
      'Débloquez les fonctionnalités premium et améliorez votre expérience de rencontre';

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
  String get shortTermRelationship => 'Relation à court terme';

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
      'Vos profils sociaux seront visibles sur votre profil de rencontres et aideront les autres à vérifier votre identité.';

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
      'Commencez à balayer pour trouver vos correspondances !';

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
  String get superLike => 'Super Like';

  @override
  String superLikedYou(String name) {
    return '$name vous a envoyé un Super Like !';
  }

  @override
  String get superLikes => 'Super J\'aime';

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
      'Faites défiler les profils pour trouver votre match parfait. Glissez à droite si intéressé, à gauche pour passer.';

  @override
  String get tourDiscoveryTitle => 'Découvrez des Matchs';

  @override
  String get tourDone => 'Terminé';

  @override
  String get tourLearnDescription =>
      'Étudie le vocabulaire, la grammaire et les compétences de conversation';

  @override
  String get tourLearnTitle => 'Apprends les Langues';

  @override
  String get tourMatchesDescription =>
      'Voyez tous ceux qui vous ont aussi aimé ! Commencez des conversations avec vos matchs mutuels.';

  @override
  String get tourMatchesTitle => 'Vos Matchs';

  @override
  String get tourMessagesDescription =>
      'Discutez avec vos matchs ici. Envoyez des messages, photos et notes vocales pour vous connecter.';

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
      'Obtenez des pièces et des fonctionnalités premium pour améliorer votre expérience.';

  @override
  String get tourShopTitle => 'Boutique et Pièces';

  @override
  String get tourSkip => 'Passer';

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
    return 'Etes-vous sur de vouloir annuler le match avec $name ? Cette action est irreversible.';
  }

  @override
  String get unmatchLabel => 'Annuler le Match';

  @override
  String unmatchedWith(String name) {
    return 'Unmatché avec $name';
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
  String get waitingCountdownLabel => 'Compte à rebours avant le lancement';

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
  String get waitingExclusiveAccess => 'Votre date d\'accès exclusive';

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
  String get yearlyMembership => 'Adhésion annuelle';

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
  String get youGotSuperLike => 'Vous avez reçu un Super Like !';

  @override
  String get youLabel => 'VOUS';

  @override
  String get youLose => 'Tu as Perdu';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Vous avez matché avec $name le $date';
  }

  @override
  String get youWin => 'Tu as Gagné !';

  @override
  String get yourLanguages => 'Vos Langues';

  @override
  String get yourRankLabel => 'Votre Rang';

  @override
  String get yourTurn => 'À Ton Tour !';
}
