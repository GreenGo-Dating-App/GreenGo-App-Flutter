/**
 * ID-document retention — PURE decision logic (no Firebase access), so it can
 * be unit-tested. The I/O lives in idDocumentRetention.ts.
 *
 * Policy (DRAFT — lawyer review: LGPD art. 7 IX legitimate interest /
 * GDPR Art. 6(1)(f), fraud prevention):
 *   - the CURRENT identity document of an account is kept server-side
 *     (`id_documents/{uid}/…`, no client access) while the account exists;
 *   - a REPLACED document is kept for 30 days after the replacement;
 *   - on ACCOUNT DELETION every document is moved to `retention/{uid}/…` and
 *     kept for 30 days after the deletion;
 *   - then it is permanently erased by `purgeRetainedIdDocuments`, unless an
 *     admin placed a `legalHold` (e.g. an open scam report).
 */

export const RETENTION_DAYS = 30;
export const DAY_MS = 24 * 60 * 60 * 1000;

export type RetentionReason = 'replaced' | 'account-deleted';

export interface RetentionEntry {
  id: string;
  uid?: string;
  storagePaths?: unknown;
  purgeAfterMs: number | null; // null = unknown/malformed
  legalHold?: unknown;
}

/** When a document retained at [retainedAtMs] may be purged. */
export function purgeAfterMs(retainedAtMs: number, days = RETENTION_DAYS): number {
  return retainedAtMs + days * DAY_MS;
}

/** Storage paths of an entry, sanitised (strings only, de-duplicated). */
export function entryPaths(entry: Pick<RetentionEntry, 'storagePaths'>): string[] {
  if (!Array.isArray(entry.storagePaths)) return [];
  const out: string[] = [];
  for (const p of entry.storagePaths) {
    if (typeof p === 'string' && p.length > 0 && !out.includes(p)) out.push(p);
  }
  return out;
}

/**
 * Whether [entry] must be purged now. A legal hold always wins; an entry with
 * an unreadable purge date is NEVER purged automatically (keep + log rather
 * than erase evidence by accident).
 */
export function isDueForPurge(entry: RetentionEntry, nowMs: number): boolean {
  if (entry.legalHold === true) return false;
  if (entry.purgeAfterMs === null || !Number.isFinite(entry.purgeAfterMs)) return false;
  return entry.purgeAfterMs <= nowMs;
}

export interface PurgePagePlan {
  due: RetentionEntry[];
  held: number;
  notDue: number;
  /** Id of the last entry of the page (startAfter cursor), or null if empty. */
  cursor: string | null;
  /** True when the page was short → no more candidates. */
  done: boolean;
}

/**
 * Plans one page of the purge. The query already selects `purgeAfter <= now`
 * ordered by purgeAfter; held entries stay in that range forever, so the
 * caller pages past them with [cursor] instead of re-reading page 1.
 */
export function planPurgePage(
  page: RetentionEntry[],
  nowMs: number,
  pageSize: number,
): PurgePagePlan {
  const due: RetentionEntry[] = [];
  let held = 0;
  let notDue = 0;
  for (const e of page) {
    if (isDueForPurge(e, nowMs)) due.push(e);
    else if (e.legalHold === true) held++;
    else notDue++;
  }
  return {
    due,
    held,
    notDue,
    cursor: page.length ? page[page.length - 1].id : null,
    done: page.length < pageSize,
  };
}

/**
 * The single 'account-deleted' entry for [uid], merged with any entries it
 * supersedes (earlier 'replaced' ones, or a previous run of the deletion
 * hook): union of paths, the LATEST purge date, and a hold if any had one.
 */
export function mergeAccountRetention(
  movedPaths: string[],
  deletedAtMs: number,
  existing: RetentionEntry[],
): { storagePaths: string[]; purgeAfterMs: number; legalHold: boolean } {
  const paths = [...new Set(movedPaths.filter((p) => typeof p === 'string' && p))];
  let purge = purgeAfterMs(deletedAtMs);
  let hold = false;
  for (const e of existing) {
    for (const p of entryPaths(e)) {
      // Paths still under the live prefix were moved by this run.
      if (!p.startsWith('id_documents/') && !paths.includes(p)) paths.push(p);
    }
    if (e.purgeAfterMs !== null && Number.isFinite(e.purgeAfterMs)) {
      purge = Math.max(purge, e.purgeAfterMs);
    }
    if (e.legalHold === true) hold = true;
  }
  return { storagePaths: paths, purgeAfterMs: purge, legalHold: hold };
}

/** `id_documents/{uid}/x.jpg` → `retention/{uid}/x.jpg`. */
export function retentionPathFor(livePath: string, uid: string): string {
  const prefix = `id_documents/${uid}/`;
  const name = livePath.startsWith(prefix) ? livePath.slice(prefix.length) : livePath.split('/').pop() ?? livePath;
  return `retention/${uid}/${name}`;
}

/**
 * The value `profiles.isAgeVerified` must hold for an `ageVerification`
 * status. It is the ONE "ID verified" flag (badge source of truth): true only
 * for an APPROVED identity document. A ban does not change it — the client
 * hides the badge for inactive (banned/suspended) accounts instead, so an
 * unban does not require re-verification.
 */
export function idVerifiedFlagFor(ageVerification: unknown): boolean {
  if (!ageVerification || typeof ageVerification !== 'object') return false;
  return (ageVerification as Record<string, unknown>).status === 'verified';
}

/** Whether a stored flag differs from what the status implies. */
export function idVerifiedFlagNeedsRepair(profile: Record<string, unknown> | null | undefined): boolean {
  if (!profile) return false;
  const want = idVerifiedFlagFor(profile.ageVerification);
  return (profile.isAgeVerified === true) !== want;
}
