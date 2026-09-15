/**
 * Seeds the seven fixture accounts the end-to-end suites expect.
 *
 * Runs against the LOCAL EMULATOR ONLY. It refuses to run without the
 * emulator environment variables set, because every account it creates is one
 * a test will later ban, reject or delete — none of that belongs in
 * production.
 *
 *   firebase emulators:start --only auth,firestore,storage,functions
 *   node tool/e2e_seed.js
 *
 * Add --reset to delete the fixture accounts and their documents first, which
 * is what a run that left data behind needs.
 */
const admin = require('firebase-admin');

const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const STORE_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_HOST;
process.env.FIRESTORE_EMULATOR_HOST = STORE_HOST;

if (process.env.E2E_ALLOW_PRODUCTION === 'yes-really') {
  console.warn('!! seeding a NON-emulator project because E2E_ALLOW_PRODUCTION is set');
} else if (!AUTH_HOST.startsWith('127.0.0.1') && !AUTH_HOST.startsWith('localhost')) {
  console.error('Refusing to run: the auth emulator host is not local.');
  process.exit(2);
}

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'greengo-chat' });
const db = admin.firestore();
const auth = admin.auth();

/** The six access-gate states plus a peer, matching E2EConfig. */
const FIXTURES = [
  { key: 'approved', email: 'approved@e2e.greengo.test', password: 'E2e-Approved!2026',
    name: 'E2E Main',     approvalStatus: 'approved', verificationStatus: 'approved' },
  { key: 'peer',     email: 'peer@e2e.greengo.test',     password: 'E2e-Peer!2026',
    name: 'E2E Peer',     approvalStatus: 'approved', verificationStatus: 'approved' },
  { key: 'pending',  email: 'pending@e2e.greengo.test',  password: 'E2e-Pending!2026',
    name: 'E2E Pending',  approvalStatus: 'pending',  verificationStatus: 'pending' },
  { key: 'rejected', email: 'rejected@e2e.greengo.test', password: 'E2e-Rejected!2026',
    name: 'E2E Rejected', approvalStatus: 'rejected', verificationStatus: 'rejected' },
  { key: 'banned',   email: 'banned@e2e.greengo.test',   password: 'E2e-Banned!2026',
    name: 'E2E Banned',   approvalStatus: 'approved', verificationStatus: 'approved', isBanned: true },
  { key: 'admin',    email: 'admin@e2e.greengo.test',    password: 'E2e-Admin!2026',
    name: 'E2E Admin',    approvalStatus: 'approved', verificationStatus: 'approved', isAdmin: true },
  // Authenticated with no profile document: the onboarding entry state.
  { key: 'fresh',    email: 'fresh@e2e.greengo.test',    password: 'E2e-Fresh!2026',
    name: null },
];

async function uidFor(email) {
  try { return (await auth.getUserByEmail(email)).uid; } catch { return null; }
}

async function ensureUser(f) {
  let uid = await uidFor(f.email);
  if (uid) {
    await auth.updateUser(uid, { password: f.password });
  } else {
    uid = (await auth.createUser({
      email: f.email, password: f.password, emailVerified: true,
    })).uid;
  }
  return uid;
}

async function seedOne(f) {
  const uid = await ensureUser(f);

  if (f.name === null) {
    // The fresh account deliberately has no profile.
    await db.collection('profiles').doc(uid).delete().catch(() => {});
    await db.collection('users').doc(uid).delete().catch(() => {});
    console.log(`  ${f.key.padEnd(9)} ${uid}  (no profile, for onboarding)`);
    return;
  }

  await db.collection('profiles').doc(uid).set({
    userId: uid,
    displayName: f.name,
    nickname: `e2e_${f.key}`,
    bio: 'Seeded fixture for the end-to-end suites.',
    dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1995-06-15')),
    isComplete: true,
    isBanned: !!f.isBanned,
    isAdmin: !!f.isAdmin,
    isBusiness: false,
    verificationStatus: f.verificationStatus,
    membershipTier: 'FREE',
    languages: ['en', 'it'],
    nativeLanguage: 'en',
    preferredLanguages: ['en'],
    primaryOrigin: 'IT',
    photoUrls: [],
    interests: ['culture', 'languages'],
    showOnMap: true,
    isOnline: true,
    location: new admin.firestore.GeoPoint(41.9028, 12.4964),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection('users').doc(uid).set({
    email: f.email,
    approvalStatus: f.approvalStatus,
    membershipTier: 'FREE',
    isAdmin: !!f.isAdmin,
    accessDate: admin.firestore.Timestamp.fromDate(new Date('2020-01-01')),
    hasEarlyAccess: true,
    notificationsEnabled: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`  ${f.key.padEnd(9)} ${uid}  ${f.approvalStatus}${f.isBanned ? ' banned' : ''}${f.isAdmin ? ' admin' : ''}`);
}

async function reset() {
  console.log('removing existing fixtures...');
  for (const f of FIXTURES) {
    const uid = await uidFor(f.email);
    if (!uid) continue;
    await db.collection('profiles').doc(uid).delete().catch(() => {});
    await db.collection('users').doc(uid).delete().catch(() => {});
    await auth.deleteUser(uid).catch(() => {});
  }
}

/**
 * Discovery needs a population, or DISC-01 has nothing to assert against and
 * DISC-02 cannot tell a working filter from an empty database.
 */
async function seedCrowd(count = 40) {
  const batch = db.batch();
  const countries = ['IT', 'BR', 'JP', 'FR', 'DE', 'ES'];
  for (let i = 0; i < count; i++) {
    const ref = db.collection('profiles').doc(`e2e_crowd_${i}`);
    batch.set(ref, {
      userId: `e2e_crowd_${i}`,
      displayName: `E2E Crowd ${i}`,
      nickname: `e2e_crowd_${i}`,
      isComplete: true,
      isBanned: false,
      verificationStatus: 'approved',
      membershipTier: 'FREE',
      languages: ['en'],
      primaryOrigin: countries[i % countries.length],
      photoUrls: [],
      showOnMap: true,
      isOnline: true,
      dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1996-01-01')),
      location: new admin.firestore.GeoPoint(41.9 + i * 0.01, 12.5 + i * 0.01),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await batch.commit();
  console.log(`  seeded ${count} discovery profiles`);
}

(async () => {
  if (process.argv.includes('--reset')) await reset();
  console.log(`seeding fixtures against auth=${AUTH_HOST} firestore=${STORE_HOST}`);
  for (const f of FIXTURES) await seedOne(f);
  await seedCrowd();
  console.log('\ndone.');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
