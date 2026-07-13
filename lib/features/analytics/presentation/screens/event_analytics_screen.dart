import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../data/services/analytics_service.dart';
import '../widgets/audience_charts.dart';
import '../widgets/stat_grid.dart';

/// Per-event analytics dashboard (Platinum-gated).
///
/// Shows headline RSVP stats for ONE event (going / waitlist / checked-in and
/// the check-in rate) plus the same k-anonymized audience charts (age, country,
/// interests) restricted to THAT event's attendees. Every number is aggregated
/// — no individual attendee is ever surfaced.
///
/// The screen re-checks [TierEntitlements.analyticsEnabled] itself so it stays
/// safe even if opened without going through the tier gate.
class EventAnalyticsScreen extends StatefulWidget {
  const EventAnalyticsScreen({
    required this.eventId,
    required this.tier,
    this.eventTitle,
    super.key,
  });

  final String eventId;
  final MembershipTier tier;
  final String? eventTitle;

  @override
  State<EventAnalyticsScreen> createState() => _EventAnalyticsScreenState();
}

class _EventAnalyticsScreenState extends State<EventAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  late final bool _unlocked = TierEntitlements.analyticsEnabled(widget.tier);
  late Future<EventAudienceAggregate> _future;

  @override
  void initState() {
    super.initState();
    if (_unlocked) {
      _future = _analyticsService.aggregateEventAudience(widget.eventId);
    }
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
          widget.eventTitle ?? l10n.eventAnalyticsTitle,
          overflow: TextOverflow.ellipsis,
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

  Widget _buildDashboard(AppLocalizations l10n) {
    return FutureBuilder<EventAudienceAggregate>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
            ),
          );
        }
        final agg = snapshot.data ?? const EventAudienceAggregate.empty();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatGrid(items: _headlineStats(l10n, agg)),
              const SizedBox(height: 24),
              if (agg.tierBreakdown.isNotEmpty) ...[
                AudienceChartCard(
                  title: l10n.eventAnalyticsTierBreakdown,
                  icon: Icons.confirmation_number_outlined,
                  child: TierBreakdownChart(
                    data: agg.tierBreakdown,
                    animate: !MediaQuery.of(context).disableAnimations,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ...buildAudienceCharts(context, agg.audience, l10n),
            ],
          ),
        );
      },
    );
  }

  /// Headline stat tiles — the SAME colored [StatGrid] the Business analytics
  /// dashboard uses, scoped to this one event's RSVP funnel.
  List<StatItem> _headlineStats(
      AppLocalizations l10n, EventAudienceAggregate agg) {
    final pct = (agg.checkInRate * 100).round();
    return [
      StatItem(
        icon: Icons.visibility_outlined,
        label: l10n.eventAnalyticsViews,
        value: '${agg.viewCount}',
        accent: StatColors.sky,
      ),
      StatItem(
        icon: Icons.check_circle_outline,
        label: l10n.eventAnalyticsGoing,
        value: '${agg.goingCount}',
        accent: StatColors.teal,
      ),
      StatItem(
        icon: Icons.hourglass_bottom,
        label: l10n.eventAnalyticsWaitlist,
        value: '${agg.waitlistCount}',
        accent: StatColors.gold,
      ),
      StatItem(
        icon: Icons.how_to_reg,
        label: l10n.eventAnalyticsCheckedIn,
        value: '${agg.checkedInCount}',
        accent: StatColors.violet,
      ),
      StatItem(
        icon: Icons.percent,
        label: l10n.eventAnalyticsCheckInRate,
        value: '$pct%',
        accent: StatColors.emerald,
      ),
    ];
  }

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
                    onPressed: () => SafeNavigation.pop(context),
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
