import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/web_notification_help.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Future<void> _open(WidgetTester tester, WebNotificationHelp kind) async {
  webNotificationHelpKind = () => kind;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => showWebNotificationHelpDialog(context),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('browser: site-permission steps, no Open Settings button', (tester) async {
    await _open(tester, WebNotificationHelp.browser);
    expect(find.byKey(const ValueKey('web-notification-help')), findsOneWidget);
    expect(find.textContaining('next to the web address'), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-notification-help')), findsNothing);
  });

  testWidgets('installed iPhone web app: iOS Settings steps', (tester) async {
    await _open(tester, WebNotificationHelp.iosInstalled);
    expect(find.textContaining('Settings app on your iPhone'), findsOneWidget);
  });

  testWidgets('iPhone browser tab: add to Home Screen first', (tester) async {
    await _open(tester, WebNotificationHelp.iosNotInstalled);
    expect(find.textContaining('Home Screen'), findsOneWidget);
    expect(find.text('How to add it'), findsOneWidget);
  });
}
