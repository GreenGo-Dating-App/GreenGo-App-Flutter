/**
 * Terms 19.2 / 17.1 b compliance helpers (pure functions, no emulator):
 *   - a confirmed CSAE case always closes the account (19.2 a);
 *   - report packages offer an EU channel next to NCMEC and Brazil (19.2 b);
 *   - upload hash screening covers chat / group / private-album images only
 *     behind the counsel flag (17.1 b, audit EU-19).
 */
import { effectiveSanction, SANCTIONS } from '../../src/safety/takedowns/safetyCases';
import { AUTHORITIES } from '../../src/safety/takedowns/legalHold';
import { isPublicScanScope, isPrivateScanScope, isScanScope } from '../../src/safety/takedowns/uploadScreening';

describe('CSAE always bans (Terms 19.2 a)', () => {
  test.each(SANCTIONS)('csae + requested %s -> ban', (s) => {
    expect(effectiveSanction('csae', s)).toBe('ban');
  });
  test.each(SANCTIONS)('ncii keeps the moderator choice (%s)', (s) => {
    expect(effectiveSanction('ncii', s)).toBe(s);
  });
});

describe('report package authorities (Terms 19.2 b)', () => {
  test('US, Brazil and the EU are offered', () => {
    expect(AUTHORITIES).toEqual(expect.arrayContaining(['NCMEC', 'PF_BR', 'SAFERNET', 'EU_INHOPE']));
  });
});

describe('upload hash screening scope (Terms 17.1 b)', () => {
  test('public surfaces are always scanned', () => {
    expect(isScanScope('profiles/u1/photos/a.jpg', 'public', false)).toBe(true);
    expect(isScanScope('communities/c1/a.jpg', 'public', false)).toBe(true);
    expect(isPublicScanScope('storefronts/s1/a.jpg', 'public')).toBe(true);
  });
  test('private surfaces are scanned only with the flag on', () => {
    for (const p of ['chat_images/m1/a.jpg', 'group_media/g1/a.jpg']) {
      expect(isScanScope(p, 'public', false)).toBe(false);
      expect(isScanScope(p, 'public', true)).toBe(true);
    }
    expect(isScanScope('profiles/u1/private/a.jpg', 'private', false)).toBe(false);
    expect(isScanScope('profiles/u1/private/a.jpg', 'private', true)).toBe(true);
  });
  test('never: support attachments, receipts, voice and video', () => {
    for (const p of ['support_attachments/t1/a.jpg', 'ticket_receipts/r1/a.jpg', 'chat_images/m1/chat_videos/a.jpg']) {
      expect(isScanScope(p, 'public', true)).toBe(false);
    }
    expect(isPrivateScanScope('chat_images/m1/voice/a.jpg', 'public')).toBe(false);
  });
});
