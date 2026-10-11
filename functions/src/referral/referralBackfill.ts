/**
 * One-off initialisation of the server-authoritative invite counters
 * (referral_stats/{ownerId}) from the redemptions that happened before the
 * invite-friends milestones existed, granting every milestone an inviter has
 * ALREADY reached (owner decision: existing inviters are rewarded, once).
 *
 * Source of truth: referral_redemptions/{inviteeUid} = { ownerId, ... }
 * (server-only, one per invited account). The counter is re-derived from the
 * source on every run, never from a saved offset, so the job is idempotent:
 * a second run finds the milestones already in `milestonesGranted` and grants
 * nothing. Milestones whose grant failed earlier (`milestonesFailed`) are
 * retried.
 *
 * DRY-RUN BY DEFAULT: without `apply` this module only READS.
 * Driven by functions/scripts/backfill-referral-stats.ts.
 */

import * as admin from 'firebase-admin';
import { computeMembershipExtension, grantMembership, TierName } from '../shared/grants';
import { normalizeStoredTier } from '../shared/effectiveTier';
import {
  REFERRAL_MILESTONES,
  ReferralMilestone,
  grantedSet,
  milestonesToGrant,
} from './referralRules';
import { REFERRAL_STATS_COLLECTION, notifyMilestone } from './redeemReferral';

export interface OwnerPlan {
  ownerId: string;
  /** Successful invitations found in referral_redemptions. */
  invitedCount: number;
  /** invitedCount currently stored in referral_stats (0 when missing). */
  storedCount: number;
  alreadyGranted: number[];
  /** Milestones this run grants (newly reached + previously failed). */
  toGrant: { count: number; tier: TierName; predictedTier: string; predictedEnd: string }[];
}

export interface BackfillResult {
  apply: boolean;
  redemptionsScanned: number;
  owners: number;
  ownersWithGrants: number;
  grants: Record<string, number>;
  plans: OwnerPlan[];
  failures: string[];
}

const PAGE = 500;

/** ownerId -> count, paging referral_redemptions by document id (bounded pages). */
async function countByOwner(db: admin.firestore.Firestore): Promise<{ scanned: number; byOwner: Map<string, number> }> {
  const byOwner = new Map<string, number>();
  let scanned = 0;
  let last: admin.firestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let q = db.collection('referral_redemptions')
      .orderBy(admin.firestore.FieldPath.documentId())
      .select('ownerId')
      .limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    for (const d of snap.docs) {
      scanned++;
      const owner = d.get('ownerId');
      if (typeof owner === 'string' && owner) byOwner.set(owner, (byOwner.get(owner) || 0) + 1);
    }
    last = snap.docs[snap.docs.length - 1];
    if (snap.size < PAGE) break;
  }
  return { scanned, byOwner };
}

function predict(profile: admin.firestore.DocumentData | undefined, ms: ReferralMilestone[]) {
  // Chain the grants the way grantMembership would apply them in order.
  let tier: string = normalizeStoredTier(profile?.membershipTier);
  let end: Date | null = profile?.membershipEndDate?.toDate ? profile.membershipEndDate.toDate() : null;
  return ms.map((m) => {
    const r = computeMembershipExtension(tier, end, m.tier, m.durationMs);
    tier = r.effectiveTier;
    end = r.newEndDate;
    return { count: m.count, tier: m.tier, predictedTier: r.effectiveTier, predictedEnd: r.newEndDate.toISOString() };
  });
}

export async function runReferralStatsBackfill(opts: { apply: boolean; db?: admin.firestore.Firestore }): Promise<BackfillResult> {
  const db = opts.db ?? admin.firestore();
  const { scanned, byOwner } = await countByOwner(db);
  const result: BackfillResult = {
    apply: opts.apply,
    redemptionsScanned: scanned,
    owners: byOwner.size,
    ownersWithGrants: 0,
    grants: Object.fromEntries(REFERRAL_MILESTONES.map((m) => [String(m.count), 0])),
    plans: [],
    failures: [],
  };

  for (const [ownerId, scannedCount] of byOwner) {
    const statsRef = db.collection(REFERRAL_STATS_COLLECTION).doc(ownerId);
    let toGrant: ReferralMilestone[] = [];
    let invitedCount = scannedCount;
    let storedCount = 0;
    let alreadyGranted: number[] = [];

    if (!opts.apply) {
      const stats = (await statsRef.get()).data() || {};
      storedCount = Number(stats.invitedCount) || 0;
      invitedCount = Math.max(scannedCount, storedCount);
      const granted = grantedSet(stats.milestonesGranted);
      const failed = grantedSet(stats.milestonesFailed);
      alreadyGranted = [...granted].filter((c) => !failed.has(c)).sort((a, b) => a - b);
      toGrant = REFERRAL_MILESTONES.filter((m) => invitedCount >= m.count && (!granted.has(m.count) || failed.has(m.count)));
    } else {
      // Re-count inside the transaction (a live redemption may land meanwhile)
      // and claim the milestones atomically with the counter.
      const mirror = (await db.collection('referrals').doc(ownerId).get()).data() || {};
      const claimed = await db.runTransaction(async (tx) => {
        const statsSnap = await tx.get(statsRef);
        const live = await tx.get(db.collection('referral_redemptions').where('ownerId', '==', ownerId).select());
        const stats = statsSnap.data() || {};
        storedCount = Number(stats.invitedCount) || 0;
        const count = Math.max(live.size, storedCount);
        const granted = grantedSet(stats.milestonesGranted);
        const failed = grantedSet(stats.milestonesFailed);
        const retry = REFERRAL_MILESTONES.filter((m) => failed.has(m.count) && granted.has(m.count) && count >= m.count);
        const fresh = milestonesToGrant(count, granted);
        for (const m of fresh) granted.add(m.count);
        alreadyGranted = [...grantedSet(stats.milestonesGranted)].filter((c) => !failed.has(c)).sort((a, b) => a - b);
        tx.set(statsRef, {
          ownerId,
          invitedCount: count,
          coinsEarned: Math.max(Number(stats.coinsEarned) || 0, Number(mirror.coinsEarned) || 0),
          milestonesGranted: [...granted].sort((a, b) => a - b),
          milestonesFailed: [],
          backfilledAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        invitedCount = count;
        return [...retry, ...fresh].sort((a, b) => a.count - b.count);
      });
      toGrant = claimed;
      // Display-only mirror read by older app versions.
      await db.collection('referrals').doc(ownerId).set({ invitedCount }, { merge: true });
    }

    const profile = toGrant.length ? (await db.collection('profiles').doc(ownerId).get()).data() : undefined;
    const plan: OwnerPlan = {
      ownerId,
      invitedCount,
      storedCount,
      alreadyGranted,
      toGrant: predict(profile, toGrant),
    };
    result.plans.push(plan);
    if (toGrant.length) result.ownersWithGrants++;
    for (const m of toGrant) result.grants[String(m.count)]++;

    if (opts.apply) {
      for (const m of toGrant) {
        try {
          await grantMembership(ownerId, m.tier, m.durationMs);
          await notifyMilestone(ownerId, m);
        } catch (e) {
          result.failures.push(`${ownerId}:${m.count}: ${(e as Error).message}`);
          await statsRef.set({ milestonesFailed: admin.firestore.FieldValue.arrayUnion(m.count) }, { merge: true });
        }
      }
    }
  }
  return result;
}
