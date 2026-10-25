/**
 * Followed-store search / filter fields (functions src/social/followStores.ts),
 * against the Firestore emulator:
 *
 *  1. Clients can NOT write the store fields on a mirror, the place facets
 *     (`user_store_places`) or the `follow_store_jobs` queue; facets are
 *     readable ONLY by their owner. The plain client follow keeps working.
 *  2. Server stamping + the app's query shapes as a signed-in client:
 *     equality filters (category / country / city) + orderBy storeNameLower
 *     + prefix range + cursor.
 *  3. The backfill script (dry-run, apply, resumable, idempotent).
 *
 * Run against BOTH firestore.rules and firestore.additive.rules.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import {
  FOLLOW_STORE_JOBS,
  STORE_PLACES,
  placeId,
  stampStoreFields,
} from '../../src/social/followStores';
import { runStoreFieldsBackfill } from '../../scripts/backfill-store-fields';

/* eslint-disable @typescript-eslint/no-explicit-any */

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const fv = {
  increment: (n: number) => admin.firestore.FieldValue.increment(n),
  delete: () => admin.firestore.FieldValue.delete(),
};

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

async function clientCreate(uid: string, path: string, extra: Record<string, string> = {}): Promise<number> {
  const fields = Object.fromEntries(Object.entries(extra).map(([k, v]) => [k, { stringValue: v }]));
  const res = await fetch(`${fsBase()}:commit`, {
    method: 'POST', headers: auth(uid),
    body: JSON.stringify({ writes: [{
      update: { name: `${docsRoot}/${path}`, fields },
      updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: false },
    }] }),
  });
  await res.text();
  return res.status;
}
async function clientPatch(uid: string, path: string, data: Record<string, string>): Promise<number> {
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, { stringValue: v }]));
  const mask = Object.keys(data).map((k) => `updateMask.fieldPaths=${k}`).join('&');
  const res = await fetch(`${fsBase()}/${path}?${mask}`, { method: 'PATCH', headers: auth(uid), body: JSON.stringify({ fields }) });
  await res.text();
  return res.status;
}
async function clientGet(uid: string, path: string): Promise<number> {
  const res = await fetch(`${fsBase()}/${path}`, { headers: auth(uid) });
  await res.text();
  return res.status;
}

/** The app's store query as a signed-in client. Returns doc ids. */
async function clientStores(uid: string, owner: string, opts: {
  category?: string; country?: string; city?: string; q?: string; limit?: number;
  after?: { name: string; id: string };
}): Promise<{ status: number; ids: string[] }> {
  const eq = (field: string, value: string) => ({
    fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: value } },
  });
  const filters = [
    ...(opts.category ? [eq('storeCategory', opts.category)] : []),
    ...(opts.country ? [eq('storeCountry', opts.country)] : []),
    ...(opts.city ? [eq('storeCityLower', opts.city)] : []),
  ];
  const sq: any = {
    from: [{ collectionId: 'businesses' }],
    orderBy: [{ field: { fieldPath: 'storeNameLower' }, direction: 'ASCENDING' },
      { field: { fieldPath: '__name__' }, direction: 'ASCENDING' }],
    limit: opts.limit ?? 30,
  };
  if (filters.length) sq.where = filters.length === 1 ? filters[0] : { compositeFilter: { op: 'AND', filters } };
  if (opts.q !== undefined) sq.endAt = { values: [{ stringValue: `${opts.q}` }], before: false };
  if (opts.after) {
    sq.startAt = { values: [{ stringValue: opts.after.name },
      { referenceValue: `${docsRoot}/user_business_following/${owner}/businesses/${opts.after.id}` }], before: false };
  } else if (opts.q !== undefined) {
    sq.startAt = { values: [{ stringValue: opts.q }], before: true };
  }
  const res = await fetch(`${fsBase()}/user_business_following/${owner}:runQuery`, {
    method: 'POST', headers: auth(uid), body: JSON.stringify({ structuredQuery: sq }),
  });
  const body: any = await res.json().catch(() => null);
  const ids = Array.isArray(body) ? body.filter((r) => r.document).map((r) => String(r.document.name).split('/').pop()) : [];
  return { status: res.status, ids };
}

const edge = (followee: string, follower: string) => `business_followers/${followee}/followers/${follower}`;
const mirror = (follower: string, followee: string) => `user_business_following/${follower}/businesses/${followee}`;
const addr = (city: string, country: string) => ({ address: `1 Main St, ${city}`, city, country, latitude: 41.9, longitude: 12.5 });

beforeEach(async () => {
  await clearAll();
});

describe('followed-store fields are server-only, facets owner-only', () => {
  test('client writes refused; plain follow works; facets readable only by the owner', async () => {
    await db.doc('profiles/s').set({ isBusiness: true, businessName: 'Shop', businessCategory: 'Bar', businessAddress: addr('Rome', 'Italy') });
    await db.doc('profiles/a').set({ displayName: 'Ana' });

    for (const f of ['storeNameLower', 'storeCategory', 'storeCountry', 'storeCityLower']) {
      expect(await clientCreate('a', mirror('a', 's'), { [f]: 'forged' })).toBe(403);
    }
    expect(await clientCreate('a', edge('s', 'a'))).toBe(200);
    expect(await clientCreate('a', mirror('a', 's'))).toBe(200);
    expect(await clientPatch('a', mirror('a', 's'), { storeCategory: 'x' })).toBe(403);

    expect(await stampStoreFields(db, fv, 's', 'a')).toBe(true);
    const country = `${STORE_PLACES}/a/countries/${placeId('Italy')}`;
    const city = `${STORE_PLACES}/a/cities/${placeId('Italy', 'rome')}`;
    expect((await db.doc(country).get()).data()).toEqual({ country: 'Italy', n: 1 });
    expect(await clientGet('a', country)).toBe(200);
    expect(await clientGet('a', city)).toBe(200);
    expect(await clientGet('b', country)).toBe(403);
    expect(await clientPatch('a', country, { n: '99' } as any)).toBe(403);
    expect(await clientCreate('a', `${STORE_PLACES}/a/countries/x`, { country: 'X' })).toBe(403);
    expect(await clientCreate('a', `${FOLLOW_STORE_JOBS}/a`, { x: 'y' })).toBe(403);

    // Owner LIST of the facets (the app's place picker query).
    const res = await fetch(`${fsBase()}/${STORE_PLACES}/a:runQuery`, {
      method: 'POST', headers: auth('a'),
      body: JSON.stringify({ structuredQuery: {
        from: [{ collectionId: 'countries' }],
        where: { fieldFilter: { field: { fieldPath: 'n' }, op: 'GREATER_THAN', value: { integerValue: '0' } } },
        orderBy: [{ field: { fieldPath: 'n' }, direction: 'DESCENDING' }], limit: 100,
      } }),
    });
    expect(res.status).toBe(200);
    const other = await fetch(`${fsBase()}/${STORE_PLACES}/a:runQuery`, {
      method: 'POST', headers: auth('b'),
      body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'countries' }], limit: 100 } }),
    });
    expect(other.status).toBe(403);
  });
});

describe('store query shapes', () => {
  test('category / country / city filters + prefix search + cursor', async () => {
    const U = 'u';
    const stores: Record<string, any> = {
      s1: { businessName: 'Café Roma', businessCategory: 'Cafe', businessAddress: addr('Rome', 'Italy') },
      s2: { businessName: 'Caffè Milano', businessCategory: 'Cafe', businessAddress: addr('Milan', 'Italy') },
      s3: { businessName: 'Casa Porto', businessCategory: 'Bar', businessAddress: addr('Porto', 'Portugal') },
      s4: { businessName: 'Roma Bar', businessCategory: 'Bar', businessAddress: addr('Rome', 'Italy') },
    };
    for (const [id, p] of Object.entries(stores)) {
      await db.doc(`profiles/${id}`).set({ isBusiness: true, ...p });
      expect(await clientCreate(U, edge(id, U))).toBe(200);
      expect(await clientCreate(U, mirror(U, id))).toBe(200);
      await stampStoreFields(db, fv, id, U);
    }
    expect((await clientStores(U, U, { q: 'caf' })).ids).toEqual(['s1', 's2']);
    expect((await clientStores(U, U, { category: 'Bar' })).ids).toEqual(['s3', 's4']);
    expect((await clientStores(U, U, { country: 'Italy' })).ids).toEqual(['s1', 's2', 's4']);
    expect((await clientStores(U, U, { country: 'Italy', city: 'rome' })).ids).toEqual(['s1', 's4']);
    expect((await clientStores(U, U, { category: 'Cafe', country: 'Italy' })).ids).toEqual(['s1', 's2']);
    expect((await clientStores(U, U, { category: 'Bar', country: 'Italy', city: 'rome', q: 'ro' })).ids).toEqual(['s4']);
    const p1 = await clientStores(U, U, { country: 'Italy', limit: 2 });
    expect(p1.ids).toEqual(['s1', 's2']);
    const p2 = await clientStores(U, U, { country: 'Italy', limit: 2, after: { name: 'caffe milano', id: 's2' } });
    expect(p2.ids).toEqual(['s4']);
    // Public mirror (owner decision 2026-10-19): someone else may query it too.
    expect((await clientStores('x', U, { category: 'Bar' })).status).toBe(200);
  });
});

describe('backfill-store-fields script', () => {
  test('dry-run writes nothing; --apply fills legacy mirrors once; resumable', async () => {
    await db.doc('profiles/s').set({ isBusiness: true, businessName: 'Shop', businessAddress: addr('Rome', 'Italy') });
    await db.doc('profiles/p').set({ displayName: 'Person' });
    for (const f of ['a', 'b', 'c']) {
      await db.doc(edge('s', f)).set({ createdAt: 1 });
      await db.doc(mirror(f, 's')).set({ createdAt: 1 });
    }
    await db.doc(mirror('a', 'p')).set({ createdAt: 1 });
    // A top-level / foreign `businesses` collection is never touched.
    await db.doc('businesses/zz').set({ x: 1 });
    const quiet = () => undefined;
    const dry = await runStoreFieldsBackfill({ db, fv, apply: false, log: quiet });
    expect(dry).toMatchObject({ scanned: 5, mirrorWrites: 3, done: true });
    expect((await db.doc(mirror('a', 's')).get()).get('storeNameLower')).toBeUndefined();

    const first = await runStoreFieldsBackfill({ db, fv, apply: true, pageSize: 2, maxPages: 1, log: quiet });
    expect(first.done).toBe(false);
    await runStoreFieldsBackfill({ db, fv, apply: true, pageSize: 2, startAfter: first.cursor!, log: quiet });
    for (const f of ['a', 'b', 'c']) {
      expect((await db.doc(mirror(f, 's')).get()).data()).toMatchObject({ storeNameLower: 'shop', storeCountry: 'Italy', storeCityLower: 'rome' });
      expect((await db.doc(`${STORE_PLACES}/${f}/countries/${placeId('Italy')}`).get()).get('n')).toBe(1);
    }
    expect((await db.doc(mirror('a', 'p')).get()).data()).toEqual({ createdAt: 1 });
    expect((await db.doc('businesses/zz').get()).data()).toEqual({ x: 1 });
    const again = await runStoreFieldsBackfill({ db, fv, apply: true, log: quiet });
    expect(again.mirrorWrites).toBe(0);
    expect((await db.doc(`${STORE_PLACES}/a/countries/${placeId('Italy')}`).get()).get('n')).toBe(1);
  });
});
