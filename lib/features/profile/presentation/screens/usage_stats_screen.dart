import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/usage_limit_service.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/profile.dart';
import '../../../../core/utils/safe_navigation.dart';

/// Usage Stats Screen
///
/// Shows user's current daily usage vs tier limits with progress bars
class UsageStatsScreen extends StatefulWidget {
  final String userId;
  final MembershipTier membershipTier;
  final Profile? profile;

  const UsageStatsScreen({
    super.key,
    required this.userId,
    required this.membershipTier,
    this.profile,
  });

  @override
  State<UsageStatsScreen> createState() => _UsageStatsScreenState();
}

class _UsageStatsScreenState extends State<UsageStatsScreen> {
  final UsageLimitService _usageLimitService = UsageLimitService();
  Map<UsageLimitType, int> _usageStats = {};
  int _coinBalance = 0;
  bool _isLoading = true;

  // Real-time Firestore listeners
  StreamSubscription<DocumentSnapshot>? _hourlyUsageSub;
  StreamSubscription<DocumentSnapshot>? _dailyUsageSub;
  StreamSubscription<DocumentSnapshot>? _profileSub;

  // Real-time membership tier (updates after purchase)
  late MembershipTier _liveMembershipTier;

  @override
  void initState() {
    super.initState();
    _liveMembershipTier = widget.membershipTier;
    _loadStats();
    _subscribeToRealtimeUsage();
    _subscribeToProfileChanges();
  }

  @override
  void dispose() {
    _hourlyUsageSub?.cancel();
    _dailyUsageSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  /// Listen to profile changes so the tier badge updates in real-time after a purchase
  void _subscribeToProfileChanges() {
    _profileSub = FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      final tierStr = data['membershipTier'] as String?;
      if (tierStr != null) {
        final newTier = _membershipTierFromString(tierStr);
        if (newTier != _liveMembershipTier) {
          setState(() {
            _liveMembershipTier = newTier;
          });
        }
      }
    });
  }

  MembershipTier _membershipTierFromString(String tierStr) {
    switch (tierStr.toUpperCase()) {
      case 'PLATINUM':
        return MembershipTier.platinum;
      case 'GOLD':
        return MembershipTier.gold;
      case 'SILVER':
        return MembershipTier.silver;
      default:
        return MembershipTier.free;
    }
  }

  String _getHourKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}';
  }

  String _getDayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Stream the current hour's and current day's usage documents so the UI
  /// updates automatically the moment a swipe/action is recorded.
  void _subscribeToRealtimeUsage() {
    final userId = widget.userId;
    final db = FirebaseFirestore.instance;

    _hourlyUsageSub = db
        .collection('usageLimits')
        .doc(userId)
        .collection('hours')
        .doc(_getHourKey())
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        _usageStats[UsageLimitType.likes] =
            (data['likeCount'] as num?)?.toInt() ?? 0;
        _usageStats[UsageLimitType.nopes] =
            (data['nopeCount'] as num?)?.toInt() ?? 0;
        _usageStats[UsageLimitType.superLikes] =
            (data['superLikeCount'] as num?)?.toInt() ?? 0;
      });
    });

    _dailyUsageSub = db
        .collection('usageLimits')
        .doc(userId)
        .collection('days')
        .doc(_getDayKey())
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        _usageStats[UsageLimitType.messages] =
            (data['messageCount'] as num?)?.toInt() ?? 0;
        _usageStats[UsageLimitType.mediaSends] =
            (data['mediaSendCount'] as num?)?.toInt() ?? 0;
      });
    });
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _usageLimitService.getAllUsageStats(widget.userId);

      // Get coin balance
      int coins = 0;
      try {
        final coinRepo = GetIt.instance<CoinRepository>();
        final balanceResult = await coinRepo.getBalance(widget.userId);
        coins = balanceResult.fold(
          (failure) => 0,
          (balance) => balance.availableCoins,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _usageStats = stats;
          _coinBalance = coins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = MembershipRules.getDefaultsForTier(_liveMembershipTier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context, userId: widget.userId),
        ),
        title: const Text(
          'My Usage',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.richGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Tier Badge
                    _buildTierSection(),

                    const SizedBox(height: 16),

                    // Base Membership
                    if (widget.profile != null)
                      _buildBaseMembershipSection(),

                    const SizedBox(height: 24),

                    // Coin Balance
                    _buildCoinBalanceCard(),

                    const SizedBox(height: 24),

                    // Usage Stats
                    const Text(
                      'Daily Usage',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hourly limits
                    _buildUsageStat(
                      icon: Icons.favorite,
                      label: 'Likes This Hour',
                      used: _usageStats[UsageLimitType.likes] ?? 0,
                      limit: rules.hourlyLikeLimit,
                    ),
                    const SizedBox(height: 12),

                    _buildUsageStat(
                      icon: Icons.close,
                      label: 'Nopes This Hour',
                      used: _usageStats[UsageLimitType.nopes] ?? 0,
                      limit: rules.hourlyNopeLimit,
                    ),
                    const SizedBox(height: 12),

                    _buildUsageStat(
                      icon: Icons.star,
                      label: 'Super Likes This Hour',
                      used: _usageStats[UsageLimitType.superLikes] ?? 0,
                      limit: rules.hourlySuperLikeLimit,
                    ),
                    const SizedBox(height: 12),

                    // Daily limits
                    _buildUsageStat(
                      icon: Icons.message,
                      label: 'Messages Today',
                      used: _usageStats[UsageLimitType.messages] ?? 0,
                      limit: rules.dailyMessageLimit,
                    ),
                    const SizedBox(height: 12),

                    _buildUsageStat(
                      icon: Icons.photo,
                      label: 'Media Sent Today',
                      used: _usageStats[UsageLimitType.mediaSends] ?? 0,
                      limit: rules.dailyMediaSendLimit,
                    ),
                    const SizedBox(height: 12),

                    _buildUsageStat(
                      icon: Icons.flash_on,
                      label: 'Boosts This Month',
                      used: _usageStats[UsageLimitType.boosts] ?? 0,
                      limit: rules.monthlyFreeBoosts,
                    ),

                    const SizedBox(height: 32),

                    // Tier Comparison
                    if (_liveMembershipTier != MembershipTier.platinum) ...[
                      const Text(
                        'Upgrade Benefits',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTierComparison(rules),
                      const SizedBox(height: 24),

                      // Upgrade Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => di.sl<CoinBloc>()..add(LoadCoinBalance(widget.userId))..add(const LoadAvailablePackages()),
                                  child: CoinShopScreen(
                                    userId: widget.userId,
                                    initialTab: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                            ),
                          ),
                          child: const Text(
                            'Upgrade Membership',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTierSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundCard,
            AppColors.richGold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          MembershipBadge(tier: _liveMembershipTier),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_liveMembershipTier.displayName} Plan',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current membership tier',
                  style: TextStyle(
                    color: AppColors.textTertiary.withOpacity(0.8),
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

  Widget _buildBaseMembershipSection() {
    final profile = widget.profile!;
    final endDate = profile.baseMembershipEndDate;
    final isActive = profile.isBaseMembershipActive;

    if (!profile.hasBaseMembership || endDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            const Text(
              'No GreenGo Base Membership',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final formattedDate =
        '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : AppColors.errorRed.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? const Color(0xFF4CAF50) : AppColors.errorRed,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GreenGo Base Membership',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'Expires: $formattedDate' : 'Expired: $formattedDate',
                  style: TextStyle(
                    color: isActive ? AppColors.textSecondary : AppColors.errorRed,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4CAF50) : AppColors.errorRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Active' : 'Expired',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: AppColors.richGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coins Available',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_coinBalance coins',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStat({
    required IconData icon,
    required String label,
    required int used,
    required int limit,
  }) {
    final isUnlimited = limit == -1;
    final isNotAvailable = limit == 0;
    final progress = isUnlimited || isNotAvailable
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);

    String valueText;
    if (isUnlimited) {
      valueText = '$used / \u221E';
    } else if (isNotAvailable) {
      valueText = 'Not Available';
    } else {
      valueText = '$used / $limit';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            isNotAvailable ? Icons.lock : icon,
            color: isNotAvailable
                ? AppColors.textTertiary
                : AppColors.richGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isNotAvailable
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      valueText,
                      style: TextStyle(
                        color: isNotAvailable
                            ? AppColors.textTertiary
                            : isUnlimited
                                ? AppColors.richGold
                                : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!isNotAvailable && !isUnlimited) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0
                            ? AppColors.errorRed
                            : AppColors.richGold,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierComparison(MembershipRules currentRules) {
    // Get next tier
    MembershipTier nextTier;
    switch (_liveMembershipTier) {
      case MembershipTier.free:
        nextTier = MembershipTier.silver;
        break;
      case MembershipTier.silver:
        nextTier = MembershipTier.gold;
        break;
      case MembershipTier.gold:
        nextTier = MembershipTier.platinum;
        break;
      default:
        return const SizedBox.shrink();
    }

    final nextRules = MembershipRules.getDefaultsForTier(nextTier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MembershipBadge(tier: nextTier, compact: true),
              const SizedBox(width: 8),
              Text(
                'With ${nextTier.displayName}',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildComparisonRow('Swipes', currentRules.dailySwipeLimit, nextRules.dailySwipeLimit),
          _buildComparisonRow('Super Likes', currentRules.dailySuperLikeLimit, nextRules.dailySuperLikeLimit),
          _buildComparisonRow('Messages', currentRules.dailyMessageLimit, nextRules.dailyMessageLimit),
          _buildComparisonRow('Media Sends', currentRules.dailyMediaSendLimit, nextRules.dailyMediaSendLimit),
          _buildComparisonRow('Free Boosts/mo', currentRules.monthlyFreeBoosts, nextRules.monthlyFreeBoosts),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, int current, int next) {
    String formatLimit(int val) {
      if (val == -1) return '\u221E';
      return val.toString();
    }

    final isUpgrade = next > current || (next == -1 && current != -1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              Text(
                formatLimit(current),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                formatLimit(next),
                style: TextStyle(
                  color: isUpgrade ? AppColors.richGold : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isUpgrade ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
