import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';
import 'package:greengo_chat/features/discovery/presentation/screens/profile_detail_screen.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/profile_fixtures.dart';
import 'follow_test_support.dart';

/// Someone else's profile (owner decision 2026-10-19): "N followers ·
/// M following" under the city, each part tappable -> that profile's lists.
void main() {
  late FollowWorld w;

  setUp(() {
    w = FollowWorld();
    // audioplayers (voice intro player) has no platform side in tests.
    for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(ch), (_) async => null);
    }
  });
  tearDown(() => w.dispose());

  Widget app(String viewer) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ProfileDetailScreen(
          profile: buildProfile(userId: 't', photoUrls: const []),
          currentUserId: viewer,
        ),
      );

  testWidgets("others' profile: tappable followers · following line", (tester) async {
    await w.fs
        .collection(FollowService.publicCountsCollection)
        .doc('t')
        .set({'followersCount': 12, 'followingCount': 3});
    await w.follow('t', 'x1', followeeName: 'bia');
    w.briefs({'x1': const UserBrief(name: 'Bia')});

    await tester.pumpWidget(app('me'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('public_follow_stats_line')), findsOneWidget);
    expect(find.text('12 followers'), findsOneWidget);
    expect(find.text('3 following'), findsOneWidget);

    final following = find.byKey(const Key('public_line_following'));
    await tester.ensureVisible(following);
    await tester.tap(following);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final screen = tester.widget<FollowListScreen>(find.byType(FollowListScreen));
    expect(screen.userId, 't');
    expect(screen.currentUserId, 'me');
    expect(screen.initialTab, 1);
    expect(find.text('Bia'), findsOneWidget);
  });
}
