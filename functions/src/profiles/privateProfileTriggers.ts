/**
 * Cloud Functions for the private profile split. Logic lives in
 * ./privateProfile.ts (pure helpers + transactional sync); see the header
 * there for the data model and the no-loop argument.
 *
 * Deploy:  mirrorPrivateProfileFields, syncCoarseFromPrivateProfile,
 *          refreshBirthdayAges, getVerificationPhotoUrl
 */

import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { requireAdmin, MODERATION_ROLES } from '../shared/adminAuth';
import { AppError, handleError } from '../shared/utils';
import {
  PRIVATE_PROFILES,
  SENSITIVE_FIELDS,
  ageFrom,
  dateOfBirthOf,
  handlePrivateProfileWrite,
  handlePublicProfileWrite,
  syncProfile,
} from './privateProfile';

/**
 * profiles/{uid} written. Most writes (presence, counters) touch no watched
 * field and return before any read. 512MiB: the bundle needs ~200MB to load.
 */
export const mirrorPrivateProfileFields = onDocumentWritten(
  { document: 'profiles/{uid}', memory: '512MiB' },
  async (event) => {
    const uid = event.params.uid as string;
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    await handlePublicProfileWrite(uid, before, after);
  },
);

/** profiles_private/{uid} written (new app versions write only here). */
export const syncCoarseFromPrivateProfile = onDocumentWritten(
  { document: `${PRIVATE_PROFILES}/{uid}`, memory: '512MiB' },
  async (event) => {
    const uid = event.params.uid as string;
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    await handlePrivateProfileWrite(uid, before, after);
  },
);

/** Today's 'MM-DD' keys (UTC); Feb 29 birthdays age on Mar 1 in common years. */
export function birthdayKeysFor(now: Date): string[] {
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  const keys = [`${mm}-${dd}`];
  const y = now.getUTCFullYear();
  const leap = (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
  if (!leap && mm === '03' && dd === '01') keys.push('02-29');
  return keys;
}

/**
 * Updates the public `age` of everyone whose birthday is [now]. Paged by
 * document id over an equality query (single-field index, no composite);
 * each page reads the matching public docs with one getAll and commits one
 * batch of the ages that actually changed.
 */
export async function runBirthdayAgeRefresh(
  now: Date = new Date(),
  opts: { firestore?: admin.firestore.Firestore; pageSize?: number } = {},
): Promise<{ scanned: number; updated: number }> {
  const fs = opts.firestore ?? admin.firestore();
  const pageSize = Math.min(opts.pageSize ?? 300, 400);
  let scanned = 0;
  let updated = 0;
  for (const key of birthdayKeysFor(now)) {
    let cursor: string | null = null;
    for (;;) {
      let q = fs.collection(PRIVATE_PROFILES)
        .where('birthMonthDay', '==', key)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(pageSize);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.get();
      if (snap.empty) break;
      const pubSnaps = await fs.getAll(...snap.docs.map((d) => fs.collection('profiles').doc(d.id)));
      const batch = fs.batch();
      let writes = 0;
      snap.docs.forEach((d, i) => {
        scanned++;
        const pub = pubSnaps[i];
        if (!pub.exists) return;
        const age = ageFrom(dateOfBirthOf(pub.data(), d.data()), now);
        if (age !== null && pub.data()?.age !== age) {
          batch.update(pub.ref, { age });
          writes++;
        }
      });
      if (writes) await batch.commit();
      updated += writes;
      cursor = snap.docs[snap.docs.length - 1].id;
      if (snap.size < pageSize) break;
    }
  }
  return { scanned, updated };
}

export const refreshBirthdayAges = onSchedule(
  { schedule: '15 0 * * *', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const r = await runBirthdayAgeRefresh();
    console.log(`refreshBirthdayAges: ${JSON.stringify(r)}`);
  },
);

const SIGNED_URL_TTL_MS = 10 * 60 * 1000;

/**
 * Admin-only: a short-lived read URL for a user's ID-verification selfie.
 *
 * The app now stores only the Storage PATH (profiles_private.verificationPhotoPath);
 * nothing world-readable carries a tokenized download URL any more. Older
 * submissions only have the legacy URL, returned as-is (source 'legacy').
 *
 * Roles: MODERATION_ROLES (superAdmin, moderator). Reviewing an identity
 * selfie is a moderation decision; support/analyst have no reason to see it.
 *
 * IAM: getSignedUrl() signs with the runtime service account through the
 * IAM signBlob API, so that account needs roles/iam.serviceAccountTokenCreator
 * on itself in production (console action, once).
 */
export const getVerificationPhotoUrl = onCall({ memory: '512MiB' }, async (request) => {
  try {
    await requireAdmin(request.auth as any, MODERATION_ROLES);
    const uid = String((request.data as any)?.uid ?? '').trim();
    if (!uid || uid.includes('/')) throw new AppError('invalid-argument', 'uid is required', 400);
    const result = await resolveVerificationPhotoUrl(uid);
    console.log(`getVerificationPhotoUrl: admin=${request.auth?.uid} uid=${uid} source=${result.source}`);
    return result;
  } catch (e: any) {
    if (e instanceof HttpsError) throw e; // requireAdmin's own errors
    throw handleError(e);
  }
});

export async function resolveVerificationPhotoUrl(
  uid: string,
  opts: { firestore?: admin.firestore.Firestore; sign?: (path: string, expires: number) => Promise<string> } = {},
): Promise<{ url: string | null; expiresAt: number | null; source: 'path' | 'legacy' | 'none' }> {
  const fs = opts.firestore ?? admin.firestore();
  const [privSnap, pubSnap] = await fs.getAll(
    fs.collection(PRIVATE_PROFILES).doc(uid),
    fs.collection('profiles').doc(uid),
  );
  const priv = privSnap.data() ?? {};
  const pub = pubSnap.data() ?? {};
  const path = typeof priv.verificationPhotoPath === 'string' ? priv.verificationPhotoPath : '';
  if (path) {
    // New uploads: verifications/{uid}/ (owner + admin read). Older app
    // versions uploaded to profiles/{uid}/verifications/ (see lockdown doc).
    const inUserFolder = path.startsWith(`verifications/${uid}/`)
      || path.startsWith(`profiles/${uid}/verifications/`);
    if (!inUserFolder || path.includes('..')) {
      throw new AppError('failed-precondition', 'Stored verification path is not in the user folder', 400);
    }
    const expires = Date.now() + SIGNED_URL_TTL_MS;
    const sign = opts.sign ?? (async (p: string, exp: number) => {
      const [url] = await admin.storage().bucket().file(p).getSignedUrl({ version: 'v4', action: 'read', expires: exp });
      return url;
    });
    return { url: await sign(path, expires), expiresAt: expires, source: 'path' };
  }
  const legacy = [priv.verificationPhotoUrl, pub.verificationPhotoUrl].find((u) => typeof u === 'string' && u);
  if (legacy) return { url: legacy, expiresAt: null, source: 'legacy' };
  return { url: null, expiresAt: null, source: 'none' };
}

// ---------------------------------------------------------------------------
// Backfill core (used by scripts/backfill-profiles-private.ts)
// ---------------------------------------------------------------------------

export interface PrivateBackfillResult {
  scanned: number;
  privateWrites: number;
  publicWrites: number;
  done: boolean;
  /** Only a hint for continuing; restarting without it is always correct. */
  startAfter: string | null;
  dryRun: boolean;
}

/**
 * Scans `profiles` in document-id order and, per doc, fills the private copy
 * (missing fields only: a new-app user's private value is newer than its
 * stale public one) and the public coarse fields. Nothing is saved between
 * runs, so an interrupted run is resumed by simply running again: docs that
 * are already correct are read but not written.
 */
export async function runPrivateProfileBackfill(opts: {
  firestore?: admin.firestore.Firestore;
  startAfter?: string | null;
  pageSize?: number;
  maxPages?: number;
  dryRun?: boolean;
  concurrency?: number;
  onPage?: (r: PrivateBackfillResult) => void;
} = {}): Promise<PrivateBackfillResult> {
  const fs = opts.firestore ?? admin.firestore();
  const pageSize = Math.min(Math.max(opts.pageSize ?? 300, 1), 400);
  const maxPages = opts.maxPages ?? Number.MAX_SAFE_INTEGER;
  const conc = Math.max(1, opts.concurrency ?? 10);
  const res: PrivateBackfillResult = {
    scanned: 0, privateWrites: 0, publicWrites: 0, done: false,
    startAfter: opts.startAfter ?? null, dryRun: opts.dryRun === true,
  };
  let pages = 0;
  for (;;) {
    let q = fs.collection('profiles').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (res.startAfter) q = q.startAfter(res.startAfter);
    const snap = await q.select().get(); // ids only; syncProfile reads in its transaction
    if (snap.empty) { res.done = true; res.startAfter = null; return res; }
    const ids = snap.docs.map((d) => d.id);
    for (let i = 0; i < ids.length; i += conc) {
      const out = await Promise.all(ids.slice(i, i + conc).map((id) =>
        syncProfile(id, SENSITIVE_FIELDS, { firestore: fs, dryRun: res.dryRun, fillMissingOnly: true })));
      for (const r of out) { res.privateWrites += r.privateWrites; res.publicWrites += r.publicWrites; }
    }
    res.scanned += ids.length;
    res.startAfter = ids[ids.length - 1];
    pages++;
    opts.onPage?.({ ...res });
    if (snap.size < pageSize) { res.done = true; res.startAfter = null; return res; }
    if (pages >= maxPages) return res;
  }
}

// ---------------------------------------------------------------------------
// Private album (privatePhotoUrls now lives in profiles_private)
// ---------------------------------------------------------------------------

/**
 * Photo URLs of [ownerId]'s private album for [callerUid]: allowed for the
 * owner, or when an album_access doc {ownerId, grantedToId: caller} exists
 * (two equality filters: served by single-field indexes, the same query the
 * app already runs). Private copy first, legacy public field second.
 */
/**
 * Storage object path of a private-album photo download URL, but ONLY when
 * the object is in the OWNER's own folder (`profiles/{ownerId}/...`) and, if
 * [bucket] is given, in that bucket. Anything else (external URL, another
 * user's folder, ID selfies under `verifications/`) is null and never signed:
 * an owner must not be able to turn their album into a signer for someone
 * else's files.
 */
export function albumObjectPath(url: unknown, ownerId: string, bucket?: string | null): string | null {
  if (typeof url !== 'string' || !url || url.length > 2048) return null;
  let path: string;
  try {
    const u = new URL(url);
    if (u.hostname !== 'firebasestorage.googleapis.com') return null;
    const m = u.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
    if (!m) return null;
    if (bucket && decodeURIComponent(m[1]) !== bucket) return null;
    path = decodeURIComponent(m[2]);
  } catch {
    return null;
  }
  if (!path || path.includes('..') || path.includes('\\') || !path.startsWith(`profiles/${ownerId}/`)) return null;
  return path;
}

/** Lifetime of the signed URLs getSharedAlbum hands to a grantee. */
export const ALBUM_URL_TTL_MS = 10 * 60 * 1000;

function defaultBucketName(): string | null {
  try {
    return admin.storage().bucket().name || null;
  } catch {
    return null;
  }
}

/**
 * Replaces each Storage download URL (permanent bearer token) by a V4 signed
 * URL valid [ALBUM_URL_TTL_MS]: a grantee who copies a URL out of the app can
 * use it for minutes, not forever, and a revoked grant stops working once the
 * last URL expires. Signing failures (missing iam.serviceAccounts.signBlob on
 * the runtime service account) fall back to the stored URL, i.e. exactly the
 * previous behaviour. The app caches by object path (stableMediaCacheKey), so
 * changing signatures do not defeat its image cache.
 */
export async function signAlbumUrls(
  urls: string[],
  ownerId: string,
  opts: { sign?: (path: string, expires: number) => Promise<string>; bucket?: string | null; now?: number } = {},
): Promise<string[]> {
  const bucket = opts.bucket === undefined ? defaultBucketName() : opts.bucket;
  if (!opts.sign && !bucket) return urls; // no bucket configured (tests/emulator)
  const expires = (opts.now ?? Date.now()) + ALBUM_URL_TTL_MS;
  const sign = opts.sign ?? (async (p: string, exp: number) => {
    const [signed] = await admin.storage().bucket().file(p).getSignedUrl({ version: 'v4', action: 'read', expires: exp });
    return signed;
  });
  let warned = false;
  return Promise.all(urls.map(async (url) => {
    const path = albumObjectPath(url, ownerId, bucket);
    if (!path) return url;
    try {
      return await sign(path, expires);
    } catch (e: any) {
      if (!warned) {
        warned = true;
        console.warn('getSharedAlbum: URL signing failed, serving stored URLs', e?.message || e);
      }
      return url;
    }
  }));
}

export async function resolveSharedAlbum(
  callerUid: string,
  ownerId: string,
  opts: {
    firestore?: admin.firestore.Firestore;
    sign?: (path: string, expires: number) => Promise<string>;
    bucket?: string | null;
  } = {},
): Promise<{ photoUrls: string[] }> {
  const fs = opts.firestore ?? admin.firestore();
  if (callerUid !== ownerId) {
    const grant = await fs.collection('album_access')
      .where('ownerId', '==', ownerId)
      .where('grantedToId', '==', callerUid)
      .limit(1)
      .get();
    if (grant.empty) throw new AppError('permission-denied', 'No access to this album', 403);
  }
  const [privSnap, pubSnap] = await fs.getAll(
    fs.collection(PRIVATE_PROFILES).doc(ownerId),
    fs.collection('profiles').doc(ownerId),
  );
  const list = (v: any) => (Array.isArray(v) ? v.filter((x) => typeof x === 'string') : null);
  const stored = list(privSnap.data()?.privatePhotoUrls) ?? list(pubSnap.data()?.privatePhotoUrls) ?? [];
  // The owner reads their own album straight from profiles_private; a
  // grantee only ever receives short-lived URLs.
  if (callerUid === ownerId) return { photoUrls: stored };
  const photoUrls = await signAlbumUrls(stored, ownerId, { sign: opts.sign, bucket: opts.bucket });
  return { photoUrls };
}

export const getSharedAlbum = onCall({ memory: '512MiB' }, async (request) => {
  try {
    const caller = request.auth?.uid;
    if (!caller) throw new AppError('unauthenticated', 'Sign in required', 401);
    const ownerId = String((request.data as any)?.ownerId ?? '').trim();
    if (!ownerId || ownerId.includes('/')) throw new AppError('invalid-argument', 'ownerId is required', 400);
    return await resolveSharedAlbum(caller, ownerId);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw handleError(e);
  }
});
