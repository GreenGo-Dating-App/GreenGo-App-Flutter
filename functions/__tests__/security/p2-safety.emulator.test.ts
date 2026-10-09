/**
 * Phase 2 safety & consent (plan P2-6, P2-5, P2-8 remainder).
 *
 * Real Firestore + Auth + Storage emulators. Only Google Cloud Vision (OCR /
 * SafeSearch) and outbound fetch (Brevo) are stubbed.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Source modules are required lazily so that, against the pre-change code,
 * the new behaviour is what fails (not the import).
 */

import * as admin from 'firebase-admin';
import * as http from 'http';
import { createHash, createHmac } from 'crypto';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
}
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const auth = admin.auth();
const bucket = () => admin.storage().bucket();
const TS = admin.firestore.Timestamp;

process.env.RETENTION_SALT = 'test-retention-salt';
process.env.BREVO_API_KEY = 'test-brevo-key';

// --- Vision stub: tests set the OCR text / SafeSearch verdict per case -----
const vision = { text: '', annotate: {} as any };
jest.mock('@google-cloud/vision', () => {
  class ImageAnnotatorClient {
    textDetection = async () => [{ fullTextAnnotation: { text: (global as any).__visionText ?? '' } }];
    annotateImage = async () => [(global as any).__visionAnnotate ?? {}];
  }
  return { __esModule: true, default: { ImageAnnotatorClient }, ImageAnnotatorClient };
});
const setOcr = (t: string) => { vision.text = t; (global as any).__visionText = t; };
const setSafeSearch = (a: any) => { vision.annotate = a; (global as any).__visionAnnotate = a; };

const fetchMock = jest.fn(async (..._args: any[]) => ({
  ok: true, status: 200, statusText: 'OK',
  json: async () => ({ messageId: 'brevo-1' }), text: async () => '{}',
}));
(global as any).fetch = fetchMock;

// eslint-disable-next-line @typescript-eslint/no-var-requires
const req = (p: string): any => require(p);
const age = () => req('../../src/safety/ageAssurance');
const retention = () => req('../../src/safety/idDocumentRetention');

const v2 = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token } : undefined });
const v1 = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token } : undefined, rawRequest: {} });

function emulatorDelete(path: string) {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  return new Promise<void>((resolve, reject) => {
    const r = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    r.on('error', reject);
    r.end();
  });
}
async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Not a local emulator');
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Storage emulator required');
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
  await bucket().deleteFiles({ force: true }).catch(() => undefined);
}
const put = (path: string, metadata: Record<string, string> = {}) =>
  bucket().file(path).save(Buffer.from('img'), { contentType: 'image/jpeg', resumable: false, metadata: { metadata } });
const exists = async (path: string) => (await bucket().file(path).exists())[0];
const filesUnder = async (prefix: string) => (await bucket().getFiles({ prefix }))[0].map((f) => f.name);

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  setOcr('');
  setSafeSearch({});
});
afterAll(() => fft.cleanup());

// ===========================================================================
// P2-6 ID documents
// ===========================================================================
const U = 'idUser000000000000000000001';
const DOB = new Date(Date.UTC(1974, 7, 12));
const MRZ_TEXT = 'PASSPORT\nP<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<\nL898902C36UTO7408122F1204159ZE184226B<<<<<10';
const PENDING_TEXT = 'IDENTITY CARD\nDATE OF BIRTH 12.08.1974\nAB123456';

async function seedIdUser(uid = U, consent = true) {
  await db.doc(`profiles/${uid}`).set({ displayName: 'Anna' });
  await db.doc(`profiles_private/${uid}`).set({ dateOfBirth: TS.fromDate(DOB) });
  if (consent) {
    await db.doc(`consents/${uid}`).set({ id_verification: { accepted: true, version: 1, at: TS.now() } });
  }
  await put(`age_verification/${uid}/doc.jpg`);
}
const submit = (uid = U) =>
  v2(age().submitAgeDocument, { documentPath: `age_verification/${uid}/doc.jpg`, documentType: 'passport' }, uid);

describe('P2-6 ID document images are deleted once decided', () => {
  test('default policy: even a clean MRZ document stays PENDING until an admin decides', async () => {
    delete process.env.ID_AUTO_VERIFY;
    await seedIdUser();
    setOcr(MRZ_TEXT);
    const r = await submit();
    expect(r.status).toBe('pending');
    expect((await db.doc(`age_verification_queue/${U}`).get()).data()).toMatchObject({ status: 'pending' });
    expect(await filesUnder(`id_documents/${U}/`)).toHaveLength(1);
    expect((await db.doc(`profiles/${U}`).get()).data()!.isAgeVerified).not.toBe(true);
  });

  test('automatic APPROVE (ID_AUTO_VERIFY=true): image deleted, only {ageVerified, method, decidedAt, birthYear} kept, HMAC fingerprint', async () => {
    process.env.ID_AUTO_VERIFY = 'true';
    await seedIdUser();
    setOcr(MRZ_TEXT);
    const r = await submit().finally(() => { delete process.env.ID_AUTO_VERIFY; });
    expect(r.status).toBe('verified');

    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
    expect(await filesUnder(`age_verification/${U}/`)).toEqual([]);
    expect(await filesUnder('retention/')).toEqual([]);

    const index = (await db.doc(`id_documents/${U}`).get()).data()!;
    expect(Object.keys(index).sort()).toEqual(['ageVerified', 'birthYear', 'decidedAt', 'imageDeleted', 'method']);
    expect(index).toMatchObject({ ageVerified: true, method: 'document', birthYear: 1974, imageDeleted: true });

    const priv = (await db.doc(`profiles_private/${U}`).get()).data()!.ageVerification;
    const pub = (await db.doc(`profiles/${U}`).get()).data()!;
    expect(pub.isAgeVerified).toBe(true);
    expect(pub.ageVerification.documentDateOfBirth).toBeUndefined();
    expect(priv.documentDateOfBirth).toBeUndefined();
    expect(priv.documentBirthYear).toBe(1974);
    // Salted HMAC, not the guessable plain SHA-256 of the number.
    const num = 'PASSPORT';
    expect(priv.documentHash).toBe(
      createHmac('sha256', 'test-retention-salt').update(`passport:${num}`).digest('hex'));
    expect(priv.documentHash).not.toBe(createHash('sha256').update(`passport:${num}`).digest('hex'));
    // INC-2026-001: the fingerprint is private only, never on the public profile.
    expect(pub.ageVerification.documentHash).toBeUndefined();
  });

  test('automatic REJECT (no birth date): image deleted', async () => {
    await seedIdUser();
    setOcr('blurry nothing here');
    const r = await submit();
    expect(r).toMatchObject({ status: 'rejected', reason: 'noBirthDateFound' });
    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
    expect(await filesUnder(`age_verification/${U}/`)).toEqual([]);
    expect((await db.doc(`id_documents/${U}`).get()).data()).toMatchObject({ ageVerified: false, imageDeleted: true });
  });

  test('a document fingerprinted with the LEGACY unsalted hash still blocks reuse', async () => {
    await seedIdUser();
    const legacy = createHash('sha256').update('passport:PASSPORT').digest('hex');
    await db.doc('profiles_private/other').set({ ageVerification: { documentHash: legacy } });
    setOcr(MRZ_TEXT);
    const r = await submit();
    expect(r).toMatchObject({ status: 'rejected', reason: 'documentAlreadyUsed' });
    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
  });

  test('pending review keeps the image; ADMIN decision deletes it; viewer reports "image deleted"', async () => {
    await seedIdUser();
    setOcr(PENDING_TEXT);
    expect((await submit()).status).toBe('pending');
    const kept = await filesUnder(`id_documents/${U}/`);
    expect(kept).toHaveLength(1);
    const idx = (await db.doc(`id_documents/${U}`).get()).data()!;
    expect(idx.status).toBe('pending');
    expect(idx.purgeImageAfter.toMillis() - idx.uploadedAt.toMillis()).toBe(7 * 86400000);

    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    const before = await v2(age().getAgeVerificationDetails, { userId: U }, 'boss');
    expect(before.document).not.toBeNull();
    expect(before.imageDeleted).toBe(false);

    await db.doc('admin_users/mod').set({ role: 'moderator' });
    const res = await v2(age().reviewAgeVerification, { userId: U, approve: true }, 'mod');
    expect(res.status).toBe('verified');
    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
    expect(Object.keys((await db.doc(`id_documents/${U}`).get()).data()!).sort())
      .toEqual(['ageVerified', 'birthYear', 'decidedAt', 'imageDeleted', 'method']);
    const q = (await db.doc(`age_verification_queue/${U}`).get()).data()!;
    expect(q.status).toBe('approved');
    expect(q.documentDateOfBirth).toBeUndefined();
    expect(q.documentBirthYear).toBe(1974);

    const after = await v2(age().getAgeVerificationDetails, { userId: U }, 'boss');
    expect(after.document).toBeNull();
    expect(after.imageDeleted).toBe(true);
    expect(after.documentError).toMatch(/deleted/i);
    expect(after.documentBirthYear).toBe(1974);
  });

  test('admin REJECT deletes the image and legacy retention copies (legal hold kept)', async () => {
    await seedIdUser();
    setOcr(PENDING_TEXT);
    await submit();
    await put(`retention/${U}/old.jpg`);
    await put(`retention/${U}/held.jpg`);
    await db.collection('id_document_retention').add({ uid: U, storagePaths: [`retention/${U}/old.jpg`], purgeAfter: TS.fromMillis(Date.now() + 20 * 86400000), legalHold: false });
    await db.collection('id_document_retention').add({ uid: U, storagePaths: [`retention/${U}/held.jpg`], purgeAfter: TS.fromMillis(Date.now() + 20 * 86400000), legalHold: true });

    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await v2(age().reviewAgeVerification, { userId: U, approve: false, reason: 'blurry' }, 'mod');
    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
    expect(await exists(`retention/${U}/old.jpg`)).toBe(false);
    expect(await exists(`retention/${U}/held.jpg`)).toBe(true);
    const left = await db.collection('id_document_retention').where('uid', '==', U).get();
    expect(left.docs.map((d) => d.data().legalHold)).toEqual([true]);
  });

  test('undecided image older than 7 days is purged; user must re-upload; late approval refused', async () => {
    await seedIdUser();
    setOcr(PENDING_TEXT);
    await submit();
    // Not yet due.
    await retention().runIdDocumentPurge(Date.now() + 6 * 86400000);
    expect(await filesUnder(`id_documents/${U}/`)).toHaveLength(1);

    const stats = await retention().runIdDocumentPurge(Date.now() + 8 * 86400000);
    expect(stats.expired).toBe(1);
    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
    expect((await db.doc(`profiles/${U}`).get()).data()!.ageVerification)
      .toMatchObject({ status: 'rejected', rejectionReason: 'reuploadRequired' });
    const q = (await db.doc(`age_verification_queue/${U}`).get()).data()!;
    expect(q.status).toBe('expired');
    expect(q.documentDateOfBirth).toBeUndefined();

    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await expect(v2(age().reviewAgeVerification, { userId: U, approve: true }, 'mod'))
      .rejects.toMatchObject({ code: 'failed-precondition' });
  });

  test('daily sweep deletes LEGACY decided images and legacy retention entries now', async () => {
    await put('id_documents/legacy1/1_doc.jpg');
    await db.doc('id_documents/legacy1').set({ currentPath: 'id_documents/legacy1/1_doc.jpg', status: 'verified', uploadedAt: TS.now() });
    await db.doc('profiles_private/legacy1').set({ ageVerification: { documentDateOfBirth: TS.fromDate(DOB) } });
    await put('retention/legacy2/a.jpg');
    await db.collection('id_document_retention').add({ uid: 'legacy2', storagePaths: ['retention/legacy2/a.jpg'], purgeAfter: TS.fromMillis(Date.now() + 25 * 86400000), legalHold: false });

    await retention().runIdDocumentPurge(Date.now());
    expect(await exists('id_documents/legacy1/1_doc.jpg')).toBe(false);
    expect((await db.doc('id_documents/legacy1').get()).data()).toMatchObject({ ageVerified: true, birthYear: 1974, imageDeleted: true });
    expect((await db.doc('id_documents/legacy1').get()).data()!.currentPath).toBeUndefined();
    expect(await exists('retention/legacy2/a.jpg')).toBe(false);
    expect((await db.collection('id_document_retention').get()).size).toBe(0);
  });
});

describe('P2-6 explicit consent before upload', () => {
  test('ENFORCED: no recorded id_verification consent -> refused and the upload deleted', async () => {
    await seedIdUser(U, false);
    await db.doc('app_config/compliance').set({ idConsentRequired: true });
    setOcr(MRZ_TEXT);
    await expect(submit()).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await filesUnder(`age_verification/${U}/`)).toEqual([]);
    expect(await filesUnder(`id_documents/${U}/`)).toEqual([]);
  });

  test('GRACE path (old apps): accepted but flagged consentMissing', async () => {
    await seedIdUser(U, false);
    setOcr(PENDING_TEXT);
    expect((await submit()).status).toBe('pending');
    expect((await db.doc(`id_documents/${U}`).get()).data()!.consentMissing).toBe(true);
    expect((await db.doc(`age_verification_queue/${U}`).get()).data()!.consentMissing).toBe(true);
  });

  test('recordConsent accepts the new consent types (with docVersion) and still rejects unknown ones', async () => {
    const { recordConsent } = req('../../src/ai/aiGateway');
    for (const type of ['id_verification', 'analytics', 'marketing_email', 'marketing_push', 'terms', 'privacy', 'profiling', 'third_party_data']) {
      await v2(recordConsent, { type, version: 1, accepted: type !== 'profiling', locale: 'it_IT', docVersion: '1.0' }, 'c1');
    }
    const c = (await db.doc('consents/c1').get()).data()!;
    expect(c.terms).toMatchObject({ accepted: true, version: 1, locale: 'it_IT', docVersion: '1.0' });
    expect(c.profiling.accepted).toBe(false);
    expect((await db.collection('consents/c1/events').get()).size).toBe(8);
    await expect(v2(recordConsent, { type: 'everything', version: 1, accepted: true }, 'c1')).rejects.toBeTruthy();
  });
});

// ===========================================================================
// P2-5 marketing
// ===========================================================================
describe('P2-5b marketing e-mail needs an explicit opt-in', () => {
  async function seedEmailUser(uid: string, optIn: boolean | null) {
    await db.doc(`users/${uid}`).set({
      email: `${uid}@example.com`, displayName: uid, accountStatus: 'active', lastActiveAt: TS.now(),
    });
    await db.collection('likes').add({ likedUserId: uid, createdAt: TS.now() });
    if (optIn !== null) await db.doc(`consents/${uid}`).set({ marketing_email: { accepted: optIn, version: 1 } });
  }
  /**
   * NOTE: the built-in default templates cannot be sent at all today
   * (emailLog.templateId is `undefined`, which Firestore rejects) - a
   * pre-existing bug reported, not fixed here. Stored templates work, and
   * pre-P2-5 ones link to greengo.app/unsubscribe, which must be rewritten.
   */
  async function seedTemplates() {
    for (const t of ['weekly_digest', 'inactive_7_days', 'password_reset_success']) {
      await db.doc(`email_templates/${t}`).set({
        isActive: true, subject: `${t} {{userName}}`,
        htmlContent: '<p>Hi {{userName}}</p><a href="https://greengo.app/unsubscribe">Unsubscribe</a>',
      });
    }
  }
  const brevoCalls = () => fetchMock.mock.calls.filter((c) => String(c[0]).includes('brevo.com/v3/smtp/email'));

  test('weekly digest goes ONLY to the opted-in user, with a working unsubscribe link', async () => {
    await seedEmailUser('optedIn', true);
    await seedEmailUser('noRecord', null);
    await seedEmailUser('optedOut', false);
    await seedTemplates();
    const brevo = req('../../src/notifications/brevoEmailService');
    await (brevo.sendBrevoWeeklyDigest as any).run({});
    const calls = brevoCalls();
    expect(calls).toHaveLength(1);
    const body = JSON.parse((calls[0][1] as any).body);
    expect(body.to[0].email).toBe('optedIn@example.com');
    expect(body.htmlContent).not.toMatch(/greengo\.app\/unsubscribe/);
    expect(body.htmlContent).toMatch(/unsubscribeMarketing\?u=optedIn&t=[0-9a-f]{32}/);
    expect(body.headers['List-Unsubscribe']).toMatch(/unsubscribeMarketing\?u=optedIn/);
    expect(body.headers['List-Unsubscribe-Post']).toBe('List-Unsubscribe=One-Click');
  });

  test('sendBrevoEmail refuses a marketing trigger without opt-in (no caller can bypass)', async () => {
    await seedEmailUser('noRecord', null);
    await seedTemplates();
    const brevo = req('../../src/notifications/brevoEmailService');
    await expect(brevo.sendBrevoEmail({ userId: 'noRecord', trigger: 'inactive_7_days' }))
      .rejects.toThrow('MARKETING_OPT_IN_REQUIRED');
    expect(brevoCalls()).toHaveLength(0);
    // Service mail is unaffected.
    await brevo.sendBrevoEmail({ userId: 'noRecord', trigger: 'password_reset_success' });
    expect(brevoCalls()).toHaveLength(1);
  });

  test('unsubscribe link: GET changes nothing, POST records the opt-out, a forged token is refused', async () => {
    await seedEmailUser('optedIn', true);
    const { handleUnsubscribe } = req('../../src/notifications/marketingUnsubscribe');
    const { unsubscribeToken } = req('../../src/shared/marketingConsent');
    const mk = () => {
      const r: any = { statusCode: 0, headers: {}, body: '' };
      r.status = (c: number) => { r.statusCode = c; return r; };
      r.set = (k: string, v: string) => { r.headers[k] = v; return r; };
      r.type = () => r;
      r.send = (b: any) => { r.body = b; return r; };
      return r;
    };
    const t = unsubscribeToken('optedIn');
    const get = mk();
    await handleUnsubscribe({ method: 'GET', query: { u: 'optedIn', t } }, get);
    expect(get.statusCode).toBe(200);
    expect((await db.doc('consents/optedIn').get()).data()!.marketing_email.accepted).toBe(true);

    const forged = mk();
    await handleUnsubscribe({ method: 'POST', query: { u: 'optedIn', t: '0'.repeat(32) } }, forged);
    expect(forged.statusCode).toBe(400);
    expect((await db.doc('consents/optedIn').get()).data()!.marketing_email.accepted).toBe(true);

    const post = mk();
    await handleUnsubscribe({ method: 'POST', query: { u: 'optedIn', t }, body: { 'List-Unsubscribe': 'One-Click' } }, post);
    expect(post.statusCode).toBe(200);
    expect((await db.doc('consents/optedIn').get()).data()!.marketing_email).toMatchObject({ accepted: false, source: 'unsubscribe_link' });
  });
});

describe('P2-5c marketing push category (default OFF)', () => {
  test('shouldNotify(marketing) is false by default and true only after opt-in', async () => {
    const { shouldNotify, categoryForType } = req('../../src/notifications/prefs');
    expect(await shouldNotify('p0', 'marketing')).toBe(false);
    await db.doc('notification_preferences/p1').set({ pushEnabled: true, categories: { exchanges: true } });
    expect(await shouldNotify('p1', 'marketing')).toBe(false);
    await db.doc('notification_preferences/p2').set({ pushEnabled: true, categories: { marketing: true } });
    expect(await shouldNotify('p2', 'marketing')).toBe(true);
    expect(categoryForType('marketing_promo')).toBe('marketing');
  });

  test('sendBroadcastNotification reaches only users who turned marketing ON', async () => {
    jest.spyOn(admin.messaging(), 'sendEach').mockImplementation(async (msgs: any[]) =>
      ({ successCount: msgs.length, failureCount: 0, responses: msgs.map(() => ({ success: true })) }) as any);
    for (const uid of ['in1', 'out1', 'default1']) {
      await db.doc(`users/${uid}`).set({ notificationsEnabled: true, fcmToken: `tok_${uid}`, preferredLanguage: 'en' });
    }
    await db.doc('notification_preferences/in1').set({ categories: { marketing: true } });
    await db.doc('notification_preferences/out1').set({ categories: { marketing: false } });
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    const { sendBroadcastNotification } = req('../../src/admin/mvp_access');
    const r = await v2(sendBroadcastNotification, { messageType: 'custom', customTitle: { en: 'Sale' }, customBody: { en: '50% off' } }, 'boss');
    expect(r.successCount).toBe(1);
    const notifs = await db.collection('notifications').where('type', '==', 'broadcast').get();
    expect(notifs.docs.map((d) => d.data().userId)).toEqual(['in1']);
  });
});

// ===========================================================================
// P2-8 moderation
// ===========================================================================
describe('P2-8a every image is moderated, private albums included', () => {
  test('a PRIVATE album image flagged by SafeSearch is quarantined and queued', async () => {
    process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
    const { moderateUploadedImage } = req('../../src/safety/moderateUploadedImage');
    const path = 'profiles/priv1/photos/p.jpg';
    await put(path, { visibility: 'private' });
    setSafeSearch({ safeSearchAnnotation: { adult: 'VERY_LIKELY' }, labelAnnotations: [] });
    // fft.wrap() cannot build a v2 storage CloudEvent here (ts-deepmerge interop); call the handler directly.
    await (moderateUploadedImage as any).run({
      data: { name: path, bucket: `${PROJECT}.appspot.com`, contentType: 'image/jpeg', metadata: { visibility: 'private' } },
    });
    expect(await exists(path)).toBe(false);
    expect(await exists(`quarantine/${path}`)).toBe(true);
    const q = await db.collection('moderation_queue').where('objectPath', '==', path).get();
    expect(q.size).toBe(1);
    expect(q.docs[0].data()).toMatchObject({ visibility: 'private', status: 'pending_review' });
  });
});

describe('P2-8b server-side text screening of shared chats (flag-for-review only)', () => {
  const fire = async (trigger: any, col: string, chatParam: string, chatId: string, id: string, msg: any) => {
    await db.doc(`${col}/${chatId}/messages/${id}`).set(msg);
    const snap = await db.doc(`${col}/${chatId}/messages/${id}`).get();
    await (fft.wrap(trigger) as any)({ data: snap, params: { [chatParam]: chatId, messageId: id } });
  };

  test('a threatening group message is queued with source auto_text; no automatic action', async () => {
    const m = req('../../src/safety/autoTextModeration');
    await db.doc('users/spk').set({ accountStatus: 'active' });
    await fire(m.screenGroupMessage, 'groups', 'groupId', 'g1', 'm1',
      { senderId: 'spk', type: 'text', content: 'I will kill you tomorrow', sentAt: TS.now() });
    const q = await db.collection('moderation_queue').get();
    expect(q.size).toBe(1);
    expect(q.docs[0].data()).toMatchObject({
      status: 'pending', itemType: 'autoTextFlag', reasonCode: 'threats', reporterId: 'system',
      source: { collection: 'auto_text', path: 'groups/g1/messages/m1' },
      contentRef: { type: 'message', path: 'groups/g1/messages/m1' },
    });
    // Nothing automatic happened to the sender or the message.
    expect((await db.doc('users/spk').get()).data()).toEqual({ accountStatus: 'active' });
    expect((await db.doc('groups/g1/messages/m1').get()).data()!.content).toBe('I will kill you tomorrow');
  });

  test('community + event chats are screened; clean text and 1:1 chats are not queued; re-delivery is idempotent', async () => {
    const m = req('../../src/safety/autoTextModeration');
    await fire(m.screenCommunityMessage, 'communities', 'communityId', 'c1', 'm1',
      { senderId: 'a', text: 'pay me via paypal and I hold the spot' });
    await fire(m.screenEventMessage, 'events', 'eventId', 'e1', 'm1', { senderId: 'b', text: 'see you at 8!' });
    const snap = await db.doc('communities/c1/messages/m1').get();
    await (fft.wrap(m.screenCommunityMessage) as any)({ data: snap, params: { communityId: 'c1', messageId: 'm1' } });
    const q = await db.collection('moderation_queue').get();
    expect(q.docs.map((d) => d.data().reasonCode)).toEqual(['off_platform_payment']);
    expect(m.screenText('hello there, how are you?')).toBeNull();
  });

  test('per-sender daily cap bounds the queue (child-safety hits are never capped)', async () => {
    const m = req('../../src/safety/autoTextModeration');
    for (let i = 0; i < m.MAX_FLAGS_PER_SENDER_PER_DAY + 3; i++) {
      await m.screenChatMessage('group', 'g1', `x${i}`, `groups/g1/messages/x${i}`, { senderId: 'spam1', content: 'send me bitcoin now' });
    }
    expect((await db.collection('moderation_queue').get()).size).toBe(m.MAX_FLAGS_PER_SENDER_PER_DAY);
    await m.screenChatMessage('group', 'g1', 'csae', 'groups/g1/messages/csae', { senderId: 'spam1', content: 'selling child porn' });
    expect((await db.collection('moderation_queue').where('reasonCode', '==', 'csae').get()).size).toBe(1);
  });
});

describe('P2-8c statement of reasons + appeal (DSA art. 17/20)', () => {
  const modCtx = { auth: { uid: 'mod1', token: { adminRole: 'moderator' } } };

  async function queueItemFor(userId: string) {
    const m = req('../../src/safety/autoTextModeration');
    await db.doc(`users/${userId}`).set({ preferredLanguage: 'it', accountStatus: 'active' });
    await m.screenChatMessage('group', 'g9', 'mm', 'groups/g9/messages/mm', { senderId: userId, content: 'I will kill you' });
    await db.doc('groups/g9/messages/mm').set({ senderId: userId, content: 'I will kill you' });
    return (await db.collection('moderation_queue').get()).docs[0].id;
  }

  test('the affected user is notified with the reasons and can appeal ONCE', async () => {
    await db.doc('admin_users/mod1').set({ role: 'moderator' });
    const queueId = await queueItemFor('bob');
    const { takeModerationAction } = req('../../src/admin/moderationQueue');
    await (fft.wrap(takeModerationAction) as any)(
      { queueId, action: 'removeContent', reasonCode: 'threats', explanation: 'Threatening another member.' }, modCtx);

    // The flagged shared-chat message was removable.
    expect((await db.doc('groups/g9/messages/mm').get()).data()).toMatchObject({ isDeletedForEveryone: true, content: 'This message was removed by a moderator' });

    const n = await db.collection('notifications').where('userId', '==', 'bob').get();
    expect(n.size).toBe(1);
    expect(n.docs[0].data()).toMatchObject({
      type: 'system',
      title: 'Una decisione di moderazione sul tuo account',
      data: { action: 'moderation_decision', decisionId: queueId, moderationAction: 'removeContent', reasonCode: 'threats', explanation: 'Threatening another member.', appealable: 'true' },
    });
    const d = (await db.doc(`moderation_decisions/${queueId}`).get()).data()!;
    expect(d.appealDeadline.toMillis() - d.decidedAt.toMillis()).toBeGreaterThanOrEqual(182 * 86400000);

    const { submitAppeal } = req('../../src/safety/reportingSystem');
    await expect(v1(submitAppeal, { decisionId: queueId, appealReason: 'It was a joke between friends.' }, 'mallory'))
      .rejects.toMatchObject({ code: 'permission-denied' });
    const r = await v1(submitAppeal, { decisionId: queueId, appealReason: 'It was a joke between friends.' }, 'bob');
    expect(r.status).toBe('submitted');
    expect((await db.doc(`report_appeals/${r.appealId}`).get()).data()).toMatchObject({ userId: 'bob', decisionId: queueId, status: 'pending' });
    expect((await db.doc(`moderation_queue/appeal__${queueId}`).get()).data()).toMatchObject({ itemType: 'appeal', status: 'pending', userId: 'bob' });
    await expect(v1(submitAppeal, { decisionId: queueId, appealReason: 'Second try, please look again.' }, 'bob'))
      .rejects.toMatchObject({ code: 'already-exists' });
  });

  test('appeal after the window is refused; approve/dismiss send no decision notice', async () => {
    await db.doc('moderation_decisions/old1').set({
      userId: 'bob', queueId: 'old1', action: 'issueWarning', appealable: true,
      appealDeadline: TS.fromMillis(Date.now() - 1000), appealStatus: null,
    });
    const { submitAppeal } = req('../../src/safety/reportingSystem');
    await expect(v1(submitAppeal, { decisionId: 'old1', appealReason: 'Please review this again.' }, 'bob'))
      .rejects.toMatchObject({ code: 'failed-precondition' });

    await db.doc('admin_users/mod1').set({ role: 'moderator' });
    const queueId = await queueItemFor('carol');
    const { takeModerationAction } = req('../../src/admin/moderationQueue');
    await (fft.wrap(takeModerationAction) as any)({ queueId, action: 'dismiss', reasonCode: 'no_violation', explanation: 'No violation found.' }, modCtx);
    expect((await db.collection('notifications').where('userId', '==', 'carol').get()).size).toBe(0);
  });
});

describe('BIPA: unused selfie / ID-OCR callables are no longer exported', () => {
  test('verifyPhotoSelfie, verifyIDDocument, startPhotoVerification are not deployed', () => {
    const src = require('fs').readFileSync(require('path').join(__dirname, '../../src/index.ts'), 'utf8');
    const exported = src.replace(/\/\/.*$/gm, '');
    expect(exported).not.toMatch(/\bverifyPhotoSelfie\b/);
    expect(exported).not.toMatch(/\bverifyIDDocument\b/);
    expect(exported).not.toMatch(/\bstartPhotoVerification\b/);
  });
});
