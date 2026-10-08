import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/safety/data/services/age_assurance_service.dart';
import 'package:greengo_chat/features/safety/presentation/screens/age_assurance_required_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// P3-1 regional age assurance: the app-side gate logic.
void main() {
  group('AgeAssuranceStatus', () {
    test('parses the getAgeAssuranceStatus response', () {
      final s = AgeAssuranceStatus.fromMap({
        'enforced': true,
        'required': true,
        'satisfied': true,
        'satisfiedBy': ['store_signal', 'admin_override', 'unknown_new_method'],
        'methods': ['id_verification', 'store_signal'],
      });
      expect(s.blocked, isFalse);
      expect(s.satisfiedBy,
          [AgeAssuranceMethod.storeSignal, AgeAssuranceMethod.adminOverride]);
      expect(s.methods,
          [AgeAssuranceMethod.idVerification, AgeAssuranceMethod.storeSignal]);
    });

    test('blocked only when required and not satisfied', () {
      AgeAssuranceStatus st(bool req, bool sat) =>
          AgeAssuranceStatus(enforced: true, required: req, satisfied: sat);
      expect(st(true, false).blocked, isTrue);
      expect(st(true, true).blocked, isFalse);
      expect(st(false, false).blocked, isFalse);
      expect(const AgeAssuranceStatus.notRequired().blocked, isFalse);
    });

    test('options per platform: no store signal on the web', () {
      const s = AgeAssuranceStatus(enforced: true, required: true, satisfied: false);
      expect(s.optionsFor(AgeAssurancePlatform.web),
          [AgeAssuranceMethod.idVerification]);
      expect(s.optionsFor(AgeAssurancePlatform.android),
          [AgeAssuranceMethod.storeSignal, AgeAssuranceMethod.idVerification]);
      expect(s.optionsFor(AgeAssurancePlatform.ios),
          [AgeAssuranceMethod.storeSignal, AgeAssuranceMethod.idVerification]);
      // A server that only offers ID verification: no store button anywhere.
      const idOnly = AgeAssuranceStatus(
          enforced: true,
          required: true,
          satisfied: false,
          methods: [AgeAssuranceMethod.idVerification]);
      expect(idOnly.optionsFor(AgeAssurancePlatform.android),
          [AgeAssuranceMethod.idVerification]);
    });
  });

  group('AgeAssuranceService', () {
    test('flag OFF: not required and the callable is never invoked', () async {
      var calls = 0;
      final svc = AgeAssuranceService(
        readFlag: () async => false,
        fetchStatus: (_) async {
          calls++;
          return {'required': true, 'satisfied': false};
        },
      );
      expect(await svc.isBlocked(), isFalse);
      expect(calls, 0);
    });

    test('flag ON: uses the server answer, cached until invalidated', () async {
      var calls = 0;
      Map<String, dynamic>? sentHints;
      final svc = AgeAssuranceService(
        readFlag: () async => true,
        fetchStatus: (hints) async {
          calls++;
          sentHints = hints;
          return {'enforced': true, 'required': true, 'satisfied': false};
        },
      );
      expect(await svc.isBlocked(), isTrue);
      expect(await svc.isBlocked(), isTrue);
      expect(calls, 1);
      expect(sentHints, isA<Map<String, dynamic>>());
      svc.invalidate();
      await svc.status();
      expect(calls, 2);
      await svc.status(refresh: true);
      expect(calls, 3);
    });

    test('fails OPEN on errors and does not cache the failure', () async {
      var fail = true;
      final svc = AgeAssuranceService(
        readFlag: () async => true,
        fetchStatus: (_) async {
          if (fail) throw Exception('offline');
          return {'enforced': true, 'required': true, 'satisfied': false};
        },
      );
      expect(await svc.isBlocked(), isFalse);
      fail = false;
      expect(await svc.isBlocked(), isTrue);
    });
  });

  group('gate UI', () {
    Widget app(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        );

    AgeAssuranceService svc({required bool blocked}) => AgeAssuranceService(
          readFlag: () async => true,
          fetchStatus: (_) async => {
            'enforced': true,
            'required': blocked,
            'satisfied': false,
          },
        );

    testWidgets('panel on the web offers ID verification only', (t) async {
      await t.pumpWidget(app(AgeAssuranceRequiredPanel(
          service: svc(blocked: true), platform: AgeAssurancePlatform.web)));
      await t.pumpAndSettle();
      final l10n = AppLocalizations.of(
          t.element(find.byType(AgeAssuranceRequiredPanel)))!;
      expect(find.text(l10n.ageAssuranceTitle), findsOneWidget);
      expect(find.byKey(const Key('ageAssuranceIdButton')), findsOneWidget);
      expect(find.byKey(const Key('ageAssuranceStoreButton')), findsNothing);
      expect(find.text(l10n.ageAssuranceWebNote), findsOneWidget);
    });

    testWidgets('panel on Android offers the Play check and ID', (t) async {
      await t.pumpWidget(app(AgeAssuranceRequiredPanel(
          service: svc(blocked: true),
          platform: AgeAssurancePlatform.android)));
      await t.pumpAndSettle();
      final l10n = AppLocalizations.of(
          t.element(find.byType(AgeAssuranceRequiredPanel)))!;
      expect(find.text(l10n.ageAssuranceStoreCheckAndroid), findsOneWidget);
      expect(find.byKey(const Key('ageAssuranceIdButton')), findsOneWidget);
    });

    testWidgets('gate view shows the feature when not blocked', (t) async {
      await t.pumpWidget(app(AgeAssuranceGateView(
          service: svc(blocked: false), child: const Text('people grid'))));
      await t.pumpAndSettle();
      expect(find.text('people grid'), findsOneWidget);
      expect(find.byType(AgeAssuranceRequiredPanel), findsNothing);
    });

    testWidgets('gate view replaces the feature when blocked', (t) async {
      await t.pumpWidget(app(AgeAssuranceGateView(
          service: svc(blocked: true), child: const Text('people grid'))));
      await t.pumpAndSettle();
      expect(find.text('people grid'), findsNothing);
      expect(find.byType(AgeAssuranceRequiredPanel), findsOneWidget);
    });

    testWidgets('send guard: allowed in a conversation the user already wrote in',
        (t) async {
      late BuildContext ctx;
      await t.pumpWidget(app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      final blocked = svc(blocked: true);
      expect(
          await AgeAssuranceGuard.ensureCanSend(ctx,
              conversationId: 'c1',
              userId: 'u1',
              alreadyWrote: true,
              service: blocked),
          isTrue);
      final open = svc(blocked: false);
      expect(
          await AgeAssuranceGuard.ensureCanStartConversation(ctx,
              service: open),
          isTrue);
    });
  });
}
