/// Countries where GreenGo sends phone-verification SMS (owner rule
/// 2026-10-17): every European country except Russia and Belarus, plus
/// Brazil, the United States and Canada.
///
/// SINGLE SOURCE for the app. The server mirror is
/// functions/src/shared/phoneCountries.ts and the two lists are kept identical
/// by test/unit/safety/phone_countries_sync_test.dart. The Identity Platform
/// "SMS region policy" (Firebase console) must allow exactly these regions -
/// see docs/safety/phone-verification.md.
library;

/// One supported country: ISO 3166-1 alpha-2 code and its E.164 calling code
/// (with the leading '+').
class PhoneCountry {
  const PhoneCountry(this.isoCode, this.dialCode);
  final String isoCode;
  final String dialCode;
}

/// Supported countries, alphabetical by ISO code.
///
/// Notes: VA (Vatican City) numbers use the Italian plan (+39 06 698...);
/// IM / JE / GG use +44, AX uses +358. US and CA share +1 - other +1
/// (NANP) territories are rejected by [kNanpExcludedAreaCodes].
const List<PhoneCountry> kPhoneVerificationCountries = [
  PhoneCountry('AD', '+376'),
  PhoneCountry('AL', '+355'),
  PhoneCountry('AT', '+43'),
  PhoneCountry('AX', '+358'),
  PhoneCountry('BA', '+387'),
  PhoneCountry('BE', '+32'),
  PhoneCountry('BG', '+359'),
  PhoneCountry('BR', '+55'),
  PhoneCountry('CA', '+1'),
  PhoneCountry('CH', '+41'),
  PhoneCountry('CY', '+357'),
  PhoneCountry('CZ', '+420'),
  PhoneCountry('DE', '+49'),
  PhoneCountry('DK', '+45'),
  PhoneCountry('EE', '+372'),
  PhoneCountry('ES', '+34'),
  PhoneCountry('FI', '+358'),
  PhoneCountry('FO', '+298'),
  PhoneCountry('FR', '+33'),
  PhoneCountry('GB', '+44'),
  PhoneCountry('GG', '+44'),
  PhoneCountry('GI', '+350'),
  PhoneCountry('GR', '+30'),
  PhoneCountry('HR', '+385'),
  PhoneCountry('HU', '+36'),
  PhoneCountry('IE', '+353'),
  PhoneCountry('IM', '+44'),
  PhoneCountry('IS', '+354'),
  PhoneCountry('IT', '+39'),
  PhoneCountry('JE', '+44'),
  PhoneCountry('LI', '+423'),
  PhoneCountry('LT', '+370'),
  PhoneCountry('LU', '+352'),
  PhoneCountry('LV', '+371'),
  PhoneCountry('MC', '+377'),
  PhoneCountry('MD', '+373'),
  PhoneCountry('ME', '+382'),
  PhoneCountry('MK', '+389'),
  PhoneCountry('MT', '+356'),
  PhoneCountry('NL', '+31'),
  PhoneCountry('NO', '+47'),
  PhoneCountry('PL', '+48'),
  PhoneCountry('PT', '+351'),
  PhoneCountry('RO', '+40'),
  PhoneCountry('RS', '+381'),
  PhoneCountry('SE', '+46'),
  PhoneCountry('SI', '+386'),
  PhoneCountry('SK', '+421'),
  PhoneCountry('SM', '+378'),
  PhoneCountry('UA', '+380'),
  PhoneCountry('US', '+1'),
  PhoneCountry('VA', '+39'),
  PhoneCountry('XK', '+383'),
];

/// +1 area codes that are NOT the United States or Canada (Caribbean NANP
/// countries and US territories with their own SMS region). Numbers in these
/// area codes are refused.
const Set<String> kNanpExcludedAreaCodes = {
  '242', '246', '264', '268', '284', '340', '345', '441', '473', '649',
  '658', '664', '670', '671', '684', '721', '758', '767', '784', '787',
  '809', '829', '849', '868', '869', '876', '939',
};

/// Support contact shown to people whose country is not supported.
const String kPhoneVerificationSupportEmail = 'support@greengochat.com';

/// True when [isoCode] is a supported SMS country.
bool isPhoneCountrySupported(String? isoCode) {
  if (isoCode == null) return false;
  final c = isoCode.trim().toUpperCase();
  return kPhoneVerificationCountries.any((p) => p.isoCode == c);
}

/// The supported entry for [isoCode], or null.
PhoneCountry? phoneCountryFor(String? isoCode) {
  if (isoCode == null) return null;
  final c = isoCode.trim().toUpperCase();
  for (final p in kPhoneVerificationCountries) {
    if (p.isoCode == c) return p;
  }
  return null;
}

/// Builds an E.164 number from a dial code and what the user typed
/// (spaces, dashes, dots, brackets and a national trunk '0' removed - except
/// for Italy / San Marino / Vatican, where the leading 0 of a landline is
/// part of the number). Returns null when the result is not plausible E.164.
String? toE164(String dialCode, String typed) {
  var digits = typed.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  if (digits.startsWith('+')) {
    final full = '+${digits.substring(1).replaceAll(RegExp(r'\D'), '')}';
    return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(full) ? full : null;
  }
  if (digits.startsWith('00')) {
    final full = '+${digits.substring(2).replaceAll(RegExp(r'\D'), '')}';
    return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(full) ? full : null;
  }
  digits = digits.replaceAll(RegExp(r'\D'), '');
  const keepsZero = {'+39', '+378'};
  if (!keepsZero.contains(dialCode)) {
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
  }
  final full = '$dialCode$digits';
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(full) ? full : null;
}

/// True when the E.164 [phone] belongs to a supported country (by calling
/// code; +1 must not be an excluded NANP area code). Same logic as
/// isPhoneNumberSupported() in functions/src/shared/phoneCountries.ts.
bool isPhoneNumberSupported(String? phone) {
  if (phone == null || !RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone)) {
    return false;
  }
  if (phone.startsWith('+1')) {
    if (phone.length != 12) return false;
    return !kNanpExcludedAreaCodes.contains(phone.substring(2, 5));
  }
  if (phone.startsWith('+7') || phone.startsWith('+375')) return false;
  final codes = kPhoneVerificationCountries.map((c) => c.dialCode).toSet()
    ..remove('+1');
  return codes.any(phone.startsWith);
}

/// Who must verify (owner decision 2026-10-17, final): ONLY accounts created
/// on/after [kPhoneRequiredForAccountsCreatedFrom] (00:00 UTC). Older
/// accounts are never required nor blocked; they may add a phone optionally.
/// Server mirror: PHONE_REQUIRED_FOR_ACCOUNTS_CREATED_FROM in
/// functions/src/shared/participation.ts (+ the server-only
/// phone_required/{uid} marker the rules read) - phone_countries_sync_test.
final DateTime kPhoneRequiredForAccountsCreatedFrom = DateTime.utc(2026, 10, 16);

/// True when an account created at [createdAt] must have a verified phone
/// (unknown creation time: not required - the server decides).
bool phoneRequiredFor(DateTime? createdAt) =>
    createdAt != null &&
    !createdAt.toUtc().isBefore(kPhoneRequiredForAccountsCreatedFrom);
