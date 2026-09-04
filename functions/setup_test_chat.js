/**
 * Creates two throwaway accounts and a conversation between them, so the web
 * app's chat translation can be exercised end to end without touching anyone's
 * real account or reading a real conversation.
 *
 * Everything it writes is prefixed/marked so teardown_test_chat.js can remove
 * it again. Run teardown when finished.
 */
const admin = require('firebase-admin');
const sa = require('C:/Users/Software Engineering/Desktop/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();
const auth = admin.auth();

const PASSWORD = 'GreenGoTest!2026';
const A = { email: 'qa.translate.a@greengo-test.local', name: 'QA Alice', nick: 'qa_alice' };
const B = { email: 'qa.translate.b@greengo-test.local', name: 'QA Bruno', nick: 'qa_bruno' };

// Message deliberately in Italian. The test account's app language is English,
// so translation MUST fire — this rules out the "same language, skipped by
// design" explanation.
const ITALIAN = 'Ciao! Come stai oggi? Ti va di prendere un caffe insieme domani?';

async function ensureUser(u) {
  try {
    const existing = await auth.getUserByEmail(u.email);
    await auth.updateUser(existing.uid, { password: PASSWORD });
    return existing.uid;
  } catch (_) {
    const created = await auth.createUser({
      email: u.email, password: PASSWORD, displayName: u.name,
    });
    return created.uid;
  }
}

function profile(uid, u, languages) {
  const now = admin.firestore.Timestamp.now();
  return {
    userId: uid,
    displayName: u.name,
    nickname: u.nick,
    dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1995-05-05')),
    gender: 'Other',
    photoUrls: [],
    privatePhotoUrls: [],
    bio: 'Temporary QA account used to verify chat translation.',
    interests: ['Travel', 'Music', 'Coffee'],
    location: {
      latitude: 41.9028, longitude: 12.4964,
      city: 'Rome', country: 'Italy', displayAddress: 'Rome, Italy',
    },
    languages,
    createdAt: now,
    updatedAt: now,
    isComplete: true,
    // Phone-verified accounts are auto-approved, so the app lets us straight in
    // instead of parking us on the "verification pending" screen.
    verificationStatus: 'approved',
    verificationMethod: 'phone',
    verificationReviewedAt: now,
    accountStatus: 'active',
    isAdmin: false,
    isSupport: false,
    membershipTier: 'PLATINUM', // so tier-gated features are testable too
    hasBaseMembership: true,
    isOnline: false,
    isQaFixture: true,
  };
}

(async () => {
  const uidA = await ensureUser(A);
  const uidB = await ensureUser(B);
  console.log('user A (we log in as this one):', uidA);
  console.log('user B (writes the Italian msg):', uidB);

  await db.collection('profiles').doc(uidA).set(profile(uidA, A, ['English']), { merge: true });
  await db.collection('profiles').doc(uidB).set(profile(uidB, B, ['Italian']), { merge: true });
  await db.collection('users').doc(uidA).set({ email: A.email, locale: 'en', isQaFixture: true }, { merge: true });
  await db.collection('users').doc(uidB).set({ email: B.email, locale: 'it', isQaFixture: true }, { merge: true });

  // A's app language must be English for the Italian message to need translating.
  await db.collection('userSettings').doc(uidA).set({ language: 'en', isQaFixture: true }, { merge: true });

  const convRef = db.collection('conversations').doc('qa_translate_fixture');
  const now = admin.firestore.Timestamp.now();
  await convRef.set({
    conversationId: convRef.id,
    matchId: 'qa_translate_match',
    userId1: uidA,
    userId2: uidB,
    conversationType: 'match',
    createdAt: now,
    lastMessageAt: now,
    unreadCount: 1,
    isDeleted: false,
    isQaFixture: true,
    lastMessage: {
      messageId: 'qa_msg_1',
      senderId: uidB,
      receiverId: uidA,
      content: ITALIAN,
      type: 'text',
      sentAt: now,
    },
  }, { merge: true });

  await convRef.collection('messages').doc('qa_msg_1').set({
    messageId: 'qa_msg_1',
    conversationId: convRef.id,
    matchId: 'qa_translate_match',
    senderId: uidB,
    receiverId: uidA,
    content: ITALIAN,
    type: 'text',
    sentAt: now,
    deliveredAt: now,
    isQaFixture: true,
  }, { merge: true });

  console.log('\nconversation:', convRef.id);
  console.log('italian message:', ITALIAN);
  console.log('\nlogin ->', A.email, '/', PASSWORD);
})().catch((e) => { console.error('ERR', e); process.exit(1); });
