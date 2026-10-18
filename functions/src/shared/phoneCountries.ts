/**
 * Countries where GreenGo sends phone-verification SMS (owner rule
 * 2026-10-17): every European country except Russia and Belarus, plus
 * Brazil, the United States and Canada.
 *
 * Server mirror of lib/core/constants/phone_verification_countries.dart -
 * the two lists are kept identical by
 * test/unit/safety/phone_countries_sync_test.dart (it parses this file).
 * The Identity Platform SMS region policy must allow exactly these regions
 * (docs/safety/phone-verification.md).
 */

/** [ISO 3166-1 alpha-2, E.164 calling code] - alphabetical by ISO code. */
export const PHONE_VERIFICATION_COUNTRIES: ReadonlyArray<readonly [string, string]> = [
  ['AD', '+376'],
  ['AL', '+355'],
  ['AT', '+43'],
  ['AX', '+358'],
  ['BA', '+387'],
  ['BE', '+32'],
  ['BG', '+359'],
  ['BR', '+55'],
  ['CA', '+1'],
  ['CH', '+41'],
  ['CY', '+357'],
  ['CZ', '+420'],
  ['DE', '+49'],
  ['DK', '+45'],
  ['EE', '+372'],
  ['ES', '+34'],
  ['FI', '+358'],
  ['FO', '+298'],
  ['FR', '+33'],
  ['GB', '+44'],
  ['GG', '+44'],
  ['GI', '+350'],
  ['GR', '+30'],
  ['HR', '+385'],
  ['HU', '+36'],
  ['IE', '+353'],
  ['IM', '+44'],
  ['IS', '+354'],
  ['IT', '+39'],
  ['JE', '+44'],
  ['LI', '+423'],
  ['LT', '+370'],
  ['LU', '+352'],
  ['LV', '+371'],
  ['MC', '+377'],
  ['MD', '+373'],
  ['ME', '+382'],
  ['MK', '+389'],
  ['MT', '+356'],
  ['NL', '+31'],
  ['NO', '+47'],
  ['PL', '+48'],
  ['PT', '+351'],
  ['RO', '+40'],
  ['RS', '+381'],
  ['SE', '+46'],
  ['SI', '+386'],
  ['SK', '+421'],
  ['SM', '+378'],
  ['UA', '+380'],
  ['US', '+1'],
  ['VA', '+39'],
  ['XK', '+383'],
];

/** +1 area codes that are NOT the United States or Canada. */
export const NANP_EXCLUDED_AREA_CODES: ReadonlySet<string> = new Set([
  '242', '246', '264', '268', '284', '340', '345', '441', '473', '649',
  '658', '664', '670', '671', '684', '721', '758', '767', '784', '787',
  '809', '829', '849', '868', '869', '876', '939',
]);

const E164 = /^\+[1-9]\d{6,14}$/;

/** True when `phone` is syntactically E.164. */
export function isE164(phone: unknown): phone is string {
  return typeof phone === 'string' && E164.test(phone);
}

/** True when the E.164 `phone` belongs to a supported SMS country. */
export function isPhoneNumberSupported(phone: unknown): boolean {
  if (!isE164(phone)) return false;
  if (phone.startsWith('+1')) {
    if (phone.length !== 12) return false;
    return !NANP_EXCLUDED_AREA_CODES.has(phone.substring(2, 5));
  }
  if (phone.startsWith('+7') || phone.startsWith('+375')) return false;
  const codes = new Set(PHONE_VERIFICATION_COUNTRIES.map(([, d]) => d));
  codes.delete('+1');
  for (const c of codes) if (phone.startsWith(c)) return true;
  return false;
}
