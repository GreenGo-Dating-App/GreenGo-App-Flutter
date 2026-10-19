import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_tour/presentation/screens/welcome_carousel_screen.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_environment.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: child,
      ),
    );

const _login = Text('LOGIN', key: ValueKey('login'));

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() => TourEnvironment.debugOverride = true);
  tearDown(() => TourEnvironment.debugOverride = null);

  testWidgets('4 slides with dots; Next walks to "Get started"', (t) async {
    var done = 0;
    await t.pumpWidget(_app(WelcomeCarouselScreen(onDone: () => done++)));
    await t.pumpAndSettle();

    expect(WelcomeCarouselScreen.slideCount, 4);
    expect(find.text(l.welcomeSlide1Title), findsOneWidget);
    final dots = find.descendant(
        of: find.byKey(const ValueKey('welcome-dots')),
        matching: find.byType(AnimatedContainer));
    expect(dots, findsNWidgets(4));
    expect(find.bySemanticsLabel(l.welcomeSlideOf(1, 4)), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const ValueKey('welcome-next')));
      await t.pumpAndSettle();
    }
    expect(find.text(l.welcomeSlide4Title), findsOneWidget);
    expect(find.bySemanticsLabel(l.welcomeSlideOf(4, 4)), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
    expect(find.text(l.welcomeGetStarted), findsOneWidget);
    expect(done, 0);
    await t.tap(find.byKey(const ValueKey('welcome-get-started')));
    await t.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('Skip finishes right away', (t) async {
    var done = 0;
    await t.pumpWidget(_app(WelcomeCarouselScreen(onDone: () => done++)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('welcome-skip')));
    await t.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('reduce motion: Next jumps without animating', (t) async {
    await t.pumpWidget(_app(WelcomeCarouselScreen(onDone: () {}),
        reduceMotion: true));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('welcome-next')));
    await t.pump();
    expect(find.text(l.welcomeSlide2Title), findsOneWidget);
    expect(find.byType(AnimatedScale), findsNothing);
  });

  testWidgets('gate: shown once per device, Get started marks it seen',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_app(const WelcomeGate(child: _login)));
    await t.pumpAndSettle();
    expect(find.byType(WelcomeCarouselScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('login')), findsNothing);

    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const ValueKey('welcome-next')));
      await t.pumpAndSettle();
    }
    await t.tap(find.byKey(const ValueKey('welcome-get-started')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('login')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(WelcomeGate.prefKey), isTrue);

    // Next launch: straight to login.
    await t.pumpWidget(_app(const SizedBox()));
    await t.pumpWidget(_app(const WelcomeGate(child: _login)));
    await t.pumpAndSettle();
    expect(find.byType(WelcomeCarouselScreen), findsNothing);
    expect(find.byKey(const ValueKey('login')), findsOneWidget);
  });

  testWidgets('gate: Skip also marks it seen', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_app(const WelcomeGate(child: _login)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('welcome-skip')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('login')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(WelcomeGate.prefKey), isTrue);
  });

  test('web deep links to a specific page skip the carousel', () {
    expect(WelcomeGate.isWebDeepLink(Uri.parse('https://greengo-chat.web.app/')),
        isFalse);
    expect(
        WelcomeGate.isWebDeepLink(
            Uri.parse('https://greengo-chat.web.app/index.html')),
        isFalse);
    expect(
        WelcomeGate.isWebDeepLink(Uri.parse('https://greengo-chat.web.app/e/abc')),
        isTrue);
    expect(
        WelcomeGate.isWebDeepLink(Uri.parse('https://greengo-chat.web.app/guest')),
        isTrue);
    expect(
        WelcomeGate.isWebDeepLink(
            Uri.parse('https://greengo-chat.web.app/?link=%2Fu%2Fxyz')),
        isTrue);
  });
}
