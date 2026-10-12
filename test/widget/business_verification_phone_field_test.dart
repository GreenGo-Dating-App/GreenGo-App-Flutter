import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/theme/app_theme.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_verification_request_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../support/profile_fixtures.dart';

/// The app theme gives buttons `minimumSize: Size(double.infinity, ...)`.
/// Next to the phone field (in a Row) that squeezed the field to almost no
/// width; the "Send code" button must keep its own size.
void main() {
  testWidgets('phone field keeps a usable width on a phone screen',
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
    final field = find.byKey(const ValueKey('verify_field_phone'));
    expect(field, findsOneWidget);
    expect(tester.getSize(field).width, greaterThan(180));
    expect(find.text('Send code'), findsOneWidget);
  });
}
