/**
 * Direct entitlement grants — the replacement for coupon codes.
 *
 * v4.0.0 removed every code-redemption surface from the app, because App Store
 * Guideline 3.1.1 forbids unlocking paid functionality by any mechanism other
 * than In-App Purchase. A code the user types is exactly that mechanism.
 *
 * What Apple has never objected to is a developer GRANTING an entitlement
 * server-side: comped accounts, press accounts, partner deals, win-back gifts.
 * Nothing is redeemed in the app, there is no input to find, and the reviewer
 * sees no unlock path — because there isn't one.
 *
 * So the coupon ENGINE survives and the coupon CODE does not. This callable
 * drives the same `grants.ts` helpers the coupon system used (never-downgrade
 * extension, duration whitelist, camelCase `coinBalances` shape), just with an
 * admin choosing the recipient instead of a code choosing itself.
 *
 * Every grant writes an audit record naming the admin who made it, and a
 * notification so the recipient finds out. A silent gift is a wasted one.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import {
  Grant,
  validateGrant,
  summariseGrants,
} from '../coupons/grants';
import {
  TierName,
  grantMembership,
  grantBaseMembership,
  grantCoins,
} from '../shared/grants';

/** Hard ceiling on a single fan-out, so a mis-click cannot gift the world. */
const MAX_RECIPIENTS = 500;

interface GrantRequest {
  /** Explicit recipients. Mutually exclusive with `segment`. */
  userIds?: string[];
  /** Simple audience rule, evaluated against `profiles`. */
  segment?: {
    tier?: TierName;
    country?: string;
    signedUpAfter?: string; // ISO date
    limit?: number;
  };
  grants: Grant[];
  /** Free text recorded on the audit entry — why this was given. */
  note?: string;
}

async function resolveRecipients(req: GrantRequest): Promise<string[]> {
  if (req.userIds && req.userIds.length > 0) {
    if (req.userIds.length > MAX_RECIPIENTS) {
      throw new HttpsError(
        'invalid-argument',
        `At most ${MAX_RECIPIENTS} recipients per grant.`
      );
    }
    return req.userIds;
  }

  const segment = req.segment;
  if (!segment) {
    throw new HttpsError('invalid-argument', 'Provide userIds or a segment.');
  }

  let q: admin.firestore.Query = db.collection('profiles');
  if (segment.tier) q = q.where('membershipTier', '==', segment.tier);
  if (segment.country) q = q.where('country', '==', segment.country);
  if (segment.signedUpAfter) {
    q = q.where(
      'createdAt',
      '>=',
      admin.firestore.Timestamp.fromDate(new Date(segment.signedUpAfter))
    );
  }
  const limit = Math.min(segment.limit ?? MAX_RECIPIENTS, MAX_RECIPIENTS);
  const snap = await q.limit(limit).get();
  return snap.docs.map((d) => d.id);
}

async function applyGrantsToUser(uid: string, grants: Grant[]): Promise<void> {
  for (const g of grants) {
    if (g.kind === 'membership' && g.tier && g.durationDays) {
      await grantMembership(
        uid,
        g.tier as TierName,
        g.durationDays * 24 * 60 * 60 * 1000,
      );
    } else if (g.kind === 'base_membership' && g.durationDays) {
      // grantBaseMembership takes milliseconds, not days.
      await grantBaseMembership(
        uid,
        g.durationDays * 24 * 60 * 60 * 1000,
        'admin_grant',
      );
    } else if (g.kind === 'coins' && g.coinAmount) {
      await grantCoins(uid, g.coinAmount, 'admin_grant', 'Gift from GreenGo');
    }
  }
}

export const grantEntitlement = onCall<GrantRequest>(
  { memory: '512MiB', timeoutSeconds: 300 },
  async (request) => {
    const adminUid = request.auth?.uid;
    if (!adminUid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const adminDoc = await db.collection('users').doc(adminUid).get();
    if (!adminDoc.data()?.isAdmin) {
      throw new HttpsError('permission-denied', 'Admin only.');
    }

    const data = request.data;
    const grants = data?.grants ?? [];
    if (!Array.isArray(grants) || grants.length === 0) {
      throw new HttpsError('invalid-argument', 'At least one grant is required.');
    }
    // Same validation the coupon path used, so a grant cannot express anything
    // a coupon could not.
    grants.forEach((g, i) => {
      try {
        validateGrant(g, i);
      } catch (e) {
        throw new HttpsError('invalid-argument', (e as Error).message);
      }
    });

    const recipients = await resolveRecipients(data);
    if (recipients.length === 0) {
      return { granted: 0, failed: 0, summary: summariseGrants(grants) };
    }

    const summary = summariseGrants(grants);
    const batchId = db.collection('temp').doc().id;
    let granted = 0;
    const failed: string[] = [];

    for (const uid of recipients) {
      try {
        await applyGrantsToUser(uid, grants);

        // Tell the recipient. The app already renders a dismissible banner for
        // server-applied grants; this reuses that surface rather than adding a
        // second notion of "you were given something".
        await db.collection('notifications').add({
          userId: uid,
          type: 'gift_received',
          title: 'A gift from GreenGo',
          body: summary,
          createdAt: admin.firestore.Timestamp.now(),
          read: false,
        });

        granted += 1;
      } catch (e) {
        failed.push(uid);
        logError(`grantEntitlement: failed for ${uid}`, e);
      }
    }

    await db.collection('entitlement_grants').doc(batchId).set({
      batchId,
      grantedBy: adminUid,
      grantedAt: admin.firestore.Timestamp.now(),
      grants,
      summary,
      note: data.note ?? null,
      recipientCount: recipients.length,
      grantedCount: granted,
      failedCount: failed.length,
      failedUserIds: failed.slice(0, 50),
      // Recipients are recorded for the audit trail, capped so one batch
      // cannot produce a document too large to read back.
      recipients: recipients.slice(0, MAX_RECIPIENTS),
    });

    logInfo(
      `grantEntitlement: ${adminUid} granted "${summary}" to ${granted}/${recipients.length}`
    );
    return { granted, failed: failed.length, summary, batchId };
  }
);

/** Recent grant batches, for the admin panel's history table. */
export const listEntitlementGrants = onCall(
  // 512MiB, not 256: this project's index.js loads ~274 functions and needs
  // roughly 200MB RSS before any handler runs, so a 256MiB function is
  // OOM-killed on cold start - silently, taking its invocation with it.
  { memory: '512MiB' },
  async (request) => {
    const adminUid = request.auth?.uid;
    if (!adminUid) throw new HttpsError('unauthenticated', 'Sign in required.');
    const adminDoc = await db.collection('users').doc(adminUid).get();
    if (!adminDoc.data()?.isAdmin) {
      throw new HttpsError('permission-denied', 'Admin only.');
    }

    const snap = await db
      .collection('entitlement_grants')
      .orderBy('grantedAt', 'desc')
      .limit(100)
      .get();

    return {
      grants: snap.docs.map((d) => {
        const g = d.data();
        return {
          batchId: d.id,
          grantedBy: g.grantedBy,
          grantedAt: (g.grantedAt as admin.firestore.Timestamp)?.toDate()?.toISOString() ?? null,
          summary: g.summary,
          note: g.note ?? null,
          recipientCount: g.recipientCount ?? 0,
          grantedCount: g.grantedCount ?? 0,
          failedCount: g.failedCount ?? 0,
        };
      }),
    };
  }
);
