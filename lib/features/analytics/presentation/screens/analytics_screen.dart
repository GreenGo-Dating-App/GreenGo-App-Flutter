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
  });

  final int eventsHosted;
  final int totalAttendees;
  final int referrals;

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

    return _AnalyticsStats(
      eventsHosted: eventsHosted,
      totalAttendees: totalAttendees,
      referrals: referrals,
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
              _statCard(
                icon: Icons.event_available,
                label: l10n.analyticsEventsHosted,
                value: '${stats.eventsHosted}',
              ),
              const SizedBox(height: 16),
              _statCard(
                icon: Icons.groups,
                label: l10n.analyticsTotalAttendees,
                value: '${stats.totalAttendees}',
              ),
              const SizedBox(height: 16),
              _statCard(
                icon: Icons.trending_up,
                label: l10n.analyticsReach,
                value: '${stats.reach}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(icon, color: AppColors.richGold, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
