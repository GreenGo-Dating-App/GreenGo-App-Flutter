import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/e2e_keys.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/providers/language_provider.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/register_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/widgets/pre_registration_offer.dart';
import 'package:greengo_chat/features/profile/domain/age_gate.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_state.dart';
import 'package:greengo_chat/features/profile/presentation/screens/onboarding/step1_basic_info_screen.dart';
import 'package:greengo_chat/features/profile/presentation/widgets/luxury_onboarding_layout.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/auth_fixtures.dart';

class MockOnboardingBloc extends Mock implements OnboardingBloc {}

final en = AppLocalizationsEn();

void main() {
  setUpAll(() {
    registerFallbackValue(const OnboardingNextStep());
  });

  group('Register: "We are creating your account" loader', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
      when(
        () => repo.authStateChanges,
      ).thenAnswer((_) => const Stream<domain.User?>.empty());
      when(
        () => repo.registerWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        // A slow sign-up (fake time) that ends in an error.
        (_) => Future.delayed(
          const Duration(seconds: 12),
          () => const Left<Failure, domain.User>(AuthenticationFailure()),
        ),
      );
    });

    Future<void> pumpRegister(
      WidgetTester tester, {
      required OfferLookup offerLookup,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            BlocProvider<AuthBloc>(
              create: (_) => AuthBloc(
                repository: repo,
                accessControlService: MockAccessControlService(),
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegisterScreen(offerLookup: offerLookup),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(E2EKeys.registerEmail),
        'new@greengo.app',
      );
      await tester.enterText(
        find.byKey(E2EKeys.registerPassword),
        'Str0ng!Pass',
      );
      await tester.enterText(
        find.byKey(E2EKeys.registerConfirmPassword),
        'Str0ng!Pass',
      );
      // Required consents: privacy policy, then terms.
      for (var i = 0; i < 2; i++) {
        final box = find.byType(Checkbox).at(i);
        await tester.ensureVisible(box);
        await tester.tap(box);
        await tester.pump();
      }
      await tester.ensureVisible(find.byKey(E2EKeys.registerSubmit));
      await tester.pump();
    }

    testWidgets('shows immediately on tap, adds the slow line after 5 s, '
        'clears on error', (tester) async {
      // An offer lookup that never answers (cold callable): the tap must not
      // look dead while waiting for it, and signup must go on after the cap.
      await pumpRegister(
        tester,
        offerLookup: (_) => Completer<PreRegistrationOffer?>().future,
      );

      expect(find.byKey(CreatingAccountOverlay.overlayKey), findsNothing);

      await tester.tap(find.byKey(E2EKeys.registerSubmit));
      await tester.pump();

      expect(find.byKey(CreatingAccountOverlay.overlayKey), findsOneWidget);
      expect(find.text(en.signupCreatingAccount), findsOneWidget);
      expect(find.text(en.signupCreatingAccountSlow), findsNothing);

      // Offer lookup is capped; registration is dispatched while the loader
      // stays up.
      await tester.pump(kOfferLookupBudget + const Duration(milliseconds: 10));
      verify(
        () => repo.registerWithEmail(
          email: 'new@greengo.app',
          password: 'Str0ng!Pass',
        ),
      ).called(1);
      expect(find.byKey(CreatingAccountOverlay.overlayKey), findsOneWidget);

      await tester.pump(kCreatingAccountSlowAfter);
      expect(find.text(en.signupCreatingAccountSlow), findsOneWidget);

      // Sign-up answers 12 s after it was dispatched: error -> loader gone.
      await tester.pump(const Duration(seconds: 8));
      await tester.pump();
      expect(find.byKey(CreatingAccountOverlay.overlayKey), findsNothing);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a second tap while creating does not register twice', (
      tester,
    ) async {
      await pumpRegister(tester, offerLookup: (_) async => null);
      await tester.tap(find.byKey(E2EKeys.registerSubmit));
      await tester.pump();
      // The barrier absorbs the second tap.
      await tester.tap(find.byKey(E2EKeys.registerSubmit), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
      verify(
        () => repo.registerWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
      await tester.pump(const Duration(seconds: 13));
      await tester.pump(const Duration(seconds: 10));
    });
  });

  group('Onboarding DOB: age computed from the selected date only', () {
    late MockOnboardingBloc bloc;

    setUp(() {
      bloc = MockOnboardingBloc();
      const state = OnboardingInProgress(
        userId: 'u1',
        currentStep: OnboardingStep.basicInfo,
      );
      when(() => bloc.state).thenReturn(state);
      when(
        () => bloc.stream,
      ).thenAnswer((_) => const Stream<OnboardingState>.empty());
      when(() => bloc.close()).thenAnswer((_) async {});
    });

    DateTime yearsAgo(int years) {
      final n = DateTime.now();
      return DateTime(n.year - years, n.month, n.day);
    }

    testWidgets('picking 17, then 35, continues without a restart', (
      tester,
    ) async {
      final picks = <DateTime>[yearsAgo(17), yearsAgo(35)];
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<OnboardingBloc>.value(
            value: bloc,
            child: Step1BasicInfoScreen(
              pickDate: (_, __) async => picks.removeAt(0),
              ageGate: AgeGateService(
                declare: (d) async {
                  sent.add(d);
                  return {'allowed': true};
                },
                clearLegacyFlag: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Ava');
      await tester.ensureVisible(find.byType(LuxuryChip).first);
      await tester.tap(find.byType(LuxuryChip).first);
      await tester.pump();

      final continueBtn = find.text(en.onboardingContinue);
      final hint = find.byKey(const Key('onboardingAgeUnderMinimumHint'));

      // 1) A 17-year-old date: inline hint, Continue refused, nothing sent.
      await tester.tap(find.byKey(const Key('onboardingDobField')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(hint, findsOneWidget);
      expect(find.text(en.onboardingAgeUnderMinimumHint), findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 600));
      expect(sent, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => bloc.add(any()));

      // 2) Corrected to 35: hint clears and Continue proceeds.
      await tester.tap(find.byKey(const Key('onboardingDobField')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(hint, findsNothing);
      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 600));
      expect(sent, [dobToIso(yearsAgo(35))]);
      expect(find.byType(AlertDialog), findsNothing);
      verify(() => bloc.add(const OnboardingNextStep())).called(1);
    });

    testWidgets('an account the server already blocked shows the dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<OnboardingBloc>.value(
            value: bloc,
            child: Step1BasicInfoScreen(
              pickDate: (_, __) async => yearsAgo(35),
              ageGate: AgeGateService(
                declare: (_) async => {
                  'allowed': false,
                  'reason': 'AGE_BLOCKED',
                },
                clearLegacyFlag: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, 'Ava');
      await tester.ensureVisible(find.byType(LuxuryChip).first);
      await tester.tap(find.byType(LuxuryChip).first);
      await tester.tap(find.byKey(const Key('onboardingDobField')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text(en.onboardingContinue));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(en.onboardingAgePreviouslyBlockedBody), findsOneWidget);
      verifyNever(() => bloc.add(const OnboardingNextStep()));
    });
  });
}
