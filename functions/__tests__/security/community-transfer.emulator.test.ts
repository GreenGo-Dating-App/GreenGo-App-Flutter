/**
 * Community ownership transfer (owner request 2026-10-21), against the
 * Firestore emulator rules + the real transfer service on the emulator:
 *
 *  1. community_transfers: the owner reads the offer by id (also when there
 *     is none), the target finds it with a toUserId query; nobody else reads
 *     it, and NO client (owner, target, community admin, platform admin) can
 *     create / update / delete it.
 *  2. community_audit is server-only (platform admins read).
 *  3. Clients still cannot move createdByUserId themselves.
 *  4. End to end with real Firestore transactions: offer -> accept moves
 *     ownership; afterwards the rules treat the NEW owner as creator (info
 *     edit, delete) and the old owner as an admin only.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i --config jest.security.config.js community-transfer"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import * as T from '../../src/communities/transfer';

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
function toValue(v: any): any {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}
const base = () => `http://${emulatorHost('FIRESTORE_EMULATOR_HOST')}/v1/projects/${PROJECT}/databases/(default)/documents`;
const authH = (uid: string) => ({ Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' });

async function clientGet(uid: string, path: string): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { headers: authH(uid) });
  await res.text();
  return res.status;
}
/** Query [collection] where field == value (all pairs), as [uid]. */
async function clientQuery(uid: string, collection: string, eq: Record<string, string>): Promise<{ status: number; count: number }> {
  const filters = Object.entries(eq).map(([f, v]) => ({
    fieldFilter: { field: { fieldPath: f }, op: 'EQUAL', value: { stringValue: v } },
  }));
  const res = await fetch(`${base()}:runQuery`, {
    method: 'POST',
    headers: authH(uid),
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: collection }],
        where: filters.length === 1 ? filters[0] : { compositeFilter: { op: 'AND', filters } },
        limit: 5,
      },
    }),
  });
  const body: any = await res.json().catch(() => []);
  const count = Array.isArray(body) ? body.filter((r) => r.document).length : 0;
  return { status: res.status, count };
}
async function clientWrite(uid: string, path: string, data: Record<string, any>, mode: 'create' | 'update'): Promise<number> {
  const q = [
    ...(mode === 'update' ? Object.keys(data).map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`) : []),
    `currentDocument.exists=${mode === 'update'}`,
  ].join('&');
  const res = await fetch(`${base()}/${path}?${q}`, {
    method: 'PATCH',
    headers: authH(uid),
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}
async function clientDelete(uid: string, path: string): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { method: 'DELETE', headers: authH(uid) });
  await res.text();
  return res.status;
}

const OWNER = 'u_owner';
const TARGET = 'u_target';
const COMM_ADMIN = 'u_comm_admin';
const STRANGER = 'u_stranger';
const PLATFORM_ADMIN = 'u_platform_admin';
const CID = 'c_xfer';
const C = `communities/${CID}`;
const TX = `community_transfers/${CID}`;

function communityDoc(): Record<string, any> {
  return {
    name: 'Porto Coffee Club',
    description: 'Coffee lovers meeting in Porto',
    type: 'general',
    imageUrl: null,
    createdByUserId: OWNER,
    createdByName: 'Olivia',
    createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
    memberCount: 4,
    languages: ['en'],
    tags: [],
    isPublic: true,
    city: null,
    country: null,
    sponsorId: null,
    isSponsored: false,
    pinnedPromo: null,
    rules: null,
    resourceLinks: [],
  };
}

const saved = { ...T.transferDeps };

beforeAll(() => {
  Object.assign(T.transferDeps, {
    notify: async () => undefined,
    actor: async (uid: string) => ({ id: uid, name: uid }),
    authUnavailable: async () => false,
  });
});
afterAll(() => Object.assign(T.transferDeps, saved));

beforeEach(async () => {
  await clearAll();
  await db.doc(C).set(communityDoc());
  await db.doc(`${C}/members/${OWNER}`).set({ userId: OWNER, displayName: 'Olivia', role: 'owner' });
  await db.doc(`${C}/members/${TARGET}`).set({ userId: TARGET, displayName: 'Tiago', role: 'member' });
  await db.doc(`${C}/members/${COMM_ADMIN}`).set({ userId: COMM_ADMIN, displayName: 'Ana', role: 'admin' });
  for (const u of [OWNER, TARGET, COMM_ADMIN, STRANGER]) {
    await db.doc(`users/${u}`).set({ role: 'user', accountStatus: 'active' });
    await db.doc(`profiles/${u}`).set({ displayName: u });
  }
  await db.doc(`users/${PLATFORM_ADMIN}`).set({ role: 'admin' });
});

const nowSec = () => Math.floor(Date.now() / 1000);
const offer = () => T.requestCommunityTransfer(OWNER, nowSec(), { communityId: CID, toUserId: TARGET });

describe('community_transfers reads', () => {
  test('owner reads the offer by id, also before one exists', async () => {
    // Missing doc: the read is ALLOWED (REST 404 = not found, not 403), so
    // the owner's snapshot listener never fails; there is nothing to leak.
    expect(await clientGet(OWNER, TX)).toBe(404);
    await offer();
    expect(await clientGet(OWNER, TX)).toBe(200);
  });

  test('the target finds it with a toUserId query (and reads it by id)', async () => {
    await offer();
    const q = await clientQuery(TARGET, 'community_transfers', { toUserId: TARGET, communityId: CID });
    expect(q.status).toBe(200);
    expect(q.count).toBe(1);
    expect(await clientGet(TARGET, TX)).toBe(200);
  });

  test('nobody else reads it', async () => {
    await offer();
    expect(await clientGet(STRANGER, TX)).toBe(403);
    expect(await clientGet(COMM_ADMIN, TX)).toBe(403);
    // An unconstrained / foreign query is refused...
    expect((await clientQuery(STRANGER, 'community_transfers', { communityId: CID })).status).toBe(403);
    expect((await clientQuery(STRANGER, 'community_transfers', { toUserId: TARGET })).status).toBe(403);
    // ...and a query for one's own offers simply finds none.
    const own = await clientQuery(STRANGER, 'community_transfers', { toUserId: STRANGER });
    expect(own.status).toBe(200);
    expect(own.count).toBe(0);
    expect(await clientGet(PLATFORM_ADMIN, TX)).toBe(200);
  });
});

describe('no client writes', () => {
  const forged = () => ({
    communityId: CID, fromUserId: OWNER, toUserId: TARGET, status: 'pending',
    expiresAt: new Date(Date.now() + 86400000),
  });

  test('nobody can create an offer', async () => {
    for (const u of [OWNER, TARGET, COMM_ADMIN, STRANGER, PLATFORM_ADMIN]) {
      expect(await clientWrite(u, TX, forged(), 'create')).toBe(403);
    }
  });

  test('nobody can change or delete an existing offer', async () => {
    await offer();
    for (const u of [OWNER, TARGET, COMM_ADMIN, PLATFORM_ADMIN]) {
      expect(await clientWrite(u, TX, { toUserId: STRANGER }, 'update')).toBe(403);
      expect(await clientWrite(u, TX, { status: 'accepted' }, 'update')).toBe(403);
      expect(await clientDelete(u, TX)).toBe(403);
    }
    expect((await db.doc(TX).get()).data()?.toUserId).toBe(TARGET);
  });

  test('community_audit is server-only', async () => {
    await offer();
    const audit = await db.collection('community_audit').get();
    expect(audit.size).toBe(1);
    const path = `community_audit/${audit.docs[0].id}`;
    expect(await clientGet(OWNER, path)).toBe(403);
    expect(await clientGet(TARGET, path)).toBe(403);
    expect(await clientGet(PLATFORM_ADMIN, path)).toBe(200);
    expect(await clientWrite(OWNER, 'community_audit/x', { action: 'accepted' }, 'create')).toBe(403);
    expect(await clientWrite(PLATFORM_ADMIN, 'community_audit/x', { action: 'accepted' }, 'create')).toBe(403);
  });

  test('clients cannot move createdByUserId themselves', async () => {
    expect(await clientWrite(OWNER, C, { createdByUserId: TARGET, createdByName: 'Tiago' }, 'update')).toBe(403);
    expect(await clientWrite(TARGET, C, { createdByUserId: TARGET }, 'update')).toBe(403);
    expect(await clientWrite(COMM_ADMIN, C, { createdByUserId: COMM_ADMIN }, 'update')).toBe(403);
    expect((await db.doc(C).get()).data()?.createdByUserId).toBe(OWNER);
  });
});

describe('end to end on the emulator', () => {
  test('offer -> accept: the new owner is the creator for the rules, the old one an admin', async () => {
    await offer();
    await T.respondCommunityTransfer(TARGET, { communityId: CID, accept: true });

    const c = (await db.doc(C).get()).data()!;
    expect(c.createdByUserId).toBe(TARGET);
    expect(c.createdByName).toBe('Tiago');
    expect((await db.doc(`${C}/members/${TARGET}`).get()).data()?.role).toBe('owner');
    expect((await db.doc(`${C}/members/${OWNER}`).get()).data()?.role).toBe('admin');
    expect((await db.doc(TX).get()).exists).toBe(false);

    // Creator-only info edit follows the new owner (5.0.50 rules).
    expect(await clientWrite(TARGET, C, { name: 'Lisbon Coffee Club' }, 'update')).toBe(200);
    expect(await clientWrite(OWNER, C, { name: 'Hijack' }, 'update')).toBe(403);
    // The old owner keeps admin powers (rules), the new one may delete.
    expect(await clientWrite(OWNER, C, { rules: 'Be kind' }, 'update')).toBe(200);
    expect(await clientDelete(OWNER, C)).toBe(403);
    expect(await clientDelete(TARGET, C)).toBe(200);
  });

  test('decline and the expiry sweep leave ownership untouched', async () => {
    await offer();
    await T.respondCommunityTransfer(TARGET, { communityId: CID, accept: false });
    expect((await db.doc(C).get()).data()?.createdByUserId).toBe(OWNER);
    expect((await db.doc(TX).get()).exists).toBe(false);

    await offer();
    const realNow = T.transferDeps.now;
    T.transferDeps.now = () => new Date(Date.now() + T.TRANSFER_TTL_MS + 1000);
    try {
      expect(await T.expireDueTransfers()).toBe(1);
    } finally {
      T.transferDeps.now = realNow;
    }
    expect((await db.doc(TX).get()).exists).toBe(false);
    expect((await db.doc(C).get()).data()?.createdByUserId).toBe(OWNER);
  });
});
