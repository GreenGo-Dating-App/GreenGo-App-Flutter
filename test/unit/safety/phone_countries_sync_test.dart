import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/phone_verification_countries.dart';

/// The SMS country allowlist exists twice (app + functions). This keeps them
/// identical and pins the owner rule (Europe minus RU/BY, plus BR/US/CA).
void main() {
  final tsSource =
      File('functions/src/shared/phoneCountries.ts').readAsStringSync();

  test('dart and ts country lists are identical', () {
    final ts = RegExp(r"\['([A-Z]{2})', '(\+\d+)'\]")
        .allMatches(tsSource)
        .map((m) => '${m.group(1)}${m.group(2)}')
        .toList();
    final dart = kPhoneVerificationCountries
        .map((c) => '${c.isoCode}${c.dialCode}')
        .toList();
    expect(ts, dart);
  });

  test('dart and ts NANP exclusions are identical', () {
    final block = RegExp(r'NANP_EXCLUDED_AREA_CODES[^\[]*\[([^\]]*)\]')
        .firstMatch(tsSource)!
        .group(1)!;
    final ts = RegExp(r"'(\d{3})'").allMatches(block).map((m) => m.group(1)).toSet();
    expect(ts, kNanpExcludedAreaCodes);
  });

  test('allowlist content follows the owner rule', () {
    const eu27 = [
      'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
      'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK',
      'SI', 'ES', 'SE',
    ];
    const rest = [
      'NO', 'IS', 'LI', 'CH', 'GB', 'AL', 'AD', 'BA', 'XK', 'ME', 'MK', 'MD',
      'MC', 'RS', 'SM', 'UA', 'VA', 'GI', 'FO', 'IM', 'JE', 'GG', 'AX', 'BR',
      'US', 'CA',
    ];
    final codes = kPhoneVerificationCountries.map((c) => c.isoCode).toSet();
    expect(codes, {...eu27, ...rest});
    expect(codes.length, 53);
    expect(isPhoneCountrySupported('RU'), isFalse);
    expect(isPhoneCountrySupported('BY'), isFalse);
    expect(isPhoneCountrySupported('IN'), isFalse);
    expect(isPhoneCountrySupported('pt'), isTrue);
  });

  test('number check by calling code', () {
    expect(isPhoneNumberSupported('+351912345678'), isTrue); // PT
    expect(isPhoneNumberSupported('+5511987654321'), isTrue); // BR
    expect(isPhoneNumberSupported('+14155550123'), isTrue); // US
    expect(isPhoneNumberSupported('+16135550123'), isTrue); // CA
    expect(isPhoneNumberSupported('+18765550123'), isFalse); // Jamaica
    expect(isPhoneNumberSupported('+17875550123'), isFalse); // Puerto Rico
    expect(isPhoneNumberSupported('+79161234567'), isFalse); // RU
    expect(isPhoneNumberSupported('+375291234567'), isFalse); // BY
    expect(isPhoneNumberSupported('+919876543210'), isFalse); // IN
    expect(isPhoneNumberSupported('+447700900123'), isTrue); // UK
    expect(isPhoneNumberSupported('351912345678'), isFalse); // no +
    expect(isPhoneNumberSupported(null), isFalse);
  });

  test('cutoff matches the server; rules read the new-account marker', () {
    final ts = File('functions/src/shared/participation.ts').readAsStringSync();
    expect(ts, contains("PHONE_REQUIRED_FOR_ACCOUNTS_CREATED_FROM = '2026-10-16T00:00:00Z'"));
    expect(ts, isNot(contains('PHONE_REQUIRED_FOR_ALL_FROM')));
    expect(kPhoneRequiredForAccountsCreatedFrom, DateTime.utc(2026, 10, 16));
    for (final f in ['firestore.rules', 'firestore.additive.rules']) {
      final rules = File(f).readAsStringSync();
      expect(rules, contains('documents/phone_required/\$(request.auth.uid)'), reason: f);
      expect(rules, isNot(contains('timestamp.date(2026, 11, 16)')), reason: f);
    }
  });

  test('phoneRequiredFor: only accounts created on/after 16 Oct 2026', () {
    expect(phoneRequiredFor(DateTime.utc(2026, 9, 1)), isFalse);
    expect(phoneRequiredFor(DateTime.utc(2026, 10, 15, 23, 59)), isFalse);
    expect(phoneRequiredFor(DateTime.utc(2026, 10, 16)), isTrue);
    expect(phoneRequiredFor(DateTime.utc(2027, 1, 1)), isTrue);
    expect(phoneRequiredFor(null), isFalse);
  });

  test('toE164 normalizes typed numbers', () {
    expect(toE164('+351', '912 345 678'), '+351912345678');
    expect(toE164('+44', '07700 900123'), '+447700900123');
    expect(toE164('+39', '06 6982 1234'), '+390669821234');
    expect(toE164('+1', '(415) 555-0123'), '+14155550123');
    expect(toE164('+351', '+55 11 98765-4321'), '+5511987654321');
    expect(toE164('+351', '0055 11 98765 4321'), '+5511987654321');
    expect(toE164('+351', '12'), isNull);
  });
}
