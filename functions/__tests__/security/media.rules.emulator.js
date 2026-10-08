/**
 * P1-3 (audit H-06 / L-01): private chat, group and support media in Cloud
 * Storage. Real-client test against the Storage + Firestore + Auth emulators.
 *
 * Signs in through the Auth emulator and uses the same web SDK
 * (`firebase/storage`) the apps use, so it exercises exactly what an attacker
 * (or the real app) can do. Membership lives in Firestore and is read by the
 * Storage rules through cross-service firestore.get()/exists().
 * ATTACK cases must be DENIED; LEGIT cases (copied from the app's own upload
 * code: chat_screen.dart, group_chat_screen.dart, support_chat_screen.dart)
 * must be ALLOWED.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "node __tests__/security/media.rules.emulator.js"
 * Needs NODE_PATH with a node_modules that has `firebase` (web SDK) and one
 * that has `firebase-admin`.
 */
const PROJECT = process.env.GCLOUD_PROJECT || 'demo-gg';
const BUCKET = `${PROJECT}.appspot.com`;
for (const k of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(process.env[k] || '')) {
    throw new Error(`Refusing to run outside the local emulators (${k})`);
  }
}
const admin = require('firebase-admin');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signOut } = require('firebase/auth');
const st = require('firebase/storage');

admin.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
const adb = admin.firestore();

const results = [];
async function expectOk(name, fn) {
  try { await fn(); results.push(['PASS', 'LEGIT ', name]); }
  catch (e) { results.push(['FAIL', 'LEGIT ', `${name} -> ${e.code || e.message}`]); }
}
async function expectDenied(name, fn) {
  try { await fn(); results.push(['FAIL', 'ATTACK', `${name} -> was ALLOWED`]); }
  catch (e) {
    const denied = e.code === 'storage/unauthorized' || e.code === 'storage/unauthenticated';
    results.push([denied ? 'PASS' : 'FAIL', 'ATTACK', `${name}${denied ? '' : ' -> ' + (e.code || e.message)}`]);
  }
}

const host = (v) => { const [h, p] = v.split(':'); return [h === '0.0.0.0' ? '127.0.0.1' : h, Number(p)]; };
let n = 0;
async function client(email, claims) {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake-api-key', storageBucket: BUCKET }, `c${n++}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
  const storage = st.getStorage(app);
  st.connectStorageEmulator(storage, ...host(process.env.FIREBASE_STORAGE_EMULATOR_HOST));
  let uid = null;
  if (email) {
    const cred = await createUserWithEmailAndPassword(auth, email, 'Passw0rd!x');
    uid = cred.user.uid;
    if (claims) {
      await admin.auth().setCustomUserClaims(uid, claims);
      await cred.user.getIdToken(true);
    }
  }
  return { app, auth, storage, uid };
}

const bytes = (size) => new Uint8Array(size).fill(7);
const SMALL = bytes(2048);
const MB = 1024 * 1024;
const R = (c, path) => st.ref(c.storage, path);
const put = (c, path, contentType, data = SMALL, customMetadata) =>
  st.uploadBytes(R(c, path), data, customMetadata ? { contentType, customMetadata } : { contentType });

(async () => {
  const anon = await client(null);
  const alice = await client('alice@example.com');
  const bob = await client('bob@example.com');
  const mallory = await client('mallory@example.com');
  const agent = await client('agent@example.com');
  const staff = await client('staff@example.com', { adminRole: 'support' });
  const panel = await client('panel@example.com'); // admin_users doc, claim not synced yet
  const A = alice.uid, B = bob.uid, M = mallory.uid;
  const [lo, hi] = [A, B].sort();

  // ---- seed membership (admin SDK, bypasses rules) ----
  await adb.doc('matches/m1').set({ userId1: A, userId2: B, isActive: true });
  await adb.doc('conversations/c1').set({ userId1: A, userId2: B, matchId: 'm1' });
  await adb.doc('conversations/legacy1').set({ userId1: A, userId2: B }); // no matchId field
  await adb.doc('groups/g1').set({ participants: [A, B], roles: { [A]: 'admin', [B]: 'member' } });
  await adb.doc('conversations/sup1').set({ userId1: A, userId2: 'support_system', matchId: 'support',
    conversationType: 'support', supportAgentId: agent.uid });
  await adb.doc('conversations/sup2').set({ userId1: A, userId2: 'support_system', matchId: 'support',
    conversationType: 'support' });
  await adb.doc(`admin_users/${panel.uid}`).set({ role: 'support', isActive: true });

  // ================= 1:1 chat (chat_images / chat_voice / chat_videos) =================
  const img = 'chat_images/m1/11111111-aaaa.jpg';
  await expectOk('member uploads chat image (matches/{id} key, image/jpeg)', () => put(alice, img, 'image/jpeg'));
  await expectOk('uploader gets download URL right after upload', () => st.getDownloadURL(R(alice, img)));
  await expectOk('other member downloads the chat image', () => st.getBytes(R(bob, img)));
  await expectOk('member uploads voice note (audio/mp4)', () => put(bob, 'chat_voice/m1/v1.m4a', 'audio/mp4'));
  await expectOk('member uploads video (video/mp4)', () => put(alice, 'chat_videos/m1/v1.mp4', 'video/mp4'));
  await expectOk('member uploads iOS video (video/MOV)', () => put(alice, 'chat_videos/m1/v2.MOV', 'video/MOV'));
  await expectOk('member uploads 45 MB video (app limit is 50 MB)', () =>
    put(alice, 'chat_videos/m1/big.mp4', 'video/mp4', bytes(45 * MB)));
  await expectOk('search_{a}_{b} key: member uploads', () => put(alice, `chat_images/search_${lo}_${hi}/s.jpg`, 'image/jpeg'));
  await expectOk('search_{a}_{b} key: other member reads', () => st.getDownloadURL(R(bob, `chat_images/search_${lo}_${hi}/s.jpg`)));
  await expectOk('bizsearch_{owner}_{customer}: customer uploads', () => put(alice, `chat_images/bizsearch_${B}_${A}/b.jpg`, 'image/jpeg'));
  await expectOk('superlike_{sender}_{target}: target uploads voice', () => put(bob, `chat_voice/superlike_${A}_${B}/v.m4a`, 'audio/mp4'));
  await expectOk('gift_{a}_{b}: member uploads', () => put(bob, `chat_images/gift_${lo}_${hi}/g.jpg`, 'image/jpeg'));
  await expectOk('legacy key = conversations/{id} (push fallback): member uploads', () =>
    put(bob, 'chat_images/legacy1/l.jpg', 'image/jpeg'));
  await expectOk('moderation reject: uploader deletes own just-uploaded image', async () => {
    await put(alice, 'chat_images/m1/rejected.jpg', 'image/jpeg');
    await st.deleteObject(R(alice, 'chat_images/m1/rejected.jpg'));
  });
  await expectOk('upload stamped with own uploaderId', () =>
    put(alice, 'chat_images/m1/stamped.jpg', 'image/jpeg', SMALL, { uploaderId: A }));
  await expectOk('staff (adminRole claim) reads chat media for a report', () => st.getDownloadURL(R(staff, img)));

  await expectDenied('stranger gets download URL of a chat image', () => st.getDownloadURL(R(mallory, img)));
  await expectDenied('stranger downloads a chat image', () => st.getBytes(R(mallory, img)));
  await expectDenied('stranger lists a chat folder', () => st.listAll(R(mallory, 'chat_images/m1')));
  await expectDenied('stranger overwrites a chat image', () => put(mallory, img, 'image/jpeg'));
  await expectDenied('stranger uploads into someone else\'s chat', () => put(mallory, 'chat_images/m1/evil.jpg', 'image/jpeg'));
  await expectDenied('stranger deletes a chat image', () => st.deleteObject(R(mallory, img)));
  await expectDenied('stranger reads a voice note', () => st.getDownloadURL(R(mallory, 'chat_voice/m1/v1.m4a')));
  await expectDenied('stranger reads a chat video', () => st.getDownloadURL(R(mallory, 'chat_videos/m1/v1.mp4')));
  await expectDenied('stranger reads a search_{a}_{b} chat image', () =>
    st.getDownloadURL(R(mallory, `chat_images/search_${lo}_${hi}/s.jpg`)));
  await expectDenied('stranger uploads into a search_{a}_{b} chat', () =>
    put(mallory, `chat_images/search_${lo}_${hi}/evil.jpg`, 'image/jpeg'));
  await expectDenied('stranger reads via legacy conversation-id key', () =>
    st.getDownloadURL(R(mallory, 'chat_images/legacy1/l.jpg')));
  await expectDenied('upload into a chat key that does not exist', () => put(alice, 'chat_images/nope123/x.jpg', 'image/jpeg'));
  await expectDenied('unauthenticated download', () => st.getDownloadURL(R(anon, img)));
  await expectDenied('member overwrites the other member\'s image', () => put(bob, img, 'image/jpeg'));
  await expectDenied('member deletes a stamped image uploaded by the other member', () =>
    st.deleteObject(R(bob, 'chat_images/m1/stamped.jpg')));
  await expectDenied('upload stamped with someone else\'s uploaderId', () =>
    put(alice, 'chat_images/m1/forged.jpg', 'image/jpeg', SMALL, { uploaderId: B }));
  await expectDenied('chat image as text/html', () => put(alice, 'chat_images/m1/x.html', 'text/html'));
  await expectDenied('chat image as image/svg+xml (script)', () => put(alice, 'chat_images/m1/x.svg', 'image/svg+xml'));
  await expectDenied('chat image as application/octet-stream', () => put(alice, 'chat_images/m1/x.bin', 'application/octet-stream'));
  await expectDenied('voice note as application/x-msdownload', () => put(alice, 'chat_voice/m1/x.exe', 'application/x-msdownload'));
  await expectDenied('voice folder accepts only audio (video/mp4)', () => put(alice, 'chat_voice/m1/x.mp4', 'video/mp4'));
  await expectDenied('video folder refuses application/javascript', () => put(alice, 'chat_videos/m1/x.js', 'application/javascript'));
  await expectDenied('oversized chat image (11 MB > 10 MB)', () => put(alice, 'chat_images/m1/big.jpg', 'image/jpeg', bytes(11 * MB)));
  await expectDenied('oversized voice note (21 MB > 20 MB)', () => put(alice, 'chat_voice/m1/big.m4a', 'audio/mp4', bytes(21 * MB)));
  await expectDenied('oversized video (51 MB > 50 MB)', () => put(alice, 'chat_videos/m1/huge.mp4', 'video/mp4', bytes(51 * MB)));

  // ================= group chat (group_media / group_voice) =================
  const gimg = 'group_media/g1/22222222-bbbb.jpg';
  await expectOk('group member uploads image (image/jpeg)', () => put(alice, gimg, 'image/jpeg'));
  await expectOk('group member uploads video (video/mp4)', () => put(bob, 'group_media/g1/v.mp4', 'video/mp4'));
  await expectOk('group member uploads 15 MB full-res image', () => put(bob, 'group_media/g1/full.jpg', 'image/jpeg', bytes(15 * MB)));
  await expectOk('group member uploads voice (audio/mp4)', () => put(bob, 'group_voice/g1/v.m4a', 'audio/mp4'));
  await expectOk('other group member downloads image', () => st.getBytes(R(bob, gimg)));
  await expectDenied('stranger downloads group image', () => st.getBytes(R(mallory, gimg)));
  await expectDenied('stranger gets group voice URL', () => st.getDownloadURL(R(mallory, 'group_voice/g1/v.m4a')));
  await expectDenied('stranger lists group media', () => st.listAll(R(mallory, 'group_media/g1')));
  await expectDenied('stranger uploads into group', () => put(mallory, 'group_media/g1/evil.jpg', 'image/jpeg'));
  await expectDenied('stranger overwrites group image', () => put(mallory, gimg, 'image/jpeg'));
  await expectDenied('stranger uploads group voice', () => put(mallory, 'group_voice/g1/evil.m4a', 'audio/mp4'));
  await expectDenied('upload into a group that does not exist', () => put(alice, 'group_media/nogroup/x.jpg', 'image/jpeg'));
  await expectDenied('group media as application/pdf', () => put(alice, 'group_media/g1/x.pdf', 'application/pdf'));
  await expectDenied('oversized group image (21 MB > 20 MB)', () => put(alice, 'group_media/g1/huge.jpg', 'image/jpeg', bytes(21 * MB)));

  // ================= support chat (support_attachments) =================
  const simg = 'support_attachments/sup1/33333333-cccc.jpg';
  await expectOk('ticket owner uploads attachment (image/jpeg)', () => put(alice, simg, 'image/jpeg'));
  await expectOk('ticket owner reads own attachment', () => st.getDownloadURL(R(alice, simg)));
  await expectOk('assigned support agent reads attachment', () => st.getDownloadURL(R(agent, simg)));
  await expectOk('assigned support agent uploads a reply image', () => put(agent, 'support_attachments/sup1/reply.jpg', 'image/jpeg'));
  await expectOk('support staff (adminRole claim) uploads to unassigned ticket', () =>
    put(staff, 'support_attachments/sup2/s.jpg', 'image/jpeg'));
  await expectOk('admin panel user (admin_users doc, no claim) reads attachment', () => st.getDownloadURL(R(panel, simg)));
  await expectDenied('stranger reads support attachment', () => st.getDownloadURL(R(mallory, simg)));
  await expectDenied('other user (B) reads A\'s support attachment', () => st.getBytes(R(bob, simg)));
  await expectDenied('stranger lists support attachments', () => st.listAll(R(mallory, 'support_attachments/sup1')));
  await expectDenied('stranger uploads into someone else\'s ticket', () => put(mallory, 'support_attachments/sup1/evil.jpg', 'image/jpeg'));
  await expectDenied('stranger overwrites a support attachment', () => put(mallory, simg, 'image/jpeg'));
  await expectDenied('support attachment as video/mp4', () => put(alice, 'support_attachments/sup1/x.mp4', 'video/mp4'));
  await expectDenied('oversized support attachment (11 MB > 10 MB)', () =>
    put(alice, 'support_attachments/sup1/big.jpg', 'image/jpeg', bytes(11 * MB)));

  for (const c of [anon, alice, bob, mallory, agent, staff, panel]) { await signOut(c.auth).catch(() => {}); await deleteApp(c.app); }
  const failed = results.filter((r) => r[0] !== 'PASS');
  for (const r of results) console.log(`${r[0]}  ${r[1]}  ${r[2]}`);
  console.log(`\n${results.length - failed.length}/${results.length} passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
