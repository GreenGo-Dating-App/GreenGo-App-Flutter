/**
 * One-time script: Populate the public 'nicknames' collection
 * so nickname login works before authentication.
 *
 * Each doc: nicknames/{nickname} → { uid, nickname, createdAt }
 * INC-2026-001: NEVER write the email here. The collection is publicly
 * readable by id; nickname sign-in resolves the email on the server
 * (signInWithNickname). Existing docs are only created when missing.
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

    if (!nickname) {
      console.log(`  SKIP ${uid}: no nickname`);
      skipped++;
      continue;
    }

    const normalizedNickname = nickname.toLowerCase();
    const ref = firestore.collection('nicknames').doc(normalizedNickname);
    const existing = await ref.get();
    if (existing.exists) {
      skipped++;
      continue;
    }
    await ref.set({
      uid,
      nickname: normalizedNickname,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  CREATED nicknames/${normalizedNickname}`);
    created++;
  }

  console.log(`\nDone! Created: ${created}, Skipped: ${skipped}`);
  process.exit(0);
}

populateNicknames().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
