import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('pt', 'BR')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GreenGoChat'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Discover Your Perfect Match'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinMessage.
  ///
  /// In en, this message translates to:
  /// **'Join GreenGoChat and find your perfect match'**
  String get joinMessage;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must contain uppercase, lowercase, number, and special character'**
  String get passwordWeak;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMustContainUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMustContainUppercase;

  /// No description provided for @passwordMustContainLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordMustContainLowercase;

  /// No description provided for @passwordMustContainNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordMustContainNumber;

  /// No description provided for @passwordMustContainSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordMustContainSpecialChar;

  /// No description provided for @passwordStrengthVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very Weak'**
  String get passwordStrengthVeryWeak;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthVeryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very Strong'**
  String get passwordStrengthVeryStrong;

  /// No description provided for @passwordMustContain.
  ///
  /// In en, this message translates to:
  /// **'Password must contain:'**
  String get passwordMustContain;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @uppercaseLowercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase and lowercase letters'**
  String get uppercaseLowercase;

  /// No description provided for @atLeastOneNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number'**
  String get atLeastOneNumber;

  /// No description provided for @atLeastOneSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'At least one special character'**
  String get atLeastOneSpecialChar;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfile;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @voiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Voice Introduction'**
  String get voiceIntro;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record Voice'**
  String get recordVoice;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GreenGoChat'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get stepOf;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @superLikes.
  ///
  /// In en, this message translates to:
  /// **'Super Likes'**
  String get superLikes;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get ageRange;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @noMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'No more profiles to show'**
  String get noMoreProfiles;

  /// No description provided for @itsAMatch.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match!'**
  String get itsAMatch;

  /// No description provided for @youAndMatched.
  ///
  /// In en, this message translates to:
  /// **'You and {name} liked each other'**
  String youAndMatched(String name);

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @keepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get keepSwiping;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @loginWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometrics'**
  String get loginWithBiometrics;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Required Consents'**
  String get consentRequired;

  /// No description provided for @optionalConsents.
  ///
  /// In en, this message translates to:
  /// **'Optional Consents'**
  String get optionalConsents;

  /// No description provided for @acceptPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Privacy Policy'**
  String get acceptPrivacyPolicy;

  /// No description provided for @acceptTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Terms and Conditions'**
  String get acceptTermsAndConditions;

  /// No description provided for @acceptProfiling.
  ///
  /// In en, this message translates to:
  /// **'I consent to profiling for personalized recommendations'**
  String get acceptProfiling;

  /// No description provided for @acceptThirdPartyData.
  ///
  /// In en, this message translates to:
  /// **'I consent to sharing my data with third parties'**
  String get acceptThirdPartyData;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read Privacy Policy'**
  String get readPrivacyPolicy;

  /// No description provided for @readTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Read Terms and Conditions'**
  String get readTermsAndConditions;

  /// No description provided for @profilingDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow us to analyze your preferences to provide better match suggestions'**
  String get profilingDescription;

  /// No description provided for @thirdPartyDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow sharing anonymized data with partners for service improvement'**
  String get thirdPartyDataDescription;

  /// No description provided for @consentRequiredError.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Privacy Policy and Terms and Conditions to register'**
  String get consentRequiredError;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @errorLoadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error loading document'**
  String get errorLoadingDocument;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @documentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Document not available'**
  String get documentNotAvailable;

  /// No description provided for @documentNotAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'This document is not available in your language yet.'**
  String get documentNotAvailableDescription;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification Required'**
  String get verificationRequired;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Identity'**
  String get verificationTitle;

  /// No description provided for @verificationDescription.
  ///
  /// In en, this message translates to:
  /// **'To ensure the safety of our community, we require all users to verify their identity. Please take a photo of yourself holding your ID document.'**
  String get verificationDescription;

  /// No description provided for @verificationInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please hold your ID document (passport, driver\'s license, or national ID) next to your face and take a clear photo.'**
  String get verificationInstructions;

  /// No description provided for @verificationTips.
  ///
  /// In en, this message translates to:
  /// **'Tips for a successful verification:'**
  String get verificationTips;

  /// No description provided for @verificationTip1.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get verificationTip1;

  /// No description provided for @verificationTip2.
  ///
  /// In en, this message translates to:
  /// **'Make sure your face and ID are clearly visible'**
  String get verificationTip2;

  /// No description provided for @verificationTip3.
  ///
  /// In en, this message translates to:
  /// **'Hold the ID next to your face, not covering it'**
  String get verificationTip3;

  /// No description provided for @verificationTip4.
  ///
  /// In en, this message translates to:
  /// **'All text on the ID should be readable'**
  String get verificationTip4;

  /// No description provided for @takeVerificationPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Verification Photo'**
  String get takeVerificationPhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @submitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitVerification;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @verificationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is being verified. This usually takes 24-48 hours. You will be notified once the review is complete.'**
  String get verificationPendingMessage;

  /// No description provided for @verificationApproved.
  ///
  /// In en, this message translates to:
  /// **'Verification Approved'**
  String get verificationApproved;

  /// No description provided for @verificationApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been verified. You now have full access to the app.'**
  String get verificationApprovedMessage;

  /// No description provided for @verificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationRejected;

  /// No description provided for @verificationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification was rejected. Please submit a new photo.'**
  String get verificationRejectedMessage;

  /// No description provided for @verificationNeedsResubmission.
  ///
  /// In en, this message translates to:
  /// **'Better Photo Required'**
  String get verificationNeedsResubmission;

  /// No description provided for @verificationNeedsResubmissionMessage.
  ///
  /// In en, this message translates to:
  /// **'We need a clearer photo for verification. Please resubmit.'**
  String get verificationNeedsResubmissionMessage;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String rejectionReason(String reason);

  /// No description provided for @accountUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Account Under Review'**
  String get accountUnderReview;

  /// No description provided for @cannotAccessFeature.
  ///
  /// In en, this message translates to:
  /// **'This feature is available after your account is verified.'**
  String get cannotAccessFeature;

  /// No description provided for @waitingForVerification.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification...'**
  String get waitingForVerification;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// No description provided for @verificationSkipWarning.
  ///
  /// In en, this message translates to:
  /// **'You can browse the app, but you won\'t be able to chat or see other profiles until verified.'**
  String get verificationSkipWarning;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @pendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'Pending Verifications'**
  String get pendingVerifications;

  /// No description provided for @verificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Verification History'**
  String get verificationHistory;

  /// No description provided for @approveVerification.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveVerification;

  /// No description provided for @rejectVerification.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectVerification;

  /// No description provided for @requestBetterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Request Better Photo'**
  String get requestBetterPhoto;

  /// No description provided for @enterRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Enter rejection reason'**
  String get enterRejectionReason;

  /// No description provided for @rejectionReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for rejection'**
  String get rejectionReasonRequired;

  /// No description provided for @verificationApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification approved successfully'**
  String get verificationApprovedSuccess;

  /// No description provided for @verificationRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get verificationRejectedSuccess;

  /// No description provided for @betterPhotoRequested.
  ///
  /// In en, this message translates to:
  /// **'Better photo requested'**
  String get betterPhotoRequested;

  /// No description provided for @noPhotoSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No photo submitted'**
  String get noPhotoSubmitted;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String submittedOn(String date);

  /// No description provided for @reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {admin}'**
  String reviewedBy(String admin);

  /// No description provided for @noPendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'No pending verifications'**
  String get noPendingVerifications;

  /// No description provided for @platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinum;

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank You for Registering!'**
  String get waitingTitle;

  /// No description provided for @waitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully'**
  String get waitingSubtitle;

  /// No description provided for @waitingMessagePending.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending approval from our team. We will notify you once your account has been reviewed.'**
  String get waitingMessagePending;

  /// No description provided for @waitingMessageApproved.
  ///
  /// In en, this message translates to:
  /// **'Great news! Your account has been approved. You will be able to access GreenGoChat on the date shown below.'**
  String get waitingMessageApproved;

  /// No description provided for @waitingMessageRejected.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your account could not be approved at this time. Please contact support for more information.'**
  String get waitingMessageRejected;

  /// No description provided for @waitingAccessDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Access Date'**
  String get waitingAccessDateTitle;

  /// No description provided for @waitingAccessDatePremium.
  ///
  /// In en, this message translates to:
  /// **'As a {tier} member, you get early access before April 14th, 2026!'**
  String waitingAccessDatePremium(String tier);

  /// No description provided for @waitingAccessDateBasic.
  ///
  /// In en, this message translates to:
  /// **'Your access will begin on April 14th, 2026'**
  String get waitingAccessDateBasic;

  /// No description provided for @waitingCountdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Countdown to Launch'**
  String get waitingCountdownTitle;

  /// No description provided for @waitingDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String waitingDaysRemaining(int days);

  /// No description provided for @waitingHoursRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String waitingHoursRemaining(int hours);

  /// No description provided for @waitingMinutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String waitingMinutesRemaining(int minutes);

  /// No description provided for @waitingSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String waitingSecondsRemaining(int seconds);

  /// No description provided for @accountPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get accountPendingApproval;

  /// No description provided for @accountApproved.
  ///
  /// In en, this message translates to:
  /// **'Account Approved'**
  String get accountApproved;

  /// No description provided for @accountRejected.
  ///
  /// In en, this message translates to:
  /// **'Account Rejected'**
  String get accountRejected;

  /// No description provided for @upgradeForEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Silver, Gold, or Platinum for early access before April 14th, 2026!'**
  String get upgradeForEarlyAccess;

  /// No description provided for @waitingStayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned! We\'ll notify you when it\'s time to start connecting.'**
  String get waitingStayTuned;

  /// No description provided for @waitingNotificationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled - we\'ll let you know when you can access the app!'**
  String get waitingNotificationEnabled;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @waitingCountdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for registering! GreenGo Chat is launching soon. Get ready for an exclusive experience.'**
  String get waitingCountdownSubtitle;

  /// No description provided for @waitingCountdownLabel.
  ///
  /// In en, this message translates to:
  /// **'App Launch Countdown'**
  String get waitingCountdownLabel;

  /// No description provided for @waitingEarlyAccessMember.
  ///
  /// In en, this message translates to:
  /// **'Early Access Member'**
  String get waitingEarlyAccessMember;

  /// No description provided for @waitingExclusiveAccess.
  ///
  /// In en, this message translates to:
  /// **'Your exclusive access date'**
  String get waitingExclusiveAccess;

  /// No description provided for @waitingProfileUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Profile Under Review'**
  String get waitingProfileUnderReview;

  /// No description provided for @waitingReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'The app is now live! Our team is reviewing your profile to ensure the best experience for our community. This usually takes 24-48 hours.'**
  String get waitingReviewMessage;

  /// No description provided for @waitingStepRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration Complete'**
  String get waitingStepRegistration;

  /// No description provided for @waitingStepReview.
  ///
  /// In en, this message translates to:
  /// **'Profile Review in Progress'**
  String get waitingStepReview;

  /// No description provided for @waitingStepActivation.
  ///
  /// In en, this message translates to:
  /// **'Account Activation'**
  String get waitingStepActivation;

  /// No description provided for @waitingEnableNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Updated'**
  String get waitingEnableNotificationsTitle;

  /// No description provided for @waitingEnableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to be the first to know when you can access the app.'**
  String get waitingEnableNotificationsSubtitle;

  /// No description provided for @waitingThankYouRegistration.
  ///
  /// In en, this message translates to:
  /// **'Thank you for registering!'**
  String get waitingThankYouRegistration;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @vipPlatinumMember.
  ///
  /// In en, this message translates to:
  /// **'PLATINUM VIP'**
  String get vipPlatinumMember;

  /// No description provided for @vipGoldMember.
  ///
  /// In en, this message translates to:
  /// **'GOLD MEMBER'**
  String get vipGoldMember;

  /// No description provided for @vipSilverMember.
  ///
  /// In en, this message translates to:
  /// **'SILVER MEMBER'**
  String get vipSilverMember;

  /// No description provided for @vipPremiumBenefitsActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Benefits Active'**
  String get vipPremiumBenefitsActive;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email or nickname. Please check and try again, or sign up.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Please try again.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please use a stronger password.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get authErrorNetworkError;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email/nickname or password. Please check your credentials and try again.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @connectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get connectionErrorTitle;

  /// No description provided for @connectionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get connectionErrorMessage;

  /// No description provided for @serverUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Unavailable'**
  String get serverUnavailableTitle;

  /// No description provided for @serverUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Our servers are temporarily unavailable. Please try again in a few moments.'**
  String get serverUnavailableMessage;

  /// No description provided for @authenticationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get authenticationErrorTitle;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to verify your account.'**
  String get accountCreatedSuccess;

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'LEVEL UP!'**
  String get levelUp;

  /// No description provided for @levelUpCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations on reaching a new level!'**
  String get levelUpCongratulations;

  /// No description provided for @levelUpYouReachedLevel.
  ///
  /// In en, this message translates to:
  /// **'You reached Level {level}'**
  String levelUpYouReachedLevel(int level);

  /// No description provided for @levelUpRewards.
  ///
  /// In en, this message translates to:
  /// **'REWARDS'**
  String get levelUpRewards;

  /// No description provided for @levelUpContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get levelUpContinue;

  /// No description provided for @levelUpVIPUnlocked.
  ///
  /// In en, this message translates to:
  /// **'VIP Status Unlocked!'**
  String get levelUpVIPUnlocked;

  /// No description provided for @chatSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Safe While Chatting'**
  String get chatSafetyTitle;

  /// No description provided for @chatSafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our priority. Please keep these tips in mind.'**
  String get chatSafetySubtitle;

  /// No description provided for @chatSafetyTip1Title.
  ///
  /// In en, this message translates to:
  /// **'Keep Personal Info Private'**
  String get chatSafetyTip1Title;

  /// No description provided for @chatSafetyTip1Description.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share your address, phone number, or financial information.'**
  String get chatSafetyTip1Description;

  /// No description provided for @chatSafetyTip2Title.
  ///
  /// In en, this message translates to:
  /// **'Beware of Money Requests'**
  String get chatSafetyTip2Title;

  /// No description provided for @chatSafetyTip2Description.
  ///
  /// In en, this message translates to:
  /// **'Never send money to someone you haven\'t met in person.'**
  String get chatSafetyTip2Description;

  /// No description provided for @chatSafetyTip3Title.
  ///
  /// In en, this message translates to:
  /// **'Meet in Public Places'**
  String get chatSafetyTip3Title;

  /// No description provided for @chatSafetyTip3Description.
  ///
  /// In en, this message translates to:
  /// **'For first meetings, always choose a public, well-lit location.'**
  String get chatSafetyTip3Description;

  /// No description provided for @chatSafetyTip4Title.
  ///
  /// In en, this message translates to:
  /// **'Trust Your Instincts'**
  String get chatSafetyTip4Title;

  /// No description provided for @chatSafetyTip4Description.
  ///
  /// In en, this message translates to:
  /// **'If something feels wrong, trust your gut and end the conversation.'**
  String get chatSafetyTip4Description;

  /// No description provided for @chatSafetyTip5Title.
  ///
  /// In en, this message translates to:
  /// **'Report Suspicious Behavior'**
  String get chatSafetyTip5Title;

  /// No description provided for @chatSafetyTip5Description.
  ///
  /// In en, this message translates to:
  /// **'Use the report feature if someone makes you uncomfortable.'**
  String get chatSafetyTip5Description;

  /// No description provided for @chatSafetyGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get chatSafetyGotIt;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// No description provided for @tourDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Matches'**
  String get tourDiscoveryTitle;

  /// No description provided for @tourDiscoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Swipe through profiles to find your perfect match. Swipe right if you\'re interested, left to pass.'**
  String get tourDiscoveryDescription;

  /// No description provided for @tourMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Matches'**
  String get tourMatchesTitle;

  /// No description provided for @tourMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'See everyone who liked you back! Start conversations with your mutual matches.'**
  String get tourMatchesDescription;

  /// No description provided for @tourMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tourMessagesTitle;

  /// No description provided for @tourMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat with your matches here. Send messages, photos, and voice notes to connect.'**
  String get tourMessagesDescription;

  /// No description provided for @tourShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop & Coins'**
  String get tourShopTitle;

  /// No description provided for @tourShopDescription.
  ///
  /// In en, this message translates to:
  /// **'Get coins and premium features to boost your dating experience.'**
  String get tourShopDescription;

  /// No description provided for @tourProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Progress'**
  String get tourProgressTitle;

  /// No description provided for @tourProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Earn badges, complete challenges, and climb the leaderboard!'**
  String get tourProgressDescription;

  /// No description provided for @tourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get tourProfileTitle;

  /// No description provided for @tourProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize your profile, manage settings, and control your privacy.'**
  String get tourProfileDescription;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get progressOverview;

  /// No description provided for @progressAchievements.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get progressAchievements;

  /// No description provided for @progressChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get progressChallenges;

  /// No description provided for @progressLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get progressLeaderboard;

  /// No description provided for @progressLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String progressLevel(int level);

  /// No description provided for @progressBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get progressBadges;

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get progressCompleted;

  /// No description provided for @progressTotalXP.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get progressTotalXP;

  /// No description provided for @progressRecentAchievements.
  ///
  /// In en, this message translates to:
  /// **'Recent Achievements'**
  String get progressRecentAchievements;

  /// No description provided for @progressTodaysChallenges.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Challenges'**
  String get progressTodaysChallenges;

  /// No description provided for @progressSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get progressSeeAll;

  /// No description provided for @progressViewJourney.
  ///
  /// In en, this message translates to:
  /// **'View Your Journey'**
  String get progressViewJourney;

  /// No description provided for @progressJourneyDescription.
  ///
  /// In en, this message translates to:
  /// **'See your complete dating journey and milestones'**
  String get progressJourneyDescription;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @editNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get editNickname;

  /// No description provided for @nicknameUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated successfully'**
  String get nicknameUpdatedSuccess;

  /// No description provided for @nicknameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken'**
  String get nicknameAlreadyTaken;

  /// No description provided for @nicknameCheckError.
  ///
  /// In en, this message translates to:
  /// **'Error checking availability'**
  String get nicknameCheckError;

  /// No description provided for @nicknameInfoText.
  ///
  /// In en, this message translates to:
  /// **'Your nickname is unique and can be used to find you. Others can search for you using @{nickname}'**
  String nicknameInfoText(String nickname);

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get enterNickname;

  /// No description provided for @nicknameRequirements.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters. Letters, numbers, and underscores only.'**
  String get nicknameRequirements;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @nicknameRules.
  ///
  /// In en, this message translates to:
  /// **'Nickname Rules'**
  String get nicknameRules;

  /// No description provided for @nicknameMustBe3To20Chars.
  ///
  /// In en, this message translates to:
  /// **'Must be 3-20 characters'**
  String get nicknameMustBe3To20Chars;

  /// No description provided for @nicknameStartWithLetter.
  ///
  /// In en, this message translates to:
  /// **'Start with a letter'**
  String get nicknameStartWithLetter;

  /// No description provided for @nicknameOnlyAlphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores'**
  String get nicknameOnlyAlphanumeric;

  /// No description provided for @nicknameNoConsecutiveUnderscores.
  ///
  /// In en, this message translates to:
  /// **'No consecutive underscores'**
  String get nicknameNoConsecutiveUnderscores;

  /// No description provided for @nicknameNoReservedWords.
  ///
  /// In en, this message translates to:
  /// **'Cannot contain reserved words'**
  String get nicknameNoReservedWords;

  /// No description provided for @setYourUniqueNickname.
  ///
  /// In en, this message translates to:
  /// **'Set your unique nickname'**
  String get setYourUniqueNickname;

  /// No description provided for @searchByNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by Nickname'**
  String get searchByNickname;

  /// No description provided for @noProfileFoundWithNickname.
  ///
  /// In en, this message translates to:
  /// **'No profile found with @{nickname}'**
  String noProfileFoundWithNickname(String nickname);

  /// No description provided for @thatsYourOwnProfile.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own profile!'**
  String get thatsYourOwnProfile;

  /// No description provided for @errorSearchingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error searching. Please try again.'**
  String get errorSearchingTryAgain;

  /// No description provided for @enterNicknameToFind.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname to find someone directly'**
  String get enterNicknameToFind;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @unableToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile'**
  String get unableToLoadProfile;

  /// No description provided for @viewMyProfile.
  ///
  /// In en, this message translates to:
  /// **'View My Profile'**
  String get viewMyProfile;

  /// No description provided for @seeHowOthersViewProfile.
  ///
  /// In en, this message translates to:
  /// **'See how others view your profile'**
  String get seeHowOthersViewProfile;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos'**
  String photosCount(int count);

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @addBio.
  ///
  /// In en, this message translates to:
  /// **'Add a bio'**
  String get addBio;

  /// No description provided for @interestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} interests'**
  String interestsCount(int count);

  /// No description provided for @locationAndLanguages.
  ///
  /// In en, this message translates to:
  /// **'Location & Languages'**
  String get locationAndLanguages;

  /// No description provided for @voiceRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice recorded'**
  String get voiceRecorded;

  /// No description provided for @noVoiceRecording.
  ///
  /// In en, this message translates to:
  /// **'No voice recording'**
  String get noVoiceRecording;

  /// No description provided for @socialProfiles.
  ///
  /// In en, this message translates to:
  /// **'Social Profiles'**
  String get socialProfiles;

  /// No description provided for @noSocialProfilesLinked.
  ///
  /// In en, this message translates to:
  /// **'No social profiles linked'**
  String get noSocialProfilesLinked;

  /// No description provided for @profilesLinkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} profile{count, plural, =1{} other{s}} linked'**
  String profilesLinkedCount(int count);

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @rewardsAndProgress.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Progress'**
  String get rewardsAndProgress;

  /// No description provided for @myProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get myProgress;

  /// No description provided for @viewBadgesAchievementsLevel.
  ///
  /// In en, this message translates to:
  /// **'View badges, achievements & level'**
  String get viewBadgesAchievementsLevel;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @verificationPanel.
  ///
  /// In en, this message translates to:
  /// **'Verification Panel'**
  String get verificationPanel;

  /// No description provided for @reviewUserVerifications.
  ///
  /// In en, this message translates to:
  /// **'Review user verifications'**
  String get reviewUserVerifications;

  /// No description provided for @reportsPanel.
  ///
  /// In en, this message translates to:
  /// **'Reports Panel'**
  String get reportsPanel;

  /// No description provided for @reviewReportedMessages.
  ///
  /// In en, this message translates to:
  /// **'Review reported messages & manage accounts'**
  String get reviewReportedMessages;

  /// No description provided for @membershipPanel.
  ///
  /// In en, this message translates to:
  /// **'Membership Panel'**
  String get membershipPanel;

  /// No description provided for @manageCouponsTiersRules.
  ///
  /// In en, this message translates to:
  /// **'Manage coupons, tiers & rules'**
  String get manageCouponsTiersRules;

  /// No description provided for @exportMyDataGDPR.
  ///
  /// In en, this message translates to:
  /// **'Export My Data (GDPR)'**
  String get exportMyDataGDPR;

  /// No description provided for @restartAppWizard.
  ///
  /// In en, this message translates to:
  /// **'Restart App Wizard'**
  String get restartAppWizard;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChangedTo(String language);

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.'**
  String get deleteAccountConfirmation;

  /// No description provided for @adminAccountsCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts cannot be deleted'**
  String get adminAccountsCannotBeDeleted;

  /// No description provided for @exportingYourData.
  ///
  /// In en, this message translates to:
  /// **'Exporting your data...'**
  String get exportingYourData;

  /// No description provided for @dataExportSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Data export sent to your email'**
  String get dataExportSentToEmail;

  /// No description provided for @restartWizardDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will restart the onboarding wizard. You can update your profile information step by step. Your current data will be preserved.'**
  String get restartWizardDialogContent;

  /// No description provided for @restartWizard.
  ///
  /// In en, this message translates to:
  /// **'Restart Wizard'**
  String get restartWizard;

  /// No description provided for @logOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirmation;

  /// No description provided for @editVoiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit voice coming soon'**
  String get editVoiceComingSoon;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @startSwipingToFindMatches.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to find your matches!'**
  String get startSwipingToFindMatches;

  /// No description provided for @searchByNameOrNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @nickname'**
  String get searchByNameOrNickname;

  /// No description provided for @matchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} matches'**
  String matchesCount(int count);

  /// No description provided for @matchesOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} matches'**
  String matchesOfTotal(int filtered, int total);

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @tryDifferentSearchOrFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter'**
  String get tryDifferentSearchOrFilter;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get filterNew;

  /// No description provided for @filterMessaged.
  ///
  /// In en, this message translates to:
  /// **'Messaged'**
  String get filterMessaged;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get lookingFor;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @youMatchedWithOnDate.
  ///
  /// In en, this message translates to:
  /// **'You matched with {name} on {date}'**
  String youMatchedWithOnDate(String name, String date);

  /// No description provided for @chatWithName.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWithName(String name);

  /// No description provided for @longTermRelationship.
  ///
  /// In en, this message translates to:
  /// **'Long-term relationship'**
  String get longTermRelationship;

  /// No description provided for @shortTermRelationship.
  ///
  /// In en, this message translates to:
  /// **'Short-term relationship'**
  String get shortTermRelationship;

  /// No description provided for @friendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get friendship;

  /// No description provided for @casualDating.
  ///
  /// In en, this message translates to:
  /// **'Casual dating'**
  String get casualDating;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @lvl.
  ///
  /// In en, this message translates to:
  /// **'LVL'**
  String get lvl;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @toNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to Level {level}'**
  String toNextLevel(int percent, int level);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @myBadges.
  ///
  /// In en, this message translates to:
  /// **'My Badges'**
  String get myBadges;

  /// No description provided for @noBadgesEarnedYet.
  ///
  /// In en, this message translates to:
  /// **'No badges earned yet'**
  String get noBadgesEarnedYet;

  /// No description provided for @completeAchievementsToEarnBadges.
  ///
  /// In en, this message translates to:
  /// **'Complete achievements to earn badges!'**
  String get completeAchievementsToEarnBadges;

  /// No description provided for @moreAchievements.
  ///
  /// In en, this message translates to:
  /// **'+{count} more achievements'**
  String moreAchievements(int count);

  /// No description provided for @levelTitleLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get levelTitleLegend;

  /// No description provided for @levelTitleMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get levelTitleMaster;

  /// No description provided for @levelTitleExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get levelTitleExpert;

  /// No description provided for @levelTitleVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get levelTitleVeteran;

  /// No description provided for @levelTitleExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get levelTitleExplorer;

  /// No description provided for @levelTitleEnthusiast.
  ///
  /// In en, this message translates to:
  /// **'Enthusiast'**
  String get levelTitleEnthusiast;

  /// No description provided for @levelTitleNewcomer.
  ///
  /// In en, this message translates to:
  /// **'Newcomer'**
  String get levelTitleNewcomer;

  /// No description provided for @notificationNewLike.
  ///
  /// In en, this message translates to:
  /// **'You received a like from @{nickname}'**
  String notificationNewLike(String nickname);

  /// No description provided for @notificationSuperLike.
  ///
  /// In en, this message translates to:
  /// **'You received a super like from @{nickname}'**
  String notificationSuperLike(String nickname);

  /// No description provided for @notificationNewMatch.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match! You matched with @{nickname}. Start chatting now.'**
  String notificationNewMatch(String nickname);

  /// No description provided for @notificationNewChat.
  ///
  /// In en, this message translates to:
  /// **'@{nickname} started a conversation with you.'**
  String notificationNewChat(String nickname);

  /// No description provided for @notificationNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message from @{nickname}'**
  String notificationNewMessage(String nickname);

  /// No description provided for @notificationCoinsPurchased.
  ///
  /// In en, this message translates to:
  /// **'You successfully purchased {amount} coins.'**
  String notificationCoinsPurchased(int amount);

  /// No description provided for @notificationAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked: {name}'**
  String notificationAchievementUnlocked(String name);

  /// No description provided for @voiceStandOutWithYourVoice.
  ///
  /// In en, this message translates to:
  /// **'Stand out with your voice!'**
  String get voiceStandOutWithYourVoice;

  /// No description provided for @voiceRecordIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a short {seconds} second introduction to let others hear your personality.'**
  String voiceRecordIntroDescription(int seconds);

  /// No description provided for @voiceRecordingTips.
  ///
  /// In en, this message translates to:
  /// **'Recording Tips'**
  String get voiceRecordingTips;

  /// No description provided for @voiceTipFindQuietPlace.
  ///
  /// In en, this message translates to:
  /// **'Find a quiet place'**
  String get voiceTipFindQuietPlace;

  /// No description provided for @voiceTipBeYourself.
  ///
  /// In en, this message translates to:
  /// **'Be yourself and natural'**
  String get voiceTipBeYourself;

  /// No description provided for @voiceTipShareWhatMakesYouUnique.
  ///
  /// In en, this message translates to:
  /// **'Share what makes you unique'**
  String get voiceTipShareWhatMakesYouUnique;

  /// No description provided for @voiceTipKeepItShort.
  ///
  /// In en, this message translates to:
  /// **'Keep it short and sweet'**
  String get voiceTipKeepItShort;

  /// No description provided for @voiceTapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get voiceTapToRecord;

  /// No description provided for @voiceRecordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get voiceRecordingSaved;

  /// No description provided for @voiceRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record Again'**
  String get voiceRecordAgain;

  /// No description provided for @voiceUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get voiceUploading;

  /// No description provided for @voiceIntroSaved.
  ///
  /// In en, this message translates to:
  /// **'Voice introduction saved'**
  String get voiceIntroSaved;

  /// No description provided for @voiceUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload voice recording'**
  String get voiceUploadFailed;

  /// No description provided for @voiceDeleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get voiceDeleteRecording;

  /// No description provided for @voiceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your voice introduction?'**
  String get voiceDeleteConfirm;

  /// No description provided for @voiceMicrophonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required'**
  String get voiceMicrophonePermissionRequired;

  /// No description provided for @listenMe.
  ///
  /// In en, this message translates to:
  /// **'Listen me!'**
  String get listenMe;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'For security, please verify your identity before changing your password.'**
  String get changePasswordDescription;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get changePasswordEmailHint;

  /// No description provided for @changePasswordEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address'**
  String get changePasswordEmailConfirm;

  /// No description provided for @changePasswordEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'Email does not match your account'**
  String get changePasswordEmailMismatch;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordWrongCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get changePasswordWrongCurrent;

  /// No description provided for @changePasswordReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log out and log in again before changing your password'**
  String get changePasswordReauthRequired;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubtitle;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App?'**
  String get exitApp;

  /// No description provided for @exitAppConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit GreenGo?'**
  String get exitAppConfirmation;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @letsChat.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Chat!'**
  String get letsChat;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @supportCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help, report issues, contact us'**
  String get supportCenterSubtitle;

  /// No description provided for @editInterests.
  ///
  /// In en, this message translates to:
  /// **'Edit Interests'**
  String get editInterests;

  /// No description provided for @interestsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{selected}/{max} interests selected'**
  String interestsSelectedCount(int selected, int max);

  /// No description provided for @selectAtLeastInterests.
  ///
  /// In en, this message translates to:
  /// **'Select at least {count} interests'**
  String selectAtLeastInterests(int count);

  /// No description provided for @greatInterestsHelp.
  ///
  /// In en, this message translates to:
  /// **'Great! Your interests help us find better matches'**
  String get greatInterestsHelp;

  /// No description provided for @maximumInterestsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} interests allowed'**
  String maximumInterestsAllowed(int count);

  /// No description provided for @connectSocialAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connect your social accounts'**
  String get connectSocialAccounts;

  /// No description provided for @helpOthersFindYou.
  ///
  /// In en, this message translates to:
  /// **'Help others find you on social media'**
  String get helpOthersFindYou;

  /// No description provided for @socialProfilesTip.
  ///
  /// In en, this message translates to:
  /// **'Your social profiles will be visible on your dating profile and help others verify your identity.'**
  String get socialProfilesTip;

  /// No description provided for @usernameOrProfileUrl.
  ///
  /// In en, this message translates to:
  /// **'Username or profile URL'**
  String get usernameOrProfileUrl;

  /// No description provided for @usernameWithoutAt.
  ///
  /// In en, this message translates to:
  /// **'Username (without @)'**
  String get usernameWithoutAt;

  /// No description provided for @voiceIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Voice Introduction'**
  String get voiceIntroduction;

  /// No description provided for @interestTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get interestTravel;

  /// No description provided for @interestPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interestPhotography;

  /// No description provided for @interestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get interestMusic;

  /// No description provided for @interestFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get interestFitness;

  /// No description provided for @interestCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get interestCooking;

  /// No description provided for @interestReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get interestReading;

  /// No description provided for @interestMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get interestMovies;

  /// No description provided for @interestGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get interestGaming;

  /// No description provided for @interestArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get interestArt;

  /// No description provided for @interestDance.
  ///
  /// In en, this message translates to:
  /// **'Dance'**
  String get interestDance;

  /// No description provided for @interestYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get interestYoga;

  /// No description provided for @interestHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get interestHiking;

  /// No description provided for @interestSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get interestSwimming;

  /// No description provided for @interestCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get interestCycling;

  /// No description provided for @interestRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get interestRunning;

  /// No description provided for @interestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get interestSports;

  /// No description provided for @interestFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get interestFashion;

  /// No description provided for @interestTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get interestTechnology;

  /// No description provided for @interestWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get interestWriting;

  /// No description provided for @interestCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get interestCoffee;

  /// No description provided for @interestWine.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get interestWine;

  /// No description provided for @interestBeer.
  ///
  /// In en, this message translates to:
  /// **'Beer'**
  String get interestBeer;

  /// No description provided for @interestFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get interestFood;

  /// No description provided for @interestVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get interestVegetarian;

  /// No description provided for @interestVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get interestVegan;

  /// No description provided for @interestPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get interestPets;

  /// No description provided for @interestDogs.
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get interestDogs;

  /// No description provided for @interestCats.
  ///
  /// In en, this message translates to:
  /// **'Cats'**
  String get interestCats;

  /// No description provided for @interestNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get interestNature;

  /// No description provided for @interestBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get interestBeach;

  /// No description provided for @interestMountains.
  ///
  /// In en, this message translates to:
  /// **'Mountains'**
  String get interestMountains;

  /// No description provided for @interestCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get interestCamping;

  /// No description provided for @interestSurfing.
  ///
  /// In en, this message translates to:
  /// **'Surfing'**
  String get interestSurfing;

  /// No description provided for @interestSkiing.
  ///
  /// In en, this message translates to:
  /// **'Skiing'**
  String get interestSkiing;

  /// No description provided for @interestSnowboarding.
  ///
  /// In en, this message translates to:
  /// **'Snowboarding'**
  String get interestSnowboarding;

  /// No description provided for @interestMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get interestMeditation;

  /// No description provided for @interestSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Spirituality'**
  String get interestSpirituality;

  /// No description provided for @interestVolunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get interestVolunteering;

  /// No description provided for @interestEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get interestEnvironment;

  /// No description provided for @interestPolitics.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get interestPolitics;

  /// No description provided for @interestScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get interestScience;

  /// No description provided for @interestHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get interestHistory;

  /// No description provided for @interestLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get interestLanguages;

  /// No description provided for @interestTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get interestTeaching;

  /// No description provided for @xTwitter.
  ///
  /// In en, this message translates to:
  /// **'X (Twitter)'**
  String get xTwitter;

  /// No description provided for @chatMessageBlockedContains.
  ///
  /// In en, this message translates to:
  /// **'Message blocked: Contains {violations}. For your safety, sharing personal contact details is not allowed.'**
  String chatMessageBlockedContains(String violations);

  /// No description provided for @chatReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report Message'**
  String get chatReportMessage;

  /// No description provided for @chatWhyReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this message?'**
  String get chatWhyReportMessage;

  /// No description provided for @chatReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get chatReportReasonHarassment;

  /// No description provided for @chatReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get chatReportReasonSpam;

  /// No description provided for @chatReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get chatReportReasonInappropriate;

  /// No description provided for @chatReportReasonPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Sharing personal information'**
  String get chatReportReasonPersonalInfo;

  /// No description provided for @chatReportReasonThreatening.
  ///
  /// In en, this message translates to:
  /// **'Threatening behavior'**
  String get chatReportReasonThreatening;

  /// No description provided for @chatReportReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile / Catfishing'**
  String get chatReportReasonFakeProfile;

  /// No description provided for @chatReportReasonUnderage.
  ///
  /// In en, this message translates to:
  /// **'Underage user'**
  String get chatReportReasonUnderage;

  /// No description provided for @chatReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatReportReasonOther;

  /// No description provided for @chatMessageReported.
  ///
  /// In en, this message translates to:
  /// **'Message reported. We will review it shortly.'**
  String get chatMessageReported;

  /// No description provided for @chatFailedToReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to report message: {error}'**
  String chatFailedToReportMessage(String error);

  /// No description provided for @chatSendAttachment.
  ///
  /// In en, this message translates to:
  /// **'Send Attachment'**
  String get chatSendAttachment;

  /// No description provided for @chatAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get chatAttachGallery;

  /// No description provided for @chatAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatAttachCamera;

  /// No description provided for @chatAttachVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatAttachVideo;

  /// No description provided for @chatAttachRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get chatAttachRecord;

  /// No description provided for @chatFailedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String chatFailedToPickImage(String error);

  /// No description provided for @chatFailedToPickVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick video: {error}'**
  String chatFailedToPickVideo(String error);

  /// No description provided for @chatFailedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String chatFailedToUploadImage(String error);

  /// No description provided for @chatVideoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Video too large. Maximum size is 50MB.'**
  String get chatVideoTooLarge;

  /// No description provided for @chatFailedToUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload video: {error}'**
  String chatFailedToUploadVideo(String error);

  /// No description provided for @chatMediaLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Media Limit Reached'**
  String get chatMediaLimitReached;

  /// No description provided for @chatSayHiTo.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name}!'**
  String chatSayHiTo(String name);

  /// No description provided for @chatSendMessageToStart.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation'**
  String get chatSendMessageToStart;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get chatTyping;

  /// No description provided for @chatDisableTranslation.
  ///
  /// In en, this message translates to:
  /// **'Disable translation'**
  String get chatDisableTranslation;

  /// No description provided for @chatEnableTranslation.
  ///
  /// In en, this message translates to:
  /// **'Enable translation'**
  String get chatEnableTranslation;

  /// No description provided for @chatTranslationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Translation enabled'**
  String get chatTranslationEnabled;

  /// No description provided for @chatTranslationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Translation disabled'**
  String get chatTranslationDisabled;

  /// No description provided for @chatUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get chatUploading;

  /// No description provided for @chatOptions.
  ///
  /// In en, this message translates to:
  /// **'Chat Options'**
  String get chatOptions;

  /// No description provided for @chatDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete chat for me'**
  String get chatDeleteForMe;

  /// No description provided for @chatDeleteForBoth.
  ///
  /// In en, this message translates to:
  /// **'Delete chat for both'**
  String get chatDeleteForBoth;

  /// No description provided for @chatBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String chatBlockUser(String name);

  /// No description provided for @chatReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String chatReportUser(String name);

  /// No description provided for @chatDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get chatDeleteChat;

  /// No description provided for @chatDeleteChatForMeMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete the chat from your device only. The other person will still see the messages.'**
  String get chatDeleteChatForMeMessage;

  /// No description provided for @chatDeleteChatForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat for Everyone'**
  String get chatDeleteChatForEveryone;

  /// No description provided for @chatDeleteChatForBothMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all messages for both you and {name}. This action cannot be undone.'**
  String chatDeleteChatForBothMessage(String name);

  /// No description provided for @chatDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for Everyone'**
  String get chatDeleteForEveryone;

  /// No description provided for @chatBlockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get chatBlockUserTitle;

  /// No description provided for @chatBlockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {name}? They will no longer be able to contact you.'**
  String chatBlockUserMessage(String name);

  /// No description provided for @chatBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlock;

  /// No description provided for @chatCannotBlockAdmin.
  ///
  /// In en, this message translates to:
  /// **'You cannot block an administrator.'**
  String get chatCannotBlockAdmin;

  /// No description provided for @chatUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked'**
  String chatUserBlocked(String name);

  /// No description provided for @chatReportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get chatReportUserTitle;

  /// No description provided for @chatWhyReportUser.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting {name}?'**
  String chatWhyReportUser(String name);

  /// No description provided for @chatCannotReportAdmin.
  ///
  /// In en, this message translates to:
  /// **'You cannot report an administrator.'**
  String get chatCannotReportAdmin;

  /// No description provided for @chatUserReported.
  ///
  /// In en, this message translates to:
  /// **'User reported. We will review your report shortly.'**
  String get chatUserReported;

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatUnableToForward.
  ///
  /// In en, this message translates to:
  /// **'Unable to forward message'**
  String get chatUnableToForward;

  /// No description provided for @chatSearchByNameOrNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @nickname'**
  String get chatSearchByNameOrNickname;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatStartSwipingToChat.
  ///
  /// In en, this message translates to:
  /// **'Start swiping and matching to chat with people!'**
  String get chatStartSwipingToChat;

  /// No description provided for @chatMessageOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get chatMessageOriginal;

  /// No description provided for @chatMessageTranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get chatMessageTranslated;

  /// No description provided for @chatMessageStarred.
  ///
  /// In en, this message translates to:
  /// **'Message starred'**
  String get chatMessageStarred;

  /// No description provided for @chatMessageUnstarred.
  ///
  /// In en, this message translates to:
  /// **'Message unstarred'**
  String get chatMessageUnstarred;

  /// No description provided for @chatMessageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message Options'**
  String get chatMessageOptions;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatReplyToMessage.
  ///
  /// In en, this message translates to:
  /// **'Reply to this message'**
  String get chatReplyToMessage;

  /// No description provided for @chatForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForward;

  /// No description provided for @chatForwardToChat.
  ///
  /// In en, this message translates to:
  /// **'Forward to another chat'**
  String get chatForwardToChat;

  /// No description provided for @chatStarMessage.
  ///
  /// In en, this message translates to:
  /// **'Star Message'**
  String get chatStarMessage;

  /// No description provided for @chatUnstarMessage.
  ///
  /// In en, this message translates to:
  /// **'Unstar Message'**
  String get chatUnstarMessage;

  /// No description provided for @chatAddToStarred.
  ///
  /// In en, this message translates to:
  /// **'Add to starred messages'**
  String get chatAddToStarred;

  /// No description provided for @chatRemoveFromStarred.
  ///
  /// In en, this message translates to:
  /// **'Remove from starred messages'**
  String get chatRemoveFromStarred;

  /// No description provided for @chatReportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Report inappropriate content'**
  String get chatReportInappropriate;

  /// No description provided for @chatVideoPlayer.
  ///
  /// In en, this message translates to:
  /// **'Video Player'**
  String get chatVideoPlayer;

  /// No description provided for @chatFailedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get chatFailedToLoadImage;

  /// No description provided for @chatLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get chatLoadingVideo;

  /// No description provided for @chatPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'Preview Video'**
  String get chatPreviewVideo;

  /// No description provided for @chatPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Preview Image'**
  String get chatPreviewImage;

  /// No description provided for @chatAddCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get chatAddCaption;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Support'**
  String get chatSupportTitle;

  /// No description provided for @chatSupportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get chatSupportStatusOpen;

  /// No description provided for @chatSupportStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get chatSupportStatusPending;

  /// No description provided for @chatSupportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get chatSupportStatusResolved;

  /// No description provided for @chatSupportStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get chatSupportStatusClosed;

  /// No description provided for @chatSupportStatusDefault.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatSupportStatusDefault;

  /// No description provided for @chatSupportAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent: {name}'**
  String chatSupportAgent(String name);

  /// No description provided for @chatSupportWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Support'**
  String get chatSupportWelcome;

  /// No description provided for @chatSupportStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation.\nOur team will respond as soon as possible.'**
  String get chatSupportStartMessage;

  /// No description provided for @chatSupportTicketStart.
  ///
  /// In en, this message translates to:
  /// **'Ticket Start'**
  String get chatSupportTicketStart;

  /// No description provided for @chatSupportTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket Created'**
  String get chatSupportTicketCreated;

  /// No description provided for @chatSupportErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get chatSupportErrorLoading;

  /// No description provided for @chatSupportFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String chatSupportFailedToSend(String error);

  /// No description provided for @chatSupportTicketResolved.
  ///
  /// In en, this message translates to:
  /// **'This ticket has been resolved'**
  String get chatSupportTicketResolved;

  /// No description provided for @chatSupportReopenTicket.
  ///
  /// In en, this message translates to:
  /// **'Need more help? Tap to reopen'**
  String get chatSupportReopenTicket;

  /// No description provided for @chatSupportTicketReopened.
  ///
  /// In en, this message translates to:
  /// **'Ticket reopened. You can send a message now.'**
  String get chatSupportTicketReopened;

  /// No description provided for @chatSupportFailedToReopen.
  ///
  /// In en, this message translates to:
  /// **'Failed to reopen ticket: {error}'**
  String chatSupportFailedToReopen(String error);

  /// No description provided for @chatSupportAddCaptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)...'**
  String get chatSupportAddCaptionOptional;

  /// No description provided for @chatSupportTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get chatSupportTypeMessage;

  /// No description provided for @chatSupportAddAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get chatSupportAddAttachment;

  /// No description provided for @chatSupportTicketInfo.
  ///
  /// In en, this message translates to:
  /// **'Ticket Information'**
  String get chatSupportTicketInfo;

  /// No description provided for @chatSupportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get chatSupportSubject;

  /// No description provided for @chatSupportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get chatSupportCategory;

  /// No description provided for @chatSupportStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get chatSupportStatus;

  /// No description provided for @chatSupportAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get chatSupportAgentLabel;

  /// No description provided for @chatSupportTicketId.
  ///
  /// In en, this message translates to:
  /// **'Ticket ID'**
  String get chatSupportTicketId;

  /// No description provided for @chatSupportGeneralSupport.
  ///
  /// In en, this message translates to:
  /// **'General Support'**
  String get chatSupportGeneralSupport;

  /// No description provided for @chatSupportGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get chatSupportGeneral;

  /// No description provided for @chatSupportWaitingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for assignment'**
  String get chatSupportWaitingAssignment;

  /// No description provided for @chatSupportClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chatSupportClose;

  /// No description provided for @chatSupportJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatSupportJustNow;

  /// No description provided for @chatSupportMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String chatSupportMinutesAgo(int minutes);

  /// No description provided for @chatSupportHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String chatSupportHoursAgo(int hours);

  /// No description provided for @chatSupportDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String chatSupportDaysAgo(int days);

  /// No description provided for @nicknameSearchChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get nicknameSearchChat;

  /// No description provided for @filterNewMessages.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get filterNewMessages;

  /// No description provided for @filterNotReplied.
  ///
  /// In en, this message translates to:
  /// **'No Reply'**
  String get filterNotReplied;

  /// No description provided for @filterFromMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get filterFromMatch;

  /// No description provided for @filterFromSearch.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get filterFromSearch;

  /// No description provided for @publicAlbum.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicAlbum;

  /// No description provided for @privateAlbum.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateAlbum;

  /// No description provided for @shareAlbum.
  ///
  /// In en, this message translates to:
  /// **'Share Album'**
  String get shareAlbum;

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke album access'**
  String get revokeAccess;

  /// No description provided for @albumNotShared.
  ///
  /// In en, this message translates to:
  /// **'Album not shared with you'**
  String get albumNotShared;

  /// No description provided for @grantAlbumAccess.
  ///
  /// In en, this message translates to:
  /// **'Share my album'**
  String get grantAlbumAccess;

  /// No description provided for @albumOption.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumOption;

  /// No description provided for @albumSharedMessage.
  ///
  /// In en, this message translates to:
  /// **'{username} shared their album with you'**
  String albumSharedMessage(String username);

  /// No description provided for @albumRevokedMessage.
  ///
  /// In en, this message translates to:
  /// **'{username} revoked album access'**
  String albumRevokedMessage(String username);

  /// No description provided for @sendCoins.
  ///
  /// In en, this message translates to:
  /// **'Send Coins'**
  String get sendCoins;

  /// No description provided for @recipientNickname.
  ///
  /// In en, this message translates to:
  /// **'Recipient nickname'**
  String get recipientNickname;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @sendCoinsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} coins to @{nickname}?'**
  String sendCoinsConfirm(String amount, String nickname);

  /// No description provided for @coinsSent.
  ///
  /// In en, this message translates to:
  /// **'Coins sent successfully!'**
  String get coinsSent;

  /// No description provided for @insufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coins'**
  String get insufficientCoins;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @aboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMeTitle;

  /// No description provided for @travelerBadge.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get travelerBadge;

  /// No description provided for @travelerModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveler Mode'**
  String get travelerModeTitle;

  /// No description provided for @travelerModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Appear in a different city\'s discovery feed for 24 hours'**
  String get travelerModeDescription;

  /// No description provided for @travelerModeActive.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode active'**
  String get travelerModeActive;

  /// No description provided for @travelerModeActivated.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode activated! Appearing in {city} for 24 hours.'**
  String travelerModeActivated(String city);

  /// No description provided for @travelerModeDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode deactivated. Back to your real location.'**
  String get travelerModeDeactivated;

  /// No description provided for @selectTravelLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Travel Location'**
  String get selectTravelLocation;

  /// No description provided for @searchCityPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search city, address, or place...'**
  String get searchCityPlaceholder;

  /// No description provided for @useCurrentGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current GPS location'**
  String get useCurrentGpsLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get changeLocation;

  /// No description provided for @travelerLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'You will appear in discovery results for this location for 24 hours.'**
  String get travelerLocationInfo;

  /// No description provided for @searchForCity.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or use GPS'**
  String get searchForCity;

  /// No description provided for @travelerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Your profile will appear in that location\'s discovery feed for 24 hours with a Traveler badge.'**
  String get travelerSearchHint;

  /// No description provided for @incognitoMode.
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get incognitoMode;

  /// No description provided for @incognitoModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Hide your profile from discovery'**
  String get incognitoModeDescription;

  /// No description provided for @myUsage.
  ///
  /// In en, this message translates to:
  /// **'My Usage'**
  String get myUsage;

  /// No description provided for @boostProfile.
  ///
  /// In en, this message translates to:
  /// **'Boost Profile'**
  String get boostProfile;

  /// No description provided for @boostActivated.
  ///
  /// In en, this message translates to:
  /// **'Boost activated for 30 minutes!'**
  String get boostActivated;

  /// No description provided for @superLike.
  ///
  /// In en, this message translates to:
  /// **'Super Like'**
  String get superLike;

  /// No description provided for @undoSwipe.
  ///
  /// In en, this message translates to:
  /// **'Undo Swipe'**
  String get undoSwipe;

  /// No description provided for @freeActionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} free actions remaining today'**
  String freeActionsRemaining(int count);

  /// No description provided for @coinsRequired.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins required'**
  String coinsRequired(int amount);

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @dailySwipeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily swipe limit reached. Upgrade for more swipes!'**
  String get dailySwipeLimitReached;

  /// No description provided for @noOthersToSee.
  ///
  /// In en, this message translates to:
  /// **'There\'s no others to see'**
  String get noOthersToSee;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new people, or adjust your preferences'**
  String get checkBackLater;

  /// No description provided for @adjustPreferences.
  ///
  /// In en, this message translates to:
  /// **'Adjust Preferences'**
  String get adjustPreferences;

  /// No description provided for @noPreviousProfile.
  ///
  /// In en, this message translates to:
  /// **'No previous profile to rewind'**
  String get noPreviousProfile;

  /// No description provided for @cantUndoMatched.
  ///
  /// In en, this message translates to:
  /// **'Can\'t undo — you already matched!'**
  String get cantUndoMatched;

  /// No description provided for @showingProfiles.
  ///
  /// In en, this message translates to:
  /// **'{count} profiles'**
  String showingProfiles(int count);

  /// No description provided for @seeMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'See {count} more'**
  String seeMoreProfiles(int count);

  /// No description provided for @coinsCost.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins'**
  String coinsCost(int amount);

  /// No description provided for @seeMoreProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'See More Profiles'**
  String get seeMoreProfilesTitle;

  /// No description provided for @unlockMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'Unlock {count} more profiles in grid view for {cost} coins.'**
  String unlockMoreProfiles(int count, int cost);

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @buyCoins.
  ///
  /// In en, this message translates to:
  /// **'Buy Coins'**
  String get buyCoins;

  /// No description provided for @needCoinsForProfiles.
  ///
  /// In en, this message translates to:
  /// **'You need {amount} coins to unlock more profiles.'**
  String needCoinsForProfiles(int amount);

  /// No description provided for @matchPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percentage} match'**
  String matchPercentage(String percentage);

  /// No description provided for @youGotSuperLike.
  ///
  /// In en, this message translates to:
  /// **'You got a Super Like!'**
  String get youGotSuperLike;

  /// No description provided for @superLikedYou.
  ///
  /// In en, this message translates to:
  /// **'{name} super liked you!'**
  String superLikedYou(String name);

  /// No description provided for @photoValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating photo...'**
  String get photoValidating;

  /// No description provided for @photoNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Photo Not Accepted'**
  String get photoNotAccepted;

  /// No description provided for @photoMainNoFace.
  ///
  /// In en, this message translates to:
  /// **'Your main photo must show your face clearly. No face was detected in this photo.'**
  String get photoMainNoFace;

  /// No description provided for @photoMainNotForward.
  ///
  /// In en, this message translates to:
  /// **'Please use a photo where your face is clearly visible and facing forward.'**
  String get photoMainNotForward;

  /// No description provided for @photoExplicitNudity.
  ///
  /// In en, this message translates to:
  /// **'This photo appears to contain nudity or explicit content. All photos must be appropriate and fully clothed.'**
  String get photoExplicitNudity;

  /// No description provided for @photoExplicitContent.
  ///
  /// In en, this message translates to:
  /// **'This photo contains inappropriate content. Nudity, underwear, and explicit content are not allowed anywhere in the app.'**
  String get photoExplicitContent;

  /// No description provided for @photoTooMuchSkin.
  ///
  /// In en, this message translates to:
  /// **'This photo shows too much skin exposure. Please use a photo where you are appropriately dressed.'**
  String get photoTooMuchSkin;

  /// No description provided for @photoNotAllowedPublic.
  ///
  /// In en, this message translates to:
  /// **'This photo is not allowed. All photos must be appropriate.'**
  String get photoNotAllowedPublic;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Photo is too large. Maximum size is 10MB.'**
  String get photoTooLarge;

  /// No description provided for @photoMustHaveOne.
  ///
  /// In en, this message translates to:
  /// **'You must have at least one public photo with your face visible.'**
  String get photoMustHaveOne;

  /// No description provided for @photoDeleteMainWarning.
  ///
  /// In en, this message translates to:
  /// **'This is your main photo. The next photo will become your main photo (must show your face). Continue?'**
  String get photoDeleteMainWarning;

  /// No description provided for @photoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get photoDeleteConfirm;

  /// No description provided for @photoMaxPublic.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 public photos allowed'**
  String get photoMaxPublic;

  /// No description provided for @photoMaxPrivate.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 private photos allowed'**
  String get photoMaxPrivate;

  /// No description provided for @membershipRequired.
  ///
  /// In en, this message translates to:
  /// **'Membership Required'**
  String get membershipRequired;

  /// No description provided for @membershipRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'You need to be a member of GreenGo to perform this action.'**
  String get membershipRequiredDescription;

  /// No description provided for @yearlyMembership.
  ///
  /// In en, this message translates to:
  /// **'Yearly Membership'**
  String get yearlyMembership;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopTabCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get shopTabCoins;

  /// No description provided for @shopTabMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get shopTabMembership;

  /// No description provided for @shopTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get shopTabVideo;

  /// No description provided for @shopUpgradeExperience.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Experience'**
  String get shopUpgradeExperience;

  /// No description provided for @shopCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan: {tier}'**
  String shopCurrentPlan(String tier);

  /// No description provided for @shopExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date} ({days} days remaining)'**
  String shopExpires(String date, String days);

  /// No description provided for @shopExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired: {date}'**
  String shopExpired(String date);

  /// No description provided for @shopMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get shopMonthly;

  /// No description provided for @shopYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get shopYearly;

  /// No description provided for @shopSavePercent.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String shopSavePercent(String percent);

  /// No description provided for @shopUpgradeAndSave.
  ///
  /// In en, this message translates to:
  /// **'Upgrade & Save! Get discount on higher tiers'**
  String get shopUpgradeAndSave;

  /// No description provided for @shopBaseMembership.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Base Membership'**
  String get shopBaseMembership;

  /// No description provided for @shopYearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly subscription'**
  String get shopYearlyPlan;

  /// No description provided for @shopActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get shopActive;

  /// No description provided for @shopBaseMembershipDescription.
  ///
  /// In en, this message translates to:
  /// **'Required to swipe, like, chat, and interact with other users.'**
  String get shopBaseMembershipDescription;

  /// No description provided for @shopValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String shopValidUntil(String date);

  /// No description provided for @shopUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {tier} ({duration})'**
  String shopUpgradeTo(String tier, String duration);

  /// No description provided for @shopBuyTier.
  ///
  /// In en, this message translates to:
  /// **'Buy {tier} ({duration})'**
  String shopBuyTier(String tier, String duration);

  /// No description provided for @shopOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get shopOneYear;

  /// No description provided for @shopOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get shopOneMonth;

  /// No description provided for @shopYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save \${amount}/month upgrading from {tier}'**
  String shopYouSave(String amount, String tier);

  /// No description provided for @shopDailyLikes.
  ///
  /// In en, this message translates to:
  /// **'Daily Likes'**
  String get shopDailyLikes;

  /// No description provided for @shopSuperLikes.
  ///
  /// In en, this message translates to:
  /// **'Super Likes'**
  String get shopSuperLikes;

  /// No description provided for @shopBoosts.
  ///
  /// In en, this message translates to:
  /// **'Boosts'**
  String get shopBoosts;

  /// No description provided for @shopSeeWhoLikesYou.
  ///
  /// In en, this message translates to:
  /// **'See Who Likes You'**
  String get shopSeeWhoLikesYou;

  /// No description provided for @shopVipBadge.
  ///
  /// In en, this message translates to:
  /// **'VIP Badge'**
  String get shopVipBadge;

  /// No description provided for @shopPriorityMatching.
  ///
  /// In en, this message translates to:
  /// **'Priority Matching'**
  String get shopPriorityMatching;

  /// No description provided for @shopSendCoins.
  ///
  /// In en, this message translates to:
  /// **'Send Coins'**
  String get shopSendCoins;

  /// No description provided for @shopRecipientNickname.
  ///
  /// In en, this message translates to:
  /// **'Recipient nickname'**
  String get shopRecipientNickname;

  /// No description provided for @shopEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get shopEnterAmount;

  /// No description provided for @shopConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm Send'**
  String get shopConfirmSend;

  /// No description provided for @shopSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shopSend;

  /// No description provided for @shopUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get shopUserNotFound;

  /// No description provided for @shopCannotSendToSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot send coins to yourself'**
  String get shopCannotSendToSelf;

  /// No description provided for @shopCoinsSentTo.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins sent to @{nickname}'**
  String shopCoinsSentTo(String amount, String nickname);

  /// No description provided for @shopFailedToSendCoins.
  ///
  /// In en, this message translates to:
  /// **'Failed to send coins'**
  String get shopFailedToSendCoins;

  /// No description provided for @shopEnterBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter both nickname and amount'**
  String get shopEnterBothFields;

  /// No description provided for @shopEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get shopEnterValidAmount;

  /// No description provided for @shopInsufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coins'**
  String get shopInsufficientCoins;

  /// No description provided for @shopYouHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get shopYouHave;

  /// No description provided for @shopGreenGoCoins.
  ///
  /// In en, this message translates to:
  /// **'GreenGoCoins'**
  String get shopGreenGoCoins;

  /// No description provided for @shopUnlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features and enhance your dating experience'**
  String get shopUnlockPremium;

  /// No description provided for @shopPopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get shopPopular;

  /// No description provided for @shopCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get shopCoins;

  /// No description provided for @shopPurchaseCoinsFor.
  ///
  /// In en, this message translates to:
  /// **'Purchase {coins} Coins for {price}'**
  String shopPurchaseCoinsFor(String coins, String price);

  /// No description provided for @shopComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get shopComingSoon;

  /// No description provided for @shopVideoCoinsDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch short videos to earn free coins!\nStay tuned for this exciting feature.'**
  String get shopVideoCoinsDescription;

  /// No description provided for @shopGetNotified.
  ///
  /// In en, this message translates to:
  /// **'Get Notified'**
  String get shopGetNotified;

  /// No description provided for @shopNotifyMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when Video-Coins is available'**
  String get shopNotifyMessage;

  /// No description provided for @shopStoreNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Store not available. Make sure Google Play is installed.'**
  String get shopStoreNotAvailable;

  /// No description provided for @shopFailedToInitiate.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate purchase'**
  String get shopFailedToInitiate;

  /// No description provided for @shopUnableToLoadPackages.
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Packages'**
  String get shopUnableToLoadPackages;

  /// No description provided for @shopRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shopRetry;

  /// No description provided for @shopCheckInternet.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have an internet connection\nand try again.'**
  String get shopCheckInternet;

  /// No description provided for @shopMembershipActivated.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Membership activated! +500 bonus coins. Valid until {date}.'**
  String shopMembershipActivated(String date);

  /// No description provided for @shopPreviousPurchaseFound.
  ///
  /// In en, this message translates to:
  /// **'Previous purchase found. Please try again.'**
  String get shopPreviousPurchaseFound;

  /// No description provided for @reuploadVerification.
  ///
  /// In en, this message translates to:
  /// **'Re-upload Verification Photo'**
  String get reuploadVerification;

  /// No description provided for @reverificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get reverificationTitle;

  /// No description provided for @reverificationHeading.
  ///
  /// In en, this message translates to:
  /// **'We need to verify your identity'**
  String get reverificationHeading;

  /// No description provided for @reverificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please take a clear selfie so we can verify your identity. Make sure your face is well lit and clearly visible.'**
  String get reverificationDescription;

  /// No description provided for @reverificationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for request:'**
  String get reverificationReasonLabel;

  /// No description provided for @reverificationPhotoTips.
  ///
  /// In en, this message translates to:
  /// **'Photo Tips'**
  String get reverificationPhotoTips;

  /// No description provided for @reverificationTipLighting.
  ///
  /// In en, this message translates to:
  /// **'Good lighting — face the light source'**
  String get reverificationTipLighting;

  /// No description provided for @reverificationTipCamera.
  ///
  /// In en, this message translates to:
  /// **'Look directly at the camera'**
  String get reverificationTipCamera;

  /// No description provided for @reverificationTipNoAccessories.
  ///
  /// In en, this message translates to:
  /// **'No sunglasses, hats, or masks'**
  String get reverificationTipNoAccessories;

  /// No description provided for @reverificationTipFullFace.
  ///
  /// In en, this message translates to:
  /// **'Make sure your full face is visible'**
  String get reverificationTipFullFace;

  /// No description provided for @reverificationRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get reverificationRetakePhoto;

  /// No description provided for @reverificationTapToSelfie.
  ///
  /// In en, this message translates to:
  /// **'Tap to take a selfie'**
  String get reverificationTapToSelfie;

  /// No description provided for @reverificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get reverificationSubmit;

  /// No description provided for @reverificationInfoText.
  ///
  /// In en, this message translates to:
  /// **'After submitting, your profile will be under review. You will get access once approved.'**
  String get reverificationInfoText;

  /// No description provided for @reverificationCameraError.
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera'**
  String get reverificationCameraError;

  /// No description provided for @reverificationUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get reverificationUploadFailed;

  /// No description provided for @notificationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected'**
  String get notificationDialogTitle;

  /// No description provided for @notificationDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to know when you get matches, messages, and super likes.'**
  String get notificationDialogMessage;

  /// No description provided for @notificationDialogEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationDialogEnable;

  /// No description provided for @notificationDialogNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notificationDialogNotNow;

  /// No description provided for @discoveryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoveryFilterAll;

  /// No description provided for @discoveryFilterLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get discoveryFilterLiked;

  /// No description provided for @discoveryFilterSuperLiked.
  ///
  /// In en, this message translates to:
  /// **'Super Liked'**
  String get discoveryFilterSuperLiked;

  /// No description provided for @discoveryFilterPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get discoveryFilterPassed;

  /// No description provided for @discoveryFilterSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get discoveryFilterSkipped;

  /// No description provided for @discoveryFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get discoveryFilterMatches;

  /// No description provided for @discoveryError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String discoveryError(String error);

  /// No description provided for @admin2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Verification'**
  String get admin2faTitle;

  /// No description provided for @admin2faSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email'**
  String get admin2faSubtitle;

  /// No description provided for @admin2faCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String admin2faCodeSent(String email);

  /// No description provided for @admin2faVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get admin2faVerify;

  /// No description provided for @admin2faResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get admin2faResend;

  /// No description provided for @admin2faResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String admin2faResendIn(String seconds);

  /// No description provided for @admin2faInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get admin2faInvalidCode;

  /// No description provided for @admin2faExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Please request a new one.'**
  String get admin2faExpired;

  /// No description provided for @admin2faMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please request a new code.'**
  String get admin2faMaxAttempts;

  /// No description provided for @admin2faSending.
  ///
  /// In en, this message translates to:
  /// **'Sending code...'**
  String get admin2faSending;

  /// No description provided for @admin2faSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get admin2faSignOut;

  /// No description provided for @twoFaToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA Authenticator'**
  String get twoFaToggleTitle;

  /// No description provided for @twoFaToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require email code verification on every login'**
  String get twoFaToggleSubtitle;

  /// No description provided for @twoFaEnabled.
  ///
  /// In en, this message translates to:
  /// **'2FA authentication enabled'**
  String get twoFaEnabled;

  /// No description provided for @twoFaDisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA authentication disabled'**
  String get twoFaDisabled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
