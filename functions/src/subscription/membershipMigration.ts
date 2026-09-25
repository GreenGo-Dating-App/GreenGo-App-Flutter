/**
 * ONE-OFF membership tier migration (HTTP, token-guarded, DRY RUN by default).
 *
 *   GET  .../runMembershipTierMigrationNow?token=<MEMBERSHIP_MIGRATION_TOKEN>            → dry run (counts only)
 *   GET  .../runMembershipTierMigrationNow?token=<...>&dryRun=0                          → apply
 *   optional &startAfter=<uid> to resume a scan that hit the time budget (see `nextCursor`).
 *
 * The token is NOT committed: it is read from MEMBERSHIP_MIGRATION_TOKEN in the
 * gitignored functions/.env (baked in at deploy). Unset → 503, nothing runs.
 *
 * Buckets:
 *   (a) basicToFree         membershipTier 'BASIC' (legacy; the client reads it as SILVER) → 'FREE'.
 *       (a2) baseRepaired   …of which the legacy end date is still running and the Base fields are
 *                           missing (with a store Base purchase on record) or shorter → Base set to
 *                           that end date (never shortened; a past Base end = refund/expiry, untouched).
 *   (b) expiredPaidToFree   SILVER/GOLD/PLATINUM with membershipEndDate < now → 'FREE'
 *                           (same writes as the hourly handleExpiredMemberships job).
 *   (c) paidNullEndDate     SILVER/GOLD/PLATINUM with NO membershipEndDate (not admin/TEST) — REPORT ONLY.
 *   (d) baseWronglyCleared  hasBaseMembership == false but baseMembershipEndDate still in the future
 *                           (the old expiry job cleared Base when the TIER expired) → restored.
 *   skipped: admins / TEST.
 *
 * Idempotent: a second real run finds nothing left to change.
 */

import * as crypto from 'crypto';
import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import {
  BASE_PRODUCT_IDS,
  LEGACY_BASIC_STORED_VALUES,
  PAID_TIER_STORED_VALUES,
  USERS_FREE_TIER,
  isProfileAdmin,
  normalizeStoredTier,
  tierDateFromValue,
} from '../shared/effectiveTier';
import { WriteQueue, planTierExpiry } from '../shared/membershipExpiry';

const PAGE_SIZE = 300;
const TIME_BUDGET_MS = 480_000;
const SAMPLE_MAX = 20;

interface Bucket {
  count: number;
  sample: string[];
}

function bucket(): Bucket {
  return { count: 0, sample: [] };
}

function add(b: Bucket, uid: string): void {
  b.count++;
  if (b.sample.length < SAMPLE_MAX) b.sample.push(uid);
}

function tokenOk(given: unknown): boolean {
  const expected = process.env.MEMBERSHIP_MIGRATION_TOKEN || '';
  if (!expected || typeof given !== 'string' || given.length === 0) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

/**
 * Store evidence that this user bought the Base membership (legacy
 * verifyPurchase wrote `subscriptions` + `purchases` rows with the Base
 * productId). Profile fields are not evidence: they are what we repair.
 */
async function hadStoreBasePurchase(uid: string): Promise<boolean> {
  const [subs, purchases] = await Promise.all([
    db.collection('subscriptions').where('userId', '==', uid)
      .where('productId', 'in', [...BASE_PRODUCT_IDS]).limit(1).get(),
    db.collection('purchases').where('userId', '==', uid)
      .where('productId', 'in', [...BASE_PRODUCT_IDS]).limit(1).get(),
  ]);
  return !subs.empty || !purchases.empty;
}

export const runMembershipTierMigrationNow = onRequest(
  { memory: '512MiB', timeoutSeconds: 540 },
  async (req, res) => {
    if (!process.env.MEMBERSHIP_MIGRATION_TOKEN) {
      res.status(503).json({ error: 'MEMBERSHIP_MIGRATION_TOKEN not configured' });
      return;
    }
    if (!tokenOk(req.query.token)) {
      res.status(403).send('forbidden');
      return;
    }
    const dryRunParam = String(req.query.dryRun ?? '1').toLowerCase();
    const dryRun = !(dryRunParam === '0' || dryRunParam === 'false' || dryRunParam === 'no');
    const startAfter = typeof req.query.startAfter === 'string' ? req.query.startAfter : undefined;

    const started = Date.now();
    const now = admin.firestore.Timestamp.now();
    const nowDate = now.toDate();
    const queue = new WriteQueue();

    const out = {
      dryRun,
      basicToFree: bucket(),
      baseRepaired: bucket(),
      expiredPaidToFree: bucket(),
      paidNullEndDate: bucket(),
      baseWronglyCleared: bucket(),
      skippedAdminOrTest: bucket(),
      errors: bucket(),
      scannedTierProfiles: 0,
      scannedBaseProfiles: 0,
      writesCommitted: 0,
      nextCursor: null as string | null,
      complete: false,
    };

    try {
      // ── Pass 1: every profile whose stored tier is BASIC or paid (by doc id) ──
      let cursor: string | undefined = startAfter;
      let timedOut = false;
      // eslint-disable-next-line no-constant-condition
      while (true) {
        if (Date.now() - started > TIME_BUDGET_MS) {
          timedOut = true;
          break;
        }
        let q = db
          .collection('profiles')
          .where('membershipTier', 'in', [...LEGACY_BASIC_STORED_VALUES, ...PAID_TIER_STORED_VALUES])
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(PAGE_SIZE);
        if (cursor) q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty) break;
        cursor = snap.docs[snap.docs.length - 1].id;

        for (const doc of snap.docs) {
          out.scannedTierProfiles++;
          const uid = doc.id;
          const p = doc.data();
          try {
            const stored = normalizeStoredTier(p.membershipTier);
            if (isProfileAdmin(p) || stored === 'TEST') {
              add(out.skippedAdminOrTest, uid);
              continue;
            }
            const end = tierDateFromValue(p.membershipEndDate);

            if (stored === 'BASIC') {
              add(out.basicToFree, uid);
              // A legacy Base purchase wrote tier 'BASIC' + the Base end date
              // into membershipEndDate. Make sure the Base fields carry at
              // least that period — never shorten them.
              //   - Base end missing + store evidence of a Base purchase → set it.
              //   - Base end still running but shorter than the legacy end → extend.
              //   - Base end in the PAST → leave it: that is a refund/revoke
              //     (which stamps the end to "now") or a real expiry.
              const baseEnd = tierDateFromValue(p.baseMembershipEndDate);
              let baseFix: Record<string, any> | null = null;
              if (end && end > nowDate) {
                const repair = !baseEnd
                  ? await hadStoreBasePurchase(uid)
                  : baseEnd > nowDate && baseEnd < end;
                if (repair) {
                  baseFix = {
                    hasBaseMembership: true,
                    baseMembershipEndDate: admin.firestore.Timestamp.fromDate(end),
                    baseMembershipSource: p.baseMembershipSource || 'purchase',
                  };
                  add(out.baseRepaired, uid);
                }
              }
              if (!dryRun) {
                await queue.set(doc.ref, {
                  membershipTier: 'FREE',
                  previousMembershipTier: String(p.membershipTier),
                  membershipMigratedAt: now,
                  updatedAt: now,
                  ...(baseFix || {}),
                });
                const userRef = db.collection('users').doc(uid);
                if ((await userRef.get()).exists) {
                  await queue.set(userRef, { subscriptionTier: USERS_FREE_TIER, updatedAt: now });
                }
              }
              continue;
            }

            // Paid tier.
            if (!end) {
              add(out.paidNullEndDate, uid); // report only
              continue;
            }
            if (end.getTime() <= nowDate.getTime()) {
              add(out.expiredPaidToFree, uid);
              if (!dryRun) {
                await planTierExpiry(doc, queue, { reason: 'migration', now });
              }
            }
          } catch (e) {
            add(out.errors, uid);
            logError(`runMembershipTierMigrationNow: ${uid}`, e);
          }
        }
        if (!dryRun) await queue.flush();
        if (snap.size < PAGE_SIZE) break;
      }

      if (timedOut) {
        out.nextCursor = cursor ?? null;
      } else {
        // ── Pass 2: Base wrongly cleared by the old tier-expiry job ──
        // Index: profiles (hasBaseMembership ASC, baseMembershipEndDate ASC).
        let baseCursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
        // eslint-disable-next-line no-constant-condition
        while (true) {
          if (Date.now() - started > TIME_BUDGET_MS) {
            timedOut = true;
            break;
          }
          let q = db
            .collection('profiles')
            .where('hasBaseMembership', '==', false)
            .where('baseMembershipEndDate', '>', now)
            .orderBy('baseMembershipEndDate', 'asc')
            .limit(PAGE_SIZE);
          if (baseCursor) q = q.startAfter(baseCursor);
          const snap = await q.get();
          if (snap.empty) break;
          baseCursor = snap.docs[snap.docs.length - 1];
          for (const doc of snap.docs) {
            out.scannedBaseProfiles++;
            add(out.baseWronglyCleared, doc.id);
            if (!dryRun) {
              await queue.set(doc.ref, {
                hasBaseMembership: true,
                baseMembershipRestoredAt: now,
                updatedAt: now,
              });
            }
          }
          if (!dryRun) await queue.flush();
          if (snap.size < PAGE_SIZE) break;
        }
        // Pass 2 is cheap and idempotent: if it timed out, re-running with
        // `startAfter` = the pass-1 end is not needed — just run again.
        out.complete = !timedOut;
      }

      if (!dryRun) await queue.flush();
      out.writesCommitted = queue.committedOps;
      logInfo(`runMembershipTierMigrationNow ${dryRun ? 'DRY RUN' : 'APPLIED'}: ${JSON.stringify({
        basicToFree: out.basicToFree.count,
        baseRepaired: out.baseRepaired.count,
        expiredPaidToFree: out.expiredPaidToFree.count,
        paidNullEndDate: out.paidNullEndDate.count,
        baseWronglyCleared: out.baseWronglyCleared.count,
        skippedAdminOrTest: out.skippedAdminOrTest.count,
        errors: out.errors.count,
        writes: out.writesCommitted,
      })}`);
      res.status(200).json(out);
    } catch (e: any) {
      logError('runMembershipTierMigrationNow failed', e);
      try {
        await queue.flush();
      } catch {
        // already logged
      }
      out.writesCommitted = queue.committedOps;
      res.status(500).json({ error: e?.message || String(e), partial: out });
    }
  },
);
