import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/luxury_particles_background.dart';
import '../../../../core/widgets/animated_luxury_logo.dart';
import '../../../../core/services/access_control_service.dart';
import '../../../subscription/domain/entities/subscription.dart';

/// Screen shown to users who are registered but waiting for:
/// 1. Admin approval
/// 2. Their tier-specific access date (March 1st for premium, March 15th for basic)
class WaitingScreen extends StatefulWidget {
  final UserAccessData? accessData;
  final VoidCallback? onEnableNotifications;
  final VoidCallback? onContactSupport;
  final VoidCallback? onSignOut;

  const WaitingScreen({
    super.key,
    this.accessData,
    this.onEnableNotifications,
    this.onContactSupport,
    this.onSignOut,
  });

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
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
    _startCountdown();
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    if (widget.accessData != null) {
      setState(() {
        _timeRemaining = widget.accessData!.timeUntilAccess;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accessData = widget.accessData;
    final approvalStatus = accessData?.approvalStatus ?? ApprovalStatus.pending;

    return Scaffold(
      body: LuxuryParticlesBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Animated Logo
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: const AnimatedLuxuryLogo(size: 120),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    l10n.waitingTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    l10n.waitingSubtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Status Card
                  _buildStatusCard(context, l10n, approvalStatus),

                  const SizedBox(height: 24),

                  // Access Date Card (only if approved)
                  if (approvalStatus == ApprovalStatus.approved && accessData != null)
                    _buildAccessDateCard(context, l10n, accessData),

                  if (approvalStatus == ApprovalStatus.approved && accessData != null)
                    const SizedBox(height: 24),

                  // Countdown (only if approved and waiting for date)
                  if (approvalStatus == ApprovalStatus.approved &&
                      accessData != null &&
                      !accessData.canAccessApp)
                    _buildCountdownCard(context, l10n),

                  if (approvalStatus == ApprovalStatus.approved &&
                      accessData != null &&
                      !accessData.canAccessApp)
                    const SizedBox(height: 24),

                  // Early Access Upgrade Banner (only for basic users)
                  if (accessData?.membershipTier == SubscriptionTier.basic &&
                      approvalStatus == ApprovalStatus.approved)
                    _buildUpgradeBanner(context, l10n),

                  if (accessData?.membershipTier == SubscriptionTier.basic &&
                      approvalStatus == ApprovalStatus.approved)
                    const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(context, l10n, approvalStatus, accessData),

                  const SizedBox(height: 40),

                  // Stay Tuned Message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.waitingStayTuned,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Out Link
                  TextButton(
                    onPressed: widget.onSignOut,
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    AppLocalizations l10n,
    ApprovalStatus status,
  ) {
    IconData icon;
    Color iconColor;
    String title;
    String message;

    switch (status) {
      case ApprovalStatus.pending:
        icon = Icons.hourglass_empty;
        iconColor = AppColors.gold;
        title = l10n.accountPendingApproval;
        message = l10n.waitingMessagePending;
        break;
      case ApprovalStatus.approved:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        title = l10n.accountApproved;
        message = l10n.waitingMessageApproved;
        break;
      case ApprovalStatus.rejected:
        icon = Icons.cancel;
        iconColor = Colors.red;
        title = l10n.accountRejected;
        message = l10n.waitingMessageRejected;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDateCard(
    BuildContext context,
    AppLocalizations l10n,
    UserAccessData accessData,
  ) {
    final tier = accessData.membershipTier;
    final hasEarlyAccess = tier.hasEarlyAccess;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasEarlyAccess
              ? [AppColors.gold.withValues(alpha: 0.2), AppColors.gold.withValues(alpha: 0.1)]
              : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasEarlyAccess
              ? AppColors.gold.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today,
            color: hasEarlyAccess ? AppColors.gold : Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.waitingAccessDateTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasEarlyAccess
                ? l10n.waitingAccessDatePremium(tier.displayName)
                : l10n.waitingAccessDateBasic,
            style: TextStyle(
              fontSize: 14,
              color: hasEarlyAccess ? AppColors.gold : Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasEarlyAccess) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: AppColors.gold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Early Access',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownCard(BuildContext context, AppLocalizations l10n) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.waitingCountdownTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCountdownUnit(l10n.waitingDaysRemaining(days), days.toString()),
              _buildCountdownSeparator(),
              _buildCountdownUnit(l10n.waitingHoursRemaining(hours), hours.toString().padLeft(2, '0')),
              _buildCountdownSeparator(),
              _buildCountdownUnit(l10n.waitingMinutesRemaining(minutes), minutes.toString().padLeft(2, '0')),
              _buildCountdownSeparator(),
              _buildCountdownUnit(l10n.waitingSecondsRemaining(seconds), seconds.toString().padLeft(2, '0')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String label, String value) {
    // Extract just the unit (days, hours, etc.)
    final parts = label.split(' ');
    final unit = parts.length > 1 ? parts.last : label;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSeparator() {
    return const Text(
      ':',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.gold,
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.3),
            AppColors.gold.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: AppColors.gold, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.upgradeForEarlyAccess,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
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
              icon: const Icon(Icons.notifications_active),
              label: Text(l10n.enableNotifications),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (notificationsEnabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.waitingNotificationEnabled,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        if (status == ApprovalStatus.rejected) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onContactSupport,
              icon: const Icon(Icons.support_agent),
              label: Text(l10n.contactSupport),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
