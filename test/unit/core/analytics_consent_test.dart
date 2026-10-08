import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/analytics_consent_service.dart';
import 'package:greengo_chat/core/services/consent_recorder.dart';
import 'package:greengo_chat/core/widgets/analytics_consent_prompt.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApplier implements AnalyticsCollectionApplier {
  final List<bool> calls = [];
  @override
  Future<void> apply({required bool enabled, required bool everEnabled}) async {
    calls.add(enabled);
  }
}

Future<(AnalyticsConsentService, _FakeApplier, List<Map<String, dynamic>>)>
    _make(String? country, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final applier = _FakeApplier();
  final recorded = <Map<String, dynamic>>[];
  final svc = AnalyticsConsentService(
    applier: applier,
    deviceCountryCode: () => country,
    recorder: ConsentRecorder(
      callable: (p) async => recorded.add(p),
      currentUid: () => 'u1',
    ),
  );
  await svc.init(await SharedPreferences.getInstance());
  return (svc, applier, recorded);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('region rules', () {
    test('EEA / UK / CH and unknown need prior consent', () {
      for (final c in ['IT', 'de', 'FR', 'NO', 'IS', 'LI', 'GB', 'UK', 'CH', 'PT']) {
        expect(AnalyticsConsentService.isConsentRequiredRegion(c), isTrue, reason: c);
      }
      expect(AnalyticsConsentService.isConsentRequiredRegion(null), isTrue);
      expect(AnalyticsConsentService.isConsentRequiredRegion(''), isTrue);
    });

    test('other regions do not', () {
      for (final c in ['US', 'BR', 'IN', 'JP', 'AU']) {
        expect(AnalyticsConsentService.isConsentRequiredRegion(c), isFalse, reason: c);
      }
    });
  });

  group('defaults on first run', () {
    test('EEA: collection OFF, prompt shown, SDKs switched off', () async {
      final (svc, applier, _) = await _make('IT');
      expect(svc.consentRequired, isTrue);
      expect(svc.collectionAllowed, isFalse);
      expect(svc.shouldPrompt, isTrue);
      await svc.applyAtStartup();
      expect(applier.calls, [false]);
    });

    test('unknown region behaves like EEA', () async {
      final (svc, _, _) = await _make(null);
      expect(svc.collectionAllowed, isFalse);
      expect(svc.shouldPrompt, isTrue);
    });

    test('outside the EEA: ON by default (previous behaviour), no prompt', () async {
      final (svc, applier, _) = await _make('BR');
      expect(svc.collectionAllowed, isTrue);
      expect(svc.shouldPrompt, isFalse);
      await svc.applyAtStartup();
      expect(applier.calls, [true]);
    });

    test('region is decided once and stored (travel does not flip it)', () async {
      final (svc, _, _) = await _make('US',
          prefs: {AnalyticsConsentService.prefsRegionKey: 'DE'});
      expect(svc.region, 'DE');
      expect(svc.collectionAllowed, isFalse);
    });

    test('nothing is allowed before init', () {
      final svc = AnalyticsConsentService(
          applier: _FakeApplier(), deviceCountryCode: () => 'US');
      expect(svc.collectionAllowed, isFalse);
    });
  });

  group('choice', () {
    test('accepting in the EEA enables, stores and records', () async {
      final (svc, applier, recorded) = await _make('FR');
      await svc.setChoice(granted: true);
      await Future<void>.delayed(Duration.zero);
      expect(svc.collectionAllowed, isTrue);
      expect(svc.shouldPrompt, isFalse);
      expect(applier.calls.last, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AnalyticsConsentService.prefsChoiceKey), 'granted');
      expect(recorded.single['type'], 'analytics');
      expect(recorded.single['accepted'], isTrue);
      expect(recorded.single['region'], 'FR');
    });

    test('declining outside the EEA disables', () async {
      final (svc, applier, recorded) = await _make('US');
      await svc.setChoice(granted: false);
      await Future<void>.delayed(Duration.zero);
      expect(svc.collectionAllowed, isFalse);
      expect(applier.calls.last, isFalse);
      expect(recorded.single['accepted'], isFalse);
    });

    test('stored choice survives a restart', () async {
      final (svc, _, _) = await _make('IT',
          prefs: {AnalyticsConsentService.prefsChoiceKey: 'granted'});
      expect(svc.collectionAllowed, isTrue);
      expect(svc.shouldPrompt, isFalse);
    });
  });

  testWidgets('prompt: decline records denial, equal-weight buttons', (tester) async {
    final (svc, applier, recorded) = await _make('ES');
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showAnalyticsConsentPromptIfNeeded(context, service: svc),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('analyticsConsentAllow')), findsOneWidget);
    await tester.tap(find.byKey(const Key('analyticsConsentDecline')));
    await tester.pumpAndSettle();
    expect(svc.choice.value, AnalyticsConsentChoice.denied);
    expect(svc.collectionAllowed, isFalse);
    expect(applier.calls.last, isFalse);
    expect(recorded.single['accepted'], isFalse);
  });
}
