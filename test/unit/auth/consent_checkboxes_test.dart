import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/authentication/presentation/widgets/consent_checkboxes.dart';

/// Master Test Plan — A. Authentication & Session (registration consents / GDPR).
/// Guards the gate that blocks account creation until the two REQUIRED consents
/// (privacy policy + terms) are actively accepted. Profiling and third-party
/// consents are optional (pre-checked in the form) and never gate registration.
void main() {
  group('ConsentCheckboxes.areRequiredConsentsAccepted', () {
    test('true only when BOTH privacy and terms are accepted', () {
      expect(
        ConsentCheckboxes.areRequiredConsentsAccepted(
          privacyPolicy: true,
          terms: true,
        ),
        isTrue,
      );
    });

    test('false when privacy policy is not accepted', () {
      expect(
        ConsentCheckboxes.areRequiredConsentsAccepted(
          privacyPolicy: false,
          terms: true,
        ),
        isFalse,
      );
    });

    test('false when terms are not accepted', () {
      expect(
        ConsentCheckboxes.areRequiredConsentsAccepted(
          privacyPolicy: true,
          terms: false,
        ),
        isFalse,
      );
    });

    test('false when neither required consent is accepted', () {
      expect(
        ConsentCheckboxes.areRequiredConsentsAccepted(
          privacyPolicy: false,
          terms: false,
        ),
        isFalse,
      );
    });

    test('gate is independent of the optional consents', () {
      // Optional consents (profiling / third-party) are not arguments here —
      // the required-consent gate depends solely on privacy + terms. Verifying
      // the truth table is stable regardless of any optional selection.
      expect(
        ConsentCheckboxes.areRequiredConsentsAccepted(
              privacyPolicy: true,
              terms: true,
            ) &&
            !ConsentCheckboxes.areRequiredConsentsAccepted(
              privacyPolicy: true,
              terms: false,
            ),
        isTrue,
      );
    });
  });
}
