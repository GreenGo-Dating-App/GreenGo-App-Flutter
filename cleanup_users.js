const admin = require('firebase-admin');
const { execSync } = require('child_process');
const { GoogleAuth } = require('google-auth-library');

// Use gcloud access token directly
const accessToken = execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();

admin.initializeApp({
  projectId: 'greengo-chat',
  credential: {
    getAccessToken: () => Promise.resolve({ access_token: accessToken, expires_in: 3600 }),
  },
});

const KEEP_UID = 'hu757P3dXzdeSFbvfb5dviDqpaF2';
const firestore = admin.firestore();

const TOP_LEVEL = [
  'profiles', 'users', 'userSettings', 'coinBalances', 'subscriptions',
  'memberships', 'membership_purchases', 'userLevels', 'userAchievements',
  'userBadges', 'userChallenges', 'userVibeTags', 'user_levels',
  'user_vectors', 'user_interactions', 'notification_preferences',
  'match_preferences', 'streaks', 'dailyUsage', 'usageLimits',
  'achievement_progress', 'language_progress', 'learning_progress',
  'daily_hints_progress', 'videoCoinBalances',
];

const QUERY_COLS = {
  'swipes': ['userId', 'targetUserId'],
  'matches': ['userId1', 'userId2'],
  'conversations': ['participants'],
  'notifications': ['userId'],
  'blockedUsers': ['userId', 'blockedUserId'],
  'user_reports': ['reporterId', 'reportedUserId'],
  'message_reports': ['reporterId'],
  'coinTransactions': ['userId'],
  'coinGifts': ['senderId', 'receiverId'],
  'coinOrders': ['userId'],
  'purchases': ['userId'],
  'support_chats': ['userId'],
  'photo_likes': ['userId', 'targetUserId'],
  'sentVirtualGifts': ['senderId'],
  'secondChancePool': ['userId'],
  'blindMatches': ['userId1', 'userId2'],
  'scheduledDates': ['userId1', 'userId2'],
  'call_history': ['callerId', 'receiverId'],
  'album_access': ['ownerId', 'grantedToUserId'],
  'account_actions': ['userId'],
  'videoCoinTransactions': ['userId'],
  'xp_transactions': ['userId'],
};

const SUBCOLS = ['coinBatches', 'coinTransactions', 'messages', 'support_messages', 'days', 'hours'];

async function deleteSubs(docRef) {
  for (const sub of SUBCOLS) {
    try {
      const docs = await docRef.collection(sub).limit(500).get();
      const batch = firestore.batch();
      docs.forEach(d => batch.delete(d.ref));
      if (docs.size > 0) await batch.commit();
    } catch (_) {}
  }
}

async function main() {
  console.log('=== Fetching Auth users ===');
  const list = await admin.auth().listUsers(1000);
  const toDelete = list.users.filter(u => u.uid !== KEEP_UID);
  console.log(`Total: ${list.users.length}, Keeping: support@greengochat.com, Deleting: ${toDelete.length}\n`);

  const uids = toDelete.map(u => u.uid);

  // Delete top-level Firestore docs
  console.log('=== Deleting Firestore (top-level) ===');
  for (const uid of uids) {
    for (const col of TOP_LEVEL) {
      try {
        const ref = firestore.collection(col).doc(uid);
        const doc = await ref.get();
        if (doc.exists) {
          await deleteSubs(ref);
          await ref.delete();
          console.log(`  ${col}/${uid.substring(0,8)}...`);
        }
      } catch (e) { console.log(`  err: ${col}/${uid.substring(0,8)}: ${e.code || e.message}`); }
    }
  }

  // Delete query-based docs
  console.log('\n=== Deleting Firestore (query-based) ===');
  for (const [col, fields] of Object.entries(QUERY_COLS)) {
    for (const field of fields) {
      for (const uid of uids) {
        try {
          const q = field === 'participants'
            ? firestore.collection(col).where(field, 'array-contains', uid)
            : firestore.collection(col).where(field, '==', uid);
          const snap = await q.get();
          if (snap.size > 0) {
            for (const doc of snap.docs) {
              await deleteSubs(doc.ref);
              await doc.ref.delete();
            }
            console.log(`  ${col}.${field}: ${snap.size} docs (${uid.substring(0,8)}...)`);
          }
        } catch (e) { console.log(`  err: ${col}.${field}: ${e.code || e.message}`); }
      }
    }
  }

  // Delete Auth users
  console.log('\n=== Deleting Auth accounts ===');
  const result = await admin.auth().deleteUsers(uids);
  console.log(`Deleted: ${result.successCount}, Failed: ${result.failureCount}`);
  if (result.failureCount > 0) {
    result.errors.forEach(e => console.log(`  fail: ${e.error.message}`));
  }

  console.log('\nDone! Only support@greengochat.com remains.');
  process.exit(0);
}

main().catch(e => { console.error('Fatal:', e.message || e); process.exit(1); });
