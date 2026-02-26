import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/membership/domain/entities/membership.dart';

/// Types of usage limits that can be tracked
enum UsageLimitType {
  swipes,           // Legacy — all swipes combined (daily)
  likes,            // Right swipes — hourly
  nopes,            // Left swipes — hourly
  superLikes,       // Up swipes — hourly
  dailySuperLikes,  // Up swipes — daily cap
  messages,         // Daily
  mediaSends,       // Daily
}

/// Result of checking a usage limit
class UsageLimitResult {
  final bool isAllowed;
  final int currentUsage;
  final int limit;
  final int remaining;
  final String message;
  final MembershipTier currentTier;
  final MembershipTier? suggestedTier;

  const UsageLimitResult({
    required this.isAllowed,
    required this.currentUsage,
    required this.limit,
    required this.remaining,
    required this.message,
    required this.currentTier,
    this.suggestedTier,
  });

  bool get isUnlimited => limit == -1;
}

/// Service to track and enforce usage limits based on membership tier.
///
/// Likes, nopes, and super likes are tracked HOURLY.
/// Messages and media sends are tracked DAILY.
/// Boosts are tracked MONTHLY.
/// All data is persisted in Firestore so it survives logout/login.
class UsageLimitService {
  final FirebaseFirestore _firestore;

  UsageLimitService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

    // If unlimited, always allow
    if (limit == -1) {
      return UsageLimitResult(
        isAllowed: true,
        currentUsage: 0,
        limit: -1,
        remaining: -1,
        message: 'Unlimited ${_getLimitTypeName(limitType)}',
        currentTier: currentTier,
      );
    }

    final currentUsage = await _getCurrentUsage(userId, limitType);
    final remaining = limit - currentUsage;
    final isAllowed = remaining > 0;

    final periodLabel = _isHourlyType(limitType) ? 'this hour' : 'today';

    return UsageLimitResult(
      isAllowed: isAllowed,
      currentUsage: currentUsage,
      limit: limit,
      remaining: remaining > 0 ? remaining : 0,
      message: isAllowed
          ? '$remaining ${_getLimitTypeName(limitType)} remaining $periodLabel'
          : _getLimitReachedMessage(limitType, limit, currentTier),
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
      final doc = await docRef.get();
      if (doc.exists) {
        final fieldName = _getFieldName(limitType);
        final usage = (doc.data()?[fieldName] as num?)?.toInt() ?? 0;

        // Update local cache
        await _setLocalCache(userId, limitType, usage);

        return usage;
      }
    } catch (e) {
      // On error, return cached value or 0
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
        return rules.hourlyLikeLimit;
      case UsageLimitType.nopes:
        return rules.hourlyNopeLimit;
      case UsageLimitType.superLikes:
        return rules.hourlySuperLikeLimit;
      case UsageLimitType.dailySuperLikes:
        return rules.dailySuperLikeLimit;
      case UsageLimitType.swipes:
        return rules.dailySwipeLimit;
      case UsageLimitType.messages:
        return rules.dailyMessageLimit;
      case UsageLimitType.mediaSends:
        return rules.dailyMediaSendLimit;
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
    }
  }

  /// Get human-readable name for limit type
  String _getLimitTypeName(UsageLimitType limitType) {
    switch (limitType) {
      case UsageLimitType.likes:
        return 'likes';
      case UsageLimitType.nopes:
        return 'nopes';
      case UsageLimitType.superLikes:
        return 'super likes';
      case UsageLimitType.dailySuperLikes:
        return 'daily super likes';
      case UsageLimitType.swipes:
        return 'swipes';
      case UsageLimitType.messages:
        return 'messages';
      case UsageLimitType.mediaSends:
        return 'media sends';
    }
  }

  // ─── Limit-reached messages ──────────────────────────────────

  /// Get message when limit is reached
  String _getLimitReachedMessage(
    UsageLimitType limitType,
    int limit,
    MembershipTier currentTier,
  ) {
    switch (limitType) {
      case UsageLimitType.likes:
        return "You've used all $limit likes this hour. Upgrade for more or wait until next hour.";
      case UsageLimitType.nopes:
        return "You've used all $limit nopes this hour. Upgrade for more or wait until next hour.";
      case UsageLimitType.superLikes:
        if (limit == 0) {
          return 'Super Likes are not available on the ${currentTier.displayName} plan. Upgrade to unlock this feature!';
        }
        return "You've used all $limit super likes this hour. Upgrade for more or wait until next hour.";
      case UsageLimitType.dailySuperLikes:
        return "You've used your $limit free super like${limit == 1 ? '' : 's'} for today. Use coins for more or wait until tomorrow.";
      case UsageLimitType.swipes:
        return "You've used all $limit swipes for today. Upgrade to get more swipes or wait until tomorrow.";
      case UsageLimitType.messages:
        return "You've reached your daily limit of $limit messages. Upgrade to send unlimited messages!";
      case UsageLimitType.mediaSends:
        if (limit == 0) {
          return 'Sending media is not available on the ${currentTier.displayName} plan. Upgrade to send images and videos!';
        }
        return "You've reached your daily limit of $limit media sends. Upgrade for more or wait until tomorrow.";
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
      int currentValue = 0;

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
