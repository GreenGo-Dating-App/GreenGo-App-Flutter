import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/safety/data/services/identity_details_service.dart';
import 'package:greengo_chat/features/safety/presentation/widgets/identity_details_form.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';

/// Optional ID-document details (identity-records.md): manual entry, all six
/// fields required once the user opts in, document-number format checked.
void main() {
  final en = AppLocalizationsEn();

  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('empty form shows required errors and does not submit',
      (tester) async {
    var submitted = 0;
    await tester.pumpWidget(host(IdentityDetailsForm(
      submitLabel: 'Save',
      onSubmit: (_) async => submitted++,
    )));
    await tester.tap(find.byKey(const Key('identity_submit')));
    await tester.pumpAndSettle();
    expect(submitted, 0);
    expect(find.text(en.identityFieldRequired), findsWidgets);
  });

  testWidgets('pre-filled details submit normalized values', (tester) async {
    IdentityDetails? got;
    await tester.pumpWidget(host(IdentityDetailsForm(
      submitLabel: 'Save',
      initial: IdentityDetails(
        firstName: 'Maria',
        surname: 'Silva',
        dateOfBirth: DateTime(1990, 5, 17),
        docType: 'passport',
        issuingCountry: 'br',
        docNumber: 'ab123456',
      ),
      onSubmit: (d) async => got = d,
    )));
    await tester.tap(find.byKey(const Key('identity_submit')));
    await tester.pumpAndSettle();
    expect(got, isNotNull);
    expect(got!.toMap(), {
      'firstName': 'Maria',
      'surname': 'Silva',
      'dateOfBirth': '1990-05-17',
      'docType': 'passport',
      'issuingCountry': 'BR',
      'docNumber': 'AB123456',
    });
  });

  testWidgets('an invalid document number is refused', (tester) async {
    var submitted = 0;
    await tester.pumpWidget(host(IdentityDetailsForm(
      submitLabel: 'Save',
      initial: IdentityDetails(
        firstName: 'Maria',
        surname: 'Silva',
        dateOfBirth: DateTime(1990, 5, 17),
        docType: 'id_card',
        issuingCountry: 'PT',
        docNumber: 'x',
      ),
      onSubmit: (_) async => submitted++,
    )));
    await tester.tap(find.byKey(const Key('identity_submit')));
    await tester.pumpAndSettle();
    expect(submitted, 0);
    expect(find.text(en.identityDocNumberInvalid), findsOneWidget);
  });

  test('doc types match the server list', () {
    expect(kIdentityDocTypes,
        ['passport', 'id_card', 'driving_licence', 'residence_permit', 'other']);
  });
}
