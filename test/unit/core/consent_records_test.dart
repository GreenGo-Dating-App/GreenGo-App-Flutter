import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/consent_recorder.dart';
import 'package:greengo_chat/features/authentication/presentation/widgets/consent_checkboxes.dart';
import 'package:greengo_chat/features/notifications/data/models/notification_preferences_model.dart';
import 'package:greengo_chat/features/notifications/domain/entities/notification_preferences.dart';
import 'package:greengo_chat/features/safety/presentation/screens/moderation_decision_screen.dart';
import 'package:greengo_chat/features/safety/presentation/widgets/id_consent_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('signup consent defaults (P2-5d)', () {
    test('every optional consent starts unticked', () {
      expect(ConsentCheckboxes.defaultProfilingAccepted, isFalse);
      expect(ConsentCheckboxes.defaultThirdPartyDataAccepted, isFalse);
      expect(ConsentCheckboxes.defaultMarketingEmailAccepted, isFalse);
    });

    testWidgets('marketing opt-in box renders unticked and toggles', (tester) async {
      var marketing = false;
      await tester.pumpWidget(_app(StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: ConsentCheckboxes(
            privacyPolicyAccepted: false,
            termsAccepted: false,
            profilingAccepted: ConsentCheckboxes.defaultProfilingAccepted,
            thirdPartyDataAccepted: ConsentCheckboxes.defaultThirdPartyDataAccepted,
            marketingEmailAccepted: marketing,
            onPrivacyPolicyChanged: (_) {},
            onTermsChanged: (_) {},
            onProfilingChanged: (_) {},
            onThirdPartyDataChanged: (_) {},
            onMarketingEmailChanged: (v) => setState(() => marketing = v),
          ),
        ),
      )));
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes, hasLength(5));
      expect(boxes.every((b) => b.value == false), isTrue);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      expect(marketing, isTrue);
    });

    test('signup records terms, privacy and the real optional choices', () async {
      final sent = <Map<String, dynamic>>[];
      final r = ConsentRecorder(
          callable: (p) async => sent.add(p), currentUid: () => 'u1');
      await r.recordSignupConsents(
          profiling: false, thirdPartyData: true, marketingEmail: false,
          docVersion: '2026-09-15');
      final byType = {for (final p in sent) p['type'] as String: p};
      expect(byType.keys.toSet(), {
        'terms', 'privacy', 'profiling', 'third_party_data', 'marketing_email'
      });
      expect(byType['terms']!['accepted'], isTrue);
      expect(byType['terms']!['docVersion'], '2026-09-15');
      expect(byType['privacy']!['accepted'], isTrue);
      expect(byType['profiling']!['accepted'], isFalse);
      expect(byType['third_party_data']!['accepted'], isTrue);
      expect(byType['marketing_email']!['accepted'], isFalse);
      for (final p in sent) {
        expect(p['version'], 1);
        expect(p['locale'], isA<String>());
      }
    });

    test('a failing server call never throws and is not mirrored locally', () async {
      var calls = 0;
      final r = ConsentRecorder(
          callable: (p) async {
            calls++;
            throw Exception('offline');
          },
          currentUid: () => 'u1');
      final ok = await r.record(type: ConsentTypes.marketingEmail, accepted: true);
      expect(ok, isFalse);
      expect(calls, 1);
      expect(await r.localDecision(ConsentTypes.marketingEmail), isNull);
    });

    test('signed out: nothing is sent', () async {
      var calls = 0;
      final r = ConsentRecorder(
          callable: (p) async => calls++, currentUid: () => null);
      expect(await r.record(type: 'terms', accepted: true), isFalse);
      expect(calls, 0);
    });
  });

  group('marketing push category (P2-5c)', () {
    test('defaults OFF and is written under categories.marketing', () {
      const p = NotificationPreferences(userId: 'u1');
      expect(p.marketing, isFalse);
      final m = NotificationPreferencesModel.fromEntity(p.copyWith(marketing: true));
      final cats = m.toFirestore()['categories'] as Map<String, dynamic>;
      expect(cats['marketing'], isTrue);
      final off = NotificationPreferencesModel.fromEntity(p).toFirestore();
      expect((off['categories'] as Map)['marketing'], isFalse);
    });
  });

  group('ID consent sheet (P2-6)', () {
    testWidgets('accept records id_verification before returning true', (tester) async {
      final sent = <Map<String, dynamic>>[];
      final r = ConsentRecorder(
          callable: (p) async => sent.add(p), currentUid: () => 'u1');
      bool? result;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showIdConsentSheet(context, recorder: r),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(IdConsentSheetBody)))!;
      expect(find.text(l10n.idConsentRetention), findsOneWidget);
      expect(find.text(l10n.idConsentWho), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('idConsentAccept')));
      await tester.tap(find.byKey(const Key('idConsentAccept')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(sent.single['type'], 'id_verification');
      expect(sent.single['accepted'], isTrue);
      expect(sent.single['version'], kIdVerificationConsentVersion);
    });

    testWidgets('cancel sends nothing', (tester) async {
      final sent = <Map<String, dynamic>>[];
      final r = ConsentRecorder(
          callable: (p) async => sent.add(p), currentUid: () => 'u1');
      bool? result;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showIdConsentSheet(context, recorder: r),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('idConsentCancel')));
      await tester.tap(find.byKey(const Key('idConsentCancel')));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(sent, isEmpty);
    });
  });

  group('moderation decision (P2-8c)', () {
    test('parses FCM string payloads', () {
      final d = ModerationDecision.fromData({
        'action': 'moderation_decision',
        'decisionId': 'q1',
        'moderationAction': 'removeContent',
        'reasonCode': 'spam',
        'explanation': 'Repeated promotional links.',
        'appealable': 'true',
        'appealDeadline': '2099-01-01T00:00:00.000Z',
      })!;
      expect(d.appealable, isTrue);
      expect(d.appealWindowOpen, isTrue);
      expect(ModerationDecision.fromData({'decisionId': ''}), isNull);
      final closed = ModerationDecision.fromData(
          {'decisionId': 'x', 'appealable': 'true', 'appealDeadline': '2000-01-01T00:00:00Z'})!;
      expect(closed.appealWindowOpen, isFalse);
    });

    testWidgets('appeal flow sends decisionId + reason', (tester) async {
      final calls = <List<String>>[];
      final decision = ModerationDecision.fromData({
        'decisionId': 'q1',
        'moderationAction': 'issueWarning',
        'reasonCode': 'harassment',
        'explanation': 'Insulting messages in a group chat.',
        'appealable': 'true',
      })!;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ModerationDecisionScreen(
          decision: decision,
          submitter: ({required decisionId, required appealReason}) async =>
              calls.add([decisionId, appealReason]),
        ),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(ModerationDecisionScreen)))!;
      expect(find.text(l10n.moderationActionWarning), findsOneWidget);
      expect(find.text(l10n.moderationReasonHarassment), findsOneWidget);
      expect(find.text('Insulting messages in a group chat.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('appealButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('appealReasonField')), 'short');
      await tester.tap(find.byKey(const Key('appealSubmit')));
      await tester.pumpAndSettle();
      expect(calls, isEmpty); // too short
      await tester.enterText(find.byKey(const Key('appealReasonField')),
          'This was a joke between friends, please review.');
      await tester.tap(find.byKey(const Key('appealSubmit')));
      await tester.pumpAndSettle();
      expect(calls, [
        ['q1', 'This was a joke between friends, please review.']
      ]);
      expect(find.byKey(const Key('appealButton')), findsNothing);
    });
  });
}
