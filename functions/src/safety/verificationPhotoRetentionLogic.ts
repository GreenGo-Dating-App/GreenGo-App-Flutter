/**
 * Verification-photo retention: PURE decisions (no Firebase access), unit
 * tested. The I/O lives in verificationPhotoRetention.ts.
 *
 * Privacy Policy 8.3 / retention table: "We delete the selfie after the
 * review and keep only the result (verified or not)". 8.4: the business
 * owner's identity document "follows the same rules as in 8.2" (deleted when
 * the check is decided). This covers the two image flows the age-assurance
 * model (idDocumentRetention.ts, P2-6) did not:
 *
 *  1. REGISTRATION photo ("a photo of yourself holding your ID document",
 *     onboarding + reverification), Storage `verifications/{uid}/...` (and
 *     the pre-P1-4 `profiles/{uid}/verifications/...`), referenced by
 *     profiles_private.verificationPhotoPath (legacy: verificationPhotoUrl on
 *     the private and the public profile). Decided by an admin: approved,
 *     rejected or needsResubmission (admin_actions + profiles.verificationStatus).
 *  2. BUSINESS owner ID document, Storage `business_verification/{uid}/...`,
 *     referenced by business_verification_requests/{uid}.ownerDocumentUrl.
 *     Decided when the request status leaves 'pending'.
 *
 * An image that may still be awaiting a review is NEVER deleted.
 */

export const HOUR_MS = 60 * 60 * 1000;
export const DAY_MS = 24 * HOUR_MS;

/** Sweep: grace after a decision before a still-present image is deleted. */
export const DECIDED_GRACE_MS = 24 * HOUR_MS;
/** Sweep: an image no review will ever look at (abandoned / superseded upload). */
export const ORPHAN_GRACE_MS = 7 * DAY_MS;

/** profiles.verificationStatus values that are a final admin decision. */
export const FINAL_REGISTRATION_STATUSES: ReadonlySet<string> = new Set([
  'approved', 'verified', 'rejected', 'needsResubmission',
]);

/** admin_actions.actionType → the final decision it records. */
export const FINAL_REGISTRATION_ACTIONS: Readonly<Record<string, string>> = {
  verification_approved: 'approved',
  verification_rejected: 'rejected',
  verification_resubmission_requested: 'needsResubmission',
};

/** business_verification_requests.status values that are a decision. */
export const FINAL_BUSINESS_STATUSES: ReadonlySet<string> = new Set([
  'approved', 'verified', 'rejected', 'denied',
]);

/** Storage prefixes of a user's registration photos (current + legacy). */
export function registrationPrefixes(uid: string): string[] {
  return [`verifications/${uid}/`, `profiles/${uid}/verifications/`];
}

export function businessPrefix(uid: string): string {
  return `business_verification/${uid}/`;
}

/** Owner uid of a registration / business object path, or null. */
export function ownerOfPath(name: string): { uid: string; kind: 'registration' | 'business' } | null {
  if (typeof name !== 'string' || !name || name.includes('..')) return null;
  let m = name.match(/^verifications\/([^/]+)\/.+/);
  if (m) return { uid: m[1], kind: 'registration' };
  m = name.match(/^profiles\/([^/]+)\/verifications\/.+/);
  if (m) return { uid: m[1], kind: 'registration' };
  m = name.match(/^business_verification\/([^/]+)\/.+/);
  if (m) return { uid: m[1], kind: 'business' };
  return null;
}

/**
 * Storage path of a reference: a plain path, or a Firebase download URL
 * (`https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded path>`,
 * also the emulator form). Null when it is neither.
 */
export function storagePathOfRef(ref: unknown): string | null {
  if (typeof ref !== 'string' || !ref) return null;
  if (!/^https?:\/\//i.test(ref)) return ref.includes('..') ? null : ref;
  try {
    const u = new URL(ref);
    const m = u.pathname.match(/\/v0\/b\/[^/]+\/o\/(.+)$/);
    if (m) return decodeURIComponent(m[1]);
    const g = u.hostname === 'storage.googleapis.com' ? u.pathname.match(/^\/[^/]+\/(.+)$/) : null;
    return g ? decodeURIComponent(g[1]) : null;
  } catch {
    return null;
  }
}

export interface StoredObject {
  name: string;
  /** Creation time (ms); NaN/unknown is treated as "now" (never old enough). */
  createdMs: number;
}

export type PhotoClass = 'pending' | 'decided' | 'orphan';

// ───────────────────────────────────────────────────── registration photo

export interface RegistrationState {
  profileExists: boolean;
  /** profiles.verificationStatus */
  status: string | null;
  /** Latest decision time: max(verificationReviewedAt, latest final admin_action). */
  reviewedAtMs: number | null;
  /** Storage paths the user's profile currently references. */
  referencedPaths: string[];
}

export function isFinalRegistrationStatus(status: unknown): boolean {
  return typeof status === 'string' && FINAL_REGISTRATION_STATUSES.has(status);
}

/**
 *  - 'pending'  may still be reviewed: keep;
 *  - 'decided'  was looked at by (or superseded before) a decision: delete;
 *  - 'orphan'   nobody will ever review it (no profile, never submitted,
 *               uploaded after the decision): delete after ORPHAN_GRACE_MS.
 */
export function classifyRegistrationPhoto(obj: StoredObject, st: RegistrationState): PhotoClass {
  if (!st.profileExists) return 'orphan';
  const created = Number.isFinite(obj.createdMs) ? obj.createdMs : Number.POSITIVE_INFINITY;
  const reviewed = st.reviewedAtMs;
  const beforeDecision = reviewed !== null && Number.isFinite(reviewed) && created <= reviewed;
  if (st.status === 'pending') {
    // The submission under review, or anything that might be it: keep.
    if (st.referencedPaths.includes(obj.name)) return 'pending';
    // Superseded before the previous decision (already reviewed).
    if (beforeDecision) return 'decided';
    // A newer upload that is not the referenced one: an onboarding retake
    // or an abandoned reverification - but only when we KNOW which one is
    // under review; with no reference at all, keep everything.
    return st.referencedPaths.length > 0 ? 'orphan' : 'pending';
  }
  if (isFinalRegistrationStatus(st.status)) {
    if (reviewed === null || !Number.isFinite(reviewed)) return 'decided';
    return beforeDecision ? 'decided' : 'orphan';
  }
  // notSubmitted / phone sign-up / unknown: never sent for review.
  return 'orphan';
}

export interface GraceOpts {
  decidedGraceMs?: number;
  orphanGraceMs?: number;
}

/** Whether [obj] (class [cls]) must be deleted at [nowMs]. Pending never. */
export function isDue(
  cls: PhotoClass,
  obj: StoredObject,
  decidedAtMs: number | null,
  nowMs: number,
  opts: GraceOpts = {},
): boolean {
  const created = Number.isFinite(obj.createdMs) ? obj.createdMs : Number.POSITIVE_INFINITY;
  if (cls === 'pending') return false;
  if (cls === 'decided') {
    const grace = opts.decidedGraceMs ?? DECIDED_GRACE_MS;
    const from = decidedAtMs !== null && Number.isFinite(decidedAtMs) ? decidedAtMs : created;
    return nowMs >= from + grace;
  }
  return nowMs >= created + (opts.orphanGraceMs ?? ORPHAN_GRACE_MS);
}

/**
 * References to clear once the objects in [deleted] are gone: any stored
 * reference to a deleted object, and - when no review is pending any more -
 * any reference to an object that no longer exists.
 */
export function referencesToClear(
  refs: Record<string, unknown>,
  deleted: ReadonlySet<string>,
  existing: ReadonlySet<string>,
  reviewPending: boolean,
): string[] {
  const out: string[] = [];
  for (const [field, value] of Object.entries(refs)) {
    if (value === undefined || value === null || value === '') continue;
    const p = storagePathOfRef(value);
    if (p !== null && deleted.has(p)) out.push(field);
    else if (!reviewPending && (p === null || !existing.has(p))) out.push(field);
  }
  return out;
}

/**
 * The only thing kept after deletion (Privacy Policy 8.3: "the result
 * (verified or not)"), plus who/when/how for the audit trail.
 */
export function registrationReviewRecord(input: {
  status: string | null;
  reviewedAtMs: number | null;
  reviewedBy: string | null;
  method: string | null;
}): { verified: boolean; status: string | null; reviewedAtMs: number | null; reviewedBy: string | null; method: string } {
  return {
    verified: input.status === 'approved' || input.status === 'verified',
    status: input.status,
    reviewedAtMs: input.reviewedAtMs,
    reviewedBy: input.reviewedBy,
    method: input.method && input.method !== 'phone' ? input.method : 'photo',
  };
}

/** Latest final decision among admin_actions rows (timestamps in ms). */
export function latestFinalAction(
  actions: Array<{ actionType?: unknown; timestampMs: number; performedBy?: unknown }>,
): { decision: string; atMs: number; by: string | null } | null {
  let best: { decision: string; atMs: number; by: string | null } | null = null;
  for (const a of actions) {
    const d = FINAL_REGISTRATION_ACTIONS[String(a.actionType ?? '')];
    if (!d || !Number.isFinite(a.timestampMs)) continue;
    if (!best || a.timestampMs >= best.atMs) {
      best = { decision: d, atMs: a.timestampMs, by: typeof a.performedBy === 'string' ? a.performedBy : null };
    }
  }
  return best;
}

// ───────────────────────────────────────────────────── business owner ID

export interface BusinessState {
  requestExists: boolean;
  status: string | null;
  decidedAtMs: number | null;
}

export function isFinalBusinessStatus(status: unknown): boolean {
  return typeof status === 'string' && FINAL_BUSINESS_STATUSES.has(status);
}

export function classifyBusinessDocument(obj: StoredObject, st: BusinessState): PhotoClass {
  if (!st.requestExists) return 'orphan';
  if (!isFinalBusinessStatus(st.status)) return 'pending'; // pending or unknown: keep
  const created = Number.isFinite(obj.createdMs) ? obj.createdMs : Number.POSITIVE_INFINITY;
  const d = st.decidedAtMs;
  if (d === null || !Number.isFinite(d)) return 'decided';
  return created <= d ? 'decided' : 'orphan';
}
