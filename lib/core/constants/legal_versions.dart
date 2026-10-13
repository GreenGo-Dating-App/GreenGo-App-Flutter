/// Versions of the legal documents bundled in `assets/legal/*.txt` (copied
/// byte-for-byte from the published greengo-terms-and-conditions and
/// greengo-privacy-policy repos). Update these together with the texts.
///
/// They are stored with every acceptance record (`consents/{uid}.terms` /
/// `.privacy`, field `docVersion`, written server-side by `recordConsent`).
library;

/// Terms and Conditions version shown in-app and recorded at acceptance.
const String kTermsVersion = '5.1.2';

/// Privacy Policy version shown in-app and recorded at acceptance.
const String kPrivacyPolicyVersion = '5.1.0';

/// Effective date of [kPrivacyPolicyVersion] (and of the Terms up to 5.1.0).
final DateTime kLegalEffectiveDate = DateTime(2026, 10, 11);

/// Effective date of [kTermsVersion] (5.1.1: section 9.2 - fixed price
/// points per currency; 5.1.2: the 9.2 example uses the current Base price.
/// Both are clarifications; no re-acceptance).
final DateTime kTermsEffectiveDate = DateTime(2026, 10, 13);

/// Oldest accepted version that does NOT trigger the "we've updated our
/// Terms" sheet. Raise it only for a MATERIAL change (5.1.0: new Terms 16.9
/// and the private-content warning); a typo-fix release keeps it.
const String kTermsReacceptFrom = '5.1.0';

/// Same as [kTermsReacceptFrom], for the Privacy Policy.
const String kPrivacyReacceptFrom = '5.1.0';

final RegExp _semver = RegExp(r'^\d{1,3}(\.\d{1,3}){0,2}$');

/// True when [accepted] is a dotted version (e.g. "5.1.0") at least [min].
/// Anything else - null, empty, the old date labels such as "2026-09-15", or
/// "1.0" - counts as older, so the user is asked to accept the current texts.
bool isLegalVersionAtLeast(String? accepted, String min) {
  final a = accepted?.trim() ?? '';
  if (!_semver.hasMatch(a)) return false;
  List<int> parts(String v) {
    final p = v.split('.').map(int.parse).toList();
    while (p.length < 3) {
      p.add(0);
    }
    return p;
  }

  final x = parts(a);
  final y = parts(min);
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i] > y[i];
  }
  return true;
}
