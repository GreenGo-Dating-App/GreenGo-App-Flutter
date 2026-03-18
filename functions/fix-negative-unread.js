const admin = require('firebase-admin');

// Initialize with default credentials (uses gcloud auth)
if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'greengo-chat' });
}

const db = admin.firestore();

async function fixNegativeUnreadCounts() {
  console.log('Scanning conversations for negative unreadCount...');

  const snapshot = await db.collection('conversations').get();
  let fixed = 0;
  let total = 0;

  for (const doc of snapshot.docs) {
    total++;
    const data = doc.data();
    const unreadCount = data.unreadCount;

    if (unreadCount !== undefined && unreadCount < 0) {
      console.log(`  FIX: ${doc.id} unreadCount=${unreadCount} → 0`);
      await doc.ref.update({ unreadCount: 0 });
      fixed++;
    }
  }

  console.log(`\nDone. Scanned ${total} conversations, fixed ${fixed} negative counts.`);
}

fixNegativeUnreadCounts().catch(console.error);
