/**
 * NCII / CSAE safety takedowns (audit BR-11, US-09, US-10, BR-14, AS-08, EU-19).
 *
 * Real Firestore + Auth + Storage emulators (rules included). Only Cloud
 * Vision and outbound Resend calls are stubbed.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Source modules are required lazily so that, on the pre-change code, the new
 * behaviour is what fails.
 */

import * as admin from 'firebase-admin';
import * as http from 'http';
import sharp from 'sharp';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
const BUCKET = `${PROJECT}.appspot.com`;
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT, storageBucket: BUCKET });
const db = admin.firestore();
const auth = admin.auth();
const bucket = () => admin.storage().bucket();
const H = 3600_000;

jest.mock('@google-cloud/vision', () => {
  class ImageAnnotatorClient {
    annotateImage = async () => [{}]; // SafeSearch: nothing found -> approved
    textDetection = async () => [{}];
  }
  return { __esModule: true, default: { ImageAnnotatorClient }, ImageAnnotatorClient };
});

const fetchMock = jest.fn(async (..._args: any[]) => ({ ok: true, status: 200, json: async () => ({}), text: async () => '{}' }));
(global as any).fetch = fetchMock;
const emails = () => fetchMock.mock.calls
  .filter((c) => String(c[0]).includes('api.resend.com'))
  .map((c) => JSON.parse((c[1] as any).body));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const req = (p: string): any => require(p);
const cases = () => req('../../src/safety/takedowns/safetyCases');
const endpoints = () => req('../../src/safety/takedowns/endpoints');

// --- emulator helpers --------------------------------------------------------
function emulatorRequest(hostVar: string, method: string, path: string, headers: Record<string, string> = {}, body?: string): Promise<{ status: number; body: string }> {
  const host = process.env[hostVar]!;
  return new Promise((resolve, reject) => {
    const r = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method, path, headers },
      (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => resolve({ status: res.statusCode || 0, body: b })); });
    r.on('error', reject);
    if (body) r.write(body);
    r.end();
  });
}
async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Not a local emulator');
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Storage emulator required');
  await emulatorRequest('FIRESTORE_EMULATOR_HOST', 'DELETE', `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
  await bucket().deleteFiles({ force: true }).catch(() => undefined);
}
/** Signs a user up in the Auth emulator and returns an ID token. */
async function idTokenFor(email: string): Promise<{ uid: string; idToken: string }> {
  const r = await emulatorRequest('FIREBASE_AUTH_EMULATOR_HOST', 'POST', '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake',
    { 'Content-Type': 'application/json' }, JSON.stringify({ email, password: 'Passw0rd!x', returnSecureToken: true }));
  const j = JSON.parse(r.body);
  return { uid: j.localId, idToken: j.idToken };
}
/** Client read through the Firestore REST API, so the security rules apply. */
const clientGet = (path: string, idToken: string) =>
  emulatorRequest('FIRESTORE_EMULATOR_HOST', 'GET', `/v1/projects/${PROJECT}/databases/(default)/documents/${path}`,
    { Authorization: `Bearer ${idToken}` });

// --- images --------------------------------------------------------------------
function synthetic(seed: number, w = 320, h = 240): Buffer {
  const px = Buffer.alloc(w * h * 3);
  const blobs = Array.from({ length: 6 }, (_, i) => ({
    x: ((seed * 97 + i * 53) % 100) / 100 * w, y: ((seed * 31 + i * 71) % 100) / 100 * h,
    r: 20 + ((seed * 13 + i * 29) % 60),
    c: [(seed * 40 + i * 70) % 256, (seed * 90 + i * 30) % 256, (seed * 10 + i * 110) % 256],
  }));
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let r = (x / w) * 200 * ((seed % 3) + 1) / 3; let g = (y / h) * 180; let b = 128 + 100 * Math.sin((x + seed * 17) / (15 + seed));
      for (const bl of blobs) if (Math.hypot(x - bl.x, y - bl.y) < bl.r) { r = bl.c[0]; g = bl.c[1]; b = bl.c[2]; }
      const o = (y * w + x) * 3; px[o] = r; px[o + 1] = g; px[o + 2] = b;
    }
  }
  return px;
}
const jpeg = (seed: number, quality = 90) =>
  sharp(synthetic(seed), { raw: { width: 320, height: 240, channels: 3 } }).jpeg({ quality }).toBuffer();
const put = (path: string, buf: Buffer, metadata: Record<string, string> = {}) =>
  bucket().file(path).save(buf, { contentType: 'image/jpeg', resumable: false, metadata: { metadata } });
const exists = async (path: string) => (await bucket().file(path).exists())[0];
const dl = (path: string) => `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=t1`;

async function runUploadTrigger(path: string, metadata: Record<string, string> = {}) {
  const { moderateUploadedImage } = req('../../src/safety/moderateUploadedImage');
  const [meta] = await bucket().file(path).getMetadata();
  await (moderateUploadedImage as any).run({
    data: { name: path, bucket: BUCKET, contentType: 'image/jpeg', size: String(meta.size), metadata },
  });
}

// --- HTTP / callable helpers ---------------------------------------------------------
function fakeRes() {
  const r: any = { statusCode: 0, headers: {}, payload: undefined };
  r.set = (k: string, v: string) => { r.headers[k] = v; return r; };
  r.status = (c: number) => { r.statusCode = c; return r; };
  r.json = (p: any) => { r.payload = p; return r; };
  r.send = (p: any) => { r.payload = p; return r; };
  return r;
}
const fakeReq = (method: string, body: any, query: any = {}, ip = '203.0.113.7') => ({
  method, body, query, path: '/', headers: { 'x-forwarded-for': ip, host: 'localhost' },
  get(h: string) { return (this.headers as any)[h.toLowerCase()]; },
});
const VICTIM_EMAIL = 'victim.person@example.com';
const VICTIM_NAME = 'Vicky Victimova';
const form = (locations: string[], extra: Record<string, unknown> = {}) => ({
  fullName: VICTIM_NAME, email: VICTIM_EMAIL, role: 'depicted_person', contentLocations: locations,
  description: 'My ex posted this photo without my consent',
  statements: { depictedOrAuthorized: true, goodFaith: true, accurate: true }, signature: VICTIM_NAME, ...extra,
});
async function postForm(body: any, ip?: string, nowMs?: number) {
  const res = fakeRes();
  await endpoints().handleNciiHttp(fakeReq('POST', body, {}, ip), res, nowMs);
  return res;
}
const adminCall = (uid: string, data: any, role?: string) =>
  endpoints().handleSafetyAdmin({ uid, token: role ? { adminRole: role } : {} }, data);
const caseDoc = async (id: string) => (await db.doc(`safety_cases/${id}`).get()).data()!;

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'alerts@greengo.test' });
  await db.doc('admin_users/mod1').set({ role: 'moderator', isActive: true });
  await db.doc('admin_users/boss').set({ role: 'superAdmin', isActive: true });
});

// ===========================================================================
describe('NCII public request form (TAKE IT DOWN / Decreto 12.976)', () => {
  test('content is hidden at once, P0 alert carries no personal data, requester confirms + checks status by token', async () => {
    const p1 = 'profiles/upl1/photos/a.jpg';
    const p2 = 'profiles/upl1/photos/b.jpg';
    await put(p1, await jpeg(3), { userId: 'upl1' });
    await put(p2, await jpeg(5), { userId: 'upl1' });
    await db.doc('profiles/upl1').set({ displayName: 'Uploader', photoUrls: [dl(p1), dl(p2)] });

    const t0 = Date.now();
    const res = await postForm(form([dl(p1)]), undefined, t0);
    expect(res.statusCode).toBe(201);
    const caseId = res.payload.caseId;
    const c = await caseDoc(caseId);
    expect(c).toMatchObject({ kind: 'ncii', status: 'pending_review', source: 'public_form', reportedUserId: 'upl1' });
    expect(c.slaTargetAt.toMillis() - t0).toBe(2 * H);
    expect(c.slaMaxAt.toMillis() - t0).toBe(48 * H);
    expect(c.escalateAt.toMillis() - t0).toBe(1 * H);
    expect(c.statements).toMatchObject({ depictedOrAuthorized: true, goodFaith: true, accurate: true });

    // Precautionary takedown: object moved, URL removed from the profile, hash blocked (provisional).
    expect(await exists(p1)).toBe(false);
    expect(await exists(`safety_holds/${caseId}/${p1}`)).toBe(true);
    expect(await exists(p2)).toBe(true);
    expect((await db.doc('profiles/upl1').get()).data()?.photoUrls).toEqual([dl(p2)]);
    const hashes = await db.collection('blocked_media_hashes').get();
    expect(hashes.size).toBe(1);
    expect(hashes.docs[0].data()).toMatchObject({ active: true, provisional: true, kind: 'ncii', caseId });

    // P0 alert to the security list + greengochat.com@gmail.com, no PII; confirmation email to the requester.
    const sent = emails();
    const alert = sent.find((e) => e.subject.includes('P0 NCII'))!;
    expect(alert.to).toEqual(expect.arrayContaining(['greengochat.com@gmail.com']));
    const alertText = JSON.stringify(alert);
    for (const pii of [VICTIM_EMAIL, VICTIM_NAME, 'upl1', p1]) expect(alertText).not.toContain(pii);
    const confirm = sent.find((e) => e.to.includes(VICTIM_EMAIL))!;
    expect(confirm.subject).toContain('confirm your removal request');
    expect((await db.doc(`admin_alerts/safety_opened_${caseId}`).get()).exists).toBe(true);

    // Token links.
    const token = /token=([0-9a-f]{48})/.exec(confirm.html)![1];
    const r1 = fakeRes();
    await endpoints().handleNciiHttp(fakeReq('GET', undefined, { action: 'confirm', case: caseId, token }), r1);
    expect(r1.statusCode).toBe(200);
    expect((await caseDoc(caseId)).requester.emailConfirmed).toBe(true);
    const r2 = fakeRes();
    await endpoints().handleNciiHttp(fakeReq('GET', undefined, { action: 'status', case: caseId, token }), r2);
    expect(r2.payload).toMatchObject({ status: 'pending_review', emailConfirmed: true });
    expect(JSON.stringify(r2.payload)).not.toContain(VICTIM_EMAIL);
    const r3 = fakeRes();
    await endpoints().handleNciiHttp(fakeReq('GET', undefined, { action: 'status', case: caseId, token: 'a'.repeat(48) }), r3);
    expect(r3.statusCode).toBe(404);
  });

  test('validation, honeypot and per-IP rate limit', async () => {
    const bad = await postForm({ ...form(['https://example.com/x']), statements: { goodFaith: true } });
    expect(bad.statusCode).toBe(400);
    expect(bad.payload.fields).toEqual(expect.arrayContaining(['statements.depictedOrAuthorized', 'statements.accurate']));
    const noSig = await postForm({ ...form(['https://example.com/x']), signature: '' });
    expect(noSig.payload.fields).toContain('signature');

    const bot = await postForm({ ...form(['https://example.com/x']), website: 'http://spam' });
    expect(bot.statusCode).toBe(201);
    expect((await db.collection('safety_cases').get()).size).toBe(0);

    const codes: number[] = [];
    for (let i = 0; i < 6; i++) codes.push((await postForm(form([`https://example.com/x${i}`], { email: `v${i}@example.com` }), '198.51.100.9')).statusCode);
    expect(codes).toEqual([201, 201, 201, 201, 201, 429]);
    // An unknown link is kept for a manual action, not silently dropped.
    const one = (await db.collection('safety_cases').limit(1).get()).docs[0].data();
    expect(one.hidden[0]).toMatchObject({ type: 'unresolved', reason: 'manual_review' });
  });
});

// ===========================================================================
describe('in-app request + Firestore rules', () => {
  test('auth required; requester reads only their own status; cases, holds and hash lists are server-only', async () => {
    await expect(endpoints().handleSubmitSafetyRequest(undefined, form(['profile:someone1']))).rejects.toMatchObject({ code: 'unauthenticated' });

    const owner = await idTokenFor('owner@example.com');
    const other = await idTokenFor('other@example.com');
    await put('profiles/someone1/p.jpg', await jpeg(7));
    await db.doc('profiles/someone1').set({ photoUrls: [dl('profiles/someone1/p.jpg')] });
    const r = await endpoints().handleSubmitSafetyRequest({ uid: owner.uid, token: { email: 'owner@example.com' } },
      { ...form(['profile:someone1']), email: undefined });
    expect(r.ok).toBe(true);
    expect(await exists('profiles/someone1/p.jpg')).toBe(false);
    expect((await caseDoc(r.caseId)).requester).toMatchObject({ uid: owner.uid, email: 'owner@example.com', emailConfirmed: true });

    expect((await clientGet(`safety_request_status/${r.caseId}`, owner.idToken)).status).toBe(200);
    expect((await clientGet(`safety_request_status/${r.caseId}`, other.idToken)).status).toBe(403);
    expect((await clientGet(`safety_cases/${r.caseId}`, owner.idToken)).status).toBe(403);
    await db.doc('legal_holds/h1').set({ subjectUid: 'x' });
    await db.doc('blocked_media_hashes/b1').set({ active: true });
    await db.doc('csam_hash_list/c1').set({ hash: 'x' });
    for (const p of ['legal_holds/h1', 'blocked_media_hashes/b1', 'csam_hash_list/c1']) {
      expect((await clientGet(p, owner.idToken)).status).toBe(403);
    }
  });
});

// ===========================================================================
describe('SLA escalation (fake clock)', () => {
  test('1h escalation, 2h breach, 48h legal breach - each once; decided cases never escalate', async () => {
    const t0 = Date.UTC(2026, 9, 9, 12, 0, 0);
    const mk = async () => (await cases().createSafetyCase({
      kind: 'ncii', source: 'in_app_form', requester: { name: 'X', email: null, phone: null, uid: 'u1', role: 'depicted_person' },
      contentRefs: [{ type: 'url', value: 'https://example.com/a' }], nowMs: t0,
    })).caseId;
    const open = await mk();
    const done = await mk();
    await db.doc(`safety_cases/${done}`).update({ status: 'restored' });
    fetchMock.mockClear();
    const sweep = (ms: number) => cases().runSafetySlaSweep(t0 + ms);

    expect(await sweep(30 * 60_000)).toEqual([]);
    expect(await sweep(61 * 60_000)).toEqual([{ caseId: open, stage: 'escalation' }]);
    expect(await sweep(62 * 60_000)).toEqual([]);
    expect(await sweep(2 * H + 60_000)).toEqual([{ caseId: open, stage: 'sla_breach' }]);
    expect(await sweep(3 * H)).toEqual([]);
    expect(await sweep(48 * H + 60_000)).toEqual([{ caseId: open, stage: 'legal_max_breach' }]);
    expect(await sweep(60 * H)).toEqual([]);

    const subjects = emails().map((e) => e.subject);
    expect(subjects.filter((s) => s.includes('ESCALATION'))).toHaveLength(1);
    expect(subjects.filter((s) => s.includes('SLA BREACHED'))).toHaveLength(1);
    expect(subjects.filter((s) => s.includes('LEGAL DEADLINE BREACHED'))).toHaveLength(1);
    expect(subjects.join(' ')).not.toContain(done.slice(0, 6));
    const audit = await db.collection(`safety_cases/${open}/audit`).where('action', '==', 'sla_escalation').get();
    expect(audit.size).toBe(1);
  });
});

// ===========================================================================
describe('decision + hash blocking of re-uploads', () => {
  test('confirm: permanent block, uploader suspended + strike + statement of reasons; re-encoded re-upload to a public surface is hidden; private chat not scanned', async () => {
    const p1 = 'profiles/upl1/photos/a.jpg';
    await put(p1, await jpeg(3), { userId: 'upl1' });
    await db.doc('profiles/upl1').set({ photoUrls: [dl(p1)] });
    await db.doc('users/upl1').set({ accountStatus: 'active' });
    const first = (await postForm(form([dl(p1)]))).payload.caseId;

    // Non-admin cannot decide; moderator can.
    await expect(adminCall('joe', { op: 'decide', caseId: first, decision: 'confirm' })).rejects.toMatchObject({ code: 'permission-denied' });
    fetchMock.mockClear();
    const r = await adminCall('mod1', { op: 'decide', caseId: first, decision: 'confirm', sanction: 'suspend', notes: 'verified' }, 'moderator');
    expect(r.status).toBe('confirmed');
    expect(await exists(`safety_holds/${first}/${p1}`)).toBe(false); // NCII copy destroyed after hashing
    const h = (await db.collection('blocked_media_hashes').get()).docs[0].data();
    expect(h).toMatchObject({ active: true, provisional: false });
    expect((await db.doc('users/upl1').get()).data()).toMatchObject({ accountStatus: 'suspended', safetyStrikes: 1 });
    expect((await db.doc(`user_strikes/${first}_upl1`).get()).exists).toBe(true);
    expect((await db.doc(`moderation_decisions/safety_${first}`).get()).data()).toMatchObject({ userId: 'upl1', action: 'suspendUser', reasonCode: 'ncii' });
    expect((await db.doc(`safety_request_status/${first}`).get()).data()?.status).toBe('confirmed');
    expect(emails().some((e) => e.to.includes(VICTIM_EMAIL) && e.subject.includes('reviewed'))).toBe(true);
    await expect(adminCall('mod1', { op: 'decide', caseId: first, decision: 'restore' }, 'moderator')).rejects.toMatchObject({ code: 'failed-precondition' });

    // Re-upload of the same photo, re-encoded (different bytes), by another account.
    const again = 'profiles/upl2/photos/again.jpg';
    await put(again, await jpeg(3, 45), { userId: 'upl2' });
    fetchMock.mockClear();
    await runUploadTrigger(again, { userId: 'upl2' });
    expect(await exists(again)).toBe(false);
    expect((await db.doc(`image_moderation/${again.replace(/\//g, '~')}`).get()).data()).toMatchObject({ status: 'rejected', reasons: ['blocked_hash'] });
    const blocked = (await db.collection('safety_cases').where('source', '==', 'hash_match').get()).docs;
    expect(blocked).toHaveLength(1);
    expect(blocked[0].data()).toMatchObject({ kind: 'ncii', status: 'pending_review', reportedUserId: 'upl2' });
    expect(blocked[0].data().hashMatch).toMatchObject({ matchedCaseId: first, how: 'perceptual' });
    expect(await exists(`safety_holds/${blocked[0].id}/${again}`)).toBe(true);
    expect(emails().some((e) => e.subject.includes('re-upload blocked'))).toBe(true);

    // Private chat image: not hash-scanned (EU-19), only the normal Vision check.
    const chat = 'chat_images/c1/m1.jpg';
    await put(chat, await jpeg(3, 60));
    await runUploadTrigger(chat);
    expect(await exists(chat)).toBe(true);
    // An unrelated public photo passes.
    const ok = 'profiles/upl3/photos/ok.jpg';
    await put(ok, await jpeg(8));
    await runUploadTrigger(ok);
    expect(await exists(ok)).toBe(true);
    expect((await db.collection('safety_cases').where('source', '==', 'hash_match').get()).size).toBe(1);
  });

  test('restore puts the photo and profile link back and lifts the block', async () => {
    const p1 = 'profiles/upl1/photos/a.jpg';
    await put(p1, await jpeg(3), { userId: 'upl1' });
    await db.doc('profiles/upl1').set({ photoUrls: [dl(p1)] });
    const id = (await postForm(form([dl(p1)]))).payload.caseId;
    expect(await exists(p1)).toBe(false);

    const r = await adminCall('mod1', { op: 'decide', caseId: id, decision: 'restore', notes: 'consensual, verified' }, 'moderator');
    expect(r.status).toBe('restored');
    expect(await exists(p1)).toBe(true);
    expect(await exists(`safety_holds/${id}/${p1}`)).toBe(false);
    expect((await db.doc('profiles/upl1').get()).data()?.photoUrls).toEqual([dl(p1)]);
    expect((await db.collection('blocked_media_hashes').get()).docs[0].data().active).toBe(false);

    const again = 'profiles/upl4/photos/x.jpg';
    await put(again, await jpeg(3, 50));
    await runUploadTrigger(again);
    expect(await exists(again)).toBe(true);
    const audit = (await db.collection(`safety_cases/${id}/audit`).get()).docs.map((d) => d.data().action);
    expect(audit).toEqual(expect.arrayContaining(['created', 'content_hidden', 'decision_restore']));
  });
});

// ===========================================================================
async function seedCsaeAccount() {
  await auth.createUser({ uid: 'bad1', email: 'bad1@example.com' });
  await db.doc('users/bad1').set({ email: 'bad1@example.com', accountStatus: 'active' });
  await db.doc('profiles/bad1').set({ displayName: 'Bad Actor', photoUrls: [dl('profiles/bad1/a.jpg')] });
  await put('profiles/bad1/a.jpg', await jpeg(11), { userId: 'bad1' });
  await put('chat_images/c1/m1.jpg', await jpeg(12));
  await db.doc('conversations/c1').set({ participants: ['bad1', 'rep1'] });
  await db.doc('conversations/c1/messages/m1').set({ senderId: 'bad1', type: 'image', content: dl('chat_images/c1/m1.jpg') });
}

describe('CSAE: report -> immediate hide, P0, 1-year legal hold, NCMEC/PF package', () => {
  test('a CSAE report hides the message, opens a legal hold; holds and packages are superAdmin-only', async () => {
    await seedCsaeAccount();
    await db.doc('user_reports/r1').set({
      reporterId: 'rep1', reportedUserId: 'bad1', reason: 'Abuso ou exploração sexual infantil',
      conversationId: 'c1', messageId: 'm1', timestamp: admin.firestore.Timestamp.now(),
    });
    const { enqueueReport } = req('../../src/safety/reportPipeline');
    await enqueueReport('user_reports', 'r1', (await db.doc('user_reports/r1').get()).data());

    const q = (await db.doc('moderation_queue/user_reports__r1').get()).data()!;
    expect(q).toMatchObject({ reasonCode: 'csae', priorityLevel: 'P0' });
    const caseId = q.safetyCaseId;
    const c = await caseDoc(caseId);
    expect(c).toMatchObject({ kind: 'csae', status: 'pending_review', reportedUserId: 'bad1', legalHoldId: 'csae_bad1' });
    expect(c.slaTargetAt.toMillis() - c.createdAt.toMillis()).toBe(24 * H);

    const msg = (await db.doc('conversations/c1/messages/m1').get()).data()!;
    expect(msg).toMatchObject({ isDeletedForEveryone: true, type: 'text' });
    expect(msg.content).not.toContain('chat_images');
    expect(await exists('chat_images/c1/m1.jpg')).toBe(false);

    const hold = (await db.doc('legal_holds/csae_bad1').get()).data()!;
    expect(hold).toMatchObject({ status: 'active', subjectUid: 'bad1', access: 'superAdmin' });
    const days = (hold.holdUntil.toMillis() - Date.now()) / 86_400_000;
    expect(days).toBeGreaterThan(364);
    expect(days).toBeLessThan(366);
    const preserved = (await db.collection('legal_holds/csae_bad1/preserved').get()).docs.map((d) => d.data().path);
    expect(preserved).toEqual(expect.arrayContaining(['users/bad1', 'profiles/bad1', 'auth/bad1']));
    expect(await exists('legal_holds/csae_bad1/files/profiles/bad1/a.jpg')).toBe(true);
    expect(await exists(`legal_holds/csae_bad1/files/safety_holds/${caseId}/chat_images/c1/m1.jpg`)).toBe(true);
    const alert = emails().find((e) => e.subject.includes('P0 CSAE'))!;
    expect(JSON.stringify(alert)).not.toMatch(/bad1|rep1|Bad Actor/);

    // Permissions.
    await expect(adminCall('joe', { op: 'list' })).rejects.toMatchObject({ code: 'permission-denied' });
    const list = await adminCall('mod1', { op: 'list', kind: 'csae' }, 'moderator');
    expect(list.cases.map((x: any) => x.caseId)).toEqual([caseId]);
    expect(list.cases[0].legalHoldId).toBe('active'); // moderators do not get the hold id
    for (const op of [{ op: 'listHolds' }, { op: 'getHold', holdId: 'csae_bad1' }, { op: 'reportPackage', caseId, authority: 'NCMEC' },
      { op: 'markReported', caseId, authority: 'NCMEC', reference: 'CT-123' }, { op: 'viewContent', caseId },
      { op: 'decide', caseId, decision: 'restore' }]) {
      await expect(adminCall('mod1', op, 'moderator')).rejects.toMatchObject({ code: 'permission-denied' });
    }
    const holds = await adminCall('boss', { op: 'listHolds' });
    expect(holds.holds.map((h: any) => h.holdId)).toEqual(['csae_bad1']);
    const pkg = await adminCall('boss', { op: 'reportPackage', caseId, authority: 'NCMEC' });
    expect(pkg.pkg.reportedPerson).toMatchObject({ uid: 'bad1', email: 'bad1@example.com' });
    expect(String(pkg.pkg.reportedPerson.ipLogs)).toContain('not available');
    expect(pkg.pkg.content.files.length).toBeGreaterThanOrEqual(2);
    expect((await db.collection('legal_holds/csae_bad1/report_packages').get()).size).toBe(1);
    await adminCall('boss', { op: 'markReported', caseId, authority: 'NCMEC', reference: 'CT-123' });
    expect((await caseDoc(caseId)).reportedTo[0]).toMatchObject({ authority: 'NCMEC', reference: 'CT-123', by: 'boss' });
    const sensitive = (await db.collection('admin_audit_log').where('adminId', '==', 'boss').get()).docs.map((d) => d.data().action);
    expect(sensitive).toEqual(expect.arrayContaining(['safety_view_legal_hold', 'safety_report_package', 'safety_mark_reported']));

    // Confirm: ALWAYS a ban for CSAE, even when the moderator picked a lighter
    // sanction (Terms 19.2 a); no notice to the suspect (no tipping-off);
    // evidence stays in the hold.
    await adminCall('mod1', { op: 'decide', caseId, decision: 'confirm', sanction: 'strike' }, 'moderator');
    expect((await auth.getUser('bad1')).disabled).toBe(true);
    expect((await db.doc('users/bad1').get()).data()?.accountStatus).toBe('banned');
    expect((await caseDoc(caseId)).decision).toMatchObject({ sanction: 'ban', requestedSanction: 'strike' });
    expect((await db.doc(`moderation_decisions/safety_${caseId}`).get()).exists).toBe(false);
    expect(await exists(`safety_holds/${caseId}/chat_images/c1/m1.jpg`)).toBe(false);
    expect(await exists(`legal_holds/csae_bad1/files/safety_holds/${caseId}/chat_images/c1/m1.jpg`)).toBe(true);
  });

  test('the legal hold survives account deletion (deleteMyAccount path)', async () => {
    await seedCsaeAccount();
    await db.doc('moderation_queue/q-bad1').set({ userId: 'bad1', reasonCode: 'csae', status: 'pending' });
    const { createSafetyCase } = cases();
    const created = await createSafetyCase({
      kind: 'csae', source: 'user_report', requester: { name: null, email: null, phone: null, uid: 'rep1', role: 'reporter' },
      contentRefs: [{ type: 'profile', value: 'bad1' }], reportedUserId: 'bad1',
    });
    expect(created.legalHoldId).toBe('csae_bad1');
    // Data the user adds AFTER the hold opened is captured at deletion time too.
    await put('profiles/bad1/later.jpg', await jpeg(13));
    await db.doc('profiles/bad1').update({ bio: 'written after the report' });

    const del = req('../../src/auth/accountDeletion');
    const report = await del.deleteAccountCompletely('bad1', { source: 'app_callable' });
    expect(report.failures).toEqual([]);
    await expect(auth.getUser('bad1')).rejects.toMatchObject({ code: 'auth/user-not-found' });
    expect((await db.doc('profiles/bad1').get()).exists).toBe(false);
    expect(await exists('profiles/bad1/later.jpg')).toBe(false);

    // Preserved, restricted copies remain.
    const prof = (await db.doc('legal_holds/csae_bad1/preserved/profiles~bad1').get()).data()!;
    expect(prof.data.bio).toBe('written after the report');
    expect((await db.doc('legal_holds/csae_bad1/preserved/auth_user').get()).data()?.data.email).toBe('bad1@example.com');
    expect(await exists('legal_holds/csae_bad1/files/profiles/bad1/later.jpg')).toBe(true);
    expect(await exists(`legal_holds/csae_bad1/files/safety_holds/${created.caseId}/profiles/bad1/a.jpg`)).toBe(true);
    // Held moderation records are skipped by the deletion; the case stays.
    expect((await db.doc('moderation_queue/q-bad1').get()).exists).toBe(true);
    expect((await caseDoc(created.caseId)).kind).toBe('csae');
    expect((await db.doc('legal_holds/csae_bad1').get()).data()?.subjectDeletionRequestedAt).toBeTruthy();
    expect(del.RETENTION_STORES).toEqual(expect.arrayContaining(['legal_holds', 'safety_cases']));
  });

  test('without a hold, deletion still removes the moderation rows (control)', async () => {
    await db.doc('users/plain1').set({ x: 1 });
    await db.doc('moderation_queue/q-plain').set({ userId: 'plain1', status: 'pending' });
    const del = req('../../src/auth/accountDeletion');
    const report = await del.deleteAccountData('plain1', 'auth_trigger');
    expect(report.failures).toEqual([]);
    expect((await db.doc('moderation_queue/q-plain').get()).exists).toBe(false);
  });
});

// ===========================================================================
describe('CSAM hash list (public uploads only, EU-19)', () => {
  test('superAdmin imports hashes; exact and perceptual matches on public uploads open a CSAE case + legal hold; chat images are not scanned', async () => {
    const { computeImageHashes } = req('../../src/safety/takedowns/perceptualHash');
    const exact = await jpeg(21);
    const pdImg = await jpeg(23);
    const hExact = await computeImageHashes(exact);
    const hPd = await computeImageHashes(pdImg);
    await expect(adminCall('mod1', { op: 'importCsamHashes', entries: [{ algorithm: 'md5', hash: hExact.md5 }] }, 'moderator'))
      .rejects.toMatchObject({ code: 'permission-denied' });
    const imp = await adminCall('boss', {
      op: 'importCsamHashes',
      entries: [{ algorithm: 'md5', hash: hExact.md5, source: 'NCMEC' }, { algorithm: 'dhash', hash: hPd.dhash, source: 'industry' },
        { algorithm: 'md5', hash: 'not-a-hash' }],
    });
    expect(imp).toEqual({ added: 2, rejected: 1 });

    await put('profiles/u9/x.jpg', exact, { userId: 'u9' });
    await runUploadTrigger('profiles/u9/x.jpg', { userId: 'u9' });
    expect(await exists('profiles/u9/x.jpg')).toBe(false);
    await put('communities/u9/y.jpg', await jpeg(23, 50), { userId: 'u9' });
    await runUploadTrigger('communities/u9/y.jpg', { userId: 'u9' });
    expect(await exists('communities/u9/y.jpg')).toBe(false);

    const cs = (await db.collection('safety_cases').where('kind', '==', 'csae').get()).docs.map((d) => d.data());
    expect(cs).toHaveLength(2);
    expect(cs.map((c) => c.hashMatch.how).sort()).toEqual(['exact', 'perceptual']);
    expect(cs.every((c) => c.legalHoldId === 'csae_u9' && c.reportedUserId === 'u9')).toBe(true);
    const [held] = await bucket().getFiles({ prefix: 'legal_holds/csae_u9/files/' });
    expect(held.length).toBeGreaterThanOrEqual(2);

    await put('chat_images/c9/z.jpg', exact);
    await runUploadTrigger('chat_images/c9/z.jpg');
    expect(await exists('chat_images/c9/z.jpg')).toBe(true);
    // A private-album photo is not scanned either.
    await put('profiles/u8/priv.jpg', exact, { visibility: 'private' });
    await runUploadTrigger('profiles/u8/priv.jpg', { visibility: 'private' });
    expect(await exists('profiles/u8/priv.jpg')).toBe(true);
  });
});

// ===========================================================================
describe('report reasons', () => {
  test('new localized NCII / CSAE reasons map to P0 codes', () => {
    const { classifyReason, priorityFor } = req('../../src/safety/reportPipeline');
    expect(classifyReason('Intimate image shared without consent')).toBe('ncii');
    expect(classifyReason('Imagem íntima compartilhada sem consentimento')).toBe('ncii');
    expect(classifyReason('he posted revenge porn of me')).toBe('ncii');
    expect(classifyReason('Child sexual abuse or exploitation')).toBe('csae');
    expect(priorityFor('ncii')).toBe('P0');
  });
});
