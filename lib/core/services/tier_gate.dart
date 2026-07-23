import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/membership/domain/entities/membership.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';
import '../../features/subscription/presentation/screens/subscription_selection_screen.dart';
import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../di/injection_container.dart' as di;
import '../widgets/limit_reached_dialog.dart';
import 'tier_entitlements.dart';
import 'tier_limits_service.dart';
import 'usage_limit_service.dart';

/// Allow / deny result for a single tier-gated action.
///
/// [limit] is `null` when the action is unlimited for the resolved [tier]
/// (∞). [current] is the usage counted so far in the relevant window.
class TierGateResult {
  const TierGateResult({
    required this.allowed,
    required this.tier,
    required this.current,
    required this.limit,
  });

  final bool allowed;
  final MembershipTier tier;
  final int current;

  /// null = unlimited (∞).
  final int? limit;

  bool get isUnlimited => limit == null;
}

/// Central membership-tier ENFORCEMENT gate.
///
/// Resolves the user's tier from `profiles/{uid}.membershipTier` and answers
/// "is the user allowed to do X right now?" for the actions whose caps live in
/// [TierEntitlements]:
///   • daily new-people connects (vs [TierEntitlements.maxDailyConnects]),
///   • profile boosts this month (vs [TierEntitlements.boostsPerMonth]),
///   • create-event / create-group (delegated to [TierLimitsService]).
///
/// The `ensureX` helpers additionally surface the upgrade path (reusing
/// [LimitReachedDialog] / [FeatureNotAvailableDialog]) and route to the
/// membership marketplace on deny, returning `false` so callers can bail.
///
/// Counting is cheap and per-user: daily connects reuse [UsageLimitService]'s
/// day counters; monthly boosts use a dedicated `usageLimits/{uid}/months`
/// document so they survive logout/login and scale (single indexed read).
class TierGate {
  TierGate({
    FirebaseFirestore? firestore,
    TierLimitsService? tierLimits,
    UsageLimitService? usageLimits,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _tierLimits = tierLimits ?? TierLimitsService(),
        _usageLimits = usageLimits ?? UsageLimitService();

  final FirebaseFirestore _firestore;
  final TierLimitsService _tierLimits;
  final UsageLimitService _usageLimits;

  // ── Tier resolution ────────────────────────────────────────────────────────

  /// Reads the user's membership tier from `profiles/{uid}.membershipTier`.
  /// Falls back to [MembershipTier.free] on any error or missing value.
  Future<MembershipTier> resolveTier(String uid) async {
    try {
      // Hard timeout: an online-but-degraded Firestore socket can leave a
      // default-source .get() pending forever. Bound it so the caller (the
      // connect flow's loading barrier) can never hang — on timeout the catch
      // below falls back to the free tier.
      final doc = await _firestore
          .collection('profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      final raw = doc.data()?['membershipTier'] as String?;
      if (raw == null) return MembershipTier.free;
      return MembershipTier.fromString(raw);
    } catch (_) {
      return MembershipTier.free;
    }
  }

  // ── Daily connects ─────────────────────────────────────────────────────────

  /// Whether [uid] may start a NEW connection today under their tier's
  /// [TierEntitlements.maxDailyConnects] cap (null cap = unlimited).
  Future<TierGateResult> canConnectToday(String uid) async {
    final tier = await resolveTier(uid);
    final limit = TierEntitlements.maxDailyConnects(tier);
    if (limit == null) {
      return TierGateResult(
          allowed: true, tier: tier, current: 0, limit: null);
    }
    final current =
        await _usageLimits.getCurrentUsage(uid, UsageLimitType.connects);
    return TierGateResult(
      allowed: current < limit,
      tier: tier,
      current: current,
      limit: limit,
    );
  }

  /// Counts one successful NEW connection toward today's cap.
  Future<void> recordConnect(String uid) {
    return _usageLimits.recordUsage(
      userId: uid,
      limitType: UsageLimitType.connects,
    );
  }

  // ── Monthly boosts ─────────────────────────────────────────────────────────

  /// Whether [uid] may activate a profile boost this month under their tier's
  /// [TierEntitlements.boostsPerMonth] allotment. A 0 allotment (Base) is
  /// always denied — boosts are simply not included on that plan.
  Future<TierGateResult> canBoost(String uid) async {
    final tier = await resolveTier(uid);
    final limit = TierEntitlements.boostsPerMonth(tier);
    if (limit <= 0) {
      return TierGateResult(allowed: false, tier: tier, current: 0, limit: limit);
    }
    final current = await _boostsThisMonth(uid);
    return TierGateResult(
      allowed: current < limit,
      tier: tier,
      current: current,
      limit: limit,
    );
  }

  /// Counts one activated boost toward this month's allotment.
  Future<void> recordBoost(String uid) async {
    try {
      await _firestore
          .collection('usageLimits')
          .doc(uid)
          .collection('months')
          .doc(_monthKey())
          .set({
        'boostCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal: an uncounted boost simply isn't debited against the cap.
    }
  }

  Future<int> _boostsThisMonth(String uid) async {
    try {
      final doc = await _firestore
          .collection('usageLimits')
          .doc(uid)
          .collection('months')
          .doc(_monthKey())
          .get();
      return (doc.data()?['boostCount'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Monthly key: YYYY-MM (resets every calendar month).
  String _monthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ── Create event / group (pass-through to TierLimitsService) ────────────────

  Future<TierLimitResult> canCreateEvent(String uid) =>
      _tierLimits.canCreateEvent(uid);

  Future<TierLimitResult> canCreateGroup(String uid) =>
      _tierLimits.canCreateGroup(uid);

  // ── ensureX: gate + surface the upgrade path on deny ────────────────────────

  /// Returns true if the user may connect today; otherwise shows the upgrade
  /// dialog (routing to the membership marketplace) and returns false.
  Future<bool> ensureConnect(BuildContext context, String uid) async {
    final result = await canConnectToday(uid);
    if (result.allowed) return true;
    if (!context.mounted) return false;
    await showConnectLimitDialog(context, uid, result);
    return false;
  }

  /// Returns true if the user may boost this month; otherwise shows either the
  /// "feature not on your plan" dialog (Base) or the monthly-limit dialog and
  /// returns false.
  Future<bool> ensureBoost(BuildContext context, String uid) async {
    final result = await canBoost(uid);
    if (result.allowed) return true;
    if (!context.mounted) return false;

    if ((result.limit ?? 0) <= 0) {
      // Base tier — boosts are not part of the plan at all.
      final l10n = AppLocalizations.of(context)!;
      final r = await FeatureNotAvailableDialog.show(
        context: context,
        featureName: l10n.boostFeatureName,
        description: l10n.boostRequiresTierDescription,
        currentTier: result.tier,
        requiredTier: MembershipTier.silver,
        userId: uid,
        icon: Icons.flash_on,
      );
      if (context.mounted) _maybeUpgrade(context, r, uid);
      return false;
    }

    // Paid tier — monthly allotment exhausted.
    final l10n = AppLocalizations.of(context)!;
    final usageResult = UsageLimitResult(
      isAllowed: false,
      currentUsage: result.current,
      limit: result.limit ?? 0,
      remaining: 0,
      message: l10n.boostMonthlyLimitReached(result.limit ?? 0),
      currentTier: result.tier,
      suggestedTier: _nextTier(result.tier),
    );
    final r = await LimitReachedDialog.show(
      context: context,
      limitResult: usageResult,
      userId: uid,
    );
    if (context.mounted) _maybeUpgrade(context, r, uid);
    return false;
  }

  /// Returns true if travel/traveler mode is enabled for the user's tier;
  /// otherwise shows the "feature not on your plan" dialog and returns false.
  ///
  /// Pass [knownTier] to skip the Firestore read when the caller already holds
  /// the user's tier (e.g. from a loaded profile).
  Future<bool> ensureTravelMode(
    BuildContext context,
    String uid, {
    MembershipTier? knownTier,
  }) async {
    final tier = knownTier ?? await resolveTier(uid);
    if (TierEntitlements.travelModeEnabled(tier)) return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final r = await FeatureNotAvailableDialog.show(
      context: context,
      featureName: l10n.travelModeFeatureName,
      description: l10n.travelModeRequiresTierDescription,
      currentTier: tier,
      requiredTier: MembershipTier.silver,
      userId: uid,
      icon: Icons.flight,
    );
    if (context.mounted) _maybeUpgrade(context, r, uid);
    return false;
  }

  /// Returns true if the Analytics dashboard is unlocked for the user's tier
  /// (Platinum only); otherwise shows the "feature not on your plan" dialog
  /// (routing to the membership marketplace) and returns false.
  ///
  /// Pass [knownTier] to skip the Firestore read when the caller already holds
  /// the user's tier (e.g. from a loaded profile).
  Future<bool> ensureAnalytics(
    BuildContext context,
    String uid, {
    MembershipTier? knownTier,
  }) async {
    final tier = knownTier ?? await resolveTier(uid);
    if (TierEntitlements.analyticsEnabled(tier)) return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final r = await FeatureNotAvailableDialog.show(
      context: context,
      featureName: l10n.analyticsTitle,
      description: l10n.analyticsPlatinumOnly,
      currentTier: tier,
      requiredTier: MembershipTier.platinum,
      userId: uid,
      icon: Icons.insights,
    );
    if (context.mounted) _maybeUpgrade(context, r, uid);
    return false;
  }

  // ── Valid-membership gate (chat / groups / events) ──────────────────────────

  /// Whether [p]'s GreenGo membership is currently VALID.
  ///
  /// A valid membership is the precondition for chatting, creating groups and
  /// creating events. The default active Base (free) membership is ALWAYS
  /// valid — this only returns false on a REAL not-valid signal:
  ///   • a paid tier whose [Profile.membershipEndDate] is in the past, or
  ///   • a legacy base membership whose [Profile.baseMembershipEndDate] has
  ///     passed.
  /// With no such signal it defaults to `true`, so normal users are never
  /// blocked.
  bool hasValidMembership(Profile p) {
    if (p.membershipTier == MembershipTier.test) return true;
    final now = DateTime.now();
    // Expired PAID membership.
    if (p.membershipTier != MembershipTier.free &&
        p.membershipEndDate != null &&
        !p.membershipEndDate!.isAfter(now)) {
      return false;
    }
    // Expired legacy base membership.
    if (p.hasBaseMembership &&
        p.baseMembershipEndDate != null &&
        !p.baseMembershipEndDate!.isAfter(now)) {
      return false;
    }
    return true; // active Base / free → allowed by default.
  }

  /// Returns true if [p]'s membership is valid; otherwise shows the glass
  /// "renew membership" dialog (routing to the membership marketplace) and
  /// returns false so the caller can abort the gated action.
  Future<bool> ensureValidMembership(BuildContext context, Profile p) async {
    if (hasValidMembership(p)) return true;
    if (!context.mounted) return false;
    await _showRenewMembershipDialog(context, p.userId);
    return false;
  }

  /// uid-only variant of [ensureValidMembership] for call sites that hold a
  /// user id but not a loaded [Profile]. Reads the membership fields from
  /// `profiles/{uid}` and applies the exact same predicate — defaults to
  /// allowed, never blocking on a read error or a missing document.
  Future<bool> ensureValidMembershipByUid(
      BuildContext context, String uid) async {
    if (await _isMembershipValidByUid(uid)) return true;
    if (!context.mounted) return false;
    await _showRenewMembershipDialog(context, uid);
    return false;
  }

  Future<bool> _isMembershipValidByUid(String uid) async {
    try {
      final doc = await _firestore.collection('profiles').doc(uid).get();
      final data = doc.data();
      if (data == null) return true; // no signal → allowed.
      final raw = data['membershipTier'] as String?;
      final tier =
          raw == null ? MembershipTier.free : MembershipTier.fromString(raw);
      if (tier == MembershipTier.test) return true;
      final now = DateTime.now();
      final endTs = data['membershipEndDate'];
      final endDate = endTs is Timestamp ? endTs.toDate() : null;
      if (tier != MembershipTier.free &&
          endDate != null &&
          !endDate.isAfter(now)) {
        return false;
      }
      final hasBase = data['hasBaseMembership'] as bool? ?? false;
      final baseTs = data['baseMembershipEndDate'];
      final baseEnd = baseTs is Timestamp ? baseTs.toDate() : null;
      if (hasBase && baseEnd != null && !baseEnd.isAfter(now)) {
        return false;
      }
      return true;
    } catch (_) {
      return true; // never block on error.
    }
  }

  /// Glass "renew membership" dialog. On confirm, routes to the membership
  /// marketplace via [openMembershipUpgrade].
  Future<void> _showRenewMembershipDialog(
      BuildContext context, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final renew = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.richGold,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.membershipRequiredTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.membershipRequiredBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      l10n.renewMembership,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l10n.notNow,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (renew == true && context.mounted) {
      openMembershipUpgrade(context, currentUserId: uid);
    }
  }

  /// Shows the daily-connect limit dialog and routes to upgrade on accept.
  /// Public so callers that manage their own loading barrier (e.g. the connect
  /// flow) can dismiss it first and then surface the dialog.
  Future<void> showConnectLimitDialog(
    BuildContext context,
    String uid,
    TierGateResult result,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final usageResult = UsageLimitResult(
      isAllowed: false,
      currentUsage: result.current,
      limit: result.limit ?? 0,
      remaining: 0,
      message: l10n.connectDailyLimitReached(result.limit ?? 0),
      currentTier: result.tier,
      suggestedTier: _nextTier(result.tier),
    );
    final r = await LimitReachedDialog.show(
      context: context,
      limitResult: usageResult,
      userId: uid,
    );
    if (context.mounted) _maybeUpgrade(context, r, uid);
  }

  /// Pushes the membership marketplace (wrapped with its [SubscriptionBloc]).
  void openMembershipUpgrade(BuildContext context, {String? currentUserId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<SubscriptionBloc>(),
          child: MembershipSelectionScreen(currentUserId: currentUserId),
        ),
      ),
    );
  }

  void _maybeUpgrade(BuildContext context, LimitDialogResult? r, String uid) {
    if (r?.action == LimitDialogAction.upgrade) {
      openMembershipUpgrade(context, currentUserId: uid);
    }
  }

  /// The next tier up (for the "upgrade to" suggestion). null at the top.
  MembershipTier? _nextTier(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return MembershipTier.silver;
      case MembershipTier.silver:
        return MembershipTier.gold;
      case MembershipTier.gold:
        return MembershipTier.platinum;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return null;
    }
  }
}
