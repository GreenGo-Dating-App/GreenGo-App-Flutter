/**
 * Feature-level end-to-end tests against PRODUCTION.
 *
 * The login smoke test proves the app starts. This proves the features still
 * work after the v4.0.0 rules changes, by performing the reads and writes each
 * one actually makes, as a real signed-in user with real security rules
 * applied. The Admin SDK is used ONLY to set up and tear down fixtures, never
 * to perform the operation under test - it bypasses rules and would make every
 * assertion meaningless.
 *
 * Covers: purchases, chat, communities, age verification.
 *
 * SAFETY
 *   - Two throwaway accounts are created and deleted again, along with every
 *     document they touch. Nothing is left behind.
 *   - No purchase is ever completed. Stripe Checkout and StoreKit are not
 *     driven; what is tested is that the catalogue resolves and the
 *     verification callables are reachable and reject bad input. Completing a
 *     purchase would move real money.
 *   - No notification is sent to anyone.
 *
 * Usage:
 *   node tool/e2e_feature_tests.cjs            # against greengo-chat
 */

const path = require('path');
const fs = require('fs');
const { createRequire } = require('module');

const PANEL = path.resolve(__dirname, '../../greengo-admin-panel');
const req = createRequire(path.join(PANEL, 'package.json'));
const admin = req('firebase-admin');

const env = Object.fromEntries(
  fs.readFileSync(path.join(PANEL, '.env'), 'utf8')
    .split(/\r?\n/)
    .filter((l) => l.includes('=') && !l.startsWith('#'))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i).trim(), l.slice(i + 1).trim().replace(/^['"]|['"]$/g, '')];
    })
);

const KEY = env.VITE_FIREBASE_API_KEY;
const PROJECT = env.VITE_FIREBASE_PROJECT_ID;
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const FN = `https://us-central1-${PROJECT}.cloudfunctions.net`;

let pass = 0, fail = 0;
const created = { users: [], docs: [] };

function ok(label, extra = '') {
  console.log(`  ok    ${label}${extra ? '  (' + extra + ')' : ''}`);
  pass += 1;
}
function bad(label, why) {
  console.log(`  FAIL  ${label}\n        ${why}`);
  fail += 1;
}

/** Signs a new throwaway account in and returns its token + uid. */
async function makeUser(tag) {
  const email = `e2e.${tag}.${Date.now()}@greengo-verify.invalid`;
  const r = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${KEY}`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'E2e!' + Date.now(), returnSecureToken: true }) }
  );
  const j = await r.json();
  if (!j.idToken) throw new Error('signUp failed: ' + JSON.stringify(j).slice(0, 200));
  created.users.push(j.localId);
  return { uid: j.localId, token: j.idToken, email };
}

const H = (t) => ({ Authorization: 'Bearer ' + t, 'Content-Type': 'application/json' });

async function getDoc(token, p) {
  return (await fetch(`${FS}/${p}`, { headers: H(token) })).status;
}
async function listCol(token, c, limit = 1) {
  return (await fetch(`${FS}/${c}?pageSize=${limit}`, { headers: H(token) })).status;
}
async function callFn(token, name, data) {
  const res = await fetch(`${FN}/${name}`, {
    method: 'POST',
    headers: token ? H(token) : { 'Content-Type': 'application/json' },
    body: JSON.stringify({ data: data ?? {} }),
  });
  return { status: res.status, body: await res.text() };
}

/** Deletes accounts and profiles left behind by a previous failed run. */
async function sweepStale(db) {
  let n = 0;
  let pageToken;
  do {
    const res = await admin.auth().listUsers(1000, pageToken);
    for (const u of res.users) {
      if (!u.email || !u.email.endsWith('@greengo-verify.invalid')) continue;
      for (const c of ['profiles', 'users', 'coinBalances']) {
        try { await db.collection(c).doc(u.uid).delete(); } catch (e) {}
      }
      try { await admin.auth().deleteUser(u.uid); n += 1; } catch (e) {}
    }
    pageToken = res.pageToken;
  } while (pageToken);
  if (n) console.log('  swept ' + n + ' stale test account(s) from a previous run');
}

/**
 * A community chat message. The rule reads request.resource.data.type, so a
 * message without it is denied for a missing field rather than by the age gate
 * - which is exactly how the first run of this test "passed" the gate check
 * while proving nothing. Both the unverified and the verified post use this
 * same payload, so verification status is the only variable.
 */
const MSG = (uid) => ({
  senderId: { stringValue: uid },
  content: { stringValue: 'e2e' },
  type: { stringValue: 'text' },
  createdAt: { timestampValue: new Date().toISOString() },
});

async function main() {
  admin.initializeApp({ projectId: PROJECT });
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  console.log(`feature tests against ${PROJECT}\n`);

  // Sweep any accounts stranded by an earlier crashed run. Cleanup only runs
  // at the end, so a harness error leaks fixtures into production - and a test
  // that quietly litters the live database is worse than no test.
  await sweepStale(db);

  const A = await makeUser('a');
  const B = await makeUser('b');

  // Fixtures: two complete, approved profiles.
  for (const u of [A, B]) {
    await db.collection('profiles').doc(u.uid).set({
      userId: u.uid, displayName: 'E2E ' + u.uid.slice(0, 4), email: u.email,
      dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1990-01-01')),
      membershipTier: 'FREE', isComplete: true, isAdmin: false, isBanned: false,
      isAgeVerified: false, ageVerification: { status: 'declared', updatedAt: now },
      createdAt: now,
    });
    await db.collection('users').doc(u.uid).set({
      userId: u.uid, email: u.email, approvalStatus: 'approved', isAdmin: false, createdAt: now,
    });
    created.docs.push(['profiles', u.uid], ['users', u.uid]);
  }

  // ───────────────────────────────── PURCHASES ─────────────────────────────
  console.log('PURCHASES');
  {
    const s = await getDoc(A.token, `coinBalances/${A.uid}`);
    (s === 200 || s === 404) ? ok('own coin balance readable') : bad('own coin balance readable', `HTTP ${s}`);

    // The shop reads the membership/price configuration.
    const cfg = await listCol(A.token, 'membership_config');
    (cfg === 200 || cfg === 404) ? ok('membership config readable') : bad('membership config readable', `HTTP ${cfg}`);

    // Purchases are verified server-side by three separate callables: coins on
    // each store, and subscriptions. All three are the boundary that stands
    // between a forged client receipt and a free membership, so all three are
    // checked - testing only one would leave two thirds of the surface unseen.
    //
    // No purchase is ever completed here. What is asserted is that the
    // callables are reachable (a missing one would break the shop outright)
    // and that they refuse anonymous callers and forged receipts. Driving a
    // real purchase through would move real money.
    const PURCHASE_FNS = ['verifyGooglePlayCoinPurchase', 'verifyAppStoreCoinPurchase', 'verifyPurchase'];
    for (const fn of PURCHASE_FNS) {
      const anon = await callFn(null, fn, { productId: 'x' });
      anon.body.includes('UNAUTHENTICATED') || anon.status === 401
        ? ok(`${fn} refuses unauthenticated callers`)
        : bad(`${fn} refuses unauthenticated callers`, `HTTP ${anon.status} ${anon.body.slice(0, 90)}`);

      const forged = await callFn(A.token, fn, {
        productId: 'not_a_product', purchaseToken: 'forged', receipt: 'forged', platform: 'android',
      });
      // A crash is NOT a rejection. 503 here was a 256MiB function being
      // OOM-killed before it ever ran - the readiness check failed and the
      // caller got an error that looked, from outside, exactly like a refusal.
      // Counting that as a pass would have hidden the fact that subscription
      // verification was dead in production, so these statuses fail loudly.
      const granted = forged.status === 200 && /"success"\s*:\s*true/.test(forged.body);
      const crashed = forged.status === 404 || forged.status === 503;
      if (crashed) {
        bad(`${fn} rejects a forged receipt`,
            forged.status === 404
              ? 'NOT DEPLOYED (404) - the shop cannot verify anything'
              : 'HTTP 503 - the function never started (check for an OOM at 256MiB). '
                + 'This is a crash, not a rejection.');
      } else if (granted) {
        bad(`${fn} rejects a forged receipt`, `it GRANTED the purchase: ${forged.body.slice(0, 140)}`);
      } else {
        ok(`${fn} rejects a forged receipt`, `HTTP ${forged.status}`);
      }
    }

    // A forged receipt must also not have moved the balance.
    const balAfter = await db.collection('coinBalances').doc(A.uid).get();
    const tc = balAfter.exists ? (balAfter.data().totalCoins || 0) : 0;
    tc <= 100
      ? ok('no coins minted by the rejected purchases', `totalCoins=${tc}`)
      : bad('no coins minted by the rejected purchases', `totalCoins=${tc}`);

    // Another user's orders must stay private.
    await db.collection('orders').doc('e2e_order_b').set({ userId: B.uid, amount: 999 });
    created.docs.push(['orders', 'e2e_order_b']);
    const other = await getDoc(A.token, 'orders/e2e_order_b');
    other === 403 ? ok("another user's order is private") : bad("another user's order is private", `HTTP ${other}`);
  }

  // ─────────────────────────────────── CHAT ────────────────────────────────
  console.log('\nCHAT');
  {
    const convId = 'e2e_conv_' + Date.now();
    await db.collection('conversations').doc(convId).set({
      conversationId: convId, participants: [A.uid, B.uid], createdAt: now, lastMessageAt: now,
    });
    created.docs.push(['conversations', convId]);

    const read = await getDoc(A.token, `conversations/${convId}`);
    read === 200 ? ok('participant can read the conversation') : bad('participant can read the conversation', `HTTP ${read}`);

    // A participant sends a message - the core write of the whole feature.
    const send = await fetch(`${FS}/conversations/${convId}/messages?documentId=m1`, {
      method: 'POST', headers: H(A.token),
      body: JSON.stringify({ fields: {
        senderId: { stringValue: A.uid }, content: { stringValue: 'e2e hello' },
        type: { stringValue: 'text' }, sentAt: { timestampValue: new Date().toISOString() },
      } }),
    });
    send.status === 200 ? ok('participant can send a message') : bad('participant can send a message', `HTTP ${send.status} ${(await send.text()).slice(0, 120)}`);

    const readMsg = await getDoc(A.token, `conversations/${convId}/messages/m1`);
    readMsg === 200 ? ok('message readable by the participant') : bad('message readable by the participant', `HTTP ${readMsg}`);

    // An outsider must not be able to read the conversation.
    const C = await makeUser('c');
    const outsider = await getDoc(C.token, `conversations/${convId}`);
    outsider === 403 ? ok('a non-participant cannot read it') : bad('a non-participant cannot read it', `HTTP ${outsider}`);
  }

  // ───────────────────────────────  COMMUNITIES  ───────────────────────────
  console.log('\nCOMMUNITIES');
  {
    const cid = 'e2e_comm_' + Date.now();
    await db.collection('communities').doc(cid).set({
      communityId: cid, name: 'E2E Community', createdByUserId: B.uid, memberCount: 1, createdAt: now,
    });
    await db.collection('communities').doc(cid).collection('members').doc(A.uid).set({
      userId: A.uid, role: 'member', joinedAt: now, isBanned: false, isMuted: false,
    });
    created.docs.push(['communities', cid]);

    const r = await getDoc(A.token, `communities/${cid}`);
    r === 200 ? ok('community readable') : bad('community readable', `HTTP ${r}`);

    // The age gate: a declared-but-unverified member must NOT be able to post.
    const postUnverified = await fetch(`${FS}/communities/${cid}/messages?documentId=e2e1`, {
      method: 'POST', headers: H(A.token),
      body: JSON.stringify({ fields: MSG(A.uid) }),
    });
    postUnverified.status === 403
      ? ok('unverified member CANNOT publish (age gate holds)')
      : bad('unverified member CANNOT publish', `HTTP ${postUnverified.status} - the gate is open`);

    // Verify them server-side, exactly as reviewAgeVerification would, and the
    // same post must now succeed. This is the gate working in both directions.
    await db.collection('profiles').doc(A.uid).set({ isAgeVerified: true }, { merge: true });
    await new Promise((r2) => setTimeout(r2, 1500));
    const postVerified = await fetch(`${FS}/communities/${cid}/messages?documentId=e2e2`, {
      method: 'POST', headers: H(A.token),
      body: JSON.stringify({ fields: MSG(A.uid) }),
    });
    postVerified.status === 200
      ? ok('verified member CAN publish')
      : bad('verified member CAN publish', `HTTP ${postVerified.status} ${(await postVerified.text()).slice(0, 140)}`);

    // collectionGroup('members') - the query the app uses for "my communities",
    // and one of the two that the first rules attempt broke outright.
    const grp = await fetch(`https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`, {
      method: 'POST', headers: H(A.token),
      body: JSON.stringify({ structuredQuery: {
        from: [{ collectionId: 'members', allDescendants: true }],
        where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: A.uid } } },
        limit: 5,
      } }),
    });
    grp.status === 200 ? ok('collectionGroup(members) works') : bad('collectionGroup(members) works', `HTTP ${grp.status}`);
  }

  // ───────────────────────────  AGE VERIFICATION  ──────────────────────────
  console.log('\nAGE VERIFICATION');
  {
    const st = await callFn(A.token, 'getAgeVerificationState');
    st.status === 200 && st.body.includes('status')
      ? ok('getAgeVerificationState responds', st.body.slice(0, 60))
      : bad('getAgeVerificationState responds', `HTTP ${st.status} ${st.body.slice(0, 120)}`);

    const anon = await callFn(null, 'submitAgeDocument', { documentPath: 'x' });
    anon.body.includes('UNAUTHENTICATED')
      ? ok('submitAgeDocument refuses unauthenticated callers')
      : bad('submitAgeDocument refuses unauthenticated callers', anon.body.slice(0, 120));

    // Someone else's upload folder must be refused: the check that stops a
    // user pointing the reader at a document that is not theirs.
    const foreign = await callFn(A.token, 'submitAgeDocument', { documentPath: `age_verification/${B.uid}/x.jpg` });
    /permission-denied|PERMISSION_DENIED/.test(foreign.body)
      ? ok('submitAgeDocument refuses another user folder')
      : bad('submitAgeDocument refuses another user folder', foreign.body.slice(0, 140));

    // Identity documents must be unreadable in Storage - by anyone.
    const bucket = `${PROJECT}.firebasestorage.app`;
    const st2 = await fetch(`https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent('age_verification/' + A.uid + '/probe.jpg')}?alt=media`, { headers: { Authorization: 'Bearer ' + A.token } });
    st2.status === 403 || st2.status === 404
      ? ok('identity documents are not readable', `HTTP ${st2.status}`)
      : bad('identity documents are not readable', `HTTP ${st2.status}`);
  }

  // ──────────────────────────────── CLEANUP ────────────────────────────────
  console.log('\ncleaning up');
  for (const [c, id] of created.docs) {
    try {
      const sub = await db.collection(c).doc(id).listCollections();
      for (const s of sub) {
        const docs = await s.get();
        for (const d of docs.docs) await d.ref.delete();
      }
      await db.collection(c).doc(id).delete();
    } catch (e) { /* best effort */ }
  }
  for (const uid of created.users) {
    for (const c of ['profiles', 'users', 'coinBalances']) {
      try { await db.collection(c).doc(uid).delete(); } catch (e) {}
    }
    try { await admin.auth().deleteUser(uid); } catch (e) {}
  }
  console.log(`  removed ${created.users.length} accounts and ${created.docs.length} fixtures`);

  console.log(`\n${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
}

main().catch((e) => { console.error('harness error:', e); process.exit(1); });
