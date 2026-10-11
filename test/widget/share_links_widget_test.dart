import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/deep_link_service.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_card.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// The share actions hand the OS share sheet the item's OWN link (the one the
/// `sharePreview` function renders as a preview card), with localized text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final shared = <Map<Object?, Object?>>[];

  setUp(() {
    shared.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'share') {
        shared.add(Map<Object?, Object?>.from(call.arguments as Map));
      }
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  Widget button(Future<void> Function(BuildContext) onTap) => Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => onTap(context),
          child: const Text('go'),
        ),
      );

  testWidgets('experience share sends the /x/ link with localized text',
      (tester) async {
    await tester.pumpWidget(app(
        button((c) => shareExperienceLink(c, 'exp_1', title: 'Pasta class')),
        locale: const Locale('it')));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    final l10n = lookupAppLocalizations(const Locale('it'));
    expect(shared.single['text'],
        l10n.uexpShareText('Pasta class', 'https://greengo-chat.web.app/x/exp_1'));
    expect(shared.single['subject'], 'Pasta class');
  });

  testWidgets('attraction share sends the /a/ link', (tester) async {
    await tester.pumpWidget(
        app(button((c) => shareAttractionLink(c, 4242, name: 'Colosseum'))));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(shared.single['text'],
        l10n.shareAttractionMessage('Colosseum', 'https://greengo-chat.web.app/a/4242'));
  });

  Community community({bool isPublic = true}) => Community(
        id: 'c1',
        name: 'Lisbon Language Exchange',
        description: 'Practice languages over coffee',
        type: CommunityType.values.first,
        createdByUserId: 'u1',
        createdByName: 'Ana',
        createdAt: DateTime(2026),
        isPublic: isPublic,
      );

  testWidgets('long-press on a public community card shares its /c/ link',
      (tester) async {
    await tester.pumpWidget(app(CommunityCard(community: community())));
    await tester.longPress(find.byType(CommunityCard));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(shared.single['text'],
        l10n.shareCommunityMessage('Lisbon Language Exchange', 'https://greengo-chat.web.app/c/c1'));
  });

  testWidgets('private community cards do not share', (tester) async {
    await tester.pumpWidget(
        app(CommunityCard(community: community(isPublic: false))));
    await tester.longPress(find.byType(CommunityCard));
    await tester.pumpAndSettle();
    expect(shared, isEmpty);
  });
}
