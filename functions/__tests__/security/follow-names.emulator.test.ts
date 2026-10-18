/**
 * Searchable follow-edge names (functions src/social/followNames.ts), against
 * the Firestore emulator:
 *
 *  1. Clients can NOT write `followerNameLower` / `followeeNameLower` (edge or
 *     mirror, create or update) nor the `follow_name_jobs` queue; the normal
 *     client follow writes keep working.
 *  2. The server stamps both names on a new edge, and the app's prefix-search
 *     query shape (orderBy name, startAt q, endAt q+'', limit 20,
 *     startAfter cursor) works for a signed-in client inside the
 *     subcollection (automatic single-field index; no composite needed).
 *  3. The name fan-out (real `orderBy('__name__').startAfter(id)` paging)
 *     refreshes every edge in both directions.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import {
  FOLLOW_NAME_JOBS,
  enqueueFollowNameJobIfChanged,
  followNameRound,
  stampEdgeNames,
} from '../../src/social/followNames';
import { runFollowNameBackfill } from '../../scripts/backfill-follow-names';

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
const auth = (uid: string) => ({ Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' });

/** Client create of [path] with `createdAt = request.time` plus [extra] string fields. */
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
/** Client merge-update of string fields on an existing doc. */
async function clientPatch(uid: string, path: string, data: Record<string, string>): Promise<number> {
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, { stringValue: v }]));
  const mask = Object.keys(data).map((k) => `updateMask.fieldPaths=${k}`).join('&');
  const res = await fetch(`${fsBase()}/${path}?${mask}`, { method: 'PATCH', headers: auth(uid), body: JSON.stringify({ fields }) });
  await res.text();
  return res.status;
}
/** The app's search query, as a signed-in client. Returns doc ids. */
async function clientSearch(uid: string, parent: string, collectionId: string, field: string, q: string,
  limit = 20, after?: { name: string; id: string }): Promise<{ status: number; ids: string[] }> {
  const structuredQuery: any = {
    from: [{ collectionId }],
    orderBy: [{ field: { fieldPath: field }, direction: 'ASCENDING' },
      { field: { fieldPath: '__name__' }, direction: 'ASCENDING' }],
    endAt: { values: [{ stringValue: `${q}` }], before: false },
    limit,
  };
  structuredQuery.startAt = after
    ? { values: [{ stringValue: after.name }, { referenceValue: `${docsRoot}/${parent}/${collectionId}/${after.id}` }], before: false }
    : { values: [{ stringValue: q }], before: true };
  const res = await fetch(`${fsBase()}/${parent}:runQuery`, { method: 'POST', headers: auth(uid), body: JSON.stringify({ structuredQuery }) });
  const body: any = await res.json().catch(() => null);
  const ids = Array.isArray(body) ? body.filter((r) => r.document).map((r) => String(r.document.name).split('/').pop()) : [];
  return { status: res.status, ids };
}

const edge = (followee: string, follower: string) => `business_followers/${followee}/followers/${follower}`;
const mirror = (follower: string, followee: string) => `user_business_following/${follower}/businesses/${followee}`;

beforeEach(async () => {
  await clearAll();
});

describe('follow-edge names are server-only', () => {
  test('plain client follow writes work; name fields and the job queue are refused', async () => {
    await db.doc('profiles/b').set({ displayName: 'Bea' });
    await db.doc('profiles/a').set({ displayName: 'Ana' });

    expect(await clientCreate('a', edge('b', 'a'), { followerNameLower: 'forged' })).toBe(403);
    expect(await clientCreate('a', mirror('a', 'b'), { followeeNameLower: 'forged' })).toBe(403);
    expect(await clientCreate('a', mirror('a', 'b'), { followerNameLower: 'forged' })).toBe(403);
    expect(await clientCreate('a', edge('b', 'a'))).toBe(200);
    expect(await clientCreate('a', mirror('a', 'b'))).toBe(200);

    // No client update of an edge or a mirror (names cannot be changed later).
    expect(await clientPatch('a', edge('b', 'a'), { followerNameLower: 'x' })).toBe(403);
    expect(await clientPatch('a', mirror('a', 'b'), { followeeNameLower: 'x' })).toBe(403);
    // Someone else cannot touch them either.
    expect(await clientPatch('b', edge('b', 'a'), { followerNameLower: 'x' })).toBe(403);
    // The fan-out queue is server-only.
    expect(await clientCreate('a', `${FOLLOW_NAME_JOBS}/a`, { name: 'x' })).toBe(403);
    expect(await clientPatch('a', `${FOLLOW_NAME_JOBS}/a`, { name: 'x' })).toBe(403);
  });
});

describe('server stamping + prefix search', () => {
  test('stamped edges are searchable by prefix, paged, accent/case-insensitive', async () => {
    const T = 'target';
    await db.doc(`profiles/${T}`).set({ displayName: 'Tâmara' });
    const names: Record<string, string> = {
      u1: 'Maria Silva', u2: 'MARÍA José', u3: 'Mário', u4: 'Marcos', u5: 'João', u6: 'Ana Maria',
    };
    for (const [uid, displayName] of Object.entries(names)) {
      await db.doc(`profiles/${uid}`).set({ displayName });
      expect(await clientCreate(uid, edge(T, uid))).toBe(200);
      expect(await clientCreate(uid, mirror(uid, T))).toBe(200);
      await stampEdgeNames(db, T, uid);
    }
    // A legacy edge with no name yet (pre-backfill): not in search results.
    await db.doc(edge(T, 'legacy')).set({ createdAt: admin.firestore.Timestamp.now() });

    expect((await db.doc(edge(T, 'u2')).get()).get('followerNameLower')).toBe('maria jose');
    expect((await db.doc(mirror('u2', T)).get()).get('followeeNameLower')).toBe('tamara');

    const all = await clientSearch('u5', `business_followers/${T}`, 'followers', 'followerNameLower', 'mar');
    expect(all.status).toBe(200);
    expect(all.ids).toEqual(['u4', 'u2', 'u1', 'u3']); // marcos, maria jose, maria silva, mario

    // Endless loading: limit 2 + startAfter the last row.
    const p1 = await clientSearch('u5', `business_followers/${T}`, 'followers', 'followerNameLower', 'mar', 2);
    expect(p1.ids).toEqual(['u4', 'u2']);
    const p2 = await clientSearch('u5', `business_followers/${T}`, 'followers', 'followerNameLower', 'mar', 2,
      { name: 'maria jose', id: 'u2' });
    expect(p2.ids).toEqual(['u1', 'u3']);

    // Following side (mirror) of one follower.
    const f = await clientSearch('u1', 'user_business_following/u1', 'businesses', 'followeeNameLower', 'tam');
    expect(f.ids).toEqual([T]);

    // The admin SDK form the app uses (startAt/endAt/limit) works too.
    const snap = await db.collection(`business_followers/${T}/followers`)
      .orderBy('followerNameLower').startAt('jo').endAt('jo').limit(20).get();
    expect(snap.docs.map((d) => d.id)).toEqual(['u5']);
  });
});

describe('display-name fan-out', () => {
  test('a name change refreshes every edge in both directions (paged)', async () => {
    const U = 'renamed';
    await db.doc(`profiles/${U}`).set({ displayName: 'Old' });
    for (let i = 0; i < 5; i++) {
      const o = `o${i}`;
      await db.doc(`profiles/${o}`).set({ displayName: `Other ${i}` });
      // U follows o_i and o_i follows U.
      await db.doc(edge(o, U)).set({ createdAt: 1, followerNameLower: 'old' });
      await db.doc(mirror(U, o)).set({ createdAt: 1 });
      await db.doc(edge(U, o)).set({ createdAt: 1 });
      await db.doc(mirror(o, U)).set({ createdAt: 1, followeeNameLower: 'old' });
    }
    expect(await enqueueFollowNameJobIfChanged(db, U, { displayName: 'Old' }, { displayName: 'Néw Name' })).toBe(true);
    const job: any = (await db.doc(`${FOLLOW_NAME_JOBS}/${U}`).get()).data();
    let r = await followNameRound(db, U, job, { deadlineMs: Date.now() + 60_000, pageSize: 2 });
    expect(r.done).toBe(true);
    expect(r.updated).toBe(10);
    for (let i = 0; i < 5; i++) {
      expect((await db.doc(edge(`o${i}`, U)).get()).get('followerNameLower')).toBe('new name');
      expect((await db.doc(mirror(`o${i}`, U)).get()).get('followeeNameLower')).toBe('new name');
    }
    r = await followNameRound(db, U, job, { deadlineMs: Date.now() + 60_000, pageSize: 2 });
    expect(r.updated).toBe(0); // idempotent
  });
});

describe('backfill-follow-names script', () => {
  test('dry-run writes nothing; --apply fills legacy edges; resumable by cursor', async () => {
    await db.doc('profiles/x').set({ displayName: 'Xénia' });
    for (const f of ['a', 'b', 'c']) {
      await db.doc(`profiles/${f}`).set({ nickname: f.toUpperCase() });
      await db.doc(edge('x', f)).set({ createdAt: 1 });
      await db.doc(mirror(f, 'x')).set({ createdAt: 1 });
    }
    const quiet = () => undefined;
    const dry = await runFollowNameBackfill({ db, apply: false, log: quiet });
    expect(dry).toMatchObject({ scanned: 3, edgeWrites: 3, mirrorWrites: 3, done: true });
    expect((await db.doc(edge('x', 'a')).get()).get('followerNameLower')).toBeUndefined();

    const first = await runFollowNameBackfill({ db, apply: true, pageSize: 2, maxPages: 1, log: quiet });
    expect(first).toMatchObject({ scanned: 2, done: false });
    const rest = await runFollowNameBackfill({ db, apply: true, pageSize: 2, startAfter: first.cursor!, log: quiet });
    expect(rest.scanned).toBe(1);
    expect(rest.done).toBe(true);
    for (const f of ['a', 'b', 'c']) {
      expect((await db.doc(edge('x', f)).get()).get('followerNameLower')).toBe(f);
      expect((await db.doc(mirror(f, 'x')).get()).get('followeeNameLower')).toBe('xenia');
    }
    const again = await runFollowNameBackfill({ db, apply: true, log: quiet });
    expect(again).toMatchObject({ edgeWrites: 0, mirrorWrites: 0 });
  });
});
