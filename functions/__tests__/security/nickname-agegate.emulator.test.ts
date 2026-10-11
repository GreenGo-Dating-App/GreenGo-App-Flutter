/**
 * INC-2026-001 residual fixes, against the Firestore + Auth emulators:
 *
 *  1. signInWithNickname: nickname + password -> custom token, verified by
 *     the Identity Toolkit (Auth emulator). Wrong password and unknown
 *     nickname answer identically (no enumeration); per-nickname lockout and
 *     per-IP limit; MFA accounts are refused with MFA_REQUIRED; disabled
 *     accounts with USER_DISABLED.
 *  2. nicknames/{nick} holds no email: the rules reject a client write that
 *     carries one (or any non allow-listed key), and the strip script
 *     removes it from legacy docs.
 *  3. Server age gate on profiles_private/{uid}.dateOfBirth (the public
 *     profile no longer carries it), and the public `age` computed from it.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  handleSignInWithNickname, NICKNAME_FAIL_LIMIT, IP_ATTEMPT_LIMIT, INVALID_CREDENTIALS,
} from '../../src/auth/nicknameSignIn';
import { applyPrivateProfileAgeGate, applyProfileAgeGate, AGE_GATE, AGE_BLOCKED_STATUS } from '../../src/auth/ageGate';
import { handlePrivateProfileWrite, handlePublicProfileWrite } from '../../src/profiles/privateProfile';
import { stripNicknameDoc } from '../../scripts/strip-nickname-emails';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

function emulatorHost(env: string): string {
  const h = process.env[env]!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(h)) throw new Error(`Refusing: ${env} is not a local emulator`);
  return h;
}

async function httpDelete(host: string, path: string) {
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}
async function clearAll() {
  await httpDelete(emulatorHost('FIRESTORE_EMULATOR_HOST'), `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  await httpDelete(emulatorHost('FIREBASE_AUTH_EMULATOR_HOST'), `/emulator/v1/projects/${PROJECT}/accounts`);
}

// ---- Firestore REST as a real client (rules apply) -------------------------
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const fsBase = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
function enc(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  return { stringValue: String(v) };
}
/** Client `set(data)` (full overwrite). */
async function clientSet(uid: string | null, path: string, data: Record<string, any>): Promise<number> {
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, enc(v)]));
  const res = await fetch(`${fsBase()}/${path}`, {
    method: 'PATCH',
    headers: { ...(uid ? { Authorization: `Bearer ${idToken(uid)}` } : {}), 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  await res.text();
  return res.status;
}
async function clientGet(uid: string | null, path: string): Promise<{ status: number; body: any }> {
  const res = await fetch(`${fsBase()}/${path}`, { headers: uid ? { Authorization: `Bearer ${idToken(uid)}` } : {} });
  return { status: res.status, body: await res.json().catch(() => null) };
}

// ---- callable invocation ----------------------------------------------------
function req(data: any, ip = '203.0.113.7') {
  return { data, rawRequest: { ip, headers: {} } } as any;
}
async function call(data: any, ip?: string): Promise<{ token?: string; err?: { code: string; message: string; reason?: string } }> {
  try {
    return await handleSignInWithNickname(req(data, ip));
  } catch (e: any) {
    if (!(e instanceof HttpsError)) throw e;
    return { err: { code: e.code, message: e.message, reason: (e.details as any)?.code } };
  }
}
/** Exchanges a custom token at the Auth emulator; returns the localId. */
async function exchangeCustomToken(token: string): Promise<string> {
  const host = emulatorHost('FIREBASE_AUTH_EMULATOR_HOST');
  const res = await fetch(`http://${host}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token, returnSecureToken: true }),
  });
  const body: any = await res.json();
  if (!res.ok) throw new Error(`custom token rejected: ${JSON.stringify(body)}`);
  const claims = JSON.parse(Buffer.from(String(body.idToken).split('.')[1], 'base64url').toString());
  return claims.user_id;
}

const PW = 'correct-horse-battery';

async function makeUser(uid: string, nick: string, opts: { legacyEmailDoc?: boolean; mapping?: boolean } = {}) {
  await admin.auth().createUser({ uid, email: `${uid}@example.com`, password: PW });
  await db.doc(`profiles/${uid}`).set({ userId: uid, nickname: nick, accountStatus: 'active' });
  if (opts.mapping !== false) {
    await db.doc(`nicknames/${nick}`).set(opts.legacyEmailDoc
      ? { email: `${uid}@example.com`, uid }
      : { uid, nickname: nick, createdAt: admin.firestore.Timestamp.now() });
  }
}

beforeAll(() => {
  process.env.NICKNAME_SIGNIN_MIN_RESPONSE_MS = '0';
});
beforeEach(async () => {
  await clearAll();
});

describe('signInWithNickname', () => {
  test('right password -> a custom token for that uid (legacy doc, mapping-less profile, @/case)', async () => {
    await makeUser('u_ann', 'ann', { legacyEmailDoc: true });
    await makeUser('u_ben', 'ben', { mapping: false }); // only profiles.nickname

    const a = await call({ nickname: '@Ann', password: PW });
    expect(a.err).toBeUndefined();
    expect(await exchangeCustomToken(a.token!)).toBe('u_ann');

    const b = await call({ nickname: 'ben', password: PW });
    expect(b.err).toBeUndefined();
    expect(await exchangeCustomToken(b.token!)).toBe('u_ben');
  });

  test('wrong password and unknown nickname are indistinguishable', async () => {
    await makeUser('u_ann', 'ann');
    const wrong = await call({ nickname: 'ann', password: 'nope' });
    const unknown = await call({ nickname: 'nobody_here', password: 'nope' });
    const empty = await call({ nickname: 'ann', password: '' });
    const emailish = await call({ nickname: 'ann@example.com', password: PW });
    for (const r of [wrong, unknown, empty, emailish]) {
      expect(r.token).toBeUndefined();
      expect(r.err).toEqual({ code: 'unauthenticated', message: INVALID_CREDENTIALS, reason: 'INVALID_CREDENTIALS' });
    }
    // The answer never contains the email.
    expect(JSON.stringify([wrong, unknown])).not.toContain('example.com');
  });

  test('per-nickname lockout after repeated failures (same for unknown nicknames)', async () => {
    await makeUser('u_ann', 'ann');
    for (let i = 0; i < NICKNAME_FAIL_LIMIT; i++) {
      expect((await call({ nickname: 'ann', password: `bad${i}` }, `198.51.100.${i}`)).err?.code).toBe('unauthenticated');
      expect((await call({ nickname: 'ghost', password: `bad${i}` }, `198.51.100.${i}`)).err?.code).toBe('unauthenticated');
    }
    // Even the right password is refused while locked; unknown nickname looks the same.
    const locked = await call({ nickname: 'ann', password: PW }, '198.51.100.99');
    const lockedGhost = await call({ nickname: 'ghost', password: PW }, '198.51.100.99');
    expect(locked.err?.code).toBe('resource-exhausted');
    expect(lockedGhost.err).toEqual(locked.err);
    // Other nicknames are unaffected.
    await makeUser('u_cat', 'cat');
    expect((await call({ nickname: 'cat', password: PW }, '198.51.100.99')).token).toBeTruthy();
    // Limit docs hold no raw nickname / IP.
    const lim = await db.collection('nickname_signin_limits').get();
    expect(JSON.stringify(lim.docs.map((d) => [d.id, d.data()]))).not.toMatch(/ann|ghost|198\.51/);
  });

  test('a success resets the nickname failure counter', async () => {
    await makeUser('u_ann', 'ann');
    for (let i = 0; i < NICKNAME_FAIL_LIMIT - 1; i++) await call({ nickname: 'ann', password: 'bad' }, `192.0.2.${i}`);
    expect((await call({ nickname: 'ann', password: PW }, '192.0.2.50')).token).toBeTruthy();
    for (let i = 0; i < NICKNAME_FAIL_LIMIT - 1; i++) await call({ nickname: 'ann', password: 'bad' }, `192.0.2.${60 + i}`);
    expect((await call({ nickname: 'ann', password: PW }, '192.0.2.99')).token).toBeTruthy();
  });

  test('per-IP limit across nicknames', async () => {
    await makeUser('u_ann', 'ann');
    for (let i = 0; i < IP_ATTEMPT_LIMIT; i++) await call({ nickname: `spray${i}`, password: 'x' }, '203.0.113.200');
    const r = await call({ nickname: 'ann', password: PW }, '203.0.113.200');
    expect(r.err?.code).toBe('resource-exhausted');
    expect((await call({ nickname: 'ann', password: PW }, '203.0.113.201')).token).toBeTruthy();
  });

  test('MFA accounts are not signed in (only after the password is verified)', async () => {
    await makeUser('u_mfa', 'mfa');
    await admin.auth().updateUser('u_mfa', {
      emailVerified: true,
      multiFactor: { enrolledFactors: [{ uid: 'enr1', factorId: 'phone', phoneNumber: '+15555550100', displayName: 'phone' }] },
    });
    const wrong = await call({ nickname: 'mfa', password: 'bad' });
    expect(wrong.err?.code).toBe('unauthenticated');
    const right = await call({ nickname: 'mfa', password: PW });
    expect(right.token).toBeUndefined();
    expect(right.err?.code).toBe('failed-precondition');
    expect(right.err?.reason).toBe('MFA_REQUIRED');
  });

  test('disabled accounts are refused', async () => {
    await makeUser('u_dis', 'dis');
    await admin.auth().updateUser('u_dis', { disabled: true });
    const r = await call({ nickname: 'dis', password: PW });
    expect(r.token).toBeUndefined();
    expect(r.err?.code).toBe('permission-denied');
  });

  test('a nickname mapping pointing at a password-less account fails generically', async () => {
    await admin.auth().createUser({ uid: 'u_g', email: 'g@example.com' }); // no password provider
    await db.doc('nicknames/gee').set({ uid: 'u_g', nickname: 'gee' });
    expect((await call({ nickname: 'gee', password: PW })).err?.reason).toBe('INVALID_CREDENTIALS');
  });
});

describe('nicknames/{nick} rules: no email', () => {
  test('client may write only {uid, nickname, createdAt}; email is rejected', async () => {
    expect(await clientSet('u_a', 'nicknames/alpha', { uid: 'u_a', nickname: 'alpha', createdAt: new Date() })).toBe(200);
    expect(await clientSet('u_a', 'nicknames/alpha', { uid: 'u_a', nickname: 'alpha', email: 'a@example.com' })).toBe(403);
    expect(await clientSet('u_a', 'nicknames/alpha2', { uid: 'u_a', email: 'a@example.com' })).toBe(403);
    expect(await clientSet('u_a', 'nicknames/alpha3', { uid: 'u_a', nickname: 'alpha3', foo: 1 })).toBe(403);
    expect(await clientSet('u_a', 'nicknames/alpha4', { uid: 'u_a', nickname: 'other' })).toBe(403);
    expect(await clientSet('u_b', 'nicknames/alpha', { uid: 'u_b', nickname: 'alpha' })).toBe(403);
    // Legacy {email, uid} doc: the owner may rewrite it WITHOUT the email.
    await db.doc('nicknames/legacy').set({ email: 'l@example.com', uid: 'u_l' });
    expect(await clientSet('u_l', 'nicknames/legacy', { uid: 'u_l', email: 'l@example.com' })).toBe(403);
    expect(await clientSet('u_l', 'nicknames/legacy', { uid: 'u_l', nickname: 'legacy', createdAt: new Date() })).toBe(200);
    expect((await db.doc('nicknames/legacy').get()).data()?.email).toBeUndefined();
    // Availability check: anonymous get still works, listing does not.
    const g = await clientGet(null, 'nicknames/alpha');
    expect(g.status).toBe(200);
    expect(JSON.stringify(g.body)).not.toContain('example.com');
  });

  test('strip script removes the email (dry run writes nothing)', async () => {
    await db.doc('nicknames/old').set({ email: 'o@example.com', uid: 'u_o' });
    await db.doc('nicknames/clean').set({ uid: 'u_c', nickname: 'clean', createdAt: admin.firestore.Timestamp.now() });
    expect(await stripNicknameDoc(db, 'old', false)).toEqual(['email', 'nickname+']);
    expect((await db.doc('nicknames/old').get()).data()?.email).toBe('o@example.com');
    expect(await stripNicknameDoc(db, 'old', true)).toEqual(['email', 'nickname+']);
    expect((await db.doc('nicknames/old').get()).data()).toEqual({ uid: 'u_o', nickname: 'old' });
    expect(await stripNicknameDoc(db, 'clean', true)).toEqual([]);
    expect(await stripNicknameDoc(db, 'missing', true)).toEqual([]);
    // Sign-in by nickname still works after the strip.
    await admin.auth().createUser({ uid: 'u_o', email: 'o@example.com', password: PW });
    expect(await exchangeCustomToken((await call({ nickname: 'old', password: PW })).token!)).toBe('u_o');
  });
});

describe('server age gate on profiles_private', () => {
  // Fixed noon UTC today: "today somewhere on Earth" (UTC+14) is then
  // tomorrow's UTC date, whatever time the suite runs.
  const t = new Date();
  const NOW = new Date(Date.UTC(t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate(), 12));
  const yearsAgo = (y: number, extraDays = 0) => admin.firestore.Timestamp.fromDate(
    new Date(Date.UTC(NOW.getUTCFullYear() - y, NOW.getUTCMonth(), NOW.getUTCDate() + extraDays)));

  async function writePrivate(uid: string, data: Record<string, any>) {
    const ref = db.doc(`profiles_private/${uid}`);
    const before = (await ref.get()).data();
    await ref.set(data, { merge: true });
    const after = (await ref.get()).data();
    // What syncCoarseFromPrivateProfile runs, in order.
    const blocked = await applyPrivateProfileAgeGate(uid, before, after, { now: NOW });
    await handlePrivateProfileWrite(uid, before, after, { now: NOW });
    return blocked;
  }

  test('under-18 private DOB blocks the account (age_gate + accountStatus)', async () => {
    await admin.auth().createUser({ uid: 'u_kid', email: 'kid@example.com', password: PW });
    await db.doc('profiles/u_kid').set({ userId: 'u_kid', accountStatus: 'active' });
    expect(await writePrivate('u_kid', { dateOfBirth: yearsAgo(16) })).toBe(true);
    expect((await db.doc('profiles/u_kid').get()).data()?.accountStatus).toBe(AGE_BLOCKED_STATUS);
    const gate = (await db.doc(`${AGE_GATE}/u_kid`).get()).data();
    expect(gate?.blocked).toBe(true);
    expect(gate?.ageAtBlock).toBe(16);
    expect(gate?.source).toBe('private_profile_trigger');
    // The email (from Auth) is recorded too, hashed.
    expect((await db.collection('age_gate_emails').get()).size).toBe(1);
  });

  test('adult private DOB: not blocked, public age computed from the private DOB', async () => {
    await db.doc('profiles/u_ad').set({ userId: 'u_ad', accountStatus: 'active' });
    expect(await writePrivate('u_ad', { dateOfBirth: yearsAgo(30, -3) })).toBe(false);
    const pub = (await db.doc('profiles/u_ad').get()).data();
    expect(pub?.accountStatus).toBe('active');
    expect(pub?.age).toBe(30);
    expect(pub?.dateOfBirth).toBeUndefined();
    expect((await db.doc(`${AGE_GATE}/u_ad`).get()).exists).toBe(false);
    // Changing the DOB to under 18 later blocks.
    expect(await writePrivate('u_ad', { dateOfBirth: yearsAgo(17) })).toBe(true);
    expect((await db.doc('profiles/u_ad').get()).data()?.accountStatus).toBe(AGE_BLOCKED_STATUS);
  });

  test('unrelated private writes do nothing; an 18th birthday today anywhere on Earth passes', async () => {
    await db.doc('profiles/u_b').set({ userId: 'u_b', accountStatus: 'active' });
    expect(await writePrivate('u_b', { dateOfBirth: yearsAgo(18, 1) })).toBe(false); // turns 18 tomorrow (UTC) = today in UTC+14
    expect(await writePrivate('u_b', { email: 'b@example.com' })).toBe(false);
    expect((await db.doc('profiles/u_b').get()).data()?.accountStatus).toBe('active');
    expect(await writePrivate('u_b', { dateOfBirth: yearsAgo(18, 2) })).toBe(true); // 18 in 2 days: under 18 everywhere
  });

  test('private DOB written BEFORE the public profile: profile creation is blocked', async () => {
    expect(await writePrivate('u_early', { dateOfBirth: yearsAgo(15) })).toBe(true);
    expect((await db.doc('profiles/u_early').get()).exists).toBe(false);
    const ref = db.doc('profiles/u_early');
    await ref.set({ userId: 'u_early', accountStatus: 'active' });
    expect(await applyProfileAgeGate('u_early', null, (await ref.get()).data(), ref)).toBe(true);
    expect((await ref.get()).data()?.accountStatus).toBe(AGE_BLOCKED_STATUS);
    // ...and the public profile then gets its coarse age from private.
    await handlePublicProfileWrite('u_early', undefined, (await ref.get()).data(), { now: NOW });
    expect((await ref.get()).data()?.age).toBe(15);
  });
});
