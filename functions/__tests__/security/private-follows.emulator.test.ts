/**
 * Private follows (owner rule 2026-10-17): "followers and following are
 * visible only on the profile page as information for the user, not to let
 * people know the followers of a user" - users AND businesses.
 *
 *  1. Follow lists: only the list owner can list / search their followers
 *     (`business_followers/{me}/followers`) and following
 *     (`user_business_following/{me}/businesses`). A viewer can still GET
 *     their OWN edge under someone else (follow button state), never someone
 *     else's edge.
 *  2. Counters live in the owner-only `follow_counts/{uid}` (server-written);
 *     no client can read another user's or write any.
 *  3. The public profile carries no counters: the follow triggers never write
 *     them there, a client can not add / change them, and the move script
 *     folds legacy public values into follow_counts and deletes them.
 *  4. Follow / unfollow (client edge + mirror writes) still works.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { countEdge, uncountEdge, FollowCounterDeps } from '../../src/social/followCounters';
import { backfillStoresCount, moveOne } from '../../scripts/move-follow-counts-private';

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
const auth = (uid: string) => ({ Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' });

/** Client create with `createdAt = request.time` (the app's follow write). */
async function clientCreate(uid: string, path: string): Promise<number> {
  const res = await fetch(`${fsBase()}:commit`, {
    method: 'POST', headers: auth(uid),
    body: JSON.stringify({ writes: [{
      update: { name: `${docsRoot}/${path}`, fields: {} },
      updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: false },
    }] }),
  });
  await res.text();
  return res.status;
}
async function clientGet(uid: string, path: string): Promise<number> {
  const res = await fetch(`${fsBase()}/${path}`, { headers: auth(uid) });
  await res.text();
  return res.status;
}
async function clientDelete(uid: string, path: string): Promise<number> {
  const res = await fetch(`${fsBase()}/${path}`, { method: 'DELETE', headers: auth(uid) });
  await res.text();
  return res.status;
}
/** Merge-update of integer fields (updateMask). */
async function clientPatchInts(uid: string, path: string, data: Record<string, number>): Promise<number> {
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, { integerValue: String(v) }]));
  const mask = Object.keys(data).map((k) => `updateMask.fieldPaths=${k}`).join('&');
  const res = await fetch(`${fsBase()}/${path}?${mask}`, { method: 'PATCH', headers: auth(uid), body: JSON.stringify({ fields }) });
  await res.text();
  return res.status;
}
/** Create a doc with integer + string fields (no transforms). */
async function clientCreateFields(uid: string, path: string, data: Record<string, number | string>): Promise<number> {
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) =>
    [k, typeof v === 'number' ? { integerValue: String(v) } : { stringValue: v }]));
  const res = await fetch(`${fsBase()}:commit`, {
    method: 'POST', headers: auth(uid),
    body: JSON.stringify({ writes: [{ update: { name: `${docsRoot}/${path}`, fields }, currentDocument: { exists: false } }] }),
  });
  await res.text();
  return res.status;
}
/** A list query (the app's page read: orderBy createdAt desc, limit 30). */
async function clientList(uid: string, parent: string, collectionId: string, orderField = 'createdAt'): Promise<number> {
  const structuredQuery = {
    from: [{ collectionId }],
    orderBy: [{ field: { fieldPath: orderField }, direction: 'DESCENDING' }],
    limit: 30,
  };
  const res = await fetch(`${fsBase()}/${parent}:runQuery`, { method: 'POST', headers: auth(uid), body: JSON.stringify({ structuredQuery }) });
  await res.text();
  return res.status;
}

const edge = (followee: string, follower: string) => `business_followers/${followee}/followers/${follower}`;
const mirror = (follower: string, followee: string) => `user_business_following/${follower}/businesses/${followee}`;

/** a follows b through the client, then the create trigger counts it. */
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

describe('follow lists are private to their owner', () => {
  test('only the followee lists / searches their followers; only the follower lists their following', async () => {
    await follow('ana', 'bea');

    // bea's followers: bea yes, everyone else no.
    expect(await clientList('bea', 'business_followers/bea', 'followers')).toBe(200);
    expect(await clientList('carl', 'business_followers/bea', 'followers')).toBe(403);
    expect(await clientList('ana', 'business_followers/bea', 'followers')).toBe(403);
    expect(await clientList('carl', 'business_followers/bea', 'followers', 'followerNameLower')).toBe(403);

    // ana's following: ana yes, everyone else no.
    expect(await clientList('ana', 'user_business_following/ana', 'businesses')).toBe(200);
    expect(await clientList('carl', 'user_business_following/ana', 'businesses')).toBe(403);
    expect(await clientList('bea', 'user_business_following/ana', 'businesses')).toBe(403);
    expect(await clientGet('carl', mirror('ana', 'bea'))).toBe(403);
  });

  test('a viewer reads only their OWN edge (follow button state), never another user\'s', async () => {
    await follow('ana', 'bea');
    expect(await clientGet('ana', edge('bea', 'ana'))).toBe(200); // do I follow bea?
    expect(await clientGet('carl', edge('bea', 'carl'))).toBe(404); // carl: not following (allowed, missing)
    expect(await clientGet('carl', edge('bea', 'ana'))).toBe(403); // does ana follow bea? none of carl's business
    expect(await clientGet('bea', edge('bea', 'ana'))).toBe(200); // "follows you" in bea's own list
    expect(await clientGet('ana', mirror('ana', 'bea'))).toBe(200);
  });

  test('business accounts are private too (owner decision 2026-10-17)', async () => {
    await follow('ana', 'shop');
    expect(await clientList('shop', 'business_followers/shop', 'followers')).toBe(200);
    expect(await clientList('carl', 'business_followers/shop', 'followers')).toBe(403);
    expect(await clientGet('carl', edge('shop', 'ana'))).toBe(403);
    expect(await clientGet('ana', edge('shop', 'ana'))).toBe(200);
    expect(await clientGet('carl', 'follow_counts/shop')).toBe(403);
    expect(await clientGet('shop', 'follow_counts/shop')).toBe(200);
    expect((await db.doc('profiles/shop').get()).get('followersCount')).toBeUndefined();
  });

  test('follow and unfollow still work for the follower', async () => {
    await follow('ana', 'bea');
    expect(await clientDelete('ana', edge('bea', 'ana'))).toBe(200);
    expect(await clientDelete('ana', mirror('ana', 'bea'))).toBe(200);
    // Nobody else can remove the edge.
    await follow('carl', 'bea');
    expect(await clientDelete('ana', edge('bea', 'carl'))).toBe(403);
  });
});

describe('follow counters are private (follow_counts/{uid})', () => {
  test('triggers write ONLY follow_counts; owner reads, others cannot; nobody writes', async () => {
    await follow('ana', 'bea');
    expect((await db.doc('follow_counts/bea').get()).get('followersCount')).toBe(1);
    expect((await db.doc('follow_counts/ana').get()).get('followingCount')).toBe(1);
    const pubBea = (await db.doc('profiles/bea').get()).data()!;
    const pubAna = (await db.doc('profiles/ana').get()).data()!;
    for (const p of [pubBea, pubAna]) {
      expect(p.followersCount).toBeUndefined();
      expect(p.followingCount).toBeUndefined();
    }

    expect(await clientGet('bea', 'follow_counts/bea')).toBe(200);
    expect(await clientGet('ana', 'follow_counts/bea')).toBe(403);
    expect(await clientGet('carl', 'follow_counts/bea')).toBe(403);
    expect(await clientPatchInts('bea', 'follow_counts/bea', { followersCount: 999 })).toBe(403);
    expect(await clientCreateFields('carl', 'follow_counts/carl', { followersCount: 5 })).toBe(403);

    // Unfollow decrements the private counters.
    const was = (await db.doc(edge('bea', 'ana')).get()).get('counted') === true;
    expect(await clientDelete('ana', edge('bea', 'ana'))).toBe(200);
    expect(await uncountEdge(deps, 'evt-1', 'bea', 'ana', was)).toBe(true);
    expect((await db.doc('follow_counts/bea').get()).get('followersCount')).toBe(0);
  });

  test('a client cannot put counters on a public profile (create or update, even 0)', async () => {
    expect(await clientCreateFields('dan', 'profiles/dan', { displayName: 'Dan', followersCount: 0 })).toBe(403);
    expect(await clientCreateFields('dan', 'profiles/dan', { displayName: 'Dan', followingCount: 3 })).toBe(403);
    expect(await clientCreateFields('dan', 'profiles/dan', { displayName: 'Dan' })).toBe(200);
    expect(await clientPatchInts('dan', 'profiles/dan', { followersCount: 0 })).toBe(403);
    expect(await clientPatchInts('dan', 'profiles/dan', { followingCount: 10 })).toBe(403);
    // A legacy public value cannot be changed by the client either.
    await db.doc('profiles/ana').update({ followersCount: 4 });
    expect(await clientPatchInts('ana', 'profiles/ana', { followersCount: 400 })).toBe(403);
  });
});

describe('move-follow-counts-private script', () => {
  test('dry run writes nothing; apply folds public into private and strips the public fields', async () => {
    // Legacy public values + a post-deploy private delta.
    await db.doc('profiles/bea').update({ followersCount: 10, followingCount: 2, followerCount: 7 });
    await db.doc('profiles/shop').update({ followersCount: 50 });
    await db.doc('follow_counts/bea').set({ followersCount: 1 });

    expect(await moveOne(db, 'bea', false)).toEqual(['followersCount', 'followingCount', 'followerCount']);
    expect((await db.doc('profiles/bea').get()).get('followersCount')).toBe(10);
    expect((await db.doc('follow_counts/bea').get()).get('followersCount')).toBe(1);

    expect(await moveOne(db, 'bea', true)).toEqual(['followersCount', 'followingCount', 'followerCount']);
    expect(await moveOne(db, 'shop', true)).toEqual(['followersCount']);
    const pub = (await db.doc('profiles/bea').get()).data()!;
    expect(pub.followersCount).toBeUndefined();
    expect(pub.followingCount).toBeUndefined();
    expect(pub.followerCount).toBeUndefined();
    expect(pub.displayName).toBe('Bea');
    expect((await db.doc('follow_counts/bea').get()).data()).toEqual({ followersCount: 11, followingCount: 2 });
    expect((await db.doc('follow_counts/shop').get()).data()).toEqual({ followersCount: 50 });
    expect((await db.doc('profiles/shop').get()).get('followersCount')).toBeUndefined();

    // Re-run: nothing left, nothing double-counted.
    expect(await moveOne(db, 'bea', true)).toEqual([]);
    expect((await db.doc('follow_counts/bea').get()).get('followersCount')).toBe(11);
  });

  test('stores backfill counts legacy business follows once', async () => {
    // Legacy counted edges (before storesCount): ana follows shop + bea.
    await db.doc(edge('shop', 'ana')).set({ createdAt: 1, counted: true });
    await db.doc(edge('bea', 'ana')).set({ createdAt: 1, counted: true });
    const dry = await backfillStoresCount(db, false);
    expect(dry).toEqual({ businesses: 1, edges: 1, counted: 0 });
    expect((await db.doc('follow_counts/ana').get()).exists).toBe(false);
    expect(await backfillStoresCount(db, true)).toEqual({ businesses: 1, edges: 1, counted: 1 });
    expect((await db.doc('follow_counts/ana').get()).data()).toEqual({ storesCount: 1 });
    expect(await backfillStoresCount(db, true)).toEqual({ businesses: 1, edges: 0, counted: 0 });
    // New business follow: counted by the trigger core directly.
    await follow('carl', 'shop');
    expect((await db.doc('follow_counts/carl').get()).data()).toEqual({ followingCount: 1, storesCount: 1 });
    expect((await db.doc(mirror('carl', 'shop')).get()).get('isStore')).toBe(true);
    expect((await db.doc(mirror('ana', 'shop')).get()).exists).toBe(false); // legacy fixture had no mirror
    // The app's Stores list query: own mirror, isStore == true.
    const res = await fetch(`${fsBase()}/user_business_following/carl:runQuery`, {
      method: 'POST', headers: auth('carl'),
      body: JSON.stringify({ structuredQuery: {
        from: [{ collectionId: 'businesses' }],
        where: { fieldFilter: { field: { fieldPath: 'isStore' }, op: 'EQUAL', value: { booleanValue: true } } },
        orderBy: [{ field: { fieldPath: '__name__' }, direction: 'ASCENDING' }], limit: 30,
      } }),
    });
    const rows: any = await res.json();
    expect(res.status).toBe(200);
    expect(rows.filter((r: any) => r.document).length).toBe(1);
    // A client may not forge the flag on its own mirror.
    const forged = await fetch(`${fsBase()}:commit`, {
      method: 'POST', headers: auth('bea'),
      body: JSON.stringify({ writes: [{
        update: { name: `${docsRoot}/${mirror('bea', 'ana')}`, fields: { isStore: { booleanValue: true } } },
        currentDocument: { exists: false },
      }] }),
    });
    await forged.text();
    expect(forged.status).toBe(403);
  });
});
