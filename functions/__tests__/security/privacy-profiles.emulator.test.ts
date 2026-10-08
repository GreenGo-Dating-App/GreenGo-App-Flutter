/**
 * P1-4 private profile split (audit C-07 exact location, C-10 selfie URL):
 * emulator integration tests for the mirror triggers, coarse location / age,
 * the backfill + strip scripts, and the admin / album callables.
 *
 *   firebase emulators:exec --config ../firebase.emulators.<you>.json \
 *     --only firestore,auth --project test-project "npx jest --config jest.security.config.js"
 */

import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import {
  approxLocationFor,
  ageFrom,
  computeCoarse,
  geohashBounds,
  geohashEncode,
  handlePrivateProfileWrite,
  handlePublicProfileWrite,
  jitterOffsetMeters,
} from '../../src/profiles/privateProfile';
import {
  mirrorPrivateProfileFields,
  syncCoarseFromPrivateProfile,
  getVerificationPhotoUrl,
  getSharedAlbum,
  resolveVerificationPhotoUrl,
  runBirthdayAgeRefresh,
  runPrivateProfileBackfill,
  birthdayKeysFor,
} from '../../src/profiles/privateProfileTriggers';
import { stripOne } from '../../scripts/strip-public-sensitive-fields';

const db = admin.firestore();
const Ts = admin.firestore.Timestamp;

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const project = process.env.GCLOUD_PROJECT;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  await new Promise<void>((resolve, reject) => {
    const req = require('http').request(
      { host: host!.split(':')[0], port: Number(host!.split(':')[1]), method: 'DELETE',
        path: `/emulator/v1/projects/${project}/databases/(default)/documents` },
      (res: any) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const call = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token } : undefined });
const denied = { code: 'permission-denied' };

/** Great-circle distance in metres. */
function dist(a: [number, number], b: [number, number]): number {
  const R = 6371000, r = Math.PI / 180;
  const dLat = (b[0] - a[0]) * r, dLng = (b[1] - a[1]) * r;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a[0] * r) * Math.cos(b[0] * r) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

// Rome, Piazza Navona-ish.
const ROME: [number, number] = [41.89893, 12.47311];
const MILAN: [number, number] = [45.46416, 9.19199];

const legacyPublic = (over: Record<string, any> = {}) => ({
  displayName: 'Alice',
  location: { latitude: ROME[0], longitude: ROME[1], city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy' },
  geohash: geohashEncode(ROME[0], ROME[1], 9),
  dateOfBirth: Ts.fromDate(new Date(Date.UTC(1995, 4, 20))),
  sexualOrientation: 'straight',
  email: 'alice@example.com',
  verificationPhone: '+390000000',
  verificationPhotoUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/verifications%2Falice%2Fa.jpg?alt=media&token=t',
  privatePhotoUrls: ['https://p/1.jpg'],
  ageVerification: { status: 'verified', documentHash: 'h1', documentDateOfBirth: Ts.fromDate(new Date(Date.UTC(1995, 4, 20))) },
  ...over,
});

/** Simulates the platform delivering the profiles/{uid} write event. */
async function firePublic(uid: string, before: any) {
  const snap = await db.doc(`profiles/${uid}`).get();
  return handlePublicProfileWrite(uid, before, snap.exists ? snap.data() : undefined);
}
async function firePrivate(uid: string, before: any) {
  const snap = await db.doc(`profiles_private/${uid}`).get();
  return handlePrivateProfileWrite(uid, before, snap.exists ? snap.data() : undefined);
}
const data = async (p: string) => (await db.doc(p).get()).data();
const updateTime = async (p: string) => (await db.doc(p).get()).updateTime?.toMillis();

beforeEach(clearAll);
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('mirrorPrivateProfileFields: public -> private (old app versions)', () => {
  test('sensitive fields are copied to profiles_private; public gets geohash5 / approxLocation / age', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    const r: any = await firePublic('alice', undefined);
    expect(r.privateWrites).toBe(1);

    const priv = await data('profiles_private/alice');
    expect(priv.location).toEqual({ latitude: ROME[0], longitude: ROME[1] });
    expect(priv.geohash).toBe(geohashEncode(ROME[0], ROME[1], 9));
    expect(priv.dateOfBirth.toDate().toISOString()).toBe('1995-05-20T00:00:00.000Z');
    expect(priv.email).toBe('alice@example.com');
    expect(priv.verificationPhone).toBe('+390000000');
    expect(priv.verificationPhotoUrl).toMatch(/verifications/);
    expect(priv.privatePhotoUrls).toEqual(['https://p/1.jpg']);
    expect(priv.sexualOrientation).toBe('straight');
    expect(priv.ageVerification).toEqual({ documentHash: 'h1', documentDateOfBirth: expect.anything() });
    expect(priv.birthMonthDay).toBe('05-20');
    // City / country are NOT sensitive and are not copied.
    expect(priv.location.city).toBeUndefined();

    const pub = await data('profiles/alice');
    expect(pub.geohash5).toBe(geohashEncode(ROME[0], ROME[1], 5));
    expect(pub.age).toBe(ageFrom(new Date(Date.UTC(1995, 4, 20))));
    expect(dist([pub.approxLocation.lat, pub.approxLocation.lng], ROME)).toBeLessThan(5000);
    // Not deleted yet: old app versions still read them.
    expect(pub.location.latitude).toBe(ROME[0]);
  });

  test('the exported v2 trigger is wired to the same handler', async () => {
    await db.doc('profiles/wired').set(legacyPublic());
    const after = fft.firestore.makeDocumentSnapshot(legacyPublic(), 'profiles/wired');
    const before = fft.firestore.makeDocumentSnapshot({}, 'profiles/wired');
    await (mirrorPrivateProfileFields as any).run({ data: fft.makeChange(before, after), params: { uid: 'wired' } });
    expect((await data('profiles_private/wired')).email).toBe('alice@example.com');
    expect((await data('profiles/wired')).geohash5).toBeTruthy();
  });

  test('presence / counter writes exit without reading or writing anything', async () => {
    const before = legacyPublic();
    await db.doc('profiles/alice').set(before);
    await firePublic('alice', undefined);
    const b = await data('profiles/alice');
    await db.doc('profiles/alice').update({ lastSeen: Ts.now(), isOnline: true, followersCount: 3 });
    const t0 = await updateTime('profiles_private/alice');
    expect(await firePublic('alice', b)).toBe('skipped');
    expect(await updateTime('profiles_private/alice')).toBe(t0);
  });

  test('a later old-app location change moves private + coarse', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    await firePublic('alice', undefined);
    const b = await data('profiles/alice');
    await db.doc('profiles/alice').update({ 'location.latitude': MILAN[0], 'location.longitude': MILAN[1] });
    await firePublic('alice', b);
    expect((await data('profiles_private/alice')).location).toEqual({ latitude: MILAN[0], longitude: MILAN[1] });
    expect((await data('profiles/alice')).geohash5).toBe(geohashEncode(MILAN[0], MILAN[1], 5));
  });

  test('OUT OF ORDER: a late event copies the CURRENT public value, never the stale one', async () => {
    await db.doc('profiles/alice').set(legacyPublic({ email: 'a@x.com' }));
    const before1 = await data('profiles/alice');
    await db.doc('profiles/alice').update({ email: 'b@x.com' });
    const before2 = await data('profiles/alice');
    await db.doc('profiles/alice').update({ email: 'c@x.com' });
    // Event 2 (b -> c) is delivered first, then the late event 1 (a -> b).
    await firePublic('alice', before2);
    await firePublic('alice', before1);
    expect((await data('profiles_private/alice')).email).toBe('c@x.com');
  });

  test('a field REMOVED from public (new app / strip) is not propagated', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    await firePublic('alice', undefined);
    const b = await data('profiles/alice');
    await db.doc('profiles/alice').update({
      location: { city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy' },
      email: admin.firestore.FieldValue.delete(),
    });
    await firePublic('alice', b);
    const priv = await data('profiles_private/alice');
    expect(priv.location).toEqual({ latitude: ROME[0], longitude: ROME[1] });
    expect(priv.email).toBe('alice@example.com');
    // Coarse still computed from the private exact location.
    expect((await data('profiles/alice')).geohash5).toBe(geohashEncode(ROME[0], ROME[1], 5));
  });

  test('public profile deleted -> private profile deleted', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    await firePublic('alice', undefined);
    const b = await data('profiles/alice');
    await db.doc('profiles/alice').delete();
    expect(await firePublic('alice', b)).toBe('deleted');
    expect((await db.doc('profiles_private/alice').get()).exists).toBe(false);
  });

  test('traveller mode: coarse follows the active travel location, home when expired', async () => {
    const future = Ts.fromMillis(Date.now() + 86400000);
    await db.doc('profiles/t').set(legacyPublic({
      isTraveler: true, travelerExpiry: future,
      travelerLocation: { latitude: MILAN[0], longitude: MILAN[1], city: 'Milan', country: 'Italy', displayAddress: '' },
    }));
    await firePublic('t', undefined);
    expect((await data('profiles/t')).geohash5).toBe(geohashEncode(MILAN[0], MILAN[1], 5));
    expect((await data('profiles_private/t')).travelerLocation).toEqual({ latitude: MILAN[0], longitude: MILAN[1] });
    const b = await data('profiles/t');
    await db.doc('profiles/t').update({ isTraveler: false });
    await firePublic('t', b);
    expect((await data('profiles/t')).geohash5).toBe(geohashEncode(ROME[0], ROME[1], 5));
  });
});

// ---------------------------------------------------------------------------
describe('syncCoarseFromPrivateProfile: private -> public coarse (new app)', () => {
  test('new-app write to private only updates public coarse fields, never sensitive ones', async () => {
    await db.doc('profiles/bob').set({ displayName: 'Bob', location: { city: 'Milan', country: 'Italy' } });
    await db.doc('profiles_private/bob').set({
      location: { latitude: MILAN[0], longitude: MILAN[1] },
      dateOfBirth: Ts.fromDate(new Date(Date.UTC(2000, 0, 15))),
      email: 'bob@example.com',
    });
    const r: any = await firePrivate('bob', undefined);
    expect(r.publicWrites).toBe(1);
    const pub = await data('profiles/bob');
    expect(pub.geohash5).toBe(geohashEncode(MILAN[0], MILAN[1], 5));
    expect(pub.age).toBe(ageFrom(new Date(Date.UTC(2000, 0, 15))));
    expect(pub.location.latitude).toBeUndefined();
    expect(pub.dateOfBirth).toBeUndefined();
    expect(pub.email).toBeUndefined();
    expect((await data('profiles_private/bob')).birthMonthDay).toBe('01-15');
  });

  test('exported v2 trigger wired', async () => {
    await db.doc('profiles/w2').set({ displayName: 'W' });
    const priv = { location: { latitude: MILAN[0], longitude: MILAN[1] } };
    await db.doc('profiles_private/w2').set(priv);
    const before = fft.firestore.makeDocumentSnapshot({}, 'profiles_private/w2');
    const after = fft.firestore.makeDocumentSnapshot(priv, 'profiles_private/w2');
    await (syncCoarseFromPrivateProfile as any).run({ data: fft.makeChange(before, after), params: { uid: 'w2' } });
    expect((await data('profiles/w2')).geohash5).toBe(geohashEncode(MILAN[0], MILAN[1], 5));
  });

  test('private write without a public profile does nothing', async () => {
    await db.doc('profiles_private/ghost').set({ location: { latitude: 1, longitude: 1 } });
    await firePrivate('ghost', undefined);
    expect((await db.doc('profiles/ghost').get()).exists).toBe(false);
  });
});

// ---------------------------------------------------------------------------
describe('NO LOOPS: every trigger write re-fires the other trigger into a no-op', () => {
  test('old-app write: mirror -> (private trigger, public trigger) both write nothing', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    const pubBefore = await data('profiles/alice');
    const r1: any = await firePublic('alice', undefined);
    expect(r1.privateWrites + r1.publicWrites).toBe(2);
    const pubT = await updateTime('profiles/alice');
    const privT = await updateTime('profiles_private/alice');

    // The mirror's private write fires syncCoarse...: nothing to change.
    const r2: any = await firePrivate('alice', undefined);
    expect(r2.privateWrites + r2.publicWrites).toBe(0);
    // The mirror's public coarse write fires the mirror again: skipped.
    expect(await firePublic('alice', { ...pubBefore })).not.toBe(undefined);
    const r3 = await firePublic('alice', await data('profiles/alice'));
    expect(r3).toBe('skipped');
    expect(await updateTime('profiles/alice')).toBe(pubT);
    expect(await updateTime('profiles_private/alice')).toBe(privT);
  });

  test('new-app write: syncCoarse -> mirror skips; syncCoarse again writes nothing', async () => {
    await db.doc('profiles/bob').set({ displayName: 'Bob' });
    await db.doc('profiles_private/bob').set({ location: { latitude: MILAN[0], longitude: MILAN[1] },
      dateOfBirth: Ts.fromDate(new Date(Date.UTC(2000, 0, 15))) });
    const pubBefore = await data('profiles/bob');
    const privBefore = await data('profiles_private/bob');
    await firePrivate('bob', undefined);
    const pubT = await updateTime('profiles/bob');
    const privT = await updateTime('profiles_private/bob');
    // Public coarse write -> mirror: only coarse fields changed -> skipped.
    expect(await firePublic('bob', pubBefore)).toBe('skipped');
    // birthMonthDay write -> syncCoarse: no coarse input changed -> skipped.
    expect(await firePrivate('bob', { ...privBefore, birthMonthDay: undefined })).toBe('skipped');
    // Even a forced full re-run writes nothing.
    const r: any = await firePrivate('bob', undefined);
    expect(r.privateWrites + r.publicWrites).toBe(0);
    expect(await updateTime('profiles/bob')).toBe(pubT);
    expect(await updateTime('profiles_private/bob')).toBe(privT);
  });

  test('concurrent owner edit of another private field is not clobbered', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    await db.doc('profiles_private/alice').set({ verificationPhotoPath: 'verifications/alice/new.jpg' });
    await firePublic('alice', undefined);
    expect((await data('profiles_private/alice')).verificationPhotoPath).toBe('verifications/alice/new.jpg');
  });
});

// ---------------------------------------------------------------------------
describe('approxLocation: stable jitter + trilateration resistance', () => {
  test('same uid -> same offset (deterministic, no drift); <= 1.5 km; uids differ', () => {
    const a1 = jitterOffsetMeters('user-1', 'k'.repeat(32));
    const a2 = jitterOffsetMeters('user-1', 'k'.repeat(32));
    const b = jitterOffsetMeters('user-2', 'k'.repeat(32));
    expect(a1).toEqual(a2);
    expect(a1).not.toEqual(b);
    for (let i = 0; i < 500; i++) {
      const o = jitterOffsetMeters(`u${i}`, 'k'.repeat(32));
      expect(Math.hypot(o.north, o.east)).toBeLessThanOrEqual(1500);
    }
    // Re-saving the same place many times never moves the public point.
    const p1 = approxLocationFor('user-1', ROME[0], ROME[1]);
    const p2 = approxLocationFor('user-1', ROME[0] + 0.0001, ROME[1] + 0.0001);
    expect(p1).toEqual(p2);
    const cell = geohashBounds(p1.geohash5);
    const centre: [number, number] = [(cell.latMin + cell.latMax) / 2, (cell.lngMin + cell.lngMax) / 2];
    expect(dist(centre, [p1.approxLocation.lat, p1.approxLocation.lng])).toBeLessThanOrEqual(1500);
  });

  test('two true positions >= 2.5 km apart in one geohash5 cell publish IDENTICAL fields', () => {
    const cell = geohashBounds(geohashEncode(ROME[0], ROME[1], 5));
    const p: [number, number] = [cell.latMin + 0.002, cell.lngMin + 0.002];
    const q: [number, number] = [cell.latMax - 0.002, cell.lngMax - 0.002];
    expect(dist(p, q)).toBeGreaterThanOrEqual(2500);
    const dob = Ts.fromDate(new Date(Date.UTC(1990, 1, 1)));
    const cp = computeCoarse('victim', {}, { location: { latitude: p[0], longitude: p[1] }, dateOfBirth: dob });
    const cq = computeCoarse('victim', {}, { location: { latitude: q[0], longitude: q[1] }, dateOfBirth: dob });
    expect(cp).toEqual(cq);
  });

  test('3 vantage points with exact distances to the public point cannot locate the victim within 1 km', () => {
    const uid = 'victim';
    const cell = geohashBounds(geohashEncode(ROME[0], ROME[1], 5));
    // Attacker: three spoofed vantage points ~3 km around, each sees the
    // EXACT distance to the published point (worse than the app's buckets).
    const pub = approxLocationFor(uid, ROME[0], ROME[1]).approxLocation;
    const V: [number, number][] = [[pub.lat + 0.03, pub.lng], [pub.lat - 0.015, pub.lng + 0.03], [pub.lat - 0.015, pub.lng - 0.03]];

    let tested = 0, within1km = 0, maxErr = 0;
    for (let i = 1; i < 15; i++) {
      for (let j = 1; j < 15; j++) {
        const truth: [number, number] = [
          cell.latMin + ((cell.latMax - cell.latMin) * i) / 15,
          cell.lngMin + ((cell.lngMax - cell.lngMin) * j) / 15,
        ];
        const c = computeCoarse(uid, {}, { location: { latitude: truth[0], longitude: truth[1] } });
        const published: [number, number] = [c.approxLocation.lat, c.approxLocation.lng];
        const d = V.map((v) => dist(v, published));
        // Least-squares trilateration (grid search, ~20 m steps).
        let best: [number, number] = published, bestErr = Infinity;
        for (let a = -0.05; a <= 0.05; a += 0.0002) {
          for (let b = -0.05; b <= 0.05; b += 0.002) {
            const e: [number, number] = [pub.lat + a, pub.lng + b];
            const err = V.reduce((s, v, k) => s + (dist(v, e) - d[k]) ** 2, 0);
            if (err < bestErr) { bestErr = err; best = e; }
          }
        }
        const miss = dist(best, truth);
        tested++;
        if (miss < 1000) within1km++;
        maxErr = Math.max(maxErr, miss);
      }
    }
    // The estimate is the same point for the whole ~24 km2 cell, so at most
    // the ~3 km2 disc around it is within 1 km: the attacker cannot get within
    // 1 km for the overwhelming majority of positions, and is >= 2.5 km off
    // for some.
    expect(within1km / tested).toBeLessThan(0.2);
    expect(maxErr).toBeGreaterThan(2500);
  }, 60000);
});

// ---------------------------------------------------------------------------
describe('age', () => {
  test('integer years in UTC, decremented the day before the birthday', () => {
    const dob = new Date(Date.UTC(2000, 9, 8));
    expect(ageFrom(dob, new Date(Date.UTC(2026, 9, 8)))).toBe(26);
    expect(ageFrom(dob, new Date(Date.UTC(2026, 9, 7, 23, 59)))).toBe(25);
    expect(ageFrom(new Date(Date.UTC(2030, 0, 1)), new Date(Date.UTC(2026, 0, 1)))).toBeNull();
    expect(ageFrom(null)).toBeNull();
  });

  test('Feb 29 birthdays age on Mar 1 in common years', () => {
    expect(birthdayKeysFor(new Date(Date.UTC(2027, 2, 1)))).toEqual(['03-01', '02-29']);
    expect(birthdayKeysFor(new Date(Date.UTC(2028, 2, 1)))).toEqual(['03-01']);
  });

  test('refreshBirthdayAges bumps only today\'s birthdays', async () => {
    const now = new Date(Date.UTC(2026, 9, 8, 1));
    await db.doc('profiles/bday').set({ age: 25 });
    await db.doc('profiles_private/bday').set({ dateOfBirth: Ts.fromDate(new Date(Date.UTC(2000, 9, 8))), birthMonthDay: '10-08' });
    await db.doc('profiles/other').set({ age: 25 });
    await db.doc('profiles_private/other').set({ dateOfBirth: Ts.fromDate(new Date(Date.UTC(2000, 9, 9))), birthMonthDay: '10-09' });
    const r = await runBirthdayAgeRefresh(now);
    expect(r).toEqual({ scanned: 1, updated: 1 });
    expect((await data('profiles/bday')).age).toBe(26);
    expect((await data('profiles/other')).age).toBe(25);
  });
});

// ---------------------------------------------------------------------------
describe('backfill + strip scripts', () => {
  test('backfill fills missing private fields, never overwrites a newer private value, and is idempotent', async () => {
    await db.doc('profiles/old').set(legacyPublic());
    // New-app user: stale public lat/lng, newer private location.
    await db.doc('profiles/newapp').set(legacyPublic());
    await db.doc('profiles_private/newapp').set({ location: { latitude: MILAN[0], longitude: MILAN[1] } });
    const r1 = await runPrivateProfileBackfill({ pageSize: 1 });
    expect(r1.done).toBe(true);
    expect(r1.scanned).toBe(2);
    expect((await data('profiles_private/old')).email).toBe('alice@example.com');
    expect((await data('profiles_private/newapp')).location).toEqual({ latitude: MILAN[0], longitude: MILAN[1] });
    expect((await data('profiles/newapp')).geohash5).toBe(geohashEncode(MILAN[0], MILAN[1], 5));
    const r2 = await runPrivateProfileBackfill({});
    expect(r2.privateWrites + r2.publicWrites).toBe(0);
  });

  test('strip: dry run changes nothing; apply removes public copies and keeps private data', async () => {
    await db.doc('profiles/alice').set(legacyPublic());
    const dry = await stripOne(db, 'alice', false);
    expect(dry).toContain('dateOfBirth');
    expect((await data('profiles/alice')).dateOfBirth).toBeTruthy();
    expect((await db.doc('profiles_private/alice').get()).exists).toBe(false);

    const b = await data('profiles/alice');
    await stripOne(db, 'alice', true);
    const pub = await data('profiles/alice');
    for (const f of ['geohash', 'dateOfBirth', 'email', 'verificationPhone', 'verificationPhotoUrl', 'privatePhotoUrls', 'sexualOrientation']) {
      expect(pub[f]).toBeUndefined();
    }
    expect(pub.location).toEqual({ city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy' });
    expect(pub.ageVerification).toEqual({ status: 'verified' });
    // The mirror sees the deletions and does not propagate them.
    await firePublic('alice', b);
    const priv = await data('profiles_private/alice');
    expect(priv.location).toEqual({ latitude: ROME[0], longitude: ROME[1] });
    expect(priv.email).toBe('alice@example.com');
    expect(priv.ageVerification.documentHash).toBe('h1');
    expect((await data('profiles/alice')).age).toBeGreaterThan(20);
    expect(await stripOne(db, 'alice', true)).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
describe('getVerificationPhotoUrl (admin only)', () => {
  test('ATTACK: a normal user or a support admin is denied', async () => {
    await db.doc('profiles_private/victim').set({ verificationPhotoPath: 'verifications/victim/a.jpg' });
    await expect(call(getVerificationPhotoUrl, { uid: 'victim' }, 'mallory')).rejects.toMatchObject(denied);
    await db.doc('admin_users/sup').set({ role: 'support' });
    await expect(call(getVerificationPhotoUrl, { uid: 'victim' }, 'sup')).rejects.toMatchObject(denied);
    await expect(call(getVerificationPhotoUrl, { uid: 'victim' })).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  test('LEGIT: moderator gets the legacy URL for old submissions, null when none', async () => {
    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await db.doc('profiles/old').set({ verificationPhotoUrl: 'https://legacy/url' });
    await expect(call(getVerificationPhotoUrl, { uid: 'old' }, 'mod'))
      .resolves.toEqual({ url: 'https://legacy/url', expiresAt: null, source: 'legacy' });
    await expect(call(getVerificationPhotoUrl, { uid: 'nobody' }, 'mod'))
      .resolves.toEqual({ url: null, expiresAt: null, source: 'none' });
  });

  test('stored path -> short-lived signed URL; a path outside the user folder is refused', async () => {
    await db.doc('profiles_private/v').set({ verificationPhotoPath: 'verifications/v/selfie.jpg' });
    const signed: string[] = [];
    const r = await resolveVerificationPhotoUrl('v', { sign: async (p, exp) => { signed.push(p); return `https://signed/${p}?e=${exp}`; } });
    expect(r.source).toBe('path');
    expect(signed).toEqual(['verifications/v/selfie.jpg']);
    expect(r.expiresAt - Date.now()).toBeLessThanOrEqual(10 * 60 * 1000);
    await db.doc('profiles_private/lg').set({ verificationPhotoPath: 'profiles/lg/verifications/1.jpg' });
    await expect(resolveVerificationPhotoUrl('lg', { sign: async (p) => `https://signed/${p}` }))
      .resolves.toMatchObject({ source: 'path', url: 'https://signed/profiles/lg/verifications/1.jpg' });
    await db.doc('profiles_private/w').set({ verificationPhotoPath: 'verifications/someone-else/x.jpg' });
    await expect(resolveVerificationPhotoUrl('w', { sign: async () => 'x' })).rejects.toThrow(/user folder/);
  });
});

// ---------------------------------------------------------------------------
describe('getSharedAlbum', () => {
  beforeEach(async () => {
    await db.doc('profiles_private/owner').set({ privatePhotoUrls: ['https://p/private1.jpg'] });
    await db.doc('profiles/owner').set({ displayName: 'Owner' });
  });

  test('LEGIT: a granted user and the owner get the photos', async () => {
    await db.collection('album_access').add({ ownerId: 'owner', grantedToId: 'friend', grantedAt: Ts.now() });
    await expect(call(getSharedAlbum, { ownerId: 'owner' }, 'friend')).resolves.toEqual({ photoUrls: ['https://p/private1.jpg'] });
    await expect(call(getSharedAlbum, { ownerId: 'owner' }, 'owner')).resolves.toEqual({ photoUrls: ['https://p/private1.jpg'] });
  });

  test('legacy public privatePhotoUrls still served when there is no private copy', async () => {
    await db.doc('profiles/legacy').set({ privatePhotoUrls: ['https://p/old.jpg'] });
    await expect(call(getSharedAlbum, { ownerId: 'legacy' }, 'legacy')).resolves.toEqual({ photoUrls: ['https://p/old.jpg'] });
  });

  test('ATTACK: not granted (or granted by someone else) -> denied', async () => {
    await db.collection('album_access').add({ ownerId: 'someone-else', grantedToId: 'stranger', grantedAt: Ts.now() });
    await expect(call(getSharedAlbum, { ownerId: 'owner' }, 'stranger')).rejects.toMatchObject(denied);
    await expect(call(getSharedAlbum, { ownerId: 'owner' })).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});
