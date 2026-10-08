import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../generated/app_localizations.dart';
import '../../features/subscription/presentation/tier_l10n.dart';
import '../utils/app_l10n_lookup.dart';

/// Types of usage limits that can be tracked
enum UsageLimitType {
  swipes,           // Legacy — all swipes combined (daily)
  likes,            // Connects (right swipes) — hourly
  nopes,            // Passes (left swipes) — hourly
  superLikes,            // Priority connects — hourly
  dailySuperLikes,       // Priority connects — daily cap
  messages,         // Daily
  mediaSends,       // Daily
  directMatch,      // Direct match (direct message) — daily free quota, then coins
  connects,         // New-people connects / first-messages — daily (tier-gated)
}

/// Result of checking a usage limit
class UsageLimitResult {

  const UsageLimitResult({
    required this.isAllowed,
    required this.currentUsage,
    required this.limit,
    required this.remaining,
    required this.message,
    required this.currentTier,
    this.suggestedTier,
  });
  final bool isAllowed;
  final int currentUsage;
  final int limit;
  final int remaining;
  final String message;
  final MembershipTier currentTier;
  final MembershipTier? suggestedTier;

  bool get isUnlimited => limit == -1;
}

/// Service to track and enforce usage limits based on membership tier.
///
/// Likes, nopes, and priority connects are tracked HOURLY.
/// Messages and media sends are tracked DAILY.
/// Boosts are tracked MONTHLY.
/// All data is persisted in Firestore so it survives logout/login.
class UsageLimitService {

  UsageLimitService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  // ─── Time keys ───────────────────────────────────────────────

  /// Hourly key: YYYY-MM-DD-HH (resets every hour)
  String _getHourKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}';
  }

  /// Daily key: YYYY-MM-DD (resets every day)
  String _getDayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Whether this limit type uses hourly tracking
  bool _isHourlyType(UsageLimitType type) {
    return type == UsageLimitType.likes ||
        type == UsageLimitType.nopes ||
        type == UsageLimitType.superLikes;
  }

  /// Get the correct time key for a limit type
  String _getTimeKey(UsageLimitType type) {
    return _isHourlyType(type) ? _getHourKey() : _getDayKey();
  }

  /// Get Firestore subcollection name for a limit type
  String _getSubcollection(UsageLimitType type) {
    return _isHourlyType(type) ? 'hours' : 'days';
  }

  // ─── Check limit ─────────────────────────────────────────────

  /// Check if a user can perform an action based on their limits
  Future<UsageLimitResult> checkLimit({
    required String userId,
    required UsageLimitType limitType,
    required MembershipRules rules,
    required MembershipTier currentTier,
  }) async {
    final limit = _getLimit(limitType, rules);
    // [UsageLimitResult.message] is shown to the user (dialog / snackbar), so
    // it is built in the app's current language.
    final l10n = await currentAppL10nAsync();

    // If unlimited, always allow
    if (limit == -1) {
      return UsageLimitResult(
        isAllowed: true,
        currentUsage: 0,
        limit: -1,
        remaining: -1,
        message: l10n.usageLimitUnlimited(_getLimitTypeName(l10n, limitType)),
        currentTier: currentTier,
      );
    }

    final currentUsage = await _getCurrentUsage(userId, limitType);
    final remaining = limit - currentUsage;
    final isAllowed = remaining > 0;

    return UsageLimitResult(
      isAllowed: isAllowed,
      currentUsage: currentUsage,
      limit: limit,
      remaining: remaining > 0 ? remaining : 0,
      message: isAllowed
          ? (_isHourlyType(limitType)
              ? l10n.usageLimitRemainingThisHour(
                  remaining, _getLimitTypeName(l10n, limitType))
              : l10n.usageLimitRemainingToday(
                  remaining, _getLimitTypeName(l10n, limitType)))
          : _getLimitReachedMessage(l10n, limitType, limit, currentTier),
      currentTier: currentTier,
      suggestedTier: isAllowed ? null : _getSuggestedTier(limitType, currentTier),
    );
  }

  // ─── Record usage ────────────────────────────────────────────

  /// Record a usage action (persisted in Firestore)
  Future<void> recordUsage({
    required String userId,
    required UsageLimitType limitType,
    int count = 1,
  }) async {
    final timeKey = _getTimeKey(limitType);
    final subcollection = _getSubcollection(limitType);
    final docRef = _firestore
        .collection('usageLimits')
        .doc(userId)
        .collection(subcollection)
        .doc(timeKey);

    final fieldName = _getFieldName(limitType);

    await docRef.set({
      fieldName: FieldValue.increment(count),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also update local cache for faster checks
    await _updateLocalCache(userId, limitType, count);
  }

  // ─── Read current usage ──────────────────────────────────────

  /// Get current usage count for a limit type
  Future<int> _getCurrentUsage(String userId, UsageLimitType limitType) async {
    // Try local cache first for faster response
    final cachedUsage = await _getLocalCache(userId, limitType);
    if (cachedUsage != null) {
      return cachedUsage;
    }

    final timeKey = _getTimeKey(limitType);
    final subcollection = _getSubcollection(limitType);
    final docRef = _firestore
        .collection('usageLimits')
        .doc(userId)
        .collection(subcollection)
        .doc(timeKey);

    try {
      // Bounded: a default-source .get() can hang on a degraded connection, and
      // this read sits inside the connect flow's loading barrier. On timeout the
      // catch returns 0 (treat as no usage) so the flow never stalls.
      final doc = await docRef.get().timeout(const Duration(seconds: 6));
      if (doc.exists) {
        final fieldName = _getFieldName(limitType);
        final usage = (doc.data()?[fieldName] as num?)?.toInt() ?? 0;

        // Update local cache
        await _setLocalCache(userId, limitType, usage);

        return usage;
      }
    } catch (e) {
      // On error/timeout, return cached value or 0
    }

    return 0;
  }

  /// Get current usage (public — for usage stats screen)
  Future<int> getCurrentUsage(String userId, UsageLimitType limitType) {
    return _getCurrentUsage(userId, limitType);
  }

  // ─── Limit mapping ──────────────────────────────────────────

  /// Get limit value based on type and rules
  int _getLimit(UsageLimitType limitType, MembershipRules rules) {
    switch (limitType) {
      case UsageLimitType.likes:
        return rules.hourlyConnectLimit;
      case UsageLimitType.nopes:
        return rules.hourlyPassLimit;
      case UsageLimitType.superLikes:
        return rules.hourlyPriorityConnectLimit;
      case UsageLimitType.dailySuperLikes:
        return rules.dailyPriorityConnectLimit;
      case UsageLimitType.swipes:
        return rules.dailySwipeLimit;
      case UsageLimitType.messages:
        return rules.dailyMessageLimit;
      case UsageLimitType.mediaSends:
        return rules.dailyMediaSendLimit;
      case UsageLimitType.directMatch:
        return rules.dailyDirectMatchLimit;
      case UsageLimitType.connects:
        // Connect caps live in TierEntitlements.maxDailyConnects and are
        // enforced by TierGate (not via MembershipRules / checkLimit).
        return -1;
    }
  }

  /// Get field name for Firestore
  String _getFieldName(UsageLimitType limitType) {
    switch (limitType) {
      case UsageLimitType.likes:
        return 'likeCount';
      case UsageLimitType.nopes:
        return 'nopeCount';
      case UsageLimitType.superLikes:
        return 'superLikeCount';
      case UsageLimitType.dailySuperLikes:
        return 'dailySuperLikeCount';
      case UsageLimitType.swipes:
        return 'swipeCount';
      case UsageLimitType.messages:
        return 'messageCount';
      case UsageLimitType.mediaSends:
        return 'mediaSendCount';
      case UsageLimitType.directMatch:
        return 'directMatchCount';
      case UsageLimitType.connects:
        return 'connectsCount';
    }
  }

  /// Get human-readable (localized) name for limit type
  String _getLimitTypeName(AppLocalizations l10n, UsageLimitType limitType) {
    switch (limitType) {
      case UsageLimitType.likes:
        return l10n.usageLimitTypeConnects;
      case UsageLimitType.nopes:
        return l10n.usageLimitTypePasses;
      case UsageLimitType.superLikes:
        return l10n.usageLimitTypePriorityConnects;
      case UsageLimitType.dailySuperLikes:
        return l10n.usageLimitTypeDailyPriorityConnects;
      case UsageLimitType.swipes:
        return l10n.usageLimitTypeSwipes;
      case UsageLimitType.messages:
        return l10n.usageLimitTypeMessages;
      case UsageLimitType.mediaSends:
        return l10n.usageLimitTypeMediaSends;
      case UsageLimitType.directMatch:
        return l10n.usageLimitTypeDirectMatches;
      case UsageLimitType.connects:
        return l10n.usageLimitTypeConnections;
    }
  }

  // ─── Limit-reached messages ──────────────────────────────────

  /// Get (localized) message when limit is reached
  String _getLimitReachedMessage(
    AppLocalizations l10n,
    UsageLimitType limitType,
    int limit,
    MembershipTier currentTier,
  ) {
    switch (limitType) {
      case UsageLimitType.likes:
        return l10n.usageLimitConnectsHourly(limit);
      case UsageLimitType.nopes:
        return l10n.usageLimitPassesHourly(limit);
      case UsageLimitType.superLikes:
        if (limit == 0) {
          return l10n.usageLimitPriorityUnavailable(localizedMembershipTierName(l10n, currentTier));
        }
        return l10n.usageLimitPriorityHourly(limit);
      case UsageLimitType.dailySuperLikes:
        return l10n.usageLimitPriorityDaily(limit);
      case UsageLimitType.swipes:
        return l10n.usageLimitSwipesDaily(limit);
      case UsageLimitType.messages:
        return l10n.usageLimitMessagesDaily(limit);
      case UsageLimitType.mediaSends:
        if (limit == 0) {
          return l10n.usageLimitMediaUnavailable(localizedMembershipTierName(l10n, currentTier));
        }
        return l10n.usageLimitMediaDaily(limit);
      case UsageLimitType.directMatch:
        return l10n.usageLimitDirectMatchDaily(limit);
      case UsageLimitType.connects:
        return l10n.connectDailyLimitReached(limit);
    }
  }

  /// Get suggested tier to upgrade to for more of this limit
  MembershipTier? _getSuggestedTier(UsageLimitType limitType, MembershipTier currentTier) {
    switch (currentTier) {
      case MembershipTier.free:
        return MembershipTier.silver;
      case MembershipTier.silver:
        return MembershipTier.gold;
      case MembershipTier.gold:
        if (limitType == UsageLimitType.superLikes) {
          return MembershipTier.platinum;
        }
        return null; // Gold already has unlimited likes/nopes
      case MembershipTier.platinum:
        return null;
      case MembershipTier.test:
        return null;
    }
  }

  // ─── Local cache (SharedPreferences) ─────────────────────────

  Future<int?> _getLocalCache(String userId, UsageLimitType limitType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(userId, limitType);
      final dateKey = '${key}_period';

      final cachedPeriod = prefs.getString(dateKey);
      final currentPeriod = _getTimeKey(limitType);

      // Only return cached value if it's from the current period
      if (cachedPeriod == currentPeriod) {
        return prefs.getInt(key);
      }

      // Clear stale cache
      await prefs.remove(key);
      await prefs.remove(dateKey);
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  Future<void> _setLocalCache(String userId, UsageLimitType limitType, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(userId, limitType);
      final dateKey = '${key}_period';
      final currentPeriod = _getTimeKey(limitType);

      await prefs.setInt(key, value);
      await prefs.setString(dateKey, currentPeriod);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> _updateLocalCache(String userId, UsageLimitType limitType, int increment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(userId, limitType);
      final dateKey = '${key}_period';
      final currentPeriod = _getTimeKey(limitType);

      final cachedPeriod = prefs.getString(dateKey);
      var currentValue = 0;

      if (cachedPeriod == currentPeriod) {
        currentValue = prefs.getInt(key) ?? 0;
      }

      await prefs.setInt(key, currentValue + increment);
      await prefs.setString(dateKey, currentPeriod);
    } catch (e) {
      // Ignore cache errors
    }
  }

  String _getCacheKey(String userId, UsageLimitType limitType) {
    return 'usage_${userId}_${limitType.name}';
  }

  // ─── Admin / testing helpers ─────────────────────────────────

  /// Reset hourly usage (for testing or admin purposes)
  Future<void> resetHourlyUsage(String userId) async {
    final hourKey = _getHourKey();
    await _firestore
        .collection('usageLimits')
        .doc(userId)
        .collection('hours')
        .doc(hourKey)
        .delete();

    // Clear local cache
    final prefs = await SharedPreferences.getInstance();
    for (final type in [UsageLimitType.likes, UsageLimitType.nopes, UsageLimitType.superLikes]) {
      final key = _getCacheKey(userId, type);
      await prefs.remove(key);
      await prefs.remove('${key}_period');
    }
  }

  /// Reset daily usage (for testing or admin purposes)
  Future<void> resetDailyUsage(String userId) async {
    final dayKey = _getDayKey();
    await _firestore
        .collection('usageLimits')
        .doc(userId)
        .collection('days')
        .doc(dayKey)
        .delete();

    // Clear local cache
    final prefs = await SharedPreferences.getInstance();
    for (final type in UsageLimitType.values) {
      final key = _getCacheKey(userId, type);
      await prefs.remove(key);
      await prefs.remove('${key}_period');
    }
  }

  /// Get all usage stats for a user (current period per type)
  Future<Map<UsageLimitType, int>> getAllUsageStats(String userId) async {
    final stats = <UsageLimitType, int>{};

    for (final type in UsageLimitType.values) {
      stats[type] = await _getCurrentUsage(userId, type);
    }

    return stats;
  }
}
