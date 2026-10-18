/**
 * Terms compliance W3 against the emulators (Firestore + Auth):
 *  1. adminSendTermsChangeNotice (Terms 24.2 a): superAdmin only, dry run by
 *     default (no email, no claim), bounded pages with a cursor, one email per
 *     user + version (re-run = alreadySent), the user's app language, run
 *     counters, refused after the effective date, accounts created on or
 *     after accountsCreatedBefore (16 Oct 2026) skipped.
 *  2. saveMyTraderDeclaration / getMyTraderDeclaration (Terms 12.4, DSA art.
 *     30): validation, invoice-details reuse, masked ID number, public part.
 *  3. requestHumanSupport (Terms 14.1): owner only, escalates once, posts the
 *     handoff message once.
 *  4. recordConsent accepts promotional_use (Terms 15.3).
 *  5. Rules (run with firestore.additive.rules - production - and with
 *     firestore.rules): trader_declarations and legal_notice_runs are
 *     admin-only, trader_public is signed-in read-only.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest --config jest.security.config.js -i terms-w3"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const fft = functionsTest({ projectId: PROJECT });

import { emailDeps, EMAIL_DISPATCH } from '../../src/emails/sendEmail';
import { adminSendTermsChangeNotice, noticeKey, NOTICE_RUNS } from '../../src/legal/termsChangeNotice';
import { getMyTraderDeclaration, saveMyTraderDeclaration, TRADER, TRADER_PUBLIC } from '../../src/legal/traderDeclaration';
import { requestHumanSupport } from '../../src/admin/supportHandoff';
import { recordConsent } from '../../src/ai/aiGateway';

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

const wrap = (fn: any) => (data: any, uid?: string) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token: {} } : undefined });

async function expectCode(p: Promise<unknown>, code: string, message?: RegExp) {
  await expect(p).rejects.toMatchObject({ code });
  if (message) await expect(p).rejects.toThrow(message);
}

// ---- REST as a real client (rules apply) ---------------------------------
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
async function rest(uid: string | null, method: string, p: string, body?: any): Promise<number> {
  const res = await fetch(`${base()}/${p}`, {
    method,
    headers: { ...(uid ? { Authorization: `Bearer ${idToken(uid)}` } : {}), 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  await res.text();
  return res.status;
}

// ---- outbound email mock ---------------------------------------------------
const sent: any[] = [];
const realFetch = emailDeps.fetch;
const realNow = emailDeps.now;
beforeAll(() => {
  process.env.RESEND_API_KEY = 'test-key';
  emailDeps.fetch = async (_url: string, init: any) => {
    sent.push(JSON.parse(init.body));
    return { ok: true, status: 200 };
  };
  emailDeps.now = () => Date.parse('2026-10-16T12:00:00Z');
});
afterAll(() => {
  emailDeps.fetch = realFetch;
  emailDeps.now = realNow;
  delete process.env.RESEND_API_KEY;
  return fft.cleanup();
});

// Accounts created before 16 Oct 2026 by default (the ones notified of 5.3.2).
async function makeUser(uid: string, email: string | null, appLanguage?: string,
  creationTime = 'Thu, 01 Oct 2026 10:00:00 GMT') {
  try {
    await admin.auth().deleteUser(uid);
  } catch {
    // not there
  }
  const r = await admin.auth().importUsers([{ uid, ...(email ? { email } : {}), metadata: { creationTime, lastSignInTime: creationTime } }]);
  if (r.failureCount) throw new Error(`importUsers failed: ${JSON.stringify(r.errors)}`);
  await db.doc(`users/${uid}`).set({ ...(appLanguage ? { appLanguage } : {}), createdAt: admin.firestore.Timestamp.now() });
}

describe('adminSendTermsChangeNotice', () => {
  const call = wrap(adminSendTermsChangeNotice);
  beforeAll(async () => {
    await clearAll();
    sent.length = 0;
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await makeUser('n_a', 'a@example.com', 'it');
    await makeUser('n_b', 'b@example.com', 'pt_BR');
    await makeUser('n_c', 'c@example.com');
    await makeUser('n_d', null, 'de');
    await makeUser('n_e', 'e@example.com', 'de');
    // Created on 16 Oct 2026: accepted 5.3.x at sign-up, never notified.
    await makeUser('n_f', 'f@example.com', 'en', 'Fri, 16 Oct 2026 08:00:00 GMT');
  });

  test('superAdmin only; known versions only', async () => {
    await expectCode(call({ version: '5.3.2' }), 'unauthenticated');
    await expectCode(call({ version: '5.3.2' }, 'mod'), 'permission-denied');
    await expectCode(call({ version: '5.3.2' }, 'nobody'), 'permission-denied');
    await expectCode(call({ version: '9.9.9' }, 'boss'), 'invalid-argument', /unknown_version/);
    // 5.3.2 (after 5.3.1) replaced 5.3.0 before it took effect for existing accounts.
    await expectCode(call({ version: '5.3.0' }, 'boss'), 'invalid-argument', /unknown_version/);
  });

  test('dry run is the default: counts, preview, no email, no claim, no run record', async () => {
    const r = await call({ version: '5.3.2' }, 'boss');
    expect(r).toMatchObject({ dryRun: true, sent: 0, failed: 0, alreadySent: 0, done: true, nextCursor: null,
      effectiveDate: '2026-11-16', url: 'https://greengochat.com/terms-of-service/upcoming' });
    // 6 users docs + the 2 admin_users are not users: processed counts users docs only.
    expect(r.processed).toBe(6);
    expect(r.withEmail).toBe(4);
    expect(r.skippedNoEmail).toBe(1);
    expect(r.skippedNewAccounts).toBe(1);
    expect(r.locales).toEqual({ it: 1, pt_BR: 1, en: 1, de: 1 });
    expect(r.noticeDaysLeft).toBe(30);
    expect(r.preview.subject).toContain('16 November 2026');
    expect(sent).toHaveLength(0);
    expect((await db.collection(EMAIL_DISPATCH).get()).size).toBe(0);
    expect((await db.doc(`${NOTICE_RUNS}/terms_5.3.2`).get()).exists).toBe(false);
  });

  test('live run in pages of 2, each user once, in their language; a re-run sends nothing', async () => {
    let cursor: string | null = null;
    let pages = 0;
    let total = 0;
    do {
      const r: any = await call({ version: '5.3.2', dryRun: false, pageSize: 2, cursor }, 'boss');
      pages++;
      total += r.sent;
      expect(r.processed).toBeLessThanOrEqual(2);
      cursor = r.nextCursor;
    } while (cursor && pages < 10);
    expect(pages).toBe(4);
    expect(total).toBe(4);
    expect(sent).toHaveLength(4);
    expect(sent.map((m) => m.to[0])).not.toContain('f@example.com');
    const byTo = Object.fromEntries(sent.map((m) => [m.to[0], m]));
    expect(byTo['a@example.com'].subject).toMatch(/^I nostri Termini cambiano il 16 novembre 2026/);
    expect(byTo['b@example.com'].subject).toMatch(/^Nossos Termos mudam em 16 de novembro de 2026/);
    expect(byTo['c@example.com'].subject).toMatch(/^Our Terms are changing on 16 November 2026/);
    expect(byTo['e@example.com'].text).toContain('billing@greengochat.com');
    const claim = (await db.doc(`${EMAIL_DISPATCH}/${noticeKey('5.3.2', 'n_a')}`).get()).data()!;
    expect(claim.status).toBe('sent');
    const run = (await db.doc(`${NOTICE_RUNS}/terms_5.3.2`).get()).data()!;
    expect(run).toMatchObject({ sent: 4, skippedNoEmail: 1, skippedNewAccounts: 1, done: true, updatedBy: 'boss' });

    const again = await call({ version: '5.3.2', dryRun: false, pageSize: 500 }, 'boss');
    expect(again).toMatchObject({ sent: 0, alreadySent: 4, done: true });
    expect(sent).toHaveLength(4);
    const dry = await call({ version: '5.3.2' }, 'boss');
    expect(dry.alreadySent).toBe(4);
  });

  test('refused once the change has taken effect', async () => {
    emailDeps.now = () => Date.parse('2026-11-16T00:00:00Z');
    try {
      await expectCode(call({ version: '5.3.2', dryRun: false }, 'boss'), 'failed-precondition', /notice_period_over/);
    } finally {
      emailDeps.now = () => Date.parse('2026-10-16T12:00:00Z');
    }
  });
});

describe('trader declaration', () => {
  const save = wrap(saveMyTraderDeclaration);
  const get = wrap(getMyTraderDeclaration);
  const valid = {
    isTrader: true, name: 'Bar do Zé Srl',
    address: { street: 'Via Roma', number: '1', city: 'Roma', postalCode: '00100', country: 'IT' },
    phone: '+39 06 123456', email: 'ze@example.com', idNumber: 'AB1234567',
    tradeRegister: 'Registro Imprese Roma', tradeRegisterNumber: 'RM-123', selfCertified: true,
  };
  beforeAll(async () => {
    await clearAll();
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
  });

  test('sign-in required; field errors carry the field', async () => {
    await expectCode(save(valid), 'unauthenticated');
    const p = save({ ...valid, selfCertified: false }, 'host1');
    await expect(p).rejects.toMatchObject({ code: 'invalid-argument', details: { field: 'selfCertified', code: 'required' } });
    expect((await db.doc(`${TRADER}/host1`).get()).exists).toBe(false);
  });

  test('trader: server-only record + public part without the ID number; owner sees it masked', async () => {
    const r = await save(valid, 'host1');
    expect(r.declaration).toMatchObject({ isTrader: true, name: 'Bar do Zé Srl', idNumberMasked: '•••••4567' });
    expect(JSON.stringify(r)).not.toContain('AB1234567');
    const full = (await db.doc(`${TRADER}/host1`).get()).data()!;
    expect(full).toMatchObject({ idNumber: 'AB1234567', idNumberSource: 'own', selfCertified: true, version: 1 });
    expect(full.selfCertifiedAt).toBeTruthy();
    const pub = (await db.doc(`${TRADER_PUBLIC}/host1`).get()).data()!;
    expect(pub).toMatchObject({ isTrader: true, name: 'Bar do Zé Srl', phone: '+39 06 123456', tradeRegisterNumber: 'RM-123' });
    expect(pub.address).toContain('Roma');
    expect(JSON.stringify(pub)).not.toContain('AB1234567');
    // Re-save without retyping the ID number keeps it; declaredAt is kept.
    const declaredAt = full.declaredAt.toMillis();
    await save({ ...valid, idNumber: '' }, 'host1');
    const again = (await db.doc(`${TRADER}/host1`).get()).data()!;
    expect(again.idNumber).toBe('AB1234567');
    expect(again.declaredAt.toMillis()).toBe(declaredAt);
  });

  test('reuses the invoice details (tax id never sent to the client)', async () => {
    await db.doc('finance_billing_profiles/host2').set({
      type: 'company', country: 'IT', legalName: 'Gelato Srl', taxId: 'IT00743110157', email: 'fatture@gelato.it', phone: '+39 02 1',
      address: { street: 'Corso Como', number: '5', complement: '', district: '', city: 'Milano', region: 'MI', postalCode: '20154', country: 'IT' },
    });
    const g = await get({}, 'host2');
    expect(g.declaration).toBeNull();
    expect(g.billing).toMatchObject({ legalName: 'Gelato Srl', hasTaxId: true });
    expect(JSON.stringify(g)).not.toContain('IT00743110157');
    await save({ isTrader: true, useBillingProfile: true, selfCertified: true }, 'host2');
    const full = (await db.doc(`${TRADER}/host2`).get()).data()!;
    expect(full).toMatchObject({ name: 'Gelato Srl', idNumber: 'IT00743110157', idNumberSource: 'billing', email: 'fatture@gelato.it' });
  });

  test('non-trader', async () => {
    await save({ isTrader: false }, 'host3');
    expect((await db.doc(`${TRADER_PUBLIC}/host3`).get()).data()).toMatchObject({ isTrader: false });
    expect((await get({}, 'host3')).declaration).toMatchObject({ isTrader: false });
  });

  test('rules: declarations and notice runs admin-only; public part signed-in read-only', async () => {
    await db.doc(`${NOTICE_RUNS}/terms_5.3.2`).set({ sent: 1 });
    expect(await rest('host1', 'GET', `${TRADER}/host1`)).toBe(403);
    expect(await rest('other', 'GET', `${TRADER}/host1`)).toBe(403);
    expect(await rest('boss', 'GET', `${TRADER}/host1`)).toBe(200);
    expect(await rest('host1', 'PATCH', `${TRADER}/host1`, { fields: { isTrader: { booleanValue: false } } })).toBe(403);
    expect(await rest('other', 'GET', `${TRADER_PUBLIC}/host1`)).toBe(200);
    expect(await rest(null, 'GET', `${TRADER_PUBLIC}/host1`)).toBe(403);
    expect(await rest('host1', 'PATCH', `${TRADER_PUBLIC}/host1`, { fields: { name: { stringValue: 'Fake' } } })).toBe(403);
    expect(await rest('host1', 'GET', `${NOTICE_RUNS}/terms_5.3.2`)).toBe(403);
    expect(await rest('boss', 'GET', `${NOTICE_RUNS}/terms_5.3.2`)).toBe(200);
  });
});

describe('requestHumanSupport', () => {
  const call = wrap(requestHumanSupport);
  beforeAll(async () => {
    await clearAll();
    await db.doc('support_chats/c1').set({ userId: 'owner', status: 'pending', priority: 'normal' });
  });

  test('owner only', async () => {
    await expectCode(call({ conversationId: 'c1' }), 'unauthenticated');
    await expectCode(call({ conversationId: 'c1' }, 'stranger'), 'permission-denied');
    await expectCode(call({ conversationId: 'nope' }, 'owner'), 'not-found');
    await expectCode(call({ conversationId: 'a/b' }, 'owner'), 'invalid-argument');
  });

  test('escalates at once and posts the handoff message once; priority untouched', async () => {
    expect(await call({ conversationId: 'c1' }, 'owner')).toEqual({ ok: true, already: false });
    const c = (await db.doc('support_chats/c1').get()).data()!;
    expect(c).toMatchObject({ status: 'open', escalatedFromAI: true, escalationReason: 'user_requested_human', priority: 'normal' });
    expect(await call({ conversationId: 'c1' }, 'owner')).toEqual({ ok: true, already: true });
    const msgs = await db.collection('support_messages').where('conversationId', '==', 'c1').get();
    expect(msgs.size).toBe(1);
    expect(msgs.docs[0].data().metadata).toEqual({ systemKey: 'srvSupportAiHandoff' });
  });
});

describe('recordConsent: promotional_use (Terms 15.3)', () => {
  test('accepted and withdrawn are recorded', async () => {
    await clearAll();
    const rc = wrap(recordConsent);
    await rc({ type: 'promotional_use', version: 1, accepted: true, locale: 'it', platform: 'web' }, 'u1');
    expect((await db.doc('consents/u1').get()).data()!.promotional_use).toMatchObject({ accepted: true });
    await rc({ type: 'promotional_use', version: 1, accepted: false, locale: 'it', platform: 'web' }, 'u1');
    expect((await db.doc('consents/u1').get()).data()!.promotional_use).toMatchObject({ accepted: false });
    expect((await db.collection('consents/u1/events').get()).size).toBe(2);
  });
});
