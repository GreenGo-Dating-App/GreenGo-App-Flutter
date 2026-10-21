/**
 * My pictures library (safety/mediaLibrary.ts) + "Ask for a review"
 * (safety/imageReview.ts). No network: PathFakeFirestore + injected deps.
 */
process.env.TICKET_QR_SIGNING_KEY = 'unit-test-signing-key-0123456789abcdef0123456789';

import * as admin from 'firebase-admin';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as lib from '../../src/safety/mediaLibrary';
import * as rev from '../../src/safety/imageReview';
import { makeStatusResolver, isFaceCheckablePath } from '../../src/safety/mainPhotoFaceRule';

const T0 = Date.UTC(2026, 9, 21, 10, 0, 0);
const H = 3600_000;
const UID = 'ownerUid0001';
const BUCKET = 'greengo-chat.appspot.com';
const PHOTO = `profiles/${UID}/photos/1700000000000.jpg`;
const ITEM = lib.libraryItemId(PHOTO);
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

let db: PathFakeFirestore;
let now = T0;
let calls: Record<string, any[]>;
const savedLib = { ...lib.mediaLibraryDeps };
const savedRev = { ...rev.imageReviewDeps };

beforeEach(() => {
  db = new PathFakeFirestore();
  now = T0;
  calls = { appeal: [], decision: [], restore: [], alert: [], notify: [] };
  Object.assign(lib.mediaLibraryDeps, {
    db: () => db as any,
    now: () => now,
    ensureToken: async (_b: string, _p: string, meta: any) => lib.firstToken(meta) ?? 'generated-token',
    readDims: async () => ({ width: 800, height: 600 }),
  });
  Object.assign(rev.imageReviewDeps, {
    db: () => db as any,
    now: () => now,
    submitAppeal: async (uid: string, data: any) => {
      calls.appeal.push({ uid, ...data });
      db.setDoc(`moderation_queue/appeal__${data.decisionId}`, { queueId: `appeal__${data.decisionId}`, itemType: 'appeal', status: 'pending' }, false);
      return { appealId: 'a1', status: 'submitted' };
    },
    createDecision: async (p: any) => { calls.decision.push(p); return true; },
    restore: async (objectPath: string, quarantinePath: string) => {
      calls.restore.push({ objectPath, quarantinePath });
      await lib.recordLibraryRestored({ bucket: BUCKET, objectPath, generation: '99', meta: { firebaseStorageDownloadTokens: 'tok-1' } });
      return 'restored';
    },
    sendAlert: async (subject: string) => { calls.alert.push(subject); return true; },
    notify: async (uid: string, id: string, data: any) => { calls.notify.push({ uid, id, data }); },
  });
});

afterAll(() => {
  Object.assign(lib.mediaLibraryDeps, savedLib);
  Object.assign(rev.imageReviewDeps, savedRev);
});

const item = (id = ITEM) => db.get(`media_library/${UID}/items/${id}`) as any;

async function hold(opts: { decisionId?: string | null; path?: string } = {}) {
  const path = opts.path ?? PHOTO;
  await lib.recordLibraryVerdict({
    bucket: BUCKET, objectPath: path, generation: '7', contentType: 'image/jpeg',
    meta: { userId: UID, visibility: 'public', firebaseStorageDownloadTokens: 'tok-1' },
    status: 'held', reasons: ['no_face'], reasonCode: null, hasFace: false,
    queueId: `image__${lib.libraryItemId(path)}__7`, decisionId: opts.decisionId ?? null, reviewable: true,
  });
}

// ─────────────────────────────────────────────────────────── pure

describe('libraryTarget (who owns an upload)', () => {
  test('profile folders by path uid; private album and non-image folders never', () => {
    expect(lib.libraryTarget(PHOTO, {})).toEqual({ uid: UID, usage: 'profile' });
    expect(lib.libraryTarget(`profiles/${UID}/events/a.jpg`, {})).toEqual({ uid: UID, usage: 'event' });
    expect(lib.libraryTarget(`profiles/${UID}/experiences/a.jpg`, {})).toEqual({ uid: UID, usage: 'experience' });
    expect(lib.libraryTarget(PHOTO, { visibility: 'private' })).toBeNull();
    expect(lib.libraryTarget(`profiles/${UID}/voice/a.m4a`, {})).toBeNull();
    expect(lib.libraryTarget(`profiles/${UID}/verifications/a.jpg`, {})).toBeNull();
    expect(lib.libraryTarget(`communities/${UID}/c.jpg`, {})).toEqual({ uid: UID, usage: 'community' });
  });
  test('chat / group images only with the uploader stamp; other prefixes never', () => {
    expect(lib.libraryTarget('chat_images/match1/x.jpg', { uploaderId: UID })).toEqual({ uid: UID, usage: 'chat' });
    expect(lib.libraryTarget('chat_images/match1/x.jpg', {})).toBeNull();
    expect(lib.libraryTarget('group_media/g1/x.jpg', { uploaderId: UID })).toEqual({ uid: UID, usage: 'group_chat' });
    expect(lib.libraryTarget('support_attachments/c/x.jpg', { uploaderId: UID })).toBeNull();
    expect(lib.libraryTarget('ticket_receipts/o/x.jpg', { uploaderId: UID })).toBeNull();
  });
  test('download URL', () => {
    expect(lib.downloadUrlFor('b', 'profiles/u/p.jpg', 't'))
      .toBe('https://firebasestorage.googleapis.com/v0/b/b/o/profiles%2Fu%2Fp.jpg?alt=media&token=t');
    expect(lib.firstToken({ firebaseStorageDownloadTokens: 'a, b' })).toBe('a');
  });
  test('rate limit window', () => {
    expect(rev.nextLimitState(null, T0)).toEqual({ windowStart: T0, count: 1 });
    expect(rev.nextLimitState({ windowStart: T0, count: 4 }, T0 + H)).toEqual({ windowStart: T0, count: 5 });
    expect(rev.nextLimitState({ windowStart: T0, count: 5 }, T0 + H)).toBeNull();
    expect(rev.nextLimitState({ windowStart: T0, count: 5 }, T0 + 24 * H)).toEqual({ windowStart: T0 + 24 * H, count: 1 });
  });
});

// ─────────────────────────────────────────────────────────── verdict -> library

describe('verdict -> library item (server-written)', () => {
  test('APPROVED: item with url, size, face, approvedAt', async () => {
    await lib.recordLibraryVerdict({
      bucket: BUCKET, objectPath: PHOTO, generation: 5, contentType: 'image/jpeg',
      meta: { userId: UID, visibility: 'public', firebaseStorageDownloadTokens: 'tok-1' },
      status: 'approved', reasons: [], hasFace: true,
    });
    const d = item();
    expect(d.status).toBe('approved');
    expect(d.url).toBe(lib.downloadUrlFor(BUCKET, PHOTO, 'tok-1'));
    expect(d).toMatchObject({ path: PHOTO, width: 800, height: 600, hasFace: true, usage: 'profile', generation: '5' });
    expect(d.approvedAt.toMillis()).toBe(T0);
  });
  test('REJECTED / held: no URL, not pickable (no approvedAt), reviewable', async () => {
    await hold();
    const d = item();
    expect(d.status).toBe('held');
    expect(d.url).toBeNull();
    expect(d.approvedAt).toBeUndefined();
    expect(d.reviewable).toBe(true);
    expect(d.quarantinePath).toBe(`quarantine/${PHOTO}`);
  });
  test('hash-list block: rejected, never reviewable', async () => {
    await lib.recordLibraryVerdict({
      bucket: BUCKET, objectPath: PHOTO, generation: 1, meta: {}, status: 'rejected', reasons: ['blocked_hash'], reviewable: false,
    });
    expect(item()).toMatchObject({ status: 'rejected', reviewable: false, url: null });
  });
  test('private album upload is not recorded', async () => {
    const r = await lib.recordLibraryVerdict({
      bucket: BUCKET, objectPath: PHOTO, generation: 1, meta: { visibility: 'private' }, status: 'approved',
    });
    expect(r).toBeNull();
    expect(item()).toBeUndefined();
  });
  test('object deleted: approved item of that generation goes, held item stays', async () => {
    await lib.recordLibraryVerdict({ bucket: BUCKET, objectPath: PHOTO, generation: 5, meta: { firebaseStorageDownloadTokens: 't' }, status: 'approved' });
    expect(await lib.handleLibraryObjectDeleted({ objectPath: PHOTO, generation: 4, meta: {} })).toBe('kept');
    expect(await lib.handleLibraryObjectDeleted({ objectPath: PHOTO, generation: 5, meta: {} })).toBe('deleted');
    expect(item()).toBeUndefined();
    await hold();
    expect(await lib.handleLibraryObjectDeleted({ objectPath: PHOTO, generation: 7, meta: {} })).toBe('kept');
    expect(item().status).toBe('held');
  });
});

// ─────────────────────────────────────────────────────────── review requests

describe('requestImageReview', () => {
  test('creates an imageReview queue item with SLA fields; the item shows pending', async () => {
    await hold();
    const r = await rev.handleRequestImageReview(UID, { itemId: ITEM, note: 'It is me, with sunglasses.' });
    expect(r).toMatchObject({ status: 'pending', kind: 'imageReview', dueAtMs: T0 + 48 * H });
    const q = db.get(`moderation_queue/${r.queueId}`) as any;
    expect(q).toMatchObject({
      itemType: 'imageReview', status: 'pending', userId: UID, objectPath: PHOTO,
      quarantinePath: `quarantine/${PHOTO}`, userNote: 'It is me, with sunglasses.', reasons: ['no_face'],
      relatedQueueId: `image__${ITEM}__7`, reporterId: 'system',
    });
    expect(q.slaAlertAt.toMillis()).toBe(T0 + 24 * H);
    expect(q.slaDueAt.toMillis()).toBe(T0 + 48 * H);
    expect(item().review).toMatchObject({ status: 'pending', kind: 'imageReview', queueId: r.queueId });
  });

  test('one open request per image', async () => {
    await hold();
    await rev.handleRequestImageReview(UID, { itemId: ITEM });
    await expect(rev.handleRequestImageReview(UID, { itemId: ITEM })).rejects.toMatchObject({ code: 'already-exists' });
  });

  test('only held items of the caller; approved or missing items refused', async () => {
    await expect(rev.handleRequestImageReview(UID, { itemId: ITEM })).rejects.toMatchObject({ code: 'not-found' });
    await lib.recordLibraryVerdict({ bucket: BUCKET, objectPath: PHOTO, generation: 5, meta: { firebaseStorageDownloadTokens: 't' }, status: 'approved' });
    await expect(rev.handleRequestImageReview(UID, { itemId: ITEM })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(rev.handleRequestImageReview(undefined, { itemId: ITEM })).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(rev.handleRequestImageReview('someoneElse01', { itemId: ITEM })).rejects.toMatchObject({ code: 'not-found' });
  });

  test(`rate limit: ${rev.REVIEW_DAILY_LIMIT} per 24 h`, async () => {
    for (let i = 0; i <= rev.REVIEW_DAILY_LIMIT; i++) await hold({ path: `profiles/${UID}/photos/p${i}.jpg` });
    for (let i = 0; i < rev.REVIEW_DAILY_LIMIT; i++) {
      await rev.handleRequestImageReview(UID, { itemId: lib.libraryItemId(`profiles/${UID}/photos/p${i}.jpg`) });
    }
    const last = lib.libraryItemId(`profiles/${UID}/photos/p${rev.REVIEW_DAILY_LIMIT}.jpg`);
    await expect(rev.handleRequestImageReview(UID, { itemId: last })).rejects.toMatchObject({ code: 'resource-exhausted' });
    now = T0 + 24 * H + 1;
    await expect(rev.handleRequestImageReview(UID, { itemId: last })).resolves.toMatchObject({ status: 'pending' });
  });

  test('a hold with a DSA decision: the request IS the appeal (reused pipeline)', async () => {
    await hold({ decisionId: `image__${ITEM}__7` });
    const r = await rev.handleRequestImageReview(UID, { itemId: ITEM, note: 'ok' });
    expect(r.kind).toBe('appeal');
    expect(r.queueId).toBe(`appeal__image__${ITEM}__7`);
    expect(calls.appeal).toHaveLength(1);
    expect(calls.appeal[0].appealReason.length).toBeGreaterThanOrEqual(10);
    const q = db.get(`moderation_queue/${r.queueId}`) as any;
    expect(q.itemType).toBe('appeal');
    expect(q.slaAlertAt.toMillis()).toBe(T0 + 24 * H);
    expect(q.imageReview).toMatchObject({ uid: UID, itemId: ITEM, objectPath: PHOTO });
  });

  test('note too long is refused', async () => {
    await hold();
    await expect(rev.handleRequestImageReview(UID, { itemId: ITEM, note: 'x'.repeat(rev.REVIEW_NOTE_MAX + 1) }))
      .rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe('resolveImageReview (takeModerationAction)', () => {
  async function requested() {
    await hold();
    db.setDoc(`moderation_queue/image__${ITEM}__7`, { status: 'pending', itemType: 'quarantinedImage' }, false);
    const r = await rev.handleRequestImageReview(UID, { itemId: ITEM });
    return db.get(`moderation_queue/${r.queueId}`) as any;
  }

  test('APPROVE: restores, item approved with URL, user notified, queue items closed', async () => {
    const q = await requested();
    now = T0 + 5 * H;
    const r = await rev.resolveImageReview(q, 'approve', 'mod1', null);
    expect(r.outcome).toBe('approved');
    expect(calls.restore).toEqual([{ objectPath: PHOTO, quarantinePath: `quarantine/${PHOTO}` }]);
    expect(item()).toMatchObject({ status: 'approved', url: lib.downloadUrlFor(BUCKET, PHOTO, 'tok-1') });
    expect(item().review.status).toBe('approved');
    expect(calls.notify).toHaveLength(1);
    expect(calls.notify[0]).toMatchObject({ uid: UID, data: { action: 'my_pictures', itemId: ITEM } });
    const qa = db.get(`moderation_queue/${q.queueId}`) as any;
    expect(qa.status).toBe('resolved');
    expect(qa.slaAlertAt).toBeUndefined();
    expect((db.get(`moderation_queue/image__${ITEM}__7`) as any).status).toBe('resolved');
  });

  test('REJECT: statement of reasons (decision), item stays hidden and final', async () => {
    const q = await requested();
    const r = await rev.resolveImageReview(q, 'removeContent', 'mod1', { reasonCode: 'other', explanation: 'No face visible.' });
    expect(r.outcome).toBe('rejected');
    expect(calls.restore).toHaveLength(0);
    expect(calls.decision).toHaveLength(1);
    expect(calls.decision[0]).toMatchObject({
      decisionId: q.queueId, userId: UID, action: 'removeContent', reasonCode: 'other', explanation: 'No face visible.', decidedBy: 'mod1',
    });
    expect(item()).toMatchObject({ status: 'rejected', reviewable: false, url: null });
    expect(item().review).toMatchObject({ status: 'rejected', decisionId: q.queueId });
  });

  test('other actions are refused', async () => {
    const q = await requested();
    await expect(rev.resolveImageReview(q, 'banUser', 'mod1', null)).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  test('upheld appeal on a decision-backed hold makes the item final', async () => {
    await hold({ decisionId: 'd1' });
    await lib.syncLibraryAfterAppeal({ decisionId: 'd1', userId: UID, role: 'affected', effects: [{ type: 'quarantine', objectPath: PHOTO }] }, 'upheld');
    expect(item()).toMatchObject({ status: 'rejected', reviewable: false });
  });
});

describe('SLA sweep (24 h alert)', () => {
  test('alerts once for open requests older than 24 h; resolved ones are just cleaned', async () => {
    db.setDoc('moderation_queue/a', { status: 'pending', itemType: 'imageReview', slaAlertAt: ts(T0 - H) }, false);
    db.setDoc('moderation_queue/b', { status: 'resolved', itemType: 'imageReview', slaAlertAt: ts(T0 - H) }, false);
    db.setDoc('moderation_queue/c', { status: 'pending', itemType: 'imageReview', slaAlertAt: ts(T0 + H) }, false);
    const r = await rev.runImageReviewSlaSweep(T0);
    expect(r.overdue).toEqual(['a']);
    expect(r.cleared).toBe(2);
    expect(calls.alert).toHaveLength(1);
    expect((db.get('moderation_queue/a') as any).slaAlertAt).toBeUndefined();
    expect((db.get('moderation_queue/a') as any).slaAlertedAt.toMillis()).toBe(T0);
    expect((db.get('moderation_queue/c') as any).slaAlertAt).toBeDefined();
    // Second pass: nothing new to alert.
    const again = await rev.runImageReviewSlaSweep(T0 + 1);
    expect(again.overdue).toEqual([]);
    expect(calls.alert).toHaveLength(1);
  });
});

describe('main-photo face rule uses the library item', () => {
  test('a library picture reused as main photo: hasFace from the item, no Vision call', async () => {
    const chatPath = 'chat_images/match1/x.jpg';
    let detected = 0;
    const resolve = makeStatusResolver(UID, {
      defaultBucket: () => BUCKET,
      readVerdict: async () => null,
      detectFaces: async () => { detected++; return 1; },
      saveFaceResult: async () => undefined,
      readProfile: async () => null,
      updatePhotoUrls: async () => false,
      notify: async () => undefined,
      readLibraryFace: async (_u, p) => (p === chatPath ? false : null),
    });
    expect(isFaceCheckablePath(chatPath)).toBe(true);
    expect(await resolve(lib.downloadUrlFor(BUCKET, chatPath, 't'))).toBe('no_face');
    expect(detected).toBe(0);
    expect(await resolve(lib.downloadUrlFor(BUCKET, 'communities/u/c.jpg', 't'))).toBe('face');
    expect(detected).toBe(1);
  });
});
