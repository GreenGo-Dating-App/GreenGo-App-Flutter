import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/presentation/widgets/buddy_avatar.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/buddies_fakes.dart';

void main() {
  late FakeBuddiesRepository repo;

  setUp(() => repo = FakeBuddiesRepository());
  tearDown(() => repo.dispose());

  Future<void> pump(WidgetTester tester, Widget child, {bool scope = true}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: scope ? BuddyAvatarScope(repository: repo, child: child) : child,
      ),
    ));
    await tester.pump();
  }

  const drawn = ValueKey('buddy-avatar-drawn');

  testWidgets('a buddy_avatars id renders its picture (cached network image)', (tester) async {
    await pump(tester, const BuddyAvatar(avatarId: 'av_owl', size: 40));
    final img = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(img.imageUrl, 'https://img.test/owl.png');
    expect(find.byKey(drawn), findsNothing);
    expect(find.bySemanticsLabel('Owl'), findsOneWidget);
  });

  testWidgets('legacy buddy_XX and unknown ids fall back to the drawn avatar', (tester) async {
    await pump(
        tester,
        const Row(children: [
          BuddyAvatar(avatarId: 'buddy_07'),
          BuddyAvatar(avatarId: 'av_removed'),
        ]));
    expect(find.byKey(drawn), findsNWidgets(2));
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('drawn avatar while the pictures load / outside a scope / when loading fails',
      (tester) async {
    await pump(tester, const BuddyAvatar(avatarId: 'av_owl'), scope: false);
    expect(find.byKey(drawn), findsOneWidget);

    repo.avatarsError = StateError('offline');
    await pump(tester, const BuddyAvatar(avatarId: 'av_owl'));
    expect(find.byKey(drawn), findsOneWidget);
  });

  testWidgets('picture placeholder while loading', (tester) async {
    await pump(tester, const BuddyAvatarImage(url: 'https://img.test/fox.png', size: 40),
        scope: false);
    expect(
        find.byWidgetPredicate((w) =>
            w.key == const ValueKey('buddy-avatar-placeholder') ||
            w.key == const ValueKey('buddy-avatar-error')),
        findsOneWidget);
  });

  testWidgets('grid: pictures with a gold ring on the selected one; tap selects', (tester) async {
    String? picked;
    await pump(tester, BuddyAvatarGrid(selected: 'av_owl', onSelected: (id) => picked = id));
    for (final o in kFakeAvatars) {
      expect(find.byKey(ValueKey('buddy-avatar-${o.id}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('buddy-avatar-av_cat')));
    expect(picked, 'av_cat');
  });
}
