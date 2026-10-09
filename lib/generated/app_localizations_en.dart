// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get culturalPassportTitle => 'Cultural Passport';

  @override
  String get culturalPassportSubtitle =>
      'Stamps you collect from the cultures, languages and events you explore';

  @override
  String get passportSectionCountries => 'Countries';

  @override
  String get passportSectionLanguages => 'Languages';

  @override
  String get passportSectionEvents => 'Events';

  @override
  String get passportLoading => 'Loading your passport…';

  @override
  String get passportEarned => 'Earned';

  @override
  String get passportLocked => 'Locked';

  @override
  String get passportEmpty =>
      'Start chatting, learning languages and joining events to earn your first stamps.';

  @override
  String passportProgressSummary(int countries, int languages, int events) {
    return '$countries countries · $languages languages · $events events';
  }

  @override
  String passportOverallProgress(int percent) {
    return '$percent% explored';
  }

  @override
  String get passportEventDating => 'Dating';

  @override
  String get passportEventSocial => 'Social';

  @override
  String get passportEventSports => 'Sports';

  @override
  String get passportEventFood => 'Food';

  @override
  String get passportEventNightlife => 'Nightlife';

  @override
  String get passportEventOutdoor => 'Outdoor';

  @override
  String get passportEventArts => 'Arts';

  @override
  String get passportEventGaming => 'Gaming';

  @override
  String get passportEventTravel => 'Travel';

  @override
  String get passportEventWellness => 'Wellness';

  @override
  String get passportEventLanguageExchange => 'Language Exchange';

  @override
  String get passportEventOther => 'Other';

  @override
  String get tourGotIt => 'Got it';

  @override
  String get tourWelcomeTitle => 'Welcome to GreenGo!';

  @override
  String get tourWelcomeDesc =>
      'This is your Discovery grid — real people around you, sorted by distance. Let\'s learn the gestures that make GreenGo quick to use.';

  @override
  String get tourCardTapTitle => 'Tap a card';

  @override
  String get tourCardTapDesc =>
      'Tap the center of a card to open the action menu — like, super-like, or view their full profile.';

  @override
  String get tourCardEdgeTitle => 'Browse photos';

  @override
  String get tourCardEdgeDesc =>
      'Tap the left or right edge of a card to flip through that person\'s photos without leaving the grid.';

  @override
  String get tourCardHoldTitle => 'Hold to preview';

  @override
  String get tourCardHoldDesc =>
      'Press and hold a card to preview photos full-screen.';

  @override
  String get tourRefreshTitle => 'Pull to refresh';

  @override
  String get tourRefreshDesc =>
      'Drag the grid down at any time to load the newest people around you.';

  @override
  String get tourModeToggleTitle => 'Swipe mode';

  @override
  String get tourModeToggleDesc =>
      'Tap here to switch between grid and swipe mode. In swipe mode: swipe right to like, left to pass, up to super-like.';

  @override
  String get tourGlobeTitle => 'Explore the globe';

  @override
  String get tourGlobeDesc =>
      'Open the 3D globe to discover people all around the world — not just nearby.';

  @override
  String get tourSearchTitle => 'Find by nickname';

  @override
  String get tourSearchDesc =>
      'Know who you\'re looking for? Search people directly by their nickname.';

  @override
  String get tourPrefsTitle => 'Discovery filters';

  @override
  String get tourPrefsDesc =>
      'Fine-tune who you discover: distance, age, languages, country and more.';

  @override
  String get tourCoinsTitle => 'Your coins';

  @override
  String get tourCoinsDesc =>
      'You receive free coins every day. Tap your balance anytime to open the Shop.';

  @override
  String get tourHelpTitle => 'Need a reminder?';

  @override
  String get tourHelpDesc =>
      'The app guide lives here — including this tutorial, which you can replay anytime.';

  @override
  String get tourNavMessagesTitle => 'Messages';

  @override
  String get tourNavMessagesDesc =>
      'Chat without language barriers — hold any message to translate it, double-tap to hear it spoken.';

  @override
  String get tourNavLeaderboardTitle => 'Leaderboard';

  @override
  String get tourNavLeaderboardDesc =>
      'Earn XP and badges as you connect, chat and learn. See how you rank.';

  @override
  String get tourNavShopTitle => 'Shop';

  @override
  String get tourNavShopDesc =>
      'Coin packages and memberships to unlock more of GreenGo.';

  @override
  String get tourNavProfileTitle => 'Your profile';

  @override
  String get tourNavProfileDesc =>
      'Complete your profile and verification to get discovered by more people.';

  @override
  String get tourFinishTitle => 'You\'re all set!';

  @override
  String get tourFinishDesc =>
      'Enjoy discovering new people and cultures. You can replay this tutorial anytime from the guide (? icon).';

  @override
  String get tourSwipeHintTitle => 'Swipe to connect';

  @override
  String get tourSwipeHintLike => 'Like';

  @override
  String get tourSwipeHintPass => 'Pass';

  @override
  String get tourSwipeHintSuper => 'Super Like';

  @override
  String get tourChatHoldTitle => 'Hold a message';

  @override
  String get tourChatHoldDesc =>
      'Press and hold any message to translate, copy or forward it.';

  @override
  String get tourChatDoubleTapTitle => 'Hear it spoken';

  @override
  String get tourChatDoubleTapDesc =>
      'Double-tap a received message to hear its pronunciation.';

  @override
  String get tourChatLanguageTitle => 'Languages & learning';

  @override
  String get tourChatLanguageDesc =>
      'Open the translate menu for language tools: translation settings, pronunciation practice and learning features.';

  @override
  String get tourChatSettingsTitle => 'Chat options';

  @override
  String get tourChatSettingsDesc =>
      'Manage this conversation: chat settings, delete, block or report.';

  @override
  String get tourDetailDoubleTapTitle => 'Like a photo';

  @override
  String get tourDetailDoubleTapDesc => 'Double-tap any photo to like it.';

  @override
  String get tourStoryHoldHint => 'Hold to pause';

  @override
  String get guideReplayTour => 'Replay tutorial';

  @override
  String get abandonGame => 'Abandon Game';

  @override
  String get about => 'About';

  @override
  String get aboutMe => 'About Me';

  @override
  String get aboutMeTitle => 'About Me';

  @override
  String get academicCategory => 'Academic';

  @override
  String get acceptPrivacyPolicy => 'I have read and accept the Privacy Policy';

  @override
  String get acceptProfiling =>
      'I consent to profiling for personalized recommendations';

  @override
  String get acceptTermsAndConditions =>
      'I have read and accept the Terms and Conditions';

  @override
  String get acceptThirdPartyData =>
      'I consent to sharing my data with third parties';

  @override
  String get accessGranted => 'Access Granted!';

  @override
  String accessGrantedBody(Object tierName) {
    return 'GreenGo is now live! As a $tierName, you now have full access to all features.';
  }

  @override
  String get accountApproved => 'Account Approved';

  @override
  String get accountApprovedBody =>
      'Your GreenGo account has been approved. Welcome to the community!';

  @override
  String get accountCreatedSuccess =>
      'Account created! Please check your email to verify your account.';

  @override
  String get accountPendingApproval => 'Account Pending Approval';

  @override
  String get accountRejected => 'Account Rejected';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get accountUnderReview => 'Account Under Review';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String get achievementsSubtitle => 'View your badges and progress';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get addBio => 'Add a bio';

  @override
  String get addDealBreakerTitle => 'Add Deal Breaker';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get adjustPreferences => 'Adjust Preferences';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Code sent to $email';
  }

  @override
  String get admin2faExpired => 'Code expired. Please request a new one.';

  @override
  String get admin2faInvalidCode => 'Invalid verification code';

  @override
  String get admin2faMaxAttempts =>
      'Too many attempts. Please request a new code.';

  @override
  String get admin2faResend => 'Resend Code';

  @override
  String admin2faResendIn(String seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get admin2faSending => 'Sending code...';

  @override
  String get admin2faSignOut => 'Sign Out';

  @override
  String get admin2faSubtitle => 'Enter the 6-digit code sent to your email';

  @override
  String get admin2faTitle => 'Admin Verification';

  @override
  String get admin2faVerify => 'Verify';

  @override
  String get adminAccessDates => 'Access Dates:';

  @override
  String get adminAccountLockedSuccessfully => 'Account locked successfully';

  @override
  String get adminAccountUnlockedSuccessfully =>
      'Account unlocked successfully';

  @override
  String get adminAccountsCannotBeDeleted => 'Admin accounts cannot be deleted';

  @override
  String adminAchievementCount(Object count) {
    return '$count achievements';
  }

  @override
  String get adminAchievementUpdated => 'Achievement updated';

  @override
  String get adminAchievements => 'Achievements';

  @override
  String get adminAchievementsSubtitle => 'Manage achievements and badges';

  @override
  String get adminActive => 'ACTIVE';

  @override
  String adminActiveCount(Object count) {
    return 'Active ($count)';
  }

  @override
  String get adminActiveEvent => 'Active Event';

  @override
  String get adminActiveUsers => 'Active Users';

  @override
  String get adminAdd => 'Add';

  @override
  String get adminAddCoins => 'Add Coins';

  @override
  String get adminAddPackage => 'Add Package';

  @override
  String get adminAddResolutionNote => 'Add a resolution note...';

  @override
  String get adminAddSingleEmail => 'Add Single Email';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return 'Added $amount coins to user';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Added $date';
  }

  @override
  String get adminAdvancedFilters => 'Advanced Filters';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age years old - $gender';
  }

  @override
  String get adminAll => 'All';

  @override
  String get adminAllReports => 'All Reports';

  @override
  String get adminAmount => 'Amount';

  @override
  String get adminAnalyticsAndReports => 'Analytics & Reports';

  @override
  String get adminAppSettings => 'App Settings';

  @override
  String get adminAppSettingsSubtitle => 'General application settings';

  @override
  String get adminApproveSelected => 'Approve Selected';

  @override
  String get adminAssignToMe => 'Assign to me';

  @override
  String get adminAssigned => 'Assigned';

  @override
  String get adminAvailable => 'Available';

  @override
  String get adminBadge => 'Badge';

  @override
  String get adminBaseCoins => 'Base Coins';

  @override
  String get adminBaseXp => 'Base XP';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount bonus coins';
  }

  @override
  String get adminBonusCoinsLabel => 'Bonus Coins';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes bonus';
  }

  @override
  String get adminBrowseProfilesAnonymously => 'Browse profiles anonymously';

  @override
  String get adminCanSendMedia => 'Can Send Media';

  @override
  String adminChallengeCount(Object count) {
    return '$count challenges';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'Challenge creation interface coming soon.';

  @override
  String get adminChallenges => 'Challenges';

  @override
  String get adminChangesSaved => 'Changes saved';

  @override
  String get adminChatWithReporter => 'Chat with Reporter';

  @override
  String get adminClear => 'Clear';

  @override
  String get adminClosed => 'Closed';

  @override
  String get adminCoinAmount => 'Coin Amount';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount Coins';
  }

  @override
  String get adminCoinCost => 'Coin Cost';

  @override
  String get adminCoinManagement => 'Coin Management';

  @override
  String get adminCoinManagementSubtitle =>
      'Manage coin packages and user balances';

  @override
  String get adminCoinPackages => 'Coin Packages';

  @override
  String get adminCoinReward => 'Coin Reward';

  @override
  String adminComingSoon(Object route) {
    return '$route coming soon';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Configurations reset to defaults. Save to apply.';

  @override
  String get adminConfigureLimitsAndFeatures => 'Configure limits and features';

  @override
  String get adminConfigureMilestoneRewards =>
      'Configure milestone rewards for consecutive logins';

  @override
  String get adminCreateChallenge => 'Create Challenge';

  @override
  String get adminCreateEvent => 'Create Event';

  @override
  String get adminCreateNewChallenge => 'Create New Challenge';

  @override
  String get adminCreateSeasonalEvent => 'Create Seasonal Event';

  @override
  String get adminCsvFormat => 'CSV Format:';

  @override
  String get adminCsvFormatDescription =>
      'One email per line, or comma-separated values. Quotes are automatically removed. Invalid emails are skipped.';

  @override
  String get adminCurrentBalance => 'Current Balance';

  @override
  String get adminDailyChallenges => 'Daily Challenges';

  @override
  String get adminDailyChallengesSubtitle =>
      'Configure daily challenges and rewards';

  @override
  String get adminDailyLimits => 'Daily Limits';

  @override
  String get adminDailyLoginRewards => 'Daily Login Rewards';

  @override
  String get adminDailyMessages => 'Daily Messages';

  @override
  String get adminDailySuperLikes => 'Daily Priority Connects';

  @override
  String get adminDailySwipes => 'Daily Swipes';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get adminDate => 'Date';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return 'Are you sure you want to delete \"$amount Coins\" package?';
  }

  @override
  String get adminDeletePackageTitle => 'Delete Package?';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminDeselectAll => 'Deselect all';

  @override
  String get adminDisabled => 'Disabled';

  @override
  String get adminDismiss => 'Dismiss';

  @override
  String get adminDismissReport => 'Dismiss Report';

  @override
  String get adminDismissReportConfirm =>
      'Are you sure you want to dismiss this report?';

  @override
  String get adminEarlyAccessDate => 'March 14, 2026';

  @override
  String get adminEarlyAccessDates =>
      'Users in this list get access on March 14, 2026.\nAll other users get access on April 14, 2026.';

  @override
  String get adminEarlyAccessInList => 'Early Access (in list)';

  @override
  String get adminEarlyAccessInfo => 'Early Access Info';

  @override
  String get adminEarlyAccessList => 'Early Access List';

  @override
  String get adminEarlyAccessProgram => 'Early Access Program';

  @override
  String get adminEditAchievement => 'Edit Achievement';

  @override
  String adminEditItem(Object name) {
    return 'Edit $name';
  }

  @override
  String adminEditMilestone(Object name) {
    return 'Edit $name';
  }

  @override
  String get adminEditPackage => 'Edit Package';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email added to early access list';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count emails';
  }

  @override
  String get adminEmailList => 'Email List';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email removed from early access list';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Enable advanced filtering options';

  @override
  String get adminEngagementReports => 'Engagement Reports';

  @override
  String get adminEngagementReportsSubtitle =>
      'View matching and messaging statistics';

  @override
  String get adminEnterEmailAddress => 'Enter email address';

  @override
  String get adminEnterValidAmount => 'Please enter a valid amount';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Please enter valid coin amount and price';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Error adding email: $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Error loading context: $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Error loading data: $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Error opening chat: $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Error removing email: $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Error: $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Error uploading file: $error';
  }

  @override
  String get adminErrors => 'Errors:';

  @override
  String get adminEventCreationComingSoon =>
      'Event creation interface coming soon.';

  @override
  String get adminEvents => 'Events';

  @override
  String adminFailedToSave(Object error) {
    return 'Failed to save: $error';
  }

  @override
  String get adminFeatures => 'Features';

  @override
  String get adminFilterByInterests => 'Filter by interests';

  @override
  String get adminFilterBySpecificLocation => 'Filter by specific location';

  @override
  String get adminFilterBySpokenLanguages => 'Filter by spoken languages';

  @override
  String get adminFilterByVerificationStatus => 'Filter by verification status';

  @override
  String get adminFilterOptions => 'Filter Options';

  @override
  String get adminGamification => 'Gamification';

  @override
  String get adminGamificationAndRewards => 'Gamification & Rewards';

  @override
  String get adminGeneralAccess => 'General Access';

  @override
  String get adminGeneralAccessDate => 'April 14, 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Higher priority = shown first in discovery';

  @override
  String get adminImportResult => 'Import Result';

  @override
  String get adminInProgress => 'In Progress';

  @override
  String get adminIncognitoMode => 'Incognito Mode';

  @override
  String get adminInterestFilter => 'Interest Filter';

  @override
  String get adminInvoices => 'Invoices';

  @override
  String get adminLanguageFilter => 'Language Filter';

  @override
  String get adminLoading => 'Loading...';

  @override
  String get adminLocationFilter => 'Location Filter';

  @override
  String get adminLockAccount => 'Lock Account';

  @override
  String adminLockAccountConfirm(Object userId) {
    return 'Lock account for user $userId...?';
  }

  @override
  String get adminLockDuration => 'Lock Duration';

  @override
  String adminLockReasonLabel(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String adminLockedCount(Object count) {
    return 'Locked ($count)';
  }

  @override
  String adminLockedDate(Object date) {
    return 'Locked: $date';
  }

  @override
  String get adminLoginStreakSystem => 'Login Streak System';

  @override
  String get adminLoginStreaks => 'Login Streaks';

  @override
  String get adminLoginStreaksSubtitle =>
      'Configure streak milestones and rewards';

  @override
  String get adminManageAppSettings =>
      'Manage your GreenGo application settings';

  @override
  String get adminMatchPriority => 'Match Priority';

  @override
  String get adminMatchingAndVisibility => 'Matching & Visibility';

  @override
  String get adminMessageContext => 'Message Context (50 before/after)';

  @override
  String get adminMilestoneUpdated => 'Milestone updated';

  @override
  String adminMoreErrors(Object count) {
    return '... and $count more errors';
  }

  @override
  String get adminName => 'Name';

  @override
  String get adminNinetyDays => '90 days';

  @override
  String get adminNoEmailsInEarlyAccessList => 'No emails in early access list';

  @override
  String get adminNoInvoicesFound => 'No invoices found';

  @override
  String get adminNoLockedAccounts => 'No locked accounts';

  @override
  String get adminNoMatchingEmailsFound => 'No matching emails found';

  @override
  String get adminNoOrdersFound => 'No orders found';

  @override
  String get adminNoPendingReports => 'No pending reports';

  @override
  String get adminNoReportsYet => 'No reports yet';

  @override
  String adminNoTickets(Object status) {
    return 'No $status tickets';
  }

  @override
  String get adminNoValidEmailsFound =>
      'No valid email addresses found in the file';

  @override
  String get adminNoVerificationHistory => 'No verification history';

  @override
  String get adminOneDay => '1 day';

  @override
  String get adminOpen => 'Open';

  @override
  String adminOpenCount(Object count) {
    return 'Open ($count)';
  }

  @override
  String get adminOpenTickets => 'Open Tickets';

  @override
  String get adminOrderDetails => 'Order Details';

  @override
  String get adminOrderId => 'Order ID';

  @override
  String get adminOrderRefunded => 'Order refunded';

  @override
  String get adminOrders => 'Orders';

  @override
  String get adminPackages => 'Packages';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminPayment => 'Payment';

  @override
  String get adminPending => 'Pending';

  @override
  String adminPendingCount(Object count) {
    return 'Pending ($count)';
  }

  @override
  String get adminPermanent => 'Permanent';

  @override
  String get adminPleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get adminPriceUsd => 'Price (USD)';

  @override
  String get adminProductIdIap => 'Product ID (for IAP)';

  @override
  String get adminProfileVisitors => 'Profile Visitors';

  @override
  String get adminPromotional => 'Promotional';

  @override
  String get adminPromotionalPackage => 'Promotional Package';

  @override
  String get adminPromotions => 'Promotions';

  @override
  String get adminPromotionsSubtitle => 'Manage special offers and promotions';

  @override
  String get adminProvideReason => 'Please provide a reason';

  @override
  String get adminReadReceipts => 'Read Receipts';

  @override
  String get adminReason => 'Reason';

  @override
  String adminReasonLabel(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String get adminReasonRequired => 'Reason (required)';

  @override
  String get adminRefund => 'Refund';

  @override
  String get adminRemove => 'Remove';

  @override
  String get adminRemoveCoins => 'Remove Coins';

  @override
  String get adminRemoveEmail => 'Remove Email';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return 'Are you sure you want to remove \"$email\" from the early access list?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return 'Removed $amount coins from user';
  }

  @override
  String get adminReportDismissed => 'Report dismissed';

  @override
  String get adminReportFollowupStarted =>
      'Report Follow-up conversation started';

  @override
  String get adminReportedMessage => 'Reported Message:';

  @override
  String get adminReportedMessageMarker => '^ REPORTED MESSAGE';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'Reported User ID: $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'Reporter ID: $reporterId...';
  }

  @override
  String get adminReports => 'Reports';

  @override
  String get adminReportsManagement => 'Reports Management';

  @override
  String get adminRequestNewPhoto => 'Request New Photo';

  @override
  String get adminRequiredCount => 'Required Count';

  @override
  String adminRequiresCount(Object count) {
    return 'Requires: $count';
  }

  @override
  String get adminReset => 'Reset';

  @override
  String get adminResetToDefaults => 'Reset to Defaults';

  @override
  String get adminResetToDefaultsConfirm =>
      'This will reset all tier configurations to their default values. This action cannot be undone.';

  @override
  String get adminResetToDefaultsTitle => 'Reset to Defaults?';

  @override
  String get adminResolutionNote => 'Resolution Note';

  @override
  String get adminResolve => 'Resolve';

  @override
  String get adminResolved => 'Resolved';

  @override
  String adminResolvedCount(Object count) {
    return 'Resolved ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Revenue Analytics';

  @override
  String get adminRevenueAnalyticsSubtitle => 'Track purchases and revenue';

  @override
  String get adminReviewedBy => 'Reviewed By';

  @override
  String get adminRewardAmount => 'Reward Amount';

  @override
  String get adminSaving => 'Saving...';

  @override
  String get adminScheduledEvents => 'Scheduled Events';

  @override
  String get adminSearchByUserIdOrEmail => 'Search by user ID or email';

  @override
  String get adminSearchEmails => 'Search emails...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Search for a user to manage their coin balance';

  @override
  String get adminSearchOrders => 'Search orders...';

  @override
  String get adminSeeWhenMessagesAreRead => 'See when messages are read';

  @override
  String get adminSeeWhoVisitedProfile => 'See who visited their profile';

  @override
  String get adminSelectAll => 'Select all';

  @override
  String get adminSelectCsvFile => 'Select CSV File';

  @override
  String adminSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get adminSendImagesAndVideosInChat => 'Send images and videos in chat';

  @override
  String get adminSevenDays => '7 days';

  @override
  String get adminSpendItems => 'Spend Items';

  @override
  String get adminStatistics => 'Statistics';

  @override
  String get adminStatus => 'Status';

  @override
  String get adminStreakMilestones => 'Streak Milestones';

  @override
  String get adminStreakMultiplier => 'Streak Multiplier';

  @override
  String get adminStreakMultiplierValue => '1.5x per day';

  @override
  String get adminStreaks => 'Streaks';

  @override
  String get adminSupport => 'Support';

  @override
  String get adminSupportAgents => 'Support Agents';

  @override
  String get adminSupportAgentsSubtitle => 'Manage support agent accounts';

  @override
  String get adminSupportManagement => 'Support Management';

  @override
  String get adminSupportRequest => 'Support Request';

  @override
  String get adminSupportTickets => 'Support Tickets';

  @override
  String get adminSupportTicketsSubtitle =>
      'View and manage user support conversations';

  @override
  String get adminSystemConfiguration => 'System Configuration';

  @override
  String get adminThirtyDays => '30 days';

  @override
  String get adminTicketAssignedToYou => 'Ticket assigned to you';

  @override
  String get adminTicketAssignment => 'Ticket Assignment';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Assign tickets to support agents';

  @override
  String get adminTicketClosed => 'Ticket closed';

  @override
  String get adminTicketResolved => 'Ticket resolved';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Tier configurations saved successfully';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Tier Management';

  @override
  String get adminTierManagementSubtitle =>
      'Configure tier limits and features';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Today';

  @override
  String get adminTotalMinutes => 'Total Minutes';

  @override
  String get adminType => 'Type';

  @override
  String get adminUnassigned => 'Unassigned';

  @override
  String get adminUnknown => 'Unknown';

  @override
  String get adminUnlimited => 'Unlimited';

  @override
  String get adminUnlock => 'Unlock';

  @override
  String get adminUnlockAccount => 'Unlock Account';

  @override
  String get adminUnlockAccountConfirm =>
      'Are you sure you want to unlock this account?';

  @override
  String get adminUnresolved => 'Unresolved';

  @override
  String get adminUploadCsvDescription =>
      'Upload a CSV file containing email addresses (one per line or comma-separated)';

  @override
  String get adminUploadCsvFile => 'Upload CSV File';

  @override
  String get adminUploading => 'Uploading...';

  @override
  String get adminUsedMinutes => 'Used Minutes';

  @override
  String get adminUser => 'User';

  @override
  String get adminUserAnalytics => 'User Analytics';

  @override
  String get adminUserAnalyticsSubtitle =>
      'View user engagement and growth metrics';

  @override
  String get adminUserBalance => 'User Balance';

  @override
  String get adminUserId => 'User ID';

  @override
  String adminUserIdLabel(Object userId) {
    return 'User ID: $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'User: $userId...';
  }

  @override
  String get adminUserManagement => 'User Management';

  @override
  String get adminUserModeration => 'User Moderation';

  @override
  String get adminUserModerationSubtitle => 'Manage user bans and suspensions';

  @override
  String get adminUserReports => 'User Reports';

  @override
  String get adminUserReportsSubtitle => 'Review and handle user reports';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'User: $senderId...';
  }

  @override
  String get adminUserVerifications => 'User Verifications';

  @override
  String get adminUserVerificationsSubtitle =>
      'Approve or reject user verification requests';

  @override
  String get adminVerificationFilter => 'Verification Filter';

  @override
  String get adminVerifications => 'Verifications';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes Minutes';
  }

  @override
  String get adminViewContext => 'View Context';

  @override
  String get adminViewDocument => 'View Document';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Violation of community guidelines';

  @override
  String get adminWaiting => 'Waiting';

  @override
  String adminWaitingCount(Object count) {
    return 'Waiting ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Weekly Challenges';

  @override
  String get adminWelcome => 'Welcome, Admin';

  @override
  String get adminXpReward => 'XP Reward';

  @override
  String get ageRange => 'Age Range';

  @override
  String get aiCoachBenefitAllChapters => 'All learning chapters unlocked';

  @override
  String get aiCoachBenefitFeedback =>
      'Real-time grammar & pronunciation feedback';

  @override
  String get aiCoachBenefitPersonalized => 'Personalized learning path';

  @override
  String get aiCoachBenefitUnlimited => 'Unlimited AI conversation practice';

  @override
  String get aiCoachLabel => 'AI Coach';

  @override
  String get aiCoachTrialEnded => 'Your free trial of AI Coach has ended.';

  @override
  String get aiCoachUpgradePrompt =>
      'Upgrade to Silver, Gold, or Platinum to unlock.';

  @override
  String get aiCoachUpgradeTitle => 'Upgrade to Learn More';

  @override
  String get albumNotShared => 'Album not shared with you';

  @override
  String get albumOption => 'Album';

  @override
  String albumRevokedMessage(String username) {
    return '$username revoked album access';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username shared their album with you';
  }

  @override
  String get allCategoriesFilter => 'All';

  @override
  String get allDealBreakersAdded => 'All deal breakers have been added';

  @override
  String get allLanguagesFilter => 'All';

  @override
  String get allPlayersReady => 'All players ready!';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get appLanguage => 'App Language';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Discover Your Perfect Match';

  @override
  String get approveVerification => 'Approve';

  @override
  String get atLeast8Characters => 'At least 8 characters';

  @override
  String get atLeastOneNumber => 'At least one number';

  @override
  String get atLeastOneSpecialChar => 'At least one special character';

  @override
  String get authAppleSignInComingSoon => 'Apple Sign-In coming soon';

  @override
  String get authCancelVerification => 'Cancel Verification?';

  @override
  String get authCancelVerificationBody =>
      'You will be signed out if you cancel the verification.';

  @override
  String get authDisableInSettings =>
      'You can disable this in Settings > Security';

  @override
  String get authErrorEmailAlreadyInUse =>
      'An account already exists with this email.';

  @override
  String get authErrorGeneric => 'An error occurred. Please try again.';

  @override
  String get authErrorInvalidCredentials =>
      'Wrong email/nickname or password. Please check your credentials and try again.';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authErrorNetworkError =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorUserNotFound =>
      'No account found with this email or nickname. Please check and try again, or sign up.';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak. Please use a stronger password.';

  @override
  String get authErrorWrongPassword => 'Wrong password. Please try again.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'Failed to take photo: $error';
  }

  @override
  String get authIdentityVerification => 'Identity Verification';

  @override
  String get authPleaseEnterEmail => 'Please enter your email';

  @override
  String get authRetakePhoto => 'Retake Photo';

  @override
  String get authSecurityStep =>
      'This extra security step helps protect your account';

  @override
  String get authSelfieInstruction => 'Look at the camera and tap to capture';

  @override
  String get authSignOut => 'Sign Out';

  @override
  String get authSignOutInstead => 'Sign out instead';

  @override
  String get authStay => 'Stay';

  @override
  String get authTakeSelfie => 'Take a Selfie';

  @override
  String get authTakeSelfieToVerify =>
      'Please take a selfie to verify your identity';

  @override
  String get authVerifyAndContinue => 'Verify & Continue';

  @override
  String get authVerifyWithSelfie =>
      'Please verify your identity with a selfie';

  @override
  String authWelcomeBack(Object name) {
    return 'Welcome back, $name!';
  }

  @override
  String get authenticationErrorTitle => 'Login Failed';

  @override
  String get away => 'away';

  @override
  String get awesome => 'Awesome!';

  @override
  String get backToLobby => 'Back to Lobby';

  @override
  String get badgeLocked => 'Locked';

  @override
  String get badgeUnlocked => 'Unlocked';

  @override
  String get achievementUnlockedTitle => 'ACHIEVEMENT UNLOCKED!';

  @override
  String get achievementUnlockedAwesome => 'Awesome!';

  @override
  String get achievementRarityCommon => 'COMMON';

  @override
  String get achievementRarityUncommon => 'UNCOMMON';

  @override
  String get achievementRarityRare => 'RARE';

  @override
  String get achievementRarityEpic => 'EPIC';

  @override
  String get achievementRarityLegendary => 'LEGENDARY';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

  @override
  String get badges => 'Badges';

  @override
  String get basic => 'Basic';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get betterPhotoRequested => 'Better photo requested';

  @override
  String get bio => 'Bio';

  @override
  String get bioUpdatedMessage => 'Your profile bio has been saved';

  @override
  String get bioUpdatedTitle => 'Bio Updated!';

  @override
  String get blindDateActivate => 'Activate Blind Date Mode';

  @override
  String get blindDateDeactivate => 'Deactivate';

  @override
  String get blindDateDeactivateMessage =>
      'You\'ll return to normal discovery mode.';

  @override
  String get blindDateDeactivateTitle => 'Deactivate Blind Date Mode?';

  @override
  String get blindDateDeactivateTooltip => 'Deactivate Blind Date Mode';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Instant reveal for $cost coins';
  }

  @override
  String get blindDateFeatureNoPhotos => 'No profile photos visible initially';

  @override
  String get blindDateFeaturePersonality => 'Focus on personality & interests';

  @override
  String get blindDateFeatureUnlock => 'Photos unlock after chatting';

  @override
  String get blindDateGetCoins => 'Get Coins';

  @override
  String get blindDateInstantReveal => 'Instant Reveal';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return 'Reveal all photos of this match for $cost coins?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Instant reveal ($cost coins)';
  }

  @override
  String get blindDateInsufficientCoins => 'Insufficient Coins';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'You need $cost coins to instantly reveal photos.';
  }

  @override
  String get blindDateInterests => 'Interests';

  @override
  String blindDateKmAway(String distance) {
    return '$distance km away';
  }

  @override
  String get blindDateLetsExchange => 'Start Connecting!';

  @override
  String get blindDateMatchMessage =>
      'You both liked each other! Start chatting to reveal your photos.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total messages';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return '$count to go';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count messages until reveal';
  }

  @override
  String get blindDateModeActivated => 'Blind Date mode activated!';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Match based on personality, not looks.\nPhotos reveal after $threshold messages.';
  }

  @override
  String get blindDateModeTitle => 'Blind Date Mode';

  @override
  String get blindDateMysteryPerson => 'Mystery Person';

  @override
  String get blindDateNoCandidates => 'No candidates available';

  @override
  String get blindDateNoMatches => 'No matches yet';

  @override
  String blindDatePendingReveal(int count) {
    return 'Pending Reveal ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Photo Reveal Progress';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'Photos reveal after $threshold messages';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return 'Photos revealed! $coinsSpent coins spent.';
  }

  @override
  String get blindDatePhotosRevealedLabel => 'Photos revealed!';

  @override
  String get blindDateReveal => 'Reveal';

  @override
  String blindDateRevealed(int count) {
    return 'Revealed ($count)';
  }

  @override
  String get blindDateRevealedMatch => 'Revealed Match';

  @override
  String get blindDateStartSwiping => 'Start swiping to find your blind date!';

  @override
  String get blindDateTabDiscover => 'Discover';

  @override
  String get blindDateTabMatches => 'Matches';

  @override
  String get blindDateTitle => 'Blind Date';

  @override
  String get blindDateViewMatch => 'View Match';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonus bonus!)';
  }

  @override
  String get boost => 'Boost';

  @override
  String get boostActivated => 'Boost activated for 30 minutes!';

  @override
  String get boostNow => 'Boost Now';

  @override
  String get boostProfile => 'Boost Profile';

  @override
  String get boosted => 'BOOSTED!';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Bundle';

  @override
  String get businessCategory => 'Business';

  @override
  String get buyCoins => 'Buy Coins';

  @override
  String get buyCoinsBtnLabel => 'Buy Coins';

  @override
  String get buyPackBtn => 'Buy';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get cannotAccessFeature =>
      'This feature is available after your account is verified.';

  @override
  String get cantUndoMatched => 'Can\'t undo — you already matched!';

  @override
  String get casualCategory => 'Casual';

  @override
  String get casualDating => 'Casual dating';

  @override
  String get categoryFlashcard => 'Flashcard';

  @override
  String get categoryLearning => 'Learning';

  @override
  String get categoryMultilingual => 'Multilingual';

  @override
  String get categoryName => 'Category';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Seasonal';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryStreak => 'Streak';

  @override
  String get categoryTranslation => 'Translation';

  @override
  String get challenges => 'Challenges';

  @override
  String get changeLocation => 'Change location';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordConfirm => 'Confirm New Password';

  @override
  String get changePasswordCurrent => 'Current Password';

  @override
  String get changePasswordDescription =>
      'For security, please verify your identity before changing your password.';

  @override
  String get changePasswordEmailConfirm => 'Confirm your email address';

  @override
  String get changePasswordEmailHint => 'Your email';

  @override
  String get changePasswordEmailMismatch => 'Email does not match your account';

  @override
  String get changePasswordNew => 'New Password';

  @override
  String get changePasswordReauthRequired =>
      'Please log out and log in again before changing your password';

  @override
  String get changePasswordSubtitle => 'Update your account password';

  @override
  String get changePasswordSuccess => 'Password changed successfully';

  @override
  String get changePasswordWrongCurrent => 'Current password is incorrect';

  @override
  String get chatAddCaption => 'Add a caption...';

  @override
  String get chatAddToStarred => 'Add to starred messages';

  @override
  String get chatAlreadyInYourLanguage => 'Message is already in your language';

  @override
  String get chatAttachCamera => 'Camera';

  @override
  String get chatAttachGallery => 'Gallery';

  @override
  String get chatAttachRecord => 'Record';

  @override
  String get chatAttachVideo => 'Video';

  @override
  String get chatBlock => 'Block';

  @override
  String chatBlockUser(String name) {
    return 'Block $name';
  }

  @override
  String chatBlockUserMessage(String name) {
    return 'Are you sure you want to block $name? They will no longer be able to contact you.';
  }

  @override
  String get chatBlockUserTitle => 'Block User';

  @override
  String get chatCannotBlockAdmin => 'You cannot block an administrator.';

  @override
  String get chatCannotReportAdmin => 'You cannot report an administrator.';

  @override
  String get chatCategory => 'Category';

  @override
  String get chatCategoryAccount => 'Account Help';

  @override
  String get chatCategoryBilling => 'Billing & Payments';

  @override
  String get chatCategoryFeedback => 'Feedback';

  @override
  String get chatCategoryGeneral => 'General Question';

  @override
  String get chatCategorySafety => 'Safety Concern';

  @override
  String get chatCategoryTechnical => 'Technical Issue';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatCreate => 'Create';

  @override
  String get chatCreateSupportTicket => 'Create Support Ticket';

  @override
  String get chatCreateTicket => 'Create Ticket';

  @override
  String chatDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get chatDelete => 'Delete';

  @override
  String get chatDeleteChat => 'Delete Chat';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'This will delete all messages for both you and $name. This action cannot be undone.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Delete Chat for Everyone';

  @override
  String get chatDeleteChatForMeMessage =>
      'This will delete the chat from your device only. The other person will still see the messages.';

  @override
  String chatDeleteConversationWith(String name) {
    return 'Delete conversation with $name?';
  }

  @override
  String get chatDeleteForBoth => 'Delete chat for both';

  @override
  String get chatDeleteForBothDescription =>
      'This will permanently delete the conversation for both you and the other person.';

  @override
  String get chatDeleteForEveryone => 'Delete for Everyone';

  @override
  String get chatDeleteForMe => 'Delete chat for me';

  @override
  String get chatDeleteForMeDescription =>
      'This will delete the conversation from your chat list only. The other person will still see it.';

  @override
  String get chatDeletedForBothMessage =>
      'This chat has been permanently removed';

  @override
  String get chatDeletedForMeMessage =>
      'This chat has been removed from your inbox';

  @override
  String get chatDeletedTitle => 'Chat Deleted!';

  @override
  String get chatDescriptionOptional => 'Description (Optional)';

  @override
  String get chatDetailsHint => 'Provide more details about your issue...';

  @override
  String get chatDisableTranslation => 'Disable translation';

  @override
  String get chatEnableTranslation => 'Enable translation';

  @override
  String get chatErrorLoadingTickets => 'Error loading tickets';

  @override
  String get chatFailedToCreateTicket => 'Failed to create ticket';

  @override
  String get chatFailedToForwardMessage => 'Failed to forward message';

  @override
  String get chatFailedToLoadAlbum => 'Failed to load album';

  @override
  String get chatFailedToLoadConversations => 'Failed to load conversations';

  @override
  String get chatFailedToLoadImage => 'Failed to load image';

  @override
  String get chatFailedToLoadVideo => 'Failed to load video';

  @override
  String chatFailedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Failed to pick video: $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Failed to report message: $error';
  }

  @override
  String get chatFailedToRevokeAccess => 'Failed to revoke access';

  @override
  String get chatFailedToSaveFlashcard => 'Failed to save flashcard';

  @override
  String get chatFailedToShareAlbum => 'Failed to share album';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Failed to upload video: $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Cultural tips & context';

  @override
  String get chatFeatureGrammar => 'Real-time grammar feedback';

  @override
  String get chatFeatureVocabulary => 'Vocabulary building exercises';

  @override
  String get chatForward => 'Forward';

  @override
  String get chatForwardMessage => 'Forward Message';

  @override
  String get chatForwardToChat => 'Forward to another chat';

  @override
  String get chatGrammarSuggestion => 'Grammar Suggestion';

  @override
  String chatHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get chatIcebreakers => 'Icebreakers';

  @override
  String chatIsTyping(String userName) {
    return '$userName is typing';
  }

  @override
  String get chatJustNow => 'Just now';

  @override
  String get chatLanguagePickerHint =>
      'Choose the language you want to read this conversation in. All messages will be translated for you.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Chat language set to $language';
  }

  @override
  String get chatLanguages => 'Languages';

  @override
  String get chatLearnThis => 'Learn This';

  @override
  String get chatListen => 'Listen';

  @override
  String get chatLoadingVideo => 'Loading video...';

  @override
  String get chatMaybeLater => 'Maybe later';

  @override
  String get chatMediaLimitReached => 'Media Limit Reached';

  @override
  String get chatMessage => 'Message';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Message blocked: Contains $violations. For your safety, sharing personal contact details is not allowed.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Message forwarded to $count conversation(s)';
  }

  @override
  String get chatMessageOptions => 'Message Options';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageReported =>
      'Message reported. We will review it shortly.';

  @override
  String get chatMessageStarred => 'Message starred';

  @override
  String get chatMessageTranslated => 'Translated';

  @override
  String get chatMessageUnstarred => 'Message unstarred';

  @override
  String chatMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get chatMySupportTickets => 'My Support Tickets';

  @override
  String get chatNeedHelpCreateTicket => 'Need help? Create a new ticket.';

  @override
  String get chatNewTicket => 'New Ticket';

  @override
  String get chatNoConversationsToForward => 'No conversations to forward to';

  @override
  String get chatNoMatchingConversations => 'No matching conversations';

  @override
  String get chatNoMessagesToPractice => 'No messages to practice with yet';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatNoPrivatePhotos => 'No private photos available';

  @override
  String get chatNoSupportTickets => 'No Support Tickets';

  @override
  String get chatOffline => 'Offline';

  @override
  String get chatOnline => 'Online';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'Online ${days}d ago';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'Online ${hours}h ago';
  }

  @override
  String get chatOnlineJustNow => 'Online just now';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'Online ${minutes}m ago';
  }

  @override
  String get chatOptions => 'Chat Options';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name revoked album access';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name shared their private album';
  }

  @override
  String get chatPhoto => 'Photo';

  @override
  String get chatPhraseSaved => 'Phrase saved to your flashcard deck!';

  @override
  String get chatPleaseEnterSubject => 'Please enter a subject';

  @override
  String get chatPractice => 'Practice';

  @override
  String get chatPracticeMode => 'Practice Mode';

  @override
  String get chatPracticeTrialStarted =>
      'Practice mode trial started! You have 3 free sessions.';

  @override
  String get chatPreviewImage => 'Preview Image';

  @override
  String get chatPreviewVideo => 'Preview Video';

  @override
  String get chatPronunciationChallenge => 'Pronunciation Challenge';

  @override
  String get chatPronunciationHint =>
      'Tap to hear, then practice saying each phrase:';

  @override
  String get chatRemoveFromStarred => 'Remove from starred messages';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatReplyToMessage => 'Reply to this message';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatReportInappropriate => 'Report inappropriate content';

  @override
  String get chatReportMessage => 'Report Message';

  @override
  String get chatReportReasonFakeProfile => 'Fake profile / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Harassment or bullying';

  @override
  String get chatReportReasonInappropriate => 'Inappropriate content';

  @override
  String get chatReportReasonOther => 'Other';

  @override
  String get chatReportReasonPersonalInfo => 'Sharing personal information';

  @override
  String get chatReportReasonSpam => 'Spam or scam';

  @override
  String get chatReportReasonThreatening => 'Threatening behavior';

  @override
  String get chatReportReasonUnderage => 'Underage user';

  @override
  String chatReportUser(String name) {
    return 'Report $name';
  }

  @override
  String get chatReportUserTitle => 'Report User';

  @override
  String chatSeeExchangeDetails(String name) {
    return 'See Exchange Details with $name';
  }

  @override
  String get chatSafetyGotIt => 'Got It';

  @override
  String get chatSafetySubtitle =>
      'Your safety is our priority. Please keep these tips in mind.';

  @override
  String get chatSafetyTip => 'Safety Tip';

  @override
  String get chatSafetyTip1Description =>
      'Don\'t share your address, phone number, or financial information.';

  @override
  String get chatSafetyTip1Title => 'Keep Personal Info Private';

  @override
  String get chatSafetyTip2Description =>
      'Never send money to someone you haven\'t met in person.';

  @override
  String get chatSafetyTip2Title => 'Beware of Money Requests';

  @override
  String get chatSafetyTip3Description =>
      'For first meetings, always choose a public, well-lit location.';

  @override
  String get chatSafetyTip3Title => 'Meet in Public Places';

  @override
  String get chatSafetyTip4Description =>
      'If something feels wrong, trust your gut and end the conversation.';

  @override
  String get chatSafetyTip4Title => 'Trust Your Instincts';

  @override
  String get chatSafetyTip5Description =>
      'Use the report feature if someone makes you uncomfortable.';

  @override
  String get chatSafetyTip5Title => 'Report Suspicious Behavior';

  @override
  String get chatSafetyTitle => 'Stay Safe While Chatting';

  @override
  String get chatSaving => 'Saving...';

  @override
  String chatSayHiTo(String name) {
    return 'Say hi to $name!';
  }

  @override
  String get chatScrollUpForOlder => 'Scroll up for older messages';

  @override
  String get chatSearchByNameOrNickname => 'Search by name or @nickname';

  @override
  String get chatSearchConversationsHint => 'Search conversations...';

  @override
  String get chatSelectPhotos => 'Select photos to send';

  @override
  String get chatSend => 'Send';

  @override
  String get chatSendAnyway => 'Send Anyway';

  @override
  String get chatSendAttachment => 'Send Attachment';

  @override
  String chatSendCount(int count) {
    return 'Send ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Send a message to start the conversation';

  @override
  String get chatSendMessagesForTips =>
      'Send messages to get language learning tips!';

  @override
  String get chatSetNativeLanguage =>
      'Set your native language in settings first';

  @override
  String get chatSettingCulturalTips => 'Cultural Tips';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Show cultural context for idioms and expressions';

  @override
  String get chatSettingDifficultyBadges => 'Difficulty Badges';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'Show CEFR level (A1-C2) on messages';

  @override
  String get chatSettingGrammarCheck => 'Grammar Check';

  @override
  String get chatSettingGrammarCheckDesc =>
      'Check grammar before sending messages';

  @override
  String get chatSettingLanguageFlags => 'Language Flags';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Show flag emoji next to translated and original text';

  @override
  String get chatSettingPhraseOfDay => 'Phrase of the Day';

  @override
  String get chatSettingPhraseOfDayDesc => 'Show a daily phrase to practice';

  @override
  String get chatSettingPronunciation => 'Pronunciation (TTS)';

  @override
  String get chatSettingPronunciationDesc =>
      'Double-tap messages to hear pronunciation';

  @override
  String get chatSettingShowOriginal => 'Show Original Text';

  @override
  String get chatSettingShowOriginalDesc =>
      'Display the original message below translation';

  @override
  String get chatSettingSmartReplies => 'Smart Replies';

  @override
  String get chatSettingSmartRepliesDesc =>
      'Suggest replies in the target language';

  @override
  String get chatSettingTtsTranslation => 'TTS Reads Translation';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Read the translated text instead of original';

  @override
  String get chatSettingWordBreakdown => 'Word Breakdown';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Tap messages for word-by-word translation';

  @override
  String get chatSettingXpBar => 'XP & Streak Bar';

  @override
  String get chatSettingXpBarDesc => 'Show session XP and word count progress';

  @override
  String get chatSettingsSaveAllChats => 'Save settings for all chats';

  @override
  String get chatSettingsSaveThisChat => 'Save settings to this chat';

  @override
  String get chatSettingsSavedAllChats => 'Settings saved for all chats';

  @override
  String get chatSettingsSavedThisChat => 'Settings saved for this chat';

  @override
  String get chatSettingsSubtitle =>
      'Customise your learning experience in this chat';

  @override
  String get chatSettingsTitle => 'Chat Settings';

  @override
  String get chatSomeone => 'Someone';

  @override
  String get chatStarMessage => 'Star Message';

  @override
  String get chatStartSwipingToChat =>
      'Start swiping and matching to chat with people!';

  @override
  String get chatStatusAssigned => 'Assigned';

  @override
  String get chatStatusAwaitingReply => 'Awaiting Reply';

  @override
  String get chatStatusClosed => 'Closed';

  @override
  String get chatStatusInProgress => 'In Progress';

  @override
  String get chatStatusOpen => 'Open';

  @override
  String get chatStatusResolved => 'Resolved';

  @override
  String chatStreak(int count) {
    return 'Streak: $count';
  }

  @override
  String get chatSubject => 'Subject';

  @override
  String get chatSubjectHint => 'Brief description of your issue';

  @override
  String get chatSupportAddAttachment => 'Add Attachment';

  @override
  String get chatSupportAddCaptionOptional => 'Add a caption (optional)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agent: $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agent';

  @override
  String get chatSupportCategory => 'Category';

  @override
  String get chatSupportClose => 'Close';

  @override
  String chatSupportDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get chatSupportErrorLoading => 'Error loading messages';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Failed to reopen ticket: $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String get chatSupportGeneral => 'General';

  @override
  String get chatSupportGeneralSupport => 'General Support';

  @override
  String chatSupportHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get chatSupportJustNow => 'Just now';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get chatSupportReopenTicket => 'Need more help? Tap to reopen';

  @override
  String get chatSupportStartMessage =>
      'Send a message to start the conversation.\nOur team will respond as soon as possible.';

  @override
  String get chatSupportStatus => 'Status';

  @override
  String get chatSupportStatusClosed => 'Closed';

  @override
  String get chatSupportStatusDefault => 'Support';

  @override
  String get chatSupportStatusOpen => 'Open';

  @override
  String get chatSupportStatusPending => 'Pending';

  @override
  String get chatSupportStatusResolved => 'Resolved';

  @override
  String get chatSupportSubject => 'Subject';

  @override
  String get chatSupportTicketCreated => 'Ticket Created';

  @override
  String get chatSupportTicketId => 'Ticket ID';

  @override
  String get chatSupportTicketInfo => 'Ticket Information';

  @override
  String get chatSupportTicketReopened =>
      'Ticket reopened. You can send a message now.';

  @override
  String get chatSupportTicketResolved => 'This ticket has been resolved';

  @override
  String get chatSupportTicketStart => 'Ticket Start';

  @override
  String get chatSupportTitle => 'GreenGo Support';

  @override
  String get chatSupportTypeMessage => 'Type your message...';

  @override
  String get chatSupportWaitingAssignment => 'Waiting for assignment';

  @override
  String get chatSupportWelcome => 'Welcome to Support';

  @override
  String get chatTapToView => 'Tap to view';

  @override
  String get chatTapToViewAlbum => 'Tap to view album';

  @override
  String get chatTranslate => 'Translate';

  @override
  String get chatTranslated => 'Translated';

  @override
  String get chatTranslating => 'Translating...';

  @override
  String get chatTranslationDisabled => 'Translation disabled';

  @override
  String get chatTranslationEnabled => 'Translation enabled';

  @override
  String get chatTranslationFailed => 'Translation failed. Please try again.';

  @override
  String get translationFailedTapRetry => 'Couldn\'t translate · Tap to retry';

  @override
  String get chatTrialExpired => 'Your free trial has expired.';

  @override
  String get chatTtsComingSoon => 'Text-to-speech coming soon!';

  @override
  String get chatTyping => 'typing...';

  @override
  String get chatUnableToForward => 'Unable to forward message';

  @override
  String get chatUnknown => 'Unknown';

  @override
  String get chatUnstarMessage => 'Unstar Message';

  @override
  String get chatUpgrade => 'Upgrade';

  @override
  String get chatUpgradePracticeMode =>
      'Upgrade to Silver VIP or higher to continue practicing languages in your chats.';

  @override
  String get chatUploading => 'Uploading...';

  @override
  String get chatUseCorrection => 'Use Correction';

  @override
  String chatUserBlocked(String name) {
    return '$name has been blocked';
  }

  @override
  String get chatUserReported =>
      'User reported. We will review your report shortly.';

  @override
  String get chatVideo => 'Video';

  @override
  String get chatVideoPlayer => 'Video Player';

  @override
  String get chatVideoTooLarge => 'Video too large. Maximum size is 50MB.';

  @override
  String get chatWhyReportMessage => 'Why are you reporting this message?';

  @override
  String chatWhyReportUser(String name) {
    return 'Why are you reporting $name?';
  }

  @override
  String chatWithName(String name) {
    return 'Chat with $name';
  }

  @override
  String chatWords(int count) {
    return '$count words';
  }

  @override
  String get chatYou => 'You';

  @override
  String get chatYouRevokedAlbum => 'You revoked album access';

  @override
  String get chatYouSharedAlbum => 'You shared your private album';

  @override
  String get chatYourLanguage => 'Your Language';

  @override
  String get checkBackLater =>
      'Check back later for new people, or adjust your preferences';

  @override
  String get chooseCorrectAnswer => 'Choose the correct answer';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get chooseGame => 'Choose a Game';

  @override
  String get claimReward => 'Claim Reward';

  @override
  String get claimRewardBtn => 'Claim';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get close => 'Close';

  @override
  String get coins => 'Coins';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins coins added to your account$bonusText';
  }

  @override
  String get coinsAllTransactions => 'All Transactions';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount Coins';
  }

  @override
  String get coinsApply => 'Apply';

  @override
  String coinsBalance(Object balance) {
    return 'Balance: $balance';
  }

  @override
  String coinsBonusCoins(Object amount) {
    return '+$amount bonus coins';
  }

  @override
  String get coinsCancelLabel => 'Cancel';

  @override
  String get coinsConfirmPurchase => 'Confirm Purchase';

  @override
  String coinsCost(int amount) {
    return '$amount coins';
  }

  @override
  String get coinsCreditsOnly => 'Credits Only';

  @override
  String get coinsDebitsOnly => 'Debits Only';

  @override
  String get coinsEnterReceiverId => 'Enter receiver ID';

  @override
  String get coinsFilterTransactions => 'Filter Transactions';

  @override
  String coinsGiftAccepted(Object amount) {
    return 'Accepted $amount coins!';
  }

  @override
  String get coinsGiftDeclined => 'Gift declined';

  @override
  String get coinsGiftSendFailed => 'Failed to send gift';

  @override
  String coinsGiftSent(Object amount) {
    return 'Gift of $amount coins sent!';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Insufficient coins';

  @override
  String get coinsLabel => 'Coins';

  @override
  String get coinsMessageLabel => 'Message (optional)';

  @override
  String get coinsMins => 'mins';

  @override
  String get coinsNoTransactionsYet => 'No transactions yet';

  @override
  String get coinsPendingGifts => 'Pending Gifts';

  @override
  String get coinsPopular => 'POPULAR';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return 'Purchase $totalCoins coins for $price?';
  }

  @override
  String get coinsPurchaseFailed => 'Purchase failed';

  @override
  String get coinsPurchaseLabel => 'Purchase';

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return 'Successfully purchased $totalCoins coins!';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return 'Successfully purchased $totalMinutes video minutes!';
  }

  @override
  String get coinsReceiverIdLabel => 'Receiver User ID';

  @override
  String coinsRequired(int amount) {
    return '$amount coins required';
  }

  @override
  String get coinsRetry => 'Retry';

  @override
  String get coinsSelectAmount => 'Select Amount';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return 'Send $amount Coins';
  }

  @override
  String get coinsSendGift => 'Send Gift';

  @override
  String get coinsSent => 'Coins sent successfully!';

  @override
  String get coinsShareCoins => 'Share coins with someone special';

  @override
  String get coinsShopLabel => 'Shop';

  @override
  String get coinsTabCoins => 'Coins';

  @override
  String get coinsTabGifts => 'Gifts';

  @override
  String get coinsToday => 'Today';

  @override
  String get coinsTransactionHistory => 'Transaction History';

  @override
  String get coinsTransactionsAppearHere =>
      'Your coin transactions will appear here';

  @override
  String get coinsUnlockPremium => 'Unlock premium features';

  @override
  String get coinsVideoCallMatches => 'Video call with your matches';

  @override
  String get coinsVideoMinutes => 'Video Minutes';

  @override
  String get coinsYesterday => 'Yesterday';

  @override
  String get comingSoonLabel => 'Coming Soon';

  @override
  String get communitiesAddTag => 'Add a tag';

  @override
  String get communitiesAdjustSearch => 'Try adjusting your search or filters.';

  @override
  String get communitiesAllCommunities => 'All Communities';

  @override
  String get communitiesAllFilter => 'All';

  @override
  String get communitiesAnyoneCanJoin => 'Anyone can find and join';

  @override
  String get communitiesBeFirstToSay => 'Be the first to say something!';

  @override
  String get communitiesCancelLabel => 'Cancel';

  @override
  String get communitiesCityLabel => 'City';

  @override
  String get communitiesCityTipLabel => 'City Tip';

  @override
  String get communitiesCityTipUpper => 'CITY TIP';

  @override
  String get communitiesCommunityInfo => 'Community Info';

  @override
  String get communitiesCommunityName => 'Community Name';

  @override
  String get communitiesCoverImageLabel => 'Cover image';

  @override
  String get communitiesCoverImageHint => 'Add a cover photo (optional)';

  @override
  String get communitiesCommunityType => 'Community Type';

  @override
  String get communitiesCountryLabel => 'Country';

  @override
  String get communitiesCreateAction => 'Create';

  @override
  String get communitiesCreateCommunity => 'Create Community';

  @override
  String get communitiesCreateCommunityAction => 'Create Community';

  @override
  String get communitiesCreateLabel => 'Create';

  @override
  String get communitiesCreateLanguageCircle => 'Create Language Circle';

  @override
  String get communitiesCreated => 'Community created!';

  @override
  String communitiesCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Created';

  @override
  String get communitiesCulturalFactLabel => 'Cultural Fact';

  @override
  String get communitiesCulturalFactUpper => 'CULTURAL FACT';

  @override
  String get communitiesDescription => 'Description';

  @override
  String get communitiesDescriptionHint => 'What is this community about?';

  @override
  String get communitiesDescriptionLabel => 'Description';

  @override
  String get communitiesDescriptionMinLength =>
      'Description must be at least 10 characters';

  @override
  String get communitiesDescriptionRequired => 'Please enter a description';

  @override
  String get communitiesDiscoverCommunities => 'Discover Communities';

  @override
  String get communitiesEditLabel => 'Edit';

  @override
  String get communitiesGuide => 'Guide';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Invite only';

  @override
  String get communitiesJoinCommunity => 'Join Community';

  @override
  String get communitiesJoinPrompt =>
      'Join communities to connect with people who share your interests and languages.';

  @override
  String get communitiesJoined => 'Joined community!';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'Language circles will appear here when available. Create one to get started!';

  @override
  String get communitiesLanguageTipLabel => 'Language Tip';

  @override
  String get communitiesLanguageTipUpper => 'LANGUAGE TIP';

  @override
  String get communitiesLanguages => 'Languages';

  @override
  String get communitiesLanguagesLabel => 'Languages';

  @override
  String get communitiesLeaveCommunity => 'Leave Community';

  @override
  String get communitiesBusinessCannotJoin =>
      'Business accounts cannot join communities. Switch off business mode to join.';

  @override
  String get communitiesDeleteCommunity => 'Delete Community';

  @override
  String communitiesDeleteConfirm(String name) {
    return 'Permanently delete \"$name\"? All messages, members and content are removed. This cannot be undone.';
  }

  @override
  String get communitiesDeletedSuccess => 'Community deleted';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Are you sure you want to leave \"$name\"?';
  }

  @override
  String get communitiesLeaveLabel => 'Leave';

  @override
  String get communitiesLeaveTitle => 'Leave Community';

  @override
  String get communitiesLocation => 'Location';

  @override
  String get communitiesLocationLabel => 'Location';

  @override
  String communitiesMembersCount(Object count) {
    return '$count members';
  }

  @override
  String get communitiesMembersStatLabel => 'Members';

  @override
  String get communitiesMembersTitle => 'Members';

  @override
  String get communitiesNameHint => 'e.g., Spanish Learners NYC';

  @override
  String get communitiesNameMinLength => 'Name must be at least 3 characters';

  @override
  String get communitiesNameRequired => 'Please enter a name';

  @override
  String get communitiesNoCommunities => 'No Communities Yet';

  @override
  String get communitiesNoCommunitiesFound => 'No Communities Found';

  @override
  String get communitiesNoLanguageCircles => 'No Language Circles';

  @override
  String get communitiesNoMessagesYet => 'No messages yet';

  @override
  String get communitiesPreview => 'Preview';

  @override
  String get communitiesPreviewSubtitle =>
      'This is how your community will appear to others.';

  @override
  String get communitiesPrivate => 'Private';

  @override
  String get communitiesPublic => 'Public';

  @override
  String get communitiesRecommendedForYou => 'Recommended for You';

  @override
  String get communitiesSearchHint => 'Search communities...';

  @override
  String get communitiesSaveFavorite => 'Save to favorites';

  @override
  String get communitiesRemoveFavorite => 'Remove from favorites';

  @override
  String get communitiesFavoritesSection => 'Favorites';

  @override
  String get communitiesShareCityTip => 'Share a city tip...';

  @override
  String get communitiesShareCulturalFact => 'Share a cultural fact...';

  @override
  String get communitiesShareLanguageTip => 'Share a language tip...';

  @override
  String get communitiesStats => 'Stats';

  @override
  String get communitiesTabDiscover => 'Discover';

  @override
  String get communitiesTabLanguageCircles => 'Language Circles';

  @override
  String get communitiesTabMyGroups => 'My Groups';

  @override
  String get communitiesTabJoined => 'Joined Communities';

  @override
  String get communitiesTabManaged => 'My communities';

  @override
  String get communitiesNoManaged => 'You don\'t manage any communities yet';

  @override
  String get communitiesNoManagedSubtitle =>
      'Create a community to bring people together';

  @override
  String get communitiesTags => 'Tags';

  @override
  String get communitiesTagsLabel => 'Tags';

  @override
  String get communitiesTextLabel => 'Text';

  @override
  String get communitiesTitle => 'Communities';

  @override
  String get communitiesTypeAMessage => 'Type a message...';

  @override
  String get communitiesUnableToLoad => 'Unable to load community';

  @override
  String get compatibilityLabel => 'Compatibility';

  @override
  String compatiblePercent(String percent) {
    return '$percent% compatible';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      'Complete achievements to earn badges!';

  @override
  String get completeProfile => 'Complete Your Profile';

  @override
  String get complimentsCategory => 'Compliments';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmLabel => 'Confirm';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get connectSocialAccounts => 'Connect your social accounts';

  @override
  String get connectionError => 'Connection error';

  @override
  String get connectionErrorMessage =>
      'Please check your internet connection and try again.';

  @override
  String get connectionErrorTitle => 'No Internet Connection';

  @override
  String get consentRequired => 'Required Consents';

  @override
  String get consentRequiredError =>
      'You must accept the Privacy Policy and Terms and Conditions to register';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get continueLearningBtn => 'Continue';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get conversationCategory => 'Conversation';

  @override
  String get correctAnswer => 'Correct!';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get createAccount => 'Create Account';

  @override
  String get culturalCategory => 'Cultural';

  @override
  String get culturalExchangeBeFirstTip =>
      'Be the first to share a cultural tip!';

  @override
  String get culturalExchangeCategory => 'Category';

  @override
  String get culturalExchangeCommunityTips => 'Community Tips';

  @override
  String get culturalExchangeCountry => 'Country';

  @override
  String get culturalExchangeCountryHint => 'e.g., Japan, Brazil, France';

  @override
  String get culturalExchangeCountrySpotlight => 'Country Spotlight';

  @override
  String get culturalExchangeDailyInsight => 'Daily Cultural Insight';

  @override
  String get culturalExchangeDatingEtiquette => 'Dating Etiquette';

  @override
  String get culturalExchangeDatingEtiquetteGuide => 'Dating Etiquette Guide';

  @override
  String get culturalExchangeLoadingCountries => 'Loading countries...';

  @override
  String get culturalExchangeNoTips => 'No tips yet';

  @override
  String get culturalExchangeShareCulturalTip => 'Share a Cultural Tip';

  @override
  String get culturalExchangeShareTip => 'Share a Tip';

  @override
  String get culturalExchangeSubmitTip => 'Submit Tip';

  @override
  String get culturalExchangeTipTitle => 'Title';

  @override
  String get culturalExchangeTipTitleHint => 'Give your tip a catchy title';

  @override
  String get culturalExchangeTitle => 'Cultural Exchange';

  @override
  String get culturalExchangeViewAll => 'View All';

  @override
  String get culturalExchangeYourTip => 'Your Tip';

  @override
  String get culturalExchangeYourTipHint => 'Share your cultural knowledge...';

  @override
  String get dailyChallengesSubtitle => 'Complete challenges for rewards';

  @override
  String get dailyChallengesTitle => 'Daily Challenges';

  @override
  String dailyLimitReached(int limit) {
    return 'Daily limit of $limit reached';
  }

  @override
  String get dailyMessages => 'Daily Messages';

  @override
  String get dailyRewardHeader => 'Daily Reward';

  @override
  String get dailySwipeLimitReached =>
      'Daily swipe limit reached. Upgrade for more swipes!';

  @override
  String get dailySwipes => 'Daily Swipes';

  @override
  String get dataExportSentToEmail => 'Data export sent to your email';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get datePlanningCategory => 'Date Planning';

  @override
  String get dateSchedulerAccept => 'Accept';

  @override
  String get dateSchedulerCancelConfirm =>
      'Are you sure you want to cancel this date?';

  @override
  String get dateSchedulerCancelTitle => 'Cancel Date';

  @override
  String get dateSchedulerConfirmed => 'Date confirmed!';

  @override
  String get dateSchedulerDecline => 'Decline';

  @override
  String get dateSchedulerEnterTitle => 'Please enter a title';

  @override
  String get dateSchedulerKeepDate => 'Keep Date';

  @override
  String get dateSchedulerNotesLabel => 'Notes (optional)';

  @override
  String get dateSchedulerPlanningHint => 'e.g., Coffee, Dinner, Movie...';

  @override
  String get dateSchedulerReasonLabel => 'Reason (optional)';

  @override
  String get dateSchedulerReschedule => 'Reschedule';

  @override
  String get dateSchedulerRescheduleTitle => 'Reschedule Date';

  @override
  String get dateSchedulerSchedule => 'Schedule';

  @override
  String get dateSchedulerScheduled => 'Date scheduled!';

  @override
  String get dateSchedulerTabPast => 'Past';

  @override
  String get dateSchedulerTabPending => 'Pending';

  @override
  String get dateSchedulerTabUpcoming => 'Upcoming';

  @override
  String get dateSchedulerTitle => 'My Dates';

  @override
  String get dateSchedulerWhatPlanning => 'What are you planning?';

  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count day streak';
  }

  @override
  String dayStreakLabel(int days) {
    return '$days Day Streak!';
  }

  @override
  String get days => 'Days';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.';

  @override
  String get details => 'Details';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String directMessageCost(int cost) {
    return 'Direct messaging costs $cost coins. Would you like to buy more coins?';
  }

  @override
  String get discover => 'Network';

  @override
  String discoveryError(String error) {
    return 'Error: $error';
  }

  @override
  String get discoveryFilterAll => 'All';

  @override
  String get discoveryFilterGuides => 'Guides';

  @override
  String get discoveryFilterLiked => 'Connected';

  @override
  String get discoveryFilterMatches => 'Matches';

  @override
  String get discoveryFilterPassed => 'Passed';

  @override
  String get discoveryFilterSkipped => 'Explored';

  @override
  String get discoveryFilterSuperLiked => 'Priority';

  @override
  String get discoveryFilterNetwork => 'My Network';

  @override
  String get discoveryFilterTravelers => 'Travelers';

  @override
  String get discoveryLimitReached => 'You\'ve reached your discovery limit';

  @override
  String discoverySeeMoreCoins(int coins) {
    return 'Spend $coins coins to see more';
  }

  @override
  String get discoveryPreferencesTitle => 'Discovery Preferences';

  @override
  String get discoveryPreferencesTooltip => 'Discovery Preferences';

  @override
  String get discoverySwitchToGrid => 'Switch to grid mode';

  @override
  String get discoverySwitchToSwipe => 'Switch to swipe mode';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get distance => 'Distance';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Document not available';

  @override
  String get documentNotAvailableDescription =>
      'This document is not available in your language yet.';

  @override
  String get done => 'Done';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get download => 'Download';

  @override
  String downloadProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String downloadingLanguage(String language) {
    return 'Downloading $language...';
  }

  @override
  String get downloadingTranslationData => 'Downloading Translation Data';

  @override
  String get edit => 'Edit';

  @override
  String get editInterests => 'Edit Interests';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editVoiceComingSoon => 'Edit voice coming soon';

  @override
  String get education => 'Education';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Please enter a valid email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emergencyCategory => 'Emergency';

  @override
  String get emptyStateErrorMessage =>
      'We couldn\'t load this content. Please try again.';

  @override
  String get emptyStateErrorTitle => 'Something went wrong';

  @override
  String get emptyStateNoInternetMessage =>
      'Please check your internet connection and try again.';

  @override
  String get emptyStateNoInternetTitle => 'No connection';

  @override
  String get emptyStateNoLikesMessage =>
      'Complete your profile to get more likes!';

  @override
  String get emptyStateNoLikesTitle => 'No likes yet';

  @override
  String get emptyStateNoMatchesMessage =>
      'Start swiping to find your perfect match!';

  @override
  String get emptyStateNoMatchesTitle => 'No matches yet';

  @override
  String get emptyStateNoMessagesMessage =>
      'When you match with someone, you can start chatting here.';

  @override
  String get emptyStateNoMessagesTitle => 'No messages';

  @override
  String get emptyStateNoNotificationsMessage =>
      'You don\'t have any new notifications.';

  @override
  String get emptyStateNoNotificationsTitle => 'All caught up!';

  @override
  String get emptyStateNoResultsMessage =>
      'Try adjusting your search or filters.';

  @override
  String get emptyStateNoResultsTitle => 'No results found';

  @override
  String get enableAutoTranslation => 'Enable Auto-Translation';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get enterNickname => 'Enter nickname';

  @override
  String get enterNicknameHint => 'Enter nickname';

  @override
  String get enterNicknameToFind => 'Enter a nickname to find someone directly';

  @override
  String get enterRejectionReason => 'Enter rejection reason';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String get errorLoadingDocument => 'Error loading document';

  @override
  String get errorSearchingTryAgain => 'Error searching. Please try again.';

  @override
  String get eventsAboutThisEvent => 'About this event';

  @override
  String get eventsApplyFilters => 'Apply Filters';

  @override
  String get eventsAttendees => 'Attendees';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max attending';
  }

  @override
  String get eventsBeFirstToSay => 'Be the first to say something!';

  @override
  String get eventsCategory => 'Category';

  @override
  String get eventsChatWithAttendees => 'Chat with other attendees';

  @override
  String get eventsCheckBackLater =>
      'Check back later or create your own event!';

  @override
  String get eventsCreateEvent => 'Create Event';

  @override
  String get eventsCreatedSuccessfully => 'Event created successfully!';

  @override
  String get eventsDateRange => 'Date Range';

  @override
  String get eventsDeleted => 'Event deleted';

  @override
  String get eventsDescription => 'Description';

  @override
  String get eventsDistance => 'Distance';

  @override
  String get eventsEndDateTime => 'End Date & Time';

  @override
  String get eventsErrorLoadingMessages => 'Error loading messages';

  @override
  String get eventsEventFull => 'Event Full';

  @override
  String get eventsEventTitle => 'Event Title';

  @override
  String get eventsFilterEvents => 'Filter Events';

  @override
  String get eventsFreeEvent => 'Free Event';

  @override
  String get eventsFreeLabel => 'FREE';

  @override
  String get eventsFullLabel => 'Full';

  @override
  String eventsGoing(Object count) {
    return '$count going';
  }

  @override
  String get eventsGoingLabel => 'Going';

  @override
  String get eventsGroupChatTooltip => 'Event Group Chat';

  @override
  String get eventsJoinEvent => 'Join Event';

  @override
  String get eventsJoinLabel => 'Join';

  @override
  String eventsKmAwayFormat(String km) {
    return '${km}km away';
  }

  @override
  String get eventsLanguageExchange => 'Language Exchange';

  @override
  String get eventsLanguagePairs => 'Language Pairs (e.g., Spanish ↔ English)';

  @override
  String eventsLanguages(String languages) {
    return 'Languages: $languages';
  }

  @override
  String get eventsLocation => 'Location';

  @override
  String eventsMAwayFormat(Object meters) {
    return '${meters}m away';
  }

  @override
  String get eventsMaxAttendees => 'Max Attendees';

  @override
  String get eventsCapacityAllowed => 'Capacity allowed';

  @override
  String get eventsNoAttendeesYet => 'No attendees yet. Be the first to join!';

  @override
  String get eventsNoEventsFound => 'No events found';

  @override
  String get eventsNoMessagesYet => 'No messages yet';

  @override
  String get eventsRequired => 'Required';

  @override
  String get eventsRsvpCancelled => 'RSVP cancelled';

  @override
  String get eventsRsvpUpdated => 'RSVP updated!';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count spots left';
  }

  @override
  String get eventsStartDateTime => 'Start Date & Time';

  @override
  String get eventsTabMyEvents => 'My Events';

  @override
  String get eventsFilterOngoing => 'On-going';

  @override
  String get eventsFilterUpcoming => 'Upcoming';

  @override
  String get eventsFilterPast => 'Past';

  @override
  String get eventsTabExperiences => 'Experiences';

  @override
  String get eventsTabAttractions => 'Attractions';

  @override
  String get eventsTabCommunity => 'Community';

  @override
  String get eventsDeleteEvent => 'Delete event';

  @override
  String get eventsDeleteConfirmBody =>
      'Are you sure you want to delete this event? This cannot be undone.';

  @override
  String get eventsBook => 'Book';

  @override
  String get eventsFromPrice => 'from';

  @override
  String get eventsTabNearby => 'Nearby';

  @override
  String get eventsTabUpcoming => 'Upcoming';

  @override
  String get eventsThisMonth => 'This Month';

  @override
  String get eventsDateUntil => 'Until';

  @override
  String get eventsDateFrom => 'From';

  @override
  String get eventsCustomRange => 'Custom range';

  @override
  String get eventsDateAnyTime => 'Any time';

  @override
  String get eventsThisWeekFilter => 'This Week';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsAndPlacesTitle => 'Events and Places';

  @override
  String get eventsCategoryAll => 'All';

  @override
  String attractionVisitWebsite(String host) {
    return 'Visit $host';
  }

  @override
  String get attractionVisitWikidata => 'Visit wikidata.org';

  @override
  String get attractionOpenInMaps => 'Open in Maps';

  @override
  String get attractionOpenLink => 'Open link';

  @override
  String get attractionOpenWebsite => 'Open official website';

  @override
  String get attractionShareChat => 'Share to chat';

  @override
  String get attractionShareGroup => 'Share to group';

  @override
  String get attractionDescribedAt => 'Read more';

  @override
  String get attractionReport => 'Report event';

  @override
  String get attractionReportConfirm =>
      'Report this listing as inappropriate or incorrect?';

  @override
  String get eventsToday => 'Today';

  @override
  String get eventsTypeAMessage => 'Type a message...';

  @override
  String get exit => 'Exit';

  @override
  String get exitApp => 'Exit App?';

  @override
  String get exitAppConfirmation => 'Are you sure you want to exit GreenGo?';

  @override
  String get exploreLanguages => 'Explore Languages';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get communityTabTitle => 'Community';

  @override
  String exploreHeadline(String city) {
    return 'Explore $city';
  }

  @override
  String get exploreSubtitle =>
      'Cultural experiences and language partners near you';

  @override
  String get explorePracticeLanguage => 'Practice a language';

  @override
  String get exploreNetworkDiscovery => 'Network Discovery';

  @override
  String exploreNetworkDiscoverySubtitle(String country) {
    return 'People to connect with in $country';
  }

  @override
  String get exploreSeeAll => 'See all';

  @override
  String get explorePromotedBadge => 'Promoted';

  @override
  String get exploreHappeningThisWeek => 'Happening this week';

  @override
  String get exploreHappeningToday => 'Happening today';

  @override
  String get exploreJoin => 'Join';

  @override
  String get exploreFeatured => 'Featured experience';

  @override
  String exploreSpeaksLearning(String speaks, String learning) {
    return 'speaks $speaks · learning $learning';
  }

  @override
  String exploreSpeaks(String language) {
    return 'speaks $language';
  }

  @override
  String get exploreAroundYou => 'Discover new people';

  @override
  String get exploreSameInterests => 'People with your same interests';

  @override
  String get exploreBusinessAccounts => 'Business accounts';

  @override
  String exploreSpeaksLanguage(String language) {
    return 'People that speak $language';
  }

  @override
  String get exploreCommunityEventsNearby => 'Community events near you';

  @override
  String get exploreNoPartners =>
      'No language partners nearby yet — check back soon.';

  @override
  String get exploreNoEvents => 'No experiences to show yet — check back soon.';

  @override
  String get exploreNoCommunities =>
      'No communities to join yet — check back soon.';

  @override
  String exploreGoingCount(int count) {
    return '$count going';
  }

  @override
  String get exploreFeaturedEvents => 'Featured events';

  @override
  String get exploreFeaturedAttractions => 'Featured attractions';

  @override
  String get exploreTopExperiences => 'Top experiences';

  @override
  String get exploreMyNextEvents => 'My next events';

  @override
  String get exploreCommunitiesTitle => 'Communities to join';

  @override
  String exploreMembersCount(int count) {
    return '$count members';
  }

  @override
  String get exploreCountrySpotlight => 'Country Spotlight';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get statCoins => 'Coins';

  @override
  String get statTier => 'Tier';

  @override
  String get statCountries => 'Countries';

  @override
  String get statPeople => 'People';

  @override
  String get networkWorldMap => 'World Network';

  @override
  String get discoveryShowPeople => 'Show people';

  @override
  String get discoveryShowBusinesses => 'Show businesses';

  @override
  String networkDiscoveryDistanceKm(String distance) {
    return '$distance km away';
  }

  @override
  String get connectAction => 'Connect';

  @override
  String get connectError => 'Could not start the chat. Please try again.';

  @override
  String get sayHiAction => 'Say hi';

  @override
  String get newConnectionLabel => 'New connection';

  @override
  String get connectionsTitle => 'Connections';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km away';
  }

  @override
  String get exploreMapError => 'Could not load nearby users';

  @override
  String get exploreMapExpandRadius => 'Expand Radius';

  @override
  String get exploreMapExpandRadiusHint =>
      'Try increasing your search radius to find more people.';

  @override
  String get exploreMapNearbyUser => 'Nearby User';

  @override
  String get exploreMapNoOneNearby => 'No one nearby';

  @override
  String get exploreMapOnlineNow => 'Online now';

  @override
  String get exploreMapPeopleNearYou => 'People Near You';

  @override
  String get exploreMapRadius => 'Radius:';

  @override
  String get exploreMapVisible => 'Visible';

  @override
  String get exportMyDataGDPR => 'Export My Data (GDPR)';

  @override
  String get exportingYourData => 'Exporting your data...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Extend ($cost coins)';
  }

  @override
  String get extendTooltip => 'Extend';

  @override
  String failedToDownloadModel(String language) {
    return 'Failed to download $language model';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Failed to save preferences: $error';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Feature not available on $tier';
  }

  @override
  String get fillCategories => 'Fill all categories';

  @override
  String get filterAll => 'All';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Direct';

  @override
  String get filterMessaged => 'Messaged';

  @override
  String get filterNew => 'New';

  @override
  String get filterNewMessages => 'New';

  @override
  String get filterNotReplied => 'Unread';

  @override
  String filteredFromTotal(int total) {
    return 'Filtered from $total';
  }

  @override
  String get filters => 'Filters';

  @override
  String get finish => 'Finish';

  @override
  String get firstName => 'First Name';

  @override
  String get firstTo30Wins => 'First to 30 wins!';

  @override
  String get flashcardReviewLabel => 'Flashcards';

  @override
  String get flirtyCategory => 'Flirty';

  @override
  String get foodDiningCategory => 'Food & Dining';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String freeActionsRemaining(int count) {
    return '$count free actions remaining today';
  }

  @override
  String get friendship => 'Friendship';

  @override
  String get gameAbandon => 'Abandon';

  @override
  String get gameAbandonLoseMessage =>
      'You will lose this game if you leave now.';

  @override
  String get gameAbandonProgressMessage =>
      'You will lose your progress and return to the lobby.';

  @override
  String get gameAbandonTitle => 'Abandon Game?';

  @override
  String get gameAbandonTooltip => 'Abandon Game';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Enter a word starting with \"$letter\"...';
  }

  @override
  String get gameCategoriesFilled => 'filled';

  @override
  String get gameCategoriesNewLetter => 'New Letter!';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — starts with \"$letter\"';
  }

  @override
  String get gameCategoriesTapToFill => 'Tap a category to fill it!';

  @override
  String get gameCategoriesTimesUp => 'Time\'s up! Waiting for next round...';

  @override
  String get gameCategoriesTitle => 'Categories';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      'Word already used in another category!';

  @override
  String get gameCategoryAnimals => 'Animals';

  @override
  String get gameCategoryClothing => 'Clothing';

  @override
  String get gameCategoryColors => 'Colors';

  @override
  String get gameCategoryCountries => 'Countries';

  @override
  String get gameCategoryFood => 'Food';

  @override
  String get gameCategoryNature => 'Nature';

  @override
  String get gameCategoryProfessions => 'Professions';

  @override
  String get gameCategorySports => 'Sports';

  @override
  String get gameCategoryTransport => 'Transport';

  @override
  String get gameChainBreak => 'CHAIN BREAK!';

  @override
  String get gameChainNextMustStartWith => 'Next word must start with: ';

  @override
  String get gameChainNoWordsYet => 'No words yet!';

  @override
  String get gameChainStartWithAnyWord => 'Start the chain with any word';

  @override
  String get gameChainTitle => 'Vocabulary Chain';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Type a word starting with \"$letter\"...';
  }

  @override
  String get gameChainTypeToStartHint => 'Type a word to start the chain...';

  @override
  String gameChainWordsChained(int count) {
    return '$count words chained';
  }

  @override
  String get gameCorrect => 'Correct!';

  @override
  String get gameDefaultPlayerName => 'Player';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff ahead';
  }

  @override
  String get gameGrammarDuelAnswered => 'Answered';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff behind';
  }

  @override
  String get gameGrammarDuelFast => 'FAST!';

  @override
  String get gameGrammarDuelGrammarQuestion => 'GRAMMAR QUESTION';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '+$points points!';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return 'x$count streak!';
  }

  @override
  String get gameGrammarDuelThinking => 'Thinking...';

  @override
  String get gameGrammarDuelTitle => 'Grammar Duel';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => 'Wrong answer!';

  @override
  String get gameInvalidAnswer => 'Invalid!';

  @override
  String get gameLanguageBrazilianPortuguese => 'Brazilian Portuguese';

  @override
  String get gameLanguageEnglish => 'English';

  @override
  String get gameLanguageFrench => 'French';

  @override
  String get gameLanguageGerman => 'German';

  @override
  String get gameLanguageItalian => 'Italian';

  @override
  String get gameLanguageJapanese => 'Japanese';

  @override
  String get gameLanguagePortuguese => 'Portuguese';

  @override
  String get gameLanguageSpanish => 'Spanish';

  @override
  String get gameLeave => 'Leave';

  @override
  String get gameOpponent => 'Opponent';

  @override
  String get gameOver => 'Game Over';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Attempt $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      'You can\'t use the word itself in your clue!';

  @override
  String get gamePictureGuessClues => 'CLUES';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count clue(s) sent';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return 'Correct! +$points points';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      'Correct! Waiting for round to end...';

  @override
  String get gamePictureGuessDescriber => 'DESCRIBER';

  @override
  String get gamePictureGuessDescriberRules =>
      'Give clues to help others guess. No direct translations or spelling hints!';

  @override
  String get gamePictureGuessGuessTheWord => 'Guess the word!';

  @override
  String get gamePictureGuessGuessTheWordUpper => 'GUESS THE WORD!';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'No more attempts — waiting for round to end';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'No more attempts this round';

  @override
  String get gamePictureGuessTheWordWas => 'The word was:';

  @override
  String get gamePictureGuessTitle => 'Picture Guess';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Type a clue (no direct translations!)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Type your guess... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'Waiting for clues...';

  @override
  String get gamePictureGuessWaitingForOthers => 'Waiting for others...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Wrong guess: \"$guess\"';
  }

  @override
  String get gamePictureGuessYouAreDescriber => 'You are the DESCRIBER!';

  @override
  String get gamePictureGuessYourWord => 'YOUR WORD';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      'Answer submitted! Waiting for others...';

  @override
  String get gamePlayCategoriesHeader => 'CATEGORIES';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Category: $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return 'Correct! +$points pts';
  }

  @override
  String get gamePlayDescribeThisWord => 'DESCRIBE THIS WORD!';

  @override
  String get gamePlayDescribeWordHint =>
      'Describe the word (don\'t say it!)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name is describing a word...';
  }

  @override
  String get gamePlayDoNotSayWord => 'Do not say the word itself!';

  @override
  String get gamePlayGuessTheWord => 'GUESS THE WORD';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Incorrect. The answer was \"$answer\"';
  }

  @override
  String get gamePlayLeaderboard => 'LEADERBOARD';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Name a $language word starting with \"$letter\"';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Name a word in \"$category\" starting with \"$letter\"';
  }

  @override
  String get gamePlayNextWordMustStartWith => 'NEXT WORD MUST START WITH';

  @override
  String get gamePlayNoWordsStartChain => 'No words yet - start the chain!';

  @override
  String get gamePlayPickLetterNameWord => 'Pick a letter, then name a word!';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name is choosing...';
  }

  @override
  String gamePlayPlayerIsThinking(String name) {
    return '$name is thinking...';
  }

  @override
  String gamePlayThemeLabel(String theme) {
    return 'Theme: $theme';
  }

  @override
  String get gamePlayTranslateThisWord => 'TRANSLATE THIS WORD';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Type a word containing \"$prompt\"...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Type a word starting with \"$prompt\"...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Type the translation...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      'Type a word containing these letters!';

  @override
  String get gamePlayTypeYourAnswerHint => 'Type your answer...';

  @override
  String get gamePlayTypeYourGuessBelow => 'Type your guess below!';

  @override
  String get gamePlayTypeYourGuessHint => 'Type your guess...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Use the chat to describe the word to other players';

  @override
  String get gamePlayWaitingForOpponent => 'Waiting for opponent...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Word starting with \"$letter\"...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Word starting with \"$prompt\"...';
  }

  @override
  String get gamePlayYourTurnFlipCards => 'Your turn - flip two cards!';

  @override
  String gamePlayersTurn(String name) {
    return '$name\'s turn';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points pts';
  }

  @override
  String get gamePositionFirst => '1st';

  @override
  String gamePositionNth(int pos) {
    return '${pos}th';
  }

  @override
  String get gamePositionSecond => '2nd';

  @override
  String get gamePositionThird => '3rd';

  @override
  String get gameResultsBackToLobby => 'Back to Lobby';

  @override
  String get gameResultsBaseXp => 'Base XP';

  @override
  String get gameResultsCoinsEarned => 'Coins Earned';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Difficulty Bonus (Lv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'FINAL STANDINGS';

  @override
  String get gameResultsGameOver => 'GAME OVER';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'Not enough coins ($amount required)';
  }

  @override
  String get gameResultsPlayAgain => 'Play Again';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'REWARDS EARNED';

  @override
  String get gameResultsTotalXp => 'Total XP';

  @override
  String get gameResultsVictory => 'VICTORY!';

  @override
  String get gameResultsWhatYouLearned => 'WHAT YOU LEARNED';

  @override
  String get gameResultsWinner => 'Winner';

  @override
  String get gameResultsWinnerBonus => 'Winner Bonus';

  @override
  String get gameResultsYouWon => 'You won!';

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
    return '$score pts';
  }

  @override
  String get gameSnapsNoMatch => 'No match';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total pairs found';
  }

  @override
  String get gameSnapsTitle => 'Language Snaps';

  @override
  String get gameSnapsYourTurnFlipCards => 'YOUR TURN — Flip 2 cards!';

  @override
  String get gameSomeone => 'Someone';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Name a word starting with \"$letter\"';
  }

  @override
  String get gameTapplesPickLetterFromWheel => 'Pick a letter from the wheel!';

  @override
  String get gameTapplesPickLetterNameWord => 'Pick a letter, name a word';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name lost a life';
  }

  @override
  String get gameTapplesTimeUp => 'TIME UP!';

  @override
  String get gameTapplesTitle => 'Language Tapples';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Word starting with \"$letter\"...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount words used  •  $lettersCount letters left';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Correct';

  @override
  String get gameTranslationRaceFirstTo30 => 'First to 30 wins!';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'R$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Translation Race';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Translate to $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'Waiting for others... $answered/$total answered';
  }

  @override
  String get gameWaitForYourTurn => 'Wait for your turn...';

  @override
  String get gameWaiting => 'Waiting';

  @override
  String get gameWaitingCancelReady => 'Cancel Ready';

  @override
  String get gameWaitingCountdownGo => 'GO!';

  @override
  String get gameWaitingDisconnected => 'Disconnected';

  @override
  String get gameWaitingEllipsis => 'Waiting...';

  @override
  String get gameWaitingForPlayers => 'Waiting for Players...';

  @override
  String get gameWaitingGetReady => 'Get Ready...';

  @override
  String get gameWaitingHost => 'HOST';

  @override
  String get gameWaitingInviteCodeCopied => 'Invite code copied!';

  @override
  String get gameWaitingInviteCodeHeader => 'INVITE CODE';

  @override
  String get gameWaitingInvitePlayer => 'Invite Player';

  @override
  String get gameWaitingLeaveRoom => 'Leave Room';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Level $level';
  }

  @override
  String get gameWaitingNotReady => 'Not Ready';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count not ready)';
  }

  @override
  String get gameWaitingPlayersHeader => 'PLAYERS';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count players in room';
  }

  @override
  String get gameWaitingReady => 'Ready';

  @override
  String get gameWaitingReadyUp => 'Ready Up';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count rounds';
  }

  @override
  String get gameWaitingShareCode => 'Share this code with friends to join';

  @override
  String get gameWaitingStartGame => 'Start Game';

  @override
  String get gameWordAlreadyUsed => 'Word already used!';

  @override
  String get gameWordBombBoom => 'BOOM!';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'Word must contain \"$prompt\"';
  }

  @override
  String get gameWordBombReport => 'Report';

  @override
  String get gameWordBombReportContent =>
      'Report this word as invalid or inappropriate.';

  @override
  String gameWordBombReportTitle(String word) {
    return 'Report \"$word\"?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife => 'Time ran out! You lost a life.';

  @override
  String get gameWordBombTitle => 'Word Bomb';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Type a word containing \"$prompt\"...';
  }

  @override
  String get gameWordBombUsedWords => 'Used Words';

  @override
  String get gameWordBombWordReported => 'Word reported';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count words used';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'Word must start with \"$letter\"';
  }

  @override
  String get gameWrong => 'Wrong';

  @override
  String get gameYou => 'You';

  @override
  String get gameYourTurn => 'YOUR TURN!';

  @override
  String get gamificationAchievements => 'Achievements';

  @override
  String get gamificationAll => 'All';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '$name completed!';
  }

  @override
  String get gamificationClaim => 'Claim';

  @override
  String get gamificationClaimReward => 'Claim Reward';

  @override
  String get gamificationCoinsAvailable => 'Coins Available';

  @override
  String get gamificationDaily => 'Daily';

  @override
  String get gamificationDailyChallenges => 'Daily Challenges';

  @override
  String get gamificationDayStreak => 'Day Streak';

  @override
  String get gamificationDone => 'Done';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Earned on $date';
  }

  @override
  String get gamificationEasy => 'Easy';

  @override
  String get gamificationEngagement => 'Engagement';

  @override
  String get gamificationEpic => 'Epic';

  @override
  String get gamificationExperiencePoints => 'Experience Points';

  @override
  String get gamificationGlobal => 'Global';

  @override
  String get gamificationHard => 'Hard';

  @override
  String get gamificationLeaderboard => 'Leaderboard';

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
  String get gamificationLoadingAchievements => 'Loading achievements...';

  @override
  String get gamificationLoadingChallenges => 'Loading challenges...';

  @override
  String get gamificationLoadingRankings => 'Loading rankings...';

  @override
  String get gamificationMedium => 'Medium';

  @override
  String get gamificationMilestones => 'Milestones';

  @override
  String get gamificationMonthly => 'Month';

  @override
  String get gamificationMyProgress => 'My Progress';

  @override
  String get gamificationNoAchievements => 'No achievements found';

  @override
  String get gamificationNoAchievementsInCategory =>
      'No achievements in this category';

  @override
  String get gamificationNoChallenges => 'No challenges available';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'No $type challenges available';
  }

  @override
  String get gamificationNoLeaderboard => 'No leaderboard data';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Premium Member';

  @override
  String get gamificationProgress => 'Progress';

  @override
  String get gamificationRank => 'RANK';

  @override
  String get gamificationRankLabel => 'Rank';

  @override
  String get gamificationRegional => 'Regional';

  @override
  String gamificationReward(Object amount, Object type) {
    return 'Reward: $amount $type';
  }

  @override
  String get gamificationSocial => 'Social';

  @override
  String get gamificationSpecial => 'Special';

  @override
  String get gamificationTotal => 'Total';

  @override
  String get gamificationUnlocked => 'Unlocked';

  @override
  String get gamificationVerifiedUser => 'Verified User';

  @override
  String get gamificationVipMember => 'VIP Member';

  @override
  String get gamificationWeekly => 'Weekly';

  @override
  String get gamificationXpAvailable => 'XP Available';

  @override
  String get gamificationYearly => 'Year';

  @override
  String get gamificationYourPosition => 'Your Position';

  @override
  String get gender => 'Gender';

  @override
  String get getStarted => 'Get Started';

  @override
  String get giftCategoryAll => 'All';

  @override
  String giftFromSender(Object name) {
    return 'From $name';
  }

  @override
  String get giftGetCoins => 'Get Coins';

  @override
  String get giftNoGiftsAvailable => 'No gifts available';

  @override
  String get giftNoGiftsInCategory => 'No gifts in this category';

  @override
  String get giftNoGiftsYet => 'No gifts yet';

  @override
  String get giftNotEnoughCoins => 'Not Enough Coins';

  @override
  String giftPriceCoins(Object price) {
    return '$price coins';
  }

  @override
  String get giftReceivedGifts => 'Received Gifts';

  @override
  String get giftReceivedGiftsEmpty => 'Gifts you receive will appear here';

  @override
  String get giftSendGift => 'Send Gift';

  @override
  String giftSendGiftTo(Object name) {
    return 'Send Gift to $name';
  }

  @override
  String get giftSending => 'Sending...';

  @override
  String giftSentTo(Object name) {
    return 'Gift sent to $name!';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'You have $available coins.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'You need $required coins for this gift.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'You need $shortfall more coins.';
  }

  @override
  String get gold => 'Gold';

  @override
  String get grantAlbumAccess => 'Share my album';

  @override
  String get greatInterestsHelp =>
      'Great! Your interests help us find better matches';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Greetings';

  @override
  String get guideBadge => 'Guide';

  @override
  String get height => 'Height';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get helpOthersFindYou => 'Help others find you on social media';

  @override
  String get hours => 'Hours';

  @override
  String get icebreakersCategoryCompliments => 'Compliments';

  @override
  String get icebreakersCategoryDateIdeas => 'Date Ideas';

  @override
  String get icebreakersCategoryDeep => 'Deep';

  @override
  String get icebreakersCategoryDreams => 'Dreams';

  @override
  String get icebreakersCategoryFood => 'Food';

  @override
  String get icebreakersCategoryFunny => 'Funny';

  @override
  String get icebreakersCategoryHobbies => 'Hobbies';

  @override
  String get icebreakersCategoryHypothetical => 'Hypothetical';

  @override
  String get icebreakersCategoryMovies => 'Movies';

  @override
  String get icebreakersCategoryMusic => 'Music';

  @override
  String get icebreakersCategoryPersonality => 'Personality';

  @override
  String get icebreakersCategoryTravel => 'Travel';

  @override
  String get icebreakersCategoryTwoTruths => 'Two Truths';

  @override
  String get icebreakersCategoryWouldYouRather => 'Would You Rather';

  @override
  String get icebreakersLabel => 'Icebreaker';

  @override
  String get icebreakersNoneInCategory => 'No icebreakers in this category';

  @override
  String get icebreakersQuickAnswers => 'Quick answers:';

  @override
  String get icebreakersSendAnIcebreaker => 'Send an icebreaker';

  @override
  String icebreakersSendTo(Object name) {
    return 'Send to $name';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Send without answer';

  @override
  String get icebreakersTitle => 'Icebreakers';

  @override
  String get idiomsCategory => 'Idioms';

  @override
  String get incognitoMode => 'Incognito Mode';

  @override
  String get incognitoModeDescription => 'Hide your profile from discovery';

  @override
  String get incorrectAnswer => 'Incorrect';

  @override
  String get infoUpdatedMessage => 'Your basic information has been saved';

  @override
  String get infoUpdatedTitle => 'Info Updated!';

  @override
  String get insufficientCoins => 'Insufficient coins';

  @override
  String get insufficientCoinsTitle => 'Insufficient Coins';

  @override
  String get interestArt => 'Art';

  @override
  String get interestBeach => 'Beach';

  @override
  String get interestBeer => 'Beer';

  @override
  String get interestBusiness => 'Business';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestCats => 'Cats';

  @override
  String get interestCoffee => 'Coffee';

  @override
  String get interestCooking => 'Cooking';

  @override
  String get interestCycling => 'Cycling';

  @override
  String get interestDance => 'Dance';

  @override
  String get interestDancing => 'Dancing';

  @override
  String get interestDogs => 'Dogs';

  @override
  String get interestEntrepreneurship => 'Entrepreneurship';

  @override
  String get interestEnvironment => 'Environment';

  @override
  String get interestFashion => 'Fashion';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Food';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestHiking => 'Hiking';

  @override
  String get interestHistory => 'History';

  @override
  String get interestInvesting => 'Investing';

  @override
  String get interestLanguages => 'Languages';

  @override
  String get interestMeditation => 'Meditation';

  @override
  String get interestMountains => 'Mountains';

  @override
  String get interestMovies => 'Movies';

  @override
  String get interestMusic => 'Music';

  @override
  String get interestNature => 'Nature';

  @override
  String get interestPets => 'Pets';

  @override
  String get interestPhotography => 'Photography';

  @override
  String get interestPoetry => 'Poetry';

  @override
  String get interestPolitics => 'Politics';

  @override
  String get interestReading => 'Reading';

  @override
  String get interestRunning => 'Running';

  @override
  String get interestScience => 'Science';

  @override
  String get interestSkiing => 'Skiing';

  @override
  String get interestSnowboarding => 'Snowboarding';

  @override
  String get interestSpirituality => 'Spirituality';

  @override
  String get interestSports => 'Sports';

  @override
  String get interestSurfing => 'Surfing';

  @override
  String get interestSwimming => 'Swimming';

  @override
  String get interestTeaching => 'Teaching';

  @override
  String get interestTechnology => 'Technology';

  @override
  String get interestTravel => 'Travel';

  @override
  String get interestVegan => 'Vegan';

  @override
  String get interestVegetarian => 'Vegetarian';

  @override
  String get interestVolunteering => 'Volunteering';

  @override
  String get interestWine => 'Wine';

  @override
  String get interestWriting => 'Writing';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Interests';

  @override
  String interestsCount(int count) {
    return '$count interests';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max interests selected';
  }

  @override
  String get interestsUpdatedMessage => 'Your interests have been saved';

  @override
  String get interestsUpdatedTitle => 'Interests Updated!';

  @override
  String get invalidWord => 'Invalid word';

  @override
  String get inviteCodeCopied => 'Invite code copied!';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get itsAMatch => 'Start Connecting!';

  @override
  String get joinMessage => 'Join GreenGoChat and find your perfect match';

  @override
  String get keepSwiping => 'Keep Swiping';

  @override
  String get langMatchBadge => 'Lang Match';

  @override
  String get language => 'Language';

  @override
  String languageChangedTo(String language) {
    return 'Language changed to $language';
  }

  @override
  String get languagePacksBtn => 'Language Packs';

  @override
  String get languagePacksShopTitle => 'Language Packs Shop';

  @override
  String get languagesToDownloadLabel => 'Languages to download:';

  @override
  String get lastName => 'Last Name';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get leaderboardSubtitle => 'See global and regional rankings';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get learn => 'Learn';

  @override
  String get learningAccuracy => 'Accuracy';

  @override
  String get learningActiveThisWeek => 'Active This Week';

  @override
  String get learningAddLessonSection => 'Add Lesson Section';

  @override
  String get learningAiConversationCoach => 'AI Conversation Coach';

  @override
  String get learningAllCategories => 'All Categories';

  @override
  String get learningAllLessons => 'All Lessons';

  @override
  String get learningAllLevels => 'All Levels';

  @override
  String get learningAmount => 'Amount';

  @override
  String get learningAmountLabel => 'Amount';

  @override
  String get learningAnalytics => 'Analytics';

  @override
  String learningAnswer(Object answer) {
    return 'Answer: $answer';
  }

  @override
  String get learningApplyFilters => 'Apply Filters';

  @override
  String get learningAreasToImprove => 'Areas to Improve';

  @override
  String get learningAvailableBalance => 'Available Balance';

  @override
  String get learningAverageRating => 'Average Rating';

  @override
  String get learningBeginnerProgress => 'Beginner Progress';

  @override
  String get learningBonusCoins => 'Bonus Coins';

  @override
  String get learningCategory => 'Category';

  @override
  String get learningCategoryProgress => 'Category Progress';

  @override
  String get learningCheck => 'Check';

  @override
  String get learningCheckBackSoon => 'Check back soon!';

  @override
  String get learningCoachSessionCost => '10 coins/session  |  25 XP reward';

  @override
  String get learningContinue => 'Continue';

  @override
  String get learningCorrect => 'Correct!';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Correct: $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get learningCorrectAnswers => 'Correct Answers';

  @override
  String get learningCorrectLabel => 'Correct';

  @override
  String get learningCorrections => 'Corrections';

  @override
  String get learningCreateLesson => 'Create Lesson';

  @override
  String get learningCreateNewLesson => 'Create New Lesson';

  @override
  String get learningCustomPackTitleHint =>
      'e.g., \"Spanish Greetings for Dating\"';

  @override
  String get learningDescribeImage => 'Describe this image';

  @override
  String get learningDescriptionHint => 'What will students learn?';

  @override
  String get learningDescriptionLabel => 'Description';

  @override
  String get learningDifficultyLevel => 'Difficulty Level';

  @override
  String get learningDone => 'Done';

  @override
  String get learningDraftSave => 'Save Draft';

  @override
  String get learningDraftSaved => 'Draft saved!';

  @override
  String get learningEarned => 'Earned';

  @override
  String get learningEdit => 'Edit';

  @override
  String get learningEndSession => 'End Session';

  @override
  String get learningEndSessionBody =>
      'Your current session progress will be lost. Would you like to end the session and see your score first?';

  @override
  String get learningEndSessionQuestion => 'End Session?';

  @override
  String get learningExit => 'Exit';

  @override
  String get learningFalse => 'False';

  @override
  String get learningFilterAll => 'All';

  @override
  String get learningFilterDraft => 'Draft';

  @override
  String get learningFilterLessons => 'Filter Lessons';

  @override
  String get learningFilterPublished => 'Published';

  @override
  String get learningFilterUnderReview => 'Under Review';

  @override
  String get learningFluency => 'Fluency';

  @override
  String get learningFree => 'FREE';

  @override
  String get learningGoBack => 'Go Back';

  @override
  String get learningGoalCompleteLessons => 'Complete 5 lessons';

  @override
  String get learningGoalEarnXp => 'Earn 500 XP';

  @override
  String get learningGoalPracticeMinutes => 'Practice 30 minutes';

  @override
  String get learningGrammar => 'Grammar';

  @override
  String get learningHint => 'Hint';

  @override
  String get learningLangBrazilianPortuguese => 'Brazilian Portuguese';

  @override
  String get learningLangEnglish => 'English';

  @override
  String get learningLangFrench => 'French';

  @override
  String get learningLangGerman => 'German';

  @override
  String get learningLangItalian => 'Italian';

  @override
  String get learningLangPortuguese => 'Portuguese';

  @override
  String get learningLangSpanish => 'Spanish';

  @override
  String get learningLanguagesSubtitle =>
      'Select up to 5 languages. This helps us connect you with native speakers and learning partners.';

  @override
  String get learningLanguagesTitle => 'What languages do you want to learn?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Languages to learn ($count/5)';
  }

  @override
  String get learningLastMonth => 'Last Month';

  @override
  String learningLearnLanguage(Object language) {
    return 'Learn $language';
  }

  @override
  String get learningLearned => 'Learned';

  @override
  String get learningLessonComplete => 'Lesson Complete!';

  @override
  String get learningLessonCompleteUpper => 'LESSON COMPLETE!';

  @override
  String get learningLessonContent => 'Lesson Content';

  @override
  String learningLessonNumber(Object number) {
    return 'Lesson $number';
  }

  @override
  String get learningLessonSubmitted => 'Lesson submitted for review!';

  @override
  String get learningLessonTitle => 'Lesson Title';

  @override
  String get learningLessonTitleHint =>
      'e.g., \"Spanish Greetings for Dating\"';

  @override
  String get learningLessonTitleLabel => 'Lesson Title';

  @override
  String get learningLessonsLabel => 'Lessons';

  @override
  String get learningLetsStart => 'Let\'s Start!';

  @override
  String get learningLevel => 'Level';

  @override
  String learningLevelBadge(Object level) {
    return 'LV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Level $level';
  }

  @override
  String get learningListen => 'Listen';

  @override
  String get learningListening => 'Listening...';

  @override
  String get learningLongPressForTranslation => 'Long-press for translation';

  @override
  String get learningMessages => 'Messages';

  @override
  String get learningMessagesSent => 'Messages sent';

  @override
  String get learningMinimumWithdrawal => 'Minimum withdrawal: \$50.00';

  @override
  String get learningMonthlyEarnings => 'Monthly Earnings';

  @override
  String get learningMyProgress => 'My Progress';

  @override
  String get learningNativeLabel => '(native)';

  @override
  String get learningNativeLanguage => 'Your native language';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'You need at least $threshold% to pass this lesson.';
  }

  @override
  String get learningNext => 'Next';

  @override
  String get learningNoExercisesInSection => 'No exercises in this section';

  @override
  String get learningNoLessonsAvailable => 'No lessons available yet';

  @override
  String get learningNoPacksFound => 'No packs found';

  @override
  String get learningNoQuestionsAvailable => 'No questions available yet.';

  @override
  String get learningNotQuite => 'Not quite';

  @override
  String get learningNotQuiteTitle => 'Not Quite There...';

  @override
  String get learningOpenAiCoach => 'Open AI Coach';

  @override
  String learningPackFilter(Object category) {
    return 'Pack: $category';
  }

  @override
  String get learningPackPurchased => 'Pack purchased successfully!';

  @override
  String get learningPassageRevealed => 'Passage (revealed)';

  @override
  String get learningPathTitle => 'Learning Path';

  @override
  String get learningPlaying => 'Playing...';

  @override
  String get learningPleaseEnterDescription => 'Please enter a description';

  @override
  String get learningPleaseEnterTitle => 'Please enter a title';

  @override
  String get learningPracticeAgain => 'Practice Again';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Published Lessons';

  @override
  String get learningPurchased => 'Purchased';

  @override
  String get learningPurchasedLessonsEmpty =>
      'Your purchased lessons will appear here';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count questions in this lesson';
  }

  @override
  String get learningQuickActions => 'Quick Actions';

  @override
  String get learningReadPassage => 'Read the passage';

  @override
  String get learningRecentActivity => 'Recent Activity';

  @override
  String get learningRecentMilestones => 'Recent Milestones';

  @override
  String get learningRecentTransactions => 'Recent Transactions';

  @override
  String get learningRequired => 'Required';

  @override
  String get learningResponseRecorded => 'Response recorded';

  @override
  String get learningReview => 'Review';

  @override
  String get learningSearchLanguages => 'Search languages...';

  @override
  String get learningSectionEditorComingSoon => 'Section editor coming soon!';

  @override
  String get learningSeeScore => 'See Score';

  @override
  String get learningSelectNativeLanguage => 'Select your native language';

  @override
  String get learningSelectScenario => 'Select a scenario to begin';

  @override
  String get learningSelectScenarioFirst => 'Select a scenario first...';

  @override
  String get learningSessionComplete => 'Session Complete!';

  @override
  String get learningSessionSummary => 'Session Summary';

  @override
  String get learningShowAll => 'Show All';

  @override
  String get learningShowPassageText => 'Show passage text';

  @override
  String get learningSkip => 'Skip';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return 'Spend $price coins to unlock this lesson?';
  }

  @override
  String get learningStartFlashcards => 'Start Flashcards';

  @override
  String get learningStartLesson => 'Start Lesson';

  @override
  String get learningStartPractice => 'Start Practice';

  @override
  String get learningStartQuiz => 'Start Quiz';

  @override
  String get learningStartingLesson => 'Starting lesson...';

  @override
  String get learningStop => 'Stop';

  @override
  String get learningStreak => 'Streak';

  @override
  String get learningStrengths => 'Strengths';

  @override
  String get learningSubmit => 'Submit';

  @override
  String get learningSubmitForReview => 'Submit for Review';

  @override
  String get learningSubmitForReviewBody =>
      'Your lesson will be reviewed by our team before it goes live. This usually takes 24-48 hours.';

  @override
  String get learningSubmitForReviewQuestion => 'Submit for Review?';

  @override
  String get learningTabAllLessons => 'All Lessons';

  @override
  String get learningTabEarnings => 'Earnings';

  @override
  String get learningTabFlashcards => 'Flashcards';

  @override
  String get learningTabLessons => 'Lessons';

  @override
  String get learningTabMyLessons => 'My Lessons';

  @override
  String get learningTabMyProgress => 'My Progress';

  @override
  String get learningTabOverview => 'Overview';

  @override
  String get learningTabPhrases => 'Phrases';

  @override
  String get learningTabProgress => 'Progress';

  @override
  String get learningTabPurchased => 'Purchased';

  @override
  String get learningTabQuizzes => 'Quizzes';

  @override
  String get learningTabStudents => 'Students';

  @override
  String get learningTapToContinue => 'Tap to continue';

  @override
  String get learningTapToHearPassage => 'Tap to hear the passage';

  @override
  String get learningTapToListen => 'Tap to listen';

  @override
  String get learningTapToMatch => 'Tap items to match them';

  @override
  String get learningTapToRevealTranslation => 'Tap to reveal translation';

  @override
  String get learningTapWordsToBuild => 'Tap words below to build the sentence';

  @override
  String get learningTargetLanguage => 'Target Language';

  @override
  String get learningTeacherDashboardTitle => 'Teacher Dashboard';

  @override
  String get learningTeacherTiers => 'Teacher Tiers';

  @override
  String get learningThisMonth => 'This Month';

  @override
  String get learningTopPerformingStudents => 'Top Performing Students';

  @override
  String get learningTotalStudents => 'Total Students';

  @override
  String get learningTotalStudentsLabel => 'Total Students';

  @override
  String get learningTotalXp => 'Total XP';

  @override
  String get learningTranslatePhrase => 'Translate this phrase';

  @override
  String get learningTrue => 'True';

  @override
  String get learningTryAgain => 'Try Again';

  @override
  String get learningTypeAnswerBelow => 'Type your answer below';

  @override
  String get learningTypeAnswerHint => 'Type your answer...';

  @override
  String get learningTypeDescriptionHint => 'Type your description...';

  @override
  String get learningTypeMessageHint => 'Type your message...';

  @override
  String get learningTypeMissingWordHint => 'Type the missing word...';

  @override
  String get learningTypeSentenceHint => 'Type the sentence...';

  @override
  String get learningTypeTranslationHint => 'Type your translation...';

  @override
  String get learningTypeWhatYouHeardHint => 'Type what you heard...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Unit $unit - Lesson $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Unit $number';
  }

  @override
  String get learningUnlock => 'Unlock';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Unlock for $price Coins';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Unlock for $price coins';
  }

  @override
  String get learningUnlockLesson => 'Unlock Lesson';

  @override
  String get learningViewAll => 'View All';

  @override
  String get learningViewAnalytics => 'View Analytics';

  @override
  String get learningVocabulary => 'Vocabulary';

  @override
  String learningWeek(Object week) {
    return 'Week $week';
  }

  @override
  String get learningWeeklyGoals => 'Weekly Goals';

  @override
  String get learningWhatWillStudentsLearnHint => 'What will students learn?';

  @override
  String get learningWhatYouWillLearn => 'What you will learn';

  @override
  String get learningWithdraw => 'Withdraw';

  @override
  String get learningWithdrawFunds => 'Withdraw Funds';

  @override
  String get learningWithdrawalSubmitted => 'Withdrawal request submitted!';

  @override
  String get learningWordsAndPhrases => 'Words & Phrases';

  @override
  String get learningWriteAnswerFreely => 'Write your answer freely';

  @override
  String get learningWriteAnswerHint => 'Write your answer...';

  @override
  String get learningXpEarned => 'XP Earned';

  @override
  String learningYourAnswer(Object answer) {
    return 'Your answer: $answer';
  }

  @override
  String get learningYourScore => 'Your Score';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Lesson';

  @override
  String get letsChat => 'Let\'s Chat!';

  @override
  String get letsExchange => 'Start Connecting!';

  @override
  String get levelLabel => 'Level';

  @override
  String levelLabelN(String level) {
    return 'Level $level';
  }

  @override
  String get levelTitleEnthusiast => 'Enthusiast';

  @override
  String get levelTitleExpert => 'Expert';

  @override
  String get levelTitleExplorer => 'Explorer';

  @override
  String get levelTitleLegend => 'Legend';

  @override
  String get levelTitleMaster => 'Master';

  @override
  String get levelTitleNewcomer => 'Newcomer';

  @override
  String get levelTitleVeteran => 'Veteran';

  @override
  String get levelUp => 'LEVEL UP!';

  @override
  String get levelUpCongratulations =>
      'Congratulations on reaching a new level!';

  @override
  String get levelUpContinue => 'Continue';

  @override
  String get levelUpRewards => 'REWARDS';

  @override
  String get levelUpTitle => 'LEVEL UP!';

  @override
  String get levelUpVIPUnlocked => 'VIP Status Unlocked!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'You reached Level $level';
  }

  @override
  String get likes => 'Likes';

  @override
  String get limitReachedTitle => 'Limit Reached';

  @override
  String get listenMe => 'Listen me!';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get localGuideBadge => 'Local Guide';

  @override
  String get location => 'Location';

  @override
  String get locationAndLanguages => 'Location & Languages';

  @override
  String get locationError => 'Location Error';

  @override
  String get locationNotFound => 'Location Not Found';

  @override
  String get locationNotFoundMessage =>
      'We could not determine your address. Please try again or set your location manually later.';

  @override
  String get locationPermissionDenied => 'Permission Denied';

  @override
  String get locationPermissionDeniedMessage =>
      'Location permission is required to detect your current location. Please grant permission to continue.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permission Permanently Denied';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'Location permission has been permanently denied. Please enable it in your device settings to use this feature.';

  @override
  String get locationRequestTimeout => 'Request Timeout';

  @override
  String get locationRequestTimeoutMessage =>
      'Getting your location took too long. Please check your connection and try again.';

  @override
  String get locationServicesDisabled => 'Location Services Disabled';

  @override
  String get locationServicesDisabledMessage =>
      'Please enable location services in your device settings to use this feature.';

  @override
  String get locationUnavailable =>
      'Unable to get your location at the moment. You can set it manually later in settings.';

  @override
  String get locationUnavailableTitle => 'Location Unavailable';

  @override
  String get locationUpdatedMessage => 'Your location settings have been saved';

  @override
  String get locationUpdatedTitle => 'Location Updated!';

  @override
  String get logOut => 'Log Out';

  @override
  String get logOutConfirmation => 'Are you sure you want to log out?';

  @override
  String get login => 'Login';

  @override
  String get loginWithBiometrics => 'Login with Biometrics';

  @override
  String get logout => 'Logout';

  @override
  String get longTermRelationship => 'Long-term relationship';

  @override
  String get lookingFor => 'Looking for';

  @override
  String get lvl => 'LVL';

  @override
  String get manageCouponsTiersRules => 'Manage coupons, tiers & rules';

  @override
  String get matchDetailsTitle => 'Exchange Details';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'You and $name want to exchange languages!';
  }

  @override
  String get matchNotifKeepSwiping => 'Keep Swiping';

  @override
  String get matchNotifLetsChat => 'Let\'s Chat!';

  @override
  String get matchNotifLetsExchange => 'START CONNECTING!';

  @override
  String get matchNotifViewProfile => 'View Profile';

  @override
  String matchPercentage(String percentage) {
    return '$percentage match';
  }

  @override
  String matchedOnDate(String date) {
    return 'Matched on $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'You matched with $name on $date';
  }

  @override
  String get matches => 'Matches';

  @override
  String get matchesClearFilters => 'Clear Filters';

  @override
  String matchesCount(int count) {
    return '$count matches';
  }

  @override
  String get matchesFilterAll => 'All';

  @override
  String get matchesFilterMessaged => 'Messaged';

  @override
  String get matchesFilterNew => 'New';

  @override
  String get matchesNoMatchesFound => 'No matches found';

  @override
  String get matchesNoMatchesYet => 'No matches yet';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered of $total matches';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered of $total matches';
  }

  @override
  String get matchesStartSwiping => 'Start swiping to find your matches!';

  @override
  String get matchesTryDifferent => 'Try a different search or filter';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Maximum $count interests allowed';
  }

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get discoverWorldwideTitle => 'Expand your horizons!';

  @override
  String get discoverWorldwideMessage =>
      'There aren\'t many people in your country yet, so we\'re also showing you people from other countries close to you and around the world. The more you explore, the more connections you\'ll find!';

  @override
  String get openFilters => 'Open Filters';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return '$tierName membership active until $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => 'Membership Activated!';

  @override
  String get membershipAdvancedFilters => 'Advanced Filters';

  @override
  String get membershipBase => 'Base';

  @override
  String get membershipBaseMembership => 'Base Membership';

  @override
  String get membershipBestValue => 'Best value for long-term commitment!';

  @override
  String get membershipBoostsMonth => 'Boosts/month';

  @override
  String get membershipBuyTitle => 'Buy Membership';

  @override
  String get membershipCouponCodeLabel => 'Coupon Code *';

  @override
  String get membershipCouponHint => 'e.g., GOLD2024';

  @override
  String get membershipCurrent => 'Current Membership';

  @override
  String get membershipDailyLikes => 'Daily Connects';

  @override
  String get membershipDailyMessagesLabel =>
      'Daily Messages (empty = unlimited)';

  @override
  String get membershipDailySwipesLabel => 'Daily Swipes (empty = unlimited)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days days remaining';
  }

  @override
  String get membershipDurationLabel => 'Duration (days)';

  @override
  String get membershipEnterCouponHint => 'Enter coupon code';

  @override
  String get couponRedeemTitle => 'Redeem Coupon Code';

  @override
  String get referralCodeTitle => 'Have a referral code?';

  @override
  String get referralCodeLabel => 'Referral code (optional)';

  @override
  String get referralCodeHint => 'Enter a friend s code';

  @override
  String get couponApplyButton => 'Apply';

  @override
  String get couponAppliedSuccess => 'Coupon Applied';

  @override
  String get couponNotValid => 'Coupon not Valid';

  @override
  String get freeBaseWeekInfo =>
      'No coupon needed — you still get 1 week of Base membership free!';

  @override
  String get couponRedeemSubtitle =>
      'Enter your code to upgrade your membership or get free coins';

  @override
  String get couponRedeemButton => 'Redeem Coupon';

  @override
  String couponRedeemedSuccess(String grantSummary) {
    return 'Redeemed: $grantSummary';
  }

  @override
  String get couponErrorInvalid => 'This coupon code is not valid';

  @override
  String get couponErrorExpired => 'This coupon has expired';

  @override
  String get couponErrorMaxUsesReached =>
      'This coupon has reached its usage limit';

  @override
  String get couponErrorEmailMismatch =>
      'This coupon is restricted to a different account';

  @override
  String get couponErrorAlreadyRedeemed => 'You have already used this coupon';

  @override
  String get couponErrorDisabled => 'This coupon is no longer active';

  @override
  String get couponErrorGeneric => 'Could not redeem coupon. Please try again.';

  @override
  String get registerCouponLabel => 'Coupon code (optional)';

  @override
  String get registerCouponHint => 'Enter a coupon code';

  @override
  String get welcomeGrantTitle => 'Welcome to GreenGo!';

  @override
  String get welcomeGrantDismiss => 'Got it';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Equivalent to $price/month';
  }

  @override
  String get membershipErrorLoadingData => 'Error loading data';

  @override
  String membershipExpires(Object date) {
    return 'Expires: $date';
  }

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get subscriptionAutoRenewInfo =>
      'Auto-renews unless canceled 24h before the period ends. Manage in your store account.';

  @override
  String get subscriptionFreeTrialInfo =>
      'New subscribers: 7 days free, then renews at the price shown. Cancel 24h before it ends.';

  @override
  String get purchasesRestored => 'Purchases restored.';

  @override
  String get membershipExtendTitle => 'Extend Your Membership';

  @override
  String get membershipFeatureComparison => 'Feature Comparison';

  @override
  String get membershipGeneric => 'Membership';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Base';

  @override
  String get membershipIncognitoMode => 'Incognito Mode';

  @override
  String get membershipLeaveEmptyLifetime => 'Leave empty for lifetime';

  @override
  String get membershipLeaveEmptyUnlimited => 'Leave empty for unlimited';

  @override
  String get membershipLowerThanCurrent => 'Lower than your current tier';

  @override
  String get membershipMaxUsesLabel => 'Max Uses';

  @override
  String get membershipMonthly => 'Monthly Memberships';

  @override
  String get membershipNameDescriptionLabel => 'Name/Description';

  @override
  String get membershipActive => 'Active';

  @override
  String get membershipNoActive => 'No active membership';

  @override
  String get membershipNotesLabel => 'Notes';

  @override
  String get membershipOneMonth => '1 month';

  @override
  String get membershipOneYear => '1 year';

  @override
  String get membershipPanel => 'Membership Panel';

  @override
  String get membershipPermanent => 'Permanent';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 COINS';

  @override
  String get membershipPrioritySupport => 'Priority Support';

  @override
  String get membershipReadReceipts => 'Read Receipts';

  @override
  String get membershipRequired => 'Membership Required';

  @override
  String get membershipRequiredDescription =>
      'You need to be a member of GreenGo to perform this action.';

  @override
  String get membershipExtendDescription =>
      'Your base membership is active. Purchase another year to extend your expiration date.';

  @override
  String get membershipRewinds => 'Rewinds';

  @override
  String membershipSavePercent(Object percent) {
    return 'SAVE $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'See Who Connects';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Buy once, enjoy premium features for 1 month or 1 year';

  @override
  String get membershipSuperLikes => 'Priority Connects';

  @override
  String get membershipSuperLikesLabel =>
      'Priority Connects/Day (empty = unlimited)';

  @override
  String get membershipTerms =>
      'One-time purchase. Membership will be extended from your current end date.';

  @override
  String get membershipTermsExtended =>
      'One-time purchase. Membership will be extended from your current end date. Higher tier purchases override lower tiers.';

  @override
  String get membershipTierLabel => 'Membership Tier *';

  @override
  String membershipTierName(Object tierName) {
    return '$tierName Membership';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Yearly Memberships (Save up to $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'You have $tierName';
  }

  @override
  String get menu => 'Menu';

  @override
  String socialLinkInvalid(String platform) {
    return 'Enter a valid link or handle for $platform';
  }

  @override
  String get messages => 'Exchanges';

  @override
  String get messagesTabMessages => 'Messages';

  @override
  String get messagesTabGroups => 'Groups';

  @override
  String get messagesTabBusiness => 'Business';

  @override
  String get messagesBusinessEmpty => 'No storefront inquiries yet';

  @override
  String get minutes => 'Minutes';

  @override
  String moreAchievements(int count) {
    return '+$count more achievements';
  }

  @override
  String get myBadges => 'My Badges';

  @override
  String get myProgress => 'My Progress';

  @override
  String get myUsage => 'My Usage';

  @override
  String get navLearn => 'Learn';

  @override
  String get navPlay => 'Play';

  @override
  String get nearby => 'Nearby';

  @override
  String needCoinsForProfiles(int amount) {
    return 'You need $amount coins to unlock more profiles.';
  }

  @override
  String get newLabel => 'NEW';

  @override
  String get next => 'Next';

  @override
  String nextLevelXp(String xp) {
    return 'Next level in $xp XP';
  }

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameAlreadyTaken => 'This nickname is already taken';

  @override
  String get nicknameCheckError => 'Error checking availability';

  @override
  String nicknameInfoText(String nickname) {
    return 'Your nickname is unique and can be used to find you. Others can search for you using @$nickname';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Must be 3-20 characters';

  @override
  String get nicknameNoConsecutiveUnderscores => 'No consecutive underscores';

  @override
  String get nicknameNoReservedWords => 'Cannot contain reserved words';

  @override
  String get nicknameOnlyAlphanumeric =>
      'Only letters, numbers, and underscores';

  @override
  String get nicknameRequirements =>
      '3-20 characters. Letters, numbers, and underscores only.';

  @override
  String get nicknameRules => 'Nickname Rules';

  @override
  String get nicknameSearchChat => 'Chat';

  @override
  String get nicknameSearchError => 'Error searching. Please try again.';

  @override
  String get nicknameSearchHelp => 'Enter a nickname to find someone directly';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'No profile found with @$nickname';
  }

  @override
  String get nicknameSearchOwnProfile => 'That\'s your own profile!';

  @override
  String get nicknameSearchTitle => 'Search by Nickname';

  @override
  String get nicknameSearchView => 'View';

  @override
  String nicknameSearchActionNope(String nickname) {
    return 'You just selected \"Nope\" for @$nickname';
  }

  @override
  String nicknameSearchActionSkip(String nickname) {
    return 'You just selected \"Skip\" for @$nickname';
  }

  @override
  String nicknameSearchActionPriorityConnect(String nickname) {
    return 'You just selected \"Priority Connect\" for @$nickname';
  }

  @override
  String nicknameSearchActionConnect(String nickname) {
    return 'You just selected \"Let\'s Connect\" for @$nickname';
  }

  @override
  String nicknameSearchActionMatch(String nickname) {
    return 'It\'s a match with @$nickname!';
  }

  @override
  String nicknameSearchLimitReached(String action) {
    return 'You\'ve reached your $action limit. Try again later.';
  }

  @override
  String get nicknameStartWithLetter => 'Start with a letter';

  @override
  String get nicknameUpdatedMessage => 'Your new nickname is now active';

  @override
  String get nicknameUpdatedSuccess => 'Nickname updated successfully';

  @override
  String get nicknameUpdatedTitle => 'Nickname Updated!';

  @override
  String get no => 'No';

  @override
  String get noActiveGamesLabel => 'No active games';

  @override
  String get noBadgesEarnedYet => 'No badges earned yet';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get noLanguagesYet => 'No languages yet. Start learning!';

  @override
  String get noLeaderboardData => 'No leaderboard data yet';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get noMoreProfiles => 'No more profiles to show';

  @override
  String get noOthersToSee => 'There\'s no others to see';

  @override
  String get noPendingVerifications => 'No pending verifications';

  @override
  String get noPhotoSubmitted => 'No photo submitted';

  @override
  String get noPreviousProfile => 'No previous profile to rewind';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'No profile found with @$nickname';
  }

  @override
  String get noResults => 'No results';

  @override
  String get noSocialProfilesLinked => 'No social profiles linked';

  @override
  String get noVoiceRecording => 'No voice recording';

  @override
  String get nodeAvailable => 'Available';

  @override
  String get nodeCompleted => 'Completed';

  @override
  String get nodeInProgress => 'In Progress';

  @override
  String get nodeLocked => 'Locked';

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String get notNow => 'Not Now';

  @override
  String get notSet => 'Not set';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Achievement Unlocked: $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'You successfully purchased $amount coins.';
  }

  @override
  String get notificationDialogEnable => 'Enable';

  @override
  String get notificationDialogMessage =>
      'Enable notifications to know when you get matches, messages, and priority connects.';

  @override
  String get notificationDialogNotNow => 'Not Now';

  @override
  String get notificationDialogTitle => 'Stay Connected';

  @override
  String get notificationEmailSubtitle => 'Receive notifications via email';

  @override
  String get notificationEmailTitle => 'Email Notifications';

  @override
  String get notificationEnableQuietHours => 'Enable Quiet Hours';

  @override
  String get notificationEndTime => 'End Time';

  @override
  String get notificationMasterControls => 'Master Controls';

  @override
  String get notificationMatchExpiring => 'Match Expiring';

  @override
  String get notificationMatchExpiringSubtitle =>
      'When a match is about to expire';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname started a conversation with you.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'You received a like from @$nickname';
  }

  @override
  String get notificationNewLikes => 'New Likes';

  @override
  String get notificationNewLikesSubtitle => 'When someone likes you';

  @override
  String notificationNewMatch(String nickname) {
    return 'It\'s a Match! You matched with @$nickname. Start chatting now.';
  }

  @override
  String get notificationNewMatches => 'New Matches';

  @override
  String get notificationNewMatchesSubtitle => 'When you get a new match';

  @override
  String notificationNewMessage(String nickname) {
    return 'New message from @$nickname';
  }

  @override
  String get notificationNewMessages => 'New Messages';

  @override
  String get notificationNewMessagesSubtitle =>
      'When someone sends you a message';

  @override
  String get notificationProfileViews => 'Profile Views';

  @override
  String get notificationProfileViewsSubtitle =>
      'When someone views your profile';

  @override
  String get notificationPromotional => 'Promotional';

  @override
  String get notificationPromotionalSubtitle => 'Tips, offers, and promotions';

  @override
  String get notificationPushSubtitle => 'Receive notifications on this device';

  @override
  String get notificationPushTitle => 'Push Notifications';

  @override
  String get notificationQuietHours => 'Quiet Hours';

  @override
  String get notificationQuietHoursDescription =>
      'Mute notifications between set times';

  @override
  String get notificationQuietHoursSubtitle =>
      'Mute notifications during certain hours';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get notificationCategories => 'Notification categories';

  @override
  String get notificationCatExchanges => 'Exchange chats';

  @override
  String get notificationCatExchangesSubtitle =>
      'Messages from your 1:1 exchanges';

  @override
  String get notificationCatGroups => 'Group chats';

  @override
  String get notificationCatGroupsSubtitle => 'Messages in your group chats';

  @override
  String get notificationCatBusiness => 'Business chats';

  @override
  String get notificationCatBusinessSubtitle =>
      'Messages from businesses you contact';

  @override
  String get notificationCatEventsChat => 'Event chats';

  @override
  String get notificationCatEventsChatSubtitle =>
      'Messages inside events you joined';

  @override
  String get notificationCatCommunityChat => 'Community chats';

  @override
  String get notificationCatCommunityChatSubtitle =>
      'Messages in the community chat';

  @override
  String get notificationCatAnnouncements => 'Announcements & events';

  @override
  String get notificationCatAnnouncementsSubtitle =>
      'Community announcements and events';

  @override
  String get notificationCatTips => 'Tips';

  @override
  String get notificationCatTipsSubtitle => 'Community tips and suggestions';

  @override
  String get notificationCatMessages => 'Messages';

  @override
  String get notificationCatMessagesSubtitle =>
      'Direct, group, business and event chats';

  @override
  String get notificationCatEvents => 'Events';

  @override
  String get notificationCatEventsSubtitle =>
      'Events, reminders, RSVPs and city alerts';

  @override
  String get notificationCatCommunities => 'Communities';

  @override
  String get notificationCatCommunitiesSubtitle =>
      'Announcements and new members';

  @override
  String get notificationCatSocial => 'Social';

  @override
  String get notificationCatSocialSubtitle =>
      'Profile views, follows, ratings and boosts';

  @override
  String get notificationCatAccount => 'Account';

  @override
  String get notificationCatAccountSubtitle =>
      'Verification and important account updates';

  @override
  String get notificationEventCities => 'Community events by city';

  @override
  String get notificationEventCitiesSubtitle =>
      'Get notified when events are happening in these cities';

  @override
  String get notificationAddCity => 'Add a city';

  @override
  String get notificationAddCityHint => 'e.g. Rome';

  @override
  String get notificationNoCities =>
      'No cities yet — add one to get event alerts';

  @override
  String get notificationEnableInSettingsBody =>
      'Notifications are off. Turn them on in Settings to get messages, events and community alerts.';

  @override
  String get notificationOpenSettings => 'Open Settings';

  @override
  String get notificationSound => 'Sound';

  @override
  String get notificationSoundSubtitle => 'Play sound for notifications';

  @override
  String get notificationSoundVibration => 'Sound & Vibration';

  @override
  String get notificationStartTime => 'Start Time';

  @override
  String notificationSuperLike(String nickname) {
    return 'You received a priority connect from @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Priority Connects';

  @override
  String get notificationSuperLikesSubtitle =>
      'When someone priority connects with you';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get notificationVibration => 'Vibration';

  @override
  String get notificationVibrationSubtitle => 'Vibrate for notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptySubtitle =>
      'When you get notifications, they\'ll show up here';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get occupation => 'Occupation';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Add Photo';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Add photos that represent the real you';

  @override
  String get onboardingAiVerifiedDescription =>
      'Your photos are verified using AI to ensure authenticity';

  @override
  String get onboardingAiVerifiedPhotos => 'AI Verified Photos';

  @override
  String get onboardingBioHint =>
      'Tell us about your interests, the languages you speak, and the cultures you\'d love to explore...';

  @override
  String get onboardingBioMinLength => 'Bio must be at least 50 characters';

  @override
  String get onboardingChooseFromGallery => 'Choose from Gallery';

  @override
  String get onboardingCompleteAllFields => 'Please complete all fields';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingDateOfBirth => 'Date of Birth';

  @override
  String get onboardingDisplayName => 'Display Name';

  @override
  String get onboardingDisplayNameHint => 'How should we call you?';

  @override
  String get onboardingEnterYourName => 'Please enter your name';

  @override
  String get onboardingExpressYourself => 'Express yourself';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Write something that captures who you are';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'Failed to pick image: $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'Failed to take photo: $error';
  }

  @override
  String get onboardingGenderFemale => 'Female';

  @override
  String get onboardingGenderMale => 'Male';

  @override
  String get onboardingGenderNonBinary => 'Non-binary';

  @override
  String get onboardingGenderOther => 'Other';

  @override
  String get onboardingHoldIdNextToFace => 'Hold your ID next to your face';

  @override
  String get onboardingIdentifyAs => 'I identify as';

  @override
  String get onboardingInterestsHelpMatches =>
      'Your interests help us connect you with people who share your culture and languages';

  @override
  String get onboardingInterestsSubtitle =>
      'Select at least 3 interests (max 10)';

  @override
  String get onboardingLanguages => 'Languages';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 selected';
  }

  @override
  String get onboardingLetsGetStarted => 'Let\'s get started';

  @override
  String get onboardingLocation => 'Location';

  @override
  String get onboardingLocationLater =>
      'You can set your location later in settings';

  @override
  String get onboardingMainPhoto => 'MAIN';

  @override
  String get onboardingMaxInterests => 'You can select up to 10 interests';

  @override
  String get onboardingMaxLanguages => 'You can select up to 3 languages';

  @override
  String get onboardingMinInterests => 'Please select at least 3 interests';

  @override
  String get onboardingMinLanguage => 'Please select at least one language';

  @override
  String get onboardingMinLocation => 'Please set your location to continue';

  @override
  String get onboardingNameMinLength => 'Name must be at least 2 characters';

  @override
  String get onboardingNoLocationSelected => 'No location selected';

  @override
  String get onboardingOptional => 'Optional';

  @override
  String get onboardingSelectFromPhotos => 'Select from your photos';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 selected';
  }

  @override
  String get onboardingShowYourself => 'Show yourself';

  @override
  String get onboardingTakePhoto => 'Take Photo';

  @override
  String get onboardingTellUsAboutYourself => 'Tell us a bit about yourself';

  @override
  String get onboardingTipAuthentic => 'Be authentic and genuine';

  @override
  String get onboardingTipPassions => 'Share your passions and hobbies';

  @override
  String get onboardingTipPositive => 'Keep it positive';

  @override
  String get onboardingTipUnique => 'What makes you unique?';

  @override
  String get onboardingUploadAtLeastOnePhoto =>
      'Please upload at least one photo';

  @override
  String get onboardingUseCurrentLocation => 'Use Current Location';

  @override
  String get onboardingUseYourCamera => 'Use your camera';

  @override
  String get onboardingWhereAreYou => 'Where are you?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Set your preferred languages and location (optional)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Please write something about yourself';

  @override
  String get onboardingWritingTips => 'Writing tips';

  @override
  String get onboardingYourInterests => 'Your interests';

  @override
  String oneTimeDownloadSize(int size) {
    return 'This is a one-time download of approximately ${size}MB.';
  }

  @override
  String get optionalConsents => 'Optional Consents';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get origin => 'Origin';

  @override
  String packFocusMode(String packName) {
    return 'Pack: $packName';
  }

  @override
  String get password => 'Password';

  @override
  String get passwordMustContain => 'Password must contain:';

  @override
  String get passwordMustContainLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordMustContainNumber =>
      'Password must contain at least one number';

  @override
  String get passwordMustContainSpecialChar =>
      'Password must contain at least one special character';

  @override
  String get passwordMustContainUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordStrengthVeryStrong => 'Very Strong';

  @override
  String get passwordStrengthVeryWeak => 'Very Weak';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordWeak =>
      'Password must contain uppercase, lowercase, number, and special character';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pendingVerifications => 'Pending Verifications';

  @override
  String get perMonth => '/month';

  @override
  String get periodAllTime => 'All Time';

  @override
  String get periodMonthly => 'This Month';

  @override
  String get periodWeekly => 'This Week';

  @override
  String get personalStatistics => 'Personal Statistics';

  @override
  String get personalStatisticsSubtitle =>
      'Charts, goals, and language progress';

  @override
  String get personalStatsActivity => 'Recent Activity';

  @override
  String get personalStatsChatStats => 'Chat Stats';

  @override
  String get personalStatsConversations => 'Conversations';

  @override
  String get personalStatsGoalsAchieved => 'Goals Achieved';

  @override
  String get personalStatsLevel => 'Level';

  @override
  String get personalStatsLanguage => 'Language';

  @override
  String get personalStatsTotal => 'Total';

  @override
  String get personalStatsNextLevel => 'Next Level';

  @override
  String get personalStatsNoActivityYet => 'No activity recorded yet';

  @override
  String get personalStatsNoWordsYet => 'Start chatting to discover new words';

  @override
  String get personalStatsTotalMessages => 'Messages Sent';

  @override
  String get personalStatsWordsDiscovered => 'Words Discovered';

  @override
  String get personalStatsWordsLearned => 'Words Learned';

  @override
  String get personalStatsXpOverview => 'XP Overview';

  @override
  String get photoAddPhoto => 'Add Photo';

  @override
  String get photoAddPrivateDescription =>
      'Add private photos that you can share in chat';

  @override
  String get photoAddPublicDescription => 'Add photos to complete your profile';

  @override
  String get photoAlreadyExistsInAlbum =>
      'Photo already exists in target album';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 photos';
  }

  @override
  String get photoDeleteConfirm =>
      'Are you sure you want to delete this photo?';

  @override
  String get photoDeleteMainWarning =>
      'This is your main photo. The next photo will become your main photo (must show your face). Continue?';

  @override
  String get photoExplicitContent =>
      'This photo contains inappropriate content. Nudity, underwear, and explicit content are not allowed anywhere in the app.';

  @override
  String get photoExplicitNudity =>
      'This photo appears to contain nudity or explicit content. All photos must be appropriate and fully clothed.';

  @override
  String get photoPrivateAlbumSuggestion =>
      'You can upload this photo to your private album instead, where it is only visible to people you grant access to.';

  @override
  String get photoUploadDeniedNudity =>
      'Upload denied - violation: nudity. Photos on your public profile must be fully clothed.';

  @override
  String photoFailedPickImage(Object error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get photoLongPressReorder => 'Long press and drag to reorder';

  @override
  String get photoMainNoFace =>
      'Your main photo must show your face clearly. No face was detected in this photo.';

  @override
  String get photoMainNotForward =>
      'Please use a photo where your face is clearly visible and facing forward.';

  @override
  String get photoManagePhotos => 'Manage Photos';

  @override
  String get photoMaxPrivate => 'Maximum 6 private photos allowed';

  @override
  String get photoMaxPublic => 'Maximum 6 public photos allowed';

  @override
  String get photoMustHaveOne =>
      'You must have at least one public photo with your face visible.';

  @override
  String get photoNoPhotos => 'No photos yet';

  @override
  String get photoNoPrivatePhotos => 'No private photos yet';

  @override
  String get photoNotAccepted => 'Photo Not Accepted';

  @override
  String get photoNotAllowedPublic =>
      'This photo is not allowed. All photos must be appropriate.';

  @override
  String get photoPrimary => 'PRIMARY';

  @override
  String get photoPrivateShareInfo => 'Private photos can be shared in chat';

  @override
  String get photoTooLarge => 'Photo is too large. Maximum size is 10MB.';

  @override
  String get photoTooMuchSkin =>
      'This photo shows too much skin exposure. Please use a photo where you are appropriately dressed.';

  @override
  String get photoUploadedMessage =>
      'Your photo has been added to your profile';

  @override
  String get photoUploadedTitle => 'Photo Uploaded!';

  @override
  String get photoValidating => 'Validating photo...';

  @override
  String get photos => 'Photos';

  @override
  String photosCount(int count) {
    return '$count/6 photos';
  }

  @override
  String photosPublicCount(int count) {
    return 'Photos: $count public';
  }

  @override
  String photosPublicPrivateCount(int publicCount, int privateCount) {
    return 'Photos: $publicCount public + $privateCount private';
  }

  @override
  String get photosUpdatedMessage => 'Your photo gallery has been saved';

  @override
  String get photosUpdatedTitle => 'Photos Updated!';

  @override
  String phrasesCount(String count) {
    return '$count phrases';
  }

  @override
  String get phrasesLabel => 'phrases';

  @override
  String get platinum => 'Platinum';

  @override
  String get playAgain => 'Play Again';

  @override
  String playersRange(String min, String max) {
    return '$min-$max players';
  }

  @override
  String get playing => 'Playing...';

  @override
  String playingCountLabel(String count) {
    return '$count playing';
  }

  @override
  String get plusTaxes => '+ taxes';

  @override
  String get preferenceAddCountry => 'Add Country';

  @override
  String get preferenceLanguageFilter => 'Language';

  @override
  String get preferenceLanguageFilterDesc =>
      'Only show people who speak a specific language';

  @override
  String get preferenceAnyLanguage => 'Any language';

  @override
  String get preferenceInterestFilter => 'Interests';

  @override
  String get preferenceInterestFilterDesc =>
      'Only show people who share your interests';

  @override
  String get preferenceNoInterestFilter =>
      'No interest filter — showing everyone';

  @override
  String get preferenceAddInterest => 'Add Interest';

  @override
  String get preferenceSearchInterest => 'Search interests...';

  @override
  String get preferenceNoInterestsFound => 'No interests found';

  @override
  String get preferenceAddDealBreaker => 'Add Deal Breaker';

  @override
  String get preferenceAdvancedFilters => 'Advanced Filters';

  @override
  String get preferenceAgeRange => 'Age Range';

  @override
  String get preferenceAllCountries => 'All Countries';

  @override
  String get preferenceAllVerified => 'All profiles must be verified';

  @override
  String get preferenceCountry => 'Country';

  @override
  String get preferenceCountryDescription =>
      'Only show people from specific countries (leave empty to show all)';

  @override
  String get preferenceDealBreakers => 'Deal Breakers';

  @override
  String get preferenceDealBreakersDesc =>
      'Never show me profiles with these characteristics';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Everyone';

  @override
  String get preferenceMaxDistance => 'Maximum Distance';

  @override
  String get preferenceMen => 'Men';

  @override
  String get preferenceMostPopular => 'Most Popular';

  @override
  String get preferenceNoCountriesFound => 'No countries found';

  @override
  String get preferenceNoCountryFilter =>
      'No country filter — showing worldwide';

  @override
  String get preferenceCountryRequired =>
      'At least one country must be selected';

  @override
  String get preferenceByUsers => 'By users';

  @override
  String get preferenceNoDealBreakers => 'No deal breakers set';

  @override
  String get preferenceNoDistanceLimit => 'No distance limit';

  @override
  String get preferenceOnlineNow => 'Online Now';

  @override
  String get preferenceOnlineNowDesc =>
      'Show only profiles that are currently online';

  @override
  String get preferenceOnlyVerified => 'Only show verified profiles';

  @override
  String get preferenceOrientationDescription =>
      'Filter by orientation (leave all unchecked to show everyone)';

  @override
  String get preferenceRecentlyActive => 'Recently active';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Show only profiles active in the last 7 days';

  @override
  String get preferenceSave => 'Save';

  @override
  String get preferenceSelectCountry => 'Select Country';

  @override
  String get preferenceSexualOrientation => 'Sexual Orientation';

  @override
  String get preferenceShowMe => 'Show Me';

  @override
  String get preferenceUnlimited => 'Unlimited';

  @override
  String preferenceUsersCount(int count) {
    return '$count users';
  }

  @override
  String get preferenceWithin => 'Within';

  @override
  String get preferenceWomen => 'Women';

  @override
  String get preferencesSavedMessage =>
      'Your discovery preferences have been updated';

  @override
  String get preferencesSavedTitle => 'Preferences Saved!';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Primary Origin';

  @override
  String get priorityConnectNotificationMessage =>
      'Someone wants to connect with you!';

  @override
  String get priorityConnectNotificationTitle => 'Priority Connect!';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get privateAlbum => 'Private';

  @override
  String get privateRoom => 'Private Room';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Profile';

  @override
  String get profileAboutMe => 'About Me';

  @override
  String get profileAccountDeletedSuccess => 'Account deleted successfully.';

  @override
  String get profileActivate => 'Activate';

  @override
  String get profileActivateIncognito => 'Activate Incognito?';

  @override
  String get profileActivateTravelerMode => 'Activate Traveler Mode?';

  @override
  String get profileActivatingBoost => 'Activating boost...';

  @override
  String get profileActiveLabel => 'ACTIVE';

  @override
  String get profileAdditionalDetails => 'Additional Details';

  @override
  String profileAgeCannotChange(int age) {
    return 'Age $age - Cannot be changed for verification';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return 'Profile already boosted! ${minutes}m remaining';
  }

  @override
  String get profileAuthenticationFailed => 'Authentication failed';

  @override
  String profileBioMinLength(int min) {
    return 'Bio must be at least $min characters';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Cost: $cost coins';
  }

  @override
  String get profileBoostDescription =>
      'Your profile will appear at the top of discovery for 30 minutes!';

  @override
  String get profileBoostNow => 'Boost Now';

  @override
  String get profileBoostProfile => 'Boost Profile';

  @override
  String get profileBoostSubtitle => 'Be seen first for 30 minutes';

  @override
  String get profileBoosted => 'Profile Boosted!';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return 'Profile boosted for $minutes minutes!';
  }

  @override
  String get profileBuyCoins => 'Buy Coins';

  @override
  String get profileCoinShop => 'Coin Shop';

  @override
  String get profileCoinShopSubtitle => 'Purchase coins and premium membership';

  @override
  String get profileConfirmYourPassword => 'Confirm Your Password';

  @override
  String get profileContinue => 'Continue';

  @override
  String get profileDataExportSent => 'Data export sent to your email';

  @override
  String get profileDateOfBirth => 'Date of Birth';

  @override
  String get profileDeleteAccountWarning =>
      'This action is permanent and cannot be undone. All your data, matches, and messages will be deleted. Please enter your password to confirm.';

  @override
  String get profileDiscoveryRestarted =>
      'Discovery restarted! You can now see all profiles again.';

  @override
  String get profileDisplayName => 'Display Name';

  @override
  String get profileDobInfo =>
      'Your date of birth cannot be changed for age verification purposes. Your exact age is visible to matches.';

  @override
  String get profileEditBasicInfo => 'Edit Basic Info';

  @override
  String get profileEditLocation => 'Edit Location & Languages';

  @override
  String get profileEditNickname => 'Edit Nickname';

  @override
  String get profileEducation => 'Education';

  @override
  String get profileEducationHint => 'e.g. Bachelor in Computer Science';

  @override
  String get profileEnterNameHint => 'Enter your name';

  @override
  String get profileEnterNicknameHint => 'Enter nickname';

  @override
  String get profileEnterNicknameWith => 'Enter a nickname starting with @';

  @override
  String get profileExportingData => 'Exporting your data...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Failed to restart discovery: $error';
  }

  @override
  String get profileFindUsers => 'Find Users';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGetCoins => 'Get Coins';

  @override
  String get profileGetMembership => 'Get GreenGo Membership';

  @override
  String get profileGettingLocation => 'Getting Location...';

  @override
  String get profileGreengoMembership => 'GreenGo Membership';

  @override
  String get profileHeightCm => 'Height (cm)';

  @override
  String get profileIncognitoActivated =>
      'Incognito mode activated for 24 hours!';

  @override
  String profileIncognitoCost(Object cost) {
    return 'Incognito mode costs $cost coins per day.';
  }

  @override
  String get profileIncognitoDeactivated => 'Incognito mode deactivated.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'Incognito mode hides your profile from discovery for 24 hours.\n\nCost: $cost';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Free with Platinum - Hidden from discovery';

  @override
  String get profileIncognitoMode => 'Incognito Mode';

  @override
  String get profileInsufficientCoins => 'Insufficient Coins';

  @override
  String profileInterestsCount(Object count) {
    return '$count interests';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Tell us about your interests, hobbies, what you\'re looking for...';

  @override
  String get profileLanguagesSectionTitle => 'Languages';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 languages selected';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count profile(s) linked';
  }

  @override
  String profileLocationFailed(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get profileLocationSectionTitle => 'Location';

  @override
  String get profileLookingFor => 'Looking For';

  @override
  String get profileLookingForHint => 'e.g. Long-term relationship';

  @override
  String get profileMaxLanguagesAllowed => 'Maximum 3 languages allowed';

  @override
  String get profileMembershipActive => 'Active';

  @override
  String get profileMembershipExpired => 'Expired';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Valid till $date';
  }

  @override
  String get profileMyUsage => 'My Usage';

  @override
  String get profileMyUsageSubtitle => 'View your daily usage and tier limits';

  @override
  String get profileNicknameAlreadyTaken => 'This nickname is already taken';

  @override
  String get profileNicknameCharRules =>
      '3-20 characters. Letters, numbers, and underscores only.';

  @override
  String get profileNicknameCheckError => 'Error checking availability';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'Your nickname is unique and can be used to find you. Others can search for you using @$nickname';
  }

  @override
  String get profileNicknameInfoWithout =>
      'Your nickname is unique and can be used to find you. Set one below to let others discover you.';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileNicknameRefresh => 'Refresh';

  @override
  String get profileNicknameRule1 => 'Must be 3-20 characters';

  @override
  String get profileNicknameRule2 => 'Start with a letter';

  @override
  String get profileNicknameRule3 => 'Only letters, numbers, and underscores';

  @override
  String get profileNicknameRule4 => 'No consecutive underscores';

  @override
  String get profileNicknameRule5 => 'Cannot contain reserved words';

  @override
  String get profileNicknameRules => 'Nickname Rules';

  @override
  String get profileNicknameSuggestions => 'Suggestions';

  @override
  String profileNoUsersFound(String query) {
    return 'No users found for \"@$query\"';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return 'Not enough coins! Need $required, have $available';
  }

  @override
  String get profileOccupation => 'Occupation';

  @override
  String get profileOccupationHint => 'e.g. Software Engineer';

  @override
  String get profileOptionalDetails =>
      'Optional — helps others get to know you';

  @override
  String get profileOrientationPrivate =>
      'This is private and not shown on your profile card';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 photos';
  }

  @override
  String get profilePremiumFeatures => 'Premium Features';

  @override
  String get profileProgressGrowth => 'Progress & Growth';

  @override
  String get profileRestart => 'Restart';

  @override
  String get profileRestartDiscovery => 'Restart Discovery';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'This will erase all your swipes (connects, passes, priority connects) so you can rediscover everyone from scratch.\n\nYour matches and chats will NOT be affected.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Restart Discovery';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Reset all swipes and start fresh';

  @override
  String get profileSearchByNickname => 'Search by @nickname';

  @override
  String get profileSearchByNicknameHint => 'Search by @nickname';

  @override
  String get profileSearchCityHint => 'Search city, address, or place...';

  @override
  String get profileSearchForUsers => 'Search for users by nickname';

  @override
  String get profileSearchLanguagesHint => 'Search languages...';

  @override
  String get profileSetLocationAndLanguage =>
      'Please set location and select at least one language';

  @override
  String get profileSexualOrientation => 'Sexual Orientation';

  @override
  String get profileStop => 'Stop';

  @override
  String get profileTellAboutYourselfHint => 'Tell people about yourself...';

  @override
  String get profileTipAuthentic => 'Be authentic and genuine';

  @override
  String get profileTipHobbies => 'Mention your hobbies and passions';

  @override
  String get profileTipHumor => 'Add a touch of humor';

  @override
  String get profileTipPositive => 'Keep it positive';

  @override
  String get profileTipsForGreatBio => 'Tips for a great bio';

  @override
  String profileTravelerActivated(Object city) {
    return 'Traveler mode activated! Appearing in $city for 24 hours.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'Traveler mode costs $cost coins per day.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Traveler mode deactivated. Back to your real location.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'Traveler mode lets you appear in a different city\'s discovery feed for 24 hours.\n\nCost: $cost';
  }

  @override
  String get profileTravelerMode => 'Traveler Mode';

  @override
  String get profileTryDifferentNickname => 'Try a different nickname';

  @override
  String get profileUnableToVerifyAccount => 'Unable to verify account';

  @override
  String get profileReauthProviderMismatch =>
      'This account was created with a social sign-in (e.g. Google), so there is no password to confirm here. Please delete it from the account you signed in with, or contact support.';

  @override
  String get profileTooManyAttempts =>
      'Too many attempts. For your security this device is temporarily blocked — please wait a few minutes and try again.';

  @override
  String get profileUpdateCurrentLocation => 'Update Current Location';

  @override
  String get profileUpdatedMessage => 'Your changes have been saved';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get profileUpdatedTitle => 'Profile Updated!';

  @override
  String get profileWeightKg => 'Weight (kg)';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count profile$_temp0 linked';
  }

  @override
  String get profilingDescription =>
      'Allow us to analyze your preferences to provide better match suggestions';

  @override
  String get progress => 'Progress';

  @override
  String get progressAchievements => 'Badges';

  @override
  String get progressBadges => 'Badges';

  @override
  String get progressChallenges => 'Challenges';

  @override
  String get progressComparison => 'Progress Comparison';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressJourneyDescription =>
      'See your complete dating journey and milestones';

  @override
  String get progressLabel => 'Progress';

  @override
  String get progressLeaderboard => 'Leaderboard';

  @override
  String progressLevel(int level) {
    return 'Level $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Overview';

  @override
  String get progressRecentAchievements => 'Recent Achievements';

  @override
  String get progressSeeAll => 'See All';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressTodaysChallenges => 'Today\'s Challenges';

  @override
  String get progressTotalXP => 'Total XP';

  @override
  String get progressViewJourney => 'View Your Journey';

  @override
  String get publicAlbum => 'Public';

  @override
  String get purchaseSuccessfulTitle => 'Purchase Successful!';

  @override
  String get purchasedLabel => 'Purchased';

  @override
  String get quickPlay => 'Quick Play';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Read Privacy Policy';

  @override
  String get readTermsAndConditions => 'Read Terms and Conditions';

  @override
  String get readyButton => 'Ready';

  @override
  String get recipientNickname => 'Recipient nickname';

  @override
  String get recordVoice => 'Record Voice';

  @override
  String get refresh => 'Refresh';

  @override
  String get register => 'Register';

  @override
  String get rejectVerification => 'Reject';

  @override
  String rejectionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get rejectionReasonRequired => 'Please enter a reason for rejection';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $type remaining today';
  }

  @override
  String get reportSubmittedMessage =>
      'Thank you for helping keep our community safe';

  @override
  String get reportSubmittedTitle => 'Report Submitted!';

  @override
  String get reportWord => 'Report Word';

  @override
  String get reportsPanel => 'Reports Panel';

  @override
  String get requestBetterPhoto => 'Request Better Photo';

  @override
  String requiresTier(String tier) {
    return 'Requires $tier';
  }

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get restartAppWizard => 'Restart App Wizard';

  @override
  String get restartWizard => 'Restart Wizard';

  @override
  String get restartWizardDialogContent =>
      'This will restart the onboarding wizard. You can update your profile information step by step. Your current data will be preserved.';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get retry => 'Retry';

  @override
  String get reuploadVerification => 'Re-upload Verification Photo';

  @override
  String get reverificationCameraError => 'Failed to open camera';

  @override
  String get reverificationDescription =>
      'Please take a clear selfie so we can verify your identity. Make sure your face is well lit and clearly visible.';

  @override
  String get reverificationHeading => 'We need to verify your identity';

  @override
  String get reverificationInfoText =>
      'After submitting, your profile will be under review. You will get access once approved.';

  @override
  String get reverificationPhotoTips => 'Photo Tips';

  @override
  String get reverificationReasonLabel => 'Reason for request:';

  @override
  String get reverificationRetakePhoto => 'Retake Photo';

  @override
  String get reverificationSubmit => 'Submit for Review';

  @override
  String get reverificationTapToSelfie => 'Tap to take a selfie';

  @override
  String get reverificationTipCamera => 'Look directly at the camera';

  @override
  String get reverificationTipFullFace => 'Make sure your full face is visible';

  @override
  String get reverificationTipLighting =>
      'Good lighting — face the light source';

  @override
  String get reverificationTipNoAccessories => 'No sunglasses, hats, or masks';

  @override
  String get reverificationTitle => 'Identity Verification';

  @override
  String get reverificationUploadFailed => 'Upload failed. Please try again.';

  @override
  String get reviewReportedMessages =>
      'Review reported messages & manage accounts';

  @override
  String get reviewUserVerifications => 'Review user verifications';

  @override
  String reviewedBy(String admin) {
    return 'Reviewed by $admin';
  }

  @override
  String get revokeAccess => 'Revoke album access';

  @override
  String get rewardsAndProgress => 'Rewards & Progress';

  @override
  String get romanticCategory => 'Romantic';

  @override
  String get roundTimer => 'Round Timer';

  @override
  String roundXofY(String current, String total) {
    return 'Round $current/$total';
  }

  @override
  String get rounds => 'Rounds';

  @override
  String get safetyAdd => 'Add';

  @override
  String get safetyAddAtLeastOneContact =>
      'Please add at least one emergency contact';

  @override
  String get safetyAddEmergencyContact => 'Add Emergency Contact';

  @override
  String get safetyAddEmergencyContacts => 'Add emergency contacts';

  @override
  String get safetyAdditionalDetailsHint => 'Any additional details...';

  @override
  String get safetyCheckInDescription =>
      'Set up a check-in for your date. We\'ll remind you to check in, and alert your contacts if you don\'t respond.';

  @override
  String get safetyCheckInEvery => 'Check-in every';

  @override
  String get safetyCheckInScheduled => 'Date check-in scheduled!';

  @override
  String get safetyDateCheckIn => 'Date Check-In';

  @override
  String get safetyDateTime => 'Date & Time';

  @override
  String get safetyEmergencyContacts => 'Emergency Contacts';

  @override
  String get safetyEmergencyContactsHelp =>
      'They\'ll be notified if you need help';

  @override
  String get safetyEmergencyContactsLocation =>
      'Emergency contacts can see your location';

  @override
  String get safetyInterval15Min => '15 min';

  @override
  String get safetyInterval1Hour => '1 hour';

  @override
  String get safetyInterval2Hours => '2 hours';

  @override
  String get safetyInterval30Min => '30 min';

  @override
  String get safetyLocation => 'Location';

  @override
  String get safetyMeetingLocationHint => 'Where are you meeting?';

  @override
  String get safetyMeetingWith => 'Meeting with';

  @override
  String get safetyNameLabel => 'Name';

  @override
  String get safetyNotesOptional => 'Notes (Optional)';

  @override
  String get safetyPhoneLabel => 'Phone Number';

  @override
  String get safetyPleaseEnterLocation => 'Please enter a location';

  @override
  String get safetyRelationshipFamily => 'Family';

  @override
  String get safetyRelationshipFriend => 'Friend';

  @override
  String get safetyRelationshipLabel => 'Relationship';

  @override
  String get safetyRelationshipOther => 'Other';

  @override
  String get safetyRelationshipPartner => 'Partner';

  @override
  String get safetyRelationshipRoommate => 'Roommate';

  @override
  String get safetyScheduleCheckIn => 'Schedule Check-In';

  @override
  String get safetyShareLiveLocation => 'Share live location';

  @override
  String get safetyStaySafe => 'Stay Safe';

  @override
  String get save => 'Save';

  @override
  String get searchByNameOrNickname => 'Search by name or @nickname';

  @override
  String get searchByNickname => 'Search by Nickname';

  @override
  String get searchByNicknameTooltip => 'Search by nickname';

  @override
  String get searchCityPlaceholder => 'Search city, address, or place...';

  @override
  String get searchCountries => 'Search countries...';

  @override
  String get searchCountryHint => 'Search country...';

  @override
  String get searchForCity => 'Search for a city or use GPS';

  @override
  String get searchMessagesHint => 'Search messages...';

  @override
  String get secondChanceDescription =>
      'See profiles you passed on who actually liked you!';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km away';
  }

  @override
  String get secondChanceEmpty => 'No second chances available';

  @override
  String get secondChanceEmptySubtitle =>
      'Check back later for more opportunities!';

  @override
  String get secondChanceFindButton => 'Find Second Chances';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max free';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Get Unlimited ($cost)';
  }

  @override
  String get secondChanceLike => 'Like';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'They liked you $ago';
  }

  @override
  String get secondChanceMatchBody =>
      'You and this person both like each other! Start a conversation.';

  @override
  String get secondChanceMatchTitle => 'Start Connecting!';

  @override
  String get secondChanceOutOf => 'Out of Second Chances';

  @override
  String get secondChancePass => 'Pass';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'You\'ve used all $freePerDay free second chances for today.\n\nGet unlimited for $cost coins!';
  }

  @override
  String get secondChanceRefresh => 'Refresh';

  @override
  String get secondChanceStartChat => 'Start Chat';

  @override
  String get secondChanceTitle => 'Second Chance';

  @override
  String get secondChanceUnlimited => 'Unlimited';

  @override
  String get secondChanceUnlimitedUnlocked =>
      'Unlimited second chances unlocked!';

  @override
  String get secondaryOrigin => 'Secondary Origin (optional)';

  @override
  String get seconds => 'Seconds';

  @override
  String get secretAchievement => 'Secret Achievement';

  @override
  String get seeAll => 'See All';

  @override
  String get seeHowOthersViewProfile => 'See how others view your profile';

  @override
  String seeMoreProfiles(int count) {
    return 'See $count more';
  }

  @override
  String get seeMoreProfilesTitle => 'See More Profiles';

  @override
  String get seeProfile => 'See Profile';

  @override
  String selectAtLeastInterests(int count) {
    return 'Select at least $count interests';
  }

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectTravelLocation => 'Select Travel Location';

  @override
  String get sendCoins => 'Send Coins';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return 'Send $amount coins to @$nickname?';
  }

  @override
  String get sendMedia => 'Send Media';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get serverUnavailableMessage =>
      'Our servers are temporarily unavailable. Please try again in a few moments.';

  @override
  String get serverUnavailableTitle => 'Server Unavailable';

  @override
  String get setYourUniqueNickname => 'Set your unique nickname';

  @override
  String get settings => 'Settings';

  @override
  String get shareAlbum => 'Share Album';

  @override
  String get shop => 'Shop';

  @override
  String get shopActive => 'ACTIVE';

  @override
  String get shopAdvancedFilters => 'Advanced Filters';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount coins';
  }

  @override
  String get shopBadge => 'Badge';

  @override
  String get shopBaseMembership => 'GreenGo Base Membership';

  @override
  String get shopBaseMembershipDescription =>
      'Required to swipe, like, chat, and interact with other users.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus bonus coins';
  }

  @override
  String get shopBoosts => 'Boosts';

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Buy $tier ($duration)';
  }

  @override
  String get shopCannotSendToSelf => 'You cannot send coins to yourself';

  @override
  String get shopCheckInternet =>
      'Make sure you have an internet connection\nand try again.';

  @override
  String get shopCoins => 'Coins';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount coins/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount coins sent to @$nickname';
  }

  @override
  String get shopComingSoon => 'Coming Soon';

  @override
  String get shopConfirmSend => 'Confirm Send';

  @override
  String get shopCurrent => 'CURRENT';

  @override
  String shopCurrentExpires(Object date) {
    return 'CURRENT - Expires $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Current Plan: $tier';
  }

  @override
  String get shopDailyLikes => 'Daily Connects';

  @override
  String shopDaysLeft(Object days) {
    return '${days}d left';
  }

  @override
  String get shopEnterAmount => 'Enter amount';

  @override
  String get shopEnterBothFields => 'Please enter both nickname and amount';

  @override
  String get shopEnterValidAmount => 'Please enter a valid amount';

  @override
  String shopExpired(String date) {
    return 'Expired: $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expires: $date ($days days remaining)';
  }

  @override
  String get shopFailedToInitiate => 'Failed to initiate purchase';

  @override
  String get shopFailedToSendCoins => 'Failed to send coins';

  @override
  String get shopGetNotified => 'Get Notified';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Incognito Mode';

  @override
  String get shopInsufficientCoins => 'Insufficient coins';

  @override
  String shopMembershipActivated(String date) {
    return 'GreenGo Membership activated! +500 bonus coins. Valid until $date.';
  }

  @override
  String get shopMonthly => 'Monthly';

  @override
  String get shopNotifyMessage =>
      'We\'ll let you know when Video-Coins is available';

  @override
  String get shopOneMonth => '1 Month';

  @override
  String get shopOneYear => '1 Year';

  @override
  String get shopPerMonth => '/month';

  @override
  String get shopPerYear => '/year';

  @override
  String get shopPopular => 'POPULAR';

  @override
  String get shopPreviousPurchaseFound =>
      'Previous purchase found. Please try again.';

  @override
  String get shopPriorityMatching => 'Priority Matching';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Purchase $coins Coins for $price';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Purchase error: $error';
  }

  @override
  String get shopReadReceipts => 'Read Receipts';

  @override
  String get shopRecipientNickname => 'Recipient nickname';

  @override
  String get shopRetry => 'Retry';

  @override
  String shopSavePercent(String percent) {
    return 'SAVE $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'See Who Connects';

  @override
  String get shopSend => 'Send';

  @override
  String get shopSendCoins => 'Send Coins';

  @override
  String get shopStoreNotAvailable =>
      'Store not available. Please check your device settings.';

  @override
  String get shopTemporarilyUnavailable =>
      'Purchases are temporarily unavailable. Please try again later.';

  @override
  String get shopSuperLikes => 'Priority Connects';

  @override
  String get shopTabCoins => 'Coins';

  @override
  String shopTabError(Object tabName) {
    return '$tabName tab error';
  }

  @override
  String get shopTabMembership => 'Membership';

  @override
  String get shopTabVideo => 'Video';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopTravelling => 'Travelling';

  @override
  String get shopUnableToLoadPackages => 'Unable to Load Packages';

  @override
  String get shopUnlimited => 'Unlimited';

  @override
  String get shopUnlockPremium =>
      'Unlock premium features and enhance your dating experience';

  @override
  String get shopUpgradeAndSave =>
      'Upgrade & Save! Get discount on higher tiers';

  @override
  String get shopUpgradeExperience => 'Upgrade Your Experience';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Upgrade to $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'User not found';

  @override
  String shopValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      'Watch short videos to earn free coins!\nStay tuned for this exciting feature.';

  @override
  String get shopVipBadge => 'VIP Badge';

  @override
  String get shopYearly => 'Yearly';

  @override
  String get shopYearlyPlan => 'Yearly subscription';

  @override
  String get shopYouHave => 'You have';

  @override
  String shopYouSave(String amount, String tier) {
    return 'You save \$$amount/month upgrading from $tier';
  }

  @override
  String get shortTermRelationship => 'Short-term relationship';

  @override
  String showingProfiles(int count) {
    return '$count profiles';
  }

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signUp => 'Sign Up';

  @override
  String get silver => 'Silver';

  @override
  String get skip => 'Skip';

  @override
  String get skipForNow => 'Skip for Now';

  @override
  String get slangCategory => 'Slang';

  @override
  String get socialConnectAccounts => 'Connect your social accounts';

  @override
  String get socialHintUsername => 'Username (without @)';

  @override
  String get socialHintUsernameOrUrl => 'Username or profile URL';

  @override
  String get socialLinksUpdatedMessage =>
      'Your social profiles have been saved';

  @override
  String get socialLinksUpdatedTitle => 'Social Links Updated!';

  @override
  String get socialNotConnected => 'Not connected';

  @override
  String get socialProfiles => 'Social Profiles';

  @override
  String get socialProfilesTip =>
      'Your social profiles will be visible on your dating profile and help others verify your identity.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get spotsAbout => 'About';

  @override
  String get spotsAddNewSpot => 'Add a New Spot';

  @override
  String get spotsAddSpot => 'Add a Spot';

  @override
  String spotsAddedBy(Object name) {
    return 'Added by $name';
  }

  @override
  String get spotsAll => 'All';

  @override
  String get spotsCategory => 'Category';

  @override
  String get spotsCouldNotLoad => 'Could not load spots';

  @override
  String get spotsCouldNotLoadSpot => 'Could not load spot';

  @override
  String get spotsCreateSpot => 'Create Spot';

  @override
  String get spotsCulturalSpots => 'Cultural Spots';

  @override
  String spotsDateDaysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return '$count months ago';
  }

  @override
  String get spotsDateToday => 'Today';

  @override
  String spotsDateWeeksAgo(Object count) {
    return '$count weeks ago';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return '$count years ago';
  }

  @override
  String get spotsDateYesterday => 'Yesterday';

  @override
  String get spotsDescriptionLabel => 'Description';

  @override
  String get spotsNameLabel => 'Spot Name';

  @override
  String get spotsNoReviews => 'No reviews yet. Be the first to write one!';

  @override
  String get spotsNoSpotsFound => 'No spots found';

  @override
  String get spotsReviewAdded => 'Review added!';

  @override
  String spotsReviewsCount(Object count) {
    return 'Reviews ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Share your experience...';

  @override
  String get spotsSubmitReview => 'Submit Review';

  @override
  String get spotsWriteReview => 'Write a Review';

  @override
  String get spotsYourRating => 'Your Rating';

  @override
  String get standardTier => 'Standard';

  @override
  String get startChat => 'Start Chat';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get startGame => 'Start Game';

  @override
  String get startLearning => 'Start Learning';

  @override
  String get startLessonBtn => 'Start Lesson';

  @override
  String get startSwipingToFindMatches => 'Start swiping to find your matches!';

  @override
  String get step => 'Step';

  @override
  String get stepOf => 'of';

  @override
  String get storiesAddCaptionHint => 'Add a caption...';

  @override
  String get storiesCreateStory => 'Create Story';

  @override
  String storiesDaysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String get storiesDisappearAfter24h =>
      'Your story will disappear after 24 hours';

  @override
  String get storiesGallery => 'Gallery';

  @override
  String storiesHoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String get storiesNoActive => 'No active stories';

  @override
  String get storiesNoStories => 'No stories available';

  @override
  String get storiesPhoto => 'Photo';

  @override
  String get storiesPost => 'Post';

  @override
  String get storiesSendMessageHint => 'Send a message...';

  @override
  String get storiesShareMoment => 'Share a moment';

  @override
  String get storiesVideo => 'Video';

  @override
  String get storiesYourStory => 'Your Story';

  @override
  String get streakActiveToday => 'Active today';

  @override
  String get streakBonusHeader => 'Streak Bonus!';

  @override
  String get streakInactive => 'Start your streak!';

  @override
  String get streakMessageIncredible => 'Incredible dedication! 🏆';

  @override
  String get streakMessageKeepItUp => 'Keep it up! ✨';

  @override
  String get streakMessageMomentum => 'Building momentum! 🚀';

  @override
  String get streakMessageOneWeek => 'One week milestone! 🎯';

  @override
  String get streakMessageTwoWeeks => 'Two weeks strong! 💪';

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get submitVerification => 'Submit for Verification';

  @override
  String submittedOn(String date) {
    return 'Submitted on $date';
  }

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get subscriptionExpired => 'Subscription Expired';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'Your $tierName subscription has expired. You have been moved to the Free tier.\n\nUpgrade anytime to restore your premium features!';
  }

  @override
  String get suggestions => 'Suggestions';

  @override
  String get superLike => 'Priority Connect';

  @override
  String superLikedYou(String name) {
    return '$name priority connected with you!';
  }

  @override
  String get superLikes => 'Priority Connects';

  @override
  String get supportCenter => 'Support Center';

  @override
  String get supportCenterSubtitle => 'Get help, report issues, contact us';

  @override
  String get swipeIndicatorLike => 'CONNECT';

  @override
  String get swipeIndicatorNope => 'PASS';

  @override
  String get swipeIndicatorSkip => 'EXPLORE NEXT';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITY CONNECT';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get takeVerificationPhoto => 'Take Verification Photo';

  @override
  String get tapToContinue => 'Tap to continue';

  @override
  String get targetLanguage => 'Target Language';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get thatsYourOwnProfile => 'That\'s your own profile!';

  @override
  String get thirdPartyDataDescription =>
      'Allow sharing anonymized data with partners for service improvement';

  @override
  String get thisWeek => 'This Week';

  @override
  String get tierFree => 'Free';

  @override
  String get timeRemaining => 'Time remaining';

  @override
  String get timeoutError => 'Request timed out';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% to Level $level';
  }

  @override
  String get today => 'today';

  @override
  String get totalXpLabel => 'Total XP';

  @override
  String get tourDiscoveryDescription =>
      'Swipe through profiles to find your perfect match. Swipe right if you\'re interested, left to pass.';

  @override
  String get tourDiscoveryTitle => 'Discover Matches';

  @override
  String get tourDone => 'Done';

  @override
  String get tourLearnDescription =>
      'Study vocabulary, grammar, and conversation skills';

  @override
  String get tourLearnTitle => 'Learn Languages';

  @override
  String get tourMatchesDescription =>
      'See everyone who liked you back! Start conversations with your mutual matches.';

  @override
  String get tourMatchesTitle => 'Your Matches';

  @override
  String get tourMessagesDescription =>
      'Chat with your matches here. Send messages, photos, and voice notes to connect.';

  @override
  String get tourMessagesTitle => 'Messages';

  @override
  String get tourNext => 'Next';

  @override
  String get tourPlayDescription => 'Challenge others in fun language games';

  @override
  String get tourPlayTitle => 'Play Games';

  @override
  String get tourProfileDescription =>
      'Customize your profile, manage settings, and control your privacy.';

  @override
  String get tourProfileTitle => 'Your Profile';

  @override
  String get tourProgressDescription =>
      'Earn badges, complete challenges, and climb the leaderboard!';

  @override
  String get tourProgressTitle => 'Track Progress';

  @override
  String get tourShopDescription =>
      'Get coins and premium features to boost your dating experience.';

  @override
  String get tourShopTitle => 'Shop & Coins';

  @override
  String get tourSkip => 'Skip';

  @override
  String get trialWelcomeTitle => 'Welcome to GreenGo!';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'You are currently using the trial version. Your free base membership is active until $expirationDate. Enjoy exploring GreenGo!';
  }

  @override
  String get trialWelcomeButton => 'Get Started';

  @override
  String get translateWord => 'Translate this word';

  @override
  String get translationDownloadExplanation =>
      'To enable automatic message translation, we need to download language data for offline use.';

  @override
  String get travelCategory => 'Travel';

  @override
  String get travelLabel => 'Travel';

  @override
  String get travelerAppearFor24Hours =>
      'You will appear in discovery results for this location for 24 hours.';

  @override
  String get travelerBadge => 'Traveler';

  @override
  String get travelerChangeLocation => 'Change location';

  @override
  String get travelerConfirmLocation => 'Confirm Location';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'Failed to get location: $error';
  }

  @override
  String get travelerGettingLocation => 'Getting location...';

  @override
  String travelerInCity(String city) {
    return 'In $city';
  }

  @override
  String get travelerLoadingAddress => 'Loading address...';

  @override
  String get travelerLocationInfo =>
      'You will appear in discovery results for this location for 24 hours.';

  @override
  String get travelerLocationPermissionsDenied => 'Location permissions denied';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Location permissions permanently denied';

  @override
  String get travelerLocationServicesDisabled =>
      'Location services are disabled';

  @override
  String travelerModeActivated(String city) {
    return 'Traveler mode activated! Appearing in $city for 24 hours.';
  }

  @override
  String get travelerModeActive => 'Traveler mode active';

  @override
  String get travelerModeDeactivated =>
      'Traveler mode deactivated. Back to your real location.';

  @override
  String get travelerModeDescription =>
      'Appear in a different city\'s discovery feed for 24 hours';

  @override
  String get travelerModeTitle => 'Traveler Mode';

  @override
  String travelerNoResultsFor(Object query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Pick on Map';

  @override
  String get travelerProfileAppearDescription =>
      'Your profile will appear in that location\'s discovery feed for 24 hours with a Traveler badge.';

  @override
  String get travelerSearchHint =>
      'Your profile will appear in that location\'s discovery feed for 24 hours with a Traveler badge.';

  @override
  String get travelerSearchOrGps => 'Search for a city or use GPS';

  @override
  String get travelerSelectOnMap => 'Select on Map';

  @override
  String get travelerSelectThisLocation => 'Select This Location';

  @override
  String get travelerSelectTravelLocation => 'Select Travel Location';

  @override
  String get travelerTapOnMap => 'Tap on the map to select a location';

  @override
  String get travelerUseGps => 'Use GPS';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get tryDifferentSearchOrFilter => 'Try a different search or filter';

  @override
  String get twoFaDisabled => '2FA authentication disabled';

  @override
  String get twoFaEnabled => '2FA authentication enabled';

  @override
  String get twoFaToggleSubtitle =>
      'Require email code verification on every login';

  @override
  String get twoFaToggleTitle => 'Enable 2FA Authenticator';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get typeQuizzes => 'Quizzes';

  @override
  String get typeStreak => 'Streak';

  @override
  String typeWordStartingWith(String letter) {
    return 'Type a word starting with \"$letter\"';
  }

  @override
  String get typeWordsLearned => 'Words Learned';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'Unable to load profile';

  @override
  String get unableToPlayVoiceIntro => 'Unable to play voice introduction';

  @override
  String get undoSwipe => 'Undo Swipe';

  @override
  String unitLabelN(String number) {
    return 'Unit $number';
  }

  @override
  String get unlimited => 'Unlimited';

  @override
  String get unlock => 'Unlock';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Unlock $count more profiles in grid view for $cost coins.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Are you sure you want to unmatch with $name? This cannot be undone.';
  }

  @override
  String get unmatchLabel => 'Unmatch';

  @override
  String unmatchedWith(String name) {
    return 'Unmatched with $name';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeForEarlyAccess =>
      'Upgrade to Silver, Gold, or Platinum for early access before April 14th, 2026!';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String upgradeToTier(String tier) {
    return 'Upgrade to $tier';
  }

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get uppercaseLowercase => 'Uppercase and lowercase letters';

  @override
  String get useCurrentGpsLocation => 'Use my current GPS location';

  @override
  String get usedToday => 'Used today';

  @override
  String get usedWords => 'Used Words';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName has been blocked';
  }

  @override
  String get userBlockedTitle => 'User Blocked!';

  @override
  String get userNotFound => 'User not found';

  @override
  String get usernameOrProfileUrl => 'Username or profile URL';

  @override
  String get usernameWithoutAt => 'Username (without @)';

  @override
  String get verificationApproved => 'Verification Approved';

  @override
  String get verificationApprovedMessage =>
      'Your identity has been verified. You now have full access to the app.';

  @override
  String get verificationApprovedSuccess =>
      'Verification approved successfully';

  @override
  String get verificationDescription =>
      'To ensure the safety of our community, we require all users to verify their identity. Please take a photo of yourself holding your ID document.';

  @override
  String get verificationHistory => 'Verification History';

  @override
  String get verificationInstructions =>
      'Please hold your ID document (passport, driver\'s license, or national ID) next to your face and take a clear photo.';

  @override
  String get verificationNeedsResubmission => 'Better Photo Required';

  @override
  String get verificationNeedsResubmissionMessage =>
      'We need a clearer photo for verification. Please resubmit.';

  @override
  String get verificationPanel => 'Verification Panel';

  @override
  String get verificationPending => 'Verification Pending';

  @override
  String get verificationPendingMessage =>
      'Your account is being verified. This usually takes 24-48 hours. You will be notified once the review is complete.';

  @override
  String get verificationRejected => 'Verification Rejected';

  @override
  String get verificationRejectedMessage =>
      'Your verification was rejected. Please submit a new photo.';

  @override
  String get verificationRejectedSuccess => 'Verification rejected';

  @override
  String get verificationRequired => 'Identity Verification Required';

  @override
  String get verificationSkipWarning =>
      'You can browse the app, but you won\'t be able to chat or see other profiles until verified.';

  @override
  String get verificationTip1 => 'Ensure good lighting';

  @override
  String get verificationTip2 =>
      'Make sure your face and ID are clearly visible';

  @override
  String get verificationTip3 =>
      'Hold the ID next to your face, not covering it';

  @override
  String get verificationTip4 => 'All text on the ID should be readable';

  @override
  String get verificationTips => 'Tips for a successful verification:';

  @override
  String get verificationTitle => 'Verify Your Identity';

  @override
  String get verificationPrivacyTitle => 'Your data is safe with us';

  @override
  String get verificationPrivacyEncryption =>
      'All documents are encrypted with end-to-end encryption. Not even GreenGo engineers can access your data.';

  @override
  String get verificationPrivacyAccess =>
      'Your information can only be accessed through your personal request via official channels or email.';

  @override
  String get verificationPrivacySafety =>
      'This step is essential to protect all members. We invite you to report any suspicious behaviour and let GreenGo take action.';

  @override
  String get verificationPrivacyReporting =>
      'If something happens, report it immediately. GreenGo will investigate and act to keep the community safe.';

  @override
  String get verificationChooseMethod => 'Choose your verification method';

  @override
  String get verificationMethodPhoto => 'ID Document';

  @override
  String get verificationMethodPhotoDesc =>
      'Take a photo holding your ID next to your face';

  @override
  String get verificationMethodPhone => 'Phone Number';

  @override
  String get verificationMethodPhoneDesc =>
      'Verify via SMS code sent to your phone';

  @override
  String get verificationPhoneTitle => 'Phone Verification';

  @override
  String get verificationPhoneSubtitle =>
      'Enter your phone number to receive a verification code via SMS';

  @override
  String get verificationPhoneLabel => 'Phone number';

  @override
  String get verificationPhoneHint => '+1 234 567 8900';

  @override
  String get verificationSendCode => 'Send Code';

  @override
  String get verificationEnterCode =>
      'Enter the 6-digit code sent to your phone';

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verificationVerifyCode => 'Verify Code';

  @override
  String get verificationPhoneSuccess => 'Phone number verified successfully!';

  @override
  String get verificationPhoneResponsibility =>
      'By verifying with your phone number, you acknowledge that the owner of this number is personally responsible for all actions performed on this account.';

  @override
  String get verificationResendCode => 'Resend code';

  @override
  String verificationCodeSent(String phoneNumber) {
    return 'Code sent to $phoneNumber';
  }

  @override
  String get verificationPhoneError =>
      'Failed to verify phone number. Please try again.';

  @override
  String get verificationInvalidCode =>
      'Invalid code. Please check and try again.';

  @override
  String get verificationOr => 'or';

  @override
  String get verifyNow => 'Verify Now';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit tags selected';
  }

  @override
  String get vibeTagsGet5Tags => 'Get 5 tags';

  @override
  String get vibeTagsGetAccessTo => 'Get access to:';

  @override
  String get vibeTagsLimitReached => 'Tag Limit Reached';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Free users can select up to $limit tags. Upgrade to Premium for 5 tags!';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'You\'ve reached your maximum of $limit tags. Remove one to add another.';
  }

  @override
  String get vibeTagsNoTags => 'No tags available';

  @override
  String get vibeTagsPremiumFeature1 => '5 vibe tags instead of 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Exclusive premium tags';

  @override
  String get vibeTagsPremiumFeature3 => 'Priority in search results';

  @override
  String get vibeTagsPremiumFeature4 => 'And much more!';

  @override
  String get vibeTagsRemoveTag => 'Remove tag';

  @override
  String get vibeTagsSelectDescription =>
      'Select tags that match your current mood and intentions';

  @override
  String get vibeTagsSetTemporary => 'Set as temporary tag (24h)';

  @override
  String get vibeTagsShowYourVibe => 'Show your vibe';

  @override
  String get vibeTagsTemporaryDescription =>
      'Show this vibe for the next 24 hours';

  @override
  String get vibeTagsTemporaryTag => 'Temporary Tag (24h)';

  @override
  String get vibeTagsTitle => 'Your Vibe';

  @override
  String get vibeTagsUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get vibeTagsViewPlans => 'View Plans';

  @override
  String get vibeTagsYourSelected => 'Your Selected Tags';

  @override
  String get videoCallCategory => 'Video Call';

  @override
  String get view => 'View';

  @override
  String get viewAllChallenges => 'View All Challenges';

  @override
  String get viewAllLabel => 'View All';

  @override
  String get viewBadgesAchievementsLevel => 'View badges, achievements & level';

  @override
  String get viewMyProfile => 'View My Profile';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'GOLD MEMBER';

  @override
  String get vipPlatinumMember => 'PLATINUM VIP';

  @override
  String get vipPremiumBenefitsActive => 'Premium Benefits Active';

  @override
  String get vipSilverMember => 'SILVER MEMBER';

  @override
  String get virtualGiftsAddMessageHint => 'Add a message (optional)';

  @override
  String get voiceDeleteConfirm =>
      'Are you sure you want to delete your voice introduction?';

  @override
  String get voiceDeleteRecording => 'Delete Recording';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'Failed to start recording: $error';
  }

  @override
  String get voiceMicPermissionDenied =>
      'Microphone access is needed to record your voice intro';

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'Failed to upload recording: $error';
  }

  @override
  String get voiceIntro => 'Voice Introduction';

  @override
  String get voiceIntroSaved => 'Voice introduction saved';

  @override
  String get voiceIntroShort => 'Voice Intro';

  @override
  String get voiceIntroduction => 'Voice Introduction';

  @override
  String get voiceIntroductionInfo =>
      'Voice introductions help others get to know you better. This step is optional.';

  @override
  String get voiceIntroductionSubtitle =>
      'Record a short voice message (optional)';

  @override
  String get voiceIntroductionTitle => 'Voice introduction';

  @override
  String get voiceMicrophonePermissionRequired =>
      'Microphone permission is required';

  @override
  String get voiceMessageTooShort => 'Hold to record, release to send';

  @override
  String get voiceSlideToCancel => '‹ Slide to cancel';

  @override
  String get voiceReleaseToCancel => 'Release to cancel';

  @override
  String get voiceFailedToSend => 'Failed to send voice message';

  @override
  String get voiceRecordAgain => 'Record Again';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Record a short $seconds second introduction to let others hear your personality.';
  }

  @override
  String get voiceRecorded => 'Voice recorded';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'Recording... (max $maxDuration seconds)';
  }

  @override
  String get voiceRecordingReady => 'Recording ready';

  @override
  String get voiceRecordingSaved => 'Recording saved';

  @override
  String get voiceRecordingTips => 'Recording Tips';

  @override
  String get voiceSavedMessage => 'Your voice introduction has been updated';

  @override
  String get voiceSavedTitle => 'Voice Saved!';

  @override
  String get voiceStandOutWithYourVoice => 'Stand out with your voice!';

  @override
  String get voiceTapToRecord => 'Tap to record';

  @override
  String get voiceTipBeYourself => 'Be yourself and natural';

  @override
  String get voiceTipFindQuietPlace => 'Find a quiet place';

  @override
  String get voiceTipKeepItShort => 'Keep it short and sweet';

  @override
  String get voiceTipShareWhatMakesYouUnique => 'Share what makes you unique';

  @override
  String get voiceUploadFailed => 'Failed to upload voice recording';

  @override
  String get voiceUploading => 'Uploading...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic =>
      'Your access will begin on April 14th, 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'As a $tier member, you get early access before April 14th, 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'Your Access Date';

  @override
  String waitingCountLabel(String count) {
    return '$count waiting';
  }

  @override
  String get waitingCountdownLabel => 'Your Launch Date';

  @override
  String get waitingCountdownSubtitle =>
      'Thank you for registering! GreenGo Chat is launching soon. Get ready for an exclusive experience.';

  @override
  String get waitingCountdownTitle => 'Countdown to Launch';

  @override
  String waitingDaysRemaining(int days) {
    return '$days days';
  }

  @override
  String get waitingEarlyAccessMember => 'Early Access Member';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Enable notifications to be the first to know when you can access the app.';

  @override
  String get waitingEnableNotificationsTitle => 'Stay Updated';

  @override
  String get waitingExclusiveAccess =>
      'Time till you\'ll be eligible to use the app';

  @override
  String get waitingGeneralLaunchDate => 'General Launch Date';

  @override
  String get waitingYourAccessDate => 'Your Access Date';

  @override
  String get waitingForPlayers => 'Waiting for players...';

  @override
  String get waitingForVerification => 'Waiting for verification...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours hours';
  }

  @override
  String get waitingMessageApproved =>
      'Great news! Your account has been approved. You will be able to access GreenGoChat on the date shown below.';

  @override
  String get waitingMessagePending =>
      'Your account is pending approval from our team. We will notify you once your account has been reviewed.';

  @override
  String get waitingMessageRejected =>
      'Unfortunately, your account could not be approved at this time. Please contact support for more information.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get waitingNotificationEnabled =>
      'Notifications enabled - we\'ll let you know when you can access the app!';

  @override
  String get waitingProfileUnderReview => 'Profile Under Review';

  @override
  String get waitingReviewMessage =>
      'The app is now live! Our team is reviewing your profile to ensure the best experience for our community. This usually takes 24-48 hours.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get waitingStayTuned =>
      'Stay tuned! We\'ll notify you when it\'s time to start connecting.';

  @override
  String get waitingStepActivation => 'Account Activation';

  @override
  String get waitingStepRegistration => 'Registration Complete';

  @override
  String get waitingStepReview => 'Profile Review in Progress';

  @override
  String get waitingSubtitle => 'Your account has been created successfully';

  @override
  String get waitingThankYouRegistration => 'Thank you for registering!';

  @override
  String get waitingTitle => 'Thank You for Registering!';

  @override
  String get weeklyChallengesTitle => 'Weekly Challenges';

  @override
  String get weight => 'Weight';

  @override
  String get weightLabel => 'Weight';

  @override
  String get welcome => 'Welcome to GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Word already used';

  @override
  String get wordReported => 'Word reported';

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
    return '$amount XP earned';
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
  String get yearlyMembership => 'Yearly subscription';

  @override
  String yearsLabel(int age) {
    return '$age years';
  }

  @override
  String get yes => 'Yes';

  @override
  String get yesterday => 'yesterday';

  @override
  String youAndMatched(String name) {
    return 'You and $name want to exchange languages';
  }

  @override
  String get youGotSuperLike => 'You got a Priority Connect!';

  @override
  String get youLabel => 'YOU';

  @override
  String get youLose => 'You Lose';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'You matched with $name on $date';
  }

  @override
  String get youWin => 'You Win!';

  @override
  String get yourLanguages => 'Your Languages';

  @override
  String get yourRankLabel => 'Your Rank';

  @override
  String get yourTurn => 'Your Turn!';

  @override
  String get achievementBadges => 'Achievement Badges';

  @override
  String get achievementBadgesSubtitle =>
      'Tap to select which badges to display on your profile (max 5)';

  @override
  String get noBadgesYet => 'Unlock achievements to earn badges!';

  @override
  String get guideTitle => 'How GreenGo Works';

  @override
  String get guideSwipeTitle => 'Swiping Profiles';

  @override
  String get guideSwipeItem1 =>
      'Swipe right to Connect with someone, swipe left to Nope.';

  @override
  String get guideSwipeItem2 =>
      'Swipe up to send a Priority Connect (uses coins).';

  @override
  String get guideSwipeItem3 =>
      'Swipe down to Explore Next and skip a profile for now.';

  @override
  String get guideSwipeItem4 =>
      'You can switch between swipe and grid mode using the toggle icon in the top bar.';

  @override
  String get guideGridTitle => 'Grid View';

  @override
  String get guideGridItem1 =>
      'Browse profiles in a grid layout for a quick overview.';

  @override
  String get guideGridItem2 =>
      'Tap on a profile image to reveal the four action buttons: Connect, Priority Connect, Nope, and Explore Next.';

  @override
  String get guideGridItem3 =>
      'Long press on a profile image to see their details without opening the full profile.';

  @override
  String get guideConnectionsTitle => 'Connecting with People';

  @override
  String get guideConnectionsItem1 =>
      'When two people Connect with each other, it\'s a match!';

  @override
  String get guideConnectionsItem2 =>
      'After matching, you can start chatting right away.';

  @override
  String get guideConnectionsItem3 =>
      'Use Priority Connect to stand out and increase your chances.';

  @override
  String get guideConnectionsItem4 =>
      'Check the Exchanges tab to see all your matches and conversations.';

  @override
  String get guideChatTitle => 'Chat & Messaging';

  @override
  String get guideChatItem1 => 'Send text messages, photos, and voice notes.';

  @override
  String get guideChatItem2 =>
      'Use the translation feature to chat in different languages.';

  @override
  String get guideChatItem3 =>
      'Open chat settings to customize your experience: toggle grammar check, smart replies, cultural tips, word breakdown, pronunciation help, and more.';

  @override
  String get guideChatItem4 =>
      'Enable text-to-speech to hear translations, show language flags, and track your language learning XP.';

  @override
  String get guideFiltersTitle => 'Discovery Filters';

  @override
  String get guideFiltersItem1 =>
      'Tap the filter icon to set your preferences: age range, distance, languages, and more.';

  @override
  String get guideFiltersItem2 =>
      'Random Mode: enable this toggle to discover random people from all over the world. Each refresh gives you a new set of profiles. When Random Mode is off, only people close to you are shown. You can also select specific countries to narrow your search.';

  @override
  String get guideFiltersItem3 =>
      'Filters help you find people who match what you\'re looking for. You can adjust them anytime.';

  @override
  String get guideTravelTitle => 'Travel & Explore';

  @override
  String get guideTravelItem1 =>
      'Activate Traveler Mode to appear in discovery for a city you plan to visit for 24 hours.';

  @override
  String get guideTravelItem2 =>
      'Local Guides can help travelers discover their city and culture.';

  @override
  String get guideTravelItem3 =>
      'Language exchange partners are matched based on what you speak and what you want to learn.';

  @override
  String get guideMembershipTitle => 'Base Membership';

  @override
  String get guideMembershipItem1 =>
      'Your base membership gives you access to all core features: swiping, chatting, and matching.';

  @override
  String get guideMembershipItem2 =>
      'Membership starts with a free trial after your first sign-up.';

  @override
  String get guideMembershipItem3 =>
      'When your membership expires, you can renew it to continue using the app.';

  @override
  String get guideTiersTitle => 'VIP Tiers (Silver, Gold, Platinum)';

  @override
  String get guideTiersItem1 =>
      'Silver: Get more daily connects, see who connected with you, and priority support.';

  @override
  String get guideTiersItem2 =>
      'Gold: Everything in Silver plus unlimited connects, advanced filters, and read receipts.';

  @override
  String get guideTiersItem3 =>
      'Platinum: Everything in Gold plus profile boost, top picks, and exclusive features.';

  @override
  String get guideTiersItem4 =>
      'VIP tiers are independent from your base membership and provide extra perks.';

  @override
  String get guideCoinsTitle => 'Coins';

  @override
  String get guideCoinsItem1 =>
      'Coins are used for premium actions. Here are the costs:';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect: 10 coins  • Boost: 50 coins  • Direct Match: 2/day free, then 50 coins';

  @override
  String get guideCoinsItem3 =>
      '• Incognito: 30 coins/day  • Traveler: 100 coins/day';

  @override
  String get guideCoinsItem4 =>
      '• Listen (TTS): 5 coins  • Grid Extend: 10 coins  • Learning Coach: 10 coins/session';

  @override
  String get guideCoinsItem5 =>
      'You receive 20 free coins daily. Earn more through achievements, leaderboard rankings, and the Shop.';

  @override
  String get guideLeaderboardTitle => 'Leaderboard';

  @override
  String get guideLeaderboardItem1 =>
      'Compete with other users to climb the leaderboard and earn rewards.';

  @override
  String get guideLeaderboardItem2 =>
      'Earn points by being active, completing your profile, and engaging with others.';

  @override
  String get guideGridFiltersTitle => 'Grid Filters';

  @override
  String get guideGridFiltersItem1 =>
      'In grid mode, use the filter chips at the top to narrow down profiles.';

  @override
  String get guideGridFiltersItem2 =>
      'All: Shows everyone in your discovery pool.';

  @override
  String get guideGridFiltersItem3 =>
      'Connected: People you sent a Connect to.';

  @override
  String get guideGridFiltersItem4 =>
      'Priority: People you sent a Priority Connect to.';

  @override
  String get guideGridFiltersItem5 => 'Passed: People you chose to pass on.';

  @override
  String get guideGridFiltersItem6 =>
      'Travelers: People with Traveler Mode active, visiting a city near you.';

  @override
  String get guideExchangesTitle => 'Exchanges (Chat)';

  @override
  String get guideExchangesItem1 =>
      'Exchanges is where all your conversations live. You\'ll find it in the bottom menu.';

  @override
  String get guideExchangesItem2 =>
      'The red badge on the Exchanges icon shows the number of conversations with unread messages or pending approvals.';

  @override
  String get guideExchangesItem3 =>
      'Use the filter chips to organize your chats: All, New, Not Replied, Favorites, To Approve, Match, and Search.';

  @override
  String get guideExchangesItem4 =>
      'New shows conversations with new messages you haven\'t read. Not Replied shows messages you haven\'t responded to yet.';

  @override
  String get guideExchangesItem5 =>
      'To Approve shows Priority Connect requests waiting for your decision. Accept or reject them directly from the list.';

  @override
  String get guideExchangesItem6 =>
      'Unread conversations are highlighted with bold text and a gold shimmer effect so you can spot them easily.';

  @override
  String get guideExchangesItem7 =>
      'Tap a conversation to open the chat. Once opened, it\'s marked as read and the badge count decreases.';

  @override
  String get guideExchangesItem8 =>
      'Long press a conversation for more options. Use the star icon to add a chat to your Favorites.';

  @override
  String get guideExchangesItem9 =>
      'Each conversation shows the other user\'s language flags, so you know what languages they speak.';

  @override
  String get guideGroupsTitle => 'Groups (Culture Circles)';

  @override
  String get guideGroupsItem1 =>
      'Create a group to chat with several people at once around a shared interest or language.';

  @override
  String get guideGroupsItem2 =>
      'Admins can rename the group, change its photo, and add or remove members.';

  @override
  String get guideGroupsItem3 =>
      'Invite people by their nickname from Group Info.';

  @override
  String get guideGroupsItem4 =>
      'Add your own private tags to a group in Group Info, then filter your groups list by tag — only you can see your tags.';

  @override
  String get guideGroupsItem5 => 'Leave or report a group at any time.';

  @override
  String get guideEventsTitle => 'Events';

  @override
  String get guideEventsItem1 =>
      'Discover events near you — parties, museum visits, language meetups and city tours.';

  @override
  String get guideEventsItem2 =>
      'Browse curated experiences and attractions, or create your own event with photos, location and date.';

  @override
  String get guideEventsItem3 =>
      'Mark events as Going or Interested and find them again in your Going tab.';

  @override
  String get guideEventsItem4 =>
      'Every event has its own chat; organizers can broadcast announcements to all attendees.';

  @override
  String get guideEventsItem5 =>
      'Share any event into a private chat or a group.';

  @override
  String get guideEventsItem6 =>
      'Explore events around the world on the map, by location.';

  @override
  String get guideSafetyTitle => 'Safety & Privacy';

  @override
  String get guideSafetyItem1 =>
      'All photos are AI-verified to ensure authentic profiles.';

  @override
  String get guideSafetyItem2 =>
      'You can block or report any user at any time from their profile.';

  @override
  String get guideSafetyItem3 =>
      'Your personal information is protected and never shared without your consent.';

  @override
  String get firstStepsTitle => 'First Steps';

  @override
  String get firstStepsReview =>
      'Your documents will be reviewed within 24-48 hours after submission.';

  @override
  String get firstStepsStatusUpdate =>
      'The app needs approximately 15 minutes to update your current status after first login.';

  @override
  String get firstStepsSupportChat =>
      'You can contact support through chat or by opening a ticket directly.';

  @override
  String get showSupportUser => 'Show GreenGo Support';

  @override
  String get showSupportUserDescription =>
      'Show GreenGo Support user in discovery grid';

  @override
  String get preferenceShowMyNetwork => 'My Network';

  @override
  String get preferenceShowMyNetworkDesc => 'Show only people in your network.';

  @override
  String get randomMode => 'Random Mode';

  @override
  String get randomModeDescription =>
      'Discover random people from all over the world, sorted by distance. When off, only people close to you are shown.';

  @override
  String get yourProfile => 'You';

  @override
  String get loadingMsg1 => 'Looking for amazing profiles around the world...';

  @override
  String get loadingMsg2 => 'Connecting hearts across continents...';

  @override
  String get loadingMsg3 => 'Discovering incredible people near you...';

  @override
  String get loadingMsg4 => 'Preparing your personalized matches...';

  @override
  String get loadingMsg5 =>
      'Exploring profiles from every corner of the globe...';

  @override
  String get loadingMsg6 => 'Finding people who share your interests...';

  @override
  String get loadingMsg7 => 'Setting up your discovery experience...';

  @override
  String get loadingMsg8 => 'Loading beautiful profiles just for you...';

  @override
  String get loadingMsg9 => 'Searching for your perfect match...';

  @override
  String get loadingMsg10 => 'Bringing the world closer to you...';

  @override
  String get loadingMsg11 => 'Curating profiles based on your preferences...';

  @override
  String get loadingMsg12 => 'Almost there! Great things take a moment...';

  @override
  String get loadingMsg13 => 'Connecting you to a world of possibilities...';

  @override
  String get loadingMsg14 => 'Finding the best matches in your area...';

  @override
  String get loadingMsg15 => 'Unlocking new connections around you...';

  @override
  String get loadingMsg16 =>
      'Your next great conversation is just a swipe away...';

  @override
  String get loadingMsg17 => 'Gathering profiles from around the world...';

  @override
  String get loadingMsg18 => 'Preparing something special for you...';

  @override
  String get loadingMsg19 => 'Making sure everything is perfect...';

  @override
  String get loadingMsg20 => 'Love knows no borders, and neither do we...';

  @override
  String get loadingMsg21 => 'Warming up your discovery feed...';

  @override
  String get loadingMsg22 => 'Scanning the globe for interesting people...';

  @override
  String get loadingMsg23 => 'Great connections start here...';

  @override
  String get loadingMsg24 => 'Your adventure is about to begin...';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterToApprove => 'To Approve';

  @override
  String get priorityConnectAccept => 'Accept';

  @override
  String get priorityConnectReject => 'Reject';

  @override
  String get priorityConnectPending => 'Pending approval';

  @override
  String get membershipTrialTitle => 'Start Your Free Trial!';

  @override
  String get membershipTrialSubtitle => '7 days free, then auto-renews yearly';

  @override
  String get membershipTrialFeature1 =>
      'Create unlimited communities, events & groups';

  @override
  String get membershipTrialFeature2 =>
      'Ad-free experience — no advertisements';

  @override
  String get membershipTrialFeature3 =>
      '500 bonus coins + full access to every feature';

  @override
  String get membershipHaveCoupon => 'Have a coupon code?';

  @override
  String get membershipTrialCta => 'Start 7-Day Free Trial';

  @override
  String get membershipTrialFooter => 'Cancel anytime. No charge until day 8.';

  @override
  String get membershipTrialBadge => 'FREE FOR 7 DAYS';

  @override
  String get globeMyNetwork => 'My Network';

  @override
  String get globeMyWorldMap => 'My World Map';

  @override
  String get globeLayerContacts => 'My Community';

  @override
  String get globeLayerExperiences => 'Experiences';

  @override
  String get globeYou => 'You';

  @override
  String get globeConnections => 'Connections';

  @override
  String get globeTraveler => 'Traveler';

  @override
  String globeConnectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'connections',
      one: 'connection',
    );
    return '$count $_temp0';
  }

  @override
  String globeConnectionsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'connections',
      one: 'connection',
    );
    return '$count $_temp0 here';
  }

  @override
  String get globeThisIsYou => 'This is you!';

  @override
  String globeTravelingTo(String country) {
    return 'Traveling to $country';
  }

  @override
  String globeNoConnectionsInCountry(String country) {
    return 'No connections in $country yet';
  }

  @override
  String get globeNoConnectionsHint => 'Keep connecting to find people here!';

  @override
  String get globeProfile => 'Profile';

  @override
  String get globeChat => 'Chat';

  @override
  String get globeViewProfileTooltip => 'View Profile';

  @override
  String get globeOpenChatTooltip => 'Open Chat';

  @override
  String globeNoConnectionsInCountryTitle(String country) {
    return 'No connections in $country';
  }

  @override
  String get discoverabilityExact => 'Exact';

  @override
  String get discoverabilityExactDesc => 'Pin at your exact location (<1km)';

  @override
  String get discoverabilityApproximate => 'Approximate';

  @override
  String get discoverabilityApproximateDesc =>
      'Pin in your region (~50km grid, default)';

  @override
  String get discoverabilityCountry => 'Country';

  @override
  String get discoverabilityCountryDesc => 'Pin somewhere in your country';

  @override
  String get discoverabilityHidden => 'Hidden';

  @override
  String get discoverabilityHiddenDesc => 'Not discoverable on the Map';

  @override
  String get discoverabilityTitle => 'Globe Discoverability';

  @override
  String get discoverabilityInfo =>
      'Your connections always see you on the Map, regardless of this setting.';

  @override
  String get discoverabilityChangedExact => 'Location set to exact';

  @override
  String get discoverabilityChangedApproximate => 'Location set to approximate';

  @override
  String get discoverabilityChangedCountry => 'Location set to country level';

  @override
  String get discoverabilityChangedHidden => 'You are now hidden from the map';

  @override
  String get onboardingExitTitle => 'Exit registration?';

  @override
  String get onboardingExitMessage =>
      'You\'ll be signed out. You can finish setting up your profile next time you log in.';

  @override
  String get onboardingExitConfirm => 'Sign Out';

  @override
  String get onboardingExitCancel => 'Cancel';

  @override
  String get loginEmailOrNickname => 'Email / Nickname';

  @override
  String get paymentVerifying => 'Verifying your payment...';

  @override
  String get paymentSuccess => 'Payment Successful!';

  @override
  String get paymentSuccessMessage =>
      'Your purchase has been credited to your account.';

  @override
  String get paymentPending => 'Payment Processing';

  @override
  String get paymentPendingMessage =>
      'Your payment is being processed. It may take a few minutes to appear.';

  @override
  String get paymentCancelled => 'Payment Cancelled';

  @override
  String get paymentCancelledMessage =>
      'Your payment was cancelled. No charges were made.';

  @override
  String get continueToApp => 'Continue';

  @override
  String get webCheckoutOpening => 'Opening secure checkout…';

  @override
  String get webCheckoutWaiting =>
      'Complete your payment in the new tab. This window will update automatically once it\'s done.';

  @override
  String get webCheckoutTimeout =>
      'We couldn\'t confirm your payment yet. If you completed it, your balance will update shortly.';

  @override
  String get webCheckoutFailed => 'Couldn\'t start checkout. Please try again.';

  @override
  String get groupNewGroup => 'New group';

  @override
  String get groupCreate => 'Create';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String groupSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get groupInviteByNickname => 'Invite by nickname';

  @override
  String get groupAddMembers => 'Add members';

  @override
  String get groupTtsReadTranslated => 'Read aloud the translation';

  @override
  String get groupTtsReadTranslatedHint =>
      'Double-tap a message to hear it. On = your language, Off = original.';

  @override
  String get ttsNotEnoughCoins => 'Not enough coins for TTS (5 coins required)';

  @override
  String get groupRemoveMember => 'Remove member';

  @override
  String groupRemoveMemberConfirm(String name) {
    return 'Remove $name from this group?';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name removed';
  }

  @override
  String groupAddSelected(int count) {
    return 'Add $count selected';
  }

  @override
  String get groupNicknameHint => 'Enter a nickname';

  @override
  String get groupNoContacts => 'No contacts to add yet';

  @override
  String get groupNoOneFound => 'No one found with that nickname';

  @override
  String get groupAlreadyAdded => 'Already added';

  @override
  String groupAddedCount(int count) {
    return 'Added $count';
  }

  @override
  String get groupSearchFailed => 'Search failed';

  @override
  String get groupInfo => 'Group info';

  @override
  String groupMembersCount(int count) {
    return '$count members';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupYou => 'You';

  @override
  String get groupLeave => 'Leave group';

  @override
  String get groupDelete => 'Delete group';

  @override
  String get groupDeleteConfirmTitle => 'Delete group?';

  @override
  String get groupDeleteConfirmBody =>
      'This permanently deletes the group and all its messages for everyone. This cannot be undone.';

  @override
  String get groupLeaveConfirmTitle => 'Leave group?';

  @override
  String get groupLeaveConfirmBody =>
      'You will stop receiving messages from this group.';

  @override
  String get groupCancel => 'Cancel';

  @override
  String get groupLeaveAction => 'Leave';

  @override
  String get groupReport => 'Report group';

  @override
  String get groupReportConfirmBody => 'Report this group to our safety team?';

  @override
  String get groupReportAction => 'Report';

  @override
  String get groupReportSubmitted => 'Report submitted';

  @override
  String get groupMessageHint => 'Message…';

  @override
  String get groupSayHello => 'Say hello to the group 👋';

  @override
  String get groupLoadError => 'Couldn\'t load this group';

  @override
  String get chatLocation => 'Location';

  @override
  String get chatShareLocation => 'Share location';

  @override
  String get chatLocationDenied =>
      'Location permission is required to share your position';

  @override
  String get chatOpenInMaps => 'Open in Maps';

  @override
  String get eventsSearchHint => 'Search by country, city or name';

  @override
  String get eventsSortPopular => 'Popular';

  @override
  String get eventsViewList => 'List view';

  @override
  String get eventsViewGrid => 'Grid view';

  @override
  String get eventViewEvent => 'View event';

  @override
  String get eventLoadError => 'Couldn\'t load this event';

  @override
  String get eventShare => 'Share event';

  @override
  String get eventReport => 'Report event';

  @override
  String get eventReportTitle => 'Report this event?';

  @override
  String get eventReportBody =>
      'Our team will review it. You won\'t see this event anymore.';

  @override
  String get eventReported => 'Event reported';

  @override
  String get shareAsLink => 'Share as link';

  @override
  String get eventShared => 'Event shared';

  @override
  String get eventShareEmpty => 'No chats or groups to share with yet';

  @override
  String get eventsUnlimitedAttendees => 'Unlimited attendees';

  @override
  String get eventsPrivateEvent => 'Private event';

  @override
  String get eventsExternalLinks => 'Links';

  @override
  String get eventsLinkUrlHint => 'https://…';

  @override
  String get eventsAddLink => 'Add link';

  @override
  String get tierLimitTitle => 'Upgrade to create more';

  @override
  String tierLimitEventsBody(int max) {
    return 'Your plan allows $max events. Upgrade to create more.';
  }

  @override
  String tierLimitGroupsBody(int max) {
    return 'Your plan allows $max groups. Upgrade to create more.';
  }

  @override
  String get groupsTitle => 'Groups';

  @override
  String get profileRankingSubtitle => 'See the global leaderboard';

  @override
  String get eventBroadcastTooltip => 'Broadcast to everyone';

  @override
  String get eventBroadcastHint => 'Announcement to all attendees…';

  @override
  String get eventBroadcastLabel => 'Announcement';

  @override
  String get eventsFeatured => 'Featured';

  @override
  String get eventsInsufficientCoins => 'Not enough coins';

  @override
  String get eventsConfirmAction => 'Confirm';

  @override
  String get eventsBoost => 'Boost';

  @override
  String get eventsBoosted => 'Event featured!';

  @override
  String eventsJoinForCoins(int cost) {
    return 'Join this event for $cost coins?';
  }

  @override
  String eventsBoostConfirm(int cost) {
    return 'Boost this event for $cost coins?';
  }

  @override
  String groupMemberLimit(int count) {
    return 'Up to $count members per group';
  }

  @override
  String get eventsPriceHint => 'Price (1–1000)';

  @override
  String get eventsPriceRange => 'Enter a price between 1 and 1000';

  @override
  String get eventsLinkLabelHint => 'Label (optional)';

  @override
  String get eventsPickLocation => 'Pick location';

  @override
  String get eventsSearchAddress => 'Search address';

  @override
  String get eventsUseThisLocation => 'Use this location';

  @override
  String get eventsEditEvent => 'Edit event';

  @override
  String get groupEditName => 'Edit group name';

  @override
  String get groupChangePhoto => 'Change group photo';

  @override
  String get groupUploadingPhoto => 'Uploading photo…';

  @override
  String get groupPhotoUpdated => 'Group photo updated';

  @override
  String get groupPhotoUpdateFailed => 'Failed to update group photo';

  @override
  String get eventTextProhibited =>
      'Title or description contains prohibited language and cannot be used';

  @override
  String get groupSearchHint => 'Search groups';

  @override
  String get groupNoSearchResults => 'No groups found';

  @override
  String get groupMyTags => 'My tags';

  @override
  String get groupMyTagsSubtitle => 'Private — only you can see these';

  @override
  String get groupNoTagsYet => 'No tags yet';

  @override
  String get groupTagsEditTitle => 'Edit my tags';

  @override
  String get groupAddTagHint => 'Add a tag';

  @override
  String get groupTagsSave => 'Save';

  @override
  String get groupTagsSaved => 'Tags saved';

  @override
  String get groupTagsSaveFailed => 'Couldn\'t save tags';

  @override
  String get groupTagsLimitReached => 'Tag limit reached';

  @override
  String peopleTagsEditTitle(String name) {
    return 'Tags for $name';
  }

  @override
  String get groupTranslationSettings => 'Translation';

  @override
  String get groupTranslateMessages => 'Translate messages';

  @override
  String get groupShowOriginal => 'Show original text';

  @override
  String get eventsTabLiveEvents => 'Live Events';

  @override
  String get globeLayerLiveEvents => 'Live Events';

  @override
  String get eventsSortBy => 'Sort by';

  @override
  String get eventsSortDistance => 'Distance';

  @override
  String get eventsSortStars => 'Stars';

  @override
  String get eventsSortReviews => 'Reviews';

  @override
  String get eventsSortDate => 'Date';

  @override
  String get catMuseums => 'Museums';

  @override
  String get catSights => 'Sights';

  @override
  String get catParks => 'Parks';

  @override
  String get catNationalParks => 'National parks';

  @override
  String get catThemeParks => 'Theme parks';

  @override
  String get catTours => 'Tours & Sightseeing';

  @override
  String get catCulture => 'Culture & Museums';

  @override
  String get catFoodDrink => 'Food & Drink';

  @override
  String get catCruises => 'Cruises & Water';

  @override
  String get catNature => 'Nature & Outdoors';

  @override
  String get catDayTrips => 'Day Trips';

  @override
  String get catTickets => 'Tickets & Passes';

  @override
  String get catOther => 'Other';

  @override
  String get eventsUnlimited => 'Unlimited';

  @override
  String get eventsTabGoing => 'Going';

  @override
  String get globeLayerCommunityEvents => 'Community events';

  @override
  String get webMapUnavailableTitle =>
      'Interactive map available on the mobile app';

  @override
  String get webMapUnavailableBody =>
      'Search for an address to set your location.';

  @override
  String get webLocationPickerTitle => 'Pick your location';

  @override
  String get webLocationSearchHint => 'Search city or address';

  @override
  String get webLocationConfirm => 'Use this location';

  @override
  String get webLocationTapHint => 'Tap the map to drop a pin';

  @override
  String webLocationMonthlyLimit(String date) {
    return 'You can update your location once a month on the web. Next update available $date.';
  }

  @override
  String get eventMyTicket => 'My ticket';

  @override
  String get eventTicketDelete => 'Delete ticket';

  @override
  String get eventTicketDeleteConfirm =>
      'Permanently delete this ticket? The event has already ended.';

  @override
  String get eventScanCheckIn => 'Scan / Check-in';

  @override
  String get eventScanUseMobileApp =>
      'QR check-in scanning is available in the GreenGo mobile app.';

  @override
  String get eventScanManageScanners => 'Manage scanners';

  @override
  String get eventScanInviteScannerHint =>
      'Invite a member to scan tickets at the door.';

  @override
  String get eventScanNicknameHint => 'Nickname';

  @override
  String get eventScanAddScanner => 'Add';

  @override
  String get eventScanScannerNotFound => 'No member found with that nickname';

  @override
  String get eventScanScannerAddFailed => 'Could not add scanner. Try again.';

  @override
  String eventScanScannerAdded(String name) {
    return '$name can now scan tickets';
  }

  @override
  String get eventAttendance => 'Attendance';

  @override
  String get eventCheckedIn => 'Checked in';

  @override
  String get eventNotCheckedIn => 'Not here yet';

  @override
  String get eventGuestsAllowedLabel => 'Guests allowed per attendee';

  @override
  String get eventBringGuests => 'Bring guests';

  @override
  String get eventInvalidTicket => 'Invalid ticket for this event';

  @override
  String get eventScanInstructions =>
      'Point the camera at an attendee\'s QR code';

  @override
  String get eventTotalHeadcount => 'Total headcount';

  @override
  String get eventCameraPermission => 'Camera permission is required to scan';

  @override
  String get eventTicketSubtitle => 'Show this QR at the entrance';

  @override
  String eventGuestCount(int count, int max) {
    return '$count of $max guests';
  }

  @override
  String eventCheckedInSuccess(String name) {
    return '$name checked in';
  }

  @override
  String eventAlreadyCheckedIn(String name) {
    return '$name already checked in';
  }

  @override
  String eventGuestsBringing(int count) {
    return '+$count guests';
  }

  @override
  String connectDailyLimitReached(int limit) {
    return 'You\'ve reached your daily limit of $limit new connections. Upgrade to connect with more people!';
  }

  @override
  String get boostFeatureName => 'Profile Boost';

  @override
  String get boostRequiresTierDescription =>
      'Profile boosts are a paid-membership perk. Upgrade your plan to boost your profile and get seen by more people.';

  @override
  String boostMonthlyLimitReached(int limit) {
    return 'You\'ve used all $limit profile boosts included in your plan this month. Upgrade for more.';
  }

  @override
  String get travelModeFeatureName => 'Traveler Mode';

  @override
  String get travelModeRequiresTierDescription =>
      'Traveler Mode lets you appear in another city\'s discovery feed. Upgrade your plan to unlock it.';

  @override
  String get exploreRecommended => 'Recommended for you';

  @override
  String get businessAccountTitle => 'Business account';

  @override
  String get becomeBusiness => 'Become a business';

  @override
  String get businessProfileLabel => 'Business profile';

  @override
  String get businessCategoryLabel => 'Business category';

  @override
  String get businessCategoryHint => 'Select a category';

  @override
  String get businessVerifiedLabel => 'Verified business';

  @override
  String get featureThisEvent => 'Feature this event';

  @override
  String featureEventCostLabel(int cost) {
    return 'Feature this event · $cost coins';
  }

  @override
  String featureEventActive(String date) {
    return 'Featured until $date';
  }

  @override
  String featureEventConfirm(int cost) {
    return 'Feature this event for $cost coins?';
  }

  @override
  String get referralTitle => 'Invite friends';

  @override
  String get referralInviteFriends => 'Invite friends';

  @override
  String get referralYourCode => 'Your referral code';

  @override
  String get referralShareCta => 'Share';

  @override
  String get referralShareMessage => 'Join me on GreenGo!';

  @override
  String get referralRewardEarned => 'Coins earned';

  @override
  String get referralCountLabel => 'Friends invited';

  @override
  String referralHowItWorks(int coins, int monthlyCap) {
    final intl.NumberFormat coinsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String coinsString = coinsNumberFormat.format(coins);
    final intl.NumberFormat monthlyCapNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthlyCapString = monthlyCapNumberFormat.format(monthlyCap);

    return 'Share your code — when a friend joins with it, you earn $coinsString coins (up to $monthlyCapString a month) and they get 1 month of Platinum.';
  }

  @override
  String get referralHowItWorksTitle => 'How it works';

  @override
  String get achievementsLoadError => 'Couldn\'t load achievements';

  @override
  String get loadErrorCheckConnection => 'Check your connection and try again.';

  @override
  String get streakTitle => 'Streak';

  @override
  String get streakDaysLabel => 'day streak';

  @override
  String get streakKeepGoing => 'Keep it going!';

  @override
  String get missionsTitle => 'Missions';

  @override
  String get missionsSubtitle => 'Complete missions to earn coins';

  @override
  String get missionProgressLabel => 'Progress';

  @override
  String get missionRewardLabel => 'Reward';

  @override
  String get missionCompleteLabel => 'Completed';

  @override
  String get onboardingWelcomeTitle => 'Welcome to GreenGo';

  @override
  String get onboardingWelcomeBody =>
      'Discover cultures, practice languages, find local events, and meet people near you — no language barriers.';

  @override
  String get onboardingPickInterests => 'What do you love?';

  @override
  String get onboardingPickLanguages => 'Languages you speak';

  @override
  String get savedSearchesTitle => 'Saved searches';

  @override
  String get saveThisSearch => 'Save this search';

  @override
  String get savedSearchSaved => 'Search saved';

  @override
  String get savedSearchRun => 'Run';

  @override
  String get savedSearchEmpty => 'No saved searches yet';

  @override
  String get savedSearchAlertsToggle => 'Alerts';

  @override
  String get exploreFeaturedCommunity => 'Featured community events';

  @override
  String get notificationMarkAllRead => 'Mark all read';

  @override
  String get notificationsDeleteUnread => 'Delete unread';

  @override
  String get notificationsDeleteAll => 'Delete all';

  @override
  String get notificationsDeleteAllConfirm =>
      'Permanently delete all notifications on this page? This cannot be undone.';

  @override
  String get notificationsDeleteUnreadConfirm =>
      'Permanently delete all unread notifications? This cannot be undone.';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsPlatinumOnly => 'Analytics is a Platinum feature.';

  @override
  String get analyticsEventsHosted => 'Events hosted';

  @override
  String get analyticsTotalAttendees => 'Total attendees';

  @override
  String get analyticsReach => 'Reach';

  @override
  String get analyticsUpgradeCta => 'Upgrade to Platinum';

  @override
  String get safetyVerifiedBadge => 'Verified';

  @override
  String get safetyReportUser => 'Report';

  @override
  String get safetyBlockUser => 'Block';

  @override
  String get safetyCheckInTitle => 'Safety check-in';

  @override
  String get safetyCheckInArrived => 'I\'ve arrived safely';

  @override
  String get safetyCheckInDone => 'You checked in safely';

  @override
  String get guidelinesTitle => 'Community guidelines';

  @override
  String get guidelinesAccept => 'Accept community guidelines';

  @override
  String get guidelinesBody =>
      'GreenGo is a cross-cultural community for discovery, language exchange, local events and friendship. Be respectful and welcoming to people from every culture. This is not a dating app. No harassment, hate speech, spam or explicit content. Report anything that doesn\'t belong.';

  @override
  String get businessSectionTitle => 'Business';

  @override
  String get businessSectionSubtitle => 'Tools for your business';

  @override
  String get businessHubAccount => 'Business account';

  @override
  String get businessHubAnalytics => 'Analytics';

  @override
  String get businessHubFeatured => 'Featured placements';

  @override
  String get becomeBusinessAction => 'Become one';

  @override
  String get becomeBusinessPermanentHint =>
      'One-time upgrade. This can\'t be undone.';

  @override
  String get becomeBusinessConfirmTitle => 'Become a business account?';

  @override
  String get becomeBusinessConfirmMessage =>
      'This is permanent — your account becomes a public business account and can\'t be switched back.';

  @override
  String get becomeBusinessConfirmAction => 'Make it permanent';

  @override
  String get becomeBusinessSuccess => 'Your account is now a business account.';

  @override
  String get becomeBusinessError =>
      'Couldn\'t switch your account. Please try again.';

  @override
  String get businessAccountActive => 'Business account active (permanent)';

  @override
  String get businessRequiresPlatinum =>
      'Business accounts are a Platinum feature. Upgrade to unlock your storefront, followers and lead capture.';

  @override
  String get viewStorefront => 'View storefront';

  @override
  String get requestVerification => 'Request verification';

  @override
  String get requestVerificationPending => 'Verification pending';

  @override
  String get requestVerificationTitle => 'Request verification';

  @override
  String get verifyBusinessNameLabel => 'Business name';

  @override
  String get verifyLegalNameLabel => 'Legal name';

  @override
  String get verifyLegalNameHint => 'Registered legal entity name';

  @override
  String get verifyPhoneLabel => 'Phone number';

  @override
  String get verifyPhoneHint => '+1 555 123 4567';

  @override
  String get verifyPhoneFormatError =>
      'Enter your number in international format, e.g. +12025550123';

  @override
  String get verifySendCode => 'Send code';

  @override
  String get verifyResendCode => 'Resend';

  @override
  String get verifyEnterCodeLabel => '6-digit code';

  @override
  String get verifyConfirmCode => 'Verify';

  @override
  String get verifyPhoneVerified => 'Phone verified';

  @override
  String get verifyOwnerDocumentLabel => 'Owner\'s ID document';

  @override
  String get verifyUploadDocument => 'Upload document';

  @override
  String get verifyDocumentUploaded => 'Document uploaded';

  @override
  String get verifyDocumentUploadError =>
      'Couldn\'t upload the document. Please try again.';

  @override
  String get verifyWebsiteLabel => 'Website (optional)';

  @override
  String get verifyWebsiteHint => 'https://example.com';

  @override
  String get verifyNotesLabel => 'Notes (optional)';

  @override
  String get verifyMissingFields =>
      'Please complete all required fields and verify your phone.';

  @override
  String get requestVerificationMessage =>
      'Tell us a little about your business so we can verify it. Our team will review your request.';

  @override
  String get requestVerificationNoteHint =>
      'Add a note (website, address, anything that helps us verify you)';

  @override
  String get requestVerificationSubmitted => 'Verification request submitted.';

  @override
  String get requestVerificationError =>
      'Couldn\'t submit your request. Please try again.';

  @override
  String get submit => 'Submit';

  @override
  String get businessVerifiedBadgeTooltip => 'Verified business';

  @override
  String get businessLinks => 'Links';

  @override
  String get businessOpeningHours => 'Opening hours';

  @override
  String get businessHoursNotProvided => 'Opening hours not provided';

  @override
  String get businessGallery => 'Gallery';

  @override
  String get businessUpcomingEvents => 'Upcoming events';

  @override
  String get businessNoUpcomingEvents => 'No upcoming events yet.';

  @override
  String get businessCommunities => 'Communities';

  @override
  String get businessNoCommunities => 'No communities yet.';

  @override
  String get businessContact => 'Contact';

  @override
  String get businessFollow => 'Follow';

  @override
  String get businessFollowing => 'Following';

  @override
  String get businessFollowError =>
      'Couldn\'t update follow. Please try again.';

  @override
  String businessFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count followers',
      one: '1 follower',
      zero: 'No followers',
    );
    return '$_temp0';
  }

  @override
  String businessMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get adminBusinessVerifications => 'Business Verifications';

  @override
  String get adminBusinessVerificationsSubtitle =>
      'Review and approve business verified badges';

  @override
  String get adminApproveBusinessVerification => 'Approve';

  @override
  String get adminRejectBusinessVerification => 'Reject Business Verification';

  @override
  String get adminBusinessRejectReasonHint => 'Reason for rejection (optional)';

  @override
  String get adminBusinessApproved => 'Business verified';

  @override
  String get adminBusinessRejected => 'Business verification rejected';

  @override
  String get adminNoPendingBusinessVerifications =>
      'No pending business verifications';

  @override
  String get adminAccessDenied => 'Access denied. Admins only.';

  @override
  String get adminBusinessVerifiedNotificationTitle =>
      'Your business is verified';

  @override
  String get adminBusinessVerifiedNotificationBody =>
      'Your business now shows the gold verified badge.';

  @override
  String adminSubmittedLabel(String date) {
    return 'Submitted $date';
  }

  @override
  String get communitiesSponsored => 'Sponsored';

  @override
  String get communitiesSponsorThisCommunity => 'Sponsor this community';

  @override
  String get communitiesSponsorSubtitle => 'Pin a promo to the top for members';

  @override
  String get communitiesSponsorFeatureName => 'Community sponsorship';

  @override
  String get communitiesSponsorRequiresPlatinum =>
      'Sponsoring a community and pinning a promo is a Platinum business feature.';

  @override
  String get communitiesEditSponsorship => 'Edit sponsorship & promo';

  @override
  String get communitiesMarkAsSponsored => 'Mark as sponsored';

  @override
  String get communitiesPromoTitleLabel => 'Promo title';

  @override
  String get communitiesPromoTitleHint => 'e.g. 20% off this weekend';

  @override
  String get communitiesPromoBodyLabel => 'Promo message';

  @override
  String get communitiesPromoBodyHint => 'Tell members about your offer';

  @override
  String get communitiesPromoImageLabel => 'Image URL (optional)';

  @override
  String get communitiesPromoLinkEventLabel => 'Linked event ID (optional)';

  @override
  String get communitiesPromoLinkUrlLabel => 'Link URL (optional)';

  @override
  String get communitiesPromoTitleRequired => 'Please enter a promo title';

  @override
  String get communitiesSaveSponsorship => 'Save';

  @override
  String get communitiesRemovePromo => 'Remove promo';

  @override
  String get exploreSearchTooltip => 'Search';

  @override
  String get exploreQrTooltip => 'My QR codes';

  @override
  String get universalSearchTitle => 'Search';

  @override
  String get universalSearchHint => 'Search people and events';

  @override
  String get universalSearchTabPeople => 'People';

  @override
  String get universalSearchTabEvents => 'Events';

  @override
  String get universalSearchEmptyPrompt =>
      'Find people to chat with and events to join';

  @override
  String get universalSearchNoPeople => 'No people found';

  @override
  String get universalSearchNoEvents => 'No events found';

  @override
  String get qrHubTitle => 'QR codes';

  @override
  String get qrHubTabMyTickets => 'My tickets';

  @override
  String get qrHubTabScan => 'Scan';

  @override
  String get qrHubNoTickets =>
      'No upcoming tickets yet. Join an event to get your QR code.';

  @override
  String get qrHubTicketHint => 'Tap a ticket to open its full QR code';

  @override
  String get qrHubScanInstructions => 'Point your camera at a GreenGo QR code';

  @override
  String get qrHubInvalidCode => 'That\'s not a valid GreenGo code';

  @override
  String get qrScanApproved => 'Approved — checked in';

  @override
  String get qrScanNotAuthorized =>
      'Only the event owner or an invited scanner can redeem tickets';

  @override
  String get qrHubJoinedEvent => 'You\'re going! Opening the event…';

  @override
  String get eventsRepeats => 'Repeats';

  @override
  String get eventsRepeatNone => 'Does not repeat';

  @override
  String get eventsRepeatDaily => 'Daily';

  @override
  String get eventsRepeatWeekly => 'Weekly';

  @override
  String get eventsRepeatMonthly => 'Monthly';

  @override
  String get eventsRepeatInterval => 'Every';

  @override
  String get eventsRepeatCount => 'Occurrences';

  @override
  String get eventsRecurringLabel => 'Recurring';

  @override
  String get eventsCancelSeries => 'Cancel entire series';

  @override
  String get eventsCancelSeriesConfirm =>
      'Cancel all future occurrences of this recurring event?';

  @override
  String get eventsSeriesCancelled => 'Series cancelled';

  @override
  String get eventsSeriesCancelError => 'Couldn\'t cancel the series';

  @override
  String get eventsSaveAsDraft => 'Save as draft';

  @override
  String get eventsSchedule => 'Schedule';

  @override
  String get eventsStatusDraft => 'Draft';

  @override
  String get eventsStatusScheduled => 'Scheduled';

  @override
  String get eventsStatusCancelled => 'Cancelled';

  @override
  String eventsScheduledForDate(String date) {
    return 'Scheduled for $date';
  }

  @override
  String eventsRepeatCap(int max) {
    return 'Up to $max occurrences';
  }

  @override
  String get eventsTicketTiers => 'Ticket tiers';

  @override
  String get eventsRepeatHelper =>
      '\'Every\' sets the gap between dates (e.g. every 2 weeks); \'Occurrences\' is how many dates are created in total.';

  @override
  String get eventsTicketTiersHelper =>
      'Optional price levels (e.g. Standard, VIP) that set ticket price and capacity. They do not control coin access to the event.';

  @override
  String get eventsAddTier => 'Add tier';

  @override
  String get eventsTierName => 'Tier name';

  @override
  String get eventsTierPriceCoins => 'Price (coins, 0 = free)';

  @override
  String get eventsTierCapacity => 'Capacity (0 = unlimited)';

  @override
  String get eventsFreeTier => 'Free';

  @override
  String get eventsSelectTier => 'Select a ticket';

  @override
  String get eventsJoinWaitlist => 'Join waitlist';

  @override
  String get eventsOnWaitlist => 'On waitlist';

  @override
  String eventsWaitlistPosition(int position) {
    return 'You\'re #$position on the waitlist';
  }

  @override
  String eventsTierPriceValue(int coins) {
    return '$coins coins';
  }

  @override
  String eventsTierCapacityValue(int capacity) {
    return '$capacity spots';
  }

  @override
  String get eventsRsvpError => 'Couldn\'t update your RSVP';

  @override
  String get shareProfileTooltip => 'Share profile';

  @override
  String shareProfileMessage(String link) {
    return 'Chat with me on GreenGo: $link';
  }

  @override
  String shareEventMessage(String link) {
    return 'Check out this event on GreenGo: $link';
  }

  @override
  String get guidelinesSubtitle => 'A quick welcome to how we connect here';

  @override
  String get guidelinesWelcomeTitle => 'Welcome across cultures';

  @override
  String get guidelinesWelcomeDesc =>
      'Meet people from everywhere and share your world with openness.';

  @override
  String get guidelinesRespectTitle => 'Respect everyone';

  @override
  String get guidelinesRespectDesc =>
      'Kindness and curiosity first — treat others as you\'d like to be treated.';

  @override
  String get guidelinesAuthenticTitle => 'Stay authentic';

  @override
  String get guidelinesAuthenticDesc =>
      'GreenGo is for genuine cultural connection — it is not a dating app.';

  @override
  String get guidelinesSafetyTitle => 'No harassment or hate';

  @override
  String get guidelinesSafetyDesc =>
      'Harassment, hate speech, and threats have no place here.';

  @override
  String get guidelinesNoSpamTitle => 'No spam or explicit content';

  @override
  String get guidelinesNoSpamDesc =>
      'Keep it clean — no spam, scams, or sexual content.';

  @override
  String get guidelinesReportTitle => 'Report anything wrong';

  @override
  String get guidelinesReportDesc =>
      'See something off? Report it and our team will take a look.';

  @override
  String get businessNewBadge => 'NEW';

  @override
  String get businessLeadsTitle => 'Leads';

  @override
  String get businessLeadsEmpty =>
      'No leads yet. People who contact you or save your events will show up here.';

  @override
  String get businessLeadContact => 'Contacted you';

  @override
  String get businessLeadSavedEvent => 'Saved your event';

  @override
  String get eventTicketWhen => 'When';

  @override
  String get eventTicketVenue => 'Venue';

  @override
  String get eventTicketWhere => 'Where';

  @override
  String get eventTicketGuestsLabel => 'Guests';

  @override
  String eventTicketAdmits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Admits $count people',
      one: 'Admits 1 person',
    );
    return '$_temp0';
  }

  @override
  String get shareEvent => 'Share event';

  @override
  String get promoteTitle => 'Promote';

  @override
  String get promoteSubtitle => 'Boost your visibility with GreenGoCoins';

  @override
  String get promoteBusinessOption => 'Promote business';

  @override
  String get promoteBusinessDesc =>
      'Feature your storefront at the top of Explore';

  @override
  String get promoteEventsOption => 'Promote an event';

  @override
  String get promoteEventsDesc => 'Feature one of your events in discovery';

  @override
  String get promoteChooseDuration => 'Choose a duration';

  @override
  String get promoteNotActive => 'Not currently promoted';

  @override
  String get promoteConfirmTitle => 'Confirm promotion';

  @override
  String get promoteConfirmCta => 'Promote';

  @override
  String get promoteCancel => 'Cancel';

  @override
  String get promoteSelectEvent => 'Select an event to feature';

  @override
  String get promoteNoEvents => 'You have no upcoming events to feature';

  @override
  String get promoteEventAlreadyFeatured => 'Already featured';

  @override
  String get promoteSuccess => 'Promotion active!';

  @override
  String get promoteError => 'Something went wrong. Please try again.';

  @override
  String get promoteInsufficientCoins => 'Not enough coins';

  @override
  String get promoteInsufficientCoinsBody =>
      'You don\'t have enough coins for this promotion. Top up to continue.';

  @override
  String get promoteGetCoins => 'Get coins';

  @override
  String promoteDurationDays(int days) {
    return '$days days';
  }

  @override
  String promoteCostLabel(int cost) {
    return '$cost coins';
  }

  @override
  String promoteActiveUntil(String date) {
    return 'Promoted until $date';
  }

  @override
  String promoteBusinessConfirm(int days, int cost) {
    return 'Promote your business for $days days for $cost coins?';
  }

  @override
  String promoteEventConfirm(int days, int cost) {
    return 'Feature this event for $days days for $cost coins?';
  }

  @override
  String get audienceSectionTitle => 'Audience insights';

  @override
  String get audiencePrivacyNote =>
      'Aggregated and anonymized — small groups are hidden to protect privacy.';

  @override
  String get audienceNotEnoughData =>
      'Not enough data yet to show this while protecting privacy.';

  @override
  String get audienceAgeTitle => 'Age distribution';

  @override
  String get audienceCountriesTitle => 'Top countries';

  @override
  String get audienceInterestsTitle => 'Top interests';

  @override
  String get eventAnalyticsTitle => 'Event analytics';

  @override
  String get eventAnalyticsGoing => 'Going';

  @override
  String get eventAnalyticsWaitlist => 'Waitlist';

  @override
  String get eventAnalyticsCheckedIn => 'Checked in';

  @override
  String get eventAnalyticsCheckInRate => 'Check-in rate';

  @override
  String get eventAnalyticsTierBreakdown => 'Ticket tiers';

  @override
  String get businessEventsTitle => 'Manage my events';

  @override
  String get businessEventsSearchHint => 'Search by name or date';

  @override
  String get businessEventsEmpty => 'You haven\'t created any events yet.';

  @override
  String get businessEventsAnalytics => 'Analytics';

  @override
  String get businessEventsCancelTitle => 'Cancel event';

  @override
  String get businessEventsCancelMessage =>
      'Cancel this event? Attendees will be notified and it will be removed.';

  @override
  String get businessEventsCancelSeriesMessage =>
      'Cancel every occurrence in this recurring series?';

  @override
  String get businessEventsCancelConfirm => 'Cancel event';

  @override
  String get businessEventsCancelled => 'Event cancelled';

  @override
  String get businessPausedTitle => 'Business paused';

  @override
  String get businessPausedSubtitle =>
      'Your business features are paused because your Platinum membership expired. Renew Platinum to restore your storefront, analytics, leads and promotions.';

  @override
  String get businessReactivate => 'Renew Platinum';

  @override
  String get eventsBoostChooseDuration => 'Choose boost duration';

  @override
  String eventsBoostHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String eventBoostEndsIn(String time) {
    return 'Boost ends in $time';
  }

  @override
  String get eventBoostEnded => 'Boost ended';

  @override
  String get eventsBuyCoins => 'Buy coins';

  @override
  String get eventsBuyCoinsPrompt =>
      'You don\'t have enough coins. Would you like to buy more?';

  @override
  String get messageTooLong => 'Messages can be up to 4096 characters.';

  @override
  String get exploreBusinessesNearYou => 'Businesses close to you';

  @override
  String get storefrontEnabled => 'Storefront is on';

  @override
  String get storefrontDisabled => 'Storefront is off';

  @override
  String get storefrontToggleHint => 'Turn your storefront on or off anytime';

  @override
  String get splashBusinessLabel => 'BUSINESS';

  @override
  String get rateThisBusiness => 'Rate this business';

  @override
  String get businessRatingError =>
      'Couldn\'t save your rating. Please try again.';

  @override
  String businessRatingCount(int count) {
    return '($count)';
  }

  @override
  String rateStarsSemantic(int stars) {
    return 'Rate $stars stars';
  }

  @override
  String businessRatingSemantic(String avg, int count) {
    return 'Rated $avg out of 5, $count ratings';
  }

  @override
  String get editStorefront => 'Edit storefront';

  @override
  String get editStorefrontSubtitle =>
      'Manage your gallery, hours, links and info';

  @override
  String get storefrontGallerySubtitle =>
      'Showcase your venue, products or team';

  @override
  String get storefrontOpeningHoursSubtitle =>
      'Set your opening days and hours';

  @override
  String get storefrontDescriptionHint => 'Tell people about your business';

  @override
  String get storefrontCategoryHint => 'e.g. Restaurant, Cafe, Museum';

  @override
  String get storefrontLinkHint => 'https://...';

  @override
  String get storefrontAddLink => 'Add link';

  @override
  String get storefrontAddImage => 'Add image';

  @override
  String get storefrontSaved => 'Storefront updated';

  @override
  String get analyticsEventViews => 'Event views';

  @override
  String get analyticsCommunityReach => 'Community reach';

  @override
  String get analyticsChatsInvolved => 'Chats involved';

  @override
  String get eventAnalyticsViews => 'Views';

  @override
  String get businessHubScanner => 'Quick scanner';

  @override
  String get businessHubScannerSubtitle => 'Scan tickets to check attendees in';

  @override
  String get businessHubFollowers => 'Followers';

  @override
  String get businessHubFollowersSubtitle => 'See who follows your business';

  @override
  String get businessFollowersTitle => 'Followers';

  @override
  String get businessNoFollowers =>
      'No followers yet. Share your storefront to grow your audience.';

  @override
  String get membershipRequiredTitle => 'Membership required';

  @override
  String get membershipRequiredBody =>
      'You need an active membership to do this. Renew to continue.';

  @override
  String get renewMembership => 'Renew membership';

  @override
  String get extraEventTitle => 'Extra event';

  @override
  String extraEventBody(int cost) {
    return 'You\'ve reached your free event limit. Create an extra event for $cost coins?';
  }

  @override
  String get accountBannedTitle => 'Account permanently banned';

  @override
  String get accountBannedBody =>
      'This account has been permanently banned for violating our content policy. This decision is final.';

  @override
  String get adminBanPermanently => 'Ban permanently';

  @override
  String get adminBanConfirm => 'Ban this account permanently?';

  @override
  String get adminBanConfirmBody =>
      'This permanently bans the account and blocks all access. This cannot be undone.';

  @override
  String get adminBanReasonHint => 'Reason (e.g. nudity in gallery)';

  @override
  String get adminBanned => 'Account permanently banned';

  @override
  String get storefrontFeaturedImage => 'Featured image';

  @override
  String get storefrontFeaturedImageSubtitle =>
      'The hero banner shown at the top of your storefront.';

  @override
  String get storefrontAddFeaturedImage => 'Add featured image';

  @override
  String get storefrontProfileImage => 'Profile image';

  @override
  String get storefrontProfileImageSubtitle =>
      'Your avatar, shown next to your business name.';

  @override
  String get storefrontAddProfileImage => 'Add profile image';

  @override
  String get storefrontReplaceProfileImage => 'Replace profile image';

  @override
  String get preferenceBusinessOnly => 'Business accounts only';

  @override
  String get preferenceBusinessOnlyDesc =>
      'Show only business accounts in discovery';

  @override
  String get businessProfileNameLabel => 'Business profile name';

  @override
  String get businessProfileNameHint => 'Shown on your storefront';

  @override
  String get businessLegalNameLabel => 'Legal business name';

  @override
  String get businessLegalNameHint => 'Registered company name';

  @override
  String get verifyOwnerNameLabel => 'Owner\'s full name';

  @override
  String get verifyOwnerNameHint => 'Exactly as on the uploaded ID document';

  @override
  String get scanResultApproved => 'Approved';

  @override
  String get scanResultDenied => 'Denied';

  @override
  String get communitiesTabChat => 'Chat';

  @override
  String get communitiesTabTips => 'Tips';

  @override
  String get communitiesTabAnnouncements => 'Announcements';

  @override
  String get communitiesTabEvents => 'Events';

  @override
  String get communitiesJoinRequestSent => 'Request sent — awaiting approval';

  @override
  String get communitiesJoinRequestsTitle => 'Join requests';

  @override
  String get communitiesTipsEmpty =>
      'No tips yet. Share a language tip, cultural fact, or city tip from the chat.';

  @override
  String get communitiesAnnouncementsEmpty => 'No announcements yet.';

  @override
  String get communitiesPostAnnouncement => 'Post announcement';

  @override
  String get communitiesRequestToJoin => 'Request to join';

  @override
  String get communitiesMutedNotice => 'You\'ve been muted in this community';

  @override
  String get communitiesRulesResourcesTitle => 'Rules & resources';

  @override
  String get communitiesRulesLabel => 'Community rules';

  @override
  String get communitiesRulesHint => 'Guidelines for members…';

  @override
  String get communitiesResourcesLabel => 'Resource links';

  @override
  String get communitiesResourceTitleHint => 'Title';

  @override
  String get communitiesResourceUrlHint => 'https://…';

  @override
  String get communitiesAddResource => 'Add link';

  @override
  String get communitiesSaveLabel => 'Save';

  @override
  String get communitiesAddRulesPrompt =>
      'Add rules & resources for this community';

  @override
  String get communitiesAnnouncementHint =>
      'Write an announcement to all members…';

  @override
  String get communitiesPostLabel => 'Post';

  @override
  String get communitiesPromoteMember => 'Promote to admin';

  @override
  String get communitiesGrantTips => 'Allow to post Tips';

  @override
  String get communitiesRevokeTips => 'Revoke Tips posting';

  @override
  String get communitiesGrantAnnouncements => 'Allow to post Announcements';

  @override
  String get communitiesRevokeAnnouncements => 'Revoke Announcements posting';

  @override
  String get communitiesDemoteMember => 'Demote to member';

  @override
  String get communitiesRemoveMember => 'Remove from community';

  @override
  String get communitiesMuteMember => 'Mute';

  @override
  String get communitiesUnmuteMember => 'Unmute';

  @override
  String get communitiesBanMember => 'Ban';

  @override
  String get communitiesReportMember => 'Report';

  @override
  String get communitiesNoJoinRequests => 'No pending requests';

  @override
  String get communitiesApprove => 'Approve';

  @override
  String get communitiesReject => 'Reject';

  @override
  String get communitiesLinkToCommunity => 'Link to community (optional)';

  @override
  String get communitiesLinkNone => 'None';

  @override
  String get communitiesCreateEvent => 'Create event';

  @override
  String get communitiesEventsEmpty => 'No events yet';

  @override
  String get communitiesTranslate => 'Translate';

  @override
  String get communitiesShowOriginal => 'Show original';

  @override
  String get communitiesTranslating => 'Translating…';

  @override
  String get eventsFilterSoon => 'Soon';

  @override
  String get businessBadgeLabel => 'Business';

  @override
  String get businessWhatsappLabel => 'WhatsApp number';

  @override
  String get businessWhatsappSubtitle =>
      'Visitors tap to chat with you on WhatsApp';

  @override
  String get businessWhatsappHint => 'e.g. +351912345678';

  @override
  String get businessWhatsappButton => 'WhatsApp';

  @override
  String get locationLanguagesLabel => 'Location & Languages';

  @override
  String get storefrontLocationLanguagesSubtitle =>
      'Where you are and the languages you speak';

  @override
  String get storefrontLocationNotSet => 'Not set';

  @override
  String get universalSearchTabBusiness => 'Business';

  @override
  String get universalSearchTabCommunity => 'Communities';

  @override
  String get universalSearchNoBusiness => 'No businesses found';

  @override
  String get universalSearchNoCommunities => 'No communities found';

  @override
  String get communitiesSearchTips => 'Search tips';

  @override
  String get communitiesAddTip => 'Add tip';

  @override
  String get communitiesTipHint => 'Share a helpful tip…';

  @override
  String get shopEventsCreate => 'Events you can create';

  @override
  String get shopGroupsCreate => 'Groups & communities you can create';

  @override
  String get shopDailyConnects => 'Daily new connections';

  @override
  String get shopMonthlyBoosts => 'Monthly profile boosts';

  @override
  String get shopMonthlyCoins => 'Monthly coins';

  @override
  String get shopNoAds => 'Ad-free experience';

  @override
  String get shopSeeWhoConnected => 'See who connected with you';

  @override
  String get shopTravelMode => 'Travel mode';

  @override
  String get shopBusinessAccount => 'Business account';

  @override
  String get tourCommunitiesTabsTitle => 'Three ways to browse';

  @override
  String get tourCommunitiesTabsDesc =>
      'Switch between the groups you joined, discover new ones, and manage the communities you created.';

  @override
  String get tourCommunitiesSearchTitle => 'Find your groups';

  @override
  String get tourCommunitiesSearchDesc =>
      'Type here to filter your communities by name — handy once you\'ve joined a few.';

  @override
  String get tourCommunitiesCardTitle => 'Open & favorite';

  @override
  String get tourCommunitiesCardDesc =>
      'Tap a community to open its chat, tips, announcements and events. Tap the ⭐ star to save it — favorites pin to the top.';

  @override
  String get tourCommunitiesCreateTitle => 'Start a community';

  @override
  String get tourCommunitiesCreateDesc =>
      'Tap here to create your own community and bring people together.';

  @override
  String get tourReplayGuide => 'Replay guide';

  @override
  String get tourExploreSearchTitle => 'Search everything';

  @override
  String get tourExploreSearchDesc =>
      'Find people, businesses, events and communities — all from one search.';

  @override
  String get tourExploreQrTitle => 'Your QR code';

  @override
  String get tourExploreQrDesc =>
      'Scan or share a QR code to connect instantly in person.';

  @override
  String get tourEventsCreateTitle => 'Create an event';

  @override
  String get tourEventsCreateDesc =>
      'Tap the plus to host your own event or meetup.';

  @override
  String get tourEventsSearchTitle => 'Search events';

  @override
  String get tourEventsSearchDesc =>
      'Find events by city, country or name, and sort them your way.';

  @override
  String get tourEventsTabsTitle => 'Explore every tab';

  @override
  String get tourEventsTabsDesc =>
      'Browse community events, live events, attractions and experiences around you.';

  @override
  String get tourProfileHubTitle => 'Your profile hub';

  @override
  String get tourProfileHubDesc =>
      'Everything about your account lives here - edit it, manage settings and unlock premium features.';

  @override
  String get tourProfileViewTitle => 'Preview your profile';

  @override
  String get tourProfileViewDesc =>
      'See exactly how other people view your profile.';

  @override
  String get tourProfileEditTitle => 'Edit your details';

  @override
  String get tourProfileEditDesc =>
      'Tap to update your photos, bio, interests, location and more.';

  @override
  String get tourNotifHubTitle => 'Your notifications';

  @override
  String get tourNotifHubDesc =>
      'Every like, match, message and event update lands here.';

  @override
  String get tourNotifOpenTitle => 'Open and manage';

  @override
  String get tourNotifOpenDesc =>
      'Tap a notification to open it, or swipe left to delete it.';

  @override
  String get tourNotifMarkAllTitle => 'Clear the unread';

  @override
  String get tourNotifMarkAllDesc => 'Mark everything as read in a single tap.';

  @override
  String get communitiesJoinAsPersonalTitle =>
      'Join with your personal profile';

  @override
  String get communitiesJoinAsPersonalBody =>
      'You\'ll join this community as your personal profile. Your business storefront won\'t be shown here. Continue?';

  @override
  String get communitiesJoinAsPersonalConfirm => 'Join';

  @override
  String get communitiesCreatedManageHint =>
      'Community created! Open Members to add people and grant tip or announcement rights.';

  @override
  String get exploreHappeningSoon => 'Happening soon';

  @override
  String get attrScoreLabel => 'GreenGo Score';

  @override
  String get attrTierIconic => 'Iconic';

  @override
  String get attrTierExceptional => 'Exceptional';

  @override
  String get attrTierExcellent => 'Excellent';

  @override
  String get attrTierGreat => 'Great';

  @override
  String get attrTierWorthVisit => 'Worth a visit';

  @override
  String get attrImpWorldIcon => 'World icon';

  @override
  String get attrImpInternational => 'International landmark';

  @override
  String get attrImpNational => 'National landmark';

  @override
  String get attrImpRegional => 'Regional attraction';

  @override
  String get attrImpLocal => 'Local attraction';

  @override
  String get attrChipHome => 'Home';

  @override
  String get attrChipHere => 'You\'re here';

  @override
  String get attrFree => 'Free';

  @override
  String get attrUnesco => 'UNESCO';

  @override
  String get attrMustVisit => 'Must visit';

  @override
  String get attrTop10 => 'Top 10';

  @override
  String get attrPhotoSpot => 'Great for photos';

  @override
  String get attrAllCategories => 'All';

  @override
  String get attrFilterCategory => 'Category';

  @override
  String get attrFilterCountry => 'Country';

  @override
  String get attrFilterCity => 'City';

  @override
  String get attrAllCities => 'All cities';

  @override
  String get attrSortDistance => 'Nearest first';

  @override
  String get attrSortScore => 'GreenGo Score';

  @override
  String get attrSortRating => 'Rating';

  @override
  String get attrSortPrice => 'Price';

  @override
  String get attrSortName => 'Name';

  @override
  String get attrNoResults => 'No attractions match your filters';

  @override
  String get attrNoCoverage =>
      'We do not cover attractions in your country yet — more coming soon';

  @override
  String get attrLoadFailed => 'Could not load attractions';

  @override
  String attrKmAway(String km) {
    return '$km km away';
  }

  @override
  String get attrAbout => 'About';

  @override
  String get attrHighlights => 'Highlights';

  @override
  String get attrWhyVisit => 'Why visit';

  @override
  String get attrScoreHistorical => 'Historical';

  @override
  String get attrScoreArchitectural => 'Architectural';

  @override
  String get attrScoreNatural => 'Nature';

  @override
  String get attrScorePhotography => 'Photography';

  @override
  String get attrBestTimeTitle => 'Best time to visit';

  @override
  String get attrHistoryTitle => 'History';

  @override
  String get attrDidYouKnow => 'Did you know';

  @override
  String get attrPhotoTips => 'Photo tips';

  @override
  String get attrPractical => 'Practical';

  @override
  String get attrOpeningHours => 'Opening hours';

  @override
  String get attrVisitDuration => 'Typical visit';

  @override
  String get attrAccessibility => 'Accessibility';

  @override
  String get attrPets => 'Pets';

  @override
  String get attrSafety => 'Safety';

  @override
  String get attrVisitorsPerYear => 'Visitors per year';

  @override
  String get attrTicketFrom => 'Ticket';

  @override
  String get attrOpenInMaps => 'Open in Maps';

  @override
  String attrPhotoBy(String author, String license) {
    return 'Photo: $author · $license';
  }

  @override
  String get attrIndoor => 'Indoor';

  @override
  String get attrOutdoor => 'Outdoor';

  @override
  String attrCountAttractions(int count) {
    return '$count attractions';
  }

  @override
  String get attrEnableLocation =>
      'Turn on location to see what is closest to you right now';

  @override
  String get attrRetry => 'Retry';

  @override
  String get attrTranslate => 'Translate';

  @override
  String get attrShowOriginal => 'Show original';

  @override
  String get attrCatReligious => 'Religious site';

  @override
  String get attrCatHistoricSite => 'Historic site';

  @override
  String get attrCatMuseum => 'Museum';

  @override
  String get attrCatNature => 'Nature';

  @override
  String get attrCatNeighborhood => 'Neighbourhood';

  @override
  String get attrCatBeach => 'Beach';

  @override
  String get attrCatGarden => 'Garden';

  @override
  String get attrCatMonument => 'Monument';

  @override
  String get attrCatSquare => 'Square';

  @override
  String get attrCatStreet => 'Street';

  @override
  String get attrCatArchitecture => 'Architecture';

  @override
  String get attrCatObservationDeck => 'Viewpoint';

  @override
  String get attrCatCastle => 'Castle';

  @override
  String get attrCatMarket => 'Market';

  @override
  String get attrCatMountain => 'Mountain';

  @override
  String get attrCatPalace => 'Palace';

  @override
  String get attrCatIsland => 'Island';

  @override
  String get attrCatLake => 'Lake';

  @override
  String get attrCatNationalPark => 'National park';

  @override
  String get attrCatOther => 'Other';

  @override
  String get attrCatBridge => 'Bridge';

  @override
  String get attrCatThemePark => 'Theme park';

  @override
  String get attrCatWaterfall => 'Waterfall';

  @override
  String get attrCatZoo => 'Zoo';

  @override
  String get attrCatShopping => 'Shopping';

  @override
  String get attrCatAquarium => 'Aquarium';

  @override
  String attrSearchResults(int count, String query) {
    return '$count results for \"$query\"';
  }

  @override
  String get attendeesSeeAll => 'See all';

  @override
  String attendeesCount(int count) {
    return '$count going';
  }

  @override
  String attendeesCountWithGuests(int count, int guests) {
    return '$count going · $guests guests';
  }

  @override
  String attendeesBringing(int count) {
    return 'Bringing $count guests';
  }

  @override
  String get attendeesOrganizer => 'Organizer';

  @override
  String get attendeesLoadFailed => 'Could not load attendees';

  @override
  String get attendeesProfileFailed => 'Could not open this profile';

  @override
  String get quizTitle => 'Personality quiz';

  @override
  String get quizSubtitle => 'Help us understand your personality';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get quizQuestionOpenness =>
      'I enjoy trying new and exciting activities';

  @override
  String get quizQuestionConscientiousness =>
      'I prefer to have a structured and organized routine';

  @override
  String get quizQuestionExtraversion =>
      'I feel energized when socializing with others';

  @override
  String get quizQuestionAgreeableness =>
      'I try to be cooperative and avoid conflicts';

  @override
  String get quizQuestionNeuroticism =>
      'I often feel anxious or worried about things';

  @override
  String get quizAnswerStronglyDisagree => 'Strongly Disagree';

  @override
  String get quizAnswerDisagree => 'Disagree';

  @override
  String get quizAnswerNeutral => 'Neutral';

  @override
  String get quizAnswerAgree => 'Agree';

  @override
  String get quizAnswerStronglyAgree => 'Strongly Agree';

  @override
  String get quizBigFiveNote =>
      'Based on the Big Five personality traits model';

  @override
  String get profilePreviewTitle => 'Profile preview';

  @override
  String get profilePreviewSubtitle => 'Review your profile before completing';

  @override
  String get profilePreviewCompleteButton => 'Complete Profile';

  @override
  String get profileFieldName => 'Name';

  @override
  String get profileFieldAge => 'Age';

  @override
  String profileAgeYearsOld(int age) {
    return '$age years old';
  }

  @override
  String get profileFieldStatus => 'Status';

  @override
  String get profileNoBio => 'No bio provided';

  @override
  String get profileCompleteBadgeTitle => 'Profile Complete!';

  @override
  String get profileCompleteBadgeSubtitle =>
      'Your profile is ready to be published';

  @override
  String get personalityTraitsTitle => 'Personality Traits';

  @override
  String get traitOpenness => 'Openness';

  @override
  String get traitConscientiousness => 'Conscientiousness';

  @override
  String get traitExtraversion => 'Extraversion';

  @override
  String get traitAgreeableness => 'Agreeableness';

  @override
  String get traitNeuroticism => 'Neuroticism';

  @override
  String get socialLinksSubtitle => 'Connect your social accounts (optional)';

  @override
  String get socialHintUsernameNoAt => 'Username (without @)';

  @override
  String get socialLinksVisibilityNote =>
      'Your social profiles will be visible on your public profile';

  @override
  String get travelPrefTitle => 'How do you want to use GreenGo?';

  @override
  String get travelPrefSubtitle =>
      'Tell us about your interests so we can personalize your experience.';

  @override
  String get travelPrefLearnTravelTitle => 'Learn & Travel';

  @override
  String get travelPrefLearnTravelDesc =>
      'Learn languages and meet people when I travel to new places';

  @override
  String get travelPrefLocalGuideTitle => 'Local Guide';

  @override
  String get travelPrefLocalGuideDesc =>
      'Help travelers discover my city and share my culture with them';

  @override
  String get travelPrefBothTitle => 'Both';

  @override
  String get travelPrefBothDesc =>
      'I want to learn languages, travel the world, and help visitors in my city';

  @override
  String get travelPrefChangeLater =>
      'You can change this anytime in your profile settings.';

  @override
  String get locationErrorPermissionDenied =>
      'Location permission was denied. Please grant permission in settings.';

  @override
  String get locationErrorServicesDisabled =>
      'Location services are disabled. Please enable them in settings.';

  @override
  String get locationErrorUnableToGet =>
      'Unable to get your location. Please check your device settings or try again later.';

  @override
  String get locationErrorCheckInternet =>
      'Please check your internet connection and try again.';

  @override
  String get locationErrorPermissionRequired =>
      'Location permission is required. Please grant permission in settings.';

  @override
  String get locationErrorTookTooLong =>
      'Getting your location took too long. Please try again.';

  @override
  String get phoneErrorInvalidNumber =>
      'Invalid phone number format. Please use international format (e.g. +1234567890).';

  @override
  String get phoneErrorTooManyRequests =>
      'Too many attempts. Please wait a few minutes before trying again.';

  @override
  String get phoneErrorQuotaExceeded =>
      'SMS quota exceeded. Please try again later.';

  @override
  String get phoneErrorCaptchaFailed =>
      'reCAPTCHA verification failed. Please try again.';

  @override
  String get phoneErrorMissingNumber => 'Please enter a phone number.';

  @override
  String phoneErrorGeneric(String code) {
    return 'Phone verification error ($code). Please try again.';
  }

  @override
  String get phoneErrorUnexpected =>
      'Phone verification error. Please try again.';

  @override
  String get phoneErrorAlreadyLinked =>
      'This phone number is already linked to another account.';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameSpanish => 'Spanish';

  @override
  String get languageNameFrench => 'French';

  @override
  String get languageNameGerman => 'German';

  @override
  String get languageNameItalian => 'Italian';

  @override
  String get languageNamePortuguese => 'Portuguese';

  @override
  String get languageNamePortugueseBrazil => 'Portuguese (Brazil)';

  @override
  String get languageNameRussian => 'Russian';

  @override
  String get languageNameChinese => 'Chinese';

  @override
  String get languageNameJapanese => 'Japanese';

  @override
  String get languageNameKorean => 'Korean';

  @override
  String get languageNameArabic => 'Arabic';

  @override
  String get languageNameHindi => 'Hindi';

  @override
  String get languageNameDutch => 'Dutch';

  @override
  String get languageNameSwedish => 'Swedish';

  @override
  String get languageNameNorwegian => 'Norwegian';

  @override
  String get languageNameDanish => 'Danish';

  @override
  String get languageNameFinnish => 'Finnish';

  @override
  String get languageNamePolish => 'Polish';

  @override
  String get languageNameTurkish => 'Turkish';

  @override
  String get languageNameGreek => 'Greek';

  @override
  String get resetPasswordTitle => 'Reset Your Password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email address and we\'ll send you instructions to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetLinkExpiryNote =>
      'The reset link will expire in 1 hour for security reasons.';

  @override
  String get resetEmailSentTitle => 'Email Sent!';

  @override
  String resetEmailSentBody(String email) {
    return 'A password reset link has been sent to $email.\n\nPlease check your inbox and spam folder.';
  }

  @override
  String get resetErrorInvalidEmail => 'Invalid email address.';

  @override
  String get resetErrorUnavailable =>
      'Service temporarily unavailable. Please try again later.';

  @override
  String get resetErrorFailed =>
      'Failed to send reset email. Please try again.';

  @override
  String get onboardingSubmitCreatingProfile => 'Creating your profile…';

  @override
  String get onboardingSubmitGrantingCoins => 'Setting up your coins…';

  @override
  String get onboardingSubmitFinishingUp => 'Almost there…';

  @override
  String get onboardingSubmitPleaseWait => 'This only takes a moment';

  @override
  String get chatSettingSilverPlusOnly => 'Available on Silver and above';

  @override
  String get chatSettingXpBarHint => 'Appears once you earn XP in this chat';

  @override
  String get chatSettingLanguageFlagsHint =>
      'Shown on messages that have a translation';

  @override
  String get chatSmartRepliesLoading => 'Thinking of replies...';

  @override
  String get errorScreenTitle => 'Something went wrong';

  @override
  String get errorScreenBody =>
      'This screen could not be opened. Reload the app to try again — your account is not affected.';

  @override
  String get errorScreenReload => 'Reload';

  @override
  String get ageVerifyTitle => 'Verify your age';

  @override
  String get ageVerifyWhyPublish =>
      'To post in a community, we need to confirm you are over 18.';

  @override
  String get ageVerifyWhyPhone =>
      'You signed up with a phone number, so we need a document to confirm your age.';

  @override
  String get ageVerifyPrivacyNote =>
      'We read the date of birth automatically. The photo is deleted as soon as a decision is made (after at most 7 days if a person needs to review it) and is never shown on your profile.';

  @override
  String get ageVerifyTakePhoto => 'Take a photo of your ID';

  @override
  String get ageVerifyChooseImage => 'Choose from library';

  @override
  String get ageVerifyChecking => 'Checking your document…';

  @override
  String get ageVerifyPending =>
      'We are reviewing your document. This usually takes less than a day.';

  @override
  String get ageVerifyVerified => 'Your age is verified.';

  @override
  String get ageVerifyRejected =>
      'We could not read your document. Please try again with a clearer photo.';

  @override
  String get ageVerifyRejectedUnderage =>
      'The document shows you are under 18.';

  @override
  String get ageVerifyRejectedReused =>
      'This document is already linked to another account.';

  @override
  String get ageVerifyCta => 'Verify now';

  @override
  String get ageVerifyLater => 'Not now';

  @override
  String get ageVerifyNeededToPost => 'Verify your age to post';

  @override
  String get contactSupportSubtitle =>
      'Questions, problems or a report — we reply by email';

  @override
  String get offerPreRegisteredTitle => 'You are pre-registered';

  @override
  String get offerWelcomePackTitle => 'Your welcome pack';

  @override
  String offerTierLine(String tier, String duration) {
    return '$tier membership for $duration';
  }

  @override
  String offerBaseLine(String duration) {
    return 'Base membership for $duration';
  }

  @override
  String get offerFreeMonthLine => 'One month of free full access';

  @override
  String offerCoinsLine(int coins) {
    return '$coins welcome coins';
  }

  @override
  String get offerAppliedFromToday =>
      'Added automatically from today, the first time you sign in.';

  @override
  String get offerDurationOneMonth => '1 month';

  @override
  String offerDurationMonths(int count) {
    return '$count months';
  }

  @override
  String get offerDurationOneYear => '1 year';

  @override
  String offerDurationDays(int count) {
    return '$count days';
  }

  @override
  String get featureIncludedTitle => 'WHAT\'S INCLUDED';

  @override
  String get featureUnlimited => 'Unlimited';

  @override
  String featureDailyConnects(String count) {
    return '$count new connections every day';
  }

  @override
  String featureMonthlyCoins(int coins) {
    return '$coins coins every month';
  }

  @override
  String featureEvents(String count) {
    return '$count events running at once';
  }

  @override
  String featureBoosts(int count) {
    return '$count profile boosts a month';
  }

  @override
  String featureDiscoveryReveals(int count) {
    return '$count profiles revealed at a time';
  }

  @override
  String get featureTravelMode => 'Travel mode - discover people anywhere';

  @override
  String get featureWhoConnected => 'See who connected with you';

  @override
  String get boostProfileCelebrationTitle => 'Profile boosted!';

  @override
  String get boostEventCelebrationTitle => 'Event boosted!';

  @override
  String get eventsEnded => 'Event ended';

  @override
  String get eventsAttendeeListVisibility => 'Who can see who\'s coming';

  @override
  String get eventsAttendeeListPrivate => 'Nobody';

  @override
  String get eventsAttendeeListParticipants => 'Participants';

  @override
  String get eventsAttendeeListPublic => 'Everyone';

  @override
  String get eventsAttendeeListPrivateHint =>
      'Only you can see the guest list.';

  @override
  String get eventsAttendeeListParticipantsHint =>
      'People attending can see each other.';

  @override
  String get eventsAttendeeListPublicHint =>
      'Anyone who can see the event can see the guest list.';

  @override
  String get eventsAttendeeListHidden =>
      'The organizer has hidden the guest list.';

  @override
  String get eventsOrganizedBy => 'Organized by';

  @override
  String eventsOrganizerYou(String name) {
    return '$name (you)';
  }

  @override
  String eventsByOrganizer(String name) {
    return 'by $name';
  }

  @override
  String shareEventMessageTitled(String title, String link) {
    return '$title\nCheck out this event on GreenGo: $link';
  }

  @override
  String shareCommunityMessage(String name, String link) {
    return '$name\nJoin this community on GreenGo: $link';
  }

  @override
  String shopMembershipExpiredOn(String tier, String date) {
    return 'Your $tier membership expired on $date';
  }

  @override
  String get eventsLocationHelper =>
      'Type a venue or address, or pick it on the map';

  @override
  String get eventsPickOnMap => 'Pick on map';

  @override
  String get eventsLocationNotOnMap =>
      'Saved with the location you typed. We couldn\'t place it on the map, so it won\'t show in nearby searches.';

  @override
  String get eventsCoOwners => 'Co-owners';

  @override
  String get eventsCoOwnersHelper =>
      'Co-owners can edit the event, open the attendance list, check guests in and see the full guest list. Only you can delete the event or change co-owners.';

  @override
  String get eventsCoOwnersCreatorOnly =>
      'Only the event creator can change co-owners.';

  @override
  String get eventsAddCoOwner => 'Add co-owner';

  @override
  String eventsCoOwnerLimit(int max) {
    return 'You can add up to $max co-owners';
  }

  @override
  String get eventsCoOwnerSearchHint => 'Search by nickname';

  @override
  String get eventsCoOwnerSearch => 'Search';

  @override
  String get eventsCoOwnerRecentChats => 'Recent chats';

  @override
  String get eventsCoOwnerNoRecentChats => 'No recent chats yet';

  @override
  String get eventsCoOwnerNotFound => 'No one found with that nickname';

  @override
  String get eventsCoOwnerSearchFailed => 'Search failed. Please try again.';

  @override
  String get eventsCoOwnerRemove => 'Remove co-owner';

  @override
  String eventsOrganizedWith(String names) {
    return 'with $names';
  }

  @override
  String get eventsCoOwnerBadge => 'Co-owner';

  @override
  String get qrHubCancelRsvpConfirm =>
      'Delete this ticket? This cancels your RSVP and frees your spot for someone else.';

  @override
  String get qrHubHideTicketConfirm =>
      'Remove this ticket from your list? Your attendance record is kept.';

  @override
  String get qrHubTicketRemoved => 'Ticket removed';

  @override
  String get usageDailyUsageTitle => 'Daily Usage';

  @override
  String get usageConnectsThisHour => 'Connects This Hour';

  @override
  String get usagePassesThisHour => 'Passes This Hour';

  @override
  String get usagePriorityConnectsThisHour => 'Priority Connects This Hour';

  @override
  String get usageMessagesToday => 'Messages Today';

  @override
  String get usageMediaSentToday => 'Media Sent Today';

  @override
  String get usageUpgradeBenefitsTitle => 'Upgrade Benefits';

  @override
  String get usageUpgradeButton => 'Upgrade Membership';

  @override
  String usagePlanName(String tier) {
    return '$tier Plan';
  }

  @override
  String get usageCurrentTierLabel => 'Current membership tier';

  @override
  String get usageNoBaseMembership => 'No GreenGo Base Membership';

  @override
  String usageExpiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String usageExpiredOn(String date) {
    return 'Expired: $date';
  }

  @override
  String get usageStatusActive => 'Active';

  @override
  String get usageStatusExpired => 'Expired';

  @override
  String get usageCoinsAvailable => 'Coins Available';

  @override
  String get usageNotAvailable => 'Not Available';

  @override
  String usageWithTier(String tier) {
    return 'With $tier';
  }

  @override
  String get attrApplyFilter => 'Apply filter';

  @override
  String get userFollowFollow => 'Follow';

  @override
  String get userFollowFollowing => 'Following';

  @override
  String get userFollowFollowBack => 'Follow back';

  @override
  String get userFollowError => 'Couldn\'t update follow. Please try again.';

  @override
  String get userFollowBlocked => 'You can\'t follow this user.';

  @override
  String get userFollowUnfollowTooltip => 'Unfollow';

  @override
  String userFollowFollowersStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted followers',
      one: '$formatted follower',
    );
    return '$_temp0';
  }

  @override
  String userFollowFollowingStat(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted following',
    );
    return '$_temp0';
  }

  @override
  String get userFollowTabFollowers => 'Followers';

  @override
  String get userFollowTabFollowing => 'Following';

  @override
  String get userFollowEmptyFollowers => 'No followers yet';

  @override
  String get userFollowEmptyFollowing => 'Not following anyone yet';

  @override
  String get userFollowListError => 'Couldn\'t load this list.';

  @override
  String attractionViewsCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted views',
      one: '$formatted view',
    );
    return '$_temp0';
  }

  @override
  String get uexpCommunity => 'Community';

  @override
  String get uexpPartners => 'Partners';

  @override
  String get uexpCreate => 'Create experience';

  @override
  String get uexpMine => 'My experiences';

  @override
  String get uexpEmpty =>
      'No community experiences yet. Be the first to host one!';

  @override
  String get uexpMineEmpty => 'You haven\'t created any experiences yet.';

  @override
  String get uexpAll => 'All';

  @override
  String get uexpFree => 'Free';

  @override
  String get uexpCatFoodDrink => 'Food & drink';

  @override
  String get uexpCatCultureHistory => 'Culture & history';

  @override
  String get uexpCatNatureOutdoors => 'Nature & outdoors';

  @override
  String get uexpCatNightlife => 'Nightlife';

  @override
  String get uexpCatSportsAdventure => 'Sports & adventure';

  @override
  String get uexpCatWellness => 'Wellness';

  @override
  String get uexpCatLanguageLearning => 'Language learning';

  @override
  String get uexpCatToursWalks => 'Tours & walks';

  @override
  String get uexpCatWorkshopsClasses => 'Workshops & classes';

  @override
  String get uexpCatOther => 'Other';

  @override
  String uexpReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
      zero: 'No reviews',
    );
    return '$_temp0';
  }

  @override
  String get uexpStatusDraft => 'Draft';

  @override
  String get uexpStatusPublished => 'Published';

  @override
  String get uexpStatusHidden => 'Hidden';

  @override
  String get uexpHiddenNotice =>
      'This experience was hidden because it violates GreenGo standards. Edit the text to restore it.';

  @override
  String get uexpNewTitle => 'New experience';

  @override
  String get uexpEditTitle => 'Edit experience';

  @override
  String get uexpSectionPhotos => 'Photos';

  @override
  String get uexpSectionBasics => 'About the experience';

  @override
  String get uexpSectionPractical => 'Practical info';

  @override
  String get uexpMainPhoto => 'Main photo (required)';

  @override
  String uexpMorePhotos(int max) {
    return 'up to $max more photos';
  }

  @override
  String get uexpFieldTitle => 'Title';

  @override
  String get uexpFieldDescription => 'Description';

  @override
  String get uexpFieldCategory => 'Category';

  @override
  String get uexpIncluded => 'What\'s included';

  @override
  String get uexpNotIncluded => 'What\'s not included';

  @override
  String get uexpAddItem => 'Add item';

  @override
  String get uexpRemoveItem => 'Remove item';

  @override
  String get uexpItemHint => 'e.g. Local snacks';

  @override
  String get uexpFieldLocation => 'Location';

  @override
  String get uexpLocationHint => 'Type a place or pick it on the map';

  @override
  String get uexpPickOnMap => 'Pick on map';

  @override
  String get uexpMeetingPoint => 'Meeting point (optional)';

  @override
  String get uexpMeetingPointLabel => 'Meeting point';

  @override
  String get uexpLocationNotFound =>
      'We couldn\'t find this place on the map. It is saved as typed and won\'t appear in nearby results.';

  @override
  String get uexpDuration => 'Duration';

  @override
  String get uexpHours => 'Hours';

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
  String get uexpLanguages => 'Languages spoken';

  @override
  String get uexpGroupSize => 'Group size';

  @override
  String get uexpMinGroup => 'Min people (optional)';

  @override
  String get uexpMaxGroup => 'Max people';

  @override
  String uexpGroupSizeRange(int min, int max) {
    return '$min–$max people';
  }

  @override
  String uexpGroupUpTo(int max) {
    return 'Up to $max people';
  }

  @override
  String get uexpPrice => 'Price';

  @override
  String get uexpCurrency => 'Currency';

  @override
  String get uexpIsFree => 'This experience is free';

  @override
  String get uexpPaymentLink => 'How guests pay you';

  @override
  String get uexpPaymentType => 'Payment method';

  @override
  String get uexpPayPix => 'PIX';

  @override
  String get uexpPayPaypal => 'PayPal';

  @override
  String get uexpPayVenmo => 'Venmo';

  @override
  String get uexpPayStripe => 'Stripe payment link';

  @override
  String get uexpPayOther => 'Other payment link';

  @override
  String get uexpPaymentValuePix => 'PIX key';

  @override
  String get uexpPaymentValueUrl => 'Payment link';

  @override
  String get uexpPaymentValueHintPix => 'Email, phone, CPF or random key';

  @override
  String get uexpPaymentDisclaimer =>
      'Payments happen outside GreenGo, directly between guests and the host. GreenGo does not process, guarantee or refund them.';

  @override
  String get uexpAvailability => 'Availability (optional)';

  @override
  String get uexpAvailabilityLabel => 'Availability';

  @override
  String get uexpAvailabilityHint => 'e.g. Saturdays 10:00–13:00';

  @override
  String get uexpCancellation => 'Cancellation policy (optional)';

  @override
  String get uexpCancellationLabel => 'Cancellation policy';

  @override
  String get uexpSaveDraft => 'Save as draft';

  @override
  String get uexpPublish => 'Publish';

  @override
  String get uexpSaveChanges => 'Save changes';

  @override
  String get uexpUnpublish => 'Unpublish';

  @override
  String get uexpSaved => 'Experience saved';

  @override
  String get uexpPublished => 'Experience published';

  @override
  String get uexpUnpublished => 'Experience moved to drafts';

  @override
  String get uexpSaveFailed =>
      'Couldn\'t save the experience. Please try again.';

  @override
  String get uexpPhotoUploadFailed =>
      'Couldn\'t upload the photos. Please try again.';

  @override
  String uexpErrTitle(int min, int max) {
    return 'Title must be $min–$max characters';
  }

  @override
  String uexpErrDescription(int min, int max) {
    return 'Description must be $min–$max characters';
  }

  @override
  String get uexpErrMainPhoto => 'Add a main photo';

  @override
  String uexpErrTooManyPhotos(int max) {
    return 'Up to $max extra photos';
  }

  @override
  String get uexpErrIncluded => 'Add at least one included item';

  @override
  String uexpErrTooManyItems(int max) {
    return 'Up to $max items';
  }

  @override
  String uexpErrItemTooLong(int max) {
    return 'Each item can have up to $max characters';
  }

  @override
  String get uexpErrLocation => 'Enter a location';

  @override
  String get uexpErrDuration =>
      'Enter a duration between 15 minutes and 14 days';

  @override
  String get uexpErrLanguages => 'Pick at least one language';

  @override
  String uexpErrMaxGroup(int max) {
    return 'Max people must be between 1 and $max';
  }

  @override
  String get uexpErrMinGroup =>
      'Min people must be at least 1 and not more than max';

  @override
  String get uexpErrPrice => 'Enter a valid price';

  @override
  String get uexpErrPaymentRequired =>
      'Add how guests pay you (or mark the experience as free)';

  @override
  String get uexpErrPaymentInvalid =>
      'Enter a valid link starting with https://';

  @override
  String get uexpErrProhibited =>
      'Some text contains language that isn\'t allowed on GreenGo';

  @override
  String get uexpErrNoLinks => 'Links aren\'t allowed in reviews and replies';

  @override
  String uexpErrTooLong(int max) {
    return 'Up to $max characters';
  }

  @override
  String get uexpErrFixFields => 'Please fix the highlighted fields';

  @override
  String get uexpLimitFeature => 'Host experiences';

  @override
  String get uexpLimitFreeBody =>
      'Hosting experiences is available with a Silver, Gold or Platinum membership.';

  @override
  String uexpLimitReachedBody(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Your plan allows $limit experiences.',
      one: 'Your plan allows 1 experience.',
    );
    return '$_temp0 Upgrade to create more experiences.';
  }

  @override
  String get uexpUpgradeToCreateMore => 'Upgrade to create more experiences';

  @override
  String get shopExperiencesCreate => 'Experiences you can create';

  @override
  String get uexpHostedBy => 'Hosted by';

  @override
  String get uexpHostBadge => 'Host';

  @override
  String get uexpPayBook => 'Pay / Book';

  @override
  String get uexpPixCopied => 'PIX key copied to the clipboard';

  @override
  String get uexpOpenLinkFailed => 'Couldn\'t open the link';

  @override
  String get uexpShare => 'Share';

  @override
  String uexpShareText(String title, String link) {
    return '$title\nDiscover this experience on GreenGo: $link';
  }

  @override
  String get uexpReport => 'Report';

  @override
  String get uexpReportTitle => 'Report this experience?';

  @override
  String get uexpReportBody =>
      'Our team will review it against the GreenGo standards.';

  @override
  String get uexpReported => 'Thanks, we\'ll review it.';

  @override
  String get uexpReportReview => 'Report review';

  @override
  String get uexpEdit => 'Edit';

  @override
  String get uexpDelete => 'Delete';

  @override
  String get uexpDeleteConfirmTitle => 'Delete this experience?';

  @override
  String get uexpDeleteConfirmBody =>
      'Its reviews will be deleted too. This can\'t be undone.';

  @override
  String get uexpDeleted => 'Experience deleted';

  @override
  String get uexpNotFound => 'This experience is no longer available.';

  @override
  String get uexpReviews => 'Reviews';

  @override
  String get uexpNoReviews => 'No reviews yet';

  @override
  String get uexpWriteReview => 'Write a review';

  @override
  String get uexpEditReview => 'Edit your review';

  @override
  String get uexpYourRating => 'Your rating';

  @override
  String get uexpSelectRating => 'Select a rating from 1 to 5 stars';

  @override
  String get uexpCommentHint => 'Share what you liked (optional)';

  @override
  String get uexpSubmit => 'Submit';

  @override
  String get uexpDeleteReview => 'Delete review';

  @override
  String get uexpDeleteReviewConfirm => 'Delete your review?';

  @override
  String get uexpReviewSaved => 'Review saved';

  @override
  String get uexpReviewDeleted => 'Review deleted';

  @override
  String get uexpReviewRemoved =>
      'Your review was removed for violating GreenGo standards. Edit it to try again.';

  @override
  String get uexpReplyRemoved =>
      'Your reply was removed for violating GreenGo standards.';

  @override
  String get uexpPendingModeration => 'Being checked…';

  @override
  String get uexpHostCannotReview =>
      'Hosts can\'t review their own experience.';

  @override
  String get uexpReply => 'Reply';

  @override
  String get uexpReplyHint => 'Write a reply. Type @ to tag someone';

  @override
  String get uexpShowMoreReplies => 'Show more replies';

  @override
  String get uexpLoadMoreReviews => 'Load more reviews';

  @override
  String get uexpEdited => 'edited';

  @override
  String get feedFilterTooltip => 'Show';

  @override
  String get feedFilterAll => 'All';

  @override
  String get feedFilterCommunity => 'Community';

  @override
  String get feedFilterPartner => 'Partner';

  @override
  String get feedFilterMyEvents => 'My events';

  @override
  String get feedFilterMyExperiences => 'My experiences';

  @override
  String get partnerBadge => 'Partner';

  @override
  String get createChooserTitle => 'What would you like to create?';

  @override
  String get createChooserEventDesc =>
      'Host a meetup or activity that people nearby can join';

  @override
  String get createChooserExperienceDesc =>
      'Offer a tour, class or local experience as a host';

  @override
  String get uexpAddExperience => 'Add experience';

  @override
  String get uexpNewHost => 'New host';

  @override
  String uexpHostRatings(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ratings',
      one: '$countText rating',
    );
    return '$_temp0';
  }

  @override
  String get verifiedBadgeLabel => 'Verified';

  @override
  String get verifiedBadgeTooltip => 'ID verified by GreenGo';

  @override
  String get idDocumentRetentionNotice =>
      'For fraud prevention and the safety of the community, identity documents are kept for up to 30 days after account deletion and then permanently erased.';

  @override
  String get uexpErrContactInfo =>
      'Remove phone numbers, e-mails, @handles and payment details: guests pay only through the methods on your listing.';

  @override
  String get uexpErrPaymentMethods => 'Choose at least one payment method';

  @override
  String get uexpPaymentLinkDetails => 'Online payment link';

  @override
  String get uexpMethodCash => 'Cash at the meeting';

  @override
  String get uexpMethodLink => 'Online link (PIX/PayPal/…)';

  @override
  String get uexpBook => 'Book';

  @override
  String get uexpBookedCash => 'Noted. Pay the host in cash at the meeting.';

  @override
  String get uexpIdDocTitle => 'ID document needed';

  @override
  String get uexpIdDocGuestBody =>
      'To keep GreenGo safe, upload an ID document before paying a host.';

  @override
  String get uexpIdDocHostBody =>
      'Hosts must upload an ID document before creating an experience.';

  @override
  String get uexpIdDocUpload => 'Upload document';

  @override
  String get uexpPaidPendingTitle => 'ID review pending';

  @override
  String get uexpPaidPendingBody =>
      'Paid experiences need an approved ID document. Yours is still under review: save this one as a draft or publish it as free for now.';

  @override
  String get uexpPaidMissingBody =>
      'Paid experiences need an approved ID document. Upload one (or a new one if it was not approved), or save this one as a draft or publish it as free for now.';

  @override
  String get uexpNewHostLimitTitle => 'New host limit';

  @override
  String get uexpNewHostLimitBody =>
      'Until you have 3 reviews you can have one published paid experience. Save this one as a draft or publish it as free.';

  @override
  String get uexpPublishAsFree => 'Publish as free';

  @override
  String get uexpHostBanned => 'Your account can\'t host experiences.';

  @override
  String get hostAgreementTitle => 'Host agreement';

  @override
  String get hostAgreementIntro =>
      'Before you publish your first experience, please read and accept these rules.';

  @override
  String get hostAgreementClause1 =>
      'You organise and host this experience and are responsible for it and for the safety of your guests.';

  @override
  String get hostAgreementClause2 =>
      'Describe it accurately: title, photos, price, duration, what is included and the meeting point must be true and up to date.';

  @override
  String get hostAgreementClause3 =>
      'Follow the law: you hold any licence, permit, insurance or registration your activity requires where it takes place, and you declare your income as required.';

  @override
  String get hostAgreementClause4 =>
      'Refund guests according to the cancellation policy you chose, and always in full if you cancel.';

  @override
  String get hostAgreementClause5 =>
      'Never ask guests to pay outside the methods shown on your listing, and never put phone numbers, e-mails or payment handles in the listing text.';

  @override
  String get hostAgreementClause6 =>
      'Treat guests with respect: no discrimination, harassment or unsafe situations.';

  @override
  String get hostAgreementClause7 =>
      'GreenGo may hide or remove listings and suspend or ban accounts that break these rules or receive credible reports.';

  @override
  String get hostAgreementCheckbox =>
      'I have read and accept the host agreement';

  @override
  String get hostAgreementAccept => 'Accept and continue';

  @override
  String get uexpConsentTitle => 'Before you pay';

  @override
  String get uexpConsentBodyLink =>
      'You are paying the host directly. GreenGo does not process or guarantee this payment and cannot refund it. Prefer protected methods (PayPal Goods & Services, credit card). Never pay outside the link shown here.';

  @override
  String get uexpConsentBodyCash =>
      'You will pay the host in cash at the meeting. GreenGo does not process or guarantee this payment and cannot refund it. Count the money, ask for a receipt if needed, and never pay in advance outside the methods listed on this page.';

  @override
  String get uexpConsentPickMethod => 'How will you pay?';

  @override
  String uexpConsentPolicy(String policy) {
    return 'Cancellation policy: $policy';
  }

  @override
  String get uexpConsentUnderstand => 'I understand';

  @override
  String get uexpConsentContinue => 'Continue';

  @override
  String get uexpGuidePix =>
      'PIX: if you are the victim of a scam, ask your bank right away to open a MED (Mecanismo Especial de Devolução) claim.';

  @override
  String get uexpGuidePaypal =>
      'PayPal: choose Goods & Services, never Friends & Family, to keep buyer protection.';

  @override
  String get uexpGuideVenmo =>
      'Venmo: use purchase protection (goods and services) when available.';

  @override
  String get uexpGuideCard =>
      'Card payments can be disputed with your card issuer.';

  @override
  String get uexpGuideCash =>
      'Pay only when you meet the host, count the money together and ask for a receipt if needed.';

  @override
  String get uexpPolicyFlexible => 'Flexible';

  @override
  String get uexpPolicyModerate => 'Moderate';

  @override
  String get uexpPolicyStrict => 'Strict';

  @override
  String get uexpPolicyFlexibleDesc =>
      'Full refund if you cancel at least 24 h before the start; no refund after that.';

  @override
  String get uexpPolicyModerateDesc =>
      'Full refund if you cancel at least 7 days before; 50% if at least 24 h before; no refund after that.';

  @override
  String get uexpPolicyStrictDesc =>
      'Full refund if you cancel at least 7 days before; no refund after that.';

  @override
  String get uexpPolicyWhen => 'If you cancel';

  @override
  String get uexpPolicyRefund => 'Refund';

  @override
  String get uexpPolicyMoreThan7d => '7 days or more before';

  @override
  String get uexpPolicy7dTo24h => 'Less than 7 days, but at least 24 h before';

  @override
  String get uexpPolicyMoreThan24h => '24 h or more before';

  @override
  String get uexpPolicyLess24h => 'Less than 24 h before';

  @override
  String get uexpPolicyLess7d => 'Less than 7 days before';

  @override
  String get uexpPolicyAlwaysTitle => 'Always applies';

  @override
  String get uexpRuleHostCancels => 'The host cancels: 100% refund.';

  @override
  String get uexpRuleGrace =>
      'You cancel within 24 h of the host confirming your booking, and the experience is more than 48 h away: 100% refund.';

  @override
  String get uexpRuleReport =>
      'Host no-show or not as described: report it within 24 h.';

  @override
  String get uexpPolicyNotes => 'Notes on your policy (optional)';

  @override
  String get uexpPolicyHostNotes => 'Host notes';

  @override
  String get uexpReportScamTitle => 'Report this experience';

  @override
  String get uexpReasonScam => 'Scam or fraud';

  @override
  String get uexpReasonOffPlatform => 'Asked to pay outside the app';

  @override
  String get uexpReasonMisleading => 'Not as described';

  @override
  String get uexpReasonNoShow => 'Host didn\'t show up';

  @override
  String get uexpReasonInappropriate => 'Inappropriate';

  @override
  String get uexpReasonOther => 'Other';

  @override
  String get uexpReportDetailsHint => 'What happened? (optional)';

  @override
  String get uexpReportSend => 'Send report';

  @override
  String get bkStatusRequested => 'Requested';

  @override
  String get bkStatusConfirmed => 'Confirmed';

  @override
  String get bkStatusDeclined => 'Declined';

  @override
  String get bkStatusExpired => 'Expired';

  @override
  String get bkStatusCancelledGuest => 'Cancelled by guest';

  @override
  String get bkStatusCancelledHost => 'Cancelled by host';

  @override
  String get bkStatusCompleted => 'Completed';

  @override
  String get bkStatusNoShow => 'No-show';

  @override
  String get bkStatusDisputed => 'Problem reported';

  @override
  String get bkStatusResolved => 'Resolved';

  @override
  String get bkStatusUnknown => 'Unknown';

  @override
  String get bkRequestToBook => 'Request to book';

  @override
  String get bkChooseDate => 'Choose a date';

  @override
  String get bkNoDates => 'No dates available yet.';

  @override
  String bkDatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates available',
      one: '1 date available',
    );
    return '$_temp0';
  }

  @override
  String bkSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats left',
      one: '1 seat left',
    );
    return '$_temp0';
  }

  @override
  String get bkFull => 'Full';

  @override
  String get bkGuests => 'Guests';

  @override
  String bkGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String bkMaxGuests(int max) {
    return 'Up to $max on this date';
  }

  @override
  String get bkSummary => 'Summary';

  @override
  String get bkRequestInfo =>
      'The host has up to 48 h to accept your request. Nothing is paid before they accept.';

  @override
  String get bkInstantInfo => 'Instant booking: confirmed right away.';

  @override
  String get bkConfirmBooking => 'Confirm booking';

  @override
  String get bkSendRequest => 'Send request';

  @override
  String get bkRetry => 'Retry';

  @override
  String get bkResultConfirmedTitle => 'You\'re booked!';

  @override
  String get bkResultConfirmedBody =>
      'Show your check-in code to the host when you meet. You find it in My bookings.';

  @override
  String get bkResultRequestTitle => 'Request sent';

  @override
  String get bkResultRequestBody =>
      'We\'ll notify you as soon as the host answers (within 48 h).';

  @override
  String get bkViewBooking => 'View booking';

  @override
  String get bkDone => 'Done';

  @override
  String get bkPayment => 'Payment';

  @override
  String get bkCashAtMeeting => 'Pay the host in cash when you meet.';

  @override
  String get bkPayLinkHint =>
      'Pay the host with their link, then tap \"Mark as paid\" in your booking.';

  @override
  String get bkPayAfterAccept =>
      'You pay with the host\'s link once they accept your request.';

  @override
  String get bkPayNow => 'Open payment link';

  @override
  String get bkCopyPixKey => 'Copy PIX key';

  @override
  String get bkMyBookings => 'My bookings';

  @override
  String get bkHostBookings => 'Bookings received';

  @override
  String get bkUpcoming => 'Upcoming';

  @override
  String get bkPast => 'Past';

  @override
  String get bkNoUpcoming => 'No upcoming bookings.';

  @override
  String get bkNoPast => 'No past bookings.';

  @override
  String get bkBookings => 'Bookings';

  @override
  String get bkViewBookings => 'View bookings';

  @override
  String get bkDetailTitle => 'Booking';

  @override
  String get bkNotFound => 'This booking is not available.';

  @override
  String get bkExperienceGone => 'This experience is no longer listed.';

  @override
  String get bkOpenExperience => 'Open experience';

  @override
  String get bkGuest => 'Guest';

  @override
  String get bkCheckedIn => 'Checked in';

  @override
  String bkAnswerBefore(String date) {
    return 'Answer before $date';
  }

  @override
  String get bkWaitingForHost => 'Waiting for the host to answer.';

  @override
  String get bkRequestTitle => 'Booking request';

  @override
  String get bkRequestHostHint =>
      'Check the guest\'s profile and rating, then accept or decline. Unanswered requests expire after 48 h.';

  @override
  String get bkAccept => 'Accept';

  @override
  String get bkDecline => 'Decline';

  @override
  String get bkDeclineConfirm => 'Decline this request?';

  @override
  String get bkDeclineBody =>
      'The guest is notified and the seats are released.';

  @override
  String get bkAccepted => 'Booking accepted';

  @override
  String get bkDeclined => 'Request declined';

  @override
  String get bkCheckInTitle => 'Check-in';

  @override
  String get bkShowCode => 'Show check-in code';

  @override
  String get bkCodeTitle => 'Your check-in code';

  @override
  String get bkCodeHint =>
      'Show this QR code to the host when you meet. They can also type the code.';

  @override
  String get bkCheckInGuest => 'Check in guest';

  @override
  String get bkScanQr => 'Scan QR code';

  @override
  String get bkTypeCode => 'Type the code';

  @override
  String get bkCodeLabel => 'Check-in code';

  @override
  String get bkScanInstructions => 'Point the camera at the guest\'s QR code';

  @override
  String get bkWrongBooking => 'This QR code is for another booking.';

  @override
  String get bkTorch => 'Flash';

  @override
  String get bkSwitchCamera => 'Switch camera';

  @override
  String get bkCashReceivedQuestion => 'Did you also receive the cash payment?';

  @override
  String get bkCashYes => 'Yes, received';

  @override
  String get bkCashNo => 'Not yet';

  @override
  String get bkCheckedInSnack => 'Guest checked in';

  @override
  String get bkMarkNoShow => 'Mark no-show';

  @override
  String get bkNoShowConfirm =>
      'Mark the guest as a no-show? No refund is due, and they can contest it until 24 h after the end.';

  @override
  String get bkNoShowMarked => 'Marked as no-show';

  @override
  String get bkNotPaidYet => 'Not marked as paid yet.';

  @override
  String get bkYouMarkedPaid =>
      'You marked it as paid. Waiting for the host to confirm.';

  @override
  String get bkGuestSaysPaid =>
      'The guest says they paid. Confirm once you received it.';

  @override
  String get bkPaymentConfirmed => 'Payment confirmed by the host.';

  @override
  String get bkCashConfirmed => 'Cash received (confirmed by the host).';

  @override
  String get bkMarkPaid => 'Mark as paid';

  @override
  String get bkConfirmPayment => 'Payment received';

  @override
  String get bkCashReceived => 'Cash received';

  @override
  String get bkPaidMarked => 'Marked as paid';

  @override
  String get bkPaymentConfirmedSnack => 'Payment confirmed';

  @override
  String get bkRefundTitle => 'Refund';

  @override
  String bkRefundOwed(String percent, String amount) {
    return 'The host owes you $percent back ($amount).';
  }

  @override
  String get bkRefundNone => 'No refund is due under the cancellation policy.';

  @override
  String get bkRefundCashUnpaid => 'No refund is due: the cash was never paid.';

  @override
  String get bkRefundOffPlatform =>
      'GreenGo does not handle the money: the host refunds you directly, the same way you paid.';

  @override
  String bkIfCancelNow(String percent, String amount) {
    return 'If you cancel now: $percent back ($amount).';
  }

  @override
  String get bkIfCancelNowNothing => 'If you cancel now, no refund is due.';

  @override
  String get bkIfCancelNowCash =>
      'Cash is paid at the meeting, so cancelling now costs nothing.';

  @override
  String get bkIfCancelNowFree => 'Free experience: you can cancel at no cost.';

  @override
  String get bkCancelRequestNoCharge =>
      'The host has not accepted yet: cancelling the request costs nothing.';

  @override
  String get bkHostCancelWarning =>
      'You cancel: the guest is owed 100% back and it counts as a host cancellation (3 in 90 days are reviewed by GreenGo).';

  @override
  String get bkCancelBooking => 'Cancel booking';

  @override
  String get bkCancelConfirmTitle => 'Cancel this booking?';

  @override
  String get bkCancelReasonHint => 'Reason (optional)';

  @override
  String get bkKeepBooking => 'Keep booking';

  @override
  String get bkCancelled => 'Booking cancelled';

  @override
  String get bkReportProblem => 'Report a problem';

  @override
  String get bkDisputeIntro =>
      'Host didn\'t show up, or the experience was not as described? Tell us within 24 h of the end and our team will review it.';

  @override
  String get bkDisputeHint => 'What happened? (at least 10 characters)';

  @override
  String get bkSendReport => 'Send report';

  @override
  String get bkDisputeSent =>
      'Thanks. Our team will review it and contact you both.';

  @override
  String get bkDisputeOpen =>
      'A problem was reported. Our team is reviewing it.';

  @override
  String bkDisputeResolved(String percent) {
    return 'Reviewed by GreenGo: $percent refund owed.';
  }

  @override
  String get bkReviewGuest => 'Review your guest';

  @override
  String get bkReviewGuestIntro =>
      'Help other hosts: how was hosting this guest? Both reviews stay hidden until your guest reviews too, or 14 days pass.';

  @override
  String get bkReviewGuestHint => 'Punctual, respectful, fun? (optional)';

  @override
  String get bkGuestReviewSaved =>
      'Thanks! Reviews are revealed when your guest has reviewed too, or in 14 days.';

  @override
  String get bkGuestReviewed => 'Your review of this guest';

  @override
  String get bkGuestReviewHeld =>
      'Hidden until your guest reviews too, or 14 days pass.';

  @override
  String get bkReviewExperience => 'Review the experience';

  @override
  String get bkReviewExperienceHint =>
      'Share how it went: your review helps other travelers.';

  @override
  String get bkReviewHeld =>
      'Your review will be published when the host has reviewed you too, or in 14 days.';

  @override
  String get bkReviewNeedsBooking =>
      'Only guests who took part through a booking can review this experience.';

  @override
  String get bkNewGuest => 'New guest';

  @override
  String get bkDatesTitle => 'Dates & availability';

  @override
  String get bkAddDate => 'Add date';

  @override
  String get bkEditDate => 'Edit date';

  @override
  String get bkDeleteDate => 'Delete date';

  @override
  String get bkCancelDate => 'Cancel date';

  @override
  String get bkKeepDate => 'Keep date';

  @override
  String get bkCancelDateTitle => 'Cancel this date?';

  @override
  String bkCancelDateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $count booked seats on this date are cancelled and every guest is owed a 100% refund.',
      one:
          'The booking on this date is cancelled and the guest is owed a 100% refund.',
    );
    return '$_temp0 This counts as a host cancellation.';
  }

  @override
  String get bkDateSaved => 'Date saved';

  @override
  String get bkDateDeleted => 'Date deleted';

  @override
  String bkDateCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Date cancelled: $count bookings cancelled',
      one: 'Date cancelled: 1 booking cancelled',
      zero: 'Date cancelled',
    );
    return '$_temp0';
  }

  @override
  String get bkNoDatesHost =>
      'No upcoming dates. Add the dates guests can book.';

  @override
  String get bkRequestToBookToggle => 'Request to book';

  @override
  String get bkRequestToBookDesc =>
      'You accept or decline each booking (within 48 h). Off: guests book instantly.';

  @override
  String get bkDatesAfterSave =>
      'Save the experience first, then add its dates from My experiences.';

  @override
  String get bkDate => 'Date';

  @override
  String get bkStartTime => 'Start';

  @override
  String get bkEndTime => 'End';

  @override
  String get bkCapacity => 'Seats';

  @override
  String bkBookedOf(int booked, int capacity) {
    return '$booked/$capacity booked';
  }

  @override
  String get bkSlotCancelled => 'Cancelled';

  @override
  String get bkTimesFrozen =>
      'Guests are booked on this date: only the number of seats can change. To move it, cancel the date.';

  @override
  String get bkSlotSaveFailed =>
      'Couldn\'t save the date. Check your connection and try again.';

  @override
  String get bkSlotErrPast => 'Pick a start time in the future.';

  @override
  String get bkSlotErrEnd => 'The end must be after the start.';

  @override
  String get bkSlotErrTooLong => 'A date can last at most 24 h.';

  @override
  String get bkSlotErrTooFar => 'Dates can be at most one year ahead.';

  @override
  String bkSlotErrCapacity(int max) {
    return 'Seats: from 1 to $max.';
  }

  @override
  String bkSlotErrBelowBooked(int count) {
    return '$count seats are already booked: keep at least that many.';
  }

  @override
  String bkErrSlotFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count seats left on this date.',
      one: 'Only 1 seat left on this date.',
      zero: 'This date is full.',
    );
    return '$_temp0';
  }

  @override
  String get bkErrAlreadyBooked => 'You already have a booking for this date.';

  @override
  String get bkErrIdRequired => 'Upload an ID document to book.';

  @override
  String get bkErrHostNotVerified =>
      'This host can\'t take paid bookings yet (identity not verified).';

  @override
  String get bkErrPaymentMethodRequired => 'Choose how you will pay.';

  @override
  String get bkErrPaymentMethodNotAccepted =>
      'The host no longer accepts this payment method. Choose another one.';

  @override
  String get bkErrOwnExperience => 'You can\'t book your own experience.';

  @override
  String get bkErrNotAvailable => 'This experience isn\'t available to you.';

  @override
  String get bkErrSlotStarted => 'This date has already started.';

  @override
  String get bkErrSlotClosed => 'This date is no longer available.';

  @override
  String get bkErrNotBookable => 'This experience can\'t be booked right now.';

  @override
  String get bkErrPriceInvalid =>
      'This listing\'s price is incomplete. Ask the host to update it.';

  @override
  String get bkErrHostUnavailable =>
      'The host is not taking bookings right now.';

  @override
  String get bkErrConsentRequired => 'Please accept the booking terms first.';

  @override
  String bkErrTooManyGuests(int max) {
    return 'At most $max guests per booking.';
  }

  @override
  String get bkErrAccountRestricted =>
      'Your account can\'t make bookings right now.';

  @override
  String get bkErrNetwork =>
      'Connection problem. Try again: you won\'t be booked twice.';

  @override
  String get bkErrRequestExpired => 'This request has expired.';

  @override
  String get bkErrStateChanged =>
      'This booking changed in the meantime. Pull down to refresh.';

  @override
  String get bkErrInvalidCode =>
      'This check-in code isn\'t valid for this booking.';

  @override
  String get bkErrOutsideCheckIn =>
      'Check-in opens 2 h before the start and closes 12 h after the end.';

  @override
  String get bkErrTooEarlyNoShow =>
      'You can mark a no-show from 30 min after the start.';

  @override
  String get bkErrGuestCheckedIn => 'The guest is already checked in.';

  @override
  String get bkErrCashBeforeMeeting =>
      'Cash can be confirmed once you meet the guest.';

  @override
  String get bkErrOutsideDispute =>
      'Problems can be reported from the start until 24 h after the end.';

  @override
  String bkErrReasonRequired(int min) {
    return 'Describe the problem (at least $min characters).';
  }

  @override
  String get uexpDatesRequiredHint =>
      'Guests can only book the dates you set, and every booking is a request you accept or decline. Add at least one upcoming date to publish.';

  @override
  String get uexpDatesRequiredToPublish =>
      'Add at least one upcoming date to publish. Your experience is saved as a draft.';

  @override
  String bkRefundIfPaid(String percent, String amount) {
    return 'If you already paid, the host owes you $percent back ($amount).';
  }

  @override
  String get shareLinkCopied => 'Link copied to the clipboard';

  @override
  String shareOtherProfileMessage(String name, String link) {
    return 'Meet $name on GreenGo: $link';
  }

  @override
  String get communitiesExperiencesEmpty => 'No experiences yet';

  @override
  String uexpPostedInCommunity(String community) {
    return 'Posted in $community';
  }

  @override
  String get uexpErrCommunityNotAllowed =>
      'Only this community\'s owner and admins can post experiences here.';

  @override
  String attrRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$_temp0';
  }

  @override
  String get attrNoRatingsYet => 'No ratings yet';

  @override
  String get attrRateThis => 'Rate this attraction';

  @override
  String get attrYourRating => 'Your rating';

  @override
  String get attrRatingRemove => 'Remove my rating';

  @override
  String get attrRatingFailed =>
      'Couldn\'t save your rating. Please try again.';

  @override
  String get attrRatingGreengoLabel => 'GreenGo community';

  @override
  String get attrRatingGoogleLabel => 'Google rating';

  @override
  String get webUpdateAvailable => 'A new version of GreenGo is available.';

  @override
  String get webUpdateRefresh => 'Refresh';

  @override
  String get webUpdateLater => 'Later';

  @override
  String get userErrorTitle => 'Oops!';

  @override
  String get userErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get userErrorTimeout =>
      'This is taking longer than expected. Please try again.';

  @override
  String get userErrorPermissionDenied =>
      'You don\'t have permission to do that.';

  @override
  String get userErrorNotFound => 'This content is no longer available.';

  @override
  String get userErrorTooManyRequests =>
      'You\'re doing that too often. Please wait a moment and try again.';

  @override
  String get userErrorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get userErrorInvalidInput =>
      'Some of the information isn\'t valid. Please check it and try again.';

  @override
  String get userErrorNotAllowed => 'This action isn\'t available right now.';

  @override
  String get userErrorUploadFailed =>
      'The upload didn\'t go through. Please try again.';

  @override
  String videoMaxDurationError(int seconds) {
    return 'Video must be $seconds seconds or less';
  }

  @override
  String get exploreLoadingContent => 'Finding the best of what\'s around you…';

  @override
  String get checkinWrongPlace =>
      'This code is for a different event or experience';

  @override
  String get checkinOutsideWindow => 'Check-in is not open right now';

  @override
  String get checkinNotConfirmed => 'This person is not confirmed for it';

  @override
  String get checkinUpdateApp =>
      'Old ticket: ask them to update GreenGo and show the new code';

  @override
  String get checkinNetwork => 'No connection. Try again.';

  @override
  String get expDoorTitle => 'Check in guests';

  @override
  String get expDoorInstructions => 'Scan each guest\'s booking QR code';

  @override
  String expDoorCheckedInNow(int count) {
    return '$count checked in';
  }

  @override
  String expDoorAdmits(int count) {
    return 'Admits $count people';
  }

  @override
  String get expDoorHelpers => 'Door helpers';

  @override
  String get expDoorHelpersHint =>
      'Members you add here can scan guests in for this experience.';

  @override
  String expDoorHelpersMax(int max) {
    return 'Up to $max helpers';
  }

  @override
  String get expAttendanceTitle => 'Attendance';

  @override
  String get expAttendanceEmpty =>
      'No confirmed guests for upcoming dates yet.';

  @override
  String expAttendanceCount(int checked, int total) {
    return '$checked/$total in';
  }

  @override
  String get qrHubExperienceTicket => 'Experience';

  @override
  String metInPersonOn(String date) {
    return 'Met in person · $date';
  }

  @override
  String metInPersonTimes(int count, String date) {
    return 'Met in person $count times · last $date';
  }

  @override
  String get paymentLinksTitle => 'Payment methods';

  @override
  String get paymentLinksNone => 'No payment methods added';

  @override
  String paymentLinksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payment methods',
      one: '1 payment method',
    );
    return '$_temp0';
  }

  @override
  String get paymentLinksInfoTitle => 'Get paid directly';

  @override
  String get paymentLinksInfoBody =>
      'Let people pay you with your own accounts. Money goes straight to you — GreenGo never processes, holds or takes a fee from these payments.';

  @override
  String get paymentLinksHintHandle => 'Username or link';

  @override
  String get paymentLinksHintPix =>
      'CPF, CNPJ, e-mail, +55 phone or random key';

  @override
  String get paymentLinksHintLink => 'Paste your payment link';

  @override
  String paymentLinkInvalid(String method) {
    return 'Invalid $method value — check it and try again';
  }

  @override
  String get paymentLinksUpdated => 'Payment methods updated';

  @override
  String get paymentLinksRules =>
      'Use these only for payments between people (gifts, tips, in-person services and tours). GreenGo coins and memberships can only be bought in the app.';

  @override
  String get paymentLinksSection => 'Pay directly';

  @override
  String paymentDisclaimerTitle(String name) {
    return 'Pay $name directly';
  }

  @override
  String paymentDisclaimerBody(String name, String method) {
    return 'This payment goes from you to $name through $method. GreenGo is not involved and cannot refund, protect or verify it. Only pay people you trust.';
  }

  @override
  String paymentContinueTo(String method) {
    return 'Continue to $method';
  }

  @override
  String get pixInstructions =>
      'Scan the QR code or copy the Pix code into your bank app, then enter the amount there.';

  @override
  String get pixKeyLabel => 'Pix key';

  @override
  String get pixCopyCode => 'Copy Pix code';

  @override
  String get pixCopyKey => 'Copy key';

  @override
  String get pixCopied => 'Copied — paste it in your bank app\'s Pix area';

  @override
  String get bkRepeat => 'Repeat';

  @override
  String get bkRepeatHint => 'Add these times on several dates at once';

  @override
  String get bkRepeatThisDate => 'Repeat this date';

  @override
  String get bkRepeatDates => 'Apply to dates';

  @override
  String get bkRepeatPickRange => 'Choose the dates on the calendar';

  @override
  String get bkRepeatOnDays => 'On these days';

  @override
  String get bkRepeatEveryDay => 'Every day';

  @override
  String bkRepeatPreview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates will be added',
      one: '1 date will be added',
      zero: 'No dates match — choose a wider range or more days',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatCapped(int max) {
    return 'up to $max dates at a time';
  }

  @override
  String bkRepeatAddButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count dates',
      one: 'Add 1 date',
      zero: 'Add dates',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates added',
      one: '1 date added',
      zero: 'No new dates added',
    );
    return '$_temp0';
  }

  @override
  String bkRepeatSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already existed',
      one: '1 already existed',
    );
    return '$_temp0';
  }

  @override
  String get bkChooseTime => 'Choose a time';

  @override
  String get bkNoFreeTimes => 'No free times left on this date';

  @override
  String bkTimesHint(String duration) {
    return 'Each time lasts $duration and is only for you and your group.';
  }

  @override
  String bkWindowHint(String duration) {
    return 'This is when you are available. Guests each book their own $duration time inside it, and your bookings never overlap, across all your experiences.';
  }

  @override
  String bkWindowPeopleBooked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people booked',
      one: '1 person booked',
      zero: 'No bookings yet',
    );
    return '$_temp0';
  }

  @override
  String get bkErrTimeTaken =>
      'That time was just taken. Please pick another one.';

  @override
  String get bkErrInvalidStart => 'That time is not available on this date.';

  @override
  String get coinsGiftPurchaseHold =>
      'Coins you bought in the last 72 hours can\'t be gifted yet. You can still spend them on features.';

  @override
  String get coinsGiftDailyLimit =>
      'You\'ve reached today\'s gifting limit (10 gifts or 5,000 coins). Please try again tomorrow.';

  @override
  String get coinReasonRefundClawback => 'Refunded purchase reversed';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get aiConsentTitle => 'AI features use Google services';

  @override
  String get aiConsentIntro =>
      'Smart replies, the AI language coach, translating messages you receive and read-aloud audio only work if GreenGo sends the text involved to Google.';

  @override
  String get aiConsentProviders =>
      'Who: Google Gemini (suggestions and coaching), Google Cloud Text-to-Speech (audio) and Google Translate (translations).';

  @override
  String get aiConsentWhatSent =>
      'What is sent: only the text of the message you use the feature on (including messages other people sent you) and the languages. Never your name, photos or profile.';

  @override
  String get aiConsentWhy =>
      'Why: only to produce the suggestion, translation or audio you asked for.';

  @override
  String get aiConsentDeclineInfo =>
      'If you decline, these features stay off and nothing is sent. Tap any of them later to review your choice.';

  @override
  String get aiConsentAccept => 'Allow';

  @override
  String get aiConsentDecline => 'Decline';

  @override
  String get aiConsentDisabledNotice =>
      'This feature is off because you chose not to send text to Google AI services.';

  @override
  String get aiConsentReview => 'Review';

  @override
  String get profileDeleteReauthRequired =>
      'For your security, please confirm your password again to delete your account.';

  @override
  String get profileDeleteNetworkError =>
      'No connection. Your account was not deleted. Please try again.';

  @override
  String get profileDeleteFailed =>
      'We could not delete your account, and nothing was deleted. Please try again or contact support.';

  @override
  String get onboardingAgeBlockedTitle => 'GreenGo is for adults';

  @override
  String get onboardingAgeBlockedBody =>
      'You must be at least 18 years old to use GreenGo, so we cannot create your account.';

  @override
  String get distanceBucketUnder2Km => '< 2 km';

  @override
  String get distanceBucket2To5Km => '2-5 km';

  @override
  String get distanceBucket5To10Km => '5-10 km';

  @override
  String get distanceBucket10To25Km => '10-25 km';

  @override
  String get distanceBucketOver25Km => '25+ km';

  @override
  String distanceUnderKm(String km) {
    return '< $km km';
  }

  @override
  String distanceOverKm(String km) {
    return '$km+ km';
  }

  @override
  String get idConsentTitle => 'Before you upload your ID';

  @override
  String get idConsentWhat =>
      'What we process: a photo of your identity document. We read your date of birth and the document number from it automatically (OCR).';

  @override
  String get idConsentWho =>
      'Who processes it: GreenGo, using Google Cloud Vision (Google acts as our processor).';

  @override
  String get idConsentRetention =>
      'How long: the image is deleted as soon as a decision is made, automatically or by a reviewer. If a person needs to review it, it is kept for at most 7 days, then deleted, and you will be asked to upload it again.';

  @override
  String get idConsentKept =>
      'What we keep: only whether you are verified, how, the decision date, your birth year, and a keyed one-way fingerprint of the document number so that one document cannot verify many accounts.';

  @override
  String get idConsentAccess =>
      'Who can see it: no other users. Only automated processing and, if needed, a small number of authorised GreenGo reviewers.';

  @override
  String get idConsentAccept => 'I agree, continue';

  @override
  String get idConsentRecordError =>
      'We could not record your consent, so nothing was uploaded. Check your connection and try again.';

  @override
  String get ageVerifyRejectedExpired =>
      'Your document could not be reviewed in time and has been deleted. Please upload it again.';

  @override
  String get analyticsConsentTitle => 'Help us improve GreenGo';

  @override
  String get analyticsConsentBody =>
      'With your permission we use Google Firebase Analytics, Crashlytics and Performance Monitoring to understand how the app is used and to fix crashes. This stores and reads identifiers on your device. Nothing is collected unless you allow it. You can change this at any time in Settings > Privacy & data.';

  @override
  String get analyticsConsentAllow => 'Allow';

  @override
  String get analyticsConsentDecline => 'Decline';

  @override
  String get privacySettingsTitle => 'Privacy & data';

  @override
  String get privacySettingsSubtitle =>
      'Analytics, crash reports and marketing emails';

  @override
  String get privacyAnalyticsToggle => 'Usage analytics & crash reports';

  @override
  String get privacyAnalyticsToggleSubtitle =>
      'Share usage statistics and crash reports with us (Google Firebase) to help improve the app.';

  @override
  String get privacyMarketingEmailToggle => 'News and offers by email';

  @override
  String get privacyMarketingEmailSubtitle =>
      'Occasional emails about new features, tips, activity summaries and offers. You can unsubscribe at any time.';

  @override
  String get privacySettingsSaveError =>
      'Could not save your choice. Please try again.';

  @override
  String get notificationCatMarketing => 'Marketing & promotions';

  @override
  String get notificationCatMarketingSubtitle =>
      'News, offers and announcements from GreenGo. Off unless you turn it on.';

  @override
  String get signupMarketingEmailConsent => 'Send me news and offers by email';

  @override
  String get signupMarketingEmailConsentSubtitle =>
      'Optional. You can unsubscribe at any time.';

  @override
  String get moderationDecisionTitle => 'Moderation decision';

  @override
  String get moderationDecisionIntro =>
      'Our team took action on your account or content under our Community Guidelines. This is the statement of reasons.';

  @override
  String get moderationDecisionActionLabel => 'Action taken';

  @override
  String get moderationDecisionReasonLabel => 'Reason';

  @override
  String get moderationDecisionExplanationLabel => 'Explanation from our team';

  @override
  String moderationDecisionAppealUntil(String date) {
    return 'You can appeal until $date.';
  }

  @override
  String get moderationDecisionAppealButton => 'Appeal this decision';

  @override
  String get moderationDecisionAppealHint =>
      'Explain why you think this decision is wrong (at least 10 characters).';

  @override
  String get moderationDecisionAppealSubmit => 'Send appeal';

  @override
  String get moderationDecisionAppealSent =>
      'Your appeal was sent. Our team will review it again and let you know.';

  @override
  String get moderationDecisionAppealAlready =>
      'You have already appealed this decision.';

  @override
  String get moderationDecisionAppealClosed =>
      'This decision can no longer be appealed.';

  @override
  String get moderationDecisionAppealError =>
      'Your appeal could not be sent. Please try again.';

  @override
  String get moderationDecisionAppealTooShort =>
      'Please write at least 10 characters.';

  @override
  String get moderationDecisionNotAppealable =>
      'This decision cannot be appealed in the app. Contact support if you think it is wrong.';

  @override
  String get moderationActionRemoveContent => 'Content removed';

  @override
  String get moderationActionWarning => 'Warning issued';

  @override
  String get moderationActionSuspend => 'Account temporarily suspended';

  @override
  String get moderationActionBan => 'Account banned';

  @override
  String get moderationActionShadowBan => 'Reduced visibility of your profile';

  @override
  String get moderationActionRequireVerification =>
      'Identity verification required';

  @override
  String get moderationActionOther => 'Restriction applied';

  @override
  String get moderationReasonCsae => 'Child sexual exploitation or abuse';

  @override
  String get moderationReasonUnderage => 'Underage user';

  @override
  String get moderationReasonSexualContent => 'Sexual content';

  @override
  String get moderationReasonInappropriate => 'Inappropriate content';

  @override
  String get moderationReasonThreats => 'Threats';

  @override
  String get moderationReasonViolence => 'Violence';

  @override
  String get moderationReasonHarassment => 'Harassment or bullying';

  @override
  String get moderationReasonHate => 'Hate speech';

  @override
  String get moderationReasonSpam => 'Spam';

  @override
  String get moderationReasonScam => 'Scam or fraud';

  @override
  String get moderationReasonImpersonation => 'Impersonation or fake profile';

  @override
  String get moderationReasonPrivacy => 'Sharing personal information';

  @override
  String get moderationReasonMisleading => 'Misleading content';

  @override
  String get moderationReasonNoShow => 'Did not show up to a booking';

  @override
  String get moderationReasonOffPlatformPayment =>
      'Payment outside the platform';

  @override
  String get moderationReasonOther =>
      'Other breach of our Community Guidelines';

  @override
  String get checkoutConsentTitle => 'Before you pay';

  @override
  String get checkoutCoinWaiverCheckbox =>
      'I agree that the coins are delivered immediately and I acknowledge that I lose my right of withdrawal once delivery starts.';

  @override
  String get checkoutMembershipWithdrawalInfo =>
      'Right of withdrawal: you can withdraw from this membership within 14 days of purchase (7 days for purchases in Brazil) without giving a reason and receive a full refund, using \"Withdraw from contract\" in the Shop or on our website. The membership renews automatically until you cancel; you can cancel anytime in the billing portal.';

  @override
  String get checkoutContinueToPayment => 'Continue to payment';

  @override
  String get withdrawFromContract => 'Withdraw from contract';

  @override
  String get withdrawalDialogIntro =>
      'Choose the purchase to withdraw from. We will email a confirmation link to the address used for the purchase; nothing is cancelled or refunded until you confirm.';

  @override
  String get withdrawalNothingEligible =>
      'None of your web purchases can be withdrawn from right now. Memberships can be withdrawn within 14 days of purchase (7 days in Brazil); coin purchases only if the right was not waived at checkout.';

  @override
  String withdrawalDeadline(String date) {
    return 'Withdraw by $date';
  }

  @override
  String get withdrawalRequestSent =>
      'Check your email and confirm the withdrawal with the link we sent.';

  @override
  String get withdrawalRequestFailed =>
      'The withdrawal request could not be sent. Please try again or email support@greengochat.com.';

  @override
  String webSubscriptionRenewsOn(
      String plan, String price, String interval, String date) {
    return '$plan: $price per $interval. Renews automatically on $date.';
  }

  @override
  String webSubscriptionEndsOn(
      String plan, String price, String interval, String date) {
    return '$plan: $price per $interval. Cancelled; access ends on $date.';
  }

  @override
  String get billingIntervalMonth => 'month';

  @override
  String get billingIntervalYear => 'year';

  @override
  String get cancelAnytimeBillingPortal =>
      'Cancel anytime in the billing portal';

  @override
  String get billingPortalOpenFailed =>
      'Could not open the billing portal. Please try again.';

  @override
  String get subscriptionAutoRenewInfoWeb =>
      'Subscriptions renew automatically at the price and interval shown until you cancel. Cancel anytime in the billing portal.';

  @override
  String get webBillingTitle => 'Billing and withdrawal';

  @override
  String get ageAssuranceTitle => 'Verify your age to use this feature';

  @override
  String get ageAssuranceBody =>
      'Where you live, the law requires us to confirm that you are an adult before you can discover people or start new private conversations. The rest of GreenGo works as usual.';

  @override
  String get ageAssuranceExistingChats =>
      'Conversations you have already taken part in stay available.';

  @override
  String get ageAssuranceStoreCheckAndroid => 'Confirm with Google Play';

  @override
  String get ageAssuranceStoreCheckIos => 'Confirm with the App Store';

  @override
  String get ageAssuranceStoreHint =>
      'Uses the age your store account has already confirmed. We only receive an age range, never your date of birth.';

  @override
  String get ageAssuranceIdOption => 'Verify with an ID document';

  @override
  String get ageAssuranceStoreUnavailable =>
      'Your store account could not confirm your age. Please verify with an ID document instead.';

  @override
  String get ageAssuranceVerified => 'Thank you, your age is confirmed.';

  @override
  String get ageAssuranceWebNote =>
      'On the web, your age is confirmed with an ID document.';

  @override
  String get ageVerifyWhyRegional =>
      'To discover people and start new private chats where you live, we need to confirm you are over 18.';

  @override
  String get privacyDownloadDataTitle => 'Download my data';

  @override
  String get privacyDownloadDataSubtitle =>
      'A copy of your profile, settings, photos and the messages you sent (ZIP file)';

  @override
  String get privacyDownloadDataConfirmBody =>
      'We will prepare a ZIP file with the data we hold about you. To protect other people, messages they sent you are not included. You will get a download link here and by email. The link works for 24 hours and you can ask for one copy per day.';

  @override
  String get privacyDownloadDataConfirmButton => 'Prepare my data';

  @override
  String get privacyDownloadDataPreparing =>
      'Preparing your data. This can take a few minutes...';

  @override
  String get privacyDownloadDataReadyTitle => 'Your data is ready';

  @override
  String get privacyDownloadDataReadyBody =>
      'Download the ZIP file now. The link works for 24 hours.';

  @override
  String get privacyDownloadDataReadyEmailed =>
      'We also sent the link to your email address.';

  @override
  String get privacyDownloadDataOpen => 'Download';

  @override
  String get privacyDownloadDataRateLimited =>
      'You can download your data once every 24 hours. Use the link we emailed you, or try again tomorrow.';

  @override
  String get privacyDownloadDataInProgress =>
      'Your data is already being prepared. Please wait a few minutes.';

  @override
  String get privacyDownloadDataFailed =>
      'We could not prepare your data. Please try again later.';

  @override
  String get reauthPasswordBody =>
      'For your security, enter your password again to continue.';

  @override
  String get reauthContinue => 'Continue';

  @override
  String get reauthSignInAgain =>
      'For your security, please sign out and sign in again, then try once more.';

  @override
  String get profilePhotoPrevious => 'Previous photo';

  @override
  String get profilePhotoNext => 'Next photo';

  @override
  String get aiServicesTitle => 'AI services';

  @override
  String get aiServicesSubtitleOn =>
      'On: AI features may send the text you use them on to Google.';

  @override
  String get aiServicesSubtitleOff => 'Off: no text is sent to AI services.';

  @override
  String get aiServicesWhatsIncluded => 'What this switch covers';

  @override
  String get aiServicesFeatureCoach =>
      'Smart replies and the AI language coach (grammar, word breakdown, cultural tips)';

  @override
  String get aiServicesFeatureTranslate =>
      'Translating chat messages you receive';

  @override
  String get aiServicesFeatureReadAloud => 'Read-aloud audio and pronunciation';

  @override
  String get aiServicesFeatureSupport =>
      'Automatic replies from the support assistant (when off, a person answers you)';

  @override
  String get aiServicesSafetyNote =>
      'Safety screening of photos and messages always stays on: it protects everyone and cannot be turned off.';

  @override
  String get aiServicesTurnedOff =>
      'AI services turned off. Your choice has been recorded.';

  @override
  String get aiServicesTurnedOn =>
      'AI services turned on. Your choice has been recorded.';

  @override
  String get aiServicesSyncPending =>
      'Saved on this device. It will be recorded on our servers as soon as you are online.';

  @override
  String get tpAddTicketType => 'Add ticket type';

  @override
  String get tpAdviceLarge =>
      'Many people expected: instant confirmation is recommended. Tickets are confirmed automatically, so you don\'t have to check every payment.';

  @override
  String get tpAdviceSmall =>
      'Small group: the simplest is a payment link — no setup, you confirm each payment with one tap.';

  @override
  String get tpAmountLabel => 'Amount';

  @override
  String get tpAttachReceipt => 'Attach receipt (optional)';

  @override
  String get tpAwaitingOrganizerInfo =>
      'You told the organizer you paid. Your ticket appears here as soon as they confirm.';

  @override
  String get tpBadgeBrazil => 'Recommended in Brazil';

  @override
  String get tpBadgeNoSetup => 'No setup';

  @override
  String get tpBadgeRecommended => 'Recommended';

  @override
  String get tpBankInstructionsLabel => 'Bank details and instructions';

  @override
  String tpBlockMinimum(String provider, String amount) {
    return '$provider needs at least $amount per ticket.';
  }

  @override
  String tpBlockMpCurrency(String currency) {
    return 'Mercado Pago only charges in $currency: change the price to $currency or use Stripe.';
  }

  @override
  String get tpBlockMpCurrencyUnknown =>
      'Mercado Pago only charges in your account\'s local currency. Use that currency or Stripe.';

  @override
  String get tpBlockNotConfigured => 'Not available yet.';

  @override
  String tpBlockNotConnected(String provider) {
    return 'Connect $provider to use it.';
  }

  @override
  String get tpBuyMoreTickets => 'Buy more tickets';

  @override
  String get tpBuyTickets => 'Buy tickets';

  @override
  String tpCanBuyMore(int count) {
    return 'You can buy $count more tickets';
  }

  @override
  String get tpCanBuyUnlimited => 'No limit per person';

  @override
  String get tpCancelOrder => 'Cancel';

  @override
  String get tpCashInstructionsLabel =>
      'Where and when to pay in cash (optional)';

  @override
  String get tpChooseHowToGetPaid =>
      'Choose how buyers pay for this paid listing.';

  @override
  String get tpClose => 'Close';

  @override
  String get tpCodeHint =>
      'Put this code in the payment description so the organizer can find your payment.';

  @override
  String get tpCodeLabel => 'Payment code';

  @override
  String get tpConfirm => 'Confirm';

  @override
  String tpConfirmSelected(int count) {
    return 'Confirm selected ($count)';
  }

  @override
  String tpConfirmedCount(int count) {
    return '$count payments confirmed';
  }

  @override
  String tpConnectProvider(String provider) {
    return 'Connect $provider';
  }

  @override
  String get tpConsentGuideInstant =>
      'You pay inside the app with a secure checkout. Your ticket and QR appear as soon as the payment is confirmed. Refunds are made by the organizer.';

  @override
  String get tpConsentGuideManual =>
      'You pay the host directly with their payment method and a code. GreenGo does not verify this payment: the host confirms it, then your QR appears.';

  @override
  String get tpContinueSetup => 'Continue setup';

  @override
  String tpContinueToPay(String amount) {
    return 'Continue · $amount';
  }

  @override
  String get tpCopied => 'Copied';

  @override
  String get tpCopy => 'Copy';

  @override
  String get tpEditTicketType => 'Edit ticket type';

  @override
  String get tpErrAlreadyHasTicket => 'You already have a ticket for this.';

  @override
  String get tpErrEnded => 'Sales have ended.';

  @override
  String get tpErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get tpErrLimit => 'You reached the ticket limit per person.';

  @override
  String get tpErrMinimum =>
      'The price is below the payment provider\'s minimum.';

  @override
  String get tpErrNotAllowed => 'You can\'t do this.';

  @override
  String get tpErrNotOnSale =>
      'Tickets are not on sale yet: the organizer hasn\'t finished the payment setup.';

  @override
  String get tpErrOwnListing => 'You can\'t buy tickets for your own listing.';

  @override
  String get tpErrProvider =>
      'The payment provider is not responding. Try again in a moment.';

  @override
  String get tpErrSoldOut => 'Sold out — not enough places left.';

  @override
  String get tpFree => 'Free';

  @override
  String get tpGetPaidIntro =>
      'Money goes directly to your own account. GreenGo takes no fee on ticket sales.';

  @override
  String get tpGetPaidManualInfo =>
      'No setup: pick one of your Profile > Payment methods (or cash / bank transfer) in the event or experience, and confirm each payment yourself.';

  @override
  String get tpGetPaidSubtitle =>
      'Payment methods, Stripe and Mercado Pago, payments to confirm';

  @override
  String get tpGetPaidTitle => 'Get paid';

  @override
  String tpGroupOf(int count) {
    return 'Group of $count';
  }

  @override
  String tpGroupPreview(String price, int size) {
    return '$price for a group of up to $size';
  }

  @override
  String get tpGroupPrice => 'Price per group';

  @override
  String tpHoldCountdown(String time) {
    return 'Your place is held for $time';
  }

  @override
  String get tpInstantOptional => 'Instant confirmation (optional)';

  @override
  String get tpInstantSubtitle =>
      'Buyers pay in the app; tickets are confirmed automatically.';

  @override
  String get tpInstantTitle => 'Instant confirmation';

  @override
  String get tpIvePaid => 'I\'ve paid';

  @override
  String get tpLegacyPaymentPrompt =>
      'This listing used an old payment method. Choose how guests pay so you can keep selling.';

  @override
  String get tpManualAddMethodsHint =>
      'Add your Pix, PayPal… in Profile > Payment methods to see them here.';

  @override
  String get tpManualDisclaimer =>
      'GreenGo does not verify these payments: the organizer is responsible for confirming them.';

  @override
  String tpManualLargeWarning(String count) {
    return 'With $count people you\'ll have to confirm each payment by hand.';
  }

  @override
  String get tpManualMethodLabel => 'Payment method';

  @override
  String get tpManualSubtitle =>
      'Your own payment method; you confirm each payment with one tap.';

  @override
  String get tpManualTitle => 'Payment link — you confirm';

  @override
  String get tpMaxGroupBookingsPerUser => 'Max group bookings per person';

  @override
  String get tpMaxTicketsPerUser => 'Max tickets per person';

  @override
  String get tpMethodBankTransfer => 'Bank transfer';

  @override
  String get tpMethodCash => 'Cash (before the event)';

  @override
  String tpMpCurrencyInfo(String currency) {
    return 'Charges in $currency';
  }

  @override
  String get tpMpDescription =>
      'Pix, cards and Mercado Pago balance. Buyers don\'t need a Mercado Pago account.';

  @override
  String get tpMyPurchases => 'My purchases';

  @override
  String get tpNoFeeNote =>
      'GreenGo takes no fee: the money goes straight to you.';

  @override
  String get tpNoLimitHint => 'Empty = no limit';

  @override
  String get tpNoPurchases => 'No purchases yet.';

  @override
  String get tpNotOnSaleYet => 'Not on sale yet';

  @override
  String get tpOpenPaymentLink => 'Open payment link';

  @override
  String get tpOpenProviderSettings => 'Update account details';

  @override
  String get tpOrderAwaitingConfirmation =>
      'Waiting for the organizer to confirm your payment…';

  @override
  String get tpOrderCancelled => 'Order cancelled';

  @override
  String get tpOrderClosedInfo =>
      'This order is closed. You can start a new purchase from the event or experience.';

  @override
  String get tpOrderDisputed => 'Payment disputed — ticket not valid';

  @override
  String get tpOrderExpired => 'Reservation expired';

  @override
  String get tpOrderFailed => 'Payment failed';

  @override
  String get tpOrderPaid => 'Paid';

  @override
  String get tpOrderPendingPayment => 'Waiting for your payment';

  @override
  String get tpOrderRefunded => 'Refunded — ticket no longer valid';

  @override
  String get tpOrderRejected => 'The organizer did not confirm your payment';

  @override
  String get tpOrderTitle => 'Your tickets';

  @override
  String get tpOrderWaitingProvider => 'Waiting for payment confirmation…';

  @override
  String get tpPayAgain => 'Pay again';

  @override
  String get tpPayInApp => 'Pay in the app';

  @override
  String get tpPayInAppInfo =>
      'Pay in the app once the host accepts; your QR appears after the payment is confirmed.';

  @override
  String get tpPayNow => 'Pay now';

  @override
  String tpPayWith(String method) {
    return 'Pay with $method';
  }

  @override
  String get tpPaymentConfirmed => 'Payment confirmed — your tickets are ready';

  @override
  String get tpPerGroup => 'Per group';

  @override
  String get tpPerGroupInfo =>
      'One fixed price for a group (e.g. a private tour), whatever the group size up to the maximum.';

  @override
  String get tpPerPerson => 'Per person';

  @override
  String get tpPerPersonInfo =>
      'Each person pays the price; one ticket per person.';

  @override
  String get tpPixHint =>
      'Paid with Pix? Confirmation usually takes a few seconds.';

  @override
  String get tpReceiptAttached => 'Receipt attached';

  @override
  String get tpReconnectBanner =>
      'Connect Mercado Pago / Stripe to sell tickets with automatic confirmation. Pasted Stripe or Mercado Pago links can\'t be used for tickets.';

  @override
  String get tpRefresh => 'Refresh';

  @override
  String get tpReject => 'Not received';

  @override
  String get tpRejectReason => 'Reason (shown to the buyer)';

  @override
  String get tpRejectTitle => 'Payment not received?';

  @override
  String get tpSalesEnd => 'Sales end';

  @override
  String get tpSalesStart => 'Sales start';

  @override
  String get tpSave => 'Save';

  @override
  String get tpScanNotPaid => 'Not paid — no valid ticket';

  @override
  String get tpScanTicketNotValid => 'Ticket refunded or cancelled — not valid';

  @override
  String get tpSelectorTitle => 'How do guests pay?';

  @override
  String get tpShareTicket => 'Share this ticket';

  @override
  String tpShareTicketText(String title, int index, int total) {
    return 'Ticket $index/$total for $title on GreenGo. Show this QR at the entrance (valid once).';
  }

  @override
  String get tpStatusNotConnected => 'Not connected';

  @override
  String get tpStatusPending => 'Pending verification';

  @override
  String get tpStatusReady => 'Ready';

  @override
  String get tpStatusReconnect => 'Reconnect needed';

  @override
  String get tpStopSelling => 'Stop selling';

  @override
  String get tpStripeDescription =>
      'Cards, Apple Pay and Google Pay worldwide. Buyers don\'t need an account.';

  @override
  String tpTicketIndex(int index, int total) {
    return 'Ticket $index of $total';
  }

  @override
  String get tpTicketInvalid => 'This ticket is no longer valid.';

  @override
  String get tpTicketTypes => 'Ticket types';

  @override
  String get tpTicketTypesEmpty =>
      'No ticket types: the event price is the only ticket. Add types for VIP, early bird and more.';

  @override
  String get tpTicketUsed => 'Already used at the entrance';

  @override
  String tpTicketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get tpTiredOfConfirming =>
      'Tired of confirming? Connect Mercado Pago or Stripe for automatic confirmation.';

  @override
  String get tpToConfirmEmpty => 'No payments waiting for you.';

  @override
  String get tpToConfirmInfo =>
      'Check your own account for the amount and the GG- code before confirming. Confirming issues the tickets.';

  @override
  String get tpToConfirmTitle => 'Payments to confirm';

  @override
  String get tpTotal => 'Total';

  @override
  String get tpTypeEnded => 'Sales ended';

  @override
  String get tpTypeHasSalesWarning =>
      'Tickets of this type were already sold: they keep their price and type.';

  @override
  String get tpTypeHidden => 'Hidden';

  @override
  String get tpTypeMaxPerUser => 'Max per person';

  @override
  String get tpTypeName => 'Name (e.g. VIP)';

  @override
  String get tpTypeNotStarted => 'Sales haven\'t started yet';

  @override
  String tpTypeOnlyLeft(int count) {
    return 'Only $count left';
  }

  @override
  String get tpTypePerks => 'Description / perks';

  @override
  String get tpTypePrice => 'Price';

  @override
  String get tpTypeQuantity => 'Quantity (empty = event capacity)';

  @override
  String get tpTypeSelling => 'On sale';

  @override
  String tpTypeSold(int sold, String total) {
    return '$sold/$total sold';
  }

  @override
  String get tpTypeSoldOut => 'Sold out';

  @override
  String get tpTypeUnavailable => 'Not on sale';

  @override
  String get tpViewPayment => 'View payment';

  @override
  String get tpViewReceipt => 'Receipt';

  @override
  String get tpViewTickets => 'View tickets';

  @override
  String get mtAddTime => 'Add time';

  @override
  String get mtAdvanced => 'Advanced';

  @override
  String get mtApplyAll => 'Apply to all selected days';

  @override
  String get mtAvailableFrom => 'Available from';

  @override
  String get mtAvailableUntil => 'Until';

  @override
  String get mtBreak => 'Break between sessions';

  @override
  String get mtBulkCloseRange => 'Close a date range (vacation)';

  @override
  String get mtBulkHint => 'Changes are saved when you tap Save.';

  @override
  String get mtBulkRemoveTime => 'Remove a time from every chosen weekday';

  @override
  String get mtBulkTitle => 'Quick changes';

  @override
  String get mtCalendarTitle => 'Calendar';

  @override
  String get mtCapacity => 'Places per time';

  @override
  String get mtCloseDay => 'Closed this day';

  @override
  String get mtClosed => 'Closed';

  @override
  String mtConfirmBody(int count) {
    return '$count booked times would be removed. Those bookings will be cancelled, the guests notified and refunded.';
  }

  @override
  String get mtConfirmCancelBookings => 'Cancel those bookings';

  @override
  String get mtConfirmTitle => 'Some times are booked';

  @override
  String get mtCopyToMonth => 'Copy to the whole month';

  @override
  String mtCopyToWeekdays(String weekday) {
    return 'Copy to every $weekday this month';
  }

  @override
  String get mtDateFrom => 'From date';

  @override
  String get mtDateTo => 'Until date';

  @override
  String get mtDaysOfWeek => 'Days of the week';

  @override
  String get mtDone => 'Done';

  @override
  String get mtDuration => 'Duration';

  @override
  String get mtErrOverlap =>
      'Times would overlap: \"start every\" must be at least the duration.';

  @override
  String get mtErrRules => 'Check the schedule settings.';

  @override
  String get mtErrTimeExists => 'That time is already on the list.';

  @override
  String get mtErrTimeFit => 'The session would end after midnight.';

  @override
  String get mtErrTimeOverlaps => 'It overlaps another time of that day.';

  @override
  String get mtErrWeekdays => 'Choose at least one day of the week.';

  @override
  String get mtErrWindow => '\"Until\" must be after \"Available from\".';

  @override
  String mtHours(int h) {
    return '$h h';
  }

  @override
  String mtHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get mtLegendChanged => 'changed day';

  @override
  String get mtLegendSpecialPrice => 'special price';

  @override
  String get mtLegendWeekendPrice => 'weekend price';

  @override
  String mtMinutes(int m) {
    return '$m min';
  }

  @override
  String get mtNextMonth => 'Next month';

  @override
  String get mtNoBreak => 'No break';

  @override
  String get mtNoEnd => 'No end date';

  @override
  String get mtPrevMonth => 'Previous month';

  @override
  String get mtPreview => 'Times each selected day';

  @override
  String get mtRemoveTime => 'Remove time';

  @override
  String get mtResetDay => 'Reset to default';

  @override
  String get mtSaved => 'Schedule saved';

  @override
  String mtSavedCancelled(int count) {
    return 'Schedule saved — $count bookings cancelled and refunded';
  }

  @override
  String get mtSetupTitle => 'Your times';

  @override
  String get mtSpecialPrice => 'Special price for this day';

  @override
  String get mtSpecialPriceHint => 'Empty = normal price';

  @override
  String get mtStartEvery => 'Start every';

  @override
  String get mtStartEveryAuto => 'Automatic (duration + break)';

  @override
  String get mtTime => 'Time';

  @override
  String get mtTimezone => 'Time zone';

  @override
  String get mtTitle => 'Manage times';

  @override
  String get mtWeekendPrice => 'Weekend price';

  @override
  String get mtWeekendPriceInfo =>
      'Applies on the days you pick; a special price for a single day is set in Manage times.';

  @override
  String get mtWeekendPriceToggle => 'Different price on weekends';

  @override
  String rtGroupsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count group slots left',
      one: '1 group slot left',
    );
    return '$_temp0';
  }

  @override
  String rtSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats left',
      one: '1 seat left',
    );
    return '$_temp0';
  }

  @override
  String get rtSpecialPrice => 'special price';

  @override
  String rtTimesIn(String zone) {
    return 'Times in the host\'s time zone ($zone)';
  }

  @override
  String get rtWeekendPrice => 'weekend price';

  @override
  String rtYourTime(String time) {
    return 'Your time: $time';
  }

  @override
  String get tpReorder => 'Drag to reorder';

  @override
  String tpSalesRow(int sold, int held, String left) {
    return '$sold sold · $held reserved · $left left';
  }

  @override
  String get tpSalesSummary => 'Sales by ticket type';

  @override
  String tpSalesTotal(int sold, int held) {
    return 'Total: $sold sold, $held reserved';
  }

  @override
  String get wzAllGood => 'Everything is ready.';

  @override
  String get wzAvailability => 'Availability';

  @override
  String get wzBack => 'Back';

  @override
  String get wzEdit => 'Edit';

  @override
  String get wzErrCapacity => 'Enter how many people can come.';

  @override
  String get wzErrDates => 'The end must be after the start.';

  @override
  String get wzErrDescription => 'Add a description.';

  @override
  String get wzErrLocation => 'Add the place.';

  @override
  String get wzErrTitle => 'Add a title.';

  @override
  String get wzEventBasics => 'Basics';

  @override
  String get wzExpBasics => 'Basics';

  @override
  String get wzFineTuneLater =>
      'You can fine-tune single days later in Manage times.';

  @override
  String get wzFix => 'Fix';

  @override
  String get wzFormatPrice => 'Format & price';

  @override
  String get wzLocation => 'Location';

  @override
  String get wzNext => 'Next';

  @override
  String get wzOverviewTitle => 'What do you want to change?';

  @override
  String get wzPayment => 'Payment';

  @override
  String get wzPreviewTitle => 'How buyers will see it';

  @override
  String get wzRecurringInfo =>
      'Guests pick one of the generated times. Turn off to keep using individual dates.';

  @override
  String get wzRecurringToggle => 'Repeat every week';

  @override
  String get wzResume => 'Resume';

  @override
  String get wzResumeBody =>
      'You have an unfinished draft on this device. Continue where you left off?';

  @override
  String get wzResumeTitle => 'Continue your draft?';

  @override
  String get wzReview => 'Review & publish';

  @override
  String get wzStartOver => 'Start over';

  @override
  String wzStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get wzTickets => 'Tickets';

  @override
  String get wzWarnManualLarge =>
      'Many people with manual payments: you will confirm each one. Consider instant confirmation.';

  @override
  String get wzWarnNoAvailability =>
      'No availability yet: add dates after saving, or turn on \"Repeat every week\".';

  @override
  String get wzWarnNoPhoto =>
      'No cover photo yet: listings with a photo get more bookings.';

  @override
  String get wzWhenWhere => 'When & where';

  @override
  String get tpPaymentMethodsSectionHint =>
      'Your own methods (Pix, PayPal, …): people can pay you directly, and you can use them for tickets you confirm by hand.';

  @override
  String get tpPaymentMethodsSaveFailed =>
      'Couldn\'t save your payment methods. Try again.';

  @override
  String wzNextTo(String step) {
    return 'Next: $step';
  }

  @override
  String get wzSteps => 'Steps';

  @override
  String get wzAllStepsTitle => 'All steps';

  @override
  String get wzStepsHint =>
      'Tap any step to go there. You can come back at any time.';

  @override
  String get wzStatusCurrent => 'Current step';

  @override
  String get wzStatusDone => 'Done';

  @override
  String get wzStatusAttention => 'Needs attention';

  @override
  String get wzStatusTodo => 'Not started';

  @override
  String wzStepSemantics(int step, int total, String title, String status) {
    return 'Step $step of $total: $title. $status';
  }

  @override
  String get wzPaymentAppearsNote =>
      'The Payment step appears when the price is above 0.';

  @override
  String get wzPublishBlocked =>
      'Complete the required items above to publish.';

  @override
  String get wzEvBasicsDesc =>
      'Give your event a clear title and tell people what to expect. A cover photo helps it stand out.';

  @override
  String get wzEvBasicsReq => 'Required: title and description.';

  @override
  String get wzEvWhereDesc =>
      'Say where it happens (type the address or pick it on the map) and when it starts and ends.';

  @override
  String get wzEvWhereReq =>
      'Required: the place, and an end time after the start.';

  @override
  String get wzEvTicketsDesc =>
      'Choose if the event is free or paid, set the price and how many people can join.';

  @override
  String get wzEvTicketsReq =>
      'Required: how many people can come (or unlimited) and, for paid events, a price.';

  @override
  String get wzEvPaymentDesc =>
      'Choose how attendees pay you for their tickets.';

  @override
  String get wzEvPaymentReq => 'Required: a way to get paid.';

  @override
  String get wzEvReviewDesc =>
      'Check how your event will look. Fix anything marked in red, then publish, save a draft or schedule it.';

  @override
  String get wzExBasicsDesc =>
      'Name your experience, describe it, and add photos, the languages you speak and what\'s included.';

  @override
  String get wzExBasicsReq =>
      'Required: title, description, a main photo, at least one language and what\'s included.';

  @override
  String get wzExLocationDesc => 'Tell guests where to meet you.';

  @override
  String get wzExLocationReq => 'Required: the meeting place.';

  @override
  String get wzExFormatDesc =>
      'Set how long it lasts, the group size, and whether it\'s free or paid (per person or per group).';

  @override
  String get wzExFormatReq =>
      'Required: duration, group size and, for paid experiences, a price.';

  @override
  String get wzExAvailDesc =>
      'Choose when guests can book: a weekly repeating schedule, or single dates you add later.';

  @override
  String get wzExAvailReq => 'Optional: you can also add dates after saving.';

  @override
  String get wzExPaymentDesc => 'Choose how guests pay you.';

  @override
  String get wzExPaymentReq => 'Required: at least one way to get paid.';

  @override
  String get wzExReviewDesc =>
      'Check how guests will see it. Fix anything marked in red, then publish or save a draft.';

  @override
  String verificationOrMethod(String method) {
    return 'or $method';
  }

  @override
  String get safetyAcademyTitle => 'Safety Academy';

  @override
  String get safetyAcademyLearningModules => 'Learning Modules';

  @override
  String safetyAcademyModulesCompleted(int completed, int total) {
    return '$completed / $total modules completed';
  }

  @override
  String get safetyAcademyChampionTitle => 'Safety Champion';

  @override
  String get safetyAcademyChampionBody => 'You completed all safety modules!';

  @override
  String get safetyAcademyLessonCompletedToast => 'Lesson completed!';

  @override
  String get safetyAcademyNoLessons => 'No lessons available yet.';

  @override
  String safetyAcademyLessonsProgress(int completed, int total) {
    return '$completed / $total lessons';
  }

  @override
  String safetyAcademyLessonXpWithQuiz(int xp) {
    return '+$xp XP | Quiz';
  }

  @override
  String get safetyAcademyTakeQuiz => 'Take Quiz';

  @override
  String get safetyAcademyCompleteLesson => 'Complete Lesson';

  @override
  String get safetyAcademyCompleted => 'Completed';

  @override
  String safetyAcademyQuestionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String safetyAcademyCorrectCount(int count) {
    return '$count correct';
  }

  @override
  String get safetyAcademyNextQuestion => 'Next Question';

  @override
  String get safetyAcademySeeResults => 'See Results';

  @override
  String get safetyAcademyGreatJob => 'Great Job!';

  @override
  String get safetyAcademyKeepLearning => 'Keep Learning!';

  @override
  String safetyAcademyScoreSummary(int correct, int total) {
    return '$correct out of $total correct';
  }

  @override
  String safetyAcademyPassingScore(int score) {
    return 'Passing score: $score%';
  }

  @override
  String safetyAcademyCompleteLessonXp(int xp) {
    return 'Complete Lesson (+$xp XP)';
  }

  @override
  String get safetyAcademyReviewLesson => 'Review Lesson';

  @override
  String get safetyAcademyExitQuizTitle => 'Exit Quiz?';

  @override
  String get safetyAcademyExitQuizBody => 'Your progress will be lost.';

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
  String get countryNameAG => 'Antigua and Barbuda';

  @override
  String get countryNameAR => 'Argentina';

  @override
  String get countryNameAM => 'Armenia';

  @override
  String get countryNameAU => 'Australia';

  @override
  String get countryNameAT => 'Austria';

  @override
  String get countryNameAZ => 'Azerbaijan';

  @override
  String get countryNameBS => 'Bahamas';

  @override
  String get countryNameBH => 'Bahrain';

  @override
  String get countryNameBD => 'Bangladesh';

  @override
  String get countryNameBB => 'Barbados';

  @override
  String get countryNameBY => 'Belarus';

  @override
  String get countryNameBE => 'Belgium';

  @override
  String get countryNameBZ => 'Belize';

  @override
  String get countryNameBJ => 'Benin';

  @override
  String get countryNameBT => 'Bhutan';

  @override
  String get countryNameBO => 'Bolivia';

  @override
  String get countryNameBA => 'Bosnia and Herzegovina';

  @override
  String get countryNameBW => 'Botswana';

  @override
  String get countryNameBR => 'Brazil';

  @override
  String get countryNameBN => 'Brunei';

  @override
  String get countryNameBG => 'Bulgaria';

  @override
  String get countryNameBF => 'Burkina Faso';

  @override
  String get countryNameBI => 'Burundi';

  @override
  String get countryNameCV => 'Cabo Verde';

  @override
  String get countryNameKH => 'Cambodia';

  @override
  String get countryNameCM => 'Cameroon';

  @override
  String get countryNameCA => 'Canada';

  @override
  String get countryNameCF => 'Central African Republic';

  @override
  String get countryNameTD => 'Chad';

  @override
  String get countryNameCL => 'Chile';

  @override
  String get countryNameCN => 'China';

  @override
  String get countryNameCO => 'Colombia';

  @override
  String get countryNameKM => 'Comoros';

  @override
  String get countryNameCG => 'Congo';

  @override
  String get countryNameCD => 'DR Congo';

  @override
  String get countryNameCR => 'Costa Rica';

  @override
  String get countryNameHR => 'Croatia';

  @override
  String get countryNameCU => 'Cuba';

  @override
  String get countryNameCY => 'Cyprus';

  @override
  String get countryNameCZ => 'Czechia';

  @override
  String get countryNameDK => 'Denmark';

  @override
  String get countryNameDJ => 'Djibouti';

  @override
  String get countryNameDM => 'Dominica';

  @override
  String get countryNameDO => 'Dominican Republic';

  @override
  String get countryNameEC => 'Ecuador';

  @override
  String get countryNameEG => 'Egypt';

  @override
  String get countryNameSV => 'El Salvador';

  @override
  String get countryNameGQ => 'Equatorial Guinea';

  @override
  String get countryNameER => 'Eritrea';

  @override
  String get countryNameEE => 'Estonia';

  @override
  String get countryNameSZ => 'Eswatini';

  @override
  String get countryNameET => 'Ethiopia';

  @override
  String get countryNameFJ => 'Fiji';

  @override
  String get countryNameFI => 'Finland';

  @override
  String get countryNameFR => 'France';

  @override
  String get countryNameGA => 'Gabon';

  @override
  String get countryNameGM => 'Gambia';

  @override
  String get countryNameGE => 'Georgia';

  @override
  String get countryNameDE => 'Germany';

  @override
  String get countryNameGH => 'Ghana';

  @override
  String get countryNameGR => 'Greece';

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
  String get countryNameHU => 'Hungary';

  @override
  String get countryNameIS => 'Iceland';

  @override
  String get countryNameIN => 'India';

  @override
  String get countryNameID => 'Indonesia';

  @override
  String get countryNameIR => 'Iran';

  @override
  String get countryNameIQ => 'Iraq';

  @override
  String get countryNameIE => 'Ireland';

  @override
  String get countryNameIL => 'Israel';

  @override
  String get countryNameIT => 'Italy';

  @override
  String get countryNameCI => 'Ivory Coast';

  @override
  String get countryNameJM => 'Jamaica';

  @override
  String get countryNameJP => 'Japan';

  @override
  String get countryNameJO => 'Jordan';

  @override
  String get countryNameKZ => 'Kazakhstan';

  @override
  String get countryNameKE => 'Kenya';

  @override
  String get countryNameKI => 'Kiribati';

  @override
  String get countryNameXK => 'Kosovo';

  @override
  String get countryNameKW => 'Kuwait';

  @override
  String get countryNameKG => 'Kyrgyzstan';

  @override
  String get countryNameLA => 'Laos';

  @override
  String get countryNameLV => 'Latvia';

  @override
  String get countryNameLB => 'Lebanon';

  @override
  String get countryNameLS => 'Lesotho';

  @override
  String get countryNameLR => 'Liberia';

  @override
  String get countryNameLY => 'Libya';

  @override
  String get countryNameLI => 'Liechtenstein';

  @override
  String get countryNameLT => 'Lithuania';

  @override
  String get countryNameLU => 'Luxembourg';

  @override
  String get countryNameMG => 'Madagascar';

  @override
  String get countryNameMW => 'Malawi';

  @override
  String get countryNameMY => 'Malaysia';

  @override
  String get countryNameMV => 'Maldives';

  @override
  String get countryNameML => 'Mali';

  @override
  String get countryNameMT => 'Malta';

  @override
  String get countryNameMH => 'Marshall Islands';

  @override
  String get countryNameMR => 'Mauritania';

  @override
  String get countryNameMU => 'Mauritius';

  @override
  String get countryNameMX => 'Mexico';

  @override
  String get countryNameFM => 'Micronesia';

  @override
  String get countryNameMD => 'Moldova';

  @override
  String get countryNameMC => 'Monaco';

  @override
  String get countryNameMN => 'Mongolia';

  @override
  String get countryNameME => 'Montenegro';

  @override
  String get countryNameMA => 'Morocco';

  @override
  String get countryNameMZ => 'Mozambique';

  @override
  String get countryNameMM => 'Myanmar';

  @override
  String get countryNameNA => 'Namibia';

  @override
  String get countryNameNR => 'Nauru';

  @override
  String get countryNameNP => 'Nepal';

  @override
  String get countryNameNL => 'Netherlands';

  @override
  String get countryNameNZ => 'New Zealand';

  @override
  String get countryNameNI => 'Nicaragua';

  @override
  String get countryNameNE => 'Niger';

  @override
  String get countryNameNG => 'Nigeria';

  @override
  String get countryNameKP => 'North Korea';

  @override
  String get countryNameMK => 'North Macedonia';

  @override
  String get countryNameNO => 'Norway';

  @override
  String get countryNameOM => 'Oman';

  @override
  String get countryNamePK => 'Pakistan';

  @override
  String get countryNamePW => 'Palau';

  @override
  String get countryNamePS => 'Palestine';

  @override
  String get countryNamePA => 'Panama';

  @override
  String get countryNamePG => 'Papua New Guinea';

  @override
  String get countryNamePY => 'Paraguay';

  @override
  String get countryNamePE => 'Peru';

  @override
  String get countryNamePH => 'Philippines';

  @override
  String get countryNamePL => 'Poland';

  @override
  String get countryNamePT => 'Portugal';

  @override
  String get countryNameQA => 'Qatar';

  @override
  String get countryNameRO => 'Romania';

  @override
  String get countryNameRU => 'Russia';

  @override
  String get countryNameRW => 'Rwanda';

  @override
  String get countryNameKN => 'Saint Kitts and Nevis';

  @override
  String get countryNameLC => 'Saint Lucia';

  @override
  String get countryNameVC => 'Saint Vincent and the Grenadines';

  @override
  String get countryNameWS => 'Samoa';

  @override
  String get countryNameSM => 'San Marino';

  @override
  String get countryNameST => 'Sao Tome and Principe';

  @override
  String get countryNameSA => 'Saudi Arabia';

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
  String get countryNameSK => 'Slovakia';

  @override
  String get countryNameSI => 'Slovenia';

  @override
  String get countryNameSB => 'Solomon Islands';

  @override
  String get countryNameSO => 'Somalia';

  @override
  String get countryNameZA => 'South Africa';

  @override
  String get countryNameKR => 'South Korea';

  @override
  String get countryNameSS => 'South Sudan';

  @override
  String get countryNameES => 'Spain';

  @override
  String get countryNameLK => 'Sri Lanka';

  @override
  String get countryNameSD => 'Sudan';

  @override
  String get countryNameSR => 'Suriname';

  @override
  String get countryNameSE => 'Sweden';

  @override
  String get countryNameCH => 'Switzerland';

  @override
  String get countryNameSY => 'Syria';

  @override
  String get countryNameTW => 'Taiwan';

  @override
  String get countryNameTJ => 'Tajikistan';

  @override
  String get countryNameTZ => 'Tanzania';

  @override
  String get countryNameTH => 'Thailand';

  @override
  String get countryNameTL => 'Timor-Leste';

  @override
  String get countryNameTG => 'Togo';

  @override
  String get countryNameTO => 'Tonga';

  @override
  String get countryNameTT => 'Trinidad and Tobago';

  @override
  String get countryNameTN => 'Tunisia';

  @override
  String get countryNameTR => 'Turkey';

  @override
  String get countryNameTM => 'Turkmenistan';

  @override
  String get countryNameTV => 'Tuvalu';

  @override
  String get countryNameUG => 'Uganda';

  @override
  String get countryNameUA => 'Ukraine';

  @override
  String get countryNameAE => 'United Arab Emirates';

  @override
  String get countryNameGB => 'United Kingdom';

  @override
  String get countryNameUS => 'United States';

  @override
  String get countryNameUY => 'Uruguay';

  @override
  String get countryNameUZ => 'Uzbekistan';

  @override
  String get countryNameVU => 'Vanuatu';

  @override
  String get countryNameVA => 'Vatican City';

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
  String get countryNamePR => 'Puerto Rico';

  @override
  String get spotsCatRestaurant => 'Restaurant';

  @override
  String get spotsCatCafe => 'Café';

  @override
  String get spotsCatCulturalSite => 'Cultural site';

  @override
  String get spotsCatMarket => 'Market';

  @override
  String get spotsCatViewpoint => 'Viewpoint';

  @override
  String spotsCreatedNamed(String name) {
    return 'Spot \"$name\" created!';
  }

  @override
  String get spotsEmptyHint =>
      'No cultural spots in this city yet. Be the first to add one!';

  @override
  String spotsEmptyCategoryHint(String category) {
    return 'No spots in \"$category\" in this city yet. Be the first to add one!';
  }

  @override
  String spotsReviewCountParen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count reviews)',
      one: '(1 review)',
    );
    return '$_temp0';
  }

  @override
  String get uexpLangHebrew => 'Hebrew';

  @override
  String get uexpLangThai => 'Thai';

  @override
  String get uexpLangVietnamese => 'Vietnamese';

  @override
  String get safetyAcademyModCommunicationTitle => 'Communication Skills';

  @override
  String get safetyAcademyModCommunicationDesc =>
      'Build healthy communication habits including consent, boundaries, and active listening.';

  @override
  String get safetyAcademyLsnActiveListeningTitle => 'Active Listening';

  @override
  String get safetyAcademyLsnActiveListeningS0 =>
      'Active listening is the foundation of meaningful connection. It goes beyond hearing words -- it is about fully engaging with your conversation partner and making them feel valued.';

  @override
  String get safetyAcademyLsnActiveListeningS1 =>
      'Ask follow-up questions based on what they said, not just what you want to talk about. This shows genuine interest.';

  @override
  String get safetyAcademyLsnActiveListeningS2 => 'Active Listening Techniques';

  @override
  String get safetyAcademyLsnActiveListeningS2I0 =>
      'Give your full attention (put your phone away)';

  @override
  String get safetyAcademyLsnActiveListeningS2I1 =>
      'Use verbal cues (\"I see\", \"That\'s interesting\")';

  @override
  String get safetyAcademyLsnActiveListeningS2I2 =>
      'Reflect back what you heard (\"So you\'re saying...\")';

  @override
  String get safetyAcademyLsnActiveListeningS2I3 =>
      'Ask open-ended follow-up questions';

  @override
  String get safetyAcademyLsnActiveListeningS2I4 =>
      'Avoid interrupting or planning your response while they talk';

  @override
  String get safetyAcademyLsnActiveListeningS3 =>
      'In text conversations, active listening means reading messages carefully, responding to what was actually said, and asking thoughtful questions rather than redirecting every topic to yourself.';

  @override
  String get safetyAcademyLsnActiveListeningQ0 =>
      'Your date shares a story about their recent trip. What is the best active listening response?';

  @override
  String get safetyAcademyLsnActiveListeningQ0O0 =>
      '\"Cool. So anyway, I went to...\"';

  @override
  String get safetyAcademyLsnActiveListeningQ0O1 =>
      '\"That sounds amazing! What was the highlight of the trip?\"';

  @override
  String get safetyAcademyLsnActiveListeningQ0O2 =>
      '\"I have been there too, let me tell you about it.\"';

  @override
  String get safetyAcademyLsnActiveListeningQ0O3 => '\"Nice.\"';

  @override
  String get safetyAcademyLsnActiveListeningQ0Exp =>
      'Asking a follow-up question about their experience shows genuine interest and keeps the conversation flowing.';

  @override
  String get safetyAcademyLsnActiveListeningQ1 =>
      'What should you avoid during active listening?';

  @override
  String get safetyAcademyLsnActiveListeningQ1O0 => 'Making eye contact';

  @override
  String get safetyAcademyLsnActiveListeningQ1O1 =>
      'Planning your response while the other person is still talking';

  @override
  String get safetyAcademyLsnActiveListeningQ1O2 => 'Nodding occasionally';

  @override
  String get safetyAcademyLsnActiveListeningQ1O3 =>
      'Asking follow-up questions';

  @override
  String get safetyAcademyLsnActiveListeningQ1Exp =>
      'If you are planning your next response, you are not truly listening. Focus on understanding first, then respond.';

  @override
  String get safetyAcademyLsnBoundariesTitle => 'Setting Boundaries';

  @override
  String get safetyAcademyLsnBoundariesS0 =>
      'Boundaries are the guidelines you set for how you want to be treated. They are essential for healthy relationships and protect your emotional, physical, and mental well-being.';

  @override
  String get safetyAcademyLsnBoundariesS1 =>
      'State boundaries clearly and early. For example: \"I prefer to get to know someone through chat before meeting in person\" or \"I am not comfortable sharing photos right now.\"';

  @override
  String get safetyAcademyLsnBoundariesS2 =>
      'If someone repeatedly pushes against a boundary you have set, this is a serious red flag regardless of their excuses.';

  @override
  String get safetyAcademyLsnBoundariesS3 => 'Healthy Boundary Examples';

  @override
  String get safetyAcademyLsnBoundariesS3I0 =>
      'Deciding when you are ready to share your phone number';

  @override
  String get safetyAcademyLsnBoundariesS3I1 =>
      'Setting limits on how late someone can message you';

  @override
  String get safetyAcademyLsnBoundariesS3I2 =>
      'Being clear about physical comfort levels on dates';

  @override
  String get safetyAcademyLsnBoundariesS3I3 =>
      'Saying no to plans that feel rushed or uncomfortable';

  @override
  String get safetyAcademyLsnBoundariesS3I4 =>
      'Taking breaks from conversation when you need space';

  @override
  String get safetyAcademyLsnBoundariesS4 =>
      'Remember: setting boundaries is not being difficult. It is self-respect. A partner who values you will appreciate and honor your boundaries.';

  @override
  String get safetyAcademyLsnBoundariesQ0 =>
      'You tell your match you are not comfortable sharing your number yet, and they keep asking. What does this indicate?';

  @override
  String get safetyAcademyLsnBoundariesQ0O0 =>
      'They are really interested in you';

  @override
  String get safetyAcademyLsnBoundariesQ0O1 =>
      'They are just eager to move the conversation';

  @override
  String get safetyAcademyLsnBoundariesQ0O2 =>
      'They are not respecting your stated boundary';

  @override
  String get safetyAcademyLsnBoundariesQ0O3 => 'It is normal dating behavior';

  @override
  String get safetyAcademyLsnBoundariesQ0Exp =>
      'Repeatedly pushing against a clearly stated boundary is disrespectful and a red flag, regardless of the reason given.';

  @override
  String get safetyAcademyLsnBoundariesQ1 =>
      'When is the best time to communicate a boundary?';

  @override
  String get safetyAcademyLsnBoundariesQ1O0 =>
      'After it has been crossed multiple times';

  @override
  String get safetyAcademyLsnBoundariesQ1O1 =>
      'Clearly and early, before it becomes an issue';

  @override
  String get safetyAcademyLsnBoundariesQ1O2 => 'Only if the other person asks';

  @override
  String get safetyAcademyLsnBoundariesQ1O3 =>
      'Boundaries are not necessary in dating';

  @override
  String get safetyAcademyLsnBoundariesQ1Exp =>
      'Stating boundaries early and clearly prevents misunderstandings and sets the tone for mutual respect.';

  @override
  String get safetyAcademyLsnConsentTitle => 'Understanding Consent';

  @override
  String get safetyAcademyLsnConsentS0 =>
      'Consent is a clear, enthusiastic, and ongoing agreement. It applies to every aspect of dating -- from sharing personal information to physical intimacy.';

  @override
  String get safetyAcademyLsnConsentS1 =>
      'Consent is not just about physical contact. Sharing someone\'s photos, forwarding their messages, or sharing their personal details without permission also violates consent.';

  @override
  String get safetyAcademyLsnConsentS2 => 'Key Principles of Consent';

  @override
  String get safetyAcademyLsnConsentS2I0 =>
      'Freely given -- not pressured, coerced, or manipulated';

  @override
  String get safetyAcademyLsnConsentS2I1 =>
      'Reversible -- anyone can change their mind at any time';

  @override
  String get safetyAcademyLsnConsentS2I2 =>
      'Informed -- based on honest, complete information';

  @override
  String get safetyAcademyLsnConsentS2I3 =>
      'Enthusiastic -- look for active \"yes\", not just absence of \"no\"';

  @override
  String get safetyAcademyLsnConsentS2I4 =>
      'Specific -- consent to one thing does not mean consent to everything';

  @override
  String get safetyAcademyLsnConsentS3 =>
      'Silence or a lack of \"no\" does not equal consent. Always look for clear, positive agreement.';

  @override
  String get safetyAcademyLsnConsentS4 =>
      'Asking for consent is not awkward -- it shows maturity and respect. Simple check-ins like \"Are you comfortable with this?\" or \"Would you like to...?\" make a big difference.';

  @override
  String get safetyAcademyLsnConsentQ0 =>
      'Which statement best describes consent?';

  @override
  String get safetyAcademyLsnConsentQ0O0 => 'The absence of \"no\"';

  @override
  String get safetyAcademyLsnConsentQ0O1 =>
      'A clear, enthusiastic, and ongoing agreement';

  @override
  String get safetyAcademyLsnConsentQ0O2 =>
      'Something only needed for physical contact';

  @override
  String get safetyAcademyLsnConsentQ0O3 =>
      'Agreement given once that covers all future interactions';

  @override
  String get safetyAcademyLsnConsentQ0Exp =>
      'Consent must be clear, enthusiastic, ongoing, and can be revoked at any time. It applies to all interactions.';

  @override
  String get safetyAcademyLsnConsentQ1 =>
      'Your date agreed to come to your place but seems uncomfortable after arriving. What should you do?';

  @override
  String get safetyAcademyLsnConsentQ1O0 =>
      'They agreed already, so continue as planned';

  @override
  String get safetyAcademyLsnConsentQ1O1 =>
      'Check in with them and offer to go somewhere else';

  @override
  String get safetyAcademyLsnConsentQ1O2 =>
      'Ignore the discomfort -- it is probably nerves';

  @override
  String get safetyAcademyLsnConsentQ1O3 =>
      'Tell them they should not have agreed if they did not want to come';

  @override
  String get safetyAcademyLsnConsentQ1Exp =>
      'Consent is reversible. If someone seems uncomfortable, check in with them. Their well-being is more important than plans.';

  @override
  String get safetyAcademyModCulturalSensitivityTitle => 'Cultural Sensitivity';

  @override
  String get safetyAcademyModCulturalSensitivityDesc =>
      'Navigate cross-cultural dating with respect, curiosity, and awareness.';

  @override
  String get safetyAcademyLsnCulturalDosTitle => 'Cross-Cultural Dating Do\'s';

  @override
  String get safetyAcademyLsnCulturalDosS0 =>
      'Dating someone from a different cultural background can be one of the most enriching experiences. Approach it with genuine curiosity, respect, and a willingness to learn.';

  @override
  String get safetyAcademyLsnCulturalDosS1 =>
      'Ask open-ended questions about their culture with genuine curiosity, not as a quiz. \"What traditions are important to your family?\" is much better than \"Do your people really do X?\"';

  @override
  String get safetyAcademyLsnCulturalDosS2 => 'Do\'s for Cross-Cultural Dating';

  @override
  String get safetyAcademyLsnCulturalDosS2I0 =>
      'Research basic cultural customs before a date';

  @override
  String get safetyAcademyLsnCulturalDosS2I1 =>
      'Show genuine interest in their background and traditions';

  @override
  String get safetyAcademyLsnCulturalDosS2I2 =>
      'Be open to trying new foods, activities, and experiences';

  @override
  String get safetyAcademyLsnCulturalDosS2I3 =>
      'Respect family dynamics that may differ from yours';

  @override
  String get safetyAcademyLsnCulturalDosS2I4 =>
      'Learn a few words or phrases in their language';

  @override
  String get safetyAcademyLsnCulturalDosS2I5 =>
      'Ask how they prefer to be addressed or introduced';

  @override
  String get safetyAcademyLsnCulturalDosS3 =>
      'Remember that every person is an individual first. Cultural awareness is a starting point, but get to know the person beyond stereotypes.';

  @override
  String get safetyAcademyLsnCulturalDosQ0 =>
      'What is the best way to learn about your date\'s culture?';

  @override
  String get safetyAcademyLsnCulturalDosQ0O0 =>
      'Make assumptions based on what you have seen in movies';

  @override
  String get safetyAcademyLsnCulturalDosQ0O1 =>
      'Ask thoughtful, open-ended questions with genuine curiosity';

  @override
  String get safetyAcademyLsnCulturalDosQ0O2 =>
      'Quiz them on cultural facts you read online';

  @override
  String get safetyAcademyLsnCulturalDosQ0O3 =>
      'Avoid the topic entirely to prevent offense';

  @override
  String get safetyAcademyLsnCulturalDosQ0Exp =>
      'Genuine, respectful curiosity is the best approach. Let them share what is meaningful to them.';

  @override
  String get safetyAcademyLsnCulturalDosQ1 =>
      'Your date mentions a family tradition you do not understand. What should you do?';

  @override
  String get safetyAcademyLsnCulturalDosQ1O0 =>
      'Nod along and pretend you understand';

  @override
  String get safetyAcademyLsnCulturalDosQ1O1 =>
      'Ask them to explain more about it and why it matters';

  @override
  String get safetyAcademyLsnCulturalDosQ1O2 =>
      'Tell them your traditions are different';

  @override
  String get safetyAcademyLsnCulturalDosQ1O3 => 'Change the subject';

  @override
  String get safetyAcademyLsnCulturalDosQ1Exp =>
      'Asking them to share more shows respect and genuine interest in their world.';

  @override
  String get safetyAcademyLsnCulturalDontsTitle =>
      'Cross-Cultural Dating Don\'ts';

  @override
  String get safetyAcademyLsnCulturalDontsS0 =>
      'Well-intentioned but uninformed comments can feel hurtful or dismissive. Understanding common pitfalls helps you navigate cross-cultural dating with grace.';

  @override
  String get safetyAcademyLsnCulturalDontsS1 =>
      'Never reduce someone to their ethnicity or nationality. Comments like \"I\'ve always wanted to date a [nationality]\" or \"You\'re pretty for a [ethnicity]\" are hurtful, not complimentary.';

  @override
  String get safetyAcademyLsnCulturalDontsS2 =>
      'Don\'ts for Cross-Cultural Dating';

  @override
  String get safetyAcademyLsnCulturalDontsS2I0 =>
      'Do not fetishize or exoticize their culture or appearance';

  @override
  String get safetyAcademyLsnCulturalDontsS2I1 =>
      'Do not assume they represent their entire culture';

  @override
  String get safetyAcademyLsnCulturalDontsS2I2 =>
      'Do not make jokes about their accent or language';

  @override
  String get safetyAcademyLsnCulturalDontsS2I3 =>
      'Do not pressure them to explain or defend cultural practices';

  @override
  String get safetyAcademyLsnCulturalDontsS2I4 =>
      'Do not compare them to stereotypes or media portrayals';

  @override
  String get safetyAcademyLsnCulturalDontsS2I5 =>
      'Do not dismiss cultural differences as unimportant';

  @override
  String get safetyAcademyLsnCulturalDontsS3 =>
      'If you make a cultural misstep, apologize sincerely, learn from it, and move on. Do not over-apologize to the point of making it about your feelings.';

  @override
  String get safetyAcademyLsnCulturalDontsQ0 =>
      'Which comment is culturally insensitive?';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O0 =>
      '\"I would love to try the food from your country.\"';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O1 =>
      '\"You are so exotic looking.\"';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O2 =>
      '\"What language do you speak at home?\"';

  @override
  String get safetyAcademyLsnCulturalDontsQ0O3 =>
      '\"Tell me about a holiday your family celebrates.\"';

  @override
  String get safetyAcademyLsnCulturalDontsQ0Exp =>
      'Calling someone \"exotic\" reduces them to their appearance and cultural background. It is objectifying, not complimentary.';

  @override
  String get safetyAcademyLsnCulturalDontsQ1 =>
      'You accidentally say something culturally insensitive. What is the best response?';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O0 => 'Pretend it did not happen';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O1 =>
      'Apologize sincerely, learn from it, and move on';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O2 =>
      'Explain that you did not mean it that way';

  @override
  String get safetyAcademyLsnCulturalDontsQ1O3 =>
      'Over-apologize and keep bringing it up';

  @override
  String get safetyAcademyLsnCulturalDontsQ1Exp =>
      'A sincere, brief apology followed by genuine effort to do better is the most mature response.';

  @override
  String get safetyAcademyLsnCulturalCommunicationTitle =>
      'Communication Across Cultures';

  @override
  String get safetyAcademyLsnCulturalCommunicationS0 =>
      'Communication styles vary significantly across cultures. What feels direct and honest in one culture may come across as rude in another. Understanding these differences prevents misunderstandings.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS1 =>
      'If something your date says or does confuses you, assume positive intent and ask for clarification rather than jumping to conclusions.';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2 =>
      'Cultural Communication Differences to Be Aware Of';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I0 =>
      'Direct vs. indirect communication styles';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I1 =>
      'Personal space and physical touch norms';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I2 =>
      'Eye contact expectations (some cultures find direct eye contact disrespectful)';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I3 =>
      'Attitudes toward punctuality and time';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I4 =>
      'Gift-giving customs and expectations';

  @override
  String get safetyAcademyLsnCulturalCommunicationS2I5 =>
      'The role of humor and what topics are off-limits';

  @override
  String get safetyAcademyLsnCulturalCommunicationS3 =>
      'When in doubt, communicate openly. A simple \"I want to make sure I understand you correctly\" goes a long way in bridging cultural gaps.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0 =>
      'Your date avoids direct eye contact. What should you think?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O0 =>
      'They are not interested in you';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O1 =>
      'They are being dishonest';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O2 =>
      'It may be a cultural norm -- do not assume negative intent';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0O3 =>
      'They are shy and need more encouragement';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ0Exp =>
      'In many cultures, avoiding direct eye contact is a sign of respect, not disinterest or dishonesty.';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1 =>
      'What is the best approach when cultural communication differences cause confusion?';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O0 => 'Assume the worst';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O1 =>
      'Ignore it and hope it resolves';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O2 =>
      'Ask for clarification with an open mind';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1O3 =>
      'Tell them to communicate more like you do';

  @override
  String get safetyAcademyLsnCulturalCommunicationQ1Exp =>
      'Open, non-judgmental communication is the best way to navigate cultural differences.';

  @override
  String get safetyAcademyModOnlineSafetyTitle => 'Online Safety 101';

  @override
  String get safetyAcademyModOnlineSafetyDesc =>
      'Learn to protect your identity and spot potential scams while dating online.';

  @override
  String get safetyAcademyLsnProfileProtectionTitle => 'Profile Protection';

  @override
  String get safetyAcademyLsnProfileProtectionS0 =>
      'Your dating profile is your first impression, but it can also expose personal information if you are not careful. Learning to share the right amount keeps you safe while still showing your personality.';

  @override
  String get safetyAcademyLsnProfileProtectionS1 =>
      'Use a unique photo that is not on your other social media profiles. Reverse image searches can link accounts together.';

  @override
  String get safetyAcademyLsnProfileProtectionS2 =>
      'Never include your full name, workplace, home address, or phone number in your bio.';

  @override
  String get safetyAcademyLsnProfileProtectionS3 => 'Profile Safety Checklist';

  @override
  String get safetyAcademyLsnProfileProtectionS3I0 =>
      'Remove or crop out identifiable landmarks near your home';

  @override
  String get safetyAcademyLsnProfileProtectionS3I1 =>
      'Use a first name or nickname only';

  @override
  String get safetyAcademyLsnProfileProtectionS3I2 =>
      'Disable location metadata on uploaded photos';

  @override
  String get safetyAcademyLsnProfileProtectionS3I3 =>
      'Avoid photos in work uniforms or with visible ID badges';

  @override
  String get safetyAcademyLsnProfileProtectionS3I4 =>
      'Review your profile from a stranger\'s perspective';

  @override
  String get safetyAcademyLsnProfileProtectionS4 =>
      'A well-crafted profile balances openness with privacy. Share your interests and values, but save specifics like your daily routine or home neighborhood for later conversations.';

  @override
  String get safetyAcademyLsnProfileProtectionQ0 =>
      'Which of the following is safe to include in your dating profile?';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O0 => 'Your home address';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O1 => 'Your favorite hobbies';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O2 =>
      'Your workplace name and department';

  @override
  String get safetyAcademyLsnProfileProtectionQ0O3 => 'Your phone number';

  @override
  String get safetyAcademyLsnProfileProtectionQ0Exp =>
      'Sharing hobbies is great for conversation starters without revealing personal details that could be used to locate you.';

  @override
  String get safetyAcademyLsnProfileProtectionQ1 =>
      'Why should you use unique photos on your dating profile?';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O0 => 'To look more attractive';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O1 =>
      'Because dating apps compress images';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O2 =>
      'To prevent reverse image searches linking to your other accounts';

  @override
  String get safetyAcademyLsnProfileProtectionQ1O3 =>
      'Unique photos get more likes';

  @override
  String get safetyAcademyLsnProfileProtectionQ1Exp =>
      'Reverse image search tools can link your dating profile to social media, blogs, or professional pages, revealing your full identity.';

  @override
  String get safetyAcademyLsnProfileProtectionQ2 =>
      'What should you check before uploading a photo?';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O0 =>
      'That it has a nice filter';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O1 =>
      'That location metadata is removed and no identifiable landmarks are visible';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O2 =>
      'That it was taken recently';

  @override
  String get safetyAcademyLsnProfileProtectionQ2O3 => 'That it is a selfie';

  @override
  String get safetyAcademyLsnProfileProtectionQ2Exp =>
      'Photo metadata (EXIF data) can contain GPS coordinates. Landmarks like street signs or building names can also reveal your location.';

  @override
  String get safetyAcademyLsnScamRecognitionTitle => 'Scam Recognition';

  @override
  String get safetyAcademyLsnScamRecognitionS0 =>
      'Romance scams cost victims billions worldwide each year. Scammers build emotional connections quickly and then exploit them for money or personal data. Knowing the signs can protect you.';

  @override
  String get safetyAcademyLsnScamRecognitionS1 =>
      'If someone asks for money, gift cards, cryptocurrency, or financial help early in a relationship -- no matter how compelling the story -- it is almost certainly a scam.';

  @override
  String get safetyAcademyLsnScamRecognitionS2 =>
      'Do a video call early on. Scammers avoid live video because it exposes fake identities. If someone repeatedly avoids video, be cautious.';

  @override
  String get safetyAcademyLsnScamRecognitionS3 => 'Common Scam Red Flags';

  @override
  String get safetyAcademyLsnScamRecognitionS3I0 =>
      'Profile seems too perfect (model-quality photos, dream career)';

  @override
  String get safetyAcademyLsnScamRecognitionS3I1 =>
      'Claims to be overseas military, oil rig worker, or international business person';

  @override
  String get safetyAcademyLsnScamRecognitionS3I2 =>
      'Falls in love unusually fast (\"love bombing\")';

  @override
  String get safetyAcademyLsnScamRecognitionS3I3 =>
      'Avoids video calls or meeting in person';

  @override
  String get safetyAcademyLsnScamRecognitionS3I4 =>
      'Requests money for emergencies, travel, or medical bills';

  @override
  String get safetyAcademyLsnScamRecognitionS3I5 =>
      'Asks you to move conversation to another platform quickly';

  @override
  String get safetyAcademyLsnScamRecognitionS4 =>
      'If you suspect a scam, stop communication immediately. Report the profile to the app and consider filing a report with your local authorities.';

  @override
  String get safetyAcademyLsnScamRecognitionQ0 =>
      'Someone you matched with a week ago says they love you and asks for money to visit you. What should you do?';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O0 =>
      'Send the money -- they seem genuine';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O1 =>
      'Ask for more details about why they need money';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O2 =>
      'Recognize this as a classic romance scam pattern and report them';

  @override
  String get safetyAcademyLsnScamRecognitionQ0O3 =>
      'Offer to buy their plane ticket directly';

  @override
  String get safetyAcademyLsnScamRecognitionQ0Exp =>
      'Declaring love very quickly and then requesting money is the hallmark pattern of romance scams. Report and block.';

  @override
  String get safetyAcademyLsnScamRecognitionQ1 =>
      'Which profession is commonly used as a cover story by scammers?';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O0 => 'Local teacher';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O1 =>
      'Overseas military deployment';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O2 => 'Neighborhood barista';

  @override
  String get safetyAcademyLsnScamRecognitionQ1O3 => 'Nearby office worker';

  @override
  String get safetyAcademyLsnScamRecognitionQ1Exp =>
      'Scammers often claim military deployment, offshore work, or international business to explain why they cannot meet in person or video call.';

  @override
  String get safetyAcademyLsnScamRecognitionQ2 =>
      'What is a good early step to verify someone is real?';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O0 =>
      'Ask for their home address';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O1 => 'Request a video call';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O2 =>
      'Send them money to test their response';

  @override
  String get safetyAcademyLsnScamRecognitionQ2O3 =>
      'Search for them on all social media platforms';

  @override
  String get safetyAcademyLsnScamRecognitionQ2Exp =>
      'A video call is one of the simplest ways to verify someone is who they claim to be. Scammers typically avoid live video at all costs.';

  @override
  String get safetyAcademyLsnRedFlagsTitle => 'Behavioral Red Flags';

  @override
  String get safetyAcademyLsnRedFlagsS0 =>
      'Beyond scams, there are behavioral patterns that can indicate controlling, manipulative, or potentially dangerous individuals. Learning to spot these early can save you from harmful situations.';

  @override
  String get safetyAcademyLsnRedFlagsS1 =>
      'Someone who pressures you to share intimate photos, meet immediately, or isolate from friends is displaying controlling behavior.';

  @override
  String get safetyAcademyLsnRedFlagsS2 => 'Behavioral Red Flags';

  @override
  String get safetyAcademyLsnRedFlagsS2I0 =>
      'Excessive jealousy or possessiveness before even meeting';

  @override
  String get safetyAcademyLsnRedFlagsS2I1 =>
      'Pressuring for personal information or intimate content';

  @override
  String get safetyAcademyLsnRedFlagsS2I2 =>
      'Getting angry when you don\'t respond immediately';

  @override
  String get safetyAcademyLsnRedFlagsS2I3 =>
      'Disrespecting your stated boundaries';

  @override
  String get safetyAcademyLsnRedFlagsS2I4 =>
      'Making you feel guilty for spending time with others';

  @override
  String get safetyAcademyLsnRedFlagsS2I5 =>
      'Inconsistent stories about themselves';

  @override
  String get safetyAcademyLsnRedFlagsS3 =>
      'Trust your gut. If a conversation makes you uncomfortable, you do not owe anyone an explanation. It is always okay to stop responding, block, or report.';

  @override
  String get safetyAcademyLsnRedFlagsS4 =>
      'Healthy connections are built on mutual respect. Someone who truly cares about you will respect your pace, your boundaries, and your autonomy.';

  @override
  String get safetyAcademyLsnRedFlagsQ0 =>
      'Your match gets upset when you take an hour to reply. What does this indicate?';

  @override
  String get safetyAcademyLsnRedFlagsQ0O0 => 'They really like you';

  @override
  String get safetyAcademyLsnRedFlagsQ0O1 =>
      'They are enthusiastic about the conversation';

  @override
  String get safetyAcademyLsnRedFlagsQ0O2 => 'Potentially controlling behavior';

  @override
  String get safetyAcademyLsnRedFlagsQ0O3 => 'They are just anxious';

  @override
  String get safetyAcademyLsnRedFlagsQ0Exp =>
      'Getting angry about response times before you have even met is a sign of controlling behavior. Everyone is entitled to their own schedule.';

  @override
  String get safetyAcademyLsnRedFlagsQ1 =>
      'What is the best response when someone pressures you for intimate photos?';

  @override
  String get safetyAcademyLsnRedFlagsQ1O0 => 'Send them to keep the peace';

  @override
  String get safetyAcademyLsnRedFlagsQ1O1 =>
      'Firmly decline, and if they persist, block and report them';

  @override
  String get safetyAcademyLsnRedFlagsQ1O2 => 'Ask them to send theirs first';

  @override
  String get safetyAcademyLsnRedFlagsQ1O3 => 'Promise to send them later';

  @override
  String get safetyAcademyLsnRedFlagsQ1Exp =>
      'You should never feel pressured to share intimate content. A respectful person will accept your decision without pushing.';

  @override
  String get safetyAcademyLsnRedFlagsQ2 =>
      'Which is a healthy sign in early conversations?';

  @override
  String get safetyAcademyLsnRedFlagsQ2O0 =>
      'They want to know your exact daily schedule';

  @override
  String get safetyAcademyLsnRedFlagsQ2O1 =>
      'They respect your pace and boundaries';

  @override
  String get safetyAcademyLsnRedFlagsQ2O2 =>
      'They say \"I love you\" within the first few days';

  @override
  String get safetyAcademyLsnRedFlagsQ2O3 =>
      'They ask you to stop talking to other people on the app';

  @override
  String get safetyAcademyLsnRedFlagsQ2Exp =>
      'Respect for pace and boundaries is the foundation of a healthy connection. Everything else in this list is a potential red flag.';

  @override
  String get safetyAcademyModEmotionalIntelligenceTitle =>
      'Emotional Intelligence';

  @override
  String get safetyAcademyModEmotionalIntelligenceDesc =>
      'Understand attachment styles, love languages, and build emotional awareness.';

  @override
  String get safetyAcademyLsnAttachmentStylesTitle => 'Attachment Styles';

  @override
  String get safetyAcademyLsnAttachmentStylesS0 =>
      'Attachment theory explains how our early relationships shape the way we connect with romantic partners. Understanding your attachment style can help you build healthier relationships.';

  @override
  String get safetyAcademyLsnAttachmentStylesS1 =>
      'The four main attachment styles are: Secure, Anxious, Avoidant, and Disorganized. Most people are a mix, and styles can change with awareness and effort.';

  @override
  String get safetyAcademyLsnAttachmentStylesS2 => 'The Four Attachment Styles';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I0 =>
      'Secure: Comfortable with closeness, trusting, communicative';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I1 =>
      'Anxious: Craves closeness but fears rejection, may need extra reassurance';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I2 =>
      'Avoidant: Values independence highly, may pull away when things get close';

  @override
  String get safetyAcademyLsnAttachmentStylesS2I3 =>
      'Disorganized: Mix of anxious and avoidant, often from difficult early experiences';

  @override
  String get safetyAcademyLsnAttachmentStylesS3 =>
      'Knowing your style helps you understand your reactions. If you tend toward anxious attachment, you might recognize that your urge to text repeatedly comes from fear, not genuine need. If avoidant, you might notice your tendency to shut down when emotions run high.';

  @override
  String get safetyAcademyLsnAttachmentStylesS4 =>
      'Understanding your partner\'s attachment style helps you respond with empathy rather than frustration. An avoidant partner pulling away is not rejection -- it is their coping mechanism.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0 =>
      'Your partner needs a lot of reassurance and gets anxious when you do not respond quickly. Which attachment style might this reflect?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O0 => 'Secure';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O1 => 'Anxious';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O2 => 'Avoidant';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0O3 => 'Disorganized';

  @override
  String get safetyAcademyLsnAttachmentStylesQ0Exp =>
      'Anxious attachment is characterized by a strong desire for closeness and fear of rejection, often leading to a need for frequent reassurance.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1 =>
      'What is the healthiest response to recognizing your attachment patterns?';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O0 =>
      'Accept that they cannot change';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O1 =>
      'Blame your parents for your style';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O2 =>
      'Use awareness to communicate better and work toward secure attachment';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1O3 =>
      'Only date people with the same style';

  @override
  String get safetyAcademyLsnAttachmentStylesQ1Exp =>
      'Attachment styles can evolve with self-awareness, communication, and sometimes professional support.';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2 =>
      'Someone with an avoidant attachment style might:';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O0 =>
      'Send multiple texts if you do not reply quickly';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O1 =>
      'Pull away or shut down when the relationship gets emotionally close';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O2 =>
      'Always want to spend every moment together';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2O3 =>
      'Be very open about their feelings from the start';

  @override
  String get safetyAcademyLsnAttachmentStylesQ2Exp =>
      'Avoidant attachment often manifests as pulling away when emotional intimacy increases, as a self-protection mechanism.';

  @override
  String get safetyAcademyLsnLoveLanguagesTitle => 'Love Languages';

  @override
  String get safetyAcademyLsnLoveLanguagesS0 =>
      'The concept of love languages, popularized by Dr. Gary Chapman, suggests that people express and receive love in five primary ways. Understanding yours and your partner\'s can transform your relationship.';

  @override
  String get safetyAcademyLsnLoveLanguagesS1 => 'The Five Love Languages';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I0 =>
      'Words of Affirmation: Verbal compliments, encouragement, and expressions of love';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I1 =>
      'Quality Time: Undivided attention and presence';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I2 =>
      'Receiving Gifts: Thoughtful tokens of affection (not about cost)';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I3 =>
      'Acts of Service: Actions that make life easier or show care';

  @override
  String get safetyAcademyLsnLoveLanguagesS1I4 =>
      'Physical Touch: Hugs, holding hands, and other physical affection';

  @override
  String get safetyAcademyLsnLoveLanguagesS2 =>
      'Pay attention to how your date expresses affection -- that is likely their love language. If they always compliment you, they probably value words of affirmation.';

  @override
  String get safetyAcademyLsnLoveLanguagesS3 =>
      'Mismatched love languages are common and manageable. The key is communication: tell your partner what makes you feel loved, and ask them the same question.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0 =>
      'Your partner always makes time for you and puts their phone away during conversations. Their love language is likely:';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O0 => 'Words of Affirmation';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O1 => 'Quality Time';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O2 => 'Receiving Gifts';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0O3 => 'Physical Touch';

  @override
  String get safetyAcademyLsnLoveLanguagesQ0Exp =>
      'Giving undivided attention and prioritizing presence is the hallmark of Quality Time as a love language.';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1 =>
      'You value words of affirmation but your partner shows love through acts of service. What should you do?';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O0 =>
      'Accept that you are incompatible';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O1 =>
      'Tell your partner what you need and learn to recognize their style of showing love';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O2 =>
      'Change your love language to match theirs';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1O3 => 'Ignore the difference';

  @override
  String get safetyAcademyLsnLoveLanguagesQ1Exp =>
      'Communication is key. Express what you need while also learning to appreciate how your partner shows love.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessTitle => 'Emotional Awareness';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS0 =>
      'Emotional awareness is the ability to recognize, understand, and manage your own emotions while also being attuned to others\'. In dating, this skill prevents reactive decisions and builds deeper connections.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS1 =>
      'Before responding to a frustrating message, pause and identify what you are actually feeling. Are you hurt? Anxious? Disappointed? Naming the emotion reduces its power.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2 =>
      'Building Emotional Awareness';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I0 =>
      'Practice naming your emotions throughout the day';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I1 =>
      'Notice physical sensations tied to emotions (tight chest = anxiety)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I2 =>
      'Journal about dating experiences and your emotional reactions';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I3 =>
      'Distinguish between reacting (impulsive) and responding (thoughtful)';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS2I4 =>
      'Develop a pause habit: wait before sending emotional messages';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS3 =>
      'Emotional awareness does not mean suppressing emotions. It means understanding them well enough to choose how you act on them.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessS4 =>
      'When you can say \"I felt hurt when you canceled our plans\" instead of \"You obviously do not care about me,\" you transform conflict into connection. That is emotional intelligence in action.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0 =>
      'Your date cancels plans last minute and you feel angry. What is the emotionally aware response?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O0 =>
      'Send an angry message immediately';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O1 =>
      'Ghost them as punishment';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O2 =>
      'Pause, identify your feelings, then communicate calmly how the cancellation made you feel';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0O3 =>
      'Pretend you do not care';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ0Exp =>
      'Pausing to identify your emotions and then communicating them calmly leads to better outcomes than reacting impulsively.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1 =>
      'What does emotional awareness mean?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O0 => 'Never showing emotions';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O1 => 'Always being happy';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O2 =>
      'Recognizing and understanding emotions to choose how to act on them';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1O3 =>
      'Expressing every emotion as soon as you feel it';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ1Exp =>
      'Emotional awareness is about recognition and understanding, which enables thoughtful responses rather than impulsive reactions.';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2 =>
      'Which is an example of \"responding\" versus \"reacting\"?';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O0 =>
      'Typing an angry reply the moment you feel upset';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O1 =>
      'Waiting, reflecting on your feelings, then crafting a thoughtful message';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O2 =>
      'Ignoring the message entirely';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2O3 =>
      'Venting to friends before replying';

  @override
  String get safetyAcademyLsnEmotionalAwarenessQ2Exp =>
      'Responding involves a deliberate pause for reflection, while reacting is driven by immediate emotion.';

  @override
  String get safetyAcademyModFirstMeetingTitle => 'First Meeting Guide';

  @override
  String get safetyAcademyModFirstMeetingDesc =>
      'Essential tips for safe, confident first dates with people you meet online.';

  @override
  String get safetyAcademyLsnPublicPlacesTitle => 'Meeting in Public Places';

  @override
  String get safetyAcademyLsnPublicPlacesS0 =>
      'Meeting someone from a dating app for the first time is exciting, but safety should always come first. Choosing the right location sets the foundation for a comfortable experience.';

  @override
  String get safetyAcademyLsnPublicPlacesS1 =>
      'Choose a busy cafe, restaurant, or public park for your first meeting. Familiarity with the venue gives you an advantage -- you know the exits and the staff.';

  @override
  String get safetyAcademyLsnPublicPlacesS2 =>
      'Never agree to meet at someone\'s home, a secluded area, or a place you are unfamiliar with for a first date.';

  @override
  String get safetyAcademyLsnPublicPlacesS3 =>
      'First Meeting Location Checklist';

  @override
  String get safetyAcademyLsnPublicPlacesS3I0 =>
      'Choose a public, well-lit location';

  @override
  String get safetyAcademyLsnPublicPlacesS3I1 =>
      'Pick somewhere you are familiar with';

  @override
  String get safetyAcademyLsnPublicPlacesS3I2 =>
      'Ensure the venue has other people around';

  @override
  String get safetyAcademyLsnPublicPlacesS3I3 =>
      'Check that you have phone signal at the venue';

  @override
  String get safetyAcademyLsnPublicPlacesS3I4 =>
      'Have a backup plan if you need to leave quickly';

  @override
  String get safetyAcademyLsnPublicPlacesQ0 =>
      'Which is the safest first date location?';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O0 => 'Their apartment';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O1 => 'A busy downtown cafe';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O2 => 'A remote hiking trail';

  @override
  String get safetyAcademyLsnPublicPlacesQ0O3 => 'Your home';

  @override
  String get safetyAcademyLsnPublicPlacesQ0Exp =>
      'A busy cafe is public, has staff around, and you can leave easily if needed.';

  @override
  String get safetyAcademyLsnPublicPlacesQ1 =>
      'Why should you pick a venue you are familiar with?';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O0 =>
      'So you can impress your date with recommendations';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O1 =>
      'Because you know the exits, staff, and surroundings';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O2 =>
      'It is cheaper if you know the menu';

  @override
  String get safetyAcademyLsnPublicPlacesQ1O3 => 'There is no real advantage';

  @override
  String get safetyAcademyLsnPublicPlacesQ1Exp =>
      'Knowing the venue means you know how to leave quickly and who to ask for help if you feel uncomfortable.';

  @override
  String get safetyAcademyLsnSharingPlansTitle => 'Sharing Your Plans';

  @override
  String get safetyAcademyLsnSharingPlansS0 =>
      'Letting someone you trust know about your date is one of the simplest and most effective safety measures. A safety buddy can check in on you and knows where to look if something goes wrong.';

  @override
  String get safetyAcademyLsnSharingPlansS1 =>
      'Share your date\'s profile, the venue, and your expected return time with a trusted friend. Set up a check-in call 30 minutes into the date.';

  @override
  String get safetyAcademyLsnSharingPlansS2 =>
      'Information to Share with Your Safety Buddy';

  @override
  String get safetyAcademyLsnSharingPlansS2I0 =>
      'Screenshot of your date\'s profile';

  @override
  String get safetyAcademyLsnSharingPlansS2I1 =>
      'Name (or username) of the person you are meeting';

  @override
  String get safetyAcademyLsnSharingPlansS2I2 =>
      'Date, time, and venue of the meeting';

  @override
  String get safetyAcademyLsnSharingPlansS2I3 => 'Your expected return time';

  @override
  String get safetyAcademyLsnSharingPlansS2I4 =>
      'Agreed check-in time (e.g., a call or text)';

  @override
  String get safetyAcademyLsnSharingPlansS3 =>
      'You can also use GreenGo\'s Share My Date feature to easily send date details to a trusted contact. There is no shame in being safe -- your date should understand.';

  @override
  String get safetyAcademyLsnSharingPlansQ0 =>
      'What should you share with a trusted friend before a first date?';

  @override
  String get safetyAcademyLsnSharingPlansQ0O0 => 'Only the venue name';

  @override
  String get safetyAcademyLsnSharingPlansQ0O1 =>
      'Your date\'s profile, venue, time, and expected return';

  @override
  String get safetyAcademyLsnSharingPlansQ0O2 => 'Nothing -- it is private';

  @override
  String get safetyAcademyLsnSharingPlansQ0O3 =>
      'Just a text saying \"going on a date\"';

  @override
  String get safetyAcademyLsnSharingPlansQ0Exp =>
      'The more information your safety buddy has, the better they can help if something goes wrong.';

  @override
  String get safetyAcademyLsnSharingPlansQ1 =>
      'When is a good time to set up a check-in call?';

  @override
  String get safetyAcademyLsnSharingPlansQ1O0 => 'After the date is over';

  @override
  String get safetyAcademyLsnSharingPlansQ1O1 =>
      'About 30 minutes into the date';

  @override
  String get safetyAcademyLsnSharingPlansQ1O2 => 'A check-in is not necessary';

  @override
  String get safetyAcademyLsnSharingPlansQ1O3 =>
      'Before you leave for the date';

  @override
  String get safetyAcademyLsnSharingPlansQ1Exp =>
      'A check-in 30 minutes in gives you enough time to assess the situation and an easy out if you feel uncomfortable.';

  @override
  String get safetyAcademyLsnTransportSafetyTitle => 'Transport Safety';

  @override
  String get safetyAcademyLsnTransportSafetyS0 =>
      'How you get to and from a date matters just as much as where you meet. Maintaining control over your transportation ensures you can leave whenever you want.';

  @override
  String get safetyAcademyLsnTransportSafetyS1 =>
      'Never let your date pick you up from your home for the first meeting. This reveals your address and makes you dependent on them for a ride home.';

  @override
  String get safetyAcademyLsnTransportSafetyS2 =>
      'Drive yourself, use ride-sharing, or take public transport. Keep your phone charged and have enough money for an emergency ride home.';

  @override
  String get safetyAcademyLsnTransportSafetyS3 => 'Transport Safety Checklist';

  @override
  String get safetyAcademyLsnTransportSafetyS3I0 =>
      'Arrange your own transportation';

  @override
  String get safetyAcademyLsnTransportSafetyS3I1 =>
      'Keep your phone fully charged';

  @override
  String get safetyAcademyLsnTransportSafetyS3I2 =>
      'Have emergency ride money available';

  @override
  String get safetyAcademyLsnTransportSafetyS3I3 =>
      'Share your live location with a trusted contact';

  @override
  String get safetyAcademyLsnTransportSafetyS3I4 =>
      'Park in a well-lit area if driving';

  @override
  String get safetyAcademyLsnTransportSafetyS3I5 =>
      'Do not leave drinks unattended if you step away';

  @override
  String get safetyAcademyLsnTransportSafetyQ0 =>
      'Why should you arrange your own transportation for a first date?';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O0 => 'To save money on gas';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O1 =>
      'So you can leave whenever you want and your address stays private';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O2 => 'To avoid traffic';

  @override
  String get safetyAcademyLsnTransportSafetyQ0O3 =>
      'Because parking is easier alone';

  @override
  String get safetyAcademyLsnTransportSafetyQ0Exp =>
      'Having your own transport means you are not dependent on your date and your home address remains private.';

  @override
  String get safetyAcademyLsnTransportSafetyQ1 =>
      'Your date offers to pick you up from home. What should you do?';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O0 =>
      'Accept -- it is a nice gesture';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O1 =>
      'Politely decline and suggest meeting at the venue instead';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O2 =>
      'Give them a nearby intersection instead of your exact address';

  @override
  String get safetyAcademyLsnTransportSafetyQ1O3 =>
      'Accept but have a friend watch from the window';

  @override
  String get safetyAcademyLsnTransportSafetyQ1Exp =>
      'Meeting at the venue keeps your address private and ensures you have independent transportation.';

  @override
  String get gamificationAchFirstMatchName => 'First Match';

  @override
  String get gamificationAchFirstMatchDesc => 'Get your first mutual like';

  @override
  String get gamificationAchConversationStarterName => 'Conversation Starter';

  @override
  String get gamificationAchConversationStarterDesc =>
      'Initiate 10 conversations';

  @override
  String get gamificationAchVideoChampionName => 'Video Champion';

  @override
  String get gamificationAchVideoChampionDesc => 'Complete 5 video calls';

  @override
  String get gamificationAchProfileMasterName => 'Profile Master';

  @override
  String get gamificationAchProfileMasterDesc =>
      'Complete all profile sections 100%';

  @override
  String get gamificationAchGlobeTrotterName => 'Globe Trotter';

  @override
  String get gamificationAchGlobeTrotterDesc =>
      'Match with users from 10+ countries';

  @override
  String get gamificationAchGenerousHeartName => 'Generous Heart';

  @override
  String get gamificationAchGenerousHeartDesc => 'Gift coins to matches';

  @override
  String get gamificationAchDailyDedicationName => 'Daily Dedication';

  @override
  String get gamificationAchDailyDedicationDesc =>
      '7-day consecutive login streak';

  @override
  String get gamificationAchSuperStarName => 'Super Star';

  @override
  String get gamificationAchSuperStarDesc => 'Receive 50+ super likes';

  @override
  String get gamificationAchSocialButterflyName => 'Social Butterfly';

  @override
  String get gamificationAchSocialButterflyDesc =>
      'Maintain 20+ active conversations';

  @override
  String get gamificationAchPerfectWeekName => 'Perfect Week';

  @override
  String get gamificationAchPerfectWeekDesc =>
      'Complete all daily challenges for 7 days';

  @override
  String get gamificationAchEarlyBirdName => 'Early Bird';

  @override
  String get gamificationAchEarlyBirdDesc =>
      'Send messages before 9 AM on 10 days';

  @override
  String get gamificationAchNightOwlName => 'Night Owl';

  @override
  String get gamificationAchNightOwlDesc =>
      'Send messages after 10 PM on 10 days';

  @override
  String get gamificationAchCenturionName => 'Centurion';

  @override
  String get gamificationAchCenturionDesc => 'Reach 100 total matches';

  @override
  String get gamificationAchSpeedDaterName => 'Speed Dater';

  @override
  String get gamificationAchSpeedDaterDesc => 'Match with 10 people in one day';

  @override
  String get gamificationAchPhotoCollectorName => 'Photo Collector';

  @override
  String get gamificationAchPhotoCollectorDesc =>
      'Add 6 photos to your profile';

  @override
  String get gamificationAchTrendSetterName => 'Trend Setter';

  @override
  String get gamificationAchTrendSetterDesc => 'Be among the first 1000 users';

  @override
  String get gamificationAchVerifiedName => 'Verified';

  @override
  String get gamificationAchVerifiedDesc => 'Complete photo verification';

  @override
  String get gamificationAchPremiumMemberName => 'Premium Member';

  @override
  String get gamificationAchPremiumMemberDesc =>
      'Subscribe to Silver or Gold tier';

  @override
  String get gamificationAchCoinCollectorName => 'Coin Collector';

  @override
  String get gamificationAchCoinCollectorDesc => 'Accumulate 1000 coins';

  @override
  String get gamificationAchMonthlyStreakName => 'Monthly Dedication';

  @override
  String get gamificationAchMonthlyStreakDesc =>
      '30-day consecutive login streak';

  @override
  String get gamificationAchVocabularyBeginnerName => 'Word Explorer';

  @override
  String get gamificationAchVocabularyBeginnerDesc =>
      'Use 100 unique words in chat';

  @override
  String get gamificationAchVocabularyIntermediateName => 'Wordsmith';

  @override
  String get gamificationAchVocabularyIntermediateDesc =>
      'Use 500 unique words in chat';

  @override
  String get gamificationAchVocabularyAdvancedName => 'Vocabulary Expert';

  @override
  String get gamificationAchVocabularyAdvancedDesc =>
      'Use 1000 unique words in chat';

  @override
  String get gamificationAchVocabularyMasterName => 'Vocabulary Master';

  @override
  String get gamificationAchVocabularyMasterDesc =>
      'Use 5000 unique words in chat';

  @override
  String get gamificationAchRareWordHunterName => 'Rare Word Hunter';

  @override
  String get gamificationAchRareWordHunterDesc =>
      'Use 50 rare words (frequency score below 50)';

  @override
  String gamificationRewardCoinsPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count coins',
      one: '+1 coin',
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
    return 'Reward: $reward';
  }

  @override
  String get gamificationRewardBadge => 'Badge';

  @override
  String get gamificationVip => 'VIP';

  @override
  String get gamificationRewardsTitle => 'Rewards';

  @override
  String gamificationXpToNextLevel(String xp) {
    return '$xp XP to next level';
  }

  @override
  String get gamificationStreakDayUnitOne => 'day';

  @override
  String get gamificationStreakDayUnitOther => 'days';

  @override
  String get gamificationOnFire => '🎉 On Fire!';

  @override
  String gamificationUserFallback(String id) {
    return 'User $id';
  }

  @override
  String gamificationNoticeAchievementUnlocked(String name, String reward) {
    return '$name unlocked! $reward';
  }

  @override
  String gamificationNoticeAchievementReady(String name) {
    return 'Achievement complete! Ready to unlock: $name';
  }

  @override
  String gamificationNoticeLevelUp(int level) {
    return 'Level up! You reached level $level!';
  }

  @override
  String get gamificationNoticeVip =>
      'Congratulations! You\'ve achieved VIP status! 👑';

  @override
  String gamificationNoticeLevelRewardsClaimed(int level, String rewards) {
    return 'Level $level rewards claimed! $rewards';
  }

  @override
  String gamificationNoticeChallengeRewardsClaimed(
      String name, String rewards) {
    return '$name rewards claimed! $rewards';
  }

  @override
  String gamificationNoticeFeatureLocked(int count, String feature, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$feature unlocks at level $level. $count levels to go!',
      one: '$feature unlocks at level $level. 1 level to go!',
    );
    return '$_temp0';
  }

  @override
  String get gamificationFeatureCustomChatThemes => 'Custom Chat Themes';

  @override
  String get gamificationFeatureProfileVideo => 'Profile Video';

  @override
  String get gamificationFeatureAdvancedFilters => 'Advanced Filters';

  @override
  String get gamificationFeatureUnlimitedRewinds => 'Unlimited Rewinds';

  @override
  String get gamificationFeatureVipBadge => 'VIP Badge';

  @override
  String get gamificationFeaturePriorityLikes => 'Priority Likes';

  @override
  String get gamificationLevelRewardBronzeFrame => 'Bronze Frame';

  @override
  String get gamificationLevelRewardSilverFrame => 'Silver Frame';

  @override
  String get gamificationLevelRewardGoldFrame => 'Gold Frame';

  @override
  String get gamificationLevelRewardPlatinumFrame => 'Platinum Frame';

  @override
  String get gamificationLevelRewardDiamondFrame => 'Diamond Frame';

  @override
  String get gamificationLevelRewardLegendaryFrame => 'Legendary Frame';

  @override
  String get gamificationLevelRewardVipCrown => 'VIP Crown';

  @override
  String gamificationLevelRewardMaxLevelBadge(int level) {
    return 'Level $level Badge';
  }

  @override
  String gamificationLevelRewardBonusCoins(int count) {
    return '$count Bonus Coins';
  }

  @override
  String get gamificationMissionAttend3Events => 'Attend 3 events';

  @override
  String get gamificationMissionConnect3Countries =>
      'Connect with people from 3 countries';

  @override
  String get gamificationMissionJoinCommunity => 'Join a community';

  @override
  String get gamificationMissionCompleteProfile => 'Complete your profile';

  @override
  String get gamificationMissionAdd5People => 'Add 5 people';

  @override
  String get updateRequiredTitle => 'Update Required';

  @override
  String get updateRequiredMessage =>
      'A new version of GreenGo is available. Please update to continue using the app.';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String get updateAvailableMessage =>
      'A new version of GreenGo is available with improvements and new features.';

  @override
  String get updateVersionCurrent => 'Current';

  @override
  String get updateVersionRequired => 'Required';

  @override
  String get updateVersionAvailable => 'Available';

  @override
  String get updateVersionLatest => 'Latest';

  @override
  String get updateWhatsNew => 'What\'s New';

  @override
  String get updateNowButton => 'Update Now';

  @override
  String get updateButton => 'Update';

  @override
  String get maintenanceTitle => 'Under Maintenance';

  @override
  String get maintenanceCheckBackSoon => 'Please check back soon';

  @override
  String get maintenanceDefaultMessage =>
      'We are currently performing maintenance. Please try again later.';

  @override
  String get countdownAlmostThere => 'Almost There!';

  @override
  String get countdownVipEarlyAccess => 'VIP Early Access';

  @override
  String countdownLaunchDate(String date) {
    return 'Launch Date: $date';
  }

  @override
  String get countdownTimeUntilLaunch => 'Time Until Launch';

  @override
  String get countdownWantEarlierAccess => 'Want Earlier Access?';

  @override
  String countdownUpgradeForEarlierAccess(String date) {
    return 'Upgrade your tier to get earlier access before $date!';
  }

  @override
  String get countdownLaunchDay => 'Launch Day!';

  @override
  String get countdownNowAvailable => 'GreenGo Chat is now available';

  @override
  String celebrationWelcomeToTier(String tier) {
    return 'Welcome to $tier!';
  }

  @override
  String get celebrationMembershipActive =>
      'Your premium membership is now active';

  @override
  String get celebrationUnlimitedLikes => 'Unlimited likes';

  @override
  String get celebrationSeeWhoLikedYou => 'See who liked you';

  @override
  String celebrationPerDay(int count) {
    return '$count/day';
  }

  @override
  String get celebrationExclusiveEvents => 'Exclusive Events';

  @override
  String purchaseSuccessCoinsAdded(int count) {
    return '$count GreenGo Coins added!';
  }

  @override
  String get pushChannelMainName => 'GreenGo Notifications';

  @override
  String get pushChannelMainDescription =>
      'Messages, likes, events and activity';

  @override
  String get pushChannelAnnouncementsName => 'Announcements';

  @override
  String get pushChannelAnnouncementsDescription =>
      'Broadcasts and announcements from GreenGo';

  @override
  String get pushChannelSummaryName => 'Activity summary';

  @override
  String get pushChannelSummaryDescription => 'Bundled activity notifications';

  @override
  String get pushChannelGeneralName => 'General';

  @override
  String get pushChannelGeneralDescription => 'General notifications';

  @override
  String get usageLimitTypeConnects => 'connects';

  @override
  String get usageLimitTypePasses => 'passes';

  @override
  String get usageLimitTypePriorityConnects => 'Priority Connects';

  @override
  String get usageLimitTypeDailyPriorityConnects => 'daily Priority Connects';

  @override
  String get usageLimitTypeSwipes => 'swipes';

  @override
  String get usageLimitTypeMessages => 'messages';

  @override
  String get usageLimitTypeMediaSends => 'media sends';

  @override
  String get usageLimitTypeDirectMatches => 'direct matches';

  @override
  String get usageLimitTypeConnections => 'connections';

  @override
  String usageLimitUnlimited(String type) {
    return 'Unlimited $type';
  }

  @override
  String usageLimitRemainingThisHour(int remaining, String type) {
    return '$remaining $type remaining this hour';
  }

  @override
  String usageLimitRemainingToday(int remaining, String type) {
    return '$remaining $type remaining today';
  }

  @override
  String usageLimitConnectsHourly(int limit) {
    return 'You\'ve used all $limit connects this hour. Upgrade for more or wait until next hour.';
  }

  @override
  String usageLimitPassesHourly(int limit) {
    return 'You\'ve used all $limit passes this hour. Upgrade for more or wait until next hour.';
  }

  @override
  String usageLimitPriorityUnavailable(String tier) {
    return 'Priority Connects are not available on the $tier plan. Upgrade to unlock this feature!';
  }

  @override
  String usageLimitPriorityHourly(int limit) {
    return 'You\'ve used all $limit Priority Connects this hour. Upgrade for more or wait until next hour.';
  }

  @override
  String usageLimitPriorityDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'You\'ve used your $limit free priority connects for today. Use coins for more or wait until tomorrow.',
      one:
          'You\'ve used your 1 free priority connect for today. Use coins for more or wait until tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String usageLimitSwipesDaily(int limit) {
    return 'You\'ve used all $limit swipes for today. Upgrade to get more swipes or wait until tomorrow.';
  }

  @override
  String usageLimitMessagesDaily(int limit) {
    return 'You\'ve reached your daily limit of $limit messages. Upgrade to send unlimited messages!';
  }

  @override
  String usageLimitMediaUnavailable(String tier) {
    return 'Sending media is not available on the $tier plan. Upgrade to send images and videos!';
  }

  @override
  String usageLimitMediaDaily(int limit) {
    return 'You\'ve reached your daily limit of $limit media sends. Upgrade for more or wait until tomorrow.';
  }

  @override
  String usageLimitDirectMatchDaily(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other:
          'You\'ve used your $limit free direct matches today. Use coins for more or wait until tomorrow.',
      one:
          'You\'ve used your 1 free direct match today. Use coins for more or wait until tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get contentFilterViolationEmail => 'email address';

  @override
  String get contentFilterViolationPhoneWords =>
      'phone number (written as words)';

  @override
  String get contentFilterViolationPhone => 'phone number';

  @override
  String get contentFilterViolationSocial => 'social media/link';

  @override
  String adminImportSummary(int success, int duplicates, int errors) {
    return 'Imported: $success | Duplicates: $duplicates | Errors: $errors';
  }

  @override
  String get tierBoostCadenceNone => 'None';

  @override
  String get tierBoostCadenceMonthly => '1 per month';

  @override
  String get tierBoostCadenceWeekly => '~1 per week';

  @override
  String get tierBoostCadenceDaily => '~1 per day';

  @override
  String get tierFilterLevelBasic => 'Basic';

  @override
  String get tierFilterLevelStandard => 'Standard';

  @override
  String get tierFilterLevelAdvanced => 'Advanced';

  @override
  String get tierFilterLevelAll => 'All filters';

  @override
  String tierTtsCostValue(int coins) {
    return '$coins coins per translation';
  }

  @override
  String chatLearningLiteral(String text) {
    return 'Literal: $text';
  }

  @override
  String chatLearningMeaning(String text) {
    return 'Meaning: $text';
  }

  @override
  String get validatorNameRequired => 'Name is required';

  @override
  String get validatorNameLettersOnly =>
      'Name can only contain letters and spaces';

  @override
  String get validatorPhoneRequired => 'Phone number is required';

  @override
  String get validatorPhoneMinDigits =>
      'Phone number must be at least 10 digits';

  @override
  String get validatorAgeRequired => 'Age is required';

  @override
  String validatorMinAge(int minAge) {
    return 'You must be at least $minAge years old';
  }

  @override
  String get validatorInvalidAge => 'Invalid age';

  @override
  String validatorBioMaxLength(int max) {
    return 'Bio must be less than $max characters';
  }

  @override
  String get profileOnboardingIncompleteStep =>
      'Please complete all required fields';

  @override
  String get profileGenderPreferNotToSay => 'Prefer not to say';

  @override
  String get profileOrientationStraight => 'Straight';

  @override
  String get profileOrientationGay => 'Gay';

  @override
  String get profileOrientationBisexual => 'Bisexual';

  @override
  String get profileLanguageHebrew => 'Hebrew';

  @override
  String get profileLanguageThai => 'Thai';

  @override
  String get profileLanguageVietnamese => 'Vietnamese';

  @override
  String profileLatLon(String lat, String lon) {
    return 'Lat: $lat, Lon: $lon';
  }

  @override
  String get profileNicknameInvalid => 'Invalid nickname';

  @override
  String get profileNicknameErrorEmpty => 'Nickname cannot be empty';

  @override
  String profileNicknameErrorTooShort(int min) {
    return 'Nickname must be at least $min characters';
  }

  @override
  String profileNicknameErrorTooLong(int max) {
    return 'Nickname must be $max characters or less';
  }

  @override
  String get profileNicknameErrorStartLetter =>
      'Nickname must start with a letter';

  @override
  String get profileNicknameErrorChars =>
      'Nickname can only contain letters, numbers, and underscores';

  @override
  String get profileNicknameErrorUnderscores =>
      'Nickname cannot contain consecutive underscores';

  @override
  String get profileNicknameErrorReserved =>
      'Nickname cannot contain reserved words';

  @override
  String get profileFreeUnlimited => 'Free - Unlimited';

  @override
  String get profileFreeWithPlatinum => 'Free with Platinum';

  @override
  String profileCoinsPerDay(int count) {
    return '$count coins/day';
  }

  @override
  String profileTravelerActiveSubtitle(
      String location, int hours, int minutes) {
    return '$location - ${hours}h ${minutes}m remaining';
  }

  @override
  String profileTravelerInactiveSubtitle(String cost) {
    return '$cost - Appear in another city';
  }

  @override
  String profileMinutesRemaining(int minutes) {
    return '${minutes}m remaining';
  }

  @override
  String profileHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m remaining';
  }

  @override
  String get profileGhostMode => 'Ghost Mode';

  @override
  String get profileGhostModeActiveSubtitle =>
      'Ghost Mode - Unlimited - Hidden from discovery & search';

  @override
  String get profileGhostModeInactiveSubtitle =>
      'Free - Unlimited - Hidden from discovery & nickname search';

  @override
  String profileIncognitoCostSubtitle(int count) {
    return '$count coins/24h - Hidden from discovery';
  }

  @override
  String get photoDeleteTitle => 'Delete Photo';

  @override
  String travelerCouldNotResolveAddress(String coordinates) {
    return '$coordinates — could not resolve address';
  }

  @override
  String get membershipTierNameBasicFree => 'Basic (Free)';

  @override
  String get membershipTierNameSilverPremium => 'Silver Premium';

  @override
  String get membershipTierNameGoldPremium => 'Gold Premium';

  @override
  String get membershipTierNamePlatinumVip => 'Platinum VIP';

  @override
  String get membershipTierNameSilverVip => 'Silver VIP';

  @override
  String get membershipTierNameGoldVip => 'Gold VIP';

  @override
  String get membershipTierNameTester => 'Tester';

  @override
  String membershipBuyProductPrice(String product, String price) {
    return 'Buy $product – $price';
  }

  @override
  String get coinSpendCategoryMatching => 'Matching';

  @override
  String get coinSpendCategoryMessaging => 'Messaging';

  @override
  String get coinSpendCategoryGifts => 'Virtual Gifts';

  @override
  String get coinSpendSeeWhoLiked => 'See Who Liked';

  @override
  String get coinSpendReadReceiptsDay => 'Read Receipts (1 Day)';

  @override
  String get coinSpendRose => 'Rose';

  @override
  String get coinSpendTeddyBear => 'Teddy Bear';

  @override
  String get coinSpendDiamond => 'Diamond';

  @override
  String get coinSpendSuperLikeDesc => 'Send a super like to stand out';

  @override
  String get coinSpendBoostDesc => 'Be seen by more people for 30 mins';

  @override
  String get coinSpendUndoDesc => 'Undo your last swipe';

  @override
  String get coinSpendSeeWhoLikedDesc => 'See who liked your profile';

  @override
  String get coinSpendReadReceiptsDesc => 'See when messages are read';

  @override
  String get coinSpendRoseDesc => 'Send a virtual rose';

  @override
  String get coinSpendTeddyBearDesc => 'Send a cute teddy bear';

  @override
  String get coinSpendDiamondDesc => 'Send a sparkling diamond';

  @override
  String get coinReasonFirstMatchReward => 'First Match Reward';

  @override
  String get coinReasonCompleteProfileReward => 'Complete Profile Reward';

  @override
  String get coinReasonDailyLoginStreak => 'Daily Login Streak';

  @override
  String get coinReasonAchievementUnlocked => 'Achievement Unlocked';

  @override
  String get coinReasonMonthlyAllowance => 'Monthly Allowance';

  @override
  String get coinReasonGiftReceived => 'Gift Received';

  @override
  String get coinReasonGiftSent => 'Gift Sent';

  @override
  String get coinReasonPromotionalBonus => 'Promotional Bonus';

  @override
  String get coinReasonReferralBonus => 'Referral Bonus';

  @override
  String get coinReasonCoinPurchase => 'Coin Purchase';

  @override
  String get coinReasonRefund => 'Refund';

  @override
  String get coinReasonUndoLastSwipe => 'Undo Last Swipe';

  @override
  String get coinReasonSeeWhoLikedYou => 'See Who Liked You';

  @override
  String get coinReasonDirectMessage => 'Direct Message';

  @override
  String get coinReasonFeaturePurchase => 'Feature Purchase';

  @override
  String get coinReasonCoinsExpired => 'Coins Expired';

  @override
  String get coinReasonAdminAdjustment => 'Admin Adjustment';

  @override
  String coinTxDescFirstMatch(int amount) {
    return 'Congratulations on your first match! Earned $amount coins.';
  }

  @override
  String coinTxDescCompleteProfile(int amount) {
    return 'Profile completed! Earned $amount coins.';
  }

  @override
  String coinTxDescDailyStreak(String streak, int amount) {
    return 'Day $streak login streak! Earned $amount coins.';
  }

  @override
  String coinTxDescAchievement(String achievement, int amount) {
    return 'Achievement unlocked: $achievement! Earned $amount coins.';
  }

  @override
  String coinTxDescAchievementGeneric(int amount) {
    return 'Achievement unlocked! Earned $amount coins.';
  }

  @override
  String coinTxDescMonthlyAllowance(String tier, int amount) {
    return '$tier monthly allowance: $amount coins.';
  }

  @override
  String coinTxDescGiftReceived(int amount, String user) {
    return 'Received $amount coins from $user.';
  }

  @override
  String coinTxDescGiftSent(int amount, String user) {
    return 'Sent $amount coins to $user.';
  }

  @override
  String coinTxDescPromotional(String campaign, int amount) {
    return 'Promotional bonus from $campaign: $amount coins.';
  }

  @override
  String coinTxDescPromotionalGeneric(int amount) {
    return 'Promotional bonus: $amount coins.';
  }

  @override
  String coinTxDescReferral(int amount) {
    return 'Referral bonus: earned $amount coins.';
  }

  @override
  String coinTxDescPurchase(int amount) {
    return 'Purchased $amount coins.';
  }

  @override
  String coinTxDescPurchasePackage(int amount, String package) {
    return 'Purchased $amount coins ($package).';
  }

  @override
  String coinTxDescRefund(int amount) {
    return 'Refund: $amount coins.';
  }

  @override
  String coinTxDescUsedFor(int amount, String feature) {
    return 'Used $amount coins for $feature.';
  }

  @override
  String coinTxDescExpired(int amount) {
    return '$amount coins expired.';
  }

  @override
  String coinTxDescClawback(int amount) {
    return '$amount coins removed: the purchase was refunded.';
  }

  @override
  String coinTxDescAdmin(int amount, String reason) {
    return 'Admin adjustment: $amount coins ($reason).';
  }

  @override
  String coinTxDescAdminGeneric(int amount) {
    return 'Admin adjustment: $amount coins.';
  }

  @override
  String coinPromoPercentBonus(int percent) {
    return '+$percent% bonus coins';
  }

  @override
  String get businessFollowerFallbackName => 'GreenGo member';

  @override
  String get bizCatRestaurant => 'Restaurant';

  @override
  String get bizCatBar => 'Bar';

  @override
  String get bizCatCafe => 'Cafe';

  @override
  String get bizCatNightclub => 'Nightclub';

  @override
  String get bizCatLounge => 'Lounge';

  @override
  String get bizCatHotel => 'Hotel';

  @override
  String get bizCatHostel => 'Hostel';

  @override
  String get bizCatGuesthouse => 'Guesthouse';

  @override
  String get bizCatResort => 'Resort';

  @override
  String get bizCatBedAndBreakfast => 'Bed & Breakfast';

  @override
  String get bizCatGym => 'Gym';

  @override
  String get bizCatYogaStudio => 'Yoga Studio';

  @override
  String get bizCatFitnessStudio => 'Fitness Studio';

  @override
  String get bizCatSpa => 'Spa';

  @override
  String get bizCatWellnessCenter => 'Wellness Center';

  @override
  String get bizCatBeautySalon => 'Beauty Salon';

  @override
  String get bizCatBarbershop => 'Barbershop';

  @override
  String get bizCatMuseum => 'Museum';

  @override
  String get bizCatArtGallery => 'Art Gallery';

  @override
  String get bizCatTheater => 'Theater';

  @override
  String get bizCatCinema => 'Cinema';

  @override
  String get bizCatLiveMusicVenue => 'Live Music Venue';

  @override
  String get bizCatCulturalCenter => 'Cultural Center';

  @override
  String get bizCatTourOperator => 'Tour Operator';

  @override
  String get bizCatTravelAgency => 'Travel Agency';

  @override
  String get bizCatLanguageSchool => 'Language School';

  @override
  String get bizCatCookingSchool => 'Cooking School';

  @override
  String get bizCatDanceStudio => 'Dance Studio';

  @override
  String get bizCatCoworkingSpace => 'Coworking Space';

  @override
  String get bizCatEventVenue => 'Event Venue';

  @override
  String get bizCatConferenceCenter => 'Conference Center';

  @override
  String get bizCatShopRetail => 'Shop / Retail';

  @override
  String get bizCatBoutique => 'Boutique';

  @override
  String get bizCatBookstore => 'Bookstore';

  @override
  String get bizCatMarket => 'Market';

  @override
  String get bizCatWinery => 'Winery';

  @override
  String get bizCatBrewery => 'Brewery';

  @override
  String get bizCatDistillery => 'Distillery';

  @override
  String get bizCatFoodTruck => 'Food Truck';

  @override
  String get bizCatBakery => 'Bakery';

  @override
  String get bizCatCoffeeRoastery => 'Coffee Roastery';

  @override
  String get bizCatSportsClub => 'Sports Club';

  @override
  String get bizCatAdventureAndOutdoor => 'Adventure & Outdoor';

  @override
  String get bizCatDivingCenter => 'Diving Center';

  @override
  String get bizCatPhotographyStudio => 'Photography Studio';

  @override
  String get bizCatCoachingAndConsulting => 'Coaching & Consulting';

  @override
  String get bizCatNonprofitAndNGO => 'Nonprofit & NGO';

  @override
  String get bizCatCommunityCenter => 'Community Center';

  @override
  String get bizCatTransportationService => 'Transportation Service';

  @override
  String get bizCatOther => 'Other';

  @override
  String get bizCatGroupFoodAndDrink => 'Food & Drink';

  @override
  String get bizCatGroupNightlife => 'Nightlife';

  @override
  String get bizCatGroupStay => 'Stay';

  @override
  String get bizCatGroupWellness => 'Wellness';

  @override
  String get bizCatGroupCulture => 'Culture';

  @override
  String get bizCatGroupTravelAndTours => 'Travel & Tours';

  @override
  String get bizCatGroupLearnAndWork => 'Learn & Work';

  @override
  String get bizCatGroupEvents => 'Events';

  @override
  String get bizCatGroupRetail => 'Retail';

  @override
  String get bizCatGroupCommunityAndServices => 'Community & Services';

  @override
  String get gamificationJourneyTitle => 'Your Journey';

  @override
  String gamificationJourneyMilestonesCompleted(int completed, int total) {
    return '$completed of $total milestones completed';
  }

  @override
  String get gamificationJourneyOverallProgress => 'Overall Progress';

  @override
  String get gamificationJourneyNoMilestones => 'No milestones yet';

  @override
  String get gamificationJourneyCompletePrevious =>
      'Complete previous categories to unlock';

  @override
  String get gamificationJourneyTabStart => 'Start';

  @override
  String get gamificationJourneyTabMaster => 'Master';

  @override
  String get gamificationJourneyCatGettingStarted => 'Getting Started';

  @override
  String get gamificationJourneyCatSocializing => 'Socializing';

  @override
  String get gamificationJourneyCatMastery => 'Mastery';

  @override
  String get gamificationJourneyCatGettingStartedDesc =>
      'Complete your profile and get familiar with the app';

  @override
  String get gamificationJourneyCatSocializingDesc =>
      'Connect with others and build relationships';

  @override
  String get gamificationJourneyCatPremiumDesc =>
      'Unlock premium features and rewards';

  @override
  String get gamificationJourneyCatMasteryDesc =>
      'Become a master of the dating game';

  @override
  String get gamificationJourneyCatSpecialDesc =>
      'Exclusive milestones and achievements';

  @override
  String get gamificationJourneyCompleteProfileName => 'Profile Pro';

  @override
  String get gamificationJourneyCompleteProfileDesc =>
      'Complete your profile 100%';

  @override
  String get gamificationJourneyAddPhotosName => 'Picture Perfect';

  @override
  String get gamificationJourneyAddPhotosDesc => 'Add 5 photos to your profile';

  @override
  String get gamificationJourneyGetVerifiedName => 'Verified User';

  @override
  String get gamificationJourneyGetVerifiedDesc =>
      'Complete photo verification';

  @override
  String get gamificationJourneyFirstMatchName => 'First Connection';

  @override
  String get gamificationJourneyFirstMatchDesc => 'Get your first match';

  @override
  String get gamificationJourneyTenMatchesName => 'Rising Star';

  @override
  String get gamificationJourneyTenMatchesDesc => 'Get 10 matches';

  @override
  String get gamificationJourneyFiftyMatchesName => 'Social Butterfly';

  @override
  String get gamificationJourneyFiftyMatchesDesc => 'Get 50 matches';

  @override
  String get gamificationJourneyFirstMessageName => 'Ice Breaker';

  @override
  String get gamificationJourneyFirstMessageDesc => 'Send your first message';

  @override
  String get gamificationJourneyHundredMessagesName => 'Conversation King';

  @override
  String get gamificationJourneyHundredMessagesDesc => 'Send 100 messages';

  @override
  String get gamificationJourneyFirstVideoCallName => 'Face to Face';

  @override
  String get gamificationJourneyFirstVideoCallDesc =>
      'Complete your first video call';

  @override
  String get gamificationJourneyTenVideoCallsName => 'Video Pro';

  @override
  String get gamificationJourneyTenVideoCallsDesc => 'Complete 10 video calls';

  @override
  String get gamificationJourneyWeekStreakName => 'Dedicated User';

  @override
  String get gamificationJourneyWeekStreakDesc =>
      'Maintain a 7-day login streak';

  @override
  String get gamificationJourneyMonthStreakName => 'Super Dedicated';

  @override
  String get gamificationJourneyMonthStreakDesc =>
      'Maintain a 30-day login streak';

  @override
  String get gamificationJourneyUpgradeSilverName => 'Silver Member';

  @override
  String get gamificationJourneyUpgradeSilverDesc => 'Upgrade to Silver VIP';

  @override
  String get gamificationJourneyUpgradeGoldName => 'Gold Member';

  @override
  String get gamificationJourneyUpgradeGoldDesc => 'Upgrade to Gold VIP';

  @override
  String get gamificationJourneyUpgradePlatinumName => 'Platinum Member';

  @override
  String get gamificationJourneyUpgradePlatinumDesc =>
      'Upgrade to Platinum VIP';

  @override
  String get gamificationJourneyTenAchievementsName => 'Achievement Hunter';

  @override
  String get gamificationJourneyTenAchievementsDesc => 'Earn 10 achievements';

  @override
  String get gamificationJourneyFiftyAchievementsName => 'Achievement Master';

  @override
  String get gamificationJourneyFiftyAchievementsDesc => 'Earn 50 achievements';

  @override
  String get gamificationJourneyHundredMatchesName => 'Centurion';

  @override
  String get gamificationJourneyHundredMatchesDesc => 'Get 100 matches';

  @override
  String get gamificationStreakMilestone3Name => 'Getting Started';

  @override
  String get gamificationStreakMilestone7Name => 'Week Warrior';

  @override
  String get gamificationStreakMilestone14Name => 'Two Week Champ';

  @override
  String get gamificationStreakMilestone30Name => 'Monthly Master';

  @override
  String get gamificationStreakMilestone60Name => 'Two Month Champion';

  @override
  String get gamificationStreakMilestone90Name => 'Quarter Year Legend';

  @override
  String get gamificationStreakMilestone180Name => 'Half Year Hero';

  @override
  String get gamificationStreakMilestone365Name => 'Year of Love';

  @override
  String gamificationStreakMilestoneDesc(int days) {
    return 'Log in for $days consecutive days';
  }

  @override
  String get gamificationChallengeSend3MessagesName => 'Quick Chat';

  @override
  String get gamificationChallengeSend3MessagesDesc => 'Send 3 messages';

  @override
  String get gamificationChallengeSend5MessagesName => 'Message Master';

  @override
  String get gamificationChallengeSend5MessagesDesc =>
      'Send 5 messages to your matches';

  @override
  String get gamificationChallengeSend10MessagesName => 'Conversation King';

  @override
  String get gamificationChallengeSend10MessagesDesc =>
      'Send 10 messages today';

  @override
  String get gamificationChallengeSend15MessagesName => 'Chat Marathon';

  @override
  String get gamificationChallengeSend15MessagesDesc =>
      'Send 15 messages today';

  @override
  String get gamificationChallengeGet1MatchName => 'First Spark';

  @override
  String get gamificationChallengeGet1MatchDesc => 'Get 1 new match today';

  @override
  String get gamificationChallengeGet3MatchesName => 'Match Maker';

  @override
  String get gamificationChallengeGet3MatchesDesc => 'Get 3 new matches today';

  @override
  String get gamificationChallengeGet5MatchesName => 'Love Magnet';

  @override
  String get gamificationChallengeGet5MatchesDesc => 'Get 5 new matches today';

  @override
  String get gamificationChallengeSend1SuperlikeName => 'Priority Pick';

  @override
  String get gamificationChallengeSend1SuperlikeDesc => 'Send 1 super like';

  @override
  String get gamificationChallengeSend3SuperlikesName => 'Super Liker';

  @override
  String get gamificationChallengeSend3SuperlikesDesc => 'Send 3 super likes';

  @override
  String get gamificationChallengeSend5SuperlikesName => 'Super Star';

  @override
  String get gamificationChallengeSend5SuperlikesDesc => 'Send 5 super likes';

  @override
  String get gamificationChallengeVideoCall1Name => 'Video Enthusiast';

  @override
  String get gamificationChallengeVideoCall1Desc => 'Complete 1 video call';

  @override
  String get gamificationChallengeVideoCall2Name => 'Video Pro';

  @override
  String get gamificationChallengeVideoCall2Desc => 'Complete 2 video calls';

  @override
  String get gamificationChallengeAddPhotoName => 'Photo Refresh';

  @override
  String get gamificationChallengeAddPhotoDesc =>
      'Add or update a profile photo';

  @override
  String get gamificationChallengeAdd2PhotosName => 'Photo Gallery';

  @override
  String get gamificationChallengeAdd2PhotosDesc => 'Add 2 new profile photos';

  @override
  String get gamificationChallengeSend1GiftName => 'Gift Giver';

  @override
  String get gamificationChallengeSend1GiftDesc => 'Send 1 gift to a match';

  @override
  String get gamificationChallengeSend3GiftsName => 'Generous Heart';

  @override
  String get gamificationChallengeSend3GiftsDesc => 'Send 3 gifts today';

  @override
  String get gamificationChallengeSend5GiftsName => 'Gift Master';

  @override
  String get gamificationChallengeSend5GiftsDesc => 'Send 5 gifts today';

  @override
  String get gamificationChallengeChatStarterName => 'Ice Breaker';

  @override
  String get gamificationChallengeChatStarterDesc =>
      'Send 7 messages to different matches';

  @override
  String get gamificationChallengeSocialButterflyName => 'Social Butterfly';

  @override
  String get gamificationChallengeSocialButterflyDesc =>
      'Send 20 messages today';

  @override
  String get gamificationChallengeMatchRushName => 'Match Rush';

  @override
  String get gamificationChallengeMatchRushDesc => 'Get 7 matches today';

  @override
  String get gamificationChallengeVideoMarathonName => 'Video Marathon';

  @override
  String get gamificationChallengeVideoMarathonDesc => 'Complete 3 video calls';

  @override
  String get gamificationChallengeWeeklyMessages30Name => 'Chat Enthusiast';

  @override
  String get gamificationChallengeWeeklyMessages30Desc =>
      'Send 30 messages this week';

  @override
  String get gamificationChallengeWeeklyMessages50Name => 'Chat Master';

  @override
  String get gamificationChallengeWeeklyMessages50Desc =>
      'Send 50 messages this week';

  @override
  String get gamificationChallengeWeeklyMessages100Name => 'Chat Legend';

  @override
  String get gamificationChallengeWeeklyMessages100Desc =>
      'Send 100 messages this week';

  @override
  String get gamificationChallengeWeeklyMatches10Name => 'Weekly Connector';

  @override
  String get gamificationChallengeWeeklyMatches10Desc =>
      'Get 10 matches this week';

  @override
  String get gamificationChallengeWeeklyMatches20Name =>
      'Weekly Match Champion';

  @override
  String get gamificationChallengeWeeklyMatches20Desc =>
      'Get 20 matches this week';

  @override
  String get gamificationChallengeWeeklyMatches30Name => 'Match Machine';

  @override
  String get gamificationChallengeWeeklyMatches30Desc =>
      'Get 30 matches this week';

  @override
  String get gamificationChallengeWeeklySuperlikes5Name => 'Weekly Super Liker';

  @override
  String get gamificationChallengeWeeklySuperlikes5Desc =>
      'Send 5 super likes this week';

  @override
  String get gamificationChallengeWeeklySuperlikes10Name => 'Super Fan';

  @override
  String get gamificationChallengeWeeklySuperlikes10Desc =>
      'Send 10 super likes this week';

  @override
  String get gamificationChallengeWeeklySuperlikes15Name => 'Priority King';

  @override
  String get gamificationChallengeWeeklySuperlikes15Desc =>
      'Send 15 super likes this week';

  @override
  String get gamificationChallengeWeeklyVideo3Name => 'Video Socialite';

  @override
  String get gamificationChallengeWeeklyVideo3Desc =>
      'Complete 3 video calls this week';

  @override
  String get gamificationChallengeWeeklyVideo5Name => 'Video Star';

  @override
  String get gamificationChallengeWeeklyVideo5Desc =>
      'Complete 5 video calls this week';

  @override
  String get gamificationChallengeWeeklyGifts5Name => 'Weekly Gift Giver';

  @override
  String get gamificationChallengeWeeklyGifts5Desc => 'Send 5 gifts this week';

  @override
  String get gamificationChallengeWeeklyGifts10Name => 'Generous Soul';

  @override
  String get gamificationChallengeWeeklyGifts10Desc =>
      'Send 10 gifts this week';

  @override
  String get gamificationChallengeWeeklyPhotos3Name => 'Photo Week';

  @override
  String get gamificationChallengeWeeklyPhotos3Desc => 'Add 3 photos this week';

  @override
  String get gamificationChallengeWeeklyPerfectName => 'Perfect Week';

  @override
  String get gamificationChallengeWeeklyPerfectDesc =>
      'Complete all daily challenges 7 days in a row';

  @override
  String get gamificationChallengeValentineMatchesName => 'Love Connections';

  @override
  String get gamificationChallengeValentineMatchesDesc =>
      'Get 14 matches during Valentine’s Week (1 per day)';

  @override
  String get gamificationChallengeValentineVideoName => 'Virtual Date Night';

  @override
  String get gamificationChallengeValentineVideoDesc =>
      'Complete 3 video calls';

  @override
  String get gamificationChallengeSummerMatchesName => 'Beach Vibes';

  @override
  String get gamificationChallengeSummerMatchesDesc =>
      'Get 30 matches this summer';

  @override
  String get gamificationChallengeHolidayGiftsName => 'Gift Giver';

  @override
  String get gamificationChallengeHolidayGiftsDesc =>
      'Send 10 coin gifts to matches';

  @override
  String get gamificationChallengeHolidayMessagesName => 'Holiday Cheer';

  @override
  String get gamificationChallengeHolidayMessagesDesc => 'Send 100 messages';

  @override
  String get gamificationEventValentinesName => 'Valentine’s Week';

  @override
  String get gamificationEventValentinesDesc =>
      'Spread the love this Valentine’s Week!';

  @override
  String get gamificationEventSummerName => 'Summer Love';

  @override
  String get gamificationEventSummerDesc => 'Find your summer romance!';

  @override
  String get gamificationEventHolidayName => 'Holiday Season';

  @override
  String get gamificationEventHolidayDesc => 'Find love this holiday season!';

  @override
  String get travelExploreTitle => 'Travel Explore';

  @override
  String get travelExploreInMyCity => 'In my city';

  @override
  String get travelExploreWorldwide => 'Worldwide';

  @override
  String travelExploreTravelersIn(String city) {
    return 'Travelers in $city';
  }

  @override
  String get travelExploreUnknownLocation => 'Unknown location';

  @override
  String get travelExploreLocalGuides => 'Local Guides';

  @override
  String get travelExploreCities => 'Cities';

  @override
  String travelExploreGuideIn(String city) {
    return 'Guide in $city';
  }

  @override
  String travelExploreNoTravelersInCity(String city) {
    return 'No travelers in $city right now';
  }

  @override
  String get travelExploreNoTravelers => 'No travelers found';

  @override
  String get travelExploreTryWorldwide =>
      'Try switching to Worldwide to see all travelers';

  @override
  String get travelExploreCheckBack => 'Check back later for active travelers';

  @override
  String get travelExploreShowWorldwide => 'Show Worldwide';

  @override
  String get discoveryDealBreakerSmoking => 'Smoking';

  @override
  String get discoveryDealBreakerDrinking => 'Drinking';

  @override
  String get discoveryDealBreakerNoBio => 'No bio';

  @override
  String get discoveryDealBreakerNoPhotos => 'No photos';

  @override
  String get discoveryDealBreakerDifferentReligion => 'Different religion';

  @override
  String get discoveryDealBreakerDifferentPolitics => 'Different politics';

  @override
  String get discoveryDealBreakerHasChildren => 'Has children';

  @override
  String get discoveryDealBreakerWantsChildren => 'Wants children';

  @override
  String get discoveryDealBreakerLongDistance => 'Long distance';

  @override
  String get discoveryDealBreakerNonMonogamy => 'Non-monogamy';

  @override
  String discoveryPrefCountryUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users',
      one: '1 user',
    );
    return '$_temp0';
  }

  @override
  String get discoveryGridAuto => 'Auto';

  @override
  String get discoveryMatchFallbackName => 'Match';

  @override
  String get discoveryThisUser => 'this user';

  @override
  String get discoveryActionNope => 'Nope';

  @override
  String get exploreTierTester => 'Tester';

  @override
  String get chatCulturalContextTitle => 'Cultural Context';

  @override
  String get chatCulturalContextLink => 'Cultural context';

  @override
  String get chatWordBreakdownTierRequired =>
      'Word breakdown is available for Silver, Gold, and Platinum members';

  @override
  String get chatPreviewSticker => 'Sticker';

  @override
  String get chatPreviewVoiceMessage => 'Voice message';

  @override
  String get chatPreviewAlbumShared => 'Album shared';

  @override
  String get chatPreviewAlbumRevoked => 'Album revoked';

  @override
  String get chatPreviewEvent => 'Event';

  @override
  String get chatPreviewSayHi => 'Say hi to your match!';

  @override
  String chatTimeShortMinutes(int count) {
    return '${count}m';
  }

  @override
  String chatTimeShortHours(int count) {
    return '${count}h';
  }

  @override
  String chatTimeShortDays(int count) {
    return '${count}d';
  }

  @override
  String get chatNotificationsMutedForChat =>
      'Notifications muted for this chat';

  @override
  String get chatNotificationsUnmuted => 'Notifications unmuted';

  @override
  String get chatMuteNotifications => 'Mute notifications';

  @override
  String get chatUnmuteNotifications => 'Unmute notifications';

  @override
  String chatAlbumSelectCount(int count) {
    return 'Select ($count)';
  }

  @override
  String chatAlbumPhotosSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos selected',
      one: '1 photo selected',
    );
    return '$_temp0';
  }

  @override
  String chatSessionXp(int xp) {
    return '$xp XP';
  }

  @override
  String get chatPhraseHowAreYou => 'How are you?';

  @override
  String get chatPhraseGoodMorning => 'Good morning!';

  @override
  String get chatPhraseAllGood => 'All good?';

  @override
  String get chatPhrasePleasedToMeetYou => 'Pleased to meet you!';

  @override
  String get chatPhraseNiceToMeetYou => 'Nice to meet you!';

  @override
  String get chatPhraseWhatsUp => 'What\'s up?';

  @override
  String get chatSupportAiBadge => 'AI';

  @override
  String get chatGroupFallbackName => 'Group';

  @override
  String get communitiesTypeLanguageCircle => 'Language Circle';

  @override
  String get communitiesTypeCulturalInterest => 'Cultural Interest';

  @override
  String get communitiesTypeTravelGroup => 'Travel Group';

  @override
  String get communitiesTypeLocalGuides => 'Local Guides';

  @override
  String get communitiesTypeStudyGroup => 'Study Group';

  @override
  String get communitiesTypeGeneral => 'General';

  @override
  String get communitiesRoleOwner => 'Owner';

  @override
  String get communitiesRoleAdmin => 'Admin';

  @override
  String get communitiesRoleMember => 'Member';

  @override
  String get communitiesNoActivityYet => 'No activity yet';

  @override
  String get communitiesLanguageMandarin => 'Mandarin';

  @override
  String get communitiesLanguageThai => 'Thai';

  @override
  String get communitiesLanguageVietnamese => 'Vietnamese';

  @override
  String get communitiesLanguageCatalan => 'Catalan';

  @override
  String get communitiesLanguageHebrew => 'Hebrew';

  @override
  String get videoPromptSelectorTitle => 'Choose a Prompt';

  @override
  String get videoPromptSelectorSubtitle =>
      'Pick a topic for your video introduction';

  @override
  String get videoPromptIntroduceTitle => 'Introduce yourself';

  @override
  String get videoPromptIntroduceDesc => 'Say hello and tell us who you are';

  @override
  String get videoPromptIntroduceTemplate =>
      'Introduce yourself in your favorite language';

  @override
  String get videoPromptNativeTitle => 'Native language';

  @override
  String get videoPromptNativeDesc => 'Show off your mother tongue';

  @override
  String get videoPromptNativeTemplate =>
      'Say something in your native language';

  @override
  String get videoPromptTeachTitle => 'Teach a phrase';

  @override
  String get videoPromptTeachDesc => 'Share something fun to say';

  @override
  String get videoPromptTeachTemplate => 'Teach us a phrase in your language';

  @override
  String get videoPromptPlaceTitle => 'Favorite place';

  @override
  String get videoPromptPlaceDesc =>
      'Share a place that means something to you';

  @override
  String get videoPromptPlaceTemplate =>
      'What\'s your favorite place to visit?';

  @override
  String get videoPromptCultureTitle => 'Cultural exchange';

  @override
  String get videoPromptCultureDesc =>
      'What does cultural exchange mean to you?';

  @override
  String get videoPromptCultureTemplate =>
      'Describe your ideal cultural exchange';

  @override
  String get videoPromptTalentTitle => 'Hidden talent';

  @override
  String get videoPromptTalentDesc => 'Surprise us with something unexpected';

  @override
  String get videoPromptTalentTemplate =>
      'Show us a hidden talent or fun fact about you';

  @override
  String get videoPromptTripTitle => 'Dream trip';

  @override
  String get videoPromptTripDesc => 'Where in the world would you go?';

  @override
  String get videoPromptTripTemplate =>
      'Describe your dream travel destination';

  @override
  String get videoPromptFreeTitle => 'Free style';

  @override
  String get videoPromptFreeDesc => 'Say whatever you want!';

  @override
  String get videoPromptFreeTemplate => 'Free style - no prompt';

  @override
  String get videoDiscoveryLiked => 'Liked!';

  @override
  String get videoDiscoveryPassed => 'Passed';

  @override
  String get videoDiscoveryTitle => 'Video Intros';

  @override
  String get videoDiscoveryEmptyTitle => 'No video introductions yet';

  @override
  String get videoDiscoveryEmptySubtitle => 'Be the first to create one!';

  @override
  String videoDiscoveryUserFallback(String id) {
    return 'User $id';
  }

  @override
  String videoDiscoveryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count views',
      one: '1 view',
    );
    return '$_temp0';
  }

  @override
  String get videoDiscoveryLike => 'Like';

  @override
  String get videoDiscoveryPass => 'Pass';

  @override
  String get videoDiscoveryReport => 'Report';

  @override
  String get videoDiscoveryMute => 'Mute';

  @override
  String get videoDiscoveryUnmute => 'Unmute';

  @override
  String get videoProfileUploadSuccess => 'Video uploaded successfully!';

  @override
  String get videoProfileDeleteTitle => 'Delete Video?';

  @override
  String get videoProfileDeleteConfirm =>
      'Are you sure you want to delete your video introduction?';

  @override
  String get videoProfileDeleted => 'Video deleted';

  @override
  String get videoProfileScreenTitle => 'Video Introduction';

  @override
  String get videoProfileFirstImpression => 'Make a great first impression!';

  @override
  String videoProfileInfoBody(int seconds) {
    return 'Record a $seconds second video to introduce yourself. Profiles with videos get 40% more matches!';
  }

  @override
  String get videoProfileNoVideo => 'No video yet';

  @override
  String videoProfileMaxSeconds(int seconds) {
    return 'Max $seconds seconds';
  }

  @override
  String get videoProfileRecord => 'Record Video';

  @override
  String get videoProfileUploadFromGallery => 'Upload from Gallery';

  @override
  String get videoProfileSave => 'Save Video';

  @override
  String get videoProfileRecordAgain => 'Record Again';

  @override
  String get videoProfileTipsTitle => 'Tips for a great video:';

  @override
  String get videoProfileTipLighting =>
      'Good lighting - face a window or light source';

  @override
  String get videoProfileTipVertical => 'Hold your phone vertically';

  @override
  String get videoProfileTipSmile => 'Smile and be yourself!';

  @override
  String get videoProfileTipSpeak => 'Speak clearly - introduce yourself';

  @override
  String get videoProfileTipHobbies => 'Mention your hobbies or interests';

  @override
  String adminVerificationBulkBetterPhotoTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users',
      one: '1 user',
    );
    return 'Request Better Photo ($_temp0)';
  }

  @override
  String adminVerificationBulkApproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verifications approved',
      one: '1 verification approved',
    );
    return '$_temp0';
  }

  @override
  String adminVerificationBulkBetterPhotoRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Better photo requested for $count users',
      one: 'Better photo requested for 1 user',
    );
    return '$_temp0';
  }

  @override
  String get adminPreSaleTitle => 'Pre-Sale Management';

  @override
  String get adminPreSaleProgramTitle => 'Pre-Sale Tier Program';

  @override
  String get adminPreSaleProgramDescription =>
      'Manage pre-sale users with tier-based countdown and subscription duration.';

  @override
  String adminPreSaleCsvFormatHint(String columns, String tiers) {
    return 'CSV format: $columns\nTier values: $tiers';
  }

  @override
  String get adminPreSaleAddSingleEntry => 'Add Single Entry';

  @override
  String get adminPreSaleEntries => 'Pre-Sale Entries';

  @override
  String get adminPreSaleAllTiers => 'All Tiers';

  @override
  String get adminPreSaleNoMatching => 'No matching entries found';

  @override
  String get adminPreSaleEmpty =>
      'No pre-sale entries yet.\nUpload a CSV to get started.';

  @override
  String adminPreSaleDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String adminPreSaleEntryAdded(String email, String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$email added as $tier ($_temp0)';
  }

  @override
  String get adminPreSaleRemoveEntryTitle => 'Remove Entry';

  @override
  String adminPreSaleRemoveEntryConfirm(String email) {
    return 'Remove $email from the pre-sale list?';
  }

  @override
  String adminPreSaleEntryRemoved(String email) {
    return '$email removed from pre-sale list';
  }

  @override
  String get adminPreSaleCsvEmpty => 'CSV file is empty';

  @override
  String adminPreSaleCsvMissingHeaders(String expected, String found) {
    return 'CSV must have headers: $expected\nFound: $found';
  }

  @override
  String get adminPreSaleCsvNoRows => 'No valid data rows found in CSV';

  @override
  String get adminPreSaleInvalidDays => 'Please enter a valid number of days';

  @override
  String get adminPreSaleInfoTitle => 'Pre-Sale Info';

  @override
  String get adminPreSaleCsvFormatTitle => 'CSV Format';

  @override
  String get adminPreSaleCountdownDates => 'Tier Countdown Dates';

  @override
  String get adminPreSaleHowItWorks => 'How it works';

  @override
  String get adminPreSaleHowItWorksSteps =>
      '1. User registers with email\n2. App checks pre-sale list\n3. Countdown shows tier date\n4. After countdown: subscription activates\n5. Duration = NUMBER_OF_DAYS from list\n6. Base membership = same expiry';

  @override
  String get adminStatusProcessing => 'Processing';

  @override
  String get adminStatusCompleted => 'Completed';

  @override
  String get adminStatusFailed => 'Failed';

  @override
  String get adminStatusCancelled => 'Cancelled';

  @override
  String get adminStatusRefunded => 'Refunded';

  @override
  String get adminStatusDraft => 'Draft';

  @override
  String get adminStatusIssued => 'Issued';

  @override
  String get adminStatusPaid => 'Paid';

  @override
  String get adminStatusOverdue => 'Overdue';

  @override
  String get adminOrderTypeCoins => 'Coins Purchase';

  @override
  String get adminOrderTypeSubscription => 'Subscription';

  @override
  String get adminOrderTypeGift => 'Gift Purchase';

  @override
  String get adminRoleSuperAdmin => 'Super Admin';

  @override
  String get adminRoleModerator => 'Moderator';

  @override
  String get adminRoleAnalyst => 'Analyst';

  @override
  String get cityPickerTitle => 'Pick a city';

  @override
  String get cityPickerSearchHint => 'Search a city…';

  @override
  String get cityPickerEmptyHint => 'Search a city or tap the map';

  @override
  String get cityPickerUseCity => 'Use this city';

  @override
  String get notifServerViewedYourProfile => 'viewed your profile';

  @override
  String get notifServerStartedFollowingYou => 'started following you';

  @override
  String get notifServerStartedFollowingBusiness =>
      'started following your business';

  @override
  String get notifServerRatedYourBusiness => 'rated your business';

  @override
  String notifServerRatedYourBusinessStars(int stars) {
    return 'rated your business $stars★';
  }

  @override
  String get notifServerReviewedYourExperience => 'reviewed your experience';

  @override
  String get notifServerTapToSeeWhoStoppedBy => 'Tap to see who stopped by';

  @override
  String get notifServerTapToSeeTheirProfile => 'Tap to see their profile';

  @override
  String get notifServerNewFollower => 'You have a new follower';

  @override
  String get notifServerNewRating => 'You have a new rating';

  @override
  String get notifServerYourCommunity => 'Your community';

  @override
  String get notifServerYourEvent => 'Your event';

  @override
  String get notifServerProfileBoostLive => 'Your profile boost is now live';

  @override
  String get notifServerProfileBoostEnded => 'Your profile boost has ended';

  @override
  String get notifServerProfilePromoted =>
      'Your profile is being promoted to more people';

  @override
  String get notifServerEventPromoted =>
      'Your event is being promoted in Explore';

  @override
  String get notifServerBoostAgainProfile =>
      'Boost again to keep reaching more people';

  @override
  String get notifServerBoostAgainEvent => 'Boost again to keep it featured';

  @override
  String get notifServerCheckedIn => 'You\'re checked in — enjoy!';

  @override
  String get notifServerTicketReady => 'Your ticket is ready';

  @override
  String get notifServerTicketSold => 'Ticket sold';

  @override
  String get notifServerPaymentToConfirm => 'Payment to confirm';

  @override
  String get notifServerPaymentNotConfirmed => 'Payment not confirmed';

  @override
  String get notifServerPaymentsWaiting =>
      'Payments waiting for your confirmation';

  @override
  String get notifServerTicketRefunded => 'Ticket refunded';

  @override
  String get notifServerTicketDisputed => 'Ticket payment disputed';

  @override
  String get notifServerRefundToPayBack => 'Refund to pay back';

  @override
  String get notifServerTicketReservationExpired =>
      'Ticket reservation expired';

  @override
  String get notifServerExperienceHidden =>
      'Your experience was hidden after several reports';

  @override
  String get notifServerPendingReview => 'Pending review by GreenGo';

  @override
  String get notifServerMonthlyCoinsAdded => 'Monthly coins added';

  @override
  String get notifServerSupportReplied => 'Support replied to your ticket';

  @override
  String get notifServerSupportNewReply => 'You have a new reply from support.';

  @override
  String get notifServerIncognitoExpiring => 'Incognito Mode Expiring Soon';

  @override
  String get notifServerIncognitoExpiringBody =>
      'Your Incognito Mode expires in less than 1 hour!';

  @override
  String get notifServerTravelerExpiring => 'Traveler Mode Expiring Soon';

  @override
  String get notifServerTravelerExpiringBody =>
      'Your Traveler Mode expires in less than 1 hour!';

  @override
  String get notifServerProfileVerified => 'Profile Verified!';

  @override
  String get notifServerProfileVerifiedBody =>
      'Your profile has been verified! You now have a verified badge.';

  @override
  String get notifServerNewVerificationPhoto => 'New Verification Photo Needed';

  @override
  String get notifServerVerificationUpdate => 'Verification Update';

  @override
  String notifServerJoinedYourCommunity(String name) {
    return 'joined your community $name';
  }

  @override
  String notifServerJoinedYourEvent(String name) {
    return 'joined your event $name';
  }

  @override
  String notifServerLikedYourEvent(String name) {
    return 'liked your event $name';
  }

  @override
  String notifServerJoinedYourGroup(String name) {
    return 'joined your group $name';
  }

  @override
  String notifServerAddedYouAsCoOwner(String name) {
    return 'added you as a co-owner of $name';
  }

  @override
  String notifServerAddedYouToGroup(String name) {
    return 'added you to $name';
  }

  @override
  String notifServerEventBoostLive(String name) {
    return 'Your event $name boost is now live';
  }

  @override
  String notifServerEventBoostEnded(String name) {
    return 'Your event $name boost has ended';
  }

  @override
  String notifServerTicketScanned(String name) {
    return 'Your ticket for $name was scanned';
  }

  @override
  String notifServerNewEventIn(String name) {
    return 'New event in $name';
  }

  @override
  String notifServerEventCancelledIn(String name) {
    return 'Event cancelled in $name';
  }

  @override
  String notifServerEventUpdatedIn(String name) {
    return 'Event updated in $name';
  }

  @override
  String notifServerNewEventFrom(String name) {
    return 'New event from $name';
  }

  @override
  String notifServerAnnouncement(String name) {
    return 'Announcement · $name';
  }

  @override
  String get culturalExchangeCategoryFood => 'Food';

  @override
  String get culturalExchangeCategoryTransportation => 'Transportation';

  @override
  String get culturalExchangeCategoryDating => 'Dating';

  @override
  String get culturalExchangeCategoryCustoms => 'Customs';

  @override
  String get culturalExchangeCategoryLanguage => 'Language';

  @override
  String get culturalExchangeCategorySafety => 'Safety';

  @override
  String get culturalExchangeSectionCuisine => 'Cuisine';

  @override
  String get culturalExchangeSectionCustoms => 'Customs';

  @override
  String get culturalExchangeSectionKeyPhrases => 'Key Phrases';

  @override
  String get culturalExchangeSectionPhrases => 'Phrases';

  @override
  String get culturalExchangeSpotlightBadge => 'SPOTLIGHT';

  @override
  String get culturalExchangeContentComingSoon => 'Content coming soon';

  @override
  String get culturalExchangeContentComingSoonBody =>
      'We are preparing detailed content for this spotlight.';

  @override
  String get culturalExchangeLike => 'Like';

  @override
  String culturalExchangeWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String culturalExchangeMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String get culturalExchangeDailyInsightJapanBow =>
      'In Japan, it is customary to bow when greeting someone. The deeper the bow, the more respect you show.';

  @override
  String get culturalExchangeSelectCountry => 'Select a Country';

  @override
  String get culturalExchangeChooseCountry => 'Choose a country...';

  @override
  String get culturalExchangeSelectCountryAbove => 'Select a country above';

  @override
  String get culturalExchangeLearnEtiquette =>
      'Learn dating etiquette from 20+ countries\naround the world';

  @override
  String get culturalExchangeDos => 'Do\'s';

  @override
  String get culturalExchangeDonts => 'Don\'ts';

  @override
  String get notifNewConversationTitle => 'New Conversation';

  @override
  String notifNewMessageFrom(String name) {
    return 'New message from $name';
  }

  @override
  String notifStartedConversation(String name) {
    return '$name started a conversation with you.';
  }

  @override
  String get notifNewPhotoLikeTitle => 'New Photo Like';

  @override
  String notifLikedYourPhoto(String name) {
    return '$name liked your photo';
  }

  @override
  String get notifCoinsReceivedTitle => 'You received coins!';

  @override
  String chatSystemCoinsReceived(String name, int amount) {
    return '$name sent you $amount coins!';
  }

  @override
  String chatSystemCoinsSent(int amount) {
    return 'I just sent you $amount coins!';
  }

  @override
  String chatSystemSupportWelcome(String subject) {
    return 'Welcome to GreenGo Support! A support agent will be with you shortly. Your ticket: $subject';
  }

  @override
  String chatSystemSupportAgentJoined(String name) {
    return '$name has joined the conversation and will assist you.';
  }

  @override
  String get chatSystemSupportAgentFallback => 'Support agent';

  @override
  String get chatSystemSupportInProgress =>
      'A support agent is working on your issue.';

  @override
  String get chatSystemSupportWaitingOnUser =>
      'We\'re waiting for your response.';

  @override
  String get chatSystemSupportResolved =>
      'Your issue has been resolved. Thank you for contacting GreenGo Support!';

  @override
  String get chatSystemSupportClosed => 'This support ticket has been closed.';

  @override
  String get chatSystemSupportStatusUpdated => 'Ticket status updated.';

  @override
  String get commonUnknownUser => 'Unknown user';

  @override
  String get chatSupportDescription => 'Description';

  @override
  String get supportReportFollowUpTitle => 'Report follow-up';

  @override
  String supportReportFollowUpSubject(String reason) {
    return 'Report follow-up: $reason';
  }

  @override
  String supportReportFollowUpDetails(
      String reason, String message, String user, String date) {
    return 'Reason: $reason\nReported message: \"$message\"\nReported user: $user\nReported at: $date';
  }

  @override
  String get supportChatWithGreenGoSubject => 'Chat with GreenGo Support';

  @override
  String invoiceLineCoins(int count) {
    return '$count GreenGo Coins';
  }

  @override
  String get invoiceLineSubscription => 'Subscription plan';

  @override
  String get invoiceLineGiftPackage => 'Coin gift package';

  @override
  String get srvSomeone => 'Someone';

  @override
  String get srvJoinedYourCommunity => 'joined your community';

  @override
  String get srvJoinedYourEvent => 'joined your event';

  @override
  String get srvLikedYourEvent => 'liked your event';

  @override
  String get srvJoinedYourGroup => 'joined your group';

  @override
  String get srvAddedYouToAGroup => 'added you to a group';

  @override
  String get srvGroup => 'Group';

  @override
  String srvGroupMembersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members left the group',
      one: 'A member left the group',
    );
    return '$_temp0';
  }

  @override
  String get srvTicketScanned => 'Your ticket was scanned';

  @override
  String get srvEventBoostLive => 'Your event boost is now live';

  @override
  String get srvEventBoostEnded => 'Your event boost has ended';

  @override
  String get srvAddedYouAsCoOwnerOfEvent =>
      'added you as a co-owner of an event';

  @override
  String get srvAnEvent => 'An event';

  @override
  String srvPaymentsWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String get srvNewReview => 'New review';

  @override
  String get srvMentionedYouInReviewReply => 'mentioned you in a review reply';

  @override
  String get srvRepliedToYourReview => 'replied to your review';

  @override
  String get srvExperience => 'Experience';

  @override
  String get srvBookingRequested => 'requested to book your experience';

  @override
  String get srvBookingBooked => 'booked your experience';

  @override
  String get srvBookingConfirmed => 'Booking confirmed';

  @override
  String get srvBookingAccepted => 'accepted your booking request';

  @override
  String get srvBookingDeclined => 'declined your booking request';

  @override
  String get srvBookingCancelledTheirs => 'cancelled their booking';

  @override
  String get srvBookingCancelledYours => 'cancelled your booking';

  @override
  String srvBookingRefundOwed(String title, int percent) {
    return '$title — refund owed: $percent%.';
  }

  @override
  String get srvBookingCheckedIn => 'You are checked in';

  @override
  String get srvBookingCancelledByHost =>
      'Your booking was cancelled by the host';

  @override
  String srvBookingCancelledByHostBody(String title) {
    return '$title — the time is no longer available. Any payment is refunded.';
  }

  @override
  String get srvBookingNoShow => 'marked you as a no-show';

  @override
  String srvBookingNoShowBody(String title, int hours) {
    return '$title — you can contest this within $hours h of the end.';
  }

  @override
  String get srvBookingGuestSaysPaid => 'says they paid for their booking';

  @override
  String get srvBookingPaymentConfirmed => 'confirmed your payment';

  @override
  String get srvBookingProblemReported =>
      'reported a problem with their booking';

  @override
  String get srvBookingReportReviewed => 'Your report was reviewed';

  @override
  String get srvBookingHostWarning => 'Warning about one of your bookings';

  @override
  String get srvBookingReportReviewedHost => 'A booking report was reviewed';

  @override
  String srvBookingReviewedBody(String title) {
    return '$title.';
  }

  @override
  String srvBookingReviewedRefundBody(String title, int percent) {
    return '$title. Refund owed: $percent%.';
  }

  @override
  String get srvBookingCancelled => 'Your booking was cancelled';

  @override
  String srvBookingNoLongerAvailable(String title) {
    return '$title is no longer available.';
  }

  @override
  String get srvBookingComingUp => 'Your experience is coming up';

  @override
  String get srvBookingHostingSoon => 'You are hosting soon';

  @override
  String get srvBookingRequestExpired => 'Your booking request expired';

  @override
  String srvBookingRequestExpiredBody(String title) {
    return '$title — the host did not answer in time.';
  }

  @override
  String get srvBookingHowWasIt => 'How was your experience?';

  @override
  String srvBookingReviewIt(String title) {
    return 'Review $title';
  }

  @override
  String get srvBookingReviewGuest => 'Review your guest';

  @override
  String srvBookingPayLink(String title) {
    return '$title — pay the host with their payment link.';
  }

  @override
  String srvBookingPayOnline(String title) {
    return '$title — pay in the app to get your ticket.';
  }

  @override
  String srvBookingPayCash(String title) {
    return '$title — pay the host in cash when you meet.';
  }

  @override
  String get srvHostReviewedYou => 'Your host reviewed you';

  @override
  String get srvHostReviewedYouBody =>
      'Review your experience to see what they said.';

  @override
  String get srvNewReviewFromHost => 'You have a new review from a host';

  @override
  String get srvGuestLeftReview => 'Your guest left a review';

  @override
  String get srvGuestLeftReviewBody =>
      'Review your guest to reveal both reviews.';

  @override
  String get srvSupportNewMessageOnTicket => 'New message on support ticket';

  @override
  String get srvSupportUserSentMessage => 'A user sent a new message.';

  @override
  String get srvVerificationResubmit =>
      'Please submit a new verification photo.';

  @override
  String srvVerificationResubmitReason(String reason) {
    return 'Please submit a new verification photo. Reason: $reason';
  }

  @override
  String get srvVerificationRejected =>
      'Your verification was not approved. Please try again.';

  @override
  String srvVerificationRejectedReason(String reason) {
    return 'Your verification was not approved. Reason: $reason';
  }

  @override
  String srvBundleNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String srvBundleLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people liked your profile',
      one: '1 person liked your profile',
    );
    return '$_temp0';
  }

  @override
  String srvBundleProfileViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profile views',
      one: '1 profile view',
    );
    return '$_temp0';
  }

  @override
  String srvBundleNewConnections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new connections',
      one: '1 new connection',
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
      other: '$count others',
      one: '1 other',
    );
    return '$names and $_temp0';
  }

  @override
  String srvLevelUpTitle(int level) {
    return 'Level Up! You\'re now level $level!';
  }

  @override
  String srvLevelUpBody(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: 'Congratulations! You\'ve earned $coins coins.',
      one: 'Congratulations! You\'ve earned 1 coin.',
    );
    return '$_temp0';
  }

  @override
  String srvAchievementUnlockedTitle(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'First Match',
        'social_butterfly': 'Social Butterfly',
        'popular': 'Popular',
        'video_enthusiast': 'Video Enthusiast',
        'daily_streak_7': '7-Day Streak',
        'daily_streak_30': '30-Day Streak',
        'other': 'New achievement',
      },
    );
    return 'Achievement Unlocked: $_temp0!';
  }

  @override
  String srvAchievementDescription(String achievement) {
    String _temp0 = intl.Intl.selectLogic(
      achievement,
      {
        'first_match': 'Make your first connection',
        'social_butterfly': 'Send 100 messages',
        'popular': 'Make 50 connections',
        'video_enthusiast': 'Complete 10 video calls',
        'daily_streak_7': 'Log in 7 days in a row',
        'daily_streak_30': 'Log in 30 days in a row',
        'other': 'Keep it up!',
      },
    );
    return '$_temp0';
  }

  @override
  String srvChallengeCompletedTitle(String challenge) {
    String _temp0 = intl.Intl.selectLogic(
      challenge,
      {
        'send_5_messages': 'Conversation Starter',
        'get_3_matches': 'Match Maker',
        'complete_profile': 'Profile Perfectionist',
        'video_call_1': 'Face to Face',
        'other': 'Daily challenge',
      },
    );
    return 'Challenge Completed: $_temp0!';
  }

  @override
  String srvChallengeRewardsBody(int xp, int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coins coins',
      one: '1 coin',
    );
    return 'Claim your rewards: $xp XP and $_temp0';
  }

  @override
  String srvSentYouCoins(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'sent you $amount coins',
      one: 'sent you 1 coin',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyFree(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'You received $amount coins with your free membership this month.',
      one: 'You received 1 coin with your free membership this month.',
    );
    return '$_temp0';
  }

  @override
  String srvMonthlyCoinsBodyTier(int amount, String tier) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other:
          'You received $amount coins with your $tier membership this month.',
      one: 'You received 1 coin with your $tier membership this month.',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiringTitle => 'Membership expiring soon';

  @override
  String srvMembershipExpiringBody(String tier, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Your $tier membership expires in $days days. Extend now to keep your premium features!',
      one:
          'Your $tier membership expires in 1 day. Extend now to keep your premium features!',
    );
    return '$_temp0';
  }

  @override
  String get srvMembershipExpiredTitle => 'Membership expired';

  @override
  String get srvMembershipExpiredBody =>
      'Your membership has expired. Purchase a new membership to restore premium features.';

  @override
  String get srvSubscriptionCancelledTitle => 'Subscription cancelled';

  @override
  String get srvSubscriptionEndedBody =>
      'Your membership has ended. You can resubscribe anytime from the Shop.';

  @override
  String get srvPaymentFailedTitle => 'Payment failed';

  @override
  String get srvSubscriptionPaymentFailedBody =>
      'Your subscription payment failed. Please update your payment method to keep your membership active.';

  @override
  String get srvGiftFromGreenGo => 'A gift from GreenGo';

  @override
  String get srvAccountNotApprovedTitle => 'Account not approved';

  @override
  String srvAccountNotApprovedReason(String reason) {
    return 'Your account could not be approved. Reason: $reason';
  }

  @override
  String get srvAccountNotApprovedContactSupport =>
      'Your account could not be approved. Please contact support.';

  @override
  String get srvEvent => 'Event';

  @override
  String get srvNewEvent => 'New event';

  @override
  String get srvEventStartingNow => 'is starting now — enjoy!';

  @override
  String get srvEventStartsIn6h => 'starts in about 6 hours';

  @override
  String get srvEventIsTomorrow => 'is tomorrow — see you there!';

  @override
  String get srvNewEventInYourCommunity => 'New event in your community';

  @override
  String get srvEventCancelledInYourCommunity =>
      'Event cancelled in your community';

  @override
  String get srvEventUpdatedInYourCommunity =>
      'Event updated in your community';

  @override
  String srvEventHasBeenCancelled(String event) {
    return '\"$event\" has been cancelled';
  }

  @override
  String srvEventNewTime(String event) {
    return 'New time for \"$event\"';
  }

  @override
  String srvEventNewLocation(String event) {
    return 'New location for \"$event\"';
  }

  @override
  String srvAnnouncementTitle(String name) {
    return '📣 $name';
  }

  @override
  String get srvAnnouncementACommunity => '📣 A community';

  @override
  String get srvAnnouncementAnEvent => '📣 Event announcement';

  @override
  String get srvReportReviewedTitle => 'Your report was reviewed';

  @override
  String get srvReportReviewedActionTaken =>
      'Thank you for your report. Our team reviewed it and took action under our Community Guidelines.';

  @override
  String get srvReportReviewedNoViolation =>
      'Thank you for your report. Our team reviewed it and found no violation of our Community Guidelines.';

  @override
  String get srvModerationDecisionTitle =>
      'A moderation decision about your account';

  @override
  String get srvModerationDecisionBody =>
      'We took action under our Community Guidelines. Tap to read the reasons and how to appeal.';

  @override
  String get srvNewMessage => 'New message';

  @override
  String get srvGroupCreated => 'Group created';

  @override
  String get srvYouWereAddedToGroup => 'You were added to the group';

  @override
  String srvGroupMembersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new members joined',
      one: 'A new member joined',
    );
    return '$_temp0';
  }

  @override
  String get srvUnknownUser => 'Unknown user';

  @override
  String srvCoinsReceivedBody(String name, int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount coins',
      one: '1 coin',
    );
    return '$name sent you $_temp0!';
  }

  @override
  String get srvNewEventFromFollowedBusiness =>
      'New event from a business you follow';

  @override
  String get srvMessageRemovedByModerator =>
      'This message was removed by a moderator';

  @override
  String get srvSupportAiHandoff =>
      'I understand you’d like to speak with a human agent. I’m connecting you now. A support team member will respond shortly.';

  @override
  String emailTicketSubject(String title) {
    return 'Your ticket for $title';
  }

  @override
  String get emailTicketIntro =>
      'Your booking is confirmed. Show the QR code at the entrance: each code admits once.';

  @override
  String get emailTicketWhen => 'When';

  @override
  String get emailTicketWhere => 'Where';

  @override
  String get emailTicketTypeLabel => 'Ticket type';

  @override
  String get emailTicketPartySizeLabel => 'Party size';

  @override
  String get emailTicketCodeLabel => 'Booking code';

  @override
  String emailTicketQrCaption(int index, int count) {
    return 'Ticket $index of $count';
  }

  @override
  String get emailTicketFooter =>
      'You can also find your tickets in the GreenGo app. Do not share these QR codes.';

  @override
  String emailParticipantsSubject(String title) {
    return 'Participants list: $title';
  }

  @override
  String emailParticipantsIntro(String title, String when, int count) {
    return 'Attached is the participants list for $title ($when). Participants: $count.';
  }

  @override
  String get emailParticipantsPrivacy =>
      'This file contains personal data shared only for entry. Do not share it and delete it after the event.';

  @override
  String get csvColName => 'Name';

  @override
  String get csvColEmail => 'Email';

  @override
  String get csvColBookingCode => 'Booking code';

  @override
  String get csvColTicket => 'Ticket type / party size';

  @override
  String get csvColStatus => 'Status';

  @override
  String get csvStatusPaid => 'paid';

  @override
  String get csvStatusConfirmed => 'confirmed';

  @override
  String get csvStatusCheckedIn => 'checked-in';

  @override
  String get participantsEmailButton => 'Email me the participants list';

  @override
  String get participantsEmailSent =>
      'Participants list sent to your account email';

  @override
  String get participantsEmailRateLimited =>
      'You just requested it. Try again in a few minutes.';

  @override
  String get participantsEmailFailed =>
      'Couldn’t send the participants list. Please try again later.';

  @override
  String get participantsEmailNoEmail =>
      'Your account has no email address to send the list to.';

  @override
  String get checkoutOrganizerShareNotice =>
      'Your name and email will be shared with the organizer for entry.';
}
