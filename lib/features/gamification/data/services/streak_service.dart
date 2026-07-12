import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../coins/data/datasources/coin_remote_datasource.dart';
import '../../../coins/domain/entities/coin_transaction.dart';

/// Immutable snapshot of a user's engagement streak after a [StreakService.touch].
///
/// [coinsAwarded] / [milestoneReached] are non-zero/non-null only on the single
/// [touch] that first crosses a milestone, so callers can surface a reward toast.
@immutable
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.longest,
    required this.lastActiveDay,
    this.coinsAwarded = 0,
    this.milestoneReached,
  });

  /// Current consecutive-day streak (1 on the first active day).
  final int current;

  /// All-time best streak.
  final int longest;

  /// `YYYY-MM-DD` (device-local) of the most recent active day.
  final String lastActiveDay;

  /// Coins granted by the [touch] that produced this info (0 if none).
  final int coinsAwarded;

  /// The milestone day count (3/7/30) crossed by this [touch], else null.
  final int? milestoneReached;

  const StreakInfo.empty()
      : current = 0,
        longest = 0,
        lastActiveDay = '',
        coinsAwarded = 0,
        milestoneReached = null;
}

/// Daily engagement streak — a single bounded doc per user.
///
/// Doc shape: `streaks/{userId} = {`
///   `current, longest, lastActiveDay (YYYY-MM-DD), awardedMilestones: [int],`
///   `updatedAt }`.
///
/// Design (see project memory — "design for millions / perf-first"): every
/// [touch] is exactly one read + at most one write on a single document, so it
/// stays O(1) regardless of how many users or how active they are. Coins are
/// granted at milestone streaks (3/7/30) through the existing coin-credit path
/// ([CoinRemoteDataSource.updateBalance]) and are idempotent via the
/// `awardedMilestones` list stored on the doc.
class StreakService {
  StreakService({
    required CoinRemoteDataSource coinDataSource,
    FirebaseFirestore? firestore,
  })  : _coinDataSource = coinDataSource,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final CoinRemoteDataSource _coinDataSource;

  static const String _collection = 'streaks';

  /// Coins granted the first time each milestone streak is reached.
  static const Map<int, int> milestoneRewards = <int, int>{
    3: 50,
    7: 150,
    30: 500,
  };

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_collection).doc(userId);

  /// Formats a [DateTime] as a device-local `YYYY-MM-DD` day key.
  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Records activity for [userId] "today" and advances / resets the streak.
  ///
  ///  * already active today → no-op (returns the stored streak),
  ///  * active yesterday     → `current++` (and `longest` grows to match),
  ///  * otherwise            → streak resets to 1.
  ///
  /// When the new `current` first reaches a milestone (3/7/30) the matching
  /// coin reward is credited once. Never throws — on any failure it returns a
  /// best-effort [StreakInfo] so callers can treat it as fire-and-forget.
  Future<StreakInfo> touch(String userId) async {
    if (userId.isEmpty) return const StreakInfo.empty();

    try {
      final now = DateTime.now();
      final today = _dayKey(now);
      final yesterday = _dayKey(now.subtract(const Duration(days: 1)));

      final snap = await _doc(userId).get();
      final data = snap.data();

      final storedCurrent = (data?['current'] as num?)?.toInt() ?? 0;
      final storedLongest = (data?['longest'] as num?)?.toInt() ?? 0;
      final lastActiveDay = data?['lastActiveDay'] as String? ?? '';
      final awarded = <int>{
        ...?(data?['awardedMilestones'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt()),
      };

      // Already counted today — nothing to do.
      if (lastActiveDay == today) {
        return StreakInfo(
          current: storedCurrent == 0 ? 1 : storedCurrent,
          longest: storedLongest,
          lastActiveDay: today,
        );
      }

      final int newCurrent;
      if (lastActiveDay == yesterday) {
        newCurrent = storedCurrent + 1;
      } else {
        newCurrent = 1;
        awarded.clear(); // Streak broke — milestones are earnable again.
      }
      final newLongest = newCurrent > storedLongest ? newCurrent : storedLongest;

      // Determine any newly-crossed milestone (grant once per streak run).
      int coinsAwarded = 0;
      int? milestoneReached;
      for (final entry in milestoneRewards.entries) {
        if (newCurrent >= entry.key && !awarded.contains(entry.key)) {
          awarded.add(entry.key);
          coinsAwarded += entry.value;
          milestoneReached = entry.key;
        }
      }

      await _doc(userId).set(<String, dynamic>{
        'current': newCurrent,
        'longest': newLongest,
        'lastActiveDay': today,
        'awardedMilestones': awarded.toList()..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (coinsAwarded > 0) {
        try {
          await _coinDataSource.updateBalance(
            userId: userId,
            amount: coinsAwarded,
            type: CoinTransactionType.credit,
            reason: CoinTransactionReason.dailyLoginStreakReward,
            metadata: <String, dynamic>{
              'streakDay': milestoneReached,
              'source': 'streak_milestone',
            },
          );
        } catch (e) {
          debugPrint('StreakService.touch reward credit failed: $e');
        }
      }

      return StreakInfo(
        current: newCurrent,
        longest: newLongest,
        lastActiveDay: today,
        coinsAwarded: coinsAwarded,
        milestoneReached: milestoneReached,
      );
    } catch (e) {
      debugPrint('StreakService.touch failed: $e');
      return const StreakInfo.empty();
    }
  }

  /// Reads the current streak without mutating it (for display).
  Future<StreakInfo> read(String userId) async {
    if (userId.isEmpty) return const StreakInfo.empty();
    try {
      final snap = await _doc(userId).get();
      final data = snap.data();
      if (data == null) return const StreakInfo.empty();
      return StreakInfo(
        current: (data['current'] as num?)?.toInt() ?? 0,
        longest: (data['longest'] as num?)?.toInt() ?? 0,
        lastActiveDay: data['lastActiveDay'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('StreakService.read failed: $e');
      return const StreakInfo.empty();
    }
  }
}
