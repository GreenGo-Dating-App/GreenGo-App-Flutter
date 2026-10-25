/**
 * Searchable / filterable STORE fields on the follower's mirror edge, so the
 * own-profile "Stores" list can be name-searched AND filtered by category and
 * place across ALL followed stores with one bounded, indexed query per page.
 *
 * Fields on `user_business_following/{follower}/businesses/{store}` (written
 * ONLY by server code; the rules refuse them from clients), present only while
 * the followee is a business account (`profiles.isBusiness == true`):
 *   - `storeNameLower`  normalized storefront name (businessName, else the
 *                       display name / nickname), see normalizeFollowName
 *   - `storeCategory`   profiles.businessCategory, raw canonical value ('' = none)
 *   - `storeCountry`    profiles.businessAddress.country, the stored value as-is
 *                       ('' = no usable storefront address)
 *   - `storeCityLower`  normalized businessAddress.city ('' when no country)
 * The personal `location` is private and never used.
 *
 * App query (FollowService.followedStoresPage with a search / filter):
 *   [storeCategory ==] [storeCountry == [storeCityLower ==]]
 *   orderBy storeNameLower [startAt q, endAt q+''] limit 30, cursor paged.
 * Composite indexes (collection scope, `businesses`) in firestore.indexes.json;
 * a city filter is only offered together with its country.
 *
 * Place filter options: per-follower counters of the places of the followed
 * stores, OWNER-ONLY to read, never client-written:
 *   - `user_store_places/{uid}/countries/{id}` {country, n}
 *   - `user_store_places/{uid}/cities/{id}`    {country, city, cityLower, n}
 * Moved EXACTLY ONCE together with the mirror fields: every change runs in a
 * transaction that reads the mirror (so a retried / concurrent writer sees the
 * value already there), and a facet that drops to 0 is deleted in the same
 * transaction (no leftovers, also for deleted accounts).
 *
 * Writers:
 *   1. onUserFollowCreated → [stampStoreFields] (fast path: no read and no
 *      write for a followee that is not a business).
 *   2. Store fields changed on the business profile →
 *      [enqueueFollowStoreJobIfChanged] (from mirrorPrivateProfileFields; an
 *      in-memory compare, no read unless a store field changed) →
 *      `follow_store_jobs/{uid}` → onFollowStoreJob runs [followStoreRound]:
 *      bounded pages of the business's followers (<= STORE_PAGE mirrors per
 *      transaction, <= 5 writes each), re-firing itself until done. A newer
 *      change overwrites the job (new `gen`) and the older run stops.
 *   3. Mirror deleted (unfollow, cleanup) → onFollowedStoreRemoved →
 *      [unplaceDeletedMirror] (event-id marker: a retried delete event never
 *      decrements twice; no read for a mirror without a place).
 *   4. scripts/backfill-store-fields.ts for mirrors that predate this.
 */

import { createHash } from 'crypto';
import { followersCol, followingCol, normalizeFollowName, profileFollowName } from './followNames';
import { UNCOUNT_MARKERS } from './followCounters';

/* eslint-disable @typescript-eslint/no-explicit-any */

export const STORE_NAME_FIELD = 'storeNameLower';
export const STORE_CATEGORY_FIELD = 'storeCategory';
export const STORE_COUNTRY_FIELD = 'storeCountry';
export const STORE_CITY_FIELD = 'storeCityLower';
export const STORE_FIELDS = [
  STORE_NAME_FIELD,
  STORE_CATEGORY_FIELD,
  STORE_COUNTRY_FIELD,
  STORE_CITY_FIELD,
] as const;

export const FOLLOW_STORE_JOBS = 'follow_store_jobs';
export const STORE_PLACES = 'user_store_places';

/**
 * Mirrors per fan-out transaction: each changed mirror costs <= 5 writes
 * (mirror + country/city -1/+1), so 80 stay under the 500-write limit.
 */
export const STORE_PAGE = 80;

/** Stored strings are capped (category / country / city never need more). */
const MAX_LEN = 80;

/** `FieldValue.increment` / `FieldValue.delete` (fakes in tests). */
export interface StoreFieldValues {
  increment: (n: number) => unknown;
  delete: () => unknown;
}

/** What a business contributes to its followers' mirrors. */
export interface StoreFields {
  name: string;
  category: string;
  country: string;
  cityLower: string;
  /** City as typed (facet label only; not on the mirror). */
  city: string;
}

function clean(v: unknown): string {
  if (typeof v !== 'string') return '';
  return Array.from(v.replace(/\s+/g, ' ').trim()).slice(0, MAX_LEN).join('').trim();
}

/**
 * The storefront address the app shows (BusinessAddress.fromMap): numeric,
 * in-range, non-(0,0) coordinates and a non-empty address line.
 */
function usableAddress(a: any): boolean {
  if (!a || typeof a !== 'object') return false;
  const { latitude: lat, longitude: lng } = a;
  if (typeof lat !== 'number' || typeof lng !== 'number') return false;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180 || (lat === 0 && lng === 0)) return false;
  return clean(a.address) !== '';
}

/** The store fields of a profile; null when it is not a business account. */
export function storeFieldsOf(p: Record<string, any> | undefined | null): StoreFields | null {
  if (!p || p.isBusiness !== true) return null;
  const name = normalizeFollowName(p.businessName) || profileFollowName(p);
  const a = usableAddress(p.businessAddress) ? p.businessAddress : null;
  const country = clean(a?.country);
  const city = country ? clean(a?.city) : '';
  return {
    name,
    category: clean(p.businessCategory),
    country,
    cityLower: normalizeFollowName(city),
    city,
  };
}

/** Same mirror fields (the city LABEL alone never triggers a fan-out). */
export function sameStoreFields(a: StoreFields | null, b: StoreFields | null): boolean {
  if (!a || !b) return a === b;
  return a.name === b.name && a.category === b.category &&
    a.country === b.country && a.cityLower === b.cityLower;
}

/** True when the mirror already carries exactly [next] (null = no store fields). */
function mirrorHas(data: Record<string, any> | undefined, next: StoreFields | null): boolean {
  if (!next) return STORE_FIELDS.every((f) => data?.[f] === undefined);
  return data?.[STORE_NAME_FIELD] === next.name &&
    data?.[STORE_CATEGORY_FIELD] === next.category &&
    data?.[STORE_COUNTRY_FIELD] === next.country &&
    data?.[STORE_CITY_FIELD] === next.cityLower;
}

interface Place { country: string; cityLower: string; city: string }

/** The place a mirror is counted under (null = none). */
function placeOfMirror(data: Record<string, any> | undefined): Place | null {
  const country = data?.[STORE_COUNTRY_FIELD];
  if (typeof country !== 'string' || !country) return null;
  const c = data?.[STORE_CITY_FIELD];
  return { country, cityLower: typeof c === 'string' ? c : '', city: '' };
}

function placeOfFields(f: StoreFields | null): Place | null {
  return f && f.country ? { country: f.country, cityLower: f.cityLower, city: f.city } : null;
}

/** Deterministic, path-safe facet id. */
export function placeId(...parts: string[]): string {
  return createHash('sha1').update(parts.join('\u0000')).digest('hex').slice(0, 24);
}

export function countryFacetRef(db: any, uid: string, country: string) {
  return db.collection(STORE_PLACES).doc(uid).collection('countries').doc(placeId(country));
}
export function cityFacetRef(db: any, uid: string, country: string, cityLower: string) {
  return db.collection(STORE_PLACES).doc(uid).collection('cities').doc(placeId(country, cityLower));
}

interface FacetDelta { ref: any; delta: number; init: Record<string, unknown> }

/** Country / city facet moves for one follower whose store moved old → next. */
function facetDeltas(db: any, uid: string, old: Place | null, next: Place | null): FacetDelta[] {
  const out: FacetDelta[] = [];
  const oldCountry = old?.country ?? '';
  const newCountry = next?.country ?? '';
  if (oldCountry !== newCountry) {
    if (oldCountry) out.push({ ref: countryFacetRef(db, uid, oldCountry), delta: -1, init: {} });
    if (newCountry) {
      out.push({ ref: countryFacetRef(db, uid, newCountry), delta: 1, init: { country: newCountry } });
    }
  }
  const oldCity = old && old.cityLower ? `${old.country}\u0000${old.cityLower}` : '';
  const newCity = next && next.cityLower ? `${next.country}\u0000${next.cityLower}` : '';
  if (oldCity !== newCity) {
    if (oldCity) out.push({ ref: cityFacetRef(db, uid, old!.country, old!.cityLower), delta: -1, init: {} });
    if (newCity) {
      out.push({
        ref: cityFacetRef(db, uid, next!.country, next!.cityLower),
        delta: 1,
        init: { country: next!.country, city: next!.city || next!.cityLower, cityLower: next!.cityLower },
      });
    }
  }
  return out;
}

/**
 * Inside ONE transaction (mirrors already read through it): write the
 * changed mirror fields and move the facets. Decremented facets are read
 * here (reads before writes) so one that reaches 0 is deleted, never left
 * at 0 / negative. Returns how many mirrors changed.
 */
async function applyInTxn(
  txn: any,
  db: any,
  fv: StoreFieldValues,
  items: Array<{ followerId: string; mirror: any; next: StoreFields | null }>,
): Promise<number> {
  const writes: Array<{ ref: any; patch: Record<string, unknown> }> = [];
  const deltas = new Map<string, FacetDelta>();
  for (const { followerId, mirror, next } of items) {
    // Never create: a mirror deleted meanwhile (unfollow) is skipped.
    if (!mirror.exists) continue;
    const data = mirror.data();
    if (mirrorHas(data, next)) continue;
    writes.push({
      ref: mirror.ref,
      patch: next
        ? {
          [STORE_NAME_FIELD]: next.name,
          [STORE_CATEGORY_FIELD]: next.category,
          [STORE_COUNTRY_FIELD]: next.country,
          [STORE_CITY_FIELD]: next.cityLower,
        }
        : Object.fromEntries(STORE_FIELDS.map((f) => [f, fv.delete()])),
    });
    for (const d of facetDeltas(db, followerId, placeOfMirror(data), placeOfFields(next))) {
      const cur = deltas.get(d.ref.path);
      if (cur) {
        cur.delta += d.delta;
        Object.assign(cur.init, d.init);
      } else {
        deltas.set(d.ref.path, { ...d, init: { ...d.init } });
      }
    }
  }
  if (!writes.length) return 0;
  const moves = [...deltas.values()].filter((d) => d.delta !== 0);
  await writeFacets(txn, fv, moves);
  for (const w of writes) txn.update(w.ref, w.patch);
  return writes.length;
}

/**
 * Facet writes of one transaction: increments as merge-sets (no read), and
 * decrements against a transactional read so a facet reaching 0 is deleted.
 * All reads happen before the first write.
 */
async function writeFacets(txn: any, fv: StoreFieldValues, moves: FacetDelta[]): Promise<void> {
  const down = moves.filter((m) => m.delta < 0);
  const snaps = down.length ? await txn.getAll(...down.map((m) => m.ref)) : [];
  down.forEach((m, i) => {
    const s = snaps[i];
    const n = s.exists ? Number(s.get('n')) || 0 : 0;
    if (n + m.delta <= 0) {
      if (s.exists) txn.delete(m.ref);
    } else {
      txn.update(m.ref, { n: fv.increment(m.delta) });
    }
  });
  for (const m of moves) {
    if (m.delta > 0) txn.set(m.ref, { ...m.init, n: fv.increment(m.delta) }, { merge: true });
  }
}

/**
 * Stamp the store fields on ONE new follow's mirror. [followee] is the
 * followee's profile data when the caller already read it. Idempotent; never
 * creates the mirror. No read and no write when the followee is not a
 * business.
 */
export async function stampStoreFields(
  db: any,
  fv: StoreFieldValues,
  followeeId: string,
  followerId: string,
  followee?: Record<string, any> | null,
): Promise<boolean> {
  if (!followeeId || !followerId) return false;
  const data = followee !== undefined
    ? followee
    : await db.collection('profiles').doc(followeeId).get().then((s: any) => (s.exists ? s.data() : null));
  const next = storeFieldsOf(data);
  if (!next) return false;
  const ref = followingCol(db, followerId).doc(followeeId);
  const n = await db.runTransaction(async (txn: any) => {
    const mirror = await txn.get(ref);
    return applyInTxn(txn, db, fv, [{ followerId, mirror, next }]);
  });
  return n > 0;
}

export interface FollowStoreJob {
  /** The business's current store fields (null = no longer a business). */
  fields: StoreFields | null;
  gen: number;
  cursor: string | null;
  round?: number;
}

/**
 * Called on every profiles/{uid} write. Exits WITHOUT a read unless a store
 * field actually changed on an existing (not new, not deleted) profile; then
 * (re)starts the fan-out job. Overwriting the job resets it to the newest
 * fields — a run for older fields stops at its next page.
 */
export async function enqueueFollowStoreJobIfChanged(
  db: any,
  uid: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  now: () => number = () => Date.now(),
): Promise<boolean> {
  if (!uid || !before || !after) return false;
  const next = storeFieldsOf(after);
  if (sameStoreFields(storeFieldsOf(before), next)) return false;
  const job: FollowStoreJob = { fields: next, gen: now(), cursor: null, round: 0 };
  await db.collection(FOLLOW_STORE_JOBS).doc(uid).set(job);
  return true;
}

export interface FollowStoreRoundResult {
  done: boolean;
  /** A newer change superseded the job (this run stopped). */
  superseded: boolean;
  updated: number;
  scanned: number;
  cursor: string | null;
}

/**
 * One bounded round of the store fan-out for business [uid]: its followers
 * (canonical edges, paged by document id from the saved cursor; the source is
 * not consumed, so a cursor is the right resume point) → their mirrors
 * `user_business_following/{f}/businesses/{uid}`. Each page is ONE
 * transaction that first re-reads the job (a newer `gen` stops the run), so a
 * stale fan-out never writes last.
 */
export async function followStoreRound(
  db: any,
  fv: StoreFieldValues,
  uid: string,
  job: FollowStoreJob,
  opts: { deadlineMs: number; pageSize?: number; nowMs?: () => number },
): Promise<FollowStoreRoundResult> {
  const pageSize = Math.max(1, Math.min(opts.pageSize ?? STORE_PAGE, STORE_PAGE));
  const now = opts.nowMs ?? (() => Date.now());
  const jobRef = db.collection(FOLLOW_STORE_JOBS).doc(uid);
  let cursor = job.cursor;
  let updated = 0;
  let scanned = 0;
  let worked = false;
  const res = (done: boolean, superseded = false): FollowStoreRoundResult => ({
    done, superseded, updated, scanned, cursor,
  });

  for (;;) {
    if (worked && now() > opts.deadlineMs) return res(false);
    worked = true;
    let q = followersCol(db, uid).orderBy('__name__').limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const page = await q.get();
    scanned += page.size;
    if (page.size > 0) {
      const ids: string[] = page.docs.map((d: any) => d.id);
      const n: number = await db.runTransaction(async (txn: any) => {
        const cur = await txn.get(jobRef);
        if (!cur.exists || cur.get('gen') !== job.gen) return -1;
        const mirrors = await txn.getAll(...ids.map((f) => followingCol(db, f).doc(uid)));
        return applyInTxn(txn, db, fv, ids.map((followerId, i) => ({
          followerId, mirror: mirrors[i], next: job.fields,
        })));
      });
      if (n < 0) return res(false, true);
      updated += n;
      cursor = ids[ids.length - 1];
    } else {
      // An empty first page still has to notice a superseded job.
      const cur = await jobRef.get();
      if (!cur.exists || cur.get('gen') !== job.gen) return res(false, true);
    }
    if (page.size < pageSize) return res(true);
  }
}

/**
 * Backfill / repair: bring a page of mirrors (each with its followee's
 * profile data) to the current store fields in ONE transaction. Returns how
 * many mirrors changed. Used by scripts/backfill-store-fields.ts.
 */
export async function applyStoreFieldsPage(
  db: any,
  fv: StoreFieldValues,
  rows: Array<{ followerId: string; followeeId: string; followee: Record<string, any> | null }>,
): Promise<number> {
  if (!rows.length) return 0;
  return db.runTransaction(async (txn: any) => {
    const mirrors = await txn.getAll(...rows.map((r) => followingCol(db, r.followerId).doc(r.followeeId)));
    return applyInTxn(txn, db, fv, rows.map((r, i) => ({
      followerId: r.followerId, mirror: mirrors[i], next: storeFieldsOf(r.followee),
    })));
  });
}

/** True when [mirror] (data) differs from what [followee] should stamp. */
export function mirrorNeedsStoreFields(
  mirror: Record<string, any> | undefined,
  followee: Record<string, any> | null,
): boolean {
  return !mirrorHas(mirror, storeFieldsOf(followee));
}

/** How long a mirror-delete event marker is kept (retries stop after 7 days). */
const MARKER_TTL_MS = 8 * 24 * 60 * 60 * 1000;

/**
 * A mirror was deleted: take its place out of the follower's facets, exactly
 * once per delete event. No read for a mirror that carried no place (every
 * non-store unfollow). Returns true when this call decremented.
 */
export async function unplaceDeletedMirror(
  db: any,
  fv: StoreFieldValues,
  eventId: string,
  followerId: string,
  followeeId: string,
  old: Record<string, any> | undefined,
  now: () => Date = () => new Date(),
): Promise<boolean> {
  const place = placeOfMirror(old);
  if (!place || !followerId) return false;
  const at = now();
  const marker = db
    .collection(UNCOUNT_MARKERS)
    .doc(`store_${eventId || `${followerId}_${followeeId}_${at.getTime()}`}`);
  return db.runTransaction(async (txn: any) => {
    const m = await txn.get(marker);
    if (m.exists) return false; // retried delivery of an event already applied
    const moves = facetDeltas(db, followerId, place, null);
    await writeFacets(txn, fv, moves);
    txn.set(marker, {
      kind: 'store_unplace',
      followerId,
      followeeId,
      at,
      expireAt: new Date(at.getTime() + MARKER_TTL_MS),
    });
    return true;
  });
}
