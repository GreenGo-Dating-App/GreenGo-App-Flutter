/**
 * Invite links: ensureReferralCode (every user gets a code, server-side) and
 * the /r/{CODE} preview route of sharePreview (inviter's public name only).
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js referral-link"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();

const ensureMod = () => require('../../src/referral/ensureReferralCode');
const shareMod = () => require('../../src/share/sharePreview');

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const ensure = (uid?: string) =>
  (fft.wrap(ensureMod().ensureReferralCode) as any)({ data: {}, auth: uid ? { uid, token: {} } : undefined });

/** Minimal express-like req/res for the onRequest handler. */
async function get(path: string, acceptLanguage = 'en') {
  const out: { status: number; headers: Record<string, string>; body: string; redirect?: string } = {
    status: 200, headers: {}, body: '',
  };
  const res: any = {
    status(c: number) { out.status = c; return res; },
    set(k: string, v: string) { out.headers[k.toLowerCase()] = v; return res; },
    type() { return res; },
    send(b: any) { out.body = String(b); return res; },
    redirect(c: number, u: string) { out.status = c; out.redirect = u; return res; },
    on() { return res; }, once() { return res; }, emit() { return true; },
  };
  const req: any = {
    method: 'GET', path, url: path, headers: { 'accept-language': acceptLanguage },
    get: (h: string) => (h.toLowerCase() === 'accept-language' ? acceptLanguage : undefined),
  };
  await shareMod().sharePreview(req, res);
  return out;
}

beforeEach(clearAll);
afterAll(() => fft.cleanup());

describe('ensureReferralCode', () => {
  test('creates a code once and returns the same code afterwards', async () => {
    const a = await ensure('u1');
    expect(a.code).toMatch(/^[A-Z2-9]{6}$/);
    expect((await db.doc(`referral_codes/${a.code}`).get()).data()).toMatchObject({ ownerId: 'u1' });
    expect((await db.doc('referrals/u1').get()).data()).toMatchObject({ code: a.code, invitedCount: 0, coinsEarned: 0 });
    expect((await ensure('u1')).code).toBe(a.code);
    expect((await db.collection('referral_codes').get()).size).toBe(1);
  });

  test('keeps an existing client-created code', async () => {
    await db.doc('referral_codes/OLD234').set({ ownerId: 'u2' });
    await db.doc('referrals/u2').set({ code: 'OLD234', invitedCount: 3, coinsEarned: 150 });
    expect((await ensure('u2')).code).toBe('OLD234');
  });

  test('does not keep a code whose owner is someone else; never touches counters', async () => {
    await db.doc('referral_codes/BAD234').set({ ownerId: 'victim' });
    await db.doc('referrals/u3').set({ code: 'BAD234', invitedCount: 2, coinsEarned: 100 });
    const r = await ensure('u3');
    expect(r.code).not.toBe('BAD234');
    expect((await db.doc('referrals/u3').get()).data()).toMatchObject({ code: r.code, invitedCount: 2, coinsEarned: 100 });
    expect((await db.doc('referral_codes/BAD234').get()).data()?.ownerId).toBe('victim');
  });

  test('concurrent calls end with one code', async () => {
    const rs = await Promise.all([ensure('u4'), ensure('u4'), ensure('u4')]);
    const final = (await db.doc('referrals/u4').get()).data()?.code;
    expect(rs.every((r: any) => r.code === final)).toBe(true);
  });

  test('ATTACK: unauthenticated is refused', async () => {
    await expect(ensure()).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});

describe('sharePreview /r/{CODE}', () => {
  beforeEach(async () => {
    await db.doc('referral_codes/ABC234').set({ ownerId: 'inviter1' });
    await db.doc('profiles/inviter1').set({
      displayName: 'Ana Souza', accountStatus: 'active', bio: 'call me +55 11 99999-9999',
      email: 'ana@example.com', photoUrls: ['https://firebasestorage.googleapis.com/a.jpg'],
      location: { city: 'Lisbon' },
    });
  });

  test('names the inviter (public display name only), localized, cacheable per language', async () => {
    const r = await get('/r/abc234', 'it-IT,it;q=0.9');
    expect(r.status).toBe(200);
    expect(r.body).toContain('<meta property="og:title" content="Ana Souza ti ha invitato su GreenGo" />');
    expect(r.body).toContain('1 settimana di iscrizione Base');
    for (const secret of ['99999', 'ana@example.com', 'Lisbon', 'a.jpg', 'inviter1']) {
      expect(r.body).not.toContain(secret);
    }
    expect(r.headers['vary']).toBe('Accept-Language');
    expect(r.headers['cache-control']).toContain('s-maxage');
  });

  test('a hidden inviter or unknown code gets the generic card', async () => {
    await db.doc('profiles/inviter1').update({ isIncognito: true });
    const hidden = await get('/r/ABC234');
    expect(hidden.body).toContain('content="You&#39;re invited to GreenGo"');
    expect(hidden.body).not.toContain('Ana');
    const unknown = await get('/r/ZZZ999');
    expect(unknown.body).toContain('content="You&#39;re invited to GreenGo"');
  });

  test('malformed codes redirect home; other routes untouched', async () => {
    const bad = await get('/r/x');
    expect(bad.status).toBe(302);
    const other = await get('/nothing/here');
    expect(other.status).toBe(302);
  });
});
