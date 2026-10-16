/**
 * The server records the Terms version with legal acknowledgements (Terms
 * 16.9 d). It must be the version the app shows: fail as soon as the server
 * constant and the app's kTermsVersion differ.
 */
import * as fs from 'fs';
import * as path from 'path';
import { TERMS_VERSION } from '../../src/shared/legalVersions';
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

  test('the check can fail (parser reads a real version)', () => {
    expect(appTermsVersion()).toMatch(/^\d+\.\d+\.\d+$/);
    expect('0.0.0').not.toBe(appTermsVersion());
  });
});
