import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_detail_tab_bar.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// The community detail tab bar (Chat · Tips · Announcements · Events ·
/// Experiences) fills the width and never overflows, even at 320 px with the
/// longest translations (German "Ankündigungen").
class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final TabController _c =
      TabController(length: CommunityDetailTabBar.tabCount, vsync: this);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Lisbon Foodies'),
          bottom: CommunityDetailTabBar(controller: _c),
        ),
        body: TabBarView(controller: _c, children: [
          for (var i = 0; i < CommunityDetailTabBar.tabCount; i++)
            Center(child: Text('tab $i')),
        ]),
      );
}

Future<AppLocalizations> _pump(WidgetTester tester, Locale locale,
    {double width = 320}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const _Host(),
  ));
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(_Host)))!;
}

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('fills 320 px without overflow ($locale)', (tester) async {
      final l = await _pump(tester, locale);
      expect(tester.takeException(), isNull);

      final labels = [
        l.communitiesTabChat,
        l.communitiesTabTips,
        l.communitiesTabAnnouncements,
        l.communitiesTabEvents,
        l.eventsTabExperiences,
      ];
      final tabs = find.byType(Tab);
      expect(tabs, findsNWidgets(5));
      final bar = tester.getRect(find.byType(TabBar));
      // Fills the full width, equal shares.
      expect(bar.width, 320);
      for (var i = 0; i < 5; i++) {
        final r = tester.getRect(tabs.at(i));
        // Equal share minus the 4 px label padding on each side.
        expect(r.width, closeTo(320 / 5 - 8, 0.5));
        expect(r.left >= bar.left - 0.5 && r.right <= bar.right + 0.5, isTrue);
        // The label is on one line and fully inside its tab (scaled down).
        final text = find.descendant(
            of: tabs.at(i), matching: find.text(labels[i]));
        expect(text, findsOneWidget);
        final tr = tester.getRect(text);
        expect(tr.left >= r.left - 0.5 && tr.right <= r.right + 0.5, isTrue,
            reason: '"${labels[i]}" overflows its tab');
      }
    });
  }

  testWidgets('switching to Experiences works (en, 320 px)', (tester) async {
    final l = await _pump(tester, const Locale('en'));
    await tester.tap(find.text(l.eventsTabExperiences));
    await tester.pumpAndSettle();
    expect(find.text('tab ${CommunityDetailTabBar.experiencesIndex}'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
