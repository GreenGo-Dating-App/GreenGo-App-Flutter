/**
 * Every subcollection the clients read, tested as a real signed-in user.
 *
 * Firestore rules do NOT cascade: a rule on /blocked_users/{id} says nothing
 * about /profiles/{uid}/blocked_users/{id}. Any subcollection without its own
 * match falls through to default-deny - which is invisible until a feature
 * that uses it breaks.
 */
const { createRequire } = require('module');
const path = require('path'), fs = require('fs');
const PANEL = 'C:/Users/Software Engineering/Desktop/Projects/GreenGo/greengo-admin-panel';
const req = createRequire(path.join(PANEL, 'package.json'));
const admin = req('firebase-admin');
const env = Object.fromEntries(fs.readFileSync(path.join(PANEL, '.env'), 'utf8')
  .split(/\r?\n/).filter((l) => l.includes('=') && !l.startsWith('#'))
  .map((l) => { const i = l.indexOf('='); return [l.slice(0,i).trim(), l.slice(i+1).trim().replace(/^['"]|['"]$/g,'')]; }));
const KEY = env.VITE_FIREBASE_API_KEY, PROJECT = env.VITE_FIREBASE_PROJECT_ID;
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

// {id} is the CALLER's uid wherever the collection is keyed by user.
const SUBS = [
  ['profiles', 'blocked_users', true],
  ['usageLimits', 'days', true],
  ['usageLimits', 'hours', true],
  ['usageLimits', 'months', true],
  ['users', 'features', true],
  ['users', 'feature_trials', true],
  ['users', 'flashcard_decks', true],
  ['users', 'safety_progress', true],
  ['users', 'starred_messages', true],
  ['user_vocabulary', 'words', true],
  ['user_interactions', 'events', true],
  ['user_group_inbox', 'threads', true],
  ['user_business_following', 'businesses', true],
  ['business_followers', 'followers', false],
  ['business_leads', 'leads', false],
  ['business_ratings', 'ratings', false],
  ['spots', 'reviews', false],
];

(async () => {
  const email = `e2e.sub.${Date.now()}@greengo-verify.invalid`;
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${KEY}`,
    { method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ email, password:'E2e!'+Date.now(), returnSecureToken:true }) });
  const a = await r.json();
  const uid = a.localId, token = a.idToken;
  await db.collection('profiles').doc(uid).set({ userId: uid, displayName: 'sub audit' });
  await db.collection('users').doc(uid).set({ userId: uid, email });

  const denied = [];
  for (const [parent, child, ownKeyed] of SUBS) {
    const pid = ownKeyed ? uid : 'probe_parent';
    const res = await fetch(`${FS}/${parent}/${pid}/${child}?pageSize=1`,
      { headers: { Authorization: 'Bearer ' + token } });
    const ok = res.status === 200;
    if (!ok) denied.push(`${parent}/{id}/${child}`);
    console.log(`  ${ok ? 'ok    ' : 'DENIED'} ${parent}/{id}/${child}`.padEnd(52) + `HTTP ${res.status}`);
  }
  console.log(`\n${denied.length} denied: ${denied.join(', ') || '(none)'}`);

  for (const c of ['profiles','users']) { try { await db.collection(c).doc(uid).delete(); } catch(e){} }
  try { await admin.auth().deleteUser(uid); } catch(e){}
  process.exit(0);
})();
