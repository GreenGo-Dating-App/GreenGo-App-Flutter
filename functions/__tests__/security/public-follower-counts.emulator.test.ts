/**
 * Public follower count (owner decision 2026-10-19): the NUMBER of followers
 * of every user AND business is public; who follows (the lists), the
 * following count and the stores count stay private.
 *
 *  - The follow triggers write `follower_counts_public/{uid}` =
 *    {followersCount, updatedAt} in the same transaction as follow_counts.
 *  - Any signed-in user can GET one doc; nobody can LIST / query the
 *    collection; signed-out cannot read; no client can write.
 *  - follow_counts (following / stores) stays owner-only.
 *  - scripts/backfill-public-follower-counts.ts copies follow_counts ->
 *    follower_counts_public, dry-run by default, idempotent.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { countEdge, uncountEdge, FollowCounterDeps } from '../../src/social/followCounters';
import { runPublicFollowerBackfill } from '../../scripts/backfill-public-follower-counts';

/* eslint-disable @typescript-eslint/no-explicit-any */

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const deps: FollowCounterDeps = { db, increment: (n) => admin.firestore.FieldValue.increment(n) };

function emulatorHost(env: string): string {
  const h = process.env[env]!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(h)) throw new Error(`Refusing: ${env} is not a local emulator`);
  return h;
}
async function clearAll() {
  const host = emulatorHost('FIRESTORE_EMULATOR_HOST');
  await new Promise<void>((resolve, reject) => {
    const r = http.request({
      host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    }, (res) => { res.resume(); res.on('end', resolve); });
    r.on('error', reject);
    r.end();
  });
}

function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const docsRoot = `projects/${PROJECT}/databases/(default)/documents`;
const fsBase = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/${docsRoot}`;
const auth = (uid: string | null): Record<string, string> => (uid
  ? { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' }
  : { 'Content-Type': 'application/json' });

async function status(res: Response): Promise<number> {
  await res.text();
  return res.status;
}
async function clientCreate(uid: string, path: string): Promise<number> {
  return status(await fetch(`${fsBase()}:commit`, {
    method: 'POST', headers: auth(uid),
    body: JSON.stringify({ writes: [{
      update: { name: `${docsRoot}/${path}`, fields: {} },
      updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: false },
    }] }),
  }));
}
const clientGet = async (uid: string | null, path: string) =>
  status(await fetch(`${fsBase()}/${path}`, { headers: auth(uid) }));
const clientDelete = async (uid: string, path: string) =>
  status(await fetch(`${fsBase()}/${path}`, { method: 'DELETE', headers: auth(uid) }));
async function clientSetInt(uid: string, path: string, field: string, v: number, mustExist?: boolean): Promise<number> {
  const body: any = { writes: [{ update: { name: `${docsRoot}/${path}`, fields: { [field]: { integerValue: String(v) } } } }] };
  if (mustExist !== undefined) body.writes[0].currentDocument = { exists: mustExist };
  return status(await fetch(`${fsBase()}:commit`, { method: 'POST', headers: auth(uid), body: JSON.stringify(body) }));
}
/** Root collection query (e.g. "top accounts by followers"). */
async function clientListRoot(uid: string, collectionId: string, orderField?: string): Promise<number> {
  const structuredQuery: any = { from: [{ collectionId }], limit: 30 };
  if (orderField) structuredQuery.orderBy = [{ field: { fieldPath: orderField }, direction: 'DESCENDING' }];
  return status(await fetch(`${fsBase()}:runQuery`, { method: 'POST', headers: auth(uid), body: JSON.stringify({ structuredQuery }) }));
}

const edge = (followee: string, follower: string) => `business_followers/${followee}/followers/${follower}`;
const mirror = (follower: string, followee: string) => `user_business_following/${follower}/businesses/${followee}`;
const PUB = 'follower_counts_public';

async function follow(a: string, b: string) {
  expect(await clientCreate(a, edge(b, a))).toBe(200);
  expect(await clientCreate(a, mirror(a, b))).toBe(200);
  expect(await countEdge(deps, b, a)).toBe(true);
}

beforeEach(async () => {
  await clearAll();
  await db.doc('profiles/ana').set({ displayName: 'Ana' });
  await db.doc('profiles/bea').set({ displayName: 'Bea' });
  await db.doc('profiles/carl').set({ displayName: 'Carl' });
  await db.doc('profiles/shop').set({ displayName: 'Shop', isBusiness: true });
});

describe('follower_counts_public', () => {
  test('triggers keep it in step with follow_counts (followersCount + updatedAt only)', async () => {
    await follow('ana', 'bea');
    await follow('carl', 'bea');
    await follow('ana', 'shop');
    const bea = (await db.doc(`${PUB}/bea`).get()).data()!;
    expect(Object.keys(bea).sort()).toEqual(['followersCount', 'updatedAt']);
    expect(bea.followersCount).toBe(2);
    expect((await db.doc(`${PUB}/shop`).get()).get('followersCount')).toBe(1);
    // The follower side never gets a public doc (following / stores private).
    expect((await db.doc(`${PUB}/ana`).get()).exists).toBe(false);
    expect((await db.doc(`${PUB}/carl`).get()).exists).toBe(false);
    // Public profile untouched.
    expect((await db.doc('profiles/bea').get()).data()).toEqual({ displayName: 'Bea' });

    const was = (await db.doc(edge('bea', 'carl')).get()).get('counted') === true;
    expect(await clientDelete('carl', edge('bea', 'carl'))).toBe(200);
    expect(await uncountEdge(deps, 'evt-pub-1', 'bea', 'carl', was)).toBe(true);
    expect((await db.doc(`${PUB}/bea`).get()).get('followersCount')).toBe(1);
    expect((await db.doc('follow_counts/bea').get()).get('followersCount')).toBe(1);
  });

  test('any signed-in user can GET one doc (users AND businesses); signed-out cannot', async () => {
    await follow('ana', 'bea');
    await follow('ana', 'shop');
    expect(await clientGet('carl', `${PUB}/bea`)).toBe(200);
    expect(await clientGet('carl', `${PUB}/shop`)).toBe(200);
    expect(await clientGet('bea', `${PUB}/bea`)).toBe(200);
    expect(await clientGet('carl', `${PUB}/nobody`)).toBe(404); // missing = 0 followers
    expect(await clientGet(null, `${PUB}/bea`)).toBe(403);
  });

  test('nobody can LIST / query the collection', async () => {
    await follow('ana', 'bea');
    expect(await clientListRoot('carl', PUB)).toBe(403);
    expect(await clientListRoot('carl', PUB, 'followersCount')).toBe(403);
    expect(await clientListRoot('bea', PUB)).toBe(403);
  });

  test('no client writes (create, update, delete, own doc or not)', async () => {
    await follow('ana', 'bea');
    expect(await clientSetInt('bea', `${PUB}/bea`, 'followersCount', 999, true)).toBe(403);
    expect(await clientSetInt('carl', `${PUB}/bea`, 'followersCount', 0, true)).toBe(403);
    expect(await clientSetInt('carl', `${PUB}/carl`, 'followersCount', 5, false)).toBe(403);
    expect(await clientDelete('bea', `${PUB}/bea`)).toBe(403);
    expect((await db.doc(`${PUB}/bea`).get()).get('followersCount')).toBe(1);
  });

  test('follow_counts (following / stores) stays owner-only', async () => {
    await follow('ana', 'shop');
    expect(await clientGet('ana', 'follow_counts/ana')).toBe(200);
    expect(await clientGet('carl', 'follow_counts/ana')).toBe(403);
    expect(await clientGet('carl', 'follow_counts/shop')).toBe(403);
    expect(await clientListRoot('carl', 'follow_counts')).toBe(403);
    expect(await clientSetInt('ana', 'follow_counts/ana', 'followingCount', 9, true)).toBe(403);
  });
});

describe('backfill-public-follower-counts script', () => {
  test('dry run writes nothing; apply copies followersCount only; re-run is a no-op', async () => {
    await db.doc('follow_counts/bea').set({ followersCount: 12, followingCount: 3 });
    await db.doc('follow_counts/shop').set({ followersCount: 40, followingCount: 0, storesCount: 2 });
    await db.doc('follow_counts/ana').set({ followingCount: 5, storesCount: 1 }); // 0 followers
    await db.doc(`${PUB}/carl`).set({ followersCount: 3 }); // stale
    await db.doc('follow_counts/carl').set({ followersCount: 4 });
    const quiet = { log: () => undefined };

    const dry = await runPublicFollowerBackfill({ db, apply: false, pageSize: 2, ...quiet });
    expect(dry).toMatchObject({ scanned: 4, writes: 3, done: true });
    expect((await db.doc(`${PUB}/bea`).get()).exists).toBe(false);
    expect((await db.doc(`${PUB}/carl`).get()).get('followersCount')).toBe(3);

    const r = await runPublicFollowerBackfill({ db, apply: true, pageSize: 2, ...quiet });
    expect(r).toMatchObject({ scanned: 4, writes: 3, done: true });
    const bea = (await db.doc(`${PUB}/bea`).get()).data()!;
    expect(Object.keys(bea).sort()).toEqual(['followersCount', 'updatedAt']);
    expect(bea.followersCount).toBe(12);
    const shop = (await db.doc(`${PUB}/shop`).get()).data()!;
    expect(shop.followersCount).toBe(40);
    expect(shop.storesCount).toBeUndefined();
    expect(shop.followingCount).toBeUndefined();
    expect((await db.doc(`${PUB}/carl`).get()).get('followersCount')).toBe(4);
    expect((await db.doc(`${PUB}/ana`).get()).exists).toBe(false);

    expect(await runPublicFollowerBackfill({ db, apply: true, ...quiet })).toMatchObject({ writes: 0, done: true });

    // Resumable: --start-after skips the already-done prefix.
    const tail = await runPublicFollowerBackfill({ db, apply: false, startAfter: 'bea', ...quiet });
    expect(tail.scanned).toBe(2); // carl, shop
  });

  test('after the backfill, a follow keeps both docs equal', async () => {
    await db.doc('follow_counts/bea').set({ followersCount: 7 });
    await runPublicFollowerBackfill({ db, apply: true, log: () => undefined });
    await follow('ana', 'bea');
    expect((await db.doc('follow_counts/bea').get()).get('followersCount')).toBe(8);
    expect((await db.doc(`${PUB}/bea`).get()).get('followersCount')).toBe(8);
  });
});
