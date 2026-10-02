import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';
import 'package:greengo_chat/features/user_experiences/domain/cancellation_rules.dart';
import 'package:greengo_chat/features/user_experiences/domain/contact_info.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/features/user_experiences/domain/experience_validation.dart';
import 'package:greengo_chat/features/user_experiences/domain/review_moderation.dart';
import 'package:greengo_chat/features/user_experiences/presentation/experience_safety_flow.dart';
import 'package:greengo_chat/features/user_experiences/presentation/screens/host_agreement_screen.dart';
import 'package:greengo_chat/features/user_experiences/presentation/widgets/booking_consent_dialog.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Phase 1 experience safety — client mirrors of the server rules.
UserExperience _exp({
  bool isFree = false,
  Set<PaymentMethod> methods = const {PaymentMethod.link},
  PaymentLink? link =
      const PaymentLink(type: PaymentLinkType.pix, value: 'key@example.com'),
  CancellationPolicy policy = CancellationPolicy.moderate,
}) =>
    UserExperience(
      id: 'e1',
      hostId: 'h',
      title: 'Cooking class',
      description: 'd' * 40,
      category: ExperienceCategory.foodDrink,
      mainPhotoUrl: 'https://a/b.jpg',
      included: const ['Dinner'],
      locationName: 'Rome',
      durationMinutes: 120,
      languages: const ['English'],
      maxGroupSize: 6,
      price: isFree ? 0 : 50,
      isFree: isFree,
      paymentLink: link,
      paymentMethods: methods,
      cancellationPolicy: policy,
    );

ExperienceDraft _draft({
  String description = 'A lovely evening cooking fresh pasta with locals.',
  String meetingPoint = '',
  String notes = '',
  bool isFree = false,
  Set<PaymentMethod> methods = const {PaymentMethod.link},
  String paymentValue = 'key@example.com',
}) =>
    ExperienceDraft(
      title: 'Cooking class',
      description: description,
      category: ExperienceCategory.foodDrink,
      hasMainPhoto: true,
      photoCount: 0,
      included: const ['Dinner'],
      notIncluded: const [],
      locationName: 'Rome',
      durationMinutes: 120,
      languages: const ['English'],
      maxGroupSize: 6,
      meetingPoint: meetingPoint,
      cancellationNotes: notes,
      isFree: isFree,
      price: isFree ? 0 : 50,
      paymentType: PaymentLinkType.pix,
      paymentValue: paymentValue,
      paymentMethods: methods,
    );

void main() {
  group('contact info detector (shared fixture with the server)', () {
    // Same file functions/__tests__/unit/experienceSafety.test.ts reads.
    final fixture = jsonDecode(
            File('functions/__tests__/fixtures/contact_info_cases.json')
                .readAsStringSync()) as Map<String, dynamic>;
    for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
      final text = c['text'] as String;
      test(text, () {
        final got = ContactInfoDetector.find(text)
            .map(ContactInfoDetector.wireName)
            .toSet();
        expect(got, (c['kinds'] as List).cast<String>().toSet());
      });
    }

    test('review / reply verdict + experience validation', () {
      expect(
          ReviewModeration.check('Great! call me 11 98765-4321',
              maxLength: 1000),
          CommentVerdict.contactInfo);
      expect(ReviewModeration.check('Great host', maxLength: 1000),
          CommentVerdict.ok);
      expect(ExperienceValidator.validate(_draft(meetingPoint: 'WhatsApp me')),
          contains(ExperienceFieldError.contactInfo));
      expect(ExperienceValidator.validate(_draft(notes: 'mail a@b.co')),
          contains(ExperienceFieldError.contactInfo));
      // The payment link field itself is exempt.
      expect(ExperienceValidator.validate(_draft()), isEmpty);
    });
  });

  group('payment methods', () {
    test('validation: paid needs a method; link only when chosen', () {
      expect(ExperienceValidator.validate(_draft(methods: const {})),
          contains(ExperienceFieldError.paymentMethodsRequired));
      expect(
          ExperienceValidator.validate(
              _draft(methods: const {PaymentMethod.cash}, paymentValue: '')),
          isEmpty);
      expect(
          ExperienceValidator.validate(
              _draft(methods: const {PaymentMethod.link}, paymentValue: '')),
          contains(ExperienceFieldError.paymentLinkRequired));
      expect(ExperienceValidator.validate(_draft(isFree: true, methods: const {})),
          isEmpty);
    });

    test('model: legacy docs with a link read as {link}; payload drops the '
        'link when only cash', () {
      final legacy = UserExperienceModel.fromMap('x', {
        'isFree': false,
        'paymentLink': {'type': 'pix', 'value': 'k'},
      });
      expect(legacy.paymentMethods, {PaymentMethod.link});
      final cash = UserExperienceModel.fromMap('y', {
        'isFree': false,
        'paymentMethods': ['cash'],
      });
      expect(cash.acceptsCash, isTrue);
      expect(cash.acceptsLink, isFalse);
      final p = UserExperienceModel.editablePayload(
          _exp(methods: const {PaymentMethod.cash}));
      expect(p['paymentMethods'], ['cash']);
      expect(p['paymentLink'], isNull);
      final free = UserExperienceModel.editablePayload(_exp(isFree: true));
      expect(free['paymentMethods'], isEmpty);
      expect(free['paymentLink'], isNull);
    });

    test('consent dialog methods + guidance', () async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final both =
          _exp(methods: const {PaymentMethod.cash, PaymentMethod.link});
      expect(BookingConsentDialog.methodsOf(both),
          [PaymentMethod.link, PaymentMethod.cash]);
      expect(
          BookingConsentDialog.methodsOf(
              _exp(methods: const {PaymentMethod.cash}, link: null)),
          [PaymentMethod.cash]);
      expect(BookingConsentDialog.guidance(l, both, PaymentMethod.link).single,
          contains('MED'));
      expect(BookingConsentDialog.guidance(l, both, PaymentMethod.cash).single,
          l.uexpGuideCash);
      // asFree drops every payment.
      final f = both.asFree();
      expect(f.isFree && f.paymentMethods.isEmpty && f.paymentLink == null,
          isTrue);
      expect(f.takesPayment, isFalse);
    });
  });

  group('ID document state (mirror of safety.ts)', () {
    test('states', () {
      expect(idDocStateFromProfile(null), IdDocState.none);
      expect(
          idDocStateFromProfile({
            'ageVerification': {'status': 'declared'}
          }),
          IdDocState.none);
      expect(
          idDocStateFromProfile({
            'ageVerification': {'status': 'pending'}
          }),
          IdDocState.uploaded);
      expect(idDocStateFromProfile({'isAgeVerified': true}),
          IdDocState.approved);
      final s = HostSafetySnapshot.fromProfile({
        'ageVerification': {'status': 'rejected'},
        'hostAgreementVersion': HostAgreementScreen.currentVersion,
      });
      expect(s.idState, IdDocState.none);
      expect(s.idRejected, isTrue);
      expect(s.agreementAccepted, isTrue);
      expect(const HostSafetySnapshot().agreementAccepted, isFalse);
    });
  });

  group('cancellation policies', () {
    test('tables', () {
      expect(
          CancellationRules.tiers(CancellationPolicy.moderate)
              .map((t) => t.refund),
          [1, 0.5, 0]);
      expect(
          CancellationRules.tiers(CancellationPolicy.flexible)
              .map((t) => t.refund),
          [1, 0]);
      expect(
          CancellationRules.tiers(CancellationPolicy.strict)
              .map((t) => t.refund),
          [1, 0]);
    });

    test('refunds incl. universal rules', () {
      const h = Duration(hours: 1);
      expect(
          CancellationRules.refund(CancellationPolicy.flexible,
              beforeStart: h * 25),
          1);
      expect(
          CancellationRules.refund(CancellationPolicy.flexible,
              beforeStart: h * 23),
          0);
      expect(
          CancellationRules.refund(CancellationPolicy.moderate,
              beforeStart: h * 24 * 8),
          1);
      expect(
          CancellationRules.refund(CancellationPolicy.moderate,
              beforeStart: h * 48),
          0.5);
      expect(
          CancellationRules.refund(CancellationPolicy.strict,
              beforeStart: h * 24 * 6),
          0);
      // host cancels → 100%
      expect(
          CancellationRules.refund(CancellationPolicy.strict,
              beforeStart: h, hostCancelled: true),
          1);
      // within 24 h of booking and > 48 h away → 100%
      expect(
          CancellationRules.refund(CancellationPolicy.strict,
              beforeStart: h * 72, sinceBooking: h * 2),
          1);
      expect(
          CancellationRules.refund(CancellationPolicy.strict,
              beforeStart: h * 40, sinceBooking: h * 2),
          0);
    });

    test('legacy free text reads as moderate + notes', () {
      final e = UserExperienceModel.fromMap('x', {
        'cancellationPolicy': 'Full refund 2 days before',
      });
      expect(e.cancellationPolicy, CancellationPolicy.moderate);
      expect(e.cancellationNotes, 'Full refund 2 days before');
    });
  });

  test('host agreement has every clause in all 7 languages', () async {
    for (final loc in const [
      Locale('en'),
      Locale('de'),
      Locale('es'),
      Locale('fr'),
      Locale('it'),
      Locale('pt'),
      Locale('pt', 'BR'),
    ]) {
      final l = await AppLocalizations.delegate.load(loc);
      final clauses = HostAgreementScreen.clauses(l);
      expect(clauses, hasLength(8));
      expect(clauses.every((c) => c.trim().length > 20), isTrue,
          reason: loc.toString());
    }
  });

  testWidgets('consent: Continue only after "I understand"; cash text',
      (tester) async {
    PaymentMethod? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await BookingConsentDialog.show(
                context, _exp(methods: const {PaymentMethod.cash}, link: null)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.uexpConsentBodyCash), findsOneWidget);
    final cont = find.byKey(const ValueKey('consent-continue'));
    expect(tester.widget<ElevatedButton>(cont).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('consent-understand')));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(cont).onPressed, isNotNull);
    await tester.tap(cont);
    await tester.pumpAndSettle();
    expect(result, PaymentMethod.cash);
  });
}
