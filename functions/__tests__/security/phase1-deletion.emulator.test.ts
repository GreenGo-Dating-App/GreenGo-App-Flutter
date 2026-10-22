/**
 * Phase 1 / P1-10: working account deletion (audit H-15; Play account-deletion
 * policy, Apple 5.1.1(v), GDPR Art. 17, LGPD Art. 18).
 *
 * Runs against the real Firestore + Auth + Storage emulators:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Source modules are required lazily (inside the describes) so the trigger
 * tests can also run against the pre-change code (proof that they catch the
 * old behaviour: financial records deleted instead of retained, etc.).
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
const BACKUP_BUCKET = process.env.BACKUP_BUCKET || 'greengo-chat-backups';

const fetchMock = jest.fn(async (..._args: any[]) => ({ ok: true, status: 200, text: async () => '{}', json: async () => ({}) }));
(global as any).fetch = fetchMock;

process.env.DELETION_MIN_RESPONSE_MS = '0';

// ---------------------------------------------------------------------------
// helpers

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
  for (const b of [bucket(), admin.storage().bucket(BACKUP_BUCKET)]) {
    await b.deleteFiles({ force: true }).catch(() => undefined);
  }
}

const put = (path: string, b = bucket()) =>
  b.file(path).save(Buffer.from('x'), { contentType: 'image/jpeg', resumable: false });
const exists = async (path: string, b = bucket()) => (await b.file(path).exists())[0];
const dlUrl = (path: string) =>
  `https://firebasestorage.googleapis.com/v0/b/${PROJECT}.appspot.com/o/${encodeURIComponent(path)}?alt=media&token=t`;
const docExists = async (p: string) => (await db.doc(p).get()).exists;
const authExists = (uid: string) => auth.getUser(uid).then(() => true, () => false);

function mockRes() {
  const r: any = {
    statusCode: 0, headers: {} as Record<string, string>, body: undefined,
    status(c: number) { this.statusCode = c; return this; },
    json(b: any) { this.body = b; return this; },
    send(b: any) { this.body = b; return this; },
    set(k: string, v: string) { this.headers[k.toLowerCase()] = v; return this; },
    type(t: string) { this.headers['content-type'] = t; return this; },
  };
  return r;
}
function mockReq(o: { method?: string; origin?: string | null; body?: any; query?: any; ip?: string; headers?: any } = {}) {
  const headers: any = { ...(o.headers || {}) };
  if (o.origin !== null) headers.origin = o.origin ?? 'https://www.greengochat.com';
  return { method: o.method ?? 'POST', headers, body: o.body ?? {}, query: o.query ?? {}, ip: o.ip ?? '203.0.113.7' } as any;
}

async function newUser(uid: string, email: string) {
  await auth.createUser({ uid, email, password: 'Passw0rd!x' });
  await db.doc(`profiles/${uid}`).set({ name: `Name ${uid}`, email, nickname: uid });
  await db.doc(`users/${uid}`).set({ email, fcmToken: 'tok' });
}

/** Real ID token from the Auth emulator (auth_time = now). */
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
      r.on('end', () => {
        try { resolve(JSON.parse(s).idToken); } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.end(body);
  });
}

function sentLinkToken(): string {
  const call = fetchMock.mock.calls.find((c) => String(c[0]).includes('api.resend.com'));
  if (!call) throw new Error('no email sent');
  const html = JSON.parse((call[1] as any).body).html as string;
  const m = html.match(/confirmAccountDeletion\?token=([A-Za-z0-9_\-%]+)/);
  if (!m) throw new Error('no link in email');
  return decodeURIComponent(m[1]);
}

const v2call = (fn: any, data: any, authCtx?: any) => (fft.wrap(fn) as any)({ data, auth: authCtx });

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'no-reply@greengochat.com' });
});
afterAll(() => fft.cleanup());

// ===========================================================================
describe('website: requestAccountDeletion / confirmAccountDeletion', () => {
  const ep = () => require('../../src/auth/accountDeletionEndpoints');
  const request = async (body: any, extra: any = {}) => {
    const res = mockRes();
    await ep().handleRequestAccountDeletion(mockReq({ body, ...extra }), res);
    return res;
  };

  test('known and unknown email get the identical response; only a real account gets an email', async () => {
    await newUser('web1', 'web1@example.com');
    const known = await request({ email: 'Web1@Example.com ', password: 'whatever' });
    const unknown = await request({ email: 'nobody@example.com', password: 'whatever' });
    expect(known.statusCode).toBe(200);
    expect({ s: known.statusCode, b: known.body }).toEqual({ s: unknown.statusCode, b: unknown.body });
    expect(known.body.success).toBe(true);
    const mails = fetchMock.mock.calls.filter((c) => String(c[0]).includes('api.resend.com'));
    expect(mails).toHaveLength(1);
    expect(JSON.parse((mails[0][1] as any).body).to).toEqual(['web1@example.com']);
    // Only the token HASH is stored; the account is untouched.
    const token = sentLinkToken();
    const reqs = await db.collection('deletion_requests').get();
    expect(reqs.size).toBe(1);
    expect(reqs.docs[0].id).not.toBe(token);
    expect(JSON.stringify(reqs.docs[0].data())).not.toContain(token);
    expect(reqs.docs[0].data()).toMatchObject({ uid: 'web1', used: false });
    expect(await authExists('web1')).toBe(true);
    // The password is never stored anywhere.
    expect(JSON.stringify(reqs.docs[0].data())).not.toContain('whatever');
  });

  test('CORS: greengochat.com preflight allowed, foreign origin refused', async () => {
    const pre = mockRes();
    await ep().handleRequestAccountDeletion(mockReq({ method: 'OPTIONS', origin: 'https://greengochat.com' }), pre);
    expect(pre.statusCode).toBe(204);
    expect(pre.headers['access-control-allow-origin']).toBe('https://greengochat.com');
    await newUser('web2', 'web2@example.com');
    const evil = await request({ email: 'web2@example.com' }, { origin: 'https://evil.example' });
    expect(evil.statusCode).toBe(403);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('link: GET has no side effect, POST deletes, reuse is rejected', async () => {
    await newUser('web3', 'web3@example.com');
    await put('profiles/web3/photos/1.jpg');
    await request({ email: 'web3@example.com', password: 'x' });
    const token = sentLinkToken();

    const get = mockRes();
    await ep().handleConfirmAccountDeletion(mockReq({ method: 'GET', origin: null, query: { token } }), get);
    expect(get.statusCode).toBe(200);
    expect(get.body).toContain('<form method="POST"');
    expect(get.body).not.toContain('web3@example.com');
    expect(await authExists('web3')).toBe(true);

    const post = mockRes();
    await ep().handleConfirmAccountDeletion(mockReq({ method: 'POST', origin: null, body: { token } }), post);
    expect(post.statusCode).toBe(200);
    expect(post.body).toContain('Account deleted');
    expect(post.body).not.toContain('web3');
    expect(await authExists('web3')).toBe(false);
    expect(await docExists('profiles/web3')).toBe(false);
    expect(await exists('profiles/web3/photos/1.jpg')).toBe(false);
    expect(await docExists('deletion_receipts/web3')).toBe(true);

    const again = mockRes();
    await ep().handleConfirmAccountDeletion(mockReq({ method: 'POST', origin: null, body: { token } }), again);
    expect(again.statusCode).toBe(410);
  });

  test('expired or forged link is rejected and the account stays', async () => {
    await newUser('web4', 'web4@example.com');
    await request({ email: 'web4@example.com' });
    const token = sentLinkToken();
    const reqDoc = (await db.collection('deletion_requests').get()).docs[0];
    await reqDoc.ref.update({ expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() - 1000) });
    for (const t of [token, 'A'.repeat(43)]) {
      const r = mockRes();
      await ep().handleConfirmAccountDeletion(mockReq({ method: 'POST', origin: null, body: { token: t } }), r);
      expect(r.statusCode).toBe(410);
    }
    expect(await authExists('web4')).toBe(true);
    expect(await docExists('profiles/web4')).toBe(true);
  });

  test('rate limit: 3/hour per email, 5/hour per IP', async () => {
    await newUser('web5', 'web5@example.com');
    const codes: number[] = [];
    for (let i = 0; i < 4; i++) codes.push((await request({ email: 'web5@example.com' }, { ip: `198.51.100.${i}` })).statusCode);
    expect(codes).toEqual([200, 200, 200, 429]);
    const ipCodes: number[] = [];
    for (let i = 0; i < 6; i++) ipCodes.push((await request({ email: `x${i}@example.com` }, { ip: '192.0.2.1' })).statusCode);
    expect(ipCodes).toEqual([200, 200, 200, 200, 200, 429]);
    // Rate-limit docs hold no raw email / IP.
    const rl = await db.collection('deletion_rate_limits').get();
    expect(JSON.stringify(rl.docs.map((d) => [d.id, d.data()]))).not.toMatch(/example\.com|192\.0\.2\.1/);
  });

  test('signed-in mode: a fresh ID token deletes immediately', async () => {
    await newUser('web6', 'web6@example.com');
    const idToken = await idTokenFor('web6');
    const r = await request({}, { headers: { authorization: `Bearer ${idToken}` } });
    expect(r.statusCode).toBe(200);
    expect(r.body).toMatchObject({ success: true, status: 'deleted' });
    expect(await authExists('web6')).toBe(false);
    expect(await docExists('profiles/web6')).toBe(false);
  });
});

// ===========================================================================
describe('app: deleteMyAccount callable', () => {
  const fn = () => require('../../src/auth/accountDeletionEndpoints').deleteMyAccount;
  const fresh = (uid: string) => ({ uid, token: { auth_time: Math.floor(Date.now() / 1000) - 30 } });

  test('stale sign-in (auth_time > 10 min) is rejected and nothing is deleted', async () => {
    await newUser('app1', 'app1@example.com');
    await expect(v2call(fn(), {}, { uid: 'app1', token: { auth_time: Math.floor(Date.now() / 1000) - 3600 } }))
      .rejects.toMatchObject({ code: 'unauthenticated', details: { code: 'REQUIRES_RECENT_LOGIN' } });
    await expect(v2call(fn(), {}, undefined)).rejects.toMatchObject({ code: 'unauthenticated' });
    expect(await authExists('app1')).toBe(true);
    expect(await docExists('profiles/app1')).toBe(true);
  });

  test('success removes Firestore + Storage + Auth, keeps money rows pseudonymised, anonymises sent messages', async () => {
    await newUser('app2', 'app2@example.com');
    await newUser('peer', 'peer@example.com');
    await put('profiles/app2/photos/a.jpg');
    await put('voice_intros/app2/v.m4a');
    await put('chat_images/match1/img.jpg');
    await db.doc('conversations/c1').set({ userId1: 'app2', userId2: 'peer', matchId: 'match1', unreadCounts: { app2: 1, peer: 0 }, lastMessage: { senderId: 'app2', content: 'hi' } });
    await db.doc('conversations/c1/messages/m1').set({ senderId: 'app2', receiverId: 'peer', type: 'image', content: dlUrl('chat_images/match1/img.jpg'), senderName: 'Name app2' });
    const sentAt = admin.firestore.Timestamp.fromMillis(1760000000000);
    await db.doc('conversations/c1/messages/m2').set({
      senderId: 'app2', receiverId: 'peer', type: 'text', content: 'hello', sentAt,
      translatedContent: 'ola', translations: { pt: 'ola', it: 'ciao' }, detectedLanguage: 'en',
    });
    await db.doc('conversations/c1/messages/m3').set({ senderId: 'peer', receiverId: 'app2', type: 'text', content: 'hey' });
    await db.doc('purchaseLedger/tokhash').set({ userId: 'app2', productId: 'greengo_coins_100', amount: 4.99, currency: 'USD', email: 'app2@example.com', displayName: 'Name app2', createdAt: admin.firestore.Timestamp.now() });
    await db.doc('coinTransactions/t1').set({ userId: 'app2', type: 'credit', amount: 100, reason: 'purchase', note: 'free text' });
    await db.doc('coinBalances/app2').set({ userId: 'app2', totalCoins: 100 });
    await db.doc('stripe_customers/app2').set({ customerId: 'cus_123', email: 'app2@example.com' });

    const r = await v2call(fn(), {}, fresh('app2'));
    expect(r).toEqual({ success: true, status: 'deleted' });

    expect(await authExists('app2')).toBe(false);
    for (const p of ['profiles/app2', 'users/app2', 'coinBalances/app2', 'purchaseLedger/tokhash', 'coinTransactions/t1', 'stripe_customers/app2']) {
      expect([p, await docExists(p)]).toEqual([p, false]);
    }
    expect(await exists('profiles/app2/photos/a.jpg')).toBe(false);
    expect(await exists('voice_intros/app2/v.m4a')).toBe(false);
    expect(await exists('chat_images/match1/img.jpg')).toBe(false);

    // Financial: minimal pseudonymised copies.
    const fin = await db.collection('retention_finance').get();
    expect(fin.size).toBe(4);
    const blob = JSON.stringify(fin.docs.map((d) => d.data()));
    expect(blob).not.toMatch(/app2|example\.com|Name |free text|cus_123/);
    const ledger = fin.docs.find((d) => d.id === 'purchaseLedger__tokhash')!.data();
    expect(ledger).toMatchObject({ productId: 'greengo_coins_100', amount: 4.99, currency: 'USD', sourceCollection: 'purchaseLedger' });
    expect(ledger.uidHash).toMatch(/^[0-9a-f]{64}$/);

    // Other party keeps the conversation, without the deleted user's identity/media.
    const conv = (await db.doc('conversations/c1').get()).data()!;
    expect(conv.userId2).toBe('peer');
    expect(conv.userId1).toBe('deleted_user');
    expect(conv.unreadCounts).toEqual({ peer: 0 });
    const m1 = (await db.doc('conversations/c1/messages/m1').get()).data()!;
    expect(m1).toMatchObject({ senderId: 'deleted_user', type: 'text', content: '', mediaRemoved: true });
    expect(m1.senderName).toBeUndefined();
    expect(m1.deletedAuthor).toBe(true);
    // Owner decision: the deleted user's words are gone (body + translations),
    // the placeholder keeps its timestamp so the conversation order holds.
    const m2 = (await db.doc('conversations/c1/messages/m2').get()).data()!;
    expect(m2).toMatchObject({ senderId: 'deleted_user', type: 'text', content: '', deletedAuthor: true });
    expect(m2.sentAt.toMillis()).toBe(sentAt.toMillis());
    expect(m2.translatedContent).toBeUndefined();
    expect(m2.translations).toBeUndefined();
    expect(JSON.stringify(m2)).not.toMatch(/hello|ola|ciao/);
    expect(conv.lastMessage).toMatchObject({ senderId: 'deleted_user', content: '', deletedAuthor: true });
    expect((await db.doc('conversations/c1/messages/m3').get()).data()).toMatchObject({ senderId: 'peer', content: 'hey' });
    expect(await authExists('peer')).toBe(true);
    expect(await docExists('profiles/peer')).toBe(true);

    // Follow-ups queued, not executed.
    expect((await db.doc('deletion_followups/app2').get()).data()).toMatchObject({ stripeCustomerId: 'cus_123', analytics: true, status: 'pending' });
    expect(fetchMock).not.toHaveBeenCalled();
    expect((await db.doc('deletion_receipts/app2').get()).data()).toMatchObject({ source: 'app_callable', failures: [] });
    expect(await docExists('deletion_jobs/app2')).toBe(false);
  });

  test('legal proof (consents + warning confirmations) is retained and stamped, not deleted', async () => {
    await newUser('app3', 'app3@example.com');
    await db.doc('consents/app3').set({ terms: { accepted: true, version: 1, docVersion: '5.1.0' } });
    await db.doc('consents/app3/events/e1').set({ type: 'terms', accepted: true, docVersion: '5.1.0' });
    await db.doc('legal_acknowledgements/app3/items/w1').set({ type: 'private_content_warning', termsVersion: '5.1.0' });

    expect(await v2call(fn(), {}, fresh('app3'))).toEqual({ success: true, status: 'deleted' });
    expect(await authExists('app3')).toBe(false);
    expect(await docExists('profiles/app3')).toBe(false);

    for (const p of ['consents/app3', 'consents/app3/events/e1', 'legal_acknowledgements/app3/items/w1']) {
      expect([p, await docExists(p)]).toEqual([p, true]);
    }
    const c = (await db.doc('consents/app3').get()).data()!;
    expect(c.terms.docVersion).toBe('5.1.0');
    const years = (c.legalRetention.retainUntil.toMillis() - c.legalRetention.accountDeletedAt.toMillis()) / (365.25 * 86400000);
    expect(Math.round(years)).toBe(5);
    const a = (await db.doc('legal_acknowledgements/app3').get()).data()!;
    expect(a.legalRetention.retainUntil.toMillis()).toBe(c.legalRetention.retainUntil.toMillis());

    // A later sweep (Auth trigger) keeps the first dates.
    const { markLegalRecordsRetained } = require('../../src/auth/accountDeletion');
    await markLegalRecordsRetained('app3', Date.now() + 86400000);
    const again = (await db.doc('consents/app3').get()).data()!;
    expect(again.legalRetention.retainUntil.toMillis()).toBe(c.legalRetention.retainUntil.toMillis());
  });

  test('a failing step leaves the account intact (Auth deleted last); retry completes', async () => {
    await newUser('app3', 'app3@example.com');
    await put('profiles/app3/photos/a.jpg');
    const proto = Object.getPrototypeOf(bucket());
    const spy = jest.spyOn(proto, 'getFiles').mockImplementation(async () => { throw new Error('storage down'); });
    await expect(v2call(fn(), {}, fresh('app3'))).rejects.toMatchObject({ code: 'internal' });
    spy.mockRestore();
    expect(await authExists('app3')).toBe(true);
    expect(await docExists('profiles/app3')).toBe(true);
    expect((await db.doc('deletion_jobs/app3').get()).data()).toMatchObject({ status: 'failed' });
    expect(await docExists('deletion_receipts/app3')).toBe(false);

    await expect(v2call(fn(), {}, fresh('app3'))).resolves.toEqual({ success: true, status: 'deleted' });
    expect(await authExists('app3')).toBe(false);
    expect(await exists('profiles/app3/photos/a.jpg')).toBe(false);
  });
});

// ===========================================================================
describe('Auth onDelete trigger (old app versions, admin panel, console)', () => {
  const trigger = () => require('../../src/auth/deleteUserData').onUserDeletedCleanup;
  const fire = (uid: string) => (fft.wrap(trigger()) as any)(fft.auth.makeUserRecord({ uid }));

  test('sweeps data, writes the receipt in the same shape, retains money rows', async () => {
    await db.doc('profiles/old1').set({ name: 'Old' });
    await db.doc('coinBalances/old1').set({ totalCoins: 5 });
    await db.doc('purchaseLedger/p1').set({ userId: 'old1', amount: 9.99, currency: 'EUR' });
    await db.doc('coinTransactions/t1').set({ userId: 'old1', amount: 5, type: 'credit' });
    await db.doc('profiles/old1/blocked_users/x').set({ v: 1 });
    await put('profiles/old1/p.jpg');
    await fire('old1');
    expect(await docExists('profiles/old1')).toBe(false);
    expect(await docExists('profiles/old1/blocked_users/x')).toBe(false);
    expect(await exists('profiles/old1/p.jpg')).toBe(false);
    const receipt = (await db.doc('deletion_receipts/old1').get()).data()!;
    expect(receipt).toEqual(expect.objectContaining({
      deletedAt: expect.anything(), documentsDeleted: expect.any(Number),
      messagesAnonymised: expect.any(Number), filesDeleted: expect.any(Number), failures: [],
    }));
    // Money rows are retained (pseudonymised), not destroyed.
    const fin = await db.collection('retention_finance').get();
    expect(fin.docs.map((d) => d.data().sourceCollection).sort()).toEqual(['coinBalances', 'coinTransactions', 'purchaseLedger']);
    expect(JSON.stringify(fin.docs.map((d) => [d.id, d.data()]))).not.toContain('old1');
  });

  test('after a server deletion the trigger keeps the original receipt', async () => {
    const { deleteAccountCompletely } = require('../../src/auth/accountDeletion');
    await newUser('srv1', 'srv1@example.com');
    await deleteAccountCompletely('srv1', { source: 'app_callable' });
    await fire('srv1');
    const r = (await db.doc('deletion_receipts/srv1').get()).data()!;
    expect(r.source).toBe('app_callable');
    expect(r.sweptAt).toBeDefined();
  });

  test('onProfileDeleted leaves Auth alone while a server deletion runs, deletes it otherwise', async () => {
    const { onProfileDeleted } = require('../../src/admin/accountCleanup');
    const fireProfile = (uid: string) => (fft.wrap(onProfileDeleted) as any)({
      data: fft.firestore.makeDocumentSnapshot({}, `profiles/${uid}`), params: { uid },
    });
    await newUser('pd1', 'pd1@example.com');
    await db.doc('deletion_jobs/pd1').set({ status: 'running', startedAt: admin.firestore.Timestamp.now() });
    await fireProfile('pd1');
    expect(await authExists('pd1')).toBe(true);
    await newUser('pd2', 'pd2@example.com');
    await fireProfile('pd2');
    expect(await authExists('pd2')).toBe(false);
  });
});

// ===========================================================================
describe('inventory: every listed location is cleared', () => {
  const UID = 'invUser1';
  const OTHER = 'otherUser9';

  async function seed(mod: any) {
    const { ACCOUNT_DATA_INVENTORY, BACKUP_BUCKETS } = mod;
    let i = 0;
    for (const e of ACCOUNT_DATA_INVENTORY as any[]) {
      i++;
      switch (e.kind) {
        case 'doc':
          await db.doc(`${e.collection}/${UID}`).set({ userId: UID, v: 1 });
          await db.doc(`${e.collection}/${UID}/sub/x`).set({ v: 1 });
          break;
        case 'path':
          await db.doc(e.path.replace('{uid}', UID)).set({ v: 1 });
          break;
        case 'idPrefix':
          await db.doc(`${e.collection}/${UID}_2026-10-08`).set({ v: 1 });
          await db.doc(`${e.collection}/${OTHER}_2026-10-08`).set({ v: 1 });
          break;
        case 'query':
          await db.doc(`${e.collection}/q${i}`).set({ [e.field]: e.arrayContains ? [UID, OTHER] : UID });
          if (e.recursive) await db.doc(`${e.collection}/q${i}/sub/x`).set({ by: UID });
          break;
        case 'supportChats':
          await db.doc('support_chats/sc1').set({ userId: UID, userName: 'N' });
          await db.doc('support_chats/sc1/messages/x').set({ senderId: 'agent' });
          await db.doc('support_messages/sm1').set({ conversationId: 'sc1', senderId: 'agent', text: 'hi' });
          await put('support_attachments/sc1/a.jpg');
          break;
        case 'group':
          await db.doc(`parents${i}/p1`).set({ [e.parentCounter]: 5 });
          // Event rosters count PLACES of 'going' attendees (attendeeSeats):
          // a doc without a status takes no place, so it must be 'going' here.
          await db.doc(`parents${i}/p1/${e.group}/${UID}`).set({ userId: UID, status: 'going' });
          break;
        case 'buyerRecords':
          await db.doc(`${e.collection}/b${i}`).set({
            [e.field]: UID, kind: 'event', listingId: `ev${i}`, status: 'paid', totalAmount: 1000, currency: 'brl',
            attendeeName: 'Inv User', guestName: 'Inv User', attendeeNames: [{ firstName: 'Inv', lastName: 'User' }],
          });
          break;
        case 'finance':
          if (e.byDocId) await db.doc(`${e.collection}/${UID}`).set({ amount: 1, email: 'inv@example.com' });
          else await db.doc(`${e.collection}/f${i}`).set({ [e.field]: UID, amount: 1, currency: 'BRL', email: 'inv@example.com', displayName: 'Inv User' });
          break;
        case 'scrub':
          await db.doc(`${e.collection}/s${i}`).set({
            [e.field]: e.arrayContains ? [UID, OTHER] : UID, keep: OTHER, map: { [UID]: 1, [OTHER]: 2 },
          });
          if (e.deleteSub) await db.doc(`${e.collection}/s${i}/${e.deleteSub}/${UID}`).set({ v: 1 });
          break;
        case 'arrayRemove':
          await db.doc(`${e.collection}/${OTHER}`).set({ [e.field]: [UID, 'someoneElse'] });
          break;
        case 'replaceField':
          await db.doc(`${e.collection}/r${i}`).set({ userId: OTHER, [e.field]: UID });
          break;
        case 'anonymise':
          if (e.topLevelOnly) await db.doc(`${e.group}/a${i}`).set({ senderId: UID, type: 'text', content: 'x' });
          else await db.doc(`conv${i}/c/${e.group}/a${i}`).set({ senderId: UID, type: 'image', content: dlUrl('chat_images/m/x.jpg') });
          break;
        case 'storage':
          if (e.buckets === 'backup') {
            for (const bn of BACKUP_BUCKETS()) await put(`${e.prefix ? e.prefix + '/' : ''}${UID}/f.json`, admin.storage().bucket(bn));
          } else await put(`${e.prefix}/${UID}/f.jpg`);
          break;
      }
    }
    await put('chat_images/m/x.jpg');
    await newUser(UID, 'inv@example.com');
    await newUser(OTHER, 'other@example.com');
    await db.doc(`users/${OTHER}`).set({ blockedUsers: [UID, 'someoneElse'], email: 'other@example.com' }, { merge: true });
  }

  /** Every doc anywhere whose path or data mentions the uid. */
  async function findUid(ref: FirebaseFirestore.CollectionReference | FirebaseFirestore.Firestore, hits: string[], skip: string[]) {
    const cols = await (ref as any).listCollections();
    for (const c of cols as FirebaseFirestore.CollectionReference[]) {
      if (c.parent === null && skip.includes(c.id)) continue;
      for (const d of await c.listDocuments()) {
        const snap = await d.get();
        if (d.path.includes(UID) || (snap.exists && JSON.stringify(snap.data()).includes(UID))) hits.push(d.path);
        await findUid(d as any, hits, skip);
      }
    }
  }

  test('nothing with the uid remains outside the retention stores', async () => {
    const mod = require('../../src/auth/accountDeletion');
    await seed(mod);
    const report = await mod.deleteAccountCompletely(UID, { source: 'app_callable' });
    expect(report.failures).toEqual([]);
    // Buyer-side ticket records: the follow-up task (trigger in production).
    const fu = require('../../src/auth/deletionFollowups');
    expect((await db.doc(`deletion_followups/${UID}`).get()).data()!.ticketsStatus).toBe('pending');
    expect(await fu.processTicketsFollowup(UID)).toBe('done');

    const hits: string[] = [];
    await findUid(db, hits, mod.RETENTION_STORES);
    expect(hits).toEqual([]);

    // Retention stores: no uid in retention_finance, no PII.
    const fin = await db.collection('retention_finance').get();
    expect(fin.size).toBeGreaterThan(20);
    expect(JSON.stringify(fin.docs.map((d) => [d.id, d.data()]))).not.toMatch(new RegExp(`${UID}|example\\.com|Inv User`));

    // Storage: nothing of the user outside retention/.
    const [files] = await bucket().getFiles();
    expect(files.map((f) => f.name).filter((n) => n.includes(UID) || n.startsWith('chat_images/') || n.startsWith('support_attachments/'))).toEqual([]);
    for (const bn of mod.BACKUP_BUCKETS()) {
      const [bf] = await admin.storage().bucket(bn).getFiles();
      expect(bf.map((f) => f.name).filter((n) => n.includes(UID))).toEqual([]);
    }

    // Others are untouched (only de-referenced).
    expect(await authExists(OTHER)).toBe(true);
    expect(await docExists(`profiles/${OTHER}`)).toBe(true);
    expect((await db.doc(`users/${OTHER}`).get()).data()!.blockedUsers).toEqual(['someoneElse']);
    expect(await docExists(`translation_quota/${OTHER}_2026-10-08`)).toBe(true);
    const counters = await Promise.all(
      (mod.ACCOUNT_DATA_INVENTORY as any[]).map((e, idx) => e.kind === 'group' ? db.doc(`parents${idx + 1}/p1`).get() : null).filter(Boolean),
    );
    for (const c of counters) expect(Object.values(c!.data()!)[0]).toBe(4);
    const scrubbedConv = (await db.collection('conversations').get()).docs.map((d) => d.data());
    expect(scrubbedConv.every((d) => d.keep === OTHER && d.map[OTHER] === 2)).toBe(true);
    const groups = (await db.collection('groups').get()).docs.map((d) => d.data());
    expect(groups[0].participants).toEqual([OTHER]);

    // Ticket purchases: kept with the pseudonym, without names (privacy 15.2 e).
    const pseudonym = mod.retentionUidHash(UID);
    for (const c of ['ticket_orders', 'tickets', 'ticket_refunds', 'admin_alerts']) {
      const rows = (await db.collection(c).get()).docs.map((d) => d.data());
      expect(rows.length).toBe(1);
      expect(rows[0]).toMatchObject({ totalAmount: 1000, currency: 'brl', buyerDeleted: true, buyerId: pseudonym });
      expect(JSON.stringify(rows)).not.toMatch(/Inv User|"Inv"/);
    }
    expect((await db.collection('ticket_holdings').get()).size).toBe(0);
  });

  test('ticket buyer: orders / tickets / refunds pseudonymised, holder names + counters deleted, guest purchases of the VERIFIED e-mail too', async () => {
    const mod = require('../../src/auth/accountDeletion');
    const fu = require('../../src/auth/deletionFollowups');
    const { guestKeyFor } = require('../../src/shared/guestIdentity');
    const { guestIdentitySecret } = require('../../src/guest/guestKeys');
    const BUYER = 'ticketBuyer1';
    await auth.createUser({ uid: BUYER, email: 'buyer@example.com', emailVerified: true, password: 'Passw0rd!x' });
    await db.doc(`profiles/${BUYER}`).set({ name: 'Buyer Person', email: 'buyer@example.com' });
    await db.doc(`users/${BUYER}`).set({ email: 'buyer@example.com' });
    const gk = guestKeyFor(await guestIdentitySecret(), 'Buyer@Example.com');
    const otherGk = guestKeyFor(await guestIdentitySecret(), 'someone@example.com');
    const past = admin.firestore.Timestamp.fromMillis(Date.now() - 10 * 86400_000);
    const soon = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 86400_000);
    await db.doc('events/evA').set({ title: 'A', attendeeCount: 3, organizerId: 'orgX' });
    await db.doc(`events/evA/attendees/${BUYER}`).set({ userId: BUYER, status: 'going', guestCount: 1 });
    await db.doc(`events/evA/attendee_names/${BUYER}`).set({ buyerId: BUYER, names: [{ ticketId: 'oA_1', firstName: 'Holder', lastName: 'One' }] });
    await db.doc('ticket_orders/oA').set({
      kind: 'event', listingId: 'evA', buyerId: BUYER, organizerId: 'orgX', status: 'paid', totalAmount: 4000, feeTotal: 400,
      hostNet: 3600, currency: 'eur', startsAt: soon, paidAt: past, attendeeNames: [{ firstName: 'Holder', lastName: 'One' }],
    });
    await db.doc('tickets/oA_1').set({ orderId: 'oA', buyerId: BUYER, organizerId: 'orgX', status: 'valid', qrPayload: 'qr', startsAt: soon, attendeeName: 'Holder One' });
    await db.doc('ticket_refunds/oB').set({ orderId: 'oB', buyerId: BUYER, organizerId: 'orgX', amount: 1500, currency: 'eur', status: 'refunded' });
    await db.doc(`ticket_holdings/event_evA_${BUYER}`).set({ uid: BUYER, owned: 2 });
    // Guest purchase with the same (verified) e-mail before the account existed.
    await db.doc('ticket_orders/oG').set({
      kind: 'event', listingId: 'evA', buyerId: gk, organizerId: 'orgX', status: 'paid', totalAmount: 2000, currency: 'eur',
      isGuest: true, guest: { firstName: 'Guest', lastName: 'Buyer' }, guestName: 'Guest Buyer', startsAt: past,
    });
    await db.doc(`guest_contacts/${gk}`).set({ email: 'buyer@example.com', locale: 'en' });
    // Someone else's guest order: untouched.
    await db.doc('ticket_orders/oX').set({ kind: 'event', listingId: 'evA', buyerId: otherGk, status: 'paid', guestName: 'Other Guest' });

    const report = await mod.deleteAccountCompletely(BUYER, { source: 'app_callable' });
    expect(report.failures).toEqual([]);
    // Inline: the roster entry (2 places) and its holder names are gone.
    expect(await docExists(`events/evA/attendees/${BUYER}`)).toBe(false);
    expect(await docExists(`events/evA/attendee_names/${BUYER}`)).toBe(false);
    expect((await db.doc('events/evA').get()).data()!.attendeeCount).toBe(1);
    const fdoc = (await db.doc(`deletion_followups/${BUYER}`).get()).data()!;
    expect(fdoc.ticketGuestKeys).toEqual([gk]);
    expect(JSON.stringify(fdoc)).not.toContain('example.com');

    expect(await fu.processTicketsFollowup(BUYER)).toBe('done');
    const P = mod.retentionUidHash(BUYER);
    const oA = (await db.doc('ticket_orders/oA').get()).data()!;
    expect(oA).toMatchObject({ buyerId: P, organizerId: 'orgX', totalAmount: 4000, feeTotal: 400, hostNet: 3600, currency: 'eur', status: 'paid', attendeeNames: null, buyerDeleted: true });
    const tA = (await db.doc('tickets/oA_1').get()).data()!;
    expect(tA).toMatchObject({ buyerId: P, status: 'void', attendeeName: null });
    expect(tA.qrPayload).toBeUndefined();
    expect((await db.doc('ticket_refunds/oB').get()).data()).toMatchObject({ buyerId: P, amount: 1500, status: 'refunded' });
    expect(await docExists(`ticket_holdings/event_evA_${BUYER}`)).toBe(false);
    const oG = (await db.doc('ticket_orders/oG').get()).data()!;
    expect(oG).toMatchObject({ buyerId: P, totalAmount: 2000, isGuest: true });
    expect(oG.guestName).toBeUndefined();
    expect(oG.guest).toBeUndefined();
    expect(await docExists(`guest_contacts/${gk}`)).toBe(false);
    expect((await db.doc('ticket_orders/oX').get()).data()).toMatchObject({ buyerId: otherGk, guestName: 'Other Guest' });
    const fdone = (await db.doc(`deletion_followups/${BUYER}`).get()).data()!;
    expect(fdone.ticketsStatus).toBe('done');
    expect(fdone.ticketGuestKeys).toBeUndefined();

    // Idempotent: a second pass (e.g. the Auth trigger sweep) changes nothing.
    await db.doc(`deletion_followups/${BUYER}`).set({ ticketsStatus: 'pending' }, { merge: true });
    expect(await fu.processTicketsFollowup(BUYER)).toBe('done');
    expect((await db.doc('ticket_orders/oA').get()).data()).toEqual(oA);
  });

  test('an UNVERIFIED e-mail never links guest purchases', async () => {
    const mod = require('../../src/auth/accountDeletion');
    const { guestKeyFor } = require('../../src/shared/guestIdentity');
    const { guestIdentitySecret } = require('../../src/guest/guestKeys');
    await auth.createUser({ uid: 'unverified1', email: 'claimed@example.com', emailVerified: false, password: 'Passw0rd!x' });
    await db.doc('profiles/unverified1').set({ name: 'U' });
    const gk = guestKeyFor(await guestIdentitySecret(), 'claimed@example.com');
    await db.doc('ticket_orders/oV').set({ buyerId: gk, guestName: 'Real Owner', status: 'paid' });
    await mod.deleteAccountCompletely('unverified1', { source: 'app_callable' });
    expect((await db.doc('deletion_followups/unverified1').get()).data()!.ticketGuestKeys).toBeUndefined();
    expect((await db.doc('ticket_orders/oV').get()).data()).toMatchObject({ buyerId: gk, guestName: 'Real Owner' });
  });
});
