/**
 * Backfill script: record HOW existing memberships were granted.
 *
 * Usage: cd functions && node backfill-membership-source.js [--apply]
 *        (dry-run by default; --apply performs the writes)
 *
 * `redeemCoupon` and `verifyPurchase` now stamp `baseMembershipSource` /
 * `membershipSource` ('coupon' | 'purchase') so the client can decide whether
 * the store's free-trial offer is still available. Profiles that predate that
 * change have neither field, and a missing value reads as a purchase — which
 * silently denies the trial to everyone who got in via a coupon.
 *
 * Classification, deliberately conservative:
 *   - any membership purchase on record        -> 'purchase'
 *   - else redeemed a coupon that granted a
 *     membership or base membership            -> 'coupon'
 *   - else                                     -> LEFT UNSET
 *
 * Mislabelling a coupon user as a purchaser only preserves today's behaviour;
 * mislabelling a purchaser as a coupon user would offer them a trial they are
 * not entitled to. So no-evidence profiles are left alone rather than guessed.
 */

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'greengo-chat',
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const APPLY = process.argv.includes('--apply');

async function main() {
  console.log(APPLY ? '=== APPLY MODE ===' : '=== DRY RUN (pass --apply to write) ===');

  // ── Who has ever purchased a membership? ──
  const purchasers = new Set();
  const purchaseSnap = await db.collection('purchases').where('type', '==', 'membership').get();
  purchaseSnap.forEach((d) => {
    const uid = d.data().userId;
    if (uid) purchasers.add(uid);
  });
  const subsSnap = await db.collection('subscriptions').get();
  subsSnap.forEach((d) => {
    const uid = d.data().userId || d.id;
    if (uid) purchasers.add(uid);
  });
  console.log(`purchasers: ${purchasers.size}`);

  // ── Who redeemed a coupon that granted membership? ──
  const couponGrantsMembership = new Map(); // couponId -> bool
  const couponUsers = new Set();
  const redemptions = await db.collectionGroup('redemptions').get();
  for (const doc of redemptions.docs) {
    const couponRef = doc.ref.parent.parent;
    if (!couponRef) continue;
    if (!couponGrantsMembership.has(couponRef.id)) {
      const c = await couponRef.get();
      const grants = (c.data() || {}).grants || [];
      const type = (c.data() || {}).type;
      const grantsMembership =
        grants.some((g) => g.kind === 'membership' || g.kind === 'base_membership') ||
        type === 'membership' ||
        type === 'base_membership';
      couponGrantsMembership.set(couponRef.id, grantsMembership);
    }
    if (couponGrantsMembership.get(couponRef.id)) couponUsers.add(doc.id);
  }
  console.log(`coupon redeemers with a membership grant: ${couponUsers.size}`);

  // ── Walk profiles that hold an entitlement but carry no source ──
  const stats = { scanned: 0, purchase: 0, coupon: 0, noEvidence: 0, alreadySet: 0 };
  let batch = db.batch();
  let pending = 0;

  const profiles = await db.collection('profiles').get();
  for (const doc of profiles.docs) {
    const d = doc.data();
    const hasBase = d.hasBaseMembership === true;
    const hasTier = d.membershipTier && d.membershipTier !== 'BASIC';
    if (!hasBase && !hasTier) continue;
    stats.scanned++;

    if (d.baseMembershipSource || d.membershipSource) {
      stats.alreadySet++;
      continue;
    }

    let source = null;
    if (purchasers.has(doc.id)) source = 'purchase';
    else if (couponUsers.has(doc.id)) source = 'coupon';

    if (!source) {
      stats.noEvidence++;
      continue;
    }
    stats[source]++;

    if (APPLY) {
      const update = { baseMembershipSourceBackfilledAt: admin.firestore.Timestamp.now() };
      if (hasBase) update.baseMembershipSource = source;
      if (hasTier) update.membershipSource = source;
      batch.update(doc.ref, update);
      if (++pending >= 400) {
        await batch.commit();
        batch = db.batch();
        pending = 0;
      }
    }
  }
  if (APPLY && pending > 0) await batch.commit();

  console.log(JSON.stringify(stats, null, 2));
  console.log(APPLY ? 'done — writes committed' : 'done — no writes (dry run)');
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
