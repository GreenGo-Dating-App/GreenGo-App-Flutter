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
}
