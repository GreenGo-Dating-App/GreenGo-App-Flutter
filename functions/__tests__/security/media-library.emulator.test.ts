/**
 * My pictures library + "Ask for a review" rules (2026-10-21):
 *  - media_library/{uid}/items/{id}: owner get/list/delete only; NO client
 *    create or update (the server writes every item from a verdict);
 *  - image_review_limits: server only;
 *  - review requests live in moderation_queue: admin read only, no client
 *    write; they are created only through requestImageReview.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest --config jest.security.config.js -i media-library"
 *
 * Run against BOTH rule files (firestore.rules and firestore.additive.rules).
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
// Storage triggers in the required modules need a default bucket at load time.
{
  const cfg = (() => { try { return JSON.parse(process.env.FIREBASE_CONFIG || '{}'); } catch { return {}; } })();
  if (!cfg.storageBucket) {
    process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT, ...cfg, storageBucket: `${PROJECT}.appspot.com` });
  }
}
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const db = admin.firestore();

// eslint-disable-next-line @typescript-eslint/no-var-requires
const lib = (): any => require('../../src/safety/mediaLibrary');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const rev = (): any => require('../../src/safety/imageReview');

const OWNER = 'ownerUid0001';
const OTHER = 'otherUid0002';
const PHOTO = `profiles/${OWNER}/photos/1.jpg`;
const HELD = `profiles/${OWNER}/photos/2.jpg`;
const ITEM = PHOTO.replace(/\//g, '~');
const HELD_ITEM = HELD.replace(/\//g, '~');
const ADMIN_CLAIMS = { admin: true, isAdmin: true, adminRole: 'superAdmin', role: 'superAdmin' };

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Refusing: not a local emulator');
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}
function idToken(uid: string, claims: Record<string, any> = {}): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' }, ...claims })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
const auth = (uid: string, claims?: Record<string, any>) => ({ Authorization: `Bearer ${idToken(uid, claims)}` });
async function clientGet(uid: string, path: string, claims?: Record<string, any>): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { headers: auth(uid, claims) });
  await res.text();
  return res.status;
}
/** PATCH = create when missing, update when present. */
async function clientPatch(uid: string, path: string, fields: Record<string, any>): Promise<number> {
  const res = await fetch(`${base()}/${path}`, {
    method: 'PATCH',
    headers: { ...auth(uid), 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  await res.text();
  return res.status;
}
async function clientDelete(uid: string, path: string): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { method: 'DELETE', headers: auth(uid) });
  await res.text();
  return res.status;
}
/** Paged list exactly as the app queries it (newest first). */
async function clientList(uid: string, ownerUid: string, orderField = 'createdAt'): Promise<{ status: number; count: number }> {
  const res = await fetch(`${base()}/media_library/${ownerUid}:runQuery`, {
    method: 'POST',
    headers: { ...auth(uid), 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: {
      from: [{ collectionId: 'items' }],
      orderBy: [{ field: { fieldPath: orderField }, direction: 'DESCENDING' }],
      limit: 20,
    } }),
  });
  const body: any = await res.json();
  const count = Array.isArray(body) ? body.filter((r: any) => r.document).length : 0;
  return { status: res.status, count };
}

const STR = (s: string) => ({ stringValue: s });

beforeEach(async () => {
  await clearAll();
  Object.assign(lib().mediaLibraryDeps, {
    ensureToken: async () => 'tok-1',
    readDims: async () => ({ width: 10, height: 10 }),
  });
  await db.doc('admin_users/admin1').set({ role: 'superAdmin', isActive: true });
  // Server-written items (the real writer, against the emulator).
  await lib().recordLibraryVerdict({
    bucket: `${PROJECT}.appspot.com`, objectPath: PHOTO, generation: 1, meta: {}, status: 'approved', hasFace: true,
  });
  await lib().recordLibraryVerdict({
    bucket: `${PROJECT}.appspot.com`, objectPath: HELD, generation: 3, meta: {}, status: 'held',
    reasons: ['no_face'], queueId: `image__${HELD_ITEM}__3`, reviewable: true,
  });
});
afterAll(() => fft.cleanup());

describe('rules: media_library (owner read/delete only)', () => {
  test('owner reads own items, single and paged list (createdAt / approvedAt)', async () => {
    expect(await clientGet(OWNER, `media_library/${OWNER}/items/${ITEM}`)).toBe(200);
    expect(await clientList(OWNER, OWNER)).toEqual({ status: 200, count: 2 });
    // Picker query: only approved items carry approvedAt.
    expect(await clientList(OWNER, OWNER, 'approvedAt')).toEqual({ status: 200, count: 1 });
  });

  test('another user cannot read, list or delete them', async () => {
    expect(await clientGet(OTHER, `media_library/${OWNER}/items/${ITEM}`)).toBe(403);
    expect((await clientList(OTHER, OWNER)).status).toBe(403);
    expect(await clientDelete(OTHER, `media_library/${OWNER}/items/${ITEM}`)).toBe(403);
  });

  test('no client create or update - not even the owner', async () => {
    expect(await clientPatch(OWNER, `media_library/${OWNER}/items/forged`, {
      path: STR(`profiles/${OWNER}/photos/x.jpg`), status: STR('approved'), url: STR('https://evil.example/x.jpg'),
    })).toBe(403);
    expect(await clientPatch(OWNER, `media_library/${OWNER}/items/${HELD_ITEM}`, { status: STR('approved') })).toBe(403);
    expect(await clientPatch(OWNER, `media_library/${OWNER}`, { x: STR('y') })).toBe(403);
    expect(await clientPatch(OTHER, `media_library/${OWNER}/items/forged2`, { status: STR('approved') })).toBe(403);
  });

  test('owner may remove an entry (record only)', async () => {
    expect(await clientDelete(OWNER, `media_library/${OWNER}/items/${ITEM}`)).toBe(200);
    expect((await db.doc(`media_library/${OWNER}/items/${ITEM}`).get()).exists).toBe(false);
  });
});

describe('review requests', () => {
  test('requestImageReview creates the queue item; clients can neither read nor forge it', async () => {
    const wrapped = fft.wrap(rev().requestImageReview) as any;
    const r = await wrapped({ data: { itemId: HELD_ITEM, note: 'This is me.' }, auth: { uid: OWNER, token: {} } });
    expect(r).toMatchObject({ status: 'pending', kind: 'imageReview' });
    const q = (await db.doc(`moderation_queue/${r.queueId}`).get()).data()!;
    expect(q).toMatchObject({ itemType: 'imageReview', userId: OWNER, status: 'pending' });
    expect(q.slaAlertAt).toBeDefined();

    // Owner cannot read or write the queue item; an admin-panel client reads it.
    expect(await clientGet(OWNER, `moderation_queue/${r.queueId}`)).toBe(403);
    expect(await clientPatch(OWNER, `moderation_queue/${r.queueId}`, { status: STR('resolved') })).toBe(403);
    expect(await clientPatch(OWNER, 'moderation_queue/forged', { itemType: STR('imageReview') })).toBe(403);
    expect(await clientGet('admin1', `moderation_queue/${r.queueId}`, ADMIN_CLAIMS)).toBe(200);

    // The rate-limit counter is server only.
    expect(await clientGet(OWNER, `image_review_limits/${OWNER}`)).toBe(403);
    expect(await clientPatch(OWNER, `image_review_limits/${OWNER}`, { count: { integerValue: '0' } })).toBe(403);

    // Owner sees the pending state on the item; cannot clear it.
    expect((await db.doc(`media_library/${OWNER}/items/${HELD_ITEM}`).get()).data()!.review.status).toBe('pending');
    expect(await clientPatch(OWNER, `media_library/${OWNER}/items/${HELD_ITEM}`, { review: { nullValue: null } })).toBe(403);
  });

  test('another user cannot ask for a review of my picture', async () => {
    const wrapped = fft.wrap(rev().requestImageReview) as any;
    await expect(wrapped({ data: { itemId: HELD_ITEM }, auth: { uid: OTHER, token: {} } }))
      .rejects.toMatchObject({ code: 'not-found' });
  });
});
