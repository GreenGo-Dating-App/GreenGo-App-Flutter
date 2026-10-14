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
import 'effective_tier.dart';
import 'entitlement_usage.dart';
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

/// Free monthly boosts of a user: the plan's allowance and what is left this
/// (UTC) month. Boosts beyond it cost CoinFeaturePrices.boost coins.
class BoostAllowance {
  const BoostAllowance({
    required this.tier,
    required this.allowance,
    required this.used,
  });

  final MembershipTier tier;
  final int allowance;
  final int used;

  int get left => used >= allowance ? 0 : allowance - used;

  /// Boosts are not part of the free plan at all.
  bool get available => allowance > 0;
}

/// Central membership-tier gate (the UX side of the caps).
///
/// Resolves the user's EFFECTIVE tier from `profiles/{uid}` and answers "is the
/// user allowed to do X right now?" for the actions whose caps live in
/// [TierEntitlements]:
///   • daily new-people connects (vs [TierEntitlements.maxDailyConnects]),
///   • free profile boosts this month ([TierEntitlements.boostsPerMonth]),
///   • create-event / create-group (delegated to [TierLimitsService]).
///
/// The SERVER enforces the same caps (Firestore rules + Cloud Functions, audit
/// 2026-10-11); the counts shown here are read from its counters
/// (`entitlement_usage/{uid}`, see entitlement_usage.dart), so the app shows
/// exactly what the server will accept.
///
/// The `ensureX` helpers additionally surface the upgrade path (reusing
/// [LimitReachedDialog] / [FeatureNotAvailableDialog]) and route to the
/// membership marketplace on deny, returning `false` so callers can bail.
class TierGate {
  TierGate({
    FirebaseFirestore? firestore,
    TierLimitsService? tierLimits,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _tierLimits =
            tierLimits ?? TierLimitsService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final TierLimitsService _tierLimits;

  // ── Tier resolution ────────────────────────────────────────────────────────

  /// Resolves the user's EFFECTIVE tier from `profiles/{uid}` — the stored
  /// `membershipTier` only while `membershipEndDate` is in the future (see
  /// [effectiveTierFromDoc]). Falls back to [MembershipTier.free] on any
  /// error or missing value.
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
      return effectiveTierFromDoc(doc.data());
    } catch (_) {
      return MembershipTier.free;
    }
  }

  /// The server-owned usage counters of [uid] (null when none yet).
  Future<Map<String, dynamic>?> _usage(String uid) async {
    try {
      final doc = await _firestore
          .collection(kEntitlementUsageCollection)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // ── Daily connects ─────────────────────────────────────────────────────────

  /// Whether [uid] may start a NEW connection today under their tier's
  /// [TierEntitlements.maxDailyConnects] cap (null cap = unlimited). Counted
  /// by the server per UTC day; the rules refuse the create over the cap.
  Future<TierGateResult> canConnectToday(String uid) async {
    final tier = await resolveTier(uid);
    final limit = TierEntitlements.maxDailyConnects(tier);
    if (limit == null) {
      return TierGateResult(
          allowed: true, tier: tier, current: 0, limit: null);
    }
    final current = connectsTodayFrom(await _usage(uid), DateTime.now());
    return TierGateResult(
      allowed: current < limit,
      tier: tier,
      current: current,
      limit: limit,
    );
  }

  // ── Monthly boosts ─────────────────────────────────────────────────────────

  /// The free boosts of [uid]'s plan and how many are left this month.
  Future<BoostAllowance> boostAllowance(String uid,
      {MembershipTier? knownTier}) async {
    final tier = knownTier ?? await resolveTier(uid);
    final allowance = TierEntitlements.boostsPerMonth(tier);
    final used = allowance > 0
        ? freeBoostsUsedFrom(await _usage(uid), DateTime.now())
        : 0;
    return BoostAllowance(tier: tier, allowance: allowance, used: used);
  }

  /// Whether [uid] may boost at all: every paid plan may (free boosts first,
  /// then coins); the free plan may not.
  Future<TierGateResult> canBoost(String uid) async {
    final a = await boostAllowance(uid);
    return TierGateResult(
      allowed: a.available,
      tier: a.tier,
      current: a.used,
      limit: a.allowance,
    );
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

  /// Returns true if [uid] may create another event: under their tier's
  /// ACTIVE-at-a-time allowance (Base 1, Silver 5, Gold 10, Platinum
  /// unlimited). Otherwise shows how many are active against the allowance
  /// with the upgrade path, and returns false. Ending or deleting an event
  /// frees a slot; extra events cannot be bought.
  Future<bool> ensureCreateEvent(BuildContext context, String uid) async {
    final result = await canCreateEvent(uid);
    if (result.allowed) return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final r = await FeatureNotAvailableDialog.show(
      context: context,
      featureName: l10n.shopEventsCreate,
      description: l10n.tierLimitEventsBody(result.max ?? 0, result.current),
      currentTier: result.tier,
      requiredTier: TierEntitlements.nextTierForMoreListings(result.tier) ??
          MembershipTier.platinum,
      userId: uid,
      icon: Icons.event_available,
    );
    if (context.mounted) _maybeUpgrade(context, r, uid);
    return false;
  }

  /// Returns true if the user's plan includes boosts (free monthly boosts,
  /// then coins); on the free plan shows the "feature not on your plan"
  /// dialog and returns false.
  Future<bool> ensureBoost(BuildContext context, String uid) async {
    final result = await canBoost(uid);
    if (result.allowed) return true;
    if (!context.mounted) return false;
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
  /// creating events. A lapsed PAID tier is NOT a not-valid signal on its own:
  /// the user simply falls back to what they had before (Base / free), exactly
  /// as after the server's downgrade job. This only returns false when a
  /// legacy base membership's [Profile.baseMembershipEndDate] has passed and
  /// no paid tier is active. With no such signal it defaults to `true`, so
  /// normal users are never blocked.
  bool hasValidMembership(Profile p) => _isValid(
        effective: p.effectiveTier,
        hasBase: p.hasBaseMembership,
        baseEnd: p.baseMembershipEndDate,
      );

  static bool _isValid({
    required MembershipTier effective,
    required bool hasBase,
    required DateTime? baseEnd,
  }) {
    if (effective != MembershipTier.free) return true; // active paid / TEST
    // Expired legacy base membership.
    if (hasBase && baseEnd != null && !baseEnd.isAfter(DateTime.now())) {
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
      return _isValid(
        effective: effectiveTierFromDoc(data),
        hasBase: data['hasBaseMembership'] as bool? ?? false,
        baseEnd: tierDateFromValue(data['baseMembershipEndDate']),
      );
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
