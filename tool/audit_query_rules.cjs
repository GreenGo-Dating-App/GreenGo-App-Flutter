/**
 * Runs every client query shape against the DEPLOYED rules as a real signed-in
 * user, and reports the ones that are refused.
 *
 * Why this exists: Firestore rules are not filters. A query is rejected unless
 * its own constraints prove that every document it could return is readable -
 * even when it would have returned nothing. So a collection can have a correct
 * rule and still break the app. Reading the rules cannot find this; only
 * running the query can.
 *
 * Shapes come from tool/extract_client_queries.py.
 *
 * Usage: python3 tool/extract_client_queries.py --json > shapes.json
 *        node tool/audit_query_rules.cjs shapes.json
 */
const { createRequire } = require('module');
const path = require('path'), fs = require('fs');
const PANEL = 'C:/Users/Software Engineering/Desktop/Projects/GreenGo/greengo-admin-panel';
const req = createRequire(path.join(PANEL, 'package.json'));
const admin = req('firebase-admin');

const env = Object.fromEntries(fs.readFileSync(path.join(PANEL, '.env'), 'utf8')
  .split(/\r?\n/).filter((l) => l.includes('=') && !l.startsWith('#'))
  .map((l) => { const i = l.indexOf('='); return [l.slice(0, i).trim(), l.slice(i + 1).trim().replace(/^['"]|['"]$/g, '')]; }));
const KEY = env.VITE_FIREBASE_API_KEY, PROJECT = env.VITE_FIREBASE_PROJECT_ID;
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// Fields that name the acting user. These MUST carry the real uid or the query
// cannot be proven safe, and we would report a false failure.
const OWNER = /(^|[a-z])(uid|userid|user|owner|sender|receiver|blocker|blocked|granted|createdby|creator|organizer|participant|member|author|host|inviter|assignee|agent)/i;

const OPS = {
  isEqualTo: 'EQUAL', isNotEqualTo: 'NOT_EQUAL',
  arrayContains: 'ARRAY_CONTAINS', arrayContainsAny: 'ARRAY_CONTAINS_ANY',
  whereIn: 'IN', whereNotIn: 'NOT_IN',
  isGreaterThan: 'GREATER_THAN', isGreaterThanOrEqualTo: 'GREATER_THAN_OR_EQUAL',
  isLessThan: 'LESS_THAN', isLessThanOrEqualTo: 'LESS_THAN_OR_EQUAL',
};

const value = (field, uid) => (OWNER.test(field)
  ? { stringValue: uid }
  : (/^(is|has|can|published|active|disabled|locked)/i.test(field)
    ? { booleanValue: true } : { stringValue: 'x' }));

function filterFor(w, uid) {
  const op = OPS[w.op];
  const v = value(w.field, uid);
  if (op === 'IN' || op === 'NOT_IN' || op === 'ARRAY_CONTAINS_ANY') {
    return { fieldFilter: { field: { fieldPath: w.field }, op, value: { arrayValue: { values: [v] } } } };
  }
  return { fieldFilter: { field: { fieldPath: w.field }, op, value: v } };
}

(async () => {
  const shapes = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  admin.initializeApp({ projectId: PROJECT });
  const db = admin.firestore();

  const email = `e2e.audit.${Date.now()}@greengo-verify.invalid`;
  const r0 = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${KEY}`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'E2e!' + Date.now(), returnSecureToken: true }) });
  const A = await r0.json();
  const uid = A.localId, token = A.idToken;
  const now = admin.firestore.Timestamp.now();
  await db.collection('profiles').doc(uid).set({
    userId: uid, displayName: 'audit', membershipTier: 'BASE', isComplete: true,
    isAgeVerified: true, isBanned: false, createdAt: now,
  });
  await db.collection('users').doc(uid).set({ userId: uid, approvalStatus: 'approved' });

  const denied = [];
  for (const s of shapes) {
    const filters = s.where.map((w) => filterFor(w, uid));
    const q = {
      from: [{ collectionId: s.collection, allDescendants: !!s.collectionGroup }],
      where: filters.length === 1 ? filters[0] : { compositeFilter: { op: 'AND', filters } },
      limit: 1,
    };
    const res = await fetch(`${FS}:runQuery`, {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ structuredQuery: q }),
    });
    const body = await res.text();
    const isDenied = res.status === 403 || /PERMISSION_DENIED/.test(body);
    const needsIndex = /FAILED_PRECONDITION|requires an index/i.test(body);
    if (isDenied) denied.push({ ...s, reason: 'PERMISSION_DENIED' });
    else if (needsIndex) denied.push({ ...s, reason: 'MISSING_INDEX' });
  }

  const shape = (s) => s.where.map((w) => `${w.field} ${w.op}`).join(' + ');
  const perms = denied.filter((d) => d.reason === 'PERMISSION_DENIED');
  const idx = denied.filter((d) => d.reason === 'MISSING_INDEX');
  console.log(`checked ${shapes.length} query shapes as a signed-in BASE user\n`);
  console.log(`PERMISSION_DENIED: ${perms.length}`);
  for (const d of perms) {
    console.log(`  ${(d.collectionGroup ? 'CG:' : '') + d.collection}`);
    console.log(`      where: ${shape(d)}`);
    console.log(`      used by: ${d.seen.join(', ')}`);
  }
  console.log(`\nMISSING_INDEX (works once the index exists): ${idx.length}`);
  for (const d of idx) console.log(`  ${d.collection}: ${shape(d)}`);

  await db.collection('profiles').doc(uid).delete();
  await db.collection('users').doc(uid).delete();
  try { await admin.auth().deleteUser(uid); } catch (e) {}
  process.exit(0);
})();
