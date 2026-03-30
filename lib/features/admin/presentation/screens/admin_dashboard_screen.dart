import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/admin_role.dart';

/// Admin Dashboard Screen
/// Main hub for all admin management features
class AdminDashboardScreen extends StatelessWidget {
  final String adminId;
  final AdminUser adminUser;

  const AdminDashboardScreen({
    super.key,
    required this.adminId,
    required this.adminUser,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          l10n.adminDashboard,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingM),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getRoleBadgeColor(adminUser.role),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  adminUser.role.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(context),
            const SizedBox(height: AppDimensions.paddingL),

            // Quick stats
            _buildQuickStats(context),
            const SizedBox(height: AppDimensions.paddingL),

            // Management sections
            Text(
              l10n.adminUserManagement,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildUserManagementSection(context),
            const SizedBox(height: AppDimensions.paddingL),

            // System configuration
            Text(
              l10n.adminSystemConfiguration,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildSystemConfigSection(context),
            const SizedBox(height: AppDimensions.paddingL),

            // Gamification
            Text(
              l10n.adminGamificationAndRewards,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildGamificationSection(context),
            const SizedBox(height: AppDimensions.paddingL),

            // Support Chat Management
            if (_hasPermission(Permission.viewSupportTickets)) ...[
              Text(
                l10n.adminSupportManagement,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildSupportSection(context),
              const SizedBox(height: AppDimensions.paddingL),
            ],

            // Analytics
            if (_hasPermission(Permission.viewAnalytics)) ...[
              Text(
                l10n.adminAnalyticsAndReports,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildAnalyticsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.2),
            AppColors.charcoal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.richGold,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.adminWelcome,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.adminManageAppSettings,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                iconColor: AppColors.successGreen,
                title: l10n.adminActiveUsers,
                value: '--',
                subtitle: l10n.adminToday,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _StatCard(
                icon: Icons.verified_user,
                iconColor: AppColors.richGold,
                title: l10n.adminPending,
                value: '--',
                subtitle: l10n.adminVerifications,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _StatCard(
                icon: Icons.report,
                iconColor: AppColors.errorRed,
                title: l10n.adminReports,
                value: '--',
                subtitle: l10n.adminUnresolved,
              ),
            ),
          ],
        ),
        if (_hasPermission(Permission.viewSupportTickets)) ...[
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.support_agent,
                  iconColor: Colors.blue,
                  title: l10n.adminSupport,
                  value: '--',
                  subtitle: l10n.adminOpenTickets,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.hourglass_empty,
                  iconColor: Colors.orange,
                  title: l10n.adminWaiting,
                  value: '--',
                  subtitle: l10n.adminUnassigned,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  iconColor: AppColors.successGreen,
                  title: l10n.adminResolved,
                  value: '--',
                  subtitle: l10n.adminToday,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUserManagementSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (_hasPermission(Permission.viewUserProfiles))
          _AdminMenuItem(
            icon: Icons.verified_user,
            iconColor: AppColors.successGreen,
            title: l10n.adminUserVerifications,
            subtitle: l10n.adminUserVerificationsSubtitle,
            onTap: () => _navigateTo(context, 'verifications'),
          ),
        if (_hasPermission(Permission.viewReports))
          _AdminMenuItem(
            icon: Icons.report_problem,
            iconColor: AppColors.warningAmber,
            title: l10n.adminUserReports,
            subtitle: l10n.adminUserReportsSubtitle,
            onTap: () => _navigateTo(context, 'reports'),
          ),
        if (_hasPermission(Permission.banUsers))
          _AdminMenuItem(
            icon: Icons.block,
            iconColor: AppColors.errorRed,
            title: l10n.adminUserModeration,
            subtitle: l10n.adminUserModerationSubtitle,
            onTap: () => _navigateTo(context, 'moderation'),
          ),
      ],
    );
  }

  Widget _buildSystemConfigSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.shopping_bag,
            iconColor: Colors.deepPurple,
            title: 'Pre-Sale Management',
            subtitle: 'Manage pre-sale tiers & CSV import',
            onTap: () => _navigateTo(context, 'pre_sale'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.stars,
            iconColor: AppColors.richGold,
            title: l10n.adminEarlyAccessList,
            subtitle: l10n.adminEarlyAccessList,
            onTap: () => _navigateTo(context, 'early_access'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.star,
            iconColor: AppColors.richGold,
            title: l10n.adminTierManagement,
            subtitle: l10n.adminTierManagementSubtitle,
            onTap: () => _navigateTo(context, 'tiers'),
          ),
        if (_hasPermission(Permission.adjustCoins))
          _AdminMenuItem(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            title: l10n.adminCoinManagement,
            subtitle: l10n.adminCoinManagementSubtitle,
            onTap: () => _navigateTo(context, 'coins'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.settings,
            iconColor: AppColors.textSecondary,
            title: l10n.adminAppSettings,
            subtitle: l10n.adminAppSettingsSubtitle,
            onTap: () => _navigateTo(context, 'settings'),
          ),
      ],
    );
  }

  Widget _buildGamificationSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            title: l10n.adminAchievements,
            subtitle: l10n.adminAchievementsSubtitle,
            onTap: () => _navigateTo(context, 'achievements'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.today,
            iconColor: AppColors.successGreen,
            title: l10n.adminDailyChallenges,
            subtitle: l10n.adminDailyChallengesSubtitle,
            onTap: () => _navigateTo(context, 'challenges'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            title: l10n.adminLoginStreaks,
            subtitle: l10n.adminLoginStreaksSubtitle,
            onTap: () => _navigateTo(context, 'streaks'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.card_giftcard,
            iconColor: Colors.purple,
            title: l10n.adminPromotions,
            subtitle: l10n.adminPromotionsSubtitle,
            onTap: () => _navigateTo(context, 'promotions'),
          ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _AdminMenuItem(
          icon: Icons.support_agent,
          iconColor: Colors.blue,
          title: l10n.adminSupportTickets,
          subtitle: l10n.adminSupportTicketsSubtitle,
          onTap: () => _navigateTo(context, 'support_tickets'),
        ),
        if (_hasPermission(Permission.assignSupportTickets))
          _AdminMenuItem(
            icon: Icons.assignment_ind,
            iconColor: Colors.teal,
            title: l10n.adminTicketAssignment,
            subtitle: l10n.adminTicketAssignmentSubtitle,
            onTap: () => _navigateTo(context, 'ticket_assignment'),
          ),
        if (_hasPermission(Permission.manageAdmins))
          _AdminMenuItem(
            icon: Icons.group_add,
            iconColor: Colors.purple,
            title: l10n.adminSupportAgents,
            subtitle: l10n.adminSupportAgentsSubtitle,
            onTap: () => _navigateTo(context, 'support_agents'),
          ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _AdminMenuItem(
          icon: Icons.analytics,
          iconColor: AppColors.richGold,
          title: l10n.adminUserAnalytics,
          subtitle: l10n.adminUserAnalyticsSubtitle,
          onTap: () => _navigateTo(context, 'user_analytics'),
        ),
        _AdminMenuItem(
          icon: Icons.attach_money,
          iconColor: AppColors.successGreen,
          title: l10n.adminRevenueAnalytics,
          subtitle: l10n.adminRevenueAnalyticsSubtitle,
          onTap: () => _navigateTo(context, 'revenue_analytics'),
        ),
        _AdminMenuItem(
          icon: Icons.trending_up,
          iconColor: Colors.blue,
          title: l10n.adminEngagementReports,
          subtitle: l10n.adminEngagementReportsSubtitle,
          onTap: () => _navigateTo(context, 'engagement_reports'),
        ),
      ],
    );
  }

  bool _hasPermission(Permission permission) {
    return adminUser.hasPermission(permission);
  }

  Color _getRoleBadgeColor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AppColors.richGold;
      case AdminRole.moderator:
        return AppColors.successGreen;
      case AdminRole.support:
        return Colors.blue;
      case AdminRole.analyst:
        return Colors.purple;
    }
  }

  void _navigateTo(BuildContext context, String route) {
    switch (route) {
      case 'verifications':
        Navigator.of(context).pushNamed(
          '/admin/verifications',
          arguments: adminId,
        );
        break;
      case 'reports':
        Navigator.of(context).pushNamed(
          '/admin/reports',
          arguments: adminId,
        );
        break;
      case 'pre_sale':
        Navigator.of(context).pushNamed(
          '/admin/pre_sale',
          arguments: adminId,
        );
        break;
      case 'early_access':
        Navigator.of(context).pushNamed(
          '/admin/early_access',
          arguments: adminId,
        );
        break;
      case 'tiers':
        Navigator.of(context).pushNamed(
          '/admin/tiers',
          arguments: adminId,
        );
        break;
      case 'coins':
        Navigator.of(context).pushNamed(
          '/admin/coins',
          arguments: adminId,
        );
        break;
      case 'achievements':
        Navigator.of(context).pushNamed(
          '/admin/gamification',
          arguments: {'adminId': adminId, 'tab': 'achievements'},
        );
        break;
      case 'challenges':
        Navigator.of(context).pushNamed(
          '/admin/gamification',
          arguments: {'adminId': adminId, 'tab': 'challenges'},
        );
        break;
      case 'streaks':
        Navigator.of(context).pushNamed(
          '/admin/gamification',
          arguments: {'adminId': adminId, 'tab': 'streaks'},
        );
        break;
      case 'support_tickets':
        Navigator.of(context).pushNamed(
          '/admin/support_tickets',
          arguments: adminId,
        );
        break;
      case 'ticket_assignment':
        Navigator.of(context).pushNamed(
          '/admin/ticket_assignment',
          arguments: adminId,
        );
        break;
      case 'support_agents':
        Navigator.of(context).pushNamed(
          '/admin/support_agents',
          arguments: adminId,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminComingSoon(route)),
            backgroundColor: AppColors.charcoal,
          ),
        );
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
