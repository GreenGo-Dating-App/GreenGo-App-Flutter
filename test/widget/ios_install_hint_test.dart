import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/ios_install_hint.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  tearDown(() => iosInstallHintEligible = () => false);

  testWidgets('install link only on an iPhone/iPad browser', (tester) async {
    iosInstallHintEligible = () => false;
    await tester.pumpWidget(_app(const IosInstallLink()));
    expect(find.byKey(const ValueKey('ios-install-link')), findsNothing);

    iosInstallHintEligible = () => true;
    await tester.pumpWidget(_app(const IosInstallLink(), locale: const Locale('it')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ios-install-link')), findsOneWidget);
    expect(find.textContaining('iPhone'), findsOneWidget);
  });

  testWidgets('banner shows once, then stays hidden for 30 days after dismiss', (tester) async {
    SharedPreferences.setMockInitialValues({});
    iosInstallHintEligible = () => true;
    await tester.pumpWidget(_app(Builder(builder: (c) => TextButton(
        onPressed: () => IosInstallBanner.maybeShow(c), child: const Text('go')))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ios-install-banner')), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ios-install-banner')), findsNothing);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ios-install-banner')), findsNothing);
  });

  testWidgets('no banner when not eligible', (tester) async {
    SharedPreferences.setMockInitialValues({});
    iosInstallHintEligible = () => false;
    await tester.pumpWidget(_app(Builder(builder: (c) => TextButton(
        onPressed: () => IosInstallBanner.maybeShow(c), child: const Text('go')))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ios-install-banner')), findsNothing);
  });
}
