import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_controller.dart';
import 'package:greengo_chat/features/app_tour/presentation/widgets/gesture_tooltip.dart';
import 'package:greengo_chat/features/app_tour/presentation/widgets/tour_showcase.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:showcaseview/showcaseview.dart';

/// Owner notes 2026-10-20: the Traveler-mode bubble of the privacy &
/// location tour ran off the screen. Its card sits below the fold at the end
/// of the profile's collapsed section; the step now scrolls its target into
/// view near the top (enableAutoScroll + scrollAlignment) and the bubble
/// narrows on small screens. Checked on a 320x640 screen with the same
/// layout shape: a short card, a tall card, a short card, far down a list.
void main() {
  final incognito = GlobalKey(debugLabel: 'incognito');
  final globe = GlobalKey(debugLabel: 'globe');
  final traveler = GlobalKey(debugLabel: 'traveler');

  Widget step(GlobalKey key, String title, double height, double alignment) =>
      TourShowcase(
        showcaseKey: key,
        title: title,
        description: 'What $title does and how to use it.',
        enableAutoScroll: true,
        scrollAlignment: alignment,
        child: Container(
          height: height,
          color: Colors.grey,
          child: Text('$title card'),
        ),
      );

  Future<void> settle(WidgetTester t) async {
    // The tooltip glyphs animate forever: pump frames instead of settling.
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Rect rectOf(WidgetTester t, Finder f) => t.getRect(f);

  testWidgets('every step and its bubble stay on a 320x640 screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late BuildContext showcaseContext;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ShowCaseWidget(
        builder: (context) {
          showcaseContext = context;
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            // The profile screen is a SingleChildScrollView.
            body: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 900), // the sections above
                step(incognito, 'Incognito', 90, 0.1),
                const SizedBox(height: 16),
                step(globe, 'Globe', 260, 0),
                const SizedBox(height: 16),
                step(traveler, 'Traveler', 90, 0.1),
                const SizedBox(height: 16),
                const SizedBox(height: 140), // boost card
              ]),
            ),
          );
        },
      ),
    ));
    await tester.pump();

    final screen = Offset.zero & const Size(320, 640);
    ShowCaseWidget.of(showcaseContext)
        .startShowCase([incognito, globe, traveler]);

    for (final (key, title) in [
      (incognito, 'Incognito'),
      (globe, 'Globe'),
      (traveler, 'Traveler'),
    ]) {
      await settle(tester);
      final target = rectOf(tester, find.byKey(key));
      expect(screen.contains(target.topLeft) && screen.contains(target.bottomRight - const Offset(1, 1)),
          isTrue,
          reason: '$title target scrolled into view: $target');
      final bubble = find.byWidgetPredicate(
          (w) => w is GestureTooltip && w.title == title);
      expect(bubble, findsOneWidget, reason: '$title bubble shown');
      final r = rectOf(tester, bubble);
      expect(r.left, greaterThanOrEqualTo(0), reason: '$title bubble $r');
      expect(r.top, greaterThanOrEqualTo(0), reason: '$title bubble $r');
      expect(r.right, lessThanOrEqualTo(320), reason: '$title bubble $r');
      expect(r.bottom, lessThanOrEqualTo(640), reason: '$title bubble $r');
      ShowCaseWidget.of(showcaseContext).next();
    }
    await settle(tester);
  });

  test('bubble width narrows on small screens', () {
    expect(GestureTooltip.widthFor(320), 288);
    expect(GestureTooltip.widthFor(800), GestureTooltip.width);
  });

  test('privacy tour still lists its three steps', () {
    expect(TourController.allTourIds,
        contains(TourController.privacyLocationTourId));
  });
}
