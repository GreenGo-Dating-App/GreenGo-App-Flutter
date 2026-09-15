/**
 * Turns the pre-registration allowlist on.
 *
 * applySignupGrants only applies a coupon when `autoGrantOnSignup === true`.
 * The 238 pre-registration coupons were imported with that flag FALSE, so not
 * one of them has ever fired: every person on the list who registered got
 * nothing, silently. (It is also why the stub profiles carry an empty
 * `signupGrantsApplied: []`.)
 *
 * This sets the flag on every coupon that is bound to a specific email, which
 * is exactly what the flag means: "this address is pre-registered, grant it on
 * signup".
 *
 * NOT touched:
 *   - coupons with no allowedEmail. autoGrantOnSignup without an address would
 *     fire for EVERY new user, handing that grant to the whole world. The
 *     upsert validation rejects the combination for the same reason.
 *   - coupons already disabled or fully redeemed.
 *
 * Dry run by default. Nothing is written without --commit.
 *
 *   node functions/scripts/enableSignupGrants.cjs
 *   node functions/scripts/enableSignupGrants.cjs --commit
 */

const { createRequire } = require('module');
const path = require('path');

const PANEL = path.resolve(__dirname, '../../../greengo-admin-panel');
const admin = createRequire(path.join(PANEL, 'package.json'))('firebase-admin');

const COMMIT = process.argv.includes('--commit');
const PROJECT = process.env.GOOGLE_CLOUD_PROJECT || 'greengo-chat';

admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

(async () => {
  console.log(`${COMMIT ? 'COMMIT' : 'DRY RUN'} against ${PROJECT}\n`);

  const snap = await db.collection('coupons').get();
  const toEnable = [];
  const skipped = { alreadyOn: 0, noEmail: 0, disabled: 0, exhausted: 0 };

  for (const doc of snap.docs) {
    const c = doc.data();
    if (c.autoGrantOnSignup === true) { skipped.alreadyOn += 1; continue; }
    if (!c.allowedEmail) { skipped.noEmail += 1; continue; }
    if (c.disabled) { skipped.disabled += 1; continue; }
    if (c.maxRedemptions != null && (c.redemptionsCount || 0) >= c.maxRedemptions) {
      skipped.exhausted += 1; continue;
    }
    toEnable.push({ id: doc.id, email: c.allowedEmail, code: c.code });
  }

  console.log(`coupons total            : ${snap.size}`);
  console.log(`to enable                : ${toEnable.length}`);
  console.log(`skipped - already on     : ${skipped.alreadyOn}`);
  console.log(`skipped - no email       : ${skipped.noEmail}  (would grant to everyone)`);
  console.log(`skipped - disabled       : ${skipped.disabled}`);
  console.log(`skipped - fully redeemed : ${skipped.exhausted}\n`);

  for (const c of toEnable.slice(0, 5)) {
    console.log(`   e.g. ${c.code} -> ${c.email}`);
  }
  if (toEnable.length > 5) console.log(`   ... and ${toEnable.length - 5} more`);

  if (!COMMIT) {
    console.log('\nDry run - nothing written. Re-run with --commit to apply.');
    process.exit(0);
  }

  let written = 0;
  for (let i = 0; i < toEnable.length; i += 400) {
    const batch = db.batch();
    for (const c of toEnable.slice(i, i + 400)) {
      batch.update(db.collection('coupons').doc(c.id), {
        autoGrantOnSignup: true,
        updatedAt: admin.firestore.Timestamp.now(),
        updatedBy: 'enableSignupGrants-script',
      });
      written += 1;
    }
    await batch.commit();
  }

  // Read back rather than trusting the writes.
  const after = await db.collection('coupons').where('autoGrantOnSignup', '==', true).get();
  console.log(`\nwrote ${written}; coupons now armed: ${after.size}`);
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
