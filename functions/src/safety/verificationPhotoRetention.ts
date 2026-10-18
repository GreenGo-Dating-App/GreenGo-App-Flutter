/**
 * Verification-photo retention - Storage/Firestore side. Policy and pure
 * decisions in verificationPhotoRetentionLogic.ts (Privacy Policy 8.3 / 8.4).
 *
 * After an admin decision the image is DELETED and its stored references are
 * cleared; only a minimal record is kept:
 *   registration photo  profiles_private/{uid}.verificationReview =
 *                         { verified, status, reviewedAt, reviewedBy, method, imageDeletedAt }
 *                       (profiles.verificationStatus / verificationReviewedAt /
 *                        verificationReviewedBy stay as they are: the panel
 *                        and the app read the decision from there)
 *   business owner ID   business_verification_requests/{uid}: ownerDocumentUrl
 *                       removed, ownerDocumentDeletedAt set; the business
 *                       registration details stay (Privacy Policy 8.4).
 *
 * Where it runs:
 *   - onAdminVerificationAction (admin_actions create, registrationIdVerified.ts)
 *     calls processRegistrationUser right after an approve / reject /
 *     resubmission request: every decision path (in-app admin tools, panel
 *     callables, panel direct writes) records one there;
 *   - onBusinessVerificationDecided: business request status leaves 'pending';
 *   - purgeReviewedVerificationPhotos (daily): retries failed deletes and
 *     catches decisions recorded without admin_actions (24 h grace), deletes
 *     orphans (7 days), clears dangling references. Paged, bounded, resumable.
 *     Privacy Policy 8.2(d): an image still PENDING review 7 days after its
 *     upload is deleted whatever the outcome; the submission becomes
 *       registration  profiles.verificationStatus 'needsResubmission' +
 *                     verificationRejectionReason 'reviewExpired' (leaves
 *                     the admin queue; onVerificationStatusChange pushes
 *                     srvVerificationReviewExpired), record status 'expired';
 *       business      request status 'expired' (+ expiredReason
 *                     'documentExpired'), in-app + push notification. A
 *                     request WITHOUT an owner document (optional) is
 *                     never expired.
 *   - scripts/delete-reviewed-id-photos.ts: one-off backfill (dry run default).
 */
import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import '../shared/firebaseAdmin';
import {
  BusinessState,
  DECIDED_GRACE_MS,
  GraceOpts,
  BUSINESS_EXPIRED_STATUS,
  ORPHAN_GRACE_MS,
  PENDING_REVIEW_MAX_MS,
  PhotoClass,
  REVIEW_EXPIRED_REASON,
  RegistrationState,
  StoredObject,
  businessPrefix,
  classifyBusinessDocument,
  classifyRegistrationPhoto,
  isDue,
  isFinalBusinessStatus,
  isFinalRegistrationStatus,
  latestFinalAction,
  ownerOfPath,
  pendingReviewExpired,
  referencesToClear,
  registrationPrefixes,
  registrationReviewRecord,
  storagePathOfRef,
} from './verificationPhotoRetentionLogic';

// ───────────────────────────────────────────────────────────── ports

export interface ListPage {
  objects: StoredObject[];
  /** True when the listing is exhausted. */
  done: boolean;
  /** Continuation within the same run (a matchGlob page can be short or empty). */
  pageToken?: string | null;
}

/** Everything the retention code touches; injectable for unit tests. */
export interface RetentionPorts {
  listPage(prefix: string, startOffset: string | null, max: number, matchGlob?: string, pageToken?: string | null): Promise<ListPage>;
  deleteObject(name: string): Promise<boolean>;
  readDoc(path: string): Promise<Record<string, any> | null>;
  /** Merge [patch] into [path] and delete [deleteFields] (top-level). */
  mergeDoc(path: string, patch: Record<string, unknown>, deleteFields?: string[]): Promise<void>;
  adminActions(uid: string): Promise<Array<{ actionType?: unknown; timestampMs: number; performedBy?: unknown }>>;
  /**
   * Transactionally: when [path].[field] is still 'pending', merge [patch]
   * (and delete [deleteFields]) and return true; otherwise change nothing.
   */
  updateIfPending(path: string, field: string, patch: Record<string, unknown>, deleteFields?: string[]): Promise<boolean>;
  /** Tell the business owner that the ID document expired (in-app + push). */
  notifyBusinessDocumentExpired(uid: string): Promise<void>;
  timestamp(ms: number): unknown;
  log(message: string): void;
}

export function toMillis(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  const t = v as { toMillis?: () => number; seconds?: number; _seconds?: number };
  if (typeof t.toMillis === 'function') return t.toMillis();
  if (typeof t.seconds === 'number') return t.seconds * 1000;
  if (typeof t._seconds === 'number') return t._seconds * 1000;
  return null;
}

export function adminPorts(
  fs: admin.firestore.Firestore = admin.firestore(),
  bucket: ReturnType<ReturnType<typeof admin.storage>['bucket']> = admin.storage().bucket(),
): RetentionPorts {
  return {
    async listPage(prefix, startOffset, max, matchGlob, pageToken) {
      const [files, next] = await bucket.getFiles({
        prefix,
        maxResults: max,
        autoPaginate: false,
        ...(startOffset ? { startOffset } : {}),
        ...(matchGlob ? { matchGlob } : {}),
        ...(pageToken ? { pageToken } : {}),
      } as any);
      const token = (next as { pageToken?: string } | null | undefined)?.pageToken ?? null;
      return {
        objects: files.map((f) => ({
          name: f.name,
          createdMs: Date.parse(String((f.metadata as any)?.timeCreated ?? '')),
        })),
        done: !token,
        pageToken: token,
      };
    },
    async deleteObject(name) {
      try {
        await bucket.file(name).delete({ ignoreNotFound: true });
        return true;
      } catch {
        return false;
      }
    },
    async readDoc(path) {
      const s = await fs.doc(path).get();
      return s.exists ? (s.data() ?? {}) : null;
    },
    async mergeDoc(path, patch, deleteFields = []) {
      const out: Record<string, unknown> = { ...patch };
      for (const f of deleteFields) out[f] = admin.firestore.FieldValue.delete();
      await fs.doc(path).set(out, { merge: true });
    },
    async adminActions(uid) {
      // Equality filter only (no composite index); a user has few actions.
      const snap = await fs.collection('admin_actions').where('targetUserId', '==', uid).limit(100).get();
      return snap.docs.map((d) => {
        const x = d.data();
        return { actionType: x.actionType, performedBy: x.performedBy, timestampMs: toMillis(x.timestamp) ?? NaN };
      });
    },
    async updateIfPending(path, field, patch, deleteFields = []) {
      const ref = fs.doc(path);
      return fs.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists || snap.get(field) !== 'pending') return false;
        const out: Record<string, unknown> = { ...patch };
        for (const f of deleteFields) out[f] = admin.firestore.FieldValue.delete();
        tx.update(ref, out);
        return true;
      });
    },
    async notifyBusinessDocumentExpired(uid) {
      try {
        // Lazy: keeps the notifications module out of the trigger cold start.
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const { emitNotification } = require('../notifications/notifyHelpers');
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const { lt } = require('../shared/i18n');
        await emitNotification({
          recipientId: uid,
          type: 'verification',
          title: lt('notifServerVerificationUpdate'),
          body: lt('srvBusinessDocumentExpired'),
          data: { type: 'business_verification_expired' },
        });
      } catch (e) {
        console.error('notifyBusinessDocumentExpired failed', (e as Error)?.message);
      }
    },
    timestamp: (ms) => admin.firestore.Timestamp.fromMillis(ms),
    log: (m) => console.log(m),
  };
}

async function listAll(ports: RetentionPorts, prefix: string): Promise<StoredObject[]> {
  const out: StoredObject[] = [];
  let token: string | null = null;
  for (let i = 0; i < 20; i++) {
    const page = await ports.listPage(prefix, null, 200, undefined, token);
    out.push(...page.objects);
    token = page.pageToken ?? null;
    if (page.done || !token) break;
  }
  return out;
}

// ───────────────────────────────────────────────────────────── per user

export interface UserResult {
  objects: number;
  deleted: number;
  failed: number;
  pending: number;
  decided: number;
  orphan: number;
  /** Decided/orphan images still inside their grace period. */
  notDue: number;
  cleared: number;
  recordWritten: boolean;
  /** Pending images deleted because the review took longer than 7 days. */
  expired: number;
  /** The submission was set to "expired, please resubmit". */
  expiredSubmission: boolean;
}

function emptyResult(): UserResult {
  return {
    objects: 0, deleted: 0, failed: 0, pending: 0, decided: 0, orphan: 0, notDue: 0, cleared: 0,
    recordWritten: false, expired: 0, expiredSubmission: false,
  };
}

export interface ProcessOpts extends GraceOpts {
  nowMs: number;
  dryRun?: boolean;
  /** The decision that triggered this run (admin_actions row / event time). */
  decisionHint?: { atMs: number; by?: string | null } | null;
  /**
   * Privacy Policy 8.2(d): delete PENDING images older than this (from the
   * upload) and ask the user to upload again. Sweep/backfill only; unset =
   * pending images are never touched.
   */
  expirePendingAfterMs?: number;
}

async function deleteAll(ports: RetentionPorts, names: string[], deleted: Set<string>, r: UserResult) {
  for (const n of names) {
    if (deleted.has(n)) continue;
    if (await ports.deleteObject(n)) {
      deleted.add(n);
      r.deleted++;
    } else {
      r.failed++;
    }
  }
}

function tally(r: UserResult, cls: PhotoClass) {
  if (cls === 'pending') r.pending++;
  else if (cls === 'decided') r.decided++;
  else r.orphan++;
}

/**
 * Registration photo of [uid]: deletes every image that is decided (or
 * orphaned) and due, clears references to deleted / missing images when no
 * review is pending, and records the minimal result. Idempotent.
 */
export async function processRegistrationUser(
  ports: RetentionPorts,
  uid: string,
  opts: ProcessOpts,
): Promise<UserResult> {
  const r = emptyResult();
  if (!uid || uid.includes('/')) return r;
  const [profile, priv] = await Promise.all([
    ports.readDoc(`profiles/${uid}`),
    ports.readDoc(`profiles_private/${uid}`),
  ]);
  const objects: StoredObject[] = [];
  for (const p of registrationPrefixes(uid)) objects.push(...(await listAll(ports, p)));
  r.objects = objects.length;

  const refsPriv: Record<string, unknown> = {
    verificationPhotoPath: priv?.verificationPhotoPath,
    verificationPhotoUrl: priv?.verificationPhotoUrl,
  };
  const refsPub: Record<string, unknown> = {
    verificationPhotoUrl: profile?.verificationPhotoUrl,
    verificationPhotoPath: profile?.verificationPhotoPath,
  };
  const anyRef = [...Object.values(refsPriv), ...Object.values(refsPub)].some((v) => typeof v === 'string' && v);
  if (objects.length === 0 && !anyRef) return r; // nothing stored: no reads of admin_actions

  const status = typeof profile?.verificationStatus === 'string' ? profile.verificationStatus : null;
  const actions = profile ? await ports.adminActions(uid) : [];
  const latest = latestFinalAction(actions);
  const times = [toMillis(profile?.verificationReviewedAt), latest?.atMs ?? null, opts.decisionHint?.atMs ?? null]
    .filter((t): t is number => typeof t === 'number' && Number.isFinite(t));
  const reviewedAtMs = times.length ? Math.max(...times) : null;
  const referencedPaths = [...Object.values(refsPriv), ...Object.values(refsPub)]
    .map(storagePathOfRef)
    .filter((p): p is string => !!p);
  const st: RegistrationState = { profileExists: !!profile, status, reviewedAtMs, referencedPaths };

  const deleted = new Set<string>();
  const pendingObjs: StoredObject[] = [];
  for (const o of objects) {
    const cls = classifyRegistrationPhoto(o, st);
    tally(r, cls);
    if (cls === 'pending') pendingObjs.push(o);
    if (!isDue(cls, o, reviewedAtMs, opts.nowMs, opts)) {
      if (cls !== 'pending') r.notDue++;
      continue;
    }
    if (opts.dryRun) continue;
    await deleteAll(ports, [o.name], deleted, r);
  }

  // Privacy Policy 8.2(d): a submission nobody reviewed within 7 days.
  const submittedMs = toMillis(profile?.verificationSubmittedAt);
  const expire = opts.expirePendingAfterMs !== undefined && status === 'pending' && pendingObjs.length > 0
    && pendingObjs.every((o) => pendingReviewExpired(o, opts.nowMs, opts.expirePendingAfterMs, submittedMs));
  let expiredNow = false;
  if (expire) {
    r.expired = pendingObjs.length;
    if (opts.dryRun) return r;
    // Status first, conditionally: an admin deciding at the same moment wins
    // (its own trigger then deletes the image).
    expiredNow = await ports.updateIfPending(`profiles/${uid}`, 'verificationStatus', {
      verificationStatus: 'needsResubmission',
      verificationRejectionReason: REVIEW_EXPIRED_REASON,
      verificationExpiredAt: ports.timestamp(opts.nowMs),
    });
    if (expiredNow) {
      r.expiredSubmission = true;
      await deleteAll(ports, pendingObjs.map((o) => o.name), deleted, r);
    } else {
      r.expired = 0;
    }
  }
  if (opts.dryRun || !profile) return r; // no profile: account gone, nothing to update

  const existing = new Set(objects.map((o) => o.name).filter((n) => !deleted.has(n)));
  const reviewPending = status === 'pending' && !expiredNow;
  const clearPub = referencesToClear(refsPub, deleted, existing, reviewPending);
  const clearPriv = referencesToClear(refsPriv, deleted, existing, reviewPending);
  if (clearPub.length) await ports.mergeDoc(`profiles/${uid}`, {}, clearPub);
  const final = isFinalRegistrationStatus(status) || expiredNow;
  const writeRecord = final && (deleted.size > 0 || clearPub.length > 0 || clearPriv.length > 0);
  if (clearPriv.length || writeRecord) {
    const rec = expiredNow ? {
      verified: false, status: 'expired', reviewedAtMs: null, reviewedBy: 'system',
      method: typeof profile.verificationMethod === 'string' && profile.verificationMethod !== 'phone'
        ? profile.verificationMethod : 'photo',
    } : registrationReviewRecord({
      status,
      reviewedAtMs,
      reviewedBy: (typeof profile.verificationReviewedBy === 'string' ? profile.verificationReviewedBy : null)
        ?? latest?.by ?? opts.decisionHint?.by ?? null,
      method: typeof profile.verificationMethod === 'string' ? profile.verificationMethod : null,
    });
    const patch: Record<string, unknown> = writeRecord ? {
      verificationReview: {
        verified: rec.verified,
        status: rec.status,
        reviewedAt: rec.reviewedAtMs !== null ? ports.timestamp(rec.reviewedAtMs) : null,
        reviewedBy: rec.reviewedBy,
        method: rec.method,
        imageDeletedAt: ports.timestamp(opts.nowMs),
      },
    } : {};
    await ports.mergeDoc(`profiles_private/${uid}`, patch, clearPriv);
    r.recordWritten = writeRecord;
  }
  r.cleared = clearPub.length + clearPriv.length;
  return r;
}

/** Business owner ID document of [uid] (business_verification_requests/{uid}). */
export async function processBusinessUser(
  ports: RetentionPorts,
  uid: string,
  opts: ProcessOpts,
): Promise<UserResult> {
  const r = emptyResult();
  if (!uid || uid.includes('/')) return r;
  const req = await ports.readDoc(`business_verification_requests/${uid}`);
  const objects = await listAll(ports, businessPrefix(uid));
  r.objects = objects.length;
  const refs: Record<string, unknown> = { ownerDocumentUrl: req?.ownerDocumentUrl };
  if (objects.length === 0 && !(typeof refs.ownerDocumentUrl === 'string' && refs.ownerDocumentUrl)) return r;

  const status = typeof req?.status === 'string' ? req.status : null;
  const decidedAtMs = opts.decisionHint?.atMs
    ?? toMillis(req?.reviewedAt) ?? toMillis(req?.decidedAt) ?? toMillis(req?.expiredAt) ?? toMillis(req?.updatedAt);
  const st: BusinessState = { requestExists: !!req, status, decidedAtMs };

  const deleted = new Set<string>();
  const pendingObjs: StoredObject[] = [];
  for (const o of objects) {
    const cls = classifyBusinessDocument(o, st);
    tally(r, cls);
    if (cls === 'pending') pendingObjs.push(o);
    if (!isDue(cls, o, decidedAtMs, opts.nowMs, opts)) {
      if (cls !== 'pending') r.notDue++;
      continue;
    }
    if (opts.dryRun) continue;
    await deleteAll(ports, [o.name], deleted, r);
  }

  // Privacy Policy 8.2(d) via 8.4: the owner's ID document waited 7 days.
  // The document is optional (phone-only verification): a pending request
  // without one is never expired; a stray upload it does not reference is
  // just deleted.
  if (opts.expirePendingAfterMs !== undefined && status === 'pending' && pendingObjs.length > 0) {
    const submittedMs = toMillis(req?.submittedAt);
    const old = pendingObjs.filter((o) => pendingReviewExpired(o, opts.nowMs, opts.expirePendingAfterMs, submittedMs));
    const referenced = typeof refs.ownerDocumentUrl === 'string' && refs.ownerDocumentUrl.length > 0;
    const refPath = referenced ? storagePathOfRef(refs.ownerDocumentUrl) : null;
    const refObj = refPath !== null ? pendingObjs.find((o) => o.name === refPath) : undefined;
    // The referenced document expired (unknown path: every pending object expired).
    const refExpired = referenced && (refObj
      ? old.includes(refObj)
      : old.length === pendingObjs.length);
    if (old.length) {
      r.expired = old.length;
      if (opts.dryRun) return r;
      if (refExpired) {
        const done = await ports.updateIfPending(`business_verification_requests/${uid}`, 'status', {
          status: BUSINESS_EXPIRED_STATUS,
          expiredReason: 'documentExpired',
          expiredAt: ports.timestamp(opts.nowMs),
          ownerDocumentDeletedAt: ports.timestamp(opts.nowMs),
        }, ['ownerDocumentUrl']);
        if (!done) {
          r.expired = 0;
          return r;
        }
        r.expiredSubmission = true;
        r.cleared++;
        r.recordWritten = true;
        await deleteAll(ports, pendingObjs.map((o) => o.name), deleted, r);
        await ports.notifyBusinessDocumentExpired(uid);
        return r;
      }
      // Uploads the request does not reference: not under review.
      await deleteAll(ports, old.filter((o) => o !== refObj).map((o) => o.name), deleted, r);
    }
  }
  if (opts.dryRun || !req) return r;
  const existing = new Set(objects.map((o) => o.name).filter((n) => !deleted.has(n)));
  const clear = referencesToClear(refs, deleted, existing, !isFinalBusinessStatus(status));
  if (clear.length || (deleted.size > 0 && isFinalBusinessStatus(status))) {
    await ports.mergeDoc(`business_verification_requests/${uid}`,
      { ownerDocumentDeletedAt: ports.timestamp(opts.nowMs) }, clear);
    r.recordWritten = true;
  }
  r.cleared = clear.length;
  return r;
}

// ───────────────────────────────────────────────────────────── sweep

export const SWEEP_PREFIXES = ['verifications/', 'business_verification/'] as const;
const SWEEP_PAGE = 500;
const SWEEP_MAX_PAGES = 20;
const SWEEP_CURSOR_DOC = 'maintenance_cursors/verificationPhotoSweep';

export interface SweepStats {
  users: number;
  objects: number;
  deleted: number;
  failed: number;
  pending: number;
  decided: number;
  orphan: number;
  notDue: number;
  cleared: number;
  danglingCleared: number;
  pages: number;
  /** Pending images deleted after 7 days without a review (8.2(d)). */
  expired: number;
  /** Submissions set to "expired, please resubmit". */
  expiredSubmissions: number;
}

function addTo(s: SweepStats, r: UserResult) {
  s.objects += r.objects;
  s.deleted += r.deleted;
  s.failed += r.failed;
  s.pending += r.pending;
  s.decided += r.decided;
  s.orphan += r.orphan;
  s.notDue += r.notDue;
  s.cleared += r.cleared;
  s.expired += r.expired;
  if (r.expiredSubmission) s.expiredSubmissions++;
}

export function emptyStats(): SweepStats {
  return {
    users: 0, objects: 0, deleted: 0, failed: 0, pending: 0, decided: 0, orphan: 0, notDue: 0, cleared: 0,
    danglingCleared: 0, pages: 0, expired: 0, expiredSubmissions: 0,
  };
}

/**
 * One pass over [prefix] (optionally a [matchGlob] for the legacy
 * `profiles/{uid}/verifications/` objects), from [startOffset], at most
 * [maxPages] pages. Each owner is processed once per page (idempotent, so a
 * user split across pages is simply processed twice). Returns the cursor to
 * resume from, or null when the listing was exhausted.
 */
export async function sweepPrefix(
  ports: RetentionPorts,
  prefix: string,
  startOffset: string | null,
  opts: ProcessOpts & { maxPages?: number; pageSize?: number; matchGlob?: string },
  stats: SweepStats,
): Promise<string | null> {
  const pageSize = opts.pageSize ?? SWEEP_PAGE;
  let offset = startOffset;
  let token: string | null = null;
  for (let i = 0; i < (opts.maxPages ?? SWEEP_MAX_PAGES); i++) {
    const page = await ports.listPage(prefix, token ? null : offset, pageSize, opts.matchGlob, token);
    stats.pages++;
    const owners = new Map<string, 'registration' | 'business'>();
    for (const o of page.objects) {
      if (o.name === offset) continue;
      const own = ownerOfPath(o.name);
      if (own) owners.set(`${own.kind}:${own.uid}`, own.kind);
    }
    for (const [key, kind] of owners) {
      const uid = key.slice(kind.length + 1);
      try {
        const r = kind === 'registration'
          ? await processRegistrationUser(ports, uid, opts)
          : await processBusinessUser(ports, uid, opts);
        stats.users++;
        addTo(stats, r);
      } catch {
        stats.failed++; // retried on the next run
      }
    }
    if (page.done) return null;
    token = page.pageToken ?? null;
    if (page.objects.length) offset = page.objects[page.objects.length - 1].name;
    else if (!token) return null;
  }
  return offset;
}

/**
 * The daily sweep. Counts only in the log (no uid, no path). Cursors are
 * kept per prefix so a large backlog is worked through over several days;
 * an exhausted listing restarts from the beginning next time.
 */
export async function runVerificationPhotoSweep(
  ports: RetentionPorts,
  opts: {
    nowMs: number; maxPages?: number; pageSize?: number; dryRun?: boolean; cursors?: Record<string, string | null>;
    /** Default PENDING_REVIEW_MAX_MS (Privacy Policy 8.2(d)); null disables the expiry. */
    expirePendingAfterMs?: number | null;
  },
): Promise<{ stats: SweepStats; cursors: Record<string, string | null> }> {
  const stats = emptyStats();
  const cursors: Record<string, string | null> = { ...(opts.cursors ?? {}) };
  for (const prefix of SWEEP_PREFIXES) {
    cursors[prefix] = await sweepPrefix(ports, prefix, cursors[prefix] ?? null, {
      nowMs: opts.nowMs, dryRun: opts.dryRun, maxPages: opts.maxPages, pageSize: opts.pageSize,
      decidedGraceMs: DECIDED_GRACE_MS, orphanGraceMs: ORPHAN_GRACE_MS,
      expirePendingAfterMs: opts.expirePendingAfterMs === null ? undefined
        : (opts.expirePendingAfterMs ?? PENDING_REVIEW_MAX_MS),
    }, stats);
  }
  return { stats, cursors };
}

/**
 * Dangling references: profiles_private docs that still carry a photo path /
 * URL although no image is pending (e.g. a stale app write after the
 * deletion). Paged by document id; processRegistrationUser does the rest.
 */
export async function sweepDanglingReferences(
  fs: admin.firestore.Firestore,
  ports: RetentionPorts,
  opts: ProcessOpts & { maxPages?: number; pageSize?: number },
  stats: SweepStats,
): Promise<void> {
  for (const field of ['verificationPhotoPath', 'verificationPhotoUrl']) {
    let cursor: string | null = null;
    for (let i = 0; i < (opts.maxPages ?? 10); i++) {
      let q = fs.collection('profiles_private').where(field, '>', '').orderBy(field).limit(opts.pageSize ?? 300);
      if (cursor !== null) q = q.startAfter(cursor);
      const snap = await q.select(field).get();
      for (const d of snap.docs) {
        try {
          const r = await processRegistrationUser(ports, d.id, opts);
          stats.users++;
          stats.danglingCleared += r.cleared;
          addTo(stats, r);
        } catch {
          stats.failed++;
        }
      }
      if (snap.size < (opts.pageSize ?? 300)) break;
      cursor = String(snap.docs[snap.docs.length - 1].get(field));
    }
  }
}

export const purgeReviewedVerificationPhotos = onSchedule(
  { schedule: '45 3 * * *', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const fs = admin.firestore();
    const ports = adminPorts(fs);
    const ref = fs.doc(SWEEP_CURSOR_DOC);
    const saved = (await ref.get()).data()?.cursors ?? {};
    const nowMs = Date.now();
    const { stats, cursors } = await runVerificationPhotoSweep(ports, { nowMs, cursors: saved });
    try {
      await sweepDanglingReferences(fs, ports, { nowMs, decidedGraceMs: DECIDED_GRACE_MS, orphanGraceMs: ORPHAN_GRACE_MS }, stats);
    } catch (e) {
      console.error('purgeReviewedVerificationPhotos: dangling-reference pass failed', (e as Error)?.message);
    }
    await ref.set({ cursors, lastRunAt: admin.firestore.Timestamp.now(), lastStats: stats });
    console.log(`purgeReviewedVerificationPhotos: ${JSON.stringify(stats)}`);
  },
);

// ───────────────────────────────────────────────────────────── triggers

/** Tolerated difference between the Firestore / Storage and function clocks. */
const CLOCK_SKEW_MS = 60_000;

/** Called by onAdminVerificationAction for a final registration decision. */
export async function deleteRegistrationPhotoOnDecision(
  uid: string,
  decision: { atMs: number | null; by?: string | null },
  ports: RetentionPorts = adminPorts(),
): Promise<UserResult | null> {
  try {
    const nowMs = Date.now();
    const r = await processRegistrationUser(ports, uid, {
      nowMs,
      decidedGraceMs: -CLOCK_SKEW_MS,
      decisionHint: { atMs: decision.atMs ?? nowMs, by: decision.by ?? null },
    });
    if (r.failed > 0) console.error(`deleteRegistrationPhotoOnDecision: ${r.failed} delete(s) failed; the daily sweep retries`);
    return r;
  } catch (e) {
    console.error('deleteRegistrationPhotoOnDecision failed; the daily sweep retries', (e as Error)?.message);
    return null;
  }
}

/** Pure: whether a business request write is a (new) decision to act on. */
export function businessDecisionToProcess(
  before: Record<string, any> | null | undefined,
  after: Record<string, any> | null | undefined,
): boolean {
  if (!after || !isFinalBusinessStatus(after.status)) return false;
  if (!before || before.status !== after.status) return true;
  // Same decided status: only while a document reference is still there
  // (our own clearing write lands here and stops the loop).
  return typeof after.ownerDocumentUrl === 'string' && after.ownerDocumentUrl.length > 0;
}

export const onBusinessVerificationDecided = onDocumentWritten(
  { document: 'business_verification_requests/{uid}', memory: '512MiB', timeoutSeconds: 60 },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!businessDecisionToProcess(before, after)) return;
    const uid = String(event.params.uid);
    try {
      const nowMs = Date.now();
      const at = Date.parse(String(event.time ?? '')) || nowMs;
      const r = await processBusinessUser(adminPorts(), uid, { nowMs, decidedGraceMs: -CLOCK_SKEW_MS, decisionHint: { atMs: at } });
      if (r.failed > 0) console.error(`onBusinessVerificationDecided: ${r.failed} delete(s) failed; the daily sweep retries`);
    } catch (e) {
      console.error('onBusinessVerificationDecided failed; the daily sweep retries', (e as Error)?.message);
    }
  },
);
