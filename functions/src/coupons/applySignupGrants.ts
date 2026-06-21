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
import { computeMembershipExtension } from '../shared/grants';
import { sendCouponRedeemedEmail } from '../notifications/couponEmails';
import { effectiveGrants, hasBaseGrant, summariseGrants } from './grants';
import { monitored } from '../shared/monitoring';

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
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  monitored("applySignupGrants", async (event) => {
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
      // Transactional to avoid racing with a concurrent invocation that
      // also processed an (empty) grant list.
      await markProcessedIfFresh(profileRef, []);
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
    // Wrapped in a transaction that re-checks signupGrantsAppliedAt — under
    // at-least-once trigger delivery two invocations can both pass the
    // out-of-tx idempotency check above, but only one of them has the
    // populated `applied` list (the other's per-coupon redemption-doc checks
    // all bail out, leaving `applied` empty). Without this guard the loser
    // would clobber the winner's banner data.
    const wrote = await markProcessedIfFresh(profileRef, applied);
    if (!wrote) {
      logInfo(
        `applySignupGrants: another invocation already wrote grants for ${uid}, skipping notify`,
      );
      return;
    }

    // ── Best-effort email per grant (already non-fatal inside the helper) ──
    for (const g of applied) {
      await sendCouponRedeemedEmail(uid, {
        couponCode: g.couponCode,
        grantSummary: g.grantSummary,
      });
    }

    logInfo(`applySignupGrants: applied ${applied.length} grant(s) for ${uid} (${email})`);
  }),
);

/**
 * Writes `signupGrantsApplied` + `signupGrantsAppliedAt` to the profile only
 * if no prior invocation already wrote `signupGrantsAppliedAt`. Returns true
 * if this call did the write (so the caller can do follow-up side effects
 * like sending the welcome email).
 */
async function markProcessedIfFresh(
  profileRef: FirebaseFirestore.DocumentReference,
  applied: AppliedGrant[],
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(profileRef);
    if (snap.exists && snap.data()?.signupGrantsAppliedAt) {
      return false;
    }
    const now = admin.firestore.Timestamp.now();
    tx.set(
      profileRef,
      {
        signupGrantsApplied: applied,
        signupGrantsAppliedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    return true;
  });
}

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
    const profileRef = db.collection('profiles').doc(uid);
    const userRef = db.collection('users').doc(uid);
    const balanceRef = db.collection('coinBalances').doc(uid);

    const grants = effectiveGrants(c);
    if (grants.length === 0) return null;

    // ── All reads up-front (Firestore tx rule) ──
    const needsBalance = grants.some((g) => g.kind === 'coins');
    // Profile is needed for both membership and base_membership; also for the
    // implicit bonus rule when grants include a membership without an
    // explicit base grant.
    const couponHasBaseGrant = hasBaseGrant(c);
    const needsProfile =
      grants.some((g) => g.kind === 'membership' || g.kind === 'base_membership');

    const existing = await tx.get(redemptionRef);
    if (existing.exists) return null;

    const profSnap = needsProfile ? await tx.get(profileRef) : null;
    const balanceSnap = needsBalance ? await tx.get(balanceRef) : null;

    // ── Accumulate updates ──
    const profileUpdate: Record<string, any> = {};
    const userUpdate: Record<string, any> = {};
    let runningTier: string = (profSnap?.data()?.membershipTier as string) || 'BASIC';
    let runningTierEnd: Date | null =
      (profSnap?.data()?.membershipEndDate as admin.firestore.Timestamp | undefined)?.toDate() ??
      null;
    let runningBaseEnd: Date | null =
      (profSnap?.data()?.baseMembershipEndDate as admin.firestore.Timestamp | undefined)?.toDate() ??
      null;

    const balanceData = balanceSnap?.exists ? (balanceSnap.data() as any) : {};
    let runningBalance: number = (balanceData?.totalCoins as number) || 0;
    const coinBatches: any[] = (balanceData?.coinBatches as any[]) || [];
    let totalCoinsGranted = 0;

    // Track whether any membership grant was applied so we know whether to
    // append the implicit base-membership bonus.
    let membershipGrantApplied = false;
    let largestMembershipDurationMs = 0;

    for (const g of grants) {
      if (g.kind === 'membership' && g.tier && g.durationDays) {
        const durationMs = g.durationDays * 24 * 60 * 60 * 1000;
        const ext = computeMembershipExtension(
          runningTier,
          runningTierEnd,
          g.tier,
          durationMs,
          now.toDate(),
        );
        runningTier = ext.effectiveTier;
        runningTierEnd = ext.newEndDate;
        profileUpdate.membershipTier = ext.effectiveTier;
        profileUpdate.membershipStartDate = now;
        profileUpdate.membershipEndDate = ext.newEndTimestamp;
        userUpdate.subscriptionTier = ext.effectiveTier;
        userUpdate.membershipEndDate = ext.newEndTimestamp;
        membershipGrantApplied = true;
        if (durationMs > largestMembershipDurationMs) {
          largestMembershipDurationMs = durationMs;
        }
      } else if (g.kind === 'base_membership' && g.durationDays) {
        const durationMs = g.durationDays * 24 * 60 * 60 * 1000;
        const baseStart =
          runningBaseEnd && runningBaseEnd > now.toDate() ? runningBaseEnd : now.toDate();
        const newBaseEnd = new Date(baseStart.getTime() + durationMs);
        runningBaseEnd = newBaseEnd;
        profileUpdate.hasBaseMembership = true;
        profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
      } else if (g.kind === 'coins' && g.coinAmount && g.coinAmount > 0) {
        const amount = g.coinAmount;
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
        runningBalance += amount;
        totalCoinsGranted += amount;
      }
    }

    // ── Implicit bonus rule: signup membership grants get a same-duration ──
    // base membership for free, UNLESS the coupon already includes a base
    // grant in its bundle (no double-stack).
    let bonusApplied = false;
    if (membershipGrantApplied && !couponHasBaseGrant && largestMembershipDurationMs > 0) {
      const baseStart =
        runningBaseEnd && runningBaseEnd > now.toDate() ? runningBaseEnd : now.toDate();
      const newBaseEnd = new Date(baseStart.getTime() + largestMembershipDurationMs);
      runningBaseEnd = newBaseEnd;
      profileUpdate.hasBaseMembership = true;
      profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
      bonusApplied = true;
    }

    // ── Writes ──
    if (Object.keys(profileUpdate).length > 0) {
      profileUpdate.updatedAt = now;
      tx.set(profileRef, profileUpdate, { merge: true });
    }
    if (Object.keys(userUpdate).length > 0) {
      userUpdate.updatedAt = now;
      tx.set(userRef, userUpdate, { merge: true });
    }
    if (totalCoinsGranted > 0) {
      tx.set(
        balanceRef,
        {
          userId: uid,
          totalCoins: runningBalance,
          lastUpdated: now,
          coinBatches,
        },
        { merge: true },
      );
      const txnRef = db.collection('coinTransactions').doc();
      tx.set(txnRef, {
        userId: uid,
        type: 'credit',
        amount: totalCoinsGranted,
        balanceAfter: runningBalance,
        reason: 'coupon',
        metadata: { couponId: couponRef.id, couponCode: c.code, source: 'signup_grant' },
        createdAt: now,
      });
    }

    // Build the summary — append " + BASE +Nd" if the implicit bonus fired.
    let grantSummary = summariseGrants(grants);
    if (bonusApplied) {
      const bonusDays = Math.round(largestMembershipDurationMs / (24 * 60 * 60 * 1000));
      grantSummary = `${grantSummary} · BASE +${bonusDays}d`;
    }

    // Mark redemption + bump counter (one per coupon, not one per grant —
    // preserves maxRedemptions semantics).
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
