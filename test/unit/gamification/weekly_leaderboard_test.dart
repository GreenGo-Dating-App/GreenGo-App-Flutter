// Weekly leaderboard: ranked by user_levels.weeklyXP for the current ISO
// week; falls back to the legacy xp_transactions aggregation when nobody has
// weekly fields yet. XP grants maintain weekKey/weeklyXP.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/gamification/data/datasources/gamification_remote_datasource.dart';
import 'package:greengo_chat/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:greengo_chat/features/gamification/domain/utils/week_key.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

Future<void> _user(
  FakeFirebaseFirestore fs,
  String uid, {
  required int totalXP,
  String? weekKey,
  int? weeklyXP,
  String region = 'IT',
  bool isAdmin = false,
}) async {
  await fs.collection('profiles').doc(uid).set({
    'accountStatus': 'active',
    'isAdmin': isAdmin,
    'lastSeen': Timestamp.now(),
  });
  await fs.collection('user_levels').doc(uid).set({
    'userId': uid,
    'displayName': uid,
    'level': 1,
    'currentXP': 0,
    'totalXP': totalXP,
    'region': region,
    'isVIP': false,
    if (weekKey != null) 'weekKey': weekKey,
    if (weeklyXP != null) 'weeklyXP': weeklyXP,
  });
}

void main() {
  late FakeFirebaseFirestore fs;
  late GamificationRemoteDataSourceImpl ds;
  final thisWeek = currentIsoWeekKey();

  setUp(() {
    fs = FakeFirebaseFirestore();
    ds = GamificationRemoteDataSourceImpl(
        firestore: fs, functions: _MockFunctions());
  });

  test('ranks by weeklyXP of the current week, not all-time XP', () async {
    await _user(fs, 'veteran', totalXP: 99999, weekKey: thisWeek, weeklyXP: 10);
    await _user(fs, 'rookie', totalXP: 50, weekKey: thisWeek, weeklyXP: 40);
    await _user(fs, 'stale', totalXP: 5000, weekKey: '2000-W01', weeklyXP: 900);
    await _user(fs, 'admin', totalXP: 1, weekKey: thisWeek, weeklyXP: 1000,
        isAdmin: true);

    final board = await ds.getLeaderboard(
        type: LeaderboardType.global, limit: 50, timePeriod: 'week');

    expect(board.map((e) => e.userId), ['rookie', 'veteran']);
    expect(board.map((e) => e.totalXP), [40, 10]); // weekly XP shown
    expect(board.map((e) => e.rank), [1, 2]);
  });

  test('regional weekly board filters by region', () async {
    await _user(fs, 'it', totalXP: 1, weekKey: thisWeek, weeklyXP: 5);
    await _user(fs, 'br', totalXP: 1, weekKey: thisWeek, weeklyXP: 50,
        region: 'BR');

    final board = await ds.getLeaderboard(
        type: LeaderboardType.regional,
        region: 'IT',
        limit: 50,
        timePeriod: 'week');
    expect(board.map((e) => e.userId), ['it']);
  });

  test('falls back to the legacy board when nobody has weekly fields',
      () async {
    await _user(fs, 'a', totalXP: 100);
    await _user(fs, 'b', totalXP: 300);

    final board = await ds.getLeaderboard(
        type: LeaderboardType.global, limit: 50, timePeriod: 'week');
    // No xp_transactions either -> all-time board, as before.
    expect(board.map((e) => e.userId), ['b', 'a']);
  });

  test('grantXP maintains weekKey/weeklyXP', () async {
    await _user(fs, 'u', totalXP: 0, weekKey: '2000-W01', weeklyXP: 999);

    await ds.grantXP('u', 25, 'test');
    var data = (await fs.collection('user_levels').doc('u').get()).data()!;
    expect(data['weekKey'], thisWeek);
    expect(data['weeklyXP'], 25); // stale week reset
    expect(data['totalXP'], 25);

    await ds.grantXP('u', 10, 'test');
    data = (await fs.collection('user_levels').doc('u').get()).data()!;
    expect(data['weeklyXP'], 35); // same week incremented
  });
}
