// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get adminUseVideoCallingFeature => 'Use video calling feature';

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
  String get adminVideoChat => 'Video Chat';

  @override
  String get adminVideoCoinPackages => 'Video Coin Packages';

  @override
  String get adminVideoCoins => 'Video Coins';

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
  String coinsAmountVideoMinutes(Object amount) {
    return '$amount Video Minutes';
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
  String coinsExpiring(Object count) {
    return '$count expiring';
  }

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
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return 'Purchase $totalMinutes video minutes for $price?';
  }

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
  String get coinsTabVideoCoins => 'Video Coins';

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
  String get coinsVideoCoinInfo => '1 Video Coin = 1 minute of video call';

  @override
  String get coinsVideoMin => 'Video Min';

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
  String get eventsTabNearby => 'Nearby';

  @override
  String get eventsTabUpcoming => 'Upcoming';

  @override
  String get eventsThisMonth => 'This Month';

  @override
  String get eventsThisWeekFilter => 'This Week';

  @override
  String get eventsTitle => 'Events';

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
  String get messages => 'Exchanges';

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
      'Tell us about your interests, hobbies, what you\'re looking for...';

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
      'Your interests help us find better matches for you';

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
  String get waitingCountdownLabel => 'App Launch Countdown';

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
  String get waitingExclusiveAccess => 'Your exclusive access date';

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
  String get yearlyMembership => 'Yearly Membership — \$4.99/year';

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
      'Random Mode: enable this toggle to discover random people from all over the world, sorted by distance. Each refresh gives you a new set of profiles. When Random Mode is off, only people close to you are shown. You can also select specific countries to narrow your search.';

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
      '• Priority Connect: 10 coins  • Boost: 50 coins  • Direct Message: 50 coins';

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
      'Explored: People you skipped without deciding yet — you can revisit them later.';

  @override
  String get guideGridFiltersItem7 =>
      'Matches: People you mutually Connected with (both said Let\'s Connect).';

  @override
  String get guideGridFiltersItem8 =>
      'My Network: All people you\'re connected with — includes Matches and accepted Priority Connects.';

  @override
  String get guideGridFiltersItem9 =>
      'Travelers: People with Traveler Mode active, visiting a city near you.';

  @override
  String get guideGridFiltersItem10 =>
      'Guides: Local Guides ready to help travelers discover their city.';

  @override
  String get guideGridFiltersItem11 =>
      'You can combine multiple filters at once to refine your search.';

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
      'Use the filter chips to organize your chats: All, New, Unread, Favorites, To Approve, Matches, and Direct.';

  @override
  String get guideExchangesItem4 =>
      'New and Unread show conversations with messages you haven\'t read yet. The filter chip shows the count when greater than 0.';

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
  String get preferenceShowMyNetworkDesc =>
      'Show only people in your network (matches and accepted Priority Connect).';

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
}
