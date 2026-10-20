/**
 * World map snapshots (owner decision 2026-10-20): server-built pins with the
 * SAME privacy rules as the app's client assembler. Parity is pinned by the
 * shared fixture __tests__/fixtures/world_map_pin_cases.json, which
 * test/unit/globe/world_map_snapshot_test.dart runs against the Dart code.
 */
import * as fs from 'fs';
import * as path from 'path';
import {
  CHATS_CAP,
  FOLLOWERS_CAP,
  FOLLOWING_CAP,
  INLINE_BUDGET_BYTES,
  MAX_PINS,
  ACTIVE_WINDOW_MS,
  ON_DEMAND_MIN_INTERVAL_MS,
  SNAPSHOT_SCHEMA,
  SNAPSHOT_TTL_MS,
  SnapshotReader,
  WorldMapPin,
  assemblePins,
  buildSnapshot,
  chatPartnerOf,
  decideOpen,
  dispatchDue,
  markerDue,
  personPin,
  processBatch,
  snapshotWrites,
  splitPins,
  toMillis,
} from '../../src/globe/worldMapSnapshot';
import { COUNTRY_CENTROIDS } from '../../src/globe/countryCentroids';

/* eslint-disable @typescript-eslint/no-explicit-any */

const FIXTURE = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'fixtures', 'world_map_pin_cases.json'), 'utf8'));

/** Deterministic rng (mulberry32). */
function rngOf(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function fixtureInputs() {
  return {
    userId: FIXTURE.userId,
    following: FIXTURE.following,
    followers: FIXTURE.followers,
    chats: FIXTURE.chats,
    profiles: FIXTURE.profiles,
    blocked: new Set<string>(FIXTURE.blocked),
  };
}

describe('shared fixture parity (world_map_pin_cases.json)', () => {
  // Many seeds: the jittered positions must stay inside the documented
  // bounds for every random draw, not just one.
  test.each(Array.from({ length: 25 }, (_, i) => i + 1))('seed %i: every expected pin, nothing else', (seed) => {
    const pins = assemblePins(fixtureInputs(), rngOf(seed), Date.UTC(2026, 9, 20));
    const byId = new Map(pins.map((p) => [p.id, p]));
    expect(new Set(byId.keys())).toEqual(new Set(Object.keys(FIXTURE.expected)));
    for (const id of FIXTURE.excluded) expect(byId.has(id)).toBe(false);
    for (const [id, e] of Object.entries<any>(FIXTURE.expected)) {
      const p = byId.get(id)!;
      expect({ id, kind: p.kind }).toEqual({ id, kind: e.kind });
      expect(p.badges).toEqual(e.badges);
      expect(Math.abs(p.lat - e.lat)).toBeLessThanOrEqual(e.tol + 1e-6);
      expect(Math.abs(p.lng - e.lng)).toBeLessThanOrEqual(e.tol + 1e-6);
      expect(p.name).toBe(e.name);
      expect(p.photo).toBe(e.photo);
      expect(p.country).toBe(e.country);
      expect(p.city).toBe(e.city);
      expect(p.isOnlineAtBuild).toBe(e.isOnline);
      if (e.kind === 'person') expect(p.disc).toBe(e.disc);
      expect(p.traveler ?? null).toEqual(e.traveler);
    }
  });

  test('chatPartnerOf cases', () => {
    for (const c of FIXTURE.chatPartnerCases) {
      expect({ name: c.name, got: chatPartnerOf(c.conv, 'me') }).toEqual({ name: c.name, got: c.expected });
    }
  });
});

describe('privacy invariants', () => {
  const EXACT = { lat: 41.95123, lng: 12.40001 };

  test('a non-exact person never carries exact coordinates (no approxLocation either)', () => {
    for (const disc of [undefined, 'approximate', 'country', 'odd']) {
      for (let s = 1; s < 200; s++) {
        const p = personPin({
          accountStatus: 'active', displayName: 'x', globeDiscoverability: disc,
          location: { latitude: EXACT.lat, longitude: EXACT.lng, country: 'Italy', city: 'Rome' },
          preciseLocation: { lat: EXACT.lat, lng: EXACT.lng }, // stale, must be ignored
        }, 'x', rngOf(s), Date.now())!;
        // Grid-cell centre +-0.1 deg or country centroid +-1.5 deg: never
        // the stored point itself (>= ~0.5 km away in at least one axis
        // except by a 1e-4 coincidence, which the seeds here do not hit).
        expect(Math.abs(p.lat - EXACT.lat) + Math.abs(p.lng - EXACT.lng)).toBeGreaterThan(1e-4);
      }
    }
  });

  test('the stored pin fields are only the documented public ones', () => {
    const pins = assemblePins(fixtureInputs(), rngOf(7), Date.now());
    const allowed = new Set(['id', 'kind', 'lat', 'lng', 'name', 'photo', 'badges', 'country', 'city',
      'disc', 'isOnlineAtBuild', 'traveler']);
    for (const p of pins) for (const k of Object.keys(p)) expect(allowed.has(k)).toBe(true);
  });

  test('blocked in either direction: blocked ids are never pinned, even in every group', () => {
    const profile = (n: string) => ({ ...FIXTURE.profiles.p_default, displayName: n });
    const pins = assemblePins({
      userId: 'me',
      following: [{ id: 'a', isStore: false }, { id: 'b', isStore: false }],
      followers: ['a', 'b'],
      chats: ['a', 'b'],
      profiles: { a: profile('a'), b: profile('b') },
      blocked: new Set(['a']),
    }, rngOf(1), Date.now());
    expect(pins.map((p) => p.id)).toEqual(['b']);
  });
});

describe('caps', () => {
  const p = FIXTURE.profiles.p_default;
  test('each group capped (newest first), one pin per account', () => {
    const ids = (pfx: string, n: number) => Array.from({ length: n }, (_, i) => `${pfx}${i}`);
    const following = ids('f', FOLLOWING_CAP + 50).map((id) => ({ id, isStore: false }));
    const followers = ids('r', FOLLOWERS_CAP + 50);
    const chats = ids('c', CHATS_CAP + 50);
    const profiles: Record<string, any> = {};
    [...following.map((e) => e.id), ...followers, ...chats].forEach((id) => { profiles[id] = p; });
    const pins = assemblePins({ userId: 'me', following, followers, chats, profiles, blocked: new Set() }, rngOf(3));
    expect(pins.length).toBe(FOLLOWING_CAP + FOLLOWERS_CAP + CHATS_CAP);
    expect(pins.length).toBeLessThanOrEqual(MAX_PINS);
    expect(pins.some((x) => x.id === `f${FOLLOWING_CAP}`)).toBe(false);
    expect(pins.some((x) => x.id === `f${FOLLOWING_CAP - 1}`)).toBe(true);
    expect(new Set(pins.map((x) => x.id)).size).toBe(pins.length);
  });

  test('same accounts in all groups -> one pin with all badges', () => {
    const ids = Array.from({ length: 10 }, (_, i) => `u${i}`);
    const profiles = Object.fromEntries(ids.map((id) => [id, p]));
    const pins = assemblePins({
      userId: 'me', following: ids.map((id) => ({ id, isStore: false })), followers: ids, chats: ids, profiles, blocked: new Set(),
    }, rngOf(4));
    expect(pins).toHaveLength(10);
    for (const x of pins) expect(x.badges).toEqual(['following', 'follower', 'chat']);
  });
});

describe('storage: inline vs chunks', () => {
  const pin = (i: number, extra = 0): WorldMapPin => ({
    id: `user-${i}`, kind: 'person', lat: 1, lng: 2, name: 'N'.repeat(20 + extra),
    photo: `https://firebasestorage.googleapis.com/v0/b/x/o/${'p'.repeat(150)}`, badges: ['following'],
    country: 'Italy', city: 'Rome', disc: 'approximate', isOnlineAtBuild: false,
  });

  test('a full network (900 pins) fits one doc', () => {
    const pins = Array.from({ length: 900 }, (_, i) => pin(i));
    const { inline, chunks } = splitPins(pins);
    expect(chunks).toHaveLength(0);
    expect(inline).toHaveLength(900);
    expect(Buffer.byteLength(JSON.stringify(inline))).toBeLessThan(INLINE_BUDGET_BYTES);
  });

  test('oversized pins are chunked, order kept, each chunk < budget', () => {
    const pins = Array.from({ length: MAX_PINS }, (_, i) => pin(i, 900));
    const { inline, chunks } = splitPins(pins);
    expect(inline).toHaveLength(0);
    expect(chunks.length).toBeGreaterThan(1);
    expect(chunks.flat().map((x) => x.id)).toEqual(pins.map((x) => x.id));
    for (const c of chunks) expect(Buffer.byteLength(JSON.stringify(c))).toBeLessThanOrEqual(700_000);
  });

  test('snapshotWrites: chunks tagged with the build id, stale chunks deleted', () => {
    const big = Array.from({ length: MAX_PINS }, (_, i) => pin(i, 900));
    const counts = { pins: big.length, people: big.length, businesses: 0, following: 0, followers: 0, chats: 0 };
    const w = snapshotWrites(big, counts, 1_000, 'b1', 9);
    expect(w.main.pins).toEqual([]);
    expect(w.main.chunkCount).toBe(w.chunks.length);
    expect(w.main.schema).toBe(SNAPSHOT_SCHEMA);
    for (const c of w.chunks) expect(c.buildId).toBe('b1');
    expect(w.deleteChunks).toEqual(Array.from({ length: 9 - w.chunks.length }, (_, i) => w.chunks.length + i));

    const small = snapshotWrites(big.slice(0, 5), counts, 1_000, 'b2', 3);
    expect(small.main.pins).toHaveLength(5);
    expect(small.main.chunkCount).toBe(0);
    expect(small.deleteChunks).toEqual([0, 1, 2]);
    expect(toMillis(small.main.refreshAfter)! - toMillis(small.main.builtAt)!).toBe(55 * 60 * 1000);
  });
});

describe('buildSnapshot (fake reader)', () => {
  test('reads once, removes self + blocked before the profile read', async () => {
    const asked: string[][] = [];
    const reader: SnapshotReader = {
      blocked: async () => new Set(['x']),
      following: async () => [{ id: 'a', isStore: false }, { id: 'x', isStore: false }],
      followers: async () => ['me', 'b'],
      chats: async () => ['a'],
      profiles: async (ids) => {
        asked.push(ids);
        return { a: FIXTURE.profiles.p_default, b: FIXTURE.profiles.p_country };
      },
    };
    const r = await buildSnapshot(reader, 'me', rngOf(1));
    expect(asked).toHaveLength(1);
    expect(new Set(asked[0])).toEqual(new Set(['a', 'b']));
    expect(r.pins.map((p) => [p.id, p.badges])).toEqual([['a', ['following', 'chat']], ['b', ['follower']]]);
    expect(r.counts).toEqual({ pins: 2, people: 2, businesses: 0, following: 2, followers: 2, chats: 1 });
  });
});

describe('open decision + marker', () => {
  const now = 10 * SNAPSHOT_TTL_MS;
  const ts = (ms: number) => ({ _ts: ms });
  test('fresh / stale / missing / rate-limited', () => {
    expect(decideOpen(undefined, now)).toBe('build');
    expect(decideOpen({ schema: SNAPSHOT_SCHEMA, builtAt: ts(now - 1000), pins: [] }, now)).toBe('fresh');
    expect(decideOpen({ schema: SNAPSHOT_SCHEMA, builtAt: ts(now - SNAPSHOT_TTL_MS), pins: [] }, now)).toBe('build');
    expect(decideOpen({ schema: 0, builtAt: ts(now), pins: [] }, now)).toBe('build');
    expect(decideOpen({
      schema: SNAPSHOT_SCHEMA, builtAt: ts(now - 2 * SNAPSHOT_TTL_MS), pins: [], lastOnDemandAt: ts(now - 1000),
    }, now)).toBe('stale-rate-limited');
    expect(decideOpen({
      schema: SNAPSHOT_SCHEMA, builtAt: ts(now - 2 * SNAPSHOT_TTL_MS), pins: [],
      lastOnDemandAt: ts(now - ON_DEMAND_MIN_INTERVAL_MS),
    }, now)).toBe('build');
  });
  test('marker throttled to once an hour while active', () => {
    expect(markerDue(undefined, now)).toBe(true);
    expect(markerDue({ active: true, lastOpenedAt: ts(now - 1000) }, now)).toBe(false);
    expect(markerDue({ active: false, lastOpenedAt: ts(now - 1000) }, now)).toBe(true);
    expect(markerDue({ active: true, lastOpenedAt: ts(now - 3_600_000) }, now)).toBe(true);
  });
});

describe('dispatchDue (hourly fan-out)', () => {
  test('pages all due docs, deactivates idle users, publishes batches', async () => {
    const now = 100 * ACTIVE_WINDOW_MS;
    const docs = Array.from({ length: 2350 }, (_, i) => ({
      uid: `u${String(i).padStart(5, '0')}`,
      lastOpenedAtMs: i % 10 === 0 ? now - ACTIVE_WINDOW_MS - 1 : now - 1000,
      refreshAfterMs: now - 10_000 + i,
    }));
    const published: string[][] = [];
    const deactivated: string[] = [];
    const r = await dispatchDue({
      queryDue: async (_due, cursor, limit) => {
        const start = cursor ? docs.findIndex((d) => d.uid === cursor.uid) + 1 : 0;
        return docs.slice(start, start + limit);
      },
      deactivate: async (u) => { deactivated.push(...u); },
      publish: async (u) => { published.push(u); },
    }, now, { pageSize: 500, batchSize: 100 });
    expect(r.scanned).toBe(2350);
    expect(r.deactivated).toBe(235);
    expect(r.dispatched).toBe(2115);
    expect(published.every((b) => b.length <= 100)).toBe(true);
    expect(new Set(published.flat()).size).toBe(2115);
    expect(deactivated.every((u) => Number(u.slice(1)) % 10 === 0)).toBe(true);
    expect(r.truncated).toBe(false);
  });

  test('bounded per run (truncated, rest left for the next run)', async () => {
    const docs = Array.from({ length: 50 }, (_, i) => ({ uid: `u${i}`, lastOpenedAtMs: 0, refreshAfterMs: i }));
    const published: string[][] = [];
    const r = await dispatchDue({
      queryDue: async (_d, cursor, limit) => {
        const start = cursor ? docs.findIndex((d) => d.uid === cursor.uid) + 1 : 0;
        return docs.slice(start, start + limit);
      },
      deactivate: async () => undefined,
      publish: async (u) => { published.push(u); },
    }, 1000, { pageSize: 10, batchSize: 7, maxUsers: 20 });
    expect(r.scanned).toBe(20);
    expect(r.truncated).toBe(true);
    expect(published.flat()).toEqual(docs.slice(0, 20).map((d) => d.uid));
  });
});

describe('processBatch (worker)', () => {
  test('builds active due docs; skips inactive / not due / missing; failures back off', async () => {
    const now = 1_000_000_000;
    const docs: Record<string, any> = {
      a: { active: true, refreshAfter: { _ts: now - 1 }, chunkCount: 2 },
      b: { active: false, refreshAfter: { _ts: now - 1 } },
      c: { active: true, refreshAfter: { _ts: now + 3_600_000 } },
      d: { active: true, refreshAfter: { _ts: now - 1 } },
    };
    const built: [string, number][] = [];
    const failed: string[] = [];
    const r = await processBatch(['a', 'b', 'c', 'd', 'e', 'a', 'bad/id'], {
      load: async (u) => docs[u],
      build: async (u, prev) => {
        if (u === 'd') throw new Error('boom');
        built.push([u, prev]);
      },
      markFailed: async (u) => { failed.push(u); },
    }, now, 3);
    expect(built).toEqual([['a', 2]]);
    expect(failed).toEqual(['d']);
    expect(r).toEqual({ built: 1, skipped: 3, failed: 1 });
  });
});

test('country centroids are identical to the Dart table', () => {
  const dart = fs.readFileSync(path.join(__dirname, '..', '..', '..',
    'lib', 'features', 'globe_explore', 'data', 'country_centroids.dart'), 'utf8');
  const body = dart.split('const Map<String, List<double>> countryCentroids = {')[1].split('};')[0];
  const re = /^\s*(['"])(.+?)\1:\s*\[\s*(-?[\d.]+),\s*(-?[\d.]+)\s*\],?\s*$/gm;
  const parsed: Record<string, [number, number]> = {};
  let m: RegExpExecArray | null;
  while ((m = re.exec(body))) parsed[m[2]] = [Number(m[3]), Number(m[4])];
  expect(Object.keys(parsed).length).toBeGreaterThan(150);
  expect(Object.fromEntries(Object.entries(COUNTRY_CENTROIDS).map(([k, v]) => [k, [v[0], v[1]]]))).toEqual(parsed);
});
