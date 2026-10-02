/**
 * ID-document retention / purge selection + the "ID verified" flag decision
 * + host-ban experience hiding (pure logic only).
 */
import {
  DAY_MS,
  RETENTION_DAYS,
  entryPaths,
  idVerifiedFlagFor,
  idVerifiedFlagNeedsRepair,
  isDueForPurge,
  mergeAccountRetention,
  planPurgePage,
  purgeAfterMs,
  retentionPathFor,
  RetentionEntry,
} from '../../src/safety/idDocumentRetentionLogic';
import { banPatch, isBannedState, unbanStatus } from '../../src/user_experiences/hostBan';

const NOW = Date.UTC(2026, 9, 1);
const e = (id: string, purge: number | null, extra: Partial<RetentionEntry> = {}): RetentionEntry => ({
  id,
  purgeAfterMs: purge,
  storagePaths: [`retention/u/${id}.jpg`],
  ...extra,
});

describe('retention window', () => {
  it('is 30 days after retention', () => {
    expect(RETENTION_DAYS).toBe(30);
    expect(purgeAfterMs(NOW)).toBe(NOW + 30 * DAY_MS);
  });

  it('due only when purgeAfter <= now, never under legal hold or bad date', () => {
    expect(isDueForPurge(e('a', NOW - 1), NOW)).toBe(true);
    expect(isDueForPurge(e('b', NOW), NOW)).toBe(true);
    expect(isDueForPurge(e('c', NOW + 1), NOW)).toBe(false);
    expect(isDueForPurge(e('d', NOW - DAY_MS, { legalHold: true }), NOW)).toBe(false);
    expect(isDueForPurge(e('e', null), NOW)).toBe(false);
    expect(isDueForPurge(e('f', NaN), NOW)).toBe(false);
    // only a literal true holds
    expect(isDueForPurge(e('g', NOW - 1, { legalHold: 'yes' }), NOW)).toBe(true);
  });

  it('a document retained 29 days ago survives, 30 days ago is purged', () => {
    expect(isDueForPurge(e('x', purgeAfterMs(NOW - 29 * DAY_MS)), NOW)).toBe(false);
    expect(isDueForPurge(e('y', purgeAfterMs(NOW - 30 * DAY_MS)), NOW)).toBe(true);
  });
});

describe('purge page planning', () => {
  it('splits due / held, pages past held entries with a cursor', () => {
    const page = [e('1', NOW - 5), e('2', NOW - 4, { legalHold: true }), e('3', NOW - 3)];
    const plan = planPurgePage(page, NOW, 3);
    expect(plan.due.map((x) => x.id)).toEqual(['1', '3']);
    expect(plan.held).toBe(1);
    expect(plan.cursor).toBe('3');
    expect(plan.done).toBe(false); // full page → read the next one
  });

  it('short / empty page ends the run', () => {
    expect(planPurgePage([e('1', NOW - 1)], NOW, 200).done).toBe(true);
    const empty = planPurgePage([], NOW, 200);
    expect(empty).toEqual({ due: [], held: 0, notDue: 0, cursor: null, done: true });
  });

  it('sanitises storage paths', () => {
    expect(entryPaths({ storagePaths: ['a', 'a', '', 3, 'b'] })).toEqual(['a', 'b']);
    expect(entryPaths({ storagePaths: 'a' })).toEqual([]);
  });
});

describe('account deletion merge', () => {
  it('one entry: moved paths, latest purge date, any hold kept', () => {
    const replacedHeld = e('r1', NOW + 40 * DAY_MS, {
      storagePaths: ['id_documents/u/old.jpg'], legalHold: true,
    });
    const previousRun = e('account_u', NOW + 10 * DAY_MS, { storagePaths: ['retention/u/early.jpg'] });
    const m = mergeAccountRetention(['retention/u/old.jpg', 'retention/u/cur.jpg'], NOW, [replacedHeld, previousRun]);
    expect(m.storagePaths).toEqual(['retention/u/old.jpg', 'retention/u/cur.jpg', 'retention/u/early.jpg']);
    expect(m.purgeAfterMs).toBe(NOW + 40 * DAY_MS);
    expect(m.legalHold).toBe(true);
  });

  it('defaults to deletion + 30 days without hold', () => {
    const m = mergeAccountRetention(['retention/u/a.jpg'], NOW, []);
    expect(m).toEqual({ storagePaths: ['retention/u/a.jpg'], purgeAfterMs: NOW + 30 * DAY_MS, legalHold: false });
  });

  it('maps live paths to the retention prefix', () => {
    expect(retentionPathFor('id_documents/u1/123_doc.jpg', 'u1')).toBe('retention/u1/123_doc.jpg');
  });
});

describe('ID verified flag (profiles.isAgeVerified)', () => {
  it('approval → true, anything else → false', () => {
    expect(idVerifiedFlagFor({ status: 'verified' })).toBe(true);
    for (const st of ['pending', 'rejected', 'declared', 'none', undefined]) {
      expect(idVerifiedFlagFor({ status: st })).toBe(false);
    }
    expect(idVerifiedFlagFor(null)).toBe(false);
  });

  it('repair detects drift both ways; a ban does not touch the flag', () => {
    expect(idVerifiedFlagNeedsRepair({ ageVerification: { status: 'verified' } })).toBe(true);
    expect(idVerifiedFlagNeedsRepair({ ageVerification: { status: 'rejected' }, isAgeVerified: true })).toBe(true);
    expect(idVerifiedFlagNeedsRepair({ ageVerification: { status: 'verified' }, isAgeVerified: true })).toBe(false);
    // banned users keep the flag (the client hides the badge for inactive accounts)
    expect(idVerifiedFlagNeedsRepair({ ageVerification: { status: 'verified' }, isAgeVerified: true, isBanned: true })).toBe(false);
  });
});

describe('host ban → experiences', () => {
  it('detects ban states', () => {
    expect(isBannedState({ isBanned: true })).toBe(true);
    expect(isBannedState({ accountStatus: 'suspended' })).toBe(true);
    expect(isBannedState({ banned: true })).toBe(true);
    expect(isBannedState({ accountStatus: 'active', isBanned: false })).toBe(false);
    expect(isBannedState(null)).toBe(false);
  });

  it('hides non-hidden experiences, remembering the status; restores only ban hides', () => {
    expect(banPatch({ status: 'published' })).toEqual({
      status: 'hidden', moderation: { reason: 'host_banned', previousStatus: 'published' },
    });
    expect(banPatch({ status: 'draft' })?.moderation).toEqual({ reason: 'host_banned', previousStatus: 'draft' });
    expect(banPatch({ status: 'hidden', moderation: { auto: true } })).toBeNull();
    expect(unbanStatus({ status: 'hidden', moderation: { reason: 'host_banned', previousStatus: 'published' } })).toBe('published');
    expect(unbanStatus({ status: 'hidden', moderation: { auto: true, reason: 'prohibited_terms' } })).toBeNull();
    expect(unbanStatus({ status: 'published' })).toBeNull();
  });
});
