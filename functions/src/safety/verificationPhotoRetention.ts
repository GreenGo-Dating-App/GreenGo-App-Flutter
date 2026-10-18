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
 *   - scripts/delete-reviewed-id-photos.ts: one-off backfill (dry run default).
 *
 * Never deletes an image that may still be awaiting a review.
 */
import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import '../shared/firebaseAdmin';
import {
  BusinessState,
  DECIDED_GRACE_MS,
  GraceOpts,
  ORPHAN_GRACE_MS,
  PhotoClass,
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
}

function emptyResult(): UserResult {
  return { objects: 0, deleted: 0, failed: 0, pending: 0, decided: 0, orphan: 0, notDue: 0, cleared: 0, recordWritten: false };
}

export interface ProcessOpts extends GraceOpts {
  nowMs: number;
  dryRun?: boolean;
  /** The decision that triggered this run (admin_actions row / event time). */
  decisionHint?: { atMs: number; by?: string | null } | null;
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
  for (const o of objects) {
    const cls = classifyRegistrationPhoto(o, st);
    tally(r, cls);
    if (!isDue(cls, o, reviewedAtMs, opts.nowMs, opts)) {
      if (cls !== 'pending') r.notDue++;
      continue;
    }
    if (opts.dryRun) continue;
    if (await ports.deleteObject(o.name)) {
      deleted.add(o.name);
      r.deleted++;
    } else {
      r.failed++;
    }
  }
  if (opts.dryRun || !profile) return r; // no profile: account gone, nothing to update

  const existing = new Set(objects.map((o) => o.name).filter((n) => !deleted.has(n)));
  const reviewPending = status === 'pending';
  const clearPub = referencesToClear(refsPub, deleted, existing, reviewPending);
  const clearPriv = referencesToClear(refsPriv, deleted, existing, reviewPending);
  if (clearPub.length) await ports.mergeDoc(`profiles/${uid}`, {}, clearPub);
  const final = isFinalRegistrationStatus(status);
  const writeRecord = final && (deleted.size > 0 || clearPub.length > 0 || clearPriv.length > 0);
  if (clearPriv.length || writeRecord) {
    const rec = registrationReviewRecord({
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
    ?? toMillis(req?.reviewedAt) ?? toMillis(req?.decidedAt) ?? toMillis(req?.updatedAt);
  const st: BusinessState = { requestExists: !!req, status, decidedAtMs };

  const deleted = new Set<string>();
  for (const o of objects) {
    const cls = classifyBusinessDocument(o, st);
    tally(r, cls);
    if (!isDue(cls, o, decidedAtMs, opts.nowMs, opts)) {
      if (cls !== 'pending') r.notDue++;
      continue;
    }
    if (opts.dryRun) continue;
    if (await ports.deleteObject(o.name)) {
      deleted.add(o.name);
      r.deleted++;
    } else {
      r.failed++;
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
}

export function emptyStats(): SweepStats {
  return { users: 0, objects: 0, deleted: 0, failed: 0, pending: 0, decided: 0, orphan: 0, notDue: 0, cleared: 0, danglingCleared: 0, pages: 0 };
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
  opts: { nowMs: number; maxPages?: number; pageSize?: number; dryRun?: boolean; cursors?: Record<string, string | null> },
): Promise<{ stats: SweepStats; cursors: Record<string, string | null> }> {
  const stats = emptyStats();
  const cursors: Record<string, string | null> = { ...(opts.cursors ?? {}) };
  for (const prefix of SWEEP_PREFIXES) {
    cursors[prefix] = await sweepPrefix(ports, prefix, cursors[prefix] ?? null, {
      nowMs: opts.nowMs, dryRun: opts.dryRun, maxPages: opts.maxPages, pageSize: opts.pageSize,
      decidedGraceMs: DECIDED_GRACE_MS, orphanGraceMs: ORPHAN_GRACE_MS,
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
