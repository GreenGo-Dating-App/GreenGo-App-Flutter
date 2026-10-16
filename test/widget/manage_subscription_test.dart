import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/presentation/manage_subscription.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  final opened = <Uri>[];
  var portalCalls = 0;
  var portalResult = true;

  setUp(() {
    opened.clear();
    portalCalls = 0;
    portalResult = true;
    ManageSubscription.openPortal = () async {
      portalCalls++;
      return portalResult;
    };
    ManageSubscription.openUrl = (u) async {
      opened.add(u);
      return true;
    };
  });
  tearDown(() {
    ManageSubscription.isWebOverride = null;
    ManageSubscription.platformOverride = null;
  });

  Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(onPressed: () => ManageSubscription.open(context), child: const Text('go')),
          ),
        ),
      );

  testWidgets('web with a web subscription: opens the Stripe billing portal', (t) async {
    ManageSubscription.isWebOverride = true;
    await t.pumpWidget(app());
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(portalCalls, 1);
    expect(find.byKey(const ValueKey('manage-subscription-help')), findsNothing);
  });

  testWidgets('web without a web subscription: explains where to cancel', (t) async {
    ManageSubscription.isWebOverride = true;
    portalResult = false;
    await t.pumpWidget(app());
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('manage-subscription-help')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('manage-subscription-play')));
    expect(opened.single.toString(), ManageSubscription.playSubscriptionsUrl);
  });

  testWidgets('Android: opens Google Play subscriptions for GreenGo', (t) async {
    ManageSubscription.isWebOverride = false;
    ManageSubscription.platformOverride = TargetPlatform.android;
    await t.pumpWidget(app());
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(opened.single.toString(), contains('package=com.greengochat.greengochatapp'));
    expect(portalCalls, 0);
  });

  testWidgets('iOS: opens App Store subscriptions', (t) async {
    ManageSubscription.isWebOverride = false;
    ManageSubscription.platformOverride = TargetPlatform.iOS;
    await t.pumpWidget(app());
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(opened.single.toString(), ManageSubscription.appStoreSubscriptionsUrl);
  });
}
