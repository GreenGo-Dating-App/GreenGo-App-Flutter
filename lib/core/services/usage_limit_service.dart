import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/membership/domain/entities/membership.dart';

/// Types of usage limits that can be tracked
enum UsageLimitType {
  swipes,
  superLikes,
  messages,
  boosts,
  mediaSends,
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

/// Service to track and enforce usage limits based on membership tier
class UsageLimitService {
  final FirebaseFirestore _firestore;

  UsageLimitService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the daily usage collection key based on today's date
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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

    return UsageLimitResult(
      isAllowed: isAllowed,
      currentUsage: currentUsage,
      limit: limit,
      remaining: remaining > 0 ? remaining : 0,
      message: isAllowed
          ? '$remaining ${_getLimitTypeName(limitType)} remaining today'
          : _getLimitReachedMessage(limitType, limit, currentTier),
      currentTier: currentTier,
      suggestedTier: isAllowed ? null : _getSuggestedTier(limitType, currentTier),
    );
  }

  /// Record a usage action
  Future<void> recordUsage({
    required String userId,
    required UsageLimitType limitType,
    int count = 1,
  }) async {
    final todayKey = _getTodayKey();
    final docRef = _firestore
        .collection('dailyUsage')
        .doc(userId)
        .collection('days')
        .doc(todayKey);

    final fieldName = _getFieldName(limitType);

    await docRef.set({
      fieldName: FieldValue.increment(count),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also update local cache for faster checks
    await _updateLocalCache(userId, limitType, count);
  }

  /// Get current usage count for a limit type
  Future<int> _getCurrentUsage(String userId, UsageLimitType limitType) async {
    // Try local cache first for faster response
    final cachedUsage = await _getLocalCache(userId, limitType);
    if (cachedUsage != null) {
      return cachedUsage;
    }

    final todayKey = _getTodayKey();
    final docRef = _firestore
        .collection('dailyUsage')
        .doc(userId)
        .collection('days')
        .doc(todayKey);

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

  /// Get limit value based on type and rules
  int _getLimit(UsageLimitType limitType, MembershipRules rules) {
    switch (limitType) {
      case UsageLimitType.swipes:
        return rules.dailySwipeLimit;
      case UsageLimitType.superLikes:
        return rules.dailySuperLikeLimit;
      case UsageLimitType.messages:
        return rules.dailyMessageLimit;
      case UsageLimitType.boosts:
        return rules.monthlyFreeBoosts;
      case UsageLimitType.mediaSends:
        return rules.dailyMediaSendLimit;
    }
  }

  /// Get field name for Firestore
  String _getFieldName(UsageLimitType limitType) {
    switch (limitType) {
      case UsageLimitType.swipes:
        return 'swipeCount';
      case UsageLimitType.superLikes:
        return 'superLikeCount';
      case UsageLimitType.messages:
        return 'messageCount';
      case UsageLimitType.boosts:
        return 'boostCount';
      case UsageLimitType.mediaSends:
        return 'mediaSendCount';
    }
  }

  /// Get human-readable name for limit type
  String _getLimitTypeName(UsageLimitType limitType) {
    switch (limitType) {
      case UsageLimitType.swipes:
        return 'swipes';
      case UsageLimitType.superLikes:
        return 'super likes';
      case UsageLimitType.messages:
        return 'messages';
      case UsageLimitType.boosts:
        return 'boosts';
      case UsageLimitType.mediaSends:
        return 'media sends';
    }
  }

  /// Get message when limit is reached
  String _getLimitReachedMessage(
    UsageLimitType limitType,
    int limit,
    MembershipTier currentTier,
  ) {
    final limitName = _getLimitTypeName(limitType);

    switch (limitType) {
      case UsageLimitType.swipes:
        return "You've used all $limit swipes for today. Upgrade to get more swipes or wait until tomorrow.";
      case UsageLimitType.superLikes:
        if (limit == 0) {
          return 'Super Likes are not available on the ${currentTier.displayName} plan. Upgrade to unlock this feature!';
        }
        return "You've used all $limit super likes for today. Upgrade for more or wait until tomorrow.";
      case UsageLimitType.messages:
        return "You've reached your daily limit of $limit messages. Upgrade to send unlimited messages!";
      case UsageLimitType.boosts:
        return "You've used all $limit profile boosts this month. Upgrade for more boosts!";
      case UsageLimitType.mediaSends:
        if (limit == 0) {
          return 'Sending media is not available on the ${currentTier.displayName} plan. Upgrade to send images and videos!';
        }
        return "You've reached your daily limit of $limit media sends. Upgrade for more or wait until tomorrow.";
    }
  }

  /// Get suggested tier to upgrade to for more of this limit
  MembershipTier? _getSuggestedTier(UsageLimitType limitType, MembershipTier currentTier) {
    // Suggest the next tier up that provides more of the requested limit
    switch (currentTier) {
      case MembershipTier.free:
        return MembershipTier.silver;
      case MembershipTier.silver:
        return MembershipTier.gold;
      case MembershipTier.gold:
        if (limitType == UsageLimitType.superLikes) {
          return MembershipTier.platinum;
        }
        return null; // Gold already has unlimited swipes/messages
      case MembershipTier.platinum:
        return null; // Already at max tier
      case MembershipTier.test:
        return null; // Test users have full access
    }
  }

  // Local cache methods for faster limit checking
  Future<int?> _getLocalCache(String userId, UsageLimitType limitType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(userId, limitType);
      final dateKey = '${key}_date';

      final cachedDate = prefs.getString(dateKey);
      final todayKey = _getTodayKey();

      // Only return cached value if it's from today
      if (cachedDate == todayKey) {
        return prefs.getInt(key);
      }

      // Clear old cache
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
      final dateKey = '${key}_date';
      final todayKey = _getTodayKey();

      await prefs.setInt(key, value);
      await prefs.setString(dateKey, todayKey);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> _updateLocalCache(String userId, UsageLimitType limitType, int increment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(userId, limitType);
      final dateKey = '${key}_date';
      final todayKey = _getTodayKey();

      final cachedDate = prefs.getString(dateKey);
      int currentValue = 0;

      if (cachedDate == todayKey) {
        currentValue = prefs.getInt(key) ?? 0;
      }

      await prefs.setInt(key, currentValue + increment);
      await prefs.setString(dateKey, todayKey);
    } catch (e) {
      // Ignore cache errors
    }
  }

  String _getCacheKey(String userId, UsageLimitType limitType) {
    return 'usage_${userId}_${limitType.name}';
  }

  /// Reset daily usage (for testing or admin purposes)
  Future<void> resetDailyUsage(String userId) async {
    final todayKey = _getTodayKey();
    await _firestore
        .collection('dailyUsage')
        .doc(userId)
        .collection('days')
        .doc(todayKey)
        .delete();

    // Clear local cache
    final prefs = await SharedPreferences.getInstance();
    for (final type in UsageLimitType.values) {
      final key = _getCacheKey(userId, type);
      await prefs.remove(key);
      await prefs.remove('${key}_date');
    }
  }

  /// Get all usage stats for a user today
  Future<Map<UsageLimitType, int>> getAllUsageStats(String userId) async {
    final stats = <UsageLimitType, int>{};

    for (final type in UsageLimitType.values) {
      stats[type] = await _getCurrentUsage(userId, type);
    }

    return stats;
  }
}
