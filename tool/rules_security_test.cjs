/**
 * Behavioural tests for firestore.rules, run against the emulator.
 *
 * A rules change is the kind of edit that either does nothing or locks every
 * user out, and neither outcome is visible by reading it. These exercise the
 * five findings fixed in the v4.0.0 security pass, as a real signed-in user, and
 * just as importantly check that ordinary writes still succeed.
 *
 * Run:
 *   npx firebase emulators:exec --only firestore,auth \
 *     --config firebase.rulestest.json --project greengo-chat \
 *     "node tool/rules_security_test.cjs"
 *
 * Modules are resolved from the admin panel, which has both SDKs installed;
 * the npm registry is unreachable from this machine so nothing new can be
 * added here.
 */

const path = require('path');
const { createRequire } = require('module');

const ADMIN_PANEL = path.resolve(
  __dirname,
  '../../greengo-admin-panel/package.json'
);
const req = createRequire(ADMIN_PANEL);

const admin = req('firebase-admin');
const { initializeApp } = req('firebase/app');
const {
  getFirestore,
  connectFirestoreEmulator,
  doc,
  setDoc,
  updateDoc,
  getDoc,
  getDocs,
  collection,
  Timestamp,
} = req('firebase/firestore');
const {
  getAuth,
  connectAuthEmulator,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
} = req('firebase/auth');

const PROJECT = 'greengo-chat';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8098';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

let passed = 0;
let failed = 0;
let openFindings = 0;

/**
 * A finding that is CONFIRMED OPEN and not yet fixed.
 *
 * Printed loudly every run, but does not fail the suite, so this file stays
 * usable as a CI gate for the things that ARE fixed. Convert to denied() the
 * moment the underlying issue is closed - a permanently amber test is only
 * marginally better than no test.
 */
async function knownOpen(label, why, fn) {
  try {
    await fn();
    console.log(`  OPEN  ${label}`);
    console.log(`        ${why}`);
    openFindings += 1;
  } catch (e) {
    console.log(`  ok    ${label} - now denied; convert this to denied()`);
    passed += 1;
  }
}

/** Asserts a write is rejected by the rules. */
async function denied(label, fn) {
  try {
    await fn();
    console.log(`  FAIL  ${label}\n        expected DENY, but it succeeded`);
    failed += 1;
  } catch (e) {
    if (String(e.code || e.message).includes('permission-denied')) {
      console.log(`  ok    ${label} (denied)`);
      passed += 1;
    } else {
      console.log(`  FAIL  ${label}\n        expected permission-denied, got ${e.code || e.message}`);
      failed += 1;
    }
  }
}

/** Asserts a write is accepted - the half that catches an over-tight rule. */
async function allowed(label, fn) {
  try {
    await fn();
    console.log(`  ok    ${label} (allowed)`);
    passed += 1;
  } catch (e) {
    console.log(`  FAIL  ${label}\n        expected ALLOW, got ${e.code || e.message}`);
    failed += 1;
  }
}

async function main() {
  // Admin SDK bypasses rules; used only to seed.
  admin.initializeApp({ projectId: PROJECT });
  const adb = admin.firestore();

  const client = initializeApp({ projectId: PROJECT, apiKey: 'emulator' }, 'client');
  const cdb = getFirestore(client);
  const auth = getAuth(client);
  connectFirestoreEmulator(cdb, '127.0.0.1', 8098);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });

  const userA = await createUserWithEmailAndPassword(auth, 'a@test.dev', 'password123');
  const uidA = userA.user.uid;
  const userB = await createUserWithEmailAndPassword(auth, 'b@test.dev', 'password123');
  const uidB = userB.user.uid;

  // Seed as admin: a SILVER profile with coins, plus another user's membership.
  await adb.collection('profiles').doc(uidA).set({
    userId: uidA,
    displayName: 'A',
    membershipTier: 'SILVER',
    membershipEndDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 8.64e7)),
    hasBaseMembership: true,
    isAgeVerified: false,
    isAdmin: false,
    isBanned: false,
  });
  await adb.collection('coinBalances').doc(uidA).set({ userId: uidA, totalCoins: 100 });
  await adb.collection('memberships').doc('mB').set({ userId: uidB, tier: 'GOLD', isActive: true });
  await adb.collection('admin_users').doc('someAdmin').set({ role: 'superAdmin', email: 'x@y.z' });

  // Sign in as A for every client call below.
  await signInWithEmailAndPassword(auth, 'a@test.dev', 'password123');

  console.log('\nFinding 1 - entitlements are not self-writable');
  await denied('cannot promote self to PLATINUM', () =>
    updateDoc(doc(cdb, 'profiles', uidA), { membershipTier: 'PLATINUM' })
  );
  await denied('cannot extend own membershipEndDate', () =>
    updateDoc(doc(cdb, 'profiles', uidA), {
      membershipEndDate: Timestamp.fromDate(new Date(Date.now() + 9e10)),
    })
  );
  await denied('cannot grant self base membership', () =>
    updateDoc(doc(cdb, 'profiles', uidA), { hasBaseMembership: true, membershipTier: 'SILVER' })
      .then(() => updateDoc(doc(cdb, 'profiles', uidA), { baseMembershipEndDate: Timestamp.now() }))
  );
  await allowed('CAN downgrade self to FREE (expiry self-heal)', () =>
    updateDoc(doc(cdb, 'profiles', uidA), { membershipTier: 'FREE', membershipEndDate: null })
  );

  console.log('\nOrdinary profile edits still work');
  await allowed('can change own display name', () =>
    updateDoc(doc(cdb, 'profiles', uidA), { displayName: 'A renamed' })
  );
  await denied('still cannot self-verify age (v4.0.0 regression check)', () =>
    updateDoc(doc(cdb, 'profiles', uidA), { isAgeVerified: true })
  );
  await denied('still cannot self-grant admin', () =>
    updateDoc(doc(cdb, 'profiles', uidA), { isAdmin: true })
  );

  console.log('\nFinding 2 - coin balance cannot increase from the client');
  await denied('cannot inflate own coin balance', () =>
    updateDoc(doc(cdb, 'coinBalances', uidA), { totalCoins: 500 })
  );
  await allowed('CAN spend coins (balance decreases)', () =>
    updateDoc(doc(cdb, 'coinBalances', uidA), { totalCoins: 50 })
  );
  await denied('cannot create another user rich balance', () =>
    setDoc(doc(cdb, 'coinBalances', uidB), { userId: uidB, totalCoins: 9999 })
  );

  console.log('\nFinding 3 - memberships are bound to their owner');
  await denied('cannot modify another user membership', () =>
    updateDoc(doc(cdb, 'memberships', 'mB'), { tier: 'PLATINUM' })
  );
  await denied('cannot create a membership for someone else', () =>
    setDoc(doc(cdb, 'memberships', 'mNew'), { userId: uidB, tier: 'PLATINUM' })
  );
  await allowed('CAN create own membership record', () =>
    setDoc(doc(cdb, 'memberships', 'mMine'), { userId: uidA, tier: 'FREE' })
  );

  console.log('\nFindings 7 & 8 - admin surface');
  await denied('non-admin cannot read the admin roster', () =>
    getDocs(collection(cdb, 'admin_users'))
  );
  await denied('non-admin cannot make themselves an admin', () =>
    setDoc(doc(cdb, 'admin_users', uidA), { role: 'superAdmin' })
  );


  console.log('');
  console.log('Finding 7 - the catch-all is gone');
  await adb.collection('orders').doc('oB').set({ userId: uidB, amount: 999 });
  await adb.collection('orders').doc('oA').set({ userId: uidA, amount: 10 });
  await adb.collection('leads').doc('l1').set({ email: 'lead@x.y' });
  await adb.collection('daily_phrases').doc('p1').set({ phrase: 'ciao' });
  await adb.collection('userSettings').doc(uidB).set({ language: 'it' });
  await adb.collection('a_collection_nobody_declared').doc('x').set({ a: 1 });

  const mustDenyRead = (path, id) => () =>
    getDoc(doc(cdb, path, id)).then((d) => {
      // A denied READ on a doc that exists surfaces as permission-denied; this
      // guard catches the case where the rule silently allowed it instead.
      if (d.exists()) throw new Error('document was readable');
    });

  await denied('cannot read another user order', mustDenyRead('orders', 'oB'));
  await allowed('CAN read own order', () =>
    getDoc(doc(cdb, 'orders', 'oA')).then((d) => {
      if (!d.exists()) throw new Error('own order not readable');
    })
  );
  await denied('cannot list leads', () => getDocs(collection(cdb, 'leads')));
  await allowed('CAN read public reference content', () =>
    getDoc(doc(cdb, 'daily_phrases', 'p1')).then((d) => {
      if (!d.exists()) throw new Error('reference content not readable');
    })
  );
  await denied('cannot write public reference content', () =>
    setDoc(doc(cdb, 'daily_phrases', 'p2'), { phrase: 'forged' })
  );
  await denied('cannot read another user settings', mustDenyRead('userSettings', uidB));
  await allowed('CAN write own settings', () =>
    setDoc(doc(cdb, 'userSettings', uidA), { language: 'en' })
  );
  await denied('an undeclared collection is denied by default',
    mustDenyRead('a_collection_nobody_declared', 'x'));

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('harness error:', e);
  process.exit(1);
});
