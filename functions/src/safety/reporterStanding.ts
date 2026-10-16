/**
 * Terms 18.6 (second bullet) / DSA art. 23: "If someone often sends clearly
 * unfounded reports, we stop processing their reports for a period after a
 * warning."
 *
 * Counting: when a report-pipeline queue item is closed as no-violation
 * (dismiss / approve), the reporter's last 30 days of reports are counted
 * (moderation_queue reporterId + createdAt, bounded read). "Often" =
 * MIN_DISMISSED or more dismissed AND at least MIN_RATIO of the decided ones.
 *
 *   1. First time over the threshold (or the last warning is older than
 *      WARNING_VALID_DAYS): an automatic WARNING with a statement of reasons
 *      and appeal (decision action 'reporterWarning'). Reports keep being
 *      processed.
 *   2. Still over the threshold with AFTER_WARNING_MIN more dismissed reports
 *      filed after the warning: a 'reporterAbuse' item goes to the moderation
 *      queue. A moderator assesses the case (art. 23(3): case by case) and
 *      either suspends report processing (takeModerationAction
 *      'suspendReporting', default SUSPEND_DAYS) or dismisses it.
 *
 * While suspended (reporter_standing/{uid}.suspendedUntil in the future) new
 * reports are STORED with status 'reporter_suspended' (not in the pending
 * queue, no auto-actions). Child-safety reports (P0) are always processed.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { createModerationDecision } from './moderationDecisions';
import { DecisionEffect, REPORTER_STANDING } from './moderationEffects';

const db = () => admin.firestore();
const TS = admin.firestore.Timestamp;

export const ABUSE_WINDOW_DAYS = 30;
export const MIN_DISMISSED = 10;
export const MIN_RATIO = 0.8;
export const WARNING_VALID_DAYS = 180;
export const AFTER_WARNING_MIN = 5;
export const SUSPEND_DAYS = 30;
const READ_LIMIT = 300;

const FINAL = new Set(['resolved', 'completed', 'dismissed', 'closed', 'actioned']);
const NO_VIOLATION = new Set(['approve', 'dismiss', 'dismissed', 'no_action', 'noAction', 'noViolation', 'no_violation']);

export interface ReporterStats {
  dismissed: number;
  actioned: number;
  /** Dismissed reports filed after the last warning. */
  dismissedSinceWarning: number;
}

export interface Standing {
  warnedAtMs: number | null;
  suspendedUntilMs: number | null;
  reviewPending: boolean;
}

export type ReporterVerdict = 'none' | 'warn' | 'review';

/** Pure. */
export function evaluateReporter(s: ReporterStats, st: Standing, nowMs: number): ReporterVerdict {
  if (st.suspendedUntilMs && st.suspendedUntilMs > nowMs) return 'none';
  const decided = s.dismissed + s.actioned;
  const often = s.dismissed >= MIN_DISMISSED && decided > 0 && s.dismissed / decided >= MIN_RATIO;
  if (!often) return 'none';
  const warningValid = st.warnedAtMs !== null && nowMs - st.warnedAtMs <= WARNING_VALID_DAYS * 86_400_000;
  if (!warningValid) return 'warn';
  if (st.reviewPending) return 'none';
  return s.dismissedSinceWarning >= AFTER_WARNING_MIN ? 'review' : 'none';
}

/** Pure: no-violation vs action, as the reporter feedback classifies it. */
export function isDismissed(q: Record<string, any>): boolean | null {
  if (!FINAL.has(q.status)) return null;
  if (q.status === 'dismissed') return true;
  const a = q.action ?? q.resolvedAction ?? q.actionTaken;
  return !(typeof a === 'string' && a && !NO_VIOLATION.has(a));
}

const ms = (v: unknown): number | null =>
  v instanceof TS ? v.toMillis() : (v && typeof (v as any).toMillis === 'function' ? (v as any).toMillis() : null);

export async function reporterStats(uid: string, warnedAtMs: number | null, nowMs: number): Promise<ReporterStats> {
  const since = TS.fromMillis(nowMs - ABUSE_WINDOW_DAYS * 86_400_000);
  const snap = await db().collection('moderation_queue')
    .where('reporterId', '==', uid)
    .where('createdAt', '>=', since)
    .orderBy('createdAt', 'desc')
    .limit(READ_LIMIT)
    .get();
  const out: ReporterStats = { dismissed: 0, actioned: 0, dismissedSinceWarning: 0 };
  for (const d of snap.docs) {
    const q = d.data();
    if (q.reopenedByAppealId && !FINAL.has(q.status)) continue;
    const dismissed = isDismissed(q);
    if (dismissed === null) continue;
    if (dismissed) {
      out.dismissed++;
      const created = ms(q.createdAt);
      if (warnedAtMs !== null && created !== null && created > warnedAtMs) out.dismissedSinceWarning++;
    } else {
      out.actioned++;
    }
  }
  return out;
}

async function readStanding(uid: string): Promise<Standing & { raw: Record<string, any> }> {
  const raw = (await db().collection(REPORTER_STANDING).doc(uid).get()).data() || {};
  return {
    raw,
    warnedAtMs: ms(raw.warnedAt),
    suspendedUntilMs: ms(raw.suspendedUntil),
    reviewPending: typeof raw.pendingReviewQueueId === 'string' && !!raw.pendingReviewQueueId,
  };
}

/** True while the reporter's reports are not processed (one doc read). */
export async function isReportingSuspended(uid: string | null | undefined, nowMs = Date.now()): Promise<boolean> {
  if (!uid || ['anonymous', 'admin', 'system'].includes(uid)) return false;
  const until = ms((await db().collection(REPORTER_STANDING).doc(uid).get()).data()?.suspendedUntil);
  return until !== null && until > nowMs;
}

/** Runs after a report-pipeline item was closed as no-violation. */
export async function checkAbusiveReporter(uid: string, nowMs = Date.now()): Promise<ReporterVerdict> {
  if (!uid || ['anonymous', 'admin', 'system'].includes(uid)) return 'none';
  const st = await readStanding(uid);
  const stats = await reporterStats(uid, st.warnedAtMs, nowMs);
  const verdict = evaluateReporter(stats, st, nowMs);
  const ref = db().collection(REPORTER_STANDING).doc(uid);
  const counts = `${stats.dismissed} of your ${stats.dismissed + stats.actioned} reports reviewed in the last ${ABUSE_WINDOW_DAYS} days were found to be unfounded`;
  if (verdict === 'warn') {
    const decisionId = `reporter_warning_${uid}_${nowMs}`;
    await ref.set({
      userId: uid,
      warnedAt: TS.fromMillis(nowMs),
      warningDecisionId: decisionId,
      lastStats: { ...stats, at: TS.fromMillis(nowMs) },
    }, { merge: true });
    await createModerationDecision({
      decisionId,
      userId: uid,
      action: 'reporterWarning',
      reasonCode: 'unfounded_reports',
      explanation: `${counts}. If this continues, we may stop processing your reports for ${SUSPEND_DAYS} days (Terms 18.6). Please report only content you believe is illegal or against our Community Guidelines.`,
      decidedBy: 'system',
      contentRef: { type: 'report', id: null, excerpt: null },
      // A warning computed from the review outcomes, not a restriction.
      automated: { detection: null, decision: true },
      nowMs,
    });
  } else if (verdict === 'review') {
    const queueId = `reporter_abuse__${uid}__${nowMs}`;
    const now = TS.fromMillis(nowMs);
    await db().collection('moderation_queue').doc(queueId).create({
      queueId,
      itemType: 'reporterAbuse',
      itemId: uid,
      userId: uid,
      priority: 'low',
      category: 'reporterAbuse',
      status: 'pending',
      addedAt: now,
      createdAt: now,
      assignedTo: null,
      relatedReportIds: [],
      reasonCode: 'unfounded_reports',
      metadata: { reasonCode: 'unfounded_reports', stats, warningDecisionId: st.raw.warningDecisionId ?? null },
      content: { text: `${counts} (${stats.dismissedSinceWarning} after the warning). Suggested: suspendReporting for ${SUSPEND_DAYS} days, or dismiss.` },
      reporterId: 'system',
    });
    await ref.set({ pendingReviewQueueId: queueId, lastStats: { ...stats, at: now } }, { merge: true });
  }
  return verdict;
}

/** takeModerationAction 'suspendReporting' on a reporterAbuse item. */
export async function suspendReporting(p: {
  uid: string; days: number; decisionId: string; moderatorId: string; explanation: string | null; nowMs?: number;
}): Promise<DecisionEffect[]> {
  const nowMs = p.nowMs ?? Date.now();
  const until = TS.fromMillis(nowMs + p.days * 86_400_000);
  await db().collection(REPORTER_STANDING).doc(p.uid).set({
    userId: p.uid,
    suspendedUntil: until,
    suspendedAt: TS.fromMillis(nowMs),
    suspensionDecisionId: p.decisionId,
    pendingReviewQueueId: null,
  }, { merge: true });
  return [{ type: 'reportingSuspension', userId: p.uid }];
}

/** Moderator dismissed a reporterAbuse item: allow a later review. */
export async function clearReporterReview(uid: string): Promise<void> {
  await db().collection(REPORTER_STANDING).doc(uid).set({ pendingReviewQueueId: null }, { merge: true });
}
