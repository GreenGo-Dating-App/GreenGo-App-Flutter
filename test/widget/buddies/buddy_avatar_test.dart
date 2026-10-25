import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_avatar_option.dart';
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

  testWidgets('small sizes load the thumbnail, big ones the full picture; retired pictures still show',
      (tester) async {
    repo.avatars = const [
      BuddyAvatarOption(
          id: 'p1', url: 'https://img.test/p1_512.webp', thumbUrl: 'https://img.test/p1_192.webp', order: 1),
      BuddyAvatarOption(id: 'old', url: 'https://img.test/old.png', order: 2, active: false),
    ];
    await pump(
        tester,
        const Column(children: [
          BuddyAvatar(avatarId: 'p1', size: 40),
          BuddyAvatar(avatarId: 'p1', size: 300),
          BuddyAvatar(avatarId: 'old', size: 40),
        ]));
    final urls = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).map((i) => i.imageUrl);
    expect(urls, ['https://img.test/p1_192.webp', 'https://img.test/p1_512.webp', 'https://img.test/old.png']);
    expect(find.byKey(drawn), findsNothing);
  });

  test('the picker offers only active pictures; thumbUrl and active are parsed', () {
    final o = BuddyAvatarOption.fromMap('p1', {
      'url': 'https://img.test/a.webp',
      'thumbUrl': 'https://img.test/t.webp',
      'active': false,
    })!;
    expect(o.thumbUrl, 'https://img.test/t.webp');
    expect(o.active, isFalse);
    expect(BuddyAvatarOption.fromMap('p2', {'url': 'https://img.test/a.webp', 'thumbUrl': 'http://x'})!.thumbUrl,
        isNull);
    final c = BuddyAvatarCatalog(all: [o, ...kFakeAvatars], loading: false, failed: false, retry: () {});
    expect(c.options.map((x) => x.id), ['av_fox', 'av_owl', 'av_cat']);
    expect(c.byId('p1'), o);
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
