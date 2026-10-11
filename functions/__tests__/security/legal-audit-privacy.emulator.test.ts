/**
 * Legal / regulatory audit 2026-10 (EU-02, BR-04, US-03, GCC-01, AS-06,
 * EU-05, BR-06, BR-09) - server + rules enforcement:
 *
 *  1. Sexual orientation is gone: clients cannot store a NEW value (profiles,
 *     profiles_private, users, the removed discovery filter); the purge
 *     script removes every stored copy (dry run first); exports drop it.
 *  2. AI consent v2: the Claude support assistant needs an accepted consent
 *     of version >= 2 (the notice that names Anthropic). v1 (Google only),
 *     none and withdrawn all hand the chat to a human, nothing goes to
 *     Anthropic. Google features keep accepting v1.
 *  3. Marco Civil access logs: logAccess records IP + time with a 6-month
 *     expireAt, de-duplicated per minute; the blocking-function handler never
 *     throws; access_logs is unreadable/unwritable from any client.
 *  4. reverseGeocodeCoarse only ever sends ~1 km coordinates.
 *
 * Real Firestore + Auth emulators; only outbound HTTP (global fetch) mocked.
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
const Ts = admin.firestore.Timestamp;

// --- outbound HTTP mock ------------------------------------------------------
const fetchMock = jest.fn(async (url: any) => {
  const u = String(url);
  const json = (status: number, body: any) => ({
    ok: status >= 200 && status < 300, status, json: async () => body, text: async () => JSON.stringify(body),
  });
  if (u.includes('api.anthropic.com')) return json(200, { content: [{ type: 'text', text: 'Happy to help!' }] });
  if (u.includes('nominatim.openstreetmap.org/reverse')) {
    return json(200, { address: { city: 'Lisbon', country: 'Portugal' } });
  }
  return json(404, {});
});
(global as any).fetch = fetchMock;
const calls = (host: string) => fetchMock.mock.calls.filter((c) => String(c[0]).includes(host));

// --- emulator helpers -----------------------------------------------------------
const emuHost = () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  return host;
};
function emulatorRequest(method: string, path: string, headers: Record<string, string> = {}, body?: string) {
  const host = emuHost();
  return new Promise<{ status: number; body: string }>((resolve, reject) => {
    const req = http.request(
      { host: host.split(':')[0], port: Number(host.split(':')[1]), method, path, headers },
      (res) => {
        let data = '';
        res.on('data', (c) => { data += c; });
        res.on('end', () => resolve({ status: res.statusCode || 0, body: data }));
      });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}
const clearAll = () => emulatorRequest('DELETE', `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);

function userToken(uid: string): string {
  const b64 = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, sub: uid, user_id: uid,
    iat: now, exp: now + 3600, auth_time: now,
    email: `${uid}@example.com`, email_verified: true,
    firebase: { sign_in_provider: 'password', identities: {} },
  })}.`;
}

/** Plain JS -> Firestore REST `Value`. */
function toValue(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: toFields(v) } };
}
function toFields(o: Record<string, any>): any {
  const out: any = {};
  for (const [k, v] of Object.entries(o)) out[k] = toValue(v);
  return out;
}
const docPath = (p: string) => `/v1/projects/${PROJECT}/databases/(default)/documents/${p}`;
const auth = (uid: string) => ({ Authorization: `Bearer ${userToken(uid)}`, 'Content-Type': 'application/json' });
const clientGet = (uid: string, p: string) => emulatorRequest('GET', docPath(p), auth(uid));
const clientList = (uid: string, col: string) => emulatorRequest('GET', docPath(col), auth(uid));
/** Merge-update of [fields] (only those keys change), like a client update(). */
const clientUpdate = (uid: string, p: string, fields: Record<string, any>) => {
  const mask = Object.keys(fields).map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  return emulatorRequest('PATCH', `${docPath(p)}?${mask}&currentDocument.exists=true`, auth(uid),
    JSON.stringify({ fields: toFields(fields) }));
};
/** Full set (create or replace), like a client set(). */
const clientSet = (uid: string, p: string, fields: Record<string, any>) =>
  emulatorRequest('PATCH', docPath(p), auth(uid), JSON.stringify({ fields: toFields(fields) }));

const ok = (r: { status: number; body: string }) => expect({ status: r.status, body: r.status === 200 ? '' : r.body }).toEqual({ status: 200, body: '' });
const denied = (r: { status: number }) => expect(r.status).toBe(403);

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
});
afterAll(() => fft.cleanup());

// ===========================================================================
describe('rules: sexual orientation can no longer be stored by a client', () => {
  test('profiles: create with a value is DENIED; without (or null) is allowed', async () => {
    denied(await clientSet('u1', 'profiles/u1', { displayName: 'A', sexualOrientation: 'Gay' }));
    ok(await clientSet('u1', 'profiles/u1', { displayName: 'A', sexualOrientation: null }));
    ok(await clientSet('u2', 'profiles/u2', { displayName: 'B' }));
  });

  test('profiles: setting / changing a value is DENIED; legacy value unchanged or cleared is allowed', async () => {
    await db.doc('profiles/u1').set({ displayName: 'A' });
    denied(await clientUpdate('u1', 'profiles/u1', { sexualOrientation: 'Straight' }));
    await db.doc('profiles/u2').set({ displayName: 'B', sexualOrientation: 'Gay' });
    // An old app re-saving the whole profile with the stored value: allowed.
    ok(await clientUpdate('u2', 'profiles/u2', { displayName: 'B2', sexualOrientation: 'Gay' }));
    denied(await clientUpdate('u2', 'profiles/u2', { sexualOrientation: 'Bisexual' }));
    ok(await clientUpdate('u2', 'profiles/u2', { sexualOrientation: null }));
  });

  test('profiles_private: the key is no longer owner-writable', async () => {
    denied(await clientSet('u1', 'profiles_private/u1', { email: 'a@b.c', sexualOrientation: 'Gay' }));
    ok(await clientSet('u1', 'profiles_private/u1', { email: 'a@b.c' }));
    denied(await clientUpdate('u1', 'profiles_private/u1', { sexualOrientation: 'Gay' }));
  });

  test('users: no orientation and no orientation discovery filter', async () => {
    denied(await clientSet('u1', 'users/u1', { email: 'a@b.c', sexualOrientation: 'Gay' }));
    denied(await clientSet('u1', 'users/u1', { email: 'a@b.c', matchPreferences: { minAge: 18, preferredOrientations: ['Gay'] } }));
    ok(await clientSet('u1', 'users/u1', { email: 'a@b.c', matchPreferences: { minAge: 18, preferredOrientations: [] } }));
    denied(await clientUpdate('u1', 'users/u1', { matchPreferences: { minAge: 18, preferredOrientations: ['Straight'] } }));
    ok(await clientUpdate('u1', 'users/u1', { matchPreferences: { minAge: 21 } }));
    // Legacy stored filter: unrelated writes keep working until the purge.
    await db.doc('users/u2').set({ email: 'b@c.d', matchPreferences: { minAge: 18, preferredOrientations: ['Gay'] } });
    ok(await clientUpdate('u2', 'users/u2', { fcmToken: 't' }));
  });

  test('users/{uid}: the owner-subcollection rule no longer matches the user doc itself', async () => {
    // `match /{userSub=**}` also matched ZERO segments, so its owner write
    // overrode every guard on users/{uid} (role / isAdmin / orientation).
    denied(await clientSet('u3', 'users/u3', { email: 'c@x', role: 'admin' }));
    ok(await clientSet('u3', 'users/u3', { email: 'c@x' }));
    denied(await clientUpdate('u3', 'users/u3', { role: 'admin' }));
    denied(await clientUpdate('u3', 'users/u3', { isAdmin: true }));
    // Own subcollections keep working; other users' do not.
    ok(await clientSet('u3', 'users/u3/starred_messages/m1', { text: 'x' }));
    ok(await clientSet('u3', 'users/u3/flashcard_decks/d1/cards/c1', { front: 'a' }));
    denied(await clientSet('u4', 'users/u3/starred_messages/m2', { text: 'y' }));
  });
});

// ===========================================================================
describe('purge-sexual-orientation script', () => {
  const purge = () => require('../../scripts/purge-sexual-orientation');

  async function seed() {
    await db.doc('profiles/a').set({ displayName: 'A', sexualOrientation: 'Gay' });
    await db.doc('profiles/b').set({ displayName: 'B' });
    await db.doc('profiles/c').set({ displayName: 'C', sexualOrientation: null });
    await db.doc('profiles_private/a').set({ email: 'a@x', sexualOrientation: 'Gay' });
    await db.doc('users/a').set({ email: 'a@x', sexualOrientation: 'Gay', matchPreferences: { minAge: 18, preferredOrientations: ['Gay'] } });
    await db.doc('users/b').set({ email: 'b@x', matchPreferences: { minAge: 20 } });
    await db.doc('saved_searches/a/searches/s1').set({ name: 'x', preferences: { minAge: 18, preferredOrientations: [] } });
    await db.doc('saved_searches/b/searches/s2').set({ name: 'y', preferences: { minAge: 18 } });
    await db.doc('candidate_pools/IT_Female_25-34').set({
      members: [{ userId: 'a', age: 30, sexualOrientation: 'Gay' }, { userId: 'b', age: 31 }],
    });
  }

  test('dry run (default) reports every copy and changes NOTHING', async () => {
    await seed();
    const r = await purge().runPurge(db, {});
    expect(r.apply).toBe(false);
    const by = Object.fromEntries(r.targets.map((t: any) => [t.target, t]));
    expect(by.profiles.matched).toBe(1);
    expect(by.profiles_private.matched).toBe(1);
    expect(by.users.matched).toBe(1);
    expect(by['users.matchPreferences'].matched).toBe(1);
    expect(by.saved_searches.matched).toBe(1);
    expect(by.candidate_pools.matched).toBe(1);
    expect(r.totalMatched).toBe(6);
    expect(r.totalUpdated).toBe(0);
    expect(by.profiles.sampleIds).toEqual(['profiles/a']);
    expect(JSON.stringify(r)).not.toMatch(/Gay/);
    expect((await db.doc('profiles/a').get()).data()!.sexualOrientation).toBe('Gay');
    expect((await db.doc('candidate_pools/IT_Female_25-34').get()).data()!.members[0].sexualOrientation).toBe('Gay');
  });

  test('--apply removes every copy (other fields untouched); a re-run finds nothing', async () => {
    await seed();
    const r = await purge().runPurge(db, { apply: true, pageSize: 1 });
    expect(r.totalUpdated).toBe(6);
    expect(r.totalErrors).toBe(0);
    const a = (await db.doc('profiles/a').get()).data()!;
    expect(a).toEqual({ displayName: 'A' });
    expect((await db.doc('profiles_private/a').get()).data()).toEqual({ email: 'a@x' });
    expect((await db.doc('users/a').get()).data()).toEqual({ email: 'a@x', matchPreferences: { minAge: 18 } });
    expect((await db.doc('saved_searches/a/searches/s1').get()).data()).toEqual({ name: 'x', preferences: { minAge: 18 } });
    expect((await db.doc('candidate_pools/IT_Female_25-34').get()).data()!.members)
      .toEqual([{ userId: 'a', age: 30 }, { userId: 'b', age: 31 }]);
    const again = await purge().runPurge(db, { apply: true });
    expect(again.totalMatched).toBe(0);
  });

  test('--only limits the targets', async () => {
    await seed();
    const r = await purge().runPurge(db, { apply: true, only: ['profiles'] });
    expect(r.targets.map((t: any) => t.target)).toEqual(['profiles']);
    expect((await db.doc('profiles_private/a').get()).data()!.sexualOrientation).toBe('Gay');
  });
});

// ===========================================================================
describe('data export never contains the removed fields', () => {
  test('collectSections drops sexualOrientation / preferredOrientations from legacy docs', async () => {
    await db.doc('profiles/exp1').set({ displayName: 'E', sexualOrientation: 'Gay' });
    await db.doc('users/exp1').set({ email: 'e@x', matchPreferences: { minAge: 18, preferredOrientations: ['Gay'] } });
    await db.doc('profiles_private/exp1').set({ email: 'e@x', sexualOrientation: 'Gay' });
    const { collectSections } = require('../../src/auth/dataExport');
    const { sections } = await collectSections('exp1');
    const json = JSON.stringify(sections);
    expect(json).toContain('e@x');
    expect(json).not.toMatch(/sexualOrientation|preferredOrientations/);
  });
});

// ===========================================================================
describe('support assistant requires CURRENT (v2) AI consent', () => {
  const gw = () => require('../../src/ai/aiGateway');
  const support = () => require('../../src/admin/adminPanelFunctions');
  const consent = (uid: string, accepted: boolean, version: number) =>
    (fft.wrap(gw().recordConsent) as any)({
      data: { type: 'ai_processing', version, accepted, locale: 'en', platform: 'web' },
      auth: { uid, token: { email: `${uid}@example.com` } },
    });
  const fire = (id: string, data: any) =>
    (fft.wrap(support().processAISupportMessage) as any)(
      fft.firestore.makeDocumentSnapshot(data, `support_messages/${id}`), { params: { messageId: id } });
  const msg = { conversationId: 's1', senderId: 'u1', senderType: 'user', content: 'How do I change my photo?' };

  beforeEach(async () => {
    await db.doc('environment_config/production').set({
      aiAgent: { enabled: true, claudeApiKey: 'sk-test', escalateAfterMessages: 50 },
    });
    await db.doc('support_chats/s1').set({ userId: 'u1', status: 'waiting' });
    await db.doc('support_messages/a').set(msg);
  });

  const aiReplies = async () =>
    (await db.collection('support_messages').where('senderId', '==', 'ai-agent').get()).size;
  const logStatuses = async () => (await db.collection('ai_support_logs').get()).docs.map((d) => d.data().status);

  test.each([
    ['never asked', null, 'ai_consent_missing'],
    ['accepted v1 (Google-only notice)', 1, 'ai_consent_missing'],
  ])('%s: no Anthropic call, chat handed to a human', async (_name, v, status) => {
    if (v !== null) await consent('u1', true, v as number);
    await fire('a', msg);
    expect(calls('api.anthropic.com')).toHaveLength(0);
    expect(await aiReplies()).toBe(0);
    expect(await logStatuses()).toEqual([status]);
    const chat = (await db.doc('support_chats/s1').get()).data()!;
    expect(chat).toMatchObject({ status: 'open', escalatedFromAI: true, escalationReason: status });
    // The next message does not log again (already with a human).
    await fire('a', msg);
    expect(await logStatuses()).toEqual([status]);
  });

  test('withdrawn (even at v2): handed to a human as ai_consent_withdrawn', async () => {
    await consent('u1', false, 2);
    await fire('a', msg);
    expect(calls('api.anthropic.com')).toHaveLength(0);
    expect(await logStatuses()).toEqual(['ai_consent_withdrawn']);
  });

  test('accepted v2: the assistant answers', async () => {
    await consent('u1', true, 2);
    await fire('a', msg);
    expect(calls('api.anthropic.com')).toHaveLength(1);
    expect(await aiReplies()).toBe(1);
  });

  test('Google features still accept a v1 record (old app versions keep working)', async () => {
    const { getAiConsentState, hasSupportAiConsent } = require('../../src/shared/aiConsent');
    await consent('u2', true, 1);
    expect(await getAiConsentState('u2')).toBe('granted');
    expect(await hasSupportAiConsent('u2')).toBe(false);
    await consent('u2', true, 2);
    expect(await hasSupportAiConsent('u2')).toBe(true);
  });
});

// ===========================================================================
describe('Marco Civil access logs', () => {
  const mod = () => require('../../src/auth/accessLogs');
  const call = (data: any, uid?: string, headers: Record<string, any> = {}) =>
    (fft.wrap(mod().logAccess) as any)({
      data,
      auth: uid ? { uid, token: { email: `${uid}@example.com`, firebase: { sign_in_provider: 'google.com' } } } : undefined,
      rawRequest: { headers: { 'user-agent': 'GreenGo/4.6 (Android)', ...headers }, ip: '10.0.0.1' },
    });
  const logs = async () => (await db.collection('access_logs').get()).docs.map((d) => d.data());

  test('logAccess records uid, event, client IP (last X-Forwarded-For hop), UA, null port and a 6-month expireAt', async () => {
    const before = Date.now();
    await expect(call({ event: 'sign_in', platform: 'android' }, 'u1', { 'x-forwarded-for': '6.6.6.6, 203.0.113.7' }))
      .resolves.toEqual({ success: true });
    const [l] = await logs();
    expect(l).toMatchObject({
      uid: 'u1', event: 'sign_in', ip: '203.0.113.7', port: null, userAgent: 'GreenGo/4.6 (Android)',
      provider: 'google.com', source: 'callable', platform: 'android',
    });
    const days = (l.expireAt.toMillis() - l.at.toMillis()) / 864e5;
    expect(days).toBeGreaterThanOrEqual(182);
    expect(days).toBeLessThanOrEqual(185);
    expect(l.at.toMillis()).toBeGreaterThanOrEqual(before - 1000);
  });

  test('at most one record per user, event and minute; app_session is the default event', async () => {
    await call({}, 'u1');
    await call({}, 'u1');
    await call({ event: 'bogus' }, 'u1');
    const l = await logs();
    expect(l).toHaveLength(1);
    expect(l[0]).toMatchObject({ event: 'app_session', ip: '10.0.0.1' });
  });

  test('unauthenticated: nothing recorded, no error', async () => {
    await expect(call({}, undefined)).resolves.toEqual({ success: false });
    expect(await logs()).toHaveLength(0);
  });

  test('blocking handler records the sign-in from event.ipAddress / userAgent', async () => {
    await mod().handleBlockingAccessEvent({
      data: { uid: 'u9' }, ipAddress: '198.51.100.4', userAgent: 'Mozilla/5.0',
      credential: { providerId: 'password', signInMethod: 'password' },
    } as any, 'sign_in');
    expect(await logs()).toEqual([expect.objectContaining({
      uid: 'u9', event: 'sign_in', ip: '198.51.100.4', userAgent: 'Mozilla/5.0', provider: 'password',
      source: 'auth_blocking', port: null,
    })]);
  });

  test('blocking handler NEVER throws (malformed event, failing write)', async () => {
    await expect(mod().handleBlockingAccessEvent(undefined as any, 'sign_in')).resolves.toBeUndefined();
    await expect(mod().handleBlockingAccessEvent({ data: {} } as any, 'sign_up')).resolves.toBeUndefined();
    const spy = jest.spyOn(admin.firestore.DocumentReference.prototype, 'set')
      .mockRejectedValueOnce(new Error('firestore down'));
    try {
      await expect(mod().handleBlockingAccessEvent({ data: { uid: 'u8' }, ipAddress: '1.2.3.4', userAgent: 'x' } as any, 'sign_in'))
        .resolves.toBeUndefined();
    } finally {
      spy.mockRestore();
    }
  });

  test('rules: access_logs is closed to every client (owner and admin-panel users included)', async () => {
    await db.doc('admin_users/mod1').set({ role: 'superAdmin' });
    await db.doc('access_logs/x').set({ uid: 'u1', ip: '1.2.3.4' });
    denied(await clientGet('u1', 'access_logs/x'));
    denied(await clientGet('mod1', 'access_logs/x'));
    denied(await clientList('mod1', 'access_logs'));
    denied(await clientSet('u1', 'access_logs/y', { uid: 'u1', ip: '9.9.9.9' }));
    denied(await clientUpdate('u1', 'access_logs/x', { ip: '0.0.0.0' }));
  });
});

// ===========================================================================
describe('reverseGeocodeCoarse', () => {
  const mod = () => require('../../src/location/reverseGeocodeCoarse');
  const call = (data: any, uid = 'u1') =>
    (fft.wrap(mod().reverseGeocodeCoarse) as any)({ data, auth: { uid, token: {} } });

  beforeEach(() => {
    mod()._resetCache();
    require('../../src/ai/aiGateway')._resetKeyCache();
  });

  test('the third party only sees ~1 km coordinates, never the exact fix', async () => {
    await expect(call({ lat: 38.7223012, lng: -9.1393367 })).resolves.toEqual({ success: true, city: 'Lisbon', country: 'Portugal' });
    const urls = calls('nominatim').map((c) => String(c[0]));
    expect(urls).toHaveLength(1);
    expect(urls[0]).toContain('lat=38.72&lon=-9.14');
    expect(urls[0]).not.toContain('38.7223');
    // Same cell: served from cache, no second call.
    await call({ lat: 38.7249, lng: -9.1351 });
    expect(calls('nominatim')).toHaveLength(1);
  });

  test('rejects missing / invalid coordinates', async () => {
    await expect(call({ lat: 'x', lng: 1 })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call({ lat: 91, lng: 1 })).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
