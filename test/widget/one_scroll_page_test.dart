import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/one_scroll_page.dart';

/// The Shop (Coins / Membership tabs) and the Membership screen scroll as
/// ONE scroll view (owner 2026-10-24): the app bar, the tab bar and the
/// header scroll away with the content; nothing stays fixed at the top.
void main() {
  bool onScreen(WidgetTester tester, Finder f) {
    if (f.evaluate().isEmpty) return false;
    final r = tester.getRect(f);
    return r.bottom > 0 && r.top < tester.view.physicalSize.height / tester.view.devicePixelRatio;
  }

  Future<void> pumpTabs(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TabController(length: 2, vsync: const TestVSync());
    addTearDown(controller.dispose);
    Widget tab(String name) => OneScrollTab(
          header: [
            SizedBox(
              key: ValueKey('header-$name'),
              height: 200,
              child: Text('Balance $name'),
            ),
          ],
          items: [
            for (var i = 0; i < 30; i++)
              SizedBox(key: ValueKey('item-$name-$i'), height: 80, child: Text('Item $i')),
          ],
          bottomBar: SizedBox(
              key: ValueKey('bottom-$name'), height: 56, child: const Text('Purchase')),
        );
    await tester.pumpWidget(MaterialApp(
      home: OneScrollTabsScaffold(
        title: const Text('Shop', key: ValueKey('title')),
        tabBar: TabBar(
          key: const ValueKey('tabs'),
          controller: controller,
          tabs: const [Tab(text: 'Coins'), Tab(text: 'Membership')],
        ),
        controller: controller,
        tabs: [tab('coins'), tab('membership')],
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Shop tabs: app bar, tab bar and header scroll away with the content',
      (tester) async {
    await pumpTabs(tester);
    expect(onScreen(tester, find.byKey(const ValueKey('title'))), isTrue);
    expect(onScreen(tester, find.byKey(const ValueKey('tabs'))), isTrue);
    expect(onScreen(tester, find.byKey(const ValueKey('header-coins'))), isTrue);

    await tester.drag(find.byKey(const ValueKey('item-coins-2')), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(onScreen(tester, find.byKey(const ValueKey('title'))), isFalse);
    expect(onScreen(tester, find.byKey(const ValueKey('tabs'))), isFalse);
    expect(onScreen(tester, find.byKey(const ValueKey('header-coins'))), isFalse);
    // The purchase bar under the list stays reachable.
    expect(onScreen(tester, find.byKey(const ValueKey('bottom-coins'))), isTrue);

    // Scrolling back down brings everything back.
    await tester.drag(find.byType(TabBarView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(onScreen(tester, find.byKey(const ValueKey('title'))), isTrue);
    expect(onScreen(tester, find.byKey(const ValueKey('header-coins'))), isTrue);
  }, variant: const TargetPlatformVariant(
      {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.windows, TargetPlatform.macOS}));

  testWidgets('Membership page: app bar and header scroll away', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: OneScrollPage(
        title: const Text('Buy membership', key: ValueKey('title')),
        padding: const EdgeInsets.all(20),
        overlay: const IgnorePointer(child: SizedBox.shrink(key: ValueKey('overlay'))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(key: ValueKey('header'), height: 150, child: Text('Extend')),
            for (var i = 0; i < 20; i++)
              SizedBox(key: ValueKey('plan-$i'), height: 90, child: Text('Plan $i')),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(onScreen(tester, find.byKey(const ValueKey('title'))), isTrue);
    expect(onScreen(tester, find.byKey(const ValueKey('header'))), isTrue);
    expect(find.byKey(const ValueKey('overlay')), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('plan-1')), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(onScreen(tester, find.byKey(const ValueKey('title'))), isFalse);
    expect(onScreen(tester, find.byKey(const ValueKey('header'))), isFalse);
  });
}
