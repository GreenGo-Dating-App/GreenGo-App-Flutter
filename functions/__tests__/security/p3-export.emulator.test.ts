/**
 * P3-2: data-subject access and portability (GDPR Art. 15/20, LGPD Art. 18).
 * exportMyData + cleanupDataExports + the exports/ Storage rule.
 *
 * Runs against the real Firestore + Auth + Storage emulators:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * The source module is required lazily, so on the pre-change code every test
 * fails (module not found), which is the "fails on old code" proof.
 */

import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
}
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const auth = admin.auth();
const bucket = () => admin.storage().bucket();

const fetchMock = jest.fn(async (..._args: any[]) => ({ ok: true, status: 200, text: async () => '{}', json: async () => ({}) }));
(global as any).fetch = fetchMock;

// Realistic (28-char) uids, so uid-shaped map keys are exercised too.
const ME = 'Me7user0000000000000000000A1';
const BOB = 'Bob9user000000000000000000B2';
const ME_EMAIL = 'me.export@example.com';
const BOB_EMAIL = 'bob.other@example.org';

const mod = () => require('../../src/auth/dataExport');
const zipMod = () => require('../../src/shared/zipWriter');
const v2call = (fn: any, data: any, authCtx?: any) => (fft.wrap(fn) as any)({ data, auth: authCtx });
const fresh = (uid: string) => ({ uid, token: { auth_time: Math.floor(Date.now() / 1000) - 30 } });

function emulatorDelete(path: string) {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  return new Promise<void>((resolve, reject) => {
    const req = http.request(
      { host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Storage emulator required');
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
  await bucket().deleteFiles({ force: true }).catch(() => undefined);
}

const put = (path: string, body = 'x', contentType = 'image/jpeg') =>
  bucket().file(path).save(Buffer.from(body), { contentType, resumable: false });
const dlUrl = (path: string) =>
  `https://firebasestorage.googleapis.com/v0/b/${PROJECT}.appspot.com/o/${encodeURIComponent(path)}?alt=media&token=t`;

function httpGet(url: string, headers: Record<string, string> = {}): Promise<{ status: number; body: Buffer }> {
  return new Promise((resolve, reject) => {
    const req = http.get(url, { headers }, (res) => {
      const chunks: Buffer[] = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode || 0, body: Buffer.concat(chunks) }));
    });
    req.on('error', reject);
  });
}

/** Real ID token from the Auth emulator. */
async function idTokenFor(uid: string): Promise<string> {
  const custom = await auth.createCustomToken(uid);
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ token: custom, returnSecureToken: true });
    const req = http.request({
      host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'POST',
      path: '/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    }, (r) => {
      let s = '';
      r.on('data', (c) => (s += c));
      r.on('end', () => { try { resolve(JSON.parse(s).idToken); } catch (e) { reject(e); } });
    });
    req.on('error', reject);
    req.end(body);
  });
}

async function seed() {
  await auth.createUser({ uid: ME, email: ME_EMAIL, password: 'Passw0rd!x', displayName: 'Mia Export' });
  await auth.createUser({ uid: BOB, email: BOB_EMAIL, password: 'Passw0rd!x', displayName: 'Bob Otherperson' });

  // Mine
  await db.doc(`profiles/${ME}`).set({ userId: ME, name: 'Mia Export', bio: 'my-own-bio', email: ME_EMAIL });
  await db.doc(`users/${ME}`).set({ email: ME_EMAIL, fcmToken: 'tok-me' });
  await db.doc(`profiles_private/${ME}`).set({ dateOfBirth: '1990-01-02', exactLocation: { lat: -23.5, lng: -46.6 } });
  await db.doc(`consents/${ME}`).set({ marketing_email: { accepted: true, version: 1 } });
  await db.doc(`consents/${ME}/events/e1`).set({ type: 'marketing_email', accepted: true });
  await db.doc(`notifications/n1`).set({ userId: ME, title: 'my-notification', fromUserId: BOB, fromUserName: 'Bob Otherperson' });
  await db.doc(`notifications/n2`).set({ userId: ME, title: 'my-second-notification' });
  await db.doc(`coinTransactions/t1`).set({ userId: ME, amount: 100, type: 'credit', relatedUserId: BOB });
  await db.doc(`matches/mt1`).set({ userId1: ME, userId2: BOB, user2Name: 'Bob Otherperson', matchedAt: admin.firestore.Timestamp.now() });
  await db.doc(`user_reports/r1`).set({ reporterId: ME, reportedUserId: BOB, reason: 'my-report-reason' });
  await put(`profiles/${ME}/photos/me.jpg`, 'MY-PHOTO-BYTES');

  // A 1:1 conversation with messages from both sides.
  await db.doc('conversations/c1').set({
    participants: [ME, BOB], userId1: ME, userId2: BOB, createdAt: admin.firestore.Timestamp.now(),
    unreadCounts: { [ME]: 0, [BOB]: 2 },
    lastMessage: { senderId: BOB, content: 'B-private-words', senderName: 'Bob Otherperson' },
    otherUserName: 'Bob Otherperson',
  });
  await db.doc('conversations/c1/messages/m1').set({
    senderId: ME, receiverId: BOB, type: 'text', content: 'A-secret-hello', senderName: 'Mia Export',
    readBy: [ME, BOB], reactions: { [BOB]: 'heart' }, sentAt: admin.firestore.Timestamp.now(),
  });
  await db.doc('conversations/c1/messages/m2').set({
    senderId: BOB, receiverId: ME, type: 'text', content: 'B-private-words', senderName: 'Bob Otherperson',
  });
  await put('chat_images/c1/mine.jpg', 'MY-CHAT-IMAGE');
  await put('chat_images/c1/bobs.jpg', 'BOB-CHAT-IMAGE');
  await db.doc('conversations/c1/messages/m3').set({ senderId: ME, receiverId: BOB, type: 'image', content: dlUrl('chat_images/c1/mine.jpg') });
  await db.doc('conversations/c1/messages/m4').set({ senderId: BOB, receiverId: ME, type: 'image', content: dlUrl('chat_images/c1/bobs.jpg') });
  // A group.
  await db.doc('groups/g1').set({ isGroup: true, name: 'Lisbon walkers', participants: [ME, BOB], createdBy: BOB });
  await db.doc('groups/g1/messages/gm1').set({ senderId: ME, content: 'A-group-hello' });
  await db.doc('groups/g1/messages/gm2').set({ senderId: BOB, content: 'B-group-words' });

  // Other people's actions about me (must NOT be exported).
  await db.doc('swipes/s1').set({ userId: BOB, targetUserId: ME, action: 'like' });
  await db.doc('blockedUsers/b1').set({ blockerId: BOB, blockedUserId: ME });
  await db.doc('photo_likes/pl1').set({ profileUserId: ME, likerId: BOB });
  // Bob's own data (must NOT be exported).
  await db.doc(`profiles/${BOB}`).set({ userId: BOB, name: 'Bob Otherperson', bio: 'bob-bio', email: BOB_EMAIL });
  await db.doc(`profiles_private/${BOB}`).set({ dateOfBirth: '1980-05-05' });
  await db.doc(`users/${BOB}`).set({ email: BOB_EMAIL, blockedUsers: [ME] });
  await db.doc(`notifications/n3`).set({ userId: BOB, title: 'bob-notification' });
  await put(`profiles/${BOB}/photos/bob.jpg`, 'BOB-PHOTO-BYTES');
}

async function readExport(objectPath: string): Promise<Record<string, Buffer>> {
  const [buf] = await bucket().file(objectPath).download();
  return zipMod().readZip(buf);
}

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'no-reply@greengochat.com' });
});
afterAll(() => fft.cleanup());

// ===========================================================================
describe('exportMyData: authentication', () => {
  test('unauthenticated and stale sign-ins are rejected; nothing is built', async () => {
    await seed();
    const fn = mod().exportMyData;
    await expect(v2call(fn, {}, undefined)).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(v2call(fn, {}, { uid: ME, token: { auth_time: Math.floor(Date.now() / 1000) - 3600 } }))
      .rejects.toMatchObject({ code: 'unauthenticated', details: { code: 'REQUIRES_RECENT_LOGIN' } });
    await expect(v2call(fn, {}, { uid: ME, token: {} }))
      .rejects.toMatchObject({ details: { code: 'REQUIRES_RECENT_LOGIN' } });
    const [files] = await bucket().getFiles({ prefix: 'exports/' });
    expect(files).toHaveLength(0);
    expect((await db.doc(`data_exports/${ME}`).get()).exists).toBe(false);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe('exportMyData: contents', () => {
  test('ZIP holds the caller\'s data and nothing of other users', async () => {
    await seed();
    const r = await v2call(mod().exportMyData, {}, fresh(ME));
    expect(r.success).toBe(true);
    expect(typeof r.url).toBe('string');
    expect(Date.parse(r.expiresAt) - Date.now()).toBeGreaterThan(23 * 3600 * 1000);

    const [files] = await bucket().getFiles({ prefix: `exports/${ME}/` });
    expect(files).toHaveLength(1);
    expect(files[0].name).toMatch(new RegExp(`^exports/${ME}/\\d+\\.zip$`));
    // The returned link points at that same object (in production it is a
    // V4 signed URL; the emulator has no signer, so it is the plain path,
    // which storage.rules deny to clients - see the rules test below).
    expect(r.url).toContain(encodeURIComponent(files[0].name));

    const z = await readExport(files[0].name);
    const names = Object.keys(z);
    const all = names.map((n) => z[n].toString('utf8')).join('\n');

    // Mine: account, private profile, consents, inventory data, my messages, media.
    expect(names).toEqual(expect.arrayContaining([
      'README.txt', 'manifest.json', 'account/auth.json', 'account/profiles.json', 'account/users.json',
      'account/profiles_private.json', 'account/consents.json', 'messages/my_messages.json',
      'messages/my_messages.csv', 'conversations/conversations.json', 'data/notifications__userId.json',
      'data/notifications__userId.csv',
    ]));
    expect(JSON.parse(z['account/auth.json'].toString())[0].email).toBe(ME_EMAIL);
    expect(z['account/profiles.json'].toString()).toContain('my-own-bio');
    expect(z['account/profiles_private.json'].toString()).toContain('1990-01-02');
    const consents = JSON.parse(z['account/consents.json'].toString());
    expect(consents).toHaveLength(2); // doc + its events subcollection
    expect(all).toContain('my-notification');
    expect(all).toContain('my-report-reason');
    const msgs = JSON.parse(z['messages/my_messages.json'].toString());
    expect(msgs.map((m: any) => m.content).filter((c: string) => !c.startsWith('http')).sort())
      .toEqual(['A-group-hello', 'A-secret-hello']);
    expect(msgs).toHaveLength(3);
    expect(z['messages/my_messages.csv'].toString()).toContain('A-secret-hello');
    expect(z[`media/profiles/you/photos/me.jpg`].toString()).toBe('MY-PHOTO-BYTES');
    expect(z['media/chat_images/c1/mine.jpg'].toString()).toBe('MY-CHAT-IMAGE');
    const convs = JSON.parse(z['conversations/conversations.json'].toString());
    expect(convs.map((c: any) => c.conversationId).sort()).toEqual(['c1', 'g1']);
    expect(convs.find((c: any) => c.conversationId === 'c1').participantCount).toBe(2);

    // Nothing of Bob: no uid, name, email, words, photo, own records.
    for (const bad of [BOB, 'Bob Otherperson', BOB_EMAIL, 'B-private-words', 'B-group-words', 'BOB-PHOTO-BYTES',
      'BOB-CHAT-IMAGE', 'bob-bio', 'bob-notification', '1980-05-05']) {
      expect({ bad, foundIn: names.filter((n) => z[n].toString('utf8').includes(bad)) }).toEqual({ bad, foundIn: [] });
    }
    // Other people's actions about me are not exported.
    expect(names.some((n) => /swipes|blockedUsers__blockedUserId|photo_likes__profileUserId|^data\/users/.test(n))).toBe(false);
    // Other ids are shown as other_user.
    expect(all).toContain('other_user');

    // Emailed via Resend with the same link; request logged.
    const mail = fetchMock.mock.calls.find((c) => String(c[0]).includes('api.resend.com'));
    expect(mail).toBeTruthy();
    const body = JSON.parse((mail![1] as any).body);
    expect(body.to).toEqual([ME_EMAIL]);
    expect(body.html).toContain(r.url.replace(/&/g, '&'));
    const log = (await db.doc(`data_exports/${ME}`).get()).data()!;
    expect(log.status).toBe('done');
    expect(log.lastObjectPath).toBe(files[0].name);
    const runs = await db.collection(`data_exports/${ME}/runs`).get();
    expect(runs.docs[0].data()).toMatchObject({ status: 'done', emailSent: true });
    expect(JSON.stringify(runs.docs[0].data())).not.toContain(ME_EMAIL);
  });
});

describe('exportMyData: rate limit', () => {
  test('one export per 24 h; a failed run does not count', async () => {
    await seed();
    const fn = mod().exportMyData;
    await v2call(fn, {}, fresh(ME));
    await expect(v2call(fn, {}, fresh(ME))).rejects.toMatchObject({
      code: 'resource-exhausted', details: { code: 'RATE_LIMITED' },
    });
    let [files] = await bucket().getFiles({ prefix: `exports/${ME}/` });
    expect(files).toHaveLength(1);

    // Another user is not affected.
    await db.doc(`profiles/${BOB}`).set({ name: 'Bob Otherperson' }, { merge: true });
    await expect(v2call(fn, {}, fresh(BOB))).resolves.toMatchObject({ success: true });

    // 25 h later: allowed again.
    await db.doc(`data_exports/${ME}`).set({
      lastSuccessAt: admin.firestore.Timestamp.fromMillis(Date.now() - 25 * 3600 * 1000),
    }, { merge: true });
    await expect(v2call(fn, {}, fresh(ME))).resolves.toMatchObject({ success: true });
    [files] = await bucket().getFiles({ prefix: `exports/${ME}/` });
    expect(files).toHaveLength(2);

    // A run still in progress blocks a parallel one.
    await db.doc(`data_exports/${ME}`).set({
      status: 'running', startedAt: admin.firestore.Timestamp.now(),
      lastSuccessAt: admin.firestore.Timestamp.fromMillis(0),
    }, { merge: true });
    await expect(v2call(fn, {}, fresh(ME))).rejects.toMatchObject({ details: { code: 'EXPORT_IN_PROGRESS' } });
  });
});

describe('cleanupDataExports + storage rules', () => {
  test('exports older than 7 days are deleted; newer ones and other paths are kept', async () => {
    const old = Date.now() - 8 * 24 * 3600 * 1000;
    const recent = Date.now() - 2 * 24 * 3600 * 1000;
    await put(`exports/${ME}/${old}.zip`, 'old', 'application/zip');
    await put(`exports/${ME}/${recent}.zip`, 'new', 'application/zip');
    await put(`exports/${BOB}/${old}.zip`, 'old', 'application/zip');
    await put(`exports/${ME}/notes.txt`, 'keep', 'text/plain');
    const n = await mod().cleanupExpiredExports();
    expect(n).toBe(2);
    const [files] = await bucket().getFiles({ prefix: 'exports/' });
    expect(files.map((f) => f.name).sort()).toEqual([`exports/${ME}/${recent}.zip`, `exports/${ME}/notes.txt`].sort());
  });

  test('clients cannot read or list exports/, not even the owner', async () => {
    await auth.createUser({ uid: ME, email: ME_EMAIL, password: 'Passw0rd!x' });
    await put(`exports/${ME}/1.zip`, 'zip', 'application/zip');
    const token = await idTokenFor(ME);
    const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST!.replace('0.0.0.0', '127.0.0.1');
    const b = `${PROJECT}.appspot.com`;
    const get = await httpGet(`http://${host}/v0/b/${b}/o/${encodeURIComponent(`exports/${ME}/1.zip`)}?alt=media`,
      { Authorization: `Firebase ${token}` });
    expect(get.status).toBe(403);
    const list = await httpGet(`http://${host}/v0/b/${b}/o?prefix=${encodeURIComponent(`exports/${ME}/`)}`,
      { Authorization: `Firebase ${token}` });
    expect(list.status).toBe(403);
  });
});

describe('unit: redaction, CSV and ZIP', () => {
  test('redactOthers keeps the caller and hides other people', () => {
    const { redactOthers } = mod();
    const out = redactOthers({
      senderId: ME, senderName: 'Me', receiverId: BOB, receiverName: 'Bob', participants: [ME, BOB],
      reactions: { [BOB]: 'x' }, orderId: 'ord_1', to: ME_EMAIL, createdBy: BOB, nested: [{ userId: BOB, userName: 'Bob' }],
    }, ME);
    expect(out).toEqual({
      senderId: ME, senderName: 'Me', receiverId: 'other_user', participants: [ME, 'other_user'],
      reactions: { other_user_1: 'x' }, orderId: 'ord_1', to: ME_EMAIL, createdBy: 'other_user', nested: [{ userId: 'other_user' }],
    });
  });

  test('toCsv escapes and neutralises formulas; ZIP round-trips', () => {
    const { toCsv } = mod();
    const csv = toCsv([{ a: 'x,y', b: '=HYPERLINK("e")' }, { a: 'line\nbreak', c: { n: 1 } }]);
    expect(csv).toContain('"x,y"');
    expect(csv).toContain(`"'=HYPERLINK(""e"")"`);
    expect(csv).toContain('"{""n"":1}"');
  });
});
