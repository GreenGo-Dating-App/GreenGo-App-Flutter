/**
 * Log / prompt redaction helpers (security Phase 1: L-07, H-04).
 *
 * redact()     - for LOG LINES: emails -> `a***@domain`, tokens -> first 4 chars.
 * scrubPII()   - for text SENT TO A THIRD-PARTY MODEL: removes emails, phone
 *                numbers, coordinates and dates (DOB) entirely.
 *
 * Both are pure, never throw, and pass non-strings through unchanged.
 */

const EMAIL = /([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+\.[A-Za-z]{2,})/g;

/** `alice@example.com` -> `a***@example.com`. Non-email strings are returned unchanged. */
export function redactEmail(value: unknown): string {
  if (typeof value !== 'string') return String(value ?? '');
  return value.replace(EMAIL, (_m, first: string, domain: string) => `${first}***@${domain}`);
}

/** Secret / token -> first 4 chars + `…` (never the full value). */
export function redactToken(value: unknown): string {
  if (typeof value !== 'string' || !value) return '';
  return value.length <= 4 ? '****' : `${value.slice(0, 4)}…`;
}

/**
 * Generic log redaction: masks any email addresses inside `value`. Use
 * redactToken() for values known to be secrets.
 */
export function redact(value: unknown): string {
  return redactEmail(value);
}

const PII_PATTERNS: Array<[RegExp, string]> = [
  [EMAIL, '[email]'],
  // lat,lng pairs with >= 3 decimals (exact location)
  [/-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}/g, '[location]'],
  // dates such as 1990-04-21, 21/04/1990, 21.04.90 (date of birth)
  [/\b\d{1,4}[/.-]\d{1,2}[/.-]\d{1,4}\b/g, '[date]'],
  // phone numbers: 7+ digits with optional +, spaces, dots, dashes, parens
  [/\+?\d[\d\s().-]{5,}\d/g, '[phone]'],
];

/** Remove contact details / exact location / dates from free text. */
export function scrubPII(value: unknown): string {
  if (typeof value !== 'string') return '';
  let out = value;
  for (const [re, repl] of PII_PATTERNS) out = out.replace(re, repl);
  return out;
}
