/**
 * INC-2026-001 / E5: support chats and their messages are readable only by the
 * ticket owner and staff (they used to be readable by any signed-in user).
 * Exercises the deployed rules through the emulator REST API as real clients.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';

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
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;

async function read(uid: string, path: string): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { headers: { Authorization: `Bearer ${idToken(uid)}` } });
  await res.text();
  return res.status;
}
/** Runs the same query the app uses: support_messages where conversationId == X. */
async function queryMessages(uid: string, conversationId: string): Promise<number> {
  const res = await fetch(`${base()}:runQuery`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: {
      from: [{ collectionId: 'support_messages' }],
      where: { fieldFilter: { field: { fieldPath: 'conversationId' }, op: 'EQUAL', value: { stringValue: conversationId } } },
    } }),
  });
  await res.text();
  return res.status;
}
async function queryOwnChats(uid: string, whereUid: string): Promise<number> {
  const res = await fetch(`${base()}:runQuery`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: {
      from: [{ collectionId: 'support_chats' }],
      where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: whereUid } } },
    } }),
  });
  await res.text();
  return res.status;
}

const OWNER = 'owner01';
const STRANGER = 'stranger01';
const STAFF = 'staff01';

beforeEach(async () => {
  await clearAll();
  await db.doc('support_chats/c1').set({ userId: OWNER, subject: 'Help', status: 'open' });
  await db.doc('support_messages/m1').set({ conversationId: 'c1', senderId: OWNER, content: 'private text' });
  await db.doc(`admin_users/${STAFF}`).set({ role: 'moderator' });
});

test('owner can read their support chat, its messages and query their own chats', async () => {
  expect(await read(OWNER, 'support_chats/c1')).toBe(200);
  expect(await read(OWNER, 'support_messages/m1')).toBe(200);
  expect(await queryMessages(OWNER, 'c1')).toBe(200);
  expect(await queryOwnChats(OWNER, OWNER)).toBe(200);
});

test('another signed-in user can NOT read someone else\'s support chat or messages', async () => {
  expect(await read(STRANGER, 'support_chats/c1')).toBe(403);
  expect(await read(STRANGER, 'support_messages/m1')).toBe(403);
  expect(await queryMessages(STRANGER, 'c1')).toBe(403);
  expect(await queryOwnChats(STRANGER, OWNER)).toBe(403);
});

test('staff (admin panel users) can read support chats and messages', async () => {
  expect(await read(STAFF, 'support_chats/c1')).toBe(200);
  expect(await read(STAFF, 'support_messages/m1')).toBe(200);
  expect(await queryMessages(STAFF, 'c1')).toBe(200);
});
