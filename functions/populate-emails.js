/**
 * One-time script: Populate email field on profiles and users docs
 * for all existing Firebase Auth users.
 *
 * Run from the functions/ directory:
 *   node populate-emails.js
 */

const admin = require('firebase-admin');

// Use service account key
const path = require('path');
const os = require('os');
const serviceAccount = require(path.join(os.tmpdir(), 'greengo-sa-key.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'greengo-chat',
});

const firestore = admin.firestore();
const auth = admin.auth();

async function populateEmails() {
  console.log('Fetching all Firebase Auth users...');

  let nextPageToken;
  let totalUpdated = 0;
  let totalSkipped = 0;

  do {
    const listResult = await auth.listUsers(1000, nextPageToken);

    for (const user of listResult.users) {
      const uid = user.uid;
      const email = user.email;

      if (!email) {
        console.log(`  SKIP ${uid}: no email in Firebase Auth`);
        totalSkipped++;
        continue;
      }

      // Update profiles doc
      try {
        const profileDoc = await firestore.collection('profiles').doc(uid).get();
        if (profileDoc.exists) {
          const data = profileDoc.data();
          const nickname = data.nickname || '(no nickname)';
          if (!data.email || data.email !== email) {
            await firestore.collection('profiles').doc(uid).update({ email });
            console.log(`  UPDATED profiles/${uid} (${nickname}): ${email}`);
          } else {
            console.log(`  OK      profiles/${uid} (${nickname}): already has ${email}`);
          }
        } else {
          console.log(`  SKIP    profiles/${uid}: profile doc does not exist`);
        }
      } catch (e) {
        console.error(`  ERROR   profiles/${uid}: ${e.message}`);
      }

      // Update users doc
      try {
        await firestore.collection('users').doc(uid).set(
          { email },
          { merge: true }
        );
      } catch (e) {
        console.error(`  ERROR   users/${uid}: ${e.message}`);
      }

      totalUpdated++;
    }

    nextPageToken = listResult.pageToken;
  } while (nextPageToken);

  console.log(`\nDone! Updated: ${totalUpdated}, Skipped: ${totalSkipped}`);
  process.exit(0);
}

populateEmails().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
