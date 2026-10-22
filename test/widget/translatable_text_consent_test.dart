import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/ai_consent_service.dart';
import 'package:greengo_chat/core/widgets/translatable_text.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Apple 5.1.2(i) (App Review 2026-10-22): automatic translation of public
/// content (events, experiences, reviews) needs the account's AI consent,
/// asked ONCE; without it the original shows with a Translate action that
/// asks again; the Settings switch changes it for every screen.
class _MemStore implements AiConsentStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

void main() {
  late List<String> sent;
  late List<bool> recorded;

  AiConsentService consent({bool? server}) => AiConsentService(
        store: _MemStore(),
        recorder: ({required bool accepted, required int version}) async =>
            recorded.add(accepted),
        currentUid: () => 'viewer',
        serverReader: (_) async => server,
      );

  Future<String> fakeTranslate(String text, String target,
      {required bool shared}) async {
    sent.add(text);
    return 'IT:$text';
  }

  setUp(() {
    sent = [];
    recorded = [];
  });

  Widget app(AiConsentService c, {List<String> texts = const ['Guided walk']}) =>
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(children: [
            for (final t in texts)
              TranslatableText(
                key: ValueKey(t),
                text: t,
                targetLang: 'it',
                style: const TextStyle(),
                autoTranslate: true,
                aiConsent: c,
                translator: fakeTranslate,
              ),
          ]),
        ),
      );

  Future<void> tapSheet(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('granted: translated at once, no sheet', (tester) async {
    final c = consent();
    await c.setDecision(accepted: true);
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(find.text('IT:Guided walk'), findsOneWidget);
    expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
  });

  testWidgets('undecided: the sheet is shown ONCE for all texts, Allow '
      'translates them and is recorded on the account', (tester) async {
    final c = consent();
    await tester.pumpWidget(app(c, texts: const ['Guided walk', 'Food tour']));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiConsentAccept')), findsOneWidget);
    expect(sent, isEmpty, reason: 'nothing sent before the choice');

    await tapSheet(tester, 'aiConsentAccept');
    expect(recorded, [true], reason: 'server record (consents/{uid})');
    expect(find.text('IT:Guided walk'), findsOneWidget);
    expect(find.text('IT:Food tour'), findsOneWidget);

    // Another screen later: no sheet again.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(c, texts: const ['Sunset cruise']));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
    expect(find.text('IT:Sunset cruise'), findsOneWidget);
  });

  testWidgets('Decline: original + Translate; the tap asks again',
      (tester) async {
    final c = consent();
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    await tapSheet(tester, 'aiConsentDecline');
    expect(c.status, AiConsentStatus.declined);
    expect(recorded, [false]);
    expect(find.text('Guided walk'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(sent, isEmpty);

    // New screen: a decided account is not prompted automatically.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
    expect(find.text('Translate'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('translatable-text-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiConsentAccept')), findsOneWidget);
    await tapSheet(tester, 'aiConsentAccept');
    expect(find.text('IT:Guided walk'), findsOneWidget);
    expect(sent, ['Guided walk'], reason: 'translated exactly once');
  });

  testWidgets('Settings switch: turning AI services on translates the waiting '
      'text; off stops automatic translation on the next screen',
      (tester) async {
    final c = consent();
    await c.setDecision(accepted: false);
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(find.text('Guided walk'), findsOneWidget);

    // What AiServicesSettingsCard does when switched ON.
    await c.setDecision(accepted: true);
    await tester.pumpAndSettle();
    expect(find.text('IT:Guided walk'), findsOneWidget);

    // Switched OFF: the next screen shows the original, nothing is sent.
    await c.setDecision(accepted: false);
    sent.clear();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(c, texts: const ['Wine tasting']));
    await tester.pumpAndSettle();
    expect(find.text('Wine tasting'), findsOneWidget);
    expect(sent, isEmpty);
  });
}
