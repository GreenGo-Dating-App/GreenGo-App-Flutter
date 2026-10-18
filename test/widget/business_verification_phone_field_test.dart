import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/theme/app_theme.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_verification_request_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../support/profile_fixtures.dart';

/// Owner decision 2026-10-17: the business verification request needs ONLY
/// the account's verified phone (no separate OTP field, no mandatory ID
/// document). Without a verified phone the screen asks to verify it first.
void main() {
  testWidgets('asks for the account phone; owner ID is optional',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BusinessVerificationRequestScreen(profile: buildProfile()),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('verify_field_phone')), findsNothing);
    expect(find.byKey(const ValueKey('business-verify-phone-needed')), findsOneWidget);
    expect(find.text('Owner ID document (optional)', findRichText: true), findsOneWidget);
  });
}
