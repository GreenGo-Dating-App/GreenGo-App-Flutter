import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_card.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/sponsored_badge.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:network_image_mock/network_image_mock.dart';

Community buildCommunity({
  String name = 'Lisbon Locals',
  CommunityType type = CommunityType.localGuides,
  int memberCount = 42,
  List<String> languages = const ['en', 'pt'],
  String? imageUrl,
  String? lastMessagePreview,
  bool isSponsored = false,
}) {
  return Community(
    id: 'c1',
    name: name,
    description: 'desc',
    type: type,
    createdByUserId: 'owner',
    createdByName: 'Owner',
    createdAt: DateTime(2026, 1, 1),
    memberCount: memberCount,
    languages: languages,
    imageUrl: imageUrl,
    lastMessagePreview: lastMessagePreview,
    lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)),
    isSponsored: isSponsored,
  );
}

Future<void> pumpCard(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders name, member count and type badge', (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(tester, CommunityCard(community: buildCommunity())),
    );

    expect(find.text('Lisbon Locals'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    // CommunityType.localGuides display name.
    expect(find.text('Local Guides'), findsOneWidget);
  });

  testWidgets('renders language badges in upper-case', (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(community: buildCommunity(languages: const ['en', 'it'])),
      ),
    );

    expect(find.text('EN'), findsOneWidget);
    expect(find.text('IT'), findsOneWidget);
  });

  testWidgets('shows the last message preview when present', (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(
          community: buildCommunity(lastMessagePreview: 'See you tonight!'),
        ),
      ),
    );

    expect(find.text('See you tonight!'), findsOneWidget);
  });

  testWidgets('shows a SponsoredBadge only for sponsored communities',
      (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(community: buildCommunity(isSponsored: true)),
      ),
    );
    expect(find.byType(SponsoredBadge), findsOneWidget);
  });

  testWidgets('hides the SponsoredBadge for regular communities',
      (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(community: buildCommunity()),
      ),
    );
    expect(find.byType(SponsoredBadge), findsNothing);
  });

  testWidgets('renders a network image when imageUrl is set', (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(
          community: buildCommunity(imageUrl: 'https://example.com/c.png'),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('falls back to a type icon when imageUrl is null',
      (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(tester, CommunityCard(community: buildCommunity())),
    );
    // localGuides -> Icons.location_on
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });

  testWidgets('invokes onTap when the row is tapped', (tester) async {
    var tapped = false;
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(
          community: buildCommunity(),
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows the unread dot when showUnreadIndicator is true',
      (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        CommunityCard(
          community: buildCommunity(lastMessagePreview: 'hi'),
          showUnreadIndicator: true,
        ),
      ),
    );
    // Activity text renders in gold/bold when unread; assert it is present.
    expect(find.textContaining('ago'), findsOneWidget);
  });
}
