/**
 * Community ownership transfer (owner request 2026-10-21: "for a community, I
 * need to be able to transfer the community to another user; need password to
 * certify that").
 *
 * Flow:
 *  1. The CREATOR (communities/{id}.createdByUserId) re-enters their password
 *     in the app (Google / Apple accounts sign in with their provider again)
 *     and calls requestCommunityTransfer({communityId, toUserId}). The
 *     server-side proof of that password is the ID token's `auth_time`: it must
 *     be at most RECENT_AUTH_SECONDS old.
 *  2. A pending offer is written to community_transfers/{communityId} (one per
 *     community; clients can read their own, never write) and the target gets
 *     a notification (in-app + push, localized).
 *  3. The target accepts or declines (respondCommunityTransfer). Nobody gets
 *     ownership forced on them. On accept, in ONE transaction: the community's
 *     createdByUserId / createdByName move to the new owner, the new owner's
 *     member role becomes `owner`, the old owner's becomes `admin` (they stay a
 *     member and can leave later), a sponsorship of the old owner's business
 *     ends, an audit record is written and the offer is removed.
 *  4. The owner can cancel (cancelCommunityTransfer); offers expire after
 *     TRANSFER_TTL_MS (expireCommunityTransfers job + lazily on any call).
 *
 * The 5.0.50 rules keep createdByUserId immutable from clients, so this module
 * (Admin SDK) is the ONLY way ownership changes.
 */

import * as admin from 'firebase-admin';
import { HttpsError, FunctionsErrorCode } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { emitNotification, resolveActor, Actor } from '../notifications/notifyHelpers';
import { LText, lt } from '../shared/i18n';

export const TRANSFERS = 'community_transfers';
export const COMMUNITY_AUDIT = 'community_audit';
/** An offer stays open for 7 days. */
export const TRANSFER_TTL_MS = 7 * 24 * 60 * 60 * 1000;
/** The owner must have signed in (password / provider) within 5 minutes. */
export const RECENT_AUTH_SECONDS = 5 * 60;
/** Expiry job page size. */
const EXPIRE_BATCH = 200;

export type TransferRefusal =
  | 'requires_recent_login'
  | 'invalid_argument'
  | 'community_not_found'
  | 'not_creator'
  | 'self_transfer'
  | 'target_not_member'
  | 'target_unavailable'
  | 'transfer_pending'
  | 'owner_limit_reached'
  | 'no_pending_transfer'
  | 'transfer_expired';

export interface TransferNotifyParams {
  recipientId: string;
  type: string;
  title: LText;
  body: LText;
  data: Record<string, string>;
  actor?: Actor;
}

/**
 * Overridable in unit tests; production uses the defaults.
 *
 * [ownedCommunityCap]: how many communities a profile may OWN (null =
 * unlimited). No membership tier caps communities today (createCommunity has
 * no limit: shared/tierLimits.ts has no community entry), so the default is
 * unlimited; the check is in place for when a cap is introduced.
 */
export const transferDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  now: (): Date => new Date(),
  notify: (p: TransferNotifyParams): Promise<void> => emitNotification(p),
  actor: (uid: string): Promise<Actor> => resolveActor(uid),
  /** True when the Firebase Auth account is disabled or gone. */
  authUnavailable: async (uid: string): Promise<boolean> => {
    try {
      return (await admin.auth().getUser(uid)).disabled === true;
    } catch {
      return true;
    }
  },
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  ownedCommunityCap: (_profile: Record<string, unknown> | undefined): number | null => null,
};

const fdb = () => transferDeps.db();
const nowMs = () => transferDeps.now().getTime();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

function fail(code: FunctionsErrorCode, reason: TransferRefusal, extra: Record<string, unknown> = {}): never {
  throw new HttpsError(code, reason, { code: reason, ...extra });
}

function msOf(v: unknown): number | null {
  if (!v) return null;
  if (typeof (v as { toMillis?: unknown }).toMillis === 'function') {
    return (v as { toMillis: () => number }).toMillis();
  }
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return v;
  return null;
}

function docId(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const id = v.trim();
  if (!id || id.length > 128 || id.includes('/') || id === '.' || id === '..' || /^__.*__$/.test(id)) {
    return null;
  }
  return id;
}

/** True when the ID token proves a sign-in within [RECENT_AUTH_SECONDS]. */
export function isRecentAuth(authTime: unknown, now: Date = transferDeps.now()): boolean {
  const t = Number(authTime);
  return Number.isFinite(t) && t > 0 && now.getTime() / 1000 - t <= RECENT_AUTH_SECONDS;
}

/**
 * Whether the community currently carries a sponsorship of [ownerId]'s
 * business. Sponsorship is set only by the creator (the app writes
 * sponsorId = creator uid), so a sponsored doc without a sponsorId is the
 * creator's too. A sponsorId of somebody else is left alone.
 */
export function sponsoredByOwner(community: Record<string, any>, ownerId: string): boolean {
  const sponsored = community.isSponsored === true
    || (community.pinnedPromo !== null && community.pinnedPromo !== undefined)
    || (typeof community.sponsorId === 'string' && community.sponsorId !== '');
  if (!sponsored) return false;
  const sid = typeof community.sponsorId === 'string' ? community.sponsorId : '';
  return sid === '' || sid === ownerId;
}

/** Either user blocked the other (root blockedUsers + the profile block list). */
async function blockedEitherWay(a: string, b: string): Promise<boolean> {
  const db = fdb();
  const [ab, ba, pa, pb] = await Promise.all([
    db.collection('blockedUsers').where('blockerId', '==', a).where('blockedUserId', '==', b).limit(1).get(),
    db.collection('blockedUsers').where('blockerId', '==', b).where('blockedUserId', '==', a).limit(1).get(),
    db.collection('profiles').doc(a).collection('blocked_users').doc(b).get(),
    db.collection('profiles').doc(b).collection('blocked_users').doc(a).get(),
  ]);
  return !ab.empty || !ba.empty || pa.exists || pb.exists;
}

/**
 * The target must be a real, active personal account: a profile exists, the
 * account is not suspended / deleted (users/{uid}.accountStatus) nor disabled
 * in Firebase Auth, and it is not a business storefront identity (those can
 * never be community members).
 */
async function targetUnavailable(uid: string): Promise<boolean> {
  const db = fdb();
  const [profile, user] = await Promise.all([
    db.collection('profiles').doc(uid).get(),
    db.collection('users').doc(uid).get(),
  ]);
  if (!profile.exists) return true;
  if (profile.data()?.isBusiness === true) return true;
  const status = String(user.data()?.accountStatus ?? 'active');
  if (status === 'suspended' || status === 'deleted' || status === 'banned') return true;
  return transferDeps.authUnavailable(uid);
}

/** Refuse when [uid]'s plan caps owned communities and they are at the cap. */
async function assertUnderOwnerCap(uid: string): Promise<void> {
  const db = fdb();
  const profile = (await db.collection('profiles').doc(uid).get()).data();
  const cap = transferDeps.ownedCommunityCap(profile);
  if (cap === null || cap === undefined) return;
  const owned = await db.collection('communities').where('createdByUserId', '==', uid).limit(cap).get();
  if (owned.size >= cap) fail('failed-precondition', 'owner_limit_reached', { cap });
}

function displayName(member: Record<string, any> | undefined, actor: Actor | undefined): string {
  const fromMember = typeof member?.displayName === 'string' ? member.displayName.trim() : '';
  if (fromMember) return fromMember.slice(0, 80);
  if (actor && !actor.unknown && actor.name) return actor.name.slice(0, 80);
  return '';
}

async function safeNotify(p: TransferNotifyParams): Promise<void> {
  try {
    await transferDeps.notify(p);
  } catch (e) {
    console.error(`[communityTransfer] notify ${p.type} -> ${p.recipientId} failed:`, e);
  }
}

async function safeActor(uid: string): Promise<Actor | undefined> {
  try {
    return await transferDeps.actor(uid);
  } catch {
    return undefined;
  }
}

function audit(
  tx: FirebaseFirestore.Transaction | FirebaseFirestore.WriteBatch,
  action: 'requested' | 'accepted' | 'declined' | 'cancelled' | 'expired',
  t: Record<string, any>,
  byUserId: string,
  extra: Record<string, unknown> = {},
): void {
  const ref = fdb().collection(COMMUNITY_AUDIT).doc();
  (tx as FirebaseFirestore.Transaction).set(ref, {
    kind: 'ownership_transfer',
    action,
    communityId: t.communityId,
    fromUserId: t.fromUserId,
    toUserId: t.toUserId,
    byUserId,
    at: ts(nowMs()),
    ...extra,
  });
}

// ─────────────────────────────────────────────────────────── request

export async function requestCommunityTransfer(
  uid: string,
  authTime: unknown,
  data: any,
): Promise<Record<string, unknown>> {
  if (!isRecentAuth(authTime)) {
    fail('unauthenticated', 'requires_recent_login', { maxAgeSeconds: RECENT_AUTH_SECONDS });
  }
  const communityId = docId(data?.communityId);
  const toUserId = docId(data?.toUserId);
  if (!communityId || !toUserId) fail('invalid-argument', 'invalid_argument');
  if (toUserId === uid) fail('invalid-argument', 'self_transfer');

  const db = fdb();
  const communityRef = db.collection('communities').doc(communityId);
  const targetMemberRef = communityRef.collection('members').doc(toUserId);
  const transferRef = db.collection(TRANSFERS).doc(communityId);

  // Cheap refusals first (outside the transaction: they read other users'
  // profiles / block lists, which the transaction does not need to lock).
  const pre = await communityRef.get();
  if (!pre.exists) fail('not-found', 'community_not_found');
  if (pre.data()?.createdByUserId !== uid) fail('permission-denied', 'not_creator');
  if (await targetUnavailable(toUserId)) fail('failed-precondition', 'target_unavailable');
  if (await blockedEitherWay(uid, toUserId)) fail('failed-precondition', 'target_unavailable');
  await assertUnderOwnerCap(toUserId);

  const [fromActor, toActor] = await Promise.all([safeActor(uid), safeActor(toUserId)]);
  const now = nowMs();
  const expiresAtMs = now + TRANSFER_TTL_MS;

  const result = await db.runTransaction(async (tx) => {
    const [cSnap, mSnap, ownSnap, tSnap] = await Promise.all([
      tx.get(communityRef),
      tx.get(targetMemberRef),
      tx.get(communityRef.collection('members').doc(uid)),
      tx.get(transferRef),
    ]);
    if (!cSnap.exists) fail('not-found', 'community_not_found');
    const c = cSnap.data() || {};
    if (c.createdByUserId !== uid) fail('permission-denied', 'not_creator');
    const m = mSnap.data();
    if (!mSnap.exists || m?.isBanned === true) fail('failed-precondition', 'target_not_member');
    if (tSnap.exists) {
      const exp = msOf(tSnap.data()?.expiresAt);
      if (exp === null || exp > now) fail('failed-precondition', 'transfer_pending');
      // An expired offer the job has not swept yet is simply replaced.
    }
    const t = {
      communityId,
      communityName: typeof c.name === 'string' ? c.name.slice(0, 120) : '',
      fromUserId: uid,
      fromName: displayName(ownSnap.data(), fromActor) || String(c.createdByName ?? ''),
      toUserId,
      toName: displayName(m, toActor),
      status: 'pending',
      sponsorshipWillEnd: sponsoredByOwner(c, uid),
      createdAt: ts(now),
      expiresAt: ts(expiresAtMs),
    };
    tx.set(transferRef, t);
    audit(tx, 'requested', t, uid);
    return t;
  });

  await safeNotify({
    recipientId: toUserId,
    type: 'community_transfer_offer',
    title: lt('srvCommunityTransferOfferTitle'),
    body: lt('srvCommunityTransferOfferBody', { community: result.communityName }),
    data: {
      action: 'community_transfer_offer',
      communityId,
      communityName: result.communityName,
    },
    actor: fromActor,
  });

  return {
    success: true,
    communityId,
    toUserId,
    expiresAt: expiresAtMs,
    sponsorshipWillEnd: result.sponsorshipWillEnd,
  };
}

// ─────────────────────────────────────────────────────────── respond

export async function respondCommunityTransfer(uid: string, data: any): Promise<Record<string, unknown>> {
  const communityId = docId(data?.communityId);
  if (!communityId || typeof data?.accept !== 'boolean') fail('invalid-argument', 'invalid_argument');
  const accept = data.accept === true;

  const db = fdb();
  const communityRef = db.collection('communities').doc(communityId);
  const transferRef = db.collection(TRANSFERS).doc(communityId);

  // Plan cap of the NEW owner (checked again at accept time: their plan may
  // have changed since the offer).
  if (accept) {
    const pre = (await transferRef.get()).data();
    if (pre?.toUserId === uid) await assertUnderOwnerCap(uid);
  }
  const actor = await safeActor(uid);

  let expired = false;
  let stale = false;
  const out = await db.runTransaction(async (tx) => {
    const tSnap = await tx.get(transferRef);
    const t = tSnap.data();
    if (!tSnap.exists || !t || t.toUserId !== uid || t.status !== 'pending') {
      fail('failed-precondition', 'no_pending_transfer');
    }
    const [cSnap, newSnap, oldSnap] = await Promise.all([
      tx.get(communityRef),
      tx.get(communityRef.collection('members').doc(uid)),
      tx.get(communityRef.collection('members').doc(String(t.fromUserId))),
    ]);
    const exp = msOf(t.expiresAt);
    if (exp !== null && exp <= nowMs()) {
      expired = true;
      tx.delete(transferRef);
      audit(tx, 'expired', t, uid);
      return t;
    }
    const c = cSnap.data();
    // The community is gone, or its owner changed some other way: the offer
    // no longer stands.
    if (!cSnap.exists || !c || c.createdByUserId !== t.fromUserId) {
      stale = true;
      tx.delete(transferRef);
      audit(tx, 'cancelled', t, uid, { reason: 'stale' });
      return t;
    }
    if (!accept) {
      tx.delete(transferRef);
      audit(tx, 'declined', t, uid);
      return t;
    }
    const me = newSnap.data();
    if (!newSnap.exists || me?.isBanned === true) {
      tx.delete(transferRef);
      audit(tx, 'cancelled', t, uid, { reason: 'target_not_member' });
      stale = true;
      return t;
    }

    const newName = displayName(me, actor) || String(t.toName || '');
    const endSponsorship = sponsoredByOwner(c, String(t.fromUserId));
    const update: Record<string, unknown> = {
      createdByUserId: uid,
      createdByName: newName,
      previousOwnerId: t.fromUserId,
      ownerTransferredAt: ts(nowMs()),
    };
    if (endSponsorship) {
      update.isSponsored = false;
      update.sponsorId = null;
      update.pinnedPromo = null;
    }
    tx.update(communityRef, update);
    tx.update(newSnap.ref, {
      role: 'owner',
      ...(newName && !(typeof me?.displayName === 'string' && me.displayName.trim()) ? { displayName: newName } : {}),
    });
    if (oldSnap.exists) tx.update(oldSnap.ref, { role: 'admin' });
    tx.delete(transferRef);
    audit(tx, 'accepted', t, uid, { sponsorshipEnded: endSponsorship });
    return { ...t, sponsorshipEnded: endSponsorship };
  });

  if (expired) fail('failed-precondition', 'transfer_expired');
  if (stale) fail('failed-precondition', 'no_pending_transfer');

  const name = String(out.communityName || '');
  await safeNotify({
    recipientId: String(out.fromUserId),
    type: accept ? 'community_transfer_accepted' : 'community_transfer_declined',
    title: lt(accept ? 'srvCommunityTransferAcceptedTitle' : 'srvCommunityTransferDeclinedTitle'),
    body: lt(accept ? 'srvCommunityTransferAcceptedBody' : 'srvCommunityTransferDeclinedBody', { community: name }),
    data: { action: 'open_community', communityId, communityName: name },
    actor,
  });

  return {
    success: true,
    communityId,
    accepted: accept,
    ...(accept ? { sponsorshipEnded: (out as any).sponsorshipEnded === true } : {}),
  };
}

// ─────────────────────────────────────────────────────────── cancel

export async function cancelCommunityTransfer(uid: string, data: any): Promise<Record<string, unknown>> {
  const communityId = docId(data?.communityId);
  if (!communityId) fail('invalid-argument', 'invalid_argument');
  const db = fdb();
  const transferRef = db.collection(TRANSFERS).doc(communityId);
  await db.runTransaction(async (tx) => {
    const tSnap = await tx.get(transferRef);
    const t = tSnap.data();
    if (!tSnap.exists || !t || t.fromUserId !== uid) fail('failed-precondition', 'no_pending_transfer');
    tx.delete(transferRef);
    audit(tx, 'cancelled', t, uid);
  });
  return { success: true, communityId };
}

// ─────────────────────────────────────────────────────────── expiry job

/** Removes offers past expiresAt and tells their owners. Returns the count. */
export async function expireDueTransfers(): Promise<number> {
  const db = fdb();
  const due = await db.collection(TRANSFERS)
    .where('expiresAt', '<=', ts(nowMs()))
    .limit(EXPIRE_BATCH)
    .get();
  let n = 0;
  for (const d of due.docs) {
    const t = await db.runTransaction(async (tx) => {
      const snap = await tx.get(d.ref);
      const cur = snap.data();
      const exp = msOf(cur?.expiresAt);
      if (!snap.exists || !cur || exp === null || exp > nowMs()) return null;
      tx.delete(d.ref);
      audit(tx, 'expired', cur, 'system');
      return cur;
    });
    if (!t) continue;
    n++;
    await safeNotify({
      recipientId: String(t.fromUserId),
      type: 'community_transfer_expired',
      title: lt('srvCommunityTransferExpiredTitle'),
      body: lt('srvCommunityTransferExpiredBody', { community: String(t.communityName || '') }),
      data: { action: 'open_community', communityId: String(t.communityId) },
    });
  }
  return n;
}
