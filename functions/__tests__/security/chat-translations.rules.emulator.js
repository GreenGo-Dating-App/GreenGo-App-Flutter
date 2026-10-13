/**
 * Stored chat translations (2026-10): `tr` / `trHash` / `lang` on chat
 * messages and `chat_translation_cache` are server-only. Real-client test
 * against the emulators (same web SDK as the apps). ATTACK cases must be
 * DENIED; LEGIT cases (the app's own message writes) must stay ALLOWED.
 *
 *   firebase emulators:exec --only firestore,auth --project demo-gg \
 *     "node functions/__tests__/security/chat-translations.rules.emulator.js"
 * Needs NODE_PATH pointing at a node_modules that has `firebase` (web SDK)
 * and `firebase-admin`.
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
  const alice = await client('alice.tr@example.com');
  const bob = await client('bob.tr@example.com');
  const eve = await client('eve.tr@example.com');
  const A = alice.uid, B = bob.uid;
  const D = (c, path) => fs.doc(c.db, path);
  const conv = 'conv_tr';
  const msg = (id) => `conversations/${conv}/messages/${id}`;
  const gmsg = (id) => `groups/g_tr/messages/${id}`;

  // ---- seed (admin, bypasses rules) ----
  for (const u of [A, B]) await adb.doc(`profiles/${u}`).set({ name: u, membershipTier: 'TEST' });
  await adb.doc(`conversations/${conv}`).set({ userId1: A, userId2: B, participants: [A, B] });
  await adb.doc(msg('m1')).set({
    senderId: A, receiverId: B, content: 'Hello friend', type: 'text', status: 'sent',
    tr: { it: 'Ciao amico' }, trHash: 'abcd', lang: 'en',
  });
  await adb.doc('groups/g_tr').set({ participants: [A, B], roles: { [A]: 'admin', [B]: 'member' }, createdBy: A });
  await adb.doc(gmsg('gm1')).set({ senderId: A, content: 'Hi all', type: 'text', tr: { de: 'Hallo zusammen' } });
  await adb.doc('chat_translation_cache/x').set({ target: 'it', text: 'Come stai?', source: 'en' });

  // ---- 1:1 messages ----
  await expectOk('participant reads a message with stored translations', () => fs.getDoc(D(bob, msg('m1'))));
  await expectDenied('non-participant reads the message', () => fs.getDoc(D(eve, msg('m1'))));
  await expectOk('send a message (app payload, no translation fields)', () =>
    fs.setDoc(D(alice, msg('m2')), { senderId: A, receiverId: B, conversationId: conv, content: 'Hi',
      type: 'text', status: 'sent', sentAt: fs.serverTimestamp() }));
  await expectDenied('send a message with a forged tr map', () =>
    fs.setDoc(D(alice, msg('m3')), { senderId: A, receiverId: B, content: 'Hi', type: 'text', tr: { it: 'X' } }));
  await expectDenied('send a message with a lang', () =>
    fs.setDoc(D(alice, msg('m4')), { senderId: A, receiverId: B, content: 'Hi', type: 'text', lang: 'en' }));
  await expectOk('mark read / react (app update)', () =>
    fs.updateDoc(D(bob, msg('m1')), { status: 'read', readAt: fs.serverTimestamp(), [`reactions.${B}`]: '❤️' }));
  await expectOk('sender edits / soft-deletes content', () =>
    fs.updateDoc(D(alice, msg('m1')), { content: 'Hello friend!' }));
  await expectDenied('participant rewrites a stored translation', () =>
    fs.updateDoc(D(bob, msg('m1')), { 'tr.it': 'Insulto' }));
  await expectDenied('participant adds a language to tr', () =>
    fs.updateDoc(D(bob, msg('m1')), { 'tr.de': 'Hallo' }));
  await expectDenied('participant changes lang', () => fs.updateDoc(D(bob, msg('m1')), { lang: 'it' }));
  await expectDenied('participant deletes trHash', () => fs.updateDoc(D(bob, msg('m1')), { trHash: fs.deleteField() }));
  await expectOk('sender deletes for everyone (app payload drops the translations)', () =>
    fs.updateDoc(D(alice, msg('m1')), { isDeletedForEveryone: true, content: 'This message was deleted',
      originalContent: 'Hello friend!', tr: fs.deleteField(), trHash: fs.deleteField(), lang: fs.deleteField() }));

  // ---- group messages ----
  await expectOk('member sends a group message', () =>
    fs.setDoc(D(bob, gmsg('gm2')), { senderId: B, receiverId: '', matchId: 'g_tr', content: 'Hey', type: 'text',
      status: 'sent', sentAt: fs.serverTimestamp() }));
  await expectDenied('member sends a group message with tr', () =>
    fs.setDoc(D(bob, gmsg('gm3')), { senderId: B, content: 'Hey', type: 'text', tr: { it: 'Ehi' } }));
  await expectOk('member reacts to a group message', () =>
    fs.updateDoc(D(bob, gmsg('gm1')), { [`reactions.${B}`]: '👍' }));
  await expectDenied('group admin rewrites a stored translation', () =>
    fs.updateDoc(D(alice, gmsg('gm1')), { 'tr.de': 'Tschüss' }));
  await expectDenied('partial removal (drop tr, keep lang)', async () => {
    await adb.doc(gmsg('gm1')).update({ lang: 'en' });
    await fs.updateDoc(D(alice, gmsg('gm1')), { tr: fs.deleteField() });
  });
  await expectOk('group delete for everyone (app payload drops the translations)', () =>
    fs.updateDoc(D(alice, gmsg('gm1')), { 'metadata.isDeletedForEveryone': true, 'metadata.deletedBy': A,
      content: '', tr: fs.deleteField(), trHash: fs.deleteField(), lang: fs.deleteField() }));

  // ---- cross-chat cache: server only ----
  await expectDenied('read chat_translation_cache', () => fs.getDoc(D(alice, 'chat_translation_cache/x')));
  await expectDenied('write chat_translation_cache', () =>
    fs.setDoc(D(alice, 'chat_translation_cache/y'), { target: 'it', text: 'X' }));

  for (const c of [alice, bob, eve]) { await signOut(c.auth).catch(() => {}); await deleteApp(c.app); }
  const failed = results.filter((r) => r[0] !== 'PASS');
  for (const r of results) console.log(`${r[0]}  ${r[1]}  ${r[2]}`);
  console.log(`\n${results.length - failed.length}/${results.length} passed`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
