/**
 * businessGeohash (owner rule 2026-10-19: Discover finds businesses by their
 * BUSINESS ADDRESS) against the Firestore emulator:
 *  - rules: no client may write `businessGeohash` on profiles/{uid} (it is in
 *    profileServerCoarseKeys); the owner's own storefront address edit still
 *    passes;
 *  - trigger body (handlePublicProfileWrite, as mirrorPrivateProfileFields
 *    runs it): sets / moves / clears the field, writes nothing when unchanged;
 *  - backfill (scripts/backfill-business-geohash.ts core): dry run by
 *    default, --apply writes, a second run writes nothing.
 * Run against BOTH firestore.rules and firestore.additive.rules:
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 firebase emulators:exec --only firestore,auth,storage \
 *     --project test-project "cd functions && npx jest -i __tests__/security/business-geohash.emulator.test.ts"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { geohashEncode, handlePublicProfileWrite } from '../../src/profiles/privateProfile';
import { runBusinessGeohashBackfill } from '../../src/profiles/businessGeohash';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

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
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, phone_number: '+351910000000', firebase: { sign_in_provider: 'password' } })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;

function enc(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
}

/** Client `update({...})` with top-level keys (updateMask = the keys). */
async function update(uid: string, path: string, data: Record<string, any>): Promise<number> {
  const qs = [...Object.keys(data).map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`), 'currentDocument.exists=true'].join('&');
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, enc(v)]));
  const res = await fetch(`${base()}/${path}?${qs}`, {
    method: 'PATCH', headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  await res.text();
  return res.status;
}
/** Client `set(data)` on a document that does not exist yet. */
async function create(uid: string, path: string, data: Record<string, any>): Promise<number> {
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, enc(v)]));
  const res = await fetch(`${base()}/${path}?currentDocument.exists=false`, {
    method: 'PATCH', headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  await res.text();
  return res.status;
}

const SP: [number, number] = [-23.5505, -46.6333];
const RIO: [number, number] = [-22.9068, -43.1729];
const addr = (c: [number, number]) => ({ address: 'Rua A, 1', latitude: c[0], longitude: c[1], city: 'X', country: 'Brazil' });
const OWNER = 'shopowner01';
const PERSON = 'person01';

const publicProfile = (uid: string, extra: Record<string, any> = {}) => ({
  userId: uid,
  displayName: uid,
  nickname: uid,
  bio: 'hi',
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
  ...extra,
});

const g = (c: [number, number]) => geohashEncode(c[0], c[1], 9);
const data = async (path: string) => (await db.doc(path).get()).data() ?? {};

beforeEach(async () => {
  await clearAll();
  await db.doc(`profiles/${OWNER}`).set(publicProfile(OWNER, { isBusiness: true, businessAddress: addr(SP), businessGeohash: g(SP) }));
  await db.doc(`profiles/${PERSON}`).set(publicProfile(PERSON));
});

describe('rules: businessGeohash is server-only', () => {
  test('the owner cannot set, change or remove businessGeohash', async () => {
    expect(await update(OWNER, `profiles/${OWNER}`, { businessGeohash: g(RIO) })).toBe(403);
    expect(await update(OWNER, `profiles/${OWNER}`, { businessGeohash: null })).toBe(403);
    expect(await update(PERSON, `profiles/${PERSON}`, { businessGeohash: g(SP) })).toBe(403);
    expect((await data(`profiles/${OWNER}`)).businessGeohash).toBe(g(SP));
  });

  test('another user cannot write it either', async () => {
    expect(await update(PERSON, `profiles/${OWNER}`, { businessGeohash: g(RIO) })).toBe(403);
  });

  test('a new profile cannot be created with businessGeohash', async () => {
    const doc = {
      userId: PERSON, displayName: 'P', photoUrls: [], interests: [],
      location: { city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy' },
      travelerLocation: null, membershipTier: 'FREE', isAdmin: false, isBanned: false,
    };
    // Control: the same create without the field passes.
    await db.doc(`profiles/${PERSON}`).delete();
    expect(await create(PERSON, `profiles/${PERSON}`, doc)).toBe(200);
    await db.doc(`profiles/${PERSON}`).delete();
    expect(await create(PERSON, `profiles/${PERSON}`, { ...doc, businessGeohash: g(SP) })).toBe(403);
  });

  test('the owner can still edit the storefront address (the trigger derives the cell)', async () => {
    expect(await update(OWNER, `profiles/${OWNER}`, { businessAddress: addr(RIO) })).toBe(200);
  });
});

describe('trigger body: handlePublicProfileWrite', () => {
  test('sets the field for a new business, moves it, clears it, no write when unchanged', async () => {
    const ref = db.doc(`profiles/${PERSON}`);
    const before0 = await data(`profiles/${PERSON}`);
    await ref.update({ isBusiness: true, businessAddress: addr(SP) });
    const after1 = await data(`profiles/${PERSON}`);
    await handlePublicProfileWrite(PERSON, before0, after1, { firestore: db });
    expect((await data(`profiles/${PERSON}`)).businessGeohash).toBe(g(SP));

    // The trigger's own write re-fires the trigger: nothing watched changed.
    const after2 = await data(`profiles/${PERSON}`);
    expect(await handlePublicProfileWrite(PERSON, after1, after2, { firestore: db })).toBe('skipped');

    await ref.update({ businessAddress: addr(RIO) });
    const after3 = await data(`profiles/${PERSON}`);
    await handlePublicProfileWrite(PERSON, after2, after3, { firestore: db });
    expect((await data(`profiles/${PERSON}`)).businessGeohash).toBe(g(RIO));

    // Address text-only edit: re-evaluated, but the same cell -> no public write.
    const t0 = (await ref.get()).updateTime!;
    await ref.update({ 'businessAddress.address': 'Rua B, 2' });
    const after4 = await data(`profiles/${PERSON}`);
    const t1 = (await ref.get()).updateTime!;
    const r = await handlePublicProfileWrite(PERSON, after3, after4, { firestore: db });
    expect(r).toMatchObject({ publicWrites: 0 });
    expect((await ref.get()).updateTime!.isEqual(t1)).toBe(true);
    expect(t1.isEqual(t0)).toBe(false);

    await ref.update({ isBusiness: false });
    const after5 = await data(`profiles/${PERSON}`);
    await handlePublicProfileWrite(PERSON, after4, after5, { firestore: db });
    expect((await data(`profiles/${PERSON}`))).not.toHaveProperty('businessGeohash');
  });
});

describe('backfill-business-geohash', () => {
  test('dry run by default, apply writes, second run writes nothing', async () => {
    // A business written before the trigger knew the field, and a former
    // business still carrying a stale cell.
    await db.doc('profiles/legacybiz').set(publicProfile('legacybiz', { isBusiness: true, businessAddress: addr(RIO) }));
    await db.doc('profiles/formerbiz').set(publicProfile('formerbiz', { isBusiness: false, businessAddress: addr(SP), businessGeohash: g(SP) }));

    const dry = await runBusinessGeohashBackfill({ pageSize: 1 });
    expect(dry).toMatchObject({ dryRun: true, done: true, set: 1, cleared: 1 });
    expect(await data('profiles/legacybiz')).not.toHaveProperty('businessGeohash');

    const run = await runBusinessGeohashBackfill({ dryRun: false, pageSize: 1 });
    expect(run).toMatchObject({ dryRun: false, done: true, set: 1, cleared: 1 });
    expect((await data('profiles/legacybiz')).businessGeohash).toBe(g(RIO));
    expect(await data('profiles/formerbiz')).not.toHaveProperty('businessGeohash');
    expect((await data(`profiles/${OWNER}`)).businessGeohash).toBe(g(SP));

    const again = await runBusinessGeohashBackfill({ dryRun: false });
    expect(again).toMatchObject({ set: 0, cleared: 0, done: true });
  });
});
