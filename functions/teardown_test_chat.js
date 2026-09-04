/**
 * Removes everything setup_test_chat.js created: the two QA auth users, their
 * profiles/users/userSettings docs, and the fixture conversation.
 *
 * Run when the chat-crash investigation is finished:
 *   node teardown_test_chat.js
 */
const admin = require('firebase-admin');
const sa = require('C:/Users/Software Engineering/Desktop/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();
const auth = admin.auth();

const EMAILS = [
  'qa.translate.a@greengo-test.local',
  'qa.translate.b@greengo-test.local',
];
const CONV = 'qa_translate_fixture';

(async () => {
  for (const email of EMAILS) {
    try {
      const u = await auth.getUserByEmail(email);
      for (const col of ['profiles', 'users', 'userSettings']) {
        await db.collection(col).doc(u.uid).delete().catch(() => {});
      }
      await auth.deleteUser(u.uid);
      console.log('removed', email, u.uid);
    } catch (e) {
      console.log('skip', email, '-', e.message);
    }
  }

  const conv = db.collection('conversations').doc(CONV);
  const msgs = await conv.collection('messages').get();
  for (const m of msgs.docs) await m.ref.delete();
  await conv.delete().catch(() => {});
  console.log('removed conversation', CONV, `(+${msgs.size} message(s))`);
})().catch((e) => { console.error('ERR', e); process.exit(1); });
