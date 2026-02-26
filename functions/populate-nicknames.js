/**
 * One-time script: Populate the public 'nicknames' collection
 * so nickname login works before authentication.
 *
 * Each doc: nicknames/{nickname} → { email, uid }
 *
 * Run from the functions/ directory:
 *   node populate-nicknames.js
 */

const admin = require('firebase-admin');
const path = require('path');
const os = require('os');

// Use service account key (will be created temporarily)
const serviceAccount = require(path.join(os.tmpdir(), 'greengo-sa-key.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'greengo-chat',
});

const firestore = admin.firestore();

async function populateNicknames() {
  console.log('Fetching all profiles with nicknames...');

  const profilesSnap = await firestore.collection('profiles').get();
  let created = 0;
  let skipped = 0;

  for (const doc of profilesSnap.docs) {
    const data = doc.data();
    const uid = doc.id;
    const nickname = data.nickname;
    const email = data.email;

    if (!nickname || !email) {
      console.log(`  SKIP ${uid}: nickname=${nickname || 'null'}, email=${email || 'null'}`);
      skipped++;
      continue;
    }

    const normalizedNickname = nickname.toLowerCase();
    await firestore.collection('nicknames').doc(normalizedNickname).set({
      email,
      uid,
    });
    console.log(`  CREATED nicknames/${normalizedNickname} → ${email}`);
    created++;
  }

  console.log(`\nDone! Created: ${created}, Skipped: ${skipped}`);
  process.exit(0);
}

populateNicknames().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
