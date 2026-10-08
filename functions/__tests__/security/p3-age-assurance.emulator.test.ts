/**
 * P3-1 regional age assurance (audit H-21): getAgeAssuranceStatus,
 * recordStoreAgeSignal, setAgeAssuranceOverride, and server enforcement in
 * spendCoins (discovery / direct-message features) and scheduleMessage.
 *
 * Real Firestore + Auth emulators.
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Source modules are required lazily so that, against the pre-change code,
 * the new behaviour is what fails.
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
const TS = admin.firestore.Timestamp;

// eslint-disable-next-line @typescript-eslint/no-var-requires
const req = (p: string): any => require(p);
const gate = () => req('../../src/safety/ageAssuranceGate');
const coins = () => req('../../src/coins/spendCoins');
const sched = () => req('../../src/messaging/scheduledMessages');

const v2 = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token } : undefined });
const v1 = (fn: any, data: any, uid?: string) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token: {} } : undefined, rawRequest: {} });

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
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
}

async function setFlag(on: boolean) {
  await db.doc('app_config/feature_flags').set({ ageAssuranceEnforced: on }, { merge: true });
  await db.doc('app_config/age_assurance').set({ regions: ['BR', 'GB', 'US-TX'] }, { merge: true });
  gate().resetAgeAssuranceConfigCache();
}

const PLACES: Record<string, Record<string, unknown>> = {
  brazil: { country: 'Brazil', city: 'São Paulo', latitude: -23.55, longitude: -46.63 },
  uk: { country: 'United Kingdom', city: 'London', latitude: 51.5, longitude: -0.12 },
  austin: { country: 'United States', city: 'Austin', latitude: 30.27, longitude: -97.74 },
  elpaso: { country: 'United States', city: 'El Paso', latitude: 31.76, longitude: -106.49 },
  newyork: { country: 'United States', city: 'New York', latitude: 40.71, longitude: -74.0 },
  oklahoma: { country: 'United States', city: 'Oklahoma City', latitude: 35.47, longitude: -97.52 },
  italy: { country: 'Italy', city: 'Rome', latitude: 41.9, longitude: 12.5 },
  unknown: {},
};
async function seedUser(uid: string, place: keyof typeof PLACES, extra: Record<string, unknown> = {}) {
  await db.doc(`profiles/${uid}`).set({ displayName: uid, accountStatus: 'active', location: PLACES[place], ...extra });
}
const status = (uid: string, data: any = {}) => v2(gate().getAgeAssuranceStatus, data, uid);
const errOf = async (p: Promise<any>) => { try { await p; return null; } catch (e: any) { return e; } };

beforeEach(async () => {
  await clearAll();
  gate().resetAgeAssuranceConfigCache();
});
afterAll(() => fft.cleanup());

describe('P3-1 status per region, flag off / on', () => {
  test('flag OFF: nobody is required, whatever the region', async () => {
    await setFlag(false);
    for (const p of ['brazil', 'uk', 'austin', 'italy'] as const) {
      await seedUser(`u_${p}`, p);
      const s = await status(`u_${p}`);
      expect(s.enforced).toBe(false);
      expect(s.required).toBe(false);
      expect(s.methods).toEqual(['id_verification', 'store_signal']);
    }
  });

  test('flag ON: BR, GB and Texas are required; elsewhere (incl. other US states) is not', async () => {
    await setFlag(true);
    const expected: Record<string, boolean> = {
      brazil: true, uk: true, austin: true, elpaso: true, newyork: false, oklahoma: false, italy: false, unknown: false,
    };
    for (const [p, want] of Object.entries(expected)) {
      await seedUser(`u_${p}`, p as any);
      const s = await status(`u_${p}`);
      expect({ p, required: s.required }).toEqual({ p, required: want });
      expect(s.satisfied).toBe(false);
    }
  });

  test('hints: locale country only fills a MISSING profile country; subdivision hint can add US-TX but never remove a region', async () => {
    await setFlag(true);
    await seedUser('noCountry', 'unknown');
    expect((await status('noCountry', { localeCountry: 'BR' })).required).toBe(true);
    // Stored hint is reused by later calls (and by enforcement).
    expect((await status('noCountry')).required).toBe(true);

    await seedUser('brLiar', 'brazil');
    expect((await status('brLiar', { localeCountry: 'IT', storeCountry: 'IT' })).required).toBe(true);

    await seedUser('usNoCoords', 'unknown', { location: { country: 'United States' } });
    expect((await status('usNoCoords')).required).toBe(false);
    expect((await status('usNoCoords', { subdivision: 'US-TX' })).required).toBe(true);

    await seedUser('itWithBrStore', 'italy');
    expect((await status('itWithBrStore', { storeCountry: 'BR' })).required).toBe(true);
  });

  test('region list is admin-editable', async () => {
    await setFlag(true);
    await db.doc('app_config/age_assurance').set({ regions: ['IT'] });
    gate().resetAgeAssuranceConfigCache();
    await seedUser('it', 'italy');
    await seedUser('br', 'brazil');
    expect((await status('it')).required).toBe(true);
    expect((await status('br')).required).toBe(false);
  });

  test('unauthenticated is refused', async () => {
    expect((await errOf(status(undefined as any)))?.code).toBe('unauthenticated');
  });
});

describe('P3-1 satisfying methods', () => {
  beforeEach(() => setFlag(true));

  test('(a) approved ID verification satisfies (profile flag or id_documents record)', async () => {
    await seedUser('idA', 'brazil', { isAgeVerified: true });
    const a = await status('idA');
    expect(a).toMatchObject({ required: true, satisfied: true, satisfiedBy: ['id_verification'] });
    await seedUser('idB', 'uk');
    await db.doc('id_documents/idB').set({ ageVerified: true, method: 'document' });
    expect((await status('idB')).satisfied).toBe(true);
  });

  test('(b) Android store signal: TIER_C/D adult accepted; self-declared TIER_A is recorded but not accepted', async () => {
    await seedUser('andA', 'brazil');
    const weak = await v2(gate().recordStoreAgeSignal, { platform: 'android', ageLower: 18, ageUpper: null, ageRangeSource: 1 }, 'andA');
    expect(weak).toMatchObject({ accepted: false, reason: 'SOURCE_NOT_ACCEPTED', satisfied: false });
    const strong = await v2(gate().recordStoreAgeSignal, { platform: 'android', ageLower: 18, ageUpper: null, ageRangeSource: 3, installId: 'i1' }, 'andA');
    expect(strong).toMatchObject({ accepted: true, required: true, satisfied: true, satisfiedBy: ['store_signal'] });
    const rec = (await db.doc('age_assurance/andA').get()).data()!;
    expect(rec.storeSignal).toMatchObject({
      platform: 'android', source: 'google_play_age_signals', strength: '3', accepted: true, verifiedServerSide: false, installId: 'i1',
    });
    expect(rec.storeSignal.recordedAt).toBeInstanceOf(TS);
    expect(rec.lastSatisfiedMethod).toBe('store_signal');
  });

  test('(b) Apple Declared Age Range: a checked declaration is accepted, selfDeclared is not', async () => {
    await seedUser('iosA', 'uk');
    expect((await v2(gate().recordStoreAgeSignal, { platform: 'ios', ageLower: 18, declaration: 'selfDeclared' }, 'iosA')).accepted).toBe(false);
    const r = await v2(gate().recordStoreAgeSignal, { platform: 'ios', ageLower: 18, declaration: 'governmentIDChecked' }, 'iosA');
    expect(r).toMatchObject({ accepted: true, satisfied: true });
    expect((await db.doc('age_assurance/iosA').get()).data()!.storeSignal.source).toBe('apple_declared_age_range');
  });

  test('(b) a stale store signal stops counting; not shared is not accepted', async () => {
    await seedUser('old', 'brazil');
    await db.doc('age_assurance/old').set({ storeSignal: { accepted: true, recordedAt: TS.fromMillis(Date.now() - 400 * 86_400_000) } });
    expect((await status('old')).satisfied).toBe(false);
    const r = await v2(gate().recordStoreAgeSignal, { platform: 'android', shared: false, ageRangeSource: 4 }, 'old');
    expect(r).toMatchObject({ accepted: false, reason: 'NOT_SHARED' });
  });

  test('a store signal saying UNDER 18 age-blocks the account (like declareAge)', async () => {
    await seedUser('kid', 'brazil');
    const r = await v2(gate().recordStoreAgeSignal, { platform: 'android', ageLower: 13, ageUpper: 15, ageRangeSource: 2 }, 'kid');
    expect(r).toMatchObject({ accepted: false, reason: 'UNDER_18' });
    expect((await db.doc('age_gate/kid').get()).data()?.blocked).toBe(true);
    expect((await db.doc('profiles/kid').get()).data()?.accountStatus).toBe('age_blocked');
  });

  test('invalid platform is refused', async () => {
    await seedUser('x', 'brazil');
    expect((await errOf(v2(gate().recordStoreAgeSignal, { platform: 'web' }, 'x')))?.code).toBe('invalid-argument');
  });

  test('(c) admin override: superAdmin only, audited, revocable', async () => {
    await seedUser('target', 'brazil');
    await db.doc('admin_users/boss').set({ role: 'superAdmin', isActive: true });
    await db.doc('admin_users/mod').set({ role: 'moderator', isActive: true });

    expect((await errOf(v2(gate().setAgeAssuranceOverride, { userId: 'target', granted: true }, 'target')))?.code).toBe('permission-denied');
    expect((await errOf(v2(gate().setAgeAssuranceOverride, { userId: 'target', granted: true }, 'mod', { adminRole: 'moderator' })))?.code).toBe('permission-denied');
    expect((await errOf(v2(gate().setAgeAssuranceOverride, { userId: 'target', granted: true }, undefined)))?.code).toBe('unauthenticated');
    expect((await status('target')).satisfied).toBe(false);

    const g = await v2(gate().setAgeAssuranceOverride, { userId: 'target', granted: true, reason: 'support ticket 42' }, 'boss', { adminRole: 'superAdmin' });
    expect(g).toMatchObject({ granted: true, satisfied: true, satisfiedBy: ['admin_override'] });
    const audit = await db.collection('admin_audit_log').where('targetId', '==', 'target').get();
    expect(audit.docs.map((d) => d.data().action)).toEqual(['age_assurance_override_grant']);

    await v2(gate().setAgeAssuranceOverride, { userId: 'target', granted: false }, 'boss', { adminRole: 'superAdmin' });
    expect((await status('target')).satisfied).toBe(false);
  });
});

describe('P3-1 server enforcement', () => {
  const spend = (uid: string, featureId: string) =>
    v2(coins().spendCoins, { featureId, requestId: `req_${featureId}_${uid}`.slice(0, 60) }, uid);
  const reasonOf = (e: any) => e?.details?.reason ?? null;

  test('spendCoins refuses discovery / direct-message features for unassured region users, before any charge', async () => {
    await setFlag(true);
    await seedUser('brUser', 'brazil');
    await db.doc('coinBalances/brUser').set({ userId: 'brUser', totalCoins: 500, earnedCoins: 0, purchasedCoins: 500, giftedCoins: 0, spentCoins: 0, coinBatches: [] });
    for (const f of ['direct_message', 'superlike', 'grid_view_more', 'discovery_see_more', 'super_like']) {
      const e = await errOf(spend('brUser', f));
      expect({ f, code: e?.code, reason: reasonOf(e) }).toEqual({ f, code: 'failed-precondition', reason: 'age-assurance-required' });
    }
    expect((await db.doc('coinBalances/brUser').get()).data()?.totalCoins).toBe(500);
    // Other features are not gated.
    expect(reasonOf(await errOf(spend('brUser', 'boost')))).not.toBe('age-assurance-required');
  });

  test('spendCoins: assured, non-region and flag-off users are not refused for age', async () => {
    await setFlag(true);
    await seedUser('brOk', 'brazil', { isAgeVerified: true });
    await seedUser('itUser', 'italy');
    expect(reasonOf(await errOf(spend('brOk', 'direct_message')))).not.toBe('age-assurance-required');
    expect(reasonOf(await errOf(spend('itUser', 'direct_message')))).not.toBe('age-assurance-required');
    await setFlag(false);
    await seedUser('brOff', 'brazil');
    expect(reasonOf(await errOf(spend('brOff', 'grid_view_more')))).not.toBe('age-assurance-required');
  });

  const schedule = (uid: string, conversationId: string) => v1(sched().scheduleMessage, {
    conversationId, matchId: 'm1', senderId: uid, receiverId: 'other', content: 'hi',
    scheduledFor: new Date(Date.now() + 3_600_000).toISOString(),
  }, uid);

  test('scheduleMessage: unassured region user cannot write a FIRST message; can continue a conversation they already wrote in', async () => {
    await setFlag(true);
    await seedUser('brS', 'brazil');
    await db.doc('conversations/c1').set({ userId1: 'brS', userId2: 'other' });
    await db.doc('conversations/c1/messages/in1').set({ senderId: 'other', content: 'hello' });
    const e = await errOf(schedule('brS', 'c1'));
    expect(e?.code).toBe('failed-precondition');
    expect(reasonOf(e)).toBe('age-assurance-required');

    await db.doc('conversations/c2').set({ userId1: 'brS', userId2: 'other' });
    await db.doc('conversations/c2/messages/out1').set({ senderId: 'brS', content: 'earlier' });
    const ok = await schedule('brS', 'c2');
    expect(ok.success).toBe(true);
  });

  test('scheduleMessage: non-region user and flag off are unaffected', async () => {
    await setFlag(true);
    await seedUser('itS', 'italy');
    expect((await schedule('itS', 'c3')).success).toBe(true);
    await setFlag(false);
    await seedUser('brOffS', 'brazil');
    expect((await schedule('brOffS', 'c4')).success).toBe(true);
  });
});

describe('P3-1 pure helpers', () => {
  test('country names / codes', () => {
    const { countryCodeOf } = gate();
    expect(countryCodeOf('Brasil')).toBe('BR');
    expect(countryCodeOf('Regno Unito')).toBe('GB');
    expect(countryCodeOf('uk')).toBe('GB');
    expect(countryCodeOf('United States')).toBe('US');
    expect(countryCodeOf('Narnia')).toBeNull();
  });
  test('Texas polygon: in-state cities in, neighbouring-state cities out', () => {
    const { usStateFromCoarse } = gate();
    for (const [lat, lng] of [[29.76, -95.37], [32.78, -96.8], [35.22, -101.83], [27.8, -97.4], [29.3, -94.8], [31.76, -106.49], [25.9, -97.5]]) {
      expect({ lat, lng, s: usStateFromCoarse(lat, lng) }).toEqual({ lat, lng, s: 'US-TX' });
    }
    // Shreveport LA, Oklahoma City, Albuquerque, Little Rock, Lake Charles LA, Las Cruces NM
    for (const [lat, lng] of [[32.52, -93.75], [35.47, -97.52], [35.08, -106.65], [34.75, -92.29], [30.23, -93.22], [32.35, -106.76]]) {
      expect({ lat, lng, s: usStateFromCoarse(lat, lng) }).toEqual({ lat, lng, s: null });
    }
  });
});
