import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: AppColors.textPrimary),
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
            _buildWelcomeHeader(),
            const SizedBox(height: AppDimensions.paddingL),

            // Quick stats
            _buildQuickStats(context),
            const SizedBox(height: AppDimensions.paddingL),

            // Management sections
            const Text(
              'User Management',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildUserManagementSection(context),
            const SizedBox(height: AppDimensions.paddingL),

            // System configuration
            const Text(
              'System Configuration',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildSystemConfigSection(context),
            const SizedBox(height: AppDimensions.paddingL),

            // Gamification
            const Text(
              'Gamification & Rewards',
              style: TextStyle(
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
              const Text(
                'Support Management',
                style: TextStyle(
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
              const Text(
                'Analytics & Reports',
                style: TextStyle(
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

  Widget _buildWelcomeHeader() {
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
                const Text(
                  'Welcome, Admin',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your GreenGo application settings',
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                iconColor: AppColors.successGreen,
                title: 'Active Users',
                value: '--',
                subtitle: 'Today',
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _StatCard(
                icon: Icons.verified_user,
                iconColor: AppColors.richGold,
                title: 'Pending',
                value: '--',
                subtitle: 'Verifications',
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _StatCard(
                icon: Icons.report,
                iconColor: AppColors.errorRed,
                title: 'Reports',
                value: '--',
                subtitle: 'Unresolved',
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
                  title: 'Support',
                  value: '--',
                  subtitle: 'Open Tickets',
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.hourglass_empty,
                  iconColor: Colors.orange,
                  title: 'Waiting',
                  value: '--',
                  subtitle: 'Unassigned',
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  iconColor: AppColors.successGreen,
                  title: 'Resolved',
                  value: '--',
                  subtitle: 'Today',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUserManagementSection(BuildContext context) {
    return Column(
      children: [
        if (_hasPermission(Permission.viewUserProfiles))
          _AdminMenuItem(
            icon: Icons.verified_user,
            iconColor: AppColors.successGreen,
            title: 'User Verifications',
            subtitle: 'Approve or reject user verification requests',
            onTap: () => _navigateTo(context, 'verifications'),
          ),
        if (_hasPermission(Permission.viewReports))
          _AdminMenuItem(
            icon: Icons.report_problem,
            iconColor: AppColors.warningAmber,
            title: 'User Reports',
            subtitle: 'Review and handle user reports',
            onTap: () => _navigateTo(context, 'reports'),
          ),
        if (_hasPermission(Permission.banUsers))
          _AdminMenuItem(
            icon: Icons.block,
            iconColor: AppColors.errorRed,
            title: 'User Moderation',
            subtitle: 'Manage user bans and suspensions',
            onTap: () => _navigateTo(context, 'moderation'),
          ),
      ],
    );
  }

  Widget _buildSystemConfigSection(BuildContext context) {
    return Column(
      children: [
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.stars,
            iconColor: AppColors.richGold,
            title: 'Early Access List',
            subtitle: 'Manage early access email list (CSV upload)',
            onTap: () => _navigateTo(context, 'early_access'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.star,
            iconColor: AppColors.richGold,
            title: 'Tier Management',
            subtitle: 'Configure tier limits and features',
            onTap: () => _navigateTo(context, 'tiers'),
          ),
        if (_hasPermission(Permission.adjustCoins))
          _AdminMenuItem(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            title: 'Coin Management',
            subtitle: 'Manage coin packages and user balances',
            onTap: () => _navigateTo(context, 'coins'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.settings,
            iconColor: AppColors.textSecondary,
            title: 'App Settings',
            subtitle: 'General application settings',
            onTap: () => _navigateTo(context, 'settings'),
          ),
      ],
    );
  }

  Widget _buildGamificationSection(BuildContext context) {
    return Column(
      children: [
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            title: 'Achievements',
            subtitle: 'Manage achievements and badges',
            onTap: () => _navigateTo(context, 'achievements'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.today,
            iconColor: AppColors.successGreen,
            title: 'Daily Challenges',
            subtitle: 'Configure daily challenges and rewards',
            onTap: () => _navigateTo(context, 'challenges'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            title: 'Login Streaks',
            subtitle: 'Configure streak milestones and rewards',
            onTap: () => _navigateTo(context, 'streaks'),
          ),
        if (_hasPermission(Permission.systemSettings))
          _AdminMenuItem(
            icon: Icons.card_giftcard,
            iconColor: Colors.purple,
            title: 'Promotions',
            subtitle: 'Manage special offers and promotions',
            onTap: () => _navigateTo(context, 'promotions'),
          ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      children: [
        _AdminMenuItem(
          icon: Icons.support_agent,
          iconColor: Colors.blue,
          title: 'Support Tickets',
          subtitle: 'View and manage user support conversations',
          onTap: () => _navigateTo(context, 'support_tickets'),
        ),
        if (_hasPermission(Permission.assignSupportTickets))
          _AdminMenuItem(
            icon: Icons.assignment_ind,
            iconColor: Colors.teal,
            title: 'Ticket Assignment',
            subtitle: 'Assign tickets to support agents',
            onTap: () => _navigateTo(context, 'ticket_assignment'),
          ),
        if (_hasPermission(Permission.manageAdmins))
          _AdminMenuItem(
            icon: Icons.group_add,
            iconColor: Colors.purple,
            title: 'Support Agents',
            subtitle: 'Manage support agent accounts',
            onTap: () => _navigateTo(context, 'support_agents'),
          ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    return Column(
      children: [
        _AdminMenuItem(
          icon: Icons.analytics,
          iconColor: AppColors.richGold,
          title: 'User Analytics',
          subtitle: 'View user engagement and growth metrics',
          onTap: () => _navigateTo(context, 'user_analytics'),
        ),
        _AdminMenuItem(
          icon: Icons.attach_money,
          iconColor: AppColors.successGreen,
          title: 'Revenue Analytics',
          subtitle: 'Track purchases and revenue',
          onTap: () => _navigateTo(context, 'revenue_analytics'),
        ),
        _AdminMenuItem(
          icon: Icons.trending_up,
          iconColor: Colors.blue,
          title: 'Engagement Reports',
          subtitle: 'View matching and messaging statistics',
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
            content: Text('$route coming soon'),
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
