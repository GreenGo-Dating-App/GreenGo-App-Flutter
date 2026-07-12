import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../data/services/analytics_service.dart';
import '../widgets/audience_charts.dart';
import '../widgets/stat_grid.dart';

/// Immutable snapshot of a business/organizer's own analytics.
///
/// All numbers are derived from the organizer's OWN data with bounded,
/// index-free reads (single-field equality + one doc read), so this scales
/// per-user without composite indexes.
class _AnalyticsStats {
  const _AnalyticsStats({
    required this.eventsHosted,
    required this.totalAttendees,
    required this.referrals,
    this.audience = const AudienceAggregate.empty(),
    this.insights = const BusinessInsights.empty(),
  });

  final int eventsHosted;
  final int totalAttendees;
  final int referrals;

  /// Aggregated, k-anonymized demographics of the organizer's audience.
  final AudienceAggregate audience;

  /// Bounded aggregate business insights (event views, community reach, chats).
  final BusinessInsights insights;

  /// Simple derived reach: everyone the organizer has touched — attendees
  /// across their events plus friends they've invited.
  int get reach => totalAttendees + referrals;
}

/// Platinum-only business analytics dashboard.
///
/// For a Platinum organizer this shows a handful of glass stat cards derived
/// from their own Firestore data (events hosted, total attendees, referral
/// reach). For every other tier it renders a locked / upgrade state.
///
/// The screen is defensive: it re-checks [TierEntitlements.analyticsEnabled]
/// itself so it stays safe even if opened without going through
/// [TierGate.ensureAnalytics].
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    required this.userId,
    required this.tier,
    super.key,
  });

  final String userId;
  final MembershipTier tier;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analyticsService = AnalyticsService();

  late final bool _unlocked = TierEntitlements.analyticsEnabled(widget.tier);
  late Future<_AnalyticsStats> _future;

  @override
  void initState() {
    super.initState();
    if (_unlocked) {
      _future = _loadStats();
    }
  }

  /// Bounded, index-free load of the organizer's own stats.
  Future<_AnalyticsStats> _loadStats() async {
    var eventsHosted = 0;
    var totalAttendees = 0;
    var referrals = 0;

    try {
      // events where organizerId == uid — single-field equality, capped.
      final events = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: widget.userId)
          .limit(500)
          .get();
      eventsHosted = events.docs.length;
      for (final doc in events.docs) {
        totalAttendees += (doc.data()['attendeeCount'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      // Non-fatal: leave the events-derived stats at zero.
    }

    try {
      // referrals/{uid} = { invitedCount, ... } — one doc read.
      final ref = await _firestore.collection('referrals').doc(widget.userId).get();
      referrals = (ref.data()?['invitedCount'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Non-fatal.
    }

    // Aggregated, privacy-safe audience demographics (bounded fan-out).
    var audience = const AudienceAggregate.empty();
    try {
      audience = await _analyticsService.aggregateBusinessAudience(widget.userId);
    } catch (_) {
      // Non-fatal: charts fall back to their insufficient-data state.
    }

    // Bounded aggregate insights: event views, community reach, chats involved.
    var insights = const BusinessInsights.empty();
    try {
      insights = await _analyticsService.aggregateBusinessInsights(widget.userId);
    } catch (_) {
      // Non-fatal: insight cards fall back to zeros.
    }

    return _AnalyticsStats(
      eventsHosted: eventsHosted,
      totalAttendees: totalAttendees,
      referrals: referrals,
      audience: audience,
      insights: insights,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(
          l10n.analyticsTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _unlocked ? _buildDashboard(l10n) : _buildLocked(l10n),
    );
  }

  // ── Unlocked (Platinum) dashboard ──────────────────────────────────────────

  Widget _buildDashboard(AppLocalizations l10n) {
    return FutureBuilder<_AnalyticsStats>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
            ),
          );
        }
        final stats = snapshot.data ??
            const _AnalyticsStats(
              eventsHosted: 0,
              totalAttendees: 0,
              referrals: 0,
            );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatGrid(items: _headlineStats(stats, l10n)),
              const SizedBox(height: 24),
              ...buildAudienceCharts(context, stats.audience, l10n),
            ],
          ),
        );
      },
    );
  }

  /// The six headline metrics surfaced as the colored 3×2 stat grid.
  ///
  /// Each gets a distinct, tasteful accent from the curated [StatColors]
  /// palette so the row reads as one premium system on the dark glass theme.
  List<StatItem> _headlineStats(_AnalyticsStats stats, AppLocalizations l10n) {
    final chats = stats.insights.cappedChats
        ? '${stats.insights.chatsInvolved}+'
        : '${stats.insights.chatsInvolved}';
    return [
      StatItem(
        icon: Icons.visibility_outlined,
        label: l10n.analyticsEventViews,
        value: '${stats.insights.totalEventViews}',
        accent: StatColors.sky,
      ),
      StatItem(
        icon: Icons.groups,
        label: l10n.analyticsTotalAttendees,
        value: '${stats.totalAttendees}',
        accent: StatColors.teal,
      ),
      StatItem(
        icon: Icons.event_available,
        label: l10n.analyticsEventsHosted,
        value: '${stats.eventsHosted}',
        accent: StatColors.gold,
      ),
      StatItem(
        icon: Icons.diversity_3,
        label: l10n.analyticsCommunityReach,
        value: '${stats.insights.communityMembers}',
        accent: StatColors.violet,
      ),
      StatItem(
        icon: Icons.forum_outlined,
        label: l10n.analyticsChatsInvolved,
        value: chats,
        accent: StatColors.coral,
      ),
      StatItem(
        icon: Icons.trending_up,
        label: l10n.analyticsReach,
        value: '${stats.reach}',
        accent: StatColors.emerald,
      ),
    ];
  }

  // ── Locked (non-Platinum) upgrade state ────────────────────────────────────

  Widget _buildLocked(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights,
                    color: AppColors.richGold, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.analyticsPlatinumOnly,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppGlass.radiusPill),
                    boxShadow: AppGlass.goldGlow,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppGlass.radiusPill),
                      ),
                    ),
                    onPressed: () => TierGate()
                        .openMembershipUpgrade(context,
                            currentUserId: widget.userId),
                    child: Text(
                      l10n.analyticsUpgradeCta,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
