/**
 * Auto-grants memberships/coins at signup based on the email allowlist.
 *
 * Fires when a new `users/{uid}` doc is created (client writes it on signup;
 * `onUserCreatedSendWelcome` in brevoEmailService.ts uses the same trigger).
 *
 * For every coupon whose `allowedEmail` matches the new user AND
 * `autoGrantOnSignup === true`, this:
 *   1. Atomically redeems the coupon (no double-grant, no over-redemption).
 *   2. For membership coupons, ADDITIONALLY grants a base membership of the
 *      same duration as a free bonus (per product decision).
 *   3. Records the grant in `profiles/{uid}.signupGrantsApplied[]` so the
 *      client can render a one-time welcome banner.
 *
 * Idempotency: `profiles/{uid}.signupGrantsAppliedAt` short-circuits the
 * trigger on re-fires (Firestore guarantees at-least-once delivery).
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { TierName, computeMembershipExtension } from '../shared/grants';
import { sendCouponRedeemedEmail } from '../notifications/couponEmails';

const COIN_EXPIRATION_DAYS = 365;

interface AppliedGrant {
  couponId: string;
  couponCode: string;
  grantSummary: string;
  dismissed: boolean;
}

export const applySignupGrants = onDocumentCreated(
  {
    document: 'users/{userId}',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const uid = event.params.userId;
    const userData = event.data?.data();
    if (!userData?.email) {
      logInfo(`applySignupGrants: no email on users/${uid}, skipping`);
      return;
    }

    const email = String(userData.email).toLowerCase().trim();
    const profileRef = db.collection('profiles').doc(uid);

    // ── Idempotency: short-circuit if we've already applied grants ──
    const profileSnap = await profileRef.get();
    if (profileSnap.exists && profileSnap.data()?.signupGrantsAppliedAt) {
      logInfo(`applySignupGrants: already applied for ${uid}, skipping`);
      return;
    }

    // ── Find matching allowlist coupons ──
    const couponsSnap = await db
      .collection('coupons')
      .where('allowedEmail', '==', email)
      .where('disabled', '==', false)
      .where('autoGrantOnSignup', '==', true)
      .get();

    if (couponsSnap.empty) {
      logInfo(`applySignupGrants: no allowlist coupons for ${email}`);
      // Still mark as processed so we don't keep querying on every doc update.
      await profileRef.set(
        { signupGrantsAppliedAt: admin.firestore.Timestamp.now() },
        { merge: true },
      );
      return;
    }

    const applied: AppliedGrant[] = [];

    for (const couponDoc of couponsSnap.docs) {
      try {
        const grant = await applyOneCoupon(uid, email, couponDoc);
        if (grant) applied.push(grant);
      } catch (err) {
        logError(
          `applySignupGrants: failed to apply coupon ${couponDoc.id} for ${uid}`,
          err,
        );
      }
    }

    // ── Record the applied grants so the client can show a welcome banner ──
    const now = admin.firestore.Timestamp.now();
    await profileRef.set(
      {
        signupGrantsApplied: applied,
        signupGrantsAppliedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    // ── Best-effort email per grant (already non-fatal inside the helper) ──
    for (const g of applied) {
      await sendCouponRedeemedEmail(uid, {
        couponCode: g.couponCode,
        grantSummary: g.grantSummary,
      });
    }

    logInfo(`applySignupGrants: applied ${applied.length} grant(s) for ${uid} (${email})`);
  },
);

/**
 * Redeems a single coupon for a new user inside a transaction.
 * Returns the AppliedGrant entry to record, or null if skipped (expired, etc).
 */
async function applyOneCoupon(
  uid: string,
  userEmail: string,
  couponDoc: FirebaseFirestore.QueryDocumentSnapshot,
): Promise<AppliedGrant | null> {
  const couponRef = couponDoc.ref;
  return db.runTransaction(async (tx) => {
    // Re-fetch the coupon inside the tx for atomic check.
    const snap = await tx.get(couponRef);
    if (!snap.exists) return null;
    const c = snap.data() as any;
    if (c.disabled) return null;
    const now = admin.firestore.Timestamp.now();
    if (c.expiresAt && (c.expiresAt as admin.firestore.Timestamp).toDate() <= now.toDate()) {
      return null;
    }
    if (
      c.maxRedemptions != null &&
      (c.redemptionsCount || 0) >= c.maxRedemptions
    ) {
      return null;
    }

    const redemptionRef = couponRef.collection('redemptions').doc(uid);
    const existing = await tx.get(redemptionRef);
    if (existing.exists) return null;

    const durationDays = Number(c.durationDays) || 0;
    const durationMs = durationDays * 24 * 60 * 60 * 1000;
    const profileRef = db.collection('profiles').doc(uid);
    const userRef = db.collection('users').doc(uid);

    let grantSummary = '';

    if (c.type === 'membership') {
      const tier = c.tier as TierName;
      const profSnap = await tx.get(profileRef);
      const prof = profSnap.data() || {};
      const currentTier = (prof.membershipTier as string) || 'BASIC';
      const currentEndTs = prof.membershipEndDate as admin.firestore.Timestamp | undefined;
      const currentEnd = currentEndTs ? currentEndTs.toDate() : null;

      const ext = computeMembershipExtension(
        currentTier,
        currentEnd,
        tier,
        durationMs,
        now.toDate(),
      );

      // Tier writes
      tx.set(
        profileRef,
        {
          membershipTier: ext.effectiveTier,
          membershipStartDate: now,
          membershipEndDate: ext.newEndTimestamp,
          updatedAt: now,
        },
        { merge: true },
      );
      tx.set(
        userRef,
        {
          subscriptionTier: ext.effectiveTier,
          membershipEndDate: ext.newEndTimestamp,
          updatedAt: now,
        },
        { merge: true },
      );

      // ── Bonus rule: same-duration base membership ──
      const currentBaseEndTs = prof.baseMembershipEndDate as
        | admin.firestore.Timestamp
        | undefined;
      const currentBaseEnd = currentBaseEndTs ? currentBaseEndTs.toDate() : null;
      const baseStart =
        currentBaseEnd && currentBaseEnd > now.toDate() ? currentBaseEnd : now.toDate();
      const newBaseEnd = new Date(baseStart.getTime() + durationMs);
      tx.set(
        profileRef,
        {
          hasBaseMembership: true,
          baseMembershipEndDate: admin.firestore.Timestamp.fromDate(newBaseEnd),
        },
        { merge: true },
      );

      grantSummary = `${ext.effectiveTier} +${durationDays}d + BASE +${durationDays}d`;
    } else if (c.type === 'base_membership') {
      const profSnap = await tx.get(profileRef);
      const prof = profSnap.data() || {};
      const currentEndTs = prof.baseMembershipEndDate as
        | admin.firestore.Timestamp
        | undefined;
      const currentEnd = currentEndTs ? currentEndTs.toDate() : null;
      const baseStart = currentEnd && currentEnd > now.toDate() ? currentEnd : now.toDate();
      const newEnd = new Date(baseStart.getTime() + durationMs);
      tx.set(
        profileRef,
        {
          hasBaseMembership: true,
          baseMembershipEndDate: admin.firestore.Timestamp.fromDate(newEnd),
          updatedAt: now,
        },
        { merge: true },
      );
      grantSummary = `BASE +${durationDays}d`;
    } else if (c.type === 'coins') {
      const amount = Number(c.coinAmount) || 0;
      if (amount <= 0) return null;
      const balanceRef = db.collection('coinBalances').doc(uid);
      const balanceSnap = await tx.get(balanceRef);
      let currentBalance = 0;
      let coinBatches: any[] = [];
      if (balanceSnap.exists) {
        const data = balanceSnap.data() as any;
        currentBalance = data.totalCoins || 0;
        coinBatches = data.coinBatches || [];
      }
      const expirationDate = new Date();
      expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);
      coinBatches.push({
        batchId: db.collection('temp').doc().id,
        initialCoins: amount,
        remainingCoins: amount,
        source: 'coupon',
        acquiredDate: now,
        expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
      });
      tx.set(
        balanceRef,
        {
          userId: uid,
          totalCoins: currentBalance + amount,
          lastUpdated: now,
          coinBatches,
        },
        { merge: true },
      );
      const txnRef = db.collection('coinTransactions').doc();
      tx.set(txnRef, {
        userId: uid,
        type: 'credit',
        amount,
        balanceAfter: currentBalance + amount,
        reason: 'coupon',
        metadata: { couponId: couponRef.id, couponCode: c.code, source: 'signup_grant' },
        createdAt: now,
      });
      grantSummary = `+${amount} coins`;
    } else {
      return null;
    }

    // Mark redemption + bump counter
    tx.set(redemptionRef, {
      redeemedAt: now,
      userEmail,
      grantSummary,
      couponCode: c.code,
      source: 'signup_grant',
    });
    tx.update(couponRef, {
      redemptionsCount: admin.firestore.FieldValue.increment(1),
      lastRedeemedAt: now,
    });

    return {
      couponId: couponRef.id,
      couponCode: c.code,
      grantSummary,
      dismissed: false,
    };
  });
}
