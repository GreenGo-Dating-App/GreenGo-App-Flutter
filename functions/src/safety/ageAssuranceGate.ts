/**
 * Regional age-assurance gate (audit H-21, plan P3-1).
 *
 * Laws: Brazil ECA Digital (Lei 15.211/2025), UK Online Safety Act ("highly
 * effective age assurance"), Texas SB 2420 (+ Utah / Louisiana app-store age
 * laws), EU DSA art. 28.
 *
 * OWNER DECISION (2026-10-08): when switched ON, users in the configured
 * regions (default BR, GB, US-TX) need STRONG age assurance before they can use
 * people discovery and START private 1:1 messages (new conversations, or a
 * first message from them in a conversation). Conversations in which they have
 * already written stay usable; everything else in the app keeps working.
 * Everybody else keeps today's self-declared gate (declareAge, under-18 blocked).
 * Minors are blocked entirely by that gate, so no parental-supervision tooling.
 *
 * Switches (admin-editable, both default OFF / default list):
 *   app_config/feature_flags.ageAssuranceEnforced   (bool; `flags.ageAssuranceEnforced` also read)
 *   app_config/age_assurance.regions                ['BR','GB','US-TX']
 *   app_config/age_assurance.acceptedAndroidSources [3,4]  Play ageRangeSource tiers
 *   app_config/age_assurance.acceptedAppleDeclarations     see DEFAULT_APPLE_DECLARATIONS
 *   app_config/age_assurance.storeSignalMaxAgeDays  365
 *
 * Assurance is satisfied by ANY of:
 *   (a) id_verification - ID document approved (profiles.isAgeVerified or
 *       id_documents/{uid}.ageVerified, both server-owned);
 *   (b) store_signal    - an accepted store age signal (recordStoreAgeSignal);
 *   (c) admin_override  - setAgeAssuranceOverride (superAdmin only).
 *
 * Record: `age_assurance/{uid}` (server-only: no rule matches it, so the
 * default-deny rule applies) - method, timestamp, signal source.
 *
 * Region: country from the profile (`location.country`, English name or ISO
 * code), US state from the COARSE public coordinates (point-in-polygon, 0.1
 * degree rounding) - never the exact private location - and, only as a
 * fallback or to ADD a region, the device locale / store region sent by the
 * app. A hint can never REMOVE a region. Spoofing the location only lets
 * someone skip the requirement in the same way as moving abroad would; ID
 * verification is accepted everywhere.
 *
 * Server enforcement (assertAgeAssured):
 *   - spendCoins: direct_message, superlike (messaging), grid_view_more,
 *     discovery_see_more (discovery) are refused BEFORE any charge;
 *   - scheduleMessage: refused unless the sender already wrote in that
 *     conversation.
 * The rest of discovery and 1:1 chat are client-side Firestore reads/writes;
 * the rules for the later lockdown wave are in docs/security/age-assurance-rules.md.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { requireAdmin, SUPER_ADMIN_ONLY } from '../shared/adminAuth';
import { markAgeBlocked, AGE_BLOCKED_STATUS } from '../auth/ageGate';

const db = () => admin.firestore();

export const AGE_ASSURANCE = 'age_assurance';
export const AGE_ASSURANCE_REQUIRED = 'age-assurance-required';
export const DEFAULT_REGIONS = ['BR', 'GB', 'US-TX'];
/** Play Age Signals ageRangeSource: 1 TIER_A self-declared, 2 TIER_B guardian,
 *  3 TIER_C credit card / email / selfie / government ID / tax ID,
 *  4 TIER_D government ID + selfie, or digital ID. */
export const DEFAULT_ANDROID_SOURCES = [3, 4];
/** Apple AgeRangeService.AgeRangeDeclaration case names that are NOT a bare
 *  self-declaration. iOS 26.0 only has selfDeclared / guardianDeclared; the
 *  others arrived later, so the app sends the case name as a string. */
export const DEFAULT_APPLE_DECLARATIONS = [
  'checkedByOtherMethod',
  'governmentIDChecked',
  'paymentChecked',
];
export const DEFAULT_STORE_SIGNAL_MAX_AGE_DAYS = 365;

export type AgeAssuranceMethod = 'id_verification' | 'store_signal' | 'admin_override';
export type GatedFeature = 'discovery' | 'messaging';

export interface AgeAssuranceConfig {
  enforced: boolean;
  regions: string[];
  acceptedAndroidSources: number[];
  acceptedAppleDeclarations: string[];
  storeSignalMaxAgeDays: number;
}

// ---------------------------------------------------------------------------
// Config (cached: the enforcement helper runs on hot callables)
// ---------------------------------------------------------------------------

const CONFIG_TTL_MS = 60_000;
let configCache: { at: number; cfg: AgeAssuranceConfig } | null = null;

/** Test hook. */
export function resetAgeAssuranceConfigCache(): void {
  configCache = null;
}

const upperList = (v: unknown, fallback: string[]): string[] =>
  Array.isArray(v) ? v.filter((x) => typeof x === 'string' && x.trim()).map((x) => String(x).trim().toUpperCase()) : fallback;

export async function loadAgeAssuranceConfig(): Promise<AgeAssuranceConfig> {
  if (configCache && Date.now() - configCache.at < CONFIG_TTL_MS) return configCache.cfg;
  const [flagsSnap, cfgSnap] = await Promise.all([
    db().doc('app_config/feature_flags').get(),
    db().doc('app_config/age_assurance').get(),
  ]);
  const flags = flagsSnap.data() ?? {};
  const c = cfgSnap.data() ?? {};
  const cfg: AgeAssuranceConfig = {
    enforced: flags.ageAssuranceEnforced === true || flags.flags?.ageAssuranceEnforced === true,
    regions: upperList(c.regions, DEFAULT_REGIONS),
    acceptedAndroidSources: Array.isArray(c.acceptedAndroidSources)
      ? c.acceptedAndroidSources.filter((x: unknown) => typeof x === 'number')
      : DEFAULT_ANDROID_SOURCES,
    acceptedAppleDeclarations: Array.isArray(c.acceptedAppleDeclarations)
      ? c.acceptedAppleDeclarations.filter((x: unknown) => typeof x === 'string')
      : DEFAULT_APPLE_DECLARATIONS,
    storeSignalMaxAgeDays: typeof c.storeSignalMaxAgeDays === 'number' && c.storeSignalMaxAgeDays > 0
      ? c.storeSignalMaxAgeDays
      : DEFAULT_STORE_SIGNAL_MAX_AGE_DAYS,
  };
  configCache = { at: Date.now(), cfg };
  return cfg;
}

// ---------------------------------------------------------------------------
// Region detection (pure, exported for tests)
// ---------------------------------------------------------------------------

/** Lower-cased country names (en/it/de/es/fr/pt) -> ISO 3166-1 alpha-2. Only
 *  the countries a region list is likely to name; a 2-letter code also works. */
const COUNTRY_NAMES: Record<string, string> = {
  brazil: 'BR', brasil: 'BR', brasile: 'BR', 'brésil': 'BR', bresil: 'BR', brasilien: 'BR',
  'united kingdom': 'GB', uk: 'GB', 'great britain': 'GB', britain: 'GB', england: 'GB',
  scotland: 'GB', wales: 'GB', 'northern ireland': 'GB', 'regno unito': 'GB', 'reino unido': 'GB',
  'vereinigtes königreich': 'GB', 'royaume-uni': 'GB', 'united kingdom of great britain and northern ireland': 'GB',
  'united states': 'US', 'united states of america': 'US', usa: 'US', 'u.s.a.': 'US', 'u.s.': 'US',
  'stati uniti': 'US', "stati uniti d'america": 'US', 'vereinigte staaten': 'US', 'estados unidos': 'US',
  'états-unis': 'US', 'etats-unis': 'US',
  australia: 'AU', ireland: 'IE', france: 'FR', germany: 'DE', italy: 'IT', spain: 'ES', portugal: 'PT',
};

export function countryCodeOf(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const s = raw.trim();
  if (!s) return null;
  if (/^[A-Za-z]{2}$/.test(s)) return s.toUpperCase() === 'UK' ? 'GB' : s.toUpperCase();
  return COUNTRY_NAMES[s.toLowerCase()] ?? null;
}

/** Simplified Texas boundary [lon, lat]. Only the borders with other US states
 *  (NM, OK, AR, LA) need to be right: the country is checked first, so the
 *  polygon deliberately spills into Mexico and the Gulf. ~10-20 km accuracy at
 *  state lines, which is all coarse coordinates allow anyway. */
const TEXAS: Array<[number, number]> = [
  [-106.65, 32.0], [-103.06, 32.0], [-103.04, 36.5], [-100.0, 36.5], [-100.0, 34.56],
  [-99.2, 34.38], [-98.6, 34.15], [-98.1, 34.13], [-97.55, 33.9], [-97.15, 33.72],
  [-96.6, 33.85], [-96.4, 33.75], [-95.8, 33.86], [-95.3, 33.88], [-94.9, 33.8],
  [-94.48, 33.64], [-94.04, 33.55], [-94.04, 31.99], [-93.8, 31.7], [-93.55, 31.1],
  [-93.7, 30.3], [-93.84, 29.69], [-93.84, 28.0], [-97.0, 25.5], [-99.5, 26.0],
  [-101.5, 28.5], [-103.5, 28.5], [-105.5, 30.0], [-106.8, 31.5],
];
const US_STATE_POLYGONS: Record<string, Array<[number, number]>> = { 'US-TX': TEXAS };

function pointInPolygon(lon: number, lat: number, poly: Array<[number, number]>): boolean {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i];
    const [xj, yj] = poly[j];
    if ((yi > lat) !== (yj > lat) && lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

/** US state (ISO 3166-2) from coordinates rounded to 0.1 deg, for the states
 *  that have a polygon here (Texas). Null when unknown. */
export function usStateFromCoarse(lat: unknown, lng: unknown): string | null {
  if (typeof lat !== 'number' || typeof lng !== 'number' || !isFinite(lat) || !isFinite(lng)) return null;
  if (lat === 0 && lng === 0) return null;
  const rl = Math.round(lat * 10) / 10;
  const rg = Math.round(lng * 10) / 10;
  for (const [code, poly] of Object.entries(US_STATE_POLYGONS)) {
    if (pointInPolygon(rg, rl, poly)) return code;
  }
  return null;
}

export interface RegionHints {
  /** Device locale country (e.g. 'BR' from pt_BR). */
  localeCountry?: unknown;
  /** Store / device region, ISO 3166-1 alpha-2. */
  storeCountry?: unknown;
  /** ISO 3166-2 subdivision the device reported, e.g. 'US-TX'. */
  subdivision?: unknown;
}

export interface ResolvedRegion {
  country: string | null;
  subdivision: string | null;
  source: 'profile' | 'hint' | 'none';
}

/** Region of a user from the public profile (+ optional client hints). */
export function resolveRegion(profile: Record<string, any> | undefined, hints: RegionHints = {}): ResolvedRegion {
  const loc = profile?.location ?? {};
  let country = countryCodeOf(loc.countryCode) ?? countryCodeOf(loc.country);
  let source: ResolvedRegion['source'] = country ? 'profile' : 'none';
  if (!country) {
    country = countryCodeOf(hints.storeCountry) ?? countryCodeOf(hints.localeCountry);
    if (country) source = 'hint';
  }
  let subdivision: string | null = null;
  if (country === 'US') {
    subdivision = usStateFromCoarse(loc.latitude, loc.longitude);
    const hinted = typeof hints.subdivision === 'string' ? hints.subdivision.trim().toUpperCase() : '';
    if (!subdivision && /^US-[A-Z]{2}$/.test(hinted)) subdivision = hinted;
  }
  return { country, subdivision, source };
}

/** All region codes that apply to [r] (country, plus subdivision), plus any
 *  region a hint ADDS (hints never remove one). */
export function regionCodes(r: ResolvedRegion, hints: RegionHints = {}): string[] {
  const out = new Set<string>();
  if (r.country) out.add(r.country);
  if (r.subdivision) out.add(r.subdivision);
  const hc = countryCodeOf(hints.storeCountry);
  if (hc) out.add(hc);
  const hs = typeof hints.subdivision === 'string' ? hints.subdivision.trim().toUpperCase() : '';
  if (/^[A-Z]{2}-[A-Z0-9]{1,3}$/.test(hs) && (!r.country || hs.startsWith(`${r.country}-`))) out.add(hs);
  return [...out];
}

export function regionRequired(codes: string[], regions: string[]): boolean {
  return codes.some((c) => regions.includes(c));
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

const millis = (v: any): number | null =>
  v instanceof admin.firestore.Timestamp ? v.toMillis() : typeof v?.toMillis === 'function' ? v.toMillis() : null;

export interface AgeAssuranceStatus {
  enforced: boolean;
  required: boolean;
  satisfied: boolean;
  satisfiedBy: AgeAssuranceMethod[];
  /** Ways the requirement can be met (the app shows those its platform has). */
  methods: AgeAssuranceMethod[];
  region: ResolvedRegion & { codes: string[] };
  idVerificationStatus: string | null;
  /** `age_assurance/{uid}.blocked` as last stored (rules mirror, see syncBlockedFlag). */
  storedBlocked: boolean | null;
}

export async function computeAgeAssurance(uid: string, hints: RegionHints = {}): Promise<AgeAssuranceStatus> {
  const cfg = await loadAgeAssuranceConfig();
  const [profileSnap, recordSnap, idSnap] = await Promise.all([
    db().collection('profiles').doc(uid).get(),
    db().collection(AGE_ASSURANCE).doc(uid).get(),
    db().collection('id_documents').doc(uid).get(),
  ]);
  const profile = profileSnap.data();
  const record = recordSnap.data() ?? {};
  // Hints from this call win; otherwise the ones the app sent last time.
  const stored = (record.regionHints ?? {}) as RegionHints;
  const given = hints.localeCountry || hints.storeCountry || hints.subdivision;
  if (!given) hints = stored;
  const region = resolveRegion(profile, hints);
  const codes = regionCodes(region, hints);

  const satisfiedBy: AgeAssuranceMethod[] = [];
  if (profile?.isAgeVerified === true || idSnap.data()?.ageVerified === true) satisfiedBy.push('id_verification');
  const sig = record.storeSignal;
  if (sig?.accepted === true) {
    const at = millis(sig.recordedAt);
    if (at !== null && Date.now() - at <= cfg.storeSignalMaxAgeDays * 86_400_000) satisfiedBy.push('store_signal');
  }
  if (record.adminOverride?.granted === true) satisfiedBy.push('admin_override');

  return {
    enforced: cfg.enforced,
    required: cfg.enforced && regionRequired(codes, cfg.regions),
    satisfied: satisfiedBy.length > 0,
    satisfiedBy,
    methods: ['id_verification', 'store_signal'],
    region: { ...region, codes },
    idVerificationStatus: (profile?.ageVerification?.status as string | undefined) ?? null,
    storedBlocked: typeof record.blocked === 'boolean' ? record.blocked : null,
  };
}

/**
 * Keeps `age_assurance/{uid}.blocked` (required && !satisfied) current, for the
 * Firestore rules of the lockdown wave (they cannot compute regions; see
 * docs/security/age-assurance-rules.md). Writes only when the value changes,
 * and never creates a record for a user the gate does not concern.
 */
export async function syncBlockedFlag(uid: string, s: AgeAssuranceStatus): Promise<void> {
  const blocked = s.required && !s.satisfied;
  if (s.storedBlocked === blocked) return;
  if (s.storedBlocked === null && !blocked) return;
  await db().collection(AGE_ASSURANCE).doc(uid).set(
    { blocked, blockedComputedAt: admin.firestore.Timestamp.now() },
    { merge: true },
  );
}

/** True when [uid] may use [feature]. One cached config read when the flag is off. */
export async function isAgeAssured(uid: string): Promise<boolean> {
  const cfg = await loadAgeAssuranceConfig();
  if (!cfg.enforced) return true;
  const s = await computeAgeAssurance(uid);
  return !s.required || s.satisfied;
}

/** Throws failed-precondition {reason: 'age-assurance-required'} when blocked. */
export async function assertAgeAssured(uid: string, feature: GatedFeature): Promise<void> {
  if (await isAgeAssured(uid)) return;
  throw new HttpsError(
    'failed-precondition',
    `${AGE_ASSURANCE_REQUIRED}: Verify your age to use this feature.`,
    { reason: AGE_ASSURANCE_REQUIRED, feature },
  );
}

// ---------------------------------------------------------------------------
// Callables
// ---------------------------------------------------------------------------

/** `{required, satisfied, methods, satisfiedBy, enforced, region}` for the caller. */
export async function handleGetAgeAssuranceStatus(request: any) {
  const uid = request?.auth?.uid as string | undefined;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const d = request.data ?? {};
  const hints: RegionHints = {
    localeCountry: typeof d.localeCountry === 'string' ? d.localeCountry.slice(0, 8) : undefined,
    storeCountry: typeof d.storeCountry === 'string' ? d.storeCountry.slice(0, 8) : undefined,
    subdivision: typeof d.subdivision === 'string' ? d.subdivision.slice(0, 8) : undefined,
  };
  const s = await computeAgeAssurance(uid, hints);
  await syncBlockedFlag(uid, s);
  // Remember the hints the decision used (server-only) so enforcement on other
  // callables sees the same region even without hints.
  if (s.enforced && (hints.localeCountry || hints.storeCountry || hints.subdivision)) {
    await db().collection(AGE_ASSURANCE).doc(uid).set({
      regionHints: {
        localeCountry: countryCodeOf(hints.localeCountry),
        storeCountry: countryCodeOf(hints.storeCountry),
        subdivision: typeof hints.subdivision === 'string' ? hints.subdivision.toUpperCase() : null,
        at: admin.firestore.Timestamp.now(),
      },
    }, { merge: true });
  }
  return {
    enforced: s.enforced,
    required: s.required,
    satisfied: s.satisfied,
    satisfiedBy: s.satisfiedBy,
    methods: s.methods,
    region: s.region.codes,
    idVerificationStatus: s.idVerificationStatus,
  };
}

export const getAgeAssuranceStatus = onCall({ memory: '512MiB', timeoutSeconds: 30 }, handleGetAgeAssuranceStatus);

/**
 * Records an on-device store age signal.
 *
 * TRUST MODEL: the app reads the signal on the device; a modified client can
 * forge it. It is recorded with its source and only ever counts for the
 * `store_signal` method. Neither Play Age Signals (0.0.4) nor Apple's Declared
 * Age Range returns a server-verifiable signed token; Google recommends Play
 * Integrity around the call (optional `integrityToken` is stored for a later
 * server check, not verified here). Counsel: see docs/security/age-assurance-rules.md.
 *
 * A signal saying the user is UNDER 18 is acted on like declareAge: the account
 * is age-blocked (a forged minor signal only harms the forger).
 */
export async function handleRecordStoreAgeSignal(request: any) {
  const uid = request?.auth?.uid as string | undefined;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const d = request.data ?? {};
  const platform = d.platform === 'android' || d.platform === 'ios' ? d.platform : null;
  if (!platform) throw new HttpsError('invalid-argument', 'platform must be android or ios.');
  const intOrNull = (v: unknown): number | null =>
    typeof v === 'number' && Number.isInteger(v) && v >= 0 && v <= 150 ? v : null;
  const ageLower = intOrNull(d.ageLower);
  const ageUpper = intOrNull(d.ageUpper);
  const cfg = await loadAgeAssuranceConfig();

  let source: string;
  let strength: string | null;
  let sourceAccepted: boolean;
  if (platform === 'android') {
    source = 'google_play_age_signals';
    const tier = intOrNull(d.ageRangeSource);
    strength = tier === null ? null : String(tier);
    sourceAccepted = tier !== null && cfg.acceptedAndroidSources.includes(tier);
  } else {
    source = 'apple_declared_age_range';
    const decl = typeof d.declaration === 'string' ? d.declaration.slice(0, 64) : null;
    strength = decl;
    sourceAccepted = decl !== null && cfg.acceptedAppleDeclarations.includes(decl);
  }
  const shared = d.shared !== false && (ageLower !== null || ageUpper !== null);
  const adult = ageLower !== null && ageLower >= 18;
  const minor = ageUpper !== null && ageUpper < 18;
  const accepted = shared && adult && !minor && sourceAccepted;

  const now = admin.firestore.Timestamp.now();
  await db().collection(AGE_ASSURANCE).doc(uid).set({
    storeSignal: {
      platform,
      source,
      strength,
      ageLower,
      ageUpper,
      shared,
      accepted,
      minor,
      installId: typeof d.installId === 'string' ? d.installId.slice(0, 128) : null,
      integrityTokenPresent: typeof d.integrityToken === 'string' && d.integrityToken.length > 0,
      verifiedServerSide: false,
      recordedAt: now,
    },
    ...(accepted ? { lastSatisfiedMethod: 'store_signal', lastSatisfiedAt: now } : {}),
    updatedAt: now,
  }, { merge: true });

  if (minor) {
    // Same outcome as declaring an under-18 birth date.
    await markAgeBlocked(uid, (request.auth?.token?.email as string | undefined) ?? null, ageUpper, `store_signal_${platform}`);
    const profile = db().collection('profiles').doc(uid);
    const p = await profile.get();
    if (p.exists) await profile.update({ accountStatus: AGE_BLOCKED_STATUS, ageBlockedAt: now });
    return { accepted: false, reason: 'UNDER_18' };
  }

  const s = await computeAgeAssurance(uid);
  await syncBlockedFlag(uid, s);
  return {
    accepted,
    reason: accepted ? null : !shared ? 'NOT_SHARED' : !adult ? 'NOT_ADULT' : 'SOURCE_NOT_ACCEPTED',
    required: s.required,
    satisfied: s.satisfied,
    satisfiedBy: s.satisfiedBy,
  };
}

export const recordStoreAgeSignal = onCall({ memory: '512MiB', timeoutSeconds: 30 }, handleRecordStoreAgeSignal);

/**
 * Admin override (superAdmin only): `{userId, granted: boolean, reason}`.
 * granted=true satisfies assurance; false removes the override (other methods
 * still count). Audited in admin_audit_log.
 */
export async function handleSetAgeAssuranceOverride(request: any) {
  const who = await requireAdmin(request?.auth, SUPER_ADMIN_ONLY);
  const d = request.data ?? {};
  const target = typeof d.userId === 'string' ? d.userId.trim() : '';
  if (!target || target.includes('/')) throw new HttpsError('invalid-argument', 'userId is required.');
  if (typeof d.granted !== 'boolean') throw new HttpsError('invalid-argument', 'granted (boolean) is required.');
  const reason = typeof d.reason === 'string' ? d.reason.slice(0, 500) : '';
  const now = admin.firestore.Timestamp.now();
  await db().collection(AGE_ASSURANCE).doc(target).set({
    adminOverride: { granted: d.granted, by: who.uid, reason, at: now },
    ...(d.granted ? { lastSatisfiedMethod: 'admin_override', lastSatisfiedAt: now } : {}),
    updatedAt: now,
  }, { merge: true });
  await db().collection('admin_audit_log').add({
    adminId: who.uid,
    adminEmail: request.auth?.token?.email ?? 'unknown',
    action: d.granted ? 'age_assurance_override_grant' : 'age_assurance_override_revoke',
    targetType: 'user',
    targetId: target,
    details: { reason },
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  const s = await computeAgeAssurance(target);
  await syncBlockedFlag(target, s);
  return { userId: target, granted: d.granted, required: s.required, satisfied: s.satisfied, satisfiedBy: s.satisfiedBy };
}

export const setAgeAssuranceOverride = onCall({ memory: '512MiB', timeoutSeconds: 30 }, handleSetAgeAssuranceOverride);
