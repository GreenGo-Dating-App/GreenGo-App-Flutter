/**
 * Pure logic of identity_records/{uid} (optional ID-document details,
 * encrypted). No Firestore, no logging. See docs/safety/identity-records.md.
 */
export const IDENTITY_RECORDS = 'identity_records';
export const IDENTITY_ACCESS_LOG = 'identity_access_log';
export const IDENTITY_RATE_LIMITS = 'identity_rate_limits';

export const IDENTITY_SOURCES = ['registration', 'age', 'business'] as const;
export type IdentitySource = (typeof IDENTITY_SOURCES)[number];

export const LEGAL_BASES = ['court_order', 'police_request', 'legal_hold', 'other'] as const;
export type LegalBasis = (typeof LEGAL_BASES)[number];

export const REFERENCE_MIN_LENGTH = 8;
export const REFERENCE_MAX_LENGTH = 500;

/** Retention after account deletion: 6 months (Marco Civil art. 15 period). */
export const RETAIN_AFTER_DELETION_MS = 183 * 24 * 3600 * 1000;
/** A pending (never reviewed) submission is dropped after 30 days. */
export const PENDING_MAX_AGE_MS = 30 * 24 * 3600 * 1000;

/** Submissions per user per day; reveals per admin per hour. */
export const SUBMIT_LIMIT = { cap: 10, windowMs: 24 * 3600 * 1000 };
export const REVEAL_LIMIT = { cap: 20, windowMs: 3600 * 1000 };

export function isIdentitySource(v: unknown): v is IdentitySource {
  return typeof v === 'string' && (IDENTITY_SOURCES as readonly string[]).includes(v);
}

/** Validates the reveal request. Returns an error code or null. */
export function validateRevealRequest(data: unknown): { uid: string; legalBasis: LegalBasis; reference: string } | string {
  const d = (data && typeof data === 'object' ? data : {}) as Record<string, unknown>;
  const uid = typeof d.uid === 'string' ? d.uid.trim() : '';
  if (!uid || uid.length > 128 || uid.includes('/')) return 'invalid_uid';
  const basis = d.legalBasis;
  if (typeof basis !== 'string' || !(LEGAL_BASES as readonly string[]).includes(basis)) return 'invalid_legal_basis';
  const reference = typeof d.reference === 'string' ? d.reference.trim() : '';
  if (reference.length < REFERENCE_MIN_LENGTH || reference.length > REFERENCE_MAX_LENGTH) return 'invalid_reference';
  return { uid, legalBasis: basis as LegalBasis, reference };
}

/** Fixed-window counter step. `state` = the counter doc data (or null). */
export function rateLimitStep(
  state: { windowStartMs?: number; count?: number } | null | undefined,
  limit: { cap: number; windowMs: number },
  nowMs: number,
): { allowed: boolean; next: { windowStartMs: number; count: number } } {
  const start = typeof state?.windowStartMs === 'number' ? state.windowStartMs : 0;
  const count = typeof state?.count === 'number' ? state.count : 0;
  if (start + limit.windowMs <= nowMs) {
    return { allowed: true, next: { windowStartMs: nowMs, count: 1 } };
  }
  if (count >= limit.cap) return { allowed: false, next: { windowStartMs: start, count } };
  return { allowed: true, next: { windowStartMs: start, count: count + 1 } };
}

const toMs = (v: unknown): number | null => {
  if (typeof v === 'number') return v;
  const t = v as { toMillis?: () => number } | null;
  return t && typeof t.toMillis === 'function' ? t.toMillis() : null;
};

/**
 * What the daily sweep does with one record:
 *  - 'delete'  : retainUntil passed, or a pending submission older than 30 days;
 *  - 'held'    : would be deleted but the subject is under a legal hold;
 *  - 'keep'    : otherwise.
 */
export function sweepDecision(
  rec: Record<string, unknown>,
  nowMs: number,
  underLegalHold: boolean,
): 'delete' | 'held' | 'keep' {
  const retainUntil = toMs(rec.retainUntil);
  const submittedAt = toMs(rec.submittedAt);
  const expired =
    (retainUntil !== null && retainUntil <= nowMs) ||
    (rec.status === 'pending' && submittedAt !== null && submittedAt + PENDING_MAX_AGE_MS <= nowMs);
  if (!expired) return 'keep';
  if (rec.legalHold === true || underLegalHold) return 'held';
  return 'delete';
}

/** Patch applied on account deletion: pending -> delete; verified -> retainUntil. */
export function onAccountDeletion(
  rec: Record<string, unknown> | null | undefined,
  nowMs: number,
): { action: 'none' } | { action: 'delete' } | { action: 'retain'; retainUntilMs: number } {
  if (!rec) return { action: 'none' };
  if (rec.status !== 'verified') return { action: 'delete' };
  const existing = toMs(rec.retainUntil);
  const until = nowMs + RETAIN_AFTER_DELETION_MS;
  return { action: 'retain', retainUntilMs: existing !== null && existing > until ? existing : until };
}
