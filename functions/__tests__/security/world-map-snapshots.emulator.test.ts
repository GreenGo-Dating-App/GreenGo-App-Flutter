/**
 * World map snapshots (owner decision 2026-10-20), against the emulator:
 *
 *  1. Rules: the owner may GET `world_map_snapshots/{uid}` and its chunks;
 *     another user, a signed-out client and any list query are denied; no
 *     client may create / update / delete either.
 *  2. The Firestore reader + writer (FirestoreSnapshotReader / buildAndStore)
 *     on real queries: following / followers / the inbox OR-query / both
 *     block directions (profiles/{uid}/blocked_users + block_index) /
 *     getAll with a field mask; chunked storage read back by readStoredPins.
 *  3. The callable getWorldMapSnapshot: builds on first open, returns the
 *     stored doc on the next open, marks the user active.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules:
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 firebase emulators:exec --only firestore,auth,storage \
 *     --project test-project "cd functions && npx jest -i __tests__/security/world-map-snapshots.emulator.test.ts"
 *   (and once more with --config pointing at a copy of firebase.json whose
 *   firestore.rules is firestore.additive.rules)
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import {
  FirestoreSnapshotReader,
  WORLD_MAP_SNAPSHOTS,
  buildAndStore,
  readStoredPins,
} from '../../src/globe/worldMapSnapshot';

/* eslint-disable @typescript-eslint/no-explicit-any */

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

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
const headers = (uid: string | null) => ({
  ...(uid ? { Authorization: `Bearer ${idToken(uid)}` } : {}),
  'Content-Type': 'application/json',
});

async function clientGet(uid: string | null, path: string): Promise<number> {
  const res = await fetch(`${fsBase()}/${path}`, { headers: headers(uid) });
  await res.text();
  return res.status;
}
async function clientList(uid: string, parent: string, collectionId: string): Promise<number> {
  const res = await fetch(`${fsBase()}${parent ? `/${parent}` : ''}:runQuery`, {
    method: 'POST', headers: headers(uid),
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId }], limit: 10 } }),
  });
  await res.text();
  return res.status;
}
async function clientWrite(uid: string, path: string, exists: boolean | null): Promise<number> {
  const write: any = { update: { name: `${docsRoot}/${path}`, fields: { pins: { arrayValue: {} } } } };
  if (exists !== null) write.currentDocument = { exists };
  const res = await fetch(`${fsBase()}:commit`, { method: 'POST', headers: headers(uid), body: JSON.stringify({ writes: [write] }) });
  await res.text();
  return res.status;
}
async function clientDelete(uid: string, path: string): Promise<number> {
  const res = await fetch(`${fsBase()}/${path}`, { method: 'DELETE', headers: headers(uid) });
  await res.text();
  return res.status;
}

const person = (name: string, extra: Record<string, any> = {}) => ({
  displayName: name,
  accountStatus: 'active',
  photoUrls: [`https://img.example/${name}.jpg`],
  location: { latitude: 41.95123, longitude: 12.40001, city: 'Rome', country: 'Italy' },
  approxLocation: { lat: 41.901, lng: 12.499 },
  email: `${name}@secret.example`, // must never reach a pin
  ...extra,
});

async function seedNetwork() {
  const now = admin.firestore.Timestamp.now();
  await db.doc('profiles/me').set(person('me'));
  await db.doc('profiles/fo').set(person('fo'));
  await db.doc('profiles/fr').set(person('fr', { globeDiscoverability: 'country' }));
  await db.doc('profiles/ch').set(person('ch'));
  await db.doc('profiles/hid').set(person('hid', { globeDiscoverability: 'hidden' }));
  await db.doc('profiles/iblocked').set(person('iblocked'));
  await db.doc('profiles/blockedme').set(person('blockedme'));
  await db.doc('profiles/legacyblock').set(person('legacyblock'));
  await db.doc('profiles/biz').set(person('Owner', {
    isBusiness: true, businessName: 'Cafe Roma', businessLogoUrl: 'https://img.example/logo.png',
    businessAddress: { address: 'Via Roma 1', latitude: 45.4642, longitude: 9.19, city: 'Milan', country: 'Italy' },
  }));
  for (const id of ['fo', 'biz', 'hid', 'iblocked', 'blockedme', 'legacyblock']) {
    await db.doc(`user_business_following/me/businesses/${id}`).set({ createdAt: now, ...(id === 'biz' ? { isStore: true } : {}) });
  }
  await db.doc('business_followers/me/followers/fr').set({ createdAt: now });
  await db.doc('conversations/c1').set({ userId1: 'ch', userId2: 'me', lastMessage: { content: 'hi' }, lastMessageAt: now });
  await db.doc('conversations/c2').set({ userId1: 'me', userId2: 'fo', lastMessageAt: now }); // no message: not a chat
  await db.doc('conversations/c3').set({ userId1: 'me', userId2: 'biz', lastMessage: { content: 'x' }, lastMessageAt: now });
  await db.doc('block_index/me_iblocked').set({ blockerId: 'me', blockedUserId: 'iblocked' });
  await db.doc('block_index/blockedme_me').set({ blockerId: 'blockedme', blockedUserId: 'me' });
  await db.doc('profiles/me/blocked_users/legacyblock').set({ blockedAt: now });
}

beforeEach(async () => {
  await clearAll();
});

describe('Firestore reader + writer', () => {
  test('builds the network with both block directions, stores one doc', async () => {
    await seedNetwork();
    const r = await buildAndStore(db, new FirestoreSnapshotReader(db), 'me', { nowMs: Date.now() });
    const byId = Object.fromEntries(r.pins.map((p) => [p.id, p]));
    expect(new Set(Object.keys(byId))).toEqual(new Set(['fo', 'fr', 'ch', 'biz']));
    expect(byId.fo.badges).toEqual(['following']);
    expect(byId.fr.badges).toEqual(['follower']);
    expect(byId.ch.badges).toEqual(['chat']);
    expect(byId.biz.badges).toEqual(['following', 'chat']);
    expect(byId.biz.kind).toBe('business');
    expect([byId.biz.lat, byId.biz.lng]).toEqual([45.4642, 9.19]);
    expect(JSON.stringify(r.pins)).not.toContain('secret.example');
    expect(JSON.stringify(r.pins)).not.toContain('41.95123');

    const doc = (await db.doc(`${WORLD_MAP_SNAPSHOTS}/me`).get()).data()!;
    expect(doc.chunkCount).toBe(0);
    expect(doc.pins).toHaveLength(4);
    expect(doc.counts.pins).toBe(4);
    expect(await readStoredPins(db, 'me', doc)).toHaveLength(4);
  });

  test('chunked storage round trip; a smaller rebuild deletes stale chunks', async () => {
    await seedNetwork();
    const reader = new FirestoreSnapshotReader(db);
    // Tiny budgets: one pin per chunk.
    await buildAndStore(db, reader, 'me', { nowMs: Date.now(), budgets: { inline: 10, chunk: 10 } });
    let doc = (await db.doc(`${WORLD_MAP_SNAPSHOTS}/me`).get()).data()!;
    expect(doc.pins).toEqual([]);
    expect(doc.chunkCount).toBe(4);
    expect((await db.collection(`${WORLD_MAP_SNAPSHOTS}/me/chunks`).get()).size).toBe(4);
    const pins = await readStoredPins(db, 'me', doc);
    expect(pins!.map((p) => p.id).sort()).toEqual(['biz', 'ch', 'fo', 'fr']);

    // A chunk of another build is detected (a rebuild raced the reader).
    await db.doc(`${WORLD_MAP_SNAPSHOTS}/me/chunks/2`).update({ buildId: 'other' });
    expect(await readStoredPins(db, 'me', doc)).toBeNull();

    // Rebuild inline: the 4 old chunks are deleted in the same batch.
    await buildAndStore(db, reader, 'me', { nowMs: Date.now(), prevChunkCount: doc.chunkCount });
    doc = (await db.doc(`${WORLD_MAP_SNAPSHOTS}/me`).get()).data()!;
    expect(doc.chunkCount).toBe(0);
    expect(doc.pins).toHaveLength(4);
    expect((await db.collection(`${WORLD_MAP_SNAPSHOTS}/me/chunks`).get()).size).toBe(0);
  });
});

describe('rules: owner get only (world_map_snapshots + chunks)', () => {
  beforeEach(async () => {
    await db.doc(`${WORLD_MAP_SNAPSHOTS}/me`).set({ schema: 1, pins: [], chunkCount: 1, buildId: 'b' });
    await db.doc(`${WORLD_MAP_SNAPSHOTS}/me/chunks/0`).set({ buildId: 'b', index: 0, pins: [] });
  });

  test('owner gets own snapshot and chunk', async () => {
    expect(await clientGet('me', `${WORLD_MAP_SNAPSHOTS}/me`)).toBe(200);
    expect(await clientGet('me', `${WORLD_MAP_SNAPSHOTS}/me/chunks/0`)).toBe(200);
  });

  test('another user and signed-out are denied', async () => {
    expect(await clientGet('eve', `${WORLD_MAP_SNAPSHOTS}/me`)).toBe(403);
    expect(await clientGet('eve', `${WORLD_MAP_SNAPSHOTS}/me/chunks/0`)).toBe(403);
    expect(await clientGet(null, `${WORLD_MAP_SNAPSHOTS}/me`)).toBe(403);
    expect(await clientGet(null, `${WORLD_MAP_SNAPSHOTS}/me/chunks/0`)).toBe(403);
  });

  test('no list query, not even by the owner', async () => {
    expect(await clientList('me', '', WORLD_MAP_SNAPSHOTS)).toBe(403);
    expect(await clientList('me', `${WORLD_MAP_SNAPSHOTS}/me`, 'chunks')).toBe(403);
  });

  test('no client writes (create / update / delete), owner included', async () => {
    expect(await clientWrite('me', `${WORLD_MAP_SNAPSHOTS}/me`, true)).toBe(403);
    expect(await clientWrite('me', `${WORLD_MAP_SNAPSHOTS}/new`, false)).toBe(403);
    expect(await clientWrite('new', `${WORLD_MAP_SNAPSHOTS}/new`, false)).toBe(403);
    expect(await clientWrite('me', `${WORLD_MAP_SNAPSHOTS}/me/chunks/0`, null)).toBe(403);
    expect(await clientDelete('me', `${WORLD_MAP_SNAPSHOTS}/me`)).toBe(403);
    expect(await clientDelete('me', `${WORLD_MAP_SNAPSHOTS}/me/chunks/0`)).toBe(403);
    expect(await clientGet('me', 'maintenance/world_map_snapshots')).toBe(403);
  });
});

describe('callable getWorldMapSnapshot', () => {
  // Loaded lazily: the module creates its Firestore handle at import.
  const fn = () => require('../../src/globe/worldMapSnapshotFunctions').getWorldMapSnapshot;

  test('unauthenticated is refused', async () => {
    await expect(fn().run({ data: {}, auth: undefined } as any)).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  test('first open builds, next open returns the stored snapshot; user marked active', async () => {
    await seedNetwork();
    const first = await fn().run({ data: {}, auth: { uid: 'me' } } as any);
    expect(first.pins.map((p: any) => p.id).sort()).toEqual(['biz', 'ch', 'fo', 'fr']);
    expect(first.stale).toBe(false);
    const doc = (await db.doc(`${WORLD_MAP_SNAPSHOTS}/me`).get()).data()!;
    expect(doc.active).toBe(true);
    expect(doc.lastOpenedAt).toBeTruthy();
    expect(doc.refreshAfter.toMillis()).toBeGreaterThan(Date.now());

    // A new follow after the build is NOT visible until the next batch.
    await db.doc('profiles/late').set(person('late'));
    await db.doc('user_business_following/me/businesses/late').set({ createdAt: admin.firestore.Timestamp.now() });
    const second = await fn().run({ data: {}, auth: { uid: 'me' } } as any);
    expect(second.builtAt).toBe(first.builtAt);
    expect(second.pins).toHaveLength(4);
  });

  test('touchOnly sets the marker without building', async () => {
    const r = await fn().run({ data: { touchOnly: true }, auth: { uid: 'solo' } } as any);
    expect(r).toEqual({ ok: true });
    const doc = (await db.doc(`${WORLD_MAP_SNAPSHOTS}/solo`).get()).data()!;
    expect(doc.active).toBe(true);
    expect(doc.pins).toBeUndefined();
    expect(doc.refreshAfter.toMillis()).toBeLessThanOrEqual(Date.now());
  });
});
