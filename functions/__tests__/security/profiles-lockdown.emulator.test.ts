/**
 * INC-2026-001 / E2: public profile lockdown (docs/security/profiles-rules-lockdown.md
 * §2-5). Exercises the rules through the emulator REST API as real clients:
 *  - no client can (re)write a stripped sensitive field to profiles/{uid};
 *  - the writes app 4.6.0+194/195 makes to its own public profile still pass;
 *  - a blocked user can't open the blocker's profile (block_index);
 *  - blockedUsers / album_access are party-only;
 *  - the legacy selfie folder in Storage is owner/admin only.
 * Run against BOTH firestore.rules and firestore.additive.rules.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { applyBlockIndexChange, runBlockIndexBackfill } from '../../src/safety/blockIndex';
import { stripOne } from '../../scripts/strip-public-sensitive-fields';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
const BUCKET = `${PROJECT}.appspot.com`;
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
const db = admin.firestore();
const Ts = admin.firestore.Timestamp;

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

function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
const auth = (uid: string) => ({ Authorization: `Bearer ${idToken(uid)}` });

// ---- REST value encoding ---------------------------------------------------
const SERVER_TS = Symbol('serverTimestamp');
function enc(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
}
/** Dotted paths -> nested object (like the client SDK's update()). */
function nest(flat: Record<string, any>): Record<string, any> {
  const out: Record<string, any> = {};
  for (const [path, v] of Object.entries(flat)) {
    if (v === DELETE) continue;
    const parts = path.split('.');
    let o = out;
    for (const p of parts.slice(0, -1)) o = (o[p] ??= {});
    o[parts[parts.length - 1]] = v;
  }
  return out;
}
const DELETE = Symbol('delete');
function leafPaths(o: Record<string, any>, prefix = ''): string[] {
  return Object.entries(o).flatMap(([k, v]) =>
    v && typeof v === 'object' && !Array.isArray(v) && !(v instanceof Date) && Object.keys(v).length
      ? leafPaths(v, `${prefix}${k}.`) : [`${prefix}${k}`]);
}

async function patch(uid: string, path: string, body: Record<string, any>, mask: string[] | null, exists?: boolean): Promise<number> {
  const qs = [
    ...(mask ?? []).map((m) => `updateMask.fieldPaths=${encodeURIComponent(m.split('.').map((s) => (/^[A-Za-z_][A-Za-z_0-9]*$/.test(s) ? s : `\`${s}\``)).join('.'))}`),
    ...(exists === undefined ? [] : [`currentDocument.exists=${exists}`]),
  ].join('&');
  const fields = Object.fromEntries(Object.entries(body).map(([k, v]) => [k, enc(v)]));
  const res = await fetch(`${base()}/${path}${qs ? `?${qs}` : ''}`, {
    method: 'PATCH', headers: { ...auth(uid), 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  await res.text();
  return res.status;
}
/** Client `update(flatPathsMap)`. */
const update = (uid: string, path: string, flat: Record<string, any>) =>
  patch(uid, path, nest(flat), Object.keys(flat), true);
/** Client `set(data, SetOptions(merge: true))` (deep merge). */
const setMerge = (uid: string, path: string, data: Record<string, any>) => patch(uid, path, data, leafPaths(data));
/** Client `set(data)` on a document that does not exist yet. */
const create = (uid: string, path: string, data: Record<string, any>) => patch(uid, path, data, null, false);

async function get(uid: string, path: string): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { headers: auth(uid) });
  await res.text();
  return res.status;
}
async function del(uid: string, path: string): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { method: 'DELETE', headers: auth(uid) });
  await res.text();
  return res.status;
}
type F = [string, string, any];
async function query(uid: string, collectionId: string, filters: F[], limit?: number): Promise<number> {
  const ops: Record<string, string> = { '==': 'EQUAL', in: 'IN' };
  const fs = filters.map(([f, op, v]) => ({ fieldFilter: { field: { fieldPath: f }, op: ops[op], value: enc(v) } }));
  const where = fs.length === 0 ? undefined : fs.length === 1 ? fs[0] : { compositeFilter: { op: 'AND', filters: fs } };
  const res = await fetch(`${base()}:runQuery`, {
    method: 'POST', headers: { ...auth(uid), 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId }], ...(where ? { where } : {}), ...(limit ? { limit } : {}) } }),
  });
  await res.text();
  return res.status;
}

// ---- fixtures --------------------------------------------------------------
const ALICE = 'alice01';
const BOB = 'bob01';
const MALLORY = 'mallory01';
const CAROL = 'carol01'; // legacy (not yet stripped) profile
const STAFF = 'staff01'; // admin panel user
const INAPP_ADMIN = 'inappadmin01'; // profiles/{uid}.isAdmin == true

/** A public profile as it looks after the strip (what 4.6.0+194 sees). */
const strippedPublic = (name: string) => ({
  userId: name,
  displayName: name,
  nickname: name,
  bio: 'hi',
  gender: 'female',
  photoUrls: ['https://p/1.jpg'],
  interests: ['travel'],
  languages: ['en'],
  location: { city: 'Rome', country: 'Italy', countryLower: 'italy', displayAddress: 'Rome, Italy' },
  geohash5: 'sr2yk',
  approxLocation: { lat: 41.9, lng: 12.48 },
  age: 31,
  isTraveler: false,
  travelerLocation: null,
  verificationStatus: 'approved',
  ageVerification: { status: 'none' },
  isOnline: false,
  showOnMap: true,
  membershipTier: 'FREE',
});

beforeEach(async () => {
  await clearAll();
  await db.doc(`profiles/${ALICE}`).set(strippedPublic(ALICE));
  await db.doc(`profiles/${BOB}`).set(strippedPublic(BOB));
  await db.doc(`profiles/${MALLORY}`).set(strippedPublic(MALLORY));
  await db.doc(`profiles/${INAPP_ADMIN}`).set({ ...strippedPublic(INAPP_ADMIN), isAdmin: true });
  await db.doc(`profiles/${CAROL}`).set({
    ...strippedPublic(CAROL),
    location: { latitude: 45.46, longitude: 9.19, city: 'Milan', country: 'Italy' },
    dateOfBirth: Ts.fromDate(new Date(Date.UTC(1990, 0, 2))),
    fcmToken: 'legacy-token',
  });
  await db.doc(`admin_users/${STAFF}`).set({ role: 'moderator' });
});

// ---------------------------------------------------------------------------
describe('LEGIT: what app 4.6.0+194/195 writes to its own public profile', () => {
  test('full-profile save (ProfileRemoteDataSource.updateProfile, publicSafeProfileJson forUpdate)', async () => {
    expect(await update(ALICE, `profiles/${ALICE}`, {
      displayName: 'Alice B', nickname: 'aliceb', bio: 'new bio', gender: 'female',
      photoUrls: ['https://p/1.jpg', 'https://p/2.jpg'], interests: ['food', 'art'], languages: ['en', 'it'],
      'location.city': 'Rome', 'location.country': 'Italy', 'location.countryLower': 'italy',
      'location.displayAddress': 'Rome, Italy',
      travelerLocation: null, isTraveler: false, verificationStatus: 'approved',
      verificationMethod: null, verificationRejectionReason: null,
      updatedAt: new Date(), showOnMap: false, occupation: 'dev', education: null,
      membershipTier: 'FREE', isAdmin: false, isBanned: false,
    })).toBe(200);
  });

  test('onboarding createProfile = set(merge) of the public-safe JSON on the existing doc', async () => {
    expect(await setMerge(ALICE, `profiles/${ALICE}`, {
      userId: ALICE, displayName: 'Alice', bio: 'b', photoUrls: ['https://p/1.jpg'], interests: ['x'],
      location: { city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy' },
      travelerLocation: null, verificationStatus: 'pending', isComplete: true, createdAt: new Date(), updatedAt: new Date(),
    })).toBe(200);
  });

  test('a brand-new profile document created by the owner (public-safe JSON)', async () => {
    await db.doc(`profiles/${BOB}`).delete();
    expect(await create(BOB, `profiles/${BOB}`, {
      userId: BOB, displayName: 'Bob', photoUrls: [], interests: [],
      location: { city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy' },
      travelerLocation: null, membershipTier: 'FREE', isAdmin: false, isBanned: false,
    })).toBe(200);
  });

  test('location refresh, traveller on/off, presence, ghost mode, boost, showOnMap', async () => {
    expect(await update(ALICE, `profiles/${ALICE}`, {
      locationUpdatedAt: new Date(), 'location.city': 'Milan', 'location.country': 'Italy',
      'location.countryLower': 'italy', 'location.displayAddress': 'Milan, Italy',
    })).toBe(200);
    expect(await update(ALICE, `profiles/${ALICE}`, {
      isTraveler: true, travelerExpiry: new Date(Date.now() + 86400000),
      travelerLocation: { city: 'Paris', country: 'France', displayAddress: 'Paris, France' },
    })).toBe(200);
    expect(await update(ALICE, `profiles/${ALICE}`, { isTraveler: false, travelerLocation: null })).toBe(200);
    expect(await update(ALICE, `profiles/${ALICE}`, { isOnline: true, lastSeen: new Date() })).toBe(200);
    expect(await update(ALICE, `profiles/${ALICE}`, { isGhostMode: true, isIncognito: false, incognitoExpiry: null })).toBe(200);
    expect(await update(ALICE, `profiles/${ALICE}`, { isBoosted: true, boostExpiry: new Date() })).toBe(200);
    expect(await update(ALICE, `profiles/${ALICE}`, { showOnMap: false })).toBe(200);
  });

  test('reverification clears the legacy verificationPhotoUrl (null is allowed)', async () => {
    expect(await update(ALICE, `profiles/${ALICE}`, {
      verificationPhotoUrl: null, verificationStatus: 'pending',
      verificationSubmittedAt: new Date(), verificationRejectionReason: null,
    })).toBe(200);
  });

  test('a legacy (not yet stripped) profile stays editable: untouched legacy values are kept', async () => {
    expect(await update(CAROL, `profiles/${CAROL}`, { bio: 'still works', 'location.city': 'Milano' })).toBe(200);
    // ...and the owner may clear them.
    expect(await update(CAROL, `profiles/${CAROL}`, { dateOfBirth: DELETE, fcmToken: null })).toBe(200);
  });

  test('admin panel / in-app admin verification review (clears verificationPhotoUrl)', async () => {
    expect(await update(STAFF, `profiles/${ALICE}`, {
      verificationStatus: 'approved', verificationPhotoUrl: null, verificationReviewedBy: STAFF,
    })).toBe(200);
    expect(await update(INAPP_ADMIN, `profiles/${BOB}`, {
      verificationStatus: 'rejected', verificationPhotoUrl: null, verificationRejectionReason: 'blurry',
    })).toBe(200);
  });

  test('other users: business follower counter still writable', async () => {
    expect(await update(BOB, `profiles/${ALICE}`, { followerCount: 1 })).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('ATTACK: no client may write a stripped field to a public profile', () => {
  const values: Record<string, any> = {
    dateOfBirth: new Date(Date.UTC(1995, 4, 20)),
    sexualOrientation: 'straight',
    email: 'alice@example.com',
    verificationPhone: '+390000',
    verificationPhotoUrl: 'https://firebasestorage.googleapis.com/x?token=t',
    verificationPhotoPath: `verifications/${ALICE}/a.jpg`,
    privatePhotoUrls: ['https://p/private.jpg'],
    geohash: 'sr2yk3abc',
    fcmToken: 'device-token',
    birthMonthDay: '05-20',
    'location.latitude': 41.89893,
    'location.longitude': 12.47311,
    geohash5: 'u0nd9',
    approxLocation: { lat: 1, lng: 2 },
    age: 18,
  };

  for (const [k, v] of Object.entries(values)) {
    test(`owner update() of ${k} is denied`, async () => {
      expect(await update(ALICE, `profiles/${ALICE}`, { [k]: v })).toBe(403);
    });
  }

  test('travelerLocation with exact coordinates is denied (update and merge)', async () => {
    expect(await update(ALICE, `profiles/${ALICE}`, {
      isTraveler: true, travelerLocation: { city: 'Paris', country: 'France', latitude: 48.85, longitude: 2.35 },
    })).toBe(403);
    expect(await setMerge(ALICE, `profiles/${ALICE}`, { location: { latitude: 41.9, longitude: 12.5 } })).toBe(403);
  });

  test('old-app style full set(merge) with sensitive fields is denied', async () => {
    expect(await setMerge(ALICE, `profiles/${ALICE}`, {
      displayName: 'Alice', dateOfBirth: new Date(Date.UTC(1995, 4, 20)), sexualOrientation: 'gay',
      location: { city: 'Rome', country: 'Italy', latitude: 41.9, longitude: 12.5 },
    })).toBe(403);
  });

  test('the 4.6.0+194 push-token write to profiles is refused (token goes to users/{uid})', async () => {
    expect(await setMerge(ALICE, `profiles/${ALICE}`, { fcmToken: 'tok', fcmTokenUpdatedAt: new Date() })).toBe(403);
    expect(await setMerge(ALICE, `users/${ALICE}`, { fcmToken: 'tok', fcmTokenUpdatedAt: new Date() })).toBe(200);
  });

  test('legacy profile: replacing a kept value with a NEW one is denied', async () => {
    expect(await update(CAROL, `profiles/${CAROL}`, { 'location.latitude': 1.5 })).toBe(403);
    expect(await update(CAROL, `profiles/${CAROL}`, { dateOfBirth: new Date(Date.UTC(1991, 0, 1)) })).toBe(403);
    expect(await update(CAROL, `profiles/${CAROL}`, { fcmToken: 'new-token' })).toBe(403);
  });

  test('create with sensitive fields / coordinates / coarse fields is denied', async () => {
    await db.doc(`profiles/${BOB}`).delete();
    expect(await create(BOB, `profiles/${BOB}`, { displayName: 'Bob', dateOfBirth: new Date() })).toBe(403);
    expect(await create(BOB, `profiles/${BOB}`, { displayName: 'Bob', location: { city: 'X', latitude: 1, longitude: 2 } })).toBe(403);
    expect(await create(BOB, `profiles/${BOB}`, { displayName: 'Bob', geohash5: 'sr2yk' })).toBe(403);
    expect(await create(BOB, `profiles/${BOB}`, { displayName: 'Bob', ageVerification: { documentHash: 'h' } })).toBe(403);
  });

  test('admin panel user and in-app admin can not write sensitive values either', async () => {
    expect(await update(STAFF, `profiles/${ALICE}`, { dateOfBirth: new Date() })).toBe(403);
    expect(await update(STAFF, `profiles/${ALICE}`, { 'location.latitude': 41.9 })).toBe(403);
    expect(await update(INAPP_ADMIN, `profiles/${INAPP_ADMIN}`, { dateOfBirth: new Date(Date.UTC(1990, 0, 1)) })).toBe(403);
    expect(await update(STAFF, `profiles/${ALICE}`, { 'ageVerification.documentHash': 'h' })).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('profiles get / list and the block index', () => {
  test('a user blocked by the owner can NOT open the profile; others, owner and staff can', async () => {
    await applyBlockIndexChange(undefined, { blockerId: ALICE, blockedUserId: BOB }, db);
    expect(await get(BOB, `profiles/${ALICE}`)).toBe(403);
    expect(await get(MALLORY, `profiles/${ALICE}`)).toBe(200);
    expect(await get(ALICE, `profiles/${ALICE}`)).toBe(200);
    expect(await get(STAFF, `profiles/${ALICE}`)).toBe(200);
    // The block is one-way: the blocker still opens the blocked user's profile.
    expect(await get(ALICE, `profiles/${BOB}`)).toBe(200);
    // block_index itself is unreadable / unwritable by clients.
    expect(await get(ALICE, `block_index/${ALICE}_${BOB}`)).toBe(403);
    expect(await create(MALLORY, `block_index/${ALICE}_${MALLORY}`, { blockerId: ALICE })).toBe(403);
  });

  test('syncBlockIndex: create indexes, delete un-indexes only when no duplicate block is left', async () => {
    const pair = { blockerId: ALICE, blockedUserId: BOB };
    await db.doc('blockedUsers/b1').set(pair);
    await db.doc('blockedUsers/b2').set(pair);
    await applyBlockIndexChange(undefined, pair, db);
    expect((await db.doc(`block_index/${ALICE}_${BOB}`).get()).exists).toBe(true);
    await db.doc('blockedUsers/b1').delete();
    await applyBlockIndexChange(pair, undefined, db);
    expect((await db.doc(`block_index/${ALICE}_${BOB}`).get()).exists).toBe(true);
    await db.doc('blockedUsers/b2').delete();
    await applyBlockIndexChange(pair, undefined, db);
    expect((await db.doc(`block_index/${ALICE}_${BOB}`).get()).exists).toBe(false);
    expect(await get(BOB, `profiles/${ALICE}`)).toBe(200);
  });

  test('block index backfill is idempotent', async () => {
    await db.doc('blockedUsers/x1').set({ blockerId: ALICE, blockedUserId: BOB });
    await db.doc('blockedUsers/x2').set({ blockerId: MALLORY, blockedUserId: ALICE });
    await db.doc('blockedUsers/bad').set({ blockerId: ALICE });
    expect(await runBlockIndexBackfill({ firestore: db, pageSize: 1 })).toEqual({ scanned: 3, indexed: 2 });
    expect(await runBlockIndexBackfill({ firestore: db })).toEqual({ scanned: 3, indexed: 2 });
    expect((await db.doc(`block_index/${MALLORY}_${ALICE}`).get()).exists).toBe(true);
  });

  test('discovery-style queries still work (4.6.0+194 limits 20..1000 and unbounded)', async () => {
    expect(await query(BOB, 'profiles', [['showOnMap', '==', true]], 75)).toBe(200);
    expect(await query(BOB, 'profiles', [['showOnMap', '==', true]], 1000)).toBe(200);
    expect(await query(BOB, 'profiles', [['nickname', '==', ALICE]])).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('blockedUsers: party-only', () => {
  beforeEach(async () => {
    await db.doc('blockedUsers/blk').set({ blockId: 'blk', blockerId: ALICE, blockedUserId: BOB, reason: 'x' });
  });

  test('LEGIT: the app\'s block / list / unblock flows', async () => {
    expect(await create(BOB, 'blockedUsers/new1', { blockId: 'new1', blockerId: BOB, blockedUserId: MALLORY, reason: 'r', blockedAt: new Date() })).toBe(200);
    expect(await query(ALICE, 'blockedUsers', [['blockerId', '==', ALICE]], 500)).toBe(200);
    expect(await query(BOB, 'blockedUsers', [['blockedUserId', '==', BOB]], 500)).toBe(200);
    expect(await query(ALICE, 'blockedUsers', [['blockerId', '==', ALICE], ['blockedUserId', '==', BOB]], 1)).toBe(200);
    expect(await query(BOB, 'blockedUsers', [['blockerId', '==', ALICE], ['blockedUserId', '==', BOB]], 1)).toBe(200);
    expect(await get(BOB, 'blockedUsers/blk')).toBe(200);
    expect(await del(ALICE, 'blockedUsers/blk')).toBe(200);
  });

  test('ATTACK: strangers can not read, forge or delete blocks', async () => {
    expect(await get(MALLORY, 'blockedUsers/blk')).toBe(403);
    expect(await query(MALLORY, 'blockedUsers', [['blockerId', '==', ALICE]], 50)).toBe(403);
    expect(await query(MALLORY, 'blockedUsers', [])).toBe(403);
    // The old nickname-search query (blockerId IN [me, other]) is not provable.
    expect(await query(MALLORY, 'blockedUsers', [['blockerId', 'in', [MALLORY, ALICE]]])).toBe(403);
    expect(await create(MALLORY, 'blockedUsers/forged', { blockerId: ALICE, blockedUserId: BOB })).toBe(403);
    expect(await create(MALLORY, 'blockedUsers/self', { blockerId: MALLORY, blockedUserId: MALLORY })).toBe(403);
    expect(await del(MALLORY, 'blockedUsers/blk')).toBe(403);
    // The BLOCKED user can't lift the block either.
    expect(await del(BOB, 'blockedUsers/blk')).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('album_access: only the owner grants', () => {
  beforeEach(async () => {
    await db.doc('album_access/g1').set({ ownerId: ALICE, grantedToId: BOB, grantedAt: Ts.now() });
  });

  test('LEGIT: grant / hasAccess / list / revoke as AlbumAccessDatasource does', async () => {
    expect(await create(ALICE, 'album_access/g2', { ownerId: ALICE, grantedToId: MALLORY, grantedAt: new Date() })).toBe(200);
    expect(await query(BOB, 'album_access', [['ownerId', '==', ALICE], ['grantedToId', '==', BOB]], 1)).toBe(200);
    expect(await query(ALICE, 'album_access', [['ownerId', '==', ALICE], ['grantedToId', '==', BOB]], 1)).toBe(200);
    expect(await query(ALICE, 'album_access', [['ownerId', '==', ALICE]])).toBe(200);
    expect(await query(BOB, 'album_access', [['grantedToId', '==', BOB]])).toBe(200);
    expect(await del(ALICE, 'album_access/g1')).toBe(200);
  });

  test('ATTACK: self-granting someone else\'s album, reading others\' grants, editing grants', async () => {
    expect(await create(MALLORY, 'album_access/x', { ownerId: ALICE, grantedToId: MALLORY, grantedAt: new Date() })).toBe(403);
    expect(await create(ALICE, 'album_access/y', { ownerId: ALICE, grantedToId: BOB, grantedAt: new Date(), extra: 1 })).toBe(403);
    expect(await query(MALLORY, 'album_access', [['ownerId', '==', ALICE]])).toBe(403);
    expect(await get(MALLORY, 'album_access/g1')).toBe(403);
    expect(await update(ALICE, 'album_access/g1', { grantedToId: MALLORY })).toBe(403);
    expect(await del(BOB, 'album_access/g1')).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('strip script --fcm-token', () => {
  test('removes the public push token, copying it to users/{uid} only when users has none', async () => {
    await db.doc(`profiles/${ALICE}`).set({ fcmToken: 'pub-a', fcmTokenUpdatedAt: Ts.now() }, { merge: true });
    await db.doc(`profiles/${BOB}`).set({ fcmToken: 'pub-b' }, { merge: true });
    await db.doc(`users/${BOB}`).set({ fcmToken: 'newer-b' });
    expect(await stripOne(db, ALICE, false, { fcmToken: true })).toEqual(['fcmToken', 'fcmTokenUpdatedAt']);
    expect((await db.doc(`profiles/${ALICE}`).get()).data()!.fcmToken).toBe('pub-a');
    await stripOne(db, ALICE, true, { fcmToken: true });
    await stripOne(db, BOB, true, { fcmToken: true });
    expect((await db.doc(`profiles/${ALICE}`).get()).data()!.fcmToken).toBeUndefined();
    expect((await db.doc(`profiles/${ALICE}`).get()).data()!.fcmTokenUpdatedAt).toBeUndefined();
    expect((await db.doc(`users/${ALICE}`).get()).data()!.fcmToken).toBe('pub-a');
    expect((await db.doc(`users/${BOB}`).get()).data()!.fcmToken).toBe('newer-b');
    // Without the flag the token is left alone.
    await db.doc(`profiles/${MALLORY}`).set({ fcmToken: 'pub-m' }, { merge: true });
    expect(await stripOne(db, MALLORY, true)).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
const storageHost = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
(storageHost ? describe : describe.skip)('Storage: legacy selfie folder profiles/{uid}/verifications', () => {
  const objUrl = (p: string) => `http://${storageHost}/v0/b/${BUCKET}/o/${encodeURIComponent(p)}?alt=media`;
  const sget = async (uid: string, p: string) => {
    const res = await fetch(objUrl(p), { headers: { Authorization: `Firebase ${idToken(uid)}` } });
    await res.arrayBuffer();
    return res.status;
  };
  beforeAll(async () => {
    const bucket = admin.storage().bucket();
    for (const p of [`profiles/${ALICE}/verifications/selfie.jpg`, `profiles/${ALICE}/photos/p.jpg`]) {
      await bucket.file(p).save(Buffer.from('x'), { contentType: 'image/jpeg', resumable: false });
    }
  });

  test('profile photos stay readable by signed-in users; the legacy selfie is owner-only', async () => {
    expect(await sget(BOB, `profiles/${ALICE}/photos/p.jpg`)).toBe(200);
    expect(await sget(BOB, `profiles/${ALICE}/verifications/selfie.jpg`)).toBe(403);
    expect(await sget(ALICE, `profiles/${ALICE}/verifications/selfie.jpg`)).toBe(200);
  });
});
