/**
 * adminQuarantinePreview (safety/quarantinePreview.ts): signed 10-minute
 * preview of a held picture for moderators. No network: PathFakeFirestore +
 * injected storage/sign/role deps.
 */
import { HttpsError } from 'firebase-functions/v2/https';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as qp from '../../src/safety/quarantinePreview';

const T0 = Date.UTC(2026, 9, 22, 10, 0, 0);
const UID = 'ownerUid0001';
const PHOTO = `profiles/${UID}/photos/1700000000000.jpg`;

let db: PathFakeFirestore;
let stored: Record<string, string>;
let signed: Array<{ path: string; expires: number }>;
let roleOk: boolean;
const saved = { ...qp.quarantinePreviewDeps };

beforeEach(() => {
  db = new PathFakeFirestore();
  stored = {};
  signed = [];
  roleOk = true;
  Object.assign(qp.quarantinePreviewDeps, {
    db: () => db as any,
    now: () => T0,
    requireModerator: async () => {
      if (!roleOk) throw new HttpsError('permission-denied', 'Requires role: superAdmin | moderator');
      return { uid: 'mod1', role: 'moderator' };
    },
    stat: async (p: string) => (p in stored ? { contentType: stored[p] } : null),
    sign: async (path: string, expires: number) => {
      signed.push({ path, expires });
      return `https://signed.example/${path}?exp=${expires}`;
    },
  });
});
afterAll(() => Object.assign(qp.quarantinePreviewDeps, saved));

const call = (queueId: unknown) => qp.handleQuarantinePreview({ uid: 'mod1' }, { queueId });

describe('previewCandidates', () => {
  it('quarantinedImage: quarantine copy first, then the original path', () => {
    expect(qp.previewCandidates({ itemType: 'quarantinedImage', objectPath: PHOTO, quarantinePath: `quarantine/${PHOTO}` }))
      .toEqual([{ path: `quarantine/${PHOTO}`, location: 'quarantine' }, { path: PHOTO, location: 'original' }]);
  });

  it('picture appeal uses imageReview.objectPath', () => {
    expect(qp.previewCandidates({ itemType: 'appeal', imageReview: { objectPath: PHOTO } })[0])
      .toEqual({ path: `quarantine/${PHOTO}`, location: 'quarantine' });
  });

  it('refuses non-picture items and unexpected paths', () => {
    expect(qp.previewCandidates({ itemType: 'userReport', objectPath: PHOTO })).toEqual([]);
    expect(qp.previewCandidates({ itemType: 'appeal' })).toEqual([]);
    expect(qp.previewCandidates({ itemType: 'quarantinedImage', objectPath: 'safety_holds/x.jpg' })).toEqual([]);
    expect(qp.previewCandidates({ itemType: 'quarantinedImage', objectPath: 'profiles/../legal_holds/x.jpg' })).toEqual([]);
    expect(qp.previewCandidates({ itemType: 'imageReview', objectPath: 'quarantine/profiles/a.jpg' })).toEqual([]);
  });

  it('ignores a quarantinePath that does not match the object path', () => {
    expect(qp.previewCandidates({ itemType: 'quarantinedImage', objectPath: PHOTO, quarantinePath: 'legal_holds/x.jpg' }))
      .toEqual([{ path: PHOTO, location: 'original' }]);
  });
});

describe('handleQuarantinePreview', () => {
  beforeEach(() => {
    db.setDoc('moderation_queue/q1', {
      itemType: 'quarantinedImage', status: 'pending', objectPath: PHOTO, quarantinePath: `quarantine/${PHOTO}`,
    }, false);
  });

  it('signs the quarantined copy for 10 minutes and audits the view', async () => {
    stored[`quarantine/${PHOTO}`] = 'image/jpeg';
    const r = await call('q1');
    expect(r).toEqual({
      url: `https://signed.example/quarantine/${PHOTO}?exp=${T0 + 10 * 60 * 1000}`,
      expiresAt: T0 + qp.PREVIEW_TTL_MS,
      path: `quarantine/${PHOTO}`,
      location: 'quarantine',
      contentType: 'image/jpeg',
    });
    expect(qp.PREVIEW_TTL_MS).toBe(10 * 60 * 1000);
    const audit = await (db as any).collection('admin_audit_log').get();
    expect(audit.docs.map((d: any) => d.data().action)).toEqual(['viewedHeldImage']);
  });

  it('falls back to the original path when the quarantine move did not happen', async () => {
    stored[PHOTO] = 'image/png';
    const r = await call('q1');
    expect(r.location).toBe('original');
    expect(signed).toEqual([{ path: PHOTO, expires: T0 + qp.PREVIEW_TTL_MS }]);
  });

  it('not-found when neither copy exists', async () => {
    await expect(call('q1')).rejects.toMatchObject({ code: 'not-found', details: { code: 'object_not_found' } });
  });

  it('rejects callers without a moderation role before reading anything', async () => {
    roleOk = false;
    stored[`quarantine/${PHOTO}`] = 'image/jpeg';
    await expect(call('q1')).rejects.toMatchObject({ code: 'permission-denied' });
    expect(signed).toEqual([]);
  });

  it('validates the queue id and the item type', async () => {
    await expect(call('')).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call('a/b')).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call('missing')).rejects.toMatchObject({ code: 'not-found' });
    db.setDoc('moderation_queue/r1', { itemType: 'userReport', status: 'pending' }, false);
    await expect(call('r1')).rejects.toMatchObject({ code: 'failed-precondition', details: { code: 'not_a_picture_item' } });
  });

  it('signing failure is failed-precondition, nothing leaks', async () => {
    stored[`quarantine/${PHOTO}`] = 'image/jpeg';
    qp.quarantinePreviewDeps.sign = async () => { throw new Error('signBlob denied'); };
    await expect(call('q1')).rejects.toMatchObject({ code: 'failed-precondition', details: { code: 'signing_failed' } });
  });
});
