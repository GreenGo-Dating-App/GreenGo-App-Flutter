/**
 * Creates (or re-asserts) the App Store / Google Play REVIEWER demo account.
 *
 * DRY RUN BY DEFAULT: prints what it would do and writes nothing.
 * Pass --apply to write. Idempotent: a re-run finds the account by email and
 * only fills in what is missing or different; it never duplicates documents,
 * never shortens the membership and never changes the password (unless
 * --reset-password is passed).
 *
 * What a normal sign-up produces, replicated through the app's own server
 * paths wherever one exists:
 *   - Firebase Auth user: email + password, displayName "GreenGo Review",
 *     emailVerified, and a VERIFIED phone number set on the Auth record
 *     (fictional +1 650-555-01xx test-style number), so the ID token carries
 *     the phone_number claim the rules require of new accounts. No SMS.
 *   - profiles_private/{uid}: exact location (Lisbon), 9-char geohash, date of
 *     birth (adult), email, verificationPhone, birthMonthDay - the fields the
 *     app writes ONLY to the private doc (lib/features/profile/data/private_profile.dart).
 *   - profiles/{uid}: the onboarding fields of ProfileModel.toJson() without
 *     the sensitive ones; isComplete, phone verification approved (the
 *     onboarding rule since 2026-10-17: phone only = auto-approved),
 *     globeDiscoverability 'approximate', NOT business. Coarse public fields
 *     (geohash5, approxLocation, age) via computeCoarse(), the same function
 *     the mirror triggers use.
 *   - recordVerifiedPhoneImpl(): the server path the app calls after linking
 *     the phone (phone_index + profiles_private.phone).
 *   - Age: ageVerification.status 'verified' + isAgeVerified (the shape
 *     ageAssurance.writeStatus writes on an admin approval).
 *   - users/{uid}: access doc, approvalStatus 'approved'. Its creation fires
 *     applySignupGrants (standard 2026 welcome pack), like any sign-up.
 *   - Membership: GOLD until 2027-12-31 via grantMembership() - the helper
 *     grantEntitlement (the admin grant callable) uses - plus an
 *     entitlement_grants audit record.
 *
 * The generated password is NEVER printed. On creation it is appended to the
 * credentials file given by --credentials-file (required with --apply when
 * the account does not exist yet).
 *
 * Usage (from functions/; ts-node is not installed here):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/create-review-account.ts
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 GCLOUD_PROJECT=greengo-chat \
 *     node -r dotenv/config scripts/.out/scripts/create-review-account.js dotenv_config_path=.env \
 *     [--apply] [--credentials-file <path>] [--reset-password]
 *   Verification only (sign-in via the Auth REST API, token claims, tier):
 *     REVIEW_PASSWORD=... node ... create-review-account.js --verify
 *
 * Needs PHONE_INDEX_KEY and PROFILE_LOCATION_JITTER_KEY from functions/.env
 * (same values as the deployed functions), and GG_WEB_API_KEY for --verify.
 */
import '../src/shared/firebaseAdmin';
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as https from 'https';
import { randomBytes, randomInt } from 'crypto';
import { grantMembership } from '../src/shared/grants';
import { effectiveTier } from '../src/shared/effectiveTier';
import {
  PRIVATE_PROFILES,
  birthMonthDayOf,
  coarseUpdates,
  computeCoarse,
  geohashEncode,
} from '../src/profiles/privateProfile';
import { recordVerifiedPhoneImpl } from '../src/safety/phoneVerification';

// ---------------------------------------------------------------------------
// Account definition
// ---------------------------------------------------------------------------
const EMAIL = 'review@greengochat.com';
const DISPLAY_NAME = 'GreenGo Review';
/** Fictional NANP number (555-01xx is reserved for fiction); never receives SMS. */
const PHONE = '+16505550142';
const DATE_OF_BIRTH = new Date(Date.UTC(1990, 5, 15)); // adult (36)
const LISBON = { latitude: 38.7223, longitude: -9.1393 };
const TIER = 'GOLD' as const;
const MEMBERSHIP_END = new Date(Date.UTC(2027, 11, 31, 23, 59, 59));
const GRANT_AUDIT_ID = 'review-demo-account-gold-2027-12-31';
const ACTOR = 'script:create-review-account';

const argv = process.argv.slice(2);
const APPLY = argv.includes('--apply');
const VERIFY_ONLY = argv.includes('--verify');
const RESET_PASSWORD = argv.includes('--reset-password');
function arg(name: string): string | undefined {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : undefined;
}
const CREDENTIALS_FILE = arg('--credentials-file');

const db = admin.firestore();
const Ts = admin.firestore.Timestamp;

function log(msg: string) {
  console.log(`${APPLY ? '' : '[DRY RUN] '}${msg}`);
}

/** 24 chars from an unambiguous alphabet, with each class guaranteed. */
function generatePassword(): string {
  const lower = 'abcdefghijkmnpqrstuvwxyz';
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  const symbols = '!#%+=?@_-';
  const all = lower + upper + digits + symbols;
  const chars = [
    lower[randomInt(lower.length)],
    upper[randomInt(upper.length)],
    digits[randomInt(digits.length)],
    symbols[randomInt(symbols.length)],
  ];
  const bytes = randomBytes(20);
  for (let i = 0; i < 20; i++) chars.push(all[bytes[i] % all.length]);
  for (let i = chars.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}

function saveCredentials(uid: string, password: string, heading: string) {
  if (!CREDENTIALS_FILE) throw new Error('--credentials-file is required to store a new password');
  const block = [
    '',
    heading,
    `Email: ${EMAIL}`,
    `Password: ${password}`,
    `Phone on the Auth user (fictional test number, no SMS needed): ${PHONE}`,
    `UID: ${uid}`,
    `Membership: ${TIER} until ${MEMBERSHIP_END.toISOString().slice(0, 10)} (admin grant, entitlement_grants/${GRANT_AUDIT_ID})`,
    'Created by functions/scripts/create-review-account.ts (branch chore/review-account). Mailbox may not exist yet; login is email + password only.',
    '',
  ].join('\n');
  fs.appendFileSync(CREDENTIALS_FILE, block, 'utf8');
  console.log(`Credentials appended to ${CREDENTIALS_FILE} (password not printed).`);
}

// ---------------------------------------------------------------------------
// Auth user
// ---------------------------------------------------------------------------
async function ensureAuthUser(): Promise<{ uid: string; created: boolean; password?: string }> {
  let user: admin.auth.UserRecord | null = null;
  try {
    user = await admin.auth().getUserByEmail(EMAIL);
  } catch (e: any) {
    if (e?.code !== 'auth/user-not-found') throw e;
  }

  if (!user) {
    log(`create Auth user ${EMAIL} (displayName, emailVerified, phone ${PHONE})`);
    if (!APPLY) return { uid: '(new uid)', created: true };
    if (!CREDENTIALS_FILE) throw new Error('--credentials-file is required to create the account');
    const password = generatePassword();
    const created = await admin.auth().createUser({
      email: EMAIL,
      password,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      phoneNumber: PHONE,
      disabled: false,
    });
    saveCredentials(created.uid, password, '# App Store / Play review demo account (created 2026-10-18)');
    return { uid: created.uid, created: true, password };
  }

  const patch: admin.auth.UpdateRequest = {};
  if (user.displayName !== DISPLAY_NAME) patch.displayName = DISPLAY_NAME;
  if (!user.emailVerified) patch.emailVerified = true;
  if (user.phoneNumber !== PHONE) patch.phoneNumber = PHONE;
  if (user.disabled) patch.disabled = false;
  let password: string | undefined;
  if (RESET_PASSWORD) {
    password = generatePassword();
    patch.password = password;
  }
  const keys = Object.keys(patch).filter((k) => k !== 'password');
  log(`Auth user exists (${user.uid}); ${keys.length ? `update ${keys.join(', ')}` : 'nothing to change'}${RESET_PASSWORD ? ' + reset password' : ''}`);
  if (APPLY && Object.keys(patch).length) {
    await admin.auth().updateUser(user.uid, patch);
    if (password) {
      saveCredentials(user.uid, password, `# App Store / Play review demo account (password reset ${new Date().toISOString().slice(0, 10)})`);
    }
  }
  return { uid: user.uid, created: false, password };
}

// ---------------------------------------------------------------------------
// Firestore docs
// ---------------------------------------------------------------------------
function privateProfileDoc() {
  return {
    location: { ...LISBON },
    geohash: geohashEncode(LISBON.latitude, LISBON.longitude, 9),
    dateOfBirth: Ts.fromDate(DATE_OF_BIRTH),
    birthMonthDay: birthMonthDayOf(DATE_OF_BIRTH),
    email: EMAIL,
    verificationPhone: PHONE,
    updatedAt: Ts.now(),
  };
}

/** ProfileModel.toJson() of a completed onboarding, minus the private fields. */
function publicProfileDoc(uid: string, existing: Record<string, any> | undefined) {
  const now = Ts.now();
  return {
    userId: uid,
    displayName: DISPLAY_NAME,
    nickname: null,
    gender: 'Other',
    accountStatus: 'active',
    isBoosted: false,
    boostExpiry: null,
    isIncognito: false,
    incognitoExpiry: null,
    isGhostMode: false,
    isTraveler: false,
    travelerExpiry: null,
    travelerLocation: null,
    photoUrls: existing?.photoUrls ?? [],
    bio:
      'Demo account for the App Store and Google Play review teams. ' +
      'Based in Lisbon, curious about languages, food and local culture.',
    interests: ['Travel', 'Languages', 'Food', 'History', 'Photography', 'Music'],
    location: {
      city: 'Lisbon',
      country: 'Portugal',
      countryLower: 'portugal',
      displayAddress: 'Lisbon, Portugal',
    },
    languages: ['English', 'Portuguese', 'Spanish'],
    voiceRecordingUrl: null,
    personalityTraits: null,
    education: null,
    occupation: null,
    lookingFor: null,
    height: null,
    weight: null,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
    isComplete: true,
    // Onboarding since 2026-10-17: verified phone only = auto-approved.
    verificationStatus: 'approved',
    verificationMethod: 'phone',
    verificationRejectionReason: null,
    verificationSubmittedAt: existing?.verificationSubmittedAt ?? now,
    verificationReviewedAt: existing?.verificationReviewedAt ?? now,
    verificationReviewedBy: null,
    isAdmin: false,
    isSupport: false,
    is2FAEnabled: false,
    socialLinks: null,
    isOnline: false,
    preferredLanguages: [],
    nativeLanguage: null,
    travelPreference: null,
    primaryOrigin: null,
    secondaryOrigin: null,
    isLocalGuide: false,
    localGuideCity: null,
    videoProfileUrl: null,
    hasVideoProfile: false,
    showOnMap: true,
    globeDiscoverability: 'approximate',
    completedSafetyModules: [],
    isBusiness: false,
    businessName: null,
    businessLegalName: null,
    businessWhatsapp: null,
    businessAddress: null,
    businessCategory: null,
    businessVerified: false,
    galleryImages: [],
    openingHours: [],
    storefrontBio: null,
    storefrontLinks: [],
    coverImageUrl: null,
    isBanned: false,
    // Server-owned age decision (ageAssurance.writeStatus shape).
    ageVerification: {
      status: 'verified',
      method: 'admin_review',
      reviewedBy: ACTOR,
      reviewedAt: existing?.ageVerification?.reviewedAt ?? now,
      verifiedAt: existing?.ageVerification?.verifiedAt ?? now,
      rejectionReason: null,
      updatedAt: now,
    },
    isAgeVerified: true,
    idVerifiedVia: 'admin_review',
  };
}

function usersDoc(existing: Record<string, any> | undefined) {
  const now = Ts.now();
  return {
    email: EMAIL,
    locale: 'en',
    createdAt: existing?.createdAt ?? now,
    accessDate: existing?.accessDate ?? now,
    hasEarlyAccess: false,
    notificationsEnabled: false,
    approvalStatus: 'approved',
    approvedAt: existing?.approvedAt ?? now,
    approvedBy: ACTOR,
    isAdmin: false,
    updatedAt: now,
  };
}

async function ensureDocs(uid: string) {
  const profileRef = db.collection('profiles').doc(uid);
  const privRef = db.collection(PRIVATE_PROFILES).doc(uid);
  const usersRef = db.collection('users').doc(uid);
  const [p, priv, u] = await db.getAll(profileRef, privRef, usersRef);

  const privDoc = privateProfileDoc();
  const pubDoc = publicProfileDoc(uid, p.data());
  log(`profiles_private/${uid}: ${priv.exists ? 'merge' : 'create'} (Lisbon coords, geohash9, adult DOB, email, verificationPhone)`);
  log(`profiles/${uid}: ${p.exists ? 'merge' : 'create'} (isComplete, phone-verified, age verified, approximate, not business)`);
  if (APPLY) {
    // Profile first: the users/{uid} create below fires applySignupGrants,
    // which expects the profile in the shape the app leaves it.
    const batch = db.batch();
    batch.set(privRef, privDoc, { merge: true });
    batch.set(profileRef, pubDoc, { merge: true });
    await batch.commit();
  }

  // Coarse public fields, computed exactly like the mirror triggers.
  const pubAfter = { ...(p.data() ?? {}), ...pubDoc };
  const privAfter = { ...(priv.data() ?? {}), ...privDoc };
  const coarse = computeCoarse(uid, pubAfter, privAfter);
  const coarsePatch = coarseUpdates(p.data() ?? {}, coarse);
  log(`profiles/${uid}: coarse fields ${JSON.stringify({ geohash5: coarse.geohash5, age: coarse.age, approx: !!coarse.approxLocation })}`);
  if (APPLY && Object.keys(coarsePatch).length) await profileRef.update(coarsePatch);

  log(`users/${uid}: ${u.exists ? 'merge' : 'create'} (approvalStatus approved, locale en)`);
  if (APPLY) await usersRef.set(usersDoc(u.data()), { merge: true });

  log('recordVerifiedPhoneImpl: phone_index + profiles_private.phone');
  if (APPLY) {
    const r = await recordVerifiedPhoneImpl(uid);
    if (!r.ok) throw new Error(`recordVerifiedPhone failed: ${r.reason}`);
  }
}

async function ensureMembership(uid: string) {
  const snap = await db.collection('profiles').doc(uid).get();
  const profile = snap.data() ?? {};
  const now = new Date();
  const tier = effectiveTier(profile, now);
  const end = profile.membershipEndDate?.toDate?.() as Date | undefined;
  if ((tier === 'GOLD' || tier === 'PLATINUM') && end && end.getTime() >= MEMBERSHIP_END.getTime()) {
    log(`membership already ${tier} until ${end.toISOString()}: nothing to grant`);
    return;
  }
  // grantMembership extends from the current end date when a paid tier is
  // active, otherwise from now; size the grant so it lands on MEMBERSHIP_END.
  const activeEnd = tier !== 'FREE' && tier !== 'TEST' && end ? end : now;
  const durationMs = MEMBERSHIP_END.getTime() - Math.max(activeEnd.getTime(), now.getTime());
  log(`grantMembership(${TIER}, ${Math.round(durationMs / 86400000)} days) -> ends ${MEMBERSHIP_END.toISOString()}`);
  if (!APPLY) return;
  const result = await grantMembership(uid, TIER, durationMs);
  await db.collection('entitlement_grants').doc(GRANT_AUDIT_ID).set({
    batchId: GRANT_AUDIT_ID,
    grantedBy: ACTOR,
    grantedAt: Ts.now(),
    grants: [{ kind: 'membership', tier: TIER, until: MEMBERSHIP_END.toISOString() }],
    summary: `${TIER} until ${MEMBERSHIP_END.toISOString().slice(0, 10)}`,
    note: 'App Store / Google Play reviewer demo account',
    recipientCount: 1,
    grantedCount: 1,
    failedCount: 0,
    failedUserIds: [],
    recipients: [uid],
    resultEndDate: result.newEndTimestamp,
  });
}

// ---------------------------------------------------------------------------
// Verification
// ---------------------------------------------------------------------------
function postJson(url: string, body: unknown): Promise<any> {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = https.request(
      url,
      { method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          try {
            const json = JSON.parse(raw);
            if ((res.statusCode ?? 500) >= 400) reject(new Error(json?.error?.message ?? `HTTP ${res.statusCode}`));
            else resolve(json);
          } catch (e) {
            reject(e);
          }
        });
      },
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function verify(password: string | undefined): Promise<boolean> {
  let ok = true;
  const user = await admin.auth().getUserByEmail(EMAIL);
  const profile = (await db.collection('profiles').doc(user.uid).get()).data() ?? {};
  const users = (await db.collection('users').doc(user.uid).get()).data() ?? {};
  const tier = effectiveTier(profile);
  const check = (name: string, pass: boolean, detail = '') => {
    console.log(`${pass ? 'PASS' : 'FAIL'}  ${name}${detail ? `  (${detail})` : ''}`);
    if (!pass) ok = false;
  };
  check('Auth user phone set', user.phoneNumber === PHONE);
  check('effective tier GOLD', tier === 'GOLD', `end ${profile.membershipEndDate?.toDate?.().toISOString()}`);
  check('profile complete, not business', profile.isComplete === true && profile.isBusiness === false);
  check('age verified', profile.isAgeVerified === true && profile.ageVerification?.status === 'verified', `age ${profile.age}`);
  check('approximate location in Lisbon', profile.globeDiscoverability === 'approximate' && profile.location?.city === 'Lisbon' && typeof profile.geohash5 === 'string');
  check('users.approvalStatus approved', users.approvalStatus === 'approved');

  if (!password) {
    console.log('SKIP  REST sign-in (set REVIEW_PASSWORD to check it)');
    return ok;
  }
  const key = process.env.GG_WEB_API_KEY;
  if (!key) {
    console.log('SKIP  REST sign-in (GG_WEB_API_KEY not set)');
    return ok;
  }
  try {
    const r = await postJson(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(key)}`,
      { email: EMAIL, password, returnSecureToken: true },
    );
    const payload = JSON.parse(Buffer.from(String(r.idToken).split('.')[1], 'base64url').toString('utf8'));
    check('REST signInWithPassword', r.localId === user.uid);
    check('ID token phone_number claim', payload.phone_number === PHONE);
  } catch (e) {
    check('REST signInWithPassword', false, (e as Error).message);
  }
  return ok;
}

async function main() {
  if (VERIFY_ONLY) {
    const ok = await verify(process.env.REVIEW_PASSWORD);
    process.exit(ok ? 0 : 1);
  }
  console.log(`${APPLY ? 'APPLY' : 'DRY RUN (pass --apply to write)'}: reviewer demo account ${EMAIL}`);
  const { uid, password } = await ensureAuthUser();
  if (!APPLY && uid === '(new uid)') {
    log('profiles, profiles_private, users, phone index, age verification and GOLD grant would be created next');
    return;
  }
  await ensureDocs(uid);
  await ensureMembership(uid);
  if (APPLY) {
    console.log('--- verification ---');
    const ok = await verify(password ?? process.env.REVIEW_PASSWORD);
    if (!ok) process.exit(1);
  }
}

main().then(
  () => process.exit(0),
  (e) => {
    console.error(e);
    process.exit(1);
  },
);
