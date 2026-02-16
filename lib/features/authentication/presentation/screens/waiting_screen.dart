import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/luxury_particles_background.dart';
import '../../../../core/widgets/animated_luxury_logo.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/widgets/luxury_countdown_widget.dart';
import '../../../../core/services/access_control_service.dart';
import '../../../../features/subscription/domain/entities/subscription.dart';

/// Screen shown to users who are registered but waiting for:
/// 1. Their access date (tier-based: Platinum March 14, Gold March 28, Silver April 7, Free April 14)
/// 2. Admin approval (only shown AFTER countdown is over)
///
/// Flow:
/// - User completes registration
/// - System checks if email is in early access CSV list
/// - Show countdown to their access date
/// - After countdown ends, if not approved, show pending approval message
/// - Once approved and after access date, user can enter the app
class WaitingScreen extends StatefulWidget {
  final UserAccessData? accessData;
  final VoidCallback? onEnableNotifications;
  final VoidCallback? onContactSupport;
  final VoidCallback? onSignOut;
  final VoidCallback? onRefresh;

  const WaitingScreen({
    super.key,
    this.accessData,
    this.onEnableNotifications,
    this.onContactSupport,
    this.onSignOut,
    this.onRefresh,
  });

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accessData = widget.accessData;
    final approvalStatus = accessData?.approvalStatus ?? ApprovalStatus.pending;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine what to show based on countdown and approval status
    final isCountdownActive = accessData?.isCountdownActive ?? true;
    final shouldShowPendingApproval = accessData?.shouldShowPendingApproval ?? false;
    final isRejected = approvalStatus == ApprovalStatus.rejected;

    return LuxuryParticlesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: LanguageSelector(),
            ),
          ],
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: constraints.maxHeight > 700 ? 16 : 8,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top section with logo and title
                        Column(
                          children: [
                            SizedBox(height: constraints.maxHeight > 700 ? 20 : 8),

                            // Animated Logo - same as login page
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: AnimatedLuxuryLogo(
                                assetPath: 'assets/images/greengo_main_logo_gold.png',
                                size: constraints.maxHeight > 700 ? 140 : 100,
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight > 700 ? 24 : 16),

                            // Title based on state
                            _buildTitle(context, l10n, isCountdownActive, shouldShowPendingApproval, isRejected),
                          ],
                        ),

                        // Middle section with main content
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              // VIP Badge for Silver, Gold, Platinum members
                              if (accessData != null &&
                                  accessData.membershipTier != SubscriptionTier.basic &&
                                  isCountdownActive)
                                _buildVIPMembershipBadge(context, accessData.membershipTier),

                              // Main Content based on state
                              if (isRejected)
                                _buildRejectedCard(context, l10n)
                              else if (isCountdownActive && accessData != null)
                                _buildCountdownSection(context, l10n, accessData, constraints)
                              else if (shouldShowPendingApproval)
                                _buildPendingApprovalCard(context, l10n)
                              else if (approvalStatus == ApprovalStatus.approved && !isCountdownActive)
                                _buildWelcomeCard(context, l10n),

                              const SizedBox(height: 16),

                              // Early access badge if applicable
                              if (accessData?.hasEarlyAccess == true && isCountdownActive)
                                _buildEarlyAccessBadge(context),
                            ],
                          ),
                        ),

                        // Bottom section with action buttons
                        Column(
                          children: [
                            // Action Buttons
                            _buildActionButtons(context, l10n, approvalStatus, accessData),

                            const SizedBox(height: 16),

                            // Stay Tuned Message
                            if (isCountdownActive || shouldShowPendingApproval)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  l10n.waitingStayTuned,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Sign Out Link
                            TextButton(
                              onPressed: widget.onSignOut,
                              child: Text(
                                l10n.signOut,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    AppLocalizations l10n,
    bool isCountdownActive,
    bool shouldShowPendingApproval,
    bool isRejected,
  ) {
    String title;
    String subtitle;

    if (isRejected) {
      title = l10n.accountRejected;
      subtitle = l10n.waitingMessageRejected;
    } else if (isCountdownActive) {
      title = l10n.waitingCountdownTitle;
      subtitle = l10n.waitingCountdownSubtitle;
    } else if (shouldShowPendingApproval) {
      title = l10n.accountPendingApproval;
      subtitle = l10n.waitingMessagePending;
    } else {
      title = l10n.accountApproved;
      subtitle = l10n.waitingMessageApproved;
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.richGold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection(
    BuildContext context,
    AppLocalizations l10n,
    UserAccessData accessData,
    BoxConstraints constraints,
  ) {
    return Column(
      children: [
        LuxuryCountdownWidget(
          targetDate: accessData.accessDate,
          title: l10n.waitingCountdownLabel,
          subtitle: accessData.hasEarlyAccess
              ? l10n.waitingEarlyAccessMember
              : l10n.waitingExclusiveAccess,
          onComplete: widget.onRefresh,
          compact: constraints.maxHeight < 700,
        ),
        const SizedBox(height: 16),
        _buildNotificationReminder(context, l10n, accessData),
      ],
    );
  }

  Widget _buildNotificationReminder(
    BuildContext context,
    AppLocalizations l10n,
    UserAccessData accessData,
  ) {
    final notificationsEnabled = accessData.notificationsEnabled;

    if (notificationsEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.waitingNotificationEnabled,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.infoBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.infoBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.waitingEnableNotificationsTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.infoBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.waitingEnableNotificationsSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.15),
            AppColors.charcoal.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: AppColors.richGold,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.waitingProfileUnderReview,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.richGold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.waitingReviewMessage,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildReviewSteps(l10n),
        ],
      ),
    );
  }

  Widget _buildReviewSteps(AppLocalizations l10n) {
    return Column(
      children: [
        _buildReviewStep(
          icon: Icons.check_circle,
          iconColor: AppColors.successGreen,
          title: l10n.waitingStepRegistration,
          isComplete: true,
        ),
        _buildReviewStep(
          icon: Icons.pending,
          iconColor: AppColors.richGold,
          title: l10n.waitingStepReview,
          isComplete: false,
          isActive: true,
        ),
        _buildReviewStep(
          icon: Icons.verified,
          iconColor: Colors.grey,
          title: l10n.waitingStepActivation,
          isComplete: false,
        ),
      ],
    );
  }

  Widget _buildReviewStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isComplete,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isComplete
                  ? iconColor.withValues(alpha: 0.2)
                  : (isActive
                      ? iconColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isComplete || isActive ? iconColor : Colors.grey,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isComplete || isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel,
              color: AppColors.errorRed,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.accountRejected,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.errorRed,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.waitingMessageRejected,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen.withValues(alpha: 0.2),
            AppColors.charcoal.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.successGreen,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.accountApproved,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.waitingMessageApproved,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build VIP membership badge for Silver, Gold, Platinum users
  Widget _buildVIPMembershipBadge(BuildContext context, SubscriptionTier tier) {
    if (tier == SubscriptionTier.basic) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    // Define colors and icons for each tier
    Color primaryColor;
    Color secondaryColor;
    IconData badgeIcon;
    String tierLabel;
    String benefitsLabel = l10n.vipPremiumBenefitsActive;

    switch (tier) {
      case SubscriptionTier.platinum:
        primaryColor = const Color(0xFFE5E4E2); // Platinum silver
        secondaryColor = const Color(0xFFB4B4B4);
        badgeIcon = Icons.diamond;
        tierLabel = l10n.vipPlatinumMember;
        break;
      case SubscriptionTier.gold:
        primaryColor = AppColors.richGold;
        secondaryColor = AppColors.accentGold;
        badgeIcon = Icons.workspace_premium;
        tierLabel = l10n.vipGoldMember;
        break;
      case SubscriptionTier.silver:
        primaryColor = const Color(0xFFC0C0C0); // Silver
        secondaryColor = const Color(0xFF808080);
        badgeIcon = Icons.stars;
        tierLabel = l10n.vipSilverMember;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.3),
            secondaryColor.withValues(alpha: 0.2),
            primaryColor.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: primaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tierLabel,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                benefitsLabel,
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Icon(
            badgeIcon,
            color: primaryColor,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildEarlyAccessBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.3),
            AppColors.accentGold.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: AppColors.richGold,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.waitingEarlyAccessMember,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.star,
            color: AppColors.richGold,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppLocalizations l10n,
    ApprovalStatus status,
    UserAccessData? accessData,
  ) {
    final notificationsEnabled = accessData?.notificationsEnabled ?? false;

    return Column(
      children: [
        if (status != ApprovalStatus.rejected && !notificationsEnabled)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onEnableNotifications,
              icon: const Icon(Icons.notifications_active, size: 20),
              label: Text(l10n.enableNotifications),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (status == ApprovalStatus.rejected) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onContactSupport,
              icon: const Icon(Icons.support_agent, size: 20),
              label: Text(l10n.contactSupport),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
