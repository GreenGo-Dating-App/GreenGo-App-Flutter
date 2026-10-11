/**
 * Copyright notice-and-takedown against the emulators (Firestore + Auth):
 *  - notice validation (§512(c)(3) elements), auth, rate limits
 *  - public web form: honeypot, email confirmation, per-IP limit
 *  - admin roles on every admin callable
 *  - accept: content disabled, strike, DSA decision record, uploader push +
 *    email (no complainant phone/address), complainant email; idempotent
 *  - reject, lawsuit, counter-notice (forwarded in full to the complainant)
 *  - restoration after 10 business days with a fake clock; strike removed
 *  - 3 active strikes -> account suspended with an appealable decision;
 *    strikes expire after 12 months
 *  - Firestore rules: own reads only, server-only writes and subcollections
 */
import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
import { emailDeps } from '../../src/emails/sendEmail';
import {
  submitCopyrightNotice, submitCopyrightCounterNotice, adminListCopyrightNotices, adminGetCopyrightNotice,
  adminDecideCopyrightNotice, adminMarkCopyrightLawsuit, adminGetCopyrightStrikes,
} from '../../src/copyright';
import { copyrightDeps, runCopyrightMaintenance } from '../../src/copyright/service';
import { handleCopyrightWeb } from '../../src/copyright/web';
import { addBusinessDays, normalizeSignature } from '../../src/copyright/model';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const PROJECT = process.env.GCLOUD_PROJECT!;
const DAY = 86_400_000;
const fetchMock = jest.fn(async (_url: any, _init?: any) => ({ ok: true, status: 200 }));
emailDeps.fetch = fetchMock as any;
const START = Date.UTC(2026, 9, 9, 12, 0); // Friday 2026-10-09
let NOW = START;
emailDeps.now = () => NOW;
copyrightDeps.now = () => NOW;
let tokenSeq = 0;
copyrightDeps.token = () => (++tokenSeq).toString(16).padStart(64, 'a');

async function clearAll() {
  const fsHost = process.env.FIRESTORE_EMULATOR_HOST!;
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
  for (const h of [fsHost, authHost]) {
    if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(h)) throw new Error('not an emulator');
  }
  const del = (host: string, path: string) => new Promise<void>((res, rej) => {
    const r = require('http').request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path,
      headers: { Authorization: 'Bearer owner' } }, (x: any) => { x.resume(); x.on('end', res); });
    r.on('error', rej); r.end();
  });
  await del(fsHost, `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  await del(authHost, `/emulator/v1/projects/${PROJECT}/accounts`);
}

const call = (fn: any, data: any, uid?: string, token: Record<string, unknown> = {}) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token } : undefined });
const asMod = (fn: any, data: any) => call(fn, data, 'mod1', { adminRole: 'moderator' });
const bodies = () => fetchMock.mock.calls.map((c) => JSON.parse((c[1] as any).body));
const sentTo = (addr: string) => bodies().filter((b) => b.to.includes(addr));

async function expectCode(p: Promise<unknown>, code: string, message?: RegExp) {
  await expect(p).rejects.toMatchObject({ code });
  if (message) await expect(p).rejects.toThrow(message);
}

const validNotice = (over: Record<string, any> = {}) => ({
  complainant: { name: 'Jane Rights', email: 'jane@studio.test', organization: 'Studio X', phone: '+1 555 0100', address: '1 Main St, Springfield', relationship: 'owner' },
  work: { description: 'My photograph "Sunset over the bay" (2025)', url: 'https://studio.test/sunset' },
  content: { location: 'groups/g1/messages/m1', details: 'The photo in the group chat', target: { type: 'message', path: 'groups/g1/messages/m1' } },
  statements: { goodFaith: true, accuracy: true, authority: true },
  signature: '/s/ Jane Rights',
  locale: 'en',
  ...over,
});

async function seedUploader(uid = 'up1', lang = 'it') {
  await admin.auth().createUser({ uid, email: `${uid}@example.com` }).catch(() => undefined);
  await db.doc(`users/${uid}`).set({ appLanguage: lang });
  await db.doc(`profiles/${uid}`).set({ displayName: uid, photoUrls: ['https://cdn.test/a.jpg', 'https://cdn.test/b.jpg'] });
}

async function seedMessage(id = 'm1') {
  await db.doc(`groups/g1/messages/${id}`).set({ senderId: 'up1', text: 'look at this', mediaUrl: 'https://cdn.test/sunset.jpg', type: 'image' });
}

/** Submits from the app as reporter rep1 and accepts as moderator. */
async function acceptedNotice(msgId = 'm1'): Promise<string> {
  await seedMessage(msgId);
  const r = await call(submitCopyrightNotice, validNotice({ content: { location: msgId, target: { type: 'message', path: `groups/g1/messages/${msgId}` } } }), 'rep1');
  await asMod(adminDecideCopyrightNotice, { noticeId: r.noticeId, decision: 'accept' });
  return r.noticeId;
}

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  NOW = START;
  delete process.env.RESEND_API_KEY;
  delete process.env.ADMIN_COPYRIGHT_EMAILS;
  await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'no-reply@greengo.test' });
  await seedUploader();
});
afterAll(() => fft.cleanup());

describe('pure helpers', () => {
  test('10 business days from a Friday lands on the Friday two weeks later; signature normalisation', () => {
    expect(new Date(addBusinessDays(START, 10)).toISOString().slice(0, 10)).toBe('2026-10-23');
    expect(new Date(addBusinessDays(Date.UTC(2026, 9, 10), 1)).toISOString().slice(0, 10)).toBe('2026-10-12'); // Sat -> Mon
    expect(normalizeSignature('/s/  JANE   Rights ')).toBe('jane rights');
  });
});

describe('submitCopyrightNotice (app)', () => {
  test('requires sign-in and every §512(c)(3) element', async () => {
    await expectCode(call(submitCopyrightNotice, validNotice()), 'unauthenticated');
    for (const st of ['goodFaith', 'accuracy', 'authority']) {
      await expectCode(call(submitCopyrightNotice, validNotice({ statements: { goodFaith: true, accuracy: true, authority: true, [st]: false } }), 'rep1'), 'invalid-argument', new RegExp(`invalid_${st}`));
    }
    await expectCode(call(submitCopyrightNotice, validNotice({ signature: 'Someone Else' }), 'rep1'), 'invalid-argument', /invalid_signature/);
    const bad = validNotice();
    bad.complainant.email = 'nope';
    await expectCode(call(submitCopyrightNotice, bad, 'rep1'), 'invalid-argument', /invalid_email/);
    const noPhone = validNotice();
    (noPhone.complainant as any).phone = '';
    await expectCode(call(submitCopyrightNotice, noPhone, 'rep1'), 'invalid-argument', /invalid_phone/);
    await expectCode(call(submitCopyrightNotice, validNotice({ work: { description: 'short' } }), 'rep1'), 'invalid-argument', /invalid_work/);
    await expectCode(call(submitCopyrightNotice, validNotice({ content: { location: 'x', target: { type: 'message', path: 'users/u1' } } }), 'rep1'), 'invalid-argument', /invalid_content_path/);
    expect((await db.collection('copyright_notices').get()).size).toBe(0);
  });

  test('valid -> pending, private contact split off, admin alert without personal data', async () => {
    const r = await call(submitCopyrightNotice, validNotice(), 'rep1');
    expect(r).toMatchObject({ status: 'pending', ref: expect.stringMatching(/^CN-/) });
    const n = (await db.doc(`copyright_notices/${r.noticeId}`).get()).data()!;
    expect(n).toMatchObject({ status: 'pending', source: 'app', submitterUid: 'rep1', uploaderVisible: false, targetUid: null });
    expect(JSON.stringify(n)).not.toMatch(/555 0100|Main St/);
    expect((await db.doc(`copyright_notices/${r.noticeId}/private/contact`).get()).data()).toMatchObject({ phone: '+1 555 0100', address: '1 Main St, Springfield' });
    const alert = sentTo('greengochat.com@gmail.com');
    expect(alert).toHaveLength(1);
    expect(alert[0].subject).toBe(`New copyright notice ${r.ref}`);
    expect(JSON.stringify(alert[0])).not.toMatch(/Jane|jane@|Studio|Sunset|555 0100|Main St/);
    expect(alert[0].html).toContain(`/copyright?notice=${r.noticeId}`);
  });

  test('rate limit: 10 per user per day', async () => {
    for (let i = 0; i < 10; i++) await call(submitCopyrightNotice, validNotice(), 'rep1');
    await expectCode(call(submitCopyrightNotice, validNotice(), 'rep1'), 'resource-exhausted');
    NOW += DAY + 1;
    await expect(call(submitCopyrightNotice, validNotice(), 'rep1')).resolves.toMatchObject({ status: 'pending' });
  });
});

describe('public web form', () => {
  function res() {
    const out: any = { code: 0, headers: {} as Record<string, string>, body: '' };
    out.status = (c: number) => { out.code = c; return out; };
    out.set = (k: string, v: string) => { out.headers[k] = v; return out; };
    out.send = (b: string) => { out.body = b; };
    out.json = (b: unknown) => { out.body = b; };
    return out;
  }
  const form = (over: Record<string, string> = {}) => ({
    name: 'Jane Rights', email: 'jane@studio.test', phone: '+1 555 0100', address: '1 Main St, Springfield', relationship: 'agent',
    work: 'My photograph Sunset over the bay', location: 'https://greengo-chat.web.app/e/ev9', goodFaith: 'on', accuracy: 'on', authority: 'on',
    signature: 'Jane Rights', lang: 'de', ...over,
  });
  const post = async (body: any, ip = '203.0.113.7') => {
    const r = res();
    await handleCopyrightWeb({ method: 'POST', path: '/', body, query: {}, headers: { 'x-forwarded-for': ip, 'content-type': 'application/x-www-form-urlencoded' } }, r);
    return r;
  };

  test('GET renders the localized form with every sworn statement and security headers', async () => {
    const r = res();
    await handleCopyrightWeb({ method: 'GET', path: '/', query: { lang: 'fr' }, headers: {} }, r);
    expect(r.code).toBe(200);
    expect(r.body).toContain('Signaler une violation du droit d’auteur');
    for (const n of ['goodFaith', 'accuracy', 'authority', 'signature', 'website']) expect(r.body).toContain(`name="${n}"`);
    expect(r.headers['Content-Security-Policy']).toContain("frame-ancestors 'none'");
  });

  test('submit -> unverified + confirmation email; confirm -> pending + admin alert; link single-use', async () => {
    const r = await post(form());
    expect(r.code).toBe(200);
    const notices = await db.collection('copyright_notices').get();
    expect(notices.size).toBe(1);
    const n = notices.docs[0];
    expect(n.data()).toMatchObject({ status: 'unverified', source: 'web', submitterUid: null, locale: 'de', content: { target: { type: 'event', path: 'events/ev9' } } });
    expect(sentTo('greengochat.com@gmail.com')).toHaveLength(0);
    const confirm = sentTo('jane@studio.test');
    expect(confirm).toHaveLength(1);
    expect(confirm[0].subject).toBe('Bestätige deine Urheberrechtsmeldung');
    const link = /https:\/\/[^"<\s]+\/confirm\?id=[^"<\s]+/.exec(confirm[0].text)![0];
    const u = new URL(link);
    const priv = (await db.doc(`copyright_notices/${n.id}/private/contact`).get()).data()!;
    expect(priv.confirmTokenHash).not.toBe(u.searchParams.get('token'));
    expect(priv.ipHash).toMatch(/^[a-f0-9]{32}$/);
    expect(JSON.stringify(priv)).not.toContain('203.0.113.7');

    const bad = res();
    await handleCopyrightWeb({ method: 'GET', path: '/copyright-notice/confirm', query: { id: n.id, token: 'b'.repeat(64) }, headers: {} }, bad);
    expect(bad.code).toBe(400);
    const ok = res();
    await handleCopyrightWeb({ method: 'GET', path: '/copyright-notice/confirm', query: { id: n.id, token: u.searchParams.get('token') }, headers: {} }, ok);
    expect(ok.code).toBe(200);
    expect((await n.ref.get()).data()).toMatchObject({ status: 'pending' });
    expect(sentTo('greengochat.com@gmail.com')).toHaveLength(1);
    const again = res();
    await handleCopyrightWeb({ method: 'GET', path: '/confirm', query: { id: n.id, token: u.searchParams.get('token') }, headers: {} }, again);
    expect(again.code).toBe(200);
    expect(sentTo('greengochat.com@gmail.com')).toHaveLength(1);
  });

  test('expired confirmation link is refused; unconfirmed notices are purged with their private data', async () => {
    await post(form());
    const n = (await db.collection('copyright_notices').get()).docs[0];
    const token = new URL(/https:\/\/[^"<\s]+/.exec(bodies()[0].text)![0]).searchParams.get('token');
    NOW += 49 * 3_600_000;
    const r = res();
    await handleCopyrightWeb({ method: 'GET', path: '/confirm', query: { id: n.id, token }, headers: {} }, r);
    expect(r.code).toBe(400);
    NOW = START + 8 * DAY;
    expect((await runCopyrightMaintenance()).purged).toBe(1);
    expect((await n.ref.get()).exists).toBe(false);
    expect((await db.doc(`copyright_notices/${n.id}/private/contact`).get()).exists).toBe(false);
  });

  test('honeypot stores nothing; invalid input is a 400; 6th post from one IP within an hour is 429', async () => {
    expect((await post(form({ website: 'http://spam.test' }))).code).toBe(200);
    expect((await post(form({ authority: '' }))).code).toBe(400);
    expect((await db.collection('copyright_notices').get()).size).toBe(0);
    for (let i = 0; i < 5; i++) expect((await post(form({ email: `j${i}@studio.test` }))).code).toBe(200);
    expect((await post(form({ email: 'j9@studio.test' }))).code).toBe(429);
    expect((await post(form({ email: 'j9@studio.test' }), '198.51.100.1')).code).toBe(200);
  });
});

describe('admin roles', () => {
  test('every admin callable refuses users and support admins', async () => {
    const r = await call(submitCopyrightNotice, validNotice(), 'rep1');
    const calls: Array<[any, any]> = [
      [adminListCopyrightNotices, {}],
      [adminGetCopyrightNotice, { noticeId: r.noticeId }],
      [adminDecideCopyrightNotice, { noticeId: r.noticeId, decision: 'accept' }],
      [adminMarkCopyrightLawsuit, { noticeId: r.noticeId, note: 'filed in court' }],
      [adminGetCopyrightStrikes, { userId: 'up1' }],
    ];
    for (const [fn, data] of calls) {
      await expectCode(call(fn, data), 'unauthenticated');
      await expectCode(call(fn, data, 'rep1'), 'permission-denied');
      await expectCode(call(fn, data, 'sup1', { adminRole: 'support' }), 'permission-denied');
    }
    expect((await db.doc(`copyright_notices/${r.noticeId}`).get()).data()!.status).toBe('pending');
    const list = await asMod(adminListCopyrightNotices, { status: 'pending' });
    expect(list.items.map((i: any) => i.noticeId)).toEqual([r.noticeId]);
    const detail = await asMod(adminGetCopyrightNotice, { noticeId: r.noticeId });
    expect(detail.contact).toEqual({ phone: '+1 555 0100', address: '1 Main St, Springfield' });
    expect(detail.audit.map((a: any) => a.action)).toEqual(['submitted']);
  });
});

describe('accept / reject', () => {
  test('accept disables the message, records strike + decision, notifies both sides; idempotent', async () => {
    await seedMessage();
    const { noticeId } = await call(submitCopyrightNotice, validNotice(), 'rep1');
    fetchMock.mockClear();
    const r = await asMod(adminDecideCopyrightNotice, { noticeId, decision: 'accept', reason: 'Matches the registered work' });
    expect(r).toMatchObject({ status: 'accepted', targetUid: 'up1', activeStrikes: 1, terminated: false });

    const msg = (await db.doc('groups/g1/messages/m1').get()).data()!;
    expect(msg).toMatchObject({ isDeletedForEveryone: true, mediaUrl: null, copyrightHold: { noticeId } });
    expect(msg.text).not.toBe('look at this');
    expect(JSON.stringify(msg)).not.toContain('sunset.jpg');

    const n = (await db.doc(`copyright_notices/${noticeId}`).get()).data()!;
    expect(n).toMatchObject({ status: 'accepted', uploaderVisible: true, targetUid: 'up1', decisionId: `copyright_${noticeId}` });
    expect(n.removal.backup).toMatchObject({ text: 'look at this', mediaUrl: 'https://cdn.test/sunset.jpg' });
    expect((await db.doc(`copyright_strikes/${noticeId}`).get()).data()).toMatchObject({ userId: 'up1', status: 'active' });
    expect((await db.doc(`moderation_decisions/copyright_${noticeId}`).get()).data()).toMatchObject({ userId: 'up1', action: 'removeContent', reasonCode: 'copyright', appealable: true });
    expect((await db.doc(`notifications/copyright_removed_${noticeId}`).get()).data()).toMatchObject({ userId: 'up1', titleKey: 'srvCopyrightRemovedTitle', data: { action: 'copyright_notice', noticeId } });

    const up = sentTo('up1@example.com');
    expect(up).toHaveLength(1);
    expect(up[0].subject).toBe('Segnalazione di copyright: contenuto rimosso');
    expect(up[0].reply_to).toBe('copyright@greengochat.com');
    expect(up[0].html).toContain('Jane Rights');
    expect(up[0].html).toContain('jane@studio.test');
    expect(up[0].html).not.toMatch(/555 0100|Main St/);
    expect(sentTo('jane@studio.test').map((b) => b.subject)).toEqual(['Your copyright notice was accepted']);

    await expectCode(asMod(adminDecideCopyrightNotice, { noticeId, decision: 'accept' }), 'failed-precondition', /notice_is_accepted/);
    await expectCode(asMod(adminDecideCopyrightNotice, { noticeId, decision: 'reject', reason: 'changed my mind' }), 'failed-precondition');
    expect((await db.collection('copyright_strikes').get()).size).toBe(1);
    expect(sentTo('up1@example.com')).toHaveLength(1);
    const audit = (await asMod(adminGetCopyrightNotice, { noticeId })).audit.map((a: any) => a.action).sort();
    expect(audit).toEqual(['accepted', 'submitted']);
    expect((await db.collection('admin_audit_log').where('targetId', '==', noticeId).get()).size).toBe(1);
  });

  test('accept needs a resolvable target; the admin can set one (event)', async () => {
    const { noticeId } = await call(submitCopyrightNotice, validNotice({ content: { location: 'somewhere in the app', details: 'a poster' } }), 'rep1');
    await expectCode(asMod(adminDecideCopyrightNotice, { noticeId, decision: 'accept' }), 'failed-precondition', /target_required/);
    expect((await db.doc(`copyright_notices/${noticeId}`).get()).data()!.status).toBe('pending');
    await expectCode(asMod(adminDecideCopyrightNotice, { noticeId, decision: 'accept', target: { type: 'event', path: 'events/missing' } }), 'not-found');
    await db.doc('events/ev1').set({ organizerId: 'up1', status: 'published', title: 'Party' });
    await asMod(adminDecideCopyrightNotice, { noticeId, decision: 'accept', target: { type: 'event', path: 'events/ev1' } });
    expect((await db.doc('events/ev1').get()).data()).toMatchObject({ status: 'cancelled', copyrightHold: { noticeId } });
  });

  test('reject needs a reason and emails the complainant in their language', async () => {
    const { noticeId } = await call(submitCopyrightNotice, validNotice({ locale: 'pt_BR' }), 'rep1');
    await expectCode(asMod(adminDecideCopyrightNotice, { noticeId, decision: 'reject' }), 'invalid-argument');
    await asMod(adminDecideCopyrightNotice, { noticeId, decision: 'reject', reason: 'Fair use: commentary' });
    expect((await db.doc(`copyright_notices/${noticeId}`).get()).data()).toMatchObject({ status: 'rejected', uploaderVisible: false });
    const mail = sentTo('jane@studio.test');
    expect(mail[0].subject).toBe('Não foi possível processar sua notificação de direitos autorais');
    expect(mail[0].html).toContain('Fair use: commentary');
  });
});

describe('counter-notice and restoration', () => {
  const counter = (noticeId: string, over: Record<string, any> = {}) => ({
    noticeId, name: 'Up Loader', email: 'up1@example.com', phone: '+39 06 1234', address: 'Via Roma 1, Roma', explanation: 'I took this photo myself.',
    statements: { perjury: true, jurisdiction: true }, signature: 'Up Loader', ...over,
  });

  test('only the uploader, once; forwarded in full; restored after 10 business days; strike removed', async () => {
    const noticeId = await acceptedNotice();
    fetchMock.mockClear();
    await expectCode(call(submitCopyrightCounterNotice, counter(noticeId), 'someoneElse'), 'permission-denied');
    await expectCode(call(submitCopyrightCounterNotice, counter(noticeId, { statements: { perjury: true } }), 'up1'), 'invalid-argument', /invalid_jurisdiction/);
    const r = await call(submitCopyrightCounterNotice, counter(noticeId), 'up1');
    expect(new Date(r.restoreAfter).toISOString().slice(0, 10)).toBe('2026-10-23');
    await expectCode(call(submitCopyrightCounterNotice, counter(noticeId), 'up1'), 'already-exists');

    const fwd = sentTo('jane@studio.test');
    expect(fwd).toHaveLength(1);
    expect(fwd[0].subject).toBe('Counter-notice received');
    for (const s of ['Via Roma 1, Roma', '+39 06 1234', 'up1@example.com', 'I took this photo myself.', '23 October 2026']) {
      expect(fwd[0].html).toContain(s);
    }
    expect(sentTo('greengochat.com@gmail.com').map((b) => b.subject)).toEqual([expect.stringMatching(/^Copyright counter-notice received CN-/)]);

    NOW = Date.UTC(2026, 9, 22, 23, 0);
    expect((await runCopyrightMaintenance()).restored).toBe(0);
    expect((await db.doc('groups/g1/messages/m1').get()).data()!.isDeletedForEveryone).toBe(true);

    NOW = Date.UTC(2026, 9, 23, 13, 0);
    expect((await runCopyrightMaintenance()).restored).toBe(1);
    const msg = (await db.doc('groups/g1/messages/m1').get()).data()!;
    expect(msg).toEqual({ senderId: 'up1', text: 'look at this', mediaUrl: 'https://cdn.test/sunset.jpg', type: 'image' });
    expect((await db.doc(`copyright_notices/${noticeId}`).get()).data()).toMatchObject({ status: 'restored' });
    expect((await db.doc(`copyright_strikes/${noticeId}`).get()).data()).toMatchObject({ status: 'removed', removedReason: 'counter_notice_restored' });
    expect((await db.doc(`notifications/copyright_restored_${noticeId}`).get()).exists).toBe(true);
    expect(sentTo('jane@studio.test').map((b) => b.subject)).toContain('Material restored');
    expect((await runCopyrightMaintenance()).restored).toBe(0);
    expect((await asMod(adminGetCopyrightStrikes, { userId: 'up1' })).active).toBe(0);
  });

  test('lawsuit filed: the material stays down', async () => {
    const noticeId = await acceptedNotice();
    await expectCode(asMod(adminMarkCopyrightLawsuit, { noticeId, note: 'Case 1:26-cv-001' }), 'failed-precondition');
    await call(submitCopyrightCounterNotice, counter(noticeId), 'up1');
    await asMod(adminMarkCopyrightLawsuit, { noticeId, note: 'Case 1:26-cv-001' });
    NOW = START + 30 * DAY;
    expect((await runCopyrightMaintenance()).restored).toBe(0);
    expect((await db.doc(`copyright_notices/${noticeId}`).get()).data()).toMatchObject({ status: 'lawsuit_filed', lawsuitNote: 'Case 1:26-cv-001' });
    expect((await db.doc('groups/g1/messages/m1').get()).data()!.isDeletedForEveryone).toBe(true);
    expect((await db.doc(`copyright_counter_notices/${noticeId}`).get()).data()).toMatchObject({ status: 'lawsuit' });
  });

  test('profile photo and experience are restored to their previous state', async () => {
    await db.doc('user_experiences/x1').set({ hostId: 'up1', status: 'published', title: 'Tour' });
    const a = await call(submitCopyrightNotice, validNotice({ content: { location: 'x1', target: { type: 'experience', path: 'user_experiences/x1' } } }), 'rep1');
    const b = await call(submitCopyrightNotice, validNotice({ content: { location: 'photo', target: { type: 'profilePhoto', path: 'profiles/up1', photoUrl: 'https://cdn.test/b.jpg' } } }), 'rep1');
    await asMod(adminDecideCopyrightNotice, { noticeId: a.noticeId, decision: 'accept' });
    await asMod(adminDecideCopyrightNotice, { noticeId: b.noticeId, decision: 'accept' });
    expect((await db.doc('user_experiences/x1').get()).data()!.status).toBe('hidden');
    expect((await db.doc('profiles/up1').get()).data()!.photoUrls).toEqual(['https://cdn.test/a.jpg']);
    await call(submitCopyrightCounterNotice, counter(a.noticeId), 'up1');
    await call(submitCopyrightCounterNotice, counter(b.noticeId), 'up1');
    NOW = START + 20 * DAY;
    expect((await runCopyrightMaintenance()).restored).toBe(2);
    expect((await db.doc('user_experiences/x1').get()).data()).toEqual({ hostId: 'up1', status: 'published', title: 'Tour' });
    expect((await db.doc('profiles/up1').get()).data()!.photoUrls).toEqual(['https://cdn.test/a.jpg', 'https://cdn.test/b.jpg']);
  });
});

describe('repeat infringers', () => {
  test('3 active strikes in 12 months -> suspended with an appealable decision; expired strikes do not count', async () => {
    await acceptedNotice('m1');
    NOW += 100 * DAY;
    await acceptedNotice('m2');
    expect((await db.doc('users/up1').get()).data()!.accountStatus).toBeUndefined();
    // 13 months after the first strike: only 2 active -> no termination.
    NOW = START + 395 * DAY;
    const third = await acceptedNotice('m3');
    expect((await db.doc(`copyright_notices/${third}`).get()).data()!.strike.activeCount).toBe(2);
    expect((await db.doc('users/up1').get()).data()!.accountStatus).toBeUndefined();
    expect((await runCopyrightMaintenance()).expired).toBe(1);

    const fourth = await acceptedNotice('m4');
    const user = (await db.doc('users/up1').get()).data()!;
    expect(user).toMatchObject({ accountStatus: 'suspended', suspensionReason: 'copyright_repeat_infringer', suspendedUntil: null });
    expect((await db.doc('profiles/up1').get()).data()).toMatchObject({ status: 'suspended' });
    const decision = (await db.doc(`moderation_decisions/copyright_term_${fourth}`).get()).data()!;
    expect(decision).toMatchObject({ userId: 'up1', action: 'suspendUser', reasonCode: 'copyright', appealable: true });
    expect((await db.doc(`notifications/moderation_decision_copyright_term_${fourth}`).get()).exists).toBe(true);
    const strikes = await asMod(adminGetCopyrightStrikes, { userId: 'up1' });
    expect(strikes.active).toBe(3);
    expect(strikes.strikes).toHaveLength(4);
  });
});

// ───────────────────────────────────────────────────────────── rules (REST, emulator mock tokens)

function idToken(uid: string): string {
  const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const iat = Math.floor(Date.now() / 1000);
  return `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: iat, user_id: uid, sub: uid, iat, exp: iat + 3600,
    firebase: { sign_in_provider: 'password', identities: {} },
  })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
const getAs = async (uid: string, path: string) => (await fetch(`${base()}/${path}`, { headers: { Authorization: `Bearer ${idToken(uid)}` } })).status;
const listAs = async (uid: string, collectionId: string, filters: Array<[string, unknown]>) => {
  const value = (v: unknown) => (typeof v === 'boolean' ? { booleanValue: v } : { stringValue: v });
  const res = await fetch(`${base()}:runQuery`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId }], where: { compositeFilter: { op: 'AND', filters: filters.map(([f, v]) => ({ fieldFilter: { field: { fieldPath: f }, op: 'EQUAL', value: value(v) } })) } } } }),
  });
  return res.status;
};
const writeAs = async (uid: string, path: string) => (await fetch(`${base()}/${path}`, {
  method: 'PATCH', headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ fields: { status: { stringValue: 'restored' } } }),
})).status;

describe('firestore rules', () => {
  test('own reads only; server-only writes and subcollections', async () => {
    const accepted = await acceptedNotice();
    const pending = (await call(submitCopyrightNotice, validNotice(), 'rep1')).noticeId;
    await call(submitCopyrightCounterNotice, {
      noticeId: accepted, name: 'Up Loader', email: 'up1@example.com', phone: '+39 06 1234', address: 'Via Roma 1', explanation: 'My own photo, really.',
      statements: { perjury: true, jurisdiction: true }, signature: 'Up Loader',
    }, 'up1');

    expect(await getAs('up1', `copyright_notices/${accepted}`)).toBe(200);
    expect(await getAs('rep1', `copyright_notices/${accepted}`)).toBe(200); // submitter
    expect(await getAs('stranger', `copyright_notices/${accepted}`)).toBe(403);
    await db.doc(`copyright_notices/${pending}`).update({ targetUid: 'up1' });
    expect(await getAs('up1', `copyright_notices/${pending}`)).toBe(403); // not acted on yet
    expect(await listAs('up1', 'copyright_notices', [['targetUid', 'up1'], ['uploaderVisible', true]])).toBe(200);
    expect(await listAs('up1', 'copyright_notices', [['targetUid', 'up1']])).toBe(403);
    expect(await listAs('stranger', 'copyright_notices', [['targetUid', 'up1'], ['uploaderVisible', true]])).toBe(403);

    expect(await getAs('up1', `copyright_notices/${accepted}/private/contact`)).toBe(403);
    expect(await getAs('rep1', `copyright_notices/${accepted}/private/contact`)).toBe(403);
    const auditId = (await db.collection(`copyright_notices/${accepted}/audit`).limit(1).get()).docs[0].id;
    expect(await getAs('up1', `copyright_notices/${accepted}/audit/${auditId}`)).toBe(403);

    expect(await getAs('up1', `copyright_counter_notices/${accepted}`)).toBe(200);
    expect(await getAs('rep1', `copyright_counter_notices/${accepted}`)).toBe(403);
    expect(await getAs('up1', `copyright_strikes/${accepted}`)).toBe(200);
    expect(await getAs('stranger', `copyright_strikes/${accepted}`)).toBe(403);
    expect(await listAs('up1', 'copyright_strikes', [['userId', 'up1']])).toBe(200);

    for (const p of [`copyright_notices/${accepted}`, `copyright_counter_notices/${accepted}`, `copyright_strikes/${accepted}`, 'copyright_rate_limits/x', 'copyright_notices/new1']) {
      expect(await writeAs('up1', p)).toBe(403);
    }
  });
});
