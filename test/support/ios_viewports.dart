import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every iOS form factor the app ships to, so layout regressions are caught
/// here rather than by an App Store reviewer.
///
/// The deployment target is iOS 15.5 (ios/Podfile, project.pbxproj), which
/// reaches back to the iPhone SE 1st gen at 320x568pt and forward to the
/// 13" iPad at 1024x1366pt — a 4.6x spread in area. Sizes are logical points,
/// which is what MediaQuery reports, so a dp here equals an iOS point.
///
/// Keyboard heights are the realistic on-screen heights for each class of
/// device including the accessory/predictive bar; they are what makes the
/// difference between a reachable submit button and one the user cannot tap.
@immutable
class IosViewport {
  const IosViewport(
    this.name,
    this.size, {
    this.topPad = 0,
    this.bottomPad = 0,
    this.keyboardHeight = 0,
    this.keyboardOpen = false,
  });

  final String name;
  final Size size;

  /// Safe-area inset at the top (status bar / notch / Dynamic Island).
  final double topPad;

  /// Safe-area inset at the bottom (home indicator).
  final double bottomPad;

  /// Height this device's on-screen keyboard occupies when it is shown.
  final double keyboardHeight;

  /// Whether the keyboard is currently up for this case.
  final bool keyboardOpen;

  /// The inset actually applied to the view.
  double get activeKeyboard => keyboardOpen ? keyboardHeight : 0;

  /// The lowest y a widget can occupy and still be tappable: the keyboard is a
  /// native layer above Flutter, so anything under it never receives the touch.
  double get usableBottom => size.height - activeKeyboard;

  IosViewport get keyboardUp => IosViewport(
        '$name + keyboard',
        size,
        topPad: topPad,
        bottomPad: bottomPad,
        keyboardHeight: keyboardHeight,
        keyboardOpen: true,
      );

  @override
  String toString() => name;
}

/// Portrait form factors, smallest first.
const List<IosViewport> kIosPortraitViewports = <IosViewport>[
  // Oldest device still on iOS 15.5 — the tightest layout in the matrix.
  IosViewport('iPhone SE 1st gen', Size(320, 568),
      topPad: 20, keyboardHeight: 216),
  IosViewport('iPhone SE 2nd/3rd gen', Size(375, 667),
      topPad: 20, keyboardHeight: 260),
  IosViewport('iPhone 13 mini', Size(375, 812),
      topPad: 50, bottomPad: 34, keyboardHeight: 291),
  IosViewport('iPhone 15/16', Size(393, 852),
      topPad: 59, bottomPad: 34, keyboardHeight: 336),
  IosViewport('iPhone 16 Pro Max', Size(440, 956),
      topPad: 62, bottomPad: 34, keyboardHeight: 346),
  IosViewport('iPad mini 6', Size(744, 1133),
      topPad: 24, bottomPad: 20, keyboardHeight: 320),
  IosViewport('iPad Air 11in', Size(820, 1180),
      topPad: 24, bottomPad: 20, keyboardHeight: 350),
  IosViewport('iPad 13in', Size(1024, 1366),
      topPad: 24, bottomPad: 20, keyboardHeight: 400),
];

/// iPad landscape. Info.plist now declares iPad portrait-only, but
/// UIRequiresFullScreen is deprecated on iPadOS 26 and SDK-26 apps are
/// resizable regardless — so landscape stays in the matrix as defence.
/// This is the shape that produced the App Store 2.1 rejection.
const List<IosViewport> kIosLandscapeViewports = <IosViewport>[
  IosViewport('iPad mini 6 landscape', Size(1133, 744),
      topPad: 24, bottomPad: 20, keyboardHeight: 340),
  IosViewport('iPad Air 11in landscape', Size(1180, 820),
      topPad: 24, bottomPad: 20, keyboardHeight: 380),
  IosViewport('iPad 13in landscape', Size(1366, 1024),
      topPad: 24, bottomPad: 20, keyboardHeight: 420),
];

List<IosViewport> get kAllIosViewports =>
    <IosViewport>[...kIosPortraitViewports, ...kIosLandscapeViewports];

/// Pumps [child] with [viewport]'s metrics applied to the test view, so
/// MediaQuery reports exactly what the real device would.
Future<void> pumpAtViewport(
  WidgetTester tester,
  Widget child,
  IosViewport viewport, {
  Duration settle = const Duration(seconds: 2),
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = viewport.size * 2.0;
  tester.view.viewInsets =
      FakeViewPadding(bottom: viewport.activeKeyboard * 2.0);
  tester.view.padding = FakeViewPadding(
    top: viewport.topPad * 2.0,
    bottom: viewport.bottomPad * 2.0,
  );
  tester.view.viewPadding = FakeViewPadding(
    top: viewport.topPad * 2.0,
    bottom: viewport.bottomPad * 2.0,
  );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(child);
  // Several screens run endless animations (particles, shimmer), so
  // pumpAndSettle would spin forever. Pump past the entry animation instead.
  await tester.pump(settle);
}

/// Largest scroll offset available on the screen's outermost scroll view.
/// Zero means the content fits — and therefore that the user has no visual cue
/// that anything lies further down.
double maxScrollExtentOf(WidgetTester tester) {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return 0;
  return tester
      .state<ScrollableState>(scrollables.first)
      .position
      .maxScrollExtent;
}

/// Fully usable: on screen, clear of the keyboard, and actually hit-testable.
/// Checking only the bottom edge is not enough — scrolling can push a widget
/// off the TOP of the viewport, which satisfies "above the keyboard" while
/// being just as untappable.
bool _isUsable(
  WidgetTester tester,
  Finder action,
  IosViewport viewport,
) {
  if (action.evaluate().isEmpty) return false;
  final rect = tester.getRect(action.first);
  if (rect.bottom > viewport.usableBottom) return false;
  if (rect.top < 0) return false;
  return action.hitTestable().evaluate().isNotEmpty;
}

/// Asserts the primary call-to-action is visible above the keyboard right now,
/// without the user having to scroll.
///
/// This is the invariant the App Store 2.1 rejection violated. It only applies
/// where the user has no reason to scroll — see [expectPrimaryActionReachable]
/// for the weaker rule that fits long forms.
void expectPrimaryActionUsable(
  WidgetTester tester,
  Finder action,
  IosViewport viewport, {
  String context = '',
}) {
  expect(action, findsOneWidget,
      reason: 'primary action missing on ${viewport.name}');

  final rect = tester.getRect(action.first);
  expect(
    rect.bottom,
    lessThanOrEqualTo(viewport.usableBottom),
    reason: 'primary action $rect is under the keyboard on ${viewport.name} '
        '$context (usable to ${viewport.usableBottom}). The page does not '
        'scroll at rest, so nothing tells the user the button moved.',
  );
  expect(
    action.hitTestable(),
    findsOneWidget,
    reason: 'primary action is not hit-testable on ${viewport.name} $context',
  );
}

/// Asserts the primary call-to-action can be reached, scrolling if necessary.
///
/// The weaker rule, correct for forms that are already scrollable — a long
/// registration form legitimately puts its submit button below the fold.
Future<void> expectPrimaryActionReachable(
  WidgetTester tester,
  Finder action,
  IosViewport viewport, {
  String context = '',
}) async {
  expect(action, findsOneWidget,
      reason: 'primary action missing on ${viewport.name}');

  if (_isUsable(tester, action, viewport)) {
    expect(action.hitTestable(), findsOneWidget,
        reason: 'primary action not hit-testable on ${viewport.name} $context');
    return;
  }

  final scrollables = find.byType(Scrollable);
  expect(
    scrollables,
    findsWidgets,
    reason: 'primary action is off-screen on ${viewport.name} $context and '
        'there is no scroll view to reach it with',
  );

  for (var attempt = 0; attempt < 15; attempt++) {
    await tester.drag(scrollables.first, const Offset(0, -180));
    await tester.pump();
    if (_isUsable(tester, action, viewport)) break;
  }

  expect(
    _isUsable(tester, action, viewport),
    isTrue,
    reason: 'primary action ${tester.getRect(action.first)} is still '
        'unreachable on ${viewport.name} $context after scrolling '
        '(must sit within 0..${viewport.usableBottom} and be hit-testable)',
  );
}

/// Raises the keyboard on an already-pumped screen.
Future<void> raiseKeyboard(WidgetTester tester, IosViewport viewport) async {
  tester.view.viewInsets =
      FakeViewPadding(bottom: viewport.keyboardHeight * 2.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Fails if the frame produced a layout overflow. Overflows clip content and
/// make the clipped part untappable, so they are defects, not cosmetics.
void expectNoLayoutOverflow(WidgetTester tester, IosViewport viewport,
    {String context = ''}) {
  final error = tester.takeException();
  expect(
    error,
    isNull,
    reason: 'layout error on ${viewport.name} $context: $error',
  );
}
