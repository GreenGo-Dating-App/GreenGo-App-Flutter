// Achievement unlock popups: only achievements unlocked during this session,
// each at most once, never replayed after a restart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/gamification/data/services/achievement_unlock_watcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 'user-1';

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

Future<void> _writeProgress(
  FakeFirebaseFirestore fs,
  String achievementId, {
  required bool unlocked,
  DateTime? unlockedAt,
  String userId = _uid,
}) {
  return fs
      .collection('achievement_progress')
      .doc('${userId}_$achievementId')
      .set({
    'userId': userId,
    'achievementId': achievementId,
    'progress': 1,
    'requiredCount': 1,
    'isUnlocked': unlocked,
    'unlockedAt': unlockedAt == null ? null : Timestamp.fromDate(unlockedAt),
    'rewardsClaimed': false,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fs;
  late List<String> shown;
  late DateTime now;

  AchievementUnlockWatcher watcher() => AchievementUnlockWatcher(
        firestore: fs,
        userId: _uid,
        onUnlocked: shown.add,
        clock: () => now,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fs = FakeFirebaseFirestore();
    shown = [];
    now = DateTime.now();
  });

  test('ignores achievements already unlocked when the listener starts',
      () async {
    await _writeProgress(fs, 'first_match',
        unlocked: true, unlockedAt: now.subtract(const Duration(days: 3)));
    final w = watcher();
    await w.start();
    await _pump();
    // Unrelated update to the old doc must not replay it.
    await fs
        .collection('achievement_progress')
        .doc('${_uid}_first_match')
        .update({'rewardsClaimed': true});
    await _pump();
    expect(shown, isEmpty);
    await w.dispose();
  });

  test('shows an achievement unlocked during the session exactly once',
      () async {
    await _writeProgress(fs, 'social_butterfly', unlocked: false);
    final w = watcher();
    await w.start();
    await _pump();

    await _writeProgress(fs, 'social_butterfly',
        unlocked: true, unlockedAt: now.add(const Duration(seconds: 5)));
    await _pump();
    expect(shown, ['social_butterfly']);

    // Further writes to the same doc do not re-fire.
    await fs
        .collection('achievement_progress')
        .doc('${_uid}_social_butterfly')
        .update({'rewardsClaimed': true});
    await _pump();
    expect(shown, ['social_butterfly']);
    await w.dispose();
  });

  test('ignores unlocks with unlockedAt before the listener started',
      () async {
    final w = watcher();
    await w.start();
    await _pump();
    // Arrives late (e.g. stale cache, then server), but is old.
    await _writeProgress(fs, 'popular',
        unlocked: true, unlockedAt: now.subtract(const Duration(hours: 1)));
    await _pump();
    expect(shown, isEmpty);
    await w.dispose();
  });

  test('ignores other users and locked docs', () async {
    final w = watcher();
    await w.start();
    await _pump();
    await _writeProgress(fs, 'popular',
        unlocked: true, unlockedAt: now, userId: 'someone-else');
    await _writeProgress(fs, 'video_enthusiast', unlocked: false);
    await _pump();
    expect(shown, isEmpty);
    await w.dispose();
  });

  test('persisted ids are not shown again after a restart', () async {
    final w1 = watcher();
    await w1.start();
    await _pump();
    await _writeProgress(fs, 'daily_streak_7',
        unlocked: true, unlockedAt: now.add(const Duration(seconds: 1)));
    await _pump();
    expect(shown, ['daily_streak_7']);
    await w1.dispose();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(AchievementUnlockWatcher.prefsKey(_uid)),
        contains('daily_streak_7'));

    // "Restart": fresh watcher, the doc is re-written (e.g. reset + re-unlock
    // race) after the first snapshot — still never shown twice.
    await fs
        .collection('achievement_progress')
        .doc('${_uid}_daily_streak_7')
        .delete();
    final w2 = watcher();
    await w2.start();
    await _pump();
    await _writeProgress(fs, 'daily_streak_7',
        unlocked: true, unlockedAt: now.add(const Duration(seconds: 2)));
    await _pump();
    expect(shown, ['daily_streak_7']);
    await w2.dispose();
  });
}
