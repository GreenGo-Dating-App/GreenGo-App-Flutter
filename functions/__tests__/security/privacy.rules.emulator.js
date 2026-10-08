/**
 * P1-4 profiles_private rules: real-client test against the emulators.
 * Signs in through the Auth emulator with the web SDK the apps use.
 * ATTACK cases must be DENIED; LEGIT cases (the new app's own writes) ALLOWED.
 *
 *   NODE_PATH=<node_modules with firebase + firebase-admin> \
 *   firebase emulators:exec --config ../firebase.emulators.<you>.json --only firestore,auth \
 *     --project demo-gg "node __tests__/security/privacy.rules.emulator.js"
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
  const sfx = Date.now();
  const anon = await client(null);
  const alice = await client(`alice${sfx}@example.com`);
  const bob = await client(`bob${sfx}@example.com`);
  const mod = await client(`mod${sfx}@example.com`);
  const A = alice.uid, B = bob.uid;
  const D = (c, path) => fs.doc(c.db, path);

  await adb.doc(`admin_users/${mod.uid}`).set({ role: 'moderator' });
  await adb.doc(`profiles/${A}`).set({ displayName: 'Alice' });
  await adb.doc(`profiles/${B}`).set({ displayName: 'Bob' });
  // Server-written private doc for Bob (mirror trigger).
  await adb.doc(`profiles_private/${B}`).set({ email: 'bob@example.com', birthMonthDay: '01-01',
    ageVerification: { documentHash: 'h' } });

  // ---- LEGIT: what the new app writes ----
  await expectOk('onboarding creates own private profile', () =>
    fs.setDoc(D(alice, `profiles_private/${A}`), {
      location: { latitude: 41.9, longitude: 12.5 }, geohash: 'sr2yk3abc',
      dateOfBirth: fs.Timestamp.fromDate(new Date('1995-05-20')), sexualOrientation: 'straight',
      email: 'alice@example.com', verificationPhone: '+39', privatePhotoUrls: [],
      verificationPhotoPath: `verifications/${A}/1.jpg`, updatedAt: fs.serverTimestamp(),
    }));
  await expectOk('location refresh (merge update of location + geohash)', () =>
    fs.setDoc(D(alice, `profiles_private/${A}`), { location: { latitude: 45.4, longitude: 9.1 }, geohash: 'u0nd9abcd' }, { merge: true }));
  await expectOk('edit DOB', () =>
    fs.updateDoc(D(alice, `profiles_private/${A}`), { dateOfBirth: fs.Timestamp.fromDate(new Date('1994-05-20')) }));
  await expectOk('owner reads own private profile', () => fs.getDoc(D(alice, `profiles_private/${A}`)));
  await expectOk('admin_users member reads a private profile', () => fs.getDoc(D(mod, `profiles_private/${A}`)));
  await expectOk('owner updates a doc that holds server-owned fields (untouched)', () =>
    fs.updateDoc(D(bob, `profiles_private/${B}`), { sexualOrientation: 'gay' }));

  // ---- ATTACK ----
  await expectDenied('other user reads someone\'s private profile', () => fs.getDoc(D(bob, `profiles_private/${A}`)));
  await expectDenied('anonymous reads a private profile', () => fs.getDoc(D(anon, `profiles_private/${A}`)));
  await expectDenied('other user lists profiles_private', () => fs.getDocs(fs.collection(bob.db, 'profiles_private')));
  await expectDenied('other user writes someone\'s private profile', () =>
    fs.setDoc(D(bob, `profiles_private/${A}`), { email: 'x' }, { merge: true }));
  await expectDenied('owner forges ageVerification', () =>
    fs.updateDoc(D(alice, `profiles_private/${A}`), { ageVerification: { documentHash: 'forged' } }));
  await expectDenied('owner rewrites server-owned birthMonthDay', () =>
    fs.updateDoc(D(bob, `profiles_private/${B}`), { birthMonthDay: '12-31' }));
  await expectDenied('owner sets the legacy verificationPhotoUrl', () =>
    fs.updateDoc(D(alice, `profiles_private/${A}`), { verificationPhotoUrl: 'https://x' }));
  await expectDenied('owner points verificationPhotoPath at another user\'s file', () =>
    fs.updateDoc(D(alice, `profiles_private/${A}`), { verificationPhotoPath: `verifications/${B}/1.jpg` }));
  await expectDenied('owner creates own private profile with a server-owned key', () =>
    fs.setDoc(D(mod, `profiles_private/${mod.uid}`), { email: 'x', birthMonthDay: '01-01' }));
  await expectDenied('user creates a private profile under another uid', () =>
    fs.setDoc(D(bob, `profiles_private/${A}x`), { email: 'x' }));
  await expectDenied('owner deletes own private profile', () => fs.deleteDoc(D(alice, `profiles_private/${A}`)));
  await expectDenied('admin deletes a private profile from a client', () => fs.deleteDoc(D(mod, `profiles_private/${A}`)));

  for (const c of [anon, alice, bob, mod]) { await signOut(c.auth).catch(() => {}); await deleteApp(c.app); }
  const failed = results.filter((r) => r[0] !== 'PASS');
  for (const r of results) console.log(`${r[0]}  ${r[1]}  ${r[2]}`);
  console.log(`\n${results.length - failed.length}/${results.length} passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
