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

  /// No description provided for @abandonGame.
  ///
  /// In en, this message translates to:
  /// **'Abandon Game'**
  String get abandonGame;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @aboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMeTitle;

  /// No description provided for @academicCategory.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get academicCategory;

  /// No description provided for @acceptPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Privacy Policy'**
  String get acceptPrivacyPolicy;

  /// No description provided for @acceptProfiling.
  ///
  /// In en, this message translates to:
  /// **'I consent to profiling for personalized recommendations'**
  String get acceptProfiling;

  /// No description provided for @acceptTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Terms and Conditions'**
  String get acceptTermsAndConditions;

  /// No description provided for @acceptThirdPartyData.
  ///
  /// In en, this message translates to:
  /// **'I consent to sharing my data with third parties'**
  String get acceptThirdPartyData;

  /// No description provided for @accessGranted.
  ///
  /// In en, this message translates to:
  /// **'Access Granted!'**
  String get accessGranted;

  /// No description provided for @accessGrantedBody.
  ///
  /// In en, this message translates to:
  /// **'GreenGo is now live! As a {tierName}, you now have full access to all features.'**
  String accessGrantedBody(Object tierName);

  /// No description provided for @accountApproved.
  ///
  /// In en, this message translates to:
  /// **'Account Approved'**
  String get accountApproved;

  /// No description provided for @accountApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your GreenGo account has been approved. Welcome to the community!'**
  String get accountApprovedBody;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to verify your account.'**
  String get accountCreatedSuccess;

  /// No description provided for @accountPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get accountPendingApproval;

  /// No description provided for @accountRejected.
  ///
  /// In en, this message translates to:
  /// **'Account Rejected'**
  String get accountRejected;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @accountUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Account Under Review'**
  String get accountUnderReview;

  /// No description provided for @achievementProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String achievementProgressLabel(String current, String total);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your badges and progress'**
  String get achievementsSubtitle;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @addBio.
  ///
  /// In en, this message translates to:
  /// **'Add a bio'**
  String get addBio;

  /// No description provided for @addDealBreakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Deal Breaker'**
  String get addDealBreakerTitle;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @adjustPreferences.
  ///
  /// In en, this message translates to:
  /// **'Adjust Preferences'**
  String get adjustPreferences;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @admin2faCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String admin2faCodeSent(String email);

  /// No description provided for @admin2faExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Please request a new one.'**
  String get admin2faExpired;

  /// No description provided for @admin2faInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get admin2faInvalidCode;

  /// No description provided for @admin2faMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please request a new code.'**
  String get admin2faMaxAttempts;

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

  /// No description provided for @admin2faSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email'**
  String get admin2faSubtitle;

  /// No description provided for @admin2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Verification'**
  String get admin2faTitle;

  /// No description provided for @admin2faVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get admin2faVerify;

  /// No description provided for @adminAccessDates.
  ///
  /// In en, this message translates to:
  /// **'Access Dates:'**
  String get adminAccessDates;

  /// No description provided for @adminAccountLockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account locked successfully'**
  String get adminAccountLockedSuccessfully;

  /// No description provided for @adminAccountUnlockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account unlocked successfully'**
  String get adminAccountUnlockedSuccessfully;

  /// No description provided for @adminAccountsCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts cannot be deleted'**
  String get adminAccountsCannotBeDeleted;

  /// No description provided for @adminAchievementCount.
  ///
  /// In en, this message translates to:
  /// **'{count} achievements'**
  String adminAchievementCount(Object count);

  /// No description provided for @adminAchievementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Achievement updated'**
  String get adminAchievementUpdated;

  /// No description provided for @adminAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get adminAchievements;

  /// No description provided for @adminAchievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage achievements and badges'**
  String get adminAchievementsSubtitle;

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get adminActive;

  /// No description provided for @adminActiveCount.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String adminActiveCount(Object count);

  /// No description provided for @adminActiveEvent.
  ///
  /// In en, this message translates to:
  /// **'Active Event'**
  String get adminActiveEvent;

  /// No description provided for @adminActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get adminActiveUsers;

  /// No description provided for @adminAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminAdd;

  /// No description provided for @adminAddCoins.
  ///
  /// In en, this message translates to:
  /// **'Add Coins'**
  String get adminAddCoins;

  /// No description provided for @adminAddPackage.
  ///
  /// In en, this message translates to:
  /// **'Add Package'**
  String get adminAddPackage;

  /// No description provided for @adminAddResolutionNote.
  ///
  /// In en, this message translates to:
  /// **'Add a resolution note...'**
  String get adminAddResolutionNote;

  /// No description provided for @adminAddSingleEmail.
  ///
  /// In en, this message translates to:
  /// **'Add Single Email'**
  String get adminAddSingleEmail;

  /// No description provided for @adminAddedCoinsToUser.
  ///
  /// In en, this message translates to:
  /// **'Added {amount} coins to user'**
  String adminAddedCoinsToUser(Object amount);

  /// No description provided for @adminAddedDate.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String adminAddedDate(Object date);

  /// No description provided for @adminAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get adminAdvancedFilters;

  /// No description provided for @adminAgeAndGender.
  ///
  /// In en, this message translates to:
  /// **'{age} years old - {gender}'**
  String adminAgeAndGender(Object age, Object gender);

  /// No description provided for @adminAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminAll;

  /// No description provided for @adminAllReports.
  ///
  /// In en, this message translates to:
  /// **'All Reports'**
  String get adminAllReports;

  /// No description provided for @adminAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminAmount;

  /// No description provided for @adminAnalyticsAndReports.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get adminAnalyticsAndReports;

  /// No description provided for @adminAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get adminAppSettings;

  /// No description provided for @adminAppSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'General application settings'**
  String get adminAppSettingsSubtitle;

  /// No description provided for @adminApproveSelected.
  ///
  /// In en, this message translates to:
  /// **'Approve Selected'**
  String get adminApproveSelected;

  /// No description provided for @adminAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to me'**
  String get adminAssignToMe;

  /// No description provided for @adminAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get adminAssigned;

  /// No description provided for @adminAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get adminAvailable;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get adminBadge;

  /// No description provided for @adminBaseCoins.
  ///
  /// In en, this message translates to:
  /// **'Base Coins'**
  String get adminBaseCoins;

  /// No description provided for @adminBaseXp.
  ///
  /// In en, this message translates to:
  /// **'Base XP'**
  String get adminBaseXp;

  /// No description provided for @adminBonusCoins.
  ///
  /// In en, this message translates to:
  /// **'+{amount} bonus coins'**
  String adminBonusCoins(Object amount);

  /// No description provided for @adminBonusCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus Coins'**
  String get adminBonusCoinsLabel;

  /// No description provided for @adminBonusMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} bonus'**
  String adminBonusMinutes(Object minutes);

  /// No description provided for @adminBrowseProfilesAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles anonymously'**
  String get adminBrowseProfilesAnonymously;

  /// No description provided for @adminCanSendMedia.
  ///
  /// In en, this message translates to:
  /// **'Can Send Media'**
  String get adminCanSendMedia;

  /// No description provided for @adminChallengeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} challenges'**
  String adminChallengeCount(Object count);

  /// No description provided for @adminChallengeCreationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Challenge creation interface coming soon.'**
  String get adminChallengeCreationComingSoon;

  /// No description provided for @adminChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get adminChallenges;

  /// No description provided for @adminChangesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get adminChangesSaved;

  /// No description provided for @adminChatWithReporter.
  ///
  /// In en, this message translates to:
  /// **'Chat with Reporter'**
  String get adminChatWithReporter;

  /// No description provided for @adminClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get adminClear;

  /// No description provided for @adminClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get adminClosed;

  /// No description provided for @adminCoinAmount.
  ///
  /// In en, this message translates to:
  /// **'Coin Amount'**
  String get adminCoinAmount;

  /// No description provided for @adminCoinAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} Coins'**
  String adminCoinAmountLabel(Object amount);

  /// No description provided for @adminCoinCost.
  ///
  /// In en, this message translates to:
  /// **'Coin Cost'**
  String get adminCoinCost;

  /// No description provided for @adminCoinManagement.
  ///
  /// In en, this message translates to:
  /// **'Coin Management'**
  String get adminCoinManagement;

  /// No description provided for @adminCoinManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage coin packages and user balances'**
  String get adminCoinManagementSubtitle;

  /// No description provided for @adminCoinPackages.
  ///
  /// In en, this message translates to:
  /// **'Coin Packages'**
  String get adminCoinPackages;

  /// No description provided for @adminCoinReward.
  ///
  /// In en, this message translates to:
  /// **'Coin Reward'**
  String get adminCoinReward;

  /// No description provided for @adminComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{route} coming soon'**
  String adminComingSoon(Object route);

  /// No description provided for @adminConfigurationsResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Configurations reset to defaults. Save to apply.'**
  String get adminConfigurationsResetToDefaults;

  /// No description provided for @adminConfigureLimitsAndFeatures.
  ///
  /// In en, this message translates to:
  /// **'Configure limits and features'**
  String get adminConfigureLimitsAndFeatures;

  /// No description provided for @adminConfigureMilestoneRewards.
  ///
  /// In en, this message translates to:
  /// **'Configure milestone rewards for consecutive logins'**
  String get adminConfigureMilestoneRewards;

  /// No description provided for @adminCreateChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create Challenge'**
  String get adminCreateChallenge;

  /// No description provided for @adminCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get adminCreateEvent;

  /// No description provided for @adminCreateNewChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create New Challenge'**
  String get adminCreateNewChallenge;

  /// No description provided for @adminCreateSeasonalEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Seasonal Event'**
  String get adminCreateSeasonalEvent;

  /// No description provided for @adminCsvFormat.
  ///
  /// In en, this message translates to:
  /// **'CSV Format:'**
  String get adminCsvFormat;

  /// No description provided for @adminCsvFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'One email per line, or comma-separated values. Quotes are automatically removed. Invalid emails are skipped.'**
  String get adminCsvFormatDescription;

  /// No description provided for @adminCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get adminCurrentBalance;

  /// No description provided for @adminDailyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenges'**
  String get adminDailyChallenges;

  /// No description provided for @adminDailyChallengesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure daily challenges and rewards'**
  String get adminDailyChallengesSubtitle;

  /// No description provided for @adminDailyLimits.
  ///
  /// In en, this message translates to:
  /// **'Daily Limits'**
  String get adminDailyLimits;

  /// No description provided for @adminDailyLoginRewards.
  ///
  /// In en, this message translates to:
  /// **'Daily Login Rewards'**
  String get adminDailyLoginRewards;

  /// No description provided for @adminDailyMessages.
  ///
  /// In en, this message translates to:
  /// **'Daily Messages'**
  String get adminDailyMessages;

  /// No description provided for @adminDailySuperLikes.
  ///
  /// In en, this message translates to:
  /// **'Daily Priority Connects'**
  String get adminDailySuperLikes;

  /// No description provided for @adminDailySwipes.
  ///
  /// In en, this message translates to:
  /// **'Daily Swipes'**
  String get adminDailySwipes;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get adminDate;

  /// No description provided for @adminDeletePackageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{amount} Coins\" package?'**
  String adminDeletePackageConfirm(Object amount);

  /// No description provided for @adminDeletePackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Package?'**
  String get adminDeletePackageTitle;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get adminDeselectAll;

  /// No description provided for @adminDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get adminDisabled;

  /// No description provided for @adminDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminDismiss;

  /// No description provided for @adminDismissReport.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Report'**
  String get adminDismissReport;

  /// No description provided for @adminDismissReportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to dismiss this report?'**
  String get adminDismissReportConfirm;

  /// No description provided for @adminEarlyAccessDate.
  ///
  /// In en, this message translates to:
  /// **'March 14, 2026'**
  String get adminEarlyAccessDate;

  /// No description provided for @adminEarlyAccessDates.
  ///
  /// In en, this message translates to:
  /// **'Users in this list get access on March 14, 2026.\nAll other users get access on April 14, 2026.'**
  String get adminEarlyAccessDates;

  /// No description provided for @adminEarlyAccessInList.
  ///
  /// In en, this message translates to:
  /// **'Early Access (in list)'**
  String get adminEarlyAccessInList;

  /// No description provided for @adminEarlyAccessInfo.
  ///
  /// In en, this message translates to:
  /// **'Early Access Info'**
  String get adminEarlyAccessInfo;

  /// No description provided for @adminEarlyAccessList.
  ///
  /// In en, this message translates to:
  /// **'Early Access List'**
  String get adminEarlyAccessList;

  /// No description provided for @adminEarlyAccessProgram.
  ///
  /// In en, this message translates to:
  /// **'Early Access Program'**
  String get adminEarlyAccessProgram;

  /// No description provided for @adminEditAchievement.
  ///
  /// In en, this message translates to:
  /// **'Edit Achievement'**
  String get adminEditAchievement;

  /// No description provided for @adminEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String adminEditItem(Object name);

  /// No description provided for @adminEditMilestone.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String adminEditMilestone(Object name);

  /// No description provided for @adminEditPackage.
  ///
  /// In en, this message translates to:
  /// **'Edit Package'**
  String get adminEditPackage;

  /// No description provided for @adminEmailAddedToEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'{email} added to early access list'**
  String adminEmailAddedToEarlyAccess(Object email);

  /// No description provided for @adminEmailCount.
  ///
  /// In en, this message translates to:
  /// **'{count} emails'**
  String adminEmailCount(Object count);

  /// No description provided for @adminEmailList.
  ///
  /// In en, this message translates to:
  /// **'Email List'**
  String get adminEmailList;

  /// No description provided for @adminEmailRemovedFromEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'{email} removed from early access list'**
  String adminEmailRemovedFromEarlyAccess(Object email);

  /// No description provided for @adminEnableAdvancedFilteringOptions.
  ///
  /// In en, this message translates to:
  /// **'Enable advanced filtering options'**
  String get adminEnableAdvancedFilteringOptions;

  /// No description provided for @adminEngagementReports.
  ///
  /// In en, this message translates to:
  /// **'Engagement Reports'**
  String get adminEngagementReports;

  /// No description provided for @adminEngagementReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View matching and messaging statistics'**
  String get adminEngagementReportsSubtitle;

  /// No description provided for @adminEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get adminEnterEmailAddress;

  /// No description provided for @adminEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get adminEnterValidAmount;

  /// No description provided for @adminEnterValidCoinAmountAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid coin amount and price'**
  String get adminEnterValidCoinAmountAndPrice;

  /// No description provided for @adminErrorAddingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error adding email: {error}'**
  String adminErrorAddingEmail(Object error);

  /// No description provided for @adminErrorLoadingContext.
  ///
  /// In en, this message translates to:
  /// **'Error loading context: {error}'**
  String adminErrorLoadingContext(Object error);

  /// No description provided for @adminErrorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String adminErrorLoadingData(Object error);

  /// No description provided for @adminErrorOpeningChat.
  ///
  /// In en, this message translates to:
  /// **'Error opening chat: {error}'**
  String adminErrorOpeningChat(Object error);

  /// No description provided for @adminErrorRemovingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error removing email: {error}'**
  String adminErrorRemovingEmail(Object error);

  /// No description provided for @adminErrorSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String adminErrorSnapshot(Object error);

  /// No description provided for @adminErrorUploadingFile.
  ///
  /// In en, this message translates to:
  /// **'Error uploading file: {error}'**
  String adminErrorUploadingFile(Object error);

  /// No description provided for @adminErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get adminErrors;

  /// No description provided for @adminEventCreationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Event creation interface coming soon.'**
  String get adminEventCreationComingSoon;

  /// No description provided for @adminEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get adminEvents;

  /// No description provided for @adminFailedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String adminFailedToSave(Object error);

  /// No description provided for @adminFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get adminFeatures;

  /// No description provided for @adminFilterByInterests.
  ///
  /// In en, this message translates to:
  /// **'Filter by interests'**
  String get adminFilterByInterests;

  /// No description provided for @adminFilterBySpecificLocation.
  ///
  /// In en, this message translates to:
  /// **'Filter by specific location'**
  String get adminFilterBySpecificLocation;

  /// No description provided for @adminFilterBySpokenLanguages.
  ///
  /// In en, this message translates to:
  /// **'Filter by spoken languages'**
  String get adminFilterBySpokenLanguages;

  /// No description provided for @adminFilterByVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by verification status'**
  String get adminFilterByVerificationStatus;

  /// No description provided for @adminFilterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get adminFilterOptions;

  /// No description provided for @adminGamification.
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get adminGamification;

  /// No description provided for @adminGamificationAndRewards.
  ///
  /// In en, this message translates to:
  /// **'Gamification & Rewards'**
  String get adminGamificationAndRewards;

  /// No description provided for @adminGeneralAccess.
  ///
  /// In en, this message translates to:
  /// **'General Access'**
  String get adminGeneralAccess;

  /// No description provided for @adminGeneralAccessDate.
  ///
  /// In en, this message translates to:
  /// **'April 14, 2026'**
  String get adminGeneralAccessDate;

  /// No description provided for @adminHigherPriorityDescription.
  ///
  /// In en, this message translates to:
  /// **'Higher priority = shown first in discovery'**
  String get adminHigherPriorityDescription;

  /// No description provided for @adminImportResult.
  ///
  /// In en, this message translates to:
  /// **'Import Result'**
  String get adminImportResult;

  /// No description provided for @adminInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get adminInProgress;

  /// No description provided for @adminIncognitoMode.
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get adminIncognitoMode;

  /// No description provided for @adminInterestFilter.
  ///
  /// In en, this message translates to:
  /// **'Interest Filter'**
  String get adminInterestFilter;

  /// No description provided for @adminInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get adminInvoices;

  /// No description provided for @adminLanguageFilter.
  ///
  /// In en, this message translates to:
  /// **'Language Filter'**
  String get adminLanguageFilter;

  /// No description provided for @adminLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get adminLoading;

  /// No description provided for @adminLocationFilter.
  ///
  /// In en, this message translates to:
  /// **'Location Filter'**
  String get adminLocationFilter;

  /// No description provided for @adminLockAccount.
  ///
  /// In en, this message translates to:
  /// **'Lock Account'**
  String get adminLockAccount;

  /// No description provided for @adminLockAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Lock account for user {userId}...?'**
  String adminLockAccountConfirm(Object userId);

  /// No description provided for @adminLockDuration.
  ///
  /// In en, this message translates to:
  /// **'Lock Duration'**
  String get adminLockDuration;

  /// No description provided for @adminLockReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String adminLockReasonLabel(Object reason);

  /// No description provided for @adminLockedCount.
  ///
  /// In en, this message translates to:
  /// **'Locked ({count})'**
  String adminLockedCount(Object count);

  /// No description provided for @adminLockedDate.
  ///
  /// In en, this message translates to:
  /// **'Locked: {date}'**
  String adminLockedDate(Object date);

  /// No description provided for @adminLoginStreakSystem.
  ///
  /// In en, this message translates to:
  /// **'Login Streak System'**
  String get adminLoginStreakSystem;

  /// No description provided for @adminLoginStreaks.
  ///
  /// In en, this message translates to:
  /// **'Login Streaks'**
  String get adminLoginStreaks;

  /// No description provided for @adminLoginStreaksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure streak milestones and rewards'**
  String get adminLoginStreaksSubtitle;

  /// No description provided for @adminManageAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your GreenGo application settings'**
  String get adminManageAppSettings;

  /// No description provided for @adminMatchPriority.
  ///
  /// In en, this message translates to:
  /// **'Match Priority'**
  String get adminMatchPriority;

  /// No description provided for @adminMatchingAndVisibility.
  ///
  /// In en, this message translates to:
  /// **'Matching & Visibility'**
  String get adminMatchingAndVisibility;

  /// No description provided for @adminMessageContext.
  ///
  /// In en, this message translates to:
  /// **'Message Context (50 before/after)'**
  String get adminMessageContext;

  /// No description provided for @adminMilestoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Milestone updated'**
  String get adminMilestoneUpdated;

  /// No description provided for @adminMoreErrors.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more errors'**
  String adminMoreErrors(Object count);

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminName;

  /// No description provided for @adminNinetyDays.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get adminNinetyDays;

  /// No description provided for @adminNoEmailsInEarlyAccessList.
  ///
  /// In en, this message translates to:
  /// **'No emails in early access list'**
  String get adminNoEmailsInEarlyAccessList;

  /// No description provided for @adminNoInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get adminNoInvoicesFound;

  /// No description provided for @adminNoLockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'No locked accounts'**
  String get adminNoLockedAccounts;

  /// No description provided for @adminNoMatchingEmailsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching emails found'**
  String get adminNoMatchingEmailsFound;

  /// No description provided for @adminNoOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get adminNoOrdersFound;

  /// No description provided for @adminNoPendingReports.
  ///
  /// In en, this message translates to:
  /// **'No pending reports'**
  String get adminNoPendingReports;

  /// No description provided for @adminNoReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get adminNoReportsYet;

  /// No description provided for @adminNoTickets.
  ///
  /// In en, this message translates to:
  /// **'No {status} tickets'**
  String adminNoTickets(Object status);

  /// No description provided for @adminNoValidEmailsFound.
  ///
  /// In en, this message translates to:
  /// **'No valid email addresses found in the file'**
  String get adminNoValidEmailsFound;

  /// No description provided for @adminNoVerificationHistory.
  ///
  /// In en, this message translates to:
  /// **'No verification history'**
  String get adminNoVerificationHistory;

  /// No description provided for @adminOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get adminOneDay;

  /// No description provided for @adminOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminOpen;

  /// No description provided for @adminOpenCount.
  ///
  /// In en, this message translates to:
  /// **'Open ({count})'**
  String adminOpenCount(Object count);

  /// No description provided for @adminOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get adminOpenTickets;

  /// No description provided for @adminOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get adminOrderDetails;

  /// No description provided for @adminOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get adminOrderId;

  /// No description provided for @adminOrderRefunded.
  ///
  /// In en, this message translates to:
  /// **'Order refunded'**
  String get adminOrderRefunded;

  /// No description provided for @adminOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get adminOrders;

  /// No description provided for @adminPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get adminPackages;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get adminPayment;

  /// No description provided for @adminPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminPending;

  /// No description provided for @adminPendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String adminPendingCount(Object count);

  /// No description provided for @adminPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get adminPermanent;

  /// No description provided for @adminPleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get adminPleaseEnterValidEmail;

  /// No description provided for @adminPriceUsd.
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get adminPriceUsd;

  /// No description provided for @adminProductIdIap.
  ///
  /// In en, this message translates to:
  /// **'Product ID (for IAP)'**
  String get adminProductIdIap;

  /// No description provided for @adminProfileVisitors.
  ///
  /// In en, this message translates to:
  /// **'Profile Visitors'**
  String get adminProfileVisitors;

  /// No description provided for @adminPromotional.
  ///
  /// In en, this message translates to:
  /// **'Promotional'**
  String get adminPromotional;

  /// No description provided for @adminPromotionalPackage.
  ///
  /// In en, this message translates to:
  /// **'Promotional Package'**
  String get adminPromotionalPackage;

  /// No description provided for @adminPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get adminPromotions;

  /// No description provided for @adminPromotionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage special offers and promotions'**
  String get adminPromotionsSubtitle;

  /// No description provided for @adminProvideReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason'**
  String get adminProvideReason;

  /// No description provided for @adminReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read Receipts'**
  String get adminReadReceipts;

  /// No description provided for @adminReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminReason;

  /// No description provided for @adminReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String adminReasonLabel(Object reason);

  /// No description provided for @adminReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get adminReasonRequired;

  /// No description provided for @adminRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get adminRefund;

  /// No description provided for @adminRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRemove;

  /// No description provided for @adminRemoveCoins.
  ///
  /// In en, this message translates to:
  /// **'Remove Coins'**
  String get adminRemoveCoins;

  /// No description provided for @adminRemoveEmail.
  ///
  /// In en, this message translates to:
  /// **'Remove Email'**
  String get adminRemoveEmail;

  /// No description provided for @adminRemoveEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{email}\" from the early access list?'**
  String adminRemoveEmailConfirm(Object email);

  /// No description provided for @adminRemovedCoinsFromUser.
  ///
  /// In en, this message translates to:
  /// **'Removed {amount} coins from user'**
  String adminRemovedCoinsFromUser(Object amount);

  /// No description provided for @adminReportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Report dismissed'**
  String get adminReportDismissed;

  /// No description provided for @adminReportFollowupStarted.
  ///
  /// In en, this message translates to:
  /// **'Report Follow-up conversation started'**
  String get adminReportFollowupStarted;

  /// No description provided for @adminReportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reported Message:'**
  String get adminReportedMessage;

  /// No description provided for @adminReportedMessageMarker.
  ///
  /// In en, this message translates to:
  /// **'^ REPORTED MESSAGE'**
  String get adminReportedMessageMarker;

  /// No description provided for @adminReportedUserIdShort.
  ///
  /// In en, this message translates to:
  /// **'Reported User ID: {userId}...'**
  String adminReportedUserIdShort(Object userId);

  /// No description provided for @adminReporterIdShort.
  ///
  /// In en, this message translates to:
  /// **'Reporter ID: {reporterId}...'**
  String adminReporterIdShort(Object reporterId);

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminReportsManagement.
  ///
  /// In en, this message translates to:
  /// **'Reports Management'**
  String get adminReportsManagement;

  /// No description provided for @adminRequestNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Request New Photo'**
  String get adminRequestNewPhoto;

  /// No description provided for @adminRequiredCount.
  ///
  /// In en, this message translates to:
  /// **'Required Count'**
  String get adminRequiredCount;

  /// No description provided for @adminRequiresCount.
  ///
  /// In en, this message translates to:
  /// **'Requires: {count}'**
  String adminRequiresCount(Object count);

  /// No description provided for @adminReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get adminReset;

  /// No description provided for @adminResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get adminResetToDefaults;

  /// No description provided for @adminResetToDefaultsConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will reset all tier configurations to their default values. This action cannot be undone.'**
  String get adminResetToDefaultsConfirm;

  /// No description provided for @adminResetToDefaultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults?'**
  String get adminResetToDefaultsTitle;

  /// No description provided for @adminResolutionNote.
  ///
  /// In en, this message translates to:
  /// **'Resolution Note'**
  String get adminResolutionNote;

  /// No description provided for @adminResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get adminResolve;

  /// No description provided for @adminResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adminResolved;

  /// No description provided for @adminResolvedCount.
  ///
  /// In en, this message translates to:
  /// **'Resolved ({count})'**
  String adminResolvedCount(Object count);

  /// No description provided for @adminRevenueAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Revenue Analytics'**
  String get adminRevenueAnalytics;

  /// No description provided for @adminRevenueAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track purchases and revenue'**
  String get adminRevenueAnalyticsSubtitle;

  /// No description provided for @adminReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed By'**
  String get adminReviewedBy;

  /// No description provided for @adminRewardAmount.
  ///
  /// In en, this message translates to:
  /// **'Reward Amount'**
  String get adminRewardAmount;

  /// No description provided for @adminSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get adminSaving;

  /// No description provided for @adminScheduledEvents.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Events'**
  String get adminScheduledEvents;

  /// No description provided for @adminSearchByUserIdOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by user ID or email'**
  String get adminSearchByUserIdOrEmail;

  /// No description provided for @adminSearchEmails.
  ///
  /// In en, this message translates to:
  /// **'Search emails...'**
  String get adminSearchEmails;

  /// No description provided for @adminSearchForUserCoinBalance.
  ///
  /// In en, this message translates to:
  /// **'Search for a user to manage their coin balance'**
  String get adminSearchForUserCoinBalance;

  /// No description provided for @adminSearchOrders.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get adminSearchOrders;

  /// No description provided for @adminSeeWhenMessagesAreRead.
  ///
  /// In en, this message translates to:
  /// **'See when messages are read'**
  String get adminSeeWhenMessagesAreRead;

  /// No description provided for @adminSeeWhoVisitedProfile.
  ///
  /// In en, this message translates to:
  /// **'See who visited their profile'**
  String get adminSeeWhoVisitedProfile;

  /// No description provided for @adminSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get adminSelectAll;

  /// No description provided for @adminSelectCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Select CSV File'**
  String get adminSelectCsvFile;

  /// No description provided for @adminSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String adminSelectedCount(Object count);

  /// No description provided for @adminSendImagesAndVideosInChat.
  ///
  /// In en, this message translates to:
  /// **'Send images and videos in chat'**
  String get adminSendImagesAndVideosInChat;

  /// No description provided for @adminSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get adminSevenDays;

  /// No description provided for @adminSpendItems.
  ///
  /// In en, this message translates to:
  /// **'Spend Items'**
  String get adminSpendItems;

  /// No description provided for @adminStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get adminStatistics;

  /// No description provided for @adminStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminStatus;

  /// No description provided for @adminStreakMilestones.
  ///
  /// In en, this message translates to:
  /// **'Streak Milestones'**
  String get adminStreakMilestones;

  /// No description provided for @adminStreakMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Streak Multiplier'**
  String get adminStreakMultiplier;

  /// No description provided for @adminStreakMultiplierValue.
  ///
  /// In en, this message translates to:
  /// **'1.5x per day'**
  String get adminStreakMultiplierValue;

  /// No description provided for @adminStreaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get adminStreaks;

  /// No description provided for @adminSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get adminSupport;

  /// No description provided for @adminSupportAgents.
  ///
  /// In en, this message translates to:
  /// **'Support Agents'**
  String get adminSupportAgents;

  /// No description provided for @adminSupportAgentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage support agent accounts'**
  String get adminSupportAgentsSubtitle;

  /// No description provided for @adminSupportManagement.
  ///
  /// In en, this message translates to:
  /// **'Support Management'**
  String get adminSupportManagement;

  /// No description provided for @adminSupportRequest.
  ///
  /// In en, this message translates to:
  /// **'Support Request'**
  String get adminSupportRequest;

  /// No description provided for @adminSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get adminSupportTickets;

  /// No description provided for @adminSupportTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage user support conversations'**
  String get adminSupportTicketsSubtitle;

  /// No description provided for @adminSystemConfiguration.
  ///
  /// In en, this message translates to:
  /// **'System Configuration'**
  String get adminSystemConfiguration;

  /// No description provided for @adminThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get adminThirtyDays;

  /// No description provided for @adminTicketAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Ticket assigned to you'**
  String get adminTicketAssignedToYou;

  /// No description provided for @adminTicketAssignment.
  ///
  /// In en, this message translates to:
  /// **'Ticket Assignment'**
  String get adminTicketAssignment;

  /// No description provided for @adminTicketAssignmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign tickets to support agents'**
  String get adminTicketAssignmentSubtitle;

  /// No description provided for @adminTicketClosed.
  ///
  /// In en, this message translates to:
  /// **'Ticket closed'**
  String get adminTicketClosed;

  /// No description provided for @adminTicketResolved.
  ///
  /// In en, this message translates to:
  /// **'Ticket resolved'**
  String get adminTicketResolved;

  /// No description provided for @adminTierConfigsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tier configurations saved successfully'**
  String get adminTierConfigsSavedSuccessfully;

  /// No description provided for @adminTierFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get adminTierFree;

  /// No description provided for @adminTierGold.
  ///
  /// In en, this message translates to:
  /// **'GOLD'**
  String get adminTierGold;

  /// No description provided for @adminTierManagement.
  ///
  /// In en, this message translates to:
  /// **'Tier Management'**
  String get adminTierManagement;

  /// No description provided for @adminTierManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure tier limits and features'**
  String get adminTierManagementSubtitle;

  /// No description provided for @adminTierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'PLATINUM'**
  String get adminTierPlatinum;

  /// No description provided for @adminTierSilver.
  ///
  /// In en, this message translates to:
  /// **'SILVER'**
  String get adminTierSilver;

  /// No description provided for @adminToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get adminToday;

  /// No description provided for @adminTotalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Total Minutes'**
  String get adminTotalMinutes;

  /// No description provided for @adminType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminType;

  /// No description provided for @adminUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get adminUnassigned;

  /// No description provided for @adminUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get adminUnknown;

  /// No description provided for @adminUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get adminUnlimited;

  /// No description provided for @adminUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get adminUnlock;

  /// No description provided for @adminUnlockAccount.
  ///
  /// In en, this message translates to:
  /// **'Unlock Account'**
  String get adminUnlockAccount;

  /// No description provided for @adminUnlockAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unlock this account?'**
  String get adminUnlockAccountConfirm;

  /// No description provided for @adminUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get adminUnresolved;

  /// No description provided for @adminUploadCsvDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a CSV file containing email addresses (one per line or comma-separated)'**
  String get adminUploadCsvDescription;

  /// No description provided for @adminUploadCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV File'**
  String get adminUploadCsvFile;

  /// No description provided for @adminUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get adminUploading;

  /// No description provided for @adminUseVideoCallingFeature.
  ///
  /// In en, this message translates to:
  /// **'Use video calling feature'**
  String get adminUseVideoCallingFeature;

  /// No description provided for @adminUsedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Used Minutes'**
  String get adminUsedMinutes;

  /// No description provided for @adminUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminUser;

  /// No description provided for @adminUserAnalytics.
  ///
  /// In en, this message translates to:
  /// **'User Analytics'**
  String get adminUserAnalytics;

  /// No description provided for @adminUserAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View user engagement and growth metrics'**
  String get adminUserAnalyticsSubtitle;

  /// No description provided for @adminUserBalance.
  ///
  /// In en, this message translates to:
  /// **'User Balance'**
  String get adminUserBalance;

  /// No description provided for @adminUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get adminUserId;

  /// No description provided for @adminUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID: {userId}'**
  String adminUserIdLabel(Object userId);

  /// No description provided for @adminUserIdShort.
  ///
  /// In en, this message translates to:
  /// **'User: {userId}...'**
  String adminUserIdShort(Object userId);

  /// No description provided for @adminUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get adminUserManagement;

  /// No description provided for @adminUserModeration.
  ///
  /// In en, this message translates to:
  /// **'User Moderation'**
  String get adminUserModeration;

  /// No description provided for @adminUserModerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage user bans and suspensions'**
  String get adminUserModerationSubtitle;

  /// No description provided for @adminUserReports.
  ///
  /// In en, this message translates to:
  /// **'User Reports'**
  String get adminUserReports;

  /// No description provided for @adminUserReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and handle user reports'**
  String get adminUserReportsSubtitle;

  /// No description provided for @adminUserSenderIdShort.
  ///
  /// In en, this message translates to:
  /// **'User: {senderId}...'**
  String adminUserSenderIdShort(Object senderId);

  /// No description provided for @adminUserVerifications.
  ///
  /// In en, this message translates to:
  /// **'User Verifications'**
  String get adminUserVerifications;

  /// No description provided for @adminUserVerificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approve or reject user verification requests'**
  String get adminUserVerificationsSubtitle;

  /// No description provided for @adminVerificationFilter.
  ///
  /// In en, this message translates to:
  /// **'Verification Filter'**
  String get adminVerificationFilter;

  /// No description provided for @adminVerifications.
  ///
  /// In en, this message translates to:
  /// **'Verifications'**
  String get adminVerifications;

  /// No description provided for @adminVideoChat.
  ///
  /// In en, this message translates to:
  /// **'Video Chat'**
  String get adminVideoChat;

  /// No description provided for @adminVideoCoinPackages.
  ///
  /// In en, this message translates to:
  /// **'Video Coin Packages'**
  String get adminVideoCoinPackages;

  /// No description provided for @adminVideoCoins.
  ///
  /// In en, this message translates to:
  /// **'Video Coins'**
  String get adminVideoCoins;

  /// No description provided for @adminVideoMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} Minutes'**
  String adminVideoMinutesLabel(Object minutes);

  /// No description provided for @adminViewContext.
  ///
  /// In en, this message translates to:
  /// **'View Context'**
  String get adminViewContext;

  /// No description provided for @adminViewDocument.
  ///
  /// In en, this message translates to:
  /// **'View Document'**
  String get adminViewDocument;

  /// No description provided for @adminViolationOfCommunityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Violation of community guidelines'**
  String get adminViolationOfCommunityGuidelines;

  /// No description provided for @adminWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get adminWaiting;

  /// No description provided for @adminWaitingCount.
  ///
  /// In en, this message translates to:
  /// **'Waiting ({count})'**
  String adminWaitingCount(Object count);

  /// No description provided for @adminWeeklyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Weekly Challenges'**
  String get adminWeeklyChallenges;

  /// No description provided for @adminWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Admin'**
  String get adminWelcome;

  /// No description provided for @adminXpReward.
  ///
  /// In en, this message translates to:
  /// **'XP Reward'**
  String get adminXpReward;

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get ageRange;

  /// No description provided for @aiCoachBenefitAllChapters.
  ///
  /// In en, this message translates to:
  /// **'All learning chapters unlocked'**
  String get aiCoachBenefitAllChapters;

  /// No description provided for @aiCoachBenefitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Real-time grammar & pronunciation feedback'**
  String get aiCoachBenefitFeedback;

  /// No description provided for @aiCoachBenefitPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized learning path'**
  String get aiCoachBenefitPersonalized;

  /// No description provided for @aiCoachBenefitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI conversation practice'**
  String get aiCoachBenefitUnlimited;

  /// No description provided for @aiCoachLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get aiCoachLabel;

  /// No description provided for @aiCoachTrialEnded.
  ///
  /// In en, this message translates to:
  /// **'Your free trial of AI Coach has ended.'**
  String get aiCoachTrialEnded;

  /// No description provided for @aiCoachUpgradePrompt.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Silver, Gold, or Platinum to unlock.'**
  String get aiCoachUpgradePrompt;

  /// No description provided for @aiCoachUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Learn More'**
  String get aiCoachUpgradeTitle;

  /// No description provided for @albumNotShared.
  ///
  /// In en, this message translates to:
  /// **'Album not shared with you'**
  String get albumNotShared;

  /// No description provided for @albumOption.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumOption;

  /// No description provided for @albumRevokedMessage.
  ///
  /// In en, this message translates to:
  /// **'{username} revoked album access'**
  String albumRevokedMessage(String username);

  /// No description provided for @albumSharedMessage.
  ///
  /// In en, this message translates to:
  /// **'{username} shared their album with you'**
  String albumSharedMessage(String username);

  /// No description provided for @allCategoriesFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategoriesFilter;

  /// No description provided for @allDealBreakersAdded.
  ///
  /// In en, this message translates to:
  /// **'All deal breakers have been added'**
  String get allDealBreakersAdded;

  /// No description provided for @allLanguagesFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLanguagesFilter;

  /// No description provided for @allPlayersReady.
  ///
  /// In en, this message translates to:
  /// **'All players ready!'**
  String get allPlayersReady;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

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

  /// No description provided for @approveVerification.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveVerification;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

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

  /// No description provided for @authAppleSignInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In coming soon'**
  String get authAppleSignInComingSoon;

  /// No description provided for @authCancelVerification.
  ///
  /// In en, this message translates to:
  /// **'Cancel Verification?'**
  String get authCancelVerification;

  /// No description provided for @authCancelVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out if you cancel the verification.'**
  String get authCancelVerificationBody;

  /// No description provided for @authDisableInSettings.
  ///
  /// In en, this message translates to:
  /// **'You can disable this in Settings > Security'**
  String get authDisableInSettings;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get authErrorEmailAlreadyInUse;

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

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get authErrorNetworkError;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email or nickname. Please check and try again, or sign up.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please use a stronger password.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Please try again.'**
  String get authErrorWrongPassword;

  /// No description provided for @authFailedToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo: {error}'**
  String authFailedToTakePhoto(Object error);

  /// No description provided for @authIdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get authIdentityVerification;

  /// No description provided for @authPleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authPleaseEnterEmail;

  /// No description provided for @authRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get authRetakePhoto;

  /// No description provided for @authSecurityStep.
  ///
  /// In en, this message translates to:
  /// **'This extra security step helps protect your account'**
  String get authSecurityStep;

  /// No description provided for @authSelfieInstruction.
  ///
  /// In en, this message translates to:
  /// **'Look at the camera and tap to capture'**
  String get authSelfieInstruction;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get authSignOut;

  /// No description provided for @authSignOutInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign out instead'**
  String get authSignOutInstead;

  /// No description provided for @authStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get authStay;

  /// No description provided for @authTakeSelfie.
  ///
  /// In en, this message translates to:
  /// **'Take a Selfie'**
  String get authTakeSelfie;

  /// No description provided for @authTakeSelfieToVerify.
  ///
  /// In en, this message translates to:
  /// **'Please take a selfie to verify your identity'**
  String get authTakeSelfieToVerify;

  /// No description provided for @authVerifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get authVerifyAndContinue;

  /// No description provided for @authVerifyWithSelfie.
  ///
  /// In en, this message translates to:
  /// **'Please verify your identity with a selfie'**
  String get authVerifyWithSelfie;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String authWelcomeBack(Object name);

  /// No description provided for @authenticationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get authenticationErrorTitle;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'away'**
  String get away;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @backToLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to Lobby'**
  String get backToLobby;

  /// No description provided for @badgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get badgeLocked;

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get badgeUnlocked;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @betterPhotoRequested.
  ///
  /// In en, this message translates to:
  /// **'Better photo requested'**
  String get betterPhotoRequested;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your profile bio has been saved'**
  String get bioUpdatedMessage;

  /// No description provided for @bioUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bio Updated!'**
  String get bioUpdatedTitle;

  /// No description provided for @blindDateActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate Blind Date Mode'**
  String get blindDateActivate;

  /// No description provided for @blindDateDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get blindDateDeactivate;

  /// No description provided for @blindDateDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll return to normal discovery mode.'**
  String get blindDateDeactivateMessage;

  /// No description provided for @blindDateDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Blind Date Mode?'**
  String get blindDateDeactivateTitle;

  /// No description provided for @blindDateDeactivateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Blind Date Mode'**
  String get blindDateDeactivateTooltip;

  /// No description provided for @blindDateFeatureInstantReveal.
  ///
  /// In en, this message translates to:
  /// **'Instant reveal for {cost} coins'**
  String blindDateFeatureInstantReveal(int cost);

  /// No description provided for @blindDateFeatureNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No profile photos visible initially'**
  String get blindDateFeatureNoPhotos;

  /// No description provided for @blindDateFeaturePersonality.
  ///
  /// In en, this message translates to:
  /// **'Focus on personality & interests'**
  String get blindDateFeaturePersonality;

  /// No description provided for @blindDateFeatureUnlock.
  ///
  /// In en, this message translates to:
  /// **'Photos unlock after chatting'**
  String get blindDateFeatureUnlock;

  /// No description provided for @blindDateGetCoins.
  ///
  /// In en, this message translates to:
  /// **'Get Coins'**
  String get blindDateGetCoins;

  /// No description provided for @blindDateInstantReveal.
  ///
  /// In en, this message translates to:
  /// **'Instant Reveal'**
  String get blindDateInstantReveal;

  /// No description provided for @blindDateInstantRevealMessage.
  ///
  /// In en, this message translates to:
  /// **'Reveal all photos of this match for {cost} coins?'**
  String blindDateInstantRevealMessage(int cost);

  /// No description provided for @blindDateInstantRevealTooltip.
  ///
  /// In en, this message translates to:
  /// **'Instant reveal ({cost} coins)'**
  String blindDateInstantRevealTooltip(int cost);

  /// No description provided for @blindDateInsufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Coins'**
  String get blindDateInsufficientCoins;

  /// No description provided for @blindDateInsufficientCoinsMessage.
  ///
  /// In en, this message translates to:
  /// **'You need {cost} coins to instantly reveal photos.'**
  String blindDateInsufficientCoinsMessage(int cost);

  /// No description provided for @blindDateInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get blindDateInterests;

  /// No description provided for @blindDateKmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String blindDateKmAway(String distance);

  /// No description provided for @blindDateLetsExchange.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Exchange!'**
  String get blindDateLetsExchange;

  /// No description provided for @blindDateMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'You both liked each other! Start chatting to reveal your photos.'**
  String get blindDateMatchMessage;

  /// No description provided for @blindDateMessageProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} messages'**
  String blindDateMessageProgress(int current, int total);

  /// No description provided for @blindDateMessagesToGo.
  ///
  /// In en, this message translates to:
  /// **'{count} to go'**
  String blindDateMessagesToGo(int count);

  /// No description provided for @blindDateMessagesUntilReveal.
  ///
  /// In en, this message translates to:
  /// **'{count} messages until reveal'**
  String blindDateMessagesUntilReveal(int count);

  /// No description provided for @blindDateModeActivated.
  ///
  /// In en, this message translates to:
  /// **'Blind Date mode activated!'**
  String get blindDateModeActivated;

  /// No description provided for @blindDateModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Match based on personality, not looks.\nPhotos reveal after {threshold} messages.'**
  String blindDateModeDescription(int threshold);

  /// No description provided for @blindDateModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Blind Date Mode'**
  String get blindDateModeTitle;

  /// No description provided for @blindDateMysteryPerson.
  ///
  /// In en, this message translates to:
  /// **'Mystery Person'**
  String get blindDateMysteryPerson;

  /// No description provided for @blindDateNoCandidates.
  ///
  /// In en, this message translates to:
  /// **'No candidates available'**
  String get blindDateNoCandidates;

  /// No description provided for @blindDateNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get blindDateNoMatches;

  /// No description provided for @blindDatePendingReveal.
  ///
  /// In en, this message translates to:
  /// **'Pending Reveal ({count})'**
  String blindDatePendingReveal(int count);

  /// No description provided for @blindDatePhotoRevealProgress.
  ///
  /// In en, this message translates to:
  /// **'Photo Reveal Progress'**
  String get blindDatePhotoRevealProgress;

  /// No description provided for @blindDatePhotosRevealHint.
  ///
  /// In en, this message translates to:
  /// **'Photos reveal after {threshold} messages'**
  String blindDatePhotosRevealHint(int threshold);

  /// No description provided for @blindDatePhotosRevealed.
  ///
  /// In en, this message translates to:
  /// **'Photos revealed! {coinsSpent} coins spent.'**
  String blindDatePhotosRevealed(int coinsSpent);

  /// No description provided for @blindDatePhotosRevealedLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos revealed!'**
  String get blindDatePhotosRevealedLabel;

  /// No description provided for @blindDateReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get blindDateReveal;

  /// No description provided for @blindDateRevealed.
  ///
  /// In en, this message translates to:
  /// **'Revealed ({count})'**
  String blindDateRevealed(int count);

  /// No description provided for @blindDateRevealedMatch.
  ///
  /// In en, this message translates to:
  /// **'Revealed Match'**
  String get blindDateRevealedMatch;

  /// No description provided for @blindDateStartSwiping.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to find your blind date!'**
  String get blindDateStartSwiping;

  /// No description provided for @blindDateTabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get blindDateTabDiscover;

  /// No description provided for @blindDateTabMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get blindDateTabMatches;

  /// No description provided for @blindDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Blind Date'**
  String get blindDateTitle;

  /// No description provided for @blindDateViewMatch.
  ///
  /// In en, this message translates to:
  /// **'View Match'**
  String get blindDateViewMatch;

  /// No description provided for @bonusCoinsText.
  ///
  /// In en, this message translates to:
  /// **' (+{bonus} bonus!)'**
  String bonusCoinsText(int bonus, Object bonusCoins);

  /// No description provided for @boost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boost;

  /// No description provided for @boostActivated.
  ///
  /// In en, this message translates to:
  /// **'Boost activated for 30 minutes!'**
  String get boostActivated;

  /// No description provided for @boostNow.
  ///
  /// In en, this message translates to:
  /// **'Boost Now'**
  String get boostNow;

  /// No description provided for @boostProfile.
  ///
  /// In en, this message translates to:
  /// **'Boost Profile'**
  String get boostProfile;

  /// No description provided for @boosted.
  ///
  /// In en, this message translates to:
  /// **'BOOSTED!'**
  String get boosted;

  /// No description provided for @boostsRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'x{count}'**
  String boostsRemainingCount(int count);

  /// No description provided for @bundleTier.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get bundleTier;

  /// No description provided for @businessCategory.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessCategory;

  /// No description provided for @buyCoins.
  ///
  /// In en, this message translates to:
  /// **'Buy Coins'**
  String get buyCoins;

  /// No description provided for @buyCoinsBtnLabel.
  ///
  /// In en, this message translates to:
  /// **'Buy Coins'**
  String get buyCoinsBtnLabel;

  /// No description provided for @buyPackBtn.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyPackBtn;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @cannotAccessFeature.
  ///
  /// In en, this message translates to:
  /// **'This feature is available after your account is verified.'**
  String get cannotAccessFeature;

  /// No description provided for @cantUndoMatched.
  ///
  /// In en, this message translates to:
  /// **'Can\'t undo — you already matched!'**
  String get cantUndoMatched;

  /// No description provided for @casualCategory.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get casualCategory;

  /// No description provided for @casualDating.
  ///
  /// In en, this message translates to:
  /// **'Casual dating'**
  String get casualDating;

  /// No description provided for @categoryFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Flashcard'**
  String get categoryFlashcard;

  /// No description provided for @categoryLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get categoryLearning;

  /// No description provided for @categoryMultilingual.
  ///
  /// In en, this message translates to:
  /// **'Multilingual'**
  String get categoryMultilingual;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryName;

  /// No description provided for @categoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get categoryQuiz;

  /// No description provided for @categorySeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get categorySeasonal;

  /// No description provided for @categorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get categorySocial;

  /// No description provided for @categoryStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get categoryStreak;

  /// No description provided for @categoryTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get categoryTranslation;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get changeLocation;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'For security, please verify your identity before changing your password.'**
  String get changePasswordDescription;

  /// No description provided for @changePasswordEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address'**
  String get changePasswordEmailConfirm;

  /// No description provided for @changePasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get changePasswordEmailHint;

  /// No description provided for @changePasswordEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'Email does not match your account'**
  String get changePasswordEmailMismatch;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordNew;

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

  /// No description provided for @chatAddCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get chatAddCaption;

  /// No description provided for @chatAddToStarred.
  ///
  /// In en, this message translates to:
  /// **'Add to starred messages'**
  String get chatAddToStarred;

  /// No description provided for @chatAlreadyInYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Message is already in your language'**
  String get chatAlreadyInYourLanguage;

  /// No description provided for @chatAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatAttachCamera;

  /// No description provided for @chatAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get chatAttachGallery;

  /// No description provided for @chatAttachRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get chatAttachRecord;

  /// No description provided for @chatAttachVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatAttachVideo;

  /// No description provided for @chatBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlock;

  /// No description provided for @chatBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String chatBlockUser(String name);

  /// No description provided for @chatBlockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {name}? They will no longer be able to contact you.'**
  String chatBlockUserMessage(String name);

  /// No description provided for @chatBlockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get chatBlockUserTitle;

  /// No description provided for @chatCannotBlockAdmin.
  ///
  /// In en, this message translates to:
  /// **'You cannot block an administrator.'**
  String get chatCannotBlockAdmin;

  /// No description provided for @chatCannotReportAdmin.
  ///
  /// In en, this message translates to:
  /// **'You cannot report an administrator.'**
  String get chatCannotReportAdmin;

  /// No description provided for @chatCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get chatCategory;

  /// No description provided for @chatCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Help'**
  String get chatCategoryAccount;

  /// No description provided for @chatCategoryBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing & Payments'**
  String get chatCategoryBilling;

  /// No description provided for @chatCategoryFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get chatCategoryFeedback;

  /// No description provided for @chatCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Question'**
  String get chatCategoryGeneral;

  /// No description provided for @chatCategorySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety Concern'**
  String get chatCategorySafety;

  /// No description provided for @chatCategoryTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get chatCategoryTechnical;

  /// No description provided for @chatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// No description provided for @chatCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get chatCreate;

  /// No description provided for @chatCreateSupportTicket.
  ///
  /// In en, this message translates to:
  /// **'Create Support Ticket'**
  String get chatCreateSupportTicket;

  /// No description provided for @chatCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get chatCreateTicket;

  /// No description provided for @chatDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String chatDaysAgo(int count);

  /// No description provided for @chatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDelete;

  /// No description provided for @chatDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get chatDeleteChat;

  /// No description provided for @chatDeleteChatForBothMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all messages for both you and {name}. This action cannot be undone.'**
  String chatDeleteChatForBothMessage(String name);

  /// No description provided for @chatDeleteChatForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat for Everyone'**
  String get chatDeleteChatForEveryone;

  /// No description provided for @chatDeleteChatForMeMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete the chat from your device only. The other person will still see the messages.'**
  String get chatDeleteChatForMeMessage;

  /// No description provided for @chatDeleteConversationWith.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation with {name}?'**
  String chatDeleteConversationWith(String name);

  /// No description provided for @chatDeleteForBoth.
  ///
  /// In en, this message translates to:
  /// **'Delete chat for both'**
  String get chatDeleteForBoth;

  /// No description provided for @chatDeleteForBothDescription.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the conversation for both you and the other person.'**
  String get chatDeleteForBothDescription;

  /// No description provided for @chatDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for Everyone'**
  String get chatDeleteForEveryone;

  /// No description provided for @chatDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete chat for me'**
  String get chatDeleteForMe;

  /// No description provided for @chatDeleteForMeDescription.
  ///
  /// In en, this message translates to:
  /// **'This will delete the conversation from your chat list only. The other person will still see it.'**
  String get chatDeleteForMeDescription;

  /// No description provided for @chatDeletedForBothMessage.
  ///
  /// In en, this message translates to:
  /// **'This chat has been permanently removed'**
  String get chatDeletedForBothMessage;

  /// No description provided for @chatDeletedForMeMessage.
  ///
  /// In en, this message translates to:
  /// **'This chat has been removed from your inbox'**
  String get chatDeletedForMeMessage;

  /// No description provided for @chatDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Deleted!'**
  String get chatDeletedTitle;

  /// No description provided for @chatDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get chatDescriptionOptional;

  /// No description provided for @chatDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Provide more details about your issue...'**
  String get chatDetailsHint;

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

  /// No description provided for @chatErrorLoadingTickets.
  ///
  /// In en, this message translates to:
  /// **'Error loading tickets'**
  String get chatErrorLoadingTickets;

  /// No description provided for @chatFailedToCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Failed to create ticket'**
  String get chatFailedToCreateTicket;

  /// No description provided for @chatFailedToForwardMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to forward message'**
  String get chatFailedToForwardMessage;

  /// No description provided for @chatFailedToLoadAlbum.
  ///
  /// In en, this message translates to:
  /// **'Failed to load album'**
  String get chatFailedToLoadAlbum;

  /// No description provided for @chatFailedToLoadConversations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load conversations'**
  String get chatFailedToLoadConversations;

  /// No description provided for @chatFailedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get chatFailedToLoadImage;

  /// No description provided for @chatFailedToLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get chatFailedToLoadVideo;

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

  /// No description provided for @chatFailedToReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to report message: {error}'**
  String chatFailedToReportMessage(String error);

  /// No description provided for @chatFailedToRevokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke access'**
  String get chatFailedToRevokeAccess;

  /// No description provided for @chatFailedToSaveFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Failed to save flashcard'**
  String get chatFailedToSaveFlashcard;

  /// No description provided for @chatFailedToShareAlbum.
  ///
  /// In en, this message translates to:
  /// **'Failed to share album'**
  String get chatFailedToShareAlbum;

  /// No description provided for @chatFailedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String chatFailedToUploadImage(String error);

  /// No description provided for @chatFailedToUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload video: {error}'**
  String chatFailedToUploadVideo(String error);

  /// No description provided for @chatFeatureCulturalTips.
  ///
  /// In en, this message translates to:
  /// **'Cultural tips & context'**
  String get chatFeatureCulturalTips;

  /// No description provided for @chatFeatureGrammar.
  ///
  /// In en, this message translates to:
  /// **'Real-time grammar feedback'**
  String get chatFeatureGrammar;

  /// No description provided for @chatFeatureVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary building exercises'**
  String get chatFeatureVocabulary;

  /// No description provided for @chatForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForward;

  /// No description provided for @chatForwardMessage.
  ///
  /// In en, this message translates to:
  /// **'Forward Message'**
  String get chatForwardMessage;

  /// No description provided for @chatForwardToChat.
  ///
  /// In en, this message translates to:
  /// **'Forward to another chat'**
  String get chatForwardToChat;

  /// No description provided for @chatGrammarSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Grammar Suggestion'**
  String get chatGrammarSuggestion;

  /// No description provided for @chatHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String chatHoursAgo(int count);

  /// No description provided for @chatIcebreakers.
  ///
  /// In en, this message translates to:
  /// **'Icebreakers'**
  String get chatIcebreakers;

  /// No description provided for @chatIsTyping.
  ///
  /// In en, this message translates to:
  /// **'{userName} is typing'**
  String chatIsTyping(String userName);

  /// No description provided for @chatJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatJustNow;

  /// No description provided for @chatLanguagePickerHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you want to read this conversation in. All messages will be translated for you.'**
  String get chatLanguagePickerHint;

  /// No description provided for @chatLanguageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Chat language set to {language}'**
  String chatLanguageSetTo(String language);

  /// No description provided for @chatLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get chatLanguages;

  /// No description provided for @chatLearnThis.
  ///
  /// In en, this message translates to:
  /// **'Learn This'**
  String get chatLearnThis;

  /// No description provided for @chatListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get chatListen;

  /// No description provided for @chatLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get chatLoadingVideo;

  /// No description provided for @chatMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get chatMaybeLater;

  /// No description provided for @chatMediaLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Media Limit Reached'**
  String get chatMediaLimitReached;

  /// No description provided for @chatMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessage;

  /// No description provided for @chatMessageBlockedContains.
  ///
  /// In en, this message translates to:
  /// **'Message blocked: Contains {violations}. For your safety, sharing personal contact details is not allowed.'**
  String chatMessageBlockedContains(String violations);

  /// No description provided for @chatMessageForwarded.
  ///
  /// In en, this message translates to:
  /// **'Message forwarded to {count} conversation(s)'**
  String chatMessageForwarded(int count);

  /// No description provided for @chatMessageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message Options'**
  String get chatMessageOptions;

  /// No description provided for @chatMessageOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get chatMessageOriginal;

  /// No description provided for @chatMessageReported.
  ///
  /// In en, this message translates to:
  /// **'Message reported. We will review it shortly.'**
  String get chatMessageReported;

  /// No description provided for @chatMessageStarred.
  ///
  /// In en, this message translates to:
  /// **'Message starred'**
  String get chatMessageStarred;

  /// No description provided for @chatMessageTranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get chatMessageTranslated;

  /// No description provided for @chatMessageUnstarred.
  ///
  /// In en, this message translates to:
  /// **'Message unstarred'**
  String get chatMessageUnstarred;

  /// No description provided for @chatMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String chatMinutesAgo(int count);

  /// No description provided for @chatMySupportTickets.
  ///
  /// In en, this message translates to:
  /// **'My Support Tickets'**
  String get chatMySupportTickets;

  /// No description provided for @chatNeedHelpCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Need help? Create a new ticket.'**
  String get chatNeedHelpCreateTicket;

  /// No description provided for @chatNewTicket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get chatNewTicket;

  /// No description provided for @chatNoConversationsToForward.
  ///
  /// In en, this message translates to:
  /// **'No conversations to forward to'**
  String get chatNoConversationsToForward;

  /// No description provided for @chatNoMatchingConversations.
  ///
  /// In en, this message translates to:
  /// **'No matching conversations'**
  String get chatNoMatchingConversations;

  /// No description provided for @chatNoMessagesToPractice.
  ///
  /// In en, this message translates to:
  /// **'No messages to practice with yet'**
  String get chatNoMessagesToPractice;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatNoPrivatePhotos.
  ///
  /// In en, this message translates to:
  /// **'No private photos available'**
  String get chatNoPrivatePhotos;

  /// No description provided for @chatNoSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'No Support Tickets'**
  String get chatNoSupportTickets;

  /// No description provided for @chatOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chatOffline;

  /// No description provided for @chatOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatOnline;

  /// No description provided for @chatOnlineDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Online {days}d ago'**
  String chatOnlineDaysAgo(int days);

  /// No description provided for @chatOnlineHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Online {hours}h ago'**
  String chatOnlineHoursAgo(int hours);

  /// No description provided for @chatOnlineJustNow.
  ///
  /// In en, this message translates to:
  /// **'Online just now'**
  String get chatOnlineJustNow;

  /// No description provided for @chatOnlineMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Online {minutes}m ago'**
  String chatOnlineMinutesAgo(int minutes);

  /// No description provided for @chatOptions.
  ///
  /// In en, this message translates to:
  /// **'Chat Options'**
  String get chatOptions;

  /// No description provided for @chatOtherRevokedAlbum.
  ///
  /// In en, this message translates to:
  /// **'{name} revoked album access'**
  String chatOtherRevokedAlbum(String name);

  /// No description provided for @chatOtherSharedAlbum.
  ///
  /// In en, this message translates to:
  /// **'{name} shared their private album'**
  String chatOtherSharedAlbum(String name);

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// No description provided for @chatPhraseSaved.
  ///
  /// In en, this message translates to:
  /// **'Phrase saved to your flashcard deck!'**
  String get chatPhraseSaved;

  /// No description provided for @chatPleaseEnterSubject.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get chatPleaseEnterSubject;

  /// No description provided for @chatPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get chatPractice;

  /// No description provided for @chatPracticeMode.
  ///
  /// In en, this message translates to:
  /// **'Practice Mode'**
  String get chatPracticeMode;

  /// No description provided for @chatPracticeTrialStarted.
  ///
  /// In en, this message translates to:
  /// **'Practice mode trial started! You have 3 free sessions.'**
  String get chatPracticeTrialStarted;

  /// No description provided for @chatPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Preview Image'**
  String get chatPreviewImage;

  /// No description provided for @chatPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'Preview Video'**
  String get chatPreviewVideo;

  /// No description provided for @chatPronunciationChallenge.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Challenge'**
  String get chatPronunciationChallenge;

  /// No description provided for @chatPronunciationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to hear, then practice saying each phrase:'**
  String get chatPronunciationHint;

  /// No description provided for @chatRemoveFromStarred.
  ///
  /// In en, this message translates to:
  /// **'Remove from starred messages'**
  String get chatRemoveFromStarred;

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

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatReportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Report inappropriate content'**
  String get chatReportInappropriate;

  /// No description provided for @chatReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report Message'**
  String get chatReportMessage;

  /// No description provided for @chatReportReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile / Catfishing'**
  String get chatReportReasonFakeProfile;

  /// No description provided for @chatReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get chatReportReasonHarassment;

  /// No description provided for @chatReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get chatReportReasonInappropriate;

  /// No description provided for @chatReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatReportReasonOther;

  /// No description provided for @chatReportReasonPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Sharing personal information'**
  String get chatReportReasonPersonalInfo;

  /// No description provided for @chatReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get chatReportReasonSpam;

  /// No description provided for @chatReportReasonThreatening.
  ///
  /// In en, this message translates to:
  /// **'Threatening behavior'**
  String get chatReportReasonThreatening;

  /// No description provided for @chatReportReasonUnderage.
  ///
  /// In en, this message translates to:
  /// **'Underage user'**
  String get chatReportReasonUnderage;

  /// No description provided for @chatReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String chatReportUser(String name);

  /// No description provided for @chatReportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get chatReportUserTitle;

  /// No description provided for @chatSafetyGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get chatSafetyGotIt;

  /// No description provided for @chatSafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our priority. Please keep these tips in mind.'**
  String get chatSafetySubtitle;

  /// No description provided for @chatSafetyTip.
  ///
  /// In en, this message translates to:
  /// **'Safety Tip'**
  String get chatSafetyTip;

  /// No description provided for @chatSafetyTip1Description.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share your address, phone number, or financial information.'**
  String get chatSafetyTip1Description;

  /// No description provided for @chatSafetyTip1Title.
  ///
  /// In en, this message translates to:
  /// **'Keep Personal Info Private'**
  String get chatSafetyTip1Title;

  /// No description provided for @chatSafetyTip2Description.
  ///
  /// In en, this message translates to:
  /// **'Never send money to someone you haven\'t met in person.'**
  String get chatSafetyTip2Description;

  /// No description provided for @chatSafetyTip2Title.
  ///
  /// In en, this message translates to:
  /// **'Beware of Money Requests'**
  String get chatSafetyTip2Title;

  /// No description provided for @chatSafetyTip3Description.
  ///
  /// In en, this message translates to:
  /// **'For first meetings, always choose a public, well-lit location.'**
  String get chatSafetyTip3Description;

  /// No description provided for @chatSafetyTip3Title.
  ///
  /// In en, this message translates to:
  /// **'Meet in Public Places'**
  String get chatSafetyTip3Title;

  /// No description provided for @chatSafetyTip4Description.
  ///
  /// In en, this message translates to:
  /// **'If something feels wrong, trust your gut and end the conversation.'**
  String get chatSafetyTip4Description;

  /// No description provided for @chatSafetyTip4Title.
  ///
  /// In en, this message translates to:
  /// **'Trust Your Instincts'**
  String get chatSafetyTip4Title;

  /// No description provided for @chatSafetyTip5Description.
  ///
  /// In en, this message translates to:
  /// **'Use the report feature if someone makes you uncomfortable.'**
  String get chatSafetyTip5Description;

  /// No description provided for @chatSafetyTip5Title.
  ///
  /// In en, this message translates to:
  /// **'Report Suspicious Behavior'**
  String get chatSafetyTip5Title;

  /// No description provided for @chatSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Safe While Chatting'**
  String get chatSafetyTitle;

  /// No description provided for @chatSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get chatSaving;

  /// No description provided for @chatSayHiTo.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name}!'**
  String chatSayHiTo(String name);

  /// No description provided for @chatScrollUpForOlder.
  ///
  /// In en, this message translates to:
  /// **'Scroll up for older messages'**
  String get chatScrollUpForOlder;

  /// No description provided for @chatSearchByNameOrNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @nickname'**
  String get chatSearchByNameOrNickname;

  /// No description provided for @chatSearchConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get chatSearchConversationsHint;

  /// No description provided for @chatSelectPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select photos to send'**
  String get chatSelectPhotos;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatSendAnyway.
  ///
  /// In en, this message translates to:
  /// **'Send Anyway'**
  String get chatSendAnyway;

  /// No description provided for @chatSendAttachment.
  ///
  /// In en, this message translates to:
  /// **'Send Attachment'**
  String get chatSendAttachment;

  /// No description provided for @chatSendCount.
  ///
  /// In en, this message translates to:
  /// **'Send ({count})'**
  String chatSendCount(int count);

  /// No description provided for @chatSendMessageToStart.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation'**
  String get chatSendMessageToStart;

  /// No description provided for @chatSendMessagesForTips.
  ///
  /// In en, this message translates to:
  /// **'Send messages to get language learning tips!'**
  String get chatSendMessagesForTips;

  /// No description provided for @chatSetNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Set your native language in settings first'**
  String get chatSetNativeLanguage;

  /// No description provided for @chatSettingCulturalTips.
  ///
  /// In en, this message translates to:
  /// **'Cultural Tips'**
  String get chatSettingCulturalTips;

  /// No description provided for @chatSettingCulturalTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show cultural context for idioms and expressions'**
  String get chatSettingCulturalTipsDesc;

  /// No description provided for @chatSettingDifficultyBadges.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Badges'**
  String get chatSettingDifficultyBadges;

  /// No description provided for @chatSettingDifficultyBadgesDesc.
  ///
  /// In en, this message translates to:
  /// **'Show CEFR level (A1-C2) on messages'**
  String get chatSettingDifficultyBadgesDesc;

  /// No description provided for @chatSettingGrammarCheck.
  ///
  /// In en, this message translates to:
  /// **'Grammar Check'**
  String get chatSettingGrammarCheck;

  /// No description provided for @chatSettingGrammarCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Check grammar before sending messages'**
  String get chatSettingGrammarCheckDesc;

  /// No description provided for @chatSettingLanguageFlags.
  ///
  /// In en, this message translates to:
  /// **'Language Flags'**
  String get chatSettingLanguageFlags;

  /// No description provided for @chatSettingLanguageFlagsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show flag emoji next to translated and original text'**
  String get chatSettingLanguageFlagsDesc;

  /// No description provided for @chatSettingPhraseOfDay.
  ///
  /// In en, this message translates to:
  /// **'Phrase of the Day'**
  String get chatSettingPhraseOfDay;

  /// No description provided for @chatSettingPhraseOfDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Show a daily phrase to practice'**
  String get chatSettingPhraseOfDayDesc;

  /// No description provided for @chatSettingPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation (TTS)'**
  String get chatSettingPronunciation;

  /// No description provided for @chatSettingPronunciationDesc.
  ///
  /// In en, this message translates to:
  /// **'Double-tap messages to hear pronunciation'**
  String get chatSettingPronunciationDesc;

  /// No description provided for @chatSettingShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show Original Text'**
  String get chatSettingShowOriginal;

  /// No description provided for @chatSettingShowOriginalDesc.
  ///
  /// In en, this message translates to:
  /// **'Display the original message below translation'**
  String get chatSettingShowOriginalDesc;

  /// No description provided for @chatSettingSmartReplies.
  ///
  /// In en, this message translates to:
  /// **'Smart Replies'**
  String get chatSettingSmartReplies;

  /// No description provided for @chatSettingSmartRepliesDesc.
  ///
  /// In en, this message translates to:
  /// **'Suggest replies in the target language'**
  String get chatSettingSmartRepliesDesc;

  /// No description provided for @chatSettingTtsTranslation.
  ///
  /// In en, this message translates to:
  /// **'TTS Reads Translation'**
  String get chatSettingTtsTranslation;

  /// No description provided for @chatSettingTtsTranslationDesc.
  ///
  /// In en, this message translates to:
  /// **'Read the translated text instead of original'**
  String get chatSettingTtsTranslationDesc;

  /// No description provided for @chatSettingWordBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Word Breakdown'**
  String get chatSettingWordBreakdown;

  /// No description provided for @chatSettingWordBreakdownDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap messages for word-by-word translation'**
  String get chatSettingWordBreakdownDesc;

  /// No description provided for @chatSettingXpBar.
  ///
  /// In en, this message translates to:
  /// **'XP & Streak Bar'**
  String get chatSettingXpBar;

  /// No description provided for @chatSettingXpBarDesc.
  ///
  /// In en, this message translates to:
  /// **'Show session XP and word count progress'**
  String get chatSettingXpBarDesc;

  /// No description provided for @chatSettingsSaveAllChats.
  ///
  /// In en, this message translates to:
  /// **'Save settings for all chats'**
  String get chatSettingsSaveAllChats;

  /// No description provided for @chatSettingsSaveThisChat.
  ///
  /// In en, this message translates to:
  /// **'Save settings to this chat'**
  String get chatSettingsSaveThisChat;

  /// No description provided for @chatSettingsSavedAllChats.
  ///
  /// In en, this message translates to:
  /// **'Settings saved for all chats'**
  String get chatSettingsSavedAllChats;

  /// No description provided for @chatSettingsSavedThisChat.
  ///
  /// In en, this message translates to:
  /// **'Settings saved for this chat'**
  String get chatSettingsSavedThisChat;

  /// No description provided for @chatSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customise your learning experience in this chat'**
  String get chatSettingsSubtitle;

  /// No description provided for @chatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettingsTitle;

  /// No description provided for @chatSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get chatSomeone;

  /// No description provided for @chatStarMessage.
  ///
  /// In en, this message translates to:
  /// **'Star Message'**
  String get chatStarMessage;

  /// No description provided for @chatStartSwipingToChat.
  ///
  /// In en, this message translates to:
  /// **'Start swiping and matching to chat with people!'**
  String get chatStartSwipingToChat;

  /// No description provided for @chatStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get chatStatusAssigned;

  /// No description provided for @chatStatusAwaitingReply.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Reply'**
  String get chatStatusAwaitingReply;

  /// No description provided for @chatStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get chatStatusClosed;

  /// No description provided for @chatStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get chatStatusInProgress;

  /// No description provided for @chatStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get chatStatusOpen;

  /// No description provided for @chatStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get chatStatusResolved;

  /// No description provided for @chatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak: {count}'**
  String chatStreak(int count);

  /// No description provided for @chatSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get chatSubject;

  /// No description provided for @chatSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your issue'**
  String get chatSubjectHint;

  /// No description provided for @chatSupportAddAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get chatSupportAddAttachment;

  /// No description provided for @chatSupportAddCaptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)...'**
  String get chatSupportAddCaptionOptional;

  /// No description provided for @chatSupportAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent: {name}'**
  String chatSupportAgent(String name);

  /// No description provided for @chatSupportAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get chatSupportAgentLabel;

  /// No description provided for @chatSupportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get chatSupportCategory;

  /// No description provided for @chatSupportClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chatSupportClose;

  /// No description provided for @chatSupportDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String chatSupportDaysAgo(int days);

  /// No description provided for @chatSupportErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get chatSupportErrorLoading;

  /// No description provided for @chatSupportFailedToReopen.
  ///
  /// In en, this message translates to:
  /// **'Failed to reopen ticket: {error}'**
  String chatSupportFailedToReopen(String error);

  /// No description provided for @chatSupportFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String chatSupportFailedToSend(String error);

  /// No description provided for @chatSupportGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get chatSupportGeneral;

  /// No description provided for @chatSupportGeneralSupport.
  ///
  /// In en, this message translates to:
  /// **'General Support'**
  String get chatSupportGeneralSupport;

  /// No description provided for @chatSupportHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String chatSupportHoursAgo(int hours);

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

  /// No description provided for @chatSupportReopenTicket.
  ///
  /// In en, this message translates to:
  /// **'Need more help? Tap to reopen'**
  String get chatSupportReopenTicket;

  /// No description provided for @chatSupportStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation.\nOur team will respond as soon as possible.'**
  String get chatSupportStartMessage;

  /// No description provided for @chatSupportStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get chatSupportStatus;

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

  /// No description provided for @chatSupportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get chatSupportSubject;

  /// No description provided for @chatSupportTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket Created'**
  String get chatSupportTicketCreated;

  /// No description provided for @chatSupportTicketId.
  ///
  /// In en, this message translates to:
  /// **'Ticket ID'**
  String get chatSupportTicketId;

  /// No description provided for @chatSupportTicketInfo.
  ///
  /// In en, this message translates to:
  /// **'Ticket Information'**
  String get chatSupportTicketInfo;

  /// No description provided for @chatSupportTicketReopened.
  ///
  /// In en, this message translates to:
  /// **'Ticket reopened. You can send a message now.'**
  String get chatSupportTicketReopened;

  /// No description provided for @chatSupportTicketResolved.
  ///
  /// In en, this message translates to:
  /// **'This ticket has been resolved'**
  String get chatSupportTicketResolved;

  /// No description provided for @chatSupportTicketStart.
  ///
  /// In en, this message translates to:
  /// **'Ticket Start'**
  String get chatSupportTicketStart;

  /// No description provided for @chatSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Support'**
  String get chatSupportTitle;

  /// No description provided for @chatSupportTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get chatSupportTypeMessage;

  /// No description provided for @chatSupportWaitingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for assignment'**
  String get chatSupportWaitingAssignment;

  /// No description provided for @chatSupportWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Support'**
  String get chatSupportWelcome;

  /// No description provided for @chatTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get chatTapToView;

  /// No description provided for @chatTapToViewAlbum.
  ///
  /// In en, this message translates to:
  /// **'Tap to view album'**
  String get chatTapToViewAlbum;

  /// No description provided for @chatTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatTranslate;

  /// No description provided for @chatTranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get chatTranslated;

  /// No description provided for @chatTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get chatTranslating;

  /// No description provided for @chatTranslationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Translation disabled'**
  String get chatTranslationDisabled;

  /// No description provided for @chatTranslationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Translation enabled'**
  String get chatTranslationEnabled;

  /// No description provided for @chatTranslationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed. Please try again.'**
  String get chatTranslationFailed;

  /// No description provided for @chatTrialExpired.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has expired.'**
  String get chatTrialExpired;

  /// No description provided for @chatTtsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Text-to-speech coming soon!'**
  String get chatTtsComingSoon;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get chatTyping;

  /// No description provided for @chatUnableToForward.
  ///
  /// In en, this message translates to:
  /// **'Unable to forward message'**
  String get chatUnableToForward;

  /// No description provided for @chatUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get chatUnknown;

  /// No description provided for @chatUnstarMessage.
  ///
  /// In en, this message translates to:
  /// **'Unstar Message'**
  String get chatUnstarMessage;

  /// No description provided for @chatUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get chatUpgrade;

  /// No description provided for @chatUpgradePracticeMode.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Silver VIP or higher to continue practicing languages in your chats.'**
  String get chatUpgradePracticeMode;

  /// No description provided for @chatUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get chatUploading;

  /// No description provided for @chatUseCorrection.
  ///
  /// In en, this message translates to:
  /// **'Use Correction'**
  String get chatUseCorrection;

  /// No description provided for @chatUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked'**
  String chatUserBlocked(String name);

  /// No description provided for @chatUserReported.
  ///
  /// In en, this message translates to:
  /// **'User reported. We will review your report shortly.'**
  String get chatUserReported;

  /// No description provided for @chatVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatVideo;

  /// No description provided for @chatVideoPlayer.
  ///
  /// In en, this message translates to:
  /// **'Video Player'**
  String get chatVideoPlayer;

  /// No description provided for @chatVideoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Video too large. Maximum size is 50MB.'**
  String get chatVideoTooLarge;

  /// No description provided for @chatWhyReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this message?'**
  String get chatWhyReportMessage;

  /// No description provided for @chatWhyReportUser.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting {name}?'**
  String chatWhyReportUser(String name);

  /// No description provided for @chatWithName.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWithName(String name);

  /// No description provided for @chatWords.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String chatWords(int count);

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatYouRevokedAlbum.
  ///
  /// In en, this message translates to:
  /// **'You revoked album access'**
  String get chatYouRevokedAlbum;

  /// No description provided for @chatYouSharedAlbum.
  ///
  /// In en, this message translates to:
  /// **'You shared your private album'**
  String get chatYouSharedAlbum;

  /// No description provided for @chatYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Your Language'**
  String get chatYourLanguage;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new people, or adjust your preferences'**
  String get checkBackLater;

  /// No description provided for @chooseCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Choose the correct answer'**
  String get chooseCorrectAnswer;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseGame.
  ///
  /// In en, this message translates to:
  /// **'Choose a Game'**
  String get chooseGame;

  /// No description provided for @claimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get claimReward;

  /// No description provided for @claimRewardBtn.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claimRewardBtn;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @coinsAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'{totalCoins} coins added to your account{bonusText}'**
  String coinsAddedMessage(int totalCoins, String bonusText);

  /// No description provided for @coinsAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get coinsAllTransactions;

  /// No description provided for @coinsAmountCoins.
  ///
  /// In en, this message translates to:
  /// **'{amount} Coins'**
  String coinsAmountCoins(Object amount);

  /// No description provided for @coinsAmountVideoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{amount} Video Minutes'**
  String coinsAmountVideoMinutes(Object amount);

  /// No description provided for @coinsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get coinsApply;

  /// No description provided for @coinsBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {balance}'**
  String coinsBalance(Object balance);

  /// No description provided for @coinsBonusCoins.
  ///
  /// In en, this message translates to:
  /// **'+{amount} bonus coins'**
  String coinsBonusCoins(Object amount);

  /// No description provided for @coinsCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coinsCancelLabel;

  /// No description provided for @coinsConfirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get coinsConfirmPurchase;

  /// No description provided for @coinsCost.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins'**
  String coinsCost(int amount);

  /// No description provided for @coinsCreditsOnly.
  ///
  /// In en, this message translates to:
  /// **'Credits Only'**
  String get coinsCreditsOnly;

  /// No description provided for @coinsDebitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Debits Only'**
  String get coinsDebitsOnly;

  /// No description provided for @coinsEnterReceiverId.
  ///
  /// In en, this message translates to:
  /// **'Enter receiver ID'**
  String get coinsEnterReceiverId;

  /// No description provided for @coinsExpiring.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring'**
  String coinsExpiring(Object count);

  /// No description provided for @coinsFilterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get coinsFilterTransactions;

  /// No description provided for @coinsGiftAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted {amount} coins!'**
  String coinsGiftAccepted(Object amount);

  /// No description provided for @coinsGiftDeclined.
  ///
  /// In en, this message translates to:
  /// **'Gift declined'**
  String get coinsGiftDeclined;

  /// No description provided for @coinsGiftSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send gift'**
  String get coinsGiftSendFailed;

  /// No description provided for @coinsGiftSent.
  ///
  /// In en, this message translates to:
  /// **'Gift of {amount} coins sent!'**
  String coinsGiftSent(Object amount);

  /// No description provided for @coinsGreenGoCoins.
  ///
  /// In en, this message translates to:
  /// **'GreenGoCoins'**
  String get coinsGreenGoCoins;

  /// No description provided for @coinsInsufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coins'**
  String get coinsInsufficientCoins;

  /// No description provided for @coinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinsLabel;

  /// No description provided for @coinsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get coinsMessageLabel;

  /// No description provided for @coinsMins.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get coinsMins;

  /// No description provided for @coinsNoTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get coinsNoTransactionsYet;

  /// No description provided for @coinsPendingGifts.
  ///
  /// In en, this message translates to:
  /// **'Pending Gifts'**
  String get coinsPendingGifts;

  /// No description provided for @coinsPopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get coinsPopular;

  /// No description provided for @coinsPurchaseCoinsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Purchase {totalCoins} coins for {price}?'**
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price);

  /// No description provided for @coinsPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get coinsPurchaseFailed;

  /// No description provided for @coinsPurchaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get coinsPurchaseLabel;

  /// No description provided for @coinsPurchaseMinutesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Purchase {totalMinutes} video minutes for {price}?'**
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price);

  /// No description provided for @coinsPurchasedCoins.
  ///
  /// In en, this message translates to:
  /// **'Successfully purchased {totalCoins} coins!'**
  String coinsPurchasedCoins(Object totalCoins);

  /// No description provided for @coinsPurchasedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Successfully purchased {totalMinutes} video minutes!'**
  String coinsPurchasedMinutes(Object totalMinutes);

  /// No description provided for @coinsReceiverIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Receiver User ID'**
  String get coinsReceiverIdLabel;

  /// No description provided for @coinsRequired.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins required'**
  String coinsRequired(int amount);

  /// No description provided for @coinsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coinsRetry;

  /// No description provided for @coinsSelectAmount.
  ///
  /// In en, this message translates to:
  /// **'Select Amount'**
  String get coinsSelectAmount;

  /// No description provided for @coinsSendCoinsAmount.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} Coins'**
  String coinsSendCoinsAmount(Object amount);

  /// No description provided for @coinsSendGift.
  ///
  /// In en, this message translates to:
  /// **'Send Gift'**
  String get coinsSendGift;

  /// No description provided for @coinsSent.
  ///
  /// In en, this message translates to:
  /// **'Coins sent successfully!'**
  String get coinsSent;

  /// No description provided for @coinsShareCoins.
  ///
  /// In en, this message translates to:
  /// **'Share coins with someone special'**
  String get coinsShareCoins;

  /// No description provided for @coinsShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get coinsShopLabel;

  /// No description provided for @coinsTabCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinsTabCoins;

  /// No description provided for @coinsTabGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get coinsTabGifts;

  /// No description provided for @coinsTabVideoCoins.
  ///
  /// In en, this message translates to:
  /// **'Video Coins'**
  String get coinsTabVideoCoins;

  /// No description provided for @coinsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get coinsToday;

  /// No description provided for @coinsTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get coinsTransactionHistory;

  /// No description provided for @coinsTransactionsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your coin transactions will appear here'**
  String get coinsTransactionsAppearHere;

  /// No description provided for @coinsUnlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features'**
  String get coinsUnlockPremium;

  /// No description provided for @coinsVideoCallMatches.
  ///
  /// In en, this message translates to:
  /// **'Video call with your matches'**
  String get coinsVideoCallMatches;

  /// No description provided for @coinsVideoCoinInfo.
  ///
  /// In en, this message translates to:
  /// **'1 Video Coin = 1 minute of video call'**
  String get coinsVideoCoinInfo;

  /// No description provided for @coinsVideoMin.
  ///
  /// In en, this message translates to:
  /// **'Video Min'**
  String get coinsVideoMin;

  /// No description provided for @coinsVideoMinutes.
  ///
  /// In en, this message translates to:
  /// **'Video Minutes'**
  String get coinsVideoMinutes;

  /// No description provided for @coinsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get coinsYesterday;

  /// No description provided for @comingSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonLabel;

  /// No description provided for @communitiesAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get communitiesAddTag;

  /// No description provided for @communitiesAdjustSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get communitiesAdjustSearch;

  /// No description provided for @communitiesAllCommunities.
  ///
  /// In en, this message translates to:
  /// **'All Communities'**
  String get communitiesAllCommunities;

  /// No description provided for @communitiesAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communitiesAllFilter;

  /// No description provided for @communitiesAnyoneCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Anyone can find and join'**
  String get communitiesAnyoneCanJoin;

  /// No description provided for @communitiesBeFirstToSay.
  ///
  /// In en, this message translates to:
  /// **'Be the first to say something!'**
  String get communitiesBeFirstToSay;

  /// No description provided for @communitiesCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get communitiesCancelLabel;

  /// No description provided for @communitiesCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get communitiesCityLabel;

  /// No description provided for @communitiesCityTipLabel.
  ///
  /// In en, this message translates to:
  /// **'City Tip'**
  String get communitiesCityTipLabel;

  /// No description provided for @communitiesCityTipUpper.
  ///
  /// In en, this message translates to:
  /// **'CITY TIP'**
  String get communitiesCityTipUpper;

  /// No description provided for @communitiesCommunityInfo.
  ///
  /// In en, this message translates to:
  /// **'Community Info'**
  String get communitiesCommunityInfo;

  /// No description provided for @communitiesCommunityName.
  ///
  /// In en, this message translates to:
  /// **'Community Name'**
  String get communitiesCommunityName;

  /// No description provided for @communitiesCommunityType.
  ///
  /// In en, this message translates to:
  /// **'Community Type'**
  String get communitiesCommunityType;

  /// No description provided for @communitiesCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get communitiesCountryLabel;

  /// No description provided for @communitiesCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get communitiesCreateAction;

  /// No description provided for @communitiesCreateCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get communitiesCreateCommunity;

  /// No description provided for @communitiesCreateCommunityAction.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get communitiesCreateCommunityAction;

  /// No description provided for @communitiesCreateLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get communitiesCreateLabel;

  /// No description provided for @communitiesCreateLanguageCircle.
  ///
  /// In en, this message translates to:
  /// **'Create Language Circle'**
  String get communitiesCreateLanguageCircle;

  /// No description provided for @communitiesCreated.
  ///
  /// In en, this message translates to:
  /// **'Community created!'**
  String get communitiesCreated;

  /// No description provided for @communitiesCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by {name}'**
  String communitiesCreatedBy(String name);

  /// No description provided for @communitiesCreatedStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get communitiesCreatedStatLabel;

  /// No description provided for @communitiesCulturalFactLabel.
  ///
  /// In en, this message translates to:
  /// **'Cultural Fact'**
  String get communitiesCulturalFactLabel;

  /// No description provided for @communitiesCulturalFactUpper.
  ///
  /// In en, this message translates to:
  /// **'CULTURAL FACT'**
  String get communitiesCulturalFactUpper;

  /// No description provided for @communitiesDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get communitiesDescription;

  /// No description provided for @communitiesDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this community about?'**
  String get communitiesDescriptionHint;

  /// No description provided for @communitiesDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get communitiesDescriptionLabel;

  /// No description provided for @communitiesDescriptionMinLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get communitiesDescriptionMinLength;

  /// No description provided for @communitiesDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get communitiesDescriptionRequired;

  /// No description provided for @communitiesDiscoverCommunities.
  ///
  /// In en, this message translates to:
  /// **'Discover Communities'**
  String get communitiesDiscoverCommunities;

  /// No description provided for @communitiesEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get communitiesEditLabel;

  /// No description provided for @communitiesGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get communitiesGuide;

  /// No description provided for @communitiesInfoUpper.
  ///
  /// In en, this message translates to:
  /// **'INFO'**
  String get communitiesInfoUpper;

  /// No description provided for @communitiesInviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Invite only'**
  String get communitiesInviteOnly;

  /// No description provided for @communitiesJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get communitiesJoinCommunity;

  /// No description provided for @communitiesJoinPrompt.
  ///
  /// In en, this message translates to:
  /// **'Join communities to connect with people who share your interests and languages.'**
  String get communitiesJoinPrompt;

  /// No description provided for @communitiesJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined community!'**
  String get communitiesJoined;

  /// No description provided for @communitiesLanguageCirclesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Language circles will appear here when available. Create one to get started!'**
  String get communitiesLanguageCirclesPrompt;

  /// No description provided for @communitiesLanguageTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Language Tip'**
  String get communitiesLanguageTipLabel;

  /// No description provided for @communitiesLanguageTipUpper.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE TIP'**
  String get communitiesLanguageTipUpper;

  /// No description provided for @communitiesLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get communitiesLanguages;

  /// No description provided for @communitiesLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get communitiesLanguagesLabel;

  /// No description provided for @communitiesLeaveCommunity.
  ///
  /// In en, this message translates to:
  /// **'Leave Community'**
  String get communitiesLeaveCommunity;

  /// No description provided for @communitiesLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave \"{name}\"?'**
  String communitiesLeaveConfirm(String name);

  /// No description provided for @communitiesLeaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get communitiesLeaveLabel;

  /// No description provided for @communitiesLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Community'**
  String get communitiesLeaveTitle;

  /// No description provided for @communitiesLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get communitiesLocation;

  /// No description provided for @communitiesLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get communitiesLocationLabel;

  /// No description provided for @communitiesMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String communitiesMembersCount(Object count);

  /// No description provided for @communitiesMembersStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communitiesMembersStatLabel;

  /// No description provided for @communitiesMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communitiesMembersTitle;

  /// No description provided for @communitiesNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Spanish Learners NYC'**
  String get communitiesNameHint;

  /// No description provided for @communitiesNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get communitiesNameMinLength;

  /// No description provided for @communitiesNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get communitiesNameRequired;

  /// No description provided for @communitiesNoCommunities.
  ///
  /// In en, this message translates to:
  /// **'No Communities Yet'**
  String get communitiesNoCommunities;

  /// No description provided for @communitiesNoCommunitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No Communities Found'**
  String get communitiesNoCommunitiesFound;

  /// No description provided for @communitiesNoLanguageCircles.
  ///
  /// In en, this message translates to:
  /// **'No Language Circles'**
  String get communitiesNoLanguageCircles;

  /// No description provided for @communitiesNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get communitiesNoMessagesYet;

  /// No description provided for @communitiesPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get communitiesPreview;

  /// No description provided for @communitiesPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how your community will appear to others.'**
  String get communitiesPreviewSubtitle;

  /// No description provided for @communitiesPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get communitiesPrivate;

  /// No description provided for @communitiesPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get communitiesPublic;

  /// No description provided for @communitiesRecommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get communitiesRecommendedForYou;

  /// No description provided for @communitiesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search communities...'**
  String get communitiesSearchHint;

  /// No description provided for @communitiesShareCityTip.
  ///
  /// In en, this message translates to:
  /// **'Share a city tip...'**
  String get communitiesShareCityTip;

  /// No description provided for @communitiesShareCulturalFact.
  ///
  /// In en, this message translates to:
  /// **'Share a cultural fact...'**
  String get communitiesShareCulturalFact;

  /// No description provided for @communitiesShareLanguageTip.
  ///
  /// In en, this message translates to:
  /// **'Share a language tip...'**
  String get communitiesShareLanguageTip;

  /// No description provided for @communitiesStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get communitiesStats;

  /// No description provided for @communitiesTabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get communitiesTabDiscover;

  /// No description provided for @communitiesTabLanguageCircles.
  ///
  /// In en, this message translates to:
  /// **'Language Circles'**
  String get communitiesTabLanguageCircles;

  /// No description provided for @communitiesTabMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get communitiesTabMyGroups;

  /// No description provided for @communitiesTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get communitiesTags;

  /// No description provided for @communitiesTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get communitiesTagsLabel;

  /// No description provided for @communitiesTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get communitiesTextLabel;

  /// No description provided for @communitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communitiesTitle;

  /// No description provided for @communitiesTypeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get communitiesTypeAMessage;

  /// No description provided for @communitiesUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load community'**
  String get communitiesUnableToLoad;

  /// No description provided for @compatibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibilityLabel;

  /// No description provided for @compatiblePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% compatible'**
  String compatiblePercent(String percent);

  /// No description provided for @completeAchievementsToEarnBadges.
  ///
  /// In en, this message translates to:
  /// **'Complete achievements to earn badges!'**
  String get completeAchievementsToEarnBadges;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfile;

  /// No description provided for @complimentsCategory.
  ///
  /// In en, this message translates to:
  /// **'Compliments'**
  String get complimentsCategory;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @connectSocialAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connect your social accounts'**
  String get connectSocialAccounts;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @connectionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get connectionErrorMessage;

  /// No description provided for @connectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get connectionErrorTitle;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Required Consents'**
  String get consentRequired;

  /// No description provided for @consentRequiredError.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Privacy Policy and Terms and Conditions to register'**
  String get consentRequiredError;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @continueLearningBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLearningBtn;

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

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @conversationCategory.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversationCategory;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correctAnswer;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @culturalCategory.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get culturalCategory;

  /// No description provided for @culturalExchangeBeFirstTip.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a cultural tip!'**
  String get culturalExchangeBeFirstTip;

  /// No description provided for @culturalExchangeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get culturalExchangeCategory;

  /// No description provided for @culturalExchangeCommunityTips.
  ///
  /// In en, this message translates to:
  /// **'Community Tips'**
  String get culturalExchangeCommunityTips;

  /// No description provided for @culturalExchangeCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get culturalExchangeCountry;

  /// No description provided for @culturalExchangeCountryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Japan, Brazil, France'**
  String get culturalExchangeCountryHint;

  /// No description provided for @culturalExchangeCountrySpotlight.
  ///
  /// In en, this message translates to:
  /// **'Country Spotlight'**
  String get culturalExchangeCountrySpotlight;

  /// No description provided for @culturalExchangeDailyInsight.
  ///
  /// In en, this message translates to:
  /// **'Daily Cultural Insight'**
  String get culturalExchangeDailyInsight;

  /// No description provided for @culturalExchangeDatingEtiquette.
  ///
  /// In en, this message translates to:
  /// **'Dating Etiquette'**
  String get culturalExchangeDatingEtiquette;

  /// No description provided for @culturalExchangeDatingEtiquetteGuide.
  ///
  /// In en, this message translates to:
  /// **'Dating Etiquette Guide'**
  String get culturalExchangeDatingEtiquetteGuide;

  /// No description provided for @culturalExchangeLoadingCountries.
  ///
  /// In en, this message translates to:
  /// **'Loading countries...'**
  String get culturalExchangeLoadingCountries;

  /// No description provided for @culturalExchangeNoTips.
  ///
  /// In en, this message translates to:
  /// **'No tips yet'**
  String get culturalExchangeNoTips;

  /// No description provided for @culturalExchangeShareCulturalTip.
  ///
  /// In en, this message translates to:
  /// **'Share a Cultural Tip'**
  String get culturalExchangeShareCulturalTip;

  /// No description provided for @culturalExchangeShareTip.
  ///
  /// In en, this message translates to:
  /// **'Share a Tip'**
  String get culturalExchangeShareTip;

  /// No description provided for @culturalExchangeSubmitTip.
  ///
  /// In en, this message translates to:
  /// **'Submit Tip'**
  String get culturalExchangeSubmitTip;

  /// No description provided for @culturalExchangeTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get culturalExchangeTipTitle;

  /// No description provided for @culturalExchangeTipTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give your tip a catchy title'**
  String get culturalExchangeTipTitleHint;

  /// No description provided for @culturalExchangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Cultural Exchange'**
  String get culturalExchangeTitle;

  /// No description provided for @culturalExchangeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get culturalExchangeViewAll;

  /// No description provided for @culturalExchangeYourTip.
  ///
  /// In en, this message translates to:
  /// **'Your Tip'**
  String get culturalExchangeYourTip;

  /// No description provided for @culturalExchangeYourTipHint.
  ///
  /// In en, this message translates to:
  /// **'Share your cultural knowledge...'**
  String get culturalExchangeYourTipHint;

  /// No description provided for @dailyChallengesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete challenges for rewards'**
  String get dailyChallengesSubtitle;

  /// No description provided for @dailyChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenges'**
  String get dailyChallengesTitle;

  /// No description provided for @dailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit of {limit} reached'**
  String dailyLimitReached(int limit);

  /// No description provided for @dailyMessages.
  ///
  /// In en, this message translates to:
  /// **'Daily Messages'**
  String get dailyMessages;

  /// No description provided for @dailyRewardHeader.
  ///
  /// In en, this message translates to:
  /// **'Daily Reward'**
  String get dailyRewardHeader;

  /// No description provided for @dailySwipeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily swipe limit reached. Upgrade for more swipes!'**
  String get dailySwipeLimitReached;

  /// No description provided for @dailySwipes.
  ///
  /// In en, this message translates to:
  /// **'Daily Swipes'**
  String get dailySwipes;

  /// No description provided for @dataExportSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Data export sent to your email'**
  String get dataExportSentToEmail;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @datePlanningCategory.
  ///
  /// In en, this message translates to:
  /// **'Date Planning'**
  String get datePlanningCategory;

  /// No description provided for @dateSchedulerAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get dateSchedulerAccept;

  /// No description provided for @dateSchedulerCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this date?'**
  String get dateSchedulerCancelConfirm;

  /// No description provided for @dateSchedulerCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Date'**
  String get dateSchedulerCancelTitle;

  /// No description provided for @dateSchedulerConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Date confirmed!'**
  String get dateSchedulerConfirmed;

  /// No description provided for @dateSchedulerDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get dateSchedulerDecline;

  /// No description provided for @dateSchedulerEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get dateSchedulerEnterTitle;

  /// No description provided for @dateSchedulerKeepDate.
  ///
  /// In en, this message translates to:
  /// **'Keep Date'**
  String get dateSchedulerKeepDate;

  /// No description provided for @dateSchedulerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get dateSchedulerNotesLabel;

  /// No description provided for @dateSchedulerPlanningHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Coffee, Dinner, Movie...'**
  String get dateSchedulerPlanningHint;

  /// No description provided for @dateSchedulerReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get dateSchedulerReasonLabel;

  /// No description provided for @dateSchedulerReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get dateSchedulerReschedule;

  /// No description provided for @dateSchedulerRescheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Date'**
  String get dateSchedulerRescheduleTitle;

  /// No description provided for @dateSchedulerSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get dateSchedulerSchedule;

  /// No description provided for @dateSchedulerScheduled.
  ///
  /// In en, this message translates to:
  /// **'Date scheduled!'**
  String get dateSchedulerScheduled;

  /// No description provided for @dateSchedulerTabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get dateSchedulerTabPast;

  /// No description provided for @dateSchedulerTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dateSchedulerTabPending;

  /// No description provided for @dateSchedulerTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get dateSchedulerTabUpcoming;

  /// No description provided for @dateSchedulerTitle.
  ///
  /// In en, this message translates to:
  /// **'My Dates'**
  String get dateSchedulerTitle;

  /// No description provided for @dateSchedulerWhatPlanning.
  ///
  /// In en, this message translates to:
  /// **'What are you planning?'**
  String get dateSchedulerWhatPlanning;

  /// No description provided for @dayNumber.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayNumber(int day);

  /// No description provided for @dayStreakCount.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreakCount(String count);

  /// No description provided for @dayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} Day Streak!'**
  String dayStreakLabel(int days);

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.'**
  String get deleteAccountConfirmation;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @directMessageCost.
  ///
  /// In en, this message translates to:
  /// **'Direct messaging costs {cost} coins. Would you like to buy more coins?'**
  String directMessageCost(int cost);

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get discover;

  /// No description provided for @discoveryError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String discoveryError(String error);

  /// No description provided for @discoveryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoveryFilterAll;

  /// No description provided for @discoveryFilterGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get discoveryFilterGuides;

  /// No description provided for @discoveryFilterLiked.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get discoveryFilterLiked;

  /// No description provided for @discoveryFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get discoveryFilterMatches;

  /// No description provided for @discoveryFilterPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get discoveryFilterPassed;

  /// No description provided for @discoveryFilterSkipped.
  ///
  /// In en, this message translates to:
  /// **'Explored'**
  String get discoveryFilterSkipped;

  /// No description provided for @discoveryFilterSuperLiked.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get discoveryFilterSuperLiked;

  /// No description provided for @discoveryFilterTravelers.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get discoveryFilterTravelers;

  /// No description provided for @discoveryPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery Preferences'**
  String get discoveryPreferencesTitle;

  /// No description provided for @discoveryPreferencesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Discovery Preferences'**
  String get discoveryPreferencesTooltip;

  /// No description provided for @discoverySwitchToGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to grid mode'**
  String get discoverySwitchToGrid;

  /// No description provided for @discoverySwitchToSwipe.
  ///
  /// In en, this message translates to:
  /// **'Switch to swipe mode'**
  String get discoverySwitchToSwipe;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKm(String distance);

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

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String downloadProgress(int current, int total);

  /// No description provided for @downloadingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Downloading {language}...'**
  String downloadingLanguage(String language);

  /// No description provided for @downloadingTranslationData.
  ///
  /// In en, this message translates to:
  /// **'Downloading Translation Data'**
  String get downloadingTranslationData;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editInterests.
  ///
  /// In en, this message translates to:
  /// **'Edit Interests'**
  String get editInterests;

  /// No description provided for @editNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get editNickname;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editVoiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit voice coming soon'**
  String get editVoiceComingSoon;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emergencyCategory.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyCategory;

  /// No description provided for @emptyStateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this content. Please try again.'**
  String get emptyStateErrorMessage;

  /// No description provided for @emptyStateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get emptyStateErrorTitle;

  /// No description provided for @emptyStateNoInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get emptyStateNoInternetMessage;

  /// No description provided for @emptyStateNoInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get emptyStateNoInternetTitle;

  /// No description provided for @emptyStateNoLikesMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get more likes!'**
  String get emptyStateNoLikesMessage;

  /// No description provided for @emptyStateNoLikesTitle.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get emptyStateNoLikesTitle;

  /// No description provided for @emptyStateNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to find your perfect match!'**
  String get emptyStateNoMatchesMessage;

  /// No description provided for @emptyStateNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get emptyStateNoMatchesTitle;

  /// No description provided for @emptyStateNoMessagesMessage.
  ///
  /// In en, this message translates to:
  /// **'When you match with someone, you can start chatting here.'**
  String get emptyStateNoMessagesMessage;

  /// No description provided for @emptyStateNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get emptyStateNoMessagesTitle;

  /// No description provided for @emptyStateNoNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any new notifications.'**
  String get emptyStateNoNotificationsMessage;

  /// No description provided for @emptyStateNoNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get emptyStateNoNotificationsTitle;

  /// No description provided for @emptyStateNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get emptyStateNoResultsMessage;

  /// No description provided for @emptyStateNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get emptyStateNoResultsTitle;

  /// No description provided for @enableAutoTranslation.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto-Translation'**
  String get enableAutoTranslation;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get enterNickname;

  /// No description provided for @enterNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get enterNicknameHint;

  /// No description provided for @enterNicknameToFind.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname to find someone directly'**
  String get enterNicknameToFind;

  /// No description provided for @enterRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Enter rejection reason'**
  String get enterRejectionReason;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(Object error);

  /// No description provided for @errorLoadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error loading document'**
  String get errorLoadingDocument;

  /// No description provided for @errorSearchingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error searching. Please try again.'**
  String get errorSearchingTryAgain;

  /// No description provided for @eventsAboutThisEvent.
  ///
  /// In en, this message translates to:
  /// **'About this event'**
  String get eventsAboutThisEvent;

  /// No description provided for @eventsApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get eventsApplyFilters;

  /// No description provided for @eventsAttendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get eventsAttendees;

  /// No description provided for @eventsAttending.
  ///
  /// In en, this message translates to:
  /// **'{going} / {max} attending'**
  String eventsAttending(Object going, Object max);

  /// No description provided for @eventsBeFirstToSay.
  ///
  /// In en, this message translates to:
  /// **'Be the first to say something!'**
  String get eventsBeFirstToSay;

  /// No description provided for @eventsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventsCategory;

  /// No description provided for @eventsChatWithAttendees.
  ///
  /// In en, this message translates to:
  /// **'Chat with other attendees'**
  String get eventsChatWithAttendees;

  /// No description provided for @eventsCheckBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later or create your own event!'**
  String get eventsCheckBackLater;

  /// No description provided for @eventsCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get eventsCreateEvent;

  /// No description provided for @eventsCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully!'**
  String get eventsCreatedSuccessfully;

  /// No description provided for @eventsDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get eventsDateRange;

  /// No description provided for @eventsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventsDeleted;

  /// No description provided for @eventsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventsDescription;

  /// No description provided for @eventsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get eventsDistance;

  /// No description provided for @eventsEndDateTime.
  ///
  /// In en, this message translates to:
  /// **'End Date & Time'**
  String get eventsEndDateTime;

  /// No description provided for @eventsErrorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get eventsErrorLoadingMessages;

  /// No description provided for @eventsEventFull.
  ///
  /// In en, this message translates to:
  /// **'Event Full'**
  String get eventsEventFull;

  /// No description provided for @eventsEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventsEventTitle;

  /// No description provided for @eventsFilterEvents.
  ///
  /// In en, this message translates to:
  /// **'Filter Events'**
  String get eventsFilterEvents;

  /// No description provided for @eventsFreeEvent.
  ///
  /// In en, this message translates to:
  /// **'Free Event'**
  String get eventsFreeEvent;

  /// No description provided for @eventsFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get eventsFreeLabel;

  /// No description provided for @eventsFullLabel.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get eventsFullLabel;

  /// No description provided for @eventsGoing.
  ///
  /// In en, this message translates to:
  /// **'{count} going'**
  String eventsGoing(Object count);

  /// No description provided for @eventsGoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get eventsGoingLabel;

  /// No description provided for @eventsGroupChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Event Group Chat'**
  String get eventsGroupChatTooltip;

  /// No description provided for @eventsJoinEvent.
  ///
  /// In en, this message translates to:
  /// **'Join Event'**
  String get eventsJoinEvent;

  /// No description provided for @eventsJoinLabel.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get eventsJoinLabel;

  /// No description provided for @eventsKmAwayFormat.
  ///
  /// In en, this message translates to:
  /// **'{km}km away'**
  String eventsKmAwayFormat(String km);

  /// No description provided for @eventsLanguageExchange.
  ///
  /// In en, this message translates to:
  /// **'Language Exchange'**
  String get eventsLanguageExchange;

  /// No description provided for @eventsLanguagePairs.
  ///
  /// In en, this message translates to:
  /// **'Language Pairs (e.g., Spanish ↔ English)'**
  String get eventsLanguagePairs;

  /// No description provided for @eventsLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages: {languages}'**
  String eventsLanguages(String languages);

  /// No description provided for @eventsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventsLocation;

  /// No description provided for @eventsMAwayFormat.
  ///
  /// In en, this message translates to:
  /// **'{meters}m away'**
  String eventsMAwayFormat(Object meters);

  /// No description provided for @eventsMaxAttendees.
  ///
  /// In en, this message translates to:
  /// **'Max Attendees'**
  String get eventsMaxAttendees;

  /// No description provided for @eventsNoAttendeesYet.
  ///
  /// In en, this message translates to:
  /// **'No attendees yet. Be the first to join!'**
  String get eventsNoAttendeesYet;

  /// No description provided for @eventsNoEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get eventsNoEventsFound;

  /// No description provided for @eventsNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get eventsNoMessagesYet;

  /// No description provided for @eventsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get eventsRequired;

  /// No description provided for @eventsRsvpCancelled.
  ///
  /// In en, this message translates to:
  /// **'RSVP cancelled'**
  String get eventsRsvpCancelled;

  /// No description provided for @eventsRsvpUpdated.
  ///
  /// In en, this message translates to:
  /// **'RSVP updated!'**
  String get eventsRsvpUpdated;

  /// No description provided for @eventsSpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} spots left'**
  String eventsSpotsLeft(Object count);

  /// No description provided for @eventsStartDateTime.
  ///
  /// In en, this message translates to:
  /// **'Start Date & Time'**
  String get eventsStartDateTime;

  /// No description provided for @eventsTabMyEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get eventsTabMyEvents;

  /// No description provided for @eventsTabNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get eventsTabNearby;

  /// No description provided for @eventsTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventsTabUpcoming;

  /// No description provided for @eventsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get eventsThisMonth;

  /// No description provided for @eventsThisWeekFilter.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get eventsThisWeekFilter;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventsToday;

  /// No description provided for @eventsTypeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get eventsTypeAMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

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

  /// No description provided for @exploreLanguages.
  ///
  /// In en, this message translates to:
  /// **'Explore Languages'**
  String get exploreLanguages;

  /// No description provided for @exploreMapDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'~{distance} km away'**
  String exploreMapDistanceAway(Object distance);

  /// No description provided for @exploreMapError.
  ///
  /// In en, this message translates to:
  /// **'Could not load nearby users'**
  String get exploreMapError;

  /// No description provided for @exploreMapExpandRadius.
  ///
  /// In en, this message translates to:
  /// **'Expand Radius'**
  String get exploreMapExpandRadius;

  /// No description provided for @exploreMapExpandRadiusHint.
  ///
  /// In en, this message translates to:
  /// **'Try increasing your search radius to find more people.'**
  String get exploreMapExpandRadiusHint;

  /// No description provided for @exploreMapNearbyUser.
  ///
  /// In en, this message translates to:
  /// **'Nearby User'**
  String get exploreMapNearbyUser;

  /// No description provided for @exploreMapNoOneNearby.
  ///
  /// In en, this message translates to:
  /// **'No one nearby'**
  String get exploreMapNoOneNearby;

  /// No description provided for @exploreMapOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get exploreMapOnlineNow;

  /// No description provided for @exploreMapPeopleNearYou.
  ///
  /// In en, this message translates to:
  /// **'People Near You'**
  String get exploreMapPeopleNearYou;

  /// No description provided for @exploreMapRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius:'**
  String get exploreMapRadius;

  /// No description provided for @exploreMapVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get exploreMapVisible;

  /// No description provided for @exportMyDataGDPR.
  ///
  /// In en, this message translates to:
  /// **'Export My Data (GDPR)'**
  String get exportMyDataGDPR;

  /// No description provided for @exportingYourData.
  ///
  /// In en, this message translates to:
  /// **'Exporting your data...'**
  String get exportingYourData;

  /// No description provided for @extendCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Extend ({cost} coins)'**
  String extendCoinsLabel(int cost);

  /// No description provided for @extendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get extendTooltip;

  /// No description provided for @failedToDownloadModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to download {language} model'**
  String failedToDownloadModel(String language);

  /// No description provided for @failedToSavePreferences.
  ///
  /// In en, this message translates to:
  /// **'Failed to save preferences: {error}'**
  String failedToSavePreferences(String error);

  /// No description provided for @featureNotAvailableOnTier.
  ///
  /// In en, this message translates to:
  /// **'Feature not available on {tier}'**
  String featureNotAvailableOnTier(String tier);

  /// No description provided for @fillCategories.
  ///
  /// In en, this message translates to:
  /// **'Fill all categories'**
  String get fillCategories;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

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

  /// No description provided for @filterMessaged.
  ///
  /// In en, this message translates to:
  /// **'Messaged'**
  String get filterMessaged;

  /// No description provided for @filterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get filterNew;

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

  /// No description provided for @filteredFromTotal.
  ///
  /// In en, this message translates to:
  /// **'Filtered from {total}'**
  String filteredFromTotal(int total);

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @firstTo30Wins.
  ///
  /// In en, this message translates to:
  /// **'First to 30 wins!'**
  String get firstTo30Wins;

  /// No description provided for @flashcardReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get flashcardReviewLabel;

  /// No description provided for @flirtyCategory.
  ///
  /// In en, this message translates to:
  /// **'Flirty'**
  String get flirtyCategory;

  /// No description provided for @foodDiningCategory.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get foodDiningCategory;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @freeActionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} free actions remaining today'**
  String freeActionsRemaining(int count);

  /// No description provided for @friendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get friendship;

  /// No description provided for @gameAbandon.
  ///
  /// In en, this message translates to:
  /// **'Abandon'**
  String get gameAbandon;

  /// No description provided for @gameAbandonLoseMessage.
  ///
  /// In en, this message translates to:
  /// **'You will lose this game if you leave now.'**
  String get gameAbandonLoseMessage;

  /// No description provided for @gameAbandonProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'You will lose your progress and return to the lobby.'**
  String get gameAbandonProgressMessage;

  /// No description provided for @gameAbandonTitle.
  ///
  /// In en, this message translates to:
  /// **'Abandon Game?'**
  String get gameAbandonTitle;

  /// No description provided for @gameAbandonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Abandon Game'**
  String get gameAbandonTooltip;

  /// No description provided for @gameCategoriesEnterWordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a word starting with \"{letter}\"...'**
  String gameCategoriesEnterWordHint(String letter);

  /// No description provided for @gameCategoriesFilled.
  ///
  /// In en, this message translates to:
  /// **'filled'**
  String get gameCategoriesFilled;

  /// No description provided for @gameCategoriesNewLetter.
  ///
  /// In en, this message translates to:
  /// **'New Letter!'**
  String get gameCategoriesNewLetter;

  /// No description provided for @gameCategoriesStartsWith.
  ///
  /// In en, this message translates to:
  /// **'{category} — starts with \"{letter}\"'**
  String gameCategoriesStartsWith(String category, String letter);

  /// No description provided for @gameCategoriesTapToFill.
  ///
  /// In en, this message translates to:
  /// **'Tap a category to fill it!'**
  String get gameCategoriesTapToFill;

  /// No description provided for @gameCategoriesTimesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up! Waiting for next round...'**
  String get gameCategoriesTimesUp;

  /// No description provided for @gameCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get gameCategoriesTitle;

  /// No description provided for @gameCategoriesWordAlreadyUsedInCategory.
  ///
  /// In en, this message translates to:
  /// **'Word already used in another category!'**
  String get gameCategoriesWordAlreadyUsedInCategory;

  /// No description provided for @gameCategoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get gameCategoryAnimals;

  /// No description provided for @gameCategoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get gameCategoryClothing;

  /// No description provided for @gameCategoryColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get gameCategoryColors;

  /// No description provided for @gameCategoryCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get gameCategoryCountries;

  /// No description provided for @gameCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get gameCategoryFood;

  /// No description provided for @gameCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get gameCategoryNature;

  /// No description provided for @gameCategoryProfessions.
  ///
  /// In en, this message translates to:
  /// **'Professions'**
  String get gameCategoryProfessions;

  /// No description provided for @gameCategorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get gameCategorySports;

  /// No description provided for @gameCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get gameCategoryTransport;

  /// No description provided for @gameChainBreak.
  ///
  /// In en, this message translates to:
  /// **'CHAIN BREAK!'**
  String get gameChainBreak;

  /// No description provided for @gameChainNextMustStartWith.
  ///
  /// In en, this message translates to:
  /// **'Next word must start with: '**
  String get gameChainNextMustStartWith;

  /// No description provided for @gameChainNoWordsYet.
  ///
  /// In en, this message translates to:
  /// **'No words yet!'**
  String get gameChainNoWordsYet;

  /// No description provided for @gameChainStartWithAnyWord.
  ///
  /// In en, this message translates to:
  /// **'Start the chain with any word'**
  String get gameChainStartWithAnyWord;

  /// No description provided for @gameChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Chain'**
  String get gameChainTitle;

  /// No description provided for @gameChainTypeStartingWithHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word starting with \"{letter}\"...'**
  String gameChainTypeStartingWithHint(String letter);

  /// No description provided for @gameChainTypeToStartHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word to start the chain...'**
  String get gameChainTypeToStartHint;

  /// No description provided for @gameChainWordsChained.
  ///
  /// In en, this message translates to:
  /// **'{count} words chained'**
  String gameChainWordsChained(int count);

  /// No description provided for @gameCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get gameCorrect;

  /// No description provided for @gameDefaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get gameDefaultPlayerName;

  /// No description provided for @gameGrammarDuelAheadBy.
  ///
  /// In en, this message translates to:
  /// **'+{diff} ahead'**
  String gameGrammarDuelAheadBy(int diff);

  /// No description provided for @gameGrammarDuelAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get gameGrammarDuelAnswered;

  /// No description provided for @gameGrammarDuelBehindBy.
  ///
  /// In en, this message translates to:
  /// **'{diff} behind'**
  String gameGrammarDuelBehindBy(int diff);

  /// No description provided for @gameGrammarDuelFast.
  ///
  /// In en, this message translates to:
  /// **'FAST!'**
  String get gameGrammarDuelFast;

  /// No description provided for @gameGrammarDuelGrammarQuestion.
  ///
  /// In en, this message translates to:
  /// **'GRAMMAR QUESTION'**
  String get gameGrammarDuelGrammarQuestion;

  /// No description provided for @gameGrammarDuelPlusPoints.
  ///
  /// In en, this message translates to:
  /// **'+{points} points!'**
  String gameGrammarDuelPlusPoints(int points);

  /// No description provided for @gameGrammarDuelStreakCount.
  ///
  /// In en, this message translates to:
  /// **'x{count} streak!'**
  String gameGrammarDuelStreakCount(int count);

  /// No description provided for @gameGrammarDuelThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get gameGrammarDuelThinking;

  /// No description provided for @gameGrammarDuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar Duel'**
  String get gameGrammarDuelTitle;

  /// No description provided for @gameGrammarDuelVersus.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get gameGrammarDuelVersus;

  /// No description provided for @gameGrammarDuelWrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Wrong answer!'**
  String get gameGrammarDuelWrongAnswer;

  /// No description provided for @gameInvalidAnswer.
  ///
  /// In en, this message translates to:
  /// **'Invalid!'**
  String get gameInvalidAnswer;

  /// No description provided for @gameLanguageBrazilianPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Brazilian Portuguese'**
  String get gameLanguageBrazilianPortuguese;

  /// No description provided for @gameLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get gameLanguageEnglish;

  /// No description provided for @gameLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get gameLanguageFrench;

  /// No description provided for @gameLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get gameLanguageGerman;

  /// No description provided for @gameLanguageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get gameLanguageItalian;

  /// No description provided for @gameLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get gameLanguageJapanese;

  /// No description provided for @gameLanguagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get gameLanguagePortuguese;

  /// No description provided for @gameLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get gameLanguageSpanish;

  /// No description provided for @gameLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get gameLeave;

  /// No description provided for @gameOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get gameOpponent;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @gamePictureGuessAttemptCounter.
  ///
  /// In en, this message translates to:
  /// **'Attempt {current}/{max}'**
  String gamePictureGuessAttemptCounter(int current, int max);

  /// No description provided for @gamePictureGuessCantUseWord.
  ///
  /// In en, this message translates to:
  /// **'You can\'t use the word itself in your clue!'**
  String get gamePictureGuessCantUseWord;

  /// No description provided for @gamePictureGuessClues.
  ///
  /// In en, this message translates to:
  /// **'CLUES'**
  String get gamePictureGuessClues;

  /// No description provided for @gamePictureGuessCluesSent.
  ///
  /// In en, this message translates to:
  /// **'{count} clue(s) sent'**
  String gamePictureGuessCluesSent(int count);

  /// No description provided for @gamePictureGuessCorrectPoints.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points} points'**
  String gamePictureGuessCorrectPoints(int points);

  /// No description provided for @gamePictureGuessCorrectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Correct! Waiting for round to end...'**
  String get gamePictureGuessCorrectWaiting;

  /// No description provided for @gamePictureGuessDescriber.
  ///
  /// In en, this message translates to:
  /// **'DESCRIBER'**
  String get gamePictureGuessDescriber;

  /// No description provided for @gamePictureGuessDescriberRules.
  ///
  /// In en, this message translates to:
  /// **'Give clues to help others guess. No direct translations or spelling hints!'**
  String get gamePictureGuessDescriberRules;

  /// No description provided for @gamePictureGuessGuessTheWord.
  ///
  /// In en, this message translates to:
  /// **'Guess the word!'**
  String get gamePictureGuessGuessTheWord;

  /// No description provided for @gamePictureGuessGuessTheWordUpper.
  ///
  /// In en, this message translates to:
  /// **'GUESS THE WORD!'**
  String get gamePictureGuessGuessTheWordUpper;

  /// No description provided for @gamePictureGuessNoMoreAttempts.
  ///
  /// In en, this message translates to:
  /// **'No more attempts — waiting for round to end'**
  String get gamePictureGuessNoMoreAttempts;

  /// No description provided for @gamePictureGuessNoMoreAttemptsRound.
  ///
  /// In en, this message translates to:
  /// **'No more attempts this round'**
  String get gamePictureGuessNoMoreAttemptsRound;

  /// No description provided for @gamePictureGuessTheWordWas.
  ///
  /// In en, this message translates to:
  /// **'The word was:'**
  String get gamePictureGuessTheWordWas;

  /// No description provided for @gamePictureGuessTitle.
  ///
  /// In en, this message translates to:
  /// **'Picture Guess'**
  String get gamePictureGuessTitle;

  /// No description provided for @gamePictureGuessTypeClueHint.
  ///
  /// In en, this message translates to:
  /// **'Type a clue (no direct translations!)...'**
  String get gamePictureGuessTypeClueHint;

  /// No description provided for @gamePictureGuessTypeGuessHint.
  ///
  /// In en, this message translates to:
  /// **'Type your guess... ({current}/{max})'**
  String gamePictureGuessTypeGuessHint(int current, int max);

  /// No description provided for @gamePictureGuessWaitingForClues.
  ///
  /// In en, this message translates to:
  /// **'Waiting for clues...'**
  String get gamePictureGuessWaitingForClues;

  /// No description provided for @gamePictureGuessWaitingForOthers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for others...'**
  String get gamePictureGuessWaitingForOthers;

  /// No description provided for @gamePictureGuessWrongGuess.
  ///
  /// In en, this message translates to:
  /// **'Wrong guess: \"{guess}\"'**
  String gamePictureGuessWrongGuess(String guess);

  /// No description provided for @gamePictureGuessYouAreDescriber.
  ///
  /// In en, this message translates to:
  /// **'You are the DESCRIBER!'**
  String get gamePictureGuessYouAreDescriber;

  /// No description provided for @gamePictureGuessYourWord.
  ///
  /// In en, this message translates to:
  /// **'YOUR WORD'**
  String get gamePictureGuessYourWord;

  /// No description provided for @gamePlayAnswerSubmittedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Answer submitted! Waiting for others...'**
  String get gamePlayAnswerSubmittedWaiting;

  /// No description provided for @gamePlayCategoriesHeader.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get gamePlayCategoriesHeader;

  /// No description provided for @gamePlayCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String gamePlayCategoryLabel(String category);

  /// No description provided for @gamePlayCorrectPlusPts.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points} pts'**
  String gamePlayCorrectPlusPts(int points);

  /// No description provided for @gamePlayDescribeThisWord.
  ///
  /// In en, this message translates to:
  /// **'DESCRIBE THIS WORD!'**
  String get gamePlayDescribeThisWord;

  /// No description provided for @gamePlayDescribeWordHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the word (don\'t say it!)...'**
  String get gamePlayDescribeWordHint;

  /// No description provided for @gamePlayDescriberIsDescribing.
  ///
  /// In en, this message translates to:
  /// **'{name} is describing a word...'**
  String gamePlayDescriberIsDescribing(String name);

  /// No description provided for @gamePlayDoNotSayWord.
  ///
  /// In en, this message translates to:
  /// **'Do not say the word itself!'**
  String get gamePlayDoNotSayWord;

  /// No description provided for @gamePlayGuessTheWord.
  ///
  /// In en, this message translates to:
  /// **'GUESS THE WORD'**
  String get gamePlayGuessTheWord;

  /// No description provided for @gamePlayIncorrectAnswerWas.
  ///
  /// In en, this message translates to:
  /// **'Incorrect. The answer was \"{answer}\"'**
  String gamePlayIncorrectAnswerWas(String answer);

  /// No description provided for @gamePlayLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARD'**
  String get gamePlayLeaderboard;

  /// No description provided for @gamePlayNameLanguageWordStartingWith.
  ///
  /// In en, this message translates to:
  /// **'Name a {language} word starting with \"{letter}\"'**
  String gamePlayNameLanguageWordStartingWith(String language, String letter);

  /// No description provided for @gamePlayNameWordInCategory.
  ///
  /// In en, this message translates to:
  /// **'Name a word in \"{category}\" starting with \"{letter}\"'**
  String gamePlayNameWordInCategory(String category, String letter);

  /// No description provided for @gamePlayNextWordMustStartWith.
  ///
  /// In en, this message translates to:
  /// **'NEXT WORD MUST START WITH'**
  String get gamePlayNextWordMustStartWith;

  /// No description provided for @gamePlayNoWordsStartChain.
  ///
  /// In en, this message translates to:
  /// **'No words yet - start the chain!'**
  String get gamePlayNoWordsStartChain;

  /// No description provided for @gamePlayPickLetterNameWord.
  ///
  /// In en, this message translates to:
  /// **'Pick a letter, then name a word!'**
  String get gamePlayPickLetterNameWord;

  /// No description provided for @gamePlayPlayerIsChoosing.
  ///
  /// In en, this message translates to:
  /// **'{name} is choosing...'**
  String gamePlayPlayerIsChoosing(String name);

  /// No description provided for @gamePlayPlayerIsThinking.
  ///
  /// In en, this message translates to:
  /// **'{name} is thinking...'**
  String gamePlayPlayerIsThinking(String name);

  /// No description provided for @gamePlayThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme: {theme}'**
  String gamePlayThemeLabel(String theme);

  /// No description provided for @gamePlayTranslateThisWord.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATE THIS WORD'**
  String get gamePlayTranslateThisWord;

  /// No description provided for @gamePlayTypeContainingHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word containing \"{prompt}\"...'**
  String gamePlayTypeContainingHint(String prompt);

  /// No description provided for @gamePlayTypeStartingWithHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word starting with \"{prompt}\"...'**
  String gamePlayTypeStartingWithHint(String prompt);

  /// No description provided for @gamePlayTypeTranslationHint.
  ///
  /// In en, this message translates to:
  /// **'Type the translation...'**
  String get gamePlayTypeTranslationHint;

  /// No description provided for @gamePlayTypeWordContainingLetters.
  ///
  /// In en, this message translates to:
  /// **'Type a word containing these letters!'**
  String get gamePlayTypeWordContainingLetters;

  /// No description provided for @gamePlayTypeYourAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get gamePlayTypeYourAnswerHint;

  /// No description provided for @gamePlayTypeYourGuessBelow.
  ///
  /// In en, this message translates to:
  /// **'Type your guess below!'**
  String get gamePlayTypeYourGuessBelow;

  /// No description provided for @gamePlayTypeYourGuessHint.
  ///
  /// In en, this message translates to:
  /// **'Type your guess...'**
  String get gamePlayTypeYourGuessHint;

  /// No description provided for @gamePlayUseChatToDescribe.
  ///
  /// In en, this message translates to:
  /// **'Use the chat to describe the word to other players'**
  String get gamePlayUseChatToDescribe;

  /// No description provided for @gamePlayWaitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent...'**
  String get gamePlayWaitingForOpponent;

  /// No description provided for @gamePlayWordStartingWithLetterHint.
  ///
  /// In en, this message translates to:
  /// **'Word starting with \"{letter}\"...'**
  String gamePlayWordStartingWithLetterHint(String letter);

  /// No description provided for @gamePlayWordStartingWithPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Word starting with \"{prompt}\"...'**
  String gamePlayWordStartingWithPromptHint(String prompt);

  /// No description provided for @gamePlayYourTurnFlipCards.
  ///
  /// In en, this message translates to:
  /// **'Your turn - flip two cards!'**
  String get gamePlayYourTurnFlipCards;

  /// No description provided for @gamePlayersTurn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String gamePlayersTurn(String name);

  /// No description provided for @gamePlusPts.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String gamePlusPts(int points);

  /// No description provided for @gamePositionFirst.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get gamePositionFirst;

  /// No description provided for @gamePositionNth.
  ///
  /// In en, this message translates to:
  /// **'{pos}th'**
  String gamePositionNth(int pos);

  /// No description provided for @gamePositionSecond.
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get gamePositionSecond;

  /// No description provided for @gamePositionThird.
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get gamePositionThird;

  /// No description provided for @gameResultsBackToLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to Lobby'**
  String get gameResultsBackToLobby;

  /// No description provided for @gameResultsBaseXp.
  ///
  /// In en, this message translates to:
  /// **'Base XP'**
  String get gameResultsBaseXp;

  /// No description provided for @gameResultsCoinsEarned.
  ///
  /// In en, this message translates to:
  /// **'Coins Earned'**
  String get gameResultsCoinsEarned;

  /// No description provided for @gameResultsDifficultyBonus.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Bonus (Lv.{level})'**
  String gameResultsDifficultyBonus(int level);

  /// No description provided for @gameResultsFinalStandings.
  ///
  /// In en, this message translates to:
  /// **'FINAL STANDINGS'**
  String get gameResultsFinalStandings;

  /// No description provided for @gameResultsGameOver.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get gameResultsGameOver;

  /// No description provided for @gameResultsNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins ({amount} required)'**
  String gameResultsNotEnoughCoins(int amount);

  /// No description provided for @gameResultsPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get gameResultsPlayAgain;

  /// No description provided for @gameResultsPlusXp.
  ///
  /// In en, this message translates to:
  /// **'+{amount} XP'**
  String gameResultsPlusXp(int amount);

  /// No description provided for @gameResultsRewardsEarned.
  ///
  /// In en, this message translates to:
  /// **'REWARDS EARNED'**
  String get gameResultsRewardsEarned;

  /// No description provided for @gameResultsTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get gameResultsTotalXp;

  /// No description provided for @gameResultsVictory.
  ///
  /// In en, this message translates to:
  /// **'VICTORY!'**
  String get gameResultsVictory;

  /// No description provided for @gameResultsWhatYouLearned.
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU LEARNED'**
  String get gameResultsWhatYouLearned;

  /// No description provided for @gameResultsWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get gameResultsWinner;

  /// No description provided for @gameResultsWinnerBonus.
  ///
  /// In en, this message translates to:
  /// **'Winner Bonus'**
  String get gameResultsWinnerBonus;

  /// No description provided for @gameResultsYouWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get gameResultsYouWon;

  /// No description provided for @gameRoundCounter.
  ///
  /// In en, this message translates to:
  /// **'Round {current}/{total}'**
  String gameRoundCounter(int current, int total);

  /// No description provided for @gameRoundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String gameRoundNumber(int number);

  /// No description provided for @gameScorePts.
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String gameScorePts(int score);

  /// No description provided for @gameSnapsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get gameSnapsNoMatch;

  /// No description provided for @gameSnapsPairsFound.
  ///
  /// In en, this message translates to:
  /// **'{matched} / {total} pairs found'**
  String gameSnapsPairsFound(int matched, int total);

  /// No description provided for @gameSnapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Snaps'**
  String get gameSnapsTitle;

  /// No description provided for @gameSnapsYourTurnFlipCards.
  ///
  /// In en, this message translates to:
  /// **'YOUR TURN — Flip 2 cards!'**
  String get gameSnapsYourTurnFlipCards;

  /// No description provided for @gameSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get gameSomeone;

  /// No description provided for @gameTapplesNameWordStartingWith.
  ///
  /// In en, this message translates to:
  /// **'Name a word starting with \"{letter}\"'**
  String gameTapplesNameWordStartingWith(String letter);

  /// No description provided for @gameTapplesPickLetterFromWheel.
  ///
  /// In en, this message translates to:
  /// **'Pick a letter from the wheel!'**
  String get gameTapplesPickLetterFromWheel;

  /// No description provided for @gameTapplesPickLetterNameWord.
  ///
  /// In en, this message translates to:
  /// **'Pick a letter, name a word'**
  String get gameTapplesPickLetterNameWord;

  /// No description provided for @gameTapplesPlayerLostLife.
  ///
  /// In en, this message translates to:
  /// **'{name} lost a life'**
  String gameTapplesPlayerLostLife(String name);

  /// No description provided for @gameTapplesTimeUp.
  ///
  /// In en, this message translates to:
  /// **'TIME UP!'**
  String get gameTapplesTimeUp;

  /// No description provided for @gameTapplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Tapples'**
  String get gameTapplesTitle;

  /// No description provided for @gameTapplesWordStartingWithHint.
  ///
  /// In en, this message translates to:
  /// **'Word starting with \"{letter}\"...'**
  String gameTapplesWordStartingWithHint(String letter);

  /// No description provided for @gameTapplesWordsUsedLettersLeft.
  ///
  /// In en, this message translates to:
  /// **'{wordsCount} words used  •  {lettersCount} letters left'**
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount);

  /// No description provided for @gameTranslationRaceCheckCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get gameTranslationRaceCheckCorrect;

  /// No description provided for @gameTranslationRaceFirstTo30.
  ///
  /// In en, this message translates to:
  /// **'First to 30 wins!'**
  String get gameTranslationRaceFirstTo30;

  /// No description provided for @gameTranslationRaceRoundShort.
  ///
  /// In en, this message translates to:
  /// **'R{current}/{total}'**
  String gameTranslationRaceRoundShort(int current, int total);

  /// No description provided for @gameTranslationRaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation Race'**
  String get gameTranslationRaceTitle;

  /// No description provided for @gameTranslationRaceTranslateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to {language}'**
  String gameTranslationRaceTranslateTo(String language);

  /// No description provided for @gameTranslationRaceWaitingForOthers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for others... {answered}/{total} answered'**
  String gameTranslationRaceWaitingForOthers(int answered, int total);

  /// No description provided for @gameWaitForYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Wait for your turn...'**
  String get gameWaitForYourTurn;

  /// No description provided for @gameWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get gameWaiting;

  /// No description provided for @gameWaitingCancelReady.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ready'**
  String get gameWaitingCancelReady;

  /// No description provided for @gameWaitingCountdownGo.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get gameWaitingCountdownGo;

  /// No description provided for @gameWaitingDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get gameWaitingDisconnected;

  /// No description provided for @gameWaitingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get gameWaitingEllipsis;

  /// No description provided for @gameWaitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Players...'**
  String get gameWaitingForPlayers;

  /// No description provided for @gameWaitingGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get Ready...'**
  String get gameWaitingGetReady;

  /// No description provided for @gameWaitingHost.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get gameWaitingHost;

  /// No description provided for @gameWaitingInviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied!'**
  String get gameWaitingInviteCodeCopied;

  /// No description provided for @gameWaitingInviteCodeHeader.
  ///
  /// In en, this message translates to:
  /// **'INVITE CODE'**
  String get gameWaitingInviteCodeHeader;

  /// No description provided for @gameWaitingInvitePlayer.
  ///
  /// In en, this message translates to:
  /// **'Invite Player'**
  String get gameWaitingInvitePlayer;

  /// No description provided for @gameWaitingLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get gameWaitingLeaveRoom;

  /// No description provided for @gameWaitingLevelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String gameWaitingLevelNumber(int level);

  /// No description provided for @gameWaitingNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not Ready'**
  String get gameWaitingNotReady;

  /// No description provided for @gameWaitingNotReadyCount.
  ///
  /// In en, this message translates to:
  /// **'({count} not ready)'**
  String gameWaitingNotReadyCount(int count);

  /// No description provided for @gameWaitingPlayersHeader.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get gameWaitingPlayersHeader;

  /// No description provided for @gameWaitingPlayersInRoom.
  ///
  /// In en, this message translates to:
  /// **'{count} players in room'**
  String gameWaitingPlayersInRoom(int count);

  /// No description provided for @gameWaitingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get gameWaitingReady;

  /// No description provided for @gameWaitingReadyUp.
  ///
  /// In en, this message translates to:
  /// **'Ready Up'**
  String get gameWaitingReadyUp;

  /// No description provided for @gameWaitingRoundsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String gameWaitingRoundsCount(int count);

  /// No description provided for @gameWaitingShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share this code with friends to join'**
  String get gameWaitingShareCode;

  /// No description provided for @gameWaitingStartGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get gameWaitingStartGame;

  /// No description provided for @gameWordAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Word already used!'**
  String get gameWordAlreadyUsed;

  /// No description provided for @gameWordBombBoom.
  ///
  /// In en, this message translates to:
  /// **'BOOM!'**
  String get gameWordBombBoom;

  /// No description provided for @gameWordBombMustContain.
  ///
  /// In en, this message translates to:
  /// **'Word must contain \"{prompt}\"'**
  String gameWordBombMustContain(String prompt);

  /// No description provided for @gameWordBombReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get gameWordBombReport;

  /// No description provided for @gameWordBombReportContent.
  ///
  /// In en, this message translates to:
  /// **'Report this word as invalid or inappropriate.'**
  String get gameWordBombReportContent;

  /// No description provided for @gameWordBombReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report \"{word}\"?'**
  String gameWordBombReportTitle(String word);

  /// No description provided for @gameWordBombTimeRanOutLostLife.
  ///
  /// In en, this message translates to:
  /// **'Time ran out! You lost a life.'**
  String get gameWordBombTimeRanOutLostLife;

  /// No description provided for @gameWordBombTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Bomb'**
  String get gameWordBombTitle;

  /// No description provided for @gameWordBombTypeContainingHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word containing \"{prompt}\"...'**
  String gameWordBombTypeContainingHint(String prompt);

  /// No description provided for @gameWordBombUsedWords.
  ///
  /// In en, this message translates to:
  /// **'Used Words'**
  String get gameWordBombUsedWords;

  /// No description provided for @gameWordBombWordReported.
  ///
  /// In en, this message translates to:
  /// **'Word reported'**
  String get gameWordBombWordReported;

  /// No description provided for @gameWordBombWordsUsedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words used'**
  String gameWordBombWordsUsedCount(int count);

  /// No description provided for @gameWordMustStartWith.
  ///
  /// In en, this message translates to:
  /// **'Word must start with \"{letter}\"'**
  String gameWordMustStartWith(String letter);

  /// No description provided for @gameWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get gameWrong;

  /// No description provided for @gameYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get gameYou;

  /// No description provided for @gameYourTurn.
  ///
  /// In en, this message translates to:
  /// **'YOUR TURN!'**
  String get gameYourTurn;

  /// No description provided for @gamificationAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get gamificationAchievements;

  /// No description provided for @gamificationAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gamificationAll;

  /// No description provided for @gamificationChallengeCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} completed!'**
  String gamificationChallengeCompleted(Object name);

  /// No description provided for @gamificationClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get gamificationClaim;

  /// No description provided for @gamificationClaimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get gamificationClaimReward;

  /// No description provided for @gamificationCoinsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Coins Available'**
  String get gamificationCoinsAvailable;

  /// No description provided for @gamificationDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get gamificationDaily;

  /// No description provided for @gamificationDailyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenges'**
  String get gamificationDailyChallenges;

  /// No description provided for @gamificationDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get gamificationDayStreak;

  /// No description provided for @gamificationDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get gamificationDone;

  /// No description provided for @gamificationEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned on {date}'**
  String gamificationEarnedOn(Object date);

  /// No description provided for @gamificationEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get gamificationEasy;

  /// No description provided for @gamificationEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get gamificationEngagement;

  /// No description provided for @gamificationEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get gamificationEpic;

  /// No description provided for @gamificationExperiencePoints.
  ///
  /// In en, this message translates to:
  /// **'Experience Points'**
  String get gamificationExperiencePoints;

  /// No description provided for @gamificationGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get gamificationGlobal;

  /// No description provided for @gamificationHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gamificationHard;

  /// No description provided for @gamificationLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get gamificationLeaderboard;

  /// No description provided for @gamificationLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String gamificationLevel(Object level);

  /// No description provided for @gamificationLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get gamificationLevelLabel;

  /// No description provided for @gamificationLevelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level}'**
  String gamificationLevelShort(Object level);

  /// No description provided for @gamificationLoadingAchievements.
  ///
  /// In en, this message translates to:
  /// **'Loading achievements...'**
  String get gamificationLoadingAchievements;

  /// No description provided for @gamificationLoadingChallenges.
  ///
  /// In en, this message translates to:
  /// **'Loading challenges...'**
  String get gamificationLoadingChallenges;

  /// No description provided for @gamificationLoadingRankings.
  ///
  /// In en, this message translates to:
  /// **'Loading rankings...'**
  String get gamificationLoadingRankings;

  /// No description provided for @gamificationMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get gamificationMedium;

  /// No description provided for @gamificationMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get gamificationMilestones;

  /// No description provided for @gamificationMonthly.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get gamificationMonthly;

  /// No description provided for @gamificationMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get gamificationMyProgress;

  /// No description provided for @gamificationNoAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements found'**
  String get gamificationNoAchievements;

  /// No description provided for @gamificationNoAchievementsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No achievements in this category'**
  String get gamificationNoAchievementsInCategory;

  /// No description provided for @gamificationNoChallenges.
  ///
  /// In en, this message translates to:
  /// **'No challenges available'**
  String get gamificationNoChallenges;

  /// No description provided for @gamificationNoChallengesType.
  ///
  /// In en, this message translates to:
  /// **'No {type} challenges available'**
  String gamificationNoChallengesType(Object type);

  /// No description provided for @gamificationNoLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data'**
  String get gamificationNoLeaderboard;

  /// No description provided for @gamificationPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get gamificationPremium;

  /// No description provided for @gamificationPremiumMember.
  ///
  /// In en, this message translates to:
  /// **'Premium Member'**
  String get gamificationPremiumMember;

  /// No description provided for @gamificationProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get gamificationProgress;

  /// No description provided for @gamificationRank.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get gamificationRank;

  /// No description provided for @gamificationRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get gamificationRankLabel;

  /// No description provided for @gamificationRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional'**
  String get gamificationRegional;

  /// No description provided for @gamificationReward.
  ///
  /// In en, this message translates to:
  /// **'Reward: {amount} {type}'**
  String gamificationReward(Object amount, Object type);

  /// No description provided for @gamificationSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get gamificationSocial;

  /// No description provided for @gamificationSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get gamificationSpecial;

  /// No description provided for @gamificationTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get gamificationTotal;

  /// No description provided for @gamificationUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get gamificationUnlocked;

  /// No description provided for @gamificationVerifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified User'**
  String get gamificationVerifiedUser;

  /// No description provided for @gamificationVipMember.
  ///
  /// In en, this message translates to:
  /// **'VIP Member'**
  String get gamificationVipMember;

  /// No description provided for @gamificationWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get gamificationWeekly;

  /// No description provided for @gamificationXpAvailable.
  ///
  /// In en, this message translates to:
  /// **'XP Available'**
  String get gamificationXpAvailable;

  /// No description provided for @gamificationYearly.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get gamificationYearly;

  /// No description provided for @gamificationYourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get gamificationYourPosition;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @giftCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get giftCategoryAll;

  /// No description provided for @giftFromSender.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String giftFromSender(Object name);

  /// No description provided for @giftGetCoins.
  ///
  /// In en, this message translates to:
  /// **'Get Coins'**
  String get giftGetCoins;

  /// No description provided for @giftNoGiftsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No gifts available'**
  String get giftNoGiftsAvailable;

  /// No description provided for @giftNoGiftsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No gifts in this category'**
  String get giftNoGiftsInCategory;

  /// No description provided for @giftNoGiftsYet.
  ///
  /// In en, this message translates to:
  /// **'No gifts yet'**
  String get giftNoGiftsYet;

  /// No description provided for @giftNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not Enough Coins'**
  String get giftNotEnoughCoins;

  /// No description provided for @giftPriceCoins.
  ///
  /// In en, this message translates to:
  /// **'{price} coins'**
  String giftPriceCoins(Object price);

  /// No description provided for @giftReceivedGifts.
  ///
  /// In en, this message translates to:
  /// **'Received Gifts'**
  String get giftReceivedGifts;

  /// No description provided for @giftReceivedGiftsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Gifts you receive will appear here'**
  String get giftReceivedGiftsEmpty;

  /// No description provided for @giftSendGift.
  ///
  /// In en, this message translates to:
  /// **'Send Gift'**
  String get giftSendGift;

  /// No description provided for @giftSendGiftTo.
  ///
  /// In en, this message translates to:
  /// **'Send Gift to {name}'**
  String giftSendGiftTo(Object name);

  /// No description provided for @giftSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get giftSending;

  /// No description provided for @giftSentTo.
  ///
  /// In en, this message translates to:
  /// **'Gift sent to {name}!'**
  String giftSentTo(Object name);

  /// No description provided for @giftYouHaveCoins.
  ///
  /// In en, this message translates to:
  /// **'You have {available} coins.'**
  String giftYouHaveCoins(Object available);

  /// No description provided for @giftYouNeedCoins.
  ///
  /// In en, this message translates to:
  /// **'You need {required} coins for this gift.'**
  String giftYouNeedCoins(Object required);

  /// No description provided for @giftYouNeedMoreCoins.
  ///
  /// In en, this message translates to:
  /// **'You need {shortfall} more coins.'**
  String giftYouNeedMoreCoins(Object shortfall);

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @grantAlbumAccess.
  ///
  /// In en, this message translates to:
  /// **'Share my album'**
  String get grantAlbumAccess;

  /// No description provided for @greatInterestsHelp.
  ///
  /// In en, this message translates to:
  /// **'Great! Your interests help us find better matches'**
  String get greatInterestsHelp;

  /// No description provided for @greengoLearn.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Learn'**
  String get greengoLearn;

  /// No description provided for @greengoPlay.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Play'**
  String get greengoPlay;

  /// No description provided for @greengoXpLabel.
  ///
  /// In en, this message translates to:
  /// **'GreenGoXP'**
  String get greengoXpLabel;

  /// No description provided for @greetingsCategory.
  ///
  /// In en, this message translates to:
  /// **'Greetings'**
  String get greetingsCategory;

  /// No description provided for @guideBadge.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guideBadge;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @helpOthersFindYou.
  ///
  /// In en, this message translates to:
  /// **'Help others find you on social media'**
  String get helpOthersFindYou;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @icebreakersCategoryCompliments.
  ///
  /// In en, this message translates to:
  /// **'Compliments'**
  String get icebreakersCategoryCompliments;

  /// No description provided for @icebreakersCategoryDateIdeas.
  ///
  /// In en, this message translates to:
  /// **'Date Ideas'**
  String get icebreakersCategoryDateIdeas;

  /// No description provided for @icebreakersCategoryDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get icebreakersCategoryDeep;

  /// No description provided for @icebreakersCategoryDreams.
  ///
  /// In en, this message translates to:
  /// **'Dreams'**
  String get icebreakersCategoryDreams;

  /// No description provided for @icebreakersCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get icebreakersCategoryFood;

  /// No description provided for @icebreakersCategoryFunny.
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get icebreakersCategoryFunny;

  /// No description provided for @icebreakersCategoryHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get icebreakersCategoryHobbies;

  /// No description provided for @icebreakersCategoryHypothetical.
  ///
  /// In en, this message translates to:
  /// **'Hypothetical'**
  String get icebreakersCategoryHypothetical;

  /// No description provided for @icebreakersCategoryMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get icebreakersCategoryMovies;

  /// No description provided for @icebreakersCategoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get icebreakersCategoryMusic;

  /// No description provided for @icebreakersCategoryPersonality.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get icebreakersCategoryPersonality;

  /// No description provided for @icebreakersCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get icebreakersCategoryTravel;

  /// No description provided for @icebreakersCategoryTwoTruths.
  ///
  /// In en, this message translates to:
  /// **'Two Truths'**
  String get icebreakersCategoryTwoTruths;

  /// No description provided for @icebreakersCategoryWouldYouRather.
  ///
  /// In en, this message translates to:
  /// **'Would You Rather'**
  String get icebreakersCategoryWouldYouRather;

  /// No description provided for @icebreakersLabel.
  ///
  /// In en, this message translates to:
  /// **'Icebreaker'**
  String get icebreakersLabel;

  /// No description provided for @icebreakersNoneInCategory.
  ///
  /// In en, this message translates to:
  /// **'No icebreakers in this category'**
  String get icebreakersNoneInCategory;

  /// No description provided for @icebreakersQuickAnswers.
  ///
  /// In en, this message translates to:
  /// **'Quick answers:'**
  String get icebreakersQuickAnswers;

  /// No description provided for @icebreakersSendAnIcebreaker.
  ///
  /// In en, this message translates to:
  /// **'Send an icebreaker'**
  String get icebreakersSendAnIcebreaker;

  /// No description provided for @icebreakersSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to {name}'**
  String icebreakersSendTo(Object name);

  /// No description provided for @icebreakersSendWithoutAnswer.
  ///
  /// In en, this message translates to:
  /// **'Send without answer'**
  String get icebreakersSendWithoutAnswer;

  /// No description provided for @icebreakersTitle.
  ///
  /// In en, this message translates to:
  /// **'Icebreakers'**
  String get icebreakersTitle;

  /// No description provided for @idiomsCategory.
  ///
  /// In en, this message translates to:
  /// **'Idioms'**
  String get idiomsCategory;

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

  /// No description provided for @incorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrectAnswer;

  /// No description provided for @infoUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your basic information has been saved'**
  String get infoUpdatedMessage;

  /// No description provided for @infoUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Info Updated!'**
  String get infoUpdatedTitle;

  /// No description provided for @insufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coins'**
  String get insufficientCoins;

  /// No description provided for @insufficientCoinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Coins'**
  String get insufficientCoinsTitle;

  /// No description provided for @interestArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get interestArt;

  /// No description provided for @interestBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get interestBeach;

  /// No description provided for @interestBeer.
  ///
  /// In en, this message translates to:
  /// **'Beer'**
  String get interestBeer;

  /// No description provided for @interestBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get interestBusiness;

  /// No description provided for @interestCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get interestCamping;

  /// No description provided for @interestCats.
  ///
  /// In en, this message translates to:
  /// **'Cats'**
  String get interestCats;

  /// No description provided for @interestCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get interestCoffee;

  /// No description provided for @interestCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get interestCooking;

  /// No description provided for @interestCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get interestCycling;

  /// No description provided for @interestDance.
  ///
  /// In en, this message translates to:
  /// **'Dance'**
  String get interestDance;

  /// No description provided for @interestDancing.
  ///
  /// In en, this message translates to:
  /// **'Dancing'**
  String get interestDancing;

  /// No description provided for @interestDogs.
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get interestDogs;

  /// No description provided for @interestEntrepreneurship.
  ///
  /// In en, this message translates to:
  /// **'Entrepreneurship'**
  String get interestEntrepreneurship;

  /// No description provided for @interestEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get interestEnvironment;

  /// No description provided for @interestFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get interestFashion;

  /// No description provided for @interestFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get interestFitness;

  /// No description provided for @interestFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get interestFood;

  /// No description provided for @interestGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get interestGaming;

  /// No description provided for @interestHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get interestHiking;

  /// No description provided for @interestHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get interestHistory;

  /// No description provided for @interestInvesting.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get interestInvesting;

  /// No description provided for @interestLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get interestLanguages;

  /// No description provided for @interestMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get interestMeditation;

  /// No description provided for @interestMountains.
  ///
  /// In en, this message translates to:
  /// **'Mountains'**
  String get interestMountains;

  /// No description provided for @interestMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get interestMovies;

  /// No description provided for @interestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get interestMusic;

  /// No description provided for @interestNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get interestNature;

  /// No description provided for @interestPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get interestPets;

  /// No description provided for @interestPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interestPhotography;

  /// No description provided for @interestPoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get interestPoetry;

  /// No description provided for @interestPolitics.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get interestPolitics;

  /// No description provided for @interestReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get interestReading;

  /// No description provided for @interestRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get interestRunning;

  /// No description provided for @interestScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get interestScience;

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

  /// No description provided for @interestSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Spirituality'**
  String get interestSpirituality;

  /// No description provided for @interestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get interestSports;

  /// No description provided for @interestSurfing.
  ///
  /// In en, this message translates to:
  /// **'Surfing'**
  String get interestSurfing;

  /// No description provided for @interestSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get interestSwimming;

  /// No description provided for @interestTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get interestTeaching;

  /// No description provided for @interestTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get interestTechnology;

  /// No description provided for @interestTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get interestTravel;

  /// No description provided for @interestVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get interestVegan;

  /// No description provided for @interestVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get interestVegetarian;

  /// No description provided for @interestVolunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get interestVolunteering;

  /// No description provided for @interestWine.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get interestWine;

  /// No description provided for @interestWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get interestWriting;

  /// No description provided for @interestYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get interestYoga;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @interestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} interests'**
  String interestsCount(int count);

  /// No description provided for @interestsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{selected}/{max} interests selected'**
  String interestsSelectedCount(int selected, int max);

  /// No description provided for @interestsUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your interests have been saved'**
  String get interestsUpdatedMessage;

  /// No description provided for @interestsUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Interests Updated!'**
  String get interestsUpdatedTitle;

  /// No description provided for @invalidWord.
  ///
  /// In en, this message translates to:
  /// **'Invalid word'**
  String get invalidWord;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied!'**
  String get inviteCodeCopied;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @itsAMatch.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Exchange!'**
  String get itsAMatch;

  /// No description provided for @joinMessage.
  ///
  /// In en, this message translates to:
  /// **'Join GreenGoChat and find your perfect match'**
  String get joinMessage;

  /// No description provided for @keepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get keepSwiping;

  /// No description provided for @langMatchBadge.
  ///
  /// In en, this message translates to:
  /// **'Lang Match'**
  String get langMatchBadge;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChangedTo(String language);

  /// No description provided for @languagePacksBtn.
  ///
  /// In en, this message translates to:
  /// **'Language Packs'**
  String get languagePacksBtn;

  /// No description provided for @languagePacksShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Packs Shop'**
  String get languagePacksShopTitle;

  /// No description provided for @languagesToDownloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages to download:'**
  String get languagesToDownloadLabel;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @leaderboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See global and regional rankings'**
  String get leaderboardSubtitle;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @learningAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get learningAccuracy;

  /// No description provided for @learningActiveThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Active This Week'**
  String get learningActiveThisWeek;

  /// No description provided for @learningAddLessonSection.
  ///
  /// In en, this message translates to:
  /// **'Add Lesson Section'**
  String get learningAddLessonSection;

  /// No description provided for @learningAiConversationCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Conversation Coach'**
  String get learningAiConversationCoach;

  /// No description provided for @learningAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get learningAllCategories;

  /// No description provided for @learningAllLessons.
  ///
  /// In en, this message translates to:
  /// **'All Lessons'**
  String get learningAllLessons;

  /// No description provided for @learningAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get learningAllLevels;

  /// No description provided for @learningAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get learningAmount;

  /// No description provided for @learningAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get learningAmountLabel;

  /// No description provided for @learningAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get learningAnalytics;

  /// No description provided for @learningAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String learningAnswer(Object answer);

  /// No description provided for @learningApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get learningApplyFilters;

  /// No description provided for @learningAreasToImprove.
  ///
  /// In en, this message translates to:
  /// **'Areas to Improve'**
  String get learningAreasToImprove;

  /// No description provided for @learningAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get learningAvailableBalance;

  /// No description provided for @learningAverageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get learningAverageRating;

  /// No description provided for @learningBeginnerProgress.
  ///
  /// In en, this message translates to:
  /// **'Beginner Progress'**
  String get learningBeginnerProgress;

  /// No description provided for @learningBonusCoins.
  ///
  /// In en, this message translates to:
  /// **'Bonus Coins'**
  String get learningBonusCoins;

  /// No description provided for @learningCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get learningCategory;

  /// No description provided for @learningCategoryProgress.
  ///
  /// In en, this message translates to:
  /// **'Category Progress'**
  String get learningCategoryProgress;

  /// No description provided for @learningCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get learningCheck;

  /// No description provided for @learningCheckBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon!'**
  String get learningCheckBackSoon;

  /// No description provided for @learningCoachSessionCost.
  ///
  /// In en, this message translates to:
  /// **'10 coins/session  |  25 XP reward'**
  String get learningCoachSessionCost;

  /// No description provided for @learningContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get learningContinue;

  /// No description provided for @learningCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get learningCorrect;

  /// No description provided for @learningCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct: {answer}'**
  String learningCorrectAnswer(Object answer);

  /// No description provided for @learningCorrectAnswerIs.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String learningCorrectAnswerIs(Object answer);

  /// No description provided for @learningCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get learningCorrectAnswers;

  /// No description provided for @learningCorrectLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get learningCorrectLabel;

  /// No description provided for @learningCorrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get learningCorrections;

  /// No description provided for @learningCreateLesson.
  ///
  /// In en, this message translates to:
  /// **'Create Lesson'**
  String get learningCreateLesson;

  /// No description provided for @learningCreateNewLesson.
  ///
  /// In en, this message translates to:
  /// **'Create New Lesson'**
  String get learningCreateNewLesson;

  /// No description provided for @learningCustomPackTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"Spanish Greetings for Dating\"'**
  String get learningCustomPackTitleHint;

  /// No description provided for @learningDescribeImage.
  ///
  /// In en, this message translates to:
  /// **'Describe this image'**
  String get learningDescribeImage;

  /// No description provided for @learningDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What will students learn?'**
  String get learningDescriptionHint;

  /// No description provided for @learningDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get learningDescriptionLabel;

  /// No description provided for @learningDifficultyLevel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Level'**
  String get learningDifficultyLevel;

  /// No description provided for @learningDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get learningDone;

  /// No description provided for @learningDraftSave.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get learningDraftSave;

  /// No description provided for @learningDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved!'**
  String get learningDraftSaved;

  /// No description provided for @learningEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get learningEarned;

  /// No description provided for @learningEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get learningEdit;

  /// No description provided for @learningEndSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get learningEndSession;

  /// No description provided for @learningEndSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Your current session progress will be lost. Would you like to end the session and see your score first?'**
  String get learningEndSessionBody;

  /// No description provided for @learningEndSessionQuestion.
  ///
  /// In en, this message translates to:
  /// **'End Session?'**
  String get learningEndSessionQuestion;

  /// No description provided for @learningExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get learningExit;

  /// No description provided for @learningFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get learningFalse;

  /// No description provided for @learningFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get learningFilterAll;

  /// No description provided for @learningFilterDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get learningFilterDraft;

  /// No description provided for @learningFilterLessons.
  ///
  /// In en, this message translates to:
  /// **'Filter Lessons'**
  String get learningFilterLessons;

  /// No description provided for @learningFilterPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get learningFilterPublished;

  /// No description provided for @learningFilterUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get learningFilterUnderReview;

  /// No description provided for @learningFluency.
  ///
  /// In en, this message translates to:
  /// **'Fluency'**
  String get learningFluency;

  /// No description provided for @learningFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get learningFree;

  /// No description provided for @learningGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get learningGoBack;

  /// No description provided for @learningGoalCompleteLessons.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 lessons'**
  String get learningGoalCompleteLessons;

  /// No description provided for @learningGoalEarnXp.
  ///
  /// In en, this message translates to:
  /// **'Earn 500 XP'**
  String get learningGoalEarnXp;

  /// No description provided for @learningGoalPracticeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Practice 30 minutes'**
  String get learningGoalPracticeMinutes;

  /// No description provided for @learningGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get learningGrammar;

  /// No description provided for @learningHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get learningHint;

  /// No description provided for @learningLangBrazilianPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Brazilian Portuguese'**
  String get learningLangBrazilianPortuguese;

  /// No description provided for @learningLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get learningLangEnglish;

  /// No description provided for @learningLangFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get learningLangFrench;

  /// No description provided for @learningLangGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get learningLangGerman;

  /// No description provided for @learningLangItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get learningLangItalian;

  /// No description provided for @learningLangPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get learningLangPortuguese;

  /// No description provided for @learningLangSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get learningLangSpanish;

  /// No description provided for @learningLanguagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5 languages. This helps us connect you with native speakers and learning partners.'**
  String get learningLanguagesSubtitle;

  /// No description provided for @learningLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'What languages do you want to learn?'**
  String get learningLanguagesTitle;

  /// No description provided for @learningLanguagesToLearn.
  ///
  /// In en, this message translates to:
  /// **'Languages to learn ({count}/5)'**
  String learningLanguagesToLearn(Object count);

  /// No description provided for @learningLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get learningLastMonth;

  /// No description provided for @learningLearnLanguage.
  ///
  /// In en, this message translates to:
  /// **'Learn {language}'**
  String learningLearnLanguage(Object language);

  /// No description provided for @learningLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get learningLearned;

  /// No description provided for @learningLessonComplete.
  ///
  /// In en, this message translates to:
  /// **'Lesson Complete!'**
  String get learningLessonComplete;

  /// No description provided for @learningLessonCompleteUpper.
  ///
  /// In en, this message translates to:
  /// **'LESSON COMPLETE!'**
  String get learningLessonCompleteUpper;

  /// No description provided for @learningLessonContent.
  ///
  /// In en, this message translates to:
  /// **'Lesson Content'**
  String get learningLessonContent;

  /// No description provided for @learningLessonNumber.
  ///
  /// In en, this message translates to:
  /// **'Lesson {number}'**
  String learningLessonNumber(Object number);

  /// No description provided for @learningLessonSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Lesson submitted for review!'**
  String get learningLessonSubmitted;

  /// No description provided for @learningLessonTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson Title'**
  String get learningLessonTitle;

  /// No description provided for @learningLessonTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"Spanish Greetings for Dating\"'**
  String get learningLessonTitleHint;

  /// No description provided for @learningLessonTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Lesson Title'**
  String get learningLessonTitleLabel;

  /// No description provided for @learningLessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get learningLessonsLabel;

  /// No description provided for @learningLetsStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start!'**
  String get learningLetsStart;

  /// No description provided for @learningLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get learningLevel;

  /// No description provided for @learningLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'LV {level}'**
  String learningLevelBadge(Object level);

  /// No description provided for @learningLevelRequired.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String learningLevelRequired(Object level);

  /// No description provided for @learningListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get learningListen;

  /// No description provided for @learningListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get learningListening;

  /// No description provided for @learningLongPressForTranslation.
  ///
  /// In en, this message translates to:
  /// **'Long-press for translation'**
  String get learningLongPressForTranslation;

  /// No description provided for @learningMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get learningMessages;

  /// No description provided for @learningMessagesSent.
  ///
  /// In en, this message translates to:
  /// **'Messages sent'**
  String get learningMessagesSent;

  /// No description provided for @learningMinimumWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal: \$50.00'**
  String get learningMinimumWithdrawal;

  /// No description provided for @learningMonthlyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Monthly Earnings'**
  String get learningMonthlyEarnings;

  /// No description provided for @learningMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get learningMyProgress;

  /// No description provided for @learningNativeLabel.
  ///
  /// In en, this message translates to:
  /// **'(native)'**
  String get learningNativeLabel;

  /// No description provided for @learningNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Your native language'**
  String get learningNativeLanguage;

  /// No description provided for @learningNeedMinPercent.
  ///
  /// In en, this message translates to:
  /// **'You need at least {threshold}% to pass this lesson.'**
  String learningNeedMinPercent(Object threshold);

  /// No description provided for @learningNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get learningNext;

  /// No description provided for @learningNoExercisesInSection.
  ///
  /// In en, this message translates to:
  /// **'No exercises in this section'**
  String get learningNoExercisesInSection;

  /// No description provided for @learningNoLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lessons available yet'**
  String get learningNoLessonsAvailable;

  /// No description provided for @learningNoPacksFound.
  ///
  /// In en, this message translates to:
  /// **'No packs found'**
  String get learningNoPacksFound;

  /// No description provided for @learningNoQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No questions available yet.'**
  String get learningNoQuestionsAvailable;

  /// No description provided for @learningNotQuite.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get learningNotQuite;

  /// No description provided for @learningNotQuiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Quite There...'**
  String get learningNotQuiteTitle;

  /// No description provided for @learningOpenAiCoach.
  ///
  /// In en, this message translates to:
  /// **'Open AI Coach'**
  String get learningOpenAiCoach;

  /// No description provided for @learningPackFilter.
  ///
  /// In en, this message translates to:
  /// **'Pack: {category}'**
  String learningPackFilter(Object category);

  /// No description provided for @learningPackPurchased.
  ///
  /// In en, this message translates to:
  /// **'Pack purchased successfully!'**
  String get learningPackPurchased;

  /// No description provided for @learningPassageRevealed.
  ///
  /// In en, this message translates to:
  /// **'Passage (revealed)'**
  String get learningPassageRevealed;

  /// No description provided for @learningPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get learningPathTitle;

  /// No description provided for @learningPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get learningPlaying;

  /// No description provided for @learningPleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get learningPleaseEnterDescription;

  /// No description provided for @learningPleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get learningPleaseEnterTitle;

  /// No description provided for @learningPracticeAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get learningPracticeAgain;

  /// No description provided for @learningPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get learningPro;

  /// No description provided for @learningPublishedLessons.
  ///
  /// In en, this message translates to:
  /// **'Published Lessons'**
  String get learningPublishedLessons;

  /// No description provided for @learningPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get learningPurchased;

  /// No description provided for @learningPurchasedLessonsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your purchased lessons will appear here'**
  String get learningPurchasedLessonsEmpty;

  /// No description provided for @learningQuestionsInLesson.
  ///
  /// In en, this message translates to:
  /// **'{count} questions in this lesson'**
  String learningQuestionsInLesson(Object count);

  /// No description provided for @learningQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get learningQuickActions;

  /// No description provided for @learningReadPassage.
  ///
  /// In en, this message translates to:
  /// **'Read the passage'**
  String get learningReadPassage;

  /// No description provided for @learningRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get learningRecentActivity;

  /// No description provided for @learningRecentMilestones.
  ///
  /// In en, this message translates to:
  /// **'Recent Milestones'**
  String get learningRecentMilestones;

  /// No description provided for @learningRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get learningRecentTransactions;

  /// No description provided for @learningRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get learningRequired;

  /// No description provided for @learningResponseRecorded.
  ///
  /// In en, this message translates to:
  /// **'Response recorded'**
  String get learningResponseRecorded;

  /// No description provided for @learningReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get learningReview;

  /// No description provided for @learningSearchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get learningSearchLanguages;

  /// No description provided for @learningSectionEditorComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Section editor coming soon!'**
  String get learningSectionEditorComingSoon;

  /// No description provided for @learningSeeScore.
  ///
  /// In en, this message translates to:
  /// **'See Score'**
  String get learningSeeScore;

  /// No description provided for @learningSelectNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your native language'**
  String get learningSelectNativeLanguage;

  /// No description provided for @learningSelectScenario.
  ///
  /// In en, this message translates to:
  /// **'Select a scenario to begin'**
  String get learningSelectScenario;

  /// No description provided for @learningSelectScenarioFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a scenario first...'**
  String get learningSelectScenarioFirst;

  /// No description provided for @learningSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get learningSessionComplete;

  /// No description provided for @learningSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Session Summary'**
  String get learningSessionSummary;

  /// No description provided for @learningShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get learningShowAll;

  /// No description provided for @learningShowPassageText.
  ///
  /// In en, this message translates to:
  /// **'Show passage text'**
  String get learningShowPassageText;

  /// No description provided for @learningSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get learningSkip;

  /// No description provided for @learningSpendCoinsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Spend {price} coins to unlock this lesson?'**
  String learningSpendCoinsToUnlock(Object price);

  /// No description provided for @learningStartFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Start Flashcards'**
  String get learningStartFlashcards;

  /// No description provided for @learningStartLesson.
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get learningStartLesson;

  /// No description provided for @learningStartPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get learningStartPractice;

  /// No description provided for @learningStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get learningStartQuiz;

  /// No description provided for @learningStartingLesson.
  ///
  /// In en, this message translates to:
  /// **'Starting lesson...'**
  String get learningStartingLesson;

  /// No description provided for @learningStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get learningStop;

  /// No description provided for @learningStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get learningStreak;

  /// No description provided for @learningStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get learningStrengths;

  /// No description provided for @learningSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get learningSubmit;

  /// No description provided for @learningSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get learningSubmitForReview;

  /// No description provided for @learningSubmitForReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your lesson will be reviewed by our team before it goes live. This usually takes 24-48 hours.'**
  String get learningSubmitForReviewBody;

  /// No description provided for @learningSubmitForReviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review?'**
  String get learningSubmitForReviewQuestion;

  /// No description provided for @learningTabAllLessons.
  ///
  /// In en, this message translates to:
  /// **'All Lessons'**
  String get learningTabAllLessons;

  /// No description provided for @learningTabEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get learningTabEarnings;

  /// No description provided for @learningTabFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get learningTabFlashcards;

  /// No description provided for @learningTabLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get learningTabLessons;

  /// No description provided for @learningTabMyLessons.
  ///
  /// In en, this message translates to:
  /// **'My Lessons'**
  String get learningTabMyLessons;

  /// No description provided for @learningTabMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get learningTabMyProgress;

  /// No description provided for @learningTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get learningTabOverview;

  /// No description provided for @learningTabPhrases.
  ///
  /// In en, this message translates to:
  /// **'Phrases'**
  String get learningTabPhrases;

  /// No description provided for @learningTabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get learningTabProgress;

  /// No description provided for @learningTabPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get learningTabPurchased;

  /// No description provided for @learningTabQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get learningTabQuizzes;

  /// No description provided for @learningTabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get learningTabStudents;

  /// No description provided for @learningTapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get learningTapToContinue;

  /// No description provided for @learningTapToHearPassage.
  ///
  /// In en, this message translates to:
  /// **'Tap to hear the passage'**
  String get learningTapToHearPassage;

  /// No description provided for @learningTapToListen.
  ///
  /// In en, this message translates to:
  /// **'Tap to listen'**
  String get learningTapToListen;

  /// No description provided for @learningTapToMatch.
  ///
  /// In en, this message translates to:
  /// **'Tap items to match them'**
  String get learningTapToMatch;

  /// No description provided for @learningTapToRevealTranslation.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal translation'**
  String get learningTapToRevealTranslation;

  /// No description provided for @learningTapWordsToBuild.
  ///
  /// In en, this message translates to:
  /// **'Tap words below to build the sentence'**
  String get learningTapWordsToBuild;

  /// No description provided for @learningTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target Language'**
  String get learningTargetLanguage;

  /// No description provided for @learningTeacherDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Dashboard'**
  String get learningTeacherDashboardTitle;

  /// No description provided for @learningTeacherTiers.
  ///
  /// In en, this message translates to:
  /// **'Teacher Tiers'**
  String get learningTeacherTiers;

  /// No description provided for @learningThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get learningThisMonth;

  /// No description provided for @learningTopPerformingStudents.
  ///
  /// In en, this message translates to:
  /// **'Top Performing Students'**
  String get learningTopPerformingStudents;

  /// No description provided for @learningTotalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get learningTotalStudents;

  /// No description provided for @learningTotalStudentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get learningTotalStudentsLabel;

  /// No description provided for @learningTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get learningTotalXp;

  /// No description provided for @learningTranslatePhrase.
  ///
  /// In en, this message translates to:
  /// **'Translate this phrase'**
  String get learningTranslatePhrase;

  /// No description provided for @learningTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get learningTrue;

  /// No description provided for @learningTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get learningTryAgain;

  /// No description provided for @learningTypeAnswerBelow.
  ///
  /// In en, this message translates to:
  /// **'Type your answer below'**
  String get learningTypeAnswerBelow;

  /// No description provided for @learningTypeAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get learningTypeAnswerHint;

  /// No description provided for @learningTypeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Type your description...'**
  String get learningTypeDescriptionHint;

  /// No description provided for @learningTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get learningTypeMessageHint;

  /// No description provided for @learningTypeMissingWordHint.
  ///
  /// In en, this message translates to:
  /// **'Type the missing word...'**
  String get learningTypeMissingWordHint;

  /// No description provided for @learningTypeSentenceHint.
  ///
  /// In en, this message translates to:
  /// **'Type the sentence...'**
  String get learningTypeSentenceHint;

  /// No description provided for @learningTypeTranslationHint.
  ///
  /// In en, this message translates to:
  /// **'Type your translation...'**
  String get learningTypeTranslationHint;

  /// No description provided for @learningTypeWhatYouHeardHint.
  ///
  /// In en, this message translates to:
  /// **'Type what you heard...'**
  String get learningTypeWhatYouHeardHint;

  /// No description provided for @learningUnitLesson.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} - Lesson {lesson}'**
  String learningUnitLesson(Object lesson, Object unit);

  /// No description provided for @learningUnitNumber.
  ///
  /// In en, this message translates to:
  /// **'Unit {number}'**
  String learningUnitNumber(Object number);

  /// No description provided for @learningUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get learningUnlock;

  /// No description provided for @learningUnlockForCoins.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price} Coins'**
  String learningUnlockForCoins(Object price);

  /// No description provided for @learningUnlockForCoinsLower.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price} coins'**
  String learningUnlockForCoinsLower(Object price);

  /// No description provided for @learningUnlockLesson.
  ///
  /// In en, this message translates to:
  /// **'Unlock Lesson'**
  String get learningUnlockLesson;

  /// No description provided for @learningViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get learningViewAll;

  /// No description provided for @learningViewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get learningViewAnalytics;

  /// No description provided for @learningVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get learningVocabulary;

  /// No description provided for @learningWeek.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String learningWeek(Object week);

  /// No description provided for @learningWeeklyGoals.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goals'**
  String get learningWeeklyGoals;

  /// No description provided for @learningWhatWillStudentsLearnHint.
  ///
  /// In en, this message translates to:
  /// **'What will students learn?'**
  String get learningWhatWillStudentsLearnHint;

  /// No description provided for @learningWhatYouWillLearn.
  ///
  /// In en, this message translates to:
  /// **'What you will learn'**
  String get learningWhatYouWillLearn;

  /// No description provided for @learningWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get learningWithdraw;

  /// No description provided for @learningWithdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get learningWithdrawFunds;

  /// No description provided for @learningWithdrawalSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted!'**
  String get learningWithdrawalSubmitted;

  /// No description provided for @learningWordsAndPhrases.
  ///
  /// In en, this message translates to:
  /// **'Words & Phrases'**
  String get learningWordsAndPhrases;

  /// No description provided for @learningWriteAnswerFreely.
  ///
  /// In en, this message translates to:
  /// **'Write your answer freely'**
  String get learningWriteAnswerFreely;

  /// No description provided for @learningWriteAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer...'**
  String get learningWriteAnswerHint;

  /// No description provided for @learningXpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get learningXpEarned;

  /// No description provided for @learningYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer: {answer}'**
  String learningYourAnswer(Object answer);

  /// No description provided for @learningYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your Score'**
  String get learningYourScore;

  /// No description provided for @lessThanOneKm.
  ///
  /// In en, this message translates to:
  /// **'< 1 km'**
  String get lessThanOneKm;

  /// No description provided for @lessonLabel.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonLabel;

  /// No description provided for @letsChat.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Chat!'**
  String get letsChat;

  /// No description provided for @letsExchange.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Exchange!'**
  String get letsExchange;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @levelLabelN.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabelN(String level);

  /// No description provided for @levelTitleEnthusiast.
  ///
  /// In en, this message translates to:
  /// **'Enthusiast'**
  String get levelTitleEnthusiast;

  /// No description provided for @levelTitleExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get levelTitleExpert;

  /// No description provided for @levelTitleExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get levelTitleExplorer;

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

  /// No description provided for @levelTitleNewcomer.
  ///
  /// In en, this message translates to:
  /// **'Newcomer'**
  String get levelTitleNewcomer;

  /// No description provided for @levelTitleVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get levelTitleVeteran;

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

  /// No description provided for @levelUpContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get levelUpContinue;

  /// No description provided for @levelUpRewards.
  ///
  /// In en, this message translates to:
  /// **'REWARDS'**
  String get levelUpRewards;

  /// No description provided for @levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'LEVEL UP!'**
  String get levelUpTitle;

  /// No description provided for @levelUpVIPUnlocked.
  ///
  /// In en, this message translates to:
  /// **'VIP Status Unlocked!'**
  String get levelUpVIPUnlocked;

  /// No description provided for @levelUpYouReachedLevel.
  ///
  /// In en, this message translates to:
  /// **'You reached Level {level}'**
  String levelUpYouReachedLevel(int level);

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @limitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReachedTitle;

  /// No description provided for @listenMe.
  ///
  /// In en, this message translates to:
  /// **'Listen me!'**
  String get listenMe;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @localGuideBadge.
  ///
  /// In en, this message translates to:
  /// **'Local Guide'**
  String get localGuideBadge;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationAndLanguages.
  ///
  /// In en, this message translates to:
  /// **'Location & Languages'**
  String get locationAndLanguages;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationError;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location Not Found'**
  String get locationNotFound;

  /// No description provided for @locationNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not determine your address. Please try again or set your location manually later.'**
  String get locationNotFoundMessage;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to detect your current location. Please grant permission to continue.'**
  String get locationPermissionDeniedMessage;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Permanently Denied'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationPermissionPermanentlyDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission has been permanently denied. Please enable it in your device settings to use this feature.'**
  String get locationPermissionPermanentlyDeniedMessage;

  /// No description provided for @locationRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request Timeout'**
  String get locationRequestTimeout;

  /// No description provided for @locationRequestTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Getting your location took too long. Please check your connection and try again.'**
  String get locationRequestTimeoutMessage;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Services Disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationServicesDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services in your device settings to use this feature.'**
  String get locationServicesDisabledMessage;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to get your location at the moment. You can set it manually later in settings.'**
  String get locationUnavailable;

  /// No description provided for @locationUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Unavailable'**
  String get locationUnavailableTitle;

  /// No description provided for @locationUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your location settings have been saved'**
  String get locationUpdatedMessage;

  /// No description provided for @locationUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Updated!'**
  String get locationUpdatedTitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirmation;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometrics'**
  String get loginWithBiometrics;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @longTermRelationship.
  ///
  /// In en, this message translates to:
  /// **'Long-term relationship'**
  String get longTermRelationship;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get lookingFor;

  /// No description provided for @lvl.
  ///
  /// In en, this message translates to:
  /// **'LVL'**
  String get lvl;

  /// No description provided for @manageCouponsTiersRules.
  ///
  /// In en, this message translates to:
  /// **'Manage coupons, tiers & rules'**
  String get manageCouponsTiersRules;

  /// No description provided for @matchDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Details'**
  String get matchDetailsTitle;

  /// No description provided for @matchNotifExchangeMsg.
  ///
  /// In en, this message translates to:
  /// **'You and {name} want to exchange languages!'**
  String matchNotifExchangeMsg(String name);

  /// No description provided for @matchNotifKeepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get matchNotifKeepSwiping;

  /// No description provided for @matchNotifLetsChat.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Chat!'**
  String get matchNotifLetsChat;

  /// No description provided for @matchNotifLetsExchange.
  ///
  /// In en, this message translates to:
  /// **'LET\'S EXCHANGE!'**
  String get matchNotifLetsExchange;

  /// No description provided for @matchNotifViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get matchNotifViewProfile;

  /// No description provided for @matchPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percentage} match'**
  String matchPercentage(String percentage);

  /// No description provided for @matchedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Matched on {date}'**
  String matchedOnDate(String date);

  /// No description provided for @matchedWithDate.
  ///
  /// In en, this message translates to:
  /// **'You matched with {name} on {date}'**
  String matchedWithDate(String name, String date);

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @matchesClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get matchesClearFilters;

  /// No description provided for @matchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} matches'**
  String matchesCount(int count);

  /// No description provided for @matchesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get matchesFilterAll;

  /// No description provided for @matchesFilterMessaged.
  ///
  /// In en, this message translates to:
  /// **'Messaged'**
  String get matchesFilterMessaged;

  /// No description provided for @matchesFilterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get matchesFilterNew;

  /// No description provided for @matchesNoMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get matchesNoMatchesFound;

  /// No description provided for @matchesNoMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get matchesNoMatchesYet;

  /// No description provided for @matchesOfCount.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} matches'**
  String matchesOfCount(int filtered, int total);

  /// No description provided for @matchesOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} matches'**
  String matchesOfTotal(int filtered, int total);

  /// No description provided for @matchesStartSwiping.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to find your matches!'**
  String get matchesStartSwiping;

  /// No description provided for @matchesTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter'**
  String get matchesTryDifferent;

  /// No description provided for @maximumInterestsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} interests allowed'**
  String maximumInterestsAllowed(int count);

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @membershipActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{tierName} membership active until {formattedDate}{coinsText}'**
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText);

  /// No description provided for @membershipActivatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership Activated!'**
  String get membershipActivatedTitle;

  /// No description provided for @membershipAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get membershipAdvancedFilters;

  /// No description provided for @membershipBase.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get membershipBase;

  /// No description provided for @membershipBaseMembership.
  ///
  /// In en, this message translates to:
  /// **'Base Membership'**
  String get membershipBaseMembership;

  /// No description provided for @membershipBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value for long-term commitment!'**
  String get membershipBestValue;

  /// No description provided for @membershipBoostsMonth.
  ///
  /// In en, this message translates to:
  /// **'Boosts/month'**
  String get membershipBoostsMonth;

  /// No description provided for @membershipBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy Membership'**
  String get membershipBuyTitle;

  /// No description provided for @membershipCouponCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code *'**
  String get membershipCouponCodeLabel;

  /// No description provided for @membershipCouponHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., GOLD2024'**
  String get membershipCouponHint;

  /// No description provided for @membershipCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Membership'**
  String get membershipCurrent;

  /// No description provided for @membershipDailyLikes.
  ///
  /// In en, this message translates to:
  /// **'Daily Connects'**
  String get membershipDailyLikes;

  /// No description provided for @membershipDailyMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Messages (empty = unlimited)'**
  String get membershipDailyMessagesLabel;

  /// No description provided for @membershipDailySwipesLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Swipes (empty = unlimited)'**
  String get membershipDailySwipesLabel;

  /// No description provided for @membershipDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String membershipDaysRemaining(Object days);

  /// No description provided for @membershipDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get membershipDurationLabel;

  /// No description provided for @membershipEnterCouponHint.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get membershipEnterCouponHint;

  /// No description provided for @membershipEquivalentMonthly.
  ///
  /// In en, this message translates to:
  /// **'Equivalent to {price}/month'**
  String membershipEquivalentMonthly(Object price);

  /// No description provided for @membershipErrorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get membershipErrorLoadingData;

  /// No description provided for @membershipExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String membershipExpires(Object date);

  /// No description provided for @membershipExtendTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend Your Membership'**
  String get membershipExtendTitle;

  /// No description provided for @membershipFeatureComparison.
  ///
  /// In en, this message translates to:
  /// **'Feature Comparison'**
  String get membershipFeatureComparison;

  /// No description provided for @membershipGeneric.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membershipGeneric;

  /// No description provided for @membershipGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get membershipGold;

  /// No description provided for @membershipGreenGoBase.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Base'**
  String get membershipGreenGoBase;

  /// No description provided for @membershipIncognitoMode.
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get membershipIncognitoMode;

  /// No description provided for @membershipLeaveEmptyLifetime.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for lifetime'**
  String get membershipLeaveEmptyLifetime;

  /// No description provided for @membershipLeaveEmptyUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited'**
  String get membershipLeaveEmptyUnlimited;

  /// No description provided for @membershipLowerThanCurrent.
  ///
  /// In en, this message translates to:
  /// **'Lower than your current tier'**
  String get membershipLowerThanCurrent;

  /// No description provided for @membershipMaxUsesLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Uses'**
  String get membershipMaxUsesLabel;

  /// No description provided for @membershipMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Memberships'**
  String get membershipMonthly;

  /// No description provided for @membershipNameDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Name/Description'**
  String get membershipNameDescriptionLabel;

  /// No description provided for @membershipNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active membership'**
  String get membershipNoActive;

  /// No description provided for @membershipNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get membershipNotesLabel;

  /// No description provided for @membershipOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get membershipOneMonth;

  /// No description provided for @membershipOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get membershipOneYear;

  /// No description provided for @membershipPanel.
  ///
  /// In en, this message translates to:
  /// **'Membership Panel'**
  String get membershipPanel;

  /// No description provided for @membershipPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get membershipPermanent;

  /// No description provided for @membershipPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get membershipPlatinum;

  /// No description provided for @membershipPlus500Coins.
  ///
  /// In en, this message translates to:
  /// **'+500 COINS'**
  String get membershipPlus500Coins;

  /// No description provided for @membershipPrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get membershipPrioritySupport;

  /// No description provided for @membershipReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read Receipts'**
  String get membershipReadReceipts;

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

  /// No description provided for @membershipRewinds.
  ///
  /// In en, this message translates to:
  /// **'Rewinds'**
  String get membershipRewinds;

  /// No description provided for @membershipSavePercent.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String membershipSavePercent(Object percent);

  /// No description provided for @membershipSeeWhoLikes.
  ///
  /// In en, this message translates to:
  /// **'See Who Connects'**
  String get membershipSeeWhoLikes;

  /// No description provided for @membershipSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get membershipSilver;

  /// No description provided for @membershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy once, enjoy premium features for 1 month or 1 year'**
  String get membershipSubtitle;

  /// No description provided for @membershipSuperLikes.
  ///
  /// In en, this message translates to:
  /// **'Priority Connects'**
  String get membershipSuperLikes;

  /// No description provided for @membershipSuperLikesLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority Connects/Day (empty = unlimited)'**
  String get membershipSuperLikesLabel;

  /// No description provided for @membershipTerms.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Membership will be extended from your current end date.'**
  String get membershipTerms;

  /// No description provided for @membershipTermsExtended.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Membership will be extended from your current end date. Higher tier purchases override lower tiers.'**
  String get membershipTermsExtended;

  /// No description provided for @membershipTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Membership Tier *'**
  String get membershipTierLabel;

  /// No description provided for @membershipTierName.
  ///
  /// In en, this message translates to:
  /// **'{tierName} Membership'**
  String membershipTierName(Object tierName);

  /// No description provided for @membershipYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly Memberships (Save up to {percent}%)'**
  String membershipYearly(Object percent);

  /// No description provided for @membershipYouHaveTier.
  ///
  /// In en, this message translates to:
  /// **'You have {tierName}'**
  String membershipYouHaveTier(Object tierName);

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Exchanges'**
  String get messages;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @moreAchievements.
  ///
  /// In en, this message translates to:
  /// **'+{count} more achievements'**
  String moreAchievements(int count);

  /// No description provided for @myBadges.
  ///
  /// In en, this message translates to:
  /// **'My Badges'**
  String get myBadges;

  /// No description provided for @myProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get myProgress;

  /// No description provided for @myUsage.
  ///
  /// In en, this message translates to:
  /// **'My Usage'**
  String get myUsage;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @needCoinsForProfiles.
  ///
  /// In en, this message translates to:
  /// **'You need {amount} coins to unlock more profiles.'**
  String needCoinsForProfiles(int amount);

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextLevelXp.
  ///
  /// In en, this message translates to:
  /// **'Next level in {xp} XP'**
  String nextLevelXp(String xp);

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

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

  /// No description provided for @nicknameMustBe3To20Chars.
  ///
  /// In en, this message translates to:
  /// **'Must be 3-20 characters'**
  String get nicknameMustBe3To20Chars;

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

  /// No description provided for @nicknameOnlyAlphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores'**
  String get nicknameOnlyAlphanumeric;

  /// No description provided for @nicknameRequirements.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters. Letters, numbers, and underscores only.'**
  String get nicknameRequirements;

  /// No description provided for @nicknameRules.
  ///
  /// In en, this message translates to:
  /// **'Nickname Rules'**
  String get nicknameRules;

  /// No description provided for @nicknameSearchChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get nicknameSearchChat;

  /// No description provided for @nicknameSearchError.
  ///
  /// In en, this message translates to:
  /// **'Error searching. Please try again.'**
  String get nicknameSearchError;

  /// No description provided for @nicknameSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname to find someone directly'**
  String get nicknameSearchHelp;

  /// No description provided for @nicknameSearchNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No profile found with @{nickname}'**
  String nicknameSearchNoProfile(String nickname);

  /// No description provided for @nicknameSearchOwnProfile.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own profile!'**
  String get nicknameSearchOwnProfile;

  /// No description provided for @nicknameSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by Nickname'**
  String get nicknameSearchTitle;

  /// No description provided for @nicknameSearchView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get nicknameSearchView;

  /// No description provided for @nicknameStartWithLetter.
  ///
  /// In en, this message translates to:
  /// **'Start with a letter'**
  String get nicknameStartWithLetter;

  /// No description provided for @nicknameUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your new nickname is now active'**
  String get nicknameUpdatedMessage;

  /// No description provided for @nicknameUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated successfully'**
  String get nicknameUpdatedSuccess;

  /// No description provided for @nicknameUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nickname Updated!'**
  String get nicknameUpdatedTitle;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noActiveGamesLabel.
  ///
  /// In en, this message translates to:
  /// **'No active games'**
  String get noActiveGamesLabel;

  /// No description provided for @noBadgesEarnedYet.
  ///
  /// In en, this message translates to:
  /// **'No badges earned yet'**
  String get noBadgesEarnedYet;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @noLanguagesYet.
  ///
  /// In en, this message translates to:
  /// **'No languages yet. Start learning!'**
  String get noLanguagesYet;

  /// No description provided for @noLeaderboardData.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data yet'**
  String get noLeaderboardData;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @noMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'No more profiles to show'**
  String get noMoreProfiles;

  /// No description provided for @noOthersToSee.
  ///
  /// In en, this message translates to:
  /// **'There\'s no others to see'**
  String get noOthersToSee;

  /// No description provided for @noPendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'No pending verifications'**
  String get noPendingVerifications;

  /// No description provided for @noPhotoSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No photo submitted'**
  String get noPhotoSubmitted;

  /// No description provided for @noPreviousProfile.
  ///
  /// In en, this message translates to:
  /// **'No previous profile to rewind'**
  String get noPreviousProfile;

  /// No description provided for @noProfileFoundWithNickname.
  ///
  /// In en, this message translates to:
  /// **'No profile found with @{nickname}'**
  String noProfileFoundWithNickname(String nickname);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noSocialProfilesLinked.
  ///
  /// In en, this message translates to:
  /// **'No social profiles linked'**
  String get noSocialProfilesLinked;

  /// No description provided for @noVoiceRecording.
  ///
  /// In en, this message translates to:
  /// **'No voice recording'**
  String get noVoiceRecording;

  /// No description provided for @nodeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get nodeAvailable;

  /// No description provided for @nodeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get nodeCompleted;

  /// No description provided for @nodeInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get nodeInProgress;

  /// No description provided for @nodeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get nodeLocked;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get notEnoughCoins;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notificationAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked: {name}'**
  String notificationAchievementUnlocked(String name);

  /// No description provided for @notificationCoinsPurchased.
  ///
  /// In en, this message translates to:
  /// **'You successfully purchased {amount} coins.'**
  String notificationCoinsPurchased(int amount);

  /// No description provided for @notificationDialogEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationDialogEnable;

  /// No description provided for @notificationDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to know when you get matches, messages, and priority connects.'**
  String get notificationDialogMessage;

  /// No description provided for @notificationDialogNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notificationDialogNotNow;

  /// No description provided for @notificationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected'**
  String get notificationDialogTitle;

  /// No description provided for @notificationEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications via email'**
  String get notificationEmailSubtitle;

  /// No description provided for @notificationEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get notificationEmailTitle;

  /// No description provided for @notificationEnableQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Enable Quiet Hours'**
  String get notificationEnableQuietHours;

  /// No description provided for @notificationEndTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get notificationEndTime;

  /// No description provided for @notificationMasterControls.
  ///
  /// In en, this message translates to:
  /// **'Master Controls'**
  String get notificationMasterControls;

  /// No description provided for @notificationMatchExpiring.
  ///
  /// In en, this message translates to:
  /// **'Match Expiring'**
  String get notificationMatchExpiring;

  /// No description provided for @notificationMatchExpiringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a match is about to expire'**
  String get notificationMatchExpiringSubtitle;

  /// No description provided for @notificationNewChat.
  ///
  /// In en, this message translates to:
  /// **'@{nickname} started a conversation with you.'**
  String notificationNewChat(String nickname);

  /// No description provided for @notificationNewLike.
  ///
  /// In en, this message translates to:
  /// **'You received a like from @{nickname}'**
  String notificationNewLike(String nickname);

  /// No description provided for @notificationNewLikes.
  ///
  /// In en, this message translates to:
  /// **'New Likes'**
  String get notificationNewLikes;

  /// No description provided for @notificationNewLikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone likes you'**
  String get notificationNewLikesSubtitle;

  /// No description provided for @notificationNewMatch.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match! You matched with @{nickname}. Start chatting now.'**
  String notificationNewMatch(String nickname);

  /// No description provided for @notificationNewMatches.
  ///
  /// In en, this message translates to:
  /// **'New Matches'**
  String get notificationNewMatches;

  /// No description provided for @notificationNewMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you get a new match'**
  String get notificationNewMatchesSubtitle;

  /// No description provided for @notificationNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message from @{nickname}'**
  String notificationNewMessage(String nickname);

  /// No description provided for @notificationNewMessages.
  ///
  /// In en, this message translates to:
  /// **'New Messages'**
  String get notificationNewMessages;

  /// No description provided for @notificationNewMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone sends you a message'**
  String get notificationNewMessagesSubtitle;

  /// No description provided for @notificationProfileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile Views'**
  String get notificationProfileViews;

  /// No description provided for @notificationProfileViewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone views your profile'**
  String get notificationProfileViewsSubtitle;

  /// No description provided for @notificationPromotional.
  ///
  /// In en, this message translates to:
  /// **'Promotional'**
  String get notificationPromotional;

  /// No description provided for @notificationPromotionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tips, offers, and promotions'**
  String get notificationPromotionalSubtitle;

  /// No description provided for @notificationPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications on this device'**
  String get notificationPushSubtitle;

  /// No description provided for @notificationPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notificationPushTitle;

  /// No description provided for @notificationQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notificationQuietHours;

  /// No description provided for @notificationQuietHoursDescription.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications between set times'**
  String get notificationQuietHoursDescription;

  /// No description provided for @notificationQuietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications during certain hours'**
  String get notificationQuietHoursSubtitle;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notificationSound;

  /// No description provided for @notificationSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play sound for notifications'**
  String get notificationSoundSubtitle;

  /// No description provided for @notificationSoundVibration.
  ///
  /// In en, this message translates to:
  /// **'Sound & Vibration'**
  String get notificationSoundVibration;

  /// No description provided for @notificationStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get notificationStartTime;

  /// No description provided for @notificationSuperLike.
  ///
  /// In en, this message translates to:
  /// **'You received a priority connect from @{nickname}'**
  String notificationSuperLike(String nickname);

  /// No description provided for @notificationSuperLikes.
  ///
  /// In en, this message translates to:
  /// **'Priority Connects'**
  String get notificationSuperLikes;

  /// No description provided for @notificationSuperLikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone priority connects with you'**
  String get notificationSuperLikesSubtitle;

  /// No description provided for @notificationTypes.
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// No description provided for @notificationVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get notificationVibration;

  /// No description provided for @notificationVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate for notifications'**
  String get notificationVibrationSubtitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you get notifications, they\'ll show up here'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @onboardingAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get onboardingAddPhoto;

  /// No description provided for @onboardingAddPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos that represent the real you'**
  String get onboardingAddPhotosSubtitle;

  /// No description provided for @onboardingAiVerifiedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your photos are verified using AI to ensure authenticity'**
  String get onboardingAiVerifiedDescription;

  /// No description provided for @onboardingAiVerifiedPhotos.
  ///
  /// In en, this message translates to:
  /// **'AI Verified Photos'**
  String get onboardingAiVerifiedPhotos;

  /// No description provided for @onboardingBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your interests, hobbies, what you\'re looking for...'**
  String get onboardingBioHint;

  /// No description provided for @onboardingBioMinLength.
  ///
  /// In en, this message translates to:
  /// **'Bio must be at least 50 characters'**
  String get onboardingBioMinLength;

  /// No description provided for @onboardingChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get onboardingChooseFromGallery;

  /// No description provided for @onboardingCompleteAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get onboardingCompleteAllFields;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get onboardingDateOfBirth;

  /// No description provided for @onboardingDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get onboardingDisplayName;

  /// No description provided for @onboardingDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get onboardingDisplayNameHint;

  /// No description provided for @onboardingEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get onboardingEnterYourName;

  /// No description provided for @onboardingExpressYourself.
  ///
  /// In en, this message translates to:
  /// **'Express yourself'**
  String get onboardingExpressYourself;

  /// No description provided for @onboardingExpressYourselfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write something that captures who you are'**
  String get onboardingExpressYourselfSubtitle;

  /// No description provided for @onboardingFailedPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String onboardingFailedPickImage(Object error);

  /// No description provided for @onboardingFailedTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo: {error}'**
  String onboardingFailedTakePhoto(Object error);

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingGenderNonBinary.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get onboardingGenderNonBinary;

  /// No description provided for @onboardingGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get onboardingGenderOther;

  /// No description provided for @onboardingHoldIdNextToFace.
  ///
  /// In en, this message translates to:
  /// **'Hold your ID next to your face'**
  String get onboardingHoldIdNextToFace;

  /// No description provided for @onboardingIdentifyAs.
  ///
  /// In en, this message translates to:
  /// **'I identify as'**
  String get onboardingIdentifyAs;

  /// No description provided for @onboardingInterestsHelpMatches.
  ///
  /// In en, this message translates to:
  /// **'Your interests help us find better matches for you'**
  String get onboardingInterestsHelpMatches;

  /// No description provided for @onboardingInterestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 interests (max 10)'**
  String get onboardingInterestsSubtitle;

  /// No description provided for @onboardingLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get onboardingLanguages;

  /// No description provided for @onboardingLanguagesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 selected'**
  String onboardingLanguagesSelected(Object count);

  /// No description provided for @onboardingLetsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get onboardingLetsGetStarted;

  /// No description provided for @onboardingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get onboardingLocation;

  /// No description provided for @onboardingLocationLater.
  ///
  /// In en, this message translates to:
  /// **'You can set your location later in settings'**
  String get onboardingLocationLater;

  /// No description provided for @onboardingMainPhoto.
  ///
  /// In en, this message translates to:
  /// **'MAIN'**
  String get onboardingMainPhoto;

  /// No description provided for @onboardingMaxInterests.
  ///
  /// In en, this message translates to:
  /// **'You can select up to 10 interests'**
  String get onboardingMaxInterests;

  /// No description provided for @onboardingMaxLanguages.
  ///
  /// In en, this message translates to:
  /// **'You can select up to 3 languages'**
  String get onboardingMaxLanguages;

  /// No description provided for @onboardingMinInterests.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 3 interests'**
  String get onboardingMinInterests;

  /// No description provided for @onboardingMinLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one language'**
  String get onboardingMinLanguage;

  /// No description provided for @onboardingNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get onboardingNameMinLength;

  /// No description provided for @onboardingNoLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'No location selected'**
  String get onboardingNoLocationSelected;

  /// No description provided for @onboardingOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get onboardingOptional;

  /// No description provided for @onboardingSelectFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select from your photos'**
  String get onboardingSelectFromPhotos;

  /// No description provided for @onboardingSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/10 selected'**
  String onboardingSelectedCount(Object count);

  /// No description provided for @onboardingShowYourself.
  ///
  /// In en, this message translates to:
  /// **'Show yourself'**
  String get onboardingShowYourself;

  /// No description provided for @onboardingTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get onboardingTakePhoto;

  /// No description provided for @onboardingTellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get onboardingTellUsAboutYourself;

  /// No description provided for @onboardingTipAuthentic.
  ///
  /// In en, this message translates to:
  /// **'Be authentic and genuine'**
  String get onboardingTipAuthentic;

  /// No description provided for @onboardingTipPassions.
  ///
  /// In en, this message translates to:
  /// **'Share your passions and hobbies'**
  String get onboardingTipPassions;

  /// No description provided for @onboardingTipPositive.
  ///
  /// In en, this message translates to:
  /// **'Keep it positive'**
  String get onboardingTipPositive;

  /// No description provided for @onboardingTipUnique.
  ///
  /// In en, this message translates to:
  /// **'What makes you unique?'**
  String get onboardingTipUnique;

  /// No description provided for @onboardingUploadAtLeastOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please upload at least one photo'**
  String get onboardingUploadAtLeastOnePhoto;

  /// No description provided for @onboardingUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get onboardingUseCurrentLocation;

  /// No description provided for @onboardingUseYourCamera.
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get onboardingUseYourCamera;

  /// No description provided for @onboardingWhereAreYou.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get onboardingWhereAreYou;

  /// No description provided for @onboardingWhereAreYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your preferred languages and location (optional)'**
  String get onboardingWhereAreYouSubtitle;

  /// No description provided for @onboardingWriteSomethingAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Please write something about yourself'**
  String get onboardingWriteSomethingAboutYourself;

  /// No description provided for @onboardingWritingTips.
  ///
  /// In en, this message translates to:
  /// **'Writing tips'**
  String get onboardingWritingTips;

  /// No description provided for @onboardingYourInterests.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get onboardingYourInterests;

  /// No description provided for @oneTimeDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'This is a one-time download of approximately {size}MB.'**
  String oneTimeDownloadSize(int size);

  /// No description provided for @optionalConsents.
  ///
  /// In en, this message translates to:
  /// **'Optional Consents'**
  String get optionalConsents;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @packFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Pack: {packName}'**
  String packFocusMode(String packName);

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordMustContain.
  ///
  /// In en, this message translates to:
  /// **'Password must contain:'**
  String get passwordMustContain;

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

  /// No description provided for @passwordMustContainUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMustContainUppercase;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

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

  /// No description provided for @pendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'Pending Verifications'**
  String get pendingVerifications;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @periodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get periodAllTime;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get periodMonthly;

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get periodWeekly;

  /// No description provided for @personalStatistics.
  ///
  /// In en, this message translates to:
  /// **'Personal Statistics'**
  String get personalStatistics;

  /// No description provided for @personalStatisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charts, goals, and language progress'**
  String get personalStatisticsSubtitle;

  /// No description provided for @personalStatsActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get personalStatsActivity;

  /// No description provided for @personalStatsChatStats.
  ///
  /// In en, this message translates to:
  /// **'Chat Stats'**
  String get personalStatsChatStats;

  /// No description provided for @personalStatsConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get personalStatsConversations;

  /// No description provided for @personalStatsGoalsAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goals Achieved'**
  String get personalStatsGoalsAchieved;

  /// No description provided for @personalStatsLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get personalStatsLevel;

  /// No description provided for @personalStatsNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get personalStatsNextLevel;

  /// No description provided for @personalStatsNoActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get personalStatsNoActivityYet;

  /// No description provided for @personalStatsNoWordsYet.
  ///
  /// In en, this message translates to:
  /// **'Start chatting to discover new words'**
  String get personalStatsNoWordsYet;

  /// No description provided for @personalStatsTotalMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages Sent'**
  String get personalStatsTotalMessages;

  /// No description provided for @personalStatsWordsDiscovered.
  ///
  /// In en, this message translates to:
  /// **'Words Discovered'**
  String get personalStatsWordsDiscovered;

  /// No description provided for @personalStatsXpOverview.
  ///
  /// In en, this message translates to:
  /// **'XP Overview'**
  String get personalStatsXpOverview;

  /// No description provided for @photoAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get photoAddPhoto;

  /// No description provided for @photoAddPrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'Add private photos that you can share in chat'**
  String get photoAddPrivateDescription;

  /// No description provided for @photoAddPublicDescription.
  ///
  /// In en, this message translates to:
  /// **'Add photos to complete your profile'**
  String get photoAddPublicDescription;

  /// No description provided for @photoAlreadyExistsInAlbum.
  ///
  /// In en, this message translates to:
  /// **'Photo already exists in target album'**
  String get photoAlreadyExistsInAlbum;

  /// No description provided for @photoCountOf6.
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos'**
  String photoCountOf6(Object count);

  /// No description provided for @photoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get photoDeleteConfirm;

  /// No description provided for @photoDeleteMainWarning.
  ///
  /// In en, this message translates to:
  /// **'This is your main photo. The next photo will become your main photo (must show your face). Continue?'**
  String get photoDeleteMainWarning;

  /// No description provided for @photoExplicitContent.
  ///
  /// In en, this message translates to:
  /// **'This photo contains inappropriate content. Nudity, underwear, and explicit content are not allowed anywhere in the app.'**
  String get photoExplicitContent;

  /// No description provided for @photoExplicitNudity.
  ///
  /// In en, this message translates to:
  /// **'This photo appears to contain nudity or explicit content. All photos must be appropriate and fully clothed.'**
  String get photoExplicitNudity;

  /// No description provided for @photoFailedPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String photoFailedPickImage(Object error);

  /// No description provided for @photoLongPressReorder.
  ///
  /// In en, this message translates to:
  /// **'Long press and drag to reorder'**
  String get photoLongPressReorder;

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

  /// No description provided for @photoManagePhotos.
  ///
  /// In en, this message translates to:
  /// **'Manage Photos'**
  String get photoManagePhotos;

  /// No description provided for @photoMaxPrivate.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 private photos allowed'**
  String get photoMaxPrivate;

  /// No description provided for @photoMaxPublic.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 public photos allowed'**
  String get photoMaxPublic;

  /// No description provided for @photoMustHaveOne.
  ///
  /// In en, this message translates to:
  /// **'You must have at least one public photo with your face visible.'**
  String get photoMustHaveOne;

  /// No description provided for @photoNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get photoNoPhotos;

  /// No description provided for @photoNoPrivatePhotos.
  ///
  /// In en, this message translates to:
  /// **'No private photos yet'**
  String get photoNoPrivatePhotos;

  /// No description provided for @photoNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Photo Not Accepted'**
  String get photoNotAccepted;

  /// No description provided for @photoNotAllowedPublic.
  ///
  /// In en, this message translates to:
  /// **'This photo is not allowed. All photos must be appropriate.'**
  String get photoNotAllowedPublic;

  /// No description provided for @photoPrimary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get photoPrimary;

  /// No description provided for @photoPrivateShareInfo.
  ///
  /// In en, this message translates to:
  /// **'Private photos can be shared in chat'**
  String get photoPrivateShareInfo;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Photo is too large. Maximum size is 10MB.'**
  String get photoTooLarge;

  /// No description provided for @photoTooMuchSkin.
  ///
  /// In en, this message translates to:
  /// **'This photo shows too much skin exposure. Please use a photo where you are appropriately dressed.'**
  String get photoTooMuchSkin;

  /// No description provided for @photoUploadedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your photo has been added to your profile'**
  String get photoUploadedMessage;

  /// No description provided for @photoUploadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Uploaded!'**
  String get photoUploadedTitle;

  /// No description provided for @photoValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating photo...'**
  String get photoValidating;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos'**
  String photosCount(int count);

  /// No description provided for @photosPublicCount.
  ///
  /// In en, this message translates to:
  /// **'Photos: {count} public'**
  String photosPublicCount(int count);

  /// No description provided for @photosPublicPrivateCount.
  ///
  /// In en, this message translates to:
  /// **'Photos: {publicCount} public + {privateCount} private'**
  String photosPublicPrivateCount(int publicCount, int privateCount);

  /// No description provided for @photosUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your photo gallery has been saved'**
  String get photosUpdatedMessage;

  /// No description provided for @photosUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos Updated!'**
  String get photosUpdatedTitle;

  /// No description provided for @phrasesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} phrases'**
  String phrasesCount(String count);

  /// No description provided for @phrasesLabel.
  ///
  /// In en, this message translates to:
  /// **'phrases'**
  String get phrasesLabel;

  /// No description provided for @platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinum;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @playersRange.
  ///
  /// In en, this message translates to:
  /// **'{min}-{max} players'**
  String playersRange(String min, String max);

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get playing;

  /// No description provided for @playingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} playing'**
  String playingCountLabel(String count);

  /// No description provided for @plusTaxes.
  ///
  /// In en, this message translates to:
  /// **'+ taxes'**
  String get plusTaxes;

  /// No description provided for @preferenceAddCountry.
  ///
  /// In en, this message translates to:
  /// **'Add Country'**
  String get preferenceAddCountry;

  /// No description provided for @preferenceAddDealBreaker.
  ///
  /// In en, this message translates to:
  /// **'Add Deal Breaker'**
  String get preferenceAddDealBreaker;

  /// No description provided for @preferenceAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get preferenceAdvancedFilters;

  /// No description provided for @preferenceAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get preferenceAgeRange;

  /// No description provided for @preferenceAllCountries.
  ///
  /// In en, this message translates to:
  /// **'All Countries'**
  String get preferenceAllCountries;

  /// No description provided for @preferenceAllVerified.
  ///
  /// In en, this message translates to:
  /// **'All profiles must be verified'**
  String get preferenceAllVerified;

  /// No description provided for @preferenceCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get preferenceCountry;

  /// No description provided for @preferenceCountryDescription.
  ///
  /// In en, this message translates to:
  /// **'Only show people from specific countries (leave empty to show all)'**
  String get preferenceCountryDescription;

  /// No description provided for @preferenceDealBreakers.
  ///
  /// In en, this message translates to:
  /// **'Deal Breakers'**
  String get preferenceDealBreakers;

  /// No description provided for @preferenceDealBreakersDesc.
  ///
  /// In en, this message translates to:
  /// **'Never show me profiles with these characteristics'**
  String get preferenceDealBreakersDesc;

  /// No description provided for @preferenceDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String preferenceDistanceKm(int km);

  /// No description provided for @preferenceEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get preferenceEveryone;

  /// No description provided for @preferenceMaxDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get preferenceMaxDistance;

  /// No description provided for @preferenceMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get preferenceMen;

  /// No description provided for @preferenceMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get preferenceMostPopular;

  /// No description provided for @preferenceNoCountriesFound.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get preferenceNoCountriesFound;

  /// No description provided for @preferenceNoCountryFilter.
  ///
  /// In en, this message translates to:
  /// **'No country filter — showing worldwide'**
  String get preferenceNoCountryFilter;

  /// No description provided for @preferenceNoDealBreakers.
  ///
  /// In en, this message translates to:
  /// **'No deal breakers set'**
  String get preferenceNoDealBreakers;

  /// No description provided for @preferenceNoDistanceLimit.
  ///
  /// In en, this message translates to:
  /// **'No distance limit'**
  String get preferenceNoDistanceLimit;

  /// No description provided for @preferenceOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online Now'**
  String get preferenceOnlineNow;

  /// No description provided for @preferenceOnlineNowDesc.
  ///
  /// In en, this message translates to:
  /// **'Show only profiles that are currently online'**
  String get preferenceOnlineNowDesc;

  /// No description provided for @preferenceOnlyVerified.
  ///
  /// In en, this message translates to:
  /// **'Only show verified profiles'**
  String get preferenceOnlyVerified;

  /// No description provided for @preferenceOrientationDescription.
  ///
  /// In en, this message translates to:
  /// **'Filter by orientation (leave all unchecked to show everyone)'**
  String get preferenceOrientationDescription;

  /// No description provided for @preferenceRecentlyActive.
  ///
  /// In en, this message translates to:
  /// **'Recently active'**
  String get preferenceRecentlyActive;

  /// No description provided for @preferenceRecentlyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Show only profiles active in the last 7 days'**
  String get preferenceRecentlyActiveDesc;

  /// No description provided for @preferenceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get preferenceSave;

  /// No description provided for @preferenceSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get preferenceSelectCountry;

  /// No description provided for @preferenceSexualOrientation.
  ///
  /// In en, this message translates to:
  /// **'Sexual Orientation'**
  String get preferenceSexualOrientation;

  /// No description provided for @preferenceShowMe.
  ///
  /// In en, this message translates to:
  /// **'Show Me'**
  String get preferenceShowMe;

  /// No description provided for @preferenceUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get preferenceUnlimited;

  /// No description provided for @preferenceUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String preferenceUsersCount(int count);

  /// No description provided for @preferenceWithin.
  ///
  /// In en, this message translates to:
  /// **'Within'**
  String get preferenceWithin;

  /// No description provided for @preferenceWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get preferenceWomen;

  /// No description provided for @preferencesSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your discovery preferences have been updated'**
  String get preferencesSavedMessage;

  /// No description provided for @preferencesSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences Saved!'**
  String get preferencesSavedTitle;

  /// No description provided for @premiumTier.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumTier;

  /// No description provided for @primaryOrigin.
  ///
  /// In en, this message translates to:
  /// **'Primary Origin'**
  String get primaryOrigin;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @privateAlbum.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateAlbum;

  /// No description provided for @privateRoom.
  ///
  /// In en, this message translates to:
  /// **'Private Room'**
  String get privateRoom;

  /// No description provided for @proLabel.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proLabel;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get profileAboutMe;

  /// No description provided for @profileAccountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get profileAccountDeletedSuccess;

  /// No description provided for @profileActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get profileActivate;

  /// No description provided for @profileActivateIncognito.
  ///
  /// In en, this message translates to:
  /// **'Activate Incognito?'**
  String get profileActivateIncognito;

  /// No description provided for @profileActivateTravelerMode.
  ///
  /// In en, this message translates to:
  /// **'Activate Traveler Mode?'**
  String get profileActivateTravelerMode;

  /// No description provided for @profileActivatingBoost.
  ///
  /// In en, this message translates to:
  /// **'Activating boost...'**
  String get profileActivatingBoost;

  /// No description provided for @profileActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get profileActiveLabel;

  /// No description provided for @profileAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get profileAdditionalDetails;

  /// No description provided for @profileAgeCannotChange.
  ///
  /// In en, this message translates to:
  /// **'Age {age} - Cannot be changed for verification'**
  String profileAgeCannotChange(int age);

  /// No description provided for @profileAlreadyBoosted.
  ///
  /// In en, this message translates to:
  /// **'Profile already boosted! {minutes}m remaining'**
  String profileAlreadyBoosted(Object minutes);

  /// No description provided for @profileAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get profileAuthenticationFailed;

  /// No description provided for @profileBioMinLength.
  ///
  /// In en, this message translates to:
  /// **'Bio must be at least {min} characters'**
  String profileBioMinLength(int min);

  /// No description provided for @profileBoostCost.
  ///
  /// In en, this message translates to:
  /// **'Cost: {cost} coins'**
  String profileBoostCost(Object cost);

  /// No description provided for @profileBoostDescription.
  ///
  /// In en, this message translates to:
  /// **'Your profile will appear at the top of discovery for 30 minutes!'**
  String get profileBoostDescription;

  /// No description provided for @profileBoostNow.
  ///
  /// In en, this message translates to:
  /// **'Boost Now'**
  String get profileBoostNow;

  /// No description provided for @profileBoostProfile.
  ///
  /// In en, this message translates to:
  /// **'Boost Profile'**
  String get profileBoostProfile;

  /// No description provided for @profileBoostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be seen first for 30 minutes'**
  String get profileBoostSubtitle;

  /// No description provided for @profileBoosted.
  ///
  /// In en, this message translates to:
  /// **'Profile Boosted!'**
  String get profileBoosted;

  /// No description provided for @profileBoostedForMinutes.
  ///
  /// In en, this message translates to:
  /// **'Profile boosted for {minutes} minutes!'**
  String profileBoostedForMinutes(Object minutes);

  /// No description provided for @profileBuyCoins.
  ///
  /// In en, this message translates to:
  /// **'Buy Coins'**
  String get profileBuyCoins;

  /// No description provided for @profileCoinShop.
  ///
  /// In en, this message translates to:
  /// **'Coin Shop'**
  String get profileCoinShop;

  /// No description provided for @profileCoinShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase coins and premium membership'**
  String get profileCoinShopSubtitle;

  /// No description provided for @profileConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Password'**
  String get profileConfirmYourPassword;

  /// No description provided for @profileContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileContinue;

  /// No description provided for @profileDataExportSent.
  ///
  /// In en, this message translates to:
  /// **'Data export sent to your email'**
  String get profileDataExportSent;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileDeleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data, matches, and messages will be deleted. Please enter your password to confirm.'**
  String get profileDeleteAccountWarning;

  /// No description provided for @profileDiscoveryRestarted.
  ///
  /// In en, this message translates to:
  /// **'Discovery restarted! You can now see all profiles again.'**
  String get profileDiscoveryRestarted;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get profileDisplayName;

  /// No description provided for @profileDobInfo.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth cannot be changed for age verification purposes. Your exact age is visible to matches.'**
  String get profileDobInfo;

  /// No description provided for @profileEditBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Basic Info'**
  String get profileEditBasicInfo;

  /// No description provided for @profileEditLocation.
  ///
  /// In en, this message translates to:
  /// **'Edit Location & Languages'**
  String get profileEditLocation;

  /// No description provided for @profileEditNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get profileEditNickname;

  /// No description provided for @profileEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileEducation;

  /// No description provided for @profileEducationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bachelor in Computer Science'**
  String get profileEducationHint;

  /// No description provided for @profileEnterNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileEnterNameHint;

  /// No description provided for @profileEnterNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get profileEnterNicknameHint;

  /// No description provided for @profileEnterNicknameWith.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname starting with @'**
  String get profileEnterNicknameWith;

  /// No description provided for @profileExportingData.
  ///
  /// In en, this message translates to:
  /// **'Exporting your data...'**
  String get profileExportingData;

  /// No description provided for @profileFailedRestartDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Failed to restart discovery: {error}'**
  String profileFailedRestartDiscovery(Object error);

  /// No description provided for @profileFindUsers.
  ///
  /// In en, this message translates to:
  /// **'Find Users'**
  String get profileFindUsers;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileGetCoins.
  ///
  /// In en, this message translates to:
  /// **'Get Coins'**
  String get profileGetCoins;

  /// No description provided for @profileGetMembership.
  ///
  /// In en, this message translates to:
  /// **'Get GreenGo Membership'**
  String get profileGetMembership;

  /// No description provided for @profileGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting Location...'**
  String get profileGettingLocation;

  /// No description provided for @profileGreengoMembership.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Membership'**
  String get profileGreengoMembership;

  /// No description provided for @profileHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileHeightCm;

  /// No description provided for @profileIncognitoActivated.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode activated for 24 hours!'**
  String get profileIncognitoActivated;

  /// No description provided for @profileIncognitoCost.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode costs {cost} coins per day.'**
  String profileIncognitoCost(Object cost);

  /// No description provided for @profileIncognitoDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode deactivated.'**
  String get profileIncognitoDeactivated;

  /// No description provided for @profileIncognitoDescription.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode hides your profile from discovery for 24 hours.\n\nCost: {cost}'**
  String profileIncognitoDescription(Object cost);

  /// No description provided for @profileIncognitoFreePlatinum.
  ///
  /// In en, this message translates to:
  /// **'Free with Platinum - Hidden from discovery'**
  String get profileIncognitoFreePlatinum;

  /// No description provided for @profileIncognitoMode.
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get profileIncognitoMode;

  /// No description provided for @profileInsufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Coins'**
  String get profileInsufficientCoins;

  /// No description provided for @profileInterestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} interests'**
  String profileInterestsCount(Object count);

  /// No description provided for @profileInterestsHobbiesHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your interests, hobbies, what you\'re looking for...'**
  String get profileInterestsHobbiesHint;

  /// No description provided for @profileLanguagesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileLanguagesSectionTitle;

  /// No description provided for @profileLanguagesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 languages selected'**
  String profileLanguagesSelectedCount(int count);

  /// No description provided for @profileLinkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} profile(s) linked'**
  String profileLinkedCount(Object count);

  /// No description provided for @profileLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String profileLocationFailed(String error);

  /// No description provided for @profileLocationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocationSectionTitle;

  /// No description provided for @profileLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking For'**
  String get profileLookingFor;

  /// No description provided for @profileLookingForHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Long-term relationship'**
  String get profileLookingForHint;

  /// No description provided for @profileMaxLanguagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 languages allowed'**
  String get profileMaxLanguagesAllowed;

  /// No description provided for @profileMembershipActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileMembershipActive;

  /// No description provided for @profileMembershipExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get profileMembershipExpired;

  /// No description provided for @profileMembershipValidTill.
  ///
  /// In en, this message translates to:
  /// **'Valid till {date}'**
  String profileMembershipValidTill(Object date);

  /// No description provided for @profileMyUsage.
  ///
  /// In en, this message translates to:
  /// **'My Usage'**
  String get profileMyUsage;

  /// No description provided for @profileMyUsageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your daily usage and tier limits'**
  String get profileMyUsageSubtitle;

  /// No description provided for @profileNicknameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken'**
  String get profileNicknameAlreadyTaken;

  /// No description provided for @profileNicknameCharRules.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters. Letters, numbers, and underscores only.'**
  String get profileNicknameCharRules;

  /// No description provided for @profileNicknameCheckError.
  ///
  /// In en, this message translates to:
  /// **'Error checking availability'**
  String get profileNicknameCheckError;

  /// No description provided for @profileNicknameInfoWithNickname.
  ///
  /// In en, this message translates to:
  /// **'Your nickname is unique and can be used to find you. Others can search for you using @{nickname}'**
  String profileNicknameInfoWithNickname(String nickname);

  /// No description provided for @profileNicknameInfoWithout.
  ///
  /// In en, this message translates to:
  /// **'Your nickname is unique and can be used to find you. Set one below to let others discover you.'**
  String get profileNicknameInfoWithout;

  /// No description provided for @profileNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNicknameLabel;

  /// No description provided for @profileNicknameRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get profileNicknameRefresh;

  /// No description provided for @profileNicknameRule1.
  ///
  /// In en, this message translates to:
  /// **'Must be 3-20 characters'**
  String get profileNicknameRule1;

  /// No description provided for @profileNicknameRule2.
  ///
  /// In en, this message translates to:
  /// **'Start with a letter'**
  String get profileNicknameRule2;

  /// No description provided for @profileNicknameRule3.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores'**
  String get profileNicknameRule3;

  /// No description provided for @profileNicknameRule4.
  ///
  /// In en, this message translates to:
  /// **'No consecutive underscores'**
  String get profileNicknameRule4;

  /// No description provided for @profileNicknameRule5.
  ///
  /// In en, this message translates to:
  /// **'Cannot contain reserved words'**
  String get profileNicknameRule5;

  /// No description provided for @profileNicknameRules.
  ///
  /// In en, this message translates to:
  /// **'Nickname Rules'**
  String get profileNicknameRules;

  /// No description provided for @profileNicknameSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get profileNicknameSuggestions;

  /// No description provided for @profileNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found for \"@{query}\"'**
  String profileNoUsersFound(String query);

  /// No description provided for @profileNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins! Need {required}, have {available}'**
  String profileNotEnoughCoins(Object available, Object required);

  /// No description provided for @profileOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get profileOccupation;

  /// No description provided for @profileOccupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Engineer'**
  String get profileOccupationHint;

  /// No description provided for @profileOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps others get to know you'**
  String get profileOptionalDetails;

  /// No description provided for @profileOrientationPrivate.
  ///
  /// In en, this message translates to:
  /// **'This is private and not shown on your profile card'**
  String get profileOrientationPrivate;

  /// No description provided for @profilePhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photos'**
  String profilePhotosCount(Object count);

  /// No description provided for @profilePremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get profilePremiumFeatures;

  /// No description provided for @profileProgressGrowth.
  ///
  /// In en, this message translates to:
  /// **'Progress & Growth'**
  String get profileProgressGrowth;

  /// No description provided for @profileRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get profileRestart;

  /// No description provided for @profileRestartDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Restart Discovery'**
  String get profileRestartDiscovery;

  /// No description provided for @profileRestartDiscoveryDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will erase all your swipes (connects, passes, priority connects) so you can rediscover everyone from scratch.\n\nYour matches and chats will NOT be affected.'**
  String get profileRestartDiscoveryDialogContent;

  /// No description provided for @profileRestartDiscoveryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart Discovery'**
  String get profileRestartDiscoveryDialogTitle;

  /// No description provided for @profileRestartDiscoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all swipes and start fresh'**
  String get profileRestartDiscoverySubtitle;

  /// No description provided for @profileSearchByNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by @nickname'**
  String get profileSearchByNickname;

  /// No description provided for @profileSearchByNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by @nickname'**
  String get profileSearchByNicknameHint;

  /// No description provided for @profileSearchCityHint.
  ///
  /// In en, this message translates to:
  /// **'Search city, address, or place...'**
  String get profileSearchCityHint;

  /// No description provided for @profileSearchForUsers.
  ///
  /// In en, this message translates to:
  /// **'Search for users by nickname'**
  String get profileSearchForUsers;

  /// No description provided for @profileSearchLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get profileSearchLanguagesHint;

  /// No description provided for @profileSetLocationAndLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please set location and select at least one language'**
  String get profileSetLocationAndLanguage;

  /// No description provided for @profileSexualOrientation.
  ///
  /// In en, this message translates to:
  /// **'Sexual Orientation'**
  String get profileSexualOrientation;

  /// No description provided for @profileStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get profileStop;

  /// No description provided for @profileTellAboutYourselfHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people about yourself...'**
  String get profileTellAboutYourselfHint;

  /// No description provided for @profileTipAuthentic.
  ///
  /// In en, this message translates to:
  /// **'Be authentic and genuine'**
  String get profileTipAuthentic;

  /// No description provided for @profileTipHobbies.
  ///
  /// In en, this message translates to:
  /// **'Mention your hobbies and passions'**
  String get profileTipHobbies;

  /// No description provided for @profileTipHumor.
  ///
  /// In en, this message translates to:
  /// **'Add a touch of humor'**
  String get profileTipHumor;

  /// No description provided for @profileTipPositive.
  ///
  /// In en, this message translates to:
  /// **'Keep it positive'**
  String get profileTipPositive;

  /// No description provided for @profileTipsForGreatBio.
  ///
  /// In en, this message translates to:
  /// **'Tips for a great bio'**
  String get profileTipsForGreatBio;

  /// No description provided for @profileTravelerActivated.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode activated! Appearing in {city} for 24 hours.'**
  String profileTravelerActivated(Object city);

  /// No description provided for @profileTravelerCost.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode costs {cost} coins per day.'**
  String profileTravelerCost(Object cost);

  /// No description provided for @profileTravelerDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode deactivated. Back to your real location.'**
  String get profileTravelerDeactivated;

  /// No description provided for @profileTravelerDescription.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode lets you appear in a different city\'s discovery feed for 24 hours.\n\nCost: {cost}'**
  String profileTravelerDescription(Object cost);

  /// No description provided for @profileTravelerMode.
  ///
  /// In en, this message translates to:
  /// **'Traveler Mode'**
  String get profileTravelerMode;

  /// No description provided for @profileTryDifferentNickname.
  ///
  /// In en, this message translates to:
  /// **'Try a different nickname'**
  String get profileTryDifferentNickname;

  /// No description provided for @profileUnableToVerifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify account'**
  String get profileUnableToVerifyAccount;

  /// No description provided for @profileUpdateCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Update Current Location'**
  String get profileUpdateCurrentLocation;

  /// No description provided for @profileUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your changes have been saved'**
  String get profileUpdatedMessage;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated!'**
  String get profileUpdatedTitle;

  /// No description provided for @profileWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get profileWeightKg;

  /// No description provided for @profilesLinkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} profile{count, plural, =1{} other{s}} linked'**
  String profilesLinkedCount(int count);

  /// No description provided for @profilingDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow us to analyze your preferences to provide better match suggestions'**
  String get profilingDescription;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @progressAchievements.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get progressAchievements;

  /// No description provided for @progressBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get progressBadges;

  /// No description provided for @progressChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get progressChallenges;

  /// No description provided for @progressComparison.
  ///
  /// In en, this message translates to:
  /// **'Progress Comparison'**
  String get progressComparison;

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get progressCompleted;

  /// No description provided for @progressJourneyDescription.
  ///
  /// In en, this message translates to:
  /// **'See your complete dating journey and milestones'**
  String get progressJourneyDescription;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

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

  /// No description provided for @progressNofM.
  ///
  /// In en, this message translates to:
  /// **'{n}/{m}'**
  String progressNofM(String n, String m);

  /// No description provided for @progressOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get progressOverview;

  /// No description provided for @progressRecentAchievements.
  ///
  /// In en, this message translates to:
  /// **'Recent Achievements'**
  String get progressRecentAchievements;

  /// No description provided for @progressSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get progressSeeAll;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressTodaysChallenges.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Challenges'**
  String get progressTodaysChallenges;

  /// No description provided for @progressTotalXP.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get progressTotalXP;

  /// No description provided for @progressViewJourney.
  ///
  /// In en, this message translates to:
  /// **'View Your Journey'**
  String get progressViewJourney;

  /// No description provided for @publicAlbum.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicAlbum;

  /// No description provided for @purchaseSuccessfulTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful!'**
  String get purchaseSuccessfulTitle;

  /// No description provided for @purchasedLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchasedLabel;

  /// No description provided for @quickPlay.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get quickPlay;

  /// No description provided for @quizCheckpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizCheckpointLabel;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String rankLabel(String rank);

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

  /// No description provided for @readyButton.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyButton;

  /// No description provided for @recipientNickname.
  ///
  /// In en, this message translates to:
  /// **'Recipient nickname'**
  String get recipientNickname;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record Voice'**
  String get recordVoice;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @rejectVerification.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectVerification;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String rejectionReason(String reason);

  /// No description provided for @rejectionReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for rejection'**
  String get rejectionReasonRequired;

  /// No description provided for @remainingToday.
  ///
  /// In en, this message translates to:
  /// **'{remaining} {type} remaining today'**
  String remainingToday(int remaining, String type, Object limitType);

  /// No description provided for @reportSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping keep our community safe'**
  String get reportSubmittedMessage;

  /// No description provided for @reportSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted!'**
  String get reportSubmittedTitle;

  /// No description provided for @reportWord.
  ///
  /// In en, this message translates to:
  /// **'Report Word'**
  String get reportWord;

  /// No description provided for @reportsPanel.
  ///
  /// In en, this message translates to:
  /// **'Reports Panel'**
  String get reportsPanel;

  /// No description provided for @requestBetterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Request Better Photo'**
  String get requestBetterPhoto;

  /// No description provided for @requiresTier.
  ///
  /// In en, this message translates to:
  /// **'Requires {tier}'**
  String requiresTier(String tier);

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @restartAppWizard.
  ///
  /// In en, this message translates to:
  /// **'Restart App Wizard'**
  String get restartAppWizard;

  /// No description provided for @restartWizard.
  ///
  /// In en, this message translates to:
  /// **'Restart Wizard'**
  String get restartWizard;

  /// No description provided for @restartWizardDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will restart the onboarding wizard. You can update your profile information step by step. Your current data will be preserved.'**
  String get restartWizardDialogContent;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reuploadVerification.
  ///
  /// In en, this message translates to:
  /// **'Re-upload Verification Photo'**
  String get reuploadVerification;

  /// No description provided for @reverificationCameraError.
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera'**
  String get reverificationCameraError;

  /// No description provided for @reverificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please take a clear selfie so we can verify your identity. Make sure your face is well lit and clearly visible.'**
  String get reverificationDescription;

  /// No description provided for @reverificationHeading.
  ///
  /// In en, this message translates to:
  /// **'We need to verify your identity'**
  String get reverificationHeading;

  /// No description provided for @reverificationInfoText.
  ///
  /// In en, this message translates to:
  /// **'After submitting, your profile will be under review. You will get access once approved.'**
  String get reverificationInfoText;

  /// No description provided for @reverificationPhotoTips.
  ///
  /// In en, this message translates to:
  /// **'Photo Tips'**
  String get reverificationPhotoTips;

  /// No description provided for @reverificationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for request:'**
  String get reverificationReasonLabel;

  /// No description provided for @reverificationRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get reverificationRetakePhoto;

  /// No description provided for @reverificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get reverificationSubmit;

  /// No description provided for @reverificationTapToSelfie.
  ///
  /// In en, this message translates to:
  /// **'Tap to take a selfie'**
  String get reverificationTapToSelfie;

  /// No description provided for @reverificationTipCamera.
  ///
  /// In en, this message translates to:
  /// **'Look directly at the camera'**
  String get reverificationTipCamera;

  /// No description provided for @reverificationTipFullFace.
  ///
  /// In en, this message translates to:
  /// **'Make sure your full face is visible'**
  String get reverificationTipFullFace;

  /// No description provided for @reverificationTipLighting.
  ///
  /// In en, this message translates to:
  /// **'Good lighting — face the light source'**
  String get reverificationTipLighting;

  /// No description provided for @reverificationTipNoAccessories.
  ///
  /// In en, this message translates to:
  /// **'No sunglasses, hats, or masks'**
  String get reverificationTipNoAccessories;

  /// No description provided for @reverificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get reverificationTitle;

  /// No description provided for @reverificationUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get reverificationUploadFailed;

  /// No description provided for @reviewReportedMessages.
  ///
  /// In en, this message translates to:
  /// **'Review reported messages & manage accounts'**
  String get reviewReportedMessages;

  /// No description provided for @reviewUserVerifications.
  ///
  /// In en, this message translates to:
  /// **'Review user verifications'**
  String get reviewUserVerifications;

  /// No description provided for @reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {admin}'**
  String reviewedBy(String admin);

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke album access'**
  String get revokeAccess;

  /// No description provided for @rewardsAndProgress.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Progress'**
  String get rewardsAndProgress;

  /// No description provided for @romanticCategory.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get romanticCategory;

  /// No description provided for @roundTimer.
  ///
  /// In en, this message translates to:
  /// **'Round Timer'**
  String get roundTimer;

  /// No description provided for @roundXofY.
  ///
  /// In en, this message translates to:
  /// **'Round {current}/{total}'**
  String roundXofY(String current, String total);

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @safetyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get safetyAdd;

  /// No description provided for @safetyAddAtLeastOneContact.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one emergency contact'**
  String get safetyAddAtLeastOneContact;

  /// No description provided for @safetyAddEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get safetyAddEmergencyContact;

  /// No description provided for @safetyAddEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contacts'**
  String get safetyAddEmergencyContacts;

  /// No description provided for @safetyAdditionalDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional details...'**
  String get safetyAdditionalDetailsHint;

  /// No description provided for @safetyCheckInDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up a check-in for your date. We\'ll remind you to check in, and alert your contacts if you don\'t respond.'**
  String get safetyCheckInDescription;

  /// No description provided for @safetyCheckInEvery.
  ///
  /// In en, this message translates to:
  /// **'Check-in every'**
  String get safetyCheckInEvery;

  /// No description provided for @safetyCheckInScheduled.
  ///
  /// In en, this message translates to:
  /// **'Date check-in scheduled!'**
  String get safetyCheckInScheduled;

  /// No description provided for @safetyDateCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Date Check-In'**
  String get safetyDateCheckIn;

  /// No description provided for @safetyDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get safetyDateTime;

  /// No description provided for @safetyEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get safetyEmergencyContacts;

  /// No description provided for @safetyEmergencyContactsHelp.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be notified if you need help'**
  String get safetyEmergencyContactsHelp;

  /// No description provided for @safetyEmergencyContactsLocation.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts can see your location'**
  String get safetyEmergencyContactsLocation;

  /// No description provided for @safetyInterval15Min.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get safetyInterval15Min;

  /// No description provided for @safetyInterval1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get safetyInterval1Hour;

  /// No description provided for @safetyInterval2Hours.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get safetyInterval2Hours;

  /// No description provided for @safetyInterval30Min.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get safetyInterval30Min;

  /// No description provided for @safetyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get safetyLocation;

  /// No description provided for @safetyMeetingLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Where are you meeting?'**
  String get safetyMeetingLocationHint;

  /// No description provided for @safetyMeetingWith.
  ///
  /// In en, this message translates to:
  /// **'Meeting with'**
  String get safetyMeetingWith;

  /// No description provided for @safetyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get safetyNameLabel;

  /// No description provided for @safetyNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get safetyNotesOptional;

  /// No description provided for @safetyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get safetyPhoneLabel;

  /// No description provided for @safetyPleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get safetyPleaseEnterLocation;

  /// No description provided for @safetyRelationshipFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get safetyRelationshipFamily;

  /// No description provided for @safetyRelationshipFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get safetyRelationshipFriend;

  /// No description provided for @safetyRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get safetyRelationshipLabel;

  /// No description provided for @safetyRelationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get safetyRelationshipOther;

  /// No description provided for @safetyRelationshipPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get safetyRelationshipPartner;

  /// No description provided for @safetyRelationshipRoommate.
  ///
  /// In en, this message translates to:
  /// **'Roommate'**
  String get safetyRelationshipRoommate;

  /// No description provided for @safetyScheduleCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Schedule Check-In'**
  String get safetyScheduleCheckIn;

  /// No description provided for @safetyShareLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Share live location'**
  String get safetyShareLiveLocation;

  /// No description provided for @safetyStaySafe.
  ///
  /// In en, this message translates to:
  /// **'Stay Safe'**
  String get safetyStaySafe;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @searchByNameOrNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @nickname'**
  String get searchByNameOrNickname;

  /// No description provided for @searchByNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by Nickname'**
  String get searchByNickname;

  /// No description provided for @searchByNicknameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search by nickname'**
  String get searchByNicknameTooltip;

  /// No description provided for @searchCityPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search city, address, or place...'**
  String get searchCityPlaceholder;

  /// No description provided for @searchCountries.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get searchCountries;

  /// No description provided for @searchCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get searchCountryHint;

  /// No description provided for @searchForCity.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or use GPS'**
  String get searchForCity;

  /// No description provided for @searchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchMessagesHint;

  /// No description provided for @secondChanceDescription.
  ///
  /// In en, this message translates to:
  /// **'See profiles you passed on who actually liked you!'**
  String get secondChanceDescription;

  /// No description provided for @secondChanceDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String secondChanceDistanceAway(Object distance);

  /// No description provided for @secondChanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No second chances available'**
  String get secondChanceEmpty;

  /// No description provided for @secondChanceEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back later for more opportunities!'**
  String get secondChanceEmptySubtitle;

  /// No description provided for @secondChanceFindButton.
  ///
  /// In en, this message translates to:
  /// **'Find Second Chances'**
  String get secondChanceFindButton;

  /// No description provided for @secondChanceFreeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{max} free'**
  String secondChanceFreeRemaining(Object max, Object remaining);

  /// No description provided for @secondChanceGetUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Get Unlimited ({cost})'**
  String secondChanceGetUnlimited(Object cost);

  /// No description provided for @secondChanceLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get secondChanceLike;

  /// No description provided for @secondChanceLikedYouAgo.
  ///
  /// In en, this message translates to:
  /// **'They liked you {ago}'**
  String secondChanceLikedYouAgo(Object ago);

  /// No description provided for @secondChanceMatchBody.
  ///
  /// In en, this message translates to:
  /// **'You and this person both like each other! Start a conversation.'**
  String get secondChanceMatchBody;

  /// No description provided for @secondChanceMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Exchange!'**
  String get secondChanceMatchTitle;

  /// No description provided for @secondChanceOutOf.
  ///
  /// In en, this message translates to:
  /// **'Out of Second Chances'**
  String get secondChanceOutOf;

  /// No description provided for @secondChancePass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get secondChancePass;

  /// No description provided for @secondChancePurchaseBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all {freePerDay} free second chances for today.\n\nGet unlimited for {cost} coins!'**
  String secondChancePurchaseBody(Object cost, Object freePerDay);

  /// No description provided for @secondChanceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get secondChanceRefresh;

  /// No description provided for @secondChanceStartChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get secondChanceStartChat;

  /// No description provided for @secondChanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Second Chance'**
  String get secondChanceTitle;

  /// No description provided for @secondChanceUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get secondChanceUnlimited;

  /// No description provided for @secondChanceUnlimitedUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlimited second chances unlocked!'**
  String get secondChanceUnlimitedUnlocked;

  /// No description provided for @secondaryOrigin.
  ///
  /// In en, this message translates to:
  /// **'Secondary Origin (optional)'**
  String get secondaryOrigin;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @secretAchievement.
  ///
  /// In en, this message translates to:
  /// **'Secret Achievement'**
  String get secretAchievement;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @seeHowOthersViewProfile.
  ///
  /// In en, this message translates to:
  /// **'See how others view your profile'**
  String get seeHowOthersViewProfile;

  /// No description provided for @seeMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'See {count} more'**
  String seeMoreProfiles(int count);

  /// No description provided for @seeMoreProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'See More Profiles'**
  String get seeMoreProfilesTitle;

  /// No description provided for @seeProfile.
  ///
  /// In en, this message translates to:
  /// **'See Profile'**
  String get seeProfile;

  /// No description provided for @selectAtLeastInterests.
  ///
  /// In en, this message translates to:
  /// **'Select at least {count} interests'**
  String selectAtLeastInterests(int count);

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectTravelLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Travel Location'**
  String get selectTravelLocation;

  /// No description provided for @sendCoins.
  ///
  /// In en, this message translates to:
  /// **'Send Coins'**
  String get sendCoins;

  /// No description provided for @sendCoinsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} coins to @{nickname}?'**
  String sendCoinsConfirm(String amount, String nickname);

  /// No description provided for @sendMedia.
  ///
  /// In en, this message translates to:
  /// **'Send Media'**
  String get sendMedia;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @serverUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Our servers are temporarily unavailable. Please try again in a few moments.'**
  String get serverUnavailableMessage;

  /// No description provided for @serverUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Unavailable'**
  String get serverUnavailableTitle;

  /// No description provided for @setYourUniqueNickname.
  ///
  /// In en, this message translates to:
  /// **'Set your unique nickname'**
  String get setYourUniqueNickname;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shareAlbum.
  ///
  /// In en, this message translates to:
  /// **'Share Album'**
  String get shareAlbum;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @shopActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get shopActive;

  /// No description provided for @shopAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get shopAdvancedFilters;

  /// No description provided for @shopAmountCoins.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins'**
  String shopAmountCoins(Object amount);

  /// No description provided for @shopBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get shopBadge;

  /// No description provided for @shopBaseMembership.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Base Membership'**
  String get shopBaseMembership;

  /// No description provided for @shopBaseMembershipDescription.
  ///
  /// In en, this message translates to:
  /// **'Required to swipe, like, chat, and interact with other users.'**
  String get shopBaseMembershipDescription;

  /// No description provided for @shopBonusCoins.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} bonus coins'**
  String shopBonusCoins(Object bonus);

  /// No description provided for @shopBoosts.
  ///
  /// In en, this message translates to:
  /// **'Boosts'**
  String get shopBoosts;

  /// No description provided for @shopBuyTier.
  ///
  /// In en, this message translates to:
  /// **'Buy {tier} ({duration})'**
  String shopBuyTier(String tier, String duration);

  /// No description provided for @shopCannotSendToSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot send coins to yourself'**
  String get shopCannotSendToSelf;

  /// No description provided for @shopCheckInternet.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have an internet connection\nand try again.'**
  String get shopCheckInternet;

  /// No description provided for @shopCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get shopCoins;

  /// No description provided for @shopCoinsPerDollar.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins/\$'**
  String shopCoinsPerDollar(Object amount);

  /// No description provided for @shopCoinsSentTo.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins sent to @{nickname}'**
  String shopCoinsSentTo(String amount, String nickname);

  /// No description provided for @shopComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get shopComingSoon;

  /// No description provided for @shopConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm Send'**
  String get shopConfirmSend;

  /// No description provided for @shopCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get shopCurrent;

  /// No description provided for @shopCurrentExpires.
  ///
  /// In en, this message translates to:
  /// **'CURRENT - Expires {date}'**
  String shopCurrentExpires(Object date);

  /// No description provided for @shopCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan: {tier}'**
  String shopCurrentPlan(String tier);

  /// No description provided for @shopDailyLikes.
  ///
  /// In en, this message translates to:
  /// **'Daily Connects'**
  String get shopDailyLikes;

  /// No description provided for @shopDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String shopDaysLeft(Object days);

  /// No description provided for @shopEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get shopEnterAmount;

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

  /// No description provided for @shopExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired: {date}'**
  String shopExpired(String date);

  /// No description provided for @shopExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date} ({days} days remaining)'**
  String shopExpires(String date, String days);

  /// No description provided for @shopFailedToInitiate.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate purchase'**
  String get shopFailedToInitiate;

  /// No description provided for @shopFailedToSendCoins.
  ///
  /// In en, this message translates to:
  /// **'Failed to send coins'**
  String get shopFailedToSendCoins;

  /// No description provided for @shopGetNotified.
  ///
  /// In en, this message translates to:
  /// **'Get Notified'**
  String get shopGetNotified;

  /// No description provided for @shopGreenGoCoins.
  ///
  /// In en, this message translates to:
  /// **'GreenGoCoins'**
  String get shopGreenGoCoins;

  /// No description provided for @shopIncognitoMode.
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get shopIncognitoMode;

  /// No description provided for @shopInsufficientCoins.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coins'**
  String get shopInsufficientCoins;

  /// No description provided for @shopMembershipActivated.
  ///
  /// In en, this message translates to:
  /// **'GreenGo Membership activated! +500 bonus coins. Valid until {date}.'**
  String shopMembershipActivated(String date);

  /// No description provided for @shopMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get shopMonthly;

  /// No description provided for @shopNotifyMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when Video-Coins is available'**
  String get shopNotifyMessage;

  /// No description provided for @shopOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get shopOneMonth;

  /// No description provided for @shopOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get shopOneYear;

  /// No description provided for @shopPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get shopPerMonth;

  /// No description provided for @shopPerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get shopPerYear;

  /// No description provided for @shopPopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get shopPopular;

  /// No description provided for @shopPreviousPurchaseFound.
  ///
  /// In en, this message translates to:
  /// **'Previous purchase found. Please try again.'**
  String get shopPreviousPurchaseFound;

  /// No description provided for @shopPriorityMatching.
  ///
  /// In en, this message translates to:
  /// **'Priority Matching'**
  String get shopPriorityMatching;

  /// No description provided for @shopPurchaseCoinsFor.
  ///
  /// In en, this message translates to:
  /// **'Purchase {coins} Coins for {price}'**
  String shopPurchaseCoinsFor(String coins, String price);

  /// No description provided for @shopPurchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase error: {error}'**
  String shopPurchaseError(Object error);

  /// No description provided for @shopReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read Receipts'**
  String get shopReadReceipts;

  /// No description provided for @shopRecipientNickname.
  ///
  /// In en, this message translates to:
  /// **'Recipient nickname'**
  String get shopRecipientNickname;

  /// No description provided for @shopRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shopRetry;

  /// No description provided for @shopSavePercent.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String shopSavePercent(String percent);

  /// No description provided for @shopSeeWhoLikesYou.
  ///
  /// In en, this message translates to:
  /// **'See Who Connects'**
  String get shopSeeWhoLikesYou;

  /// No description provided for @shopSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shopSend;

  /// No description provided for @shopSendCoins.
  ///
  /// In en, this message translates to:
  /// **'Send Coins'**
  String get shopSendCoins;

  /// No description provided for @shopStoreNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Store not available. Please check your device settings.'**
  String get shopStoreNotAvailable;

  /// No description provided for @shopSuperLikes.
  ///
  /// In en, this message translates to:
  /// **'Priority Connects'**
  String get shopSuperLikes;

  /// No description provided for @shopTabCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get shopTabCoins;

  /// No description provided for @shopTabError.
  ///
  /// In en, this message translates to:
  /// **'{tabName} tab error'**
  String shopTabError(Object tabName);

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

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopTravelling.
  ///
  /// In en, this message translates to:
  /// **'Travelling'**
  String get shopTravelling;

  /// No description provided for @shopUnableToLoadPackages.
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Packages'**
  String get shopUnableToLoadPackages;

  /// No description provided for @shopUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get shopUnlimited;

  /// No description provided for @shopUnlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features and enhance your dating experience'**
  String get shopUnlockPremium;

  /// No description provided for @shopUpgradeAndSave.
  ///
  /// In en, this message translates to:
  /// **'Upgrade & Save! Get discount on higher tiers'**
  String get shopUpgradeAndSave;

  /// No description provided for @shopUpgradeExperience.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Experience'**
  String get shopUpgradeExperience;

  /// No description provided for @shopUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {tier} ({duration})'**
  String shopUpgradeTo(String tier, String duration);

  /// No description provided for @shopUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get shopUserNotFound;

  /// No description provided for @shopValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String shopValidUntil(String date);

  /// No description provided for @shopVideoCoinsDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch short videos to earn free coins!\nStay tuned for this exciting feature.'**
  String get shopVideoCoinsDescription;

  /// No description provided for @shopVipBadge.
  ///
  /// In en, this message translates to:
  /// **'VIP Badge'**
  String get shopVipBadge;

  /// No description provided for @shopYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get shopYearly;

  /// No description provided for @shopYearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly subscription'**
  String get shopYearlyPlan;

  /// No description provided for @shopYouHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get shopYouHave;

  /// No description provided for @shopYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save \${amount}/month upgrading from {tier}'**
  String shopYouSave(String amount, String tier);

  /// No description provided for @shortTermRelationship.
  ///
  /// In en, this message translates to:
  /// **'Short-term relationship'**
  String get shortTermRelationship;

  /// No description provided for @showingProfiles.
  ///
  /// In en, this message translates to:
  /// **'{count} profiles'**
  String showingProfiles(int count);

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

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// No description provided for @slangCategory.
  ///
  /// In en, this message translates to:
  /// **'Slang'**
  String get slangCategory;

  /// No description provided for @socialConnectAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connect your social accounts'**
  String get socialConnectAccounts;

  /// No description provided for @socialHintUsername.
  ///
  /// In en, this message translates to:
  /// **'Username (without @)'**
  String get socialHintUsername;

  /// No description provided for @socialHintUsernameOrUrl.
  ///
  /// In en, this message translates to:
  /// **'Username or profile URL'**
  String get socialHintUsernameOrUrl;

  /// No description provided for @socialLinksUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your social profiles have been saved'**
  String get socialLinksUpdatedMessage;

  /// No description provided for @socialLinksUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Links Updated!'**
  String get socialLinksUpdatedTitle;

  /// No description provided for @socialNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get socialNotConnected;

  /// No description provided for @socialProfiles.
  ///
  /// In en, this message translates to:
  /// **'Social Profiles'**
  String get socialProfiles;

  /// No description provided for @socialProfilesTip.
  ///
  /// In en, this message translates to:
  /// **'Your social profiles will be visible on your dating profile and help others verify your identity.'**
  String get socialProfilesTip;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @spotsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get spotsAbout;

  /// No description provided for @spotsAddNewSpot.
  ///
  /// In en, this message translates to:
  /// **'Add a New Spot'**
  String get spotsAddNewSpot;

  /// No description provided for @spotsAddSpot.
  ///
  /// In en, this message translates to:
  /// **'Add a Spot'**
  String get spotsAddSpot;

  /// No description provided for @spotsAddedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String spotsAddedBy(Object name);

  /// No description provided for @spotsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get spotsAll;

  /// No description provided for @spotsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get spotsCategory;

  /// No description provided for @spotsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load spots'**
  String get spotsCouldNotLoad;

  /// No description provided for @spotsCouldNotLoadSpot.
  ///
  /// In en, this message translates to:
  /// **'Could not load spot'**
  String get spotsCouldNotLoadSpot;

  /// No description provided for @spotsCreateSpot.
  ///
  /// In en, this message translates to:
  /// **'Create Spot'**
  String get spotsCreateSpot;

  /// No description provided for @spotsCulturalSpots.
  ///
  /// In en, this message translates to:
  /// **'Cultural Spots'**
  String get spotsCulturalSpots;

  /// No description provided for @spotsDateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String spotsDateDaysAgo(Object count);

  /// No description provided for @spotsDateMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String spotsDateMonthsAgo(Object count);

  /// No description provided for @spotsDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get spotsDateToday;

  /// No description provided for @spotsDateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String spotsDateWeeksAgo(Object count);

  /// No description provided for @spotsDateYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String spotsDateYearsAgo(Object count);

  /// No description provided for @spotsDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get spotsDateYesterday;

  /// No description provided for @spotsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get spotsDescriptionLabel;

  /// No description provided for @spotsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Spot Name'**
  String get spotsNameLabel;

  /// No description provided for @spotsNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to write one!'**
  String get spotsNoReviews;

  /// No description provided for @spotsNoSpotsFound.
  ///
  /// In en, this message translates to:
  /// **'No spots found'**
  String get spotsNoSpotsFound;

  /// No description provided for @spotsReviewAdded.
  ///
  /// In en, this message translates to:
  /// **'Review added!'**
  String get spotsReviewAdded;

  /// No description provided for @spotsReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String spotsReviewsCount(Object count);

  /// No description provided for @spotsShareExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get spotsShareExperienceHint;

  /// No description provided for @spotsSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get spotsSubmitReview;

  /// No description provided for @spotsWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get spotsWriteReview;

  /// No description provided for @spotsYourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get spotsYourRating;

  /// No description provided for @standardTier.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standardTier;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @startLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get startLearning;

  /// No description provided for @startLessonBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get startLessonBtn;

  /// No description provided for @startSwipingToFindMatches.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to find your matches!'**
  String get startSwipingToFindMatches;

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

  /// No description provided for @storiesAddCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get storiesAddCaptionHint;

  /// No description provided for @storiesCreateStory.
  ///
  /// In en, this message translates to:
  /// **'Create Story'**
  String get storiesCreateStory;

  /// No description provided for @storiesDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String storiesDaysAgo(Object count);

  /// No description provided for @storiesDisappearAfter24h.
  ///
  /// In en, this message translates to:
  /// **'Your story will disappear after 24 hours'**
  String get storiesDisappearAfter24h;

  /// No description provided for @storiesGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get storiesGallery;

  /// No description provided for @storiesHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String storiesHoursAgo(Object count);

  /// No description provided for @storiesMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String storiesMinutesAgo(Object count);

  /// No description provided for @storiesNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active stories'**
  String get storiesNoActive;

  /// No description provided for @storiesNoStories.
  ///
  /// In en, this message translates to:
  /// **'No stories available'**
  String get storiesNoStories;

  /// No description provided for @storiesPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get storiesPhoto;

  /// No description provided for @storiesPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get storiesPost;

  /// No description provided for @storiesSendMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Send a message...'**
  String get storiesSendMessageHint;

  /// No description provided for @storiesShareMoment.
  ///
  /// In en, this message translates to:
  /// **'Share a moment'**
  String get storiesShareMoment;

  /// No description provided for @storiesVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get storiesVideo;

  /// No description provided for @storiesYourStory.
  ///
  /// In en, this message translates to:
  /// **'Your Story'**
  String get storiesYourStory;

  /// No description provided for @streakActiveToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get streakActiveToday;

  /// No description provided for @streakBonusHeader.
  ///
  /// In en, this message translates to:
  /// **'Streak Bonus!'**
  String get streakBonusHeader;

  /// No description provided for @streakInactive.
  ///
  /// In en, this message translates to:
  /// **'Start your streak!'**
  String get streakInactive;

  /// No description provided for @streakMessageIncredible.
  ///
  /// In en, this message translates to:
  /// **'Incredible dedication! 🏆'**
  String get streakMessageIncredible;

  /// No description provided for @streakMessageKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up! ✨'**
  String get streakMessageKeepItUp;

  /// No description provided for @streakMessageMomentum.
  ///
  /// In en, this message translates to:
  /// **'Building momentum! 🚀'**
  String get streakMessageMomentum;

  /// No description provided for @streakMessageOneWeek.
  ///
  /// In en, this message translates to:
  /// **'One week milestone! 🎯'**
  String get streakMessageOneWeek;

  /// No description provided for @streakMessageTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Two weeks strong! 💪'**
  String get streakMessageTwoWeeks;

  /// No description provided for @submitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// No description provided for @submitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitVerification;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String submittedOn(String date);

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your {tierName} subscription has expired. You have been moved to the Free tier.\n\nUpgrade anytime to restore your premium features!'**
  String subscriptionExpiredBody(Object tierName);

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @superLike.
  ///
  /// In en, this message translates to:
  /// **'Priority Connect'**
  String get superLike;

  /// No description provided for @superLikedYou.
  ///
  /// In en, this message translates to:
  /// **'{name} priority connected with you!'**
  String superLikedYou(String name);

  /// No description provided for @superLikes.
  ///
  /// In en, this message translates to:
  /// **'Priority Connects'**
  String get superLikes;

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

  /// No description provided for @swipeIndicatorLike.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get swipeIndicatorLike;

  /// No description provided for @swipeIndicatorNope.
  ///
  /// In en, this message translates to:
  /// **'PASS'**
  String get swipeIndicatorNope;

  /// No description provided for @swipeIndicatorSkip.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE NEXT'**
  String get swipeIndicatorSkip;

  /// No description provided for @swipeIndicatorSuperLike.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY CONNECT'**
  String get swipeIndicatorSuperLike;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @takeVerificationPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Verification Photo'**
  String get takeVerificationPhoto;

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tapToContinue;

  /// No description provided for @targetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target Language'**
  String get targetLanguage;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @thatsYourOwnProfile.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own profile!'**
  String get thatsYourOwnProfile;

  /// No description provided for @thirdPartyDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow sharing anonymized data with partners for service improvement'**
  String get thirdPartyDataDescription;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get timeRemaining;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get timeoutError;

  /// No description provided for @toNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to Level {level}'**
  String toNextLevel(int percent, int level);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @totalXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXpLabel;

  /// No description provided for @tourDiscoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Swipe through profiles to find your perfect match. Swipe right if you\'re interested, left to pass.'**
  String get tourDiscoveryDescription;

  /// No description provided for @tourDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Matches'**
  String get tourDiscoveryTitle;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// No description provided for @tourLearnDescription.
  ///
  /// In en, this message translates to:
  /// **'Study vocabulary, grammar, and conversation skills'**
  String get tourLearnDescription;

  /// No description provided for @tourLearnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn Languages'**
  String get tourLearnTitle;

  /// No description provided for @tourMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'See everyone who liked you back! Start conversations with your mutual matches.'**
  String get tourMatchesDescription;

  /// No description provided for @tourMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Matches'**
  String get tourMatchesTitle;

  /// No description provided for @tourMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat with your matches here. Send messages, photos, and voice notes to connect.'**
  String get tourMessagesDescription;

  /// No description provided for @tourMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tourMessagesTitle;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourPlayDescription.
  ///
  /// In en, this message translates to:
  /// **'Challenge others in fun language games'**
  String get tourPlayDescription;

  /// No description provided for @tourPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Play Games'**
  String get tourPlayTitle;

  /// No description provided for @tourProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize your profile, manage settings, and control your privacy.'**
  String get tourProfileDescription;

  /// No description provided for @tourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get tourProfileTitle;

  /// No description provided for @tourProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Earn badges, complete challenges, and climb the leaderboard!'**
  String get tourProgressDescription;

  /// No description provided for @tourProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Progress'**
  String get tourProgressTitle;

  /// No description provided for @tourShopDescription.
  ///
  /// In en, this message translates to:
  /// **'Get coins and premium features to boost your dating experience.'**
  String get tourShopDescription;

  /// No description provided for @tourShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop & Coins'**
  String get tourShopTitle;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @translateWord.
  ///
  /// In en, this message translates to:
  /// **'Translate this word'**
  String get translateWord;

  /// No description provided for @translationDownloadExplanation.
  ///
  /// In en, this message translates to:
  /// **'To enable automatic message translation, we need to download language data for offline use.'**
  String get translationDownloadExplanation;

  /// No description provided for @travelCategory.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelCategory;

  /// No description provided for @travelLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelLabel;

  /// No description provided for @travelerAppearFor24Hours.
  ///
  /// In en, this message translates to:
  /// **'You will appear in discovery results for this location for 24 hours.'**
  String get travelerAppearFor24Hours;

  /// No description provided for @travelerBadge.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get travelerBadge;

  /// No description provided for @travelerChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get travelerChangeLocation;

  /// No description provided for @travelerConfirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get travelerConfirmLocation;

  /// No description provided for @travelerFailedGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String travelerFailedGetLocation(Object error);

  /// No description provided for @travelerGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get travelerGettingLocation;

  /// No description provided for @travelerInCity.
  ///
  /// In en, this message translates to:
  /// **'In {city}'**
  String travelerInCity(String city);

  /// No description provided for @travelerLoadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Loading address...'**
  String get travelerLoadingAddress;

  /// No description provided for @travelerLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'You will appear in discovery results for this location for 24 hours.'**
  String get travelerLocationInfo;

  /// No description provided for @travelerLocationPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions denied'**
  String get travelerLocationPermissionsDenied;

  /// No description provided for @travelerLocationPermissionsPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions permanently denied'**
  String get travelerLocationPermissionsPermanentlyDenied;

  /// No description provided for @travelerLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get travelerLocationServicesDisabled;

  /// No description provided for @travelerModeActivated.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode activated! Appearing in {city} for 24 hours.'**
  String travelerModeActivated(String city);

  /// No description provided for @travelerModeActive.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode active'**
  String get travelerModeActive;

  /// No description provided for @travelerModeDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Traveler mode deactivated. Back to your real location.'**
  String get travelerModeDeactivated;

  /// No description provided for @travelerModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Appear in a different city\'s discovery feed for 24 hours'**
  String get travelerModeDescription;

  /// No description provided for @travelerModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveler Mode'**
  String get travelerModeTitle;

  /// No description provided for @travelerNoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String travelerNoResultsFor(Object query);

  /// No description provided for @travelerPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get travelerPickOnMap;

  /// No description provided for @travelerProfileAppearDescription.
  ///
  /// In en, this message translates to:
  /// **'Your profile will appear in that location\'s discovery feed for 24 hours with a Traveler badge.'**
  String get travelerProfileAppearDescription;

  /// No description provided for @travelerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Your profile will appear in that location\'s discovery feed for 24 hours with a Traveler badge.'**
  String get travelerSearchHint;

  /// No description provided for @travelerSearchOrGps.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or use GPS'**
  String get travelerSearchOrGps;

  /// No description provided for @travelerSelectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select on Map'**
  String get travelerSelectOnMap;

  /// No description provided for @travelerSelectThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Select This Location'**
  String get travelerSelectThisLocation;

  /// No description provided for @travelerSelectTravelLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Travel Location'**
  String get travelerSelectTravelLocation;

  /// No description provided for @travelerTapOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select a location'**
  String get travelerTapOnMap;

  /// No description provided for @travelerUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use GPS'**
  String get travelerUseGps;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @tryDifferentSearchOrFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter'**
  String get tryDifferentSearchOrFilter;

  /// No description provided for @twoFaDisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA authentication disabled'**
  String get twoFaDisabled;

  /// No description provided for @twoFaEnabled.
  ///
  /// In en, this message translates to:
  /// **'2FA authentication enabled'**
  String get twoFaEnabled;

  /// No description provided for @twoFaToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require email code verification on every login'**
  String get twoFaToggleSubtitle;

  /// No description provided for @twoFaToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA Authenticator'**
  String get twoFaToggleTitle;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @typeQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get typeQuizzes;

  /// No description provided for @typeStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get typeStreak;

  /// No description provided for @typeWordStartingWith.
  ///
  /// In en, this message translates to:
  /// **'Type a word starting with \"{letter}\"'**
  String typeWordStartingWith(String letter);

  /// No description provided for @typeWordsLearned.
  ///
  /// In en, this message translates to:
  /// **'Words Learned'**
  String get typeWordsLearned;

  /// No description provided for @typeXp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get typeXp;

  /// No description provided for @unableToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile'**
  String get unableToLoadProfile;

  /// No description provided for @unableToPlayVoiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Unable to play voice introduction'**
  String get unableToPlayVoiceIntro;

  /// No description provided for @undoSwipe.
  ///
  /// In en, this message translates to:
  /// **'Undo Swipe'**
  String get undoSwipe;

  /// No description provided for @unitLabelN.
  ///
  /// In en, this message translates to:
  /// **'Unit {number}'**
  String unitLabelN(String number);

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'Unlock {count} more profiles in grid view for {cost} coins.'**
  String unlockMoreProfiles(int count, int cost);

  /// No description provided for @unmatchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unmatch with {name}? This cannot be undone.'**
  String unmatchConfirm(String name);

  /// No description provided for @unmatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get unmatchLabel;

  /// No description provided for @unmatchedWith.
  ///
  /// In en, this message translates to:
  /// **'Unmatched with {name}'**
  String unmatchedWith(String name);

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeForEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Silver, Gold, or Platinum for early access before April 14th, 2026!'**
  String get upgradeForEarlyAccess;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @upgradeToTier.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {tier}'**
  String upgradeToTier(String tier);

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @uppercaseLowercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase and lowercase letters'**
  String get uppercaseLowercase;

  /// No description provided for @useCurrentGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current GPS location'**
  String get useCurrentGpsLocation;

  /// No description provided for @usedToday.
  ///
  /// In en, this message translates to:
  /// **'Used today'**
  String get usedToday;

  /// No description provided for @usedWords.
  ///
  /// In en, this message translates to:
  /// **'Used Words'**
  String get usedWords;

  /// No description provided for @userBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'{displayName} has been blocked'**
  String userBlockedMessage(String displayName);

  /// No description provided for @userBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'User Blocked!'**
  String get userBlockedTitle;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

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

  /// No description provided for @verificationApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification approved successfully'**
  String get verificationApprovedSuccess;

  /// No description provided for @verificationDescription.
  ///
  /// In en, this message translates to:
  /// **'To ensure the safety of our community, we require all users to verify their identity. Please take a photo of yourself holding your ID document.'**
  String get verificationDescription;

  /// No description provided for @verificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Verification History'**
  String get verificationHistory;

  /// No description provided for @verificationInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please hold your ID document (passport, driver\'s license, or national ID) next to your face and take a clear photo.'**
  String get verificationInstructions;

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

  /// No description provided for @verificationPanel.
  ///
  /// In en, this message translates to:
  /// **'Verification Panel'**
  String get verificationPanel;

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

  /// No description provided for @verificationRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get verificationRejectedSuccess;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification Required'**
  String get verificationRequired;

  /// No description provided for @verificationSkipWarning.
  ///
  /// In en, this message translates to:
  /// **'You can browse the app, but you won\'t be able to chat or see other profiles until verified.'**
  String get verificationSkipWarning;

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

  /// No description provided for @verificationTips.
  ///
  /// In en, this message translates to:
  /// **'Tips for a successful verification:'**
  String get verificationTips;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Identity'**
  String get verificationTitle;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @vibeTagsCountSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} / {limit} tags selected'**
  String vibeTagsCountSelected(Object count, Object limit);

  /// No description provided for @vibeTagsGet5Tags.
  ///
  /// In en, this message translates to:
  /// **'Get 5 tags'**
  String get vibeTagsGet5Tags;

  /// No description provided for @vibeTagsGetAccessTo.
  ///
  /// In en, this message translates to:
  /// **'Get access to:'**
  String get vibeTagsGetAccessTo;

  /// No description provided for @vibeTagsLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Tag Limit Reached'**
  String get vibeTagsLimitReached;

  /// No description provided for @vibeTagsLimitReachedFree.
  ///
  /// In en, this message translates to:
  /// **'Free users can select up to {limit} tags. Upgrade to Premium for 5 tags!'**
  String vibeTagsLimitReachedFree(Object limit);

  /// No description provided for @vibeTagsLimitReachedPremium.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your maximum of {limit} tags. Remove one to add another.'**
  String vibeTagsLimitReachedPremium(Object limit);

  /// No description provided for @vibeTagsNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get vibeTagsNoTags;

  /// No description provided for @vibeTagsPremiumFeature1.
  ///
  /// In en, this message translates to:
  /// **'5 vibe tags instead of 3'**
  String get vibeTagsPremiumFeature1;

  /// No description provided for @vibeTagsPremiumFeature2.
  ///
  /// In en, this message translates to:
  /// **'Exclusive premium tags'**
  String get vibeTagsPremiumFeature2;

  /// No description provided for @vibeTagsPremiumFeature3.
  ///
  /// In en, this message translates to:
  /// **'Priority in search results'**
  String get vibeTagsPremiumFeature3;

  /// No description provided for @vibeTagsPremiumFeature4.
  ///
  /// In en, this message translates to:
  /// **'And much more!'**
  String get vibeTagsPremiumFeature4;

  /// No description provided for @vibeTagsRemoveTag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag'**
  String get vibeTagsRemoveTag;

  /// No description provided for @vibeTagsSelectDescription.
  ///
  /// In en, this message translates to:
  /// **'Select tags that match your current mood and intentions'**
  String get vibeTagsSelectDescription;

  /// No description provided for @vibeTagsSetTemporary.
  ///
  /// In en, this message translates to:
  /// **'Set as temporary tag (24h)'**
  String get vibeTagsSetTemporary;

  /// No description provided for @vibeTagsShowYourVibe.
  ///
  /// In en, this message translates to:
  /// **'Show your vibe'**
  String get vibeTagsShowYourVibe;

  /// No description provided for @vibeTagsTemporaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Show this vibe for the next 24 hours'**
  String get vibeTagsTemporaryDescription;

  /// No description provided for @vibeTagsTemporaryTag.
  ///
  /// In en, this message translates to:
  /// **'Temporary Tag (24h)'**
  String get vibeTagsTemporaryTag;

  /// No description provided for @vibeTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Vibe'**
  String get vibeTagsTitle;

  /// No description provided for @vibeTagsUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get vibeTagsUpgradeToPremium;

  /// No description provided for @vibeTagsViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get vibeTagsViewPlans;

  /// No description provided for @vibeTagsYourSelected.
  ///
  /// In en, this message translates to:
  /// **'Your Selected Tags'**
  String get vibeTagsYourSelected;

  /// No description provided for @videoCallCategory.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCallCategory;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @viewAllChallenges.
  ///
  /// In en, this message translates to:
  /// **'View All Challenges'**
  String get viewAllChallenges;

  /// No description provided for @viewAllLabel.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllLabel;

  /// No description provided for @viewBadgesAchievementsLevel.
  ///
  /// In en, this message translates to:
  /// **'View badges, achievements & level'**
  String get viewBadgesAchievementsLevel;

  /// No description provided for @viewMyProfile.
  ///
  /// In en, this message translates to:
  /// **'View My Profile'**
  String get viewMyProfile;

  /// No description provided for @viewsGainedCount.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String viewsGainedCount(int count);

  /// No description provided for @vipGoldMember.
  ///
  /// In en, this message translates to:
  /// **'GOLD MEMBER'**
  String get vipGoldMember;

  /// No description provided for @vipPlatinumMember.
  ///
  /// In en, this message translates to:
  /// **'PLATINUM VIP'**
  String get vipPlatinumMember;

  /// No description provided for @vipPremiumBenefitsActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Benefits Active'**
  String get vipPremiumBenefitsActive;

  /// No description provided for @vipSilverMember.
  ///
  /// In en, this message translates to:
  /// **'SILVER MEMBER'**
  String get vipSilverMember;

  /// No description provided for @virtualGiftsAddMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Add a message (optional)'**
  String get virtualGiftsAddMessageHint;

  /// No description provided for @voiceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your voice introduction?'**
  String get voiceDeleteConfirm;

  /// No description provided for @voiceDeleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get voiceDeleteRecording;

  /// No description provided for @voiceFailedStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording: {error}'**
  String voiceFailedStartRecording(Object error);

  /// No description provided for @voiceFailedUploadRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload recording: {error}'**
  String voiceFailedUploadRecording(Object error);

  /// No description provided for @voiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Voice Introduction'**
  String get voiceIntro;

  /// No description provided for @voiceIntroSaved.
  ///
  /// In en, this message translates to:
  /// **'Voice introduction saved'**
  String get voiceIntroSaved;

  /// No description provided for @voiceIntroShort.
  ///
  /// In en, this message translates to:
  /// **'Voice Intro'**
  String get voiceIntroShort;

  /// No description provided for @voiceIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Voice Introduction'**
  String get voiceIntroduction;

  /// No description provided for @voiceIntroductionInfo.
  ///
  /// In en, this message translates to:
  /// **'Voice introductions help others get to know you better. This step is optional.'**
  String get voiceIntroductionInfo;

  /// No description provided for @voiceIntroductionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record a short voice message (optional)'**
  String get voiceIntroductionSubtitle;

  /// No description provided for @voiceIntroductionTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice introduction'**
  String get voiceIntroductionTitle;

  /// No description provided for @voiceMicrophonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required'**
  String get voiceMicrophonePermissionRequired;

  /// No description provided for @voiceRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record Again'**
  String get voiceRecordAgain;

  /// No description provided for @voiceRecordIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a short {seconds} second introduction to let others hear your personality.'**
  String voiceRecordIntroDescription(int seconds);

  /// No description provided for @voiceRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice recorded'**
  String get voiceRecorded;

  /// No description provided for @voiceRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording... (max {maxDuration} seconds)'**
  String voiceRecordingInProgress(Object maxDuration);

  /// No description provided for @voiceRecordingReady.
  ///
  /// In en, this message translates to:
  /// **'Recording ready'**
  String get voiceRecordingReady;

  /// No description provided for @voiceRecordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get voiceRecordingSaved;

  /// No description provided for @voiceRecordingTips.
  ///
  /// In en, this message translates to:
  /// **'Recording Tips'**
  String get voiceRecordingTips;

  /// No description provided for @voiceSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your voice introduction has been updated'**
  String get voiceSavedMessage;

  /// No description provided for @voiceSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Saved!'**
  String get voiceSavedTitle;

  /// No description provided for @voiceStandOutWithYourVoice.
  ///
  /// In en, this message translates to:
  /// **'Stand out with your voice!'**
  String get voiceStandOutWithYourVoice;

  /// No description provided for @voiceTapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get voiceTapToRecord;

  /// No description provided for @voiceTipBeYourself.
  ///
  /// In en, this message translates to:
  /// **'Be yourself and natural'**
  String get voiceTipBeYourself;

  /// No description provided for @voiceTipFindQuietPlace.
  ///
  /// In en, this message translates to:
  /// **'Find a quiet place'**
  String get voiceTipFindQuietPlace;

  /// No description provided for @voiceTipKeepItShort.
  ///
  /// In en, this message translates to:
  /// **'Keep it short and sweet'**
  String get voiceTipKeepItShort;

  /// No description provided for @voiceTipShareWhatMakesYouUnique.
  ///
  /// In en, this message translates to:
  /// **'Share what makes you unique'**
  String get voiceTipShareWhatMakesYouUnique;

  /// No description provided for @voiceUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload voice recording'**
  String get voiceUploadFailed;

  /// No description provided for @voiceUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get voiceUploading;

  /// No description provided for @vsLabel.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vsLabel;

  /// No description provided for @waitingAccessDateBasic.
  ///
  /// In en, this message translates to:
  /// **'Your access will begin on April 14th, 2026'**
  String get waitingAccessDateBasic;

  /// No description provided for @waitingAccessDatePremium.
  ///
  /// In en, this message translates to:
  /// **'As a {tier} member, you get early access before April 14th, 2026!'**
  String waitingAccessDatePremium(String tier);

  /// No description provided for @waitingAccessDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Access Date'**
  String get waitingAccessDateTitle;

  /// No description provided for @waitingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String waitingCountLabel(String count);

  /// No description provided for @waitingCountdownLabel.
  ///
  /// In en, this message translates to:
  /// **'App Launch Countdown'**
  String get waitingCountdownLabel;

  /// No description provided for @waitingCountdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for registering! GreenGo Chat is launching soon. Get ready for an exclusive experience.'**
  String get waitingCountdownSubtitle;

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

  /// No description provided for @waitingEarlyAccessMember.
  ///
  /// In en, this message translates to:
  /// **'Early Access Member'**
  String get waitingEarlyAccessMember;

  /// No description provided for @waitingEnableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to be the first to know when you can access the app.'**
  String get waitingEnableNotificationsSubtitle;

  /// No description provided for @waitingEnableNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Updated'**
  String get waitingEnableNotificationsTitle;

  /// No description provided for @waitingExclusiveAccess.
  ///
  /// In en, this message translates to:
  /// **'Your exclusive access date'**
  String get waitingExclusiveAccess;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players...'**
  String get waitingForPlayers;

  /// No description provided for @waitingForVerification.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification...'**
  String get waitingForVerification;

  /// No description provided for @waitingHoursRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String waitingHoursRemaining(int hours);

  /// No description provided for @waitingMessageApproved.
  ///
  /// In en, this message translates to:
  /// **'Great news! Your account has been approved. You will be able to access GreenGoChat on the date shown below.'**
  String get waitingMessageApproved;

  /// No description provided for @waitingMessagePending.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending approval from our team. We will notify you once your account has been reviewed.'**
  String get waitingMessagePending;

  /// No description provided for @waitingMessageRejected.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your account could not be approved at this time. Please contact support for more information.'**
  String get waitingMessageRejected;

  /// No description provided for @waitingMinutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String waitingMinutesRemaining(int minutes);

  /// No description provided for @waitingNotificationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled - we\'ll let you know when you can access the app!'**
  String get waitingNotificationEnabled;

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

  /// No description provided for @waitingSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String waitingSecondsRemaining(int seconds);

  /// No description provided for @waitingStayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned! We\'ll notify you when it\'s time to start connecting.'**
  String get waitingStayTuned;

  /// No description provided for @waitingStepActivation.
  ///
  /// In en, this message translates to:
  /// **'Account Activation'**
  String get waitingStepActivation;

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

  /// No description provided for @waitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully'**
  String get waitingSubtitle;

  /// No description provided for @waitingThankYouRegistration.
  ///
  /// In en, this message translates to:
  /// **'Thank you for registering!'**
  String get waitingThankYouRegistration;

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank You for Registering!'**
  String get waitingTitle;

  /// No description provided for @weeklyChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Challenges'**
  String get weeklyChallengesTitle;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GreenGoChat'**
  String get welcome;

  /// No description provided for @wordAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Word already used'**
  String get wordAlreadyUsed;

  /// No description provided for @wordReported.
  ///
  /// In en, this message translates to:
  /// **'Word reported'**
  String get wordReported;

  /// No description provided for @xTwitter.
  ///
  /// In en, this message translates to:
  /// **'X (Twitter)'**
  String get xTwitter;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @xpAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} XP'**
  String xpAmountLabel(String amount);

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'{amount} XP earned'**
  String xpEarned(String amount);

  /// No description provided for @xpLabel.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xpLabel;

  /// No description provided for @xpProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} XP'**
  String xpProgressLabel(String current, String max);

  /// No description provided for @xpRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpRewardLabel(String xp);

  /// No description provided for @yearlyMembership.
  ///
  /// In en, this message translates to:
  /// **'Yearly Membership'**
  String get yearlyMembership;

  /// No description provided for @yearsLabel.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String yearsLabel(int age);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @youAndMatched.
  ///
  /// In en, this message translates to:
  /// **'You and {name} want to exchange languages'**
  String youAndMatched(String name);

  /// No description provided for @youGotSuperLike.
  ///
  /// In en, this message translates to:
  /// **'You got a Priority Connect!'**
  String get youGotSuperLike;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get youLabel;

  /// No description provided for @youLose.
  ///
  /// In en, this message translates to:
  /// **'You Lose'**
  String get youLose;

  /// No description provided for @youMatchedWithOnDate.
  ///
  /// In en, this message translates to:
  /// **'You matched with {name} on {date}'**
  String youMatchedWithOnDate(String name, String date);

  /// No description provided for @youWin.
  ///
  /// In en, this message translates to:
  /// **'You Win!'**
  String get youWin;

  /// No description provided for @yourLanguages.
  ///
  /// In en, this message translates to:
  /// **'Your Languages'**
  String get yourLanguages;

  /// No description provided for @yourRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRankLabel;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your Turn!'**
  String get yourTurn;

  /// No description provided for @achievementBadges.
  ///
  /// In en, this message translates to:
  /// **'Achievement Badges'**
  String get achievementBadges;

  /// No description provided for @achievementBadgesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to select which badges to display on your profile (max 5)'**
  String get achievementBadgesSubtitle;

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'Unlock achievements to earn badges!'**
  String get noBadgesYet;
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
