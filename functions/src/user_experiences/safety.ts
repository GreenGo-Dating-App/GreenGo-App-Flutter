/**
 * User experiences — Phase 1 safety rules (PURE: no Firestore access).
 *
 *  - ID document: hosts need an UPLOADED identity document (age-assurance
 *    flow: profiles.ageVerification.status pending|verified) to create an
 *    experience, and an APPROVED one (server-owned profiles.isAgeVerified) to
 *    PUBLISH a listing that takes money (paid, or carrying a paymentLink).
 *    Free listings: uploaded is enough. Drafts may hold a payment link.
 *  - Host agreement: accepted (profiles.hostAgreementVersion >= current)
 *    before the first publish.
 *  - New hosts (< 3 visible reviews across all their experiences, i.e.
 *    profiles.hostRatingCount) may have at most ONE published paid listing.
 *  - Fixed cancellation policies (flexible | moderate | strict) + notes.
 *
 * Mirrored by firestore.rules (user_experiences update) for direct client
 * writes; transitions the rules cannot check (the new-host count) go through
 * the publishUserExperience callable.
 */

export const HOST_AGREEMENT_VERSION = 1;
export const NEW_HOST_MIN_REVIEWS = 3;
export const NEW_HOST_MAX_PUBLISHED_PAID = 1;

export const CANCELLATION_POLICIES = ['flexible', 'moderate', 'strict'] as const;
export type CancellationPolicy = typeof CANCELLATION_POLICIES[number];
export const DEFAULT_CANCELLATION_POLICY: CancellationPolicy = 'moderate';
export const CANCELLATION_NOTES_MAX = 300;

/**
 * Policy + notes from a payload or stored doc. A legacy free-text
 * `cancellationPolicy` (pre-enum docs) becomes policy 'moderate' with the old
 * text as notes.
 */
export function normalizeCancellation(d: Record<string, unknown> | null | undefined): {
  cancellationPolicy: CancellationPolicy;
  cancellationNotes: string | null;
} {
  const raw = typeof d?.cancellationPolicy === 'string' ? d.cancellationPolicy.trim() : '';
  const notesRaw = typeof d?.cancellationNotes === 'string' ? d.cancellationNotes.trim() : '';
  if ((CANCELLATION_POLICIES as readonly string[]).includes(raw)) {
    return {
      cancellationPolicy: raw as CancellationPolicy,
      cancellationNotes: notesRaw ? notesRaw.slice(0, CANCELLATION_NOTES_MAX) : null,
    };
  }
  const legacy = notesRaw || raw;
  return {
    cancellationPolicy: DEFAULT_CANCELLATION_POLICY,
    cancellationNotes: legacy ? legacy.slice(0, CANCELLATION_NOTES_MAX) : null,
  };
}

export type IdDocumentState = 'none' | 'uploaded' | 'approved';

/** Where [profile] stands on the identity document. */
export function idDocumentState(profile: Record<string, any> | null | undefined): IdDocumentState {
  if (!profile) return 'none';
  if (profile.isAgeVerified === true) return 'approved';
  const status = profile.ageVerification?.status;
  if (status === 'verified') return 'approved';
  if (status === 'pending') return 'uploaded';
  return 'none';
}

/** True when the listing takes money from guests (paid, or has a link). */
export function takesPayment(e: Record<string, unknown> | null | undefined): boolean {
  if (!e) return false;
  const pl = e.paymentLink as Record<string, unknown> | null | undefined;
  const hasLink = !!pl && typeof pl === 'object' && typeof pl.value === 'string' &&
    pl.value.trim().length > 0;
  return e.isFree !== true || hasLink;
}

export function hostAgreementAccepted(profile: Record<string, any> | null | undefined): boolean {
  return Number(profile?.hostAgreementVersion ?? 0) >= HOST_AGREEMENT_VERSION;
}

export function isNewHost(profile: Record<string, any> | null | undefined): boolean {
  return Number(profile?.hostRatingCount ?? 0) < NEW_HOST_MIN_REVIEWS;
}

export type SafetyCode =
  | 'id_document_required'
  | 'id_document_not_approved'
  | 'host_agreement_required'
  | 'new_host_paid_limit'
  | 'host_banned';

/** Why [profile] may not CREATE an experience at all (any status), or null. */
export function createBlockReason(profile: Record<string, any> | null | undefined): SafetyCode | null {
  if (profile?.isBanned === true) return 'host_banned';
  if (idDocumentState(profile) === 'none') return 'id_document_required';
  return null;
}

/**
 * Why the listing [experience] (as it WILL be) may not be PUBLISHED by
 * [profile], or null. [otherPublishedPaid] = the host's OTHER published
 * PAID listings (isFree false, not counting this one).
 * Admins skip the new-host limit (but not the document rules).
 */
export function publishBlockReason(params: {
  profile: Record<string, any> | null | undefined;
  experience: Record<string, unknown>;
  otherPublishedPaid: number;
}): SafetyCode | null {
  const { profile, experience, otherPublishedPaid } = params;
  const base = createBlockReason(profile);
  if (base) return base;
  if (!hostAgreementAccepted(profile)) return 'host_agreement_required';
  if (!takesPayment(experience)) return null;
  if (idDocumentState(profile) !== 'approved') return 'id_document_not_approved';
  if (experience.isFree !== true && profile?.isAdmin !== true && isNewHost(profile) &&
      otherPublishedPaid >= NEW_HOST_MAX_PUBLISHED_PAID) {
    return 'new_host_paid_limit';
  }
  return null;
}

/** The fields that turn a listing into a FREE one (the "publish as free" option). */
export const AS_FREE_PATCH = Object.freeze({
  isFree: true,
  price: 0,
  currency: null,
  paymentLink: null,
});

// ─────────────────────────────────────────────────────────────── reports

export const REPORTS_TO_HIDE = 3;
/** `reports.type` values that target a user experience. */
export const EXPERIENCE_REPORT_TYPES: readonly string[] = ['user_experience', 'experience'];

/** Whether this many DISTINCT reporters hide a listing currently in [status]. */
export function shouldHideForReports(distinctReporters: number, status: unknown): boolean {
  return distinctReporters >= REPORTS_TO_HIDE && status !== 'hidden';
}
