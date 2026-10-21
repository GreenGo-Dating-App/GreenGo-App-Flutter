/**
 * "Ask for a review" on a held image (My pictures).
 *
 * REUSES THE EXISTING MODERATION PIPELINE
 * ---------------------------------------
 *  - Hold with an appealable DSA decision (SafeSearch: sexual_content /
 *    violence -> moderateUploadedImage created a statement of reasons): the
 *    request IS the art. 20 appeal (submitAppealForDecision). It lands in
 *    moderation_queue as the usual `appeal__{decisionId}` item and is decided
 *    with resolveAppeal (overturn restores the file; a different person than
 *    the original decider - Terms 18.4 b).
 *  - Hold without a decision (no face on a main photo, ...): a new
 *    moderation_queue item `itemType: 'imageReview'`, decided in
 *    takeModerationAction with `approve` (restore + notify) or
 *    `removeContent` (keep the hold + statement of reasons, DSA flow).
 *
 * Contract for the admin panel: docs/safety/image-review-requests.md.
 *
 * SLA: we tell the user "within 24-48 hours". Every request carries
 * `slaDueAt` (+48 h) and `slaAlertAt` (+24 h). imageReviewSlaSweep (hourly)
 * picks items whose slaAlertAt passed - one single-field range query, no
 * composite index - alerts the admins once (admin_alerts + email) and clears
 * the field, so every request is alerted at most once.
 *
 * RATE LIMIT: one open request per image, and REVIEW_DAILY_LIMIT requests per
 * user per rolling 24 h window (image_review_limits/{uid}, server-only).
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import '../shared/firebaseAdmin';
import { logError, logInfo } from '../shared/utils';
import { lt, notifTextFields } from '../shared/i18n';
import { createModerationDecision, submitAppealForDecision } from './moderationDecisions';
import { restoreQuarantined } from './moderationEffects';
import { libraryRef, MEDIA_LIBRARY, LIBRARY_ITEMS, recordLibraryHoldFinal } from './mediaLibrary';
import { sendSecurityAlert } from '../security/securityEventAlerts';
import { SAFETY_ALERT_EMAIL } from './takedowns/safetyCases';

export const REVIEW_DAILY_LIMIT = 5;
export const REVIEW_WINDOW_MS = 24 * 3600_000;
export const REVIEW_ALERT_AFTER_MS = 24 * 3600_000;
export const REVIEW_SLA_MS = 48 * 3600_000;
export const REVIEW_NOTE_MAX = 500;
export const IMAGE_REVIEW_LIMITS = 'image_review_limits';
/** Appeals need 10+ characters; used when the user leaves no (or a short) note. */
export const DEFAULT_APPEAL_TEXT = 'The uploader asked for a human review of this picture from My pictures.';

const FINAL = new Set(['resolved', 'completed', 'dismissed', 'closed', 'actioned']);

/** Overridable in unit tests; production uses the defaults. */
export const imageReviewDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  now: (): number => Date.now(),
  submitAppeal: (uid: string, data: { decisionId: string; appealReason: string }) =>
    submitAppealForDecision(uid, data, Date.now(), 'app'),
  createDecision: createModerationDecision,
  restore: restoreQuarantined,
  sendAlert: (subject: string, lines: string[]) => sendSecurityAlert(subject, lines, [SAFETY_ALERT_EMAIL]),
  notify: async (uid: string, id: string, data: Record<string, string>): Promise<void> => {
    try {
      await admin.firestore().collection('notifications').doc(id).create({
        userId: uid,
        type: 'system',
        ...notifTextFields(lt('srvImageReviewApprovedTitle'), lt('srvImageReviewApprovedBody')),
        data,
        read: false,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e: any) {
      if (e?.code === 6 || /already exists/i.test(String(e?.message))) return;
      throw e;
    }
  },
};

const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const del = () => admin.firestore.FieldValue.delete();
const fdb = () => imageReviewDeps.db();

/** moderation_queue id of a review request: one per object generation. Pure. */
export function imageReviewQueueId(itemId: string, generation: unknown): string {
  return `imgreview__${itemId}__${String(generation ?? '0')}`.slice(0, 1400);
}

/** Validated user note (optional, trimmed, <= REVIEW_NOTE_MAX). Pure. */
export function parseReviewNote(v: unknown): string {
  if (v === undefined || v === null) return '';
  if (typeof v !== 'string') throw new HttpsError('invalid-argument', 'invalid_note', { code: 'invalid_note' });
  const s = v.trim();
  if (s.length > REVIEW_NOTE_MAX) throw new HttpsError('invalid-argument', 'note_too_long', { code: 'note_too_long' });
  return s;
}

/** Rolling-window counter after one more request, or null when over the limit. Pure. */
export function nextLimitState(
  cur: { windowStart?: number | null; count?: number | null } | null | undefined,
  nowMs: number,
  limit = REVIEW_DAILY_LIMIT,
  windowMs = REVIEW_WINDOW_MS,
): { windowStart: number; count: number } | null {
  const start = typeof cur?.windowStart === 'number' ? cur.windowStart : 0;
  if (!start || nowMs - start >= windowMs) return { windowStart: nowMs, count: 1 };
  const count = typeof cur?.count === 'number' ? cur.count : 0;
  if (count >= limit) return null;
  return { windowStart: start, count: count + 1 };
}

function fail(code: string, kind: 'failed-precondition' | 'not-found' | 'already-exists' | 'resource-exhausted' | 'invalid-argument' | 'unauthenticated'): never {
  throw new HttpsError(kind, code, { code });
}

export interface ReviewRequestResult {
  status: 'pending';
  kind: 'imageReview' | 'appeal';
  queueId: string;
  dueAtMs: number;
}

/**
 * requestImageReview({ itemId, note? }) for the signed-in owner of
 * media_library/{uid}/items/{itemId}.
 */
export async function handleRequestImageReview(uid: string | undefined, data: unknown): Promise<ReviewRequestResult> {
  if (!uid) fail('unauthenticated', 'unauthenticated');
  const d = (data || {}) as Record<string, unknown>;
  const itemId = typeof d.itemId === 'string' ? d.itemId.trim() : '';
  if (!itemId || itemId.length > 1500 || itemId.includes('/')) fail('invalid_item', 'invalid-argument');
  const note = parseReviewNote(d.note);

  const nowMs = imageReviewDeps.now();
  const itemRef = libraryRef(uid!, itemId);
  const limitRef = fdb().collection(IMAGE_REVIEW_LIMITS).doc(uid!);
  const dueAtMs = nowMs + REVIEW_SLA_MS;

  // 1. Claim: item is held + reviewable + nothing open; count the request.
  const claim = await fdb().runTransaction(async (tx) => {
    const [itemSnap, limSnap] = await Promise.all([tx.get(itemRef), tx.get(limitRef)]);
    const item = itemSnap.data();
    if (!itemSnap.exists || !item) fail('not_found', 'not-found');
    // 'rejected' + reviewable: a person confirmed a hold that carries an
    // appealable decision - the request is then the DSA appeal.
    if ((item.status !== 'held' && item.status !== 'rejected') || item.reviewable !== true) {
      fail('not_reviewable', 'failed-precondition');
    }
    if (item.review && item.review.status === 'pending') fail('already_requested', 'already-exists');
    const lim = limSnap.data();
    const next = nextLimitState(
      { windowStart: lim?.windowStart?.toMillis?.() ?? null, count: lim?.count ?? 0 },
      nowMs,
    );
    if (!next) fail('rate_limited', 'resource-exhausted');
    const kind: 'appeal' | 'imageReview' = typeof item.decisionId === 'string' && item.decisionId ? 'appeal' : 'imageReview';
    const queueId = kind === 'appeal' ? `appeal__${item.decisionId}` : imageReviewQueueId(itemId, item.generation);
    tx.set(limitRef, { windowStart: ts(next!.windowStart), count: next!.count, updatedAt: ts(nowMs) });
    tx.set(itemRef, {
      review: { status: 'pending', kind, queueId, note: note || null, requestedAt: ts(nowMs), dueAt: ts(dueAtMs) },
      updatedAt: ts(nowMs),
    }, { merge: true });
    return { item, kind, queueId };
  });

  const { item, kind, queueId } = claim;
  const sla = { slaDueAt: ts(dueAtMs), slaAlertAt: ts(nowMs + REVIEW_ALERT_AFTER_MS), slaHours: 48 };
  try {
    if (kind === 'appeal') {
      try {
        await imageReviewDeps.submitAppeal(uid!, {
          decisionId: item.decisionId,
          appealReason: note.length >= 10 ? note : (note ? `${note} - ${DEFAULT_APPEAL_TEXT}` : DEFAULT_APPEAL_TEXT),
        });
      } catch (e: any) {
        // Already appealed from the decision screen: that appeal is the review.
        if (!(e?.code === 'already-exists' || /already-exists|already appealed/i.test(String(e?.code ?? e?.message)))) throw e;
      }
      await fdb().collection('moderation_queue').doc(queueId).set({
        ...sla,
        imageReview: { uid, itemId, objectPath: item.path ?? null, requestedAt: ts(nowMs) },
      }, { merge: true });
    } else {
      const fileName = String(item.path || '').split('/').pop() || itemId;
      await fdb().collection('moderation_queue').doc(queueId).create({
        queueId,
        itemType: 'imageReview',
        itemId: item.path ?? null,
        userId: uid,
        status: 'pending',
        priority: 'medium',
        priorityLevel: 'P1',
        category: 'imageReview',
        reasonCode: item.reasonCode ?? 'other',
        reasons: Array.isArray(item.reasons) ? item.reasons : [],
        userNote: note || null,
        objectPath: item.path ?? null,
        quarantinePath: item.quarantinePath ?? `quarantine/${item.path}`,
        libraryItemPath: `${MEDIA_LIBRARY}/${uid}/${LIBRARY_ITEMS}/${itemId}`,
        relatedQueueId: item.queueId ?? null,
        usage: item.usage ?? null,
        contentRef: { type: 'photo', id: fileName, path: item.path ?? null },
        reporterId: 'system',
        assignedTo: null,
        relatedReportIds: [],
        metadata: { reasons: item.reasons ?? [], usage: item.usage ?? null, relatedQueueId: item.queueId ?? null },
        addedAt: ts(nowMs),
        createdAt: ts(nowMs),
        ...sla,
      });
    }
  } catch (e) {
    // Release the claim (the rate-limit count stays: no free retries on abuse).
    await itemRef.set({ review: null }, { merge: true }).catch(() => undefined);
    if (e instanceof HttpsError) throw e;
    logError(`[imageReview] request ${queueId} failed`, e);
    fail('request_failed', 'failed-precondition');
  }
  logInfo(`[imageReview] ${uid} asked for a review of ${item.path} (${kind} ${queueId})`);
  return { status: 'pending', kind, queueId, dueAtMs };
}

export interface ResolveImageReviewResult {
  queueId: string;
  outcome: 'approved' | 'rejected';
  restored?: 'restored' | 'missing';
  decisionCreated?: boolean;
}

/**
 * takeModerationAction on an `imageReview` item: `approve` restores the
 * image and tells the user; `removeContent` keeps the hold and sends the
 * statement of reasons (decision id = queue id, appealable).
 */
export async function resolveImageReview(
  q: Record<string, any>,
  action: string,
  moderatorId: string,
  sor: { reasonCode: string | null; explanation: string | null } | null,
): Promise<ResolveImageReviewResult> {
  const queueId: string = q.queueId;
  if (action !== 'approve' && action !== 'removeContent') {
    throw new HttpsError('failed-precondition', 'imageReview items: approve = publish the image, removeContent = keep it hidden');
  }
  const uid: string = q.userId;
  const objectPath: string = q.objectPath;
  const quarantinePath: string = q.quarantinePath || `quarantine/${objectPath}`;
  if (!uid || !objectPath) throw new HttpsError('failed-precondition', 'imageReview item has no user or object');
  const nowMs = imageReviewDeps.now();
  const itemId = objectPath.replace(/\//g, '~');
  const queueRef = fdb().collection('moderation_queue').doc(queueId);
  const closeRelated = async (act: string) => {
    if (typeof q.relatedQueueId !== 'string' || !q.relatedQueueId) return;
    const rel = fdb().collection('moderation_queue').doc(q.relatedQueueId);
    const cur = (await rel.get()).data();
    if (cur && !FINAL.has(cur.status)) {
      await rel.set({ status: 'resolved', action: act, resolvedAt: ts(nowMs), resolvedBy: moderatorId, resolvedVia: queueId }, { merge: true });
    }
  };

  if (action === 'approve') {
    // restoreQuarantined re-approves the library item (status, url) and marks
    // the pending request approved (mediaLibrary.recordLibraryRestored).
    const restored = await imageReviewDeps.restore(objectPath, quarantinePath);
    if (restored === 'missing') {
      throw new HttpsError('failed-precondition', 'The held file no longer exists (removed or expired); use removeContent');
    }
    await libraryRef(uid, itemId).set({
      review: { status: 'approved', decidedAt: ts(nowMs), kind: 'imageReview', queueId },
    }, { merge: true });
    await queueRef.set({
      status: 'resolved', action: 'approve', resolvedAt: ts(nowMs), resolvedBy: moderatorId,
      moderatorNotes: sor?.explanation ?? null, slaAlertAt: del(),
    }, { merge: true });
    await closeRelated('approve');
    await imageReviewDeps.notify(uid, `imgreview_ok__${queueId}`.slice(0, 1400), {
      action: 'my_pictures', itemId, queueId,
    });
    return { queueId, outcome: 'approved', restored };
  }

  const fileName = objectPath.split('/').pop() || objectPath;
  const decisionCreated = await imageReviewDeps.createDecision({
    decisionId: queueId,
    queueId,
    userId: uid,
    action: 'removeContent',
    reasonCode: sor?.reasonCode ?? q.reasonCode ?? 'other',
    explanation: sor?.explanation
      ?? 'A moderator reviewed this picture and it stays hidden: it does not meet our rules for where it was uploaded.',
    decidedBy: moderatorId,
    contentRef: { type: 'photo', id: fileName, excerpt: null },
    automated: { detection: 'vision', decision: false },
    effects: [{ type: 'quarantine', objectPath, quarantinePath }],
  });
  await recordLibraryHoldFinal({ uid, objectPath, decisionId: queueId, reviewable: false });
  await queueRef.set({
    status: 'resolved', action: 'removeContent', resolvedAt: ts(nowMs), resolvedBy: moderatorId,
    moderatorNotes: sor?.explanation ?? null, slaAlertAt: del(),
    ...(sor?.reasonCode ? { statementOfReasons: { ...sor, action: 'removeContent', decidedBy: moderatorId, decidedAt: ts(nowMs), automated: false } } : {}),
  }, { merge: true });
  await closeRelated('removeContent');
  return { queueId, outcome: 'rejected', decisionCreated };
}

/**
 * One SLA pass: every queue item whose slaAlertAt passed. Open ones are
 * reported (once); resolved ones are just cleaned up.
 */
export async function runImageReviewSlaSweep(nowMs = imageReviewDeps.now()): Promise<{ overdue: string[]; cleared: number }> {
  const snap = await fdb().collection('moderation_queue')
    .where('slaAlertAt', '<=', ts(nowMs))
    .limit(200)
    .get();
  const overdue: string[] = [];
  let cleared = 0;
  for (const d of snap.docs) {
    const q = d.data() || {};
    const open = !FINAL.has(String(q.status));
    if (open) overdue.push(d.id);
    await d.ref.update({ slaAlertAt: del(), ...(open ? { slaAlertedAt: ts(nowMs) } : {}) });
    cleared++;
  }
  if (overdue.length) {
    const hour = new Date(nowMs).toISOString().slice(0, 13);
    try {
      await fdb().collection('admin_alerts').doc(`image_review_sla_${hour}`).set({
        type: 'image_review_sla',
        count: admin.firestore.FieldValue.increment(overdue.length),
        queueIds: admin.firestore.FieldValue.arrayUnion(...overdue.slice(0, 50)),
        status: 'open',
        createdAt: ts(nowMs),
      }, { merge: true });
    } catch (e) {
      logError('[imageReview] admin alert write failed', e);
    }
    try {
      await imageReviewDeps.sendAlert(`image review requests waiting > 24 h: ${overdue.length}`, [
        `${overdue.length} "Ask for a review" request(s) on held pictures are older than 24 hours.`,
        'Users were promised a decision within 24-48 hours.',
        'Open the admin panel moderation queue (itemType imageReview, or appeal items with imageReview set).',
      ]);
    } catch (e) {
      logError('[imageReview] SLA email failed', e);
    }
  }
  return { overdue, cleared };
}

// ─────────────────────────────────────────────────────────── endpoints

export const requestImageReview = onCall(
  { memory: '512MiB' },
  async (request) => handleRequestImageReview(request.auth?.uid, request.data),
);

export const imageReviewSlaSweep = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 300 },
  async () => {
    const r = await runImageReviewSlaSweep();
    if (r.overdue.length) console.log(`imageReviewSlaSweep: ${r.overdue.length} overdue`, r.overdue.slice(0, 20));
  },
);
