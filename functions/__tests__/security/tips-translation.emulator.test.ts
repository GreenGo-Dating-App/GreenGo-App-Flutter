/**
 * Community tips translation (owner request 2026-10-21): the shared store
 * `translations/{id}` is written ONLY by functions (translateCommunityTips /
 * translateTexts). Clients may read a translation by id (they must already
 * know the text, the id is sha256(target \0 text)), but never list the store
 * or create / update / delete a doc, and never touch translation_quota.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules:
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "cd functions && npx jest -i --config jest.security.config.js tips-translation"
 */
import * as admin from 'firebase-admin';

/* eslint-disable @typescript-eslint/no-explicit-any */

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

function emulatorHost(): string {
  const h = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(h)) throw new Error('Refusing: not a local emulator');
  return h;
}
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const base = () => `http://${emulatorHost()}/v1/projects/${PROJECT}/databases/(default)/documents`;
const fields = (data: Record<string, string>) =>
  ({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, { stringValue: v }])) });

async function req(uid: string | null, method: string, url: string, body?: any): Promise<number> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (uid) headers.Authorization = `Bearer ${idToken(uid)}`;
  const res = await fetch(url, { method, headers, body: body ? JSON.stringify(body) : undefined });
  await res.text();
  return res.status;
}
const create = (uid: string | null, col: string, id: string, data: Record<string, string>) =>
  req(uid, 'POST', `${base()}/${col}?documentId=${id}`, fields(data));
const update = (uid: string | null, path: string, data: Record<string, string>) =>
  req(uid, 'PATCH', `${base()}/${path}?${Object.keys(data).map((k) => `updateMask.fieldPaths=${k}`).join('&')}&currentDocument.exists=true`, fields(data));
const del = (uid: string | null, path: string) => req(uid, 'DELETE', `${base()}/${path}`);
const get = (uid: string | null, path: string) => req(uid, 'GET', `${base()}/${path}`);
const list = (uid: string | null, col: string) => req(uid, 'GET', `${base()}/${col}`);

const ID = 'a'.repeat(64);

beforeAll(async () => {
  await db.doc(`translations/${ID}`).set({ target: 'it', translated: 'Ciao', source: 'en', origin: 'community_tip' });
  await db.doc('translation_quota/tips_u1_20261021').set({ count: 1, uid: 'u1' });
});

describe('translations store is server-only', () => {
  it('a signed-in user can get one translation by id', async () => {
    expect(await get('u1', `translations/${ID}`)).toBe(200);
  });

  it('anonymous get is denied', async () => {
    expect(await get(null, `translations/${ID}`)).toBe(403);
  });

  it('nobody can list the store', async () => {
    expect(await list('u1', 'translations')).toBe(403);
  });

  it('a client cannot create a translation (no planted translations)', async () => {
    expect(await create('u1', 'translations', 'b'.repeat(64),
      { target: 'it', translated: 'planted', origin: 'community_tip' })).toBe(403);
    expect((await db.doc(`translations/${'b'.repeat(64)}`).get()).exists).toBe(false);
  });

  it('a client cannot overwrite or delete a stored translation', async () => {
    expect(await update('u1', `translations/${ID}`, { translated: 'hacked' })).toBe(403);
    expect(await del('u1', `translations/${ID}`)).toBe(403);
    expect((await db.doc(`translations/${ID}`).get()).data()?.translated).toBe('Ciao');
  });

  it('translation_quota is neither readable nor writable by clients', async () => {
    expect(await get('u1', 'translation_quota/tips_u1_20261021')).toBe(403);
    expect(await update('u1', 'translation_quota/tips_u1_20261021', { count: '0' })).toBe(403);
    expect(await create('u1', 'translation_quota', 'tips_u1_20991231', { uid: 'u1' })).toBe(403);
  });
});
