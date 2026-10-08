/**
 * Phase 0 Firestore rules: real-client test against the emulators.
 * Signs in through the Auth emulator and uses the same web SDK the apps use,
 * so it exercises exactly what an attacker (or the real app) can do.
 * ATTACK cases must be DENIED; LEGIT cases (copied from the app's own writes)
 * must be ALLOWED.
 *
 *   firebase emulators:exec --only firestore,auth --project demo-gg \
 *     "node functions/__tests__/security/phase0.rules.emulator.js"
 * Needs NODE_PATH pointing at a node_modules that has `firebase` (web SDK)
 * and `firebase-admin`.
 */
const PROJECT = process.env.GCLOUD_PROJECT || 'demo-gg';
if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(process.env.FIRESTORE_EMULATOR_HOST || '')) {
  throw new Error('Refusing to run outside the local emulator');
}
const admin = require('firebase-admin');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signOut } = require('firebase/auth');
const fs = require('firebase/firestore');

admin.initializeApp({ projectId: PROJECT });
const adb = admin.firestore();

const results = [];
async function expectOk(name, fn) {
  try { await fn(); results.push(['PASS', 'LEGIT ', name]); }
  catch (e) { results.push(['FAIL', 'LEGIT ', `${name} -> ${e.code || e.message}`]); }
}
async function expectDenied(name, fn) {
  try { await fn(); results.push(['FAIL', 'ATTACK', `${name} -> was ALLOWED`]); }
  catch (e) {
    const denied = e.code === 'permission-denied';
    results.push([denied ? 'PASS' : 'FAIL', 'ATTACK', `${name}${denied ? '' : ' -> ' + (e.code || e.message)}`]);
  }
}

let n = 0;
async function client(email) {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake-api-key' }, `c${n++}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
  const db = fs.getFirestore(app);
  const [h, p] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  fs.connectFirestoreEmulator(db, h === '0.0.0.0' ? '127.0.0.1' : h, Number(p));
  let uid = null;
  if (email) uid = (await createUserWithEmailAndPassword(auth, email, 'Passw0rd!x')).user.uid;
  return { app, auth, db, uid };
}

(async () => {
  const anon = await client(null);
  const alice = await client('alice@example.com');
  const bob = await client('bob@example.com');
  const A = alice.uid, B = bob.uid;
  const D = (c, path) => fs.doc(c.db, path);

  // ---- seed (admin, bypasses rules) ----
  await adb.doc('app_config/version').set({ minVersion: '1.0.0' });
  await adb.doc('app_config/countdown').set({ x: 1 });
  await adb.doc('app_config/web_push').set({ vapidPublicKey: 'pub' });
  await adb.doc('app_config/settings').set({ maxPhotos: 6 });
  await adb.doc('app_config/api_keys').set({ gemini_api_key: 'k' });
  await adb.doc('app_config/resend_settings').set({ apiKey: 'secret' });
  await adb.doc(`profiles/${A}`).set({ name: 'Alice', signupGrantsAppliedAt: admin.firestore.Timestamp.now(),
    signupGrantsApplied: [{ couponId: 'welcome_2026', dismissed: false }] });
  await adb.doc(`nicknames/bobby`).set({ email: 'bob@example.com', uid: B });
  await adb.doc(`referrals/${B}`).set({ redeemedCode: 'ABC', redeemedFrom: A }); // server-written

  // ---- app_config (C-08) ----
  for (const d of ['version', 'countdown', 'web_push', 'settings']) {
    await expectOk(`anonymous app startup reads app_config/${d}`, () => fs.getDoc(D(anon, `app_config/${d}`)));
  }
  await expectOk('signed-in app reads app_config/api_keys (until P1-1)', () => fs.getDoc(D(alice, 'app_config/api_keys')));
  await expectDenied('anonymous reads app_config/api_keys', () => fs.getDoc(D(anon, 'app_config/api_keys')));
  await expectDenied('signed-in user reads app_config/resend_settings', () => fs.getDoc(D(alice, 'app_config/resend_settings')));
  await expectDenied('anonymous lists app_config', () => fs.getDocs(fs.collection(anon.db, 'app_config')));

  // ---- nicknames (C-06) ----
  await expectOk('registration writes own nickname {email, uid}', () =>
    fs.setDoc(D(alice, 'nicknames/ali'), { email: 'alice@example.com', uid: A, createdAt: fs.serverTimestamp() }));
  await expectOk('nickname login: anonymous get by id', () => fs.getDoc(D(anon, 'nicknames/bobby')));
  await expectDenied('anonymous lists all nicknames (email dump)', () => fs.getDocs(fs.collection(anon.db, 'nicknames')));
  await expectDenied('signed-in lists all nicknames', () => fs.getDocs(fs.collection(alice.db, 'nicknames')));
  await expectDenied('hijack another user\'s nickname mapping', () =>
    fs.setDoc(D(alice, 'nicknames/bobby'), { email: 'alice@example.com', uid: A }));

  // ---- referrals (C-05) ----
  await expectOk('getOrCreateCode on a new doc', () =>
    fs.setDoc(D(alice, `referrals/${A}`), { code: 'ALICE1', invitedCount: 0, coinsEarned: 0 }, { merge: true }));
  await expectOk('getOrCreateCode on a doc the server already wrote (redeemed user)', () =>
    fs.setDoc(D(bob, `referrals/${B}`), { code: 'BOB111', invitedCount: 0, coinsEarned: 0 }, { merge: true }));
  await expectDenied('clear own redeemedCode to redeem again', () =>
    fs.updateDoc(D(bob, `referrals/${B}`), { redeemedCode: fs.deleteField() }));
  await expectDenied('inflate own invitedCount', () => fs.updateDoc(D(alice, `referrals/${A}`), { invitedCount: 999 }));
  await expectDenied('write arbitrary fields on someone else\'s referral doc', () =>
    fs.updateDoc(D(alice, `referrals/${B}`), { invitedCount: 50, code: 'STOLEN' }));

  // ---- coinGifts (C-01) ----
  await expectOk('sendGift: pending gift from me to someone else', () =>
    fs.setDoc(D(alice, 'coinGifts/g1'), { senderId: A, receiverId: B, amount: 100, message: null,
      status: 'pending', sentAt: fs.Timestamp.now(), receivedAt: null, expiresAt: fs.Timestamp.now() }));
  await expectOk('shop direct send: accepted gift record', () =>
    fs.setDoc(D(alice, 'coinGifts/g2'), { giftId: 'g2', senderId: A, receiverId: B, amount: 50, status: 'accepted',
      sentAt: fs.serverTimestamp(), receivedAt: fs.serverTimestamp() }));
  await expectDenied('forge a gift in someone else\'s name', () =>
    fs.setDoc(D(alice, 'coinGifts/f1'), { senderId: B, receiverId: A, amount: 100, status: 'pending' }));
  await expectDenied('gift to yourself', () =>
    fs.setDoc(D(alice, 'coinGifts/f2'), { senderId: A, receiverId: A, amount: 100, status: 'pending' }));
  await expectDenied('absurd amount', () =>
    fs.setDoc(D(alice, 'coinGifts/f3'), { senderId: A, receiverId: B, amount: 1000000, status: 'pending' }));
  await expectDenied('sender tampers with own pending gift', () => fs.updateDoc(D(alice, 'coinGifts/g1'), { amount: 9999 }));
  await expectOk('acceptGift: receiver accepts pending gift', () =>
    fs.updateDoc(D(bob, 'coinGifts/g1'), { status: 'accepted', receivedAt: fs.Timestamp.now() }));
  await expectDenied('receiver flips accepted gift back to pending', () =>
    fs.updateDoc(D(bob, 'coinGifts/g1'), { status: 'pending' }));

  // ---- profiles signup marker (C-04) ----
  await expectOk('dismiss welcome banner (signupGrantsApplied update)', () =>
    fs.updateDoc(D(alice, `profiles/${A}`), { signupGrantsApplied: [{ couponId: 'welcome_2026', dismissed: true }] }));
  await expectOk('normal profile edit', () => fs.updateDoc(D(alice, `profiles/${A}`), { bio: 'hello' }));
  await expectDenied('clear signupGrantsAppliedAt', () =>
    fs.updateDoc(D(alice, `profiles/${A}`), { signupGrantsAppliedAt: fs.deleteField() }));

  for (const c of [anon, alice, bob]) { await signOut(c.auth).catch(() => {}); await deleteApp(c.app); }
  const failed = results.filter((r) => r[0] !== 'PASS');
  for (const r of results) console.log(`${r[0]}  ${r[1]}  ${r[2]}`);
  console.log(`\n${results.length - failed.length}/${results.length} passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
