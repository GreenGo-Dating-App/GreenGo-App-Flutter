import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/legal_versions.dart';
import 'package:greengo_chat/core/services/consent_recorder.dart';
import 'package:greengo_chat/core/services/legal_documents_service.dart';
import 'package:greengo_chat/features/legal/presentation/widgets/legal_update_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _langs = ['de', 'en', 'es', 'fr', 'it', 'pt', 'pt_BR'];

String _asset(String prefix, String lang) =>
    File('assets/legal/$prefix-$lang.txt').readAsStringSync();

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetLegalUpdateSheetSession();
  });

  group('bundled legal texts v5.1.0', () {
    for (final lang in _langs) {
      test('terms + privacy ($lang) carry the version constants', () {
        for (final (prefix, version) in [
          ('terms-and-conditions', kTermsVersion),
          ('privacy-policy', kPrivacyPolicyVersion),
        ]) {
          final text = _asset(prefix, lang);
          expect(text.codeUnitAt(0), isNot(0xFEFF), reason: 'no BOM');
          expect(LegalDocument.parseHeaderVersion(text.split('\n')), version,
              reason: '$prefix-$lang');
          // CRLF checkouts (Windows) parse the same.
          final crlf = text.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
          final doc = LegalDocument.fromAsset(
            type: prefix == 'privacy-policy'
                ? LegalDocumentType.privacyPolicy
                : LegalDocumentType.termsAndConditions,
            languageCode: lang,
            content: crlf,
          );
          expect(doc.version, version);
          expect(doc.lastUpdated, kLegalEffectiveDate);
          expect(doc.title.trim(), isNotEmpty);
          expect(doc.title.contains('\r'), isFalse);
        }
      });
    }

    test('"Previous version" lines are never taken as the version', () {
      expect(
          LegalDocument.parseHeaderVersion(
              ['X', '', 'Previous version: 5.0.0 (9 October 2026)', 'Version : 5.1.0']),
          '5.1.0');
    });

    test('English texts carry no dating wording', () {
      // "romantic" appears on purpose, in the disclaimer ("not for finding
      // romantic or sexual partners") and in the harassment rules.
      final re = RegExp(r'\bdating\b|\bflirt|\bsoul ?mate|\bhook[ -]?ups?\b',
          caseSensitive: false);
      for (final prefix in ['terms-and-conditions', 'privacy-policy']) {
        expect(re.hasMatch(_asset(prefix, 'en')), isFalse, reason: prefix);
      }
    });

    test('privacy policies say sexual orientation is NOT collected', () {
      final en = _asset('privacy-policy', 'en');
      expect(en, contains('Sexual orientation: we do NOT collect it'));
      expect(en, contains('10.5 Private photos and chat media: warning and record'));
      expect(_asset('terms-and-conditions', 'en'),
          contains("16.9 Other users' photos, content and personal data"));
    });
  });

  group('isLegalVersionAtLeast', () {
    test('compares dotted versions; anything else is older', () {
      expect(isLegalVersionAtLeast('5.1.0', '5.1.0'), isTrue);
      expect(isLegalVersionAtLeast('5.1.1', '5.1.0'), isTrue);
      expect(isLegalVersionAtLeast('6.0', '5.1.0'), isTrue);
      expect(isLegalVersionAtLeast('5.0.0', '5.1.0'), isFalse);
      expect(isLegalVersionAtLeast('1.0', '5.1.0'), isFalse);
      expect(isLegalVersionAtLeast('2026-09-15', '5.1.0'), isFalse);
      expect(isLegalVersionAtLeast('', '5.1.0'), isFalse);
      expect(isLegalVersionAtLeast(null, '5.1.0'), isFalse);
    });
  });

  group('LegalUpdateGate', () {
    ConsentRecorder recorder(List<Map<String, dynamic>> sent, {bool fail = false}) =>
        ConsentRecorder(
          callable: (p) async {
            if (fail) throw Exception('offline');
            sent.add(p);
          },
          currentUid: () => 'u1',
        );

    LegalUpdateGate gate(ConsentRecorder r, Map<String, dynamic>? doc,
            {List<String>? reads, bool throwOnRead = false}) =>
        LegalUpdateGate(
          recorder: r,
          currentUid: () => 'u1',
          readConsents: (uid) async {
            reads?.add(uid);
            if (throwOnRead) throw Exception('offline');
            return doc;
          },
        );

    Map<String, dynamic> rec(String v) => {'accepted': true, 'version': 1, 'docVersion': v};

    test('no record (pre-consent account or social sign-in) -> ask', () async {
      expect(await gate(recorder([]), null).needsAcceptance(), isTrue);
    });

    test('accepted an older version -> ask', () async {
      final g = gate(recorder([]), {'terms': rec('2026-09-15'), 'privacy': rec('2026-09-15')});
      expect(await g.needsAcceptance(), isTrue);
      final g2 = gate(recorder([]), {'terms': rec('5.1.0'), 'privacy': rec('5.0.0')});
      expect(await g2.needsAcceptance(), isTrue);
    });

    test('accepted 5.1.0 -> no sheet, mirrored locally, no second read', () async {
      final reads = <String>[];
      final r = recorder([]);
      final doc = {'terms': rec('5.1.0'), 'privacy': rec('5.1.0')};
      expect(await gate(r, doc, reads: reads).needsAcceptance(), isFalse);
      expect(await gate(r, doc, reads: reads).needsAcceptance(), isFalse);
      expect(reads, ['u1']);
    });

    test('unreadable record (offline) -> do not block, ask next start', () async {
      expect(await gate(recorder([]), null, throwOnRead: true).needsAcceptance(), isFalse);
    });

    test('signed out -> nothing', () async {
      final g = LegalUpdateGate(
          recorder: recorder([]), currentUid: () => null, readConsents: (_) async => null);
      expect(await g.needsAcceptance(), isFalse);
    });
  });

  group('legal update sheet', () {
    testWidgets('I agree records terms + privacy 5.1.0 server-side, then closes',
        (tester) async {
      final sent = <Map<String, dynamic>>[];
      final r = ConsentRecorder(callable: (p) async => sent.add(p), currentUid: () => 'u1');
      var signedOut = false;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => showLegalUpdateSheetIfNeeded(
            context,
            onSignOut: () => signedOut = true,
            recorder: r,
            gate: LegalUpdateGate(
                recorder: r, currentUid: () => 'u1', readConsents: (_) async => null),
          ),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(LegalUpdateSheetBody)))!;
      expect(find.text(l10n.legalUpdateTitle), findsOneWidget);
      expect(find.text(l10n.legalUpdateBulletPrivateContent), findsOneWidget);
      expect(find.text(l10n.legalUpdateBulletWarning), findsOneWidget);
      expect(find.text(l10n.legalUpdateBulletOrientation), findsOneWidget);

      // Not dismissable by a tap outside.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(LegalUpdateSheetBody), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('legalUpdateAgree')));
      await tester.tap(find.byKey(const Key('legalUpdateAgree')));
      await tester.pumpAndSettle();
      expect(find.byType(LegalUpdateSheetBody), findsNothing);
      expect(signedOut, isFalse);
      final byType = {for (final p in sent) p['type'] as String: p};
      expect(byType.keys.toSet(), {'terms', 'privacy'});
      expect(byType['terms']!['docVersion'], kTermsVersion);
      expect(byType['privacy']!['docVersion'], kPrivacyPolicyVersion);
      expect(byType['terms']!['accepted'], isTrue);
      // The client never sends a timestamp: the server stamps it.
      expect(sent.every((p) => !p.containsKey('at') && !p.containsKey('acceptedAt')), isTrue);
      expect(await r.localDocVersion('terms'), kTermsVersion);
    });

    testWidgets('a failed save keeps the sheet open with an error', (tester) async {
      final r = ConsentRecorder(
          callable: (p) async => throw Exception('offline'), currentUid: () => 'u1');
      await tester.pumpWidget(_app(LegalUpdateSheetBody(recorder: r)));
      await tester.ensureVisible(find.byKey(const Key('legalUpdateAgree')));
      await tester.tap(find.byKey(const Key('legalUpdateAgree')));
      // record() retries once after 2 s.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(LegalUpdateSheetBody)))!;
      expect(find.text(l10n.legalUpdateSaveFailed), findsOneWidget);
      expect(find.byType(LegalUpdateSheetBody), findsOneWidget);
    });

    testWidgets('Sign out closes the sheet and signs out', (tester) async {
      final r = ConsentRecorder(callable: (p) async {}, currentUid: () => 'u1');
      var signedOut = false;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => showLegalUpdateSheetIfNeeded(
            context,
            onSignOut: () => signedOut = true,
            recorder: r,
            gate: LegalUpdateGate(
                recorder: r, currentUid: () => 'u1', readConsents: (_) async => null),
          ),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('legalUpdateSignOut')));
      await tester.tap(find.byKey(const Key('legalUpdateSignOut')));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
    });
  });
}
