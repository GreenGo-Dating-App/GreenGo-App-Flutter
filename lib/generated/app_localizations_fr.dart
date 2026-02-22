// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Découvrez Votre Partenaire Parfait';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get resetPassword => 'Réinitialiser le Mot de passe';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte?';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithFacebook => 'Continuer avec Facebook';

  @override
  String get orContinueWith => 'Ou continuez avec';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get joinMessage =>
      'Rejoignez GreenGoChat et trouvez votre partenaire parfait';

  @override
  String get emailRequired => 'L\'e-mail est requis';

  @override
  String get emailInvalid => 'Veuillez entrer un e-mail valide';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get passwordWeak =>
      'Le mot de passe doit contenir des majuscules, des minuscules, des chiffres et des caractères spéciaux';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordMustContainUppercase =>
      'Le mot de passe doit contenir au moins une lettre majuscule';

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
  String get passwordStrengthVeryWeak => 'Très Faible';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthFair => 'Moyen';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get passwordStrengthVeryStrong => 'Très Fort';

  @override
  String get passwordMustContain => 'Le mot de passe doit contenir:';

  @override
  String get atLeast8Characters => 'Au moins 8 caractères';

  @override
  String get uppercaseLowercase => 'Lettres majuscules et minuscules';

  @override
  String get atLeastOneNumber => 'Au moins un chiffre';

  @override
  String get atLeastOneSpecialChar => 'Au moins un caractère spécial';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get completeProfile => 'Complétez Votre Profil';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get dateOfBirth => 'Date de Naissance';

  @override
  String get gender => 'Genre';

  @override
  String get bio => 'Biographie';

  @override
  String get interests => 'Centres d\'intérêt';

  @override
  String get photos => 'Photos';

  @override
  String get addPhoto => 'Ajouter une Photo';

  @override
  String get uploadPhoto => 'Télécharger une Photo';

  @override
  String get takePhoto => 'Prendre une Photo';

  @override
  String get chooseFromGallery => 'Choisir dans la Galerie';

  @override
  String get location => 'Localisation';

  @override
  String get language => 'Langue';

  @override
  String get voiceIntro => 'Présentation Vocale';

  @override
  String get recordVoice => 'Enregistrer la Voix';

  @override
  String get welcome => 'Bienvenue sur GreenGoChat';

  @override
  String get getStarted => 'Commencer';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get finish => 'Terminer';

  @override
  String get step => 'Étape';

  @override
  String get stepOf => 'de';

  @override
  String get discover => 'Découvrir';

  @override
  String get matches => 'Correspondances';

  @override
  String get likes => 'J\'aime';

  @override
  String get superLikes => 'Super J\'aime';

  @override
  String get filters => 'Filtres';

  @override
  String get ageRange => 'Tranche d\'Âge';

  @override
  String get distance => 'Distance';

  @override
  String get noMoreProfiles => 'Plus de profils à afficher';

  @override
  String get itsAMatch => 'C\'est un Match!';

  @override
  String youAndMatched(String name) {
    return 'Vous et $name vous êtes aimés mutuellement';
  }

  @override
  String get sendMessage => 'Envoyer un Message';

  @override
  String get keepSwiping => 'Continuer à Balayer';

  @override
  String get messages => 'Messages';

  @override
  String get typeMessage => 'Tapez un message...';

  @override
  String get noMessages => 'Pas encore de messages';

  @override
  String get startConversation => 'Démarrer une conversation';

  @override
  String get settings => 'Paramètres';

  @override
  String get accountSettings => 'Paramètres du Compte';

  @override
  String get notificationSettings => 'Paramètres des Notifications';

  @override
  String get privacySettings => 'Paramètres de Confidentialité';

  @override
  String get deleteAccount => 'Supprimer le Compte';

  @override
  String get logout => 'Se Déconnecter';

  @override
  String get upgradeToPremium => 'Passer à Premium';

  @override
  String get basic => 'Basique';

  @override
  String get silver => 'Argent';

  @override
  String get gold => 'Or';

  @override
  String get subscribe => 'S\'abonner';

  @override
  String get perMonth => '/mois';

  @override
  String get somethingWentWrong => 'Quelque chose s\'est mal passé';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get noInternetConnection => 'Pas de connexion internet';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get done => 'Terminé';

  @override
  String get loading => 'Chargement...';

  @override
  String get ok => 'OK';

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get loginWithBiometrics => 'Connexion avec Biométrie';

  @override
  String get consentRequired => 'Consentements Obligatoires';

  @override
  String get optionalConsents => 'Consentements Optionnels';

  @override
  String get acceptPrivacyPolicy =>
      'J\'ai lu et j\'accepte la Politique de Confidentialité';

  @override
  String get acceptTermsAndConditions =>
      'J\'ai lu et j\'accepte les Conditions Générales';

  @override
  String get acceptProfiling =>
      'Je consens au profilage pour des recommandations personnalisées';

  @override
  String get acceptThirdPartyData =>
      'Je consens au partage de mes données avec des tiers';

  @override
  String get readPrivacyPolicy => 'Lire la Politique de Confidentialité';

  @override
  String get readTermsAndConditions => 'Lire les Conditions Générales';

  @override
  String get profilingDescription =>
      'Nous permettre d\'analyser vos préférences pour fournir de meilleures suggestions de correspondance';

  @override
  String get thirdPartyDataDescription =>
      'Permettre le partage de données anonymisées avec des partenaires pour l\'amélioration du service';

  @override
  String get consentRequiredError =>
      'Vous devez accepter la Politique de Confidentialité et les Conditions Générales pour vous inscrire';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get termsAndConditions => 'Conditions Générales';

  @override
  String get errorLoadingDocument => 'Error loading document';

  @override
  String get retry => 'Retry';

  @override
  String get documentNotAvailable => 'Document not available';

  @override
  String get documentNotAvailableDescription =>
      'This document is not available in your language yet.';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get verificationRequired => 'Vérification d\'Identité Requise';

  @override
  String get verificationTitle => 'Vérifiez Votre Identité';

  @override
  String get verificationDescription =>
      'Pour assurer la sécurité de notre communauté, nous demandons à tous les utilisateurs de vérifier leur identité. Prenez une photo de vous tenant votre pièce d\'identité.';

  @override
  String get verificationInstructions =>
      'Tenez votre pièce d\'identité (passeport, permis de conduire ou carte d\'identité) à côté de votre visage et prenez une photo claire.';

  @override
  String get verificationTips => 'Conseils pour une vérification réussie:';

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
  String get takeVerificationPhoto => 'Prendre Photo de Vérification';

  @override
  String get retakePhoto => 'Reprendre la Photo';

  @override
  String get submitVerification => 'Soumettre pour Vérification';

  @override
  String get verificationPending => 'Vérification en Cours';

  @override
  String get verificationPendingMessage =>
      'Votre compte est en cours de vérification. Cela prend généralement 24-48 heures. Vous serez notifié une fois la révision terminée.';

  @override
  String get verificationApproved => 'Vérification Approuvée';

  @override
  String get verificationApprovedMessage =>
      'Votre identité a été vérifiée. Vous avez maintenant un accès complet à l\'application.';

  @override
  String get verificationRejected => 'Vérification Refusée';

  @override
  String get verificationRejectedMessage =>
      'Votre vérification a été refusée. Veuillez soumettre une nouvelle photo.';

  @override
  String get verificationNeedsResubmission => 'Meilleure Photo Requise';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Nous avons besoin d\'une photo plus claire pour la vérification. Veuillez renvoyer.';

  @override
  String rejectionReason(String reason) {
    return 'Raison: $reason';
  }

  @override
  String get accountUnderReview => 'Compte en Révision';

  @override
  String get cannotAccessFeature =>
      'Cette fonctionnalité est disponible après la vérification de votre compte.';

  @override
  String get waitingForVerification => 'En attente de vérification...';

  @override
  String get verifyNow => 'Vérifier Maintenant';

  @override
  String get skipForNow => 'Passer pour l\'Instant';

  @override
  String get verificationSkipWarning =>
      'Vous pouvez parcourir l\'application, mais vous ne pourrez pas discuter ou voir d\'autres profils tant que vous n\'êtes pas vérifié.';

  @override
  String get adminPanel => 'Panneau Admin';

  @override
  String get pendingVerifications => 'Vérifications en Attente';

  @override
  String get verificationHistory => 'Historique des Vérifications';

  @override
  String get approveVerification => 'Approuver';

  @override
  String get rejectVerification => 'Refuser';

  @override
  String get requestBetterPhoto => 'Demander Meilleure Photo';

  @override
  String get enterRejectionReason => 'Entrez la raison du refus';

  @override
  String get rejectionReasonRequired =>
      'Veuillez entrer une raison pour le refus';

  @override
  String get verificationApprovedSuccess =>
      'Vérification approuvée avec succès';

  @override
  String get verificationRejectedSuccess => 'Vérification refusée';

  @override
  String get betterPhotoRequested => 'Meilleure photo demandée';

  @override
  String get noPhotoSubmitted => 'Aucune photo soumise';

  @override
  String submittedOn(String date) {
    return 'Soumis le $date';
  }

  @override
  String reviewedBy(String admin) {
    return 'Révisé par $admin';
  }

  @override
  String get noPendingVerifications => 'Aucune vérification en attente';

  @override
  String get platinum => 'Platine';

  @override
  String get waitingTitle => 'Merci de Vous Être Inscrit!';

  @override
  String get waitingSubtitle => 'Votre compte a été créé avec succès';

  @override
  String get waitingMessagePending =>
      'Votre compte est en attente d\'approbation par notre équipe. Nous vous informerons une fois que votre compte aura été examiné.';

  @override
  String get waitingMessageApproved =>
      'Bonne nouvelle! Votre compte a été approuvé. Vous pourrez accéder à GreenGoChat à la date indiquée ci-dessous.';

  @override
  String get waitingMessageRejected =>
      'Malheureusement, votre compte n\'a pas pu être approuvé pour le moment. Veuillez contacter le support pour plus d\'informations.';

  @override
  String get waitingAccessDateTitle => 'Votre Date d\'Accès';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'En tant que membre $tier, vous bénéficiez d\'un accès anticipé le 1er mars 2026!';
  }

  @override
  String get waitingAccessDateBasic => 'Votre accès commencera le 15 mars 2026';

  @override
  String get waitingCountdownTitle => 'Compte à Rebours jusqu\'au Lancement';

  @override
  String waitingDaysRemaining(int days) {
    return '$days jours';
  }

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours heures';
  }

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutes';
  }

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds secondes';
  }

  @override
  String get accountPendingApproval => 'Compte en Attente d\'Approbation';

  @override
  String get accountApproved => 'Compte Approuvé';

  @override
  String get accountRejected => 'Compte Refusé';

  @override
  String get upgradeForEarlyAccess =>
      'Passez à Argent, Or ou Platine pour un accès anticipé le 1er mars 2026!';

  @override
  String get waitingStayTuned =>
      'Restez à l\'écoute! Nous vous informerons quand il sera temps de commencer à vous connecter.';

  @override
  String get waitingNotificationEnabled =>
      'Notifications activées - nous vous préviendrons quand vous pourrez accéder à l\'application!';

  @override
  String get enableNotifications => 'Activer les Notifications';

  @override
  String get contactSupport => 'Contacter le Support';

  @override
  String get waitingCountdownSubtitle =>
      'Merci de vous être inscrit ! GreenGo Chat sera lancé bientôt. Préparez-vous pour une expérience exclusive.';

  @override
  String get waitingCountdownLabel => 'Compte à rebours avant le lancement';

  @override
  String get waitingEarlyAccessMember => 'Membre Accès Anticipé';

  @override
  String get waitingExclusiveAccess => 'Votre date d\'accès exclusive';

  @override
  String get waitingProfileUnderReview => 'Profil en cours d\'examen';

  @override
  String get waitingReviewMessage =>
      'L\'application est maintenant en ligne ! Notre équipe examine votre profil pour garantir la meilleure expérience pour notre communauté. Cela prend généralement 24 à 48 heures.';

  @override
  String get waitingStepRegistration => 'Inscription terminée';

  @override
  String get waitingStepReview => 'Examen du profil en cours';

  @override
  String get waitingStepActivation => 'Activation du compte';

  @override
  String get waitingEnableNotificationsTitle => 'Restez informé';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Activez les notifications pour être le premier à savoir quand vous pouvez accéder à l\'application.';

  @override
  String get waitingThankYouRegistration => 'Merci de vous être inscrit !';

  @override
  String get days => 'Jours';

  @override
  String get hours => 'Heures';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Secondes';

  @override
  String get vipPlatinumMember => 'PLATINE VIP';

  @override
  String get vipGoldMember => 'MEMBRE OR';

  @override
  String get vipSilverMember => 'MEMBRE ARGENT';

  @override
  String get vipPremiumBenefitsActive => 'Avantages Premium Actifs';

  @override
  String get authErrorUserNotFound =>
      'Aucun compte trouvé avec cet e-mail ou pseudo. Vérifiez et réessayez, ou inscrivez-vous.';

  @override
  String get authErrorWrongPassword =>
      'Mot de passe incorrect. Veuillez réessayer.';

  @override
  String get authErrorInvalidEmail =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Un compte existe déjà avec cet e-mail.';

  @override
  String get authErrorWeakPassword =>
      'Le mot de passe est trop faible. Veuillez utiliser un mot de passe plus fort.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get authErrorNetworkError =>
      'Pas de connexion internet. Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorGeneric => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail/pseudo ou mot de passe incorrect. Vérifiez vos identifiants et réessayez.';

  @override
  String get connectionErrorTitle => 'Pas de Connexion Internet';

  @override
  String get connectionErrorMessage =>
      'Vérifiez votre connexion internet et réessayez.';

  @override
  String get serverUnavailableTitle => 'Serveur Indisponible';

  @override
  String get serverUnavailableMessage =>
      'Nos serveurs sont temporairement indisponibles. Veuillez réessayer dans quelques instants.';

  @override
  String get authenticationErrorTitle => 'Échec de Connexion';

  @override
  String get dismiss => 'Fermer';

  @override
  String get accountCreatedSuccess =>
      'Compte créé ! Veuillez vérifier votre e-mail pour valider votre compte.';

  @override
  String get levelUp => 'NIVEAU SUPÉRIEUR !';

  @override
  String get levelUpCongratulations =>
      'Félicitations pour avoir atteint un nouveau niveau !';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Vous avez atteint le Niveau $level';
  }

  @override
  String get levelUpRewards => 'RÉCOMPENSES';

  @override
  String get levelUpContinue => 'Continuer';

  @override
  String get levelUpVIPUnlocked => 'Statut VIP Débloqué !';

  @override
  String get chatSafetyTitle => 'Chattez en Toute Sécurité';

  @override
  String get chatSafetySubtitle =>
      'Votre sécurité est notre priorité. Gardez ces conseils à l\'esprit.';

  @override
  String get chatSafetyTip1Title => 'Gardez Vos Infos Personnelles Privées';

  @override
  String get chatSafetyTip1Description =>
      'Ne partagez pas votre adresse, numéro de téléphone ou informations financières.';

  @override
  String get chatSafetyTip2Title => 'Méfiez-vous des Demandes d\'Argent';

  @override
  String get chatSafetyTip2Description =>
      'N\'envoyez jamais d\'argent à quelqu\'un que vous n\'avez pas rencontré en personne.';

  @override
  String get chatSafetyTip3Title => 'Rencontrez dans des Lieux Publics';

  @override
  String get chatSafetyTip3Description =>
      'Pour les premiers rendez-vous, choisissez toujours un lieu public et bien éclairé.';

  @override
  String get chatSafetyTip4Title => 'Faites Confiance à Votre Instinct';

  @override
  String get chatSafetyTip4Description =>
      'Si quelque chose ne va pas, faites confiance à votre instinct et terminez la conversation.';

  @override
  String get chatSafetyTip5Title => 'Signalez les Comportements Suspects';

  @override
  String get chatSafetyTip5Description =>
      'Utilisez la fonction de signalement si quelqu\'un vous met mal à l\'aise.';

  @override
  String get chatSafetyGotIt => 'Compris';

  @override
  String get tourSkip => 'Passer';

  @override
  String get tourNext => 'Suivant';

  @override
  String get tourDone => 'Terminé';

  @override
  String get tourDiscoveryTitle => 'Découvrez des Matchs';

  @override
  String get tourDiscoveryDescription =>
      'Faites défiler les profils pour trouver votre match parfait. Glissez à droite si intéressé, à gauche pour passer.';

  @override
  String get tourMatchesTitle => 'Vos Matchs';

  @override
  String get tourMatchesDescription =>
      'Voyez tous ceux qui vous ont aussi aimé ! Commencez des conversations avec vos matchs mutuels.';

  @override
  String get tourMessagesTitle => 'Messages';

  @override
  String get tourMessagesDescription =>
      'Discutez avec vos matchs ici. Envoyez des messages, photos et notes vocales pour vous connecter.';

  @override
  String get tourShopTitle => 'Boutique et Pièces';

  @override
  String get tourShopDescription =>
      'Obtenez des pièces et des fonctionnalités premium pour améliorer votre expérience.';

  @override
  String get tourProgressTitle => 'Suivez Vos Progrès';

  @override
  String get tourProgressDescription =>
      'Gagnez des badges, complétez des défis et montez dans le classement !';

  @override
  String get tourProfileTitle => 'Votre Profil';

  @override
  String get tourProfileDescription =>
      'Personnalisez votre profil, gérez les paramètres et contrôlez votre vie privée.';

  @override
  String get progressTitle => 'Progrès';

  @override
  String get progressOverview => 'Aperçu';

  @override
  String get progressAchievements => 'Badges';

  @override
  String get progressChallenges => 'Défis';

  @override
  String get progressLeaderboard => 'Classement';

  @override
  String progressLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String get progressBadges => 'Badges';

  @override
  String get progressCompleted => 'Complétés';

  @override
  String get progressTotalXP => 'XP Total';

  @override
  String get progressRecentAchievements => 'Succès Récents';

  @override
  String get progressTodaysChallenges => 'Défis du Jour';

  @override
  String get progressSeeAll => 'Voir Tout';

  @override
  String get progressViewJourney => 'Voir Votre Parcours';

  @override
  String get progressJourneyDescription =>
      'Voir votre parcours de rencontres complet et vos jalons';

  @override
  String get nickname => 'Pseudo';

  @override
  String get editNickname => 'Modifier le Pseudo';

  @override
  String get nicknameUpdatedSuccess => 'Pseudo mis à jour avec succès';

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
  String get enterNickname => 'Entrez le pseudo';

  @override
  String get nicknameRequirements =>
      '3-20 caractères. Lettres, chiffres et underscores uniquement.';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get refresh => 'Actualiser';

  @override
  String get nicknameRules => 'Règles du Pseudo';

  @override
  String get nicknameMustBe3To20Chars => 'Doit contenir 3-20 caractères';

  @override
  String get nicknameStartWithLetter => 'Commencer par une lettre';

  @override
  String get nicknameOnlyAlphanumeric =>
      'Lettres, chiffres et underscores uniquement';

  @override
  String get nicknameNoConsecutiveUnderscores =>
      'Pas d\'underscores consécutifs';

  @override
  String get nicknameNoReservedWords => 'Ne peut pas contenir de mots réservés';

  @override
  String get setYourUniqueNickname => 'Définissez votre pseudo unique';

  @override
  String get searchByNickname => 'Rechercher par Pseudo';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'Aucun profil trouvé avec @$nickname';
  }

  @override
  String get thatsYourOwnProfile => 'C\'est votre propre profil !';

  @override
  String get errorSearchingTryAgain => 'Erreur de recherche. Réessayez.';

  @override
  String get enterNicknameToFind =>
      'Entrez un pseudo pour trouver quelqu\'un directement';

  @override
  String get view => 'Voir';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès';

  @override
  String get unableToLoadProfile => 'Impossible de charger le profil';

  @override
  String get viewMyProfile => 'Voir Mon Profil';

  @override
  String get seeHowOthersViewProfile =>
      'Voyez comment les autres voient votre profil';

  @override
  String photosCount(int count) {
    return '$count/6 photos';
  }

  @override
  String get basicInformation => 'Informations de Base';

  @override
  String get aboutMe => 'À Propos de Moi';

  @override
  String get addBio => 'Ajouter une biographie';

  @override
  String interestsCount(int count) {
    return '$count centres d\'intérêt';
  }

  @override
  String get locationAndLanguages => 'Localisation et Langues';

  @override
  String get voiceRecorded => 'Voix enregistrée';

  @override
  String get noVoiceRecording => 'Pas d\'enregistrement vocal';

  @override
  String get socialProfiles => 'Profils Sociaux';

  @override
  String get noSocialProfilesLinked => 'Aucun profil social lié';

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
  String get appLanguage => 'Langue de l\'App';

  @override
  String get rewardsAndProgress => 'Récompenses et Progrès';

  @override
  String get myProgress => 'Mes Progrès';

  @override
  String get viewBadgesAchievementsLevel => 'Voir badges, succès et niveau';

  @override
  String get admin => 'Admin';

  @override
  String get verificationPanel => 'Panneau de Vérification';

  @override
  String get reviewUserVerifications => 'Examiner les vérifications';

  @override
  String get reportsPanel => 'Panneau des Signalements';

  @override
  String get reviewReportedMessages =>
      'Examiner les messages signalés et gérer les comptes';

  @override
  String get membershipPanel => 'Panneau des Abonnements';

  @override
  String get manageCouponsTiersRules => 'Gérer coupons, niveaux et règles';

  @override
  String get exportMyDataGDPR => 'Exporter Mes Données (RGPD)';

  @override
  String get restartAppWizard => 'Redémarrer l\'Assistant de l\'App';

  @override
  String languageChangedTo(String language) {
    return 'Langue changée en $language';
  }

  @override
  String get deleteAccountConfirmation =>
      'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront définitivement supprimées.';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Les comptes admin ne peuvent pas être supprimés';

  @override
  String get exportingYourData => 'Exportation de vos données...';

  @override
  String get dataExportSentToEmail => 'Export de données envoyé à votre email';

  @override
  String get restartWizardDialogContent =>
      'Cela redémarrera l\'assistant de configuration. Vous pourrez mettre à jour les informations de votre profil étape par étape. Vos données actuelles seront préservées.';

  @override
  String get restartWizard => 'Redémarrer l\'Assistant';

  @override
  String get logOutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get editVoiceComingSoon => 'Modifier la voix bientôt disponible';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get noMatchesYet => 'Pas encore de correspondances';

  @override
  String get startSwipingToFindMatches =>
      'Commencez à balayer pour trouver vos correspondances !';

  @override
  String get searchByNameOrNickname => 'Rechercher par nom ou @pseudo';

  @override
  String matchesCount(int count) {
    return '$count correspondances';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered sur $total correspondances';
  }

  @override
  String get noMatchesFound => 'Aucune correspondance trouvée';

  @override
  String get tryDifferentSearchOrFilter =>
      'Essayez une recherche ou un filtre différent';

  @override
  String get clearFilters => 'Effacer les Filtres';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterNew => 'Nouveaux';

  @override
  String get filterMessaged => 'Avec Messages';

  @override
  String get about => 'À propos';

  @override
  String get lookingFor => 'Recherche';

  @override
  String get details => 'Détails';

  @override
  String get height => 'Taille';

  @override
  String get education => 'Éducation';

  @override
  String get occupation => 'Profession';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Vous avez matché avec $name le $date';
  }

  @override
  String chatWithName(String name) {
    return 'Discuter avec $name';
  }

  @override
  String get longTermRelationship => 'Relation à long terme';

  @override
  String get shortTermRelationship => 'Relation à court terme';

  @override
  String get friendship => 'Amitié';

  @override
  String get casualDating => 'Rencontres occasionnelles';

  @override
  String get today => 'aujourd\'hui';

  @override
  String get yesterday => 'hier';

  @override
  String daysAgo(int count) {
    return 'il y a $count jours';
  }

  @override
  String get lvl => 'NIV';

  @override
  String get xp => 'XP';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% au Niveau $level';
  }

  @override
  String get achievements => 'Succès';

  @override
  String get badges => 'Badges';

  @override
  String get challenges => 'Défis';

  @override
  String get myBadges => 'Mes Badges';

  @override
  String get noBadgesEarnedYet => 'Aucun badge gagné';

  @override
  String get completeAchievementsToEarnBadges =>
      'Complétez des succès pour gagner des badges !';

  @override
  String moreAchievements(int count) {
    return '+$count autres succès';
  }

  @override
  String get levelTitleLegend => 'Légende';

  @override
  String get levelTitleMaster => 'Maître';

  @override
  String get levelTitleExpert => 'Expert';

  @override
  String get levelTitleVeteran => 'Vétéran';

  @override
  String get levelTitleExplorer => 'Explorateur';

  @override
  String get levelTitleEnthusiast => 'Enthousiaste';

  @override
  String get levelTitleNewcomer => 'Débutant';

  @override
  String notificationNewLike(String nickname) {
    return 'Vous avez reçu un j\'aime de @$nickname';
  }

  @override
  String notificationSuperLike(String nickname) {
    return 'Vous avez reçu un super j\'aime de @$nickname';
  }

  @override
  String notificationNewMatch(String nickname) {
    return 'C\'est un Match ! Vous avez matché avec @$nickname. Commencez à discuter.';
  }

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname a commencé une conversation avec vous.';
  }

  @override
  String notificationNewMessage(String nickname) {
    return 'Nouveau message de @$nickname';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Vous avez acheté $amount pièces avec succès.';
  }

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Succès Débloqué : $name';
  }

  @override
  String get voiceStandOutWithYourVoice => 'Démarquez-vous avec votre voix !';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Enregistrez une courte présentation de $seconds secondes pour faire entendre votre personnalité.';
  }

  @override
  String get voiceRecordingTips => 'Conseils d\'Enregistrement';

  @override
  String get voiceTipFindQuietPlace => 'Trouvez un endroit calme';

  @override
  String get voiceTipBeYourself => 'Soyez vous-même et naturel';

  @override
  String get voiceTipShareWhatMakesYouUnique =>
      'Partagez ce qui vous rend unique';

  @override
  String get voiceTipKeepItShort => 'Restez bref et concis';

  @override
  String get voiceTapToRecord => 'Appuyez pour enregistrer';

  @override
  String get voiceRecordingSaved => 'Enregistrement sauvegardé';

  @override
  String get voiceRecordAgain => 'Réenregistrer';

  @override
  String get voiceUploading => 'Téléversement...';

  @override
  String get voiceIntroSaved => 'Présentation vocale sauvegardée';

  @override
  String get voiceUploadFailed =>
      'Échec du téléversement de l\'enregistrement vocal';

  @override
  String get voiceDeleteRecording => 'Supprimer l\'Enregistrement';

  @override
  String get voiceDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer votre présentation vocale ?';

  @override
  String get voiceMicrophonePermissionRequired =>
      'L\'autorisation du microphone est requise';

  @override
  String get listenMe => 'Écoute-moi !';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordDescription =>
      'Pour des raisons de sécurité, veuillez vérifier votre identité avant de changer votre mot de passe.';

  @override
  String get changePasswordCurrent => 'Mot de passe actuel';

  @override
  String get changePasswordNew => 'Nouveau mot de passe';

  @override
  String get changePasswordConfirm => 'Confirmer le nouveau mot de passe';

  @override
  String get changePasswordEmailHint => 'Votre e-mail';

  @override
  String get changePasswordEmailConfirm => 'Confirmez votre adresse e-mail';

  @override
  String get changePasswordEmailMismatch =>
      'L\'e-mail ne correspond pas à votre compte';

  @override
  String get changePasswordSuccess => 'Mot de passe changé avec succès';

  @override
  String get changePasswordWrongCurrent =>
      'Le mot de passe actuel est incorrect';

  @override
  String get changePasswordReauthRequired =>
      'Veuillez vous déconnecter et vous reconnecter avant de changer votre mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Mettre à jour le mot de passe de votre compte';

  @override
  String get shop => 'Boutique';

  @override
  String get progress => 'Progrès';

  @override
  String get learn => 'Apprendre';

  @override
  String get exitApp => 'Quitter l\'App ?';

  @override
  String get exitAppConfirmation =>
      'Êtes-vous sûr de vouloir quitter GreenGo ?';

  @override
  String get exit => 'Quitter';

  @override
  String get letsChat => 'Discutons !';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get helpAndSupport => 'Aide et Support';

  @override
  String get supportCenter => 'Centre d\'Aide';

  @override
  String get supportCenterSubtitle =>
      'Obtenir de l\'aide, signaler des problèmes, nous contacter';

  @override
  String get editInterests => 'Modifier les Intérêts';

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max centres d\'intérêt sélectionnés';
  }

  @override
  String selectAtLeastInterests(int count) {
    return 'Sélectionnez au moins $count centres d\'intérêt';
  }

  @override
  String get greatInterestsHelp =>
      'Super ! Vos intérêts nous aident à trouver de meilleures correspondances';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Maximum $count centres d\'intérêt autorisés';
  }

  @override
  String get connectSocialAccounts => 'Connectez vos comptes sociaux';

  @override
  String get helpOthersFindYou =>
      'Aidez les autres à vous trouver sur les réseaux sociaux';

  @override
  String get socialProfilesTip =>
      'Vos profils sociaux seront visibles sur votre profil de rencontres et aideront les autres à vérifier votre identité.';

  @override
  String get usernameOrProfileUrl => 'Nom d\'utilisateur ou URL du profil';

  @override
  String get usernameWithoutAt => 'Nom d\'utilisateur (sans @)';

  @override
  String get voiceIntroduction => 'Présentation Vocale';

  @override
  String get interestTravel => 'Voyages';

  @override
  String get interestPhotography => 'Photographie';

  @override
  String get interestMusic => 'Musique';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestCooking => 'Cuisine';

  @override
  String get interestReading => 'Lecture';

  @override
  String get interestMovies => 'Films';

  @override
  String get interestGaming => 'Jeux vidéo';

  @override
  String get interestArt => 'Art';

  @override
  String get interestDance => 'Danse';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestHiking => 'Randonnée';

  @override
  String get interestSwimming => 'Natation';

  @override
  String get interestCycling => 'Cyclisme';

  @override
  String get interestRunning => 'Course';

  @override
  String get interestSports => 'Sports';

  @override
  String get interestFashion => 'Mode';

  @override
  String get interestTechnology => 'Technologie';

  @override
  String get interestWriting => 'Écriture';

  @override
  String get interestCoffee => 'Café';

  @override
  String get interestWine => 'Vin';

  @override
  String get interestBeer => 'Bière';

  @override
  String get interestFood => 'Nourriture';

  @override
  String get interestVegetarian => 'Végétarien';

  @override
  String get interestVegan => 'Végan';

  @override
  String get interestPets => 'Animaux';

  @override
  String get interestDogs => 'Chiens';

  @override
  String get interestCats => 'Chats';

  @override
  String get interestNature => 'Nature';

  @override
  String get interestBeach => 'Plage';

  @override
  String get interestMountains => 'Montagnes';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSkiing => 'Ski';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestMeditation => 'Méditation';

  @override
  String get interestSpirituality => 'Spiritualité';

  @override
  String get interestVolunteering => 'Bénévolat';

  @override
  String get interestEnvironment => 'Environnement';

  @override
  String get interestPolitics => 'Politique';

  @override
  String get interestScience => 'Science';

  @override
  String get interestHistory => 'Histoire';

  @override
  String get interestLanguages => 'Langues';

  @override
  String get interestTeaching => 'Enseignement';

  @override
  String get xTwitter => 'X (Twitter)';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Message bloqué : Contient $violations. Pour votre sécurité, le partage de coordonnées personnelles n\'est pas autorisé.';
  }

  @override
  String get chatReportMessage => 'Signaler le Message';

  @override
  String get chatWhyReportMessage => 'Pourquoi signalez-vous ce message ?';

  @override
  String get chatReportReasonHarassment => 'Harcèlement ou intimidation';

  @override
  String get chatReportReasonSpam => 'Spam ou arnaque';

  @override
  String get chatReportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get chatReportReasonPersonalInfo =>
      'Partage d\'informations personnelles';

  @override
  String get chatReportReasonThreatening => 'Comportement menaçant';

  @override
  String get chatReportReasonFakeProfile => 'Faux profil / Catfishing';

  @override
  String get chatReportReasonUnderage => 'Utilisateur mineur';

  @override
  String get chatReportReasonOther => 'Autre';

  @override
  String get chatMessageReported =>
      'Message signalé. Nous l\'examinerons sous peu.';

  @override
  String chatFailedToReportMessage(String error) {
    return 'Échec du signalement du message : $error';
  }

  @override
  String get chatSendAttachment => 'Envoyer une Pièce Jointe';

  @override
  String get chatAttachGallery => 'Galerie';

  @override
  String get chatAttachCamera => 'Appareil Photo';

  @override
  String get chatAttachVideo => 'Vidéo';

  @override
  String get chatAttachRecord => 'Enregistrer';

  @override
  String chatFailedToPickImage(String error) {
    return 'Échec de la sélection d\'image : $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Échec de la sélection de vidéo : $error';
  }

  @override
  String chatFailedToUploadImage(String error) {
    return 'Échec du téléversement d\'image : $error';
  }

  @override
  String get chatVideoTooLarge =>
      'Vidéo trop volumineuse. La taille maximale est de 50 Mo.';

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Échec du téléversement de vidéo : $error';
  }

  @override
  String get chatMediaLimitReached => 'Limite de médias atteinte';

  @override
  String chatSayHiTo(String name) {
    return 'Dites bonjour à $name !';
  }

  @override
  String get chatSendMessageToStart =>
      'Envoyez un message pour démarrer la conversation';

  @override
  String get chatTyping => 'en train d\'écrire...';

  @override
  String get chatDisableTranslation => 'Désactiver la traduction';

  @override
  String get chatEnableTranslation => 'Activer la traduction';

  @override
  String get chatTranslationEnabled => 'Traduction activée';

  @override
  String get chatTranslationDisabled => 'Traduction désactivée';

  @override
  String get chatUploading => 'Téléversement...';

  @override
  String get chatOptions => 'Options du Chat';

  @override
  String get chatDeleteForMe => 'Supprimer le chat pour moi';

  @override
  String get chatDeleteForBoth => 'Supprimer le chat pour les deux';

  @override
  String chatBlockUser(String name) {
    return 'Bloquer $name';
  }

  @override
  String chatReportUser(String name) {
    return 'Signaler $name';
  }

  @override
  String get chatDeleteChat => 'Supprimer le Chat';

  @override
  String get chatDeleteChatForMeMessage =>
      'Cela supprimera le chat de votre appareil uniquement. L\'autre personne verra toujours les messages.';

  @override
  String get chatDeleteChatForEveryone => 'Supprimer le Chat pour Tous';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Cela supprimera tous les messages pour vous et $name. Cette action est irréversible.';
  }

  @override
  String get chatDeleteForEveryone => 'Supprimer pour Tous';

  @override
  String get chatBlockUserTitle => 'Bloquer l\'Utilisateur';

  @override
  String chatBlockUserMessage(String name) {
    return 'Êtes-vous sûr de vouloir bloquer $name ? Ils ne pourront plus vous contacter.';
  }

  @override
  String get chatBlock => 'Bloquer';

  @override
  String get chatCannotBlockAdmin =>
      'Vous ne pouvez pas bloquer un administrateur.';

  @override
  String chatUserBlocked(String name) {
    return '$name a été bloqué';
  }

  @override
  String get chatReportUserTitle => 'Signaler l\'Utilisateur';

  @override
  String chatWhyReportUser(String name) {
    return 'Pourquoi signalez-vous $name ?';
  }

  @override
  String get chatCannotReportAdmin =>
      'Vous ne pouvez pas signaler un administrateur.';

  @override
  String get chatUserReported =>
      'Utilisateur signalé. Nous examinerons votre signalement sous peu.';

  @override
  String chatReplyingTo(String name) {
    return 'Réponse à $name';
  }

  @override
  String get chatYou => 'Vous';

  @override
  String get chatUnableToForward => 'Impossible de transférer le message';

  @override
  String get chatSearchByNameOrNickname => 'Rechercher par nom ou @pseudo';

  @override
  String get chatNoMessagesYet => 'Pas encore de messages';

  @override
  String get chatStartSwipingToChat =>
      'Balayez et matchez pour discuter avec des personnes !';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageTranslated => 'Traduit';

  @override
  String get chatMessageStarred => 'Message mis en favori';

  @override
  String get chatMessageUnstarred => 'Message retiré des favoris';

  @override
  String get chatMessageOptions => 'Options du Message';

  @override
  String get chatReply => 'Répondre';

  @override
  String get chatReplyToMessage => 'Répondre à ce message';

  @override
  String get chatForward => 'Transférer';

  @override
  String get chatForwardToChat => 'Transférer vers un autre chat';

  @override
  String get chatStarMessage => 'Mettre en Favori';

  @override
  String get chatUnstarMessage => 'Retirer des Favoris';

  @override
  String get chatAddToStarred => 'Ajouter aux messages favoris';

  @override
  String get chatRemoveFromStarred => 'Retirer des messages favoris';

  @override
  String get chatReportInappropriate => 'Signaler un contenu inapproprié';

  @override
  String get chatVideoPlayer => 'Lecteur Vidéo';

  @override
  String get chatFailedToLoadImage => 'Échec du chargement de l\'image';

  @override
  String get chatLoadingVideo => 'Chargement de la vidéo...';

  @override
  String get chatPreviewVideo => 'Aperçu Vidéo';

  @override
  String get chatPreviewImage => 'Aperçu Image';

  @override
  String get chatAddCaption => 'Ajouter une légende...';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatSupportTitle => 'Support GreenGo';

  @override
  String get chatSupportStatusOpen => 'Ouvert';

  @override
  String get chatSupportStatusPending => 'En attente';

  @override
  String get chatSupportStatusResolved => 'Résolu';

  @override
  String get chatSupportStatusClosed => 'Fermé';

  @override
  String get chatSupportStatusDefault => 'Support';

  @override
  String chatSupportAgent(String name) {
    return 'Agent : $name';
  }

  @override
  String get chatSupportWelcome => 'Bienvenue au Support';

  @override
  String get chatSupportStartMessage =>
      'Envoyez un message pour démarrer la conversation.\nNotre équipe répondra dès que possible.';

  @override
  String get chatSupportTicketStart => 'Début du Ticket';

  @override
  String get chatSupportTicketCreated => 'Ticket Créé';

  @override
  String get chatSupportErrorLoading => 'Erreur de chargement des messages';

  @override
  String chatSupportFailedToSend(String error) {
    return 'Échec de l\'envoi du message : $error';
  }

  @override
  String get chatSupportTicketResolved => 'Ce ticket a été résolu';

  @override
  String get chatSupportReopenTicket =>
      'Besoin d\'aide supplémentaire ? Appuyez pour rouvrir';

  @override
  String get chatSupportTicketReopened =>
      'Ticket rouvert. Vous pouvez maintenant envoyer un message.';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Échec de la réouverture du ticket : $error';
  }

  @override
  String get chatSupportAddCaptionOptional =>
      'Ajouter une légende (optionnel)...';

  @override
  String get chatSupportTypeMessage => 'Tapez votre message...';

  @override
  String get chatSupportAddAttachment => 'Ajouter une Pièce Jointe';

  @override
  String get chatSupportTicketInfo => 'Informations du Ticket';

  @override
  String get chatSupportSubject => 'Sujet';

  @override
  String get chatSupportCategory => 'Catégorie';

  @override
  String get chatSupportStatus => 'Statut';

  @override
  String get chatSupportAgentLabel => 'Agent';

  @override
  String get chatSupportTicketId => 'ID du Ticket';

  @override
  String get chatSupportGeneralSupport => 'Support Général';

  @override
  String get chatSupportGeneral => 'Général';

  @override
  String get chatSupportWaitingAssignment => 'En attente d\'attribution';

  @override
  String get chatSupportClose => 'Fermer';

  @override
  String get chatSupportJustNow => 'À l\'instant';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'il y a ${minutes}min';
  }

  @override
  String chatSupportHoursAgo(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String chatSupportDaysAgo(int days) {
    return 'il y a ${days}j';
  }

  @override
  String get nicknameSearchChat => 'Discuter';

  @override
  String get filterNewMessages => 'Nouveaux';

  @override
  String get filterNotReplied => 'Sans réponse';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Direct';

  @override
  String get publicAlbum => 'Public';

  @override
  String get privateAlbum => 'Privé';

  @override
  String get shareAlbum => 'Partager l\'album';

  @override
  String get revokeAccess => 'Révoquer l\'accès à l\'album';

  @override
  String get albumNotShared => 'Album non partagé';

  @override
  String get grantAlbumAccess => 'Partager mon album';

  @override
  String get albumOption => 'Album';

  @override
  String albumSharedMessage(String username) {
    return '$username a partagé son album avec vous';
  }

  @override
  String albumRevokedMessage(String username) {
    return '$username a révoqué l\'accès à l\'album';
  }

  @override
  String get sendCoins => 'Envoyer des pièces';

  @override
  String get recipientNickname => 'Pseudo du destinataire';

  @override
  String get enterAmount => 'Entrer le montant';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return 'Envoyer $amount pièces à @$nickname ?';
  }

  @override
  String get coinsSent => 'Pièces envoyées avec succès !';

  @override
  String get insufficientCoins => 'Pièces insuffisantes';

  @override
  String get userNotFound => 'Utilisateur non trouvé';

  @override
  String get weight => 'Poids';

  @override
  String get aboutMeTitle => 'À propos de moi';

  @override
  String get travelerBadge => 'Voyageur';

  @override
  String get travelerModeTitle => 'Mode Voyageur';

  @override
  String get travelerModeDescription =>
      'Apparaissez dans le fil de découverte d\'une autre ville pendant 24 heures';

  @override
  String get travelerModeActive => 'Mode voyageur actif';

  @override
  String travelerModeActivated(String city) {
    return 'Mode voyageur activé ! Vous apparaissez à $city pendant 24 heures.';
  }

  @override
  String get travelerModeDeactivated =>
      'Mode voyageur désactivé. Retour à votre emplacement réel.';

  @override
  String get selectTravelLocation => 'Sélectionner le lieu de voyage';

  @override
  String get searchCityPlaceholder => 'Rechercher ville, adresse ou lieu...';

  @override
  String get useCurrentGpsLocation => 'Utiliser ma position GPS actuelle';

  @override
  String get confirmLocation => 'Confirmer l\'emplacement';

  @override
  String get changeLocation => 'Changer l\'emplacement';

  @override
  String get travelerLocationInfo =>
      'Vous apparaîtrez dans les résultats de découverte de cet emplacement pendant 24 heures.';

  @override
  String get searchForCity => 'Rechercher une ville ou utiliser le GPS';

  @override
  String get travelerSearchHint =>
      'Votre profil apparaîtra dans le fil de découverte de cet emplacement pendant 24 heures avec un badge Voyageur.';

  @override
  String get incognitoMode => 'Mode Incognito';

  @override
  String get incognitoModeDescription =>
      'Masquer votre profil de la découverte';

  @override
  String get myUsage => 'Mon Utilisation';

  @override
  String get boostProfile => 'Booster le Profil';

  @override
  String get boostActivated => 'Boost activé pour 30 minutes !';

  @override
  String get superLike => 'Super Like';

  @override
  String get undoSwipe => 'Annuler le Swipe';

  @override
  String freeActionsRemaining(int count) {
    return '$count actions gratuites restantes aujourd\'hui';
  }

  @override
  String coinsRequired(int amount) {
    return '$amount pièces requises';
  }

  @override
  String get tierFree => 'Gratuit';

  @override
  String get dailySwipeLimitReached =>
      'Limite quotidienne de swipes atteinte. Passez à la version supérieure pour plus de swipes !';

  @override
  String get noOthersToSee => 'Il n\'y a personne d\'autre à voir';

  @override
  String get checkBackLater =>
      'Revenez plus tard pour de nouvelles personnes, ou ajustez vos préférences';

  @override
  String get adjustPreferences => 'Ajuster les Préférences';

  @override
  String get noPreviousProfile => 'Aucun profil précédent à revenir';

  @override
  String get cantUndoMatched =>
      'Impossible d\'annuler — vous avez déjà matché !';

  @override
  String showingProfiles(int count) {
    return '$count profils';
  }

  @override
  String seeMoreProfiles(int count) {
    return 'Voir $count de plus';
  }

  @override
  String coinsCost(int amount) {
    return '$amount pièces';
  }

  @override
  String get seeMoreProfilesTitle => 'Voir Plus de Profils';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Débloquez $count profils supplémentaires en grille pour $cost pièces.';
  }

  @override
  String get unlock => 'Débloquer';

  @override
  String get buyCoins => 'Acheter des Pièces';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Vous avez besoin de $amount pièces pour débloquer plus de profils.';
  }

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilité';
  }

  @override
  String get youGotSuperLike => 'Vous avez reçu un Super Like !';

  @override
  String superLikedYou(String name) {
    return '$name vous a envoyé un Super Like !';
  }

  @override
  String get photoValidating => 'Validation de la photo...';

  @override
  String get photoNotAccepted => 'Photo non acceptée';

  @override
  String get photoMainNoFace =>
      'Votre photo principale doit montrer clairement votre visage. Aucun visage n\'a été détecté sur cette photo.';

  @override
  String get photoMainNotForward =>
      'Veuillez utiliser une photo où votre visage est clairement visible et tourné vers l\'avant.';

  @override
  String get photoExplicitNudity =>
      'Cette photo semble contenir de la nudité ou du contenu explicite. Toutes les photos dans l\'application doivent être appropriées et entièrement habillées.';

  @override
  String get photoExplicitContent =>
      'Cette photo peut contenir du contenu inapproprié. Les photos dans l\'application ne doivent pas montrer de nudité, de sous-vêtements ou de contenu explicite.';

  @override
  String get photoTooMuchSkin =>
      'Cette photo montre trop de peau exposée. Veuillez utiliser une photo où vous êtes habillé(e) de manière appropriée.';

  @override
  String get photoNotAllowedPublic =>
      'Cette photo n\'est pas autorisée dans l\'application.';

  @override
  String get photoTooLarge =>
      'La photo est trop volumineuse. La taille maximale est de 10 Mo.';

  @override
  String get photoMustHaveOne =>
      'Vous devez avoir au moins une photo publique avec votre visage visible.';

  @override
  String get photoDeleteMainWarning =>
      'Ceci est votre photo principale. La photo suivante deviendra votre photo principale (elle doit montrer votre visage). Continuer ?';

  @override
  String get photoDeleteConfirm =>
      'Êtes-vous sûr(e) de vouloir supprimer cette photo ?';

  @override
  String get photoMaxPublic => 'Maximum 6 photos publiques autorisées';

  @override
  String get photoMaxPrivate => 'Maximum 6 photos privées autorisées';

  @override
  String get membershipRequired => 'Adhésion requise';

  @override
  String get membershipRequiredDescription =>
      'Vous devez être membre de GreenGo pour effectuer cette action.';

  @override
  String get yearlyMembership => 'Adhésion annuelle';

  @override
  String get subscribeNow => 'S\'abonner maintenant';

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get shopTitle => 'Boutique';

  @override
  String get shopTabCoins => 'Pièces';

  @override
  String get shopTabMembership => 'Adhésion';

  @override
  String get shopTabVideo => 'Vidéo';

  @override
  String get shopUpgradeExperience => 'Améliorez votre expérience';

  @override
  String shopCurrentPlan(String tier) {
    return 'Plan actuel : $tier';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expire le : $date ($days jours restants)';
  }

  @override
  String shopExpired(String date) {
    return 'Expiré : $date';
  }

  @override
  String get shopMonthly => 'Mensuel';

  @override
  String get shopYearly => 'Annuel';

  @override
  String shopSavePercent(String percent) {
    return 'ÉCONOMISEZ $percent%';
  }

  @override
  String get shopUpgradeAndSave =>
      'Améliorez et économisez ! Réduction sur les niveaux supérieurs';

  @override
  String get shopBaseMembership => 'Adhésion de base GreenGo';

  @override
  String get shopYearlyPlan => 'Abonnement annuel';

  @override
  String get shopActive => 'ACTIF';

  @override
  String get shopBaseMembershipDescription =>
      'Nécessaire pour swiper, liker, discuter et interagir avec d\'autres utilisateurs.';

  @override
  String shopValidUntil(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Passer à $tier ($duration)';
  }

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Acheter $tier ($duration)';
  }

  @override
  String get shopOneYear => '1 An';

  @override
  String get shopOneMonth => '1 Mois';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Vous économisez $amount/mois en passant de $tier';
  }

  @override
  String get shopDailyLikes => 'Likes quotidiens';

  @override
  String get shopSuperLikes => 'Super Likes';

  @override
  String get shopBoosts => 'Boosts';

  @override
  String get shopSeeWhoLikesYou => 'Voir qui vous aime';

  @override
  String get shopVipBadge => 'Badge VIP';

  @override
  String get shopPriorityMatching => 'Matching prioritaire';

  @override
  String get shopSendCoins => 'Envoyer des pièces';

  @override
  String get shopRecipientNickname => 'Pseudo du destinataire';

  @override
  String get shopEnterAmount => 'Entrez le montant';

  @override
  String get shopConfirmSend => 'Confirmer l\'envoi';

  @override
  String get shopSend => 'Envoyer';

  @override
  String get shopUserNotFound => 'Utilisateur introuvable';

  @override
  String get shopCannotSendToSelf =>
      'Vous ne pouvez pas vous envoyer des pièces';

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount pièces envoyées à @$nickname';
  }

  @override
  String get shopFailedToSendCoins => 'Échec de l\'envoi des pièces';

  @override
  String get shopEnterBothFields => 'Veuillez entrer le pseudo et le montant';

  @override
  String get shopEnterValidAmount => 'Veuillez entrer un montant valide';

  @override
  String get shopInsufficientCoins => 'Pièces insuffisantes';

  @override
  String get shopYouHave => 'Vous avez';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopUnlockPremium =>
      'Débloquez les fonctionnalités premium et améliorez votre expérience de rencontre';

  @override
  String get shopPopular => 'POPULAIRE';

  @override
  String get shopCoins => 'Pièces';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Acheter $coins pièces pour $price';
  }

  @override
  String get shopComingSoon => 'Bientôt disponible';

  @override
  String get shopVideoCoinsDescription =>
      'Regardez de courtes vidéos pour gagner des pièces gratuites !\nRestez à l\'écoute pour cette fonctionnalité passionnante.';

  @override
  String get shopGetNotified => 'Être notifié';

  @override
  String get shopNotifyMessage =>
      'Nous vous informerons quand les Video-Coins seront disponibles';

  @override
  String get shopStoreNotAvailable =>
      'Boutique indisponible. Vérifiez que Google Play est installé.';

  @override
  String get shopFailedToInitiate => 'Impossible de lancer l\'achat';

  @override
  String get shopUnableToLoadPackages => 'Impossible de charger les paquets';

  @override
  String get shopRetry => 'Réessayer';

  @override
  String get shopCheckInternet =>
      'Vérifiez votre connexion internet\net réessayez.';

  @override
  String shopMembershipActivated(String date) {
    return 'Adhésion GreenGo activée ! +500 pièces bonus. Valable jusqu\'au $date.';
  }

  @override
  String get shopPreviousPurchaseFound =>
      'Achat précédent trouvé. Veuillez réessayer.';
}
