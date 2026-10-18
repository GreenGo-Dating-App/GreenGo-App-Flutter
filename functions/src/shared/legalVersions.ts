/**
 * Versions of the legal texts, server side.
 *
 * MUST equal the app's lib/core/constants/legal_versions.dart
 * (kTermsVersion). Bump both together when the Terms change;
 * __tests__/unit/legalVersions.test.ts fails while they differ.
 */

/** Terms and Conditions version currently published (Terms 16.9 d proof). */
export const TERMS_VERSION = '5.3.2';

/**
 * Owner decision of 16 October 2026: TERMS_VERSION (5.3.0) applies from
 * 16 Oct 2026 to accounts created on or after that day; accounts created
 * before stay on PREVIOUS_TERMS_VERSION until 15 Nov 2026 and move to
 * TERMS_VERSION on 16 Nov 2026 (30-day notice, Terms 24.2).
 * 5.3.1 (same day, same dates): fee caps per ticket raised in 11.6 b
 * (Silver US$30, Gold US$28, Platinum US$25); replaces 5.3.0.
 * 5.3.2 (17 Oct 2026, accounts created from 16 Oct 2026; older accounts
 * still move on 16 Nov 2026): clarifications + ticket price phases.
 */
export const PREVIOUS_TERMS_VERSION = '5.2.1';
export const TERMS_NEW_ACCOUNTS_FROM_MS = Date.parse('2026-10-16T00:00:00Z');
export const TERMS_ALL_ACCOUNTS_FROM_MS = Date.parse('2026-11-16T00:00:00Z');

/**
 * The Terms version that applies at [nowMs] to an account created at
 * [createdMs] (Firebase Auth creation time). Unknown creation time: the
 * current version.
 */
export function termsVersionForAccount(createdMs: number | null | undefined, nowMs: number): string {
  if (nowMs >= TERMS_ALL_ACCOUNTS_FROM_MS) return TERMS_VERSION;
  if (createdMs == null || !Number.isFinite(createdMs)) return TERMS_VERSION;
  return createdMs < TERMS_NEW_ACCOUNTS_FROM_MS ? PREVIOUS_TERMS_VERSION : TERMS_VERSION;
}
