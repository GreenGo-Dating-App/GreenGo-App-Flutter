/**
 * Private profile split (security audit C-07 / C-10, plan P1-4).
 *
 * `profiles/{uid}` is readable by every signed-in user (discovery). It used to
 * carry exact coordinates (raw lat/lng + a 9-char geohash, ~5 m), the date of
 * birth, orientation, email, phone, the ID-selfie download URL, private photo
 * URLs and ID-derived age-verification data. This module moves that data to
 * the owner/admin-only `profiles_private/{uid}` and publishes COARSE
 * replacements on the public profile:
 *
 *   geohash5        5-char geohash (cell ~4.9 x 4.9 km) of the discoverable
 *                   location: the app queries it nearest-first.
 *   approxLocation  {lat, lng}: centre of that cell plus a stable per-user
 *                   offset (<= 1.5 km, HMAC of the uid), so map pins don't
 *                   stack on cell centres. It moves only when the cell does.
 *   age             integer years (UTC), from dateOfBirth.
 *
 * Two triggers keep both sides consistent without loops:
 *
 *   mirrorPrivateProfileFields   profiles/{uid} written (old app versions
 *     still write sensitive fields there): copies each sensitive field that
 *     CHANGED in this event into profiles_private, then recomputes the coarse
 *     fields. Writes that touch none of the watched fields (presence,
 *     lastSeen, counters... profiles is a hot collection) exit without a
 *     single read.
 *   syncCoarseFromPrivateProfile profiles_private/{uid} written (new app
 *     versions write sensitive fields ONLY there): recomputes the coarse
 *     fields on the public profile. Never copies sensitive data to public.
 *
 * Why there is no loop: each trigger writes only values that differ from the
 * stored ones. The public write made by either trigger touches only coarse
 * fields, which mirrorPrivateProfileFields does not watch; the private write
 * made by mirrorPrivateProfileFields re-runs syncCoarse..., which recomputes
 * the very values just written and therefore writes nothing.
 *
 * Out-of-order delivery: the mirror copies the CURRENT public value (read in
 * the transaction), not the event's value, so a late event can never roll the
 * private copy back. A field that disappears from the public doc is NOT
 * propagated (the new app writes `location` without lat/lng; the strip script
 * deletes them), so private data is never lost that way.
 *
 * Sensitive public fields are NOT deleted here: old app versions still read
 * and write them. scripts/strip-public-sensitive-fields.ts removes them after
 * app_config/version.minVersion forces the new app.
 */

import { createHmac } from 'crypto';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

export const PRIVATE_PROFILES = 'profiles_private';

/** Public path -> private path of every sensitive field. */
export const SENSITIVE_FIELDS: ReadonlyArray<{ pub: string; priv: string }> = [
  { pub: 'location.latitude', priv: 'location.latitude' },
  { pub: 'location.longitude', priv: 'location.longitude' },
  { pub: 'travelerLocation.latitude', priv: 'travelerLocation.latitude' },
  { pub: 'travelerLocation.longitude', priv: 'travelerLocation.longitude' },
  { pub: 'geohash', priv: 'geohash' },
  { pub: 'dateOfBirth', priv: 'dateOfBirth' },
  { pub: 'sexualOrientation', priv: 'sexualOrientation' },
  { pub: 'email', priv: 'email' },
  { pub: 'verificationPhone', priv: 'verificationPhone' },
  { pub: 'verificationPhotoUrl', priv: 'verificationPhotoUrl' },
  { pub: 'privatePhotoUrls', priv: 'privatePhotoUrls' },
  { pub: 'ageVerification.documentHash', priv: 'ageVerification.documentHash' },
  { pub: 'ageVerification.documentDateOfBirth', priv: 'ageVerification.documentDateOfBirth' },
];

/** Public fields that change the coarse result without being sensitive. */
export const COARSE_INPUT_FIELDS = ['isTraveler', 'travelerExpiry'] as const;

/** Private fields that change the coarse result. */
export const PRIVATE_COARSE_INPUTS = [
  'location.latitude', 'location.longitude',
  'travelerLocation.latitude', 'travelerLocation.longitude',
  'dateOfBirth',
] as const;

export const COARSE_FIELDS = ['geohash5', 'approxLocation', 'age'] as const;

export const APPROX_PRECISION = 5;
/** Max jitter radius in metres. 1495 (not 1500) leaves room for rounding. */
export const JITTER_MAX_M = 1495;
const DEFAULT_JITTER_KEY = 'greengo-approx-location-v1';
let warnedKey = false;

export function jitterKey(): string {
  const k = process.env.PROFILE_LOCATION_JITTER_KEY;
  if (k && k.length >= 16) return k;
  if (!warnedKey) {
    warnedKey = true;
    console.warn('privateProfile: PROFILE_LOCATION_JITTER_KEY not set; using the built-in fallback key');
  }
  return DEFAULT_JITTER_KEY;
}

// ---------------------------------------------------------------------------
// Generic helpers
// ---------------------------------------------------------------------------

export function getPath(obj: any, path: string): any {
  let cur = obj;
  for (const k of path.split('.')) {
    if (cur === null || cur === undefined || typeof cur !== 'object') return undefined;
    cur = cur[k];
  }
  return cur;
}

/** Sets a dotted path in a plain object (creating maps). Returns obj. */
export function setPath(obj: Record<string, any>, path: string, value: any): Record<string, any> {
  const keys = path.split('.');
  let cur = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    const k = keys[i];
    if (cur[k] === null || typeof cur[k] !== 'object' || Array.isArray(cur[k]) || isTimestampLike(cur[k])) {
      cur[k] = {};
    }
    cur = cur[k];
  }
  cur[keys[keys.length - 1]] = value;
  return obj;
}

function isTimestampLike(v: any): boolean {
  return !!v && typeof v === 'object' && typeof v.toDate === 'function';
}

/** Structural equality that understands Timestamps/GeoPoints (isEqual). */
export function valuesEqual(a: any, b: any): boolean {
  if (a === b) return true;
  if (a === undefined || b === undefined || a === null || b === null) return false;
  if (typeof a !== typeof b) return false;
  if (typeof a === 'number') return Number.isNaN(a) && Number.isNaN(b);
  if (typeof a !== 'object') return false;
  if (typeof a.isEqual === 'function' && typeof b.isEqual === 'function') {
    try { return a.isEqual(b); } catch { return false; }
  }
  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
    return a.every((x, i) => valuesEqual(x, b[i]));
  }
  const ka = Object.keys(a).filter((k) => a[k] !== undefined);
  const kb = Object.keys(b).filter((k) => b[k] !== undefined);
  if (ka.length !== kb.length) return false;
  return ka.every((k) => valuesEqual(a[k], b[k]));
}

export function toDate(v: unknown): Date | null {
  if (!v) return null;
  if (v instanceof Date) return v;
  const o = v as any;
  if (typeof o?.toDate === 'function') return o.toDate();
  const secs = o?._seconds ?? o?.seconds;
  if (typeof secs === 'number') return new Date(secs * 1000);
  if (typeof v === 'string') {
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

export function validCoords(lat: unknown, lng: unknown): boolean {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    Math.abs(lat) <= 90 &&
    Math.abs(lng) <= 180 &&
    !(lat === 0 && lng === 0)
  );
}

// ---------------------------------------------------------------------------
// Geohash (standard base32, longitude on even bits; matches
// lib/core/utils/geo_query.dart and external_events/geohash.ts)
// ---------------------------------------------------------------------------

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

export function geohashEncode(lat: number, lng: number, precision = 9): string {
  let idx = 0;
  let bit = 0;
  let evenBit = true;
  let out = '';
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  while (out.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) { idx = idx * 2 + 1; lngMin = mid; } else { idx = idx * 2; lngMax = mid; }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) { idx = idx * 2 + 1; latMin = mid; } else { idx = idx * 2; latMax = mid; }
    }
    evenBit = !evenBit;
    if (++bit === 5) { out += BASE32[idx]; bit = 0; idx = 0; }
  }
  return out;
}

/** Bounding box of a geohash cell. */
export function geohashBounds(hash: string): { latMin: number; latMax: number; lngMin: number; lngMax: number } {
  let evenBit = true;
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  for (const ch of hash) {
    const v = BASE32.indexOf(ch);
    if (v < 0) throw new Error(`invalid geohash char ${ch}`);
    for (let n = 4; n >= 0; n--) {
      const b = (v >> n) & 1;
      if (evenBit) {
        const mid = (lngMin + lngMax) / 2;
        if (b) lngMin = mid; else lngMax = mid;
      } else {
        const mid = (latMin + latMax) / 2;
        if (b) latMin = mid; else latMax = mid;
      }
      evenBit = !evenBit;
    }
  }
  return { latMin, latMax, lngMin, lngMax };
}

// ---------------------------------------------------------------------------
// Coarse values
// ---------------------------------------------------------------------------

const M_PER_DEG_LAT = 111_320;

/** Stable per-user offset (metres north / east), uniform in a disk. */
export function jitterOffsetMeters(uid: string, key = jitterKey()): { north: number; east: number } {
  const h = createHmac('sha256', key).update(`approx-location:${uid}`).digest();
  const u1 = h.readUInt32BE(0) / 0x1_0000_0000;
  const u2 = h.readUInt32BE(4) / 0x1_0000_0000;
  const r = JITTER_MAX_M * Math.sqrt(u2);
  const theta = 2 * Math.PI * u1;
  return { north: r * Math.cos(theta), east: r * Math.sin(theta) };
}

const round5 = (x: number) => Math.round(x * 1e5) / 1e5;

/** Cell centre of the precision-5 geohash of (lat, lng) + the uid offset. */
export function approxLocationFor(uid: string, lat: number, lng: number, key?: string): {
  geohash5: string; approxLocation: { lat: number; lng: number };
} {
  const geohash5 = geohashEncode(lat, lng, APPROX_PRECISION);
  const b = geohashBounds(geohash5);
  const cLat = (b.latMin + b.latMax) / 2;
  const cLng = (b.lngMin + b.lngMax) / 2;
  const off = jitterOffsetMeters(uid, key);
  let aLat = cLat + off.north / M_PER_DEG_LAT;
  aLat = Math.max(-89.99999, Math.min(89.99999, aLat));
  const cos = Math.max(Math.cos((cLat * Math.PI) / 180), 1e-6);
  let aLng = cLng + off.east / (M_PER_DEG_LAT * cos);
  if (aLng > 180) aLng -= 360;
  if (aLng < -180) aLng += 360;
  return { geohash5, approxLocation: { lat: round5(aLat), lng: round5(aLng) } };
}

/** Whole years between dob and now, in UTC. Null for implausible input. */
export function ageFrom(dob: Date | null, now: Date = new Date()): number | null {
  if (!dob || Number.isNaN(dob.getTime())) return null;
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const m = now.getUTCMonth() - dob.getUTCMonth();
  if (m < 0 || (m === 0 && now.getUTCDate() < dob.getUTCDate())) age--;
  if (age < 0 || age > 130) return null;
  return age;
}

/** 'MM-DD' (UTC) of a date of birth, or null. */
export function birthMonthDayOf(dob: Date | null): string | null {
  if (!dob || Number.isNaN(dob.getTime())) return null;
  const mm = String(dob.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(dob.getUTCDate()).padStart(2, '0');
  return `${mm}-${dd}`;
}

function pair(m: any): [number, number] | null {
  if (!m || typeof m !== 'object') return null;
  return validCoords(m.latitude, m.longitude) ? [m.latitude, m.longitude] : null;
}

/**
 * Discoverable exact coordinates: the travel location while traveller mode
 * is active, else home. Private copy first, legacy public copy second.
 * Same rules as discovery/profileGeohash.ts discoverableGeohash.
 */
export function discoverableCoords(pub: any, priv: any, now: Date = new Date()): [number, number] | null {
  const expiry = toDate(pub?.travelerExpiry);
  const travelling = pub?.isTraveler === true && !!expiry && expiry.getTime() > now.getTime();
  if (travelling) {
    const t = pair(priv?.travelerLocation) ?? pair(pub?.travelerLocation);
    if (t) return t;
  }
  return pair(priv?.location) ?? pair(pub?.location);
}

export function dateOfBirthOf(pub: any, priv: any): Date | null {
  return toDate(priv?.dateOfBirth) ?? toDate(pub?.dateOfBirth);
}

export interface Coarse {
  geohash5: string | null;
  approxLocation: { lat: number; lng: number } | null;
  age: number | null;
}

export function computeCoarse(uid: string, pub: any, priv: any, now: Date = new Date(), key?: string): Coarse {
  const c = discoverableCoords(pub, priv, now);
  const a = c ? approxLocationFor(uid, c[0], c[1], key) : null;
  return {
    geohash5: a?.geohash5 ?? null,
    approxLocation: a?.approxLocation ?? null,
    age: ageFrom(dateOfBirthOf(pub, priv), now),
  };
}

/** Field-path update for the public doc: only coarse values that differ. */
export function coarseUpdates(pub: any, coarse: Coarse): Record<string, any> {
  const out: Record<string, any> = {};
  for (const f of COARSE_FIELDS) {
    const want = coarse[f];
    const have = pub?.[f];
    if (want === null) {
      if (have !== undefined) out[f] = admin.firestore.FieldValue.delete();
    } else if (!valuesEqual(want, have)) {
      out[f] = want;
    }
  }
  return out;
}

/** Sensitive public paths whose value differs between two snapshots. */
export function changedSensitive(before: any, after: any): Array<{ pub: string; priv: string }> {
  return SENSITIVE_FIELDS.filter((f) => !valuesEqual(getPath(before, f.pub), getPath(after, f.pub)));
}

export function coarseInputsChanged(before: any, after: any): boolean {
  return COARSE_INPUT_FIELDS.some((f) => !valuesEqual(before?.[f], after?.[f]));
}

/**
 * Private-side updates (dotted paths) that copy the CURRENT public value of
 * [fields] where it is present and differs. `undefined` (absent) is never
 * copied; null is. With [fillMissingOnly] a field the private doc already
 * has is left alone: the backfill and strip script use that, because a user
 * on the new app writes ONLY to private, so its public copy may be stale.
 */
export function privateCopyUpdates(
  pub: any,
  priv: any,
  fields: ReadonlyArray<{ pub: string; priv: string }>,
  fillMissingOnly = false,
): Record<string, any> {
  const out: Record<string, any> = {};
  for (const f of fields) {
    const cur = getPath(pub, f.pub);
    if (cur === undefined) continue;
    const have = getPath(priv, f.priv);
    if (fillMissingOnly && have !== undefined) continue;
    if (!valuesEqual(cur, have)) out[f.priv] = cur;
  }
  return out;
}

/** Applies dotted-path updates to a deep copy of [base]. */
export function applyPaths(base: any, updates: Record<string, any>): Record<string, any> {
  const copy = deepCopy(base ?? {});
  for (const [p, v] of Object.entries(updates)) setPath(copy, p, v);
  return copy;
}

function deepCopy(v: any): any {
  if (v === null || typeof v !== 'object' || isTimestampLike(v) || typeof v.isEqual === 'function') return v;
  if (Array.isArray(v)) return v.map(deepCopy);
  const o: Record<string, any> = {};
  for (const [k, x] of Object.entries(v)) o[k] = deepCopy(x);
  return o;
}

/** Builds a nested object from dotted-path updates (for set(..., {merge})). */
export function nestedFromPaths(updates: Record<string, any>): Record<string, any> {
  const o: Record<string, any> = {};
  for (const [p, v] of Object.entries(updates)) setPath(o, p, v);
  return o;
}

// ---------------------------------------------------------------------------
// Transactional sync (shared by both triggers and the backfill)
// ---------------------------------------------------------------------------

export interface SyncResult {
  privateWrites: number;
  publicWrites: number;
  privateFields: string[];
  publicFields: string[];
}

/**
 * One transaction: copy [copyFields] (current public value) into private,
 * keep private.birthMonthDay in step, and update the public coarse fields.
 * Writes only what differs. Missing public doc -> no-op.
 */
export async function syncProfile(
  uid: string,
  copyFields: ReadonlyArray<{ pub: string; priv: string }>,
  opts: { firestore?: admin.firestore.Firestore; now?: Date; dryRun?: boolean; fillMissingOnly?: boolean } = {},
): Promise<SyncResult> {
  const fs = opts.firestore ?? admin.firestore();
  const pubRef = fs.collection('profiles').doc(uid);
  const privRef = fs.collection(PRIVATE_PROFILES).doc(uid);
  return fs.runTransaction(async (tx) => {
    const [pubSnap, privSnap] = await tx.getAll(pubRef, privRef);
    const res: SyncResult = { privateWrites: 0, publicWrites: 0, privateFields: [], publicFields: [] };
    if (!pubSnap.exists) return res;
    const pub = pubSnap.data() ?? {};
    const priv = privSnap.exists ? privSnap.data() ?? {} : {};

    const privUpd = privateCopyUpdates(pub, priv, copyFields, opts.fillMissingOnly === true);
    const merged = applyPaths(priv, privUpd);
    const bmd = birthMonthDayOf(dateOfBirthOf(pub, merged));
    if (bmd !== null && merged.birthMonthDay !== bmd) privUpd.birthMonthDay = bmd;

    const pubUpd = coarseUpdates(pub, computeCoarse(uid, pub, merged, opts.now ?? new Date()));

    res.privateFields = Object.keys(privUpd);
    res.publicFields = Object.keys(pubUpd);
    if (opts.dryRun) {
      res.privateWrites = res.privateFields.length ? 1 : 0;
      res.publicWrites = res.publicFields.length ? 1 : 0;
      return res;
    }
    if (res.privateFields.length) {
      // set+merge with a nested object: creates the doc if missing and never
      // touches fields not named here (owner edits survive).
      tx.set(privRef, { ...nestedFromPaths(privUpd), _mirroredAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      res.privateWrites = 1;
    }
    if (res.publicFields.length) {
      tx.update(pubRef, pubUpd);
      res.publicWrites = 1;
    }
    return res;
  });
}

/** Handler body of mirrorPrivateProfileFields (exported for tests). */
export async function handlePublicProfileWrite(
  uid: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  opts: { firestore?: admin.firestore.Firestore; now?: Date } = {},
): Promise<SyncResult | 'deleted' | 'skipped'> {
  const fs = opts.firestore ?? admin.firestore();
  if (!after) {
    if (before) {
      await fs.collection(PRIVATE_PROFILES).doc(uid).delete();
      return 'deleted';
    }
    return 'skipped';
  }
  const changed = changedSensitive(before, after);
  if (changed.length === 0 && before && !coarseInputsChanged(before, after)) return 'skipped';
  // A (re)created public doc: fill whatever private lacks, never overwrite.
  return before
    ? syncProfile(uid, changed, opts)
    : syncProfile(uid, SENSITIVE_FIELDS, { ...opts, fillMissingOnly: true });
}

/** Handler body of syncCoarseFromPrivateProfile (exported for tests). */
export async function handlePrivateProfileWrite(
  uid: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  opts: { firestore?: admin.firestore.Firestore; now?: Date } = {},
): Promise<SyncResult | 'skipped'> {
  if (!after) return 'skipped';
  if (before && !PRIVATE_COARSE_INPUTS.some((p) => !valuesEqual(getPath(before, p), getPath(after, p)))) {
    return 'skipped';
  }
  return syncProfile(uid, [], opts);
}
