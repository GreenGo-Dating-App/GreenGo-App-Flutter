import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/tier_config.dart';

/// Tier Management Screen
/// Admin interface for configuring tier limits and features
class TierManagementScreen extends StatefulWidget {
  final String adminId;

  const TierManagementScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<TierManagementScreen> createState() => _TierManagementScreenState();
}

class _TierManagementScreenState extends State<TierManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<MembershipTier, TierConfig> _editedConfigs = {};
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfigs();
  }

  void _loadConfigs() {
    final provider = TierConfigProvider();
    for (final tier in MembershipTier.values) {
      final config = provider.getConfig(tier) ?? TierConfig.withDefaults(tier);
      _editedConfigs[tier] = config;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Tier Management',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.richGold,
                      ),
                    )
                  : const Icon(Icons.save, color: AppColors.richGold),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(color: AppColors.richGold),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: _showResetConfirmation,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('FREE'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('SILVER'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.richGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('GOLD'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade300, Colors.blue.shade300],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('PLATINUM'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: MembershipTier.values.map((tier) {
          return _TierConfigEditor(
            tier: tier,
            config: _editedConfigs[tier]!,
            onConfigChanged: (newConfig) {
              setState(() {
                _editedConfigs[tier] = newConfig;
                _hasChanges = true;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Reset to Defaults?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will reset all tier configurations to their default values. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      for (final tier in MembershipTier.values) {
        _editedConfigs[tier] = TierConfig.withDefaults(tier);
      }
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurations reset to defaults. Save to apply.'),
        backgroundColor: AppColors.warningAmber,
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // TODO: Implement actual save to Firestore via repository
      // For now, just update the local provider
      final provider = TierConfigProvider();
      for (final config in _editedConfigs.values) {
        provider.updateConfig(config.copyWith(
          updatedBy: widget.adminId,
          updatedAt: DateTime.now(),
        ));
      }

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tier configurations saved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

class _TierConfigEditor extends StatelessWidget {
  final MembershipTier tier;
  final TierConfig config;
  final Function(TierConfig) onConfigChanged;

  const _TierConfigEditor({
    required this.tier,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier header
          _buildTierHeader(),
          const SizedBox(height: AppDimensions.paddingL),

          // Limits section
          _buildSectionHeader('Daily Limits'),
          const SizedBox(height: AppDimensions.paddingS),
          _buildLimitsSection(),
          const SizedBox(height: AppDimensions.paddingL),

          // Features section
          _buildSectionHeader('Features'),
          const SizedBox(height: AppDimensions.paddingS),
          _buildFeaturesSection(),
          const SizedBox(height: AppDimensions.paddingL),

          // Filters section
          _buildSectionHeader('Filter Options'),
          const SizedBox(height: AppDimensions.paddingS),
          _buildFiltersSection(),
          const SizedBox(height: AppDimensions.paddingL),

          // Matching section
          _buildSectionHeader('Matching & Visibility'),
          const SizedBox(height: AppDimensions.paddingS),
          _buildMatchingSection(),
          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }

  Widget _buildTierHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getTierGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            _getTierIcon(),
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Configure limits and features',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getTierGradient() {
    switch (tier) {
      case MembershipTier.free:
        return [Colors.grey.shade700, Colors.grey.shade900];
      case MembershipTier.silver:
        return [Colors.grey.shade400, Colors.grey.shade600];
      case MembershipTier.gold:
        return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
      case MembershipTier.platinum:
        return [Colors.purple.shade400, Colors.blue.shade600];
      case MembershipTier.test:
        return [Colors.green.shade400, Colors.green.shade600];
    }
  }

  IconData _getTierIcon() {
    switch (tier) {
      case MembershipTier.free:
        return Icons.person;
      case MembershipTier.silver:
        return Icons.star_border;
      case MembershipTier.gold:
        return Icons.star;
      case MembershipTier.platinum:
        return Icons.diamond;
      case MembershipTier.test:
        return Icons.bug_report;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLimitsSection() {
    return Column(
      children: [
        _LimitSlider(
          label: 'Daily Messages',
          value: config.rules.dailyMessageLimit,
          min: 0,
          max: 200,
          icon: Icons.message,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(dailyMessageLimit: value),
          ),
        ),
        _LimitSlider(
          label: 'Daily Swipes',
          value: config.rules.dailySwipeLimit,
          min: 0,
          max: 200,
          icon: Icons.swipe,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(dailySwipeLimit: value),
          ),
        ),
        _LimitSlider(
          label: 'Daily Super Likes',
          value: config.rules.dailySuperLikeLimit,
          min: 0,
          max: 50,
          icon: Icons.favorite,
          iconColor: Colors.pink,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(dailySuperLikeLimit: value),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        _FeatureToggle(
          label: 'Can Send Media',
          description: 'Send images and videos in chat',
          value: config.rules.canSendMedia,
          icon: Icons.photo,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canSendMedia: value),
          ),
        ),
        _FeatureToggle(
          label: 'Read Receipts',
          description: 'See when messages are read',
          value: config.rules.canSeeReadReceipts,
          icon: Icons.done_all,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canSeeReadReceipts: value),
          ),
        ),
        _FeatureToggle(
          label: 'Incognito Mode',
          description: 'Browse profiles anonymously',
          value: config.rules.canUseIncognitoMode,
          icon: Icons.visibility_off,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canUseIncognitoMode: value),
          ),
        ),
        _FeatureToggle(
          label: 'Profile Visitors',
          description: 'See who visited their profile',
          value: config.rules.canSeeProfileVisitors,
          icon: Icons.people,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canSeeProfileVisitors: value),
          ),
        ),
        _FeatureToggle(
          label: 'Video Chat',
          description: 'Use video calling feature',
          value: config.rules.canUseVideoChat,
          icon: Icons.videocam,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canUseVideoChat: value),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      children: [
        _FeatureToggle(
          label: 'Advanced Filters',
          description: 'Enable advanced filtering options',
          value: config.rules.canUseAdvancedFilters,
          icon: Icons.filter_list,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canUseAdvancedFilters: value),
          ),
        ),
        _FeatureToggle(
          label: 'Location Filter',
          description: 'Filter by specific location',
          value: config.rules.canFilterByLocation,
          icon: Icons.location_on,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canFilterByLocation: value),
          ),
        ),
        _FeatureToggle(
          label: 'Interest Filter',
          description: 'Filter by interests',
          value: config.rules.canFilterByInterests,
          icon: Icons.interests,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canFilterByInterests: value),
          ),
        ),
        _FeatureToggle(
          label: 'Language Filter',
          description: 'Filter by spoken languages',
          value: config.rules.canFilterByLanguage,
          icon: Icons.language,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canFilterByLanguage: value),
          ),
        ),
        _FeatureToggle(
          label: 'Verification Filter',
          description: 'Filter by verification status',
          value: config.rules.canFilterByVerification,
          icon: Icons.verified,
          onChanged: (value) => _updateRules(
            config.rules.copyWith(canFilterByVerification: value),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingSection() {
    return Column(
      children: [
        _LimitSlider(
          label: 'Match Priority',
          value: config.rules.matchPriority,
          min: 0,
          max: 10,
          allowUnlimited: false,
          icon: Icons.priority_high,
          iconColor: AppColors.richGold,
          description: 'Higher priority = shown first in discovery',
          onChanged: (value) => _updateRules(
            config.rules.copyWith(matchPriority: value),
          ),
        ),
      ],
    );
  }

  void _updateRules(MembershipRules newRules) {
    onConfigChanged(config.copyWith(rules: newRules));
  }
}

class _LimitSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final bool allowUnlimited;
  final IconData icon;
  final Color? iconColor;
  final String? description;
  final Function(int) onChanged;

  const _LimitSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.allowUnlimited = true,
    required this.icon,
    this.iconColor,
    this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlimited = value == -1;
    final displayValue = isUnlimited ? max.toDouble() : value.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlimited
                      ? AppColors.successGreen.withValues(alpha: 0.2)
                      : AppColors.richGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  isUnlimited ? 'Unlimited' : value.toString(),
                  style: TextStyle(
                    color: isUnlimited ? AppColors.successGreen : AppColors.richGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                min.toString(),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: displayValue.clamp(min.toDouble(), max.toDouble()),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  activeColor: AppColors.richGold,
                  inactiveColor: AppColors.divider,
                  onChanged: (newValue) {
                    if (!isUnlimited) {
                      onChanged(newValue.round());
                    }
                  },
                ),
              ),
              Text(
                max.toString(),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (allowUnlimited)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Unlimited',
                  style: TextStyle(
                    color: isUnlimited
                        ? AppColors.successGreen
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isUnlimited,
                  activeColor: AppColors.successGreen,
                  onChanged: (checked) {
                    if (checked) {
                      onChanged(-1);
                    } else {
                      onChanged(max ~/ 2);
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final IconData icon;
  final Function(bool) onChanged;

  const _FeatureToggle({
    required this.label,
    required this.description,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: value ? AppColors.successGreen.withValues(alpha: 0.5) : AppColors.divider,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: value ? AppColors.successGreen : AppColors.textTertiary,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: AppColors.successGreen,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Extension to add copyWith to MembershipRules
extension MembershipRulesCopyWith on MembershipRules {
  MembershipRules copyWith({
    int? dailyMessageLimit,
    int? dailySwipeLimit,
    int? dailySuperLikeLimit,
    bool? canUseAdvancedFilters,
    bool? canFilterByLocation,
    bool? canFilterByInterests,
    bool? canFilterByLanguage,
    bool? canFilterByVerification,
    bool? canSendMedia,
    bool? canSeeReadReceipts,
    bool? canUseIncognitoMode,
    int? matchPriority,
    bool? canSeeProfileVisitors,
    bool? canUseVideoChat,
    String? badgeIcon,
  }) {
    return MembershipRules(
      dailyMessageLimit: dailyMessageLimit ?? this.dailyMessageLimit,
      dailySwipeLimit: dailySwipeLimit ?? this.dailySwipeLimit,
      dailySuperLikeLimit: dailySuperLikeLimit ?? this.dailySuperLikeLimit,
      canUseAdvancedFilters: canUseAdvancedFilters ?? this.canUseAdvancedFilters,
      canFilterByLocation: canFilterByLocation ?? this.canFilterByLocation,
      canFilterByInterests: canFilterByInterests ?? this.canFilterByInterests,
      canFilterByLanguage: canFilterByLanguage ?? this.canFilterByLanguage,
      canFilterByVerification: canFilterByVerification ?? this.canFilterByVerification,
      canSendMedia: canSendMedia ?? this.canSendMedia,
      canSeeReadReceipts: canSeeReadReceipts ?? this.canSeeReadReceipts,
      canUseIncognitoMode: canUseIncognitoMode ?? this.canUseIncognitoMode,
      matchPriority: matchPriority ?? this.matchPriority,
      canSeeProfileVisitors: canSeeProfileVisitors ?? this.canSeeProfileVisitors,
      canUseVideoChat: canUseVideoChat ?? this.canUseVideoChat,
      badgeIcon: badgeIcon ?? this.badgeIcon,
    );
  }
}
