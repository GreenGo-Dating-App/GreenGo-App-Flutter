import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/own_profile_store.dart';
import 'package:greengo_chat/core/services/phone_verification_service.dart';
import 'package:greengo_chat/core/utils/base_membership_gate.dart';
import 'package:greengo_chat/core/utils/phone_verification_gate.dart';
import 'package:greengo_chat/core/widgets/add_phone_banner.dart';
import 'package:greengo_chat/core/widgets/phone_verification_panel.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner rule 2026-10-17 (final): verified phone required for join / book /
/// tickets / host / business ONLY for accounts created on/after 16 Oct 2026;
/// older accounts are never asked or blocked (optional profile banner).
class _FakeService extends PhoneVerificationService {
  _FakeService({this.allowed});
  final String? allowed;
  int checks = 0;
  @override
  String? get currentPhone => null;
  @override
  Future<String?> checkAllowed(String e164) async {
    checks++;
    return allowed;
  }

  @override
  Future<void> sendCode(String e164,
      {required VoidCallback onCodeSent,
      required VoidCallback onAutoVerified,
      required void Function(String code) onError}) async {
    onCodeSent();
  }
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  late int sheets;
  late bool sheetResult;

  setUp(() {
    sheets = 0;
    sheetResult = false;
    PhoneVerificationGate.debugShowSheet = (_) async {
      sheets++;
      return sheetResult;
    };
    PhoneVerificationService.debugHasPhone = () => false;
    PhoneVerificationService.debugCreatedAt = () => DateTime.utc(2026, 10, 17);
    OwnProfileStore.instance.reset();
  });

  tearDown(() {
    PhoneVerificationGate.debugShowSheet = null;
    PhoneVerificationService.debugHasPhone = null;
    PhoneVerificationService.debugCreatedAt = null;
    OwnProfileStore.instance.reset();
  });

  Future<BuildContext> pumpCtx(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_app(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    return ctx;
  }

  testWidgets('verified phone passes without a sheet', (tester) async {
    PhoneVerificationService.debugHasPhone = () => true;
    final ctx = await pumpCtx(tester);
    expect(await PhoneVerificationGate.ensureVerified(ctx), isTrue);
    expect(sheets, 0);
  });

  testWidgets('new account without phone: blocked unless verified in sheet',
      (tester) async {
    final ctx = await pumpCtx(tester);
    expect(await PhoneVerificationGate.ensureVerified(ctx), isFalse);
    expect(sheets, 1);
    sheetResult = true;
    expect(await PhoneVerificationGate.ensureVerified(ctx), isTrue);
  });

  testWidgets('old account (created before 16 Oct 2026): never asked, never blocked',
      (tester) async {
    PhoneVerificationService.debugCreatedAt = () => DateTime.utc(2026, 5, 1);
    final ctx = await pumpCtx(tester);
    expect(await PhoneVerificationGate.ensureVerified(ctx), isTrue);
    expect(sheets, 0);
  });

  testWidgets('join / book (ensureCanParticipate) and host (ensureCanCreate) are gated',
      (tester) async {
    final ctx = await pumpCtx(tester);
    expect(await BaseMembershipGate.ensureCanParticipate(context: ctx, userId: 'u1'), isFalse);
    expect(await BaseMembershipGate.ensureCanCreate(context: ctx, userId: 'u1'), isFalse);
    expect(sheets, 2);
  });

  testWidgets('server refusal phone_verification_required opens the sheet',
      (tester) async {
    final ctx = await pumpCtx(tester);
    final handled = await BaseMembershipGate.handleParticipationError(ctx,
        userId: 'u1', reason: kPhoneVerificationRequiredCode);
    expect(handled, isTrue);
    expect(sheets, 1);
    expect(await PhoneVerificationGate.handleError(ctx, error: 'x phone_verification_required'), isTrue);
    expect(await PhoneVerificationGate.handleError(ctx, error: 'other'), isFalse);
  });

  testWidgets('profile banner shows without phone and can be dismissed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app(const AddPhoneBanner(userId: 'u1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-phone-banner')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-phone-banner-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-phone-banner')), findsNothing);
  });

  testWidgets('old account banner is optional', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PhoneVerificationService.debugCreatedAt = () => DateTime.utc(2026, 5, 1);
    await tester.pumpWidget(_app(const AddPhoneBanner(userId: 'u2')));
    await tester.pumpAndSettle();
    expect(find.text('Add your phone number (optional)'), findsOneWidget);
    expect(find.text('It helps keep your account safe. Your number stays private.'), findsOneWidget);
  });

  testWidgets('banner hidden with a verified phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PhoneVerificationService.debugHasPhone = () => true;
    await tester.pumpWidget(_app(const AddPhoneBanner(userId: 'u1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-phone-banner')), findsNothing);
  });

  testWidgets('panel: unsupported home country notice, invalid number, server refusal',
      (tester) async {
    final svc = _FakeService(allowed: PhoneVerificationError.alreadyUsed);
    await tester.pumpWidget(_app(SingleChildScrollView(
      child: PhoneVerificationPanel(
          service: svc, initialCountry: 'IN', onVerified: (_) {}),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phone-verify-unsupported-home')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('phone-verify-number')), '12');
    await tester.tap(find.byKey(const ValueKey('phone-verify-send')));
    await tester.pumpAndSettle();
    expect(find.text(AppLocalizationsEn().phoneVerifyInvalidNumber), findsOneWidget);
    expect(svc.checks, 0);

    await tester.enterText(find.byKey(const ValueKey('phone-verify-number')), '4155550123');
    await tester.tap(find.byKey(const ValueKey('phone-verify-send')));
    await tester.pumpAndSettle();
    expect(svc.checks, 1);
    expect(find.text('This number is already used by another account.'), findsOneWidget);
  });

  testWidgets('panel: allowed number moves to the code step', (tester) async {
    final svc = _FakeService();
    await tester.pumpWidget(_app(SingleChildScrollView(
      child: PhoneVerificationPanel(
          service: svc, initialCountry: 'PT', onVerified: (_) {}),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phone-verify-unsupported-home')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('phone-verify-number')), '912 345 678');
    await tester.tap(find.byKey(const ValueKey('phone-verify-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phone-verify-code')), findsOneWidget);
    expect(find.textContaining('+351912345678'), findsOneWidget);
  });

  test('error text mapping', () {
    final l = AppLocalizationsEn();
    expect(PhoneVerificationError.fromAuthCode('credential-already-in-use'),
        PhoneVerificationError.alreadyUsed);
    expect(phoneVerificationErrorText(l, PhoneVerificationError.alreadyUsed),
        'This number is already used by another account.');
    expect(phoneVerificationErrorText(l, PhoneVerificationError.unsupportedCountry),
        contains('not yet available in your country'));
    expect(PhoneVerificationError.fromServerReason('phone_banned'), PhoneVerificationError.banned);
    expect(PhoneVerificationError.fromAuthCode('invalid-verification-code'),
        PhoneVerificationError.invalidCode);
  });
}
