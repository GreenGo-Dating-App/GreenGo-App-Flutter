// Terms 15.3: "Promotional use of my content" in Settings > Privacy & data.
// Separate permission: OFF unless the user turns it on; recorded server-side
// as the `promotional_use` consent (recordConsent), owner-only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/analytics_consent_service.dart';
import 'package:greengo_chat/core/services/consent_recorder.dart';
import 'package:greengo_chat/features/settings/presentation/screens/privacy_data_settings_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApplier implements AnalyticsCollectionApplier {
  @override
  Future<void> apply({required bool enabled, required bool everEnabled}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, ConsentRecorder recorder, {bool? server}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PrivacyDataSettingsScreen(
        analytics: AnalyticsConsentService(applier: _FakeApplier(), deviceCountryCode: () => 'BR'),
        recorder: recorder,
        readServerConsent: (_) async => server,
      ),
    ));
    await tester.pumpAndSettle();
  }

  SwitchListTile tile(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byKey(const Key('privacyPromotionalUseSwitch')));

  testWidgets('off by default; turning it on records promotional_use', (tester) async {
    final sent = <Map<String, dynamic>>[];
    await pump(tester, ConsentRecorder(callable: (p) async => sent.add(p), currentUid: () => 'u1'));
    final l10n = AppLocalizations.of(tester.element(find.byType(PrivacyDataSettingsScreen)))!;
    expect(find.text(l10n.promotionalUseTitle), findsOneWidget);
    expect(l10n.promotionalUseTitle, 'Promotional use of my content');
    expect(tile(tester).value, isFalse);

    await tester.tap(find.byKey(const Key('privacyPromotionalUseSwitch')));
    await tester.pumpAndSettle();
    expect(tile(tester).value, isTrue);
    expect(sent.single['type'], ConsentTypes.promotionalUse);
    expect(sent.single['type'], 'promotional_use');
    expect(sent.single['accepted'], isTrue);
  });

  testWidgets('a permission given on another device shows as on', (tester) async {
    await pump(tester, ConsentRecorder(callable: (_) async {}, currentUid: () => 'u1'), server: true);
    expect(tile(tester).value, isTrue);
  });

  testWidgets('a failed save puts the switch back', (tester) async {
    await pump(tester, ConsentRecorder(callable: (_) async => throw Exception('offline'), currentUid: () => 'u1'));
    await tester.tap(find.byKey(const Key('privacyPromotionalUseSwitch')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tile(tester).value, isFalse);
  });
}
