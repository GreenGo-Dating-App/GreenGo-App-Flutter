/**
 * Admin-panel user actions (security Phase 1, P1-6 / audit H-29).
 *
 * The admin panel used to write `coinBalances`, `profiles` and its own
 * `admin_actions` audit log straight from the browser. The coin writes were
 * denied by the rules (or landed in the phantom snake_case `coin_balances`
 * that no client reads), the profile writes relied on a broad admin rule, and
 * the audit log was whatever the browser chose to write. Each of those writes
 * is now one of these callables: the role check, the validation and the audit
 * entry (`admin_audit_log` + the legacy `admin_actions`) happen server-side.
 *
 * Roles (shared/adminAuth.ts):
 *   - account status, basic profile fields, verification  -> superAdmin | moderator
 *   - coins, tiers / entitlements, test users, user notifications -> superAdmin
 *     (superAdmin-only checks also require a fresh admin 2FA once
 *     app_config/security_flags.requireAdmin2fa is switched on)
 *
 * Existing callables are reused where they already match the data model the
 * app reads (adminDeleteUser, forcePasswordChange, adminChangeUserPassword,
 * sendPasswordResetEmail). userManagement.ts's adjustUserCoins /
 * editUserProfile / banUserAccount write `coin_balances` / `users`, which the
 * panel and the app do not read for these fields, so they are not used here.
 */

import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  AdminIdentity,
  MODERATION_ROLES,
  requireAdmin,
  rolesForPermission,
  SUPER_ADMIN_ONLY,
} from '../shared/adminAuth';
import { deductFromBatches } from '../coins/purchaseClawback';

const db = () => admin.firestore();
const OPTS = { memory: '512MiB' as const, timeoutSeconds: 120 };

const MAX_COIN_ADJUSTMENT = 1_000_000;
const MAX_BULK = 100;
export const PANEL_TIERS = ['FREE', 'BASIC', 'SILVER', 'GOLD', 'PLATINUM', 'TEST'] as const;
const PAID_TIERS = new Set(['SILVER', 'GOLD', 'PLATINUM']);
const VERIFICATION_STATUSES = new Set([
  'unverified', 'pending', 'approved', 'verified', 'rejected', 'needsResubmission',
]);

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

function str(v: unknown, field: string, opts: { min?: number; max: number; optional?: boolean }): string | undefined {
  if (v === undefined || v === null) {
    if (opts.optional) return undefined;
    throw new HttpsError('invalid-argument', `${field} is required`);
  }
  if (typeof v !== 'string') throw new HttpsError('invalid-argument', `${field} must be a string`);
  const t = v.trim();
  if (t.length < (opts.min ?? 0)) throw new HttpsError('invalid-argument', `${field} is too short`);
  if (t.length > opts.max) throw new HttpsError('invalid-argument', `${field} must be at most ${opts.max} characters`);
  return t;
}

function userIdOf(data: any): string {
  const uid = str(data?.userId, 'userId', { min: 1, max: 128 })!;
  if (uid.includes('/')) throw new HttpsError('invalid-argument', 'userId is invalid');
  return uid;
}

/** ISO string / epoch ms / null -> Timestamp | null. undefined -> undefined. */
function tsOrNull(v: unknown, field: string): admin.firestore.Timestamp | null | undefined {
  if (v === undefined) return undefined;
  if (v === null || v === '') return null;
  const d = typeof v === 'number' ? new Date(v) : typeof v === 'string' ? new Date(v) : null;
  if (!d || isNaN(d.getTime())) throw new HttpsError('invalid-argument', `${field} must be an ISO date or null`);
  return admin.firestore.Timestamp.fromDate(d);
}

async function requireProfile(uid: string): Promise<admin.firestore.DocumentSnapshot> {
  const snap = await db().collection('profiles').doc(uid).get();
  if (!snap.exists) throw new HttpsError('not-found', 'User profile not found');
  return snap;
}

/** Another admin can only be acted on by a superAdmin. */
async function guardAdminTarget(caller: AdminIdentity, targetUid: string): Promise<void> {
  if (caller.role === 'superAdmin') return;
  const t = await db().collection('admin_users').doc(targetUid).get();
  if (t.exists) throw new HttpsError('permission-denied', 'Only a superAdmin can act on an admin account');
}

/** Server-side audit entry (admin_audit_log) plus the legacy admin_actions row the panel lists. */
export async function auditPanelAction(
  caller: AdminIdentity,
  action: string,
  targetUid: string | null,
  details: Record<string, unknown>
): Promise<void> {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const adminDoc = await db().collection('admin_users').doc(caller.uid).get();
  const batch = db().batch();
  batch.set(db().collection('admin_audit_log').doc(), {
    adminId: caller.uid,
    adminEmail: adminDoc.data()?.email ?? null,
    adminRole: caller.role,
    action,
    targetType: 'user',
    targetId: targetUid,
    details,
    source: 'admin_panel_callable',
    timestamp: now,
  });
  batch.set(db().collection('admin_actions').doc(), {
    action,
    userId: targetUid,
    performedBy: caller.uid,
    ...details,
    timestamp: now,
  });
  await batch.commit();
}

// ---------------------------------------------------------------------------
// coins
// ---------------------------------------------------------------------------

/**
 * Add (amount > 0) or remove (amount < 0) coins. `kind: 'videoCoins'` adjusts
 * `videoCoinBalances` instead. Writes the camelCase shape the app parses
 * (coins/index.ts) and a `coinTransactions` row with reason 'adminAdjustment'.
 */
export const adminAdjustUserCoins = onCall(OPTS, async (request) => {
  const caller = await requireAdmin(request.auth, SUPER_ADMIN_ONLY);
  const data = request.data || {};
  const uid = userIdOf(data);
  const amount = data.amount;
  if (typeof amount !== 'number' || !Number.isInteger(amount) || amount === 0 || Math.abs(amount) > MAX_COIN_ADJUSTMENT) {
    throw new HttpsError('invalid-argument', `amount must be a non-zero integer up to ${MAX_COIN_ADJUSTMENT}`);
  }
  const reason = str(data.reason, 'reason', { min: 3, max: 500 })!;
  const kind = data.kind === 'videoCoins' ? 'videoCoins' : 'coins';
  await requireProfile(uid);

  const now = admin.firestore.Timestamp.now();
  let previous = 0;
  let next = 0;

  if (kind === 'coins') {
    const balanceRef = db().collection('coinBalances').doc(uid);
    const txRef = db().collection('coinTransactions').doc();
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(balanceRef);
      const d = snap.data() || {};
      previous = typeof d.totalCoins === 'number' ? d.totalCoins : 0;
      let batches: any[] = Array.isArray(d.coinBatches) ? d.coinBatches : [];
      let applied = amount;
      if (amount > 0) {
        batches = [...batches, {
          batchId: `admin_${now.toMillis()}_${txRef.id}`,
          initialCoins: amount,
          remainingCoins: amount,
          source: 'admin_grant',
          acquiredDate: now,
        }];
      } else {
        // Never below zero; remove from the oldest batches first.
        applied = -Math.min(-amount, Math.max(0, previous));
        batches = deductFromBatches(batches, -applied);
      }
      next = previous + applied;
      tx.set(balanceRef, {
        userId: uid,
        totalCoins: next,
        earnedCoins: d.earnedCoins ?? 0,
        purchasedCoins: d.purchasedCoins ?? 0,
        giftedCoins: d.giftedCoins ?? 0,
        spentCoins: d.spentCoins ?? 0,
        coinBatches: batches,
        lastUpdated: now,
      }, { merge: true });
      tx.set(txRef, {
        userId: uid,
        type: applied > 0 ? 'credit' : 'debit',
        amount: Math.abs(applied),
        balanceAfter: next,
        reason: 'adminAdjustment',
        createdAt: now,
        metadata: { note: reason, adjustedBy: caller.uid, requestedAmount: amount },
      });
    });
  } else {
    const balanceRef = db().collection('videoCoinBalances').doc(uid);
    const txRef = db().collection('videoCoinTransactions').doc();
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(balanceRef);
      const d = snap.data() || {};
      previous = typeof d.totalVideoCoins === 'number' ? d.totalVideoCoins : 0;
      next = Math.max(0, previous + amount);
      tx.set(balanceRef, {
        userId: uid,
        totalVideoCoins: next,
        usedVideoCoins: d.usedVideoCoins ?? 0,
        lastUpdated: now,
      }, { merge: true });
      tx.set(txRef, {
        userId: uid,
        type: next >= previous ? 'credit' : 'debit',
        amount: Math.abs(next - previous),
        reason: 'adminAdjustment',
        metadata: { note: reason, adjustedBy: caller.uid, requestedAmount: amount },
        createdAt: now,
      });
    });
  }

  await auditPanelAction(caller, amount > 0 ? 'add_coins' : 'remove_coins', uid, {
    kind, amount, reason, previousBalance: previous, newBalance: next,
  });
  return { success: true, kind, previousBalance: previous, newBalance: next };
});

// ---------------------------------------------------------------------------
// profile edits
// ---------------------------------------------------------------------------

const BASIC_FIELDS: Record<string, number> = {
  displayName: 100,
  nickname: 30,
  bio: 1000,
  occupation: 200,
  education: 200,
};
const ENTITLEMENT_FIELDS = new Set(['membershipTier', 'membershipEndDate', 'baseMembershipEndDate', 'hasBaseMembership']);

/**
 * Edit a user's profile from the panel's Users page. Basic text fields and
 * verificationStatus: superAdmin | moderator. Tier / end dates / Base
 * membership (entitlements): superAdmin only.
 */
export const adminUpdateUserProfile = onCall(OPTS, async (request) => {
  const data = request.data || {};
  const updates = data.updates;
  if (!updates || typeof updates !== 'object' || Array.isArray(updates)) {
    throw new HttpsError('invalid-argument', 'updates must be an object');
  }
  const keys = Object.keys(updates);
  const unknown = keys.filter((k) => !(k in BASIC_FIELDS) && k !== 'verificationStatus' && !ENTITLEMENT_FIELDS.has(k));
  if (unknown.length) throw new HttpsError('invalid-argument', `Fields not editable here: ${unknown.join(', ')}`);
  if (keys.length === 0) throw new HttpsError('invalid-argument', 'Nothing to update');

  const touchesEntitlements = keys.some((k) => ENTITLEMENT_FIELDS.has(k));
  const caller = await requireAdmin(request.auth, touchesEntitlements ? SUPER_ADMIN_ONLY : MODERATION_ROLES);
  const uid = userIdOf(data);
  await guardAdminTarget(caller, uid);

  const patch: Record<string, unknown> = {};
  for (const [k, max] of Object.entries(BASIC_FIELDS)) {
    if (k in updates) patch[k] = str(updates[k], k, { max, optional: true }) ?? '';
  }
  if (typeof patch.nickname === 'string' && patch.nickname && !/^[a-zA-Z0-9_.]+$/.test(patch.nickname)) {
    throw new HttpsError('invalid-argument', 'nickname may contain letters, digits, _ and . only');
  }
  if ('verificationStatus' in updates) {
    if (!VERIFICATION_STATUSES.has(updates.verificationStatus)) {
      throw new HttpsError('invalid-argument', 'verificationStatus is invalid');
    }
    patch.verificationStatus = updates.verificationStatus;
  }
  if ('membershipTier' in updates) {
    const tier = typeof updates.membershipTier === 'string' ? updates.membershipTier.toUpperCase() : '';
    if (!(PANEL_TIERS as readonly string[]).includes(tier)) {
      throw new HttpsError('invalid-argument', `membershipTier must be one of ${PANEL_TIERS.join(', ')}`);
    }
    patch.membershipTier = tier;
  }
  const end = tsOrNull(updates.membershipEndDate, 'membershipEndDate');
  if (end !== undefined) patch.membershipEndDate = end;
  const baseEnd = tsOrNull(updates.baseMembershipEndDate, 'baseMembershipEndDate');
  if (baseEnd !== undefined) patch.baseMembershipEndDate = baseEnd;
  if ('hasBaseMembership' in updates) {
    if (typeof updates.hasBaseMembership !== 'boolean') {
      throw new HttpsError('invalid-argument', 'hasBaseMembership must be a boolean');
    }
    patch.hasBaseMembership = updates.hasBaseMembership;
  }

  const ref = db().collection('profiles').doc(uid);
  const before = (await requireProfile(uid)).data() || {};
  await ref.update({ ...patch, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

  const previousValues: Record<string, unknown> = {};
  for (const k of Object.keys(patch)) previousValues[k] = before[k] ?? null;
  await auditPanelAction(caller, 'update_user_profile', uid, {
    fieldsUpdated: Object.keys(patch), previousValues, newValues: patch,
  });
  return { success: true, fieldsUpdated: Object.keys(patch) };
});

// ---------------------------------------------------------------------------
// account status
// ---------------------------------------------------------------------------

/**
 * Suspend / unsuspend / ban / unban, written on `profiles/{uid}` exactly as the
 * panel used to (status, suspensionReason, suspendedAt, suspendedUntil,
 * banReason, bannedAt). superAdmin | moderator; an admin account only by a
 * superAdmin.
 */
export const adminSetUserStatus = onCall(OPTS, async (request) => {
  const data = request.data || {};
  const action = data.action;
  if (!['suspend', 'unsuspend', 'ban', 'unban'].includes(action)) {
    throw new HttpsError('invalid-argument', 'action must be suspend | unsuspend | ban | unban');
  }
  const caller = await requireAdmin(
    request.auth,
    rolesForPermission(action === 'ban' || action === 'unban' ? 'banUsers' : 'suspendUsers')
  );
  const uid = userIdOf(data);
  await guardAdminTarget(caller, uid);
  const needsReason = action === 'suspend' || action === 'ban';
  const reason = str(data.reason, 'reason', { min: needsReason ? 3 : 0, max: 1000, optional: !needsReason });
  let durationDays: number | null = null;
  if (action === 'suspend' && data.durationDays !== undefined && data.durationDays !== null) {
    if (typeof data.durationDays !== 'number' || !Number.isInteger(data.durationDays)
        || data.durationDays < 1 || data.durationDays > 3650) {
      throw new HttpsError('invalid-argument', 'durationDays must be an integer between 1 and 3650');
    }
    durationDays = data.durationDays;
  }

  const before = (await requireProfile(uid)).data() || {};
  const now = admin.firestore.Timestamp.now();
  let patch: Record<string, unknown>;
  switch (action) {
    case 'suspend':
      patch = {
        status: 'suspended',
        suspensionReason: reason,
        suspendedAt: now,
        suspendedUntil: durationDays
          ? admin.firestore.Timestamp.fromMillis(now.toMillis() + durationDays * 86_400_000)
          : null,
      };
      break;
    case 'unsuspend':
      patch = { status: 'active', suspensionReason: null, suspendedAt: null, suspendedUntil: null };
      break;
    case 'ban':
      patch = { status: 'banned', banReason: reason, bannedAt: now };
      break;
    default:
      patch = { status: 'active', banReason: null, bannedAt: null };
  }
  await db().collection('profiles').doc(uid).update(patch);

  await auditPanelAction(caller, `${action}_user`, uid, {
    reason: reason ?? null,
    duration: durationDays,
    previousStatus: before.status ?? 'active',
  });
  return { success: true, status: patch.status };
});

/** Approve the photo verification of up to 100 users (Users page bulk action). */
export const adminBulkApproveVerification = onCall(OPTS, async (request) => {
  const caller = await requireAdmin(request.auth, MODERATION_ROLES);
  const ids = request.data?.userIds;
  if (!Array.isArray(ids) || ids.length === 0 || ids.length > MAX_BULK
      || ids.some((u) => typeof u !== 'string' || !u || u.includes('/'))) {
    throw new HttpsError('invalid-argument', `userIds must be 1-${MAX_BULK} user ids`);
  }
  let success = 0;
  const failedIds: string[] = [];
  for (const uid of ids as string[]) {
    try {
      await db().collection('profiles').doc(uid).update({
        verificationStatus: 'approved',
        verificationReviewedAt: admin.firestore.Timestamp.now(),
        verificationReviewedBy: caller.uid,
        verificationRejectionReason: null,
      });
      success++;
    } catch {
      failedIds.push(uid);
    }
  }
  await auditPanelAction(caller, 'bulk_approve_verification', null, {
    userIds: ids.slice(0, MAX_BULK), success, failed: failedIds.length,
  });
  return { success, failed: failedIds.length, failedIds };
});

// ---------------------------------------------------------------------------
// entitlements
// ---------------------------------------------------------------------------

/**
 * Subscriptions page override: sets `profiles.membershipTier` AND
 * `membershipEndDate` (a paid tier without an end date is NOT active under
 * shared/effectiveTier.ts, so the old browser write granted nothing), plus a
 * `subscriptions` record as before.
 */
export const adminOverrideSubscription = onCall(OPTS, async (request) => {
  const caller = await requireAdmin(request.auth, SUPER_ADMIN_ONLY);
  const data = request.data || {};
  const uid = userIdOf(data);
  // The Subscriptions page sends lowercase tiers; the profile stores uppercase.
  const tier = typeof data.tier === 'string' ? data.tier.toUpperCase() : data.tier;
  if (!(PANEL_TIERS as readonly string[]).includes(tier)) {
    throw new HttpsError('invalid-argument', `tier must be one of ${PANEL_TIERS.join(', ')}`);
  }
  const end = tsOrNull(data.expirationDate, 'expirationDate');
  if (PAID_TIERS.has(tier) && !end) {
    throw new HttpsError('invalid-argument', 'A paid tier needs an expirationDate');
  }
  const before = (await requireProfile(uid)).data() || {};

  const now = admin.firestore.Timestamp.now();
  const batch = db().batch();
  batch.update(db().collection('profiles').doc(uid), {
    membershipTier: tier,
    ...(end ? { membershipEndDate: end } : {}),
    updatedAt: now,
  });
  batch.set(db().collection('subscriptions').doc(), {
    userId: uid,
    tier,
    status: 'active',
    startDate: now,
    endDate: end ?? null,
    autoRenew: false,
    paymentMethod: 'admin_override',
    amount: 0,
    currency: 'USD',
    createdAt: now,
    note: 'Admin override',
    overriddenBy: caller.uid,
  });
  await batch.commit();

  await auditPanelAction(caller, 'override_subscription', uid, {
    previousTier: before.membershipTier ?? null,
    tier,
    expirationDate: end ? end.toDate().toISOString() : null,
  });
  return { success: true };
});

/**
 * Toggle internal test-user status (membershipTier TEST + isTestUser) and the
 * matching `mvp_access` entry, as the Users page did from the browser.
 */
export const adminToggleTestUser = onCall(OPTS, async (request) => {
  const caller = await requireAdmin(request.auth, SUPER_ADMIN_ONLY);
  const uid = userIdOf(request.data || {});
  const data = (await requireProfile(uid)).data() || {};
  const currentTier = data.membershipTier || 'FREE';
  const isCurrentlyTest = currentTier === 'TEST' || data.isTestUser === true;
  const email = typeof data.email === 'string' ? data.email.toLowerCase() : '';
  const now = admin.firestore.Timestamp.now();
  const profileRef = db().collection('profiles').doc(uid);
  const mvpDocs = email
    ? (await db().collection('mvp_access').where('email', '==', email).limit(10).get()).docs
    : [];

  if (isCurrentlyTest) {
    await profileRef.update({ membershipTier: 'FREE', isTestUser: false, updatedAt: now });
    for (const m of mvpDocs) {
      if (m.data().membershipTier === 'test') {
        await m.ref.update({ membershipTier: 'basic', approvalStatus: 'rejected', updatedAt: now });
      }
    }
  } else {
    await profileRef.update({ membershipTier: 'TEST', isTestUser: true, updatedAt: now });
    if (email) {
      if (mvpDocs.length === 0) {
        await db().collection('mvp_access').add({
          email,
          membershipTier: 'test',
          accessDate: now,
          approvalStatus: 'approved',
          notificationsEnabled: true,
          createdAt: now,
          updatedAt: now,
          notes: 'Test user - bypasses countdown',
          displayName: data.displayName || '',
        });
      } else {
        await mvpDocs[0].ref.update({
          membershipTier: 'test',
          approvalStatus: 'approved',
          updatedAt: now,
          notes: 'Test user - bypasses countdown',
        });
      }
    }
  }
  const isTestUser = !isCurrentlyTest;
  await auditPanelAction(caller, 'toggle_test_user', uid, { isTestUser, previousTier: currentTier });
  const name = data.displayName || email || uid;
  return {
    success: true,
    isTestUser,
    message: isTestUser ? `${name} is now a test user` : `Test mode removed for ${name}`,
  };
});

// ---------------------------------------------------------------------------
// notifications
// ---------------------------------------------------------------------------

/** In-app notification to one user (Notifications page). superAdmin only (sendNotifications). */
export const adminSendUserNotification = onCall(OPTS, async (request) => {
  const caller = await requireAdmin(request.auth, rolesForPermission('sendNotifications'));
  const d = request.data || {};
  const uid = userIdOf(d);
  const title = str(d.title, 'title', { min: 1, max: 200 })!;
  const body = str(d.body, 'body', { min: 1, max: 2000 })!;
  let extra: Record<string, unknown> = {};
  if (d.data !== undefined && d.data !== null) {
    if (typeof d.data !== 'object' || Array.isArray(d.data) || JSON.stringify(d.data).length > 4000) {
      throw new HttpsError('invalid-argument', 'data must be a small object');
    }
    extra = d.data;
  }
  const ref = await db().collection('notifications').add({
    userId: uid,
    title,
    body,
    data: extra,
    read: false,
    createdAt: admin.firestore.Timestamp.now(),
    sentBy: caller.uid,
  });
  await auditPanelAction(caller, 'send_notification', uid, { title, bodyPreview: body.slice(0, 100), notificationId: ref.id });
  return { success: true, notificationId: ref.id };
});
