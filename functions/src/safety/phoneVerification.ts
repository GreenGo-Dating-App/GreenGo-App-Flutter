/**
 * Mandatory verified phone (owner rule 2026-10-17).
 *
 *  - checkPhoneAllowed({phone})   BEFORE the app sends the SMS: supported
 *    country (phoneCountries.ts) and the number is not remembered from a
 *    banned account / not indexed to another live account.
 *  - recordVerifiedPhone()        AFTER the app linked the phone credential
 *    and refreshed its ID token: reads the VERIFIED number from the Auth user
 *    record (never from the client), stores it in profiles_private/{uid}.phone
 *    (owner/admin readable only, never public) and indexes
 *    phone_index/{hmac(e164)} -> {uid} (server-only collection).
 *  - onAuthUserCreatedPhoneRequired  marks NEW accounts (created on/after
 *    16 Oct 2026) in the server-only phone_required/{uid}; the rules require
 *    the phone_number claim only where that marker exists (old accounts are
 *    never required). Backfill: scripts/backfill-phone-required.ts.
 *  - retirePhoneIndexForDeletion  account deletion: a BANNED account's hash is
 *    kept with banned:true (the number can never verify again), otherwise
 *    the index entry is removed.
 *
 * Firebase Auth itself refuses linking a phone that another account already
 * holds (auth/credential-already-in-use). Plaintext numbers are never logged.
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as functionsV1 from 'firebase-functions/v1';
import { PHONE_REQUIRED, phoneRequiredFor } from '../shared/participation';
import '../shared/firebaseAdmin';
import { isBannedState } from '../user_experiences/hostBan';
import { PHONE_INDEX, decidePhone, phoneHash } from './phoneIndexLogic';

const OPTS = { memory: '512MiB' as const, timeoutSeconds: 30 };
const db = () => admin.firestore();

/** Per-instance limiter: N checks per uid per hour (SMS pumping brake). */
const CHECKS_PER_HOUR = 10;
const checkHits = new Map<string, { start: number; n: number }>();
export function takeCheck(uid: string, now = Date.now()): boolean {
  const e = checkHits.get(uid);
  if (!e || now - e.start > 3600_000) {
    checkHits.set(uid, { start: now, n: 1 });
    if (checkHits.size > 50_000) checkHits.clear();
    return true;
  }
  e.n += 1;
  return e.n <= CHECKS_PER_HOUR;
}

/** Banned in any of the shapes the moderation tools write. */
export function isBannedAccount(
  user: Record<string, unknown> | null | undefined,
  profile: Record<string, unknown> | null | undefined,
): boolean {
  if (isBannedState(user) && (user?.accountStatus !== 'suspended')) return true;
  if (isBannedState(profile) && (profile?.accountStatus !== 'suspended')) return true;
  return profile?.status === 'banned';
}

async function indexDocFor(e164: string): Promise<{ ref: admin.firestore.DocumentReference; data: Record<string, unknown> | null }> {
  const ref = db().collection(PHONE_INDEX).doc(phoneHash(e164));
  const snap = await ref.get();
  return { ref, data: snap.exists ? (snap.data() as Record<string, unknown>) : null };
}

/** The owner of an index entry is banned right now (not yet deleted). */
async function ownerBanned(data: Record<string, unknown> | null): Promise<boolean> {
  const owner = typeof data?.uid === 'string' ? data.uid : null;
  if (!owner) return false;
  const [u, p] = await db().getAll(db().collection('users').doc(owner), db().collection('profiles').doc(owner));
  return isBannedAccount(u.data(), p.data());
}

export async function checkPhoneAllowedImpl(uid: string, phone: unknown): Promise<{ allowed: boolean; reason?: string }> {
  const pre = decidePhone(uid, phone, null);
  if (pre.allowed === false) return { allowed: false, reason: pre.reason };
  const { data } = await indexDocFor(phone as string);
  const d = decidePhone(uid, phone, data);
  if (d.allowed === false) return { allowed: false, reason: d.reason };
  if (data && data.uid !== uid && (await ownerBanned(data))) {
    return { allowed: false, reason: 'phone_banned' };
  }
  return { allowed: true };
}

export const checkPhoneAllowed = onCall(OPTS, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.', { code: 'unauthenticated' });
  if (!takeCheck(uid)) {
    throw new HttpsError('resource-exhausted', 'too_many_attempts', { code: 'too_many_attempts' });
  }
  return checkPhoneAllowedImpl(uid, (req.data ?? {}).phone);
});

export async function recordVerifiedPhoneImpl(uid: string): Promise<{ ok: boolean; reason?: string }> {
  const user = await admin.auth().getUser(uid);
  const phone = user.phoneNumber;
  if (!phone) return { ok: false, reason: 'no_verified_phone' };
  const hash = phoneHash(phone);
  const indexRef = db().collection(PHONE_INDEX).doc(hash);
  const privRef = db().collection('profiles_private').doc(uid);
  return db().runTransaction(async (tx) => {
    const [idx, priv] = await Promise.all([tx.get(indexRef), tx.get(privRef)]);
    const d = idx.exists ? (idx.data() as Record<string, unknown>) : null;
    if (d?.banned === true) return { ok: false, reason: 'phone_banned' };
    const oldHash = priv.exists ? priv.get('phoneHash') : null;
    if (typeof oldHash === 'string' && oldHash !== hash) {
      const oldRef = db().collection(PHONE_INDEX).doc(oldHash);
      const old = await tx.get(oldRef);
      if (old.exists && old.get('uid') === uid && old.get('banned') !== true) tx.delete(oldRef);
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    tx.set(indexRef, { uid, verifiedAt: now, released: false }, { merge: true });
    tx.set(privRef, { phone, phoneHash: hash, phoneVerifiedAt: now }, { merge: true });
    return { ok: true };
  });
}

export const recordVerifiedPhone = onCall(OPTS, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.', { code: 'unauthenticated' });
  return recordVerifiedPhoneImpl(uid);
});

/**
 * Account deletion hook (deleteAccountData). Runs BEFORE users / profiles /
 * profiles_private are removed so the ban state and the hash are readable.
 */
export async function retirePhoneIndexForDeletion(uid: string): Promise<'banned' | 'removed' | 'none'> {
  const [u, p, priv] = await db().getAll(
    db().collection('users').doc(uid),
    db().collection('profiles').doc(uid),
    db().collection('profiles_private').doc(uid),
  );
  let hash = typeof priv.get('phoneHash') === 'string' ? (priv.get('phoneHash') as string) : null;
  if (!hash) {
    try {
      const phone = (await admin.auth().getUser(uid)).phoneNumber;
      if (phone) hash = phoneHash(phone);
    } catch {
      // Auth user already gone: nothing else to derive the hash from.
    }
  }
  try {
    await db().collection(PHONE_REQUIRED).doc(uid).delete();
  } catch {
    // best effort: the marker holds no personal data
  }
  if (!hash) return 'none';
  const ref = db().collection(PHONE_INDEX).doc(hash);
  if (isBannedAccount(u.data(), p.data())) {
    // Privacy Policy: the hash of a banned-then-deleted account's number is
    // kept for 5 years (bannedPhoneRetainUntil), then removed by
    // runBannedPhoneSweep (daily, inside sweepIdentityRecords).
    await ref.set(
      {
        banned: true, uid: null, released: true,
        bannedAt: admin.firestore.FieldValue.serverTimestamp(),
        retainUntil: admin.firestore.Timestamp.fromMillis(bannedPhoneRetainUntil(Date.now())),
      },
      { merge: true },
    );
    return 'banned';
  }
  const snap = await ref.get();
  if (snap.exists && snap.get('uid') === uid && snap.get('banned') !== true) {
    await ref.delete();
    return 'removed';
  }
  return 'none';
}

/** Marker doc for an account that must verify a phone (pure helper). */
export function phoneRequiredMarker(createdAtMs: number): Record<string, unknown> | null {
  return phoneRequiredFor(createdAtMs) ? { createdAtMs, reason: 'new_account' } : null;
}

export const onAuthUserCreatedPhoneRequired = functionsV1
  .runWith({ memory: '512MB', timeoutSeconds: 30 })
  .auth.user()
  .onCreate(async (user) => {
    const created = Date.parse(user.metadata?.creationTime ?? '') || Date.now();
    const marker = phoneRequiredMarker(created);
    if (!marker) return;
    await db().collection(PHONE_REQUIRED).doc(user.uid).set(marker, { merge: true });
  });

/** Banned numbers are remembered for 5 years after the account deletion. */
export const BANNED_PHONE_RETENTION_YEARS = 5;

/** Pure: retainUntil (ms) for a banned number deleted at [deletedAtMs]. */
export function bannedPhoneRetainUntil(deletedAtMs: number): number {
  const d = new Date(deletedAtMs);
  d.setUTCFullYear(d.getUTCFullYear() + BANNED_PHONE_RETENTION_YEARS);
  return d.getTime();
}

export interface BannedPhoneSweepDeps {
  /** Up to [limit] phone_index ids with retainUntil <= nowMs. */
  page: (nowMs: number, limit: number) => Promise<string[]>;
  remove: (ids: string[]) => Promise<void>;
}

const defaultBannedSweepDeps: BannedPhoneSweepDeps = {
  page: async (nowMs, limit) => {
    const snap = await db().collection(PHONE_INDEX)
      .where('retainUntil', '<=', admin.firestore.Timestamp.fromMillis(nowMs))
      .limit(limit)
      .get();
    return snap.docs.map((d) => d.id);
  },
  remove: async (ids) => {
    const batch = db().batch();
    for (const id of ids) batch.delete(db().collection(PHONE_INDEX).doc(id));
    await batch.commit();
  },
};

/**
 * Deletes banned-number hashes past their 5-year retention. Paged (300) and
 * bounded (maxPages) - the next daily run continues. Counts-only log.
 */
export async function runBannedPhoneSweep(
  nowMs = Date.now(),
  deps: BannedPhoneSweepDeps = defaultBannedSweepDeps,
  opts: { pageSize?: number; maxPages?: number } = {},
): Promise<{ deleted: number; pages: number }> {
  const pageSize = opts.pageSize ?? 300;
  const maxPages = opts.maxPages ?? 50;
  let deleted = 0;
  let pages = 0;
  while (pages < maxPages) {
    const ids = await deps.page(nowMs, pageSize);
    if (ids.length === 0) break;
    await deps.remove(ids);
    deleted += ids.length;
    pages++;
    if (ids.length < pageSize) break;
  }
  if (deleted > 0) console.log(`bannedPhoneSweep: deleted=${deleted} pages=${pages}`);
  return { deleted, pages };
}
