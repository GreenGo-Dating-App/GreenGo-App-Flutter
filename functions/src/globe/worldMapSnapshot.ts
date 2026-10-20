/**
 * World map ("My world") snapshots - owner decision 2026-10-20: "My world map
 * data are updated with batches, not in real time. Every hour data is
 * refreshed and must be able to have quick fetch from server."
 *
 * `world_map_snapshots/{uid}` holds the pins of the user's network map, built
 * on the server with the SAME rules as the app's client assembler
 * (lib/features/globe_explore/data/network_pin_assembler.dart, 5.0.41):
 *
 *  * relations: following (newest 300), followers (newest 300), partners of
 *    the 300 most recent 1:1 chats with a message; one pin per account with
 *    all its badges;
 *  * the user, accounts blocked by the user AND accounts that blocked the
 *    user (both directions, `profiles/{uid}/blocked_users` + `block_index`)
 *    and accounts without a profile are skipped;
 *  * BUSINESSES (isBusiness, or the follow edge's isStore) at their PUBLIC
 *    business address with the business picture / name, else people rules;
 *  * PEOPLE: inactive, incognito (unexpired), ghost mode, "Hidden" and
 *    location-less accounts are left out; the rest are positioned from the
 *    PUBLIC position only (approxLocation, or the +-100 m preciseLocation the
 *    server publishes for 'exact' users): 'exact' -> preciseLocation as is
 *    (legacy fallback: +-0.005 deg around the public position), 'approximate'
 *    (the default) -> ~50 km grid cell centre +-0.1 deg, 'country' -> country
 *    centroid +-1.5 deg. Exact coordinates of a non-'exact' person never
 *    leave this module.
 *
 * Parity with the Dart assembler is pinned by ONE shared fixture both test
 * suites read: functions/__tests__/fixtures/world_map_pin_cases.json.
 *
 * Doc shape (owner `get` only, Admin SDK writes only - firestore rules):
 *   { schema, buildId, builtAt, pins: WorldMapPin[], chunkCount, counts,
 *     refreshAfter, active, lastOpenedAt, lastOnDemandAt? }
 * Pins that do not fit INLINE_BUDGET_BYTES go to `chunks/{0..n-1}`
 * ({buildId, index, pins}) and the main doc's `pins` is empty.
 *
 * This file is pure + injectable I/O (no firebase-functions import) so it is
 * unit-tested without emulators; the deployed functions are in
 * worldMapSnapshotFunctions.ts.
 */
import * as admin from 'firebase-admin';
import { COUNTRY_CENTROIDS } from './countryCentroids';

/* eslint-disable @typescript-eslint/no-explicit-any */

export const WORLD_MAP_SNAPSHOTS = 'world_map_snapshots';
export const WORLD_MAP_CHUNKS = 'chunks';
export const WORLD_MAP_MAINTENANCE_DOC = 'maintenance/world_map_snapshots';
/** Pub/Sub topic of the hourly fan-out (dispatcher -> batch workers). */
export const WORLD_MAP_REBUILD_TOPIC = 'world-map-snapshot-rebuild';
export const SNAPSHOT_SCHEMA = 1;

export const FOLLOWING_CAP = 300;
export const FOLLOWERS_CAP = 300;
export const CHATS_CAP = 300;
export const BLOCKS_CAP = 1000;
export const MAX_PINS = 1000;

/** A snapshot older than this is rebuilt when its owner opens the map. */
export const SNAPSHOT_TTL_MS = 60 * 60 * 1000;
/** Due time of the next scheduled rebuild after a build. */
export const REFRESH_EVERY_MS = 55 * 60 * 1000;
/** Backoff after a failed scheduled build. */
export const FAILED_RETRY_MS = 60 * 60 * 1000;
/** Hourly rebuilds only for users who opened the map within this window. */
export const ACTIVE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
/** On-demand builds per user at most once per this interval. */
export const ON_DEMAND_MIN_INTERVAL_MS = 2 * 60 * 1000;
/** `lastOpenedAt` is rewritten at most once per this interval. */
export const OPEN_MARKER_EVERY_MS = 60 * 60 * 1000;

/** Pins JSON above this goes to chunk docs (the doc limit is 1 MiB). */
export const INLINE_BUDGET_BYTES = 800_000;
export const CHUNK_BUDGET_BYTES = 700_000;

/** Public profile fields the pins need (getAll field mask). */
export const PROFILE_FIELDS = [
  'displayName', 'photoUrls', 'accountStatus', 'isBanned', 'isIncognito',
  'incognitoExpiry', 'isGhostMode', 'globeDiscoverability', 'location',
  'approxLocation', 'preciseLocation', 'travelerLocation', 'isTraveler',
  'travelerExpiry', 'isOnline', 'isBusiness', 'businessAddress',
  'businessLogoUrl', 'coverImageUrl', 'galleryImages', 'businessName',
];

export type Rng = () => number;
export type Badge = 'following' | 'follower' | 'chat';
export type Disc = 'exact' | 'approximate' | 'country';
const BADGE_ORDER: Badge[] = ['following', 'follower', 'chat'];

export interface WorldMapPin {
  id: string;
  kind: 'person' | 'business';
  lat: number;
  lng: number;
  name: string;
  photo: string | null;
  badges: Badge[];
  country: string;
  city: string;
  /** People only: the discoverability they are drawn with. */
  disc?: Disc;
  isOnlineAtBuild: boolean;
  /** People with an active traveler mode: destination + home centroid. */
  traveler?: { country: string; homeLat: number; homeLng: number };
}

export interface FollowEdge { id: string; isStore: boolean }

export interface SnapshotInputs {
  userId: string;
  following: FollowEdge[];
  followers: string[];
  chats: string[];
  profiles: Record<string, Record<string, any>>;
  blocked: Set<string>;
}

export interface SnapshotCounts {
  pins: number;
  people: number;
  businesses: number;
  following: number;
  followers: number;
  chats: number;
}

// ---------------------------------------------------------------------------
// Pure rules (ported 1:1 from the Dart assembler)
// ---------------------------------------------------------------------------

/** Millis of a Firestore Timestamp / Date / number / {seconds}, else null. */
export function toMillis(v: any): number | null {
  if (v == null) return null;
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  if (v instanceof Date) return v.getTime();
  if (typeof v.toMillis === 'function') return v.toMillis();
  if (typeof v._ts === 'number') return v._ts; // shared JSON fixture form
  const s = v.seconds ?? v._seconds;
  if (typeof s === 'number') return s * 1000 + Math.floor((v.nanoseconds ?? v._nanoseconds ?? 0) / 1e6);
  return null;
}

const isNum = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v);

function validCoords(lat: unknown, lng: unknown): [number, number] | null {
  if (!isNum(lat) || !isNum(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180 || (lat === 0 && lng === 0)) return null;
  return [lat, lng];
}

const coordsOf = (m: unknown, latKey: string, lngKey: string) =>
  m && typeof m === 'object' ? validCoords((m as any)[latKey], (m as any)[lngKey]) : null;

/** `preciseLocation`, honoured only while globeDiscoverability is 'exact'. */
export const preciseCoordsOf = (d: Record<string, any>) =>
  d?.globeDiscoverability === 'exact' ? coordsOf(d.preciseLocation, 'lat', 'lng') : null;
export const approxCoordsOf = (d: Record<string, any>) => coordsOf(d?.approxLocation, 'lat', 'lng');

/**
 * Another user's profile as the map may use it: `location` (and
 * `travelerLocation`) coordinates replaced by the public position
 * (preciseLocation for 'exact', else approxLocation). Port of Dart
 * `publicProfileView`.
 */
export function publicView(data: Record<string, any>): Record<string, any> {
  const coords = preciseCoordsOf(data) ?? approxCoordsOf(data);
  if (!coords) return data;
  const withCoords = (base: unknown) => ({
    ...(base && typeof base === 'object' ? base : {}),
    latitude: coords[0],
    longitude: coords[1],
  });
  const out: Record<string, any> = { ...data, location: withCoords(data.location) };
  if (data.travelerLocation && typeof data.travelerLocation === 'object') {
    out.travelerLocation = withCoords(data.travelerLocation);
  }
  return out;
}

export function centroidOf(country: string): [number, number] {
  const c = COUNTRY_CENTROIDS[country];
  return c ? [c[0], c[1]] : [0, 0];
}

/** Country centroid +-1.5 deg (Dart getJitteredCentroid). */
export function jitteredCentroid(country: string, rng: Rng): [number, number] {
  const c = centroidOf(country);
  return [c[0] + (rng() * 3.0 - 1.5), c[1] + (rng() * 3.0 - 1.5)];
}

/** +-0.005 deg (Dart getExactJittered). */
export function exactJittered(lat: number, lng: number, rng: Rng): [number, number] {
  return [lat + (rng() * 0.01 - 0.005), lng + (rng() * 0.01 - 0.005)];
}

export const HILBERT_CELL_DEG = 0.45;

/** ~50 km grid cell centre +-0.1 deg (Dart getHilbertCentroid). */
export function hilbertCentroid(lat: number, lng: number, rng: Rng): [number, number] {
  const cs = HILBERT_CELL_DEG;
  const cellLat = Math.floor(lat / cs) * cs + cs / 2;
  const cellLng = Math.floor(lng / cs) * cs + cs / 2;
  return [cellLat + (rng() * 0.2 - 0.1), cellLng + (rng() * 0.2 - 0.1)];
}

function parseDisc(v: unknown): Disc | 'hidden' {
  const s = v == null ? 'approximate' : v;
  if (s === 'exact' || s === 'approximate' || s === 'hidden') return s;
  return 'country';
}

const round = (v: number) => Math.round(v * 1e6) / 1e6;
const str = (v: unknown): string | null => (typeof v === 'string' ? v : null);

/**
 * A person's pin, or null when they must not be shown. Port of Dart
 * `personPinFrom` + `GlobeUserModel.fromFirestore` (the 'matched' branch).
 */
export function personPin(
  raw: Record<string, any>,
  id: string,
  rng: Rng,
  nowMs: number,
): WorldMapPin | null {
  const p = publicView(raw);
  if (p.accountStatus !== 'active') return null;
  if (p.isIncognito === true) {
    const exp = toMillis(p.incognitoExpiry);
    if (exp == null || exp > nowMs) return null;
  }
  if (p.isGhostMode === true) return null;
  if (p.globeDiscoverability === 'hidden') return null;

  const loc = p.location;
  if (!loc || typeof loc !== 'object') return null;
  if (loc.latitude == null || loc.longitude == null || loc.country == null) return null;
  if (!isNum(loc.latitude) || !isNum(loc.longitude) || typeof loc.country !== 'string') return null;
  if (loc.country === 'Unknown') return null;

  const photos = p.photoUrls;
  const photo = Array.isArray(photos) && photos.length > 0 ? str(photos[0]) : null;
  const city = str(loc.city) ?? 'Unknown';
  const country: string = loc.country;

  const travelerActive = p.isTraveler === true && (toMillis(p.travelerExpiry) ?? -Infinity) > nowMs;
  const tl = p.travelerLocation && typeof p.travelerLocation === 'object' ? p.travelerLocation : null;
  const tLat = isNum(tl?.latitude) ? tl.latitude : null;
  const tLng = isNum(tl?.longitude) ? tl.longitude : null;
  const tCountry = str(tl?.country);
  const effLat = travelerActive && tLat != null ? tLat : loc.latitude;
  const effLng = travelerActive && tLng != null ? tLng : loc.longitude;
  const effCountry = travelerActive && tCountry != null ? tCountry : country;

  const disc = parseDisc(p.globeDiscoverability);
  let coords: [number, number];
  if (disc === 'exact') {
    coords = preciseCoordsOf(p) ?? exactJittered(effLat, effLng, rng);
  } else if (disc === 'approximate') {
    coords = hilbertCentroid(effLat, effLng, rng);
  } else {
    coords = jitteredCentroid(effCountry, rng);
  }

  const pin: WorldMapPin = {
    id,
    kind: 'person',
    lat: round(coords[0]),
    lng: round(coords[1]),
    name: str(p.displayName) ?? 'Unknown',
    photo,
    badges: [],
    country: effCountry,
    city,
    disc: disc === 'hidden' ? 'country' : disc,
    isOnlineAtBuild: p.isOnline === true,
  };
  if (travelerActive && tCountry != null) {
    const home = centroidOf(country);
    pin.traveler = { country: tCountry, homeLat: home[0], homeLng: home[1] };
  }
  return pin;
}

function firstUrl(v: unknown): string | null {
  if (typeof v === 'string') return v.trim() === '' ? null : v.trim();
  if (Array.isArray(v)) {
    for (const u of v) if (typeof u === 'string' && u.trim() !== '') return u.trim();
  }
  return null;
}

/** Port of Dart BusinessAddress.fromMap: null when not usable. */
export function businessAddressOf(m: unknown):
  { latitude: number; longitude: number; city: string; country: string } | null {
  if (!m || typeof m !== 'object') return null;
  const a = m as any;
  if (!isNum(a.latitude) || !isNum(a.longitude)) return null;
  if (Math.abs(a.latitude) > 90 || Math.abs(a.longitude) > 180 || (a.latitude === 0 && a.longitude === 0)) return null;
  if (`${a.address ?? ''}`.trim() === '') return null;
  return {
    latitude: a.latitude,
    longitude: a.longitude,
    city: `${a.city ?? ''}`.trim(),
    country: `${a.country ?? ''}`.trim(),
  };
}

/** A business's pin at its PUBLIC address (Dart `businessPinFrom`). */
export function businessPin(data: Record<string, any>, id: string): WorldMapPin | null {
  if (data.accountStatus !== 'active' || data.isBanned === true) return null;
  const address = businessAddressOf(data.businessAddress);
  if (!address) return null;
  const photo = firstUrl(data.businessLogoUrl) ?? firstUrl(data.coverImageUrl)
    ?? firstUrl(data.galleryImages) ?? firstUrl(data.photoUrls);
  const businessName = (str(data.businessName) ?? '').trim();
  const displayName = (str(data.displayName) ?? '').trim();
  return {
    id,
    kind: 'business',
    lat: address.latitude,
    lng: address.longitude,
    name: businessName || displayName || 'Unknown',
    photo,
    badges: [],
    country: address.country || 'Unknown',
    city: address.city || 'Unknown',
    isOnlineAtBuild: data.isOnline === true,
  };
}

/**
 * The network map's pins (Dart `assembleNetworkPins`): one per account, all
 * of its badges, each relation group capped in the order given (newest
 * first), the user / blocked / profile-less accounts skipped, at most
 * [MAX_PINS] (chats first, then following, then followers).
 */
export function assemblePins(input: SnapshotInputs, rng: Rng = Math.random, nowMs: number = Date.now()): WorldMapPin[] {
  const { userId, blocked } = input;
  const relations = new Map<string, Set<Badge>>();
  const storeFlag = new Set<string>();
  const add = (id: string, b: Badge) => {
    if (!id || id === userId || blocked.has(id)) return;
    let s = relations.get(id);
    if (!s) relations.set(id, (s = new Set()));
    s.add(b);
  };
  for (const c of input.chats.slice(0, CHATS_CAP)) add(c, 'chat');
  for (const e of input.following.slice(0, FOLLOWING_CAP)) {
    add(e.id, 'following');
    if (e.isStore) storeFlag.add(e.id);
  }
  for (const f of input.followers.slice(0, FOLLOWERS_CAP)) add(f, 'follower');

  const pins: WorldMapPin[] = [];
  for (const [id, rels] of relations) {
    if (pins.length >= MAX_PINS) break;
    const data = input.profiles[id];
    if (!data) continue;
    const isBusiness = data.isBusiness === true || storeFlag.has(id);
    const pin = isBusiness
      ? (businessPin(data, id) ?? personPin(data, id, rng, nowMs))
      : personPin(data, id, rng, nowMs);
    if (!pin) continue;
    pin.badges = BADGE_ORDER.filter((b) => rels.has(b));
    pins.push(pin);
  }
  return pins;
}

/** Port of Dart `chatPartnerOf`: the other member of a counted 1:1 chat. */
export function chatPartnerOf(conv: Record<string, any>, userId: string): string | null {
  if (conv.lastMessage == null) return null;
  const type = conv.conversationType;
  if (type === 'support' || type === 'group') return null;
  if (conv.isDeleted === true) return null;
  const deletedFor = conv.deletedFor;
  if (deletedFor && typeof deletedFor === 'object' && !Array.isArray(deletedFor)
      && Object.prototype.hasOwnProperty.call(deletedFor, userId)) return null;
  const visibleTo = conv.visibleTo;
  if (Array.isArray(visibleTo) && !visibleTo.includes(userId)) return null;
  const u1 = str(conv.userId1);
  const u2 = str(conv.userId2);
  const other = u1 === userId ? u2 : (u2 === userId ? u1 : null);
  return !other || other === userId ? null : other;
}

export function countsOf(pins: WorldMapPin[], input: SnapshotInputs): SnapshotCounts {
  return {
    pins: pins.length,
    people: pins.filter((p) => p.kind === 'person').length,
    businesses: pins.filter((p) => p.kind === 'business').length,
    following: Math.min(input.following.length, FOLLOWING_CAP),
    followers: Math.min(input.followers.length, FOLLOWERS_CAP),
    chats: Math.min(input.chats.length, CHATS_CAP),
  };
}

const bytesOf = (v: unknown) => Buffer.byteLength(JSON.stringify(v), 'utf8');

/**
 * Pins split for storage: `inline` when they fit [inlineBudget], else
 * consecutive chunks each <= [chunkBudget] bytes of JSON (order kept).
 */
export function splitPins(
  pins: WorldMapPin[],
  inlineBudget: number = INLINE_BUDGET_BYTES,
  chunkBudget: number = CHUNK_BUDGET_BYTES,
): { inline: WorldMapPin[]; chunks: WorldMapPin[][] } {
  if (bytesOf(pins) <= inlineBudget) return { inline: pins, chunks: [] };
  const chunks: WorldMapPin[][] = [];
  let cur: WorldMapPin[] = [];
  let size = 2;
  for (const p of pins) {
    const b = bytesOf(p) + 1;
    if (cur.length > 0 && size + b > chunkBudget) {
      chunks.push(cur);
      cur = [];
      size = 2;
    }
    cur.push(p);
    size += b;
  }
  if (cur.length) chunks.push(cur);
  return { inline: [], chunks };
}

// ---------------------------------------------------------------------------
// I/O (injectable)
// ---------------------------------------------------------------------------

/** Where the inputs of a build come from (Firestore in prod, fakes in tests). */
export interface SnapshotReader {
  blocked(uid: string): Promise<Set<string>>;
  following(uid: string): Promise<FollowEdge[]>;
  followers(uid: string): Promise<string[]>;
  chats(uid: string): Promise<string[]>;
  profiles(ids: string[]): Promise<Record<string, Record<string, any>>>;
}

async function safe<T>(f: () => Promise<T>, fallback: T): Promise<T> {
  try {
    return await f();
  } catch (e) {
    console.warn('worldMapSnapshot read failed', (e as Error)?.message);
    return fallback;
  }
}

/**
 * Firestore reads of one build. All bounded; the profiles come from a
 * per-instance [cache] shared by the users of one batch (popular accounts are
 * read once per batch, not once per follower).
 */
export class FirestoreSnapshotReader implements SnapshotReader {
  constructor(
    private readonly db: admin.firestore.Firestore,
    private readonly cache: Map<string, Record<string, any> | null> = new Map(),
    private readonly cacheMax = 20000,
  ) {}

  async blocked(uid: string): Promise<Set<string>> {
    const [own, byMe, ofMe] = await Promise.all([
      safe(() => this.db.collection('profiles').doc(uid).collection('blocked_users')
        .limit(BLOCKS_CAP).select().get(), null),
      safe(() => this.db.collection('block_index').where('blockerId', '==', uid)
        .limit(BLOCKS_CAP).select('blockedUserId').get(), null),
      safe(() => this.db.collection('block_index').where('blockedUserId', '==', uid)
        .limit(BLOCKS_CAP).select('blockerId').get(), null),
    ]);
    const out = new Set<string>();
    own?.docs.forEach((d) => out.add(d.id));
    byMe?.docs.forEach((d) => { const v = d.get('blockedUserId'); if (typeof v === 'string') out.add(v); });
    ofMe?.docs.forEach((d) => { const v = d.get('blockerId'); if (typeof v === 'string') out.add(v); });
    return out;
  }

  private async newest(col: admin.firestore.CollectionReference, cap: number) {
    return safe(async () => (await col.orderBy('createdAt', 'desc').limit(cap).select('isStore').get()).docs,
      null as admin.firestore.QueryDocumentSnapshot[] | null)
      .then(async (docs) => docs ?? (await safe(async () => (await col.limit(cap).select('isStore').get()).docs, [])));
  }

  async following(uid: string): Promise<FollowEdge[]> {
    const docs = await this.newest(
      this.db.collection('user_business_following').doc(uid).collection('businesses'), FOLLOWING_CAP);
    return docs.map((d) => ({ id: d.id, isStore: d.get('isStore') === true }));
  }

  async followers(uid: string): Promise<string[]> {
    const docs = await this.newest(
      this.db.collection('business_followers').doc(uid).collection('followers'), FOLLOWERS_CAP);
    return docs.map((d) => d.id);
  }

  async chats(uid: string): Promise<string[]> {
    const Filter = admin.firestore.Filter;
    const fields = ['userId1', 'userId2', 'lastMessage', 'conversationType', 'isDeleted', 'deletedFor', 'visibleTo'];
    const base = this.db.collection('conversations').where(Filter.or(
      Filter.where('userId1', '==', uid),
      Filter.where('userId2', '==', uid),
    ));
    const snap = await safe(() => base.orderBy('lastMessageAt', 'desc').limit(CHATS_CAP).select(...fields).get(), null)
      ?? await safe(() => base.limit(CHATS_CAP).select(...fields).get(), null);
    const out: string[] = [];
    const seen = new Set<string>();
    for (const d of snap?.docs ?? []) {
      const other = chatPartnerOf(d.data(), uid);
      if (other && !seen.has(other)) {
        seen.add(other);
        out.push(other);
      }
    }
    return out;
  }

  async profiles(ids: string[]): Promise<Record<string, Record<string, any>>> {
    const missing = ids.filter((id) => !this.cache.has(id));
    for (let i = 0; i < missing.length; i += 300) {
      const part = missing.slice(i, i + 300);
      const refs = part.map((id) => this.db.collection('profiles').doc(id));
      const snaps = await safe(() => this.db.getAll(...refs, { fieldMask: PROFILE_FIELDS }), null);
      if (!snaps) continue; // not cached: retried by the next build
      snaps.forEach((s, j) => this.cache.set(part[j], s.exists ? (s.data() ?? null) : null));
    }
    while (this.cache.size > this.cacheMax) {
      this.cache.delete(this.cache.keys().next().value as string);
    }
    const out: Record<string, Record<string, any>> = {};
    for (const id of ids) {
      const d = this.cache.get(id);
      if (d) out[id] = d;
    }
    return out;
  }
}

/** Reads the inputs of [uid]'s snapshot and assembles its pins. */
export async function buildSnapshot(
  reader: SnapshotReader,
  uid: string,
  rng: Rng = Math.random,
  nowMs: number = Date.now(),
): Promise<{ pins: WorldMapPin[]; counts: SnapshotCounts }> {
  const [blocked, following, followers, chats] = await Promise.all([
    reader.blocked(uid), reader.following(uid), reader.followers(uid), reader.chats(uid),
  ]);
  const ids = new Set<string>([
    ...chats.slice(0, CHATS_CAP),
    ...following.slice(0, FOLLOWING_CAP).map((e) => e.id),
    ...followers.slice(0, FOLLOWERS_CAP),
  ]);
  ids.delete(uid);
  for (const b of blocked) ids.delete(b);
  const profiles = await reader.profiles([...ids]);
  const input: SnapshotInputs = { userId: uid, following, followers, chats, profiles, blocked };
  const pins = assemblePins(input, rng, nowMs);
  return { pins, counts: countsOf(pins, input) };
}

/** The main doc + chunk docs one build writes (pure; tested). */
export function snapshotWrites(
  pins: WorldMapPin[],
  counts: SnapshotCounts,
  nowMs: number,
  buildId: string,
  prevChunkCount: number,
  extra: Record<string, any> = {},
  budgets: { inline: number; chunk: number } = { inline: INLINE_BUDGET_BYTES, chunk: CHUNK_BUDGET_BYTES },
): { main: Record<string, any>; chunks: Record<string, any>[]; deleteChunks: number[] } {
  const { inline, chunks } = splitPins(pins, budgets.inline, budgets.chunk);
  const main = {
    schema: SNAPSHOT_SCHEMA,
    buildId,
    builtAt: admin.firestore.Timestamp.fromMillis(nowMs),
    refreshAfter: admin.firestore.Timestamp.fromMillis(nowMs + REFRESH_EVERY_MS),
    pins: inline,
    chunkCount: chunks.length,
    counts,
    lastBuildErrorAt: null,
    ...extra,
  };
  const deleteChunks: number[] = [];
  for (let i = chunks.length; i < Math.max(0, prevChunkCount); i++) deleteChunks.push(i);
  return {
    main,
    chunks: chunks.map((c, index) => ({ buildId, index, pins: c })),
    deleteChunks,
  };
}

export const snapshotRef = (db: admin.firestore.Firestore, uid: string) =>
  db.collection(WORLD_MAP_SNAPSHOTS).doc(uid);

/**
 * Builds and stores [uid]'s snapshot (one atomic batch: chunks, then the main
 * doc, stale chunks deleted). Idempotent: a rebuild replaces everything.
 */
export async function buildAndStore(
  db: admin.firestore.Firestore,
  reader: SnapshotReader,
  uid: string,
  opts: {
    nowMs?: number; rng?: Rng; prevChunkCount?: number; extra?: Record<string, any>;
    /** Test hook: storage budgets (bytes). */
    budgets?: { inline: number; chunk: number };
  } = {},
): Promise<{ pins: WorldMapPin[]; counts: SnapshotCounts; builtAtMs: number }> {
  const nowMs = opts.nowMs ?? Date.now();
  const { pins, counts } = await buildSnapshot(reader, uid, opts.rng ?? Math.random, nowMs);
  const buildId = `${nowMs.toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
  const w = snapshotWrites(pins, counts, nowMs, buildId, opts.prevChunkCount ?? 0, opts.extra, opts.budgets);
  const ref = snapshotRef(db, uid);
  const batch = db.batch();
  w.chunks.forEach((c) => batch.set(ref.collection(WORLD_MAP_CHUNKS).doc(String(c.index)), c));
  w.deleteChunks.forEach((i) => batch.delete(ref.collection(WORLD_MAP_CHUNKS).doc(String(i))));
  batch.set(ref, w.main, { merge: true });
  await batch.commit();
  return { pins, counts, builtAtMs: nowMs };
}

/** All pins of a stored snapshot (main doc + its chunks of the same build). */
export async function readStoredPins(
  db: admin.firestore.Firestore,
  uid: string,
  main: Record<string, any>,
): Promise<WorldMapPin[] | null> {
  const n = typeof main.chunkCount === 'number' ? main.chunkCount : 0;
  if (n <= 0) return Array.isArray(main.pins) ? main.pins : [];
  const ref = snapshotRef(db, uid).collection(WORLD_MAP_CHUNKS);
  const snaps = await db.getAll(...Array.from({ length: n }, (_, i) => ref.doc(String(i))));
  const out: WorldMapPin[] = [];
  for (const s of snaps) {
    if (!s.exists || s.get('buildId') !== main.buildId) return null; // a rebuild raced us
    out.push(...(s.get('pins') ?? []));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Callable decision + scheduled dispatch + batch worker cores (injectable)
// ---------------------------------------------------------------------------

export type OpenDecision = 'fresh' | 'build' | 'stale-rate-limited';

/** What `getWorldMapSnapshot` does for a stored doc (pure). */
export function decideOpen(doc: Record<string, any> | undefined, nowMs: number): OpenDecision {
  const builtAt = toMillis(doc?.builtAt);
  if (doc && doc.schema === SNAPSHOT_SCHEMA && builtAt != null && nowMs - builtAt < SNAPSHOT_TTL_MS) {
    return 'fresh';
  }
  const lastOnDemand = toMillis(doc?.lastOnDemandAt);
  if (doc && doc.schema === SNAPSHOT_SCHEMA && Array.isArray(doc.pins)
      && lastOnDemand != null && nowMs - lastOnDemand < ON_DEMAND_MIN_INTERVAL_MS) {
    return 'stale-rate-limited';
  }
  return 'build';
}

/** True when the open marker should be rewritten (throttled). */
export function markerDue(doc: Record<string, any> | undefined, nowMs: number): boolean {
  const last = toMillis(doc?.lastOpenedAt);
  return doc?.active !== true || last == null || nowMs - last >= OPEN_MARKER_EVERY_MS;
}

export interface DueDoc { uid: string; lastOpenedAtMs: number | null; refreshAfterMs: number | null }

export interface DispatchDeps {
  /** Due docs (active, refreshAfter <= dueBefore) ordered by refreshAfter, after [cursor]. */
  queryDue(dueBeforeMs: number, cursor: DueDoc | null, limit: number): Promise<DueDoc[]>;
  deactivate(uids: string[]): Promise<void>;
  publish(uids: string[]): Promise<void>;
}

export interface DispatchResult { scanned: number; dispatched: number; deactivated: number; messages: number; truncated: boolean }

/**
 * The hourly dispatcher: every active snapshot that is due is sent to the
 * batch workers ([batchSize] uids per message); users who have not opened
 * the map within [ACTIVE_WINDOW_MS] are deactivated (no more hourly builds
 * until they open it again). Bounded by [maxUsers]; the queue position is
 * `refreshAfter` itself (stalest first), so whatever is left over is the
 * first thing the next run picks up - no user starves.
 */
export async function dispatchDue(
  deps: DispatchDeps,
  nowMs: number,
  opts: { pageSize?: number; batchSize?: number; maxUsers?: number; slackMs?: number } = {},
): Promise<DispatchResult> {
  const pageSize = opts.pageSize ?? 1000;
  const batchSize = opts.batchSize ?? 100;
  const maxUsers = opts.maxUsers ?? 200_000;
  const dueBefore = nowMs + (opts.slackMs ?? 5 * 60 * 1000);
  const r: DispatchResult = { scanned: 0, dispatched: 0, deactivated: 0, messages: 0, truncated: false };
  let cursor: DueDoc | null = null;
  let pending: string[] = [];
  const flush = async (all: boolean) => {
    while (pending.length >= batchSize || (all && pending.length > 0)) {
      const part = pending.slice(0, batchSize);
      pending = pending.slice(batchSize);
      await deps.publish(part);
      r.messages++;
      r.dispatched += part.length;
    }
  };
  for (;;) {
    if (r.scanned >= maxUsers) { r.truncated = true; break; }
    const page = await deps.queryDue(dueBefore, cursor, Math.min(pageSize, maxUsers - r.scanned));
    if (page.length === 0) break;
    r.scanned += page.length;
    const inactive: string[] = [];
    for (const d of page) {
      if (d.lastOpenedAtMs == null || nowMs - d.lastOpenedAtMs > ACTIVE_WINDOW_MS) inactive.push(d.uid);
      else pending.push(d.uid);
    }
    if (inactive.length) {
      await deps.deactivate(inactive);
      r.deactivated += inactive.length;
    }
    await flush(false);
    cursor = page[page.length - 1];
    if (page.length < pageSize) break;
  }
  await flush(true);
  return r;
}

export interface BatchDeps {
  /** Current main doc of [uid] (undefined when missing). */
  load(uid: string): Promise<Record<string, any> | undefined>;
  build(uid: string, prevChunkCount: number): Promise<void>;
  markFailed(uid: string): Promise<void>;
}

/**
 * The batch worker: rebuilds each uid that is still active and due (a
 * duplicate message or a just-opened on-demand build is skipped), [concurrency]
 * at a time. A failed build backs off [FAILED_RETRY_MS]; the old pins stay.
 */
export async function processBatch(
  uids: string[],
  deps: BatchDeps,
  nowMs: number,
  concurrency = 8,
): Promise<{ built: number; skipped: number; failed: number }> {
  const r = { built: 0, skipped: 0, failed: 0 };
  const queue = [...new Set(uids.filter((u) => typeof u === 'string' && u && !u.includes('/')))];
  const worker = async () => {
    for (;;) {
      const uid = queue.shift();
      if (uid === undefined) return;
      try {
        const doc = await deps.load(uid);
        const due = toMillis(doc?.refreshAfter);
        if (!doc || doc.active !== true || (due != null && due > nowMs + 5 * 60 * 1000)) {
          r.skipped++;
          continue;
        }
        await deps.build(uid, typeof doc.chunkCount === 'number' ? doc.chunkCount : 0);
        r.built++;
      } catch (e) {
        r.failed++;
        console.warn(`world map rebuild failed for ${uid}`, (e as Error)?.message);
        await deps.markFailed(uid).catch(() => undefined);
      }
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, concurrency) }, worker));
  return r;
}
