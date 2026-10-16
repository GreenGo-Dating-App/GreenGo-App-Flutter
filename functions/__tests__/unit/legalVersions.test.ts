/**
 * The server records the Terms version with legal acknowledgements (Terms
 * 16.9 d). It must be the version the app shows: fail as soon as the server
 * constant and the app's kTermsVersion differ.
 */
import * as fs from 'fs';
import * as path from 'path';
import {
  PREVIOUS_TERMS_VERSION, TERMS_VERSION, termsVersionForAccount,
} from '../../src/shared/legalVersions';
import { TERMS_VERSION as PCW_TERMS_VERSION } from '../../src/legal/privateContentWarning';

const DART = path.resolve(__dirname, '../../../lib/core/constants/legal_versions.dart');

function appTermsVersion(): string {
  const src = fs.readFileSync(DART, 'utf8');
  const m = src.match(/const\s+String\s+kTermsVersion\s*=\s*'([^']+)'/);
  if (!m) throw new Error(`kTermsVersion not found in ${DART}`);
  return m[1];
}

describe('legal versions', () => {
  test('server TERMS_VERSION equals the app kTermsVersion', () => {
    expect(TERMS_VERSION).toBe(appTermsVersion());
  });

  test('the private-content warning records the shared constant', () => {
    expect(PCW_TERMS_VERSION).toBe(TERMS_VERSION);
  });

  test('5.3.1 for accounts created from 16 Oct 2026; 5.2.1 for older ones until 15 Nov 2026', () => {
    expect(TERMS_VERSION).toBe('5.3.1');
    expect(PREVIOUS_TERMS_VERSION).toBe('5.2.1');
    const t = (iso: string) => Date.parse(iso);
    const now = t('2026-10-20T10:00:00Z');
    expect(termsVersionForAccount(t('2026-10-16T00:00:00Z'), now)).toBe('5.3.1');
    expect(termsVersionForAccount(t('2026-10-15T23:59:59Z'), now)).toBe('5.2.1');
    expect(termsVersionForAccount(t('2025-01-01T00:00:00Z'), t('2026-11-15T23:59:59Z'))).toBe('5.2.1');
    expect(termsVersionForAccount(t('2025-01-01T00:00:00Z'), t('2026-11-16T00:00:00Z'))).toBe('5.3.1');
    expect(termsVersionForAccount(null, now)).toBe('5.3.1');
    expect(termsVersionForAccount(Number.NaN, now)).toBe('5.3.1');
  });

  test('the check can fail (parser reads a real version)', () => {
    expect(appTermsVersion()).toMatch(/^\d+\.\d+\.\d+$/);
    expect('0.0.0').not.toBe(appTermsVersion());
  });
});
